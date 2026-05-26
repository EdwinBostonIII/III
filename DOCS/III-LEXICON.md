# III-LEXICON.md — The Alphabet of III

**Document Identity:** A1 / The Lexicon
**Canonical Hash Slot:** R1.A1
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. This document binds the SELF compiler. Any deviation is a conformance failure (C-LEX-1 through C-LEX-SELF).
**Parent Architecture:** Language-as-Operating-System (Language-as-OS)
**Successor Plan:** A2 III-GRAMMAR.bnf, A3 III-TYPES.md, A4 III-EFFECTS.md, A5 III-CYCLES.md, A6 III-HEXAD.md, A7 III-PHASES.md, A8 III-SANCTUM.md, A9 III-TRINITY.md, A10 III-MODULES.md, B1 III-CATALYST.md, B2 III-FEDERATION.md, B3 III-CONFORMANCE.md, C1 III-ABI.md, IDX III-INDEX.md.

---

## §0. Preamble

III is not a language *for* an operating system.
III **is** the operating system, expressed as a single self-reinforcing, self-abstracting, witnessed manifold. The substrate is the language. The language is the substrate. Every keyword in this document names a primitive of sovereign computation; every modifier names a refinement of a type, an effect, or a cycle; every operator names an action over the witnessed reduction graph.

Two non-negotiable design constraints govern every entry below.

**Constraint I — Ambition without compromise.** Each symbol must feel as if carved from the sovereign calculus itself, not borrowed from the history of programming languages. III refuses to descend from C, refuses to inherit from ML, refuses to imitate Rust. Every symbol is justified against the architecture's own primitives: Möbius self-reference, the asymmetric ternary algebra, Ring -2 sanctum semantics, witnessed reductions, Catalyst-driven runtime extension, the Persistent Audit Spine, the constitutional ceiling, the OBSERVATORY of mathematical abstractions, the SRPA continuous self-audit, the Trinity admission manifold, federation tiers, and the cognitive layer.

**Constraint II — Unprecedentedness.** No symbol in this lexicon is reachable by any other language on Earth, because no other language has access to all of:

- A Ring -2 hardware sanctum it has not had to rewrite firmware to obtain.
- A content-addressed witness chain anchored by hardware-rooted DRTM with VDF-witnessed time.
- A 144-byte asymmetric ternary reachability bitmap (`xii_asym_reach6`) that makes catastrophic operations *structurally absent* from the algebra.
- An OBSERVATORY of statistically-saturated mathematical schemas indexing the system's own abstractions.
- A Möbius Catalyst that promotes new keywords by mathematical proof rather than committee vote.
- A phase-polymorphic compiler that lowers a single source to four privilege rings (R-2, R-1, R0, R3) with full type-level marshalling.
- A type system whose six-tuple `Reduction` unifies effect, safety, reversibility, provenance, privilege, and temporal identity into one first-class value.
- A cognitive layer (`narrative`, `explain`, `propose`, `negotiate`, `reflect`, `uncertainty`) expressed as language productions rather than library calls.

The alphabet is **deliberately small in surface area and infinite in depth**: a "puddle" you can hold in one hand, an "ocean" beneath. Forty-seven keywords; nineteen modifiers; twenty-three operators; a finite set of reserved punctuators; eight literal forms; three kinds of comments. Once the alphabet is mastered, every other programming language reads like a historical artifact — a toy from the age before computation became witnessed, reversible, self-extending, and sovereign.

This document is **the alphabet**. Every later III spec document builds on the symbols defined here. Without this document, the SELF compiler has no input alphabet; without the alphabet, no further specification is meaningful.

---

## §1. Conformance & Sealing

### §1.1 The Sealing Discipline

This document is **sealed against the C:\\CHARIOT closure of 2026-05-03**. Sealing means:

1. The set of keywords, modifiers, and operators defined in this document is **frozen** and may be extended *only* through the Möbius Catalyst pathway specified in §14 — not through pull requests, working groups, language committees, or any externally-administered revision process.
2. The canonical UTF-8 byte sequence of this document, after applying the canonicalization rules in §2.5, has a SHA-256 hash designated **R1.A1** which is embedded in every compiled module's closure root (see III-MODULES.md §1).
3. Two copies of this document differing only in trailing whitespace, line-ending convention, BOM presence, or comment punctuation must yield byte-identical R1.A1 hashes after canonicalization. Any change that alters R1.A1 forces a substrate-wide DRTM relaunch (see III-SANCTUM.md §4).

### §1.2 Conformance Criteria (Lexicon-Specific)

A toolchain is *III-lexical-conformant* iff it satisfies all of the following:

- **C-LEX-1.** It accepts every byte sequence that is a well-formed III source per §3 of this document.
- **C-LEX-2.** It rejects every byte sequence that is *not* a well-formed III source per §3, with a precise diagnostic naming the first offending byte offset and one of the canonical error codes in §12.3.
- **C-LEX-3.** It produces exactly one token of the canonical kind (per §3.1) for each lexeme; no extraneous tokens, no missing tokens, no merged tokens.
- **C-LEX-4.** It computes R1.A1 byte-deterministically and matches the canonical R1.A1 of any other conformant toolchain on the same canonical input.
- **C-LEX-5.** It refuses to lex any keyword, modifier, or operator not in the frozen set, except those that have been added by a witnessed Catalyst promotion per §14.
- **C-LEX-FROZEN.** The frozen set of 47 keywords, 19 modifiers, 23 operators, and the punctuator set in §7 is implemented with no additions, removals, or aliases (except those introduced by a witnessed Catalyst promotion).
- **C-LEX-NIH.** The lexer implementation depends on no external lexer-generator, no external regex library, and no external Unicode library outside the III project's own NIH crypto/string/normalization primitives (see §12.4).
- **C-LEX-SELF.** The SELF lexer (`SELF/lex.III`) tokenizes this document successfully and produces an mhash matching R1.A1.

These criteria are restated in III-CONFORMANCE.md §1 (C-1 through C-5) and form part of the substrate-wide acceptance contract.

### §1.3 The SELF Compiler Requirement

Once III reaches Stage 4 self-host (see III-SANCTUM.md §1, seal_id 9), the SELF compiler `telosc-σ` **must** parse the canonical text of this document using exactly the alphabet defined here. The SELF compiler's own source is written in III, and that source must lex against this very document — making the alphabet self-applying. If the SELF compiler's source cannot be lexed by an implementation of this document, the implementation is non-conformant.

### §1.4 The BOOT Compiler Requirement

The BOOT compiler `telosc-0` (hand-written C in `COMPILER/BOOT/lex.{h,c}`) is the bootstrap implementation of this lexicon. It must:

- Tokenize this document and produce R1.A1 byte-deterministically.
- Tokenize every SELF/*.III source produced during Stages 1–4.
- Refuse to accept any III source whose tokens fall outside the frozen alphabet — including refusing to accept Catalyst-promoted symbols at BOOT time (the Catalyst extension pathway is a runtime-only mechanism that requires a live OBSERVATORY and a live Catalyst, neither of which exists at BOOT).

---

## §2. Source Encoding

### §2.1 Character Encoding

III source is encoded in **UTF-8**. The lexer reads a sequence of Unicode codepoints, decoded via the canonical UTF-8 algorithm (RFC 3629, hand-rolled in `COMPILER/BOOT/utf8.{h,c}`). A source file is an ordered sequence of codepoints; sequences that are not valid UTF-8 are rejected with a diagnostic naming the first offending byte.

### §2.2 Byte-Order Mark

A byte-order mark (U+FEFF) is **forbidden** at the start of an III source file. Files beginning with the byte sequence `EF BB BF` are rejected with `LEX-ENC-001 BOM forbidden — III source is BOM-less UTF-8`.

### §2.3 Line Endings

The canonical line ending is **LF (U+000A) only**. CR (U+000D) is forbidden anywhere in the source, including as part of a CR-LF sequence. Files containing CR are rejected with `LEX-ENC-002 CR forbidden — III source is LF-only`.

### §2.4 Trailing Whitespace

Trailing whitespace on any line is forbidden. The lexer rejects the file with `LEX-ENC-003 trailing whitespace at line N` and refuses to compute R1.A1 over a non-canonical source. (This rule guarantees R1.A1 stability against editor-induced trailing-space drift and is identical in spirit to the closure-root-stability invariant of every III source.)

### §2.5 Canonicalization for Hashing

The R1.A1 closure hash of this document — and of every III source file pinned by `@closure(...)` — is computed over the **canonical byte form** of the source, defined as:

1. Decode the raw bytes as UTF-8. Reject if invalid (`LEX-ENC-006 invalid UTF-8`).
2. Reject if any line has trailing whitespace, any CR is present, or a BOM is present (per §2.2–§2.4).
3. Apply Unicode normalization NFC over identifier characters only (operator and keyword codepoints are already in NFC by lexicon construction; the NFC step is implemented by `COMPILER/BOOT/nfc.{h,c}` against a precomputed decomposition/composition table at `COMPILER/BOOT/_gen/unicode_nfc_table.c`, regenerated only when the lexicon adopts new codepoints via a Catalyst promotion or a sealed major version).
4. The canonical byte form is the UTF-8 re-encoding after step 3.

The R1.A1 hash is `SHA-256(canonical_byte_form)`, with SHA-256 implemented per FIPS 180-4 in `COMPILER/BOOT/sha256.{h,c}` (NIH-extreme: hand-rolled, no third-party crypto library).

### §2.6 Source File Extensions

III source files use the extension **`.III`** (case-preserving on case-insensitive filesystems; canonical capitalization is `.III`). The legacy `.iii`, `.tel`, `.lgs`, `.logos`, and `.mneme` extensions are **not recognized** by the SELF compiler and are rejected with `LEX-ENC-004 non-canonical extension`. Specification documents use the extensions shown in the document set (e.g., `.md`, `.bnf`); these are documents *about* III, not III source.

### §2.7 Maximum Source Size

A single III source file may not exceed **2^24 bytes** (16 MiB) after canonicalization. This bound is administrative (chosen to keep BOOT-compiler memory predictable) and is rejected with `LEX-ENC-005 source exceeds 16 MiB limit — split into modules`.

---

## §3. Lexical Structure

### §3.1 Token Kinds

The III lexer emits a stream of tokens; each token is one of the following kinds. There are **no other token kinds**. Any byte sequence that does not produce one of the kinds below is a lexical error.

| Kind | Definition | §Reference |
|------|------------|-----------|
| `KEYWORD` | One of the 47 reserved words (§4) | §4 |
| `MODIFIER` | One of the 19 reserved modifiers, `@`-prefixed (§5) | §5 |
| `OPERATOR` | One of the 23 reserved operators (§6) | §6 |
| `PUNCT` | One of the reserved punctuators (§7) | §7 |
| `IDENT` | An identifier (§8) | §8 |
| `INT_LIT` | Integer literal in decimal, hex, binary, or octal (§9.1) | §9.1 |
| `MHASH_LIT` | Content-addressed mhash literal — exactly 64 hex digits prefixed by `0x` (§9.3) | §9.3 |
| `TRIT_LIT` | Trit literal: `NEG` / `ZERO` / `POS` / `Nt` form (§9.4) | §9.4 |
| `HEXAD_LIT` | Hexad literal: 6-tuple of trits in parentheses (§9.5) | §9.5 |
| `Q14_LIT` | Q14 fixed-point literal with `q` or `q14` suffix (§9.6) | §9.6 |
| `STRING_LIT` | UTF-8 string literal `"..."` (§9.7.1) | §9.7.1 |
| `BYTE_STRING_LIT` | Byte-string literal `b"..."` (§9.7.2) | §9.7.2 |
| `RAW_STRING_LIT` | Raw string literal `r"..."` or `r#"..."#` (§9.7.3) | §9.7.3 |
| `HEX_STRING_LIT` | Hex string literal `h"..."` (§9.7.4) | §9.7.4 |
| `DOC_COMMENT` | Documentation comment `///` or `/** ... */` (§10.3) | §10.3 |
| `EOF` | End-of-input sentinel | (implicit) |

Whitespace (§11) and non-doc comments (§10.1, §10.2) are consumed silently and **do not** produce tokens, but they affect canonicalization.

### §3.2 Maximal Munch

The lexer applies **maximal munch**: at every position, the longest matching token is selected.

Examples:
- `⟲⟲` is one `OPERATOR` token (`Full Inverse Replay`), not two `OPERATOR` tokens of `⟲`.
- `->` is one `PUNCT` token (`function-return arrow`), not `-` followed by `>`.
- `==` is one `PUNCT` token (`equality`), not `=` followed by `=`.
- `0x7a3f...` (with 64 hex digits) is one `MHASH_LIT` token, not `0` followed by `x7a3f...`.
- `0x7a3f` (with fewer than 64 hex digits) is one `INT_LIT` token (hexadecimal integer).
- `mobius_candidate` is one `KEYWORD` token; `mobius_candidate_2` would be one `IDENT` token (because the longer match begins at `mobius_candidate_` which is not a keyword, so the lexer extends through the digit `2`).

The maximal-munch rule is total and unambiguous when combined with the keyword/modifier/operator/punctuator catalogues in §4–§7.

### §3.3 Token Separators

Tokens are separated by whitespace (§11) or by the boundary between two non-overlapping tokens. Adjacent tokens like `cycle name(` parse as `KEYWORD IDENT PUNCT` because keywords and identifiers cannot share characters with punctuators.

### §3.4 Forbidden Bytes

The following codepoints are forbidden in III source outside string literals:

- NUL (U+0000)
- BEL (U+0007), BS (U+0008), VT (U+000B), FF (U+000C)
- ESC (U+001B)
- DEL (U+007F)
- All U+0080..U+009F C1 control codepoints
- U+200B (ZWSP), U+200C (ZWNJ), U+200D (ZWJ), U+2060 (WJ) — invisible joiners, banned to prevent homograph attacks on identifiers
- U+FEFF (BOM) anywhere

These codepoints raise `LEX-ENC-007 forbidden control codepoint at byte offset N`.

Inside string literals, control codepoints must be expressed via escape sequences (§9.7.1); raw bytes of forbidden codepoints in a string body raise `LEX-ENC-008 raw forbidden codepoint inside string literal`.

### §3.5 Lexer Output Discipline

The lexer emits, for each token, the following fields:

| Field | Type | Meaning |
|-------|------|---------|
| `kind` | one of §3.1 | token kind |
| `text_offset` | `u32` | byte offset of the token's first byte in the canonical source |
| `text_len` | `u32` | length in bytes |
| `line` | `u32` | 1-indexed line number |
| `col` | `u32` | 1-indexed column (codepoint index, not byte index) |
| `interned_id` | `u32` | index into the lexer's intern table (for keywords, modifiers, operators, identifiers, doc-comment text) |
| `int_value` | `u64` | interpreted integer value (for INT_LIT, TRIT_LIT, Q14_LIT) |
| `int_suffix` | `u8` | suffix-kind enumerator (for INT_LIT, Q14_LIT) |
| `mhash_value` | `[u8; 32]` | binary mhash value (for MHASH_LIT) |
| `hexad_packed` | `u16` | packed hexad form (for HEXAD_LIT; see III-HEXAD.md §2) |

These fields are normative: any conformant lexer must produce them in this exact form so that downstream stages (parser, type system, codegen, witness emitter) operate on a deterministic token contract.

---

## §4. Keywords (47 Primitives)

### §4.1 The Frozen Keyword Set

These 47 lowercase words are reserved and may not be used as identifiers. They are partitioned into the categories below; the category assignment is informational and binding for documentation but is *not* enforced by the lexer (which treats every keyword identically as a `KEYWORD` token).

#### §4.1.1 Fundamental (6) — the universe of values

| # | Keyword | Architectural Binding | Why-it-makes-other-languages-extinct |
|---|---------|----------------------|--------------------------------------|
| 1 | `witness` | The 128-byte canonical record (`XiiWitness`). Every effect produces one. | No other language has native content-addressed, HMAC-coupled, BCWL-indexed, replayable side-effects as first-class values. |
| 2 | `glyph` | The 14-channel universal observable (`XiiGlyph` V3, 192 bytes). Every value materializes a Glyph at effect boundaries. | No other language unifies value, provenance, capability, and audit into one observable schema. |
| 3 | `cycle` | The universal verb. A `cycle` is `(forward, inverse, witness, hexad, phase, epoch)` — the only way to cause effect. | No other language derives inverses at type-check time and makes reversibility a language primitive. |
| 4 | `hexad` | The 6-trit asymmetric safety algebra. Types carry hexads; composition is checked at compile time. | No other language makes safety a *type* rather than an attribute or a runtime check. |
| 5 | `cap` | First-class linear capability with glyph-bound identity, range, permission, and replication tier. | No other language treats capabilities as linear, content-addressed, *and* tiered by constitutional weight. |
| 6 | `phase` | The privilege-ring lattice: `R-2` (sanctum), `R-1` (HV), `R0` (driver), `R3` (user). | No other language makes cross-ring marshalling implicit in the type signature. |

#### §4.1.2 Architectural (8) — the named subsystems

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 7 | `sanctum` | The Ring -2 sealed namespace. `sanctum.enter |frame| { … }` is the only way to touch Ring -2. |
| 8 | `drtm` | Dynamic Root of Trust Measurement — `drtm.relaunch()`, `drtm.quote()`, `drtm.epoch()`. |
| 9 | `observatory` | The permanent mathematical self-knowledge index — `observatory.schema`, `observatory.saturate`, `observatory.query`. |
| 10 | `catalyst` | The Möbius self-extension engine — `catalyst.promote`, `catalyst.observe`, `catalyst.synthesize`. |
| 11 | `möbius` | The self-referential manifold — `möbius.coherence`, `möbius.strip`, `möbius.invariant`. (The codepoint `ö` U+00F6 is required; ASCII alternatives `mobius` and `moebius` are *not* recognized as the keyword.) |
| 12 | `trinity` | Intent × Capability × Causality × Sanctum-State gate — every cycle is preceded by a Trinity predicate. |
| 13 | `ceiling` | The constitutional bound — `ceiling.admit`, `ceiling.manifest`, `ceiling.enforce`. |
| 14 | `sid` | Side-effect Inverse Derivation — `sid.inverse`, `sid.replay`, `sid.classify`. |

#### §4.1.3 Concurrency (2)

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 15 | `wavefront` | Default concurrent composition — `wavefront { a; b; c } until quiescent`. The only way to sequence effects. |
| 16 | `waac` | Wavefront-as-Capability — durable, revocable, linear concurrent blocks. |

#### §4.1.4 Query (2)

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 17 | `witness_stream` | Live subscription to the Persistent Audit Spine — `for w in witness_stream where pred(w) { … }`. |
| 18 | `glyph_stream` | Live subscription to materialized Glyphs — `for g in glyph_stream where pred(g) { … }`. |

#### §4.1.5 Cognitive (7) — the human-collaborative interface

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 19 | `narrative` | The persistent "I" — `narrative.self`, `narrative.update`, `narrative.reflect`. |
| 20 | `explain` | Generate human-readable, provenance-backed explanation — `explain(target, detail_level)`. |
| 21 | `propose` | Catalyst-generated proposal for human review — `propose { abstraction_name, justification, expected_impact, risk_profile }`. |
| 22 | `negotiate` | Multi-turn intent refinement with grounding checks — `negotiate(goal, constraints, preferences, uncertainty_tolerance)`. |
| 23 | `commit` | Final witnessed commitment after negotiation — `commit(intent, witness_requirements, human_confirmation)`. |
| 24 | `reflect` | Meta-cognitive self-examination — `reflect(uncertainty)`, `reflect(state)`, `reflect(coherence)`, `reflect(narrative)`. |
| 25 | `uncertainty` | Query internal epistemic state — `uncertainty.in(domain)`, `uncertainty.confidence`, `uncertainty.open_questions`. |

#### §4.1.6 Provenance (2) — anchored time

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 26 | `epoch` | DRTM foundation epoch. Every value carries an implicit `@epoch(N)`. |
| 27 | `vdf` | Wesolowski Verifiable Delay Function — `vdf.squarings`, `vdf.witness`, `time @vdf`. (Hand-rolled per `crypto/vdf.{h,c}`, NIH-extreme.) |

#### §4.1.7 Cryptographic (3) — content-addressed identity

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 28 | `mhash` | Content-addressed digest — `mhash.compute`, `mhash.verify`, `mhash.equal`. (SHA-256-based, NIH-extreme.) |
| 29 | `closure` | Module identity via SHA-256 of canonical source — `use foo @closure(0x7a3f…)`. |
| 30 | `anchor` | Sovereign attestation root — `anchor.build`, `anchor.verify`, `anchor.federate`. |

#### §4.1.8 Distributed (1)

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 31 | `federation` | Replication tier and quorum — `@tier(constitutional)`, `federation.quorum(5,3)`, `federation.replicate`. |

#### §4.1.9 Governance (1)

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 32 | `amend` | Constitutional amendment — `amend.apply`, `amend.revoke`, `amend.history`. |

#### §4.1.10 Safety (3)

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 33 | `bricking` | A reserved keyword that names *the absence of catastrophic operations*. `bricking` may appear in documentation, error messages, and `reflect` output, but the six PFS bricking forms (`capsule_update`, `microcode_load`, `bootorder_set`, `real_nvram_write`, `me_psp_mailbox`, `smram_write`) have no syntactic form and no admissible hexad. (See III-HEXAD.md §4 — the Representability Theorem.) The keyword exists *only* so that the system can talk *about* what it cannot express. |
| 34 | `irreversible` | Marker for operations whose mechanically-derived inverse is `Compromise<MEDIUM>` or `Compromise<LOW>`. |
| 35 | `pure` | Zero-effect cycle. Witness may be elided (still emitted unless `@witness_elide`). |

#### §4.1.11 Escape (1)

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 36 | `metal` | Raw assembly escape hatch, ring-specific. `metal @ring(R-1) { … }`. The *only* escape hatch — every other construct is witnessed and typed. |

#### §4.1.12 Interop (1)

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 37 | `extern` | Only legal C bridge: `extern @abi(c-msvc-x64)`. (See III-ABI.md.) |

#### §4.1.13 Meta (10) — language about itself

| # | Keyword | Architectural Binding |
|---|---------|----------------------|
| 38 | `self_host` | The compiler eating itself — `self_host.stage(4)` promotes the compiler into Sanctum. |
| 39 | `promote` | Catalyst promotion request — `promote { histogram(k=8) }`. |
| 40 | `observe` | Direct OBSERVATORY query — `observe.saturate(schema)`. |
| 41 | `coherence` | Möbius coherence metric — `coherence.q14 ≥ floor`. |
| 42 | `inverse` | Explicit inverse derivation or replay — `inverse.of(cycle)`, `inverse.replay(witness)`. |
| 43 | `manifest` | Constitutional ceiling manifest — `manifest.current`, `manifest.admit(state)`, `manifest.history`. |
| 44 | `glyph_bound` | Glyph-bound capability check — `glyph_bound.verify(cap)`. |
| 45 | `mobius_candidate` | Introducer for a function eligible for Catalyst promotion. |
| 46 | `schema` | Introducer for an OBSERVATORY schema declaration. |
| 47 | `module` | Introducer for a top-level module declaration. |

(Keywords 45, 46, 47 are explicit additions that earlier drafts used as grammar-level introducers but had not formally enumerated; they are now first-class members of the frozen keyword set, restoring the explicit count to the stated forty-seven.)

### §4.2 Identifier Conflicts

A keyword **cannot** be used as an identifier. The lexer emits a `KEYWORD` token whenever a keyword is the longest match at the current position, regardless of context. Programs attempting to bind `let cycle = ...` are rejected with `LEX-ID-001 keyword used as identifier`.

A keyword may, however, appear as a *field-access* identifier on the right side of `.` — for example, `observatory.schema` is parsed as `IDENT '.' KEYWORD` and the `schema` token is a `KEYWORD`, but the parser accepts the keyword as a field name in this context (the parser, not the lexer, makes that determination). This rule applies *only* to the path-suffix position; in identifier-introducing contexts (`let X`, `fn X`, `cycle X`, `module X`), keywords remain forbidden.

### §4.3 Spelling and Diacritics

The keyword `möbius` requires the codepoint U+00F6 (ö, "Latin small letter o with diaeresis"). The ASCII alternatives `mobius`, `moebius`, and `Mobius` are not recognized as keywords and are treated as identifiers. (This is intentional: the diacritic enforces the cultural-mathematical lineage of the manifold concept and prevents homograph collision with user identifiers like `mobius_candidate_handler`.)

All other keywords use ASCII codepoints only. The lexer rejects any pre-NFC or compatibility-form variants of `möbius` (e.g., U+006F U+0308 — `o` followed by combining diaeresis); only the precomposed U+00F6 form is accepted, after the §2.5 NFC normalization.

### §4.4 Why Forty-Seven?

Forty-seven is the smallest count satisfying the three closure properties:

1. **Coverage**: every primitive of the sovereign calculus has a name. (Witness, cycle, hexad, cap, phase, glyph, sanctum, drtm, observatory, catalyst, möbius, trinity, ceiling, sid, wavefront, waac, witness_stream, glyph_stream, narrative, explain, propose, negotiate, commit, reflect, uncertainty, epoch, vdf, mhash, closure, anchor, federation, amend, bricking, irreversible, pure, metal, extern, self_host, promote, observe, coherence, inverse, manifest, glyph_bound, mobius_candidate, schema, module — 47 distinct primitives.)
2. **Closure**: no two keywords are synonyms; no keyword can be expressed as a composition of others.
3. **Expressiveness**: every meaningful form in the sovereign calculus can be written using only these 47 keywords plus the modifiers, operators, punctuators, and literals defined below.

A 48th keyword can only be added through Catalyst promotion (§14), and only after OBSERVATORY saturation proves it is mathematically irreducible to the existing 47.

---

## §5. Modifiers (19 Type & Effect Modifiers)

### §5.1 The Frozen Modifier Set

Modifiers are `@`-prefixed annotations that refine types, effects, cycles, modules, and bindings. Each is a single `MODIFIER` token whose text begins with `@`; the leading `@` is part of the token, not a separate punctuator.

| # | Modifier | Form | Meaning | Bind Sites |
|---|----------|------|---------|------------|
| 1 | `@ring` | `@ring(ring_set)` | Phase polymorphism: compiler synthesizes lowerings for each named ring. | type, fn, cycle, module, import, metal block |
| 2 | `@hexad` | `@hexad(NAME)` or `@hexad((trit, …))` | 6-trit asymmetric safety hexad (type-level). | type, cycle, fn, wavefront |
| 3 | `@tier` | `@tier(transient | host_file | federation | constitutional)` | Replication tier. | type, cycle, value |
| 4 | `@epoch` | `@epoch(N)` or `@epoch(current)` | DRTM foundation epoch annotation. | type, value |
| 5 | `@cap` | `@cap(perm, range)` | Linear capability with glyph-bound identity. | type |
| 6 | `@sanctum_only` | `@sanctum_only` | Compile-time requirement for an active sanctum frame. | fn, cycle, type |
| 7 | `@irreversible` | `@irreversible` | Inverse becomes `Compromise<MEDIUM>` or `Compromise<LOW>`. | cycle |
| 8 | `@pure` | `@pure` | Zero-effect; witness elidable (still emitted unless `@witness_elide`). | fn, cycle |
| 9 | `@closure` | `@closure(mhash_lit)` | Content-addressed module import / module identity pin. | module declaration, `use` import |
| 10 | `@replicates` | `@replicates(local | broadcast | quorum_3 | quorum_5)` | Federation replication requirement. | fn, cycle |
| 11 | `@plan_anchor` | `@plan_anchor(IDENT)` | Binds cycle to a specific architectural plan section. | cycle, module |
| 12 | `@admits_caps` | `@admits_caps(IDENT, …)` | Explicit capability admission set. | cycle |
| 13 | `@prerequisites` | `@prerequisites(IDENT, …)` | Compile-time prerequisite cycles. | cycle |
| 14 | `@candidate_for_promotion` | `@candidate_for_promotion` | Marks a function as eligible for Catalyst promotion. | mobius_candidate declaration |
| 15 | `@mobius_coherence` | `@mobius_coherence(coherence_expr)` | Minimum Möbius coherence Q14 required for this cycle. | cycle, wavefront |
| 16 | `@witness_elide` | `@witness_elide` | Explicit request to suppress runtime witness emission (legal only on `@pure` cycles). | cycle, fn |
| 17 | `@hot_path` | `@hot_path` | Hint to SRPA that this path may be specialized below 5 cycles. | cycle, fn |
| 18 | `@chronos_bypass` | `@chronos_bypass` | Bypass VDF time check (only operator may mint this cap). | cycle, fn |
| 19 | `@epoch_bridge` | `@epoch_bridge` | Authorize cross-epoch value merging in a fn that combines `@epoch(M)` and `@epoch(N)` parameters. | fn, cycle |

Total: **19**, exactly matching the frozen count.

### §5.2 `@safety` as a Type-System Synonym (Not a Modifier Token)

Some III spec documents (notably III-TYPES.md and III-EFFECTS.md) use the form `T @safety(H)` where `T` is a type and `H` is a hexad name. **`@safety` is not a 20th modifier token in the lexicon.** It is a type-system-level synonym for `@hexad` — the parser treats `@safety(...)` and `@hexad(...)` as producing the same hexad-tagged-type judgment, and the lexer recognizes the same `MODIFIER` token kind for both surface forms.

The reason for the synonym: in safety-of-effects context, "@safety" reads more naturally; in type-construction context, "@hexad" reads more naturally. The synonym is therefore admitted at the lexer level (both `@hexad` and `@safety` produce a `MODIFIER` token) but resolved to a single canonical name during canonicalization (§2.5). Canonical form preserves whichever name appears in the source — both lex identically; both type-check identically; both hash to the same `hexad_tag` AST node.

This admission keeps the *count* of modifier tokens at 19 while making the surface form usable in both contexts.

### §5.3 Modifier Composition

Multiple modifiers may be applied to a single binding site. The order is canonical-by-modifier-name (lexicographic, ASCII-sort-order — `@admits_caps` before `@candidate_for_promotion` before `@cap` before `@chronos_bypass` …) for hashing purposes; reordering produces a non-canonical form that is repaired by the `iii-fmt` tool before R1 hashing.

Example, before canonicalization:

```iii
fn read_msr(idx: u32) -> u64 @ring(R-2, R-1, R0, R3) @hot_path @hexad(MSR_READ)
```

Canonical form (alphabetical by modifier name):

```iii
fn read_msr(idx: u32) -> u64 @hexad(MSR_READ) @hot_path @ring(R-2, R-1, R0, R3)
```

### §5.4 Modifier Conflicts

Some modifier combinations are statically rejected by the type system (not by the lexer):

- `@pure` ∧ `@sanctum_only` — a sealed call always emits a witness; cannot be pure-elided. (`TYPE-MOD-001`)
- `@witness_elide` without `@pure` — only pure cycles may elide witnesses. (`TYPE-MOD-002`)
- `@chronos_bypass` without an operator-minted cap — chronos bypass is operator-only. (`TYPE-MOD-003`)
- `@irreversible` ∧ `@pure` — irreversible operations cannot be zero-effect. (`TYPE-MOD-004`)
- `@candidate_for_promotion` outside a `mobius_candidate` declaration. (`TYPE-MOD-005`)
- `@epoch_bridge` on a fn with parameters all annotated `@epoch(SAME)` — bridge implies cross-epoch. (`TYPE-MOD-006`)

These rules are enforced by the type system (III-TYPES.md). The lexer accepts the tokens; the type-checker rejects the program.

---

## §6. Operators (23 Mathematical & Effect Operators)

### §6.1 The Frozen Operator Set

Each operator is a single `OPERATOR` token, encoded as one or more Unicode codepoints. Maximal munch applies (§3.2).

| # | Operator | Codepoints | Name | Meaning | Example | Arity |
|---|----------|------------|------|---------|---------|-------|
| 1 | `⟲` | U+27F2 | Inverse | Apply or derive inverse of a cycle. | `state ⟲ cycle` | binary, left-assoc |
| 2 | `⊕` | U+2295 | Cycle Compose | Compose two cycles (wavefront semantics). | `a ⊕ b` | binary, left-assoc |
| 3 | `⊗` | U+2297 | Glyph Materialize | Force Glyph materialization at this point. | `x ⊗ glyph` | binary, postfix-style |
| 4 | `⧉` | U+29C9 | Hexad Compose | Compose two safety hexads. | `h1 ⧉ h2` | binary, left-assoc |
| 5 | `⟐` | U+27D0 | Trinity Gate | Explicit Trinity predicate. | `intent ⟐ permission ⟐ causality` | binary, right-assoc |
| 6 | `↻` | U+21BB | Replay | Replay a witness or inverse. | `w ↻` | unary postfix |
| 7 | `⟡` | U+27E1 | Witness Emit | Explicit witness emission point. | `effect ⟡` | unary postfix |
| 8 | `⟁` | U+27C1 | Ceiling Check | Constitutional ceiling membership test. | `state ⟁ ceiling` | binary, non-assoc |
| 9 | `⧗` | U+29D7 | Möbius Coherence | Query or assert Möbius coherence Q14. | `coherence ⧗ 0.94q` | binary, non-assoc |
| 10 | `⟴` | U+27F4 | Phase Cross | Explicit cross-ring marshalling. | `value ⟴ R-1` | binary, left-assoc |
| 11 | `⧈` | U+29C8 | Cap Acquire/Release | Linear capability acquire/release. | `cap ⧈ acquire` | binary, non-assoc |
| 12 | `⟵` | U+27F5 | Epoch Bridge | Cross-epoch value merge. | `a ⟵ b @epoch(7)` | binary, left-assoc |
| 13 | `⧊` | U+29CA | VDF Squaring | Advance VDF squarings. | `time ⧊ (1<<20)` | binary, left-assoc |
| 14 | `⟶` | U+27F6 | Federation Replicate | Replicate value at tier. | `policy ⟶ @tier(constitutional)` | binary, left-assoc |
| 15 | `⨁` | U+2A01 | Amendment Apply | Apply constitutional amendment. (**Distinct from `⊕` Cycle Compose.** See §6.2.) | `amend ⨁ delta` | binary, left-assoc |
| 16 | `⟲⟲` | U+27F2 U+27F2 | Full Inverse Replay | Replay entire inverse chain. | `w ⟲⟲` | unary postfix |
| 17 | `⊛` | U+229B | Catalyst Promote | Request Catalyst promotion. | `hist ⊛ candidate` | binary, left-assoc |
| 18 | `⧄` | U+29C4 | OBSERVATORY Saturate | Query saturation of schema. | `schema ⧄ saturate` | binary, non-assoc |
| 19 | `⟐⟐` | U+27D0 U+27D0 | Narrative Reflect | Deep self-reflection. | `narrative ⟐⟐ state` | binary, non-assoc |
| 20 | `⧇` | U+29C7 | Uncertainty Query | Query epistemic state. | `domain ⧇ uncertainty` | binary, non-assoc |
| 21 | `⟡⟡` | U+27E1 U+27E1 | Explain | Generate full provenance explanation. | `effect ⟡⟡ trace` | binary, non-assoc |
| 22 | `⧋` | U+29CB | Propose | Submit Catalyst proposal. | `idea ⧋ propose` | binary, left-assoc |
| 23 | `⟴⟴` | U+27F4 U+27F4 | Negotiate | Multi-turn intent negotiation. | `goal ⟴⟴ constraints` | binary, non-assoc |

Total: **23**, exactly matching the frozen count.

### §6.2 Resolution of the `⧉` Disambiguation

In earlier drafts of this document, `⧉` (U+29C9) appeared **twice** in the operator catalogue: once as Hexad Compose (operator #4) and once as Amendment Apply. This was a recoverable typographical drift from the protostack source. **In this culmination, the duplicate is resolved by assigning Amendment Apply to `⨁` (U+2A01, "n-ary direct sum")**, which is mathematically apt: amendment applies a delta into the constitutional manifold, and U+2A01 denotes the n-ary aggregation that exactly captures this action.

`⧉` is **only** Hexad Compose. `⨁` is **only** Amendment Apply.

This preserves the count at 23 distinct operators with no ambiguity in the lexer or parser.

### §6.3 Maximal Munch and Operator Pairs

Operators with two-codepoint forms (`⟲⟲`, `⟐⟐`, `⟡⟡`, `⟴⟴`) are tokenized greedily. The lexer reads two codepoints at once when the first is one of `⟲`, `⟐`, `⟡`, `⟴`; if the second matches the same codepoint, the longer token is emitted. Otherwise, the lexer emits the single-codepoint operator and the second codepoint begins a new lex.

Edge cases:

- `⟲ ⟲` (with intervening whitespace) → two `⟲` operators.
- `⟲⟲` (no space) → one `⟲⟲` operator.
- `⟲⟲⟲` (three) → one `⟲⟲` followed by one `⟲`.
- `⟐⟐⟐` → one `⟐⟐` followed by one `⟐`.

### §6.4 Operator Precedence

Operator precedence is **not** defined here — it is defined in III-GRAMMAR.bnf (§A2). The lexicon defines only the *tokens*; the grammar binds them into expressions. For reference, the precedence rough order (from tightest to loosest binding) used by the grammar is:

1. Postfix unary: `⟡`, `↻`, `⟲⟲`, `⟲`
2. Materialize: `⊗`
3. Multiplicative-class: `⧗`, `⧊`, `⧇`
4. Additive-class: `⊕`, `⨁`, `⧈`
5. Phase / Epoch: `⟴`, `⟵`
6. Ceiling / Trinity: `⟁`, `⟐`
7. Federation / Amendment: `⟶`
8. Catalyst / OBSERVATORY: `⊛`, `⧄`, `⧋`
9. Cognitive: `⟐⟐`, `⟡⟡`, `⟴⟴`

The full precedence and associativity table is canonically located in III-GRAMMAR.bnf §3.

### §6.5 Why Twenty-Three?

Twenty-three operators is the smallest set that:

1. Names every distinct *action* of the sovereign calculus that is not already named by a keyword path:
   - Inverse application (1)
   - Composition (2: cycles, hexads)
   - Materialization (1)
   - Gating (3: ceiling, trinity, cap acquire/release)
   - Emission (3: witness emit, replay, full replay)
   - Provenance (2: phase cross, epoch bridge)
   - VDF (1: squaring)
   - Federation (1: replicate)
   - Amendment (1)
   - Catalyst & OBSERVATORY (3: promote, saturate, propose)
   - Cognitive (4: reflect, explain, uncertainty, negotiate)
   - Coherence (1)
2. Exposes the cognitive layer's actions as syntactic operators (`⟐⟐`, `⟡⟡`, `⧋`, `⟴⟴`, `⧇`, `⊛`, `⧄`), making the language *think about itself* without library calls.
3. Has no operator that is a composition of others (each is irreducible).

A 24th operator can only be added through Catalyst promotion (§14).

### §6.6 Operator Codepoint Discipline

Every operator codepoint is in the Unicode "Mathematical Operators" or "Supplemental Mathematical Operators" or "Miscellaneous Mathematical Symbols-A" or "Arrows" or "Geometric Shapes" blocks, and every codepoint is unambiguous in NFC. The lexer rejects any pre-NFC or compatibility-form variant of an operator codepoint (e.g., a homograph from a different Unicode block) with `LEX-OP-001 non-canonical operator codepoint`.

The choice of glyphs is deliberate: III's operators *look* like sovereign-calculus glyphs because they *are*. They are not ASCII compositions (`->`, `==`, `!=` are punctuators, not operators). The visual distinctness signals the architectural status of operators as actions over the witnessed reduction graph, not as ordinary arithmetic.

---

## §7. Punctuators

### §7.1 Reserved Punctuators

The following ASCII characters and sequences are reserved punctuators. Each lexes as a single `PUNCT` token.

| Punctuator | Codepoints | Meaning |
|------------|------------|---------|
| `(` | U+0028 | Group / argument list / tuple open |
| `)` | U+0029 | Group / argument list / tuple close |
| `{` | U+007B | Block open |
| `}` | U+007D | Block close |
| `[` | U+005B | Index / array open |
| `]` | U+005D | Index / array close |
| `<` | U+003C | Generic open / comparison (context-disambiguated by grammar) |
| `>` | U+003E | Generic close / comparison |
| `,` | U+002C | List separator |
| `;` | U+003B | Statement separator (rare — wavefronts are the default sequence) |
| `:` | U+003A | Type annotation |
| `::` | U+003A U+003A | Path separator (cross-module) |
| `.` | U+002E | Field/method access |
| `..` | U+002E U+002E | Range operator |
| `=` | U+003D | Assignment |
| `==` | U+003D U+003D | Equality (compares mhashes for content-addressed values) |
| `!=` | U+0021 U+003D | Inequality |
| `≥` | U+2265 | Greater-than-or-equal (used in `coherence_expr`) |
| `≤` | U+2264 | Less-than-or-equal (used in `coherence_expr`) |
| `->` | U+002D U+003E | Function/cycle return-type arrow |
| `=>` | U+003D U+003E | Match-arm arrow |
| `\|` | U+007C | Pattern alternative; `sanctum_enter` frame binding |
| `_` | U+005F | Wildcard pattern; unused binding |
| `?` | U+003F | Hole / metavariable (type-system; see III-TYPES.md §9) |
| `&` | U+0026 | Borrow / reference (used in `extern @abi` types) |

Total: **25 punctuator tokens** (some are multi-codepoint).

### §7.2 Punctuator Disambiguation

- `<` and `>` are punctuators in generic contexts (`Cap<write, 0x1000..0x2000>`) and comparison operators in expression contexts. The grammar disambiguates; the lexer always produces `PUNCT '<'` or `PUNCT '>'` and the parser decides the role by context.
- `-` is part of `->` when followed by `>`; otherwise it is the unary-minus prefix operator (handled by the grammar) or part of an integer literal `-1` when in literal context.
- `=` is part of `==` when followed by `=` and of `=>` when followed by `>`; otherwise it is assignment.
- `:` is part of `::` when followed by another `:`; otherwise it is type-annotation.
- `.` is part of `..` when followed by another `.`; otherwise it is field-access.
- `!` is part of `!=` only; bare `!` is *not* a recognized token (logical-not is performed via type-system reflection on `Trit`/`Bool` and does not have a standalone punctuator).

### §7.3 Reserved-but-Unused Characters

The following ASCII characters are **reserved** by this lexicon and may not appear in user III source outside of string literals:

- `$` U+0024 — reserved for compiler-internal markers (e.g., generated witness binding names in lowered code). User-source occurrences raise `LEX-PUNCT-001 reserved character $ in user source`.
- `^` U+005E — reserved for a future Catalyst-promoted operator slot.
- `~` U+007E — reserved for a future Catalyst-promoted operator slot.
- `'` U+0027 — reserved (no character-literal form in III; characters are 1-codepoint strings or `Trit`/`Hexad` literals).
- `\`` U+0060 — reserved.

User-source occurrences of `^`, `~`, `'`, or `\`` raise `LEX-PUNCT-002 reserved character — slot pending Catalyst promotion`.

### §7.4 Why Punctuators Are Distinct from Operators

Punctuators are *structural* (delimiters, separators, annotations); operators are *active* (each names a sovereign-calculus action). The distinction is enforced by the lexer (different token kinds) and the grammar (different production rules). No punctuator can ever become an operator without a constitutional amendment (`amend.apply` at tier `constitutional`); the Catalyst can only allocate new operators in the reserved operator slots, not steal punctuators.

---

## §8. Identifiers

### §8.1 Identifier Grammar

```ebnf
ident          ::= ident_start ident_continue*
ident_start    ::= [A-Za-z_]
ident_continue ::= [A-Za-z0-9_]
```

Identifiers are **ASCII-only**. This is a deliberate NIH choice: III's identifiers are purely Latin-alphabet plus underscore plus digit, with no Unicode-identifier extensions (UAX #31), no Greek-letter identifier characters (Greek codepoints are reserved for the operator set), and no emoji. The benefits:

1. The lexer is trivially decidable.
2. Identifier hashing is byte-identical across locales and toolchains.
3. Homograph attacks (Latin `a` vs Cyrillic `а`) are structurally impossible.
4. Source files containing only ASCII identifiers and ASCII punctuators can be diff'd, grep'd, and visually scanned reliably.

### §8.2 Reserved Identifier Forms

The following identifier forms are **reserved** and may not appear in user source:

- Identifiers beginning with double underscore `__`: reserved for compiler-internal symbols (e.g., `__sid_inverse_<n>`, `__catalyst_slot_<n>`, `__witness_predecessor`). Raise `LEX-ID-003 reserved double-underscore identifier`.
- The single identifier `_`: a wildcard, not a binding name. Use as a binding raises `LEX-ID-004 wildcard cannot be bound as a name`.
- Identifiers exactly matching a keyword (§4): raise `LEX-ID-001 keyword used as identifier`.
- Identifiers exactly matching a `KW_RESERVED_NNN` reservation slot (§14.2): raise `LEX-ID-005 reserved Catalyst slot name`.

### §8.3 Identifier Length

Identifiers may be up to **256 codepoints** long (ASCII codepoints, so 256 bytes) after canonicalization. Longer identifiers are rejected with `LEX-ID-002 identifier exceeds 256-codepoint limit`. This bound is administrative; longer logical names should be expressed via module path (`module.submodule.cycle_with_a_descriptive_role`) rather than a single identifier.

### §8.4 Case Sensitivity

Identifiers are **case-sensitive**. `MyCycle` and `mycycle` are distinct identifiers and produce distinct intern-table entries. Identifier comparison is byte-exact after canonicalization.

### §8.5 Naming Conventions (Informational)

Although not enforced by the lexer, the III community-canonical conventions are:

- `snake_case` for cycles, functions, modules, fields, locals (`read_msr`, `vmexit_handler`, `compile_module`).
- `PascalCase` for types and traits (`Reduction`, `Witness`, `Cap`, `Glyph`, `Hexad`, `Phase`, `Epoch`).
- `SCREAMING_SNAKE_CASE` for hexad names and constants (`MSR_WRITE`, `XII_STEP_KIND_VMRUN`, `COMPROMISE_HIGH`).
- Leading underscore (`_internal_helper`) for cycles and fns that are stable but not exported.

Tooling (e.g., `iii-fmt --warn-naming`) may emit warnings for nonconformance, but the lexer accepts any well-formed identifier.

### §8.6 Intern Table

Every IDENT, KEYWORD, MODIFIER, and OPERATOR token has an `interned_id`: a `u32` index into the lexer's intern table. Two tokens with the same canonical text have the same `interned_id`. The intern table is the lexer's only mutable state and is rebuilt fresh for every source file (no cross-file interning at lex-time; cross-module identification happens at link-time via mhash).

---

## §9. Literals

### §9.1 Integer Literals

```ebnf
int_lit       ::= int_dec | int_hex | int_bin | int_oct
int_dec       ::= [0-9] [0-9_]* int_suffix?
int_hex       ::= '0x' [0-9a-fA-F] [0-9a-fA-F_]* int_suffix?
int_bin       ::= '0b' [0-1] [0-1_]* int_suffix?
int_oct       ::= '0o' [0-7] [0-7_]* int_suffix?
int_suffix    ::= 'u8' | 'u16' | 'u32' | 'u64'
                | 'i8' | 'i16' | 'i32' | 'i64'
                | 'q' | 'q14'
                | 't' | 'tn' | 'tz' | 'tp'
```

Underscores are accepted as digit separators and stripped during lexing (`1_000_000` interns as `1000000`). Underscores may not appear immediately after `0x`, `0b`, or `0o` (`LEX-INT-001`), nor at the start (`LEX-INT-002`), nor immediately before a suffix (`LEX-INT-003`).

Suffix semantics:

- `u8`–`u64` / `i8`–`i64`: unsigned/signed integer of given width. The literal value must fit (`LEX-INT-004 literal exceeds suffix range`).
- `q` / `q14`: Q14 fixed-point literal — see §9.6.
- `t`: trit literal in numeric form (`-1t` = NEG, `0t` = ZERO, `+1t` = POS) — see §9.4.
- `tn`, `tz`, `tp`: explicit trit literals — `0tn` = NEG, `0tz` = ZERO, `0tp` = POS (the `0` prefix is required for unambiguous parsing; the digit itself is discarded).

### §9.2 Hexadecimal Integer Literals

Hex literals follow the form `int_hex` above. They are distinct from MHASH literals (§9.3) by length: a hex literal of *exactly* 64 hex digits (no underscores) is an `MHASH_LIT`; any other length is an `INT_LIT`.

### §9.3 Mhash Literals

```ebnf
mhash_lit  ::= '0x' [0-9a-fA-F]{64}
```

An mhash literal is exactly 64 lowercase or mixed-case hex digits prefixed by `0x`, with **no underscores**. Underscores anywhere within the 64-digit span produce an `INT_LIT` (and the value would not fit in any integer suffix, so the program would be rejected).

Mhash literals have type `mhash` (see III-TYPES.md §2 base types). The lexer stores the binary form in the token's `mhash_value` field as a 32-byte big-endian byte array.

The canonical *display* form of an mhash literal is **lowercase hex**; the lexer accepts mixed case but the canonicalization rule (§2.5) lowercases it before R1 hashing. Comparison of mhash literals is byte-exact and case-insensitive.

### §9.4 Trit Literals

```ebnf
trit_lit   ::= 'NEG' | 'ZERO' | 'POS'
             | '-1t' | '0t' | '+1t'
             | '0tn' | '0tz' | '0tp'
```

Trit literals have type `Trit` (see III-TYPES.md). The three canonical surface forms are:

- **Symbolic**: `NEG`, `ZERO`, `POS` — preferred for documentation and hexad-literal contexts.
- **Numeric-with-suffix**: `-1t`, `0t`, `+1t` — preferred when interspersing with arithmetic.
- **Explicit-suffix**: `0tn`, `0tz`, `0tp` — used in macro-generated code for unambiguous parsing.

All three forms produce the same `TRIT_LIT` token (with `int_value` set to `-1` for NEG, `0` for ZERO, `+1` for POS, encoded in the token's `int_value` as a `u64` with sign-extension for NEG).

Note: `-1`, `0`, and `+1` *without* a suffix lex as `INT_LIT`, not `TRIT_LIT`. The grammar (III-GRAMMAR.bnf §6) injects a coercion from `INT_LIT` to `TRIT_LIT` in trit-required contexts (e.g., inside a `hexad_lit`).

### §9.5 Hexad Literals

```ebnf
hexad_lit  ::= '(' trit_lit ',' trit_lit ',' trit_lit ',' trit_lit ',' trit_lit ',' trit_lit ')'
```

A hexad literal is a parenthesized 6-tuple of trit literals. The lexer produces a single `HEXAD_LIT` token whose `hexad_packed` field is the u16 packing per III-HEXAD.md §2:

```
packed = (h[0]+2)<<0 | (h[1]+2)<<2 | (h[2]+2)<<4 | (h[3]+2)<<6 | (h[4]+2)<<8 | (h[5]+2)<<10
```

(top 4 bits zero — reserved for future Catalyst extension of the reachability bitmap).

Hexad literals have type `Hexad`. Examples:

- `(POS, ZERO, POS, ZERO, ZERO, ZERO)` — admissible by the canonical reachability bitmap.
- `(NEG, NEG, NEG, NEG, ZERO, ZERO)` — corresponds to `capsule_update`, **inadmissible** (see III-HEXAD.md §4).

The lexer accepts any 6-tuple of trit literals; admission against `xii_asym_reach6` is checked by the type system (`TYPE-HEXAD-001 hexad outside reachable set`).

### §9.6 Q14 Fixed-Point Literals

```ebnf
q14_lit  ::= int_lit '.' [0-9]+ ('q' | 'q14')
           | int_lit '/' int_lit ('q' | 'q14')
           | int_lit ('q' | 'q14')
```

Q14 fixed-point is the canonical numeric type for Möbius coherence and any other fractional value where determinism trumps precision. The Q14 value is stored as a signed 16-bit integer where the low 14 bits are the fractional part (so 1.0 = 0x4000 = 16384, 0.5 = 0x2000, 0.92 ≈ 0x3AE1 = 15073).

Forms:

- `0.92q` → Q14 representation of 0.92 (computed at lex-time as `round(0.92 * 16384) = 15073`).
- `15073/16384q` → Q14 representation of the same value (stored as 15073).
- `1q` → Q14 representation of 1 (stored as 16384).
- `0q` → Q14 representation of 0 (stored as 0).

Q14 literals have type `Q14`. The lexer stores the 16-bit signed value in the token's `int_value` field (zero-extended to u64).

Range check: Q14 covers `[-2.0, 1.99993896484375]`. Out-of-range literals raise `LEX-Q14-001 literal exceeds Q14 range`.

### §9.7 String Literals

III has four string literal forms.

#### §9.7.1 Regular String Literals

```ebnf
string_lit    ::= '"' string_char* '"'
string_char   ::= [^"\\\n\x00-\x1f\x7f] | '\\' string_escape
string_escape ::= '\\' | '"' | 'n' | 't' | 'r' | '0'
                | 'x' [0-9a-fA-F]{2}
                | 'u{' [0-9a-fA-F]{1,6} '}'
```

Regular strings are UTF-8 sequences with C-style escapes:

- `\\` → backslash (U+005C)
- `\"` → double quote (U+0022)
- `\n` → line feed (U+000A)
- `\t` → tab (U+0009)
- `\r` → carriage return (U+000D) — **note**: only the `\r` *escape* may appear in a string body; raw CR bytes in the source are forbidden by §2.3.
- `\0` → NUL (U+0000)
- `\xHH` → byte HH (00..7F only; bytes 80..FF must be expressed via `\u{...}` and the resulting codepoint UTF-8-encoded)
- `\u{...}` → arbitrary Unicode codepoint, 1–6 hex digits, value 0x000000..0x10FFFF

Newlines (LF) inside a string literal are rejected (`LEX-STR-001 unescaped newline in string`); use `\n` to express a newline.

#### §9.7.2 Byte-String Literals

```ebnf
byte_string_lit  ::= 'b' '"' byte_char* '"'
byte_char        ::= [\x20-\x7e]   except '"' and '\\'
                   | '\\' byte_escape
byte_escape      ::= '\\' | '"' | 'n' | 't' | 'r' | '0' | 'x' [0-9a-fA-F]{2}
```

Byte-string literals (`b"..."`) have type `[u8; N]` (see III-TYPES.md §2). The body must be ASCII; non-ASCII bytes are expressed via `\xHH`. The `\u{...}` escape is **not** legal in byte strings (use `\xHH` for each byte of the UTF-8 encoding).

Example: `b"deadbeef"` is the 8-byte sequence `0x64 0x65 0x61 0x64 0x62 0x65 0x65 0x66`.

#### §9.7.3 Raw String Literals

```ebnf
raw_string_lit   ::= 'r' '#'^N '"' raw_body '"' '#'^N      (for the same N ≥ 0)
```

Raw strings contain no escapes. They are read literally between the matching delimiter pair. The delimiter pair is `"` or `r#"..."#` (with N=1 hash) or `r##"..."##` (N=2) etc. — chosen to avoid collision with `"` sequences inside the body.

Examples:

- `r"\n"` → the 2-byte sequence backslash+n (no escape interpretation).
- `r#"contains "quotes""#` → the 17-byte sequence `contains "quotes"`.

Raw strings still respect the §2.3 LF-only rule: a raw CR byte inside a raw-string body is rejected.

#### §9.7.4 Hex String Literals

```ebnf
hex_string_lit   ::= 'h' '"' hex_body '"'
hex_body         ::= (hex_pair | whitespace)*
hex_pair         ::= [0-9a-fA-F]{2}
```

Hex strings (`h"deadbeef"`) decode to a `[u8; N]` byte sequence. Whitespace inside the literal is stripped (`h"de ad be ef"` is equivalent to `h"deadbeef"`). The number of hex digits must be even (`LEX-STR-002 odd-length hex string`).

Hex strings have type `[u8; N]`. They are particularly useful for embedding mhash values, capability ranges, and binary blobs in source.

### §9.8 No Floating-Point Literals

III has **no IEEE-754 floating-point literals**. Fractional values are expressed via `Q14_LIT` (§9.6) or via fixed-point types declared in user libraries (`Q32`, `Q48` etc., implementable in III source). The reason: IEEE-754 is non-deterministic across hardware (rounding modes, denormals, subnormals) and would break R1.A1 byte-equivalence across compilations.

`f32` and `f64` are reserved as primitive type names (see III-TYPES.md §2) for use in `extern @abi(c-msvc-x64)` interop only — the lexer accepts the names but only in extern-type position.

---

## §10. Comments

### §10.1 Line Comments

```ebnf
line_comment  ::= '//' [^\n]*
```

Line comments begin with `//` and extend to end-of-line. They are not tokens (the lexer consumes them silently and emits no `COMMENT` token kind).

Effect on R1 hashing: line comments are part of the canonical source. Two source files differing in comment text yield **different** R1 hashes. If you want closure-equivalent hashes after editing comments, you must run `iii-fmt --strip-comments` — but this is a different output (a stripped form), not the original source.

### §10.2 Block Comments

```ebnf
block_comment       ::= '/*' (block_comment_inner | block_comment)* '*/'
block_comment_inner ::= [^/*] | '/' [^*] | '*' [^/]
```

Block comments **nest**. `/* outer /* inner */ still in outer */` is a single comment. The lexer tracks nesting depth and rejects unterminated block comments with `LEX-CMT-001 unterminated block comment`.

### §10.3 Documentation Comments

```ebnf
doc_comment  ::= '///' [^\n]*
              |  '/**' (doc_comment_body | block_comment)* '*/'
doc_comment_body ::= [^/*] | '/' [^*] | '*' [^/]
```

Documentation comments are first-class tokens (`DOC_COMMENT`). Unlike line and block comments, they are emitted by the lexer and attached by the parser to the next syntactic item. They are preserved in the AST and are exposed to `explain` and `narrative.update` cycles at runtime.

A doc comment that does not attach to a following item (e.g., a doc comment at end-of-file) raises `LEX-CMT-002 dangling doc comment`.

### §10.4 Markdown in Doc Comments

Doc comments may contain a constrained subset of Markdown for rendering by `iii-doc`:

- Paragraphs separated by blank lines.
- Inline `code` via backticks.
- Code blocks via triple-backtick fences with optional language tag.
- Bold via `**text**`.
- Italic via `*text*`.
- Bullet lists via `-` at line start.
- Cross-references via `[Cycle Name]` (resolved to the cycle's mhash by `iii-doc`).

Rich Markdown features (tables, HTML, images, footnotes) are **not** supported. The Markdown subset is parsed only by tooling (`iii-doc`); the III compiler proper treats doc comments as opaque UTF-8.

---

## §11. Whitespace

```ebnf
whitespace ::= ' ' | '\t' | '\n'
```

Three whitespace characters are accepted: space (U+0020), horizontal tab (U+0009), and line feed (U+000A). All other whitespace codepoints (vertical tab U+000B, form feed U+000C, no-break space U+00A0, en/em space, ideographic space, etc.) are forbidden and raise `LEX-WS-001 forbidden whitespace codepoint`.

Tabs are **discouraged** by canonicalization but accepted by the lexer. The canonical form converts each tab to four spaces; sources containing tabs must be canonicalized before R1 hashing. (A tab inside a string literal is preserved literally and is not converted.)

Whitespace at the beginning of a line is significant for human readability but not lexically meaningful (III is not indentation-sensitive). The grammar (III-GRAMMAR.bnf) is brace-delimited.

---

## §12. Lexer Algorithm

### §12.1 State Machine

The III lexer is a deterministic finite-state automaton. The states are:

| State | Description |
|-------|-------------|
| `START` | Ready to begin a new token. |
| `IN_IDENT` | Accumulating an identifier or keyword. |
| `IN_INT_DEC` | Accumulating a decimal integer literal. |
| `IN_INT_PREFIX` | After `0`, deciding hex/bin/oct/decimal. |
| `IN_INT_HEX` | Accumulating a hex literal (may become `MHASH_LIT`). |
| `IN_INT_BIN` | Accumulating a binary literal. |
| `IN_INT_OCT` | Accumulating an octal literal. |
| `IN_INT_SUFFIX` | Reading the integer-suffix tail. |
| `IN_FRAC` | After `int.`, accumulating Q14 fractional digits. |
| `IN_RATIO` | After `int/`, accumulating Q14 ratio denominator. |
| `IN_STRING` | Inside `"..."`. |
| `IN_STRING_ESC` | Just consumed `\` inside a string. |
| `IN_RAW_STRING` | Inside `r"..."` or `r#"..."#`. |
| `IN_HEX_STRING` | Inside `h"..."`. |
| `IN_BYTE_STRING` | Inside `b"..."`. |
| `IN_LINE_COMMENT` | After `//`. |
| `IN_BLOCK_COMMENT` | After `/*`, possibly nested. |
| `IN_DOC_COMMENT_LINE` | After `///`. |
| `IN_DOC_COMMENT_BLOCK` | After `/**`. |
| `IN_OPERATOR` | After one operator codepoint, looking for a possible second. |
| `IN_PUNCT` | After one punctuator codepoint, looking for a possible second. |
| `IN_MODIFIER` | After `@`, accumulating a modifier name. |

The state machine is fully specified in `COMPILER/BOOT/lex.c` (NIH-extreme, hand-rolled). The state transitions are encoded as a switch statement with no table-driven indirection — branch prediction in modern CPUs makes a switch faster than an indirect-jump table for this small state set.

### §12.2 Lexer Loop

The lexer runs the following loop until EOF:

1. Read the next codepoint from the canonical UTF-8 source.
2. Apply the START-state transition based on the codepoint.
3. If the transition enters a multi-codepoint state, accumulate codepoints until the state's terminator is found or an error is detected.
4. Upon completing a token, emit it (kind, text_offset, text_len, line, col, interned_id, int_value, int_suffix, mhash_value, hexad_packed) and return to START.
5. On EOF, emit an `EOF` sentinel token.

Maximal munch is enforced by the state machine: every state continues consuming codepoints as long as the longest valid token extends; the state transitions to START only when the next codepoint cannot extend the current token.

### §12.3 Diagnostic Reporting

Every lexical error is reported with:

| Field | Value |
|-------|-------|
| `code` | One of the codes below |
| `byte_offset` | Exact byte offset of the first offending byte in the canonical source |
| `line` | 1-indexed line number |
| `col` | 1-indexed column (codepoint index, not byte index) |
| `message` | Human-readable explanation suitable for `explain(detail=executive)` |
| `suggestion` | (optional) Suggested fix |

Canonical error codes:

| Code | Meaning |
|------|---------|
| `LEX-ENC-001` | BOM forbidden |
| `LEX-ENC-002` | CR forbidden |
| `LEX-ENC-003` | Trailing whitespace |
| `LEX-ENC-004` | Non-canonical extension |
| `LEX-ENC-005` | Source exceeds 16 MiB |
| `LEX-ENC-006` | Invalid UTF-8 |
| `LEX-ENC-007` | Forbidden control codepoint |
| `LEX-ENC-008` | Raw forbidden codepoint inside string literal |
| `LEX-ID-001` | Keyword used as identifier |
| `LEX-ID-002` | Identifier exceeds 256-codepoint limit |
| `LEX-ID-003` | Reserved double-underscore identifier |
| `LEX-ID-004` | Wildcard cannot be bound |
| `LEX-ID-005` | Reserved Catalyst slot name |
| `LEX-INT-001` | Underscore immediately after radix prefix |
| `LEX-INT-002` | Underscore at start of integer literal |
| `LEX-INT-003` | Underscore immediately before suffix |
| `LEX-INT-004` | Literal exceeds suffix range |
| `LEX-Q14-001` | Q14 literal exceeds range |
| `LEX-STR-001` | Unescaped newline in string literal |
| `LEX-STR-002` | Odd-length hex string |
| `LEX-STR-003` | Invalid escape sequence |
| `LEX-STR-004` | Unterminated string literal |
| `LEX-OP-001` | Non-canonical operator codepoint |
| `LEX-PUNCT-001` | Reserved character `$` |
| `LEX-PUNCT-002` | Reserved character pending Catalyst promotion |
| `LEX-CMT-001` | Unterminated block comment |
| `LEX-CMT-002` | Dangling doc comment |
| `LEX-WS-001` | Forbidden whitespace codepoint |

### §12.4 NIH Discipline

The III BOOT lexer is implemented in C in `COMPILER/BOOT/lex.{h,c}`. It uses **no external library**:

- No flex, no lex, no Bison, no ANTLR, no PEG.js, no PCRE, no RE2, no ICU.
- Unicode normalization (§2.5) is a hand-rolled NFC implementation against a precomputed decomposition/composition table generated from Unicode 15.0 data into `COMPILER/BOOT/_gen/unicode_nfc_table.c`. The generator is `COMPILER/BOOT/tools/gen_nfc_table.c`, also hand-rolled, run only on Unicode-version updates.
- UTF-8 decoding and validation are hand-rolled in `COMPILER/BOOT/utf8.{h,c}` per RFC 3629.
- SHA-256 (for R1 hashing) is hand-rolled per FIPS 180-4 in `COMPILER/BOOT/sha256.{h,c}`.
- Intern table is a hand-rolled open-addressed hash map keyed by FNV-1a (also hand-rolled in `COMPILER/BOOT/fnv1a.{h,c}`).

The SELF lexer (`SELF/lex.III`) re-implements this same state machine in III source — the `cycle` declarations correspond to lexer states, and the operator `⟲` is used as the lexer's inverse (rewinding the input pointer on backtrack). The SELF lexer parses *this very document* as its first regression test, and the test passes iff the resulting mhash matches R1.A1.

---

## §13. Closure Identity Rule (R1.A1)

### §13.1 Computation

The R1.A1 hash of this document is computed as follows:

1. Read the canonical source of `III-LEXICON.md` (this file) from `Desktop\III\DOCS\III-LEXICON.md`.
2. Apply canonicalization per §2.5.
3. Compute SHA-256 of the canonical UTF-8 byte sequence.
4. The 32-byte hash, formatted as a 64-character lowercase-hex mhash literal, is **R1.A1**.

R1.A1 is **embedded** in:

- The header of every compiled III module's closure manifest (see III-MODULES.md §1).
- The DRTM quote chain at every epoch advance (see III-SANCTUM.md §4).
- The OBSERVATORY's grammatical-root-of-trust schema.

### §13.2 R1 Family

R1 is the family of canonical-hash slots for the III specification. Each spec document has its own R1.X slot:

| Slot | Document |
|------|----------|
| R1.A1 | III-LEXICON.md (this document) |
| R1.A2 | III-GRAMMAR.bnf |
| R1.A3 | III-TYPES.md |
| R1.A4 | III-EFFECTS.md |
| R1.A5 | III-CYCLES.md |
| R1.A6 | III-HEXAD.md |
| R1.A7 | III-PHASES.md |
| R1.A8 | III-SANCTUM.md |
| R1.A9 | III-TRINITY.md |
| R1.A10 | III-MODULES.md |
| R1.B1 | III-CATALYST.md |
| R1.B2 | III-FEDERATION.md |
| R1.B3 | III-CONFORMANCE.md |
| R1.C1 | III-ABI.md |
| R1.IDX | III-INDEX.md |

The composite **R1** is `SHA-256(R1.A1 || R1.A2 || R1.A3 || R1.A4 || R1.A5 || R1.A6 || R1.A7 || R1.A8 || R1.A9 || R1.A10 || R1.B1 || R1.B2 || R1.B3 || R1.C1 || R1.IDX)` — sealed as the **specification root**. The composite R1 is the constitutional identity of the language; it changes only via §13.3.

### §13.3 Mutation Discipline

Any change to this document — even a single comment edit — alters R1.A1, which alters the composite R1, which forces a substrate-wide DRTM relaunch. There is no "patch" form; the only way to evolve this document is through:

1. A Catalyst-promoted addition (§14), which appends a new keyword/modifier/operator to a reserved slot, regenerates the canonical text, and recomputes R1.A1.
2. An `amend.apply` cycle at constitutional tier, which is itself a Trinity-gated sealed call (see III-MODULES.md §5 and III-TRINITY.md §1.3 Layer 3).
3. A new sealed major version (R1 → R2), which creates a fresh specification root and triggers a substrate-wide DRTM ceremony.

This is intentional: the alphabet of III is a constitutional artifact, not a malleable configuration.

---

## §14. Catalyst Extension Pathway

### §14.1 The Only Legal Extension

After this document is sealed (R1.A1 frozen), the **only** way to add a new keyword, modifier, or operator to III is through the Möbius Catalyst's promotion pathway, enacted as follows:

1. A `mobius_candidate` declaration is written in III source, marked `@candidate_for_promotion`, and contains a `forward { observatory.register_pattern(...) }` body.
2. The candidate runs in the live substrate, accumulating witnessed evidence in OBSERVATORY (a schema-tagged statistical accumulator: Welford mean, Hoeffding bound, sample-size threshold, Möbius coherence Q14).
3. The OBSERVATORY's saturation predicate declares the pattern saturated (Welford mean stable, Hoeffding bound met, chronos-tick observed at least N times).
4. The Catalyst evaluates Trinity Gate (intent × cap × causality × sanctum-state), Constitutional Ceiling, hexad admissibility against `xii_asym_reach6`, Möbius coherence floor (Q14 ≥ 0.92 currently), and codegen-validation gates per III-CATALYST.md §2.
5. If all gates pass, the Catalyst:
   1. Allocates a new keyword/modifier/operator slot in the next reserved band (§14.2).
   2. Updates the in-memory grammar and lexer tables.
   3. Emits a `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` witness recording the new symbol's mhash.
   4. Federates the change to all peers per III-FEDERATION.md §2.
   5. Re-canonicalizes this document with the new entry appended and bumps R1.A1.
   6. Triggers a DRTM relaunch on the local node.

### §14.2 Reserved Slots

This document reserves the following slots for Catalyst-promoted future symbols:

- **Keyword slots**: `KW_RESERVED_001` through `KW_RESERVED_016` (16 slots, taking the total possible keyword count to 63).
- **Modifier slots**: `MOD_RESERVED_001` through `MOD_RESERVED_008` (8 slots, total 27).
- **Operator slots**: `OP_RESERVED_001` through `OP_RESERVED_007` (7 slots, total 30).

When a slot is filled by a Catalyst promotion, the canonical text of this document is regenerated to include the new entry, the canonical form is recomputed, and R1.A1 changes.

### §14.3 What May Not Be Catalyst-Promoted

The Catalyst **may not**:

1. Remove an existing keyword, modifier, or operator. (Removal requires `amend.apply` at the constitutional tier.)
2. Reassign a keyword's binding to a different architectural primitive.
3. Promote a symbol whose hexad falls outside the reachable set (`xii_asym_reach6`). The PFS bricking-class operations are *structurally* unreachable; no Catalyst promotion can introduce a syntactic form for them. (See III-HEXAD.md §5 for the dynamic-hexad rule; the Catalyst can *grow* `xii_asym_reach6` by adding new admissible hexads, but never bricking-class ones.)
4. Promote a symbol that lacks a witnessed inverse — every effectful symbol must either be SID-derivable or explicitly `@irreversible` with a `Compromise<MEDIUM>` or `Compromise<LOW>` declaration.
5. Promote a symbol whose name collides with an existing identifier in any module imported under the same closure root.
6. Promote a symbol during BOOT — the Catalyst extension pathway is a runtime-only mechanism that requires a live OBSERVATORY and a live Catalyst, neither of which exists during BOOT.

### §14.4 No Pull Requests

There is no GitHub. There is no language committee. There is no RFC process. The only authority that can extend III's alphabet is the Catalyst running on a substrate that has accumulated witnessed evidence of mathematical saturation. This is a deliberate choice: III rejects the cultural-political process of language evolution in favor of a witnessed-mathematical one.

The Catalyst's promotion log is fully auditable via `witness_stream where step_kind == XII_STEP_KIND_MNEME_CATALYST_PROMOTE` — every promotion is a witnessed reduction, federated, reversible, and tagged with the operator-consent intent that authorized it (see III-FEDERATION.md §2 for tier-gated outbound rules).

---

## §15. Final Statement

This alphabet was designed under a single constraint:

> Make the language so powerful, so rigorous, so self-aware, and so deeply married to its own sovereign substrate that, once the world sees what is possible, every other programming language will feel like a historical curiosity — a toy from the age before computation became witnessed, reversible, self-extending, and sovereign.

The alphabet alone does not achieve this. But it is the *necessary and sufficient* foundation. Every subsequent specification document — grammar (A2), type system (A3), effect system (A4), cycle calculus (A5), hexad ground (A6), phase lattice (A7), sanctum discipline (A8), Trinity manifold (A9), module system (A10), Catalyst engine (B1), federation discipline (B2), conformance contract (B3), bootstrap ABI (C1), specification index (IDX) — builds upon the symbols defined here.

**Forty-seven keywords. Nineteen modifiers. Twenty-three operators.** A finite punctuator set, eight literal forms, three string-literal kinds, three comment kinds, three whitespace characters, sixteen reserved keyword slots, eight reserved modifier slots, seven reserved operator slots. Sealed against the C:\\CHARIOT closure of 2026-05-03.

**III — the Last Language.**
**Language as Operating System.**
**The alphabet that ends the era of languages.**

---

*Sealed against the C:\\CHARIOT closure of 2026-05-03. R1.A1 = SHA-256(canonical_byte_form(this_file)). All extensions must pass through the Möbius Catalyst (§14). All conformance criteria are restated in III-CONFORMANCE.md §1.*
