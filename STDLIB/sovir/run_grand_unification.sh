#!/usr/bin/env bash
# run_grand_unification.sh -- Phase Omega4: the SINGLE-NODE GRAND UNIFICATION gate.  ONE real EIDOS ripple computation
# proven across the audited+perfected organs, the views BOUND by a shared content-address (the fold value 675673294).
#
# This composes the now-honest, now-committed pipeline (DOCS/III-GRAND-UNIFICATION-AUDIT-AND-PLAN.md):
#   Omega.a/d  EIDOS->SVIR (FR-1): the ripple kernel R0 -> iiisv -> SVIR -> svir_verify -> x86(sovereign)+wasm == 99,
#              and the SVIR fold == the LIVE eidos::ripple organ's fold (real rf_rank + isub).   [run_eidos_svir.sh]
#   Omega.b    XII proof-carrying canonicalisation (FR-2): an XII canonicalisation emitted as a first-class, mhash-
#              chained, INDEPENDENTLY re-checkable proof bound to the sealed manifest rule set.   [run_xii_proof.sh]
#   F2 BIND    the SAME ripple event stream lifted to an XII term (flats = THEN-identities provably dropped) whose
#              canonical form FOLDS TO THE SAME VALUE R0 executes (675673294) -- one computation, two proven views,
#              agreeing on the answer.                                                            [zk_gu_ripple_xii]
#   Omega.e    the COMMITTED, witness-free GF(p^4) zkVM (F1 closed): committed FRI + committed line-755 STARK + the
#              full compute+memory+control fused zkVM, all verified against Merkle commitments.   [run_ext4_committed.sh]
#
# Each constituent carries its OWN rejecting negative arm (forged SVIR -> verifier; tampered XII step -> re-checker;
# violating trace / forged opening / corrupted root -> committed verify).  This gate asserts the CONJUNCTION + the
# cross-view binding.  HONEST SCOPE: XII does not lower to SVIR (no such lowering exists), so the organs are bound by
# the shared COMPUTATION (the ripple event stream -> the same fold), not by a single object transformed through both;
# that shared-fold binding is the faithful unification at this layer.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"
W="$ROOT/STDLIB/build/sovir"; LIB="$ROOT/STDLIB/build/iii/libiii_native.a"; mkdir -p "$W"
fail=0; say(){ echo "[grand-unification] $*"; }
GOLD=675673294

# ---- Omega.a/d : EIDOS ripple -> SVIR -> both back-ends, live-organ match ----
bash "$S/run_eidos_svir.sh" > /tmp/gu_a.log 2>&1; arc=$?
ga=$(grep -oE "$GOLD" /tmp/gu_a.log | head -1)
[ $arc -eq 0 ] && say "Omega.a/d  EIDOS->SVIR  : PASS (R0 -> SVIR -> x86 sovereign + wasm == 99 ; SVIR fold == live organ == $ga)" || { say "FAIL Omega.a/d (run_eidos_svir rc=$arc)"; fail=1; }

# ---- Omega.b : XII proof-carrying canonicalisation (mechanism) ----
bash "$S/run_xii_proof.sh" > /tmp/gu_b.log 2>&1; brc=$?
[ $brc -eq 0 ] && say "Omega.b    XII proof    : PASS (canon emitted as a checkable mhash-chained proof; independently re-checked; adversary arms reject)" || { say "FAIL Omega.b (run_xii_proof rc=$brc)"; fail=1; }

# ---- F2 BIND : the ripple event stream proven in the XII view, folding to the SAME value R0 executes ----
"$IIIS" "$ROOT/STDLIB/iii/omnia/xii_proof.iii"       --compile-only --out "$W/xii_proof.o"       >/dev/null 2>&1
"$IIIS" "$ROOT/STDLIB/iii/omnia/xii_proof_check.iii" --compile-only --out "$W/xii_proof_check.o" >/dev/null 2>&1
"$IIIS" "$S/zk_gu_ripple_xii.iii" --compile-only --out "$W/zk_gu_ripple_xii.o" >/dev/null 2>&1 || { say "FAIL compile zk_gu_ripple_xii"; fail=1; }
gcc "$W/zk_gu_ripple_xii.o" "$W/xii_proof.o" "$W/xii_proof_check.o" "$LIB" -lkernel32 -o "$W/zk_gu_ripple_xii.exe" 2>/dev/null || { say "FAIL link zk_gu_ripple_xii"; fail=1; }
timeout 60 "$W/zk_gu_ripple_xii.exe" >/dev/null 2>&1; f2rc=$?
[ $f2rc -eq 99 ] && say "F2 BIND    one-object   : PASS (the SAME ripple events as an XII term -> flats provably dropped (proof re-checked) -> canonical fold == $GOLD == R0's SVIR fold ; tampered step rejected)" || { say "FAIL F2 bind (zk_gu_ripple_xii rc=$f2rc)"; fail=1; }

# ---- Omega.e : the committed GF(p^4) zkVM (F1 closed) ----
bash "$S/run_ext4_committed.sh" > /tmp/gu_e.log 2>&1; erc=$?
[ $erc -eq 0 ] && say "Omega.e    committed zk : PASS (committed GF(p^4) FRI + committed witness-free STARK + the FULL fused compute+memory+control zkVM, all against Merkle commitments)" || { say "FAIL Omega.e (run_ext4_committed rc=$erc)"; fail=1; }

# ---- Omega.f : here->there -- ship a committed proof over the sealed channel; a second node verify-and-folds without re-exec ----
bash "$S/run_here_to_there.sh" > /tmp/gu_f.log 2>&1; frc2=$?
[ $frc2 -eq 0 ] && say "Omega.f    here->there  : PASS (committed proof serialised -> sealed_channel x25519+ChaCha20-Poly1305 -> peer verify-and-fold reading ONLY the artifact, prover state zeroed = no re-exec; tampered ciphertext + tampered artifact both rejected)" || { say "FAIL Omega.f (run_here_to_there rc=$frc2)"; fail=1; }

# ---- Omega.g : federation -- a post-quantum 2f+1 BFT quorum certifies the shipped committed-proof attestation ----
bash "$S/run_federate_quorum.sh" > /tmp/gu_g.log 2>&1; grc=$?
[ $grc -eq 0 ] && say "Omega.g    federation   : PASS (post-quantum ML-DSA 2f+1 BFT quorum over the committed-proof content-address: honest quorum forms, 1 Byzantine tolerated, 2 Byzantine rejected = safety)" || { say "FAIL Omega.g (run_federate_quorum rc=$grc)"; fail=1; }

# ---- Omega.cert : the end-to-end trust-closure provenance certificate (Omega7) ----
bash "$S/run_trust_certificate.sh" > /tmp/gu_cert.log 2>&1; crc=$?
[ $crc -eq 0 ] && say "Omega7     trust cert   : PASS ($(grep -oE 'CERT = SHA-256[^.]*= [0-9a-f]+' /tmp/gu_cert.log | head -1) ; binds toolchain lib mhash + frontend-DDC + committed-proof mhash + fold; reproducible + tamper-sensitive)" || { say "FAIL Omega7 (run_trust_certificate rc=$crc)"; fail=1; }

# ---- the cross-view binding ----
bindok=0; [ "$ga" = "$GOLD" ] && [ $f2rc -eq 99 ] && bindok=1

if [ $fail -eq 0 ] && [ $bindok -eq 1 ]; then
  say "GRAND UNIFICATION (single node + here->there + federation) : the EIDOS ripple flows through the proven pipeline as ONE computation -- EIDOS->SVIR->run (Omega.a/d) + XII canonicalisation proof-carried (Omega.b) + committed GF(p^4) zkVM (Omega.e) -- its two proven views (SVIR EXECUTION and XII INTENT) BOUND by folding the ripple's event stream to the SAME $GOLD; a committed proof SHIPS over the sealed channel to a second node that VERIFIES-AND-FOLDS it without the witness or re-exec (Omega.f); and that attestation is certified by a post-quantum 2f+1 BFT QUORUM, Byzantine-tolerant (Omega.g).  Every organ is sound + committed + adversary-gated; F1 (committed production zkVM) closed, F2 (one-computation composition) realised, Omega5 (here->there) + Omega6 (federation) realised; and the whole result is bound to the trust-closed toolchain by an end-to-end PROVENANCE CERTIFICATE = SHA-256(lib mhash || committed-proof mhash || fold || frontend-DDC), reproducible + tamper-sensitive (Omega7).  HONEST: XII does not lower to SVIR, so the cross-view binding is the shared COMPUTATION (one fold), not one object through both stages; ~2^-86 is the NQ query-count knob; the seed-LINEAGE DDC axis is the documented residual (SVIR-DDC-RESIDUAL.md).  REMAINING: Omega0 binary-level DDC (the ccsv worker) closes the last trust-floor residual."
else
  say "FAIL grand-unification: a/d=$arc b=$brc f2=$f2rc e=$erc bind=$bindok(ga=$ga gold=$GOLD)"; fail=1
fi
exit $fail
