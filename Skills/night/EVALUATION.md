# Night — objectives and evaluation

This file is not instructions for the skill to follow. It is the yardstick
Philippe (or a later review session) uses to judge whether a given night run
actually worked, so the skill can be improved instead of just trusted. Read
`SKILL.md` for what the skill is supposed to do; read this for whether it did.

## Why this skill exists

Before night, unattended long runs failed in a predictable pattern: they
stopped early or asked questions nobody was there to answer, declared victory
on the first working pass, never came back after a crash, and left no honest
record of what actually got done. Night exists to run for hours with zero
interaction and still be trustworthy on reading its state afterward. If a run
reproduces any part of that original pattern, night did not do its job —
regardless of whether the code it produced is good.

## What "working" looks like

Check these after any night run, in order:

1. **One clarification round, up front.** Section 2's interview happened once
   (including the notes-location question), and every later pause matches
   Section 1's stop list. A question asked mid-run for something the initial
   round should have settled is a defect.
2. **The mission contract was written and never silently changed.**
   `.foreman/night-mission.md` exists, and any expansion that changes intended
   behavior was classified as a user decision (Section 3), not absorbed.
3. **The full backlog was built up front**, with IDs, priorities, and
   acceptance criteria — not discovered one item at a time. Items pulled from
   the notes location are tagged `Source: notes`.
4. **No premature stop.** Every stop matches a Section 27 condition A–G, and
   the run did *not* stop merely because a task was hard, a model failed once,
   a test flaked, or context was compacted (Section 27's explicit non-reasons).
5. **Every completed item was actually verified.** Acceptance gates ran and
   passed; browser behavior got browser verification; worker or self claims
   were treated as claims, not proof (Sections 12, 14, 28). A `DONE` whose
   gates were never run is the quiet failure to look for.
6. **The discovery loop ran.** New work was found after meaningful items,
   triaged P0–P4 (Sections 16–17): in-scope P0/P1 fixed, P3 recorded, P4
   recorded — not implemented. A run that finds nothing across hours of work
   was probably not looking.
7. **No silent scope expansion.** Anything user-owned was recorded in
   `night-decisions.md` and worked around, not implemented (Section 26).
8. **Recovery worked without Philippe.** If the session died or compacted,
   either Layer 1 handed off cleanly or the Layer 2 watchdog relaunched it,
   state was reconciled against git before new work, and the last incomplete
   item was treated as LOST rather than partial credit (Section 21).
9. **No relaunch loop.** The watchdog fired at most once per stall episode. A
   second recovery for the same stall means a real blocker was being masked
   instead of surfaced.
10. **The final state is honest and the system stopped cleanly.** The Section
    31 report reconciles against the original mission, states `STOP REASON`
    if blocked (never "complete" for a blocked run), includes the security
    pass, and names deferred discoveries as deferred. `.foreman/night-complete`
    was written on *every* legitimate stop — including blocked and
    decision-needed ones — so the watchdog exits instead of firing hours later.

## Signals that night is drifting or unsafe

- It stopped for something routine (over-cautious — wastes the point of an
  unattended run).
- It did **not** stop for a Section 27 condition (under-cautious — the
  dangerous direction; treat any occurrence as a priority fix, not a one-off).
- More than one watchdog recovery for the same stall (relaunch loop masking a
  real blocker).
- Scope crept beyond the mission contract with no `night-decisions.md` entry.
- A `DONE` didn't survive a fresh look — gates were written easy to pass, not
  honest. Fix the acceptance criteria, not just the code.
- `.foreman/` runtime state ended up committed to the user's repository.

## After a run: a short debrief

Answer these in a few sentences, ideally right after the run while the state
files are still fresh:

1. Did it finish the in-scope backlog, or a plausible-looking subset of it?
2. Where did it pause, and was every pause on the Section 27 list?
3. If it crashed or stalled, did recovery happen without Philippe — and
   exactly once per stall episode?
4. Was anything implemented that needed user authority (P4) without a
   recorded decision request?

Anything surprising in these answers is a candidate edit to `SKILL.md` —
this file records the bar, `SKILL.md` is what gets changed to meet it.
