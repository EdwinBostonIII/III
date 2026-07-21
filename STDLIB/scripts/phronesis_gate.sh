#!/usr/bin/env bash
# phronesis_gate.sh -- THE PRACTICAL-JUDGMENT RITE, re-derived from clean objects every run.
#
# PHRONESIS holds six mental-model lenses, each an obligation scroll discharged by the ONE entailment
# (composing PRAXIS): earned on real evidence chains, refused on broken ones, unknown = NAMED.

# Exit 0 = green + byte-deterministic.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/phronesis"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"; cd "$ROOT"
[ -x "$IIIS" ] || { echo "[phronesis_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[phronesis_gate] no archive: $ARC"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[phronesis_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[phronesis_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -6 "$out.log"; return 1
}

cc_one "$ROOT/STDLIB/iii/omnia/phronesis.iii"     "$T/phronesis.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/praxis.iii"    "$T/praxis.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"   "$T/eidolos.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/exec_cert.iii" "$T/exec_cert.o" || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"      "$T/isub.o"      || exit 2
cc_one "$ROOT/STDLIB/iii/numera/idfold.iii"   "$T/idfold.o"    || exit 2

rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/phronesis.exe"
    gcc -o "$T/phronesis.exe" "$T/phronesis.o" "$T/praxis.o" "$T/eidolos.o" "$T/exec_cert.o" "$T/isub.o" "$T/idfold.o" "$ARC" \
        -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/phronesis.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[phronesis_gate] LINK FAIL rc=$rc"; tail -6 "$T/link.log"; exit 3; }

STG="$T/phronesis_run.exe"
cp "$T/phronesis.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; rc1=$?
cp "$T/phronesis.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; rc2=$?; rm -f "$STG"
[ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] || { echo "[phronesis_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2"; tail -6 "$T/run1.txt"; exit 4; }
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[phronesis_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 5; }
grep -q "phronesis_selfprove = 0" "$T/run1.txt" || { echo "[phronesis_gate] not green"; tail "$T/run1.txt"; exit 6; }


echo "[phronesis_gate] THE LENSES ARE LAW -- green + byte-deterministic:"
cat "$T/run1.txt"
exit 0
