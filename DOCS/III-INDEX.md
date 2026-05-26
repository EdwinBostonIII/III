# III-INDEX.md — The Master Specification Index

**Document Identity:** IDX / The Master Index / R1 Specification Root
**Canonical Hash Slot:** R1.IDX
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. This document is the index of the entire III specification set. Its mhash R1.IDX is the last component of the composite specification root R1.

---

## §0. Preamble — One Hash to Rule Them All

The III language is defined by **fifteen sealed documents**. Each document has its own canonical-hash slot in the R1 family. The composite **R1** is the SHA-256 of the concatenated R1 family, in canonical order. R1 is **the constitutional identity of III** — it is embedded in every compiled module's closure manifest, every DRTM quote at every epoch advance, every proof certificate's `closure_root` field, and every federation peer's identity record.

A change to any document — even a single comment edit — alters that document's R1.X, alters the composite R1, and forces a substrate-wide DRTM relaunch. There is no "patch" form of III; mutations proceed only via Catalyst-promoted appends (which bump the appropriate R1.X), `amend.apply` at constitutional tier (a sealed call that updates the spec root after federation-wide unanimous consent), or a sealed major-version bump (R1 → R2, a once-in-a-generation event).

This document is therefore both **inventory** and **constitution**.

---

## §1. The Specification Set (15 Documents)

### §1.1 Primary — Core Language (10 documents)

| # | Document | Hash Slot | Subject |
|---|----------|-----------|---------|
| A1 | [III-LEXICON.md](./III-LEXICON.md) | R1.A1 | The alphabet — 47 keywords, 19 modifiers, 23 operators, punctuators, literals, comments, lexer state machine. |
| A2 | [III-GRAMMAR.bnf](./III-GRAMMAR.bnf) | R1.A2 | The formal BNF — every production, AST kind enumerator, precedence ladder, disambiguation rules. |
| A3 | [III-TYPES.md](./III-TYPES.md) | R1.A3 | The type system — universe ladder Prop / Type₀..Type₆, Reduction six-tuple, hexad/ring/tier/epoch dependent typing, linear capabilities, epistemic types, constitutional/Möbius Prop types, bidirectional inference, the folded-in proof layer (CIC fragment + native ternary kernel). |
| A4 | [III-EFFECTS.md](./III-EFFECTS.md) | R1.A4 | The effect system — 17 SE kinds + 3 Compromise tiers, IRPD discipline, four novel inventions (PIP, Ghost, Epistemic, Möbius effects). |
| A5 | [III-CYCLES.md](./III-CYCLES.md) | R1.A5 | The cycle calculus — SID 17-kind classifier + 32-step plan, 128-byte witness emission, BCWL indexing, cycle-table invariants, self-modifying cycles. |
| A6 | [III-HEXAD.md](./III-HEXAD.md) | R1.A6 | The asymmetric ternary ground — `{NEG, ZERO, POS}` algebra, 6-trit hexad packing, 144-byte reachability bitmap `xii_asym_reach6`, the Representability Theorem (six PFS ops have no admissible hexad), dynamic hexads, epistemic hexads, Möbius hexads. |
| A7 | [III-PHASES.md](./III-PHASES.md) | R1.A7 | The cross-ring lattice — R-2 / R-1 / R0 / R3, phase polymorphism (one source four lowerings), cross-ring constructor catalogue, marshalling rules, dynamic phase promotion, epistemic phases, ghost phases, predictive phase specialization. |
| A8 | [III-SANCTUM.md](./III-SANCTUM.md) | R1.A8 | Ring -2 discipline — 9+1 sealed methods, `@seal_id(N)` annotation rules, 8-step Sealed-Cycle Box, Trinity-gate prerequisites, DRTM-relaunch role, Sanctum as live data manifold. |
| A9 | [III-TRINITY.md](./III-TRINITY.md) | R1.A9 | The three-layer admission manifold — SCBA bit-test, ACC Wall-Y composed-delta admit, Trinity Gate (intent × cap × causality × sanctum-state), failure-mode error codes, five novel inventions (Predictive, Epistemic, Möbius, Catalyst, Ghost Trinity), dynamic layer activation. |
| A10 | [III-MODULES.md](./III-MODULES.md) | R1.A10 | The module & complementarity system (safety-first revision) — content-addressed witnessed nodes, name resolution as mathematical discovery, complementarity principle, ring-gated promotion, codegen-first validation, deployment flags `SAFE_APPROVED`/`SAFE_FLAGGED`/`UNSAFE_REJECTED`, dynamic module fusion. |

### §1.2 Secondary — Integrated (3 documents)

| # | Document | Hash Slot | Subject |
|---|----------|-----------|---------|
| B1 | [III-CATALYST.md](./III-CATALYST.md) | R1.B1 | The Dynamic Transformation Catalyst — mandate, eight promotion gates, synthesis capabilities, safety rails. |
| B2 | [III-FEDERATION.md](./III-FEDERATION.md) | R1.B2 | Tier-gated outbound — Tier₀ transient / Tier₁ host_file / Tier₂ federation / Tier₃ constitutional, mutation & outbound rules, quorum specifications, transport via IOMMU mediation. |
| B3 | [III-CONFORMANCE.md](./III-CONFORMANCE.md) | R1.B3 | The 30 conformance criteria — C-1..C-15 core language, C-16..C-25 substrate & runtime, C-26..C-30 cognitive layer & human interface. |

### §1.3 Minimized — Bootstrap-Only (1 document)

| # | Document | Hash Slot | Subject |
|---|----------|-----------|---------|
| C1 | [III-ABI.md](./III-ABI.md) | R1.C1 | Single bootstrap-only ABI rule — `extern @abi(c-msvc-x64)` is the only legal cross-language bridge; ring-restricted to R0/R3; bootstrap-only discipline. |

### §1.4 The Index (this document)

| # | Document | Hash Slot |
|---|----------|-----------|
| IDX | III-INDEX.md (this document) | R1.IDX |

**Total: 15 documents.** No more, no fewer.

### §1.5 Derivative Set — Wave-0+ Architectural Mandates (16 documents, NOT part of R1)

The derivative set is **architecturally binding** on every implementation but is **NOT part of the R1 sealed set**. Each derivative document specifies architectural mandates for substrate primitives, performance, observability, portability, ghost-code, legacy-ingestion, polymorphic-data, sovereign-web, Catalyst-extensions, planetary-federation, sandbox, and deployment. The sealed R1 set defines the **language**; the derivative set defines the **architectural mandates** for substrate implementation.

| # | Document | Subject | Wave |
|---|----------|---------|------|
| D1 | [III-STDLIB.md](./III-STDLIB.md) | Comprehensive auditable inventory of all R1-sealed primitives + cross-cutting analysis (95 codex edits + Cluster K integration as §19.7) | 0.1 |
| D2 | [III-CONSTANTS.md](./III-CONSTANTS.md) | Constitutional constants ledger; 20 sections; 3 mutation paths (CATALYST-APPEND, AMEND-APPLY, R2-MAJOR-BUMP) | 0.2 |
| D3 | [III-ERRORS.md](./III-ERRORS.md) | Unified error-code namespace; `<PHASE>-<SUBSYSTEM>-<NNN>`; 20 phase namespaces; per-spec C-A1-* through C-IDX-* renaming | 0.3 |
| D4 | [III-CRYPTO-AGILITY.md](./III-CRYPTO-AGILITY.md) | Item 176; uniform `crypto.<primitive>(suite_id, args)`; pre/post-quantum suite catalogue; Tier-3 swap; NIH FIPS 203/204/205 | 0.4 |
| D5 | [III-FOUNDERS-ANCHOR.md](./III-FOUNDERS-ANCHOR.md) | Item 178; structurally un-amendable veto; R-3 ring; seven Anchor authorities; PFK-ANCHOR-INVARIANT; Skynet-prevention argument | 0.5 |
| D6 | [III-PERFORMANCE.md](./III-PERFORMANCE.md) | Items 10-25; speed-without-sacrifice (SHA-NI, AVX-512, lock-free rings, hexad table compaction, NUMA-local audit, etc.) | 1 |
| D7 | [III-OBSERVABILITY.md](./III-OBSERVABILITY.md) | Items 26-32; OBSERVATORY collapse; 12-family threshold library; State surface; WLISHI; health metrics | 2.1 |
| D8 | [III-ZK-PRUNING.md](./III-ZK-PRUNING.md) | Item 175; ZK-rollup compression; SNARK + STARK NIH; preservation list; planetary-scale storage | 2.2 |
| D9 | [III-PORTABILITY.md](./III-PORTABILITY.md) | Items 1-9; HAL interface; ARMv8 + RISC-V H + Intel-VMX + POWER9 ports; cross-architecture closure root | 3 |
| D10 | [III-GHOST-CODE.md](./III-GHOST-CODE.md) | Items 63-71; ghost-mode declarations; 12 verification gates; SE compromise tier integration | 4 |
| D11 | [III-LEGACY-INGESTION.md](./III-LEGACY-INGESTION.md) | Items 33-46; ELF/PE/Mach-O/COFF parsers NIH; legacy execution sandbox; syscall translation; legacy-OS coexistence | 5 |
| D12 | [III-POLYMORPHIC-DATA.md](./III-POLYMORPHIC-DATA.md) | Items 47-53; Glyph V3 192-byte forms; 16 deserialization parsers NIH; cross-architecture canonicalization; hash-consing | 6 |
| D13 | [III-SOVEREIGN-WEB.md](./III-SOVEREIGN-WEB.md) | Items 54-62; IOMMU-mediated transport; witness-tagged packets; AH trailer; HotStuff BFT NIH | 7 |
| D14 | [III-CATALYST-EXT.md](./III-CATALYST-EXT.md) | Items 72-78; causal-DAG-driven hypothesis synthesis; counterfactual replay in SANCTUM; 8-gate promotion; Anchor-bounded restraint | 8 |
| D15 | [III-PLANETARY.md](./III-PLANETARY.md) | Items 79-85; 5-tier hierarchy; Sybil + eclipse resistance; partition recovery; planetary R1 Merkle root | 9 |
| D16 | [III-SANDBOX.md](./III-SANDBOX.md) | Items 86-90; sandbox first-class type; total isolation + observation + reversibility; recursive composition | 10.1 |
| D17 | [III-GENESIS-VECTOR.md](./III-GENESIS-VECTOR.md) | Item 177; legitimate signing model; polymorphic packaging; Trinity-gated first invocation; software-only DRTM relaunch | 10.2 |

**Total: 16 derivative documents.** Coverage: all 178 items of the 174-item refinement plan + Cluster K (175-178). The R1-sealed set + derivative set together = **31 documents, ~812 KB total**.

The derivative set's mhashes do **not** participate in R1 composition. However, every implementation conformance harness verifies BOTH the R1 sealed set AND the derivative set's conformance criteria. Failing any derivative criterion fails substrate conformance.

---

## §2. The Composite Specification Root R1

The composite **R1** is computed as:

```
R1 = SHA-256(R1.A1 || R1.A2 || R1.A3 || R1.A4 || R1.A5 ||
             R1.A6 || R1.A7 || R1.A8 || R1.A9 || R1.A10 ||
             R1.B1 || R1.B2 || R1.B3 ||
             R1.C1 ||
             R1.IDX)
```

where `||` denotes byte concatenation of the 32-byte SHA-256 outputs in the canonical order shown.

R1 is embedded in:

- Every compiled III module's closure manifest (in the `r1_specification_root` field).
- Every DRTM quote at every epoch advance (in the `attestation` body).
- Every proof certificate's `closure_root` field.
- Every federation peer's identity record (so peers can verify they share the same constitution).
- The header section of every binary artifact (in the `.iii_manifest` PE / ELF section).

A peer with a different R1 is operating under a different specification — by definition, a different language — and federation peering is refused.

---

## §3. Mutation Discipline

### §3.1 Append-Only Catalyst Promotions

A Catalyst promotion that adds a new keyword, modifier, operator, hexad, or cycle bumps the appropriate R1.X (for example, a new keyword bumps R1.A1, a new operator bumps both R1.A1 and R1.A2). The bump triggers:

1. Re-canonicalization of the affected document.
2. Recomputation of the affected R1.X.
3. Recomputation of the composite R1.
4. Federation broadcast of the promotion (per III-FEDERATION.md §2).
5. DRTM relaunch on every node (per III-SANCTUM.md §4).

The mutation is **monotonic**: existing entries cannot be removed, only appended.

### §3.2 Constitutional Amendments

A constitutional change (modifying a coherence floor, adding a sealed-call slot, changing the rate cap, modifying a Trinity conjunct, changing the universe ladder) requires:

1. `amend.apply` cycle invocation at constitutional tier.
2. Federation-wide unanimous consent.
3. DRTM relaunch on every node.
4. Re-sealing of the affected R1.X family members.

The `amend.apply` cycle is itself a witnessed reduction with a SID-derived inverse — even constitutional amendments are reversible (within the bounded window where the federation has not yet universally accepted them; once unanimous consent is recorded, the amendment becomes part of the canonical R1).

### §3.3 Major Version Bump (R1 → R2)

A major version bump creates a fresh specification root and triggers a substrate-wide DRTM ceremony. This is reserved for **categorical advances** (e.g., a new privilege ring after AMD or Intel ships hardware with one; a new cryptographic primitive that obsoletes SHA-256; a new logic that supersedes CIC). R2 is not currently in scope; III is sealed at R1.

---

## §4. Reading Order

For a new operator, the recommended reading order is:

1. **III-LEXICON.md** (A1) — what symbols exist.
2. **III-GRAMMAR.bnf** (A2) — how those symbols compose.
3. **III-HEXAD.md** (A6) — the safety ground (read this before TYPES, EFFECTS, CYCLES, because everything below depends on it).
4. **III-TYPES.md** (A3) — the type system + folded proof layer.
5. **III-EFFECTS.md** (A4) — the IRPD discipline + 17 SE kinds.
6. **III-CYCLES.md** (A5) — the cycle calculus + SID's 32-step plan.
7. **III-PHASES.md** (A7) — the cross-ring lattice.
8. **III-SANCTUM.md** (A8) — Ring -2 discipline.
9. **III-TRINITY.md** (A9) — the admission manifold.
10. **III-MODULES.md** (A10) — modules + complementarity + ring-gated safety.
11. **III-CATALYST.md** (B1) — the engine of self-extension.
12. **III-FEDERATION.md** (B2) — tier-gated outbound.
13. **III-CONFORMANCE.md** (B3) — the 30 criteria.
14. **III-ABI.md** (C1) — the single bootstrap rule.
15. **III-INDEX.md** (this document) — the master index.

For an operator reading the substrate's source, the recommended traversal is:

1. Read this index.
2. Open `COMPILER/BOOT/` and read `lex.h`, `lex.c`, `ast.h`, `ast.c`, `parse.h`, `parse.c` against III-LEXICON.md and III-GRAMMAR.bnf.
3. Open `COMPILER/BOOT/sema.h`, `sema.c`, `proof.h`, `proof.c` against III-TYPES.md.
4. Open `COMPILER/BOOT/sid.h`, `sid.c`, `hexad_check.h`, `hexad_check.c`, `acc.h`, `acc.c` against III-EFFECTS.md, III-HEXAD.md, III-CYCLES.md.
5. Open `COMPILER/BOOT/ceiling.h`, `ceiling.c`, `witness_alloc.h`, `witness_alloc.c` against III-TRINITY.md.
6. Open `COMPILER/BOOT/cg_*.{h,c}`, `jit_emit.{h,c}`, `link.{h,c}`, `emit.{h,c}` against III-PHASES.md, III-SANCTUM.md, III-MODULES.md.
7. Open `STDLIB/` and read each module against the spec it implements.
8. Open `SELF/` (after Stage 1) and read each `.III` file as the III-source mirror of the BOOT/*.c files.

---

## §5. Versioning & History

| Version | Date | Notes |
|---------|------|-------|
| 1.0 | 2026-05-03 | Initial sealing. R1 computed over the 15 sealed documents listed above. |

Future versions are appended here when constitutional amendments alter the spec; major-version bumps (R1 → R2) start a fresh history log.

---

## §6. Closure Identity Rule (R1.IDX)

R1.IDX = `SHA-256(canonical_byte_form(this_file))`. After this index document is sealed, R1.IDX is computed; then R1 is computed using R1.IDX as the final input to the concatenated SHA-256.

---

## §7. Final Declaration

**Fifteen documents. One specification root. One language.**

III is sealed against the C:\\CHARIOT closure of 2026-05-03. Every implementation that claims conformance must produce a composite R1 byte-identical to the canonical R1 over these 15 documents. Every binary artifact carries R1 in its manifest. Every DRTM quote attests R1.

No fragmentation. No drift. No "version of III" that differs from another version of III without an explicit, witnessed, federated, DRTM-relaunched amendment.

This is **III**. **The Last Language. Language as Operating System. The grammar that ends grammars. The alphabet that ends the era of languages.**

*Sealed. R1.IDX = SHA-256(canonical_byte_form(this_file)). R1 = SHA-256(R1.A1 || R1.A2 || R1.A3 || R1.A4 || R1.A5 || R1.A6 || R1.A7 || R1.A8 || R1.A9 || R1.A10 || R1.B1 || R1.B2 || R1.B3 || R1.C1 || R1.IDX).*
