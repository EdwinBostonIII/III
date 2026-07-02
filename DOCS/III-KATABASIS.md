# III KATABASIS — The Sovereign Descent
### III Beneath Running Windows: a deterministic, witnessed, reversible descent through Rings 3 → 0 → −1 (→ −2), built on CHARIOT's verified launchpad, re-founded entirely in III

> **Status:** ARCHITECTURE / PLAN ONLY — no implementation yet. (Per the directive: design exhaustively first.)
> **Author pass:** /architect · /brainstorming · /creative-solve · /code-review · /deep-think
> **Date:** 2026-05-23 (substrate-local)
> **Companion artifacts:** `Resources/Assets.txt` (Part II = CHARIOT salvage), `Resources/Value-Inventory.txt` (the [III✦] re-forge of CHARIOT's lower-ring ideas), `DOCS/III-CONSTANTS.md`, `DOCS/III-XII.md`, `DOCS/III-HEXAD.md`.
> **Source of truth for CHARIOT facts:** `C:\Users\Edwin Boston\OneDrive\Desktop\CHARIOT\` (the FOUNDATION/HYPERVISOR/SOV/BUILD/LINK/TOOLS generation that holds `sma_address_map.h` + the platform driver — distinct from `C:\CHARIOT` and the plain-Desktop TRAMPOLINE generation). **Every fact in PART 0 was read in that source on 2026-05-23; provenance and the proven-vs-designed status are recorded honestly.**

---

## 0. PREFACE — WHY THIS DOCUMENT EXISTS, AND WHAT IT IS NOT

CHARIOT spent months learning, byte by byte, how to descend beneath a running Windows on **this exact machine** — an ASUS Zephyrus Duo (Ryzen 9 7945HX + RTX 4090 Laptop). It collected real, verified hardware addresses; it proved it could read and write GPU MMIO under the OS; it built a ~10 KB kernel driver exposing ~90 IOCTLs from PCI-config reads up to a single-shot bluepill VMRUN; it recorded — the hard way, with a real BSOD — exactly which bytes brick the machine. That knowledge is a launchpad no amount of cleverness could re-derive from datasheets.

This plan does **not** propose to port CHARIOT, nor to trust it. CHARIOT was born in a system that tolerated heuristics, nondeterminism, and "good enough." III is the opposite gamble: every component curated to deterministic, bit-identical, witnessed, proven perfection — never ML, never a guess that is right half the time and lying the rest. So the task is a **re-forge**: take CHARIOT's verified *facts* and hard-won *techniques*, keep only what is reliable, and rebuild the descent so that its safety is **mathematically necessary** rather than carefully engineered — emitted by III's own compiler, expressed in III's own primitives, and made a **force multiplier** for III without betraying one tenet.

The proof-of-worth thesis (developed in PART 8): the descent is the severest possible test of III's brutal methodology, and therefore its severest possible vindication. At Ring −1/−2 a single wrong byte reboots the machine (PART 0 §0.6 documents exactly that). Only a system whose every operation is hexad-typed so a bricking write is *unrepresentable*, SID-reversible so every touch carries its own undo, witnessed so every step is replayable, and capability-named so authority cannot be ambient — only such a system can live at the metal *reversibly and provably*. CHARIOT could take the machine. III can take it **and always give it back, with a proof**.

---

# PART 0 — THE VERIFIED LAUNCHPAD (read from CHARIOT source, 2026-05-23)

Everything below is transcribed from the actual files. Where a value is unverified or a capability is only designed (not proven live), it is marked **[TBD]** or **[DESIGNED/STUB]**. This part is the auditable evidence base; the architecture in Parts 1–8 may use only what is marked **[PROVEN]** as load-bearing, and must treat **[DESIGNED/STUB]** items as work to be re-derived and proven III-native.

## 0.1 The machine (verified 2026-04-11 off live silicon)

- **Platform:** ASUS Zephyrus Duo. **CPU:** AMD Ryzen 9 7945HX (Zen 4, 16C/32T → `cpu_count = 32`). **GPU:** NVIDIA RTX 4090 Laptop (AD103).
- **GPU PCI identity:** VEN `0x10DE`, DEV `0x2717`, REV `0xA1`, at **PCI Bus 1, Dev 0, Func 0**. `NV_PMC_BOOT_0 = 0x193000A1` (AD103 rev A1). 76 SMs. 16376 MB VRAM. PTHERM ≈ 40 °C.
- **Provenance:** "REAL addresses from PCI config space read via Ring −1 CF8h/CFCh, verified 2026-04-11" (`FOUNDATION/sma_address_map.h`).

## 0.2 The physical address map (the "database")  — `FOUNDATION/sma_address_map.h`

| Region | Physical base | Size | Notes |
|---|---|---|---|
| GPU BAR0 (MMIO regs) | `0xFB000000` | `0x1000000` (16 MB) | NV control registers |
| GPU BAR1 (VRAM aperture) | `0xF800000000` | **[TBD — needs BAR sizing]** | device memory; writes harmless to host kernel |
| GPU BAR3 (RAMIN/instance) | `0xFC00000000` | `0x2000000` (32 MB) | GPU contexts |
| GPU BAR5 (legacy VGA I/O) | `0xF000` | — | I/O port |
| CPU LAPIC | `0xFEE00000` | `0x1000` | x86 standard |
| CPU SMU | `0x03B00000` | `0x10000` | via SMN indirect (write `0x60`, read `0x64`, PCI cfg of root complex) |

**AD103 MMIO register offsets (within BAR0, verified from Ring −1 reads):** `PMC_BOOT_0`=`0x000000`, `PMC_ENABLE`=`0x000200`, `PTHERM_SENSOR`=`0x020008`, `PTIMER_LOW/HIGH`=`0x009400/0x009410` (independent ns oscillator), `CLOCK_DOMAIN`=`0x040000`, **GSP Falcon `MAILBOX0/1`=`0x110040/0x110044` (read/write PROVEN)**, `PGSP_MAILBOX(i)`=`0x110804+4i`, `QUEUE_HEAD(i)`=`0x110C00+8i` (observed `QUEUE_HEAD(0)=0x1000018` → GSP live), `FALCON_ENGINE`=`0x1103C0`, `VBIOS_BASE`=`0x300000` (AA55 sig; BIT table at `+0x1B2`), `RUNLIST_BASE`=`0x820000`, `RUNLIST_SM_COUNT`=`0x820014` (=76).
**PCIe discipline:** GPU reads memory in 128-byte cache lines → all shared CPU↔GPU structures `__attribute__((aligned(128)))`.

**CPU MSR catalogue (read in driver IOCTL docs, `LINK/sma_pe_emit_platform.h`):** `HWCR`=`0xC0010015` (SMM_LOCK bit 0, SMBASE_LOCK bit 1), `SMM_BASE`=`0xC0010111`, `SMM_ADDR`=`0xC0010112` (TSeg base), `SMM_MASK`=`0xC0010113`, `VM_CR`=`0xC0010114` (LOCK bit 3, SVMDIS bit 4), `VM_HSAVE_PA`=`0xC0010117`, `EFER`=`0xC0000080` (SVME bit 12), `LSTAR` (Windows syscall RIP → reveals kernel text base), `IA32_BIOS_SIGN_ID` (microcode version), `PATCH_LEVEL`=`0x8B`. **TPM** TCG TIS @ `0xFED40000`. **PSP** at PCI bus0/dev8/fn1, mailbox window `0x10500..0x105FF`. **ACPI SMI_CMD** port `0xB2`.

**Software SMA regions (the `.sov`-era software address space in the *same* `sma_address_map.h`, lines ~310–651) — re-forge INSPIRATION, NOT verified physical hardware:** the header also lays out CHARIOT's *software* SMA space for the (abandoned) `.sov` ring modules, including `ADDR_TEMPORAL_NPT_BASE = 903000000` ("speculative fork," 512 slots, `sma_temporal_npt`) **@903M** and `ADDR_SIDE_CHANNEL_BASE = 906000000` ("side-channel defense," 256 slots, `sma_side_channel_obs`) **@906M** (CHARIOT's address-map comments count in decimal megabytes). These are **software** addresses, not silicon — the plan adopts only the *ideas* (a speculative-fork region → III's NPT-CoW `temporal_npt`, §3.2/§5.1; a side-channel observation region, §7 R10), never the `.sov` code (ADR-001).

## 0.3 The software MMU (the reversible-memory primitive) — `sma_address_map.h` + `HYPERVISOR/sma_npt.c`

- 4-level radix MMU (`SmaMmu`), x86-64 compatible. PTE flags: `PRESENT`(b63), `WRITABLE`(b62), **`COW`(b61)**, `DIRTY`(b60), PFN mask `0x000FFFFFFFFFF000`. "On bare metal these become real NPT entries via the hypervisor."
- **NPT copy-on-write (`SmaNptCow`)** — **[PROVEN in software-emulation; bare-metal path writes the real VMCB NPT]**: `snapshot(range)` = mark range COW; first write → `cow_fault` allocates a shadow page, copies the original, and records `SmaNptShadowEntry{ original_phys, shadow_phys, virt_addr, fault_tick, active }`. **This is reversible memory: the shadow IS a witnessed pre-image; rollback is a swap-back.** Shadow pool exhaustion is counted, not faulted.

## 0.4 The platform driver — `LINK/sma_pe_emit_platform.{c,h}` (the R0 surface)

- **`chariot_platform.sys`**: thin **~10 KB PE32+** kernel driver, emitted byte-by-byte by `sma_pe_emit_platform.c` (no .sov compile; intelligence loaded at runtime). `IMAGE_BASE = 0x140000000` (**lesson:** `0x10000` is user-mode VA → W11 26100 idle BSOD `0x50 PAGE_FAULT_IN_NONPAGED_AREA`). Pool tag `'CPLT'`. Version **1.14**.
- **SVM region (256 KB), fixed layout** — **memorize, it is load-bearing for safety (§0.6):**
  `VMCB@0x0` · `HOST_SAVE@0x1000` · `NPT@0x2000`(32 KB) · `GUEST_CODE@0xA000` · `MSRPM@0xB000` · `IOPM@0xC000` · `ML_STATE@0x10000`(64 KB) · `SHARED@0x20000`(128 KB) · `DIAG@0x3F000`. **HV dispatcher state** at `HV_STATE@0x3E000` (counters + flags `lower_requested`/`hoist_arm_flag` + witness-pulse slots + 14×Q64 guest-GPR persistence + SMI-intercept slots + 16-entry revocation registry). **Guest cell pool** = 128 × 256 B at `SHARED+0x10000` (NPT identity-mapped). **Field cells** = module mem 512 KB ÷ 2048 × 256 B, coordinate-addressed `(coord & 0x7FF)`; cell 2047 = loaded-bitmap gate (FIELD_EXEC refuses an unloaded cell).
- **The IOCTL surface, ~90 codes `0x222100..0x222268`** (the capability ladder, each a hard-won win):
  - **R0 metal:** `VERSION`,`INFO`,`READ/WRITE_SHARED`,`READ_DIAG`; `PCI_CFG_READ`(CF8h/CFCh), `PHYS_PEEK`(MmMapIoSpace ≤4 KB), **`WRITE_PHYS`/`WRITE_MMIO` (MDL-based MMIO read/write any phys — PROVEN)**, `RDMSR`(whitelist RAPL+TSC), `WRMSR_WHITELISTED`(PerfEvtSel/Ctr), `SILICON_SNAPSHOT`(atomic TSC+CPUID+8 RDMSRs), `CHIP_IDENTITY`(CPUID 64-byte fingerprint), `SOVEREIGN_INIT`(SME/SEV/SNP/QoS probe), `TPM_STATUS`(TIS probe), `PQOS_CONFIGURE/ACTIVATE`(L3 cache COS islands), `WORKER_START/STOP`(persistent kernel worker pinned to CPU 31, COS 15), `WITNESS`(FNV-1a pulse chain).
  - **R−1 hypervisor:** `INIT_SVM`/`CLEANUP_SVM`, `HV_PROBE`, `NPT_PROTECT`/`NPT_EXPAND`(→128 GB, 1 GB pages), `HV_VMSAVE`, `HV_SEGMENT_CAPTURE`(LAR/LSL/SGDT/SIDT/MOV-DR), **`HV_VMCB_ZERO/VMSAVE/CTRL/SEGS/SCALARS/READ` (6-step incrementally byte-verified VMCB build)**, `VMRUN_COORD`/`VMRUN_COORD_CHAIN`(8-hop code-crystal dispatch at silicon speed)/`VMRUN_COORD_SLOT`, `HV_HOIST_RUN`(single-shot VMRUN — "the dangerous instruction"), `HV_HOIST_LOOP`/`HV_HOIST_LOOP_V2`(loop + host-register scrub), `HV_STATS`/`HV_LOWER`/`HV_ARM`, `HV_WITNESS_CHAIN`.
  - **R−2 reconnaissance (observe, not replace):** `HV_SMI_PROBE`(SVM #SMI intercept — observes Ring-2 SMM **without** replacing AMI's signed handlers; auto-disarm after first), `HV_SMM_STATUS`(SMM MSRs/lock state), `HV_SMRAM_PROBE`(read TSEG; D_LCK→graceful fail), `HV_MSR_SURVEY`(12-MSR basket incl. LSTAR), `HV_SMI_TRIGGER`(software SMI via 0xB2), `HV_PSP_PROBE`/`HV_PSP_SEND`(PSP mailbox).
  - **Write primitives (footguns):** `HV_MSR_WRITE`(arbitrary WRMSR), `HV_MEM_WRITE`(arbitrary phys write), **`HV_MSR_WRITE_PROBE` — the safe-write technique: runs the WRMSR inside a throwaway SVM guest so a `#GP` becomes `VMEXIT_EXCP_13` caught by the host; the host never faults.**
  - **Self-verification (SVS):** `HV_READ_SELF`(copy own `.text` for external SHA-256), **`HV_LIVE_VERIFY`(driver hashes its own `.text` with NIH SHA-256 emitted into `.text`, returns digest → detects PatchGuard/HVCI/hostile tamper).**
  - **Capability kernel (Aegis v10, 24+1 IOCTLs):** `CAP_BOOTSTRAP/REVOKE/SUBDIVIDE/QUORUM_ISSUE/TIME_LOCK_ISSUE/ANTI_INSTALL/ROOT_QUERY/DESCENT_QUERY/REFLECT/NIZK_PROVE/NIZK_VERIFY/COINAGE_ISSUE/STREAM_APPEND`, `RING_TRANSITION_WITNESS`, `RING_QUORUM_ATTEST`, `TPM_TAKEOVER_INIT`, `SMM_SOVEREIGN_INSTALL`, `BCD_HV_DISABLE`, `NESTED_L1_INIT`, `DRTM_SKINIT`, `RING_MINUS_FOUR_WITNESS`, `RING_PLUS_FOUR_JOIN/MESSAGE`, `CAP_QLCC_PREFETCH`. Each capability-gated handler verifies a 32-byte token against an embedded ring master key (mismatch → `STATUS_ACCESS_DENIED`).
- **Crash forensics:** the DIAG region is a 256-entry ring buffer; every driver function writes `{function_id, proof_hash (FNV-1a chain), timestamp (rdtsc)}` on entry → the executing function at crash time is identifiable post-mortem.

## 0.5 The descent implementations (techniques to re-forge)

- **Nested-L1 bluepill** (`BUILD/hv/sma_hv_nested_l1.c`) — **[DESIGNED, hashed template]**: when `CPUID(0x40000000)="Microsoft Hv"` and BCD eviction fails, become an L1 guest under Hyper-V's L0 (NESTED_CTL.npt_enable=1, g_pat inherited, ~5 % per-VMEXIT overhead, still controls L2). Init template = hand-assembled bytes (rdmsr VM_CR → test SVMDIS → set EFER.SVME → program VM_HSAVE_PA to a private region); blob SHA-256'd under tag `HV_NESTED_L1_v10`.
- **DRTM SLB** (`BUILD/drtm/sma_drtm_slb.c`) — **[DESIGNED; representative 64 KiB head + zero-pad + tail, hashed]**: SKINIT lands CPL0/paging-off → set segments → suspend APs (APIC ICR `0xFEE00300` ← `0x00054500` broadcast-INIT) → extend TPM PCR17 (TIS `0xFED40000`, tpmGo `0x40`) → install sovereign SMM handler at `SMM_BASE+0x8000` → set `SMM_BASE=0x30000` → lock `D_LCK` → return frame to OS. Hashed under `DRTM_SLB_v10`.
- **Ring −2 SMM handler** (`BUILD/smm/sma_smm_handler.c`) — **[DESIGNED/STUB, KNOWN LATENT BUG]**: ~3 KB position-independent payload, sub-code dispatch (0x80 witness_pcr / 0x81 read_smram_audit / 0x82 cap_root_publish / 0x83 cap_revoke_broadcast / 0x84 ring_minus_four_witness). **Recorded bug:** `48 83 F8 imm8` (cmp rax,imm8) sign-extends sub-codes 0x80..0x85 negative → never matches → always epilogue. Not wired live. Must be re-assembled (`3C imm8` or `48 3D imm32`) with recomputed offsets before going live.
- **TPM 2.0 takeover** (`BUILD/tpm/sma_tpm_takeover.c`) — **[DESIGNED, real wire format]**: `TPM2_Clear` (Platform Hierarchy auth) → `TPM2_CreatePrimary` (2048-bit RSA SRK, Storage Hierarchy); deterministic command byte templates; AMI platform-auth candidate list (empty / SHA256("PLATFORM") / SHA256("AMI_PLAT_AUTH_v2"), from observed Promontory-21 X670E behavior).
- **Ring −4 silicon witness** (`BUILD/ring/sma_ring_minus_four.c`) — **[DESIGNED, observe-only by principle]**: witnesses microcode patch level (MSR `0x8B`) + PSP firmware (PSP MMIO `0x10500`) each transition, extends a shadow PCR, cross-checks `AegisAnchor.silicon_fingerprint`; mismatch → `CAP_SILICON_DRIFT` freezes the capability kernel. **Principle: "CHARIOT does not WRITE Ring −4 (AMD signs microcode); CHARIOT WITNESSES Ring −4."**
- **Silicon census** (`HYPERVISOR/sma_hv_silicon_census.c`) — **[PROVEN methodology]**: vendor-aware, hand-assembled CPUID/MSR probes across an 8-slot Ring-1 substrate. Pass 1 vendor-agnostic (CPUID.0 vendor, CPUID.1 ECX Intel-VMX bit 5, CPUID.80000001 ECX AMD-SVM bit 2, CPUID.40000000 hypervisor sig, CR4, EFER SVME, CPUID roundtrip TSC cost); Pass 2a Intel VMX MSRs / Pass 2b AMD SVM MSRs — **"AMD-only MSRs are NEVER loaded on Intel and vice versa; the vendor check is explicit so the driver cannot #GP into a BSOD on mistaken vendor."** RBX preserved across every CPUID. This is the deterministic, fault-avoiding enumeration that produced §0.1/§0.2.

## 0.6 The hard-won failure data (the safety constraints)

- **BSOD post-mortem 2026-04-26** (`BUILD/accel/POSTMORTEM_BSOD_2026-04-26.md`): a test wrote 16 bytes via `HV_MEM_WRITE` to **SVM offset `0x1000` = the AMD Host Save Area** (mistakenly believed "away from header"); the next VMRUN/VMEXIT restored garbage segment selectors → **BugCheck `0x1` APC_INDEX_MISMATCH**, reboot ≈ 15 s later (because only intercepted ops trigger VMEXIT). **Rules extracted:** (1) SVM `0..0x20000` is hypervisor-critical — never write from outside the driver; only `SHARED 0x20000..0x40000` is safe. (2) `HV_MEM_WRITE` is a footgun; the only known-safe targets are AD103 **BAR0/BAR1/BAR3** (writes contained within the GPU, harmless to host kernel). (3) The allowlist (`BAR0 0xFB000000..0xFC000000`, `BAR1 0xF800000000..0xF900000000`, `BAR3 0xFC00000000..0xFC02000000`, deny otherwise) lives **in userspace**, validated *before* the IOCTL — the driver stays a generic primitive. (4) **The system was reboot-survivable**: `chariot_platform.sys` text-hash intact → clean reboot, fresh HSAVE; the crash was transient state, not persistent damage.
- The earlier `IMAGE_BASE` lesson (§0.4) is the same family: a wrong constant at the metal = a reboot.

## 0.7 The verification methodology + collected data

- **Probe DSL** (`TOOLS/probe/catalog/*.probe`, `BUILD/deploy/probe_dsl_parser.c`, `probe_runner.c`, `check_probe_matrix_complete`): declarative `[case.X]` blocks — `ioctl=`, `safety_class=`, `tag=`, `in.<field>.{kind,value,offset}`, `out.expected_{size,status}`, `out.<field>.{kind,value,offset}`; adversarial cases assert `BLOCKED_IOCTL` (out of `[0x222100,0x222268]`) and `BLOCKED_BAR` (a SAFE case smuggling `0xF800000000` in InBuf — "exactly the pattern that BSOD'd"). **Honest status:** the DSL + catalog + safety verdicts + aggregate are real; **`probe_runner_execute` is a structural stub** (returns the expected status; the live `DeviceIoControl` path is described in-comment but not committed). The actual hardware proofs came from `query_hv_gpu.exe` + the bisection rig, not this runner.
- **Collected data files (to mine during implementation, not yet read byte-by-byte):** `LINK/encode/apm_corpus.json` (AMD-APM instruction-encoding corpus — feeds the x64 encoder), `BUILD/accel/calibration.bin` + `calib_cache_*.bin` (per-GPU-op timing calibration), `BUILD/phase6_results.json`, `BUILD/aegis7/aegis_catalog.json` (the ~40 Aegis machine-code checks), `BUILD/chariot_hv_baremetal.bin` (a built bare-metal HV image), `BUILD/chariot_platform.selfdesc.bin` (platform self-description).

## 0.8 The honest ledger — what is PROVEN vs DESIGNED

| Capability | Status | Load-bearing for the plan? |
|---|---|---|
| GPU/CPU address map (§0.1–0.2) | **PROVEN** (verified 2026-04-11) | YES — the census crystal |
| MDL-bypass MMIO read + write | **PROVEN** | YES |
| BAR1 VRAM read · GSP mailbox live · VBIOS found · Vulkan dispatch | **PROVEN** | YES — GPU coprocessor |
| PCI cfg / PHYS_PEEK / MSR survey / SILICON_SNAPSHOT / silicon census | **PROVEN** | YES — the deterministic census |
| NPT-CoW reversible memory | **PROVEN (sw-emul); bare-metal designed** | YES — the reversibility multiplier |
| 6-step VMCB build + VMRUN single/loop/coord/chain | **PROVEN** | YES — the R−1 cycle |
| `HV_MSR_WRITE_PROBE` safe-write-in-guest | **PROVEN technique** | YES — the determinism-safety pattern |
| `HV_LIVE_VERIFY` self-attestation | **PROVEN** | YES — measured-launch seed |
| Capability kernel (token-gated IOCTLs) | **PROVEN (gating); algebra partly designed** | YES (re-forged to III caps) |
| Nested-L1 (Hyper-V coexistence) | **DESIGNED (hashed template)** | re-derive + prove |
| DRTM SLB (SKINIT) | **DESIGNED (representative blob)** | re-derive + prove |
| SMM sovereign handler (R−2 install) | **DESIGNED/STUB + latent bug** | LOWEST priority; re-found from scratch |
| TPM 2.0 takeover | **DESIGNED (real wire fmt)** | optional, late |
| Ring −4 microcode/PSP | **OBSERVE-ONLY by principle** | YES — witness only, never write |
| Probe runner live execution | **STUB** | re-forge as witnessed cycle |

> **Architectural rule (binding):** anything not **PROVEN** above is a hypothesis until III re-derives it and proves it III-native (a corpus/KAT/probe-cycle that passes deterministically). The plan never assumes a DESIGNED item works; it schedules its proof.

---

# PART 1 — REQUIREMENTS

## 1.1 The one-sentence goal

Give III a **deterministic, witnessed, reversible, capability-gated, NIH** presence beneath running Windows — Ring 0 (kernel driver) and Ring −1 (hypervisor), optionally observing Ring −2/−4 — emitted by III's own `iiis`/`cg_r0`/`cg_rm1`, expressed entirely in III's primitives (the canonical XII term, the witness chain + `algebraic_time`, the hexad, capabilities, crystals, the resolver, SID inverses, content-addressing, the Forge), such that this vantage **multiplies** III's power while betraying none of its tenets — and is thereby the severest proof that III's methodology was worth it.

## 1.2 Functional requirements

```
FR-1  Emit a III-native Ring-0 platform driver (the "III Gate") via cg_r0 — a thin PE32+ .sys —
      whose every IOCTL is a witnessed, hexad-typed, capability-gated CYCLE (not a raw primitive).
      ACCEPTANCE: load on the Zephyrus Duo; HV_LIVE_VERIFY-equivalent self-hash matches the sealed
      closure-root; a deterministic probe-cycle suite passes; clean unload; reboot-survivable.

FR-2  Read the machine deterministically (PCI cfg, MMIO via MDL, MSR survey, CPUID census) and fold
      the result into a single witnessed "Silicon Census Crystal" bound to the node's genesis lineage.
      ACCEPTANCE: two runs on the same machine produce a byte-identical census crystal; the crystal
      re-verifies by replay; the AD103/Ryzen facts of §0.1–0.2 reproduce exactly.

FR-3  Reversible memory: a III "snapshot" of a guest/physical range is a witnessed pre-image (NPT-CoW
      shadow), and "rollback" restores it — making SID inverses and ripple re-seal LITERAL at the page level.
      ACCEPTANCE: snapshot → mutate → rollback yields byte-identical memory; the pre-image is a crystal
      in the witness chain; replaying the witness reproduces both the mutation and its inverse.

FR-4  Emit a III-native Ring-1 hypervisor (the "III Floor") via cg_rm1 that virtualizes the running OS
      (bluepill), under or beside Hyper-V, controlling NPT, intercepting a MINIMAL deterministic set of
      VMEXITs, each handled by a witnessed cycle. The image IS its own proof (closure-root + per-fn hexad).
      ACCEPTANCE: VMRUN/VMEXIT round-trips deterministically; the 6-step VMCB build is reproduced as ONE
      sealed term; no host fault on any DESIGNED write (all writes go through the safe-write-in-guest law).

FR-5  Run III code at silicon speed beneath the OS as witnessed "descent cycles" (the re-forge of
      VMRUN_COORD/CHAIN): a canonical XII term is emitted to a guest cell and executed under nested paging;
      its result + cycle count + VMEXIT cause are folded into the witness chain.
      ACCEPTANCE: a code-crystal chain runs and returns; the run is replayable and content-addressed;
      the same term yields the same bytes + same witness on the same silicon.

FR-6  Observe (never overreach): Ring −2 (SMM activity, via intercept-observe — NOT handler replacement)
      and Ring −4 (microcode/PSP version) are WITNESSED into the chain; drift freezes the capability kernel.
      ACCEPTANCE: an SMI is observed and witnessed without replacing AMI handlers; a (simulated) microcode
      drift triggers a deterministic CAP_SILICON_DRIFT freeze; III never writes a signed/locked layer.

FR-7  The GPU becomes a WITNESSED COPROCESSOR: III drives AD103 BAR0/BAR1/GSP (the proven paths) for
      manifold-compilation/parallel work, with every dispatch a capability-gated, witnessed cycle and the
      result proven equivalent to the sequential path (manifold-compilation equivalence cert).
      ACCEPTANCE: a GPU dispatch returns a result proven byte-equal to its CPU computation; the dispatch is
      witnessed; writes are confined to the BAR0/BAR1/BAR3 allowlist by hexad, not by a userspace check alone.

FR-8  Verification-as-cycles: re-forge the probe DSL so a "probe" is a deterministic, replayable, hexad-
      safety-gated GHOST-PHASE cycle (observed, not performed) that leaves a witness; the safety verdicts
      (BLOCKED-by-hexad, BLOCKED-by-capability) are mathematical, not a userspace allowlist alone.
      ACCEPTANCE: the §0.7 adversarial cases (bad IOCTL, BAR-in-input) are rejected by construction; the
      probe suite is reproducible and its pass/fail is a witnessed, gradeable artifact.

FR-9  The whole descent is FORGED: the driver/HV images, the IOCTL/cycle surface, the census schema, and
      the address map are single-source artifacts generated + drift-pinned by the Sovereign Forge, signed
      by the Founders-Anchor, measured at launch (xii_sml-equivalent), and re-checked at runtime (xii_atm).
      ACCEPTANCE: editing any source regenerates consumers; a drift fails the build; the loaded image's
      measured hash equals the sealed closure-root or it refuses to run.
```

## 1.3 Non-functional requirements (III tenets as hard gates)

| Category | Requirement | Target / law | Measurement |
|---|---|---|---|
| **Determinism** | Bit-identity | Same source → byte-identical driver/HV image; same silicon → byte-identical census + descent-cycle output | twin-build + reproducibility-check; the determinism gate (ADR-027) |
| **Witnessedness** | Total | Every privileged op emits a witness fragment; `algebraic_time` advances only via the hook | witness-chain replay; no op without a fragment |
| **Provenness** | Proof-carrying | Every emitted image carries its closure-root + per-fn hexad; descent cycles carry SID inverses | hexad admission; Curry-Howard via cic; live self-hash |
| **Bricking-impossibility** | Structural | A write to a hypervisor-critical / signed / locked region is **hexad-unrepresentable**, not guarded | the hexad bricking proof extended to physical-write trits; §0.6 target made impossible |
| **Reversibility** | Total | Every descent touch has a pre-materialized SID inverse; NPT-CoW backs it physically | snapshot→mutate→rollback byte-identity |
| **Capability** | No ambient authority | Every metal op names the exact address/MSR/port term it touches; attenuating tokens | cap verification at every cycle; NIZK where crossing trust |
| **NIH** | Absolute | Only libc + III BOOT headers on the host; the driver/HV is III-emitted machine code; SHA-256/ed25519 are III's `numera` | dependency audit; no third-party in the closure |
| **No ML / no learning** | Absolute | Descent decisions are total functions of the verified census + hexad; the "immune system" = replay-divergence, never an anomaly score | no count-and-promote / observe-and-adapt anywhere |
| **Safety latency** | Reboot-survivable | A worst-case bug is transient: image text-hash intact, fresh state on reload | the §0.6 survivability property preserved by construction |

## 1.4 Constraints

```
TECHNICAL
- Host: this exact Zephyrus Duo (Ryzen 9 7945HX + RTX 4090 AD103). The verified addresses are machine-bound;
  the census MUST re-derive them, never hard-code blindly (silicon-fingerprint binding, not assumption).
- AMD SVM path is primary (this is an AMD machine); Intel-VMX is a future census branch (the census is
  vendor-explicit so it never #GPs on the wrong vendor).
- Windows 11 26100 is the running OS; Hyper-V may be present (→ nested-L1 coexistence path).
- The emitted driver must satisfy Windows kernel-module loading (the cg_r0 backend already emits DriverEntry,
  IRQL discipline, ntoskrnl imports, .pdata/.xdata) — and ONLY Ke*/Mm*/Io*/Rtl* + III substrate symbols, no CRT.
- Signed-driver / HVCI / PatchGuard reality: address test-signing / DSE during R&D; the live-verify cycle
  detects HVCI/PatchGuard interference rather than fighting it.

IDEOLOGICAL (binding, non-negotiable)
- Not one III tenet may be bent for convenience. If a CHARIOT technique cannot be made deterministic /
  witnessed / reversible / hexad-safe / NIH, it is re-invented until it can be, or it is not adopted.
- Observe-don't-write the signed/locked/deepest layers (microcode, AMI SMM) — sovereignty in observation.
- The descent is a force MULTIPLIER for III's existing aims (the resolver, XII, the witness economy, the
  manifold), not a separate empire. Every lower-ring capability must feed an existing III system.

OUT OF SCOPE (explicit)
- No offensive use against any machine but the user's own; no third-party targeting; no malware behavior.
  This is sovereign systems R&D on the owner's hardware — a Type-1 hypervisor for III's own substrate.
- No CHARIOT cognition/AGI layers; no .sov/Gestalt; no borrowed hypervisor/driver code.
```

---

# PART 2 — ARCHITECTURE OVERVIEW

## 2.1 The governing idea: one invariant, repeated at every depth

CHARIOT's lower-ring code was a federation of ~90 independent IOCTLs, each a separately-engineered capability with its own ad-hoc safety. III replaces the federation with a single repeated **invariant**, the same one that already governs III at Ring 3:

> **Every privileged act — at any ring — is a witnessed, hexad-typed, capability-named, SID-reversible CYCLE: the deterministic projection of a canonical XII term.**

A "cycle" is III's existing atom (the CYCLES calculus, the witness chain, the hexad, SID inverse derivation). KATABASIS asserts that descending to Ring 0 / −1 / −2 does **not** introduce a new programming model — it *re-uses the Ring-3 model at lower privilege*. A PCI read, a VMRUN, an SMI observation, a microcode witness: each is a cycle with the identical five guarantees. This is the architectural spine. Everything else is the consequence of insisting on it at the metal.

The corollary is the safety thesis: because a cycle is hexad-typed, a *bricking* cycle (writing the Host Save Area, writing locked microcode, writing the SVM control region) is **structurally unrepresentable** — exactly as the six firmware-brick operations are unrepresentable in III's hexad algebra today (`HEXAD/src/hexad_pfs.c` defines the six PFS brick patterns; `HEXAD/tests/hexad_bricking_proof.c` proves exhaustively over all 729×729 = 531,441 hexad pairs that no admitted composition is ever a brick). The §0.6 BSOD is not "guarded against"; in III it cannot be expressed.

## 2.2 Systems-thinking context map

```
                         ┌──────────────────────────────────────────────────────┐
                         │  THE RUNNING ASUS ZEPHYRUS DUO  (external context)     │
                         │                                                        │
   ┌─────────────┐       │   Windows 11 26100  (the GUEST, once III descends)     │
   │  Operator   │──prose│   Hyper-V (maybe present → nested-L1 coexistence)      │
   │  (Ring 3)   │  +cap │   AD103 GPU · Ryzen 9 7945HX · TPM · PSP · SMM/AMI fw  │
   └──────┬──────┘       │        ▲                    ▲                ▲         │
          │ intent       │        │ MMIO/PCI/MSR        │ NPT/VMRUN      │ observe │
          ▼              │        │ (cycles)            │ (cycles)       │ (cycles)│
   ┌─────────────────────┴────────┴─────────────────────┴────────────────┴───────┐
   │                          III  (the SYSTEM, descending)                        │
   │   R3 III Daemon ──► R0 III Gate ──► R−1 III Floor ──► R−2/−4 III Deep (obs)    │
   │        │                │                │                    │               │
   │        └────────────────┴── one WITNESS CHAIN (algebraic_time) ───────────────┤
   │                                   │                                           │
   │                         Silicon Census Crystal  ◄── bound to genesis lineage  │
   └───────────────────────────────────┬───────────────────────────────────────────┘
                                        │ feeds
            ┌───────────────────────────┼───────────────────────────┐
            ▼                           ▼                           ▼
   the resolver / XII          the manifold (GPU)          the witness economy
   (a metal backend)        (a witnessed coprocessor)   (real joules / reversibility)
```

The machine is **external context**: III does not own it, it descends into it and observes/controls chosen slices reversibly. Windows becomes a *guest* only to the precise extent III chooses (and can always un-choose). The witness chain is the single spine threading every ring; the Census Crystal is the system's authoritative, replayable model of the silicon.

## 2.3 Quality-attribute trade-offs (and why III always picks the same side)

| Trade-off | Conventional pick | III's pick | Why |
|---|---|---|---|
| Determinism vs raw performance | performance | **determinism** | a non-reproducible metal op cannot be witnessed/replayed/proven; perf is recovered via XII curated paths + the GPU, not by surrendering bit-identity |
| Coverage vs safety | intercept broadly | **minimal deterministic VMEXIT set** | every interception is a cycle that must be proven reversible; fewer, total, proven beats many, partial |
| Capability vs convenience | ambient kernel power | **no ambient authority** | every metal op names its exact target term; the §0.6 footgun exists only where authority is ambient |
| Liveness vs reversibility | commit fast | **reversibility first** | a deploy/descent that cannot roll back is unrepresentable; the NPT-CoW pre-image makes rollback physical |
| Write vs observe (deepest layers) | take control | **observe-don't-write** microcode/AMI-SMM | sovereignty in observation; III witnesses signed/locked layers, never overreaches them |
| Generic primitive vs typed op | generic "write any phys" | **hexad-typed op** | a generic primitive is a footgun; a typed op makes the dangerous case unrepresentable |

There is no genuine trade here once the tenets are accepted: III resolves every tension toward determinism + reversibility + provability, and *recovers* performance and dynamism through the GPU coprocessor (§5.4), the XII curated paths, and the silicon-speed descent cycles (§3.3) — i.e. by being **more** rigorous, not less.

## 2.4 Pattern selection

| Pattern | Fit for KATABASIS | Verdict |
|---|---|---|
| Layered | privilege rings ARE layers (R3..R−4), with strict, lawful crossings | **adopt (as the privilege spine)** |
| Event-Driven / Event-Sourcing | every cycle is a witnessed event; the witness chain IS an event-sourced, replayable log; "rollback" = replay to a prior root | **adopt (the witness chain is event-sourcing done right)** |
| Hexagonal (ports/adapters) | the host OS / silicon is the "outside"; `sma_platform`-equivalent is the single port; everything above is pure cycle resolution | **adopt (the platform boundary is the one adapter)** |
| Modular Monolith | one sealed substrate, single closure-root, Forge-generated — not microservices | **adopt (one sealed image, not a fleet)** |
| CQRS | read-cycles (census/observe) and write-cycles (descend/snapshot) have very different safety classes | **adopt the split as a SAFETY distinction (reads are hexad-light; writes are NEG-gated)** |
| Microservices / Serverless | no — there is no network of services; there is one sovereign substrate at graduated privilege | reject |

**Selected pattern — the Witnessed Ring-Lattice:** a *layered* privilege lattice (R3≼R0≼R−1, with observe-only R−2/R−4), where (a) crossings occur only through the lawful ring-transition constructors of `PHASES/ring_lattice` (IOCTL, magic-MSR/VMMCALL, SKINIT, SMI), (b) every operation is an *event-sourced* witnessed cycle whose inverse is SID-derived, (c) the host/silicon is reached through a single *hexagonal* platform port, and (d) the whole thing is one Forge-generated, closure-pinned *modular-monolith* image. CQRS appears as the read/write **safety** split, not a scaling split.

Rationale: the ring lattice is not a metaphor here — it is the literal CPU privilege structure, and III *already* models it (`ring_lattice.c`, the cg_r3/r0/rm1/rm2 backends). KATABASIS is the realization of a model III already holds; the pattern is chosen because it already exists in the substrate and the hardware both.

## 2.5 The component triad (+ daemon + forge)

| Component | Ring | Responsibility (one sentence) | Emitted by |
|---|---|---|---|
| **III Daemon** | R3 | Resolve operator/system intents into descent cycles, hold the capability wallet, host the resolver/XII/manifold that *consume* the lower rings. | `iiis` → `cg_r3` (user PE) |
| **III Gate** | R0 | A thin kernel driver whose every IOCTL is a witnessed/hexad-typed/cap-named/SID-reversible metal cycle (read/write MMIO, PCI, MSR, census, snapshot, self-verify). | `iiis` → `cg_r0` (kernel .sys) |
| **III Floor** | R−1 | A minimal deterministic hypervisor: VMCB/NPT, the smallest proven VMEXIT set, the descent-cycle executor, NPT-CoW reversible memory. | `iiis` → `cg_rm1` (bare-metal image) |
| **III Deep** | R−2 / R−4 | Observe-only: witness SMM activity (intercept-observe, no handler replace) and microcode/PSP version; freeze on drift. Never writes a signed/locked layer. | `cg_rm1`/`cg_rm2` (observe stubs) |
| **III Forge** | build | Single-source generation + drift-pinning of the Gate/Floor images, the cycle/IOCTL surface, the census schema, the address map; Founders-Anchor signing; measured-launch + anti-tamper. | the Sovereign Forge (`.def` → consumers) |

Note the deliberate inversion of CHARIOT's layering: in CHARIOT the daemon was a thin caller and the driver held the intelligence (~90 IOCTLs). In III, the **Daemon holds the intelligence** (the resolver decides *which* cycle, the wallet decides *whether*), and the Gate/Floor are **minimal, dumb, proven executors** of pre-resolved, pre-witnessed cycles. The metal code is as small and as proven as possible; the cleverness lives where it can be reasoned about (Ring 3, in III). This is the NIH + bricking-impossibility discipline applied to layering: *the most dangerous code is the least clever.*

## 2.6 Master diagram

```
 ┌──────────────────────────────────────────────────────────────────────────────────────┐
 │ R3  III DAEMON  (cg_r3 PE)                                                              │
 │   resolver ─► "descend(intent)" ─► XII-canonical cycle term ─► hexad+cap+SID stamp      │
 │   capability wallet · the manifold scheduler · the witness-economy ledger               │
 └───────────────┬───────────────────────────────────────────────────────────────────────┘
                 │  IOCTL crossing  (the only R3→R0 door; carries a sealed cycle term + cap)
                 ▼
 ┌──────────────────────────────────────────────────────────────────────────────────────┐
 │ R0  III GATE  (cg_r0 .sys, ~10KB, IMAGE_BASE 0x140000000, self-hashing)                 │
 │   cycle dispatch ─► [ReadMetal | WriteMetal | MsrSurvey | Census | Snapshot |           │
 │                       SelfVerify | CapOp | →Descend]   each = a witnessed cycle          │
 │   SVM region (hexad-typed offsets) · diagnostic witness ring · NPT-CoW shadow pool       │
 └───────────────┬───────────────────────────────────────────────────────────────────────┘
                 │  magic-MSR / VMMCALL crossing  (R0→R−1; the "dangerous instruction", gated)
                 ▼
 ┌──────────────────────────────────────────────────────────────────────────────────────┐
 │ R−1 III FLOOR  (cg_rm1 image; the image IS its proof: closure-root + per-fn hexad)      │
 │   VMCB (one sealed term, not 6 IOCTLs) · NPT identity + CoW · ASID                       │
 │   minimal deterministic VMEXIT set {CPUID, MSR, NPF, VMMCALL, (SMI observe)}             │
 │   descent-cycle executor (VMRUN a code-crystal under nested paging, witnessed)           │
 │   ── reversible memory: snapshot=witnessed pre-image, rollback=CoW restore ──            │
 └───────────────┬───────────────────────────────────┬───────────────────────────────────┘
                 │ SMI intercept (observe)             │ MMIO/GSP (witnessed coprocessor)
                 ▼                                     ▼
 ┌───────────────────────────────┐      ┌──────────────────────────────────────────────────┐
 │ R−2/R−4 III DEEP (observe-only)│      │ AD103 GPU  (BAR0/BAR1/GSP — proven paths)         │
 │  SMM activity witnessed         │      │ witnessed manifold coprocessor (proven≡CPU)       │
 │  microcode/PSP witnessed→drift  │      │ writes confined to BAR0/1/3 by HEXAD, not a check │
 └───────────────────────────────┘      └──────────────────────────────────────────────────┘

   ════════════ ONE WITNESS CHAIN (sanctus/witness.iii + algebraic_time) threads all rings ════════════
   ════════════ ONE CENSUS CRYSTAL (the verified silicon model) bound to genesis lineage  ════════════
   ════════════ ONE CLOSURE-ROOT (Forge-sealed, Anchor-signed, measured at launch)        ════════════
```

## 2.6.1 The core invariants (binding on every later section)

1. **No op without a cycle.** There is no "raw write." Every metal touch is a cycle term; if it isn't a cycle, the Gate refuses it (there is no generic primitive surface exposed across the ring boundary).
2. **No cycle without a hexad.** The cycle's hexad classifies its danger; a structural-NEG (bricking) cycle is unrepresentable, so it cannot be emitted, let alone dispatched.
3. **No cycle without a capability.** The cycle names the exact term it touches (an address range, an MSR, a port, a BAR window); the wallet must hold an attenuated capability for *that term*; ambient authority does not exist.
4. **No cycle without an inverse.** SID derives the cycle's inverse and pre-materializes it (NPT-CoW pre-image for memory; the recorded prior MSR/register value for state) *before* the forward act; a cycle whose inverse cannot be derived is irreversible-typed and only admissible in the observe class.
5. **No cycle without a witness.** Every cycle emits a fragment (`witness_hook`); `algebraic_time` advances only through it; the chain root attests the whole descent and makes it replayable.
6. **No image without a seal.** The Gate/Floor images are content-addressed, Forge-generated, Anchor-signed, measured at launch, re-checked at runtime; a tampered image refuses to run.
7. **Observe ≠ write.** The deepest/locked/signed layers (microcode, AMI SMM, the SVM control region) are observe-class only; III witnesses them and freezes on drift; it never writes them.

These seven are the constitution of the descent. Parts 3–8 are their elaboration and proof.

# PART 3 — THE RE-FORGE CATALOGUE

Each entry: **[CHARIOT, verified]** what exists (Part 0 cite) → **[III cycle]** the re-forge → **[5 guarantees]** how the cycle is hexad/cap/SID/witness/seal-bound → **[enlargement]** what it becomes that the original was not. The re-forge collapses CHARIOT's ~90 IOCTLs + descent blobs into **nine cycle families** plus the data/seal substrate.

## 3.0 The reduction: ~90 IOCTLs → 9 cycle families

CHARIOT's IOCTL count grew organically (v1→v10, §0.4). III does not preserve the count; it preserves the *capabilities* and re-expresses them as nine hexad-distinguished cycle families. The Gate exposes exactly one cross-ring entry — `iii_gate_cycle(sealed_term, cap)` — and the family is *read from the term's kernel*, not from an IOCTL number. (Re-forge of `_dispatch_gen.c` + `_capability_table.c`: the dispatch switchboard becomes content-addressed resolution; the per-command permission becomes the cycle's named capability.)

| # | Family | Subsumes (CHARIOT IOCTLs, §0.4) | Hexad class | Inverse (SID) |
|---|---|---|---|---|
| F1 | **ReadMetal** | PCI_CFG_READ, PHYS_PEEK, READ_SHARED, READ_DIAG, HV_PROBE, SILICON_SNAPSHOT, RDMSR, HV_MSR_SURVEY, HV_SMM_STATUS, HV_SMRAM_PROBE, HV_PSP_PROBE | read-only (no structural NEG) | identity (reads are self-inverse) |
| F2 | **WriteMetal** | WRITE_PHYS, WRITE_MMIO, WRITE_SHARED, HV_MEM_WRITE, HV_MSR_WRITE, WRMSR_WHITELISTED | NEG-gated; admissible only for allowlisted target-terms | recorded prior value / CoW pre-image |
| F3 | **Census** | (composition of F1 over the silicon census payloads) | read-only | identity |
| F4 | **Snapshot/Reverse** | NPT_PROTECT, NPT_EXPAND, (NPT-CoW) | structural-positive (creates pre-images) | the CoW restore |
| F5 | **Descend** | INIT_SVM, the 6-step HV_VMCB_* build, HV_VMSAVE, HV_SEGMENT_CAPTURE, HV_HOIST_RUN/LOOP, VMRUN_COORD/CHAIN/SLOT | NEG-gated (the dangerous instruction) | VMEXIT + state restore; CoW for guest memory |
| F6 | **Observe** | HV_SMI_PROBE, RING_MINUS_FOUR_WITNESS, HV_PSP_PROBE(read), HV_STATS, HV_WITNESS_CHAIN | observe-only (cannot write) | identity (observation has no forward effect) |
| F7 | **SelfVerify** | HV_READ_SELF, HV_LIVE_VERIFY, HV_AEGIS_ROOT, HV_BOOT_GREETING | read-only | identity |
| F8 | **CapOp** | the 24 CAP_* IOCTLs, RING_*_WITNESS/ATTEST/JOIN | governance (Trinity-gated) | the capability's revoke/descent path |
| F9 | **CoprocDispatch** | (BAR0 doorbell + BAR1 pushbuffer writes, Vulkan path) | NEG-gated to BAR0/1/3 only | GPU-context restore / re-dispatch |

Everything dangerous (F2, F5, F9) shares **one law** — the safe-write gate (§3.9). Everything deep (F6) is observe-only by type. Reads (F1, F3, F7) are self-inverse and hexad-light. This nine-family table is the entire descent surface; the rest of Part 3 specifies each.

## 3.1 The driver → III Gate cycles  (re-forge of `sma_pe_emit_platform.c` + the IOCTL surface)

**[CHARIOT, verified §0.4]** A ~10 KB PE32+ driver, ~90 IOCTLs, generic primitives (incl. the `HV_MEM_WRITE` footgun), token-gated late additions. **[III cycle]** `cg_r0` emits a Gate of the *same ~10 KB class* (cg_r0 already emits DriverEntry, IRQL discipline, ntoskrnl imports, .pdata/.xdata, no CRT — §Value-Inventory §1), but it exposes **one** cross-ring entry that consumes a *sealed cycle term*. The Gate does not decide anything: it (1) verifies the term's Anchor seal + the caller's capability for the term's named target, (2) checks the term's hexad is admissible (a NEG-structural target → reject, by the same bitmap as `hexad_check.c`), (3) records the SID pre-image (prior value / CoW), (4) performs the minimal metal action, (5) emits the witness fragment, (6) returns. **[5 guarantees]** seal = the term is Anchor-signed and content-addressed; hexad = `hexad_check`-admitted (the §0.6 HSAVE write is unrepresentable because the SVM control region carries a structural-NEG, §4.7); cap = the wallet holds an attenuated cap for *exactly* the named address/MSR/port; SID = pre-image recorded before the act; witness = a fragment per cycle, folded into the chain. **[enlargement]** CHARIOT had a generic "write any phys" footgun guarded by a *userspace* allowlist (§0.6 forward plan); III has *no generic write* — only typed cycles whose dangerous targets are unrepresentable, so the allowlist is the hexad algebra itself, enforced in the kernel by construction, with the proof that no admissible composition reaches a brick (the bricking-pair theorem extended, §4.7). The driver stops being a pile of primitives and becomes a *minimal proven executor of pre-resolved cycles*.

## 3.2 NPT-CoW → physical SID / ripple  (re-forge of `sma_npt.c`)

**[CHARIOT, verified §0.3]** `SmaNptCow`: snapshot marks a range COW; first write faults, allocates a shadow, copies the original, records `SmaNptShadowEntry{original_phys, fault_tick, …}`. **[III cycle]** This is *already* SID inverse derivation made physical — III names it as such. A `Snapshot` cycle (F4) marks a guest/physical range CoW and the **shadow page becomes a crystal**: a content-addressed pre-image whose lineage is the witness chain, whose `fault_tick` is `algebraic_time`. A `Reverse` cycle restores it. **[5 guarantees]** the pre-image crystal is content-addressed (its hash IS its identity, so two snapshots of identical memory share a pre-image — echo); the snapshot/restore pair is one reversible cycle whose inverse is *the other direction of the same term*; every fault is witnessed; the shadow pool exhaustion is a hexad-bounded resource (the K-value / quota discipline applies). **[enlargement]** This is the **killer multiplier (§5.1)**: III's foundational promise "everything can be rolled back" — until now a software discipline — becomes **literally true at silicon speed at the page level**. A `ripple` re-seal (the change-propagation engine, Value-Inventory §20) backed by NPT-CoW means a whole-system change is a hardware-checkpointed, witnessed, atomic transaction: snapshot → apply across the dependency closure → on any K-underflow or contradiction, the CoW restore reverts every touched page byte-identically. Time-travel debugging, speculative execution with witnessed rollback, and `temporal_npt` (CHARIOT's "speculative fork" region, §0.2 address map @903M) all fall out of this one cycle.

## 3.3 VMRUN / the 6-step VMCB build → the Descent Cycle  (re-forge of `HV_VMCB_*`, `VMRUN_COORD/CHAIN`, `sma_hv_nested_l1.c`)

**[CHARIOT, verified §0.4–0.5]** The VMCB is built by six byte-verified IOCTLs (`HV_VMCB_ZERO/VMSAVE/CTRL/SEGS/SCALARS/READ`); `VMRUN_COORD` patches VMCB.RIP to a guest cell and runs; `VMRUN_COORD_CHAIN` chains up to 8 code-crystals at silicon speed; nested-L1 is a hashed template for Hyper-V coexistence. **[III cycle]** The six-step build becomes **one canonical XII term** — `vmcb := compose(zero, vmsave, ctrl, segs, scalars)` — emitted by `cg_rm1` and *byte-verified by confluence* (the XII critical-pair discipline guarantees the composition is order-independent and reaches one normal form), so "build the VMCB" is a single sealed artifact, not six fragile IOCTLs. A `Descend` cycle (F5) = "VMRUN this guest term": the guest is a code-crystal at a NPT-identity-mapped cell; the cycle's inverse is the VMEXIT + the captured guest state (HV_VMSAVE/SEGMENT_CAPTURE become the *inverse pre-image*). `VMRUN_COORD_CHAIN` becomes a **witnessed wavefront** (the CYCLES wavefront calculus, Value-Inventory §5): a chain of code-crystals whose interleave is fixed by witness order, replayable bit-for-bit, each hop a fragment. **[5 guarantees]** the VMCB term is sealed + hexad-typed (NEG-gated: VMRUN is the dangerous instruction, admissible only with a full pre-materialized host-state inverse); the cap names the guest cell + ASID; SID = the host state captured pre-VMRUN is the literal inverse; witness = every VMEXIT is a pulse (CHARIOT's HV_STATE witness-pulse slots, §0.4, become `witness_hook` fragments). **[enlargement]** CHARIOT ran code-crystals at silicon speed but with hand-built fragile VMCB state and a host-register leak it had to scrub (HV_HOIST_LOOP_V2, §0.4); III's descent cycle is *deterministic, replayable, and reversible by construction* — the same guest term yields the same VMEXIT trace + same witness on the same silicon, and the host can always be restored from the SID pre-image. The nested-L1 coexistence (run under Hyper-V) becomes a *resolved branch*: the census (F3) detects `CPUID(0x40000000)="Microsoft Hv"` and the resolver picks the nested descent term — deterministically, not by an ad-hoc check.

## 3.4 Silicon census → the Census Crystal  (re-forge of `sma_hv_silicon_census.c`, the address DB, `g_gpu_caps`)

**[CHARIOT, verified §0.5, §0.1–0.2]** Vendor-explicit CPUID/MSR probes ("AMD-only MSRs never on Intel — cannot #GP into BSOD"); the address map hand-maintained; `g_gpu_caps` populated once via driver IOCTLs with "proven" flags. **[III cycle]** A `Census` cycle (F3) is a *composition of ReadMetal cycles* over the vendor-explicit probe set, producing a single **Census Crystal**: a content-addressed value carrying the vendor, the verified addresses (the §0.1–0.2 table re-derived live, never hard-coded), the feature vector, and the "proven" flags — bound to the node's **genesis closure-root** (genesis.iii). **[5 guarantees]** read-only (no NEG); the cap is the read-census capability; identity inverse; each probe witnessed; the crystal sealed into the lineage. The vendor-explicit discipline becomes a **hexad property**: an AMD-only probe carries a hexad that is inadmissible on an Intel-vendor census term, so "cannot #GP on the wrong vendor" is *type-checked*, not a runtime branch. **[enlargement]** CHARIOT's address map was a header that could drift from reality (§Value-Inventory §11 "The Address Map as a Witnessed Census"); III's is a *witnessed measurement sealed into the node's identity* — two runs produce a byte-identical crystal, the crystal re-verifies by replay, and "the address that answered on THIS machine" is a fact in the lineage, machine-bound by `silicon_fingerprint` (cap binding to genesis-root, §Value-Inventory §7), not an assumption. The §0.1 facts (AD103 BAR0=0xFB000000, 76 SMs, etc.) are the *expected* crystal content; a deviation is `CAP_SILICON_DRIFT` (§3.6).

## 3.5 Probe DSL → witnessed ghost-probe cycles  (re-forge of the `.probe` catalog + `probe_runner.c`)

**[CHARIOT, verified §0.7]** A declarative `.probe` DSL (ioctl/safety_class/in/out asserts + adversarial BLOCKED_IOCTL/BLOCKED_BAR cases); the runner is a *structural stub*. **[III cycle]** A probe becomes a **ghost-phase cycle** (the "observed, not performed" primitive, Value-Inventory §6/B1): the probe term is run in ghost mode — it emits a real witness saying "this cycle WAS SEEN" and asserts the expected output shape — *without performing the privileged effect*, then (if it's a safe read) performs and checks. The safety verdicts become **type rejections**: `BLOCKED_BAR` (a write term naming a lethal address) is a NEG-structural hexad → unrepresentable; `BLOCKED_IOCTL` (a term outside the sealed cycle grammar) fails to parse as a cycle. **[5 guarantees]** the probe is itself a cycle (hexad-light for reads); the adversarial cases are rejected by construction; each probe witnessed; the suite's pass/fail is a gradeable, replayable, sealed artifact (the conformance discipline, Value-Inventory §23). **[enlargement]** CHARIOT's runner was a stub and its safety lived in a userspace allowlist; III's probe is a *real, deterministic, witnessed dry-run* whose safety is mathematical (a lethal probe cannot be expressed), and the whole probe suite is a witnessed conformance crystal — so "did the descent pass its safety matrix?" is answered by a sealed hash, reproducibly, on every build. The probe DSL is re-expressed as III cycle terms (no new language — probes are cycles), satisfying NIH and unifying verification with execution.

## 3.6 SMM / DRTM / TPM / Ring-4 → sealed Sanctum observe-cycles  (re-forge of `sma_smm_handler.c`, `sma_drtm_slb.c`, `sma_tpm_takeover.c`, `sma_ring_minus_four.c`)

**[CHARIOT, verified §0.5]** SMM handler (DESIGNED/STUB + latent sign-extension bug, not live); DRTM SLB (DESIGNED, SKINIT re-root + SMM install + PCR17); TPM takeover (DESIGNED, real TPM2 wire format); Ring-4 (observe-only microcode/PSP, drift→freeze). **[III cycle]** These are the deepest, least-proven layer, and III treats them with maximal restraint, governed by invariant #7 (observe ≠ write):
- **R−2 SMM = an `Observe` cycle (F6) only, initially.** III re-forges `HV_SMI_PROBE`: the Floor arranges VMCB SMI-intercept so an `#SMI` becomes a witnessed VMEXIT (a fragment recording tsc + source), auto-disarming after the first — III *witnesses* SMM activity, it does **not** replace AMI's signed handlers. The CHARIOT SMM handler (with its latent bug, §0.5) is **not adopted**; if a sovereign SMM handler is ever wanted, it is re-derived from scratch as a `cg_rm2`-emitted, hexad-typed, content-addressed term whose dispatch is XII-canonical (the sign-extension class of bug is unrepresentable because the dispatch is generated, not hand-assembled).
- **DRTM re-root = a sealed Sanctum (R−2) cycle.** Re-rooting trust (SKINIT) maps onto III's *existing* Sanctum: it is the most dangerous of the sealed-cycle-box operations (Value-Inventory §13, `sanctum.c`), performed through the 8-step sealed protocol the Trinity gate must admit, with the SLB content-addressed and the PCR17 extension *being* the witness-chain anchor (the measured launch, xii_sml). The SLB is not a representative blob; it is a Forge-generated, byte-verified term.
- **TPM = witnessed, not "taken over."** III uses the TPM as a *witness sink* (PCR extension = anchoring the closure-root in hardware) rather than clearing/re-owning it; the TPM2 command terms are deterministic and sealed, but the hierarchy-clear is gated behind an explicit, capability + Trinity + operator-quorum decision (it is destructive of the existing owner state, hence the highest gate).
- **R−4 = pure `Observe`.** III preserves CHARIOT's principle verbatim: witness microcode patch level (MSR 0x8B) + PSP firmware (PSP MMIO 0x10500) into the chain; a mismatch vs the Census Crystal's expected fingerprint is `CAP_SILICON_DRIFT` → the capability kernel freezes (a deterministic, witnessed reaction — *not* an anomaly score). **III never writes Ring −4.**

**[enlargement]** CHARIOT's deepest layer was a pile of designed-but-unproven, partly-buggy blobs. III's is a *disciplined observation surface* + (only if ever needed) a Forge-generated sealed-Sanctum re-root — every byte content-addressed, every observation witnessed, every drift a deterministic freeze, and the irreversible/destructive acts (SMM install, TPM clear) behind the highest Trinity + quorum + operator gates. The deepest descent is the *most* restrained, not the most reckless — which is exactly why it is trustworthy.

## 3.7 The capability kernel → III object-capabilities at the metal  (re-forge of the 24 `CAP_*` IOCTLs)

**[CHARIOT, verified §0.4]** 24 cap IOCTLs (bootstrap/revoke/subdivide/quorum/time_lock/anti/nizk/coinage/descent/reflect…), token = 32 bytes verified against an embedded ring master key. **[III cycle]** The metal capability surface becomes the **III object-capability algebra already designed in Value-Inventory §7** — capabilities are content-addressed hypostases, attenuation is the hexad subset-lattice, denial is sticky-NEG, freshness is the witness clock, membership/revocation are ZK-proof / ripple-over-lineage. A `CapOp` cycle (F8) mints/attenuates/revokes the capabilities that *gate every other cycle*: a `WriteMetal` to BAR0 requires a cap naming the BAR0 term; a `Descend` requires a cap naming the guest ASID; etc. **[5 guarantees]** governance-hexad (Trinity-gated); the cap algebra is the cap; SID = the revoke/descent path; witnessed; sealed. **[enlargement]** CHARIOT verified a token against an *embedded master key* in the driver (a secret to extract); III has *no embedded secret* — a capability is a content-addressed term re-derivable by anyone, attenuated by hexad, bound to the node's genesis-root, so "hold a cap" = "be able to re-derive it," and the entire 24-IOCTL algebra collapses into III's four capability laws (Value-Inventory §7) governing the metal exactly as they govern Ring 3. Authority at the metal is *the same authority* as everywhere else in III — one algebra, no special kernel-key.

## 3.8 The diagnostic ring buffer → the witness chain at the metal  (re-forge of the DIAG region)

**[CHARIOT, verified §0.4]** Each driver function writes `{function_id, proof_hash (FNV-1a chain), rdtsc}` to a 256-entry DIAG ring → post-mortem identifies the executing function at crash time. **[III cycle]** This *is* the witness chain, at the metal — III names it so. Every Gate/Floor cycle's entry/exit is a `witness_hook` fragment (the FNV-1a proof-chain becomes the SHA-256/Keccak running-root of `sanctus/witness.iii`); the DIAG ring is the on-chip tail of the one witness chain. **[enlargement]** Crash forensics stops being a separate ring buffer you parse post-mortem and becomes **witnessed replay** (Value-Inventory §15): the failing cycle is named by the last fragment, its inputs are content-addressed and reproducible, and "why did it fault?" is a deterministic lookup, not a dump autopsy. The §0.6 BSOD, in III, would have left a witness fragment naming the exact `WriteMetal` cycle and its target term — and that target term (HSAVE) would have been hexad-rejected before emission, so the fragment would say "rejected," not "executed."

## 3.9 The safe-write-in-guest → the universal Write Law  (re-forge of `HV_MSR_WRITE_PROBE`)

**[CHARIOT, verified §0.4]** `HV_MSR_WRITE_PROBE` runs a WRMSR inside a throwaway SVM guest so a `#GP` becomes `VMEXIT_EXCP_13` caught by the host — the host never faults. This is CHARIOT's single most III-aligned invention: *make a dangerous operation's failure deterministic and contained.* **[III cycle / law]** III elevates it from one IOCTL to a **universal obligation on the WriteMetal (F2), Descend (F5), and CoprocDispatch (F9) families**: any cycle whose hexad is NEG-gated (dangerous) and whose effect on the host cannot be proven safe by the census + allowlist is **first executed in a throwaway guest** (a one-shot Descend), where its fault becomes a witnessed VMEXIT, *before* it is ever performed against the host. The forward act runs against the host only if the guest probe returns clean. **[5 guarantees]** the probe-in-guest is itself a hexad-light Descend cycle; its outcome is witnessed; the host-side act is gated on the probe's clean witness; SID pre-image still recorded. **[enlargement]** This generalizes "test a write safely" into a *substrate law*: at the metal, III never performs an unproven dangerous write against the host directly — it proves it in a sacrificial guest first, deterministically, with the fault contained and witnessed. Combined with the hexad (which makes the *truly* lethal targets unrepresentable) and the NPT-CoW pre-image (which makes the merely-risky ones reversible), the §0.6 brick class is closed three ways: **unrepresentable** (hexad), **rehearsed-in-guest** (this law), and **reversible** (CoW). That triple is the architectural reason III can do what CHARIOT could only do carefully.

## 3.10 What is deliberately NOT re-forged

To honor "keep the best and the reliable" and reject the rest:
- The **CHARIOT SMM handler bytes** (latent sign-extension bug, never live) — not adopted; re-derived only if ever needed.
- The **embedded ring master key** in the cap kernel — rejected (no embedded secrets; content-addressed caps instead).
- The **userspace-only allowlist** as the *primary* write guard — demoted to defense-in-depth; the hexad is primary.
- The **~90-IOCTL sprawl** — collapsed to nine families + one entry.
- Any **.sov/Gestalt** descent code — not adopted; III emits via `cg_r0`/`cg_rm1` only.
- The **TPM hierarchy clear / takeover** as a default — demoted to a highest-gate, operator-quorum, optional act; III uses the TPM as a witness sink by default.

# PART 4 — RING-BY-RING DESCENT ARCHITECTURE

## 4.1 COMPONENT — III Daemon (Ring 3)

```
COMPONENT: III Daemon
RESPONSIBILITY: Resolve intents into sealed descent-cycle terms, hold the capability wallet,
                and host the III systems that CONSUME the lower rings (resolver, XII, manifold,
                witness-economy ledger). Decides WHICH cycle and WHETHER; never touches metal directly.
EMITTED BY: iiis → cg_r3 (ordinary user-mode PE)

INTERFACE (exposed to operator / III systems):
  + descend(intent, ctx) -> WitnessedResult        # resolve → cycle term → Gate → witnessed result
  + snapshot(range) / reverse(handle)              # reversible-memory front door (F4)
  + census() -> CensusCrystal                       # the verified silicon model (F3)
  + coproc(manifold_term) -> WitnessedResult        # GPU dispatch (F9), proven≡CPU
  + wallet: attenuate(cap, target) / revoke(cap)    # capability ops (F8)
  Events emitted: WitnessFragment (per cycle), DriftAlarm (census mismatch)
  Events consumed: OperatorIntent (prose via the resolver), GovernanceVerdict

DEPENDENCIES:
  - the resolver/HIP (intent → cycle term)         : Value-Inventory §18
  - the wallet (object-capabilities)               : §3.7
  - the witness chain + algebraic_time             : it reads the chain root; only the hook writes it
  - the III Gate (the one IOCTL crossing)           : §4.2

DATA:
  - Owns: the capability wallet, the manifold schedule, the witness-economy ledger
  - References: the Census Crystal (queries, does not own — the Gate/Floor produce it)

SCALABILITY/SAFETY:
  - Stateless across reboots except the wallet + the sealed closure-root (both reconstructable)
  - The MOST clever component (so it sits at the SAFEST ring); a Daemon bug cannot brick the machine
  - It is the ONLY place the allowlist/policy lives in addition to the kernel hexad (defense-in-depth)
```

The inversion (§2.5) is the key safety property here: cleverness at R3, dumbness at the metal. The Daemon's resolver decides; the Gate/Floor merely execute pre-sealed terms. A logic error in "which cycle to run" is a R3 bug (recoverable, witnessed); it can never be a brick, because the *kind* of cycle it can emit is hexad-bounded.

## 4.2 COMPONENT — III Gate (Ring 0 kernel driver)

```
COMPONENT: III Gate  (chariot_platform.sys's deterministic successor; ~10KB PE32+ .sys)
RESPONSIBILITY: Execute pre-sealed, pre-resolved metal cycles minimally and provably; verify
                seal+cap+hexad; record SID pre-image; emit witness; nothing else. The dumbest
                possible code at the most dangerous-to-be-wrong ring.
EMITTED BY: iiis → cg_r0  (DriverEntry, IRQL discipline, ntoskrnl imports, .pdata/.xdata, no CRT)
IMAGE_BASE 0x140000000 (NEVER 0x10000 — §0.4 lesson). Pool tag 'CPLT'. Self-hashing (.text SHA-256).

INTERFACE (the ONE cross-ring entry):
  + iii_gate_cycle(sealed_term, cap_token) -> {status, out_bytes, witness_fragment}
       step 1: verify sealed_term Anchor signature + content-address  (else REJECT_SEAL)
       step 2: verify cap_token attenuates to the term's named target  (else REJECT_CAP)
       step 3: verify term hexad ∈ admissible bitmap (hexad_check)     (else REJECT_HEXAD)
       step 4: derive+record SID pre-image (prior value / mark CoW)    (else REJECT_IRREVERSIBLE)
       step 5: perform minimal metal action (the family's primitive)
       step 6: emit witness fragment to the DIAG ring (= chain tail)
  Family primitives (the only metal the Gate knows): F1 ReadMetal · F2 WriteMetal · F3 Census
       · F4 Snapshot · F7 SelfVerify · F8 CapOp · (F5 Descend is delegated up to the Floor crossing)
  Events emitted: WitnessFragment; self-verify digest on demand
  Events consumed: iii_gate_cycle only

DEPENDENCIES:
  - hexad_check bitmap (compiled in, byte-identical to TYPES copy)   : §4.7
  - the SVM region (hexad-typed offsets)                            : §4.7
  - the NPT-CoW shadow pool (for F4)                                : §3.2
  - numera SHA-256 emitted into .text (for self-verify)             : §3.8
DATA:
  - Owns: the SVM region, the diagnostic witness ring, the NPT-CoW shadow pool, the revocation registry
  - References: the sealed term + cap (passed in), never policy
SAFETY:
  - Stateless re policy; reboot-survivable (text-hash intact → clean reload, fresh SVM)
  - Exposes NO generic primitive across the boundary — only typed cycles (invariant #1)
  - The §0.6 brick class is rejected at step 3 (REJECT_HEXAD) before any metal action
```

The Gate is the security kernel of the descent. Its correctness is small enough to audit line-by-line and prove in the disassembly (the CLAUDE.md crash-protocol discipline applies in full: read every line, verify in binary). Its six steps are the entire trusted computing base of a metal write.

## 4.3 COMPONENT — III Floor (Ring −1 hypervisor)

```
COMPONENT: III Floor  (the bluepill; a minimal deterministic Type-1 HV image)
RESPONSIBILITY: Virtualize the running OS with the SMALLEST proven VMEXIT set; own NPT (identity +
                CoW); execute Descend cycles (VMRUN a guest code-crystal); be its own proof.
EMITTED BY: iiis → cg_rm1  (SysV ABI, identity-mapped, no host libc in the image; witness to a
                            per-CPU forward ring; .xii_sanctum-style sealed text)

INTERFACE (reached only via the R0→R−1 crossing, §4.6):
  + floor_vmcb := sealed_compose(zero,vmsave,ctrl,segs,scalars)   # ONE term, confluence-verified
  + descend(guest_cell_term, asid) -> {vmexit_trace, result, witness}   # F5
  + npt_protect(range) / npt_cow_resolve(fault)                  # F4 backing (real VMCB NPT)
  + observe_smi(arm|disarm) -> WitnessFragment                   # F6 (no handler replace)
  Events emitted: VMEXIT pulse (per exit), SMI-observed fragment, drift alarm
  Events consumed: descend terms (from the Gate crossing)

THE MINIMAL DETERMINISTIC VMEXIT SET (§4.8) — only these are intercepted, each a witnessed cycle:
  CPUID (deterministic synthetic leaves) · MSR (whitelisted r/w) · NPF (CoW fault → §3.2) ·
  VMMCALL (the guest→host witnessed call) · #SMI (observe-only, auto-disarm) · INVALID (fail-closed)

DEPENDENCIES:
  - the Census Crystal (vendor/feature gating; never #GP on wrong vendor)  : §3.4
  - NPT-CoW (reversible memory)                                            : §3.2
  - the SID host-state pre-image (VMSAVE/segment capture)                  : §3.3
DATA:
  - Owns: the VMCB(s), NPT tables, the per-CPU witness forward ring, the host-state pre-image
  - References: the guest code-crystal terms (passed in)
SAFETY:
  - The image IS its proof (closure-root + per-fn hexad, the cg_rm2 sealed-text discipline)
  - Coexists with Hyper-V via the resolved nested-L1 branch (§3.3) when census detects "Microsoft Hv"
  - Every VMRUN carries a pre-materialized full host-state inverse (the §0.6 lesson, structural)
```

## 4.4 COMPONENT — III Deep (Rings −2 / −4, observe-only)

```
COMPONENT: III Deep
RESPONSIBILITY: WITNESS the deepest layers (SMM activity, microcode/PSP version); freeze on drift.
                Write NOTHING signed/locked. (Invariant #7.)
EMITTED BY: cg_rm1 / cg_rm2 (observe stubs); the optional sealed-Sanctum re-root is a separate gated act
INTERFACE:
  + observe_smm() -> WitnessFragment{tsc, source}        # via Floor SMI-intercept, auto-disarm
  + witness_ring4() -> WitnessFragment{microcode, psp_fw}; compare vs Census → CAP_SILICON_DRIFT
  Events emitted: SMM-observed, microcode/PSP-witnessed, DriftFreeze
DEPENDENCIES: the Floor (SMI intercept), the Census Crystal (expected fingerprint), the cap kernel (freeze)
SAFETY: cannot write by type (observe-class hexad); a drift is a deterministic freeze, NOT an anomaly score
NOTE: DRTM re-root / SMM-handler install / TPM-clear are NOT part of Deep's default surface — they are
      separate, highest-gate (Trinity + operator-quorum) sealed-Sanctum cycles, scheduled last (§8 roadmap).
```

## 4.5 COMPONENT — III Forge (build-time)

```
COMPONENT: III Forge
RESPONSIBILITY: Single-source generate + drift-pin the Gate/Floor images, the cycle grammar, the
                census schema, the SVM-offset hexad table, the address map; Anchor-sign; emit the
                measured-launch + anti-tamper seals.
INTERFACE: edit a .def → gen → consumers; --check fails the build on any drift (the iii_compositions.def
           discipline, Value-Inventory §23); sign_xii_manifest-equivalent binds images to the Anchor.
SAFETY: a drift between the SVM-offset hexad table and the Gate's compiled bitmap is a build failure
        (the §0.6 layout and its safety typing are ONE source); the loaded image's measured hash must
        equal the sealed closure-root (xii_sml) or it refuses to run; xii_atm re-checks at runtime.
```

## 4.6 The legal ring-transition constructors (mapped to `PHASES/ring_lattice` + `phase_poly`)

III already enumerates the *only* legal ring-crossing doors (Value-Inventory §13, `ring_lattice.c`: magic-MSR, IOCTL, Sanctum-gate, VMRUN, sysret). KATABASIS binds the descent crossings to exactly those:

| From → To | Constructor | Carried payload | Witnessed as |
|---|---|---|---|
| R3 → R0 | **IOCTL** (`iii_gate_cycle`) | sealed cycle term + cap token | a cross-ring fragment (the only R3→R0 door) |
| R0 → R−1 | **magic-MSR / VMMCALL** | the descend term (guest cell + ASID) | a hoist fragment (gated by `hoist_arm`) |
| R−1 → R−1 | **VMRUN / VMEXIT** | guest code-crystal | a VMEXIT pulse (each exit a fragment) |
| R0 → R−2 | **SKINIT** (only for the optional sealed re-root) | the Forge-generated SLB term | a Sanctum-cycle fragment (highest gate) |
| (any) → R−2 obs | **#SMI intercept** | none (observe) | an SMM-observed fragment |
| guest → host | **VMMCALL** | result + ECX chain selector | the descend cycle's return fragment |

`phase_poly` (the phase-polymorphic codegen, Value-Inventory §1) is the mechanism: a single descend operation is written once and `cg_rm1`/`cg_r0` synthesize the correct lowering for each ring it crosses, with the cross-ring plumbing *generated* (not hand-copied per IOCTL as CHARIOT did). The crossings are thus lawful by construction — there is no door that is not in the lattice.

## 4.7 SVM-region safety typing — the §0.6 BSOD made unrepresentable

This is the single most important safety mechanism, so it is specified exactly. The verified SVM layout (§0.4) is given a **per-offset hexad** in a Forge `.def` (one source, drift-pinned to the Gate's compiled bitmap):

| SVM offset range | Region | Hexad class | Writable from a cycle? |
|---|---|---|---|
| `0x00000–0x00FFF` | VMCB (control) | **structural-NEG** (bricking) | **NO — unrepresentable** |
| `0x01000–0x01FFF` | **HOST_SAVE (HSAVE)** | **structural-NEG** (the §0.6 brick) | **NO — unrepresentable** |
| `0x02000–0x09FFF` | NPT pages | structural-NEG (HV-critical) | only via the Floor's `npt_protect` cycle |
| `0x0A000–0x0FFFF` | GUEST_CODE / MSRPM / IOPM | NEG-gated | only via cap-named Descend setup |
| `0x10000–0x1FFFF` | ML_STATE | positive | yes (cap-named) |
| `0x20000–0x3DFFF` | **SHARED** | positive (the safe region, §0.6) | yes — the normal coordination surface |
| `0x3E000–0x3EFFF` | HV_STATE (dispatcher) | NEG-gated | only the Floor writes it |
| `0x3F000–0x3FFFF` | DIAG (witness ring) | append-only | only the witness hook appends |

Because composing a write-cycle with a structural-NEG target yields a structural-NEG (sticky, by the hexad algebra `AND(NEG,·)=NEG`), and the admissible-cycle bitmap excludes all structural-NEG cycles (the `hexad_reach`/`hexad_check` discipline), **a `WriteMetal` cycle naming HSAVE or VMCB or NPT cannot be emitted, sealed, or dispatched**. The §0.6 test (write 16 bytes to `0x1000`) is not "rejected at runtime" — it has no representation in the cycle grammar. The bricking-pair theorem (`hexad_bricking_proof.c`, 531,441 pairs) is extended with the physical-write trits to prove: *no composition of admissible metal cycles reaches a structural-NEG SVM offset.* This is a hard gate before any descent code is emitted (the F5 roadmap phase, §8).

## 4.8 The minimal deterministic VMEXIT set — why fewer is safer

CHARIOT's HV intercepted broadly and scrubbed leaks reactively (HV_HOIST_LOOP_V2, §0.4). III intercepts the *minimal* set, each handled by a *total, deterministic, witnessed* cycle:

- **CPUID** → return deterministic synthetic leaves (the guest sees a reproducible CPU; no host-timing leak). Inverse: identity (read).
- **MSR (whitelisted)** → r/w only the census-approved MSRs; everything else → fail-closed VMEXIT_INVALID. Inverse: the recorded prior value.
- **NPF (nested page fault)** → the CoW resolve (§3.2): the fault *is* the reversible-memory mechanism. Inverse: the CoW restore.
- **VMMCALL** → the guest→host witnessed call (the descend cycle's result + chain selector). Inverse: the captured guest register file.
- **#SMI** → observe-only, auto-disarm after first (§3.6). Inverse: identity (observe).
- **INVALID / unexpected** → fail-closed: capture state, witness, return to host via the SID pre-image. Never proceed on an unmodelled exit.

Determinism rationale: every intercepted exit must be a *total function* (defined for all inputs) and *witnessed* (so the guest's whole execution is replayable). An un-modelled exit is fail-closed (revert to host) rather than handled heuristically — there is no "best-effort" VMEXIT handler, because best-effort is non-deterministic and III forbids it. Fewer interceptions = fewer total functions to prove = a smaller, fully-verified Floor.

# PART 5 — THE FORCE-MULTIPLIER THESIS

The descent is not an end in itself. It is justified only insofar as each lower-ring capability **multiplies an existing III system** — the resolver, XII, the witness chain, the manifold, the crystal/ripple lineage, the capability algebra, the joule-backed economy — without betraying a tenet. This Part is the argument that it does, decisively, and that no system built on nondeterminism or ML could obtain the same multipliers because the multipliers *depend on* III's determinism. "Don't be dissuaded by what's nearly impossible if it's what the system needs" — these are the things worth the descent.

## 5.1 Reversible memory at silicon speed = SID inverses and ripple, made physical  (the keystone)

III's deepest promise is reversibility: every cycle has a SID-derived inverse; `ripple` re-seals the dependency closure atomically; "nothing is unrecoverable." Today that promise is enforced *in software* and bounded by what III itself allocates. With NPT-CoW at Ring −1 (§3.2), the promise becomes **physical and total**: III can mark *any* page — including the guest Windows' own pages — copy-on-write, and the first write traps to a witnessed pre-image at hardware speed.

What this unlocks, each feeding an existing III aim:
- **True time-travel for the whole machine.** A `Snapshot` cycle checkpoints arbitrary physical state; `ripple` applies a change across the closure; on any K-underflow or contradiction the CoW restore reverts every touched page byte-identically and the witness chain replays exactly how. This is `ripple` (Value-Inventory §20) with a *hardware backstop* — atomic, witnessed, page-granular transactions over real memory.
- **Speculative execution with witnessed rollback.** `temporal_npt` (CHARIOT's "speculative fork" region, §0.2 @903M) becomes a III primitive: fork a snapshot, run a speculative descent cycle, keep the result only if its witnessed branch is taken, else restore — the deterministic, reversible analogue of branch prediction, with the cost ledgered (the economy, §5.6).
- **Crash-proof self-modification.** III re-forging *itself* (governance, the catalyst, the Forge) can snapshot, apply, verify the closure-root, and roll back on failure — at the page level, beneath the OS, so even a fault in privileged code is recoverable to the witnessed prior state. The §0.6 "reboot-survivable" property is upgraded to "checkpoint-survivable": you don't even reboot.

**Why only III can have this:** a reversible-memory substrate is worthless unless the *forward* computation is deterministic — otherwise the "restore" restores a state the replay can't reproduce, and the inverse is a lie. III's bit-identity is the precondition that makes hardware reversibility *trustworthy*. A nondeterministic system gets a snapshot facility; III gets a *proof* that snapshot+restore is an identity.

## 5.2 The Ring −1 vantage = the whole machine folded into the witness chain  (total observability)

From R−1, beneath the OS, III sees everything: the guest Windows' memory and execution (via NPT + VMEXIT), the hardware (via the proven MMIO/PCI/MSR census), the deepest layers (SMM/microcode, observe-only). KATABASIS folds *all* of it into the **one witness chain** (§3.8): every VMEXIT is a pulse, every census a crystal, every SMM intercept a fragment.

What this multiplies:
- **Attestation extends to the metal.** III's `attest.iii` (Value-Inventory §6) today binds the witness-root + closure-root. With the descent, the attestation includes a *witnessed model of the entire machine it runs on* — the silicon census, the microcode version, the guest OS state at any checkpoint. III can prove not just "I am this build and did this history" but "…on this exact, witnessed, undrifted machine." That is an attestation no userspace process can produce.
- **The immune system becomes exact (no ML).** CHARIOT's "hyper_immune" watched for anomalies from beneath the OS (§0.5) — the kind of fuzzy detection III forbids. III's version (Value-Inventory §10) is *replay-divergence*: an intrusion is a guest/host state the witness chain can no longer replay, or a census drift vs the sealed crystal. Detection is exact, explainable (here is the divergent fragment), and the response is a deterministic ring-gated freeze — zero false positives, because it detects *breach of mathematics*, not deviation from a learned normal. The R−1 vantage is what makes the whole machine subject to this exact discipline.
- **Crash forensics = replay (§3.8).** A guest BSOD, a hardware fault, a tamper — each is found by replaying the witness chain to the divergent fragment, not by parsing a corpse.

## 5.3 Deterministic time + isolated execution islands = jitter-immune determinism

III forbids wall-clock time (it has `algebraic_time`, the witnessed-fragment count). The descent gives III *hardware* time and isolation it can make deterministic:
- **A reproducible clock source.** The GPU `PTIMER` (§0.2, an independent ns oscillator) and the TSC, read via witnessed `ReadMetal` cycles, give III a monotone hardware time that is *witnessed into* `algebraic_time` rather than trusted — III gets real-time resolution without surrendering determinism (the hardware time is data in a fragment, not a control input that forks behavior).
- **A deterministic execution lane.** CHARIOT's `WORKER_START` pins a kernel worker to CPU 31 with L3 cache COS island 15 (PQOS, §0.4). Re-forged, this gives III a **cache-isolated, OS-jitter-immune core** to run descent cycles on — so a descent cycle's *timing* (and thus its witnessed cost, §5.6) is reproducible, not contaminated by Windows scheduling noise. The cache-COS island is the spatial isolation that makes the joule/cost measurement honest.
- **"More dynamic and efficient" without nondeterminism.** Efficiency here is not "go faster by guessing"; it is *eliminate the host's nondeterministic interference* (scheduler jitter, cache contention, clock skew) so III's deterministic cycles run on a clean, isolated, witnessed substrate. Determinism becomes *more* efficient than the OS, not less, because it removes the entropy the OS injects.

## 5.4 The GPU as a witnessed manifold coprocessor

III's manifold-compilation (Value-Inventory §19) reshapes sequential programs into massively-parallel work and ships a proof the parallel result equals the sequential one. The descent provides the *real accelerator*: the AD103, via the **proven** paths (BAR0 MMIO, BAR1 VRAM, GSP mailbox live, Vulkan dispatch — §0.1, §0.8).
- A `CoprocDispatch` cycle (F9) submits a manifold term to the GPU; the result is folded into the witness chain and **proven byte-equal to its CPU computation** (the `manifold_compilation` equivalence cert) — so GPU offload *cannot* change an answer, only its time. Determinism survives the accelerator.
- Writes are confined to BAR0 doorbells / BAR1 pushbuffer / BAR3 by **hexad** (the §0.6 lesson: GPU-BAR writes are harmless to host kernel; a write naming any other physical term is unrepresentable), not by a userspace check alone.
- The joule-backed economy (Value-Inventory §21) gets *real energy data*: the GPU PTHERM/clock + the RAPL MSRs (the whitelisted RDMSR) measure actual joules, so `computational_specie` is denominated in *witnessed, measured* energy, not estimated — the currency's physical backing becomes literal because the descent can read the power draw.
- The GPU's 76 SMs become the substrate for XII's parallel pattern-matching, the resolver's batch resolution, the ZK prover's MSM, and the manifold's SAT/model-checking lifts — each a witnessed, proven-equivalent cycle.

**Why only III:** any system can call Vulkan; only III can use the GPU as a coprocessor whose every dispatch is *witnessed, capability-gated, reversible (re-dispatchable from the witnessed inputs), and proven equivalent to the deterministic CPU path*. The GPU stops being a black-box accelerator and becomes a *witnessed, proven* member of the substrate.

## 5.5 Covert sovereign execution = determinism-at-the-metal as the ultimate proof

"Covert access under running Windows, in the ways we choose" means: III runs *beneath* the OS, sovereign, observing and controlling chosen slices, while Windows runs on top none the wiser — and III does this **bit-identically, witnessed, reversibly**. This is the proof-of-worth in its purest form (developed fully in §8):
- Every other approach to "run beneath the OS" is either (a) a research bluepill that is fragile, non-reproducible, and one wrong byte from a brick (CHARIOT, pre-III), or (b) a vendor hypervisor that is closed, unverifiable, and trusts megabytes of code. III's Floor is *small, total, proven, reversible, witnessed, and emitted by its own compiler from a sealed source* — a Type-1 hypervisor whose entire behavior is a set of total functions you can replay.
- The "covert" part is not stealth-for-malice (out of scope, §1.4); it is *sovereignty*: III owes the OS nothing, can observe the whole machine, can checkpoint and revert it, and can run its own deterministic substrate on isolated cores — all while leaving the host able to run, and able to be restored. III is the *landlord beneath the tenant*, by mathematics.
- That this is achievable *at all* — a fully deterministic, witnessed, reversible substrate living at Ring −1 on real consumer silicon — is the thing "no other system could approach any semblance of worth by comparison," precisely because no other system pays the price (brutal per-component determinism) that the descent's safety *requires*.

## 5.6 The compounding — every multiplier feeds an existing III system

KATABASIS is a force multiplier, not a new empire, because each capability plugs into a system III already has:

| Lower-ring capability | Feeds (existing III system) | The multiplied result |
|---|---|---|
| NPT-CoW reversible memory (§5.1) | `ripple` / SID / `temporal_npt` | hardware-atomic, witnessed, page-granular transactions; checkpoint-survivable self-modification |
| R−1 witnessed vantage (§5.2) | `attest` / witness chain / immune | attestation that includes the whole machine; exact (non-ML) intrusion detection |
| Census Crystal (§3.4) | `genesis` lineage / `silicon_fingerprint` caps | machine-bound sovereignty; capabilities welded to *this* witnessed silicon |
| Deterministic time + COS island (§5.3) | `algebraic_time` / the cost ledger | honest, jitter-free witnessed cost; reproducible real-time without nondeterminism |
| GPU coprocessor (§5.4) | manifold-compilation / XII / ZK / resolver | a real, proven-equivalent accelerator; real-joule `computational_specie` |
| Descend cycles at silicon speed (§3.3) | the resolver / prespec | a *metal backend* for resolution — a resolved intent can lower to a witnessed code-crystal run beneath the OS |
| The safe-write law + hexad SVM typing (§3.9, §4.7) | the hexad bricking-impossibility proof | the proof extended to physical memory: bricking is unrepresentable at the metal, not just in the abstract |
| Observe-only Deep (§3.6) | the witness economy / governance | the deepest layers become witnessed inputs to governance; drift is a deterministic constitutional event |

The deepest compounding: **the resolver gains a metal backend.** Today the resolver maps an intent to a witnessed binding in user space. With KATABASIS, an intent can resolve to a *descent cycle* — a witnessed, reversible, hexad-safe operation that runs at Ring 0/−1 beneath the OS. III's "deterministic intelligence without learning" (Value-Inventory §18) thereby extends its reach from user-space resolution to the entire machine, *without adding an ounce of nondeterminism or ML*. That is the maximal expression of "getting III as deep as possible, just like we did with CHARIOT" — except where CHARIOT got deep by careful engineering, III gets deep by mathematical necessity, and is therefore deep *and* safe *and* reversible *and* proven, which CHARIOT never was.

# PART 6 — CROSS-CUTTING CONCERNS

## 6.1 Data architecture

| Entity | Owned by | Form | Access pattern | Consistency |
|---|---|---|---|---|
| **Sealed cycle term** | III Daemon (mints), III Gate (consumes) | canonical XII term, content-addressed, Anchor-signed | write-once, read-once-per-dispatch | strong (the hash IS identity) |
| **Census Crystal** | Gate/Floor (produce), Daemon (reads) | content-addressed crystal bound to genesis-root | write-once per boot, read-many | strong + replay-verifiable |
| **Witness fragment / chain** | the witness hook (sole writer) | append-only, running-root (`root_n = H(root_{n-1}‖frag)`) | append-only write, replay read | strong (tamper = replay-failure) |
| **NPT-CoW pre-image (shadow crystal)** | Floor | content-addressed page copy + `SmaNptShadowEntry` | write-on-first-fault, read-on-restore | strong (the inverse of a write) |
| **Capability token** | the wallet (Daemon) | content-addressed attenuating term | mint/attenuate/revoke | strong (re-derivable, not stored-secret) |
| **SVM region** | Gate (R0) / Floor (R−1) | fixed 256 KB layout, hexad-typed per offset (§4.7) | typed cycles only | strong (the layout is one Forge source) |
| **Closure-root / seal** | the Forge | the sealed image hash + Anchor signature | measured at launch, re-checked at runtime | strong (xii_sml / xii_atm) |

**Data flow (a write to GPU VRAM, end to end):**
```
operator intent ─resolve─► sealed WriteMetal term (target=BAR1 vram_off, hexad=positive-GPU, cap=BAR1-cap)
   ─IOCTL─► Gate: verify seal → verify cap names BAR1 → hexad admissible (GPU-BAR positive) →
            record SID pre-image (read prior VRAM bytes into a shadow crystal) →
            [if NEG-class: rehearse in throwaway guest first, §3.9] → MmMapIoSpace write →
            emit witness fragment {term-hash, target, tsc, prior-image-hash} → return
```
Every datum is content-addressed; nothing is identified by mutable pointer; "the same operation" is "the same term hash"; the entire flow is replayable from the fragment.

**Consistency strategy:** within a ring, strong (single-writer per entity). Across rings, the witness chain is the single serialization point — `algebraic_time` advances only through the hook, so there is a total order on all cross-ring events, and the chain root is the consistency anchor. There is no eventual consistency anywhere: a descent that cannot be made strongly-consistent-and-replayable is not admissible.

## 6.2 The cycle interface (the "API")

- **Style:** not REST/gRPC/etc. — a single **content-addressed term-passing** interface. The one cross-ring call is `iii_gate_cycle(sealed_term, cap_token) -> {status, out, fragment}` (§4.2). The "endpoints" are the nine cycle families (§3.0), selected by the term's *kernel*, not by an opcode number.
- **Grammar:** a cycle term is an XII term over the descent kernel alphabet (ReadMetal/WriteMetal/Census/Snapshot/Descend/Observe/SelfVerify/CapOp/CoprocDispatch) with a named target (address-range / MSR / port / BAR-window / guest-cell / ASID), a hexad, and a cap reference. Malformed terms fail to parse as cycles (= `BLOCKED_IOCTL`, §3.5).
- **Versioning:** by **closure-root**, not a version number. The Gate/Floor image's sealed closure-root *is* the version; a term sealed against a different closure-root is rejected. (This subsumes CHARIOT's `PLAT_VERSION 1.14` — the version is the hash.) Compatibility is a Forge concern: a new closure-root regenerates the term grammar and all consumers together (drift-pinned).
- **Status / error shape:** `{ verdict ∈ {OK, REJECT_SEAL, REJECT_CAP, REJECT_HEXAD, REJECT_IRREVERSIBLE, FAIL_CLOSED}, out_bytes, witness_fragment_hash }`. Every status is witnessed; a rejection is as auditable as a success.

## 6.3 Security model (no ambient authority, at the metal)

- **Authentication = provable sameness + Anchor signature.** A cross-ring term is accepted only if it carries a valid Founders-Anchor signature over its content-address (no embedded driver master-key, §3.7). Peer/federation auth (R+4) uses `cap_handshake` (provable identical sealed-closure, Value-Inventory §7) — not a CA chain.
- **Authorization = object-capabilities naming the exact target.** Every cycle names the precise term it touches; the wallet must hold an attenuated cap for *that* term; a cap can only attenuate (hexad subset), never amplify; revocation ripples over the crystal lineage. There is no "kernel can do anything" — the Gate holds no ambient power; it executes only what a cap authorizes.
- **Data protection.** Witness payloads are sealed to a capability (confidential by cap, verifiable by hash — §3.6 "The One Chain"). The descent's one secret (the Anchor private key) lives TPM-sealed / off-device (the founders-anchor genesis ceremony, Value-Inventory §13), never in the image.
- **The seal/sign/measure chain (defense in depth):** Forge content-addresses the image → Anchor signs it → `xii_sml` measures it at launch (refuse to run on mismatch) → `xii_atm` re-checks at runtime (abort on tamper) → `HV_LIVE_VERIFY`-equivalent lets userspace re-hash the live `.text` (detect PatchGuard/HVCI/hostile patch). Four independent content-addressed checks.

## 6.4 Determinism + reproducibility gates (the hard CI)

- **Build determinism:** the Gate/Floor images are byte-identical across rebuilds (the `emit.c` golden-bytes discipline, Value-Inventory §1; the determinism gate, ADR-027). A twin-build mismatch fails the build.
- **Census reproducibility:** two `census()` runs on the same machine produce a byte-identical Census Crystal (FR-2). A mismatch is either a drift event (silicon changed) or a non-determinism bug (build-fails).
- **Descent-cycle replay:** a recorded descent (the witness fragment + the sealed term + the census) replays to the same VMEXIT trace + same output bytes on the same silicon. The probe suite (§3.5) asserts this as a witnessed conformance crystal on every build.
- **The subsystem gate** (Value-Inventory §23): the KATABASIS suite exits zero only if the build is bit-identical, the probe-cycle corpus is FAIL=0, and the descent conformance crystal matches its golden — a regression fails it; progress raises the bar.

## 6.5 NIH boundary

- The Gate/Floor are **III-emitted machine code** (`cg_r0`/`cg_rm1`), not borrowed (no CHARIOT `.sov`, no vendor HV, no third-party driver framework). Only `Ke*/Mm*/Io*/Rtl*` + III substrate symbols in the `.sys` (the cg_r0 discipline, Value-Inventory §1).
- All crypto is III's `numera`: SHA-256/Keccak for content-addressing + the witness chain + the self-hash; ed25519 for the Anchor signature; all hand-rolled, KAT-proven (Value-Inventory §9). No OpenSSL, no CNG.
- The instruction encoder is III's own (`jit_emit` / the XII kernel-emit fragments, Value-Inventory §1–2); the AMD APM corpus (`apm_corpus.json`, §0.7) is *reference data to validate the encoder against*, not a runtime dependency.
- The only host-OS surface is the single platform port (the hexagonal adapter, §2.4): the IOCTL syscall to load/talk to the driver, and within the driver the `Ke*/Mm*/Io*` kernel primitives Windows *requires* of any driver. Everything above that line is pure III cycle resolution. NIH is absolute above the platform port; below it, III speaks only the irreducible kernel ABI Windows mandates.

## 6.6 Observability = the witness chain (there is no separate telemetry)

III does not add logging/metrics/tracing to the descent — the **witness chain is the observability** (Value-Inventory §6, witness chains & tamper-evident audit). Every cycle emits a fragment carrying its term-hash, target, tsc, cost (ergo/Landauer), and result. "What is the descent doing?" = read the chain. "What did it do at time T?" = the fragment at `algebraic_time = T`. "Is it healthy?" = the `obs_observatory` threshold-collapse (Value-Inventory §17) over the descent's indicator families (VMEXIT rate, CoW-fault rate, drift-bit, K-floor). RED/USE metrics fall out of the witness fragments for free; there is nothing to instrument because everything is already witnessed.

## 6.7 Error handling (the hexad / SID / witness triad; fail-closed)

| Error class | Strategy | Mechanism |
|---|---|---|
| Lethal target (brick) | **prevented (unrepresentable)** | hexad structural-NEG; the term cannot be emitted (§4.7) |
| Risky but reversible | **reverse** | SID pre-image (recorded value / CoW restore) |
| Dangerous, host-effect unprovable | **rehearse in guest** | the safe-write law (§3.9): #GP → witnessed VMEXIT, host never faults |
| Unmodelled VMEXIT / unexpected state | **fail-closed** | revert to host via the SID host-state pre-image; never proceed heuristically (§4.8) |
| Census drift (silicon changed/tampered) | **freeze** | `CAP_SILICON_DRIFT` freezes the capability kernel (§3.6) |
| Image tamper (PatchGuard/HVCI/hostile) | **detect + refuse** | xii_sml/xii_atm/live-verify mismatch → refuse to run / abort |
| Transient state corruption | **reboot/checkpoint-survivable** | image text-hash intact → clean reload; or CoW checkpoint restore (§5.1) — no persistent damage |

Error response is always a witnessed verdict (§6.2), never a silent failure or a guess. "Fail-closed" is the universal default: an operation III cannot prove safe-and-reversible does not proceed against the host.

## 6.8 Deployment / load flow

- **R&D posture:** test-signing mode / DSE off during development (the standard kernel-driver dev path on the owner's own machine); the live-verify cycle detects HVCI/PatchGuard interference rather than fighting it. (No bypass of code-signing for distribution — this is the owner loading their own driver on their own machine, §1.4.)
- **The load sequence (deterministic, each step witnessed, each gated on the prior):**
  ```
  1. Forge build → byte-identical Gate.sys + Floor image; Anchor-sign; emit closure-root seal.
  2. Load Gate.sys → DriverEntry → self-verify (.text SHA-256 == sealed) else refuse.
  3. census() → Census Crystal; compare to genesis-lineage expectation; drift → freeze.
  4. (optional) arm the Floor: build the VMCB term, NPT identity+CoW, set hoist_arm — gated by cap+Trinity.
  5. measured-launch (xii_sml): the loaded image's measured hash == closure-root, witnessed into PCR.
  6. ready: the Daemon may now resolve intents into descent cycles.
  ```
- **Rollback / unload:** `CLEANUP_SVM`-equivalent reverses the Floor (restore host state from the SID pre-image, tear down NPT); unload the Gate; the witness chain records the teardown. Reboot-survivable at every step (§0.6).

## 6.9 The Forge wiring (single-source, drift-pinned)

The descent's load-bearing constants and surfaces are **one source each**, generated + drift-checked (the `iii_compositions.def` discipline, Value-Inventory §23):
- `iii_descent_addrmap.def` → the Census Crystal schema + the expected silicon fingerprints (the §0.1–0.2 facts as the *expected* census, machine-bound).
- `iii_svm_layout.def` → the SVM-offset hexad table (§4.7) **and** the Gate's compiled admission bitmap — one source, so the safety typing and the layout can never drift apart (a drift = build failure; the structural guarantee against the §0.6 class).
- `iii_cycle_grammar.def` → the nine-family kernel alphabet + the term grammar consumed by both the Daemon (mint) and the Gate (parse).
- `iii_vmexit_set.def` → the minimal VMEXIT set (§4.8) + the Floor's handler dispatch — one source, so an un-handled exit is a *compile-time* gap, not a runtime surprise.
The Forge signs each generated image with the Founders-Anchor and registers its closure-root in the MHASH-LEDGER (Value-Inventory §23) — the tripwire that turns any unintended change to a sealed descent artifact into a detectable drift.

# PART 7 — RISKS, FAILURE MODES & MITIGATIONS

## 7.1 Risk register

| # | Risk | Likelihood | Impact | Mitigation (and where) |
|---|---|---|---|---|
| R1 | **Brick: a write to a hypervisor-critical region** (the §0.6 class — HSAVE/VMCB/NPT/microcode) | was HIGH in CHARIOT | catastrophic (reboot / corruption) | **closed three ways:** *unrepresentable* (hexad structural-NEG, §4.7) → *rehearsed in guest* (#GP→VMEXIT, §3.9) → *reversible* (NPT-CoW pre-image, §3.2). The forward act cannot even be expressed for a lethal target. |
| R2 | **HVCI / PatchGuard / DSE** block loading or patch the driver | HIGH (modern W11) | driver won't load / is silently modified | R&D test-signing (§6.8); the Floor sits *beneath* HVCI's R0 view; `HV_LIVE_VERIFY`-equiv detects any live patch as a hash mismatch (§3.8); III treats interference as a *detected, witnessed* event, not a fight to win. |
| R3 | **Nested-HV merge** with a present Hyper-V | MED | functional but ~5% per-VMEXIT overhead + merge complexity | the census detects `CPUID(0x40000000)="Microsoft Hv"` and the resolver picks the nested-L1 descent branch deterministically (§3.3); coexistence is a *resolved path*, not an ad-hoc check. |
| R4 | **SMM latent-bug class** (the §0.5 sign-extension dispatch bug) | was real in CHARIOT | a hand-assembled blob silently mis-dispatches | III **never hand-assembles** the deep blobs — dispatch is XII-generated (the sign-extension class is unrepresentable in generated, confluence-checked code); SMM is **observe-only** initially (§3.6); a sovereign SMM handler is re-derived from `.def`, not adopted. |
| R5 | **Determinism break from machine-variable addresses** (KASLR, BAR re-mapping) | MED | a hard-coded address is wrong → fault | **census-not-hardcode** (§3.4): every address is re-derived live and machine-bound; the §0.1–0.2 facts are the *expected* census (drift-checked), never blind constants. |
| R6 | **NPT-CoW shadow-pool exhaustion** | MED | cannot snapshot further | the pool is hexad/quota-bounded and counted (§3.2); on exhaustion the `Snapshot` cycle *fails closed* (refuses, witnessed) — it never faults or silently drops a pre-image. |
| R7 | **Building on DESIGNED-not-PROVEN ground** (DRTM/SMM-install/TPM) | MED | a hypothesis assumed working | the binding rule (§0.8): nothing un-PROVEN is load-bearing; each is scheduled for III-native re-derivation + a deterministic proof before use (§8 roadmap); the early phases use only PROVEN capabilities. |
| R8 | **AMD-only assumption** | LOW (machine is AMD) | the plan is SVM-specific | the census is vendor-explicit (§3.4); Intel-VMX is a future census branch; on this machine the AMD-SVM path is correct and primary. |
| R9 | **Microcode / firmware drift under III** | LOW | census mismatch mid-life | this is a *feature*: Ring-4 witness + `CAP_SILICON_DRIFT` freeze (§3.6) turns drift into a deterministic, witnessed constitutional event — exactly what should happen. |
| R10 | **Side channels at R−1** (Spectre/Meltdown-class, timing) | MED | info leak across the guest boundary | the minimal deterministic VMEXIT set (§4.8) shrinks the surface; CPUID returns *synthetic deterministic* leaves (no host-timing leak); `side_channel_obs` (§0.2 @906M, the CHARIOT software region) witnesses suspicious access; the COS cache island (§5.3) reduces contention channels. |
| R11 | **Scope / complexity** (a deterministic reversible R−1 HV is large) | HIGH | the effort sprawls / never proven | the phased proof-gated roadmap (§8.2): each phase is small, proven, reversible before the next; the **inversion** (cleverness at R3, the metal code as dumb + tiny as possible, §2.5) keeps the trusted base auditable line-by-line. |
| R12 | **Single-target data** (verified for ONE machine) | known | portability questioned | portability is a *census re-run on new silicon*, not a re-port; the architecture binds to the Census Crystal + genesis lineage, not to baked constants (§3.4); the §0.1–0.2 values are this machine's expected crystal. |
| R13 | **Reboot during a non-atomic descent** (power loss mid-VMRUN) | LOW | torn state | reboot-survivability (§0.6): the image text-hash is intact → clean reload + fresh SVM; the witness chain + NPT-CoW pre-images are the recovery anchor; no descent commits irreversibly without its inverse already materialized. |

## 7.2 Failure-mode deep dive — the brick class (R1), closed three ways

This is the failure mode that rebooted CHARIOT (§0.6), so its closure is specified to the bottom:

```
A WriteMetal cycle naming a lethal target (e.g. SVM HSAVE 0x1000):
   LAYER 1 — REPRESENTATION (compile/seal time):
      target 0x1000 ∈ SVM HOST_SAVE → hexad class = structural-NEG (iii_svm_layout.def, §4.7)
      compose(WriteMetal, structural-NEG-target) = structural-NEG  (sticky, AND(NEG,·)=NEG)
      structural-NEG ∉ admissible bitmap (hexad_check / hexad_reach)
      ⇒ the term DOES NOT EXIST — the Daemon cannot mint it, the Forge cannot seal it.
      [Proven by the bricking-pair theorem extended with physical-write trits, §4.7.]
   LAYER 2 — REHEARSAL (if a NEG-gated-but-not-structural write somehow reaches the Gate):
      the safe-write law (§3.9) runs it in a throwaway SVM guest first;
      a #GP becomes VMEXIT_EXCP_13 caught by the host; the host never faults.
   LAYER 3 — REVERSAL (for any write that does proceed against the host):
      SID pre-image (recorded prior bytes / NPT-CoW) is materialized BEFORE the write;
      any bad outcome restores byte-identically; transient, not persistent (§0.6 survivability).
```
The §0.6 BSOD required all three layers to be absent. CHARIOT had a userspace allowlist (a single, bypassable Layer-1.5). III has Layer 1 (unrepresentable) as primary, Layer 2 (rehearsed) and Layer 3 (reversible) as defense in depth — and Layer 1 is a *theorem*, not a check.

## 7.3 Failure-mode deep dive — the determinism contract (R5, R10, R13)

The descent's value (Part 5) *depends on* bit-identity. The threats to determinism and their structural answers:
- **Machine-variable addresses (R5):** never hard-coded; the Census Crystal re-derives them and is itself the determinism unit (two runs → identical crystal). KASLR of the *driver/guest* is handled by the cg_r0 `IMAGE_BASE` discipline (§0.4) + RVA-relative addressing.
- **Host-timing leaks (R10):** intercepted CPUID returns synthetic deterministic leaves; the TSC/PTIMER are *witnessed as data*, never used as a control input that forks behavior (§5.3). A descent cycle's output is a pure function of its term + the census, not of when it ran.
- **Torn state on power loss (R13):** no cycle commits irreversibly before its inverse is materialized; the witness chain + CoW pre-images reconstruct the last consistent root on reload. The system is a transactional log over physical state.

## 7.4 The meta-risk: "is this nearly impossible?" — and why it is not

A fully-deterministic, witnessed, reversible Type-1 hypervisor on consumer silicon sounds impossible. The decomposition shows it is not, because the *hard hardware parts are already PROVEN* (§0.8) and the *new parts are software disciplines III already has*:
- The hardware miracles (MDL-bypass MMIO read/write, the VMCB build, VMRUN, NPT, GSP, Vulkan) are **done** — CHARIOT proved them on this exact silicon. III is not inventing hardware access; it is *re-emitting proven access deterministically*.
- The new requirements (hexad-typing the SVM offsets, deriving SID inverses, witnessing every cycle, content-addressing terms, sealing the image) are **software disciplines III already runs at Ring 3** — KATABASIS applies them one ring deeper. There is no new mathematics; there is the *same* mathematics at lower privilege.
- The only genuinely new engineering is the *glue*: cg_r0/cg_rm1 emitting the cycle-dispatch + the SVM-hexad gate + the NPT-CoW-as-SID binding. That is hard but bounded, and the inversion (§2.5) keeps it small. "Nearly impossible" describes doing this *without* III's determinism; *with* it, the impossible part (safety at the metal) is exactly what the determinism provides.

# PART 8 — ADRs, PHASED ROADMAP & THE PROOF-OF-WORTH

## 8.1 Architecture Decision Records

**ADR-001 — Emit the descent via `iiis`/`cg_r0`/`cg_rm1`; never port CHARIOT, never use `.sov`.**
*Status:* Accepted. *Context:* CHARIOT's lower-ring code is C + hand-assembled blobs; III is self-hosting. *Decision:* the Gate/Floor are III-emitted machine code from sealed III source. *Consequences:* full NIH + bit-identity + the image-is-its-proof property; cost = III must teach `cg_r0`/`cg_rm1` the descent emission (already 80% present, Value-Inventory §1). *Alternatives:* link CHARIOT's `.sys` emitter (rejected — non-deterministic origin, not III's, can't be proven); port to `.sov` (rejected — abandoned dialect).

**ADR-002 — One cross-ring entry + nine cycle families, not ~90 IOCTLs.**
*Status:* Accepted. *Context:* CHARIOT's IOCTL count grew to ~90 organically. *Decision:* a single `iii_gate_cycle(term,cap)`; the family is read from the term kernel. *Consequences:* a tiny, auditable cross-ring surface; the dispatch is content-addressed resolution; cost = the term grammar must cover every needed op (it does, §3.0). *Alternatives:* preserve the IOCTL surface (rejected — sprawl, per-IOCTL ad-hoc safety, the footgun class).

**ADR-003 — The inversion: cleverness at Ring 3, the metal code minimal and dumb.**
*Status:* Accepted. *Context:* CHARIOT put intelligence in the driver. *Decision:* the Daemon (R3) resolves *which*/*whether*; the Gate/Floor merely execute pre-sealed terms. *Consequences:* the trusted-at-the-metal code is small enough to prove in the disassembly; a logic bug is a recoverable R3 bug, never a brick. *Alternatives:* smart driver (rejected — the most dangerous code becomes the most complex).

**ADR-004 — SVM-offset hexad typing is the PRIMARY brick defense (unrepresentable, not guarded).**
*Status:* Accepted. *Context:* the §0.6 BSOD. *Decision:* each SVM offset carries a hexad; a write to a structural-NEG offset is unrepresentable (§4.7), proven by the extended bricking-pair theorem. *Consequences:* the brick class cannot be expressed; the userspace allowlist is demoted to defense-in-depth. *Alternatives:* userspace allowlist as primary (rejected — bypassable, single layer; it is what CHARIOT had).

**ADR-005 — The safe-write-in-guest law is the universal gate for dangerous writes.**
*Status:* Accepted. *Context:* CHARIOT's `HV_MSR_WRITE_PROBE`. *Decision:* any NEG-gated write whose host effect is unprovable runs first in a throwaway guest (#GP→VMEXIT). *Consequences:* the host never faults on an unproven write; cost = a VMRUN per rehearsed write (acceptable; only for the dangerous class). *Alternatives:* write-and-pray with reactive scrub (rejected — CHARIOT's HOIST_LOOP leak path).

**ADR-006 — NPT-CoW is the physical realization of SID/ripple (reversible memory is the keystone).**
*Status:* Accepted. *Context:* §3.2, §5.1. *Decision:* a snapshot is a witnessed pre-image crystal; rollback is the CoW restore; `ripple` gets a hardware backstop. *Consequences:* whole-machine time-travel, checkpoint-survivable self-modification; cost = shadow-pool memory (bounded, §7 R6). *Alternatives:* software-only reversibility (kept as the emulation fallback, but bare-metal NPT is the target).

**ADR-007 — Census-not-hardcode; bind to genesis lineage.**
*Status:* Accepted. *Context:* machine-variable addresses (§7 R5). *Decision:* re-derive every address live into a Census Crystal bound to genesis-root; the §0.1–0.2 facts are the *expected* crystal. *Consequences:* portability = census re-run; drift = a witnessed event; cost = a census pass per boot. *Alternatives:* bake the verified addresses (rejected — brittle, machine-specific, undetectable drift).

**ADR-008 — Observe-don't-write the deepest/signed layers (R−2 SMM, R−4 microcode).**
*Status:* Accepted. *Context:* §3.6, invariant #7; the §0.5 SMM stub+bug. *Decision:* witness SMM/microcode; never write them by default; a sovereign SMM re-root is a separate highest-gate optional act. *Consequences:* maximal restraint at the deepest layer = maximal trustworthiness; cost = III forgoes SMM control initially (acceptable — observation suffices for the multipliers). *Alternatives:* adopt CHARIOT's SMM handler (rejected — latent bug, hand-assembled, not III-emitted).

**ADR-009 — AMD-SVM primary; vendor-explicit census; Intel-VMX a future branch.**
*Status:* Accepted. *Context:* the machine is a Ryzen 9 7945HX. *Decision:* the SVM path is primary; the census is vendor-explicit (cannot #GP on the wrong vendor); Intel-VMX is a future census branch. *Consequences:* correct on this machine now; portable later by adding the branch. *Alternatives:* abstract HAL up front (rejected — premature; YAGNI until a second machine).

**ADR-010 — The witness chain IS observability; no separate telemetry.**
*Status:* Accepted. *Context:* §6.6. *Decision:* every cycle's fragment is the log/metric/trace; `obs_observatory` rolls them up. *Consequences:* zero instrumentation cost; observability is replayable + proven. *Alternatives:* add logging/metrics (rejected — duplicates the witness chain, adds non-determinism).

**ADR-011 — Versioning by closure-root, not a version number.**
*Status:* Accepted. *Context:* §6.2. *Decision:* the sealed image hash is the version; a term sealed against a different root is rejected. *Consequences:* a new build is a new identity; compatibility is Forge-managed (drift-pinned). *Alternatives:* semantic version numbers (rejected — they drift from the bytes; the hash cannot).

**ADR-012 — TPM is a witness sink by default; takeover is highest-gate optional.**
*Status:* Accepted. *Context:* §3.6. *Decision:* use the TPM to anchor the closure-root (PCR extend); clearing/re-owning it is gated behind Trinity + operator-quorum. *Consequences:* III gains hardware-anchored measurement without destroying the existing owner state. *Alternatives:* default takeover (rejected — destructive, unnecessary for the multipliers).

## 8.2 Phased, proof-gated roadmap

> **The gate law (binding):** no phase begins until the prior phase's gate is **green**: (a) the determinism gate — byte-identical Gate/Floor build across a twin-build; (b) the probe-cycle conformance crystal — FAIL=0, including the adversarial `BLOCKED_HEXAD`/`BLOCKED_CAP` cases; (c) reboot/checkpoint survivability demonstrated. This is the brutal methodology applied to the descent: read every line, verify in the disassembly, prove before progressing.

| Phase | Scope (cycle families) | Risk surface | Proof gate (must be green to advance) |
|---|---|---|---|
| **P0 — Foundations** | Gate emits/loads/self-hashes; `Census` (F3) + `SelfVerify` (F7) — **read-only, zero brick risk** | none (reads) | byte-identical Census Crystal across 2 runs; live `.text` hash == sealed; smoke probe-suite green; §0.1–0.2 facts reproduce exactly |
| **P1 — Gate metal I/O** | `ReadMetal`/`WriteMetal`/`MsrSurvey` (F1/F2), writes **allowlisted to BAR0/1/3 by hexad** | GPU writes (contained); MSR reads | the §0.6 brick term is `REJECT_HEXAD` (the extended bricking theorem checks green); GPU MMIO read/write reproduces the proven values; adversarial `BLOCKED_BAR` rejected by construction |
| **P2 — Reversible memory** | `Snapshot`/`Reverse` (F4): NPT-CoW, software-emul → bare-metal NPT | memory CoW | snapshot→mutate→rollback byte-identity; the pre-image is a witnessed crystal; replay reproduces both directions; pool-exhaustion fails closed |
| **P3 — The Floor (minimal bluepill)** | `Descend` single-shot (F5): VMCB-as-one-term, minimal VMEXIT set, nested-L1 branch if Hyper-V | VMRUN (the dangerous instruction) | VMRUN/VMEXIT round-trip deterministic; **no host fault on any write** (safe-write law exercised); VMCB term confluence-verified; reboot-survivable; the host is restorable from the SID pre-image |
| **P4 — Silicon-speed cycles + GPU coprocessor** | `Descend` chains (F5, witnessed wavefronts) + `CoprocDispatch` (F9) | code-crystal chains; GPU dispatch | a code-crystal chain runs + replays bit-identically; a GPU dispatch returns **proven byte-equal to the CPU path**; real-joule `specie` measured via RAPL/PTHERM |
| **P5 — Deep observation** | `Observe` (F6): R−2 SMI intercept-observe; R−4 microcode/PSP witness + drift-freeze | observation only (no writes) | an `#SMI` is witnessed **without** replacing AMI handlers; a simulated microcode drift triggers a deterministic `CAP_SILICON_DRIFT` freeze; III writes nothing signed/locked |
| **P6 — (optional) Sovereign re-root** | DRTM SLB + sealed-Sanctum SMM (re-derived) + TPM, behind Trinity + **operator-quorum** | the deepest, most destructive acts | each blob Forge-generated, byte-verified, content-addressed; the re-root is reversible + witnessed; explicit operator consent recorded as a governance crystal |

**Cross-phase, always-on:** the Forge single-sources + drift-pins every artifact (§6.9); the witness chain records every step; the capability wallet gates every cycle; the determinism gate runs on every build. Phases P0–P2 use **only PROVEN capabilities** (§0.8) and carry essentially zero brick risk; the brick risk concentrates at P3 (VMRUN) and is closed three ways (§7.2) before P3 begins.

## 8.3 The proof-of-worth — why this vindicates III as nothing else could

CHARIOT proved the *hardware* is reachable: on this exact silicon, you can read and write GPU MMIO beneath Windows, build a VMCB, run a guest, observe SMM, witness microcode. It paid for that knowledge with months of work and at least one BSOD. But CHARIOT could never make the descent *safe, reversible, and provable* — because it was built on the very nondeterminism and "good enough" that III was created to reject. CHARIOT could **take** the machine; it could not **give it back with a proof**.

KATABASIS is the demonstration that III can. And the demonstration is decisive precisely because the descent is the *severest possible test* of III's tenets:

1. **At Ring −1/−2, one wrong byte reboots the machine.** There is no harsher environment for a "no placeholders, verify in the binary, determinism gate, bricking-impossibility" methodology. The §0.6 BSOD is the proof of the negative: *without* the methodology, you brick. KATABASIS is the proof of the positive: *with* it — hexad-unrepresentable lethal writes, SID-reversible everything, rehearsed-in-guest dangerous ops, witnessed every step, capability-named every target — you descend **reversibly, forever**, and the brick class *cannot be expressed*.
2. **The vantage III obtains is worth more than any other system's, by four properties no other system has:**
   - *Reversible* — no other hypervisor can checkpoint and restore the whole machine byte-identically *with a proof that restore is the inverse of the snapshot* (it depends on bit-identity, which only III has).
   - *Witnessed* — no other hypervisor folds the entire machine (guest OS, hardware, microcode) into one replayable, tamper-evident chain.
   - *Deterministic* — no other hypervisor is bit-identical, so none can be replayed, audited, or proven; III's can.
   - *Sovereign + NIH* — no other hypervisor is emitted by its own compiler from a single sealed source under the owner's anchor, owing nothing to a vendor.
3. **The brutal methodology is revealed not as overhead but as the precondition.** Every painful III discipline — read every line, prove in the disassembly, no fuzzy guess, the determinism gate, the hexad bricking proof, SID reversibility, the witness chain — is *exactly what is required* to live at the metal safely. A laxer system cannot descend reversibly; a fuzzier system cannot prove its restore; an ML-driven system cannot be replayed. The methodology that felt like a tax at Ring 3 is the *enabling condition* at Ring −1. KATABASIS makes the years of brutality pay off in the one place where laxity is fatal.
4. **It is more dynamic AND more efficient — because it is more rigorous.** The dynamism comes from reversibility: III can attempt *anything* at the metal because it can always undo it, witnessed, to a proven prior state — the whole machine becomes a reversible scratchpad. The efficiency comes from determinism: III removes the host's nondeterministic entropy (scheduler jitter, cache contention, clock skew) by running descent cycles on isolated COS-fenced cores with a witnessed hardware clock, and offloads to a *proven-equivalent* GPU coprocessor. Rigor is not the price of dynamism and efficiency here; rigor is their *source*.

The deepest expression of the original aim — "get III as deep as possible, just like we did with CHARIOT" — is this: where CHARIOT got deep by *careful engineering atop chaos*, III gets deep by *mathematical necessity atop determinism*. The resolver gains a metal backend; reversible memory makes the whole machine a witnessed, undoable transaction; the GPU becomes a proven coprocessor; the currency is denominated in measured joules; attestation extends to the silicon. Each is a force multiplier for a system III already is, obtained without bending one tenet. The descent does not make III a different system; it makes III *more itself*, one ring deeper, where being itself is hardest and therefore worth the most.

> **This is the worth no other system can approach: not that III can reach the metal — others can — but that III can reach it, control it, observe it, and leave it, all reversibly, all witnessed, all proven, all its own. CHARIOT showed the door exists. III walks through it, and can always walk back, with a receipt signed by mathematics.**

---

## APPENDIX A — Open items to verify/derive during implementation (the honest backlog)
- BAR1 VRAM size (§0.2 **[TBD]** — needs BAR sizing via the standard write-FFs/read-back size probe, as a `ReadMetal` census sub-cycle).
- The DESIGNED items (§0.8): nested-L1 merge under the *current* Hyper-V build; the DRTM SLB full 64 KiB term; the sovereign SMM re-derivation (with the §0.5 dispatch class made unrepresentable); the TPM2 sequences against *this* board's auth.
- Byte-level mining of the collected-data files (§0.7): `apm_corpus.json` (validate the III encoder against it), `calibration.bin`/`calib_cache_*` (GPU-op timing priors for the cost ledger), `aegis_catalog.json` (the ~40 machine-code invariants → III emission obligations, §Value-Inventory §15), `chariot_hv_baremetal.bin` + `chariot_platform.selfdesc.bin` (reference images to diff III's emission against).
- The extended bricking-pair theorem with physical-write trits (§4.7) — formalize + add to the corpus before P3.
- The minimal VMEXIT set's totality proof (§4.8) — each handler proven total + deterministic before the Floor arms.

## APPENDIX B — Provenance ledger
Every PART 0 fact was read on 2026-05-23 from `C:\Users\Edwin Boston\OneDrive\Desktop\CHARIOT\` in: `FOUNDATION/sma_address_map.h`, `FOUNDATION/sma_platform.h`, `LINK/sma_pe_emit_platform.h`, `BUILD/accel/POSTMORTEM_BSOD_2026-04-26.md`, `TOOLS/probe/catalog/00_smoke.probe`, `HYPERVISOR/sma_npt.c`, `BUILD/hv/sma_hv_nested_l1.c`, `BUILD/drtm/sma_drtm_slb.c`, `BUILD/deploy/probe_runner.c`, `BUILD/smm/sma_smm_handler.c`, `BUILD/tpm/sma_tpm_takeover.c`, `HYPERVISOR/sma_hv_silicon_census.c`, `BUILD/ring/sma_ring_minus_four.c`, plus the directory enumeration of HYPERVISOR/SOV/BUILD/LINK/TOOLS/FOUNDATION. The canonical CHARIOT generation is the one bearing `FOUNDATION/sma_address_map.h` (distinct from `C:\CHARIOT` and the plain-Desktop TRAMPOLINE generation). PROVEN vs DESIGNED status per §0.8 is binding.

---
*END OF PLAN. Parts 0–8 complete + appendices. Status: ARCHITECTURE — no implementation performed. Next action is the operator's: approve the phase ladder (§8.2) or direct revisions.*
