# Routing: resolving capability classes to live models

The skill's policy never names dated model IDs. This file is the procedure for resolving FRONTIER / WORKHORSE / FAST to what exists on the user's account **today**.

## The LEAD seat

The session model is the **LEAD seat** — it runs you, the foreman. Do not assume it is frontier-class: sessions start on mid-tier models, org fallbacks, and cost-capped configs. If FRONTIER-class judgment work is on the plan and you cannot establish that the LEAD seat is frontier-class (from the session's own model identity), say so and suggest the user switch models — routing architecture decisions to a mid-tier seat while calling it FRONTIER violates the First Law with extra steps.

**Frontier is a class, not a single model.** The test is whether the LEAD seat clears the frontier bar, never whether it is the *most* capable model in the lineup. Every current top-tier Claude family qualifies, and the foreman behaves identically in each: same classes, same gates, same tickets, same verification. A frontier LEAD must never recommend switching to a *different* frontier model — that is churn dressed up as rigor. Reserve the switch recommendation for a LEAD seat that is actually mid-tier or below.

**The seat can change under you.** Claude Code may move a session to a different model mid-run — safety-classifier fallback (which can also pin the session to the new model for its remainder), quota exhaustion, org policy, or the user typing `/model`. Treat the Step 0 probe as cache with an invalidation rule, not a one-time fact. On any signal the identity moved, re-probe and write one ledger line: `LEAD seat changed: <old class> → <new class> — <trigger>`. Then:

- **Frontier → frontier** (e.g. a fallback between top-tier families): nothing to re-plan. Finish the run; in-flight tickets stay valid, because tickets are written against classes.
- **Frontier → mid-tier** (a real downgrade): stop before the next FRONTIER-class dispatch, tell the user the seat dropped, and let them choose — restore the seat, re-route that work to a frontier subagent, or accept a documented reduction. Never quietly keep making frontier-class calls from a mid-tier seat.

## Claude seats

- **WORKHORSE** = the `sonnet` alias; **FAST** = the `haiku` alias. **FRONTIER** is normally the LEAD seat itself, but frontier-class *workers* are dispatchable too — the Agent tool's `model` parameter accepts frontier aliases (`opus`, `fable`) alongside `sonnet` and `haiku`. Aliases track the latest release in each family automatically — new releases require zero skill edits.
- **When to spend a frontier worker** (the First Law still applies — this is the expensive seat): genuinely independent frontier-judgment workstreams that must run in parallel; a blind verifier for a frontier-class change when no Codex counterpart exists; or a second opinion on a decision the run hinges on. Not for implementation a WORKHORSE clears. An Opus lead dispatching Opus workers is ordinary routing, not an escalation — but it is the priciest crew you can field, so announce it like any other fan-out.
- Pass the model per dispatch via the Agent tool's `model` parameter (overrides agent-file frontmatter). Treat it as a *request*: runtimes may substitute if the org disallows a tier. A dispatch behaving far above or below its class is a *trigger to check provenance* (verification.md Layer 0) — behavior is never itself the provenance mechanism, in either direction: anomalous output doesn't prove substitution, and normal-looking output doesn't prove the requested seat served.

- The built-in `Explore` agent inherits the session model — from any frontier LEAD that is an expensive default for background scanning, and when LEAD and `Explore` resolve to the same model you are paying frontier rates to grep. Dispatch `foreman-scout` (FAST) instead. (With Codex present, model-matrix.md prefers `gpt-5.6-luna` for FAST work; the bundled scout is haiku-pinned — use it for sub-minute recon where wrapper overhead would exceed the saving, and a luna Codex dispatch for large mechanical sweeps.)

### The silent-fallback hazard

A routing request the runtime can't honor may be **silently replaced, not rejected** — the dispatch proceeds on a different model with no error surfaced. Documented field case (claudemix, 2026-08): a non-Claude model string passed *inline* in an Agent tool call was silently dropped and the subagent ran on a Claude model, while the same string in the agent file's `model:` frontmatter routed correctly (through their proxy). The hazard generalizes: org policy denials, decommissioned aliases, and unsupported tiers can all land as silent substitutions.

Empirical status in Claude Code (tested 2026-08-07, current build): an agent file pinned to a foreign model **with no proxy present** fails *loudly* ("Agent terminated early due to an API error"), and inline `model` values outside the supported enum are rejected at schema validation — neither path silently substituted in our tests. Treat that as the harness's current behavior, not a guarantee: the substitution class remains real across runtimes, builds, and org policies.

Countermeasures, in order: **(1)** route non-standard models via agent-file frontmatter, never inline strings; **(2)** treat every `model` parameter as a request; **(3)** close the loop with Layer 0 seat provenance (verification.md) — deterministic evidence of the served model, which converts a silent substitution from an invisible routing error into a logged, handleable event.

## Effort — use the controls that actually exist

Effort is a real dial, but only where a mechanism exists to set it. Per surface:

- **Codex workers**: set it explicitly per invocation — `-c model_reasoning_effort=<level>` (see codex-workers.md).
- **Claude subagents**: the bundled role files carry static defaults — scout `low`, worker `high`, verifier `high` — so a FAST scout never silently inherits an expensive session effort. If your harness offers a per-invocation effort control, it overrides these; if a model/effort combination isn't supported, the runtime falls back to the model's default — log what actually applied. Where no control exists, don't pretend: convey expected depth in the ticket ("mechanical batch edit; do not deliberate" / "reason carefully about the concurrency implications").
- Heuristics: low/minimal for mechanical work; provider default for normal work; deep effort only for hard verification and design. Raising effort on a cheap seat is often better economics than raising the tier — try it first for borderline tasks (precedence table row 2).

## Codex seats

Follow codex-workers.md: probe → consent → **discover the account's actual tiers** (config.toml preference, `/model`, or asking the user; documentation ≠ entitlement; IDs differ by auth mode) → verify each tier you intend to use with one tiny call → map verified tiers to classes by the provider's published positioning → record the mapping in the ledger (consent is skipped only when the probe reports the user's opt-in pre-approval — codex-workers.md).

Providers commonly ship flagship / workhorse / economy tiers, but treat that as a pattern to check, not an invariant. The user's configured default model is their *preference* — identify what it is before classifying it; a user who pinned the flagship as default did not thereby make the flagship your WORKHORSE.

> **Dated example — not policy.** As of 2026-07 the Codex flagship family was GPT-5.6: Sol (flagship), Terra (positioned "everyday workhorse"), Luna ("clear repeatable tasks"), with ChatGPT-account logins using suffixed IDs where API-key auth used bare ones (`gpt-5.6`). **That suffix rule is not an entitlement rule, and this example is not a routing recommendation:** measured on this machine 2026-08-26, `gpt-5.6-sol` returns HTTP 400 — *"not supported when using Codex with a ChatGPT account"* — while `gpt-5.6-terra` and `gpt-5.6-luna` work. A correctly-formed ID for your auth mode can still be one your plan cannot reach. By the time you read this, assume the lineup has changed — run the discovery procedure (codex-workers.md, "Discovering the account's tiers"), and probe each tier before relying on it.

## Grok seats

Follow [grok-workers.md](grok-workers.md): probe → note billing mode → tiers are
fixed and small (`grok-4.6` default, `grok-4.5`) → dispatch only through
`scripts/grok-dispatch.sh`.

- **Grok 4.6** — first-choice **FRONTIER-advisory** seat (adversarial review,
  second opinion) and a first-choice **WORKHORSE** seat for well-specified
  implementation. Never the accepting verifier verdict: its seat evidence is
  billed-tier, not served-tier (verification.md).
- **Grok 4.5** — lower-capability fallback. **No `xhigh`** — sending it exits 1.
- **The 200K cliff is a routing boundary, not a surcharge to absorb.** Grok
  reprices the *whole* request 2x above 200K — a jump that is certain from xAI's
  published policy. Which alternative then wins on cost is **not** established
  (Table 3): the comparison is list-price math, and measured Grok billing on a
  subscription ran far under list. Route away from the surcharge; do not assert a
  specific cheaper seat as fact. Above 500K Grok is ineligible outright. Apply it
  reactively, not by pre-counting tokens: the launcher reports the dispatch's
  average prompt size per model call and emits `CONTEXT WARN`/`CONTEXT ALERT`.
  **Reactive rule:** after a `CONTEXT ALERT`, do not send Grok another ticket
  that carries the *same context set or a superset* (same working files/paths
  plus the same or a longer resumed session) — that is a fact the foreman knows
  from what it put in the ticket. A fresh ticket with a smaller context set may
  still use Grok; when unsure, don't. A `CONTEXT WARN` means shrink the next
  ticket's context or split it. See model-matrix.md Table 3.
- Grok auto-discovers the user's Claude Code config (CLAUDE.md, skills, agents,
  MCP servers, hooks) by default. The launcher switches that discovery off at
  the source (`GROK_CLAUDE_*_ENABLED=false`) and pins the remaining
  countermeasures; never hand-compose a `grok` command that skips them. Grok
  still prepends its own system prompt and toolset (~19K tokens on this build
  with discovery off; ~28K with the user's Claude config discovered).

Ordinary budget discipline **does** apply to Grok; the user's opt-in Codex
pre-approval (SKILL.md Step 0 item 4) does not extend here.

## agy seats

Follow [agy-workers.md](agy-workers.md): probe (`agy --version` / `agy models`)
→ dispatch through the `foreman-agy-wrapper` subagent, or
`scripts/agy-dispatch.sh` directly, never a hand-composed `agy` call.

- **INVARIANT — the prompt travels in argv, never on stdin.** Piping the
  ticket into `agy` doesn't just drop `--model`; it silently swaps in the most
  expensive seat in the pool (Claude Opus 4.6, Thinking) while the ledger still
  records whatever cheap Gemini tier was requested — reproduced twice on
  2026-08-26, no error, no warning (agy-workers.md). `agy-dispatch.sh` passes
  the prompt as `agy --print "$PROMPT" --model "$MODEL" ...`; never
  "harmonize" it toward Codex's stdin-pipe shape. Because of this the whole
  ticket rides in one argv string, capped at 30000 bytes
  (`FOREMAN_AGY_ARGV_CEILING`) — oversize tickets are refused outright, not
  truncated; move bulk context to files and cite the paths.
- **No seat evidence exists for this transport, ever.** `agy --print` returns
  prose with no served-model field to check. Every dispatch is logged
  `seat: unverified` (Layer 0) and must never carry FRONTIER judgment or stand
  in as the accepting verification verdict — advisory/implementation seat
  only. The launcher's `WARNING:` block on a `"You're now using"` greeting is a
  suspicion tripwire, not evidence; its silence proves nothing.
- **Claude ids reached through agy are refused, not routed** —
  `claude-sonnet-4-6` and `claude-opus-4-6-thinking` appear in `agy models`
  but the launcher's allowlist blocks both; route Claude work natively
  instead.
- Tier mapping (agy-workers.md; cross-check against model-matrix.md before a
  long run, since that file is the shared source of truth for routing
  classes):

  | Routing class | Model id(s) |
  |---|---|
  | FAST | `gemini-3.7-flash-low` |
  | WORKHORSE | `gemini-3.7-flash-medium`, `gemini-3.7-flash-high` |
  | upper-WORKHORSE | `gemini-3.1-pro-high` |
  | FRONTIER | never — no seat evidence exists for this transport |

- Ordinary budget discipline applies; the Codex pre-approval (SKILL.md Step 0
  item 4) does not extend here (SKILL.md Step 0 item 6).

## Gateway Claude Code seats

Follow [gateway-seats.md](gateway-seats.md): the probe confirms the config
directory (`~/.claude-openrouter`, `~/.claude-nvidia`) exists — no new API key is
ever needed — then dispatch through the `foreman-openrouter-wrapper` /
`foreman-api-wrapper` subagents, or `scripts/claude-seat-dispatch.sh`
directly, never a hand-composed `claude` command or a hand-set
`CLAUDE_CONFIG_DIR`.

- **Not a completion endpoint — a full agent.** `claude-openrouter` and
  `claude-api` are the same Claude Code binary pointed at a different config
  directory; a dispatch has tools, file access, and the four-status contract,
  so these seats can hold implementation tickets, not just review.
- **The `opus`/`sonnet`/`haiku`/`fable` aliases do not name Claude models.**
  Each gateway maps them to a third-party model in its own `settings.json`
  (never read those files by hand — gateway-seats.md). Route by what the
  alias resolves to, never by the alias name, and never present the output as
  a Claude second opinion — the value of these seats is that they are an
  **independent model family** (model-matrix.md has the current alias map).
- **Evidence is billed-tier, never served-tier.** `--output-format json`'s
  `modelUsage` map is real evidence (better than agy's nothing) but it is the
  gateway's accounting, not a provider-served-model field, so it is logged
  `billed-tier` and can **never carry a verification verdict** (Layer 0, hard
  rail 5). The map routinely holds two keys (the model that ran the agent loop
  plus the small background titling model); evidence means **the id carrying
  the bulk of the input tokens is the expected one** — never mere presence. A
  presence test passes trivially for the `haiku` alias, because on this machine
  the background titling model *is* what `haiku` maps to.
- **`total_cost_usd` is not money here** — it prices the alias *tier* against
  Anthropic's table, not the gateway's. Measured 2026-08-26: a dispatch served
  entirely by `:free` models reported `total_cost_usd = 0.158`. Log token
  counts; mark any dollar figure `ESTIMATE` with its price table.
- **Routing floor: these seats cost 7.5k–29k input tokens before answering a
  one-word question** (the system prompt of a full agent) — never route a
  trivial question here; a native `haiku` subagent is cheaper and faster.
- **Never route either gateway at `haiku` — the alias is silently substituted.**
  Measured 2026-08-26 on both seats: the request answered correctly, but the
  token split shows the **`sonnet`-alias** model ran the agent loop
  (`nvidia/nemotron-3-ultra-550b-a55b` 15130 in vs `minimaxai/minimax-m3` 427 on
  `claude-api`; `poolside/laguna-s-2.1:free` 29113 in vs
  `cohere/north-mini-code:free` 79 on `claude-openrouter`). You get a model you
  did not ask for at a price you did not budget. The launcher now refuses the
  alias outright (claude-seat-dispatch.sh invariant 4).
- **Alias maps drift — re-verify, don't trust a date.** Live-tested 2026-09-25:
  `claude-api`'s `opus` (live 2026-08-26) is now dead (`z-ai/glm-5-3`, HTTP 404);
  `claude-api`'s `fable` (dead 2026-08-26) is now live
  (`deepseek-ai/deepseek-v4.1-flash`); `claude-openrouter`'s `fable` (live
  2026-08-26) is now dead (`stealth/ox-alpha`, HTTP 400, "testing period"
  ended). **Usable as of 2026-09-25: openrouter at `sonnet`/`opus`, api at
  `sonnet`/`fable`** — each seat currently has exactly 2 of 3 non-`haiku`
  aliases live. Re-run the live dispatch test (gateway-seats.md "Live
  capability audit") before trusting either direction on a future date.
- Ordinary budget discipline applies (SKILL.md Step 0 item 7).

### Router-local failover — a dead alias is a model failure, not a provider failure

Live-tested 2026-09-25 with the two naturally-dead aliases above: a dead alias
fails fast (~1-2s) and loud (`is_error: true`, a clear `result` message,
non-zero exit) — this is a **model-local** event. **Try the seat's other live
alias before concluding the provider itself is down.** Both gateways currently
have exactly one working non-`haiku` alias pair each (`sonnet` + one other), so
every job in routing-defaults.json that lists a gateway now lists both live
aliases in order. Log this distinction explicitly: `<seat>: model <X>
unavailable, stepped to model <Y>, success` — never `<seat> FAILED`, which
would incorrectly write off a seat that has a perfectly good second alias.
Only move to the *other* gateway (inter-provider fallback), or further down a
job's chain, once **both** of a seat's live aliases have failed in the same
run. **True full-seat exhaustion (both live aliases down) has not been
live-tested** — forcing it safely would require corrupting a live credential
file, which was judged out of bounds; treat the gateway-to-gateway hop as
structurally wired (the JSON lists it) but not yet empirically exercised.

The identical distinction applies to a **timeout**: live-tested 2026-09-25 (a
deliberately short watchdog against a normal-latency prompt) — exit 143, an
explicit `NOTE: the child was killed at the Ns watchdog — treat as TIMEOUT, not
as a model refusal` line. A timeout is a transport-layer event, not a verdict
on the model or the provider; retry the same alias once before drawing any
conclusion, and never log a timeout as a model or provider failure.

### Second opinion policy — when a double-prompt earns its cost

Live-tested 2026-09-25: the same read-only question dispatched in parallel to
`claude-api`/`sonnet` and `claude-openrouter`/`sonnet` (two independent Agent
tool dispatches, one wave, no sequencing) both returned correct answers,
independently verified by the LEAD against the actual repository content —
never accept a claim as correct merely because two seats agree; verify
code-related claims against the repo regardless. Confirmed genuinely parallel
(a separate live test: two simultaneous dispatches finished in wall-clock time
matching the slower one, not their sum).

**Use a double-prompt (AGY + a gateway seat, or two gateway seats) as a
`task-fit` deviation, not a default**, for task classes where a second,
independently-reasoning model family plausibly catches something a single pass
would miss: architecture decisions, hard debugging/root-cause analysis, a
diff/plan review before integration, choosing between competing
implementations, a security-relevant change, an economic/RTP-relevant change,
or explicit pre-HARD-dispatch or pre-integration validation. **Never spend a
second call on mechanical/obvious work** (forbidden_reasons already bars
"the job is small" as a reason to skip delegation; the same logic bars a
second call for a ticket with one obvious correct answer). The LEAD's job on
receiving two answers: compare them, flag any divergence explicitly, keep only
the verifiable elements, and — for anything code-related — check the actual
repository rather than trusting either model's claim, including when both
models happen to agree.

**Claude API/OpenRouter are not merely a fallback pool.** Confirmed usable for:
FAST/STANDARD implementation (already routed there behind AGY), cross-family
read-only review, a second opinion in parallel with AGY (above), a plan review
before a HARD-class dispatch, and an independent check before integrating a
HARD ticket's result. They remain **behind AGY**, not ahead of it — the
2026-09-25_v3 audit found them more resilient (intra-provider fallback) and
more broadly useful (double-prompt) than previously documented, but did not
find evidence that would justify promoting them ahead of AGY as the primary
pool; that would dilute the Codex-RESERVE/AGY-primary policy without a tested
reason.

**Re-audited 2026-09-28 — one correction, everything else held.** Re-ran the
2026-09-25 protocol live: `claude-api`/`opus` still dead (same error, unchanged),
`claude-api`/`sonnet` still live, `claude-openrouter`/`opus` and `/sonnet` still
both live, `claude-openrouter`/`fable` still dead (same error, unchanged).
`claude-api`/`fable` — reported live on 2026-09-25 — timed out twice today (a
90s watchdog, then a 150s retry per the timeout-retry rule above); not
reproduced as a clean failure like `opus`, not reproduced as live either.
Treated as **DEGRADED/UNVERIFIED**, not confirmed-dead, but excluded from
*automatic* routing the same way a confirmed-dead alias is (routing-defaults.json
`never_request`) until a clean re-test settles it — do not route here on the
assumption it still works, and do not assume it is broken either. Router-local
failover, genuine parallelism, and the double-prompt second opinion were all
re-confirmed live the same day with a fresh, real code-review question (not a
repeat of the 09-25 ping) — two independent gateway seats found two different,
individually-correct edge cases in the same function, neither of which the
other mentioned, which is the clearest evidence yet that this is a genuine
second *reasoning*, not a redundant check.

## Choosing the seat for a task

0. **Consult [model-matrix.md](model-matrix.md)** — the evidence table for price, capability, context limits, effort payoff, and task-type placement. This procedure decides *which class*; that table decides *which seat within it*, and records what each choice actually costs.
1. Classify the task's *judgment content*, not its size. A 500-line mechanical rename is FAST; a 10-line concurrency fix is FRONTIER.
2. Apply the First Law: cheapest seat that clearly clears the bar; unsure → one seat up.
2a. **Codex-RESERVE policy (2026-09-25_v2, user-directed — supersedes the 2026-09-25 v1 "reserve Codex for hard-coding" note).** The user reported real observed account usage: Codex >50% through a limited/free monthly quota; agy Pro ~4% and agy Flash ~6% of a 5-hour window; agy's bundled Claude tiers ~0% used. **These are user-stated policy inputs, not telemetry** — `agy --help` exposes no usage/quota/limits subcommand (verified live 2026-09-25), so nothing in this skill reads or computes them programmatically; when the user reports new numbers, this note and the job orderings in routing-defaults.json get updated by hand. Consequence: Codex is now **RESERVE, not a fallback tier** — it does not appear at all in `mechanical` or `standard-coding` anymore (v1 still had it as a late fallback there; v2 removes it), and even in `hard-coding` it sits at the very bottom, below AGY's POWER tier, the newly-audited Claude-in-AGY seats, Claude opus, Grok, and both gateway seats. Codex is reachable only: (a) automatically, when every seat above it in a chain has failed (the `no-frontier-implementation` and `hard-coding` jobs still list it, always last); or (b) via an explicit `provider-down`/`bar`/`user` deviation reason (allowed_deviation_reasons, unchanged) — never because a task is merely "hard-coding-shaped." AGY (including its Claude-bundled tiers, see below) is now the default pool for every WORKHORSE/FAST/POWER-tier task; Claude API/OpenRouter (`claude-api`/`claude-openrouter`) are the fallback pool behind AGY, not Codex.
2a-i. **Claude-in-AGY seats (`agy:claude-sonnet-4-6`, `agy:claude-opus-4-6-thinking`) — audited and unblocked 2026-09-25.** Previously in `never_request` on cost/evidence grounds (not a technical failure). Re-audited per the user's 6-point checklist: both dispatch successfully via direct `agy --print` (argv, plan mode — exit 0, correct proof string echoed, no eligibility error, no "You're now using" substitution-tripwire text); the original block was a policy choice, not an entitlement problem; nothing in NEVER_REQUEST's remaining technical entries applies to them. **They are ordinary AGY seats now, nothing more**: same `seat: unverified (Layer 0)` tag as every other agy dispatch, never eligible for `frontier-judgment` or the accepting `blind-verifier` verdict (those two jobs are untouched — model-matrix.md Table 5's "Never: agy" line still applies to these ids too), and never treated as the LEAD. They are believed (user's own account-structure statement, not independently verifiable) to draw on a separate Antigravity-bundled Claude allocation rather than the LEAD's own Claude Code subscription. Use `claude-sonnet-4-6` for hard general-purpose reasoning within `hard-coding`, `claude-opus-4-6-thinking` only if that still isn't enough — both sit below AGY's Gemini POWER tier in the routing card's fallback order, per the user's framing ("AGY Pro / Claude Sonnet AGY" as roughly co-equal, Opus AGY reserved for when it's "really necessary").
2a-ii. **AGY model rotation.** Within a class, rotate across generations of the same tier (e.g. `gemini-3.7-flash-high` → `gemini-3.7-flash-medium` → `gemini-3.8-flash-high` → `gemini-3.6-flash-high`) rather than always dispatching the same id — this is task-fit-then-observed-availability, never quota-balancing, since no per-model AGY quota is programmatically verifiable (agy-workers.md "Quota notes" and "Selecting among agy models"). A ticket that fails past its first AGY tier should be logged as "unavailable (503/timeout/BLOCKED), stepped to <next tier>" — never as "quota exhausted," which this skill cannot actually observe.
2b. **Effort before tier.** The payoff curve depends on task shape, not difficulty: analysis/review is nearly flat (medium ≈ high at 70-85% of cost), long-horizon coding is steep. Raising effort costs ~20%; raising a tier costs 2-5x. See model-matrix.md Table 4.
2c. **Claude workers drain the same allowance the foreman runs on**; Codex, Grok, agy (including its Claude-bundled tiers — user-stated separate allocation, see 2a-i), and the gateway seats (`claude-api`/`claude-openrouter`) do not — including when the gateway seats are serving the `sonnet`/`opus` alias, since that alias names a third-party model behind an independent credential, never the LEAD. For bulk implementation, prefer an off-family seat so the run itself lasts longer. This never licenses a seat that fails the task's bar — remaining allowance is not observable on any provider, so nothing here allocates quota.
3. Claude vs Codex vs Grok vs agy within a class: respect the Codex-RESERVE policy (2a) over raw cheapest-first; prefer cross-family pairing for build/verify; respect explicit user preference. Within agy itself, prefer the model tier that matches the task (FAST → `gemini-3.7-flash-low` family, STANDARD → `gemini-3.7-flash-high` family, POWER → `gemini-3.1-pro-high` or Claude-in-AGY) and rotate per 2a-ii — this is a task-fit choice, not a quota-balancing one, since no separate quota is known to exist per agy model (agy-workers.md "Selecting among agy models").
4. Log every routing decision in one ledger line: `task → class → seat (+effort if applied) — why`.

## Currency rule

If anything suggests your model knowledge is stale — an unfamiliar name from the user, an alias resolving oddly, an entitlement error on dispatch — verify against live provider docs or the account itself before routing. This repo's own first Codex dispatch failed on exactly this: a day-old model family, a CLI predating it, and an auth-mode ID split no static document had caught yet.
