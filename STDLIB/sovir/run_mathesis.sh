#!/usr/bin/env bash
# STDLIB/sovir/run_mathesis.sh — THE MATHESIS ENGINE gate (Ξ0 seed cycle, DOCS/III-MATHESIS-MAP.md §7).
#
# This is the `run_self_improve.sh` that was never built (ADR-Ξ5): ONE command that replays the whole
# discover→prove→admit→assimilate→re-verify cycle and its rejecting negative arms:
#
#   [1] the DOOR         corpus/2600  four-clause admission conjunction (each single-false REJECTED),
#                                     content-addressed statement-sensitive theorem ids, tamper-evident chain
#   [2] the DISPOSER     corpus/2601  R4 false identity (a+b ≡ a|b) REFUTED FIRST; the ∀x,c1,c2 chain
#                                     schemas PROVEN in one symbolic seq_equiv call each; k=1..63 range
#                                     sweeps; the width-64 tooth; SEQ_TOP honest abstain; truth-table dual
#   [3] the INSTRUMENT   corpus/2602  opcode-synchronous census (anti-byte-grep phantom arm, R2 range tooth,
#                                     unknown-op honest abstain, v1+v2 containers)
#   [4] the SEAL         corpus/2603  MATHESIS-THEOREM-0001 replays from its pins (id + chain head);
#                                     a tampered statement breaks the seal
#   [5] the MEASURED EFFECT           the LIVE pinned compiler emits sq08_mixed: the census must show
#                                     c1=0 (windows folded) and container bytes <= 484 (< the 494
#                                     pre-theorem baseline); then the backend gate (A1 iiisv2 parity +
#                                     A2 goldens incl. the adjudicated sq08 reseal + the N≡E≡S square)
#                                     must be GREEN end-to-end.
#
# Exit 0 = the seed cycle is CLOSED on real, measured, sealed ground.  Any other exit names its stage.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CORPUS="$III_ROOT/STDLIB/corpus"
BUILD="$III_ROOT/STDLIB/build/iii"
RUN="$III_ROOT/STDLIB/build/mathesis/gate"
mkdir -p "$RUN"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2$BIN_SUFFIX}"
LIB="$BUILD/libiii_native.a"
[[ -x "$IIIS" ]] || { echo "[mathesis] FATAL: no pinned iiis-2"; exit 2; }
[[ -f "$LIB"  ]] || { echo "[mathesis] FATAL: no stdlib archive"; exit 2; }

# the force-linked side-effect set (mirrors run_corpus.sh)
SE=()
for n in omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o omnia_proof_ripple_resolution.iii.o \
         omnia_resolver.iii.o omnia_resolver_memo.iii.o omnia_resolver_replay.iii.o omnia_codegen_patterns.iii.o \
         omnia_transform_patterns.iii.o omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o \
         aether_pattern_set_federation.iii.o sanctus_calculus_v1.iii.o sanctus_resolver_replay.iii.o \
         sanctus_seal_resolver.iii.o verba_nl_lex.iii.o resolver_hot.o resolver_unit.o resolver_unit_avx512.o \
         bench_helpers.o; do
    [[ -f "$BUILD/$n" ]] && SE+=("$BUILD/$n")
done

gate() {  # gate <corpus-base>  -> runs the KAT, expects exit 99
    local base="$1"
    local obj="$RUN/$base.o" exe="$RUN/$base$BIN_SUFFIX"
    timeout 120 "$IIIS" "$CORPUS/$base.iii" --compile-only --out "$obj" >/dev/null 2>"$RUN/$base.err" \
        || { echo "[mathesis] RED: $base compile"; return 1; }
    rm -f "$exe"
    gcc "$obj" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" -lws2_32 -lkernel32 -o "$exe" \
        >>"$RUN/$base.err" 2>&1 || { echo "[mathesis] RED: $base link"; return 1; }
    local staged="/tmp/mx_$$_$RANDOM$BIN_SUFFIX"
    cp "$exe" "$staged"
    timeout 300 "$staged"; local rc=$?
    rm -f "$staged"
    [[ $rc -eq 99 ]] || { echo "[mathesis] RED: $base exit=$rc (want 99)"; return 1; }
    echo "[mathesis] GREEN: $base"
    return 0
}

echo "[mathesis] == Xi0 THE SEED CYCLE (DOCS/III-MATHESIS-MAP.md) =="
gate 2600_mathesis_admit   || exit 10
gate 2601_mathesis_dispose || exit 11
gate 2602_mathesis_measure || exit 12
gate 2603_mathesis_seal    || exit 13

# [5] the measured, live effect of the assimilated theorem
echo "[mathesis] == [5] the measured effect (live compiler, sq08_mixed) =="
GEN="$RUN/gen_sq08.iii"
timeout 60 "$IIIS" "$III_ROOT/COMPILER/BOOT/square_probes/sq08_mixed.iii" --emit-svir --out "$GEN" >/dev/null 2>&1 \
    || { echo "[mathesis] RED: emit sq08"; exit 14; }
NBYTES=$(sed -n 's/.*\[u8; \([0-9]*\)\].*/\1/p' "$GEN" | head -1)
[[ -n "$NBYTES" && "$NBYTES" -le 484 ]] || { echo "[mathesis] RED: sq08 container $NBYTES bytes (want <=484 < the 494 baseline)"; exit 15; }
timeout 120 "$IIIS" "$GEN" --compile-only --out "$RUN/gen_sq08.o" >/dev/null 2>&1 || { echo "[mathesis] RED: gen compile"; exit 16; }
[[ -f "$III_ROOT/STDLIB/build/mathesis/mathesis_census_main.o" ]] || \
    timeout 120 "$IIIS" "$III_ROOT/STDLIB/sovir/mathesis_census_main.iii" --compile-only \
        --out "$III_ROOT/STDLIB/build/mathesis/mathesis_census_main.o" >/dev/null 2>&1 || { echo "[mathesis] RED: census driver compile"; exit 17; }
gcc "$III_ROOT/STDLIB/build/mathesis/mathesis_census_main.o" "$RUN/gen_sq08.o" "$LIB" -lws2_32 -lkernel32 \
    -o "$RUN/census_sq08$BIN_SUFFIX" 2>/dev/null || { echo "[mathesis] RED: census link"; exit 18; }
staged="/tmp/mxc_$$_$RANDOM$BIN_SUFFIX"; cp "$RUN/census_sq08$BIN_SUFFIX" "$staged"
LINE=$(timeout 60 "$staged"); rc=$?; rm -f "$staged"
[[ $rc -eq 0 ]] || { echo "[mathesis] RED: census run rc=$rc"; exit 19; }
echo "[mathesis] census: $LINE ($NBYTES bytes)"
case "$LINE" in *" c1=0 "*) : ;; *) echo "[mathesis] RED: windows survive the fold ($LINE)"; exit 20;; esac

echo "[mathesis] == backend gate (parity + goldens + square) =="
bash "$III_ROOT/COMPILER/BOOT/run_svir_backend_gate.sh" >/dev/null 2>&1 || { echo "[mathesis] RED: backend gate"; exit 21; }
echo "[mathesis] GREEN: backend gate (A1 parity + A2 goldens + N=E=S square)"

echo "[mathesis] ============================================================"
echo "[mathesis] Xi0 SEED CYCLE CLOSED: measured -> conjectured -> PROVEN ->"
echo "[mathesis] admitted (MATHESIS-THEOREM-0001) -> assimilated (cg_svir fold)"
echo "[mathesis] -> re-verified (square green) -> measured strict decrease."
echo "[mathesis] ============================================================"
exit 0
