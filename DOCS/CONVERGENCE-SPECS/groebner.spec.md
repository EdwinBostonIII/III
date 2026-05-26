# 18 numera/groebner.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is a structurally serious, mostly-correct Buchberger draft, but it (a) is uncompilable as written because every working array is a function-local `var [u32;N]` (Trap 7, ~14 sites incl. two 65536-entry queues), (b) violates W2 in three signatures (`gb_buchberger`=6 params, `gb_reduce`=5, `gb_mul_term`=5), (c) carries the flagged iiis-1 insertion-sort active-flag anti-pattern in `gb_normalize`, (d) has a real correctness bug in `gb_normalize`'s like-term merge (the seed term is merged against itself, double-counting + double-free), (e) silently truncates the basis/pair queue on overflow instead of erroring (M4/M12/M19), and (f) computes only *a* Gröbner basis, not the canonical *reduced* one — so the output is not bit-canonical for a given ideal+order. Maximal realization closes all six, adds an autoreduction pass producing the unique reduced basis, and adds a content-address digest for witnessing (M6/M12).

## Purpose
`numera_groebner` computes Gröbner bases of ideals in `GF(p)[x_0 .. x_{nvars-1}]` by Buchberger's algorithm with the first (coprime-leading-term) criterion. A polynomial IS a descending-graded-lex sequence of (GF(p) coefficient bigint-id, exponent-vector) terms held in module-scope slot tables; the module IS the deterministic synthesis engine that closes a generating set under S-polynomial reduction into a canonical reduced Gröbner basis. Field arithmetic is delegated to `numera/galois.iii` (GF(p)); coefficients are `numera/bigint.iii` ids. **Hexad: kind_essence. Ring: R0. K: 0.99** (allocation in the field/bigint layer may fail).

## Public API
All public fns return a status: `i32` negative-error codes (W9) or a `u32` slot id whose sentinel is `GROEBNER_SENT` (W12). **The gospel's `arena`/`p` per-call parameters are folded into a module-scope field session (`gb_begin`) to satisfy W2 (≤4 params); this is an intentional, mandate-driven revision of the gospel signatures and is the only API divergence.**

```
fn gb_init(nvars: u32) -> i32 @export
fn gb_begin(arena: u64, p: u64) -> i32 @export
fn gb_new_poly() -> u32 @export
fn gb_drop_poly(slot: u32) -> i32 @export
fn gb_append_term(slot: u32, coeff_bid: u64, exps: *u32) -> i32 @export
fn gb_normalize(slot: u32) -> i32 @export
fn gb_lead_exp(slot: u32, out_exps: *u32) -> i32 @export
fn gb_lead_coeff(slot: u32) -> u64 @export
fn gb_reduce(target: u32, basis: *u32, basis_n: u32) -> u32 @export
fn gb_spoly(f: u32, g: u32) -> u32 @export
fn gb_make_monic(slot: u32) -> i32 @export
fn gb_autoreduce(basis: *u32, basis_n: u32, out_basis: *u32, out_n: *u32) -> i32 @export
fn gb_buchberger(generators: *u32, gen_n: u32, out_basis: *u32, out_n: *u32) -> i32 @export
fn gb_basis_digest(basis: *u32, basis_n: u32, out32: *u8) -> i32 @export
```

Return-status convention per fn:
- `gb_init`/`gb_begin`/`gb_drop_poly`/`gb_append_term`/`gb_normalize`/`gb_lead_exp`/`gb_make_monic`/`gb_autoreduce`/`gb_buchberger`/`gb_basis_digest` → `i32` ∈ {`GROEBNER_OK`(0), negatives}. Compare only by `==`/`!=` (W11/Trap 3).
- `gb_new_poly`/`gb_reduce`/`gb_spoly` → `u32` slot id; failure sentinel `GROEBNER_SENT` (0xFFFFFFFF). (W12: sentinel-typed value.)
- `gb_lead_coeff` → `u64` bigint id; `0u64` on empty/error (bigint INVALID convention, matches `field.iii`/`bigint.iii`).

## Constant Namespace
PREFIX = `GROEBNER_` . Grep of `STDLIB/` returned **zero** existing `GROEBNER_` symbols → no collision. (The gospel draft used a shorter `GB_` token prefix on locals; all module-level constants below carry the full assigned `GROEBNER_` prefix because module-level `const` is linker-global — Trap 2.)

| const | type | value | note |
|---|---|---|---|
| `GROEBNER_OK` | i32 | `0i32` | success |
| `GROEBNER_E_FULL` | i32 | `-1i32` | slot/term/exp/basis/pair table exhausted |
| `GROEBNER_E_BAD` | i32 | `-2i32` | bad slot / not live / nvars OOB / empty poly |
| `GROEBNER_E_NOSESS` | i32 | `-3i32` | `gb_begin` not called (arena/p unset) |
| `GROEBNER_E_INV` | i32 | `-4i32` | leading coeff not invertible in GF(p) (non-prime p) |
| `GROEBNER_SENT` | u32 | `0xFFFFFFFFu32` | slot sentinel |
| `GROEBNER_MAX_POLY` | u32 | `4096u32` | live polynomial slots (W8 bound) |
| `GROEBNER_MAX_TERMS` | u32 | `65536u32` | total term records (W8 bound) |
| `GROEBNER_MAX_VARS` | u32 | `16u32` | exponent-vector width cap (W8 bound) |
| `GROEBNER_EXP_AREA` | u64 | `1048576u64` | exponent words = 65536·16 (W8 bound) |
| `GROEBNER_MAX_BASIS` | u32 | `1024u32` | max basis polynomials during run (W8 bound) |
| `GROEBNER_MAX_PAIRS` | u32 | `65536u32` | max queued S-pairs (W8 bound) |

(Names changed vs gospel: `GB_*` → `GROEBNER_*`; added `GROEBNER_E_NOSESS`, `GROEBNER_E_INV`, `GROEBNER_MAX_BASIS`, `GROEBNER_MAX_PAIRS`. The numeric error values keep the gospel's choices where they existed.)

## Data Structures
All arrays are **module-scope** `var` (Trap 7: local `var` arrays do not parse; the entire built STDLIB declares every array at module scope). Single-threaded deterministic substrate ⇒ no concurrent reentrancy; the per-function scratch buffers below are proven non-aliasing by the call-graph analysis in §Algorithm.

Slot / storage tables (carried from gospel, renamed):
| name | type | size | bound justification |
|---|---|---|---|
| `GROEBNER_NVARS` | u32 | scalar | ≤ `GROEBNER_MAX_VARS` |
| `GROEBNER_ARENA` | u64 | scalar | field session arena id (set by `gb_begin`) |
| `GROEBNER_MOD_P` | u64 | scalar | field session modulus bigint id (set by `gb_begin`) |
| `GROEBNER_SESS` | u8 | scalar | 1 after `gb_begin`, else 0 |
| `GROEBNER_PL_LIVE` | [u8; 4096] | 4096 | one flag per poly slot = `GROEBNER_MAX_POLY` |
| `GROEBNER_PL_START` | [u32; 4096] | 4096 | term-range start per slot |
| `GROEBNER_PL_END` | [u32; 4096] | 4096 | term-range end per slot |
| `GROEBNER_TERM_COEFF` | [u64; 65536] | 65536 | bigint id per term = `GROEBNER_MAX_TERMS` |
| `GROEBNER_TERM_EXP_OFF` | [u32; 65536] | 65536 | exp-buffer offset per term |
| `GROEBNER_TERM_USED` | u32 | scalar | bump cursor into term tables |
| `GROEBNER_EXP_BUF` | [u32; 1048576] | 1048576 | 65536 terms · 16 vars (`GROEBNER_EXP_AREA`) |
| `GROEBNER_EXP_USED` | u64 | scalar | bump cursor into exp buffer |

Buchberger working set (hoisted from gospel locals — these are the 65536-entry queues that could never have been stack locals):
| name | type | size | bound justification |
|---|---|---|---|
| `GROEBNER_BASIS` | [u32; 1024] | 1024 | running basis slot ids = `GROEBNER_MAX_BASIS` |
| `GROEBNER_PQ_I` | [u32; 65536] | 65536 | S-pair left index = `GROEBNER_MAX_PAIRS` |
| `GROEBNER_PQ_J` | [u32; 65536] | 65536 | S-pair right index |
| `GROEBNER_AR_OUT` | [u32; 1024] | 1024 | autoreduce result buffer |

Per-function exponent scratch (each a distinct `[u32;16]`, width = `GROEBNER_MAX_VARS`; named by owning fn to prove non-aliasing):
| name | owner fn | size |
|---|---|---|
| `GROEBNER_MT_EXPS` | `gb_mul_term` | [u32; 16] |
| `GROEBNER_RD_LT` / `GROEBNER_RD_LE` / `GROEBNER_RD_D` | `gb_reduce` | [u32; 16] each |
| `GROEBNER_SP_FE` / `_GE` / `_LL` / `_DF` / `_DG` | `gb_spoly` | [u32; 16] each |
| `GROEBNER_DS_FE` / `GROEBNER_DS_GE` | `gb_disjoint_supports` | [u32; 16] each |
| `GROEBNER_AR_LE` / `GROEBNER_AR_LT` | `gb_autoreduce` | [u32; 16] each |
| `GROEBNER_DG_BUF` | `gb_basis_digest` (serialization scratch) | [u8; 256] |

No `var [..]` is ever declared inside a function body. No address-of-static escapes the file (W1/W3): `&GROEBNER_*[0]` is taken only inside `groebner.iii`.

## Dependencies (externs)
```
extern @abi(c-msvc-x64) fn bigint_from_u64(arena: u64, v: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_copy(arena: u64, src: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_drop(id: u64) -> i32 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_is_zero(id: u64) -> u8 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_to_u64_lo(id: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn gfp_add(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
extern @abi(c-msvc-x64) fn gfp_sub(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
extern @abi(c-msvc-x64) fn gfp_mul(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
extern @abi(c-msvc-x64) fn gfp_inv(arena: u64, a: u64, p: u64) -> u64 from "galois.iii"
```

| extern | from | NN | status |
|---|---|---|---|
| `bigint_from_u64`, `bigint_copy`, `bigint_drop`, `bigint_is_zero`, `bigint_to_u64_lo` | bigint.iii | (V1 base) | **BUILT** — verified present in `STDLIB/iii/numera/bigint.iii` |
| `gfp_add`, `gfp_sub`, `gfp_mul`, `gfp_inv` | galois.iii | **Module 04** | **NOT-YET-BUILT** — designed in parallel this wave; signatures verified against the gospel Module-04 body (exact match) |

Pruned vs gospel: `arena_alloc1` (never called — groebner allocates no raw arena bytes), `bigint_new`, `bigint_eq` (unused). Added: `bigint_to_u64_lo` (for the digest's deterministic coefficient serialization). The `from "arena.iii"` basename convention is the established house style (bigint.iii/galois.iii both import `arena_alloc1 from "arena.iii"` though the file lives at `memoria/arena.iii`); groebner needs no arena import after pruning. **Wave ordering: groebner (18) must schedule after galois (04).** bigint is already built.

## Algorithm

Common conventions: a polynomial slot's terms occupy `GROEBNER_TERM_*[start..end)`. Terms are kept in **descending graded-lex** order so term `start` is the leading term. `arena`/`p` are read from `GROEBNER_ARENA`/`GROEBNER_MOD_P` (set once by `gb_begin`); every public op first checks `GROEBNER_SESS == 1u8` else returns `GROEBNER_E_NOSESS`. No `%` anywhere (Trap 11 not exposed). All loop exits use the W14 sentinel/flag form — **no `break`, no `&&`** (compound `while` conditions are unsupported in the grammar; confirmed zero `&&` in built STDLIB). No recursion anywhere (W15); the only algorithm that is naturally recursive (multivariate division / Buchberger closure) is driven by the explicit `GROEBNER_PQ_*` pair queue and the `progressed`-flag reduction loop.

**`gb_init(nvars)`** — validate `nvars <= GROEBNER_MAX_VARS` (`u32` ordering compare is legal — Trap 3 is signed-only), set `GROEBNER_NVARS`, clear all `GROEBNER_PL_LIVE`, zero `GROEBNER_TERM_USED`/`GROEBNER_EXP_USED`, clear `GROEBNER_SESS`. Determinism: pure register/array writes. **Bounded** (≤ `GROEBNER_MAX_POLY` iterations) → M19.

**`gb_begin(arena, p)`** — record the field session: `GROEBNER_ARENA=arena`, `GROEBNER_MOD_P=p`, `GROEBNER_SESS=1u8`. (This is the W2 fix: it removes `arena`,`p` from every per-op signature.) M8 note: `arena` is the capability handle for allocation; `p` defines the field. Reversible: `gb_init` resets it.

**`gb_new_poly` / `gb_drop_poly` / `gb_term_exp_ptr` (internal) / `gb_append_term`** — as gospel, renamed. `gb_new_poly` linear-scans `GROEBNER_PL_LIVE` for a free slot (≤ `GROEBNER_MAX_POLY`, M19), returns `GROEBNER_SENT` when full. `gb_append_term` bounds-checks `GROEBNER_TERM_USED < GROEBNER_MAX_TERMS` and `GROEBNER_EXP_USED + NVARS <= GROEBNER_EXP_AREA` → `GROEBNER_E_FULL`. Exponent index math: `GROEBNER_EXP_BUF[(GROEBNER_EXP_USED as u32) + k]` — `GROEBNER_EXP_USED` is the `u64` cursor; before indexing, mask `((GROEBNER_EXP_USED) & 0xFFFFFFFFu64) as u32` then add `k` (Trap 4: u32-in-u64-slot). `gb_drop_poly` drops each term's coeff bigint (no bigint leak) and reclaims term/exp space **only if the slot is the most-recent bump** (`end == GROEBNER_TERM_USED`) — LIFO reclamation, exactly the gospel behavior; documented as monotonic otherwise (see Gap §lifecycle).

**`gb_exp_cmp(a,b) -> i32` (internal)** — graded lex: sum exponents into `sa`,`sb` (`u32`); `if sa < sb return -1i32; if sa > sb return 1i32` (u32 ordering — legal). Then lex tie-break with a `done` flag (no `break`). Returns `-1/0/1`. **Fixed deterministic monomial order (M2/M4):** graded-lex over the fixed variable index order `0..nvars-1`; never data-dependent.

**`gb_exp_eq` / `gb_lcm` / `gb_div_exp` / `gb_disjoint_supports` (internal)** — as gospel (flag-guarded loops, u32 compares only). `gb_div_exp(a,b)` = "a divides b" iff ∀k a[k]≤b[k]. `gb_disjoint_supports` = Buchberger Criterion 1 (coprime leading terms ⇒ S-poly reduces to 0, skip pair) — uses `GROEBNER_DS_FE/GE`.

**`gb_normalize(slot)`** — three passes:
1. **Stable insertion sort, descending.** Driven by the **W14 flag form** (the iiis-1 active-flag trap is the gospel's exact bug here): outer `p1` from `start+1`; inner uses `let mut moving : u8 = 1u8; while moving == 1u8 { if q == start { moving = 0u8 } else { compare exp(q-1),exp(q) once into a local cmp; if cmp == -1i32 { swap; q = q - 1u32 } else { moving = 0u8 } } }`. The flag `moving` (not the index `q`) drives termination, so setting it never clobbers a valid insertion index; `gb_exp_cmp` is evaluated **once** per step (gospel called it twice).
2. **Combine adjacent equal exponents.** Seed the write head once *before* the loop: `if end > start { copy term[start] into write head w=start+1; r=start+1 }`. Then `while r < end`: compare `exp(w-1)` vs `exp(r)` once into `eq`; `if eq == 1u8 { coeff[w-1] = gfp_add(coeff[w-1], coeff[r]); drop old coeff[w-1]; drop coeff[r] } else { coeff[w]=coeff[r]; exp_off[w]=exp_off[r]; w=w+1 }`. **This fixes the gospel double-count/double-free bug** (gospel ran both the `w==start` seed branch and the `w>start` merge branch in the same first iteration, merging term[start] with itself). gfp_add result is owned by the slot.
3. **Drop zero coeffs.** Compact `[start..w)`: keep terms with `bigint_is_zero == 0u8`, `bigint_drop` the zeros. Set `GROEBNER_PL_END[slot]` to the final write head. Determinism: total order + total field add ⇒ unique canonical term list (M15).

**`gb_lead_exp` / `gb_lead_coeff` / `gb_is_zero` (internal)** — as gospel; empty poly ⇒ `GROEBNER_E_BAD` / `0u64` / `1u8`.

**`gb_mul_term(src, c, d) -> u32` (internal helper, now ≤4 params)** — new poly `out`; for each term of `src`: `new_c = gfp_mul(coeff, c)`; `GROEBNER_MT_EXPS[k] = src_exp[k] + d[k]`; `gb_append_term(out, new_c, &GROEBNER_MT_EXPS[0])`. Returns `out` (caller owns). Uses `GROEBNER_MT_EXPS` only — distinct from caller scratch (§reentrancy below).

**`gb_sub_inplace(a, b) -> i32` (internal)** — `a := a - b`: `zero = bigint_from_u64(0)`; for each term of `b`, append `gfp_sub(zero, coeff_b)` with b's exponents into `a`; `bigint_drop(zero)`; `gb_normalize(a)`. Field subtraction is total (M15).

**`gb_reduce(target, basis, basis_n) -> u32`** — multivariate division (the explicit-stack replacement for recursive reduction, W15):
- Copy `target` (deep-copy each coeff via `bigint_copy`) into a fresh `work` slot; `gb_normalize(work)`.
- `let mut progressed : u8 = 1u8; while progressed == 1u8 { progressed = 0u8; if gb_is_zero(work)==0u8 { read LT into GROEBNER_RD_LT, lc=lead_coeff(work); scan i over basis with a hit flag: for first g whose LT divides work's LT (gb_div_exp(GROEBNER_RD_LE, GROEBNER_RD_LT)==1): d = LT - LE (per-coord u32 subtract, always ≥0 because divisibility was checked); factor = gfp_mul(lc, gfp_inv(glc)); scaled = gb_mul_term(g, factor, d); gb_sub_inplace(work, scaled); gb_drop_poly(scaled); hit=1; progressed=1 } }`.
- **Determinism (M2/M4):** the divisor chosen is always the *first* basis index whose LT divides — a fixed rule, no heuristic. Termination: each reduction strictly lowers the leading monomial under graded-lex (a well-order on a finite-dimensional grading), so `progressed` becomes 0 in finitely many steps (M19 bounded; the grading is the cost lattice). `gfp_inv` returns INVALID(0) on non-invertible lead (composite p) → propagate `GROEBNER_E_INV` path by treating factor as failure (skip + record), so no UAF. Returns remainder slot `work` (caller owns). Scratch: `GROEBNER_RD_LT/LE/D` — distinct from `GROEBNER_MT_EXPS`.

**`gb_spoly(f, g) -> u32`** — `L = lcm(LT(f),LT(g))` into `GROEBNER_SP_LL`; `df = L - LT(f)`, `dg = L - LT(g)`; `part_f = gb_mul_term(f, inv(LT_coeff(f)), df)`, `part_g = gb_mul_term(g, inv(LT_coeff(g)), dg)`; `out = part_f`; `gb_sub_inplace(out_copy, part_g)` (copy part_f's terms into a fresh `out`, then subtract part_g — as gospel); drop `part_f`,`part_g`,the two inverses. The S-poly definition matches the gospel prose `(L/LT(f))·f − (L/LT(g))·g` with monic scaling. Scratch: `GROEBNER_SP_FE/GE/LL/DF/DG` — distinct from reduce/mul scratch.

**`gb_make_monic(slot) -> i32`** (new, maximal intent) — if non-empty, `inv = gfp_inv(lead_coeff)`; multiply every coeff in place by `inv` (so lead coeff becomes `1`); drop `inv`. Makes the polynomial's canonical scale unique → required for the *reduced* basis's uniqueness (M2/M12). `GROEBNER_E_INV` if lead not invertible.

**`gb_autoreduce(basis, basis_n, out_basis, out_n) -> i32`** (new, maximal intent) — turn a Gröbner basis into the **unique reduced** Gröbner basis:
1. **Minimalize:** drop any `g` whose leading monomial is divisible by the leading monomial of some *other* basis element (`gb_div_exp(LT(other),LT(g))==1`, other≠g) — fixed scan order, deterministic.
2. **Inter-reduce:** for each surviving `g`, replace it by `gb_reduce(g, {others})` so no term of `g` is divisible by any other leading monomial.
3. **Monic:** `gb_make_monic` each result. Write survivors (in ascending leading-monomial order under `gb_exp_cmp`, a fixed total order) to `out_basis`, set `*out_n`. The result is the canonical reduced Gröbner basis — **bit-identical for a given ideal + monomial order regardless of generator order or pair-processing order** (W5/M2/M12). No recursion (explicit `GROEBNER_AR_*` buffers + flag loops).

**`gb_buchberger(generators, gen_n, out_basis, out_n) -> i32`** (W2: 4 params after session fold):
- Normalize each generator; push nonzero ones into `GROEBNER_BASIS` (bn). **Overflow → return `GROEBNER_E_FULL`** (gospel silently dropped — fixed).
- Build the initial pair queue `GROEBNER_PQ_I/J` over all `i<j` in fixed index order. Overflow → `GROEBNER_E_FULL`.
- Process the queue **FIFO from head to `pq_len`** (`pq_head` cursor). This is the **fixed deterministic S-pair selection rule (M4): first-in-first-out by insertion order** — not a sugar/lcm heuristic; documented as the canonical normal selection for this module. For each pair (ix,jx): if not `gb_disjoint_supports` (Criterion 1), `s = gb_spoly`; `r = gb_reduce(s, basis, bn)`; drop `s`; if `r` nonzero: append to basis (overflow → `GROEBNER_E_FULL`, **not** silent drop) and enqueue new pairs (k,bn) for k<bn (overflow → `GROEBNER_E_FULL`); else drop `r`.
- **Termination (M19):** by Dickson's lemma the chain of leading-term ideals stabilizes, so finitely many nonzero remainders are ever added; the static caps are a hard ceiling that converts pathological/over-cap inputs into an honest `GROEBNER_E_FULL` rather than a wrong answer.
- **Finalize:** call `gb_autoreduce(basis, bn, out_basis, out_n)` so the public result is the canonical reduced basis. Caller owns the `out_basis` slots and must `gb_drop_poly` them; intermediate dropped/zero slots are freed internally (term storage is monotonic until `gb_init` — see Gap §lifecycle).

**`gb_basis_digest(basis, basis_n, out32) -> i32`** (new, M6/M10/M12 — maximal intent) — serialize the reduced basis deterministically (for each poly in order: term count, then per term the exponent vector words little-endian via byte stores through `*u8` (Trap 5), then the coefficient low-limb via `bigint_to_u64_lo` little-endian) into `GROEBNER_DG_BUF`, folding 32 output bytes with a fixed FNV-1a-style mix over the serialized stream. Gives the synthesized ideal a **content address** so a higher layer (witness_spine, Module 12) can chain it (M6) and any party can recompute it byte-identically from the basis (M10). This is the module's verifiable certificate (M12); the basis being *reduced* + *monic* makes the digest a true invariant of the ideal.

### Reentrancy / scratch non-aliasing proof (Trap 7 hoist safety)
Single-threaded substrate; the only concern is one function's scratch being clobbered by a callee. Call graph: `gb_buchberger → {gb_normalize, gb_disjoint_supports, gb_spoly, gb_reduce, gb_autoreduce}`; `gb_spoly → {gb_mul_term, gb_sub_inplace}`; `gb_reduce → {gb_mul_term, gb_sub_inplace, gb_lead_*}`; `gb_autoreduce → {gb_reduce, gb_make_monic, gb_div_exp}`; `gb_sub_inplace → gb_normalize`. Each function owns a *disjoint, uniquely-named* scratch set (`GROEBNER_MT_*`, `GROEBNER_RD_*`, `GROEBNER_SP_*`, `GROEBNER_DS_*`, `GROEBNER_AR_*`). No function calls itself; `gb_mul_term` (the only fn reached from two different scratch-holders, spoly and reduce) touches only `GROEBNER_MT_EXPS`, disjoint from both `GROEBNER_SP_*` and `GROEBNER_RD_*`. `gb_buchberger`'s queue/basis (`GROEBNER_PQ_*`,`GROEBNER_BASIS`) are touched by no callee. Therefore no live scratch is ever overwritten. (W8: each buffer statically sized; bounds justified in §Data Structures.)

## KAT Vectors (>= 3)
Field GF(7) (p = bigint 7) unless noted; nvars and polynomials given as term lists `coeff·x^a y^b ...`; leading term first after normalize. Self-test builds polys via `gb_append_term`, runs the op, and checks the normalized term list and the digest byte-for-byte.

1. **Normalize / combine / monic (nvars=1, GF(7)).**
   Input poly `T = 3·x^2 + 5·x^2 + 6·x^0` (appended out of order: `6·1, 3·x^2, 5·x^2`). After `gb_normalize`: combine `3+5=8≡1 (mod 7)` ⇒ `1·x^2 + 6·1`, sorted desc.
   `gb_lead_exp → [2]`, `gb_lead_coeff` low-limb `→ 1`. After `gb_make_monic` (lead already 1) unchanged. Verifies the merge-bug fix (no double count: result is `1`, not `2`) and the sort flag-fix.

2. **S-polynomial cancels leading terms (nvars=2, GF(7), graded-lex x>y).**
   `f = x^2 + 1`, `g = x·y + 2`. `LT(f)=x^2`, `LT(g)=xy`, `lcm = x^2 y`. `df = y`, `dg = x`.
   `S(f,g) = y·f − x·g = (x^2 y + y) − (x^2 y + 2x) = y − 2x ≡ y + 5x (mod 7)`.
   Expected `gb_spoly` result normalized (graded-lex, deg 1 both; lex x>y) `→ 5·x + 1·y`. Lead exp `[1,0]`, lead coeff `5`. Verifies spoly + monic scaling + sub_inplace.

3. **Buchberger reduced basis — already-Gröbner linear ideal (nvars=2, GF(7)).**
   Generators `g1 = x + 6` (i.e. x−1), `g2 = y + 5` (i.e. y−2). LTs `x`,`y` are coprime ⇒ Criterion 1 skips the only pair ⇒ no new elements. `gb_autoreduce` makes each monic (already) and inter-reduces (no cross-divisibility) ⇒ reduced basis `{ x + 6, y + 5 }`, `*out_n = 2`. Verifies Criterion-1 skip, FIFO queue, autoreduce passthrough, and overflow-free path.

4. **Buchberger produces a new element then reduces (nvars=2, GF(7)).**
   Generators `f1 = x^2 + 1`, `f2 = x·y + 2` (from KAT 2). Pair (f1,f2) not coprime (`x` shared). `S = 5x + y` (KAT 2) reduces by the basis: neither `x^2` nor `xy` divides `5x` or `y` ⇒ remainder `5x + y` (monic: ·inv(5)=·3 ⇒ `x + 3y`). Add to basis. New pairs with f1,f2 then reduce to zero (S-polys land in the ideal). Expected reduced Gröbner basis (canonical, monic, inter-reduced, ascending LT): `{ x + 3y, y^2 + ... }` — exact tail computed by the reference run and frozen as the byte-vector; `gb_basis_digest` over it is recorded as the 32-byte acceptance hash. Verifies the full closure + autoreduce + digest determinism (run twice, identical digest = M2/M10).

(For Phase 2: vectors 1–3 are hand-checkable; vector 4's frozen tail + digest are captured from the first correct reference execution and then locked, per the crypto-KAT discipline used elsewhere in numera.)

## Trap Exposure
| # | Trap | Exposed? | Avoidance |
|---|---|---|---|
| 1 | Multi-line `fn` decl | YES (15 fns) | Every signature in §Public API and §Skeleton is single-line. |
| 2 | Module-level `const` linker-global | YES (12 consts) | All carry `GROEBNER_` prefix; grep confirms no STDLIB collision. |
| 3 | Signed ordering compare SIGSEGV | YES (`gb_exp_cmp` returns i32) | i32 results compared only via `== -1i32`/`!= -1i32`/`== 1i32` (never `<`/`>` on the i32). All `<`/`>` in the module are on **u32** exponents/indices (legal). |
| 4 | u32-in-u64-slot garbage | YES (`GROEBNER_EXP_USED:u64` used as index) | Mask `(GROEBNER_EXP_USED & 0xFFFFFFFFu64) as u32` before `+ k` indexing into `GROEBNER_EXP_BUF`. |
| 5 | u32 pointer store width | YES (digest byte serialization) | `gb_basis_digest` stores exponents/coeff bytes one-at-a-time through `*u8` with explicit `>> (i*8) & 0xFFu64` extraction. Exponent buffer itself is `[u32;..]` written via array index (not `*u32` store from a u32 local), so the term-build path is unaffected. |
| 6 | Nested `/* */` | N/A | Header + section comments are single-level; inline notes use `//`. |
| 7 | Local `var` arrays | YES — the dominant gospel defect (~14 sites) | **Every** array hoisted to module scope with a unique `GROEBNER_` name; non-aliasing proven in §reentrancy. |
| 8 | `} else {` must be one line | YES (introduced by the normalize/reduce fixes) | All `} else {` written on one line (bigint.iii confirms this idiom compiles). |
| 9 | Em-dash in comment | Avoided | All comments use ASCII `--`. |
| 10 | `let mut flag` checkpoint misbehave | YES (`progressed`, `hit`, `moving`, `done`) | Flags drive a *simple* `while flag == Nu8` condition (no `&&`); reduction uses the proven `while progressed == 1u8` form; insertion sort uses the `moving` flag, not the index, to terminate (fixes the iiis-1 active-flag trap). |
| 11 | `a % b` after call | NO | The module performs no modulo; all field reduction is inside galois.iii. |
| 12 | `@specialize *T` stride | N/A | No generics; element widths are concrete (`u32` exps, `u64` coeff ids). |

## Gap / Fix List
1. **Trap 7 — local `var` arrays (uncompilable).** Gospel declares `var exps:[u32;16]` (gb_mul_term), `var lt/le/d`, `var fe/ge/ll/df/dg`, `var basis:[u32;1024]`, `var pq_i/pq_j:[u32;65536]` etc. as function locals. **Fix:** hoist all to module scope with unique `GROEBNER_*` names (§Data Structures); the 65536-entry queues *had* to move regardless (256 KB stack each is infeasible). Non-aliasing proven (§reentrancy).
2. **W2 — >4 params (3 fns).** `gb_buchberger`(6), `gb_reduce`(5), `gb_mul_term`(5). **Fix:** fold `arena`,`p` into a module-scope session via new `gb_begin(arena,p)`; public sigs drop to ≤4. Add `GROEBNER_E_NOSESS` guard.
3. **iiis-1 insertion-sort active-flag trap (gospel `gb_normalize`).** Inner loop sets `q = start` to terminate — the exact flagged anti-pattern; also calls `gb_exp_cmp` twice/iter. **Fix:** drive termination with a `moving` flag (`while moving == 1u8`), evaluate `gb_exp_cmp` once into a local, set `moving=0u8` to stop (never clobber `q`).
4. **Correctness bug — `gb_normalize` like-term merge double-counts the seed.** On the first iteration both `if w==start` (seed) and `if w>start` (merge) fire, merging `term[start]` with itself → wrong coefficient (doubled) **and double-free** of `coeff[start]`. **Fix:** seed the write head once before the loop; use one-line `} else {` so seed and merge are mutually exclusive (§Algorithm gb_normalize).
5. **M4/M12/M19 — silent truncation on overflow.** Gospel: `if bn < 1024 { add } else { /* silently dropped */ }` and the same for `pq_len < 65536`. Dropping a basis element yields a **non-Gröbner** result presented as success. **Fix:** every cap breach returns `GROEBNER_E_FULL`; never silently drop. Caps documented as W8 static bounds.
6. **Maximal intent — only *a* basis, not the canonical *reduced* one.** Gospel output depends on pair order ⇒ not bit-canonical for the ideal. **Fix:** add `gb_make_monic` + `gb_autoreduce` (minimalize, inter-reduce, monic, sort by LT) and call it at the end of `gb_buchberger`, yielding the unique reduced Gröbner basis (M2/M12/W5).
7. **M6/M10/M12 — no witness/certificate.** Gospel emits no checkable artifact. **Fix:** add `gb_basis_digest` (deterministic serialization + fixed FNV-1a mix) → content address of the reduced basis for chaining by witness_spine (M12 verifiable; M10 recomputable). Note: per-op witness emission is delegated to the consuming layer; the kernel's certificate is the reduced basis + its digest.
8. **Trap 4 — `GROEBNER_EXP_USED` (u64) used as a u32 index** in `gb_append_term`. **Fix:** mask before indexing.
9. **Unused externs.** `arena_alloc1`, `bigint_new`, `bigint_eq` are declared but never called. **Fix:** prune (added `bigint_to_u64_lo` for the digest). Wave note: **galois.iii (Module 04) is NOT-YET-BUILT** — groebner must schedule after it; bigint is built.
10. **Lifecycle (bounded, documented).** `gb_drop_poly` reclaims term/exp space only LIFO (`end == GROEBNER_TERM_USED`), so intermediates (spoly parts, scaled multiples) accumulate monotonically until `gb_init`. This is **bounded** (hard caps → `GROEBNER_E_FULL`, M19 satisfied) but means a single `gb_buchberger` call must fit within `GROEBNER_MAX_TERMS`. **Fix/guidance:** treat each top-level `gb_buchberger` as one bump epoch — call `gb_init` to reset between independent problems; drop slots LIFO where the call order allows. Not a correctness defect, but flagged so Phase 2 sizes the bound deliberately and the KATs stay within it.
11. **GF(p) non-invertible lead (composite p).** `gfp_inv` may return INVALID(0). Gospel ignores this and would build wrong terms. **Fix:** treat `gfp_inv == 0u64` as failure → `GROEBNER_E_INV` (reduce/spoly/make_monic), no UAF, no silent wrong result (M4). The module assumes prime p (the GF(p) contract) and refuses otherwise rather than producing garbage (M5: refusal, not bricking).

## Implementation Skeleton
```iii
// C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\groebner.iii
//
// III STDLIB - numera::groebner
//
// Multivariate Groebner basis over GF(p) via Buchberger + Criterion 1,
// producing the canonical REDUCED (monic, inter-reduced) basis, with a
// content-address digest for witnessing.
//
// Polynomial = descending graded-lex sequence of terms; a term is a
// GF(p) coefficient (bigint id) + an NVARS-wide u32 exponent vector.
// Slot tables + bump buffers live at module scope (Trap 7).
//
// Field session (arena, p) is set once by gb_begin (W2: <=4 params/fn).
//
// Hexad: kind_essence.  Ring: R0.  K: 0.99.

module numera_groebner

extern @abi(c-msvc-x64) fn bigint_from_u64(arena: u64, v: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_copy(arena: u64, src: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_drop(id: u64) -> i32 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_is_zero(id: u64) -> u8 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_to_u64_lo(id: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn gfp_add(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
extern @abi(c-msvc-x64) fn gfp_sub(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
extern @abi(c-msvc-x64) fn gfp_mul(arena: u64, a: u64, b: u64, p: u64) -> u64 from "galois.iii"
extern @abi(c-msvc-x64) fn gfp_inv(arena: u64, a: u64, p: u64) -> u64 from "galois.iii"

const GROEBNER_OK         : i32 =  0i32
const GROEBNER_E_FULL     : i32 = -1i32
const GROEBNER_E_BAD      : i32 = -2i32
const GROEBNER_E_NOSESS   : i32 = -3i32
const GROEBNER_E_INV      : i32 = -4i32
const GROEBNER_SENT       : u32 = 0xFFFFFFFFu32

const GROEBNER_MAX_POLY   : u32 = 4096u32
const GROEBNER_MAX_TERMS  : u32 = 65536u32
const GROEBNER_MAX_VARS   : u32 = 16u32
const GROEBNER_EXP_AREA   : u64 = 1048576u64
const GROEBNER_MAX_BASIS  : u32 = 1024u32
const GROEBNER_MAX_PAIRS  : u32 = 65536u32

var GROEBNER_NVARS        : u32 = 0u32
var GROEBNER_ARENA        : u64 = 0u64
var GROEBNER_MOD_P        : u64 = 0u64
var GROEBNER_SESS         : u8  = 0u8

var GROEBNER_PL_LIVE      : [u8;  4096]
var GROEBNER_PL_START     : [u32; 4096]
var GROEBNER_PL_END       : [u32; 4096]

var GROEBNER_TERM_COEFF   : [u64; 65536]
var GROEBNER_TERM_EXP_OFF : [u32; 65536]
var GROEBNER_TERM_USED    : u32 = 0u32

var GROEBNER_EXP_BUF      : [u32; 1048576]
var GROEBNER_EXP_USED     : u64 = 0u64

var GROEBNER_BASIS        : [u32; 1024]
var GROEBNER_PQ_I         : [u32; 65536]
var GROEBNER_PQ_J         : [u32; 65536]
var GROEBNER_AR_OUT       : [u32; 1024]

var GROEBNER_MT_EXPS      : [u32; 16]
var GROEBNER_RD_LT        : [u32; 16]
var GROEBNER_RD_LE        : [u32; 16]
var GROEBNER_RD_D         : [u32; 16]
var GROEBNER_SP_FE        : [u32; 16]
var GROEBNER_SP_GE        : [u32; 16]
var GROEBNER_SP_LL        : [u32; 16]
var GROEBNER_SP_DF        : [u32; 16]
var GROEBNER_SP_DG        : [u32; 16]
var GROEBNER_DS_FE        : [u32; 16]
var GROEBNER_DS_GE        : [u32; 16]
var GROEBNER_AR_LE        : [u32; 16]
var GROEBNER_AR_LT        : [u32; 16]
var GROEBNER_DG_BUF       : [u8; 256]

// ---- session + lifecycle ----
fn gb_init(nvars: u32) -> i32 @export { /* TODO: body per Algorithm gb_init */ }
fn gb_begin(arena: u64, p: u64) -> i32 @export { /* TODO: body per Algorithm gb_begin */ }
fn gb_new_poly() -> u32 @export { /* TODO: body per Algorithm gb_new_poly */ }
fn gb_drop_poly(slot: u32) -> i32 @export { /* TODO: body per Algorithm gb_drop_poly */ }

// ---- internal exponent helpers ----
fn gb_term_exp_ptr(t: u32) -> *u32 { /* TODO: &GROEBNER_EXP_BUF[GROEBNER_TERM_EXP_OFF[t]] */ }
fn gb_exp_cmp(a: *u32, b: *u32) -> i32 { /* TODO: graded-lex, flag-driven lex tie-break */ }
fn gb_exp_eq(a: *u32, b: *u32) -> u8 { /* TODO: flag-guarded equality */ }
fn gb_lcm(a: *u32, b: *u32, out: *u32) -> i32 { /* TODO: per-coord max */ }
fn gb_div_exp(a: *u32, b: *u32) -> u8 { /* TODO: a divides b iff a[k]<=b[k] all k */ }
fn gb_disjoint_supports(f: u32, g: u32) -> u8 { /* TODO: Criterion 1, uses GROEBNER_DS_* */ }

// ---- term build / queries ----
fn gb_append_term(slot: u32, coeff_bid: u64, exps: *u32) -> i32 @export { /* TODO: mask EXP_USED (Trap 4) */ }
fn gb_normalize(slot: u32) -> i32 @export { /* TODO: flag-driven insort + seeded merge + drop-zeros (Gap 3,4) */ }
fn gb_lead_exp(slot: u32, out_exps: *u32) -> i32 @export { /* TODO */ }
fn gb_lead_coeff(slot: u32) -> u64 @export { /* TODO */ }
fn gb_is_zero(slot: u32) -> u8 { /* TODO */ }

// ---- polynomial arithmetic ----
fn gb_mul_term(src: u32, c: u64, d: *u32) -> u32 { /* TODO: uses GROEBNER_MT_EXPS */ }
fn gb_sub_inplace(a: u32, b: u32) -> i32 { /* TODO: a := a - b, then normalize */ }
fn gb_make_monic(slot: u32) -> i32 @export { /* TODO: scale by inv(lead) */ }

// ---- reduction / S-poly ----
fn gb_reduce(target: u32, basis: *u32, basis_n: u32) -> u32 @export { /* TODO: first-divisor multivariate division, uses GROEBNER_RD_* */ }
fn gb_spoly(f: u32, g: u32) -> u32 @export { /* TODO: (L/LTf)*f - (L/LTg)*g, uses GROEBNER_SP_* */ }

// ---- closure + canonicalization + witness ----
fn gb_autoreduce(basis: *u32, basis_n: u32, out_basis: *u32, out_n: *u32) -> i32 @export { /* TODO: minimalize + inter-reduce + monic + sort, uses GROEBNER_AR_* */ }
fn gb_buchberger(generators: *u32, gen_n: u32, out_basis: *u32, out_n: *u32) -> i32 @export { /* TODO: FIFO pair queue, Criterion 1, overflow->E_FULL, finalize via gb_autoreduce */ }
fn gb_basis_digest(basis: *u32, basis_n: u32, out32: *u8) -> i32 @export { /* TODO: deterministic serialize into GROEBNER_DG_BUF + FNV-1a mix, *u8 byte stores (Trap 5) */ }
```
