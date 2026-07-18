#!/usr/bin/env bash
# summit_gate.sh -- THE SUMMIT RITE: the two capstone theorems, re-derived
# from clean objects every run and sealed as EIDOLOS scrolls.
#
# The gate compiles the whole ascent with the IN-TREE compiler -- pyrgos (the
# constructible tower + the complex closure), riza (the real-closed engine),
# meris (Nekrasov localization), klisi (the perfectoid tilt), eidolos (the
# scroll) and summit (the composition) -- links the probe, and demands:
#   1. every organ battery GREEN (pyrgos 180..195, riza 210..217,
#      kyma 230..240 [Bell/CHSH emerged + Born selected by basis-invariance],
#      meris 250..254 [+ the Faulhaber/Stirling power-sum mint],
#      klisi 260..266 [+ the Hensel/Newton inverse faculty],
#      summit 280..285, gnosis 290..299 [+ the CHRONOMETER: arrival counts
#      and total work minted O(1) from the orbit oracle's decisions, and the
#      DIVISION BRIDGE: the live planner + Montgomery kernel on the
#      substrate identity]);
#   2. THEOREM I (the algebraic node): the crushing contact decided as an
#      exact node -- multiplicity by TWO engines (real-closed gcd with
#      reconstruction vs the 5-adic valuation slope), the contact
#      trichotomy, the product formula's place ledger, the tilt ledger
#      finite and distinct THROUGH the r=0 point;
#   3. THEOREM II (the forced Born weight): entanglement decided, the
#      complete 16-orbit of boolean assignments derived and EXCEEDED by
#      exact sign (Tsirelson 2*sqrt2 met exactly, two correlator engines),
#      the Born exponent surfaced as the UNIQUE basis-invariant weight,
#      the Bell probabilities forced by symmetry + null-weight;
#   4. the two EIDOLOS scrolls sealed with DETERMINISTIC canonical
#      addresses, entailing consequences absent from their text and
#      refusing the reversals;
#   5. the whole rite BYTE-DETERMINISTIC (two runs, one transcript).
# Exit 0 = green; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/summit"
K="$ROOT/STDLIB/build/kinesis"
mkdir -p "$T"

cc_one() {
    # settle-retry: OneDrive/AV race is counted, never silent
    local src="$1" out="$2" try
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[summit_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[summit_gate] COMPILE FAIL rc=$rc $(basename "$src")"
    tail -4 "$out.log"
    return 1
}

cc_one "$ROOT/STDLIB/iii/aether/pyrgos.iii"  "$T/pyrgos.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/aether/kyma.iii"    "$T/kyma.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/aether/riza.iii"    "$T/riza.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/aether/meris.iii"   "$T/meris.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/aether/klisi.iii"   "$T/klisi.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"  "$T/eidolos.o" || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/summit.iii"   "$T/summit.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/gnosis.iii"   "$T/gnosis.o"  || exit 2
cc_one "$K/hzprobe_main.iii"                 "$T/hzprobe_main.o" || exit 2

gcc -o "$T/hzprobe.exe" \
    "$T/riza.o" "$T/pyrgos.o" "$T/kyma.o" "$T/meris.o" "$T/klisi.o" "$T/summit.o" "$T/gnosis.o" "$T/eidolos.o" \
    "$K/sqrt_sum_sign.o" "$K/kfield.o" "$K/arena.o" "$K/bigint.o" "$K/bigint_div.o" "$K/sha256.o" \
    "$T/hzprobe_main.o" \
    "$ROOT/STDLIB/build/iii/libiii_native.a" -lws2_32 -lkernel32 \
    || { echo "[summit_gate] LINK FAIL"; exit 3; }

"$T/hzprobe.exe" all > "$T/run1.txt" 2>&1
rc1=$?
"$T/hzprobe.exe" all > "$T/run2.txt" 2>&1
rc2=$?
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[summit_gate] BATTERY RED rc1=$rc1 rc2=$rc2"
    tail -6 "$T/run1.txt"
    exit 4
fi
if ! cmp -s "$T/run1.txt" "$T/run2.txt"; then
    echo "[summit_gate] NONDETERMINISM"
    diff "$T/run1.txt" "$T/run2.txt" | head -10
    exit 5
fi
grep -q "^scroll gravity = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO GRAVITY SCROLL"; exit 6; }
grep -q "^scroll born    = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO BORN SCROLL"; exit 6; }
grep -q "^scroll gnosis  = [0-9]" "$T/run1.txt" || { echo "[summit_gate] NO GNOSIS SCROLL"; exit 6; }
echo "[summit_gate] THE SUMMIT IS GREEN -- both scrolls sealed, byte-deterministic:"
grep "^scroll" "$T/run1.txt"
exit 0
