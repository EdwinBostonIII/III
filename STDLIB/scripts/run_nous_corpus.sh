#!/usr/bin/env bash
# run_nous_corpus.sh -- the dedicated nous-block runner (corpus 800-808 + the two gates).
#
# run_corpus.sh delegates the nous block here (mirroring run_xii_corpus.sh's ownership of
# the XII block).  It links each nous KAT against the LIVE libiii_native.a (which
# build_stdlib.sh populates with the 11 nous modules) and runs it, then runs the keystone
# differential gate and the propose-only gate.  GREEN iff every KAT exits 99 and both
# gates pass.  Object lists are bash ARRAYS ($B is absolute and contains a space).
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STDLIB="$ROOT/STDLIB"; B="$STDLIB/build/iii"
IIIS="$ROOT/COMPILED/iiis-2.exe"; [ -x "$IIIS" ] || IIIS="$ROOT/COMPILED/iiis-2"
ARCH="$B/libiii_native.a"
[ -f "$ARCH" ] || { echo "FATAL: $ARCH missing -- run build_stdlib.sh first" >&2; exit 2; }
[ -x "$IIIS" ] || { echo "FATAL: iiis-2 not found" >&2; exit 2; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

KATS=(800_nous_socket 801_nous_costlin 802_nous_search 803_nous_charter 804_nous_policy \
      805_nous_completion 806_nous_commons 807_nous_train 808_nous_synth 809_nous_behavioral_key)

SE_ARR=()
for n in omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o \
         omnia_proof_ripple_resolution.iii.o omnia_resolver.iii.o omnia_resolver_memo.iii.o \
         omnia_resolver_replay.iii.o omnia_codegen_patterns.iii.o omnia_transform_patterns.iii.o \
         omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o aether_pattern_set_federation.iii.o \
         sanctus_calculus_v1.iii.o sanctus_resolver_replay.iii.o sanctus_seal_resolver.iii.o \
         verba_nl_lex.iii.o resolver_hot.o resolver_unit.o resolver_unit_avx512.o bench_helpers.o; do
    [ -f "$B/$n" ] && SE_ARR+=("$B/$n")
done

RC=0; PASS=0; FAIL=0
for t in "${KATS[@]}"; do
    src="$STDLIB/corpus/$t.iii"
    if ! "$IIIS" "$src" --compile-only --out "$TMP/$t.o" >/dev/null 2>&1; then echo "  FAIL $t : compile"; FAIL=$((FAIL+1)); RC=1; continue; fi
    if ! gcc "$TMP/$t.o" -Wl,--whole-archive "${SE_ARR[@]}" -Wl,--no-whole-archive "$ARCH" -lws2_32 -lkernel32 -o "$TMP/$t.exe" >/dev/null 2>&1; then echo "  FAIL $t : link"; FAIL=$((FAIL+1)); RC=1; continue; fi
    st="$TMP/staged.exe"; cp "$TMP/$t.exe" "$st"; "$st" >/dev/null 2>&1; rc=$?
    if [ "$rc" = 99 ]; then echo "  PASS $t : 99"; PASS=$((PASS+1)); else echo "  FAIL $t : got $rc want 99"; FAIL=$((FAIL+1)); RC=1; fi
done
echo "--- nous KATs: PASS=$PASS FAIL=$FAIL (of ${#KATS[@]}) ---"

echo "=== keystone differential gate (active 0 vs cascade vs policy) ==="
if bash "$STDLIB/scripts/verify_nous_differential.sh" >"$TMP/diff.log" 2>&1; then grep -E 'GATE:|compared=' "$TMP/diff.log" | tail -2; else echo "  differential gate FAILED"; grep -E 'DIVERGENCE|GATE:' "$TMP/diff.log" | tail -5; RC=1; fi

echo "=== propose-only gate (trust-root isolation + chokepoint) ==="
if bash "$STDLIB/scripts/verify_nous_propose_only.sh" >"$TMP/po.log" 2>&1; then grep -E 'GATE:' "$TMP/po.log" | tail -1; else echo "  propose-only gate FAILED"; grep -E 'RED|GATE:' "$TMP/po.log" | tail -3; RC=1; fi

echo "----------------------------------------------------------------"
if [ "$RC" = 0 ]; then
    echo "RUN_NOUS_CORPUS: GREEN -- $PASS KATs (=99) + differential gate + propose-only gate."
else
    echo "RUN_NOUS_CORPUS: RED"
fi
exit $RC
