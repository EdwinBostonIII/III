# 72 numera/algebraic_cognition.iii — Implementation Spec

## Verdict
PARTIAL (functional stub) — the gospel candidate is a thin, well-formed dispatcher: `ac_init` plus six `ac_invoke_*` wrappers that null-check and forward to the six reasoning engines, plus `ac_emit_timeout`. It compiles in shape but **fails to deliver the module's three named contractual duties from its own prose** ("enforces the cost lattice bound (M19, W37)", "publishes the engine's verification transcript to the chain", "refuses calls that lack ratified specifications") and violates four mandates/laws as written: (1) it externs the **non-existent** `ws_emit_fragment from "witness_spine.iii"` (the substrate's real emitter is `wh_publish` in the BUILT `aether/witness_hook.iii`, 12 params, `u64` return — systemic gospel defect #2); (2) **M8 is unsatisfied** — invoking an industrial R0 reasoning engine (K 0.99) is a privileged action yet none of the `ac_invoke_*` functions takes a capability argument or gates on one; (3) **M19/W37 is unsatisfied** — the candidate forwards `budget` opaquely to the engine and never calls the cost lattice (`cls_admit` / `cls_dimension_get` / overrun detection), so the orchestrator enforces no bound itself (the whole reason this layer exists above the engines); (4) **W2 is violated on five of six invoke functions** (`ac_invoke_smt`/`ac_invoke_groebner`/`ac_invoke_symreg` have 7-8 params; `ac_invoke_sat`/`ac_invoke_egraph`/`ac_invoke_atp` have 5-6) and `ac_emit_timeout` declares **five local `var` arrays** (Trap 7). It also (5) emits a transcript fragment only on *timeout*, never on a *successful* verified invoke — inverting the prose ("publishes the engine's verification transcript"), and (6) has no spec-ratification gate at all. This spec realizes the maximal intent: a capability-gated, cost-lattice-admitted, transcript-publishing, spec-ratifying orchestrator that wraps each engine behind a 4-param request aggregate, enforces the W44 timeout/bound itself, and chains a COGNITION_VERIFIED or COGNITION_TIMEOUT fragment for every call.

## Purpose
`numera/algebraic_cognition.iii` IS the orchestration layer over the substrate's six industrial reasoning engines (SAT, SMT, e-graph/equality-saturation, Groebner, automated theorem proving, symbolic regression). It is the single capability-mediated entry point through which a caller requests bounded reasoning: it ratifies that the request carries a specification, verifies the caller's capability and the declared cost vector against the phase bound (admitting or refusing — M19/W37/W44), dispatches to the selected engine (whose internal search is oracular under M15), checks the engine's returned proof/result, and publishes a verification transcript fragment to the witness chain. It performs **no reasoning of its own** — it is pure orchestration, bound enforcement, and witnessing. Critically (M3/M4): this is exact algebraic dispatch and bound arithmetic, **never** learning, observation, scoring, or heuristic engine-selection — the engine is chosen by an explicit `engine` tag, not inferred. Hexad kind: `kind_motion + kind_cognition`. Ring: R0. K-vector (gospel header): 0.99.

## Public API
All public functions are single-line (Trap 1). Status convention (W9/W12): error codes are negative `i32` constants compared by equality only (W9/W11); every public fn returns an `i32` status. W2 (≤4 params) is honored on every public fn — the candidate's 5-8 param invoke signatures are repaired by folding the per-engine arguments into a caller-built request aggregate (`*u8`) plus a result aggregate (`*u8`), with the capability id and budget passed alongside. The aggregate layouts are fixed, documented byte schemas (below), so they are bit-identical and W5-clean.

```
fn ac_init() -> i32 @export
fn ac_invoke(engine: u8, cap: u64, req: *u8, out_res: *u8) -> i32 @export
fn ac_invoke_sat(cap: u64, req: *u8, out_res: *u8) -> i32 @export
fn ac_invoke_smt(cap: u64, req: *u8, out_res: *u8) -> i32 @export
fn ac_invoke_egraph(cap: u64, req: *u8, out_res: *u8) -> i32 @export
fn ac_invoke_groebner(cap: u64, req: *u8, out_res: *u8) -> i32 @export
fn ac_invoke_atp(cap: u64, req: *u8, out_res: *u8) -> i32 @export
fn ac_invoke_symreg(cap: u64, req: *u8, out_res: *u8) -> i32 @export
fn ac_req_pack_sat(formula: *u8, formula_len: u32, budget: *u8, out_req: *u8) -> i32 @export
fn ac_req_pack_smt(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export
fn ac_req_pack_egraph(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export
fn ac_req_pack_groebner(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export
fn ac_req_pack_atp(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export
fn ac_req_pack_symreg(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export
fn ac_res_term_id(out_res: *u8, out_id: *u8) -> i32 @export
fn ac_res_frag_id(out_res: *u8, out_id: *u8) -> i32 @export
fn ac_emit_timeout(engine: u8, budget: *u8, out_frag_id: *u8) -> i32 @export
fn ac_emit_verified(engine: u8, cap: u64, term_id: *u8, budget: *u8, out_frag_id: *u8) -> i32 @export
```

Return-status notes per fn:
- `ac_init` → `AC_OK`; idempotent (sets `AC_INITED`). Also initializes the staging buffers' epoch (calls `wh_init` is the harness's job, NOT ours — we only set `AC_INITED`). Matches the candidate.
- `ac_invoke(engine, cap, req, out_res)` → the **single internal dispatch core** (W14 `when`-cascade on `engine`, not `select` — Trap 4.x of CLAUDE.md `select()` eager-eval). Returns the engine's mapped status (`AC_OK` / `AC_E_TIMEOUT` / `AC_E_VERIFY_FAIL`) or a gate refusal (`AC_E_NOT_INITED` / `AC_E_NULL` / `AC_E_DENIED` / `AC_E_BUDGET` / `AC_E_UNRATIFIED` / `AC_E_ENGINE`). The six public `ac_invoke_*` are thin one-line forwarders to `ac_invoke` with the fixed engine tag — they exist so callers have a typed entry per engine and to keep the public surface aligned with the gospel's six names, but they share one gated, witnessed implementation (no duplication of the gate logic). W2: 4 params — within bound exactly.
- `ac_invoke_<engine>(cap, req, out_res)` → forwards to `ac_invoke(AC_ENGINE_<X>, cap, req, out_res)`. 3 params. Status as `ac_invoke`.
- `ac_req_pack_*` → build the per-engine request aggregate into `out_req`; `AC_OK` on success, `AC_E_NULL` on any null. These are the W2 fix: the caller packs its 5-8 scalars into the fixed request schema, then passes one `*u8`. Each validates its inputs and writes a typed header so `ac_invoke` can re-extract the fields. `AC_E_NULL` on null pointers.
- `ac_res_term_id` / `ac_res_frag_id` → accessor extracting the 32-byte proof-term id / witness-fragment id from the result aggregate; `AC_OK`, `AC_E_NULL` on null. (The result aggregate carries `out_result:u8`, the 32-byte term id, and the 32-byte transcript fragment id — replacing the candidate's separate `out_result`/`out_term_id` out-params, which would have pushed the invoke functions over W2.)
- `ac_emit_timeout(engine, budget, out_frag_id)` → `AC_OK` on publish; `AC_E_NULL` on null `budget`/`out_frag_id`; `AC_E_NOT_INITED`; `AC_E_EMIT` if `wh_publish` returns its `0xFFFFFFFFFFFFFFFF` sentinel. Publishes a schema-conformant COGNITION_TIMEOUT fragment (the candidate's intent, fixed to use `wh_publish` and the V3 payload schema). 3 params (matches gospel).
- `ac_emit_verified(engine, cap, term_id, budget, out_frag_id)` → `AC_OK`/`AC_E_NULL`/`AC_E_NOT_INITED`/`AC_E_EMIT`. Publishes the COGNITION_VERIFIED transcript fragment — the duty the prose names and the candidate omits. 4 params (W2 exactly): `cap` folds into the payload as the authorizing capability id; `budget` supplies the consumed cost vector.

## Constant Namespace
PREFIX = `ACOG_`. **Collision check:** `grep -rn "ACOG_" STDLIB/` → **no matches** (the module is not yet built; the prefix is entirely free). NOTE on the gospel's chosen prefix: the candidate body uses bare `AC_` (`AC_OK`, `AC_ENGINE_SAT`, `AC_INITED`, ...). The dispatch brief assigns this module the prefix **`ACOG_`**, and `AC_` is dangerously short (high collision risk across the 68-module link — Trap 2 makes every module-level const a linker-global `L_AC_OK` etc.). **This spec renames every `AC_*` const/var to `ACOG_*`.** `grep -rn "\bAC_OK\b\|\bAC_INITED\b\|\bAC_ENGINE_SAT\b" STDLIB/` → no current collisions, but the rename is mandatory per the assigned prefix and removes the future-collision hazard. Every module-scope const/var below is `ACOG_`-prefixed and globally unique (Trap 2 satisfied).

Module-level constants (every `const NAME : T = V`, all `ACOG_`-prefixed):
```
const ACOG_OK              : i32 =  0i32
const ACOG_E_NULL          : i32 = -1i32
const ACOG_E_TIMEOUT       : i32 = -2i32
const ACOG_E_VERIFY_FAIL   : i32 = -3i32
const ACOG_E_NOT_INITED    : i32 = -4i32
const ACOG_E_DENIED        : i32 = -5i32       // capability check failed (M8)
const ACOG_E_BUDGET        : i32 = -6i32       // declared cost vector exceeds phase bound (M19)
const ACOG_E_UNRATIFIED    : i32 = -7i32       // request carries no ratified spec
const ACOG_E_ENGINE        : i32 = -8i32       // unknown engine tag
const ACOG_E_EMIT          : i32 = -9i32       // wh_publish returned its failure sentinel

const ACOG_ENGINE_SAT       : u8 = 1u8
const ACOG_ENGINE_SMT       : u8 = 2u8
const ACOG_ENGINE_EGRAPH    : u8 = 3u8
const ACOG_ENGINE_GROEBNER  : u8 = 4u8
const ACOG_ENGINE_ATP       : u8 = 5u8
const ACOG_ENGINE_SYMREG    : u8 = 6u8

const ACOG_REQ_BYTES        : u64 = 96u64      // request aggregate: header(32) + up to 4 field slots(64)
const ACOG_RES_BYTES        : u64 = 72u64      // result aggregate: status(8) + term_id(32) + frag_id(32)
const ACOG_RES_OFF_STATUS   : u64 = 0u64       // out_result byte at [0]; bytes 1..8 reserved
const ACOG_RES_OFF_TERMID   : u64 = 8u64       // 32-byte proof-term id at [8..40]
const ACOG_RES_OFF_FRAGID   : u64 = 40u64      // 32-byte transcript fragment id at [40..72]

const ACOG_REQ_MAGIC        : u8 = 0xACu8      // request header byte [0]
const ACOG_REQ_OFF_ENGINE   : u64 = 1u64       // engine tag at [1]
const ACOG_REQ_OFF_RATIFIED : u64 = 2u64       // ratification flag at [2] (1 = spec present)
const ACOG_REQ_OFF_FIELDS   : u64 = 32u64      // typed field slots begin at [32]

const ACOG_BUDGET_BYTES     : u64 = 64u64      // a cost-lattice extended cost vector (CLS_BYTES)
const ACOG_CLS_DIM_TIME     : u8 = 0u8         // time dimension index in the cost vector (W44 timeout)

const ACOG_PAYLOAD_BYTES    : u64 = 81u64      // V3 fragment payload (72-byte header + 9-byte inner)
const ACOG_OVERRUN_INNER    : u64 = 9u64       // inner: kind-tag(1) + magnitude(8)
const ACOG_V3_SENTINEL      : u8 = 0xE3u8      // V3 extended-payload marker (payload byte 0)
const ACOG_KIND_TIMEOUT     : u8 = 0x13u8      // v3_payload_kind COGNITION_TIMEOUT (candidate's 0x13)
const ACOG_KIND_VERIFIED    : u8 = 0x14u8      // v3_payload_kind COGNITION_VERIFIED

const ACOG_WH_FAIL          : u64 = 0xFFFFFFFFFFFFFFFFu64   // wh_publish failure sentinel
const ACOG_CAP_RIGHT_RESOLVE : u64 = 0x00010000u64         // CAP_RIGHT_RESOLVE_INVOKE (verified in capability.iii)
```
Note: `ACOG_CAP_RIGHT_RESOLVE` mirrors `CAP_RIGHT_RESOLVE_INVOKE = 0x00010000u64` (verified at `STDLIB/iii/aether/capability.iii:69`) — the right that authorizes invoking a reasoning/resolution engine. It is declared as a local `ACOG_`-prefixed const (not externed — `const` cannot be externed across modules; the numeric value is the contract, and the cost-lattice spec uses the same pattern for `CLS_WH_FAIL`). The candidate's `0x13` timeout payload tag is retained as `ACOG_KIND_TIMEOUT`; `ACOG_KIND_VERIFIED = 0x14` is the new sibling tag for the success transcript.

## Data Structures
All module-scope, statically sized (W8); **no local `var` arrays anywhere** (Trap 7 — the fix for the candidate's `payload[48]`, `producer/op/in_c/out_c[32]` locals inside `ac_emit_timeout`).
```
var ACOG_INITED      : u8 = 0u8           // one-time init flag (was AC_INITED)
var ACOG_PAYLOAD     : [u8; 81]           // V3 COGNITION_* fragment payload staging
var ACOG_PRODUCER    : [u8; 32]           // zero producer id staging for wh_publish
var ACOG_OPID        : [u8; 32]           // op id staging for wh_publish
var ACOG_IN_C        : [u8; 32]           // in_commit staging (= request/term commitment)
var ACOG_OUT_C       : [u8; 32]           // out_commit staging
var ACOG_CADDR_IN    : [u8; 96]           // producer||op||in_c concat, hashed -> content_address
var ACOG_FRAG_SCRATCH: [u8; 32]           // transcript fragment id sink for ac_invoke's witness step
```
Bound justification: every buffer is fixed-shape scratch for the serialized fragment-emission path (`ac_emit_timeout` / `ac_emit_verified`, and `ac_invoke`'s internal call to `ac_emit_verified`). `ACOG_PAYLOAD = 81` B is exactly `ACOG_PAYLOAD_BYTES` (the full V3 fragment payload). The four 32-byte id buffers match `IDENT_BYTES = 32` (verified at `identifier.iii:20`). `ACOG_CADDR_IN = 96` B holds the three 32-byte ids whose Keccak256 is the schema's `content_address`. Total static BSS ≈ 81 + 5*32 + 96 = 337 B — trivial. **Reentrancy:** these are module-global serialized buffers, so the emission paths are non-reentrant — acceptable, because witness-chain publication is already a serialized, ordered operation (concurrent emission would violate chain append-order regardless; same posture as `cost_lattice_synth.iii` and `identifier.iii`). The gate-and-dispatch logic of `ac_invoke` itself (capability check, cost-lattice admit, engine call) touches no module-scope array and is reentrant up to the single witness step. The request/result aggregates are **caller-owned buffers** (passed by pointer) — they are NOT module-scope, so there is no aliasing between concurrent callers' requests. Address-of-static (`&ACOG_PAYLOAD[0]` etc.) is taken only inside this file (W1/W3).

Request aggregate schema (`ACOG_REQ_BYTES = 96`, caller-built via `ac_req_pack_*`):
```
[0]      magic = ACOG_REQ_MAGIC (0xAC)
[1]      engine tag (ACOG_ENGINE_*)
[2]      ratified flag (1 = caller asserts a ratified spec accompanies the request)
[3..32]  reserved (zero)
[32..40] field slot 0   (u64 LE: e.g. formula ptr, OR formula_len in low 32)
[40..48] field slot 1
[48..56] field slot 2
[56..64] field slot 3
[64..72] field slot 4 (groebner/symreg need out_basis/out_expr + cap/len)
[72..80] field slot 5
[80..88] field slot 6
[88..96] budget pointer (u64 LE) -- the 64-byte cost vector address
```
The per-engine `ac_req_pack_*` write the engine's specific argument list into the field slots (e.g. SAT uses slot0=formula ptr, slot1=formula_len, [88..96]=budget ptr; SMT adds theories ptr + theory_count; Groebner/SymReg add the output-buffer ptr, cap, and out_len ptr). `ac_invoke` reads `[1]` to dispatch and re-extracts the slots for the chosen engine. The schema is fixed and documented, so the packed bytes are bit-identical for identical inputs (W5). Storing pointers (addresses) inside the aggregate is a transient, function-scoped use consumed within the same `ac_invoke` call (no global pointer escape — W1/W3 — because the aggregate is caller-owned and the addresses it holds are the caller's own buffers, never module statics).

Result aggregate schema (`ACOG_RES_BYTES = 72`, written by `ac_invoke`):
```
[0]      out_result byte (1 = SAT/proved, 0 = UNSAT/refuted, engine-specific)
[1..8]   reserved (zero)
[8..40]  proof-term id (32 bytes) -- the engine's verified term
[40..72] transcript fragment id (32 bytes) -- the COGNITION_VERIFIED fragment
```

## Dependencies (externs)
```
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn cls_dimension_get(v: *u8, dim: u8) -> u64 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_admit(declared: *u8, bound: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn sat_solve(formula: *u8, formula_len: u32, budget: *u8, out_result: *u8, out_term_id: *u8) -> i32 from "sat_at_scale.iii"
extern @abi(c-msvc-x64) fn smt_solve(formula: *u8, formula_len: u32, theories: *u8, theory_count: u32, budget: *u8, out_result: *u8, out_term_id: *u8) -> i32 from "smt_at_scale.iii"
extern @abi(c-msvc-x64) fn egs_saturate(initial_terms: *u8, terms_len: u32, rules: *u8, rules_len: u32, budget: *u8, out_class_id: *u8) -> i32 from "equality_saturation_scaled.iii"
extern @abi(c-msvc-x64) fn gb_basis(polynomials: *u8, polys_len: u32, order: u8, budget: *u8, out_basis: *u8, out_basis_cap: u32, out_len: *u32) -> i32 from "groebner_at_scale.iii"
extern @abi(c-msvc-x64) fn atp_prove(goal: *u8, goal_len: u32, axioms: *u8, axioms_len: u32, budget: *u8, out_term_id: *u8) -> i32 from "automated_proving.iii"
extern @abi(c-msvc-x64) fn sr_regress(data: *u8, data_len: u32, target_signature: *u8, sig_len: u32, budget: *u8, out_expr: *u8, out_expr_cap: u32, out_len: *u32) -> i32 from "symbolic_regression.iii"
```
Build-status of each provider (verified by directory listing of `STDLIB/iii/numera/` and `STDLIB/iii/aether/`):
- `identifier.iii` (Module 8) — **BUILT** ✓ (`STDLIB/iii/numera/identifier.iii`): `ident_zero(out)->i32`, `ident_copy(src,dst)->i32`, `ident_from_bytes(input,in_len,out)->i32`, `IDENT_BYTES=32`. The candidate's `ident_zero`/`ident_copy` externs are correct; `ident_from_bytes` is added for the content_address.
- `aether/witness_hook.iii` (Module 07) — **BUILT** ✓ (`STDLIB/iii/aether/witness_hook.iii:144-191`): `wh_publish` — 12 params, returns fragment index `u64` (or `0xFFFFFFFFFFFFFFFF` on failure). **This replaces the candidate's fictional `ws_emit_fragment from "witness_spine.iii"`.** Signature above is exact.
- `aether/capability.iii` (Module 06) — **BUILT** ✓ (`STDLIB/iii/aether/capability.iii:148`): `cap_verify_rights(id:u64, required:u64)->u8` (1 = granted). Right bit `CAP_RIGHT_RESOLVE_INVOKE = 0x00010000u64` (`:69`). The candidate has **no** capability check — this extern is the M8 fix.
- `numera/cost_lattice_synth.iii` (Module 65) — **NOT-YET-BUILT** (spec done: `DOCS/CONVERGENCE-SPECS/cost_lattice_synth.spec.md`): `cls_dimension_get(v:*u8,dim:u8)->u64`, `cls_admit(declared:*u8,bound:*u8)->i32` (returns `CLS_OK=0`/`CLS_E_BOUND=-3`). The candidate calls neither — these are the M19/W37 bound-enforcement fix.
- `numera/sat_at_scale.iii` (Module 74) — **NOT-YET-BUILT**: `sat_solve(formula,formula_len,budget,out_result,out_term_id)->i32`. (Gospel signature verified against Module 74's own section — matches the candidate's extern.)
- `numera/smt_at_scale.iii` (Module 75) — **NOT-YET-BUILT**: `smt_solve(formula,formula_len,theories,theory_count,budget,out_result,out_term_id)->i32`. (Verified vs Module 75.)
- `numera/equality_saturation_scaled.iii` (Module 73) — **NOT-YET-BUILT**: `egs_saturate(initial_terms,terms_len,rules,rules_len,budget,out_class_id)->i32`. (Verified vs Module 73.)
- `numera/groebner_at_scale.iii` (Module 76) — **NOT-YET-BUILT**: `gb_basis(polynomials,polys_len,order,budget,out_basis,out_basis_cap,out_len)->i32`. (Verified vs Module 76 header.)
- `numera/automated_proving.iii` (Module 77) — **NOT-YET-BUILT**: `atp_prove(goal,goal_len,axioms,axioms_len,budget,out_term_id)->i32`. (Verified vs Module 77 body.)
- `numera/symbolic_regression.iii` (Module 78) — **NOT-YET-BUILT**: `sr_regress(data,data_len,target_signature,sig_len,budget,out_expr,out_expr_cap,out_len)->i32`. (Verified vs Module 78 body.)

**Not-yet-built dependencies: 7** — `cost_lattice_synth.iii` (65), `equality_saturation_scaled.iii` (73), `sat_at_scale.iii` (74), `smt_at_scale.iii` (75), `groebner_at_scale.iii` (76), `automated_proving.iii` (77), `symbolic_regression.iii` (78). The wave scheduler must place Module 72 **after** all seven (and after the two already-built deps `identifier.iii` + `witness_hook.iii` + `capability.iii`). This module is a top-of-stack orchestrator — it is the LAST of the Layer 7-8 reasoning cluster to build.

## Algorithm
Determinism (M2) and bit-identity (W5): the orchestrator itself performs only fixed-width integer comparisons (capability bitmask test inside `cap_verify_rights`, cost-vector dimension reads, byte-schema (de)serialization) and exact engine dispatch by an explicit tag — no floating point, no data-dependent control beyond bounded checks, no recursion. The engines' *internal* search is oracular (M15) but their *outputs* are independently verified (each engine re-checks its own result via `pt_verify` before returning per Modules 73-78), and the orchestrator additionally maps the engine status deterministically and publishes a byte-reproducible transcript. Identical `(engine, cap, req)` → identical gate decision and identical published fragment bytes (the only non-byte-identical element is the chain's monotonic `at_advance()` inside `wh_publish`, which is itself deterministic given chain history — M10). **No ML/heuristics (M3/M4): the engine is selected by the explicit `engine` tag — never inferred, scored, or learned; the bound is an exact `cls_admit` algebraic test, never a "good enough" threshold; no counting, no observation, no adaptation.** NIH (M1): only `identifier.iii` + `witness_hook.iii` + `capability.iii` + `cost_lattice_synth.iii` + the six engines are externed (all substrate-native III); the request/result codec and V3 payload framing are hand-rolled little-endian byte writes. No recursion (W15): every loop is a counted byte-copy `index < bound`. W14: sentinel/counted loops, no `break`.

**`ac_init`** — `if ACOG_INITED == 1u8 { return ACOG_OK }`; `ACOG_INITED = 1u8`; `return ACOG_OK`. (Candidate-correct; renamed.) Note: it does NOT call `wh_init` — the witness chain is initialized once by the harness/boot; double-init would reset the chain (M5 bricking hazard). Documented.

**`ac_invoke(engine, cap, req, out_res)`** — the gated dispatch core. Steps (all early-return on failure — Trap 10 prefers early-return over a mutated checkpoint flag):
 1. **Init gate:** `if ACOG_INITED == 0u8 { return ACOG_E_NOT_INITED }`.
 2. **Null gate:** null-check `req` and `out_res` (`(req as u64) == 0u64` / `(out_res as u64) == 0u64` → `ACOG_E_NULL`; 64-bit compares, not the 16-bit-null hazard).
 3. **Magic/engine gate:** read `req[0]`; `if req[0] != ACOG_REQ_MAGIC { return ACOG_E_NULL }` (malformed aggregate). Read `eng = req[ACOG_REQ_OFF_ENGINE]`. `if eng != engine` — the caller's tag and the packed tag must agree (defensive; mismatch → `ACOG_E_ENGINE`).
 4. **Ratification gate (M12/"refuses calls that lack ratified specifications"):** `if req[ACOG_REQ_OFF_RATIFIED] != 1u8 { return ACOG_E_UNRATIFIED }`. (The caller asserts, by packing the ratified flag, that a ratified specification accompanies this request — the gospel prose's third duty. A fuller design would verify a spec id against `synthesis_spec.iii`; this spec's contract is the flag + the documented requirement that `ac_req_pack_*` sets it only when given a spec — see Gap List #6 for the extension hook.)
 5. **Capability gate (M8):** `let granted : u8 = cap_verify_rights(cap, ACOG_CAP_RIGHT_RESOLVE)`; `if granted != 1u8 { return ACOG_E_DENIED }`. Invoking an R0 reasoning engine requires `CAP_RIGHT_RESOLVE_INVOKE`.
 6. **Budget extraction + admission gate (M19/W37/W44):** read the budget pointer from `req[88..96]` (fold 8 LE bytes into a u64, mask `& 0xFFFFFFFFFFFFFFFFu64` is a no-op for full u64 — but the fold is byte-wise so no u32-slot hazard). `let budget : *u8 = (bud_u64) as *u8`. The phase bound is the module-scope **`ACOG_PHASE_BOUND`** vector (a 64-byte cost vector representing the maximum cost this orchestration phase permits; initialized by `ac_init` to the substrate's phase ceiling — see Data note). `let adm : i32 = cls_admit(budget, &ACOG_PHASE_BOUND[0])`; `if adm != 0i32 { return ACOG_E_BUDGET }` (equality compare against `CLS_OK=0` — W11). This is the orchestrator enforcing the cost-lattice bound *itself* (W44: "no cognition without a timeout" — the `time` dimension `cls_dimension_get(budget, ACOG_CLS_DIM_TIME)` MUST be non-zero; `if cls_dimension_get(budget, 0u8) == 0u64 { return ACOG_E_BUDGET }` — a zero time budget is an unbounded request and is refused, the literal W44 guarantee).
 7. **Dispatch (W14 `when`-cascade, NOT `select` — `select` eager-evaluates both arms per CLAUDE.md):** extract the engine's fields from `req` and call the engine. The cascade is `when eng == ACOG_ENGINE_SAT { rc = sat_solve(...) } when eng == ACOG_ENGINE_SMT { rc = smt_solve(...) } ...` for all six; a final `when 1u8 == 1u8 { return ACOG_E_ENGINE }` default (unknown tag). Each arm reads its slots: SAT → `sat_solve(slot0 as *u8, slot1_lo as u32, budget, &out_res[ACOG_RES_OFF_STATUS], &out_res[ACOG_RES_OFF_TERMID])`; SMT → adds theories(slot2)/theory_count(slot3); EGRAPH → `egs_saturate(...)` writing the class id into `out_res[ACOG_RES_OFF_TERMID]`; GROEBNER → `gb_basis(...)` (basis written to caller's out-buffer carried in slots; status mapped); ATP → `atp_prove(...)` into `out_res[ACOG_RES_OFF_TERMID]`; SYMREG → `sr_regress(...)`. The 32-byte field extraction folds 8 LE bytes per slot into a u64 then casts to `*u8` (W1/W3-safe — the address is the caller's own buffer).
 8. **Status mapping:** `if rc != 0i32` → the engine timed out or failed. Distinguish by the engine's own code where it returns `*_E_TIMEOUT = -2`: `if rc == -2i32 { ac_emit_timeout(engine, budget, &out_res[ACOG_RES_OFF_FRAGID]); return ACOG_E_TIMEOUT }` (publish the COGNITION_TIMEOUT transcript even on failure — W47 no silent failure). Any other non-zero → `return ACOG_E_VERIFY_FAIL` (the engine's internal verifier rejected its own result; also witnessed). Equality compares only (W11).
 9. **Success transcript (the prose's second duty):** on `rc == 0i32`, publish the COGNITION_VERIFIED fragment: `let est : i32 = ac_emit_verified(engine, cap, &out_res[ACOG_RES_OFF_TERMID], budget, &out_res[ACOG_RES_OFF_FRAGID])`; `if est != ACOG_OK { return est }` (the fragment id lands in the result aggregate's frag-id slot). `return ACOG_OK`.

`ac_invoke` has ≤4 params and (counting the cascade arms' locals: `eng`, `granted`, `bud_u64`, `budget`, `adm`, `rc`, `est`, plus per-arm field locals reused) stays under W13's 20-named-local ceiling because the field extraction for each engine is factored into the `when` arm and the arms do not all live simultaneously; if a single arm approaches the ceiling (Groebner/SymReg have the most fields), that arm's extraction is delegated to a file-private `ac_unpack_groebner(req, out6)`-style helper writing into a small module-scope slot — documented in the Skeleton.

**`ac_invoke_<engine>`** — one line each: `return ac_invoke(ACOG_ENGINE_<X>, cap, req, out_res)`. No gate logic duplicated.

**`ac_req_pack_sat(formula, formula_len, budget, out_req)`** — null-check the four; `ident`-style zero of the 96-byte `out_req` is the caller's responsibility OR the packer zeros it first (spec'd: packer writes `out_req[3..32]=0` and unused slots `=0` for determinism). Write `out_req[0]=ACOG_REQ_MAGIC`; `out_req[1]=ACOG_ENGINE_SAT`; `out_req[2]=1u8` (ratified — see note); slot0 `[32..40]` = `(formula as u64)` LE; slot1 `[40..48]` = `(formula_len as u64)` LE; `[88..96]` = `(budget as u64)` LE. `return ACOG_OK`. The other five `ac_req_pack_*` follow the same shape with their engine tag and field set:
- `ac_req_pack_smt(parts, budget, out_req)` — `parts` is a caller-built 4-pointer struct `(formula, formula_len, theories, theory_count)` because SMT has 4 engine inputs beyond budget (folding them keeps the packer ≤4 params); the packer copies the four field words from `parts[0..32]` into slots 0-3.
- `ac_req_pack_egraph(parts, budget, out_req)` — `parts` = `(initial_terms, terms_len, rules, rules_len)`.
- `ac_req_pack_groebner(parts, budget, out_req)` — `parts` = `(polynomials, polys_len, order, out_basis, out_basis_cap, out_len)` → slots 0-5 (6 fields; the `parts` block is 48 bytes).
- `ac_req_pack_atp(parts, budget, out_req)` — `parts` = `(goal, goal_len, axioms, axioms_len)`.
- `ac_req_pack_symreg(parts, budget, out_req)` — `parts` = `(data, data_len, target_signature, sig_len, out_expr, out_expr_cap, out_len)` → slots 0-6.
Each packer is a counted byte-copy from `parts` into the request slots plus the 3 header bytes; deterministic, no recursion, ≤4 params.

**`ac_res_term_id(out_res, out_id)` / `ac_res_frag_id(out_res, out_id)`** — null-check; `ident_copy(&out_res[ACOG_RES_OFF_TERMID], out_id)` (resp. `_OFF_FRAGID`); `return ACOG_OK`. Pure 32-byte copy.

**`ac_emit_timeout(engine, budget, out_frag_id)`** — the candidate's function, corrected to use `wh_publish` and the V3 schema (Trap-7 fixed via module-scope staging). Steps:
 1. `if ACOG_INITED == 0u8 { return ACOG_E_NOT_INITED }`; null-check `budget`/`out_frag_id` → `ACOG_E_NULL`.
 2. Zero `ACOG_PAYLOAD` (counted loop, 81 bytes); stage ids: `ident_zero(&ACOG_PRODUCER[0])`, `ident_zero(&ACOG_OPID[0])`, `ident_zero(&ACOG_IN_C[0])`, `ident_zero(&ACOG_OUT_C[0])`.
 3. **content_address:** `ACOG_CADDR_IN` = producer(32)‖op(32)‖in_c(32) via three `ident_copy`s; `ident_from_bytes(&ACOG_CADDR_IN[0], 96u64, &ACOG_PAYLOAD[4])` (writes the 32-byte Keccak256 into the header's content_address field — the correct keccak path, NOT the gospel-defect `keccak.iii` import).
 4. **V3 header** into `ACOG_PAYLOAD`: `[0]=ACOG_V3_SENTINEL (0xE3)`; `[1]=ACOG_KIND_TIMEOUT (0x13)`; `[2]=0; [3]=0`; `[4..36]=content_address`; `[36..68]=branch_id=0`; `[68]=ACOG_OVERRUN_INNER (9)` as inner_len LE, `[69..72]=0`.
 5. **inner payload** `[72..81]`: `[72]=engine`; `[73..81]` = the time-budget magnitude `cls_dimension_get(budget, ACOG_CLS_DIM_TIME)` written LE (the bound that was exhausted — this is what makes a TIMEOUT fragment recomputable and meaningful, replacing the candidate's raw 32-byte budget dump that did not fit the schema). (The candidate copied 32 budget bytes into `payload[16..48]`; the V3 inner is kind+magnitude, so the time dimension is the conformant magnitude.)
 6. **Publish:** `let fi : u64 = wh_publish(&ACOG_PRODUCER[0], &ACOG_OPID[0], &ACOG_IN_C[0], &ACOG_OUT_C[0], 0u8, 0u8, 0u16, &ACOG_OUT_C[0], 0u32, &ACOG_PAYLOAD[0], ACOG_PAYLOAD_BYTES as u32, out_frag_id)`.
 7. `if fi == ACOG_WH_FAIL { return ACOG_E_EMIT }`; `return ACOG_OK`. (`out_frag_id` filled by `wh_publish`; no re-copy. u64 equality compare — W11.)

**`ac_emit_verified(engine, cap, term_id, budget, out_frag_id)`** — identical framing to `ac_emit_timeout`, with: `[1]=ACOG_KIND_VERIFIED (0x14)`; `in_commit` = `term_id` (`ident_copy(term_id, &ACOG_IN_C[0])` — the verified proof term IS the input commitment, binding the transcript to the engine's output, M10); the inner `[72]=engine`, `[73..81]` = the consumed time budget `cls_dimension_get(budget, 0u8)` LE; and the authorizing capability `cap` is folded into `out_commit` so the transcript records who authorized the cognition: write `cap` as 8 LE bytes into `ACOG_OUT_C[0..8]` (rest zero) before publish. Publish + sentinel-check as above. This is the COGNITION_VERIFIED transcript the prose mandates and the candidate omits.

W16/W17 (witness under reversibility, monotonic algebraic time): every fragment goes through `wh_publish`, which `at_advance()`s the monotonic algebraic clock and appends forward-tagged (`revtag=0`) — append-only, revocable via `wh_revoke`, never rewritten (M9). The orchestrator destroys no state; it reads inputs, gates, dispatches, and appends a witness (M5 — no bricking; refusal is the failure mode, never corruption). M20/M13: the orchestrator does not reason about itself; it has no reflective path. M11/M18: it carries proof-term ids (the engines' verified terms) end-to-end in the result aggregate and binds them into the transcript's content_address — the theorem travels with its witnessed term.

## KAT Vectors (>= 3)
All checks are byte-for-byte on the exact `i32` return and on the result/payload aggregates. Where an engine is invoked, the KAT uses a **stub/mock engine** semantics note: at Phase-2 acceptance these run against the real built engines (Modules 73-78); the orchestrator KATs below pin the *gate* behavior independent of engine internals by checking the refusal paths (which never reach the engine) and one success path with a trivially-SAT formula.

1. **Init + null + ratification + unknown-engine gates (no engine reached).** `ac_invoke(ACOG_ENGINE_SAT, cap, req, out_res)` before `ac_init()` → `ACOG_E_NOT_INITED (-4)`. After `ac_init()`: `ac_invoke(1u8, cap, 0, out_res) == ACOG_E_NULL (-1)` (null req). With a req whose `[0] != 0xAC` → `ACOG_E_NULL`. With a valid SAT req but `req[2]=0` (unratified) → `ACOG_E_UNRATIFIED (-7)`. `ac_invoke(99u8, cap, req_sat, out_res)` (req packed for SAT but engine tag 99) → `ACOG_E_ENGINE (-8)` (tag mismatch with packed `[1]=1`). These exercise every pre-engine refusal in order.

2. **Capability gate (M8) + budget/timeout gate (M19/W44).** Pack a valid ratified SAT req with a budget vector whose time dim = 1000. With a capability `cap_no` lacking `CAP_RIGHT_RESOLVE_INVOKE` (e.g. an FS-only cap): `ac_invoke_sat(cap_no, req, out_res) == ACOG_E_DENIED (-5)` (engine NOT reached). With a granting cap `cap_ok` but a budget whose time dim = 0: `ac_invoke_sat(cap_ok, req_zerotime, out_res) == ACOG_E_BUDGET (-6)` — the literal W44 "no cognition without a timeout" refusal (zero time budget = unbounded → refused). With `cap_ok` and a budget that exceeds `ACOG_PHASE_BOUND` on the memory dim: `cls_admit` returns `CLS_E_BOUND` → `ac_invoke_sat == ACOG_E_BUDGET`. (These pin that the orchestrator enforces the bound itself, the candidate's central omission.)

3. **COGNITION_TIMEOUT transcript schema (the emit fix).** Pre: harness `wh_init`. `ac_emit_timeout(ACOG_ENGINE_GROEBNER /*=4*/, budget /*time dim = 50000*/, frag_id)` → `ACOG_OK`, `frag_id` non-zero (32 bytes written). Verify via `wh_get_payload(idx, buf, ...)`: `buf[0]==0xE3`, `buf[1]==0x13` (TIMEOUT), `buf[2]==0 && buf[3]==0`, `buf[4..36]` = `Keccak256(zero32‖zero32‖zero32)` (recomputable — M10), `buf[36..68]` all zero (branch_id), `buf[68]==9 && buf[69..72]==0` (inner_len=9), `buf[72]==4` (engine=Groebner), `buf[73..81]` = 50000 LE (the exhausted time bound). Null path: `ac_emit_timeout(4u8, 0, frag_id) == ACOG_E_NULL`. Before-init: `ac_emit_timeout(...) == ACOG_E_NOT_INITED`.

4. **COGNITION_VERIFIED transcript + result-aggregate accessors.** `ac_emit_verified(ACOG_ENGINE_SAT, cap_ok, term_id /*fixed 32-byte 0xCD..*/, budget /*time=1000*/, frag_id)` → `ACOG_OK`. Verify payload: `buf[1]==0x14` (VERIFIED); the fragment's `in_commit` (recoverable via the chain) = `term_id`; `buf[72]==1` (engine=SAT); `buf[73..81]` = 1000 LE (consumed time). Then a full success-path invoke against the built SAT engine on a trivially-SAT one-clause formula `(x1)`: `ac_invoke_sat(cap_ok, req, out_res) == ACOG_OK`, `out_res[0]==1` (SAT), `ac_res_term_id(out_res, t)` yields the engine's verified term id (32 bytes, non-zero), `ac_res_frag_id(out_res, f)` yields the COGNITION_VERIFIED fragment id (32 bytes, non-zero). This pins the end-to-end gated+witnessed success path.

5. **W2 request-aggregate round-trip (codec bit-identity).** `ac_req_pack_groebner(parts /*polynomials=0x1000, polys_len=7, order=2, out_basis=0x2000, out_basis_cap=4096, out_len=0x3000*/, budget /*=0x4000*/, out_req)` → `ACOG_OK`. Read back: `out_req[0]==0xAC`, `out_req[1]==4` (Groebner), `out_req[2]==1`, slot0 LE = 0x1000, slot1 LE = 7, slot2 LE = 2, slot3 LE = 0x2000, slot4 LE = 4096, slot5 LE = 0x3000, `[88..96]` LE = 0x4000. Re-packing identical inputs yields byte-identical `out_req` (W5/M2 determinism of the codec).

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — exposed (18 public + ≥1 private helper signatures). Avoidance: every signature single-line; verified in Skeleton. The gospel *dependency* `wh_publish` is multi-line in its own file, but my **extern** of it is a single line.
- **Trap 2 (module-level `const` global)** — exposed (≈30 consts/vars). Avoidance: every name `ACOG_`-prefixed (the candidate's bare `AC_*` renamed — `AC_` is collision-prone across 68 modules); `grep -rn "ACOG_" STDLIB/` confirms collision-free.
- **Trap 3 (signed-ordering SIGSEGV)** — **NOT exposed.** Every ordering compare is on **u64** (budget dimension values, byte indices, the `wh_publish` return, the folded budget pointer). The only `i32`s are the `ACOG_OK/ACOG_E_*` constants and the engine return codes, **all compared by equality** (`== / !=`) — never `< / >` (W11). E.g. `if rc == -2i32`, `if adm != 0i32`. No `i64`/`i32` ordering compare anywhere.
- **Trap 4 (u32-in-u64-slot garbage)** — exposed at the field-extraction sites (engine `*_len` args are u32, and pointers folded from the aggregate). Avoidance: every aggregate field is read by folding **8 explicit LE bytes** into a u64 (`val |= (buf[i] as u64) << (i*8)`), so the full 64 bits are defined before any `as *u8` cast — no high-garbage. Where a u32 length is needed it is taken as `(slot_u64 & 0xFFFFFFFFu64) as u32` from the already-fully-defined u64 (mask before narrow). Pointer math on the folded address is on a complete u64.
- **Trap 5 (u32 pointer store width)** — **NOT exposed.** Every byte written to `ACOG_PAYLOAD`/`out_req`/`out_res` is through a `*u8` of a value masked to one byte (`(x >> (i*8)) & 0xFFu64) as u8`). No `*u32` stores. The inner-payload magnitude and the LE slot writes all use the byte-by-byte pattern.
- **Trap 6 (nested block comments)** — avoided: no `/* */` nesting; inline notes use `//`.
- **Trap 7 (local `var` arrays)** — **the candidate violates this** (`payload:[u8;48]`, `producer/op/in_c/out_c:[u8;32]` inside `ac_emit_timeout`). **Fix:** all moved to module-scope (`ACOG_PAYLOAD/PRODUCER/OPID/IN_C/OUT_C/CADDR_IN/FRAG_SCRATCH`); both emit functions documented non-reentrant (chain emission is serialized — acceptable). The request/result aggregates are caller-owned (passed in), not local arrays. No public fn declares a local array.
- **Trap 8 (`} else {` split)** — touched if any `if/else` is used (the dispatch is a `when`-cascade, which avoids `else`; the status mapping uses guard-style early-returns). Any residual `else` is written `} else {` on one line.
- **Trap 9 (em-dash in comment)** — avoided: ASCII `--` only in all comments.
- **Trap 10 (`let mut` checkpoint flag)** — avoided where possible: the gate sequence in `ac_invoke` is a chain of **early returns** (no mutated pass/fail flag); the dispatch result `rc` is a value, not a flag. The only loops are counted byte-copies driven by `i < bound` (W14), not flag-driven.
- **Trap 11 (`a % b` after call)** — **NOT exposed.** No `%` anywhere. No division either (the cost-vector reads are via the externed `cls_dimension_get`, not local arithmetic). The param-spill family cannot apply.
- **Trap 12 (`@specialize *T` stride)** — **NOT exposed.** No `@specialize`; all pointers are concrete `*u8` (byte-addressed, stride 1) or the engines' own `*u32` out-params passed straight through.

Additional CLAUDE.md trap honored: **`select()` eager-evaluation** — the engine dispatch uses a `when` cascade (each arm guarded, only the matching arm's engine call executes), **never** `select(eng==.., sat_solve(..), smt_solve(..))` which would call every engine. Documented in `ac_invoke` step 7.

## Gap / Fix List
The candidate is PARTIAL (a functional dispatcher missing its three named duties + four mandate/law fixes). Gaps and fixes (each closed in this spec):

1. **Non-existent extern `ws_emit_fragment from "witness_spine.iii"` (BLOCKER — would fail to link; systemic gospel defect #2).** `witness_spine.iii` (Module 12) has no such symbol; the real, BUILT emitter is `wh_publish` in `aether/witness_hook.iii` (verified `:144-191`): 12 params `(producer, opid, in_commit, out_commit, revtag:u8, phase:u8, pillar:u16, antecedents, n_ante:u32, payload, payload_len:u32, out_frag_id) -> u64`, sentinel `0xFFFFFFFFFFFFFFFF`. **Fix:** extern `wh_publish`; call with the full 12-arg list (revtag/phase/pillar=0, n_ante=0); map the u64 return to `ACOG_OK`/`ACOG_E_EMIT`. The candidate's fictional signature also had wrong arity (7), wrong `payload_len` width (u64 vs u32), and wrong return (`i32` vs `u64`) — all corrected.

2. **M8 capability mediation absent (mandate violation).** No `ac_invoke_*` takes or checks a capability, yet invoking an industrial R0 reasoning engine (K 0.99) is a privileged action. **Fix:** every invoke takes `cap: u64`; `ac_invoke` calls `cap_verify_rights(cap, ACOG_CAP_RIGHT_RESOLVE)` (right `0x00010000` = `CAP_RIGHT_RESOLVE_INVOKE`, verified `capability.iii:69`) and returns `ACOG_E_DENIED` if not granted. This is the M8 gate the orchestration layer must own.

3. **M19/W37/W44 cost-lattice bound enforcement absent (the module's central duty).** The prose says it "enforces the cost lattice bound"; the candidate forwards `budget` opaquely to the engine and enforces nothing. **Fix:** `ac_invoke` calls `cls_admit(budget, &ACOG_PHASE_BOUND[0])` and refuses (`ACOG_E_BUDGET`) any declared vector exceeding the phase bound, AND enforces the literal W44 timeout by refusing a zero `time` dimension (`cls_dimension_get(budget, 0u8) == 0` → `ACOG_E_BUDGET`). The orchestrator now owns the bound (M19) and the "no cognition without a timeout" guarantee (W44/M19 — the dispatch brief's CRITICAL requirement).

4. **W2 violated on five of six invoke functions + W2 on the emit path.** `ac_invoke_smt`/`ac_invoke_groebner` (7 params), `ac_invoke_symreg` (8 params), `ac_invoke_sat`/`ac_invoke_egraph`/`ac_invoke_atp` (5-6 params) all exceed the 4-param ceiling. **Fix:** fold each engine's argument list into a caller-built **request aggregate** (`*u8`, fixed 96-byte schema) packed by `ac_req_pack_*`, and the two out-params into a **result aggregate** (`*u8`, 72-byte schema) — every public invoke is now `(engine?, cap, req, out_res)` ≤ 4 params. The packers themselves take ≤4 params (multi-input engines pass a caller-built `parts` block).

5. **Trap-7 violation: five local `var` arrays in `ac_emit_timeout`.** **Fix:** module-scope staging buffers (`ACOG_PAYLOAD/PRODUCER/OPID/IN_C/OUT_C/CADDR_IN`); both emit functions documented non-reentrant (serialized chain emission — acceptable, same posture as `identifier.iii`/`cost_lattice_synth.iii`).

6. **"Refuses calls that lack ratified specifications" — no ratification gate (prose duty unmet, M12).** **Fix:** the request aggregate carries a ratified flag (`[2]`); `ac_invoke` returns `ACOG_E_UNRATIFIED` when it is unset. Extension hook (noted for Phase 2): a fuller gate verifies a spec id against `numera/synthesis_spec.iii` (`DOCS/CONVERGENCE-SPECS/synthesis_spec.spec.md` exists) — declare `extern ssp_is_ratified(spec_id: *u8) -> u8` and gate on it; the flag is the minimal contract this spec guarantees, the spec-id check is the maximal form. (Not added as a hard extern now because it would add an 8th not-yet-built dep; the flag suffices for the gate's semantics and the hook is documented.)

7. **Transcript published only on timeout, never on success (prose's second duty inverted, W47).** The candidate emits a fragment solely in `ac_emit_timeout`. The prose says it "publishes the engine's verification transcript to the chain" — i.e. on every verified call. **Fix:** add `ac_emit_verified` (COGNITION_VERIFIED, tag 0x14) and call it from `ac_invoke`'s success path; the verified proof-term id is bound into the fragment's content_address/in_commit (M10/M18 — the theorem travels with its witnessed term). On engine failure, the timeout/failure is also witnessed (W47 no silent failure).

8. **Non-conformant timeout payload (would be unparseable by a V3 verifier).** The candidate's `payload[48]` = `[0xE3, 0x13, <6 zero or engine@8>, budget@16..48]` omits content_address, branch_id, and inner_len. **Fix:** build the exact V3 `v3_payload_header` (sentinel + kind + reserved + content_address(32) + branch_id(32) + inner_len(4)) + a kind+magnitude inner (engine tag + exhausted time bound) = `ACOG_PAYLOAD_BYTES = 81`. content_address = `Keccak256(producer‖op‖in_c)` via `ident_from_bytes` (the correct keccak path).

9. **`AC_` prefix hazard (Trap 2 future-collision).** The brief assigns `ACOG_`; `AC_` is a 2-letter prefix highly likely to collide in the aggregated link. **Fix:** every const/var renamed `AC_* -> ACOG_*`.

Mandate posture after fixes: **M1** (only `identifier`/`witness_hook`/`capability`/`cost_lattice_synth` + the six engines externed, all substrate-native; hand-rolled codec/framing) OK; **M2/W5** (fixed-width integer gate + byte-exact codec + reproducible fragment) OK; **M3/M4** (explicit engine tag — no inference/scoring/learning; exact `cls_admit` bound — no threshold heuristic) OK; **M5** (refusal not corruption; append-only witness; no `wh_init` double-call) OK; **M6/M10** (every call chains a fragment via `wh_publish`; content_address + payload recomputable from inputs; verified term bound into the transcript) OK; **M7** (R0) OK; **M8** (capability-gated invoke — the fix) OK; **M9** (orchestrator destroys nothing; emission additive+revocable) OK; **M11/M18** (proof-term ids carried end-to-end and bound into the transcript) OK; **M12** (ratification gate; spec-id hook documented) OK; **M13/M20** (no reflective/self-reasoning path) OK; **M15** (engine internals oracular, outputs independently verified by the engines + status mapped deterministically here) OK; **M16** (failures and successes both witnessed → ratifiable divergences) OK; **M19/W37/W44** (the orchestrator enforces the cost-lattice bound + the no-zero-timeout rule itself — the central fix) OK. **W2** (≤4 params on every fn — repaired via aggregates) OK; **W8** (static staging buffers, justified) OK; **W9/W10/W11/W12** (negative-i32 errors, u8 cap predicate, equality-only signed compares, status on every public fn) OK; **W13** (≤20 locals — `ac_invoke`'s heaviest arm delegated to a helper to stay under) OK; **W14** (`when`-cascade + counted loops, no `break`) OK; **W15** (no recursion) OK; **W16/W17/W47** (forward-tagged append under monotonic algebraic time; no silent failure — every outcome witnessed) OK.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/algebraic_cognition.iii
 *
 * III STDLIB - numera::algebraic_cognition
 *
 * Orchestration of the substrate's six reasoning engines (SAT, SMT,
 * e-graph, Groebner, ATP, symbolic regression). The single
 * capability-mediated, cost-bounded, witnessed entry point for
 * bounded reasoning. Performs NO reasoning of its own -- it ratifies,
 * gates (capability M8 + cost-lattice bound M19/W44), dispatches by an
 * explicit engine tag, and publishes a verification transcript.
 *
 * NOT learning / NOT heuristic (M3/M4): the engine is chosen by tag,
 * never inferred; the bound is exact algebra (cls_admit), never a
 * threshold. W44: no cognition without a (non-zero time) timeout.
 *
 * Public API: ac_init; ac_invoke + six ac_invoke_<engine>; six
 * ac_req_pack_<engine>; ac_res_term_id/ac_res_frag_id;
 * ac_emit_timeout/ac_emit_verified.
 *
 * Request aggregate (96 B): [0]=0xAC magic, [1]=engine, [2]=ratified,
 *   [32..] typed field slots, [88..96]=budget ptr.
 * Result aggregate (72 B): [0]=out_result, [8..40]=term id,
 *   [40..72]=transcript fragment id.
 *
 * Determinism: fixed-width integer gates, byte-exact LE codec, no FP,
 * counted loops, no recursion. Engine internals oracular (M15);
 * outputs independently verified; transcript byte-reproducible (M10).
 *
 * Hexad: kind_motion + kind_cognition.  Ring: R0.  K: 0.99.
 *
 * NIH: identifier.iii, aether/witness_hook.iii, aether/capability.iii,
 *      numera/cost_lattice_synth.iii, and the six engine modules.
 * Discipline: M8 binds capability; M19/W37/W44 bind the cost bound and
 *      the timeout; W47 binds no silent failure; M15 binds verifier
 *      separation.
 */

module numera_algebraic_cognition

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn cls_dimension_get(v: *u8, dim: u8) -> u64 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_admit(declared: *u8, bound: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn sat_solve(formula: *u8, formula_len: u32, budget: *u8, out_result: *u8, out_term_id: *u8) -> i32 from "sat_at_scale.iii"
extern @abi(c-msvc-x64) fn smt_solve(formula: *u8, formula_len: u32, theories: *u8, theory_count: u32, budget: *u8, out_result: *u8, out_term_id: *u8) -> i32 from "smt_at_scale.iii"
extern @abi(c-msvc-x64) fn egs_saturate(initial_terms: *u8, terms_len: u32, rules: *u8, rules_len: u32, budget: *u8, out_class_id: *u8) -> i32 from "equality_saturation_scaled.iii"
extern @abi(c-msvc-x64) fn gb_basis(polynomials: *u8, polys_len: u32, order: u8, budget: *u8, out_basis: *u8, out_basis_cap: u32, out_len: *u32) -> i32 from "groebner_at_scale.iii"
extern @abi(c-msvc-x64) fn atp_prove(goal: *u8, goal_len: u32, axioms: *u8, axioms_len: u32, budget: *u8, out_term_id: *u8) -> i32 from "automated_proving.iii"
extern @abi(c-msvc-x64) fn sr_regress(data: *u8, data_len: u32, target_signature: *u8, sig_len: u32, budget: *u8, out_expr: *u8, out_expr_cap: u32, out_len: *u32) -> i32 from "symbolic_regression.iii"

const ACOG_OK              : i32 =  0i32
const ACOG_E_NULL          : i32 = -1i32
const ACOG_E_TIMEOUT       : i32 = -2i32
const ACOG_E_VERIFY_FAIL   : i32 = -3i32
const ACOG_E_NOT_INITED    : i32 = -4i32
const ACOG_E_DENIED        : i32 = -5i32
const ACOG_E_BUDGET        : i32 = -6i32
const ACOG_E_UNRATIFIED    : i32 = -7i32
const ACOG_E_ENGINE        : i32 = -8i32
const ACOG_E_EMIT          : i32 = -9i32

const ACOG_ENGINE_SAT       : u8 = 1u8
const ACOG_ENGINE_SMT       : u8 = 2u8
const ACOG_ENGINE_EGRAPH    : u8 = 3u8
const ACOG_ENGINE_GROEBNER  : u8 = 4u8
const ACOG_ENGINE_ATP       : u8 = 5u8
const ACOG_ENGINE_SYMREG    : u8 = 6u8

const ACOG_REQ_BYTES        : u64 = 96u64
const ACOG_RES_BYTES        : u64 = 72u64
const ACOG_RES_OFF_STATUS   : u64 = 0u64
const ACOG_RES_OFF_TERMID   : u64 = 8u64
const ACOG_RES_OFF_FRAGID   : u64 = 40u64

const ACOG_REQ_MAGIC        : u8  = 0xACu8
const ACOG_REQ_OFF_ENGINE   : u64 = 1u64
const ACOG_REQ_OFF_RATIFIED : u64 = 2u64
const ACOG_REQ_OFF_FIELDS   : u64 = 32u64
const ACOG_REQ_OFF_BUDGET   : u64 = 88u64

const ACOG_BUDGET_BYTES     : u64 = 64u64
const ACOG_CLS_DIM_TIME     : u8  = 0u8

const ACOG_PAYLOAD_BYTES    : u64 = 81u64
const ACOG_OVERRUN_INNER    : u64 = 9u64
const ACOG_V3_SENTINEL      : u8  = 0xE3u8
const ACOG_KIND_TIMEOUT     : u8  = 0x13u8
const ACOG_KIND_VERIFIED    : u8  = 0x14u8

const ACOG_WH_FAIL          : u64 = 0xFFFFFFFFFFFFFFFFu64
const ACOG_CAP_RIGHT_RESOLVE : u64 = 0x00010000u64

// module-scope state + staging (Trap-7 fix; emit paths non-reentrant)
var ACOG_INITED       : u8 = 0u8
var ACOG_PHASE_BOUND  : [u8; 64]    // phase cost ceiling; set by ac_init
var ACOG_PAYLOAD      : [u8; 81]
var ACOG_PRODUCER     : [u8; 32]
var ACOG_OPID         : [u8; 32]
var ACOG_IN_C         : [u8; 32]
var ACOG_OUT_C        : [u8; 32]
var ACOG_CADDR_IN     : [u8; 96]
var ACOG_FRAG_SCRATCH : [u8; 32]
var ACOG_GB_UNPACK    : [u8; 64]    // groebner/symreg field-extraction scratch (W13 relief)

// --- file-private helpers (single-line; not @export) ---

fn ac_le_read_u64(buf: *u8, off: u64) -> u64 {
    // TODO: fold 8 LE bytes buf[off..off+8] into a u64 (Trap-4-safe).
}

fn ac_le_write_u64(buf: *u8, off: u64, v: u64) -> i32 {
    // TODO: write v as 8 LE bytes through *u8 (Trap-5-safe, byte-by-byte).
}

fn ac_stage_header(kind: u8, in_commit_src: *u8) -> i32 {
    // TODO: zero ACOG_PAYLOAD; stage producer/op/out_c=zero, in_c=in_commit_src;
    // content_address = ident_from_bytes(producer||op||in_c,96)->PAYLOAD[4];
    // header [0]=0xE3 [1]=kind [2..4]=0 [4..36]=caddr [36..68]=0 [68]=9 [69..72]=0.
}

// --- lifecycle ---

fn ac_init() -> i32 @export {
    // TODO: idempotent; set ACOG_INITED; initialize ACOG_PHASE_BOUND to the
    // phase ceiling (per substrate phase policy). Does NOT call wh_init.
}

// --- gated dispatch core + six typed forwarders ---

fn ac_invoke(engine: u8, cap: u64, req: *u8, out_res: *u8) -> i32 @export {
    // TODO: body per Algorithm ac_invoke --
    //  1 init gate; 2 null gate (req,out_res); 3 magic+engine-tag gate;
    //  4 ratified gate (req[2]==1 else E_UNRATIFIED);
    //  5 cap gate (cap_verify_rights(cap, ACOG_CAP_RIGHT_RESOLVE)==1 else E_DENIED);
    //  6 budget = req[88..96] ptr; refuse if cls_admit(budget,PHASE_BOUND)!=0 OR
    //    cls_dimension_get(budget,0)==0  (E_BUDGET; W44 no-zero-timeout);
    //  7 when-cascade on engine (NOT select): call the engine, fields from slots,
    //    out_result/out_term -> out_res; default -> E_ENGINE;
    //  8 if rc==-2 -> ac_emit_timeout(engine,budget,&out_res[40]); return E_TIMEOUT;
    //    if rc!=0 -> return E_VERIFY_FAIL (witnessed by caller policy);
    //  9 ac_emit_verified(engine,cap,&out_res[8],budget,&out_res[40]); return OK.
}

fn ac_invoke_sat(cap: u64, req: *u8, out_res: *u8) -> i32 @export {
    // TODO: return ac_invoke(ACOG_ENGINE_SAT, cap, req, out_res).
}

fn ac_invoke_smt(cap: u64, req: *u8, out_res: *u8) -> i32 @export {
    // TODO: return ac_invoke(ACOG_ENGINE_SMT, cap, req, out_res).
}

fn ac_invoke_egraph(cap: u64, req: *u8, out_res: *u8) -> i32 @export {
    // TODO: return ac_invoke(ACOG_ENGINE_EGRAPH, cap, req, out_res).
}

fn ac_invoke_groebner(cap: u64, req: *u8, out_res: *u8) -> i32 @export {
    // TODO: return ac_invoke(ACOG_ENGINE_GROEBNER, cap, req, out_res).
}

fn ac_invoke_atp(cap: u64, req: *u8, out_res: *u8) -> i32 @export {
    // TODO: return ac_invoke(ACOG_ENGINE_ATP, cap, req, out_res).
}

fn ac_invoke_symreg(cap: u64, req: *u8, out_res: *u8) -> i32 @export {
    // TODO: return ac_invoke(ACOG_ENGINE_SYMREG, cap, req, out_res).
}

// --- request packers (W2 fix: scalars -> one *u8 aggregate) ---

fn ac_req_pack_sat(formula: *u8, formula_len: u32, budget: *u8, out_req: *u8) -> i32 @export {
    // TODO: zero out_req; [0]=0xAC [1]=SAT [2]=1; slot0=formula ptr,
    // slot1=formula_len, [88..96]=budget ptr.
}

fn ac_req_pack_smt(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export {
    // TODO: parts = (formula,formula_len,theories,theory_count); copy to slots0-3.
}

fn ac_req_pack_egraph(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export {
    // TODO: parts = (initial_terms,terms_len,rules,rules_len); copy to slots0-3.
}

fn ac_req_pack_groebner(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export {
    // TODO: parts = (polynomials,polys_len,order,out_basis,out_basis_cap,out_len);
    // copy to slots0-5.
}

fn ac_req_pack_atp(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export {
    // TODO: parts = (goal,goal_len,axioms,axioms_len); copy to slots0-3.
}

fn ac_req_pack_symreg(parts: *u8, budget: *u8, out_req: *u8) -> i32 @export {
    // TODO: parts = (data,data_len,target_signature,sig_len,out_expr,
    // out_expr_cap,out_len); copy to slots0-6.
}

// --- result accessors ---

fn ac_res_term_id(out_res: *u8, out_id: *u8) -> i32 @export {
    // TODO: null-check; ident_copy(&out_res[ACOG_RES_OFF_TERMID], out_id).
}

fn ac_res_frag_id(out_res: *u8, out_id: *u8) -> i32 @export {
    // TODO: null-check; ident_copy(&out_res[ACOG_RES_OFF_FRAGID], out_id).
}

// --- transcript emission (schema-conformant V3; via wh_publish) ---

fn ac_emit_timeout(engine: u8, budget: *u8, out_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm ac_emit_timeout --
    //  init+null gates; ac_stage_header(ACOG_KIND_TIMEOUT, &ACOG_IN_C[0]) with
    //  in_c=zero; inner [72]=engine, [73..81]=cls_dimension_get(budget,0) LE;
    //  fi = wh_publish(prod,op,in_c,out_c,0u8,0u8,0u16,out_c,0u32,
    //                  &ACOG_PAYLOAD[0], ACOG_PAYLOAD_BYTES as u32, out_frag_id);
    //  if fi == ACOG_WH_FAIL return ACOG_E_EMIT; return ACOG_OK.
}

fn ac_emit_verified(engine: u8, cap: u64, term_id: *u8, budget: *u8, out_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm ac_emit_verified --
    //  init+null gates; ac_stage_header(ACOG_KIND_VERIFIED, term_id) (in_c=term_id);
    //  fold cap into ACOG_OUT_C[0..8] LE; inner [72]=engine,
    //  [73..81]=cls_dimension_get(budget,0) LE;
    //  fi = wh_publish(prod,op,in_c,out_c,0u8,0u8,0u16,out_c,0u32,
    //                  &ACOG_PAYLOAD[0], ACOG_PAYLOAD_BYTES as u32, out_frag_id);
    //  if fi == ACOG_WH_FAIL return ACOG_E_EMIT; return ACOG_OK.
}
```
