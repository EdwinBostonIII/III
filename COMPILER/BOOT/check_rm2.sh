#!/usr/bin/env bash
# check_rm2.sh -- reseal gate: prove the Ring -2 (sanctum / cg_rm2) backend still emits correct,
# RUNNABLE machine code. The determinism corpus does NOT exercise --ring R-2, so cg_rm2 can silently
# rot -- e.g. its node-kind constants drifting from ast.iii (the exact bug class that broke it before).
# This compiles a sealed_call, emits the sanctum assembly, assembles+links+RUNS it, and asserts the
# computed result: do_thing(7) == 3*7 == 21.  Falsifiable: break a cg_rm2 kind/op constant -> this reddens.
#
# Usage: check_rm2.sh [path-to-iiis-2]    (defaults to COMPILED/iiis-2.exe)
set -u
BOOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$BOOT_DIR/../.." && pwd)"
case "${OS:-}${OSTYPE:-}" in *Windows*|*mingw*|*msys*|*cygwin*) SFX=".exe" ;; *) SFX="" ;; esac
IIIS="${1:-$REPO/COMPILED/iiis-2$SFX}"
SRC="$BOOT_DIR/rm2_sample.iii"
DRV="$BOOT_DIR/rm2_driver.c"
TMP="${TMPDIR:-/tmp}/rm2gate_$$"; mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

[ -x "$IIIS" ] || { echo "[check-rm2] FAIL: no compiler at $IIIS"; exit 1; }
[ -f "$SRC" ]  || { echo "[check-rm2] FAIL: no sample $SRC"; exit 1; }
command -v gcc >/dev/null 2>&1 || { echo "[check-rm2] SKIP: no gcc (assemble/run unavailable)"; exit 0; }

# Stage 1-3: parse -> sema -> emit Ring -2 sanctum assembly (format appends .s to --out)
"$IIIS" "$SRC" --ring R-2 --emit-asm-only --out "$TMP/s.s" >/dev/null 2>&1 || { echo "[check-rm2] FAIL: --ring R-2 codegen (rc=$?)"; exit 1; }
ASM="$TMP/s.s.s"
[ -f "$ASM" ] || { echo "[check-rm2] FAIL: no emitted assembly"; exit 1; }

# Stage 4: COFF-adapt the ELF section/type/size directives (instructions are neutral), assemble, link, RUN
sed -E 's/\.section \.xii_sanctum\.text[^\n]*/.text/; s/\.section \.xii_sanctum\.rodata[^\n]*/.data/; /\.type .*@function/d; /^[[:space:]]*\.size /d' "$ASM" > "$TMP/c.s"
gcc -c "$TMP/c.s" -o "$TMP/s.o"        >/dev/null 2>&1 || { echo "[check-rm2] FAIL: assemble (invalid emitted instruction?)"; exit 1; }
gcc "$TMP/s.o" "$DRV" -o "$TMP/r$SFX"  >/dev/null 2>&1 || { echo "[check-rm2] FAIL: link"; exit 1; }
"$TMP/r$SFX" >/dev/null 2>&1; ec=$?
[ "$ec" = "21" ] || { echo "[check-rm2] FAIL: rc=$ec (1=do_thing!=21 arithmetic; 2=u64 high-bit ordering took SIGNED setcc -- the cg_rm2 signedness bug; 3=i64 ordering REGRESSED to unsigned; 4=R2 typed-binary u64 ordering took the OLD lhs-only walk -> signed setcc); expected 21 (all four pass)"; exit 1; }
echo "[check-rm2] OK: Ring -2 sanctum do_thing(7)=21 + u64-ordering(0x4..<0x8..)=1 (unsigned) + i64-ordering(-7<5)=1 (signed) + R2 typed-binary u64-ordering=1 (lhs-else-rhs shared resolver)"
exit 0
