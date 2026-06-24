#!/usr/bin/env bash
# run_ext4_committed.sh -- P2a GATE (DOCS/III-GRAND-UNIFICATION-AUDIT-AND-PLAN.md, fixes finding F1): the COMMITTED,
# succinct, witness-free GF(p^4) FRI low-degree test -- the soundness-bearing core the extension-field "production"
# gadgets were missing (their verify() read the prover's layer arrays directly; the FS challenge hashed only the FA
# limb). This gadget Merkle-commits each FRI layer's FULL 4-limb leaves, derives the fold challenge + queries from the
# ROOTS (binding both limbs), and the verifier OPENS queried leaves + Merkle-verifies them against the committed roots
# before checking fold-consistency -- mirroring the proven base-field air_stark_verify, lifted to GF(p^4).
#
# Exit 99 from the gadget iff: (H) an honest degree-15 codeword ACCEPTS; (A) a flipped claimed leaf is REJECTED against
# its committed root (opening binds the value); (B) a corrupted committed root makes the full verify REJECT (root binds
# the proof); (C) a non-low-degree (degree-63) codeword is REJECTED. Adversary-verified, not self-graded.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"
W="$ROOT/STDLIB/build/sovir"; LIB="$ROOT/STDLIB/build/iii/libiii_native.a"; mkdir -p "$W"
fail=0; say(){ echo "[ext4-committed] $*"; }
[ -s "$LIB" ] || { say "FAIL: libiii_native.a missing"; exit 1; }
"$IIIS" "$S/zk_ext4_committed.iii" --compile-only --out "$W/zk_ext4_committed.o" >/tmp/e4c.log 2>&1 || { say "FAIL compile"; cat /tmp/e4c.log; fail=1; }
gcc "$W/zk_ext4_committed.o" "$LIB" -lkernel32 -o "$W/zk_ext4_committed.exe" 2>/tmp/e4cl.log || { say "FAIL link"; cat /tmp/e4cl.log; fail=1; }
if [ $fail -eq 0 ]; then
  timeout 60 "$W/zk_ext4_committed.exe" >/dev/null 2>&1; rc=$?
  if [ $rc -eq 99 ]; then
    say "GF(p^4) FRI COMMITTED + SUCCINCT : each layer's full 4-limb GF(p^4) elements MERKLE-COMMITTED (SHA-256, 16B leaves); fold challenge = keccak(root_L), queries = keccak(final root) -> bound to BOTH limbs (fixes the FA-only defect); the verifier OPENS queried leaves + merkle_verify_proof against the committed roots before fold-consistency (witness-free, O(log n)). Honest degree-15 ACCEPTS; flipped-leaf REJECTED (opening binds value); corrupted-root REJECTED (root binds proof); degree-63 REJECTED (low-degree). The soundness-bearing core F1 found missing is BUILT + adversary-verified. NEXT (P2b): migrate zk_fused_prod's verify onto this committed path (the full compute+memory+control STARK over committed GF(p^4) FRI)."
  else say "FAIL ext4-committed: rc=$rc (1=honest-rejected 2=open-accept-fail 3=tamper-not-rejected 4=root-corrupt-not-rejected 5=nonLD-accepted 6=reprove-fail)"; fail=1; fi
fi
exit $fail
