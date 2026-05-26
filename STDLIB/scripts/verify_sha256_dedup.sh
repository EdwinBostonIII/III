#!/usr/bin/env bash
# =============================================================================
#  §4.15 -> III-APOTHEOSIS M24#1 — SHA-256 single-address invariant.
#
#  HISTORY.  The gospel's Stage 4.15 established that every C-subsystem SHA-256
#  copy was BYTE-IDENTICAL to the canonical (LEXICON/src/sha256.c) -- the
#  N-fold deduplication line.  III-APOTHEOSIS Module 1 (cad) made
#  numera/cad.iii (SHA-256 default + Keccak-256 alternate, suite-tagged) the
#  ONE content-address, KAT-proven (corpus 02/15 + 665_cad), so the 14 C copies
#  + sha256_local.c were RETIRED as a witnessed M24#1 amendment (the .iii
#  supersedes them; build-invisible -- none were compiled).
#
#  This gate now MAINTAINS that retirement: it FAILS if any non-BOOT C SHA-256
#  copy reappears, so the "one address" invariant cannot silently regress.
#  (BOOT is excluded: BOOT files embed the K-constant for closure hashing, not
#  a sha256.c copy; CRYPTO-AGILITY/src/sha2.c is the distinct FIPS SHA-2 family,
#  not a single-purpose sha256.c copy -- both are out of scope here.)
#
#  Exit 0  = no C sha256.c/sha256_local.c copy exists (cad is the one address).
#  Exit 1  = a retired copy reappeared (listed) -- M24#1 regression.
# =============================================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "============================================================"
echo " SHA-256 single-address invariant (M24#1) — cad is the one address"
echo "============================================================"

FOUND=0
while IFS= read -r f; do
    [ -z "$f" ] && continue
    FOUND=$((FOUND+1))
    echo "  REGRESSION  ${f#$ROOT/}  (a retired C sha256 copy reappeared)"
done < <(find "$ROOT" -type f \( -name "sha256.c" -o -name "sha256_local.c" \) \
            -not -path "*/BOOT/*" -not -path "*/build/*" | sort)

echo "============================================================"
echo "  reappeared copies = $FOUND"
echo "============================================================"
if [ "$FOUND" -ne 0 ]; then
    echo "[verify_sha256_dedup] FAIL: $FOUND C sha256 copy/copies reappeared -- M24#1 regression."
    echo "  cad/sha256.iii (numera) is the ONE content-address; no C copy may exist."
    exit 1
fi
echo "[verify_sha256_dedup] OK: M24#1 holds -- zero C sha256 copies; cad is the one address."
exit 0
