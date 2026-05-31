#!/usr/bin/env bash
# affine_audit_gate.sh -- the STANDING self-check for SW-INWARD-AUTO (design AA-7).
#
# Turns the one-off `--affine-audit` measurement into a pass/fail gate that re-verifies
# the pass every run, using the INSTALLED (resealed) iiis-2:
#   1. ground-truth fixtures hold EXACTLY (KAT P=1/A=1/R=1, soundness probe P=1/A=5/R=0)
#      -- a regression that breaks PROVEN / REFUTED / ABSTAIN correctness reddens here;
#   2. ZERO genuine REFUTED across III's real source (the only allowed REFUTED is the
#      KAT fixture's deliberate OOB) -- a NEW out-of-bounds typed-array access reddens here;
#   3. PROVEN > 0 (the pass is actually proving, not silently no-op'ing).
# Exit 0 = green; non-zero = the count of failed assertions.
#
# NOT a tight coverage cap (PROVEN may legitimately grow/shrink with the tree); the
# soundness invariants (exact fixtures + zero real REFUTED) are the load-bearing checks.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
KAT="$ROOT/COMPILER/BOOT/affine_audit_kat.iii"
SND="$ROOT/COMPILER/BOOT/affine_audit_sound.iii"
SCRATCH="/tmp/aagate_$$.o"
FAIL=0

# audit one file -> echo "P A R" (the tally), or "ERR" if it did not sema/print.
_tally() {
    local out line
    out="$("$IIIS" "$1" --affine-audit --out "$SCRATCH" 2>&1)"
    line="$(printf '%s\n' "$out" | grep -oE 'AA P=[0-9]+ A=[0-9]+ R=[0-9]+' | tail -1)"
    if [[ -z "$line" ]]; then echo "ERR"; return; fi
    printf '%s %s %s' \
        "$(printf '%s' "$line" | sed -E 's/AA P=([0-9]+).*/\1/')" \
        "$(printf '%s' "$line" | sed -E 's/.*A=([0-9]+) R.*/\1/')" \
        "$(printf '%s' "$line" | sed -E 's/.*R=([0-9]+)/\1/')"
}

echo "=== [affine-gate] iiis = $IIIS ==="

# --- 1. ground-truth fixtures (exact) ---
katt="$(_tally "$KAT")"
if [[ "$katt" == "1 1 1" ]]; then echo "  PASS  KAT fixture       : P/A/R = $katt"
else echo "  FAIL  KAT fixture       : P/A/R = $katt  (expected 1 1 1)"; FAIL=$((FAIL+1)); fi
sndt="$(_tally "$SND")"
if [[ "$sndt" == "1 5 0" ]]; then echo "  PASS  soundness probe   : P/A/R = $sndt"
else echo "  FAIL  soundness probe   : P/A/R = $sndt  (expected 1 5 0)"; FAIL=$((FAIL+1)); fi

# --- 2/3. sweep the real tree (fixtures excluded): zero REFUTED, PROVEN > 0 ---
TP=0; TA=0; TR=0; NFILES=0; REFFILES=""
while IFS= read -r f; do
    case "$f" in *affine_audit_kat.iii|*affine_audit_sound.iii) continue ;; esac
    t="$(_tally "$f")"; [[ "$t" == "ERR" ]] && continue
    NFILES=$((NFILES+1))
    read -r p a r <<< "$t"
    TP=$((TP+p)); TA=$((TA+a)); TR=$((TR+r))
    [[ "$r" -gt 0 ]] && REFFILES="$REFFILES ${f#$ROOT/}($r)"
done < <(find "$ROOT/STDLIB/iii" "$ROOT/COMPILER/BOOT" -name '*.iii' | sort)
rm -f "$SCRATCH"

echo "  ---- real tree: files=$NFILES  PROVEN=$TP  ABSTAIN=$TA  REFUTED=$TR ----"
if [[ "$TR" -eq 0 ]]; then echo "  PASS  zero genuine REFUTED across III's real source"
else echo "  FAIL  $TR genuine REFUTED:$REFFILES"; FAIL=$((FAIL+1)); fi
if [[ "$TP" -gt 0 ]]; then echo "  PASS  PROVEN > 0 ($TP machine-checked in-bounds accesses)"
else echo "  FAIL  PROVEN = 0 -- the pass proved nothing (broken walk?)"; FAIL=$((FAIL+1)); fi

echo "============================================================"
if [[ "$FAIL" -eq 0 ]]; then echo "  [affine-gate] GREEN -- the inward Witness re-verifies clean"
else echo "  [affine-gate] $FAIL assertion(s) FAILED"; fi
echo "============================================================"
exit $FAIL
