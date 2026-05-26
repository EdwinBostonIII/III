# 10 numera/sheaf.iii — Implementation Spec

## Verdict

**PARTIAL** — The gospel candidate body is structurally near-complete (12 functions, all slot tables present, correct overall sheaf-condition shape), but it is **not buildable as written** and violates several traps. The two showstoppers: (1) every hashing extern is **mis-sourced** — `keccak256_init/update/final` are declared `from "keccak.iii"` but that module exports none of them (they live in `keccak256.iii`), so the link fails; and (2) it relies on the **streaming Keccak API the entire rest of the substrate abandoned** because it triggers the param-spill trap (Trap 11), plus it declares **four local `var` arrays inside function bodies** (Trap 7), which `iiis-0` does not support. There is also a correctness gap in `sh_check_glue` (silently skips overlap pairs that lack a pre-registered intersection, violating the gospel's "constructed if not already present"). All are fixable without changing the public API; the algorithm is sound.

## Purpose

`numera/sheaf` is the **ontology of local-to-global agreement**: it embodies presheaves and sheaves over a base category whose objects are open sets and whose morphisms are inclusions `U ⊆ V`. A presheaf assigns each open set a 32-byte section identifier (the canonical hash of the data living over it) and each inclusion a deterministic restriction map; the sheaf condition is the exact algebraic fact that a family of local sections agreeing pairwise on overlaps glues to a unique global section. The module *is* the verifier and witness-builder for that gluing — it does not approximate or "mostly agree," it checks every `i<j` overlap exactly and emits a canonical Keccak256 global-section witness independent of cover order.
**Hexad:** `kind_essence`. **Ring:** R0. **K:** 0.99 (slot exhaustion is the only failure mode).

## Public API

All public functions are `@export`. Slot-returning constructors return `SHEAF_SENT` (0xFFFFFFFF) on table-full (a sentinel-typed value per W12). Status functions return negative-`i32` error codes (W9). The boolean `sh_check_glue` returns `u8` 0/1 (W10).

```
fn sh_init() -> i32 @export
fn sh_add_open(open_id: *u8, parent_slot: u32) -> u32 @export
fn sh_find_open(open_id: *u8) -> u32 @export
fn sh_add_section(presheaf_id: *u8, open_slot: u32, section_id: *u8) -> u32 @export
fn sh_find_section(presheaf_id: *u8, open_slot: u32) -> u32 @export
fn sh_section_id(slot: u32, out_id: *u8) -> i32 @export
fn sh_add_restriction(parent: u32, child: u32, transform_id: *u8) -> u32 @export
fn sh_find_restriction(parent: u32, child: u32) -> u32 @export
fn sh_add_intersection(a: u32, b: u32, inter: u32) -> u32 @export
fn sh_find_intersection(a: u32, b: u32) -> u32 @export
fn sh_restrict(section: u32, parent: u32, child: u32, out_id: *u8) -> i32 @export
fn sh_check_glue(cover: *u8, parent_open: u32, out_global: *u8) -> u8 @export
```

Return-status convention per fn:
- `sh_init` → `SHEAF_OK` always (W12).
- `sh_add_open` / `sh_add_section` / `sh_add_restriction` / `sh_add_intersection` → slot index `u32`, or `SHEAF_SENT` if full (sentinel-typed value, W12). Idempotent: a duplicate key returns the existing slot.
- `sh_find_open` / `sh_find_section` / `sh_find_restriction` / `sh_find_intersection` → slot index `u32`, or `SHEAF_SENT` if absent.
- `sh_section_id` → `SHEAF_OK` / `SHEAF_E_BAD_SLOT` (W9, compared `==`/`!=` only).
- `sh_restrict` → `SHEAF_OK` / `SHEAF_E_BAD_SLOT` / `SHEAF_E_NO_RESTRICT` (W9).
- `sh_check_glue` → `1u8` if the family glues (and `out_global` is written), `0u8` otherwise (W10). Never writes `out_global` on a non-glue.

> **API divergence from gospel candidate (documented):** `sh_check_glue` originally took `(presheaf_id: *u8, cover_slots: *u32, n: u64, parent_open: u32, out_global: *u8)` — **5 parameters**, violating **W2 (≤4)**. The maximal fix aggregates the cover description behind a single pointer to a `SHEAF_CoverReq` record (W2 "pass an aggregate by pointer"), giving `sh_check_glue(cover: *u8, parent_open: u32, out_global: *u8)`. The aggregate carries `presheaf_id` (32 bytes), `n` (u64), and the inline `cover_slots[n]` (u32 each). The helper `sh_global_section` is internal (not `@export`) and is likewise refactored to take the aggregate. This is the only signature change; all eleven other public signatures are byte-identical to the gospel header.

## Constant Namespace

**PREFIX = `SHEAF_`** (dispatch-assigned). **Grep result:** `^const SHEAF_` and `^const SH_` both return **zero matches** across `STDLIB/iii/**` — no collision either way.

> **PREFIX divergence (documented):** the gospel candidate uses the shorter `SH_` const prefix and `sh_*` function names. Per Trap 2, only **module-level `const`** declarations become linker-global symbols (`L_<NAME>`); function `@export` names are the cross-module call contract. Therefore: **constants are renamed to the dispatch-assigned `SHEAF_` prefix** (zero collision risk, satisfies the wave scheduler's bookkeeping), while **public function names remain `sh_*`** exactly as the gospel header specifies them (they are the API other modules link against — renaming would break the contract). The `SHEAF_`-prefixed consts are listed below.

| const | type | value |
|---|---|---|
| `SHEAF_OK` | `i32` | `0i32` |
| `SHEAF_E_FULL` | `i32` | `-1i32` |
| `SHEAF_E_BAD_SLOT` | `i32` | `-2i32` |
| `SHEAF_E_NO_RESTRICT` | `i32` | `-3i32` |
| `SHEAF_E_NO_INTERSECT` | `i32` | `-4i32` |
| `SHEAF_E_GLUE_FAIL` | `i32` | `-5i32` |
| `SHEAF_MAX_OPEN` | `u32` | `2048u32` |
| `SHEAF_MAX_SECTION` | `u32` | `8192u32` |
| `SHEAF_MAX_RESTRICT` | `u32` | `8192u32` |
| `SHEAF_MAX_INTER` | `u32` | `4096u32` |
| `SHEAF_MAX_COVER` | `u32` | `1024u32` |
| `SHEAF_IDBYTES` | `u64` | `32u64` |
| `SHEAF_SENT` | `u32` | `0xFFFFFFFFu32` |

`SHEAF_MAX_COVER = 1024` is new (the candidate had no explicit cover bound — see Gap §). It matches the established `MK_MAX_LEAVES = 1024` bound in `merkle.iii`, so the cover-concat scratch buffer is `1024 * 32 = 32768` bytes, identical to merkle's level buffers.

## Data Structures

All slot tables are statically sized module-scope arrays (W8). No local `var` arrays (Trap 7) — the four scratch buffers the candidate declared inside function bodies are hoisted to module scope here.

| name | type | size | bound justification (W8) |
|---|---|---|---|
| `SH_OPEN_LIVE` | `[u8; 2048]` | 2048 | `SHEAF_MAX_OPEN` open sets; constitutional bound on a finite base topology. |
| `SH_OPEN_ID` | `[u8; 65536]` | 2048×32 | one 32-byte identifier per open slot. |
| `SH_OPEN_PARENT` | `[u32; 2048]` | 2048 | parent open slot (or `SHEAF_SENT`). |
| `SH_SEC_LIVE` | `[u8; 8192]` | 8192 | `SHEAF_MAX_SECTION` (presheaf, open)→section bindings; allows ~4 coexisting presheaves over a full open base. |
| `SH_SEC_PRESHF` | `[u8; 262144]` | 8192×32 | presheaf identifier per section slot. |
| `SH_SEC_OPEN` | `[u32; 8192]` | 8192 | open slot the section lives over. |
| `SH_SEC_ID` | `[u8; 262144]` | 8192×32 | 32-byte section identifier. |
| `SH_RES_LIVE` | `[u8; 8192]` | 8192 | `SHEAF_MAX_RESTRICT`; one per registered inclusion `(parent,child)`. |
| `SH_RES_PARENT` | `[u32; 8192]` | 8192 | parent open slot. |
| `SH_RES_CHILD` | `[u32; 8192]` | 8192 | child open slot. |
| `SH_RES_XFORM` | `[u8; 262144]` | 8192×32 | 32-byte transform identifier (names the deterministic restriction fn). |
| `SH_INT_LIVE` | `[u8; 4096]` | 4096 | `SHEAF_MAX_INTER`; canonical unordered pair → intersection open slot. |
| `SH_INT_A` | `[u32; 4096]` | 4096 | first member (canonical: smaller slot first). |
| `SH_INT_B` | `[u32; 4096]` | 4096 | second member. |
| `SH_INT_INTER` | `[u32; 4096]` | 4096 | the intersection open slot `U_a ∩ U_b`. |
| `SH_IDS_BUF` | `[u8; 32768]` | 1024×32 | **(hoisted from local `ids_buf`)** sorted-concat scratch for the global section; bounded by `SHEAF_MAX_COVER`. Mirrors `merkle.iii`'s `MK_LEVEL_A`. |
| `SH_SWAP_BUF` | `[u8; 32]` | 32 | **(hoisted from local `swap_buf`)** one-identifier swap temp for the insertion sort. |
| `SH_R_I` | `[u8; 32]` | 32 | **(hoisted from local `r_i`)** restricted-section temp for `s_i` in the overlap check. |
| `SH_R_J` | `[u8; 32]` | 32 | **(hoisted from local `r_j`)** restricted-section temp for `s_j`. |
| `SH_HASH_BUF` | `[u8; 96]` | 96 | **(new)** 3×32 concat scratch for `sh_restrict` (`section_id‖transform_id‖child_open_id`), mirroring `content_addr.iii`'s `CA_BUF`. |
| `SH_ST_*` (selftest) | `[u8; 32]` ×~8 | — | KAT scratch identifiers/outputs for `sh_selftest`. |

> **Reentrancy note (Trap 7 consequence):** hoisting scratch buffers to module scope makes the hashing/sort paths **non-reentrant**, which is acceptable per the trap catalog for serialized hashing — `identifier.iii`, `content_addr.iii`, `keccak256.iii`, and `merkle.iii` all do exactly this. The whole module is a single-threaded deterministic verifier; no concurrent `sh_*` call is supported, and that constraint is documented in the header.

## Dependencies (externs)

| extern signature | providing module | NN | status |
|---|---|---|---|
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | `identifier.iii` | 01 | **BUILT** |
| `fn ident_cmp(a: *u8, b: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** |
| `fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32` | `keccak256.iii` | (Stage-4) | **BUILT** |

> **CORRECTED from gospel candidate.** The candidate declared seven externs, three of which were broken:
> - `ident_from_bytes` — declared but **never called** in the body; dropped (dead import).
> - `keccak256_init` / `keccak256_update` / `keccak256_final` `from "keccak.iii"` — **`keccak.iii` exports none of these** (it exports `keccak_state_zero`, `keccak_f1600`, `keccak_absorb`, `keccak_pack_rate_dom`, `keccak_squeeze`). The streaming triple actually lives in **`keccak256.iii`**, and even there the substrate-wide convention (documented verbatim in `identifier.iii` and `content_addr.iii` headers) is: *"gospel uses streaming `keccak256_init/update/final` over param pointers; iiis clobbers param registers across the `init()` call, so the inputs are concatenated into a buffer and hashed with `keccak256_oneshot`."* This spec adopts that exact reconciliation — **one extern, `keccak256_oneshot`**, over module-scope concat buffers.

**Conceptual base — `category.iii` (Module 09):** the gospel frames sheaf's base as "a category whose objects are open sets and whose morphisms are inclusions." `category.iii` (NOT YET BUILT) provides that category abstraction (`cat_add_object`, `cat_add_morphism`, `cat_compose`, `cat_pullback`, …). **However, the candidate body — and this spec — realize the open-set/inclusion/intersection base self-containedly** (open slots, restriction-map slots, intersection slots) rather than threading every open set through `category.iii`. There is therefore **no hard extern dependency on `category.iii`**: it is the conceptual base and an optional future integration point (e.g., deriving intersections from `cat_pullback`), not a build-blocking import. **The wave scheduler may build Module 10 without waiting for Module 09.** All four hard deps are already BUILT.

## Algorithm

Determinism (M2) holds throughout because every operation is a linear scan of fixed arrays in fixed order, equality tests on bytes, byte copies, and a single deterministic hash; there is no time, randomness, float, or data-dependent ordering beyond the canonicalizing sort. Bit-identity (W5) holds because section/transform/open identifiers are the reproducible representation and the global section is `Keccak256` of a **canonically sorted** concatenation. No ML/heuristics (M3/M4): the sheaf condition is the exact pairwise-overlap-agreement predicate, not a threshold. NIH (M1): the only algorithm pulled in is Keccak256 from the substrate's own `keccak256.iii`. No recursion (W15): all loops are explicit `while` counters; the insertion sort uses two module-scope-style index counters, not the call stack.

**`sh_init`** — Zero the four `*_LIVE` arrays (`SH_OPEN_LIVE`, `SH_SEC_LIVE`, `SH_RES_LIVE`, `SH_INT_LIVE`) with four independent `while i < SHEAF_MAX_*` loops. Return `SHEAF_OK`. (Live arrays are the only state that must be cleared; payload arrays are write-before-read gated by the live flag.)

**`sh_find_open(open_id, parent)`** — Linear scan `i` over `[0, SHEAF_MAX_OPEN)`; for each live slot, if no match yet (`found == SHEAF_SENT`) and `ident_eq(slot_id, open_id) == 1u8`, set `found = i`. The nested "only test while `found == SENT`" structure is a **sentinel loop (W14)** — it visits all slots without `break`, but does the equality work only until the first match, giving deterministic first-match semantics. Return `found`.

**`sh_add_open(open_id, parent)`** — Idempotent: `existing = sh_find_open(open_id)`; if `existing != SHEAF_SENT` return it. Else scan for the first `SH_OPEN_LIVE[i] == 0`, `ident_copy` the id in, store `SH_OPEN_PARENT[i] = parent`, set live, return `i`. Return `SHEAF_SENT` if full (W12 sentinel). The parent slot is stored but not validated against `SHEAF_MAX_OPEN` here (callers pass `SHEAF_SENT` for a root open set); validation, if needed, is the caller's via `sh_find_open`.

**`sh_find_section` / `sh_add_section`** — Keyed on the pair `(presheaf_id, open_slot)`. `find` scans live section slots, matches `SH_SEC_OPEN[i] == open_slot` then `ident_eq(presheaf_ptr, presheaf_id)`, first-match via the `found == SENT` gate (W14). `add` is idempotent **with update semantics**: a duplicate `(presheaf, open)` overwrites the stored section id (a presheaf may revise the data over an open set) and returns the existing slot; otherwise allocate a fresh slot. Distinct `presheaf_id`s coexist over the same open set — this is how multiple presheaves share one base topology.

**`sh_section_id(slot, out)`** — Bounds-guard `slot >= SHEAF_MAX_SECTION` → `SHEAF_E_BAD_SLOT`; liveness-guard `SH_SEC_LIVE[slot] == 0` → `SHEAF_E_BAD_SLOT`; else `ident_copy` the stored id to `out`, return `SHEAF_OK`.

**`sh_find_restriction` / `sh_add_restriction`** — Keyed on the ordered pair `(parent, child)` (direction matters: restriction goes parent→child). `find` first-matches `SH_RES_PARENT[i]==parent && SH_RES_CHILD[i]==child`. `add` is idempotent with transform-update semantics. A restriction map's identity is its `transform_id` (per gospel: "two restriction maps are equal iff their identifiers are equal").

**`sh_find_intersection` / `sh_add_intersection`** — Keyed on the **unordered** pair `{a, b}`. `find` matches either `(A==a && B==b)` or `(A==b && B==a)` (the candidate's both-orders test, kept). `add` stores canonically with the **smaller slot first** (`if a <= b` store `(a,b)`; `if a > b` store `(b,a)`) so the table has one canonical entry per unordered pair and ordering is bit-identical regardless of argument order (W5). Stores `SH_INT_INTER[i] = inter`.

**`sh_restrict(section, parent, child, out)`** — The deterministic restriction transform. Guards: `section >= SHEAF_MAX_SECTION` or dead → `SHEAF_E_BAD_SLOT`. Look up `res = sh_find_restriction(parent, child)`; if `SHEAF_SENT` → `SHEAF_E_NO_RESTRICT` (refusal, not a guess — M4). Then compute `out = Keccak256(section_id ‖ transform_id ‖ child_open_id)`:
1. Copy the three 32-byte slices into `SH_HASH_BUF` (offsets 0, 32, 64) with a single `while k < 32u64` loop, exactly like `content_addr.iii`'s `ca_compute`.
2. `keccak256_oneshot(&SH_HASH_BUF as u64, 96u64, out as u64)`.
3. Return `SHEAF_OK`.
This replaces the candidate's three streaming calls (`keccak256_init/update/final`) — same mathematical result, but **trap-free** (one call, no param-register clobber across calls; Trap 11 avoided).

**`sh_global_section(cover_aggregate, out)`** (internal helper) — Canonical, order-independent global witness:
1. **Collect:** for each of the `n` cover entries (`n <= SHEAF_MAX_COVER`, else `SHEAF_E_BAD_SLOT`), read `open_slot = cover_slots[k]`, find its section slot via `sh_find_section(presheaf_id, open_slot)`; if absent → `SHEAF_E_BAD_SLOT`. Copy the 32-byte section id into `SH_IDS_BUF[k*32 ..]` with a byte loop (no `*u32` wide-store; only `*u8` byte copies — Traps 4/5 avoided).
2. **Sort:** in-place insertion sort of the `n` 32-byte records by `ident_cmp` (lexicographic; `ident_cmp` returns `-1/0/1`, compared with `== 1i32` only — W11/Trap 3). The inner loop drives its own counter: `while q > 0`, compare `(q-1)` vs `q`; on `c == 1i32` swap the 32 bytes through `SH_SWAP_BUF` and `q = q - 1`; on `c != 1i32` set `q = 0` to terminate the run (sentinel loop, no `break` — W14; this is the documented `insertion-sort active-flag-drives-the-condition` shape).
3. **Hash:** `keccak256_oneshot(&SH_IDS_BUF as u64, n*32u64, out as u64)`. Because the input is sorted, the witness is independent of the cover's supplied order — no `s_i` is privileged (M2/W5). Return `SHEAF_OK`.

**`sh_check_glue(cover, parent_open, out_global)`** — The sheaf condition. Read `presheaf_id`, `n`, and `cover_slots[]` from the aggregate; guard `n <= SHEAF_MAX_COVER`. `ok = 1u8`. Double loop `i` over `[0,n)`, `j` over `[i+1,n)`, all work gated by `if ok == 1u8` (sentinel — a single disagreement latches `ok=0` and the remaining iterations no-op without `break`; W14). For each pair:
1. `u_i = cover_slots[i]`, `u_j = cover_slots[j]`.
2. `int_slot = sh_find_intersection(u_i, u_j)`.
   - **CORRECTED (Gap §):** if `int_slot == SHEAF_SENT`, the pair has **no registered intersection**. Per the gospel ("constructed if not already present") a missing intersection is **not vacuous agreement**. The maximal-correct behavior is **refusal**: set `ok = 0u8` (the family cannot be certified to glue without a defined overlap). The candidate silently skipped such pairs — a soundness hole that would falsely glue families over an incompletely-specified base. (Auto-construction of the intersection open set is out of scope for the verifier — building a new open slot from inside the check would mutate the base mid-verification and is non-deterministic w.r.t. caller intent; refusal is the conservative, reversible choice, M5/M9.)
   - if `int_slot != SHEAF_SENT`: `inter = SH_INT_INTER[int_slot]`; `sec_i = sh_find_section(presheaf_id, u_i)`, `sec_j = sh_find_section(presheaf_id, u_j)`; if either is `SHEAF_SENT` set `ok=0`. Else `sh_restrict(sec_i, u_i, inter, &SH_R_I)` and `sh_restrict(sec_j, u_j, inter, &SH_R_J)`; if either returns `!= SHEAF_OK` set `ok=0`; else if `ident_eq(&SH_R_I, &SH_R_J) == 0u8` set `ok=0` (overlap disagreement).
3. After both loops: `if ok == 1u8` call `sh_global_section(cover, out_global)`. Return `ok`. `out_global` is written **only** on a full glue (never on refusal) — a caller seeing `0u8` must not read it.

**Witness continuity / reproducibility (M6/M10):** the global section identifier is a pure function of the sorted multiset of input section identifiers, hence byte-recomputable from the recorded cover by any verifier (M10). The restriction witness `Keccak256(section‖transform‖child)` is likewise reproducible from the three recorded 32-byte inputs. These are the chainable witness fragments this module contributes (W16: produced under reversibility — no input is consumed or mutated).

## KAT Vectors (>= 3)

All vectors assume `sh_init()` first. Open ids `O0,O1,O2` and presheaf id `P`, transform id `T`, section ids `SA,SB` are distinct fixed 32-byte patterns (e.g. `O0 = 0x00*32`, `O1 = 0x01*32`, `O2 = 0x02*32`, `T = 0x77*32`, `P = 0x50*32`).

**KAT-1 — restriction is deterministic & equals the documented formula.**
Setup: `o0=sh_add_open(O0, SENT)`, `o1=sh_add_open(O1, o0)`, `s=sh_add_section(P, o0, SA)`, `sh_add_restriction(o0, o1, T)`.
Call: `sh_restrict(s, o0, o1, OUT)`.
Expected: `SHEAF_OK`, and `OUT == Keccak256(SA ‖ T ‖ O1)` — i.e. byte-equal to the reference `keccak256_oneshot` of the 96-byte buffer `SA‖T‖O1`. Re-invoking `sh_restrict` yields a byte-identical `OUT` (determinism). Concretely the test recomputes the reference via the same `keccak256_oneshot` and asserts all 32 bytes match; first byte is non-zero for these inputs (sanity).

**KAT-2 — glue succeeds on agreeing overlaps; global section is order-independent.**
Setup: opens `o0,o1,o2`; intersection `o01 = sh_add_open(O01,SENT)`, `sh_add_intersection(o0,o1,o01)`; restrictions `(o0,o01,T)` and `(o1,o01,T)`. Sections over `o0` and `o1` chosen so their restrictions to `o01` agree — simplest construction: register the **same** section id `SA` over both `o0` and `o1` and the **same** transform `T` for both inclusions, so `sh_restrict(_,o0,o01)=Keccak256(SA‖T‖O01)=sh_restrict(_,o1,o01)`.
Call A: cover `{o0, o1}` → `sh_check_glue(...) == 1u8`, `out_global` written.
Call B: cover `{o1, o0}` (reversed) → `sh_check_glue(...) == 1u8`.
Expected: both return `1u8` AND the two `out_global` buffers are **byte-identical** (sorted-concat canonicality). Reference value: `out_global == Keccak256(min(SA,SA)‖max(SA,SA)) = Keccak256(SA‖SA)` via `keccak256_oneshot` over the 64-byte buffer.

**KAT-3 — glue fails on disagreement (negative case, proves the gate refuses).**
Setup as KAT-2 but register **different** section ids `SA` over `o0` and `SB` over `o1` (with `SA != SB`), keeping a single transform `T` so the restrictions `Keccak256(SA‖T‖O01)` and `Keccak256(SB‖T‖O01)` differ.
Call: `sh_check_glue({o0,o1}, ...)`.
Expected: returns `0u8`, and `out_global` is left **untouched** (the test pre-fills `out_global` with a poison pattern `0xEE*32` and asserts it is unchanged).

**KAT-4 — missing-intersection refusal (proves the §Gap fix).**
Setup: opens `o0,o1` and sections over both, but **no** `sh_add_intersection` call for `{o0,o1}`.
Call: `sh_check_glue({o0,o1}, ...)`.
Expected: returns `0u8` (the corrected behavior; the original candidate would wrongly return `1u8`). `out_global` untouched.

**KAT-5 — idempotent add & sentinel-on-full.**
`sh_add_open(O0,SENT)` twice returns the same slot. `sh_add_restriction(o0,o1,T)` then again with `T2` returns the same slot with the transform updated (verify via a subsequent `sh_restrict` reflecting `T2`). (A full-table vector is optional given the 2048/8192 bounds; the sentinel path is exercised structurally.)

`sh_selftest() -> u64` returns `99u64` on all-pass, else the index of the first failing assertion (house convention, per `ident_selftest`).

## Trap Exposure

| Trap | Exposed? | Avoidance |
|---|---|---|
| **1. Multi-line `fn` decl** | YES (12 sigs) | Every signature is single-line. The candidate's `sh_global_section` and `sh_check_glue` wrapped across two lines — **both rewritten single-line** in the skeleton (the aggregate refactor also shortens them under the column budget). |
| **2. Module-level `const` linker-global** | YES (13 consts) | All consts carry the `SHEAF_` prefix; grep confirms zero collision with existing `STDLIB/` symbols (and zero collision for the legacy `SH_` too). |
| **3. Signed-int ordering compare SIGSEGV** | YES | `ident_cmp` returns `i32` ∈ {-1,0,1}; every test is `== 1i32` / `== 0i32` / `!= 1i32` — **never `<`/`>`/`>=` on a signed int**. All error-code checks are `== SHEAF_OK` / `!= SHEAF_OK`. (The candidate already obeyed this; preserved.) |
| **4. u32-in-u64-slot garbage** | YES | `cover_slots[k]` yields a `u32` open slot used in pointer math `SH_IDS_BUF[k*32 + …]` only via `k:u64` loop counters; slot values themselves index `*_LIVE`/payload arrays directly (array index, not raw pointer arithmetic). Where a slot crosses into an address (none required after refactor), mask `(x as u64) & 0xFFFFFFFFu64`. |
| **5. u32 pointer store width** | YES | All identifier writes go byte-by-byte through `*u8` (`ident_copy`, the collect/swap loops). **No `*u32` store of a u32 local** anywhere — the `SH_*_PARENT/CHILD/A/B/INTER` arrays are `[u32; N]` written by direct indexed assignment of `u32` values (not via a `*u32` pointer), which is the safe form used throughout `bigint.iii`/`category.iii`. |
| **6. Nested `/* */`** | NO | Header and inline comments are flat; any inner annotation uses `//` or `(...)`. |
| **7. Local `var` arrays** | **YES — primary fix** | The candidate declared `ids_buf [u8;32768]`, `swap_buf [u8;32]`, `r_i [u8;32]`, `r_j [u8;32]` **inside fn bodies** — unsupported. **All four hoisted to module scope** (`SH_IDS_BUF`, `SH_SWAP_BUF`, `SH_R_I`, `SH_R_J`) plus the new `SH_HASH_BUF`. Non-reentrancy documented (matches `merkle.iii`/`content_addr.iii`). |
| **8. `} else {` one line** | LOW | The candidate uses no `else` (all-`if` style). The skeleton keeps that style; any `else` introduced in Phase 2 must be `} else {` on one line. |
| **9. Em-dash in comments** | YES (prose-heavy header) | All comments use ASCII `--`; no U+2014. The header is rewritten ASCII-only. |
| **10. `let mut … = 0u32` checkpoint-flag** | LOW | The `found`/`ok` flags are the find/glue accumulators, not checkpoint flags; they drive their loops' work directly (W14 sentinel), which is the sanctioned shape, not the misbehaving one. |
| **11. `a % b` after a call** | NO | The module performs **no modulo**. (Offsets are `k * 32u64` multiplies; intersection canonicalization is `<=`/`>` on `u32` *slot indices* — unsigned, not the signed-i32 trap.) The streaming-Keccak **param-spill family** that motivated Trap 11 is sidestepped by using `keccak256_oneshot` over a single contiguous buffer. |
| **12. `@specialize *T` stride** | NO | No generics; every element stride is an explicit `* 32u64` byte offset. |

## Gap / Fix List

The candidate is PARTIAL. Each defect with its fix:

1. **[SHOWSTOPPER · Dep mis-source] Externs `keccak256_init/update/final from "keccak.iii"`.** `keccak.iii` exports none of these symbols → link failure. **Fix:** drop all three; add the single extern `keccak256_oneshot(msg_ptr:u64, msg_len:u64, out_ptr:u64) -> i32 from "keccak256.iii"`.
2. **[SHOWSTOPPER · Trap 11 / param-spill] Streaming Keccak across param-pointer calls.** Even sourced correctly, the streaming triple clobbers param registers across `init()` — the documented reason `identifier.iii`/`content_addr.iii` abandoned it. **Fix:** in `sh_restrict`, concat `section_id‖transform_id‖child_open_id` into module-scope `SH_HASH_BUF[96]` then one `keccak256_oneshot(...,96u64,...)`. In `sh_global_section`, the sorted ids already sit contiguously in `SH_IDS_BUF`; hash with one `keccak256_oneshot(..., n*32u64, ...)`. (Mathematically identical to the gospel formulas.)
3. **[SHOWSTOPPER · Trap 7] Four local `var` arrays inside fn bodies** (`ids_buf`, `swap_buf`, `r_i`, `r_j`). **Fix:** hoist to module scope as `SH_IDS_BUF`, `SH_SWAP_BUF`, `SH_R_I`, `SH_R_J`; document non-reentrancy.
4. **[W2 violation] `sh_check_glue` has 5 parameters** (`presheaf_id, cover_slots, n, parent_open, out_global`). **Fix:** aggregate `(presheaf_id, n, cover_slots[])` behind a single `cover: *u8` (the `SHEAF_CoverReq` record) → 3 params. `sh_global_section` likewise. (Only API change; documented in §Public API.)
5. **[Trap 1] `sh_global_section` and `sh_check_glue` signatures wrap two lines** in the candidate. **Fix:** single-line (the W2 refactor makes them fit).
6. **[Soundness gap · M2/M4] `sh_check_glue` silently skips pairs with no registered intersection** (`if int_slot != SH_SENT { … }` with no else). A cover over a base whose overlaps are not all declared would **falsely glue**. **Fix:** missing intersection latches `ok = 0u8` (refusal). Verified by KAT-4.
7. **[Bound gap · W8] No explicit cover-size bound.** The candidate's `ids_buf` was `[u8;32768]` (implicitly 1024 ids) but `n` was unguarded → overflow if `n > 1024`. **Fix:** add `SHEAF_MAX_COVER = 1024u32`; guard `n <= SHEAF_MAX_COVER` (else `SHEAF_E_BAD_SLOT`) in `sh_global_section` and `sh_check_glue`. Matches `merkle.iii`'s `MK_MAX_LEAVES`.
8. **[Const prefix] Candidate uses `SH_` not the dispatch-assigned `SHEAF_`.** **Fix:** rename all consts to `SHEAF_*` (functions stay `sh_*`, the link contract). Documented in §Constant Namespace.
9. **[Dead import] `ident_from_bytes` declared but unused.** **Fix:** removed.
10. **[Comment hygiene · Trap 9] Header prose is em-dash / unicode heavy** (`⊆`, `∩`, `∘`, em-dashes). **Fix:** ASCII-only comments (`U subset V`, `Ui cap Uj`, `--`). The math symbols are fine in *this spec* (Markdown) but must not appear in the `.iii` source comments.
11. **[Witness completeness · M6, enhancement] `sh_restrict`/`sh_check_glue` produce witnesses but do not chain them.** For maximal M6 intent, Phase 2 *may* additionally emit a witness fragment binding `(parent_open, child_open, transform_id, section_in, section_out)` so the restriction is replayable in the witness log. **Marked as enhancement, not a build blocker** — the deterministic output already satisfies M10 reproducibility; explicit fragment emission depends on the witness-log module's API and is deferred to integration. Noted so the scheduler can wire it.

**No mandate is *violated* by the corrected design.** M1 (only libc-free substrate Keccak), M2/M5/M9 (pure, reversible, refuse-don't-brick), M3/M4 (exact predicate, no learning), M15 (total over the bit width), M19 (cost is bounded: `O(MAX_*)` scans, `O(n²)` overlap pairs with `n<=1024`, `O(n²·32)` sort) all hold.

## Implementation Skeleton

```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\sheaf.iii
 *
 * III STDLIB - numera::sheaf  (Layer 3, Module 10)
 *
 * Presheaves and sheaves over a base of open sets with inclusion
 * morphisms.  Base objects are open sets (32-byte ids); morphisms are
 * inclusions U subset V; the sheaf condition is checked explicitly on
 * pairwise overlaps Ui cap Uj.
 *
 * Open set slot:    32-byte id + live flag + parent slot (SENT if root).
 * Section slot:     (presheaf id, open slot) -> 32-byte section id.
 * Restriction slot: (parent open, child open, 32-byte transform id).
 * Intersection slot:(open a, open b) -> intersection open slot (canonical
 *                   unordered pair, smaller slot first).
 *
 * Hashing: keccak256_oneshot over a module-scope concat buffer (the
 * substrate-wide reconciliation of the gospel streaming API; the
 * streaming form clobbers param registers across init() -- see
 * identifier.iii / content_addr.iii headers).
 *
 * NON-REENTRANT: the scratch buffers (SH_IDS_BUF, SH_SWAP_BUF, SH_R_I,
 * SH_R_J, SH_HASH_BUF) are module-scope.  Single-threaded verifier only.
 *
 * Public API:
 *   sh_init() -> i32
 *   sh_add_open(open_id, parent_slot) -> u32 ; sh_find_open(open_id) -> u32
 *   sh_add_section(presheaf_id, open_slot, section_id) -> u32
 *   sh_find_section(presheaf_id, open_slot) -> u32
 *   sh_section_id(slot, out_id) -> i32
 *   sh_add_restriction(parent, child, transform_id) -> u32
 *   sh_find_restriction(parent, child) -> u32
 *   sh_add_intersection(a, b, inter) -> u32 ; sh_find_intersection(a,b) -> u32
 *   sh_restrict(section, parent, child, out_id) -> i32
 *   sh_check_glue(cover, parent_open, out_global) -> u8
 *     cover -> SHEAF_CoverReq { presheaf_id:[u8;32], n:u64, slots:[u32;n] }
 *
 * Hexad: kind_essence.  Ring: R0.  K: 0.99.
 * Discipline: W2 (<=4 params), W8, W9, W10, W12, W13, W14, W15.
 */

module numera_sheaf

extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"

const SHEAF_OK            : i32 =  0i32
const SHEAF_E_FULL        : i32 = -1i32
const SHEAF_E_BAD_SLOT    : i32 = -2i32
const SHEAF_E_NO_RESTRICT : i32 = -3i32
const SHEAF_E_NO_INTERSECT: i32 = -4i32
const SHEAF_E_GLUE_FAIL   : i32 = -5i32

const SHEAF_MAX_OPEN     : u32 = 2048u32
const SHEAF_MAX_SECTION  : u32 = 8192u32
const SHEAF_MAX_RESTRICT : u32 = 8192u32
const SHEAF_MAX_INTER    : u32 = 4096u32
const SHEAF_MAX_COVER    : u32 = 1024u32
const SHEAF_IDBYTES      : u64 = 32u64
const SHEAF_SENT         : u32 = 0xFFFFFFFFu32

var SH_OPEN_LIVE   : [u8;  2048]
var SH_OPEN_ID     : [u8;  65536]
var SH_OPEN_PARENT : [u32; 2048]

var SH_SEC_LIVE    : [u8;  8192]
var SH_SEC_PRESHF  : [u8;  262144]
var SH_SEC_OPEN    : [u32; 8192]
var SH_SEC_ID      : [u8;  262144]

var SH_RES_LIVE    : [u8;  8192]
var SH_RES_PARENT  : [u32; 8192]
var SH_RES_CHILD   : [u32; 8192]
var SH_RES_XFORM   : [u8;  262144]

var SH_INT_LIVE    : [u8;  4096]
var SH_INT_A       : [u32; 4096]
var SH_INT_B       : [u32; 4096]
var SH_INT_INTER   : [u32; 4096]

/* Hoisted scratch (Trap 7: no local var arrays) */
var SH_IDS_BUF     : [u8;  32768]   /* SHEAF_MAX_COVER * 32 sorted-concat */
var SH_SWAP_BUF    : [u8;  32]      /* insertion-sort swap temp */
var SH_R_I         : [u8;  32]      /* restricted s_i temp */
var SH_R_J         : [u8;  32]      /* restricted s_j temp */
var SH_HASH_BUF    : [u8;  96]      /* sh_restrict concat: sec||xform||child */

/* Selftest scratch */
var SH_ST_O0 : [u8; 32]
var SH_ST_O1 : [u8; 32]
var SH_ST_O01: [u8; 32]
var SH_ST_P  : [u8; 32]
var SH_ST_T  : [u8; 32]
var SH_ST_SA : [u8; 32]
var SH_ST_SB : [u8; 32]
var SH_ST_OUT: [u8; 32]
var SH_ST_REF: [u8; 32]
var SH_ST_COVER : [u8; 4128]        /* CoverReq: 32 id + 8 n + up to 1024*4 slots */

/* --- pointer helpers into the payload arrays (address-of-static stays in-file, W1/W3) --- */
fn sh_open_id_ptr(slot: u32) -> *u8 { return (&SH_OPEN_ID[(slot as u64) * 32u64]) as *u8 }
fn sh_sec_presheaf_ptr(slot: u32) -> *u8 { return (&SH_SEC_PRESHF[(slot as u64) * 32u64]) as *u8 }
fn sh_sec_id_ptr(slot: u32) -> *u8 { return (&SH_SEC_ID[(slot as u64) * 32u64]) as *u8 }
fn sh_res_xform_ptr(slot: u32) -> *u8 { return (&SH_RES_XFORM[(slot as u64) * 32u64]) as *u8 }

fn sh_init() -> i32 @export { return SHEAF_OK }  // TODO: body per Algorithm § (zero the 4 *_LIVE arrays)

fn sh_find_open(open_id: *u8) -> u32 @export { return SHEAF_SENT }  // TODO: sentinel scan, first-match (W14)
fn sh_add_open(open_id: *u8, parent_slot: u32) -> u32 @export { return SHEAF_SENT }  // TODO: idempotent insert; SENT if full

fn sh_find_section(presheaf_id: *u8, open_slot: u32) -> u32 @export { return SHEAF_SENT }  // TODO: key (presheaf,open)
fn sh_add_section(presheaf_id: *u8, open_slot: u32, section_id: *u8) -> u32 @export { return SHEAF_SENT }  // TODO: idempotent+update
fn sh_section_id(slot: u32, out_id: *u8) -> i32 @export { return SHEAF_E_BAD_SLOT }  // TODO: bounds+live guard, ident_copy out

fn sh_find_restriction(parent: u32, child: u32) -> u32 @export { return SHEAF_SENT }  // TODO: key (parent,child) ordered
fn sh_add_restriction(parent: u32, child: u32, transform_id: *u8) -> u32 @export { return SHEAF_SENT }  // TODO: idempotent+xform update

fn sh_find_intersection(a: u32, b: u32) -> u32 @export { return SHEAF_SENT }  // TODO: unordered pair, both orders
fn sh_add_intersection(a: u32, b: u32, inter: u32) -> u32 @export { return SHEAF_SENT }  // TODO: canonical smaller-first store

fn sh_restrict(section: u32, parent: u32, child: u32, out_id: *u8) -> i32 @export { return SHEAF_E_BAD_SLOT }  // TODO: SH_HASH_BUF concat + keccak256_oneshot(96)

fn sh_global_section(cover: *u8, out_id: *u8) -> i32 { return SHEAF_E_BAD_SLOT }  // TODO: collect->insertion-sort(SH_IDS_BUF)->keccak256_oneshot(n*32); n<=SHEAF_MAX_COVER

fn sh_check_glue(cover: *u8, parent_open: u32, out_global: *u8) -> u8 @export { return 0u8 }  // TODO: i<j overlap loop; missing-intersection => ok=0; glue => sh_global_section

fn sh_selftest() -> u64 @export { return 0u64 }  // TODO: KAT-1..5; return 99u64 on pass, else first-failing index
```
