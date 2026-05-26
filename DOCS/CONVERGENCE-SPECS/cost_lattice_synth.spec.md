# 65 numera/cost_lattice_synth.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate implements the dimension codec (`cls_zero`, `cls_dimension_get`, `cls_dimension_set`), the two composition operators (`cls_compose_sequential`, `cls_compose_parallel`), and the product-order check (`cls_le`) competently, but it (1) externs a **non-existent symbol** `ws_emit_fragment from "witness_spine.iii"` — that function does not exist in Module 12 `witness_spine.iii` (whose API is `ws_init/ws_register/ws_lookup_id/...`); the real fragment emitter is `wh_publish` in the already-built `aether/witness_hook.iii`, with a 12-parameter signature and a `u64` return, not the candidate's invented 7-param `i32`-returning shape; (2) violates Trap 7 with **five local `var` arrays** inside `cls_emit_overrun` (`payload[64]`, `producer/op/in_c/out_c[32]`); (3) violates W2 (`cls_emit_overrun` has 5 params); (4) lets `cls_compose_sequential` (`lv+rv`, `(lv*rv)/100`) and `cls_compose_parallel` (`memory`/`witness`/`proof_term` sums) **overflow u64 silently** — breaking M15/M19 totality (a wrapped cost reads as tiny, defeating the entire boundedness purpose of the module); (5) emits a COST_OVERRUN payload that **does not conform to the V3 `v3_payload_header` schema** (gospel §"V3 extended payload layout", lines 502-510): it omits the `content_address`, `branch_id`, and `inner_len` framing the schema mandates, so the fragment the candidate produces is unparseable by a V3 verifier; (6) provides **no admission gate** — the named mandate for this module is M19/W43 ("no synthesis output beyond cost lattice"; "operations whose declared cost vector exceeds the bound permitted by their containing phase fail at admission", gospel lines 91/349) — the candidate has the order check `cls_le` but no function that *refuses* an over-budget vector or names the violated dimension for the overrun fragment. This spec realizes the maximal intent: a total, saturating, schema-conformant V3 cost lattice with an explicit bound-admission gate and a correct, content-addressed COST_OVERRUN emission.

## Purpose
`numera/cost_lattice_synth.iii` IS the V3 extension of the base cost lattice (`numera/cost_lattice.iii`, Module 22): it lifts the order/composition algebra onto a **64-byte extended cost vector** carrying eight u64 additive/max dimensions (time, memory, witness_growth, proof_term_size, lib_cite_depth, branch_depth, synth_budget, reflect_budget) plus a five-component **K vector** (K, K_synth, K_reflect, K_memo, K_theorem; each a u8 fixed-point in 0..100) in bytes 56-60. It defines sequential composition (additive dims add, K multiplies as fixed-point), parallel composition (time/budgets max, memory/witness/proof sum, K mins), the mixed partial order (≤ on additive dims, ≥ on K dims — "cheaper and at-least-as-trusted"), an explicit admission gate that refuses any declared vector exceeding a permitted bound, and the emission of schema-conformant `COST_OVERRUN` witness fragments. It is the M19 boundedness mechanism for the V3 reasoning engines — the answer to "how does synthesis/reflection avoid running forever." Hexad kind: `kind_essence`. Ring: R0. K-vector (module's own): 1.00 (pure arithmetic + one witnessed emission path; deterministic over fixed bit width).

## Public API
All public functions are single-line (Trap 1). Status convention (W9/W12): error codes are negative `i32` constants compared by equality only (W9/W11); boolean predicates return `u8` 0/1 (W10); dimension reads return a sentinel-typed `u64`; every public fn returns a status or sentinel-typed value (W12). W2 ≤4 params is honored on every fn (the candidate's 5-param `cls_emit_overrun` is repaired via an aggregate descriptor).

```
fn cls_zero(out: *u8) -> i32 @export
fn cls_dimension_get(v: *u8, dim: u8) -> u64 @export
fn cls_dimension_set(v: *u8, dim: u8, value: u64) -> i32 @export
fn cls_compose_sequential(left: *u8, right: *u8, out: *u8) -> i32 @export
fn cls_compose_parallel(left: *u8, right: *u8, out: *u8) -> i32 @export
fn cls_le(a: *u8, b: *u8) -> u8 @export
fn cls_first_exceeded(declared: *u8, bound: *u8, out_dim: *u8) -> i32 @export
fn cls_admit(declared: *u8, bound: *u8) -> i32 @export
fn cls_emit_overrun(operation_id: *u8, desc: *u8, out_frag_id: *u8) -> i32 @export
fn cls_overrun_desc_pack(dim: u8, declared: u64, observed: u64, out_desc: *u8) -> i32 @export
```

Return-status notes per fn:
- `cls_zero` → `CLS_OK`; `CLS_E_NULL` on null `out`. Zeros all 64 bytes (gospel-correct).
- `cls_dimension_get` → the dimension value as `u64`; **returns `0u64` on null `v` or `dim >= 14`** (sentinel-typed value, W12; a true zero dimension is indistinguishable from invalid — acceptable for a pure accessor, matching the gospel; callers needing the distinction range-check `dim` and null-check `v` themselves). Additive dims 0..7 read 8 little-endian bytes at `dim*8`; K dims 8..13 read one byte at `56 + (dim-8)`.
- `cls_dimension_set` → `CLS_OK`; `CLS_E_NULL` on null; `CLS_E_DIM` on `dim >= 14`. K-dim writes mask to the low byte (`value & 0xFF`); the spec additionally **clamps K to 0..100** (the declared fixed-point range) so an out-of-range K can never enter a vector — closing a silent-corruption path the candidate leaves open (a K byte of 200 would make `cls_le`'s ≥-on-K comparison meaningless).
- `cls_compose_sequential` → `CLS_OK`; `CLS_E_NULL` on any null. Additive dims 0..7: **saturating** add (→ `U64_MAX` on overflow). K dims 8..12: fixed-point product `(lv*rv)/100`, computed without overflow (the intermediate `lv*rv ≤ 100*100 = 10000` since both K bytes are clamped ≤100, so no saturation needed — but the multiply is still guarded). Dim 13 (reserved) untouched.
- `cls_compose_parallel` → `CLS_OK`; `CLS_E_NULL` on any null. time/lib_cite/branch/synth/reflect: max; memory/witness_growth/proof_term: **saturating** sum; K dims 8..12: min. (Fixes the candidate's silent-overflow sums.)
- `cls_le` → `u8` 1 iff `a` is ≤ `b` on additive dims 0..7 **and** ≥ `b` on K dims 8..12 (the mixed product order: cheaper-or-equal in resources, trusted-or-better in K); 0 otherwise or on null. Unsigned compares throughout.
- `cls_first_exceeded` → `CLS_OK` and writes into `*out_dim` the **lowest** dimension index (0..12) on which `declared` violates `bound` (additive: `declared > bound`; K: `declared < bound`); writes `CLS_DIM_NONE (0xFF)` and returns `CLS_OK` if `declared ⊑ bound` (no violation); `CLS_E_NULL` on null. This is what supplies the dimension to `cls_emit_overrun`.
- `cls_admit` → `CLS_OK` iff `cls_le(declared, bound) == 1` (the vector is within budget — admit); `CLS_E_BOUND` if any dimension is exceeded (refuse); `CLS_E_NULL` on null. This is the M19/W43 admission gate — the explicit refusal the gospel prose mandates and the candidate lacks. Pure: no witness emitted here (admission-failure witnessing is the caller's ceremony; overrun-during-execution witnessing is `cls_emit_overrun`).
- `cls_overrun_desc_pack` → `CLS_OK` writing a 24-byte overrun descriptor `(dim:u8 @0, declared:u64 LE @8, observed:u64 LE @16)` into `*out_desc`; `CLS_E_NULL`/`CLS_E_DIM` on null/bad dim. This is the W2 aggregate that lets `cls_emit_overrun` keep ≤4 params.
- `cls_emit_overrun` → returns the published **fragment index as `u64`** is NOT the shape (it returns `i32` status per the gospel signature); on success `CLS_OK` and writes the 32-byte fragment id into `*out_frag_id`; `CLS_E_NULL` on null `operation_id`/`desc`/`out_frag_id`; `CLS_E_EMIT (-4)` if `wh_publish` returns its failure sentinel `0xFFFFFFFFFFFFFFFF`. Builds a schema-conformant V3 COST_OVERRUN payload (see Algorithm) and calls `wh_publish`.

## Constant Namespace
PREFIX = `CLS_` (the gospel's chosen prefix). **Collision check:** `grep -rn "CLS_\|module numera_cost_lattice_synth\|fn cls_" STDLIB/` → **no matches** (module not yet built; prefix free). `grep` of the gospel for `cls_*` symbols outside Module 65's own section → **no matches** (no other module externs my symbols → I block no one on my names). Every module-scope const is `CLS_`-prefixed and globally unique (Trap 2 satisfied).

Module-level constants (every `const NAME : T = V`, all `CLS_`-prefixed):
```
const CLS_OK              : i32 =  0i32
const CLS_E_NULL          : i32 = -1i32
const CLS_E_DIM           : i32 = -2i32
const CLS_E_BOUND         : i32 = -3i32       // admission refused: bound exceeded
const CLS_E_EMIT          : i32 = -4i32       // wh_publish returned its failure sentinel

const CLS_BYTES           : u64 = 64u64       // extended cost vector width

const CLS_DIM_TIME            : u8 = 0u8
const CLS_DIM_MEMORY          : u8 = 1u8
const CLS_DIM_WITNESS_GROWTH  : u8 = 2u8
const CLS_DIM_PROOF_TERM_SIZE : u8 = 3u8
const CLS_DIM_LIB_CITE_DEPTH  : u8 = 4u8
const CLS_DIM_BRANCH_DEPTH    : u8 = 5u8
const CLS_DIM_SYNTH_BUDGET    : u8 = 6u8
const CLS_DIM_REFLECT_BUDGET  : u8 = 7u8

const CLS_K_BASE          : u8 = 8u8          // first K-vector dim index
const CLS_K_END           : u8 = 13u8         // one past last real K dim (8..12 are K)
const CLS_DIM_RESERVED    : u8 = 13u8         // byte 61, untouched by composition
const CLS_DIM_COUNT       : u8 = 14u8         // dims 0..13 addressable
const CLS_DIM_NONE        : u8 = 0xFFu8       // "no dimension exceeded" sentinel
const CLS_K_BYTE0         : u64 = 56u64       // first K byte offset in the vector
const CLS_K_FP_ONE        : u64 = 100u64      // fixed-point scale (K in 0..100)

const CLS_U64_MAX         : u64 = 0xFFFFFFFFFFFFFFFFu64   // saturation ceiling
const CLS_WH_FAIL         : u64 = 0xFFFFFFFFFFFFFFFFu64   // wh_publish failure sentinel

const CLS_V3_SENTINEL     : u8 = 0xE3u8       // V3 extended-payload marker (byte 0)
const CLS_KIND_OVERRUN    : u8 = 0x11u8       // v3_payload_kind COST_OVERRUN

const CLS_DESC_BYTES      : u64 = 24u64       // overrun descriptor: dim + declared + observed
const CLS_OVERRUN_INNER   : u64 = 9u64        // inner payload: dim(1) + magnitude(8)
const CLS_PAYLOAD_BYTES   : u64 = 81u64       // 72-byte V3 header + 9-byte inner
```
Note: `CLS_U64_MAX` and `CLS_WH_FAIL` share the value `U64_MAX` but carry distinct meanings (arithmetic saturation ceiling vs. `wh_publish`'s documented failure return); naming them separately makes the source self-documenting and costs nothing (both fold to the same immediate). `CLS_PAYLOAD_BYTES = 81` = 72 (header: 1 sentinel + 1 kind + 2 reserved + 32 content_address + 32 branch_id + 4 inner_len) + 9 (inner: 1 dim + 8 magnitude); the candidate's `57u64` length was for its non-conformant ad-hoc layout and is replaced.

## Data Structures
All module-scope, statically sized (W8); **no local `var` arrays anywhere** (Trap 7 — this is the fix for the candidate's `payload`, `producer`, `op`, `in_c`, `out_c` locals inside `cls_emit_overrun`).
```
var CLS_PAYLOAD   : [u8; 81]    // V3 COST_OVERRUN payload staging (CLS_PAYLOAD_BYTES)
var CLS_PRODUCER  : [u8; 32]    // zero producer id staging for wh_publish
var CLS_OPID      : [u8; 32]    // zero op id staging for wh_publish
var CLS_IN_C      : [u8; 32]    // in_commit staging (= operation_id, copied)
var CLS_OUT_C     : [u8; 32]    // zero out_commit staging for wh_publish
var CLS_CADDR_IN  : [u8; 96]    // producer||op||operation_id concat, hashed -> content_address
```
Bound justification: every buffer is a fixed-shape scratch area for the single `cls_emit_overrun` emission path. `CLS_PAYLOAD` = 81 B is exactly `CLS_PAYLOAD_BYTES` (the full V3 COST_OVERRUN fragment payload). The four 32-byte id buffers match `IDENT_BYTES = 32` (verified in `identifier.iii`). `CLS_CADDR_IN` = 96 B holds the three 32-byte ids whose Keccak256 is the schema's `content_address` (gospel line 543: `Keccak256(producer || operation_id || input_commitment)`). Total static BSS ≈ 81 + 4*32 + 96 = 305 B — trivial. **Reentrancy:** these are module-global serialized buffers; `cls_emit_overrun` is therefore non-reentrant (acceptable — fragment publication into the witness chain is already a serialized, ordered operation by construction; concurrent emission would violate chain append-order regardless). The pure arithmetic functions (`cls_zero/get/set/compose_*/le/first_exceeded/admit/overrun_desc_pack`) use **no** module-scope state and are fully reentrant. Note: address-of-static (`&CLS_PAYLOAD[0]` etc.) is taken only inside this file (W1/W3).

## Dependencies (externs)
```
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
```
- `identifier.iii` (Module 8, **BUILT** — verified at `STDLIB/iii/numera/identifier.iii`): `ident_zero`, `ident_copy` (both `IDENT_BYTES = 32`), `ident_from_bytes(input, in_len, out)` (Keccak256-based id; itself wraps `keccak256_oneshot` from `keccak256.iii` — the *correct* path).
- `aether/witness_hook.iii` (**BUILT** — verified at `STDLIB/iii/aether/witness_hook.iii`, lines 144-191): `wh_publish` — the real fragment emitter. **12 parameters**, returns the fragment index `u64` (or `0xFFFFFFFFFFFFFFFF` on failure). The single-line extern above is the exact signature.

**Not-yet-built dependencies: 0.** Every extern resolves to an already-built module. (The gospel's `extern ... ws_emit_fragment from "witness_spine.iii"` is replaced; see Gap List #1.)

Relationship (NOT an extern): Module 22 `numera/cost_lattice.iii` is the conceptual base this module "extends," but the two use **incompatible vector representations** (Module 22: six u64 dims, 48 B; this module: 64 B with eight u64 + packed K bytes). The candidate correctly does **not** extern `cl_*`, and this spec keeps them separate (re-implementing the 64-byte ops natively). Module 22's spec (`DOCS/CONVERGENCE-SPECS/cost_lattice.spec.md`) is done; it is itself **not-yet-built**, but it is not a dependency of mine. Downstream consumers (Module 81 `aether/cost_overrun_handler.iii`, the synthesis/reflection engines that declare cost vectors) are not-yet-built but do not block me.

## Algorithm
Determinism (M2) and bit-identity (W5): every operation is fixed-width integer arithmetic over u64/u8 with no floating point, no data-dependent control beyond bounded counted loops, fixed widths `CLS_BYTES = 64`, `CLS_DIM_COUNT = 14`. Identical input bytes → identical output bytes, every run, every CPU. The one impure path (`cls_emit_overrun`) emits a witness fragment whose bytes are a pure function of `(operation_id, dim, declared, observed)` plus the chain's deterministic algebraic-time advance inside `wh_publish` — so the fragment is byte-reproducible from recorded inputs (M10). No ML/heuristics (M3/M4): composition and order are exact algebra over named dimensions. No recursion (W15): all loops are counted with `index < bound`. NIH (M1): hand-rolled little-endian codec, saturating add, fixed-point K product; content_address via the substrate's own `ident_from_bytes`/Keccak256. W14 sentinel-loop discipline; no `break`.

**`cls_zero`** — Null-check `out` (`(out as u64) == 0u64` → `CLS_E_NULL`; 64-bit compare, not a 16-bit-null hazard). Counted loop `i in 0..CLS_BYTES`: `out[i] = 0u8`. Return `CLS_OK`. (Gospel-correct; retained verbatim.)

**`cls_dimension_get`** — Null-check `v` → return `0u64`. If `dim < 8u8`: `base = (dim as u64) * 8u64`; fold eight bytes little-endian: `val = val | ((v[base+k] as u64) << (k*8))` for `k in 0..8`; return `val`. The byte index `base+k` is u64 throughout, and each `v[base+k] as u64` is a single byte (0..255) before the shift, so no u32-in-u64 garbage (Trap 4 N/A — values are u8). If `dim < 14u8` (K dims): `idx = 56u64 + ((dim - 8u8) as u64)`; return `v[idx] as u64` (single byte). Else return `0u64`. (Gospel-correct; retained.)

**`cls_dimension_set`** — Null-check `v` → `CLS_E_NULL`. If `dim < 8u8`: `base = (dim as u64)*8`; store eight bytes `v[base+k] = ((value >> (k*8)) & 0xFFu64) as u8` for `k in 0..8`. **These stores are through a `*u8` (`v` is `*u8`) of a value masked to one byte** — Trap 5 (u32-pointer-store-width) N/A because the pointer element type is u8 and the stored value is `& 0xFF`. Return `CLS_OK`. If `dim < 14u8`: clamp K to fixed-point range — `kv = value & 0xFFu64`; `if kv > CLS_K_FP_ONE { kv = CLS_K_FP_ONE }` (this is the added clamp; W14/no-break, a guarded assignment not a loop); `idx = 56u64 + ((dim-8u8) as u64)`; `v[idx] = kv as u8`; return `CLS_OK`. Else `CLS_E_DIM`. (Candidate retained + K-clamp added.)

**`cls_compose_sequential`** — Null-check `left`/`right`/`out` → `CLS_E_NULL`. Additive dims `d in 0..8` (W14 counted): `lv = cls_dimension_get(left,d)`; `rv = cls_dimension_get(right,d)`; **saturating add** — `sum = lv + rv`; `if sum < lv { sum = CLS_U64_MAX }` (unsigned wrap detection: a true sum is ≥ either addend; `sum < lv` ⇒ wrapped ⇒ saturate). `cls_dimension_set(out, d, sum)`. K dims `k in 8..13` (i.e. `k < CLS_K_END`): `lv = cls_dimension_get(left,k)`; `rv = cls_dimension_get(right,k)`; both ≤100 (clamped on entry), so `prod = (lv * rv) / CLS_K_FP_ONE` cannot overflow (`lv*rv ≤ 10000`). **The division `/ 100u64` uses the literal `CLS_K_FP_ONE` constant, and the operands `lv,rv` are fresh locals from the immediately-preceding `cls_dimension_get` calls** — but to be safe against the param-spill family (Trap 11 is about `%`, this is `/`; still) the dividend `lv*rv` is bound to a local `prodraw` first, then `prod = prodraw / 100u64`, with no function call between the bind and the divide. `cls_dimension_set(out, k, prod)`. Return `CLS_OK`. Note: `out` may alias `left`/`right` — safe because each output dim is written only after both inputs at that dim are read into locals. Dim 13 (reserved) is never written. (Fixes candidate's silent additive overflow.)

**`cls_compose_parallel`** — Null-check all three → `CLS_E_NULL`. Per gospel rules, but **saturating** on the sums:
- TIME, LIB_CITE_DEPTH, BRANCH_DEPTH, SYNTH_BUDGET, REFLECT_BUDGET → `max` (read both into locals `lv,rv`; `m = lv`; `if rv > lv { m = rv }`; set).
- MEMORY, WITNESS_GROWTH, PROOF_TERM_SIZE → **saturating sum** (`sum = lv + rv; if sum < lv { sum = CLS_U64_MAX }`; set).
- K dims `k in 8..13` → `min` (`m = lv; if rv < lv { m = rv }`; set).
Implemented as explicit per-dimension statements (the candidate's flat form is fine; it just needs the saturation guard on the three sums and the K-min loop). All compares unsigned u64. Return `CLS_OK`. (Fixes candidate's silent sum overflow; the candidate's nested `cls_max_u64(cls_dimension_get(...), cls_dimension_get(...))` calls are also refactored so each `cls_dimension_get` result is bound to a named local before the max/min/sum, eliminating any reliance on argument-evaluation order and the single-use-param-spill hazard.)

Helper (file-private, not `@export`): `cls_sat_add(a: u64, b: u64) -> u64` — `let s = a + b; if s < a { return CLS_U64_MAX } return s`. Single-line signature; used by both composers so the saturation logic is written once (NIH-internal, no extern). (The candidate's `cls_max_u64`/`cls_min_u64` file-private helpers are retained, single-line.)

**`cls_le`** — Null-check `a`/`b` → `0u8`. Sentinel-flag loop (W14, the candidate's exact shape, kept because it already drives the loop body by `if ok == 1u8`): additive dims `d in 0..8`: `if ok == 1u8 { av = cls_dimension_get(a,d); bv = cls_dimension_get(b,d); if av > bv { ok = 0u8 } }`. K dims `k in 8..13` (`k < CLS_K_END`): `if ok == 1u8 { ak = cls_dimension_get(a,k); bk = cls_dimension_get(b,k); if ak < bk { ok = 0u8 } }`. Return `ok`. Unsigned compares. This is the mixed product order ⊑: `a ⊑ b` iff `a` is no more expensive on every additive dim and no less trusted on every K dim. Reflexive, antisymmetric, transitive over the (additive ≤) × (K ≥) product — a genuine partial order, hence `cls_admit` below is a sound bound test. (Candidate correct; loop bound corrected to stop K at dim 12 via `CLS_K_END = 13`, matching `cls_compose_*`.)

**`cls_first_exceeded`** — Null-check `declared`/`bound`/`out_dim` → `CLS_E_NULL`. Init `found_dim = CLS_DIM_NONE` and `done = 0u8`. Single counted loop `i in 0..CLS_K_END` (0..13) driven by `done` (W14, the flag drives whether we still look): `if done == 0u8 { dv = cls_dimension_get(declared, i as u8); bv = cls_dimension_get(bound, i as u8); viol = 0u8; if i < 8u64 { if dv > bv { viol = 1u8 } } else { if dv < bv { viol = 1u8 } }; if viol == 1u8 { found_dim = i as u8; done = 1u8 } }`. After the loop, `*out_dim = found_dim`; return `CLS_OK`. The `} else {` is on one line (Trap 8). Lowest-index-first is exact and deterministic (M2/M4). This yields the dimension argument for `cls_emit_overrun`.

**`cls_admit`** — Null-check `declared`/`bound` → `CLS_E_NULL`. `if cls_le(declared, bound) == 1u8 { return CLS_OK }`; `return CLS_E_BOUND`. The M19/W43 admission gate: an operation whose declared 64-byte cost vector is not ⊑ the phase's permitted bound is **refused** (`CLS_E_BOUND`) — the explicit "fail at admission" the gospel mandates (lines 91, 349) and the candidate omits. Pure, no witness (the caller's admission ceremony witnesses the refusal if it chooses). Early-return form (Trap 10 — no mutated checkpoint flag).

**`cls_overrun_desc_pack`** — Null-check `out_desc` → `CLS_E_NULL`; `if dim >= CLS_DIM_COUNT { return CLS_E_DIM }`. Write `out_desc[0] = dim`; `out_desc[8..16] = declared` (8 bytes LE via `((declared >> (k*8)) & 0xFFu64) as u8`, `k in 0..8`, through the `*u8` `out_desc`); `out_desc[16..24] = observed` (same). Bytes 1-7 left as caller-provided padding (caller zeros the 24-byte buffer first; or `cls_overrun_desc_pack` zeros 1-7 explicitly — spec'd to zero them for determinism). Return `CLS_OK`. This is the W2 aggregate (3 scalars → one `*u8`), so `cls_emit_overrun` takes `(operation_id, desc, out_frag_id)` = 3 params ≤ 4.

**`cls_emit_overrun`** — The corrected, schema-conformant emission. Null-check `operation_id`/`desc`/`out_frag_id` → `CLS_E_NULL`. Steps:
1. **Producer/op/commit ids** (module-scope staging, Trap-7 fix): `ident_zero(&CLS_PRODUCER[0])`; `ident_zero(&CLS_OPID[0])`; `ident_copy(operation_id, &CLS_IN_C[0])` (in_commit = the operation whose cost overran); `ident_zero(&CLS_OUT_C[0])`. (A future refinement may set a real producer/op id; zeros are the gospel candidate's choice and are admissible — `wh_publish` accepts them.)
2. **content_address** (M6/M10/schema line 543): build `CLS_CADDR_IN` = `CLS_PRODUCER (32) || CLS_OPID (32) || CLS_IN_C (32)` via three `ident_copy`s into offsets 0/32/64; then `ident_from_bytes(&CLS_CADDR_IN[0], 96u64, &CLS_PAYLOAD[4])` writes the 32-byte Keccak256 directly into the `content_address` field of the staged payload. (Closes the candidate's all-zero-content_address gap; `ident_from_bytes` uses `keccak256_oneshot` from `keccak256.iii` — the correct path, NOT the gospel-defect `keccak256_init/update/final from "keccak.iii"`.)
3. **V3 header** into `CLS_PAYLOAD` per `v3_payload_header` (schema lines 502-510): `CLS_PAYLOAD[0] = CLS_V3_SENTINEL (0xE3)`; `CLS_PAYLOAD[1] = CLS_KIND_OVERRUN (0x11)`; `CLS_PAYLOAD[2] = 0u8`; `CLS_PAYLOAD[3] = 0u8` (reserved); bytes 4-35 = content_address (written in step 2); bytes 36-67 = branch_id = zero (canonical line — a counted zero-loop, or pre-zeroed by a leading `cls_zero`-style clear of `CLS_PAYLOAD`); bytes 68-71 = inner_len = `CLS_OVERRUN_INNER (9)` as u32 LE (`CLS_PAYLOAD[68] = 9u8; 69..71 = 0`).
4. **inner payload** (COST_OVERRUN inner = dimension + magnitude, schema line 531) at bytes 72+: `CLS_PAYLOAD[72] = desc[0]` (the dimension); magnitude = `observed - declared` computed from the descriptor with **saturating subtract** (`obs` at `desc[16..24]`, `dec` at `desc[8..16]`, both folded LE into locals; `mag = obs - dec`; `if obs < dec { mag = 0u64 }` — an overrun has `obs >= dec`, but guard defensively); write `mag` LE into `CLS_PAYLOAD[73..81]`. (The candidate stored *both* declared and observed in an ad-hoc 8/8 layout outside the schema; the schema's inner is dim+magnitude, so this is the conformant form. If both raw values are desired they can be appended and `inner_len` raised — but `CLS_OVERRUN_INNER = 9` matches "dimension and the overrun magnitude" exactly.)
5. **Publish**: `let fi : u64 = wh_publish(&CLS_PRODUCER[0], &CLS_OPID[0], &CLS_IN_C[0], &CLS_OUT_C[0], 0u8 /*revtag: forward*/, 0u8 /*phase*/, 0u16 /*pillar*/, &CLS_OUT_C[0] /*antecedents: none, ptr unused when n_ante=0*/, 0u32 /*n_ante*/, &CLS_PAYLOAD[0], CLS_PAYLOAD_BYTES as u32 /*=81*/, out_frag_id)`. The `payload_len` is passed as **u32** (matching `wh_publish`), value 81.
6. **Status**: `if fi == CLS_WH_FAIL { return CLS_E_EMIT }`; `return CLS_OK`. (`out_frag_id` is filled by `wh_publish` itself; we do not re-copy. We compare against the documented `0xFFFFFFFFFFFFFFFF` failure sentinel by equality — W11-clean since `fi`/`CLS_WH_FAIL` are u64.)

W16/W17 (witness under reversibility, monotonic algebraic time): `wh_publish` advances algebraic time (`at_advance()`) and appends — append-only, forward-tagged (`revtag = 0`); the fragment is the reversible record of the overrun event (M6). No state in this module is destroyed; the emission is additive (M9 reversibility — the chain is append-only and the fragment can be revoked via `wh_revoke`, never rewritten).

Algebraic/lattice laws the implementation must satisfy (M19/M15 contract, KAT targets): `cls_le` is reflexive (`cls_le(x,x)=1`), antisymmetric, transitive; sequential/parallel composition are deterministic and total (saturating ⇒ never overflow ⇒ never wrap to a spuriously-small "cost"); `cls_admit(d,b)=CLS_OK ⇔ cls_le(d,b)=1`; `cls_first_exceeded` names a real violated dimension whenever `cls_le(d,b)=0`. Saturation is the M19 boundedness guarantee at the type level: no composed cost can escape the lattice by integer overflow.

## KAT Vectors (>= 3)
Extended cost vectors are 64-byte buffers; dimensions written as additive[time, memory, witness, proof, libcite, branch, synth, reflect] and K[K, K_synth, K_reflect, K_memo, K_theorem]. All checks are byte-for-byte on the 64-byte output (read back via `cls_dimension_get`) or on the exact i32/u8 return.

1. **Codec + sequential composition (additive add, K fixed-point product).** `cls_zero(a)`; `cls_dimension_set(a, CLS_DIM_TIME, 10); cls_dimension_set(a, CLS_DIM_MEMORY, 200); cls_dimension_set(a, 8/*K*/, 90)`. `cls_dimension_get(a, CLS_DIM_TIME) == 10`, `... MEMORY == 200`, `... K(8) == 90`. `cls_zero(b)`; `set(b,TIME,5); set(b,MEMORY,50); set(b,8,80)`. `cls_compose_sequential(a,b,out)` → `get(out,TIME)==15` (10+5), `get(out,MEMORY)==250` (200+50), `get(out,8)==72` (90*80/100 = 7200/100). K-clamp: `cls_dimension_set(a, 8, 250)` then `get(a,8)==100` (clamped to fixed-point max, not 250&0xFF=250).

2. **Parallel composition + mixed product order.** `a` = TIME 10, MEMORY 200, WITNESS 4, K(8) 90; `b` = TIME 5, MEMORY 50, WITNESS 9, K(8) 80. `cls_compose_parallel(a,b,out)` → `get(out,TIME)==10` (max), `get(out,MEMORY)==250` (sum), `get(out,WITNESS)==13` (sum 4+9), `get(out,8)==80` (min). Order: with `lo` = TIME 5/MEM 50/K 90 and `hi` = TIME 10/MEM 200/K 80, `cls_le(lo,hi)==1` (cheaper on time+mem, more-trusted on K: 90≥80). `cls_le(hi,lo)==0` (hi costs more). `cls_le(lo,lo)==1` (reflexive). Flip trust: `lo2` = TIME 5/MEM 50/K 70, `cls_le(lo2,hi)==0` (K 70 < 80 violates the ≥-on-K rule even though cheaper).

3. **Admission gate + first-exceeded + saturation (M19 boundedness).** `bound` = TIME 100, MEMORY 1000, K(8) 50. `declared_ok` = TIME 80, MEMORY 900, K 60 → `cls_admit(declared_ok, bound) == CLS_OK`; `cls_first_exceeded(declared_ok, bound, &d)` → `CLS_OK`, `d == CLS_DIM_NONE (0xFF)`. `declared_bad` = TIME 80, MEMORY 1200, K 60 → `cls_admit == CLS_E_BOUND`; `cls_first_exceeded(...,&d)` → `d == CLS_DIM_MEMORY (1)` (memory 1200 > 1000). K-violation: `declared_k` = TIME 80, MEMORY 900, K 40 → `cls_first_exceeded` → `d == 8` (K 40 < 50). Saturation: `x` = MEMORY `U64_MAX`; `y` = MEMORY 5; `cls_compose_sequential(x,y,out)` → `get(out,MEMORY) == U64_MAX` (saturated, NOT 4 from wraparound) — the boundedness guarantee.

4. **Schema-conformant COST_OVERRUN emission (the major fix).** Pre: `wh_init(...)` called by the harness. `operation_id` = a fixed 32-byte id (e.g. all-`0xAB`). `cls_overrun_desc_pack(CLS_DIM_MEMORY, 1000u64, 1200u64, desc)` → `CLS_OK`, `desc[0]==1`, `desc[8..16]` = 1000 LE, `desc[16..24]` = 1200 LE. `cls_emit_overrun(operation_id, desc, frag_id)` → `CLS_OK`, `frag_id` non-zero (32 bytes written by `wh_publish`). Verify the published payload via `wh_get_payload(idx, buf, ...)`: `buf[0]==0xE3`, `buf[1]==0x11`, `buf[2]==0 && buf[3]==0`, `buf[4..36]` = `Keccak256(zero32 || zero32 || operation_id)` (recomputable — M10), `buf[36..68]` all zero (branch_id, canonical), `buf[68]==9 && buf[69..72]==0` (inner_len=9), `buf[72]==1` (dim=MEMORY), `buf[73..81]` = 200 LE (magnitude = 1200-1000). Null path: `cls_emit_overrun(0, desc, frag_id) == CLS_E_NULL`. (Contrast the candidate, which would have failed to link — `ws_emit_fragment` is undefined — and even if linked would emit a non-schema payload with no content_address and no inner_len.)

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — exposed (10 public + 3 private signatures). Avoidance: every signature written single-line; verified in Skeleton. (Note: the gospel's *dependency* `wh_publish` is declared multi-line in `witness_hook.iii`, but my **extern** of it is single-line — the extern declaration is mine and is on one line.)
- **Trap 2 (module-level `const` global)** — exposed (24 consts). Avoidance: every const `CLS_`-prefixed; `grep STDLIB/` confirms `CLS_*` collision-free. The gospel's bare `CLS_DIM_TIME`-style names are already prefixed; retained.
- **Trap 3 (signed-ordering SIGSEGV)** — **NOT exposed.** Every ordering compare (`<`, `>`) is on **u64** (cost-dimension values, byte indices, the `wh_publish` return) — unsigned, safe. The only `i32`s are the `CLS_OK/CLS_E_*` constants, used solely as return values and compared by equality (W11). No `i64`/`i32` ordering compare anywhere. The `wh_publish` failure test compares `fi == CLS_WH_FAIL` (u64 equality).
- **Trap 4 (u32-in-u64-slot garbage)** — **NOT exposed.** Dimension/byte indices are computed in u64 (`(dim as u64)*8`, `56u64 + ...`); the `dim` parameter is u8 widened to u64 (a u8 has no high-garbage problem); `payload_len` is the only u32 crossing into `wh_publish` and it is passed as a value (`CLS_PAYLOAD_BYTES as u32`), not used in pointer math. No `(u32 as u64)` feeds pointer arithmetic.
- **Trap 5 (u32 pointer store width)** — **NOT exposed.** Every byte store is through a `*u8` (`out`, `v`, `out_desc`, `&CLS_PAYLOAD[...]`) of a value masked to one byte (`& 0xFFu64) as u8`). No `*u32` stores. (This is the standard little-endian-codec pattern; the candidate already does it correctly for the additive dims.)
- **Trap 6 (nested block comments)** — avoided: no `/* */` nesting; inline notes use `//`.
- **Trap 7 (local `var` arrays)** — **the candidate violates this** (`payload:[u8;64]`, `producer/op/in_c/out_c:[u8;32]` inside `cls_emit_overrun`). **Fix:** all six moved to module-scope (`CLS_PAYLOAD`, `CLS_PRODUCER`, `CLS_OPID`, `CLS_IN_C`, `CLS_OUT_C`, `CLS_CADDR_IN`); `cls_emit_overrun` is documented non-reentrant (acceptable — chain emission is serialized). No other function uses any local array. The arithmetic functions have zero arrays.
- **Trap 8 (`} else {` split)** — touched (`cls_first_exceeded` has an `if/else` for additive-vs-K direction). Avoidance: written `} else {` on one line; elsewhere guard-style early-returns avoid `else` entirely.
- **Trap 9 (em-dash in comment)** — avoided: ASCII `--` only in all comments.
- **Trap 10 (`let mut` checkpoint flag)** — touched by the `ok` flag in `cls_le` and the `done`/`found_dim` flags in `cls_first_exceeded`. Avoidance: where a clean early-return expresses the logic (`cls_admit`, `cls_dimension_set`, null checks), prefer it. Where the loop must complete (`cls_le`, `cls_first_exceeded`), the flag **drives the loop body's guard** (`if ok == 1u8 { ... }` / `if done == 0u8 { ... }`) rather than being a post-hoc boolean — the iiis-1 insertion-sort lesson. `cls_le` keeps the candidate's already-correct `if ok == 1u8` shape.
- **Trap 11 (`a % b` after call)** — **NOT exposed.** No `%` anywhere. The only division is the K fixed-point `prodraw / CLS_K_FP_ONE` in `cls_compose_sequential`, where `prodraw` is a local bound from `lv*rv` (both fresh locals) with **no function call between the bind and the divide**, so the param-spill quotient/stale-divisor family cannot apply. (The candidate's `(lv*rv)/100u64` is in the same statement as the `cls_dimension_get` calls that produced `lv`/`rv`; the spec hoists `lv`/`rv` to named locals first, removing any ambiguity.)
- **Trap 12 (`@specialize *T` stride)** — **NOT exposed.** No `@specialize`; all pointers are concrete `*u8`/`*u64`-free (everything is `*u8` byte-addressed); `p[i]` on a `*u8` strides 1 byte correctly.

## Gap / Fix List
The candidate is PARTIAL. Gaps and fixes (each closed in this spec):

1. **Non-existent extern `ws_emit_fragment from "witness_spine.iii"` (BLOCKER — would fail to link).** Module 12 `witness_spine.iii`'s real API is `ws_init/ws_register/ws_lookup_id/ws_pillar_*/ws_producer_*/ws_operation_*/ws_epoch_*/ws_chain_root/ws_chain_replay_verify` (gospel lines 3047-3093) — there is no `ws_emit_fragment`. The actual fragment emitter is **`wh_publish`** in the already-built `aether/witness_hook.iii` (verified, lines 144-191): 12 params `(producer, opid, in_commit, out_commit, revtag:u8, phase:u8, pillar:u16, antecedents, n_ante:u32, payload, payload_len:u32, out_frag_id) -> u64`. **Fix:** extern `wh_publish`; call it with the full 12-arg list (revtag/phase/pillar=0, n_ante=0). This is the same systemic gospel defect found in `numera/computation_graph.iii` (gospel line 16314 calls the identical fiction `ws_emit_fragment(..., payload_len:u64) -> i32`) — flagged for the other agents.
2. **Wrong `payload_len` width + wrong return type in the candidate's emit call.** The fiction signature used `payload_len: u64` and `-> i32`; `wh_publish` takes `payload_len: u32` and returns `u64` (fragment index, sentinel `0xFFFF...FF` on failure). **Fix:** pass `CLS_PAYLOAD_BYTES as u32`; map the u64 return to `CLS_OK`/`CLS_E_EMIT` by equality with `CLS_WH_FAIL`.
3. **Non-conformant COST_OVERRUN payload (would be unparseable by a V3 verifier).** The candidate's payload is an ad-hoc `[0xE3, 0x11, <6 zero>, op_id@8..40, dim@40, declared@41..49, observed@49..57]` with `payload_len=57`. The V3 schema (gospel lines 502-510) requires `v3_payload_header` = sentinel(1) + kind(1) + reserved(2) + **content_address(32)** + **branch_id(32)** + **inner_len(4)** + inner, and COST_OVERRUN inner = dimension(1) + magnitude(8) (line 531). The candidate omits content_address, branch_id, and inner_len entirely and mislocates op_id. **Fix:** build the exact 72-byte header + 9-byte inner (total `CLS_PAYLOAD_BYTES = 81`); content_address = `Keccak256(producer||op||operation_id)` via `ident_from_bytes`; branch_id = 0 (canonical); inner_len = 9; inner = `[dim, magnitude_LE]`, magnitude = saturating `observed - declared`.
4. **Trap-7 violation: five local `var` arrays in `cls_emit_overrun`.** **Fix:** six module-scope staging buffers (`CLS_PAYLOAD/PRODUCER/OPID/IN_C/OUT_C/CADDR_IN`); function documented non-reentrant (chain emission is serialized — acceptable, like `identifier.iii`'s `IDENT_OUT` scratch pattern).
5. **W2 violation: `cls_emit_overrun(operation_id, dim, declared, observed, out_frag_id)` = 5 params.** **Fix:** aggregate `(dim, declared, observed)` into a 24-byte descriptor via the new `cls_overrun_desc_pack`, giving `cls_emit_overrun(operation_id, desc, out_frag_id)` = 3 params.
6. **M15/M19 totality bug: silent u64 overflow in composition.** `cls_compose_sequential`'s additive `lv+rv` and `cls_compose_parallel`'s `memory`/`witness`/`proof_term` sums can wrap, making a huge composed cost read as tiny — defeating the module's entire boundedness purpose (a wrapped cost would pass `cls_admit`). **Fix:** saturating add (`cls_sat_add` → `CLS_U64_MAX` on wrap) on every additive sum. The K fixed-point product cannot overflow once K is clamped ≤100.
7. **Missing admission gate (the module's named mandate M19/W43).** The candidate has the order check `cls_le` but no function that *refuses* an over-budget vector or names the violated dimension — yet the module's whole point (gospel lines 91, 349; "no synthesis output beyond cost lattice") is admission refusal. **Fix:** add `cls_admit` (returns `CLS_E_BOUND` when `!cls_le`) and `cls_first_exceeded` (names the lowest violated dimension, feeding the overrun fragment).
8. **Unclamped K vector (silent-corruption path).** `cls_dimension_set` masks K to `& 0xFF`, admitting values 101..255 into a field the order semantics assume is 0..100; a K of 200 makes `cls_le`'s ≥-on-K test meaningless. **Fix:** clamp K to `CLS_K_FP_ONE (100)` in `cls_dimension_set`.
9. **Absent content_address (M6/M10 + schema).** Gospel line 543 mandates content_address be populated on every V3 fragment; the candidate emits all-zero. **Fix:** compute `Keccak256(producer||op||operation_id)` via `ident_from_bytes` (correct keccak path) into the header. This also satisfies M10 (the fragment is byte-recomputable from `operation_id`).

Mandate posture after fixes: M1 (only `identifier.iii` + `witness_hook.iii` externs, both pure III; hand-rolled codec/saturation/fixed-point) OK; M2/W5 (fixed-width integer, no FP, counted loops; emission byte-reproducible) OK; M3/M4 (named dimensions, exact algebra, lowest-index-first violation — no learning/guessing) OK; M5 (append-only emission; no destructive state → no bricking) OK; M6/M10 (COST_OVERRUN fragment chains by hash via `wh_publish`; content_address + payload recomputable from `(operation_id, dim, declared, observed)`) OK; M7 (R0) OK; M8 (pure compute + an append-only witness publish — no privileged capability needed; `wh_publish` is the substrate's own ungated emit) OK; M9 (composition/order pure; emission additive+revocable, never rewritten) OK; M11/M18 (this module carries no proof terms — N/A; it supplies the cost bound that proof-carrying modules cite) noted; M15 (saturating composition total over u64; K product bounded by clamp) OK; **M19 (the module IS the synthesis cost-boundedness mechanism — saturating ops + admission gate + overrun emission)** OK; W43 (admission refusal is `cls_admit`) OK. W2 (≤4 params on every fn — repaired) OK; W8 (static buffers, justified) OK; W9/W10/W11/W12 (negative-i32 errors, u8 predicates, equality-only signed compares, status on every public fn) OK; W13 (≤20 locals — every fn well under) OK; W14 (sentinel/counter loops, no `break`) OK; W15 (no recursion) OK; W16/W17 (forward-tagged append under monotonic algebraic time) OK.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/cost_lattice_synth.iii
 *
 * III STDLIB - numera::cost_lattice_synth
 *
 * The V3 cost lattice extension. A 64-byte extended cost vector:
 *   bytes 0..55  : eight u64 little-endian additive/max dimensions
 *     0 time  1 memory  2 witness_growth  3 proof_term_size
 *     4 lib_cite_depth  5 branch_depth  6 synth_budget  7 reflect_budget
 *   bytes 56..60 : five K-vector components (u8 fixed-point 0..100)
 *     K, K_synth, K_reflect, K_memo, K_theorem  (dims 8..12)
 *   byte  61     : reserved (dim 13)   bytes 62..63 : reserved
 *
 * Operations:
 *   sequential composition : additive add (saturating), K product/100
 *   parallel   composition : time/budgets max, memory/witness/proof sum
 *                            (saturating), K min
 *   order cls_le           : <= on additive dims, >= on K dims
 *   admission cls_admit     : refuse a declared vector not <= the bound
 *   cls_emit_overrun        : publish a schema-conformant COST_OVERRUN
 *                            fragment via the witness hook
 *
 * Determinism: fixed-width integer only, no FP, counted loops, no
 * recursion. Saturating composition is the M19 boundedness guarantee:
 * no composed cost escapes the lattice by overflow. W43 binds (no
 * synthesis output beyond the cost lattice); M19 binds.
 *
 * Hexad: kind_essence.  Ring: R0.  K: 1.00.
 *
 * NIH: depends on identifier.iii (ids + content_address Keccak256) and
 * aether/witness_hook.iii (wh_publish). The base numera/cost_lattice.iii
 * uses a different 6-u64 representation and is NOT externed here.
 */

module numera_cost_lattice_synth

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

const CLS_OK              : i32 =  0i32
const CLS_E_NULL          : i32 = -1i32
const CLS_E_DIM           : i32 = -2i32
const CLS_E_BOUND         : i32 = -3i32
const CLS_E_EMIT          : i32 = -4i32

const CLS_BYTES           : u64 = 64u64

const CLS_DIM_TIME            : u8 = 0u8
const CLS_DIM_MEMORY          : u8 = 1u8
const CLS_DIM_WITNESS_GROWTH  : u8 = 2u8
const CLS_DIM_PROOF_TERM_SIZE : u8 = 3u8
const CLS_DIM_LIB_CITE_DEPTH  : u8 = 4u8
const CLS_DIM_BRANCH_DEPTH    : u8 = 5u8
const CLS_DIM_SYNTH_BUDGET    : u8 = 6u8
const CLS_DIM_REFLECT_BUDGET  : u8 = 7u8

const CLS_K_BASE          : u8  = 8u8
const CLS_K_END           : u8  = 13u8
const CLS_DIM_RESERVED    : u8  = 13u8
const CLS_DIM_COUNT       : u8  = 14u8
const CLS_DIM_NONE        : u8  = 0xFFu8
const CLS_K_BYTE0         : u64 = 56u64
const CLS_K_FP_ONE        : u64 = 100u64

const CLS_U64_MAX         : u64 = 0xFFFFFFFFFFFFFFFFu64
const CLS_WH_FAIL         : u64 = 0xFFFFFFFFFFFFFFFFu64

const CLS_V3_SENTINEL     : u8  = 0xE3u8
const CLS_KIND_OVERRUN    : u8  = 0x11u8

const CLS_DESC_BYTES      : u64 = 24u64
const CLS_OVERRUN_INNER   : u64 = 9u64
const CLS_PAYLOAD_BYTES   : u64 = 81u64

// module-scope staging (Trap-7 fix; cls_emit_overrun non-reentrant)
var CLS_PAYLOAD   : [u8; 81]
var CLS_PRODUCER  : [u8; 32]
var CLS_OPID      : [u8; 32]
var CLS_IN_C      : [u8; 32]
var CLS_OUT_C     : [u8; 32]
var CLS_CADDR_IN  : [u8; 96]

// --- file-private helpers (single-line; not @export) ---

fn cls_sat_add(a: u64, b: u64) -> u64 {
    // TODO: body per Algorithm -- s=a+b; if s<a return CLS_U64_MAX; else s.
}

fn cls_max_u64(a: u64, b: u64) -> u64 {
    // TODO: body -- if a>b return a; return b.
}

fn cls_min_u64(a: u64, b: u64) -> u64 {
    // TODO: body -- if a<b return a; return b.
}

// --- dimension codec ---

fn cls_zero(out: *u8) -> i32 @export {
    // TODO: body per Algorithm cls_zero -- null-check; zero 64 bytes.
}

fn cls_dimension_get(v: *u8, dim: u8) -> u64 @export {
    // TODO: body per Algorithm cls_dimension_get -- additive dims 0..7
    // fold 8 LE bytes at dim*8; K dims 8..13 read byte 56+(dim-8); else 0.
}

fn cls_dimension_set(v: *u8, dim: u8, value: u64) -> i32 @export {
    // TODO: body per Algorithm cls_dimension_set -- additive: store 8 LE
    // bytes; K: clamp value to CLS_K_FP_ONE then store one byte; else E_DIM.
}

// --- composition ---

fn cls_compose_sequential(left: *u8, right: *u8, out: *u8) -> i32 @export {
    // TODO: body per Algorithm -- additive dims saturating-add (cls_sat_add);
    // K dims 8..12 fixed-point product (lv*rv)/100 with hoisted locals.
}

fn cls_compose_parallel(left: *u8, right: *u8, out: *u8) -> i32 @export {
    // TODO: body per Algorithm -- time/libcite/branch/synth/reflect=max;
    // memory/witness/proof=saturating sum; K dims 8..12=min. Hoist locals.
}

// --- order + admission ---

fn cls_le(a: *u8, b: *u8) -> u8 @export {
    // TODO: body per Algorithm cls_le -- additive <= AND K >= ; ok-flag
    // drives the loop body guard (W14, no break); unsigned compares.
}

fn cls_first_exceeded(declared: *u8, bound: *u8, out_dim: *u8) -> i32 @export {
    // TODO: body per Algorithm -- lowest dim where additive declared>bound
    // or K declared<bound; CLS_DIM_NONE if none. done-flag drives loop.
}

fn cls_admit(declared: *u8, bound: *u8) -> i32 @export {
    // TODO: body per Algorithm cls_admit -- CLS_OK iff cls_le==1 else
    // CLS_E_BOUND (the M19/W43 admission gate). Early-return form.
}

// --- overrun witness emission ---

fn cls_overrun_desc_pack(dim: u8, declared: u64, observed: u64, out_desc: *u8) -> i32 @export {
    // TODO: body per Algorithm -- 24-byte desc: dim@0 (zero 1..7),
    // declared LE @8..16, observed LE @16..24. Validates dim<CLS_DIM_COUNT.
}

fn cls_emit_overrun(operation_id: *u8, desc: *u8, out_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm cls_emit_overrun --
    //  1. zero CLS_PAYLOAD; stage producer/op/out_c=zero, in_c=operation_id
    //  2. content_address = ident_from_bytes(producer||op||op_id, 96) -> PAYLOAD[4]
    //  3. header: [0]=0xE3 [1]=0x11 [2..4]=0 [4..36]=caddr [36..68]=0 [68]=9 [69..72]=0
    //  4. inner: [72]=desc[0] (dim); [73..81]=saturating(observed-declared) LE
    //  5. fi = wh_publish(producer,op,in_c,out_c,0u8,0u8,0u16,out_c,0u32,
    //                     &CLS_PAYLOAD[0], CLS_PAYLOAD_BYTES as u32, out_frag_id)
    //  6. if fi == CLS_WH_FAIL return CLS_E_EMIT; return CLS_OK.
}
```
