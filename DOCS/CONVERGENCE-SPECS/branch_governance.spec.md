# 68 aether/branch_governance.iii — Implementation Spec

## Verdict
**PARTIAL** — the gospel candidate body is structurally close (init + 3 ceremonies, clean control flow) but contains TWO link-fatal extern-signature defects against already-built modules (`cap_verify` does not exist in the built `capability.iii`; `cons_find` is typed/checked wrong), uses forbidden function-local `var`-style arrays (Trap 7), and omits the governance witness fragment that its own header (`kind_witness`, W42, M6) mandates. All are closed below.

## Purpose
`aether_branch_governance` is the **operator-ceremony mediation layer** for branch lifecycle transitions (retire, merge-propose, merge-commit). It IS the constitutional gate that stands between an operator capability and the lower `numera/branch_anchor.iii` primitives: before any branch state changes it verifies (a) the caller holds a branch-ops capability, (b) the governing constitutional clause is ratified and present, and (c) — for merges — that branch_anchor's bisimulation proof-of-compatibility holds (W42). It owns no branch storage; it is a pure verify-then-delegate-then-witness ceremony module.
- **Hexad:** kind_motion + kind_witness
- **Ring:** R0
- **K-vector:** K = 1.00
- **Discipline:** Nine — M16 (branch ratifiability), W42 (no branch merge without proof of compatibility), M6/W16 (witness continuity over every governed transition).

## Public API
Public function names retain the gospel's `bg_*` contract (the documented external API; analogous to how the dependency keeps `ba_*`). Only module-level consts/vars/scratch take the `BGOV_` prefix (see Constant Namespace).

```
fn bg_init() -> i32 @export
fn bg_retire_branch(branch_id: *u8, operator_cap: u64) -> i32 @export
fn bg_merge_branch(req: *u8) -> i32 @export
fn bg_commit_merge(proposal_fid: *u8, operator_cap: u64) -> i32 @export
```

Return-status convention (W9/W12): every public fn returns `i32`; `BGOV_OK = 0i32`, all errors are negative `i32` (W9), compared only by `==`/`!=` (W11). Every public fn returns a status (W12).

**API changes from the gospel signatures (all mandatory, justified in Gap/Fix):**
1. `operator_cap` is **`u64`** (a capability id), not `*u8` — the built `capability.iii` represents caps as `u64` ids (`CAP_INVALID = 0u64`, `CAP_ENV_ROOT = 1u64`). The gospel's `*u8` is a link-fatal type error.
2. `bg_merge_branch` originally had **5 parameters** (`branch_id, canonical_target_fid, operator_cap, out_proposal_fid` = 4, but adding witness needs more) — it is at the W2 limit of 4. To stay within W2 *and* leave room to pass the cap as a scalar, the four pointer/scalar arguments are packed into a caller-supplied **`BGOV_MergeReq` aggregate passed by pointer** (`req: *u8`), per the briefing's "more → pass an aggregate by pointer" rule. Layout in Data Structures. (If Phase 2 confirms exactly 4 args still fit — `branch_id:*u8, canonical_target_fid:*u8, operator_cap:u64, out_proposal_fid:*u8` is 4 — it MAY instead use the flat 4-arg form `fn bg_merge_branch(branch_id: *u8, canonical_target_fid: *u8, operator_cap: u64, out_proposal_fid: *u8) -> i32 @export`. Both are W2-legal; the aggregate form is the safe default and is specified as canonical. The flat form is the documented fallback.)

## Constant Namespace
**PREFIX = `BGOV_`** . Grep of `STDLIB/` for `\bBGOV_` → **no files found** (no collision). The gospel body used prefix `BG_`; grep of `STDLIB/` for `\bBG_` also → no collision, but the dispatch assigns `BGOV_`, so every module-level constant/var is renamed `BG_*` → `BGOV_*`. (Renaming is required because Trap 2: module-level `const` emits a linker-global `L_<NAME>`; using the assigned unique prefix is the collision-avoidance contract.)

| name | type | value |
|---|---|---|
| `BGOV_OK` | i32 | `0i32` |
| `BGOV_E_NULL` | i32 | `-1i32` |
| `BGOV_E_CLAUSE_ABSENT` | i32 | `-2i32` |
| `BGOV_E_CAP_DENIED` | i32 | `-3i32` |
| `BGOV_E_NOT_INITED` | i32 | `-4i32` |
| `BGOV_E_WITNESS` | i32 | `-5i32` (new: governance fragment emission failed) |
| `BGOV_CAP_RIGHT_BRANCH_OPS` | u64 | `0x4000u64` (== built `capability.iii` `CAP_RIGHT_AMEND`; branch lifecycle is an amend-class right) |
| `BGOV_CLAUSE_RETIRE_LEN` | u64 | `16u64` (byte length of `"cp_branch_retire"`) |
| `BGOV_CLAUSE_MERGE_LEN` | u64 | `15u64` (byte length of `"cp_branch_merge"`) |
| `BGOV_MERGEREQ_BYTES` | u64 | `104u64` (aggregate size: 3×32 ptr-targets are referenced by address, see Data Structures; the req itself stores 3 pointers + 1 u64 = 32 bytes — see note) |

Note on `BGOV_CAP_RIGHT_BRANCH_OPS`: the gospel used a bespoke `BG_CAP_KIND_BRANCH_OPS : u8 = 0x42u8` for a (nonexistent) kind-based `cap_verify`. The built capability model is a **rights bitmask**, not a kind enum. Branch retire/merge are amendment-class state changes, so the required right is `CAP_RIGHT_AMEND (0x4000)`. Phase 2 may instead mint a dedicated bit if the capability spec later reserves one for branch-ops (e.g. a future `0x80000` in the resolution-rights block); until then `AMEND` is the correct ratified-spec bit.

## Data Structures
All scratch is module-scope (Trap 7: function-local `var`/`let … : [u8; N]` arrays are unsupported; the gospel body's `let label`/`let mut clause_id` must be hoisted). The module is a **serialized operator ceremony** (one operator drives one ceremony at a time), so module-scope scratch is acceptable and **non-reentrancy is by design** — documented per Trap 7.

| name | type | fixed size | bound justification (W8) |
|---|---|---|---|
| `BGOV_INITED` | u8 | 1 | init flag |
| `BGOV_CLAUSE_LABEL` | [u8; 16] | 16 B | longest clause label `"cp_branch_retire"` is 16 bytes; `"cp_branch_merge"` (15) reuses the same buffer, length-limited by the `*_LEN` const. Built as ASCII byte literals (Trap 9: no em-dash; pure ASCII). |
| `BGOV_CLAUSE_ID` | [u8; 32] | 32 B | one 256-bit clause identifier (Keccak256 via `ident_from_bytes`); single ceremony in flight ⇒ one slot suffices. |
| `BGOV_W_PRODUCER` | [u8; 32] | 32 B | zero-id system producer for the governance witness fragment. |
| `BGOV_W_OP` | [u8; 32] | 32 B | zero-id op slot for the witness fragment. |
| `BGOV_W_INCOMMIT` | [u8; 32] | 32 B | in-commit = the branch_id (or proposal_fid) being governed. |
| `BGOV_W_OUTCOMMIT` | [u8; 32] | 32 B | out-commit = zero (governance attestation carries effect in payload). |
| `BGOV_W_PAYLOAD` | [u8; 48] | 48 B | governance fragment payload: 2-byte tag `0xE3 0x12` + 6 pad + 32-byte governed id + 8-byte ceremony discriminant. |
| `BGOV_W_FID` | [u8; 32] | 32 B | sink for the emitted fragment id (ignored by caller; chained internally). |

**`BGOV_MergeReq` aggregate (caller-allocated, passed as `req: *u8`)** — fixed 32-byte layout, little-endian:
| offset | size | field |
|---|---|---|
| 0 | 8 | `branch_id` pointer (as u64) |
| 8 | 8 | `canonical_target_fid` pointer (as u64) |
| 16 | 8 | `operator_cap` (u64 id) |
| 24 | 8 | `out_proposal_fid` pointer (as u64) |
`BGOV_MERGEREQ_BYTES` is therefore **32**, not 104 (the 104 figure was a miscount; corrected here). The pointed-to id buffers (32 bytes each) live in caller memory. Reads of the three pointer fields apply Trap 4 masking (`& 0xFFFFFFFFFFFFFFFFu64` is a no-op for u64, but each field is loaded as a full u64 — no u32-in-u64 hazard here since every field is natively 8 bytes).

## Dependencies (externs)
All externed by basename (house style: `from "<basename>.iii"`).

| extern signature | provider | NN | built? |
|---|---|---|---|
| `fn ident_zero(out: *u8) -> i32` | numera/identifier.iii | 01 | **built** ✓ (verified signature match) |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | numera/identifier.iii | 01 | **built** ✓ |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | numera/identifier.iii | 01 | **built** ✓ |
| `fn cap_verify_rights(id: u64, required: u64) -> u8` | aether/capability.iii | (built) | **built** ✓ (REPLACES gospel's nonexistent `cap_verify`) |
| `fn cons_find(clause_id: *u8) -> u32` | numera/constitution.iii | 13 | **NOT built** (return type `u32`, sentinel `0xFFFFFFFFu32`) |
| `fn ba_retire(branch_id: *u8) -> i32` | numera/branch_anchor.iii | 57 | **NOT built** |
| `fn ba_merge_propose(branch_id: *u8, canonical_target_fid: *u8, out_proposal_fid: *u8) -> i32` | numera/branch_anchor.iii | 57 | **NOT built** |
| `fn ba_merge_commit(proposal_fid: *u8) -> i32` | numera/branch_anchor.iii | 57 | **NOT built** |
| `fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32` | numera/witness_spine.iii | (Layer 2) | **NOT built** (added for M6/W16 governance witness; same signature branch_anchor uses) |

**Not-yet-built dependencies (wave-ordering): 3 modules — `numera/branch_anchor.iii` (57), `numera/constitution.iii` (13), `numera/witness_spine.iii`.** (`identifier.iii` and `capability.iii` are already built.) `ident_eq` from the gospel externs is **dropped** — branch_governance never compares identifiers itself; the dependency does. The gospel's `cap_verify` extern is **removed entirely** (it names a function that does not exist).

`ident_dependency note from dispatch`: Module 57 (branch_anchor) is the named parallel dependency; this spec consumes its gospel API verbatim (`ba_retire`, `ba_merge_propose`, `ba_merge_commit`), which I verified against Module 57's gospel section.

## Algorithm

Determinism (M2) / bit-identity (W5): every path is a fixed sequence of pointer-null checks, one capability bitmask test, one clause-label materialization (`ident_from_bytes` = Keccak256, deterministic), one `cons_find` lookup, one delegated branch_anchor call, and one witness emission. No floats, no time-of-day branching, no counters that adapt (M3/M4). The clause labels are compile-time ASCII byte arrays ⇒ identical clause ids every run. No recursion anywhere (W15) — there are no loops at all in this module except the trivial scratch copies, which are bounded `while i < 32u64`/`< len` counters (W14 sentinel form, no `break`).

### `bg_init() -> i32`
1. `if BGOV_INITED == 1u8 { return BGOV_OK }` (idempotent; early-return, not a mutated checkpoint flag — Trap 10).
2. Zero `BGOV_W_PRODUCER`, `BGOV_W_OP`, `BGOV_W_OUTCOMMIT` via `ident_zero` (one-time setup of the constant witness-frame fields).
3. `BGOV_INITED = 1u8`; `return BGOV_OK`.

### `_bgov_check_clause(label_len: u64) -> i32` (internal helper, not exported)
Hand-rolled clause-presence gate (NIH M1). Precondition: caller has already filled `BGOV_CLAUSE_LABEL` with the ASCII clause name.
1. `ident_from_bytes(&BGOV_CLAUSE_LABEL[0], label_len, &BGOV_CLAUSE_ID[0])` → clause id = Keccak256(label).
2. `let slot : u32 = cons_find(&BGOV_CLAUSE_ID[0])`.
3. **Correct presence test (M4 exact, fixes the gospel bug):** `if slot == 0xFFFFFFFFu32 { return BGOV_E_CLAUSE_ABSENT }` — absence is the sentinel `CONS_SENT`, NOT "nonzero". Slot 0 is a *present* clause. `return BGOV_OK`. (Comparison is `==`/`!=` on a `u32`, no signed-ordering trap; sentinel is full-width `0xFFFFFFFFu32`, no 16-bit-null hazard — Trap; W11.)

### `_bgov_fill_label(which: u8)` (internal helper)
Writes the clause label bytes into `BGOV_CLAUSE_LABEL` from a compile-time choice. `which==0` ⇒ `"cp_branch_retire"` (16 B), `which==1` ⇒ `"cp_branch_merge"` (15 B). Bytes are assigned individually as `u8` literals (no local array literal needed). Returns nothing; deterministic.

### `bg_retire_branch(branch_id: *u8, operator_cap: u64) -> i32`
1. `if BGOV_INITED == 0u8 { return BGOV_E_NOT_INITED }`.
2. `if (branch_id as u64) == 0u64 { return BGOV_E_NULL }` (full u64 compare — Trap; not a 16-bit test).
3. **Capability gate (M8):** `if cap_verify_rights(operator_cap, BGOV_CAP_RIGHT_BRANCH_OPS) != 1u8 { return BGOV_E_CAP_DENIED }`. (`cap_verify_rights` returns `u8` 0/1; `operator_cap` passed as the native u64 id. This REPLACES the gospel's `cap_verify(operator_cap, kind) != 0i32`.)
4. `_bgov_fill_label(0u8)`; `let c : i32 = _bgov_check_clause(BGOV_CLAUSE_RETIRE_LEN)`; `if c != BGOV_OK { return c }`.
5. **Delegate (M16/W42 lower primitive):** `let r : i32 = ba_retire(branch_id)`; `if r != BGOV_OK { return r }`. (Propagate branch_anchor's own status verbatim; `==`/`!=` only.)
6. **Governance witness (M6/W16):** emit a `GOVERNANCE_RETIRE` fragment — `ident_copy(branch_id, &BGOV_W_INCOMMIT[0])`, fill `BGOV_W_PAYLOAD` (tag `0xE3 0x12`, governed id = branch_id, discriminant byte = `0x01` retire), `if ws_emit_fragment(&BGOV_W_PRODUCER[0], &BGOV_W_OP[0], &BGOV_W_INCOMMIT[0], &BGOV_W_OUTCOMMIT[0], &BGOV_W_PAYLOAD[0], 48u64, &BGOV_W_FID[0]) != 0i32 { return BGOV_E_WITNESS }`.
7. `return BGOV_OK`.

Reversibility (M5/M9): retirement is "no further appends," not destruction; the branch fragments remain in the spine, so the operation is non-bricking and the witness fragment makes it auditable/reversible by a counter-ceremony. The capability gate is the explicit privilege boundary (M8).

### `bg_merge_branch(req: *u8) -> i32`
1. `if BGOV_INITED == 0u8 { return BGOV_E_NOT_INITED }`.
2. `if (req as u64) == 0u64 { return BGOV_E_NULL }`.
3. Load the four fields from the aggregate (each a full 8-byte slot — no u32-in-u64 hazard, Trap 4): `branch_id` (off 0), `canonical_target_fid` (off 8), `operator_cap` (off 16), `out_proposal_fid` (off 24). Read pointer fields as u64 then cast to `*u8`.
4. `if branch_id_u64 == 0u64 { return BGOV_E_NULL }`; same for `canonical_target_fid` and `out_proposal_fid` (three full-u64 null checks).
5. **Capability gate (M8):** `if cap_verify_rights(operator_cap, BGOV_CAP_RIGHT_BRANCH_OPS) != 1u8 { return BGOV_E_CAP_DENIED }`.
6. `_bgov_fill_label(1u8)`; `let c : i32 = _bgov_check_clause(BGOV_CLAUSE_MERGE_LEN)`; `if c != BGOV_OK { return c }`.
7. **Delegate (W42 proof-of-compatibility lives here):** `let r : i32 = ba_merge_propose(branch_id, canonical_target_fid, out_proposal_fid)`; `if r != BGOV_OK { return r }`. `ba_merge_propose` internally runs `cg_bisimulate` and only writes a proposal when the bisimulation witness verifies — this IS the W42 compatibility proof. branch_governance never constructs a proposal that bypasses it.
8. **Governance witness:** `ident_copy(branch_id, &BGOV_W_INCOMMIT[0])`, payload discriminant `0x02` (merge-propose), governed id = branch_id, emit; `!= 0i32 ⇒ BGOV_E_WITNESS`.
9. `return BGOV_OK`.

### `bg_commit_merge(proposal_fid: *u8, operator_cap: u64) -> i32`
1. `if BGOV_INITED == 0u8 { return BGOV_E_NOT_INITED }`.
2. `if (proposal_fid as u64) == 0u64 { return BGOV_E_NULL }`.
3. **Capability gate (M8):** `if cap_verify_rights(operator_cap, BGOV_CAP_RIGHT_BRANCH_OPS) != 1u8 { return BGOV_E_CAP_DENIED }`.
4. **Delegate (W42 re-verified):** `let r : i32 = ba_merge_commit(proposal_fid)`; `if r != BGOV_OK { return r }`. `ba_merge_commit` calls `ba_verify_bisimulation` first, so a commit is impossible without a verified compatibility proof — double-gated (M16/W42).
5. **Governance witness:** `ident_copy(proposal_fid, &BGOV_W_INCOMMIT[0])`, payload discriminant `0x03` (merge-commit), governed id = proposal_fid, emit; `!= 0i32 ⇒ BGOV_E_WITNESS`.
6. `return BGOV_OK`.

Maximal-intent note: the gospel header says "the bisimulation witness verifies when applicable." branch_governance does NOT re-implement bisimulation (that would duplicate Module 57 and violate NIH/anti-bloat) — it ratifies by *requiring* the lower primitives that already enforce it, and adds the governance-layer witness fragment that records the operator's ratified ceremony. This is the correct division of labor for a Layer-6 governance module over a Layer-3 anchor.

## KAT Vectors (>= 3)
These are the Phase-2 acceptance gate. Because every state-changing path delegates to not-yet-built modules (57/13/witness_spine), the KATs are split into (A) gate-logic KATs runnable against stubbed/real deps, and (B) full-path KATs that activate once 57/13 land. All assert exact `i32` returns byte-for-byte.

1. **Not-inited refusal (M-gate, dep-free):** call `bg_retire_branch(&valid_branch_id, 1u64)` *before* `bg_init()` → expect `BGOV_E_NOT_INITED (-4i32)`. Then `bg_init()` → `0i32`. Proves the init guard fires (negative-case proof, not just the happy path).
2. **Null-pointer refusal (dep-free):** after `bg_init()`, `bg_retire_branch(0x0 as *u8, 1u64)` → `BGOV_E_NULL (-1i32)`; and `bg_merge_branch(0x0 as *u8)` → `BGOV_E_NULL (-1i32)`. Proves the W-null guards on both the scalar and the aggregate path.
3. **Capability-denied refusal (uses built capability.iii):** `cap_env_init()` → root cap id `1`. `let weak : u64 = cap_attenuate(1u64, CAP_RIGHT_FS_READ, 0u64)` (a child cap lacking `AMEND/0x4000`). `bg_retire_branch(&valid_branch_id, weak)` → `BGOV_E_CAP_DENIED (-3i32)`. Then with `cap_attenuate(1u64, 0x4000u64, 0u64)` (a cap that DOES carry the branch-ops right) the capability gate passes (proceeds to the clause check). Proves the capability gate FAILS on an insufficient cap and PASSES on a sufficient one — both directions.
4. **Clause-absent refusal (full path, activates with Module 13):** with a sufficient cap but `cons_init()` having ratified *no* `cp_branch_retire` clause, `bg_retire_branch(...)` → `BGOV_E_CLAUSE_ABSENT (-2i32)`. After `cons_ratify("cp_branch_retire", …)`, the same call proceeds to `ba_retire`. Proves the corrected `slot == 0xFFFFFFFFu32` test (a clause ratified into slot 0 must read as *present*, exercising the exact bug fixed from the gospel).
5. **Happy-path retire + witness (full path, activates with 57+13+witness_spine):** init all deps, ratify clause, construct a branch via `ba_construct`, hold a branch-ops cap → `bg_retire_branch(&bid, cap)` returns `0i32`, `ba`-side `BA_BRANCH_RETIRED[slot]==1`, and exactly one governance fragment with payload tag `0xE3 0x12` + discriminant `0x01` was appended to the spine (assert `ws` next-index advanced by 1 and the payload bytes match).

## Trap Exposure
| # | trap | exposed? | avoidance |
|---|---|---|---|
| 1 | multi-line `fn` decl | yes (every fn) | all signatures are single-line in the skeleton; no wrapping. |
| 2 | module-level `const` is linker-global | yes (10 consts) | every const prefixed `BGOV_` (grep-confirmed no collision); renamed from gospel `BG_`. |
| 3 | signed-int ordering compare SIGSEGV | yes (i32 status codes) | all status comparisons are `==`/`!=` against named sentinels (W11); never `<`/`>`/`>=`/`<=` on any `i32`. |
| 4 | u32-in-u64-slot garbage | minor | the only multi-byte loads are the 4 aggregate fields, each a *native* 8-byte slot; no u32 widened into pointer math. Pointer casts are `(x as u64) as *u8` from full-width slots. |
| 5 | u32 pointer-store width | no | no `*u32` stores; all payload/clause writes are byte-wise through `*u8`. |
| 6 | nested `/* */` | n/a | no nested block comments; inline notes use `//` or parentheses. |
| 7 | local `var` arrays unsupported | **YES (gospel violates)** | gospel's `let label : [u8;16]` and `let mut clause_id : [u8;32]` are function-local arrays — **hoisted to module-scope** `BGOV_CLAUSE_LABEL`/`BGOV_CLAUSE_ID` (+ witness scratch). Module is serialized single-ceremony ⇒ non-reentrant by design (documented). |
| 8 | `} else {` one line | n/a | no `else` branches in the design (all guards are early-return). |
| 9 | em-dash in comment | yes (comments) | all comments ASCII only; clause labels are ASCII byte literals; `--` used for dashes. |
| 10 | `let mut x=0` checkpoint flag | avoided | `bg_init` idempotency uses an early-return on `BGOV_INITED`, not a mutated in-function flag. |
| 11 | `%` after a call returns quotient | **not exposed** | the module performs no modulo anywhere. |
| 12 | `@specialize *T` stride | n/a | module is not generic; no `@specialize`. |

## Gap / Fix List
The candidate body is PARTIAL. Defects and fixes (each load-bearing):

1. **[LINK-FATAL, built-module mismatch] `cap_verify` does not exist.** Gospel externs `fn cap_verify(capability: *u8, required_kind: u8) -> i32 from "capability.iii"`. The built `aether/capability.iii` has **no `cap_verify`**; caps are `u64` ids and rights are `u64` bitmasks. **Fix:** extern `fn cap_verify_rights(id: u64, required: u64) -> u8`; change `operator_cap` param to `u64`; gate as `cap_verify_rights(operator_cap, BGOV_CAP_RIGHT_BRANCH_OPS) != 1u8`. Drop `BG_CAP_KIND_BRANCH_OPS:u8=0x42`; introduce `BGOV_CAP_RIGHT_BRANCH_OPS:u64=0x4000` (= `CAP_RIGHT_AMEND`). *(This is the dispatch-flagged class of systemic gospel extern defect, here against an already-built module — strictly worse than a not-yet-built mismatch.)*
2. **[SEMANTIC + TYPE BUG] `cons_find` checked wrong.** Gospel externs `cons_find(...) -> i32` and rejects on `!= 0i32`. The real constitution API (Module 13) returns **`u32`** with absence sentinel `CONS_SENT = 0xFFFFFFFFu32`; a *found* clause returns a slot index `0..1023`, so **slot 0 is a valid present clause** and the gospel's `!= 0` test both mis-types the return and wrongly rejects slot-0 clauses while wrongly accepting the sentinel as "present-ish." **Fix:** extern `cons_find(...) -> u32`; reject only on `slot == 0xFFFFFFFFu32`. *(Note: Module 57 `branch_anchor` makes the identical `cons_find -> i32`/`!= 0i32` error in its gospel body; flagged for that module's owner — out of scope to fix here, but our extern uses the correct `u32` form.)*
3. **[MANDATE GAP, M6/W16/Hexad] no governance witness emitted.** Header declares `kind_witness` and "every state transition is gated … W42 binds," but the body emits **zero** fragments — the operator ceremonies leave no chained provenance at the governance layer. **Fix:** extern `ws_emit_fragment` (the same primitive branch_anchor uses); after each successful delegate, emit a `GOVERNANCE_*` fragment (tag `0xE3 0x12`, governed id, ceremony discriminant 0x01/0x02/0x03). Add `BGOV_E_WITNESS (-5i32)` and the witness scratch buffers. This realizes the maximal `kind_motion + kind_witness` intent.
4. **[TRAP 7] function-local arrays.** `let label : [u8; 16]`, `let label : [u8; 15]`, `let mut clause_id : [u8; 32]` are local `var`-class arrays → unsupported. **Fix:** hoist to module-scope `BGOV_CLAUSE_LABEL[16]` + `BGOV_CLAUSE_ID[32]`, fill the label via per-byte assignment in `_bgov_fill_label`. Document non-reentrancy (serialized ceremony; acceptable).
5. **[W2 / API] `bg_merge_branch` arg pressure.** With `operator_cap` now a scalar `u64`, the 4-arg form `(branch_id, canonical_target_fid, operator_cap, out_proposal_fid)` is exactly at the W2=4 limit and is legal; this spec nonetheless makes the **`BGOV_MergeReq` aggregate-by-pointer** the canonical signature (briefing's preferred shape for parameter pressure and the most future-proof), with the flat 4-arg form documented as an equivalent fallback. Either is W2-compliant.
6. **[PREFIX] `BG_` → `BGOV_`.** All module-level consts/vars renamed to the dispatched `BGOV_` prefix (Trap 2 collision contract). Public *function* names stay `bg_*` (external contract; mirrors `ba_*`/`cap_*` house style where the fn prefix differs from the const prefix is NOT done — but here the gospel's documented public API is `bg_*` and renaming the linker-exported fn symbols would break callers like an operator-ceremony driver that binds `bg_retire_branch`; the safe choice is const-prefix-only rename). Flagged explicitly so Phase 2 and QA agree.
7. **[DROP] unused extern `ident_eq`.** Gospel externs `ident_eq` but the body never calls it (and shouldn't — identity comparison is the dependency's job). Removed to keep the extern set minimal and honest.

What is correct in the gospel body and preserved: idempotent early-return `bg_init`; per-pointer full-u64 null checks; the verify→clause→delegate ordering; pure-i32 negative error codes compared by equality; no recursion/loops/modulo; the delegate-don't-reimplement division of labor with Module 57.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/branch_governance.iii
 *
 * III STDLIB - aether::branch_governance
 *
 * Operator-ceremony mediation for branch lifecycle (retire / merge-
 * propose / merge-commit) under constitutional governance. Verifies the
 * caller's branch-ops capability, the governing clause's presence, and --
 * for merges -- delegates to branch_anchor whose bisimulation IS the W42
 * proof-of-compatibility. Every successful ceremony emits a governance
 * witness fragment (M6/W16).
 *
 * Public API:
 *   bg_init() -> i32
 *   bg_retire_branch(branch_id: *u8, operator_cap: u64) -> i32
 *   bg_merge_branch(req: *u8) -> i32        // req -> BGOV_MergeReq (32 B)
 *   bg_commit_merge(proposal_fid: *u8, operator_cap: u64) -> i32
 *
 * Hexad: kind_motion + kind_witness.  Ring: R0.  K: 1.00.
 *
 * NIH: depends on identifier.iii (built), capability.iii (built),
 *      constitution.iii, branch_anchor.iii, witness_spine.iii.
 *
 * Discipline Nine: M16, W42 (no merge without proof of compatibility),
 *   M6/W16 (governance witness over every transition). Serialized single
 *   ceremony -- module-scope scratch is non-reentrant by design (Trap 7).
 */

module aether_branch_governance

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> u32 from "constitution.iii"
extern @abi(c-msvc-x64) fn ba_retire(branch_id: *u8) -> i32 from "branch_anchor.iii"
extern @abi(c-msvc-x64) fn ba_merge_propose(branch_id: *u8, canonical_target_fid: *u8, out_proposal_fid: *u8) -> i32 from "branch_anchor.iii"
extern @abi(c-msvc-x64) fn ba_merge_commit(proposal_fid: *u8) -> i32 from "branch_anchor.iii"
extern @abi(c-msvc-x64) fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32 from "witness_spine.iii"

const BGOV_OK                  : i32 =  0i32
const BGOV_E_NULL              : i32 = -1i32
const BGOV_E_CLAUSE_ABSENT     : i32 = -2i32
const BGOV_E_CAP_DENIED        : i32 = -3i32
const BGOV_E_NOT_INITED        : i32 = -4i32
const BGOV_E_WITNESS           : i32 = -5i32

const BGOV_CAP_RIGHT_BRANCH_OPS : u64 = 0x4000u64
const BGOV_CONS_SENT            : u32 = 0xFFFFFFFFu32
const BGOV_CLAUSE_RETIRE_LEN    : u64 = 16u64
const BGOV_CLAUSE_MERGE_LEN     : u64 = 15u64

var BGOV_INITED       : u8 = 0u8

var BGOV_CLAUSE_LABEL : [u8; 16]
var BGOV_CLAUSE_ID    : [u8; 32]

var BGOV_W_PRODUCER   : [u8; 32]
var BGOV_W_OP         : [u8; 32]
var BGOV_W_INCOMMIT   : [u8; 32]
var BGOV_W_OUTCOMMIT  : [u8; 32]
var BGOV_W_PAYLOAD    : [u8; 48]
var BGOV_W_FID        : [u8; 32]

fn bg_init() -> i32 @export {
    // TODO: body per Algorithm bg_init -- idempotent early-return; zero the
    // constant witness-frame fields (producer/op/out-commit); set BGOV_INITED.
}

fn _bgov_fill_label(which: u8) -> i32 {
    // TODO: body per Algorithm _bgov_fill_label -- write "cp_branch_retire"
    // (which==0) or "cp_branch_merge" (which==1) into BGOV_CLAUSE_LABEL as
    // individual ASCII u8 literals. Returns BGOV_OK.
}

fn _bgov_check_clause(label_len: u64) -> i32 {
    // TODO: body per Algorithm _bgov_check_clause -- ident_from_bytes(label) ->
    // BGOV_CLAUSE_ID; slot = cons_find(...); reject iff slot == BGOV_CONS_SENT.
}

fn _bgov_emit_governance(governed_id: *u8, discriminant: u8) -> i32 {
    // TODO: body per Algorithm witness step -- ident_copy(governed_id -> W_INCOMMIT);
    // fill W_PAYLOAD (0xE3 0x12, 6 pad, 32-byte governed id, 8-byte discriminant);
    // ws_emit_fragment(...,48u64,...); map nonzero -> BGOV_E_WITNESS, else BGOV_OK.
}

fn bg_retire_branch(branch_id: *u8, operator_cap: u64) -> i32 @export {
    // TODO: body per Algorithm bg_retire_branch -- inited guard; null guard;
    // cap_verify_rights gate; _bgov_fill_label(0)+_bgov_check_clause(RETIRE_LEN);
    // ba_retire; _bgov_emit_governance(branch_id, 0x01u8).
}

fn bg_merge_branch(req: *u8) -> i32 @export {
    // TODO: body per Algorithm bg_merge_branch -- inited guard; req null guard;
    // load branch_id/target/cap/out_proposal from the 32-byte BGOV_MergeReq;
    // per-field null guards; cap gate; _bgov_fill_label(1)+_bgov_check_clause(MERGE_LEN);
    // ba_merge_propose; _bgov_emit_governance(branch_id, 0x02u8).
}

fn bg_commit_merge(proposal_fid: *u8, operator_cap: u64) -> i32 @export {
    // TODO: body per Algorithm bg_commit_merge -- inited guard; null guard;
    // cap gate; ba_merge_commit (re-verifies bisimulation -- W42);
    // _bgov_emit_governance(proposal_fid, 0x03u8).
}
```

### Self-test note (Phase 2)
Add a `bg_selftest() -> u64 @export` returning `99u64` on pass that runs KATs 1-3 (dep-free + built-capability.iii) deterministically, with distinct non-99 codes per failed assertion (mirrors `wh_selftest` house style). Full-path KATs 4-5 are gated behind Module 57/13/witness_spine availability and live in the integration harness, not the unit self-test.
