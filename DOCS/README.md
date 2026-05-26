# DOCS — Specification & Reference Index

This directory holds the III specification family and operational ledgers.
This README is a **navigation overlay** — it does not replace
`III-INDEX.md`, which remains the constitutional R1 master index.

> Constitutional index: see [`III-INDEX.md`](./III-INDEX.md). That document
> is sealed; its hash slot is `R1.IDX` and it participates in the composite
> specification root `R1`.

---

## §1. The R1-sealed core (15 documents)

These define the III language. A change to any of them — even a single
comment edit — alters the composite `R1` root and forces a substrate-wide
DRTM relaunch. Read these first.

| # | Document | Slot | Subject |
|---|---|---|---|
| A1 | [III-LEXICON.md](./III-LEXICON.md) | R1.A1 | 47 keywords · 19 modifiers · 23 operators · lexer state machine. |
| A2 | III-GRAMMAR.bnf *(formal grammar — check repo for sealed copy)* | R1.A2 | Production rules · AST kind enumerator · precedence ladder. |
| A3 | [III-TYPES.md](./III-TYPES.md) | R1.A3 | Universe ladder · Reduction tuple · linear/epistemic/Möbius types. |
| A4 | [III-EFFECTS.md](./III-EFFECTS.md) | R1.A4 | 17 SE kinds · 3 Compromise tiers · IRPD discipline. |
| A5 | [III-CYCLES.md](./III-CYCLES.md) | R1.A5 | SID 17-kind classifier · 32-step plan · 128-byte witnesses. |
| A6 | [III-HEXAD.md](./III-HEXAD.md) | R1.A6 | `{NEG, ZERO, POS}` algebra · 144-byte reachability bitmap. |
| A7 | [III-PHASES.md](./III-PHASES.md) | R1.A7 | R-2 · R-1 · R0 · R3 · phase polymorphism. |
| A8 | [III-SANCTUM.md](./III-SANCTUM.md) | R1.A8 | Ring -2 discipline · 9+1 sealed methods · `@seal_id`. |
| A9 | [III-TRINITY.md](./III-TRINITY.md) | R1.A9 | SCBA · ACC · Trinity Gate · admission manifold. |
| A10 | [III-MODULES.md](./III-MODULES.md) | R1.A10 | Module system · safety-first revision · ring-gated promotion. |
| B1 | [III-CATALYST.md](./III-CATALYST.md) | R1.B1 | 8 promotion gates · synthesis capabilities · safety rails. |
| B2 | [III-FEDERATION.md](./III-FEDERATION.md) | R1.B2 | 4-tier outbound · IOMMU mediation · quorum specs. |
| B3 | [III-CONFORMANCE.md](./III-CONFORMANCE.md) | R1.B3 | The 30 conformance criteria (C-1..C-30). |
| C1 | [III-ABI.md](./III-ABI.md) | R1.C1 | The single bootstrap-only `extern @abi(c-msvc-x64)` rule. |
| IDX | [III-INDEX.md](./III-INDEX.md) | R1.IDX | The master index (R1 = SHA-256 over A1..A10 · B1..B3 · C1 · IDX). |

## §2. R1-derivative architectural mandates (16 documents)

Architecturally binding on every implementation, but **not** part of the
sealed R1 set. Their mhashes do not participate in R1 composition;
implementation conformance harnesses still verify them.

| # | Document | Subject |
|---|---|---|
| D1 | [III-STDLIB.md](./III-STDLIB.md) | Stdlib inventory + cross-cutting analysis (95 codex edits + Cluster K). |
| D2 | [III-CONSTANTS.md](./III-CONSTANTS.md) | Constitutional constants ledger; 3 mutation paths. |
| D3 | [III-ERRORS.md](./III-ERRORS.md) | Unified error namespace `<PHASE>-<SUBSYSTEM>-<NNN>`. |
| D4 | [III-CRYPTO-AGILITY.md](./III-CRYPTO-AGILITY.md) | `crypto.<primitive>(suite_id, args)`; pre/post-quantum suite catalogue. |
| D5 | [III-FOUNDERS-ANCHOR.md](./III-FOUNDERS-ANCHOR.md) | Structurally un-amendable veto · R-3 ring · 7 Anchor authorities. |
| D6 | [III-PERFORMANCE.md](./III-PERFORMANCE.md) | SHA-NI · AVX-512 · lock-free rings · NUMA-local audit. |
| D7 | [III-OBSERVABILITY.md](./III-OBSERVABILITY.md) | OBSERVATORY collapse · 12-family threshold library. |
| D8 | [III-ZK-PRUNING.md](./III-ZK-PRUNING.md) | ZK-rollup compression · SNARK + STARK NIH. |
| D9 | [III-PORTABILITY.md](./III-PORTABILITY.md) | HAL · ARMv8 · RISC-V H · Intel-VMX · POWER9. |
| D10 | [III-GHOST-CODE.md](./III-GHOST-CODE.md) | `@ghost` declarations · 12 verification gates. |
| D11 | [III-LEGACY-INGESTION.md](./III-LEGACY-INGESTION.md) | ELF/PE/Mach-O/COFF parsers · sandbox · syscall translation. |
| D12 | [III-POLYMORPHIC-DATA.md](./III-POLYMORPHIC-DATA.md) | Glyph V3 192-byte forms · 16 deserialization parsers · hash-consing. |
| D13 | [III-SOVEREIGN-WEB.md](./III-SOVEREIGN-WEB.md) | IOMMU transport · witness-tagged packets · HotStuff BFT. |
| D14 | [III-CATALYST-EXT.md](./III-CATALYST-EXT.md) | Causal-DAG hypothesis synthesis · counterfactual replay · 8-gate promotion. |
| D15 | [III-PLANETARY.md](./III-PLANETARY.md) | 5-tier hierarchy · Sybil + eclipse resistance · partition recovery. |
| D16 | [III-SANDBOX.md](./III-SANDBOX.md) | Sandbox first-class type · isolation · reversibility. |
| D17 | [III-GENESIS-VECTOR.md](./III-GENESIS-VECTOR.md) | Legitimate-signing model · polymorphic packaging · Trinity-gated first invoke. |

## §3. Auxiliary specifications

| # | Document | Subject |
|---|---|---|
| — | [III-RESOLUTION.md](./III-RESOLUTION.md) | Pattern resolution (FROZEN SPEC III-RES-FROZEN-001). |
| — | [III-CODEGEN-PATTERNS.md](./III-CODEGEN-PATTERNS.md) | Codegen pattern catalogue. |
| — | [III-BABEL.md](./III-BABEL.md) | Cross-form transformation system. |

## §4. Operational ledgers

| Ledger | Purpose |
|---|---|
| [MHASH-LEDGER.md](./MHASH-LEDGER.md) | History of compiler binary mhashes (iiis-0/1/2/3). |
| [MANDATE-LEDGER.md](./MANDATE-LEDGER.md) | M1–M22 mandate audit history. |

## §5. Reading order for a new contributor

1. **`III-INDEX.md`** — for the constitutional view (15 sealed + 16 derivative).
2. **This README** — for the human navigation.
3. The R1-sealed core in this order: `III-LEXICON.md` · grammar · `III-HEXAD.md` (safety ground) · `III-TYPES.md` · `III-EFFECTS.md` · `III-CYCLES.md` · `III-PHASES.md` · `III-SANCTUM.md` · `III-TRINITY.md` · `III-MODULES.md`.
4. Then `III-CATALYST.md` · `III-FEDERATION.md` · `III-CONFORMANCE.md` · `III-ABI.md`.
5. Derivatives (D1..D17) as needed when working on a substrate area.

## §6. Code-side cross-reference

| When working on... | Read this doc | Then this code |
|---|---|---|
| Lexer | `III-LEXICON.md` | `COMPILER/BOOT/lex.c`, `lex_runtime.c`, `lex_impl.c` |
| Parser | grammar | `COMPILER/BOOT/parse.c`, `parse_impl.c`, `ast.c`, `ast_impl.c` |
| Type / Sema | `III-TYPES.md`, `III-EFFECTS.md` | `COMPILER/BOOT/sema.c`, `proof.c`, `hexad_check.c` |
| Cycles | `III-CYCLES.md` | `COMPILER/BOOT/sid.c`, `acc.c` |
| Trinity | `III-TRINITY.md` | `COMPILER/BOOT/ceiling.c`, `witness_alloc.c` |
| Codegen | `III-PHASES.md`, `III-SANCTUM.md` | `COMPILER/BOOT/cg_*.c`, `jit_emit.c`, `link.c`, `emit.c` |
| Stdlib | the relevant D-document | `STDLIB/iii/<subsphere>/<module>.iii` |
| R1 reference impls | the relevant D-document | the per-subsystem dir (HEXAD/, CYCLES/, etc.) — see `R1-SUBSYSTEMS.md` at repo root |

## §7. Provenance

This README was created during the 2026-05-08 architectural refactor (item 3
of the 10-item harmonization sequence). See `NOTES/ARCHITECTURE.md` for the
full snapshot.
