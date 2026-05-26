# III-CONSTANTS.md — Constitutional Constants Ledger

**Document Identity:** CONSTANTS / Constitutional Constants Ledger
**Status:** **DERIVATIVE — NOT part of the R1 sealed set.** Reference document consolidating every constitutional constant from the 15 sealed specs plus the Cluster K (items 175–178) extensions. Updated on Catalyst-promoted constant changes and on `amend.apply` constitutional amendments.
**Version:** 1.0 — 2026-05-03 (Wave 0.2)
**Sources:** All 15 R1-sealed specs at `Desktop/III/DOCS/`.
**Sibling derivative docs:** III-STDLIB.md, III-ERRORS.md, III-CRYPTO-AGILITY.md, III-FOUNDERS-ANCHOR.md.

---

## §0. Preamble

Every constitutional constant in III — every rate cap, every threshold, every floor, every fixed count, every byte-size — exists somewhere in the 15 sealed specs, but no single spec catalogues all of them. This ledger consolidates the entire constitutional-constants surface for one purpose: when an `amend.apply` cycle proposes to change a constant, the operator can verify *exactly* which constant is being changed, *exactly* which constants must move together, and *exactly* what the cascading effects will be.

A constitutional constant is any value that satisfies all three:

1. **Sealed** in one or more R1-rooted specs.
2. **Referenced** by structural invariants of the substrate (i.e., changing it requires re-canonicalization of the affected sealed spec, bumping its R1.X, bumping the composite R1, and triggering a substrate-wide DRTM relaunch).
3. **Outside** the Catalyst-promoted append band (which adds new entries without changing prior ones).

This document is **not authoritative for individual values** — those live in the sealed specs. It is authoritative for the *list* of constants, their cross-references, and their mutability discipline. Where two specs disagree on a value, this ledger logs both and flags it.

---

## §1. Mutability Discipline

Every constant in this ledger has one of three mutation paths:

| Path | Mechanism | Examples |
|------|-----------|----------|
| **CATALYST-APPEND** | New entry added to a reserved-slot table; existing entries unchanged. Requires 8-promotion-gate evaluation per CATALYST §2.1. Bumps the affected R1.X. | Reserved keyword slots; reserved step_kind bands; reserved modifier slots; admissible-hexad slots |
| **AMEND-APPLY** | Tier-3 unanimous-quorum constitutional amendment. Bumps R1.X + composite R1 + DRTM relaunch. Bound by Founder's Anchor veto (item 178). | Coherence floor; epistemic threshold; rate caps; sanctum slot count; ring-lattice depth |
| **R2-MAJOR-BUMP** | Entire R1 rolled to R2. Substrate-wide DRTM ceremony. Once-in-a-generation. | Universe-ladder depth; trit-encoding scheme; witness-record byte size; hexad arity (6 → ?) |

**Founder's Anchor invariants** (item 178) — these constants are protocol-level un-amendable; no path above can change them:

- The Founder's Anchor public key (`founders_anchor_pubkey`).
- The Founder's Anchor signature suite (currently Ed25519; Crypto-Agility-swappable to post-quantum, but only by Founder's Anchor co-signature on the swap).
- The protocol-level rule that any term attempting to remove the Anchor produces an unrepresentable hexad.

---

## §2. Lexical Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Keyword count | 47 | LEX §4 | CATALYST-APPEND (16 reserved slots → max 63) |
| Modifier count | 19 | LEX §5 | CATALYST-APPEND (8 reserved slots → max 27) |
| Operator count | 23 | LEX §6 | CATALYST-APPEND (7 reserved slots → max 30) |
| Punctuator count | 25 | LEX §7 | AMEND-APPLY (constitutional surface) |
| Reserved-but-unused chars | 5 (`$`, `^`, `~`, `'`, `\``) | LEX §7.3 | CATALYST-APPEND (`^` and `~` may become operators) |
| Literal token kinds | 9 | LEX §3.1 | AMEND-APPLY |
| Comment kinds | 3 (line, block, doc) | LEX §10 | AMEND-APPLY |
| Whitespace chars | 3 (space, tab, LF) | LEX §11 | AMEND-APPLY |
| Identifier max length | 256 codepoints | LEX §8.3 | AMEND-APPLY |
| Source max size | 2^24 bytes (16 MiB) | LEX §2.7 | AMEND-APPLY |
| Source extension | `.III` | LEX §2.6 | AMEND-APPLY |
| Required diacritic for `möbius` | U+00F6 (precomposed) | LEX §4.3 | AMEND-APPLY |
| BOM forbidden | true (always) | LEX §2.2 | R2-MAJOR-BUMP |
| Line ending | LF only (no CR) | LEX §2.3 | AMEND-APPLY |

---

## §3. Type-System Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Universe count | 7 (`Prop`, `Type₀..Type₆`) | TYPES §2 | R2-MAJOR-BUMP |
| Impredicative top | `Type₆` (only `Reduction` lives here) | TYPES §2.4 | R2-MAJOR-BUMP |
| `Q14` representation | 16-bit signed, 14 fractional bits | TYPES §6 | R2-MAJOR-BUMP |
| `mhash` size | 32 bytes (SHA-256-based) | TYPES §6 | AMEND-APPLY (Crypto-Agility) |
| `Glyph` size | 192 bytes (XiiGlyph V3, 14 channels) | LEX §4.1.1, TYPES §6 | AMEND-APPLY |
| `Witness` size | 128 bytes (XiiWitness) | CYCLES §4.1 | AMEND-APPLY |
| `Hexad` packing | 6 trits → u16 (12 bits used + 4 reserved) | HEXAD §2.2 | R2-MAJOR-BUMP |
| `Trit` cardinality | 3 ({NEG, ZERO, POS}) | HEXAD §1.1 | R2-MAJOR-BUMP |
| Reduction tuple arity | 6 (Forward, Inverse, Witness, Hexad, Phase, Epoch) | TYPES §3 | R2-MAJOR-BUMP |
| `Compromise` tiers | 3 (LOW, MEDIUM, HIGH) | EFFECTS §1.2 | AMEND-APPLY |
| Proof kernel LoC budget | ~3000 (target) | TYPES §11 | AMEND-APPLY (target only; empirical ceiling open) |

---

## §4. Effect-System Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| SE kind count (privileged-write) | 17 | EFFECTS §1.1 | CATALYST-APPEND (band 0x01C7..0x01CF, 9 slots) |
| Compromise tier count | 3 (LOW / MEDIUM / HIGH) | EFFECTS §1.2 | AMEND-APPLY |
| PFS bricking-class operations | 6 (capsule_update / microcode_load / bootorder_set / real_nvram_write / me_psp_mailbox / smram_write) | EFFECTS §1.3, HEXAD §4.2 | **NEVER MUTABLE** — protocol-level un-typable; protected by Founder's Anchor + Hexad Representability Theorem |
| Wavefront terminator forms | 3 (`quiescent` / `coherent(Q)` / `count(N)`) | EFFECTS §7, GRAMMAR §7 | CATALYST-APPEND |

**The 17 IRPD methods table:** see III-STDLIB.md §4.1 for full. Numerical encoding 0x01..0x11.

---

## §5. Cycle / Witness Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Witness byte size | 128 | CYCLES §4.1 | AMEND-APPLY (extending requires re-canonical of every prior witness chain — extreme caution) |
| Witness predecessor offset | 0x00, 32 bytes | CYCLES §4.1 | R2-MAJOR-BUMP |
| Witness successor offset | 0x20, 32 bytes | CYCLES §4.1 | R2-MAJOR-BUMP |
| Witness step_kind offset | 0x40, 4 bytes | CYCLES §4.1 | R2-MAJOR-BUMP |
| Witness flags offset | 0x64, 4 bytes (bits 0..7 documented; 8..31 reserved) | STDLIB §5.6 | CATALYST-APPEND (reserved bits) |
| Witness hexad_packed offset | 0x68, 24 bytes (u16 + 22 pad/HMAC tail) | CYCLES §4.1 | R2-MAJOR-BUMP |
| BCWL Bloom size per CPU | 4096 bits | CYCLES §4.3 | AMEND-APPLY |
| BCWL skip-list buckets | 16 (by step_kind range) | CYCLES §4.3 | AMEND-APPLY |
| BCWL false-positive rate target | <1% for N ≤ 1024 witnesses/CPU/tick | STDLIB §14.3 | AMEND-APPLY (operational target) |
| Step_kind total slots | 512 | CYCLES §5.3 | R2-MAJOR-BUMP (reserved-future band has growth headroom) |
| `XII_STEP_KIND_RESERVED_BOOT` band | 0x0000..0x000F (16 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_IRPD_PRIVILEGED_WRITE` band | 0x0010..0x002F (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_IRPD_PRIVILEGED_READ` band | 0x0030..0x004F (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_CYCLE_LIFECYCLE` band | 0x0050..0x006F (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_WAVEFRONT` band | 0x0070..0x007F (16 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_SANCTUM` band | 0x0080..0x009F (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_TRINITY` band | 0x00A0..0x00BF (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_CEILING` band | 0x00C0..0x00CF (16 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_FEDERATION` band | 0x00D0..0x00EF (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_DRTM` band | 0x00F0..0x00FF (16 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_VDF` band | 0x0100..0x010F (16 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_OBSERVATORY` band | 0x0110..0x012F (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_CATALYST` band | 0x0130..0x014F (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_NARRATIVE` band | 0x0150..0x015F (16 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_COGNITIVE` band | 0x0160..0x017F (32 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_PFS` band | 0x0180..0x018F (16 slots) | CYCLES §5.3 | AMEND-APPLY |
| `XII_STEP_KIND_FEDERATION_RESERVED` band | 0x0190..0x01AF (32 slots) | CYCLES §5.3 | CATALYST-APPEND |
| `XII_STEP_KIND_USER_RESERVED` band | 0x01B0..0x01C6 (23 slots) | CYCLES §5.3 | CATALYST-APPEND |
| `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` band | 0x01C7..0x01CF (9 slots) | CYCLES §5.3 | CATALYST-APPEND |
| `XII_STEP_KIND_RESERVED_FUTURE` band | 0x01D0..0x01FF (48 slots) | CYCLES §5.3 | CATALYST-APPEND |

---

## §6. Hexad Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Pillar count per hexad | 6 | HEXAD §2 | R2-MAJOR-BUMP |
| Pillar 1 — Inverse-Derivability | structural | HEXAD §2.1 | R2-MAJOR-BUMP |
| Pillar 2 — Causality-Depth | structural | HEXAD §2.1 | R2-MAJOR-BUMP |
| Pillar 3 — Consent-Recency | structural | HEXAD §2.1 | R2-MAJOR-BUMP |
| Pillar 4 — Replication-Tier | structural | HEXAD §2.1 | R2-MAJOR-BUMP |
| Pillar 5 — Adversariality-Class | informational | HEXAD §2.1 | R2-MAJOR-BUMP |
| Pillar 6 — Coherence-Impact | informational | HEXAD §2.1 | R2-MAJOR-BUMP |
| Trit values | NEG=-2(asym)/-1(balanced)/0b00(packed) ; ZERO=0/0/0b01 ; POS=+1/+1/0b10 | HEXAD §1.1 | R2-MAJOR-BUMP |
| Reserved trit-value bit-pattern | 0b11 (top of u16, future Catalyst trit values) | HEXAD §2.2 | CATALYST-APPEND (one slot) |
| Total possible hexads (3⁶) | 729 | HEXAD §3.1 | R2-MAJOR-BUMP |
| Structurally-admissible hexads (P1..P4 ∈ {ZERO, POS}) | 144 (= 2⁴ × 3²) | STDLIB §6.5 | R2-MAJOR-BUMP |
| `xii_asym_reach6` byte size | 144 bytes (1 byte per admissible hexad) | HEXAD §3.1 | CATALYST-APPEND (Dynamic-Hexad rule grows admit-set) |
| `xii_asym_reach6` reachability code bits | bits 7..6 of each byte | STDLIB §6.5 | R2-MAJOR-BUMP |
| `xii_asym_reach6` metadata bits | bits 5..0 of each byte | STDLIB §6.5 | CATALYST-APPEND |
| Reachability codes | 4 (00=unrep / 01=rep / 10=rep+escalate / 11=reserved) | HEXAD §3.1 | CATALYST-APPEND (the 11 slot) |
| PFS bricking-class hexads | 6 (the table in §4.3 of STDLIB) | HEXAD §4.2 | **NEVER MUTABLE** — protected by Founder's Anchor |
| Bitmap mhash | SHA-256 of canonical 144 bytes | HEXAD §3.4 | derived (changes when bitmap changes) |

---

## §7. Phase Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Privilege ring count | 4 (R-2 / R-1 / R0 / R3) | PHASES §1 | R2-MAJOR-BUMP (would require new hardware tier) |
| Ring lattice ordering | total linear (R-2 ≼ R-1 ≼ R0 ≼ R3) | PHASES §1 | R2-MAJOR-BUMP |
| Cross-ring constructor count | 5 (Magic-MSR / IOCTL / Sanctum-Gate / VMRUN / SYSRET-legacy) | PHASES §3 | AMEND-APPLY (constitutional surface) |
| Marshalling rule count | 5 | PHASES §4 | AMEND-APPLY |
| `XII_PHASE_PROMOTE_RATE` | 4 per chronos-tick | PHASES §5, CATALYST §2.3 | AMEND-APPLY |
| Magic-MSR address | 0xC001_F100 | PHASES §3.1 | AMEND-APPLY (one of three reserved-MSR sentinel addresses) |

---

## §8. Sanctum Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| `XII_SANCTUM_SEAL_COUNT` | 10 (slots 0..9) | SANCTUM §1.1 | AMEND-APPLY (Tier-3 unanimous + Founder's Anchor) |
| `INVALID` slot index | 0 | SANCTUM §1.1 | NEVER MUTABLE |
| `drtm_relaunch` slot index | 1 | SANCTUM §1.1 | NEVER MUTABLE |
| `pfs_var_set` slot index | 2 | SANCTUM §1.1 | NEVER MUTABLE |
| `pfs_deny_quote` slot index | 3 | SANCTUM §1.1 | NEVER MUTABLE |
| `crcc_key_export` slot index | 4 | SANCTUM §1.1 | NEVER MUTABLE |
| `phoenix_emergency` slot index | 5 | SANCTUM §1.1 | NEVER MUTABLE |
| `chronos_set_epoch` slot index | 6 | SANCTUM §1.1 | NEVER MUTABLE |
| `compromise_quote` slot index | 7 | SANCTUM §1.1 | NEVER MUTABLE |
| `phoenix_bookmark` slot index | 8 | SANCTUM §1.1 | NEVER MUTABLE |
| `compile_module` slot index | 9 | SANCTUM §1.1 | NEVER MUTABLE |
| Sanctum-gate trampoline hardening | IBPB + VERW + SSBD + RSP-swap + GPR/FPR/XMM save (x86) | SANCTUM §2.1 step 4 | AMEND-APPLY (per-arch via Wave 3) |
| DRTM quote byte size | 312 | SANCTUM §4 step 5, STDLIB §8.7 | AMEND-APPLY (per-suite via Crypto Agility) |
| Per-CPU Sanctum frame size | 160 bytes | STDLIB §8.8 | AMEND-APPLY |

---

## §9. Trinity Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Trinity layer count | 3 (SCBA / ACC Wall-Y / Trinity Gate) | TRINITY §1 | AMEND-APPLY |
| Trinity-Gate conjunct count | 4 (intent × cap × causality × sanctum-state) | TRINITY §1.3 | AMEND-APPLY (constitutional — Tier-3 unanimous + Founder's Anchor) |
| SCBA bitarray size | 8 KiB (65,536 bits) | TRINITY §1.1 | AMEND-APPLY |
| SCBA hash function | first_16_bits(BLAKE3(post_state)) | TRINITY §1.1 | AMEND-APPLY (per Crypto Agility — BLAKE3 swappable) |
| Layer 1 cycle cost target | 1–2 cycles | TRINITY §1.1 | (operational target; not constitutional) |
| Layer 2 cycle cost target | 15–40 cycles | TRINITY §1.2 | (operational target) |
| Layer 3 cycle cost target | 80–300 cycles | TRINITY §1.3 | (operational target) |
| Failure-mode code count | 11 (TRINITY §2; renamed per §19.2 in STDLIB) | TRINITY §2 | CATALYST-APPEND (additional codes) |
| `XiiConvergencePoint` size | 128 bytes | STDLIB §9.5 | AMEND-APPLY |

---

## §10. Module Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Closure-root hash function | SHA-256 (Crypto Agility-swappable) | MODULES §1 | AMEND-APPLY (per Crypto Agility) |
| Deployment flag count | 3 (`SAFE_APPROVED` / `SAFE_FLAGGED` / `UNSAFE_REJECTED`) | MODULES §6.1 | AMEND-APPLY |
| Ring-gating decision tree thresholds | (LOW × HIGH → R-2) / (MEDIUM × MEDIUM → R-1) / (LOW × LOW → R0/R3) / else reject | MODULES §5 | AMEND-APPLY |
| `XII_MOD_PROMOTE_RATE` | 16 per chronos-tick | MODULES §10, CATALYST §2.3 | AMEND-APPLY |
| Transmission rule count | 5 | MODULES §3.1 | AMEND-APPLY |
| Complementarity performance fingerprint tolerance | 5% of theoretical minimum | MODULES §4.1 | AMEND-APPLY |

---

## §11. Catalyst Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| `XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK` | 8 per chronos-tick | CATALYST §2.3 | AMEND-APPLY (Tier-3 unanimous + Founder's Anchor — protocol-rate-cap is constitutional invariant; Catalyst cannot self-amend out of) |
| Promotion gate count | 8 | CATALYST §2.1 | AMEND-APPLY |
| Synthesis capability count | 7 | CATALYST §3 | AMEND-APPLY |
| Inviolable safety rail count | 5 | CATALYST §4.1 | NEVER MUTABLE |
| Möbius coherence floor (Q14) | 0.92q (= 15073 / 16384) | CATALYST §2.1 gate 2, TRINITY §5 | AMEND-APPLY (Tier-3 unanimous + Founder's Anchor) |
| OBSERVATORY saturation: Welford ε | (per-schema; defined in `STDLIB/sufficiency/`) | CATALYST §3 | CATALYST-APPEND |
| OBSERVATORY saturation: Hoeffding bound | (per-schema) | CATALYST §3 | CATALYST-APPEND |
| 1M-tick burn-in window | 2^20 ticks | CATALYST §2.1 gate 1 | AMEND-APPLY |
| Operator override mechanisms | 4 (`pause` / `reject` / `inverse.replay` / `constrain`) | CATALYST §4.3 | AMEND-APPLY |

---

## §12. Federation Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Tier count | 4 (transient / host_file / federation / constitutional) | FEDERATION §1 | AMEND-APPLY |
| Tier₁ quorum | (3, 2) — 3 peers, 2 must agree | FEDERATION §4 | AMEND-APPLY |
| Tier₂ quorum | (5, 3) — 5 peers, 3 must agree | FEDERATION §4 | AMEND-APPLY |
| Tier₃ quorum | (N, N) — unanimous | FEDERATION §4 | AMEND-APPLY (Tier-3 unanimous + Founder's Anchor) |
| Replication policy values | 4 (`local` / `broadcast` / `quorum_3` / `quorum_5`) | LEX §5.1 #10 | CATALYST-APPEND |
| Federation discovery cadence | 1 per chronos-tick | STDLIB §12.6 | AMEND-APPLY |
| AH (RFC 4302) trailer mode | active for outbound IIIᴹ-tagged packets | FEDERATION §5 | AMEND-APPLY |

---

## §13. Cognitive-Layer Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Cognitive primitive count | 7 (`narrative`, `explain`, `propose`, `negotiate`, `commit`, `reflect`, `uncertainty`) | LEX §4.1.5 | CATALYST-APPEND (more cognitive verbs may be promoted) |
| Epistemic confidence threshold | 0.85q (= 13926 / 16384) | TYPES §8.3, EFFECTS §5, TRINITY §4 | AMEND-APPLY |
| `explain` detail levels | 5 (`executive`, `technical`, `full_trace`, `formal`, `visual`) | LEX §4.1.5 | CATALYST-APPEND |
| `reflect` targets | 6 (`state`, `uncertainty`, `coherence`, `narrative`, `manifest`, `epoch`) | LEX §4.1.5 | CATALYST-APPEND |
| Narrative declaration multiplicity | 1 per module (parser admits multiples; type-checker rejects with `TYPE-NAR-001`) | GRAMMAR §5.6, TYPES (implicit) | AMEND-APPLY |

---

## §14. Conformance Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Conformance criterion count | 30 | CONFORMANCE §1, §2, §3 | AMEND-APPLY |
| Core Language criteria | 15 (C-1..C-15) | CONFORMANCE §1 | AMEND-APPLY |
| Substrate & Runtime criteria | 10 (C-16..C-25) | CONFORMANCE §2 | AMEND-APPLY |
| Cognitive Layer criteria | 5 (C-26..C-30) | CONFORMANCE §3 | AMEND-APPLY |

---

## §15. ABI Constants

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| Legal ABI name | 1 (`c-msvc-x64`) | ABI §1.1 | AMEND-APPLY (additional ABIs require Tier-3 unanimous) |
| Reserved ABI names (non-active) | `c-sysv-x64`, `vmrun-trampoline`, `magic-msr`, `ioctl` (non-bridge constructs) | ABI §3 | CATALYST-APPEND |
| Extern call inverse | `Compromise<MEDIUM>` | ABI §1.2 | NEVER MUTABLE (no general C-side reverse-engineering possible) |
| Extern hexad | `EXTERN_C_CALL` | ABI §1.2 | AMEND-APPLY |
| Extern ring restriction | R0 / R3 only | ABI §1.2 | AMEND-APPLY |

---

## §16. R1 Specification-Root Family

| Constant | Value | Source | Mutation path |
|----------|-------|--------|---------------|
| R1 slot count (sealed) | 15 | INDEX §1 | AMEND-APPLY (each new R1 slot requires Tier-3 unanimous + Founder's Anchor co-signature) |
| Composite R1 hash function | SHA-256 over concatenated R1 family | INDEX §2 | AMEND-APPLY (per Crypto Agility) |
| Concatenation discipline | INDEX §1 listed order, big-endian, no separator bytes | STDLIB §17.1 | AMEND-APPLY |
| R1.X slots reserved for Wave-deliverables | A11 PORTABILITY, A12 LEGACY-INGESTION, A13 NETWORK, A14 GHOST-SYNTHESIS | STDLIB §20 | scheduled (each via Tier-3 amendment at the corresponding wave gate) |

---

## §17. Cluster K Constants — Survival Surface

### §17.1 Item 175 — ZK-Rollup Pruning (Wave 2)

| Constant | Value | Mutation path |
|----------|-------|---------------|
| ZK-rollup compaction threshold | 1,048,576 witnesses (or per-chronos-tick whichever greater) | AMEND-APPLY |
| ZK proof size (target) | ≤ 256 bytes per compacted segment | AMEND-APPLY |
| Decommitment witness retention | 1024 most-recent compacted segments per CPU (older fully-pruned) | AMEND-APPLY |
| ZK suite identifier (default) | (TBD by Crypto Agility — pre-quantum SNARK 0x0001 or post-quantum STARK 0x0100) | per Crypto Agility |
| Replay verifier witness step kinds | `ZK_ROLLUP_PROPOSE`, `ZK_ROLLUP_VERIFY`, `ZK_ROLLUP_COMMIT`, `ZK_DECOMMIT` | CATALYST-APPEND (in CYCLE_LIFECYCLE band) |

### §17.2 Item 176 — Cryptographic Agility (Wave 0.4)

| Constant | Value | Mutation path |
|----------|-------|---------------|
| Crypto suite ID width | 64 bits | R2-MAJOR-BUMP |
| Pre-quantum suite ID | 0x0001 (SHA-256 + BLAKE3 + Ed25519 + HMAC-SHA-256 + HKDF-SHA-256 + Wesolowski-VDF) | sealed default |
| Post-quantum suite ID 1 | 0x0100 (Kyber-1024 + Dilithium-5 + SPHINCS+-256s + SHAKE-256 + HMAC-SHAKE-256 + HKDF-SHAKE) | AMEND-APPLY |
| Post-quantum suite ID 2 | 0x0200 (Kyber-768 + Dilithium-3 + SPHINCS+-192f + lighter-weight) | AMEND-APPLY |
| Hybrid suite ID | 0x0300 (pre-quantum + post-quantum running in parallel; both signatures required) | AMEND-APPLY |
| Suite swap mechanism | `amend.apply(crypto_suite_swap, new_suite_id)` at Tier-3 unanimous + Founder's Anchor cosignature | AMEND-APPLY |
| Active suite field location | DRTM quote offset 0x160; module manifest `crypto_suite_id`; HKDF info parameter | AMEND-APPLY |

### §17.3 Item 177 — Genesis Vector (Wave 10)

| Constant | Value | Mutation path |
|----------|-------|---------------|
| Genesis installer ABI | `c-msvc-x64` (Wave 0 ABI; the installer pre-Stage-4 is a legacy-disguised legacy app) | AMEND-APPLY |
| Genesis installer signature suite | per Crypto Agility active suite | AMEND-APPLY |
| Genesis pre-discharge bundle | (intent + cap + causality + sanctum-state mhashes shipped inside payload) | AMEND-APPLY |
| Genesis discovery cadence after first boot | 1 broadcast per chronos-tick | AMEND-APPLY |

### §17.4 Item 178 — Founder's Anchor (Wave 0.5)

| Constant | Value | Mutation path |
|----------|-------|---------------|
| `founders_anchor_pubkey` size | 32 bytes (Ed25519) per current suite; varies per Crypto Agility | AMEND-APPLY (only via Founder's Anchor co-signature on the swap) |
| Anchor-cosigned cycles | every Tier-3 amendment cycle, every `drtm_relaunch`, every `pfs_deny_quote`, every Stage-4 `compile_module` | NEVER MUTABLE |
| Anchor-cosigned witness flag bit | flag bit 8 (FOUNDERS_ANCHOR_COSIGNED) | NEVER MUTABLE |
| Privkey custody | offline; suggested K-of-N Shamir's Secret Sharing across N hardware tokens | (operator policy) |
| K-of-N parameter (recommendation) | K=3, N=5 hardware tokens | (operator policy) |
| Anchor-veto witness step kinds | `FOUNDERS_ANCHOR_VETO`, `FOUNDERS_ANCHOR_DRTM`, `FOUNDERS_ANCHOR_DENY`, `FOUNDERS_ANCHOR_RESTORE` | NEVER MUTABLE |
| Anchor-removal-attempt rejection layers | 3 (Hexad-untypable, Linear-cap nature, Witness-cosignature requirement) | NEVER MUTABLE |

---

## §18. Founder's Anchor Invariants (the un-amendable list)

These constants **cannot** be changed by *any* mutation path — including R2-major-bump. They are protocol-level structurally-protected. Removing or weakening them would require the operator to hard-fork the substrate (creating a new substrate that is no longer III-conformant).

| Invariant | Source |
|-----------|--------|
| The 6 PFS bricking-class hexads remain unrepresentable | HEXAD §4 |
| The `founders_anchor_pubkey` is type-checked as `Cap<sovereign_veto, FOUNDER>` and cannot be released | FOUNDERS-ANCHOR §3 |
| Every Tier-3 `amend.apply` cycle requires the Founder's Anchor co-signature in its witness | FOUNDERS-ANCHOR §3 |
| The Hexad Representability Theorem produces unrepresentable hexads for any cycle whose effect removes the Anchor | FOUNDERS-ANCHOR §3 |
| The 5 Catalyst inviolable safety rails (CATALYST §4.1) | CATALYST §4.1 |
| The 3 PFS-bricking rejection layers (lexical / type-checking / proof discharge) | HEXAD §4.5 |
| The 32-step SID plan is total (every cycle either passes all 32 or is untypable) | CYCLES §3.2 |
| Layer 3 Trinity is full 4-conjunct (no shortcut) | TRINITY §1.3 |
| Witness chain continuity across all rings and module boundaries | C-17 (CONFORMANCE) |
| IRPD-only privileged writes (no raw WRMSR/MOV CR3/etc.) | C-16 (CONFORMANCE) |

---

## §19. Cross-Cutting Cascade Effects

When a constitutional constant changes, certain other constants must change too. This section catalogs the cascades.

| If you change... | You must also re-canonicalize... | Affected R1.X |
|------------------|-----------------------------------|----------------|
| Witness byte size | every BCWL implementation, every witness emitter, every replay tool | R1.A5 + R1.A8 + R1.B1 |
| Möbius coherence floor | every Catalyst gate-2 check, every cycle-table promotion, every Trinity Layer 3 outcome | R1.A9 + R1.B1 + R1.B3 |
| `XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK` | every chronos-tick scheduler in OBSERVATORY/Catalyst | R1.B1 |
| Crypto suite | every closure-root computation (re-hash of all sealed modules under new hash), every HKDF derivation, every DRTM quote, every Founder's Anchor signature | R1.A1..R1.IDX (full cascade — this is why Crypto Agility is itself an architectural mandate, designed to make the swap a single atomic Tier-3 amendment rather than a 15-doc cascade) |
| Sanctum slot count (10 → 11) | INCLUDE/xii_sanctum_seals.h; SANCTUM §1 + §2; CYCLES §5.3 reserved-band table | R1.A8 |
| Universe-ladder depth (7 → 8) | Reduction type's universe; every CIC kernel rule | R1.A3 + R1.B3 (R2-major-bump territory) |
| Hexad pillar count (6 → 7) | xii_asym_reach6 size (144 → 432 bytes); composition rule; the bitmap generator; the proof kernel's native ternary extension | R1.A6 + R1.A3 + R1.B3 (R2-major-bump territory) |

---

## §20. Final Statement

This ledger consolidates every constitutional constant in III's 15 sealed specs plus the four Cluster K extensions. It is **derivative** — it does not seal new values; it merely catalogues and cross-references the values already sealed elsewhere. When the operator proposes an `amend.apply` cycle to change a constant, this ledger is the single document that enumerates what's actually changing and what cascades.

Three constants categories are highlighted:

1. **NEVER MUTABLE** — protocol-level un-amendable. Founder's Anchor invariants. Hexad Representability Theorem. The 5 Catalyst inviolable safety rails.
2. **AMEND-APPLY** — Tier-3 unanimous + (where applicable) Founder's Anchor co-signature. Most coherence-floor / rate-cap / threshold values.
3. **CATALYST-APPEND** — append-only via Catalyst promotion, no existing value changes.

The ledger updates on every Catalyst-promoted constant addition and on every `amend.apply` cycle that touches constitutional state. It does not regenerate when prose sections of sealed specs change (those don't affect constants).

*Wave 0.2 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03.*
