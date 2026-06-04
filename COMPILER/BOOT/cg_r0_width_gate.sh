#!/usr/bin/env bash
# cg_r0_width_gate.sh -- the Ring-0 backend u32-WIDTH correctness gate (differential).
#
# Companion to cg_r0_crypto_gate.sh (which is the sha256 ABSOLUTE gate). This gate is
# DIFFERENTIAL: each probe is compiled through `--ring R0` (cg_r0) AND the default backend
# (cg_r3, gated/correct), run in the Ring-3 harness, and their XOR-fold outputs compared.
# cg_r0 != cg_r3 ⇒ FAIL.  It targets the u32-width defect (cg_r0 was 8-byte-uniform: a u32
# value carrying bit-32 garbage -- a wrap carry or a left-shifted bit -- read by a width-
# sensitive op gives the wrong answer).  shift-right is NOT the only such op: unsigned
# compare, div, and mod also read the high bits -- all are probed so a "shr-only" patch
# cannot pass dishonestly.  Each probe deliberately FEEDS BACK a wrapping value so the high
# half is dirty (literals would be clean and hide the bug).
#
# Exit 0 = cg_r0 matches cg_r3 on every width case.  Nonzero = a cg_r0 width defect.
set -u
cd "$(dirname "$0")/../.."                     # III root (script is in COMPILER/BOOT)
IIIS="${IIIS:-COMPILED/iiis-2.exe}"
W=/tmp/cg_r0_wgate
mkdir -p "$W"
echo "[cg_r0-wgate] compiler = $IIIS"

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
gcc -c "$W/harness.c" -o "$W/harness.o" 2>/dev/null || { echo "[cg_r0-wgate] FATAL harness"; exit 2; }
cat > "$W/m.iii" <<'EOF'
module m
extern @abi(c-msvc-x64) fn probe() -> u32 from "p.iii"
fn main() -> u64 { let v : u32 = probe()  return (((v >> 24u32) ^ (v >> 16u32) ^ (v >> 8u32) ^ v) & 0xFFu32) as u64 }
EOF
"$IIIS" --compile-only --out "$W/m.o" "$W/m.iii" 2>/dev/null || { echo "[cg_r0-wgate] FATAL m.iii compile"; exit 2; }

PASS=0; FAIL=0
dp () {  # name  body
    printf 'module p\n%s\n' "$2" > "$W/p.iii"
    # Guard EVERY compile/link: a build failure must FAIL the probe, never produce a vacuous PASS.
    # Without these guards, both exes are absent, both run as 127, 127==127 -> false "PASS".
    "$IIIS" --ring R0 --compile-only --out "$W/p_r0.o" "$W/p.iii" 2>/dev/null || { echo "[cg_r0-wgate] FAIL  $1 (cg_r0 compile)"; FAIL=$((FAIL+1)); return; }
    gcc "$W/m.o" "$W/harness.o" "$W/p_r0.o" -Wl,--defsym,probe=L_p_probe -lkernel32 -o "$W/r0.exe" 2>/dev/null || { echo "[cg_r0-wgate] FAIL  $1 (cg_r0 link)"; FAIL=$((FAIL+1)); return; }
    "$W/r0.exe"; local r0=$?
    "$IIIS" --compile-only --out "$W/p_def.o" "$W/p.iii" 2>/dev/null || { echo "[cg_r0-wgate] FAIL  $1 (cg_r3 compile)"; FAIL=$((FAIL+1)); return; }
    gcc "$W/m.o" "$W/p_def.o" -lkernel32 -o "$W/def.exe" 2>/dev/null || { echo "[cg_r0-wgate] FAIL  $1 (cg_r3 link)"; FAIL=$((FAIL+1)); return; }
    "$W/def.exe"; local def=$?
    if [ "$r0" -eq "$def" ]; then echo "[cg_r0-wgate] PASS  $1 (cg_r0==cg_r3 fold=$r0)"; PASS=$((PASS+1))
    else echo "[cg_r0-wgate] FAIL  $1 -> cg_r0=$r0 cg_r3=$def   <== cg_r0 u32-width defect"; FAIL=$((FAIL+1)); fi
}

# every probe FEEDS BACK a wrapping value (0xFFFFFFF0 + 0x20 = 0x10 with a bit-32 carry) so the
# high half is dirty; a correct backend truncates to 32 bits, cg_r0-uniform did not.
dp dirty_shr        'fn probe()->u32 @export { let x:u32=0xFFFFFFF0u32+0x20u32  return x >> 4u32 }'
dp dirty_shl_shr    'fn probe()->u32 @export { let x:u32=0xFFFFFFF0u32+0x20u32  let y:u32=x << 8u32  return y >> 8u32 }'
dp inline_add_shr   'fn probe()->u32 @export { let a:u32=0xFFFFFFF0u32  let b:u32=0x20u32  return (a + b) >> 4u32 }'
dp store_reload_shr 'var S:[u32;4] fn probe()->u32 @export { S[0u64]=0xFFFFFFF0u32+0x20u32  let x:u32=S[0u64]  return x >> 4u32 }'
dp arr_elem_shr     'var A:[u32;4] fn probe()->u32 @export { let mut i:u32=0u32 while i<4u32 { A[i as u64]=0xFFFFFF00u32+(i*0x40u32) i=i+1u32 } return A[3u64] >> 4u32 }'
dp dirty_ult        'fn probe()->u32 @export { let x:u32=0xFFFFFFF0u32+0x20u32  if x < 0x100u32 { return 1u32 }  return 2u32 }'
dp dirty_ule        'fn probe()->u32 @export { let x:u32=0xFFFFFFF0u32+0x20u32  if x <= 0x10u32 { return 1u32 }  return 2u32 }'
dp dirty_div        'fn probe()->u32 @export { let x:u32=0xFFFFFFF0u32+0x20u32  return x / 0x4u32 }'
dp dirty_mod        'fn probe()->u32 @export { let x:u32=0xFFFFFFF0u32+0x20u32  return x % 0x7u32 }'
dp dirty_gt         'fn probe()->u32 @export { let x:u32=0xFFFFFFF0u32+0x20u32  if x > 0x1000u32 { return 1u32 }  return 2u32 }'

echo "[cg_r0-wgate] PASS=$PASS FAIL=$FAIL"
if [ $FAIL -ne 0 ]; then echo "[cg_r0-wgate] GATE FAIL -- cg_r0 mishandles u32 width on $FAIL op(s)."; exit 1; fi
echo "[cg_r0-wgate] GATE PASS -- cg_r0 u32 width == cg_r3 on every probed op."
exit 0
