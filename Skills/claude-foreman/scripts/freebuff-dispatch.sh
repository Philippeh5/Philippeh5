#!/usr/bin/env bash
# freebuff-dispatch.sh — fixed-argv launcher for the FreeBuff seat (drives the FreeBuff TUI in a Paseo PTY).
# usage: freebuff-dispatch.sh <ticket-file> <artifact-json> [workdir] [keep|nokeep] [terminal-id]
#   ticket-file  : task text; whitespace is collapsed to ONE line (a newline would submit the TUI), max 4000 chars
#   artifact-json: where the freebuff-run --json result is written (.stderr beside it)
#   keep         : leave the FreeBuff terminal open and report its terminalId (for follow-ups)
#   terminal-id  : continue in an already-open FreeBuff terminal (follow-up turn)
# One FreeBuff paid session at a time: if the TUI shows "paid session in use elsewhere", this exits 3 (never takes over).
set -u
TICKET=${1:?ticket file}; ART=${2:?artifact json}; WD=${3:-$PWD}; KEEP=${4:-nokeep}; TID=${5:-}
RUN=/home/ubuntu/Projets/paseo-lab/tools/freebuff-run.mjs
URL=${FREEBUFF_DAEMON_URL:-ws://100.78.38.61:6767/ws}
[ -r "$TICKET" ] || { echo "no ticket: $TICKET" >&2; exit 2; }
PROMPT=$(tr '\n\r\t' '   ' < "$TICKET" | tr -s ' ' | cut -c1-4000)
args=(--cwd "$WD" --prompt "$PROMPT" --url "$URL" --wait-seconds "${FREEBUFF_WAIT:-180}" --json)
[ "$KEEP" = keep ] && args+=(--keep)
[ -n "$TID" ] && args+=(--terminal-id "$TID")
t0=$(date +%s)
( cd /home/ubuntu/Projets/paseo-lab && timeout 300 node "$RUN" "${args[@]}" ) > "$ART" 2> "${ART%.json}.stderr"
rc=$?
dt=$(( $(date +%s) - t0 ))
python3 - "$ART" "$rc" "$dt" <<'P'
import json,sys,re
art,rc,dt=sys.argv[1],sys.argv[2],sys.argv[3]
try: d=json.load(open(art))
except Exception as e:
    print(f"exit: {rc}\nduration: {dt}s\nenvelope: unreadable artifact ({e})"); sys.exit(0)
scr=d.get("screen","")
m=re.search(r"^ ?(.+?) · /",scr,re.M)
busy="paid session is in use elsewhere" in scr
import os,time
m2=re.search(r"(\d+)/(\d+) hours remaining",scr)
q=None
if "Not enough hours" in scr or "QUOTA:" in str(d.get("error")): q="0"
elif m2: q=m2.group(1)
if q is not None:
    fh=os.environ.get("FOREMAN_HOME") or os.path.expanduser("~/.foreman"); os.makedirs(fh,exist_ok=True)
    open(os.path.join(fh,"freebuff-quota"),"w").write(f"{q} {int(time.time())}\n")
print(f"exit: {rc}\nduration: {dt}s\nterminalId: {d.get('terminalId')} (killed={d.get('killed')})\ncompleted: {d.get('completed')}  error: {d.get('error')}")
print(f"seat: freebuff — model shown on screen: {m.group(1) if m else 'unknown'} (self-reported UI text, NOT verified; FreeBuff picks the model)")
if busy: print("BUSY: FreeBuff paid session in use elsewhere — not taken over"); sys.exit(0)
P
if grep -q "paid session is in use elsewhere" "$ART" 2>/dev/null; then exit 3; fi
if grep -q "QUOTA:" "$ART" 2>/dev/null; then echo "QUOTA: FreeBuff has no hours left for its model — do not retry; route to another seat"; exit 4; fi
[ "$rc" -eq 0 ] && exit 0 || exit 1
