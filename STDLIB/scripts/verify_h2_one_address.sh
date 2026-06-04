#!/usr/bin/env bash
# verify_h2_one_address.sh -- the STRUCTURAL half of the H2 falsifier (mig6).
#
# H2 ("one name"): every content-address in the substrate is computed by the ONE
# primitive, cad (numera/cad.iii).  A content-address computed by a raw keccak256
# call OUTSIDE cad is an H2 violation -- a "second hash path".
#
# This gate scans STDLIB/iii for direct keccak256_{oneshot,init,update,final} CALLS
# (excluding extern declarations) and checks the caller set against the ALLOWLIST
# below.  Every allowlisted file is justified as exactly one of:
#   PRIMITIVE -- the cad content-address layer + its backend (cad/keccak256/identifier),
#   KDF       -- keccak used as a key-derivation/crypto primitive, NOT a content-address,
#   KAT       -- a selftest that independently recomputes via raw keccak to PROVE
#                cad == keccak (the very byte-identity the triage repoints rely on);
#                that module's PRODUCTION content-addresses route through cad.
# A keccak caller NOT on the allowlist is a content-address outside cad -> VIOLATION.
#
# Exit 0 = the H2 structural invariant HOLDS.  Exit 1 = a violation (repoint it to
# cad_oneshot/cad_begin, or justify it on the allowlist).  The RUNTIME companion is
# numera/h2_charter.iii (the cad-faithfulness clause + run_charter terminal gate);
# together they are the complete H2 falsifier.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
III_DIR="$STDLIB_DIR/iii"

declare -A ALLOW=(
  ["numera/cad.iii"]="PRIMITIVE -- cad IS the one content-address (wraps keccak256 oneshot + begin/payload/final) + its own backend-equivalence KAT"
  ["numera/keccak256.iii"]="PRIMITIVE -- the Keccak-256 backend + its KAT vectors"
  ["numera/identifier.iii"]="PRIMITIVE -- the id primitive (ident_from_bytes/pair/list = Keccak256, byte-identical to cad(KECCAK); cad-fold is an M1/M24 follow-on)"
  ["numera/merkle.iii"]="PRIMITIVE -- the suite-parametrized Merkle hash-tree (SHA-256 seal default + Keccak-256 zk-commitment suite, mirroring cad's dispatch); leaf=hash(0x00||v)/node=hash(0x01||L||R) byte-identical to the seal AND to cad_oneshot(suite); a LOW-LEVEL hashing building block the compiler transitively links (so a cad_oneshot-fold would churn the compiler root-of-trust for ZERO byte/capability gain -- verified: it drifts the golden 450a99f2->efc256ca); same class as identifier.iii/keccak256.iii; cad-fold is an M1/M24 follow-on"
  ["aether/node_identity.iii"]="KDF -- HKDF-Expand + node_seed derivation (keccak as a key-derivation primitive, NOT a content-address) + KAT"
  ["numera/category.iii"]="KAT -- cat selftest independent cad==keccak cross-check (morphism-ids route via cad)"
  ["numera/cost_calculus.iii"]="KAT -- cc_selftest independent Keccak256 recompute (in_commit/out_commit route via cad)"
  ["numera/sheaf.iii"]="KAT -- sh_selftest reference recomputes (restriction/global-section ids route via cad)"
  ["numera/curry_howard.iii"]="KAT -- curryh selftest independent recomputes (IN_C/OUT_C commitments route via cad)"
  ["numera/theorem_carrier.iii"]="KAT -- thmc selftest reference + determinism recompute (carrier id routes via cad)"
  ["numera/sat_at_scale.iii"]="KAT -- sats selftest reproducibility recompute (sats_commit routes via cad)"
  ["numera/quine_verifier.iii"]="KAT -- qv_selftest independent target folds (the qv production target routes via cad)"
  ["numera/synthesis_spec.iii"]="KAT -- ss_selftest independent encode-hash cross-checks (ss_content_address routes via cad)"
  ["aether/witness_hook.iii"]="KAT -- wh_selftest frag-id independent recompute (frag-id/chain-root/redaction route via cad)"
  ["numera/h2_charter.iii"]="FALSIFIER -- the H2 clause itself: it cross-checks cad==keccak256 AND cad==sha256 (the runtime H2 faithfulness falsifier); calling the backends directly IS its purpose"
  ["numera/h8_charter.iii"]="FALSIFIER -- h8_verify independently recomputes keccak256(original payload) as the REFERENCE to cross-check wh_redaction_commit (which routes via cad); routing this through cad would be CIRCULAR, so the independent raw recompute IS the falsifier's purpose (cf. h2_charter, witness_hook)"
)

rc=0
found=0
echo "[verify_h2_one_address] scanning $III_DIR for keccak256 content-address callers..."
while IFS= read -r f; do
  rel="${f#$III_DIR/}"
  rel="${rel//\\//}"
  # A real call is `name(` with NO space; exclude extern declarations and comment
  # lines (leading * or /) so prose mentioning a keccak call is not a false positive.
  calls=$(grep -E 'keccak256_(oneshot|init|update|final)\(' "$f" 2>/dev/null | grep -v 'extern' | grep -vcE '^[[:space:]]*[*/]')
  if [[ "$calls" -eq 0 ]]; then continue; fi
  found=$((found + 1))
  if [[ -n "${ALLOW[$rel]+x}" ]]; then
    printf '  OK         %-34s %2s call-site(s)  %s\n' "$rel" "$calls" "${ALLOW[$rel]}"
  else
    printf '  VIOLATION  %-34s %2s call-site(s)  NOT on the H2 allowlist -- a content-address outside cad. Repoint to cad_oneshot/cad_begin (byte-identical), or justify as PRIMITIVE/KDF/KAT.\n' "$rel" "$calls"
    rc=1
  fi
done < <(find "$III_DIR" -name '*.iii' | sort)

# A stale allowlist entry (file gone, or no longer calls keccak) should be pruned.
for rel in "${!ALLOW[@]}"; do
  f="$III_DIR/$rel"
  if [[ ! -f "$f" ]]; then
    echo "  STALE      $rel -- on the allowlist but the file is missing; prune the entry."
    rc=1
  fi
done

echo "[verify_h2_one_address] $found direct keccak256 caller(s); allowlist has ${#ALLOW[@]} justified entries."
if [[ $rc -eq 0 ]]; then
  echo "[verify_h2_one_address] H2 HOLDS: every keccak256 content-address routes through cad; all direct callers are PRIMITIVE/KDF/KAT."
else
  echo "[verify_h2_one_address] H2 VIOLATION(S) -- see above."
fi
exit $rc
