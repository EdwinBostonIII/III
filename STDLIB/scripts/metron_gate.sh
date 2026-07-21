#!/usr/bin/env bash
# metron_gate.sh -- THE MEASURE RITE, re-derived from clean objects every run.
#
# METRON judges declared cost envelopes against counts measured EXACTLY by the live exec_cert
# fold under real px_pin calls (linear holds, quadratic refused), and measures descriptive
# redundancy as verdict-table shadowing through the live ONTOS meters. Exit 0 = green +
# byte-deterministic.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/metron"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"; cd "$ROOT"
[ -x "$IIIS" ] || { echo "[metron_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[metron_gate] no archive: $ARC"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[metron_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[metron_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -6 "$out.log"; return 1
}

cc_one "$ROOT/STDLIB/iii/omnia/metron.iii"         "$T/metron.o"        || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/praxis.iii"         "$T/praxis.o"        || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"        "$T/eidolos.o"       || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/exec_cert.iii"      "$T/exec_cert.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/ontos.iii"          "$T/ontos.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"           "$T/isub.o"          || exit 2
cc_one "$ROOT/STDLIB/iii/numera/idfold.iii"        "$T/idfold.o"        || exit 2
cc_one "$ROOT/STDLIB/iii/aether/bounty_attest.iii" "$T/bounty_attest.o" || exit 2
cc_one "$ROOT/STDLIB/iii/katabasis/kardia.iii"     "$T/kardia.o"        || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/ptyxis.iii"         "$T/ptyxis.o"        || exit 2

rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/metron.exe"
    gcc -o "$T/metron.exe" "$T/metron.o" "$T/praxis.o" "$T/eidolos.o" "$T/exec_cert.o" "$T/ontos.o" "$T/isub.o" "$T/idfold.o" "$T/bounty_attest.o" "$T/kardia.o" "$T/ptyxis.o" "$ARC" \
        -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/metron.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[metron_gate] LINK FAIL rc=$rc"; tail -6 "$T/link.log"; exit 3; }

STG="$T/metron_run.exe"
cp "$T/metron.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; rc1=$?
cp "$T/metron.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; rc2=$?; rm -f "$STG"
[ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] || { echo "[metron_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2"; tail -6 "$T/run1.txt"; exit 4; }
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[metron_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 5; }
grep -q "metron_selfprove = 0" "$T/run1.txt" || { echo "[metron_gate] not green"; tail "$T/run1.txt"; exit 6; }

echo "[metron_gate] THE MEASURE HOLDS -- green + byte-deterministic:"
cat "$T/run1.txt"
exit 0
