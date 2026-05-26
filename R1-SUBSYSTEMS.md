# R1-SUBSYSTEMS — Index of the 32 Parallel C Reference Implementations

This file indexes every top-level subsystem directory in the III repo and
classifies its relationship to the live STDLIB build chain.

**Live build chain (untouched by this index):**
* `COMPILER/BOOT/*.c` — bootstrap compiler (iiis-0)
* `STDLIB/iii/*.iii` — 198 production stdlib modules
* `STDLIB/corpus/*.iii` — 179 conformance tests

The 32 directories below each implement an R1 specification module as a
self-contained C library (`README.md` + `src/` + `tests/`). **None are
compiled or linked by the live build scripts.** They are reference
implementations that document the R1 sealed specification family in
executable form, alongside their STDLIB/iii counterparts.

> **Source dates:** subsystem code was last touched 2026-05-03 / 2026-05-04;
> live STDLIB/iii is at 2026-05-08. Subsystems are healthy artifacts, not
> rotted code — but they are not in the day-to-day build path.

---

## §1. Three-state classification

| State | Meaning |
|---|---|
| **REFERENCE-IMPL** | Self-contained C reference impl of a spec module; no STDLIB/iii equivalent yet, or the C version is the canonical reference. **Keep.** |
| **SUPERSEDED-BY-STDLIB** | An equivalent STDLIB/iii module exists in the live build chain. The C ref impl is now historical. **Mark with `_SUPERSEDED_BY.md` pointer; collapse `src/` once spec parity confirmed.** |
| **PARTIAL-OVERLAP** | Some functions migrated to STDLIB/iii, others not. **Audit per-function before deciding.** |
| **EMPTY-PLACEHOLDER** | No source files, possibly inert. **Throw out.** |

## §2. The 32 subsystems

Counts are `src/*.c × include/*.h × tests/*.c`. README presence is `Y/-`.

| Dir | Counts | README | Spec doc | STDLIB/iii counterpart | State |
|---|---|---|---|---|---|
| `ABI/` | 4·0·1 | Y | R1.C1 (`III-ABI.md`) | extern `@abi(c-msvc-x64)` enforced in `COMPILER/BOOT/sema.c` | **REFERENCE-IMPL** — canonical ABI lowering reference. |
| `CATALYST/` | 2·0·1 | Y | R1.B1 (`III-CATALYST.md`) | `STDLIB/iii/sanctus/catalyst.iii` | **SUPERSEDED-BY-STDLIB** |
| `CATALYST-EXT/` | 2·0·1 | Y | D14 (`III-CATALYST-EXT.md`) | `STDLIB/iii/sanctus/promote.iii`, `demote.iii` | **PARTIAL-OVERLAP** |
| `CONFORMANCE/` | 1·0·1 | Y | R1.B3 (`III-CONFORMANCE.md`) | (test harness — not a stdlib module) | **REFERENCE-IMPL** |
| `CONSTANTS/` | 2·0·1 | Y | D2 (`III-CONSTANTS.md`) | (constants embedded in many `.iii` modules) | **REFERENCE-IMPL** — canonical constants ledger. |
| `CRYPTO-AGILITY/` | 11·0·4 | Y | D4 (`III-CRYPTO-AGILITY.md`) | `numera/keccak.iii`, `sha3_*.iii`, `shake*.iii` (post-quantum suites Kyber/Dilithium pending) | **PARTIAL-OVERLAP** |
| `CYCLES/` | 8·0·1 | Y | R1.A5 (`III-CYCLES.md`) | `sanctus/witness.iii`, `sanctus/kchain.iii` (partial) | **PARTIAL-OVERLAP** |
| `EFFECTS/` | 1·0·1 | Y | R1.A4 (`III-EFFECTS.md`) | (effects checked by `COMPILER/BOOT/hexad_check.c` + `sema.c`) | **REFERENCE-IMPL** |
| `ERRORS/` | 2·0·1 | Y | D3 (`III-ERRORS.md`) | (error codes embedded in many modules) | **REFERENCE-IMPL** — canonical error namespace. |
| `FEDERATION/` | 2·0·1 | Y | R1.B2 (`III-FEDERATION.md`) | `aether/fed_tier.iii`, `fed_sybil.iii`, `fed_eclipse.iii`, `fed_admit.iii`, `fed_genesis.iii`, `fed_seal.iii` | **SUPERSEDED-BY-STDLIB** |
| `FOUNDERS-ANCHOR/` | 2·0·1 | Y | D5 (`III-FOUNDERS-ANCHOR.md`) | (no live module — ring R-3 is sealed) | **REFERENCE-IMPL** |
| `GENESIS-VECTOR/` | 2·0·1 | Y | D17 (`III-GENESIS-VECTOR.md`) | `sanctus/genesis.iii`, `aether/fed_genesis.iii` | **SUPERSEDED-BY-STDLIB** |
| `GHOST-CODE/` | 2·0·1 | Y | D10 (`III-GHOST-CODE.md`) | (no live module — `@ghost` modifier is future Phase 14f work) | **REFERENCE-IMPL** |
| `GRAMMAR/` | 13·0·11 | Y | R1.A2 (grammar) | `COMPILER/BOOT/parse.c`, `ast.c` | **REFERENCE-IMPL** — canonical grammar reference (with 11 grammar tests). |
| `HEXAD/` | 7·0·1 | Y | R1.A6 (`III-HEXAD.md`) | `COMPILER/BOOT/hexad_check.c` (live) + future `omnia/hexad.iii` (planned) | **REFERENCE-IMPL** — algebra/dynamic/epistemic/möbius/pfs/reach/types_bridge spread across 7 src files. |
| `INTEGRATION/` | 0·1·1 | - | — | `tests/test_e2e_witness.c` (148-LOC, 5-subsystem e2e; 14 tests pass) | **REFERENCE-IMPL** — top-level e2e integration suite (wired into the harness by RITCHIE Stage 9.7). |
| `LEGACY-INGESTION/` | 8·0·2 | Y | D11 (`III-LEGACY-INGESTION.md`) | (no live module — Phase 14g target) | **REFERENCE-IMPL** — ELF/PE/Mach-O/COFF/DWARF parsers ready for `verba/legacy/*.iii` port. |
| `LEXICON/` | 13·0·12 | Y | R1.A1 (`III-LEXICON.md`) | `COMPILER/BOOT/lex.c` | **REFERENCE-IMPL** — canonical lexer reference (with 12 lexer tests). |
| `MODULES/` | 2·0·1 | Y | R1.A10 (`III-MODULES.md`) | (modules handled by `COMPILER/BOOT/link.c` + each `module <name>` decl) | **REFERENCE-IMPL** |
| `OBSERVABILITY/` | 3·0·1 | Y | D7 (`III-OBSERVABILITY.md`) | `omnia/obs_log.iii`, `obs_metric.iii`, `obs_trace.iii`, `obs_observatory.iii` | **SUPERSEDED-BY-STDLIB** |
| `PERFORMANCE/` | 1·0·1 | Y | D6 (`III-PERFORMANCE.md`) | `numera/cpufeat.iii`, `sha256_dispatch.iii` (partial) | **PARTIAL-OVERLAP** |
| `PHASES/` | 10·0·1 | Y | R1.A7 (`III-PHASES.md`) | `COMPILER/BOOT/cg_*.c` (live) | **REFERENCE-IMPL** |
| `PLANETARY/` | 2·0·1 | Y | D15 (`III-PLANETARY.md`) | (subsumed by `aether/fed_*.iii` family) | **PARTIAL-OVERLAP** |
| `POLYMORPHIC-DATA/` | 2·0·1 | Y | D12 (`III-POLYMORPHIC-DATA.md`) | `verba/glyph_*.iii` (16 glyph forms) | **SUPERSEDED-BY-STDLIB** |
| `PORTABILITY/` | 7·0·1 | Y | D9 (`III-PORTABILITY.md`) | (no live module — Phase 14e target for HAL ports) | **REFERENCE-IMPL** |
| `R2-GENESIS/` | 0·0·0 (1 `.v`) | - | ADR-XII-002 / `DOCS/HARDWARE/I-INSTR-V1.0-spec.md` | `silicon/resolver_unit.v` (484-LOC RTL; completion in RITCHIE Stage 9.2) | **REFERENCE-ARTIFACT** — Verilog resolver-unit RTL preserved per ADR-XII-002. **Keep** (Stage 1.4 reclass — NOT a deletion candidate). |
| `SANCTUM/` | 3·0·1 | Y | R1.A8 (`III-SANCTUM.md`) | `sanctus/*.iii` family | **PARTIAL-OVERLAP** |
| `SANDBOX/` | 2·0·1 | Y | D16 (`III-SANDBOX.md`) | `omnia/sandbox_ctor.iii`, `sandbox_quota.iii`, `sandbox_exec.iii` | **SUPERSEDED-BY-STDLIB** |
| `SOVEREIGN-WEB/` | 2·0·1 | Y | D13 (`III-SOVEREIGN-WEB.md`) | (subsumed by `aether/*.iii` and `fed_*.iii`; HotStuff BFT NIH still pending) | **PARTIAL-OVERLAP** |
| `TRINITY/` | 2·0·1 | Y | R1.A9 (`III-TRINITY.md`) | `COMPILER/BOOT/ceiling.c` (live) + `sanctus/mandate.iii` (partial) | **PARTIAL-OVERLAP** |
| `TYPES/` | 5·0·1 | Y | R1.A3 (`III-TYPES.md`) | (type system enforced in `COMPILER/BOOT/sema.c`) | **REFERENCE-IMPL** — canonical type-system reference. |
| `ZK-PRUNING/` | 5·0·1 | - | D8 (`III-ZK-PRUNING.md`) | `numera/merkle.iii` (partial) | **PARTIAL-OVERLAP** — Groth16/PLONK/STARK still pending. |

## §3. Verdict tally

> **Tally corrected (RITCHIE Stage 1.3, 2026-05-20):** the parenthesised
> totals previously read 12 / 6 / 8 / 2 = 28, which did not match the 32
> enumerated rows (or `ls -d */ | wc -l` = 32). REFERENCE-IMPL enumerates 15
> (was mis-stated 12); PARTIAL-OVERLAP enumerates 9 (was mis-stated 8).
> Corrected to 15 / 6 / 9 / 2 = 32. (Stage 1.4 reclassifies R2-GENESIS and
> Stage 1.5 reclassifies INTEGRATION out of EMPTY-PLACEHOLDER; see those
> entries for the post-reclassification tally.)

**Final tally (post Stage 1.3 count-fix + 1.4/1.5 reclassification):**

* **REFERENCE-IMPL (16)**: ABI, CONFORMANCE, CONSTANTS, EFFECTS, ERRORS,
  FOUNDERS-ANCHOR, GHOST-CODE, GRAMMAR, HEXAD, INTEGRATION, LEGACY-INGESTION,
  LEXICON, MODULES, PHASES, PORTABILITY, TYPES → **keep, audit, document.**
* **SUPERSEDED-BY-STDLIB (6)**: CATALYST, FEDERATION, GENESIS-VECTOR,
  OBSERVABILITY, POLYMORPHIC-DATA, SANDBOX → **mark with `_SUPERSEDED_BY.md`;
  collapse `src/` to `_archive/` once spec-parity confirmed.**
* **PARTIAL-OVERLAP (9)**: CATALYST-EXT, CRYPTO-AGILITY, CYCLES, PERFORMANCE,
  PLANETARY, SANCTUM, SOVEREIGN-WEB, TRINITY, ZK-PRUNING → **per-function
  audit pending; treat as REFERENCE-IMPL meanwhile.**
* **REFERENCE-ARTIFACT (1)**: R2-GENESIS (`silicon/resolver_unit.v`, 484-LOC
  RTL preserved per ADR-XII-002; completion in Stage 9.2) → **keep, NOT a
  deletion candidate.**
* **EMPTY-PLACEHOLDER (0)**: none. (Both former entries reclassified: INTEGRATION
  → REFERENCE-IMPL, R2-GENESIS → REFERENCE-ARTIFACT.)

**Tally: 16 + 6 + 9 + 1 + 0 = 32 ✓** (matches `ls -d */ | wc -l` = 32 subsystem directories). No deletion candidates remain.

## §4. Test-runner integration (planned)

The 32 subsystems have `tests/` directories that are **not** wired into any
top-level test driver. Future cleanup task: a single
`run_subsystems_tests.sh` that walks `*/tests/` and runs each. This is item
8 of the audit verdict (covered separately as `run_all_corpora.sh`); the
subsystem test integration is a follow-up, not done in this pass.

## §5. Spec-doc cross-references

Every R1-sealed and R1-derivative spec doc maps 1:1 to a subsystem
directory:

```
R1.A1 III-LEXICON          → LEXICON/
R1.A2 III-GRAMMAR          → GRAMMAR/
R1.A3 III-TYPES            → TYPES/
R1.A4 III-EFFECTS          → EFFECTS/
R1.A5 III-CYCLES           → CYCLES/
R1.A6 III-HEXAD            → HEXAD/
R1.A7 III-PHASES           → PHASES/
R1.A8 III-SANCTUM          → SANCTUM/
R1.A9 III-TRINITY          → TRINITY/
R1.A10 III-MODULES         → MODULES/
R1.B1 III-CATALYST         → CATALYST/
R1.B2 III-FEDERATION       → FEDERATION/
R1.B3 III-CONFORMANCE      → CONFORMANCE/
R1.C1 III-ABI              → ABI/
R1.IDX III-INDEX           → (master index — no subsystem)
D2  III-CONSTANTS          → CONSTANTS/
D3  III-ERRORS             → ERRORS/
D4  III-CRYPTO-AGILITY     → CRYPTO-AGILITY/
D5  III-FOUNDERS-ANCHOR    → FOUNDERS-ANCHOR/
D6  III-PERFORMANCE        → PERFORMANCE/
D7  III-OBSERVABILITY      → OBSERVABILITY/
D8  III-ZK-PRUNING         → ZK-PRUNING/
D9  III-PORTABILITY        → PORTABILITY/
D10 III-GHOST-CODE         → GHOST-CODE/
D11 III-LEGACY-INGESTION   → LEGACY-INGESTION/
D12 III-POLYMORPHIC-DATA   → POLYMORPHIC-DATA/
D13 III-SOVEREIGN-WEB      → SOVEREIGN-WEB/
D14 III-CATALYST-EXT       → CATALYST-EXT/
D15 III-PLANETARY          → PLANETARY/
D16 III-SANDBOX            → SANDBOX/
D17 III-GENESIS-VECTOR     → GENESIS-VECTOR/
```

(The 16th derivative `D1 III-STDLIB.md` has no dedicated subsystem
directory — its content is realized as the `STDLIB/iii/*.iii` modules
themselves.)

## §6. Provenance

Created during the 2026-05-08 architectural refactor (item 4 of the 10-item
harmonization sequence). See `NOTES/ARCHITECTURE.md` for the full repo
snapshot at that date.
