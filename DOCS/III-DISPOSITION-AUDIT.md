# III — Disposition Audit (get-rid-of / update / refactor)
> **SUPERSEDED-BY: III-PERFECTION-LEDGER.md** — this document is a HISTORICAL RECORD of its campaign era; the pointer target is the live doc (reunification W6, 2026-07-02).

Companion to the cartographer Master Systems Map (scan #80, 2026-05-28). Where the map
reports *structure* (fan-in, cycles, conflicts), this reports *disposition*: for every
cluster, what to **delete**, **archive**, **keep**, **update**, **refactor** — grounded by
a 22-agent read of the live build, not the map alone.

Method: 22 read-only agents, each cross-checking `STDLIB/scripts/build_stdlib.sh` (the
418-module `MODULES` list), `run_corpus.sh`, and the `build_iiis*.sh` bootstrap. Verdicts
cite build:line / grep evidence. NOTHING was edited.

---

## 0 · The decisive fact

`iiis-2` (the active compiler) **compiles 418 `.iii` modules and ZERO `.c`** — confirmed:
commit `4de54d2` ("exclude iiis1_link_stubs.c from iiis-2/iiis-3 → ZERO compiled .c");
`build_iiis2.sh` skips every ported `.c` and links `.iii.o` + `libiii_native.a` only.
Bootstrap: `iiis-0`(C seed) → `iiis-1` → `iiis-2` → `iiis-3`; all four `.exe` + golden
mhashes are committed in `COMPILED/`.

Therefore of the ~6869 files on disk, the **load-bearing heart is 418 `.iii` modules**.
Everything `.c` is one of: (S) the frozen `iiis-0` seed; (D) reference C since ported to
`.iii` and now dead; (R) standalone reference / future-wave aspirational. The map's
"6869 files" is dominated by (D)+(R) C trees, tests, and build artifacts.

**Two distinct kinds of "dead":** (a) C the compiler no longer ties to — safe to delete or
archive, *cannot* drift the golden mhash; (b) `.iii` modules compiled into `libiii_native.a`
but never called by anything but their own corpus test (or not even that) — the real fat.

---

## 1 · GET RID OF (delete now — `iiis-2`-unreferenced, determinism-safe)

| Target | Files | Evidence |
|---|---|---|
| **`FORCEFIELD/` (UPPERCASE dir)** | ~13 `.iii` | Obsolete duplicate of `STDLIB/iii/forcefield/`. Only the lowercase copies are in `build_stdlib` (pleroma L712, ripple L713, ripple_dyn L714, optinvoke L715); two lowercase copies are *newer/diverged* (P4.3 heap+error guards). **Deleting this dir clears 18 of the 25 map "conflicts"** (all the dn_*/rn_*/oi_*/cpufeat dup @exports live here). |
| **C runtime trees `CYCLES/src`, `HEXAD/src`, `TRINITY/src`** | ~20 `.c` | Ported to `.iii`: CYCLES→`katabasis/*`, HEXAD→`omnia/hexad_*` (headers literally say "native .iii port of HEXAD/src/*.c"), TRINITY→substrate. Standalone test harnesses only; **zero references** in any `build_iiis*.sh`/`build_stdlib.sh`. |
| **Dead C headers in `COMPILER/BOOT/`** | 10 `.h` | `xii_{canon,circ,horizon,lattice,rewrite,term}.h`, `xii.h`, `sema_xii.h`, `cg_r3_xii.h`, `xii_lattice_loader.h` — zero `#include` anywhere; all logic 100% in `.iii`. Commits `2ae8395`/`99eb…` already deleted the matching `.c`. |
| **`SANDBOX/` and `OBSERVABILITY/` C domains** | ~8 files | Fully ported: `omnia/sandbox_{ctor,exec,quota}.iii` and `omnia/obs_{log,metric,trace,observatory}.iii`. C is dead legacy. |
| **Dead `.iii` leaves** | 4 | `katabasis/svm_const.iii` (orphan — NOT in `MODULES`); `verba/pattern_form.iii` + `verba/transform_form.iii` (0 fan-in, 0 corpus, aspirational); `omnia/tp_dispatch_consts.iii` (compiled, never invoked — codecs dispatch via fn-ptr, not this const map). *Removing these from `MODULES` changes `libiii_native.a` → needs a gate re-run + reseal (the ONLY determinism-affecting deletion here).* |
| **Dead dev tools** | 2 `.c` | `gen_ast_offsets.c`, `gen_anchor_seed.c` — no build invocation; offsets are hardcoded in comments / seed is externally supplied. |

All rows except the 4 `.iii` leaves are files `iiis-2` does not compile → deleting them
**cannot** drift the golden `iiis-2` mhash.

---

## 2 · ARCHIVE (move out of the live tree — superseded or aspirational C)

These are not dead *wrong*, but they are not part of `iiis-2` and inflate the tree. Move to
a `REFERENCE/` subtree or a git tag; keep the R1 conformance hashes intact.

| Domain | Files | Why archive (not delete) |
|---|---|---|
| **`LEXICON/` + `GRAMMAR/`** | 68 | Frozen R1.A1 / R1.A2 conformance references; superseded by `COMPILER/BOOT/lex.c+parse.c` (newer, larger) and the `verba`/`.iii` front-end. NOT linked by `iiis-0`. **Gotcha:** `CONSTANTS` links `libiii_lex.a` for SHA-256 — re-point that first (§4). |
| **`CRYPTO-AGILITY/`** | 25 | Ported to `numera/{sha256,sha3,keccak,aes,chacha20,ed25519,x25519,mldsa,mlkem,slhdsa,…}.iii` (headers say "native .iii port of CRYPTO-AGILITY/src/*.c"). C = spec cross-check reference. |
| **`ZK-PRUNING/`** | 13 | Ported to `numera/zk_{snark,stark,prune,field}.iii` (and the `.iii` *fixed* the §4.13 STARK soundness gap). C = toy-field proof-of-concept. |
| **Wave C subsystem domains** (GHOST-CODE, PERFORMANCE, POLYMORPHIC-DATA, CONFORMANCE, FEDERATION, FOUNDERS-ANCHOR, GENESIS-VECTOR, MODULES, PLANETARY, SOVEREIGN-WEB, EFFECTS, ERRORS, ABI, PHASES, SANCTUM-C, TRINITY-C, CATALYST(-EXT), STDLIB-domain, CONSTANTS) | ~80 | Each is `spec.c + impl + test + tool`, tested **in isolation**, **none linked by `iiis-2`** (it links 0 `.c`). Several have live `.iii` counterparts (sanctus, katabasis/ring_lattice, omnia). Keep as sealed R1 spec references. |
| **`LEGACY-INGESTION/`, `PORTABILITY/`** | 30 | *Aspirational* — no `.iii` port yet (future-wave ELF/PE/Mach-O parsers; multi-arch HAL). Keep as design seed, mark clearly "not wired." |

Net: ~215 C files leave the live tree without touching the bootstrap or the gate.

---

## 3 · KEEP-SEED (do NOT touch — bootstrap trust root)

| Target | Note |
|---|---|
| `COMPILER/BOOT/*.c` (19) + `iiis1_link_stubs.c` | The `iiis-0` seed + the `iiis-1` link stubs. Needed for a from-scratch bootstrap; excluded from `iiis-2/3`. |
| `COMPILED/iiis-{0,1,2,3}.exe` + `*.mhash.golden` | Frozen reproducibility anchors. |
| `TYPES/src/cic.c` (+ `types_*`) | The H13 C trust-root kernel; standalone test harness, not linked by `iiis-2`. **Doctrine decision (see §6.7):** keep as the C trust root, or retire now that `numera/typecheck.iii` exists? |

---

## 4 · UPDATE (finish/correct existing live things)

1. **mig1 cad-collapse incomplete** — `aether/witness_hook.iii` still calls raw `keccak256` instead of routing through `numera/cad`. Finish the fold.
2. **`CONSTANTS` → `libiii_lex.a` tie** — re-point CONSTANTS' SHA-256 to `numera/sha256` (or its own copy) *before* archiving LEXICON, else the CONSTANTS conformance build breaks.
3. **Apotheosis migrations doc-only/partial** — mig2 (SovVal-as-inductive), mig3 (@sovereign boundary), mig4 (route-through-XII rule families M2–M13), mig6 (run_charter falsify field), mig7 (register-morphisms) are designed but unimplemented in source. Backlog, not this pass.
4. **De-register the 4 dead `.iii` leaves** (§1) from `build_stdlib`/`run_corpus`; re-run the gate + reseal.

---

## 5 · REFACTOR (restructure live things)

1. **THE ORCHESTRATION GAP (headline).** ~40 `.iii` modules are compiled into `libiii_native.a` with **zero production callers**, and ~30 of them have **zero corpus** — pure anticipational "gospel": `aether` Layer-11 (bisimulation_witness, cost_overrun_handler, distress_witness, firmware_quarantine, shape_negotiator, memo_query, memo_compactor_coordination, bone_marrow, cap_forge, context_awareness, topology_atlas, triple_check, witness_compactor, pattern_set_federation, quarantine, basal_probe, reversibility_audit ×17), the Reach (×7), federation `fed_*` (×6), `hotstuff*` (×3), Phase-D wire (×4); plus `omnia` R&D: `self_reformatter`, `ai_resolve`, `jit_fuse`, `jit_swap`, `obs_*` (×4), `dynamic_*` (×2), `sandbox_exec`, `ripple_field`. **Decision per module: WIRE IN (the missile — give it a real caller + corpus) or GATE OUT of the default build.** This is the true lean-up, and the natural home for the self-optimization work.
2. **XII non-global-confluence** — `xii_joinability` proves 35 subterm critical pairs do not join (e.g., R001 assoc × R008 FIF-lift); determinism holds only by fixed bottom-up order. **Decide:** formally accept fixed-order determinism (document in `DOCS/III-XII.md §9.2`) *or* complete via Knuth-Bendix. (Map finding #5.)
3. **Consolidate the 16 `verba/glyph_*` forms** → 2-3 parametric modules (scalar / composite / domain-sealed); they are mechanically identical wrappers over `glyph_core`.
4. **Consolidate the 8 `omnia/xii_curated_*` tables** into one registration module (all called linearly from `xii_register_all`, no interdependencies).
5. **Merge the hex-family transforms** `tp_raw_hex`/`tp_iii_hex`/`tp_pe_hex`; pre-generate the boot-time pattern registration (50+ per-startup registrations → one sealed table).
6. **Quarantine `memoria/arena_safe` + `region_safe`** — in the build, zero callers (defensive BSS separation, Lattice Step 0017/0018); remove if that work is shelved.
7. **cic.c doctrine** — see §3.

---

## 6 · Map alarms that are NOT problems (debunked by evidence)

- **The 2 dependency cycles are intentional & load-bearing — keep, just document.**
  `typecheck ↔ ccl` = checker ↔ conversion-oracle/readback (breaking it = 2500-line
  duplication). `temporal_logic ↔ constitution` = the LTL model-checker evaluates
  constitutional predicates as its atoms. Both resolve cleanly at archive link time.
- **The "18 duplicate @export symbols" ≈ one problem:** they are all the `FORCEFIELD/` vs
  `forcefield/` directory duplication (§1) plus the *intentional* `cpufeat_has_avx512f`
  Ring-0 override (isolated `cg_r0` build). Delete `FORCEFIELD/` → hazards gone.
- **The ripple "triplication"** (`forcefield/ripple`, `omnia/ripple`, `omnia/proof_ripple`)
  and **`resolver_replay`** (omnia vs sanctus) are **distinct modules with disjoint symbols** —
  no link hazard.
- **`cpufeat`'s `cpuid_helper.s` is asm metal, not a C-library tie** — consistent with the
  "no C ties" property (libc + `.iii` + dedicated `.s`).

---

## 7 · Sequencing & determinism safety

1. §1 deletions of `iiis-2`-unreferenced files (FORCEFIELD/, C trees, dead headers, ported C
   domains, dead tools) — **cannot drift the golden mhash**; do first, verify gate stays green.
2. §4.2 (CONSTANTS re-point) before archiving LEXICON/GRAMMAR.
3. §1 4-leaf `.iii` removal + §4.4 de-registration — **one gate re-run + reseal** (the only
   determinism-affecting deletion).
4. §2 archive moves — `iiis-2`-neutral; verify the conformance/test builds that consume the C
   (CONSTANTS, TYPES headers) after the move.
5. §5 refactors — each behind the differential gate + corpus; the orchestration-gap (§5.1) is
   the multi-increment body of work and ties to the self-optimization "missile."

Estimated live-tree reduction: ~55 files deleted outright + ~215 C files archived, with the
418-module `.iii` heart untouched except the 4 dead leaves and the §5 refactors.
