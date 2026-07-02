#!/usr/bin/env bash
# verify_autogenesis_propose_only.sh -- the conservative SYNTACTIC approximation of the
# autogenesis propose-only invariant (the Wave E charter clause, structural arm).  Bash cannot
# do taint-tracking, so a clean exit means the structural preconditions hold, NOT that
# propose-only is proven -- the runtime PROOF is the charter canary KAT 1409 (an unauthorized
# commit is refused) plus the reversibility KAT 1407.  Two invariants:
#
#  (1) Trust-root isolation: no autogenesis symbol appears in the kernel (TYPES/src, the C
#      trust root) or the bootstrap compiler (COMPILER/BOOT).  The loop is strictly ABOVE the
#      trust root; there is no kernel->autogenesis edge, so a generative output can never reach
#      a trusted socket -- it can only reach a checked one.
#  (2) Commit chokepoint: the sealed-tree mutation primitive ag_commit is referenced ONLY from
#      the autogenesis corpus (its KATs), never from a production organ -- nothing in the live
#      tree drives an unattended commit; ag_commit is reachable only behind the capability gate.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STDLIB="$ROOT/STDLIB"
RC=0

# The distinctive autogenesis entry symbols + module names (specific enough to avoid matching
# unrelated `os_`/`hs_` substrings in the trust root).
SYMS='ag_cycle|ag_commit|ag_attest|sm_build|sm_next_gap|gc_propose|hs_admit|rp_certify|os_apply_in_model|tg_register|tg_persist|autogenesis|self_model|gap_conjecture|harmony_synth|refactor_propose|optimize_self|theorem_grow'

echo "== (1) trust-root isolation: no autogenesis symbol in TYPES/src (kernel) or COMPILER/BOOT =="
ISO_HITS=""
for d in "$ROOT/TYPES/src" "$ROOT/COMPILER/BOOT"; do
    [ -d "$d" ] || continue
    h="$(grep -rIlE "$SYMS" "$d" 2>/dev/null || true)"
    [ -n "$h" ] && ISO_HITS="$ISO_HITS$h
"
done
if [ -n "${ISO_HITS// /}" ]; then
    echo "  RED: an autogenesis symbol appears in the trust root:"
    printf '%s' "$ISO_HITS" | sed 's/^/    /'
    RC=1
else
    echo "  ok: no autogenesis symbol in TYPES/src or COMPILER/BOOT"
fi

echo "== (2) commit chokepoint: ag_commit referenced only from the autogenesis corpus =="
# ag_commit's definition lives in sanctus/autogenesis.iii (the owner, excluded).  The
# legitimate references are the corpus KATs (1406 commit arm, 1409 charter canary) and
# sanctus/autogenesis_cli.iii -- the OPERATOR command surface (grail b68e9b95): its `commit`
# verb dispatches ag_commit(cap, sig) under the session capability set by agc_attach, adding
# dispatch but NO new authority (the apprentice commit gate still bites; a human drives it).
# Any OTHER organ calling ag_commit would mean the tree can self-commit unattended -- RED.
CALLERS="$(grep -rIl 'ag_commit(' "$STDLIB/iii" 2>/dev/null | grep -v 'sanctus/autogenesis.iii' | grep -v 'sanctus/autogenesis_cli.iii' || true)"
if [ -n "$CALLERS" ]; then
    echo "  RED: ag_commit referenced from a production organ:"
    printf '%s\n' "$CALLERS" | sed 's/^/    /'
    RC=1
else
    echo "  ok: no production organ references ag_commit (commit is corpus/operator-only)"
fi

echo "----------------------------------------------------------------"
if [ "$RC" = 0 ]; then
    echo "AUTOGENESIS PROPOSE-ONLY GATE: GREEN (structural preconditions hold)."
    echo "(The propose-only PROOF is corpus 1409 -- the charter canary -- and 1407 -- reversibility.)"
else
    echo "AUTOGENESIS PROPOSE-ONLY GATE: RED -- a trust-root or chokepoint invariant is violated."
fi
exit $RC
