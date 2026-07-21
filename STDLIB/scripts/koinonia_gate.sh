#!/usr/bin/env bash
# koinonia_gate.sh -- THE COMMUNION RITE: re-derived from clean objects every run.
#
# KOINONIA (omnia/koinonia.iii) is the money-engine in communion with the sealed aether federation
# (III-FEDERATION B2 / R1.B2), under one law: TIER-GATED OUTBOUND (§2).  A ZK-hunt finding (an
# under-constrained circuit -- a forged witness w0 with row.w0 = 0 over the field) becomes a WITNESSED
# event (omnia/isub merkle root).  Its TIER decides whether it may leave the machine: a finding lifts to
# FED_TIER_SOVEREIGN (a cross-org disclosure) and is SEALED into the append-only witness chain
# (aether/fed_seal, under the PLANETARY fabric) ONLY when KOINONIA's own EXACT check confirms the forgery.
# A false / unproven finding stays FED_TIER_HOST -- local, unsealed, forever.  The proof IS the passport.
#
# This rite compiles KOINONIA + the canon-layer isub + exec_cert with the in-tree compiler (fed_tier/
# fed_seal + all deps resolve from libiii_native.a), links its own probe main, and demands:
#   1. THE COMMUNION GREEN (koinonia_selfprove = 0): a PROVEN finding crosses (SOVEREIGN) + seals; a FALSE
#      finding stays HOST, unsealed; the witnessed STANDING chain root accumulates with each proof only.
#   2. THE LIVE DEMO prints proof-gates-boundary end to end.
#   3. The whole rite BYTE-DETERMINISTIC (two runs, one transcript) -- exactness has no epsilon.
# Exit 0 = green; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/koinonia"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
cd "$ROOT"

[ -x "$IIIS" ] || { echo "[koinonia_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[koinonia_gate] no archive: $ARC (run build_stdlib.sh)"; exit 2; }

cc_one() {
    # settle-retry: OneDrive/AV race is counted, never silent (the settle-retry law)
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[koinonia_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[koinonia_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -6 "$out.log"; return 1
}

# canon-layer isub + its exec_cert dep are fresher than the archive -> compile them here; koinonia's own main.
cc_one "$ROOT/STDLIB/iii/omnia/koinonia.iii"  "$T/koinonia.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"      "$T/isub.o"      || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/exec_cert.iii" "$T/exec_cert.o" || exit 2

# link (fresh objects first so they win over stale archive members; fed_tier/fed_seal/sha256/etc from archive).
rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/koinonia.exe"
    gcc -o "$T/koinonia.exe" "$T/koinonia.o" "$T/isub.o" "$T/exec_cert.o" "$ARC" \
        -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1
    rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/koinonia.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[koinonia_gate] LINK FAIL rc=$rc (after 5 lock-retries)"; tail -6 "$T/link.log"; exit 3; }

# stage outside the OneDrive-watched tree (Defender exec-policy hardening)
STG="/tmp/koinonia_$$_$RANDOM.exe"
cp "$T/koinonia.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; rc1=$?; rm -f "$STG"
cp "$T/koinonia.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; rc2=$?; rm -f "$STG"
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[koinonia_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2 (koinonia_selfprove != 0)"; tail -8 "$T/run1.txt"; exit 4
fi
if ! cmp -s "$T/run1.txt" "$T/run2.txt"; then
    echo "[koinonia_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head -10; exit 5
fi

grep -q "SOVEREIGN" "$T/run1.txt" || { echo "[koinonia_gate] no SOVEREIGN crossing named"; tail -8 "$T/run1.txt"; exit 6; }
grep -qi "never leaves the machine" "$T/run1.txt" || { echo "[koinonia_gate] no HOST-hold of the false finding"; tail -8 "$T/run1.txt"; exit 6; }

echo "[koinonia_gate] THE COMMUNION IS GREEN -- proof gates the federation boundary, byte-deterministic:"
grep -Ei "PROVEN|FALSE|GREEN:" "$T/run1.txt" | head -3
exit 0
