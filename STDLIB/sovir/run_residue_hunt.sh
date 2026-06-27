#!/usr/bin/env bash
# run_residue_hunt.sh MODULE [N] -- the Φ1 residue FACTORY: find the first N (default 1) seed functions in
# COMPILER/BOOT/<MODULE>.c that the SVIR verifier rejects with rc=8 AND a residue signature (BND>=1, a value
# left on the eval stack between top-level statements), and dump each one's exact C body so the next
# decode->repro->fix->gate turn starts with the failing code in hand.  No guessing which line leaks.
# Uses the already-built STDLIB/build/sovir/_ve_trace.o + seed_<MODULE>.o + names_<MODULE>.txt (from run_seed_verify.sh).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
W="$ROOT/STDLIB/build/sovir"; IIIS="$ROOT/COMPILED/iiis-2.exe"
M="${1:-parse}"; N="${2:-1}"
"$IIIS" "$W/_ve_trace.iii" --compile-only --out "$W/_ve_trace.o" >/dev/null 2>&1 || { echo "FAIL: _ve_trace compile"; exit 1; }
gcc "$W/_ve_trace.o" "$W/seed_${M}.o" -o "$W/_rh.exe" 2>/dev/null || { echo "FAIL: link (run run_seed_verify.sh first to build seed_${M}.o)"; exit 1; }
CSRC="$ROOT/COMPILER/BOOT/${M}.c"
# every rc=8 residue fn -- _ve_trace summary now emits "sig=.. id=<idx> off=<ufOff>" (all summary lines ARE rc=8)
mapfile -t HITS < <("$W/_rh.exe" 2>/dev/null | sed -nE 's/.* id=([0-9]+) off=([0-9]+).*/\1 \2/p')
[ "${#HITS[@]}" -eq 0 ] && { echo "MODULE=$M : NO rc=8 residue functions (clean or all mis-parse)"; exit 0; }
shown=0
for h in "${HITS[@]}"; do
  [ "$shown" -ge "$N" ] && break
  idx="${h%% *}"; bnd="${h##* }"
  nm=$(awk -F': ' -v i="$idx" '$1==i{print $2}' "$W/names_${M}.txt" 2>/dev/null)
  echo "════════ MODULE=$M  idx=$idx  BND=$bnd  FN=$nm ════════"
  # dump the C body: from the definition line, brace-depth to the matching close
  awk -v FN="$nm" '
    index($0, FN "(") && $0 ~ /^[A-Za-z]/ { f=1 }
    f { print
        for (i=1;i<=length($0);i++){ c=substr($0,i,1); if(c=="{")d++; if(c=="}")d-- }
        if (seen && d<=0) exit
        if (d>0) seen=1 }
  ' "$CSRC" | sed 's/\t/    /g' | grep -nE '=|return|{|}' | head -40
  echo ""
  shown=$((shown+1))
done
