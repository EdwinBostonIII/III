#!/usr/bin/env bash
# run_seed_corpus.sh -- Lambda-0 CORPUS-SCALE COMPILE PARITY: the linked sovereign seed compiles EVERY
# stage1_corpus program byte-identical to gcc-built iiis-0, with exit-code parity.
#
#   S4 (run_seed_sovereign.sh) proved ONE module; this gate is the next rung: all of
#   COMPILER/BOOT/stage1_corpus/*.iii through seed.exe (ccsv 19-TU -> svir_ld -> svir_interp) vs
#   COMPILED/iiis-0.exe, both invoked FROM BOOT_DIR with the same relative input path (any embedded
#   path must match), each .o byte-compared.
#
#   The out names are deliberately LONG (_sc_<name>_s.o, abs path >= 85 chars): the first corpus
#   sweep (2026-07-08) failed 50/50 BECAUSE of the harness's long names -- ccsv resolved local
#   arrays TU-wide by name, so emit.c's `sizeof cmd` in iii_emit_assemble read the FIRST cmd's 256
#   (not its own 2048) and appendf tripped E_CMD_OVERFLOW at 256-char gcc commands (out-path >= 77)
#   -> silent EMIT_FAIL 16.  Fixed by BODYID/ABID/aidx function-scoped resolution + the stidx
#   zero-length guard (ccsv.iii; falsifier _s4_probe12.c).  Long names KEEP that defect's teeth.
#
#   Requires seed.exe (run_seed_sovereign.sh S1 builds it); rebuilds it here if missing/stale is
#   NOT attempted -- run the sovereign gate first so the two gates measure the SAME artifact.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
W="$ROOT/STDLIB/build/sovlink"; BOOT="$ROOT/COMPILER/BOOT"
SEED="$W/seed.exe"; G0="$ROOT/COMPILED/iiis-0.exe"
say(){ echo "[seed-corpus] $*"; }
[ -x "$SEED" ] || { say "FAIL: no $SEED -- run run_seed_sovereign.sh first (S1 builds it)"; exit 2; }
[ -x "$G0" ]   || { say "FAIL: no $G0"; exit 2; }
pass=0; failn=0; failed=""
cd "$BOOT" || exit 2
for f in stage1_corpus/*.iii; do
    n="$(basename "$f" .iii)"
    so="$W/_sc_${n}_s.o"; go="$W/_sc_${n}_g.o"
    rm -f "$so" "$go" "$so.s" "$go.s"
    timeout 60 "$SEED" "$f" --compile-only --out "$so" >/dev/null 2>&1; rs=$?
    timeout 60 "$G0"   "$f" --compile-only --out "$go" >/dev/null 2>&1; rg=$?
    if [ "$rs" -eq "$rg" ] && { [ "$rg" -ne 0 ] || cmp -s "$so" "$go"; }; then
        pass=$((pass+1))
    else
        failn=$((failn+1)); failed="$failed $n"
        if [ "$rs" -ne "$rg" ]; then say "FAIL $n : rc seed=$rs gcc=$rg"
        else say "FAIL $n : .o bytes diverge (rc $rs both)"; fi
    fi
done
say "corpus parity: pass=$pass fail=$failn"
if [ "$failn" -eq 0 ]; then
    say "SEED-CORPUS GREEN -- the sovereign seed compiles the WHOLE stage1_corpus byte-for-byte as gcc iiis-0."
else
    say "SEED-CORPUS RED --$failed"
fi
[ "$failn" -eq 0 ]
