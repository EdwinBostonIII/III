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
# the rule-absent BASELINE: the subk shl-sub rule was committed in c9dfd87d, so HEAD now CONTAINS it; its parent
# f52c6ac8 is the rule-absent state the full driver must start from (overridable via RESEAL_BASELINE).
BASELINE_REF="${RESEAL_BASELINE:-f52c6ac8}"
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

# === EIDOS WIRE: witness the reseal accept/rollback decision on the matured eidos/field substrate ==========
# The autopoietic accept/rollback ran on nothing III consumes (island).  These record the driver's REAL gate
# verdict on eidos/field (numera/ser_eidos -> eidos/field, which encapsulates ripple_field+event_substrate+dome
# -- we build on field, NEVER on dome the POC).  ACCEPT -> a witnessed field_record; REFUTE -> field_rewind,
# the abandoned rule retained as field_provenance.  Proof is THIS driver's executed output, not a corpus test.
sev_field_accept() {   # $1=verdict $2=rule_id  -> exit code: committed frontier (1=accepted+witnessed), else 0
  cat > "$W/_sev_a.iii" <<EOF
module sa
extern @abi(c-msvc-x64) fn sev_begin() -> i32 from "ser_eidos.iii"
extern @abi(c-msvc-x64) fn sev_reseal_record(verdict: u64, rule_id: u64) -> u64 from "ser_eidos.iii"
extern @abi(c-msvc-x64) fn sev_frontier() -> u32 from "ser_eidos.iii"
extern @abi(c-msvc-x64) fn sev_witness() -> u64 from "ser_eidos.iii"
fn main() -> u64 {
    sev_begin()
    sev_reseal_record(${1}u64, ${2}u64)
    let w: u64 = sev_witness()
    if w == 0u64 { return 0u64 }
    let f: u32 = sev_frontier()
    return f as u64
}
EOF
  "$IIIS" "$W/_sev_a.iii" --compile-only --out "$W/_sev_a.o" >/dev/null 2>&1 || { echo 250; return; }
  gcc "$W/_sev_a.o" "$LIB" -lkernel32 -o "$W/_sev_a.exe" >/dev/null 2>&1 || { echo 251; return; }
  timeout 30 "$W/_sev_a.exe" >/dev/null 2>&1; echo $?
}
sev_field_rollback() {   # $1=verdict $2=rule_id  -> exit code: field_provenance (>=1 = field_rewound + retained)
  cat > "$W/_sev_r.iii" <<EOF
module sr
extern @abi(c-msvc-x64) fn sev_begin() -> i32 from "ser_eidos.iii"
extern @abi(c-msvc-x64) fn sev_reseal_record(verdict: u64, rule_id: u64) -> u64 from "ser_eidos.iii"
extern @abi(c-msvc-x64) fn sev_provenance() -> u32 from "ser_eidos.iii"
fn main() -> u64 {
    sev_begin()
    sev_reseal_record(${1}u64, ${2}u64)
    let p: u32 = sev_provenance()
    return p as u64
}
EOF
  "$IIIS" "$W/_sev_r.iii" --compile-only --out "$W/_sev_r.o" >/dev/null 2>&1 || { echo 250; return; }
  gcc "$W/_sev_r.o" "$LIB" -lkernel32 -o "$W/_sev_r.exe" >/dev/null 2>&1 || { echo 251; return; }
  timeout 30 "$W/_sev_r.exe" >/dev/null 2>&1; echo $?
}
# A REAL CIC-kernel refutation (cga_dispose on a FALSE candidate) driving a real field_rewind -- the SAFE-path
# rollback proof (the full STEP 5 below uses a real cor_selftest RED, which needs the rule-absent rebuild).
sev_field_rollback_kernel() {
  cat > "$W/_sev_rk.iii" <<EOF
module srk
extern @abi(c-msvc-x64) fn sev_begin() -> i32 from "ser_eidos.iii"
extern @abi(c-msvc-x64) fn sev_reseal_record(verdict: u64, rule_id: u64) -> u64 from "ser_eidos.iii"
extern @abi(c-msvc-x64) fn sev_provenance() -> u32 from "ser_eidos.iii"
extern @abi(c-msvc-x64) fn cga_dispose(a: u32, b: u32, budget: u32) -> u8 from "cg_autocatalyst.iii"
fn main() -> u64 {
    sev_begin()
    let mut v: u64 = 0u64
    if cga_dispose(3u32, 4u32, 64u32) == 1u8 { v = 99u64 }
    sev_reseal_record(v, 9u64)
    let p: u32 = sev_provenance()
    return p as u64
}
EOF
  "$IIIS" "$W/_sev_rk.iii" --compile-only --out "$W/_sev_rk.o" >/dev/null 2>&1 || { echo 250; return; }
  gcc "$W/_sev_rk.o" "$LIB" -lkernel32 -o "$W/_sev_rk.exe" >/dev/null 2>&1 || { echo 251; return; }
  timeout 30 "$W/_sev_rk.exe" >/dev/null 2>&1; echo $?
}
# SAFE eidos proof (real verdicts, no iiis rebuild, no committed mutation): exercises the SAME wire STEP 4/5 use.
reseal_eidos_proof() {
  hr; say "EIDOS PROOF -- the reseal decision witnessed on the REAL eidos/field (real verdicts, safe path)"
  local RC_ACC AWIT RPROV
  RC_ACC="$(gate_cor_selftest)"
  AWIT="$(sev_field_accept "$RC_ACC" 7)"
  say "  ACCEPT  : real cor_selftest=$RC_ACC -> eidos/field committed + witnessed (frontier=$AWIT)"
  RPROV="$(sev_field_rollback_kernel)"
  say "  ROLLBACK: real CIC-kernel REFUTE (cga_dispose 3,4) -> field_rewind, provenance=$RPROV (abandoned rule retained)"
  if [ "$AWIT" = "1" ] && [ "$RPROV" = "1" ]; then say "  EIDOS WIRE PROVEN on the real substrate (accept witnessed, rollback retained)."; return 0
  else say "  EIDOS WIRE FAILED (accept=$AWIT rollback=$RPROV)"; return 1; fi
}

# === FULL PIPELINE: collapse + intent + intuition + alignment, every organ load-bearing in ONE real fold =====
# svp_run evaluates a ser_pipeline expression and returns its value via the (8-bit) exit code.
svp_run() {
  cat > "$W/_svp.iii" <<EOF
module svpr
extern @abi(c-msvc-x64) fn svp_descriptor(v: u64) -> u32 from "ser_pipeline.iii"
extern @abi(c-msvc-x64) fn svp_form(packed: u32) -> u32 from "ser_pipeline.iii"
extern @abi(c-msvc-x64) fn svp_k(packed: u32) -> u32 from "ser_pipeline.iii"
extern @abi(c-msvc-x64) fn svp_pipeline(v: u64) -> u64 from "ser_pipeline.iii"
extern @abi(c-msvc-x64) fn svp_pipeline_rejects(v: u64) -> u8 from "ser_pipeline.iii"
extern @abi(c-msvc-x64) fn svp_autopoietic_wave() -> u64 from "ser_pipeline.iii"
fn main() -> u64 { return ${1} }
EOF
  "$IIIS" "$W/_svp.iii" --compile-only --out "$W/_svp.o" >/dev/null 2>&1 || { echo 250; return; }
  gcc "$W/_svp.o" "$LIB" -lkernel32 -o "$W/_svp.exe" >/dev/null 2>&1 || { echo 251; return; }
  timeout 90 "$W/_svp.exe" >/dev/null 2>&1; echo $?
}
# the COMPILER-CHOSEN emit rule for factor v (INTUITION/CEGIS): cg_synth form 2 = shift-sub = 'subk'.  Closes
# the descriptor seam -- the operator no longer hand-picks 'subk'; the synthesizer does.
synth_rule_for() {  # $1 = factor (decimal)
  local f; f="$(svp_run "svp_form(svp_descriptor(${1}u64)) as u64")"
  if [ "$f" = "2" ]; then echo "subk"; else echo ""; fi
}
reseal_pipeline_proof() {
  hr; say "FULL SERAPHYTE PIPELINE -- collapse + intent + intuition + alignment, each load-bearing (executed output)"
  local FORM K PIPE REJ RULE
  FORM="$(svp_run 'svp_form(svp_descriptor(7u64)) as u64')"
  K="$(svp_run 'svp_k(svp_descriptor(7u64)) as u64')"
  RULE="$(synth_rule_for 7)"
  say "  INTUITION (CEGIS)    : x*7 -> descriptor {form=$FORM, k=$K} -> emit rule '$RULE' -- the COMPILER chose (seam closed)"
  PIPE="$(svp_run 'svp_pipeline(7u64)')"
  say "  INTENT+COLLAPSE+ALIGN : svp_pipeline(7)=$PIPE  (intent merged on proof; cascade+fixpoint+regalloc collapsed; temporal safe+live; eidos committed)"
  REJ="$(svp_run 'svp_pipeline_rejects(11u64) as u64')"
  say "  NEGATIVE (x*11)      : svp_pipeline_rejects=$REJ  (no rewrite synthesized -> rolled back, provenance retained)"
  WAVE="$(svp_run 'svp_autopoietic_wave()')"
  say "  FIRST WAVE (2004-15) : svp_autopoietic_wave=$WAVE  (discover/optimize/commit + immune/memo/diff/isub + kvalue/energy/real/membrane/autopoiesis all discharge)"
  if [ "$FORM" = "2" ] && [ "$K" = "3" ] && [ "$PIPE" = "99" ] && [ "$REJ" = "1" ] && [ "$WAVE" = "99" ]; then
    say "  PIPELINE PROVEN: second-wave (collapse/intent/intuition/alignment) + first-wave (autopoietic loop) ALL load-bearing (executed)."; return 0
  else say "  PIPELINE FAILED (form=$FORM k=$K pipe=$PIPE rej=$REJ wave=$WAVE)"; return 1; fi
}
if [ "${1:-}" = "--pipeline" ]; then cd "$ROOT"; reseal_pipeline_proof; exit $?; fi

# safe entry: prove the eidos wire with real verdicts WITHOUT the heavy rule-absent rebuild
if [ "${1:-}" = "--eidos-proof" ]; then cd "$ROOT"; reseal_eidos_proof; exit $?; fi

cd "$ROOT"
hr; say "STEP 0 -- BASELINE (rule-absent): revert the 3 codegen files to the rule-absent ref ($BASELINE_REF), rebuild iiis-2"
git checkout "$BASELINE_REF" -- "${F3[@]}"
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
# DESCRIPTOR SEAM CLOSED: the CEGIS synthesizer (ser_pipeline -> ser_cegis) chooses WHICH rule to emit, not
# the operator.  cg_synth(7) -> form 2 (shift-sub) -> 'subk'.  INTUITION made load-bearing in the real wire.
PIPE_RULE="$(synth_rule_for 7)"; [ -n "$PIPE_RULE" ] || { say "  INTUITION: cg_synth did NOT pick a shift-sub for 7 -- aborting"; exit 2; }
say "  INTUITION (CEGIS): cg_synth(7) chose rule '$PIPE_RULE' -- the descriptor seam is closed (compiler, not operator)"
bash STDLIB/scripts/seraphyte_emit_rule.sh "$PIPE_RULE" 2>&1 | grep -E '^\[emit\]' | sed 's/^/  /'

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
  AWIT="$(sev_field_accept "$RC" 7)"
  say "  eidos/field: ACCEPT witnessed on the REAL substrate (committed frontier=$AWIT, non-zero temporal witness)"
else say "  DECISION: REJECT (gate not all-green) -- leaving emitted source for inspection"; exit 3; fi

hr; say "STEP 5 -- ROLLBACK teeth: emit an UNSOUND variant, prove the gate refuses + auto-revert byte-exact"
SOUND_SHA="$(sha256sum "$BOOT" | cut -d' ' -f1)"
git checkout "$BASELINE_REF" -- "${F3[@]}"                       # back to rule-absent (the baseline, NOT HEAD which now HAS the rule -- else the idempotent emitter skips the unsound emit)
bash STDLIB/scripts/seraphyte_emit_rule.sh subk 7 R3_STR_SUBQ subq unsound >/dev/null 2>&1   # over-admitting rule
rebuild_iiis2
RCU="$(gate_cor_selftest)"
if [ "$RCU" != "99" ]; then say "  GATE RED (cor_selftest=$RCU) -> ROLLBACK: the unsound (over-admit) rule is REFUSED."
  RPROV="$(sev_field_rollback "$RCU" 9)"; say "  eidos/field: ROLLBACK went through field_rewind (provenance=$RPROV retains the abandoned unsound rule)"
else say "  FAIL: unsound rule passed -- no teeth"; git checkout HEAD -- "${F3[@]}"; bash STDLIB/scripts/seraphyte_emit_rule.sh subk >/dev/null 2>&1; rebuild_iiis2; gate_cor_selftest >/dev/null; exit 4; fi
git checkout HEAD -- "${F3[@]}"; bash STDLIB/scripts/seraphyte_emit_rule.sh subk >/dev/null 2>&1   # revert + re-emit SOUND
rebuild_iiis2; RCR="$(gate_cor_selftest)"; REV_SHA="$(sha256sum "$BOOT" | cut -d' ' -f1)"
if [ "$SOUND_SHA" = "$REV_SHA" ] && [ "$RCR" = "99" ]; then say "  ROLLBACK VERIFIED: rule-table restored BYTE-EXACT (${REV_SHA:0:16}...) and re-greens (cor_selftest=99)."
else say "  ROLLBACK FAILED (sha=$([ "$SOUND_SHA" = "$REV_SHA" ] && echo ok || echo NO) re-gate=$RCR)"; exit 5; fi

hr; say "CLOSURE COMPLETE: gap discovered -> EMITTER wrote the rule -> machine gate ACCEPTED (fixpoint+cert)"
say "                  -> unsound variant ROLLED BACK byte-exact.  The compiler rewrote itself; no human in the loop."
hr; exit 0
