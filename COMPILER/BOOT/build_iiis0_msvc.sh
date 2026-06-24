#!/usr/bin/env bash
# build_iiis0_msvc.sh -- build the iiis-0 C seed with MSVC (cl.exe), an INDEPENDENT-LINEAGE compiler.
#
# WHY: the III seed-DDC residual (DOCS/SVIR-DDC-RESIDUAL.md) names the deepest open hurdle as needing
# "a genuinely diverse build toolchain" for the seed -- a compiler NOT descended from the gcc that built
# iiis-0, so a Thompson "trusting trust" backdoor in gcc cannot ride into the comparison.  MSVC is exactly
# that: Microsoft's compiler, an independent lineage from gcc/mingw.  This script builds iiis-0 with it.
#
# SEED FOOTPRINT: the seed source is UNCHANGED except ONE gcc-byte-identical rename (a local var `cdecl` in
# cg_r3.c -> `callee_decl`; `cdecl` is an MSVC reserved word).  Verified: gcc's .o of cg_r3.c is bit-identical
# before/after, so the gcc reference build + its mhash golden are untouched.  The other two MSVC quirks are
# carried as BUILD FLAGS, never source edits: `/std:c11` (for _Static_assert in sid.c) and
# `/Dpopen=_popen /Dpclose=_pclose` (POSIX pipe API spelling in emit.c).
#
# TU set: identical filter to build_iiis0.sh (exclude gen_*/sign_*/verify_*/iiis1_*/*xii*/*_impl/rm2_driver).
# rm2_driver.c (the only genuine gcc-ism, __attribute__((sysv_abi))) is NOT an iiis-0 TU.
#
# Output: build/_msvcddc/iiis-0_msvc.exe -- a working Stage-0 compiler from an independent toolchain.
# This is the independent CC2 the DDC chain (next step) feeds: iiis-0_msvc -> iiis-1 -> iiis-2, compared
# byte-for-byte to the gcc-lineage reference.  Agreement = the gcc-built seed carries no Thompson backdoor.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOT="$ROOT/COMPILER/BOOT"
OUT="$ROOT/build/_msvcddc"
VCV="C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat"
WINBOOT="C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III\\COMPILER\\BOOT"
WINOUT="C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III\\build\\_msvcddc"
mkdir -p "$OUT"

# 1. the iiis-0 TU set (same filter as build_iiis0.sh)
TUS=$(cd "$BOOT" && find . -maxdepth 1 -type f -name '*.c' \
        ! -name '*_impl.c' ! -name '*xii*.c' ! -name 'gen_*.c' ! -name 'sign_*.c' \
        ! -name 'verify_*.c' ! -name 'iiis1_*.c' ! -name 'rm2_driver.c' \
        | sed 's|^\./||; s|\.c$||' | LC_ALL=C sort)
NTU=$(echo "$TUS" | wc -w)

# 2. obj response file for the link
RSP="$OUT/objs.rsp"; : > "$RSP"
for t in $TUS; do printf '"%s\\%s.obj"\n' "$WINOUT" "$t" >> "$RSP"; done

# 3. a self-contained bat: vcvars + per-TU cl + link
BAT="$OUT/build_iiis0_msvc.bat"
{
  echo '@echo off'
  echo 'setlocal enabledelayedexpansion'
  echo "call \"$VCV\" >nul 2>&1"
  echo "set BOOT=$WINBOOT"
  echo "set OUT=$WINOUT"
  echo 'set FAIL=0'
  for t in $TUS; do
    echo "cl /nologo /std:c11 /Dpopen=_popen /Dpclose=_pclose /c /TC /I \"%BOOT%\" \"%BOOT%\\$t.c\" /Fo\"%OUT%\\$t.obj\" >\"%OUT%\\e_$t.txt\" 2>&1"
    echo "if not !errorlevel!==0 ( echo FAIL_CC $t & set FAIL=1 )"
  done
  echo "link /nologo /OUT:\"%OUT%\\iiis-0_msvc.exe\" @\"%OUT%\\objs.rsp\" >\"%OUT%\\link.txt\" 2>&1"
  echo "if not !errorlevel!==0 ( echo FAIL_LINK & set FAIL=1 )"
  echo 'echo BUILD_DONE FAIL=!FAIL!'
} > "$BAT"

# 4. run it
cmd //c "$(cygpath -w "$BAT" 2>/dev/null || echo "$WINOUT\\build_iiis0_msvc.bat")" > "$OUT/build_log.txt" 2>&1
grep -E "FAIL_CC|FAIL_LINK|BUILD_DONE" "$OUT/build_log.txt" | sed 's/^/  [msvc] /'

# 5. verify the independent seed binary runs
if [ -f "$OUT/iiis-0_msvc.exe" ]; then
  BANNER=$(timeout 15 "$OUT/iiis-0_msvc.exe" 2>&1 | head -1)
  SZ=$(stat -c%s "$OUT/iiis-0_msvc.exe" 2>/dev/null)
  echo "  [msvc] iiis-0_msvc.exe BUILT ($SZ bytes), TUs=$NTU, runs: $BANNER"
  echo "  [msvc] INDEPENDENT-LINEAGE (MSVC) iiis-0 seed binary -- the diverse CC2 for the DDC chain."
else
  echo "  [msvc] FAIL: iiis-0_msvc.exe not produced"; exit 1
fi
