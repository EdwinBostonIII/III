# M5 omnia/sovval.iii — Implementation Spec (station-1 DESIGN)

> ## ⚠ SUPERSEDED BY IMPLEMENTATION (2026-05-25) — read `STDLIB/iii/omnia/sovval.iii`, not this
> The **USER is implementing M5**; `omnia/sovval.iii` exists, **compiles clean** (`--compile-only`
> OK), and carries a full falsifier `sv_selftest` (8 cases, real negative arms). **The `.iii` is
> the authority.** The implementation refined this design-ahead spec as follows:
> - **112-byte cell**, not 136: `[0..16)` payload (M4 `ucell`) · `[16..24)` **hexad `u64`** (not u16)
>   · `[24..32)` **`status` `u64`** · `[32..64)` witness (cad32) · `[64..112)` cost `u64[6]`.
> - **Refused is a `status` field** (`SV_STATUS_REFUSED=1`) + return code **`SV_REFUSED=1`** — not
>   negative `SV_REFUSED_*` codes; `out` *is* written (with status=REFUSED), not left unwritten.
> - **`sv_op(op:u32,a,b,out)`** (op-tagged: SV_ADD=0/SV_MUL=2), not `(a,b,req,out)`.
> - **`sv_make(payload_cell:*u8, hexad:u64, cost:*u64, out)`** — payload_cell is an M4 ucell.
> - Witness = **`cad_oneshot(0, payload‖hexad‖cost, 72, sv_witness_ptr)`** (not `ca_compute`).
> - Refuse-on-non-reachable-hexad (`iii_hexad_reachable`) + over-K-cost (`cl_le_product` vs
>   `SV_BUDGET`) enforced at **`sv_make` (the boundary)**; `sv_op` *preserves* the invariant
>   (closure: compose6(reachable,reachable)=reachable, join(≤B,≤B)≤B) **and** has a white-box KAT
>   arm proving its cost-Refuse gate fires.
> - The **10-field `SovMorphism` contract below is the *conceptual* contract** the `.iii` realizes
>   concretely (payload/hexad/cost/witness/Refused, directly); morphism-registration (`cat_add_morphism`)
>   + `@sovereign` are **migrations 7/3** — documented compiler-level hooks, not this `.iii`.
>
> The text below is the **original design-ahead spec** — kept for grounding + the SovMorphism
> rationale, but **do not implement from it**; the `.iii` is final.

## Verdict
**NET-NEW (design).** Does not exist today — values cross boundaries as raw scalars/pointers,
and safety/provenance/uncertainty/cost are re-derived at each boundary. This is the **currency
of the whole system** and the keystone the apotheosis turns on. This spec is the station-1
design grounded **verbatim in `DOCS/III-APOTHEOSIS.md` Module 5 + M5·D1 + "The Move"**; the
body is the overhaul proper (USER's domain). Externs pinned to real providers (§VII); every
guarantee carries a negative-arm KAT (Directive 3). Depends on M4 (`uncertainty`, sibling
net-new — its `unc_` payload arithmetic must land first; both are net-new in registry §A).

## Purpose
`omnia::sovval` promotes one indivisible value to **the** currency:
`SovVal = { payload : Known|Gap (M4) | hexad : u16 (M3) | witness : FragId (M6) | cost : 6-dim
(M13) }`, with a single total **`sv_op`** that composes payloads (sound gap arithmetic, M4),
composes hexads (`iii_hexad_compose6`, **refusing a non-reachable result as `Refused`**, M3),
joins cost (`cl_join`, **refusing over-budget as `Refused`**, M13), and **emits a witness**
(`wh_publish`, M6). Gap-totality, safety-typing, provenance, and cost stop being *behaviors* and
become *what a value is* — so non-interference, gap-containment, and the K-floor are
**structural**. The only thing crossing any `@sovereign` boundary is a SovVal (H1).

`sv_op` is the **generating morphism (M12)** every other Sovereign operation specializes — the
archetype, *not* an identity arrow (Premise-Ledger T2). Its associativity is an XII confluence
fact registered with `cat_check_assoc` and ratified as a constitutional clause (M10), never
assumed.
- **Hexad:** `kind_substance` (it is the value/substance layer). **Ring:** R0. **K:** 1.00
  (pure; deterministic; the only externs are the four facet providers + `cad` naming).

## Public API
```
fn sv_init(grant_req: *u8, cap: u64) -> i32 @export
fn sv_make(req: *u8, out: *u8) -> i32 @export
fn sv_op(a: *u8, b: *u8, req: *u8, out: *u8) -> i32 @export
fn sv_payload(v: *u8, out_uv: *u8) -> i32 @export
fn sv_hexad(v: *u8) -> u16 @export
fn sv_witness(v: *u8, out_frag: *u8) -> i32 @export
fn sv_cost(v: *u8, out_cost: *u64) -> i32 @export
fn sv_certificate(v: *u8, out_cert: *u8) -> i32 @export
fn sv_is_refused(rc: i32) -> u8 @export
fn sv_selftest() -> u64 @export
```

Return-status conventions (W9/W12):
- `sv_init` → `i32`: `SV_OK` or `SV_E_CAP` (grant capability lacks rights).
- `sv_make` → `i32`: `SV_OK` (and `out` written) or **`SV_REFUSED_HEXAD`** (the requested hexad
  is non-reachable — a bricking value is *unconstructable*, M3) or `SV_E_BAD`/`SV_E_WITNESS`.
- `sv_op` → `i32`: `SV_OK` or **`SV_REFUSED_HEXAD`** (composed hexad non-reachable) or
  **`SV_REFUSED_COST`** (joined cost exceeds the active grant — the K-floor) or `SV_E_*`. On any
  `REFUSED`/`E_`, **`out` is left unwritten** (the refusal is the absence of a value, not a value).
- accessors → `i32` ok/`SV_E_BAD`; `sv_hexad` → `u16`; `sv_is_refused` → `u8` (1 iff
  `rc ∈ {SV_REFUSED_HEXAD, SV_REFUSED_COST}`).
- `sv_selftest` → `u64`: `99u64` = pass; else failing-assertion ordinal.

**`Refused` is a first-class outcome, not an error.** Pre-M9 it is a distinguished return code +
an unwritten `out`. **Post-migration-2** (SovVal-as-CIC-inductive) the *same* refusal becomes a
**type error** (`iii_term_typecheck` → `TYPE_PROOF_007_*`): a bricking/over-K composition stops
compiling. The runtime `SV_REFUSED_*` codes are the pre-inductive realization of that type-level
`Refused`; the migration replaces the check site, not the semantics.

**W2 note:** `sv_make`/`sv_op` fold their multi-field inputs behind `req: *u8` aggregates
(layouts below). `sv_op` is `(a, b, req, out)` = 4; nothing exceeds 4.

## Constant Namespace
**PREFIX = `SV_`** — grep of `STDLIB/` for `(fn|const) (sv_|SV_|sov_|SOV_)` returned **zero hits
(2026-05-25)**: the namespace is entirely free (registry §A).

```
const SV_OK             : i32 =  0i32
const SV_E_BAD          : i32 = -1i32
const SV_E_CAP          : i32 = -2i32
const SV_E_WITNESS      : i32 = -3i32
const SV_REFUSED_HEXAD  : i32 = -10i32   // composed/requested hexad is non-reachable (M3, bricking)
const SV_REFUSED_COST   : i32 = -11i32   // joined cost exceeds the active K-floor grant (M13)

const SV_BYTES          : u64 = 136u64   // a SovVal record (layout in Data Structures)
const SV_COST_DIM       : u64 = 6u64     // microarch cost dimensions (M13)
const SV_PILLAR         : u16 = 5u16     // sovval/value-layer witness pillar
const SV_PHASE          : u8  = 5u8      // value-composition phase tag
const SV_REVTAG         : u8  = 1u8      // composition is reversible-by-derivation (M8)
const SV_OP_COMPOSE     : u8  = 0u8      // sv_op op-tags (the payload arithmetic selector, M4)
const SV_OP_ADD         : u8  = 1u8
const SV_OP_SUB         : u8  = 2u8
const SV_OP_MUL         : u8  = 3u8
const SV_OP_DIV         : u8  = 4u8
const SV_REQUIRED_RIGHTS: u64 = 0x0800u64 // CAP_RIGHT_ATTEST (compose emits an attested witness)
```

## Data Structures
Module-scope (Trap 7); Trap-19 frugal `[u64;…]` for wide byte arrays.

**SovVal record — `SV_BYTES = 136` logical bytes (the unit of currency):**
```
[0..48)    payload : UV (M4 -- tag(1)|pad(7)|concrete(8 LE)|gap_id(32))
[48..50)   hexad   : u16 LE     (M3 -- the 6-trit packed safety type, 0..728)
[50..56)   pad     : 0
[56..88)   witness : [u8;32]    (M6 -- the wh_publish FragId of this value's minting)
[88..136)  cost    : [u64;6] LE (M13 -- latency|throughput|regpress|icache|dcache|energy)
```

**`req` for `sv_make`:** `payload UV(48) ‖ hexad u16(2) ‖ pad(6) ‖ cost [u64;6](48)` = 104 B
(the producer/op provenance ids are module constants set at `sv_init`).

**`req` for `sv_op`:** `op_tag u8(1) ‖ pad(7) ‖ cost_grant [u64;6](48)` = 56 B. The `op_tag`
selects the M4 payload arithmetic (`unc_add|sub|mul|div`, or `SV_OP_COMPOSE` for the categorical
compose with no payload arithmetic). The optional per-call `cost_grant` overrides the module
grant (else the `sv_init` grant applies).

```
var SV_PRODUCER : [u8; 32]      // ident_from_bytes("omnia::sovval")
var SV_OPID     : [u8; 32]      // ident_from_bytes("omnia::sovval::op")
var SV_GRANT    : [u64; 6]      // active K-floor cost grant (set at sv_init)
var SV_CAP      : u64 = 0u64    // attest capability id
var SV_INITED   : u8  = 0u8

var SV_IN_C     : [u8; 32]      // in_commit = cad(a || b)
var SV_OUT_C    : [u8; 32]      // out_commit = cad(result facets)
var SV_ANTE     : [u8; 64]      // a.witness || b.witness (the two input frag-ids; M6 chaining)
var SV_TMPCOST  : [u64; 6]      // cl_join scratch
var SV_TMPHEX   : u16 = 0u16

var SV_T_A      : [u8; 136]     // self-test SovVals
var SV_T_B      : [u8; 136]
var SV_T_R      : [u8; 136]
var SV_T_REQ    : [u8; 128]
var SV_T_CERT   : [u8; 32]
```

**Bounds (W8):** the SovVal record is fixed-width; the only table is the witness chain (owned by
M6, not here). `SV_ANTE = 64` = exactly two 32-byte input frag-ids.

**Reentrancy (Trap 7):** module-scope compose scratch → non-reentrant; correct for the
serialized value layer (witness emission is single-writer through `wh_publish`/`at_advance`).

## The Move — the `SovMorphism` contract (authoritative, from apotheosis "The Move")
Every operation crossing a `@sovereign` boundary is **one arrow in the one category** whose
objects are SovVal-types; being such an arrow *forces* the seven entailments. `sv_op` is the
**generating** instance — every other Sovereign operation is "do what `sv_op` does, for your
arrow." The 10-field record (a CIC dependent record post-migration-2, so legality is a
*typecheck*, not an audit):

| Field | Obligation | Module | How `sv_op` realizes it |
|---|---|---|---|
| `apply : A → B` | the operation (internal scratch free; only the boundary binds) | — | the payload/hexad/cost composition |
| `payload_law` | propagate `Known`/`Gap` with sound gap arithmetic | M4 | `unc_<op>(a.payload, b.payload)` |
| `hexad_law` | `hexad(apply x)` reachable, else type-level `Refused` | M3 | `iii_hexad_compose6` → `iii_hexad_reachable` → `SV_REFUSED_HEXAD` |
| `cost_law` | `cost = lattice-join`, `≤` grant, else `Refused` | M13 | `cl_join` → `cl_le_product(.,grant)` → `SV_REFUSED_COST` |
| `witness` | a `FragId` emitted per application | M6 | `wh_publish(...)` → `out.witness` |
| `morphism_id` | `cad(src ‖ dst ‖ op)`, registered via `cat_add_morphism` | M1/M12 | `cat_add_morphism(src,dst,op,&id)` |
| `falsifier` | a constructed bad input + the verdict it MUST turn red | M10 | KAT-2/KAT-3 negative arms (non-reachable / over-K) |
| `inverse` | `Reversible(derived)` \| `Compromise(LO\|MED)` \| `Unrepresentable` | M8 | `SV_REVTAG=1` (compose is reversible-by-derivation) |
| `certificate` | a re-checkable proof handed to the consumer | M16 | `sv_certificate` = `cad` over the result facets |
| `defer` | `(obligation, reason, safety_falsifier)`; **empty iff Final** | M10 | this spec's defer-ledger row (below) |

`@sovereign fn f(a:A) -> B` elaborates to `f : SovMorphism(A,B)`; `sema`'s D-gate (M18·D1) emits
**`III_NONSOVEREIGN_BOUNDARY`** if `A` or `B` is a raw type at the boundary — **migration 3,
checker-side** (not this module; this module supplies the *value*, the checker enforces the
*boundary*). Reserved negative test: `711_neg_nonsovereign_boundary.iii` (registry §C).
`@variant` (the payload `Known|Gap` tagged union) has a corpus precedent —
`STDLIB/corpus/110_modifier_variant.iii` — so its codegen is not invented.

**`defer` (live, per The Move's ninth field).** `sv_op`'s `defer` ledger today:
`{ hexad_law : "runtime reach gate, not yet ι-reduction" : migration-2 (SovVal-as-CIC-inductive) }`,
`{ morphism_id : "registered but assoc not yet a ratified clause" : migration-7 + migration-6 }`.
Both carry their safety-falsifier (KAT-2 and KAT-4). The ledger is **empty iff Final** — these
two entries are exactly the critical-path migrations this value waits on.

## Dependencies (externs)
Pinned to real providers (registry §E), 2026-05-25.

| Symbol | Signature | Provider | Built? |
|---|---|---|---|
| `iii_hexad_compose6` | `(a:u16, b:u16) -> u16` | `omnia/hexad_algebra.iii:88` | **BUILT** ✓ |
| `iii_hexad_reachable` | `(h:u16) -> u8` | `omnia/hexad_reach.iii:76` | **BUILT** ✓ |
| `iii_hexad_pack6` | `(pillars_addr:u64) -> u16` | `omnia/hexad_algebra.iii:45` | **BUILT** ✓ |
| `cl_join` | `(c:*u64, cp:*u64, out:*u64) -> i32` | `numera/cost_lattice.iii:222` | **BUILT** ✓ |
| `cl_le_product` | `(c:*u64, cp:*u64) -> u8` | `numera/cost_lattice.iii:254` | **BUILT** ✓ |
| `wh_publish` | 12-param (see below) `-> u64` | `aether/witness_hook.iii:144` | **BUILT** ✓ |
| `cat_add_morphism` | `(src:u32, dst:u32, op:*u8, out_id:*u8) -> u32` | `numera/category.iii:285` | **BUILT** ✓ |
| `cat_check_assoc` | `(f_slot:u32, g_slot:u32, h_slot:u32) -> u8` | `numera/category.iii:369` | **BUILT** ✓ |
| `ca_compute` | `(producer:*u8, operation:*u8, input_commit:*u8, out:*u8) -> i32` | `numera/content_addr.iii:31` (→ `cad` post-M1) | **BUILT** ✓ |
| `ca_compose` | `(left:*u8, right:*u8, out:*u8) -> i32` | `numera/content_addr.iii:35` (→ `cad` post-M1) | **BUILT** ✓ |
| `ident_from_bytes` | `(input:*u8, in_len:u64, out:*u8) -> i32` | `numera/identifier.iii` | **BUILT** ✓ |
| `unc_known`/`unc_add`/`unc_sub`/`unc_mul`/`unc_div`/`unc_is_known` | see `uncertainty.spec.md` | `numera/uncertainty.iii` (M4) | **NOT-YET-BUILT** ✗ (sibling) |

`wh_publish`'s true 12-param/5-line signature (registry §E calibration — it compiles + its
replay KAT 633 is green, so the multi-line/`>4-param` form is safe for this *existing* extern;
new modules still follow W2 + single-line):
```
fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8,
              out_commit: *u8, revtag: u8, phase: u8, pillar: u16,
              antecedents: *u8, n_ante: u32,
              payload: *u8, payload_len: u32,
              out_frag_id: *u8) -> u64
```

**Not-yet-built dep for the wave scheduler:** `numera/uncertainty.iii` (M4) MUST land before
`sovval` links (its `unc_` payload arithmetic is the `payload_law`). Both are the two net-new
core modules (registry §A); build order M4 → M5.

## Algorithm
Determinism (M2): the composed hexad is a pure function of the inputs (`iii_hexad_compose6`); the
cost is the lattice join (`cl_join`); the witness id keys on the payload content-address (M6·D1
bug-#6 discipline — re-verification keys on payload `cad`, `at_time` excluded). No float, no
inference. No recursion (W15). Bit-identity (W5): hexad/cost written LE byte-by-byte through
`*u8` (Trap 5); the u16 hexad never stored through a `*u16` (Trap-5 width).

### `sv_init(grant_req, cap)`
1. `ident_from_bytes("omnia::sovval", 13, &SV_PRODUCER)`, `ident_from_bytes("omnia::sovval::op",
   17, &SV_OPID)` (string-literal byte lengths exact).
2. **M8 gate:** `if cap_verify_rights(cap, SV_REQUIRED_RIGHTS) != 1u8 { return SV_E_CAP }` (a
   composing producer attests, so it needs `CAP_RIGHT_ATTEST`). Store `SV_CAP = cap`.
3. Copy the 6 grant cost dims from `grant_req` LE into `SV_GRANT`. Set `SV_INITED = 1u8`; `SV_OK`.

### `sv_make(req, out)`
1. Guard inited. Read `payload UV` (48 B), `hexad` (LE u16), `cost` (6× LE u64) from `req`.
2. **`hexad_law` at construction:** `if iii_hexad_reachable(hexad) == 0u8 { return
   SV_REFUSED_HEXAD }` — a bricking value is *unconstructable* (M3), not merely flagged.
3. **`cost_law`:** `if cl_le_product(&cost, &SV_GRANT) != 1u8 { return SV_REFUSED_COST }` (the
   value's own cost must already sit under the K-floor).
4. **`witness`:** `in_commit = wh_chain_root`; `out_commit = ca_compute(payload ‖ hexad ‖ cost)`;
   `frag = wh_publish(&SV_PRODUCER, &SV_OPID, in_c, out_c, SV_REVTAG, SV_PHASE, SV_PILLAR, out_c,
   0u32, req, 104u32, &witness_sink)`; if `frag == 0xFFFF…` return `SV_E_WITNESS`.
5. Assemble the 136-byte SovVal into `out` (payload|hexad|witness=witness_sink|cost). `SV_OK`.

### `sv_op(a, b, req, out)` — the generating morphism
1. Guard inited; read `op_tag` + optional `cost_grant` from `req` (else `SV_GRANT`).
2. **`payload_law`:** select by `op_tag` — `unc_<op>(a.payload, b.payload, &r_payload)` (or, for
   `SV_OP_COMPOSE`, the categorical compose: `r_payload = a.payload`-with-`b` provenance). Sound
   gap arithmetic per M4 (gap propagates; `0·unknown→Known(0)`; `÷0→gap`).
3. **`hexad_law`:** `h = iii_hexad_compose6(a.hexad, b.hexad)`; `if iii_hexad_reachable(h) == 0u8
   { return SV_REFUSED_HEXAD }` (leave `out` unwritten — the bricking composition is refused).
4. **`cost_law`:** `cl_join(&a.cost, &b.cost, &SV_TMPCOST)`; `if cl_le_product(&SV_TMPCOST,
   &grant) != 1u8 { return SV_REFUSED_COST }` (over-K refused, leave `out` unwritten).
5. **`witness`:** `SV_ANTE[0..32) = a.witness`, `SV_ANTE[32..64) = b.witness` (M6 chaining — the
   composition cites both inputs); `in_c = ca_compose(a.witness, b.witness)`; `out_c =
   ca_compute(r_payload ‖ h ‖ SV_TMPCOST)`; `frag = wh_publish(..., &SV_ANTE, 2u32, ...)`.
6. **`morphism_id` (mig 7):** `cat_add_morphism(src_type, dst_type, &op_word, &morph_id)` — the
   op-word is the flat primitive-op sequence (M12·D1 associative-by-construction; never a nested
   hash). Registration makes step 7's `cat_check_assoc` meaningful.
7. Assemble the result SovVal (r_payload | h | frag | SV_TMPCOST) into `out`. `SV_OK`.

### accessors / `sv_certificate`
`sv_payload`/`sv_hexad`/`sv_witness`/`sv_cost` read the fixed offsets (LE byte-by-byte).
`sv_certificate(v, out_cert)` = `ca_compute(payload ‖ hexad ‖ witness ‖ cost)` — the
re-checkable certificate (M16/H10): a consumer recomputes it from `v`'s facets and compares,
**never trusting** the producer.

## KAT Vectors (≥ 3, every guarantee with a negative arm — Directive 3)
`sv_selftest` → `99u64` on pass. Corpus block **710–719** (registry §C). Runs once M4
(`uncertainty.iii`) lands; until then this is the byte-exact contract.

- **KAT-1 (compose, positive).** Build two SovVals `a,b` with reachable hexads (e.g. all-`ZERO`
  pillars), modest costs under the grant. `sv_op(&a,&b,req_compose,&r)` MUST return `SV_OK`,
  `sv_hexad(&r) == iii_hexad_compose6(a.hexad,b.hexad)`, `sv_cost(&r) == cl_join(a.cost,b.cost)`,
  and `sv_witness(&r)` non-zero. *(Proves the four facets compose.)*
- **KAT-2 (non-reachable hexad → `Refused`, the bricking falsifier).** Build `a,b` whose
  composed hexad drives a **structural pillar to `NEG`** (one of the 585 non-reachable patterns —
  `iii_hexad_reachable(composed) == 0`). `sv_op` MUST return `SV_REFUSED_HEXAD` and MUST leave
  `out` **unwritten** (assert `SV_T_R` unchanged from a poison pattern). *(Proves the apotheosis
  falsifier "a constructed SovVal with a non-reachable hexad" → red — refusal, not construction.)*
- **KAT-3 (over-K cost → `Refused`, the budget falsifier).** `sv_init` with a tight grant; build
  `a,b` whose `cl_join` cost exceeds it (`cl_le_product(joined,grant) == 0`). `sv_op` MUST return
  `SV_REFUSED_COST`, `out` unwritten. *(Proves "an over-budget composition that is not Refused"
  → red.)*
- **KAT-4 (morphism associativity, M12/H11, positive + falsifier).** After `sv_op` registers its
  arrow, `cat_check_assoc(f,g,h)` over three composed arrows MUST return `1`. **Negative arm:** a
  deliberately mis-built composite whose op-word ≠ `w(f)‖w(g)` MUST make `cat_check_assoc` return
  `0`. *(Proves "an sv_op whose associativity fails cat_check_assoc" → red — and that the test is
  the binary composition axiom, not a vacuous unary property, Premise-Ledger T2.)*
- **KAT-5 (certificate re-check, H10).** `sv_certificate(&r,&cert)`; an **independent** recompute
  `ca_compute(r.payload ‖ r.hexad ‖ r.witness ‖ r.cost)` MUST equal `cert` byte-for-byte. *(Proves
  the consumer re-checks, never trusts — the nothing-trusted invariant.)*
- **KAT-6 (`sv_make` refuses a non-reachable hexad at construction, negative).** `sv_make` with a
  non-reachable hexad in `req` MUST return `SV_REFUSED_HEXAD` and write nothing. *(Bricking is
  unconstructable even for a leaf value, not only for a composition.)*

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| **1** multi-line `fn` | Yes | Every signature single-line (Skeleton). `wh_publish`'s multi-line form is the *existing* extern, called not authored. |
| **2** const linker-global | Yes | All consts `SV_`-prefixed; grep-confirmed zero collision. |
| **3** signed-int ordering | **Avoided** | No signed ordering. `sv_is_refused` uses `==`; refusal codes compared by `==`. |
| **4** u32-in-u64-slot | Minor | `cat_add_morphism` returns a u32 slot; widened before any pointer math. |
| **5** u32/u16-pointer store width | **Yes — hexad u16, cost u64** | hexad written/read **byte-by-byte through `*u8`** (never `*u16`); cost dims LE byte-by-byte. |
| **18** u64 `/`·`%` | **Avoided** | No division in `sovval` (payload division is M4's `unc_udiv64`); cost uses `cl_join` (per-dim min/max, no division). |
| **19** `[u8;N]`=8N | Minor | SovVal records are fixed 136 B locals; no large `[u8;N]` pool here (the chain is M6's). |
| **7** local `var` arrays | Yes | Compose scratch module-scope; non-reentrancy documented. |
| **8/9/10/11/12** | Minor/NA | one-line `else`; ASCII comments; early-return guards; no modulo-after-call; not generic. |

## Design notes (net-new — the decisions that matter)
1. **`Refused` leaves `out` unwritten.** A refusal is the *absence* of a value, never a sentinel
   value a careless caller could propagate. This is what makes "bricking is unsayable" honest
   pre-inductive; migration-2 turns the same site into a typecheck.
2. **`sv_op` is the generating morphism, audited as binary composition.** Associativity is
   `(h∘g)∘f = h∘(g∘f)` (KAT-4), never a unary property of one arrow (Premise-Ledger T2) — the op
   word concatenates flat (`w(f)‖w(g)`), associative by construction (M12·D1), never a nested hash.
3. **Witness keys on payload content-address, not the stamped frag-id** (M6·D1 bug #6): a value's
   *reproducible* certificate (`sv_certificate`) excludes `at_time`, so re-verification across
   nodes (M19) and re-publication agree; the frag-id orders, the `cad` re-verifies.
4. **The four facets are typed, not checked (post-mig-2).** Today reach/cost are runtime gates;
   the SovVal-as-CIC-inductive makes them Π-typed refinements so refusal is `ι`-reduction. The
   `defer` ledger names this; the runtime gate is the safe-meanwhile with KAT-2/KAT-3 as its
   falsifier.
5. **Boundary enforcement is M18/sema, not here.** `sovval.iii` provides the value + its compose;
   `@sovereign`'s `III_NONSOVEREIGN_BOUNDARY` D-gate is migration 3 in `sema` (reusing the
   `TYPE-HEXAD-002` reach-gate machinery). Reserved neg-test `711_neg_nonsovereign_boundary.iii`.

**Mandate audit:** M1 (NIH; `cad`+facet providers only) ✓; M2/W5 (deterministic, LE byte-exact,
payload-cad re-verification) ✓; M3 (`hexad_law` — non-reachable Refused) ✓; M4 (`payload_law` —
sound gap arithmetic) ✓; M5 (totality — `Refused` is structural, never a crash) ✓; M6
(`witness` per op, antecedents = both inputs) ✓; M8 (`SV_REVTAG`; attest cap gate) ✓; M9 (the
record is the future CIC inductive; `defer` names the migration) ✓; M10 (falsifier per KAT) ✓;
M12 (`morphism_id` registered; `cat_check_assoc`) ✓; M13 (`cost_law` — join, over-K Refused) ✓;
M16 (`sv_certificate` re-checkable) ✓; W2 (`req` aggregates; ops ≤4) ✓; W8/W13/W14/W15 ✓.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/omnia/sovval.iii -- Module 5 (apotheosis): THE Sovereign Value.
 *
 * One currency: SovVal { payload(Known|Gap, M4) | hexad(u16, M3) | witness(FragId, M6)
 * | cost([u64;6], M13) }.  A total sv_op composes all four facets and is the GENERATING
 * morphism (M12) every Sovereign operation specializes (The Move).  Refused (unwritten
 * out) on a non-reachable composed hexad (bricking, M3) or over-K joined cost (M13) --
 * the pre-inductive realization of the migration-2 type-level Refused.
 *
 * SovVal record = 136 bytes: payload UV(48) | hexad u16(48..50) | pad | witness(56..88)
 * | cost [u64;6](88..136).
 *
 * NON-REENTRANT (module-scope compose scratch).  Hexad: kind_substance.  Ring: R0.  K: 1.00.
 * Discipline: W2, W5, W8, W13, W14, W15; Traps 5/18 designed-out (see spec).
 * Depends on M4 numera/uncertainty.iii (payload_law) -- build M4 first.
 */
module omnia_sovval

extern @abi(c-msvc-x64) fn iii_hexad_compose6(a: u16, b: u16) -> u16 from "hexad_algebra.iii"
extern @abi(c-msvc-x64) fn iii_hexad_reachable(h: u16) -> u8 from "hexad_reach.iii"
extern @abi(c-msvc-x64) fn iii_hexad_pack6(pillars_addr: u64) -> u16 from "hexad_algebra.iii"
extern @abi(c-msvc-x64) fn cl_join(c: *u64, cp: *u64, out: *u64) -> i32 from "cost_lattice.iii"
extern @abi(c-msvc-x64) fn cl_le_product(c: *u64, cp: *u64) -> u8 from "cost_lattice.iii"
extern @abi(c-msvc-x64) fn cat_add_morphism(src: u32, dst: u32, op: *u8, out_id: *u8) -> u32 from "category.iii"
extern @abi(c-msvc-x64) fn cat_check_assoc(f_slot: u32, g_slot: u32, h_slot: u32) -> u8 from "category.iii"
extern @abi(c-msvc-x64) fn ca_compute(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32 from "content_addr.iii"
extern @abi(c-msvc-x64) fn ca_compose(left: *u8, right: *u8, out: *u8) -> i32 from "content_addr.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
// NOT-YET-BUILT sibling M4 (numera/uncertainty.iii) -- the payload_law:
extern @abi(c-msvc-x64) fn unc_known(concrete: u64, out: *u8) -> i32 from "uncertainty.iii"
extern @abi(c-msvc-x64) fn unc_add(a: *u8, b: *u8, out: *u8) -> i32 from "uncertainty.iii"
extern @abi(c-msvc-x64) fn unc_mul(a: *u8, b: *u8, out: *u8) -> i32 from "uncertainty.iii"
extern @abi(c-msvc-x64) fn unc_div(a: *u8, b: *u8, out: *u8) -> i32 from "uncertainty.iii"

const SV_OK : i32 = 0i32
const SV_E_BAD : i32 = -1i32
const SV_E_CAP : i32 = -2i32
const SV_E_WITNESS : i32 = -3i32
const SV_REFUSED_HEXAD : i32 = -10i32
const SV_REFUSED_COST : i32 = -11i32
const SV_BYTES : u64 = 136u64
const SV_PILLAR : u16 = 5u16
const SV_PHASE : u8 = 5u8
const SV_REVTAG : u8 = 1u8
const SV_OP_COMPOSE : u8 = 0u8
const SV_OP_ADD : u8 = 1u8
const SV_OP_SUB : u8 = 2u8
const SV_OP_MUL : u8 = 3u8
const SV_OP_DIV : u8 = 4u8
const SV_REQUIRED_RIGHTS : u64 = 0x0800u64

var SV_PRODUCER : [u8; 32]
var SV_OPID : [u8; 32]
var SV_GRANT : [u64; 6]
var SV_CAP : u64 = 0u64
var SV_INITED : u8 = 0u8
var SV_IN_C : [u8; 32]
var SV_OUT_C : [u8; 32]
var SV_ANTE : [u8; 64]
var SV_TMPCOST : [u64; 6]
var SV_WIT : [u8; 32]
var SV_T_A : [u8; 136]
var SV_T_B : [u8; 136]
var SV_T_R : [u8; 136]
var SV_T_REQ : [u8; 128]
var SV_T_CERT : [u8; 32]

fn sv_init(grant_req: *u8, cap: u64) -> i32 @export {
    // TODO: derive producer/opid ids; cap_verify_rights(cap, SV_REQUIRED_RIGHTS) -> SV_E_CAP;
    //       copy 6 grant dims LE into SV_GRANT; SV_CAP=cap; SV_INITED=1; SV_OK.
}
fn sv_make(req: *u8, out: *u8) -> i32 @export {
    // TODO: read payload/hexad/cost; iii_hexad_reachable gate -> SV_REFUSED_HEXAD;
    //       cl_le_product(cost,grant) -> SV_REFUSED_COST; wh_publish witness; assemble out; SV_OK.
}
fn sv_op(a: *u8, b: *u8, req: *u8, out: *u8) -> i32 @export {
    // TODO: payload_law (unc_<op>); hexad_law (compose6 -> reachable? else SV_REFUSED_HEXAD);
    //       cost_law (cl_join -> cl_le_product? else SV_REFUSED_COST); witness (ante=a.wit||b.wit,
    //       wh_publish); morphism_id (cat_add_morphism); assemble out (leave unwritten on Refused).
}
fn sv_payload(v: *u8, out_uv: *u8) -> i32 @export { /* TODO: copy v[0..48) -> out_uv. */ }
fn sv_hexad(v: *u8) -> u16 @export { /* TODO: read v[48..50) LE. */ }
fn sv_witness(v: *u8, out_frag: *u8) -> i32 @export { /* TODO: copy v[56..88) -> out_frag. */ }
fn sv_cost(v: *u8, out_cost: *u64) -> i32 @export { /* TODO: copy v[88..136) -> out_cost (6 u64 LE). */ }
fn sv_certificate(v: *u8, out_cert: *u8) -> i32 @export {
    // TODO: ca_compute over (payload || hexad || witness || cost) -> out_cert (re-checkable, H10).
}
fn sv_is_refused(rc: i32) -> u8 @export { /* TODO: (rc==SV_REFUSED_HEXAD)|(rc==SV_REFUSED_COST). */ }
fn sv_selftest() -> u64 @export {
    // TODO: KAT-1..KAT-6 (compose; non-reachable hexad Refused + out unwritten; over-K Refused;
    //       cat_check_assoc positive+negative; certificate re-check; sv_make bricking refusal).
    //       99u64 on pass. (Runs once M4 uncertainty.iii lands.)
}
```
