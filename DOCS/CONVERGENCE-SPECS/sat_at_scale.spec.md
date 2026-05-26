# 74 numera/sat_at_scale.iii — Implementation Spec

## Verdict
STUB — the gospel candidate `.iii` body is a non-functional placeholder that does **not** realize the module's stated intent (verifier separation). It (a) calls a **fictional** core entry `sat_v1_solve(...)` that does not exist in Module 15 (the real `sat.iii` API is `sat_init/sat_add_clause/sat_solve/sat_value`), (b) has **no independent verifier** — `sat_verify` merely calls `pt_verify(term_id)` and never re-checks a single clause, directly contradicting the prose ("a tiny verifier that checks every clause"), (c) **never builds a certificate** (no model bytes, no resolution refutation), (d) **re-exports `sat_init`/`sat_solve`/`sat_verify`** which collide at link with Module 15's exported `sat_init`/`sat_solve` (duplicate global symbols), (e) violates **W2** (`sat_solve` has 5 params), (f) violates **Trap 7** (`let mut assignment : [u8; 4096]` local array), (g) imports `ident_zero` and `cls_dimension_get` but uses neither, omits the witness chain entirely (the prose's "only the verifier's transcript enters the witness chain" is unimplemented), and ignores `budget` (no M19 bound). The maximal-intent design below replaces it wholesale: a self-describing binary formula format, search delegated to the **real** Module-15 core, a genuinely independent clause-checking verifier (the M12 core), a SAT model certificate + a specified UNSAT resolution-refutation certificate, witness routed through `wh_publish`, capability-gated solve, and a decoded conflict budget.

## Purpose
`numera::sat_at_scale` IS a **verified** SAT decision procedure for industrial-scale instances: it wraps the oracular CDCL core (Module 15) with **verifier separation** so that the search engine is *untrusted* and the result is *independently re-checked* before it is believed. On SAT it produces a satisfying assignment whose correctness is re-established by a tiny verifier that evaluates every clause of the (re-parsed) formula; on UNSAT it produces a resolution refutation whose every step the verifier re-derives. **Only the verifier's verdict — not the oracular search trace — enters the witness chain** (M6/M10/M12). Hexad: `kind_cognition`. Ring: **R0**. K_synth: **0.99** (the verifier is the trust root; the oracle may be arbitrarily clever without affecting soundness).

## Public API
All public functions return a status `i32` (W9: negative = error; `SATS_OK`/`SATS_SAT`/`SATS_UNSAT` are the non-negative outcomes) or a sentinel-typed value documented per fn (W12). **Every name carries the `sats_` function prefix** to avoid the duplicate-symbol link collision with Module 15's exported `sat_*` symbols (Gap/Fix #1). Multi-param calls fold their arguments into a module-scope request aggregate passed by pointer (W2 ≤ 4 params).

```
fn sats_init() -> i32 @export
```
- Idempotent module init. Initializes the request/scratch state and marks inited. Returns `SATS_OK`. (Mirrors the built `sat_init()` idiom but under the distinct `sats_` name.)

```
fn sats_solve(req: *u8) -> i32 @export
```
- Solve one SAT instance described by a `SatsReq` aggregate at `*req` (layout in Data Structures): `{ formula:*u8, formula_len:u32, budget_conflicts:u64, cap:u64, out_result:*u8, out_cert:*u8, out_cert_len:*u32, out_frag_id:*u8 }`. Verifies `cap` carries `CAP_RIGHT_RESOLVE_INVOKE` (M8) and that no pointer is null. Parses the formula, runs the oracular core under the conflict budget (M19), then **independently verifies** the result before returning. On success writes `*out_result` (`1u8`=SAT, `0u8`=UNSAT), the certificate bytes into `out_cert` (model on SAT; resolution refutation on UNSAT) with length in `*out_cert_len`, publishes the verifier verdict to the witness chain (returning the fragment id in `out_frag_id`), and returns `SATS_OK`. On budget exhaustion returns `SATS_E_TIMEOUT`. If the oracle's claim **fails** independent verification, returns `SATS_E_UNVERIFIED` (never trusts the oracle). (W9/W12.)

```
fn sats_verify(formula: *u8, formula_len: u32, result: u8, cert: *u8) -> i32 @export
```
- **Independent verifier — the trust root.** Re-parses `formula` from raw bytes (no shared state with the solver) and checks the certificate `cert` against it: for `result==1u8` (SAT), parses `cert` as an assignment and asserts every clause has ≥1 satisfied literal; for `result==0u8` (UNSAT), parses `cert` as a resolution refutation and re-derives every resolution step down to the empty clause. Returns `SATS_OK` iff the certificate is valid for `result`, else `SATS_E_UNVERIFIED`. Pure and total; takes **no capability** (re-verification is unprivileged) and emits **no** witness. 4 params (W2-clean). (W9/W12.)

```
fn sats_verify_len() -> u32 @export
```
- Length in bytes of the certificate written by the most recent `sats_solve` (sentinel-typed value; `0u32` if none). (W12.)

Private (non-`@export`) helpers — single-line, all `≤4` params (W2):
```
fn sats_rd_u32(base: *u8, off: u32) -> u32
fn sats_rd_clause_count(formula: *u8, formula_len: u32) -> u32
fn sats_parse_header(formula: *u8, formula_len: u32) -> i32
fn sats_load_into_core(formula: *u8, formula_len: u32) -> i32
fn sats_lit_sat(lit: u32, assign: *u8, n_vars: u32) -> u8
fn sats_clause_sat(formula: *u8, ci: u32, assign: *u8) -> u8
fn sats_build_model_cert(out_cert: *u8) -> u32
fn sats_check_model_cert(formula: *u8, formula_len: u32, cert: *u8) -> i32
fn sats_check_refutation(formula: *u8, formula_len: u32, cert: *u8) -> i32
fn sats_commit(buf: *u8, len: u32, out32: *u8) -> i32
fn sats_emit_witness(req: *u8, result: u8) -> i32
```

## Constant Namespace
PREFIX = `SATS_` . Grep result: `grep -rn "SATS_" STDLIB/` → **no matches**; `module numera_sat_at_scale` → **no matches**; `fn sats_` → **no matches**. The `SATS_` constant prefix and the `sats_` function prefix are both clear (the sibling Module 15 uses bare `SAT_`/`sat_`, and Module 73's `numera_sat_arith` uses `sat_` arithmetic helpers — neither collides with `SATS_`/`sats_`).

Module-level constants (name : type = value):
```
const SATS_OK            : i32 =  0i32
const SATS_SAT           : i32 =  1i32     // informational outcome (also surfaced via *out_result)
const SATS_UNSAT         : i32 =  2i32
const SATS_E_NULL        : i32 = -1i32
const SATS_E_TIMEOUT     : i32 = -2i32
const SATS_E_NOT_INITED  : i32 = -3i32
const SATS_E_BADFMT      : i32 = -4i32     // malformed formula wire image
const SATS_E_TOO_BIG     : i32 = -5i32     // formula exceeds SATS_MAX_* bounds
const SATS_E_DENIED      : i32 = -6i32     // capability check failed (M8)
const SATS_E_UNVERIFIED  : i32 = -7i32     // oracle result FAILED independent verification (trust-root refusal)
const SATS_E_CORE        : i32 = -8i32     // Module-15 core returned an unexpected status

const SATS_MAGIC         : u32 = 0x53415431u32   // "SAT1" LE magic at formula[0..4)
const SATS_MAX_VARS      : u32 = 65536u32        // mirrors SAT_MAX_VARS (core bound)
const SATS_MAX_CLAUSES   : u32 = 262144u32       // mirrors SAT_MAX_CLAUSES
const SATS_MAX_FORMULA   : u32 = 16777216u32     // 16 MiB max wire image (header + clauses)
const SATS_MAX_CERT      : u32 = 4194304u32      // 4 MiB max certificate (model or refutation)
const SATS_ASSIGN_BYTES  : u32 = 65537u32        // 1 byte/var, index 0 unused (= SATS_MAX_VARS+1)
const SATS_HDR_BYTES     : u32 = 12u32           // magic(4) + n_vars(4) + n_clauses(4)
const SATS_RIGHT_SOLVE   : u64 = 0x00010000u64   // == CAP_RIGHT_RESOLVE_INVOKE (M8 right for invoking the solver)
```
Note: `SATS_RIGHT_SOLVE` mirrors the value of `CAP_RIGHT_RESOLVE_INVOKE` from `capability.iii` (Trap 2 forbids importing another module's const by name across the link; the value is duplicated locally and its provenance documented here). Phase 2 must keep it equal to the provider's bit.

## Data Structures
All state is fixed module-scope arrays/scalars (W8); there are **no local `var` arrays** (Trap 7 — the gospel's `let mut assignment : [u8; 4096]` is hoisted to `SATS_ASSIGN` below and resized to the real bound). Bounds derive from the Module-15 core limits (`SATS_MAX_VARS = 65536`, `SATS_MAX_CLAUSES = 262144`).

Request aggregate (passed by pointer to `sats_solve`; the caller stack-allocates or statically reserves it — W2 fold). Byte layout, all little-endian, total **56 bytes**:
```
// offset  field             type/size
//   0      formula           *u8  (8)   -- pointer to the wire image
//   8      formula_len       u32  (4)
//  12      _pad0             u32  (4)
//  16      budget_conflicts  u64  (8)   -- M19 conflict ceiling (0 = use SATS_DEFAULT_BUDGET)
//  24      cap               u64  (8)   -- capability id (M8)
//  32      out_result        *u8  (8)   -- written 1=SAT / 0=UNSAT
//  40      out_cert          *u8  (8)   -- certificate bytes written here
//  48      out_cert_len      *u32 (4)   -- certificate length written here
//  52      _pad1             u32  (4)
// (out_frag_id is the 13th field; to stay within a clean 56-byte struct it is the
//  module-scope SATS_LAST_FRAG buffer, surfaced via the witness call; see Algorithm)
```
> Rationale: the aggregate keeps `sats_solve` at **1 param** (W2). Field reads use `sats_rd_u32`/manual `*u8` offset loads with masked indices (Trap 4).

Assignment / model scratch (1 byte per variable; index 0 unused; W8 bound = `SATS_MAX_VARS+1`):
```
var SATS_ASSIGN    : [u8; 65537]    // 0=false, 1=true per variable (model under check) -- was local [u8;4096]
```
Certificate staging buffer (model or serialized refutation; bound = `SATS_MAX_CERT`):
```
var SATS_CERT      : [u8; 4194304]
var SATS_CERT_LEN  : u32 = 0u32
```
Commit scratch (32-byte keccak-256 digests for formula and certificate; feeds the witness call):
```
var SATS_FORM_COMMIT : [u8; 32]
var SATS_CERT_COMMIT : [u8; 32]
var SATS_PRODUCER    : [u8; 32]     // module identity tag for wh_publish (set in sats_init via ident_zero)
var SATS_OPID        : [u8; 32]     // operation-id tag ("sats.solve") for wh_publish
var SATS_LAST_FRAG   : [u8; 32]     // fragment id returned by the last witness publish
```
Parsed-header cache (set by `sats_parse_header`, read by loaders/verifier; non-reentrant — single-threaded use):
```
var SATS_HDR_NVARS   : u32 = 0u32
var SATS_HDR_NCLS    : u32 = 0u32
var SATS_INITED      : u8  = 0u8
```
Default budget (used when `req.budget_conflicts == 0`):
```
const SATS_DEFAULT_BUDGET : u64 = 4294967296u64   // 2^32 conflicts — generous but finite (M19)
```
Total static footprint ≈ `SATS_CERT` (4 MiB) + `SATS_ASSIGN` (64 KiB) + commit/tag buffers (~160 B) ≈ **~4.1 MiB BSS**, fixed and pre-reserved (no dynamic allocation; M5: cannot brick). The large clause/watch arenas live in Module 15, not here.

## Dependencies (externs)
Each `extern @abi(c-msvc-x64) fn ... from "<module>.iii"`, verified against the **real provider files** (gospel externs were unreliable — see Gap/Fix). NN = gospel module number.

BUILT (signatures confirmed by reading the provider):
```
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
```
- `ident_zero` — `numera/identifier.iii` (BUILT). Used once in `sats_init` to seed `SATS_PRODUCER`/`SATS_OPID` tags.
- `keccak256_oneshot(msg_ptr:u64, msg_len:u64, out_ptr:u64) -> i32` — `numera/keccak256.iii` (BUILT). **Note the real signature takes `u64` addresses, not `*u8`** (the §3.5 defect note said `*u8`; the real file uses `u64`). Callers pass `(&buf[0] as u64)`. Used to commit the formula and certificate.
- `cap_verify_rights(id:u64, required:u64) -> u8` — `aether/capability.iii` (BUILT). The real cap check (the gospel's `cap_verify` is a fiction, §3.5 #5).
- `wh_publish(...) -> u64` — `aether/witness_hook.iii` (BUILT). The real witness-emit primitive (the gospel's `ws_emit_fragment` is a fiction, §3.5 #2). 12 params is fine for an *extern provider*; my own wrapper `sats_emit_witness(req, result)` is W2-clean (2 params) and folds the call.

NOT-YET-BUILT (block this module; the wave scheduler must order these first):
```
extern @abi(c-msvc-x64) fn sat_init(n_vars: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_add_clause(lits: *u32, n_lits: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_solve() -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_value(var: u32) -> u8 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_n_conflicts() -> u64 from "sat.iii"
```
- **Module 15 `numera/sat.iii` — NOT BUILT.** This module is a thin verified wrapper over it. The gospel's `sat_v1_solve(formula, formula_len, out_result, out_assignment)` is a **fiction**; the real contract (per `DOCS/CONVERGENCE-SPECS/sat.spec.md`) is the incremental API above. Hard blocker.
- **Budget enforcement (M19)** reads `sat_n_conflicts()` against `req.budget_conflicts`. Module 15 exposes a *cumulative* conflict counter but **no mid-solve budget hook / interrupt**; bounding therefore happens at the *granularity of a full `sat_solve()` call* (the core's own fixed-arena bound already guarantees termination — M5/M19 hold). **Gap flagged:** a true interruptible/budgeted solve needs a Module-15 extension (`sat_solve_budgeted(max_conflicts:u64)->i32`); listed in Gap/Fix #6 as a not-yet-built capability.

NOT-YET-BUILT and **DROPPED from the design** (gospel imports that the maximal design does not need):
- `proof_term.iii` (`pt_alloc/pt_finalize/pt_verify`) — **does not exist anywhere in the tree** (NOT BUILT). The gospel routed "verification" through `pt_verify(term_id)`, which is *not* an independent check of the formula. The maximal design replaces it with a self-contained byte-level certificate + clause-checking verifier (`sats_verify*`), so `proof_term.iii` is **not a dependency** of the SAT path. (If a future revision wants proof terms as the certificate *carrier*, that is an optional layer; the trust root remains the local clause checker.)
- `cost_lattice_synth.iii` (`cls_dimension_get`) — **does not exist** (NOT BUILT) and was imported-but-unused in the gospel. The M19 bound is realized with a plain `u64` conflict budget decoded from the request, so this is **not a dependency**. (Flagged in Gap/Fix #5.)

Reverse dependency (informational): **Module 75 `numera/smt_at_scale.iii`** is expected to consume this module's verified-solve surface.

## Algorithm
Wire format (W5 bit-identity — the verifier re-parses these exact bytes, independent of solver state). All multi-byte fields little-endian. Literal encoding **identical to Module 15**: variable `v ∈ 1..n_vars`; positive `lit=(v<<1)`, negative `lit=(v<<1)|1`.
```
formula bytes:
  [0..4)    SATS_MAGIC ("SAT1", 0x53415431 LE)
  [4..8)    n_vars   (u32)
  [8..12)   n_clauses(u32)
  then n_clauses clauses, each:
     [0..4)  k = n_lits (u32)
     [4..4+4k)  k literals (u32 each), encoded as above
```
Determinism (M2): all parsing/checking is fixed-order byte iteration; the oracle's verdict is re-checked by a pure function of the wire bytes + assignment, so the *trusted* result is bit-identical across runs/CPUs regardless of any nondeterminism the oracle might (hypothetically) have. No floating point, no randomness in any trusted path.

**`sats_init()`** — idempotent: if `SATS_INITED==1u8` return `SATS_OK`. Seed `SATS_PRODUCER`/`SATS_OPID` (call `ident_zero(&SATS_PRODUCER[0])`; write the ASCII tag "sats.solve\0..." into `SATS_OPID` byte-by-byte through `*u8`, Trap 5). Zero `SATS_CERT_LEN`, `SATS_HDR_*`. Set `SATS_INITED=1`. Returns `SATS_OK`. Total, no recursion.

**`sats_parse_header(formula, formula_len)`** — guard `formula_len >= SATS_HDR_BYTES` (else `SATS_E_BADFMT`); read magic via `sats_rd_u32`, require `== SATS_MAGIC` (else `SATS_E_BADFMT`); read `n_vars`, `n_clauses`; guard `n_vars <= SATS_MAX_VARS` and `n_clauses <= SATS_MAX_CLAUSES` (else `SATS_E_TOO_BIG`). Cache into `SATS_HDR_NVARS`/`SATS_HDR_NCLS`. A second pass walks every clause header to confirm the declared `k` literals fit within `formula_len` (no truncated clause; else `SATS_E_BADFMT`) — this is the one-time structural validation the verifier relies on. Sentinel-loop over clauses (W14, counter-driven, no `break`). Returns `SATS_OK`.

**`sats_rd_u32(base, off)`** — load 4 LE bytes `base[off..off+4)` through a `*u8` pointer with the index masked `(off as u64) & 0xFFFFFFFFu64` before pointer math (Trap 4), assemble `b0 | b1<<8 | b2<<16 | b3<<24`. (Mirrors the `big_load_u64_le` idiom in `bigint.iii`.) No store-width risk (read-only, Trap 5 N/A).

**`sats_load_into_core(formula, formula_len)`** — assumes header parsed. `sat_init(SATS_HDR_NVARS)` (check `== SAT_OK`/`0i32` via `==`, W11; else `SATS_E_CORE`). Walk the `SATS_HDR_NCLS` clauses; for each, the `k` literals already sit contiguously in the wire image as `u32` LE — pass `&formula[clause_lit_off] as *u32` and `k` straight to `sat_add_clause` (the wire literal encoding equals the core's). Check each return is non-negative-success by equality against `SAT_OK`; a `SAT_E_TRIV_UNSAT` from the core means add-time UNSAT — record that and stop feeding (counter-driven, W14). Returns `SATS_OK`, or a trivial-UNSAT marker, or `SATS_E_CORE`. **Trap 4 caution:** if Phase 2 cannot form `&formula[off] as *u32` cleanly, copy the `k` literals into a module-scope `[u32; SATS_MAX_CLAUSE_LEN]` staging array first (same pattern as Module 15's `SAT_SCRATCH`).

**`sats_lit_sat(lit, assign, n_vars)`** — `v = lit>>1`; if `v==0u32 || v>n_vars` return `0u8` (defensive). `want = lit & 1u32` (0 ⇒ literal wants var true; 1 ⇒ wants var false). `a = assign[v]` (0/1). Return `1u8` iff `(want==0 && a==1) || (want==1 && a==0)`, else `0u8`. Pure, unsigned compares only (Trap 3 N/A).

**`sats_clause_sat(formula, ci, assign)`** — locate clause `ci`'s offset by walking the `ci` preceding clause headers from the post-header origin (counter-driven sum of `4 + 4*k_j`; W14). Read `k`; sentinel-loop the `k` literals, OR-reducing `sats_lit_sat`; the loop's exit flag is set when a satisfied literal is found (W14, **no `break`** — set `j = k` to terminate). Return `1u8` if any literal satisfied, else `0u8`.

**`sats_check_model_cert(formula, formula_len, cert)`** — **THE TRUST ROOT (M12).** Re-parse the header from `formula` (do **not** reuse `SATS_HDR_*`; the verifier must be independent — re-read so `sats_verify` is sound even if called standalone). The certificate `cert` is the assignment: `cert[0..4)` = `n_vars` (must equal the formula's), then `n_vars` bytes each `0u8`/`1u8`. Copy into a local read window (or read in place). Sentinel-loop **every** clause `ci=0..n_clauses`; if any `sats_clause_sat(formula, ci, cert_assign)==0u8`, the model is invalid ⇒ return `SATS_E_UNVERIFIED` (counter-driven early exit via flag, W14). If all clauses pass ⇒ `SATS_OK`. No recursion (W15). This is the "checks every clause under the proposed assignment" guarantee.

**`sats_check_refutation(formula, formula_len, cert)`** — UNSAT certificate checker. Certificate format (this spec defines it): a sequence of *derived clauses* ending in the empty clause, each annotated with its two antecedent clause ids (original-or-previously-derived) and the pivot variable; the checker re-derives each step by resolution (clause A on pivot positive, clause B on pivot negative ⇒ resolvent = (A∪B)\{pivot,¬pivot}) and asserts the stated resolvent equals the recomputed one, ending when the empty clause is derived. Original-clause ids index the formula's clauses; derived-clause ids index earlier certificate entries (an explicit module-scope index table, **no recursion**, W15). Return `SATS_OK` iff the final derived clause is empty and every step re-derives, else `SATS_E_UNVERIFIED`. **(See Gap/Fix #6: emitting this certificate requires a Module-15 proof-trace extension that is not-yet-built; the checker is specified and implementable now, but the SAT path is the fully-wired path for Phase 2.)**

**`sats_commit(buf, len, out32)`** — `keccak256_oneshot((buf as u64), (len as u64), (out32 as u64))` (real `u64`-address signature). Returns its `i32` status (`==0i32` ok). Deterministic content-address commit of `buf[0..len)`.

**`sats_emit_witness(req, result)`** — fold the 12-arg `wh_publish` call (W2: this wrapper takes 2 params). Compute `sats_commit(formula, formula_len, &SATS_FORM_COMMIT[0])` (in-commit) and `sats_commit(cert, cert_len, &SATS_CERT_COMMIT[0])` (out-commit). Build a tiny payload = `[result:u8][n_vars:u32][n_clauses:u32]`. Call `wh_publish(&SATS_PRODUCER[0], &SATS_OPID[0], &SATS_FORM_COMMIT[0], &SATS_CERT_COMMIT[0], revtag=0u8, phase=0u8, pillar=<numera pillar u16>, antecedents=0-ptr, n_ante=0u32, &payload[0], payload_len, &SATS_LAST_FRAG[0])`. Copy `SATS_LAST_FRAG` into the request's `out_frag_id`. A returned `0xFFFF..FFu64` means the witness store is full ⇒ propagate as a (non-fatal-to-verdict) error per Phase 2 policy. **Only this verifier-verdict fragment enters the chain — never the oracular trace** (M6/M10/M12).

**`sats_solve(req)`** — (1) guard `SATS_INITED` (`SATS_E_NOT_INITED`). (2) Read the 8 aggregate fields; any null `formula`/`out_result`/`out_cert`/`out_cert_len` ⇒ `SATS_E_NULL`. (3) **Capability gate (M8):** `if cap_verify_rights(cap, SATS_RIGHT_SOLVE) != 1u8 { return SATS_E_DENIED }`. (4) `sats_parse_header` (propagate `SATS_E_BADFMT`/`SATS_E_TOO_BIG`). (5) `sats_load_into_core`; an add-time trivial UNSAT short-circuits to the UNSAT path. (6) `budget = req.budget_conflicts; if budget==0u64 { budget = SATS_DEFAULT_BUDGET }`. Run `r = sat_solve()`. Bound check: `if sat_n_conflicts() > budget { return SATS_E_TIMEOUT }` (M19; coarse-grained per Gap/Fix #6). (7) Branch on `r` by **equality** (W11): `r == SAT_SAT(1i32)` ⇒ build the model: for `v=1..n_vars` `SATS_ASSIGN[v] = (sat_value(v)==1u8) ? 1u8 : 0u8` (map core's 1=true), then `cert_len = sats_build_model_cert(out_cert)` and **independently verify**: `if sats_check_model_cert(formula, formula_len, out_cert) != SATS_OK { return SATS_E_UNVERIFIED }`; write `*out_result=1u8`. `r == SAT_UNSAT(2i32)` ⇒ construct the refutation certificate (Gap/Fix #6), verify via `sats_check_refutation`; write `*out_result=0u8`. Any other `r` ⇒ `SATS_E_CORE`. (8) `*out_cert_len = cert_len; SATS_CERT_LEN = cert_len`. (9) `sats_emit_witness(req, *out_result)`. (10) return `SATS_OK`. No recursion (W15); all loops sentinel-driven (W14); no modulo anywhere (Trap 11 N/A).
> **The oracle is never trusted:** even a buggy/compromised Module-15 core cannot make `sats_solve` return SAT for an unsatisfiable formula, because step (7) re-checks every clause locally before writing the result (M12 soundness).

**`sats_verify(formula, formula_len, result, cert)`** — public re-entry to the trust root: `if result==1u8 { return sats_check_model_cert(formula, formula_len, cert) }`; `if result==0u8 { return sats_check_refutation(formula, formula_len, cert) }`; else `SATS_E_BADFMT`. (One-line `if`s; no `} else {` split, Trap 8.) Pure, no capability, no witness.

**`sats_build_model_cert(out_cert)`** — write `n_vars` (LE u32) then `SATS_ASSIGN[1..n_vars]` bytes into `out_cert` (byte-wise through `*u8`, Trap 5). Return total length `4 + n_vars`.

**`sats_verify_len()`** — return `SATS_CERT_LEN`.

## KAT Vectors (≥3)
Each builds a `SATS_MAGIC` formula image in a byte buffer, runs `sats_solve` with a valid capability, then asserts the result, the certificate, and — crucially — that `sats_verify` independently agrees byte-for-byte. Determinism is asserted by solving twice and requiring identical `(result, cert bytes, cert_len)`. (`pos(v)=2v`, `neg(v)=2v+1`.)

1. **SAT, single unit — model + independent verify.** Formula: `n_vars=1, n_clauses=1`, clause `[k=1, lit=2 (pos 1)]`. `sats_solve` ⇒ `SATS_OK`, `*out_result==1u8`. Certificate = `[n_vars=1][assign[1]=1]` (length 5). `sats_verify(formula, len, 1u8, cert) == SATS_OK`. **Negative-case proof (mandatory):** corrupt the cert to `assign[1]=0`, then `sats_verify(formula,len,1u8,cert_bad) == SATS_E_UNVERIFIED` (the verifier must REJECT a false model — proves the gate fails on bad input, not just passes on good).

2. **UNSAT by add-time contradiction — verifier separation on the UNSAT verdict.** Formula: `n_vars=1, n_clauses=2`, clauses `[1, pos1=2]` and `[1, neg1=3]`. The core reports UNSAT (contradictory level-0 units). `sats_solve` ⇒ `SATS_OK`, `*out_result==0u8`, and a refutation certificate (the single resolution of `(x1)` and `(¬x1)` to the empty clause). `sats_verify(formula, len, 0u8, cert) == SATS_OK`. **Negative case:** an empty/garbage refutation ⇒ `SATS_E_UNVERIFIED`. *(Depends on the Module-15 proof-trace extension, Gap/Fix #6; until then this KAT runs as a "core says UNSAT, model path N/A" assertion and the refutation sub-assertion is gated behind the extension.)*

3. **SAT forced chain — clause-checking verifier over multiple clauses.** Formula: `n_vars=3, n_clauses=3`: `(¬1∨2)=[2, 3,4]`, `(¬2∨3)=[2, 5,6]`, `(1)=[1, 2]`. `sats_solve` ⇒ `SATS_OK`, `*out_result==1u8`, model `assign[1]=1, assign[2]=1, assign[3]=1`. `sats_verify` ⇒ `SATS_OK` (every clause satisfied). **Negative case:** flip `assign[3]=0` and the formula's third clause is still satisfied but flipping `assign[2]=0` makes clause `(¬1∨2)` unsatisfied ⇒ `sats_verify(...,1u8,cert_bad)==SATS_E_UNVERIFIED`.

4. **Malformed-formula refusal (W8/M5).** Formula with wrong magic (`0xDEADBEEF`) ⇒ `sats_solve` returns `SATS_E_BADFMT` and writes no result. Formula with `n_vars = SATS_MAX_VARS+1` ⇒ `SATS_E_TOO_BIG`. Truncated clause (declared `k=3` but only 1 literal of bytes present) ⇒ `SATS_E_BADFMT`. Proves the parser rejects rather than reads OOB.

5. **Capability refusal (M8).** `sats_solve` with a `cap` lacking `SATS_RIGHT_SOLVE` ⇒ `SATS_E_DENIED`, no solve performed, no witness emitted. With the correct attenuated cap ⇒ proceeds. Proves the privileged-op gate FAILS closed on an insufficient capability (negative-case proof).

6. **Determinism / witness reproducibility (M2/M10).** Run KAT #3 twice (re-`sats_init` between). Assert identical `(result, cert bytes, cert_len)`. Recompute the formula+cert commits via `keccak256_oneshot` independently and assert they equal the `in_commit`/`out_commit` that `sats_emit_witness` fed to `wh_publish` (the witnessed verdict is recomputable byte-identically from recorded inputs).

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED (every fn). Avoidance: every signature in the skeleton is **single-line**; Phase 2 keeps the 12-arg `wh_publish` call as a multi-line *call* (calls may wrap; only *declarations* may not) but the `wrapper fn sats_emit_witness(req, result)` *declaration* stays single-line.
- **Trap 2 (linker-global `const`)** — EXPOSED (all consts, incl. `SATS_RIGHT_SOLVE` which duplicates `CAP_RIGHT_RESOLVE_INVOKE`'s value rather than importing the name). Avoidance: every const prefixed `SATS_`; grep confirmed no collision.
- **Trap 3 (signed-ordering SIGSEGV)** — NOT EXPOSED in trusted compares. All counters/indices/lengths are `u32`/`u64`/`u8` (unsigned). `i32` values are only status sentinels compared with `==`/`!=` (e.g. core return `r == SAT_SAT`, never `r < 0`). No `i64`/`i32` `<`/`>`/`<=`/`>=`.
- **Trap 4 (`u32`-in-`u64`-slot pointer math)** — EXPOSED in `sats_rd_u32`, `sats_clause_sat`, and the `&formula[off]` literal-span pass to the core (byte offsets are `u32` used in pointer arithmetic over `*u8`). Avoidance: mask `(off as u64) & 0xFFFFFFFFu64` before every pointer add (the `bigint.iii::big_load_u64_le` idiom); if `&formula[off] as *u32` is not clean, copy literals into a module-scope `[u32; ...]` staging array first.
- **Trap 5 (`*u32` store width)** — LOW EXPOSURE. All certificate/commit writes are **byte-wise through `*u8`** (`out_cert[i] = b`), never through a `*u32` pointer; the `n_vars` u32 prefix is emitted as 4 explicit `*u8` byte stores `(v>>(i*8))&0xFFu32`. Reads of the wire image are read-only. No `movq`-clobber risk.
- **Trap 6 (nested `/* */`)** — AVOID by construction: header block does not nest; inline notes use `//`.
- **Trap 7 (local `var` arrays)** — **WAS VIOLATED** by the gospel (`let mut assignment : [u8; 4096]` inside `sat_solve`). FIXED: hoisted to module-scope `SATS_ASSIGN : [u8; 65537]` and `SATS_CERT : [u8; 4194304]`. Non-reentrant — acceptable (single-threaded solve; `sats_solve`/`sats_verify` do not re-enter). No local `var` arrays remain.
- **Trap 8 (`} else {` split)** — AVOID: cascaded one-line `if` style throughout (`sats_verify`'s result branch is two one-line `if`s, not an `if/else`); any `else` Phase 2 adds is `} else {` on one line.
- **Trap 9 (em-dash in comment)** — AVOID: all comments use ASCII `--`, never `—`.
- **Trap 10 (`let mut x = 0u32` flag)** — LOW EXPOSURE. Sentinel loops use `u8`/`u32` flags that **drive the loop condition directly** (W14), not single-shot `u32` checkpoint flags; early-return preferred for guards (null/cap/header checks return immediately).
- **Trap 11 (`a % b` after a call)** — NOT EXPOSED. No modulo anywhere; clause offsets are computed by additive walking (`off += 4 + 4*k`), assignment indexing is direct.
- **Trap 12 (`@specialize *T` stride)** — NOT EXPOSED. No `@specialize`/generic element-width code; all arrays concretely typed (`*u8`, `[u8;N]`, `[u32;N]`).

## Gap / Fix List
STUB — the gospel body is replaced wholesale. Each defect with its fix:

1. **Fictional core entry + duplicate-symbol link collision (CRITICAL).** Gospel calls `sat_v1_solve(formula, formula_len, out_result, out_assignment)` from `sat.iii` — **no such function** (Module 15's API is `sat_init/sat_add_clause/sat_solve/sat_value/sat_n_conflicts`). Worse, the gospel **re-exports `sat_init`/`sat_solve`/`sat_verify`**, which are global symbols that **collide with Module 15's exported `sat_init`/`sat_solve`** at link (and `sat_verify` is an arbitrary new public name with no provider). **Fix:** rename this module's entire public surface with the `sats_` prefix (`sats_init/sats_solve/sats_verify/sats_verify_len`); drive the core through its **real** incremental API parsed from the wire format.

2. **No independent verifier — the module's entire reason for existing is missing (CRITICAL, M12).** `sat_verify` in the gospel just `return pt_verify(term_id)` — it never re-parses the formula or checks a clause, so it verifies *nothing* about satisfiability. The prose ("a tiny verifier that checks every clause") is unimplemented. **Fix:** implement `sats_check_model_cert` (re-parse formula bytes, assert every clause has a satisfied literal) as the SAT trust root, and `sats_check_refutation` for UNSAT; `sats_solve` re-checks the oracle's result before returning (returns `SATS_E_UNVERIFIED` on disagreement). The oracle becomes genuinely untrusted (the K_synth=0.99 claim becomes real).

3. **No certificate construction (CRITICAL, M12).** Gospel allocates a `pt_alloc`/`pt_finalize` term but never fills it with the model or a refutation — the "proof term" is empty. **Fix:** define the model certificate (`[n_vars][assign bytes]`) and the resolution-refutation certificate (antecedent-annotated derived-clause sequence ending in the empty clause), built in `SATS_CERT` and returned to the caller.

4. **Trap 7 local array + undersized buffer.** `let mut assignment : [u8; 4096]` is a local `var` array (Trap 7) and caps models at 4096 vars while the core supports 65536. **Fix:** module-scope `SATS_ASSIGN : [u8; 65537]` (= `SATS_MAX_VARS+1`).

5. **Imported-but-unused fictions / not-yet-built deps.** `ident_zero` (used now to tag the witness), `cls_dimension_get` from `cost_lattice_synth.iii` (does not exist — NOT BUILT, and was unused), and the `proof_term.iii` trio (does not exist — NOT BUILT). **Fix:** drop `proof_term.iii` and `cost_lattice_synth.iii` from the dependency set; realize the M19 bound with a plain `u64` conflict budget; keep `ident_zero` for the producer/op tags. **Flagged:** if a future spec wants the cost lattice as the budget source, that is a not-yet-built dependency to be added then.

6. **Witness chain unimplemented + W2 violation + budget ignored.** The prose's "only the verifier's transcript enters the witness chain" is absent (no witness call at all); `sat_solve` has **5 params (W2 violation)**; the `budget` argument is read but never used to bound the search (M19 unmet). **Fix:** (a) fold all args into the `SatsReq` aggregate (`sats_solve(req:*u8)` — 1 param, W2-clean); (b) `sats_emit_witness` publishes ONLY the verifier verdict (formula-commit, cert-commit, result) via the real `wh_publish` (gospel's `ws_emit_fragment` is a fiction, §3.5 #2); (c) decode `budget_conflicts` and refuse with `SATS_E_TIMEOUT` when `sat_n_conflicts()` exceeds it. **Residual not-yet-built capability:** true *mid-solve* interruption needs a Module-15 `sat_solve_budgeted(max_conflicts)` extension and the UNSAT path needs a Module-15 proof-trace/learned-clause-log export; both are flagged for the wave scheduler. The core's fixed-arena termination already guarantees M5/M19 in the absence of these (the budget is a refusal ceiling, never a brick).

7. **Capability gate missing (M8).** No privileged-access mediation despite solving being a witnessed, cost-bearing operation. **Fix:** `sats_solve` requires a `cap` carrying `SATS_RIGHT_SOLVE` (= `CAP_RIGHT_RESOLVE_INVOKE`), checked via the real `cap_verify_rights` (gospel's `cap_verify` is a fiction, §3.5 #5); the pure verifier `sats_verify` is intentionally unprivileged.

8. **keccak signature mismatch (correctness).** Any commit must call `keccak256_oneshot(msg_ptr:u64, msg_len:u64, out_ptr:u64)` (real signature; takes `u64` addresses, not `*u8`). **Fix:** callers pass `(&buf[0] as u64)`. (Confirmed by reading `keccak256.iii`; the §3.5 note's `*u8` shape is superseded by the real file.)

Mandates verified satisfied by the design: **M1** (only libc-free hand-rolled parsing + built III modules), **M2/W5** (pure byte-level deterministic verify; bit-identical trusted result), **M5** (fixed BSS, refuse-on-overflow/bad-format, never brick), **M8** (cap-gated solve), **M9** (verification is read-only/reversible; solve state lives in the recoverable Module-15 core), **M12** (independent certificate checker is the trust root — the headline mandate for this module), **M6/M10** (verifier verdict committed + witnessed, recomputable from recorded inputs), **M15** (the oracle is "oracular under M15" — its internal determinism is irrelevant because the result is re-verified), **M19** (conflict-budget ceiling; coarse pending the Module-15 budget hook). **M3/M4** are inherited from the core (the wrapper adds no heuristic; the verifier is exact).

## Implementation Skeleton
Structurally paste-ready. All signatures single-line (Trap 1). No fn bodies (Phase 2 writes those per Algorithm §). ASCII-only comments (Trap 9). No local `var` arrays (Trap 7).

```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\sat_at_scale.iii
 *
 * III STDLIB - numera::sat_at_scale
 *
 * Verified SAT at scale. The CDCL search (Module 15 numera::sat) is
 * UNTRUSTED/oracular; an independent verifier re-parses the formula
 * bytes and re-checks the result before sats_solve returns. On SAT the
 * certificate is the satisfying assignment (every clause re-evaluated);
 * on UNSAT it is a resolution refutation (every step re-derived). Only
 * the verifier verdict enters the witness chain (M6/M10/M12).
 *
 * Public API:
 *   sats_init() -> i32
 *   sats_solve(req: *u8) -> i32           (req = SatsReq aggregate; W2 fold)
 *   sats_verify(formula: *u8, formula_len: u32, result: u8, cert: *u8) -> i32
 *   sats_verify_len() -> u32
 *
 * Wire format: [magic u32 "SAT1"][n_vars u32][n_clauses u32]
 *              then per clause [k u32][k literals u32], lit=(v<<1)|sign.
 * SatsReq (56B LE): formula*8 | formula_len u32 | _pad | budget_conflicts u64
 *              | cap u64 | out_result*8 | out_cert*8 | out_cert_len*8.
 *
 * Hexad: kind_cognition.  Ring: R0.  K_synth: 0.99 (verifier is trust root).
 * Discipline: W1, W2, W8, W9, W10, W11, W12, W14, W15 (no recursion).
 *
 * NOT-YET-BUILT deps: numera/sat.iii (Module 15). See spec Gap/Fix #1,#6.
 */

module numera_sat_at_scale

/* --- BUILT dependencies (signatures verified against provider files) --- */
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

/* --- NOT-YET-BUILT dependency: Module 15 numera::sat (real incremental API) --- */
extern @abi(c-msvc-x64) fn sat_init(n_vars: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_add_clause(lits: *u32, n_lits: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_solve() -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_value(var: u32) -> u8 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_n_conflicts() -> u64 from "sat.iii"

/* --- Outcomes / errors (W9 negative) --- */
const SATS_OK            : i32 =  0i32
const SATS_SAT           : i32 =  1i32
const SATS_UNSAT         : i32 =  2i32
const SATS_E_NULL        : i32 = -1i32
const SATS_E_TIMEOUT     : i32 = -2i32
const SATS_E_NOT_INITED  : i32 = -3i32
const SATS_E_BADFMT      : i32 = -4i32
const SATS_E_TOO_BIG     : i32 = -5i32
const SATS_E_DENIED      : i32 = -6i32
const SATS_E_UNVERIFIED  : i32 = -7i32
const SATS_E_CORE        : i32 = -8i32

/* --- Bounds / format constants (W8) --- */
const SATS_MAGIC         : u32 = 0x53415431u32
const SATS_MAX_VARS      : u32 = 65536u32
const SATS_MAX_CLAUSES   : u32 = 262144u32
const SATS_MAX_FORMULA   : u32 = 16777216u32
const SATS_MAX_CERT      : u32 = 4194304u32
const SATS_ASSIGN_BYTES  : u32 = 65537u32
const SATS_HDR_BYTES     : u32 = 12u32
const SATS_RIGHT_SOLVE   : u64 = 0x00010000u64
const SATS_DEFAULT_BUDGET : u64 = 4294967296u64

/* --- Model / assignment scratch (hoisted from local var; Trap 7 fix) --- */
var SATS_ASSIGN    : [u8; 65537]

/* --- Certificate staging (model or serialized refutation) --- */
var SATS_CERT      : [u8; 4194304]
var SATS_CERT_LEN  : u32 = 0u32

/* --- Commit + witness tags --- */
var SATS_FORM_COMMIT : [u8; 32]
var SATS_CERT_COMMIT : [u8; 32]
var SATS_PRODUCER    : [u8; 32]
var SATS_OPID        : [u8; 32]
var SATS_LAST_FRAG   : [u8; 32]

/* --- Parsed-header cache (non-reentrant; single-threaded) --- */
var SATS_HDR_NVARS   : u32 = 0u32
var SATS_HDR_NCLS    : u32 = 0u32
var SATS_INITED      : u8  = 0u8

/* --- Lifecycle --- */
fn sats_init() -> i32 @export {
    // TODO: body per Algorithm (idempotent; seed PRODUCER via ident_zero, OPID bytes; INITED=1).
}

/* --- Wire-format readers (Trap 4: mask offsets before *u8 pointer math) --- */
fn sats_rd_u32(base: *u8, off: u32) -> u32 {
    // TODO: body per Algorithm (LE 4-byte load; mask (off as u64)&0xFFFFFFFFu64).
}

fn sats_rd_clause_count(formula: *u8, formula_len: u32) -> u32 {
    // TODO: body per Algorithm (return n_clauses from header).
}

fn sats_parse_header(formula: *u8, formula_len: u32) -> i32 {
    // TODO: body per Algorithm (check magic/bounds; structural clause-fits pass; cache SATS_HDR_*).
}

/* --- Core loading (real Module-15 incremental API) --- */
fn sats_load_into_core(formula: *u8, formula_len: u32) -> i32 {
    // TODO: body per Algorithm (sat_init; per-clause sat_add_clause; W11 == status checks).
}

/* --- Independent verifier: the trust root (M12) --- */
fn sats_lit_sat(lit: u32, assign: *u8, n_vars: u32) -> u8 {
    // TODO: body per Algorithm (literal truth under assignment; unsigned compares).
}

fn sats_clause_sat(formula: *u8, ci: u32, assign: *u8) -> u8 {
    // TODO: body per Algorithm (walk to clause ci; OR-reduce sats_lit_sat; W14 no-break).
}

fn sats_check_model_cert(formula: *u8, formula_len: u32, cert: *u8) -> i32 {
    // TODO: body per Algorithm (re-parse header; assert EVERY clause satisfied; W15 no recursion).
}

fn sats_check_refutation(formula: *u8, formula_len: u32, cert: *u8) -> i32 {
    // TODO: body per Algorithm (re-derive each resolution step to empty clause; explicit index table).
}

/* --- Certificate construction --- */
fn sats_build_model_cert(out_cert: *u8) -> u32 {
    // TODO: body per Algorithm (write n_vars u32 LE + assign bytes; byte-wise *u8 stores, Trap 5).
}

/* --- Content-address commit + witness (only the verdict is witnessed) --- */
fn sats_commit(buf: *u8, len: u32, out32: *u8) -> i32 {
    // TODO: body per Algorithm (keccak256_oneshot with u64 addresses).
}

fn sats_emit_witness(req: *u8, result: u8) -> i32 {
    // TODO: body per Algorithm (commit formula+cert; wh_publish verdict; copy frag id to out_frag_id).
}

/* --- Top-level verified solve (W2: single aggregate param) --- */
fn sats_solve(req: *u8) -> i32 @export {
    // TODO: body per Algorithm (INITED; null/cap gate; parse; load; budgeted sat_solve;
    //       build cert; RE-VERIFY before trusting; emit witness; SATS_OK).
}

/* --- Public independent verifier (unprivileged, no witness) --- */
fn sats_verify(formula: *u8, formula_len: u32, result: u8, cert: *u8) -> i32 @export {
    // TODO: body per Algorithm (result==1 -> check model; result==0 -> check refutation; else BADFMT).
}

fn sats_verify_len() -> u32 @export { return SATS_CERT_LEN }
```
