#!/usr/bin/env bash
# verify_rm2.sh -- prove the III Ring -2 (sanctum) backend works END TO END.
# parse -> sema -> emit SysV sanctum assembly -> assemble -> link -> RUN -> assert the computed result.
# A sealed_call `do_thing(x)` computes x + x + x; do_thing(7) must return 21.
# Run it yourself: `bash _audit_scratch/verify_rm2.sh`   (exit 0 = pass)
set -u
cd "$(dirname "$0")/.." || exit 9
IIIS="COMPILED/iiis-2.exe"
TMP="${TMPDIR:-/tmp}"
SRC="COMPILER/BOOT/rm2_sample.iii"
fail() { echo "FAIL: $1"; exit "${2:-1}"; }
[ -x "$IIIS" ] || fail "no $IIIS" 2

echo "== Stage 1-3: parse -> sema -> emit Ring-2 sanctum assembly =="
"$IIIS" "$SRC" --ring R-2 --emit-asm-only --out "$TMP/rm2v.s" 2>"$TMP/rm2v.err"
[ "$?" = "0" ] || { head -3 "$TMP/rm2v.err"; fail "iiis-2 --ring R-2 codegen failed" 3; }
# the sanctum format appends .s to the --out path
ASM="$TMP/rm2v.s.s"
[ -f "$ASM" ] || fail "no emitted assembly at $ASM" 3
echo "  emitted $(wc -l < "$ASM") lines of .xii_sanctum SysV assembly"
grep -q 'L_sanctum_do_thing' "$ASM" || fail "no sanctum function symbol" 3
grep -q 'callq iii_cap_verify' "$ASM" || fail "missing D10 cap-verify" 3

echo "== Stage 4: assemble -> link -> RUN =="
# adapt ELF section/type/size directives for the local (COFF) assembler; the instructions are neutral
sed -E 's/\.section \.xii_sanctum\.text[^\n]*/.text/; s/\.section \.xii_sanctum\.rodata[^\n]*/.data/; /\.type .*@function/d; /^\s*\.size /d' "$ASM" > "$TMP/rm2v_coff.s"
gcc -c "$TMP/rm2v_coff.s" -o "$TMP/rm2v.o" 2>"$TMP/rm2v_as.err" || { head -3 "$TMP/rm2v_as.err"; fail "assemble" 4; }
gcc "$TMP/rm2v.o" _audit_scratch/rm2_driver.c -o "$TMP/rm2v.exe" 2>"$TMP/rm2v_ld.err" || { head -3 "$TMP/rm2v_ld.err"; fail "link" 5; }
OUT=$("$TMP/rm2v.exe"); EC=$?
echo "  $OUT"
[ "$EC" = "21" ] || fail "do_thing(7) returned $EC, expected 21" 6

echo "PASS -- the III Ring-2 sanctum codegen emits correct, runnable machine code (3*7=21)."
exit 0
