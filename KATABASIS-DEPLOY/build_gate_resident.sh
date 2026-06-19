#!/usr/bin/env bash
# KATABASIS Tier-2 resident gate-DECISION .sys - deterministic build (NIH per ADR-021).
#
# Links the FULL pure-.iii gate-admit closure (cg_r0-compiled) + the driver + the kernel
# witness leaf into a PE32+ NT-native driver with ZERO external imports. DriverEntry runs
# the 4-case gate selftest in Ring 0 and returns the verdict as NTSTATUS.
set -euo pipefail
export SOURCE_DATE_EPOCH=0 LC_ALL=C TZ=UTC0
cd "$(dirname "$0")/.."                       # III root
IIIS=COMPILED/iiis-2.exe
S=KATABASIS-DEPLOY/src
B=KATABASIS-DEPLOY/build
O=$B/obj
mkdir -p "$O"

# gate-admit dependency closure, in deterministic order (leaves first).  Repaired for the post-Jun-6 stdlib drift
# (content_addr folded into cad; closure grew trit/quine_seal/wvb_*) using the kernel-safe subsets weave_blocks_kernel
# + cad_kernel (cad_kernel routes to scalar sha256, so the resident driver stays import-free); content_addr removed.
MODS=(
  omnia/hexad_algebra omnia/hexad_pfs omnia/hexad_reach omnia/xii_term
  numera/trit numera/sha256 numera/keccak256 numera/keccak
  aether/capability
  katabasis/svm_layout katabasis/bar_layout katabasis/cycle_family
  katabasis/cycle_admit katabasis/cycle_term katabasis/seal katabasis/caps
  katabasis/quine_seal katabasis/gate_verdict katabasis/gate katabasis/admit
)

echo "[1] cg_r0 -> .o : driver + kernel-safe subsets (cpufeat/weave_blocks/cad) + ${#MODS[@]} closure modules"
"./$IIIS" "$S/gate_resident.iii" --ring R0 --compile-only --out "$O/gate_resident.o"
"./$IIIS" "$S/cpufeat_kernel.iii" --ring R0 --compile-only --out "$O/cpufeat_kernel.o"
"./$IIIS" "$S/weave_blocks_kernel.iii" --ring R0 --compile-only --out "$O/weave_blocks_kernel.o"
"./$IIIS" "$S/cad_kernel.iii" --ring R0 --compile-only --out "$O/cad_kernel.o"
OBJS=("$O/gate_resident.o" "$O/cpufeat_kernel.o" "$O/weave_blocks_kernel.o" "$O/cad_kernel.o")
for m in "${MODS[@]}"; do n=$(basename "$m"); "./$IIIS" "STDLIB/iii/$m.iii" --ring R0 --compile-only --out "$O/$n.o"; OBJS+=("$O/$n.o"); done

echo "[2] assemble kernel witness leaf"
gcc -c -x assembler -o "$O/witness_kernel.o" "$S/witness_kernel.s"
OBJS+=("$O/witness_kernel.o")

echo "[3] link gate_resident.sys (PE32+ native, entry=DriverEntry, no imports, deterministic)"
gcc -mabi=ms -ffreestanding -shared -nostdlib \
    -Wl,--subsystem,native -Wl,-e,DriverEntry -Wl,--exclude-all-symbols \
    -Wl,--disable-runtime-pseudo-reloc -Wl,--image-base,0x140000000 \
    -Wl,--disable-high-entropy-va -Wl,--no-insert-timestamp \
    -Wl,--dynamicbase -Wl,--nxcompat \
    -o "$B/gate_resident.sys" "${OBJS[@]}"

sha256sum "$B/gate_resident.sys"
echo "OK -> $B/gate_resident.sys"
