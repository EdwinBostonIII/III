# 35 aether/shape_negotiator.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is a near-complete, structurally sound MaxSAT-by-iterated-CDCL negotiator with correct externs against the REALIZED substrate (wh_publish, ident_*, sat_* all verified), but it (a) uses the gospel draft prefix `SN_` instead of the dispatch-assigned `SHAPEN_`, (b) violates Trap 7 in six places (function-local `var` arrays), (c) is exposed to Trap 4 (u32 slot in pointer math, unmasked), and (d) carries one latent capability-mediation gap (M8: `sn_negotiate` mutates global classification + emits a witness with no capability argument). All gaps are listed with fixes in §Gap/Fix. Its sole code-level dependency `numera/sat.iii` is NOT YET BUILT.

## Purpose
`aether::shape_negotiator` lifts per-probe **local sections of the hardware-behavior presheaf** (each probe outcome is an assertion about hardware over an open set in the hardware ontology) into a single **globally coherent sheaf section** (the substrate's deployment shape against the probed environment). Overlapping probe assertions that disagree on their intersection form conflict edges; the module encodes accept/reject of each section as a Boolean MaxSAT instance — hard clauses `(¬accept_a | ¬accept_b)` per conflict, unit soft clauses `(accept_s)` preferring acceptance — and solves it by **iterated deterministic CDCL** (no weighted-MaxSAT oracle): on UNSAT it peels the lex-smallest-op-id probe involved in any live conflict, drops its soft clause, and re-solves, until SAT. The accepted set is the lifted section; its canonical identity is `Keccak256` over the lex-sorted accepted section values. Hexad: **kind_motion + kind_witness**. Ring: **R0**. K-vector: **0.99**.

## Public API
All six public functions are `@export`, single-line signatures (Trap 1). Return-status conventions noted per W9/W12.

```
fn sn_init() -> i32 @export
fn sn_register_section(open_set: u32, value: *u8, op_id: *u8) -> u32 @export
fn sn_declare_conflict(a: u32, b: u32) -> i32 @export
fn sn_negotiate(env_cap: u64) -> i32 @export
fn sn_is_accepted(slot: u32) -> u8 @export
fn sn_global_section(out_id: *u8) -> i32 @export
```

Return-status conventions:
- `sn_init` → `SHAPEN_OK` (0) always (W12 status). No failure path.
- `sn_register_section` → **sentinel-typed `u32`** (W12): the assigned slot id `0..SHAPEN_MAX_SEC-1` on success, or `SHAPEN_SENT` (`0xFFFFFFFFu32`) when the slot table is full. Gate callers with `== / != SHAPEN_SENT` (never ordering — Trap 3 / W11).
- `sn_declare_conflict` → `SHAPEN_OK` (0) / `SHAPEN_E_BAD` (-1) negative-i32 error (W9). Compare with `== / !=` only (W11).
- `sn_negotiate` → on success a **non-negative count of accepted sections cast to i32** (W12 sentinel-typed value); on capability denial `SHAPEN_E_CAP` (-2, negative i32, W9). Caller distinguishes via `== SHAPEN_E_CAP` then treats any other value as the count. **API CHANGE from gospel:** added `env_cap: u64` first parameter to satisfy M8 (see Gap/Fix #G7). Arity = 1 ≤ 4 (W2).
- `sn_is_accepted` → `u8` 0/1 boolean (W10). Returns 0 for out-of-range / dead / unaccepted.
- `sn_global_section` → `SHAPEN_OK` (0) (W9/W12); writes 32 bytes to `out_id`.

Internal (non-`@export`) helpers — NOT public surface, but part of the module:
```
fn sn_val_ptr(slot: u32) -> *u8
fn sn_op_ptr(slot: u32) -> *u8
fn sn_encode_and_solve() -> i32
fn sn_peel_target() -> u32
```

## Constant Namespace
**PREFIX = `SHAPEN_`** (dispatch-assigned). The gospel draft body used `SN_`; this spec **renames every module-level `const` and `var` to `SHAPEN_`** because Trap 2 makes every module-scope `const` a linker-global symbol `L_<NAME>` — the dispatch prefix is authoritative and must be honored verbatim by Phase 2.

Grep result: **`SHAPEN_` — zero matches** anywhere in `STDLIB/` (collision-free). For completeness `SN_*` is *also* currently collision-free in `STDLIB/`, and none of the candidate's individual const names (`SAT_SAT_RC`, `SAT_UNSAT_RC`, etc.) collide — but the spec still standardizes on `SHAPEN_` per the dispatch.

Module-level constants (name : type = value):
```
const SHAPEN_OK          : i32 =  0i32          // status OK
const SHAPEN_E_BAD       : i32 = -1i32          // bad argument / full (W9)
const SHAPEN_E_CAP       : i32 = -2i32          // capability denied (W9; new, M8)
const SHAPEN_SENT        : u32 = 0xFFFFFFFFu32  // u32 absence sentinel
const SHAPEN_SAT_SAT_RC  : i32 =  1i32          // mirrors numera::sat SAT_SAT
const SHAPEN_SAT_UNSAT_RC: i32 =  2i32          // mirrors numera::sat SAT_UNSAT
const SHAPEN_MAX_SEC     : u32 = 1024u32        // max registered sections (slot table bound)
const SHAPEN_MAX_CONF    : u32 = 8192u32        // max conflict edges
const SHAPEN_ID_BYTES    : u64 = 32u64          // identifier width (was inline 32 literals)
const SHAPEN_VALUE_BYTES : u64 = 32768u64       // SHAPEN_MAX_SEC * 32 (value buffer)
const SHAPEN_PILLAR      : u16 = 6u16           // witness pillar id (gospel used 6)
const SHAPEN_PHASE       : u8  = 5u8            // witness phase id (gospel used 5)
const SHAPEN_RIGHT_AMEND : u64 = 0x4000u64      // CAP_RIGHT_AMEND mirror (negotiate mutates shape; see G7)
```
`SHAPEN_SAT_SAT_RC` / `SHAPEN_SAT_UNSAT_RC` are local mirrors of `numera::sat`'s `SAT_SAT=1i32` / `SAT_UNSAT=2i32` (verified against gospel `numera/sat.iii` lines 4260–4261). They are **not** `extern`-imported because iiis links consts by emitted symbol, not import; mirroring the literal values is the house pattern (cf. fed_admit mirroring `fed_tier` ids). The values MUST be kept in sync with `numera/sat.iii`; noted as a cross-module invariant.

## Data Structures
All buffers are **module-scope** fixed arrays (W8); none are function-local (Trap 7 — see Gap/Fix #G2). Backing-type note: iiis allocates 8 bytes per array element regardless of declared element type (the u64-slot model — see witness_hook.iii header), so `[u8; N]` reserves `8*N` bytes; this is acceptable at these bounds and all byte access goes through pointer arithmetic. Names use the `SHAPEN_` prefix.

| Name | Type | Fixed size | Bound justification (W8) |
|---|---|---|---|
| `SHAPEN_LIVE` | `[u8; 1024]` | 1024 | One liveness flag per section slot; bound = `SHAPEN_MAX_SEC`. |
| `SHAPEN_OPEN` | `[u32; 1024]` | 1024 | Open-set id per section. |
| `SHAPEN_VALUE` | `[u8; 32768]` | 1024*32 | 32-byte asserted section value per slot. |
| `SHAPEN_OP_ID` | `[u8; 32768]` | 1024*32 | 32-byte op identifier per slot (lex-compared for peel + sort). |
| `SHAPEN_ACCEPT_VAR` | `[u32; 1024]` | 1024 | SAT variable id (= slot+1) per slot. |
| `SHAPEN_ACCEPTED` | `[u8; 1024]` | 1024 | Final accept flag per slot. |
| `SHAPEN_DROPPED` | `[u8; 1024]` | 1024 | Peeled-out flag per slot (per negotiation). |
| `SHAPEN_COUNT` | `u32 = 0` | scalar | Count of registered sections. |
| `SHAPEN_CONF_A` | `[u32; 8192]` | 8192 | Conflict-edge endpoint A; bound = `SHAPEN_MAX_CONF`. |
| `SHAPEN_CONF_B` | `[u32; 8192]` | 8192 | Conflict-edge endpoint B. |
| `SHAPEN_CONF_COUNT` | `u32 = 0` | scalar | Count of declared conflict edges. |
| `SHAPEN_PRODUCER` | `[u8; 32]` | 32 | Cached producer identifier (`"aether::shape_negotiator"`). |
| `SHAPEN_OPID_LIFT` | `[u8; 32]` | 32 | Cached op identifier (`"aether::shape_negotiator::lift"`). |
| `SHAPEN_INITED` | `u8 = 0` | scalar | One-shot init guard. |
| `SHAPEN_ORDER` | `[u32; 1024]` | 1024 | **Moved from local** (Trap 7): sort permutation in `sn_global_section`. |
| `SHAPEN_CONCAT` | `[u8; 32768]` | 1024*32 | **Moved from local** (Trap 7): sorted-value concat buffer for hashing. |
| `SHAPEN_CL2` | `[u32; 2]` | 2 | **Moved from local** (Trap 7): 2-literal hard-clause scratch. |
| `SHAPEN_CL1` | `[u32; 1]` | 1 | **Moved from local** (Trap 7): 1-literal soft-clause scratch. |
| `SHAPEN_INC` | `[u8; 32]` | 32 | **Moved from local** (Trap 7): in-commit (chain root) scratch for publish. |
| `SHAPEN_OUTC` | `[u8; 32]` | 32 | **Moved from local** (Trap 7): out-commit (global section) scratch. |
| `SHAPEN_FID` | `[u8; 32]` | 32 | **Moved from local** (Trap 7): fragment-id sink for `wh_publish`. |
| `SHAPEN_PL4` | `[u8; 4]` | 4 | **Moved from local** (Trap 7): 4-byte accepted-count payload. |

Reentrancy note (Trap 7): moving scratch to module scope makes `sn_negotiate` / `sn_global_section` **non-reentrant**. This is acceptable — the negotiator is a single-threaded R0 classification pass invoked serially; documented here per briefing requirement.

## Dependencies (externs)
All externs are bare-basename `from "<module>.iii"` (the verified house convention — `witness_hook.iii` itself externs `identifier.iii` by bare name though it lives in `numera/`; the build links by basename). All signatures below were confirmed by reading the REAL provider files (or the gospel body for the not-yet-built one).

| Extern signature | Provider module | NN | Status |
|---|---|---|---|
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | numera/identifier.iii | 01 | **BUILT** (verified) |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | numera/identifier.iii | 01 | **BUILT** (verified) |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | numera/identifier.iii | 01 | **BUILT** (verified) — *declared by gospel; unused in body; keep only if a value-equality fast path is added, else drop (see G5)* |
| `fn ident_cmp(a: *u8, b: *u8) -> i32` | numera/identifier.iii | 01 | **BUILT** (verified; returns -1/0/1) |
| `fn sat_init(n_vars: u32) -> i32` | numera/sat.iii | 16 | **NOT YET BUILT** |
| `fn sat_add_clause(lits: *u32, n_lits: u32) -> i32` | numera/sat.iii | 16 | **NOT YET BUILT** |
| `fn sat_solve() -> i32` | numera/sat.iii | 16 | **NOT YET BUILT** |
| `fn sat_value(var: u32) -> u8` | numera/sat.iii | 16 | **NOT YET BUILT** |
| `fn wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | aether/witness_hook.iii | 07 | **BUILT** (verified — exact match; §3.5 defect #2 correctly avoided) |
| `fn wh_chain_root(out_id: *u8) -> i32` | aether/witness_hook.iii | 07 | **BUILT** (verified) |
| `fn cap_verify_rights(id: u64, required: u64) -> u8` | aether/capability.iii | (Layer 7) | **BUILT** (verified — §3.5 defect #5 fix; `cap_verify` does NOT exist) — *NEW dependency added for M8 (G7)* |

**Not-yet-built dependency count: 1** module (`numera/sat.iii`, supplying 4 externs). The wave scheduler MUST order `numera/sat.iii` before this module. (`numera/identifier.iii`, `aether/witness_hook.iii`, `aether/capability.iii` are all built.)

**Conceptual (non-code) dependency:** the dispatch lists `aether/basal_probe.iii` (Module 34) as a dependency. This is a *data-flow* dependency only — probe outcomes from `bp_execute_and_publish` become the `(open_set, value, op_id)` triples fed to `sn_register_section`. There is **no extern from basal_probe in this module**; the gospel candidate correctly takes pre-registered sections as input. No code-level ordering constraint on Module 34.

## Algorithm

### `sn_init() -> i32`
1. Loop `i = 0 .. SHAPEN_MAX_SEC` clearing `SHAPEN_LIVE[i] = 0u8` (sentinel-counter loop, W14; `i` driven, no `break`).
2. `SHAPEN_COUNT = 0`, `SHAPEN_CONF_COUNT = 0`.
3. Materialize cached identifiers: `ident_from_bytes("aether::shape_negotiator", 24, &SHAPEN_PRODUCER)` and `ident_from_bytes("aether::shape_negotiator::lift", 30, &SHAPEN_OPID_LIFT)`. These are `Keccak256` of the literal name bytes — deterministic (M2), NIH (M1) hashing via the identifier module. **String-length audit:** `"aether::shape_negotiator"` = 24 bytes, `"aether::shape_negotiator::lift"` = 30 bytes — both correct in gospel.
4. `SHAPEN_INITED = 1`; return `SHAPEN_OK`.
Determinism (M2)/bit-identity (W5): pure array clears + fixed-string hashes; no input, no nondeterminism.

### `sn_register_section(open_set: u32, value: *u8, op_id: *u8) -> u32`
1. If `SHAPEN_INITED == 0u8` call `sn_init()` (idempotent guard).
2. Linear scan `i = 0 .. SHAPEN_MAX_SEC` (W14) for the first slot with `SHAPEN_LIVE[i] == 0u8` (first-fit; deterministic — lowest free index).
3. On finding it: store `SHAPEN_OPEN[i] = open_set`; `ident_copy(value, sn_val_ptr(i))`; `ident_copy(op_id, sn_op_ptr(i))`; assign `SHAPEN_ACCEPT_VAR[i] = i + 1u32` (variables numbered `1..` per sat.iii literal convention); clear `SHAPEN_ACCEPTED[i]`, `SHAPEN_DROPPED[i]`; set `SHAPEN_LIVE[i] = 1u8`; `SHAPEN_COUNT += 1`; return `i`.
4. Table full → return `SHAPEN_SENT`.
Determinism: first-fit by ascending index is deterministic; `ident_copy` is a 32-byte memcpy. No recursion (W15).

### `sn_declare_conflict(a: u32, b: u32) -> i32`
1. Validate: `a < SHAPEN_MAX_SEC`, `b < SHAPEN_MAX_SEC`, `SHAPEN_LIVE[a] == 1`, `SHAPEN_LIVE[b] == 1`, `SHAPEN_CONF_COUNT < SHAPEN_MAX_CONF` — any failure returns `SHAPEN_E_BAD`. (All comparisons here are `<` / `>=` on **u32**, which is unsigned and NOT subject to Trap 3 — Trap 3 is signed-integer-only; u32 ordering is safe in iiis.)
2. Append edge: `SHAPEN_CONF_A[SHAPEN_CONF_COUNT] = a`, `SHAPEN_CONF_B[...] = b`, `SHAPEN_CONF_COUNT += 1`; return `SHAPEN_OK`.
Determinism: append-only; order preserved.

### `sn_encode_and_solve() -> i32` (internal)
Hand-rolled MaxSAT-instance builder feeding the external CDCL solver (M1 — no third-party SAT; the solver itself is `numera/sat.iii`, in-substrate).
1. `sat_init(SHAPEN_COUNT)` — fresh solver with `SHAPEN_COUNT` variables `1..SHAPEN_COUNT`. **Invariant (see G6):** because there is no unregister path, slots fill densely `0..SHAPEN_COUNT-1`, so `SHAPEN_ACCEPT_VAR[s] = s+1 ∈ 1..SHAPEN_COUNT` — always in range of `sat_init(SHAPEN_COUNT)`.
2. **Hard clauses** — loop `c = 0 .. SHAPEN_CONF_COUNT` (W14). For each edge `(a,b)` with both live and both not dropped, build the 2-literal clause in module-scope `SHAPEN_CL2`: `SHAPEN_CL2[0] = (SHAPEN_ACCEPT_VAR[a] << 1) | 1` (¬accept_a), `SHAPEN_CL2[1] = (SHAPEN_ACCEPT_VAR[b] << 1) | 1` (¬accept_b); `sat_add_clause(&SHAPEN_CL2[0], 2)`. Encoding matches sat.iii: negative literal = `(v<<1)|1`.
3. **Soft clauses** — loop `s = 0 .. SHAPEN_MAX_SEC` (W14). For each live, non-dropped slot build unit `SHAPEN_CL1[0] = (SHAPEN_ACCEPT_VAR[s] << 1)` (positive accept_s) and `sat_add_clause(&SHAPEN_CL1[0], 1)`.
4. `return sat_solve()` (`SHAPEN_SAT_SAT_RC` or `SHAPEN_SAT_UNSAT_RC`).
Determinism: the solver is the deterministic CDCL of `numera/sat.iii` (no restarts, no randomness, decision heuristic = smallest-index/most-active — gospel sat.iii prose). Clause-add order is fixed by ascending slot/edge index → identical clause DB → bit-identical solve (M2/W5).

### `sn_peel_target() -> u32` (internal)
Deterministic conflict-resolution choice (NOT a heuristic in the M4 sense — it is an exact lexicographic minimum, fully specified).
1. `best = SHAPEN_SENT`.
2. Loop `c = 0 .. SHAPEN_CONF_COUNT` (W14). For each endpoint `a` then `b` that is live and not dropped: if `best == SHAPEN_SENT` set `best = endpoint`; otherwise if `ident_cmp(sn_op_ptr(endpoint), sn_op_ptr(best)) == -1i32` (strictly lex-smaller op id) set `best = endpoint`. Compare uses **equality against -1** (W11/Trap 3 safe — no ordering compare on the i32).
3. Return `best` (the lex-smallest op id among undropped probes still in any conflict; `SHAPEN_SENT` if none remain).
Determinism: total order on 32-byte op ids via `ident_cmp`; ties impossible (distinct op ids); selection is exact (M4-clean — this is algebraic lex-min, not a "good enough" guess).

### `sn_negotiate(env_cap: u64) -> i32`
1. **Capability gate (M8/G7, NEW):** `if cap_verify_rights(env_cap, SHAPEN_RIGHT_AMEND) == 0u8 { return SHAPEN_E_CAP }`. Negotiation mutates the global classification and emits a witness — a privileged amend; gated explicitly.
2. If `SHAPEN_INITED == 0u8` call `sn_init()`.
3. **Iterated peeling loop** (W14, sentinel `done` flag; W15 — no recursion): `iter = 0`, `done = 0`. While `done == 0u8`:
   - If `iter > SHAPEN_COUNT` set `done = 1` (termination bound: at most `SHAPEN_COUNT` peels possible — each iteration either solves or drops exactly one live probe, and there are `SHAPEN_COUNT` of them; the `> SHAPEN_COUNT` guard makes the bound explicit and total).
   - If `iter <= SHAPEN_COUNT`: `r = sn_encode_and_solve()`.
     - If `r == SHAPEN_SAT_SAT_RC`: read the model — loop `s = 0 .. SHAPEN_MAX_SEC`, for each live `s` set `SHAPEN_ACCEPTED[s] = 0`, then if `sat_value(SHAPEN_ACCEPT_VAR[s]) == 1u8` and `SHAPEN_DROPPED[s] == 0u8` set `SHAPEN_ACCEPTED[s] = 1`. (`sat_value` returns 1 = true per sat.iii; correct.) Set `done = 1`.
     - If `r == SHAPEN_SAT_UNSAT_RC`: `peel = sn_peel_target()`; if `peel == SHAPEN_SENT` set `done = 1` (no peelable probe — give up; accepted set stays as last good or empty); else `SHAPEN_DROPPED[peel] = 1`.
     - `iter += 1`.
4. **Publish SHAPE_LIFTED witness:** `wh_chain_root(&SHAPEN_INC)` (in-commit = current chain root); `sn_global_section(&SHAPEN_OUTC)` (out-commit = lifted-section id). Count accepted: loop `k = 0 .. SHAPEN_MAX_SEC`, `accepted_count += 1` for each live+accepted `k`. Serialize `accepted_count` little-endian into `SHAPEN_PL4[0..4]` via byte shifts + `& 0xFFu32` masks (Trap 4/W4 on the u32). Call `wh_publish(&SHAPEN_PRODUCER, &SHAPEN_OPID_LIFT, &SHAPEN_INC, &SHAPEN_OUTC, 0u8 /*revtag*/, SHAPEN_PHASE, SHAPEN_PILLAR, &SHAPEN_PL4 /*antecedents ptr, n_ante=0*/, 0u32, &SHAPEN_PL4 /*payload*/, 4u32, &SHAPEN_FID)`. (revtag=0 → reversible default, M9/W16; witness chains by hash, M6/M10.)
5. Return `accepted_count as i32` (non-negative; W12).
Determinism (M2/W5): every loop is index-bounded and order-fixed; the model read is deterministic given a deterministic solver; the witness payload is a fixed 4-byte LE count → byte-identical fragment id recomputable from inputs (M10). Termination (M5 — no bricking): the `iter > SHAPEN_COUNT` guard bounds the loop absolutely; on exhaustion it publishes whatever was accepted (refusal-to-overcommit, never unrecoverable). Cost is bounded (M19): ≤ `SHAPEN_COUNT+1` CDCL solves.

### `sn_is_accepted(slot: u32) -> u8`
Range/liveness guard then return `SHAPEN_ACCEPTED[slot]`. Pure read (W10 boolean).

### `sn_global_section(out_id: *u8) -> i32`
Canonical identity of the lifted section — order-invariant by construction (M2/W5).
1. **Gather** accepted slots into `SHAPEN_ORDER[0..n]`: loop `i = 0 .. SHAPEN_MAX_SEC` (W14), append `i` to `SHAPEN_ORDER[n]` (n++) when live+accepted.
2. **Lex sort** `SHAPEN_ORDER[0..n]` by section value (`sn_val_ptr`) using **insertion sort with an explicit inner index** (W15 — no recursion; W14 — inner loop driven by `q`, no `break`): outer `p = 1 .. n`; inner `q = p` while `q > 0`: compare `ident_cmp(sn_val_ptr(order[q-1]), sn_val_ptr(order[q]))`; if `== 1i32` (left > right) swap and `q -= 1`; if `!= 1i32` set `q = 0` (terminates the inner loop without `break`). **Note (G8):** this is the gospel's insertion-sort shape; the `q=0` early-stop is the W14-clean break-replacement. It is correct *provided values are distinct*; equal values stop the inner loop (stable, fine). Comparisons use equality-against-1 only (W11/Trap 3 safe).
3. **Concatenate** sorted values into module-scope `SHAPEN_CONCAT`: loop `k = 0 .. n`, copy 32 bytes from `sn_val_ptr(order[k])` to `SHAPEN_CONCAT[k*32 ..]` via an inner byte loop (W14). 
4. `ident_from_bytes(&SHAPEN_CONCAT, (n as u64) * 32u64, out_id)` — `Keccak256` over the sorted concatenation (M1 NIH hashing; deterministic — sorted input ⇒ identical hash regardless of acceptance order, M2/W5).
5. Return `SHAPEN_OK`.
Bit-identity (W5/M10): sorting before hashing makes the global-section id a *canonical* function of the accepted *set*, independent of registration/peel order.

### Helpers `sn_val_ptr` / `sn_op_ptr`
`return (&SHAPEN_VALUE[(slot as u64) & 0xFFFFFFFFu64) * 32u64]) as *u8` — see Trap 4 fix (G3): mask the slot before multiply.

## KAT Vectors (>= 3)
A Phase-2 `sn_selftest() -> u64` (99 = pass) must check these byte-for-byte. (Requires `numera/sat.iii` linked and `wh_init(0u64)` called first.)

**KAT-1 — no conflicts ⇒ accept all.**
- Input: `sn_init()`; register 3 sections with distinct values V0,V1,V2 and distinct op ids O0,O1,O2; declare NO conflicts; `cap = cap_env_init()` (root, has AMEND); `sn_negotiate(cap)`.
- Expected: return `== 3i32`; `sn_is_accepted(0)==1 && sn_is_accepted(1)==1 && sn_is_accepted(2)==1`. (Pure SAT — all soft clauses satisfiable, no hard clauses.)

**KAT-2 — one conflict ⇒ peel lex-smallest op id, accept the other.**
- Input: `sn_init()`; register section sA with `op_id = OA` (lex-smaller, e.g. 32 bytes `0x00..`) and section sB with `op_id = OB` (lex-larger, e.g. `0x01,0x00..`); values differ; `sn_declare_conflict(sA, sB)`; `sn_negotiate(cap)`.
- Expected: return `== 1i32`; `sn_is_accepted(sA) == 0u8` (OA is lex-smaller ⇒ peeled by `sn_peel_target`); `sn_is_accepted(sB) == 1u8`. This pins the deterministic tie-break (the load-bearing determinism property).

**KAT-3 — global section is order-invariant (canonicality).**
- Input run A: register V_hi then V_lo (where `ident_cmp(V_lo, V_hi) == -1`), no conflicts, negotiate, `sn_global_section(&idA)`.
- Input run B: fresh `sn_init()`, register V_lo then V_hi (reversed registration order), no conflicts, negotiate, `sn_global_section(&idB)`.
- Expected: `ident_eq(&idA, &idB) == 1u8` (both hash `Keccak256(V_lo || V_hi)` after the lex sort — identical 32-byte id), AND `idA != Keccak256(V_hi || V_lo)` (proves the sort actually fired, not a tautology — confirm one specific byte differs from the unsorted-concat hash).

**KAT-4 (capability gate, proves the negative case) — denial refuses to mutate.**
- Input: build state with 2 accepted-able sections; mint a child cap WITHOUT amend: `bad = cap_attenuate(cap_env_init(), CAP_RIGHT_FS_READ, 0u64)`; call `sn_negotiate(bad)`.
- Expected: return `== SHAPEN_E_CAP` (-2); `sn_is_accepted(*) == 0u8` (no mutation occurred); `wh_next_idx()` unchanged (no witness published). This proves G7's gate FAILS closed on insufficient rights (per MEMORY: prove the negative case, not just the positive).

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED conceptually; AVOIDED: every signature in §Public API and §Skeleton is single-line. The 12-parameter `wh_publish` extern must stay single-line in the extern block (it is).
- **Trap 2 (linker-global const)** — EXPOSED; AVOIDED: all consts prefixed `SHAPEN_`; grep-confirmed zero collisions in `STDLIB/`.
- **Trap 3 (signed ordering compare SIGSEGV)** — EXPOSED via `ident_cmp -> i32` results; AVOIDED: every i32-compare is equality-only (`== -1i32`, `== 1i32`, `!= 1i32`, `== SHAPEN_E_CAP`). All `<`/`>=` compares in the body are on **u32** (unsigned — not subject to Trap 3). No `i64`/`i32` ordering anywhere.
- **Trap 4 (u32-in-u64-slot pointer math)** — EXPOSED: `sn_val_ptr`/`sn_op_ptr` do `(slot as u64) * 32u64` for pointer arithmetic; `slot` is a u32 local/param. AVOIDED (G3): mask `(slot as u64) & 0xFFFFFFFFu64` before the multiply in both helpers. The `SHAPEN_CONCAT[(k as u64)*32u64 + z]` index likewise masks `k`.
- **Trap 5 (u32 pointer store width)** — NOT EXPOSED: the only `*u32` writes are into `SHAPEN_CL2`/`SHAPEN_CL1` which are `[u32; N]` arrays written as full u32 literals destined for `sat_add_clause` (no adjacent-slot aliasing concern — they are standalone scratch arrays, and the value width matches the slot). The accepted-count payload is stored **byte-by-byte through `*u8`** (`SHAPEN_PL4`), which is the Trap-5-safe pattern.
- **Trap 6 (nested `/* */`)** — AVOIDED: header + inline comments use single-level `/* */` and `//`; no nesting.
- **Trap 7 (local `var` arrays)** — EXPOSED in the gospel body (`cl`, `u`, `in_c`, `out_c`, `fid`, `pl`, `order`, `concat` are all function-local `var` arrays — ILLEGAL in iiis). AVOIDED (G2): all eight moved to module scope as `SHAPEN_CL2/CL1/INC/OUTC/FID/PL4/ORDER/CONCAT`. Reentrancy loss documented.
- **Trap 8 (`} else {` one line)** — NOT EXPOSED: the body uses no `else` (all `if` are guard-style); Phase 2 must keep any introduced `else` on one line.
- **Trap 9 (em-dash in comment)** — AVOIDED: all comments use ASCII `--`/`//`; no U+2014. (This spec's prose em-dashes do NOT enter the `.iii` file.)
- **Trap 10 (`let mut` checkpoint flag)** — PRESENT but BENIGN: `sn_negotiate` uses `let mut done : u8` and `let mut iter`. These are genuine loop-control counters driving the `while done == 0u8` condition (the W14-correct pattern), NOT a misused checkpoint flag. Acceptable; matches the insertion-sort/active-flag idiom used across STDLIB. Phase 2 must ensure `done`/`iter` drive the loop condition directly (they do).
- **Trap 11 (`a % b` after call)** — NOT EXPOSED: no modulo anywhere in the module.
- **Trap 12 (`@specialize *T` stride)** — NOT EXPOSED: module is not generic; no `@specialize`.

## Gap / Fix List
The gospel candidate body is PARTIAL. Every gap, with its fix:

- **G1 — Prefix mismatch (dispatch vs gospel).** Gospel uses `SN_`; dispatch assigns `SHAPEN_`. **Fix:** rename every module-level `const`/`var`/internal symbol `SN_* → SHAPEN_*` (rename map is §Constant Namespace + §Data Structures). Confirmed `SHAPEN_` collision-free.
- **G2 — Trap 7 violations (function-local `var` arrays), 8 sites.** `cl`/`u` (in `sn_encode_and_solve`), `in_c`/`out_c`/`fid`/`pl` (in `sn_negotiate`), `order`/`concat` (in `sn_global_section`) are local `var` arrays — these do NOT parse in iiis. **Fix:** declare all as module-scope buffers (`SHAPEN_CL2`, `SHAPEN_CL1`, `SHAPEN_INC`, `SHAPEN_OUTC`, `SHAPEN_FID`, `SHAPEN_PL4`, `SHAPEN_ORDER`, `SHAPEN_CONCAT`); reference by name. Non-reentrancy documented.
- **G3 — Trap 4 exposure in `sn_val_ptr`/`sn_op_ptr`.** `(slot as u64) * 32u64` does pointer math on a u32 widened to u64 without masking the high 4 bytes. **Fix:** `((slot as u64) & 0xFFFFFFFFu64) * 32u64`. Same mask on the `k`/`z` index in `sn_global_section`'s concat copy.
- **G4 — `wh_init` precondition undocumented.** `wh_publish` returns `0xFFFF...FFFFu64` (silent failure) if `WH_INITED == 0`. The gospel body never ensures the witness hook is initialized. **Fix:** document that `wh_init(initial_time)` (and the substrate's `at_*` clock) MUST be initialized by the boot path before `sn_negotiate`; optionally, Phase 2 may check `wh_publish`'s return for the all-ones sentinel and surface a distinct status. Recommended: leave init to the substrate boot (matches every other aether module) but ADD a return-value check on `wh_publish` so a witness-hook-full condition doesn't get silently swallowed (currently the body ignores `wh_publish`'s return entirely).
- **G5 — Unused extern `ident_eq`.** Declared by the gospel but never called in the body. **Fix:** either drop the extern (cleanest) or use it in KAT-3's canonicality check. Spec retains it (used in `sn_selftest` KATs); Phase 2 may drop from the production extern block if `sn_selftest` lives in a separate test file.
- **G6 — Latent slot/var-range fragility (no unregister path).** `sat_init(SHAPEN_COUNT)` allocates variables `1..SHAPEN_COUNT`, but `SHAPEN_ACCEPT_VAR[s] = s+1` indexes by *slot*. This is correct ONLY because sections are never freed (slots stay dense). **Fix:** document the invariant explicitly (done in §Algorithm `sn_encode_and_solve`); if a future `sn_unregister` is added, it MUST either compact slots or `sat_init` must be sized to `SHAPEN_MAX_SEC` (the max live var id) rather than the count. No code change now; flagged so Phase 2 does not add a naive free.
- **G7 — M8 (capability mediation) violation.** `sn_negotiate` mutates the global hardware classification AND publishes a witness fragment — a privileged, shape-amending action — but the gospel signature takes NO capability argument. Per M8 ("privileged actions require an explicit capability argument") and the capability module's discipline ("every IO/amend surface checks cap_verify"). **Fix:** add `env_cap: u64` as the first (only) parameter; gate with `cap_verify_rights(env_cap, SHAPEN_RIGHT_AMEND)` (right bit `0x4000`, the `amend` right per capability.iii §bit 14) at function entry, returning `SHAPEN_E_CAP` on denial. (Arity 1 ≤ W2.) The read-only functions (`sn_register_section`, `sn_declare_conflict`, `sn_is_accepted`, `sn_global_section`) build *pending* state and do not mutate the committed classification or emit witnesses, so they remain uncapped — consistent with fed_admit's read vs. commit split. KAT-4 proves the gate fails closed.
- **G8 — Insertion-sort correctness note (not a bug).** The `q=0` inner-loop early-stop (W14 break-replacement) is correct. One subtlety: it relies on `ident_cmp` giving a total order; equal section values stop the inner loop early (stable, acceptable). No fix; verified.
- **G9 — `sat_value` semantics confirmed (not a bug).** Gospel sat.iii: `sat_value` returns 1=true. Body's `if v == 1u8` correctly marks accepted. Verified against the real API; no change.
- **G10 — Const value sync invariant.** `SHAPEN_SAT_SAT_RC`/`SHAPEN_SAT_UNSAT_RC` mirror `numera::sat`'s `SAT_SAT=1`/`SAT_UNSAT=2`. **Fix:** none needed (values verified equal to gospel sat.iii); flagged as a cross-module invariant Phase 2 must preserve if sat.iii's codes ever change.

**Mandate audit summary:** M1 (NIH — all hashing via identifier/keccak, SAT in-substrate) PASS; M2/W5 (determinism/bit-identity — sorted-hash canonical, deterministic CDCL, fixed loop order) PASS; M3/M4 (no ML/heuristics — lex-min peel is exact, not learned) PASS; M5 (no bricking — bounded loop, refuses-to-overcommit) PASS; M6/M10 (witness continuity/reproducibility — wh_publish chains by hash, fragment recomputable from fixed inputs) PASS; M8 (capability) **FIXED by G7**; M9/W16 (reversibility — revtag=0) PASS; M19 (cost bound — ≤COUNT+1 solves) PASS. Remaining mandates (M11–M18, M20) are not engaged by this module's surface.

## Implementation Skeleton
Paste-ready structure. SINGLE-LINE signatures; NO fn bodies (Phase 2 writes those per §Algorithm). ASCII-only comments (Trap 9).

```iii
/* III/STDLIB/iii/aether/shape_negotiator.iii
 *
 * III STDLIB - aether::shape_negotiator
 *
 * Lift local presheaf sections (probe outcomes) to a coherent sheaf
 * section (global hardware classification) by iterated MaxSAT over a
 * deterministic CDCL solver. Hard clauses (-a | -b) per conflict edge;
 * unit soft clauses (accept_s) preferring acceptance; on UNSAT peel the
 * lex-smallest-op-id probe still in conflict and re-solve until SAT.
 * Publishes SHAPE_LIFTED witness; capability-gated on the amend right.
 *
 * Hexad: kind_motion + kind_witness.  Ring: R0.  K: 0.99.
 * Discipline: W2, W8, W9, W10, W12, W13, W14, W15.
 */

module aether_shape_negotiator

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn sat_init(n_vars: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_add_clause(lits: *u32, n_lits: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_solve() -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_value(var: u32) -> u8 from "sat.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const SHAPEN_OK           : i32 =  0i32
const SHAPEN_E_BAD        : i32 = -1i32
const SHAPEN_E_CAP        : i32 = -2i32
const SHAPEN_SENT         : u32 = 0xFFFFFFFFu32
const SHAPEN_SAT_SAT_RC   : i32 =  1i32
const SHAPEN_SAT_UNSAT_RC : i32 =  2i32
const SHAPEN_MAX_SEC      : u32 = 1024u32
const SHAPEN_MAX_CONF     : u32 = 8192u32
const SHAPEN_ID_BYTES     : u64 = 32u64
const SHAPEN_PILLAR       : u16 = 6u16
const SHAPEN_PHASE        : u8  = 5u8
const SHAPEN_RIGHT_AMEND  : u64 = 0x4000u64

var SHAPEN_LIVE        : [u8;  1024]
var SHAPEN_OPEN        : [u32; 1024]
var SHAPEN_VALUE       : [u8;  32768]
var SHAPEN_OP_ID       : [u8;  32768]
var SHAPEN_ACCEPT_VAR  : [u32; 1024]
var SHAPEN_ACCEPTED    : [u8;  1024]
var SHAPEN_DROPPED     : [u8;  1024]
var SHAPEN_COUNT       : u32 = 0u32

var SHAPEN_CONF_A      : [u32; 8192]
var SHAPEN_CONF_B      : [u32; 8192]
var SHAPEN_CONF_COUNT  : u32 = 0u32

var SHAPEN_PRODUCER    : [u8; 32]
var SHAPEN_OPID_LIFT   : [u8; 32]
var SHAPEN_INITED      : u8 = 0u8

/* module-scope scratch (Trap 7: no function-local var arrays) */
var SHAPEN_CL2         : [u32; 2]
var SHAPEN_CL1         : [u32; 1]
var SHAPEN_INC         : [u8; 32]
var SHAPEN_OUTC        : [u8; 32]
var SHAPEN_FID         : [u8; 32]
var SHAPEN_PL4         : [u8; 4]
var SHAPEN_ORDER       : [u32; 1024]
var SHAPEN_CONCAT      : [u8; 32768]

fn sn_val_ptr(slot: u32) -> *u8 { return (&SHAPEN_VALUE[((slot as u64) & 0xFFFFFFFFu64) * 32u64]) as *u8 }
fn sn_op_ptr(slot: u32) -> *u8 { return (&SHAPEN_OP_ID[((slot as u64) & 0xFFFFFFFFu64) * 32u64]) as *u8 }

fn sn_init() -> i32 @export { /* TODO: body per Algorithm sn_init */ return SHAPEN_OK }

fn sn_register_section(open_set: u32, value: *u8, op_id: *u8) -> u32 @export { /* TODO: body per Algorithm sn_register_section */ return SHAPEN_SENT }

fn sn_declare_conflict(a: u32, b: u32) -> i32 @export { /* TODO: body per Algorithm sn_declare_conflict */ return SHAPEN_OK }

fn sn_encode_and_solve() -> i32 { /* TODO: body per Algorithm sn_encode_and_solve */ return SHAPEN_SAT_UNSAT_RC }

fn sn_peel_target() -> u32 { /* TODO: body per Algorithm sn_peel_target */ return SHAPEN_SENT }

fn sn_negotiate(env_cap: u64) -> i32 @export { /* TODO: body per Algorithm sn_negotiate -- cap gate first */ return SHAPEN_E_CAP }

fn sn_is_accepted(slot: u32) -> u8 @export { /* TODO: body per Algorithm sn_is_accepted */ return 0u8 }

fn sn_global_section(out_id: *u8) -> i32 @export { /* TODO: body per Algorithm sn_global_section */ return SHAPEN_OK }
```
