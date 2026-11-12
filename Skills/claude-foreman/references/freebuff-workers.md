# FreeBuff seat

FreeBuff (CLI `freebuff` 0.2.x) is interactive-only, so it is driven by `paseo-lab/tools/freebuff-run.mjs` in a Paseo PTY (types the prompt, waits for the screen to settle, returns the ANSI-free screen + reply as JSON). Launcher: `scripts/freebuff-dispatch.sh`; wrapper agent: `foreman-freebuff-wrapper`.

- Tier: free, ad-supported, the model is chosen by FreeBuff (seen: Solar Pro 4, DeepSeek V4.1 Flash Slow). Treat as **FAST/WORKHORSE scouting or simple edits, advisory — never an accepting verdict**; Claude verifier stays final arbiter. No model control, no sandbox flag: give it throwaway or git-tracked dirs only.
- **One paid session at a time.** If the TUI says "paid session is in use elsewhere" the launcher exits 3 = `BUSY`; never press take-over (it kills the other session). Check `ps -eo pid,args | grep [n]ode.*bin/freebuff` first.
- Single-line prompt, ≤ 4000 chars (a newline submits). English works best.
- Multi-turn: first call with `keep`, take `terminalId` from the envelope, next call passes it as the 5th arg; last call without `keep` kills the terminal. Verified 2026-11-07: turn 1 "remember 4721", turn 2 returned `4721`.
- Daemon: `ws://100.78.38.61:6767/ws`, password from `PASEO_PASSWORD` (not `127.0.0.1`, not `oracle-password.txt`).
- Known fragility: UI-text based readiness; startup needs ~10 s before typing is accepted (`FREEBUFF_SETTLE_MS`); confirmation dialogs are not handled.
- **Quota (mesuré 2026-11-07)** : le compte a des heures de session (`N/4 hours remaining`) ; à 0 le TUI affiche « Not enough hours for <model> … Choose another model », jamais de réponse. `freebuff-run.mjs` échoue alors en ~15 s avec `QUOTA:` et `freebuff-dispatch.sh` sort avec le code 4 (wrapper : `QUOTA`) — ne pas relancer, router vers un autre seat (agy/gateway). Le test du wrapper via `claude -p` a validé la chaîne agent -> lanceur -> relais (BLOCKED/QUOTA correctement remontés).
