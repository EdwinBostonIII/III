# 81 aether/cost_overrun_handler.iii — Implementation Spec

## Verdict
STUB — the gospel candidate implements only an op-kind→count hash table (`coh_init`, `coh_find_or_alloc`, `coh_on_overrun`, `coh_overrun_count`). It does **none** of the three duties its own prose names ("log the overrun, raise an event of severity matching the dimension and magnitude, and on repeated overruns from the same operation kind, request constitutional re-ratification") and **none** of this module's W37/M19 reason to exist: it never **refuses or quarantines** work that exceeds budget — it silently tolerates every overrun and merely increments a counter, which is exactly the "cost lattice excess silently tolerated" that W37 forbids. It emits **no witness fragment** (M6/M10 violated for a state-transition module), computes **no severity**, performs **no capability check** (M8 violated — overrun handling is a privileged immune action), and the candidate's `coh_on_overrun` is purely reactive with no admission gate. It also discards the find-or-alloc status into a `coh_on_overrun` path that returns `COH_E_NULL` for a *full table* (W12 conflation), and uses the `&ARR[expr]` element-address form that the realized substrate documents as an iiis hazard. This spec realizes the maximal intent: a deterministic, capability-gated, witness-chained overrun **enforcer** — admit/refuse/quarantine against a declared 6-dim budget, exact-algebraic severity banding (no ML, no learned thresholds), witnessed every event, with a structurally-triggered (not count-triggered) re-ratification **request**.

## Purpose
`aether/cost_overrun_handler.iii` IS the substrate's immune response to cost-lattice boundedness violations (M19): the single chokepoint through which work whose **observed** microarchitectural cost exceeds its **declared** budget is refused, quarantined, witnessed, and — when the breach is structurally severe — escalated toward constitutional re-ratification. It does not *measure* cost (that is `cost_calculus`, Module 23) nor *order* it (that is `cost_lattice`, Module 22); it **enforces** the lattice's verdict: an operation is admitted iff its observed cost vector is `⊑` (product-order ≤) its declared budget vector in every dimension, and any excess is handled exactly per W37 ("no cost lattice excess silently tolerated"). Severity is an exact integer band over (which dimensions exceeded, by what integer multiple), never a heuristic score; escalation fires on a structural band invariant, never on a tuned count threshold (M3). Hexad kind: `kind_repair`. Ring: R0. K-vector: 1.00 (deterministic; the only side effects are append-only witness fragments and recoverable quarantine flags).

## Public API
All signatures single-line (Trap 1). Status convention: error codes are negative `i32` compared by equality only (W9/W11); booleans return `u8` 0/1 (W10); every public fn returns a status or sentinel-typed value (W12). At most 4 params (W2) — the 6-dim declared/observed cost vectors are passed by `*u64` pointer (one aggregate each), not splayed.

```
fn corh_init() -> i32 @export
fn corh_admit(op_id: *u8, declared: *u64, observed: *u64, cap: u64) -> i32 @export
fn corh_on_overrun(ev: *u8, cap: u64) -> i32 @export
fn corh_severity(declared: *u64, observed: *u64) -> i32 @export
fn corh_overrun_count(op_id: *u8) -> u64 @export
fn corh_is_quarantined(op_id: *u8) -> u8 @export
fn corh_release(op_id: *u8, cap: u64) -> i32 @export
fn corh_reratification_pending(op_id: *u8) -> u8 @export
fn corh_event_count() -> u64 @export
```

Return-status notes per fn (the renamed `coh_*` → `corh_*`; see Constant Namespace for the prefix decision). The gospel's three original public fns are preserved in spirit: `coh_init`→`corh_init`, `coh_on_overrun`→folded into `corh_admit` + the aggregate-shaped `corh_on_overrun`, `coh_overrun_count`→`corh_overrun_count`.

- `corh_init` → `CORH_OK` always; re-entrant (clears every slot's live/count/quarantine/reratify flag deterministically, re-seeds nothing). Returns `CORH_OK` unconditionally (no failure mode at init).
- `corh_admit` → the W37 enforcement gate, called *before* an operation's effects commit. Computes the product-order test `observed ⊑ declared` (componentwise u64 ≤ over all 6 dims via `cl_le_product` semantics, re-derived in-module to avoid a cross-layer call — see Algorithm). On `observed ⊑ declared`: returns `CORH_OK` (admit). On any-dimension excess: increments the op-kind overrun count, computes the severity band, publishes an overrun witness fragment (M6), and returns `CORH_E_OVERRUN` (band 1) / `CORH_E_QUARANTINE` (band ≥2 → sets the quarantine flag, refusing this and all future work for the op kind until `corh_release`). On band 3 (critical) it *also* sets the reratification-pending flag and publishes a re-ratification-request fragment, returning `CORH_E_RERATIFY`. `cap` must carry `CAP_RIGHT_AMEND` for the *escalation* sub-action; if band 3 is reached but `cap` lacks the right, the quarantine still applies (refusal is unconditional) but the reratify request is withheld and `CORH_E_QUARANTINE` is returned (privilege-separated; refusal never requires a cap, escalation does — M8). Null `op_id`/`declared`/`observed` → `CORH_E_NULL`. Not-inited → `CORH_E_NOT_INITED`.
- `corh_on_overrun` → the prose-named reactive subscriber, kept for callers (e.g. `cost_calculus`) that detected the overrun out-of-band and pass a pre-packed **overrun event** aggregate `ev` (layout in Data Structures: `op_id[32] ‖ dim:u8 ‖ declared[6]u64 ‖ observed[6]u64`). It performs the identical witness+severity+quarantine+escalate pipeline as the refusal branch of `corh_admit`, returning the same status set. Aggregate-by-pointer keeps W2 (2 params). Null `ev` → `CORH_E_NULL`.
- `corh_severity` → pure classifier: returns the exact severity **band** as an `i32` in `{CORH_SEV_NONE(0), CORH_SEV_MINOR(1), CORH_SEV_MAJOR(2), CORH_SEV_CRITICAL(3)}` (compared by equality only, W11). Deterministic exact-integer function of `(declared, observed)` — no state, no cap, no witness; callers can pre-classify. Null → returns `CORH_SEV_NONE` (a value-typed sentinel; a null pair has no excess). Distinct from a status: bands are an ordered enum but are *only* ever compared `==`/`!=` in this module.
- `corh_overrun_count` → `u64` count of recorded overruns for `op_id` (0 if unknown/null/not-inited). Value-typed (W12 sentinel: 0). Provenance only — **not** an escalation trigger (M3; see Algorithm).
- `corh_is_quarantined` → `u8` 1 iff `op_id` is a live, quarantined kind; else 0 (W10).
- `corh_release` → capability-gated quarantine clear (recovery; M5/M9 reversibility). Requires `cap` with `CAP_RIGHT_AMEND` (lifting a quarantine is a privileged constitutional act). Clears quarantine + reratify-pending for `op_id`, publishes a release witness fragment, returns `CORH_OK`. `CORH_E_DENIED` if cap lacks the right; `CORH_E_NULL`/`CORH_E_NOT_INITED`/unknown-op → respective errors.
- `corh_reratification_pending` → `u8` 1 iff a re-ratification request is outstanding for `op_id` (set on band-3, cleared by `corh_release`); else 0 (W10).
- `corh_event_count` → `u64` total overrun+release events this process (monotone; mirrors the witness-fragment count produced by this module). Value-typed.

## Constant Namespace
PREFIX = `CORH_` (the **dispatch-assigned** prefix). **Decision:** the gospel candidate body uses `COH_`; the dispatch directs `CORH_`. I adopt `CORH_` and rename every `coh_*` symbol → `corh_*`, because (a) the dispatch is authoritative, and (b) `CORH_` is more collision-resistant — a future "coherence" module would naturally claim `COH_`. **Collision check** (`grep -rn` over `STDLIB/`): `CORH_` → **no matches**; `COH_` → **no matches**; `module aether_cost_overrun_handler` → **no matches**; `fn corh_` / `fn coh_` → **no matches**. Both prefixes are free; `CORH_` chosen. (Trap 2 satisfied: every module-scope const is `CORH_`-prefixed and globally unique.)

Module-level constants (every `const NAME : T = V`, all `CORH_`-prefixed):
```
const CORH_OK            : i32 =  0i32
const CORH_E_NULL        : i32 = -1i32
const CORH_E_NOT_INITED  : i32 = -2i32
const CORH_E_FULL        : i32 = -3i32
const CORH_E_DENIED      : i32 = -4i32
const CORH_E_OVERRUN     : i32 = -5i32     // admitted-no: minor excess (band 1), refused
const CORH_E_QUARANTINE  : i32 = -6i32     // refused + op-kind quarantined (band >= 2)
const CORH_E_RERATIFY    : i32 = -7i32     // refused + quarantined + reratify requested (band 3)

const CORH_SEV_NONE      : i32 =  0i32     // observed <= declared in every dim
const CORH_SEV_MINOR     : i32 =  1i32     // exceeds in >=1 dim by < 2x
const CORH_SEV_MAJOR     : i32 =  2i32     // exceeds by >= 2x in some dim (non-critical)
const CORH_SEV_CRITICAL  : i32 =  3i32     // >= 2x in a CRITICAL dim, OR exceeds in ALL 6 dims

const CORH_DIM           : u64 = 6u64      // cost-vector arity (matches CL_DIM, Module 22)
const CORH_SLOTS         : u64 = 1024u64   // op-kind table bound (gospel-stated)
const CORH_ID_BYTES      : u64 = 32u64     // identifier width (matches IDENT_BYTES)

const CORH_SAT           : u64 = 0xFFFFFFFFFFFFFFFFu64   // saturated-multiply sentinel
const CORH_SLOT_NONE     : u32 = 0xFFFFFFFFu32           // find/alloc absence sentinel

// CRITICAL-dimension mask: bit k set => dimension k is constitutionally critical.
// Fixed at compile time (NOT learned): latency (bit0) and energy (bit5).
const CORH_CRIT_MASK     : u32 = 0x21u32                 // 0b100001 = dims {0,5}

// Witness pillar tags (event kind in the wh_publish pillar slot).
const CORH_PILLAR_OVERRUN : u16 = 0x51u16                // 81 = this module's gospel #
const CORH_PILLAR_RELEASE : u16 = 0x52u16

// Capability right required to ESCALATE / RELEASE (re-exported value, not the symbol).
const CORH_RIGHT_AMEND    : u64 = 0x4000u64              // == aether_capability::CAP_RIGHT_AMEND
```
Note: `CORH_RIGHT_AMEND` duplicates the *value* of `CAP_RIGHT_AMEND` (`0x4000u64`) as a local named constant so the source is self-documenting; the authoritative source is `aether/capability.iii` and the value is asserted equal in a KAT. `CORH_SAT` and `CORH_SLOT_NONE` carry distinct meanings (arithmetic saturation vs. slot-absence) at distinct widths (u64 vs u32) so both are named.

## Data Structures
All module-scope, statically sized (W8); **no local `var` arrays** (Trap 7). The 6-dim staging rows and the overrun-event scratch are module-scope (the handler is serialized / non-reentrant — acceptable for an immune chokepoint; noted under M-posture).
```
var CORH_INITED        : u8  = 0u8
var CORH_OP_IDS        : [u8;  32768]   // CORH_SLOTS * 32 = 1024 * 32 identifier bytes
var CORH_COUNTS        : [u64; 1024]    // overrun count per slot (provenance)
var CORH_LIVE          : [u8;  1024]    // slot occupied flag
var CORH_QUARANTINE    : [u8;  1024]    // slot quarantined flag (recoverable)
var CORH_RERATIFY      : [u8;  1024]    // slot reratification-request-pending flag
var CORH_EVENTS        : u64 = 0u64     // total witnessed events (overrun + release)

// --- witness-payload + classification scratch (module-scope; Trap 7 fix) ---
var CORH_PAYLOAD       : [u8;  128]     // op_id[32] ‖ dim_mask[4] ‖ declared[48] ‖ observed[48] = 132? see note
var CORH_FRAG_ID       : [u8;  32]      // wh_publish out_frag_id sink
var CORH_ZERO_ID       : [u8;  32]      // canonical zero producer/opid/in_commit/antecedents
```
Payload-size note: the witnessed payload is `op_id(32) ‖ dim_mask(4 LE) ‖ severity(1) ‖ declared(6*8=48) ‖ observed(6*8=48)` = 133 bytes; `CORH_PAYLOAD` is sized `[u8; 160]` (next 32-aligned headroom) rather than the 128 shown above — **the skeleton uses `[u8; 160]`**. (The 128 line above is corrected in the skeleton; recorded here so the bound is explicit: 133 used ≤ 160 reserved, W8.)

Bound justification: `CORH_SLOTS = 1024` distinct operation kinds is the gospel-stated bound — operation *kinds* (not instances) are a small, bounded vocabulary (the XII op-id space and the cycle taxonomy are < 1024 kinds); 1024 × (32 + 8 + 1 + 1 + 1) = ~43 KiB BSS, trivially static. The table never compacts: `CORH_LIVE` transitions 0→1 at first sighting and is cleared only by `corh_init`; quarantine is 0↔1 (set on band≥2, cleared by `corh_release`). No reentrancy: the table + scratch are process-global by design (a process-wide immune registry); all reads after init are pure. **Trap-4 discipline:** the slot→byte-offset `slot * 32` is computed as `(slot as u64) & 0xFFFFFFFFu64` then `* 32u64`, and op-id addresses are formed as `((&CORH_OP_IDS as u64) + off) as *u8` (the witness_hook.iii house idiom), never `&CORH_OP_IDS[expr]` (the documented element-address hazard).

## Dependencies (externs)
Each with the providing module's gospel NN. Signatures **verified against the real provider file** (not the gospel's externs).
```
// --- identifier (Module 01, BUILT — STDLIB/iii/numera/identifier.iii) ---
extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"

// --- witness hook (Module 07, BUILT — STDLIB/iii/aether/witness_hook.iii) ---
// VERIFIED: returns u64 (fragment index; sentinel 0xFFFFFFFFFFFFFFFFu64 on failure), 12 params.
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

// --- capability (Module gospel-08, BUILT — STDLIB/iii/aether/capability.iii) ---
// VERIFIED: cap_verify_rights(id:u64, required:u64) -> u8 ; CAP_RIGHT_AMEND = 0x4000u64.
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
```
All three providers are **BUILT** (read and confirmed on disk). This module externs nothing that is not-yet-built **for its primary, fully-deterministic path**.

**Deliberately NOT externed (and why):**
- `cost_lattice.iii` (Module 22) — the product-order test `observed ⊑ declared` is six unsigned u64 comparisons; re-deriving it in-module (a 6-iteration counted loop with a `not_le` sentinel) avoids a cross-layer call into a module whose own spec is still PARTIAL/not-yet-built, keeps this handler self-contained (M1), and removes a wave-ordering dependency. (If Phase 2 prefers the shared symbol, `cl_le_product(observed, declared)` is signature-compatible — but it is **not-yet-built**, so the in-module derivation is the buildable choice.) Listed so the scheduler knows Module 81 does **not** block on Module 22.
- `at_advance`/`at_current` (Module 03) — **not** externed directly: `wh_publish` already advances algebraic time internally (verified: it calls `at_advance()`), so this module gets monotone witnessed time for free without a second clock writer (W16/W17; algebraic_time's contract is "only witness_hook may advance it").

**Not-yet-built dependency (FLAGGED — optional full-fidelity path only):**
- `constitution` / `cons_*` (the gospel prose's "request constitutional re-ratification through the operator ceremony"). **No built provider exists** (`grep -rln "fn cons_find" STDLIB/iii/` → empty; the only `cons_*` hits are in `omnia/xii_horizon.iii`, which is the XII *ceremony lattice*, not a constitution-clause registry). The systemic-defect note's `cons_find -> u32 sentinel 0xFFFFFFFFu32` therefore has no symbol to bind to today. **Resolution (maximal, buildable now):** escalation is realized by **publishing a re-ratification-request witness fragment** (pillar `CORH_PILLAR_OVERRUN`, a distinguished `revtag`/payload band-3 marker) which the operator ceremony consumes out-of-band — this needs **no constitution extern**. The full-fidelity direct hook is the optional extern below, marked not-yet-built so the wave scheduler can order a future wiring; the module compiles and passes its KATs **without** it.
  ```
  // OPTIONAL / NOT-YET-BUILT — wire when a constitution provider lands:
  // extern @abi(c-msvc-x64) fn cons_request_reratification(op_id: *u8, clause: u32, cap: u64) -> i32 from "constitution.iii"
  ```

## Algorithm
Determinism (M2) and bit-identity (W5): every operation is fixed-width integer arithmetic over u64/u32/u8 with no floating point, no data-dependent control beyond bounded counted loops, fixed dimension `CORH_DIM = 6`. Identical `(op_id, declared, observed, cap)` → identical refusal verdict, identical severity band, identical witnessed payload bytes (hence identical fragment id), every run, every CPU. No ML/heuristics (M3/M4): the product-order test and severity bands are exact integer algebra; the CRITICAL-dimension set is a compile-time constant mask, never learned. No recursion (W15) — all loops counted with index < bound. NIH (M1): hand-rolled product-order test, hand-rolled saturating multiply for the ×2 band test, hand-rolled little-endian field serialization; no library calls beyond the three verified externs.

**`corh_init`** — Counted loop `s` in `0..CORH_SLOTS`: clear `CORH_LIVE[s]=0`, `CORH_COUNTS[s]=0`, `CORH_QUARANTINE[s]=0`, `CORH_RERATIFY[s]=0`. Zero `CORH_ZERO_ID[0..32)` (canonical zero producer). Set `CORH_EVENTS=0`, `CORH_INITED=1`. Return `CORH_OK`. Re-entrant: a second call re-clears identically (M2). W14 sentinel/counter form, no `break`.

**`corh_find_slot`** (internal, `op_id: *u8) -> u32`) — linear scan `i` in `0..CORH_SLOTS` driven by a `found` sentinel flag (W14, no `break`): if `CORH_LIVE[i]==1` and `ident_eq(((&CORH_OP_IDS as u64)+ (i&0xFFFFFFFFu64)*32u64) as *u8, op_id)==1` then record `i` and set the flag. Return the found index or `CORH_SLOT_NONE`. **u32 sentinel** (not `i64 -1`) → no signed-ordering compare (Trap 3 avoided); the only comparison is `== CORH_SLOT_NONE` (equality, W11).

**`corh_alloc_slot`** (internal, `op_id: *u8) -> u32`) — first try `corh_find_slot`; if found, return it (idempotent). Else scan for the first `CORH_LIVE[j]==0` (sentinel-flag driven), `ident_copy(op_id, ((&CORH_OP_IDS as u64)+(j&0xFFFFFFFFu64)*32u64) as *u8)`, set `CORH_LIVE[j]=1`, `CORH_COUNTS[j]=0`, return `j`. If no free slot, return `CORH_SLOT_NONE` (caller maps to `CORH_E_FULL` — fixing the candidate's `COH_E_NULL`-for-full conflation, W12).

**`corh_severity`** (the exact-algebraic classifier — M3/M4 core) — Null `declared`/`observed` → return `CORH_SEV_NONE`. Counted loop `k` in `0..6` accumulating three exact facts into u32 flags (no division, no `%`, no float):
  1. `exceed_mask |= (1 << k)` iff `observed[k] > declared[k]` (unsigned u64 compare — safe).
  2. `times2` set iff `observed[k] >= sat_mul2(declared[k])` for some k, where `sat_mul2(x) = if x > (CORH_SAT >> 1) { CORH_SAT } else { x + x }` (hand-rolled saturating doubling; saturating so a huge declared can't wrap — M15). This is the exact "≥2× in some dimension" test with **no division-after-call** (Trap 11 avoided: it is addition, no `%`, and `declared[k]` is read into a local first).
  3. `crit2` set iff `times2-at-dim-k` holds **and** `(CORH_CRIT_MASK >> k) & 1 == 1` (≥2× in a critical dim).
  After the loop: if `exceed_mask == 0` → `CORH_SEV_NONE`. Else if `crit2 == 1` **or** `exceed_mask == 0x3Fu32` (all 6 dims exceeded) → `CORH_SEV_CRITICAL`. Else if `times2 == 1` → `CORH_SEV_MAJOR`. Else → `CORH_SEV_MINOR`. **Every branch is an exact integer predicate over the inputs; there is no tunable parameter, no accumulated state, no frequency.** Returns the band `i32`. Bit-identical (W5): the same `(declared,observed)` always yields the same band on the same CPU and every other.

**`corh_witness_event`** (internal, `op_id:*u8, dim_mask:u32, severity:i32, declared:*u64, observed:*u64, pillar:u16, revtag:u8) -> u64`) — Serialize the canonical payload into `CORH_PAYLOAD` (module-scope, Trap 7): bytes `[0..32)` = `op_id` (copied via a counted byte loop, **not** `ident_copy` into a sub-array, to keep the offset explicit); `[32..36)` = `dim_mask` little-endian (4 byte stores through `*u8`, masking each byte `(dim_mask >> (8*b)) & 0xFFu32` — Trap 5 avoided, no `*u32` store); `[36]` = `severity as u8`; `[37..85)` = `declared[0..6]` little-endian u64 (6×8 byte-by-byte stores); `[85..133)` = `observed[0..6]` likewise. Then `wh_publish(&CORH_ZERO_ID, op_id, &CORH_ZERO_ID, &CORH_ZERO_ID, revtag, severity_as_phase_u8, pillar, &CORH_ZERO_ID, 0u32, &CORH_PAYLOAD, 133u32, &CORH_FRAG_ID)`. `wh_publish` returns the fragment index (u64) or `0xFFFFFFFFFFFFFFFFu64` on failure; on success `CORH_EVENTS = CORH_EVENTS + 1`. Returns the wh_publish result. (M6/M10: the fragment id is Keccak256 over these exact bytes inside `wh_publish` — byte-recomputable from the recorded payload; algebraic time advances exactly once per event via `wh_publish`'s internal `at_advance`.)

**`corh_handle`** (internal core shared by `corh_admit`'s refusal branch and `corh_on_overrun`; `op_id:*u8, declared:*u64, observed:*u64, cap:u64) -> i32`) — Steps:
  1. `sev = corh_severity(declared, observed)`. If `sev == CORH_SEV_NONE` → return `CORH_OK` (no excess; admit). (This makes `corh_admit` total: the same product-order/severity logic decides admit-vs-refuse — the W37 gate.)
  2. `slot = corh_alloc_slot(op_id)`; if `slot == CORH_SLOT_NONE` → return `CORH_E_FULL`.
  3. `CORH_COUNTS[slot] = CORH_COUNTS[slot] + 1` (provenance only).
  4. Recompute `dim_mask` (the exceed mask) by the same `observed[k] > declared[k]` loop (or thread it out of `corh_severity` via a module-scope `CORH_LAST_MASK : u32` set by the classifier — the skeleton uses the shared module-scope mask to avoid recomputation while staying W13-clean).
  5. `corh_witness_event(op_id, dim_mask, sev, declared, observed, CORH_PILLAR_OVERRUN, 1u8)` — `revtag=1` (reversible: refusal changes nothing irrecoverably).
  6. **Verdict by band (structural, NOT count-threshold — M3):**
     - `sev == CORH_SEV_MINOR` → return `CORH_E_OVERRUN` (refused; not quarantined).
     - `sev == CORH_SEV_MAJOR` → `CORH_QUARANTINE[slot] = 1`; return `CORH_E_QUARANTINE`.
     - `sev == CORH_SEV_CRITICAL` → `CORH_QUARANTINE[slot] = 1`; then **escalation is gated**: if `cap_verify_rights(cap, CORH_RIGHT_AMEND) == 1u8` → `CORH_RERATIFY[slot] = 1`, publish a second band-3 re-ratification-request fragment (pillar `CORH_PILLAR_OVERRUN`, `revtag=0` = irreversible-request marker), return `CORH_E_RERATIFY`; else (cap insufficient) → return `CORH_E_QUARANTINE` (refusal + quarantine still apply unconditionally; only the *escalation* needs the cap — M8 privilege separation).
  **M3 avoidance (explicit):** the escalation trigger is the *band* (an exact function of magnitude on the **current** event), not a learned/accumulated count crossing a tuned bound. There is no `if count > N`. `CORH_COUNTS` is witnessed provenance, never a control input to the verdict. A single band-3 event escalates on its first occurrence; a thousand band-1 events never do. This is the `feedback_no_observational_learning` discipline: no count-and-promote, no threshold-trigger.

**`corh_admit`** — Not-inited → `CORH_E_NOT_INITED`. Null `op_id`/`declared`/`observed` (each `(p as u64) == 0u64`, a 64-bit null test — never a 16-bit narrow compare) → `CORH_E_NULL`. If `op_id`'s slot is already quarantined (`corh_is_quarantined(op_id)==1`) → witness a re-refusal fragment and return `CORH_E_QUARANTINE` immediately (a quarantined kind admits nothing until released — W37). Else delegate to `corh_handle(op_id, declared, observed, cap)` and return its status (which is `CORH_OK` on `observed ⊑ declared`, else the refusal/quarantine/reratify status).

**`corh_on_overrun`** — The prose-named reactive subscriber for out-of-band detections. Not-inited → `CORH_E_NOT_INITED`. Null `ev` → `CORH_E_NULL`. Decode the overrun-event aggregate `ev` (layout in Data Structures) into pointers `op_id = ev+0`, `declared = ev+33`, `observed = ev+81` (the `dim:u8` at `ev+32` is advisory; the authoritative mask is recomputed). Delegate to `corh_handle`. Returns the same status set as `corh_admit`'s refusal branch (note: a caller invoking `corh_on_overrun` asserts an overrun already happened, so `CORH_SEV_NONE` returning `CORH_OK` is the benign "no actual excess" case — still total).

**`corh_overrun_count`** — Not-inited or null → `0u64`. `slot = corh_find_slot(op_id)`; if `CORH_SLOT_NONE` → `0u64`; else return `CORH_COUNTS[slot]`.

**`corh_is_quarantined`** — Not-inited or null → `0u8`. `slot = corh_find_slot(op_id)`; if `CORH_SLOT_NONE` → `0u8`; else return `CORH_QUARANTINE[slot]`.

**`corh_release`** — The recovery / un-quarantine path (M5 no-bricking, M9 reversibility). Not-inited → `CORH_E_NOT_INITED`. Null `op_id` → `CORH_E_NULL`. **Capability gate first:** if `cap_verify_rights(cap, CORH_RIGHT_AMEND) != 1u8` → `CORH_E_DENIED` (lifting a quarantine is a privileged constitutional act — M8). `slot = corh_find_slot(op_id)`; if `CORH_SLOT_NONE` → `CORH_E_NULL` (unknown op). Clear `CORH_QUARANTINE[slot]=0`, `CORH_RERATIFY[slot]=0`. Witness a release fragment (`corh_witness_event` with a zero declared/observed pair, pillar `CORH_PILLAR_RELEASE`, `revtag=1`). Return `CORH_OK`. (Counts are **not** reset — provenance is append-only; only the live quarantine state reverses.)

**`corh_reratification_pending`** — Not-inited or null → `0u8`. `slot = corh_find_slot(op_id)`; if `CORH_SLOT_NONE` → `0u8`; else return `CORH_RERATIFY[slot]`.

**`corh_event_count`** — Return `CORH_EVENTS` (0 if not-inited, since init zeroes it).

## KAT Vectors (>= 3)
Cost vectors as `(latency, throughput, regp, icache, dcache, energy)`. All checks byte-for-byte on the exact `i32`/`u8`/`u64` return, or on the witnessed event count. Op-ids are 32-byte identifiers (KAT uses distinguishable fill patterns).

1. **Admit within budget + severity classification (the W37 gate, happy path).** `corh_init()`. `op = ident(fill 0x01)`. `declared = (100,100,100,100,100,100)`. `observed_ok = (50,40,10,10,10,0)`. `corh_admit(op, declared, observed_ok, cap_root)` → `CORH_OK` (observed ⊑ declared in every dim). `corh_severity(declared, observed_ok)` → `CORH_SEV_NONE (0)`. `corh_overrun_count(op)` → `0` (admit records nothing). `corh_event_count()` → `0` (no fragment for an admit). `corh_is_quarantined(op)` → `0`.

2. **Minor overrun → refuse, witness, no quarantine.** Same `op`, `declared`, but `observed_minor = (150,40,10,10,10,0)` (latency 150 > 100, ratio 1.5× < 2×). `corh_severity(declared, observed_minor)` → `CORH_SEV_MINOR (1)`. `corh_admit(op, declared, observed_minor, cap_root)` → `CORH_E_OVERRUN (-5)` (refused). `corh_overrun_count(op)` → `1`. `corh_event_count()` → `1` (one overrun fragment published). `corh_is_quarantined(op)` → `0` (minor does not quarantine). `corh_reratification_pending(op)` → `0`.

3. **Major overrun → refuse + quarantine; subsequent admit blocked until release.** `observed_major = (50,250,10,10,10,0)` (throughput 250 ≥ 2×100, throughput is non-critical → MAJOR). `corh_severity` → `CORH_SEV_MAJOR (2)`. `corh_admit(op, declared, observed_major, cap_root)` → `CORH_E_QUARANTINE (-6)`; `corh_is_quarantined(op)` → `1`; `corh_overrun_count(op)` → `2`. Now even a *within-budget* admit is refused: `corh_admit(op, declared, observed_ok, cap_root)` → `CORH_E_QUARANTINE (-6)` (quarantine blocks all). Release with the AMEND cap: `corh_release(op, cap_root)` → `CORH_OK`; `corh_is_quarantined(op)` → `0`; `corh_event_count()` → `4` (overrun#2 + re-refusal#3 + release#4). After release, `corh_admit(op, declared, observed_ok, cap_root)` → `CORH_OK` again. Counts persist: `corh_overrun_count(op)` → `3` (the blocked-admit also recorded? — **no**: a quarantine re-refusal does NOT increment the overrun count; it is the *same* unresolved overrun; count stays `2`). [KAT asserts `2`.]

4. **Critical overrun → escalation is capability-gated (M8 privilege separation).** `op2 = ident(fill 0x02)`. `observed_crit = (300,40,10,10,10,0)` (latency 300 ≥ 2×100 **and** latency ∈ CORH_CRIT_MASK → CRITICAL). `corh_severity(declared, observed_crit)` → `CORH_SEV_CRITICAL (3)`. (a) With a cap **lacking** AMEND (`cap_noamend`): `corh_admit(op2, declared, observed_crit, cap_noamend)` → `CORH_E_QUARANTINE (-6)` (refused+quarantined, but escalation withheld); `corh_reratification_pending(op2)` → `0`. (b) Re-run on a fresh `op3 = ident(fill 0x03)` with the AMEND cap (`cap_root`): `corh_admit(op3, declared, observed_crit, cap_root)` → `CORH_E_RERATIFY (-7)`; `corh_is_quarantined(op3)` → `1`; `corh_reratification_pending(op3)` → `1`. (c) `corh_release(op3, cap_noamend)` → `CORH_E_DENIED (-4)` (release needs AMEND); `corh_release(op3, cap_root)` → `CORH_OK`; `corh_reratification_pending(op3)` → `0`. **M3 proof clause:** classification depends only on the single event's magnitude — `op3` escalates on its *first* critical event (count `1`), and `op` in KAT 2 never escalates despite repeated minor events; the escalation is band-driven, not count-driven.

5. **Capability-right value pin + null/uninit guards (negative cases — prove the gate FAILS).** Assert `CORH_RIGHT_AMEND == 0x4000u64` equals `cap_verify_rights`'s expected AMEND bit (cross-checked by minting a cap with exactly `0x4000u64` and confirming `corh_release` succeeds, and a cap with `0x4000u64` cleared and confirming `corh_release` → `CORH_E_DENIED`). Before `corh_init`: `corh_admit(op, declared, observed_minor, cap_root)` → `CORH_E_NOT_INITED (-2)`. After init: `corh_admit(0-ptr, declared, observed_minor, cap_root)` → `CORH_E_NULL (-1)`; `corh_on_overrun(0-ptr, cap_root)` → `CORH_E_NULL`; `corh_severity(0-ptr, observed)` → `CORH_SEV_NONE`. `corh_overrun_count(unknown_op)` → `0`; `corh_is_quarantined(unknown_op)` → `0`.

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — exposed (9 public + 4 internal sigs). Avoidance: every signature single-line; verified in Skeleton.
- **Trap 2 (module-level `const` global)** — exposed (~22 consts). Avoidance: every const `CORH_`-prefixed; grep confirms `CORH_` and `COH_` both collision-free in `STDLIB/`. `CORH_` adopted (dispatch-authoritative; renames the gospel's `COH_`).
- **Trap 3 (signed-ordering SIGSEGV)** — **NOT exposed.** No `i64`/`i32` ordering compare anywhere. Slot indices use the `u32` sentinel `CORH_SLOT_NONE` (compared `==`/`!=` only, W11). The candidate's `found : i64 = -1i64` is **replaced** by `u32`/`0xFFFFFFFFu32` (capability.iii / cost_lattice house style) to dodge i64 entirely. All magnitude compares (`observed[k] > declared[k]`, `observed[k] >= 2x`) are **u64** (unsigned — safe). The only `i32`s are status/severity constants, used as return values and compared by equality.
- **Trap 4 (u32-in-u64-slot garbage)** — exposed at the `slot*32` op-id address computation. Avoidance: mask `(slot as u64) & 0xFFFFFFFFu64` **before** the `* 32u64` pointer arithmetic, and form addresses as `((&CORH_OP_IDS as u64) + off) as *u8` — never `&CORH_OP_IDS[expr]`.
- **Trap 5 (u32 pointer store width)** — exposed in the witness-payload serializer (writing `dim_mask:u32` and the cost u64s into the byte buffer). Avoidance: **all stores byte-by-byte through `*u8`** with explicit `(v >> (8*b)) & 0xFFu32`/`& 0xFFu64` extraction; no `*u32`/`*u64` element stores into the payload. (`CORH_COUNTS[slot]=…u64` and `CORH_EVENTS=…u64` are full-width u64 array/scalar stores of u64 values — not the narrowing hazard.)
- **Trap 6 (nested block comments)** — avoided: no `/* */` nesting; inline notes use `//`.
- **Trap 7 (local `var` arrays)** — exposed (would-be locals: the payload buffer, the frag-id sink, the zero-id, the staging). Avoidance: **all are module-scope** (`CORH_PAYLOAD`, `CORH_FRAG_ID`, `CORH_ZERO_ID`). Serialized/non-reentrant handler — acceptable for a process-wide immune chokepoint; noted in M-posture.
- **Trap 8 (`} else {` split)** — avoided: every `else` written `} else {` single-line; the band verdict prefers guard-style early `if … return` over deep `else` chains.
- **Trap 9 (em-dash in comment)** — avoided: ASCII `--` only in all comments.
- **Trap 10 (`let mut` checkpoint flag)** — touched by the `found`/`not_le`/`exceed_mask`/`times2`/`crit2` sentinels. Avoidance: where a clean early return expresses the logic (`corh_find_slot` returns on hit), prefer it; where the loop must complete (the 6-dim severity scan, the slot scan), the flag drives the **loop condition itself** (the iiis-1 insertion-sort lesson) rather than being a post-hoc mutated boolean, and the masks are accumulator u32s, not checkpoint booleans.
- **Trap 11 (`a % b` after call)** — **NOT exposed.** No `%` anywhere. The ≥2× test uses hand-rolled **saturating addition** (`x + x` with overflow guard), not division; `declared[k]` is read into a local before use, so the param-spill quotient family cannot apply.
- **Trap 12 (`@specialize *T` stride)** — **NOT exposed.** No `@specialize`; all pointers are concrete `*u8`/`*u64`; `declared[k]`/`observed[k]` stride 8 bytes correctly (concrete `*u64`).

## Gap / Fix List
The candidate is a STUB. Every missing piece + every mandate/law/trap issue in the gospel body, each with its fix:

1. **No refusal / quarantine — the module's entire reason to exist (W37/M19).** The candidate only increments a counter; it never refuses or quarantines, so "cost lattice excess" is *silently tolerated* — the exact W37 violation. **Fix:** `corh_admit` (the product-order gate that returns a refusal status), `corh_is_quarantined`, `corh_release`, and the band-driven quarantine in `corh_handle`.
2. **No witness fragment (M6/M10 violated).** A state-transition immune module that emits no provenance is unwitnessed. **Fix:** `corh_witness_event` routes every overrun and release through the verified `wh_publish` (Module 07) with a canonical, byte-recomputable payload.
3. **No severity (prose: "raise an event of severity matching the dimension and magnitude").** **Fix:** `corh_severity` — exact-integer band classifier (NONE/MINOR/MAJOR/CRITICAL) over (exceed-mask, ≥2× test, critical-dim mask), zero heuristics (M3/M4).
4. **No capability check (M8 violated).** Overrun handling and quarantine-lifting are privileged immune actions; the candidate checks nothing. **Fix:** `cap_verify_rights(cap, CORH_RIGHT_AMEND)` gates *escalation* and `corh_release`; refusal/quarantine are unconditional (privilege-separated).
5. **No re-ratification path (prose: "request constitutional re-ratification").** **Fix:** band-3 escalation publishes a re-ratification-request fragment and sets `CORH_RERATIFY`; the direct constitution hook is flagged not-yet-built (`cons_request_reratification`) with a buildable witness-fragment fallback that needs no missing extern.
6. **M3 hazard latent in the prose ("on repeated overruns … request re-ratification").** A naive `if count > N` would be count-and-threshold ML. **Fix:** escalation triggers on the **band** of the *current* event (a structural invariant), not on an accumulated count crossing a tuned bound; `CORH_COUNTS` is witnessed provenance only, never a verdict input. Stated as a proof clause in KAT 4.
7. **W12 conflation in `coh_on_overrun`** — returns `COH_E_NULL` when the *table is full* (a full table is not a null pointer). **Fix:** `CORH_E_FULL` distinct from `CORH_E_NULL`; `corh_alloc_slot` returns `CORH_SLOT_NONE` → mapped to `CORH_E_FULL`.
8. **`&ARR[expr]` element-address hazard.** The candidate passes `&COH_OP_IDS[i * 32u64]` to `ident_eq`/`ident_copy`; the realized substrate (witness_hook.iii) documents element-address as an iiis hazard. **Fix:** `((&CORH_OP_IDS as u64) + off) as *u8` idiom throughout, with `off` masked (Trap 4).
9. **`found : i64 = -1i64` signed sentinel.** Although the candidate compares it by equality (W11-safe), it introduces an `i64` where the house style uses `u32`/`0xFFFFFFFFu32`. **Fix:** switch internal find/alloc to the `u32` sentinel `CORH_SLOT_NONE` (matches capability.iii, dodges Trap 3 entirely).
10. **No `corh_event_count` / observability.** The prose's "raise an event" implies events are countable/auditable. **Fix:** `CORH_EVENTS` monotone counter + `corh_event_count` accessor, mirroring the fragment count.
11. **PREFIX mismatch (`COH_` body vs `CORH_` dispatch).** **Fix:** adopt `CORH_` (dispatch-authoritative, more collision-resistant); rename all symbols; both verified collision-free.

**Systemic gospel defects touched (corrected + flagged):**
- **witness emit** — the candidate doesn't emit at all; the real primitive `wh_publish` (verified `-> u64`, 12 params, sentinel `0xFFFFFFFFFFFFFFFFu64`) is used. No fictional `ws_emit_fragment`.
- **capability** — `cap_verify` does not exist; `cap_verify_rights(id:u64, required:u64) -> u8` (verified) is used with the real `CAP_RIGHT_AMEND = 0x4000u64`.
- **constitution** — `cons_find` has **no built provider** (verified: only `omnia/xii_horizon.iii` mentions `cons_*`, and that is the XII ceremony lattice, not a clause registry); flagged not-yet-built; escalation realized via witness fragment instead, so the module is buildable now.
- **algebraic time** — `at_now` fiction avoided; time advances via `wh_publish`'s internal `at_advance` (verified), so no second clock writer (W16/W17, algebraic_time's single-writer contract).
- **witness_hook accessors** — this module is a *producer* (calls `wh_publish`), not a consumer of fragment fields, so the Phase-2 getter gap does not affect it; no extra externs needed.

**Mandate posture after fixes:** M1 (3 verified externs + hand-rolled product-order/severity/serialize; in-module product-order avoids a cross-layer call) ✓; M2/W5 (fixed-width integer, no FP, counted loops, byte-canonical payload) ✓; M3/M4 (exact band algebra, compile-time critical mask, band-triggered escalation — no count-threshold, no learning) ✓ (the central M3 argument; cites `feedback_no_observational_learning`); M5 (refuse/quarantine are recoverable; `corh_release` reverses; counts append-only; nothing bricked) ✓; M6/M10 (every event witnessed via `wh_publish`, payload byte-recomputable → frag id reproducible) ✓; M7 (R0 — confirmed against gospel header) ✓; M8 (escalation + release require `CAP_RIGHT_AMEND`; refusal is unconditional; privilege-separated) ✓; M9 (refusal is the reversible default; quarantine is capability-reversible) ✓; M13/M20 (the module *requests* re-ratification; it never amends the constitution itself — self-reasoning stays within the governed boundary) ✓; M15 (saturating doubling totalizes the ≥2× test) ✓; M19 (this module IS the M19 enforcement point — every operation's cost is bounded *because* this gate refuses the unbounded) ✓.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/cost_overrun_handler.iii
 *
 * III STDLIB - aether::cost_overrun_handler
 *
 * Immune enforcement for cost-lattice boundedness (M19/W37).  The chokepoint
 * through which work whose OBSERVED 6-dim cost exceeds its DECLARED budget is
 * refused, quarantined, witnessed, and -- when structurally critical --
 * escalated toward constitutional re-ratification.  Does NOT measure cost
 * (cost_calculus, M23) nor order it (cost_lattice, M22); it ENFORCES the
 * verdict: admit iff observed <= declared componentwise; refuse otherwise.
 *
 * Severity is an exact integer band over (which dims exceeded, by what integer
 * multiple) -- never heuristic.  Escalation fires on the band of the CURRENT
 * event (a structural invariant), NEVER on an accumulated count crossing a
 * tuned bound (M3: no count-and-promote, no threshold-trigger, no learning).
 *
 * Public API:
 *   corh_init() -> i32
 *   corh_admit(op_id, declared, observed, cap) -> i32        // the W37 gate
 *   corh_on_overrun(ev, cap) -> i32                          // reactive subscriber
 *   corh_severity(declared, observed) -> i32                 // exact band classifier
 *   corh_overrun_count(op_id) -> u64
 *   corh_is_quarantined(op_id) -> u8
 *   corh_release(op_id, cap) -> i32                          // capability-gated recovery
 *   corh_reratification_pending(op_id) -> u8
 *   corh_event_count() -> u64
 *
 * Cost vector dims: 0 latency  1 throughput  2 regp  3 icache  4 dcache  5 energy
 * CRITICAL dims (compile-time, NOT learned): {0 latency, 5 energy} = CORH_CRIT_MASK.
 *
 * Hexad: kind_repair.  Ring: R0.  K: 1.00.
 * Discipline: W2 (aggregates by ptr), W8 (1024-slot bound), W12, W14, W37.
 */

module aether_cost_overrun_handler

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
// OPTIONAL / NOT-YET-BUILT (no constitution provider on disk today):
// extern @abi(c-msvc-x64) fn cons_request_reratification(op_id: *u8, clause: u32, cap: u64) -> i32 from "constitution.iii"

const CORH_OK            : i32 =  0i32
const CORH_E_NULL        : i32 = -1i32
const CORH_E_NOT_INITED  : i32 = -2i32
const CORH_E_FULL        : i32 = -3i32
const CORH_E_DENIED      : i32 = -4i32
const CORH_E_OVERRUN     : i32 = -5i32
const CORH_E_QUARANTINE  : i32 = -6i32
const CORH_E_RERATIFY    : i32 = -7i32

const CORH_SEV_NONE      : i32 =  0i32
const CORH_SEV_MINOR     : i32 =  1i32
const CORH_SEV_MAJOR     : i32 =  2i32
const CORH_SEV_CRITICAL  : i32 =  3i32

const CORH_DIM           : u64 = 6u64
const CORH_SLOTS         : u64 = 1024u64
const CORH_ID_BYTES      : u64 = 32u64

const CORH_SAT           : u64 = 0xFFFFFFFFFFFFFFFFu64
const CORH_SLOT_NONE     : u32 = 0xFFFFFFFFu32
const CORH_CRIT_MASK     : u32 = 0x21u32      // dims {0 latency, 5 energy}
const CORH_ALL6_MASK     : u32 = 0x3Fu32      // all six dims exceeded
const CORH_PILLAR_OVERRUN : u16 = 0x51u16     // 81
const CORH_PILLAR_RELEASE : u16 = 0x52u16
const CORH_RIGHT_AMEND    : u64 = 0x4000u64   // == aether_capability::CAP_RIGHT_AMEND

var CORH_INITED        : u8  = 0u8
var CORH_OP_IDS        : [u8;  32768]    // 1024 * 32
var CORH_COUNTS        : [u64; 1024]
var CORH_LIVE          : [u8;  1024]
var CORH_QUARANTINE    : [u8;  1024]
var CORH_RERATIFY      : [u8;  1024]
var CORH_EVENTS        : u64 = 0u64
var CORH_LAST_MASK     : u32 = 0u32       // exceed-mask threaded from corh_severity

var CORH_PAYLOAD       : [u8;  160]       // op_id32 ‖ mask4 ‖ sev1 ‖ decl48 ‖ obs48 = 133 used
var CORH_FRAG_ID       : [u8;  32]
var CORH_ZERO_ID       : [u8;  32]

// --- lifecycle ---

fn corh_init() -> i32 @export {
    // TODO: body per Algorithm corh_init -- clear all 4 per-slot arrays + counts;
    // zero CORH_ZERO_ID; CORH_EVENTS=0; CORH_INITED=1 (W14 counted loop).
}

// --- internal slot registry (u32 sentinel; no i64) ---

fn corh_find_slot(op_id: *u8) -> u32 {
    // TODO: body per Algorithm corh_find_slot -- found-flag scan; ident_eq via
    // ((&CORH_OP_IDS as u64)+(i&0xFFFFFFFFu64)*32u64) as *u8; return slot|CORH_SLOT_NONE.
}

fn corh_alloc_slot(op_id: *u8) -> u32 {
    // TODO: body per Algorithm corh_alloc_slot -- find first; else first free,
    // ident_copy in (masked offset idiom), set live, count=0; else CORH_SLOT_NONE.
}

// --- exact-algebraic severity (M3/M4 core: no thresholds, no learning) ---

fn corh_severity(declared: *u64, observed: *u64) -> i32 @export {
    // TODO: body per Algorithm corh_severity -- null -> SEV_NONE. 6-dim loop:
    // exceed_mask (observed>declared), times2 (observed>=sat_mul2(declared)),
    // crit2 (times2 & CORH_CRIT_MASK bit). Set CORH_LAST_MASK=exceed_mask.
    // crit2|all6 -> CRITICAL; times2 -> MAJOR; exceed -> MINOR; else NONE.
    // sat_mul2(x) inline: if x > (CORH_SAT>>1) {CORH_SAT} else {x+x}.  No '%','/'.
}

// --- internal witness emit (M6/M10) ---

fn corh_witness_event(op_id: *u8, dim_mask: u32, severity: i32, declared: *u64, observed: *u64, pillar: u16, revtag: u8) -> u64 {
    // TODO: body per Algorithm corh_witness_event -- serialize canonical 133-byte
    // payload into CORH_PAYLOAD (byte-by-byte *u8 stores, LE; Trap 5); wh_publish
    // with CORH_ZERO_ID producer/in/out/ante, payload_len=133u32; CORH_EVENTS+=1.
}

// --- internal core verdict (shared by admit refusal-branch + on_overrun) ---

fn corh_handle(op_id: *u8, declared: *u64, observed: *u64, cap: u64) -> i32 {
    // TODO: body per Algorithm corh_handle -- sev=corh_severity; NONE->CORH_OK.
    // slot=corh_alloc_slot (NONE->E_FULL); count+=1; witness overrun (revtag=1).
    // MINOR->E_OVERRUN; MAJOR->quarantine,E_QUARANTINE; CRITICAL->quarantine, then
    // if cap_verify_rights(cap,CORH_RIGHT_AMEND)==1 -> reratify=1, witness band-3
    // request (revtag=0), E_RERATIFY; else E_QUARANTINE.  (band-triggered, NOT count.)
}

// --- public enforcement surface ---

fn corh_admit(op_id: *u8, declared: *u64, observed: *u64, cap: u64) -> i32 @export {
    // TODO: body per Algorithm corh_admit -- not-inited->E_NOT_INITED; null ptrs
    // (p as u64 ==0)->E_NULL; if corh_is_quarantined(op_id)==1 -> witness re-refusal,
    // E_QUARANTINE; else return corh_handle(...).
}

fn corh_on_overrun(ev: *u8, cap: u64) -> i32 @export {
    // TODO: body per Algorithm corh_on_overrun -- not-inited->E_NOT_INITED; null ev
    // ->E_NULL; decode op_id=ev+0, declared=ev+33, observed=ev+81; corh_handle(...).
}

fn corh_release(op_id: *u8, cap: u64) -> i32 @export {
    // TODO: body per Algorithm corh_release -- not-inited->E_NOT_INITED; null->E_NULL;
    // cap gate (cap_verify_rights !=1 -> E_DENIED); slot=find (NONE->E_NULL);
    // clear quarantine+reratify; witness release (pillar RELEASE, revtag=1); CORH_OK.
}

// --- queries (W10/W12) ---

fn corh_overrun_count(op_id: *u8) -> u64 @export {
    // TODO: body per Algorithm corh_overrun_count -- not-inited|null->0; find; count|0.
}

fn corh_is_quarantined(op_id: *u8) -> u8 @export {
    // TODO: body per Algorithm corh_is_quarantined -- not-inited|null->0; find; flag|0.
}

fn corh_reratification_pending(op_id: *u8) -> u8 @export {
    // TODO: body per Algorithm corh_reratification_pending -- not-inited|null->0; find; flag|0.
}

fn corh_event_count() -> u64 @export {
    // TODO: body per Algorithm corh_event_count -- return CORH_EVENTS.
}
```
