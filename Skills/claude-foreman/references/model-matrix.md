# The model matrix — who gets the work, at what effort, at what cost

Companion to [routing.md](routing.md). routing.md is the *procedure* for resolving
classes to seats; this file is the *evidence table* that procedure consults.

**Read this first — what the dollars mean.** On a subscription-authenticated
account (ChatGPT login for Codex, grok.com login for Grok, a Claude plan for the
LEAD seat) these prices are **not** card charges. They are the best available
**proxy for how fast a dispatch depletes that provider's allowance**. They become
literal only on API-key auth. Never quote them to the user as money spent without
first establishing the auth mode (codex-workers.md, grok-workers.md).

**On this subscription the envelope reports a flat pool rate, not the API list.**
Measured 2026-08-17/18: eleven Grok dispatches (1–14 turns) all fit *exactly*
$0.34 input / $0.085 cache-read / $1.02 output per M — 0.17x the public list on
every bucket (5.9x below list-with-cache; an earlier draft said 3.5x, which
priced only cache-read+output and dropped the uncached tokens). Grok's docs say
`total_cost_usd` appears only when the server reports a complete cost, so this is
xAI's own accounting for OAuth/pool traffic (14-headless-mode.md:184). Read it as
a fixed internal rate — not as evidence about what the subscription *allowance*
costs, and there is no comparable measurement for Claude or Codex subscriptions.
Where an envelope reports a cost, record that number; use Table 1 only to compare
seats. The largest of them — the 6-turn plan review — moved 84.5K uncached +
285.6K cache-read input tokens and 18K output for $0.0714.

**The gateway Claude Code seats price against the wrong table entirely.**
`claude-openrouter` / `claude-api` bill the alias *tier* through Anthropic's
price table, not the gateway's — measured 2026-08-26: a dispatch served
entirely by `:free` models reported `total_cost_usd = 0.158` (gateway-seats.md).
Treat any dollar figure from these seats as fiction; log token counts only.
agy carries no cost data at all on this account — no verified rate-limit,
message-allowance, or per-call figures exist (agy-workers.md, "Quota notes") —
don't estimate one.

**Currency rule applies to this whole file.** Every number below is dated. Model
lineups move faster than skill files. If anything here disagrees with the live
provider docs or the account itself, the live source wins and this table is
stale — re-derive it, don't route off it.

## Table 1 — Seats, price, capability (verified 2026-08-17)

Capability = Artificial Analysis Intelligence Index v4.1.1, one consistent source
so the column is comparable. It is a **composite**, not a coding benchmark — see
the health warning under Table 4 before treating small gaps as real.

| Seat | In $/M | Out $/M | Cache read | Context | Index | Notes |
|---|---|---|---|---|---|---|
| Claude Opus 5 | 5 | 25 | 90% off | 1M | **63** | highest measured; no surcharge at any length |
| Claude Fable 5 | 10 | 50 | 90% off | 1M | 62* | *score unstable across index revisions (64.9 → 60 → 62) |
| Grok 4.6 | 2 | 6 | 75% off | 500K | **61** | **2x on the WHOLE request above 200K** |
| gpt-5.6-sol | 5 | 30 | 90% off | 1.05M | 61 | >272K: 2x in / 1.5x out — **NOT ENTITLED on this machine's ChatGPT login (HTTP 400, measured 2026-08-26)** |
| gpt-5.6-terra | 2 | 12 | 90% off | 1.05M | 57 | >272K surcharge as above |
| Grok 4.5 | 2 | 6 | 85% off | 500K | 56 | no `xhigh` — sending it is a hard error |
| Claude Sonnet 5 | 2 | 10 | 90% off | 1M | 55 | no surcharge ever |
| gpt-5.6-luna | 0.20 | 1.20 | 90% off | 1.05M | **52** | best value on the board by a wide margin |
| Claude Haiku 4.5 | 1 | 5 | 90% off | **200K** | 30 | 4096-token cache floor — short turns cache poorly |
| agy (Gemini family, via Antigravity) | unmeasured | unmeasured | unmeasured | unmeasured | unmeasured | no price/quota data exists on this account (agy-workers.md); **no seat evidence at all** — never FRONTIER, never a verification verdict |
| agy (Claude-bundled: `claude-sonnet-4-6`, `claude-opus-4-6-thinking`) | unmeasured | unmeasured | unmeasured | unmeasured | unmeasured | confirmed executable via `agy --print` (2026-09-25, agy-workers.md "Claude-in-agy seats"); believed to draw a separate Antigravity-bundled allocation, not the LEAD's Claude Code subscription — **user's own account-structure statement, unverifiable from here, not telemetry**; same "no seat evidence at all" caveat as the Gemini row above, unaffected by which model it happens to be |
| `claude-openrouter` (alias → 3rd-party model) | unmeasured | unmeasured | unmeasured | unmeasured | unmeasured | `total_cost_usd` prices the wrong table (measured $0.158 on an all-`:free` dispatch, 2026-08-26); alias map below; **billed-tier evidence only** |
| `claude-api` (alias → 3rd-party model) | unmeasured | unmeasured | unmeasured | unmeasured | unmeasured | same caveats as `claude-openrouter`; separate alias map below |

**Gateway alias map — these names do not resolve to Claude models.**
User-editable, and it has already drifted once (full detail, live-test evidence,
and the intra-provider-fallback/double-prompt/parallelism findings:
gateway-seats.md "Live capability audit"). Live-tested 2026-09-25 — re-run the
probe and the dispatch test before trusting this table on a future date:

| Alias | `claude-openrouter` | `claude-api` |
|---|---|---|
| `opus` | `thinkingmachines/inkling:free` — live | `z-ai/glm-5-3` — **dead (404), was live 2026-08-26** |
| `sonnet` | `poolside/laguna-s-2.1:free` — live | `nvidia/nemotron-3-ultra-550b-a55b` — live |
| `haiku` | `cohere/north-mini-code:free` — silently substituted, refused | `minimaxai/minimax-m3` — silently substituted, refused |
| `fable` | `stealth/ox-alpha` — **dead (400), was live 2026-08-26** | `deepseek-ai/deepseek-v4.1-flash` — **live, was dead 2026-08-26** |

**`haiku` is silently substituted on both seats — never route there** (unchanged
since 2026-08-26). **Usable combinations, live-tested 2026-09-25:**
`claude-openrouter` at `sonnet`/`opus`; `claude-api` at `sonnet`/`fable` — each
seat has exactly 2 of 3 non-`haiku` aliases live, which is the basis for the
intra-provider fallback policy (routing.md, gateway-seats.md).

**Routing floor:** both gateway seats consumed **7.5k–29k input tokens for a
one-word answer** (the system prompt of a full agent) — never route a trivial
question here.

## Table 2 — What one real dispatch costs

A 4-turn agentic dispatch: ~100K working context sent fresh once, ~300K re-sent
from cache across later turns, 12K output. This shape matters more than list
price, because caching dominates multi-turn work.

| Seat | Cost (no cache-write premium) | Index | Capability per dollar |
|---|---|---|---|
| gpt-5.6-luna | **$0.040** | 52 | **1287** |
| Claude Haiku 4.5 | $0.190 | 30 | 158 |
| Grok 4.5 | $0.362 | 56 | 155 |
| Claude Sonnet 5 | $0.380 | 55 | 145 |
| gpt-5.6-terra | $0.404 | 57 | 141 |
| **Grok 4.6** | **$0.422** | **61** | 145 |
| Claude Opus 5 | $0.950 | 63 | 66 |
| gpt-5.6-sol *(not entitled here)* | $1.010 | 61 | 60 |
| Claude Fable 5 | $1.900 | 62 | 33 |

Anthropic charges 1.25x base input on the first (cache-write) pass — verified on
the pricing page 2026-08-18 (2x for 1-hour TTL); Grok's envelopes report zero
cache-creation tokens (no write charge observed); OpenAI's write policy was
recorded by research as 1.25x but not primary-verified. With the Anthropic
premium applied to the 100K fresh pass: Haiku $0.215, Sonnet $0.430, Opus
$1.075, Fable $2.150 — Grok 4.6 ($0.422) then edges Sonnet rather than "landing
level"; no other conclusion changes. Cross-vendor per-token comparisons also
ignore tokenizer differences (Anthropic's 4.7+ tokenizer yields ~30% more tokens
than its 4.6-era one; vendor-to-vendor counts are not comparable) — treat Table 2
as ±20%.

Three conclusions that should drive routing:

1. **Grok 4.6 is the near-frontier value seat.** It sits in the same index band as
   Opus 5 and sol (61 vs 63 vs 61) at roughly **44% of Opus 5's depletion** and
   **42% of sol's**. State it as a band, not a ratio: per the health warning
   below, a 2-point composite gap is inside the noise, so "61 vs 63" licenses
   "same tier, far cheaper" and nothing more precise. That, not "Grok is cheap",
   is the reason to field it.
2. **gpt-5.6-luna dominates Haiku 4.5 outright** — cheaper *and* far more capable
   (52 vs 30), and Haiku's 4096-token cache floor means short agent turns often
   get no caching discount at all. Where Codex is available, luna is the FAST
   seat; Haiku is the fallback when it isn't.
3. **Sol and Fable are priced above their measured capability.** Sol costs 2.4x
   Grok 4.6 for the same index; Fable costs 2x Opus 5 while scoring at or below
   it. Field them for reasons other than capability-per-dollar — a specific
   strength, cross-family independence, or an unloaded pool — never by default.

## Table 3 — The Grok cliff is a routing boundary, not a price bump

Grok reprices the **entire request** at 2x once it crosses 200K, so cost jumps
discontinuously. Same job, 17% more input:

| Job | Grok 4.6 | Sonnet 5 | Verdict |
|---|---|---|---|
| 180K in / 15K out | **$0.450** | $0.510 | Grok wins |
| 210K in / 15K out | $1.020 | **$0.570** | Sonnet 44% cheaper (Grok costs 1.79x) |
| 250K in / 15K out | $1.180 | **$0.650** | Sonnet 45% cheaper (1.82x) |
| 400K in / 20K out | $1.840 | **$1.000** | Sonnet 46% cheaper (1.84x) |

**Rule: above ~200K, Grok loses its own cost advantage — change seats.** What is
certain is the *within-Grok* jump: xAI's published policy reprices the whole
request 2x, so the same job costs twice what it would have. What is **not**
established is the cross-provider winner: the table above is list-price math, and
this account's envelopes report a flat 0.17x-of-list pool rate (see the note
above) with no matching subscription measurement for Claude. So treat "Sonnet is
cheaper above the cliff" as a **list-price-relative** claim to confirm against
measured envelope costs, and treat "don't pay Grok's surcharge" as the rule.
Above 500K Grok is ineligible outright — that is a hard context ceiling, not a
price argument.

**How to apply this without counting tokens.** Estimating request size ahead of a
dispatch is unreliable (Grok prepends its own system prompt and toolset — ~19K
tokens on this build with Claude-config discovery off, ~28K with it on), so
measure after the fact instead. The json envelope reports summed *uncached* input
separately from cache reads, so `grok-dispatch.sh` derives the **average prompt
size per model call** (uncached + cache-read + cache-creation, divided by
`num_turns`) rather than reading `input_tokens` raw, and emits `CONTEXT WARN` /
`CONTEXT ALERT` off that. Ledger the number. **Reactive rule:** the launcher
reports the dispatch's average prompt size per model call. After a
`CONTEXT ALERT`, do not send Grok another ticket that carries the *same context
set or a superset* (same working files/paths plus the same or a longer resumed
session) — that is a fact the foreman knows from what it put in the ticket. A
fresh ticket with a smaller context set may still use Grok; when unsure, don't. A
`CONTEXT WARN` means shrink the next ticket's context or split it.

## Table 4 — Effort: a volume dial, and it pays off unevenly

Verified for all three providers: **raising reasoning effort never changes the
per-token price.** It changes how many reasoning/output tokens get generated,
billed at the ordinary output rate. Effort therefore multiplies the *output* half
of the bill — the expensive half on every seat in Table 1.

**The finding that should drive effort choice — the payoff depends on task shape,
not on difficulty alone.** Anthropic publishes the only quantified curve (PRIMARY,
2026-08-17), and the two shapes diverge sharply:

| Task shape | Accuracy-vs-effort curve | What to do |
|---|---|---|
| Analysis / knowledge work / review (WideSearch, GDPval, BrowseComp) | **nearly flat** — `low` gives up only 1-3 points for 33-50% less cost; `medium` matches `high` at 70-85% of cost | **default `medium`**; top effort is usually wasted money |
| Long-horizon coding (SWE-bench Pro) | **steep** — `low` gives up ~8 points | **default `high`**; do not economize here |

Anthropic's own framing: "Long-horizon coding is the other shape." Treat this as
measured on Anthropic models; the shape is a strong prior for other families, not
a proven transfer.

xAI's own published level guidance (PRIMARY, docs.x.ai) points the same way —
note that `medium`, not `high`, is the level it names for analysis:

| Grok level | xAI says it is for |
|---|---|
| `low` | latency-sensitive work, simple tool calls |
| `medium` | **complex data analysis and long-context reasoning** |
| `high` (default) | hard math, multi-step logic |
| `xhigh` | the hardest problems only |

OpenAI grades `none`→`max` by latency tolerance and difficulty, not by task
category. No vendor draws an explicit review-vs-build line.

| Surface | Levels | Default to | Escalate when |
|---|---|---|---|
| Grok 4.6 | low, medium, high, xhigh | **medium** for review/analysis, **high** for implementation | `xhigh` only for the hardest verification/design |
| Grok 4.5 | low, medium, high (**no xhigh**) | same, capped at high | — sending `xhigh` exits 1 |
| Codex | per codex-workers.md | provider default | hard debugging, final review |
| Claude subagents | scout low / worker high / verifier high | role default | per delegation.md |

The one hard tradeoff number anyone publishes: Grok `xhigh` vs `high` on
CursorBench buys **+0.9pp accuracy for +20% cost** (69.9% → 70.8%; SECONDARY,
cross-corroborated, absent from primary xAI pages). Combined with the flat
analysis curve above, `xhigh` on a review is close to pure waste.

Per routing.md: **raising effort on a cheap seat is often better economics than
raising the tier** — a tier step costs 2-5x (Table 2), an effort step ~20%. That
holds best on coding-shaped work, where the effort curve is steep.

## Table 4b — Grok as reviewer: supported, with a hard operating rule

Review work is reasoning-heavy and output-light. Measured on this account: an
adversarial plan review by Grok 4.6 billed **18,044 output tokens of which 14,579
(81%) were reasoning**. So the seat choice for deep review is dominated by output
price — which is where Grok is cheapest relative to capability: the same review
priced **2.4x on Opus 5, 2.7x on sol, 4.7x on Fable 5**, at index 61 vs 63/61/62.

Benchmark support is real but indirect (SECONDARY): Grok 4.6 **wins** knowledge-
work evaluations (GDPVal-AA, Harvey legal) and **loses** software-engineering
execution ones (DeepSWE -7.1pts, Terminal-Bench -8.6pts vs sol). That is
consistent with "relatively stronger at analysis than at execution" — it is not
proof, no code-review benchmark exists for any model, and some practitioner
reports argue the opposite. Do not overstate it.

> **Hard operating rule — verify a Grok reviewer's citations before acting.**
> Grok 4.6's measured non-hallucination rate is **65.7%** (SECONDARY): when
> uncertain it invents an answer roughly one time in three. That is a genuine
> hazard in a critic. Live evidence from this account cuts both ways — in a real
> plan review its quotations of this skill's own rules checked out verbatim
> against the files, and it caught a true self-contradiction; it also asserted an
> event "does not exist" when the event was simply outside its sandbox. So:
> **treat Grok findings as leads with citations attached, and confirm each
> against the named file or line before you act on it.** This is exactly why
> Grok is an advisory reviewer and never the accepting verdict (Table 5).

## Table 5 — Task type to seat

Judgment content decides the class (routing.md); this maps class to a first-choice
seat once economics is allowed to choose among seats that already clear the bar.
**The First Law is not suspended here:** if no listed seat clears the bar for a
task, go up a tier or stop — never take the cheap row because it is cheap.

> **Policy overlay, 2026-09-25_v2 — Codex-RESERVE (routing-defaults.json is
> authoritative — this table is evidence, not the live routing card; supersedes
> the same-date v1 note below the fold).** The rows below still describe
> *measured capability-per-dollar* as of 2026-08-17/26 — Grok 4.6 and
> `gpt-5.6-luna` are still the cheapest-per-call seats for WORKHORSE/FAST work
> on paper, unchanged. What changed by user direction, twice now in one day, is
> the **routing priority**, driven by real observed account usage the user
> reported (Codex >50% of a limited monthly quota already spent; agy Pro ~4%
> and agy Flash ~6% of a 5-hour window; agy's bundled Claude tiers ~0% used —
> **user-stated policy inputs, not telemetry**: `agy --help` has no usage/quota
> subcommand, checked live 2026-09-25). Consequence: `mechanical`,
> `standard-coding`, AND `hard-coding` (below Table 5, in routing-defaults.json)
> now all default to **agy** — including, in `hard-coding` only, the newly
> audited-and-enabled Claude-bundled agy seats (`claude-sonnet-4-6`,
> `claude-opus-4-6-thinking` — agy-workers.md "Claude-in-agy seats"; still
> ordinary unverified agy seats, never the LEAD, never eligible for the two
> "Never: agy" rows in this table). **Codex is RESERVE**, not merely
> deprioritized: it no longer appears at all in `mechanical`/`standard-coding`,
> and even in `hard-coding` it is the last-listed fallback, below AGY's POWER
> tier, Claude-in-AGY, Claude opus, Grok, and both gateway seats — reachable
> automatically only once everything above it has failed, or via an explicit
> `bar`/`user` deviation. `claude-api`/`claude-openrouter` remain the fallback
> pool behind AGY, never the first choice and never a stand-in for the LEAD.
> See routing.md "Choosing the seat for a task" step 2a/2a-i/2a-ii and
> agy-workers.md "Selecting among agy models" for the live procedure.

| Task | Class | First choice | Then | Never |
|---|---|---|---|---|
| Architecture, ambiguous debugging, final judgment | FRONTIER | LEAD (whichever frontier-class model holds the session) | frontier subagent | Grok, luna, Haiku |
| Accepting verdict on a change (blind verifier) | FRONTIER | **Claude verifier** — always the acceptor. A **Codex read-only reviewer** is the strongest available cross-family *second opinion* (verification.md), never the acceptor | — | **Grok, agy, and the gateway Claude Code seats**, and any off-family seat *as acceptor* — Grok and the gateway seats are billed-tier and agy has no seat evidence at all, so none of the three ever leads with a verdict (grok-workers.md, agy-workers.md, gateway-seats.md) |
| Adversarial review / second opinion | FRONTIER-advisory | **Grok 4.6 @ medium** (Table 4: review curves are flat; escalate to `high` only when the review is itself long-horizon) | Codex sol | — |
| Well-specified implementation, tests, refactors | WORKHORSE | **Grok 4.6 @ high** (<200K) when cost dominates; **terra** (Codex mid tier — the class table's Codex WORKHORSE seat) otherwise; step up to **sol** only when agentic-execution reliability dominates (First Law: unsure → one tier up) — the only measured head-to-head shows Grok trailing *sol* on DeepSWE and Terminal-Bench (Table 4b). No comparable execution measurement exists for Sonnet 5, whose only cross-model number here is the composite index (where Grok leads 61 to 55) — so do not pick Sonnet over Grok on reliability grounds this table cannot support. | Sonnet 5 / terra on pool grounds | — |
| Large-context implementation (>200K) | WORKHORSE | **Sonnet 5** | terra | **Grok (cliff)**, Haiku (200K cap) |
| Mechanical edits, extraction, scanning | FAST | **gpt-5.6-luna @ low** | Haiku 4.5 | frontier seats |
| Repo-wide sweep (>500K) | any | Claude or Codex (1M ctx) | — | **Grok (500K ceiling)** |
| Trivial one-line/one-word question | FAST | native `haiku` subagent (Claude) or `gpt-5.6-luna @ low` | — | **Gateway seats** (`claude-openrouter`/`claude-api`) — measured 7.5k-29k input tokens for a one-word answer, the system prompt of a full agent (gateway-seats.md) |
| Implementation ticket, Codex and Grok both absent | WORKHORSE | **Gateway seat** at `sonnet` alias or above (full agent, can implement) | agy `gemini-3.7-flash-high` / `gemini-3.1-pro-high` (`workspace-write`) | **either gateway at `haiku`** — the alias is silently substituted to the `sonnet`-alias model (gateway-seats.md); also `claude-api` + `opus` (HTTP 404 `unrecognized_model`, re-confirmed 2026-09-28) and, pending re-test, `claude-api` + `fable` (DEGRADED/UNVERIFIED — 2 consecutive timeouts 2026-09-28, not confirmed dead like `opus`; see `never_request`) |
| Cross-family advisory review, Codex and Grok both absent | FRONTIER-advisory | **Gateway seat** (independent third-party model family, billed-tier evidence) | agy advisory (`gemini-3.1-pro-high`, `seat: unverified`) | either as the accepting verdict (Layer 0 — see row above) |
| Second opinion: architecture, hard debugging, plan/diff review, implementation choice, security/economic-relevant change, HARD-class pre-dispatch/pre-integration check | advisory, alongside the primary seat | **AGY (primary) + a gateway seat in parallel** (`claude-api`/`claude-openrouter` at `sonnet`, live-tested 2026-09-25 — routing.md "Second opinion policy") | two gateway seats in parallel if AGY is unavailable | as a default for mechanical/obvious work — the second call must be a deliberate `task-fit` deviation, never routine |

> **On "FRONTIER-advisory" — what that row does and does not grant.** A billed-tier
> seat never carries class-sensitive *authority* (verification.md): it cannot make
> a seat `verified`, cannot supply an accepting verdict, and cannot be the
> FRONTIER judgment a decision rests on. What it can do is *produce findings* that
> a frontier seat then adjudicates. "Advisory" names that asymmetry — the seat
> argues, the foreman decides, and nothing is accepted on the strength of the
> advisory seat alone. If you catch yourself accepting a change *because* the
> advisory reviewer approved it, that is the smuggle this note exists to stop.

## Table 6 — Which pool a seat drains

Claude workers draw on **the same allowance the foreman itself runs on**; Codex
and Grok workers do not. That is the one genuine endurance asymmetry, and it is
the only "pool" consideration this skill makes — remaining allowance is **not
observable** on any provider, so nothing here allocates quota.

| Seat | Pool | Consequence |
|---|---|---|
| Claude (LEAD + subagents) | the foreman's own | heavy Claude fan-out shortens the run itself |
| Codex | ChatGPT subscription, weekly rolling window | independent; exhaustion is abrupt and has happened |
| Grok | grok.com account | independent third pool |
| agy | Google/Antigravity account | independent fourth pool; no verified rate-limit, allowance, or per-call cost figures exist on this account — journal spend under ordinary budget discipline rather than a number (agy-workers.md, "Quota notes") |
| Gateway (`claude-openrouter`, `claude-api`) | the gateway's own credential behind `ANTHROPIC_BASE_URL`, not the LEAD's Claude Code subscription | independent pool from Claude/Codex/Grok/agy; `total_cost_usd` does not reflect this pool's real metering, so depletion cannot be read off the dollar figure (gateway-seats.md) |

**Use:** prefer an off-family seat for bulk implementation so the LEAD pool lasts.
When a pool is *known* down, re-route the remainder and journal it. This never
licenses a seat that does not clear the task's bar — a dead pool is a reason to
stop and tell the user, not to accept weaker work (delegation.md, First Law).

## Provenance of this table
- Prices, context windows, cache discounts, effort mechanics: primary vendor docs, 2026-08-17.
- Capability index: Artificial Analysis Intelligence Index v4.1.1, 2026-08-17.
- Grok CLI behaviours (cliff handling, effort validation, envelope usage fields): established by direct execution on this machine, 2026-08-17.
- agy (Antigravity/Gemini) seat facts — argv-only invariant, no seat evidence, tier mapping, quota unknowns: direct execution on this machine, 2026-08-26 (agy-workers.md). No price/capability data exists for this transport; Table 1's agy row is deliberately blank.
- Gateway Claude Code seat facts (`claude-openrouter`/`claude-api`) — alias maps, billed-tier evidence, `total_cost_usd = 0.158` on an all-`:free` dispatch, the 7.5k-29k token routing floor, the `haiku` silent-substitution measurement on both seats, and the `claude-api`+`fable` 404: direct execution on this machine, 2026-08-26 (gateway-seats.md). No comparable price/capability data exists; Table 1's gateway rows are deliberately blank.
- Cost tables: computed from the above; recompute rather than trusting if any input changes.
