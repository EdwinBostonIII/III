# M4 numera/uncertainty.iii — Implementation Spec (station-1 DESIGN)

> ## ⚠ SUPERSEDED BY IMPLEMENTATION (2026-05-25) — read `STDLIB/iii/numera/uncertainty.iii`, not this
> The **USER implemented M4**; `numera/uncertainty.iii` exists, **compiles clean** (`--compile-only`
> OK), and carries a full falsifier `unc_selftest`. **The `.iii` is the authority.** The
> implementation refined this design-ahead spec — *cleaner than what is below* — as follows:
> - **16-byte `ucell`** (tag@0 KNOWN/GAP · i64 body@8), not a 48-byte UV.
> - **Gaps are compact `u32` gids** into 1024-slot arrays (`UNC_KIND/REASON/A0/A1/NA`); the
>   content-address is computed on demand via `unc_gap_addr(gid,out)` — *not* a 32-byte id
>   embedded in the cell.
> - **Known values are `i64` (signed)** — so `/` lowers to the *correct* `idivq` and **trap-18 is
>   sidestepped by construction**, not guarded around (the divide-free helper this spec specced is
>   unneeded). div0 → essential gap.
> - Arithmetic is **`unc_apply(op:u32,a,b,out)`** (op-tags ADD=0/SUB=1/MUL=2/DIV=3), not four fns.
> - Minting: **`unc_gap_root(kind:u8,reason:u32)->u32`** + **`unc_gap_derived(a0,a1,na:u8,reason:u32)->u32`**
>   (reason a `u32`, antecedents `u32` gids, ≤2). Kinds: ESSENTIAL=0/HOLE=1/REDACTED=2/DERIVED=3.
> - Externs: **`cad_oneshot`/`cad_eq` from `cad.iii`** (not `ident_from_bytes`/`ca_*`). `UNC_MAX=1024`.
> - All apotheosis falsifiers are covered by `unc_selftest`: `0*unknown=Known(0)`, `÷0`=essential
>   gap (total), derived-gap non-empty provenance, `unc_well_formed` negatives (slots 900/901),
>   `unc_gap_addr` determinism+distinctness. Provenance walk is worklist (`UNC_STACK`, W15).
>
> The text below is the **original design-ahead spec** — kept for the apotheosis-grounding +
> rationale, but **do not implement from it**; the `.iii` is final.

## Verdict
**NET-NEW (design).** There is no gospel candidate body and no prior `.iii` — this is the
*one genuinely new organ* the charter names (the POC `negknow.py` proved the shape). This spec
is the station-1 design grounded **verbatim in `DOCS/III-APOTHEOSIS.md` Module 4 + M4·D1**;
the implementation body is the overhaul proper (the USER's domain, like M1). Every extern is
pinned to its real provider (§VII); every guarantee carries a negative-arm KAT (Directive 3).

## Purpose
`numera::uncertainty` is **the one typed gap** — III's single representation of partial
information, replacing the three incompatible handlings (`either`, `checked`, `hexad_epistemic`).
A `Gap` is a first-class, content-addressed value that **explains itself**: it carries a `kind`,
a `reason`, and an `antecedents` provenance DAG walkable to named root causes. Its arithmetic is
**total, sound, and maximally precise** — the `ZERO`-inhabited reading of the M2 ternary algebra
(not a new algebra): `÷0 → gap`; the hardest-won POC invariant `0·unknown → Known(0)` (sound
*and* precise — zero annihilates even an unknown). It is a SovVal payload (M5), the open-term of
the kernel (M9·D1), the sink a redacted witness fragment becomes (M6/M20), and the reason a
proof may be *partial* and stay sound (M16).
- **Hexad:** `kind_substance` (it is the substance of partial knowledge — a value type, not a
  producer). Assigned (the apotheosis pins M4's hexad/ring/K only implicitly); grounded in the
  `numera/` R0 value-layer convention shared by `cost_lattice`/`category`.
- **Ring:** R0 (substrate value layer).
- **K-vector:** K = 1.00 (pure: no externs on the hot path save `cad` for naming, no float, no
  alloc, deterministic).

## Public API
```
fn unc_init() -> i32 @export
fn unc_known(concrete: u64, out: *u8) -> i32 @export
fn unc_mint(req: *u8, out: *u8) -> i32 @export
fn unc_add(a: *u8, b: *u8, out: *u8) -> i32 @export
fn unc_sub(a: *u8, b: *u8, out: *u8) -> i32 @export
fn unc_mul(a: *u8, b: *u8, out: *u8) -> i32 @export
fn unc_div(a: *u8, b: *u8, out: *u8) -> i32 @export
fn unc_is_known(v: *u8) -> u8 @export
fn unc_concrete(v: *u8) -> u64 @export
fn unc_gap_kind(v: *u8) -> u8 @export
fn unc_root_causes(gap_id: *u8, out: *u8, max: u32) -> u32 @export
fn unc_explain(gap_id: *u8, out: *u8, cap: u32) -> u32 @export
fn unc_selftest() -> u64 @export
```

Return-status conventions (W9/W12):
- `unc_init` / `unc_known` / `unc_mint` / `unc_add|sub|mul|div` → `i32`: `UNC_OK (0)` or a
  negative error (`UNC_E_FULL` pool exhausted, `UNC_E_BAD` malformed `req`). The **uncertainty
  is in the `out` UV's tag, never an error code** — a div-by-zero is `UNC_OK` with `out` a Gap,
  *not* an error return (totality, M5: the op never fails on a legal value; only resource
  exhaustion is an error).
- `unc_is_known` / `unc_gap_kind` → `u8`; `unc_concrete` → `u64` (defined iff Known, else 0).
- `unc_root_causes` / `unc_explain` → `u32` count (saturating; 0 if `gap_id` unknown).
- `unc_selftest` → `u64`: `99u64` = pass; else the failing assertion ordinal.

**W2 note:** `unc_mint` folds the whole gap descriptor behind one `req: *u8` aggregate (layout in
Data Structures) so minting an arbitrary kind + reason + antecedent set stays at 2 params; the
arithmetic ops are `(a, b, out)` = 3. No op exceeds 4.

## Constant Namespace
**PREFIX = `UNC_`** — grep of `STDLIB/` for both `(fn|const) unc_` and `UNC_` returned
**zero hits (2026-05-25)**: the namespace is entirely free (registry §A).

```
const UNC_OK            : i32 =  0i32
const UNC_E_BAD         : i32 = -1i32
const UNC_E_FULL        : i32 = -2i32

const UNC_KNOWN         : u8  = 0u8     // UV tag: a concrete value
const UNC_GAP           : u8  = 1u8     // UV tag: a gap (see kind)

const UNC_KIND_ESSENTIAL: u8 = 1u8      // irreducible unknown (div-by-zero, dead sensor)
const UNC_KIND_HOLE     : u8 = 2u8      // a named hole (synthesis target, open metavariable -- M9)
const UNC_KIND_REDACTED : u8 = 3u8      // provably forgotten (M6 redaction / M20)
const UNC_KIND_DERIVED  : u8 = 4u8      // computed from other gaps (carries antecedents)
const UNC_KIND_MIN      : u8 = 1u8
const UNC_KIND_MAX      : u8 = 4u8

const UNC_UV_BYTES      : u64 = 48u64   // tag(1) | pad(7) | concrete(8 LE) | gap_id(32)
const UNC_MAX_GAPS      : u32 = 4096u32 // W8 gap-pool ceiling
const UNC_MAX_ANTE      : u32 = 8u32    // antecedents cited per derived gap (W8; DAG fan-in)
const UNC_REASON_CAP    : u32 = 64u32   // reason bytes hashed into reason_id
```

## Data Structures
All buffers module-scope (Trap 7). **Trap-19 honored:** `[u8;N]` reserves 8N bytes, so every
wide byte array uses the frugal `[u64; (bytes+7)/8]` + byte-pointer idiom; the bound math below
is in *logical* bytes.

```
// The gap pool (content-addressed; identical gaps coalesce by id, M2 determinism):
var UNC_G_ID    : [u64; (4096*32+7)/8]   // 4096 gap content-address ids (32 B each), frugal
var UNC_G_KIND  : [u8;  4096]            // per-gap kind (ESSENTIAL|HOLE|REDACTED|DERIVED)
var UNC_G_REASON: [u64; (4096*32+7)/8]   // per-gap reason_id = cad(reason bytes), 32 B each
var UNC_G_ANTE  : [u64; (4096*8*32+7)/8] // per-gap antecedent ids (<=8 * 32 B), frugal
var UNC_G_NANTE : [u32; 4096]            // per-gap antecedent count
var UNC_G_K     : [u64; 4096]            // per-gap K-value at mint (M13)
var UNC_G_COUNT : u32 = 0u32             // live gap count (saturates at UNC_MAX_GAPS)
var UNC_INITED  : u8  = 0u8

// scratch for cad naming + DAG walk (no recursion -- W15: explicit stack):
var UNC_SCRATCH : [u64; (4096+7)/8 ... ] // assembly buffer for cad(kind||reason||antes)
var UNC_WALK_ST : [u32; 256]             // explicit DFS stack of gap slot-indices (root_causes)
var UNC_WALK_SEEN: [u8; 4096]            // visited-marks (cycle guard; the DAG is acyclic by
                                         //   construction -- antecedents predate their derived
                                         //   gap -- but the mark makes the walk total regardless)
```

**UV (uncertain value) layout — 48 logical bytes, the unit every op consumes/produces:**
```
[0]      tag        : u8   (UNC_KNOWN | UNC_GAP)
[1..8)   reserved   : 0
[8..16)  concrete   : u64 LE   (defined iff tag == UNC_KNOWN)
[16..48) gap_id     : [u8;32]  (defined iff tag == UNC_GAP; a pool content-address)
```

**`req` aggregate for `unc_mint` (W2 fold):**
```
[0]      kind       : u8
[1..5)   n_ante     : u32 LE   (0 unless kind == DERIVED)
[5..9)   reason_len : u32 LE   (<= UNC_REASON_CAP)
[9..9+RL)            reason bytes
[9+RL .. 9+RL+n_ante*32)   antecedent gap_ids (32 B each)
```

**Gap identity (M1/M2).** `gap_id = cad(kind_byte ‖ reason_id ‖ antecedent_ids[0..n_ante*32])`
via `ca_compute`/`ca_compose` over canonical bytes. Two structurally identical gaps therefore
**collide to one id** — gap minting is idempotent and deterministic, so the provenance DAG is a
true content-addressed Merkle-DAG (the negative-knowledge value the apotheosis demands). On a
mint, if the id already resides, return the existing slot (no duplicate).

**Bound justifications (W8):** `UNC_MAX_GAPS = 4096` is the live-gap horizon (gaps are
content-addressed and coalesce, so 4096 *distinct* gaps is generous for one computation epoch).
`UNC_MAX_ANTE = 8` bounds DAG fan-in (a derived gap cites at most 8 direct antecedents; deeper
provenance is reached transitively by `unc_root_causes`). `UNC_WALK_ST = 256` bounds DAG depth
for the explicit-stack walk (W15); overflow returns the partial root-cause set (total, never
crash).

**Reentrancy (Trap 7):** module-scope scratch makes the ops non-reentrant — correct for the
deterministic, serialized value layer.

## Dependencies (externs)
Signatures pinned to the **real provider files** (registry §E), not invented.

| Symbol | Signature | Provider | Built? |
|---|---|---|---|
| `ca_compute` | `(producer:*u8, operation:*u8, input_commit:*u8, out:*u8) -> i32` | `numera/content_addr.iii:31` (→ `cad` post-M1) | **BUILT** ✓ |
| `ca_compose` | `(left:*u8, right:*u8, out:*u8) -> i32` | `numera/content_addr.iii:35` (→ `cad` post-M1) | **BUILT** ✓ |
| `ident_from_bytes` | `(input:*u8, in_len:u64, out:*u8) -> i32` | `numera/identifier.iii` | **BUILT** ✓ |

**No division extern.** The single real division (`Known(a) ÷ Known(b≠0)`) is done by an
**internal trap-18-safe helper `unc_udiv64`** (binary long division — the catalog's prescribed
divide-free method), *never* the `/` operator (u64 `/` compiles as signed `idivq`, WRONG once
bit 63 of the dividend is set, and silent — the single most dangerous trap). `bigint_div_qr`
(`numera/bigint_div.iii:125`, corpus 48) is the proven arena-based alternative if a future op
needs full-width division; `unc_div` keeps the inline helper to stay arena-free and pure.

## Delegation absorption (M24#4 — additive, deletes duplication not API)
`omnia/either.iii` and `numera/checked.iii` **keep their public signatures** and delegate their
partial-information handling to this one gap:
- `checked_u64_add|sub|mul|div` (`numera/checked.iii:69-84`, return `u64` handles today) — the
  overflow/÷0 case mints an `unc_` **derived/essential** gap instead of a private option-handle.
- `either_u32_*` (`omnia/either.iii:19-48`) — the `right` arm reads as a `Known`, the `left`
  (error) arm as a `Gap`; the duplicated disjunction logic is deleted.
This is **additive**: no caller signature changes; only the internal duplicated handling is
removed once `unc_` lands (the M24#4 retirement gate = the existing `either`/`checked` KATs
still pass against the delegating bodies).

## Algorithm
Determinism (M2): every gap id is `cad` over canonical bytes; identical inputs → identical id.
No float, no statistical step (M3/M4): a gap's `kind` is supplied or derived structurally, never
inferred. No recursion (W15): the DAG walk uses `UNC_WALK_ST`. Bit-identity (W5): the `concrete`
field and all `req` integers are written/read **LE byte-by-byte through `*u8`** (Trap 5).

### `unc_known(concrete, out)`
Write `out[0] = UNC_KNOWN`; zero `out[1..8)`; store `concrete` LE into `out[8..16)`; zero
`out[16..48)`. Return `UNC_OK`.

### `unc_mint(req, out)`
1. Parse `kind = req[0]`, `n_ante = LE u32 @ req[1]`, `reason_len = LE u32 @ req[5]`. Guard
   `kind ∈ [MIN,MAX]` (u8 `==` cascade — Trap 3 forbids signed ordering, u8 ordering is safe but
   the cascade is future-proof), `reason_len <= UNC_REASON_CAP`, `n_ante <= UNC_MAX_ANTE`, and
   `(n_ante > 0) == (kind == UNC_KIND_DERIVED)` (only derived gaps cite antecedents; an essential
   gap with antecedents, or a derived gap with none, is `UNC_E_BAD`). **This last guard is the
   structural enforcement of the falsifier "a derived gap with empty provenance."**
2. `reason_id = ca_compute(reason, reason, reason, &tmp)` over `reason[0..reason_len]` (domain-
   separated naming of the reason text; `ca_compute`'s 3-input fold is reused as a 1-input hash by
   passing the reason thrice — or `ident_from_bytes(reason, reason_len, &reason_id)`; the spec
   pins `ident_from_bytes` for a plain content-address of variable-length bytes).
3. Assemble `kind_byte ‖ reason_id ‖ antecedents[0..n_ante*32]` into `UNC_SCRATCH`; `gap_id =
   ca_compose`-fold over it (chain `ca_compose(acc, next, &acc)` across the segments) → the
   content-address.
4. If `gap_id` already resides (linear scan of `UNC_G_ID[0..UNC_G_COUNT]`, or a hashed probe),
   write `out` as `UNC_GAP ‖ gap_id` and return `UNC_OK` (idempotent coalescing).
5. Else if `UNC_G_COUNT >= UNC_MAX_GAPS` return `UNC_E_FULL`. Else store the new gap at slot
   `UNC_G_COUNT` (id/kind/reason/antes/n_ante/K), `UNC_G_COUNT += 1`, write `out`, return `UNC_OK`.

### `unc_add|sub(a, b, out)` (additive propagation)
- both `Known` → `Known(a.concrete ± b.concrete)` (wrapping u64; the ternary `SUM` clamp does not
  apply to concretes — clamping is the trit-domain reading, M2).
- either `Gap` → mint a **derived** gap whose antecedents are the gap operand(s) (1 or 2), reason
  = `"add"`/`"sub"`. (`Known ± Gap` and `Gap ± Gap` both → derived gap; sound: the result is
  unknown, provenance names why.)

### `unc_mul(a, b, out)` (the precise invariant)
- both `Known` → `Known(a.concrete * b.concrete)` (wrapping).
- `Known(0) · anything` **or** `anything · Known(0)` → **`Known(0)`** (zero annihilates even an
  unknown — the hardest-won POC invariant; this is sound *and* maximally precise). Checked
  **before** the gap test: `if (a.tag==KNOWN && a.concrete==0) || (b.tag==KNOWN && b.concrete==0)
  { return Known(0) }`.
- else either `Gap` → derived gap (antecedents = the gap operand(s), reason `"mul"`).

### `unc_div(a, b, out)` (totality over ÷0)
- `b` is `Known(0)` → **essential gap** (reason `"div0"`, no antecedents) — *never* raises,
  *never* returns a concrete (totality, M5).
- `a` is `Known(0)` and `b` is `Known(nonzero)` → `Known(0)`.
- both `Known`, `b != 0` → `Known(unc_udiv64(a.concrete, b.concrete))` (trap-18-safe).
- either `Gap` (and `b` not the Known-0 case) → derived gap (antecedents, reason `"div"`).

### `unc_udiv64(num, den) -> u64` (internal; den > 0 guaranteed)
Binary long division: iterate bit 63→0, shifting a remainder, comparing `rem >= den` by the
**Trap-3-safe** subtraction test (`rem - den` does not underflow only when `rem >= den`; compute
via the high-bit of `rem - den` using a u64 subtract and a `== 0` test on the borrow, never a
signed `>=`). No `/`, no `%`, no `idivq`. 64 iterations, total.

### `unc_root_causes(gap_id, out, max) -> u32`
Locate the slot; if not a derived gap, the gap *is* its own root cause (write its id, return 1).
Else explicit-stack DFS (W15) over antecedents, emitting each `ESSENTIAL`/`HOLE`/`REDACTED` leaf
id into `out` (up to `max`), `UNC_WALK_SEEN` guarding re-visits. Returns the leaf count.

### `unc_explain(gap_id, out, cap) -> u32`
Serializes the provenance chain (`gap_id : kind : reason_id : [antecedent ids]` per node, BFS
order) into `out[0..cap]` — the human/audit-facing "unknown *because* … via X→Y→Z". Returns
bytes written.

## KAT Vectors (≥ 3, every guarantee with a negative arm — Directive 3)
`unc_selftest` returns `99u64` on full pass. Corpus block **700–709** (registry §C).

- **KAT-1 (`0·unknown → Known(0)` — the precision invariant, positive + negative).** Mint an
  essential gap `g` (`unc_mint`); `unc_known(0, &z)`. `unc_mul(&z, &g_uv, &r)` MUST yield `r.tag
  == UNC_KNOWN && unc_concrete(&r) == 0`. **Negative arm:** `r.tag` MUST NOT be `UNC_GAP` — the
  imprecise-but-sound answer (a gap) is *wrong* here; the test fails if `mul` propagated the gap.
  Symmetric `unc_mul(&g_uv, &z, &r)` MUST also be `Known(0)`. *(Proves precision, not just
  soundness — the POC's hardest invariant.)*
- **KAT-2 (`÷0 → essential gap`, totality, negative).** `unc_known(5,&a)`, `unc_known(0,&b)`;
  `unc_div(&a,&b,&r)` MUST return `UNC_OK` with `r.tag == UNC_GAP` and `unc_gap_kind(&r) ==
  UNC_KIND_ESSENTIAL`. **Negative arm:** it MUST NOT return a negative error code and MUST NOT
  yield `UNC_KNOWN` (no raise, no bogus concrete). *(Proves totality — the op is defined on the
  one input ordinary arithmetic traps on.)*
- **KAT-3 (derived gap has non-empty provenance, negative-as-structural).** `unc_known(3,&a)`,
  mint gap `gx`; `unc_add(&a,&gx_uv,&r)` → `r` a derived gap. `unc_root_causes(&r.gap_id, buf, 8)`
  MUST return `>= 1` and include `gx`'s id. **Negative arm:** `unc_mint` of a `DERIVED` kind with
  `n_ante == 0` MUST return `UNC_E_BAD` — a derived gap with empty provenance cannot be
  constructed. *(Proves the falsifier "a derived gap with empty provenance → red" fires.)*
- **KAT-4 (content-address coalescing / determinism, positive).** Mint the *same* essential gap
  (same kind+reason) twice → the two `out` UVs MUST carry the **identical** 32-byte `gap_id`, and
  `UNC_G_COUNT` MUST increase by exactly 1 across both mints. *(Proves M2 determinism: identical
  gaps are one content-addressed value.)*
- **KAT-5 (`unc_udiv64` against the idivq trap, negative-of-the-trap).** `unc_div(Known(0x8000_
  0000_0000_0006), Known(2))` MUST yield `Known(0x4000_0000_0000_0003)` — a dividend with **bit 63
  set**, the exact case the native `/`/`idivq` miscompiles. **Negative arm:** the result MUST NOT
  be the signed-division garbage. *(Proves the divide-free helper is correct where the trap bites.)*

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| **1** multi-line `fn` | Yes | Every signature single-line (Skeleton). |
| **2** const linker-global | Yes | All consts `UNC_`-prefixed; grep-confirmed zero collision. |
| **3** signed-int ordering SIGSEGV | **Avoided** | No signed `i32`/`i64` ordering. Kind/tag compares use `==`; `udiv64`'s `rem>=den` uses a borrow-bit test, never `>=`. |
| **4** u32-in-u64-slot | Yes (gap-slot indexing) | `(slot as u64)` widened *before* pointer math; `slot < 4096`. |
| **5** u32-pointer store width | Yes (LE concrete/req fields) | All multi-byte fields byte-by-byte through `*u8` with `>>/&0xFF`. |
| **18** u64 `/`·`%` as `idivq` | **Yes — the central risk** | `unc_div` never uses `/`; the one real division is `unc_udiv64` (binary long division), guarded by the ÷0→gap case so `den>0`. KAT-5 exercises the bit-63 dividend. |
| **19** `[u8;N]` = 8N bytes | **Yes — the gap pool** | `UNC_G_ID`/`UNC_G_REASON`/`UNC_G_ANTE` use the frugal `[u64;(bytes+7)/8]` + byte-pointer idiom; no `[u8;big]`. |
| **7** local `var` arrays | Yes | All scratch module-scope; non-reentrancy documented (serialized value layer). |
| **8/9/10/11/12** | Minor/NA | `} else {` one-line; ASCII `--` comments; early-return guards (no `let mut` flag); no modulo-after-call (no `%` at all); not generic (no `@specialize`). |

## Design notes (net-new — no gospel to correct; the decisions that matter)
1. **UV is a 48-byte value, not a handle.** Passing the gap *by content-address inside the UV*
   (not a slot index) keeps a UV self-describing and federatable (M19): a peer resolves the gap
   from its own pool by the same `cad` id. Slot indices are an internal pool detail.
2. **Coalescing is mandatory, not an optimization.** Because gaps are content-addressed, the
   pool dedups by construction — this is *why* the provenance DAG is a Merkle-DAG and `0·unknown`
   stays deterministic. (M2.)
3. **`÷0` is a value, not an error.** The single most important totality decision: arithmetic
   never returns an error code for a legal input — the unknown lives in the UV's tag. Errors are
   reserved for resource exhaustion (`UNC_E_FULL`) and malformed `req` (`UNC_E_BAD`).
4. **Trap-18 is designed-out, not guarded-around.** No `/` appears in the module; the divide-free
   helper is the only path, so there is no latent dividend that could set bit 63 unsafely.
5. **Delegation is additive (M24#4).** `either`/`checked` retire their *duplicated handling*,
   never their API — the retirement gate is their own unchanged KATs passing against delegating
   bodies (the M24 "exact KAT" rule).

**Mandate audit:** M1 (NIH; only `cad`/`identifier`) ✓; M2/W5 (deterministic, LE byte-exact,
content-addressed coalescing) ✓; M3/M4 (no inference; gap kind structural) ✓; M5 (totality — no
raise on any legal input) ✓; M6 (gap ids are `cad`, chainable into witness) ✓; M9 (a `HOLE` gap
*is* the kernel's open term) ✓; M13 (`UNC_G_K` per-gap K-value) ✓; W2 (`unc_mint` aggregate;
ops ≤3 params) ✓; W8 (4096/8 bounds) ✓; W13 (<20 locals/fn via helpers) ✓; W14/W15 (sentinel
loops, explicit DAG stack, no recursion) ✓.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/uncertainty.iii -- Module 4 (apotheosis): the ONE typed gap.
 *
 * One Gap{kind, reason, antecedents} -- the ZERO-reading of the M2 ternary algebra.
 * Total + sound + maximally-precise arithmetic: div0 -> gap; 0*unknown -> Known(0).
 * Content-addressed provenance DAG (cad, M1): identical gaps coalesce; walkable to
 * named root causes.  Absorbs either/checked/epistemic (M24#4, additive delegation).
 * A UV (uncertain value) is 48 bytes: tag(1)|pad(7)|concrete(8 LE)|gap_id(32).
 *
 * NON-REENTRANT (module-scope scratch).  Hexad: kind_substance.  Ring: R0.  K: 1.00.
 * Discipline: W2, W5, W8, W13, W14, W15; Traps 3/18/19 designed-out (see spec).
 */
module numera_uncertainty

extern @abi(c-msvc-x64) fn ca_compute(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32 from "content_addr.iii"
extern @abi(c-msvc-x64) fn ca_compose(left: *u8, right: *u8, out: *u8) -> i32 from "content_addr.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"

const UNC_OK : i32 = 0i32
const UNC_E_BAD : i32 = -1i32
const UNC_E_FULL : i32 = -2i32
const UNC_KNOWN : u8 = 0u8
const UNC_GAP : u8 = 1u8
const UNC_KIND_ESSENTIAL : u8 = 1u8
const UNC_KIND_HOLE : u8 = 2u8
const UNC_KIND_REDACTED : u8 = 3u8
const UNC_KIND_DERIVED : u8 = 4u8
const UNC_KIND_MIN : u8 = 1u8
const UNC_KIND_MAX : u8 = 4u8
const UNC_MAX_GAPS : u32 = 4096u32
const UNC_MAX_ANTE : u32 = 8u32
const UNC_REASON_CAP : u32 = 64u32

// frugal [u64;...] pools (Trap 19); byte access via ((&ARR as u64)+off) as *u8:
var UNC_G_ID : [u64; 16384]      // 4096*32 bytes
var UNC_G_KIND : [u8; 4096]
var UNC_G_REASON : [u64; 16384]  // 4096*32 bytes
var UNC_G_ANTE : [u64; 131072]   // 4096*8*32 bytes
var UNC_G_NANTE : [u32; 4096]
var UNC_G_K : [u64; 4096]
var UNC_G_COUNT : u32 = 0u32
var UNC_INITED : u8 = 0u8
var UNC_SCRATCH : [u64; 64]      // kind||reason_id||antes assembly (<= 1+32+8*32 = 289 B)
var UNC_WALK_ST : [u32; 256]
var UNC_WALK_SEEN : [u8; 4096]
var UNC_T_A : [u8; 48]           // self-test UVs
var UNC_T_B : [u8; 48]
var UNC_T_R : [u8; 48]
var UNC_T_REQ : [u8; 256]
var UNC_T_BUF : [u8; 256]

fn unc_gid_ptr(slot: u32) -> *u8 { return ((&UNC_G_ID as u64) + (slot as u64) * 32u64) as *u8 }

fn unc_init() -> i32 @export {
    // TODO: zero UNC_G_COUNT; set UNC_INITED; (pools are zero-init by .bss). return UNC_OK.
}
fn unc_known(concrete: u64, out: *u8) -> i32 @export {
    // TODO: out[0]=UNC_KNOWN; out[8..16)=concrete LE byte-by-byte; out[16..48)=0. return UNC_OK.
}
fn unc_mint(req: *u8, out: *u8) -> i32 @export {
    // TODO: parse kind/n_ante/reason_len; guard (kind in range, reason_len<=CAP, n_ante<=MAX,
    //       (n_ante>0)==(kind==DERIVED)) else UNC_E_BAD; reason_id=ident_from_bytes(reason);
    //       gap_id = ca_compose-fold(kind||reason_id||antes); coalesce if resident; else append
    //       (UNC_E_FULL if pool full); write out = UNC_GAP||gap_id; return UNC_OK.
}
fn unc_add(a: *u8, b: *u8, out: *u8) -> i32 @export {
    // TODO: both Known -> Known(a+b wrap); else derived gap (antes = gap operands, reason "add").
}
fn unc_sub(a: *u8, b: *u8, out: *u8) -> i32 @export {
    // TODO: both Known -> Known(a-b wrap); else derived gap (reason "sub").
}
fn unc_mul(a: *u8, b: *u8, out: *u8) -> i32 @export {
    // TODO: if either operand is Known(0) -> Known(0) [precision invariant, checked FIRST];
    //       both Known -> Known(a*b wrap); else derived gap (reason "mul").
}
fn unc_div(a: *u8, b: *u8, out: *u8) -> i32 @export {
    // TODO: b==Known(0) -> essential gap "div0"; a==Known(0)&b Known!=0 -> Known(0);
    //       both Known -> Known(unc_udiv64(a,b)); else derived gap (reason "div").
}
fn unc_udiv64(num: u64, den: u64) -> u64 {
    // TODO: binary long division, 64 iterations, borrow-bit compare (no / % idivq; no signed >=).
}
fn unc_is_known(v: *u8) -> u8 @export { /* TODO: return (v[0]==UNC_KNOWN) as u8 ... */ }
fn unc_concrete(v: *u8) -> u64 @export { /* TODO: read v[8..16) LE; 0 if not Known. */ }
fn unc_gap_kind(v: *u8) -> u8 @export { /* TODO: locate gap by v[16..48); return its kind; 0 if Known. */ }
fn unc_root_causes(gap_id: *u8, out: *u8, max: u32) -> u32 @export {
    // TODO: explicit-stack DFS over antecedents (W15); emit ESSENTIAL/HOLE/REDACTED leaf ids; count.
}
fn unc_explain(gap_id: *u8, out: *u8, cap: u32) -> u32 @export {
    // TODO: BFS-serialize the provenance chain into out[0..cap]; return bytes written.
}
fn unc_selftest() -> u64 @export {
    // TODO: KAT-1..KAT-5 (0*unknown=Known0; div0=essential gap; derived-gap provenance +
    //       empty-provenance refusal; cad coalescing; udiv64 bit-63 dividend). 99u64 on pass.
}
```
