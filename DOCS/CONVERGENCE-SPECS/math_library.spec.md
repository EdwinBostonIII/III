# 66 numera/math_library.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is structurally near-complete and W-law clean in shape, but it is **not buildable as written** and carries semantic defects: it externs a function that does not exist anywhere (`ws_emit_fragment`), it mis-types and inverts the `cons_find` clause-presence check (wrong return type + wrong sentinel), it declares 8 local `[u8;N]` arrays (Trap 7, unparseable on iiis-0), it uses the wrong const PREFIX (`LIB_` instead of the assigned `MATHLIB_`), and it leaves a TODO-grade witness payload. Three of its four cross-module dependencies are themselves not-yet-built. Every gap is enumerated in §Gap/Fix with the exact correction; the maximal intent (full admission ceremony + dependency-closure gate + refinement provenance + replayable witness) is preserved.

## Purpose
`numera_math_library` is the substrate's **accumulated formal knowledge**: the append-only, curated index of admitted theorem carriers. It admits a carrier only after (a) the `cp_library_admit` constitutional clause is present, (b) the carrier is `tc_verify`-clean, (c) it is not already present, and (d) its entire declared dependency closure is already present in the library (M14 / W45). It serves citation queries (`lib_cite`, W49 — no citation of an absent entry), ordered retrieval (`lib_at`), and refinement admission (`lib_refine`) that records the refinee identifier as provenance while retaining the original entry forever. Every admission emits a replayable witness fragment (M6/M10). Hexad: `kind_essence + kind_cognition`. Ring: **R0**. K: **1.00**.

## Public API
All signatures single-line (Trap 1). Error/status convention: every public fn returns a status — negative-`i32` error codes (W9) or a sentinel-typed value (`lib_size` returns a count, never an error; it is total). Boolean-style outcomes are folded into the `i32` status (W10 not needed — no `u8` returns here). Every public fn returns a status (W12).

```iii
fn lib_init() -> i32 @export
fn lib_admit(carrier_id: *u8, curator_capability: *u8, out_frag_id: *u8) -> i32 @export
fn lib_cite(carrier_id: *u8) -> i32 @export
fn lib_size() -> u64 @export
fn lib_at(index: u64, out_carrier_id: *u8) -> i32 @export
fn lib_refine(prior_carrier_id: *u8, new_carrier_id: *u8, curator_capability: *u8, out_frag_id: *u8) -> i32 @export
```

- `lib_init` → `MATHLIB_OK`; idempotent.
- `lib_admit` → `MATHLIB_OK` on success (after the witness emit succeeds); one of the negative `MATHLIB_E_*` codes otherwise. **4 params** (W2 satisfied exactly).
- `lib_cite` → `MATHLIB_OK` if present, `MATHLIB_E_ABSENT` if not, `MATHLIB_E_NOT_INITED`/`MATHLIB_E_NULL` on guard failure.
- `lib_size` → live carrier count (`u64`); total, never errors.
- `lib_at` → `MATHLIB_OK` + writes 32-byte id; `MATHLIB_E_ABSENT` for an empty/out-of-range slot.
- `lib_refine` → `MATHLIB_OK`; delegates admission to `lib_admit` and propagates its error code verbatim; **4 params** (W2 satisfied exactly).

Internal (non-exported) helper: `fn lib_find(carrier_id: *u8) -> i64` (returns slot index or `-1i64`; sentinel compared by equality only, W11).

## Constant Namespace
**PREFIX = `MATHLIB_`** (grep of `STDLIB/` → **no collision**; the gospel body's `LIB_` prefix is also collision-free today but is the *wrong assigned prefix* and is renamed wholesale). Trap 2: every module-level `const` is linker-global, so the prefix is mandatory.

```iii
const MATHLIB_OK              : i32 =  0i32
const MATHLIB_E_NULL          : i32 = -1i32
const MATHLIB_E_FULL          : i32 = -2i32
const MATHLIB_E_ABSENT        : i32 = -3i32
const MATHLIB_E_DUPLICATE     : i32 = -4i32
const MATHLIB_E_VERIFY_FAIL   : i32 = -5i32
const MATHLIB_E_DEP_ABSENT    : i32 = -6i32
const MATHLIB_E_CLAUSE_ABSENT : i32 = -7i32
const MATHLIB_E_NOT_INITED    : i32 = -8i32
const MATHLIB_E_EMIT_FAIL     : i32 = -9i32   // NEW: wh_publish returned the u64 failure sentinel
const MATHLIB_SLOTS           : u64 = 65536u64
const MATHLIB_ID_BYTES        : u64 = 32u64
const MATHLIB_MAX_DEPS        : u64 = 64u64    // dep buffer = 64 ids * 32 B = 2048 B (matches tc MAX_DEPS)
const MATHLIB_DEP_BUF_BYTES   : u64 = 2048u64
const MATHLIB_CONS_SENT       : u32 = 0xFFFFFFFFu32  // mirrors constitution.iii CONS_SENT (cons_find absence)
```

Notes: `MATHLIB_E_EMIT_FAIL`, `MATHLIB_ID_BYTES`, `MATHLIB_MAX_DEPS`, `MATHLIB_DEP_BUF_BYTES`, `MATHLIB_CONS_SENT` are additions over the gospel constant set, required by the fixes below. The `0xE3 0x0C` payload tag bytes are written as inline literals (not consts) exactly as the carrier/theorem modules do, to stay byte-identical with the witness schema family.

## Data Structures
All module-scope (Trap 7 — no local arrays). Slot table is statically sized (W8). Bound justification: `MATHLIB_SLOTS = 65536` carriers is the gospel-declared ceiling for the substrate's lifetime knowledge base; at 32 B/id this is the dominant cost (see below). This is the **maximal** gospel figure — not down-scaled.

```iii
var MATHLIB_INITED        : u8  = 0u8
var MATHLIB_CARRIER_IDS    : [u8; 2097152]   // 65536 * 32 — admitted carrier ids, indexed by slot
var MATHLIB_LIVE          : [u8; 65536]      // 1 = slot occupied
var MATHLIB_REFINES       : [u8; 2097152]    // 65536 * 32 — refinee id (zero id if not a refinement) = provenance
var MATHLIB_COUNT         : u64 = 0u64       // live carrier count

// --- serialized scratch (lib_admit/lib_refine are non-reentrant: single-ceremony, mutate global slot table) ---
var MATHLIB_S_CLAUSE_ID   : [u8; 32]         // hoisted from local: cp_library_admit clause id
var MATHLIB_S_LABEL       : [u8; 16]         // hoisted: "cp_library_admit" ASCII bytes
var MATHLIB_S_DEPS        : [u8; 2048]       // hoisted: tc_get_dependencies output (64 * 32)
var MATHLIB_S_PAYLOAD     : [u8; 80]         // hoisted: witness payload (tag + carrier id + capability id)
var MATHLIB_S_PRODUCER    : [u8; 32]         // hoisted: zero producer id
var MATHLIB_S_OPID        : [u8; 32]         // hoisted: zero op id
var MATHLIB_S_IN_C        : [u8; 32]         // hoisted: in-commit = carrier id
var MATHLIB_S_OUT_C       : [u8; 32]         // hoisted: out-commit = zero
var MATHLIB_S_ANTE        : [u8; 32]         // NEW: single-slot antecedent scratch (n_ante = 0 path)
```

Total module BSS ≈ 2,097,152 + 65,536 + 2,097,152 + small = **~4.16 MB**. Acceptable for an R0 knowledge base; matches the gospel's declared sizing. The eight `MATHLIB_S_*` scratch buffers replace the eight illegal local arrays; serialization is sound because an admission both verifies and mutates the single global slot table under one logical ceremony (M5 reversibility is preserved at the witness layer, not via reentrancy).

## Dependencies (externs)
Each `extern @abi(c-msvc-x64) fn ... from "<module>.iii"`. **NYB** = not-yet-built (the wave scheduler must order those before Module 66; Module 66 is downstream of all of them).

| Extern | From | Provider NN | Built? |
|---|---|---|---|
| `fn ident_zero(out: *u8) -> i32` | identifier.iii | 01-family | **BUILT** (verified signature match) |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | identifier.iii | 01-family | **BUILT** |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | identifier.iii | 01-family | **BUILT** |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | identifier.iii | 01-family | **BUILT** |
| `fn cons_find(clause_id: *u8) -> u32` | constitution.iii | **13** | **NYB** |
| `fn tc_verify(carrier_id: *u8) -> i32` | theorem_carrier.iii | **62** | **NYB** |
| `fn tc_get_dependencies(carrier_id: *u8, out_buf: *u8, out_cap: u32, out_count: *u32) -> i32` | theorem_carrier.iii | **62** | **NYB** |
| `fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64` | witness_hook.iii | 30/witness_hook | **BUILT** |

**Three not-yet-built deps: constitution.iii (M13), theorem_carrier.iii (M62), and the witness chain it transitively needs.** (`witness_spine.iii` M12 is NOT a dependency of this module — see Gap §G1.)

Corrections vs. the gospel extern block:
- `cons_find` return type **changed `i32` → `u32`** to match the provider (constitution.iii M13 exports `cons_find(...) -> u32`).
- The witness extern **changed from the non-existent `ws_emit_fragment` (7 params, `from "witness_spine.iii"`) to the real `wh_publish` (12 params, `from "witness_hook.iii"`)**. `wh_publish` is a multi-line declaration in the source tree; in *this* module the extern MUST be written on **one physical line** (Trap 1) — the multi-line form in `witness_hook.iii`/`constitution.iii` is a latent trap, do not copy its line-wrapping.
- Dropped the unused gospel-body assumption that `ws_emit_fragment` returns an `i32` frag-id; `wh_publish` returns a `u64` slot index (`0xFFFFFFFFFFFFFFFFu64` on failure) and writes the 32-byte frag id through `out_frag_id`.

## Algorithm
NIH (M1): pure linear-scan slot tables + byte copies; no third-party data structures, no allocation, no floating point. No ML/heuristics (M3/M4): every decision is an exact equality or a presence test. Determinism (M2) & bit-identity (W5): all state lives in fixed module-scope byte arrays scanned in fixed index order; carrier ids are 32 fixed bytes compared byte-exact via `ident_eq`; the witness payload is a fixed byte layout. No recursion (W15): all loops are bounded `while` over `MATHLIB_SLOTS` / `dcount` driven by an index counter, with a `sentinel` flag suppressing further work after the target is found (W14 — no `break`).

**`lib_init`** — if `MATHLIB_INITED == 1u8` return OK (idempotent). Else zero `MATHLIB_LIVE[0..MATHLIB_SLOTS)`, set `MATHLIB_COUNT = 0`, set `MATHLIB_INITED = 1`, return OK. (Carrier-id and refine arrays need not be pre-zeroed; `LIVE` gates every read.)

**`lib_find(carrier_id) -> i64`** (helper) — `i = 0`, `found = -1i64`, `sentinel = 0`. Loop `while i < MATHLIB_SLOTS`: when `sentinel == 0` and `MATHLIB_LIVE[i] == 1u8` and `ident_eq(&MATHLIB_CARRIER_IDS[i*32], carrier_id) == 1u8`, set `found = i as i64`, `sentinel = 1`. `i += 1`. Return `found`. Sentinel compared only by `==`/`!=` (W11).

**`lib_admit(carrier_id, curator_capability, out_frag_id)`** — the ceremony, in fixed order:
1. Guard: if `MATHLIB_INITED == 0u8` → `E_NOT_INITED`. Null-check all three pointers (`(p as u64) == 0u64`) → `E_NULL`.
2. **Clause gate (W49/M14):** build the ASCII label `"cp_library_admit"` (16 bytes: `99,112,95,108,105,98,114,97,114,121,95,97,100,109,105,116`) into `MATHLIB_S_LABEL`; `ident_from_bytes(&MATHLIB_S_LABEL[0], 16, &MATHLIB_S_CLAUSE_ID[0])`; then **`if cons_find(&MATHLIB_S_CLAUSE_ID[0]) == MATHLIB_CONS_SENT { return MATHLIB_E_CLAUSE_ABSENT }`** (presence = "not the sentinel"; see Fix §F2 — the gospel's `!= 0i32` is wrong).
3. **Verify gate:** `if tc_verify(carrier_id) != 0i32 { return MATHLIB_E_VERIFY_FAIL }`.
4. **Duplicate gate:** `if lib_find(carrier_id) != -1i64 { return MATHLIB_E_DUPLICATE }` (append-only; never re-admit).
5. **Dependency-closure gate (M14/W45):** `tc_get_dependencies(carrier_id, &MATHLIB_S_DEPS[0], 2048u32, &dcount)`; if `!= 0i32` → `E_VERIFY_FAIL`. Then `d = 0`, `ok = 1u8`; loop `while d < (dcount as u64)`: when `ok == 1u8`, if `lib_find(&MATHLIB_S_DEPS[d*32]) == -1i64` set `ok = 0u8`; `d += 1`. After the loop, `if ok == 0u8 { return MATHLIB_E_DEP_ABSENT }`. (Every cited dependency must already be present — no admission without closure.)
6. **Slot search:** `i=0`, `slot=-1i64`, `sentinel=0`; loop finds the first `MATHLIB_LIVE[i]==0u8` slot. `if slot == -1i64 { return MATHLIB_E_FULL }`. `s = slot as u64`.
7. **Commit entry:** `ident_copy(carrier_id, &MATHLIB_CARRIER_IDS[s*32])`; `ident_zero(&MATHLIB_REFINES[s*32])` (no refinee for a base admission); `MATHLIB_LIVE[s] = 1u8`; `MATHLIB_COUNT += 1`.
8. **Build witness payload** (`MATHLIB_S_PAYLOAD`, 72 used bytes): `[0]=0xE3`, `[1]=0x0C` (admit tag), bytes `[8..40)` = `carrier_id`, bytes `[40..72)` = `curator_capability` (32-byte copy loop).
9. **Emit (M6/M10):** zero `MATHLIB_S_PRODUCER`, `MATHLIB_S_OPID`, `MATHLIB_S_OUT_C`, `MATHLIB_S_ANTE`; `ident_copy(carrier_id, &MATHLIB_S_IN_C[0])`. Call `wh_publish(&MATHLIB_S_PRODUCER[0], &MATHLIB_S_OPID[0], &MATHLIB_S_IN_C[0], &MATHLIB_S_OUT_C[0], 0u8 /*revtag*/, 0u8 /*phase*/, 0u16 /*pillar*/, &MATHLIB_S_ANTE[0], 0u32 /*n_ante*/, &MATHLIB_S_PAYLOAD[0], 72u32, out_frag_id)`. Capture the `u64` result `r`; **`if r == 0xFFFFFFFFFFFFFFFFu64 { return MATHLIB_E_EMIT_FAIL }`** (compared by equality only). Return `MATHLIB_OK`. (The frag id is written through `out_frag_id` by `wh_publish`.)

   *Reversibility note (M5/M9):* the slot-table mutation in step 7 happens before the emit; if the emit fails the entry is already live but un-witnessed. To keep the chain authoritative, Phase 2 should either (a) move steps 7's `LIVE`/`COUNT` commit to *after* a successful emit, or (b) on `E_EMIT_FAIL` roll back (`MATHLIB_LIVE[s]=0u8; MATHLIB_COUNT-=1`). **Spec mandates option (a): emit first, commit the slot only on success** — this makes admission atomic w.r.t. the witness and avoids an un-witnessed live entry. (See Fix §F6.)

**`lib_cite(carrier_id)`** — guards (`E_NOT_INITED`, `E_NULL`); `if lib_find(carrier_id) == -1i64 { return MATHLIB_E_ABSENT }`; else `MATHLIB_OK`. (W49: a citation succeeds iff the entry is present.)

**`lib_size()`** — return `MATHLIB_COUNT`. Total.

**`lib_at(index, out_carrier_id)`** — guards; `if index >= MATHLIB_SLOTS { return MATHLIB_E_ABSENT }`; `if MATHLIB_LIVE[index] == 0u8 { return MATHLIB_E_ABSENT }`; `ident_copy(&MATHLIB_CARRIER_IDS[index*32], out_carrier_id)`; `MATHLIB_OK`. **Index comparison `index >= MATHLIB_SLOTS` is `u64`-vs-`u64` (both unsigned) — NOT a signed ordering compare, so Trap 3 does not apply.** The slot index multiply `index * 32u64` is `u64` throughout (no u32-in-u64 hazard, Trap 4 N/A).

**`lib_refine(prior_carrier_id, new_carrier_id, curator_capability, out_frag_id)`** — guards (4 null-checks); `if lib_find(prior_carrier_id) == -1i64 { return MATHLIB_E_ABSENT }` (the refinee must already exist — provenance integrity); `let admit_result : i32 = lib_admit(new_carrier_id, curator_capability, out_frag_id)`; `if admit_result != 0i32 { return admit_result }` (propagate verbatim). Then `let slot : i64 = lib_find(new_carrier_id)`; `if slot != -1i64 { ident_copy(prior_carrier_id, &MATHLIB_REFINES[(slot as u64)*32]) }` (record refinee = provenance; the original `prior` entry remains live, never removed). Return `MATHLIB_OK`. (Refinement = admit-new + link-to-prior; both entries coexist forever, M14.)

## KAT Vectors (>= 3)
These are the Phase-2 acceptance gate, checked byte-for-byte. They require a built `theorem_carrier` (M62) + `constitution` (M13) with the `cp_library_admit` clause ratified; the KAT harness ratifies that clause and allocates carriers via `tc_alloc` as fixtures.

1. **Init idempotence + empty state.** `lib_init()` == `0i32`; second `lib_init()` == `0i32`; `lib_size()` == `0u64`; `lib_cite(any_id)` == `-3i32` (`E_ABSENT`); `lib_at(0u64, buf)` == `-3i32`.
2. **Not-inited guard (prove the negative).** *Before* any `lib_init`: `lib_admit(c, cap, f)` == `-8i32` (`E_NOT_INITED`); `lib_cite(c)` == `-8i32`; `lib_at(0,b)` == `-8i32`. (Proves the init gate FAILS closed, per "prove the negative case.")
3. **Admit-then-cite-then-retrieve (happy path).** With `cp_library_admit` ratified and a dependency-free verified carrier `C0` (from `tc_alloc` with `dependency_count=0`): `lib_admit(C0, CAP, F0)` == `0i32`; `lib_size()` == `1u64`; `lib_cite(C0)` == `0i32`; `lib_at(0u64, B)` == `0i32` **and** `ident_eq(B, C0) == 1u8`; the frag id `F0` is non-zero (`ident_is_zero(F0) == 0u8`).
4. **Duplicate refusal.** Immediately after KAT 3: `lib_admit(C0, CAP, F1)` == `-4i32` (`E_DUPLICATE`); `lib_size()` still `1u64`.
5. **Dependency-closure gate (prove the negative).** Carrier `C1` whose `tc` dependency set = `{C0, C_MISSING}` where `C_MISSING` was never admitted to the library: `lib_admit(C1, CAP, F2)` == `-6i32` (`E_DEP_ABSENT`); `lib_size()` unchanged. Then admit the missing dep first, re-admit `C1` → `0i32` (closure now satisfied). (Proves W45 closure gate FAILS on an open dependency and PASSES once closed.)
6. **Clause-absent gate (prove the negative).** With a fresh `constitution` where `cp_library_admit` is **not** ratified: `lib_admit(C0, CAP, F3)` == `-7i32` (`E_CLAUSE_ABSENT`). (Proves the W49 clause gate FAILS closed — and specifically that the corrected `== CONS_SENT` sentinel logic rejects only true absence, not slot-0 clauses.)
7. **Refinement provenance.** Admit `C0`; allocate verified `C0R` (refines `C0`, with `C0` in its dep set so closure holds); `lib_refine(C0, C0R, CAP, F4)` == `0i32`; `lib_size()` == `2u64`; `lib_cite(C0)` == `0i32` (original retained) **and** `lib_cite(C0R)` == `0i32`; the stored `MATHLIB_REFINES` slot for `C0R` equals `C0` (read back: `ident_eq(&MATHLIB_REFINES[slot*32], C0) == 1u8`). `lib_refine(C_ABSENT, C0R2, CAP, F5)` == `-3i32` (`E_ABSENT`, refinee missing).

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED via the `wh_publish` extern, which is line-wrapped in `witness_hook.iii`/`constitution.iii`. **Avoidance:** write the `wh_publish` extern and EVERY `fn` signature on a single physical line in this module. Do not copy the wrapped form.
- **Trap 2 (const linker-global)** — EXPOSED (13 module-level consts). **Avoidance:** all consts carry the `MATHLIB_` prefix; grep confirms no `STDLIB/` collision. (The gospel's `LIB_` prefix is replaced.)
- **Trap 3 (signed-ordering SIGSEGV)** — NOT EXPOSED. The only ordering compares are `index >= MATHLIB_SLOTS`, `i < MATHLIB_SLOTS`, `d < (dcount as u64)` — all **`u64` unsigned**. Every signed (`i64`) value (`found`, `slot`, `admit_result : i32`) is compared by **`==`/`!=` against `-1i64`/`0i32` only** (W11). Confirm Phase 2 never introduces an `i64 </<=/>/>=`.
- **Trap 4 (u32-in-u64-slot)** — EXPOSED at one point: `dcount : u32` from `tc_get_dependencies` is used as `(dcount as u64)` to drive the dependency loop and `d * 32u64` pointer math. **Avoidance:** `dcount` is a loop bound only (not itself a pointer base); `d` is a native `u64` counter, so `d * 32u64` is clean. If Phase 2 ever computes a pointer offset directly from `dcount`, mask `(dcount as u64) & 0xFFFFFFFFu64` first. `out_count` width is fixed by the provider.
- **Trap 5 (u32 ptr-store width)** — NOT EXPOSED. No `*u32` stores; all writes are byte-wise `[u8]` array stores or `ident_copy`.
- **Trap 6 (nested `/* */`)** — avoid; this spec's skeleton uses only `//` line comments inside the body and one outer block header.
- **Trap 7 (local `var`/`let` arrays)** — **EXPOSED — this is the gospel body's worst structural defect:** `lib_admit` declares 8 local arrays (`label`, `clause_id`, `deps`, `payload`, `producer`, `op`, `in_c`, `out_c`). iiis-0 parses array declarations only at module scope. **Avoidance:** all 8 hoisted to the `MATHLIB_S_*` module-scope buffers (see Data Structures). Serialization is safe (single-ceremony, non-reentrant admission).
- **Trap 8 (`} else {` one line)** — N/A in the spec'd algorithm (no `else` blocks needed; all gates are guard-return). If Phase 2 adds one, keep it on a single line.
- **Trap 9 (em-dash in comment)** — avoid; use ASCII `--` in all comments.
- **Trap 10 (`let mut x = 0u32` checkpoint flag)** — borderline: the `ok : u8` / `sentinel : u8` flags are `u8` flags driving loop suppression, not the misbehaving `let mut x = 0u32` counter pattern; they mirror the proven idiom in `theorem_carrier`/`merkle`. Acceptable. Prefer the early-return guard style everywhere else.
- **Trap 11 (`a % b` after call)** — NOT EXPOSED. No modulo anywhere; all indexing is `*32u64` multiply.
- **Trap 12 (`@specialize *T` stride)** — NOT EXPOSED. No generics; element width is the fixed 32-byte identifier.

## Gap / Fix List
**G1 — Non-existent witness extern (BLOCKER, M6/M10).** The body externs `ws_emit_fragment(producer, op, in_commit, out_commit, payload, payload_len, out_fid) -> i32 from "witness_spine.iii"`. **No such function exists** — `witness_spine.iii` (M12) exports `ws_register / ws_lookup_id / ws_epoch_close / ws_chain_root / ...`, none of which emit a fragment. The real emit primitive is **`wh_publish(...12 params...) -> u64 from "witness_hook.iii"`** (verified in the built tree, line 144). **Fix:** replace the extern and both call sites (`lib_admit`, transitively `lib_refine`) with `wh_publish`; map the 4 commit ids onto its first four params, pass `revtag=0, phase=0, pillar=0, antecedents=&MATHLIB_S_ANTE, n_ante=0, payload=&MATHLIB_S_PAYLOAD, payload_len=72`; treat the `u64` return: `0xFFFFFFFFFFFFFFFFu64` → `MATHLIB_E_EMIT_FAIL`, else `MATHLIB_OK` (frag id written through `out_frag_id`).

**G2 — `cons_find` type + sentinel inversion (BLOCKER, M14/W49).** The body declares `cons_find(...) -> i32` and tests `if cons_find(...) != 0i32 { return LIB_E_CLAUSE_ABSENT }`. The provider (constitution.iii M13) exports `cons_find(...) -> u32` returning a **slot index** with absence sentinel `CONS_SENT = 0xFFFFFFFFu32`. The body is wrong twice: (a) return-type mismatch (`i32` vs `u32`); (b) inverted semantics — `!= 0` rejects every clause not at slot 0 and treats slot-0 presence as "absent." **Fix:** extern `-> u32`; add `const MATHLIB_CONS_SENT : u32 = 0xFFFFFFFFu32`; gate `if cons_find(&MATHLIB_S_CLAUSE_ID[0]) == MATHLIB_CONS_SENT { return MATHLIB_E_CLAUSE_ABSENT }`.

**G3 — Eight local arrays (BLOCKER, Trap 7).** `lib_admit` declares `label/clause_id/deps/payload/producer/op/in_c/out_c` as locals — unparseable. **Fix:** hoist all to the `MATHLIB_S_*` module-scope buffers; the body references them by `&MATHLIB_S_X[0u64]`. Document non-reentrancy.

**G4 — Wrong const PREFIX (Trap 2 / briefing §4).** The body uses `LIB_`; the assigned prefix is `MATHLIB_`. **Fix:** rename all 9 gospel consts to `MATHLIB_*` and add the 5 new consts. (`LIB_` is collision-free today, but the assignment is binding and prevents a future `LIB_` clash.)

**G5 — TODO-grade / under-specified witness payload (M10).** The body sets only `payload[0]=0xE3, payload[1]=0x0C` then copies carrier id + capability, emitting `payload_len = 72` against an `[u8;80]` buffer (bytes 2..8 and 72..80 are uninitialized scratch but excluded from the hashed length — acceptable, but unstated). **Fix:** explicitly zero bytes `[2..8)` of `MATHLIB_S_PAYLOAD` (or document them as reserved-and-unhashed) so the witness is byte-reproducible (M10); fix `payload_len = 72u32`. KAT 3 asserts the emitted frag id is reproducible.

**G6 — Non-atomic admit vs. emit (M5/M9 reversibility).** The body commits `LIVE[s]=1 / COUNT+=1` *before* emitting the witness; an emit failure leaves a live, un-witnessed entry that no chain replay can authenticate. **Fix (spec-mandated):** reorder — build payload + `wh_publish` first; only on success set `LIVE[s]=1`, `MATHLIB_COUNT+=1`, copy the carrier id and zero the refine slot. On `E_EMIT_FAIL`, leave the slot untouched. This makes admission atomic with the witness chain.

**G7 — Mandate-conformance confirmations (no change needed, recorded):** M1 (NIH, pure byte tables) ✔; M2/W5 (fixed-order scans, byte-exact ids) ✔; M3/M4 (exact equality decisions, no counting/learning) ✔; M7 (Ring R0 honored) ✔; M8 (`curator_capability` is the explicit capability arg gating admission) ✔ — note the capability is *recorded into the witness* but the body does not *verify* it; the constitutional `cp_library_admit` clause gate (G2) is the authorization mechanism per the gospel design, so this is conformant, but Phase 2 should confirm M13's clause predicate is what enforces curator authority; M11/M18 (carriers are proof-carrying via `tc_verify`) ✔; M14/W45/W49 (closure gate G5-§5, clause+presence gates) ✔ once G1/G2 fixed; M19 (cost bounded: every op is O(MATHLIB_SLOTS) linear scan, no unbounded loop) ✔.

**G8 — W2 / W13 audit:** `lib_admit` and `lib_refine` are exactly 4 params (W2 boundary — OK). Local-name count: with arrays hoisted, `lib_admit` keeps ~10 named locals (`d, ok, i, slot, sentinel, s, k`, plus the `dcount` and `r` results) — within W13's 20. Confirm Phase 2 does not exceed 20.

**Systemic dependency defect (flagged for the wave, not fixable here):** the gospel bodies of **theorem_carrier.iii (M62)** and **constitution.iii (M13)** both `extern keccak256_init/update/final from "keccak.iii"` — WRONG. Those symbols live in **`keccak256.iii`** (verified: `keccak.iii` provides the raw permutation; `keccak256.iii` provides `keccak256_oneshot/init/update/final`). M62's `tc_alloc` additionally has a self-described "Placeholder" line that calls `ident_from_bytes` into the carrier-id slot before finalizing keccak (a stub). Module 66 does not import keccak and is unaffected directly, but it *depends* on M62/M13 being correct; their Phase-2 implementers must fix the import path (`from "keccak256.iii"`) and M62's placeholder. Module 66's `tc_verify`/`tc_get_dependencies`/`cons_find` externs are otherwise signature-correct against the M62/M13 headers.

## Implementation Skeleton
Paste-ready structure. SINGLE-LINE signatures. No fn bodies (Phase 2 writes those per Algorithm §). ASCII-only comments.

```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\math_library.iii
 *
 * III STDLIB - numera::math_library
 *
 * The curated mathematical library: the append-only index of admitted
 * theorem carriers. Admits via the cp_library_admit ceremony, retains
 * every carrier indefinitely, serves citation queries, records
 * refinement provenance. The substrate's accumulated formal knowledge.
 *
 * Public API:
 *   lib_init() -> i32                         Initialize; idempotent.
 *   lib_admit(carrier_id, curator_capability, out_frag_id) -> i32
 *   lib_cite(carrier_id) -> i32               W49: present iff cited OK.
 *   lib_size() -> u64                         live carrier count.
 *   lib_at(index, out_carrier_id) -> i32      retrieve by admission slot.
 *   lib_refine(prior, new, curator_capability, out_frag_id) -> i32
 *
 * Hexad: kind_essence + kind_cognition.  Ring: R0.  K: 1.00.
 *
 * NIH: depends on identifier.iii, theorem_carrier.iii (M62),
 *      constitution.iii (M13), witness_hook.iii.
 *
 * Discipline: M14/W45 dependency closure on every admission; W49
 * citation only of present entries; W2 (<=4 params); W8 static
 * tables; W11 sentinel equality; W14 sentinel loops; W15 no recursion.
 * Non-reentrant: lib_admit/lib_refine use module-scope MATHLIB_S_*
 * scratch (single-ceremony admission, serialized).
 */

module numera_math_library

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> u32 from "constitution.iii"
extern @abi(c-msvc-x64) fn tc_verify(carrier_id: *u8) -> i32 from "theorem_carrier.iii"
extern @abi(c-msvc-x64) fn tc_get_dependencies(carrier_id: *u8, out_buf: *u8, out_cap: u32, out_count: *u32) -> i32 from "theorem_carrier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

const MATHLIB_OK              : i32 =  0i32
const MATHLIB_E_NULL          : i32 = -1i32
const MATHLIB_E_FULL          : i32 = -2i32
const MATHLIB_E_ABSENT        : i32 = -3i32
const MATHLIB_E_DUPLICATE     : i32 = -4i32
const MATHLIB_E_VERIFY_FAIL   : i32 = -5i32
const MATHLIB_E_DEP_ABSENT    : i32 = -6i32
const MATHLIB_E_CLAUSE_ABSENT : i32 = -7i32
const MATHLIB_E_NOT_INITED    : i32 = -8i32
const MATHLIB_E_EMIT_FAIL     : i32 = -9i32
const MATHLIB_SLOTS           : u64 = 65536u64
const MATHLIB_ID_BYTES        : u64 = 32u64
const MATHLIB_MAX_DEPS        : u64 = 64u64
const MATHLIB_DEP_BUF_BYTES   : u64 = 2048u64
const MATHLIB_CONS_SENT       : u32 = 0xFFFFFFFFu32

var MATHLIB_INITED        : u8  = 0u8
var MATHLIB_CARRIER_IDS    : [u8; 2097152]   // 65536 * 32
var MATHLIB_LIVE          : [u8; 65536]
var MATHLIB_REFINES       : [u8; 2097152]    // 65536 * 32 -- refinee id; zero id if base admission
var MATHLIB_COUNT         : u64 = 0u64

var MATHLIB_S_CLAUSE_ID   : [u8; 32]
var MATHLIB_S_LABEL       : [u8; 16]
var MATHLIB_S_DEPS        : [u8; 2048]
var MATHLIB_S_PAYLOAD     : [u8; 80]
var MATHLIB_S_PRODUCER    : [u8; 32]
var MATHLIB_S_OPID        : [u8; 32]
var MATHLIB_S_IN_C        : [u8; 32]
var MATHLIB_S_OUT_C       : [u8; 32]
var MATHLIB_S_ANTE        : [u8; 32]

fn lib_init() -> i32 @export { /* TODO: body per Algorithm lib_init */ }

fn lib_find(carrier_id: *u8) -> i64 { /* TODO: body per Algorithm lib_find (internal helper) */ }

fn lib_admit(carrier_id: *u8, curator_capability: *u8, out_frag_id: *u8) -> i32 @export { /* TODO: body per Algorithm lib_admit (steps 1-9; emit via wh_publish; emit-then-commit per G6) */ }

fn lib_cite(carrier_id: *u8) -> i32 @export { /* TODO: body per Algorithm lib_cite */ }

fn lib_size() -> u64 @export { /* TODO: return MATHLIB_COUNT */ }

fn lib_at(index: u64, out_carrier_id: *u8) -> i32 @export { /* TODO: body per Algorithm lib_at */ }

fn lib_refine(prior_carrier_id: *u8, new_carrier_id: *u8, curator_capability: *u8, out_frag_id: *u8) -> i32 @export { /* TODO: body per Algorithm lib_refine (delegate to lib_admit; record MATHLIB_REFINES) */ }
```
