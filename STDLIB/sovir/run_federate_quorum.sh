#!/usr/bin/env bash
# run_federate_quorum.sh -- Phase Omega6 GATE: a COMMITTED GF(p^4) FRI proof's content-address is federated by a
# POST-QUANTUM (ML-DSA) 2f+1 BFT quorum (aether/pq_quorum) over N=3f+1 peers -- the Omega5 cross-node attestation
# generalised to Byzantine-tolerant federation.  Exit 99 iff: (H) 4 honest votes over the proof-mhash form the quorum;
# (T) ONE Byzantine peer (f=1) is tolerated (3 valid -> quorum holds); (S) TWO Byzantine peers (f=2 > the bound) are
# rejected (2 valid < 3 -> no false certificate).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"
W="$ROOT/STDLIB/build/sovir"; LIB="$ROOT/STDLIB/build/iii/libiii_native.a"; mkdir -p "$W"
fail=0; say(){ echo "[federate-quorum] $*"; }
[ -s "$LIB" ] || { say "FAIL: libiii_native.a missing"; exit 1; }
"$IIIS" "$S/zk_federate_quorum.iii" --compile-only --out "$W/zk_federate_quorum.o" >/tmp/fq.log 2>&1 || { say "FAIL compile"; cat /tmp/fq.log; fail=1; }
gcc "$W/zk_federate_quorum.o" "$LIB" -lkernel32 -o "$W/zk_federate_quorum.exe" 2>/tmp/fql.log || { say "FAIL link"; cat /tmp/fql.log; fail=1; }
if [ $fail -eq 0 ]; then
  timeout 90 "$W/zk_federate_quorum.exe" >/dev/null 2>&1; rc=$?
  if [ $rc -eq 99 ]; then
    say "FEDERATION QUORUM : a COMMITTED GF(p^4) FRI proof's content-address (keccak of the committed roots + final codeword -- the same object Omega5 ships + a peer verifies) is certified by a POST-QUANTUM ML-DSA 2f+1 BFT QUORUM (N=3f+1=4 peers, quorum=3). All 4 honest votes -> quorum forms; ONE Byzantine peer (f=1, vote tampered) -> 3 valid remain -> quorum STILL forms (Byzantine-tolerant); TWO Byzantine peers (f=2 > the tolerated bound) -> only 2 valid < 3 -> NO quorum (SAFETY: no false certificate past the fault bound). Omega5's cross-node verify-and-fold generalised to a quantum-adversary-surviving federation (Omega6)."
  else say "FAIL federate-quorum: rc=$rc (1-3=bft-shape 4/5=honest-quorum 6/7=f=1-tolerance 8/9=f=2-safety)"; fail=1; fi
fi
exit $fail
