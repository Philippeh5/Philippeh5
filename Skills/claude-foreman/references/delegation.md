# Delegation: tickets, statuses, escalation, ledger

## The ticket: 7 core sections + WRITE SET

Workers start with a fresh context. The ticket must carry everything; if the worker would need to ask a question, the ticket is incomplete.

```
TASK: <the task — for verifier tickets, the user's ORIGINAL words verbatim>
EXPECTED OUTCOME: <observable definition of done, gradeable before dispatch>
CONTEXT: <file PATHS to read; current state; background>
CONSTRAINTS: <stack, patterns, performance/compat requirements>
MUST DO: <non-negotiables, incl. the exact verify command to run>
MUST NOT: <the fence — files/scope off limits; no subagent spawning>
OUTPUT FORMAT: <the role's report contract: status-first for execution roles,
              verdict-first for verifier tickets — see the vocabularies below>
WRITE SET: <every file/glob this worker may create or modify — MANDATORY on
           every implementation ticket; omit only for read-only roles>
```

Inline-vs-path rule: short essentials go **inline verbatim** — the task text, acceptance criteria, a verifier's findings being handed to a fix worker. Bulk material — logs, diffs, generated docs, source files — travels as **paths** (workers read files themselves; artifacts go to `.foreman/scratch/`). A measured failure mode: a 42k-character dispatch prompt that was 99% pasted history.

One task per ticket. EXPECTED OUTCOME must be gradeable — if you can't write the acceptance check, you're not ready to delegate.

## Parallel dispatch

Only for genuinely independent tickets, and only with **provably disjoint write sets**:

1. Compare WRITE SET declarations across the wave — any overlap, including shared manifests, lockfiles, and generated files → serialize those tickets or give each worker worktree isolation (`isolation: worktree` where supported).
2. Snapshot the baseline first: current commit hash + `git status --porcelain` output into the ledger. Every reconciliation afterward is a diff against this baseline.
3. **Independent tickets launch as one wave, not a queue.** The old "sequential remains the default" rule is inverted (SKILL.md Budget discipline): when write sets are disjoint and no ticket consumes another's output, dispatch them together — parallel spends other pools' tokens, while a sequential queue spends the LEAD's turns holding each worker's hand. Serialize only on write-set overlap, a real data dependency, or a consent gate that applies to only part of the wave.

## The three vocabularies (do not mix them)

**1. Worker status** — the first line of every **execution-role** report (worker, scout — Claude or Codex alike). Verifier reports use vocabulary 2, never this one:

| Status | Meaning | Foreman's move |
|---|---|---|
| `DONE` | Complete, with evidence (commands run + results, files touched) | Deterministic checks → verifier |
| `DONE_WITH_CONCERNS` | Complete, risks flagged | Resolve every concern before accepting; correctness concerns → fix now |
| `NEEDS_CONTEXT` | Missing information; no risky guesses made | Supply it; re-dispatch same worker, same seat |
| `BLOCKED` | Cannot proceed | Triage below |

**2. Verifier verdict** — `PASS` / `FAIL` / `PASS_WITH_NOTES` (verification.md), the **first line** of every verifier report regardless of which provider runs the verifier. A verdict is not a status; it grades a change, not a worker.

**3. Ledger lifecycle** — per task: `PENDING → DISPATCHED → REPORTED(status)`, branching on the status: `NEEDS_CONTEXT` → back to `PENDING` with a corrected ticket; `BLOCKED` → `PENDING` (re-route per the precedence table) or terminal `FAILED` if surfaced to the user. For `DONE`/`DONE_WITH_CONCERNS` (concerns resolved), the terminal path depends on the task type:

- **Implementation tasks** → `VERIFYING → VERIFIED | FAILED`. `VERIFIED` requires a `PASS` (or a `PASS_WITH_NOTES` whose notes you resolved); a `FAIL` verdict → `FAILED` + fix wave.
- **Read-only tasks** (scout, advisory) → terminal `ACCEPTED` once the foreman has consumed the report — there is no diff to verify.
- **Discipline modes** → terminal `SELF_REVIEWED` after the distinct self-review pass; never recorded as `VERIFIED`.

`LOST` = dispatched, never reported.

`BLOCKED` triage, in order: **(1)** Bad ticket (ambiguous, missing constraint) → fix ticket, same seat. **(2)** Capability gap → consult the precedence table. **(3)** External blocker (credentials, permissions, failing dependency) → surface to the user; do not work around it.

Reports are claims. Accept evidence — file:line references, command output, red-to-green transitions. Hedge language ("should work", "probably") is treated as a failure to verify.

## LOST workers and partial edits

A worker that hasn't reported within a reasonable bound for its task class, or whose process died:

1. **Prove it stopped first.** Check the recorded job's state; if it may still be running, terminate it and confirm a terminal state (exit code, dead process). Reconciling or retrying against a possibly-live worker creates exactly the concurrent-write race the WRITE SET rules exist to prevent.
2. Mark `LOST` in the ledger. Record what you know (job ID, artifact paths, exit code).
3. **Reconcile after the stop**: take a fresh diff against the ledger baseline. Partial edits are either completed by inspection (rare), reverted, or explicitly folded into the retry ticket. Never re-dispatch onto an unreconciled tree.
4. A LOST dispatch counts as a failure toward the precedence table.

Background jobs (including Codex workers): record the job identity and output path in the ledger **at dispatch time**, and capture exit codes on collection.

## The precedence table (single authority for retries and escalation)

For any failed, FAILED-verdict, or LOST task — apply the first matching row:

| # | Condition | Action |
|---|---|---|
| 1 | Failure caused by the ticket (ambiguity, missing context) | Fix ticket; retry **same seat** (doesn't count against the seat) |
| 2 | First real failure at this seat | Retry same seat with something changed: corrected ticket, added context, or raised effort |
| 3 | Second real failure at this seat | Escalate one seat, **or** the foreman takes over — whichever the task's class warrants |
| 4 | Failure at the top seat (or foreman takeover failed) | Stop; report to the user with evidence |
| 5 | Two consecutive failed **fix waves** against the same findings list | Stop; report to the user with the verifier's evidence — regardless of seats remaining |

Never a third identical retry anywhere. Escalations are one-way per task: once a task proves it needs a seat, don't re-try a cheaper one on it. Rows 4–5 exist so "keep trying" never silently becomes the plan.

## The degradation rule (budget pressure)

When usage limits bite, do **not** blanket-downshift. Re-run the routing decision for each remaining task:

- If a cheaper seat still clears that task's quality bar (tasks are often conservatively over-provisioned), step down **and journal it visibly**.
- If no affordable seat clears the bar, **stop after the current task and tell the user**. A clean stop beats degraded judgment — the First Law is not suspended by budget pressure.

## The finding contract (every reviewer, every provider)

Any ticket asking a seat to produce findings — review, audit, adversarial
critique, verifier notes — MUST require this shape per finding, in its OUTPUT
FORMAT. Prose without it is a failed ticket, not a soft miss.

```
FINDING <n> | <BLOCKER|MAJOR|MINOR> | <QUOTED|OBSERVED|DERIVED|INFERRED>
CLAIM:   <one sentence — the defect, not the fix>
CITE:    <file>:<line-or-anchor> — "<exact text, verbatim>"   (QUOTED/DERIVED: required)
COMMAND: <exact command> -> <exit code / key output line>     (OBSERVED: required)
SO-WHAT: <the consequence if true>
```

The evidence class is an **objective property of the citation**, not the seat's
feeling about its own claim:

| Class | Means | Foreman check |
|---|---|---|
| `QUOTED` | exact text at a named location | grep the string |
| `OBSERVED` | output of a command the seat ran | re-run it |
| `DERIVED` | inference built on cited quotes | verify quotes, then judge the inference |
| `INFERRED` | reasoning only, no citation | a lead — never actionable alone |

Grading and dismissal rules live in verification.md ("Finding triage"). The payoff
is cost as much as accuracy: checking "SKILL.md line 27 says X" is a lookup;
checking "this contradicts the First Law" is a re-derivation.

**What the contract does NOT do — read this before trusting it.** A resolved
citation proves *the text exists*, never that it *supports the claim*. A seat can
quote a real line and draw a false conclusion from it, and that report passes a
naive grep check. So:

- **`QUOTED` earns a cheap existence check, not acceptance.** After the string
  resolves, judge whether it actually supports the claim. `DERIVED` always
  requires judging the inference on top of the quotes.
- **Severity is the foreman's call, not the seat's.** Confidence self-reports were
  banned for a reason; a self-assigned `BLOCKER` is the same species of claim.
  Re-rank every finding before it enters a fix wave.
- **`INFERRED` means not-yet-actionable, never discarded.** An `INFERRED` finding
  that would be a BLOCKER if true is *investigated* — the foreman establishes the
  evidence itself or re-tasks it with a narrower scope. Dropping hard, poorly-cited
  findings while shipping well-cited trivia is the failure mode this contract
  would otherwise create.

## Self-correction — resolve it, don't escalate it

**The foreman resolves what the evidence already settles. It does not hand the
user a decision it can make itself.** On a `FAIL` verdict or a confirmed finding:

1. Triage findings (verification.md). Unsupported ones are dismissed and journaled — not raised with the user.
2. Batch every surviving finding into **one** fix ticket with the verifier's evidence verbatim.
3. Dispatch the fix to a **worker**.
4. Re-verify with a **fresh** verifier that never saw the first exchange.

**The verifier never edits.** A verifier that repairs what it just judged is
grading its own work, and blind verification collapses. Judgment, repair, and
re-verification are three separate seats — this is why `foreman-verifier` ships
with no edit tools.

**Bounded by the precedence table below**, so "keep trying" never becomes the
plan: two consecutive failed fix waves on the same findings list → stop and report
(row 5). Never a third identical retry.

**Stopping is not escalating.** The foreman still stops — with evidence — for:

- **an ask that was advisory in the first place.** If the user requested a review,
  an audit, an opinion, or a plan, the deliverable is findings. Self-correction
  applies to work the foreman was told to *produce*, never as licence to start
  implementing off the back of a review the user asked for. Report and ask. If the
  user asked for both — 'build X, then review it' — the build is produce-work:
  confirmed findings against it enter self-correction, and the review's findings
  are still reported alongside.
- a **design, architecture, product, or security-posture choice** — a well-cited
  finding can still be a *judgment call the user owns*, not a settled defect.
- a **user-visible contract change** (API shape, output format, defaults, schema).
- an **external blocker** it must not work around (credentials, permissions).
- an **irreversible or destructive** action.
- a **policy refusal**, or **no available seat clearing the task's bar**. Those are reports the First Law requires, and they
are never satisfied by shipping degraded work instead. Everything else — a wrong
finding, a failed check, a bad ticket, a flaky seat — the foreman fixes and
journals.

## Fix waves

Findings from review/verification batch into **one** fix ticket carrying the complete findings list and the verifier's evidence verbatim — never one worker per finding (each rebuilds context and re-runs suites). Fix output re-enters verification. Two consecutive failed waves → precedence row 5.

## Ledger schema

`.foreman/ledger.md`, written before the **first delegated dispatch of any run** — a single-worker run gets the minimal form (BASELINE + one task row + Attempts). Where a real shell exists, bootstrap it with `scripts/init-ledger.sh "<task title>"` (v0.3): it snapshots the baseline deterministically and refuses to clobber an existing ledger, forcing the resume-reconcile path below.

```
# Foreman Ledger — <task title>
BASELINE: <commit hash> | <git status --porcelain summary> | <date>
## Plan       <numbered tasks, class per task; a task kept inline gets
             `NOT DELEGATED — <reason>` appended to its line>
## Routing    <task → seat (+effort if applied) — why, one line each>
## Tasks      <id | lifecycle state | owned paths | job id>
## Attempts   <append-only, one line per attempt:
              task | attempt # | seat + effort | ticket rev | outcome
              (status/verdict/LOST + failure class) | checks run + results |
              evidence/artifact paths | timestamp |
              [cost receipt: requested model | wall-clock duration |
              exit status | artifact size | iteration index |
              token counts where the transport reports them |
              cost estimate (ESTIMATE) | LEAD counterfactual (ESTIMATE)]>
## Decisions  <choices + why; seat changes; degradations; consent grants>
## Scratch    <artifact paths>
```

The Attempts table is what makes the precedence rules provable after compaction: "second real failure at this seat", "unchanged input", and "two consecutive failed fix waves" are all read directly off it — never reconstructed from memory.

The bracketed cost-receipt fields are optional per attempt and additive to the row above, never a separate table: they record what each transport actually exposes (duration, exit status, artifact size are measured, as are token counts on the gateway seats; the two dollar fields are always priced off model-matrix.md and always carry the `(ESTIMATE)` marker, never presented as measured). Full field definitions, what each seat (Claude subagent, Codex, agy, gateway) can and cannot report, and the goal-seeking "simmer" loop that also writes one Attempts row per iteration live in [references/simmer.md](simmer.md).

Update on every state change. **Resuming after compaction or restart:** read the ledger, then reconcile — `git status`/diff against BASELINE, check for still-running jobs, confirm REPORTED/VERIFIED states against actual artifacts — before dispatching anything. A stale `DONE` causes accepted-but-missing work; a stale `DISPATCHED` causes duplicate work. Trust the tree over the ledger.

## Global crew-performance record

`.foreman/ledger.md` above is per-project and reset by nothing but the project. `~/.foreman/crew-performance.md` is the opposite: cross-project, cross-session, append-only, and never rewritten. Every dispatch closure appends one row via `scripts/crew-append.sh <record-file>` — line 1 is the framing key `RECORD host=<h> run=<r> outcome=<o> rev=<n>`, the body is free text (requested model/effort, seat-evidence tier, cost estimate, evidenced charge, elapsed, task shape). The script is crash-safe: a directory lock with a bounded wait, fsynced staged writes, and an interrupted-append recovery pass that quarantines any incomplete fragment rather than trusting it. Identical key + identical content is a silent `NOOP`; identical key + different content is a refused `CONFLICT` — corrections are new rows with a higher `rev=`, never rewrites.

**Read the relevant slice before a comparable dispatch.** This is what the `record` deviation reason (routing-defaults.json) rests on: "the performance record shows the seat failing on this task shape" is only a legitimate reason to deviate from the routing card's settled row when you actually consulted the record. A failed append writes a local receipt under `.foreman/` and never blocks the run.

## Delegation accounting (LEAD-quota protection)

The LEAD's allowance is the orchestration budget — the scarce resource this
skill exists to conserve. Workers (Codex, Grok, agy, gateway seats) spend
independent pools; Claude subagents spend the LEAD's. Two ledger facts make
that conservation auditable instead of aspirational:

1. **Every substantial task the foreman did NOT delegate** carries a
   `NOT DELEGATED — <reason>` line in the ledger's Plan section (dispatch
   gate). Count them at report time; a pattern of inline work that had no
   stated reason is a routing failure to fix, not a style.
2. **Each run closes with a one-line delegation tally** appended next to the
   final report — e.g. `delegation: 11 tickets dispatched (4 parallel waves,
   3 providers), 1 inline (NOT DELEGATED: atomic 3-file change), 2
   re-dispatches, 0 verifier overrides`. The target is not a percentage — it
   is that every inline line has a defensible reason and the LEAD's turns
   trend down for equivalent work.
3. **On any run touching more than one provider, expand the tally into a
   per-provider (and per-agy-model) breakdown** — this is what makes the
   2026-09-25_v2 Codex-RESERVE policy (routing.md step 2a) auditable instead
   of aspirational; a Codex-heavy run on routine tickets is exactly the
   regression this breakdown is meant to surface, and Codex now carries a
   `reason` field precisely because every dispatch to it should be traceable
   to one of the conditions routing.md 2a names (exceptionally complex task,
   every AGY tier unavailable, or explicit user request) — a Codex line with
   no reason is the loudest possible routing-failure signal under this policy.
   Read it off the ledger's Attempts rows and Routing section, never
   reconstructed from memory:

   ```
   DISPATCH TALLY

   AGY:
     dispatched: <n>
     gemini-3.8-flash-low: <n>
     gemini-3.8-flash-medium: <n>
     gemini-3.8-flash-high: <n>
     gemini-3.7-flash-low: <n>
     gemini-3.7-flash-medium: <n>
     gemini-3.7-flash-high: <n>
     gemini-3.6-flash-low: <n>
     gemini-3.6-flash-medium: <n>
     gemini-3.6-flash-high: <n>
     gemini-3.1-pro-low: <n>
     gemini-3.1-pro-high: <n>
     claude-sonnet-4-6: <n>
     claude-opus-4-6-thinking: <n>

   Claude API:
     sonnet: attempts=<n> success=<n> failure=<n>
     opus: attempts=<n> success=<n> failure=<n>
     fable: attempts=<n> success=<n> failure=<n>
     intra-provider fallback: <n>   (a dead alias on this seat, stepped to its live sibling — never counted as a provider failure)

   Claude OpenRouter:
     sonnet: attempts=<n> success=<n> failure=<n>
     opus: attempts=<n> success=<n> failure=<n>
     fable: attempts=<n> success=<n> failure=<n>
     intra-provider fallback: <n>

   Fallback inter-provider (gateway -> gateway, or gateway -> a different provider entirely):
     <n>

   Double-prompt / second opinion:
     <n>   (count each parallel wave once, not per-seat — e.g. AGY+claude-api on
            one ticket = 1, not 2; note the ticket/topic in the ledger, not here)

   Grok:
     dispatched: <n>

   Codex:
     dispatched: <n>
     reason: <one of: exceptional-complexity | agy-unavailable | user-requested — omit only when dispatched is 0>

   Claude LEAD inline:
     <n>

   SCOUT:
     <n>

   NOT DELEGATED:
     <n>

   Redispatch:
     <n>

   Verifier overrides:
     <n>
   ```

   `attempts`/`success`/`failure` per gateway alias make the router-local
   distinction (routing.md "Router-local failover") auditable: a `sonnet`
   failure followed by a `fable` success on `claude-api` is one `failure`, one
   `success`, and one `intra-provider fallback` — never a claim that
   `claude-api` itself failed. Only a `failure` on **every** live alias of a
   seat in the same attempt, followed by a dispatch to the other gateway,
   counts toward `fallback inter-provider`. List only the AGY model rows that are actually allowlisted this session
   (routing-defaults.json `known_models.agy`) — don't pad the tally with rows
   for models the account can't reach. Every non-zero `Claude LEAD inline` or
   `NOT DELEGATED` count must trace to a `NOT DELEGATED — <reason>` ledger line
   (dispatch gate, above); a nonzero count with no matching reason is a
   routing failure to fix, not a rounding error. `claude-openrouter`/`claude-api`
   are counted separately from `Claude LEAD inline` even though both say
   "Claude" — they spend an
   independent gateway credential, never the LEAD's own allowance (routing.md
   step 2c), and collapsing them into one line would hide exactly the pool
   this breakdown exists to protect.
