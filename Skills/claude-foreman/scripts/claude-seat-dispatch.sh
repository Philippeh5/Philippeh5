#!/bin/bash
# claude-foreman — fixed-argv launcher for the gateway Claude Code seats.
#
# Transport wrappers run ONLY this script, never a hand-composed `claude`
# command: argv is pinned here, so pipelines, substitutions, and nested
# invocations cannot ride in through the wrapper's shell (SKILL.md hard rail 1).
#
# ---------------------------------------------------------------------------
# WHAT THIS SEAT ACTUALLY IS.
#
# `claude-openrouter` and `claude-api` are not APIs. They are the *same*
# Claude Code binary pointed at a different config directory:
#
#     ~/.local/bin/claude-openrouter (sh):
#         export CLAUDE_CONFIG_DIR="$HOME/.claude-openrouter"
#         exec claude "$@"
#
# That config dir carries its own ANTHROPIC_BASE_URL (a gateway) and its own
# credential, already present on this machine. So a dispatch here is a full
# Claude Code agent — tools, file access, the four-status contract — served by
# a non-Anthropic model behind the gateway. Do NOT reimplement it as raw HTTP:
# that throws away the agent and re-adds a key that is already configured.
#
# INVARIANT 1 — THE SEAT NAME IS ALLOWLISTED, NEVER A PATH.
# The caller passes `openrouter` or `api`, not a config directory. An arbitrary
# CLAUDE_CONFIG_DIR would let a wrapper point the binary at any credential set
# on the machine, including the subscription one this session runs on.
#
# INVARIANT 2 — MODEL EVIDENCE IS BILLED-TIER, NOT SERVED-TIER.
# `--output-format json` returns a `modelUsage` map keyed by the model ids the
# gateway billed. That is real evidence — better than agy's nothing — but it is
# the *gateway's* accounting, not a served-model field from the provider, so it
# is reported as `billed-tier evidence` and never as `verified` (hard rail 5).
# Note the map routinely holds TWO keys: the model that ran the agent loop plus
# the small background model Claude Code uses for titles/summaries. Evidence
# therefore means "the id carrying the BULK OF THE INPUT TOKENS is the expected
# one" — a presence test is not evidence, because on this machine the background
# model IS what the `haiku` alias maps to, so presence passed trivially for that
# alias while the sonnet-alias model silently did all the work.
#
# INVARIANT 3 — `total_cost_usd` IS WRONG FOR THESE SEATS AND IS NOT REPORTED
# AS MONEY. Measured 2026-08-26: a dispatch served entirely by `:free` models
# reported $0.158, because the figure applies Anthropic's price table to the
# alias tier rather than the gateway's. Tokens are measured; dollars are not.
# ---------------------------------------------------------------------------
#
# Usage: claude-seat-dispatch.sh <openrouter|api> <ticket-file> <alias> <read-only|workspace-write> <artifact.json> [workdir] [timeout]
# Emits a transport envelope on stdout; the raw JSON result goes to
# <artifact.json>, stderr to <artifact.json>.stderr, the child PID to
# <artifact.json>.pid (the "prove it stopped" handle).
set -eu

[ $# -ge 5 ] || { echo "BLOCKED: usage: claude-seat-dispatch.sh <openrouter|api> <ticket> <alias> <read-only|workspace-write> <artifact.json> [workdir] [timeout]" >&2; exit 64; }
SEAT="$1"; TICKET="$2"; ALIAS="$3"; SANDBOX="$4"; OUT="$5"; WORKDIR="${6:-.}"; TIMEOUT="${7:-600}"

# --- invariant 1: seat name -> config dir, from an allowlist ---
case "$SEAT" in
  openrouter|api) ;;
  *) echo "BLOCKED: unknown seat '$SEAT' (allowed: openrouter, api)" >&2; exit 64 ;;
esac
# Linux: config dir is a plain POSIX path under $HOME (wrappers in ~/.local/bin
# set the same CLAUDE_CONFIG_DIR). Derived once; used for both check and child.
SEAT_DIR="${SEAT/api/nvidia}"
CONFIG_DIR="$HOME/.claude-$SEAT_DIR"
CONFIG_DIR_POSIX="$CONFIG_DIR"
[ -d "$CONFIG_DIR_POSIX" ] || { echo "BLOCKED: seat config dir not found: $CONFIG_DIR_POSIX — seat '$SEAT' is not installed on this machine" >&2; exit 69; }
[ -f "$CONFIG_DIR_POSIX/settings.json" ] || { echo "BLOCKED: $CONFIG_DIR_POSIX/settings.json missing — the seat has no gateway/credential configuration" >&2; exit 69; }

# Only the four stable tier aliases. Dated ids are refused on purpose: the
# gateway maps *aliases*, so a dated id would be passed through unmapped.
case "$ALIAS" in
  opus|sonnet|haiku|fable) ;;
  *) echo "BLOCKED: model must be a tier alias (opus|sonnet|haiku|fable), got '$ALIAS'." >&2
     echo "         These seats map aliases to gateway models via ANTHROPIC_DEFAULT_*_MODEL;" >&2
     echo "         a dated id would bypass that map." >&2
     exit 64 ;;
esac

# INVARIANT 4 — `haiku` IS REFUSED ON BOTH SEATS.
# Measured 2026-08-26 on the same one-word probe, on both gateways: requesting
# `haiku` returns a correct answer served by the *sonnet*-alias model. The
# token split is unambiguous (claude-api: nemotron-3-ultra 15130 input vs
# minimax-m3 427; claude-openrouter: laguna-s-2.1 29113 vs north-mini-code 79).
# Allowing the call would hand the caller a model it did not ask for at a price
# it did not budget, and every such dispatch is SUSPECT by invariant 2 anyway.
# Refuse up front rather than burn ~15-29k input tokens to produce a SUSPECT
# result. The escape hatch exists so a user who has remapped the alias can
# re-measure; it is not for routine use.
if [ "$ALIAS" = haiku ] && [ "${FOREMAN_GATEWAY_ALLOW_HAIKU:-0}" != 1 ]; then
  echo "BLOCKED: alias 'haiku' is refused on gateway seats — measured 2026-08-26," >&2
  echo "         both gateways silently serve the sonnet-alias model instead" >&2
  echo "         (routing.md silent-fallback hazard; see references/gateway-seats.md)." >&2
  echo "         Route this seat at 'sonnet' or above. For a genuinely cheap seat," >&2
  echo "         use a native haiku subagent — it is cheaper and faster than any" >&2
  echo "         gateway dispatch, which pays 7.5k-29k input tokens before answering." >&2
  echo "         If you have remapped the alias, re-measure with FOREMAN_GATEWAY_ALLOW_HAIKU=1." >&2
  exit 64
fi

case "$SANDBOX" in read-only|workspace-write) ;; *) echo "BLOCKED: invalid sandbox '$SANDBOX'" >&2; exit 64 ;; esac
case "$TIMEOUT" in ''|*[!0-9]*) echo "BLOCKED: timeout must be integer seconds" >&2; exit 64 ;; esac
[ -f "$TICKET" ] || { echo "BLOCKED: ticket not found: $TICKET" >&2; exit 66; }
[ -s "$TICKET" ] || { echo "BLOCKED: ticket is empty: $TICKET" >&2; exit 64; }
[ -d "$WORKDIR" ] || { echo "BLOCKED: workdir not found: $WORKDIR" >&2; exit 66; }

CLAUDE_BIN="${FOREMAN_CLAUDE_BIN:-claude}"
command -v "$CLAUDE_BIN" >/dev/null 2>&1 || { echo "BLOCKED: claude not found on PATH; set FOREMAN_CLAUDE_BIN" >&2; exit 127; }

# Artifact-path constraints: never a symlink, never the ticket itself — a
# dispatch must not be able to truncate arbitrary wrapper-writable files.
case "$OUT" in *.json) ;; *) echo "BLOCKED: artifact path must end in .json: $OUT" >&2; exit 64 ;; esac
[ "$OUT" = "$TICKET" ] && { echo "BLOCKED: artifact path equals ticket path" >&2; exit 64; }
for P in "$OUT" "$OUT.stderr" "$OUT.pid"; do
  [ -L "$P" ] && { echo "BLOCKED: artifact path is a symlink: $P" >&2; exit 64; }
  [ -e "$P" ] && [ ! -f "$P" ] && { echo "BLOCKED: artifact path exists and is not a regular file: $P" >&2; exit 64; }
  [ -e "$P" ] && [ "$P" -ef "$TICKET" ] && { echo "BLOCKED: artifact path aliases the ticket: $P" >&2; exit 64; }
done

# Resolve alias -> expected gateway model id from the seat's own settings, so
# the evidence check compares against what THIS machine configured rather than
# a list baked into the launcher. Reads one non-secret env key by name; no
# credential value is ever loaded into a shell variable.
TIER=$(printf '%s' "$ALIAS" | tr '[:lower:]' '[:upper:]')
EXPECTED=$(SEAT_SETTINGS="$CONFIG_DIR_POSIX/settings.json" TIER="$TIER" node -e '
  const fs = require("fs");
  try {
    const s = JSON.parse(fs.readFileSync(process.env.SEAT_SETTINGS, "utf8"));
    const v = (s.env || {})["ANTHROPIC_DEFAULT_" + process.env.TIER + "_MODEL"];
    if (typeof v === "string" && v) process.stdout.write(v);
  } catch (e) { /* absent or unparseable -> no expectation, reported below */ }
' 2>/dev/null) || EXPECTED=""

# read-only  -> plan mode: the agent proposes, never writes.
# workspace-write -> acceptEdits: edit tools auto-approve, so a headless run
#   cannot deadlock on an approval prompt it has no way to answer.
case "$SANDBOX" in
  read-only)       PERM="plan" ;;
  workspace-write) PERM="acceptEdits" ;;
esac

START=$(date +%s)

# The prompt travels on stdin. Verified 2026-08-26 that `--model` IS honoured
# in this form on both seats (unlike agy — see agy-dispatch.sh invariant 1), so
# there is no argv ceiling here and tickets may be arbitrarily large.
set +e
(
  cd "$WORKDIR" || exit 66
  CLAUDE_CONFIG_DIR="$CONFIG_DIR" exec "$CLAUDE_BIN" -p \
    --output-format json \
    --model "$ALIAS" \
    --permission-mode "$PERM" \
    < "$TICKET"
) > "$OUT" 2> "$OUT.stderr" &
CPID=$!

# The PID file is the LOST-protocol handle — if it cannot be written, paid work
# must not continue untracked: kill the child and fail loudly.
if ! printf '%s\n' "$CPID" > "$OUT.pid"; then
  kill "$CPID" 2>/dev/null; wait "$CPID" 2>/dev/null
  echo "BLOCKED: could not write pid file $OUT.pid; claude child killed — no untracked spend" >&2
  exit 74
fi
trap 'kill "$CPID" 2>/dev/null; wait "$CPID" 2>/dev/null; echo "BLOCKED: launcher terminated; claude child $CPID killed and reaped" >&2; exit 143' INT TERM

# `claude -p` has no --timeout, so the watchdog is ours. It kills only the pid
# it was given and exits as soon as the child is reaped, so it cannot outlive
# the dispatch or signal a recycled pid.
( I=0; while [ "$I" -lt "$TIMEOUT" ]; do kill -0 "$CPID" 2>/dev/null || exit 0; sleep 1; I=$((I+1)); done; kill "$CPID" 2>/dev/null ) &
WPID=$!
wait "$CPID"
CODE=$?
kill "$WPID" 2>/dev/null; wait "$WPID" 2>/dev/null
trap - INT TERM
set -e
END=$(date +%s)
ELAPSED=$((END - START))

echo "exit code: $CODE"
echo "duration: ${ELAPSED}s"
echo "pid file: $OUT.pid (child $CPID, reaped)"
echo "seat: claude-$SEAT (CLAUDE_CONFIG_DIR=~/.claude-${SEAT/api/nvidia}), permission-mode=$PERM"
echo "requested alias: $ALIAS${EXPECTED:+ -> expected gateway model '$EXPECTED'}"
if [ "$CODE" -ne 0 ] && [ "$ELAPSED" -ge "$TIMEOUT" ]; then
  echo "NOTE: the child was killed at the ${TIMEOUT}s watchdog — treat as TIMEOUT, not as a model refusal."
fi

# --- invariant 2: billed-tier evidence, reported for exactly what it is ---
# The reporter lives in its own file (seat-evidence.js) next to this script:
# its report text is full of single-quoted model ids, every one of which would
# terminate the quoting of an inline `node -e` heredoc here.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
set +e
node "$SCRIPT_DIR/seat-evidence.js" "$OUT" "$ALIAS" "$EXPECTED"
EVIDENCE_CODE=$?
set -e
case "$EVIDENCE_CODE" in
  0) ;;
  # 3 = the reporter proved a substitution. A dispatch whose output must not be
  # accepted has to be visible in the exit code, not only in the prose: the
  # transport wrapper keys its DONE/BLOCKED line off this, and until now a
  # substituted dispatch exited 0 and was relayed as DONE.
  3) echo "SEAT: SUSPECT — the seat served a model that was not requested."
     echo "      Do not accept this dispatch's output; re-route and journal it."
     # Only claim exit 3 when the child itself succeeded. If the child failed,
     # its own code is the more important fact and must not be shadowed — a
     # child that happened to exit 3 would otherwise be misread as a
     # substitution. The SUSPECT line above is printed either way.
     if [ "$CODE" -eq 0 ]; then exit 3; fi
     echo "      (the child also exited $CODE — reporting that code, not 3)"
     exit "$CODE" ;;
  *) echo "seat evidence: NONE — the evidence check failed to run. Seat: unverified (Layer 0)." ;;
esac

exit "$CODE"
