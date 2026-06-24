#!/usr/bin/env bash
# run_here_to_there.sh -- Phase Omega5 GATE: a COMMITTED GF(p^4) FRI proof is serialised, shipped over the real
# sealed_channel (x25519 ECDH + ChaCha20-Poly1305), and VERIFIED-AND-FOLDED by a second node that holds ONLY the
# artifact -- never the witness, never re-executing the prover (proven by ZEROING the prover arrays before verify).
# Exit 99 iff: (H) honest ship+verify+fold succeeds with the prover state zeroed; (C) a tampered ciphertext is rejected
# by the channel auth tag; (A) a tampered artifact leaf is rejected by the node-2 Merkle check.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"
W="$ROOT/STDLIB/build/sovir"; LIB="$ROOT/STDLIB/build/iii/libiii_native.a"; mkdir -p "$W"
fail=0; say(){ echo "[here-to-there] $*"; }
[ -s "$LIB" ] || { say "FAIL: libiii_native.a missing"; exit 1; }
"$IIIS" "$S/zk_here_to_there.iii" --compile-only --out "$W/zk_here_to_there.o" >/tmp/h2t.log 2>&1 || { say "FAIL compile"; cat /tmp/h2t.log; fail=1; }
gcc "$W/zk_here_to_there.o" "$LIB" -lkernel32 -o "$W/zk_here_to_there.exe" 2>/tmp/h2tl.log || { say "FAIL link"; cat /tmp/h2tl.log; fail=1; }
if [ $fail -eq 0 ]; then
  timeout 60 "$W/zk_here_to_there.exe" >/dev/null 2>&1; rc=$?
  if [ $rc -eq 99 ]; then
    say "HERE->THERE : a COMMITTED GF(p^4) FRI proof (roots + per-query openings + Merkle paths -- NOT the codeword/witness) is serialised, SHIPPED over the real sealed_channel (x25519 ECDH-derived key + ChaCha20-Poly1305 AEAD), and on the PEER node decrypted + Poly1305-authenticated, then VERIFIED reading ONLY the artifact -- the prover's codeword + roots are ZEROED first, so verification (recompute the fold challenges from the shipped roots, Merkle-verify every opened leaf against its root, check the GF(p^4) fold-consistency + final-constant) provably uses NO witness and does NOT re-execute the prover -- and the artifact's content-address is FOLDED into the peer's attestation state. A TAMPERED CIPHERTEXT is rejected by the auth tag; a TAMPERED ARTIFACT LEAF is rejected by the Merkle check. The proof travels, the witness does not: cross-node verify-and-fold without re-exec (Omega5)."
  else say "FAIL here-to-there: rc=$rc (1=send 2=recv-honest 3=verify-honest 4=no-fold 5=tampered-cipher-accepted 6=recv-armA 7=tampered-artifact-accepted)"; fail=1; fi
fi
exit $fail
