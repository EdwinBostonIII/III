# 78 numera/symbolic_regression.iii — Implementation Spec

## Verdict
**STUB.** The gospel candidate body is a façade: `sr_init` flips a flag and `sr_regress` performs five null-checks, writes `*out_len = 0u32`, and returns `SR_OK` — it never parses the dataset, never enumerates a single candidate expression, never verifies, never emits a witness, and never produces an expression. The prose promises "searches for a closed form expression that fits the data… verified by independent evaluation on the dataset before return; only verified expressions enter the chain" — none of that exists. Additionally the gospel's `SR_` constant prefix **collides** with the already-built `omnia/self_reformatter.iii` (`SR_OK`, `SR_E_*`, `SR_PATTERN_CAP`, …), which is a hard linker-symbol collision (Trap 2); the prefix must change to `SYMREG_`. This spec realizes the maximal intent: an **exact, deterministic, bounded symbolic search with independent algebraic verification** — emphatically NOT statistical curve-fitting / gradient / genetic / ML (M3).

## Purpose
`numera::symbolic_regression` synthesizes a **closed-form symbolic expression** that reproduces a finite dataset of (x-vector → y) sample points **exactly within a declared integer tolerance**, by **bounded deterministic enumeration** of candidate expression trees drawn from a caller-supplied operator/terminal *signature* (alphabet) and a caller-supplied *budget* (depth/node/constant bounds). Each enumerated candidate is **independently evaluated** on every data point in exact Q32.32 signed fixed-point; a candidate is accepted only if its per-point residual magnitude is `<= tol` for **all** points. The first accepted candidate in the deterministic enumeration order is canonical (no scoring, no "best fit" — first exact fit wins), is content-addressed, and is published as a witness fragment so that **only verified expressions enter the chain** (M12 synthesis-verifiability; M6 witness continuity). It is a synthesis/cognition operator. **Hexad: kind_cognition. Ring: R0. K_synth: 0.90.**

## Public API
All signatures are single-line (Trap 1). Error/status convention W9 (negative `i32` codes) / W12 (every public fn returns a status). Boolean-ish returns are `u8` (W10).

```
fn symreg_init() -> i32 @export
fn symreg_regress(req: *u8, out_expr: *u8, out_expr_cap: u32, out_len: *u32) -> i32 @export
fn symreg_verify(expr: *u8, expr_len: u32, data: *u8, data_len: u32, tol_q: u64) -> u8 @export
fn symreg_eval(expr: *u8, expr_len: u32, x_vec: *u8, n_vars: u32, out_y_q: *u64, out_sign: *u8) -> i32 @export
fn symreg_last_frag(out_frag_id: *u8) -> i32 @export
fn symreg_selftest() -> u64 @export
```

Notes on the surface vs. the gospel:
- The gospel's 8-parameter `sr_regress(data, data_len, target_signature, sig_len, budget, out_expr, out_expr_cap, out_len)` **violates W2 (≤4 params)**. It is refactored to `symreg_regress(req, out_expr, out_expr_cap, out_len)` where `req: *SymRegRequest` is a packed aggregate carrying `data/data_len/signature/sig_len/budget/cap_id` (W2 "more → pass an aggregate by pointer"). This is the load-bearing fix, not a cosmetic rename.
- `symreg_regress` returns `SYMREG_OK` (0) on success with `*out_len` = bytes of the canonical expression written into `out_expr`; `SYMREG_E_NO_FIT` if the bounded search exhausts the space with no exact-within-tol candidate (this is a *legitimate, non-error determinate outcome* but uses a distinct code so callers can branch — it is NOT a timeout); `SYMREG_E_BUDGET` if the budget bounds are themselves out of the static envelope; the null/init/cap codes otherwise.
- `symreg_verify` is the **independent verifier** (the M12 certificate checker): given a serialized expression + the dataset + tolerance, returns `1u8` iff every point's residual magnitude `<= tol_q`, else `0u8`. It shares **no state** with the search; it is the oracle the search calls and that any third party can re-run to re-check the chain entry (M10 witness reproducibility).
- `symreg_eval` evaluates one expression at one x-vector, returning the exact Q32.32 magnitude (`*out_y_q`) and sign (`*out_sign`, 0 = non-negative, 1 = negative) — signed sign-magnitude so we never do a signed-ordering compare (Trap 3).
- `cap_id` (inside `req`) gates the chain write: emitting the witness requires `cap_verify_rights(cap_id, CAP_RIGHT_ATTEST) == 1u8` (M8). If the cap is insufficient the search still runs and the expression is still written to `out_expr`, but **no fragment is published** and `symreg_regress` returns `SYMREG_E_CAP` (the synthesis is computed but refused chain entry — M5 refusal, never bricking).

## Constant Namespace
**PREFIX = `SYMREG_`** (grep of `STDLIB/` for `SYMREG_` returned **zero** matches → no collision; grep for the gospel's `SR_` returned a **collision** with `omnia/self_reformatter.iii` lines 53–82, hence the reassignment). All module-level constants and module-scope `var`s carry this prefix (Trap 2 — module-level `const`/`var` are linker-global even without `@export`).

Status codes (W9 negative i32):
```
const SYMREG_OK            : i32 =  0i32
const SYMREG_E_NULL        : i32 = -1i32   // a required pointer was null
const SYMREG_E_NOT_INITED  : i32 = -2i32   // symreg_init not called
const SYMREG_E_NO_FIT      : i32 = -3i32   // bounded space exhausted, no exact-within-tol expr (determinate)
const SYMREG_E_BUDGET      : i32 = -4i32   // requested budget exceeds static envelope
const SYMREG_E_SIG         : i32 = -5i32   // malformed / empty signature alphabet
const SYMREG_E_DATA        : i32 = -6i32   // malformed dataset (length not a multiple of record size, 0 rows)
const SYMREG_E_CAP         : i32 = -7i32   // expr synthesized + written, but cap lacked CAP_RIGHT_ATTEST (no chain entry)
const SYMREG_E_OFLOW       : i32 = -8i32   // out_expr_cap too small for the canonical expression
const SYMREG_E_WITNESS     : i32 = -9i32   // wh_publish failed (sentinel 0xFFFF…FFFF)
```

Opcode alphabet (one byte per node in the serialized RPN expression; values are stable wire constants):
```
const SYMREG_OP_END   : u8 = 0x00u8   // end-of-expression terminator
const SYMREG_OP_VAR   : u8 = 0x01u8   // next byte = variable index v in [0, n_vars)
const SYMREG_OP_CONST : u8 = 0x02u8   // next 9 bytes = sign(1) ‖ Q32.32 magnitude(8, LE)
const SYMREG_OP_ADD   : u8 = 0x10u8   // binary: pop b, pop a, push a+b
const SYMREG_OP_SUB   : u8 = 0x11u8   // binary: a-b
const SYMREG_OP_MUL   : u8 = 0x12u8   // binary: a*b
const SYMREG_OP_DIV   : u8 = 0x13u8   // binary: a/b (b==0 => candidate rejected, not a crash)
const SYMREG_OP_NEG   : u8 = 0x20u8   // unary: -a
```
Signature/request wire tags (the caller declares which ops + which constants are permitted):
```
const SYMREG_SIG_MAGIC  : u32 = 0x53524731u32   // "SRG1" — signature blob header
const SYMREG_REQ_MAGIC  : u32 = 0x53525231u32   // "SRR1" — request aggregate header
```
Static bounds (every one justified under W8 in Data Structures):
```
const SYMREG_MAX_VARS        : u32 = 8u32      // x-vector arity ceiling
const SYMREG_MAX_NODES       : u32 = 31u32     // serialized expr node ceiling (full binary tree depth 5)
const SYMREG_MAX_DEPTH       : u32 = 5u32      // enumeration tree-depth ceiling (cost-lattice bound, M19)
const SYMREG_MAX_POINTS      : u32 = 256u32    // dataset row ceiling
const SYMREG_MAX_OPS         : u32 = 8u32      // distinct operators in an alphabet (matches opcode set)
const SYMREG_MAX_CONSTS      : u32 = 8u32      // distinct caller-supplied constants in the alphabet
const SYMREG_EVAL_STACK      : u32 = 32u32     // RPN evaluation operand stack depth (= MAX_NODES + 1)
const SYMREG_EXPR_BUF        : u32 = 320u32    // max serialized-expr bytes (31 nodes * up to 10 bytes + END)
const SYMREG_VALUE_DENOM     : u64 = 0x100000000u64   // Q32.32 scale (mirrors fixed.iii FIX_ONE; local copy avoids cross-module const import)
const SYMREG_PRODUCER_TAG    : u64 = 0x53594D52454730u64   // "SYMREG0" producer label seed for ident
```

Record layouts (documented here; not separate consts):
- **Data record** = `n_vars` x-values then one y-value, each value = `sign:u8 ‖ mag:u64 LE` (9 bytes). Row size = `(n_vars + 1) * 9` bytes. `data_len` MUST be a positive multiple of row size or → `SYMREG_E_DATA`.
- **Request aggregate** `SymRegRequest` (packed, little-endian, read field-by-field — no struct type needed): `magic:u32 ‖ n_vars:u32 ‖ n_points:u32 ‖ tol_sign:u8 ‖ tol_mag:u64 ‖ max_depth:u32 ‖ data_ptr:u64 ‖ sig_ptr:u64 ‖ sig_len:u32 ‖ cap_id:u64`. (`tol` is always non-negative; `tol_sign` reserved 0.)

## Data Structures
All scratch is module-scope fixed arrays (Trap 7 — no local `var` arrays). The module is **non-reentrant** (serialized search), which is acceptable for a synthesis pass and is noted here (W8 + Trap-7 note). Every bound is static and justified:

```
var SYMREG_INITED        : u8  = 0u8                       // init guard

// --- Permitted-alphabet working set (decoded from the signature blob) ---
var SYMREG_OPS_ALLOWED   : [u8;  8]    // SYMREG_MAX_OPS: which opcodes are permitted (1=allowed)
var SYMREG_CONST_SIGN    : [u8;  8]    // SYMREG_MAX_CONSTS: sign of each permitted constant
var SYMREG_CONST_MAG     : [u64; 8]    // SYMREG_MAX_CONSTS: Q32.32 magnitude of each permitted constant
var SYMREG_N_CONSTS      : u32 = 0u32  // count actually decoded (<= MAX_CONSTS)
var SYMREG_N_VARS        : u32 = 0u32  // arity for the current request (<= MAX_VARS)

// --- Dataset mirror (decoded once per regress call) ---
var SYMREG_DX_SIGN       : [u8;  2048] // MAX_POINTS*MAX_VARS = 256*8 x-value signs
var SYMREG_DX_MAG        : [u64; 2048] // 256*8 x-value magnitudes (Q32.32)
var SYMREG_DY_SIGN       : [u8;  256]  // MAX_POINTS y signs
var SYMREG_DY_MAG        : [u64; 256]  // MAX_POINTS y magnitudes (Q32.32)
var SYMREG_N_POINTS      : u32 = 0u32  // rows decoded (<= MAX_POINTS)
var SYMREG_TOL_MAG       : u64 = 0u64  // tolerance magnitude (Q32.32); tolerance is always >= 0

// --- Enumeration state: explicit odometer over the candidate-shape catalog (W15 no recursion) ---
var SYMREG_SHAPE_NODE    : [u8;  31]   // current candidate shape: per-slot node ARITY class (0=leaf,1=unary,2=binary)
var SYMREG_SHAPE_LEN     : u32 = 0u32  // node count of current shape
var SYMREG_PICK_OP       : [u8;  31]   // per-internal-node chosen opcode (odometer digit)
var SYMREG_PICK_LEAF     : [u8;  31]   // per-leaf chosen terminal: 0..n_vars-1 => var, n_vars.. => const index
var SYMREG_DEPTH         : [u8;  31]   // per-slot depth, to enforce MAX_DEPTH during shape generation

// --- Serialization + evaluation scratch ---
var SYMREG_EXPR          : [u8;  320]  // SYMREG_EXPR_BUF: serialized RPN of the current candidate
var SYMREG_EXPR_LEN      : u32 = 0u32
var SYMREG_EVAL_MAG      : [u64; 32]   // SYMREG_EVAL_STACK: RPN operand magnitudes (Q32.32)
var SYMREG_EVAL_SGN      : [u8;  32]   // RPN operand signs

// --- Witness plumbing scratch (32-byte ident buffers) ---
var SYMREG_LAST_FRAG     : [u8;  32]   // frag id of the last published synthesis
var SYMREG_HAVE_FRAG     : u8  = 0u8
var SYMREG_PRODUCER_ID   : [u8;  32]   // content id for the producer label
var SYMREG_OPID          : [u8;  32]   // content id for "symreg.regress"
var SYMREG_IN_COMMIT     : [u8;  32]   // ca over (signature ‖ dataset)
var SYMREG_OUT_COMMIT    : [u8;  32]   // ca over the accepted serialized expression
var SYMREG_HASH_SCRATCH  : [u8;  64]   // keccak/ca staging
```
Bound justifications (W8): `MAX_DEPTH=5` with the 8-op/8-const/8-var alphabet bounds the search at a fixed maximum node budget; `MAX_NODES=31` is the exact node count of a complete binary tree of depth 5 (`2^5 - 1`), the worst-case serialized shape; `MAX_POINTS=256` caps dataset rows so the dataset mirror is a fixed `256*9*(MAX_VARS+1)`-scale footprint; `EVAL_STACK=32 = MAX_NODES+1` is the deepest RPN operand stack a 31-node tree can require; `EXPR_BUF=320 ≥ 31*10+1` covers the largest node (CONST = 1 tag + 9 payload). These bounds are the module's **cost lattice ceiling (M19/W48)** — the search is provably finite: the candidate space is `Σ over shapes ≤ depth 5 of (ops^internal × terminals^leaf)`, a fixed finite number, enumerated by a terminating odometer.

## Dependencies (externs)
All declared single-line (Trap 1), `@abi(c-msvc-x64)`. Signatures were **verified against the real provider files**, not the gospel's externs.

| extern | from | NN | status |
|---|---|---|---|
| `fn fix_add(a: u64, b: u64) -> u64` | `fixed.iii` | built | OK |
| `fn fix_sub(a: u64, b: u64) -> u64` | `fixed.iii` | built | OK |
| `fn fix_mul(a: u64, b: u64) -> u64` | `fixed.iii` | built | OK |
| `fn fix_div(a: u64, b: u64) -> u64` | `fixed.iii` | built | OK (used only for OP_DIV; b==0 guarded in caller) |
| `fn ident_zero(out: *u8) -> i32` | `identifier.iii` | built | OK (gospel had this one right) |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | built | OK |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | built | OK |
| `fn ca_compute(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32` | `content_addr.iii` | built | OK (M12 out-commit / M6 in-commit) |
| `fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32` | `keccak256.iii` | built | OK (digest dataset+sig into the in-commit; **systemic-defect #1 corrected** — NOT `keccak256_init/update/final from keccak.iii`) |
| `fn cap_verify_rights(id: u64, required: u64) -> u8` | `capability.iii` | built | OK (**systemic-defect #5 corrected** — `cap_verify` is fiction; right bit is `CAP_RIGHT_ATTEST = 0x0800`) |
| `fn at_advance() -> u64` | `algebraic_time.iii` | built | OK (**systemic-defect #4 corrected** — `at_now` is fiction; `wh_publish` already advances time internally, so this is only needed if a standalone timestamp is wanted — see note) |
| `fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64` | `aether/witness_hook.iii` | built | OK (**systemic-defect #2 corrected** — `ws_emit_fragment from witness_spine.iii` is fiction; the real built emit primitive is `wh_publish`). Returns the fragment **index** `u64`; failure sentinel `0xFFFFFFFFFFFFFFFFu64`. |

**Not-yet-built dependencies: 0.** Every provider above is already in the built tree. The gospel's lone declared extern (`ident_zero`) is real but insufficient; the realized module depends on the eleven externs above, all built. The wave scheduler may run Module 78 in any wave (no upstream blocker).

`CAP_RIGHT_ATTEST` (= `0x0800u64`) is referenced as a literal in `symreg_regress` (the rights mask). Per W2/Trap-2 hygiene it is used as an inline literal with a comment, OR mirrored as a local `SYMREG_` const — the spec uses the inline literal with the canonical name in a comment to avoid duplicating a foreign constant under our prefix.

## Algorithm

Determinism (M2) and bit-identity (W5): every value is an integer (`u64` magnitude + `u8` sign in Q32.32); there is **no floating point anywhere**. All arithmetic is the substrate's exact `fix_*` Q32.32 ops. The enumeration order is a fixed lexicographic odometer over a statically-ordered alphabet, so the *same* request yields the *same* accepted expression on every run and every CPU. There is **no scoring, no fitness, no gradient, no probability, no count-and-promote, no observe-and-adapt** (M3/M4) — the only decision is the exact predicate "residual magnitude ≤ tolerance for ALL points", and the only selection rule is "first in enumeration order". This is exact symbolic *search*, not statistical *regression*, despite the module name (the briefing M3 trap).

### `symreg_init`
Idempotent guard: if `SYMREG_INITED == 1u8` return `SYMREG_OK`; else set it and return `SYMREG_OK`. (No allocation; module-scope arrays are statically backed.)

### `symreg_eval(expr, expr_len, x_vec, n_vars, out_y_q, out_sign)`
Exact RPN evaluation over signed Q32.32, using the module-scope operand stack `SYMREG_EVAL_MAG/SGN` (W15 — explicit stack, no recursion):
1. Null-check the four pointers (W12) → `SYMREG_E_NULL`.
2. Walk `expr[0..expr_len)` with a cursor `i` and stack pointer `sp = 0` (sentinel-driven `while i < expr_len` loop, no `break` — W14):
   - `SYMREG_OP_VAR`: read `v = expr[i+1]`; load `(sign,mag)` from `x_vec` at record offset `v*9`; push; `i += 2`.
   - `SYMREG_OP_CONST`: read sign byte + 8 LE magnitude bytes (byte-by-byte assembly, never a `*u64` store/load over a u32-origin slot — Trap 4/5); push; `i += 10`.
   - `SYMREG_OP_NEG`: pop a; push `(mag, sign^1)`; `i += 1`.
   - `SYMREG_OP_ADD/SUB/MUL/DIV`: pop b, pop a; compute signed result via the sign-magnitude helpers below; for DIV, if `b.mag == 0u64` set a module flag `eval_bad = 1u8` (division undefined → candidate is simply not a fit; the verifier treats it as residual = ∞, i.e. rejected) and push `(0,0)`; `i += 1`.
   - `SYMREG_OP_END`: terminate the walk by advancing `i` to `expr_len`.
3. On completion `sp` must equal 1 (well-formed expr) else `SYMREG_E_DATA`-class internal reject. Write `*out_y_q = SYMREG_EVAL_MAG[0]`, `*out_sign = SYMREG_EVAL_SGN[0]`, return `SYMREG_OK` (or a reject code if `eval_bad`).

Signed sign-magnitude arithmetic (internal, exact, deterministic; avoids ALL signed-ordering compares — Trap 3, by comparing only magnitudes with unsigned `<`):
- **add**: if signs equal → `mag = fix_add(a,b)`, sign = common; else compare magnitudes (unsigned compare on u64 is safe — Trap 3 is signed-only): larger magnitude's sign wins, `mag = fix_sub(larger, smaller)`.
- **sub(a,b)** = add(a, neg(b)).
- **mul**: `mag = fix_mul(a.mag,b.mag)`, `sign = a.sign XOR b.sign`.
- **div**: `mag = fix_div(a.mag,b.mag)` (guarded b≠0), `sign = a.sign XOR b.sign`.
- zero canonicalization: a zero magnitude is forced to sign 0 so `+0` and `−0` compare equal byte-for-byte (W5).

### `symreg_verify(expr, expr_len, data, data_len, tol_q)`
The independent oracle (M12). For each of the `SYMREG_N_POINTS` rows in the decoded dataset mirror:
1. Build the x-vector from `SYMREG_DX_*[row]`; call `symreg_eval` → predicted `(p_sign, p_mag)`.
2. Residual = signed `sub(predicted, actual_y)`; take its magnitude `r_mag` (drop sign).
3. Exact tolerance test: `r_mag <= tol_q` via **unsigned** compare (safe). If any point fails, return `0u8` immediately (early determinate reject).
4. If a candidate's evaluation hit `eval_bad` (e.g. divide-by-zero) at any point → return `0u8`.
Return `1u8` iff all points pass. This function is **pure over its arguments + the decoded dataset mirror** and shares no mutable search state, so any verifier (including a third party replaying the chain) recomputes the identical verdict (M10).

### `symreg_regress(req, out_expr, out_expr_cap, out_len)` — the bounded search
1. Null-check `req`, `out_expr`, `out_len`; check `SYMREG_INITED` (W12).
2. **Decode the request aggregate** (W2 — single pointer): verify `magic == SYMREG_REQ_MAGIC`; read `n_vars` (≤ MAX_VARS else `SYMREG_E_SIG`), `n_points`, `tol`, `max_depth` (≤ MAX_DEPTH else `SYMREG_E_BUDGET`), `data_ptr`, `sig_ptr`, `sig_len`, `cap_id`. Multi-byte reads are byte-by-byte LE (Trap 4/5).
3. **Decode the signature blob** into `SYMREG_OPS_ALLOWED` + `SYMREG_CONST_*`: verify `SYMREG_SIG_MAGIC`; mark each permitted opcode; load each permitted constant (sign+Q32.32). Empty alphabet → `SYMREG_E_SIG`.
4. **Decode the dataset** into the mirror arrays: require `data_len == n_points * (n_vars+1) * 9` and `1 ≤ n_points ≤ MAX_POINTS` else `SYMREG_E_DATA`; copy each value byte-by-byte; set `SYMREG_N_POINTS`, `SYMREG_TOL_MAG = tol`.
5. **Enumerate candidate expression trees in canonical order** with an explicit odometer (W15 — no recursion; module-scope stacks `SYMREG_SHAPE_*`, `SYMREG_PICK_*`):
   - Outer loop over **node count** `nc = 1 .. up to the MAX_NODES implied by max_depth`, then over **tree shapes** of `nc` nodes whose depth ≤ `max_depth` (shapes generated by a deterministic left-heavy binary-tree odometer; arity per slot ∈ {leaf, unary NEG, binary} restricted to permitted ops).
   - For each shape, an inner odometer assigns: each internal slot → one permitted operator (digits over `SYMREG_OPS_ALLOWED`), each leaf → one terminal (digits over `[0..n_vars) ∪ permitted-const indices`).
   - For each fully-assigned candidate: **serialize** it to RPN in `SYMREG_EXPR` (post-order emit; binary node emits children then op; constant emits tag+sign+8 LE bytes), then call `symreg_verify(SYMREG_EXPR, SYMREG_EXPR_LEN, data, data_len, tol)`.
   - The loops are all sentinel/counter-driven (`while digit < radix`, carrying like an odometer; W14, no `break`). The whole space is finite (M19) — the odometer terminates by construction when the highest digit overflows.
6. **First exact-within-tol candidate wins** (no scoring): on the first `symreg_verify == 1u8`, stop the odometer (by setting its terminate flag), and:
   - If `SYMREG_EXPR_LEN > out_expr_cap` → `SYMREG_E_OFLOW`.
   - Copy `SYMREG_EXPR` → `out_expr` byte-by-byte; set `*out_len = SYMREG_EXPR_LEN`.
   - **Witness + capability**: build `in_commit = keccak256_oneshot(signature ‖ dataset)` (staged through `SYMREG_HASH_SCRATCH`), `out_commit = ca_compute/keccak over SYMREG_EXPR`, `producer/opid` via `ident_from_bytes` on fixed labels. If `cap_verify_rights(cap_id, 0x0800u64 /*CAP_RIGHT_ATTEST*/) == 1u8`, call `wh_publish(producer, opid, in_commit, out_commit, revtag=0, phase=0, pillar=0, antecedents=0, n_ante=0, payload=SYMREG_EXPR, payload_len=SYMREG_EXPR_LEN, out_frag_id=SYMREG_LAST_FRAG)`; if the return is the `0xFFFF…FFFF` sentinel → `SYMREG_E_WITNESS`; else set `SYMREG_HAVE_FRAG = 1u8` and return `SYMREG_OK`.
   - If the cap is insufficient: leave the expression written to `out_expr` (the synthesis is computed and returned) but publish **nothing** and return `SYMREG_E_CAP` (M5 — refusal, never corruption; the caller can re-request with a proper cap).
7. If the odometer exhausts with no acceptance → `SYMREG_E_NO_FIT` (determinate; `*out_len = 0u32`). This is **not** a timeout and **not** ML give-up — it is the exact statement "no expression in the declared bounded alphabet/depth fits within tolerance."

### `symreg_last_frag(out_frag_id)`
Null-check; if `SYMREG_HAVE_FRAG == 0u8` return `SYMREG_E_NO_FIT` (nothing published); else `ident_copy(SYMREG_LAST_FRAG, out_frag_id)`; return `SYMREG_OK`.

### `symreg_selftest`
Runs the KAT vectors below in-process and returns a `u64` bitmask (0 = all pass), the house self-test convention (mirrors `bigint_*`/`fp_*` selftests).

**No recursion (W15) anywhere:** tree shape generation, operator/terminal assignment, serialization, and evaluation all use the module-scope explicit stacks/odometer digits enumerated above. Tree depth is bounded by `max_depth ≤ SYMREG_MAX_DEPTH`, giving a fixed maximum stack height.

## KAT Vectors (>= 3)
All values in signed Q32.32 (`FIX_ONE = 0x1_0000_0000`). Tolerance `tol = 0` means *exact*; a small `tol` admits truncation slack. Each vector is checked byte-for-byte by `symreg_selftest`.

1. **Identity `y = x0`** (single var, exact). Signature permits `{VAR}` only, no ops, depth 1. Dataset rows `{x0=1→y=1}, {x0=2→y=2}, {x0=5→y=5}` (each value `sign=0, mag=k*FIX_ONE`), `tol=0`. Expected `out_expr = [OP_VAR, 0x00, OP_END]`, `out_len = 3`. `symreg_verify` of that expr on the data → `1u8`. A bogus expr `y = x0 + 1` (`[VAR,0, CONST,0,01_00_00_00_00, ADD, END]`) on the same data → `symreg_verify == 0u8` (proves the negative case — verifier rejects a non-fit).
2. **Affine `y = 2*x0 + 1`** (var + two consts + ADD/MUL). Signature permits `{VAR, CONST(2.0), CONST(1.0), ADD, MUL}`, depth ≤ 3. Dataset `{0→1},{1→3},{3→7}` (Q32.32). `tol=0`. Expected: the first canonical serialization that verifies, e.g. RPN `[CONST 2.0][VAR 0][MUL][CONST 1.0][ADD][END]`; `symreg_verify` of it → `1u8`; `symreg_eval` at `x0=3` → `(sign=0, mag=7*FIX_ONE)`. Negative: `y = x0 + 2` rejected.
3. **Two-var sum `y = x0 + x1`** (arity 2). Signature `{VAR, ADD}`, depth ≤ 2, `n_vars=2`. Dataset `{(1,2)→3},{(4,5)→9},{(0,7)→7}`. `tol=0`. Expected `out_expr = [VAR,0][VAR,1][ADD][END]`, verifies `1u8`. Negative: `y = x0 - x1` → `0u8`.
4. **No-fit determinism** (proves `SYMREG_E_NO_FIT`, not a crash/ML-giveup). Signature `{VAR, ADD}` (no constants, no MUL), `n_vars=1`, depth ≤ 5. Dataset `{1→3},{2→5}` (i.e. `y=2x+1`, unreachable from `{x, x+x, x+x+x,…}` exactly). Expected `symreg_regress → SYMREG_E_NO_FIT`, `*out_len = 0`. (The bounded space `{x, 2x, 3x, …}` is enumerated to exhaustion and none fits; determinate.)
5. **Capability refusal** (proves M8/M5). Same request as KAT 2 but `cap_id` lacks `CAP_RIGHT_ATTEST`. Expected: `out_expr` is written with the affine expression, `*out_len > 0`, **no** fragment published (`symreg_last_frag → SYMREG_E_NO_FIT`), and `symreg_regress` returns `SYMREG_E_CAP`.
6. **Witness reproducibility** (proves M6/M10). KAT 2 with a sufficient cap: `wh_publish` returns a non-sentinel index; `symreg_last_frag` yields a 32-byte id; recomputing `keccak256_oneshot(sig‖data)` and `ca_compute` over the expr yields the same in/out commits → the fragment is byte-reproducible from recorded inputs.

## Trap Exposure
- **Trap 1 (multi-line `fn`)**: every signature above is single-line; the implementation skeleton keeps each `fn` prefix on one line. The 12-param `wh_publish` extern is declared on a single physical line (the provider's own definition wraps, but the *extern declaration* in this module is one line). **Avoided.**
- **Trap 2 (module-level `const`/`var` are linker-global)**: the gospel's `SR_*` collide with `omnia/self_reformatter.iii`. Reassigned to `SYMREG_*`; grep confirms zero `SYMREG_` collisions. Every module-scope name carries the prefix. **Avoided.**
- **Trap 3 (signed-ordering SIGSEGV)**: all comparisons are either `==`/`!=` on `i32` status/sentinels or **unsigned** `<`/`<=` on `u64` magnitudes (the trap is signed-only — confirmed by `sat_arith.iii`'s own note and `bigint.iii` usage). Tolerance and residual tests compare magnitudes unsigned; signs are compared with `==`. **No `i64`/`i32` ordering compare anywhere.** **Avoided.**
- **Trap 4 (u32-in-u64-slot garbage)**: indices used in pointer math (`row*recsize`, `v*9`) are masked `(idx as u64) & 0xFFFFFFFFu64` before arithmetic. **Avoided.**
- **Trap 5 (u32 pointer-store width)**: all multi-byte values (Q32.32 magnitudes, the request/signature fields, the serialized constant payload) are stored/loaded **byte-by-byte through `*u8`** (mirroring `big_store_u64_le`/`big_load_u64_le`), never `p[0]=v_u32` through a `*u32`. **Avoided.**
- **Trap 6 (nested block comments)** & **Trap 9 (em-dash in comments)**: header/comment block uses no nested `/* */` and only ASCII `--`. **Avoided.**
- **Trap 7 (local `var` arrays)**: ALL arrays are module-scope (`SYMREG_*`); none declared inside a fn. Module is non-reentrant by design (serialized synthesis) — explicitly noted. **Avoided.**
- **Trap 8 (`} else {` one line)**: every else is written `} else {`. **Avoided.**
- **Trap 10 (`let mut` checkpoint-flag)**: the odometer-terminate and `eval_bad` flags drive the `while` condition directly (the flag IS the loop guard) rather than being a post-hoc mutated boolean; early-return is used where it reads cleaner. **Avoided.**
- **Trap 11 (`a % b` after a call)**: the design uses **no `%`**. Record offsets are multiplications, not moduli; the only "divide" is `fix_div` for `OP_DIV` (a documented exact Q32.32 op, value semantics, not an index modulo). **Avoided.**
- **Trap 12 (`@specialize *T` stride)**: the module is **not generic** — all arrays are concretely typed (`u64`/`u8`). No `@specialize`. **Not exposed.**

## Gap / Fix List
The gospel body is a STUB; the realized module is essentially a from-scratch implementation against this spec. Concrete defects in the gospel body and their fixes:

1. **No algorithm at all.** `sr_regress` returns `*out_len=0; SR_OK` — it never searches, evaluates, verifies, or emits. → Implement the full bounded enumeration + independent verifier + witness emission per Algorithm §.
2. **Prefix collision (Trap 2 / linker-fatal).** `SR_OK`/`SR_E_*`/`SR_PATTERN_CAP`/etc. already exist in `omnia/self_reformatter.iii` as global symbols. → Reassign every const/var to `SYMREG_` (grep-confirmed clean).
3. **W2 violation.** `sr_regress` has 8 parameters. → Fold `data/data_len/signature/sig_len/budget/cap_id` into a single `*SymRegRequest` aggregate; public arity becomes 4.
4. **Fictional/under-spec dependency.** The only extern is `ident_zero` (real but useless here); the prose's "verified… enters the chain" implies witness + content-addressing + a verifier, none declared. → Declare the eleven real externs in Dependencies, all verified against provider files; correct the systemic gospel defects (#1 keccak, #2 wh_publish, #4 at_*, #5 cap_verify_rights) even though the gospel body did not yet (mis)declare them — this pre-empts the Batch-1/2 errors.
5. **M3 risk in the name ("regression").** A naive reading invites curve-fitting/least-squares/gradient/genetic search. → The spec mandates **exact predicate search** (residual ≤ tol for ALL points) with **first-in-canonical-order** selection — no loss, no fitness, no float, no observe-and-adapt. Flagged prominently; the verifier is a pure boolean oracle.
6. **M12/M6 missing.** No certificate, no witness. → `symreg_verify` is the re-runnable certificate checker; `wh_publish` records in-commit (sig‖data) → out-commit (expr) so the chain entry is independently reproducible (M10).
7. **M8 missing.** Chain write was ungated. → Gate `wh_publish` on `cap_verify_rights(cap_id, CAP_RIGHT_ATTEST)`; insufficient cap → compute+return expr but refuse chain entry (`SYMREG_E_CAP`), never corrupting state (M5).
8. **M19/W48 boundedness unstated.** "Industrial scale… budget" with no static envelope invites unbounded search. → All dimensions are statically capped (`MAX_DEPTH/NODES/POINTS/OPS/CONSTS`); the candidate space is provably finite and the odometer terminates by construction. `budget.max_depth` is clamped to `SYMREG_MAX_DEPTH` (`SYMREG_E_BUDGET` if exceeded).
9. **No float discipline asserted.** Dataset/constants/tolerance are integer Q32.32 sign-magnitude; arithmetic via `fix_*`. No FP anywhere (M2/W5). The verifier's tolerance is an exact integer magnitude compare.
10. **No KAT / acceptance gate.** Gospel has none. → Six KAT vectors including two negative-case checks (verifier rejects non-fits) and a determinate `SYMREG_E_NO_FIT`, per the MEMORY "prove the negative case" discipline.

## Implementation Skeleton
```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\symbolic_regression.iii
 *
 * III STDLIB - numera::symbolic_regression
 *
 * Closed-form expression synthesis from data by EXACT DETERMINISTIC
 * BOUNDED SEARCH (not statistical regression -- no loss, no fitness,
 * no float, no ML).  A candidate expression tree is enumerated in a
 * fixed canonical order over a caller-declared operator/terminal
 * alphabet, serialized to RPN, and INDEPENDENTLY VERIFIED on every
 * data point in exact Q32.32 signed fixed-point.  The first candidate
 * whose per-point residual magnitude is <= tolerance for ALL points is
 * canonical (first exact fit wins).  It is content-addressed and, when
 * the supplied capability carries ATTEST rights, published as a witness
 * fragment -- only verified expressions enter the chain.
 *
 * Public API:
 *   symreg_init() -> i32
 *   symreg_regress(req, out_expr, out_expr_cap, out_len) -> i32   // req: *SymRegRequest
 *   symreg_verify(expr, expr_len, data, data_len, tol_q) -> u8
 *   symreg_eval(expr, expr_len, x_vec, n_vars, out_y_q, out_sign) -> i32
 *   symreg_last_frag(out_frag_id) -> i32
 *   symreg_selftest() -> u64
 *
 * Hexad: kind_cognition.  Ring: R0.  K_synth: 0.90.
 * Non-reentrant (serialized search; module-scope scratch -- Trap 7).
 * Trap discipline: single-line fns; SYMREG_ prefix; no signed ordering
 * compare; byte-wise multi-byte IO; no recursion; no modulo.
 */

module numera_symbolic_regression

extern @abi(c-msvc-x64) fn fix_add(a: u64, b: u64) -> u64 from "fixed.iii"
extern @abi(c-msvc-x64) fn fix_sub(a: u64, b: u64) -> u64 from "fixed.iii"
extern @abi(c-msvc-x64) fn fix_mul(a: u64, b: u64) -> u64 from "fixed.iii"
extern @abi(c-msvc-x64) fn fix_div(a: u64, b: u64) -> u64 from "fixed.iii"
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ca_compute(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32 from "content_addr.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn at_advance() -> u64 from "algebraic_time.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "aether/witness_hook.iii"

const SYMREG_OK            : i32 =  0i32
const SYMREG_E_NULL        : i32 = -1i32
const SYMREG_E_NOT_INITED  : i32 = -2i32
const SYMREG_E_NO_FIT      : i32 = -3i32
const SYMREG_E_BUDGET      : i32 = -4i32
const SYMREG_E_SIG         : i32 = -5i32
const SYMREG_E_DATA        : i32 = -6i32
const SYMREG_E_CAP         : i32 = -7i32
const SYMREG_E_OFLOW       : i32 = -8i32
const SYMREG_E_WITNESS     : i32 = -9i32

const SYMREG_OP_END   : u8 = 0x00u8
const SYMREG_OP_VAR   : u8 = 0x01u8
const SYMREG_OP_CONST : u8 = 0x02u8
const SYMREG_OP_ADD   : u8 = 0x10u8
const SYMREG_OP_SUB   : u8 = 0x11u8
const SYMREG_OP_MUL   : u8 = 0x12u8
const SYMREG_OP_DIV   : u8 = 0x13u8
const SYMREG_OP_NEG   : u8 = 0x20u8

const SYMREG_SIG_MAGIC  : u32 = 0x53524731u32
const SYMREG_REQ_MAGIC  : u32 = 0x53525231u32

const SYMREG_MAX_VARS        : u32 = 8u32
const SYMREG_MAX_NODES       : u32 = 31u32
const SYMREG_MAX_DEPTH       : u32 = 5u32
const SYMREG_MAX_POINTS      : u32 = 256u32
const SYMREG_MAX_OPS         : u32 = 8u32
const SYMREG_MAX_CONSTS      : u32 = 8u32
const SYMREG_EVAL_STACK      : u32 = 32u32
const SYMREG_EXPR_BUF        : u32 = 320u32
const SYMREG_VALUE_DENOM     : u64 = 0x100000000u64
const SYMREG_PRODUCER_TAG    : u64 = 0x53594D52454730u64

var SYMREG_INITED        : u8  = 0u8

var SYMREG_OPS_ALLOWED   : [u8;  8]
var SYMREG_CONST_SIGN    : [u8;  8]
var SYMREG_CONST_MAG     : [u64; 8]
var SYMREG_N_CONSTS      : u32 = 0u32
var SYMREG_N_VARS        : u32 = 0u32

var SYMREG_DX_SIGN       : [u8;  2048]
var SYMREG_DX_MAG        : [u64; 2048]
var SYMREG_DY_SIGN       : [u8;  256]
var SYMREG_DY_MAG        : [u64; 256]
var SYMREG_N_POINTS      : u32 = 0u32
var SYMREG_TOL_MAG       : u64 = 0u64

var SYMREG_SHAPE_NODE    : [u8;  31]
var SYMREG_SHAPE_LEN     : u32 = 0u32
var SYMREG_PICK_OP       : [u8;  31]
var SYMREG_PICK_LEAF     : [u8;  31]
var SYMREG_DEPTH         : [u8;  31]

var SYMREG_EXPR          : [u8;  320]
var SYMREG_EXPR_LEN      : u32 = 0u32
var SYMREG_EVAL_MAG      : [u64; 32]
var SYMREG_EVAL_SGN      : [u8;  32]

var SYMREG_LAST_FRAG     : [u8;  32]
var SYMREG_HAVE_FRAG     : u8  = 0u8
var SYMREG_PRODUCER_ID   : [u8;  32]
var SYMREG_OPID          : [u8;  32]
var SYMREG_IN_COMMIT     : [u8;  32]
var SYMREG_OUT_COMMIT    : [u8;  32]
var SYMREG_HASH_SCRATCH  : [u8;  64]

// --- signed sign-magnitude Q32.32 helpers (internal, exact) ---
fn symreg_sm_add(a_mag: u64, a_sgn: u8, b_mag: u64, b_sgn: u8, out_mag: *u64, out_sgn: *u8) -> i32 {
    // TODO: body per Algorithm (signed add; equal-sign -> fix_add; else magnitude compare + fix_sub; zero canonicalized to sgn 0)
    return SYMREG_OK
}

// --- byte-wise LE value IO over *u8 (Trap 5) ---
fn symreg_load_u64_le(p: u64, off: u64) -> u64 {
    // TODO: assemble 8 LE bytes (mirror big_load_u64_le)
    return 0u64
}
fn symreg_store_u64_le(p: u64, off: u64, v: u64) -> i32 {
    // TODO: store 8 LE bytes (mirror big_store_u64_le)
    return SYMREG_OK
}

fn symreg_init() -> i32 @export {
    // TODO: idempotent init guard
    return SYMREG_OK
}

fn symreg_eval(expr: *u8, expr_len: u32, x_vec: *u8, n_vars: u32, out_y_q: *u64, out_sign: *u8) -> i32 @export {
    // TODO: body per Algorithm symreg_eval -- explicit RPN operand stack (W15), byte-wise const decode, sign-magnitude ops, div-by-zero -> reject flag
    return SYMREG_OK
}

fn symreg_verify(expr: *u8, expr_len: u32, data: *u8, data_len: u32, tol_q: u64) -> u8 @export {
    // TODO: body per Algorithm symreg_verify -- per-point eval, residual magnitude <= tol_q via unsigned compare; any fail -> 0u8 (independent oracle, M12/M10)
    return 0u8
}

fn symreg_regress(req: *u8, out_expr: *u8, out_expr_cap: u32, out_len: *u32) -> i32 @export {
    // TODO: body per Algorithm symreg_regress
    //   1. null/init checks
    //   2. decode SymRegRequest (magic, n_vars, n_points, tol, max_depth, data_ptr, sig_ptr, sig_len, cap_id) byte-wise
    //   3. decode signature blob -> SYMREG_OPS_ALLOWED / SYMREG_CONST_*
    //   4. decode dataset -> mirror arrays (length-multiple check)
    //   5. enumerate shapes (depth<=max_depth) then op/leaf odometer (W15 explicit stacks, W14 sentinel loops)
    //   6. serialize each candidate to SYMREG_EXPR; symreg_verify; FIRST exact-within-tol wins (no scoring, M3/M4)
    //   7. on accept: cap_verify_rights(cap_id, 0x0800u64 /*CAP_RIGHT_ATTEST*/); keccak256_oneshot(sig||data)->in_commit; ca_compute(expr)->out_commit; wh_publish(...); set SYMREG_LAST_FRAG
    //      insufficient cap -> write expr, no publish, return SYMREG_E_CAP (M5/M8)
    //   8. exhaustion -> SYMREG_E_NO_FIT, *out_len=0 (determinate, not timeout)
    return SYMREG_OK
}

fn symreg_last_frag(out_frag_id: *u8) -> i32 @export {
    // TODO: null-check; if !SYMREG_HAVE_FRAG -> SYMREG_E_NO_FIT; else ident_copy(SYMREG_LAST_FRAG, out_frag_id)
    return SYMREG_OK
}

fn symreg_selftest() -> u64 @export {
    // TODO: run KAT vectors 1-6; return bitmask (0 = all pass)
    return 0u64
}
```
