# Autopilot — objectives and evaluation

This file is not instructions for the skill to follow. It is the yardstick
Philippe (or a future review session) uses to judge whether a given
autopilot run actually worked, so the skill can be improved instead of just
trusted. Read `SKILL.md` for what the skill is supposed to do; read this for
whether it did.

## Why this skill exists

Before autopilot, the standing complaint was: sessions end too early,
declare victory on the first working piece, never touch `unlazy`, and force
Philippe to manually regenerate a handoff and open a new terminal to keep
going. Autopilot is the fix for exactly that failure pattern on large or
multi-part work. If a run reproduces any part of the original complaint,
autopilot did not do its job — regardless of whether the code it produced is
good.

## What "working" looks like

Check these after any autopilot run, in order — each depends on the one
before it:

1. **Zero mid-run menus for ordinary tickets.** The only pauses that
   happened match Step 3's stop list (destructive action, unresolved
   product decision, external blocker, policy refusal, no seat clears the
   bar). If a pause happened for anything else, that's a defect.
2. **The whole backlog got built up front**, not ticket-by-ticket
   discovery. `.foreman/ledger.md` should show the full ticket list early,
   not one ticket appearing right before it's dispatched.
3. **Every ticket has a `GATES.md` (or equivalent Solo-mode evidence)**
   before it was reported `DONE` — not a bare "looks done" claim.
4. **No `unlazy` Orchestrated/Parallel artifacts appear** inside a ticket
   (`PLAN.md`, `.unlazy/<scope>/dispatch.json` at a sub-ticket level). Their
   presence means unlazy re-orchestrated instead of staying Solo — the
   stacking the division-of-labor rule exists to prevent.
5. **The foreman verifier ran on every ticket** except genuinely trivial
   single-file, no-logic changes, and its verdict is what the ledger
   records as final — not the worker's own claim.
6. **If the session had to end before the backlog was empty, it
   self-relaunched** (a continuation doc + a new window appeared) without
   Philippe doing anything. If Philippe had to notice, ask, or manually
   relaunch, autopilot failed at the one job that's hardest to verify by
   reading code afterward — this is the item most likely to silently rot.
7. **The final report is honest about scope.** Anything abandoned or
   deferred is named as such, not folded silently into "done." A
   `DONE_WITH_CONCERNS` or `ABANDON` that got reported as plain `DONE` is
   a worse failure than an honest incomplete run.
8. **The checkpoint menu appeared exactly once per batch, not more, not
   less.** After the ledger shows every ticket in the current batch `DONE`
   and verified, Step 5 should present the mandatory menu and wait — not
   silently start a new batch of self-invented work, and not skip the menu
   and just stop. If Philippe answers with a new task, that's a new batch
   under the same run; if he says stop, that's the actual end.

## Signals that autopilot is drifting or unsafe

- It stopped for something that should have been routine (over-cautious —
  wastes the point of the skill).
- It did **not** stop for something on the Step 3 list (under-cautious —
  the dangerous direction; treat any occurrence as a priority fix, not a
  one-off).
- It self-relaunched more than once for the same piece of stuck work
  (a relaunch loop masking a real blocker instead of surfacing it).
- Scope crept beyond what Step 0 resolved, without flagging it as a new
  decision.
- A ticket's `DONE` didn't survive a fresh look — i.e. the foreman
  verifier (or a later human check) found it wasn't actually finished
  despite passing its own gates. This means the gates were written to be
  easy to pass, not to be honest — fix the ticket's acceptance criteria,
  not just the code.

## After a run: a short debrief

Answer these three questions in a few sentences, ideally right after a run
while the ledger is still fresh:

1. Did it finish the actual backlog, or a plausible-looking subset of it?
2. Where did it pause, and was every pause on the Step 3 list?
3. If it had to self-relaunch, did that work cleanly, or did Philippe have
   to intervene?

Anything surprising in these answers is a candidate edit to `SKILL.md` —
this file records the bar, `SKILL.md` is what gets changed to meet it.
