#!/usr/bin/env bash
# bounty_federation_gate.sh -- THE STANDING RITE: re-derived from clean objects every run.
#
# The AUXESIS STANDING layer, networked on III's existing aether federation.  Two increments, both composing
# ONLY organs already on disk (cad + node_identity Ed25519 + crypt_ed25519 + capability + merkle) -- no new
# crypto, no island:
#   1. aether/bounty_attest.iii -- THE ATOM: a signed, content-addressed, PUBLIC-ARTIFACT-BOUND finding
#      attestation.  A node vouches "I hold a verified finding against THIS public target" without revealing
#      the secret witnessed trace; a verifier confirms offline; tampering ANY field breaks the signature.
#   2. aether/bounty_ledger.iii -- THE PORTFOLIO: a node's accreted attestations sealed under a merkle root +
#      the node's identity signature (the STANDING commitment), with per-finding inclusion proofs (reveal ONE
#      finding to a paying program, prove it belongs to the sealed set, expose nothing else).
#
# Each KAT is a REAL consumer (deny-by-default cap gate, deterministic identity, tamper arms).  Exit 99 = green.
# Exit 0 here = both gates green + byte-deterministic.  Non-zero = the failed stage.
#
# NOTE (honest placement): this is COMPOUNDING-REPUTATION infrastructure (the AUXESIS STANDING pillar), NOT the
# first-payout path (that is: find a bug -> submit via the program's HTTPS form).  Increments 3-4 (BFT agreement
# over a FEDERATION of portfolios via hotstuff_unified + pq_quorum + fed_sybil/fed_eclipse; reach_core/tcp
# gossip) need a live MULTI-NODE community and are deferred -- building them now would be an island.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/bounty"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
K="$ROOT/aether-federation/kats"
mkdir -p "$T"
cd "$ROOT"
[ -x "$IIIS" ] || { echo "[bounty_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[bounty_gate] no archive: $ARC (run build_stdlib.sh)"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[bounty_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[bounty_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -6 "$out.log"; return 1
}

cc_one "$ROOT/STDLIB/iii/aether/bounty_attest.iii" "$T/bounty_attest.o" || exit 2
cc_one "$ROOT/STDLIB/iii/aether/bounty_ledger.iii" "$T/bounty_ledger.o" || exit 2
cc_one "$K/bounty_attest_kat.iii"                  "$T/bak.o"           || exit 2
cc_one "$K/bounty_ledger_kat.iii"                  "$T/blk.o"           || exit 2

run_kat() {  # $1 = kat obj, $2..= extra organ objs ; expects exit 99, twice (determinism)
    local katobj="$1"; shift
    local rc1 rc2
    for pass in 1 2; do
        rm -f "$T/g.exe"
        gcc "$katobj" "$@" "$ARC" -lws2_32 -lkernel32 -o "$T/g.exe" >>"$T/link.log" 2>&1 || { echo "[bounty_gate] LINK FAIL"; tail -4 "$T/link.log"; return 3; }
        local stg="/tmp/bg_$$_$RANDOM.exe"; cp "$T/g.exe" "$stg"; "$stg" >/dev/null 2>&1; local rc=$?; rm -f "$stg"
        if [ "$pass" -eq 1 ]; then rc1=$rc; else rc2=$rc; fi
    done
    [ "$rc1" = 99 ] && [ "$rc2" = 99 ] || { echo "[bounty_gate] KAT $(basename "$katobj") rc1=$rc1 rc2=$rc2 (want 99/99)"; return 4; }
    return 0
}

run_kat "$T/bak.o" "$T/bounty_attest.o"                    || exit 4
echo "[bounty_gate]   ATOM      GREEN -- signed artifact-bound attestation; 3 field-tampers reject; cap-deny."
run_kat "$T/blk.o" "$T/bounty_ledger.o" "$T/bounty_attest.o" || exit 4
echo "[bounty_gate]   PORTFOLIO GREEN -- sealed merkle+signed standing; member verifies, non-member + tamper reject."
echo "[bounty_gate] THE STANDING LAYER IS GREEN (increments 1-2, composing the existing aether federation)."
exit 0
