#!/usr/bin/env bash
# seraphyte_reseal_driver.sh -- THE AUTONOMOUS SELF-APPLICATION LOOP (closure C5, faithful).
#
# Closes the autopoietic loop with NO HUMAN authoring OR authorizing the rewrite.  The driver, unattended,
# runs the full cycle on the REAL codegen, starting from a state where the rule does NOT exist:
#
#   BASELINE(rule-absent) -> DISCOVER the gap -> EMIT source (the patch-emitter, not a human) ->
#   REBUILD -> GATE(fixpoint + cert + binary) -> ACCEPT | (unsound) ROLLBACK byte-exact
#
# The DECISIVE difference from a gate-only demo: STEP 3 calls seraphyte_emit_rule.sh, which GENERATES the
# rule's source text from a descriptor.  No `Edit`, no human keystroke writes the rule.  The gate's exit
# code (machine, not operator) authorizes the self-modification of the trusted base.  Evergreen: every step
# is reproduced from source by the canonical build.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
FF="$ROOT/STDLIB/iii/forcefield/cg_opt_rules.iii"
BOOT="$ROOT/COMPILER/BOOT/cg_opt_rules.iii"
F3=(COMPILER/BOOT/cg_opt_rules.iii COMPILER/BOOT/cg_r3.iii COMPILER/BOOT/cg_r3.c)   # the 3 codegen files
W="$ROOT/STDLIB/build/_reseal"; mkdir -p "$W"
say(){ printf '[reseal] %s\n' "$*"; }
hr(){  printf '%s\n' "------------------------------------------------------------"; }

rebuild_iiis2(){ rm -f "$IIIS" 2>/dev/null; ( cd "$ROOT" && bash COMPILER/BOOT/build_iiis2.sh ) >/dev/null 2>&1; }
emit_x7(){ printf 'module p\nfn f(x: u64) -> u64 { return x * 7u64 }\nfn main() -> u64 { return f(1u64) }\n' > "$W/_x7.iii"
           "$IIIS" "$W/_x7.iii" --compile-only --out "$W/_x7.o" >/dev/null 2>&1
           objdump -d "$W/_x7.o" 2>/dev/null | grep -iE 'shl|sal|sub[[:space:]]+%rcx|imul'; }
update_archive(){ "$IIIS" "$FF" --compile-only --out "$W/forcefield_cg_opt_rules.iii.o" >/dev/null 2>&1
                  "$IIIS" "$BOOT" --compile-only --out "$W/boot_cg_opt_rules.iii.o" >/dev/null 2>&1
                  ar r "$LIB" "$W/forcefield_cg_opt_rules.iii.o" "$W/boot_cg_opt_rules.iii.o" >/dev/null 2>&1; }
gate_cor_selftest(){ update_archive
  printf 'module d\nextern @abi(c-msvc-x64) fn cor_selftest() -> u64 from "cg_opt_rules.iii"\nfn main() -> u64 { return cor_selftest() }\n' > "$W/_gd.iii"
  "$IIIS" "$W/_gd.iii" --compile-only --out "$W/_gd.o" >/dev/null 2>&1 || { echo 254; return; }
  gcc "$W/_gd.o" "$LIB" -lkernel32 -o "$W/_gd.exe" >/dev/null 2>&1 || { echo 253; return; }
  timeout 120 "$W/_gd.exe" >/dev/null 2>&1; echo $?; }

cd "$ROOT"
hr; say "STEP 0 -- BASELINE (rule-absent): revert the 3 codegen files to HEAD (no shl-sub), rebuild iiis-2"
git checkout HEAD -- "${F3[@]}"
[ "$(grep -c cgopt_mul_subk_admit "$BOOT")" = "0" ] || { say "FAIL: not rule-absent"; exit 1; }
rebuild_iiis2
say "  rule-absent compiler built (no subk rule)."

hr; say "STEP 1 -- DISCOVER the gap (engine proves valid; the compiler does NOT emit it)"
cat > "$W/_gap.iii" <<'EOF'
module gp
extern @abi(c-msvc-x64) fn bv_reset() -> i32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_var(v: u32) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_const(c: u64) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_sub(a: u32, b: u32) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_mul(a: u32, b: u32) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_shl(a: u32, k: u32) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_equal(a: u32, b: u32) -> u8 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bb_reset(w: u64) -> i32 from "bv_bits.iii"
extern @abi(c-msvc-x64) fn bb_var(v: u32) -> u32 from "bv_bits.iii"
extern @abi(c-msvc-x64) fn bb_const(c: u64) -> u32 from "bv_bits.iii"
extern @abi(c-msvc-x64) fn bb_sub(a: u32, b: u32) -> u32 from "bv_bits.iii"
extern @abi(c-msvc-x64) fn bb_mul(a: u32, b: u32) -> u32 from "bv_bits.iii"
extern @abi(c-msvc-x64) fn bb_shl(a: u32, k: u64) -> u32 from "bv_bits.iii"
extern @abi(c-msvc-x64) fn bb_equal(a: u32, b: u32) -> u8 from "bv_bits.iii"
fn main() -> u64 {
    bv_reset()
    let x: u32 = bv_var(0u32)
    if bv_equal(bv_sub(bv_shl(x, 3u32), x), bv_mul(x, bv_const(7u64))) != 1u8 { return 1u64 }
    bb_reset(64u64)
    let y: u32 = bb_var(0u32)
    if bb_equal(bb_sub(bb_shl(y, 3u64), y), bb_mul(y, bb_const(7u64))) != 1u8 { return 2u64 }
    return 99u64
}
EOF
"$IIIS" "$W/_gap.iii" --compile-only --out "$W/_gap.o" >/dev/null 2>&1
gcc "$W/_gap.o" "$LIB" -lkernel32 -o "$W/_gap.exe" >/dev/null 2>&1
timeout 60 "$W/_gap.exe" >/dev/null 2>&1; GP=$?
BASE_ASM="$(emit_x7)"
if [ "$GP" = "99" ] && printf '%s' "$BASE_ASM" | grep -qi imul && ! printf '%s' "$BASE_ASM" | grep -qiE 'sub[[:space:]]+%rcx'; then
  say "  GAP CONFIRMED: bv_ring & bv_bits PROVE x*7 == (x<<3)-x valid, but rule-absent cg_r3 emits 'imul'."
else say "  STEP 1 unexpected (GP=$GP asm=$(printf '%s' "$BASE_ASM"|tr '\n' ';'))"; bash STDLIB/scripts/seraphyte_emit_rule.sh subk >/dev/null 2>&1; exit 2; fi

hr; say "STEP 2 -- EMIT: the patch-emitter writes the rule's source from a descriptor (no human)"
bash STDLIB/scripts/seraphyte_emit_rule.sh subk 2>&1 | grep -E '^\[emit\]' | sed 's/^/  /'

hr; say "STEP 3 -- APPLY + REBUILD: rebuild iiis-2 (emitter source) + iiis-3, then GATE"
rebuild_iiis2
update_archive          # iiis-3 does NOT port cg_opt_rules -- it links the BOOT rule from the archive, so refresh it first
NEW_ASM="$(emit_x7)"
rm -f COMPILED/iiis-3.exe 2>/dev/null
FIX="$( ( cd "$ROOT" && bash COMPILER/BOOT/build_iiis3.sh --check-corpus ) 2>&1 | grep -oE '[0-9]+ passed, [0-9]+ failed' | tail -1 )"
RC="$(gate_cor_selftest)"
hr; say "STEP 4 -- GATE verdict (machine-authorized, no operator):"
say "  binary: x*7 now emits -> $(printf '%s' "$NEW_ASM" | grep -iE 'shl|sub[[:space:]]+%rcx' | tr '\n' ' ')"
say "  self-host fixpoint iiis-2==iiis-3 : $FIX"
say "  multi-engine certifier cor_selftest : $RC"
if printf '%s' "$NEW_ASM" | grep -qiE 'sub[[:space:]]+%rcx' && ! printf '%s' "$NEW_ASM" | grep -qi imul && [ "$FIX" = "59 passed, 0 failed" ] && [ "$RC" = "99" ]; then
  say "  DECISION: ACCEPT -- the EMITTER's rule closed a real gap; fixpoint + cert green; no human in the loop."
else say "  DECISION: REJECT (gate not all-green) -- leaving emitted source for inspection"; exit 3; fi

hr; say "STEP 5 -- ROLLBACK teeth: emit an UNSOUND variant, prove the gate refuses + auto-revert byte-exact"
SOUND_SHA="$(sha256sum "$BOOT" | cut -d' ' -f1)"
git checkout HEAD -- "${F3[@]}"                                  # back to rule-absent
bash STDLIB/scripts/seraphyte_emit_rule.sh subk 7 R3_STR_SUBQ subq unsound >/dev/null 2>&1   # over-admitting rule
rebuild_iiis2
RCU="$(gate_cor_selftest)"
if [ "$RCU" != "99" ]; then say "  GATE RED (cor_selftest=$RCU) -> ROLLBACK: the unsound (over-admit) rule is REFUSED."
else say "  FAIL: unsound rule passed -- no teeth"; git checkout HEAD -- "${F3[@]}"; bash STDLIB/scripts/seraphyte_emit_rule.sh subk >/dev/null 2>&1; rebuild_iiis2; gate_cor_selftest >/dev/null; exit 4; fi
git checkout HEAD -- "${F3[@]}"; bash STDLIB/scripts/seraphyte_emit_rule.sh subk >/dev/null 2>&1   # revert + re-emit SOUND
rebuild_iiis2; RCR="$(gate_cor_selftest)"; REV_SHA="$(sha256sum "$BOOT" | cut -d' ' -f1)"
if [ "$SOUND_SHA" = "$REV_SHA" ] && [ "$RCR" = "99" ]; then say "  ROLLBACK VERIFIED: rule-table restored BYTE-EXACT (${REV_SHA:0:16}...) and re-greens (cor_selftest=99)."
else say "  ROLLBACK FAILED (sha=$([ "$SOUND_SHA" = "$REV_SHA" ] && echo ok || echo NO) re-gate=$RCR)"; exit 5; fi

hr; say "CLOSURE COMPLETE: gap discovered -> EMITTER wrote the rule -> machine gate ACCEPTED (fixpoint+cert)"
say "                  -> unsound variant ROLLED BACK byte-exact.  The compiler rewrote itself; no human in the loop."
hr; exit 0
