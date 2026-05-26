# III-CRYPTO-AGILITY.md — Cryptographic Agility Architectural Mandate

**Document Identity:** CRYPTO-AGILITY / Architectural Mandate / Cluster K Item 176
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-0+ implementation.** This document is sealed alongside Wave 0; future re-canonical-form rolls are Catalyst-promoted appends only.
**Version:** 1.0 — 2026-05-03 (Wave 0.4)
**Sources:** All 15 R1-sealed specs at `Desktop/III/DOCS/`; this document is the architectural mandate that supersedes their hardcoded `SHA-256` / `BLAKE3` / `Ed25519` / `HMAC-SHA-256` / `HKDF` / `Wesolowski-VDF` references — those become the *default suite* (`0x0001`); other suites are sealed in here for the Tier-3-amendment-swappable surface.
**Sibling derivative docs:** III-STDLIB.md, III-CONSTANTS.md, III-ERRORS.md, III-FOUNDERS-ANCHOR.md.

---

## §0. Preamble — The Temporal Threat

III's mathematical immunity rests on **SHA-256, BLAKE3, Ed25519, HMAC-SHA-256, HKDF-SHA-256, and Wesolowski-VDF**. Each is rigorously analyzed and currently believed secure. None will survive **Q-Day**: the moment cryptographically-relevant quantum computers (CRQCs) become operational and Shor's algorithm becomes a routine attack against Ed25519 (any elliptic-curve discrete-log scheme), Grover's algorithm halves the effective security of every symmetric-hash (SHA-256 → ~128-bit security against quantum search, still acceptable for short-term but vulnerable for permanent-record use), and Lattice-class quantum attacks become practical.

A system designed to last forever cannot hardcode pre-quantum math. III must be able to **swap its entire cryptographic primitive set** atomically at any epoch — without source rewrites, without re-canonicalizing the 15 sealed specs, without breaking historical witness chains.

This is the **Cryptographic Agility** mandate. It is item 176 of the operator's Cluster K reality-check pass, integrated into Wave 0 as a foundational architectural commitment. It establishes:

1. A **uniform interface** behind which every cryptographic primitive lives.
2. A **suite-identifier convention** so the active primitive set is named, witnessed, and swappable.
3. A **Tier-3 amendment mechanism** for swapping suites (always co-signed by the Founder's Anchor — item 178).
4. A **multi-suite verification regime** so historical witnesses (signed under prior suites) remain verifiable across epoch boundaries.
5. **NIH discipline**: every post-quantum suite is hand-rolled from FIPS / NIST publications. No `liboqs`. No `pqclean`. No `kyber-rs`. No third-party PQC library.

---

## §1. The Uniform Interface

Every cryptographic operation in III flows through:

```iii
crypto.<primitive>(suite_id: u64, args: Glyph) -> Glyph @ring(R-2, R-1, R0, R3) @hexad(CRYPTO_<PRIMITIVE>)
```

The first parameter is always `suite_id` — a 64-bit identifier that selects the active implementation. The runtime dispatches to the registered implementation for that suite + primitive pair.

### §1.1 The 8 Primitive Categories

| Category | Operation | Default (suite 0x0001) | Post-quantum candidate (suite 0x0100) |
|----------|-----------|------------------------|----------------------------------------|
| Hash | `crypto.hash(suite, data) -> mhash` | SHA-256 (32 B) | SHAKE-256 (32 B output) |
| Cryptographic hash (long output) | `crypto.hash_long(suite, data, len) -> [u8; len]` | BLAKE3 | SHAKE-256 |
| MAC | `crypto.mac(suite, key, data) -> mac` | HMAC-SHA-256 (32 B) | HMAC-SHAKE-256 (32 B) |
| KDF | `crypto.kdf(suite, salt, info, len) -> [u8; len]` | HKDF-SHA-256 | HKDF-SHAKE-256 |
| Signature | `crypto.sign(suite, sk, msg) -> sig` / `crypto.verify(suite, pk, msg, sig) -> bool` | Ed25519 (sk 32B, pk 32B, sig 64B) | Dilithium-5 (sk 4880B, pk 2592B, sig 4595B) + SPHINCS+-256s (sk 128B, pk 64B, sig 49856B) |
| KEM | `crypto.kem_encap(suite, pk) -> (ct, ss)` / `crypto.kem_decap(suite, sk, ct) -> ss` | (none — pre-quantum substrate uses ECDH if needed) | Kyber-1024 (pk 1568B, sk 3168B, ct 1568B, ss 32B) |
| VDF | `crypto.vdf_eval(suite, x, t) -> y` / `crypto.vdf_verify(suite, x, t, y, π) -> bool` | Wesolowski-VDF over RSA-2048 group | Wesolowski-VDF over class-groups (post-quantum candidate) |
| Random | `crypto.random(suite, len) -> [u8; len]` | ChaCha20 over hardware entropy | ChaCha20-blake3 over hardware entropy (no change at Q-Day; symmetric-stream cipher remains safe) |

### §1.2 Type-Level Discipline

Every `crypto.*` call:

- Is annotated `@hexad(CRYPTO_<PRIMITIVE>)` — the hexad's pillar 1 is POS (read/compute is reversible-by-identity for hashes; reversible-by-cosignature for signatures); pillar 4 is whatever tier the call inherits; pillars 2, 3, 5, 6 are derived from context.
- Carries a runtime `suite_id` parameter — the type system verifies the suite is registered at compile time.
- Emits a witness with `crypto_suite_id` recorded in flag bits (extending the witness `flags` field at offset 0x64 — bits 16..23 reserved for active suite ID lower-byte; bits 24..31 reserved for upper-byte tag).

---

## §2. Cryptographic Primitive Registry

Every active suite is registered in `STDLIB/crypto/registry.III`. The registry is closure-pinned and Tier-3-amend-able only.

```iii
module crypto.registry @ring(R-2, R-1, R0, R3) @plan_anchor(CRYPTO_AGILITY) {
    schema RegistryEntry = {
        suite_id: u64,
        name: string,
        hash: fn(data: bytes) -> mhash,
        hash_long: fn(data: bytes, len: u32) -> bytes,
        mac: fn(key: bytes, data: bytes) -> bytes,
        kdf: fn(salt: bytes, info: bytes, len: u32) -> bytes,
        sign: fn(sk: bytes, msg: bytes) -> bytes,
        verify: fn(pk: bytes, msg: bytes, sig: bytes) -> bool,
        kem_encap: fn(pk: bytes) -> (bytes, bytes),
        kem_decap: fn(sk: bytes, ct: bytes) -> bytes,
        vdf_eval: fn(x: bytes, t: u64) -> (bytes, bytes),
        vdf_verify: fn(x: bytes, t: u64, y: bytes, pi: bytes) -> bool,
        random: fn(len: u32) -> bytes,
    }

    cycle register_suite(entry: RegistryEntry) -> Witness
        @ring(R-2)
        @hexad(CRYPTO_REGISTRY_REGISTER)
        @sanctum_only
        @tier(constitutional)
    {
        forward {
            // Witness emission with suite_id recorded.
            // Tier-3 amend.apply + Founder's Anchor cosignature required.
        }
    }
}
```

---

## §3. Suite Catalogue

| Suite ID | Name | Status | Hash | MAC | KDF | Signature | KEM | VDF |
|----------|------|--------|------|-----|-----|-----------|-----|-----|
| `0x0001` | Pre-quantum default | **active at substrate genesis** | SHA-256 + BLAKE3 | HMAC-SHA-256 | HKDF-SHA-256 | Ed25519 | (none — ECDH on demand) | Wesolowski over RSA-2048 |
| `0x0100` | Post-quantum strong (Kyber-1024 + Dilithium-5 + SPHINCS+-256s) | reserved; activate via Tier-3 amendment | SHAKE-256 | HMAC-SHAKE-256 | HKDF-SHAKE | Dilithium-5 + SPHINCS+-256s (dual) | Kyber-1024 | Wesolowski over class-groups |
| `0x0200` | Post-quantum lighter (Kyber-768 + Dilithium-3 + SPHINCS+-192f) | reserved | SHAKE-256 | HMAC-SHAKE-256 | HKDF-SHAKE | Dilithium-3 + SPHINCS+-192f | Kyber-768 | Wesolowski over class-groups |
| `0x0300` | Hybrid (pre-quantum + post-quantum dual-signed) | reserved; for migration window | SHA-256 + BLAKE3 + SHAKE-256 | HMAC-SHA-256 + HMAC-SHAKE-256 | HKDF-SHA-256 + HKDF-SHAKE | Ed25519 + Dilithium-5 (both required) | Kyber-1024 | Wesolowski over class-groups |
| `0x0400`–`0x0FFF` | Reserved-future | for additional NIST-standardized PQC primitives | — | — | — | — | — | — |
| `0x1000`–`0xFFFF` | Reserved for Catalyst-promoted research suites | per Tier-3 + Founder's Anchor | — | — | — | — | — | — |

---

## §4. Suite Identifier Convention

The `suite_id` is a 64-bit field with this layout:

| Bits | Semantics |
|------|-----------|
| 0..15 | Suite class (0x0001..0xFFFF) — the catalogue entry above |
| 16..23 | Suite minor version (0..255) — for spec-compatible enhancements within a suite |
| 24..31 | Patch revision (0..255) |
| 32..47 | Hash-function variant tag (e.g., 0x0001 = SHA-256, 0x0002 = BLAKE3, 0x0100 = SHAKE-256) |
| 48..55 | Signature-suite variant tag |
| 56..63 | Reserved-for-Catalyst |

For example, `0x0000_0000_0000_0001` = pre-quantum default v1.0.0 patch 0; `0x0000_0000_0000_0100` = post-quantum strong v1.0.0 patch 0; `0x0001_0000_0000_0300` = hybrid suite minor-version 1.

---

## §5. The Suite-Swap Mechanism

Swapping the active suite is a **Tier-3 unanimous-quorum constitutional amendment** that always requires **Founder's Anchor cosignature** (per item 178 — III-FOUNDERS-ANCHOR.md).

### §5.1 The amendment

```iii
amend.apply(
    target: crypto.active_suite,
    new_value: 0x0300,  // hybrid suite, for example
    cosignature: founders_anchor_signature
) @tier(constitutional)
```

### §5.2 Cascade effects on swap

When the active suite changes, the substrate must:

1. Re-derive every per-CPU HMAC sub-key under the new suite's HKDF (per CYCLES §4.4 / STDLIB §14.4).
2. Re-compute every cycle's `proof_certificate.closure_root` under the new hash.
3. Re-compute the substrate's R1 composite root under the new hash.
4. Emit a new DRTM quote at offset 0x160 with the new `suite_id`.
5. Update every active sealed-call's intent token under the new sub-key.
6. Federate the swap to all peers; peers must adopt the swap simultaneously (DRTM-relaunch synchronized).

### §5.3 Witness preservation

Witnesses signed under the prior suite **remain verifiable under their original suite_id**. The `flags` field's `crypto_suite_id` bits identify which suite to use for verification. Old witnesses are not re-signed; they retain their original cryptographic guarantee.

A historical chain replay must:

1. Walk the witness chain backwards.
2. At each witness, read its `crypto_suite_id`.
3. Look up the corresponding suite's verifier in `crypto.registry`.
4. Verify the HMAC + signature + hash under that suite.

This means **the registry must retain entries for every prior active suite forever** — even after the operator swaps to a newer one.

---

## §6. Per-Primitive Specifications (Hand-Rolled)

### §6.1 SHA-256 (suite 0x0001)

Hand-rolled per FIPS 180-4 in `COMPILER/BOOT/sha256.{h,c}`. NIH-extreme: no `openssl/sha.h`, no `mbedtls/sha256.h`, no `WinAPI BCryptHashData`. Implementation:

- 64-round Merkle-Damgård with custom round constants.
- AVX-512 / SHA-NI hardware acceleration when available (Wave 1 — `BOOTSTRAP/sha256_shani.S`); pure-C fallback in `sha256.c`.
- Hand-rolled test corpus: NIST KAT vectors covering 0-byte through 1-MiB inputs.

### §6.2 BLAKE3 (suite 0x0001)

Hand-rolled per the BLAKE3 specification (Aumasson, Neves, O'Hearn, Winnerlein 2020) in `COMPILER/BOOT/blake3.{h,c}`. Tree-mode for parallel hashing. AVX-512 fast path when available.

### §6.3 SHAKE-256 (suite 0x0100, 0x0200, 0x0300)

Hand-rolled per FIPS 202 (SHA-3 derived; Keccak-f[1600] permutation) in `COMPILER/BOOT/shake256.{h,c}`. Variable-length output. Domain-separation via the cryptographic-output-mode tag.

### §6.4 HMAC-SHA-256, HMAC-SHAKE-256

Hand-rolled per RFC 2104 (HMAC) in `COMPILER/BOOT/hmac.{h,c}`. Generic over hash function — instantiated for SHA-256 and SHAKE-256.

### §6.5 HKDF-SHA-256, HKDF-SHAKE

Hand-rolled per RFC 5869 (HKDF) in `COMPILER/BOOT/hkdf.{h,c}`. Generic over MAC function.

### §6.6 Ed25519 (suite 0x0001)

Hand-rolled per RFC 8032 in `COMPILER/BOOT/ed25519.{h,c}`. Curve25519 in twisted-Edwards form. Constant-time. Hand-rolled scalar arithmetic; no external curve library.

### §6.7 Dilithium-5 (suite 0x0100, 0x0300)

Hand-rolled per FIPS 204 (NIST PQC ML-DSA) in `STDLIB/crypto/dilithium5.III` and `STDLIB/crypto/dilithium5.{h,c}`. Lattice-based signature. Constant-time SamplerInBall. Fiat-Shamir transform over module lattice.

Specifications: Module-LWE (security level 5; 256-bit classical, 192-bit quantum). Public key 2592 B; secret key 4880 B; signature 4595 B.

### §6.8 SPHINCS+-256s (suite 0x0100)

Hand-rolled per FIPS 205 (NIST PQC SLH-DSA) in `STDLIB/crypto/sphincs256s.III` and `STDLIB/crypto/sphincs256s.{h,c}`. Stateless hash-based signature. WOTS+ + FORS + hypertree.

Specifications: SHA-256-based variant (also SHAKE-256 variant available). Public key 64 B; secret key 128 B; signature 49,856 B (long but stateless and quantum-secure).

**Witness layout impact:** SPHINCS+ signature size (~49 KB) does not fit in the 128-byte Witness's signature region. Resolution: use Dilithium-5 (4595 B) as the primary post-quantum signature; SPHINCS+-256s is the *backup* for catastrophic Dilithium-break scenarios. SPHINCS+ signatures, when used, are placed in a separate per-witness sidecar segment (witness gains a `sidecar_mhash` reference; the sidecar lives in a separate per-CPU long-signature ring).

### §6.9 Dilithium-3 + SPHINCS+-192f (suite 0x0200, lighter-weight)

Hand-rolled in same fashion. Smaller parameters; signature 2420 B for Dilithium-3.

### §6.10 Kyber-1024 (suite 0x0100, 0x0300)

Hand-rolled per FIPS 203 (NIST PQC ML-KEM) in `STDLIB/crypto/kyber1024.III` and `STDLIB/crypto/kyber1024.{h,c}`. Module-LWE-based KEM.

Specifications: Public key 1568 B; secret key 3168 B; ciphertext 1568 B; shared secret 32 B. Used during sealed-cycle key establishment when ECDH is unavailable post-Q-Day.

### §6.11 Kyber-768 (suite 0x0200)

Hand-rolled per FIPS 203 (smaller parameter set).

### §6.12 ChaCha20 (random)

Hand-rolled per RFC 8439 in `COMPILER/BOOT/chacha20.{h,c}`. Used as a CSPRNG over hardware-entropy seed. No change at Q-Day (symmetric-stream).

### §6.13 Wesolowski VDF over RSA-2048 (suite 0x0001)

Hand-rolled per Wesolowski 2018 paper in `COMPILER/BOOT/vdf_rsa.{h,c}`. RSA-2048 group with secure prime generation. Verifiable through Pietrzak/Wesolowski proof.

### §6.14 Wesolowski VDF over class groups (suite 0x0100, 0x0200, 0x0300)

Hand-rolled in `STDLIB/crypto/vdf_classgroup.III` and `STDLIB/crypto/vdf_classgroup.{h,c}`. Class-groups of imaginary quadratic fields — believed quantum-resistant (no known efficient quantum algorithm for the underlying class-number-computation problem).

---

## §7. NIH Implementation Discipline

**Forbidden:**
- `liboqs` (Open Quantum Safe library)
- `pqclean` (PQ Clean reference implementations)
- `kyber-rs`, `dilithium-rs`, any Rust crate
- `BoringSSL`, `OpenSSL`, `mbedTLS`, `WinCrypto`/`BCrypt`
- `libsodium`, `monocypher`
- Any pre-existing Coq/Lean/Cryptol formal-verified implementation

**Required:**
- Each primitive hand-implemented from the FIPS / NIST / RFC publication, line-by-line, with footnoted reference annotations.
- Test corpus: NIST Known-Answer Tests (KAT) for every supported parameter set.
- Constant-time discipline: all secret-data operations are constant-time; verified by `iii-timing-audit` tool (Wave 0+).
- Side-channel resistance: counter-cache-timing, counter-Spectre/Meltdown via the same IBPB+VERW+SSBD discipline used in Sanctum entries.
- Memory-zeroing of intermediate secret state on function exit (volatile-pointer + memory-fence).
- No dynamic allocation in cryptographic core paths (stack-only or pre-allocated arenas).

---

## §8. Migration Path

### §8.1 Phase 0 — Substrate Genesis (current Wave 0)

Substrate ships with suite `0x0001` active. All sealed specs reference this suite. The other suites (0x0100, 0x0200, 0x0300) are **registered but inactive** in `crypto.registry`.

### §8.2 Phase 1 — Pre-Q-Day Hybrid (operator-decided, on threat-intelligence trigger)

Operator triggers Tier-3 amendment swapping active suite to `0x0300` (hybrid). All new witnesses signed under both Ed25519 + Dilithium-5; all hashes computed under both SHA-256 and SHAKE-256. Witness storage doubles for the duration of this phase. Old witnesses remain verifiable under their original `0x0001` signatures.

### §8.3 Phase 2 — Post-Q-Day Pure (CRQC threat materializes)

Operator triggers second Tier-3 amendment swapping active suite to `0x0100` (pure post-quantum). All new witnesses signed under Dilithium-5 only. Phase-1 hybrid witnesses remain verifiable under their dual-signature; their Ed25519 component is no longer cryptographically meaningful (Shor's), but the Dilithium-5 component remains valid.

### §8.4 Phase 3 — Long-Term Post-Quantum

Sustained operation under suite `0x0100`. SPHINCS+-256s sidecars used for high-stakes constitutional amendments (where stateless hash-based signature provides defense-in-depth).

### §8.5 Sample timeline

This is *operator-controlled*; not part of the spec:

```
Year 0 (Wave 0):  Substrate ships, suite 0x0001 active.
Year ?:           NIST CRQC threat-intelligence published.
Year ?+1:         Tier-3 amendment to 0x0300 (hybrid).
Year ?+2..?+5:    Hybrid operation; double-signed witnesses.
Year ?+5:         CRQC threat materializes.
Year ?+5+ε:       Tier-3 amendment to 0x0100 (pure post-quantum).
Year ?+5+ε..∞:    Long-term post-quantum.
```

The operator decides the timing of these transitions based on real-world threat intelligence. The substrate is **prepared** for any timing.

---

## §9. Affected Specifications (Cascade List)

When the active suite changes, the following sealed specs reference the active suite implicitly via `crypto.<primitive>` calls (the indirection means the specs *don't* need re-canonicalization — that's the entire point of Crypto Agility):

| Spec | Crypto-dependent operations |
|------|------------------------------|
| A1 LEXICON | Closure-root hashing of canonical source (`crypto.hash`) |
| A2 GRAMMAR | (no direct crypto; AST mhashes computed at compile) |
| A3 TYPES | Proof-certificate signatures (`crypto.sign`) |
| A4 EFFECTS | (no direct crypto; effects use witnesses) |
| A5 CYCLES | Witness HMAC (`crypto.mac`); witness body hash (`crypto.hash`); HKDF sub-key derivation (`crypto.kdf`) |
| A6 HEXAD | Bitmap mhash (`crypto.hash`) |
| A7 PHASES | (no direct crypto; cross-ring marshalling uses witnesses) |
| A8 SANCTUM | Sanctum sub-key HKDF (`crypto.kdf`); DRTM quote signature (`crypto.sign`); intent token MAC (`crypto.mac`); VDF (`crypto.vdf_*`) |
| A9 TRINITY | SCBA hash (`crypto.hash`); convergence-point body hash |
| A10 MODULES | Module manifest signature (`crypto.sign`); closure-root hash (`crypto.hash`) |
| B1 CATALYST | Promotion witness MAC (`crypto.mac`); proposal signing (`crypto.sign`) |
| B2 FEDERATION | Peer DRTM-quote verification (`crypto.verify`); witness-signature trailer (`crypto.sign`); Kyber-KEM if available (`crypto.kem_encap` / `crypto.kem_decap`) |
| B3 CONFORMANCE | Conformance verifier output signature (`crypto.sign`) |
| C1 ABI | (no direct crypto; bootstrap-only) |
| IDX | R1 composite hash (`crypto.hash`) |

**Total: 11 of 15 sealed specs reference cryptographic operations indirectly.** With Crypto Agility, suite swaps are atomic at the registry level; the sealed specs themselves never need re-canonicalization.

---

## §10. Backward Compatibility — Multi-Suite Verification

The registry retains entries for every prior active suite. A witness chain replay walks each witness, reads its `crypto_suite_id`, looks up the suite in `crypto.registry`, and verifies under that suite's primitives.

Conformance criterion (proposed C-A4-Crypto-Agility-1):

> Every witness in the chain back to epoch 0 verifies under its own `crypto_suite_id`'s registered primitives. Verifier emits per-witness verification status; aggregate must be 100%.

A peer joining the federation must:

1. Receive the federation's R1 composite root (signed under current active suite).
2. Verify the R1 signature under that suite's verifier.
3. If the peer's local active suite differs, both peers must converge to the federation-current suite (via Tier-3 amendment if they don't already match).

---

## §11. Hybrid-Mode Discipline

Suite `0x0300` (hybrid) requires **dual signing** for every signature operation:

```iii
crypto.sign(suite=0x0300, sk_pair=(ed25519_sk, dilithium5_sk), msg) -> (ed25519_sig, dilithium5_sig)
```

Both signatures are stored. Both must verify on `crypto.verify(suite=0x0300, ...)`. If either fails, verification fails.

This doubles signature bandwidth and storage during the migration window but provides defense-in-depth: if Ed25519 breaks first (CRQC arrives), Dilithium-5 covers; if Dilithium-5 has an unknown lattice attack discovered, Ed25519 covers.

---

## §12. Signature Size Variability

| Suite | Ed25519 sig | Dilithium-5 sig | SPHINCS+-256s sig | Hybrid sig |
|-------|-------------|------------------|---------------------|------------|
| 0x0001 | 64 B | — | — | 64 B |
| 0x0100 | — | 4595 B (4.5 KB) | (sidecar 49,856 B) | 4595 B |
| 0x0200 | — | 2420 B (Dilithium-3) | (sidecar 16,720 B SPHINCS+-192f) | 2420 B |
| 0x0300 | 64 B | 4595 B | (sidecar optional) | 4659 B (dual) |

**Witness layout impact:**

- Suite 0x0001: signature fits in witness's 24-byte `hexad_packed_and_pad` region (only HMAC, no full signature).
- Suite 0x0100, 0x0200, 0x0300: full signatures don't fit in the 128-byte witness — moved to a per-CPU **signature sidecar ring**.
- Each witness gains a `sidecar_mhash` field (extending witness layout from 128 B to **160 B** at suite-swap time, or maintaining 128 B with the sidecar referenced via the `flags` field's reserved bits).

**Witness size in post-quantum era:** This is a recognized constitutional impact. The Tier-3 amendment to swap to suite 0x0100 is *bundled* with a witness-layout amendment that introduces the sidecar mechanism. Both amendments are atomic and require Founder's Anchor cosignature.

---

## §13. Performance Targets

| Operation | suite 0x0001 (target) | suite 0x0100 (target) |
|-----------|------------------------|------------------------|
| `crypto.hash(...)` (single-block) | ~200 cycles (SHA-256 SHA-NI) | ~600 cycles (SHAKE-256, no hardware accel yet) |
| `crypto.mac(...)` per witness | ~30 cycles (SHA-NI HMAC) | ~80 cycles (SHAKE-based HMAC) |
| `crypto.sign(...)` per cycle | ~50,000 cycles (Ed25519) | ~200,000 cycles (Dilithium-5) |
| `crypto.verify(...)` per cycle | ~80,000 cycles (Ed25519) | ~120,000 cycles (Dilithium-5) |
| `crypto.kem_encap(...)` per session | n/a | ~60,000 cycles (Kyber-1024) |
| `crypto.vdf_eval(...)` per epoch | ~hours (2^20 RSA squarings) | ~hours (class-group squarings) |

**Implication for Wave 1 (speed):** SHA-NI / AES-NI / SHA-3-NI hardware acceleration is critical. Without it, suite 0x0100 imposes ~3× the per-cycle witness HMAC overhead. With ARM SHA-2 / RISC-V Zksh extensions (Wave 3 portability), the suite-0x0100 cost drops to near-parity.

---

## §14. Conformance Criteria (Crypto Agility-Specific)

| Code | Criterion |
|------|-----------|
| C-CRYPTO-1 | Every cryptographic operation in the substrate flows through `crypto.<primitive>(suite_id, args)` |
| C-CRYPTO-2 | Suite swap requires Tier-3 unanimous quorum + Founder's Anchor cosignature |
| C-CRYPTO-3 | Historical witnesses verifiable under their original `crypto_suite_id` after a swap |
| C-CRYPTO-4 | Hybrid suite (0x0300) requires both pre-quantum and post-quantum signature verification |
| C-CRYPTO-5 | Every NIH-implemented primitive passes its NIST KAT corpus |
| C-CRYPTO-6 | Constant-time discipline holds for every secret-data operation |
| C-CRYPTO-7 | No third-party PQC library is linked into BOOT or STDLIB |
| C-CRYPTO-8 | Witness sidecar ring (for SPHINCS+ signatures) preserves chain continuity |
| C-CRYPTO-9 | DRTM quote layout includes `suite_id` at offset 0x160 |
| C-CRYPTO-10 | Multi-suite verifier in conformance runner correctly walks chains across suite boundaries |

---

## §15. Founder's Anchor Discipline

The Founder's Anchor (item 178) holds **cosignature authority** over all suite swaps. Without the Anchor's signature on the Tier-3 amendment, the swap does not commit. This protects against the scenario where a compromised quorum (or an unchained Catalyst at planetary scale) attempts to swap to a backdoored suite.

The Anchor's own signature is itself agile — when the active suite swaps, the Anchor's signature changes form (Ed25519 → Dilithium-5 + SPHINCS+-256s in hybrid mode → Dilithium-5 alone). The Anchor's **identity** is preserved across swaps via a special "anchor-rotation" mechanism specified in III-FOUNDERS-ANCHOR.md §6.

---

## §16. Final Statement

Cryptographic Agility is the architectural commitment that III's mathematical immunity outlives any specific cryptographic primitive. By placing every primitive behind a uniform `crypto.<primitive>(suite_id, args)` interface, with multi-suite verifier registry, with Tier-3 swap mechanism gated by Founder's Anchor cosignature, and with NIH hand-rolled implementations of every post-quantum candidate from the FIPS publications, the substrate is **prepared for Q-Day** without the operator needing to touch source code.

The 15 sealed specs reference cryptography indirectly through the `crypto.*` interface; their canonical text never changes when suites swap. R1 composite root recomputes under the new hash function on swap (as part of the Tier-3 amendment's cascade); witnesses retain their original suite_id for replay.

This is the survival-mandate solution to item 176: III is *temporally immune* — its primitives can change while its identity, history, and witnessed continuity remain unbroken.

*Wave 0.4 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updates only via Catalyst-promoted append (new suite registrations) or Tier-3 amendment (new primitive categories).*
