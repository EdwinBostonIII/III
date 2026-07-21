#!/usr/bin/env bash
# horos_gate.sh -- THE BOUNDARY-STONE RITE, re-derived from clean objects every run.
#
# HOROS registers per-export obligation scrolls and discharges them by the ONE entailment
# (composing PRAXIS). THE STONE TOOTH below greps the LIVE praxis.iii export surface and demands
# every export carries a registered stone in horos.iii -- an export added without a stone reddens
# this gate. Exit 0 = green + byte-deterministic.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/horos"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"; cd "$ROOT"
[ -x "$IIIS" ] || { echo "[horos_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[horos_gate] no archive: $ARC"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[horos_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[horos_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -6 "$out.log"; return 1
}

cc_one "$ROOT/STDLIB/iii/omnia/horos.iii"     "$T/horos.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/praxis.iii"    "$T/praxis.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"   "$T/eidolos.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/exec_cert.iii" "$T/exec_cert.o" || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"      "$T/isub.o"      || exit 2
cc_one "$ROOT/STDLIB/iii/numera/idfold.iii"   "$T/idfold.o"    || exit 2

rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/horos.exe"
    gcc -o "$T/horos.exe" "$T/horos.o" "$T/praxis.o" "$T/eidolos.o" "$T/exec_cert.o" "$T/isub.o" "$T/idfold.o" "$ARC" \
        -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/horos.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[horos_gate] LINK FAIL rc=$rc"; tail -6 "$T/link.log"; exit 3; }

STG="$T/horos_run.exe"
cp "$T/horos.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; rc1=$?
cp "$T/horos.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; rc2=$?; rm -f "$STG"
[ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] || { echo "[horos_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2"; tail -6 "$T/run1.txt"; exit 4; }
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[horos_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 5; }
grep -q "horos_selfprove = 0" "$T/run1.txt" || { echo "[horos_gate] not green"; tail "$T/run1.txt"; exit 6; }

# --- THE STONE TOOTH: every LIVE praxis export must carry a registered boundary-stone ---------
missing=0
for ex in $(grep -E '^fn (px_[a-z_0-9]+|praxis_selfprove)\(' "$ROOT/STDLIB/iii/omnia/praxis.iii" | grep '@export' | sed -E 's/^fn ([a-z_0-9]+)\(.*/\1/'); do
    grep -qF "hr_register(\"$ex\"" "$ROOT/STDLIB/iii/omnia/horos.iii" || { echo "[horos_gate] NAKED EXPORT: $ex has no boundary-stone in horos.iii"; missing=1; }
done
[ "$missing" -eq 0 ] || exit 7
echo "[horos_gate] STONE TOOTH: every live praxis export carries a registered stone."

echo "[horos_gate] THE BOUNDARY-STONES STAND -- green + byte-deterministic:"
cat "$T/run1.txt"
exit 0
