#!/usr/bin/env bash
# KATABASIS Ring-1 FLOOR loader - deterministic build.
#
# Through I2 the floor was a minimal SVM driver. At I3 it ALSO links the full pure-.iii gate-admit closure
# (the same 19 modules gate_ioctl.sys uses) so the Ring-1 VMEXIT handler can run katabasis_gate_admit on a
# guest's hypercall -- the gate decision AT the Ring -1 boundary. Still the ISOLATED floor binary (separate
# from gate_ioctl.sys). floor_abi.s carries the SVM machinery (probe/WRMSR/pin/region/VMCB/VMRUN shims).
set -euo pipefail
export SOURCE_DATE_EPOCH=0 LC_ALL=C TZ=UTC0
cd "$(dirname "$0")/.."                       # III root
IIIS=COMPILED/iiis-2.exe
S=KATABASIS-DEPLOY/src
B=KATABASIS-DEPLOY/build
O=$B/obj
mkdir -p "$O"

# gate-admit dependency closure, leaves first (identical to the Tier-3 gate_ioctl closure).
MODS=(
  omnia/hexad_algebra omnia/hexad_pfs omnia/hexad_reach omnia/xii_term
  numera/sha256 numera/keccak256 numera/keccak numera/content_addr
  aether/capability
  katabasis/svm_layout katabasis/bar_layout katabasis/cycle_family
  katabasis/cycle_admit katabasis/cycle_term katabasis/seal katabasis/caps
  katabasis/gate_verdict katabasis/gate katabasis/admit
)

echo "[1] cg_r0 -> .o : floor driver + kernel cpufeat shim + ${#MODS[@]} gate-closure modules"
"./$IIIS" "$S/gate_floor.iii"     --ring R0 --compile-only --out "$O/gate_floor.o"
"./$IIIS" "$S/cpufeat_kernel.iii" --ring R0 --compile-only --out "$O/cpufeat_kernel.o"
OBJS=("$O/gate_floor.o" "$O/cpufeat_kernel.o")
for m in "${MODS[@]}"; do n=$(basename "$m"); "./$IIIS" "STDLIB/iii/$m.iii" --ring R0 --compile-only --out "$O/$n.o"; OBJS+=("$O/$n.o"); done

echo "[2] assemble kernel witness leaf + floor ntoskrnl shims (Io + WRMSR + pin/unpin + Mm + VMCB/VMRUN)"
gcc -c -x assembler -o "$O/witness_kernel.o" "$S/witness_kernel.s"; OBJS+=("$O/witness_kernel.o")
gcc -c -x assembler -o "$O/floor_abi.o"      "$S/floor_abi.s";      OBJS+=("$O/floor_abi.o")

echo "[3] link gate_floor.sys (PE32+ native, entry=DriverEntry, ntoskrnl imports, deterministic)"
gcc -mabi=ms -ffreestanding -shared -nostdlib \
    -Wl,--subsystem,native -Wl,-e,DriverEntry -Wl,--exclude-all-symbols \
    -Wl,--disable-runtime-pseudo-reloc -Wl,--image-base,0x140000000 \
    -Wl,--disable-high-entropy-va -Wl,--no-insert-timestamp \
    -Wl,--dynamicbase -Wl,--nxcompat \
    -o "$B/gate_floor.sys" "${OBJS[@]}" -lntoskrnl

sha256sum "$B/gate_floor.sys"
echo "OK -> $B/gate_floor.sys"
