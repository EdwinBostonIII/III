#!/usr/bin/env bash
# cg_seam_gate.sh -- the BACKEND ELEMENT-MODEL SEAM conformance gate (DIFFERENTIAL).
#
# Architecture-review R1 (DOCS/III-ARCHITECTURE-REVIEW.md): the single largest recurring defect source is
# the seam between cg_r3 (byte-packed) and cg_r0 (8-byte-uniform) -- identical .iii source that compiles
# correctly under one backend's element model and silently corrupts under the other. Rounds 1-3 found 10+
# such defects BY AUDIT. This gate makes the class FOUND-BY-CI: every probe is a canonical seam idiom
# (each a KNOWN past-defect shape), compiled through `--ring R0` (cg_r0) AND the default backend (cg_r3,
# correct), run in the Ring-3 harness, and their XOR-fold outputs compared. cg_r0 != cg_r3 ⇒ FAIL.
#
# It generalises cg_r0_width_gate.sh (u32 width) + cg_r0_crypto_gate.sh (crypto vectors) to the full seam:
#   SIGNEDNESS sub-class -- u64/i64/u32 ordering straddling the sign boundary; signed/unsigned narrowing casts.
#   ELEMENT-MODEL sub-class -- [u64]/[u8]/[u32] array write/read round-trips (incl. the keccak-state SIZING
#   shape: a fully-written/read [u8;N] array -- an undersized array OOBs on cg_r0 -> crash -> differential).
# Each probe is prove-the-negative by construction: the PRE-FIX backend diverged (u64-ord: cg_r0 was 1 vs 99;
# cast_i8: cg_r3 was 1 vs 99 -- both verified this session). Compile/link failures are guarded -> never vacuous.
#
# Exit 0 = cg_r0 matches cg_r3 on every seam idiom.  Nonzero = a backend element-model seam defect.
# Usage: cg_seam_gate.sh [path-to-iiis-2]   (or IIIS=... env)
set -u
cd "$(dirname "$0")/../.."                     # III root (script is in COMPILER/BOOT)
IIIS="${1:-${IIIS:-COMPILED/iiis-2.exe}}"
W=/tmp/cg_seam_gate
mkdir -p "$W"
echo "[cg-seam] compiler = $IIIS"
[ -x "$IIIS" ] || { echo "[cg-seam] FATAL: no compiler at $IIIS"; exit 2; }
command -v gcc >/dev/null 2>&1 || { echo "[cg-seam] SKIP: no gcc"; exit 0; }

cat > "$W/harness.c" <<'EOF'
long long iii_witness_emit_kernel(long long a,long long b,long long c,long long d){return 0;}
unsigned char L_p_cpufeat_has_avx512f(void){return 0;}
unsigned char L_p_cpufeat_has_avx512dq(void){return 0;}
unsigned char L_p_cpufeat_has_sha(void){return 0;}
unsigned char L_p_cpufeat_has_avx2(void){return 0;}
unsigned char L_p_cpufeat_has_sse41(void){return 0;}
unsigned char L_p_cpufeat_has_aesni(void){return 0;}
unsigned char L_p_cpufeat_has_bmi2(void){return 0;}
EOF
gcc -c "$W/harness.c" -o "$W/harness.o" 2>/dev/null || { echo "[cg-seam] FATAL harness"; exit 2; }
cat > "$W/m.iii" <<'EOF'
module m
extern @abi(c-msvc-x64) fn probe() -> u32 from "p.iii"
fn main() -> u64 { let v : u32 = probe()  return (((v >> 24u32) ^ (v >> 16u32) ^ (v >> 8u32) ^ v) & 0xFFu32) as u64 }
EOF
"$IIIS" --compile-only --out "$W/m.o" "$W/m.iii" 2>/dev/null || { echo "[cg-seam] FATAL m.iii compile"; exit 2; }

PASS=0; FAIL=0
sp () {  # name  body   -- differential cg_r0 vs cg_r3; EVERY compile/link guarded (no vacuous PASS)
    printf 'module p\n%s\n' "$2" > "$W/p.iii"
    "$IIIS" --ring R0 --compile-only --out "$W/p_r0.o" "$W/p.iii" 2>/dev/null || { echo "[cg-seam] FAIL  $1 (cg_r0 compile)"; FAIL=$((FAIL+1)); return; }
    gcc "$W/m.o" "$W/harness.o" "$W/p_r0.o" -Wl,--defsym,probe=L_p_probe -lkernel32 -o "$W/r0.exe" 2>/dev/null || { echo "[cg-seam] FAIL  $1 (cg_r0 link)"; FAIL=$((FAIL+1)); return; }
    "$W/r0.exe"; local r0=$?
    "$IIIS" --compile-only --out "$W/p_def.o" "$W/p.iii" 2>/dev/null || { echo "[cg-seam] FAIL  $1 (cg_r3 compile)"; FAIL=$((FAIL+1)); return; }
    gcc "$W/m.o" "$W/p_def.o" -lkernel32 -o "$W/def.exe" 2>/dev/null || { echo "[cg-seam] FAIL  $1 (cg_r3 link)"; FAIL=$((FAIL+1)); return; }
    "$W/def.exe"; local def=$?
    if [ "$r0" -eq "$def" ]; then echo "[cg-seam] PASS  $1 (cg_r0==cg_r3 fold=$r0)"; PASS=$((PASS+1))
    else echo "[cg-seam] FAIL  $1 -> cg_r0=$r0 cg_r3=$def   <== backend element-model SEAM defect"; FAIL=$((FAIL+1)); fi
}

# --- SIGNEDNESS sub-class (ordering must derive from operand TYPE, identically across backends) ---
sp ord_u64_bit63  'fn probe()->u32 @export { let a:u64=0x8000000000000001u64  let b:u64=2u64  if a > b { return 99u32 }  return 1u32 }'
sp ord_u64_lt63   'fn probe()->u32 @export { let a:u64=0x8000000000000001u64  let b:u64=2u64  if a < b { return 1u32 }  return 99u32 }'
sp ord_i64_neg    'fn probe()->u32 @export { let a:i64=0i64-1i64  let b:i64=2i64  if a > b { return 1u32 }  return 99u32 }'
sp ord_u32_bit31  'fn probe()->u32 @export { let a:u32=0x80000001u32  let b:u32=2u32  if a > b { return 99u32 }  return 1u32 }'
# Narrowing-cast truncation: K3 fixed cg_r0's EXPR_CAST pass-through -> it now truncates sub-word targets
# like cg_r3 (`456 as u8` = 200, not 456). Gated as RAW cross-backend differential (return the cast result,
# no semantic assertion -- the gate asserts only cg_r0 == cg_r3, not which value is "right").
sp cast_u8_trunc  'fn probe()->u32 @export { return (456u64 as u8 as u64) as u32 }'
sp cast_u16_trunc 'fn probe()->u32 @export { return (70000u64 as u16 as u64) as u32 }'
sp cast_u32_trunc 'fn probe()->u32 @export { let x:u64=0x100000001u64  return (x as u32 as u64) as u32 }'
sp cast_i8_uni    'fn probe()->u32 @export { return (456u64 as i8 as u64) as u32 }'

# --- ELEMENT-MODEL sub-class (array element access must round-trip identically under both layouts) ---
sp arr_u64_elem   'var Q:[u64;5] fn probe()->u32 @export { let mut i:u32=0u32  while i<5u32 { Q[i as u64]=(i as u64)*0x1111u64+7u64  i=i+1u32 }  let mut s:u64=0u64  let mut j:u32=0u32  while j<5u32 { s=s+Q[j as u64]  j=j+1u32 }  return (s & 0xFFFFu64) as u32 }'
sp arr_u8_full    'var Bf:[u8;40] fn probe()->u32 @export { let mut i:u32=0u32  while i<40u32 { Bf[i as u64]=((i*7u32) & 0xFFu32) as u8  i=i+1u32 }  let mut s:u32=0u32  let mut j:u32=0u32  while j<40u32 { s=s+(Bf[j as u64] as u32)  j=j+1u32 }  return s & 0xFFFFu32 }'
sp arr_u32_elem   'var Wf:[u32;6] fn probe()->u32 @export { let mut i:u32=0u32  while i<6u32 { Wf[i as u64]=0xFFFFFF00u32+(i*0x40u32)  i=i+1u32 }  let mut s:u32=0u32  let mut j:u32=0u32  while j<6u32 { s=s^Wf[j as u64]  j=j+1u32 }  return s & 0xFFFFu32 }'

echo "[cg-seam] PASS=$PASS FAIL=$FAIL"
if [ $FAIL -ne 0 ]; then echo "[cg-seam] GATE FAIL -- backend element-model seam diverges on $FAIL idiom(s)."; exit 1; fi
echo "[cg-seam] GATE PASS -- cg_r0 element-model == cg_r3 on every seam idiom (signedness + element-model)."
exit 0
