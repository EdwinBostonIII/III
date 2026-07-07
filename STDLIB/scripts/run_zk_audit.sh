#!/usr/bin/env bash
# run_zk_audit.sh -- Φ6 exit gate (III-COMPLETION-PLAN Part 3 / III-UNIFIED-ARCHITECTURE §9):
#
#   EVERY zk gadget's CLAIMED soundness bit-count must match its query/field KNOBS.
#
# The tree's own convention (measured, 2026-07-07 census of all 49 STDLIB/sovir/zk_*.iii):
#   ~2^-86 (PRODUCTION query soundness)  ⇔  128 FS-derived queries
#       expressed either as consts (NQPB=32 × NBATCH=4 re-hash batches) or as an explicit
#       "128 queries"/"128 FS" basis line, over a declared field (GF(p^4) headline; the two
#       ext2 production gadgets claim the query term only: (5/8)^128 ~ 2^-86).
#   Mechanism/unit gadgets (D=32/64 probes, 8/16/64 queries) carry NO 2^-86 self-claim.
#
# MANIFEST (the audit's ground truth -- every CLAIMER is classified; a 2^-86 line in any
# unclassified module fails LOUDLY, so a new gadget cannot silently borrow the banner):
#   prod128:<field-marker-regex>  -- claims ~2^-86; must have (NQPB*NBATCH>=128) OR a
#                                    "128 queries|128 FS" basis line; field marker must match.
#   xref                          -- every 2^-86 line must NAME another zk_* module (a
#                                    cross-reference, not a self-claim).
#   (unlisted)                    -- must contain NO 2^-86 line at all.
#
# FALSIFIERS (teeth, both directions):
#   - downscale a production gadget's NBATCH (4 -> 2)     -> its prod128 row REDDENS (knob < claim)
#   - add a 2^-86 line to any unlisted/unit module        -> "unclassified claim" REDDENS
#   ZK_AUDIT_DIR=<dir> overrides the scan root so the teeth are provable on a perturbed copy.
#
# No Python (L4). Read-only. Exit 0 = every claim matches its knobs; 1 = violation(s).
set -u
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
ZKDIR="${ZK_AUDIT_DIR:-$ROOT/STDLIB/sovir}"

CLAIM_RE='2\^-86|2⁻⁸⁶'

# module -> class[:field-regex]
manifest() {
    case "$1" in
        zk_fused_committed)       echo "prod128:GF\\(p\\^4\\)" ;;
        zk_fused_forge63)         echo "prod128:GF\\(p\\^4\\)" ;;
        zk_here_to_there)         echo "prod128:GF\\(p\\^4\\)" ;;
        zk_fused_prod)            echo "prod128:GF\\(p\\^4\\)" ;;
        zk_ext4_prod)             echo "prod128:GF\\(p\\^4\\)" ;;
        zk_perm_k3prod)           echo "prod128:GF\\(p\\^4\\)" ;;
        zk_ext2_fri256)           echo "prod128:\(5/8\)\^128" ;;   # ext2: query term only, its own math line
        zk_ext2_prod)             echo "prod128:zk_ext2_fri256" ;; # ext2 at fri256 scale (D=256, 128 queries)
        zk_ext4_stark_committed)  echo "xref" ;;                   # 2^-86 mentions NAME zk_fused_committed
        *)                        echo "" ;;
    esac
}

fail=0; scanned=0; claimers=0
for f in "$ZKDIR"/zk_*.iii; do
    [ -f "$f" ] || continue
    scanned=$((scanned+1))
    name="$(basename "$f" .iii)"
    nclaim=$(grep -cE "$CLAIM_RE" "$f")
    cls="$(manifest "$name")"
    if [ "$nclaim" -eq 0 ]; then
        # no soundness claim: nothing to audit (a prod-classified module with NO claim is stale -> flag it)
        if [ -n "$cls" ] && [ "${cls%%:*}" = "prod128" ]; then
            echo "VIOLATION $name: manifest says prod128 but the file carries no ~2^-86 claim (stale manifest row)"
            fail=$((fail+1))
        fi
        continue
    fi
    claimers=$((claimers+1))
    case "${cls%%:*}" in
        prod128)
            fieldre="${cls#*:}"
            nqpb=$(sed -n 's/^const NQPB.*= *\([0-9]*\)u64.*/\1/p' "$f" | head -1)
            nbatch=$(sed -n 's/^const NBATCH.*= *\([0-9]*\)u64.*/\1/p' "$f" | head -1)
            basis=0
            if [ -n "$nqpb" ] && [ -n "$nbatch" ]; then
                [ $((nqpb * nbatch)) -ge 128 ] && basis=1 \
                    || { echo "VIOLATION $name: claims ~2^-86 but NQPB*NBATCH = $nqpb*$nbatch = $((nqpb*nbatch)) < 128"; fail=$((fail+1)); continue; }
            fi
            [ "$basis" -eq 0 ] && grep -qE "128 (FS.)?queries|128 FS" "$f" && basis=1
            if [ "$basis" -eq 0 ]; then
                echo "VIOLATION $name: claims ~2^-86 with NO 128-query basis (no NQPB*NBATCH>=128 consts, no '128 queries' line)"
                fail=$((fail+1)); continue
            fi
            if ! grep -qE "$fieldre" "$f"; then
                echo "VIOLATION $name: claims ~2^-86 but its declared field/basis marker '$fieldre' is absent"
                fail=$((fail+1)); continue
            fi
            echo "OK   $name (prod128: basis present, field marker present)"
            ;;
        xref)
            bad=$(grep -E "$CLAIM_RE" "$f" | grep -cvE "zk_[a-z0-9_]+")
            if [ "$bad" -gt 0 ]; then
                echo "VIOLATION $name: xref-classified, but $bad ~2^-86 line(s) do not name another zk_* module (reads as a self-claim)"
                fail=$((fail+1)); continue
            fi
            echo "OK   $name (xref: every ~2^-86 line names its subject module)"
            ;;
        *)
            echo "VIOLATION $name: carries a ~2^-86 claim but is NOT in the audit manifest (classify it: prod128/xref, or remove the claim)"
            fail=$((fail+1))
            ;;
    esac
done

echo "-------------------------------------------------------------"
echo "zk modules scanned: $scanned ; soundness claimers audited: $claimers ; violations: $fail"
if [ "$fail" -eq 0 ]; then
    echo "ZK AUDIT: PASS (every claimed bit-count matches its NQ/field knobs)"
    exit 0
else
    echo "ZK AUDIT: FAIL"
    exit 1
fi
