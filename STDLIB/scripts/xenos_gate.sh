#!/usr/bin/env bash
# xenos_gate.sh -- THE MEMBRANE RITE: the vein and the door, re-derived from
# clean objects every run.
#
# The gate compiles the bare-metal vein (xring) and the membrane of xenia
# (xenos) with the IN-TREE compiler, plus the interlingua they ride on
# (eidolos + isub), the universal lexicon (the door's own event vocabulary),
# and the foreign wire the house already owns (verba/json + verba/builder +
# memoria/arena), links the probe, and demands:
#   1. THE VEIN GREEN (xring 120..124): byte-exact FIFO across the wrap seam,
#      whole-frame refusals, torn-frame severance, monotone cursors.
#   2. THE DOOR GREEN (xenos 109..118): the vein carries a guest to the door
#      unchanged; total structural transduction of a real foreign tree with a
#      re-derived fixpoint; the guest-is-the-value naming; the claim-array and
#      envelope grades; the law judging (cycle refused, lying address refused);
#      the axiom handshake (a foreign soul quarantined); the same door emitting
#      through the REAL json parser; the tamper-evident guest-book; the throat;
#      the vocabulary at the door.
#   3. A real stranger (the two-pool DeFi arbitrage config) ADMITTED and
#      crushed into eidolos containment algebra, then re-emitted.
#   4. The whole rite BYTE-DETERMINISTIC (two runs, one transcript).
# Exit 0 = green; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/xenos"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
mkdir -p "$ROOT/STDLIB/data"
cd "$ROOT"

[ -x "$IIIS" ] || { echo "[xenos_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[xenos_gate] no archive: $ARC"; exit 2; }

cc_one() {
    # settle-retry: OneDrive/AV race is counted, never silent
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[xenos_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[xenos_gate] COMPILE FAIL rc=$rc $(basename "$src")"
    tail -4 "$out.log"
    return 1
}

cc_one "$ROOT/STDLIB/iii/aether/xring.iii"    "$T/xring.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/aether/xenos.iii"    "$T/xenos.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"   "$T/eidolos.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"      "$T/isub.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/verba/lexicon.iii"   "$T/lexicon.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/verba/json.iii"      "$T/json.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/verba/builder.iii"   "$T/builder.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/memoria/arena.iii"   "$T/arena.o"    || exit 2
cc_one "$ROOT/STDLIB/build/xenos/xnprobe_main.iii" "$T/xnprobe_main.o" || exit 2

gcc -o "$T/xnprobe.exe" \
    "$T/xnprobe_main.o" "$T/xenos.o" "$T/xring.o" "$T/eidolos.o" "$T/isub.o" \
    "$T/lexicon.o" "$T/json.o" "$T/builder.o" "$T/arena.o" \
    "$ARC" -lws2_32 -lkernel32 \
    || { echo "[xenos_gate] LINK FAIL"; exit 3; }

# a fresh book each run so the byte-compare reflects THIS rite's knocks
rm -f "$ROOT/STDLIB/data/xenos.gbk"
"$T/xnprobe.exe" > "$T/run1.txt" 2>&1
rc1=$?
rm -f "$ROOT/STDLIB/data/xenos.gbk"
"$T/xnprobe.exe" > "$T/run2.txt" 2>&1
rc2=$?
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[xenos_gate] BATTERY RED rc1=$rc1 rc2=$rc2"
    tail -6 "$T/run1.txt"
    exit 4
fi
if ! cmp -s "$T/run1.txt" "$T/run2.txt"; then
    echo "[xenos_gate] NONDETERMINISM"
    diff "$T/run1.txt" "$T/run2.txt" | head -10
    exit 5
fi
grep -q "^scroll vein   = 120..124 green" "$T/run1.txt" || { echo "[xenos_gate] NO VEIN"; exit 6; }
grep -q "^scroll door   = 109..118 green" "$T/run1.txt" || { echo "[xenos_gate] NO DOOR"; exit 6; }
grep -q "^the stranger: grade=0 " "$T/run1.txt"         || { echo "[xenos_gate] NO STRANGER"; exit 6; }
grep -q "^scroll emit   = [0-9]" "$T/run1.txt"          || { echo "[xenos_gate] NO EMIT"; exit 6; }
grep -q "^scroll book   = [0-9].* self-derived" "$T/run1.txt" || { echo "[xenos_gate] NO BOOK"; exit 6; }
[ -s "$ROOT/STDLIB/data/xenos.gbk" ] || { echo "[xenos_gate] NO GUEST-BOOK FILE"; exit 6; }
echo "[xenos_gate] THE MEMBRANE IS GREEN -- vein + door, byte-deterministic:"
grep "^scroll" "$T/run1.txt"
exit 0
