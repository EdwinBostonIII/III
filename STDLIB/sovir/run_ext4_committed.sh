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
# P2b CORE: the committed witness-free GF(p^4) STARK on a REAL constraint (next=cur^2).
"$IIIS" "$S/zk_ext4_stark_committed.iii" --compile-only --out "$W/zk_ext4_stark_committed.o" >/tmp/e4s.log 2>&1 || { say "FAIL compile stark"; cat /tmp/e4s.log; fail=1; }
gcc "$W/zk_ext4_stark_committed.o" "$LIB" -lkernel32 -o "$W/zk_ext4_stark_committed.exe" 2>/tmp/e4sl.log || { say "FAIL link stark"; cat /tmp/e4sl.log; fail=1; }
if [ $fail -eq 0 ]; then
  timeout 60 "$W/zk_ext4_committed.exe" >/dev/null 2>&1; rc=$?
  timeout 90 "$W/zk_ext4_stark_committed.exe" >/dev/null 2>&1; src=$?
  if [ $rc -eq 99 ] && [ $src -eq 99 ]; then
    say "GF(p^4) FRI COMMITTED + SUCCINCT (P2a): each layer's full 4-limb GF(p^4) elements MERKLE-COMMITTED (SHA-256, 16B leaves); fold challenge = keccak(root_L), queries = keccak(final root) -> bound to BOTH limbs (fixes the FA-only defect); verifier OPENS queried leaves + merkle_verify_proof against the committed roots (witness-free, O(log n)). Honest degree-15 ACCEPTS; flipped-leaf REJECTED (opening binds value); corrupted-root REJECTED (root binds proof); degree-63 REJECTED (low-degree)."
    say "GF(p^4) STARK COMMITTED + WITNESS-FREE (P2b core): a REAL constraint next=cur^2 (N=16, D=64) on the PROVEN zk_air LDE+CP machinery -- trace LDE MERKLE-COMMITTED, alpha FS-derived from the committed trace root, CP committed as FRI layer 0; the verifier OPENS f(q),f(q+B) from the trace commitment, RECOMPUTES combine=alpha*(f_next-f^2) ITSELF (witness-free), opens CP(q), and checks the construction-exact line-755 CP*Z_H==combine*(x-omega^{n-1}) + the GF(p^4) FRI fold-consistency. Honest ACCEPTS; VIOLATING trace REJECTED (CP not low-degree); forged trace OPENING REJECTED (Merkle); corrupted root REJECTED. The committed line-755 zk_fused_prod did over shared memory is now done against commitments. NEXT: scale to the full 20-constraint+k=4-perm fused AIR (zk_fused_prod) over this committed path."
  else say "FAIL ext4-committed: fri=$rc stark=$src"; fail=1; fi
fi
exit $fail
