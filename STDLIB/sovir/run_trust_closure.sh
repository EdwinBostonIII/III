#!/usr/bin/env bash
# run_trust_closure.sh -- III's COMPLETE trust-closure verifier (one command, the whole Thompson posture).
#
# "Trusting trust" (Thompson 1984): you cannot trust a compiler you did not build with a compiler you trust --
# a backdoor can perpetuate itself invisibly through the bootstrap.  Diverse Double-Compiling (Wheeler 2009)
# refutes it: build the SAME source with GENUINELY DIVERSE means; if they AGREE byte-for-byte, no backdoor that
# differs between them exists.  III attacks this on TWO independent axes, each gated and reproducible:
#
#   AXIS 1 -- FRONTEND IMPLEMENTATION DIVERSITY  (run_ddc.sh)
#     Two from-scratch SVIR emitters with different internal algorithms (recursive precedence-climbing vs explicit
#     shunting-yard) emit BYTE-IDENTICAL canonical SVIR for every real program, both verifier-accepted, both still
#     running to 99 on sovereign x86 + wasm.  A lowering backdoor in one (absent from the other) reddens the cmp.
#
#   AXIS 2 -- SEED COMPILER-LINEAGE DIVERSITY  (seed_ddc_msvc.sh)
#     The iiis-0 C seed, rebuilt by an INDEPENDENT-LINEAGE compiler (MSVC cl.exe -- Microsoft, not gcc/mingw),
#     produces a working iiis-0 whose object output is BYTE-IDENTICAL to the gcc-lineage seed's, across ~50 diverse
#     programs (all iiis-1 TUs + the broad witness), zero divergence.  A Thompson backdoor in the gcc-built seed
#     would have to live identically in MSVC's lineage too -- implausible.  (Seed footprint: one gcc-byte-identical
#     rename; the rest are MSVC build flags.  See COMPILER/BOOT/build_iiis0_msvc.sh.)
#
# Together: III's compilation is witnessed by IMPLEMENTATION diversity (the frontend) AND LINEAGE diversity (the
# seed) -- the two things a single hidden backdoor cannot survive.  This is the precise, gated, reproducible state
# of "closing the root", with the residual named, not hidden.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fail=0
line() { printf '%s\n' "------------------------------------------------------------------------"; }

line; echo "III TRUST CLOSURE -- Diverse Double-Compiling on two independent axes"; line

echo "[axis 1/2] FRONTEND implementation diversity (precedence-climbing vs shunting-yard SVIR emitters) ..."
if bash "$ROOT/STDLIB/sovir/run_ddc.sh" >/dev/null 2>&1; then
  echo "  PASS -- two implementation-independent emitters emit byte-identical canonical SVIR for all real programs."
else
  echo "  FAIL -- frontend emitters diverged (run STDLIB/sovir/run_ddc.sh for detail)."; fail=1
fi

echo "[axis 2/2] SEED compiler-lineage diversity (gcc/mingw vs Microsoft MSVC build the seed) ..."
if bash "$ROOT/COMPILER/BOOT/seed_ddc_msvc.sh" >/dev/null 2>&1; then
  echo "  PASS -- two independent-lineage iiis-0 seeds emit byte-identical object code for ~50 diverse programs."
else
  echo "  FAIL -- seed lineages diverged, or the MSVC seed could not be built (run COMPILER/BOOT/seed_ddc_msvc.sh)."; fail=1
fi

line
if [ $fail -eq 0 ]; then
  echo "TRUST CLOSURE: PASS on BOTH axes."
  echo "  CLOSED: frontend IMPLEMENTATION diversity + seed compiler-LINEAGE diversity, both byte-for-byte, gated."
  echo "  A single hidden compiler/seed backdoor that alters output cannot survive BOTH an algorithmically diverse"
  echo "  frontend AND a vendor-diverse bootstrap.  This is the substantive refutation, measured not asserted."
else
  echo "TRUST CLOSURE: FAIL -- one or more axes diverged (see above)."
fi
line
echo "HONEST RESIDUAL (named, not hidden -- DOCS/SVIR-DDC-RESIDUAL.md):"
echo "  - AUTHOR diversity: the two frontends (and this seed port) are one author's; real social DDC wants"
echo "    independent teams writing to the same canonical spec.  The mechanism is built and ready for a third party."
echo "  - BINARY level: the seed proof is rigorous at the .o level; a whole-iiis-1.exe byte-compare is currently"
echo "    confounded by build NON-DETERMINISM in this env (PE timestamp + mingw-ld layout / space-path file-map),"
echo "    NOT by any lineage divergence (the .iii.o are proven identical).  Fixing build reproducibility closes it."
echo "  - IRREDUCIBLE TCB: the CPU/microcode + OS loader are never DDC-removable.  The win is the smallest practical"
echo "    TCB -- this removes compiler-IMPLEMENTATION and compiler-LINEAGE trust above the silicon."
line
exit $fail
