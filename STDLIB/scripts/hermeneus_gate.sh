#!/usr/bin/env bash
# hermeneus_gate.sh -- THE INTERPRETER RITE: the English-to-EIDOLOS door, re-derived from clean
# objects every run.
#
# Compiles the door (hermeneus) with the IN-TREE compiler, plus everything it composes -- the
# tongue (eidolos + isub), the proven reduction/delivery back-end (diadosis), the vocabulary
# discipline (lexicon), and the foreign door it reuses for the external muse (xenos + xring +
# kalodion + json + builder + arena) -- links the probe (hermeneus's own main), and demands:
#   1. THE DOOR GREEN (hermeneus_selfprove = 0): all 18 arms -- the deterministic proposer exact
#      on < = ~ and TOTALLY refusing off-domain; the read-back inverse (parse(gloss(C)) == C);
#      vetting (cycle refused, alien flagged); the confirm-pin WALL (no unconfirmed/mismatched
#      delivery); the DIADOSIS seam-exactness + closure; and the external XENOS door (truthful
#      admitted PROVISIONAL, incoherent refused).
#   2. THE LIVE DEMO prints an English utterance carried end to end.
#   3. The whole rite BYTE-DETERMINISTIC (two runs, one transcript).
# Exit 0 = green; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/hermeneus"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
cd "$ROOT"

[ -x "$IIIS" ] || { echo "[hermeneus_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[hermeneus_gate] no archive: $ARC (run build_stdlib.sh)"; exit 2; }

cc_one() {
    # settle-retry: OneDrive/AV race is counted, never silent
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[hermeneus_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[hermeneus_gate] COMPILE FAIL rc=$rc $(basename "$src")"
    tail -6 "$out.log"
    return 1
}

cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"    "$T/eidolos.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"       "$T/isub.o"      || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/diadosis.iii"   "$T/diadosis.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/verba/lexicon.iii"    "$T/lexicon.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/aether/xring.iii"     "$T/xring.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/aether/kalodion.iii"  "$T/kalodion.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/aether/xenos.iii"     "$T/xenos.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/verba/json.iii"       "$T/json.o"      || exit 2
cc_one "$ROOT/STDLIB/iii/verba/builder.iii"    "$T/builder.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/memoria/arena.iii"    "$T/arena.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/hermeneus.iii"  "$T/hermeneus.o" || exit 2

# diadosis and hermeneus both define `main`; localize diadosis's so the probe's main is the sole
# global one (compose the proven back-end without dragging its standalone demo entry point).
objcopy --localize-symbol=main "$T/diadosis.o" "$T/diadosis_lib.o" \
    || { echo "[hermeneus_gate] objcopy FAIL"; exit 3; }

gcc -o "$T/hermeneus.exe" \
    "$T/hermeneus.o" "$T/eidolos.o" "$T/isub.o" "$T/diadosis_lib.o" "$T/lexicon.o" \
    "$T/xenos.o" "$T/xring.o" "$T/kalodion.o" "$T/json.o" "$T/builder.o" "$T/arena.o" \
    "$ARC" -lws2_32 -lkernel32 \
    || { echo "[hermeneus_gate] LINK FAIL"; exit 3; }

"$T/hermeneus.exe" > "$T/run1.txt" 2>&1
rc1=$?
"$T/hermeneus.exe" > "$T/run2.txt" 2>&1
rc2=$?
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[hermeneus_gate] DOOR RED rc1=$rc1 rc2=$rc2"
    tail -8 "$T/run1.txt"
    exit 4
fi
if ! cmp -s "$T/run1.txt" "$T/run2.txt"; then
    echo "[hermeneus_gate] NONDETERMINISM"
    diff "$T/run1.txt" "$T/run2.txt" | head -10
    exit 5
fi
grep -q "^hermeneus_selfprove = 0" "$T/run1.txt" || { echo "[hermeneus_gate] NOT GREEN"; tail -8 "$T/run1.txt"; exit 6; }
grep -q "^  delivered: DIADOSIS handle" "$T/run1.txt" || { echo "[hermeneus_gate] NO DEMO"; exit 6; }
echo "[hermeneus_gate] THE INTERPRETER IS GREEN -- English crosses to EIDOLOS, byte-deterministic:"
grep -E "^(  english|  proposed|  read-back|  confirm|  delivered|hermeneus_selfprove)" "$T/run1.txt"
exit 0
