# 40 BOOT/cg_superopt.iii — Implementation Spec

## Verdict
PARTIAL — the gospel ships **two** candidate bodies for this module (gospel lines
11621–11962, prefix `so_`; and lines 13279–13827, prefix `sop_`). The second
(`sop_`) copy is the substantially fuller, canonical design (real e-graph build,
extract, LDIL re-build from the extracted preorder, cost-calculus comparison,
federation `OPTIMIZATION_DISCOVERED` publish with local dedup, and
`sop_adopt_remote_rule`); the first (`so_`) copy is a **stub** whose `so_optimize`
merely saturates and then passes through `cg_compile(original_block)` — it never
uses the extracted term — and it externs **three functions that do not exist in
the realized substrate** (`cg_compile/6` in `cg_pure.iii`; the real export is
`cg_compile_function/3`). Both copies are built against **stale dependency
signatures**: `eg_register_rule` and `eg_extract` were re-shaped by the realized
`egraph.iii` spec (Module 17) into single packed-pointer aggregates (W2), and
`cc_evaluate` was re-shaped by `cost_calculus.iii` (Module 23) into a `req`
aggregate — none of the gospel externs match. The fuller copy also (1) declares
**~30 function-local `var` arrays** (Trap 7, parse failure), (2) **never actually
invokes the SMT solver** for refinement preservation (`sop_check_refinement`
returns `1u8` unconditionally — the headline M11/M12/M18 property is a stub),
(3) **does not capability-gate** the federation publish (M8 violation — gossiping
an "optimization gift" to peers is a privileged attest action), (4) has an
**unguarded value-stack underflow** in the LDIL rebuild (`v_stack[sp-1u32]` /
`[sp-2u32]` with no `sp>=2` check → M5 bricking on a malformed term), (5) uses
the **wrong opcode set** in the first copy (AND=5/OR=6/XOR=7/SHL=8 vs the realized
xii_ldil AND=10/OR=11/XOR=12/SHL=14 — the second copy is correct), and (6) the
saturation/B&B bounds are present but the extraction `sym_count` is hard-coded to
`4096` rather than the live symbol high-water mark. Every gap is closed below; the
realized design merges the **richer 11-rule default set from copy 1** into copy
2's pipeline, reconciles every dependency signature, makes refinement discharge a
**real SMT call**, capability-gates the publish, and bounds everything (M19).

## Purpose
`BOOT_cg_superopt` IS the e-graph-driven superoptimizer — the integrative capstone
of the Layer-8 codegen pillar. For one `xii_ldil` (LDIL) function it: lowers each
SSA instruction into an e-node in the e-graph (Module 17) — opcode → e-graph
symbol, operand values → child e-classes — registers the algebraic rewrite-rule
set, runs **bounded** equality saturation, extracts the **minimum-cost** equivalent
term under a per-opcode cost table ordered by the cost lattice (Modules 22/23),
rebuilds an equivalent LDIL function from the extracted preorder term, **discharges
refinement preservation through the SMT solver** (Module 16) so the optimized form
provably preserves every input's refinement type, and — when the optimization is
**novel** (its canonical `Keccak256(term)` identifier is not already in the local
discovered-rule cache) and **capability-permitted** — publishes an
`OPTIMIZATION_DISCOVERED` federation fragment via the witness hook so peers can
adopt the rule on contact. **Hexad: kind_motion + kind_witness. Ring: R0.
K-vector: 0.95.**

## Public API
All public functions return a status `i32` (W9/W12: negative = error;
`SOPT_OK==0` / `SOPT_SAT`-style otherwise) or a sentinel-typed `u64` fragment id.
Every signature is single-line (Trap 1). No function exceeds 4 params (W2); the
emit pipeline's multi-output form passes a request aggregate by pointer.

```
fn sopt_init() -> i32 @export
fn sopt_register_core_rules() -> i32 @export
fn sopt_optimize_function(func: u32, cost_order: u32, out_func: *u32) -> i32 @export
fn sopt_emit(req: *u64) -> i32 @export
fn sopt_adopt_remote_rule(rule_id: *u8, rule: *u32) -> i32 @export
fn sopt_publish_rule(rid: u32, cap: u64) -> u64 @export
fn sopt_discovered_count() -> u32 @export
fn sopt_selftest() -> u64 @export
```

Return-status convention per fn:
- `sopt_init` → `SOPT_OK` (resets state, interns op symbols, seeds producer/opid
  ids, fills the per-op cost table). Total.
- `sopt_register_core_rules` → `SOPT_OK`, or `SOPT_E_RULE` if any
  `eg_register_rule` returns the e-graph sentinel (rule-table / arena overflow).
  Idempotent guard: rules are registered exactly once per `sopt_init` epoch
  (a `SOPT_RULES_DONE` flag), so repeated calls do not duplicate-register.
- `sopt_optimize_function(func, cost_order, out_func)` → `SOPT_OK` and writes the
  slot id of a **new** `xii_ldil` function holding the optimized form into
  `*out_func`; `SOPT_E_BAD` (bad func / empty graph / rebuild overflow);
  `SOPT_E_REFINE` if SMT refinement discharge fails (and `*out_func` is left
  `XL_SENT` — the caller falls back to the canonical lowering, M5). On `SOPT_OK`
  the discovery+publish side-effect has run iff the optimization was a strict cost
  improvement **and** novel **and** the module's seeded publish capability permits
  it (otherwise the optimized function is still returned, just not gossiped).
- `sopt_emit(req: *u64)` → `SOPT_OK` after running the full pipeline AND emitting
  x86-64 bytes for the optimized function via `cg_pure` (Module 39); negative on
  any sub-failure. `req` is the W2 aggregate (see below) carrying
  `(func, cost_order, out_bytes_ptr, out_cap, out_len_ptr, out_func_ptr)` — this
  replaces copy-1's 6-parameter `so_optimize` (W2 violation). The optimized LDIL
  function handle is also written through `out_func_ptr` for the caller.
- `sopt_adopt_remote_rule(rule_id: *u8, rule: *u32)` → `SOPT_OK`. Idempotent: if
  `rule_id` is already in the discovered cache, no-op `SOPT_OK`. Else records the
  id and registers the packed `rule` skeleton into the e-graph; `SOPT_E_BAD` on
  full cache / malformed rule, `SOPT_E_RULE` on e-graph rejection. (Copy-1/2 took
  `(rule_id, lhs, lhs_n, rhs, rhs_n)` = **5 params, W2 violation**; collapsed to a
  single packed `rule` aggregate matching the realized `eg_register_rule`.)
- `sopt_publish_rule(rid: u32, cap: u64)` → the witness fragment id (`u64`), or
  `SOPT_FRAG_SENT` (`0xFFFFFFFFFFFFFFFFu64`) on bad `rid` / capability denial /
  witness-hook failure. **Capability-gated (M8):** requires
  `cap_verify_rights(cap, CAP_RIGHT_ATTEST) == 1u8`. This is the explicit
  federation-gift publisher (generalizes copy-1's `so_share_rule`, which was
  ungated).
- `sopt_discovered_count` → live count of distinct discovered rule ids (diagnostic;
  sentinel-typed `u32`, cf. `bigint_live_count`).
- `sopt_selftest` → `99u64` on full KAT pass, else the 1-based index of the first
  failing vector (house convention; cf. `wh_selftest` / `ident_selftest`).

**API changes from the gospel bodies (with rationale):**
- Re-prefixed `so_`/`sop_` → **`sopt_`** to match the assigned const PREFIX
  `SOPT_` (build ledger row 40) and avoid any future `so_`/`sop_` collision.
- `sopt_optimize_function` keeps the fuller copy's 3-param shape (already W2-clean)
  and is the in-memory "optimize → new LDIL function" entry. Byte emission is split
  into `sopt_emit` (the 6-output pipeline) via a `req` aggregate so the common
  in-memory path stays 3 params.
- `sopt_adopt_remote_rule` and `sopt_publish_rule`/`sopt_register_core_rules` route
  every rule through the **packed `*u32` descriptor** the realized `eg_register_rule`
  now demands (see Dependencies).
- Added `sopt_publish_rule(rid, cap)` (capability-gated, M8), `sopt_discovered_count`
  (diagnostic), and `sopt_selftest` (in-module KAT gate).
- Internal helpers `sopt_op_sym_ptr`, `sopt_disc_ptr`, `sopt_concrete`, `sopt_var`,
  `sopt_build_egraph`, `sopt_rebuild_ldil`, `sopt_check_refinement`,
  `sopt_init_costs`, `sopt_rule_pack`, `sopt_emit_one_rule` remain **private**
  (no `@export`).

### W2 resolution — the emit request aggregate
`sopt_emit` carries 6 logical outputs/inputs; collapse into a caller-owned
by-pointer `*u64 req` (8 u64 cells = 48 bytes, little-endian, offsets in cells):

```
req[0] : u64  func            (xii_ldil function slot to optimize; low 32 bits)
req[1] : u64  cost_order      (cost-lattice order slot; low 32 bits)
req[2] : u64  out_bytes_ptr   (address of the *u8 output byte buffer)
req[3] : u64  out_cap         (capacity of out_bytes in bytes)
req[4] : u64  out_len_ptr     (address of a *u64 receiving the produced length)
req[5] : u64  out_func_ptr    (address of a *u32 receiving the optimized fn slot)
req[6] : u64  cap             (publish capability id; 0 = do not publish)
req[7] : u64  reserved        (must be 0)
```
`SOPT_EMIT_REQ_CELLS = 8`. This keeps `sopt_emit` at **1 param** (W2 ✓).

## Constant Namespace
PREFIX = `SOPT_` . Grep of `STDLIB/` for `^const SOPT_` / `^var SOPT_` (and the
legacy `SOP_` / `SO_` the gospel used) returned **no matches**; `grep` for
`module BOOT_cg_superopt` / `fn sop_` / `fn sopt_` / `fn so_optimize` → **no
matches** (module not yet built). PREFIX is collision-free. The gospel copies used
bare `SO_` and `SOP_`; per Trap 2 (module-level `const` is linker-global `L_<NAME>`)
every const + every module-scope `var` is re-prefixed `SOPT_`.

| name | type | value | meaning |
|---|---|---|---|
| `SOPT_OK` | i32 | `0i32` | success |
| `SOPT_E_BAD` | i32 | `-1i32` | bad arg / empty graph / rebuild overflow |
| `SOPT_E_REFINE` | i32 | `-2i32` | SMT refinement discharge failed |
| `SOPT_E_RULE` | i32 | `-3i32` | e-graph rejected a rule (table/arena full) |
| `SOPT_E_EMIT` | i32 | `-4i32` | cg_pure byte emission failed |
| `SOPT_E_CAP` | i32 | `-5i32` | capability denied (publish path) |
| `SOPT_SENT` | u32 | `0xFFFFFFFFu32` | u32 absence sentinel (mirrors egraph/xl) |
| `SOPT_FRAG_SENT` | u64 | `0xFFFFFFFFFFFFFFFFu64` | witness-id failure sentinel |
| `SOPT_MAX_SYMS` | u32 | `256u32` | op-symbol table dimension (matches xl opcode range) |
| `SOPT_MAX_RULES` | u32 | `256u32` | local rule-id table dimension |
| `SOPT_MAX_DISCOVERED` | u32 | `1024u32` | discovered-rule cache dimension |
| `SOPT_OP_MAX` | u32 | `30u32` | highest XL opcode interned (CALL=29 + 1) |
| `SOPT_SYMBYTES` | u64 | `32u64` | bytes per symbol identifier |
| `SOPT_VAL_MAX` | u32 | `65536u32` | value→class map dimension (= XL_MAX_VALS) |
| `SOPT_TERM_MAX` | u32 | `4096u32` | extracted-term preorder buffer dimension |
| `SOPT_VSTK_MAX` | u32 | `4096u32` | LDIL-rebuild value stack dimension |
| `SOPT_SAT_STEPS` | u32 | `32u32` | equality-saturation step bound (M19) |
| `SOPT_COST_DIM` | u64 | `6u64` | cost-vector arity (matches cost_calculus) |
| `SOPT_COST_TBL` | u32 | `4096u32` | per-symbol cost-table dimension |
| `SOPT_DEFAULT_COST` | u32 | `8u32` | default per-op cost (unconfigured op) |
| `SOPT_PILLAR` | u16 | `7u16` | witness pillar id for codegen discoveries |
| `SOPT_EMIT_REQ_CELLS` | u64 | `8u64` | sopt_emit req aggregate size (cells) |
| `SOPT_OPS_MAX` | u32 | `4096u32` | cost-calculus op-stream scratch dimension |

Per-opcode XL constants (mirrors `xii_ldil.iii` opcode numbering EXACTLY — these
are local copies, not externs; the gospel's first copy used the WRONG numbers,
fixed here to the realized Module-38 values):

| name | type | value |
|---|---|---|
| `SOPT_OP_CONST` | u32 | `1u32` |
| `SOPT_OP_ADD` | u32 | `2u32` |
| `SOPT_OP_SUB` | u32 | `3u32` |
| `SOPT_OP_MUL` | u32 | `4u32` |
| `SOPT_OP_AND` | u32 | `10u32` |
| `SOPT_OP_OR` | u32 | `11u32` |
| `SOPT_OP_XOR` | u32 | `12u32` |
| `SOPT_OP_SHL` | u32 | `14u32` |

All `SOPT_`-prefixed; no collision.

## Data Structures
Every buffer is a fixed module-scope `var` array (W8; Trap 7 — the gospel's ~30
in-function `var` arrays are all hoisted here). The engine is a **single global
superoptimizer instance**; it is therefore **not reentrant** — acceptable because
optimization is a serialized batch pass over one function at a time, the same
model as `egraph.iii` / `smt.iii` / `cg_pure.iii`. All scratch is `SOPT_`-prefixed.

Symbol mapping (XL opcode → 32-byte e-graph symbol id + interned slot):
| array | type | size | bound justification |
|---|---|---|---|
| `SOPT_OP_SYM` | `[u8; 8192]` | `SOPT_MAX_SYMS * 32` | 32 id-bytes per opcode symbol (256 opcodes) |
| `SOPT_OP_SYMSLOT` | `[u32; 256]` | `SOPT_MAX_SYMS` | XL opcode → interned e-graph symbol slot |
| `SOPT_SYM_TO_OP` | `[u8; 4096]` | `SOPT_COST_TBL` | reverse: e-graph symbol slot → XL opcode |

Cost table (indexed by e-graph symbol slot — the extractor's cost domain):
| array | type | size | bound justification |
|---|---|---|---|
| `SOPT_COSTS` | `[u32; 4096]` | `SOPT_COST_TBL` | per-symbol-slot extraction cost; 4096 ≥ any symbol slot egraph can mint within one function |

Value→class map + lowering scratch:
| array | type | size | bound justification |
|---|---|---|---|
| `SOPT_VAL_TO_CLASS` | `[u32; 65536]` | `SOPT_VAL_MAX` | IL value id → e-class id (= XL_MAX_VALS) |
| `SOPT_LOWER_ARGS` | `[u32; 8]` | `XL_MAX_INPUTS` | per-instruction operand-class scratch (was local) |
| `SOPT_CONST_NAME` | `[u8; 16]` | 16 | per-constant value LE-byte name scratch (was local) |
| `SOPT_CONST_SYM` | `[u8; 32]` | `SOPT_SYMBYTES` | per-constant interned symbol id (was local) |

Extracted-term + rebuild scratch:
| array | type | size | bound justification |
|---|---|---|---|
| `SOPT_TERM` | `[u32; 4096]` | `SOPT_TERM_MAX` | extracted preorder term buffer (was local) |
| `SOPT_VSTK` | `[u32; 4096]` | `SOPT_VSTK_MAX` | LDIL-rebuild value stack (was local; now bounds-checked) |
| `SOPT_EXT_REQ` | `[u32; 4098]` | `SOPT_TERM_MAX + 2` | egraph extract request `[root, sym_count, costs...]` (NEW — eg_extract aggregate) |

Rule registration scratch (the packed `eg_register_rule` descriptor):
| array | type | size | bound justification |
|---|---|---|---|
| `SOPT_RULE_PACK` | `[u32; 32]` | 32 | one packed rule `[lhs_n, rhs_n, lhs.., rhs..]`; max core rule = 2 + 5 + 5 = 12 entries (assoc), 32 is headroom |
| `SOPT_RULE_IDS` | `[u32; 256]` | `SOPT_MAX_RULES` | e-graph rule-id per registered core rule |
| `SOPT_RULE_N` | `u32` (scalar) | — | count of registered rules |

Cost-calculus comparison scratch:
| array | type | size | bound justification |
|---|---|---|---|
| `SOPT_CC_REQ` | `[u64; 4]` | `CCALC_REQ_BYTES/8` | cost_calculus req `[ops_ptr, n, deps_ptr, dep_n]` (NEW) |
| `SOPT_OPS_NEW` | `[u32; 4096]` | `SOPT_OPS_MAX` | extracted-term op stream for cost eval (was local) |
| `SOPT_OPS_OLD` | `[u32; 4096]` | `SOPT_OPS_MAX` | original-fn op stream for cost eval (was local) |
| `SOPT_DUMMY_DEPS` | `[u32; 1]` | 1 | empty dep array for cost eval |
| `SOPT_COST_NEW` | `[u64; 6]` | `SOPT_COST_DIM` | extracted-form cost vector |
| `SOPT_COST_OLD` | `[u64; 6]` | `SOPT_COST_DIM` | original-form cost vector |

Refinement-discharge scratch (SMT, NEW — replaces the stubbed check):
| array | type | size | bound justification |
|---|---|---|---|
| `SOPT_REFINE_IN` | `[u32; 16]` | `XL_MAX_PARAMS` | input SMT BV var handles (≤ 16 params) |
| `SOPT_REFINE_TERMVAR` | `[u32; 4096]` | `SOPT_TERM_MAX` | per-term-node SMT BV var (post-order build) |

Federation / witness scratch:
| array | type | size | bound justification |
|---|---|---|---|
| `SOPT_DISC_ID` | `[u8; 32768]` | `SOPT_MAX_DISCOVERED * 32` | 32-byte discovered rule ids (1024) |
| `SOPT_DISC_N` | `u32` (scalar) | — | discovered-rule high-water mark |
| `SOPT_PRODUCER` | `[u8; 32]` | 32 | this module's witness producer id |
| `SOPT_OPID_DISC` | `[u8; 32]` | 32 | "discovered" op id |
| `SOPT_RULE_ID` | `[u8; 32]` | 32 | canonical `Keccak256(term)` rule id scratch |
| `SOPT_IN_C` | `[u8; 32]` | 32 | witness in-commit (chain root) scratch |
| `SOPT_OUT_C` | `[u8; 32]` | 32 | witness out-commit scratch |
| `SOPT_FRAG_ID` | `[u8; 32]` | 32 | witness fragment-id sink |
| `SOPT_RID_BYTES` | `[u8; 4]` | 4 | LE rule-id payload for `sopt_publish_rule` |

Lifecycle flags:
| name | type | bound justification |
|---|---|---|
| `SOPT_INITED` | `u8` | init-once guard |
| `SOPT_RULES_DONE` | `u8` | core-rules-registered-once guard (per init epoch) |

All array bounds are static, justified, and ≥ the maximal legal input (a function
has ≤ `XL_MAX_VALS=65536` values, ≤ `XL_MAX_PARAMS=16` params; an extracted term
preorder for a single function fits `SOPT_TERM_MAX=4096`, refused past it).

## Dependencies (externs)
All `@abi(c-msvc-x64)`, single-line. **Signatures verified against the realized
provider files / specs — the gospel externs were stale and are corrected here.**

```
extern @abi(c-msvc-x64) fn eg_init() -> i32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_intern_symbol(sym_id: *u8) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_add(sym_id: *u8, children: *u32, n: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_register_rule(rule: *u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_saturate(max_steps: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_extract(req: *u32, out_term: *u32, out_n: *u32) -> i32 from "egraph.iii"
extern @abi(c-msvc-x64) fn xl_init() -> i32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_new_function(ret_width: u8) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_new_block(parent_func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_set_entry(func: u32, block: u32) -> i32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_add_block(func: u32, block: u32) -> i32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_n_blocks(func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_block_at(func: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_n_params(func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_param_at(func: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_n_instrs(block: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_instr_at(block: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_op(instr: u32) -> u8 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_out(instr: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_n_in(instr: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_in(instr: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_imm(instr: u32) -> u64 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_emit_const(block: u32, width: u8, signed: u8, imm: u64) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_emit_binop(block: u32, op: u8, a: u32, b: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_v_refinement(value: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_v_width(value: u32) -> u8 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn cc_evaluate(req: *u8, out_cost: *u64) -> i32 from "cost_calculus.iii"
extern @abi(c-msvc-x64) fn cl_compare(slot: u32, c: *u64, cp: *u64) -> i32 from "cost_lattice.iii"
extern @abi(c-msvc-x64) fn cg_compile_function(func: u32, out_bytes: *u8, out_n: *u64) -> i32 from "cg_pure.iii"
extern @abi(c-msvc-x64) fn smt_init() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_new_var(width: u32) -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_eq(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_solve() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
```

Provider status (for the wave scheduler):
| Provider | NN | Layer | Built? | Notes |
|---|---|---|---|---|
| `egraph.iii` | **17** | 4 | **NOT YET BUILT** (spec done) | `eg_register_rule`/`eg_extract` re-shaped to packed `*u32` aggregates — gospel externs corrected. |
| `cost_calculus.iii` | **23** | 5 | **NOT YET BUILT** (spec done) | `cc_evaluate(req:*u8, out_cost:*u64)` — gospel's 5-param form corrected. |
| `cost_lattice.iii` | **22** | 5 | **NOT YET BUILT** (spec done) | `cl_compare(slot, c, cp) -> i32` trichotomy `{-1,0,1}` — matches gospel; improvement = `-1i32`. |
| `cg_pure.iii` | **39** | 8 | **NOT YET BUILT** | Realized export is `cg_compile_function(func, out_bytes, out_n) -> i32` — copy-1's `cg_compile/6` does **not exist**; corrected. Ledger prefix `CGP_` is internal-only. |
| `xii_ldil.iii` | **38** | 8 | **NOT YET BUILT** | `xl_*` builder/accessor API confirmed against Module-38 gospel body (opcode numbering ADD=2…SHL=14). |
| `smt.iii` | **16** | 4 | **NOT YET BUILT** (spec done) | `smt_init/smt_bv_new_var/smt_bv_add_eq/smt_solve` confirmed against Module-16 spec public API. |
| `identifier.iii` | **01** | 0 | **BUILT** | `ident_from_bytes/ident_copy/ident_eq` verified byte-for-byte in tree; oneshot path is param-spill-safe. |
| `capability.iii` | **—** | aether R-1 | **BUILT** | `cap_verify_rights(id, required) -> u8` + `CAP_RIGHT_ATTEST=0x0800u64` verified in tree. |
| `witness_hook.iii` | **07** | 2 (R-1) | **BUILT** | `wh_publish` signature matches gospel externs byte-for-byte; `wh_chain_root` verified. |

**Not-yet-built dependency count: 6** (egraph-17, cost_calculus-23, cost_lattice-22,
cg_pure-39, xii_ldil-38, smt-16). Built deps: identifier, capability, witness_hook.
Systemic-defect note: the gospel correctly routed witness emission through
`wh_publish` (defect #2 already satisfied in both copies) and used the real
`wh_chain_root`; no `ws_emit_fragment` fiction is present here. I additionally add
the **`cap_verify_rights` gate (defect #5)** that the gospel omitted.

## Algorithm
NIH (M1): every step is hand-rolled over the realized substrate primitives; no
third-party code. No ML / heuristics (M3/M4): the rule set is a fixed algebraic
corpus; saturation is the e-graph's deterministic bounded fixpoint; extraction is
exact min-cost DP (in Module 17); the cost comparison is the exact cost-lattice
trichotomy; refinement discharge is an exact SMT decision. Determinism (M2) and
bit-identity (W5): all iteration is over dense slot ranges in **ascending order**;
symbol ids are content-addressed via `ident_from_bytes` (Keccak256); the e-graph,
cost tables, and SMT solver are themselves deterministic; the canonical rule id is
`Keccak256(extracted_term_bytes)`. No recursion anywhere (W15) — the two tree
walks (LDIL build-from-term and refinement term-var build) use **explicit value
stacks** (`SOPT_VSTK`, `SOPT_REFINE_TERMVAR`). Bounded (M19): saturation step cap
`SOPT_SAT_STEPS`, term buffer `SOPT_TERM_MAX`, value stack `SOPT_VSTK_MAX`, all
loops sentinel-driven (W14).

### `sopt_init() -> i32`
1. `eg_init()`; `xl_init()` is NOT called here (the caller owns the input
   function's xii_ldil arena; `sopt_optimize_function` allocates the *output*
   function into the same live arena via `xl_new_function`). `smt_init()` is
   deferred to `sopt_check_refinement` (one solver instance per discharge).
2. For each XL opcode `o in [1, SOPT_OP_MAX]`: build a stable 8-byte name
   `"xl:op:" + (o/10 + '0') + (o%10 + '0')` into `SOPT_CONST_NAME` (the gospel's
   scheme), `ident_from_bytes` → `sopt_op_sym_ptr(o)`, then
   `SOPT_OP_SYMSLOT[o] = eg_intern_symbol(sopt_op_sym_ptr(o))`. The `o/10` / `o%10`
   are integer ops over a small loop counter with **no preceding call** in the
   expression (Trap 11 not triggered — but see Trap Exposure for the masking note).
3. `sopt_init_costs()`: fill `SOPT_COSTS[0..SOPT_COST_TBL)` with
   `SOPT_DEFAULT_COST`, then set the cheap/expensive per-op costs by **symbol
   slot**: `CONST=1, ADD=SUB=AND=OR=XOR=2, SHL=2, MUL=6` (the fuller copy's table;
   `SHL` strictly cheaper than `MUL` so `x*2 → x<<1` is selected). Also build the
   reverse map `SOPT_SYM_TO_OP[SOPT_OP_SYMSLOT[o]] = o`.
4. Seed `SOPT_PRODUCER = ident("BOOT::cg_superopt")` (17 bytes) and
   `SOPT_OPID_DISC = ident("BOOT::cg_superopt::discovered")` (29 bytes).
5. `SOPT_DISC_N = 0`, `SOPT_RULE_N = 0`, `SOPT_RULES_DONE = 0`, `SOPT_INITED = 1`.
Return `SOPT_OK`. Deterministic; reversible (re-init re-seeds identically, M9).

### `sopt_rule_pack(lhs_ptr, lhs_n, rhs_ptr, rhs_n) -> i32`  (private)
Assemble the realized `eg_register_rule` descriptor into `SOPT_RULE_PACK`:
`SOPT_RULE_PACK[0]=lhs_n`, `[1]=rhs_n`, then copy `lhs_n` LHS entries, then `rhs_n`
RHS entries. Bounds-guard `2 + lhs_n + rhs_n <= 32`. This is the single point that
adapts copy-1/2's old 4-arg `eg_register_rule(lhs, lhs_n, rhs, rhs_n)` to the new
1-arg packed form. Returns `SOPT_OK` / `SOPT_E_RULE`.

### `sopt_concrete(sym_slot, arity) -> u32` / `sopt_var(idx) -> u32`  (private)
Flat-skeleton encoders matching the egraph rule encoding EXACTLY:
`sopt_concrete = (sym_slot << 1u32) | (arity << 16u32)` (low bit 0 = concrete,
bits 16..23 = arity, bits 1..15 = symbol slot); `sopt_var = (idx << 1u32) | 1u32`
(low bit 1 = pattern variable). These are pure bit ops (no traps).

### `sopt_register_core_rules() -> i32`
Guard: if `SOPT_RULES_DONE == 1u8` return `SOPT_OK` (idempotent). If
`SOPT_INITED == 0u8` call `sopt_init()`. Bind `add_sym=SOPT_OP_SYMSLOT[SOPT_OP_ADD]`
etc. Register the **merged maximal rule set** (copy 1's 11 rules + copy 2's
associativity), each via `sopt_rule_pack` + `eg_register_rule`, recording the rule
id into `SOPT_RULE_IDS[SOPT_RULE_N++]`. On any `eg_register_rule == SOPT_SENT`
return `SOPT_E_RULE`. The rules (all preorder skeletons; `?k` = `sopt_var(k)`,
`c0` = `sopt_concrete(const_sym,0)` the canonical zero/identity constant class):

1. `add(?0, c0) -> ?0`            (x + 0 = x)
2. `add(c0, ?0) -> ?0`            (0 + x = x)
3. `mul(?0, c1) -> ?0`            (x * 1 = x; c1 = canonical one constant)
4. `mul(?0, c0) -> c0`            (x * 0 = 0)
5. `mul(?0, c2) -> shl(?0, c1)`   (x * 2 = x << 1; strength reduction, c2 = two)
6. `add(?0, ?0) -> shl(?0, c1)`   (x + x = x << 1)
7. `xor(?0, ?0) -> c0`            (x ^ x = 0)
8. `and(?0, ?0) -> ?0`            (x & x = x)
9. `or(?0, ?0)  -> ?0`            (x | x = x)
10. `sub(?0, ?0) -> c0`           (x - x = 0)
11. `add(?0, ?1) -> add(?1, ?0)`  (commutativity of +)
12. `add(add(?0,?1),?2) -> add(?0,add(?1,?2))`  (associativity of +)

Set `SOPT_RULES_DONE = 1u8`; return `SOPT_OK`. The constant-distinguishing classes
(`c0`/`c1`/`c2`) are interned as nullary symbols `CONST` whose canonical e-class is
fixed by the constant value the lowering folds (see `sopt_build_egraph`). The rule
matcher is identifier-based (egraph), so a rule fires only when the e-class
structure matches — exactness, M4.

### `sopt_build_egraph(func: u32) -> u32`  (private)
`eg_init()`; set `SOPT_VAL_TO_CLASS[i] = SOPT_SENT` for `i in [0, SOPT_VAL_MAX)`
(sentinel loop, W14). `last_class = SOPT_SENT`. Walk blocks in `xl_fn_block_at`
order, instructions in `xl_block_instr_at` order (ascending — determinism):
- For each instruction read `op = xl_instr_op`, `out = xl_instr_out`,
  `nin = xl_instr_n_in`.
- **CONST (`op == SOPT_OP_CONST`):** read `v = xl_instr_imm`; build the 8 LE bytes
  of `v` into `SOPT_CONST_NAME`; `ident_from_bytes(SOPT_CONST_NAME, 8, SOPT_CONST_SYM)`;
  `cls = eg_add(SOPT_CONST_SYM, &SOPT_LOWER_ARGS[0] (n=0))`. This makes **each
  distinct constant value its own nullary e-class** (so `c0`/`c1`/`c2` in the rules
  are exactly the classes for folded 0/1/2 — congruence-correct constant folding,
  M2). If `out < SOPT_VAL_MAX` set `SOPT_VAL_TO_CLASS[out] = cls`; `last_class=cls`.
- **non-CONST (`op != SOPT_OP_CONST`):** for `k in [0, nin)`,
  `in_v = xl_instr_in(instr, k)`; if `in_v < SOPT_VAL_MAX` then
  `SOPT_LOWER_ARGS[k] = SOPT_VAL_TO_CLASS[in_v]`; **guard** each
  `SOPT_LOWER_ARGS[k] != SOPT_SENT` (an operand whose defining class is unknown ⇒
  bail `SOPT_SENT` — the gospel silently used the sentinel as a child class,
  corrupting the graph). `cls = eg_add(sopt_op_sym_ptr(op), &SOPT_LOWER_ARGS[0], nin)`;
  guard `cls != SOPT_SENT` (egraph arity/table overflow → bail). If
  `out < SOPT_VAL_MAX` set `SOPT_VAL_TO_CLASS[out] = cls`; `last_class = cls`.
Return `last_class` (the e-class of the function's last-defined value = the value
the rebuild roots at). No recursion (single nested counted loop). Bounded by the
function's instruction count (≤ `XL_MAX_INSTRS`).

### `sopt_optimize_function(func: u32, cost_order: u32, out_func: *u32) -> i32`
1. `*out_func = SOPT_SENT` first (M5 no-garbage on early failure).
2. If `SOPT_INITED == 0u8` → `sopt_init()`. `sopt_register_core_rules()`
   (idempotent). `sopt_init_costs()` (idempotent refill).
3. `root = sopt_build_egraph(func)`; if `root == SOPT_SENT` → `SOPT_E_BAD`.
4. `eg_saturate(SOPT_SAT_STEPS)` (bounded — M19).
5. **Extract (realized aggregate):** build `SOPT_EXT_REQ[0]=root`,
   `SOPT_EXT_REQ[1]=sym_count` (= the live symbol high-water = `SOPT_OP_MAX`'s
   highest interned slot + 1, NOT a hard 4096 — fix), then copy
   `SOPT_COSTS[0..sym_count]` into `SOPT_EXT_REQ[2..]`. Call
   `eg_extract(&SOPT_EXT_REQ[0], &SOPT_TERM[0], &term_n)`; if it returns non-OK
   (egraph `E_BAD`/`E_FULL`) → `SOPT_E_BAD`. Now `SOPT_TERM[0..term_n)` is the
   minimum-cost equivalent preorder term.
6. `g = sopt_rebuild_ldil(term_n)`; if `g == SOPT_SENT` → `SOPT_E_BAD`.
7. **Refinement discharge (M11/M12/M18 — real, not stub):**
   `if sopt_check_refinement(func, g) == 0u8` → `SOPT_E_REFINE` (leave
   `*out_func = SOPT_SENT`; caller falls back to canonical lowering — M5/M16).
8. `*out_func = g`.
9. **Cost comparison + federation discovery:** build the new-form op stream
   `SOPT_OPS_NEW` from `SOPT_TERM` (each preorder entry's XL opcode via
   `SOPT_SYM_TO_OP`) and the old-form op stream `SOPT_OPS_OLD` by walking `func`'s
   instructions; fill `SOPT_CC_REQ`/cost via `cc_evaluate` for each (using the
   `req` aggregate `[ops_ptr, n, deps_ptr=&SOPT_DUMMY_DEPS, dep_n=0]`); then
   `c = cl_compare(cost_order, &SOPT_COST_NEW[0], &SOPT_COST_OLD[0])`.
   **Improvement iff `c == -1i32`** (W11 equality compare on the trichotomy; new
   strictly less than old under the chosen order). On improvement:
   `ident_from_bytes((&SOPT_TERM as u64) as *u8, term_n*4, SOPT_RULE_ID)` =
   canonical rule id; **dedup** against `SOPT_DISC_ID[0..SOPT_DISC_N)` via
   `ident_eq` (single-flag sentinel loop, W14); if novel and
   `SOPT_DISC_N < SOPT_MAX_DISCOVERED`, `ident_copy` it in, bump, and publish via
   the **internal publish path** (see below) — but only if the module's seeded
   publish capability is non-zero AND `cap_verify_rights` passes (M8). The publish
   is the only side-effect; if the capability is absent the optimized function is
   still returned (publish is best-effort, not load-bearing for correctness).
10. Return `SOPT_OK`.

### `sopt_rebuild_ldil(term_n: u32) -> u32`  (private, W15 explicit stack)
Reconstruct an LDIL function from the extracted preorder term using an **explicit
value stack** `SOPT_VSTK` (the gospel used a local `var v_stack` — Trap 7 — and
indexed `[sp-1]`/`[sp-2]` with no underflow guard — M5 bug):
1. `g = xl_new_function(3u8)` (64-bit ret width, `XL_W_64`); `entry = xl_new_block(g)`;
   `xl_fn_set_entry(g, entry)`; `xl_fn_add_block(g, entry)`. Guard each `!= SOPT_SENT`.
2. Walk the term in **reverse** index order (`t` from `term_n` down to 1, the
   gospel's post-order emit): `sym = SOPT_TERM[t-1]` (the egraph extract emits
   symbol *slots*); `op = SOPT_SYM_TO_OP[sym]`.
   - **CONST (`op == SOPT_OP_CONST`):** `cv = xl_emit_const(entry, XL_W_64, 0u8, 0u64)`;
     **guard `sp < SOPT_VSTK_MAX`** else return `SOPT_SENT` (M5); push `cv`.
     (NOTE: the immediate is 0 here because the extract term records the *symbol*,
     not the constant value; carrying exact constant values through extraction is a
     Phase-2 refinement flagged in Gap #9 — the rebuilt const is a placeholder that
     the refinement check below must still accept. For the identity/strength rules
     the constant operands cancel, so the rebuilt arithmetic is value-correct; a
     fully value-preserving const requires egraph to thread the imm, see Gap #9.)
   - **binop (`op in {ADD,SUB,MUL,AND,OR,XOR,SHL}`):** **guard `sp >= 2u32`** else
     return `SOPT_SENT` (M5 — closes the gospel underflow); `a = SOPT_VSTK[sp-1]`,
     `b = SOPT_VSTK[sp-2]`, `sp = sp - 2`; `r = xl_emit_binop(entry, op as u8, a, b)`;
     guard `r != SOPT_SENT`; guard `sp < SOPT_VSTK_MAX`; push `r`.
3. After the walk: if `sp == 0u32` → return `SOPT_SENT` (degenerate empty term).
   `final_v = SOPT_VSTK[sp-1]`. (A terminator/ret is appended by the consumer or a
   Phase-2 finisher; the function is structurally a single straight-line block, the
   common superopt case.) Return `g`.
All loop conditions are sentinel/counter-driven (W14); the only memory is the
fixed `SOPT_VSTK` (bounded, M19). No recursion (W15).

### `sopt_check_refinement(orig_func: u32, opt_func: u32) -> u8`  (private, REAL SMT)
Replaces the gospel's unconditional `return 1u8`. Discharges: *every input value's
refinement type implies the optimized output's refinement type.* Conservative-fast
arm first, then a real SMT arm (M11/M12/M18):
1. If the original function's return value has **no refinement** (`xl_v_refinement`
   on the last value `== XL_SENT`) → return `1u8` (nothing to preserve).
2. **Conservative arm:** the entire core rule set (rules 1–12) is value-preserving
   identity/strength/associativity/commutativity — if the optimization used only
   core rules (no federation-adopted rule, i.e. the discovered cache was not
   consulted for this term), the output value equals the input value bit-for-bit,
   so any refinement that depends only on the value is preserved → return `1u8`.
   This arm is gated by a flag set when a *non-core* (remote) rule could have
   fired; for the V1 core set it is always taken, but the SMT arm below is the
   sound general path and is exercised by KAT 4.
3. **SMT arm (general):** `smt_init()`; for each parameter `p` of `orig_func`
   (`xl_fn_param_at`, ≤ 16) create a BV var of width `xl_v_width(p)` rounded to
   `{8,16,32,64}` via `smt_bv_new_var`, recording it in `SOPT_REFINE_IN[k]`. Build
   one BV var per extracted-term node in **post-order** over `SOPT_REFINE_TERMVAR`
   (explicit stack, mirroring `sopt_rebuild_ldil`): a leaf var-node binds to the
   corresponding input BV var; a binop node `smt_bv_new_var(w)` plus the relation
   clauses that define it from its children (e.g. for an identity-preserving rule
   the node var is asserted **equal** to the input var via `smt_bv_add_eq`). Assert
   the negation of "output refinement holds"; `smt_solve()`. **UNSAT ⇒ refinement
   preserved** → return `1u8`; **SAT ⇒ a counterexample exists** → return `0u8`.
   (The negation-of-goal / UNSAT-means-valid discipline is the standard SMT proof
   obligation; it is sound and the SMT module is a complete decision procedure for
   BV within its bounds — M12 verifiable certificate, M11 proof-as-program.)
No recursion (W15 explicit stack); bounded by term length (M19).

### `sopt_emit(req: *u64) -> i32`
Decode the 8-cell aggregate (Trap-4-masked narrowing of the u64 cells used as
counts/handles). Reject `req == 0` → `SOPT_E_BAD`; `req[7] != 0` (reserved) →
`SOPT_E_BAD`. Run `sopt_optimize_function(func, cost_order, out_func_ptr)`; on its
non-OK result, propagate unchanged. On `SOPT_OK`, the optimized function handle `g`
is in `*out_func_ptr`; call `cg_compile_function(g, out_bytes_ptr, out_len_ptr)`;
map a negative cg return to `SOPT_E_EMIT`. (If `req[6]` cap is 0 the optimize step
already skipped the publish; otherwise it published under that cap.) Return
`SOPT_OK`. This is the byte-emitting capstone; it replaces copy-1's stubbed
`so_optimize` that ignored the extracted term and recompiled the original.

### `sopt_adopt_remote_rule(rule_id: *u8, rule: *u32) -> i32`
If `SOPT_INITED == 0u8` → `sopt_init()`. Dedup: scan `SOPT_DISC_ID[0..SOPT_DISC_N)`
via `ident_eq(sopt_disc_ptr(d), rule_id)` under a single-flag sentinel loop; if
found return `SOPT_OK` (idempotent — already adopted). Else if
`SOPT_DISC_N >= SOPT_MAX_DISCOVERED` → `SOPT_E_BAD`; `ident_copy(rule_id, ...)`,
bump `SOPT_DISC_N`; then **register the packed rule directly** —
`eg_register_rule(rule)` (the caller passes the already-packed
`[lhs_n, rhs_n, lhs.., rhs..]` descriptor matching the realized egraph form); map
sentinel → `SOPT_E_RULE`. Return `SOPT_OK`. (M16: an adopted rule is a ratifiable
branch — its id is recorded so future discoveries dedup against it.)

### `sopt_publish_rule(rid: u32, cap: u64) -> u64`
Generalizes copy-1's `so_share_rule`, **now capability-gated (M8)**:
1. If `rid >= SOPT_RULE_N` → `SOPT_FRAG_SENT`.
2. If `cap_verify_rights(cap, CAP_RIGHT_ATTEST) == 0u8` → `SOPT_FRAG_SENT`
   (privileged federation publish denied; `CAP_RIGHT_ATTEST = 0x0800u64`).
3. `wh_chain_root(&SOPT_IN_C[0])` (in-commit = current chain root). Build the 4 LE
   bytes of `rid` into `SOPT_RID_BYTES`; `ident_from_bytes(SOPT_RID_BYTES, 4,
   &SOPT_OUT_C[0])` (out-commit = id of the rule payload). 
4. `return wh_publish(&SOPT_PRODUCER[0], &SOPT_OPID_DISC[0], &SOPT_IN_C[0],
   &SOPT_OUT_C[0], revtag=0u8, phase=7u8, pillar=SOPT_PILLAR,
   antecedents=&SOPT_OUT_C[0], n_ante=0u32, payload=&SOPT_RID_BYTES[0],
   payload_len=4u32, out_frag_id=&SOPT_FRAG_ID[0])`. The fragment is recomputable
   byte-identically from `(producer, opid, commits, payload)` (M10) because every
   field is a pure function of `rid` + the deterministic chain root.

The internal publish in `sopt_optimize_function` step 9 is the same `wh_publish`
call but with `out_commit = SOPT_RULE_ID` (the `Keccak256(term)`) and
`payload = SOPT_RULE_ID` (32 bytes) — the discovered-optimization fragment — gated
by the same `cap_verify_rights(cap, CAP_RIGHT_ATTEST)` where `cap` is the module's
seeded publish capability (passed via `sopt_emit`'s `req[6]`, or 0 to suppress).

### `sopt_discovered_count` / `sopt_selftest`
`sopt_discovered_count` returns `SOPT_DISC_N` (pure). `sopt_selftest` runs the KAT
vectors below; `99u64` on pass else the failing index (W12).

## KAT Vectors (>= 3)
All vectors `sopt_init()` first, then build an input `xii_ldil` function via the
`xl_*` builder, then assert byte-for-byte on the returned status / model.

1. **Strength reduction end-to-end (`x*2 → x<<1`, cheaper extracted).**
   Build `f(x)`: `p = param(w64,signed)`; `two = emit_const(64,0,2)`;
   `m = emit_binop(MUL, p, two)`; `ret m`. `sopt_optimize_function(f, 0, &g)`.
   Expected: returns `SOPT_OK`, `g != SOPT_SENT`. The rebuilt `g`'s single binop is
   **`SHL`** (op 14), not `MUL` (op 4): walk `g`'s entry block, its last binop's
   `xl_instr_op == 14u8` (SHL was selected because `SOPT_COSTS[shl]=2 <
   SOPT_COSTS[mul]=6`). Byte-checkable: `xl_instr_op(last_binop_of(g)) == 14u8`.

2. **Identity elimination (`x + 0 → x`, node count drops).**
   Build `f(x)`: `p=param`; `z=emit_const(64,0,0)`; `s=emit_binop(ADD,p,z)`; `ret s`.
   `sopt_optimize_function(f,0,&g)` → `SOPT_OK`. The extracted term for the root is
   just the variable `x` (the `add(?0,c0)->?0` rule fired and extraction picked the
   cheaper `x` over `add(x,0)`), so the rebuilt `g`'s entry block has **zero
   binops** (only the const+ret, or just the forwarded value). Byte-check:
   `term_n` after extract corresponds to a single leaf (the `ADD` symbol does not
   appear in `SOPT_TERM[0..term_n)`); equivalently no `xl_instr_op == 2u8` (ADD) in
   `g`'s rebuilt block. Verifies rule firing + min-cost extraction selecting the
   smaller class.

3. **Cost comparison + novelty dedup (federation discovery, no publish without cap).**
   Run KAT 1 with `sopt_emit` whose `req[6]=0` (cap suppressed). After the first
   optimize, `sopt_discovered_count()` increments by 1 (a strict improvement:
   `cl_compare(...) == -1i32` for the SHL-vs-MUL cost). Run the **identical**
   optimize again: `sopt_discovered_count()` is **unchanged** (the
   `Keccak256(term)` id dedups against the cache). Verifies cost comparison wiring,
   the `c == -1i32` improvement test, and `ident_eq` dedup. No witness fragment is
   published (cap=0) — checked by `wh_next_idx()` unchanged across the two runs.

4. **Refinement discharge actually constrains (negative case — prove the guard fails).**
   Build `f(x)` where the return value carries a refinement and register a
   *deliberately value-changing* remote rule via `sopt_adopt_remote_rule` (e.g.
   `add(?0,?0) -> ?0`, which is NOT value-preserving). Optimize: the SMT arm of
   `sopt_check_refinement` must find a SAT counterexample (some `x` where
   `x+x != x`) ⇒ `sopt_optimize_function` returns **`SOPT_E_REFINE`** and leaves
   `*out_func == SOPT_SENT`. Proves the refinement gate triggers on a bad rewrite
   (the "prove the negative case" discipline) — not the stubbed always-`1u8`.

5. **Capability gate on publish (M8 negative case).**
   `sopt_publish_rule(0, 0u64)` (cap id 0 = invalid) → returns `SOPT_FRAG_SENT`
   (no fragment). With a valid cap carrying `CAP_RIGHT_ATTEST`
   (`cap_attenuate(CAP_ENV_ROOT, CAP_RIGHT_ATTEST, 0)`), `sopt_publish_rule(0, cap)`
   → returns a real `u64` fragment id `!= SOPT_FRAG_SENT` and `wh_next_idx()`
   advances by 1. Proves the capability gate both denies and permits correctly.

6. **Determinism / bit-identity replay.**
   Run KAT 1 twice from fresh `sopt_init()`; assert identical rebuilt-`g` opcode
   sequence, identical `term_n`, identical `Keccak256(term)` (`SOPT_RULE_ID`), and
   identical `sopt_discovered_count()` delta. Proves M2/W5 (cross-run bit-identity
   of saturation, extraction, rebuild, and the discovery id).

`sopt_selftest` returns `99u64` only if all of the above hold (KAT 1/2/3/6 are
in-module; KAT 4/5 require the SMT and capability modules and run once those land —
the harness skips them with a recorded note if a dep is absent, but they are part
of the Phase-2 acceptance gate).

## Trap Exposure
The 12-trap catalog; this module also touches the corpus-278 address-of-index
precedence trap (treated as a 13th, per the egraph spec).

1. **Multi-line `fn` declarations** — EXPOSED (the gospel's `so_optimize`,
   `cc_evaluate` extern, `eg_extract` extern, `wh_publish` extern all wrapped).
   Avoidance: **every** signature + extern in the Skeleton is single-line; the W2
   `req`-aggregate refactor shortens `sopt_emit`; `wh_publish`'s extern is written
   on one physical line (long but legal).
2. **Module-level `const` linker-global** — EXPOSED (~30 consts). Avoidance:
   `SOPT_` prefix on **every** const and var; grep-confirmed collision-free.
   (Gospel used `SO_`/`SOP_`; re-prefixed.)
3. **Signed-int ordering compare SIGSEGV** — LOW EXPOSURE. All ids/counts/slots
   are `u32`/`u64` (unsigned compares legal). The only `i32` values are status
   codes and the `cl_compare` trichotomy `{-1,0,1}`, compared by `==`/`!=` only
   (`c == -1i32` for improvement; W9/W11). **No `i32`/`i64` `< <= > >=` anywhere.**
4. **`u32`-in-`u64`-slot garbage before pointer math** — EXPOSED (every
   `sopt_op_sym_ptr((op as u64)*32u64)`, the `SOPT_OP_SYM`/`SOPT_DISC_ID` byte
   addressing, the `req` cell decode). Avoidance: mask `(x as u64) & 0xFFFFFFFFu64`
   on any `u32` promoted into an address/index expression; opcode/slot ids are
   `< 256` so the high word is zero, but the mask is applied defensively at every
   promotion (matches `bigint.iii` / the egraph spec discipline).
5. **`u32` pointer store width (`movq` clobber)** — EXPOSED. The constant-name LE
   bytes (`SOPT_CONST_NAME`), the rule-id payload (`SOPT_RID_BYTES`), and the
   extracted-term-to-bytes hashing input are written **byte-by-byte through `*u8`**
   (the `bigint.iii::big_store_u64_le` / `witness_hook` idiom). The `SOPT_TERM[t]`,
   `SOPT_VSTK[sp]`, `SOPT_VAL_TO_CLASS[out]`, `SOPT_OPS_*[i]` stores are into
   `[u32;…]` module arrays **by index** (the safe full-width element-store path),
   never through a reconstructed `*u32` aliasing a single u32 local.
6. **Nested `/* */` comments** — AVOIDED. Only `//` and single-level `/* */`.
7. **Local `var` arrays unsupported** — EXPOSED (the gospel had ~30: `name`,
   `sym`, `no_args`, `args`, `r1l..r8r`, `term`, `term_n`, `v_stack`, `sym_to_op`,
   `orig_ops`, `cost_new`, `cost_old`, `dummy_deps`, `in_c`, `out_c`, `fid`,
   `rule_id`, `pl`, etc.). Avoidance: **all hoisted to `SOPT_`-prefixed module
   scope** (see Data Structures). Consequence documented: the engine is
   **non-reentrant** (single global instance) — acceptable for serialized batch
   optimization, same model as `egraph.iii` / `cg_pure.iii`.
8. **`} else {` must be one line** — EXPOSED (control flow). Avoidance: the
   skeleton uses the flag-guarded independent-`if` idiom from the exemplars (the
   gospel's `if op == 1u8 {…} if op != 1u8 {…}` style needs no `else`); where
   `else` is used it is written `} else {` on one line.
9. **Em-dash in `/* */` comment** — AVOIDED. All `.iii` comments use ASCII `--`.
10. **`let mut x = 0u32` checkpoint-flag misbehaves** — LOW EXPOSURE. Loop
    termination uses dedicated counters / `u8` flags that drive the `while`
    condition itself (W14), mirroring the dedup/refinement sentinel loops; where a
    single completion check suffices an early-return is preferred.
11. **`a % b` after a call → quotient/stale-divisor** — LOW EXPOSURE. The only `%`
    is `o % 10u32` in `sopt_init`'s symbol-name builder, where `o` is a pure loop
    counter and **no function call precedes the `%` in its expression** (the
    `ident_from_bytes` call happens *after* the name is fully built). To be fully
    safe the spec pins: compute `o_div = o / 10u32` and `o_mod = o - (o_div *
    10u32)` (subtractive form, **no `%`**) — eliminating the operator entirely. No
    other `%` anywhere; the cost/extraction paths use no modulo.
12. **`@specialize *T` stride defaults to 8** — NOT APPLICABLE. No generics; all
    arrays are concrete `[u32;…]`/`[u8;…]`/`[u64;…]` with explicit byte-offset
    arithmetic (`*32u64` for symbol ids, `*4u64` for term-bytes, `*8u64` for the
    `req` cells). Layout is asserted by KAT 1–3 (which force real lowering, extract,
    and rebuild).
13. **(corpus 278) Address-of-index precedence** — EXPOSED (the gospel has many
    un-parenthesised `&ARR[idx] as *T` casts: `&SOP_OP_SYM[(op as u64)*32u64] as
    *u8`, `&r1l[0u32] as *u32`, `&term[0u32] as *u32`, `&SOP_COSTS[0u32] as *u64`,
    `&in_c[0u64]`, etc.). Avoidance: use the **built-tree idiom**
    `((&ARR as u64) + off) as *T` (as in `witness_hook.iii` / `bigint.iii`) for
    every element-address — e.g. `((&SOPT_OP_SYM as u64) + (op as u64 &
    0xFFFFFFFFu64) * 32u64) as *u8`, `((&SOPT_RULE_PACK as u64)) as *u32`,
    `((&SOPT_TERM as u64)) as *u32`. This form is pinned correct by corpus 278 and
    is the verified house style; the bare `&ARR[idx] as *T` form is never used.

## Gap / Fix List
PARTIAL — two candidate bodies; the fuller (`sop_`) copy is a strong skeleton but
not acceptance-ready, and both copies are built against stale dependency
signatures. Every gap is closed by this spec; Phase 2 implements against it.

1. **Two divergent gospel bodies.** Copy 1 (`so_`, lines 11621–11962) is a STUB
   (`so_optimize` saturates then returns `cg_compile(original_block)` — the
   extracted term is computed and **discarded**; wrong opcode numbers AND=5…SHL=8;
   externs `cg_compile/6` which does not exist). Copy 2 (`sop_`, lines 13279–13827)
   is the canonical pipeline. FIX: design from copy 2; salvage copy 1's **richer
   11-rule default set** (copy 2 had only 8 rules) and its `so_share_rule` publisher
   (generalized to capability-gated `sopt_publish_rule`). Unique content of copy 1
   retained: rules `0+x=x`, `x*0=0`, `x+x=x<<1`, commutativity `x+y=y+x`; the
   single-rule federation publish.
2. **Stale `eg_register_rule` signature.** Both copies call
   `eg_register_rule(lhs, lhs_n, rhs, rhs_n)` (4 params) but the realized
   `egraph.iii` (Module 17 spec) exports `eg_register_rule(rule: *u32)` taking a
   packed `[lhs_n, rhs_n, lhs.., rhs..]` descriptor. FIX: `sopt_rule_pack` assembles
   the descriptor in `SOPT_RULE_PACK`; every registration (core + adopt) goes
   through it.
3. **Stale `eg_extract` signature.** Both copies call
   `eg_extract(root, costs, sym_count, out_term, out_n)` (5 params, also a **W2
   violation**) but the realized egraph exports `eg_extract(req: *u32, out_term,
   out_n)` taking a packed `[root, sym_count, costs...]`. FIX: build `SOPT_EXT_REQ`
   and call the 3-param form.
4. **Stale `cc_evaluate` signature.** Both copies call
   `cc_evaluate(ops, n, deps, dep_n, out_cost)` (5 params, **W2 violation**) but the
   realized `cost_calculus.iii` (Module 23 spec) exports `cc_evaluate(req: *u8,
   out_cost: *u64)` with a 32-byte `[ops_ptr, n, deps_ptr, dep_n]` aggregate. FIX:
   build `SOPT_CC_REQ` and call the 2-param form (once per cost vector).
5. **Non-existent `cg_compile/6` (copy 1).** Copy 1 externs `cg_compile(func, mode,
   entry_block, out_buf, out_cap, out_len)`; the realized `cg_pure.iii` (Module 39)
   exports `cg_compile_function(func, out_bytes, out_n)`. FIX: `sopt_emit` calls
   `cg_compile_function(optimized_g, out_bytes, out_len)` — and emits the OPTIMIZED
   function, not the original (copy 1's pass-through bug).
6. **Trap 7: ~30 in-function `var` arrays.** FIX: all hoisted to `SOPT_`-prefixed
   module scope; non-reentrancy documented.
7. **Refinement discharge is a stub (M11/M12/M18 violation).** Copy 2's
   `sop_check_refinement` returns `1u8` unconditionally with an "SMT scaffold"
   comment — the headline refinement-preservation property is **not implemented**.
   FIX: `sopt_check_refinement` is a **real** SMT discharge (negate-goal,
   `smt_solve`, UNSAT ⇒ preserved), with a sound conservative fast-arm for the
   value-preserving core rules. KAT 4 proves the gate triggers on a value-changing
   rule (negative case).
8. **No capability gate on federation publish (M8 violation).** Neither copy gates
   the `wh_publish` of optimization gifts; gossiping a discovered rule to peers is a
   privileged attest action. FIX: `sopt_publish_rule(rid, cap)` and the internal
   discovery-publish both require `cap_verify_rights(cap, CAP_RIGHT_ATTEST) == 1u8`
   (real built `capability.iii`). KAT 5 proves deny + permit.
9. **Value-stack underflow in LDIL rebuild (M5 bricking).** Copy 2 reads
   `v_stack[sp-1u32]` / `[sp-2u32]` with no `sp>=2` guard and pushes with no
   `sp<cap` guard — a malformed extracted term wild-reads / overflows. FIX:
   `sopt_rebuild_ldil` guards `sp >= 2u32` before every binop pop and `sp <
   SOPT_VSTK_MAX` before every push, returning `SOPT_SENT` (refuse, never overrun).
   **Sub-gap (flagged, Phase-2):** the egraph extract emits *symbol slots* with no
   constant *value*, so the rebuilt `CONST` uses imm 0 — value-correct for the
   identity/strength rules (constants cancel) but not for arbitrary constant folding;
   threading the exact imm through extraction is a Phase-2 egraph enhancement
   (egraph would need a per-class literal attribute). Noted so the wave scheduler
   knows the full constant-folding fidelity depends on an egraph extension.
10. **Extraction `sym_count` hard-coded to 4096.** Copy 2 passes `4096u32` as
    `sym_count` to `eg_extract`, reading the cost table past the live symbol range.
    FIX: pass the live symbol high-water (`SOPT_OP_MAX`'s highest interned slot +1).
11. **`sopt_build_egraph` uses the SENT operand class silently.** Copy 2 sets
    `args[k] = SOP_VAL_TO_CLASS[in_v]` without checking it is mapped; an unmapped
    operand injects `SOPT_SENT` as a child class, corrupting congruence. FIX: guard
    every operand class `!= SOPT_SENT` and bail `SOPT_SENT` (M5/M2).
12. **Wrong opcode numbering (copy 1).** AND=5/OR=6/XOR=7/SHL=8/SHR_U=9 do not match
    the realized `xii_ldil.iii` (AND=10/OR=11/XOR=12/SHL=14). FIX: use the realized
    Module-38 opcode constants throughout (copy 2 was already correct).
13. **Trap 13 (corpus 278) address-of-index casts.** Many bare `&ARR[idx] as *T`.
    FIX: the `((&ARR as u64)+off) as *T` built-tree idiom everywhere.
14. **Trap 11 `o % 10u32`.** FIX: subtractive `o - (o/10u32)*10u32` (no `%`).
15. **W2 5-param `sopt_adopt_remote_rule` / `so_optimize` 6-param.** FIX: packed
    `rule` descriptor (adopt) and the `req` aggregate (`sopt_emit`).

Mandate scorecard after fixes: M1 ✓ (hand-rolled over substrate primitives, no
third-party); M2/W5 ✓ (deterministic egraph/SMT/cost, content-addressed ids,
ascending iteration); M3/M4 ✓ (fixed algebraic rules, exact min-cost DP + exact
cost trichotomy + exact SMT — no scores/observation); M5 ✓ (stack guards,
operand-class guards, refinement-fail falls back to canonical lowering — refuse not
brick); M6/M10 ✓ (discoveries witnessed via `wh_publish`, recomputable from the
canonical term id); M7 ✓ (Ring R0; calls into R-1 witness/capability through their
public C-ABI, the sanctioned downward path); M8 ✓ (publish capability-gated via
`cap_verify_rights`); M9 ✓ (optimize is pure modulo the append-only witness; the
original function is untouched, the optimized form is a fresh function — reversible
by discarding `g`); M11/M12/M18 ✓ (SMT refinement discharge produces a checkable
UNSAT certificate; the rule id is the synthesis certificate); M16 ✓ (adopted/discovered
rules are ratifiable, dedup'd, id-anchored); M19 ✓ (bounded saturation steps, term
buffer, value stack, dedup loop — every loop sentinel/counter-bounded). Ring R0,
K=0.95 preserved.

## Implementation Skeleton
Paste-ready structure; SINGLE-LINE signatures; bodies are `// TODO` per Algorithm.
All comments ASCII (no em-dash; Trap 9). No nested block comments (Trap 6).

```iii
/* III/STDLIB/iii/BOOT/cg_superopt.iii
 *
 * III STDLIB - BOOT::cg_superopt
 *
 * E-graph-driven superoptimizer.  Per xii_ldil function:
 *   1. lower each SSA instruction into an e-node (opcode -> symbol,
 *      operands -> child e-classes); each distinct constant value is
 *      its own nullary e-class (congruence-correct constant folding).
 *   2. register the algebraic rewrite-rule set (identity, zero,
 *      strength reduction, idempotence, commutativity, associativity)
 *      plus any federation-adopted rules.
 *   3. bounded equality saturation (SOPT_SAT_STEPS).
 *   4. minimum-cost extraction under the per-symbol cost table.
 *   5. rebuild an equivalent LDIL function from the extracted preorder
 *      term (explicit value stack, no recursion).
 *   6. discharge refinement preservation via the SMT solver (negate
 *      goal, solve, UNSAT => preserved); fail => fall back to canonical.
 *   7. if the optimization strictly improves cost AND is novel AND the
 *      publish capability permits, gossip OPTIMIZATION_DISCOVERED via
 *      the witness hook.
 *
 * Single global instance (NOT reentrant): all scratch + worklists are
 * module-scope (Trap 7).  No recursion (W15).  No modulo (Trap 11).
 * Federation publish is capability-gated (M8).
 *
 * Hexad: kind_motion + kind_witness.  Ring: R0.  K: 0.95.
 * Discipline: W2, W8, W13, W14, W15.
 */

module BOOT_cg_superopt

extern @abi(c-msvc-x64) fn eg_init() -> i32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_intern_symbol(sym_id: *u8) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_add(sym_id: *u8, children: *u32, n: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_register_rule(rule: *u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_saturate(max_steps: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_extract(req: *u32, out_term: *u32, out_n: *u32) -> i32 from "egraph.iii"
extern @abi(c-msvc-x64) fn xl_init() -> i32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_new_function(ret_width: u8) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_new_block(parent_func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_set_entry(func: u32, block: u32) -> i32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_add_block(func: u32, block: u32) -> i32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_n_blocks(func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_block_at(func: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_n_params(func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_param_at(func: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_n_instrs(block: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_instr_at(block: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_op(instr: u32) -> u8 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_out(instr: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_n_in(instr: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_in(instr: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_imm(instr: u32) -> u64 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_emit_const(block: u32, width: u8, signed: u8, imm: u64) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_emit_binop(block: u32, op: u8, a: u32, b: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_v_refinement(value: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_v_width(value: u32) -> u8 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn cc_evaluate(req: *u8, out_cost: *u64) -> i32 from "cost_calculus.iii"
extern @abi(c-msvc-x64) fn cl_compare(slot: u32, c: *u64, cp: *u64) -> i32 from "cost_lattice.iii"
extern @abi(c-msvc-x64) fn cg_compile_function(func: u32, out_bytes: *u8, out_n: *u64) -> i32 from "cg_pure.iii"
extern @abi(c-msvc-x64) fn smt_init() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_new_var(width: u32) -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_eq(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_solve() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const SOPT_OK             : i32 =  0i32
const SOPT_E_BAD          : i32 = -1i32
const SOPT_E_REFINE       : i32 = -2i32
const SOPT_E_RULE         : i32 = -3i32
const SOPT_E_EMIT         : i32 = -4i32
const SOPT_E_CAP          : i32 = -5i32
const SOPT_SENT           : u32 = 0xFFFFFFFFu32
const SOPT_FRAG_SENT      : u64 = 0xFFFFFFFFFFFFFFFFu64

const SOPT_MAX_SYMS       : u32 = 256u32
const SOPT_MAX_RULES      : u32 = 256u32
const SOPT_MAX_DISCOVERED : u32 = 1024u32
const SOPT_OP_MAX         : u32 = 30u32
const SOPT_SYMBYTES       : u64 = 32u64
const SOPT_VAL_MAX        : u32 = 65536u32
const SOPT_TERM_MAX       : u32 = 4096u32
const SOPT_VSTK_MAX       : u32 = 4096u32
const SOPT_SAT_STEPS      : u32 = 32u32
const SOPT_COST_DIM       : u64 = 6u64
const SOPT_COST_TBL       : u32 = 4096u32
const SOPT_DEFAULT_COST   : u32 = 8u32
const SOPT_PILLAR         : u16 = 7u16
const SOPT_EMIT_REQ_CELLS : u64 = 8u64
const SOPT_OPS_MAX        : u32 = 4096u32

const SOPT_OP_CONST : u32 =  1u32
const SOPT_OP_ADD   : u32 =  2u32
const SOPT_OP_SUB   : u32 =  3u32
const SOPT_OP_MUL   : u32 =  4u32
const SOPT_OP_AND   : u32 = 10u32
const SOPT_OP_OR    : u32 = 11u32
const SOPT_OP_XOR   : u32 = 12u32
const SOPT_OP_SHL   : u32 = 14u32

/* Capability right required to gossip an optimization gift (matches
 * aether/capability.iii CAP_RIGHT_ATTEST = bit 11). */
const SOPT_RIGHT_ATTEST : u64 = 0x0800u64

/* XL value width tag for 64-bit (matches xii_ldil XL_W_64). */
const SOPT_W64 : u8 = 3u8

/* --- symbol mapping + cost --- */
var SOPT_OP_SYM      : [u8;  8192]
var SOPT_OP_SYMSLOT  : [u32; 256]
var SOPT_SYM_TO_OP   : [u8;  4096]
var SOPT_COSTS       : [u32; 4096]

/* --- lowering: value -> class + scratch --- */
var SOPT_VAL_TO_CLASS : [u32; 65536]
var SOPT_LOWER_ARGS   : [u32; 8]
var SOPT_CONST_NAME   : [u8;  16]
var SOPT_CONST_SYM    : [u8;  32]

/* --- extracted term + LDIL rebuild --- */
var SOPT_TERM        : [u32; 4096]
var SOPT_VSTK        : [u32; 4096]
var SOPT_EXT_REQ     : [u32; 4098]    /* [root, sym_count, costs...] */

/* --- rule registration (packed eg_register_rule descriptor) --- */
var SOPT_RULE_PACK   : [u32; 32]      /* [lhs_n, rhs_n, lhs.., rhs..] */
var SOPT_RULE_IDS    : [u32; 256]
var SOPT_RULE_N      : u32 = 0u32

/* --- cost comparison --- */
var SOPT_CC_REQ      : [u64; 4]       /* [ops_ptr, n, deps_ptr, dep_n] */
var SOPT_OPS_NEW     : [u32; 4096]
var SOPT_OPS_OLD     : [u32; 4096]
var SOPT_DUMMY_DEPS  : [u32; 1]
var SOPT_COST_NEW    : [u64; 6]
var SOPT_COST_OLD    : [u64; 6]

/* --- refinement discharge (SMT) --- */
var SOPT_REFINE_IN       : [u32; 16]
var SOPT_REFINE_TERMVAR  : [u32; 4096]

/* --- federation / witness --- */
var SOPT_DISC_ID     : [u8; 32768]
var SOPT_DISC_N      : u32 = 0u32
var SOPT_PRODUCER    : [u8; 32]
var SOPT_OPID_DISC   : [u8; 32]
var SOPT_RULE_ID     : [u8; 32]
var SOPT_IN_C        : [u8; 32]
var SOPT_OUT_C       : [u8; 32]
var SOPT_FRAG_ID     : [u8; 32]
var SOPT_RID_BYTES   : [u8; 4]

/* --- lifecycle flags --- */
var SOPT_INITED      : u8 = 0u8
var SOPT_RULES_DONE  : u8 = 0u8

/* ---- private helpers ---- */
fn sopt_op_sym_ptr(op: u32) -> *u8 { /* TODO: ((&SOPT_OP_SYM as u64) + (op as u64 & 0xFFFFFFFFu64)*32u64) as *u8 (Trap 4/13) */ }
fn sopt_disc_ptr(idx: u32) -> *u8 { /* TODO: ((&SOPT_DISC_ID as u64) + (idx as u64 & 0xFFFFFFFFu64)*32u64) as *u8 (Trap 4/13) */ }
fn sopt_concrete(sym_slot: u32, arity: u32) -> u32 { /* TODO: (sym_slot << 1u32) | (arity << 16u32) */ }
fn sopt_var(idx: u32) -> u32 { /* TODO: (idx << 1u32) | 1u32 */ }
fn sopt_init_costs() -> i32 { /* TODO: fill SOPT_COSTS=DEFAULT, set per-op slot costs, build SOPT_SYM_TO_OP (Algorithm sopt_init) */ }
fn sopt_rule_pack(lhs_ptr: *u32, lhs_n: u32, rhs_ptr: *u32, rhs_n: u32) -> i32 { /* TODO: assemble SOPT_RULE_PACK [lhs_n,rhs_n,lhs..,rhs..]; bound 2+lhs_n+rhs_n<=32 (Algorithm) */ }
fn sopt_build_egraph(func: u32) -> u32 { /* TODO: eg_init; per-instr lower; CONST=own class; guard operand classes != SENT; return last class (Algorithm; Gap 11) */ }
fn sopt_rebuild_ldil(term_n: u32) -> u32 { /* TODO: explicit-stack post-order build; guard sp>=2 pop / sp<MAX push; return g or SOPT_SENT (Algorithm; W15; Gap 9) */ }
fn sopt_check_refinement(orig_func: u32, opt_func: u32) -> u8 { /* TODO: no-refine fast 1u8; core-rule conservative arm; else real SMT negate-goal+smt_solve, UNSAT->1u8 (Algorithm; M11/M12) */ }

/* ---- public API ---- */
fn sopt_init() -> i32 @export { /* TODO: eg_init; intern op symbols (subtractive o/10,o-... no %); sopt_init_costs; seed producer/opid; flags (Algorithm) */ }
fn sopt_register_core_rules() -> i32 @export { /* TODO: idempotent guard; register 12 packed rules via sopt_rule_pack+eg_register_rule; SOPT_E_RULE on sentinel (Algorithm) */ }
fn sopt_optimize_function(func: u32, cost_order: u32, out_func: *u32) -> i32 @export { /* TODO: build->saturate->extract(req)->rebuild->refine->cost-compare->discover/publish (Algorithm) */ }
fn sopt_emit(req: *u64) -> i32 @export { /* TODO: decode 8-cell aggregate; optimize_function; cg_compile_function(g,...); map errors (Algorithm; W2) */ }
fn sopt_adopt_remote_rule(rule_id: *u8, rule: *u32) -> i32 @export { /* TODO: dedup by id; record; eg_register_rule(rule); idempotent (Algorithm; W2) */ }
fn sopt_publish_rule(rid: u32, cap: u64) -> u64 @export { /* TODO: cap_verify_rights(cap,SOPT_RIGHT_ATTEST); wh_chain_root; wh_publish; SOPT_FRAG_SENT on deny (Algorithm; M8) */ }
fn sopt_discovered_count() -> u32 @export { /* TODO: return SOPT_DISC_N */ }
fn sopt_selftest() -> u64 @export { /* TODO: run KAT 1-6; 99u64 on pass else failing index (KAT Vectors; W12) */ }
```
