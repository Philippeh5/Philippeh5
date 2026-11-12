---
name: autopilot
description: >-
  Runs a large, multi-task, or open-ended batch of work to full completion
  with zero mid-batch confirmation from the user, then checks in with a
  proposal menu before starting the next batch. Combines claude-foreman
  (decomposition + model routing) and unlazy (per-leaf completion proof) into
  one continuous engine: asks its clarifying questions once at the start of
  each batch, works through every ticket in that batch without pausing
  between them, self-relaunching into a fresh session if the current one has
  to end before the batch is done — then, once the batch clears, proposes
  discovered follow-ups or waits for Philippe's next instruction (assisted
  mode) rather than ending the engagement outright. Also covers a SINGLE
  bounded mission (one bug, feature, refactor, audit, migration — former
  `task` skill): see "Single-mission mode" at the end. Use for: autopilot,
  run this batch, do the whole thing then check with me, big task with
  checkpoints, run everything without asking mid-way, one task to completion.
---

# Autopilot

**Two modes, pick by the shape of the ask:** several tasks or an open-ended
backlog → the batch engine below (Steps 0-5). One bounded mission → jump to
"Single-mission mode" (end of file; it replaces the retired `task` skill and
stops after one report instead of running a backlog).

This is the "big job, assisted" mode — full autonomy *within* a batch, a
checkpoint *between* batches. It exists because the default behavior (see the
top-level CLAUDE.md "Never stop at the first finished subtask" section)
pauses with a short menu after every verified completion — right for steering
a task interactively, wrong for a large backlog Philippe wants to hand off
for a stretch. Autopilot suppresses that pause *within* a batch, then
reintroduces the exact same mandatory-menu checkpoint once the whole batch
clears — that's what makes it assisted rather than a walk-away unattended
run. For a run that should never check in until the entire mission is
finished (overnight, no interaction at all), use `night` instead.

Philippe already runs Claude Code with permission bypass on, so tool
confirmation is never the blocker here — this skill's own stop conditions
(below) are the only gate.

## Step 0 — Ask everything up front, once

Before any decomposition, read the request and resolve every ambiguity that
would otherwise force a mid-run interruption: scope boundaries, which
routing/transport constraints apply (e.g. "only gemini/claude-api/
claude-openrouter" — carry this into every claude-foreman dispatch for the
whole run if Philippe stated it), acceptable risk on any destructive-looking
step, and what "done" means for this specific ask. Ask it all in one pass —
never trickle questions in after work has started. Once answered, do not ask
again for anything covered by these answers.

**If Philippe states a goal for the run itself** (not just for the code —
e.g. "test the agy/claude-api/claude-openrouter routing," "see if Codex can
handle this alone"), that goal is itself a thing to verify at the end.
claude-foreman's own dispatch gate can legitimately decide a ticket is small
enough to do inline rather than dispatch to a worker — that's correct
economics, but it can also silently defeat a stated routing-test goal with
nobody noticing. Track in the ledger whether at least one ticket actually
dispatched to the constrained transports. If the whole run finishes without
ever exercising the stated goal, say so plainly in the Step 5 report — never
let a declared test purpose go unmentioned just because the code itself
turned out fine.

## Step 1 — Decompose, route, and start the external watchdog

Invoke `claude-foreman`. It owns the backlog: probe, ledger, tickets, seat
routing. Build the full ticket backlog for the whole ask up front (not one
ticket at a time) so "what's left" is always visible in `.foreman/ledger.md`.

**If this session is resuming after a stall or a watchdog recovery prompt**
(see Step 4), do the reconciliation *first*, before touching the backlog:
`git status` + `git log -5`, read `.foreman/ledger.md` in full, and treat
its last, incomplete ticket entry as `LOST` — not partial credit. If that
ticket's edits are unverified, redispatch it from scratch. A stale `DONE`
in an inherited ledger is exactly as dangerous as a stale `PENDING`.

As soon as the ledger exists for this run, launch the external watchdog —
**detached, so it survives even if this session crashes** — this is the
only thing that can recover a run if the process dies mid-ticket instead of
ending cleanly (see Step 4):

```
setsid nohup ~/.local/bin/foreman-watchdog '<project path>' >/dev/null 2>&1 &
```

Journal in the ledger that the watchdog was started. Do not start a second
one if a watchdog recovery prompt already indicates one is watching.

**House routing policy (applies to every ticket, batch and single-mission):**
follow the "House policy" section of `claude-foreman`. In short: the lead
(Opus 5.5, effort high) only plans and routes; workers are Haiku 5.5 plus the
free seats (OpenRouter, NVIDIA, agy); each ticket has a `GOAL:` and the worker
runs its own implement → check → fix loop (max 4 rounds) before reporting;
one cheap blind verifier pass per ticket with bounce-back (max 2 rounds). Any
Sonnet or Opus worker session requires an `AskUserQuestion` first ("Haiku
suffit, ou Sonnet / Opus ?") — and this is the one allowed interruption inside
a batch, because it is a spend decision, not a confirmation of work.

## Step 2 — Each ticket proves itself with unlazy, Solo mode only

Per the division-of-labor rule in the top-level CLAUDE.md: the worker on
each ticket uses `unlazy` in **Solo** mode (one `GATES.md` for that leaf) to
prove it is genuinely finished before reporting `DONE`. Never let `unlazy`
run its own Orchestrated/Parallel mode here — claude-foreman is already the
orchestrator for this run.

**Install unlazy's Stop hook for this run** (`node <unlazy-dir>/scripts/
install-hooks.mjs`, project-local). Ordinarily this skill asks consent
before installing it — for autopilot specifically, Philippe has already
given standing consent by asking for zero-confirmation runs, so install it
without re-asking, and journal that it's on. This is what stops a ticket
from being silently left with a `GATES.md` full of `EVIDENCE: pending` and
no verifier dispatched: the hook blocks the session from ending its turn
while gates are unmet, instead of letting it just stop typing. Never let a
ticket's gates sit unresolved when you'd otherwise move on — either finish
the evidence or write an explicit `ABANDON: <id> <reason>` before leaving
it.

**Record gate evidence the moment it exists, not in a batch at the end.**
A real incident: two full rounds of real work happened on one ticket
(including a live curl proof against prod that directly satisfied two of
the seven gates) and `GATES.md` still showed 7/7 `pending` afterward — the
evidence existed and was simply never written down. The instant a command
you already ran produces evidence for a gate, write it into `GATES.md`
before doing anything else, even if other gates on the same leaf are still
open.

**The foreman verifier is still required inside autopilot**, including for
work the orchestrator did itself inline rather than dispatching — "I did
this one myself, it's small" is not the same as "this is single-file,
no-logic content" (the only real exemption). A race-condition fix, a
network query change, anything with logic, gets a blind verifier pass
before its ticket can close, dispatched or not.

**Real browser verification is a gate, not an ask.** Per the top-level
CLAUDE.md rule (a passing build/gate/verifier is not sufficient for
user-facing or runtime behavior), do not close a UI/runtime ticket by
asking Philippe to reload a page and check — that is the open-question
failure this skill exists to prevent, and it also means the "verified"
claim was never actually earned. Do it yourself:

1. Start the project's dev-mode launcher (fast iteration, hot reload) —
   check the project's own CLAUDE.md for the exact command/launcher first;
   never use a full build-then-start launcher for verification during a
   run, it's the wrong tool for fast iteration.
2. Drive the actual check with the **Playwright CLI, in headed mode** (no
   `--headless`) — not the `claude-in-chrome` extension, which is a manual
   interactive tool, not built for an unattended verification step.
3. Record what was actually observed as the gate's evidence. Only ask
   Philippe to look himself when something about the environment is
   outside what autopilot can drive on its own (a mobile-only repro, a
   third-party auth flow it can't complete) — and even then, use the
   mandatory menu format above, never a plain question.

## Step 3 — No menu between tickets. Keep dispatching.

This is the core override: when a ticket's `DONE` clears the foreman
verifier, do **not** stop to ask what's next — open the next ready ticket
from the backlog immediately (claude-foreman's rolling-dispatch pattern) and
continue. Repeat until the ledger shows every ticket resolved (`DONE` and
verified, or a deliberate, journaled `ABANDON`/handoff).

**The only legitimate stops mid-run**, per claude-foreman's own hard rails —
these override autopilot's "don't stop" rule, they are not exceptions to be
argued around:

- an irreversible or destructive action (`git push`, force operations, data
  deletion, DB migrations, anything touching credentials/secrets)
- a design or user-visible-contract decision Philippe owns and hasn't
  already resolved in Step 0
- a genuine external blocker (missing access, missing credentials, a
  provider down)
- a policy refusal from a seat
- a bar no available seat clears (never silently ship degraded work)

When one of these fires, pause with the **same mandatory menu format as the
default mode** (2-3 concrete options, a "ne rien
faire" option, implicit free text — the "mandatory menu" rule the top-level
CLAUDE.md defines) — never a plain prose question, even
though the reason for stopping is legitimate. A real incident: a session
hit a genuine external blocker (couldn't reload a browser itself) and wrote
one sentence asking Philippe to check, with no numbered options and nothing
he could answer in one word — exactly the format this rule forbids. A
correct blocker-menu for that case would have been: (1) wait for your
browser check before continuing, (2) meanwhile pre-fill whatever gate
evidence doesn't need a browser, (3) move on to the next backlog item and
come back to this one, (4) ne rien faire. Resume autopilot once answered.

## Step 4 — Two layers of recovery, because a dying session can't save itself

**This has failed silently before**: a run stopped mid-ticket with the
ledger truncated inside the "Routing" section, gates never checked, no
verifier dispatched, and nothing relaunched — because the instruction to
self-relaunch lives *inside* the same process that just died reading it. A
prose instruction cannot execute after its process is gone. Two layers,
not one:

**Layer 1 — graceful, model-initiated** (covers: approaching a hard usage
wall, claude-foreman's "fresh session per feature" policy, a planned
restart — anything you can see coming before it happens):

1. Generate the continuation document exactly as the `/handoff-prompt`
   command does (same 8-section structure), grounded in the current
   `.foreman/ledger.md` state and what remains in the backlog. Save it at
   the project root.
2. **Close out the ledger entry you're leaving mid-flight before anything
   else** — append its actual status (`DONE`, `BLOCKED`, or `LOST` with a
   reason), never leave a bare "Routing" section as the last thing written.
   An incomplete-but-labeled entry is recoverable; a silently truncated one
   looks identical to a crash.
3. Build the resume prompt exactly as `/handoff-prompt` does, with the
   USER DIRECTIVE set to "continue the autopilot backlog in
   [project path] — reconcile the ledger against git status first, resume
   dispatching unfinished tickets, stay in autopilot mode (no menu between
   tickets, same stop conditions)."
4. Relaunch immediately: `~/.local/bin/open-claude-window -Path "<project path>" -Prompt "<resume prompt text>"
   -Launcher claude` (swap `-Launcher` for `claude-openrouter` / `claude-nvidia` /
   `claude2` if this run used a different one). It opens a detached tmux session
   with Remote Control enabled (attach: `tmux attach -t cc-…`).
5. Only then let the current process end.

**Layer 2 — external, crash-proof** (covers: an actual kill, a crash, a
network failure, anything you *can't* see coming — this is the layer that
was missing): the detached watchdog started in Step 1
(`~/.local/bin/foreman-watchdog`) polls `.foreman/ledger.md` from outside
this process. If the ledger goes stale for 15+ minutes with no live
claude/node process still working in the project, it fires the same
`open-claude-window` relaunch on its own, with a resume prompt that
forces ledger reconciliation before anything else. It fires at most once
per stall episode — a relaunch loop would hide a real blocker instead of
surfacing it. Philippe never opens a terminal or notices either layer
firing; the only visible thing is a new window doing work.

## Step 5 — Batch done: report, then hand back control

A batch ends when every ticket built for the current ask is `DONE` and
verified (or a deliberate, journaled `ABANDON`). This is the one point in
autopilot where the "no menu" rule does not apply — the *batch* just
finished, not the whole engagement, and Philippe is meant to be looped in
here (autopilot is the assisted mode: full autonomy *within* a batch, a
checkpoint *between* batches).

1. Report a batch summary: what was built, what was abandoned and why,
   ledger state, anything a stated routing/test goal from Step 0 needs
   called out (per that step's tracking rule).
2. Look at the ledger and the mission for genuine leftover or adjacent work
   (P3/P4 items recorded during dispatch, obvious next steps) and present
   the **mandatory menu** (top-level CLAUDE.md format): 2-3 concrete,
   specific options grounded in that real remaining work, a "ne rien faire /
   stop" option, and the implicit free-text option for Philippe to type his
   own next task. Never a plain prose question here.
3. Wait for the reply:
   - **A new task/backlog** (numbered pick, or free text): treat it as a new
     Step 0 — clarify only what that new ask needs, extend or rebuild the
     ticket backlog, and re-enter Step 1 dispatching. Do not restart the
     watchdog if one is already running for this project; it keeps polling
     across batches.
   - **"ne rien faire" / stop**: proceed to shutdown below.
4. On stop: write `.foreman/autopilot-complete` (empty file is fine) so the
   watchdog stops polling and exits cleanly instead of running forever, then
   give a final summary across every batch run this session (not just the
   last one).

The run only ever ends via step 4 above (or a Step 3 stop condition Philippe
resolves by choosing to stop) — never by silently declaring victory after
one batch without offering the menu.

---

# Single-mission mode (ex-`task`)

Use when the ask is ONE bounded mission. One invocation = one mission: no
backlog, no watchdog, no Step 4 recovery layers (unless context really runs
out — then write `.foreman/task-state.md`: objective, completed, gates,
remaining, decisions, blockers, exact next action).

1. **Boundary.** The mission ends when the objective is verified, impossible,
   externally blocked, or needs a decision/destructive action Philippe owns.
   Extra useful work found on the way is a *proposed follow-up*, never
   executed silently (P0/P1 inside scope: fix; P2/P3: record; P4 = new
   product scope: never).
2. **Clarify once, only if it changes the implementation.** Never ask what the
   repo, docs, tests or runtime can answer.
3. **Gates before code.** For anything substantial write observable gates
   (`Gn — requirement / CHECK: command / EXPECT: result`). Unverifiable →
   `UNVERIFIED`; impossible → `ABANDONED — <reason>`. Never present editing
   the expected files as proof. Per leaf, `unlazy` Solo mode applies.
4. **Delegate by default via `claude-foreman`** (exploration, well-specified
   implementation, tests, mechanical edits) under its House policy: Haiku 5.5
   + free seats, a `GOAL:` and a worker-run check/fix loop per ticket, and
   `AskUserQuestion` before any Sonnet/Opus worker. Inline work needs a stated
   `NOT DELEGATED — <reason>`. Ticket = TASK / CONTEXT / ACCEPTANCE / WRITE
   SET / CONSTRAINTS / REPORT; worker statuses `DONE`, `DONE_WITH_CONCERNS`,
   `NEEDS_CONTEXT`, `BLOCKED`. Parallel only with disjoint write sets. A
   worker's "done" is not evidence.
5. **Minimalism ladder before new code:** needed at all? → already in the
   codebase? → stdlib? → native platform? → installed dependency? → one
   line? → only then the minimum that works. Never cuts validation, money
   safety, security or accessibility.
6. **Test narrow → wide:** targeted test → related suite → typecheck/lint →
   build. Record command, cwd, exit status.
7. **Real run for user-visible/runtime behavior:** same rule as Step 2 above
   (dev launcher + headed Playwright CLI), via the `relaunch-casino` skill.
8. **Blind verifier** (`foreman-verifier`): PASS / FAIL / PASS_WITH_NOTES. FAIL
   = not done; fix and re-verify.
9. **Final report, then STOP:** Completed · Changed · Verification
   (`[PASS]`/`[UNVERIFIED]`) · Findings · Remaining concerns · then the
   mandatory top-level-CLAUDE.md menu (2-3 concrete options + "ne rien
   faire"). Do not start the next action on your own.
