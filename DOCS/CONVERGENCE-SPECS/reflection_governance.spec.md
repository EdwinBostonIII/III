# 71 numera/reflection_governance.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is structurally present (5 public fns, forbidden-set + dispatch path), but it is a thin sketch with one correctness-fatal extern/logic defect (`cons_find` typed `-> i32` and gated `!= 0i32`, which **inverts** clause presence and crashes the W11 contract), a fictional witness extern (`ws_emit_fragment from "witness_spine.iii"`), zero capability mediation of the most-privileged call in the substrate (M8/W32 gap), and two hollow accessors (`rg_queue_size` hardcodes `0`, `rg_dequeue_proposal` returns an empty proposal). Realizing the maximal intent — "no reflection without governance; outputs queued, never applied" — requires closing all of these.

## Purpose
`reflection_governance` is the R−3 Apex gate through which **every** reflection invocation must pass (W32: no reflection bypasses this module). It is the substrate's enforcement of M13 (reflection boundedness) and M20 (no self-soundness): it checks each request's target against a boot-frozen forbidden set (the substrate refuses to reason about its own foundations of trust), confirms the governing constitutional clauses `cp_reflect_bound` and `cp_no_self_soundness` are ratified, verifies the caller's reflect capability, emits a `REFLECT_INVOCATION` witness fragment, then dispatches to `numera/reflection_constrained.iii` (Module 70) and places the resulting proof term into the ratification queue — it is **never** applied directly. Hexad: `kind_cognition + kind_witness`. Ring: **R−3**. K: **1.00**.

## Public API
All public functions return a status (`i32` negative-error per W9/W12) or a sentinel-typed value (`u64`/`u8`). Single-line signatures, paste-ready:

```
fn rg_init() -> i32 @export
fn rg_forbidden_target(target: *u8) -> u8 @export
fn rg_invoke(req: *u8) -> i32 @export
fn rg_queue_size() -> u64 @export
fn rg_dequeue_proposal(req: *u8) -> i32 @export
```

Return-status conventions:
- `rg_init` → `RG_OK` (idempotent; re-init returns `RG_OK`).
- `rg_forbidden_target` → `u8` boolean (W10): `1u8` iff `target` is in the forbidden set; `0u8` otherwise (including not-inited / null target — fail-safe to "not forbidden" is **wrong**; see Gap #6 — must fail-safe to `1u8` when uninited so an uninited governor admits nothing downstream).
- `rg_invoke` → `RG_OK` or negative `RG_E_*`. Compared by `== / !=` only (W11).
- `rg_queue_size` → `u64` count (sentinel `0xFFFF_FFFF_FFFF_FFFFu64` if not inited; queue size 0 is a valid distinct value).
- `rg_dequeue_proposal` → `RG_OK` or negative `RG_E_*`.

**W2 note — aggregate-by-pointer redesign.** The gospel's `rg_invoke` (5 params) and `rg_dequeue_proposal` (5 params) both **violate W2 (≤4 params)**. The spec folds each parameter set into a module-defined aggregate passed by a single `*u8` pointer. The caller (R−1 operator ceremony) populates the struct; the callee reads/writes through the pointer. Layouts:

```
// RG_InvokeReq (96 bytes), pointed to by rg_invoke's `req`:
//   [0  .. 32)  target_module : u8[32]   (in)   identifier of module to reflect on
//   [32 .. 64)  budget        : u8[32]   (in)   cost-lattice vector id (opaque to us)
//   [64 .. 72)  cap_id        : u64      (in)   caller's reflect capability id (M8)
//   [72 .. 80)  property_len  : u64      (in)   length of property encoding
//   [80 .. 88)  property_ptr  : u64      (in)   byte-addr of property encoding buffer
//   [88 .. 96)  out_term_ptr  : u64      (in)   byte-addr of u8[32] sink for proof-term id (out)

// RG_DequeueReq (88 bytes), pointed to by rg_dequeue_proposal's `req`:
//   [0  .. 8)   slot          : u64      (in)   queue slot to inspect
//   [8  .. 16)  out_kind_ptr  : u64      (in)   byte-addr of u8 sink  (out: proposal kind)
//   [16 .. 24)  out_cap       : u64      (in)   capability id authorizing the read
//   [24 .. 32)  out_len_ptr   : u64      (in)   byte-addr of u32 sink (out: payload len)
//   [32 .. 40)  out_payload   : u64      (in)   byte-addr of payload sink buffer
//   [40 .. 48)  out_payload_cap : u64    (in)   capacity of payload sink
```

Rationale: this preserves every datum the gospel's wide signatures carried, adds `cap_id` (M8), and brings both functions to a single `*u8` parameter — W2-clean. `req` is read element-by-element through `((req as u64)+off)` byte-pointer arithmetic, matching `witness_hook.iii` house style.

## Constant Namespace
PREFIX = `RFLG_`  — **grep of `STDLIB/` confirms NO collision** (zero occurrences of `RFLG_` anywhere in the tree). The gospel body used the bare `RG_` prefix; `RG_` is retained inside the *gospel's* text but the spec **renames every module-level const to `RFLG_`** to be collision-safe under Trap 2 (module-level `const` is linker-global), since short tokens like `RG_OK` are exactly the kind that collide. (Confirmed no `RG_OK`/`RG_E_*` collision today, but `RFLG_` is the assigned prefix and is used here verbatim.)

Module-level constants (name : type = value):
```
const RFLG_OK                 : i32 =  0i32
const RFLG_E_NULL             : i32 = -1i32
const RFLG_E_TARGET_FORBIDDEN : i32 = -2i32
const RFLG_E_CLAUSE_ABSENT    : i32 = -3i32
const RFLG_E_BUDGET_EXCEEDED  : i32 = -4i32
const RFLG_E_DISPATCH_FAIL    : i32 = -5i32
const RFLG_E_NOT_INITED       : i32 = -6i32
const RFLG_E_K_TOO_LOW        : i32 = -7i32
const RFLG_E_CAP_DENIED       : i32 = -8i32   // NEW: reflect capability check failed (M8/W32)
const RFLG_E_BAD_SLOT         : i32 = -9i32   // NEW: dequeue slot out of range

const RFLG_FORBIDDEN_SLOTS    : u64 = 16u64   // table capacity (justified in Data Structures)
const RFLG_FORBIDDEN_SEED     : u64 = 7u64    // count of foundational modules sealed at boot

const RFLG_CAP_REFLECT        : u64 = 0x4000u64   // == CAP_RIGHT_AMEND (bit 14); see Gap #4
```
Note on the K-threshold error code: `RFLG_E_K_TOO_LOW` is declared (gospel had it) but the gospel body never uses it. The spec keeps it and **wires it**: `rg_invoke` rejects with `RFLG_E_K_TOO_LOW` if the requested reflection's K-vector falls below the R−3 admission floor (K ≥ 1.00 for foundational reflection per the gospel header). Since K is carried in the budget/cost-lattice vector (opaque here), the actual comparison is delegated to Module 70's `rc_construct_proof` which owns the cost lattice; this module surfaces a `RFLG_E_K_TOO_LOW` mapping when dispatch returns the budget-exhaustion code. (Documented as a mapping, not a local float compare — there is no floating point in this path, M2.)

## Data Structures
All module-scope, statically sized (W8); no local `var` arrays (Trap 7). Every multi-byte field accessed via byte-pointer arithmetic so the backing element type is transparent.

```
var RFLG_INITED          : u8 = 0u8
var RFLG_FORBIDDEN_IDS    : [u8; 512]   // 16 slots * 32-byte identifier = 512 bytes
var RFLG_FORBIDDEN_COUNT  : u64 = 0u64

// --- module-scope scratch (replaces gospel's function-local arrays; Trap 7) ---
var RFLG_SEED_BUF         : [u8; 8]     // forbidden-id derivation seed ("FORB"||label||0..)
var RFLG_CLAUSE_LABEL     : [u8; 24]    // "cp_reflect_bound"\0  label bytes
var RFLG_CLAUSE_ID        : [u8; 32]    // derived clause id for cons_find
var RFLG_CLAUSE_LABEL2    : [u8; 24]    // "cp_no_self_soundness"\0
var RFLG_CLAUSE_ID2       : [u8; 32]
var RFLG_PAYLOAD          : [u8; 80]    // REFLECT_INVOCATION fragment payload
var RFLG_PRODUCER         : [u8; 32]    // witness producer id (this module)
var RFLG_OPID             : [u8; 32]    // witness op id  (REFLECT_INVOCATION)
var RFLG_IN_C             : [u8; 32]    // witness in-commit  (= target_module id)
var RFLG_OUT_C            : [u8; 32]    // witness out-commit (= proof-term id post-dispatch)
var RFLG_ANTE             : [u8; 32]    // single zero antecedent (n_ante = 0)
var RFLG_FRAG_ID          : [u8; 32]    // sink for emitted fragment id
```

**Bound justification.** `RFLG_FORBIDDEN_SLOTS = 16`: the forbidden set is the substrate's foundations-of-trust — exactly the seven modules the gospel enumerates (reflection_constrained, reflection_governance, constitution, constitution_preserver, quine_verifier, bone_marrow, witness_spine_root). 16 is the next power of two above 7, leaving headroom for future foundational modules without resizing; it is hard-frozen at R−3 boot and cannot change at runtime (gospel discipline). All scratch buffers are sized to their exact maximum: identifiers are 32 bytes; the `REFLECT_INVOCATION` payload is 2 tag bytes + 32 (target) + 32 (budget id) + 8 (cap_id LE) = 74 ≤ 80; clause labels ≤ 20 chars + NUL ≤ 24.

**Reentrancy note (Trap 7).** R−3 reflection is a single-threaded operator ceremony (one invocation at a time, by construction — W32 funnels all reflection through this one gate under operator control). Module-scope scratch is therefore safe and matches the established `witness_hook.iii` / `identifier.iii` pattern. Flagged here so Phase 2 does not attempt to make `rg_invoke` reentrant.

## Dependencies (externs)
Each with the providing module's NN and build status.

```
// --- identifier.iii (Layer 0, Module 01) — BUILT, signatures verified ---
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"

// --- constitution.iii (Module 13) — NOT YET BUILT (absent from STDLIB) ---
//     CORRECTED: gospel Module-71 extern said `-> i32`; the real (gospel Module-13) signature is `-> u32`
//     with absence sentinel 0xFFFFFFFFu32 (CONS_SENT). Slot 0 is a VALID clause.
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> u32 from "constitution.iii"

// --- reflection_constrained.iii (Module 70) — NOT YET BUILT (parallel wave) ---
extern @abi(c-msvc-x64) fn rc_construct_proof(target_module: *u8, property_encoding: *u8, property_len: u32, budget: *u8, out_term_id: *u8) -> i32 from "reflection_constrained.iii"
extern @abi(c-msvc-x64) fn rc_queue_size() -> u64 from "reflection_constrained.iii"
extern @abi(c-msvc-x64) fn rc_dequeue(slot: u64, out_kind: *u8, out_payload: *u8, out_cap: u32, out_len: *u32) -> i32 from "reflection_constrained.iii"

// --- witness_hook.iii (Module 07) — BUILT, signature verified ---
//     CORRECTED: gospel said `ws_emit_fragment from "witness_spine.iii"` — that symbol does NOT exist.
//     Route fragment emission through the real, built multi-field hook (12 params; W2 exception per
//     witness_hook.iii's own header). Returns u64 fragment index; 0xFFFF.. on failure.
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

// --- capability.iii (aether, Layer 2) — BUILT, signature verified ---
//     ADDED (gospel body had NO capability gate at all — M8/W32 gap).
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
```

**Not-yet-built dependencies (for wave scheduler):**
1. `reflection_constrained.iii` (Module 70) — provides `rc_construct_proof` (gospel-defined), plus the two **new accessors** `rc_queue_size()` and `rc_dequeue(...)` this spec requires (see Gap #2/#3). Module 70's gospel body already owns the queue (`RC_PROPOSAL_COUNT`, `RC_PROPOSAL_*` arrays) but does **not** yet export these getters; flag for Module 70's spec to add them (trivial, mirrors `rc_propose_*`).
2. `constitution.iii` (Module 13) — provides `cons_find -> u32`. Absent from the current tree; on the build path.

`identifier.iii`, `witness_hook.iii`, `capability.iii` are all **built and verified** against the real source this session.

## Algorithm
NIH (M1): every operation is hand-rolled over libc-free primitives already in the substrate (Keccak-derived identifiers, byte loops). No ML/heuristics (M3/M4): the forbidden set and clause gates are exact identifier equality; admission is a boolean conjunction, never a score or threshold-learned value. Determinism (M2)/bit-identity (W5): identifiers are content-addressed (Keccak256 of canonical bytes), the forbidden set is derived from fixed label bytes at boot, the witness payload is a fixed byte layout — identical inputs produce byte-identical fragment ids cross-run/cross-CPU. No recursion (W15): the only loops are bounded linear scans over fixed arrays driven by a sentinel flag (W14), no `break`.

### `rg_init()`
1. If `RFLG_INITED == 1u8` → return `RFLG_OK` (idempotent).
2. For each of the 7 foundational modules (label byte `0x01..0x07`): build the 8-byte seed `"FORB" || label || 0 || 0 || 0` in `RFLG_SEED_BUF`, then `ident_from_bytes(&RFLG_SEED_BUF, 8, &RFLG_FORBIDDEN_IDS[i*32])`. Loop is `while i < RFLG_FORBIDDEN_SEED` with `i = i + 1` (W14, no break).
   - *Maximal-intent correction (Gap #5):* the forbidden ids MUST match the ids the rest of the substrate uses for these modules. The canonical module identifier is `Keccak256(module_path_string)` (the same convention `constitution.iii::cons_init` uses: `ident_from_bytes("numera::constitution", 20, ...)`). The boot-frozen forbidden set therefore derives each id from the module's canonical path string, **not** from an ad-hoc `"FORB"||label` seed. Phase 2 uses the 7 path strings: `"numera::reflection_constrained"`, `"numera::reflection_governance"`, `"numera::constitution"`, `"numera::constitution_preserver"`, `"numera::quine_verifier"`, `"aether::bone_marrow"`, `"numera::witness_spine"`. (The gospel's `"FORB"||label` seed produces ids that match nothing else in the substrate, so `rg_forbidden_target` would never actually fire against a real caller-supplied target id — a silent no-op. This is the single most important semantic fix.)
3. `RFLG_FORBIDDEN_COUNT = 7u64`; `RFLG_INITED = 1u8`; return `RFLG_OK`.

### `rg_forbidden_target(target: *u8) -> u8`
1. **Fail-safe (Gap #6):** if `RFLG_INITED == 0u8` → return `1u8` (an uninited governor treats *everything* as forbidden, so no reflection can slip through before boot completes). *(Gospel returned `0u8` — fail-open — which violates W32/M5; corrected.)*
2. If `(target as u64) == 0u64` → return `1u8` (null target is not admissible).
3. Linear scan: `while i < RFLG_FORBIDDEN_COUNT`, with a `found` flag set once (W14, no break): `if found == 0u8 { if ident_eq(&RFLG_FORBIDDEN_IDS[i*32], target) == 1u8 { found = 1u8 } }`. The element address is computed as `((&RFLG_FORBIDDEN_IDS as u64) + i*32u64) as *u8` (transparent backing-type access).
4. Return `found`.

### `rg_invoke(req: *u8)` — the governed reflection gate
1. If `RFLG_INITED == 0u8` → `RFLG_E_NOT_INITED`.
2. If `(req as u64) == 0u64` → `RFLG_E_NULL`. Load the six fields from the aggregate into locals (target ptr, budget ptr, cap_id, property_len, property_ptr, out_term_ptr) — **assign each to a named local before use** (param-spill discipline, Traps 4/11). Null-check `target_ptr`, `budget_ptr`, `property_ptr`, `out_term_ptr`; any null → `RFLG_E_NULL`.
3. **Capability gate (M8/W32, Gap #4):** `if cap_verify_rights(cap_id, RFLG_CAP_REFLECT) != 1u8 { return RFLG_E_CAP_DENIED }`. Reflection is the most privileged operation in the substrate; it must carry an explicit, unrevoked capability bearing the reflect/amend right. Compared by `!=` on a `u8` (W10/W11-safe).
4. **Forbidden-target gate (M13/M20/W46):** `if rg_forbidden_target(target_ptr) == 1u8 { return RFLG_E_TARGET_FORBIDDEN }`. The substrate refuses to construct proofs about its own foundations of trust.
5. **Constitutional-clause gates** — both `cp_reflect_bound` and `cp_no_self_soundness` MUST be ratified, else reflection is ungoverned:
   - Build `cp_reflect_bound` label bytes in `RFLG_CLAUSE_LABEL`, `ident_from_bytes(..., &RFLG_CLAUSE_ID)`, then **`let slot : u32 = cons_find(&RFLG_CLAUSE_ID)`** and **`if slot == 0xFFFFFFFFu32 { return RFLG_E_CLAUSE_ABSENT }`** (defect #3 fix: `u32` sentinel, `==` compare, slot 0 valid).
   - Same for `cp_no_self_soundness` into `RFLG_CLAUSE_ID2`.
   - *(Gospel's `if cons_find(...) != 0i32 { return ABSENT }` was doubly broken: wrong return type, and it inverted the logic — a clause at slot 0 was reported absent while the absence sentinel `0xFFFFFFFF` was reported present. Both corrected.)*
6. **Emit `REFLECT_INVOCATION` witness BEFORE dispatch (M6/M10/W16):** build `RFLG_PAYLOAD` = `0xE3, 0x08` (tag) ‖ target_module(32) ‖ budget_id(32) ‖ cap_id(8 LE) — a fixed layout, deterministic. Set `RFLG_PRODUCER = ident("numera::reflection_governance")`, `RFLG_OPID = ident("REFLECT_INVOCATION")`, `ident_copy(target_ptr, &RFLG_IN_C)`, `ident_zero(&RFLG_OUT_C)` (out-commit unknown pre-dispatch). Call `wh_publish(&RFLG_PRODUCER, &RFLG_OPID, &RFLG_IN_C, &RFLG_OUT_C, revtag=0, phase=0, pillar=<REFLECT>, &RFLG_ANTE, 0u32, &RFLG_PAYLOAD, 74u32, &RFLG_FRAG_ID)`. The return is the `u64` fragment index; `0xFFFF_FFFF_FFFF_FFFFu64` indicates the log is full — on that sentinel, **refuse** (`RFLG_E_DISPATCH_FAIL`) rather than proceed unwitnessed (M5/M6: no unwitnessed reflection).
7. **Dispatch to Module 70:** `let d : i32 = rc_construct_proof(target_ptr, property_ptr, property_len_u32, budget_ptr, out_term_ptr)`. If `d != 0i32` → `RFLG_E_DISPATCH_FAIL` (W11 equality compare). The proof term lands in Module 70's ratification queue (its `rc_construct_proof`/`rc_propose_*` own the queue); this module never applies it — satisfying the gospel's "placed in the ratification queue, never directly applied." Determinism holds because `rc_construct_proof` is itself deterministic and the inputs are content-addressed.
8. Return `RFLG_OK`.

### `rg_queue_size() -> u64`
1. If `RFLG_INITED == 0u8` → return `0xFFFF_FFFF_FFFF_FFFFu64` (not-inited sentinel; 0 is a valid live count). 
2. Return `rc_queue_size()` — the queue physically lives in `reflection_constrained.iii` (`RC_PROPOSAL_COUNT`). *(Gospel hardcoded `return 0u64`, which lies about queue depth — corrected to a real delegation; Gap #2.)*

### `rg_dequeue_proposal(req: *u8) -> i32`
1. If `RFLG_INITED == 0u8` → `RFLG_E_NOT_INITED`.
2. If `(req as u64) == 0u64` → `RFLG_E_NULL`. Load `slot`, `out_kind_ptr`, `out_cap`, `out_len_ptr`, `out_payload`, `out_payload_cap` from the aggregate into named locals. Null-check `out_kind_ptr`, `out_len_ptr`, `out_payload` → `RFLG_E_NULL`.
3. **Capability gate:** `if cap_verify_rights(out_cap, RFLG_CAP_REFLECT) != 1u8 { return RFLG_E_CAP_DENIED }` — only an operator holding the ceremony capability may pull a proposal for ratification review.
4. Bound-check `slot` against `rc_queue_size()`: `if slot == <sentinel-or-oob> { return RFLG_E_BAD_SLOT }` (use `==`/`!=` only; compute `oob` via an explicit count read, never an ordering compare on a signed value).
5. Delegate the actual read to Module 70: `return rc_dequeue(slot, out_kind_ptr, out_payload, (out_payload_cap & 0xFFFFFFFFu64) as u32, out_len_ptr)`. The mask before the `as u32` cast avoids the u32-in-u64-slot garbage trap (Trap 4). The operator's subsequent ratify/discard is a separate R−1 ceremony, not this call. *(Gospel zeroed the outputs and returned OK — a hollow stub; corrected to a real delegated dequeue; Gap #3.)*

## KAT Vectors (>= 3)
These become the Phase-2 byte-for-byte acceptance gate. (Crypto sub-results cite the Keccak256 dependency, which has its own KATs; here we assert governance behavior.)

1. **KAT-1 forbidden-target self-membership (M20/W46).** After `rg_init()`, build the id of `"numera::reflection_governance"` via `ident_from_bytes` and call `rg_forbidden_target(id)` → expect `1u8`. Also build `"numera::constitution"` id → expect `1u8`. Build the id of a non-foundational module `"numera::bigint"` → expect `0u8`. (Proves the negative case per memory `feedback_no_autogen_stub_prove_negative`: a benign target is NOT forbidden, a foundational one IS.)
2. **KAT-2 uninited fail-safe (W32/M5).** Without calling `rg_init()` (fresh `RFLG_INITED == 0`), `rg_forbidden_target(any_nonnull)` → expect `1u8` (fail-closed), and `rg_invoke(&valid_req)` → expect `RFLG_E_NOT_INITED`. Proves an uninited governor admits no reflection.
3. **KAT-3 capability denial (M8).** After `rg_init()`, construct `RG_InvokeReq` with a `cap_id` that lacks `RFLG_CAP_REFLECT` (e.g. a freshly attenuated cap with `rights_mask = CAP_RIGHT_FS_READ` only). `rg_invoke(&req)` → expect `RFLG_E_CAP_DENIED`, and assert **no** witness fragment was emitted (`wh_next_idx()` unchanged) and **no** dispatch occurred (`rc_queue_size()` unchanged). Proves the gate precedes any side effect.
4. **KAT-4 clause-absent gate (defect #3 regression).** After `rg_init()` and `cap` valid and target benign, but with `constitution.iii` NOT having ratified `cp_reflect_bound` (so `cons_find` returns `CONS_SENT = 0xFFFFFFFFu32`): `rg_invoke(&req)` → expect `RFLG_E_CLAUSE_ABSENT`. Then ratify a clause that lands at **slot 0** and re-test the *other* missing clause: expect `RFLG_E_CLAUSE_ABSENT` still (proves slot 0 is treated as PRESENT, not as the absence sentinel — the exact inversion bug the gospel had).
5. **KAT-5 queue-size honesty.** After `rg_init()` (and `rc_init()`), `rg_queue_size()` → expect `0u64` (empty, distinct from the not-inited sentinel). After one successful `rg_invoke` that enqueues a proposal in Module 70, `rg_queue_size()` → expect `1u64`. (Proves the delegation is live, not the hardcoded `0`.)

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — every signature in this spec is single-line; Phase 2 must keep them so. Exposed: yes (5 signatures). Avoidance: enforced single-line, audited by `grep -nP '^fn [^()]*\(.*[^){]$'`.
- **Trap 2 (module-level `const` linker-global)** — exposed. Avoidance: every const carries the `RFLG_` prefix; grep confirmed no collision in `STDLIB/`.
- **Trap 3 (signed-ordering SIGSEGV)** — exposed via `cons_find` gating and error compares. Avoidance: all error/status compares use `== / !=` only (`RFLG_E_*` are negative i32 compared by equality, W11); the `cons_find` gate compares `u32` against `0xFFFFFFFFu32` by `==`; no `<`/`>`/`<=`/`>=` on any signed value anywhere.
- **Trap 4 (u32-in-u64-slot garbage)** — exposed where `out_payload_cap`/`property_len` (carried as u64 in the aggregate) are narrowed to `u32` for the extern calls, and where loop indices index byte arrays. Avoidance: mask `(x as u64) & 0xFFFFFFFFu64` (or `& 0xFFFFFFFFu64) as u32`) before every narrowing/pointer use; element addresses computed as `((&ARR as u64) + i*stride) as *u8`.
- **Trap 5 (u32 pointer-store width)** — not exposed: this module writes no `*u32` outputs itself; the `*u32` len sink is written by Module 70's `rc_dequeue`. (Flag carried to Module 70's spec.)
- **Trap 6 (nested block comments)** — avoidance: no `/* */` nested; inline notes use `//`.
- **Trap 7 (local `var` arrays)** — exposed (gospel used function-local `[u8; N]` arrays freely). Avoidance: every scratch buffer hoisted to module scope with a unique `RFLG_` name (see Data Structures); reentrancy waiver noted (single-threaded R−3 ceremony).
- **Trap 8 (`} else {` one line)** — the algorithm uses no `else` branches (guard-and-return style); if Phase 2 introduces one, it must be single-line.
- **Trap 9 (em-dash in comments)** — avoidance: ASCII `--` only in all `/* */` comments in the implementation file. (This spec doc is Markdown and not subject to the lexer; the `.iii` file must use ASCII.)
- **Trap 10 (`let mut flag` checkpoint)** — `rg_forbidden_target` uses a `found` flag in a scan; this is the *sanctioned* W14 sentinel pattern (flag drives the guard `if found == 0u8`), not the misbehaving checkpoint-flag pattern. Safe. No early-return-from-loop needed.
- **Trap 11 (`a % b` after call)** — not exposed: no modulo anywhere in this module (the gospel body had none either).
- **Trap 12 (`@specialize *T` stride)** — not exposed: no generics; all element strides are the literal `32u64`.

## Gap / Fix List
The gospel candidate body is PARTIAL. Every defect, with its fix:

1. **Fictional witness extern (defect #2).** Gospel: `extern ws_emit_fragment ... from "witness_spine.iii"` and `ws_emit_fragment(producer, op, in_c, out_c, payload, payload_len, out_fid) -> i32`. That symbol does not exist. **Fix:** route through the real `wh_publish(...) -> u64` in `witness_hook.iii` (12-param multi-field hook; the W2 exception is documented in witness_hook.iii's own header). Refuse on the `0xFFFF..` full-sentinel rather than proceed unwitnessed.
2. **`cons_find` wrong type + inverted logic (defect #3 — correctness-fatal).** Gospel extern: `cons_find(clause_id: *u8) -> i32`; gospel body: `if cons_find(...) != 0i32 { return RG_E_CLAUSE_ABSENT }`. The real signature is `-> u32` with absence sentinel `0xFFFFFFFFu32` and **slot 0 is a valid clause**. The gospel logic reports a valid slot-0 clause as ABSENT and reports the absence sentinel as PRESENT — fully inverted, and an `i32` compare on a value that is really a `u32` slot index courts the signed-ordering trap. **Fix:** extern `-> u32`; gate with `if slot == 0xFFFFFFFFu32 { return RFLG_E_CLAUSE_ABSENT }`. Covered by KAT-4.
3. **No capability mediation (M8/W32 — maximal-intent gap).** The gospel `rg_invoke` performs zero capability check, yet reflection is the substrate's most privileged action. **Fix:** add `cap_id` to the request aggregate and gate every `rg_invoke`/`rg_dequeue_proposal` with `cap_verify_rights(cap_id, RFLG_CAP_REFLECT)`; new error `RFLG_E_CAP_DENIED`. Covered by KAT-3.
4. **`rg_queue_size` hardcodes `0u64` (hollow).** Gospel returns a literal `0`, lying about queue depth. **Fix:** delegate to `rc_queue_size()` in Module 70; not-inited returns the `0xFFFF..` sentinel. Requires Module 70 to export `rc_queue_size` (new accessor — flag to Module 70). Covered by KAT-5.
5. **`rg_dequeue_proposal` returns an empty proposal (hollow stub).** Gospel sets `*out_kind = 0`, `*out_len = 0`, returns OK without reading anything. **Fix:** delegate to `rc_dequeue(slot, out_kind, out_payload, out_cap, out_len)` in Module 70 after a capability + slot-bound check. Requires Module 70 to export `rc_dequeue` (new accessor — flag to Module 70).
6. **Forbidden-set ids derived from a meaningless seed (silent no-op).** Gospel derives ids from `"FORB" || label_byte`, which match nothing else in the substrate, so `rg_forbidden_target` would never fire against a real caller-supplied module id. **Fix:** derive each forbidden id from the module's canonical path string via `ident_from_bytes`, matching the `Keccak256(path)` convention the rest of the substrate uses (e.g. `constitution.iii::cons_init`). The 7 exact strings are listed in Algorithm §rg_init. Covered by KAT-1.
7. **`rg_forbidden_target` fails open when uninited (W32/M5 violation).** Gospel returns `0u8` (not forbidden) if `RFLG_INITED == 0`. An uninited governor must forbid everything. **Fix:** return `1u8` on `RFLG_INITED == 0` and on null target. Covered by KAT-2.
8. **W2 violations (param count).** `rg_invoke` (5 params) and `rg_dequeue_proposal` (5 params) exceed the 4-param limit. **Fix:** fold each into a single `*u8` aggregate (`RG_InvokeReq` / `RG_DequeueReq`, layouts in Public API). This also created the natural home for the new `cap_id`.
9. **`RFLG_E_K_TOO_LOW` declared but unused.** **Fix:** wire it as the surfaced mapping when Module 70's `rc_construct_proof` returns budget/K exhaustion, so the K-threshold (M13/M19) is observable at this layer without a local float compare (M2 — no FP).
10. **Trap-7 local arrays.** Gospel uses function-local `[u8; N]` scratch throughout. **Fix:** hoist all to module scope with `RFLG_` names; reentrancy waiver documented.
11. **Prefix.** Gospel uses bare `RG_`. **Fix:** rename all module-level consts to the assigned `RFLG_` prefix (collision-checked).

**Mandate/law compliance verified after fixes:** M1 (NIH — only identifier/constitution/capability/witness substrate deps), M2/W5 (content-addressed, fixed byte layouts), M3/M4 (exact equality gates, no scores), M5 (refuse rather than proceed unwitnessed; fail-closed uninited), M6/M10 (witness emitted before dispatch, recomputable from recorded fields), M8 (capability gate added), M13/M20/W46 (forbidden self-reflection set, boot-frozen), W2 (aggregates), W8 (fixed arrays, bound justified), W9/W11/W12 (negative-i32 errors, equality compares, every fn returns status/sentinel), W14 (sentinel loops, no break), W15 (no recursion). W32 binds and is now actually enforced (capability + clause + forbidden gates all precede dispatch).

## Implementation Skeleton
Paste-ready structure (signatures single-line; NO fn bodies — Phase 2 writes those per Algorithm §). ASCII-only comments in the real file (Trap 9).

```iii
/* III/STDLIB/iii/numera/reflection_governance.iii
 *
 * III STDLIB - numera::reflection_governance
 *
 * The R-3 governance gate that mediates EVERY reflection request
 * (W32: no reflection bypasses this module). Enforces target
 * admissibility (forbidden foundations-of-trust set, M13/M20/W46),
 * the reflect capability (M8), ratification of cp_reflect_bound and
 * cp_no_self_soundness, emits a REFLECT_INVOCATION witness before
 * dispatch (M6), then dispatches to reflection_constrained.iii. The
 * proof-term output is placed in the ratification queue, never
 * applied directly.
 *
 * Hexad: kind_cognition + kind_witness.  Ring: R-3.  K: 1.00.
 *
 * NIH: depends on identifier.iii, constitution.iii (NYB),
 *      reflection_constrained.iii (NYB), witness_hook.iii,
 *      capability.iii.
 *
 * Discipline: W2 (requests folded into *u8 aggregates), W8 (fixed
 * forbidden table), W9/W11/W12, W14 (sentinel loops), W15 (no
 * recursion). The forbidden set is frozen at R-3 boot and cannot be
 * modified at runtime.
 */
module numera_reflection_governance

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> u32 from "constitution.iii"
extern @abi(c-msvc-x64) fn rc_construct_proof(target_module: *u8, property_encoding: *u8, property_len: u32, budget: *u8, out_term_id: *u8) -> i32 from "reflection_constrained.iii"
extern @abi(c-msvc-x64) fn rc_queue_size() -> u64 from "reflection_constrained.iii"
extern @abi(c-msvc-x64) fn rc_dequeue(slot: u64, out_kind: *u8, out_payload: *u8, out_cap: u32, out_len: *u32) -> i32 from "reflection_constrained.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"

const RFLG_OK                 : i32 =  0i32
const RFLG_E_NULL             : i32 = -1i32
const RFLG_E_TARGET_FORBIDDEN : i32 = -2i32
const RFLG_E_CLAUSE_ABSENT    : i32 = -3i32
const RFLG_E_BUDGET_EXCEEDED  : i32 = -4i32
const RFLG_E_DISPATCH_FAIL    : i32 = -5i32
const RFLG_E_NOT_INITED       : i32 = -6i32
const RFLG_E_K_TOO_LOW        : i32 = -7i32
const RFLG_E_CAP_DENIED       : i32 = -8i32
const RFLG_E_BAD_SLOT         : i32 = -9i32

const RFLG_FORBIDDEN_SLOTS    : u64 = 16u64
const RFLG_FORBIDDEN_SEED     : u64 = 7u64
const RFLG_CAP_REFLECT        : u64 = 0x4000u64

var RFLG_INITED          : u8 = 0u8
var RFLG_FORBIDDEN_IDS   : [u8; 512]
var RFLG_FORBIDDEN_COUNT : u64 = 0u64
var RFLG_SEED_BUF        : [u8; 8]
var RFLG_CLAUSE_LABEL    : [u8; 24]
var RFLG_CLAUSE_ID       : [u8; 32]
var RFLG_CLAUSE_LABEL2   : [u8; 24]
var RFLG_CLAUSE_ID2      : [u8; 32]
var RFLG_PAYLOAD         : [u8; 80]
var RFLG_PRODUCER        : [u8; 32]
var RFLG_OPID            : [u8; 32]
var RFLG_IN_C            : [u8; 32]
var RFLG_OUT_C           : [u8; 32]
var RFLG_ANTE            : [u8; 32]
var RFLG_FRAG_ID         : [u8; 32]

// internal helper (not exported): derive a forbidden id from a path string.
fn rg_seed_forbidden(idx: u64, path: *u8, path_len: u64) -> i32 {
    // TODO: body per Algorithm §rg_init step 2 (ident_from_bytes into RFLG_FORBIDDEN_IDS[idx*32]).
}

fn rg_init() -> i32 @export {
    // TODO: body per Algorithm §rg_init (idempotent; seed 7 canonical-path ids; set count + inited).
}

fn rg_forbidden_target(target: *u8) -> u8 @export {
    // TODO: body per Algorithm §rg_forbidden_target (fail-closed uninited/null; sentinel scan, W14).
}

fn rg_invoke(req: *u8) -> i32 @export {
    // TODO: body per Algorithm §rg_invoke (load aggregate; cap gate; forbidden gate; two cons_find
    //       clause gates with u32 sentinel; emit REFLECT_INVOCATION via wh_publish; dispatch
    //       rc_construct_proof; map K/budget exhaustion to RFLG_E_K_TOO_LOW).
}

fn rg_queue_size() -> u64 @export {
    // TODO: body per Algorithm §rg_queue_size (not-inited sentinel; else delegate rc_queue_size()).
}

fn rg_dequeue_proposal(req: *u8) -> i32 @export {
    // TODO: body per Algorithm §rg_dequeue_proposal (load aggregate; cap gate; slot bound-check via
    //       == / != only; delegate rc_dequeue with masked u32 cap).
}

// ---- self-test (99 = pass) per KAT-1..KAT-5 ----
fn rg_selftest() -> u64 @export {
    // TODO: KAT-1 forbidden self-membership + benign negative; KAT-2 uninited fail-safe;
    //       KAT-3 cap denial w/ no side effects; KAT-4 clause-absent incl. slot-0-present;
    //       KAT-5 queue-size honesty.  Return 99u64 on full pass.
}
```
