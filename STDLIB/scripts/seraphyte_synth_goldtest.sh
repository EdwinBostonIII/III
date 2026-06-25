#!/usr/bin/env bash
# seraphyte_synth_goldtest.sh -- THE GOLD STANDARD for the e-graph synthesizer: no self-authored "proof".
#
# For each constant factor v, three INDEPENDENT oracles must agree:
#   (A) SYNTHESIZER verdict   -- seg_mul_cost(v): < imul(4) => it synthesized a real shift-reduction.
#   (B) REAL MACHINE CODE     -- compile `x*v` with the production iiis-2 and DISASSEMBLE it: imul, or shifts?
#   (C) EXECUTION ON THE METAL-- run the compiled `x*v` over the overflow edges {2^61,2^63,2^64-1} against an
#                                IMUL reference (x * memory-load, which cg_r3 cannot strength-reduce).  ==v*x?
# The claim is only as strong as the disassembly (B) and the CPU (C) -- neither is my script.  (A) is then
# CROSS-CHECKED: the synthesizer must predict (B) on every factor.  A disagreement is a real finding, printed.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
W="$ROOT/STDLIB/build/_gold"; mkdir -p "$W"
say(){ printf '[gold] %s\n' "$*"; }

# rebuild ser_egraph into the archive (cheap -- one module, no cg_r3/full build)
"$IIIS" "$ROOT/STDLIB/iii/numera/ser_egraph.iii" --compile-only --out "$W/numera_ser_egraph.iii.o" >/dev/null 2>&1 \
  && ar r "$LIB" "$W/numera_ser_egraph.iii.o" >/dev/null 2>&1 || { say "FAIL: ser_egraph did not compile"; exit 2; }

synth_cost(){   # (A) the synthesizer's cost for x*$1, via exit code
  printf 'module p\nextern @abi(c-msvc-x64) fn seg_mul_cost(v: u64) -> u32 from "ser_egraph.iii"\nfn main() -> u64 { return seg_mul_cost(%su64) as u64 }\n' "$1" > "$W/_sc.iii"
  "$IIIS" "$W/_sc.iii" --compile-only --out "$W/_sc.o" >/dev/null 2>&1 && gcc "$W/_sc.o" "$LIB" -lkernel32 -o "$W/_sc.exe" >/dev/null 2>&1
  "$W/_sc.exe"; echo $?; }

cg_asm(){       # (B) the production compiler's emission for x*$1
  printf 'module q\nfn f(x: u64) -> u64 { return x * %su64 }\nfn main() -> u64 { return f(1u64) }\n' "$1" > "$W/_f.iii"
  "$IIIS" "$W/_f.iii" --compile-only --out "$W/_f.o" >/dev/null 2>&1
  objdump -d "$W/_f.o" 2>/dev/null | grep -iE 'imul|shl|sal|add[[:space:]]+%rcx|sub[[:space:]]+%rcx' | grep -oE 'imul|shl|sub|add' | tr '\n' ' '; }

run_correct(){  # (C) compiled x*$1 == $1*x on the overflow edges, vs an imul reference
  cat > "$W/_c.iii" <<EOF
module gold
var REF : [u64; 1] = [${1}u64]
fn rulef(x: u64) -> u64 { return x * ${1}u64 }      /* literal -> cg_r3 (maybe reduced) */
fn reff(x: u64) -> u64 { return x * REF[0u64] }     /* memory load -> imul reference */
fn chk(x: u64) -> u32 { if rulef(x) != reff(x) { return 1u32 } return 0u32 }
fn main() -> u64 {
    if chk(0u64) != 0u32 { return 1u64 }
    if chk(1u64) != 0u32 { return 2u64 }
    if chk(123456789u64) != 0u32 { return 3u64 }
    if chk(2305843009213693952u64) != 0u32 { return 4u64 }
    if chk(9223372036854775808u64) != 0u32 { return 5u64 }
    if chk(18446744073709551615u64) != 0u32 { return 6u64 }
    if chk(13835058055282163712u64) != 0u32 { return 7u64 }
    return 99u64
}
EOF
  "$IIIS" "$W/_c.iii" --compile-only --out "$W/_c.o" >/dev/null 2>&1 && gcc "$W/_c.o" "$LIB" -lkernel32 -o "$W/_c.exe" >/dev/null 2>&1
  "$W/_c.exe"; echo $?; }

say "v     synth(A)        cg_r3 asm(B)        run==v*x(C)   agree?"
say "----  -------------   ----------------    ----------    ------"
FAIL=0
for v in 7 8 9 5 6 10 12 14 20 28 30 11 13 100 1000; do
  cost="$(synth_cost $v)"
  asm="$(cg_asm $v)"
  rc="$(run_correct $v)"
  if [ "$cost" -lt 4 ]; then sv="REDUCE(c=$cost)"; else sv="imul(c=$cost)"; fi
  if printf '%s' "$asm" | grep -qi imul; then cv="imul"; else cv="REDUCE"; fi
  # agreement: synthesizer's reduce/imul verdict must match the real compiler's emission
  ag="OK"; [ "${sv%%(*}" = "REDUCE" ] && [ "$cv" != "REDUCE" ] && ag="MISMATCH"
  [ "${sv%%(*}" = "imul" ] && [ "$cv" != "imul" ] && ag="MISMATCH"
  [ "$rc" != "99" ] && ag="EXEC-FAIL($rc)"
  [ "$ag" != "OK" ] && FAIL=$((FAIL+1))
  printf '[gold] x*%-4s %-14s [%-16s] rc=%-3s        %s\n' "$v" "$sv" "$asm" "$rc" "$ag"
done
hr=$(printf '%0.s-' {1..60}); say "$hr"
if [ "$FAIL" = "0" ]; then
  say "GOLD STANDARD PASS: on every factor the synthesizer's verdict == the production compiler's machine code,"
  say "and that machine code computes v*x on the overflow edges (vs an imul reference). No self-authored proof."
  exit 0
else say "GOLD STANDARD: $FAIL disagreement(s) above -- a real finding, not a script returning 99."; exit 1; fi
