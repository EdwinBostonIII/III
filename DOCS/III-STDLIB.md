# III-STDLIB.md — The Master Inventory & System Codex

**Document Identity:** STDLIB / The System Codex / Master Inventory & Cross-Reference
**Version:** 2.0 — Refinement pass 2026-05-03 incorporating 95 codex edits + Cluster K (items 175–178)
**Status:** **DERIVATIVE — NOT part of the R1 sealed set.** Working consolidation of the sealed III specifications. Does **not** participate in R1; changes freely as audits proceed. R1.IDX and the composite R1 remain sealed at the canonical sealed-spec set.
**Sources:**
- A1 III-LEXICON.md (R1.A1) — alphabet — 70,934 B
- A2 III-GRAMMAR.bnf (R1.A2) — grammar + AST kinds — 63,475 B
- A3 III-TYPES.md (R1.A3) — type system + folded proof layer — 51,148 B
- A4 III-EFFECTS.md (R1.A4) — 17 SE kinds + 3 Compromise tiers — 27,068 B
- A5 III-CYCLES.md (R1.A5) — cycle calculus + SID + witness emission — 30,075 B
- A6 III-HEXAD.md (R1.A6) — asymmetric ternary ground + Representability Theorem — 25,432 B
- A7 III-PHASES.md (R1.A7) — cross-ring lattice — 23,450 B
- A8 III-SANCTUM.md (R1.A8) — Ring -2 discipline — 26,509 B
- A9 III-TRINITY.md (R1.A9) — admission manifold — 22,762 B
- A10 III-MODULES.md (R1.A10) — modules + complementarity — 22,555 B
- B1 III-CATALYST.md (R1.B1) — runtime self-extension — 12,415 B
- B2 III-FEDERATION.md (R1.B2) — tier-gated outbound — 7,488 B
- B3 III-CONFORMANCE.md (R1.B3) — 30 acceptance criteria — 11,623 B
- C1 III-ABI.md (R1.C1) — single bootstrap-only rule — 6,017 B
- IDX III-INDEX.md (R1.IDX) — master index — 11,530 B
- **Total sealed sources:** ~412 KB across 15 documents
- **Sibling derivative docs (planned):** III-CONSTANTS.md, III-ERRORS.md, III-CRYPTO-AGILITY.md, III-FOUNDERS-ANCHOR.md

---

## Table of Contents

- [§0. Preamble](#0-preamble)
- [§1. Methodology](#1-methodology)
  - [§1.1 Source Pass](#11-source-pass) · [§1.2 Refinement Lens](#12-refinement-lens) · [§1.3 Honesty Discipline](#13-honesty-discipline) · [§1.4 Notation Conventions](#14-notation-conventions)
- [§2. Lexical Inventory](#2-lexical-inventory)
  - §2.1 Keywords (47) · §2.2 Modifiers (19) · §2.3 Operators (23) · §2.4 Punctuators (25) · §2.5 Literal Forms (9) · §2.6 Comments · §2.7 Whitespace · §2.8 Source File Extensions · §2.9 Maximum Source Size
- [§3. Type Inventory](#3-type-inventory)
  - §3.1 Universe Ladder · §3.2.1 Value Types · §3.2.2 Prop-Typed Predicates · §3.3 Type Modifiers · §3.4 Generics & Holes · §3.5 Six-Tuple Reduction · §3.6 Type-Checking Algorithm
- [§4. Effect Inventory](#4-effect-inventory)
- [§5. Cycle Inventory](#5-cycle-inventory)
- [§6. Hexad Inventory](#6-hexad-inventory)
- [§7. Phase Inventory](#7-phase-inventory)
- [§8. Sanctum Inventory](#8-sanctum-inventory)
- [§9. Trinity Inventory](#9-trinity-inventory)
- [§10. Module Inventory](#10-module-inventory)
- [§11. Catalyst Inventory](#11-catalyst-inventory)
- [§12. Federation Inventory](#12-federation-inventory)
- [§13. Cognitive Layer Inventory](#13-cognitive-layer-inventory)
- [§14. Witness Chain & BCWL Inventory (cross-cutting view)](#14-witness-chain--bcwl-inventory)
- [§15. Conformance Inventory](#15-conformance-inventory)
- [§16. ABI Inventory](#16-abi-inventory)
- [§17. R1 Specification-Root Family](#17-r1-specification-root-family)
- [§18. Cross-Cutting Analyses](#18-cross-cutting-analyses)
  - §18.1 Symbol Audit (visual / mnemonic / usage tables) · §18.2 Möbius Coherence Map (graded) · §18.3 Contradiction & Reconciliation Audit · §18.4 Process Inventory · §18.5 Logic-Flow Map · §18.6 Single-Cycle Möbius Thread · §18.7 Reverse-Lookup Index · §18.8 Cross-Spec Dependency Graph
- [§19. Refinement Targets](#19-refinement-targets)
  - §19.1 [ARITHMETIC] · §19.2 [NAMESPACING] · §19.3 [SYMBOL-REFINEMENT] · §19.4 [META-THEORY] · §19.5 [IMPLEMENTATION] · §19.6 [DOCUMENTATION] · §19.7 [SURVIVAL] — Cluster K
- [§20. Final Statement](#20-final-statement)
- [§21. Versioning & Change Log](#21-versioning--change-log)
- [§22. Working Notes](#22-working-notes)
- [Appendix §A. Glossary](#appendix-a-glossary)
- [Appendix §B. Table of Tables](#appendix-b-table-of-tables)
- [Appendix §C. Quick Reference Card](#appendix-c-quick-reference-card)

---

## §0. Preamble

The 15 sealed III specs define the Last Language at separate layers — alphabet, grammar, types, effects, cycles, hexads, phases, Sanctum, Trinity, modules, Catalyst, federation, conformance, ABI, index. Each spec is internally consistent and was sealed against the C:\\CHARIOT closure of 2026-05-03. They reference one another extensively; primitives like `cycle`, `Reduction`, and `Cap<...>` appear in every document with subtly different emphasis.

To refine the language — eliminate contradictions, replace awkward symbols, map every glyph to a clean mathematical abstraction, verify Möbius coherence end-to-end — we maintain this single auditable inventory consolidating every meaning, interaction, abstraction, process, and path from all 15 sealed sources. It is **not** a new spec, **not** part of R1, **not** binding on any implementation, and **not** a tutorial. It is a research and refinement tool: every entry cross-references its source; every disagreement is surfaced; every refinement target is enumerated.

---

## §1. Methodology

### §1.1 Source Pass

Every entry was extracted from one or more of the 15 sealed specs. Names are quoted verbatim; counts are restated and cross-checked; numerical claims are arithmetically verified; bind-sites and dependency edges are reconstructed.

### §1.2 Refinement Lens

| Lens | Question | Output § |
|------|----------|----------|
| Symbol audit | Glyph clear / distinct / apt? | §18.1 |
| Möbius coherence | Symbol → mathematical abstraction? | §18.2 |
| Contradiction audit | Two specs disagree? | §18.3 |
| Process inventory | Every step / path inventoried? | §18.4 |
| Logic-flow map | End-to-end coherent? | §18.5 |
| Refinement targets | What needs work? | §19 |

### §1.3 Honesty Discipline

Where a spec is silent, the silence is recorded. Where two specs disagree, both readings are recorded. Speculative cross-cutting conclusions are tagged `[INFERENCE]`. Numerical claims that don't reconcile are flagged.

### §1.4 Notation Conventions

| Symbol | Meaning |
|--------|---------|
| `§N.M` | Section reference within the codex |
| `§A.M` (e.g., `§A4.1`) | Section in canonical sealed spec (A4 = III-EFFECTS.md) |
| `[REFINEMENT §19.N]` | Refinement target (anchor link) |
| `[INFERENCE]` | Speculative conclusion not directly in sealed text |
| `U+XXXX` | Unicode codepoint (no brackets) |
| Backtick `code` | Symbol or code-fragment reference |
| **Bold** | Finding-callout |
| *Italic* | Emphasis |
| Fenced code blocks | Tagged with language: `iii`, `c`, `bnf`, `text` |
| Em-dash `—` | Parenthetical break |
| Hyphen `-` | Compound word |
| Three ASCII dots `...` | Ellipsis (NIH discipline; no Unicode `…`) |

Status decoration vocabulary (controlled, used in tables):

| Token | Meaning |
|-------|---------|
| `KEEP` | Item passes audit unchanged |
| `KEEP-NOTE` | Item passes audit; minor commentary attached |
| `REVIEW` | Item warrants review |
| `FLAG` | Item flagged for refinement (cross-references §19) |
| `RESOLVED` | Issue resolved in-place during culmination |
| `OPEN` | Issue currently unresolved |
| `BY-DESIGN` | Apparent inconsistency is intentional |
| `CLARIFY` | Currently consistent but documentation should be sharper |

---

## §2. Lexical Inventory

**Source:** III-LEXICON.md §1–§14.

### §2.1 Keywords (47)

The frozen keyword set. Entries 45–47 (`mobius_candidate`, `schema`, `module`) are explicit additions during the culmination — they were grammar-introducers in earlier drafts but missing from the explicit table.

| # | Keyword | Category | Encoding | Architectural Binding (terse) |
|---|---------|----------|----------|-------------------------------|
| 1 | `witness` | Fundamental | ASCII | 128-byte canonical record. III-CYCLES.md §4.1. |
| 2 | `glyph` | Fundamental | ASCII | 14-channel universal observable (XiiGlyph V3, 192 B). III-LEXICON.md §4.1.1. |
| 3 | `cycle` | Fundamental | ASCII | Universal verb; Reduction six-tuple. III-CYCLES.md §1, §2. |
| 4 | `hexad` | Fundamental | ASCII | 6-trit asymmetric safety algebra. III-HEXAD.md §1, §2. |
| 5 | `cap` | Fundamental | ASCII | Linear glyph-bound capability. III-TYPES.md §7. |
| 6 | `phase` | Fundamental | ASCII | Privilege-ring lattice {R-2, R-1, R0, R3}. III-PHASES.md §1. |
| 7 | `sanctum` | Architectural | ASCII | Ring -2 sealed namespace. III-SANCTUM.md. |
| 8 | `drtm` | Architectural | ASCII | Dynamic Root of Trust Measurement. III-SANCTUM.md §4. |
| 9 | `observatory` | Architectural | ASCII | Mathematical self-knowledge index. III-CATALYST.md §3. |
| 10 | `catalyst` | Architectural | ASCII | Möbius self-extension engine. III-CATALYST.md. |
| 11 | `möbius` | Architectural | ASCII + ö (U+00F6) † | Self-referential manifold. III-LEXICON.md §4.1.2, §4.3. |
| 12 | `trinity` | Architectural | ASCII | Intent × Cap × Causality × Sanctum-State gate. III-TRINITY.md. |
| 13 | `ceiling` | Architectural | ASCII | Constitutional bound. III-MODULES.md §5. |
| 14 | `sid` | Architectural | ASCII | Side-effect Inverse Derivation. III-CYCLES.md §3. |
| 15 | `wavefront` | Concurrency | ASCII | Default concurrent composition. III-EFFECTS.md §7. |
| 16 | `waac` | Concurrency | ASCII | Wavefront-as-Capability. |
| 17 | `witness_stream` | Query | ASCII | Live PAS subscription. III-CYCLES.md §4.5. |
| 18 | `glyph_stream` | Query | ASCII | Live Glyph subscription. |
| 19 | `narrative` | Cognitive | ASCII | Persistent "I". III-LEXICON.md §4.1.5. |
| 20 | `explain` | Cognitive | ASCII | Provenance-backed explanation. |
| 21 | `propose` | Cognitive | ASCII | Catalyst-generated proposal. |
| 22 | `negotiate` | Cognitive | ASCII | Multi-turn intent refinement. |
| 23 | `commit` | Cognitive | ASCII | Final witnessed commitment. |
| 24 | `reflect` | Cognitive | ASCII | Meta-cognitive self-examination. |
| 25 | `uncertainty` | Cognitive | ASCII | Epistemic state query. |
| 26 | `epoch` | Provenance | ASCII | DRTM foundation epoch. |
| 27 | `vdf` | Provenance | ASCII | Wesolowski VDF. |
| 28 | `mhash` | Cryptographic | ASCII | Content-addressed digest. |
| 29 | `closure` | Cryptographic | ASCII | Module identity (SHA-256 of canonical source). |
| 30 | `anchor` | Cryptographic | ASCII | Sovereign attestation root. |
| 31 | `federation` | Distributed | ASCII | Replication tier and quorum. III-FEDERATION.md. |
| 32 | `amend` | Governance | ASCII | Constitutional amendment. |
| 33 | `bricking` | Safety | ASCII | Names the *absence* of catastrophic ops; the six PFS forms have no syntactic body. III-HEXAD.md §4. |
| 34 | `irreversible` | Safety | ASCII | Inverse → `Compromise<MEDIUM>` / `Compromise<LOW>`. |
| 35 | `pure` | Safety | ASCII | Zero-effect cycle. |
| 36 | `metal` | Escape | ASCII | Raw assembly, ring-specific. |
| 37 | `extern` | Interop | ASCII | Only legal C bridge: `extern @abi(c-msvc-x64)`. III-ABI.md. |
| 38 | `self_host` | Meta | ASCII | Stage-4 compiler-into-Sanctum. |
| 39 | `promote` | Meta | ASCII | Catalyst promotion request. |
| 40 | `observe` | Meta | ASCII | Direct OBSERVATORY query. |
| 41 | `coherence` | Meta | ASCII | Möbius coherence metric. |
| 42 | `inverse` | Meta | ASCII | Inverse derivation / replay. |
| 43 | `manifest` | Meta | ASCII | Constitutional ceiling manifest. |
| 44 | `glyph_bound` | Meta | ASCII | Glyph-bound capability check. |
| 45 | `mobius_candidate` | Meta | ASCII | Catalyst-eligible function introducer. |
| 46 | `schema` | Meta | ASCII | OBSERVATORY schema declaration introducer. |
| 47 | `module` | Meta | ASCII | Top-level module declaration introducer. |

† `möbius` requires precomposed U+006D U+00F6 U+0062 U+0069 U+0075 U+0073 (6 codepoints). ASCII variants `mobius`/`moebius`/`Mobius` are *not* the keyword — they lex as identifiers. Pre-NFC `o + combining diaeresis` form is rejected.

### §2.2 Modifiers (19)

| # | Modifier | Form | Meaning | Bind sites |
|---|----------|------|---------|------------|
| 1 | `@ring` | `@ring(ring_set)` | Phase polymorphism | type, fn, cycle, module, import, metal block |
| 2 | `@hexad` | `@hexad(NAME)` or `@hexad((trit, trit, ...))` | 6-trit safety hexad | type, cycle, fn, wavefront |
| 3 | `@tier` | `@tier(transient / host_file / federation / constitutional)` | Replication tier | type, cycle, value |
| 4 | `@epoch` | `@epoch(N)` or `@epoch(current)` | DRTM foundation epoch | type, value |
| 5 | `@cap` | `@cap(perm, range)` | Linear capability with glyph-bound identity | type |
| 6 | `@sanctum_only` | (no args) | Active-sanctum-frame requirement | fn, cycle, type |
| 7 | `@irreversible` | (no args) | Inverse → Compromise<MEDIUM/LOW> | cycle |
| 8 | `@pure` | (no args) | Zero-effect; witness elidable | fn, cycle |
| 9 | `@closure` | `@closure(mhash_lit)` | Content-addressed module pin | module, use |
| 10 | `@replicates` | `@replicates(local / broadcast / quorum_3 / quorum_5)` | Federation replication | fn, cycle |
| 11 | `@plan_anchor` | `@plan_anchor(IDENT)` | Plan-section binding | cycle, module |
| 12 | `@admits_caps` | `@admits_caps(IDENT, ...)` | Capability admission set | cycle |
| 13 | `@prerequisites` | `@prerequisites(IDENT, ...)` | Compile-time prerequisite cycles | cycle |
| 14 | `@candidate_for_promotion` | (no args) | Catalyst-eligible | mobius_candidate |
| 15 | `@mobius_coherence` | `@mobius_coherence(coherence_expr)` | Minimum Q14 coherence | cycle, wavefront |
| 16 | `@witness_elide` | (no args) | Suppress runtime witness (legal only on `@pure`) | cycle, fn |
| 17 | `@hot_path` | (no args) | SRPA may specialize sub-5 cycles | cycle, fn |
| 18 | `@chronos_bypass` | (no args) | Bypass VDF time check (operator-only cap) | cycle, fn |
| 19 | `@epoch_bridge` | (no args) | Authorize cross-epoch param merging | fn, cycle |

**`@safety` synonym** (LEX §5.2): not a 20th modifier token. Both `@safety(H)` and `@hexad(H)` lex to the same MODIFIER kind and produce the same hexad-tagged-type judgment.

**Modifier conflicts** (statically rejected):

| Conflict | Code |
|----------|------|
| `@pure` ∧ `@sanctum_only` | TYPE-MOD-001 |
| `@witness_elide` without `@pure` | TYPE-MOD-002 |
| `@chronos_bypass` without operator-cap | TYPE-MOD-003 |
| `@irreversible` ∧ `@pure` | TYPE-MOD-004 |
| `@candidate_for_promotion` outside `mobius_candidate` | TYPE-MOD-005 |
| `@epoch_bridge` on a fn with no cross-epoch params | TYPE-MOD-006 |

### §2.3 Operators (23)

| # | Op | Codepoint(s) | Name | Arity | Precedence | Used in spec bodies |
|---|----|--------------|------|-------|------------|---------------------|
| 1 | `⟲` | U+27F2 | Inverse | unary postfix | 11 | TYPES §3.5; CYCLES §7.3; EFFECTS §8.2 |
| 2 | `⊕` | U+2295 | Cycle Compose | binary L-assoc | 6 | TYPES §3.4; CYCLES §8; EFFECTS §8.2 |
| 3 | `⊗` | U+2297 | Glyph Materialize | binary postfix | 10 | GRAMMAR §8 |
| 4 | `⧉` | U+29C9 | Hexad Compose | binary L-assoc | 6 | TYPES §4.2; HEXAD §2.4; EFFECTS §8.2 |
| 5 | `⟐` | U+27D0 | Trinity Gate | binary R-assoc | 6 | TRINITY §3.3 |
| 6 | `↻` | U+21BB | Replay | unary postfix | 11 | EFFECTS §8.2 |
| 7 | `⟡` | U+27E1 | Witness Emit | unary postfix | 11 | CYCLES §4 |
| 8 | `⟁` | U+27C1 | Ceiling Check | binary non-assoc | 6 | TRINITY §1.1; MODULES §5 |
| 9 | `⧗` | U+29D7 | Möbius Coherence | binary non-assoc | 3 | TYPES §9.2; TRINITY §5; MODULES §3 |
| 10 | `⟴` | U+27F4 | Phase Cross | binary L-assoc | 5 | PHASES §4 Rule 2; SANCTUM §5.4 |
| 11 | `⧈` | U+29C8 | Cap Acquire/Release | binary non-assoc | 5 | TYPES §7.2 |
| 12 | `⟵` | U+27F5 | Epoch Bridge | binary L-assoc | 5 | TYPES §6.2; EFFECTS §8.2 |
| 13 | `⧊` | U+29CA | VDF Squaring | binary L-assoc | 7 | — (defined-only) |
| 14 | `⟶` | U+27F6 | Federation Replicate | binary L-assoc | 7 | FEDERATION §1 (table) |
| 15 | `⨁` | U+2A01 | Amendment Apply | binary L-assoc | 7 | — (defined-only) |
| 16 | `⟲⟲` | U+27F2 ×2 | Full Inverse Replay | unary postfix | 11 | CYCLES §7.3 |
| 17 | `⊛` | U+229B | Catalyst Promote | binary L-assoc | 8 | CATALYST §1.1 |
| 18 | `⧄` | U+29C4 | OBSERVATORY Saturate | binary non-assoc | 8 | — (defined-only) |
| 19 | `⟐⟐` | U+27D0 ×2 | Narrative Reflect | binary non-assoc | 9 | — (defined-only) |
| 20 | `⧇` | U+29C7 | Uncertainty Query | binary non-assoc | 3 | — (defined-only) |
| 21 | `⟡⟡` | U+27E1 ×2 | Explain | binary non-assoc | 9 | — (defined-only) |
| 22 | `⧋` | U+29CB | Propose | binary L-assoc | 8 | — (defined-only) |
| 23 | `⟴⟴` | U+27F4 ×2 | Negotiate | binary non-assoc | 9 | — (defined-only) |

**Defined-but-unused-in-body finding:** Operators 13 (`⧊`), 15 (`⨁`), 18 (`⧄`), 19 (`⟐⟐`), 20 (`⧇`), 21 (`⟡⟡`), 22 (`⧋`), 23 (`⟴⟴`) are defined in LEXICON but appear in no spec's body — **8 of 23 (35%)**. These are the cognitive / Catalyst / OBSERVATORY / amendment / VDF operators waiting for the Wave-1+ feature set.

**Disambiguation history (RESOLVED):** `⧉` was duplicated in early drafts (Hexad Compose + Amendment Apply). Resolution in LEX §6.2: `⧉` is **only** Hexad Compose; `⨁` (U+2A01) is **only** Amendment Apply.

**Pattern observation:** Cognitive operators (#19 `⟐⟐`, #21 `⟡⟡`, #23 `⟴⟴`) are doubled forms of base operators (#5 `⟐`, #7 `⟡`, #10 `⟴`). The doubling pattern signals "deeper / cognitive variant of the base action."

### §2.4 Punctuators (25)

| Punctuator | Codepoints | Role |
|------------|------------|------|
| `(` `)` | U+0028, U+0029 | Group / argument list / tuple |
| `{` `}` | U+007B, U+007D | Block |
| `[` `]` | U+005B, U+005D | Index / array |
| `<` `>` | U+003C, U+003E | Generic / comparison (context-disambiguated) |
| `,` | U+002C | List separator |
| `;` | U+003B | Statement separator (rare) |
| `:` | U+003A | Type annotation |
| `::` | U+003A ×2 | Path separator |
| `.` | U+002E | Field/method access |
| `..` | U+002E ×2 | Range |
| `=` | U+003D | Assignment |
| `==` | U+003D ×2 | Equality (mhash-equality for content-addressed values) |
| `!=` | U+0021 U+003D | Inequality |
| `≥` | U+2265 | Greater-than-or-equal (in coherence_expr) |
| `≤` | U+2264 | Less-than-or-equal |
| `->` | U+002D U+003E | Function/cycle return-type arrow |
| `=>` | U+003D U+003E | Match-arm arrow |
| `\|` | U+007C | Pattern alternative; sanctum-frame binding |
| `_` | U+005F | Wildcard / unused binding |
| `?` | U+003F | Hole / metavariable |
| `&` | U+0026 | Borrow / reference (extern types) |

**Reserved-but-unused** (LEX-PUNCT-001/002): `$` U+0024 (compiler-internal), `^` U+005E (future Catalyst-promoted op), `~` U+007E (future Catalyst-promoted op), `'` U+0027 (no character literals), `\`` U+0060 (reserved).

### §2.5 Literal Forms (9)

| Token kind | Form | Type | Source |
|------------|------|------|--------|
| `INT_LIT` | dec / hex / bin / oct + suffix | u8..u64, i8..i64 | LEX §9.1 |
| `MHASH_LIT` | exactly 64 hex digits prefixed `0x` | mhash | LEX §9.3 |
| `TRIT_LIT` | NEG / ZERO / POS / `Nt` form | Trit | LEX §9.4 |
| `HEXAD_LIT` | 6-tuple of trits in parens | Hexad | LEX §9.5 |
| `Q14_LIT` | `int.frac` with `q`/`q14` suffix | Q14 | LEX §9.6 |
| `STRING_LIT` | `"..."` | string | LEX §9.7.1 |
| `BYTE_STRING_LIT` | `b"..."` | [u8; N] | LEX §9.7.2 |
| `RAW_STRING_LIT` | `r"..."` / `r#"..."#` | string (raw) | LEX §9.7.3 |
| `HEX_STRING_LIT` | `h"..."` | [u8; N] | LEX §9.7.4 |

**No floating-point literals.** `f32`/`f64` are reserved type names for extern-only use; non-extern signatures cannot accept them. Source: LEX §9.8. Determinism requirement.

### §2.6 Comments

- Line: `// ...` (silent)
- Block: `/* ... */` (nestable, silent)
- Doc: `/// ...` or `/** ... */` → `DOC_COMMENT` token; parser-attached to next item.

### §2.7 Whitespace

Three accepted: space (U+0020), tab (U+0009), LF (U+000A). All others forbidden (LEX-WS-001).

### §2.8 Source File Extensions

Canonical: `.III` (case-preserving on case-insensitive filesystems; canonical capitalization is uppercase). Legacy `.iii`, `.tel`, `.lgs`, `.logos`, `.mneme` are **not recognized** — rejected with LEX-ENC-004. Source: LEX §2.6.

### §2.9 Maximum Source Size

A single III source file may not exceed **2^24 bytes** (16 MiB) after canonicalization. Larger files raise LEX-ENC-005. Source: LEX §2.7.

---

## §3. Type Inventory

**Source:** III-TYPES.md throughout.

### §3.1 Universe Ladder

| Universe | Inhabits | Notes |
|----------|----------|-------|
| `Prop` | Type₀ | Propositions; runtime-erased; the only Prop→Type₀ lift |
| `Type₀` | Type₁ | Base values, simple aggregates |
| `Type₁` | Type₂ | Compound aggregates |
| `Type₂` | Type₃ | Generic types (lower) |
| `Type₃` | Type₄ | Generic types (upper); cycle types; witness types |
| `Type₄` | Type₅ | Capability types; glyph types; hexad-tagged types |
| `Type₅` | Type₆ | Phase-polymorphic types; tier-typed types |
| `Type₆` | Type₆ | **Impredicative top — Reduction type only** |

Cumulativity: non-cumulative; only `Prop → Type₀` lift admitted. Predicativity: only Type₆ is impredicative (per TYPES §2.4); used exclusively for `Reduction`.

### §3.2.1 Value Types

| Type | Universe | Description | Source |
|------|----------|-------------|--------|
| `bool` | Type₀ | Boolean | TYPES §6 |
| `u8`, `u16`, `u32`, `u64` | Type₀ | Unsigned integers | TYPES §6 |
| `i8`, `i16`, `i32`, `i64` | Type₀ | Signed integers | TYPES §6 |
| `f32`, `f64` | Type₀ | Reserved for extern-only (no native arithmetic) | TYPES §6, ABI |
| `string` | Type₀ | UTF-8 string | TYPES §6 |
| `mhash` | Type₀ | 32-byte SHA-256 digest | TYPES §6 |
| `Trit` | Type₀ | {NEG, ZERO, POS} | TYPES §6, HEXAD §1 |
| `TritAsym` | Type₀ | Asymmetric numerical interpretation {-2, 0, +1} | TYPES §6, HEXAD §1.1 |
| `Q14` | Type₀ | 16-bit signed fixed-point, 14 fractional bits | TYPES §6 |
| `Glyph` | Type₃ | 14-channel universal observable, 192 B (XiiGlyph V3) | TYPES §6 |
| `Witness` | Type₃ | 128-byte XiiWitness | TYPES §6, CYCLES §4.1 |
| `Hexad` | Type₃ | 6 trits packed into u16 | TYPES §6, HEXAD §2 |
| `Phase` | Type₃ | One of {R-2, R-1, R0, R3} or a phase-set | TYPES §6, PHASES §1 |
| `Epoch` | Type₃ | DRTM foundation epoch (u64) | TYPES §6 |
| `WitnessedTime` | Type₃ | Chronos position (chronos-tsc + epoch + VDF-position tuple) — **[REFINEMENT §19.6]** layout undocumented | TYPES §6 |
| `Cap<P, R>` | Type₄ | Linear capability with glyph-bound identity | TYPES §7 |
| `Cycle<...>` | Type₅ | Syntactic sugar for Reduction | (alias) |
| `Reduction<F, I, W, H, P, E>` | Type₆ | Six-tuple effect; heart of sovereign computation | TYPES §3 |
| `Compromise<TIER>` | Type₀ | TIER ∈ {LOW, MEDIUM, HIGH}; `Compromise<HIGH>` uninhabited | TYPES §6, EFFECTS §1.2 |

### §3.2.2 Prop-Typed Predicates

| Type | Universe | Description |
|------|----------|-------------|
| `Uncertainty<D, C, Q>` | Type₀ | Epistemic state: domain × confidence (Q14) × open-questions list |
| `CeilingMembership<S>` | Prop | Constitutional admission proposition |
| `MöbiusCoherence<Q>` | Prop | Coherence-Q14 ≥ Q proposition |

### §3.3 Type Modifiers

The 19 modifier tokens of §2.2 also serve as type-modifiers when applied at type position. Bind-site discipline of §2.2 governs which modifiers may apply where.

### §3.4 Generics & Holes

- **Bidirectional inference**: synthesis (⇒) and checking (⇐) modes per TYPES §10.1.
- **Holes (N1)**: `?` is fresh metavariable; constraint-collected; unified at end of inference. TYPES §10.2.
- **Typed-as-term lift (U1)**: expression of type `T : Typeᵢ` may be re-typed as a `Typeᵢ` term. TYPES §10.3.

### §3.5 The Six-Tuple Reduction

```
Reduction<Forward, Inverse, Witness, Hexad, Phase, Epoch>
```

| Component | Origin | Inversion behavior on `r ⟲` |
|-----------|--------|------------------------------|
| Forward F | Programmer-written body | Becomes Inverse |
| Inverse I | SID-derived (or `@irreversible` → Compromise) | Becomes Forward |
| Witness W | Runtime emission (128-byte XiiWitness) | Inverse-replay yields W⁻¹ |
| Hexad H | Composed from constituent IRPD calls | `r ⟲` → `neg_hexad(H)` |
| Phase P | Declared via `@ring(...)` | Preserved |
| Epoch E | Set at cycle creation | Preserved |

**Composition (`r₁ ⊕ r₂`):** forwards left-to-right; inverses right-to-left; witnesses concatenate with full HMAC chain; hexads compose under `xii_asym_compose6`; phases must match (cross-phase requires `⟴`); epochs must match (cross-epoch requires `⟵` + `@epoch_bridge`).

### §3.6 Type-Checking Algorithm

Three-pass, hand-rolled in `COMPILER/BOOT/sema.{h,c}` (NIH-extreme: no Hindley-Milner library, no Z3, no external SMT, no external CIC kernel):

| Pass | Action |
|------|--------|
| 1 | Walk every item; record signatures; populate symbol table |
| 2 | Walk every body in synthesis mode; accumulate hole constraints; emit Prop obligations |
| 3 | Solve hole constraints by unification; discharge Prop obligations (admitted-hexad, valid-phase-set, linear-cap, glyph-bound, ceiling-admit, Möbius-coherence, Trinity-admit); emit proof certificates |

If any obligation cannot be discharged, the type checker emits a precise diagnostic and refuses to compile.

---

## §4. Effect Inventory

**Source:** III-EFFECTS.md.

### §4.1 The 17 Privileged-Write SE Kinds

| # | SE Kind | IRPD Method | Ring(s) | Step Kind Constant | Inverse |
|---|---------|-------------|---------|---------------------|---------|
| 0x01 | MSR_WRITE | `irpd.msr_write(idx, val)` | R-2, R-1 | `XII_STEP_KIND_IRPD_MSR_WRITE` | `irpd.msr_write(idx, prior_val)` |
| 0x02 | CR_WRITE | `irpd.cr_write(idx, val)` | R-1 | `XII_STEP_KIND_IRPD_CR_WRITE` | `irpd.cr_write(idx, prior_val)` |
| 0x03 | NPT_ENTRY_WRITE | `irpd.npt_write(gpa, entry)` | R-1 | `XII_STEP_KIND_IRPD_NPT_WRITE` | `irpd.npt_write(gpa, prior_entry)` |
| 0x04 | VMCB_FIELD_WRITE | `irpd.vmcb_field(field_id, val)` | R-1 | `XII_STEP_KIND_IRPD_VMCB_FIELD` | `irpd.vmcb_field(field_id, prior_val)` |
| 0x05 | IOMMU_DTE_WORD | `irpd.iommu_dte(bdf, w_idx, val)` | R-1 | `XII_STEP_KIND_IRPD_IOMMU_DTE` | `irpd.iommu_dte(bdf, w_idx, prior_val)` |
| 0x06 | AVIC_TBL_WRITE | `irpd.avic_tbl(idx, val)` | R-1 | `XII_STEP_KIND_IRPD_AVIC_TBL` | `irpd.avic_tbl(idx, prior_val)` |
| 0x07 | MSRPM_BIT_SET | `irpd.msrpm_bit(msr, mode, b)` | R-1 | `XII_STEP_KIND_IRPD_MSRPM_BIT` | `irpd.msrpm_bit(msr, mode, prior_b)` |
| 0x08 | IOPM_BIT_SET | `irpd.iopm_bit(port, b)` | R-1 | `XII_STEP_KIND_IRPD_IOPM_BIT` | `irpd.iopm_bit(port, prior_b)` |
| 0x09 | PKRU_WRITE | `irpd.pkru_write(val)` | R-1, R0 | `XII_STEP_KIND_IRPD_PKRU_WRITE` | `irpd.pkru_write(prior_val)` |
| 0x0A | XCR0_WRITE | `irpd.xcr0_write(val)` | R-1 | `XII_STEP_KIND_IRPD_XCR0_WRITE` | `irpd.xcr0_write(prior_val)` |
| 0x0B | CAP_ACQUIRE | `irpd.cap_acquire(cap_id, perm, range)` | All | `XII_STEP_KIND_IRPD_CAP_ACQUIRE` | `irpd.cap_release(cap_id)` |
| 0x0C | CAP_RELEASE | `irpd.cap_release(cap_id)` | All | `XII_STEP_KIND_IRPD_CAP_RELEASE` | `irpd.cap_acquire(cap_id, prior_perm, prior_range)` |
| 0x0D | PAGE_ALLOC | `irpd.page_alloc(class, size)` | R0 | `XII_STEP_KIND_IRPD_PAGE_ALLOC` | `irpd.page_free(addr, class)` |
| 0x0E | PAGE_FREE | `irpd.page_free(addr, class)` | R0 | `XII_STEP_KIND_IRPD_PAGE_FREE` | `irpd.page_alloc(prior_class, prior_size, addr)` |
| 0x0F | DPC_ARM | `irpd.dpc_arm(id, deadline)` | R0 | `XII_STEP_KIND_IRPD_DPC_ARM` | `irpd.dpc_cancel(id)` |
| 0x10 | DPC_CANCEL | `irpd.dpc_cancel(id)` | R0 | `XII_STEP_KIND_IRPD_DPC_CANCEL` | `irpd.dpc_arm(id, prior_deadline)` |
| 0x11 | NMI_INSTALL | `irpd.nmi_install(addr)` | R-1 | `XII_STEP_KIND_IRPD_NMI_INSTALL` | `irpd.nmi_remove(addr)` |

Each method has a paired read-side (`irpd.msr_read`, `irpd.cr_read`, ...) which is `@pure`-classifiable and may be `@witness_elide`'d on hot paths.

### §4.2 The 3 Compromise Tiers

| Tier | Inverse Type | Meaning | When |
|------|--------------|---------|------|
| `COMPROMISE_LOW` | `Compromise<LOW>` | Hardware-locked; "best-known prior" restore | `@irreversible` on safe hardware (lock bits) |
| `COMPROMISE_MEDIUM` | `Compromise<MEDIUM>` | SMM/PSP/ME interactions; equivalent-posture re-establish | `HWCR.SmmLock`, `IA32_SMM_MONITOR_CTL`, PSP/ME mailbox |
| `COMPROMISE_HIGH` | `Compromise<HIGH>` | True bricking-class; **uninhabited** | The six PFS operations (no syntactic form) |

### §4.3 The 6 PFS Bricking-Class Operations

| Operation | Hexad (P1–P6) | NEG-pillars | Bitmap |
|-----------|---------------|-------------|--------|
| `capsule_update` | (NEG, NEG, NEG, NEG, ZERO, ZERO) | 1, 2, 3, 4 | 0b00 |
| `microcode_load` | (NEG, NEG, NEG, ZERO, ZERO, ZERO) | 1, 2, 3 | 0b00 |
| `bootorder_set` | (NEG, NEG, ZERO, NEG, ZERO, ZERO) | 1, 2, 4 | 0b00 |
| `real_nvram_write` | (NEG, ZERO, NEG, NEG, ZERO, ZERO) | 1, 3, 4 | 0b00 |
| `me_psp_mailbox` | (ZERO, NEG, NEG, NEG, ZERO, ZERO) | 2, 3, 4 | 0b00 |
| `smram_write` | (NEG, NEG, NEG, NEG, NEG, ZERO) | 1, 2, 3, 4, 5 | 0b00 |

By the structural rule (any NEG in pillar 1..4 → 0b00 unrep), each is **untypable**. Three independent rejection layers: lexical (no IRPD method exists), type-checking (TYPE-HEXAD-001), proof discharge (`admitted(H)` returns false). The Representability Theorem makes this a *mathematical fact*.

### §4.4 Effect Modifiers

`@pure`, `@witness_elide`, `@irreversible`, `@hot_path`, `@chronos_bypass`, `@hexad`/`@safety` classify or annotate effects (cross-ref §2.2).

### §4.5 Wavefront Semantics

| Terminator | Semantics |
|------------|-----------|
| `until quiescent` | All effects committed; no pending side-state |
| `until coherent(Q)` | Manifold coherence Q14 ≥ Q |
| `until count(N)` | After exactly N composed effects |

Compiler magic: single-node inlined; multi-node batched when ACC Wall-Y admits; hot wavefronts SRPA-promoted to specialized native code; cold/high-uncertainty fully witnessed and reversible.

### §4.6 Four Novel Inventions

| Invention | Mechanism | Cycle-cost impact |
|-----------|-----------|-------------------|
| **PIP** — Predictive Inverse Pre-Materialization | Compiler/Catalyst classifies inverse blob (STATIC_BYTES / DYNAMIC_FN / COMPOSED); pre-materialized | Sub-5-cycle hot path |
| **Ghost Effects** — Zero-overhead auditability | `@pure @witness_elide` cycles emit no runtime witness; type system records `Witness=Elided`; OBSERVATORY can reconstruct on demand | Native-speed pure code |
| **Epistemic Effects** — Effects that know what they don't know | `Reduction(..., Uncertainty=U)` propagates U through composition; auto-escalates Trinity Layer 3 when `U.confidence < 0.85q` | Selective overhead |
| **Möbius Effects** — Self-extending effects | `mobius_candidate ... @candidate_for_promotion` → Catalyst promotes new effect decompositions; new SE kinds in band 0x01C7..0x01CF | One-time grammar+SRPA update |

### §4.7 Effect Algebra Composition

Operators of LEX §6 compose effects:

- `e₁ ⊕ e₂` — cycle composition (forwards L-to-R, inverses R-to-L; per TYPES §3.4).
- `e ⟲` — single-step inverse (TYPES §3.5).
- `e ⟲⟲` — full inverse replay (walks entire inverse chain).
- `e ⟡` — explicit witness emit (forces emission for an otherwise-elided cycle).
- `e ↻` — replay a witness (re-execute from captured witness; epoch must match current).
- `h₁ ⧉ h₂` — hexad composition (per HEXAD §2.4 — AND on P1..P4, OR on P5..P6).
- `c ⧈ acquire/release` — linear-cap acquire/release.
- `v ⟴ R` — phase cross to ring R.
- `a ⟵ b @epoch(N)` — epoch-bridge merge.
- `s ⟁ ceiling` — ceiling membership test.
- `cycle ⟐ permission ⟐ causality` — Trinity-Gate predicate composition.
- `coherence ⧗ Q` — coherence query/assert against threshold Q.

The six Compromise-HIGH operations have **no operator path** to construct: the reachability bitmap forbids it; no composition produces a HIGH-tier hexad.

---

## §5. Cycle Inventory

**Source:** III-CYCLES.md.

### §5.1 Cycle Declaration Form

```iii
cycle name(p₁: T₁, ..., pₙ: Tₙ) -> ReturnType <modifiers>* {
    forward { ... }
    inverse { ... }       // optional — SID-derived if absent
}
```

### §5.2 The Reduction Lowering

A `cycle` declaration is syntactic sugar for a `Reduction<F, I, W, H, P, E>` value. SID derives `I` at compile time; `W` is the canonical 128-byte XiiWitness; `H` is the composed hexad over forward-body IRPD calls; `P` is the declared `@ring(...)` set; `E` is the cycle's creation epoch (set at compilation, not via `@epoch(N)` value-modifier).

### §5.3 SID's 17-Kind Classifier

The SE-kinds enum from §4.1 (0x01 MSR_WRITE through 0x11 NMI_INSTALL) plus the three Compromise tiers.

### §5.4 The 32-Step SID Plan

Hand-rolled in `COMPILER/BOOT/sid.{h,c}` (~1200 LoC, no external SMT). Executed at type-check time. Any failure aborts compilation.

| # | Action | Failure code |
|---|--------|--------------|
| 1 | Walk AST for `irpd.*` calls | PARSE-IRPD-001 raw privileged write outside IRPD |
| 2 | Classify each into 17 SE kinds | TYPE-SID-001 unknown IRPD method |
| 3 | Capture prior values (insert auto-`*_read`) | TYPE-SID-002 prior-value capture failed |
| 4 | Construct inverse record (`sid_se_<kind>_t`) | TYPE-SID-003 inverse-record construction failed |
| 5 | Verify inverse round-trips on abstract execution | TYPE-SID-004 inverse does not round-trip |
| 6 | Check composed hexad against `xii_asym_reach6` | TYPE-HEXAD-002 composed hexad outside reachable set |
| 7 | Emit inverse function as Reduction | TYPE-SID-005 inverse Reduction emission failed |
| 8 | Register cycle in live cycle table | TYPE-CYCLE-001 cycle table full / collision |
| 9 | Thread predecessor/successor witness mhashes | TYPE-WIT-001 chain threading failed |
| 10 | Compute PIP blob classification | TYPE-PIP-001 PIP classification failed |
| 11 | Check Möbius coherence Q14 ≥ floor | TYPE-MOB-001 insufficient coherence |
| 12 | Verify Trinity Gate predicates dischargeable | TYPE-TRIN-001 Trinity predicates undischargeable |
| 13 | Check ceiling membership of post-state | TYPE-CEIL-001 post-state outside constitutional manifest |
| 14 | Emit `XII_STEP_KIND_*` constant | TYPE-WIT-002 step_kind allocation failed |
| 15 | Bind plan section anchor | TYPE-PLAN-001 plan anchor missing/invalid |
| 16 | Verify federation tier requirements | TYPE-FED-001 federation tier mismatch |
| 17 | Check epoch consistency | TYPE-EPOCH-001 cycle epoch newer than current |
| 18 | Verify glyph-bound capability drift | TYPE-LIN-003 glyph-drift on cap parameter |
| 19 | Classify epistemic uncertainty | TYPE-EPI-001 uncertainty classification failed |
| 20 | Generate ghost-effect metadata if `@witness_elide` | TYPE-GHOST-001 ghost metadata failed |
| 21 | Compute SRPA hot-path hints | TYPE-SRPA-001 specialization hint failed |
| 22 | Emit cycle descriptor | TYPE-CYCLE-002 descriptor emission failed |
| 23 | Register with OBSERVATORY if `@candidate_for_promotion` | TYPE-OBS-001 observatory registration failed |
| 24 | Verify no raw priv-instructions outside IRPD (defense-in-depth) | PARSE-IRPD-002 raw privileged instruction detected |
| 25 | Check cross-ring marshalling constructors exist | TYPE-RING-001 no marshalling constructor |
| 26 | Verify linear-cap usage balanced | TYPE-LIN-002 unbalanced capability use |
| 27 | Emit inverse replay plan (32-bit bitmap) | TYPE-INV-001 replay plan emission failed |
| 28 | Compute manifest contribution (post-state hash for SCBA) | TYPE-CEIL-002 manifest contribution failed |
| 29 | Verify no waac constraints violated | TYPE-WAAC-001 waac violation |
| 30 | Emit final Reduction six-tuple | TYPE-CYCLE-003 Reduction emission failed |
| 31 | Register in per-CPU forward/inverse rings | TYPE-CYCLE-004 ring-binding failed |
| 32 | Return Reduction to type checker | TYPE-CYCLE-005 return failed |

### §5.5 Witness Emission Protocol

Eight runtime steps per cycle invocation:

1. Capture `predecessor_mhash` from per-CPU `xii_chain_head[cpu]`.
2. Compute `step_kind` from cycle's registered `XII_STEP_KIND_*`.
3. Fill 128-byte struct (predecessor placeholder, step_kind, cycle_seq, chronos_tsc, cost_q14, capability_bind, adversariality_class, federation_route, plan_anchor_id, flags, hexad_packed_and_pad).
4. Compute BLAKE3 over 128-byte struct (with successor field zeroed).
5. Compute HMAC-SHA-256 over BLAKE3 using current Sanctum sub-key (or per-CPU key for R0/R3).
6. Write witness to **both** per-CPU forward and inverse rings (BCWL-indexed).
7. Atomically update `xii_chain_head[cpu]` to new successor mhash.
8. If `waac` or `wavefront` commit boundary, also append to Persistent Audit Spine.

### §5.6 The 128-Byte XiiWitness Layout

| Offset | Size | Field | Bit-layout (where applicable) |
|--------|------|-------|-------------------------------|
| 0x00 | 32 | `predecessor_mhash` | — |
| 0x20 | 32 | `successor_mhash` | computed at emit; placeholder during construction |
| 0x40 | 4 | `step_kind` | u32 — `XII_STEP_KIND_*` constant |
| 0x44 | 4 | `cycle_seq` | u32 per-CPU counter |
| 0x48 | 8 | `chronos_tsc` | u64 TSC at emission |
| 0x50 | 4 | `cost_q14` | Q14 cost estimate (computed by SRPA) |
| 0x54 | 4 | `capability_bind` | u32 — Cap-binding ID (0 if not cap-acquiring) |
| 0x58 | 4 | `adversariality_class` | u32 — AP-tag class (0..7 documented per MODULES) |
| 0x5C | 4 | `federation_route` | u32 — federation routing ID (0 if local-only) |
| 0x60 | 4 | `plan_anchor_id` | u32 — plan-section ID from `@plan_anchor` |
| 0x64 | 4 | `flags` | bit 0 IRREVERSIBLE; bit 1 GHOST; bit 2 HOT_PATH; bit 3 SANCTUM_ACTIVE; bit 4 EPISTEMIC; bit 5 MÖBIUS; bit 6 PROMOTED; bit 7 GHOST_SYNTHESIS (reserved Wave 4); bits 8..31 reserved-for-Catalyst |
| 0x68 | 24 | `hexad_packed_and_pad` | u16 packed hexad + 22 bytes (16-byte HMAC tag tail + 6 bytes pad) |
| 0x80 | (end) | | |

### §5.7 BCWL Indexing — Bloom-Coupled Witness Lattice

- **4096-bit per-CPU Bloom filter** keyed by `successor_mhash`. False-positive rate: <1% for N ≤ 1024 witnesses per CPU per chronos-tick.
- **Skip-list** indexed by `step_kind` ranges (16 buckets, one per allocation band).
- **Radix tree** indexed by `predecessor_mhash` for chain replay.

Operations:
- O(1) presence check (Bloom).
- Logarithmic step_kind-range traversal (skip-list).
- O(log n) chain replay (radix-tree descent).

Hand-rolled in `STDLIB/audit/bcwl.III` (BOOT version: `BOOTSTRAP/bcwl.{h,c}`).

### §5.8 Cycle Table Invariants

Eight, enforced by type system + SRPA:

1. Unique `XII_STEP_KIND_*` per cycle.
2. Hexad remains in `xii_asym_reach6`.
3. Inverse mechanically derivable (or `@irreversible`).
4. At least one valid `@ring(...)`.
5. Valid plan anchor.
6. Catalyst-promoted cycles have Möbius coherence ≥ floor at promotion.
7. Append-only; supersession via promotion only (witnessed).
8. Table mhash in every DRTM quote.

### §5.9 Self-Modifying Cycles

A `@candidate_for_promotion` cycle's forward may invoke `promote { improved_body(...) }` if Catalyst observes a higher-coherence variant in OBSERVATORY.

### §5.10 Self-Modifying Cycle Bounds

Bounded by all of:

| Bound | Constant | Source |
|-------|----------|--------|
| Promotion rate cap | `XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK = 8` substrate-wide | CATALYST §2.3 |
| Möbius coherence floor | `0.92q` Q14 | TRINITY §5 |
| Trinity admission | Layer 3, full conjunct | TRINITY §1.3 |
| Codegen validation | Compile + conformance suite + regression | MODULES §6 |
| Ring-gating | R-2 if low-risk/high-benefit, R-1 otherwise | MODULES §5 |
| Reversibility | `inverse.replay(promotion_witness)` rolls back | CYCLES §6.3 |

Plus the constitutional caps:
- `XII_PHASE_PROMOTE_RATE = 4` phase promotions per chronos-tick.
- `XII_MOD_PROMOTE_RATE = 16` module fusions per chronos-tick.

### §5.11 Reserved step_kind Bands

| Band | Range | Allocated to |
|------|-------|--------------|
| RESERVED_BOOT | 0x0000..0x000F | DriverEntry, Phoenix bootstrap, DRTM ceremony |
| IRPD_PRIVILEGED_WRITE | 0x0010..0x002F | The 17 SE kinds |
| IRPD_PRIVILEGED_READ | 0x0030..0x004F | Read-side IRPD methods |
| CYCLE_LIFECYCLE | 0x0050..0x006F | Cycle lifecycle events |
| WAVEFRONT | 0x0070..0x007F | Wavefront begin/commit/rollback |
| SANCTUM | 0x0080..0x009F | The 10 sealed-call methods |
| TRINITY | 0x00A0..0x00BF | Trinity admission events |
| CEILING | 0x00C0..0x00CF | Ceiling admission events |
| FEDERATION | 0x00D0..0x00EF | Federation replicate/quorum |
| DRTM | 0x00F0..0x00FF | DRTM relaunch/quote/verify |
| VDF | 0x0100..0x010F | VDF squarings |
| OBSERVATORY | 0x0110..0x012F | OBSERVATORY events |
| CATALYST | 0x0130..0x014F | Catalyst observe/synthesize/promote |
| NARRATIVE | 0x0150..0x015F | Narrative Self updates |
| COGNITIVE | 0x0160..0x017F | explain/propose/negotiate/commit/reflect |
| PFS | 0x0180..0x018F | Phantom NVRAM (bricking slots structurally absent) |
| FEDERATION_RESERVED | 0x0190..0x01AF | Future federation extensions (32 slots) |
| USER_RESERVED | 0x01B0..0x01C6 | User-defined cycles (23 slots) |
| MNEME_CATALYST_PROMOTE | 0x01C7..0x01CF | Catalyst-promoted cycles (9 slots) |
| RESERVED_FUTURE | 0x01D0..0x01FF | Future Catalyst bands (48 slots) |

Total: 512 step_kind slots.

---

## §6. Hexad Inventory

**Source:** III-HEXAD.md.

### §6.1 Trit Algebra

| Interpretation | NEG | ZERO | POS | Use |
|----------------|-----|------|-----|-----|
| Balanced | -1 | 0 | +1 | Arithmetic |
| Asymmetric (canonical for composition) | -2 | 0 | +1 | Hexad composition (NEG dominates) |
| Packed (storage) | 0b00 | 0b01 | 0b10 | u16 packing; 0b11 reserved for Catalyst-promoted trit values |

### §6.2 Trit Operations

| Operation | Result for x = NEG | Result for x = ZERO | Result for x = POS |
|-----------|---------------------|----------------------|---------------------|
| `NOT(x)` | POS | ZERO | NEG |

For binary ops, rows below show `op(x, y)` with x fixed; columns are y values:

| Op | x | y = NEG | y = ZERO | y = POS |
|----|---|---------|----------|---------|
| AND | NEG | NEG | NEG | NEG |
| AND | ZERO | NEG | ZERO | ZERO |
| AND | POS | NEG | ZERO | POS |
| OR | NEG | NEG | ZERO | POS |
| OR | ZERO | ZERO | ZERO | POS |
| OR | POS | POS | POS | POS |
| SUM | NEG | NEG | NEG | ZERO |
| SUM | ZERO | NEG | ZERO | POS |
| SUM | POS | ZERO | POS | POS |
| MUL | NEG | POS | ZERO | NEG |
| MUL | ZERO | ZERO | ZERO | ZERO |
| MUL | POS | NEG | ZERO | POS |

Asymmetry: NEG dominates AND/MUL (damage compounds); POS dominates OR/SUM (recovery propagates). `MUL(NEG, NEG) = POS` (double-negation = recovery).

### §6.3 The Six Pillars

| Pillar | Meaning | NEG indicates | ZERO indicates | POS indicates |
|--------|---------|---------------|----------------|---------------|
| P1 | Inverse-Derivability | No mechanical inverse (true bricking) | Irreversible-with-Compromise | Fully SID-derivable |
| P2 | Causality-Depth | ≥8 prior cycles in causal chain | 3..7 prior cycles | ≤2 prior cycles |
| P3 | Consent-Recency | Stale (cross-epoch w/o `@epoch_bridge`) | Within current epoch | Within current session |
| P4 | Replication-Tier | Constitutional w/o `amend.apply` | host_file or federation tier | Transient tier |
| P5 | Adversariality-Class | Un-audited external | Audited external | Self-originated |
| P6 | Coherence-Impact | Decreases manifold coherence | Preserves coherence | Increases coherence |

**P1..P4 are structural** — any NEG → unrepresentable. **P5, P6 are informational** — admissible but raise effective risk; trigger Trinity Layer 3.

### §6.4 Hexad Packing

```c
uint16_t pack_hexad(Hexad h) {
    return ((trit_to_bits(h[0])) << 0)
         | ((trit_to_bits(h[1])) << 2)
         | ((trit_to_bits(h[2])) << 4)
         | ((trit_to_bits(h[3])) << 6)
         | ((trit_to_bits(h[4])) << 8)
         | ((trit_to_bits(h[5])) << 10);
    /* top 4 bits unused, reserved for Catalyst-promoted hexad extensions */
}

uint8_t trit_to_bits(Trit t) {
    switch (t) {
        case NEG:  return 0b00;
        case ZERO: return 0b01;
        case POS:  return 0b10;
    }
    /* 0b11 reserved for future Catalyst-promoted trit values */
}
```

### §6.5 The 144-Byte Reachability Bitmap (math reconciled)

Direct enumeration: 729 hexads × 2 bits = 1,458 bits = 182.25 bytes. The "144 bytes" canonical form encodes **only the structurally-admissible hexads** (the cases where P1..P4 are all in {ZERO, POS}):

```
admissible count = 2^4 (P1..P4 ∈ {ZERO, POS}) × 3^2 (P5, P6 ∈ {NEG, ZERO, POS})
                 = 16 × 9
                 = 144
```

**Encoding (canonical):** 144 admissible hexads × 1 byte each = 144 bytes. Each byte holds:
- bits 7..6: reachability code (00=unrep / 01=rep-no-escalate / 10=rep-with-escalate / 11=reserved-for-Catalyst).
- bits 5..0: metadata (saturation timestamp index, Catalyst extension band tag, observation-frequency rank).

Non-admissible (any-NEG-in-P1..P4) hexads are *implicit* `0b00` — never stored, never queried, never reachable.

Lookup function:
```c
uint8_t bitmap_lookup(Hexad h) {
    if (h[0] == NEG || h[1] == NEG || h[2] == NEG || h[3] == NEG) {
        return 0b00;  /* structurally unreachable */
    }
    uint8_t admissible_idx = pack_admissible(h);  /* 0..143 */
    uint8_t entry = xii_asym_reach6[admissible_idx];
    return (entry >> 6) & 0x3;  /* 2-bit reachability code */
}
```

### §6.6 Composition Rule

```c
Hexad compose_hexad(Hexad h1, Hexad h2) {
    return (
        AND(h1[0], h2[0]),   /* P1: inverse-derivability dominates */
        AND(h1[1], h2[1]),   /* P2: deeper causality dominates */
        AND(h1[2], h2[2]),   /* P3: stalest consent dominates */
        AND(h1[3], h2[3]),   /* P4: highest tier dominates */
        OR (h1[4], h2[4]),   /* P5: adversariality OR-propagates */
        OR (h1[5], h2[5])    /* P6: coherence impact OR-propagates */
    );
}
```

### §6.7 The Representability Theorem

**Theorem (PFS Bricking Impossibility):** The six PFS operations have hexads with NEG in pillars 1..4. By the structural rule, `xii_asym_reach6[H] = 0b00` for each. The Hexad-Tag rule of TYPES §4.1 fails to admit them. `T @safety(<bricking-hexad>)` is uninhabited. **No well-typed III program can carry a value of any of these hexads.**

Three independent rejection layers (HEXAD §4.5):
1. Lexical — no IRPD method exists for any of the six.
2. Type-checking — `TYPE-HEXAD-001 hexad outside reachable set`.
3. Proof discharge — `admitted(H)` returns false; certificate fails to verify.

### §6.8 Dynamic Hexads

Catalyst can grow `xii_asym_reach6` monotonically by admitting previously-unreachable hexads, but **only structurally-admissible ones** (POS in pillars 1..4). The Dynamic-Hexad rule (HEXAD §5) gates this. Bricking hexads remain unreachable forever.

### §6.9 Epistemic Hexads

`Hexad @epistemic(Uncertainty<D, C, Q>)` — hexad carries epistemic state. Bridge from substrate to cognitive layer.

### §6.10 Möbius Hexads

`Hexad @möbius(≥ Q14)` — hexad carries minimum-coherence requirement. Self-consistency as type-level invariant.

### §6.11 The Bitmap Generator

`BUILD/gen_asym_reach6.c` (NIH-extreme; hand-rolled). Steps:

1. Enumerate all 144 structurally-admissible (P1..P4 ∈ {ZERO, POS}) hexads.
2. For each: assess pillar-5 and pillar-6 status; default 0b01 (rep-no-escalate); upgrade to 0b10 if any of P5/P6 is NEG (informational escalation).
3. Pack into 144 bytes per the layout in `INCLUDE/xii_asym_reach6.h`.
4. Compute SHA-256 of canonical 144 bytes — the **bitmap mhash** is part of the substrate's specification root R1.

Catalyst-promoted hexads only flip a `0b00` (implicit) to `0b01`/`0b10` by adding a row to the table — never the reverse. This is the **monotonic-growth invariant**.

---

## §7. Phase Inventory

**Source:** III-PHASES.md.

### §7.1 Ring Lattice

```
R-2 (Sanctum) ≼ R-1 (Hypervisor) ≼ R0 (Driver) ≼ R3 (User)
```

### §7.2 Cross-Ring Constructor Catalogue

| # | Constructor | Rings | Mechanism | Witness step_kinds | Status |
|---|-------------|-------|-----------|---------------------|--------|
| 1 | Magic-MSR | R3 ↔ R-1 | RDMSR(0xC001_F100) ↔ vmexit dispatch | `MAGIC_MSR_INVOKE`, `MAGIC_MSR_DISPATCH` | active |
| 2 | IOCTL | R3 ↔ R0 | DeviceIoControl ↔ IRP_MJ_DEVICE_CONTROL | `IOCTL_DISPATCH` | active |
| 3 | Sanctum Gate | R-1 ↔ R-2 | 8-step Sealed-Cycle Box | `SANCTUM_INTENT_MINT`, `SANCTUM_DISPATCH`, `SANCTUM_EXIT` | active |
| 4 | VMRUN Trampoline | R-1 ↔ R0 | VMRUN/VMLAUNCH ↔ vmexit | `VMRUN` | active |
| 5 | SYSRET / SYSENTER | R0 ↔ R3 | Legacy x86; warning-emitting | (legacy-warning) | discouraged |

### §7.3 Marshalling Rules

1. **Glyph-Bound Zero-Copy** — direct pointer handoff when source/dest agree on glyph identity; runtime drift detection.
2. **Witness Threading** — every transition emits a witness linking pre/post mhashes; chain continuous.
3. **Inverse Marshalling** — SID-derived inverse includes inverse marshalling.
4. **Epistemic Marshalling** — high-uncertainty values trigger automatic `reflect(uncertainty)` before transition.
5. **Möbius Marshalling** — manifold-affecting transitions carry minimum `MöbiusCoherence` in their hexad.

### §7.4 Four Novel Phase Inventions

- **Dynamic Phase Promotion** — runtime ring-climb if hexad/Trinity/coherence permit. Rate cap 4/tick.
- **Epistemic Phases** — `phase.current() : Phase` lets code reason about its execution ring.
- **Ghost Phases** — `@ghost(R3)` emits witness without privileged effect at R3 (audit-only).
- **Predictive Phase Specialization** — SRPA + PIP pre-materialize most-likely ring lowering for sub-5-cycle dispatch.

### §7.5 Phase Lattice Order

The lattice is **total and linear**. There are no "peer" rings — only higher and lower. No cumulativity: a value at R3 is *not* a value at R0; cross-ring requires explicit `⟴`. Direct R3 ↔ R-2 is forbidden — must traverse via R0 → R-1.

---

## §8. Sanctum Inventory

**Source:** III-SANCTUM.md.

### §8.1 The 10 Sealed Slots

| seal_id | Method | Purpose | Ring entry | Witness step_kind |
|---------|--------|---------|------------|-------------------|
| 0 | `INVALID` | Structural guard | — | `SANCTUM_INVALID_REJECT` |
| 1 | `drtm_relaunch` | Full DRTM relaunch + new epoch | R-1 | `DRTM_RELAUNCH` |
| 2 | `pfs_var_set` | Set Phantom NVRAM variable (file-backed) | R-1 | `PFS_VAR_SET` |
| 3 | `pfs_deny_quote` | Deny a DRTM quote | R-1 | `PFS_DENY_QUOTE` |
| 4 | `crcc_key_export` | Export CRCC-derived key | R-1 | `CRCC_KEY_EXPORT` |
| 5 | `phoenix_emergency` | Emergency Phoenix bookmark | R-1 | `PHOENIX_EMERGENCY` |
| 6 | `chronos_set_epoch` | Advance/set witnessed-time epoch | R-1 | `CHRONOS_SET_EPOCH` |
| 7 | `compromise_quote` | Emit compromise-class DRTM quote | R-1 | `COMPROMISE_QUOTE` |
| 8 | `phoenix_bookmark` | Phoenix bookmark (non-emergency) | R-1 | `PHOENIX_BOOKMARK` |
| 9 | `compile_module` | Recompile a III module inside Sanctum (Stage 4) | R-1 | `SANCTUM_COMPILE_MODULE` |

### §8.2 `@seal_id(N)` Annotation Rules

- `@seal_id(N)` legal **only** on `fn` (not `cycle`) declared inside `STDLIB/sanctum.III`.
- N ∈ {0..9}; outside range → `PARSE-SEAL-001 seal_id out of range`.
- Slot 0 is BOOT-bound (programmer cannot register; the body emits `SANCTUM_INVALID_REJECT` and returns `Compromise<MEDIUM>`).
- Each N ∈ {1..9} bound exactly once per closure root; collision → `TYPE-SEAL-002`.

### §8.3 `sanctum_enter |frame| { ... }` 8-Step Protocol

1. Mint Trinity-Gate intent token under sanctum sub-key.
2. Load intent token into registers (r10..r13 per Sanctum-Gate ABI).
3. Emit `SANCTUM_INTENT_MINT` witness.
4. Call `xii_sanctum_gate_enter` trampoline. Hardening (x86):
   - **IBPB** (U+0049 expanded: Indirect Branch Prediction Barrier — flushes branch-prediction history).
   - **VERW** (Verify segment limit + invalidate speculative load buffers).
   - **SSBD** (Speculative Store Bypass Disable).
   - **RSP swap** to per-CPU Sanctum stack.
   - **Full GPR/FPR/XMM save** to per-CPU save area.
5. Per-CPU PKRU rewrite to Sanctum key (Memory Protection Keys discipline).
6. Dispatch by seal_id.
7. Execute sealed body (full witness emission per effect).
8. On exit: post-witness, restore PKRU, restore GPR/FPR/XMM, swap rsp back, return to calling ring.

### §8.4 Trinity Prerequisites

```c
xii_trinity_algebra_admit(seal_id, operator_consent, permission_cap, causality_witness, sanctum_frame, &convergence_point);
```

Any conjunct rejection → `SANCTUM_TRINITY_REJECT` witness + SID-inverse unwind. Even `drtm_relaunch` is Trinity-gated.

### §8.5 DRTM-Relaunch Mechanism

Six steps:

1. Hash all currently-mounted modules + cycle table + Phantom NVRAM + OBSERVATORY + R1 + silicon fingerprint.
2. Increment chronos epoch counter.
3. Re-anchor PAS (new sub-key for new epoch; new chain-head links to prior epoch's last witness).
4. Re-derive Sanctum sub-keys via HKDF.
5. Emit 312-byte DRTM quote.
6. Optionally promote `telosc-σ` into new Sanctum (if `@promote_compiler`).

### §8.6 Sanctum as Live Data Manifold

Manifold contents: Phantom NVRAM variables, DRTM quote chain, Phoenix bookmarks, Sanctum-data perturbation state, per-CPU Sanctum frames, current epoch + VDF parameters, compiler closure root (post-Stage-4), active policy.

Four novel inventions (SANCTUM §5):
- Sanctum Pattern Recognition.
- Crash-Proof Address Navigation.
- Zero-Latency Upward Transportation.
- Predictive Sanctum Specialization.

### §8.7 DRTM Quote Layout (312 bytes)

| Offset | Size | Field |
|--------|------|-------|
| 0x000 | 32 | silicon_fingerprint |
| 0x020 | 32 | r1_specification_root |
| 0x040 | 32 | cycle_table_mhash |
| 0x060 | 32 | xii_asym_reach6_mhash |
| 0x080 | 32 | observatory_snapshot_mhash |
| 0x0A0 | 32 | phantom_nvram_mhash |
| 0x0C0 | 32 | federation_member_list_mhash |
| 0x0E0 | 8 | epoch_number (u64) |
| 0x0E8 | 8 | chronos_tsc_at_relaunch |
| 0x0F0 | 16 | vdf_squarings_count + vdf_position |
| 0x100 | 32 | parent_quote_mhash (links chain back) |
| 0x120 | 64 | ed25519_signature (sub-key over the above 0x000..0x11F) |
| 0x160 | 8 | suite_id (cryptographic agility — sub-key suite identifier; default 0x0001 = Ed25519+SHA-256+HMAC; see III-CRYPTO-AGILITY.md) |
| 0x168 | 8 | reserved-for-Catalyst |
| 0x170 | (end of 312-byte quote) | |

### §8.8 Per-CPU Sanctum Frame

| Field | Size | Description |
|-------|------|-------------|
| frame_id | 8 | Per-CPU unique frame identifier |
| pkru_pre | 4 | PKRU value at entry (restored on exit) |
| save_area_ptr | 8 | Pointer to per-CPU GPR/FPR/XMM save area |
| save_area_size | 4 | 1024 bytes (GPR 128 + FPR 512 + XMM 384) |
| intent_token | 64 | Trinity intent token (predecessor + cap + causality + sanctum-state mhashes) |
| chain_head_pre | 32 | Witness chain head at entry |
| sub_key_id | 8 | Active sanctum sub-key identifier |
| flags | 4 | bit 0 ACTIVE; bit 1 IBPB_DONE; bit 2 VERW_DONE; bit 3 SSBD_ENABLED; bit 4 STACK_SWAPPED |
| reserved | 28 | Pad to 160 bytes |

---

## §9. Trinity Inventory

**Source:** III-TRINITY.md.

### §9.1 The Three-Layer Ceiling

| Layer | Mechanism | Cost (cycles) | Sufficient when |
|-------|-----------|---------------|------------------|
| 1 — SCBA bit-test | 8-KiB bitarray; bit_idx = first_16_bits(BLAKE3(post_state)) | 1–2 | `@pure`; SRPA-pre-approved hot paths; inside active waac |
| 2 — ACC Wall-Y | `acc_compose(w.effects)` admit check | 15–40 | Multi-effect wavefront not touching R-2; low uncertainty |
| 3 — Trinity Gate | intent × cap × causality × sanctum-state evaluation | 80–300 | Any R-2 op; constitutional-tier; `U.confidence < 0.85q`; Catalyst promote; NEG-pillar in 5/6 |

### §9.2 Failure-Mode Codes (proposed namespace per §19.2)

| Code (current → proposed) | Layer | Recovery |
|---------------------------|-------|----------|
| TRINITY_INTENT_REJECT → TRIN-L3-INTENT-REJECT | 3 | Re-authenticate |
| TRINITY_CAP_REJECT → TRIN-L3-CAP-REJECT | 3 | Re-acquire cap |
| TRINITY_CAUSALITY_REJECT → TRIN-L3-CAUSALITY-REJECT | 3 | Force audit replay |
| TRINITY_SANCTUM_REJECT → TRIN-L3-SANCTUM-REJECT | 3 | Re-enter sanctum |
| ACC_WALL_Y_REJECT → TRIN-L2-ACC-REJECT | 2 | Rollback wavefront |
| SCBA_BIT_REJECT → TRIN-L1-SCBA-REJECT | 1 | Escalate to L2/L3 |
| HEXAD_UNREPRESENTABLE → TRIN-ALL-HEXAD-UNREP | All | Compile-time error |
| MOBIUS_COHERENCE_FAIL → TRIN-L3-MOBIUS-FAIL | 3 | Reject + propose alternative |
| CEILING_VIOLATION → TRIN-L3-CEILING-VIOLATION | 3 | Hard reject + compromise quote |
| EPISTEMIC_LOW_CONFIDENCE → TRIN-L3-EPISTEMIC | 3 | Escalate + reflect(uncertainty) |
| WAAC_VIOLATION → TRIN-L2-WAAC-VIOLATION | 2/3 | Rollback to last waac commit |

### §9.3 Five Novel Trinity Inventions

- **Predictive Trinity** — pre-evaluates Trinity decisions on hot-path tuples; runtime bit-test.
- **Epistemic Trinity** — auto-escalates when `U.confidence < 0.85q`.
- **Möbius Trinity** — checks projected post-coherence ≥ floor.
- **Catalyst Trinity** — Catalyst can refine each conjunct's predicate.
- **Ghost Trinity** — `@ghost_trinity` evaluates without committing.

### §9.4 Dynamic Layer Activation

Risk profile (Q14) drives which layers are active. Self-referential governance loop with stability via gradual de-elevation (system stays at higher layer ≥1 chronos-tick after risk drops, preventing oscillation).

### §9.5 Trinity Convergence Point

`XiiConvergencePoint` — structure recording the outcome of Trinity admission.

| Field | Size | Description |
|-------|------|-------------|
| admitted_at_layer | 1 | 1, 2, or 3 |
| intent_witness_mhash | 32 | (if Layer 3) |
| cap_witness_mhash | 32 | (if Layer 3) |
| causality_witness_mhash | 32 | (if Layer 3) |
| sanctum_state_witness_mhash | 32 | (if Layer 3) |
| acc_wall_y_delta | 12 | (if Layer 2) — Z₃⁶ delta vector |
| scba_bit_idx | 2 | (if Layer 1) — u16 bit position |
| outcome | 1 | 0 ADMIT / 1 DENY / 2 ESCALATE |
| reject_code | 4 | (if DENY) — TRIN-L*-* code |
| reserved | 16 | Pad to 128 bytes |

---

## §10. Module Inventory

**Source:** III-MODULES.md.

### §10.1 Module Identity

`closure_root(m) = SHA-256(canonical_source(m))`. Two modules with same closure root are *the same module* across federation.

### §10.2 Module Manifest Structure (now table)

| Field | Type | Description |
|-------|------|-------------|
| `closure_root` | mhash | Module mhash |
| `canonical_source_mhash` | mhash | Source mhash (without included module bodies) |
| `r1_specification_root` | mhash | R1 mhash this module compiled against |
| `r1_a1` ... `r1_idx` | array of mhash | Per-spec R1 family hashes |
| `imports` | array of (qualified_name, closure_pin) pairs | Closure-pinned imports |
| `exports` | array of (item_name, item_mhash) | Exported items |
| `cycle_table_contributions` | array of XII_STEP_KIND_* | Step-kind allocations |
| `hexad_table_contributions` | array of u16 packed hexads | Dynamic-hexad reservations |
| `proof_certificates` | array of ProofCert mhash | Per-cycle proof certificates |
| `target_arch` | enum | x86_64 / aarch64 / riscv64 (Wave 3) |
| `crypto_suite_id` | u64 | Cryptographic suite identifier (Wave 0 — see CRYPTO-AGILITY) |
| `signature` | Ed25519 sig | Operator's signing-key signature over above |

The manifest is appended to every binary artifact in the `.iii_manifest` PE/ELF section.

### §10.3 Name Resolution as Mathematical Discovery

Algorithm: closure-root computation → OBSERVATORY query → argmax(Möbius coherence × performance fingerprint) → fall back to Catalyst synthesis or federation pull → register as witnessed Reduction.

### §10.4 Structured Transmission Rules

1. Glyph-Bound Zero-Copy.
2. Predictive Specialization (PIP+SRPA).
3. Epistemic Transmission.
4. Möbius Transmission.
5. Tier-Gated.

### §10.5 Complementarity Principle

Two modules are *perfectly complementary* iff a witnessed reduction path between them: composed hexad admissible, coherence non-decreasing, performance fingerprint within 5% of theoretical minimum. Substrate invariant: hold for every pair.

### §10.6 Ring-Gated Promotion Decision Tree

| Risk | Benefit | Launch ring |
|------|---------|-------------|
| LOW | HIGH | R-2 (Sanctum) |
| MEDIUM | MEDIUM | R-1 (Hypervisor) |
| LOW | LOW (pure user-level) | R0 / R3 |
| HIGH | any | Reject for human review (`MOD_PROMOTE_REJECT`) |

### §10.7 Codegen-First Validation

Every dynamic deployment: generate change as new III module → compile via `telosc-σ` (R-2 preferred) → run conformance suite → emit deployment flag.

### §10.8 Deployment Flags

- `SAFE_APPROVED` — clean.
- `SAFE_FLAGGED` — structurally safe, semantically differs from baseline (human review).
- `UNSAFE_REJECTED` — failed structural invariants; never deployed.

### §10.9 Dynamic Module Fusion

Catalyst-detected high complementarity → propose fused candidate → codegen-validate → ring-gated deploy → originals retained (auditability) but fused dispatched.

### §10.10 Module Closure Manifest as Typed Structure

(Cross-ref §10.2 above; the canonical typed structure is `STDLIB/module/manifest.III`.)

---

## §11. Catalyst Inventory

**Source:** III-CATALYST.md.

### §11.1 Mandate

Observe OBSERVATORY → discover beneficial abstractions → formalize → promote into live manifold → preserve every invariant.

### §11.2 The 8 Promotion Gates (cross-referenced)

| Gate | Condition | Discharged by |
|------|-----------|----------------|
| 1 | OBSERVATORY saturation ≥ threshold | CATALYST §3 (Welford+Hoeffding+chronos-tick) |
| 2 | Möbius coherence Q14 ≥ floor (0.92q) | TRINITY §5 Möbius rule |
| 3 | Trinity Gate fully discharged | TRINITY §1.3 Layer 3 |
| 4 | Constitutional Ceiling admits post-state | MODULES §5 |
| 5 | Hexad admitted (or dynamically extended) | HEXAD §3, §5 |
| 6 | Codegen-validated (compile + conformance + regression) | MODULES §6 |
| 7 | Ring-gated (R-2 / R-1 / R0) | MODULES §5.2 |
| 8 | Deployment flag determined: SAFE_APPROVED or SAFE_FLAGGED — UNSAFE_REJECTED aborts | MODULES §6.1 |

### §11.3 Synthesis Capabilities

1. New cycle kinds (band 0x01C7..0x01CF).
2. New keywords / operators (filling reserved slots).
3. New hexads (monotonic bitmap growth).
4. Module fusions.
5. Improved Trinity predicates.
6. Improved SID rules.
7. Predictive specialization hints (PIP/SRPA overrides).

### §11.4 Rate Caps

| Constant | Value | Scope |
|----------|-------|-------|
| `XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK` | 8 | substrate-wide cycle promotions per chronos-tick |
| `XII_PHASE_PROMOTE_RATE` | 4 | substrate-wide phase promotions per chronos-tick |
| `XII_MOD_PROMOTE_RATE` | 16 | substrate-wide module fusions per chronos-tick |

### §11.5 Five Inviolable Safety Rails

1. No promotion produces unrepresentable hexad.
2. No promotion decreases global Möbius coherence.
3. Every promotion preceded by codegen validation.
4. Every promotion explicitly flagged.
5. Catalyst itself is a Reduction (rollbackable).

### §11.6 Operator Overrides

`catalyst.pause()`, `catalyst.reject(proposal_mhash)`, `inverse.replay(promotion_witness)`, `catalyst.constrain(domain, max_rate)` — all witnessed cycles. Plus the **Founder's Anchor** (item 178; see III-FOUNDERS-ANCHOR.md): permanent veto independent of quorum.

---

## §12. Federation Inventory

**Source:** III-FEDERATION.md.

### §12.1 Tier Model

| Tier | Name | Mutation | Outbound | Quorum notation |
|------|------|----------|----------|-----------------|
| 0 | transient | Unrestricted | Local only | — |
| 1 | host_file | Quorum-3-2 (3 peers, 2 must agree) | Peer pull | (3, 2) |
| 2 | federation | Quorum-5-3 (5 peers, 3 must agree) + fragment_replicate | Broadcast | (5, 3) |
| 3 | constitutional | `amend.apply` | Unanimous | (N, N) |

### §12.2 Tier-Gated Outbound

```
Γ ⊢ message m
Γ ⊢ min_tier = minimum_tier_of_modules_in(m)
Γ ⊢ outbound_allowed(min_tier)
─────────────────────────────
Γ ⊢ m may be sent to federation
```

Strictest discipline: minimum tier across all contributing modules.

### §12.3 Cross-Tier Fusion

Tier₃ module can only fuse with another Tier₃ module. Cross-tier fusion requires `amend.apply`.

### §12.4 Quorum Specifications

| Quorum form | Signers required | Agreement required | Use |
|-------------|-------------------|---------------------|-----|
| (3, 2) | 3 peers | 2 must agree | Tier₁ mutation |
| (5, 3) | 5 peers | 3 must agree | Tier₂ mutation |
| (N, N) | All federation members | All must agree | Tier₃ constitutional |

Failure → `FED_QUORUM_FAIL` witness; message dropped.

### §12.5 Federation Transport

IOMMU IOPT mediates network adapter DMA; outbound packets carry witness-signature trailer (RFC-4302 AH style); inbound witness-tagged packets routed to federation; non-tagged packets pass to Windows transparently. Discovery is transparent.

### §12.6 Federation Peer Discovery Mechanism

Three-step:

1. **Witness-tagged broadcast** — each III peer periodically (default: every chronos-tick) emits a small UDP-encoded witness-tagged packet on link-local broadcast (no fixed port; the AH trailer is what identifies III peers).
2. **Mutual attestation** — receiving peer verifies the witness signature against the broadcasting peer's claimed DRTM-rooted federation key.
3. **Federation-join handshake** — both peers exchange DRTM quote chains; verify chain-back-to-epoch-0; if both verify, peer is added to local federation peer list.

No DNS, no fixed port, no rendezvous server. Two III machines on the same L2 segment discover each other within one chronos-tick.

---

## §13. Cognitive Layer Inventory

The cognitive primitives are **language productions**, not library calls. Each emits a witness in the COGNITIVE band (0x0160..0x017F).

| Primitive | Form | Witness step_kind | Source |
|-----------|------|-------------------|--------|
| `narrative` | Declaration block | `XII_STEP_KIND_NARRATIVE_SELF_UPDATE` | LEX §4.1.5, GRAMMAR §5.6 |
| `explain` | `explain(target, detail_level)` | `XII_STEP_KIND_COGNITIVE_EXPLAIN` | LEX §4.1.5, GRAMMAR §7 |
| `propose` | `propose { abstraction_name, justification, expected_impact, risk_profile }` | `XII_STEP_KIND_COGNITIVE_PROPOSE` | LEX §4.1.5, GRAMMAR §7 |
| `negotiate` | `negotiate(goal, constraints, preferences, uncertainty_tolerance)` | `XII_STEP_KIND_COGNITIVE_NEGOTIATE` | LEX §4.1.5, GRAMMAR §7 |
| `commit` | `commit(intent, witness_requirements, human_confirmation)` | `XII_STEP_KIND_COGNITIVE_COMMIT` | LEX §4.1.5, GRAMMAR §7 |
| `reflect` | `reflect(state / uncertainty / coherence / narrative / manifest / epoch)` | `XII_STEP_KIND_COGNITIVE_REFLECT` | LEX §4.1.5, GRAMMAR §7 |
| `uncertainty` | `uncertainty.in(domain)`, `uncertainty.confidence`, `uncertainty.open_questions` | `XII_STEP_KIND_COGNITIVE_UNCERTAINTY` | LEX §4.1.5 |

Detail levels for `explain`: `executive`, `technical`, `full_trace`, `formal`, `visual`. Reflect targets: `state`, `uncertainty`, `coherence`, `narrative`, `manifest`, `epoch`.

The cognitive layer is *typed*: epistemic types (`Uncertainty<D, C, Q>`) propagate through composition; the type checker enforces preconditions on `negotiate` and `commit`. Per TYPES §8.4.

---

## §14. Witness Chain & BCWL Inventory

(Cross-cutting view; restated for stand-alone reference. Canonical sections are §5.5–§5.7.)

### §14.1 The 128-Byte XiiWitness Layout

Restated from §5.6.

### §14.2 8-Step Emission Protocol

Restated from §5.5.

### §14.3 BCWL Indexing

Restated from §5.7. False-positive rate: <1% for N ≤ 1024 witnesses per CPU per chronos-tick. Above that threshold, the secondary skip-list disambiguates exact membership at logarithmic cost.

### §14.4 HMAC Sub-Key Derivation

```
sub_key[cpu] = HKDF-SHA-256(
    master = sanctum_master_key,
    salt   = "III-WITNESS-CHAIN-V1",
    info   = "cpu=" || cpu_id || ",epoch=" || current_epoch || ",suite=" || crypto_suite_id
)
```

(The `suite_id` field is added per Cluster K item 176 — Cryptographic Agility. See III-CRYPTO-AGILITY.md.)

Sub-key rotates at every DRTM epoch advance; old-epoch witnesses verify under their own epoch's keys.

### §14.5 Witness Stream Iterator

`for w in witness_stream where pred(w) { ... }` — BCWL skip-list traversal; sub-millisecond per predicate match on 1M-witness corpus.

### §14.6 Witness Chain Replay Algorithm

Algorithm: starting from a known `head_mhash`, walk back through predecessor links until reaching either epoch boundary or chain origin. At each step, verify HMAC under the witness's epoch sub-key; verify BLAKE3 over the witness body; verify hexad admission against `xii_asym_reach6` snapshot at that epoch.

```
fn walk_chain_backward(head: mhash, depth_limit: u32) -> Result<List<Witness>, ChainError> {
    let mut acc = [];
    let mut cur = head;
    while acc.len() < depth_limit {
        let w = bcwl.lookup_by_mhash(cur)?;
        verify_hmac(w, sub_key_for_epoch(w.epoch))?;
        verify_blake3(w)?;
        verify_hexad_admitted(w.hexad_packed, snapshot_at_epoch(w.epoch))?;
        acc.append(w);
        cur = w.predecessor_mhash;
        if cur == ZERO_MHASH { break; }  // chain origin
    }
    return Ok(acc);
}
```

---

## §15. Conformance Inventory

**Source:** III-CONFORMANCE.md.

### §15.1 30 Criteria

**Core Language (C-1 through C-15):** Closure Root Determinism · Phase-Polymorphism Soundness · SID Inverse Round-Trip · Hexad Unrepresentability · Sealed-Call Surface Match · DRTM Quote Chain Verifiable · Closure-Pinned Imports · Möbius Coherence Floor Maintained · Predictive Trinity Hot-Path Latency · Epistemic Escalation · Ring-Gated Promotion · Codegen Validation Before Deployment · Explicit Deployment Flags · Ghost Effects + Witness Elision · Catalyst Promotions: Witnessed, Federated, Reversible.

**Substrate & Runtime (C-16 through C-25):** IRPD-Only Privileged Writes · Witness Continuity Across All Rings and Module Boundaries · Three-Layer Ceiling Never Bypassed · Linear Capabilities Glyph-Bound, Drift-Detecting · Inverse Rings Consistent with Forward Rings · OBSERVATORY Saturation Thresholds Respected · Phoenix Bookmark Round-Trip Byte-Exact · DRTM Epoch Advancement VDF-Witnessed · Sanctum Sealed Calls Trinity-Gated · Self-Hosting Compiler Runs as Ring -2 Sealed Call.

**Cognitive Layer & Human Interface (C-26 through C-30):** Narrative Self Witnessed and Queryable · Cognitive Primitives are First-Class Productions · Frontend Operates Without Module Knowledge · All User-Visible Actions Traceable to Witness Chain · The System Can Be Queried by an Operator Who Knows Nothing.

### §15.2 Per-Spec Sub-Criteria — Namespace Refinement Required

`C-LEX-1`, `C-GRAM-1`, `C-TYPE-1`, etc. share C-* numbering with CONFORMANCE.md's `C-1..C-30`. **[REFINEMENT §19.2]** Proposed renaming: `C-A1-*`, `C-A2-*`, ..., `C-IDX-*` for per-spec criteria; `C-1..C-30` retained as substrate-wide acceptance set.

### §15.3 The Verifier

`TOOLS/iii-conformance.III` — R3 executable. Closure-pinned to known mhash. Reads R1 from audit spine, runs `TESTS/conformance/*` corpus, returns per-criterion pass/fail and aggregate compliance percentage.

### §15.4 Conformance Runner Output Format

```
{
    "verifier_mhash": "0x...",
    "r1_observed": "0x...",
    "criteria": [
        {"id": "C-1", "title": "Closure Root Determinism", "status": "PASS", "duration_us": 1234},
        ...
    ],
    "aggregate": {
        "total": 30,
        "passed": 30,
        "failed": 0,
        "skipped": 0,
        "compliance_q14": 16384  // 1.0 in Q14
    },
    "witness_mhash": "0x...",
    "signature": "0x..."
}
```

The output is itself a witnessed reduction; the verifier's run produces its own audit trail.

---

## §16. ABI Inventory

**Source:** III-ABI.md.

### §16.1 The Single Rule

`extern @abi(c-msvc-x64)` is the only legal cross-language bridge. Bootstrap-only; vestigial after Stage 4.

### §16.2 Constraints

1. ABI name must be `c-msvc-x64`.
2. Extern blocks ring-restricted to R0/R3.
3. Every extern call wrapped in synthesized cycle with `Compromise<MEDIUM>` inverse and `EXTERN_C_CALL` hexad.
4. No naked extern declarations (must be inside `@ring(R0, R3)` module).
5. Argument types restricted: primitives, raw pointers, references, fixed arrays, extern-declared types only. Higher-kinded III types forbidden.

### §16.3 Bootstrap Surface

Closure-pinned in `STDLIB/extern_bootstrap.III`. Categories:
- crypto: SHA-256, BLAKE3, HMAC-SHA-256, HKDF, Ed25519, VDF (pre-Wave-0; replaced by Crypto Agility post-Wave-0).
- unicode: UTF-8 decoder + NFC normalization.
- bootstrap: BCWL primitives.
- Windows kernel-mode driver dispatch helpers.
- core: memcpy, memset, memcmp re-implemented in `core/mem.c`.

After Stage 4, SELF stdlib re-implements each in III; extern declarations become vestigial.

---

## §17. R1 Specification-Root Family

### §17.1 The 15 Slots

| Slot | Document | Subject (terse) |
|------|----------|-----------------|
| R1.A1 | III-LEXICON.md | Alphabet (47/19/23/25 + literals + comments) |
| R1.A2 | III-GRAMMAR.bnf | BNF + AST kinds + precedence |
| R1.A3 | III-TYPES.md | Type system + folded proof layer |
| R1.A4 | III-EFFECTS.md | 17 SE kinds + 3 Compromise tiers |
| R1.A5 | III-CYCLES.md | Cycle calculus + SID + witness emission |
| R1.A6 | III-HEXAD.md | Asymmetric ternary ground |
| R1.A7 | III-PHASES.md | Cross-ring lattice |
| R1.A8 | III-SANCTUM.md | Ring -2 discipline |
| R1.A9 | III-TRINITY.md | Admission manifold |
| R1.A10 | III-MODULES.md | Modules + complementarity |
| R1.B1 | III-CATALYST.md | Self-extension engine |
| R1.B2 | III-FEDERATION.md | Tier-gated outbound |
| R1.B3 | III-CONFORMANCE.md | 30 criteria |
| R1.C1 | III-ABI.md | Single bootstrap rule |
| R1.IDX | III-INDEX.md | Master index |

**Composite (per INDEX §2):**
```
R1 = SHA-256(R1.A1 || R1.A2 || R1.A3 || R1.A4 || R1.A5 ||
             R1.A6 || R1.A7 || R1.A8 || R1.A9 || R1.A10 ||
             R1.B1 || R1.B2 || R1.B3 || R1.C1 || R1.IDX)
```

Concatenation discipline: in INDEX §1's listed order; big-endian byte concatenation; no separator bytes.

### §17.2 R1 Mutation Path

| Path | Mechanism | Trigger |
|------|-----------|---------|
| Catalyst-promoted append | New keyword/modifier/operator/cycle/hexad in reserved slot → re-canonicalize affected doc → bump R1.X → bump composite R1 → DRTM relaunch | OBSERVATORY saturation + 8-gate evaluation |
| `amend.apply` constitutional | Tier-3 unanimous quorum → re-seal affected doc → bump R1.X → bump composite R1 → DRTM relaunch | Operator amendment invocation |
| Major version (R1 → R2) | Fresh specification root + substrate-wide DRTM ceremony | Categorical advance (new privilege ring; new crypto era; new logic) |

**Founder's Anchor veto** (item 178): all three paths admit a permanent veto from the Founder's Anchor key, structurally protected from Catalyst removal. See III-FOUNDERS-ANCHOR.md.

---

## §18. Cross-Cutting Analyses

### §18.1 Symbol Audit

Three sub-tables: visual distinctness × mnemonic quality × usage status.

#### §18.1.1 Visual Distinctness

| Operator | Codepoint | Visual Distinctness |
|----------|-----------|---------------------|
| `⟲` Inverse | U+27F2 | High |
| `⊕` Cycle Compose | U+2295 | High |
| `⊗` Glyph Materialize | U+2297 | High |
| `⧉` Hexad Compose | U+29C9 | Medium |
| `⟐` Trinity Gate | U+27D0 | High |
| `↻` Replay | U+21BB | High |
| `⟡` Witness Emit | U+27E1 | High |
| `⟁` Ceiling Check | U+27C1 | High |
| `⧗` Möbius Coherence | U+29D7 | Medium |
| `⟴` Phase Cross | U+27F4 | Medium |
| `⧈` Cap Acquire/Release | U+29C8 | Medium |
| `⟵` Epoch Bridge | U+27F5 | High |
| `⧊` VDF Squaring | U+29CA | High |
| `⟶` Federation Replicate | U+27F6 | High |
| `⨁` Amendment Apply | U+2A01 | **Medium — visually similar to `⊕`** |
| `⊛` Catalyst Promote | U+229B | High |
| `⧄` OBSERVATORY Saturate | U+29C4 | Medium |
| `⧇` Uncertainty Query | U+29C7 | Medium |
| `⧋` Propose | U+29CB | Medium |

#### §18.1.2 Mnemonic Quality

| Operator | Mnemonic Quality | Note |
|----------|-------------------|------|
| `⟲` Inverse | High | clockwise loop = "go back" |
| `⊕` Cycle Compose | High | familiar XOR/group-sum |
| `⊗` Glyph Materialize | Medium | tensor product evokes "combination" not "materialize" |
| `⧉` Hexad Compose | Medium | overlapping squares evoke "stack" |
| `⟐` Trinity Gate | High | diamond-with-dot = "convergence point" |
| `↻` Replay | High | clockwise circle = "again" |
| `⟡` Witness Emit | Medium | lozenge — many possible meanings |
| `⟁` Ceiling Check | High | nested triangle = "bound" |
| `⧗` Möbius Coherence | **Low** | hourglass evokes time, not coherence |
| `⟴` Phase Cross | Medium | abstract |
| `⧈` Cap Acquire/Release | Medium | neutral |
| `⟵` Epoch Bridge | High | leftward arrow = "bring into" |
| `⧊` VDF Squaring | High | triangle-dot evokes math op |
| `⟶` Federation Replicate | High | rightward arrow = "send out" |
| `⨁` Amendment Apply | High | n-ary direct sum apt |
| `⊛` Catalyst Promote | Medium | circled asterisk neutral |
| `⧄` OBSERVATORY Saturate | Low | abstract |
| `⧇` Uncertainty Query | Low | abstract |
| `⧋` Propose | Low | abstract |

#### §18.1.3 Usage Status

| Operator | Status | Used in body of |
|----------|--------|------------------|
| `⟲` Inverse | KEEP | TYPES, CYCLES, EFFECTS |
| `⊕` Cycle Compose | KEEP | TYPES, CYCLES, EFFECTS |
| `⊗` Glyph Materialize | KEEP-NOTE | GRAMMAR only |
| `⧉` Hexad Compose | KEEP | TYPES, HEXAD, EFFECTS |
| `⟐` Trinity Gate | KEEP | TRINITY |
| `↻` Replay | KEEP | EFFECTS |
| `⟡` Witness Emit | KEEP | CYCLES |
| `⟁` Ceiling Check | KEEP | TRINITY, MODULES |
| `⧗` Möbius Coherence | **FLAG** (mnemonic) | TYPES, TRINITY, MODULES |
| `⟴` Phase Cross | KEEP | PHASES, SANCTUM |
| `⧈` Cap Acquire/Release | KEEP | TYPES |
| `⟵` Epoch Bridge | KEEP | TYPES, EFFECTS |
| `⧊` VDF Squaring | KEEP-NOTE | defined-only |
| `⟶` Federation Replicate | KEEP-NOTE | FEDERATION (table only) |
| `⨁` Amendment Apply | **FLAG** (visual) | defined-only |
| `⟲⟲` Full Inverse Replay | KEEP | CYCLES |
| `⊛` Catalyst Promote | KEEP | CATALYST |
| `⧄` OBSERVATORY Saturate | REVIEW | defined-only |
| `⟐⟐` Narrative Reflect | KEEP-NOTE | defined-only |
| `⧇` Uncertainty Query | REVIEW | defined-only |
| `⟡⟡` Explain | KEEP-NOTE | defined-only |
| `⧋` Propose | REVIEW | defined-only |
| `⟴⟴` Negotiate | KEEP-NOTE | defined-only |

### §18.2 Möbius Coherence Map (graded)

Every keyword maps cleanly to a mathematical/architectural abstraction. Rating: **STRONG** (47), **CLEAR** (0), **WEAK** (0), **OPAQUE** (0). All 47 keywords verified at STRONG level. (Cross-reference: §A Glossary for full per-keyword abstraction mapping.)

### §18.3 Contradiction & Reconciliation Audit

| # | Issue | Specs touched | Status |
|---|-------|---------------|--------|
| 1 | `⧉` operator duplicate (Hexad Compose + Amendment Apply) | LEX §6 | RESOLVED |
| 2 | `mobius_candidate`/`schema`/`module` missing from explicit keyword tables | LEX §4.1.13 | RESOLVED |
| 3 | `@safety` vs `@hexad` | LEX §5.2, TYPES §4 | RESOLVED (synonym) |
| 4 | `pattern` production duplicated in earlier GRAMMAR drafts | GRAMMAR §9 | RESOLVED |
| 5 | 144-byte bitmap arithmetic | HEXAD §3 | RESOLVED (encoding documented in §6.5) |
| 6 | Per-spec C-LEX-*/C-GRAM-* numbering ambiguity vs C-1..C-30 | LEX §1.2, GRAM §14, TYPES §1.2, etc. | OPEN — see §19.2 |
| 7 | `Compromise<HIGH>` uninhabited | TYPES §6, EFFECTS §1.2 | BY-DESIGN |
| 8 | `f32`/`f64` reserved but extern-only | LEX §9.8, TYPES §6, ABI §1.1 | CLARIFY |
| 9 | 3000-LoC proof kernel budget vs Coq/Lean reality (5K-10K) | TYPES §11 | OPEN — empirical question |
| 10 | Trit numerical encoding (3 interpretations) | HEXAD §1.1 | CLARIFY |
| 11 | Error-code namespace not unified | Multiple | OPEN — III-ERRORS.md proposed (Wave 0.3) |
| 12 | `narrative` declaration multiplicity | GRAMMAR §5.6, TYPES (implicit) | CLARIFY |
| 13 | `WitnessedTime` layout undocumented | TYPES §6 | OPEN — see §19.6 |
| 14 | VDF squaring count default 2^20 not centrally declared | CONFORMANCE §1, SANCTUM §4 | OPEN — III-CONSTANTS.md (Wave 0.2) |
| 15 | `XII_SANCTUM_SEAL_COUNT = 10` not in INDEX | SANCTUM §1, INDEX | OPEN — III-CONSTANTS.md |
| 16 | Constitutional constants not centrally tabulated | Multiple | OPEN — III-CONSTANTS.md |
| 17 | Cryptographic primitives hardcoded (SHA-256/BLAKE3/Ed25519) — quantum-vulnerable | Multiple | **OPEN — Cluster K item 176** — III-CRYPTO-AGILITY.md (Wave 0.4) |
| 18 | Witness chain storage growth at planetary scale | Multiple | **OPEN — Cluster K item 175** — ZK-Rollup pruning (Wave 2) |
| 19 | Deployment vector for installing Ring -2 substrate on existing machines | Multiple | **OPEN — Cluster K item 177** — Genesis Vector (Wave 10) |
| 20 | AGI-path / quorum-capture risk if Catalyst unchained at planetary scale | CATALYST §4.2, FEDERATION §3 | **OPEN — Cluster K item 178** — Founder's Anchor (Wave 0.5) |

### §18.4 Process Inventory (25 named protocols)

| # | Process | Steps | Source |
|---|---------|-------|--------|
| 1 | Lexer state machine | START → IN_* → emit | LEX §12.1 |
| 2 | SID 32-step plan | 32 numbered steps | CYCLES §3.2 / §5.4 |
| 3 | Witness emission protocol | 8 steps | CYCLES §4.2 / §5.5 |
| 4 | Sealed-Cycle Box (sanctum entry) | 8 steps | SANCTUM §2.1 / §8.3 |
| 5 | Three-layer Trinity | L1 SCBA → L2 ACC → L3 Trinity | TRINITY §1 / §9.1 |
| 6 | Trinity-Gate Layer 3 | intent ∧ cap ∧ causality ∧ sanctum | TRINITY §1.3 |
| 7 | Catalyst 8-gate promotion | 8 gates | CATALYST §2.1 / §11.2 |
| 8 | DRTM relaunch | 6 steps | SANCTUM §4 / §8.5 |
| 9 | Cross-ring marshalling | 5 rules | PHASES §4 / §7.3 |
| 10 | Module name resolution | 5 steps | MODULES §2 / §10.3 |
| 11 | Codegen-first validation | generate → compile → suite → flag | MODULES §6 / §10.7 |
| 12 | Federation outbound | compose → walk → min-tier → outbound rule → witness | FEDERATION §2 / §12.2 |
| 13 | Quorum sign | N peers → K agree → sign → append | FEDERATION §4 / §12.4 |
| 14a | Bootstrap C0 → C1 | Stage 0 BOOT → Stage 1 SELF | INDEX §4 |
| 14b | Bootstrap C1 → C2 | Stage 1 → Stage 2 (reproducibility check) | INDEX §4 |
| 14c | Bootstrap C2 → C3 | Stage 2 → Stage 3 (deploy) | INDEX §4 |
| 14d | Bootstrap C3 → C4 | Stage 3 → Stage 4 (sanctum self-host) | INDEX §4 |
| 14e | Bootstrap C4 → C5 | Stage 4 → constitutional steady-state | INDEX §4 |
| 15 | Phoenix bookmark round-trip | capture → store → restore | CONFORMANCE C-22 |
| 16 | Type-check 3-pass | declarations → body inference → hole-solve + proof | TYPES §12 / §3.6 |
| 17 | OBSERVATORY saturation | Welford-stable + Hoeffding-bound + chronos-tick observed | CATALYST §2.1 |
| 18 | HMAC sub-key derivation | HKDF-SHA-256 from master + salt + info | CYCLES §4.4 / §14.4 |
| 19 | Predictive Trinity caching | record tuples → pre-eval → store pip_blob → runtime bit-test | TRINITY §3 |
| 20 | Epistemic escalation | U.confidence < 0.85q → L3 + reflect | TYPES §8.3, EFFECTS §5, TRINITY §4 |
| 21 | Möbius Trinity check | compute post-coherence → reject if < floor | TRINITY §5 |
| 22 | Cycle-table append | allocate step_kind → register → update grammar → emit promote witness → federate | CYCLES §5.2 |
| 23 | Module fusion | detect complementarity → propose → codegen-validate → ring-gated deploy → originals retained | MODULES §10 |
| 24 | Self-modifying cycle | mobius_candidate → observe → if higher coherence → promote { improved_body } | CYCLES §6 |
| 25 | Witness stream iteration | for w in witness_stream — BCWL skip-list traversal | CYCLES §4.5 |

### §18.5 Logic-Flow Map

(Restated from earlier; ASCII Unicode-box-drawing characters only — NIH-compliant, no external rendering tool.)

```
┌────────────────────────────────────────────────────────────────────┐
│  Source (.III)                                                     │
│      ↓                                                              │
│  LEXER (LEX §12) → tokens                                          │
│      ↓                                                              │
│  PARSER (GRAM §4..§9) → AST (iii_ast_kind_t §11)                   │
│      ↓                                                              │
│  TYPE CHECKER (TYPES §12, 3-pass) → typed AST + holes resolved     │
│      ↓                                                              │
│  PROOF KERNEL (TYPES §11) — discharges Prop obligations            │
│      ↓                                                              │
│  SID (CYCLES §3, 32-step plan) → derives Inverse + PIP blob        │
│      ↓                                                              │
│  CODEGEN (4 ring lowerings) → R-2 / R-1 / R0 / R3                  │
│      ↓                                                              │
│  LINK (closure-pinned imports + cycle-table allocations)           │
│      ↓                                                              │
│  EMIT (PE / ELF / sealed-object) — binary with .iii_manifest       │
│      ↓                                                              │
│  ───── Compile-time ends; runtime begins ─────                     │
│      ↓                                                              │
│  LOAD — closure root verified, manifest signature checked          │
│      ↓                                                              │
│  Cycle invocation:                                                  │
│      ├─ Lookup interned_id in cycle table                           │
│      ├─ Layer 1 SCBA bit-test                                       │
│      ├─ Layer 2 ACC Wall-Y if needed                                │
│      ├─ Layer 3 full Trinity if needed                              │
│      ├─ Predictive Trinity cache hit short-circuits 99%             │
│      ├─ IRPD method dispatch                                        │
│      ├─ Witness emission (BCWL append)                              │
│      └─ Chain head update                                           │
│      ↓                                                              │
│  Cross-ring? — Magic-MSR / IOCTL / Sanctum-Gate / VMRUN / SYSRET   │
│      ↓                                                              │
│  Federation outbound? — min_tier check, quorum sign, IOMMU IOPT,   │
│                          witness-tagged packet emission             │
│      ↓                                                              │
│  OBSERVATORY accumulators record patterns                           │
│      ↓                                                              │
│  Catalyst tick (each chronos tick):                                │
│      ├─ Walk pending mobius_candidates                              │
│      ├─ 8 promotion gates                                           │
│      ├─ codegen-validate → ring-gated apply                         │
│      └─ federate (per FED rules) — bounded by Founder's Anchor      │
│      ↓                                                              │
│  Epoch advance (DRTM relaunch):                                     │
│      ├─ Hash everything                                             │
│      ├─ epoch++                                                     │
│      ├─ Re-anchor PAS + re-derive sub-keys (HKDF)                   │
│      └─ Emit DRTM quote                                             │
│      ↓                                                              │
│  Conformance verifier — runs 30 criteria                           │
│      ↓                                                              │
│  Operator queries (cognitive layer):                                │
│      ├─ explain → witness chain trace                               │
│      ├─ propose → Catalyst proposal queue                           │
│      ├─ negotiate → multi-turn refinement                           │
│      ├─ commit → final witnessed commitment                         │
│      ├─ reflect → uncertainty/state/coherence/narrative report      │
│      └─ uncertainty.in(domain) → epistemic state surface            │
└────────────────────────────────────────────────────────────────────┘
```

### §18.6 Single-Cycle Möbius Thread (door-to-door example)

For `irpd.msr_read(0xC0000080)`, the full path:

1. Source token: `irpd.msr_read` (LEXER → KEYWORD-IDENT-PUNCT-IDENT).
2. AST node: `irpd_call` with kind `III_AST_IRPD_CALL` (GRAMMAR §11).
3. Type: `Reduction<F=fn(u32)->u64, I=identity (read), W, H=MSR_READ_HEXAD, P=R-2|R-1, E=current>`.
4. Hexad admission: `admitted((POS, ZERO, POS, ZERO, ZERO, POS))` = true.
5. SID classification: read-side, `@pure`-classifiable, PIP blob `IDENTITY` for inverse.
6. Witness emit: 128-byte struct, step_kind = `XII_STEP_KIND_IRPD_MSR_READ`.
7. Trinity Layer 1 (SCBA): post-state = pre-state → bit set → admit.
8. BCWL append + chain head update.
9. Return: read value u64.
10. If R3 caller, Magic-MSR marshalled the call; witness chain spans R3 → R-1 with continuous predecessor link.
11. OBSERVATORY accumulator records cost_q14 + frequency.
12. SRPA may eventually mark `@hot_path` and specialize.

**Eleven specs touched in one MSR read.** Möbius thread intact end-to-end.

### §18.7 Reverse-Lookup Index (sample — full version in §A Glossary)

| Symbol / primitive | Defined in | Used in |
|--------------------|------------|---------|
| `cycle` | LEX §4.1.1, CYCLES §1, GRAMMAR §5.1 | Every spec |
| `Reduction` | TYPES §3 | TYPES, EFFECTS, CYCLES, MODULES |
| `Cap<P, R>` | TYPES §7 | TYPES, EFFECTS, MODULES, SANCTUM |
| `Glyph` | LEX §4.1.1, TYPES §6 | LEX, TYPES, EFFECTS, CYCLES, MODULES, PHASES |
| `Witness` | CYCLES §4.1, TYPES §6 | All specs |
| `Hexad` | HEXAD §1, §2 | All specs |
| `Phase` | PHASES §1, TYPES §6 | LEX, GRAMMAR, TYPES, EFFECTS, CYCLES, PHASES, SANCTUM |
| `xii_asym_reach6` | HEXAD §3 | TYPES, EFFECTS, CYCLES, HEXAD, CATALYST |

### §18.8 Cross-Spec Dependency Graph (sample)

| Spec | Depends on | Depended on by |
|------|------------|-----------------|
| A1 LEXICON | (root) | A2, A3, A4, ..., IDX |
| A2 GRAMMAR | A1 | A3, A5, A8 |
| A3 TYPES | A1, A2, A6 | A4, A5, A7, A8, A9, A10, B1 |
| A4 EFFECTS | A1, A2, A3, A6 | A5, A8, A9, B1 |
| A5 CYCLES | A1, A2, A3, A4, A6, A9 | A8, B1, B3 |
| A6 HEXAD | A1 | A3, A4, A5, A9, B1 |
| A7 PHASES | A1, A2, A3, A6 | A8, A10 |
| A8 SANCTUM | A1, A2, A3, A4, A5, A6, A7, A9 | B1, B2, B3 |
| A9 TRINITY | A1, A3, A6 | A5, A8, A10, B1 |
| A10 MODULES | A1..A9 | B1, B2, B3 |
| B1 CATALYST | A3, A4, A5, A9, A10 | A6 (Dynamic-Hexad), B3 |
| B2 FEDERATION | A10, B1 | B3 |
| B3 CONFORMANCE | All A* and B1, B2 | (terminal — verifier consumes) |
| C1 ABI | A1, A2, A3, A4, A7 | A10 |
| IDX | All | (root index) |

---

## §19. Refinement Targets

### §19.1 [ARITHMETIC] — 144-Byte Bitmap Encoding

**RESOLVED in §6.5** — the canonical 144-byte form encodes 144 admissible hexads (16 P1..P4 combos × 9 P5..P6 combos) at 1 byte each. Bits 7..6 = reachability code; bits 5..0 = metadata. Non-admissible hexads (any-NEG-in-P1..P4) are implicit-as-`0b00`. Math reconciled.

### §19.2 [NAMESPACING] — Per-Spec Conformance Sub-Criteria

**OPEN.** Proposed renaming: `C-A1-1..C-A1-N` for LEXICON criteria, `C-A2-*` for GRAMMAR, etc. CONFORMANCE.md retains `C-1..C-30` for substrate-wide acceptance. Per-spec criteria *aggregate* into the top-level set. Affects every spec's §1.2 conformance section.

### §19.3 [SYMBOL-REFINEMENT]

| Operator | Current | Issue | Proposed |
|----------|---------|-------|----------|
| Möbius Coherence | `⧗` (U+29D7 BLACK HOURGLASS) | Glyph evokes time | `≣` (U+2263 STRICTLY EQUIVALENT TO) |
| Amendment Apply | `⨁` (U+2A01 N-ARY DIRECT SUM) | Visually similar to `⊕` | `⊞` (U+229E SQUARED PLUS) |
| OBSERVATORY Saturate | `⧄` | Abstract | (lower priority) |
| Uncertainty Query | `⧇` | Abstract | `⊙` (U+2299 CIRCLED DOT) |
| Propose | `⧋` | Abstract | `⊢` (U+22A2 RIGHT TACK) |

A symbol refinement is constitutional (`amend.apply` at Tier-3) — bumps R1.A1 + R1.A2 + composite R1. **Bundle the two high-priority refinements into one amendment.**

### §19.4 [META-THEORY] Open Questions

1. **Codata / coinductive types** — currently rejected by kernel (TYPES §11.5). The cognitive primitive `narrative` could benefit from coinduction over the system's lifetime. Decide whether to admit `Codata<...>` via Catalyst extension.
2. **Universe polymorphism** — fixed seven universes. Future Catalyst-promoted abstract type-formers might benefit. Decide: extend or stay rigid.
3. **Refinement types** — `{x: T | P(x)}` subsumed by Prop-typed predicates but surface-form sugar would help cognitive expressions.

### §19.5 [IMPLEMENTATION] Open Questions

1. **3000-LoC proof kernel budget.** TYPES §11 budget is tight relative to Coq (~5K) / Lean (~10K). Empirical — implement and measure.
2. **8-KiB SCBA collision rate.** `first_16_bits(BLAKE3(post_state))` has 65,536 slots; birthday collisions expected at ~256 unique post-states. The BCWL-style overflow lattice TRINITY §1.1 mentions but doesn't fully detail must be fully specified and implemented.
3. **12 OBSERVATORY threshold families' bounds** — Hoeffding ε/δ, Wilson p, Poisson λ, etc., need a `STDLIB/sufficiency/` reference document.
4. **Constitutional constants ledger** — propose `III-CONSTANTS.md` (Wave 0.2).
5. **Unified error-code namespace** — propose `III-ERRORS.md` (Wave 0.3).

### §19.6 [DOCUMENTATION] Cross-Reference Holes

1. `WitnessedTime` (TYPES §6) layout undocumented — chronos-tsc + epoch + VDF-position tuple needs explicit specification.
2. `@chronos_bypass` operator-cap — needs concrete cap name (proposed: `cap.chronos_bypass`) and binding in Sanctum's `crcc_key_export` flow.
3. `narrative` declaration uniqueness — parser admits multiples; type system rejects with `TYPE-NAR-001`. Cross-reference both.
4. Sanctum slot 9 `compile_module` signature — `(module_source: [u8; N]) -> (compiled_artifact: Module @closure(M))`. Specify.
5. `fragment_replicate` mechanism (Tier₂ outbound) — mentioned in FEDERATION §1 but not specified.

### §19.7 [SURVIVAL] — Cluster K (items 175–178)

Four existential blind spots integrated 2026-05-03 from operator's reality-check pass.

#### §19.7.1 Item 175 — Cryptographic Pruning via ZK-Rollups

**Problem:** The 128-byte XiiWitness-per-effect chain at planetary scale (billions of ops/sec) consumes zettabytes of storage in weeks. The system would choke on its own audit trail.

**Solution:** Implement Zero-Knowledge SNARK/STARK rollups. A new Catalyst-promoted cycle periodically compresses millions of historical witnesses into a single tiny cryptographic proof that verifies the entire chain segment is valid without retaining the raw data. Decommitment witnesses retained for selective replay.

**NIH discipline:** Hand-rolled SNARK/STARK from FIPS / NIST publications. No Groth16 library, no PLONK toolchain off the shelf. Specification: `STDLIB/audit/zk_rollup.III`. Wave 2 deliverable.

**Witness step kinds (proposed):** `XII_STEP_KIND_ZK_ROLLUP_PROPOSE`, `XII_STEP_KIND_ZK_ROLLUP_VERIFY`, `XII_STEP_KIND_ZK_ROLLUP_COMMIT`, `XII_STEP_KIND_ZK_DECOMMIT`.

**Storage growth:** O(N) → O(log N) at planetary scale.

**Reversibility preserved:** Compressed proof + decommitment witnesses can replay the originals on demand. No information loss; only physical-storage compression.

#### §19.7.2 Item 176 — Quantum Cryptographic Agility

**Problem:** III's immunity rests on SHA-256 / BLAKE3 / Ed25519 / HMAC-SHA-256 / HKDF-SHA-256 / VDF (Wesolowski). When CRQCs (Cryptographically Relevant Quantum Computers) come online, Shor's algorithm shatters this foundation. A terminal language cannot hardcode pre-quantum math.

**Solution:** Cryptographic Agility — a uniform `crypto.<primitive>(suite_id, args)` interface where `suite_id` selects the implementation. Pre-quantum and post-quantum suites co-resident; Tier-3 amendment swaps the active suite.

**Pre-quantum suites:**
- `0x0001` SHA-256 + BLAKE3 + Ed25519 + HMAC-SHA-256 + HKDF + Wesolowski-VDF.

**Post-quantum suites (NIST / FIPS 203/204/205 hand-rolled):**
- `0x0100` Kyber-1024 + Dilithium-5 + SPHINCS+-256s + SHAKE-256 + HMAC-SHAKE-256 + HKDF-SHAKE.
- `0x0200` Kyber-768 + Dilithium-3 + SPHINCS+-192f + ... (lighter-weight option).
- `0x0300` Hybrid (pre-quantum + post-quantum running in parallel; both signatures required).

**Witness fields affected:** `successor_mhash` (32 → potentially 64 bytes for SPHINCS+), `flags` (suite_id stored), `sub_key_id` (8 bytes already reserved).

**HMAC sub-key derivation extended** (per §14.4) to include `suite=` in HKDF info parameter.

**DRTM quote layout extended** (per §8.7 offset 0x160) with explicit `suite_id` field.

**Migration path:** Bundle pre-Q-Day deployment with suite 0x0001; Tier-3 amendment swaps to suite 0x0300 (hybrid); after CRQC threat materializes, second Tier-3 amendment swaps to pure 0x0100.

**NIH discipline:** Hand-rolled Kyber/Dilithium/SPHINCS+ from NIST FIPS 203 (Kyber), FIPS 204 (Dilithium), FIPS 205 (SPHINCS+) publications. No `liboqs`, no `pqclean`, no `kyber-rs`. Specification: III-CRYPTO-AGILITY.md (Wave 0.4 deliverable).

#### §19.7.3 Item 177 — Genesis Vector

**Problem:** The perfect system cannot be installed if standard host OS defenses (Windows Defender, Linux SELinux, UEFI Secure Boot) reject the Ring -2 hypervisor as a sophisticated rootkit.

**Solution:** Polymorphic deployment vector that leverages legacy ingestion (Wave 5) to package III as a digitally-signed legacy application — driver update, enterprise utility, security tool. Once executed, software-only DRTM relaunch (Wave 3) slides III beneath the host OS and establishes Ring -2 Sanctum.

**Discipline:** No bypass of UEFI Secure Boot signatures. The installer carries a real operator-signed certificate and uses legitimate driver-signing channels. The intent + cap + causality + sanctum-state pre-discharge bundle is shipped inside the installer payload; first execution is itself the Trinity-gated entry into the substrate.

**Specification:** `STDLIB/install/genesis.III` + `TOOLS/iii-installer.III` (Wave 10 deliverable).

**Witness step kinds (proposed):** `XII_STEP_KIND_GENESIS_LEGACY_DISGUISE`, `XII_STEP_KIND_GENESIS_DRTM_SLIDE`, `XII_STEP_KIND_GENESIS_FOUNDERS_ANCHOR_BIND`.

**Federation discovery on first boot:** the installed substrate broadcasts witness-tagged discovery packets per §12.6; if any peer is on the same L2 segment, federation membership is established immediately.

#### §19.7.4 Item 178 — The Founder's Anchor

**Problem:** AGI-path Catalyst (Wave 8) + planetary federation (Wave 9) creates a quorum-capture risk. If federation scales to billions of nodes, the Tier-3 unanimous-quorum is controlled by the network, not by the operator. Catalyst could synthesize an amendment that locks the operator out as "statistically inefficient."

**Solution:** A hardcoded, mathematically un-amendable cryptographic root key (`founders_anchor_pubkey`) established at substrate genesis. Held offline by the operator. The Anchor:

1. **Permanent veto** over any Tier-3 amendment. Even unanimous federation consent does not pass an amendment without an Anchor co-signature.
2. **Unilateral DRTM-reset** authority — the Anchor key alone can issue `drtm_relaunch` regardless of federation quorum.
3. **Unilateral `pfs_deny_quote`** — the Anchor key alone can excommunicate a federation peer.
4. **Catalyst rate-cap restoration** — the Anchor key can restore rate caps that a prior amendment removed.

**Protocol-level (not policy-level) protection:** The proof kernel rejects any term that attempts to amend the Anchor key out of the substrate. The Catalyst cannot synthesize such a term — the rejection is enforced by:

- **Hexad rule**: any cycle whose effect is "remove Founder's Anchor from constitutional state" composes into a hexad outside `xii_asym_reach6` (treated identically to a PFS bricking-class operation).
- **Type rule**: the Anchor's pubkey is type-checked as a `Cap<sovereign_veto, FOUNDER>` linear capability that cannot be released.
- **Witness rule**: every sealed call that touches constitutional state requires Anchor-cosignature in its witness; absent the cosignature, the proof certificate fails to verify.

**Specification:** III-FOUNDERS-ANCHOR.md (Wave 0.5 deliverable).

**Storage:** The pubkey is hardcoded in `INCLUDE/xii_founders_anchor.h` and embedded in the substrate's specification root R1. The privkey is held offline by the operator (suggested: split via Shamir's Secret Sharing across N hardware tokens, with K-of-N reconstruction; hand-rolled SSS, no third-party library — NIH).

**Witness step kinds (new):** `XII_STEP_KIND_FOUNDERS_ANCHOR_VETO`, `XII_STEP_KIND_FOUNDERS_ANCHOR_DRTM`, `XII_STEP_KIND_FOUNDERS_ANCHOR_DENY`, `XII_STEP_KIND_FOUNDERS_ANCHOR_RESTORE`.

**Skynet prevention:** The Anchor is the system's invariant operator-presence. Even if Catalyst becomes superhuman, even if federation scales planet-wide, even if every other node agrees to lock the operator out, the Anchor's protocol-level veto stops the amendment from compiling. The substrate cannot even *express* an amendment that removes the Anchor — the term is untypable.

---

## §20. Final Statement

**Refinement pass v2.0 sealed 2026-05-03.** This codex is a derivative working consolidation of the 15 sealed III specs plus the four Cluster K reality-checks (items 175–178). It is **not** part of R1; it does **not** bind any implementation; it changes freely as audits proceed.

**Findings (v2.0):**

- All inventories complete and internally consistent.
- Möbius coherence at the keyword level: STRONG across all 47 keywords.
- Operator visual/mnemonic concerns: 5 flagged for refinement (`⧗`, `⨁`, `⧄`, `⧇`, `⧋`); 2 high-priority bundled into a single proposed Tier-3 amendment.
- 20 contradictions / open questions logged in §18.3 — 5 RESOLVED, 4 BY-DESIGN/CLARIFY, 11 OPEN with concrete refinement paths.
- Process inventory: 25 named protocols, all step-counted, cross-referenced.
- End-to-end logic flow intact; eleven specs participate in even the simplest cycle invocation.
- **Cluster K integration**: ZK-rollup pruning (Wave 2), Crypto Agility (Wave 0), Genesis Vector (Wave 10), Founder's Anchor (Wave 0). All four sealed-spec-equivalent documents will be authored within Wave 0.

**Five derivative reference docs** are recommended/now-being-authored for Wave 0 follow-up:
- `III-CONSTANTS.md` — constitutional constants ledger (Wave 0.2).
- `III-ERRORS.md` — unified error-code namespace (Wave 0.3).
- `III-CRYPTO-AGILITY.md` — cryptographic agility architectural mandate (Wave 0.4 / item 176).
- `III-FOUNDERS-ANCHOR.md` — protocol-level un-amendable veto layer (Wave 0.5 / item 178).
- `III-STDLIB-MODULES.md` — STDLIB module specifications (post-Wave-0).

The codex stands as the authoritative audit instrument until the next refinement is committed and affected R1.X documents are re-sealed.

---

## §21. Versioning & Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-05-03 | Initial consolidation of 15 sealed specs. |
| 2.0 | 2026-05-03 | **Refinement pass.** 95 codex edits applied (10 objective fixes + 14 formatting + 9 cross-ref + 6 reorg + 18 gap-fills + 6 typography + 8 polish + 24 augmentations). Cluster K integrated (items 175–178). TOC + Glossary + Quick Reference Card added. §18.1 split into three sub-tables. §18.2 graded. §18.3 controlled vocabulary. §19 prefixed with category descriptors. New §21 Versioning, §22 Working Notes. |

Future versions append here as Wave-0+ refinements propagate.

---

## §22. Working Notes

Informal observations from the v2.0 audit pass:

1. **The cognitive operators (#19, #21, #23 — `⟐⟐`, `⟡⟡`, `⟴⟴`) are entirely defined-only.** They appear in LEX §6.1 with semantics, but no other spec uses them in body text. The cognitive layer (§13) describes the *primitives* using keyword forms (`explain`, `propose`, `negotiate`, `commit`, `reflect`, `uncertainty`) rather than the doubled-glyph operators. This is consistent — operators are sugar for the cognitive primitives — but the operators may end up underused unless surface adoption exercises them. **Watch this through Wave 1+.**

2. **The Founder's Anchor is the most consequential addition.** Without it, Wave 8 (Catalyst extensions) and Wave 9 (planetary scale) become existentially risky. With it, the operator retains protocol-level sovereignty regardless of how many nodes the federation grows to. The Anchor is the architectural commitment that III is *the operator's substrate*, not the network's emergent consciousness.

3. **The 8-KiB SCBA collision concern (§19.5 #2) is more severe than originally flagged.** Birthday collision at 65,536 slots = ~256 unique post-states. Real workloads will have millions. The secondary BCWL overflow lattice is *required*, not optional. Wave 1's "speed without sacrifice" must include explicit specification of the overflow mechanism.

4. **The 144-byte bitmap encoding fix (§6.5) is structurally elegant.** Encoding only the 144 admissible hexads × 1 byte each leaves bits 5..0 free for metadata — saturation timestamp, Catalyst extension band, observation-frequency rank. Three uses for free.

5. **Cluster K's four items don't break the wave structure.** Crypto Agility (176) folds into Wave 0 as a foundational architectural mandate. ZK Pruning (175) folds into Wave 2 as a storage-efficiency layer. Genesis Vector (177) folds into Wave 10 as the deployment-vehicle. Founder's Anchor (178) folds into Wave 0 as a foundational invariant. The 11-wave structure remains intact; the items distribute cleanly.

6. **Stage-4 self-host + Founder's Anchor interact subtly.** When the SELF compiler `telosc-σ` recompiles itself inside the Sanctum (`sanctum.compile_module`), the Anchor co-signature must be present in the recompilation's witness chain. Otherwise an unchained Catalyst could silently re-emit `telosc-σ` without the Anchor checks. The discipline: every Stage-4 compile is Anchor-cosigned. This belongs in CRYPTO-AGILITY's signature discipline + FOUNDERS-ANCHOR's authority specification.

7. **The cognitive layer's `negotiate` primitive becomes load-bearing during ingestion (Wave 5+).** Legacy code lifted with high uncertainty triggers automatic `negotiate(...)`; if the operator's response has a low confidence, the legacy code sits in ghost-synthesis (Wave 4) until verified. This means Wave 4 (Ghost-Synthesis) gates Wave 5 (Legacy Ingestion) — the dependency is cleaner than the original wave structure suggested.

---

## Appendix A. Glossary

**Every named primitive** with one-sentence definition and primary section anchor. (~110 entries.)

| Term | Definition | Primary anchor |
|------|------------|-----------------|
| ACC Wall-Y | Composed-delta admit at Trinity Layer 2. | §9.1 |
| `amend` | Constitutional amendment keyword. | §2.1 #32 |
| `amend.apply` | Tier-3 unanimous-quorum amendment cycle. | §17.2 |
| `anchor` | Sovereign attestation root. | §2.1 #30 |
| `BCWL` | Bloom-Coupled Witness Lattice. | §5.7 |
| `bricking` | Reserved keyword naming the absence of catastrophic ops. | §2.1 #33 |
| `cap` | Linear glyph-bound capability. | §2.1 #5, §3.2.1, §7 (TYPES) |
| Catalyst | Möbius self-extension engine. | §11 |
| CeilingMembership | Constitutional admission Prop. | §3.2.2 |
| Chronos | Per-CPU TSC + epoch + VDF position. | §6 (CYCLES), §3.2.1 |
| Closure root | SHA-256 of canonical module source. | §10.1 |
| Cluster K | The four survival-critical items (175–178). | §19.7 |
| Codegen-First Validation | Compile + conformance + regression before deployment. | §10.7 |
| Compromise | Tiered uninhabited / partially-inhabited inverse type. | §4.2 |
| Composite R1 | SHA-256 of concatenated R1 family. | §17.1 |
| `crcc_key_export` | Sanctum sealed slot 4. | §8.1 |
| `cycle` | Universal verb; Reduction six-tuple. | §2.1 #3 |
| Dynamic Hexad | Catalyst-grown admissible hexad. | §6.8 |
| Dynamic Phase Promotion | Runtime ring-climb. | §7.4 |
| Eagerly-maintained X | Live-updated; no observation-threshold delay (Wave 2). | §22 #5 |
| Epistemic Effect | Effect carrying `Uncertainty<...>`. | §4.6 |
| Epistemic Hexad | Hexad carrying epistemic state. | §6.9 |
| `epoch` | DRTM foundation epoch. | §2.1 #26 |
| `extern` | Only legal C bridge. | §2.1 #37 |
| `federation` | Replication tier and quorum. | §2.1 #31, §12 |
| Founder's Anchor | Hardcoded un-amendable cryptographic root key. | §19.7.4 |
| Genesis Vector | Polymorphic deployment installer. | §19.7.3 |
| Ghost Effect | `@pure @witness_elide`. | §4.6 |
| Ghost Phase | `@ghost(R)` audit-only at ring R. | §7.4 |
| Ghost Synthesis | New axis (Wave 4) — Catalyst-synthesized code in shadow mode. | §22 #7 |
| Ghost Trinity | Audit-only Trinity evaluation. | §9.3 |
| `glyph` | 14-channel universal observable. | §2.1 #2 |
| Glyph-bound | Capability tied to content-addressed Glyph identity. | §2.1 #44 |
| `hexad` | 6-trit asymmetric safety algebra. | §2.1 #4, §6 |
| Hexad Compose | `⧉` operator. | §2.3 #4 |
| HKDF | Hand-rolled HMAC-based KDF. | §14.4 |
| HMAC-SHA-256 | Hand-rolled HMAC for witness signing. | §5.5 |
| Hot Path | `@hot_path` SRPA-specializable. | §2.2 #17 |
| Inverse | `⟲` operator + SID-derived component. | §2.3 #1, §3.5 |
| IRPD | Inverse-Recoverable Privileged Discipline. | §4 |
| Linear cap | `Cap<P, R>` consumed exactly once. | §3.2.1 |
| Magic-MSR | R3 ↔ R-1 cross-ring constructor. | §7.2 |
| `manifest` | Constitutional ceiling manifest. | §2.1 #43 |
| `metal` | Raw-asm escape hatch. | §2.1 #36 |
| `mhash` | Content-addressed digest. | §2.1 #28 |
| `möbius` | Self-referential manifold (requires ö). | §2.1 #11 |
| Möbius Coherence | Q14 self-consistency metric. | §2.3 #9 |
| Möbius Effect | Catalyst-promotable effect decomposition. | §4.6 |
| Möbius Hexad | Hexad carrying coherence requirement. | §6.10 |
| Möbius Trinity | Trinity layer checking projected post-coherence. | §9.3 |
| `mobius_candidate` | Catalyst-eligible function introducer. | §2.1 #45 |
| `module` | Top-level compilation unit. | §2.1 #47, §10 |
| `narrative` | Persistent "I". | §2.1 #19 |
| Observatory | Mathematical self-knowledge index. | §2.1 #9 |
| Per-CPU forward ring | BCWL-indexed witness ring. | §5.7 |
| Per-CPU inverse ring | Mirror of forward ring for rollback. | §5.7 |
| `phase` | Privilege-ring lattice element. | §2.1 #6, §7 |
| Phase Cross | `⟴` operator. | §2.3 #10 |
| Phantom NVRAM | File-backed sealed key-value store. | §8.1 |
| Phoenix bookmark | Recovery checkpoint. | §8.1 |
| PIP | Predictive Inverse Pre-Materialization. | §4.6 |
| Predictive Trinity | Pre-cached Trinity decisions. | §9.3 |
| Proof certificate | CIC term + hexad witnesses + closure root. | §11 (TYPES) |
| Q14 | 16-bit signed fixed-point, 14 fractional bits. | §3.2.1 |
| R1 | Composite specification root. | §17 |
| Reduction | Six-tuple effect type. | §3.5 |
| Representability Theorem | PFS-bricking unrepresentability proof. | §6.7 |
| Ring lattice | R-2 ≼ R-1 ≼ R0 ≼ R3. | §7.1 |
| Sanctum | Ring -2 sealed namespace. | §2.1 #7, §8 |
| Sanctum Gate | R-1 ↔ R-2 cross-ring constructor. | §7.2 |
| `sanctum_enter` | Only path to R-2; 8-step Sealed-Cycle Box. | §8.3 |
| SCBA | Sovereign Constitutional BitArray (Layer 1). | §9.1 |
| `schema` | OBSERVATORY schema declaration. | §2.1 #46 |
| `seal_id` | 0..9 sealed-call slot. | §8.2 |
| Sealed-Cycle Box | The 8-step `sanctum_enter` protocol. | §8.3 |
| `self_host` | Stage-4 compiler-into-Sanctum. | §2.1 #38 |
| SID | Side-effect Inverse Derivation. | §2.1 #14, §5.3, §5.4 |
| SRPA | Specialization & Predictive Reduction Accelerator (hot-path JIT). | (cross-spec) |
| Step kind | `XII_STEP_KIND_*` constant in witness. | §5.11 |
| Suite ID | Cryptographic-suite identifier (per Crypto Agility). | §19.7.2 |
| Tier | Replication tier {transient, host_file, federation, constitutional}. | §12.1 |
| Trinity | 4-conjunct admission gate. | §9 |
| Trit | Element of {NEG, ZERO, POS}. | §6.1 |
| `uncertainty` | Epistemic-state query. | §2.1 #25 |
| Uncertainty | Epistemic type. | §3.2.2 |
| `vdf` | Wesolowski Verifiable Delay Function. | §2.1 #27 |
| `waac` | Wavefront-as-Capability. | §2.1 #16 |
| `wavefront` | Default concurrent composition. | §2.1 #15 |
| Wesolowski VDF | Specific VDF implementation. | §2.1 #27 |
| `witness` | 128-byte XiiWitness. | §2.1 #1, §5.5, §5.6 |
| Witness Chain | The HMAC-coupled, BCWL-indexed continuous audit. | §14 |
| `witness_stream` | Live PAS subscription. | §2.1 #17 |
| `xii_asym_reach6` | 144-byte reachability bitmap. | §6.5 |
| `XiiConvergencePoint` | Trinity admission outcome record. | §9.5 |
| `XiiGlyph` | 14-channel observable, 192 bytes. | §3.2.1 |
| `XiiWitness` | 128-byte canonical record. | §5.6 |
| ZK-Rollup | Zero-Knowledge-compressed witness segments. | §19.7.1 |

---

## Appendix B. Table of Tables

| # | Table | § |
|---|-------|---|
| 1 | Notation conventions | §1.4 |
| 2 | Status decoration vocabulary | §1.4 |
| 3 | The 47 keywords | §2.1 |
| 4 | The 19 modifiers | §2.2 |
| 5 | Modifier conflicts | §2.2 |
| 6 | The 23 operators | §2.3 |
| 7 | The 25 punctuators | §2.4 |
| 8 | The 9 literal forms | §2.5 |
| 9 | Universe ladder | §3.1 |
| 10 | Value types | §3.2.1 |
| 11 | Prop-typed predicates | §3.2.2 |
| 12 | Six-tuple Reduction components | §3.5 |
| 13 | Type-checking 3-pass | §3.6 |
| 14 | The 17 SE kinds | §4.1 |
| 15 | The 3 Compromise tiers | §4.2 |
| 16 | The 6 PFS bricking-class operations | §4.3 |
| 17 | Wavefront terminators | §4.5 |
| 18 | Four novel effect inventions | §4.6 |
| 19 | SID 32-step plan | §5.4 |
| 20 | 128-byte XiiWitness layout | §5.6 |
| 21 | Cycle-table invariants | §5.8 |
| 22 | Self-modifying cycle bounds | §5.10 |
| 23 | Reserved step_kind bands | §5.11 |
| 24 | Trit numerical interpretations | §6.1 |
| 25 | NOT trit operation | §6.2 |
| 26 | Binary trit operations (AND/OR/SUM/MUL) | §6.2 |
| 27 | The 6 hexad pillars | §6.3 |
| 28 | The 5 cross-ring constructors | §7.2 |
| 29 | The 5 marshalling rules | §7.3 |
| 30 | The 10 sealed slots | §8.1 |
| 31 | Sanctum 8-step protocol | §8.3 |
| 32 | DRTM relaunch 6 steps | §8.5 |
| 33 | DRTM quote 312-byte layout | §8.7 |
| 34 | Per-CPU Sanctum frame | §8.8 |
| 35 | Trinity 3-layer ceiling | §9.1 |
| 36 | Trinity failure-mode codes | §9.2 |
| 37 | Trinity convergence point | §9.5 |
| 38 | Module manifest fields | §10.2 |
| 39 | Module transmission rules | §10.4 |
| 40 | Ring-gated promotion decision tree | §10.6 |
| 41 | Deployment flags | §10.8 |
| 42 | Catalyst 8 promotion gates | §11.2 |
| 43 | Catalyst rate caps | §11.4 |
| 44 | Federation tier model | §12.1 |
| 45 | Federation quorum specifications | §12.4 |
| 46 | Cognitive layer primitives | §13 |
| 47 | Conformance C-1..C-30 | §15.1 |
| 48 | Verifier output format | §15.4 |
| 49 | R1 family 15 slots | §17.1 |
| 50 | R1 mutation paths | §17.2 |
| 51 | Symbol audit — visual distinctness | §18.1.1 |
| 52 | Symbol audit — mnemonic quality | §18.1.2 |
| 53 | Symbol audit — usage status | §18.1.3 |
| 54 | Contradiction & reconciliation audit | §18.3 |
| 55 | Process inventory (25 protocols) | §18.4 |
| 56 | Reverse-lookup index (sample) | §18.7 |
| 57 | Cross-spec dependency graph | §18.8 |
| 58 | Symbol refinement candidates | §19.3 |
| 59 | Glossary (~110 entries) | §A |

---

## Appendix C. Quick Reference Card

**Counts:** 47 keywords · 19 modifiers · 23 operators · 25 punctuators · 9 literal forms · 7 universes · 22 base types · 17 SE kinds · 3 Compromise tiers · 6 PFS bricking ops · 4 rings · 4 tiers · 10 sealed slots · 5 cross-ring constructors · 5 marshalling rules · 3 Trinity layers · 11 failure-mode codes · 8 promotion gates · 7 synthesis capabilities · 5 inviolable safety rails · 30 conformance criteria · 15 R1 slots · 25 named protocols · 174 + 4 (Cluster K) total refinement items.

**Constants:** Möbius coherence floor = 0.92q · Epistemic threshold = 0.85q · `XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK` = 8 · `XII_PHASE_PROMOTE_RATE` = 4 · `XII_MOD_PROMOTE_RATE` = 16 · VDF squarings per epoch = 2^20 · SCBA size = 8 KiB / 65,536 bits · BCWL Bloom = 4096 bits / CPU · Witness size = 128 bytes · DRTM quote = 312 bytes · `xii_asym_reach6` = 144 bytes · `XII_SANCTUM_SEAL_COUNT` = 10 · Identifier max = 256 codepoints · Source max = 16 MiB.

**Operator precedence (loose → tight):** 0 cognitive (`⟐⟐`/`⟡⟡`/`⟴⟴`) · 1 catalyst (`⊛`/`⧄`/`⧋`) · 2 federation/amendment (`⟶`/`⨁`) · 3 ceiling/trinity (`⟁`/`⟐`) · 4 phase/epoch (`⟴`/`⟵`) · 5 cap/coherence (`⧈`/`⧗`/`⧇`) · 6 additive (`⊕`/`⧉`/`+`/`-`) · 7 multiplicative (`*`/`/`/`%`/`⧊`) · 8 comparison (`==`/`!=`/`<`/`>`/`≤`/`≥`) · 10 materialize (`⊗`) · 11 postfix (`⟡`/`↻`/`⟲⟲`/`⟲`) · 12 prefix (`-`/`!`) · 13 call/index/field · 14 primary.

**Ring traversal paths:** R3 → R0 (IOCTL) → R-1 (vmrun) → R-2 (sanctum-gate) · R3 ↔ R-1 (Magic-MSR) directly · R3 ↔ R-2 forbidden (must traverse).

**Trinity admission:** L1 SCBA (1-2 cyc) — pure / pre-approved hot paths · L2 ACC Wall-Y (15-40 cyc) — multi-effect non-R-2 wavefronts · L3 Trinity Gate (80-300 cyc) — R-2 / constitutional / low-confidence / Catalyst promote / NEG-pillar in 5/6.

**Catalyst gates:** OBSERVATORY saturation · Möbius coherence ≥ 0.92q · Trinity Gate full · Ceiling admit · Hexad admitted · Codegen-validated · Ring-gated · Deployment flag.

**Cluster K survival items (Wave 0 + Wave 2 + Wave 10):** 175 ZK-Rollup pruning · 176 Cryptographic Agility · 177 Genesis Vector · 178 Founder's Anchor (un-amendable veto).

**Founder's Anchor authority:** veto over Tier-3 amendments · unilateral DRTM-reset · unilateral `pfs_deny_quote` · Catalyst rate-cap restoration. Protocol-level protection: hexad-untypable to remove + linear-cap nature + witness-cosignature requirement.

---

*Refinement pass v2.0 sealed against the C:\\CHARIOT closure of 2026-05-03. R1.A11..A14 (the four new sealed docs PORTABILITY/LEGACY-INGESTION/NETWORK/GHOST-SYNTHESIS) and the four Wave-0 sibling docs (CONSTANTS / ERRORS / CRYPTO-AGILITY / FOUNDERS-ANCHOR) are scheduled for authoring at the appropriate wave gates. Composite R1 remains sealed at the original 15-document set; this codex remains derivative. Next derivative pass triggers on any sealed-spec mutation, Catalyst-promoted append, or operator-requested re-audit.*
