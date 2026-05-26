# III-GENESIS-VECTOR.md — The Polymorphic Deployment Installer Architectural Mandate

**Document Identity:** GENESIS-VECTOR / Architectural Mandate / Cluster K Item 177
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-10+ implementation.** This document specifies the deployment vector by which III installs itself on a target machine without triggering hostile defenses (Windows Defender, SELinux, UEFI Secure Boot), without modifying firmware, and without bypassing legitimate signing infrastructure. The Genesis Vector is the bridge from "III is a research substrate" to "III is the operator's planetary-deployable computational environment."
**Version:** 1.0 — 2026-05-03 (Wave 10.2)
**Sources:** All 15 R1-sealed specs; III-PORTABILITY.md; III-FOUNDERS-ANCHOR.md; III-LEGACY-INGESTION.md; III-SANDBOX.md; III-SOVEREIGN-WEB.md; ADR-017 (no-firmware-write); ADR-018 (software-only DRTM); Stateful Neumann §3.2 (Windows coexistence).
**Cluster K item:** 177 (Genesis Vector — The Deployment Problem).
**Sibling Wave-10 doc:** III-SANDBOX.md (items 86-90).

---

## §0. Preamble — The Deployment Problem

III is the perfect substrate. But how does it actually get onto the world's machines?

Standard hardware requires **physical access** to install a Ring -2 hypervisor (boot from external media, modify EFI). If the operator tries to push III over the legacy internet:

- **Windows Defender** flags it as "the most sophisticated rootkit ever designed" and quarantines.
- **Linux SELinux** denies the kernel module load due to unfamiliar signatures.
- **UEFI Secure Boot** rejects unsigned bootloader payloads.
- **macOS Gatekeeper** refuses to run unsigned binaries.
- **Network defenders** block traffic patterns that don't match expected legacy protocols.
- **Endpoint protection** quarantines anything that looks like a kernel-mode driver from an untrusted publisher.

The substrate cannot achieve planetary scale by demanding the operator physically visit every target machine. It cannot achieve planetary scale by hostile evasion of legitimate security measures (which would itself be a constitutional-tier compromise per III-FOUNDERS-ANCHOR.md). It must deploy through **legitimate channels**, with **legitimate signing**, in a form that **legacy defenses recognize as benign**.

The **Genesis Vector** is the polymorphic deployment installer:

1. The operator obtains a legitimate code-signing certificate (from DigiCert, Sectigo, GlobalSign, Comodo, Apple Developer ID, etc. — purchased and held with the operator's own legal identity).
2. The operator signs the III installer with the legitimate certificate.
3. The installer presents itself as a standard enterprise utility — a "kernel performance analyzer," a "system diagnostics tool," a "driver framework."
4. Windows Defender, SELinux, UEFI Secure Boot, and macOS Gatekeeper all accept the signed installer.
5. The installer, once executed, performs a **software-only DRTM relaunch** to slide beneath the host OS.
6. Once the substrate is mounted, the host OS continues normal operation under III's R-1 hypervisor.

This is **not** a rootkit. It is **not** an attack. It is **legitimate installation through legitimate channels**, with the operator's full legal accountability (the operator owns the code-signing certificate and is the legal signing authority).

The discipline:

- The Genesis Vector uses **no exploits**, no zero-days, no privilege escalation bugs.
- The installer is a normal Windows kernel-mode driver / Linux kernel module / macOS KEXT, signed under the operator's legitimate certificate.
- The installer's **payload** is the substrate; the payload's actions are within the kernel-mode driver's normal authority.
- After installation, the substrate continues operating under R-1; the operator can audit the installation; revocation is operator-controlled.

This document specifies:

1. **§1** — The legitimate signing model
2. **§2** — The installer's polymorphic disguise
3. **§3** — The Trinity-gated entry into the substrate
4. **§4** — The software-only DRTM relaunch
5. **§5** — The intent + cap + causality + sanctum-state pre-discharge bundle
6. **§6** — Per-architecture installer variants
7. **§7** — Deployment channels
8. **§8** — Post-install verification
9. **§9** — Conformance criteria
10. **§10** — Final statement

---

## §1. The Legitimate Signing Model

### §1.1 The mandate

The Genesis Vector is **always signed under the operator's own legitimate code-signing certificate**. The certificate:

- Is purchased from a recognized Certificate Authority (DigiCert, Sectigo, GlobalSign, Comodo, etc.).
- Is held in the operator's legal name.
- Can be revoked by the operator if compromised (CRL/OCSP propagation).
- Carries the operator's legal accountability for what is signed.

### §1.2 The signing infrastructure

The operator maintains:

- **A code-signing certificate per platform**: Windows Authenticode (e.g., DigiCert EV Code Signing), macOS Developer ID (Apple Developer Program), Linux package-signing key (e.g., GPG key for RPM/DEB).
- **An air-gapped signing machine**: the certificate's private key never touches a networked machine. Signing happens via QR code transfer (per III-FOUNDERS-ANCHOR.md §7.1).
- **A revocation playbook**: if a certificate is compromised, the operator immediately revokes via the CA's revocation portal, then publishes a new signing key.

### §1.3 The non-disguised substrate

Crucially, the substrate **does not lie about what it is**. The signed binary's:

- Subject Name (CN) is the operator's legal name + the substrate name (e.g., "Edwin Boston / III Substrate v1.0").
- File Description: `III - Sovereign Computational Substrate`.
- Internal product description: `III Reduction Graph Engine`.
- Version: matches the substrate's R1 composite root prefix.

The polymorphism (per §2) is the **packaging** — what file extension, what installer wrapper, what user-facing description — not the substrate's identity. The substrate **always identifies itself accurately to anyone who inspects**.

### §1.4 Why this is not a rootkit

A rootkit:

- Is signed with a stolen/forged certificate.
- Misrepresents its identity to defenders.
- Bypasses revocation by hiding from the CRL.
- Has no operator legal accountability.

The Genesis Vector:

- Is signed with the operator's legitimate certificate.
- Identifies itself accurately (per §1.3).
- Is revocable via standard CRL.
- Has full operator legal accountability.

These distinctions are what make this deployment legal and ethical.

---

## §2. The Installer's Polymorphic Disguise

### §2.1 The mandate

The Genesis Vector adapts its **packaging** (not its identity) to match the legitimate-utility patterns expected by legacy defenders:

| Platform | Polymorphic packaging |
|----------|------------------------|
| Windows | A Windows Installer Service (.msi) carrying a kernel-mode driver (.sys), signed with EV Code Signing |
| Linux | A DEB/RPM package carrying a kernel module (.ko), signed with the operator's GPG key |
| macOS | A .pkg installer carrying a System Extension (.systemextension) or KEXT, signed with Apple Developer ID |
| ARMv8 (Linux) | DEB/RPM with kernel module .ko; same as Linux |
| RISC-V | DEB/RPM with kernel module .ko; same as Linux |
| Embedded | Custom installer per target embedded OS |

### §2.2 The user-facing description

The installer's user-facing UI describes the substrate truthfully:

- Title: `Install III - Sovereign Computational Substrate`
- Subtitle: `A research-grade substrate for typed effectful computation with mathematical immunity`
- Operator name: prominently displayed
- License: open-source license (e.g., MIT, BSD, or operator-chosen)
- Source code: linked URL where the operator publishes
- Revocation contact: operator's email / website

Users see exactly what they are installing. There is no deception.

### §2.3 The Windows-specific packaging

```
III-Substrate-v1.0.0.msi
├── Setup wizard (legitimate Microsoft Installer)
├── Pre-install: license acceptance + admin elevation prompt
├── Files installed:
│   ├── C:\Program Files\III\iii-platform.sys (kernel driver, EV-signed)
│   ├── C:\Program Files\III\iii-controller.exe (R3 user-mode controller, EV-signed)
│   ├── C:\Program Files\III\iii-uninstall.exe (uninstaller)
│   ├── C:\Program Files\III\docs/* (documentation)
│   └── C:\Program Files\III\closure-root.txt (the substrate's R1 root for verification)
├── Service installation: iii-platform service, manual-start by default
├── Post-install: verification - the user can run "iii-controller verify" to confirm installation
├── Uninstall: full removal via standard Windows uninstaller
```

### §2.4 The Linux-specific packaging

```
iii-substrate_1.0.0_amd64.deb (or .rpm)
├── Pre-install: GPG signature verification by apt/dnf
├── Files installed:
│   ├── /lib/modules/<kernel-ver>/iii.ko (kernel module, GPG-signed)
│   ├── /usr/sbin/iii-controller (R3 user-mode binary)
│   ├── /usr/share/doc/iii-substrate/* (documentation)
│   └── /etc/iii/closure-root.txt (R1 root for verification)
├── DKMS integration for kernel updates
├── systemd unit: iii-platform.service (manual-start by default)
├── Post-install: verification via iii-controller --verify
├── Removal via standard apt/dnf uninstall
```

### §2.5 The macOS-specific packaging

```
III-Substrate-1.0.0.pkg
├── Pre-install: Apple Developer ID signature verification (Gatekeeper)
├── Notarization: Apple-notarized for distribution outside Mac App Store
├── Files installed:
│   ├── /Applications/III.app (Universal Binary: x86_64 + arm64)
│   ├── /Library/SystemExtensions/com.eboston.iii (System Extension, Developer ID-signed)
│   ├── /Library/Frameworks/IIIRuntime.framework (R3 user-mode framework)
│   └── ~/Library/Application Support/III/closure-root.txt
├── User Approval: SystemExtension requires explicit user approval in System Preferences
├── Removal via standard /Applications drag-to-trash or /usr/local/bin/iii-uninstall
```

---

## §3. The Trinity-Gated Entry into the Substrate

### §3.1 The mandate

The first execution of the installed substrate is itself a **Trinity-gated cycle**. The substrate's first cycle invocation:

1. Establishes the operator's intent (operator clicked "install" → intent witness).
2. Establishes the cap (the operator has Administrator/sudo/root → cap acquired).
3. Establishes the causality (the host OS just executed the installer → causality witness).
4. Establishes the sanctum state (the substrate's sealed-cycle-box-1 is allocated → sanctum witness).
5. Constructs the substrate's initial closure root (per III-MODULES §10).
6. Performs the software-only DRTM relaunch.

### §3.2 The intent witness

The installer captures operator intent:

```
INSTALL_OPERATOR_INTENT_WITNESS {
    operator_pubkey: bytes[32],         // Operator-signed key for this install
    operator_signature: bytes[64],      // Signature on the install directive
    operator_name: string,              // From the install dialog
    install_timestamp: u64,
    target_machine_fingerprint: mhash,  // CPUID + memory size + closure root
    expected_substrate_version: string,
    intent_hash: mhash,                 // Hash over all the above
}
```

### §3.3 The cap witness

The substrate verifies the user has appropriate privileges:

- Windows: the Windows Installer's MSIEXEC has elevated to admin → admin SID is captured in the witness.
- Linux: the user has root via sudo → captured.
- macOS: the user has approved the System Extension → captured.

Without these capabilities, the substrate's first cycle invocation fails; the install does not complete; the substrate falls back to user-mode-only operation.

### §3.4 The causality witness

The substrate verifies the install context:

- Was the host OS just running an MSIEXEC / dpkg / installer process?
- Is the timestamp recent (no replay attack)?
- Is the operator signature valid?

Failure → install does not complete; the user is shown an error.

### §3.5 The sanctum witness

The substrate's first sealed-cycle box (`XII_SANCTUM_SEAL_GENESIS_DRTM = 0`) is allocated. The sealed box holds the seed for the substrate's first DRTM relaunch.

### §3.6 The Trinity gate

The Trinity gate evaluates:

- SCBA: is the operator's pubkey in the closure-pinned admit list? (Or is this the very first install, in which case the operator's pubkey *becomes* the closure-pinned Anchor pubkey at genesis.)
- ACC Wall-Y: does the install operation type-check against the substrate's expected sequence?
- Trinity Gate convergence: do all four (intent + cap + causality + sanctum) align?
- (For genesis install, the Founder's Anchor cosignature is **the operator's own signature on the install directive** — same key as the closure-pinned pubkey).

All checks pass → DRTM relaunch proceeds. Failure → install fails; substrate falls back to user-mode.

---

## §4. The Software-Only DRTM Relaunch

### §4.1 The mandate

Per ADR-018 and III-PORTABILITY.md §8.4: III performs DRTM **software-only**. No TXT, no SKINIT, no TPM. The DRTM relaunch is a **substrate-internal handoff** that establishes a fresh cryptographic epoch.

### §4.2 The DRTM relaunch sequence

```iii
cycle drtm_relaunch_genesis(
    operator_intent: OperatorIntent,
    sanctum_seed: bytes[32]
) -> Witness
    @ring(R-2)
    @hexad(DRTM_RELAUNCH_GENESIS)
    @sanctum_only
{
    forward {
        // 1. Quiesce all CPUs (per AMD-V VMRUN cessation, per III-PORTABILITY.md).
        // 2. Atomically transition substrate state to "DRTM relaunching."
        // 3. Generate fresh per-CPU sub-keys via HKDF(operator_intent || sanctum_seed || epoch).
        // 4. Re-derive the substrate's master key.
        // 5. Re-attest closure root (verify against installed binary).
        // 6. Emit DRTM quote with the new epoch.
        // 7. Resume CPUs in substrate-controlled mode.
        // 8. Mark genesis complete; transition state to "running."
    }
}
```

### §4.3 The substrate's first epoch

After DRTM relaunch, the substrate is in **epoch 0** (genesis). Subsequent operations advance the epoch. The first epoch's witnesses chain into the substrate's first audit chain.

### §4.4 The Anchor's role

For the genesis install:

- The operator's installer-signing key becomes the closure-pinned Anchor pubkey.
- A backup Anchor key (separately generated) is also closure-pinned at genesis.
- Both keys are stored in the substrate's LEXICON via `frozen` constants.

### §4.5 The post-install state

After the relaunch:

- The host OS continues running (now as a guest of III's R-1 hypervisor).
- The substrate's audit chain is initialized.
- The federation peer-info is published (if the operator opted in).
- The substrate's R1 composite root is computed and published.

### §4.6 The verification

Post-install, the operator runs:

```
iii-controller verify
=> Substrate version: 1.0.0
   Closure root: 0x...
   R1 composite root: 0x...
   Anchor pubkey: 0x...
   DRTM quote chain length: 1
   Federation peers: 0
   First-install timestamp: 2026-05-03T...
   ✓ Substrate operational.
```

---

## §5. The Intent + Cap + Causality + Sanctum-State Pre-Discharge Bundle

### §5.1 The mandate

The substrate's first cycle invocation requires all four to be present **before any execution**. The installer **carries** these in its payload:

```iii
schema GenesisDischargeBundle {
    intent: OperatorIntent,                  // Operator-signed
    cap: ExpectedAdminCap,                   // Expected administrator capability
    causality_proof: CausalityProof,         // Proof that this is a fresh install
    sanctum_seed: bytes[32],                 // Initial sanctum slot 0 seed
    bundle_signature: Signature,             // Operator-signed over all above
}
```

### §5.2 The bundle's role

The bundle is **pre-computed by the operator** before the installer is built. The operator:

1. Generates the operator-signing keypair on the air-gapped machine.
2. Signs an `OperatorIntent` directive specifying the substrate version, target architecture, and timestamp.
3. Constructs a `CausalityProof` referring to the operator's intent.
4. Generates a fresh `sanctum_seed` (32 random bytes from hardware RNG).
5. Signs the `GenesisDischargeBundle`.
6. Bundles into the installer.

### §5.3 The verification at first invocation

When the installer is first executed, the substrate verifies:

- The bundle's signature.
- The intent's timestamp is recent (no replay).
- The operator's pubkey matches the install certificate (or matches a closure-pinned operator-pubkey if not the genesis install).
- The cap matches the actual environment (admin/sudo/root verified).
- The sanctum_seed has the expected entropy properties.

Verification fails → install fails; the substrate does not proceed.

### §5.4 The bundle as substrate-genesis

For the operator's first install (genesis), the bundle is the **founding document** of the substrate. The bundle's signing key becomes the Anchor pubkey; the bundle's mhash becomes part of the closure root; the bundle's sanctum_seed initializes sanctum slot 0.

For subsequent installs (operator installs III on a second machine), the bundle is verified against the **already-published Anchor pubkey** in the substrate's LEXICON. The new install joins the federation as a new peer with its own peer-info (per III-SOVEREIGN-WEB.md §4).

---

## §6. Per-Architecture Installer Variants

### §6.1 The mandate

The Genesis Vector is **architecture-aware**. Per III-PORTABILITY.md §1, the installer detects the target architecture and deploys the appropriate substrate binary.

### §6.2 The cross-architecture single installer

A single `III-Substrate-1.0.0.msi` (or `.deb`, `.rpm`, `.pkg`) carries:

- AMD-Zen / Intel-VMX kernel module (`iii-amd64.sys` or `iii-amd64.ko`).
- ARMv8 kernel module (`iii-arm64.sys` or `iii-arm64.ko`).
- RISC-V kernel module (`iii-riscv64.ko`).
- POWER9 kernel module (`iii-ppc64.ko`).

The installer detects the architecture and installs the appropriate one. The closure root is **architecture-independent** (per III-PORTABILITY.md §7); the same R1 root works across architectures.

### §6.3 The fat-binary discipline

Per macOS's Universal Binary tradition, the substrate's user-mode binaries are built as **fat binaries**: same binary file contains x86_64, arm64, and (where applicable) other architecture machine code. Linux uses package architecture-specific subpackages; Windows uses ARM64-on-ARM and x64-on-x64 separately or via WoA emulation.

### §6.4 The cross-architecture testing

Each per-architecture installer passes the cross-architecture conformance harness (per III-PORTABILITY.md §9 / Wave 3 C-PORT-18) before being signed for distribution.

---

## §7. Deployment Channels

### §7.1 The mandate

The Genesis Vector is distributed through **legitimate distribution channels**:

| Channel | Vetting | Distribution Scale |
|---------|---------|----------------------|
| Operator's website (HTTPS download) | Operator-signed; user-verified | Direct |
| GitHub releases | GitHub's signature verification + operator's GPG | Direct |
| Microsoft Windows Store | Microsoft-vetted | Wide |
| Apple Mac App Store | Apple-vetted; Notarization | Wide |
| Apt repository (Linux DEB) | GPG-signed; mirror network | Wide |
| RPM repository (Linux RPM) | GPG-signed; mirror network | Wide |
| Helm charts (Kubernetes operator) | Signed Helm charts | Cloud |
| Chocolatey (Windows) | Operator-vetted via Chocolatey moderators | Direct |
| Homebrew (macOS) | Operator-vetted via Homebrew Casks | Direct |

### §7.2 The user opt-in discipline

Each install requires:

1. User has explicitly chosen to install (not automatic).
2. User has consented to the install (via the installer's UI).
3. User has provided administrative privileges.
4. User has accepted the substrate's license terms.

There is no auto-deployment. There is no silent install. Every install is **operator-explicitly-chosen**.

### §7.3 The federated distribution

Existing III peers can serve the installer to new installs (peer-to-peer distribution). The installer is signed; new installs verify the signature; no trust transfer is needed beyond the operator's certificate.

### §7.4 The revocation discipline

If the operator's signing certificate is compromised or revoked:

1. The CA propagates the revocation via CRL/OCSP.
2. New installs from non-revoked sources fail signature verification.
3. Existing installs continue running but cannot be re-installed.
4. The operator publishes a new signed release; users can manually update.

---

## §8. Post-Install Verification

### §8.1 The mandate

Every install is verified by the user via a tool:

```
iii-controller verify
```

The tool:

1. Reads the installed `closure-root.txt` (the substrate's R1 root claim).
2. Computes the actual closure root from the installed binaries.
3. Compares.
4. Reports match/mismatch.

### §8.2 The optional federation registration

If the user opts in:

```
iii-controller federate-register --operator-pubkey <hex>
```

The substrate registers with the federation; broadcasts its peer-info; awaits federation peer recognition.

### §8.3 The audit chain initialization

Post-install, the operator can query:

```
iii-controller audit-chain --epoch 0
```

This shows the substrate's first epoch witnesses, including:

- Genesis install witness.
- DRTM relaunch witness.
- Sanctum slot 0 initialization.
- First federation peer-info publication.

### §8.4 The uninstall discipline

The substrate is **fully uninstallable** via standard OS uninstall mechanisms. Uninstall:

1. Stops the iii-platform service.
2. Removes the kernel module.
3. Restores the pre-install OS state (the OS is no longer a guest of III).
4. Emits the final witness chain segment to a backup file.
5. Removes installed files.

After uninstall, the OS continues normal operation. The operator retains the witness chain backup for audit.

---

## §9. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-GENESIS-1 | The installer is signed under the operator's legitimate code-signing certificate (per item 177) |
| C-GENESIS-2 | The certificate's subject contains the operator's legal name |
| C-GENESIS-3 | The substrate identifies itself accurately to anyone who inspects the binary |
| C-GENESIS-4 | The installer is acceptable by Windows Defender, SELinux, UEFI Secure Boot, macOS Gatekeeper |
| C-GENESIS-5 | The installer's pre-install signature verification is passed by all relevant defenders |
| C-GENESIS-6 | The installer's user-facing UI describes the substrate truthfully |
| C-GENESIS-7 | The installer carries a complete `GenesisDischargeBundle` |
| C-GENESIS-8 | The bundle's signature is verified at first execution |
| C-GENESIS-9 | The DRTM relaunch is software-only (no TXT, SKINIT, TPM) |
| C-GENESIS-10 | The first cycle invocation passes Trinity gate (intent + cap + causality + sanctum) |
| C-GENESIS-11 | For genesis install, the operator's signing key becomes the closure-pinned Anchor pubkey |
| C-GENESIS-12 | The backup Anchor pubkey is also closure-pinned at genesis |
| C-GENESIS-13 | The substrate enters epoch 0 after successful DRTM relaunch |
| C-GENESIS-14 | The first audit chain entry includes the install witness chain |
| C-GENESIS-15 | The cross-architecture installer detects the target architecture and installs the right binary |
| C-GENESIS-16 | Per-architecture binaries pass the cross-architecture conformance harness before distribution |
| C-GENESIS-17 | The Windows installer integrates with MSIEXEC; the Linux with apt/dnf; macOS with pkg |
| C-GENESIS-18 | The substrate is fully uninstallable; uninstall restores pre-install OS state |
| C-GENESIS-19 | Post-install verification (`iii-controller verify`) detects closure-root tampering |
| C-GENESIS-20 | The substrate's first invocation does NOT use exploits, zero-days, or privilege escalation bugs |

---

## §10. Final Statement

The Genesis Vector is the architectural commitment that **III deploys through legitimate channels with legitimate signing, while preserving its terminal nature**. The substrate is not a rootkit; it is an operator-signed kernel-mode driver that, once installed, mounts itself as the substrate beneath the host OS via software-only DRTM.

The polymorphic packaging ensures that every legacy defender (Windows Defender, SELinux, UEFI Secure Boot, macOS Gatekeeper) sees the installer as a normal signed enterprise utility — because that's exactly what it is. The substrate identifies itself accurately; the operator's legal identity is bound to the certificate; revocation works through standard CRL.

The first-execution Trinity gate (intent + cap + causality + sanctum) ensures that the install is operator-authorized; the software-only DRTM relaunch ensures no firmware mutation; the closure-root verification ensures the substrate is what the operator built.

This is the bridge from "III as research substrate on Edwin's machine" to "III as planetary-deployable computational environment." The operator can install III on every machine they own, every machine in their organization, every machine in their federation — without compromising legitimate security infrastructure, without misrepresenting the substrate, without bypassing operator legal accountability.

This is the answer to item 177. Wave 10.2 is the realization that III's terminal nature includes a **deployment story** — not as a hostile takeover but as a legitimate, operator-signed, user-consented installation.

*Wave 10.2 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new platforms, new packaging) or Tier-3 amendment (signing-discipline structure).*
