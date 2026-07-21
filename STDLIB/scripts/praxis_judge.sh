#!/usr/bin/env bash
# praxis_judge.sh -- Stop: refuse a completion claim the witnessed trace does not determine.
#
# The judge is MECHANICAL -- a compiled III binary (praxis_cli.exe) over harness-authored pins --
# never an opinion. (The prose-only Stop evaluator was killed by its own pre-registered falsifier:
# 4 false positives in 6 runs. A mechanical check over real pins is the surviving configuration.)
#
# All three battle-tested guard properties (ralph-loop stop-hook pattern, adopted not reinvented):
#   1. SESSION ISOLATION -- the trace is keyed by this session_id; other sessions are untouched.
#   2. FAIL-OPEN on every anomaly -- missing engine, missing identity, corrupt counter, engine
#      error: any confusion permits the stop. The hook never blocks when it is unsure.
#   3. HARD CEILING -- 3 refusals, then it fails OPEN and RECORDS the override (NAMED-DEFICIT LAW).
#      No session is ever unstoppable.
#
# Verdict: trace scrolls + the bridge [done < gate_green], claim [done < exit_zero].
# STANDS (exit 0) iff the trace carries [gate_green < exit_zero] -- i.e. the harness observed a
# *_gate.sh run go GREEN in THIS session. Edits alone do not buy completion. A session with NO
# trace at all (pure reading/answering) passes with a named deficit, never a block.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="$ROOT/STDLIB/build/praxis/praxis_cli.exe"
[ -x "$CLI" ] || exit 0                       # engine absent: stay silent, never fake enforcement

payload="$(cat)"
sid="$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(String(JSON.parse(s).session_id||"").replace(/[^A-Za-z0-9-]/g,""))}catch(e){console.log("")}})' 2>/dev/null)"
[ -n "$sid" ] || exit 0                       # no session identity: fail-open

TRACE="$ROOT/.praxis/$sid.trace"
GUARD="$ROOT/.praxis/$sid.refusals"
if [ ! -f "$TRACE" ]; then
  echo '{"systemMessage":"PRAXIS: NAMED DEFICIT -- no witnessed trace for this session; nothing was pinned."}'
  exit 0
fi

n=0
if [ -f "$GUARD" ]; then
  raw="$(tr -cd '0-9' < "$GUARD" 2>/dev/null)"
  raw="${raw:0:2}"
  case "$raw" in '') n=0 ;; *) n=$raw ;; esac
fi
if [ "$n" -ge 3 ]; then
  echo '{"systemMessage":"PRAXIS: refusal ceiling (3) reached -- failing OPEN and recording the override (NAMED-DEFICIT LAW). The trace still lacks a green gate pin."}'
  rm -f "$GUARD"
  exit 0
fi

"$CLI" "$(tr '\n' ' ' < "$TRACE") [done < gate_green]" "[done < exit_zero]" > /dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then rm -f "$GUARD"; exit 0; fi   # STANDS: the earned claim passes silently
if [ "$rc" -ne 1 ]; then rm -f "$GUARD"; exit 0; fi   # engine anomaly (not a clean DEFECT): fail-open

echo $((n + 1)) > "$GUARD"
printf '{"decision":"block","reason":"PRAXIS REFUSES: the witnessed trace does not determine completion. MISSING PIN: [gate_green < exit_zero] -- no *_gate.sh run went GREEN in this session after your edits. Run the gate that covers what you changed (its GREEN output is pinned automatically), then finish. Refusal %s of 3; the ceiling fails open." }\n' "$((n + 1))"
exit 0
