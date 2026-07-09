#!/usr/bin/env bash
# COMPILER/BOOT/run_meaning_square.sh — Θ2 rung 0: THE COMMUTING SQUARE.
#
# Three INDEPENDENT executions of the same .iii source must agree:
#   route N  native   : pinned iiis-2 (sema+cg_r3+emit) -> gcc link -> run
#   route E  eval     : iii_eval (lex+parse+definitional evaluator)
#   route S  svir     : iiisv2 (.iii -> SVIR, the DDC shunting-yard emitter)
#                       -> gen_svir module -> svir_interp (the SVIR reference
#                       executor) — forks at the SOURCE, not below the front
#
# A pairwise split LOCALIZES the fault: N≠E,N≠S,E=S -> the compiled route;
# E≠N,E≠S,N=S -> the evaluator; S≠N,S≠E,N=E -> the SVIR emitter/interp.
#
# THEATER (explicit, honest): SVIR v1 is i64-only and DROPS width suffixes
# (SVIR-V1-CANONICAL §3.3) — arbitrary corpus KATs with u8/u16/u32 wrap
# semantics would falsely diverge.  Route S therefore runs ONLY the
# square_probes/ theater (width-free programs).  Corpus-wide route S
# arrives with Γ1 (the width-faithful cg_r3 SVIR backend absorbs this
# script's oracle unchanged).
#
# Exit: 0 green | 1 split | 2 env.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SQ_DIR="$SCRIPT_DIR/square_probes"
RUN_DIR="$III_ROOT/STDLIB/build/meaning/square"
mkdir -p "$RUN_DIR"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
EVAL_BIN="${EVAL_BIN:-$III_ROOT/COMPILED/iii_eval${BIN_SUFFIX}}"
LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
SOVIR="$III_ROOT/STDLIB/sovir"
[[ -x "$IIIS" && -x "$EVAL_BIN" && -f "$LIB" ]] || { echo "[square] FATAL: missing toolchain"; exit 2; }

say() { printf '%s\n' "$*"; }

# build the route-S executor pair once: iiisv2 (emitter) + interp shell
"$IIIS" "$SOVIR/iiisv2.iii" --compile-only --out "$RUN_DIR/iiisv2.o" >/dev/null 2>&1 || { echo "[square] FATAL: iiisv2 compile"; exit 2; }
for _la in 1 2 3; do rm -f "$RUN_DIR/iiisv2$BIN_SUFFIX"; gcc "$RUN_DIR/iiisv2.o" "$LIB" -lws2_32 -lkernel32 -o "$RUN_DIR/iiisv2$BIN_SUFFIX" >/dev/null 2>&1 && break; sleep 1; done
[[ -x "$RUN_DIR/iiisv2$BIN_SUFFIX" ]] || { echo "[square] FATAL: iiisv2 link"; exit 2; }

FAIL=0; N=0
for src in "$SQ_DIR"/sq*.iii; do
    [[ -f "$src" ]] || continue
    N=$((N+1)); base="$(basename "$src" .iii)"
    # route N
    "$IIIS" "$src" --compile-only --out "$RUN_DIR/$base.o" >/dev/null 2>&1 || { say "SPLIT $base: native compile failed"; FAIL=1; continue; }
    for _la in 1 2 3; do rm -f "$RUN_DIR/$base$BIN_SUFFIX"; gcc "$RUN_DIR/$base.o" "$LIB" -lws2_32 -lkernel32 -o "$RUN_DIR/$base$BIN_SUFFIX" >/dev/null 2>&1 && break; sleep 1; done
    cp "$RUN_DIR/$base$BIN_SUFFIX" "/tmp/sq_$$$BIN_SUFFIX"; timeout 60 "/tmp/sq_$$$BIN_SUFFIX" >/dev/null 2>&1; RCN=$?; rm -f "/tmp/sq_$$$BIN_SUFFIX"
    # route E
    timeout 60 "$EVAL_BIN" "$src" >/dev/null 2>&1; RCE=$?
    # route S: emit gen_svir module text, compile AS gen_svir.iii, link with the interp
    W="$RUN_DIR/w_$base"; mkdir -p "$W"
    "$RUN_DIR/iiisv2$BIN_SUFFIX" "$src" > "$W/gen_svir.iii" 2>/dev/null
    [[ -s "$W/gen_svir.iii" ]] || { say "SPLIT $base: iiisv2 rejected (out of v1 subset?)"; FAIL=1; continue; }
    ( cd "$W" && "$IIIS" gen_svir.iii --compile-only --out gen_svir.o >/dev/null 2>&1 ) || { say "SPLIT $base: gen_svir compile"; FAIL=1; continue; }
    ( cd "$W" && "$IIIS" "$SOVIR/svir_interp.iii" --compile-only --out svir_interp.o >/dev/null 2>&1 ) || { say "SPLIT $base: interp compile"; FAIL=1; continue; }
    for _la in 1 2 3; do rm -f "$W/route_s$BIN_SUFFIX"; gcc "$W/svir_interp.o" "$W/gen_svir.o" "$LIB" -lws2_32 -lkernel32 -o "$W/route_s$BIN_SUFFIX" >/dev/null 2>&1 && break; sleep 1; done
    [[ -x "$W/route_s$BIN_SUFFIX" ]] || { say "SPLIT $base: route-S link"; FAIL=1; continue; }
    cp "$W/route_s$BIN_SUFFIX" "/tmp/sqs_$$$BIN_SUFFIX"; timeout 60 "/tmp/sqs_$$$BIN_SUFFIX" >/dev/null 2>&1; RCS=$?; rm -f "/tmp/sqs_$$$BIN_SUFFIX"
    if [[ "$RCN" == "$RCE" && "$RCE" == "$RCS" ]]; then
        say "SQUARE $base rc=$RCN (N=E=S)"
    else
        say "SPLIT $base: N=$RCN E=$RCE S=$RCS"
        FAIL=1
    fi
done
if [[ $N -eq 0 ]]; then echo "[square] FATAL: no probes"; exit 2; fi
if [[ $FAIL -ne 0 ]]; then echo "[square] RED: a pairwise split names its axis"; exit 1; fi
echo "[square] GREEN: $N/$N three-route agreement (the commuting square holds)"
exit 0
