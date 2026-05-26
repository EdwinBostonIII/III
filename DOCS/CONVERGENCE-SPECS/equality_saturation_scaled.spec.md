# 73 numera/equality_saturation_scaled.iii — Implementation Spec

## Verdict
STUB — the gospel candidate body (gospel lines 20041-20103) is a ~40-line skeleton
that does **not** realize its stated mission ("bound enforcement, verifier
separation under M15, explicit budget tracking through cost_lattice_synth"). It is
broken in six independent ways: (1) **every egraph extern is fiction** —
`eg_add_term / eg_add_rewrite / eg_saturate_step / eg_class_of / eg_same_class`
do **not exist** in the realized `egraph.iii` (Module 17 spec), whose actual surface
is `eg_init / eg_intern_symbol / eg_add(sym,children,n) / eg_register_rule(rule) /
eg_saturate(max_steps) / eg_find / eg_extract / eg_class_count / eg_node_count` — a
term-blob-vs-interned-symbol impedance mismatch that the candidate never bridges;
(2) **the named cost_lattice_synth integration is absent** — it reads one dimension
(`cls_dimension_get(budget,0)`) and uses it as a raw loop bound, never calling
`cls_admit` (the M19 admission gate), `cls_first_exceeded`, or `cls_emit_overrun`
(the mandated COST_OVERRUN emission) — so there is no bound *enforcement* at all,
only a counter; (3) **the M15 verifier separation is fiction** — the prose says
"the verifier transcript is what enters the chain," but the body emits **no witness
fragment** and `egs_verify_saturation` does not *replay* anything: it re-adds two
terms and checks same-class, blindly trusting the (mutable, possibly-stale) global
e-graph — violating M6/M10/M17 (memo results chain-verified, never blindly trusted);
(4) **Trap 7** — five function-local `var [u8;32]` arrays (`first_node`, `node_a`,
`node_b`, `class_a`, `class_b`) will not parse; (5) **no capability gate (M8)** —
running a scaled transform that publishes federation/witness fragments is a
privileged attest action and is ungated; (6) **`egs_verify_saturation` returns the
wrong error** (`EGS_E_BUDGET_EXCEEDED`) for a plain not-in-same-class result —
semantically meaningless. This spec realizes the **maximal** intent: a bounded
(M19), capability-gated (M8), witness-transcript-emitting (M6/M10) scaled-saturation
engine whose verifier **independently re-derives** the equivalence from recorded
inputs (M11/M12/M17), with a hand-rolled flat-preorder term-blob codec that drives
the realized egraph through interned symbols and u32 child-class vectors.

## Purpose
`numera_equality_saturation_scaled` IS the industrial-scale wrapper over the base
e-graph (Module 17): it lifts equality saturation from the small constitutional-clause
regime to problem instances with tens of thousands of e-nodes and rule sets in the
hundreds, and — crucially — it is the layer that makes a saturation result
**witnessed and re-derivable** rather than a trusted in-memory side effect. It owns
three responsibilities the base engine deliberately omits (egraph is the *mechanism*;
this module is the *certificate*): (a) **explicit budget tracking** — a saturation
run declares a `cost_lattice_synth` budget vector, the engine measures the actual
saturation cost (steps consumed, node growth), and refuses / emits a schema-conformant
`COST_OVERRUN` witness fragment when the declared bound is exceeded (M19); (b) the
**M15 verifier separation** — the saturation search is oracular (the internal
e-matching order is an implementation detail), but the engine publishes a witness
fragment binding `Keccak256(initial_terms) || Keccak256(rules) || result_class_commit`,
and `egs_verify_saturation` *independently replays* the deterministic saturation from
the recorded inputs and re-checks the equivalence — the chain trusts the *replayable
transcript*, not the search; (c) **capability mediation** — a scaled run is gated on
`CAP_RIGHT_TRANSFORM_RUN`. **Hexad: kind_cognition. Ring: R0. K_synth: 0.95. K: 0.99.**

## Public API
All public functions return a status `i32` (W9/W12: negative = error,
`EGS_OK == 0` otherwise) or a sentinel-typed `u64`. Every signature is single-line
(Trap 1). No function exceeds 4 params (W2); the multi-input saturation entry passes
a request aggregate by pointer.

```
fn egs_init() -> i32 @export
fn egs_saturate(req: *u64) -> i32 @export
fn egs_verify_saturation(vreq: *u64) -> u8 @export
fn egs_result_class(out_class_id: *u8) -> i32 @export
fn egs_last_steps() -> u64 @export
fn egs_last_overrun_dim() -> u32 @export
fn egs_node_count() -> u64 @export
fn egs_selftest() -> u64 @export
```

Return-status convention per fn:
- `egs_init` → `EGS_OK`. Idempotent (re-init re-seeds identically, M9): zeroes the
  module's scratch, seeds the producer/opid witness ids, sets `EGS_INITED = 1`, and
  calls `eg_init()`. Total.
- `egs_saturate(req: *u64)` → `EGS_OK` on a completed, in-budget saturation with the
  result class id written into the caller's `out_class_id` buffer; `EGS_E_NOT_INITED`
  if `egs_init` was not called; `EGS_E_NULL` on a null `req` or any null pointer cell;
  `EGS_E_CAP` if `cap_verify_rights(cap, CAP_RIGHT_TRANSFORM_RUN) != 1`;
  `EGS_E_BUDGET_EXCEEDED` if the measured saturation cost exceeds the declared budget
  (a `COST_OVERRUN` fragment is published and `egs_last_overrun_dim()` names the
  violated dimension); `EGS_E_TERM` on a malformed term/rule blob;
  `EGS_E_GRAPH` if the e-graph rejects an add/rule (table/arena overflow);
  `EGS_E_EMIT` if the witness publish fails. The `req` aggregate (see below) replaces
  the gospel's 6-parameter `egs_saturate` (W2 violation).
- `egs_verify_saturation(vreq: *u64)` → `1u8` iff the two terms named in `vreq` are
  provably in the same equivalence class **under an independently replayed
  saturation** of the recorded `(initial_terms, rules, budget)`; `0u8` otherwise
  (not equal, malformed input, capability denied, or budget exceeded during replay).
  This is the M15 verifier: it does **not** trust the live e-graph state from a prior
  `egs_saturate`; it re-runs the deterministic saturation from the witnessed inputs
  and re-derives the verdict. Returns `u8` (W10) because it is a pure
  decision (W16 note: callers reading the u8 across the extern boundary use the value
  in register-low-byte form; see Trap Exposure).
- `egs_result_class(out_class_id: *u8)` → `EGS_OK` writing the 32-byte canonical
  class id of the most recent successful `egs_saturate` into `out_class_id`;
  `EGS_E_NULL` on null; `EGS_E_BAD` if no successful saturation has occurred since
  `egs_init`. (Separated from `egs_saturate` so the result is retrievable without a
  re-run; the 32-byte id is the 4 LE bytes of the egraph u32 class, zero-padded —
  see Data Structures.)
- `egs_last_steps` → the number of saturation steps the last `egs_saturate`/replay
  consumed (diagnostic; sentinel-typed `u64`; cf. `bigint_live_count`).
- `egs_last_overrun_dim` → the cost dimension index that triggered the last
  `EGS_E_BUDGET_EXCEEDED` (0..12), or `EGS_DIM_NONE (0xFFFFFFFFu32)` if the last run
  was in budget (diagnostic).
- `egs_node_count` → `eg_node_count()` (live e-node high-water; diagnostic).
- `egs_selftest` → `99u64` on full KAT pass, else the 1-based index of the first
  failing vector (house convention; cf. `wh_selftest` / `ident_selftest` / the
  egraph spec's `eg_selftest`).

### W2 resolution — the saturation request aggregate
`egs_saturate` carries six logical inputs/outputs; collapse into a caller-owned
by-pointer `*u64 req` (8 u64 cells = 64 bytes, little-endian, offsets in cells):

```
req[0] : u64  initial_terms_ptr   (address of the *u8 term-blob; see Term Blob Format)
req[1] : u64  terms_len           (byte length of the term blob; low 32 bits used)
req[2] : u64  rules_ptr           (address of the *u8 rule-blob; see Rule Blob Format)
req[3] : u64  rules_len           (byte length of the rule blob; low 32 bits used)
req[4] : u64  budget_ptr          (address of the 64-byte cost_lattice_synth vector)
req[5] : u64  out_class_id_ptr    (address of the caller's 32-byte class-id sink)
req[6] : u64  cap                 (CAP_RIGHT_TRANSFORM_RUN capability id; required)
req[7] : u64  reserved            (must be 0)
```
`EGS_REQ_CELLS = 8`. `egs_saturate` is thus **1 param** (W2). The verifier aggregate
`vreq` reuses the same 8-cell layout but adds two term pointers in place of the
output sink (it does not write a result):

```
vreq[0] : u64  initial_terms_ptr   vreq[1] : u64 terms_len
vreq[2] : u64  rules_ptr           vreq[3] : u64 rules_len
vreq[4] : u64  budget_ptr          vreq[5] : u64 cap
vreq[6] : u64  term_a_ptr          vreq[7] : u64 term_b_ptr
```
The two term-blobs `term_a` / `term_b` are each a standalone term blob (same format);
each carries its own length as the first cell of its 2-cell sub-header (see Term Blob
Format). `EGS_VREQ_CELLS = 8`.

### Term Blob Format (the codec bridge — NEW, the gospel had none)
A term blob is a self-framed little-endian byte buffer the engine parses into a
sequence of `eg_add` calls. The realized egraph works on **interned 32-byte symbol
ids + u32 child-class vectors**; a term blob is the serialized form the scaled API
accepts in its place. Layout:

```
bytes 0..3   : u32 n_entries (LE)            -- number of preorder entries
bytes 4..    : n_entries entries, each:
   byte  +0       : u8  kind   (0 = symbol application, 1 = back-reference)
   bytes +1..+33  : 32  sym_id (symbol identifier; present iff kind==0)
   byte  +33      : u8  arity  (0..8; child count; present iff kind==0)
   (kind==1 back-reference: bytes +1..+5 = u32 entry index already built)
```
Entries are in **post-order** (children before parents) so the codec builds bottom-up
with an explicit value stack (W15): a `kind==0` entry pops its `arity` most-recent
class ids off the build stack as `children`, calls
`eg_intern_symbol(sym_id)` then `eg_add(sym_id, children, arity)`, and pushes the
returned class id; a `kind==1` entry pushes the class id recorded for the referenced
earlier entry (DAG sharing). The **root** is the single class id remaining on the
stack after the last entry. This format is a direct serialization of the egraph's own
node model, so no information is invented (M1/M2). Malformed (stack underflow, arity
> 8, truncated buffer, n_entries past `EGS_TERM_ENTRIES`) → `EGS_E_TERM`.

### Rule Blob Format (NEW)
A rule blob is `u32 n_rules (LE)` followed by `n_rules` packed rule descriptors, each
exactly the realized `eg_register_rule` aggregate framed by a length:
`[total_u32_len][lhs_n, rhs_n, lhs.., rhs..]` where each LHS/RHS entry is a flat
preorder `u32` using the egraph encoding `concrete = (sym_slot<<1)|(arity<<16)`,
`var = (idx<<1)|1`. The engine copies each descriptor into `EGS_RULE_PACK` and calls
`eg_register_rule(&EGS_RULE_PACK[0])`. Because symbol *slots* in a rule must reference
interned symbols, the rule blob is preceded (within the same buffer, before
`n_rules`) by an optional **symbol-intern table**: `u32 n_syms` then `n_syms`×32-byte
ids that the engine interns (recording slot order) so the rule encoder's `sym_slot`
values are well-defined. (If `n_syms == 0` the rules reference only variables /
already-interned symbols from the term blob.) Malformed → `EGS_E_TERM`.

## Constant Namespace
PREFIX = `EGS_` . **Collision check:** `grep -rn "^const EGS_\|^var EGS_\|fn egs_\|
module numera_equality_saturation_scaled"` over `STDLIB/` returned **no matches**
(module not yet built; prefix free). `grep` of the gospel for `egs_*` symbols outside
Module 73's own section → none (no other module externs my symbols → I block no one).
Every module-scope const + var is `EGS_`-prefixed and globally unique (Trap 2). The
gospel's bare `EGS_OK`/`EGS_E_*` are already prefixed and retained; the rest are added.

| name | type | value | meaning |
|---|---|---|---|
| `EGS_OK` | i32 | `0i32` | success |
| `EGS_E_NULL` | i32 | `-1i32` | null pointer argument |
| `EGS_E_BUDGET_EXCEEDED` | i32 | `-2i32` | measured cost exceeds declared budget |
| `EGS_E_NOT_INITED` | i32 | `-3i32` | `egs_init` not called |
| `EGS_E_CAP` | i32 | `-4i32` | capability denied (CAP_RIGHT_TRANSFORM_RUN) |
| `EGS_E_TERM` | i32 | `-5i32` | malformed term / rule blob |
| `EGS_E_GRAPH` | i32 | `-6i32` | e-graph rejected an add / rule (overflow) |
| `EGS_E_EMIT` | i32 | `-7i32` | witness publish failed |
| `EGS_E_BAD` | i32 | `-8i32` | no result available / generic bad request |
| `EGS_SENT` | u32 | `0xFFFFFFFFu32` | u32 absence sentinel (mirrors egraph) |
| `EGS_DIM_NONE` | u32 | `0xFFFFFFFFu32` | "no dimension exceeded" diagnostic |
| `EGS_WH_FAIL` | u64 | `0xFFFFFFFFFFFFFFFFu64` | `wh_publish` failure sentinel |
| `EGS_REQ_CELLS` | u64 | `8u64` | saturation request aggregate size (cells) |
| `EGS_VREQ_CELLS` | u64 | `8u64` | verify request aggregate size (cells) |
| `EGS_MAX_STEPS` | u32 | `65536u32` | hard saturation step ceiling (M19 safety cap) |
| `EGS_TERM_ENTRIES` | u32 | `65536u32` | max preorder entries in a term blob |
| `EGS_BUILD_STK` | u32 | `65536u32` | term-codec build stack depth |
| `EGS_RULE_PACK_MAX` | u32 | `512u32` | one packed rule descriptor capacity (u32) |
| `EGS_MAX_SYMS` | u32 | `4096u32` | rule-blob intern-table dimension (= egraph MAX_SYMS) |
| `EGS_MAX_CHILDREN` | u32 | `8u32` | max arity (matches egraph MAX_CHILDREN) |
| `EGS_SYMBYTES` | u64 | `32u64` | bytes per symbol identifier (IDENT_BYTES) |
| `EGS_CLSBYTES` | u64 | `32u64` | bytes per scaled class id (4 used, 28 zero pad) |
| `EGS_CLS_DIM_TIME` | u8 | `0u8` | cost dim: time/steps budget (cost_lattice_synth dim 0) |
| `EGS_CLS_DIM_NODES` | u8 | `2u8` | cost dim: witness_growth used for node-growth budget |
| `EGS_RIGHT_TRANSFORM_RUN` | u64 | `0x00040000u64` | local copy of CAP_RIGHT_TRANSFORM_RUN |
| `EGS_PILLAR` | u16 | `6u16` | witness pillar id for saturation transcripts |
| `EGS_V3_SENTINEL` | u8 | `0xE3u8` | V3 extended-payload marker (byte 0) |
| `EGS_KIND_SATURATION` | u8 | `0x20u8` | v3_payload_kind: SATURATION_TRANSCRIPT |
| `EGS_PAYLOAD_BYTES` | u64 | `104u64` | transcript payload size (see Algorithm) |
| `EGS_CADDR_IN` | u64 | `96u64` | content-address preimage length (3×32) |

Bound rationale:
- `EGS_MAX_STEPS = EGS_TERM_ENTRIES = EGS_BUILD_STK = 65536` is the "tens of
  thousands of nodes" the gospel prose targets, rounded to a power of two; it is the
  module's hard M19 ceiling independent of the caller's (possibly larger) declared
  budget — saturation can never run past it even if the budget vector says otherwise.
- `EGS_RIGHT_TRANSFORM_RUN = 0x00040000u64` is a **local copy** (a constant, not an
  extern) of the verified `CAP_RIGHT_TRANSFORM_RUN` bit in `aether/capability.iii`
  (line 71), matching the cg_superopt precedent of copying `CAP_RIGHT_ATTEST` locally.
- `EGS_PAYLOAD_BYTES = 104` = V3 header (72: 1 sentinel + 1 kind + 2 reserved + 32
  content_address + 32 branch_id + 4 inner_len) + inner 32 (result_class_commit; the
  4 LE class bytes zero-padded to 32). The cost-dim mapping uses `cost_lattice_synth`'s
  dim 0 (time) for the step budget and dim 2 (witness_growth) for node-growth, both
  read via `cls_dimension_get`.

## Data Structures
Every buffer is a fixed module-scope `var` array (W8; Trap 7 — the gospel's five
in-function `var [u8;32]` arrays are all hoisted here). The engine is a **single
global scaled-saturation instance** (it wraps the single global e-graph); it is
therefore **not reentrant** — acceptable because a saturation run is a serialized
batch operation, the same model as `egraph.iii` / `cg_superopt.iii` / `sha256.iii`.
All scratch is `EGS_`-prefixed; address-of-static taken only inside this file (W1/W3).

Term/rule codec scratch:
| array | type | size | bound justification |
|---|---|---|---|
| `EGS_BUILD_CLS` | `[u32; 65536]` | `EGS_BUILD_STK` | term-codec build stack of class ids |
| `EGS_ENTRY_CLS` | `[u32; 65536]` | `EGS_TERM_ENTRIES` | per-entry class id (for kind==1 back-refs) |
| `EGS_CHILDREN` | `[u32; 8]` | `EGS_MAX_CHILDREN` | per-application child-class scratch for `eg_add` |
| `EGS_SYMBUF` | `[u8; 32]` | `EGS_SYMBYTES` | per-entry symbol id scratch (interning) |
| `EGS_RULE_PACK` | `[u32; 512]` | `EGS_RULE_PACK_MAX` | one packed `eg_register_rule` descriptor |

Result + diagnostic state:
| name | type | size | bound justification |
|---|---|---|---|
| `EGS_RESULT_CLS` | `u32` (scalar) | — | egraph u32 class id of the last result |
| `EGS_HAS_RESULT` | `u8` (scalar) | — | 1 iff a successful saturate has run since init |
| `EGS_LAST_STEPS` | `u64` (scalar) | — | steps consumed by the last run/replay |
| `EGS_LAST_OVERRUN` | `u32` (scalar) | — | last violated cost dim, else `EGS_DIM_NONE` |

Cost-budget scratch (cost_lattice_synth interop):
| array | type | size | bound justification |
|---|---|---|---|
| `EGS_MEASURED` | `[u8; 64]` | `CLS_BYTES` | measured cost vector (steps@dim0, nodes@dim2) |
| `EGS_OVERRUN_DESC` | `[u8; 24]` | `CLS_DESC_BYTES` | overrun descriptor for `cls_emit_overrun` |

Witness/content-address scratch:
| array | type | size | bound justification |
|---|---|---|---|
| `EGS_PRODUCER` | `[u8; 32]` | 32 | this module's witness producer id |
| `EGS_OPID` | `[u8; 32]` | 32 | "saturate" op id |
| `EGS_TERMS_COMMIT` | `[u8; 32]` | 32 | `Keccak256(initial_terms blob)` |
| `EGS_RULES_COMMIT` | `[u8; 32]` | 32 | `Keccak256(rules blob)` |
| `EGS_RESULT_COMMIT` | `[u8; 32]` | 32 | result class commit (4 LE class bytes, zero-pad) |
| `EGS_CADDR_BUF` | `[u8; 96]` | `EGS_CADDR_IN` | producer‖opid‖terms_commit preimage |
| `EGS_PAYLOAD` | `[u8; 104]` | `EGS_PAYLOAD_BYTES` | V3 SATURATION_TRANSCRIPT payload staging |
| `EGS_IN_C` | `[u8; 32]` | 32 | witness in-commit (= terms_commit) |
| `EGS_OUT_C` | `[u8; 32]` | 32 | witness out-commit (= result_commit) |
| `EGS_FRAG_ID` | `[u8; 32]` | 32 | witness fragment-id sink |

Lifecycle flag:
| name | type | bound justification |
|---|---|---|
| `EGS_INITED` | `u8` | init-once / not-inited guard (retained from gospel) |

All bounds are static and justified; total static BSS ≈ (65536+65536)×4 + 65536×... 
the two big `u32` arrays dominate at ~512 KiB combined, the rest is < 2 KiB. The
512 KiB is the cost of "tens of thousands of nodes" (gospel prose) and is module-scope
(NOT stack — fixing the Trap-7 / stack-overflow class of bug the egraph spec also
hit). `egs_*` is documented non-reentrant.

## Dependencies (externs)
All `@abi(c-msvc-x64)`, single-line. **Signatures verified against the realized
provider files / specs — the gospel's egraph externs are entirely fictional and are
replaced.**

```
extern @abi(c-msvc-x64) fn eg_init() -> i32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_intern_symbol(sym_id: *u8) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_add(sym_id: *u8, children: *u32, n: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_find(a: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_register_rule(rule: *u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_saturate(max_steps: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_node_count() -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn cls_dimension_get(v: *u8, dim: u8) -> u64 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_zero(out: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_dimension_set(v: *u8, dim: u8, value: u64) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_first_exceeded(declared: *u8, bound: *u8, out_dim: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_admit(declared: *u8, bound: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_overrun_desc_pack(dim: u8, declared: u64, observed: u64, out_desc: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_emit_overrun(operation_id: *u8, desc: *u8, out_frag_id: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
```

Provider status (for the wave scheduler):
| Provider | NN | Layer | Built? | Notes |
|---|---|---|---|---|
| `egraph.iii` | **17** | 4 | **NOT YET BUILT** (spec done) | The entire realized surface; gospel's `eg_add_term/eg_add_rewrite/eg_saturate_step/eg_class_of/eg_same_class` are fiction — corrected to `eg_init/eg_intern_symbol/eg_add/eg_find/eg_register_rule/eg_saturate/eg_node_count`. |
| `cost_lattice_synth.iii` | **65** | 7 | **NOT YET BUILT** (spec done) | `cls_dimension_get/cls_admit/cls_first_exceeded/cls_overrun_desc_pack/cls_emit_overrun/cls_zero/cls_dimension_set` verified against `cost_lattice_synth.spec.md`. The gospel's `cls_emit_overrun(operation_id, dim, declared, observed, out_frag_id)` 5-param form is wrong; realized form is `(operation_id, desc, out_frag_id)` with a packed 24-byte desc from `cls_overrun_desc_pack`. |
| `identifier.iii` | **01** | 0 | **BUILT** | `ident_from_bytes/ident_copy/ident_zero` verified byte-for-byte in tree (oneshot Keccak256 path, param-spill-safe). |
| `capability.iii` | **—** | aether R-1 | **BUILT** | `cap_verify_rights(id, required) -> u8` + `CAP_RIGHT_TRANSFORM_RUN = 0x00040000u64` verified in tree (lines 71, 148). |
| `witness_hook.iii` | **07** | 2 (R-1) | **BUILT** | `wh_publish` (12 params, `-> u64`, failure sentinel `0xFFFF…FF`) and `wh_chain_root` verified in tree (lines 144-191, 216). |

**Not-yet-built dependency count: 2** (egraph-17, cost_lattice_synth-65). Built deps:
identifier, capability, witness_hook. The gospel's `witness_spine.iii` reference in
the header NIH note is a fiction (no `ws_emit_fragment` / no witness-spine fragment
emitter); fragment emission is routed through the built `wh_publish` (systemic gospel
defect #2) and through `cls_emit_overrun` (which itself wraps `wh_publish`).

## Algorithm
NIH (M1): every step is hand-rolled over the realized substrate primitives — the
term-blob codec (explicit-stack bottom-up `eg_add`), the cost measurement, the V3
transcript-payload assembly, content-addresses via `ident_from_bytes` (Keccak256).
No ML / heuristics (M3/M4): the saturation is the e-graph's deterministic bounded
fixpoint; the budget check is the exact `cost_lattice_synth` product-order admission;
the verifier re-derivation is exact e-graph equivalence. Determinism (M2) and
bit-identity (W5): the term/rule blobs are parsed in a fixed order; the e-graph,
cost lattice, and content-address hash are all deterministic; the witnessed commits
are pure functions of the input bytes, so the published transcript and the verifier's
re-derivation are byte-reproducible from recorded inputs (M10). No recursion anywhere
(W15) — the term codec uses an explicit build stack `EGS_BUILD_CLS`. Bounded (M19):
saturation is capped by `min(declared_step_budget, EGS_MAX_STEPS)`; every loop is
sentinel/counter-driven (W14); the codec refuses (returns `EGS_E_TERM`) on stack
under/overflow rather than overrunning (M5).

### `egs_init() -> i32`
1. If `EGS_INITED == 1u8` return `EGS_OK` (idempotent, retained from gospel — but the
   gospel forgot to re-seed; this spec always (re)seeds the witness ids so a re-init
   is byte-identical, M9).
2. `eg_init()`.
3. Seed `EGS_PRODUCER = ident_from_bytes("numera::eq_sat_scaled", 21)` and
   `EGS_OPID = ident_from_bytes("numera::eq_sat_scaled::saturate", 30)` (stable
   producer/opid for the transcript fragments).
4. `EGS_HAS_RESULT = 0u8`, `EGS_RESULT_CLS = EGS_SENT`, `EGS_LAST_STEPS = 0u64`,
   `EGS_LAST_OVERRUN = EGS_DIM_NONE`, `EGS_INITED = 1u8`. Return `EGS_OK`.

### `egs_build_terms(blob: *u8, blob_len: u64) -> u32`  (private, W15 explicit stack)
Parse a term blob (see Term Blob Format) into `eg_add` calls and return the **root
class id** (or `EGS_SENT` on malformed input / e-graph overflow):
1. If `blob_len < 4u64` → `EGS_SENT`. Read `n_entries` (4 LE bytes). If
   `n_entries == 0u32` or `n_entries > EGS_TERM_ENTRIES` → `EGS_SENT`.
2. `sp = 0u32` (build-stack pointer), `off = 4u64` (byte cursor). Counted loop
   `e in [0, n_entries)` driven by a `done` flag (W14, no break):
   - Read `kind = blob[off]`; `off = off + 1`.
   - **kind == 0 (application):** bounds-check `off + 33u64 <= blob_len` (sym 32 +
     arity 1) else `done` with `EGS_SENT`. Copy 32 sym bytes
     `blob[off..off+32]` into `EGS_SYMBUF` (byte loop through `*u8`); `off += 32`.
     `arity = blob[off]`; `off += 1`. If `arity > EGS_MAX_CHILDREN` → `EGS_SENT`.
     **Guard `sp >= arity`** (else stack underflow → `EGS_SENT`, M5). Pop `arity`
     class ids into `EGS_CHILDREN[0..arity)` in **source order** (the child pushed
     last is the highest-indexed child: pop into `EGS_CHILDREN[arity-1-k]` so the
     stored order matches the term's left-to-right children — deterministic).
     `sp = sp - arity`. `eg_intern_symbol(&EGS_SYMBUF[0])` (intern, ignore the slot —
     `eg_add` re-interns by id), then
     `cls = eg_add(&EGS_SYMBUF[0], &EGS_CHILDREN[0], arity)`; if `cls == EGS_SENT`
     → `done` with `EGS_SENT` (e-graph overflow → `EGS_E_GRAPH` upstream). Record
     `EGS_ENTRY_CLS[e] = cls`. **Guard `sp < EGS_BUILD_STK`** (else `EGS_SENT`); push
     `EGS_BUILD_CLS[sp] = cls`; `sp = sp + 1`.
   - **kind == 1 (back-reference):** bounds-check `off + 4u64 <= blob_len` else
     `EGS_SENT`. `ref = blob[off..off+4] LE`; `off += 4`. If `ref >= e` → `EGS_SENT`
     (forward/self reference illegal — post-order invariant). **Guard `sp <
     EGS_BUILD_STK`**; push `EGS_BUILD_CLS[sp] = eg_find(EGS_ENTRY_CLS[ref])`
     (canonicalized); `sp = sp + 1`.
3. After the loop: require `sp == 1u32` (exactly one root remains) else `EGS_SENT`.
   Return `eg_find(EGS_BUILD_CLS[0])` (the canonical root class). All `u32`→address
   promotions masked `& 0xFFFFFFFFu64` (Trap 4); the byte cursor `off` is u64
   throughout. No `%` (Trap 11); no recursion (W15).

### `egs_register_rules(blob: *u8, blob_len: u64) -> i32`  (private)
Parse the rule blob (see Rule Blob Format): first the optional intern table (`n_syms`
then 32-byte ids, each `eg_intern_symbol`'d to fix slot order), then `n_rules`, then
each length-framed packed descriptor copied into `EGS_RULE_PACK` (bounds-guard
`total_u32_len <= EGS_RULE_PACK_MAX`) and registered via
`eg_register_rule(&EGS_RULE_PACK[0])`; any `EGS_SENT` return → `EGS_E_GRAPH`; any
framing violation → `EGS_E_TERM`. Counted loops, no recursion (W15). Returns
`EGS_OK` / `EGS_E_TERM` / `EGS_E_GRAPH`.

### `egs_measure(declared_steps: u64, nodes_before: u64) -> i32`  (private)
Fill `EGS_MEASURED` (a 64-byte cost vector) with the **actual** saturation cost:
`cls_zero(&EGS_MEASURED[0])`;
`cls_dimension_set(&EGS_MEASURED[0], EGS_CLS_DIM_TIME, EGS_LAST_STEPS)` (steps
consumed); `cls_dimension_set(&EGS_MEASURED[0], EGS_CLS_DIM_NODES,
eg_node_count() - nodes_before)` (node growth, saturating-subtract-guarded: if
`eg_node_count() < nodes_before` — impossible but guard — use 0). Returns `EGS_OK`.
(The declared budget vector is the caller's `budget_ptr`; this builds the measured
vector to compare against it.)

### `egs_saturate(req: *u64) -> i32`
1. Reject `req == 0u64` → `EGS_E_NULL`; if `EGS_INITED == 0u8` → `EGS_E_NOT_INITED`.
2. Decode the 8 cells (each `u64`, narrowing counts via `& 0xFFFFFFFFu64`, Trap 4):
   `terms_ptr/terms_len/rules_ptr/rules_len/budget_ptr/out_ptr/cap`; require
   `req[7] == 0u64` else `EGS_E_BAD`. Null-check `terms_ptr`, `rules_ptr`,
   `budget_ptr`, `out_ptr` (each `== 0u64` → `EGS_E_NULL`).
3. **Capability gate (M8):** `if cap_verify_rights(cap, EGS_RIGHT_TRANSFORM_RUN) ==
   0u8` → `EGS_E_CAP`. (A scaled run that publishes a federation transcript is a
   privileged attest-class action; the gospel had no gate.)
4. `eg_init()` (fresh graph for this saturation — deterministic from inputs).
5. `egs_register_rules(rules_ptr, rules_len)`; propagate `EGS_E_TERM`/`EGS_E_GRAPH`.
6. `root = egs_build_terms(terms_ptr, terms_len)`; if `root == EGS_SENT` → return
   `EGS_E_TERM` (malformed) — the codec already distinguished overflow, but at this
   boundary both map to a refusal (M5; caller retries with a corrected blob).
7. `nodes_before = eg_node_count() as u64`. Read the declared step budget
   `declared_steps = cls_dimension_get(budget_ptr, EGS_CLS_DIM_TIME)`. Compute the
   effective cap `cap_steps = declared_steps`; **if `cap_steps > (EGS_MAX_STEPS as
   u64)` then `cap_steps = EGS_MAX_STEPS as u64`** (the hard M19 ceiling overrides an
   over-large declared budget). `EGS_LAST_STEPS = eg_saturate(cap_steps as u32) as
   u64`. (The realized `eg_saturate` returns the steps actually performed and is
   itself bounded — this replaces the gospel's hand-rolled `while step < time_budget`
   spin that ignored fixpoint and never enforced anything.)
8. **Budget admission (M19):** `egs_measure(declared_steps, nodes_before)`;
   `if cls_admit(&EGS_MEASURED[0], budget_ptr) != EGS_OK` (the measured cost is not
   ⊑ the declared budget): `cls_first_exceeded(&EGS_MEASURED[0], budget_ptr, &dim8)`;
   set `EGS_LAST_OVERRUN = dim8 as u32`; build the overrun descriptor
   `cls_overrun_desc_pack(dim8, cls_dimension_get(budget_ptr, dim8),
   cls_dimension_get(&EGS_MEASURED[0], dim8), &EGS_OVERRUN_DESC[0])`; emit the
   COST_OVERRUN fragment `cls_emit_overrun(&EGS_OPID[0], &EGS_OVERRUN_DESC[0],
   &EGS_FRAG_ID[0])`; return `EGS_E_BUDGET_EXCEEDED`. (This is the *enforcement* the
   gospel's mission statement promised and the body entirely lacked.)
9. In budget: `EGS_LAST_OVERRUN = EGS_DIM_NONE`. `EGS_RESULT_CLS = root`;
   `EGS_HAS_RESULT = 1u8`. Write the result class id into the caller's sink:
   `egs_write_class(root, out_ptr)` (4 LE class bytes + 28 zero pad).
10. **Publish the saturation transcript (M6/M10/M15):** compute
    `EGS_TERMS_COMMIT = ident_from_bytes(terms_ptr, terms_len)`,
    `EGS_RULES_COMMIT = ident_from_bytes(rules_ptr, rules_len)`, and
    `EGS_RESULT_COMMIT = ident_from_bytes(out_ptr, 32)` (commit to the padded class
    id). Build the V3 SATURATION_TRANSCRIPT payload in `EGS_PAYLOAD` (header per
    cost_lattice_synth's V3 schema: `[0]=0xE3 [1]=0x20 [2..4]=0`,
    `[4..36]=content_address = ident_from_bytes(producer‖opid‖terms_commit, 96)`,
    `[36..68]=branch_id = rules_commit` (binds the rule set into the branch id —
    distinct rule sets are distinct branches, M16), `[68..72]=inner_len=32 LE`,
    `[72..104]=result_commit`). `wh_chain_root(&EGS_IN_C[0])`;
    `ident_copy(&EGS_RESULT_COMMIT[0], &EGS_OUT_C[0])`;
    `fi = wh_publish(&EGS_PRODUCER[0], &EGS_OPID[0], &EGS_IN_C[0], &EGS_OUT_C[0],
    0u8 /*revtag fwd*/, 0u8 /*phase*/, EGS_PILLAR, &EGS_OUT_C[0] /*antecedents,
    unused n_ante=0*/, 0u32, &EGS_PAYLOAD[0], EGS_PAYLOAD_BYTES as u32,
    &EGS_FRAG_ID[0])`; `if fi == EGS_WH_FAIL` → `EGS_E_EMIT`.
11. Return `EGS_OK`. The transcript fragment is the M15 separation: the search
    (saturation order) is oracular and not recorded; what enters the chain is the
    *replayable binding* `(terms_commit, rules_commit, result_commit)` — and
    `egs_verify_saturation` re-derives it.

### `egs_write_class(cls: u32, out: *u8) -> i32`  (private)
Zero 32 bytes of `out` (`ident_zero`), then write the 4 LE bytes of `cls` into
`out[0..4]` **byte-by-byte through `*u8`** (Trap 5 — never a `*u32` store of a u32
local). The scaled 32-byte class id is thus the egraph u32 class, zero-padded — a
total, deterministic injection (distinct classes → distinct ids; M2).

### `egs_verify_saturation(vreq: *u64) -> u8`  (the M15 verifier — re-derives)
Replaces the gospel's trust-the-live-graph check. Returns `1u8`/`0u8`:
1. Reject `vreq == 0u64` → `0u8`; if `EGS_INITED == 0u8` → `0u8`. Decode 8 cells;
   null-check `terms_ptr/rules_ptr/budget_ptr/term_a_ptr/term_b_ptr` (any null →
   `0u8`). Capability gate `cap_verify_rights(cap, EGS_RIGHT_TRANSFORM_RUN)` → `0u8`
   on deny.
2. **Independent re-derivation (the heart of M15/M17 — never trust prior state):**
   `eg_init()` (fresh graph); `egs_register_rules(rules_ptr, rules_len)` (→ `0u8` on
   error); `root = egs_build_terms(terms_ptr, terms_len)` (→ `0u8` if `EGS_SENT`).
   This reconstructs the *exact* e-graph the witnessed `egs_saturate` would have built
   from the recorded inputs — byte-deterministically (M2/M10).
3. `nodes_before = eg_node_count()`; `declared_steps = cls_dimension_get(budget_ptr,
   EGS_CLS_DIM_TIME)`; `cap_steps = min(declared_steps, EGS_MAX_STEPS)`;
   `EGS_LAST_STEPS = eg_saturate(cap_steps as u32)`. Budget check via
   `egs_measure` + `cls_admit`; if over budget → `0u8` (a run that cannot complete in
   budget cannot certify equivalence).
4. **Build the two query terms into the SAME saturated graph and compare classes:**
   `ca = egs_build_terms(term_a_ptr, term_a_len)`; `cb = egs_build_terms(term_b_ptr,
   term_b_len)` (each blob self-frames its length in its leading `u32`; the codec is
   re-entrant *within* this single-threaded call because it uses the shared build
   stack serially). If either is `EGS_SENT` → `0u8`. Return `1u8` iff
   `eg_find(ca) == eg_find(cb)` (the canonical class representatives are equal —
   congruence-closed equivalence), else `0u8`. (Because the rules + initial terms are
   re-saturated, `term_a`/`term_b` are checked against the *re-derived* closure, not a
   trusted cached graph — M11/M12/M17.)

### `egs_result_class / egs_last_steps / egs_last_overrun_dim / egs_node_count`
`egs_result_class`: null-check; `if EGS_HAS_RESULT == 0u8` → `EGS_E_BAD`; else
`egs_write_class(EGS_RESULT_CLS, out_class_id)`; `EGS_OK`. The three diagnostics
return `EGS_LAST_STEPS` / `EGS_LAST_OVERRUN` / `eg_node_count() as u64`. Pure.

### `egs_selftest() -> u64`
In-module KAT harness (see KAT Vectors). `99u64` on full pass, else the 1-based index
of the first failing vector (W12). Uses only module-scope scratch; seeds a test
capability via the harness (KAT 4/5 require capability + the not-yet-built deps; the
harness skips them with a recorded note if a dep is absent, as in the cg_superopt
spec, but they are part of the Phase-2 acceptance gate).

## KAT Vectors (>= 3)
All vectors `egs_init()` first, then build term/rule blobs into module-test scratch
and assert byte-for-byte on the returned status / class id. A valid test capability
`cap` carrying `CAP_RIGHT_TRANSFORM_RUN` is minted by the harness
(`cap_attenuate(CAP_ENV_ROOT, CAP_RIGHT_TRANSFORM_RUN, 0)`).

1. **Congruence at scale (the defining property).** Build a term blob for `f(a)` and
   `f(b)` (symbols `f`,`a`,`b`; `a`,`b` arity 0; two `f` applications sharing nothing
   initially), and a rule blob with one rule `a -> b` (a ground rewrite uniting the
   two leaf classes). `egs_saturate(req)` → `EGS_OK`. Then
   `egs_verify_saturation(vreq)` with `term_a = f(a)`, `term_b = f(b)` → **`1u8`**
   (congruence propagated `a≡b ⟹ f(a)≡f(b)` under the re-derived closure). This is
   the byte-checkable heart: the verifier re-saturates and confirms the two `f` terms
   collapse to one class.

2. **Rewrite + extract equivalence (`mul(x,two) ≡ shl(x,one)`).** Term blob for
   `mul(x, two)`; rule blob with the intern table for `mul,shl,x,two,one` and the
   single rule `mul(?0, two) -> shl(?0, one)` (flat-preorder encoded). `egs_saturate`
   → `EGS_OK`. `egs_verify_saturation` with `term_a = mul(x,two)`,
   `term_b = shl(x,one)` → **`1u8`**. Verifies the rule-blob codec, interning, the
   flat-skeleton encoding, and saturation-then-verify end to end.

3. **Budget enforcement (M19 — the major fix; positive + negative).**
   (a) *In budget:* declare a generous budget (`time` dim = 1000, `witness_growth`
   dim = 1000); `egs_saturate(KAT-1 inputs, budget)` → `EGS_OK`,
   `egs_last_overrun_dim() == EGS_DIM_NONE`. (b) *Over budget (negative — prove the
   guard fires):* declare a budget with `time` dim = `0` (zero steps permitted) on an
   input that requires >= 1 saturation step to reach the rewrite; `egs_saturate` →
   **`EGS_E_BUDGET_EXCEEDED`**, `egs_last_overrun_dim() == 0` (the time dimension),
   and a COST_OVERRUN fragment was published (`wh_next_idx()` advanced by 1).
   Proves the admission gate and `cls_emit_overrun` wiring actually trigger (the
   "prove the negative case" discipline) — the gospel body could never produce this.

4. **Capability gate (M8 — negative + positive).** `egs_saturate` with `req[6] = 0u64`
   (invalid cap id) → **`EGS_E_CAP`** (no graph built, no fragment). With the valid
   `cap` carrying `CAP_RIGHT_TRANSFORM_RUN` → `EGS_OK`. `egs_verify_saturation` with
   an invalid cap → `0u8`. Proves the gate both denies and permits.

5. **Malformed term blob refusal (negative — prove the codec guard fails safely).**
   Build a term blob whose last `kind==0` entry has `arity = 3` but only 1 prior
   entry on the build stack (stack-underflow). `egs_saturate` → **`EGS_E_TERM`** (not
   a crash, not `EGS_OK`). A second blob with `n_entries` past `EGS_TERM_ENTRIES` →
   `EGS_E_TERM`. Proves M5 (refuse, never overrun) for the W15 explicit-stack codec.

6. **Determinism / bit-identity replay.** Run KAT 1 + KAT 2 twice from a fresh
   `egs_init()`; assert identical returned class ids (`egs_result_class` bytes),
   identical `egs_last_steps`, identical published `content_address` /
   `result_commit` (recompute and compare), and identical `egs_verify_saturation`
   verdicts. Proves M2/W5 (cross-run bit-identity of the codec, saturation, the
   transcript commits, and the re-derivation).

`egs_selftest` returns `99u64` only if all of the above hold (KAT 3/4 require the
not-yet-built `cost_lattice_synth` + `capability`; the harness records a skip note if
absent, but they remain Phase-2 acceptance gates).

## Trap Exposure
The 12-trap catalog; this module also touches the corpus-278 address-of-index
precedence trap (treated as a 13th, per the egraph spec).

1. **Multi-line `fn` declarations** — EXPOSED (8 public + 5 private signatures, and
   the long `wh_publish` extern). Avoidance: **every** signature + extern in the
   Skeleton is single-line; the W2 `req`/`vreq` aggregate refactor keeps
   `egs_saturate`/`egs_verify_saturation` at 1 param so no signature tempts wrapping;
   the `wh_publish` extern is one long physical line (legal).
2. **Module-level `const` linker-global** — EXPOSED (≈30 consts). Avoidance: `EGS_`
   prefix on **every** const + var; grep-confirmed collision-free. (Gospel used
   `EGS_` already; extended consistently.)
3. **Signed-int ordering compare SIGSEGV** — LOW EXPOSURE. All ids/counts/steps/cost
   values are `u32`/`u64` (unsigned compares legal). The only `i32` values are status
   codes and the `cls_admit`/`eg_*` returns, compared by `== / !=` only (W9/W11):
   `cls_admit(...) != EGS_OK`, `cls_first_exceeded(...) ` ignored-return, `fi ==
   EGS_WH_FAIL`. **No `i32`/`i64` `< <= > >=` anywhere.**
4. **`u32`-in-`u64`-slot garbage before pointer math** — EXPOSED (the cell decode of
   `req`/`vreq`, every `class id`/`entry index` promoted to a byte offset, the
   `eg_node_count() as u64`). Avoidance: mask `(x as u64) & 0xFFFFFFFFu64` on **every**
   u32 promoted into an address/index/arithmetic expression (the byte cursor `off`
   stays u64 natively; class ids are `< 2^31` so the high word is zero, but the mask
   is applied defensively per the bigint/egraph discipline).
5. **`u32` pointer store width (`movq` clobber)** — EXPOSED. `egs_write_class` writes
   the 4 class bytes **byte-by-byte through `*u8`** (the `bigint.iii::big_store_u64_le`
   idiom), never `p[0] = cls_u32` through a `*u32`. The term-blob length/back-ref
   reads are byte-by-byte LE folds. The `EGS_CHILDREN[k] = cls` / `EGS_BUILD_CLS[sp] =
   cls` / `EGS_ENTRY_CLS[e] = cls` stores are into `[u32;…]` module arrays **by index**
   (the safe full-width element-store path).
6. **Nested `/* */` comments** — AVOIDED. Only `//` and single-level `/* */`.
7. **Local `var` arrays unsupported** — EXPOSED (the gospel had five: `first_node`,
   `node_a`, `node_b`, `class_a`, `class_b`, all `[u8;32]`). Avoidance: **all hoisted
   to module scope** (the result/commit/scratch buffers), plus the new codec/witness
   buffers. Consequence documented: the engine is **non-reentrant** (single global
   instance wrapping the single global e-graph) — acceptable for serialized batch
   saturation, same model as `egraph.iii` / `cg_superopt.iii`.
8. **`} else {` must be one line** — LOW EXPOSURE. The skeleton uses the flag-guarded
   independent-`if` idiom (`if kind == 0u8 {…} if kind == 1u8 {…}`) so `else` is
   rarely needed; where used (the codec's saturating-subtract guard) it is written
   `} else {` on one line.
9. **Em-dash in `/* */` comment** — AVOIDED. All `.iii` comments use ASCII `--`.
10. **`let mut x = 0u32` checkpoint-flag misbehaves** — LOW EXPOSURE. The codec's
    `done` flag and the `sp` build-stack pointer **drive the loop condition itself**
    (W14, the iiis-1 insertion-sort lesson); where a single completion check suffices
    (null checks, capability gate, `EGS_HAS_RESULT`) an early-return is preferred.
11. **`a % b` after a call → quotient/stale-divisor** — NOT EXPOSED. There is **no
    `%`** anywhere in the module — the codec uses byte cursors and counted loops, the
    cost comparison is delegated to `cost_lattice_synth`, and the class-id pack is a
    byte split. (Slot reduction / hashing lives inside egraph, behind the extern.)
12. **`@specialize *T` stride defaults to 8** — NOT APPLICABLE. No generics; all
    arrays are concrete `[u32;…]`/`[u8;…]`/`[u64;…]` with explicit byte-offset
    arithmetic (`*32u64` for sym/class ids, `*4u64` for entry offsets, `*8u64` for the
    `req`/`vreq` cells). Layout is asserted by KAT 1-3.
13. **(corpus 278) Address-of-index precedence** — EXPOSED (every element-address into
    a module array). Avoidance: use the **built-tree idiom** `((&ARR as u64) + off)
    as *T` (as in `witness_hook.iii` / `bigint.iii`) for every element-address — e.g.
    `((&EGS_BUILD_CLS as u64) + (sp as u64 & 0xFFFFFFFFu64) * 4u64) as *u32`,
    `((&EGS_PAYLOAD as u64) + 4u64) as *u8`. The bare `&ARR[idx] as *T` form is never
    used; where simple `ARR[idx]` indexing suffices (most reads/writes) it is used
    directly (the parser handles plain indexing correctly).

## Gap / Fix List
STUB — the gospel body does not realize its mission. Every gap is closed by this spec;
Phase 2 implements against it.

1. **Fictional egraph externs (BLOCKER — would fail to link).** `eg_add_term`,
   `eg_add_rewrite`, `eg_saturate_step`, `eg_class_of`, `eg_same_class` do **not
   exist** in the realized `egraph.iii` (Module 17 spec). The realized surface is
   `eg_init / eg_intern_symbol / eg_add(sym_id, children, n) / eg_find /
   eg_register_rule(rule) / eg_saturate(max_steps) / eg_extract / eg_class_count /
   eg_node_count`. FIX: extern the real symbols; bridge the term-blob/class-id API to
   the interned-symbol/u32-class model via the new `egs_build_terms` codec and
   `egs_write_class`. (Same systemic gospel-extern-unreliability defect flagged for
   the other agents — the gospel's downstream "scaled" modules likely share fictional
   `eg_*_term` externs.)
2. **Class-id impedance mismatch.** The gospel API passes 32-byte `*u8` class ids;
   the realized egraph uses `u32`. FIX: define the scaled class id as the 4 LE bytes
   of the egraph u32 class, zero-padded to 32 (`egs_write_class`), and read back via
   the result/commit buffers — a total deterministic injection, documented.
3. **Absent budget enforcement (the named mission, M19).** The gospel reads one
   dimension and uses it as a raw loop bound; it never calls the realized
   `cost_lattice_synth` admission machinery. FIX: after `eg_saturate`, build the
   measured cost vector (`egs_measure`), gate it with `cls_admit`, on exceedance name
   the dimension (`cls_first_exceeded`) and **emit a schema-conformant COST_OVERRUN
   fragment** (`cls_overrun_desc_pack` + `cls_emit_overrun`), returning
   `EGS_E_BUDGET_EXCEEDED`. The hard `EGS_MAX_STEPS` ceiling overrides an over-large
   declared budget (M19 safety).
4. **Fictional M15 verifier separation.** The prose promises "the verifier transcript
   is what enters the chain," but the body emits **no witness** and
   `egs_verify_saturation` blindly trusts the live e-graph (M6/M10/M17 violation).
   FIX: `egs_saturate` publishes a V3 SATURATION_TRANSCRIPT fragment via `wh_publish`
   binding `content_address(producer‖opid‖terms_commit) || branch_id=rules_commit ||
   result_commit`; `egs_verify_saturation` **independently re-derives** the
   equivalence by re-saturating from the recorded `(initial_terms, rules, budget)` in
   a fresh `eg_init()` graph and comparing `eg_find` of the two query terms — trusting
   the replayable transcript, not the search (M11/M12/M17).
5. **Trap 7: five local `var [u8;32]` arrays in `egs_saturate`/`egs_verify_saturation`.**
   FIX: all hoisted to module-scope staging buffers; non-reentrancy documented.
6. **No capability gate (M8).** A scaled run that publishes federation/witness
   fragments is privileged. FIX: both `egs_saturate` and `egs_verify_saturation`
   require `cap_verify_rights(cap, CAP_RIGHT_TRANSFORM_RUN) == 1u8` (the real built
   `capability.iii` right bit `0x00040000u64`), `req[6]`/`vreq[5]` carrying the cap id.
7. **Wrong error semantics in `egs_verify_saturation`.** The gospel returns
   `EGS_E_BUDGET_EXCEEDED` for a plain not-same-class result. FIX: the verifier
   returns `u8` (1 = equal, 0 = not-equal/error) — a clean decision; budget overrun
   during replay maps to `0u8` (cannot certify), distinct from the saturate path's
   `EGS_E_BUDGET_EXCEEDED` status.
8. **W2 violations.** Gospel `egs_saturate` had **6 params** and
   `egs_verify_saturation` **5 params**. FIX: both take a single packed `*u64`
   aggregate (`req` / `vreq`, 8 cells each), documented above.
9. **No term/rule serialization contract.** The gospel passed opaque `*u8` term/rule
   blobs with no defined format, so no implementation could parse them deterministically.
   FIX: the Term Blob Format (self-framed post-order preorder with DAG back-refs) and
   Rule Blob Format (intern table + length-framed packed `eg_register_rule`
   descriptors) are defined exactly, matching the egraph encoding (M1/M2).
10. **Idempotent-init re-seed gap.** The gospel's `egs_init` early-returns when already
    inited without re-seeding — a re-init after state mutation would leave stale
    witness ids. FIX: `egs_init` always (re)seeds the producer/opid ids and resets the
    diagnostics so re-init is byte-identical (M9).
11. **`witness_spine.iii` NIH-note fiction.** The header claims a `witness_spine.iii`
    dependency for fragment emission, but there is no `ws_emit_fragment` (systemic
    defect #2). FIX: all emission routes through the built `wh_publish` (direct, for
    the transcript) and `cls_emit_overrun` (for the COST_OVERRUN, itself wrapping
    `wh_publish`); no `witness_spine` dependency.

Mandate scorecard after fixes: M1 ✓ (hand-rolled codec/measurement/payload over the
substrate primitives; no third-party); M2/W5 ✓ (deterministic egraph + cost lattice +
content-address hash, ascending blob parse, byte-reproducible commits + re-derivation);
M3/M4 ✓ (fixed rule set, exact bounded fixpoint, exact product-order admission, exact
class-equality verify — no scores/observation); M5 ✓ (codec refuses on under/overflow,
budget overrun refuses + witnesses, no destructive state → no bricking); M6/M10 ✓
(saturation transcript + COST_OVERRUN witnessed via `wh_publish`, recomputable from
the input blobs); M7 ✓ (Ring R0; calls into R-1 witness/capability through their
public C-ABI, the sanctioned downward path); M8 ✓ (`cap_verify_rights` gate on both
entry points); M9 ✓ (saturate builds a fresh graph; the witness is append-only +
revocable; re-init re-seeds identically); M11/M12 ✓ (the verifier re-derives a
checkable equivalence; the transcript binding is the synthesis certificate); M15 ✓
(oracular search separated from the replayable verifier transcript — the headline
mandate); M16 ✓ (distinct rule sets → distinct `branch_id`, ratifiable);
M17 ✓ (the saturation result is chain-verified by independent re-derivation, never
blindly trusted); M19 ✓ (bounded by `min(declared, EGS_MAX_STEPS)`, admission gate,
COST_OVERRUN emission, every loop sentinel/counter-bounded). W2 ✓ (≤4 params — packed
aggregates); W8 ✓ (static buffers, justified); W9/W10/W11/W12 ✓ (negative-i32 errors,
u8 verifier predicate, equality-only signed compares, status on every public fn);
W13 ✓ (≤20 locals per fn — the codec is the densest at ~12); W14 ✓ (sentinel/counter
loops, no `break`); W15 ✓ (no recursion — explicit build stack);
W16/W17 ✓ (forward-tagged append under monotonic algebraic time inside `wh_publish`).
Ring R0, K=0.99 / K_synth=0.95 preserved.

## Implementation Skeleton
Paste-ready structure; SINGLE-LINE signatures; bodies are `// TODO` per Algorithm.
All comments ASCII (no em-dash; Trap 9). No nested block comments (Trap 6).

```iii
/* III/STDLIB/iii/numera/equality_saturation_scaled.iii
 *
 * III STDLIB - numera::equality_saturation_scaled
 *
 * Equality saturation at industrial scale -- the witnessed, bounded,
 * capability-gated wrapper over the base e-graph (Module 17).  The
 * internal saturation search is oracular under M15; what enters the
 * chain is the replayable transcript binding
 *   content_address(producer||opid||Keccak256(terms))
 *   || branch_id = Keccak256(rules) || result_class_commit
 * and egs_verify_saturation INDEPENDENTLY RE-DERIVES the equivalence by
 * re-saturating from the recorded inputs (M11/M12/M17 -- never trust the
 * live graph).  Budget enforcement is delegated to cost_lattice_synth:
 * the measured cost (steps, node-growth) is admission-gated and an
 * over-budget run emits a schema-conformant COST_OVERRUN fragment (M19).
 *
 * A term blob is a self-framed post-order preorder of entries (symbol
 * applications + DAG back-references); the codec drives eg_add bottom-up
 * with an explicit build stack (W15).  A rule blob is an intern table
 * plus length-framed packed eg_register_rule descriptors.
 *
 * Single global instance (NOT reentrant): all scratch + the build stack
 * are module-scope (Trap 7).  No recursion (W15).  No modulo (Trap 11).
 *
 * Hexad: kind_cognition.  Ring: R0.  K_synth: 0.95.  K: 0.99.
 * Discipline: W2, W8, W13, W14, W15.
 *
 * NIH: depends on egraph.iii (Module 17), cost_lattice_synth.iii
 *      (Module 65), identifier.iii, capability.iii, witness_hook.iii.
 */

module numera_equality_saturation_scaled

extern @abi(c-msvc-x64) fn eg_init() -> i32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_intern_symbol(sym_id: *u8) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_add(sym_id: *u8, children: *u32, n: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_find(a: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_register_rule(rule: *u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_saturate(max_steps: u32) -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn eg_node_count() -> u32 from "egraph.iii"
extern @abi(c-msvc-x64) fn cls_dimension_get(v: *u8, dim: u8) -> u64 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_zero(out: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_dimension_set(v: *u8, dim: u8, value: u64) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_first_exceeded(declared: *u8, bound: *u8, out_dim: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_admit(declared: *u8, bound: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_overrun_desc_pack(dim: u8, declared: u64, observed: u64, out_desc: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn cls_emit_overrun(operation_id: *u8, desc: *u8, out_frag_id: *u8) -> i32 from "cost_lattice_synth.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const EGS_OK               : i32 =  0i32
const EGS_E_NULL           : i32 = -1i32
const EGS_E_BUDGET_EXCEEDED : i32 = -2i32
const EGS_E_NOT_INITED     : i32 = -3i32
const EGS_E_CAP            : i32 = -4i32
const EGS_E_TERM           : i32 = -5i32
const EGS_E_GRAPH          : i32 = -6i32
const EGS_E_EMIT           : i32 = -7i32
const EGS_E_BAD            : i32 = -8i32

const EGS_SENT             : u32 = 0xFFFFFFFFu32
const EGS_DIM_NONE         : u32 = 0xFFFFFFFFu32
const EGS_WH_FAIL          : u64 = 0xFFFFFFFFFFFFFFFFu64

const EGS_REQ_CELLS        : u64 = 8u64
const EGS_VREQ_CELLS       : u64 = 8u64
const EGS_MAX_STEPS        : u32 = 65536u32
const EGS_TERM_ENTRIES     : u32 = 65536u32
const EGS_BUILD_STK        : u32 = 65536u32
const EGS_RULE_PACK_MAX    : u32 = 512u32
const EGS_MAX_SYMS         : u32 = 4096u32
const EGS_MAX_CHILDREN     : u32 = 8u32
const EGS_SYMBYTES         : u64 = 32u64
const EGS_CLSBYTES         : u64 = 32u64

const EGS_CLS_DIM_TIME     : u8  = 0u8
const EGS_CLS_DIM_NODES    : u8  = 2u8

const EGS_RIGHT_TRANSFORM_RUN : u64 = 0x00040000u64
const EGS_PILLAR           : u16 = 6u16
const EGS_V3_SENTINEL      : u8  = 0xE3u8
const EGS_KIND_SATURATION  : u8  = 0x20u8
const EGS_PAYLOAD_BYTES    : u64 = 104u64
const EGS_CADDR_IN         : u64 = 96u64

/* --- term/rule codec scratch --- */
var EGS_BUILD_CLS    : [u32; 65536]
var EGS_ENTRY_CLS    : [u32; 65536]
var EGS_CHILDREN     : [u32; 8]
var EGS_SYMBUF       : [u8;  32]
var EGS_RULE_PACK    : [u32; 512]

/* --- result + diagnostics --- */
var EGS_RESULT_CLS   : u32 = 0xFFFFFFFFu32
var EGS_HAS_RESULT   : u8  = 0u8
var EGS_LAST_STEPS   : u64 = 0u64
var EGS_LAST_OVERRUN : u32 = 0xFFFFFFFFu32

/* --- cost-budget scratch --- */
var EGS_MEASURED     : [u8; 64]
var EGS_OVERRUN_DESC : [u8; 24]

/* --- witness / content-address scratch --- */
var EGS_PRODUCER     : [u8; 32]
var EGS_OPID         : [u8; 32]
var EGS_TERMS_COMMIT : [u8; 32]
var EGS_RULES_COMMIT : [u8; 32]
var EGS_RESULT_COMMIT : [u8; 32]
var EGS_CADDR_BUF    : [u8; 96]
var EGS_PAYLOAD      : [u8; 104]
var EGS_IN_C         : [u8; 32]
var EGS_OUT_C        : [u8; 32]
var EGS_FRAG_ID      : [u8; 32]

/* --- lifecycle --- */
var EGS_INITED       : u8 = 0u8

/* ---- private helpers ---- */
fn egs_write_class(cls: u32, out: *u8) -> i32 { /* TODO: ident_zero(out); write 4 LE class bytes through *u8 (Trap 5); EGS_OK (Algorithm) */ }
fn egs_build_terms(blob: *u8, blob_len: u64) -> u32 { /* TODO: parse self-framed post-order term blob; explicit build stack EGS_BUILD_CLS; eg_intern_symbol+eg_add per app; back-ref via EGS_ENTRY_CLS; guard sp underflow/overflow; return root class or EGS_SENT (Algorithm; W15; Trap 4/13) */ }
fn egs_register_rules(blob: *u8, blob_len: u64) -> i32 { /* TODO: parse intern table then length-framed packed descriptors into EGS_RULE_PACK; eg_register_rule each; EGS_E_TERM/EGS_E_GRAPH (Algorithm) */ }
fn egs_measure(declared_steps: u64, nodes_before: u64) -> i32 { /* TODO: cls_zero(EGS_MEASURED); set dim0=EGS_LAST_STEPS, dim2=node-growth (saturating sub); EGS_OK (Algorithm) */ }

/* ---- public API ---- */
fn egs_init() -> i32 @export { /* TODO: idempotent; eg_init; seed EGS_PRODUCER/EGS_OPID; reset diagnostics; EGS_INITED=1 (Algorithm; M9) */ }
fn egs_saturate(req: *u64) -> i32 @export { /* TODO: decode 8-cell req; null+cap gate; eg_init; register_rules; build_terms->root; eg_saturate(min(declared,MAX)); measure+cls_admit; on over-budget cls_first_exceeded+cls_overrun_desc_pack+cls_emit_overrun -> EGS_E_BUDGET_EXCEEDED; else write class + publish transcript via wh_publish (Algorithm; M8/M15/M19) */ }
fn egs_verify_saturation(vreq: *u64) -> u8 @export { /* TODO: decode 8-cell vreq; null+cap gate; INDEPENDENT re-derive: eg_init; register_rules; build_terms; eg_saturate(min); budget check; build term_a/term_b; return eg_find(ca)==eg_find(cb) (Algorithm; M11/M12/M17) */ }
fn egs_result_class(out_class_id: *u8) -> i32 @export { /* TODO: null-check; EGS_E_BAD if !EGS_HAS_RESULT; egs_write_class(EGS_RESULT_CLS,out) (Algorithm) */ }
fn egs_last_steps() -> u64 @export { /* TODO: return EGS_LAST_STEPS */ }
fn egs_last_overrun_dim() -> u32 @export { /* TODO: return EGS_LAST_OVERRUN */ }
fn egs_node_count() -> u64 @export { /* TODO: return eg_node_count() as u64 */ }
fn egs_selftest() -> u64 @export { /* TODO: run KAT 1-6; 99u64 on pass else failing index (KAT Vectors; W12) */ }
```
