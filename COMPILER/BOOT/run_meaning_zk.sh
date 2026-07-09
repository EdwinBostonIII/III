#!/usr/bin/env bash
# COMPILER/BOOT/run_meaning_zk.sh — Θ5(c) rung 0: ATTESTED MEANING.
#
# Composition over sq03 (the attestable straight-line cell):
#   1. THE SQUARE: native ≡ evaluator ≡ SVIR-interp on sq03 (rc 12 = 1292&0xFF)
#   2. THE PROOF : zk_iiisv_attest parses THE SAME gen_svir bytes route S
#      executed and STARK-proves the execution (honest accepted, forged
#      stack-top REJECTED BY THE MATH — exit 99)
# The bytes are shared BY CONSTRUCTION: one iiisv2 emission feeds both arms.
# Named residual (zk_iiisv_attest header): straight-line only — locals/loops
# arithmetization is the standing zkVM frontier, not this gate's claim.
# Exit: 0 green | 1 red | 2 env.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
EVAL_BIN="${EVAL_BIN:-$III_ROOT/COMPILED/iii_eval${BIN_SUFFIX}}"
LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
SOVIR="$III_ROOT/STDLIB/sovir"
SQ="$SCRIPT_DIR/square_probes/sq03_line.iii"
W="$III_ROOT/STDLIB/build/meaning/zk"
mkdir -p "$W"
[[ -x "$IIIS" && -x "$EVAL_BIN" && -f "$LIB" && -f "$SQ" ]] || { echo "[mzk] FATAL: missing inputs"; exit 2; }

# ONE emission feeds both arms
"$IIIS" "$SOVIR/iiisv2.iii" --compile-only --out "$W/iiisv2.o" >/dev/null 2>&1 || { echo "[mzk] FATAL: iiisv2 compile"; exit 2; }
for _la in 1 2 3; do rm -f "$W/iiisv2$BIN_SUFFIX"; gcc "$W/iiisv2.o" "$LIB" -lws2_32 -lkernel32 -o "$W/iiisv2$BIN_SUFFIX" >/dev/null 2>&1 && break; sleep 1; done
"$W/iiisv2$BIN_SUFFIX" "$SQ" > "$W/gen_svir.iii" 2>/dev/null
[[ -s "$W/gen_svir.iii" ]] || { echo "[mzk] FATAL: iiisv2 rejected sq03"; exit 2; }

# arm 1: the square (N ≡ E ≡ S)
"$IIIS" "$SQ" --compile-only --out "$W/sq03.o" >/dev/null 2>&1 || { echo "[mzk] RED: native compile"; exit 1; }
for _la in 1 2 3; do rm -f "$W/sq03$BIN_SUFFIX"; gcc "$W/sq03.o" "$LIB" -lws2_32 -lkernel32 -o "$W/sq03$BIN_SUFFIX" >/dev/null 2>&1 && break; sleep 1; done
cp "$W/sq03$BIN_SUFFIX" "/tmp/mzk_n_$$${BIN_SUFFIX}"; timeout 30 "/tmp/mzk_n_$$${BIN_SUFFIX}" >/dev/null 2>&1; RCN=$?; rm -f "/tmp/mzk_n_$$${BIN_SUFFIX}"
timeout 30 "$EVAL_BIN" "$SQ" >/dev/null 2>&1; RCE=$?
( cd "$W" && "$IIIS" gen_svir.iii --compile-only --out gen_svir.o >/dev/null 2>&1 ) || { echo "[mzk] RED: gen_svir compile"; exit 1; }
( cd "$W" && "$IIIS" "$SOVIR/svir_interp.iii" --compile-only --out svir_interp.o >/dev/null 2>&1 ) || { echo "[mzk] RED: interp compile"; exit 1; }
for _la in 1 2 3; do rm -f "$W/route_s$BIN_SUFFIX"; gcc "$W/svir_interp.o" "$W/gen_svir.o" "$LIB" -lws2_32 -lkernel32 -o "$W/route_s$BIN_SUFFIX" >/dev/null 2>&1 && break; sleep 1; done
cp "$W/route_s$BIN_SUFFIX" "/tmp/mzk_s_$$${BIN_SUFFIX}"; timeout 30 "/tmp/mzk_s_$$${BIN_SUFFIX}" >/dev/null 2>&1; RCS=$?; rm -f "/tmp/mzk_s_$$${BIN_SUFFIX}"
if [[ "$RCN" != "$RCE" || "$RCE" != "$RCS" ]]; then echo "[mzk] RED: square split N=$RCN E=$RCE S=$RCS"; exit 1; fi
echo "[mzk] square holds on the attestable cell: N=E=S rc=$RCN"

# arm 2: STARK-attest THE SAME bytes (honest accept + forgery reject inside)
( cd "$W" && "$IIIS" "$SOVIR/zk_iiisv_attest.iii" --compile-only --out zk_iiisv_attest.o >/dev/null 2>&1 ) || { echo "[mzk] RED: attest compile"; exit 1; }
for _la in 1 2 3; do rm -f "$W/attest$BIN_SUFFIX"; gcc "$W/zk_iiisv_attest.o" "$W/gen_svir.o" "$LIB" -lkernel32 -o "$W/attest$BIN_SUFFIX" >/dev/null 2>&1 && break; sleep 1; done
[[ -x "$W/attest$BIN_SUFFIX" ]] || { echo "[mzk] RED: attest link"; exit 1; }
cp "$W/attest$BIN_SUFFIX" "/tmp/mzk_a_$$${BIN_SUFFIX}"; timeout 120 "/tmp/mzk_a_$$${BIN_SUFFIX}" >/dev/null 2>&1; ARC=$?; rm -f "/tmp/mzk_a_$$${BIN_SUFFIX}"
if [[ "$ARC" != "99" ]]; then echo "[mzk] RED: attestation rc=$ARC (want 99: honest-accepted + forgery-rejected)"; exit 1; fi
echo "[mzk] GREEN: the square-agreed bytes are STARK-attested (honest accepted, forgery rejected by the math)"
exit 0
