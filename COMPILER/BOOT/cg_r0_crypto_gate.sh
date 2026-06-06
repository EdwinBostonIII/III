#!/usr/bin/env bash
# cg_r0_crypto_gate.sh -- the Ring-0 backend (cg_r0) CORRECTNESS GATE.
#
# WHY THIS EXISTS (advisor 2026-06-04): the determinism/corpus gates (build_iiis2
# --check-corpus 59/0, run_corpus) exercise ONLY the default backend (cg_r3 / stage1).
# The Ring-0 codegen `cg_r0` (used by KATABASIS-DEPLOY kernel drivers) is UNGATED.
# A metal deploy of the M23 quine-seal gate surfaced that cg_r0 mis-compiles sha256
# (cg_r0 sha256("abc") != the FIPS-180-2 vector), which the gate's relative seal
# comparison masks but the quine-seal's ABSOLUTE FIPS check exposes -- the driver
# fail-closes (sc start error 31 = STATUS_UNSUCCESSFUL) instead of going resident.
#
# This gate is the structural fix for the bug CLASS: it compiles each crypto module
# through `--ring R0` (cg_r0) AND runs it against the FIPS/known-answer vector that
# the default backend (cg_r3, gated) already reproduces.  cg_r0 output that diverges
# from the known answer => GATE FAIL.  Non-golden-moving, fully in-session, III-alone
# (the harness only stubs the kernel witness leaf + the cpufeat CPUID shim -- it does
# NOT reimplement any III functionality; III's own cg_r0 emits the code under test).
#
# Exit 0 = every cg_r0 crypto KAT reproduces its known vector.  Nonzero = a cg_r0
# codegen defect (the Ring-0 backend would emit a wrong hash on metal).
set -u
cd "$(dirname "$0")/../.."                     # III root (script is in COMPILER/BOOT)
IIIS="${IIIS:-COMPILED/iiis-2.exe}"
W=/tmp/cg_r0_gate
mkdir -p "$W"
echo "[cg_r0-gate] compiler = $IIIS"

# --- the Ring-3 execution harness (stubs ONLY the kernel-only externs) ---
cat > "$W/harness.c" <<'EOF'
/* iii_witness_emit_kernel: the cg_r0 enter/exit instrumentation leaf (kernel: a
 * register-preserving no-op; here likewise).  L_p_cpufeat_*: the CPUID feature
 * probes -- forced to 0 so the gate exercises the SCALAR path (the path the kernel
 * driver forces via sha256_sched_force(1)/keccak_chi_force_path(1)). */
long long iii_witness_emit_kernel(long long a,long long b,long long c,long long d){return 0;}
unsigned char L_p_cpufeat_has_avx512f(void){return 0;}
unsigned char L_p_cpufeat_has_avx512dq(void){return 0;}
unsigned char L_p_cpufeat_has_sha(void){return 0;}
unsigned char L_p_cpufeat_has_avx2(void){return 0;}
unsigned char L_p_cpufeat_has_sse41(void){return 0;}
unsigned char L_p_cpufeat_has_aesni(void){return 0;}
unsigned char L_p_cpufeat_has_bmi2(void){return 0;}
EOF
gcc -c "$W/harness.c" -o "$W/harness.o" 2>/dev/null || { echo "[cg_r0-gate] FATAL: harness compile failed"; exit 2; }

FAIL=0
PASS=0

# probe <name> <module-path> <deps-space-list> <wrapper.iii-body returning u32 99=ok>
probe () {
    local name="$1" mod="$2" deps="$3" body="$4"
    cat > "$W/wrap.iii" <<EOF
module wrap
$body
EOF
    cat > "$W/main.iii" <<'EOF'
module gmain
extern @abi(c-msvc-x64) fn cg_r0_probe() -> u32 from "wrap.iii"
fn main() -> u64 { let r : u32 = cg_r0_probe()  if r == 99u32 { return 99u64 } return (r as u64) }
EOF
    # compile module + wrapper through cg_r0 (--ring R0); main through the default backend
    local objs="$W/wrap_r0.o $W/${name}_r0.o"
    "$IIIS" --ring R0 --compile-only --out "$W/wrap_r0.o" "$W/wrap.iii" 1>/dev/null 2>"$W/wrap.cerr" || { echo "[cg_r0-gate] $name: wrap --ring R0 FAILED:"; sed 's/^/      /' "$W/wrap.cerr" | head -6; FAIL=$((FAIL+1)); return; }
    "$IIIS" --ring R0 --compile-only --out "$W/${name}_r0.o" "$mod" >/dev/null 2>&1 || { echo "[cg_r0-gate] $name: module --ring R0 FAILED"; FAIL=$((FAIL+1)); return; }
    for d in $deps; do
        local dn=$(basename "$d" .iii)
        "$IIIS" --ring R0 --compile-only --out "$W/${dn}_r0.o" "$d" >/dev/null 2>&1 || { echo "[cg_r0-gate] $name: dep $dn --ring R0 FAILED"; FAIL=$((FAIL+1)); return; }
        objs="$objs $W/${dn}_r0.o"
    done
    "$IIIS" --compile-only --out "$W/main.o" "$W/main.iii" >/dev/null 2>&1 || { echo "[cg_r0-gate] $name: main FAILED"; FAIL=$((FAIL+1)); return; }
    gcc "$W/main.o" "$W/harness.o" $objs -Wl,--defsym,cg_r0_probe=L_p_cg_r0_probe -lkernel32 -o "$W/run_${name}.exe" 2>"$W/${name}.lerr" || { echo "[cg_r0-gate] $name: LINK FAILED"; sed 's/^/    /' "$W/${name}.lerr" | head -4; FAIL=$((FAIL+1)); return; }
    "$W/run_${name}.exe"; local rc=$?
    if [ $rc -eq 99 ]; then echo "[cg_r0-gate] PASS  $name (cg_r0 reproduces the known vector)"; PASS=$((PASS+1))
    else echo "[cg_r0-gate] FAIL  $name -> cg_r0 wrong at byte/code $rc (Ring-0 backend codegen defect)"; FAIL=$((FAIL+1)); fi
}

# --- sha256: cg_r0 sha256("abc") must equal FIPS-180-2 ba7816bf..f20015ad ---
probe sha256 STDLIB/iii/numera/sha256.iii "" '
extern @abi(c-msvc-x64) fn sha256_sched_force(p: u32) -> u32 from "sha256.iii"
extern @abi(c-msvc-x64) fn sha256_oneshot(msg: *u8, len: u64, out: *u8) -> u32 from "sha256.iii"
var IN : [u8; 4]
var OUT: [u8; 32]
var EXP: [u8; 32]
fn cg_r0_probe() -> u32 @export {
    sha256_sched_force(1u32)
    IN[0u64]=97u8 IN[1u64]=98u8 IN[2u64]=99u8
    EXP[0u64]=0xBAu8 EXP[1u64]=0x78u8 EXP[2u64]=0x16u8 EXP[3u64]=0xBFu8 EXP[4u64]=0x8Fu8 EXP[5u64]=0x01u8 EXP[6u64]=0xCFu8 EXP[7u64]=0xEAu8
    EXP[8u64]=0x41u8 EXP[9u64]=0x41u8 EXP[10u64]=0x40u8 EXP[11u64]=0xDEu8 EXP[12u64]=0x5Du8 EXP[13u64]=0xAEu8 EXP[14u64]=0x22u8 EXP[15u64]=0x23u8
    EXP[16u64]=0xB0u8 EXP[17u64]=0x03u8 EXP[18u64]=0x61u8 EXP[19u64]=0xA3u8 EXP[20u64]=0x96u8 EXP[21u64]=0x17u8 EXP[22u64]=0x7Au8 EXP[23u64]=0x9Cu8
    EXP[24u64]=0xB4u8 EXP[25u64]=0x10u8 EXP[26u64]=0xFFu8 EXP[27u64]=0x61u8 EXP[28u64]=0xF2u8 EXP[29u64]=0x00u8 EXP[30u64]=0x15u8 EXP[31u64]=0xADu8
    sha256_oneshot((&IN as u64) as *u8, 3u64, (&OUT as u64) as *u8)
    let mut i : u32 = 0u32
    while i < 32u32 { if OUT[i as u64] != EXP[i as u64] { return i + 1u32 } i = i + 1u32 }
    return 99u32
}'

# --- cad_oneshot_packed: cg_r0 SHA-256 of a BYTE-PACKED multi-block buffer must equal the NIST
#     56-byte vector (248d6a61..19db06c1).  This is the gap that BSOD'd 2026-06-04: the 1-block
#     slotted "abc" probe above passes even when byte-packed hashing over-reads 8x, because the
#     corruption only shows across block boundaries on NON-slotted input.  Absolute FIPS, not a
#     peer differential (cg_r3 shares index defects -> a differential agrees on a wrong answer). ---
probe cad_packed_fips STDLIB/iii/numera/cad.iii "STDLIB/iii/numera/sha256.iii STDLIB/iii/numera/sha256_dispatch.iii STDLIB/iii/numera/sha256_ni.iii STDLIB/iii/numera/keccak256.iii STDLIB/iii/numera/keccak.iii" '
extern @abi(c-msvc-x64) fn cad_oneshot_packed(suite: u32, msg: *u8, byte_len: u64, out: *u8) -> i32 from "cad.iii"
var OUT: [u8; 32]
var EXP: [u8; 32]
fn cg_r0_probe() -> u32 @export {
    EXP[0u64]=0x24u8 EXP[1u64]=0x8du8 EXP[2u64]=0x6au8 EXP[3u64]=0x61u8 EXP[4u64]=0xd2u8 EXP[5u64]=0x06u8 EXP[6u64]=0x38u8 EXP[7u64]=0xb8u8
    EXP[8u64]=0xe5u8 EXP[9u64]=0xc0u8 EXP[10u64]=0x26u8 EXP[11u64]=0x93u8 EXP[12u64]=0x0cu8 EXP[13u64]=0x3eu8 EXP[14u64]=0x60u8 EXP[15u64]=0x39u8
    EXP[16u64]=0xa3u8 EXP[17u64]=0x3cu8 EXP[18u64]=0xe4u8 EXP[19u64]=0x59u8 EXP[20u64]=0x64u8 EXP[21u64]=0xffu8 EXP[22u64]=0x21u8 EXP[23u64]=0x67u8
    EXP[24u64]=0xf6u8 EXP[25u64]=0xecu8 EXP[26u64]=0xedu8 EXP[27u64]=0xd4u8 EXP[28u64]=0x19u8 EXP[29u64]=0xdbu8 EXP[30u64]=0x06u8 EXP[31u64]=0xc1u8
    cad_oneshot_packed(0u32, "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" as *u8, 56u64, (&OUT as u64) as *u8)
    let mut i : u32 = 0u32
    while i < 32u32 { if OUT[i as u64] != EXP[i as u64] { return i + 1u32 } i = i + 1u32 }
    return 99u32
}'

# --- guard-page over-read: cad_oneshot_packed reading a page-sized byte-packed buffer must stay
#     within the buffer (a trailing PAGE_NOACCESS page faults the process if it over-reads).  This
#     is the exact mechanism of the BSOD (the .text self-measure walked off the image); zero-filled
#     VirtualAlloc memory means no cg_r0 byte-STORE is needed to set it up. ---
probe cad_packed_guard STDLIB/iii/numera/cad.iii "STDLIB/iii/numera/sha256.iii STDLIB/iii/numera/sha256_dispatch.iii STDLIB/iii/numera/sha256_ni.iii STDLIB/iii/numera/keccak256.iii STDLIB/iii/numera/keccak.iii" '
extern @abi(c-msvc-x64) fn cad_oneshot_packed(suite: u32, msg: *u8, byte_len: u64, out: *u8) -> i32 from "cad.iii"
extern @abi(c-msvc-x64) fn VirtualAlloc(addr: u64, size: u64, typ: u32, prot: u32) -> u64 from "kernel32"
extern @abi(c-msvc-x64) fn VirtualProtect(addr: u64, size: u64, newprot: u32, oldprot: u64) -> u32 from "kernel32"
var GOUT: [u8; 32]
var OLDP: [u32; 2]
fn cg_r0_probe() -> u32 @export {
    let buf : u64 = VirtualAlloc(0u64, 8192u64, 0x3000u32, 0x04u32)
    if buf == 0u64 { return 1u32 }
    VirtualProtect(buf + 4096u64, 4096u64, 0x01u32, (&OLDP as u64))
    cad_oneshot_packed(0u32, buf as *u8, 4096u64, (&GOUT as u64) as *u8)
    return 99u32
}'

# --- cad_oneshot_packed_bp: BYTE-PACKED OUTPUT must equal the NIST digest read byte-packed (4 u64s),
#     the way a cg_r3 challenger reads it.  WHY this and not cad_packed_fips: that probe compares the
#     SLOTTED out[i] to a SLOTTED EXP[i] -- both stride by 8 under cg_r0, so it passes even when the
#     digest is written one byte per u64 slot (sha256_final). That slotted output silently broke the
#     M23 cross-backend quine-seal (the Ring-0 driver shipped {d0,0x7,d1,0x7,...}; the Ring-3 client
#     read byte-packed and mismatched, 2026-06-04).  Reading the output as *u64 here is the
#     prove-the-negative: a regression to slotted output yields u64[0]=0x..00..00d0 != the packed
#     EXPW and the gate reddens. ---
probe cad_packed_bp_fips STDLIB/iii/numera/cad.iii "STDLIB/iii/numera/sha256.iii STDLIB/iii/numera/sha256_dispatch.iii STDLIB/iii/numera/sha256_ni.iii STDLIB/iii/numera/keccak256.iii STDLIB/iii/numera/keccak.iii" '
extern @abi(c-msvc-x64) fn cad_oneshot_packed_bp(suite: u32, msg: *u8, byte_len: u64, out: *u8) -> i32 from "cad.iii"
var OUT: [u8; 64]
var EXPW: [u64; 4]
fn cg_r0_probe() -> u32 @export {
    EXPW[0u64]=0xb83806d2616a8d24u64 EXPW[1u64]=0x39603e0c9326c0e5u64 EXPW[2u64]=0x6721ff6459e43ca3u64 EXPW[3u64]=0xc106db19d4edecf6u64
    cad_oneshot_packed_bp(0u32, "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" as *u8, 56u64, (&OUT as u64) as *u8)
    let mut q : u64 = 0u64
    while q < 4u64 { if (&OUT as *u64)[q] != EXPW[q] { return (q as u32) + 1u32 } q = q + 1u64 }
    return 99u32
}'

# --- cad_oneshot_packed_bp(KECCAK256): byte-packed keccak OUTPUT must equal keccak256("abc") read
#     byte-packed (4 u64s LE = 4e03657a...).  Prove-the-negative for the cg_r0 KECCAK ENGINE: the
#     _kk_load_lane/_kk_store_lane mixed-units defect gave a10df1f9 (every lane>0 shifted), so q=0
#     mismatched and this returns 1 -> the gate reddens. SHA-256 alone never exercised the keccak path. ---
probe cad_keccak_bp_fips STDLIB/iii/numera/cad.iii "STDLIB/iii/numera/sha256.iii STDLIB/iii/numera/sha256_dispatch.iii STDLIB/iii/numera/sha256_ni.iii STDLIB/iii/numera/keccak256.iii STDLIB/iii/numera/keccak.iii" '
extern @abi(c-msvc-x64) fn cad_oneshot_packed_bp(suite: u32, msg: *u8, byte_len: u64, out: *u8) -> i32 from "cad.iii"
var OUT: [u8; 64]
var EXPW: [u64; 4]
fn cg_r0_probe() -> u32 @export {
    EXPW[0u64]=0x4fa945ea7a65034eu64 EXPW[1u64]=0x67d6c826a87bd4c7u64 EXPW[2u64]=0x36a0643ae3e6d1c0u64 EXPW[3u64]=0x456c2da18ff544ecu64
    cad_oneshot_packed_bp(1u32, "abc" as *u8, 3u64, (&OUT as u64) as *u8)
    let mut q : u64 = 0u64
    while q < 4u64 { if (&OUT as *u64)[q] != EXPW[q] { return (q as u32) + 1u32 } q = q + 1u64 }
    return 99u32
}'

echo "[cg_r0-gate] PASS=$PASS FAIL=$FAIL"
if [ $FAIL -ne 0 ]; then echo "[cg_r0-gate] GATE FAIL -- the Ring-0 backend mis-compiles crypto; no kernel crypto driver is trustworthy until fixed."; exit 1; fi
echo "[cg_r0-gate] GATE PASS"
exit 0
