#!/usr/bin/env bash
# sovbuild.sh -- build ANY III program through the SOVEREIGN TOOLCHAIN, routing per module.
#
#   Each module in the program's .iii closure is COMPILED by iiis-2 (--compile-only -> .o.s), then ROUTED:
#     * SOVEREIGN  : sovas (Tier-1 encoder) assembles .o.s -> COFF .o            [no gcc]
#     * WITNESS    : if sovas refuses (a Tier-2 SIMD/SHA-NI mnemonic it cannot yet encode -> nonzero exit),
#                    gcc -c -x assembler assembles that ONE module -> COFF .o    [gcc-as, the declared witness]
#   ALL objects are LINKED by sovld/sovlink_main -> PE32+  [no ld, ever].  gcc is NEVER in the link path and
#   only ever ASSEMBLES the SIMD tail sovas cannot yet encode -- it leaves the trusted path entirely once
#   sovas Tier-2 lands.  The per-module route is printed as a MANIFEST (the consequential, capability-true
#   decision EIDOS routes through the silicon census).
#
# Usage:  sovbuild.sh  <root.iii>  [out.exe]   ->  builds + prints the route manifest; runs if it links.
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT_DIR/COMPILED/iiis-2.exe"
SOVTC="$ROOT_DIR/STDLIB/sovtc"
BOOT="$ROOT_DIR/STDLIB/build/_sovboot"
SRC="${1:?usage: sovbuild.sh <root.iii> [out.exe]}"
OUT="${2:-${SRC%.iii}.sov.exe}"
WORK="$ROOT_DIR/STDLIB/build/sovbuild"; mkdir -p "$WORK" "$BOOT"
say(){ echo "[sovbuild] $*"; }

# ---- module file index (bare name -> path) ----
declare -A FILEOF
while IFS= read -r f; do b="$(basename "$f" .iii)"; [ -z "${FILEOF[$b]+x}" ] && FILEOF[$b]="$f"; done \
  < <(find "$ROOT_DIR/STDLIB/iii" -name '*.iii'; echo "$SRC")
ROOTMOD="$(basename "$SRC" .iii)"; FILEOF[$ROOTMOD]="$SRC"

closure(){ local r="$1"; declare -A seen=(); local work=("$r") out=()
  while [ ${#work[@]} -gt 0 ]; do local m="${work[0]}"; work=("${work[@]:1}")
    [ -n "${seen[$m]+x}" ] && continue; seen[$m]=1; [ -z "${FILEOF[$m]+x}" ] && continue; out+=("$m")
    while IFS= read -r d; do [ -z "${seen[$d]+x}" ] && [ -n "${FILEOF[$d]+x}" ] && work+=("$d"); done \
      < <(grep -oE 'from "[a-z0-9_]+\.iii"' "${FILEOF[$m]}" | sed -E 's/from "([a-z0-9_]+)\.iii"/\1/')
  done; printf '%s\n' "${out[@]}"; }

# ensure the gen1 tools exist.  SEALED SEED first (no gcc -- the tools ARE the sealed seed binaries);
# gcc only when the seed is absent.  Codegen uses --emit-asm-only so it needs NO gcc either.  (Independence D1.)
ensure_tools(){
  for m in sovas sovparse sovcoff sovld sovas_main sovlink_main crt0; do
    [ -f "$BOOT/$m.o.s" ] || "$IIIS" "$SOVTC/$m.iii" --emit-asm-only --out "$BOOT/$m.o" >/dev/null 2>&1
  done
  local SEED="$SOVTC/seed"
  if [ -x "$SEED/sovas_main.seed.exe" ] && [ -x "$SEED/sovlink_main.seed.exe" ]; then
    [ -s "$BOOT/sovas_main.exe" ]   || cp "$SEED/sovas_main.seed.exe"   "$BOOT/sovas_main.exe"
    [ -s "$BOOT/sovlink_main.exe" ] || cp "$SEED/sovlink_main.seed.exe" "$BOOT/sovlink_main.exe"
  elif command -v gcc >/dev/null 2>&1; then
    for m in sovas sovparse sovcoff sovld sovas_main sovlink_main; do gcc -c -x assembler "$BOOT/$m.o.s" -o "$BOOT/$m.o" 2>/dev/null; done
    [ -s "$BOOT/sovas_main.exe" ]   || gcc "$BOOT/sovas_main.o" "$BOOT/sovparse.o" "$BOOT/sovcoff.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovas_main.exe" 2>/dev/null
    [ -s "$BOOT/sovlink_main.exe" ] || gcc "$BOOT/sovlink_main.o" "$BOOT/sovld.o" "$BOOT/sovparse.o" "$BOOT/sovas.o" -lkernel32 -o "$BOOT/sovlink_main.exe" 2>/dev/null
  fi
  [ -s "$BOOT/crt0_sov.o" ]       || timeout 30 "$BOOT/sovas_main.exe" "$BOOT/crt0.o.s" > "$BOOT/crt0_sov.o" 2>/dev/null
}

ensure_tools
mapfile -t MODS < <(closure "$ROOTMOD")
say "program=$ROOTMOD  closure=${#MODS[@]} modules"
OBJS=("$BOOT/crt0_sov.o"); NSOV=0; NWIT=0; WIT=""
for m in "${MODS[@]}"; do
  "$IIIS" "${FILEOF[$m]}" --emit-asm-only --out "$WORK/$m.o" >/dev/null 2>&1 || { say "  COMPILE-FAIL $m"; exit 3; }
  timeout 40 "$BOOT/sovas_main.exe" "$WORK/$m.o.s" > "$WORK/${m}.o.sov" 2>/dev/null; ec=$?
  if [ $ec -eq 0 ] && [ -s "$WORK/${m}.o.sov" ]; then
    OBJS+=("$WORK/${m}.o.sov"); NSOV=$((NSOV+1)); printf '  %-26s SOVEREIGN (sovas)\n' "$m"
  else
    gcc -c -x assembler "$WORK/$m.o.s" -o "$WORK/${m}.o.wit" 2>/dev/null || { say "  WITNESS-FAIL $m"; exit 4; }
    OBJS+=("$WORK/${m}.o.wit"); NWIT=$((NWIT+1)); WIT="$WIT $m"; printf '  %-26s witness  (gcc-as: Tier-2 mnemonic)\n' "$m"
  fi
done
# ---- non-.iii assembly helpers: stdlib modules reference symbols defined in hand-written .s files
# (not reachable by the  from "X.iii"  closure).  numera/cpufeat -> iii_cpuid/iii_xgetbv (cpuid_helper.s).
# Include the helper object (gcc-as witness; cpuid/xgetbv are outside sovas Tier-1) so the symbols resolve
# to real code instead of sovld import-thunking them into a bogus msvcrt import (-> runtime crash). ----
HELP=""
for m in "${MODS[@]}"; do if [ "$m" = "cpufeat" ]; then
  # sovas now encodes cpuid (0F A2) + xgetbv (0F 01 D0), so the helper assembles SOVEREIGNLY (no gcc-as).
  if timeout 30 "$BOOT/sovas_main.exe" "$ROOT_DIR/COMPILER/BOOT/cpuid_helper.s" > "$WORK/cpuid_helper.o" 2>/dev/null && [ -s "$WORK/cpuid_helper.o" ]; then
    OBJS+=("$WORK/cpuid_helper.o"); HELP="$HELP cpuid_helper.s(SOVEREIGN)"
  else
    gcc -c "$ROOT_DIR/COMPILER/BOOT/cpuid_helper.s" -o "$WORK/cpuid_helper.o" 2>/dev/null \
      && { OBJS+=("$WORK/cpuid_helper.o"); HELP="$HELP cpuid_helper.s(gcc-witness)"; NWIT=$((NWIT+1)); WIT="$WIT cpuid_helper.s"; }
  fi
fi; done
[ -n "$HELP" ] && say "asm helpers:${HELP}"

say "ROUTE MANIFEST: sovereign=$NSOV  witness=$NWIT [${WIT# }]"
timeout 90 "$BOOT/sovlink_main.exe" "${OBJS[@]}" > "$OUT" 2>"$WORK/_link.err"; lrc=$?
mz=$(od -An -tx1 -N2 "$OUT" 2>/dev/null | tr -d ' \n')
if [ "$mz" != 4d5a ]; then say "LINK FAILED rc=$lrc magic=$mz"; sed 's/^/    /' "$WORK/_link.err" 2>/dev/null | head -6; exit 5; fi
say "LINKED (sovld, no ld): $OUT  ($(stat -c%s "$OUT") bytes, PE32+)"
timeout 15 "$OUT" >/dev/null 2>&1; rc=$?
say "RUN exit=$rc $( [ $rc -eq 99 ] && echo '<<< the program runs SOVEREIGN to 99' )"
[ $rc -eq 99 ] && exit 0 || exit 1
