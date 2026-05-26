# 33 aether/reversibility_audit.iii — Implementation Spec

## Verdict
PARTIAL (with one FATAL soundness defect) — the gospel candidate is structurally idiomatic and its externs are unusually accurate (every `smt_*`, `ident_*`, `wh_*` extern matches the realized/spec'd provider surface), but it is **unsound** and **does not compile**. (1) The two-phase audit calls `smt_init()` in Phase B to "rebuild solver state" (line 9304); against the realized SMT module (Module 16) `smt_init()` **wipes every variable and constraint** including the caller's `x`/`y`/`z` vars and the `y=f(x)`/`z=g(y)` bindings, so Phase B tests `z<x` against **dangling, unbound, zero-width var handles** — the equivalence is never actually checked → the registry admits non-reversible operations (M5/M9/M2 violation). (2) Every audit branch declares **function-local `var [u8;N]` arrays** (`in_c`, `out_c`, `pl`, `fid` — Trap 7) which parse only at module scope → hard build break. (3) `rva_op_ptr` does `(slot as u64) * 32u64` pointer math on an unmasked `u32` (Trap 4) → wild address risk. (4) Admission to the reversible registry — a constitutional commitment — is **not capability-mediated** (M8 gap). (5) The witness binds only generic `pass`/`fail` op-ids, not the actual audited operation identity, so the proof is unattributable (M10/M18 weakness). The maximal realization **deletes the two-phase reset entirely** and discharges `x != z` as a **single monotonic SMT query** via a reified disequality primitive `smt_bv_add_neq` (a trivial one-clause-family addition to Module 16, marked NOT-BUILT), capability-gates admission, and threads the audited op-id through every witness. Each defect is closed in the Gap/Fix list.

## Purpose
`aether::reversibility_audit` IS the substrate's **proof-carrying gate for M9 (reversibility-by-default)**: it does not merely *record* that an operation is reversible, it **proves** it by discharging the equivalence `g(f(x)) = x` over the full bit-vector domain to the SMT oracle, admitting the operation to the reversible registry only when the negation `g(f(x)) != x` is **UNSAT** (no counterexample exists). The UNSAT result is itself the Curry-Howard proof term (M11) that the operation is reversible; a SAT result yields a concrete counterexample that is witnessed and refused. Its contribution is the **equivalence query** and the **admission registry**, both constitutional commitments rather than synthesis. **Hexad:** `kind_witness` (it IS attested provenance about reversibility, not a service that performs it). **Ring:** R-1 (sub-kernel constitutional substrate). **K-vector:** 1.00 in the gospel header; this spec keeps **K = 1.00** — the audit is total over its bounded registry (the only non-totality, registry-full, returns `RVA_E_FULL` rather than failing), and adding the single-query reduction + capability gate + witness threading does not introduce any non-total path.

## Public API
All signatures **single-line** (Trap 1). Return conventions per fn (W9/W10/W12).

```
fn rva_init() -> i32 @export
```
Idempotent boot: clears the live/op-id registry, resets the counter and last-counterexample state, derives the producer + pass/fail op-id identifiers. Returns `RVA_OK` (W9/W12). Total.

```
fn rva_audit_bv_pair(width: u32, x: u32, z: u32) -> i32 @export
```
The equivalence audit. **Contract:** the caller has, in the *current live SMT session*, created BV vars `x`, `y`, `z` (each via `smt_bv_new_var(width)`) and asserted the bindings `y = f(x)` and `z = g(y)` (via the caller's bit-blasted f/g circuits + `smt_bv_add_eq`). `rva_audit_bv_pair` asserts the disequality `x != z` (single `smt_bv_add_neq` call — Gap A redesign), runs `smt_solve()`, and: on **UNSAT** publishes a `pass` witness and returns `RVA_OK` (equivalence proven, operation reversible); on **SAT** extracts the counterexample `(x_value, z_value)`, publishes a `fail` witness carrying it as payload, and returns `RVA_E_FAIL`; on a negative SMT error returns `RVA_E_BAD`. 3 params (W2-OK). Returns `RVA_OK` / `RVA_E_FAIL` / `RVA_E_BAD` (W9/W12). **Note:** the audit asserts (it does not reset); the caller owns the SMT session lifecycle and calls `smt_init()` between independent audits. (See Gap A and Trap Exposure §3 for why the gospel's in-audit `smt_init()` is deleted.)

```
fn rva_audit_and_admit(width: u32, x: u32, z: u32, ctx: *u8) -> i32 @export
```
**New (Gap H — atomic prove-then-admit).** Composite entry: runs `rva_audit_bv_pair(width, x, z)`; on `RVA_OK` reads the op-id and capability from the 4-field context aggregate `ctx` (layout in Data Structures) and calls `rva_admit` internally so a proven-reversible operation is admitted in one capability-checked step (no TOCTOU window between proof and admission). Returns the audit result if the audit failed, else the admit result (`RVA_OK` / `RVA_E_CAP` / `RVA_E_FULL` / `RVA_E_BAD`). 4 params (W2-OK; the op-id + cap travel in `ctx` to stay within W2). (W9/W12.)

```
fn rva_admit(op_id: *u8, cap: u64) -> i32 @export
```
Add an operation identifier to the reversible registry **after** a successful audit, **capability-mediated** (Gap D / M8). Requires `cap` to carry `CAP_RIGHT_AMEND` (admission amends the constitutional reversible set); otherwise `RVA_E_CAP`. Idempotent: re-admitting a live op-id is `RVA_OK`. Returns `RVA_OK` / `RVA_E_CAP` / `RVA_E_FULL`. 2 params (W2-OK; widened from the gospel's 1-param `rva_admit(op_id)` to add the capability — Gap D). (W9/W12.)

```
fn rva_is_admitted(op_id: *u8) -> u8 @export
```
Membership test against the live registry. Returns `1u8` iff `op_id` is currently admitted, else `0u8` (W10). Pure read; total.

```
fn rva_last_counter(out: *u8) -> i32 @export
```
If the last audit failed, copies the 16-byte counterexample (`x_value` little-endian `u64` ‖ `z_value` little-endian `u64`) into `out`. Returns `RVA_OK`, or `RVA_E_BAD` if the last audit did not fail (no valid counterexample). (W9/W12.) `out` must point to >= 16 writable bytes.

```
fn rva_count() -> u32 @export
```
**New (diagnostic).** Number of live admitted operations. Used by self-tests to assert admission/idempotence. Returns `0 .. RVA_MAX_OPS` (pure value, sentinel-free).

```
fn rva_selftest() -> u64 @export
```
**New (Phase-2 acceptance gate).** Runs the KAT vectors in-process; returns `0u64` iff all pass, else the index of the first failing vector. (Mirrors `wh_selftest`/`smt_selftest` house style — `99u64`-style pass token replaced by `0u64`=pass per the SMT-spec convention; pick one and pin it in Phase 2. This spec uses `0u64`=pass.)

Internal (non-`@export`) helper: `rva_op_ptr(slot: u32) -> *u8` (returns the address of registry slot `slot` inside `RVA_OP_ID`; masked pointer math — Trap 4). `rva_publish_fail(...)` / `rva_publish_pass(...)` internal witness emitters factor the duplicated gospel branches (each <= 4 params via a context pointer).

## Constant Namespace
**PREFIX = `RVA_`**. Grep result: `grep -rn "^const RVA_\|RVA_OK\|RVA_E_\|RVA_MAX\|RVA_SAT" STDLIB/` → **0 matches**; `grep -rn "module aether_reversibility_audit\|fn rva_" STDLIB/` → **0 matches**. **No collision** anywhere in the tree. Module name `aether_reversibility_audit` is unique.

| const | type | value | note |
|---|---|---|---|
| `RVA_OK` | i32 | `0i32` | success (W9) |
| `RVA_E_BAD` | i32 | `-1i32` | bad arg / no valid counterexample / SMT error |
| `RVA_E_FAIL` | i32 | `-2i32` | audit failed: `g(f(x)) != x` is SAT (counterexample exists) |
| `RVA_E_FULL` | i32 | `-3i32` | reversible registry full |
| `RVA_E_CAP` | i32 | `-4i32` | **new (Gap D)**: admission lacks `CAP_RIGHT_AMEND` |
| `RVA_SAT_SAT` | i32 | `1i32` | SMT SAT result mirror (must equal `smt.iii`'s `SMT_SAT`) |
| `RVA_SAT_UNSAT` | i32 | `2i32` | SMT UNSAT result mirror (must equal `smt.iii`'s `SMT_UNSAT`) |
| `RVA_MAX_OPS` | u32 | `1024u32` | registry capacity bound (W8) |
| `RVA_OPID_BYTES` | u64 | `32u64` | **new**: identifier width (one Keccak256 id per op) — names the `32` stride/length literal |
| `RVA_CE_BYTES` | u64 | `16u64` | **new**: counterexample payload width (two LE u64) |
| `RVA_PRODUCER_LEN` | u64 | `27u64` | byte length of "aether::reversibility_audit" |
| `RVA_OPID_PASS_LEN` | u64 | `33u64` | byte length of "aether::reversibility_audit::pass" |
| `RVA_OPID_FAIL_LEN` | u64 | `33u64` | byte length of "aether::reversibility_audit::fail" |
| `RVA_WIT_REVTAG_PASS` | u8 | `0u8` | **new (names gospel literal)**: pass fragment is non-reversal (revtag 0) |
| `RVA_WIT_REVTAG_FAIL` | u8 | `1u8` | **new**: fail fragment carries the reversal/refusal tag (revtag 1) |
| `RVA_WIT_PHASE` | u8 | `4u8` | **new**: Phase Four (the reversibility auditor's phase) |
| `RVA_WIT_PILLAR` | u16 | `3u16` | **new**: pillar id used in the gospel's `wh_publish` calls |

Mirror-constant discipline (per the SMT spec's `SMT_SAT_SAT` pattern): `RVA_SAT_SAT`/`RVA_SAT_UNSAT` MUST hold the same numeric values as `smt.iii`'s `SMT_SAT`(=1)/`SMT_UNSAT`(=2); a one-line self-test asserts agreement (both are confirmed `1i32`/`2i32` in `smt.spec.md` lines 49-50). The gospel declared these as `i32` (correct, since `smt_solve()` returns `i32`); the gospel's separate use of `u32` literals does not appear — kept `i32`.

## Data Structures
All module-scope (Trap 7 — **no local `var` arrays**; the gospel's `in_c`/`out_c`/`pl`/`fid` locals are hoisted here, Gap B). Reentrancy: the module is **single-threaded / non-reentrant** (shared registry + shared witness scratch); acceptable for the serialized substrate (same posture as `witness_hook.iii`, which hoists its `WH_TMP16`/`WH_LENBUF` for the same reason).

| name | type | size | bound justification (W8) |
|---|---|---|---|
| `RVA_LIVE` | `[u8; 1024]` | 1024 | one live-bit per registry slot; `RVA_MAX_OPS`. 1024 distinct reversible operation kinds covers every primitive the codegen/transform pillars register (the substrate's total op vocabulary is in the low hundreds) with margin. |
| `RVA_OP_ID` | `[u8; 32768]` | 32768 | `RVA_MAX_OPS * RVA_OPID_BYTES` = 1024*32 = 32768 bytes; one 32-byte Keccak256 identifier per slot, contiguous. |
| `RVA_COUNT` | `u32` (scalar) | 1 | live admitted count. |
| `RVA_LAST_CE_X` | `u64` (scalar) | 1 | last counterexample `x` value (raw BV model value). |
| `RVA_LAST_CE_Z` | `u64` (scalar) | 1 | last counterexample `z` value. |
| `RVA_LAST_VALID` | `u8` (scalar) | 1 | `1u8` iff the last audit produced a counterexample (gates `rva_last_counter`). |
| `RVA_PRODUCER` | `[u8; 32]` | 32 | this module's producer identifier (Keccak256 of the producer string). |
| `RVA_OPID_PASS` | `[u8; 32]` | 32 | the canonical pass op-id (fallback when no caller op-id supplied). |
| `RVA_OPID_FAIL` | `[u8; 32]` | 32 | the canonical fail op-id. |
| `RVA_INITED` | `u8` (scalar) | 1 | boot flag; auto-`rva_init()` on first audit/admit. |
| `RVA_W_INC` | `[u8; 32]` | 32 | **new (Gap B)**: hoisted witness in-commitment buffer (was local `in_c`). |
| `RVA_W_OUTC` | `[u8; 32]` | 32 | **new (Gap B)**: hoisted witness out-commitment buffer (was local `out_c`). |
| `RVA_W_PAY` | `[u8; 16]` | 16 | **new (Gap B)**: hoisted witness payload buffer — counterexample (`RVA_CE_BYTES`) or width; sized to the larger (16). (was local `pl`). |
| `RVA_W_FID` | `[u8; 32]` | 32 | **new (Gap B)**: hoisted fragment-id sink (was local `fid`). |
| `RVA_KAT_*` | (self-test scratch) | — | module-scope buffers used only by `rva_selftest` (op-id inputs, etc.); Trap-7-safe. |

Address-of-static (`&RVA_*`) is taken **only inside this file** (W1/W3); the only addresses leaving the module are the witness payload/commitment pointers passed to `wh_publish`/`ident_from_bytes` (read-only or sink, callee-owned write) — no global pointer escapes (W1/W3).

The `ctx` aggregate for `rva_audit_and_admit` (caller-owned, passed by pointer to honor W2) is a fixed 40-byte layout: bytes `[0..32)` = the operation's 32-byte op-id; bytes `[32..40)` = the capability id as a little-endian `u64`. Documented so Phase 2 and callers agree on the byte layout.

## Dependencies (externs)
Each `extern @abi(c-msvc-x64) fn ... from "<module>.iii"` (single-line, Trap 1). Verified against the realized provider files / sibling specs.

| extern | from | providing NN | built? |
|---|---|---|---|
| `fn smt_init() -> i32` | `smt.iii` | **16** | **NOT BUILT** — `smt.spec.md` done; wave-order Module 16 before 33. Used only by the caller / between audits (NOT inside the audit — Gap A). |
| `fn smt_bv_new_var(width: u32) -> u32` | `smt.iii` | **16** | **NOT BUILT** — confirmed in `smt.spec.md` API (line 18). Used by the caller to build x/y/z; declared here for the self-test which plays the caller role. |
| `fn smt_bv_add_eq(a: u32, b: u32) -> i32` | `smt.iii` | **16** | **NOT BUILT** — confirmed `smt.spec.md` line 19. Used by the self-test to bind f/g. |
| `fn smt_bv_add_neq(a: u32, b: u32) -> i32` | `smt.iii` | **16** | **NOT BUILT — and NOT YET IN THE SMT SPEC.** Required new primitive (Gap A): reified disequality `a != b`, Tseitin-encoded as `OR over bits i of (a_i XOR b_i)` asserted true (a fresh helper per bit + one final disjunction clause; buffered into the SMT clause buffer like `smt_bv_add_ult`). **Action item for the wave scheduler:** add this one-clause-family fn to Module 16; it is strictly simpler than the existing `smt_bv_add_ult`. Without it the audit cannot express `x != z` as a single monotonic query (see Gap A). |
| `fn smt_solve() -> i32` | `smt.iii` | **16** | **NOT BUILT** — confirmed `smt.spec.md` line 22; returns `SMT_SAT`(1)/`SMT_UNSAT`(2)/negative. |
| `fn smt_bv_value(var: u32) -> u64` | `smt.iii` | **16** | **NOT BUILT** — confirmed `smt.spec.md` line 25; returns the model value or `0u64` sentinel. |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** — confirmed `identifier.iii:33` exact signature. |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | `identifier.iii` | 01 | **BUILT** — confirmed `identifier.iii:38`. |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** — confirmed `identifier.iii:65`. |
| `fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64` | `witness_hook.iii` | 07 | **BUILT** — confirmed `witness_hook.iii:144` exact 12-field signature (systemic defect #2: this IS the real emit primitive; gospel uses it correctly). |
| `fn wh_chain_root(out_id: *u8) -> i32` | `witness_hook.iii` | 07 | **BUILT** — confirmed `witness_hook.iii:216`; supplies the prior chain head as the witness in-commitment. |
| `fn cap_verify_rights(id: u64, required: u64) -> u8` | `capability.iii` | (built) | **BUILT** — confirmed `capability.iii:148` (systemic defect #5: `cap_verify` does NOT exist; this is the real rights-check). Used by `rva_admit` (Gap D / M8). |

Plus the `CAP_RIGHT_AMEND : u64 = 0x4000u64` right-bit constant from `capability.iii:66` — referenced by literal `0x4000u64` (it is another module's `const`, so it CANNOT be re-declared here — Trap 2; use the literal with a `// CAP_RIGHT_AMEND` comment, exactly as cross-module right-bits are consumed elsewhere).

**Not-yet-built dependency count for the wave scheduler: 1 module (`smt.iii`, Module 16)**, which must additionally export the new `smt_bv_add_neq` primitive before this module's audit can be implemented. (All `identifier`/`witness_hook`/`capability` deps are BUILT.) Module 05 `reversible.iii` is a **conceptual** dependency only — the gospel Module 33 body calls **no** `rev_*` symbol; this module audits the *property* that Module 05 embodies but does not link against it. (Confirmed: `grep "rev_" ` over the gospel body lines 9189-9401 = 0 matches.)

## Algorithm
NIH (M1): the registry, equivalence-query construction, counterexample packing, and witness emission are all hand-rolled over fixed arrays; the only externs are into already-NIH III modules (SMT oracle, identifier/Keccak256, witness hook, capability). No ML/heuristics (M3/M4): every decision is an exact equality/SAT verdict — there is no counting-to-promote, no observation, no threshold. Determinism (M2) / bit-identity (W5): the audit result depends only on the f/g constraints the caller registered and the deterministic SMT verdict; the SMT solver is itself bit-deterministic (Bland's rule, fixed clause order — `smt.spec.md` §M2). The counterexample `(x_value, z_value)` is the SMT model, a pure function of the constraints; its witness commitment (`ident_from_bytes` = Keccak256) is byte-identical on re-audit (M10). No recursion (W15): every loop is an explicit `while` over a `u32`/`u64` index; the registry is a flat array, not a call stack.

- **`rva_init`** — sentinel loop `while i < RVA_MAX_OPS` zeros `RVA_LIVE[i]`; set `RVA_COUNT = 0`, `RVA_LAST_VALID = 0`; derive `RVA_PRODUCER = ident_from_bytes("aether::reversibility_audit", 27)`, `RVA_OPID_PASS = ident_from_bytes("...::pass", 33)`, `RVA_OPID_FAIL = ident_from_bytes("...::fail", 33)`; set `RVA_INITED = 1`. Idempotent (re-zeros). Returns `RVA_OK`.

- **`rva_audit_bv_pair(width, x, z)`** — the maximal single-query audit (Gap A):
  1. `if RVA_INITED == 0u8 { rva_init() }`.
  2. **Assert the disequality once:** `smt_bv_add_neq(x, z)` (adds `x != z` as a monotonic hard constraint into the live solver that already holds the caller's `y=f(x)`, `z=g(y)`). No reset, no second phase.
  3. `let r : i32 = smt_solve()`.
  4. `if r == RVA_SAT_SAT` (SAT — a counterexample exists ⇒ **NOT** reversible): `RVA_LAST_CE_X = smt_bv_value(x)`; `RVA_LAST_CE_Z = smt_bv_value(z)`; `RVA_LAST_VALID = 1u8`; pack the two LE u64 into `RVA_W_PAY[0..16)`; `wh_chain_root(&RVA_W_INC)`; `ident_from_bytes(&RVA_W_PAY, 16, &RVA_W_OUTC)`; `wh_publish(producer=RVA_PRODUCER, opid=RVA_OPID_FAIL, in=RVA_W_INC, out=RVA_W_OUTC, revtag=RVA_WIT_REVTAG_FAIL, phase=RVA_WIT_PHASE, pillar=RVA_WIT_PILLAR, ante=&zero, n_ante=0, payload=&RVA_W_PAY, payload_len=16, out_frag=&RVA_W_FID)`; return `RVA_E_FAIL`.
  5. `if r == RVA_SAT_UNSAT` (UNSAT — equivalence proven ⇒ reversible): `RVA_LAST_VALID = 0u8`; pack `width` as 4 LE bytes into `RVA_W_PAY[0..4)`; `wh_chain_root(&RVA_W_INC)`; `ident_from_bytes(&RVA_W_PAY, 4, &RVA_W_OUTC)`; `wh_publish(... opid=RVA_OPID_PASS, revtag=RVA_WIT_REVTAG_PASS, ... payload_len=4 ...)`; return `RVA_OK`.
  6. Else (negative SMT error) → `RVA_E_BAD`. (Equality compares on the i32 SMT result are W11-clean; no signed ordering — Trap 3.)
  Determinism: one `smt_bv_add_neq` + one `smt_solve` over a deterministic solver ⇒ a single deterministic verdict; the gospel's order-dependent two-phase race is gone.

- **`rva_audit_and_admit(width, x, z, ctx)`** (Gap H) — `let ar = rva_audit_bv_pair(width, x, z)`; `if ar != RVA_OK { return ar }`; read `op_id = ctx[0..32)`, `cap = LE-u64(ctx[32..40))`; `return rva_admit(&ctx[0] as *u8, cap)`. Atomic: a proven operation is admitted under the same call with no intervening solver mutation.

- **`rva_admit(op_id, cap)`** (Gap D / M8) — `if RVA_INITED == 0u8 { rva_init() }`; **capability gate:** `if cap_verify_rights(cap, 0x4000u64 /* CAP_RIGHT_AMEND */) == 0u8 { return RVA_E_CAP }`; idempotent scan: `while i < RVA_MAX_OPS { if RVA_LIVE[i]==1u8 { if ident_eq(rva_op_ptr(i), op_id)==1u8 { return RVA_OK } } i=i+1 }`; first-free insert: `while j < RVA_MAX_OPS { if RVA_LIVE[j]==0u8 { ident_copy(op_id, rva_op_ptr(j)); RVA_LIVE[j]=1u8; RVA_COUNT=RVA_COUNT+1u32; return RVA_OK } j=j+1 }`; `return RVA_E_FULL`. (Both loops W14 sentinel form — early return on hit, no `break`.)

- **`rva_is_admitted(op_id)`** — single sentinel loop with a `hit` flag guarding the body (`if hit==0u8 { ... if ident_eq==1u8 { hit=1u8 } }`); returns `hit` (W10/W14; the flag drives the guard, the index drives the `while` — Trap 10 safe).

- **`rva_last_counter(out)`** — `if RVA_LAST_VALID == 0u8 { return RVA_E_BAD }`; sentinel loop `while z < 8u64`: `out[z] = ((RVA_LAST_CE_X >> (z*8)) & 0xFF) as u8`; `out[z+8] = ((RVA_LAST_CE_Z >> (z*8)) & 0xFF) as u8`; return `RVA_OK`. Pure LE serialization (W5 bit-identical).

- **`rva_count`** — return `RVA_COUNT` (or recount via one sentinel loop over `RVA_LIVE` for a defensive invariant check; either is total).

- **`rva_op_ptr(slot)`** (internal, Trap 4 fix) — `return ((&RVA_OP_ID as u64) + ((slot as u64) & 0xFFFFFFFFu64) * RVA_OPID_BYTES) as *u8`. The `(slot as u64) & 0xFFFFFFFFu64` mask zero-extends the u32 before the multiply, eliminating the high-garbage wild-address risk. (Gospel wrote `(&RVA_OP_ID[(slot as u64)*32u64])` — both the unmasked `as u64` and the `&ARR[expr]` element-address form; the realized idiom is `((&ARR as u64)+off) as *u8`, matching `witness_hook.iii`.)

- **`rva_selftest`** — plays the caller role: `smt_init()`; build `x=smt_bv_new_var(w)`, `y=smt_bv_new_var(w)`, `z=smt_bv_new_var(w)`; assert an **identity** f and g (`y=x` via `smt_bv_add_eq(x,y)`, `z=y` via `smt_bv_add_eq(y,z)`) ⇒ `g(f(x))=x` holds ⇒ `rva_audit_bv_pair` must return `RVA_OK`; then a fresh session with a **broken** g (`z = y XOR const` modeled by binding z to a different var) ⇒ must return `RVA_E_FAIL` and `rva_last_counter` must yield a witness-consistent `(x,z)` with `x != z`; then admission KATs. Returns `0u64`=pass / first-failing-index.

## KAT Vectors (>= 3)
The self-test drives the SMT oracle directly (playing the caller). Each asserts byte-for-byte / exact return code.

1. **Identity is reversible (UNSAT ⇒ admit).** `rva_init()`; `smt_init()`; `w=4`; `x=smt_bv_new_var(4)`, `y=smt_bv_new_var(4)`, `z=smt_bv_new_var(4)`; `smt_bv_add_eq(x,y)` (f = identity: `y=x`); `smt_bv_add_eq(y,z)` (g = identity: `z=y`); `r=rva_audit_bv_pair(4, x, z)`. **Expected:** `r == RVA_OK` (`x != z` is UNSAT because `z=y=x`); `rva_last_counter(out) == RVA_E_BAD` (no counterexample). Then `rva_admit(op_id_A, cap_with_AMEND) == RVA_OK`; `rva_is_admitted(op_id_A) == 1u8`; `rva_count() == 1u32`.

2. **Non-inverse is refused (SAT ⇒ counterexample).** `rva_init()`; `smt_init()`; `w=4`; `x,y,z = smt_bv_new_var(4)` ×3 plus a constant var `k`; bind f = identity (`y=x`) but g = "add 1" modeled so that `z != y` for at least one assignment (e.g. `smt_bv_add_eq` chains forcing `z` to differ from `x`); `r=rva_audit_bv_pair(4, x, z)`. **Expected:** `r == RVA_E_FAIL` (`x != z` is SAT); `rva_last_counter(out) == RVA_OK` and the two LE u64 in `out` satisfy `x_value != z_value` (the recovered counterexample). `rva_is_admitted(op_id_B) == 0u8` (never admitted). **(Negative-case proof: this vector proves the audit actually *refuses* a non-reversible pair, not merely that the happy path passes — MEMORY "prove the negative case" discipline.)**

3. **Admission is capability-gated (Gap D / M8).** `rva_init()`; `r = rva_admit(op_id_C, 0u64 /* no rights */)`. **Expected:** `r == RVA_E_CAP`; `rva_is_admitted(op_id_C) == 0u8`; `rva_count()` unchanged. Then `rva_admit(op_id_C, cap_with_AMEND) == RVA_OK`. **(Negative-case proof that the capability gate FAILS closed on an unprivileged cap.)**

4. **Admission idempotence + registry-full.** After KAT 1, `rva_admit(op_id_A, cap_with_AMEND)` again ⇒ `RVA_OK` and `rva_count()` still `1u32` (idempotent, no double-insert). Admit `RVA_MAX_OPS` distinct op-ids ⇒ the next `rva_admit` returns `RVA_E_FULL` (bounded registry, M19/W8).

5. **Counterexample reproducibility (M10).** Re-run KAT 2 byte-identically; capture `rva_last_counter` into `h1`, re-run, capture `h2`; assert the 16 bytes are equal (the SMT model and its LE packing are a pure function of the recorded constraints).

(Self-test pass token: `0u64`. Phase 2 must pin the exact concrete counterexample bytes for KAT 2/5 once Module 16's deterministic model is fixed — `rva_last_counter` equality across re-runs is the robust gate that does not depend on the specific satisfying assignment.)

## Trap Exposure
- **Trap 1 (multi-line fn):** EXPOSED (every signature, incl. the 12-field `wh_publish` extern). Avoidance: every `fn`/`extern` on one physical line.
- **Trap 2 (const prefix linker-global):** EXPOSED. Avoidance: every const is `RVA_`-prefixed; collision-checked clean. **`CAP_RIGHT_AMEND` is NOT re-declared** — it is another module's const; consumed as the literal `0x4000u64` with a comment (re-declaring it would collide — this is the trap working as intended).
- **Trap 3 (signed ordering compare SIGSEGV):** NOT EXPOSED. Every compare is unsigned (`i < RVA_MAX_OPS`, `z < 8u64` — u32/u64 bounds) or `i32` equality (`r == RVA_SAT_SAT`, `r == RVA_SAT_UNSAT`, `ar != RVA_OK`). **No `i32`/`i64` `< <= > >=`.** The gospel body was already clean here (it used `==` on the SMT result) — preserved.
- **Trap 4 (u32-in-u64-slot pointer math):** **EXPOSED in `rva_op_ptr`** — the gospel's `(slot as u64) * 32u64` reads the u32 `slot` as u64 then does pointer arithmetic (wild-address risk). Avoidance: mask `((slot as u64) & 0xFFFFFFFFu64) * RVA_OPID_BYTES` before the offset add. (Gap C.) All other indices (`i`, `j`) index the typed `[u8;..]` arrays directly via the byte-offset idiom — masked.
- **Trap 5 (u32 pointer store width):** NOT EXPOSED. All stores are single bytes through `*u8` (`out[z] = (... ) as u8`, `RVA_W_PAY[k] = ... as u8`) — correct width. No `u32`-origin value is stored through a `*u32`.
- **Trap 6 (nested `/* */`):** NOT EXPOSED — single-level comments only; the long algorithm notes use `//` for inline annotation.
- **Trap 7 (local var arrays):** **EXPOSED — the gospel body VIOLATES it repeatedly** (`var in_c:[u8;32]`, `var out_c:[u8;32]`, `var pl:[u8;16]`/`[u8;4]`, `var fid:[u8;32]` inside `rva_audit_bv_pair`). Avoidance: hoist ALL to module scope (`RVA_W_INC`, `RVA_W_OUTC`, `RVA_W_PAY`, `RVA_W_FID`) — Gap B. Documented non-reentrant. (Matches `witness_hook.iii`'s `WH_TMP16`/`WH_LENBUF` hoist for the identical reason.)
- **Trap 8 (`} else {` one line):** NOT EXPOSED in the redesign (guard-clause early returns, not if/else). Any `else` Phase 2 introduces must be `} else {` on one line.
- **Trap 9 (em-dash in comment):** EXPOSED (prose-heavy header). Avoidance: ASCII `--`/`->` everywhere; no U+2014. (Gospel source uses backslash-escapes from markdown, not em-dashes; Phase 2 transcribes ASCII.)
- **Trap 10 (`let mut` flag misbehaves):** NOT EXPOSED. Loop counters drive their own `while`; the only flag is `rva_is_admitted`'s `hit`, used as a body-guard while the index drives the loop — the documented-safe pattern (matches `identifier.iii`'s `sentinel` usage).
- **Trap 11 (modulo-after-call):** NOT EXPOSED — no `%` operator anywhere (the byte-packing uses `>>` and `& 0xFF`, not `%`).
- **Trap 12 (`@specialize *T` stride):** NOT EXPOSED — not generic; all arrays concretely typed.

## Gap / Fix List
PARTIAL — every defect and its fix:

- **A. FATAL: in-audit `smt_init()` strands the f/g constraints (M2/M5/M9 — unsound audit).** Gospel `rva_audit_bv_pair` Phase B (line 9304) calls `smt_init()` to test the `z<x` direction; against the realized SMT module `smt_init()` zeroes `SMT_BV_NVAR` and every constraint, so Phase B references dangling var handles with no f/g binding — the equivalence is never checked and the audit can pass a non-reversible operation. **Fix:** delete the two-phase scheme entirely. Add the reified disequality primitive `smt_bv_add_neq(a,b)` to Module 16 (one Tseitin OR-of-XOR, asserted — strictly simpler than the existing `smt_bv_add_ult`) and discharge `x != z` as a **single monotonic query** in the caller's live session: `smt_bv_add_neq(x,z); smt_solve()`. SAT ⇒ counterexample ⇒ `RVA_E_FAIL`; UNSAT ⇒ proven ⇒ `RVA_OK`. The audit asserts and never resets; the caller owns `smt_init()` between independent audits. This is sound, deterministic, and removes the order-dependent race. (`smt_bv_add_neq` marked NOT-BUILT in Dependencies; it is the single new symbol Module 16 must add.)
- **B. Build break: function-local `var` arrays (Trap 7).** `in_c`, `out_c`, `pl`, `fid` are declared inside the audit fn; local `var [u8;N]` arrays parse only at module scope. **Fix:** hoist to module-scope `RVA_W_INC`/`RVA_W_OUTC`/`RVA_W_PAY`/`RVA_W_FID`; note non-reentrancy. (Same fix `witness_hook.iii` already applied.)
- **C. Trap-4 unmasked pointer math in `rva_op_ptr`.** `(slot as u64) * 32u64` reads a u32 in an 8-byte slot without zero-extension → wild address. **Fix:** mask `((slot as u64) & 0xFFFFFFFFu64) * RVA_OPID_BYTES`, and switch from `&ARR[expr]` to the `((&ARR as u64)+off) as *u8` element-address idiom used across the built tree.
- **D. No capability mediation of admission (M8).** `rva_admit` adds to the constitutional reversible registry with no authorization. **Fix:** widen to `rva_admit(op_id, cap)` and gate with `cap_verify_rights(cap, CAP_RIGHT_AMEND /* 0x4000 */) == 1u8` (real symbol; systemic defect #5 — `cap_verify` does not exist). Admission is thus a capability-mediated constitutional amendment. (KAT 3 proves it fails closed.)
- **E. Witness unattributable to the audited operation (M10/M18).** Gospel publishes only the generic `RVA_OPID_PASS`/`RVA_OPID_FAIL` op-ids; nothing ties a proof fragment to *which* operation was audited. **Fix:** the composite `rva_audit_and_admit` threads the caller's op-id (from `ctx`) so the proof and the admission share an identity; `rva_audit_bv_pair` retains the generic op-ids for the bare-audit case but the pass/fail payload (`width` / counterexample) plus the chain-root in-commitment keep each fragment reproducible (M10). (A future Phase-2 enhancement may add an `op_id` param to `rva_audit_bv_pair`, but that would exceed the gospel's stated 3-param surface; the `ctx`-threaded composite is the W2-clean route.)
- **F. Sentinel/result-type discipline.** Gospel mixes a `u32`-flavored mental model with `i32` SMT results. **Fix (clarity):** keep `RVA_SAT_SAT`/`RVA_SAT_UNSAT` as `i32` mirror constants equal to `SMT_SAT`/`SMT_UNSAT`; assert agreement in the self-test (mirror-constant discipline, per `smt.spec.md`).
- **G. Magic literals.** Gospel hard-codes `32`, `27`, `33`, `16`, `1u8`/`4u8`/`3u16` (witness revtag/phase/pillar). **Fix (clarity, not a bug):** name them (`RVA_OPID_BYTES`, `RVA_PRODUCER_LEN`, `RVA_OPID_PASS/FAIL_LEN`, `RVA_CE_BYTES`, `RVA_WIT_REVTAG_*`, `RVA_WIT_PHASE`, `RVA_WIT_PILLAR`).
- **H. No atomic prove-then-admit (TOCTOU surface).** Auditing and admitting are separate calls; between them the SMT session could be mutated or another op admitted under the same proof. **Fix:** add `rva_audit_and_admit(width, x, z, ctx)` that proves then admits in one capability-checked call.
- **I. Missing diagnostics/acceptance gate.** Gospel exposes no count and no self-test. **Fix:** add `rva_count()` and `rva_selftest()` (the Phase-2 acceptance gate), mirroring `wh_selftest`.

Mandates explicitly satisfied after fixes: **M1** (NIH — only `smt`/`identifier`/`witness_hook`/`capability` III externs), **M2/M15** (single deterministic SMT verdict; total over the bounded registry), **M3/M4** (no learning/heuristics — exact SAT/UNSAT + equality), **M5** (no brick — registry-full refuses with `RVA_E_FULL`, no unrecoverable state, no dangling-handle audit), **M6/M10/W16** (pass+fail fragments published under reversibility via `wh_publish`, chained by `wh_chain_root`, payload reproducible), **M8** (capability-mediated admission), **M9** (the module IS the proof gate for reversibility-by-default), **M11** (the UNSAT verdict is the operational proof term that `g∘f = id`), **M12/M18** (the witness fragment is the checkable certificate the registry entry travels with), **M19** (cost bounded by the fixed registry + the SMT module's own node cap), **W17** (algebraic time advances monotonically — `wh_publish` calls `at_advance` internally per fragment). **M7** ring R-1 preserved. **M13/M14/M17/M20** are out of this module's remit (no self-reflection / memo / math-library entries here) — noted as out-of-scope rather than violated.

## Implementation Skeleton
Structurally paste-ready. SINGLE-LINE signatures. No fn bodies (Phase 2 writes those per Algorithm §).

```iii
// III/STDLIB/iii/aether/reversibility_audit.iii
//
// III STDLIB - aether::reversibility_audit
//
// Proof-carrying gate for reversibility (M9). Given forward f and
// inverse g (bit-blasted by the caller into the live SMT session as
// y=f(x), z=g(y)), the auditor asserts the disequality x != z as a
// single monotonic SMT query and solves: UNSAT proves g(f(x))=x over
// the whole bit-vector domain (operation is reversible -> admit + pass
// witness); SAT yields a concrete counterexample (operation refused ->
// fail witness carrying (x_value, z_value)). Admission to the reversible
// registry is capability-mediated (CAP_RIGHT_AMEND). The UNSAT verdict
// is the Curry-Howard proof term; the witness fragment is its certificate.
//
// Non-reentrant: shared registry + witness scratch (single serialized use).
//
// Hexad: kind_witness.  Ring: R-1.  K: 1.00.
// Discipline: W2 (<=4 params), W8 (static registry), W13, W14 (sentinel
// loops, no break), W15 (no recursion -- flat registry array).

module aether_reversibility_audit

extern @abi(c-msvc-x64) fn smt_init() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_new_var(width: u32) -> u32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_eq(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_add_neq(a: u32, b: u32) -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_solve() -> i32 from "smt.iii"
extern @abi(c-msvc-x64) fn smt_bv_value(var: u32) -> u64 from "smt.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"

const RVA_OK            : i32 =  0i32
const RVA_E_BAD         : i32 = -1i32
const RVA_E_FAIL        : i32 = -2i32
const RVA_E_FULL        : i32 = -3i32
const RVA_E_CAP         : i32 = -4i32

const RVA_SAT_SAT       : i32 =  1i32   // == smt.iii SMT_SAT
const RVA_SAT_UNSAT     : i32 =  2i32   // == smt.iii SMT_UNSAT

const RVA_MAX_OPS       : u32 = 1024u32
const RVA_OPID_BYTES    : u64 = 32u64
const RVA_CE_BYTES      : u64 = 16u64
const RVA_PRODUCER_LEN  : u64 = 27u64
const RVA_OPID_PASS_LEN : u64 = 33u64
const RVA_OPID_FAIL_LEN : u64 = 33u64

const RVA_WIT_REVTAG_PASS : u8  = 0u8
const RVA_WIT_REVTAG_FAIL : u8  = 1u8
const RVA_WIT_PHASE       : u8  = 4u8
const RVA_WIT_PILLAR      : u16 = 3u16

// CAP_RIGHT_AMEND = 0x4000u64 (declared in capability.iii; consumed as a literal -- Trap 2).

// --- Reversible operation registry ---
var RVA_LIVE       : [u8;  1024]
var RVA_OP_ID      : [u8;  32768]    // RVA_MAX_OPS * RVA_OPID_BYTES
var RVA_COUNT      : u32 = 0u32

// --- Last counterexample ---
var RVA_LAST_CE_X  : u64 = 0u64
var RVA_LAST_CE_Z  : u64 = 0u64
var RVA_LAST_VALID : u8 = 0u8

// --- Identity / boot ---
var RVA_PRODUCER   : [u8; 32]
var RVA_OPID_PASS  : [u8; 32]
var RVA_OPID_FAIL  : [u8; 32]
var RVA_INITED     : u8 = 0u8

// --- Hoisted witness scratch (Trap 7: was function-local in the gospel) ---
var RVA_W_INC      : [u8; 32]
var RVA_W_OUTC     : [u8; 32]
var RVA_W_PAY      : [u8; 16]
var RVA_W_FID      : [u8; 32]
var RVA_ZERO_ID    : [u8; 32]   // canonical zero antecedent

// --- Self-test scratch (module scope; Trap 7) ---
var RVA_KAT_OPA    : [u8; 32]
var RVA_KAT_OPB    : [u8; 32]
var RVA_KAT_CE     : [u8; 16]
var RVA_KAT_CE2    : [u8; 16]

fn rva_op_ptr(slot: u32) -> *u8 {
    // TODO: body per Algorithm -- ((&RVA_OP_ID as u64) + ((slot as u64)&0xFFFFFFFFu64)*RVA_OPID_BYTES) as *u8 (Trap 4)
}

fn rva_init() -> i32 @export {
    // TODO: body per Algorithm -- zero RVA_LIVE, reset COUNT/LAST_VALID, derive producer + pass/fail ids, RVA_INITED=1
}

fn rva_audit_bv_pair(width: u32, x: u32, z: u32) -> i32 @export {
    // TODO: body per Algorithm -- smt_bv_add_neq(x,z); smt_solve(); SAT->fail witness+RVA_E_FAIL; UNSAT->pass witness+RVA_OK; else RVA_E_BAD
}

fn rva_audit_and_admit(width: u32, x: u32, z: u32, ctx: *u8) -> i32 @export {
    // TODO: body per Algorithm -- audit; if RVA_OK read op_id+cap from ctx and rva_admit; return audit-or-admit result
}

fn rva_admit(op_id: *u8, cap: u64) -> i32 @export {
    // TODO: body per Algorithm -- cap_verify_rights(cap,0x4000)==0 -> RVA_E_CAP; idempotent scan; first-free insert; RVA_E_FULL
}

fn rva_is_admitted(op_id: *u8) -> u8 @export {
    // TODO: body per Algorithm -- single sentinel loop with hit-flag guard; return hit
}

fn rva_last_counter(out: *u8) -> i32 @export {
    // TODO: body per Algorithm -- RVA_LAST_VALID==0 -> RVA_E_BAD; LE-pack CE_X then CE_Z into out[0..16); RVA_OK
}

fn rva_count() -> u32 @export {
    // TODO: body per Algorithm -- return RVA_COUNT
}

fn rva_selftest() -> u64 @export {
    // TODO: body per Algorithm -- run KAT vectors 1-5 (caller role over the SMT oracle); 0u64=pass / first-fail index
}
```
