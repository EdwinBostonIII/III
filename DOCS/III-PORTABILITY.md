# III-PORTABILITY.md — Hardware/Firmware Agnosticism Architectural Mandate

**Document Identity:** PORTABILITY / Architectural Mandate / Wave 3 / Items 1-9
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-3+ implementation.** This document specifies the architectural mandates for hardware-agnostic operation across all major commodity architectures, while preserving the substrate's mathematical immunity, witnessed continuity, and bricking-impossibility properties.
**Version:** 1.0 — 2026-05-03 (Wave 3)
**Sources:** All 15 R1-sealed specs; III-PERFORMANCE.md; III-CRYPTO-AGILITY.md; III-FOUNDERS-ANCHOR.md; III-ZK-PRUNING.md; ADR-017 (no-firmware-write); ADR-018 (software-only DRTM); ADR-026 (TELOS-as-language).
**Cluster A items integrated:** 1 (ARM port), 2 (RISC-V port), 3 (Intel-VMX coexistence), 4 (generic hypervisor abstraction), 5 (generic IOMMU abstraction), 6 (generic NPT-class abstraction), 7 (cross-architecture closure root), 8 (no-firmware-write discipline universal), 9 (cross-architecture conformance test harness).

---

## §0. Preamble — The Hardware Agnosticism Imperative

III is currently engineered for **AMD-Zen + Windows** (per CHARIOT/XII). This is the operator's pragmatic-but-foundational starting platform. To achieve **planetary-scale dominance** (per Stateful Neumann §9 / Cluster D-K), III must deploy **everywhere**:

- **AMD-Zen 1-5+** (current target): SVM, NPT, AVIC, IOMMU, SHA-NI, AVX-512.
- **Intel** (Sandy Bridge through Granite Rapids+): VMX, EPT, IOMMU (VT-d), x2APIC, SHA-NI.
- **ARMv8.2+** (Apple Silicon, ARM servers, Snapdragon): SHA-NI variant, Stage-2 page tables, GIC, SMMU, virtualization extensions.
- **RISC-V (RV64GC + extensions)** (open-source silicon, server class): Zksh, hypervisor extension (H), IOMMU-RVI.
- **POWER (POWER9, POWER10)**: hypervisor mode, vMA, page-table mediated I/O.
- **Future architectures** (substrate must accept new ports without re-canonicalization).

The substrate's R1-sealed semantic guarantees do **not** depend on AMD-Zen specifics. Every architecture-specific feature lives behind a uniform abstraction layer; the closure-pinned semantics are architecture-independent.

This document specifies:

1. **§1** — The hardware abstraction layer (HAL) architectural mandate
2. **§2** — Per-architecture supported feature matrix
3. **§3** — Generic hypervisor primitive abstraction (item 4)
4. **§4** — Generic IOMMU abstraction (item 5)
5. **§5** — Generic NPT-class abstraction (item 6)
6. **§6** — Cross-architecture cryptographic acceleration (item 3, ARM SHA-2 / RISC-V Zksh)
7. **§7** — Cross-architecture closure root (item 7)
8. **§8** — No-firmware-write discipline universal (item 8)
9. **§9** — Cross-architecture conformance test harness (item 9)
10. **§10** — Specific port: ARMv8.2 (item 1)
11. **§11** — Specific port: RISC-V H-extension (item 2)
12. **§12** — Specific port: Intel-VMX coexistence (item 3)
13. **§13** — The 4-ring privilege lattice across architectures
14. **§14** — Conformance criteria
15. **§15** — Final statement

---

## §1. The Hardware Abstraction Layer Architectural Mandate

### §1.1 The mandate

Every architecture-specific operation lives behind a **uniform abstraction interface** (per the precedent of `crypto.<primitive>(suite_id, args)` in III-CRYPTO-AGILITY.md). The interfaces:

```iii
namespace hw {
    // Hypervisor primitives (per §3).
    fn hv_init() -> Witness @ring(R-1)
    fn hv_vmrun(vmcb: VmCb) -> VmExitReason @ring(R-1)
    fn hv_intercept(vmcb: VmCb, intercept_class: InterceptClass) -> Witness @ring(R-1)
    fn hv_teardown() -> Witness @ring(R-1)

    // IOMMU primitives (per §4).
    fn iommu_init() -> Witness @ring(R-1)
    fn iommu_map_iopt(bdf: PciBdf, iova: u64, gpa: u64, size: u64, flags: IoptFlags) -> Witness @ring(R-1)
    fn iommu_irte_remap(bdf: PciBdf, vector: u32, target_cpu: u32) -> Witness @ring(R-1)
    fn iommu_fault_intercept(handler: IommuFaultHandler) -> Witness @ring(R-1)

    // Page-table / NPT-class primitives (per §5).
    fn npt_class_set(gpa: u64, class: NptClass) -> Witness @ring(R-1)
    fn npt_class_get(gpa: u64) -> NptClass @ring(R-1)
    fn npt_invalidate(gpa: u64) -> Witness @ring(R-1)

    // Architecture-specific feature detection.
    fn arch() -> ArchitectureKind  // AMD_ZEN | INTEL_VMX | ARMV8 | RISCV_H | POWER9
    fn has_feature(feature: HwFeature) -> Bool
    fn cpu_count() -> u32
    fn numa_node_count() -> u32
    fn cpu_to_numa(cpu: u32) -> u32
}
```

### §1.2 Per-architecture implementation

Each architecture has a hand-rolled NIH implementation:

- `LOGOS/HW/amd_zen/{hv,iommu,npt,detect}.c` — AMD-Zen specifics.
- `LOGOS/HW/intel_vmx/{hv,iommu,npt,detect}.c` — Intel VMX specifics.
- `LOGOS/HW/armv8/{hv,iommu,npt,detect}.c` — ARMv8 specifics.
- `LOGOS/HW/riscv_h/{hv,iommu,npt,detect}.c` — RISC-V H-extension specifics.
- `LOGOS/HW/power9/{hv,iommu,npt,detect}.c` — POWER9 specifics.

All conform to the same interface. Substrate code never references architecture-specific names; it always calls through `hw.*`.

### §1.3 The discipline

- **No architecture-specific assembly in higher layers**. STDLIB, REDUCTION, CAUSAL, JIT, NET, etc. never contain architecture-specific assembly. Only `LOGOS/HW/<arch>/*.c` and `LOGOS/HW/<arch>/*.S` files.
- **No `#ifdef __amd64__`**. The compiler's hardware-detection is a runtime dispatch, not a compile-time toggle. The same source compiles for every architecture; the active code path is selected at runtime.
- **The closure root is architecture-agnostic** (per §7).

---

## §2. Per-Architecture Supported Feature Matrix

| Feature | AMD-Zen 5 | Intel Granite Rapids | ARMv8.2+ | RISC-V H | POWER9 |
|---------|-----------|----------------------|----------|-----------|--------|
| Hypervisor mode | SVM | VMX | EL2 | H-extension | Hypervisor |
| Stage-2 page tables | NPT | EPT | Stage-2 | G-stage | Hypervisor radix |
| IOMMU | AMD IOMMU | Intel VT-d | SMMU | IOMMU-RVI | PHB / IOMMU |
| Cryptographic SHA acceleration | SHA-NI | SHA-NI | SHA-2 instructions | Zksh | NX-CRYPTO |
| AES acceleration | AES-NI | AES-NI | AES instructions | Zkne | NX-CRYPTO |
| AVX/SIMD | AVX-512 | AVX-512 | NEON / SVE2 | Zvkn | VSX / VMX |
| BMI | BMI1 + BMI2 | BMI1 + BMI2 | (no equivalent; bit-manip via shifts) | Zbb | (no equivalent) |
| Hardware-RNG | RDRAND, RDSEED | RDRAND, RDSEED | RNDR, RNDRRS | Zkr | RIVN |
| TSC-equivalent | TSC | TSC | CNTPCT | RDTIME | TB |
| Memory protection keys | MPK (16 keys) | MPK (16 keys) | (no equivalent; via VMSA-2 stage-2 perms) | (no equivalent; via PMP) | (via SMR) |
| Branch prediction control | IBPB, IBRS, STIBP | IBPB, IBRS, STIBP | CSSELR, CSDB | (limited, evolving) | LPCR speculation control |

The substrate uses **graceful degradation**: features absent on a given architecture trigger a software fallback (e.g., MPK absent on ARMv8 → use stage-2 page-table-based isolation; AVX-512 absent on POWER9 → use VSX-based vectorization, scalar fallback otherwise).

---

## §3. Generic Hypervisor Primitive Abstraction (Item 4)

### §3.1 The mandate

The hypervisor (Ring -1) is exposed via a **uniform interface** that does not name AMD-V SVM specifics. The interface admits AMD-V, Intel VMX, ARMv8 EL2, RISC-V H-mode, and POWER hypervisor as backends.

### §3.2 The abstraction

```iii
schema VmCb = {
    state_save: bytes[1024],         // Architecture-agnostic state-save area
    intercepts: bytes[256],          // Architecture-mapped intercept bitmap
    asid: u32,                       // Address-space ID (per-VM)
    tsc_offset: i64,                 // TSC adjustment
    npt_root: u64,                   // Stage-2 page-table root (architecture-translated)
    // ... per-arch fields, opaque to higher layers.
}

cycle hv_intercept(vmcb: VmCb, intercept: InterceptClass) -> Witness @ring(R-1) {
    forward {
        match hw.arch() {
            AMD_ZEN -> amd_set_intercept(vmcb, intercept),
            INTEL_VMX -> intel_set_vm_exit_control(vmcb, intercept),
            ARMV8 -> arm_set_hcr_el2(vmcb, intercept),
            RISCV_H -> riscv_set_hstatus(vmcb, intercept),
            POWER9 -> power_set_lpcr(vmcb, intercept),
        }
    }
}
```

The `InterceptClass` enumerates: `MSR_READ`, `MSR_WRITE`, `CR_READ`, `CR_WRITE`, `IO_PORT`, `EXCEPTION`, `INTERRUPT`, `CPUID`, `RDTSC`, `WBINVD`, `INVLPG`, `INVLPGA`, `MWAIT`, `MONITOR`, `PAUSE`, `HLT`, `VMRUN`, `VMMCALL`. Each architecture maps these to its native intercept mechanism.

### §3.3 The closure-pinned mapping table

The mapping from `InterceptClass` to architecture-specific intercept bit indexes is closure-pinned. Modifying the mapping requires Tier-3 + Anchor cosignature; this protects against silent intercept-class drift across substrate versions.

---

## §4. Generic IOMMU Abstraction (Item 5)

### §4.1 The mandate

The IOMMU is exposed via a uniform interface. AMD IOMMU, Intel VT-d, ARM SMMU, RISC-V IOMMU-RVI, and POWER IOMMU all map to the same surface.

### §4.2 The abstraction

```iii
schema IoptEntry = {
    iova: u64,
    gpa: u64,
    size: u64,
    flags: u32,  // R/W/X + cacheability + class trit
}

cycle iommu_map_iopt(bdf: PciBdf, entry: IoptEntry) -> Witness @ring(R-1) {
    forward {
        match hw.arch() {
            AMD_ZEN -> amd_iommu_program_dte(bdf, entry),
            INTEL_VMX -> intel_iommu_program_root_table(bdf, entry),
            ARMV8 -> arm_smmu_program_ste(bdf, entry),
            RISCV_H -> riscv_iommu_program_pdt(bdf, entry),
            POWER9 -> power_iommu_program_pe(bdf, entry),
        }
    }
}
```

### §4.3 Per-architecture IRTE remapping

Interrupt remapping (per Stateful Neumann §3.3 / network-coexistence) requires architecture-specific MSI/MSI-X IRTE programming:

```iii
cycle iommu_irte_remap(bdf: PciBdf, vector: u32, target_cpu: u32) -> Witness @ring(R-1) {
    forward {
        match hw.arch() {
            AMD_ZEN -> amd_iommu_program_irte(bdf, vector, target_cpu),
            INTEL_VMX -> intel_iommu_program_iremap(bdf, vector, target_cpu),
            ARMV8 -> arm_gic_program_irq(bdf, vector, target_cpu),
            // ...
        }
    }
}
```

### §4.4 The fault-handler unification

IOMMU faults (illegal DMA, ATS errors) are delivered via architecture-specific mechanisms. The substrate registers a uniform handler that translates the architecture-specific fault to a substrate-level `IommuFault` effect.

---

## §5. Generic NPT-Class Abstraction (Item 6)

### §5.1 The mandate

NPT (Nested Page Table) class trits — the AMD-Zen-specific encoding distinguishing CODE / DATA / SECEXT / READONLY classes per page (per CHARIOT/XII `HW/iface/npt.h`) — are abstracted to a uniform `NptClass` enumeration:

```iii
enum NptClass {
    UNCLASSIFIED,      // raw memory, pre-allocator
    REDUCTION_DATA,    // managed Reduction terms (per S13)
    CODE,              // executable code; W^X enforcement
    SECEXT,            // sealed/extracted (R-2 only)
    READONLY,          // immutable; no writes possible
    JIT_CODE,          // JIT-compiled code; MPK-isolated
    AUDIT_RING,        // per-CPU audit ring; lock-free
    SUB_KEY,           // per-CPU HMAC sub-key; cache-pinned
    ANCHOR_DATA,       // closure-pinned anchor data; never written post-genesis
}
```

### §5.2 Per-architecture mapping

| NptClass | AMD-Zen NPT | Intel EPT | ARMv8 Stage-2 | RISC-V G-stage | POWER9 hypervisor radix |
|----------|-------------|-----------|----------------|------------------|--------------------------|
| UNCLASSIFIED | (no class bit; default) | (no class bit; default) | (no class bit; default) | — | — |
| REDUCTION_DATA | NPT class bit 56 | EPT class bit 56 | AttrIndx[2:0] | (custom PMA) | (custom PHB) |
| CODE | NPT class bit 56 + X bit | EPT class bit 56 + X bit | XN cleared | X bit set | X bit set |
| SECEXT | NPT bit 53 (sealed) | EPT bit 53 | (custom; tied to security extension) | (custom PMP) | (custom HSR) |
| READONLY | NPT W cleared | EPT W cleared | AP[1] = 1 (read-only) | W cleared | W cleared |
| JIT_CODE | NPT + MPK key | EPT + MPK key | + protection key (where supported) | + PMP key | + (limited) |
| AUDIT_RING | NPT + cache-line aligned | EPT + cache-line aligned | + Stage-1/Stage-2 sync | + sync | + sync |
| SUB_KEY | NPT + MPK key | EPT + MPK key | + PK | (custom) | (custom) |
| ANCHOR_DATA | NPT + W cleared + closure-pinned | EPT + W cleared + closure-pinned | + AP[1] = 1 | + W cleared | + W cleared |

### §5.3 The closure-pinned mapping

Each architecture's NPT-class mapping is closure-pinned. Modifying it requires Tier-3 + Anchor cosignature.

---

## §6. Cross-Architecture Cryptographic Acceleration (Item 3)

### §6.1 ARM SHA-2

ARMv8.2+ exposes SHA-2 instructions via the FEAT_SHA2 extension (CPUID-equivalent: `ID_AA64ISAR0_EL1.SHA2 != 0`). Per Wave 1 (III-PERFORMANCE.md §1.5), the substrate hand-rolls assembly:

```asm
sha256h q0, q1, v2.4s  ; Hash update (high words)
sha256h2 q0, q1, v2.4s ; Hash update (low words)
sha256su0 v0.4s, v1.4s ; Schedule update step 1
sha256su1 v0.4s, v1.4s, v2.4s  ; Schedule update step 2
```

Implementation: `LOGOS/HW/armv8/sha256_arm.S`. KAT corpus: same as `BOOTSTRAP/sha256_shani.S` (NIST KATs).

### §6.2 RISC-V Zksh

RISC-V's Zksh extension provides SHA-256-acceleration instructions. Per:

```asm
sha256sig0 a0, a1
sha256sig1 a0, a1
sha256sum0 a0, a1
sha256sum1 a0, a1
```

Implementation: `LOGOS/HW/riscv_h/sha256_zksh.S`. KAT corpus: NIST KATs.

### §6.3 ARM SVE2 / NEON for batched HMAC

ARM SVE2 (Scalable Vector Extension v2) is the post-NEON SIMD on modern ARMv9. Per Wave 1 §2 (SIMD batched HMAC), implementation:

```asm
ld1d { z0.d, z1.d, z2.d, z3.d }, p0/z, [x0]  ; SVE-aware load
sha256h z0.s, z1.s, z2.s.s
...
```

Implementation: `LOGOS/HW/armv8/hmac_sha256_sve2.S`.

### §6.4 The dispatch matrix

The hardware dispatcher (per III-PERFORMANCE.md §17) is extended to include per-architecture detection:

```iii
fn detect_crypto_acceleration() -> CryptoAccel {
    match hw.arch() {
        AMD_ZEN -> CryptoAccel {
            sha256: select(cpuid.has_sha_ni, SHA256_SHA_NI, SHA256_SOFTWARE),
            blake3: select(cpuid.has_avx512_bw, BLAKE3_AVX512, BLAKE3_SCALAR),
            shake256: select(cpuid.has_sha3_ni, SHAKE_SHA3_NI, SHAKE_SOFTWARE),
            // ...
        },
        INTEL_VMX -> CryptoAccel {
            sha256: select(cpuid.has_sha_ni, SHA256_SHA_NI, SHA256_SOFTWARE),
            // ...
        },
        ARMV8 -> CryptoAccel {
            sha256: select(arch.has_sha2, SHA256_ARM, SHA256_SOFTWARE),
            blake3: select(arch.has_sve2, BLAKE3_SVE2, BLAKE3_NEON_OR_SCALAR),
            shake256: SHAKE_SOFTWARE,  // No ARM SHA-3-NI yet
            // ...
        },
        RISCV_H -> CryptoAccel {
            sha256: select(arch.has_zksh, SHA256_ZKSH, SHA256_SOFTWARE),
            blake3: select(arch.has_zvkn, BLAKE3_ZVKN, BLAKE3_SCALAR),
            // ...
        },
        // ...
    }
}
```

---

## §7. Cross-Architecture Closure Root (Item 7)

### §7.1 The mandate

The closure root (per III-MODULES §10) is **architecture-independent**. The same source produces the same closure root regardless of which architecture compiles it.

### §7.2 Implementation

The compiler emits architecture-independent **canonical bytecode** for the closure-root computation. The closure root is:

```
closure_root := mhash(
    canonical_AST_bytes ||
    canonical_proof_certificates ||
    canonical_capability_chain ||
    canonical_constants ||
    architecture-INDEPENDENT bytecode emission
)
```

The compiler does not include architecture-specific machine code in the closure root computation. The actual binary output (per-architecture machine code) is a derivative of the same closure root.

### §7.3 The cross-architecture verification

A peer running an ARMv8 substrate can verify another peer's R1 composite root even if that peer runs AMD-Zen. Both peers compute the same composite root from the same source.

### §7.4 The architecture-binding witness

Each peer's witness chain includes an `arch_binding` flag in `flags` bits 25..31 (per III-CYCLES §6.4 extension):

```
ARCH_BINDING_AMD_ZEN = 0x01
ARCH_BINDING_INTEL_VMX = 0x02
ARCH_BINDING_ARMV8 = 0x04
ARCH_BINDING_RISCV_H = 0x08
ARCH_BINDING_POWER9 = 0x10
```

This indicates which architecture emitted the witness. Federation peers can audit the architecture-distribution of the federation.

---

## §8. No-Firmware-Write Discipline Universal (Item 8)

### §8.1 The mandate

Per ADR-017 and III-PHASES §5: III **never writes to firmware**. The six bricking-class operations (per III-LEXICON / III-HEXAD) are unrepresentable in the type system. This discipline must hold across **all** supported architectures.

### §8.2 Per-architecture firmware boundaries

| Architecture | Firmware regions III must NOT write |
|--------------|--------------------------------------|
| AMD-Zen | UEFI NVRAM, microcode, ME/PSP mailbox, SMRAM, capsule update |
| Intel | UEFI NVRAM, microcode, ME mailbox, SMRAM, BIOS update path |
| ARMv8 | TF-A NV memory, secure-world non-volatile storage |
| RISC-V | OpenSBI configuration, M-mode firmware, secure-monitor regions |
| POWER9 | OPAL configuration, hypervisor firmware NV regions |

The substrate's hexad-classification of writes to these regions is **NEG-pillar**, making the operation type-system-unrepresentable.

### §8.3 Phantom NVRAM is file-backed across architectures

Per ADR-017, Phantom NVRAM persists state to a signed file on the EFI System Partition (or equivalent). On non-EFI platforms (e.g., RISC-V devboards, embedded ARM), Phantom NVRAM uses an alternate storage:

- ARMv8 with U-Boot: signed file in U-Boot's environment partition (read/write via U-Boot variables; III intercepts; no actual U-Boot env write).
- RISC-V: signed file on a normal filesystem, hashed and pinned in the closure root.
- POWER9: signed file in the OPAL config partition (similar).

In all cases: **no firmware mutation**. Only file-backed signed-state.

### §8.4 DRTM software-only across architectures

Per ADR-018: III does software-only DRTM (no TXT, no SKINIT, no TPM). Per architecture:

- AMD-Zen: DRTM via the V3 software-DRTM mechanism (per CHARIOT/XII).
- Intel: same software-DRTM with IBPB+VERW+SSBD instead of SKINIT.
- ARMv8: software-DRTM using TF-A handoff signaling but no actual TF-A modification.
- RISC-V: software-DRTM via M-mode handoff to S-mode (no M-mode firmware change).
- POWER9: software-DRTM via OPAL handoff (similar).

In all cases: substrate-internal DRTM relaunch only, no external firmware reset.

---

## §9. Cross-Architecture Conformance Test Harness (Item 9)

### §9.1 The mandate

A single conformance test harness verifies that III preserves all R1-sealed semantic guarantees across every supported architecture. The harness:

- Compiles `LOGOS/TESTS/*.lgs` for every supported architecture.
- Runs each test on every architecture.
- Compares results for byte-equivalence (modulo timestamps and architecture-binding flags).
- Reports per-architecture pass/fail.

### §9.2 The 30 conformance criteria + 70 derived

Per III-CONFORMANCE.md C-1..C-30 + the 70 derived criteria (per derivative docs C-CRYPTO-1..10, C-FNDR-1..20, C-PERF-1..20, C-OBS-1..20, C-ZK-1..22, etc., totaling ~100), the harness verifies all on every architecture.

### §9.3 Implementation

`LOGOS/TESTS/cross_arch_harness.lgs` — the test driver. Spawn a sub-substrate for each architecture (via QEMU emulation if real hardware unavailable, or native execution on physical hardware), runs all tests, aggregates results.

### §9.4 The QEMU coverage discipline

For architectures where the operator lacks physical hardware (e.g., RISC-V at substrate genesis), QEMU emulation provides the test execution environment. The harness:

- Builds for each architecture.
- Boots a minimal Linux + III test runner under QEMU.
- Runs the test suite.
- Reports pass/fail.

This is **not** the operational deployment path; it is purely for conformance testing.

### §9.5 The continuous integration

Every commit to the substrate's source must pass the cross-architecture harness before being merged. The harness runs on every commit; failures block the merge.

---

## §10. Specific Port: ARMv8.2 (Item 1)

### §10.1 The platform

- **Hardware**: Apple Silicon (M1/M2/M3/M4), AWS Graviton (2/3/4), Ampere Altra/AltraMax, NVIDIA Grace, Snapdragon X Elite (laptop ARM), Raspberry Pi 5+.
- **Hypervisor mode**: EL2 (Exception Level 2). Substrate runs at EL2; guests at EL1.
- **Stage-2 page tables**: VTTBR_EL2-rooted; 48-bit IPA range; 4 KB pages; AttrIndx for class trits.
- **IOMMU**: SMMU (System Memory Management Unit) v3+. STE (Stream Table Entry) per BDF.
- **GIC**: Generic Interrupt Controller v3+. ITS (Interrupt Translation Service) for MSI/MSI-X.
- **TPM-equivalent**: Apple's Secure Enclave (proprietary, not used); ARM TrustZone (used for secure-monitor handoff but not modified).

### §10.2 The boot path

For Apple Silicon:

- macOS or Linux (Asahi) hosts the substrate.
- The substrate runs as a kernel extension (KEXT, but signed) or kernel module (Linux LKM with operator's test cert).
- Substrate mounts EL2 via ARM virtualization extensions on first boot.

For AWS Graviton:

- Linux hosts the substrate.
- The substrate runs as a kernel module.
- Substrate mounts EL2 directly.

For Ampere/NVIDIA:

- Same as Graviton.

### §10.3 The Phantom NVRAM mapping

Phantom NVRAM uses a signed file on the EFI System Partition (UEFI) or U-Boot env (embedded). On Apple Silicon, the signed file lives in the boot partition.

### §10.4 The ARM-specific MPK substitute

ARMv8 lacks Intel/AMD MPK. The substrate uses **Stage-2 page-table-based isolation** with per-page protection key (where ARMv8.5+ MTE is available) or per-region permission-domains otherwise.

### §10.5 The implementation

`LOGOS/HW/armv8/hv_arm.c` (~3000 LoC), `LOGOS/HW/armv8/iommu_smmu.c` (~2000 LoC), `LOGOS/HW/armv8/npt_stage2.c` (~1500 LoC), `LOGOS/HW/armv8/sha256_arm.S` (~500 LoC).

---

## §11. Specific Port: RISC-V H-extension (Item 2)

### §11.1 The platform

- **Hardware**: SiFive Unmatched, Pioneer (BeagleBone-class), Allwinner Nezha, custom server boards (early 2026 onwards).
- **Hypervisor mode**: H-extension (`hstatus` CSR enables hypervisor mode).
- **G-stage page tables**: vsatp + hgatp dual-stage. Class-trit encoding via PMP (Physical Memory Protection) entries + custom PTE bits.
- **IOMMU**: IOMMU-RVI (RISC-V IOMMU). PDT (Device Table) per BDF.
- **PLIC/CLIC**: Platform-Level Interrupt Controller / Core-Local Interrupt Controller.
- **Crypto extensions**: Zksh (SHA-256), Zkne (AES-128/256), Zvkn (vectorized AES + SHA).

### §11.2 The boot path

Linux hosts the substrate; substrate runs as a kernel module; substrate mounts H-extension at first boot.

### §11.3 The phantom NVRAM mapping

A signed file in the OpenSBI configuration partition. OpenSBI is not modified; only the file is updated.

### §11.4 The implementation

`LOGOS/HW/riscv_h/hv_riscv.c` (~2500 LoC), `LOGOS/HW/riscv_h/iommu_rvi.c` (~1500 LoC), `LOGOS/HW/riscv_h/npt_g_stage.c` (~1500 LoC), `LOGOS/HW/riscv_h/sha256_zksh.S` (~400 LoC).

---

## §12. Specific Port: Intel-VMX Coexistence (Item 3)

### §12.1 The platform

- **Hardware**: Intel Sandy Bridge through Granite Rapids (2011-current).
- **Hypervisor mode**: VMX root mode.
- **EPT**: Extended Page Tables.
- **IOMMU**: Intel VT-d.
- **x2APIC**: Extended APIC.

### §12.2 The boot path

Same as AMD-Zen: substrate runs as a Windows kernel driver (or Linux kernel module); substrate mounts VMX on first IOCTL.

### §12.3 The implementation

`LOGOS/HW/intel_vmx/hv_vmx.c` (~3500 LoC, larger because VMX has more configuration than SVM), `LOGOS/HW/intel_vmx/iommu_vt_d.c` (~2000 LoC), `LOGOS/HW/intel_vmx/npt_ept.c` (~1500 LoC), `LOGOS/HW/intel_vmx/sha256_shani.S` (existing — shared with AMD-Zen).

### §12.4 Coexistence

A federation may include peers running AMD-Zen, Intel-VMX, ARMv8, RISC-V H simultaneously. Each peer's witness chain is interoperable; the cross-architecture closure root (per §7) ensures identity continuity.

---

## §13. The 4-Ring Privilege Lattice Across Architectures

### §13.1 The mandate

The privilege ring lattice (R-3 / R-2 / R-1 / R0 / R3) per III-FOUNDERS-ANCHOR.md §1.3 maps consistently across architectures:

| Ring | AMD-Zen | Intel | ARMv8 | RISC-V | POWER9 |
|------|---------|-------|--------|---------|--------|
| R-3 | Logical (Anchor signature gating) | Logical | Logical | Logical | Logical |
| R-2 | Software Sanctum (SECEXT NPT class) | Software Sanctum | Software Sanctum (Stage-2 + protection key) | Software Sanctum (PMP) | Software Sanctum (HSR + protection) |
| R-1 | SVM hypervisor (CPL=0 in host mode) | VMX root mode | EL2 | H-mode | hypervisor mode |
| R0 | Kernel (CPL=0, AMD-V guest mode) | Kernel | EL1 | S-mode | OS-server mode |
| R3 | User (CPL=3) | User | EL0 | U-mode | user-server mode |

All architectures support this 5-level lattice (counting R-3 as logical). The substrate's R-3 implementation is identical across architectures (Anchor-signature verification by the closure-pinned proof kernel).

### §13.2 The closure-pinned ring lattice

The lattice's structure is closure-pinned. Modifying it (e.g., adding R-4 for a future hardware feature) requires Tier-3 + Anchor cosignature.

---

## §14. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-PORT-1 | The HAL interface (`hw.*`) is uniform across all supported architectures |
| C-PORT-2 | No architecture-specific assembly outside `LOGOS/HW/<arch>/` |
| C-PORT-3 | Cross-architecture closure root: same source produces same closure root regardless of build architecture |
| C-PORT-4 | Witness `arch_binding` flag correctly identifies the emitting architecture |
| C-PORT-5 | All 22 supported features (per §2 matrix) are runtime-detected, not compile-time-hardcoded |
| C-PORT-6 | Software fallback path produces correct results for any feature absent on a given architecture |
| C-PORT-7 | NPT-class encoding correctly maps to architecture-specific page-table bits per §5.2 mapping table |
| C-PORT-8 | Hypervisor intercept-class mapping correctly translates `InterceptClass` to architecture-specific bits per §3.2 mapping |
| C-PORT-9 | IOMMU IOPT mapping correctly programs the architecture-specific table per §4.2 |
| C-PORT-10 | IOMMU IRTE remapping correctly programs MSI/MSI-X per architecture per §4.3 |
| C-PORT-11 | The hardware-RNG dispatcher selects RDRAND/RDSEED on x86, RNDR/RNDRRS on ARM, Zkr on RISC-V |
| C-PORT-12 | All NIST KAT vectors pass for hand-rolled ARM SHA-2 implementation |
| C-PORT-13 | All NIST KAT vectors pass for hand-rolled RISC-V Zksh implementation |
| C-PORT-14 | The 4-ring privilege lattice is correctly implemented across all architectures |
| C-PORT-15 | Phantom NVRAM is file-backed; no firmware mutation on any architecture |
| C-PORT-16 | DRTM software-only across all architectures; no hardware DRTM (TXT, SKINIT) used |
| C-PORT-17 | Six bricking-class operations remain unrepresentable on every architecture (NEG hexad) |
| C-PORT-18 | Cross-architecture conformance harness passes all 100+ R1 + derivative criteria on every supported architecture |
| C-PORT-19 | A federation including AMD-Zen, Intel-VMX, ARMv8, RISC-V H peers federates correctly |
| C-PORT-20 | Cross-architecture closure-root verification: peer running ARMv8 verifies peer running AMD-Zen R1 root |

---

## §15. Final Statement

Hardware/firmware agnosticism is the architectural commitment that III is **categorically a substrate, not an AMD-Zen application**. The same closure root, the same R1 sealed semantics, the same witnessed continuity, the same Anchor invariant operate across AMD-Zen, Intel-VMX, ARMv8, RISC-V H, POWER9, and any future architecture that admits the 4-ring privilege lattice.

Each architecture's port is a hand-rolled NIH translation layer in `LOGOS/HW/<arch>/*`. The substrate's higher layers (REDUCTION, CAUSAL, CATALYST, JIT, NET, STDLIB, etc.) remain architecture-agnostic. The closure root is architecture-independent; the witness chain is interoperable across architectures; the federation includes peers running heterogeneous architectures.

This is the answer to items 1-9. Wave 3 is the realization that III's identity is a property of its mathematical structure, not its silicon binding.

*Wave 3 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new architecture port) or Tier-3 amendment (new HAL interface).*
