#!/usr/bin/env bash
# KATABASIS Tier-1 Gate .sys build - deterministic, NIH per ADR-021 (gcc/ld/as host tools).
#
#   gate_driver.iii  --(cg_r0 via iiis-2)-->  gate.s  --(as)-->  gate.o  --.
#   witness_kernel.s --(as)----------------------------------> witness_kernel.o -+-> gate.sys
#
# Produces a PE32+ NT-native kernel image: entry=DriverEntry, relocatable, no imports,
# no exports, no CRT, bit-identical across builds. Verify with verify_gate_sys.sh.
set -euo pipefail
export SOURCE_DATE_EPOCH=0 LC_ALL=C TZ=UTC0   # reproducible build env
cd "$(dirname "$0")/.."                       # III root
IIIS=COMPILED/iiis-2.exe
S=KATABASIS-DEPLOY/src
B=KATABASIS-DEPLOY/build
mkdir -p "$B"

echo "[1/4] emit Ring-0 asm (cg_r0)"
"./$IIIS" "$S/gate_driver.iii" --ring R0 --emit-asm-only --out "$B/gate"

echo "[2/4] assemble gate.o"
gcc -c -x assembler -o "$B/gate.o" "$B/gate.s"

echo "[3/4] assemble witness_kernel.o (hand-written kernel witness leaf)"
gcc -c -x assembler -o "$B/witness_kernel.o" "$S/witness_kernel.s"

echo "[4/4] link gate.sys (PE32+ native, entry=DriverEntry, deterministic)"
gcc -mabi=ms -ffreestanding -shared -nostdlib \
    -Wl,--subsystem,native \
    -Wl,-e,DriverEntry \
    -Wl,--exclude-all-symbols \
    -Wl,--disable-runtime-pseudo-reloc \
    -Wl,--image-base,0x140000000 \
    -Wl,--disable-high-entropy-va \
    -Wl,--no-insert-timestamp \
    -Wl,--dynamicbase -Wl,--nxcompat \
    -o "$B/gate.sys" "$B/gate.o" "$B/witness_kernel.o"

sha256sum "$B/gate.sys"
echo "OK -> $B/gate.sys"
