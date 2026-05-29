#!/usr/bin/env bash
# verify_nous_propose_only.sh -- D-18, the conservative SYNTACTIC approximation of the
# propose-only invariant.  Bash cannot do taint-tracking, so a clean exit means the
# structural preconditions hold, NOT that propose-only is proven -- the PROOF is the
# build-time differential gate verify_nous_differential.sh (C-14).  Two invariants:
#
#  (1) Trust-root isolation: no nous symbol appears in the kernel (TYPES/src, the C
#      trust root) or the bootstrap compiler (COMPILER/BOOT).  nous is strictly ABOVE
#      the trust root; there is no kernel->nous edge.
#  (2) Propose-only chokepoint: nous_rank (the proposer's ONLY engine entry point) is
#      called only from the allowlisted socket omnia/xii_rewrite.iii, where every
#      proposed rule-id is checked by apply_specific's match before it can fire.  Each
#      allowlist entry is an inline-justified unchecked assertion.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STDLIB="$ROOT/STDLIB"
RC=0

echo "== (1) trust-root isolation: no nous in TYPES/src (kernel) or COMPILER/BOOT =="
ISO_HITS=""
for d in "$ROOT/TYPES/src" "$ROOT/COMPILER/BOOT"; do
    [ -d "$d" ] || continue
    # Word-boundary match: a real nous symbol is `nous_*` or the bare word `nous`.
    # The old `-e 'nous '` matched the substring inside words like "synchronous"/"erroneous"
    # (a false positive in cg_sha.iii's "synchronous leaf" comment); `\bnous\b` does not.
    h="$(grep -rIlE -e 'nous_' -e '\bnous\b' "$d" 2>/dev/null || true)"
    [ -n "$h" ] && ISO_HITS="$ISO_HITS$h
"
done
if [ -n "${ISO_HITS// /}" ]; then
    echo "  RED: a nous symbol appears in the trust root:"
    printf '%s' "$ISO_HITS" | sed 's/^/    /'
    RC=1
else
    echo "  ok: no nous symbol in TYPES/src or COMPILER/BOOT"
fi

echo "== (2) propose-only chokepoint: nous_rank called only from the allowlisted socket =="
# The proposer's single engine entry is nous_rank(...).  Its definition + selftest live
# in nous/nous_socket.iii (the owner, excluded); the ONLY legitimate caller is the
# socket guard in omnia/xii_rewrite.iii (xrw_apply_ranked), which fires each proposed
# rule-id through apply_specific (match-before-fire) -- the checker.
CALLERS="$(grep -rIl 'nous_rank(' "$STDLIB/iii" 2>/dev/null | grep -v 'nous/nous_socket.iii' || true)"
if [ -z "$CALLERS" ]; then
    echo "  note: no external nous_rank caller yet (socket may be inert/unwired in this tree)"
fi
while IFS= read -r f; do
    [ -z "$f" ] && continue
    rel="${f#"$STDLIB"/iii/}"
    case "$rel" in
        omnia/xii_rewrite.iii) echo "  ok: $rel (allowlisted socket; proposals checked via apply_specific match-before-fire)";;
        *) echo "  RED: nous_rank called from non-allowlisted site: $rel"; RC=1;;
    esac
done <<< "$CALLERS"

echo "----------------------------------------------------------------"
if [ "$RC" = 0 ]; then
    echo "NOUS PROPOSE-ONLY GATE: GREEN (structural preconditions hold)."
    echo "(The propose-only PROOF is scripts/verify_nous_differential.sh -- the keystone gate.)"
else
    echo "NOUS PROPOSE-ONLY GATE: RED -- a trust-root or chokepoint invariant is violated."
fi
exit $RC
