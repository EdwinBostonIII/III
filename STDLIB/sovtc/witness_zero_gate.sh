#!/usr/bin/env bash
# witness_zero_gate.sh -- the CRYPTO-CLOSURE WITNESS-ZERO gate (audit P2a).
#
# Builds real crypto programs (SHA-256 / SHA-3 / SHA-512 -- the VEX/EVEX-emitting closure) through the
# sovereign toolchain and asserts the route manifest reads `witness=0`: sovas encodes EVERY mnemonic these
# modules emit (VEX, EVEX, the 32-bit integer tail, cpuid/xgetbv), so gcc-as is nowhere in the assemble path.
# Any module (or the cpuid_helper.s asm helper) that falls back to gcc-as raises the witness count and reddens
# this gate.  rc is captured directly from the parsed manifest -- never through a pipe.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SOVBUILD="$ROOT/STDLIB/sovtc/sovbuild.sh"
say(){ echo "[witness0] $*"; }
fail=0

# crypto programs whose closure pulls the 7 VEX/EVEX SIMD modules (sha256/sha512/keccak + deps)
PROGS="STDLIB/corpus/02_sha256_kat_abc.iii STDLIB/corpus/156_sha3_512_kat_abc.iii STDLIB/corpus/168_keccak_zero.iii"
for p in $PROGS; do
  [ -f "$ROOT/$p" ] || { say "SKIP $(basename "$p") (absent)"; continue; }
  out="$(bash "$SOVBUILD" "$ROOT/$p" 2>/dev/null)"
  man="$(printf '%s\n' "$out" | grep 'ROUTE MANIFEST' | head -1)"
  helpers="$(printf '%s\n' "$out" | grep 'asm helpers' | head -1)"
  wit="$(printf '%s\n' "$man" | grep -oE 'witness=[0-9]+' | grep -oE '[0-9]+')"
  # a gcc-witness asm helper (cpuid_helper.s) also violates witness-zero
  gccwit=0
  printf '%s\n' "$helpers" | grep -q 'gcc-witness' && gccwit=1
  if [ "${wit:-1}" = "0" ] && [ "$gccwit" = "0" ]; then
    say "PASS $(basename "$p") -> ${man#*ROUTE MANIFEST: }  |  ${helpers#*asm helpers:}"
  else
    say "FAIL $(basename "$p") -> witness=${wit:-?} gccwit=$gccwit  ($man ; $helpers)"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then say "ALL witness=0 -- the crypto closure assembles with ZERO gcc-as (sovereign)"; exit 0; fi
say "WITNESS PRESENT -- a module or asm helper still needs gcc-as"; exit 1
