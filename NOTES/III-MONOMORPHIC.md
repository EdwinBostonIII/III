# III-MONOMORPHIC.md

> Operational generics strategy for the Living Sealed Lattice plan.
>
> **Not part of R1.** Not part of the derivative set listed in
> `DOCS/III-INDEX.md` §1.5.

---

## §0 Why This Document Exists

The III language defers `@specialize` (generic-instantiation
machinery) to a future Catalyst promotion. Today, every "generic"
type at the language level is **monomorphic by hand**: the standard
library exports `vec_u8` (not `vec<T>`), `map_u32u32` (not
`map<K, V>`), `result_u32` (not `result<T, E>`), and so on (see
`STDLIB/iii/omnia/vec.iii:10`, `map.iii:11`, `result.iii:9`).

The Living Sealed Lattice plan refers to multiple generics-at-large
in its prose (`crystal<T>`, `crystal<K>`, `json_crystal<T>`,
`vec<crystal_id>`, `map<crystal_id, witness_id>`, etc.). Without
a discipline, those references become a code-bloat trap (every
mention spawns a different naming convention) or a deferred-feature
trap (every mention waits on `@specialize`).

This document fixes the discipline once.

---

## §1 The Discipline

**Rule G1 — Monomorphic-throughout, until `@specialize`.**

Every "generic" reference in the lattice plan resolves to a finite
set of monomorphic instantiations, each with a deterministic name.
The set is enumerated below (§2) and is **the only allowed set** —
adding a new instantiation requires its own atomic plan step that
(a) names it here, (b) implements its surface, (c) adds at least one
corpus test that exercises it, and (d) reseals.

**Rule G2 — Naming convention.**

A monomorphic instantiation name is of the form

    <module>_<type1>[_<type2>]_<op>

where:

* `<module>` is the bare module name (`vec`, `map`, `result`,
  `crystal`, `option`, `set`, `queue`, `pq`, `iter`, `fold`, `zip`,
  `either`).
* `<type1>` and (optionally) `<type2>` are drawn from the **approved
  type alphabet** (Rule G3 below), in the canonical order (key
  before value, in before out, etc.).
* `<op>` is the canonical operation name (`new`, `at`, `put`, `get`,
  `len`, `count`, `pop`, `peek`, `min`, `max`, `eq`, `cmp`, `mint`,
  `verify`, `fold`, `each`, …).

Examples:
* `crystal_u32_mint`, `crystal_u64_mint`, `crystal_bytes32_mint`
* `vec_u64_new`, `vec_u64_push`, `vec_u64_at`
* `map_u32_u64_put`, `map_u32_u64_get`
* `json_crystal_u64_parse`, `json_crystal_bytes32_parse`
* `pq_crystal_id_push`, `pq_crystal_id_pop_min`

**Rule G3 — Approved type alphabet.**

A monomorphic instantiation may use, and only use, the following
underlying primitive types:

| Token | Underlying III type | Bytes |
|---|---|---|
| `u8` | `u8` | 1 |
| `u32` | `u32` | 4 |
| `u64` | `u64` | 8 |
| `i32` | `i32` | 4 |
| `i64` | `i64` | 8 |
| `bytes16` | `[u8; 16]` (passed by pointer) | 16 |
| `bytes32` | `[u8; 32]` (passed by pointer) | 32 |
| `bytes64` | `[u8; 64]` (passed by pointer) | 64 |
| `crystal_id` | `u64` (handle into omnia/crystal.iii slot table) | 8 |
| `witness_id` | `u64` (handle into sanctus/witness.iii) | 8 |
| `kchain_id` | `u64` (handle into sanctus/kchain.iii) | 8 |
| `cap_id` | `u64` (handle into aether/capability.iii) | 8 |
| `arena_id` | `u64` (handle into memoria/arena.iii) | 8 |

These cover every type the lattice plan references. New types
require an atomic Catalyst-style entry below (§4) before use.

**Rule G4 — Anti-bloat (M7).**

If a generic reference appears in the plan but **no corpus test or
runtime path actually exercises** it during execution, the
corresponding monomorphic instantiation is NOT generated. The set
is the minimum closure that the live corpus + plan steps need.

**Rule G5 — Future migration to `@specialize`.**

When `@specialize` is promoted (post-lattice work), a generic
declaration

    @specialize
    fn vec_<T>_push(...) -> ...

will be added, and the existing monomorphic instantiations will be
preserved as `@specialize_instance` aliases (one-line wrappers).
No source code that imports the existing instantiations breaks.

---

## §2 Enumerated Instantiation Set (Lattice Plan)

The lattice plan creates new code touching the following
monomorphic instantiations. Each row names: (a) the existing
module file that hosts the instantiation; (b) the new operations
the plan adds; (c) the lattice plan step(s) that introduce them;
(d) the corpus test(s) that exercise them.

### 2.1 omnia/crystal.iii

| Op | Step(s) | Corpus index (rebased per LATTICE-CHANGELOG §0) |
|---|---|---|
| `crystal_u32_mint` | 0000g | `094_crystal_edges_baseline.iii` |
| `crystal_u64_mint` | 0000g | `094_crystal_edges_baseline.iii` |
| `crystal_bytes32_mint` | 0039 | `155_chacha_seal_stream.iii` |
| `crystal_id_eq` | 0001 | `091_sid_direct_graph.iii` |
| `crystal_id_cmp` | 0001 | `091_sid_direct_graph.iii` |
| `crystal_edges_init` | 0000g | `094_crystal_edges_baseline.iii` |
| `crystal_edges_add` | 0000g | `094_crystal_edges_baseline.iii` |
| `crystal_edges_count` | 0000g | `094_crystal_edges_baseline.iii` |
| `crystal_edges_at` | 0000g | `094_crystal_edges_baseline.iii` |

### 2.2 omnia/vec.iii (new instantiation: `vec_u64`)

| Op | Step(s) | Corpus |
|---|---|---|
| `vec_u64_new(arena_id, hard_max)` | 0001 | `091_sid_direct_graph.iii` |
| `vec_u64_push(id, v)` | 0001 | `091_sid_direct_graph.iii` |
| `vec_u64_at(id, idx)` | 0001 | `091_sid_direct_graph.iii` |
| `vec_u64_count(id)` | 0001 | `091_sid_direct_graph.iii` |

> Note: existing `vec.iii` only has `vec_u8`. The plan's Step 0001
> is the first user; therefore Step 0001 also lays down `vec_u64`
> as a fresh instantiation. The work is bounded (~70 LOC parallel to
> existing `vec_u8`).

### 2.3 omnia/queue.iii (new instantiation: `queue_u64`)

| Op | Step | Corpus |
|---|---|---|
| `queue_u64_new(arena_id, max)` | 0001 (BFS in `sid_transitive_closure`) | `092_sid_transitive_closure.iii` |
| `queue_u64_push(id, v)` | 0001 | `092` |
| `queue_u64_pop(id)` | 0001 | `092` |
| `queue_u64_empty(id)` | 0001 | `092` |

> Note: existing `queue.iii` only has `queue_u32`. Same argument
> applies as `vec_u64` above — Step 0001 instantiates fresh.

### 2.4 omnia/map.iii (new instantiation: `map_u32_u32` for visited set)

The existing `map_u32u32` (lines `map.iii:34-256`) is already
exactly what the BFS visited-set needs. **No new instantiation.**

### 2.5 omnia/json.iii / verba/json.iii (Phase 9)

| Op | Step | Corpus |
|---|---|---|
| `json_crystal_u64_parse(arena_id, src_ptr, len)` | 0063 | `194_json_crystal_u64.iii` (rebased) |
| `json_crystal_bytes32_parse(arena_id, src_ptr, len)` | 0063 | `195_json_crystal_bytes32.iii` (rebased) |

### 2.6 omnia/map.iii (Phase 10 — new instantiations: crystal-keyed)

| Op | Step | Corpus |
|---|---|---|
| `map_crystal_u32_new` / `map_crystal_u32_put` / `map_crystal_u32_get` | 0074 | `210_map_crystal_u32.iii` (rebased) |
| `map_crystal_u64_new` / `map_crystal_u64_put` / `map_crystal_u64_get` | 0074 | `210_map_crystal_u64.iii` (rebased) |

### 2.7 omnia/pq.iii (Phase 10 — new instantiation: `pq_crystal_id`)

| Op | Step | Corpus |
|---|---|---|
| `pq_crystal_id_new` / `pq_crystal_id_push` / `pq_crystal_id_pop_min` | 0080 | `218_pq_crystal_id.iii` (rebased) |

### 2.8 numera/checked.iii (Phase 6 — `checked_u64_*` mirror set)

The existing module already has `checked_u32_*`. Step 0031 adds
the parallel `checked_u64_*` set as a same-shape monomorphic
instantiation. No new naming pattern; mirrors `checked_u32_*`
verbatim with `u64` substituted.

### 2.9 omnia/async.iii (Phase 8 — task crystal-id queue)

| Op | Step | Corpus |
|---|---|---|
| `queue_crystal_id_new` / `queue_crystal_id_push` / `queue_crystal_id_pop` | 0055 | `186_async_task_queue.iii` (rebased) |

### 2.10 verba/glyph/* (Phase 14h — 16 monomorphic forms)

Sixteen glyph forms `g_u8`, `g_u32`, `g_u64`, `g_i64`, `g_f64`,
`g_str`, `g_bytes`, `g_vec`, `g_map`, `g_set`, `g_enum`, `g_record`,
`g_crystal`, `g_witness`, `g_proof`, `g_glyph` — each is its own
file `STDLIB/iii/verba/glyph/g_<TYPE>.iii`, declared per Phase 14h
(Steps 0165-0180).

The dispatcher `glyph_dispatch_<TYPE>(...) -> u64` selects the
correct form by type-id; this is the only "generic-shaped" surface
visible to callers; internally it is a `when` cascade over 16
monomorphic branches.

### 2.11 sanctus/quality.iii (Step 0000f — quality gate aggregator)

No instantiation; all signatures are u32/u64/u8.

---

## §3 Total Footprint

The discipline yields the following monomorphic-instantiation
ABI growth (count of new exported `@export` symbols):

| Module | Existing `@export` | New (per this discipline) | Total after lattice |
|---|---|---|---|
| omnia/crystal.iii | ~15 | +9 | ~24 |
| omnia/vec.iii | ~10 (vec_u8 only) | +4 (vec_u64 minimum surface) | ~14 |
| omnia/queue.iii | ~6 (queue_u32) | +5 (queue_u64, queue_crystal_id) | ~11 |
| omnia/map.iii | ~12 (map_u32u32) | +6 (map_crystal_u32_*, map_crystal_u64_*) | ~18 |
| omnia/pq.iii | ~6 (existing) | +3 (pq_crystal_id_*) | ~9 |
| omnia/async.iii (new) | 0 | +5 | +5 |
| omnia/sid.iii (new) | 0 | +4 | +4 |
| omnia/ripple.iii (new) | 0 | +5 | +5 |
| numera/checked.iii | ~10 (checked_u32_*) | +10 (checked_u64_*) | ~20 |
| verba/json.iii | (existing) | +2 (json_crystal_u64_parse, json_crystal_bytes32_parse) | (existing+2) |
| verba/glyph/* (new) | 0 | +16 (one per form) | +16 |

Total ABI growth: **+69 new `@export` symbols** across the lattice
plan. Each is reviewed under M7 (anti-bloat) and is justified by
at least one corpus test or runtime path. Symbols outside this
list MUST NOT be created without an addendum to this document.

---

## §4 Catalyst-Promotion Path Forward

This document is mutable until `@specialize` is promoted. Until
then, rules G1–G5 are operational law. After promotion:

1. The Catalyst gate set (per `DOCS/III-CATALYST.md`, R1.B1) admits
   `@specialize`.
2. Each affected module (`omnia/vec.iii`, `omnia/map.iii`, ...) is
   re-keyed to `vec<T>`, `map<K, V>`, etc.
3. The 69 monomorphic instantiations are preserved as
   `@specialize_instance` aliases (one-line wrappers).
4. Corpus passes byte-identically; the `iiis-0.exe.mhash` golden
   may shift (Catalyst promotion = R1.X bump), and the layered seal
   continues from the new R1.

---

## §5 Mandate Audit

* **M3** Architecture coherence: enumerated instantiations match
  existing `vec_u8`/`map_u32u32`/`result_u32`/`crystal` patterns.
* **M4** NIH discipline: pure prose; no third-party content.
* **M5** No partial implementations: rule G4 enforces minimum
  closure — every named instantiation is paired to a step + test.
* **M7** Anti-bloat density: every entry has runtime justification
  or it doesn't exist. Total +69 symbols, each with corpus.
* **M16** Edit-first: existing modules absorb new ops where they
  match; new modules created only where the surface doesn't fit
  any existing module.
* **M19** Unlimited creative potential preserved by §4 migration
  path — no creative ceiling here.

## §6 Quality / D-gates / Conformance

Q1-Q6 preserved (no `.iii` changed in this step). D1-D18 not
applicable. C-1..C-30 not impacted (this is operational policy,
not language).
