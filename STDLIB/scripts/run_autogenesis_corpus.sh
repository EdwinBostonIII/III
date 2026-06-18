#!/usr/bin/env bash
# run_autogenesis_corpus.sh -- the dedicated autogenesis-block runner (corpus 1400-1409 + the
# propose-only gate).  run_all_corpora.sh delegates the autogenesis block here.  It links each KAT
# against the LIVE libiii_native.a (which build_stdlib.sh populates with the seven autogenesis
# modules) and runs it, then runs the propose-only structural gate.  GREEN iff every KAT exits 99
# and the gate passes.  Object lists honour the space in the absolute build path.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STDLIB="$ROOT/STDLIB"; B="$STDLIB/build/iii"
IIIS="$ROOT/COMPILED/iiis-2.exe"; [ -x "$IIIS" ] || IIIS="$ROOT/COMPILED/iiis-2"
ARCH="$B/libiii_native.a"
[ -f "$ARCH" ] || { echo "FATAL: $ARCH missing -- run build_stdlib.sh first" >&2; exit 2; }
[ -x "$IIIS" ] || { echo "FATAL: iiis-2 not found" >&2; exit 2; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

KATS=(1400_self_model 1401_gap_conjecture 1402_harmony_synth 1403_refactor_propose \
      1404_optimize_self 1405_theorem_grow 1406_autogenesis_cycle 1407_autogenesis_revert \
      1408_autogenesis_attest 1409_autogenesis_charter)

RC=0; PASS=0; FAIL=0
for t in "${KATS[@]}"; do
    src="$STDLIB/corpus/$t.iii"
    if ! "$IIIS" "$src" --compile-only --out "$TMP/$t.o" >/dev/null 2>&1; then echo "  FAIL $t : compile"; FAIL=$((FAIL+1)); RC=1; continue; fi
    if ! gcc "$TMP/$t.o" "$ARCH" -lws2_32 -lkernel32 -o "$TMP/$t.exe" >/dev/null 2>&1; then echo "  FAIL $t : link"; FAIL=$((FAIL+1)); RC=1; continue; fi
    st="$TMP/staged.exe"; cp "$TMP/$t.exe" "$st"; ( cd "$TMP" && ./staged.exe >/dev/null 2>&1 ); rc=$?
    if [ "$rc" = 99 ]; then echo "  PASS $t : 99"; PASS=$((PASS+1)); else echo "  FAIL $t : got $rc want 99"; FAIL=$((FAIL+1)); RC=1; fi
done
echo "--- autogenesis KATs: PASS=$PASS FAIL=$FAIL (of ${#KATS[@]}) ---"

echo "=== propose-only gate (trust-root isolation + commit chokepoint) ==="
if bash "$STDLIB/scripts/verify_autogenesis_propose_only.sh" >"$TMP/po.log" 2>&1; then
    grep -E 'GATE:' "$TMP/po.log" | tail -1
else
    echo "  propose-only gate FAILED"; grep -E 'RED|GATE:' "$TMP/po.log" | tail -3; RC=1
fi

echo "----------------------------------------------------------------"
if [ "$RC" = 0 ]; then
    echo "RUN_AUTOGENESIS_CORPUS: GREEN -- $PASS KATs (=99) + propose-only gate."
else
    echo "RUN_AUTOGENESIS_CORPUS: RED -- see failures above."
fi
exit $RC
