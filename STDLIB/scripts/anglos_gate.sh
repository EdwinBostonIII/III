#!/usr/bin/env bash
# anglos_gate.sh -- THE ENGLISH DOOR RITE: the tongue over the vein and the
# door, re-derived from clean objects every run.
#
# The gate compiles the English organs (verba/nl_lex + verba/nl_parse), the
# tongue (anglos), the vein (xring), the door (xenos), the interlingua
# (eidolos + isub), the universal lexicon, and the foreign wire the house
# already owns (verba/json + verba/builder + memoria/arena), links the probe,
# and demands:
#   1. THE VEIN GREEN (xring 120..124) and THE DOOR GREEN (xenos 109..118).
#   2. THE TONGUE GREEN (anglos 390..399): one sentence one claim through the
#      one door deterministic twice; all three verbs reached and entailed
#      back; the determiner law; adjective predication; "and" composing while
#      "or" refuses; every refusal named and counted; questions answered by
#      derivation; the whole-utterance law; the vein carrying the tongue
#      transport-transparent; English OUT re-hearing to the same address.
#   3. A real utterance (a constant-product market described in English)
#      ADMITTED through the one door, its question answered KNOWN, and the
#      standing scroll spoken back and re-heard to the SAME address.
#   4. The whole rite BYTE-DETERMINISTIC (two runs, one transcript).
# Exit 0 = green; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/anglos"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
mkdir -p "$ROOT/STDLIB/data"
cd "$ROOT"

[ -x "$IIIS" ] || { echo "[anglos_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[anglos_gate] no archive: $ARC"; exit 2; }

cc_one() {
    # settle-retry: OneDrive/AV race is counted, never silent
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[anglos_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[anglos_gate] COMPILE FAIL rc=$rc $(basename "$src")"
    tail -4 "$out.log"
    return 1
}

cc_one "$ROOT/STDLIB/iii/aether/anglos.iii"   "$T/anglos.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/aether/proxenos.iii" "$T/proxenos.o" || exit 2
cc_one "$ROOT/STDLIB/iii/aether/oikos.iii"    "$T/oikos.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/aether/kalodion.iii" "$T/kalodion.o" || exit 2
cc_one "$ROOT/STDLIB/iii/verba/nl_lex.iii"    "$T/nl_lex.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/verba/nl_parse.iii"  "$T/nl_parse.o" || exit 2
cc_one "$ROOT/STDLIB/iii/aether/xring.iii"    "$T/xring.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/aether/xenos.iii"    "$T/xenos.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"   "$T/eidolos.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"      "$T/isub.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/verba/lexicon.iii"   "$T/lexicon.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/verba/json.iii"      "$T/json.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/verba/builder.iii"   "$T/builder.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/memoria/arena.iii"   "$T/arena.o"    || exit 2
cc_one "$ROOT/STDLIB/build/anglos/anprobe_main.iii" "$T/anprobe_main.o" || exit 2

gcc -o "$T/anprobe.exe" \
    "$T/anprobe_main.o" "$T/anglos.o" "$T/proxenos.o" "$T/oikos.o" "$T/nl_lex.o" "$T/nl_parse.o" \
    "$T/xenos.o" "$T/xring.o" "$T/kalodion.o" "$T/eidolos.o" "$T/isub.o" \
    "$T/lexicon.o" "$T/json.o" "$T/builder.o" "$T/arena.o" \
    "$ARC" -lws2_32 -lkernel32 \
    || { echo "[anglos_gate] LINK FAIL"; exit 3; }

# a fresh book each run so the byte-compare reflects THIS rite's knocks
rm -f "$ROOT/STDLIB/data/xenos.gbk"
"$T/anprobe.exe" > "$T/run1.txt" 2>&1
rc1=$?
rm -f "$ROOT/STDLIB/data/xenos.gbk"
"$T/anprobe.exe" > "$T/run2.txt" 2>&1
rc2=$?
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[anglos_gate] BATTERY RED rc1=$rc1 rc2=$rc2"
    tail -8 "$T/run1.txt"
    exit 4
fi
if ! cmp -s "$T/run1.txt" "$T/run2.txt"; then
    echo "[anglos_gate] NONDETERMINISM"
    diff "$T/run1.txt" "$T/run2.txt" | head -10
    exit 5
fi
grep -q "^scroll vein   = 120..124 green" "$T/run1.txt"  || { echo "[anglos_gate] NO VEIN"; exit 6; }
grep -q "^scroll door   = 109..118 green" "$T/run1.txt"  || { echo "[anglos_gate] NO DOOR"; exit 6; }
grep -q "^scroll anglos = 390..399 green" "$T/run1.txt"  || { echo "[anglos_gate] NO TONGUE"; exit 6; }
grep -q "^scroll sponsor = 400..404 green" "$T/run1.txt" || { echo "[anglos_gate] NO SPONSOR"; exit 6; }
grep -q "^scroll house  = 410..414 green" "$T/run1.txt"  || { echo "[anglos_gate] NO HOUSE"; exit 6; }
grep -q "^scroll sponsor= confirmed without narrowing" "$T/run1.txt" || { echo "[anglos_gate] NO SPONSORSHIP"; exit 6; }
grep -q "^the hearing: claims=2 grade=1 " "$T/run1.txt"  || { echo "[anglos_gate] NO HEARING"; exit 6; }
grep -q " : KNOWN$" "$T/run1.txt"                        || { echo "[anglos_gate] NO ANSWER"; exit 6; }
grep -q "^scroll say    = [0-9].* same address" "$T/run1.txt" || { echo "[anglos_gate] NO SAY"; exit 6; }
grep -q "^scroll book   = [0-9].* self-derived" "$T/run1.txt" || { echo "[anglos_gate] NO BOOK"; exit 6; }
[ -s "$ROOT/STDLIB/data/xenos.gbk" ] || { echo "[anglos_gate] NO GUEST-BOOK FILE"; exit 6; }
echo "[anglos_gate] THE ENGLISH DOOR IS GREEN -- tongue + vein + door, byte-deterministic:"
grep "^scroll" "$T/run1.txt"
exit 0
