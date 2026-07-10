#!/usr/bin/env bash
# Width-coherence re-embed chain (chain v3): rows 13/13b/14 -- eval ev_unify/
# ev_binop raw-forms + cg_svir sv_unify/bitwise-renorm + cg_r3 unified-tag
# renorm (cg_typeclass utag walk) ride PORTED_TUS through the full bootstrap;
# every gate re-proves on the re-embedded compiler; census re-runs.
# COPY TO COMPILER/BOOT/ ONLY AFTER THE THETA2-FULL COMMIT LANDS.
set -u
cd "$(dirname "$0")/../.." || exit 9
echo "=== THETA3W RE-EMBED CHAIN start ==="
run_phase() {
  local name="$1"; shift
  echo "=== PHASE $name START t=${SECONDS}s ==="
  "$@"
  local rc=$?
  echo "=== PHASE $name rc=$rc t=${SECONDS}s ==="
  if [ $rc -ne 0 ]; then echo "=== CHAIN ABORT at $name rc=$rc ==="; exit $rc; fi
}
run_phase iiis1_build bash -c 'bash COMPILER/BOOT/build_iiis1.sh; rc=$?; if [ $rc -eq 5 ]; then echo "golden drift (expected: width-coherence rows 13/13b/14) -- resealing"; NEW=$(cut -d" " -f1 COMPILED/iiis-1.exe.mhash); OLD=$(cat COMPILER/BOOT/iiis-1.mhash); echo "iiis-1 golden: $OLD -> $NEW (width-coherence, INTENTIONAL)"; printf "%s\n" "$NEW" > COMPILER/BOOT/iiis-1.mhash; exit 0; fi; exit $rc'
run_phase iiis2   bash COMPILER/BOOT/build_iiis2.sh --check-corpus
run_phase iiis3   bash COMPILER/BOOT/build_iiis3.sh
echo "=== PHASE fixpoint START t=${SECONDS}s ==="
H2=$(cut -d' ' -f1 "COMPILED/iiis-2.exe.mhash" 2>/dev/null)
H3=$(cut -d' ' -f1 "COMPILED/iiis-3.exe.mhash" 2>/dev/null)
echo "iiis-2 mhash: $H2"
echo "iiis-3 mhash: $H3"
if [ -n "$H2" ] && [ "$H2" = "$H3" ]; then
    echo "=== PHASE fixpoint rc=0 (BYTE-IDENTICAL self-host fixed point) ==="
    printf '%s\n' "$H2" > COMPILER/BOOT/iiis-2.mhash
    printf '%s\n' "$H3" > COMPILER/BOOT/iiis-3.mhash
    echo "reseal iiis-2/iiis-3 goldens -> $H2 (width-coherence, INTENTIONAL)"
else
    echo "=== PHASE fixpoint rc=1 MISMATCH ==="; echo "=== CHAIN ABORT at fixpoint rc=1 ==="; exit 1
fi
run_phase corpus  bash STDLIB/scripts/run_corpus.sh
echo "=== PHASE emit-svir-smoke START (--emit-svir through the rebuilt iiis-2) ==="
printf 'module g1s\nfn main() -> i64 { return 5 * 257 + 7 }\n' > STDLIB/build/meaning/g1smoke.iii
COMPILED/iiis-2.exe STDLIB/build/meaning/g1smoke.iii --emit-svir --out STDLIB/build/meaning/g1smoke_gen.iii >/dev/null 2>&1
if grep -q "svir_ptr" STDLIB/build/meaning/g1smoke_gen.iii 2>/dev/null; then echo "=== PHASE emit-svir-smoke rc=0 ==="; else echo "=== PHASE emit-svir-smoke rc=1 (no gen_svir) ==="; echo "=== CHAIN ABORT at emit-svir-smoke rc=1 ==="; exit 1; fi
run_phase evalb   bash COMPILER/BOOT/build_iii_eval.sh
run_phase svir-gate bash COMPILER/BOOT/run_svir_backend_gate.sh
run_phase square  bash COMPILER/BOOT/run_meaning_square.sh
run_phase warm    bash COMPILER/BOOT/_meaning_warm.sh
run_phase meaning bash COMPILER/BOOT/run_meaning.sh
run_phase sq-corpus bash COMPILER/BOOT/run_svir_corpus_gate.sh
echo "=== THETA3W RE-EMBED CHAIN COMPLETE GREEN ==="
