# 09 numera/category.iii — Implementation Spec

## Verdict
**PARTIAL** — The gospel candidate body is algorithmically complete and correct in *intent* (all 14 public fns present, sound finite-category math), but it is **not buildable as written**: it (1) collides every constant with `sanctus/catalyst.iii` (Trap 2), (2) declares scratch buffers as **local `var` arrays inside functions** (Trap 7 — parse only at module scope), (3) hashes via streaming `keccak256_init/update/final` over live parameter pointers across calls (param-spill / Trap 11+4 — the exact defect `identifier.iii` and `content_addr.iii` already reconciled away), (4) externs the streaming API from the wrong file (`keccak.iii` instead of `keccak256.iii`), and (5) uses the unproven indexed address-of idiom `(&ARR[off])` that appears nowhere in the built tree. Each is closed in the Gap/Fix List; the corrected design is in the Skeleton.

## Purpose
`numera/category.iii` is the substrate's **finite-category engine**: it *is* the ontological space in which objects (32-byte identifiers), morphisms (arrows hashed from `Keccak256(src‖dst‖op)`), composition, identities, pullbacks, pushouts, coequalizers, and the associativity law live as concrete slot-table state. It exists so the hardware/device ontology can declare two devices *observationally equivalent* algebraically (via a coequalizer of two parallel morphisms — exact morphism-id equality, never statistics). Hexad: **kind_essence**. Ring: **R0**. K-vector: **0.99** (slot exhaustion is the only failure mode; every op is total + reversible-by-refusal).

## Public API
All signatures single-line (Trap 1). Slot-returning fns use the `u32` sentinel `CATEGORY_SENT = 0xFFFFFFFFu32` (W12 sentinel-typed value); `i32`-returning fns use negative error codes (W9) compared by equality only (W11). The lone `u8` return (`cat_morph_eq`) follows W10; a `_u64` wrapper is added for reliable cross-extern reads (W16, per the `bigint_eq_u64` precedent).

```
fn cat_init() -> i32 @export
fn cat_add_object(obj_id: *u8) -> u32 @export
fn cat_find_object(obj_id: *u8) -> u32 @export
fn cat_object_id(slot: u32, out_id: *u8) -> i32 @export
fn cat_add_morphism(src: u32, dst: u32, op: *u8, out_id: *u8) -> u32 @export
fn cat_find_morphism(mor_id: *u8) -> u32 @export
fn cat_morphism_src(slot: u32) -> u32 @export
fn cat_morphism_dst(slot: u32) -> u32 @export
fn cat_morphism_id(slot: u32, out_id: *u8) -> i32 @export
fn cat_identity(obj_slot: u32, out_id: *u8) -> u32 @export
fn cat_compose(f_slot: u32, g_slot: u32, out_id: *u8) -> u32 @export
fn cat_morph_eq(f_slot: u32, g_slot: u32) -> u8 @export
fn cat_morph_eq_u64(f_slot: u32, g_slot: u32) -> u64 @export
fn cat_check_assoc(f_slot: u32, g_slot: u32, h_slot: u32) -> u8 @export
fn cat_pullback(out: *u32) -> i32 @export
fn cat_pushout(out: *u32) -> i32 @export
fn cat_coequalizer(out: *u32) -> i32 @export
```

W2 note: `cat_pullback`, `cat_pushout`, `cat_coequalizer` in the gospel took **5 / 5 / 4** pointer params (`f_slot,g_slot,out_p,out_p1,out_p2`). 5 params **violates W2 (≤4)**. The maximal fix is an **aggregate-by-pointer**: caller fills a module-mediated request and reads a result struct laid over a `*u32` view. Concretely, the three universal-construction fns take a single `out: *u32` pointing at a caller-provided `[u32; 5]` whose layout is **input on entry, output on exit**:
- pullback/pushout: `out[0]=f_slot, out[1]=g_slot` on entry → `out[0]=vertex, out[1]=leg1_slot, out[2]=leg2_slot` on exit.
- coequalizer: `out[0]=f_slot, out[1]=g_slot` on entry → `out[0]=q_vertex, out[1]=c_slot` on exit.
This collapses 5 params to 1 (W2-clean) and keeps every output. Return is `i32` (CATEGORY_OK / CATEGORY_E_*).

## Constant Namespace
**PREFIX = `CATEGORY_`**  (the dispatch-assigned prefix; the gospel body's `CAT_` **collides** — see Gap §G1 — and is fully replaced).

| const | type | value |
|---|---|---|
| `CATEGORY_OK` | i32 | `0i32` |
| `CATEGORY_E_FULL` | i32 | `-1i32` |
| `CATEGORY_E_BAD_SLOT` | i32 | `-2i32` |
| `CATEGORY_E_MISMATCH` | i32 | `-3i32` |
| `CATEGORY_E_NOT_FOUND` | i32 | `-4i32` |
| `CATEGORY_E_NULL` | i32 | `-5i32` |
| `CATEGORY_MAX_OBJ` | u32 | `1024u32` |
| `CATEGORY_MAX_MOR` | u32 | `16384u32` |
| `CATEGORY_SENT` | u32 | `0xFFFFFFFFu32` |
| `CATEGORY_IDBYTES` | u64 | `32u64` |

**Collision grep results (process step §4):**
- `grep "^const CATEGORY_" STDLIB/` → **no matches** (clean; safe to use).
- `grep "^const CAT_" STDLIB/` → **collides**: `STDLIB/iii/sanctus/catalyst.iii` already declares module-global `CAT_OK`, `CAT_E_FULL`, `CAT_SLOTS`, `CAT_GATE_*`, etc. Since module-level `const` emits a linker-global `L_CAT_OK` (Trap 2), the gospel's `CAT_` prefix would produce duplicate-symbol link failures. **Resolution: every `CAT_*` constant is renamed to `CATEGORY_*`.** (Note `CATEGORY_E_NULL`/`CATEGORY_IDBYTES` are additions the gospel lacked but the corrected null-checks / hashing need.)

## Data Structures
All module-scope (W8 statically sized, justified; **no local `var` arrays** — Trap 7). Bounds are the gospel's constitutional caps (`CATEGORY_MAX_OBJ=1024`, `CATEGORY_MAX_MOR=16384`): finite category required by the exhaustive-search universal constructions; 1024 objects × 32 B = 32 KiB, 16384 morphisms × (32+32) B = 1 MiB — bounded BSS, no growth.

| name | type | size | justification |
|---|---|---|---|
| `CATEGORY_OBJ_LIVE` | `[u8; 1024]` | `MAX_OBJ` | object liveness bitmap |
| `CATEGORY_OBJ_ID` | `[u8; 32768]` | `MAX_OBJ*32` | object 32-byte identifiers, packed |
| `CATEGORY_MOR_LIVE` | `[u8; 16384]` | `MAX_MOR` | morphism liveness bitmap |
| `CATEGORY_MOR_SRC` | `[u32; 16384]` | `MAX_MOR` | source object slot per morphism |
| `CATEGORY_MOR_DST` | `[u32; 16384]` | `MAX_MOR` | target object slot per morphism |
| `CATEGORY_MOR_OP` | `[u8; 524288]` | `MAX_MOR*32` | operation identifier per morphism, packed |
| `CATEGORY_MOR_ID` | `[u8; 524288]` | `MAX_MOR*32` | morphism identifier per morphism, packed |
| `CATEGORY_HBUF` | `[u8; 96]` | 3×32 | hash concat scratch (replaces all local `var ...buf:[u8;32]`); holds `src‖dst‖op` (96 B) and `f_id‖g_id` (64 B) and `obj‖"id"` (34 B). **Serialized / not reentrant** — acceptable, all hashing is straight-line (matches `IDENT_PAIRBUF`, `CA_BUF`, `KK256_*`). |
| `CATEGORY_MIDBUF` | `[u8; 32]` | 32 | computed-morphism-id scratch (replaces local `mid_buf` in `cat_add_morphism`) |
| `CATEGORY_TIDBUF` | `[u8; 32]` | 32 | composite-id throwaway for universal-construction probes (replaces local `tid`) |
| `CATEGORY_KAT_*` | `[u8; 32]` ×~6 | 32 each | self-test object/morphism id scratch (KAT only) |

Reentrancy note (W6/W7): every hashing op writes `CATEGORY_HBUF`/`CATEGORY_MIDBUF` then immediately hashes, with no suspension point — the serialized-scratch pattern is safe exactly as it is in the three sibling crypto/identifier modules.

## Dependencies (externs)
All providers are **already built** (verified present in `STDLIB/iii/numera/`). **No not-yet-built dependency** → this module is wave-schedulable immediately.

```
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
```

- `identifier.iii` — **Layer 0, Module 01** (built). Provides `ident_copy`/`ident_eq`/`ident_cmp`; signatures verified byte-exact against the gospel externs.
- `keccak256.iii` — **Stage-4 closure module** (built). Provides `keccak256_oneshot`.

**Changes from the gospel externs (see Gap §G3/§G4):**
1. The gospel externs `ident_from_bytes` — **dropped** (unused after the hashing rewrite; `keccak256_oneshot` covers all hashing).
2. The gospel externs `keccak256_init/update/final from "keccak.iii"` — **both the file and the streaming pattern are wrong**: that streaming API lives in `keccak256.iii` (not `keccak.iii`), and using it over live params triggers the param-spill clobber. **Replaced** with a single `keccak256_oneshot from "keccak256.iii"`, the reconciled house pattern.

## Algorithm

Determinism (M2) / bit-identity (W5): every identifier is a pure `Keccak256` of a canonical byte concatenation built in a fixed-order loop over module scratch; no addresses, clocks, or order-dependence enter the hash. Tie-breaking (M2 via `numera/tiebreak` spirit) is **lexicographic-smallest object identifier** via `ident_cmp == -1i32`. NIH (M1): the only algorithms are slot scans, byte concatenation, and the substrate's own Keccak256 — no third-party anything. No ML/heuristics (M3/M4): "observational equivalence" = exact morphism-id equality on a coequalizer, an algebraic universal property, not a learned/statistical judgement. No recursion (W15): every search is an explicit nested `while` over the static slot tables.

- **`cat_init`** — zero `CATEGORY_OBJ_LIVE[0..MAX_OBJ)` then `CATEGORY_MOR_LIVE[0..MAX_MOR)` via two sentinel `while` loops (W14). Return `CATEGORY_OK`. (Reversible: re-init restores ground state — M5/M9.)
- **`cat_find_object`** — single `while i<MAX_OBJ`; first live slot whose `ident_eq(obj_ptr(i),obj_id)==1` sets `found`, guarded so it sets once (no `break`, W14). Return `found` or `CATEGORY_SENT`.
- **`cat_add_object`** — idempotent: if `cat_find_object != SENT` return it; else first free slot, `ident_copy` id in, mark live, return slot; else `CATEGORY_SENT` (W12). Null-check `obj_id` → `SENT`.
- **`cat_object_id`** — bounds + live check → `CATEGORY_E_BAD_SLOT`; else `ident_copy` out. Null-check `out_id`.
- **`cat_compute_mor_id`** (private helper) — concat into `CATEGORY_HBUF`: bytes `[0..32)=src_obj_id`, `[32..64)=dst_obj_id`, `[64..96)=op` via one fixed loop; `keccak256_oneshot(&CATEGORY_HBUF, 96, out)`. **(Replaces the gospel's 3-call streaming — Gap §G3.)** Validates `src`/`dst` slots first.
- **`cat_add_morphism`** — validate `src`/`dst` (range+live) → `SENT`; compute id into module `CATEGORY_MIDBUF`; if `cat_find_morphism(mid)!=SENT`, copy mid→out, return existing (dedup → the gospel's "exactly one composition" invariant); else first free morphism slot: set `SRC/DST`, `ident_copy` op and mid into packed tables, mark live, copy mid→out, return slot; else `SENT`.
- **`cat_find_morphism`** — mirror of `cat_find_object` over `MOR` tables.
- **`cat_morphism_src/dst`** — range+live → `SENT`; else return `CATEGORY_MOR_SRC/DST[slot]`.
- **`cat_morphism_id`** — range+live → `E_BAD_SLOT`; else `ident_copy` packed id → out.
- **`cat_identity`** — id_op `= Keccak256(obj_id ‖ "id")`: write `obj_id` into `CATEGORY_HBUF[0..32)`, ASCII `0x69,0x64` ("id") into `[32..34)`, `keccak256_oneshot(&HBUF,34,op_scratch)`; then `cat_add_morphism(obj_slot,obj_slot,op,out_id)`. The 2-byte literal is materialised as two explicit byte stores (avoids the `"id" as *u8` string-literal-pointer idiom; Gap §G6).
- **`cat_compose`** (g∘f) — validate both morphism slots; require `MOR_DST[f]==MOR_SRC[g]` else `SENT` (endpoint match); composite op `= Keccak256(f_id ‖ g_id)` via `CATEGORY_HBUF[0..64)` + `keccak256_oneshot(...,64,...)`; result endpoints `(MOR_SRC[f], MOR_DST[g])`; return `cat_add_morphism(...)`. Composite-uniqueness: identical `(f,g)` always hash to the same op → `cat_add_morphism` dedups → exactly one composite (the gospel's "smaller-identifier tie-break" is automatically satisfied because the id is a deterministic function of the inputs, so there are never two candidates; this is recorded as a simplification in Gap §G7).
- **`cat_morph_eq`** — both range+live, else `0u8`; return `ident_eq(mor_id(f),mor_id(g))`. `cat_morph_eq_u64` wraps it returning `1u64/0u64` for reliable extern reads (W16).
- **`cat_check_assoc`** — compute `gf=compose(f,g)`, `h_gf=compose(gf,h)`, `hg=compose(g,h)`, `hg_f=compose(f,hg)`, each `SENT`-guarded → `0u8`; return `cat_morph_eq(h_gf,hg_f)`. (Proves `(h∘g)∘f = h∘(g∘f)` for the concrete arrows — Curry-Howard operational check, M11.)
- **`cat_pullback`** (aggregate `out:[u32;5]`, in `out[0]=f,out[1]=g`) — read `f,g`; validate; require `MOR_DST[f]==MOR_DST[g]` (shared target C) else `E_MISMATCH`; `A=MOR_SRC[f]`, `B=MOR_SRC[g]`. Explicit triple-nested `while` over `(cand∈OBJ) × (m1∈MOR: src=cand,dst=A) × (m2∈MOR: src=cand,dst=B)`: for each, `left=compose(m1,f)`, `right=compose(m2,g)` into `CATEGORY_TIDBUF`; if both valid and `cat_morph_eq(left,right)==1`, update `(best,best_p1,best_p2)` when `best==SENT` **or** `ident_cmp(obj(cand),obj(best))==-1i32` (lex-min tie-break, deterministic). On exit write `out[0]=best,out[1]=best_p1,out[2]=best_p2`; `E_NOT_FOUND` if none. The inner `(m1,m2)` body is factored into a helper to satisfy W13 (≤20 locals) — Gap §G5.
- **`cat_pushout`** (aggregate) — dual: shared **source** A (`MOR_SRC[f]==MOR_SRC[g]`), `B=MOR_DST[f]`,`C=MOR_DST[g]`; search `cand` with `m1:B→cand`, `m2:C→cand`, `left=compose(f,m1)`,`right=compose(g,m2)`; same lex-min tie-break; outputs `(q,q1,q2)`.
- **`cat_coequalizer`** (aggregate `out:[u32;5]`, in `out[0]=f,out[1]=g`) — require shared source **and** shared target (`MOR_SRC` and `MOR_DST` equal) else `E_MISMATCH`; `B=MOR_DST[f]`; search `cand` and single `m:B→cand` with `compose(f,m)==compose(g,m)`; lex-min tie-break; outputs `out[0]=q_vertex,out[1]=c_slot`. This is the device-equivalence primitive.

W13 accounting: `cat_pullback`/`cat_pushout` as written in the gospel exceed the 20-named-local budget once the nested temporaries are counted and nest 6 `if`s deep; the spec factors each innermost `(cand,m1,m2)`-test into a `category_pb_probe(cand,m1,m2,is_pushout)`-style helper returning a packed verdict, keeping each fn ≤20 locals and ≤3 nesting levels.

## KAT Vectors (>= 3)
Self-test `cat_kat() -> u64` returning `99u64` on pass; checks are byte-for-byte. Object ids are fixed test vectors derived via `keccak256_oneshot` of small literals so they are reproducible.

1. **Identity + composition closure.** `cat_init()`; add objects A,B,C (ids = Keccak256("A"/"B"/"C")). Add `f:A→B`, `g:B→C`. `gf = cat_compose(f,g)` must be `!= SENT`, with `cat_morphism_src(gf)==slotA` and `cat_morphism_dst(gf)==slotC`. Recompute `gf2 = cat_compose(f,g)` → must equal `gf` (dedup / composite-uniqueness). Expect: both slots equal, endpoints A→C.
2. **Associativity law.** Add `h:C→D`. `cat_check_assoc(f,g,h)` must return `1u8` (i.e. `(h∘g)∘f` and `h∘(g∘f)` share an identifier). Negative arm: `cat_check_assoc` with a non-composable triple (e.g. `h` replaced by an arrow `E→D`) must return `0u8` — proves the endpoint guard fails, not just passes.
3. **Coequalizer of parallel arrows.** Add parallel `p,q:A→B` and a `c:B→Q` with `c∘p = c∘q` (construct `c` so the composite ids collide by giving `p`,`q` the same op so they are the same morphism, *then* a distinct parallel pair to prove non-collapse). `cat_coequalizer(out)` with `out[0]=p,out[1]=q` must return `CATEGORY_OK` and set `out[1]` (c_slot) to the constructed `c`; for a pair with **no** equalizing `c` it must return `CATEGORY_E_NOT_FOUND` (prove the negative).
4. **Morphism-id determinism (bit-identity, W5/M2).** `cat_add_morphism(A,B,op)` twice with identical `op` returns the same slot and writes the same 32-byte `out_id`; the first 32-byte id is asserted against the precomputed `Keccak256(idA ‖ idB ‖ op)` reference bytes (one fixed vector hard-coded in the KAT). Endpoint-mismatch `cat_compose` of `f:A→B` with `g:C→D` (B≠C) must return `SENT` (negative arm).

## Trap Exposure
| # | Trap | Exposed? | Avoidance |
|---|---|---|---|
| 1 | Multi-line `fn` decl | yes (every fn) | **All signatures single-line** in the skeleton; the gospel's `cat_pullback(... \n ...)` wraps are unwrapped. |
| 2 | Module-`const` linker-global collision | **yes — confirmed collision** | Re-prefix all consts `CAT_*`→`CATEGORY_*`; grep proves `CATEGORY_` is collision-free and `CAT_` collides with `catalyst.iii`. |
| 3 | Signed ordering compare SIGSEGV | no | No `<`/`>` on i32/i64. All error compares are `==`/`!=`; `ident_cmp` results compared `== -1i32`. `u32` loop bounds (`i<MAX`) are unsigned (safe). |
| 4 | u32-in-u64-slot garbage in ptr math | yes (`obj_ptr`/`mor_ptr` offset = `slot*32`) | Mask `(slot as u64) & 0xFFFFFFFFu64` before `*32` in every `*_ptr` helper before pointer arithmetic. |
| 5 | u32 pointer store width clobber | yes (`*out = best` u32 stores) | Aggregate `out:[u32;5]` is written **element-by-element**; if any store proves to clobber the adjacent slot, fall back to byte-wise `*u8` stores (the bigint store-width remedy). KAT reads all 5 slots to catch a clobber. |
| 6 | Nested `/* */` comments | no | Single-level block header only; inline notes use `//` or `(...)`. |
| 7 | Local `var` array unsupported | **yes — every universal-construction fn** | **All** `var mid_buf/op_buf/comp_op_buf/id_buf/tid : [u8;32]` moved to module scope (`CATEGORY_HBUF/MIDBUF/TIDBUF`). |
| 8 | `} else {` split across lines | low | Few `else`s; all written `} else {` on one line. |
| 9 | Em-dash in `/* */` | yes (prose-rich header) | Header uses ASCII `--` only; no U+2014. |
| 10 | `let mut x=0u32` checkpoint flag | yes (`found`/`best` sentinels) | `found`/`best` are accumulators, not checkpoint flags, and are guarded so they assign at most once per branch; no boolean-checkpoint misuse. |
| 11 | `a % b` after a call returns quotient | no | No modulo anywhere; offsets are `slot*32` multiplies, not `%`. |
| 12 | `@specialize *T` stride = 8 | no | Module is not generic; all element widths are concrete (`u8`/`u32`). |
| (idiom) | `(&ARR[off]) as *u8` unproven | yes (gospel uses it) | Replace with the proven house idiom `((&ARR as u64) + off) as *u8` (used in fe25519/fn384/fp256). |

## Gap / Fix List
- **G1 — Const collision (Trap 2).** Gospel `CAT_OK/CAT_E_FULL/CAT_SLOTS/...` collide with `STDLIB/iii/sanctus/catalyst.iii` module-globals. **Fix:** rename every constant `CAT_*` → `CATEGORY_*` (table above). Also rename the gospel's stray `CAT_SLOTS`-equivalent usages and add `CATEGORY_E_NULL`, `CATEGORY_IDBYTES`.
- **G2 — W2 (≤4 params) violated** by `cat_pullback`/`cat_pushout` (5 params) and `cat_coequalizer` (4, borderline). **Fix:** collapse to a single `out:[u32;5]` aggregate (input-on-entry / output-on-exit layout, documented above). Drops to 1 param.
- **G3 — Param-spill via streaming Keccak (Trap 11/4).** `cat_compute_mor_id`, `cat_identity`, `cat_compose` call `keccak256_init();update();update();update();final(out)` with the caller's `op`/`out` pointers live across the calls — the documented param-register clobber that `identifier.iii` (header lines 6-9) and `content_addr.iii` (header lines 8-10) already abandoned. **Fix:** concatenate all parts into module scratch (`CATEGORY_HBUF`) in a fixed loop, then a single `keccak256_oneshot(&HBUF, len, out)`. Same hash value, robust.
- **G4 — Wrong extern source file.** Gospel: `keccak256_init/update/final from "keccak.iii"`. The streaming API lives in **`keccak256.iii`**; `keccak.iii` exposes only the low-level sponge (`keccak_absorb/squeeze/f1600`). **Fix:** after G3, extern only `keccak256_oneshot from "keccak256.iii"`; drop the three streaming externs and the unused `ident_from_bytes`.
- **G5 — W13 (≤20 locals) + nesting depth.** `cat_pullback`/`cat_pushout` nest 6 `if`s and accumulate many temporaries inside a triple loop. **Fix:** factor the innermost equalizing-pair test into a private helper (`category_pb_probe`) that returns a packed verdict; the outer fn then holds ≤20 locals and ≤3 nesting levels.
- **G6 — String-literal pointer idiom.** `let lit : *u8 = "id" as *u8` (in `cat_identity`) relies on `.iii` string-literal lowering not exercised elsewhere in `numera/`. **Fix:** write the two ASCII bytes `0x69,0x64` directly into `CATEGORY_HBUF[32],[33]` and hash 34 bytes.
- **G7 — Composite tie-break simplification (documentation, not a bug).** The prose says composition "selects the one with the smaller identifier under tie breaking." Because the composite op-id is `Keccak256(f_id‖g_id)` — a *deterministic function of the ordered pair* — there is never more than one candidate, so the tie-break is vacuous and the implementation is already canonical (M2). **Fix:** keep the dedup-via-`cat_add_morphism` form; note in the header that tie-break is satisfied by determinism, so no min-selection code is needed. (No code change beyond the comment.)
- **G8 — Address-of idiom (idiom trap).** `(&CAT_OBJ_ID[off]) as *u8` indexed-address form appears nowhere in the built tree (grep: 0 hits) while `((&ARR as u64) + off) as *u8` is universal. **Fix:** use the proven base+offset form in `cat_obj_id_ptr`/`cat_mor_op_ptr`/`cat_mor_id_ptr`, with `off` masked per Trap 4.
- **G9 — Missing null-pointer guards (M5/W12 robustness).** Gospel `cat_add_object`/`cat_object_id`/`cat_morphism_id`/`cat_identity` do not null-check their `*u8` out/in pointers. **Fix:** add `if (p as u64)==0u64 { return CATEGORY_E_NULL / SENT }` guards (matches `identifier.iii`/`content_addr.iii` discipline).
- **G10 — KAT absence.** Gospel ships no self-test. **Fix:** add `cat_kat()->u64` (99=pass) implementing the four KAT vectors above, each with a proven **negative** arm (M3 memory rule: prove the guard *fails* on bad input, not only passes on good).
- **Mandate coverage verified:** M1 (only identifier/keccak256 externs, all III), M2/W5 (pure hash of canonical bytes, lex-min tie-break), M3/M4 (coequalizer = algebraic equality, no statistics — the one "observational" word is mathematical), M5/M9 (every op total; failure = refusal via sentinel/error; `cat_init` restores ground state), M7 (R0 preserved), M11 (associativity check is an operational proof term), M15 (slot ops total over their width). **No witness emission** is required at this layer (category is pure essence state); if a future epoch mandates M6 fragments per mutation, add a `category_witness_hook` extern — flagged, not in scope.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/category.iii
 *
 * III STDLIB - numera::category
 *
 * Finite categories: objects + morphisms in fixed slot tables, with
 * composition, identities, pullbacks, pushouts, coequalizers, and the
 * associativity law.  Objects = 32-byte ids; morphism id = Keccak256(
 * src_id ++ dst_id ++ op); composite op = Keccak256(f_id ++ g_id);
 * identity op = Keccak256(obj_id ++ "id").  Composite uniqueness holds
 * because the id is a deterministic function of inputs (tie-break vacuous).
 *
 * Reconciliation (matches identifier.iii / content_addr.iii): the gospel
 * streamed keccak256_init/update/final over live param pointers; iiis
 * clobbers param registers across the calls (param-spill), so all parts
 * are concatenated into module scratch and hashed with keccak256_oneshot.
 *
 * Hexad: kind_essence.  Ring: R0.  K: 0.99 (slot exhaustion).
 * Discipline: W2 (<=4 params; universal ctors use a [u32;5] aggregate),
 * W8 (static slot tables), W13 (<=20 locals; pb-probe helper), W14
 * (sentinel loops, no break).  Not reentrant (serialized hash scratch).
 */

module numera_category

extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"

const CATEGORY_OK         : i32 =  0i32
const CATEGORY_E_FULL     : i32 = -1i32
const CATEGORY_E_BAD_SLOT : i32 = -2i32
const CATEGORY_E_MISMATCH : i32 = -3i32
const CATEGORY_E_NOT_FOUND: i32 = -4i32
const CATEGORY_E_NULL     : i32 = -5i32

const CATEGORY_MAX_OBJ : u32 = 1024u32
const CATEGORY_MAX_MOR : u32 = 16384u32
const CATEGORY_SENT    : u32 = 0xFFFFFFFFu32
const CATEGORY_IDBYTES : u64 = 32u64

/* Objects */
var CATEGORY_OBJ_LIVE  : [u8;  1024]
var CATEGORY_OBJ_ID    : [u8;  32768]    /* 1024 * 32 */

/* Morphisms */
var CATEGORY_MOR_LIVE  : [u8;  16384]
var CATEGORY_MOR_SRC   : [u32; 16384]
var CATEGORY_MOR_DST   : [u32; 16384]
var CATEGORY_MOR_OP    : [u8;  524288]   /* 16384 * 32 */
var CATEGORY_MOR_ID    : [u8;  524288]   /* 16384 * 32 */

/* Hash + probe scratch (module scope -- Trap 7; serialized, not reentrant) */
var CATEGORY_HBUF   : [u8; 96]           /* src||dst||op (96), f_id||g_id (64), obj||"id" (34) */
var CATEGORY_MIDBUF : [u8; 32]           /* computed morphism id */
var CATEGORY_TIDBUF : [u8; 32]           /* universal-construction probe throwaway */

/* KAT scratch */
var CATEGORY_KAT_A  : [u8; 32]
var CATEGORY_KAT_B  : [u8; 32]
var CATEGORY_KAT_C  : [u8; 32]
var CATEGORY_KAT_D  : [u8; 32]
var CATEGORY_KAT_ID : [u8; 32]
var CATEGORY_KAT_REF: [u8; 32]

/* --- address-of helpers (base+offset idiom; offset masked, Trap 4) --- */
fn cat_obj_id_ptr(slot: u32) -> *u8 { let off : u64 = ((slot as u64) & 0xFFFFFFFFu64) * 32u64  return ((&CATEGORY_OBJ_ID as u64) + off) as *u8 }
fn cat_mor_op_ptr(slot: u32) -> *u8 { let off : u64 = ((slot as u64) & 0xFFFFFFFFu64) * 32u64  return ((&CATEGORY_MOR_OP as u64) + off) as *u8 }
fn cat_mor_id_ptr(slot: u32) -> *u8 { let off : u64 = ((slot as u64) & 0xFFFFFFFFu64) * 32u64  return ((&CATEGORY_MOR_ID as u64) + off) as *u8 }

/* --- private hashing helpers (oneshot over scratch; Gap G3/G6) --- */
fn cat_compute_mor_id(src: u32, dst: u32, op: *u8, out: *u8) -> i32 { return CATEGORY_OK } // TODO: validate src/dst; HBUF[0..32)=obj(src), [32..64)=obj(dst), [64..96)=op; keccak256_oneshot(&HBUF,96,out) -- Algorithm §cat_compute_mor_id
fn cat_compute_comp_op(f_slot: u32, g_slot: u32, out: *u8) -> i32 { return CATEGORY_OK } // TODO: HBUF[0..32)=mor_id(f), [32..64)=mor_id(g); keccak256_oneshot(&HBUF,64,out) -- Algorithm §cat_compose

/* --- core (objects) --- */
fn cat_init() -> i32 @export { return CATEGORY_OK } // TODO: zero OBJ_LIVE then MOR_LIVE (two sentinel loops) -- Algorithm §cat_init
fn cat_find_object(obj_id: *u8) -> u32 @export { return CATEGORY_SENT } // TODO: scan live objects; first ident_eq match -- Algorithm §cat_find_object
fn cat_add_object(obj_id: *u8) -> u32 @export { return CATEGORY_SENT } // TODO: null-guard (G9); find-or-insert; SENT if full -- Algorithm §cat_add_object
fn cat_object_id(slot: u32, out_id: *u8) -> i32 @export { return CATEGORY_E_BAD_SLOT } // TODO: range+live+null guards; ident_copy out -- Algorithm §cat_object_id

/* --- core (morphisms) --- */
fn cat_find_morphism(mor_id: *u8) -> u32 @export { return CATEGORY_SENT } // TODO: scan live morphisms; first ident_eq match -- Algorithm §cat_find_morphism
fn cat_add_morphism(src: u32, dst: u32, op: *u8, out_id: *u8) -> u32 @export { return CATEGORY_SENT } // TODO: validate src/dst; compute id->MIDBUF; dedup; else insert; copy id->out_id -- Algorithm §cat_add_morphism
fn cat_morphism_src(slot: u32) -> u32 @export { return CATEGORY_SENT } // TODO: range+live; return MOR_SRC[slot]
fn cat_morphism_dst(slot: u32) -> u32 @export { return CATEGORY_SENT } // TODO: range+live; return MOR_DST[slot]
fn cat_morphism_id(slot: u32, out_id: *u8) -> i32 @export { return CATEGORY_E_BAD_SLOT } // TODO: range+live+null; ident_copy id->out_id

/* --- identities, composition, equality, associativity --- */
fn cat_identity(obj_slot: u32, out_id: *u8) -> u32 @export { return CATEGORY_SENT } // TODO: HBUF[0..32)=obj, [32]=0x69 [33]=0x64; oneshot(&HBUF,34,op); cat_add_morphism(obj,obj,op,out_id) -- Algorithm §cat_identity (G6)
fn cat_compose(f_slot: u32, g_slot: u32, out_id: *u8) -> u32 @export { return CATEGORY_SENT } // TODO: validate; require MOR_DST[f]==MOR_SRC[g]; comp op via cat_compute_comp_op; cat_add_morphism(SRC[f],DST[g],op,out_id) -- Algorithm §cat_compose
fn cat_morph_eq(f_slot: u32, g_slot: u32) -> u8 @export { return 0u8 } // TODO: range+live both; ident_eq(mor_id(f),mor_id(g)) -- Algorithm §cat_morph_eq
fn cat_morph_eq_u64(f_slot: u32, g_slot: u32) -> u64 @export { return 0u64 } // TODO: W16 wrapper: 1u64 if cat_morph_eq==1u8 else 0u64
fn cat_check_assoc(f_slot: u32, g_slot: u32, h_slot: u32) -> u8 @export { return 0u8 } // TODO: gf=compose(f,g); h_gf=compose(gf,h); hg=compose(g,h); hg_f=compose(f,hg); SENT-guard each; cat_morph_eq(h_gf,hg_f) -- Algorithm §cat_check_assoc

/* --- universal constructions (aggregate [u32;5]; G2/G5) --- */
fn category_pb_probe(cand: u32, m1: u32, m2: u32, mode: u32) -> u8 { return 0u8 } // TODO: mode 0=pullback (left=compose(m1,f),right=compose(m2,g)), 1=pushout (left=compose(f,m1),right=compose(g,m2)); TIDBUF scratch; 1u8 if both valid & cat_morph_eq -- Algorithm §cat_pullback/§cat_pushout
fn cat_pullback(out: *u32) -> i32 @export { return CATEGORY_E_NOT_FOUND } // TODO: out[0]=f,out[1]=g on entry; require DST[f]==DST[g]; A=SRC[f],B=SRC[g]; triple loop cand x m1(->A) x m2(->B) via category_pb_probe(...,0); lex-min by ident_cmp==-1i32; out[0]=P,out[1]=p1,out[2]=p2 -- Algorithm §cat_pullback
fn cat_pushout(out: *u32) -> i32 @export { return CATEGORY_E_NOT_FOUND } // TODO: require SRC[f]==SRC[g]; B=DST[f],C=DST[g]; cand x m1(B->cand) x m2(C->cand) via category_pb_probe(...,1); lex-min; out[0]=Q,out[1]=q1,out[2]=q2 -- Algorithm §cat_pushout
fn cat_coequalizer(out: *u32) -> i32 @export { return CATEGORY_E_NOT_FOUND } // TODO: require SRC[f]==SRC[g] && DST[f]==DST[g]; B=DST[f]; cand x m(B->cand) with compose(f,m)==compose(g,m); lex-min; out[0]=Q,out[1]=c -- Algorithm §cat_coequalizer

/* --- self-test (99 = pass; each vector has a proven negative arm; G10) --- */
fn cat_kat() -> u64 @export { return 99u64 } // TODO: KAT vectors 1-4 (identity/compose closure, associativity +neg, coequalizer +neg, mor-id determinism +endpoint-mismatch neg) -- KAT Vectors §
```
