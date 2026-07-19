#!/usr/bin/env bash
# hermeneus_gate.sh -- THE ONE ENGLISH DOOR RITE: re-derived from clean objects every run.
#
# Compiles the door (hermeneus) with the IN-TREE compiler, plus everything it COMPOSES -- the
# sensory organ (anglos + nl_lex + nl_parse: the deterministic English->EIDOLOS transducer and
# its say-back), the structural filter (xenos + xring + kalodion + json + builder + arena), the
# tongue (eidolos + isub), the vocabulary discipline (lexicon), and the proven reduction/delivery
# back-end (diadosis) -- links the probe (hermeneus's own main), and demands:
#   1. THE DOOR GREEN (hermeneus_selfprove = 0): the 7 SEAM + WALL arms -- anglos owns the grammar
#      (its own an_selfprove 390..399), so hermeneus proves only that the transduced claim-array
#      admits through the filter, that the an_say read-back is the EXACT confirm key, that an
#      unconfirmed standing claim yields the WALL, that the confirmed path is seam-exact to
#      DIADOSIS and closes at the consumer, and that the external muse rides the same chokepoint.
#   2. THE LIVE DEMO prints a rich English utterance (determiners + adjective + "and") end to end.
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
cc_one "$ROOT/STDLIB/iii/verba/nl_lex.iii"     "$T/nl_lex.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/verba/nl_parse.iii"   "$T/nl_parse.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/aether/anglos.iii"    "$T/anglos.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/hermeneus.iii"  "$T/hermeneus.o" || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/hermeneus_cli.iii" "$T/hermeneus_cli.o" || exit 2

# diadosis and hermeneus both define `main`; localize diadosis's so the probe's main is the sole
# global one (compose the proven back-end without dragging its standalone demo entry point).
objcopy --localize-symbol=main "$T/diadosis.o" "$T/diadosis_lib.o" \
    || { echo "[hermeneus_gate] objcopy FAIL"; exit 3; }

gcc -o "$T/hermeneus.exe" \
    "$T/hermeneus_cli.o" "$T/hermeneus.o" "$T/eidolos.o" "$T/isub.o" "$T/diadosis_lib.o" "$T/lexicon.o" \
    "$T/xenos.o" "$T/xring.o" "$T/kalodion.o" "$T/json.o" "$T/builder.o" "$T/arena.o" \
    "$T/anglos.o" "$T/nl_lex.o" "$T/nl_parse.o" \
    "$ARC" -lws2_32 -lkernel32 \
    || { echo "[hermeneus_gate] LINK FAIL"; exit 3; }

# 1. THE CONDITION OF MOTION: `iii hermeneus prove` self-proves the logos, vein, door, lexicon,
#    tongue, back-end, and immune system (exit 9 on any red).  Deterministic -> run twice.
"$T/hermeneus.exe" prove > "$T/run1.txt" 2>&1
rc1=$?
"$T/hermeneus.exe" prove > "$T/run2.txt" 2>&1
rc2=$?
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[hermeneus_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2"
    tail -8 "$T/run1.txt"
    exit 4
fi
if ! cmp -s "$T/run1.txt" "$T/run2.txt"; then
    echo "[hermeneus_gate] NONDETERMINISM (prove)"
    diff "$T/run1.txt" "$T/run2.txt" | head -10
    exit 5
fi
grep -q "^THE ONE ENGLISH DOOR PROVEN" "$T/run1.txt" || { echo "[hermeneus_gate] NOT PROVEN"; tail -8 "$T/run1.txt"; exit 6; }

# 2. THE LIVE PATH: rich English (determiner + adjective + "and") delivered end to end, twice.
"$T/hermeneus.exe" deliver "the dream is a proof and the proof equals the law" > "$T/deliver1.txt" 2>&1
rcd1=$?
"$T/hermeneus.exe" deliver "the dream is a proof and the proof equals the law" > "$T/deliver2.txt" 2>&1
rcd2=$?
if [ "$rcd1" -ne 0 ] || [ "$rcd2" -ne 0 ]; then echo "[hermeneus_gate] DELIVER FAIL rcd1=$rcd1 rcd2=$rcd2"; tail -8 "$T/deliver1.txt"; exit 4; fi
if ! cmp -s "$T/deliver1.txt" "$T/deliver2.txt"; then echo "[hermeneus_gate] NONDETERMINISM (deliver)"; exit 5; fi
grep -q "^  claims   : \[dream < proof\] \[proof = law\]" "$T/deliver1.txt" || { echo "[hermeneus_gate] WRONG CLAIMS"; cat "$T/deliver1.txt"; exit 6; }
grep -q "delivered into DIADOSIS at handle" "$T/deliver1.txt" || { echo "[hermeneus_gate] NO DELIVERY"; exit 6; }

# 3. THE WALL: the REPL HOLDS an unconfirmed proposal ('no'), delivering nothing.
printf 'the dream is a proof\nno\nquit\n' | "$T/hermeneus.exe" > "$T/wall1.txt" 2>&1
grep -q "held -- the wall stands" "$T/wall1.txt" || { echo "[hermeneus_gate] WALL NOT HELD"; cat "$T/wall1.txt"; exit 6; }
if grep -q "delivered DIADOSIS handle" "$T/wall1.txt"; then echo "[hermeneus_gate] WALL BREACHED (delivered without yes)"; exit 6; fi

echo "[hermeneus_gate] THE ONE DOOR IS GREEN -- self-proven, byte-deterministic, English delivered, wall held:"
grep -E "^(  claims|  read-back|  CONFIRMED)" "$T/deliver1.txt"
exit 0
