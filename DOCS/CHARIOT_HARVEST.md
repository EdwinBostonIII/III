# CHARIOT → III Architectural Harvest

> **Status:** read-only analysis (living document). No III substrate code is changed by this file.
> Catalogs the genuine addresses/data and the architecture of CHARIOT (the user's Sovereign Machine
> Architecture — an AMD-SVM hypervisor + self-emitting Windows kernel driver + cognitive substrate),
> and analyzes which patterns transform into III, **filtered through III's mandates** (especially
> **M3: no machine learning / no observational learning** — a large fraction of CHARIOT is an AGI
> cognition layer that is *explicitly excluded* from III transfer).
>
> **Read so far (deeply):** `FOUNDATION/sma_address_map.h`, `sma_platform.h`, `sma_q16_math.c`;
> `LINK/sma_pe_emit_platform.h`, `LINK/manifest/ioctl_codegen.c`; `TOOLS/npt-observer/pe_introspect.c`;
> `BUILD/atomic_deploy.c`, `BUILD/deploy/sovereign_sign.c`, `BUILD/deploy/hot_swap_orchestrator.c`,
> `BUILD/sma_aegis.h` (+ `sma_aegis.c` rule-registry grep), `BUILD/vmrun_test.c`, `BUILD/probe_ring2.c`;
> binary scrapes of `probe_svm_virt.exe`, `npt_observer.exe`, `build_platform.exe`. **18 transfer
> patterns (T1–T18) recorded.** Continuation queue at §6.

---

## 1. What CHARIOT is (one paragraph)

CHARIOT ("מֶרְכָּבָה", Sovereign Machine Architecture) is a from-scratch, NIH (no stdint, no libc
mem*), C + Gestalt(`.sov`) system that (a) **emits its own ~10KB PE32+ Windows kernel driver**
(`chariot_platform.sys`) with no external toolchain, (b) drives **AMD-V (SVM) hardware
virtualization** — VMCB/NPT/MSRPM/IOPM, VMRUN, VMSAVE, VMEXIT cascades — through an ~80-IOCTL
surface, (c) exposes deep hardware (PCI config via CF8h/CFCh, MMIO via MmMapIoSpace, RDMSR/WRMSR,
CPUID SEV/SNP, TPM, AMD PSP mailbox, SMM probing, cache QoS), and (d) runs a large cognitive
substrate on top (KB triple-store, RETE, blackboard, neural weights, drives — the **ML layer, NOT
for III**). It shares III's deepest commitments: NIH, pure determinism, "BSOD acceptable, **bricking
never**", witness/attestation, capability mediation, a ring/privilege lattice, and ternary logic.

---

## 2. Genuine addresses & data (reference)

CHARIOT's defining discipline: **`FOUNDATION/sma_address_map.h` is "The One True Address Map"** —
*every* module reads its base from this single header; no module declares its own; a
non-overlapping invariant is asserted. Semantic addresses are mapped to physical RAM/VRAM by a
custom software MMU (→ real NPT entries on bare metal).

### 2.1 Semantic binding-store layers (selected)
| Range | Layer |
|---|---|
| 1M–2M | Cross-ring protocol (manifest/mailbox/dispatch/route) |
| 2M–3M | GPU / SPIR-V |
| 6M / 10M | Crystal store / crystal-graph edges (stride 40) |
| 13M / 15M | Axiom store / binding store |
| 30M–40M | Rings 0/1/2/3/5 (observation, speculative, inference, perception, disposition) |
| 50M | Thermodynamic envelope |
| 100M–106M | **Ring -1 hardware observer** (hw crystal/edge, shared, baseline, delta, threat) |
| 440M–453M | **KB + reasoning** (facts stride 7 = S·P·O·conf·hash·tick_created·tick_walled; rules; negation walls; embeddings; attention; shadow/counterfactual) |
| 460M | RETE network |
| 510M–520M | COGITO unified cognitive core (focus/valence/narrative/WM/episodic/semantic/dream) |
| 588M–620M | Binding superposition + **Curry-Howard proof obligations** (stride 7) |
| 700M–708M | HEARSAY-III blackboard (8 lock-free regions) |
| 710M–719M | Truth Maintenance System (justification DAG + retraction) + drives |
| 800M–1.0G | **Dense neural weight tensors** (raw C pointer bypass of the hash table) |
| 900M–910M | Foundation telemetry (autotune, integrity, SMP sched, side-channel, sandbox) |
| 910M | Cell-membrane enzymatic inference dispatch (stride 8) |

### 2.2 Real hardware addresses (verified 2026-04-11, RTX 4090 Laptop AD103 / Ryzen 9 7945HX)
- **GPU (PCI 10DE:2717, Bus1:Dev0:Fn0, rev A1, 76 SMs, 16376 MB):**
  BAR0 MMIO `0xFB000000` (16MB), BAR1 VRAM aperture `0xF800000000`, BAR3 RAMIN `0xFC00000000` (32MB), BAR5 I/O `0xF000`.
  Register offsets within BAR0: `PMC_BOOT_0` 0x000000 (=0x193000A1), `PMC_ENABLE` 0x000200,
  `PTHERM` 0x020008, `PTIMER` 0x009400/0x009410, `CLOCK_DOMAIN` 0x040000, GSP Falcon mailbox
  0x110040/0x110044, `PGSP_MAILBOX(i)` 0x110804+4i, `QUEUE_HEAD(i)` 0x110C00+8i, `FALCON_ENGINE`
  0x1103C0, VBIOS shadow 0x300000 (BIT @ +0x1B2), runlist 0x820000 (SM_COUNT @ +0x14).
- **CPU:** LAPIC `0xFEE00000` (4KB); AMD SMU `0x03B00000` via SMN indirect (write addr→0x60, read←0x64).
- **MSRs (AMD Zen 4):** HWCR `0xC0010015` (SMM_LOCK bit0, SMBASE_LOCK bit1), SMM_BASE `0xC0010111`,
  SMM_ADDR `0xC0010112` (TSeg base), SMM_MASK `0xC0010113`, VM_CR, VM_HSAVE_PA, EFER, APIC_BASE,
  LSTAR (reveals kernel text base), STAR, IA32_BIOS_SIGN_ID (microcode ver), PQR_ASSOC `0xC8F`.
- **Other:** ACPI SMI_CMD I/O port `0xB2`, TPM TIS MMIO `0xFED40000`, AMD PSP at PCI Bus0:Dev8:Fn1
  (mailbox window 0x10500–0x105FF). PCIe cache line 128B (`SMA_PCIE_ALIGN`).

### 2.3 Platform driver layout & interface (`sma_pe_emit_platform.h`)
- Image base `0x140000000` (canonical x64 kernel-module base; `0x10000` was a user-VA range that
  caused a W11 26100 idle BSOD 0x50 PAGE_FAULT_IN_NONPAGED_AREA — a recorded crash lesson). Pool tag
  `'CPLT'` = 0x544C5043. File align 0x200, section align 0x1000.
- **SVM region (256KB) offsets:** VMCB 0x0, HostSave 0x1000, NPT 0x2000 (32KB PML4+PDPT+PD),
  GuestCode 0xA000, MSRPM 0xB000, IOPM 0xC000, ML-state 0x10000, **Shared 0x20000** (128KB), HV
  stats/diag `0x3E000`, diagnostic ring `0x3F000`.
- **Crash-forensic diagnostic region:** ring of 256 × 24-byte entries `{function_id, proof_hash, timestamp}`.
- **IOCTL map** `0x222100..0x222268` (CTL_CODE, FILE_DEVICE_UNKNOWN=0x22): version/info, FIELD_WRITE/EXEC
  (coordinate-addressed crystal cells: 2048 × 256B, cell = coord & 0x7FF), read/write shared, init/cleanup
  SVM, read diag, **READ_PHYS/WRITE_MMIO** (CF8h/CFCh + MmMapIoSpace), VMRUN_COORD(+CHAIN/SLOT), RDMSR,
  SOVEREIGN_INIT (SEV/SNP CPUID), CHIP_IDENTITY (64-byte hardware fingerprint), TPM_STATUS, PQOS, persistent
  WORKER, **WITNESS (FNV-1a pulse chain)**, PCI_CFG_READ, PHYS_PEEK, SILICON_SNAPSHOT, HV_PROBE, NPT_EXPAND,
  HV_VMSAVE/SEGMENT_CAPTURE, the HV_VMCB_* 6-step incremental VMCB builder, HV_HOIST_RUN/LOOP(_V2),
  SMI/SMM/PSP probes & sends, MSR/MEM write primitives, **READ_SELF + LIVE_VERIFY (driver SHA-256 of its
  own .text vs embedded anchor)**, the Aegis v10 **capability-token IOCTLs** (BOOTSTRAP/REVOKE/SUBDIVIDE/
  QUORUM_ISSUE/TIME_LOCK_ISSUE/NIZK_PROVE/NIZK_VERIFY/COINAGE/STREAM_APPEND), RING_TRANSITION_WITNESS,
  DRTM_SKINIT, BOOT_GREETING, kill-switch audit, BAR probe, carousel ring init/dispatch.
- Sovereignty anchor (Mandate 23): **FNV-1a("Edwin Boston III") = 0x07999E631613F20A**; 128-byte
  `AegisAnchor` in `.rdata` + 512-byte companion blob; witness pulse = {ordinal, tsc, exit_code, guest_rip}.

---

## 3. Transferable architecture (mandate-filtered, with critical review)

Each: **CHARIOT pattern → III mandate it serves → concrete III transformation → review note.**

**T1. The One True Address Map → III's canonical content-address map (the Forge spine, validated).**
CHARIOT proves at scale (hundreds of ranges) that "one header, every module reads its base, no module
declares its own, non-overlap invariant" eliminates drift. This is exactly the Sovereign-Ledger
discipline — but as an *address space*. III transform: a single canonical map from which every sealed
artifact / witness region / memo-lattice node derives its address; the non-overlap + single-source
invariant becomes a build gate. *Review:* directly compatible; strengthens the Forge with a working
large-scale precedent. III's content addresses are hashes (M6), not integers — so III's version is a
hash-keyed namespace, not a flat integer map, but the *discipline* is identical.

**T2. Capability-token algebra → III M8 (capabilities as sheaf sections → fibrations).**
CHARIOT's 32-byte MAC-verified tokens with `SUBDIVIDE / REVOKE / QUORUM_ISSUE / TIME_LOCK_ISSUE /
NIZK_PROVE / NIZK_VERIFY / COINAGE / STREAM_APPEND` are a concrete capability *vocabulary*. III transform:
give `aether/capability.iii` the same operational algebra (attenuate/subdivide/revoke/quorum/time-lock),
backed by III's NIH crypto (the token MAC = HMAC; NIZK = III's `zk_snark`). *Review:* deterministic +
algebraic ⇒ fully M8/M3-compatible; high-value, the richest direct transfer.

**T3. Runtime self-attestation (`HV_LIVE_VERIFY`) → III runtime `.text` mhash verify.**
The driver hashes its own `.text` with NIH SHA-256 and compares to an embedded `anchor.text_integrity_hash`.
III has *build-time* determinism (iiis-2≡iiis-3) and seals; this extends it to **runtime**: an III binary
that re-hashes its own code section against its sealed `mhash` and emits a witness on match/mismatch.
*Review:* novel for III, fully M2/M6/M10-compatible (deterministic, witnessed). Pairs with embedding the
artifact's seal as an anchor in its own `.rdata` (the PE emitter already has a reserved anchor slot).

**T4. Crash-forensic diagnostic region → III witness diagnostic ring (the CRASH-DEBUGGING-PROTOCOL made native).**
A fixed last-page ring of `{function_id, proof_hash, timestamp}` that survives a crash. III transform:
a fixed-offset witness diagnostic ring so a crash leaves a forensic proof chain (the protocol's
"observability" requirement, structurally). *Review:* it's witnessing (M6/D6) — compatible; directly serves
the CLAUDE.md crash protocol.

**T5. Landauer/ergo cost + adaptive precision lattice → new M19 cost-lattice dimension, enmeshed with M9.**
`sma_landauer_record(bits_erased, ergo_cost)` + `sma_qformat_select_for_ergo(budget)` (pick the cheapest
Q-format that fits an ergo budget). III transform: add a **thermodynamic dimension** to the M19 cost
lattice (Landauer cost of bit erasure), and make it *enmesh with M9 reversibility* — reversible operations
erase no bits ⇒ ergo-free; only irreversible ops are charged. A precision/representation chosen by ergo
budget. *Review:* deterministic + algebraic ⇒ M2/M19-compatible; a genuinely beautiful unification of M9
(reversibility) + M19 (cost) via physics. Strong candidate.

**T6. COW MMU (4-level radix, PTE COW/DIRTY) → III M9 reversibility mechanism.**
`SmaMmu` with `mark_cow`/`cow_resolve`, page-level copy-on-write. III transform: a COW layer over
`memoria` (arena/region) so reversible-by-default state is cheap (only dirtied pages are logged).
*Review:* compatible; gives M9 a concrete, efficient mechanism instead of full backward logs.

**T7. Coordinate-addressed crystal cells (`VMRUN_COORD`, 2048×256B cells by coord) → III content-addressed dispatch / memo lattice.**
CHARIOT abolished named module slots: executable "crystals" live at *coordinate* addresses and are
dispatched by coordinate. This is M6 (content addressing) + M17 (memo lattice keyed by content hash) +
the v3 content-addressed-computation telos, in working form. III transform: confirm/strengthen the
memo-lattice + Forge design where artifacts/results are addressed by a derived content coordinate, not a
name; "VMRUN-by-coord" ↔ "memo-lookup-by-hash". *Review:* compatible; a real-world proof of the v3
content-addressing direction.

**T8. Bounds-paranoid NIH PE introspection (`pe_introspect.c`) → III binary-verification & crash tooling.**
Re-derives every PE offset, bounds-checks every dereference (built to scan crash dumps where "MZ" can be
coincidental), RVA→file-offset with permissive fallback. III transform: harden `tp_pe_hex`/`tp_x86_disasm`
with the same discipline for the determinism gate + the crash protocol's "disassemble the actual binary,
verify machine code matches source." *Review:* compatible; directly serves III's existing PE/disasm path.

**T9. Deterministic fixed-point transcendentals (`sma_q16_math.c`: Newton sqrt/rsqrt, Padé exp, range-reduced ln) → III M2-safe transcendentals.**
Zero-FPU, bit-exact integer transcendentals. III transform: if III ever needs `exp`/`ln`/`sqrt` (cost
models, the algebraic primitive's diffusion, fixed-point analysis) it must use deterministic integer
methods, not `float` (which breaks M2 across platforms). *Review:* compatible; a ready reference for
`numera/fixed`-style deterministic transcendentals.

**T10. The firmware brick-IOCTLs ARE III's hexad brick-patterns (the safety resonance, not a transfer).**
CHARIOT's `HV_PSP_SEND`, `HV_SMRAM_PROBE`, SMM_BASE/microcode MSR writes are the literal hardware
referents of III's 6 hexad PFS brick patterns (`me_psp_mailbox`, `smram_write`, `microcode_load`,
`real_nvram_write`, `bootorder_set`, `capsule_update`). *Insight:* III's hexad bricking taxonomy is the
*formal safety model* of exactly the operations CHARIOT performs. This validates the hexad admission set
against a real system — and suggests III's hexad classifier could one day *gate* a CHARIOT-class driver's
IOCTLs (III as the deterministic safety kernel over a hypervisor). *Review:* III stays user-space and
deterministic; this is conceptual alignment + a long-horizon federation idea, not a V1 transfer.

**T11. NIH deflate / json (`FOUNDATION/sma_deflate.c`, `sma_json.c`) → optional III utilities.** *(pending read)*
Self-contained compression/serialization. *Review:* lower priority; III's M6 "algebraic witness
compression" is a different (algebraic) thing, not deflate. Note only.

**T12. Atomic content-addressed deploy + verify + rollback (`atomic_deploy.c`) → III reversible reseal (the answer to reseal-fear).**
SHA-256 the build artifact and the deployed artifact; snapshot the prior into `snapshots/<sha>/`
(content-addressed); deploy; **re-hash the deployed bytes**; if they ≠ the intended hash, atomically
roll back to the prior snapshot so the final state is **byte-equal to before**. NO-CHANGE short-circuit
when build-hash == deployed-hash (drift-driven, = D12). Exit codes make the irreducible "rollback
failed" red state explicit (0 verified / 1 mismatch+rolled-back / 2 rollback-failed / 3 internal).
III transform: every III **reseal** (golden roll, compiler bootstrap reseal, Forge artifact seal)
becomes snapshot(content-addressed by mhash) → reseal → verify-deployed-mhash → rollback-to-snapshot-
on-mismatch, with a byte-equality (**M9 reversibility**) guarantee. *Review:* this is the concrete,
proven mechanism behind the "safe-by-shadow / reversible reseal" the Forge needs — and the **direct
answer to the reseal-bricking fear**: a reseal that cannot leave a worse state than it started, because
the prior is content-addressed and restoration is byte-verified. Fully M2/M6/M9/D12-compatible; among
the highest-value transfers.

**T13. TPM-bound sovereign signing + Authenticode-normalized content hash (`sovereign_sign.c`) → III hardware-anchored artifact seal (connects #3/#13/#14).**
NIH PE signer: SHA-256 over the **Authenticode-normalized** image (excludes the mutable checksum field,
cert-directory entry, and cert trailer ⇒ a content hash stable across (re)signing); sovereign key via TPM
(`NCryptOpenKey("CHARIOT_SOVEREIGN_KEY")`, MS_PLATFORM_CRYPTO_PROVIDER — **key never leaves silicon**);
**ECDSA-P384** sign; NIH minimal ASN.1/DER + PKCS#7 emit; canonical PE-checksum recompute; `--self-test`
hashes its own bytes. III transform: make the **Founders-Anchor / federation seal hardware-bound** (TPM,
never-exfiltrated key, optionally bound to a CHIP_IDENTITY fingerprint) signing III artifacts with
`numera/ecdsa_p384.iii` (already wired, #3) over an Authenticode-normalized content hash → Windows-verifiable
signed III binaries; advances the anchor-genesis path (#13/#14) with a real hardware root of trust. *Review:*
deterministic + III-native crypto ⇒ compatible; the NIH ASN.1/DER emitter is a ready reference if III needs
X.509/PKCS#7 interop; the normalization (stable hash excluding signature-mutable fields) is exactly what the
T3 runtime self-attestation needs.

**T14. Quiesced atomic hot-swap + vtable dry-run + triple-tier rollback (`hot_swap_orchestrator.c`) → III live/reversible upgrade + the shadow-rehearsed reseal.**
Live driver-code replacement without reboot: a **quiesce conductor** (broadcast NMI → per-CPU latch state
machine RUNNING→NMI_TAKEN→RELEASED, poll-with-timeout) stops the world, swaps `.text`, verifies, resumes;
the new `.text` SHA-256 becomes the AegisAnchor; **three independent rollback tiers** (atomic_deploy snapshot
+ `_pre_swap.sys` + PCR-sealed boot fingerprint). Crucially the whole orchestration is **parameterized over
ops vtables** (`PcrSealOps`/`MiniLoaderHostOps`/`HvQuiesceOps`/hot-swap host-ops) so it runs in a **userspace
deterministic dry-run that exercises every step except the kernel round-trip** — "a live runtime invariant in
the deploy pipeline." III transform: (a) `omnia/jit_swap.iii` gains quiesce+verify+resume; (b) **the Forge's
seal-critical reseals (hexad #8) become vtable-parameterized and shadow-rehearsed** — run the entire reseal
against a deterministic dry-run vtable first (the dry-run *is* the "safe-by-shadow" verify), only then commit.
*Review:* with T12 this is the **reseal-fear answer**: reseals are atomically reversible (T12) AND fully
rehearsable in userspace before touching anything (T14). The vtable-dry-run is a clean, mandate-compatible
testability pattern III should adopt broadly. (Note: CHARIOT's live kernel hot-swap IOCTL is staged; the
orchestration + dry-run is real and exercised.)

**T15. TPM PCR-sealed measured-boot fingerprint (`chariot_pcr_seal.c`) → III anchor sealed to measured-boot state.**
The boot fingerprint is sealed to TPM PCRs (PCR-extend = SHA-256(prev‖digest); the seal blob unseals only if
the PCR mask matches) — measured boot: the seal opens only if the boot chain wasn't tampered. III transform:
III's determinism golden / Founders-Anchor can be **PCR-sealed** so it unseals only under a matching
measured-boot state, binding III's seal to platform integrity. *Review:* connects T3 + T13 + #13/#14;
deterministic; compatible. Advanced/optional (requires a TPM) — document as a hardening tier, not a V1 need.

### The deploy/seal cluster as one discipline (T12–T15)
Together: **content-addressed snapshot → shadow-rehearse via dry-run vtables → sign with a TPM-bound key →
deploy → re-hash-verify the deployed bytes → atomically roll back (3 tiers) on any mismatch → seal the
result to measured boot.** This is a complete *reversible, rehearsable, hardware-anchored upgrade* discipline.
For III it is the concrete, proven shape of the safe Forge reseal — and the definitive answer to "a reseal
must never be able to leave a worse state."

**T16. Manifest↔consumer BIJECTION + capability-bound manifest + manifest digest (`ioctl_codegen.c`) → the Forge manifest's proof gate, done right (2nd proof of the Forge pattern).**
This IS the Sovereign Forge, already working in CHARIOT for the IOCTL/capability surface: a single-source
manifest (`ioctl_manifest.gk`: `schema_version`, `manifest_hash_seed`, `ioctl NAME { code; cat; in; out; cap }`)
→ a generator that (a) **validates a strict bijection** — every `PLAT_IOCTL_*` header define ↔ exactly one
manifest entry with a matching code, in *both* directions, no duplicate codes/names; (b) emits a generated
dispatch header (`_dispatch_gen_ioctl.h`, "DO NOT EDIT") with a code-sorted table; (c) folds an **FNV-1a
manifest digest** committing the whole surface, which the Aegis attestation engine verifies (the
`MANIFEST_IOCTL_BIJECTION` rule). Each entry carries its required **`cap`** — the manifest binds every
operation to its capability (T2/M8). III transform: (1) the Forge manifest↔consumers relation should be a
**verified bijection** (every sovereign artifact ↔ exactly one ledger row; every generated consumer ↔ exactly
one source) — STRONGER than a byte-compare drift check, and it closes the "stale manifest / generator-without-
a-row" gap flagged in `SOVEREIGN_FORGE.md` §8; (2) each ledger row carries its required **capability** (M8),
making the manifest a capability-binding table, not just a registry; (3) a single **manifest digest**
content-addresses the whole sovereign surface (= the ledger closure root). *Review:* the **second independent
working instance of the Forge pattern** in the user's ecosystem (after `gen_compositions.sh`) — strong design
validation. Reinforces the **native-III directive**: CHARIOT uses an external `.gk` + C generator; III's
version should be native — manifest as an `.iii` value, generation via XII/`tp_`, the bijection proof in the
CIC kernel, the digest via `sanctus/mhash`. Same pattern, sovereign substrate.

**T17. The Aegis rule registry + paired-mutator gate + receipt chain (`sma_aegis.{h,c}`) → III's Forge proof-gate family + automated crash-protocol + the (generator,proof) Curry-Howard pairing. [CAPSTONE]**
Aegis (Sovereign Verification Substrate, v10) is a registry of ~40+ named invariant rules over the emitted
PE, each a `{witness fn `ae_w_*` → verdict + evidence_hash[32], version, flags}` producing an `AegisReceipt`
(72 B). Rule classes: **PE structure** (PE_SIG, PE_CHECKSUM_VALID, PE_MACHINE_AMD64, FILE_ALIGNMENT_512,
DLL_CHARACTERISTICS_NX, NO_UNEXPECTED_SECTIONS, DRIVERENTRY_AT_TEXT_RVA); **machine-code semantics** —
`CLI_STI_BALANCE`, `PUSHPOP_BALANCE`, `CLGI_STGI_PAIRED`, `VMRUN_BRACKETED`, `NO_DOUBLE_POP_RBX`,
`DECODE_CLEAN`, `REX_WELLFORMED`, `NO_ORPHAN_REX`, `ASID_NONZERO`, `VMRUN_COUNT_MATCHES`; **dispatch
bijection** (`PERFECT_HASH_BIJECTION`, IOCTL_CODE_RANGE, SUCCESS/FAIL_IOCTL_EXISTS, DISPATCH_FALLTHROUGH);
**commitments** (TEXT_INTEGRITY, RDATA_INTEGRITY — record a hash, not pass/fail). The `MUTATION_REQUIRED`
flag **pairs each verifier `ae_w_` with the mutator `ae_m_` that establishes the property** — proof and
producer co-defined. A `closure_digest` commits the exact TCB source-file closure; the **AegisAnchor**
(384→416 B in `.rdata`) embeds typed Merkle roots: capability-tree root (depth-21, 2M-leaf Merkle tree of
32-B `CapabilityToken`s), silicon fingerprint (CPUID brand‖patch‖features — a "Ring -4 witness", detects
silicon drift), IOCTL-permission-table hash, ring-taxonomy hash (the canonical signed -4..+4 nine-ring
string, hashed — "declares the ring set itself"). Capability model includes `AntiCapability` (negative
authority that blocks a positive token) and `CoinMaster` (HMAC bulk-issuance, with a documented
v1→v2 master-recovery-attack fix). III transforms: (1) **the Forge proof-gate family IS a rule registry**
like Aegis — each sovereign artifact's proof a named rule → a receipt `{name, verdict, evidence_hash}` = a
theorem carrier (M18); the receipt chain is the witness (M6/M12). (2) **The Forge's `(generator, proof)`
pairing = Aegis's `(mutator, witness)` MUTATION_REQUIRED pairing** = M11 Curry-Howard at the artifact level;
enforce that neither changes without the other. (3) **The CRASH-DEBUGGING-PROTOCOL's manual binary checks
(stack balance, callee-saved preservation, decode-clean, disasm-matches-source) become an automated rule
registry over III's emitted PEs** — Aegis is the *automated form of the protocol* the user's CLAUDE.md
mandates by hand; this alone is worth the harvest. (4) `closure_digest` = III's D8 closure pins + seal as one
committed root; the ring-taxonomy/IOCTL-table hashes = "the structure declares and seals itself" (M7/M8).
(5) `AntiCapability` = first-class negative authority for III's capability algebra (T2). *Review:* fully
deterministic + NIH-crypto + machine-checked ⇒ M2/M6/M8/M11/M18-compatible; **the single richest transfer** —
it gives III's Forge proof-gate family a mature, proven shape and automates the crash protocol. Native-III
form: rules as `.iii` predicates over the disassembly (`tp_x86_disasm`), receipts via `sanctus/witness`,
the registry sealed via `sanctus/mhash`, the (gen,proof) pairing enforced by the build gate.

**T18. SVM-guarded probe (fault contained in a throwaway guest) + positive control (`probe_ring2.c`) → III shadow-execution safety + control-paired proofs.**
CHARIOT tests a dangerous `WRMSR` by executing it **inside a throwaway SVM guest**: a locked MSR makes the
*guest* `#GP` (`VMEXIT_EXCP_13`, caught by the host) instead of crashing the host — the fault becomes
structured data (verdict WRITABLE / LOCKED / OTHER_EXCP / SHUTDOWN), and a known-writable control MSR
(`TSC_AUX`) validates that the probe itself works (positive control beside the negative test). Hardware
reads (SMRAM/TPM/PSP/SPI/BIOS-shadow) go through the IOCTL surface, fault-as-data throughout. III
transforms: (1) **seal-critical/dangerous operations run shadow-executed** in an isolated deterministic
context (`omnia/sandbox_exec` + the T14 dry-run vtable) so failure is observed as data, never a crash — the
operation-level form of "BSOD acceptable, bricking never"; (2) **every III proof gate pairs a negative test
with a positive control** so a "pass" cannot be a false-negative — reinforces the existing "no tautological
proof tests" rule; (3) fault-as-structured-data = the crystal/witness model (D7). *Review:* deterministic +
contained ⇒ compatible; the shadow-execution pattern is the operational core of the safe-reseal discipline
(with T12/T14).

---

## 4. The hard exclusion (what must NOT come into III)

CHARIOT is, above the FOUNDATION, an **AGI cognition substrate**: dense neural weight tensors, attention,
Hebbian updates, embeddings, a transformer, homeostatic *drives*, observational *crystallization* ("after
enough activations, promote"), curiosity/surprise learning. **All of this violates III M3 (no ML, no
statistical/observational learning) and the standing "no observational learning ever" rule.** It stays in
CHARIOT. *Critical nuance:* the *data structures* are often deterministic and DO transfer (KB triple-store,
TMS justification DAG, RETE matcher, blackboard regions, coordinate cells); the *learning dynamics* do not.
Transfer the structure, never the statistics.

---

## 5. v3-and-beyond impact + open questions

- **Content-addressed dispatch (T7)** is independent real-world evidence for III's v3 memoization lattice
  (M17) and content addressing (M6): CHARIOT already dispatches code by coordinate; III memoizes by hash.
- **Self-attestation (T3) + capability algebra (T2) + ring-transition witness** sketch a path where III is
  the *deterministic, proof-carrying safety kernel* and a CHARIOT-class driver is the *hardware actuator* it
  gates — i.e., III's hexad/witness/capability layer governing real Ring-(-1/-2) operations. That is a
  "beyond v3" federation story worth a deliberate decision.
- **Open questions for the user:** (a) Which transfers do you want pursued (T1/T2/T3/T4/T5 are the
  highest-value, all V1/V2-compatible)? (b) Is the long-horizon "III-gates-CHARIOT" direction (T10/T2/T3)
  something to seed now in III's design, or strictly later? (c) Do you want the genuine hardware addresses
  (§2.2) folded into an III reference module for the ISA/hardware roadmap (#29), or kept as documentation
  only?

---

## 6. Continuation queue (files still to read deeply)

- **Deploy/seal:** `BUILD/atomic_deploy.c`, `BUILD/deploy/sovereign_sign.c`,
  `BUILD/deploy/hot_swap_orchestrator.c`, `BUILD/deploy/check_probe_matrix_complete.c` — atomic
  deployment + signing + hot-swap = III's reseal/deploy discipline.
- **GPU:** `GPU/sma_spv_validate.c` (SPIR-V *validator* — a verifier, mildly III-relevant), `sma_gpu_manifold.c`,
  `sma_gpu_attention.c`, `sma_gpu_sdf.c`, `sma_spv_matmul_tiled.c`, `sma_spv_asm.c`, `sma_gpu_transformer.c`
  (mostly the ML/compute layer — review for the deterministic SPIR-V emit/validate parts only).
- **FOUNDATION:** `sma_deflate.c`, `sma_json.c`, `sma_vk_types.h`, `sma_platform_win.c`/`_linux.c`,
  `sma_crystal_primitive.c`, `sma_crystal_reactions.c`, `sma_types.h`, `sma_win32_shim.h`.
- **PE emit:** `LINK/sma_pe_emit_platform.c` (700KB — read the section/IAT/anchor-emit logic), `LINK/sma_pe_emit.c`,
  `LINK/sma_link.c`, `LINK/manifest/ioctl_codegen.c` (IOCTL manifest codegen — the capability/manifest spine).
- **Probes/aegis:** `BUILD/sma_aegis.c` (180KB — the attestation engine), `chariot_aegis_verify.c`,
  `aegis_metaverify.c`, the `probe_carousel_*` family, `probe_ring2.c`, `vmrun_test.c`, `probe_disasm_round_trip.c`.
- **Compiler:** `LINK/gestalt-k/parser/parser.c`, `gestalt_k_build.c` (the .sov compiler — compare to iiis).
- **TOOLS:** `npt-observer/npt_observer.c`, `adapter_minidump.c` (minidump parsing — crash forensics);
  the `sma_chat.c`/`sma_autonomous.c`/`sma_browser.c` cognition tools are mostly ML-layer (skim for the
  deterministic dispatch/address-map usage only).

---

## 7. Grounding in the Convergence Gospel (the master plan)

The decisive correction: **the harvest is not a new "Forge" — every pattern lands on a *named gospel
module*** (`III_CONVERGENCE_GOSPEL`, Part VIII Natural Order + Part IX module specs). CHARIOT supplies
mature, battle-tested *operational* mechanisms; the gospel's modules are the *substrate* target, and the
gospel's forms are frequently **richer** (a lattice, LTL model-checking, Keccak256 witness fragments). What
I'd been calling the "Sovereign Forge" is precisely the gospel's **`aether/manifest` (M8) + `numera/constitution`
(M14) + `numera/constitution_preserver` (M19) + `aether/snapshot_lattice` (M31) + the D-contracts** — already
in the plan.

| Harvest pattern | Gospel module(s) | CHARIOT (operational) vs gospel (substrate) |
|---|---|---|
| **T17** Aegis rule registry + (mutator,witness) pairing | `numera/constitution_preserver.iii` (M19) + clause schema (Part VII) | Aegis: C rules → receipts. Gospel: **LTL clauses → model-checked Compliance Witnesses**; `(witness_rule, predicate)` = `(mutator, witness)`; Aegis machine-code rules become III clauses over the disasm |
| **T12** content-addressed snapshot + rollback | `aether/snapshot_lattice.iii` (M31, W26) + `numera/reversible.iii` (M5) | CHARIOT: file-level deploy snapshot+verify+restore. Gospel: **per-op snapshot lattice** (`snap_id=Keccak256(ante‖op‖time)`, meet, retroactive query), W26 "consulted before destructive ops" |
| **T2** capability-token algebra | `aether/cap_forge.iii` (M37) + `aether/capability.iii` (M30) | CHARIOT: 32-B MAC tokens (subdivide/revoke/quorum/time-lock/coinage/anti-cap). Gospel: capabilities as **sheaf sections → fibrations**; W18 immutable after forging |
| **T3** runtime self-attestation | `numera/quine_verifier.iii` (M20, W25) + `aether/bone_marrow.iii` (M27, W30) | CHARIOT: driver SHA-256 of own `.text` vs anchor. Gospel: **seed reconstruction from running state** at every phase boundary; bone-marrow seal verified every boot |
| **T16** manifest↔consumer bijection | `aether/manifest.iii` (M8) + `numera/constitution.iii` (M14) | CHARIOT: ioctl_codegen bijection + FNV-1a digest. Gospel: provenance manifests + ratified clauses; the bijection is a constitutional invariant |
| **T7** content-addressed dispatch | `numera/content_addr.iii` (V3 M55) + `numera/memo_lattice.iii` (V3 M58) + `memo_query` (M69) | CHARIOT: VMRUN-by-coordinate. Gospel: `content_address = Keccak256(producer‖op‖input_commitment)` keys the **memo lattice** (M17); witness payload kinds 0x0D–0x0F |
| **T5** Landauer/ergo cost + precision lattice | `numera/cost_lattice.iii` (M22) + `cost_calculus` (M23) + `cost_lattice_synth` (V3 M65) | CHARIOT: ergo-cost ledger + Q-format ergo cascade. Gospel: **cost vector + 5-D K** (M19, W37/W43); ergo/Landauer is a candidate dimension; cost_overrun_handler (M81) |
| **T6** COW MMU | `numera/reversible.iii` (M5, backward continuations) + `reversibility_audit` (M33) | mechanism for M9 reversibility-by-default |
| **T10** firmware brick patterns | `aether/firmware_quarantine.iii` (M26, "forbidden region sheaf", M5/W21) | CHARIOT's PSP/SMRAM/microcode IOCTLs ARE the regions firmware_quarantine enumerates; the 6 hexad brick-patterns are their formal model |
| **T13** TPM-bound signing | `aether/node_identity.iii` (M28, "federation-ready keys at boot") + threshold sig (W23/W24) | CHARIOT: TPM `CHARIOT_SOVEREIGN_KEY` + ECDSA-P384. Gospel: boot-time federation keys |
| **T14** quiesced hot-swap + dry-run + triple rollback | `aether/phase_orchestrator.iii` (M32) + `aether/triple_check.iii` (M44) + snapshot_lattice | CHARIOT: NMI-quiesce + vtable dry-run + 3-tier rollback. Gospel: phase entry/closure gating + algebraic consensus on critical ops (W27) |
| **T15** PCR measured-boot seal | `aether/boot_fold.iii` (M29, "boot as algebraic fold") + bone_marrow (W30) | CHARIOT: PCR-sealed boot fingerprint. Gospel: boot as a verified fold over the seed |
| **T18** SVM-guarded shadow probe + control | `aether/triple_check.iii` (M44, W27) + W20 "probes reversible or refused" + `cp_quorum_tier` Speculative | CHARIOT: dangerous op in a throwaway guest, fault-as-data + positive control. Gospel: Speculative tier (isolated, merge via bisimulation) |
| **T8** PE introspection / disasm verify | `BOOT/cg_pure.iii` (M40) + the disasm path | crash-protocol binary checks, automated |
| **T9** deterministic transcendentals | `numera/galois.iii` (M4) + `cost_calculus` closed-forms | M2/M15 deterministic math, no FPU |

### Key reconciliations (gospel ideal ↔ CHARIOT ↔ real III tree)
- **Hash:** CHARIOT uses SHA-256 (+ FNV-1a witness pulse); the gospel mandates **Keccak256** for V2/V3 witness fragments + content addresses (M6). III's `sanctus/mhash` is SHA-256 today → the homegrown-primitive / Keccak question (the earlier fork) lives exactly here.
- **Rings:** gospel = R0/R-1/R-2 (Sanctum)/R-3 (Apex, bounded reflection); CHARIOT extends to **9 rings -4..+4** (R-4 silicon-witness, R+4 federation-join). CHARIOT's wider taxonomy is a candidate enrichment for III's ring model (the silicon-witness ring ties to T13/T15).
- **Native vs external:** CHARIOT uses external `.gk` manifests + C generators + a C rule engine; the gospel's equivalents are **native `.iii` modules** (manifest, constitution, constitution_preserver). This is exactly the user's "as/by/in III, not `.def`" directive — confirmed by the master plan.
- **Witness:** CHARIOT FNV-1a pulse {ordinal,tsc,exit,rip} → gospel Keccak256 fragment {producer,op,in_commit,out_commit,algebraic_time,antecedents,payload} (Part VI). The gospel's is the richer target; CHARIOT's is the lightweight runtime form.

### Reality reconciliation (gospel = ideal; the real tree is what's built)
The gospel is the north star; per `FORWARD_REFERENCES.md` the real substrate uses different nomenclature and
is "way beyond/behind" the idealized stages in places. **Verifying which gospel modules exist in the live
`STDLIB/iii/` tree vs are still planned** (snapshot_lattice, constitution_preserver, cap_forge, quine_verifier,
firmware_quarantine, content_addr, memo_lattice, reversible, boot_fold, phase_orchestrator, triple_check,
bone_marrow, node_identity) — results folded in below.

**CONFIRMED (Glob of the real `STDLIB/iii/` tree):** *none* of the gospel's idealized Part IX modules exist
verbatim — no `snapshot_lattice`, `constitution_preserver`, `quine_verifier`, `firmware_quarantine`,
`content_addr`, `memo_lattice`, `reversible`, `cap_forge`, `proof_term`, `theorem_carrier`, `curry_howard`,
`witness_spine`, nor the SAT/SMT/egraph/groebner/category/sheaf tower, nor any V3 cognition module. **The real
substrate has diverged substantially from the gospel.** It is organized as:
- **`sanctus/`** (governance + sealing + K + XII-curation): `mhash, witness, kchain, closure, attest, mandate,
  mandate_m22, seal_resolver, genesis, promote, demote, quality, quality_q7, irreducibility_proof, calculus_v1,
  catalyst, resolver_replay` + the XII sphere `xii_curate, anchor_xii, xii_sml, xii_atm, xii_antidrift,
  xii_register_all`.
- **`aether/`** (federation + net + capability): `capability, cap_handshake, fed_seal, fed_admit, fed_tier,
  fed_sybil, fed_eclipse, fed_genesis, sealed_channel, pattern_set_federation, net, tcp, inet, http,
  http_server, http_client, fs, handle, babel_wire, idoc`.
- **`numera/`**: a full real crypto+math suite (not the gospel's galois/sat/smt tower).
- **`omnia/`**: collections + the `tp_*` transform pipelines + `xii_*` + `resolver_memo, sid, sandbox_*`.

The real III is **ahead** of the gospel in crypto, XII, and federation, and **different/behind** in the
category-theory/SAT/cognition tower. The gospel is north-star *intent*; the real tree is the system; this
divergence is the "new stuff / subject to change" the user flagged.

**Three-layer anchoring (the actionable form):** each harvest pattern → gospel intent module → **real-tree home**
(existing-to-enrich, or a new forward-reference):

| Pattern | Gospel intent | Real-tree home / action |
|---|---|---|
| T17 rule registry / automated crash-protocol | constitution_preserver (M19) | **enrich** `sanctus/mandate` + `xii_antidrift` + `irreducibility_proof`; **add** a disasm-rule layer over the PE emitter |
| T12 reversible reseal | snapshot_lattice (M31, W26) | **NEW FR** — no snapshot module exists; add per-op content-addressed snapshot+rollback to `sanctus` (extends `closure`/golden); the bricking-fear answer |
| T3 runtime self-attestation | quine_verifier (M20, W25) | **enrich** `sanctus/attest` + `irreducibility_proof`; runtime `.text`-mhash verify |
| T2 capability algebra | cap_forge (M37) + capability (M30) | **enrich** real `aether/capability` + `cap_handshake` (subdivide/revoke/quorum/time-lock/anti-cap) |
| T7 content-addressed dispatch | content_addr/memo_lattice (V3 M55/M58) | **enrich** `omnia/resolver_memo` + `sanctus/seal_resolver` toward the content-addressed memo lattice |
| T10 brick patterns | firmware_quarantine (M26) | the **real hexad brick-patterns** (FR #8) are the model; a firmware_quarantine module is forward work |
| T13 TPM-bound signing | node_identity (M28) | **enrich** `aether/fed_seal`/`fed_genesis` + `sanctus/genesis` (Founders-Anchor #13/#14) |
| T5 ergo/cost dimension | cost_lattice (M22) | **enrich** `sanctus/kchain` (the real K-chain) with a Landauer/thermodynamic dimension |
| T14/T18 dry-run + shadow probe | phase_orchestrator (M32) + triple_check (M44) | **enrich** `omnia/sandbox_exec` + the reseal path with vtable dry-run + fault-as-data + positive control |

The harvest is therefore a set of **grounded forward-references against the real tree**, each carrying a mature
CHARIOT reference mechanism + a gospel intent. That is the bridge: **CHARIOT (operational) → gospel (intent) →
real III (the system to enrich)**.
