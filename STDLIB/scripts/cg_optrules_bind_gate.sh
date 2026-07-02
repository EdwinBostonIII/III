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

# compile the module ONCE (it externs typecheck.iii's CIC kernel -- the expensive compile), then reuse.
"$IIIS" "$MOD" --compile-only --out "$W/_pcmod.o" >/dev/null 2>&1 || { echo "[path-c] FATAL: module did not compile"; exit 9; }

# compile a driver, link against the cached module + lib, run, echo the exit code.
_run() {  # $1 = driver .iii text -> echoes rc
  printf '%s\n' "$1" > "$W/_pcdrv.iii"
  "$IIIS" "$W/_pcdrv.iii" --compile-only --out "$W/_pcdrv.o" >/dev/null 2>&1 || { echo 254; return; }
  gcc "$W/_pcdrv.o" "$W/_pcmod.o" "$LIB" -lkernel32 -o "$W/_pcdrv.exe" 2>/dev/null || { echo 253; return; }
  # 120s: cor_selftest CIC-certifies all 63 tabled rules and measured 41s wall on 2026-07-02
  # (the 30s budget predates the table's growth; a hang still dies well inside the gate).
  timeout 120 "$W/_pcdrv.exe" >/dev/null 2>&1; echo $?
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

# ---- (B-shladd) emit binding: each tabled SHLADD shift k => x*(2^k+1) must emit `shl $k` + `add %rcx,%rax`, NO imul ----
NS=$(_run 'module d
extern @abi(c-msvc-x64) fn cor_sl_rule_count() -> u64 from "cg_opt_rules.iii"
fn main() -> u64 { return cor_sl_rule_count() }')
say "shladd rule count (from module) = $NS"
i=0
while [ "$i" -lt "$NS" ]; do
  K=$(_run "module d
extern @abi(c-msvc-x64) fn cor_sl_shift_at(idx: u64) -> u64 from \"cg_opt_rules.iii\"
fn main() -> u64 { return cor_sl_shift_at(${i}u64) }")
  FACTOR=$(( (1 << K) + 1 ))            # 2^k+1 (printf %u below reinterprets the bits for k=63)
  HEXK=$(printf '%x' "$K")
  printf 'module p\nfn f(x: u64) -> u64 { return x * %uu64 }\nfn main() -> u64 { return f(1u64) }\n' "$FACTOR" > "$W/_pcsl.iii"
  "$IIIS" "$W/_pcsl.iii" --compile-only --out "$W/_pcsl.o" >/dev/null 2>&1
  asm="$(objdump -d "$W/_pcsl.o" 2>/dev/null | grep -iE 'shl|sal|imul|add[[:space:]]+%rcx,%rax')"
  if printf '%s' "$asm" | grep -qiE "(shl|sal)[[:space:]]+\\\$(0x${HEXK}|${K})," && printf '%s' "$asm" | grep -qiE 'add[[:space:]]+%rcx,%rax' && ! printf '%s' "$asm" | grep -qi imul; then
    say "(B-shladd) rule $i : x*$FACTOR (2^$K+1) -> 'shl \$0x$HEXK' + 'add %rcx,%rax', NO imul  [shl+add bound: certified == emitted]"
  else
    say "(B-shladd) FAIL rule $i : x*$FACTOR (2^$K+1) did NOT emit shl+add -- got: $(printf '%s' "$asm" | tr '\n' ';')"; FAIL=$((FAIL+1))
  fi
  i=$((i+1))
done

# ---- (C-shladd) emit negative: a factor that is NONE of pow2/2^k+1/2^k-1 (11) must emit imul, NOT shl+add ----
# (was x*7, but 7 = 2^3-1 now binds to the shl-sub rule below; 11 is none of the three strength classes.)
printf 'module p\nfn f(x: u64) -> u64 { return x * 11u64 }\nfn main() -> u64 { return f(1u64) }\n' > "$W/_pcslneg.iii"
"$IIIS" "$W/_pcslneg.iii" --compile-only --out "$W/_pcslneg.o" >/dev/null 2>&1
slneg="$(objdump -d "$W/_pcslneg.o" 2>/dev/null | grep -iE 'shl|sal|imul')"
if printf '%s' "$slneg" | grep -qi imul && ! printf '%s' "$slneg" | grep -qiE 'shl|sal'; then
  say "(C-shladd) negative : x*11 (non-pow2, non-2^k+1, non-2^k-1) -> 'imul', NO shift  [shl+add binding has teeth]"
else
  say "(C-shladd) FAIL negative : x*11 did not emit imul-without-shift -- got: $(printf '%s' "$slneg" | tr '\n' ';')"; FAIL=$((FAIL+1))
fi

# ---- (B-subk) emit binding: each tabled SUBK shift k => x*(2^k-1) must emit `shl $k` + `sub %rcx,%rax`, NO imul ----
NB=$(_run 'module d
extern @abi(c-msvc-x64) fn cor_ss_rule_count() -> u64 from "cg_opt_rules.iii"
fn main() -> u64 { return cor_ss_rule_count() }')
say "subk rule count (from module) = $NB"
i=0
while [ "$i" -lt "$NB" ]; do
  K=$(_run "module d
extern @abi(c-msvc-x64) fn cor_ss_shift_at(idx: u64) -> u64 from \"cg_opt_rules.iii\"
fn main() -> u64 { return cor_ss_shift_at(${i}u64) }")
  FACTOR=$(( (1 << K) - 1 ))            # 2^k-1 (Mersenne; positive int64 for k<=63)
  HEXK=$(printf '%x' "$K")
  printf 'module p\nfn f(x: u64) -> u64 { return x * %uu64 }\nfn main() -> u64 { return f(1u64) }\n' "$FACTOR" > "$W/_pcss.iii"
  "$IIIS" "$W/_pcss.iii" --compile-only --out "$W/_pcss.o" >/dev/null 2>&1
  asm="$(objdump -d "$W/_pcss.o" 2>/dev/null | grep -iE 'shl|sal|imul|sub[[:space:]]+%rcx,%rax')"
  if printf '%s' "$asm" | grep -qiE "(shl|sal)[[:space:]]+\\\$(0x${HEXK}|${K})," && printf '%s' "$asm" | grep -qiE 'sub[[:space:]]+%rcx,%rax' && ! printf '%s' "$asm" | grep -qi imul; then
    say "(B-subk) rule $i : x*$FACTOR (2^$K-1) -> 'shl \$0x$HEXK' + 'sub %rcx,%rax', NO imul  [shl+sub bound: certified == emitted]"
  else
    say "(B-subk) FAIL rule $i : x*$FACTOR (2^$K-1) did NOT emit shl+sub -- got: $(printf '%s' "$asm" | tr '\n' ';')"; FAIL=$((FAIL+1))
  fi
  i=$((i+1))
done

# ---- (C-subk) emit negative: a non-pow2/2^k+1/2^k-1 factor (13) must emit imul, NOT shl+sub ----
printf 'module p\nfn f(x: u64) -> u64 { return x * 13u64 }\nfn main() -> u64 { return f(1u64) }\n' > "$W/_pcssneg.iii"
"$IIIS" "$W/_pcssneg.iii" --compile-only --out "$W/_pcssneg.o" >/dev/null 2>&1
ssneg="$(objdump -d "$W/_pcssneg.o" 2>/dev/null | grep -iE 'shl|sal|imul')"
if printf '%s' "$ssneg" | grep -qi imul && ! printf '%s' "$ssneg" | grep -qiE 'shl|sal'; then
  say "(C-subk) negative : x*13 (non-pow2/2^k+1/2^k-1) -> 'imul', NO shift  [shl+sub binding has teeth]"
else
  say "(C-subk) FAIL negative : x*13 did not emit imul-without-shift -- got: $(printf '%s' "$ssneg" | tr '\n' ';')"; FAIL=$((FAIL+1))
fi

# ---- (C) emit negative: a factor outside EVERY certified family must emit imul, NOT shl ----
# HISTORY (2026-07-02 whole-tree sweep): this arm's original factor was 6, chosen when only the
# plain-pow2 rules existed.  The certified strength-reduction family has since grown to cover
# 6 = 2^2 + 2^1 (two-shift + add decomposition, legitimately emitted, certificates bound by the
# (B) family checks) -- so 6 stopped being a negative.  19 (10011b) is outside pow2, 2^k+-1, and
# the two-term family: verified 2026-07-02 to emit movabs+imul with zero shifts.
printf 'module p\nfn f(x: u64) -> u64 { return x * 19u64 }\nfn main() -> u64 { return f(1u64) }\n' > "$W/_pcneg.iii"
"$IIIS" "$W/_pcneg.iii" --compile-only --out "$W/_pcneg.o" >/dev/null 2>&1
negasm="$(objdump -d "$W/_pcneg.o" 2>/dev/null | grep -iE 'shl|sal|imul')"
if printf '%s' "$negasm" | grep -qi imul && ! printf '%s' "$negasm" | grep -qiE 'shl|sal'; then
  say "(C) negative : x*19 (outside all certified families) -> emits 'imul', NO shift  [the binding has teeth]"
else
  say "(C) FAIL negative : x*19 did not emit imul-without-shift -- got: $(printf '%s' "$negasm" | tr '\n' ';')"; FAIL=$((FAIL+1))
fi

echo "============================================================"
if [ "$FAIL" -eq 0 ]; then
  say "GREEN -- the SR rule table is bound: CIC kernel proof <-> width-invariance guard <-> cg_r3 emission, one source."
else say "$FAIL stage(s) FAILED"; fi
echo "============================================================"
exit $FAIL
