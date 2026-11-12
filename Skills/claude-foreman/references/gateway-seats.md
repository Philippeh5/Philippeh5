# Gateway Claude Code seats (`claude-openrouter`, `claude-api`)

Facts here were measured on this machine on 2026-08-26. Re-run
`scripts/probe.sh` before trusting the alias maps — they are user-editable.

## What the seat actually is

Not an API. Not a completion endpoint. `claude-openrouter` and `claude-api` are
the **same Claude Code binary** pointed at a different config directory:

```sh
# ~/.local/bin/claude-openrouter
export CLAUDE_CONFIG_DIR="$HOME/.claude-openrouter"
exec "$HOME/.local/bin/claude" "$@"
```

That config directory holds its own `ANTHROPIC_BASE_URL` (a gateway) and its own
credential, both already configured. Two consequences that drive every routing
decision below:

1. **No new API key is ever needed.** If the probe reports the config dir
   exists, the seat is routable. Adding `OPENROUTER_API_KEY` or
   `ANTHROPIC_API_KEY` to make these seats work is a category error — an earlier
   design of this skill did exactly that and had to be deleted.
2. **A dispatch is a full agent**, with tools, file access, and the four-status
   worker contract — not text-in/text-out. These seats *can* hold implementation
   tickets, which is what separates them from the consultation seats they
   replaced.

## The tier aliases do not name Claude models

Each gateway maps `opus`/`sonnet`/`haiku`/`fable` to a **third-party** model via
`ANTHROPIC_DEFAULT_<TIER>_MODEL` in its `settings.json`. **The map is
user-editable and has already drifted once** — re-verify with `probe.sh` before
trusting either column below, and re-run the live dispatch test in this file's
"Live capability audit" section before routing off a stale map.

| Alias | `claude-openrouter` | `claude-api` |
|---|---|---|
| `opus` | `thinkingmachines/inkling:free` — live 2026-09-25 | `z-ai/glm-5-3` — **dead 2026-09-25, HTTP 404 `unrecognized_model`** (was `stepfun-ai/step-3.7-flash`, live, on 2026-08-26 — the map changed and broke) |
| `sonnet` | `poolside/laguna-s-2.1:free` — live 2026-09-25 | `nvidia/nemotron-3-ultra-550b-a55b` — live 2026-09-25 |
| `haiku` | `cohere/north-mini-code:free` — silently substituted, launcher-refused | `minimaxai/minimax-m3` — silently substituted, launcher-refused |
| `fable` | `stealth/ox-alpha` — **dead 2026-09-25, HTTP 400** ("Stealth Ox Alpha testing period" ended, message points to `z-ai/glm-5.3-flash` as the replacement — not yet added to either map) | `deepseek-ai/deepseek-v4.1-flash` — **live 2026-09-25** (was `deepseek-ai/deepseek-v4-flash-0731`, dead/404, on 2026-08-26 — the map changed and got fixed) |

**The dead alias flipped on both seats between 2026-08-26 and 2026-09-25**:
`claude-api` went from opus-live/fable-dead to opus-dead/fable-live;
`claude-openrouter` went from all-three-live to fable-dead. Neither seat has
zero working aliases — each currently has exactly 2 of 3 non-`haiku` aliases
live (`sonnet` + one other), which is the basis for the intra-provider
model-switch policy below. Live-tested 2026-09-25: see "Live capability audit".

**Route by what the alias resolves to, never by the alias name.** `opus` here is
not a frontier seat; on the openrouter side it is a free model. The tier ordering
in the map is the user's naming convention, not a capability guarantee.

This also means the seats are an **independent model family**, which is their
real value: they give cross-family review in a session where Codex is absent.
Never describe their output as a Claude second opinion — nothing Anthropic-made
served it.

## The `haiku` alias is silently substituted — do not route to it

Measured on both gateways, 2026-08-26, on the same one-word probe:

| Request | Alias maps to | What actually ran the agent loop |
|---|---|---|
| `claude-api --model haiku` | `minimaxai/minimax-m3` | `nvidia/nemotron-3-ultra-550b-a55b` (15130 in, vs 427) |
| `claude-openrouter --model haiku` | `cohere/north-mini-code:free` | `poolside/laguna-s-2.1:free` (29113 in, vs 79) |

In both cases the model that ran was the **`sonnet`-alias** model. The answer was
correct, so nothing looked wrong — the substitution is only visible in the token
split. This is routing.md's silent-fallback hazard on a second transport.

**Never route these seats at `haiku`** — the launcher refuses it outright
(invariant 4). You would not get the model you asked for, you would pay the
`sonnet` model's tokens, and the dispatch would be SUSPECT by the evidence rule
below.

**The other dead combination, as of 2026-09-25, is `claude-openrouter` + `fable`**
(`stealth/ox-alpha`, HTTP 400, retired) **and `claude-api` + `opus`**
(`z-ai/glm-5-3`, HTTP 404, unrecognized) — see the updated table above; these
replace the 2026-08-26 dead combination (`claude-api` + `fable`, now fixed).
The launcher does *not* refuse either of these, because dead-alias-mapping is a
property of the user's (or the gateway's) map, not of the transport, and both
fail loudly (`is_error: true`, `terminal_reason: "api_error"`, empty
`modelUsage`) rather than silently. Fix the map or route elsewhere.

**Usable combinations, live-tested 2026-09-25:** `claude-openrouter` at
`sonnet` or `opus`; `claude-api` at `sonnet` or `fable`. Each of those was
served by the id it maps to (confirmed via `modelUsage` billed-tier evidence,
not just an absence of error).

(An earlier note here claimed `claude-openrouter` + `haiku` returns an *empty*
result. That was a one-off; the re-run answered `391`. The reproducible defect is
the substitution, not emptiness.)

## Evidence: billed-tier, never served-tier

`--output-format json` returns a `modelUsage` map keyed by the ids the gateway
billed. That is real evidence and it catches substitutions — far better than
agy, which offers none. But it is the *gateway's accounting*, not a served-model
field from the provider, so per verification.md Layer 0 and SKILL.md hard rail 5
it is logged **`billed-tier`** and never `verified`. These seats therefore
**cannot carry a verification verdict**.

Two details the launcher encodes so nobody has to remember them:

- **`modelUsage` routinely holds two keys** — the model that ran the agent loop
  plus the small background model Claude Code uses for titles and summaries (on
  openrouter, `cohere/north-mini-code:free` shows up in every dispatch regardless
  of alias; on the api seat, `minimaxai/minimax-m3` does). **A presence test is
  not evidence.** On this machine the background model *is* what the `haiku`
  alias maps to, so "is the expected id in the map?" passed trivially for that
  alias while a different model did all the work — which is exactly how the
  substitution above went unnoticed at first. Evidence means *the id carrying
  the bulk of the input tokens is the expected one*. The split is unambiguous:
  the background model bills 79–427 input tokens against the main model's
  7.5k–29k.
- The check compares against the id **this machine maps** for the alias, read
  from the seat's own `settings.json`, not a list baked into the launcher. A
  mismatch prints `WARNING — SEAT MISMATCH` and the dispatch is SUSPECT.

## `total_cost_usd` is not money here

Measured: a `claude-openrouter` dispatch served entirely by `:free` models
reported `total_cost_usd = 0.158`. Claude Code prices the **alias tier** against
Anthropic's table; it has no idea what the gateway charges. The figure is wrong
in both directions and must never be quoted as money.

**Cost receipts for these seats record token counts only** (`input_tokens`,
`output_tokens`, cache fields), and any dollar figure is marked `ESTIMATE` with
the price table it came from — see simmer.md, "Cost receipts".

## Dispatching

Through the visible wrappers, never by hand:

- `foreman-openrouter-wrapper` → `claude-seat-dispatch.sh openrouter ...`
- `foreman-api-wrapper` → `claude-seat-dispatch.sh api ...`

```
claude-seat-dispatch.sh <openrouter|api> <ticket-file> <alias> \
    <read-only|workspace-write> <artifact.json> [workdir] [timeout]
```

- The **seat name is allowlisted**, never a path. An arbitrary
  `CLAUDE_CONFIG_DIR` would let a wrapper point the binary at any credential set
  on the machine — including the subscription one the LEAD session runs on.
- `read-only` → `--permission-mode plan`; `workspace-write` →
  `--permission-mode acceptEdits` (a headless run must not deadlock on an
  approval prompt it cannot answer).
- **The prompt travels on stdin, and `--model` is honoured** — verified on both
  seats. This is the *opposite* of agy (see agy-dispatch.sh invariant 1), so
  there is no argv ceiling and tickets may be arbitrarily large. Do not
  "harmonize" the two launchers; the difference is load-bearing.
- `claude -p` has no timeout flag, so the launcher runs its own watchdog and
  labels a watchdog kill as TIMEOUT rather than letting it read as a refusal.

Measured latency, live-tested 2026-09-25 on a trivial one-line echo prompt across
6 dispatches (3 aliases × 2 seats): 1–60 s. The 2026-08-26 figures (14–29 s
`claude-api`, ~9 s `claude-openrouter`) undersold the spread — one 2026-09-25
`claude-api`/`sonnet` run took the full 60 s window and only just completed
inside it (`num_turns: 3` — the served model reasoned across multiple turns even
for an echo). **Treat latency as "seconds to just over a minute," never a fixed
number**, and set dispatch timeouts accordingly (90s+ recommended, not the 60s
default, for anything non-trivial). Input token cost across the same six ran
9k–30k for a one-line answer — the system prompt of a full agent, paid on every
dispatch. **Never route a one-line question here**; a native `haiku` subagent is
cheaper and faster. These seats earn their keep on real tickets and on
cross-family review.

**A real, live-tested timeout kill** (2026-09-25, `claude-api`/`sonnet`, 3s
watchdog against a normal-latency prompt): exit 143, envelope prints
`NOTE: the child was killed at the 3s watchdog — treat as TIMEOUT, not as a
model refusal`, and the evidence line correctly degrades to
`seat evidence: NONE — artifact is not parseable JSON` rather than misreporting
a model failure. **A timeout is a transport-layer event, not a model or provider
verdict** — never log a timeout as "model X failed" or "provider Y down"; log it
as "timeout, retry or extend the window," and retry the same alias once before
concluding anything about the model itself.

**A known accounting quirk on `claude-api`**: every 2026-09-25 test dispatch to
this seat reported `usage.output_tokens: 0` in the JSON envelope even when the
`result` field held a full, correct multi-paragraph answer — `claude-openrouter`
does not show this (it reports real output-token counts, e.g. 727 on a
comparable answer). Treat `claude-api`'s `output_tokens` field as unreliable;
the `billed-tier evidence` line's *input*-token comparison and the presence of
a non-empty `result` remain trustworthy, the output-token count specifically is
not. Do not build any cost estimate on `claude-api`'s reported output tokens.

## Intra-provider model fallback, double-prompt, and parallelism (live-tested 2026-09-25)

**A model failure is not a provider failure — try the other live alias on the
same seat before treating the provider as down.** Both gateways currently have
exactly one dead alias each (see the alias table above): `claude-api`'s `opus`
returns HTTP 404 `unrecognized_model`; `claude-openrouter`'s `fable` returns
HTTP 400 ("testing period" ended). Both failures were reproduced live and are
clean, fast (~1-2s), loud (`is_error: true`, a clear `result` message, non-zero
exit), and **safe to use as the "model A fails" step of a real fallback chain**
— they are naturally-occurring dead mappings, not fabricated errors:

```
claude-api  / opus   -> HTTP 404 (dead alias)          [~1-2s, real]
      |
      v
claude-api  / sonnet -> success                         [~10-60s, real]
= "provider OK, model unavailable, fallback model successful" — NOT "provider FAILED"
```

```
claude-openrouter / fable  -> HTTP 400 (dead alias)      [~1-2s, real]
      |
      v
claude-openrouter / opus (or sonnet) -> success          [~10-25s, real]
= same distinction: router-local model fallback, not a provider-down event
```

**This is the router-local-failover distinction that must be preserved in every
report and ledger line**: a dead alias on one model, followed by success on
another alias of the *same* seat, is logged as `<seat>: model <X> unavailable,
stepped to model <Y>, success` — never as `<seat> FAILED`. Only exhaust BOTH
non-`haiku`, non-dead aliases of a seat before calling that seat down and moving
to the other gateway (inter-provider fallback) or further down the chain.

**True inter-provider exhaustion (Claude API's live aliases exhausted →
Claude OpenRouter, or the reverse) could not be cleanly live-tested** — both
seats currently have a genuinely working alias (`claude-api`/`sonnet`+`fable`,
`claude-openrouter`/`sonnet`+`opus`), and forcing a full-seat outage would mean
temporarily corrupting a live credential file (`~/.claude-nvidia/settings.json` or
`~/.claude-openrouter/settings.json`), which this audit treated as out of
bounds per the explicit instruction not to break the permanent configuration,
even temporarily-and-restored. **This is a documented gap, not a claimed
capability**: the routing chain order (routing-defaults.json) encodes
gateway-then-gateway ordering structurally, but no live dispatch has actually
exercised a full first-gateway outage forcing a hop to the second. Re-test if a
real full-seat outage is ever observed naturally (a genuinely useful ledger
entry when it happens), or if the user explicitly authorizes a controlled
credential-swap test.

**Double-prompt / second opinion — live-tested and confirmed working.** The
same read-only code question was dispatched to `claude-api`/`sonnet` and
`claude-openrouter`/`sonnet` in one parallel wave (two separate Agent tool
dispatches, no sequencing). Both returned correct, independently-verified
answers (cross-checked by the LEAD against the actual file content, not
accepted merely because the two agreed) — `claude-openrouter`'s answer was more
thorough (included the downstream `.map` handler as corroborating evidence),
`claude-api`'s was terser but equally correct. **Confirmed usable as a genuine
second opinion**, not just a fallback: two independent third-party model
families reasoning over the same question, in parallel, for less wall-clock
time than either running twice sequentially.

**Parallelism — live-tested and confirmed real, not sequential-in-disguise.**
Two independent `claude-seat-dispatch.sh` invocations (`claude-openrouter` at
`opus` and at `fable`) launched as background shell jobs completed in 11s total
wall-clock — matching the slower of the two individually (11s), not their sum
(13s) — direct evidence of genuine OS-level concurrency, not queued execution.
The same holds for the two Agent-tool-dispatched double-prompt calls above,
which is the mechanism claude-foreman actually uses in a real run (see
delegation.md "Parallel dispatch").

## Update 2026-09-28 — re-audit, one status change

Re-ran the alias sweep, both fallback chains, and the double-prompt/parallelism
tests live, three days after the audit above. Confirmed unchanged: `claude-api`
`opus` dead (`unrecognized_model` on `z-ai/glm-5-3`, same error, 2s), `sonnet`
live (5-17s); `claude-openrouter` `opus` and `sonnet` both live (11-102s),
`fable` dead (HTTP 400 "testing period" ended, same error, 3s). Intra-provider
fallback re-confirmed on both seats (a dead alias, then a live one on the same
seat, same session).

**One change: `claude-api`/`fable`.** Live on 2026-09-25 (`deepseek-ai/deepseek-v4.1-flash`).
Today: two consecutive timeouts — a 90s watchdog kill, then a 150s retry (the
"retry once" rule above) that also hit the watchdog. Both attempts produced no
parseable JSON (`seat evidence: NONE`), so this is not the clean, fast,
loud failure `opus` produces — it is a transport-layer non-answer. Not
reproduced as dead, not reproduced as live. Per user policy this is now listed
in `routing-defaults.json`'s `never_request` (worded as DEGRADED/UNVERIFIED,
not confirmed-dead) so it is excluded from automatic routing until a clean
re-test — with a longer watchdog (200s+) — settles it either way. This machine
now has exactly **one** confirmed-usable non-`sonnet` alias on `claude-api`
(none — both `opus` and `fable` are currently unroutable) and **one** on
`claude-openrouter` (`opus`); `sonnet` is the only alias confirmed live on
both seats today.

**Double-prompt re-confirmed with a real question, not a repeat of the ping.**
A genuine code-review question (analyze a specific function for a specific
class of bug) was dispatched to `claude-api`/`sonnet` and
`claude-openrouter`/`sonnet` in parallel (two background shell jobs, same
mechanism as the parallelism test above). Both succeeded; both gave correct,
independently-verified answers; and — new this time — **the two answers were
different, non-overlapping, and both valid**: each found a distinct real edge
case in the same 6-line block of code that the other did not mention. Total
wall-clock 103s against a slower-individual time of 102s, confirming the
concurrency claim still holds under a heavier, more realistic prompt (not just
the earlier one-line ping).

## Never read the seat settings by hand

`~/.claude-openrouter/settings.json` and `~/.claude-nvidia/settings.json` contain
live credentials. The launcher reads exactly one non-secret field
(`ANTHROPIC_DEFAULT_<TIER>_MODEL`) through a parser that touches nothing else.
Wrappers are forbidden from reading these files at all, and the probe prints the
alias map without ever loading a credential into a shell variable.

## Field notes 2026-09-30 (BlastWin planning run)

- `claude-api` `sonnet` (nvidia/nemotron-3-ultra-550b-a55b): read-only exploration tickets timed out at the 660–840 s watchdog in 3 of 4 tries (empty artifact, stderr `unrecognized_model`); the one success took 524 s. Treat it as slow/unreliable for repo-exploring or long-review tickets; use it only with a >=900 s timeout or for short tickets.
- `claude-openrouter` `opus` (thinkingmachines/inkling:free): reliable, 166–570 s, good adversarial reviews. `claude-openrouter` `sonnet` (poolside/laguna-s-2.1:free): timed out at 660 s with `unrecognized_model`; prefer `opus` on this seat.
- **Relay trap:** the wrapper (haiku) sometimes relays only a summary of the seat's result. In every review/plan ticket's OUTPUT FORMAT add: "Your FINAL message must contain ALL findings in full, never only a summary or a count", and tell the wrapper to relay the JSON `result` text verbatim; otherwise the detail is lost and you pay for a re-run.
- Gateway seats cannot write their own plan file in `plan` permission mode (the Write is denied and shown in `permission_denials`); the plan text is still in that denial — recover it from there, or ask for it in the final message.

> Note (2026-10-13): le seat `api` utilise maintenant le dossier `~/.claude-nvidia` et la commande `claude-nvidia` (config NVIDIA). Les scripts mappent `api` -> `nvidia`.
