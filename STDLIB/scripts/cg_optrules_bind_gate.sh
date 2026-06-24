#!/usr/bin/env bash
# cg_optrules_bind_gate.sh -- Path C: the PROOF->EMIT BINDING gate (the F6 sovereign-optimizer fix).
#
# The F6 audit found the BV64 shift-fold proof is genuine but never inspects the emitter -- "proof-
# carrying" with no mechanical proof->emit binding.  This gate closes it by routing ONE source of truth
# (forcefield/cg_opt_rules.iii's COR_SHIFT/COR_FACTOR table) through THREE checks that must all agree:
#
#   (A) KERNEL PROOF + WIDTH GUARD : cor_selftest()==99  -- every tabled rule is CIC-kernel-certified
#       width-faithful (x<<k == x*2^k mod 2^64) AND the certifier provably rejects unsound rules.
#   (B) EMIT BINDING               : for each tabled SHIFT k read FROM THE MODULE, compile `x * 2^k`
#       through the live iiis-2 (cg_r3) and assert the emission is exactly `shl $k` (no imul).
#       => the kernel-certified rule and cg_r3's real machine code are bound to the same table.
#   (C) EMIT NEGATIVE             : a NON-pow2 factor (6) must emit `imul` and NOT `shl` -- proving cg_r3
#       does not blindly shift, so (B) is a real agreement, not a tautology.
#
# DIVERGENCE reddens: if cg_r3 ever emitted imul for a tabled pow2 (lost the fold) or the WRONG shift,
# (B) fails; if the kernel rejected a tabled rule, (A) fails.  Exit 0 = bound; non-zero = the failing stage.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
MOD="$ROOT/STDLIB/iii/forcefield/cg_opt_rules.iii"
W="$ROOT/STDLIB/build/sovir"; mkdir -p "$W"
FAIL=0; say(){ echo "[path-c] $*"; }

# compile the module + a driver, link against the lib, run, echo the exit code.
_run() {  # $1 = driver .iii text -> echoes rc
  printf '%s\n' "$1" > "$W/_pcdrv.iii"
  "$IIIS" "$MOD" --compile-only --out "$W/_pcmod.o" >/dev/null 2>&1 || { echo 255; return; }
  "$IIIS" "$W/_pcdrv.iii" --compile-only --out "$W/_pcdrv.o" >/dev/null 2>&1 || { echo 254; return; }
  gcc "$W/_pcdrv.o" "$W/_pcmod.o" "$LIB" -lkernel32 -o "$W/_pcdrv.exe" 2>/dev/null || { echo 253; return; }
  timeout 30 "$W/_pcdrv.exe" >/dev/null 2>&1; echo $?
}

# ---- (A) kernel proof + width guard ----
rc=$(_run 'module d
extern @abi(c-msvc-x64) fn cor_selftest() -> u64 from "cg_opt_rules.iii"
fn main() -> u64 { return cor_selftest() }')
if [ "$rc" = "99" ]; then say "(A) kernel proof + width guard : cor_selftest = 99  (table CIC-certified width-faithful, negative arm bites)"
else say "(A) FAIL : cor_selftest = $rc (expected 99)"; FAIL=$((FAIL+1)); fi

# ---- read the rule count FROM THE MODULE ----
N=$(_run 'module d
extern @abi(c-msvc-x64) fn cor_rule_count() -> u64 from "cg_opt_rules.iii"
fn main() -> u64 { return cor_rule_count() }')
say "table rule count (from module) = $N"

# ---- (B) emit binding: each tabled shift k  =>  x*2^k must emit `shl $k` ----
i=0
while [ "$i" -lt "$N" ]; do
  K=$(_run "module d
extern @abi(c-msvc-x64) fn cor_shift_at(idx: u64) -> u64 from \"cg_opt_rules.iii\"
fn main() -> u64 { return cor_shift_at(${i}u64) }")
  FACTOR=$(( 1 << K ))
  HEXK=$(printf '%x' "$K")
  printf 'module p\nfn f(x: u64) -> u64 { return x * %uu64 }\nfn main() -> u64 { return f(1u64) }\n' "$FACTOR" > "$W/_pcemit.iii"
  "$IIIS" "$W/_pcemit.iii" --compile-only --out "$W/_pcemit.o" >/dev/null 2>&1
  asm="$(objdump -d "$W/_pcemit.o" 2>/dev/null | grep -iE 'shl|sal|imul')"
  # objdump prints the shift-by-1 short form (opcode D1 /4) as `shl $1` (decimal, no 0x); shifts >=2 use
  # the C1 ib form `shl $0x<hex>`. Accept either so the certified shift binds to its real encoding.
  if printf '%s' "$asm" | grep -qiE "(shl|sal)[[:space:]]+\\\$(0x${HEXK}|${K})," && ! printf '%s' "$asm" | grep -qi imul; then
    say "(B) rule $i : x*$FACTOR (2^$K) -> emits 'shl \$0x$HEXK'  [bound: kernel-certified == emitted]"
  else
    say "(B) FAIL rule $i : x*$FACTOR (2^$K) did NOT emit 'shl \$0x$HEXK' -- got: $(printf '%s' "$asm" | tr '\n' ';')"; FAIL=$((FAIL+1))
  fi
  i=$((i+1))
done

# ---- (C) emit negative: a non-pow2 factor must emit imul, NOT shl ----
printf 'module p\nfn f(x: u64) -> u64 { return x * 6u64 }\nfn main() -> u64 { return f(1u64) }\n' > "$W/_pcneg.iii"
"$IIIS" "$W/_pcneg.iii" --compile-only --out "$W/_pcneg.o" >/dev/null 2>&1
negasm="$(objdump -d "$W/_pcneg.o" 2>/dev/null | grep -iE 'shl|sal|imul')"
if printf '%s' "$negasm" | grep -qi imul && ! printf '%s' "$negasm" | grep -qiE 'shl|sal'; then
  say "(C) negative : x*6 (non-pow2) -> emits 'imul', NO shift  [the binding has teeth]"
else
  say "(C) FAIL negative : x*6 did not emit imul-without-shift -- got: $(printf '%s' "$negasm" | tr '\n' ';')"; FAIL=$((FAIL+1))
fi

echo "============================================================"
if [ "$FAIL" -eq 0 ]; then
  say "GREEN -- the SR rule table is bound: CIC kernel proof <-> width-invariance guard <-> cg_r3 emission, one source."
else say "$FAIL stage(s) FAILED"; fi
echo "============================================================"
exit $FAIL
