# 75 numera/smt_at_scale.iii — Implementation Spec

## Verdict
STUB — the gospel candidate is a three-function pass-through shell, not a scale wrapper, and it is **not buildable as written**. Three fatal defects: (1) it externs `smt_v1_solve(formula, formula_len, theories, theory_count, out_result) from "smt.iii"` — **that symbol does not exist**; the realized Module-16 `smt.iii` (see `smt.spec.md`) is a *stateful builder* (`smt_init`→`smt_lia_*`/`smt_bv_*`/`smt_share`→`smt_solve_cap`→`smt_check_model`/`smt_witness`) with **no blob-solving entry at all**; (2) it `@export`s functions named `smt_init` and `smt_solve`, which **linker-collide** with Module-16's `smt_init`/`smt_solve` `@export`s (Trap-2 at the function-symbol level — two `L_smt_init` definitions); (3) it externs `pt_alloc/pt_finalize/pt_verify from "proof_term.iii"` against a **not-yet-built** module (Module 61) whose realized `pt_add_inference` is collapsed to `(args:*u8)` (the gospel's other `pt_*` callers used the wrong arity — verified against `proof_term.spec.md`). Beyond non-buildability the shell **under-realizes the gospel prose** ("combines the SAT engine with theory solvers … the verifier separately checks the result against the theory consistency conditions"): there is no actual scale orchestration (no formula parse, no budget enforcement, no large-instance capacity), the "verify" entry merely re-calls `pt_verify` on a term id it is handed (it never re-checks the formula against the model — M12/M18 violated), and it emits **no witness** (M6/M10 absent). It also passes `budget:*u8` but never reads it (M19 unbounded-in-practice). The maximal realization makes this module the substrate's **large-instance SMT orchestration + independent re-verification layer** over the Module-16 DPLL(T) core: it parses a canonical serialized SMT instance (the `SMTS_FMT` wire format defined here) into the Module-16 builder under an explicit cost budget, drives a bounded deterministic solve, then **independently re-verifies** the returned model with Module-16's `smt_check_model` **and** mints a checkable proof-term certificate, and emits a capability-gated reproducible witness. No new algorithm is invented (that would risk M3/M4); "at scale" is exactly the large fixed capacity + the budget refusal gate + the second, independent verifier — which is what a K=0.99 verifier module is.

## Purpose
`numera/smt_at_scale.iii` IS the substrate's industrial-scale satisfiability-modulo-theories front end and **independent result verifier**: it accepts a large SMT instance in a canonical serialized form, feeds it deterministically into the Module-16 DPLL(T) engine (LIA via exact rational Bland's-rule simplex + branch-and-bound; BV bit-blasted to the Module-15 CDCL SAT core; joined by Nelson-Oppen equality exchange), bounds the whole solve under an explicit cost budget (refusal, not divergence, on overrun — M5/M19), and then **separately re-checks** the SAT/UNSAT verdict against the theory consistency conditions before any result is trusted. A SAT result is accepted only when the independent model checker confirms it and a proof-term certificate verifies; the accepted result emits a capability-gated, byte-reproducible witness fragment. The module adds no solving heuristic of its own — its value is scale capacity + a second, independent line of verification (the "verifier separately checks" of the gospel prose). Hexad kind: `kind_cognition`. Ring: **R0**. K-vector: **0.99** (verifier).

## Public API
All public fns return a status `i32` (W9/W12: negative = error; `SMTS_SAT`/`SMTS_UNSAT`/`SMTS_OK` otherwise). Every signature is single-line (Trap 1). The `smt_*` gospel names are renamed to the assigned `smts_` prefix to eliminate the Module-16 symbol collision (Gap #2). The wide-input shape uses a single caller-filled argument record passed by pointer (W2: every public fn is <=4 params).

```
fn smts_init() -> i32 @export
fn smts_solve(args: *u8) -> i32 @export
fn smts_verify(args: *u8) -> i32 @export
fn smts_result_value_lia(var1: u32) -> i64 @export
fn smts_result_value_bv(var1: u32) -> u64 @export
fn smts_witness(out_32: *u8) -> i32 @export
fn smts_last_term(out_term_id: *u8) -> i32 @export
fn smts_selftest() -> u64 @export
```

Return-status convention per fn:
- `smts_init` → `SMTS_OK` always (resets module state incl. the Module-16 core via `smt_init`; total, idempotent, reversible — M9).
- `smts_solve(args)` → `SMTS_SAT` (1) / `SMTS_UNSAT` (2) / negative error. `args` points to an `SMTS_SOLVEARG` record (formula ptr+len, theory mask, budget fields, capability id, out-term flag — layout in Data Structures). On `SMTS_SAT` the model is readable via `smts_result_value_*`, the certificate term id via `smts_last_term`, the witness via `smts_witness` (capability-gated). Errors: `SMTS_E_NULL`, `SMTS_E_NOT_INITED`, `SMTS_E_MALFORMED` (bad wire format), `SMTS_E_TOO_BIG` (instance exceeds a static capacity or the budget — M19 refusal), `SMTS_E_BUDGET` (solve hit the cost budget), `SMTS_E_VERIFY` (solver said SAT but the independent re-check/`smt_check_model` rejected the model — a substrate integrity fault), `SMTS_E_CORE` (a Module-16 core call returned a hard error).
- `smts_verify(args)` → `SMTS_OK` iff an **independent** re-check confirms the claimed result: it re-parses the same formula into a fresh Module-16 state, asserts the recorded model satisfies every theory constraint (`smt_check_model`), and verifies the proof-term certificate (`pt_verify`). `SMTS_E_VERIFY` if any check fails; `SMTS_E_MALFORMED`/`SMTS_E_NULL`/`SMTS_E_NOT_INITED` as above. This is the gospel's "verifier separately checks" obligation realized (M12/M18) — it does NOT merely re-call `pt_verify` on a handed-in id.
- `smts_result_value_lia(var1)` → `i64` model value for 1-based LIA var; `0i64` sentinel for bad/unsolved handle (delegates to `smt_lia_value`).
- `smts_result_value_bv(var1)` → `u64` model value for 1-based BV var; `0u64` sentinel (delegates to `smt_bv_value`).
- `smts_witness(out_32)` → `SMTS_OK` after writing the 32-byte solve witness to `out_32`; `SMTS_E_BAD` if no capability-gated solve has produced one.
- `smts_last_term(out_term_id)` → `SMTS_OK` writing the 32-byte proof-term id of the last accepted solve; `SMTS_E_BAD` if none.
- `smts_selftest` → `u64`: `0u64` iff all KAT vectors pass; else a bitmask of failing vector indices.

## Constant Namespace
PREFIX = `SMTS_`. **Grep result:** `grep -rn "SMTS_" STDLIB/` → **0 matches**; `grep -rn "numera_smt_at_scale|smt_at_scale|smt_v1_solve|smts_" STDLIB/` → **0 matches**. No constant, var, or function-symbol collision. (The bare `smt_` prefix is owned by Module-16 `smt.iii`; this module deliberately uses `smts_` for **both** its consts and its public function symbols to avoid the gospel's `smt_init`/`smt_solve` `L_*` clash — see Gap #2.) Module name `numera_smt_at_scale` is unused tree-wide.

Module-level constants (every one prefixed):

```
const SMTS_OK            : i32 =  0i32
const SMTS_SAT           : i32 =  1i32      // mirrors Module-16 SMT_SAT
const SMTS_UNSAT         : i32 =  2i32      // mirrors Module-16 SMT_UNSAT
const SMTS_E_NULL        : i32 = -1i32
const SMTS_E_NOT_INITED  : i32 = -2i32
const SMTS_E_MALFORMED   : i32 = -3i32      // bad SMTS_FMT wire encoding
const SMTS_E_TOO_BIG     : i32 = -4i32      // instance exceeds static capacity (M19 refusal)
const SMTS_E_BUDGET      : i32 = -5i32      // solve hit the cost budget (M19 refusal)
const SMTS_E_VERIFY      : i32 = -6i32      // SAT claimed but independent re-check rejected
const SMTS_E_CORE        : i32 = -7i32      // Module-16 core hard error
const SMTS_E_BAD         : i32 = -8i32      // no witness / no term available
const SMTS_E_NOCAP       : i32 = -9i32      // witness requested without a valid capability

// Module-16 core result mirror (MUST equal smt.iii's SMT_SAT/SMT_UNSAT/SMT_OK exactly).
const SMTS_CORE_OK       : i32 =  0i32
const SMTS_CORE_SAT      : i32 =  1i32
const SMTS_CORE_UNSAT    : i32 =  2i32

// SMTS_FMT canonical wire-format tags (the at-scale serialized instance).
const SMTS_FMT_MAGIC     : u8 = 0xA7u8      // instance header byte 0
const SMTS_FMT_VERSION   : u8 = 0x01u8      // instance header byte 1
const SMTS_REC_LIA_LE    : u8 = 0x01u8      // record: LIA  sum c_i x_i <= b
const SMTS_REC_LIA_GE    : u8 = 0x02u8      // record: LIA  sum c_i x_i >= b
const SMTS_REC_LIA_EQ    : u8 = 0x03u8      // record: LIA  sum c_i x_i == b
const SMTS_REC_BV_EQ     : u8 = 0x04u8      // record: BV   a == b
const SMTS_REC_BV_ULT    : u8 = 0x05u8      // record: BV   a <  b (unsigned)
const SMTS_REC_SHARE     : u8 = 0x06u8      // record: Nelson-Oppen share (lia_var, bv_var)
const SMTS_REC_NEWVAR_L  : u8 = 0x07u8      // record: declare one LIA var
const SMTS_REC_NEWVAR_B  : u8 = 0x08u8      // record: declare one BV var (width u8 follows)
const SMTS_REC_END       : u8 = 0xFFu8      // record: end of instance

// Theory selector bits (args.theory_mask).
const SMTS_TH_LIA        : u32 = 0x01u32
const SMTS_TH_BV         : u32 = 0x02u32

// Static at-scale capacity bounds (the "scale" dimension; justified below).
const SMTS_MAX_RECORDS   : u32 = 1048576u32   // max wire records per instance
const SMTS_MAX_FMT_BYTES : u64 = 67108864u64  // 64 MiB max serialized instance
const SMTS_MAX_TERMLEN    : u32 = 4096u32      // max coeff/var entries in one LIA record

// Cost budget ceiling: passes straight to Module-16's node-capped solve; this is
// the at-scale hard refusal bound (M5/M19). Mirrors SMT_BB_NODE_CAP semantics.
const SMTS_BUDGET_DEFAULT : u64 = 16777216u64  // 2^24 nodes if args.budget is zero

// Result tag stored in the witness/certificate transcript.
const SMTS_RESULT_SAT    : u8 = 1u8
const SMTS_RESULT_UNSAT  : u8 = 2u8

// Proof-term inference-rule kind used for the SMT certificate step (Module-61 PT_RULE_LIBRARY_CITE).
const SMTS_PT_RULE_CITE  : u8 = 0x07u8

// witness_hook publish parameters (proof-term-style fragment).
const SMTS_FRAG_MAGIC    : u8 = 0xE4u8      // SMT_AT_SCALE_SOLVED fragment payload magic
const SMTS_FRAG_KIND     : u8 = 0x4Bu8      // fragment kind tag (distinct from PT_FRAG_KIND 0x14)
const SMTS_WH_PHASE      : u8 = 0u8
const SMTS_WH_PILLAR     : u16 = 0u16
const SMTS_WH_REVTAG     : u8 = 0u8         // reversible (W16)

// Capability right required to emit a witness (read from aether/capability.iii).
const SMTS_RIGHT_ATTEST  : u64 = 0x0800u64  // == CAP_RIGHT_ATTEST
const SMTS_NULL_CAP      : u64 = 0u64       // witness-suppressing sentinel capability
```

`SMTS_MAX_RECORDS` / `SMTS_MAX_FMT_BYTES` justification (W8 / M19): the "at scale" capacity is a fixed, statically-sized ceiling — 1,048,576 wire records and a 64 MiB serialized instance — chosen to be large (industrial) yet bounded so that parse cost, the Module-16 table footprint, and the cost budget are all provably finite. An instance exceeding either ceiling is **refused** with `SMTS_E_TOO_BIG` (M5: refusal, never bricking). Note the parsed instance must additionally fit Module-16's own caps (`SMT_MAX_LIA_VARS=256`, `SMT_MAX_LIA_CON=1024`, `SMT_MAX_BV_VARS=256`, etc.); the wrapper checks these *before* feeding the core and refuses with `SMTS_E_TOO_BIG` if the instance overflows a core table (so the core never silently truncates).

## Data Structures
Every buffer is a fixed module-scope array (W8). No local `var` arrays anywhere (Trap 7) — all scratch is hoisted with `SMTS_`-prefixed names. **Non-reentrant** (single serialized solve), documented like the `proof_term.iii`/`witness_hook.iii` exemplars.

Lifecycle / last-result state:
```
var SMTS_INITED      : u8 = 0u8
var SMTS_LAST_RESULT : i32 = 0i32     // last smts_solve result (SMTS_SAT/UNSAT) or 0 if none
var SMTS_HAVE_MODEL  : u8 = 0u8       // 1 iff a SAT model is live in the Module-16 core
var SMTS_LAST_TERM   : [u8; 32]       // proof-term id minted for the last accepted solve
var SMTS_HAVE_TERM   : u8 = 0u8
```

`SMTS_SOLVEARG` argument record (caller fills, passes `&record` to `smts_solve`/`smts_verify`; single-arg ABI per W2). Fixed 96-byte header layout (little-endian):
```
// off  0 : u64  formula_ptr        (byte address of the SMTS_FMT instance)
// off  8 : u64  formula_len        (bytes; <= SMTS_MAX_FMT_BYTES)
// off 16 : u32  theory_mask        (SMTS_TH_LIA | SMTS_TH_BV)
// off 20 : u32  pad0
// off 24 : u64  budget_nodes       (0 => SMTS_BUDGET_DEFAULT; the M19 cost bound)
// off 32 : u64  cap_id             (capability for witness emission; SMTS_NULL_CAP suppresses)
// off 40 : u8   claimed_result     (smts_verify only: SMTS_RESULT_SAT / _UNSAT being checked)
// off 41 : u8[7] pad1
// off 48 : u8[32] claimed_term_id  (smts_verify only: the certificate term id to re-verify)
// off 80 : u8[16] reserved
var SMTS_ARG_SCRATCH : [u8; 96]       // optional caller-side fill buffer (callers may use their own)
```

Wire-parse working state (the parser is a flat cursor scan — W15 no recursion):
```
var SMTS_P_CURSOR    : u64 = 0u64     // current byte offset into the instance
var SMTS_P_NREC      : u32 = 0u32     // records consumed (capped by SMTS_MAX_RECORDS)
var SMTS_TERM_COEFF  : [i64; 4096]    // one LIA record's coefficients (SMTS_MAX_TERMLEN)
var SMTS_TERM_VAR    : [u32; 4096]    // one LIA record's variable handles
var SMTS_DONE        : u8 = 0u8       // parser sentinel (W14; drives the scan loop condition)
```

Witness / certificate transcript scratch (M6/M10/M12):
```
var SMTS_WIT_HASH    : [u8; 32]       // last solve witness (keccak256 over canonical transcript)
var SMTS_WIT_VALID   : u8 = 0u8
var SMTS_WIT_SCRATCH : [u8; 65536]    // canonical-serialization scratch (module scope; Trap 7)
var SMTS_CORE_WIT    : [u8; 32]       // the Module-16 smt_witness output, folded into the transcript
var SMTS_OUT_COMMIT  : [u8; 32]       // keccak of (result || core-witness || model digest)
var SMTS_FRAG_PAYLOAD: [u8; 40]       // wh_publish payload (magic||kind||6 pad||term id)
var SMTS_PRODUCER    : [u8; 32]       // zero producer id
var SMTS_OPID        : [u8; 32]       // zero op id
var SMTS_IN_COMMIT   : [u8; 32]       // input commitment = keccak of the formula bytes
var SMTS_FRAG_ID     : [u8; 32]       // wh_publish fragment-id sink
```

KAT scratch (self-test only; module scope per Trap 7):
```
var SMTS_KAT_FMT     : [u8; 4096]     // KAT instance builder buffer
var SMTS_KAT_ARG     : [u8; 96]       // KAT SMTS_SOLVEARG record
var SMTS_KAT_W1      : [u8; 32]       // witness reproducibility h1
var SMTS_KAT_W2      : [u8; 32]       // witness reproducibility h2
```

## Dependencies (externs)
All `@abi(c-msvc-x64)`, single-line. Signatures verified against the **realized provider files** (capability.iii, witness_hook.iii, algebraic_time.iii, identifier.iii, keccak256.iii — all built) and against the **specs** of the not-yet-built providers (smt.spec.md, proof_term.spec.md). The gospel's `smt_v1_solve`/`ident_zero`/`pt_*`-arity declarations are all corrected here.

```
// --- Module-16 DPLL(T) core (numera/smt.iii) — the realized stateful builder API ---
extern @abi(c-msvc-x64) fn smt_init() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_new_var() -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_add_le(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_add_ge(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_add_eq(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_new_var(width: u32) -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_eq(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_ult(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_share(lia_var: u32, bv_var: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_solve_cap(cap: *u8) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_value(var: u32) -> i64 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_value(var: u32) -> u64 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_check_model() -> u8 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_witness(out_32: *u8) -> i32 from "smt.iii"

// --- proof-term certificate (numera/proof_term.iii) — realized arities ---
extern @abi(c-msvc-x64) fn pt_init() -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_alloc(out_term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_add_inference(args: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_finalize(term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_verify(term_id: *u8) -> i32 from "proof_term.iii"

// --- identity / hash (built) ---
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"

// --- capability check for witness emission (built) ---
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"

// --- witness fragment publish (built) ---
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
```

| Extern(s) | Provider | NN | Built? |
|---|---|---|---|
| `smt_init`, `smt_lia_*`, `smt_bv_*`, `smt_share`, `smt_solve_cap`, `smt_lia_value`, `smt_bv_value`, `smt_check_model`, `smt_witness` | `numera/smt.iii` | **16** | **NOT YET BUILT** (parallel wave; spec `smt.spec.md` is the contract; wave-order 16 before 75) |
| `pt_init`, `pt_alloc`, `pt_add_inference`, `pt_finalize`, `pt_verify` | `numera/proof_term.iii` | **61** | **NOT YET BUILT** (parallel wave; spec `proof_term.spec.md`; wave-order 61 before 75) |
| `ident_zero`, `ident_copy` | `numera/identifier.iii` | 01 | **built** (verified in tree) |
| `keccak256_oneshot` | `numera/keccak256.iii` | (Stage-4) | **built** (verified: `keccak256_oneshot(msg_ptr:u64,msg_len:u64,out_ptr:u64)->i32`) |
| `cap_verify_rights` | `aether/capability.iii` | 07-family | **built** (verified line 148; `CAP_RIGHT_ATTEST=0x0800`) |
| `wh_publish` | `aether/witness_hook.iii` | 07 | **built** (verified line 144; 12-param hook, W2-exempt) |

Contract pins (Phase 2 must hold these or the wrapper silently mismatches the core):
- **Result codes mirror exactly.** Module-16 `SMT_SAT=1`, `SMT_UNSAT=2`, `SMT_OK=0` (see `smt.spec.md` lines 49-51); `SMTS_SAT/_UNSAT/_OK` and `SMTS_CORE_SAT/_UNSAT/_OK` are defined to equal them. A Module-16 negative return maps to `SMTS_E_CORE`, **never** silently to UNSAT.
- **Builder var handles are 1-based**; `smt_lia_new_var`/`smt_bv_new_var` return `0u32` on exhaustion (Module-16 sentinel). The wrapper maps the wire's per-instance var indices to the core's returned handles via the parse-order arrays; a `0u32` return ⇒ `SMTS_E_TOO_BIG` (core capacity hit).
- **`smt_solve_cap(cap_ptr)`** takes a `*u8` capability pointer; Module-16 suppresses its own witness when the pointed value is its `SMT_NULL_CAP`. The wrapper passes a pointer to its own cap-derived flag (non-null only when `cap_verify_rights` passes), so the core's internal witness is produced only under capability — consistent with this module's witness gate (M8).
- **`smt_check_model()` returns `u8` (W10)**: `1u8` iff the recorded model satisfies every recorded constraint. This is the core's own certificate; `smts_verify` additionally re-parses from scratch (independent line).
- **`pt_add_inference` takes one `*u8` args record** (Module-61 W2 collapse), layout per `proof_term.spec.md`: term_id(32) | kind(1) | pad(3) | premise_count(u32@36) | conclusion_len(u32@40) | premises | conclusion. The wrapper fills a `LIBRARY_CITE` step (premise_count=1 = a library index; conclusion = the instance commitment) — the proof-term records "this instance was decided to verdict V". `pt_verify` then checks it structurally.

## Algorithm
NIH (M1): the wire parser, LE codecs, capacity gates, transcript serializer and the certificate assembly are all hand-rolled over the providers; no libc, no third-party. No ML/heuristics (M3/M4): the wrapper adds **no** portfolio selection, no restart schedule, no activity scoring, no observe-and-adapt — it deterministically replays the parsed instance into Module-16 in fixed wire order and bounds it by a fixed budget. Determinism (M2) + bit-identity (W5): parse order is the byte order of the instance; the Module-16 core is itself deterministic (Bland's rule + fixed branch order, per `smt.spec.md`); the witness transcript is a pure function of (result, core-witness, model) in a fixed layout. No recursion (W15): the parser and the model-read loops are flat cursor/counter scans. No `break` (W14): every loop is driven by a sentinel/counter the condition reads.

### `SMTS_FMT` wire format (the canonical at-scale instance)
A deterministic byte stream, parsed once per solve. Header: `[0]=SMTS_FMT_MAGIC(0xA7)`, `[1]=SMTS_FMT_VERSION(0x01)`, `[2..]` = a sequence of records, terminated by an `SMTS_REC_END(0xFF)` byte. Each record begins with a 1-byte tag:
- `SMTS_REC_NEWVAR_L`: declare one LIA var (no payload) — wrapper calls `smt_lia_new_var`, stores the returned handle at the next LIA-index slot.
- `SMTS_REC_NEWVAR_B`: `[+1]=width:u8` — wrapper calls `smt_bv_new_var(width)`.
- `SMTS_REC_LIA_LE`/`_GE`/`_EQ`: `[+1..5]=n:u32` then `n` * (`i64` coeff LE, `u32` wire-var-index LE); wrapper resolves each wire-var-index to its core handle, fills `SMTS_TERM_COEFF`/`SMTS_TERM_VAR`, reads the 8-byte `b:i64`, and calls `smt_lia_add_le/ge/eq(&SMTS_TERM_COEFF[0], &SMTS_TERM_VAR[0], n, b)`.
- `SMTS_REC_BV_EQ`/`_ULT`: `[+1..5]=a_idx:u32`, `[+5..9]=b_idx:u32` — wrapper resolves and calls `smt_bv_add_eq/ult`.
- `SMTS_REC_SHARE`: `[+1..5]=lia_idx:u32`, `[+5..9]=bv_idx:u32` — `smt_share`.
- `SMTS_REC_END`: stop.
All multi-byte fields are little-endian and read **byte-by-byte** through a `*u8` cursor (Trap 5 — never a `*u32`/`*i64` load of an unaligned wire field). A malformed tag, a length that runs past `formula_len`, `n > SMTS_MAX_TERMLEN`, a record count past `SMTS_MAX_RECORDS`, or an unresolved var index ⇒ `SMTS_E_MALFORMED` (or `SMTS_E_TOO_BIG` for capacity). The format is total: every well-formed instance maps to exactly one builder call sequence (M2).

### `smts_init`
If `SMTS_INITED==1u8` return `SMTS_OK` (idempotent). Call `smt_init()` (resets the Module-16 core) and `pt_init()` (resets the proof-term store); if either returns nonzero ⇒ `SMTS_E_CORE`. Zero `SMTS_LAST_RESULT=0i32`, `SMTS_HAVE_MODEL=0u8`, `SMTS_HAVE_TERM=0u8`, `SMTS_WIT_VALID=0u8`, `SMTS_P_NREC=0u32`. Set `SMTS_INITED=1u8`. Return `SMTS_OK`. Reversible (M5/M9): re-`smts_init` fully restores empty state (and re-resets both cores).

### `smts_parse_into_core(formula_ptr, formula_len, theory_mask) -> i32` (internal)
Flat cursor scan (W15). Validate `formula_len <= SMTS_MAX_FMT_BYTES` else `SMTS_E_TOO_BIG`; validate header magic+version else `SMTS_E_MALFORMED`. Set `SMTS_P_CURSOR=2`, `SMTS_P_NREC=0`, `SMTS_DONE=0u8`. Loop `while SMTS_DONE == 0u8` (W14 sentinel drives the condition): read tag byte; dispatch by a `when`-style cascade (single-line `} else {`, Trap 8) over the record tags; each branch reads its fixed-width LE fields byte-by-byte (Trap 5), advances `SMTS_P_CURSOR`, performs the corresponding Module-16 builder call, and increments `SMTS_P_NREC`. A var-declaring record stores the 1-based handle returned by `smt_lia_new_var`/`smt_bv_new_var` into a parse-order handle array (the wire uses 0-based indices into declaration order; the resolver maps index→handle). Guard at the top of each iteration: `SMTS_P_NREC >= SMTS_MAX_RECORDS` ⇒ `SMTS_E_TOO_BIG`; `SMTS_P_CURSOR >= formula_len` with no `SMTS_REC_END` seen ⇒ `SMTS_E_MALFORMED`. `SMTS_REC_END` sets `SMTS_DONE=1u8`. Any builder call returning a hard negative ⇒ `SMTS_E_CORE`; any `0u32` var handle ⇒ `SMTS_E_TOO_BIG`. Theory-mask bits gate which record families are legal (e.g. a BV record with `SMTS_TH_BV` clear ⇒ `SMTS_E_MALFORMED`). Returns `SMTS_OK` on a clean END.

### `smts_solve(args)`
1. Guard: `SMTS_INITED==0` ⇒ `SMTS_E_NOT_INITED`; `(args as u64)==0` ⇒ `SMTS_E_NULL`. Read the `SMTS_SOLVEARG` header byte-by-byte: `formula_ptr`, `formula_len`, `theory_mask`, `budget_nodes`, `cap_id`. `(formula_ptr as u64)==0` ⇒ `SMTS_E_NULL`.
2. **Reset the core for a fresh instance:** call `smt_init()` (clears any prior constraints — the wrapper owns one instance at a time). ⇒ `SMTS_E_CORE` on failure.
3. **Parse + load:** `smts_parse_into_core(formula_ptr, formula_len, theory_mask)`; propagate its error.
4. **Budget (M19):** the at-scale budget is the Module-16 node cap. `budget_nodes==0` ⇒ use `SMTS_BUDGET_DEFAULT`. (Module-16 already hard-caps its B&B at `SMT_BB_NODE_CAP` and refuses with `SMT_E_TOO_BIG` past it; the wrapper additionally refuses up-front if the parsed instance exceeds a core table — see parse gates — so the solve is bounded both in size and in search.) NOTE for Phase 2: if Module-16 grows a `smt_solve_budget(cap, node_budget)` entry the wrapper should prefer it; absent that, the budget is enforced as the static-capacity + core-node-cap composition, and `budget_nodes` is recorded into the witness transcript so the bound is witnessed even when the core's cap is the operative limit. (Flagged in Gap list.)
5. **Capability for witness (M8):** `have_cap = (cap_id != SMTS_NULL_CAP) AND (cap_verify_rights(cap_id, SMTS_RIGHT_ATTEST) == 1u8)`. If a `cap_id` was supplied but the right is absent ⇒ `SMTS_E_NOCAP` (an explicit request that fails is an error, not silent suppression). Build the core capability byte-flag: write `1u8` into a scratch byte iff `have_cap`, else `0u8` (Module-16 treats nonzero as cap-present), and take its address for `smt_solve_cap`.
6. **Solve:** `r = smt_solve_cap(&cap_flag)`. If `r` is a hard negative (not SAT/UNSAT) ⇒ `SMTS_E_CORE`. If `r == SMTS_CORE_UNSAT` ⇒ set `SMTS_LAST_RESULT=SMTS_UNSAT`, `SMTS_HAVE_MODEL=0u8`, go to step 9 (mint UNSAT certificate + witness). If `r == SMTS_CORE_SAT` continue.
7. **Independent model re-check (M12/M18 — the verifier obligation):** `if smt_check_model() != 1u8 ⇒ SMTS_E_VERIFY` (the core claimed SAT but its own independent re-checker rejects the model — a substrate integrity fault; never return a SAT the model checker won't confirm). Set `SMTS_LAST_RESULT=SMTS_SAT`, `SMTS_HAVE_MODEL=1u8`.
8. (model is readable via `smts_result_value_*`, which delegate to `smt_lia_value`/`smt_bv_value`.)
9. **Certificate (M11/M12/M18):** compute `SMTS_IN_COMMIT = keccak256_oneshot(formula_ptr, formula_len)`. If SAT, fold the model into `SMTS_OUT_COMMIT` (see Witness); if UNSAT, `SMTS_OUT_COMMIT = keccak of (result tag || in_commit)`. Mint a proof-term: `pt_alloc(&SMTS_LAST_TERM)`; fill a `pt_add_inference` args record (rule `SMTS_PT_RULE_CITE`, one premise = a library index encoding the result tag, conclusion = `SMTS_IN_COMMIT||SMTS_OUT_COMMIT`); `pt_finalize(&SMTS_LAST_TERM)`; `pt_verify(&SMTS_LAST_TERM)`. A non-OK `pt_verify` ⇒ `SMTS_E_VERIFY`. Set `SMTS_HAVE_TERM=1u8`.
10. **Witness (M6/M10), capability-gated:** if `have_cap`, call `smt_witness(&SMTS_CORE_WIT)` (fold the core's own witness in), then canonically serialize `(SMTS_LAST_RESULT tag, SMTS_IN_COMMIT, SMTS_CORE_WIT, model digest)` into `SMTS_WIT_SCRATCH` and `keccak256_oneshot` ⇒ `SMTS_WIT_HASH`; set `SMTS_WIT_VALID=1u8`; build the 40-byte `SMTS_FRAG_PAYLOAD` (`SMTS_FRAG_MAGIC||SMTS_FRAG_KIND||6 pad||SMTS_LAST_TERM`), `ident_zero(&SMTS_PRODUCER)`, `ident_zero(&SMTS_OPID)`, and `wh_publish(&SMTS_PRODUCER, &SMTS_OPID, &SMTS_IN_COMMIT, &SMTS_OUT_COMMIT, SMTS_WH_REVTAG, SMTS_WH_PHASE, SMTS_WH_PILLAR, 0-null, 0u32, &SMTS_FRAG_PAYLOAD, 40u32, &SMTS_FRAG_ID)`; map `wh_publish`'s `0xFFFF...` sentinel to `SMTS_E_CORE`. If `!have_cap`, `SMTS_WIT_VALID=0u8` and emit nothing (reversibility default, M9: the solve verdict is unchanged whether or not a witness is emitted).
11. Return `SMTS_LAST_RESULT`.

The whole solve is bounded (M19): parse is `<= SMTS_MAX_RECORDS` records; the core search is node-capped; the certificate/witness are fixed-size. On any capacity breach the answer is a refusal code, never divergence and never a corrupt result (M5).

### `smts_verify(args)` — the independent second line (M12/M18)
Guard inited + non-null. Read the `SMTS_SOLVEARG` record incl. `claimed_result` (off 40) and `claimed_term_id` (off 48). This does NOT trust the live core state — it re-establishes it:
1. `smt_init()` (fresh core); `smts_parse_into_core(formula_ptr, formula_len, theory_mask)` (re-parse the same instance independently). Propagate parse errors.
2. `r = smt_solve_cap(&zero_cap)` (no witness needed for the verify path). If `r` is a hard negative ⇒ `SMTS_E_CORE`.
3. **Cross-check verdict:** the recomputed `r` must equal `claimed_result` (mapped: `SMTS_RESULT_SAT`↔`SMTS_CORE_SAT`, `_UNSAT`↔`_UNSAT`), compared by `==` only (W11). Mismatch ⇒ `SMTS_E_VERIFY`.
4. If the claim is SAT: `smt_check_model()` must return `1u8` ⇒ else `SMTS_E_VERIFY`.
5. **Certificate check:** `pt_verify(claimed_term_id)` must return `PT_OK` (0) ⇒ else `SMTS_E_VERIFY` (compared `== 0i32`, W11). (The claimed term id is the one minted by the producing `smts_solve`; re-verifying it confirms the certificate is intact.)
6. Return `SMTS_OK`. This realizes "the verifier separately checks the result against the theory consistency conditions": an *independent* re-parse + re-solve + model re-check + certificate re-verify, none of which trusts the prior in-memory model. Determinism (M2) makes the re-solve verdict identical to the original.

### `smts_result_value_lia` / `smts_result_value_bv`
`smts_result_value_lia(var1)`: guard `SMTS_HAVE_MODEL==1u8` (else `0i64`); return `smt_lia_value(var1)` (Module-16 range-checks and returns its own `0i64` sentinel for a bad handle). `smts_result_value_bv(var1)`: guard `SMTS_HAVE_MODEL==1u8` (else `0u64`); return `smt_bv_value(var1)`. No pointer math on the wrapper side (no Trap-4 exposure here — values flow through the core).

### `smts_witness`
If `SMTS_WIT_VALID==0u8` ⇒ `SMTS_E_BAD`. Else copy `SMTS_WIT_HASH[0..32]` to `out_32` byte-by-byte (Trap 5) and return `SMTS_OK`.

### `smts_last_term`
If `SMTS_HAVE_TERM==0u8` ⇒ `SMTS_E_BAD`. Else `ident_copy(&SMTS_LAST_TERM, out_term_id)`; return `SMTS_OK`.

### `smts_selftest`
Run the KAT vectors below in-process; return a bitmask of failures (`0u64` = all pass).

### No recursion (W15)
The wire parser, the var-resolution map fill, the transcript serializer, and the model-read accessors are all flat cursor/counter loops over fixed module-scope arrays. No function in this module calls itself; the only call graph is wrapper→core/provider externs.

## KAT Vectors (>= 3)
A self-test (`smts_selftest`) builds each instance into `SMTS_KAT_FMT`, fills `SMTS_KAT_ARG`, and checks byte-for-byte. (Because the LIA/BV verdicts come from the Module-16 core, the SAT/UNSAT result and model values are pinned by `smt.spec.md`'s own KATs; these vectors pin the **wrapper's** parse → drive → re-verify → witness behavior, including the negative cases.)

1. **LIA SAT instance solves + model + independent verify.** `SMTS_FMT` = magic,ver; `NEWVAR_L`(x), `NEWVAR_L`(y); `LIA_LE` n=2 coeffs[1,1] vars[0,1] b=3; `LIA_EQ` n=2 coeffs[1,-1] vars[0,1] b=1; `END`. `theory_mask=SMTS_TH_LIA`. Expected: `smts_solve(arg)==SMTS_SAT`; `smts_result_value_lia(1)==1i64`, `smts_result_value_lia(2)==0i64` (the Module-16 deterministic vertex x=1,y=0). Then `smts_verify` with `claimed_result=SMTS_RESULT_SAT` and the `smts_last_term` id ⇒ `SMTS_OK`. (Mirrors `smt.spec.md` KAT 1, threaded through the wrapper.)

2. **LIA UNSAT instance.** `NEWVAR_L`(x); `LIA_LE` n=1 coeffs[1] vars[0] b=2; `LIA_GE` n=1 coeffs[1] vars[0] b=5; `END`. Expected `smts_solve==SMTS_UNSAT`; `smts_result_value_lia(1)==0i64` (sentinel, no model). `smts_verify` with `claimed_result=SMTS_RESULT_UNSAT` ⇒ `SMTS_OK`. (Prove UNSAT propagates and is independently re-confirmed.)

3. **BV ult SAT instance.** `NEWVAR_B`(width=4)→a, `NEWVAR_B`(width=4)→c; `BV_ULT` a,c; `END`. `theory_mask=SMTS_TH_BV`. Expected `smts_solve==SMTS_SAT` and `smts_result_value_bv(1) < smts_result_value_bv(2)` unsigned (the wrapper trusts the core's `smt_check_model` gate, which fired in step 7). `smts_verify` ⇒ `SMTS_OK`.

4. **Malformed wire rejects (prove the negative).** Instance with a bad magic byte (`0x00` instead of `0xA7`). Expected `smts_solve==SMTS_E_MALFORMED` (-3). Also: a `LIA_LE` record whose declared `n` runs the cursor past `formula_len` ⇒ `SMTS_E_MALFORMED`. (Parser refuses, never reads OOB — M5.)

5. **Capacity refusal (prove the negative, M19).** A synthetic header with `formula_len = SMTS_MAX_FMT_BYTES + 1` ⇒ `smts_solve==SMTS_E_TOO_BIG` (-4) **before** any core call. And an instance declaring more than `SMT_MAX_LIA_VARS` LIA vars ⇒ `SMTS_E_TOO_BIG` (core capacity guard fires; the core is never asked to truncate).

6. **Verify rejects a tampered claim (prove the negative, M12).** Solve KAT 1 (SAT). Then call `smts_verify` with `claimed_result=SMTS_RESULT_UNSAT` (lying about the verdict) ⇒ `SMTS_E_VERIFY` (-6) — the independent re-solve yields SAT, contradicting the claim. Separately, `smts_verify` with a `claimed_term_id` of all-zero bytes ⇒ `SMTS_E_VERIFY` (`pt_verify` rejects the absent term). (The verifier FAILS on bad input — no-autogen-stub discipline.)

7. **Witness reproducibility + capability gate (M6/M8/M10).** With a `cap_id` carrying `CAP_RIGHT_ATTEST`, solve KAT 1, capture `smts_witness(&w1)`; re-`smts_init`, re-solve identical KAT 1, capture `smts_witness(&w2)`; assert `w1==w2` byte-for-byte (32 bytes). With `cap_id=SMTS_NULL_CAP`, `smts_witness` ⇒ `SMTS_E_BAD` (suppressed). With a `cap_id` lacking `CAP_RIGHT_ATTEST`, `smts_solve` ⇒ `SMTS_E_NOCAP`.

`smts_selftest` returns `0u64` only if all of the above hold; each failure sets a distinct bit.

## Trap Exposure
1. **Multi-line `fn` (Trap 1):** all 8 public signatures + every extern (incl. the 12-param `wh_publish` and the 4-param `smt_lia_add_*`) are single-line. The longest, `smt_lia_add_le(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32`, fits one physical line. AVOIDANCE: Phase 2 keeps each `fn ... {` on one line.
2. **Module-level `const`/`@export` linker-global (Trap 2):** **the gospel violates this at the function-symbol level** — it `@export`s `smt_init` and `smt_solve`, which collide with Module-16's `smt_init`/`smt_solve` (`L_smt_init` defined twice → linker reject or silent wrong-call). FIX/AVOIDANCE: every public function and every const uses the `SMTS_`/`smts_` prefix (grep-confirmed 0 collisions tree-wide). This is the single most important correction.
3. **Signed-ordering SIGSEGV (Trap 3):** the only signed values are the `i32` status/result codes and `i64` LIA coefficients/bounds/values. All status decisions use `== / !=` (e.g. `r == SMTS_CORE_SAT`, `pt_verify(...) == 0i32`, `claimed==recomputed`). The `i64` coeffs/bounds are **only read from the wire and passed straight to the core** — the wrapper never orders them. The core (`smt.iii`) owns all `i64` magnitude comparison via its `smt_rat_sign`/`smt_rat_cmp` (Trap-3-clean per `smt.spec.md`). AVOIDANCE: **no `i32`/`i64` `<`/`<=`/`>`/`>=` anywhere in this module.** Capacity/cursor/record bounds are **unsigned** (`SMTS_P_CURSOR >= formula_len`, `n > SMTS_MAX_TERMLEN`, `SMTS_P_NREC >= SMTS_MAX_RECORDS`) — not a Trap-3 case.
4. **`u32`-in-`u64`-slot garbage (Trap 4):** wire-var indices and record fields are `u32`, but the wrapper uses them as **array indices into module-scope arrays** (the resolver `handle = HANDLE_MAP[idx]`), not as raw pointer arithmetic. Where a `u32` index feeds an address computation (e.g. `&SMTS_TERM_COEFF[i]`), the index is masked `(i as u64) & 0xFFFFFFFFu64` before the multiply, and element addresses are lowered as `((&ARR as u64) + (off as u64)) as *T` (the `witness_hook.iii` house idiom). AVOIDANCE: mask every `u32 as u64` before pointer math; the formula cursor is `u64` natively.
5. **`u32` pointer store width (Trap 5):** **all** wire reads/writes are byte-by-byte through `*u8` (the SMTS_FMT codec reads LE fields one byte at a time; the witness transcript and 40-byte payload are assembled byte-by-byte). The only `*u32`/`*i64` pointers **passed** are `&SMTS_TERM_VAR[0]` / `&SMTS_TERM_COEFF[0]` to `smt_lia_add_*` — these point at real module-scope typed arrays the wrapper filled by **indexed element store** (`SMTS_TERM_VAR[i]=v`), the normal typed-array path, never a `*u32` aliasing a single u32 local. AVOIDANCE: never build a wire field through a `*u32` over a u32 local; index the typed array or store bytes.
6. **Nested `/* */` (Trap 6):** comments are flat; `//` for inline notes. AVOIDANCE: no nested block comments.
7. **Local `var` arrays (Trap 7):** every scratch buffer (`SMTS_TERM_COEFF/VAR`, `SMTS_WIT_SCRATCH`, `SMTS_FRAG_PAYLOAD`, `SMTS_PRODUCER/OPID/IN_COMMIT/OUT_COMMIT/CORE_WIT/FRAG_ID`, `SMTS_KAT_*`, `SMTS_ARG_SCRATCH`) is **module-scope** with an `SMTS_` name. NOTE: this makes the solve/verify paths **non-reentrant** — acceptable, single serialized SMT entry point (documented; same convention as `proof_term.iii`/`witness_hook.iii`).
8. **`} else {` one line (Trap 8):** the record-tag dispatch cascade in `smts_parse_into_core` and every guard write `} else {` on one physical line. AVOIDANCE enforced in Phase 2.
9. **Em-dash in comments (Trap 9):** all `.iii` comments use ASCII `--`/`->`, never U+2014. (This spec's prose em-dashes never enter the source.)
10. **`let mut x=0u32` checkpoint-flag (Trap 10):** the parser uses `SMTS_DONE` as a **sentinel that drives the `while` condition itself** (`while SMTS_DONE == 0u8`), not a post-hoc mutated checkpoint; guards use early-return. AVOIDANCE: sentinel-in-condition, not a trailing mutated flag.
11. **`a % b` after call (Trap 11):** **no modulo anywhere** in this module — all wire offsets are cursor add/advance, all indexing is multiply/add. N/A.
12. **`@specialize *T` stride (Trap 12):** **not applicable** — no generics; all arrays are concretely typed (`[i64;N]`/`[u32;N]`/`[u8;N]`). No `@specialize`.

## Gap / Fix List
The candidate is a STUB. Every defect and its fix:

1. **Phantom core extern `smt_v1_solve` (FATAL — non-buildable).** Gospel: `extern smt_v1_solve(formula, formula_len, theories, theory_count, out_result) from "smt.iii"`. **No such symbol exists**; the realized Module-16 `smt.iii` is a stateful builder with no blob entry (verified against `smt.spec.md` public API, lines 13-28). FIX: drop `smt_v1_solve`; extern the real builder surface (`smt_init`/`smt_lia_*`/`smt_bv_*`/`smt_share`/`smt_solve_cap`/`smt_lia_value`/`smt_bv_value`/`smt_check_model`/`smt_witness`) and define the `SMTS_FMT` wire format the wrapper parses into those builder calls (Algorithm). This is the substance of "at scale."

2. **Function-symbol collision `smt_init`/`smt_solve` (FATAL — Trap 2).** Gospel `@export`s `smt_init` and `smt_solve`, identical to Module-16's `@export`s ⇒ duplicate `L_smt_init`/`L_smt_solve`. FIX: rename all public fns to the `smts_` prefix (`smts_init`, `smts_solve`, `smts_verify`, …). Prefix grep-confirmed collision-free.

3. **`proof_term` extern arity wrong + not-yet-built.** Gospel uses `pt_alloc/pt_finalize/pt_verify` (arities OK) but the broader gospel `pt_add_inference` is 6-param; the realized Module-61 collapses it to `(args:*u8)` (verified against `proof_term.spec.md`). FIX: extern `pt_add_inference(args:*u8)`; build the args record per the Module-61 layout. Mark `proof_term.iii` (Module 61) NOT-YET-BUILT (wave-order before 75).

4. **No actual scale orchestration.** Gospel forwards a blob to a non-existent solver and ignores `theories`/`theory_count`. FIX: real `SMTS_FMT` parser with static capacity ceilings (`SMTS_MAX_RECORDS`/`SMTS_MAX_FMT_BYTES`), a theory mask gating record families, and up-front core-capacity refusal so the core never truncates (M19).

5. **`budget` accepted but never enforced (M19 violation).** Gospel passes `budget:*u8` and never reads it ⇒ unbounded in practice. FIX: read `budget_nodes`; default to `SMTS_BUDGET_DEFAULT`; compose with Module-16's node cap; record the budget into the witness transcript so the bound is witnessed. **Phase-2 flag:** if Module-16 adds a `smt_solve_budget(cap, node_budget)` entry, prefer it for a tighter per-solve cap; the contract pin is noted in Dependencies.

6. **"verify" does not verify the result (M12/M18 violation).** Gospel `smt_verify` ignores `formula`/`result` and just re-calls `pt_verify(term_id)` on a handed-in id — it never re-checks the model against the theory conditions. FIX: `smts_verify` re-parses the instance into a **fresh** core, re-solves, cross-checks the verdict against the claim (`==` only), runs `smt_check_model` for SAT, and re-verifies the proof-term certificate. This is the gospel prose's "verifier separately checks the result against the theory consistency conditions," realized as a genuinely independent line (M11/M12/M18).

7. **No witness (M6/M10 absent).** Gospel emits nothing. FIX: capability-gated (`cap_verify_rights(cap_id, CAP_RIGHT_ATTEST)`) witness: fold the core's `smt_witness` into a canonical transcript, `keccak256_oneshot` it, and `wh_publish` a `SMT_AT_SCALE_SOLVED` fragment. Byte-reproducible from recorded inputs (M10). Suppressed (not errored) under `SMTS_NULL_CAP`; an explicit cap lacking the right ⇒ `SMTS_E_NOCAP`.

8. **Result-code conflation risk.** Gospel maps `solve != 0i32` ⇒ `SMT_E_TIMEOUT`, swallowing the SAT/UNSAT distinction and treating UNSAT (2) as an error. FIX: mirror Module-16's `SAT=1`/`UNSAT=2`/`OK=0` exactly; a negative core return ⇒ `SMTS_E_CORE`; UNSAT is a **valid** result, not an error.

9. **Dead `ident_zero` extern (gospel imports it, never uses it).** FIX: this module legitimately uses `ident_zero` (zero producer/op ids for `wh_publish`) and `ident_copy` — keep, with real uses.

10. **No model read-back / no last-term accessor.** Gospel returns a verdict but exposes no way to read the model or the certificate id. FIX: `smts_result_value_lia/bv` (delegate to core) and `smts_last_term`.

11. **No self-test.** Gospel ships no KAT. FIX: `smts_selftest` returning a failure bitmask, with **three negative cases** (malformed wire, capacity refusal, tampered-claim verify) per the no-autogen-stub mandate (gates proven to FAIL on bad input).

**Mandate audit (post-fix):** M1 ✓ (NIH parser/codec/transcript; only libc-free providers), M2 ✓ (parse = byte order; core deterministic; transcript a pure function of state), M3/M4 ✓ (no portfolio/restart/scoring/observe-adapt — fixed replay + fixed budget), M5 ✓ (every capacity/budget breach is a refusal code, never divergence or corruption), M6/M10 ✓ (capability-gated reproducible witness via `wh_publish`), M7 ✓ (R0), M8 ✓ (witness gated on `CAP_RIGHT_ATTEST`), M9 ✓ (re-`smts_init` restores empty state; solve verdict independent of witness emission), M11 ✓ (proof-term certificate per accepted result), M12/M18 ✓ (independent re-parse + re-solve + model re-check + certificate re-verify = checkable carrier), M13 ✓ (no self-reflection; bounded record/var counts), M14 — provenance: the witness records the instance commitment + core witness (dependency closure of the decision) — compliant, M15 ✓ (LIA/BV algebra is the core's, total over its bit width), M16 — verdicts are anchored by the witness fragment (ratifiable), M17 ✓ (verify never trusts the live model — re-establishes it), M19 ✓ (static capacity + node-cap budget + refusal), M20 ✓ (does not reason about itself). W2 ✓ (all public fns <=4 params via the arg record), W8 ✓ (all tables static), W9/W10/W12 ✓ (negative-i32 errors, `u8` bool from `cap_verify_rights`/`smt_check_model`, every public fn returns a status), W11/Trap3 ✓ (i32/i64 equality only), W13 ✓ (helpers stay under 20 locals — the parser hoists state to module scope), W14 ✓ (sentinel-driven parse loop, no break), W15 ✓ (flat cursor scans, no recursion), W5/W16/W17 ✓ (byte-fixed transcript; `wh_publish` advances algebraic time via `at_advance`; reversible revtag).

## Implementation Skeleton
Structurally paste-ready. SINGLE-LINE signatures. No fn bodies (Phase 2 writes those per Algorithm §).

```iii
/* III/STDLIB/iii/numera/smt_at_scale.iii
 *
 * III STDLIB - numera::smt_at_scale  (Layer 8, Module 75)
 *
 * Industrial-scale SMT front end + INDEPENDENT result verifier over the
 * Module-16 DPLL(T) core (numera/smt.iii).  This module adds NO solving
 * heuristic of its own (that would risk M3/M4); "at scale" is exactly a
 * large fixed capacity, an explicit cost budget (refusal on overrun --
 * M5/M19), and a second, independent line of verification.
 *
 * Flow: parse a canonical serialized instance (SMTS_FMT) into the Module-16
 * stateful builder in fixed wire order, drive a bounded deterministic solve,
 * INDEPENDENTLY re-check the model (smt_check_model) and mint + verify a
 * proof-term certificate (proof_term.iii), then emit a capability-gated,
 * byte-reproducible witness fragment (witness_hook.iii::wh_publish).
 *
 * Reconciliations vs gospel body (see smt_at_scale.spec.md Gap list):
 *   -- DROP phantom smt_v1_solve; use the real Module-16 builder surface
 *   -- RENAME public fns to smts_* (gospel smt_init/smt_solve collide with Module-16 L_smt_*)
 *   -- pt_add_inference is single *u8 arg record (Module-61 W2 collapse)
 *   -- enforce budget (gospel ignored it -- M19)
 *   -- smts_verify re-parses + re-solves + re-checks model + re-verifies cert (M12/M18)
 *   -- add capability-gated reproducible witness (gospel emitted none -- M6/M10)
 *   -- all scratch hoisted to module scope (iiis Trap 7); non-reentrant (serialized)
 *
 * Hexad: kind_cognition.  Ring: R0.  K: 0.99 (verifier).
 * Discipline: <=4 public params (arg record); sentinel loops, no break (W14);
 * no recursion (W15); i32/i64 equality only (W11/Trap3); static tables (W8).
 */
module numera_smt_at_scale

// --- Module-16 DPLL(T) core (numera/smt.iii) -- realized stateful builder ---
extern @abi(c-msvc-x64) fn smt_init() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_new_var() -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_add_le(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_add_ge(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_add_eq(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_new_var(width: u32) -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_eq(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_ult(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_share(lia_var: u32, bv_var: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_solve_cap(cap: *u8) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_lia_value(var: u32) -> i64 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_value(var: u32) -> u64 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_check_model() -> u8 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_witness(out_32: *u8) -> i32 from "smt.iii"

// --- proof-term certificate (numera/proof_term.iii) -- realized arities ---
extern @abi(c-msvc-x64) fn pt_init() -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_alloc(out_term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_add_inference(args: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_finalize(term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn pt_verify(term_id: *u8) -> i32 from "proof_term.iii"

// --- identity / hash (built) ---
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"

// --- capability + witness (built) ---
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

const SMTS_OK            : i32 =  0i32
const SMTS_SAT           : i32 =  1i32
const SMTS_UNSAT         : i32 =  2i32
const SMTS_E_NULL        : i32 = -1i32
const SMTS_E_NOT_INITED  : i32 = -2i32
const SMTS_E_MALFORMED   : i32 = -3i32
const SMTS_E_TOO_BIG     : i32 = -4i32
const SMTS_E_BUDGET      : i32 = -5i32
const SMTS_E_VERIFY      : i32 = -6i32
const SMTS_E_CORE        : i32 = -7i32
const SMTS_E_BAD         : i32 = -8i32
const SMTS_E_NOCAP       : i32 = -9i32

const SMTS_CORE_OK       : i32 =  0i32
const SMTS_CORE_SAT      : i32 =  1i32
const SMTS_CORE_UNSAT    : i32 =  2i32

const SMTS_FMT_MAGIC     : u8 = 0xA7u8
const SMTS_FMT_VERSION   : u8 = 0x01u8
const SMTS_REC_LIA_LE    : u8 = 0x01u8
const SMTS_REC_LIA_GE    : u8 = 0x02u8
const SMTS_REC_LIA_EQ    : u8 = 0x03u8
const SMTS_REC_BV_EQ     : u8 = 0x04u8
const SMTS_REC_BV_ULT    : u8 = 0x05u8
const SMTS_REC_SHARE     : u8 = 0x06u8
const SMTS_REC_NEWVAR_L  : u8 = 0x07u8
const SMTS_REC_NEWVAR_B  : u8 = 0x08u8
const SMTS_REC_END       : u8 = 0xFFu8

const SMTS_TH_LIA        : u32 = 0x01u32
const SMTS_TH_BV         : u32 = 0x02u32

const SMTS_MAX_RECORDS   : u32 = 1048576u32
const SMTS_MAX_FMT_BYTES : u64 = 67108864u64
const SMTS_MAX_TERMLEN   : u32 = 4096u32
const SMTS_BUDGET_DEFAULT: u64 = 16777216u64

const SMTS_RESULT_SAT    : u8 = 1u8
const SMTS_RESULT_UNSAT  : u8 = 2u8
const SMTS_PT_RULE_CITE  : u8 = 0x07u8

const SMTS_FRAG_MAGIC    : u8 = 0xE4u8
const SMTS_FRAG_KIND     : u8 = 0x4Bu8
const SMTS_WH_PHASE      : u8 = 0u8
const SMTS_WH_PILLAR     : u16 = 0u16
const SMTS_WH_REVTAG     : u8 = 0u8

const SMTS_RIGHT_ATTEST  : u64 = 0x0800u64
const SMTS_NULL_CAP      : u64 = 0u64

// --- lifecycle / last-result ---
var SMTS_INITED      : u8 = 0u8
var SMTS_LAST_RESULT : i32 = 0i32
var SMTS_HAVE_MODEL  : u8 = 0u8
var SMTS_LAST_TERM   : [u8; 32]
var SMTS_HAVE_TERM   : u8 = 0u8

// --- argument record (caller-fill; single-arg ABI) ---
var SMTS_ARG_SCRATCH : [u8; 96]

// --- wire-parse working state ---
var SMTS_P_CURSOR    : u64 = 0u64
var SMTS_P_NREC      : u32 = 0u32
var SMTS_TERM_COEFF  : [i64; 4096]
var SMTS_TERM_VAR    : [u32; 4096]
var SMTS_DONE        : u8 = 0u8

// --- var-resolution maps (wire 0-based decl index -> core 1-based handle) ---
var SMTS_LIA_HANDLE  : [u32; 256]
var SMTS_LIA_NDECL   : u32 = 0u32
var SMTS_BV_HANDLE   : [u32; 256]
var SMTS_BV_NDECL    : u32 = 0u32

// --- witness / certificate transcript ---
var SMTS_WIT_HASH    : [u8; 32]
var SMTS_WIT_VALID   : u8 = 0u8
var SMTS_WIT_SCRATCH : [u8; 65536]
var SMTS_CORE_WIT    : [u8; 32]
var SMTS_OUT_COMMIT  : [u8; 32]
var SMTS_FRAG_PAYLOAD: [u8; 40]
var SMTS_PRODUCER    : [u8; 32]
var SMTS_OPID        : [u8; 32]
var SMTS_IN_COMMIT   : [u8; 32]
var SMTS_FRAG_ID     : [u8; 32]

// --- proof-term args scratch (Module-61 PT_ADDARG layout) ---
var SMTS_PT_ARG      : [u8; 600]

// --- core-capability one-shot flag passed to smt_solve_cap ---
var SMTS_CAP_FLAG    : [u8; 8]

// --- KAT scratch ---
var SMTS_KAT_FMT     : [u8; 4096]
var SMTS_KAT_ARG     : [u8; 96]
var SMTS_KAT_W1      : [u8; 32]
var SMTS_KAT_W2      : [u8; 32]

// --- internal helpers (non-export; no recursion) ---
fn smts_rd_u32(off: u64) -> u32 { return 0u32 }                                          // TODO: LE u32 read byte-by-byte from formula cursor (Trap 5)
fn smts_rd_i64(off: u64) -> i64 { return 0i64 }                                          // TODO: LE i64 read byte-by-byte (Trap 5)
fn smts_parse_into_core(formula_ptr: u64, formula_len: u64, theory_mask: u32) -> i32 { return SMTS_OK }  // TODO: flat cursor scan; dispatch records into builder (Algorithm)
fn smts_mint_cert(result_tag: u8) -> i32 { return SMTS_OK }                              // TODO: pt_alloc/add_inference(LIBRARY_CITE)/finalize/verify (Algorithm step 9)
fn smts_emit_witness(result_tag: u8, have_cap: u8) -> i32 { return SMTS_OK }             // TODO: transcript -> keccak -> wh_publish, gated (Algorithm step 10)

// --- public API (single-line signatures) ---
fn smts_init() -> i32 @export { return SMTS_OK }                                         // TODO: smt_init + pt_init; reset state (Algorithm smts_init)
fn smts_solve(args: *u8) -> i32 @export { return SMTS_UNSAT }                            // TODO: parse + bounded solve + model re-check + cert + witness (Algorithm smts_solve)
fn smts_verify(args: *u8) -> i32 @export { return SMTS_E_VERIFY }                        // TODO: independent re-parse + re-solve + model re-check + pt_verify (Algorithm smts_verify)
fn smts_result_value_lia(var1: u32) -> i64 @export { return 0i64 }                       // TODO: guard model; smt_lia_value
fn smts_result_value_bv(var1: u32) -> u64 @export { return 0u64 }                        // TODO: guard model; smt_bv_value
fn smts_witness(out_32: *u8) -> i32 @export { return SMTS_E_BAD }                        // TODO: copy SMTS_WIT_HASH if valid
fn smts_last_term(out_term_id: *u8) -> i32 @export { return SMTS_E_BAD }                 // TODO: ident_copy SMTS_LAST_TERM if present
fn smts_selftest() -> u64 @export { return 0u64 }                                        // TODO: run KAT vectors 1-7 incl. 3 negative cases
```
