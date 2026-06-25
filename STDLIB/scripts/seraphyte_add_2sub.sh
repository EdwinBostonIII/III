#!/usr/bin/env bash
# seraphyte_add_2sub.sh -- AUTONOMOUS addition of the 2-SHIFT-SUBTRACT rule (x*(2^j-2^m) -> (x<<j)-(x<<m)),
# the REUSE of the 2-shift-add spine: BASELINE(x*14=imul) -> PROVE(bv_ring) -> EMIT(emitter) -> REBUILD ->
# EMISSION CHECK (x*14 -> two shifts + sub; the other rules UNCHANGED) -> FULLY-FUNCTIONAL (run x*v over
# random + overflow edges vs an IMUL reference) -> FIXPOINT -> CERT -> ACCEPT | ROLLBACK byte-exact.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
F3=(COMPILER/BOOT/cg_opt_rules.iii COMPILER/BOOT/cg_r3.iii COMPILER/BOOT/cg_r3.c)
W="$ROOT/STDLIB/build/_add2sub"; mkdir -p "$W"
say(){ printf '[add2sub] %s\n' "$*"; }
hr(){  printf '%s\n' "------------------------------------------------------------"; }
rebuild_iiis2(){ rm -f "$IIIS" 2>/dev/null; ( cd "$ROOT" && bash COMPILER/BOOT/build_iiis2.sh ) >/dev/null 2>&1; }
emit_xv(){ printf 'module p\nfn f(x: u64) -> u64 { return x * %su64 }\nfn main() -> u64 { return f(1u64) }\n' "$1" > "$W/_x.iii"
           "$IIIS" "$W/_x.iii" --compile-only --out "$W/_x.o" >/dev/null 2>&1
           objdump -d "$W/_x.o" 2>/dev/null | grep -iE 'imul|shl|sal|add[[:space:]]+%rcx|sub[[:space:]]+%rcx' | grep -oE 'imul|shl|sub|add' | tr '\n' ' '; }
update_archive(){ "$IIIS" "$ROOT/STDLIB/iii/forcefield/cg_opt_rules.iii" --compile-only --out "$W/_ff.o" >/dev/null 2>&1
                  "$IIIS" "$ROOT/COMPILER/BOOT/cg_opt_rules.iii" --compile-only --out "$W/_boot.o" >/dev/null 2>&1
                  cp "$W/_ff.o" "$W/forcefield_cg_opt_rules.iii.o"; cp "$W/_boot.o" "$W/boot_cg_opt_rules.iii.o"
                  ar r "$LIB" "$W/forcefield_cg_opt_rules.iii.o" "$W/boot_cg_opt_rules.iii.o" >/dev/null 2>&1; }
gate_cor_selftest(){ update_archive
  printf 'module d\nextern @abi(c-msvc-x64) fn cor_selftest() -> u64 from "cg_opt_rules.iii"\nfn main() -> u64 { return cor_selftest() }\n' > "$W/_gd.iii"
  "$IIIS" "$W/_gd.iii" --compile-only --out "$W/_gd.o" >/dev/null 2>&1 || { echo 254; return; }
  gcc "$W/_gd.o" "$LIB" -lkernel32 -o "$W/_gd.exe" >/dev/null 2>&1 || { echo 253; return; }
  timeout 120 "$W/_gd.exe" >/dev/null 2>&1; echo $?; }
run_fully_functional(){
  cat > "$W/_ff_test.iii" <<'EOF'
module fft
var MULS : [u64; 6] = [14u64, 28u64, 30u64, 56u64, 60u64, 1022u64]
fn ref(x: u64, i: u64) -> u64 { return x * MULS[i] }   /* x * (memory load) -> imul reference */
fn chk(x: u64) -> u32 {
    if (x * 14u64)   != ref(x, 0u64) { return 1u32 }
    if (x * 28u64)   != ref(x, 1u64) { return 2u32 }
    if (x * 30u64)   != ref(x, 2u64) { return 3u32 }
    if (x * 56u64)   != ref(x, 3u64) { return 4u32 }
    if (x * 60u64)   != ref(x, 4u64) { return 5u32 }
    if (x * 1022u64) != ref(x, 5u64) { return 6u32 }    /* 1024-2 = 2^10-2^1, a long run */
    return 0u32
}
fn main() -> u64 {
    if chk(0u64) != 0u32 { return 1u64 }
    if chk(1u64) != 0u32 { return 2u64 }
    if chk(3u64) != 0u32 { return 3u64 }
    if chk(123456789u64) != 0u32 { return 4u64 }
    if chk(9999999999u64) != 0u32 { return 5u64 }
    if chk(2305843009213693952u64) != 0u32 { return 6u64 }   /* 2^61 */
    if chk(9223372036854775808u64) != 0u32 { return 7u64 }   /* 2^63 */
    if chk(18446744073709551615u64) != 0u32 { return 8u64 }  /* 2^64-1 */
    if chk(13835058055282163712u64) != 0u32 { return 9u64 }  /* 3*2^62 wraps */
    return 99u64
}
EOF
  "$IIIS" "$W/_ff_test.iii" --compile-only --out "$W/_ff_test.o" >/dev/null 2>&1 || { echo 250; return; }
  gcc "$W/_ff_test.o" "$LIB" -lkernel32 -o "$W/_ff_test.exe" >/dev/null 2>&1 || { echo 251; return; }
  timeout 60 "$W/_ff_test.exe" >/dev/null 2>&1; echo $?; }

cd "$ROOT"
hr; say "STEP 0 -- BASELINE (2ss-absent): x*14 should be 'imul' and the rule predicate must be absent"
[ "$(grep -c cgopt_mul_2ss_admit COMPILER/BOOT/cg_opt_rules.iii)" = "0" ] || { say "FAIL: rule already present"; exit 1; }
BASE14="$(emit_xv 14)"
printf '%s' "$BASE14" | grep -qi imul || { say "FAIL: baseline x*14 not imul ($BASE14)"; exit 1; }
say "  baseline: x*14 -> $BASE14 (imul)"

hr; say "STEP 1 -- PROVE (bv_ring): (x<<j)-(x<<m) == v*x for the run family"
cat > "$W/_prove.iii" <<'EOF'
module pr
extern @abi(c-msvc-x64) fn bv_reset() -> i32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_var(v: u32) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_const(c: u64) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_sub(a: u32, b: u32) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_mul(a: u32, b: u32) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_shl(a: u32, k: u32) -> u32 from "bv_ring.iii"
extern @abi(c-msvc-x64) fn bv_equal(a: u32, b: u32) -> u8 from "bv_ring.iii"
fn pv(j: u32, m: u32, v: u64) -> u8 { bv_reset() let x: u32 = bv_var(0u32) return bv_equal(bv_sub(bv_shl(x,j), bv_shl(x,m)), bv_mul(x, bv_const(v))) }
fn main() -> u64 {
    if pv(4u32,1u32,14u64) != 1u8 { return 1u64 }
    if pv(5u32,2u32,28u64) != 1u8 { return 2u64 }
    if pv(5u32,1u32,30u64) != 1u8 { return 3u64 }
    if pv(6u32,3u32,56u64) != 1u8 { return 4u64 }
    if pv(10u32,1u32,1022u64) != 1u8 { return 5u64 }
    if pv(4u32,1u32,28u64) == 1u8 { return 6u64 }
    return 99u64
}
EOF
"$IIIS" "$W/_prove.iii" --compile-only --out "$W/_prove.o" >/dev/null 2>&1
gcc "$W/_prove.o" "$LIB" -lkernel32 -o "$W/_prove.exe" >/dev/null 2>&1
timeout 60 "$W/_prove.exe" >/dev/null 2>&1; PR=$?
[ "$PR" = "99" ] && say "  PROVEN (bv_ring): the 2-shift-sub identity holds; wrong decomposition refuted." || { say "FAIL: proof rc=$PR"; exit 1; }

hr; say "STEP 2 -- EMIT: the 2-shift-sub patch-emitter writes the rule (no human)"
bash STDLIB/scripts/seraphyte_emit_2sub.sh 2>&1 | grep -E '^\[emit2sub\]' | sed 's/^/  /'

hr; say "STEP 3 -- REBUILD iiis-2 with the emitted rule"
rebuild_iiis2
[ -x "$IIIS" ] || { say "FAIL: iiis-2 did not rebuild"; git checkout HEAD -- "${F3[@]}"; exit 2; }

hr; say "STEP 4 -- EMISSION CHECK: x*{14,28,30,56,60} -> two shifts + sub; 2-add/subk/shladd/pow2 UNCHANGED"
ok=1
for v in 14 28 30 56 60; do a="$(emit_xv $v)"; printf '%s' "$a" | grep -qi imul && { say "  x*$v still imul ($a) -- FAIL"; ok=0; }
  printf '%s' "$a" | grep -qi sub || { say "  x*$v no sub ($a) -- FAIL"; ok=0; }; done
R10="$(emit_xv 10)"; printf '%s' "$R10" | grep -qi add || { say "  REGRESSION x*10 lost 2-shift-add ($R10)"; ok=0; }
R7="$(emit_xv 7)";   printf '%s' "$R7"  | grep -qi sub || { say "  REGRESSION x*7 lost subk ($R7)"; ok=0; }
R8="$(emit_xv 8)";   printf '%s' "$R8"  | grep -qi shl || { say "  REGRESSION x*8 lost pow2 ($R8)"; ok=0; }
if [ "$ok" = "1" ]; then say "  x*14 -> $(emit_xv 14); x*10 -> $R10 (2-add); x*7 -> $R7 (subk); x*8 -> $R8 (pow2) -- all correct"
else say "  EMISSION CHECK FAILED -> ROLLBACK"; git checkout HEAD -- "${F3[@]}"; rebuild_iiis2; exit 3; fi

hr; say "STEP 5 -- FULLY-FUNCTIONAL: run the emitted x*v over random + overflow edges vs an IMUL reference"
FF="$(run_fully_functional)"
[ "$FF" = "99" ] && say "  VALUE PROVEN: x*{14,28,30,56,60,1022} == v*x on the overflow edges (matches imul reference)" \
  || { say "  FULLY-FUNCTIONAL FAILED rc=$FF -> ROLLBACK"; git checkout HEAD -- "${F3[@]}"; rebuild_iiis2; exit 4; }

hr; say "STEP 6 -- FIXPOINT + CERT"
update_archive
rm -f COMPILED/iiis-3.exe 2>/dev/null
FIX="$( ( cd "$ROOT" && bash COMPILER/BOOT/build_iiis3.sh --check-corpus ) 2>&1 | grep -oE '[0-9]+ passed, [0-9]+ failed' | tail -1 )"
RC="$(gate_cor_selftest)"
say "  self-host fixpoint iiis-2==iiis-3 : $FIX"
say "  multi-engine certifier cor_selftest : $RC"
if [ "$FIX" = "59 passed, 0 failed" ] && [ "$RC" = "99" ]; then
  hr; say "DECISION: ACCEPT -- cg_r3 GAINED a SECOND emitter-produced family (2-shift-sub).  The loop KEEPS producing."
  hr; exit 0
else say "  GATE not all-green (fixpoint=$FIX cert=$RC) -> ROLLBACK byte-exact"; git checkout HEAD -- "${F3[@]}"; rebuild_iiis2; gate_cor_selftest >/dev/null; exit 5; fi
