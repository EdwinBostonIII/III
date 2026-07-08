#!/usr/bin/env bash
# run_seed_runtime.sh -- Phi1 (R1) per-module RUNTIME-DIFFERENTIAL gate for ccsv seed compilation.
#
# WHY THIS EXISTS: the structural floor (run_seed_verify.sh / svir_verify) is a NO-UNDERFLOW check ONLY -- a
# seed module can pass the floor yet be runtime-WRONG.  Proven the hard way (2026-06-30..07-01): lex.c sat at
# structural-zero across 4 fn-ptr increments, yet iii_lex_create returned NULL when actually RUN.  A dropping
# floor is necessary but NOT sufficient.  This gate proves the STRONGER property: for each seed module that
# has a behavioral harness, ccsv->SVIR->svir_interp produces the SAME observable output as gcc (stream-mhash
# byte-identity).  gcc = the C seed's semantic reference; svir_interp = the sovereign executor of ccsv's path
# (the same two-independent-paths-agree philosophy as run_ddc.sh).
#
# TEETH (the falsifier -- a gate without teeth is decorative): the PRE-RECOVERY ccsv at commit df7ef796 (which
# emitted the lex.c NULL) MUST redden this gate; the CURRENT ccsv MUST pass it.  Positive+negative controls,
# exactly like run_seed_verify's _ve_goodmod/_ve_badmod.  If the pre-fix ccsv ever MATCHES gcc here, the gate
# has lost its teeth and a green is worthless -> that is itself a FAIL.
#
# SCOPE (honest, NOT a placeholder): only lex.c has a behavioral harness today (COMPILER/BOOT/_lexharness.c).
# sema/emit/ast/cg_r3/parse need their own harnesses (several are gated on the shadow-stack / struct-by-value
# rework) -- add a MODULES row when a REAL harness exists.  This gate proves lex.c RUNTIME and is the frame;
# it does NOT claim the other five.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/sovir"; BOOT="$ROOT/COMPILER/BOOT"
mkdir -p "$W"; say(){ echo "[seed-runtime] $*"; }
fail=0

# shared sovereign executor
"$IIIS" "$S/svir_interp.iii" --compile-only --out "$W/svir_interp.o" >/dev/null 2>&1 || { say "FAIL build svir_interp.iii"; exit 1; }

# build_ccsv SRC OUTEXE  -- iiis-2 compiles a ccsv.iii source, gcc links it to an exe
build_ccsv(){ "$IIIS" "$1" --compile-only --out "$W/_rt_ccsv.o" >/dev/null 2>&1 && gcc "$W/_rt_ccsv.o" -o "$2" 2>/dev/null; }

# ccsv_mhash CCSVEXE HARNESS.c  -- echoes the 64-hex ccsv->SVIR->interp stream-mhash (EMPTY on NULL/build-fail)
ccsv_mhash(){
  "$1" "$2" > "$W/_rt.iii" 2>/dev/null
  "$IIIS" "$W/_rt.iii" --compile-only --out "$W/_rt.o" >/dev/null 2>&1 || { echo ""; return; }
  gcc "$W/svir_interp.o" "$W/_rt.o" -o "$W/_rt_in.exe" 2>/dev/null || { echo ""; return; }
  "$W/_rt_in.exe" 2>/dev/null | grep -oE '[0-9a-f]{64}' | head -1   # strips the interp's BW:/N= watch noise
}
# gcc_mhash HARNESS.c  -- the reference stream-mhash
gcc_mhash(){ gcc "$1" -o "$W/_rt_ref.exe" 2>/dev/null && "$W/_rt_ref.exe" 2>/dev/null | grep -oE '[0-9a-f]{64}' | head -1; }

# the ccsv under test (current, recovered)
build_ccsv "$S/ccsv.iii" "$W/_rt_ccsv_cur.exe" || { say "FAIL build current ccsv.iii"; exit 1; }

# MODULES : "name:harness.c"  -- add a row ONLY when a real behavioral harness exists (no stub rows)
MODULES=( "lex:$BOOT/_lexharness.c" )

say "=== POSITIVE: current ccsv->interp stream-mhash == gcc stream-mhash, per module ==="
for row in "${MODULES[@]}"; do
  m="${row%%:*}"; h="${row#*:}"
  cg=$(gcc_mhash "$h"); ci=$(ccsv_mhash "$W/_rt_ccsv_cur.exe" "$h")
  if [ -n "$cg" ] && [ "$cg" = "$ci" ]; then say "$m : ccsv==gcc  mhash=${cg:0:16}...  RUNTIME-CORRECT"
  else say "FAIL $m : ccsv-interp[${ci:-<none>}] != gcc[${cg:-<none>}] -- ccsv miscompiles $m at RUNTIME"; fail=1; fi
done

say "=== TEETH (falsifier): the pre-recovery ccsv (in-tree fixture) MUST diverge from gcc on lex ==="
# The teeth are pinned to an IN-TREE FIXTURE, not a git ref: the original pin (commit df7ef796) was erased by
# the 2026-07-01 reorg-rewind (the "reorg-rewind casualties" of eea0fe8e) and this gate sat permanently red --
# a ref can vanish from history; committed bytes cannot.  The fixture is the REAL pre-recovery ccsv from
# surviving commit 036ce6c8 (fn-ptr Increment 2, 2026-06-30): measured 2026-07-08, it builds under current
# iiis-2 and produces the historic lex NULL (EMPTY mhash) vs gcc 4bddb768... .  Works on a pristine clone AND
# a history-less source copy.
cp "$S/_ccsv_prerecovery_lexnull.iii" "$W/_rt_ccsv_old.iii" 2>/dev/null || { say "FAIL: teeth fixture _ccsv_prerecovery_lexnull.iii missing"; fail=1; }
if build_ccsv "$W/_rt_ccsv_old.iii" "$W/_rt_ccsv_old.exe"; then
  cg=$(gcc_mhash "$BOOT/_lexharness.c"); co=$(ccsv_mhash "$W/_rt_ccsv_old.exe" "$BOOT/_lexharness.c")
  if [ "$co" != "$cg" ]; then say "teeth OK : pre-recovery ccsv lex mhash=[${co:-<NULL/none>}] != gcc[${cg:0:16}...] -- the gate REDDENS on the real bug"
  else say "TEETH BROKEN : pre-recovery ccsv MATCHED gcc -- the gate has no teeth (a green would be worthless)"; fail=1; fi
else say "FAIL build pre-recovery ccsv (teeth control could not run)"; fail=1; fi

if [ "$fail" = "0" ]; then
  say "SEED-RUNTIME GREEN -- lex.c ccsv->interp == gcc (runtime-correct, STRONGER than the structural floor);"
  say "                     teeth proven (the pre-fix fixture ccsv reddens it).  SCOPE: lex only -- add MODULES rows as harnesses land."
fi
exit $fail
