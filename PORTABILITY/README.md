# III / PORTABILITY

Hardware/firmware-agnostic substrate layer for III. Implements the
architectural mandate of [`DOCS/III-PORTABILITY.md`](../DOCS/III-PORTABILITY.md)
(Wave-3, items 1-9) in pure NIH C11.

## Build

```
gcc -std=c11 -Wall -Wextra -Werror -O2 -IPORTABILITY/include -ILEXICON/include
```

Run `build\build.bat` to produce:

| Artifact                       | Description                              |
| ------------------------------ | ---------------------------------------- |
| `build/libiii_portability.a`   | Static library (HAL + closure root)      |
| `build/iii_port_tool.exe`      | CLI: `archs`, `select <ARCH>`, `closure` |
| `build/iii_port_test.exe`      | Conformance harness (114 assertions)     |

Linked against `LEXICON/build/libiii_lex.a` for SHA-256.

## HAL interface

The single `iii_hal_t` vtable (in `include/iii/portability.h`) exposes every
primitive named in `DOCS/III-PORTABILITY.md` §1.1, §3-§5, §8:

| Group              | Members |
| ------------------ | ------- |
| Identity / detect  | `arch`, `name`, `arch_binding`, `detect`, `has_feature`, `cpu_count`, `numa_node_count`, `cpu_to_numa` |
| §3 Hypervisor      | `hv_init`, `hv_vmrun`, `hv_intercept`, `hv_teardown` |
| §4 IOMMU           | `iommu_init`, `iommu_map_iopt`, `iommu_irte_remap`, `iommu_fault_intercept` |
| §5 NPT-class / PT  | `npt_class_set`, `npt_class_get`, `npt_invalidate`, `mmu_init` |
| §8.4 DRTM          | `drtm_relaunch` (software-only — never touches firmware) |
| Concurrency / time | `ipi_send`, `timer_now`, `cache_flush`, `atomic_cas64`, `atomic_add64` |
| Closure-pinned     | `opcodes[]`, `intercept_map[18]`, `npt_class_map[9]` |

`iii_hal_select(arch)` returns the chosen HAL; `iii_hal_default()` returns the
compile-host HAL. The five vtables are linked unconditionally so a single
binary can dispatch any architecture at runtime (per §1.3: no `#ifdef
__amd64__`).

## Per-architecture notes

Each architecture is a self-contained translation unit (`src/hal_<arch>.c`)
that defines its opcode tables, intercept-bit map, and NPT-class encoding,
then includes `src/hal_template.h` to instantiate the HAL methods.

| File              | Arch       | Bind | Opcodes (NIH bytes)                                                                 |
| ----------------- | ---------- | ---- | ------------------------------------------------------------------------------------ |
| `hal_x86_64.c`    | AMD-Zen    | 0x01 | VMRUN, VMMCALL, VMLOAD, VMSAVE, STGI, CLGI, INVLPGA, RDTSC, WBINVD, CPUID            |
| `hal_intel_vmx.c` | Intel VMX  | 0x02 | VMXON, VMXOFF, VMCLEAR, VMPTRLD, VMPTRST, VMLAUNCH, VMRESUME, VMREAD, VMWRITE, INVEPT, INVVPID, VMCALL |
| `hal_armv8.c`     | ARMv8.2+   | 0x04 | ERET, HVC#0, SMC#0, DSB.SY, ISB.SY, WFI, TLBI, MRS_CurrentEL, AT_S1E1R, IC_IALLU     |
| `hal_riscv_h.c`   | RISC-V H   | 0x08 | WFI, MRET, SRET, ECALL, EBREAK, HFENCE.GVMA, HFENCE.VVMA, SFENCE.VMA, CSRRS_H, FENCE.I |
| `hal_power9.c`    | POWER9     | 0x10 | hrfid, rfid, isync, sync, eieio, slbia, mfmsr, mtmsrd, mtmsr, tlbsync                |

Every opcode is a `static const uint8_t code[]` array with hand-encoded bytes;
no `gas`/`as`/intrinsics are used (NIH discipline).

## Cross-architecture closure root (§7)

`iii_closure_root_compute(modules, n, out[32])` produces a SHA-256 over a
canonical, architecture-independent serialization:

```
"III/PORTABILITY/CLOSURE/v1\n"           (27 ASCII bytes)
u32_be(module_count)
for m in sort_by_name(modules):
    u32_be(name_len) || name_bytes
    u64_be(byte_len) || byte_bytes
```

Modules are sorted lexicographically by name internally, so caller order is
irrelevant. The conformance harness verifies that:

1. Empty input hashes to a fixed expected hex
   (`0d0154b4...b044155d`).
2. Two synthetic modules in either order hash to the same expected hex
   (`57d1ca5d...302d204e`).
3. The same modules computed under each of the five HAL contexts produce
   byte-identical roots — proving §7.3 cross-arch verifiability.

## Tool

```
iii_port_tool.exe archs                    # list supported architectures
iii_port_tool.exe select riscv_h           # dump HAL details for an arch
iii_port_tool.exe closure module1 module2  # compute cross-arch closure root
```

## Conformance criteria covered

| Criterion | Coverage |
| --------- | -------- |
| C-PORT-1  | Uniform `iii_hal_t` across all 5 archs (test: hal vtable presence) |
| C-PORT-2  | Architecture-specific code is confined to `src/hal_<arch>.c` |
| C-PORT-3  | Same source → same closure root (test: arch-independence) |
| C-PORT-4  | `arch_binding` distinct per arch (test: arch parse) |
| C-PORT-5  | `has_feature()` is runtime-dispatched per HAL feature table |
| C-PORT-7  | NPT-class mapping per arch (test: npt_class_map well-formed) |
| C-PORT-8  | Intercept-class mapping per arch (test: intercept_map distinct) |
| C-PORT-9  | IOMMU IOPT mapping (test: iommu_init+map+irte) |
| C-PORT-10 | IRTE remapping (test: iommu_init+map+irte) |
| C-PORT-15 | No firmware mutation; DRTM relaunch is software-only |
| C-PORT-16 | DRTM relaunch returns SHA-256 measurement, no TXT/SKINIT |
| C-PORT-17 | Bricking-class ops absent from public API (no firmware-write fn) |
| C-PORT-19 | Five concurrent HAL vtables coexist in one binary (federation) |
| C-PORT-20 | Closure root identical across arch contexts (cross-arch verify) |

## Stats

* 11 source files
* 1272 LOC (NIH, no third-party code)
* 114 test assertions, **0 failures**
