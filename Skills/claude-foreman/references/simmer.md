# Simmer: goal-seeking loops and cost receipts

Two additions to the base ticket-and-ledger model, both borrowed from the sous-chef plugin: a bounded iterate-until-judged-done loop for goals that don't reduce to a single gradeable ticket, and a per-dispatch cost receipt that makes delegation's savings claim checkable instead of asserted.

## Part A — Simmer: the goal-seeking loop

### When to reach for it, and when not to

Most tasks fit the base ticket contract (delegation.md): EXPECTED OUTCOME is gradeable before dispatch, one worker executes, one verifier checks it, done. Simmer is for the narrower case where the acceptance bar is real but the *path* to it isn't known up front — "get this suite green," "get this benchmark under 200ms," "make this brief-compliant" — where the first attempt is expected to fall short and the next ticket depends on what the last one revealed. If you can write the acceptance check today, use a normal ticket; simmer's iteration cost isn't worth paying for a goal you already know how to grade in one pass.

Simmer is not an escalation path. A goal that keeps failing for a *fixable* reason (bad ticket, wrong seat) still runs through the precedence table (delegation.md) inside each iteration — simmer wraps the outer loop, it does not replace the retry rules.

### The goal contract

Declared once, before iteration 1, and never rewritten mid-loop:

```
GOAL:        <the user's original words, verbatim — never a restatement>
ACCEPTANCE:  <the observable condition that ends the loop successfully>
BUDGET:      <max iterations — default 5>
WRITE SET:   <same meaning as a ticket's WRITE SET, fixed for the whole loop>
```

The verbatim requirement matters more here than in a single ticket: every judge call re-reads GOAL, not a summary of it, so drift can't compound the way it does when each pass re-derives from the last pass's prose.

### The default budget: 5 iterations, and the termination guarantee

Five is the reference point (sous-chef's default) and a default, not a law — declare it in the goal contract before the first dispatch so exhaustion has a known meaning instead of being discovered mid-run. One iteration = one worker dispatch plus one judge verdict. Raising BUDGET mid-run is a cost decision the foreman states out loud, like any fan-out — never something that happens silently because 5 wasn't enough.

**Termination guarantee.** The loop halts on exactly one of three conditions, and no other exit exists:

1. The judge returns `PASS` — success.
2. The iteration counter reaches BUDGET without a `PASS` — budget exhausted (below).
3. The foreman determines the goal is underspecified — stop and ask (below).

Every iteration consumes exactly one budget unit regardless of outcome, and the counter is checked before every dispatch, so the loop cannot run unbounded even if the judge or worker misbehaves.

### The loop body

1. Foreman writes a ticket for this pass (7 core sections + WRITE SET, delegation.md) — scoped to what the *previous* judge verdict said was still wrong, not the original goal restated from scratch.
2. Worker executes, reports a status (`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED` — SKILL.md).
3. Deterministic checks run first, same as any other change (verification.md Layer 1).
4. The simmer judge evaluates against GOAL and ACCEPTANCE and returns `PASS` / `FAIL` / `PASS_WITH_NOTES`.
5. The iteration is appended to the ledger (below) whether it passed, failed, or the worker reported `NEEDS_CONTEXT`/`BLOCKED` — a skipped iteration is an unrecorded budget unit, which breaks the resumability guarantee.

### The judge is a verifier, not a new role

The simmer judge reuses verification.md's blind-verifier contract exactly — it does not get its own vocabulary:

- **Fresh context** each call, no memory of prior iterations' reasoning (it may read the ledger's factual rows, never a worker's prose summary of them).
- **The original GOAL, verbatim** — never the worker's restatement of what it did, for the same anchoring reason verification.md gives for ticket verifiers.
- **No edit tools.** A judge that fixes what it's judging collapses the same way a self-repairing verifier does (delegation.md, "The verifier never edits").
- **Verdict vocabulary is `PASS` / `FAIL` / `PASS_WITH_NOTES`**, identical semantics to verification.md — `PASS_WITH_NOTES` only when every required acceptance criterion passed and the notes concern non-required observations.
- Where both providers are available, verification.md's cross-family pairing preference applies to the judge exactly as to any other verifier: don't have the seat that authored an iteration also judge it.

One addition specific to simmer: the judge also reports whether the *shape* of the failure changed since the last iteration (same defect, different defect, no defect but goal still unmet). That signal is what the disagreement rule below reads, and it's what tells the foreman whether iteration 4 is converging or thrashing.

### Ledger integration and resumability

Every iteration is an Attempts row (delegation.md's schema — simmer adds no parallel table). The row's `attempt #` doubles as the iteration index, and BUDGET is recorded once in `## Decisions` at loop start so it is checkable without re-deriving it. Resuming after compaction follows the same rule as any ledger resume (delegation.md, closing paragraph): read the ledger, reconcile against `git status`/diff and any still-running jobs, then resume from the next unconsumed iteration — never restart the count from 1, and never trust a ledger row you cannot confirm against the tree.

### The three failure modes, handled explicitly

- **Budget exhausted without a `PASS`.** Stop. Report to the user with the full Attempts history for the loop (not just the last iteration) and the judge's last verdict. Do not silently raise the budget and keep going — that is the degradation rule's silent-downshift problem run in reverse; raising BUDGET is a visible, journaled decision stated before it is made, same as any fan-out.
- **Judge and worker disagree repeatedly** — worker reports `DONE`, judge returns `FAIL`, on the *same* underlying claim, more than once. This is precedence table row 5 wearing a different hat: two consecutive failed passes against the same findings is a stop condition, not a retry trigger. Stop, report both the worker's evidence and the judge's evidence, and let the user adjudicate — do not keep re-dispatching hoping the next pass agrees with the last.
- **The goal turns out to be underspecified** — the judge cannot produce a verdict because ACCEPTANCE doesn't actually resolve the question (two iterations satisfy its letter while disagreeing on the outcome). This is not a budget problem; more iterations do not fix it. Stop immediately, even mid-budget, and ask the user to sharpen ACCEPTANCE. Looping harder against an ambiguous target burns budget without narrowing anything — the same principle as delegation.md's rule that a bad ticket gets fixed, not retried blind.

### What simmer does not change

Never a third identical retry within an iteration's own worker dispatch — delegation.md's precedence table governs that exactly as it does outside simmer; this file does not restate it. Parallel-dispatch rules, WRITE SET discipline, and the finding contract all apply unchanged inside each iteration's ticket. Simmer only adds the outer judge-and-loop wrapper.

## Part B — Cost receipts

### What a receipt is for

Delegation's pitch is that cheaper seats save money without lowering the bar. That claim is currently asserted, not shown. A cost receipt is a small, per-dispatch record that lets a run answer "what did the crew actually cost, and what would the same work have cost on the LEAD seat" with recorded fields instead of a narrative estimate after the fact.

### Be honest about what each transport actually exposes

Not every seat reports the same thing, and the receipt schema has to reflect that rather than paper over it:

| Seat | What's actually measurable | What's not |
|---|---|---|
| Claude subagents (opus/sonnet/haiku aliases) | Harness dispatch metadata: requested model, wall-clock duration, exit/completion state | Token counts and dollar cost are not reliably surfaced per dispatch by the harness today |
| Codex CLI (gpt-5.6-terra etc., ChatGPT-subscription billing) | `--json` event stream: thread id, wall-clock duration, exit code | No served-model field (verification.md Layer 0) and no reliable token or dollar figures in the stream |
| agy / Antigravity (Gemini, subscription-metered) | Plain-prose completion signal, wall-clock duration, exit status | No structured usage or cost output at all |
| Gateway Claude Code seats (`claude-openrouter`, `claude-api`) | `--output-format json`: **real per-dispatch token counts** (`input_tokens`, `output_tokens`, cache fields) plus a `modelUsage` map of billed ids | A trustworthy dollar figure — see below |

**The gateway seats are the one place a receipt carries measured tokens, and the one place the transport hands you a dollar figure that is wrong.** Measured 2026-08-26: a `claude-openrouter` dispatch served entirely by `:free` models reported `total_cost_usd = 0.158`. Claude Code prices the *alias tier* against Anthropic's table and knows nothing of the gateway's rates, so the figure is wrong in both directions. **Record the token counts; never copy `total_cost_usd` onto a receipt as money.** If a dollar figure is wanted for these seats, derive it from the measured tokens against the gateway's published price for the id in `modelUsage`, and mark it `(ESTIMATE)` like every other dollar field.

The same measurements give a routing floor worth writing down: those seats burned 7.5k–29k input tokens to answer a *one-word* prompt, because every dispatch pays for a full agent's system prompt. A receipt showing a trivial question routed to a gateway seat records a routing bug, not a saving.

No transport surfaces a dollar figure worth trusting. The receipt records what each one *can* give: seat, requested model, duration, exit status, artifact size (lines changed, bytes written — a proxy for volume, not for cost), and, where the transport reports them, measured token counts. Dollar figures are computed afterward from a price table, never read off the transport, and every dollar field on a receipt is marked `(ESTIMATE)`.

### Receipt fields (per dispatch)

A receipt is not a new ledger table — it is an additive set of fields appended to the existing Attempts row for that dispatch (delegation.md's `## Attempts` schema; see that file's edit for the exact line format). Fields:

| Field | Source | Measured or estimate |
|---|---|---|
| seat | ticket routing decision | requested (Layer 0 provenance rules still apply — a receipt is not a provenance claim) |
| requested model | dispatch parameter (`-m`, `model:`, alias) | requested |
| wall-clock duration | dispatch start/end timestamps, foreman-recorded | measured |
| exit status | process exit code / harness completion state | measured |
| artifact size | lines/bytes of the diff or report produced | measured |
| token counts | `usage` in the dispatch artifact — gateway seats only; omit the field entirely on transports that do not report it, rather than writing a guess | measured |
| iteration index | attempt # (or simmer iteration #, inside a simmer loop) | measured |
| cost estimate | seat + requested model + a volume proxy (duration or artifact size), looked up against model-matrix.md's dated price table | **ESTIMATE — mark it as such on every row, never as measured** |
| LEAD counterfactual | the same volume proxy, priced at the LEAD seat's rate from model-matrix.md | **ESTIMATE — a comparison baseline, not a measurement of what the LEAD seat would actually have done** |

model-matrix.md is the only source of pricing numbers this file cites; do not hardcode a price here — the matrix is dated and updated independently of this reference.

### What a receipt does not claim

A receipt does not establish seat provenance (that is Layer 0's job, verification.md) and does not substitute for it — "seat" on a receipt is the requested seat, same caveat as everywhere else in this skill. It does not claim precision the transport cannot deliver: Codex and agy receipts have no token-level or billed-dollar figures because none exist to read, and deriving one from duration alone would be a fabricated number wearing a real-looking column. The LEAD counterfactual specifically is a modeled comparison — "what a frontier LEAD would likely have spent on this volume of work at the LEAD seat's price" — not a run that was ever executed, and it must be labeled that way wherever it is reported to the user.

### Reporting the savings claim

At the end of a run (or a simmer loop), sum receipts across the ledger's Attempts rows: total wall-clock and exit-status record per seat, total estimated delegated cost, total estimated LEAD-counterfactual cost — carrying the estimate flag into the summary, not dropping it. A run summary that reports "saved $X" without the ESTIMATE qualifier is misrepresenting a modeled number as a measured one; don't do that even when the number would otherwise look clean.
