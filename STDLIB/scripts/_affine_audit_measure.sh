#!/usr/bin/env bash
# Measure --affine-audit coverage over III's own source with the LOCAL (non-installed)
# iiis-2.  Sums PROVEN/ABSTAIN/REFUTED across every .iii that sema's standalone, and
# lists every file that produced a REFUTED (a candidate real OOB to hand-verify).
set -u
IIIS="${1:-/tmp/iiis-2-local.exe}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TP=0; TA=0; TR=0; NFILES=0; NSKIP=0
REFUTED_FILES=""
REFUTED_DETAIL=""
while IFS= read -r f; do
    out="$("$IIIS" "$f" --affine-audit --out /tmp/aa_scratch.o 2>&1)"
    line="$(printf '%s\n' "$out" | grep -oE 'AA P=[0-9]+ A=[0-9]+ R=[0-9]+' | tail -1)"
    if [[ -z "$line" ]]; then NSKIP=$((NSKIP+1)); continue; fi
    NFILES=$((NFILES+1))
    p="$(printf '%s' "$line" | sed -E 's/AA P=([0-9]+).*/\1/')"
    a="$(printf '%s' "$line" | sed -E 's/.*A=([0-9]+) R.*/\1/')"
    r="$(printf '%s' "$line" | sed -E 's/.*R=([0-9]+)/\1/')"
    TP=$((TP+p)); TA=$((TA+a)); TR=$((TR+r))
    if [[ "$r" -gt 0 ]]; then
        REFUTED_FILES="$REFUTED_FILES ${f#$ROOT/}($r)"
        REFUTED_DETAIL="$REFUTED_DETAIL
--- ${f#$ROOT/} ---
$(printf '%s\n' "$out" | grep -E 'AA REFUTED')"
    fi
done < <(find "$ROOT/STDLIB/iii" "$ROOT/COMPILER/BOOT" -name '*.iii' | sort)
echo "============================================================"
echo "  [affine-audit] files audited=$NFILES  skipped(no-sema)=$NSKIP"
echo "  [affine-audit] TOTAL  PROVEN=$TP  ABSTAIN=$TA  REFUTED=$TR"
echo "  [affine-audit] REFUTED files:$REFUTED_FILES"
echo "$REFUTED_DETAIL"
echo "============================================================"
