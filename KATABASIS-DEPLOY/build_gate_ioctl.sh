#!/usr/bin/env bash
# KATABASIS Tier-3 R3-invokable IOCTL gate - deterministic build (NIH per ADR-021 + mingw libntoskrnl.a).
#
# The full pure-.iii gate-admit closure (cg_r0-compiled) + the IOCTL driver + the witness leaf +
# the hand-asm ntoskrnl marshalling shims, linked into a PE32+ NT-native driver. Unlike the Tier-2
# selftest (which self-unloads), this STAYS RESIDENT and serves DeviceIoControl from Ring 3.
set -euo pipefail
export SOURCE_DATE_EPOCH=0 LC_ALL=C TZ=UTC0
cd "$(dirname "$0")/.."                       # III root
IIIS=COMPILED/iiis-2.exe
S=KATABASIS-DEPLOY/src
B=KATABASIS-DEPLOY/build
O=$B/obj
mkdir -p "$O"

# gate-admit dependency closure, leaves first.  Repaired for the post-Jun-6 stdlib drift: content_addr was folded
# into numera/cad (dead here); the closure grew trit (hexad_algebra) + quine_seal (M23 attest) + the wvb_* helpers
# (sha256/keccak).  Kernel-INCOMPATIBLE deps are replaced by cg_r0-safe subsets compiled below (NOT listed here):
#   numera/weave_blocks -> weave_blocks_kernel (its wvb_arx_mix has 10 params, > cg_r0's 4); numera/cad ->
#   cad_kernel (cad routes through sha256_dispatch -> cpufeat -> kernel32, illegal in R0).  pci_enum = the new
#   live PCI-config deriver for census's GPU facts.
MODS=(
  omnia/hexad_algebra omnia/hexad_pfs omnia/hexad_reach omnia/xii_term
  numera/trit numera/sha256 numera/keccak256 numera/keccak
  aether/capability
  katabasis/svm_layout katabasis/bar_layout katabasis/cycle_family
  katabasis/cycle_admit katabasis/cycle_term katabasis/seal katabasis/caps
  katabasis/quine_seal katabasis/gate_verdict katabasis/gate katabasis/admit
  katabasis/pci_enum
)

echo "[1] cg_r0 -> .o : IOCTL driver + kernel-safe subsets (cpufeat/weave_blocks/cad) + ${#MODS[@]} closure modules"
"./$IIIS" "$S/gate_driver.iii"   --ring R0 --compile-only --out "$O/gate_driver.o"
"./$IIIS" "$S/cpufeat_kernel.iii" --ring R0 --compile-only --out "$O/cpufeat_kernel.o"
"./$IIIS" "$S/weave_blocks_kernel.iii" --ring R0 --compile-only --out "$O/weave_blocks_kernel.o"
"./$IIIS" "$S/cad_kernel.iii" --ring R0 --compile-only --out "$O/cad_kernel.o"
OBJS=("$O/gate_driver.o" "$O/cpufeat_kernel.o" "$O/weave_blocks_kernel.o" "$O/cad_kernel.o")
for m in "${MODS[@]}"; do n=$(basename "$m"); "./$IIIS" "STDLIB/iii/$m.iii" --ring R0 --compile-only --out "$O/$n.o"; OBJS+=("$O/$n.o"); done

echo "[2] assemble kernel witness leaf + hand-asm ntoskrnl marshalling shims"
gcc -c -x assembler -o "$O/witness_kernel.o" "$S/witness_kernel.s"; OBJS+=("$O/witness_kernel.o")
gcc -c -x assembler -o "$O/kernel_abi.o"     "$S/kernel_abi.s";     OBJS+=("$O/kernel_abi.o")

echo "[3] link gate_ioctl.sys (PE32+ native, entry=DriverEntry, ntoskrnl imports, deterministic)"
gcc -mabi=ms -ffreestanding -shared -nostdlib \
    -Wl,--subsystem,native -Wl,-e,DriverEntry -Wl,--exclude-all-symbols \
    -Wl,--disable-runtime-pseudo-reloc -Wl,--image-base,0x140000000 \
    -Wl,--disable-high-entropy-va -Wl,--no-insert-timestamp \
    -Wl,--dynamicbase -Wl,--nxcompat \
    -o "$B/gate_ioctl.sys" "${OBJS[@]}" -lntoskrnl

sha256sum "$B/gate_ioctl.sys"
echo "OK -> $B/gate_ioctl.sys"
