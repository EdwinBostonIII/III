#!/usr/bin/env bash
# henosis_gate.sh -- THE UNIFICATION RITE: re-derived from clean objects every run.
#
# HENOSIS (aether/henosis.iii) makes the two independently-built STANDING mechanisms ONE greater whole, on ONE
# identity (the bounty_attest attestation root -- public-artifact-bound, signed):
#   - KOINONIA (omnia/koinonia.iii)     : proof-gated tier-crossing (fed_tier) + fed_seal witness chain.
#   - bounty_attest + bounty_ledger     : signed/anonymous/artifact-bound attestation + merkle portfolio (standing).
# Threaded together, a PROVEN finding is SIMULTANEOUSLY: signed + stranger-verifiable-without-the-secret-trace +
# proof-gated-crossing (SOVEREIGN) + federation-sealed + membership-provable in the sealed portfolio.  A FALSE
# finding is HELD (HOST, unsigned, unsealed, absent from the standing).  The proof is the passport (mutation-tested:
# disable the gate -> a false finding wrongly crosses).  Tamper the public target -> the signature fails.
#
# Composes fresh bounty_attest + bounty_ledger (new organs) + the archive (cad + node_identity Ed25519 +
# crypt_ed25519 + capability + merkle + fed_tier + fed_seal).  No new crypto, no island, no clobber.
# Exit 0 = green + byte-deterministic; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/henosis"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"; cd "$ROOT"
[ -x "$IIIS" ] || { echo "[henosis_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[henosis_gate] no archive: $ARC"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[henosis_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[henosis_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -6 "$out.log"; return 1
}

cc_one "$ROOT/STDLIB/iii/aether/henosis.iii"       "$T/henosis.o"       || exit 2
cc_one "$ROOT/STDLIB/iii/aether/bounty_attest.iii" "$T/bounty_attest.o" || exit 2
cc_one "$ROOT/STDLIB/iii/aether/bounty_ledger.iii" "$T/bounty_ledger.o" || exit 2

rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/henosis.exe"
    gcc -o "$T/henosis.exe" "$T/henosis.o" "$T/bounty_attest.o" "$T/bounty_ledger.o" "$ARC" \
        -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/henosis.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[henosis_gate] LINK FAIL rc=$rc"; tail -6 "$T/link.log"; exit 3; }

STG="/tmp/henosis_$$_$RANDOM.exe"
cp "$T/henosis.exe" "$STG"; "$STG" > "$T/run1.txt" 2>&1; rc1=$?; rm -f "$STG"
cp "$T/henosis.exe" "$STG"; "$STG" > "$T/run2.txt" 2>&1; rc2=$?; rm -f "$STG"
[ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] || { echo "[henosis_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2"; tail -8 "$T/run1.txt"; exit 4; }
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[henosis_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 5; }
grep -q "SOVEREIGN" "$T/run1.txt" || { echo "[henosis_gate] no SOVEREIGN crossing"; tail -8 "$T/run1.txt"; exit 6; }
grep -qi "NO secret trace): YES" "$T/run1.txt" || { echo "[henosis_gate] stranger-verification not shown"; tail -8 "$T/run1.txt"; exit 6; }

echo "[henosis_gate] THE UNIFICATION IS GREEN -- proof gates a signed, anonymous, artifact-bound, sealed, portfolio-proven finding on ONE identity, byte-deterministic:"
grep -Ei "PROVEN|stranger|GREEN:" "$T/run1.txt" | head -3
exit 0
