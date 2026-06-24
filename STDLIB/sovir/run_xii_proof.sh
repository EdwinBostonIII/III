#!/usr/bin/env bash
# run_xii_proof.sh -- Phase Omega3 GATE: PROOF-CARRYING XII canonicalisation with an INDEPENDENT re-checker.
#
# XII canonicalises its term algebra by firing the SEALED reduction rules (xii_rewrite) to fixpoint.  Omega3 makes
# that derivation a FIRST-CLASS, CHECKABLE OBJECT:
#   - omnia/xii_proof.iii      emits the proof: a linear sequence of single-rule steps (rule_id, preorder position,
#                              before_hash, after_hash), mhash-CHAINED; before/after are arena-independent CONTENT
#                              hashes (cad/SHA-256 over a kind|subform|aux preorder serialisation).
#   - omnia/xii_proof_check.iii is the INDEPENDENT verifier: it re-derives canon WITHOUT the canonicaliser -- for each
#                              step it binds the rule_id to the manifest-admitted SEALED set, checks the before-hash,
#                              RE-APPLIES exactly that one sealed rule at the stated position (xii_rewrite_apply_specific),
#                              checks the after-hash, extends the chain, and finally confirms the term is canonical.
#
# R0-as-XII-term (sovir/xii_proof_demo.iii): a conditional iterated event-fold with identity/no-op edges
#   F.COMPOSE(F.IF(p, F.WITH(NULL, F.LOOP(F.LOOP(K12,2),3)), e), NULL)  -- the eidos::ripple temporal fold (iterated
#   composition of the event-fold step, gated, wrapped with the flat/no-op identity edges).  Canonicalisation drops
#   the identities (R017/R016) and folds the nested iteration to one loop of the combined count (R014: 2*3=6).
#
# Acceptance (exit 99 from the demo iff ALL hold):
#   M   the rule set is MANIFEST-ADMITTED (xad_admit: root-confluent + terminating)
#   P1  the emitter's canon == the production xii_canonicalise's canon (SAME normal form, same content hash)
#   P2  the INDEPENDENT checker ACCEPTS the honest proof (rc 0)
#   A   an OUT-OF-MANIFEST rule_id is REJECTED (checker rc 1)               [Omega3-T3 negative]
#   B   a TAMPERED after_hash is REJECTED (checker rc 4)                    [hash-chain negative]
#   C   a WRONG position is REJECTED (checker rc 3)                         [position negative]
#   D   a SEALED-but-non-matching rule at a position is REJECTED (rc 3)     [semantics-breaking negative]
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; O="$ROOT/STDLIB/iii/omnia"
W="$ROOT/STDLIB/build/sovir"; LIB="$ROOT/STDLIB/build/iii/libiii_native.a"; mkdir -p "$W"
fail=0; say(){ echo "[xii-proof] $*"; }

[ -s "$LIB" ] || { say "FAIL: libiii_native.a missing (build the stdlib first)"; exit 1; }

"$IIIS" "$O/xii_proof.iii"        --compile-only --out "$W/xii_proof.o"        >/tmp/xp1.log 2>&1 || { say "FAIL compile xii_proof";       cat /tmp/xp1.log; fail=1; }
"$IIIS" "$O/xii_proof_check.iii"  --compile-only --out "$W/xii_proof_check.o"  >/tmp/xp2.log 2>&1 || { say "FAIL compile xii_proof_check"; cat /tmp/xp2.log; fail=1; }
"$IIIS" "$S/xii_proof_demo.iii"   --compile-only --out "$W/xii_proof_demo.o"   >/tmp/xp3.log 2>&1 || { say "FAIL compile xii_proof_demo";  cat /tmp/xp3.log; fail=1; }
gcc "$W/xii_proof_demo.o" "$W/xii_proof.o" "$W/xii_proof_check.o" "$LIB" -lkernel32 -o "$W/xii_proof_demo.exe" 2>/tmp/xpl.log || { say "FAIL link"; cat /tmp/xpl.log; fail=1; }

if [ $fail -eq 0 ]; then
  timeout 60 "$W/xii_proof_demo.exe" >/dev/null 2>&1; rc=$?
  if [ $rc -eq 99 ]; then
    say "XII PROOF-CARRYING : canon(R0) of the eidos-ripple XII term is emitted as a first-class CHECKABLE proof (sealed-rule steps, mhash-chained, content-hashed) and the INDEPENDENT verifier (xii_proof_check, never calling the canonicaliser) RE-DERIVES canon from the sealed manifest set and ACCEPTS; the emitter's canon == the production xii_canonicalise's canon (same normal form). ADVERSARY ARMS all REJECT: out-of-manifest rule (rc1), tampered after-hash (rc4), wrong position (rc3), sealed-but-non-matching rule (rc3). Rule set MANIFEST-ADMITTED (root-confluent + terminating). Omega3 CLOSED."
  else
    say "FAIL xii-proof: demo rc=$rc (99=pass; 9=not-admitted; 1=emitter!=canonicalise; 2=empty-proof; 30+k=honest-checker-rejected code k; 4/5/6/7=neg arm A/B/C/D returned the wrong code)"; fail=1
  fi
fi
exit $fail
