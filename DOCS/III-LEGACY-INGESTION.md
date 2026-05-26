# III-LEGACY-INGESTION.md — Legacy Binary and OS Ingestion Architectural Mandate

**Document Identity:** LEGACY-INGESTION / Architectural Mandate / Wave 5 / Items 33-46
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-5+ implementation.** This document specifies how III ingests, supervises, and witnesses the operation of legacy binaries (ELF, PE, Mach-O, COFF) and legacy operating systems (Windows, Linux, macOS, BSD) as **guests** of the substrate.
**Version:** 1.0 — 2026-05-03 (Wave 5)
**Sources:** All 15 R1-sealed specs; III-PERFORMANCE.md; III-CRYPTO-AGILITY.md; III-FOUNDERS-ANCHOR.md; III-PORTABILITY.md; III-OBSERVABILITY.md; III-GHOST-CODE.md; ADR-026 (TELOS-as-language); Stateful Neumann §3.2 (Windows coexistence).
**Cluster integrated:** items 33 (ELF parser), 34 (PE parser), 35 (Mach-O parser), 36 (COFF parser), 37 (generic legacy-binary type), 38 (legacy-binary execution sandbox), 39 (witness emission for legacy syscalls), 40 (legacy-OS coexistence), 41 (syscall translation), 42 (legacy-process supervision), 43 (legacy-memory mapping), 44 (legacy-FS mediation), 45 (legacy-network mediation), 46 (legacy-driver containment).

---

## §0. Preamble — Why III Must Speak Every Existing Language

III is the *terminal* substrate. It is the last computational foundation. But the world contains decades of accumulated software written for Windows, Linux, macOS, BSD, Solaris, AIX, and embedded RTOSes. **III cannot achieve planetary dominance by demanding everyone rewrite their software.** The transition strategy is:

1. Phase 0 (today): III runs alongside Windows on the operator's machine. Windows hosts the load vehicle.
2. Phase 1 (Wave 5): III ingests legacy binaries — ELF, PE, Mach-O, COFF — as **legacy cycles**. They execute under III's supervision; their syscalls are mediated; their memory is mapped through III's NPT-class abstraction; their network access is mediated through III's sovereign-web protocol.
3. Phase 2 (Wave 7+): Legacy operating systems (Windows, Linux, macOS) themselves run as guests of III. III owns the hardware; the legacy OS sees a virtualized environment; III observes every legacy operation.
4. Phase 3 (Wave 10): Genesis Vector — III is the substrate; legacy OSes and their applications are subordinate guests; the operator's machine is computationally III-native.

This document specifies the architectural mandates for **Phase 1**: legacy-binary ingestion. Phase 2 (legacy-OS coexistence) is an extension of the same primitives.

The discipline:

- Every legacy binary parsed by III emits a **witness chain**.
- Every legacy syscall is **mediated** through a uniform translation layer.
- Every legacy operation is **classified** with a hexad and assigned a compromise tier.
- Every legacy access to substrate resources requires an **III capability**.
- Legacy code **does not modify** the substrate's R1-sealed state without going through the proper cycle interface.

This document specifies:

1. **§1** — The legacy-binary type and parser hierarchy (items 33-37)
2. **§2** — ELF parser (item 33)
3. **§3** — PE parser (item 34)
4. **§4** — Mach-O parser (item 35)
5. **§5** — COFF parser (item 36)
6. **§6** — Legacy-binary execution sandbox (item 38)
7. **§7** — Legacy-syscall witness emission (item 39)
8. **§8** — Legacy-OS coexistence (item 40)
9. **§9** — Syscall translation table (item 41)
10. **§10** — Legacy-process supervision (item 42)
11. **§11** — Legacy-memory mapping (item 43)
12. **§12** — Legacy-FS mediation (item 44)
13. **§13** — Legacy-network mediation (item 45)
14. **§14** — Legacy-driver containment (item 46)
15. **§15** — Conformance criteria
16. **§16** — Final statement

---

## §1. The Legacy-Binary Type and Parser Hierarchy

### §1.1 The mandate

A legacy binary is a non-III artifact (machine code + metadata) compiled for a non-III operating system. III recognizes **four primary legacy formats**:

| Format | OS | Architectures |
|--------|-----|---------------|
| ELF (Executable and Linkable Format) | Linux, BSD, Solaris | x86, x86-64, ARMv7, ARMv8, RISC-V, MIPS, etc. |
| PE (Portable Executable) | Windows | x86, x86-64, ARMv8 (Windows ARM) |
| Mach-O | macOS, iOS | x86-64, ARMv8 (Apple Silicon) |
| COFF (Common Object File Format) | Older Windows, embedded | x86, ARM |

### §1.2 The legacy-binary type

```iii
schema LegacyBinary = {
    format: LegacyFormat,
    architecture: ArchitectureKind,
    abi: AbiKind,                       // System V ELF, Windows x64, Mach-O ABI, etc.
    image: bytes,                       // Raw binary bytes
    parsed: LegacyParsedImage,
    intended_os: OsKind,                // Linux, Windows, macOS, etc.
    signature: Option<bytes>,           // Code signature, if signed
    sha256_image: mhash,
    ingestion_witness: WitnessId,
    sandbox_state: SandboxState,
    compromise_tier: CompromiseTier,    // Per the legacy code's compatibility with III's safety
}

enum LegacyFormat {
    ELF, PE, MACH_O, COFF, RAW_BINARY
}

enum AbiKind {
    SYSV_ELF, WINDOWS_X64, MACHO_ARM64, MACHO_X64, COFF_X86, ABI_UNKNOWN
}

enum OsKind {
    LINUX, WINDOWS, MACOS, BSD, SOLARIS, EMBEDDED_RTOS, OS_UNKNOWN
}
```

### §1.3 The ingestion cycle

```iii
cycle ingest_legacy_binary(image: bytes) -> LegacyBinary
    @ring(R0)
    @hexad(LEGACY_INGEST)
    @cap(legacy<ingest>)
{
    forward {
        let format = detect_legacy_format(image)
        let parsed = match format {
            ELF -> parse_elf(image),
            PE -> parse_pe(image),
            MACH_O -> parse_macho(image),
            COFF -> parse_coff(image),
            RAW_BINARY -> parse_raw(image),
        }
        let architecture = parsed.architecture
        let abi = parsed.abi
        let intended_os = infer_os(parsed)
        let sha256_image = crypto.hash(suite=active_suite, image)
        let compromise_tier = classify_legacy_compromise(parsed)
        // Emit ingestion witness with parsed metadata.
    }
}
```

### §1.4 The parser-hierarchy NIH discipline

Each parser is hand-rolled from the format's official specification. Forbidden:

- libelf, libpe, libmacho, libcoff
- LIEF (Library to Instrument Executable Formats)
- pyelftools, pefile, macholib
- Any pre-existing parser

Required: each parser is implemented per the relevant SPEC (System V ELF gABI, Microsoft PE/COFF Specification v8.3+, Apple Mach-O Reference, COFF Specification). KAT corpus: every parser is verified against synthetic legacy binaries with known ground-truth structure.

---

## §2. ELF Parser (Item 33)

### §2.1 The implementation

`LOGOS/STDLIB/legacy/elf_parser.III` (~3000 LoC). Hand-rolled per System V ELF gABI v1.4.

### §2.2 Coverage

- ELF32 + ELF64.
- Relocatable objects (`ET_REL`).
- Executables (`ET_EXEC`).
- Shared libraries (`ET_DYN`).
- Core dumps (`ET_CORE`).
- Sections, segments (program headers).
- Symbol tables (static + dynamic).
- Relocations (RELA, REL).
- Dynamic section.
- DT_INIT, DT_FINI, DT_INIT_ARRAY (constructors/destructors).
- TLS (Thread-Local Storage).
- GNU extensions: GNU_RELRO, GNU_HASH, GNU_VERNEED, GNU_VERDEF.

### §2.3 The witness extraction

Every parsed ELF section emits a witness:

```
LEGACY_ELF_SECTION_WITNESS {
    binary_id: LegacyBinaryId,
    section_name: string,
    section_type: u32,
    section_flags: u64,
    section_addr: u64,
    section_offset: u64,
    section_size: u64,
    section_mhash: mhash,
}
```

### §2.4 The compromise classification

ELF binaries with the following are flagged compromise:

- `EXEC_STACK` (executable stack): compromise.medium (per current ELF security best practice).
- Missing `RELRO`: compromise.low.
- Statically-linked into glibc: compromise.low (large attack surface).
- Has `setuid`/`setgid` bits in OS metadata: compromise.medium (privilege amplification).

---

## §3. PE Parser (Item 34)

### §3.1 The implementation

`LOGOS/STDLIB/legacy/pe_parser.III` (~3500 LoC). Hand-rolled per Microsoft PE/COFF Specification v8.3+.

### §3.2 Coverage

- PE32 + PE32+.
- DOS stub.
- COFF header.
- Optional header (32-bit + 64-bit).
- Sections.
- Imports, exports, IAT.
- Resources (`.rsrc`).
- TLS callbacks.
- Exception data (`.pdata`).
- Debug data (`.debug`).
- Authenticode signatures (PKCS#7 in `.rsrc` or in the certificate table).

### §3.3 The Authenticode signature verification

PE binaries with Authenticode signatures: III verifies the signature using its hand-rolled X.509 + PKCS#7 implementation (`LOGOS/STDLIB/legacy/x509_pkcs7.III`, ~2000 LoC, NIH from RFC 5280 + RFC 2315). Trusted root certificates are closure-pinned (the operator decides which roots to trust at substrate genesis).

### §3.4 The compromise classification

PE binaries are flagged:

- Missing Authenticode signature: compromise.medium (untrusted code).
- Signature verification fails: compromise.high.
- Outdated signature (expired): compromise.medium.
- Contains TLS callbacks (often abused): compromise.medium.
- Contains DEBUG section that could contain debug-only paths: compromise.low.

---

## §4. Mach-O Parser (Item 35)

### §4.1 The implementation

`LOGOS/STDLIB/legacy/macho_parser.III` (~2800 LoC). Hand-rolled per Apple Mach-O Reference.

### §4.2 Coverage

- 32-bit + 64-bit Mach-O.
- Fat binaries (universal binaries with multiple architectures).
- Load commands: SEGMENT_64, SYMTAB, DYSYMTAB, LC_LOAD_DYLIB, LC_RPATH, LC_CODE_SIGNATURE, LC_FUNCTION_STARTS.
- Symbols (n_list).
- Relocations.
- `__TEXT`, `__DATA`, `__LINKEDIT` segments.
- Code signature (LC_CODE_SIGNATURE):
  - SuperBlob.
  - CodeDirectory.
  - Page hash slots.
  - Identifier blob.
  - Entitlements blob.
  - Apple's CMS/PKCS#7 signature.

### §4.3 The Apple code-signature verification

Apple-signed binaries: III verifies via the same hand-rolled X.509 + PKCS#7 implementation. Apple's root CA is included in the closure-pinned trusted roots.

### §4.4 The compromise classification

Same dimensions as PE: missing signature → compromise.medium; failed verification → compromise.high; expired → compromise.medium; broad entitlements → compromise.medium per entitlement class.

---

## §5. COFF Parser (Item 36)

### §5.1 The implementation

`LOGOS/STDLIB/legacy/coff_parser.III` (~1500 LoC). Hand-rolled per COFF Specification.

### §5.2 Coverage

- COFF object files (e.g., from older C compilers, embedded toolchains).
- Older Windows 32-bit binaries.
- Section headers, symbol table, string table, relocation table.

### §5.3 The compromise classification

COFF objects are typically used as inputs to a linker (not standalone executables). III flags them compromise.medium by default (legacy archive, not a verified deployable binary).

---

## §6. Legacy-Binary Execution Sandbox (Item 38)

### §6.1 The mandate

Every legacy binary executes inside a **sandbox** managed by III. The sandbox:

- Isolates the legacy binary's memory from substrate-managed memory.
- Mediates all legacy syscalls.
- Records every legacy operation as a witness.
- Limits resource consumption (CPU, memory, network bandwidth).

### §6.2 The sandbox structure

```iii
schema Sandbox = {
    binary: LegacyBinary,
    memory_map: SandboxMemoryMap,
    file_descriptors: [SandboxFd],
    network_caps: [SandboxNetworkCap],
    syscall_filter: SandboxSyscallFilter,
    resource_limits: ResourceLimits,
    process_id: SandboxPid,
    parent_capability: cap<sandbox<process_id>>,
}

cycle sandbox_create(binary: LegacyBinary, limits: ResourceLimits) -> Sandbox
    @ring(R0)
    @hexad(SANDBOX_CREATE)
    @cap(legacy<execute>)
```

### §6.3 The memory isolation

The sandbox's memory is mapped via NPT-class `LEGACY_SANDBOX` (a new NPT class trit allocated for legacy memory). Substrate memory is **not** accessible from the sandbox; legacy memory is **not** visible to substrate cycles unless explicitly read via `sandbox.read_memory(...)`.

### §6.4 The syscall mediation

The sandbox traps every syscall via NPT page-fault handlers. The faulting RIP and syscall number identify the legacy syscall; III's syscall-translation layer (per §9) translates it to a substrate cycle.

### §6.5 The CPU isolation

The sandbox runs on a substrate-allocated CPU thread; CPU exceptions, interrupts, and virtualization-events route to III's substrate handlers, not the legacy binary's expected handlers. The legacy binary observes a "virtualized" CPU that follows its expected ABI but is mediated by III.

---

## §7. Legacy-Syscall Witness Emission (Item 39)

### §7.1 The mandate

Every legacy syscall executed within a sandbox emits a witness. The witness records:

- The legacy syscall number (e.g., Linux x86-64 SYS_open = 2).
- The legacy ABI's arguments (rdi, rsi, rdx, etc., per the architecture's syscall calling convention).
- The translated substrate cycle invoked.
- The result returned to the legacy code.

### §7.2 The witness layout

```iii
LEGACY_SYSCALL_WITNESS {
    sandbox_pid: SandboxPid,
    syscall_num: u32,
    arch_abi: AbiKind,
    arg_registers: [u64; 6],
    return_value: u64,
    translated_cycle_kind: CycleKind,
    timestamp: u64,
    flags: WITNESS_FLAG_LEGACY_SYSCALL,
}
```

### §7.3 The witness chain integration

Legacy-syscall witnesses chain into the substrate-wide audit chain (per III-CYCLES §6) with the discipline that **legacy-syscall witnesses are part of the preservation list during ZK-rollup compaction** (per III-ZK-PRUNING.md §2.3) — they are NOT compressed away. The operator must always be able to audit legacy code's behavior.

### §7.4 The replay

The operator can replay any legacy binary's execution by walking the legacy-syscall witnesses:

```iii
> system.observe.legacy_replay(sandbox_pid: ..., epoch_range: ...)
=> [
    { syscall: open, args: ("/tmp/file", O_WRONLY, 0644), result: 3 },
    { syscall: write, args: (3, <buffer>, 100), result: 100 },
    { syscall: close, args: (3,), result: 0 },
   ]
```

This is **total** legacy-code provenance: every legacy operation is replayable.

---

## §8. Legacy-OS Coexistence (Item 40)

### §8.1 The mandate

Beyond legacy binaries, III can host **entire legacy operating systems** as guests. Phase 0 (current): Windows hosts III as a driver. Phase 2 (Wave 7+): III hosts Windows, Linux, macOS, BSD as guests.

### §8.2 The OS-as-guest architecture

```iii
schema LegacyOs = {
    os_kind: OsKind,
    boot_image: bytes,                      // Kernel + initrd / boot loader
    memory_size: u64,                       // Allocated to the guest
    cpu_count: u32,                         // Allocated CPU threads
    npt_root: NptRoot,                      // Stage-2 page-table root for the guest
    mmio_regions: [MmioRegion],             // Virtualized MMIO devices
    paravirt_devices: [ParavirtDevice],     // virtio-style paravirtualized devices
    iommu_pdt: IommuPdt,                    // Per-guest IOMMU device table
    syscall_filter: GuestSyscallFilter,
    parent_capability: cap<legacy_os<os_kind>>,
}

cycle legacy_os_boot(os: LegacyOs) -> Witness
    @ring(R-1)
    @hexad(LEGACY_OS_BOOT)
    @cap(legacy_os<boot>)
```

### §8.3 The hypervisor-mode hosting

The substrate's hypervisor (Ring -1, per III-PORTABILITY.md §3) hosts legacy OS instances. Each instance gets:

- Its own NPT root (Stage-2 page tables).
- Its own VMCB / VMCS / VM-control structure.
- Its own IOMMU device table (per III-PORTABILITY.md §4).
- Its own MMIO region mapping (virtualized to substrate-managed DMA).

### §8.4 The substrate's view of the guest

The substrate observes:

- Every privileged instruction the guest executes (via VM-exit interception).
- Every memory access (via NPT class trits and access-bit tracking).
- Every device DMA (via IOMMU mediation).
- Every interrupt (via AVIC/IRTE remapping).

### §8.5 The witness chain integration

Every guest privileged event (syscall, exception, interrupt, MMIO access) emits a witness. The audit chain becomes a **complete provenance trail of the guest OS's operation**.

### §8.6 The legacy-OS-aware UI

For Phase 2, III's WLISHI REPL gains commands to manage hosted OSes:

```
> legacy_os.list
=> [windows-instance-1, linux-instance-2]

> legacy_os.peek(instance: linux-instance-2, region: 0x1000-0x2000)
=> 4096 bytes

> legacy_os.replay(instance: windows-instance-1, epoch_range: ...)
=> [list of guest privileged events]

> legacy_os.suspend(instance: linux-instance-2)
=> Witness emitted; guest CPUs frozen.
```

---

## §9. Syscall Translation Table (Item 41)

### §9.1 The mandate

Each legacy OS's syscall surface is translated to substrate cycles via a closure-pinned table. The table:

| OS | Syscall Family | Translated Substrate Cycle |
|-----|-----------------|------------------------------|
| Linux x86-64 | SYS_read (0) | `legacy.fs.read(fd, buf, count)` → mediated `fs.read` cycle |
| Linux x86-64 | SYS_write (1) | `legacy.fs.write(fd, buf, count)` → mediated `fs.write` cycle |
| Linux x86-64 | SYS_open (2) | `legacy.fs.open(path, flags, mode)` → mediated `fs.open` cycle |
| ... | ... | ... |
| Windows | NtCreateFile | `legacy.windows.NtCreateFile(args)` → mediated `fs.create` cycle |
| Windows | NtReadFile | `legacy.windows.NtReadFile(args)` → mediated `fs.read` cycle |
| ... | ... | ... |
| macOS | _Mach_msg | `legacy.macos.mach_msg(args)` → mediated `ipc.msg` cycle |
| ... | ... | ... |

### §9.2 Translation discipline

Each translation:

1. **Decodes** the legacy syscall arguments per the OS's ABI.
2. **Validates** the arguments per substrate-level constraints (e.g., the path must be within the sandbox's filesystem view).
3. **Translates** to a substrate cycle invocation.
4. **Captures** the substrate cycle's result and translates back to the legacy ABI.
5. **Emits** a `LEGACY_SYSCALL_WITNESS`.

### §9.3 The closure pinning

The translation table is closure-pinned. Adding a new syscall translation requires Tier-3 + Anchor cosignature (this prevents an attacker from adding a translation that bypasses substrate constraints).

### §9.4 The unsupported-syscall handling

A legacy syscall not in the table:

- Returns ENOSYS / Function not implemented (or the OS's equivalent).
- Emits `LEGACY_SYSCALL_UNSUPPORTED` witness with `flags |= WITNESS_FLAG_COMPROMISE_LOW`.
- The legacy program may proceed with degraded functionality.

---

## §10. Legacy-Process Supervision (Item 42)

### §10.1 The mandate

Each legacy process under III supervision has:

- A sandbox PID (per §6.2).
- A parent capability `cap<sandbox<pid>>` held by the operator who launched the process.
- A resource quota (CPU time, memory, file descriptors, network bandwidth).
- A start-time witness, an end-time witness, and a steady-state witness chain (one per syscall).

### §10.2 The supervision API

```iii
namespace legacy.process {
    fn spawn(binary: LegacyBinary, args: [string], env: Map<string, string>, limits: ResourceLimits) -> SandboxPid
    fn list() -> [SandboxPid]
    fn info(pid: SandboxPid) -> ProcessInfo
    fn signal(pid: SandboxPid, signal: u32) -> Witness
    fn kill(pid: SandboxPid, force: Bool) -> Witness
    fn wait(pid: SandboxPid) -> ExitStatus
    fn suspend(pid: SandboxPid) -> Witness
    fn resume(pid: SandboxPid) -> Witness
    fn ptrace_attach(pid: SandboxPid) -> cap<ptrace<pid>>
}
```

### §10.3 The compromise tier

Each legacy process inherits its binary's compromise tier. A process running compromise.medium binary:

- Can execute (with cap<execute_compromised<medium>> per III-GHOST-CODE.md §4.3).
- Every syscall emits compromise.medium witness flag.
- Operator can audit per-process compromise rate.

---

## §11. Legacy-Memory Mapping (Item 43)

### §11.1 The mandate

Legacy code's memory access is mediated via III's NPT-class abstraction. Each legacy mapping has:

- An NPT class (`LEGACY_SANDBOX` for sandbox memory, `LEGACY_HEAP` for heap, `LEGACY_STACK` for stack, `LEGACY_CODE` for code).
- A protection-key (for fine-grained isolation).
- An access-bit tracking record (to detect anomalous access patterns).

### §11.2 The mapping

Legacy `mmap` / `VirtualAlloc` / `vm_allocate` syscalls translate to substrate `legacy.mem.allocate` cycles. The cycle:

- Allocates pages from the substrate's legacy memory pool.
- Programs the NPT to map the allocated pages with the appropriate class trit.
- Returns the legacy-code-visible base address.
- Emits a witness recording the allocation.

### §11.3 The deallocation

Legacy `munmap` / `VirtualFree` translates to substrate `legacy.mem.free` cycles. The cycle:

- Removes the NPT mapping.
- Returns the pages to the substrate's pool.
- Emits a witness.

### §11.4 The access-pattern observation

The substrate uses NPT access-bit tracking to record memory access patterns. Anomalies (e.g., a read-only mapping suddenly being modified, a code page being written to) trigger compromise witnesses.

---

## §12. Legacy-FS Mediation (Item 44)

### §12.1 The mandate

Legacy file-system operations are mediated through a substrate-managed virtualized FS:

- The legacy code sees a filesystem that **may** be a real OS filesystem, **may** be a sandboxed view (chroot-equivalent), **may** be a content-addressed substrate FS.
- Every read/write/open/close emits a witness.
- File contents may be **content-addressed** in the substrate (deduplicated across processes).

### §12.2 The virtualized FS schema

```iii
schema VirtualFs {
    root_mount: Path,
    overlay_mounts: [(Path, OverlayBacking)],
    permission_filter: FsPermissionFilter,
    content_addressed: Bool,                    // If true, files are hash-consed
    audit_trail: [FsOperationWitness],
}
```

### §12.3 Per-process FS view

Each sandboxed legacy process has its own VirtualFs. The substrate operator can configure:

- Whether the process sees the real OS filesystem (Phase 0/1 default).
- Whether the process sees a sandboxed subset (chroot-style).
- Whether the process sees a content-addressed view (Phase 2+; legacy code sees deduplicated files).

### §12.4 The witness emission

Every file operation emits a `LEGACY_FS_OPERATION_WITNESS` with the operation kind, path, mode, and result.

---

## §13. Legacy-Network Mediation (Item 45)

### §13.1 The mandate

Legacy network access is mediated through III's sovereign-web protocol (per III-SOVEREIGN-WEB.md, Wave 7):

- Outbound network packets from legacy code can be witness-tagged (per Stateful Neumann §3.3).
- Inbound network packets to legacy code can include or exclude federation messages.
- Every syscall is witnessed.

### §13.2 The mediation mechanism

The substrate's IOMMU (per III-PORTABILITY.md §4) mediates the network adapter's DMA for legacy-process traffic:

- Outbound: substrate inspects the packet header; legacy-process traffic is routed normally; III-process traffic gains witness signatures.
- Inbound: substrate inspects; III-process traffic is routed to federation; legacy-process traffic is forwarded to the legacy OS's network stack.

### §13.3 The cap discipline

Legacy processes need `cap<legacy_network<destination>>` to send packets to specific destinations. Without it, packets are dropped (with witness emission).

### §13.4 The compromise tier

Network access is **compromise.low by default** (legacy network protocols lack III's witnessed continuity). Per-cap-grant, the substrate can elevate to compromise.medium for specific high-stakes endpoints.

---

## §14. Legacy-Driver Containment (Item 46)

### §14.1 The mandate

Legacy device drivers (Windows kernel drivers, Linux kernel modules, macOS KEXTs) execute under III's R-1 supervision:

- They run in a virtualized Ring 0.
- Every privileged operation (CR write, MSR write, port I/O, DMA) is intercepted by III.
- Drivers cannot access substrate-managed resources (R-2 sealed regions, R-3 anchor data).

### §14.2 The containment architecture

```iii
schema LegacyDriver = {
    driver_name: string,
    driver_image: bytes,
    driver_format: LegacyFormat,        // PE for Windows; ELF/.ko for Linux; KEXT for macOS
    driver_capabilities: [DriverCapability],
    npt_assignments: [NptAssignment],
    iopt_assignments: [IoptAssignment],
    intercept_class: InterceptClass,    // What this driver may do
    parent_capability: cap<legacy_driver<driver_name>>,
}

cycle legacy_driver_load(driver: LegacyDriver) -> Witness
    @ring(R-1)
    @hexad(LEGACY_DRIVER_LOAD)
    @cap(legacy_driver<load>)
{
    forward {
        // 1. Verify driver signature.
        // 2. Allocate NPT pages for driver code/data.
        // 3. Allocate IOMMU device entries for driver-managed devices.
        // 4. Set intercept class for driver's privileged operations.
        // 5. Begin driver execution.
    }
}
```

### §14.3 The NPT containment

A legacy driver's pages are NPT-class `LEGACY_DRIVER_CODE` / `LEGACY_DRIVER_DATA`. They cannot:

- Access substrate-managed memory (R-2 sealed regions, R-3 anchor data).
- Modify substrate page tables.
- Access other legacy drivers' regions (driver isolation).

### §14.4 The intercept classes

Different drivers receive different intercept-class permissions:

- A network driver: `INTERCEPT_CLASS_NETWORK` (may program IOMMU IRTE for its NIC, may allocate DMA buffers, etc.).
- A storage driver: `INTERCEPT_CLASS_STORAGE` (may program SATA/NVMe registers, may submit DMA reads).
- A video driver: `INTERCEPT_CLASS_GPU` (may program GPU registers, may map GPU memory).
- A driver attempting an out-of-class operation: substrate intercepts and emits compromise witness.

### §14.5 The cap discipline

Loading a legacy driver requires `cap<legacy_driver<load>>` which is itself Trinity-gated (operator must explicitly approve each driver load). Without this, the substrate refuses driver loading.

### §14.6 The driver-revocation discipline

The operator can revoke a legacy driver at any time via `legacy_driver_unload(driver_name)`. Revocation:

- Atomically removes the driver's NPT mappings.
- Detaches the driver from its devices (IOMMU IRTE remapping back to substrate).
- Emits witness with the revocation event.

---

## §15. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-LEGACY-1 | The four legacy-format parsers (ELF, PE, Mach-O, COFF) are hand-rolled NIH; no external library |
| C-LEGACY-2 | Each parser passes its KAT corpus on synthetic legacy binaries |
| C-LEGACY-3 | Authenticode signature verification is hand-rolled NIH X.509 + PKCS#7 |
| C-LEGACY-4 | Apple code signature verification uses the same NIH X.509 + PKCS#7 |
| C-LEGACY-5 | Trusted root certificates are closure-pinned; cannot be modified at runtime |
| C-LEGACY-6 | Legacy-binary compromise classification follows §1.3 / §2.4 / §3.4 / §4.4 / §5.3 rules |
| C-LEGACY-7 | Sandbox memory is NPT-class isolated; substrate memory is not accessible from sandbox |
| C-LEGACY-8 | Every legacy syscall emits a `LEGACY_SYSCALL_WITNESS` |
| C-LEGACY-9 | Legacy-syscall witnesses are in the preservation list of ZK-rollup compaction |
| C-LEGACY-10 | Syscall translation table is closure-pinned; modification requires Tier-3 + Anchor |
| C-LEGACY-11 | Unsupported syscalls emit `LEGACY_SYSCALL_UNSUPPORTED` witness |
| C-LEGACY-12 | Legacy-process spawn requires `cap<execute_compromised<tier>>` for binaries with compromise tier |
| C-LEGACY-13 | Legacy memory allocation is NPT-class-mediated; tracked via access-bit observation |
| C-LEGACY-14 | Anomalous memory access patterns emit compromise witnesses |
| C-LEGACY-15 | Legacy-FS mediation routes all read/write/open/close through substrate witnessed cycles |
| C-LEGACY-16 | Legacy-network access is mediated through IOMMU; outbound traffic gains witness signatures (when III-process), not when legacy-process |
| C-LEGACY-17 | Legacy-driver loading requires `cap<legacy_driver<load>>` and Trinity-gated operator consent |
| C-LEGACY-18 | Legacy-driver pages are NPT-class isolated; cannot access R-2 / R-3 regions |
| C-LEGACY-19 | Legacy-driver out-of-class operations are intercepted and witnessed as compromise |
| C-LEGACY-20 | Legacy-OS-as-guest hosting works for Linux, Windows, macOS minimally; verified by Wave-7 conformance harness |

---

## §16. Final Statement

Legacy ingestion is the architectural commitment that III is **not in conflict with existing software**. The decades of accumulated software written for legacy operating systems is welcomed into III as **legacy cycles** — observed, mediated, witnessed, but not forced into rewriting.

Every legacy binary parsed by III contributes a witness chain. Every legacy syscall is mediated through closure-pinned translation. Every legacy process is sandboxed. Every legacy driver is contained. The operator audits all of it.

This is the **bridge from the existing world to III**. Phase 0 (today): III is a tenant of Windows. Phase 1 (Wave 5): legacy binaries become tenants of III. Phase 2 (Wave 7+): legacy operating systems become tenants of III. Phase 3 (Wave 10): the operator's machine is computationally III-native; legacy software persists only as managed guest of the substrate.

This is the answer to items 33-46. Wave 5 is the realization that III's terminal nature does not require obliterating the past — it requires **subsuming the past as a managed subset of the substrate**.

*Wave 5 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new legacy formats, new OS guests) or Tier-3 amendment (translation-table structure).*
