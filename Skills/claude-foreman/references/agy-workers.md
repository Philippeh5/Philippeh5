# Antigravity (agy) workers: probe, invoke, read back

Google's Antigravity CLI (`agy`) is an optional accelerator, alongside Codex and Grok — never a requirement. When present, it adds the Gemini family of worker seats, plus a handful of non-Gemini models the same account happens to expose. Everything below is sourced from direct execution on the author's machine (2026-08-26), the launcher script (`scripts/agy-dispatch.sh`), and the visible wrapper (`agents/foreman-agy-wrapper.md`) — nothing here is asserted from general knowledge of Gemini or Antigravity.

## The dead `gemini` CLI — do not route here

This machine also has the plain `gemini` CLI installed (v0.49.0). Its auth is dead: it fails with `IneligibleTierError: This client is no longer supported for Gemini Code Assist for individuals`, and Google's own error message directs users to Antigravity. There is no live account behind `gemini` on this machine — `agy` is the *only* working transport to a Gemini model here. If a dispatch ever fails and the instinct is to "just call `gemini` directly instead," that instinct is wrong: it will fail the same way, for the same reason, every time. Don't spend a turn rediscovering this.

## The probe (once per session, cache the result)

```bash
command -v agy || ls ~/.local/bin/agy   # 1. installed? (Linux: ~/.local/bin/agy)
agy --version                                      # 2. binary alive?
agy models                                         # 3. authenticated? which models does THIS account see?
```

- On this Linux machine agy lives in `~/.local/bin/agy`. Honor `FOREMAN_AGY_BIN` if the environment sets it — the launcher resolves the binary the same way: `$FOREMAN_AGY_BIN` if set, else `agy` on PATH, else the default install path under `AppData\Local\agy\bin\agy`.
- `agy models` on 2026-08-26 returned: `gemini-3.7-flash-{low,medium,high}`, `gemini-3.6-flash-{low,medium,high}`, `gemini-3.5-flash-{low,medium,high}`, `gemini-3.1-pro-{low,high}`, `claude-sonnet-4-6`, `claude-opus-4-6-thinking`, `gpt-oss-120b-medium`. Refresh this list with a real `agy models` call before relying on it in a long run — don't assume it's still current just because it's written here.
- Reasoning effort is baked into the model id itself as a suffix (`-low`/`-medium`/`-high`), not a separate axis you choose independently — even though `agy` also exposes an `--effort` flag. Pick the model id for the effort level you want; don't expect `--effort` to retune a `-low` id up to `-high` behavior.
- Same GNU-`timeout` caveat as Codex and Grok: it may be missing on some systems (present on this Linux box, but the tool timeout is still preferred). Use your shell tool's own timeout parameter, set generously (60s+) — a slow response is latency, not absence. The launcher itself takes a `[timeout]` positional argument (seconds, default 600) that it passes to `agy` as `--print-timeout`.

## THE HAZARD: stdin silently swaps the seat — never pipe the prompt to agy

This is the one fact in this document that must never get flattened, softened, or "simplified" back out of the launcher. Reproduced twice on 2026-08-26:

```
agy --print --model gemini-3.6-flash-low --mode plan  < ticket.txt
  -> --model SILENTLY IGNORED. Served Claude Opus 4.6 (Thinking) instead.
     The prompt was never answered — the response was just a
     "You're now using Claude Opus 4.6 (Thinking)" greeting.

agy --print "<prompt text>" --model gemini-3.6-flash-low --mode plan
  -> --model honoured.
```

Putting the prompt on stdin doesn't just drop the flag quietly — it swaps in the most expensive seat in the whole pool (Claude Opus 4.6, Thinking mode) while the ledger still records whatever cheap Gemini tier was requested, and it does this with no error, no warning, nothing distinguishing a normal run from a silently-substituted one except the greeting text in the response body. A launcher shaped like Codex's — pipe the ticket in on stdin (`- <`) — would be *actively dangerous* here, not merely different. This is why `agy-dispatch.sh` passes the prompt in argv instead (`agy --print "$PROMPT" --model "$MODEL" ...`), and why that choice is called out as INVARIANT 1 in the script's own header comment, in capital letters, with an explicit instruction not to "simplify" it back toward the stdin shape other launchers use. If you are ever tempted to hand-compose an `agy` call outside the launcher, or to "fix" a launcher invocation by redirecting a file into it, stop — that is the exact shape of the failure.

**Consequence — the argv ceiling.** Because the whole ticket must travel as a single argv string, it is subject to Windows's command-line length cap (roughly 32767 bytes) and to `execve`'s per-argument limit. The launcher enforces a 30000-byte ceiling on the ticket file (`FOREMAN_AGY_ARGV_CEILING`, leaving headroom for the binary path, flags, and model id) and **refuses oversize tickets outright rather than truncating them**. A truncated prompt is a worker silently answering a smaller question than the one asked — the failure would be invisible in the output, exactly the same shape of danger as the stdin hazard itself. If a ticket is too big, the fix is to move bulk context into files and cite the paths in the ticket (delegation.md's standing rule for bulk artifacts), never to shrink the launcher's ceiling to make an oversize ticket fit.

## No seat evidence — agy dispatches may never carry FRONTIER judgment or a verdict

`agy --print` returns prose. It is not an event stream, and nothing in its output names the model that actually answered — there is no served-model field to check the way Layer 0 (verification.md) defines `SERVED` evidence. A model's own claim about its identity is not evidence (SKILL.md hard rail 5), and in the stdin-hazard case above the model didn't even make a false claim — the greeting *told the truth* about being Opus while `--model` had asked for a flash tier, and the launcher still could not have detected the swap from the JSON envelope because there isn't one. Every agy dispatch is therefore logged `seat: unverified`, exactly as the launcher itself prints it, and per Layer 0 an unverified seat must not carry FRONTIER-tier judgment or stand in as a verification verdict. Treat agy workers as advisory/implementation seats only — a second pair of hands, never the accepting review on a change and never the deciding opinion when a design question is contested. Route FRONTIER judgment and verification verdicts to a seat with real seat evidence instead (Claude natively, or whichever other transport in this skill actually produces served-tier evidence).

The launcher does carry one heuristic on top of this: if the response artifact opens with `"You're now using"` or `"You are now using"` (case-insensitive, first 400 bytes), it prints a `WARNING:` block flagging the dispatch as `SUSPECT` — the signature text of exactly the stdin-hazard failure. **This is a suspicion tripwire, not seat evidence.** It can only ever raise an alarm on the one known failure signature; it proves nothing when it stays silent, and a differently-worded fallback greeting (or a genuine on-topic response from the wrong model) would not trip it at all. Never read the absence of a `WARNING:` as confirmation the requested model served the request.

## Tier mapping

Map the verified model ids to routing classes as follows (per this ticket's empirical mapping — cross-check against model-matrix.md's own tables before leaning on this in a long run, since that file is the shared source of truth for routing classes across all worker families):

| Routing class | Model id(s) |
|---|---|
| FAST | `gemini-3.7-flash-low` (+ `gemini-3.8-flash-low`, `gemini-3.6-flash-low` as same-class rotation) |
| STANDARD (WORKHORSE) | `gemini-3.7-flash-medium`, `gemini-3.7-flash-high` (+ `gemini-3.8-flash-medium/high`, `gemini-3.6-flash-medium/high` as same-class rotation) |
| POWER (upper-WORKHORSE / hard-coding default) | `gemini-3.1-pro-high` |
| Claude-in-AGY (hard-coding fallback only, see below) | `claude-sonnet-4-6`, `claude-opus-4-6-thinking` |
| FRONTIER (judgment/verdict) | never — no seat evidence exists for this transport (see above); applies to the Claude-in-AGY ids too, they are AGY seats, not the LEAD |

`gemini-3.6-flash-{low,medium,high}` and `gemini-3.5-flash-{low,medium,high}` are older generations of the same flash line: allowlisted and safe to use, and — since the 2026-09-25_v2 Codex-RESERVE rebalance — an intended rotation target alongside 3.7/3.8, not merely a fallback for when 3.7 is absent (routing.md 2a-ii). `gemini-3.1-pro-low` is visible on `agy models` and answers correctly, but has no assigned routing class here — don't invent one.

**`gpt-oss-120b-medium` is listed by `agy models` but is not entitled on this login.** Measured 2026-08-26: two dispatches, ~2 s each, both `Error: Eligibility check failed: UNAVAILABLE (code 503)`. It is in `never_request` (routing-defaults.json) — **never route to it** until a fresh probe and a re-audit say otherwise.

**A 503 eligibility error is not proof a model is dead.** In the same sweep `gemini-3.1-pro-low` failed the identical way on attempt 1 and answered correctly on retry. Retry an eligibility 503 exactly once before recording the model unavailable — and never a third time on unchanged input (delegation.md's precedence table).

## Claude-in-agy seats — audited and enabled 2026-09-25

`claude-sonnet-4-6` and `claude-opus-4-6-thinking` appear in `agy models` and were previously refused outright by the launcher's allowlist. **Unblocked 2026-09-25** after the user asked for a 6-point re-audit, given real observed account usage (Codex >50% of a limited monthly quota; agy's Claude-bundled tiers ~0% used — user-stated policy input, not telemetry: `agy --help` has no usage/quota subcommand, checked live this date):

1. **Why they were blocked**: a cost/evidence policy choice ("costs Antigravity quota, yields no seat evidence"), recorded verbatim in the old `BLOCKED:` message — not an entitlement failure, not a technical error.
2. **Really executable via `agy --print`?** Yes — tested live 2026-09-25 with a direct argv call for each id (`agy --print "<proof string>" --model claude-sonnet-4-6 --mode plan --sandbox --add-dir <dir> --print-timeout 50s`, and the same for `claude-opus-4-6-thinking`): both exited 0 and echoed the exact requested proof string, with no `"You're now using"` substitution-tripwire text.
3. **Do they belong to the user's plan?** No 503/eligibility error on either (unlike `gpt-oss-120b-medium`, which does 503 on this account) — the account can reach both.
4. **Do they cross a `NEVER_REQUEST` line?** They were the two entries specifically named there for exactly this reason; the audit removed those two lines by the same authority that added them (the user, re-evaluating in this session) — every other `never_request` entry is untouched.
5. **Seat provenance**: identical to every other agy dispatch — **none**. `agy --print` has no served-model field for any model it runs, Claude ids included. Using them does not create or imply provenance that doesn't exist elsewhere in this transport.
6. **Micro-test**: done (item 2 above) — clean, read-only, no edits, no `.stderr` output, exit 0 on both.

**What "enabled" does and does not mean.** They are now ordinary AGY seats, reachable through `scripts/agy-dispatch.sh` / the `foreman-agy-wrapper` exactly like any Gemini tier, tagged `seat: unverified (Layer 0)` on every dispatch — same as before, no upgrade. They are **never** the LEAD, **never** eligible for `frontier-judgment` or the accepting `blind-verifier` verdict (model-matrix.md Table 5's "Never: agy" line covers these ids too — dispatching Claude *through agy* does not somehow inherit the LEAD's own seat evidence). Routing-defaults.json places them in the `hard-coding` job only, below AGY's Gemini POWER tier (`gemini-3.1-pro-high`) — `claude-sonnet-4-6` for hard general reasoning the Gemini tier couldn't clear, `claude-opus-4-6-thinking` only if that still isn't enough. Believed (user's own account-structure statement — not independently verifiable from inside this skill) to draw on a separate Antigravity-bundled Claude allocation, distinct from the LEAD's own Claude Code subscription; log spend against that belief, not as a verified fact.

If the launcher's `BLOCKED: '<model>' is a Claude seat reached through agy` message reappears in a future read of `agy-dispatch.sh`, that means someone reverted the 2026-09-25 unblock — check routing-defaults.json's `_policy_2026-09-25_v2` note and this section before re-applying either direction.

## Transport: visible subagent wrapper first, direct launcher call as fallback

agy gets the same wrapper-first transport pattern as Codex and Grok, via the bundled `scripts/agy-dispatch.sh` launcher and the `foreman-agy-wrapper` agent.

**When the Agent tool is available, dispatch agy through the wrapper subagent** — the bundled `foreman-agy-wrapper` agent (haiku, low effort, tools restricted to `Bash, Read, Grep` — no edit tools, no agent spawning), which runs the launcher exactly once and relays the result. This buys the same three things the Codex and Grok wrappers buy: user visibility (a named crew member in the harness UI, not an invisible shell-out), notification-driven collection instead of hand-rolled polling, and a foreman that stays free while the worker runs. Direct launcher invocation from the foreman's own Bash remains correct in Agent-tool-less modes and for sub-minute advisory calls where wrapper overhead exceeds the benefit.

**The launcher's real argument list** (read from `scripts/agy-dispatch.sh` — never hand-compose an `agy` call):

```
agy-dispatch.sh <ticket-file> <model> <read-only|workspace-write> <artifact-txt> [workdir] [timeout]
```

Four required positional slots (ticket, model, sandbox, artifact path) and two optional (`workdir`, defaulting to `.`; `timeout` in seconds, defaulting to 600). Resolve `FOREMAN_SKILL_DIR` once — the directory containing the SKILL.md you are reading — and pass every argument as an absolute path, matching the Codex and Grok conventions.

Before spending anything, the launcher validates and refuses (`BLOCKED` on stderr, nonzero exit) on:

- `MODEL` not on the allowlist (`gemini-3.7-flash-{low,medium,high}`, `gemini-3.6-flash-{low,medium,high}`, `gemini-3.5-flash-{low,medium,high}`, `gemini-3.1-pro-{low,high}`, `gpt-oss-120b-medium`) — an unrecognized id is exactly the input class that would otherwise silently trip invariant 1's fallback behavior if it reached `agy` unchecked, so it's caught here first.
- `MODEL` equal to `claude-sonnet-4-6` or `claude-opus-4-6-thinking` — refused with the message quoted above (route to native Claude instead).
- `SANDBOX` not exactly `read-only` or `workspace-write`.
- `TIMEOUT` not a positive integer.
- a missing ticket file or workdir.
- an artifact path that doesn't end in `.txt`, is a symlink, aliases the ticket file, or otherwise isn't a plain regular file.
- a ticket over the 30000-byte argv ceiling (see the hazard section above).
- an empty ticket file.

`SANDBOX` maps to a `--mode` flag, not a separate sandbox setting: `read-only` becomes `--mode plan` (agy will not write), `workspace-write` becomes `--mode accept-edits` (edit tools auto-approve, so a headless run cannot deadlock on an approval prompt it has no way to answer). `--sandbox` itself (agy's terminal-restriction flag) is pinned on unconditionally in both cases — it is not a knob the launcher exposes. agy has **no `-C`/`--cwd` flag**, so the launcher sets the working directory via a subshell `cd "$WORKDIR"` and additionally passes `--add-dir "$WORKDIR"` so the two cannot drift apart.

What the launcher pins into the actual `agy` invocation once validation passes: `agy --print "$PROMPT" --model "$MODEL" --mode "$MODE" --sandbox --add-dir "$WORKDIR" --print-timeout "${TIMEOUT}s"`, run as a tracked child from inside `$WORKDIR`. The child's PID is written to `<artifact>.txt.pid` **before** the launcher waits on it — the "prove it stopped" handle for the LOST protocol (delegation.md). If the PID file can't be written, the launcher kills the just-spawned child and refuses rather than let paid work run untracked. An INT/TERM to the launcher forwards to the child and reaps it — no orphaned agy process left running after the wrapper dies.

**The wrapper contract** (put it in the wrapper's prompt verbatim — it also lives in `agents/foreman-agy-wrapper.md`):

1. Run `scripts/agy-dispatch.sh` exactly once, with exactly the arguments your ticket gives you (four to six positional arguments), and the shell timeout your ticket names. Never compose a raw `agy` command, never wrap the launcher in shell operators, never run it twice.
2. **Never pipe the ticket into the launcher on stdin, and never "fix" a launcher call by redirecting a file into it.** If a call looks like it needs stdin, that is a ticket bug: report `BLOCKED` and stop.
3. Report in exactly this shape: line 1 `DONE` if the launcher exited zero, else `BLOCKED` followed by the tail of `<artifact>.stderr`. Then the launcher's stdout (the transport envelope) verbatim, **including the exact wording of the seat-evidence line** — it reads `seat evidence: NONE — ... Seat: unverified (Layer 0).`; never shorten it, never paraphrase it, never render it as `seat: verified`. If the envelope contains a `WARNING:` block about a model-switch greeting, relay it in full and put the word `SUSPECT` on the first line next to the status. Then the agy worker's response, produced by running exactly `cat <artifact-txt>` and relaying its stdout verbatim — never retype, summarize, or reconstruct it; if the command fails, relay its error and say `RELAY FAILED`.
4. Spawn nothing; write nothing except what the launcher itself writes.
5. Your relay is transport metadata. The foreman reads the artifact file directly for anything it will act on.

**Vocabulary discipline:** identical to Codex and Grok's rule — the transport envelope is metadata, not a report vocabulary. The worker status is read from the first line of the *relayed* agy message, exactly as if agy had reported directly.

**Failure mapping (deterministic — no judgment calls at the transport layer):**

| Observation | Treatment |
|---|---|
| Launcher exit nonzero (any pre-flight `BLOCKED:` refusal above, or the child itself exiting nonzero) | Worker `BLOCKED`; envelope + `<artifact>.stderr` are the evidence |
| Exit 0, no parseable status line in the relayed final message | `BLOCKED` (malformed report); artifact path in ledger |
| Exit 0, empty final message | `BLOCKED`; artifact retained for diagnosis |
| Envelope contains a `WARNING:` model-switch block | Mark the dispatch `SUSPECT`; do not accept the output before checking the artifact by hand — the requested model may not be the one that actually served the request |
| Wrapper itself silent past its deadline | Wrapper task is `LOST` — apply the LOST protocol to the *wrapper* (delegation.md); check `<artifact>.txt.pid`, kill the child if still live, and only then reconcile the workspace |
| Envelope reports `seat evidence: NONE ... Seat: unverified (Layer 0)` | Normal and expected for every agy dispatch — record it; Layer 0 consequences apply (no FRONTIER judgment, no verification verdict) |
| Relayed message does not match the artifact | Wrapper contract breach; use the artifact, ledger `wrapper relay: unreliable`, and do not reuse that wrapper seat this run |

**Enforcement scope, stated honestly:** the launcher makes compliance auditable — the transcript shows either one launcher call or a contract breach — and pins the argv so a wrapper has no legitimate reason to touch `agy` directly. It does **not** machine-prevent the wrapper's own general shell from calling `agy` raw; that remains a harness-layer concern (tool-policy hooks), exactly as with Codex and Grok.

## Invocation pattern

Non-interactive, one ticket per invocation, via the wrapper (above) or directly:

`FOREMAN_SKILL_DIR` is the directory containing the SKILL.md you are reading —
`~/.claude/skills/claude-foreman` on a standard install, `<checkout>/skills/claude-foreman`
in the marketplace repo; resolve it once, and pass every argument as an absolute path.

```bash
# Advisory / review work — read-only sandbox (plan mode, agy will not write):
"$FOREMAN_SKILL_DIR"/scripts/agy-dispatch.sh \
  <abs-repo>/.foreman/scratch/ticket-N.md gemini-3.7-flash-medium read-only \
  <abs-repo>/.foreman/scratch/artifact-N.txt <abs-repo>

# Implementation work — writable workspace (accept-edits mode):
"$FOREMAN_SKILL_DIR"/scripts/agy-dispatch.sh \
  <abs-repo>/.foreman/scratch/ticket-N.md gemini-3.7-flash-high workspace-write \
  <abs-repo>/.foreman/scratch/artifact-N.txt <abs-repo>

# Harder task needing the upper-WORKHORSE tier, with an explicit timeout:
"$FOREMAN_SKILL_DIR"/scripts/agy-dispatch.sh \
  <abs-repo>/.foreman/scratch/ticket-N.md gemini-3.1-pro-high workspace-write \
  <abs-repo>/.foreman/scratch/artifact-N.txt <abs-repo> 900
```

- The ticket file's *contents* go into argv, read via `$(cat "$TICKET")` inside the launcher — never pipe the ticket file itself into the launcher's stdin (see the hazard section). This is the opposite convention from Codex's `- <` stdin pipe; don't cross-copy the two launchers' invocation shapes.
- Keep tickets under the 30000-byte argv ceiling. If a ticket needs more context than that, write the bulk material to files under `.foreman/scratch/` and have the ticket cite the paths, rather than inlining it.
- Sandbox follows the *task*: `read-only` for advisory work, `workspace-write` for anything that edits files.

## Reading back

**Seat provenance is unverified, full stop.** Log every agy dispatch exactly as the launcher prints it: `seat evidence: NONE — agy --print returns prose with no served-model field. Requested '<model>' via --model. Seat: unverified (Layer 0).` Never write `seat: verified` for an agy dispatch, and never let an agy report stand in as the accepting verifier verdict on a change, or as the deciding FRONTIER opinion on a contested design question — an agy worker is an advisory/implementation seat, full stop, weaker in this respect than Codex's `seat: unverified` (which at least comes from a JSON event stream the launcher scans for a served-model field version-tolerantly) and weaker than Grok's `seat: billed-tier evidence` (which comes from a real usage/billing key, even though that too falls short of `verified`). agy has neither an event stream nor a billing key to fall back on — the only signal available is the heuristic `WARNING:` tripwire on the response text, and that tripwire proves nothing by its absence.

Otherwise, agy workers follow the same contract as Claude, Codex, and Grok workers: status as the first line of the final message (`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED` — put this in every execution ticket's OUTPUT FORMAT), evidence not narrative, artifacts to `.foreman/scratch/` with paths.

**The relay is a claim.** For any class-sensitive read — findings entering a fix wave, statuses that decide routing — the foreman reads the artifact file directly; the relay serves notification and status only.

## Quota notes

No verified data exists on this account for agy's rate-limit windows, message allowances, or per-call cost — don't promise numbers that weren't measured. Treat spend under the ordinary budget-discipline rule (journal it, step a tier down or stop under budget pressure) until real figures are observed.

## Selecting among agy models (2026-09-25_v2 policy: Codex-RESERVE)

Since 2026-09-25_v2, `mechanical`, `standard-coding`, and `hard-coding` (routing-defaults.json) all default to agy — Codex is RESERVE everywhere, not just deprioritized for routine work (routing.md 2a). This makes "which agy model" the primary routing decision for nearly every implementation ticket, so the procedure is:

1. **Pick by task fit first**, per the tier mapping above: TRIVIAL/FAST → `gemini-3.7-flash-low` (rotate: `gemini-3.8-flash-low`, `gemini-3.6-flash-low`); STANDARD/WORKHORSE → `gemini-3.7-flash-high` (rotate: `gemini-3.7-flash-medium`, `gemini-3.8-flash-high`, `gemini-3.6-flash-high`); POWER/hard-coding → `gemini-3.1-pro-high`, then the Claude-in-AGY seats (`claude-sonnet-4-6`, then `claude-opus-4-6-thinking` only if still not enough — see "Claude-in-agy seats" above). This is the routing card's `default`/`fallbacks` order for each job.
2. **On a failed dispatch, distinguish availability from quality.** A nonzero exit, a `BLOCKED:` refusal, or an `Eligibility check failed (503)` in the artifact/stderr is an **availability** signal — retry the same model exactly once (a 503 is not proof a model is dead, see above), then, if it fails again, step to the *next agy tier or generation appropriate for the same task* before leaving agy for the gateway pool.
3. **Do not describe this as quota rotation.** No verified evidence exists that agy's models draw on separate quota pools (model-matrix.md Table 6, "Quota notes" above) — they are one Google/Antigravity account behind one binary, with no `--account`/`--quota` selector (`agy --help`, checked 2026-09-25). "Try another agy tier" is a **task-fit-then-availability** fallback, exactly like retrying a flaky call — never write "model A's quota is exhausted, switching to model B" in a ledger or report; write "model A unavailable (503/timeout/BLOCKED after one retry), stepped to model B" instead. The user's own reported percentages (Codex >50%, agy Pro ~4%, agy Flash ~6%, agy Claude ~0%) are a **stated policy input** driving the job orderings in routing-defaults.json, not something this skill measures or refreshes automatically — if real per-model quota telemetry ever becomes observable (a rate-limit header, a documented per-tier allowance), update this section and model-matrix.md Table 6 with the citation before routing off it as fact.
4. **Only after every task-appropriate agy tier (Gemini and, for `hard-coding`, Claude-in-AGY) is unavailable** does the job fall through to `claude-openrouter`/`claude-api` (gateway-seats.md), and only after that fails too does Codex become reachable automatically — and only in the two jobs that still list it (`hard-coding`, `no-frontier-implementation`), always last.

## AGY tickets: edit-only by default (2026-09-25 finding)

A real run dispatched 3 AGY tickets in `workspace-write` mode, each asking the worker to run its own verification command (`tsc`, eslint) as part of the ticket. All 3 came back `exit 0` with an **empty artifact** — no edit made, no error surfaced. Root cause (already documented above, "workspace-write-yolo" in `agy-dispatch.sh`'s header comment): `--mode accept-edits` auto-approves EDIT tools only; a command-permission request (npx/tsc/eslint/grep-via-shell) is auto-denied **and aborts the whole run silently**. Since 2026-09-25_v2 routes far more tickets to AGY by default, this stops being an edge case and becomes the normal shape of an AGY ticket — write tickets accordingly:

- **Default: write AGY implementation tickets as edit-only.** The `MUST DO` section should tell the worker to make the file edit(s) and describe them in its report, and explicitly say "do not run any shell/terminal command — this sandbox mode does not support it and will silently abort the dispatch with no output." Verification (`tsc`, eslint, tests, browser checks) is the LEAD's or the `foreman-verifier`'s job, run independently afterward — which SKILL.md's "Verify like you trust no one" already requires regardless, so this is not a new assurance gap, just naming explicitly why the worker itself cannot supply that evidence.
- **`workspace-write-yolo` is the alternative**, but it needs the user's explicit say-so *for the run* (agy-dispatch.sh's own comment: "never select it without the user saying so") — do not switch a ticket to it as a workaround without asking, and do not treat a prior session's consent as standing consent for a new one.
- **The failure signature to watch for**: launcher exit 0 **and** an empty (or near-empty) artifact file. Per agy-workers.md's failure-mapping table this is `BLOCKED` (malformed/empty report) at the worker-status layer, regardless of what the transport wrapper's own "DONE" line says (that line only reflects the *launcher's* exit code, not the worker's actual output) — never accept it as `DONE` on the wrapper's word alone; open the artifact file and check.

## First-time setup for repo-reading tickets (2026-09-30 field note — read this before the first dispatch)

**Symptom seen in a real run:** scouts/reviews dispatched with sandbox `read-only` came back `exit 0` with an EMPTY artifact and stderr `jetski: no output produced — a tool required the "command" permission that headless mode cannot prompt for`. The same tickets re-run with `workspace-write-yolo` (= `--dangerously-skip-permissions`) worked on the first try (recon 12–18 KB, plan 9 KB, reviews 7 KB, 93–740 s). Cause: any ticket that makes agy read, list or grep the repo needs the command permission; `read-only` and `workspace-write` both auto-deny it and abort silently. The launcher now prints `WARNING: EMPTY ARTIFACT` in that case.

**Do this the first time, not after two failed dispatches:**
1. A ticket that only READS a few files it is given by exact path works in `read-only` (tested 2026-09-30: returned the first heading of a named file). Anything that must SEARCH or LIST (grep, find, "look around the repo") does not: tested, empty artifact + the permission stderr. So: named files only -> `read-only`; exploration -> option 2.
2. A ticket that must explore the repo: use sandbox `workspace-write-yolo` from the start. It needs the user's say-so; look for it in this order: the user's current message; the project's `CLAUDE.md` / memory (Philippe approved it for BlastWin analysis, plan and review tickets on 2026-09-30 — see the `foreman-agy-gotchas` memory); otherwise ask once, in one line, and remember the answer for the session.
3. yolo can also WRITE, so always: save `git status --porcelain` + `git rev-parse HEAD` to `.foreman/scratch/git_baseline.txt` before the wave, tell the ticket "read-only task, do not edit any repo file", and diff `git status --porcelain` against the baseline after every agy run; any drift voids the dispatch.
4. Never accept `DONE` from the wrapper on its word: open the artifact and check it is non-empty.

**Model notes from the same run (evidence, not policy):** `gemini-3.1-pro-high` and `claude-sonnet-4-6` via agy both returned full plans/reviews; `gemini-3.8-flash-high` did the recon. After the user confirmed in the Antigravity dashboard, usage was counted on their account (the dashboard can lag; agy itself prints no usage).

**2026-10-03 addendum:** a `workspace-write-yolo` agy ticket can create files in its `workdir`. Pass a scratch directory as workdir (cite repo files by absolute path in the ticket), and check `git status` before any `git add -A`: reviewer attack scripts were once committed into a PR by a blanket add.

## Standing instruction (Philippe, 2026-11-07): agy always runs with full permission

`scripts/agy-dispatch.sh` now passes `--dangerously-skip-permissions` in every sandbox mode, so a headless agy run can no longer die on a "command" permission with an empty artifact. `read-only` still maps to `--mode plan`. The older rule "never select yolo without the user saying so" is superseded by this standing instruction. Interactive `agy` in a shell also gets the flag through an alias in `~/.bashrc`.
