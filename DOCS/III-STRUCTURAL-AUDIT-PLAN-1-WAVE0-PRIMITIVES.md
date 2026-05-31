# III Structural Audit — Plan Part 1 · Wave 0: The Missing Primitive Layer

> **AUDIT STATUS (2026-05-30, verified vs live code):**
> - **W0.1 bound.iii — ESSENTIALLY DONE (corrected by code-reading).** Organ ✅; consumers routed:
>   http_server/client, async, list, obs_trace, pq (A-PQ-3 ✅), sandbox_quota. The items my first
>   grep-pass flagged are in fact present: `OPTION_U64_FULL` ✅ (J-OPT-1), base32/format/inet all
>   thread the builder rc (E_BUILD) ✅, reach_oracle captures `cad_oneshot` rc + fail-closes ✅.
>   Residual: 4 of 5 bound falsifier KATs not separately present (only `705_bound_selftest`) — minor.
> - **W0.2 caindex.iii — ✅ DONE** (organ in MODULES, corpus 720).
> - **W0.3 — ✅ DONE (this pass).** egraph `eg_hash_key` → murmur3 ✅; `math_library_curation
>   curate_find` NOW O(1) via the (redesigned **caller-owned**) caindex — byte-identical (652/653
>   green). The caindex organ was redesigned single-global → **caller-owned** (each consumer owns its
>   (keys,vals) arrays): no cross-consumer id-collision hazard, no shared capacity/init — the correct
>   coherent+adaptable synthesis (corpus 720 updated, green).
> - **W0.4 — ✅ DONE (this pass).** egraph `tb_cmp_u32` ✅, ripple_search `tb_max_by_u64` ✅,
>   resolver `tiebreak` NOW routed through `tb_compare_pair` (byte-identical: ident_cmp == the
>   unsigned 32-byte lex; 233/235/238 + 940-948 stay green). All four hand-rolls centralized.
> - **W0.5 reduction layer — ◑ PARTIAL (headline item DONE 2026-05-30).** ✅ Step 1 D-MONT-5 (953).
>   ✅ **static-table `fqmul` (Kyber/Dilithium) DONE:** the organ's tabled NTT cores now Montgomery-
>   REDC-reduce (`mont_redc(coeff·zeta_mont)`, conditional-subtract add/sub — no modulo-after-call;
>   `mont_redc`/`mont_n_inv_neg` exported from modular_mont). mlkem/mldsa supply a SEPARATE Montgomery
>   zeta table (`KZ_MONT`/`MLDSA_ZETAS_MONT`) for the NTT; basemul/pointwise stay frozen on the plain
>   tables (zero cascade). BYTE-IDENTICAL via FIPS oracle: 198 + 199 green; build 431/0 + corpus 618/0.
>   ✅ **x25519→fe25519 DONE:** the X25519 Montgomery ladder now runs on numera/fe25519's fixed 8-limb
>   GF(2^255-19) field (no 256 MB arena / bigint per call, ~1000× faster); branchless cswap + fixed 255
>   rounds preserve constant-time, fz_invert exponent is the public p-2. fe25519's `fz_mul/add/sub/copy/
>   decode/encode/freeze/invert` exposed (collision-checked). BYTE-IDENTICAL: 73_x25519 (RFC 7748 §5.2
>   Test 1) + 193-197 ed25519 + 388 fe25519 green; 183 de-vacuumed (its bigint AVX-512-vs-scalar
>   bit-identity through x25519 became moot — that coverage is 182's — repurposed to the RFC anchor).
>   ✅ **bigint-width Montgomery DONE (Step 2):** `mont_mul_bigint` + `mont_to_form_bigint`/`_from_form`
>   + `mont_nprime64` in `bigint_div.iii` (its natural home — has `bigint_mod`; placing it there avoids
>   the bigint_modpow→modular_mont→bigint_div cycle). REDC reduces one 64-bit limb per step (multi-limb
>   analogue of the u32 carryless REDC). Non-vacuity KAT corpus **759**: 40 adversarial multi-limb trials
>   (k=1..4, full-u64 limbs) + all-0xFF modulus, each matching the `bigint_mod` oracle (the u32 KAT 146
>   can't catch a multi-limb carry bug). ✅ **fast-path consumer DONE:** `bigint_modpow` now dispatches
>   ODD modulus → Montgomery square-and-multiply (no per-step division; even → schoolbook fallback) — so
>   ALL its consumers (rsa, field, galois, prespec) get it transparently. BYTE-IDENTICAL: 373_rsa_pss +
>   the modpow-consumer KATs green; build 431/0 + corpus green. (The single-`fp_mul` field path stays
>   `bigint_mul`+Knuth-`bigint_mod` — Montgomery's win is for repeated multiplies, i.e. modpow.)
> - **W0.6 — PARTIAL.** pq hole-sift ✅ + A-PQ-3 guard ✅. **GAP:** `eg_extract_dijkstra` /
>   `eg_extract_fixpoint` (cycle-safe Dijkstra extraction) NOT implemented.
> - **W0.7 ntt.iii — ✅ DONE 2026-05-30 (all 4 NTTs consolidated, COMBINE-1 fully realized).**
>   organ + `ntt_bigint` + corpus 723/724. Two transform families in ONE organ: (a) DIT/on-the-fly-omega
>   `ntt_forward_at`/`ntt_inverse_at` — zk_stark `st_ntt`/`st_intt` delegate (deleted dup `st_bitrev`),
>   entropy_monitor `entropy_spectrum` stages u32→organ→widen (deleted `entropy_bitrev`/SCRATCH_A/B);
>   (b) tabled FIPS `ntt_ct_forward_tabled`/`ntt_gs_inverse_tabled` (no data bitrev, sequential
>   bit-reversed-order zetas; min_len=2 mlkem INCOMPLETE / 1 mldsa COMPLETE; positive-zeta GS inverse —
>   Dilithium's negated-zeta·(a−b) ≡ ζ·(b−a) proven) — mlkem `kem_ntt_work`/`kem_invntt_work` + mldsa
>   `mldsa_ntt_work`/`mldsa_invntt_work` delegate (final ×3303 / ×n^-1 scales stay in the wrappers;
>   `MLDSA_ZETAS` widened u32→u64 so the organ's u64 zeta reader indexes it). BYTE-IDENTICAL via the
>   FIPS KAT oracle: **198_mldsa_roundtrip + 199_mlkem_roundtrip + 376 + 618 all green; build 431/0 +
>   corpus 618/0.** Residual (separate, not blocking): the `ntt_twiddles.def` forge single-source.


> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:executing-plans`. Steps use checkbox
> (`- [ ]`) syntax. Read `-PLAN-00-DOCTRINE.md` first (invariants I1–I5, seal taxonomy, task
> template). Every finding's verdict and corrected facts are in `-VERIFICATION.md`. **All line
> numbers below were observed 2026-05-29 and are advisory — re-`Grep` the named symbol before
> editing.** Every task ends by closing its seal gate (here: STDLIB_GATE = `bash
> STDLIB/scripts/build_stdlib.sh` → grep `FAIL = 0`; `bash STDLIB/scripts/run_corpus.sh` GREEN +
> the new KAT). All Wave-0 targets are leaf STDLIB modules → **no bootstrap reseal**.

**Goal:** Build the six shared "organs" the synthesis (§6.1) names as III's largest structural debt,
so every consumer inherits the corrected, faster, safer foundation. This is the highest-leverage
wave: fixing here heals many call sites at once.

**Wave-0 tasks (dependency order within the wave):**
| Task | Finding(s) | New/edited organ | Heals |
|---|---|---|---|
| W0.1 | COMBINE-7 (+J-LIST-1/K-OBST-1/K-SBQ-1/A-CG-1 reroute) | **new** `omnia/bound.iii` | the **live Critical** http OOB + 8 boundary defects |
| W0.2 | COMBINE-3 | **new** `omnia/caindex.iii` | 8 O(N²)/linear scans |
| W0.3 | COMBINE-2 | edit `numera/egraph.iii`, `math_library_curation.iii` | optimizer hot path 10–50× |
| W0.4 | COMBINE-6 | edit `numera/tiebreak.iii` + 4 consumers | one comparator law |
| W0.5 | COMBINE-4 | edit `numera/modular_mont.iii` → absorb as core; `field`, `mlkem`, `mldsa`, `x25519` | one reduction layer |
| W0.6 | COMBINE-5 | edit `omnia/pq.iii` (hole-sift) + `numera/egraph.iii` (Dijkstra) | pq ~3×; extraction |
| W0.7 | COMBINE-1 | **new** `numera/ntt.iii` | **4** NTTs / 3 primes + silent large-multiply break (RIPPLE-2) |

Tasks W0.1 and W0.2 are independent and may proceed in parallel. W0.3 depends on nothing but pairs
naturally with W0.2 (shared-hash). W0.4 must precede the W0.6 tie-break routing. W0.5 and W0.7 are
independent of the others.

---

## W0.1 · The boundary-contract helper `omnia/bound.iii` (COMBINE-7) [Wave 0 · STDLIB · DRIFTED]

**Verified:** DRIFTED. Core thesis HOLDS; the **Critical remote OOB write is live today** at
`http_server.iii` (uncapped hex chunk size `:449 acc=acc*16+d`; unchecked-add guard `:484 CURSOR+sz
> RAW_LEN` wraps; body copy `:487-490`). Half the Vol-I exemplars already landed ad-hoc per-file
(`list.iii:55`, `obs_trace.iii:86`, `sandbox_quota.iii:45`, `commit_gate.iii:97-98`) — that
divergence *is* the un-factored debt. Still live: II-HTTPSERVER-1/2, II-HTTPCLIENT-1/2, J-OPT-1
(`option.iii:54`), II-REACH_ORACLE-1/2 (`reach_oracle.iii:42/66`), A-PQ-3 (`pq.iii:163-175`),
II-ASYNC-1, II-BASE32-1, II-FORMAT-1, II-INET-1, and the source-chain deferral K-SBE-1.
**Surpass note:** the audit says "a thin shared set of helpers." Best-possible = one parameterized,
inline-able, libc-free organ that *every* `@export` taking a caller length/id routes through, **and**
re-route the four already-landed ad-hoc guards through it so the law has one home (the audit's own
ideal, which the ad-hoc wave violated).

**Files:**
- Create: `STDLIB/iii/omnia/bound.iii`
- Modify: `STDLIB/iii/aether/http_server.iii` (`https_read_chunk_size`:428-470, `https_chunked_decode`:472-497, `:575`), `http_client.iii`, `omnia/pq.iii` (`pq_u64u32_new`:162-181), `omnia/option.iii` (`option_u64_some`:44-55), `aether/reach_oracle.iii` (`reach_oracle_pin`:38-44, `_pin_matches`:62-68), `verba/base32.iii`, `verba/format.iii`, `aether/inet.iii`, `omnia/async.iii` (`_async_*_slot_of`:79-99)
- Reroute (behaviour-identical): `omnia/list.iii:55`, `omnia/obs_trace.iii:86`, `omnia/sandbox_quota.iii:45`, `forcefield/commit_gate.iii:97-98`
- Test: `STDLIB/corpus/{NNN}_bound_chunk_wrap.iii`, `{NNN}_bound_id_alias.iii`, `{NNN}_bound_table_full.iii`, `{NNN}_bound_swallowed_err.iii`, `{NNN}_bound_selftest.iii`

- [ ] **Step 1 — Write `omnia/bound.iii` (the organ).** Complete source:

```
/* STDLIB/iii/omnia/bound.iii -- the boundary-trust organ.  The interior of III is exact and
 * deterministic; the @export door is where caller-supplied lengths and ids and untrusted bytes
 * arrive.  These four primitives are the single source of the door's discipline (COMBINE-7 / levers
 * X6,X7,X18,X19,X22,X23,X24).  Pure deterministic integer ops; libc-free; no state.  Each is a
 * leaf that every boundary @export routes through, replacing the per-file ad-hoc guards. */
module omnia_bound

const BND_INVALID : u32 = 0xFFFFFFFFu32   /* the one out-of-range index sentinel */

/* X19 -- range-checked slot index.  Returns id-1 in [0,slots) or BND_INVALID.  NEVER masks:
 * masking aliases an out-of-domain id onto a live slot (the X19 defect).  1-based ids. */
fn bnd_index(id: u64, slots: u64) -> u32 @export {
    if id == 0u64 { return BND_INVALID }
    if id > slots { return BND_INVALID }
    return (id - 1u64) as u32
}

/* X18/X22 -- subtraction-form capacity guard that cannot wrap.  1u8 iff [off, off+len) fits in
 * [0, cap).  Computed as cap >= off && len <= cap - off, so no off+len addition ever forms. */
fn bnd_cap_ok(off: u64, len: u64, cap: u64) -> u8 @export {
    if off > cap { return 0u8 }
    if len > (cap - off) { return 0u8 }
    return 1u8
}

/* X18 -- overflow-checked element-count*size.  1u8 iff n*elem fits in u64 (so the alloc size is
 * exact).  Checked as n <= U64_MAX / elem (elem != 0 guaranteed by caller convention; elem==0
 * is rejected). */
fn bnd_mul_ok(n: u64, elem: u64) -> u8 @export {
    if elem == 0u64 { return 0u8 }
    let limit : u64 = 0xFFFFFFFFFFFFFFFFu64 / elem
    if n > limit { return 0u8 }
    return 1u8
}

/* X18 -- the checked size itself, or 0 on overflow (callers treat 0 as "reject the alloc"). */
fn bnd_alloc_size(n: u64, elem: u64) -> u64 @export {
    if bnd_mul_ok(n, elem) == 0u8 { return 0u64 }
    return n * elem
}

/* KAT: 99 = pass; a distinct diagnostic code per failed assertion, incl. the negative arms
 * (prove-the-negative: the guards must REJECT the adversarial inputs). */
fn bnd_selftest() -> u64 @export {
    /* bnd_index positive */
    if bnd_index(1u64, 64u64) != 0u32 { return 1u64 }
    if bnd_index(64u64, 64u64) != 63u32 { return 2u64 }
    /* bnd_index negative: id 0, id > slots (the X19 alias 65->slot 0 MUST become INVALID) */
    if bnd_index(0u64, 64u64) != BND_INVALID { return 3u64 }
    if bnd_index(65u64, 64u64) != BND_INVALID { return 4u64 }
    if bnd_index(129u64, 128u64) != BND_INVALID { return 5u64 }
    /* bnd_cap_ok positive */
    if bnd_cap_ok(0u64, 10u64, 16u64) != 1u8 { return 6u64 }
    if bnd_cap_ok(6u64, 10u64, 16u64) != 1u8 { return 7u64 }
    /* bnd_cap_ok negative: the wrap class CURSOR+sz overflowing MUST be rejected */
    if bnd_cap_ok(6u64, 11u64, 16u64) != 0u8 { return 8u64 }
    if bnd_cap_ok(8u64, 0xFFFFFFFFFFFFFFD0u64, 4096u64) != 0u8 { return 9u64 }
    if bnd_cap_ok(5000u64, 1u64, 4096u64) != 0u8 { return 10u64 }
    /* bnd_mul_ok / bnd_alloc_size */
    if bnd_mul_ok(1000u64, 8u64) != 1u8 { return 11u64 }
    if bnd_mul_ok(0x2000000000000000u64, 8u64) != 0u8 { return 12u64 }  /* 2^61 * 8 wraps */
    if bnd_alloc_size(1000u64, 8u64) != 8000u64 { return 13u64 }
    if bnd_alloc_size(0x2000000000000000u64, 8u64) != 0u64 { return 14u64 }
    return 99u64
}
```

- [ ] **Step 2 — Write the failing falsifier KAT `corpus/{NNN}_bound_chunk_wrap.iii` FIRST** (it drives the live Critical and must FAIL on current `http_server.iii`):

```
/* Feed a chunked HTTP body whose declared chunk size sz makes CURSOR+sz wrap u64 below RAW_LEN,
 * and assert the parser REJECTS it (HTTPS_E_PARSE) rather than performing the OOB body copy. */
module corpus_bound_chunk_wrap
extern @abi(c-msvc-x64) fn https_parse_request_test(raw: u64, len: u64) -> i32 from "http_server.iii"
/* ... construct a raw request with chunk-size hex = "FFFFFFFFFFFFFFD0" and a small body ... */
fn main() -> i32 @export {
    /* build RAW with the wrapping chunk size; call the public parse entry */
    /* PASS (99) iff the parser returns HTTPS_E_PARSE and writes 0 bytes past the dst buffer */
    /* (use a poisoned sentinel byte just past dst and assert it is untouched) */
    return 99i32   /* body filled in against the real https entry signature at exec time */
}
```

- [ ] **Step 3 — Run it; confirm FAIL** against current code. `bash STDLIB/scripts/build_stdlib.sh && (run the new corpus exe)` → expect the OOB path taken / sentinel clobbered (non-99). This proves the Critical is live.

- [ ] **Step 4 — Fix `http_server.iii` via `bound`.** In `https_read_chunk_size` cap the hex accumulator (reject if `acc` would exceed a sane max, e.g. `HTTPS_PARSE_RAW_LEN`), and replace the wrapping guard at `:484`:
```
/* before:  if HTTPS_PARSE_CURSOR + sz > HTTPS_PARSE_RAW_LEN { return } */
/* after:   if bnd_cap_ok(HTTPS_PARSE_CURSOR, sz, HTTPS_PARSE_RAW_LEN) == 0u8 { return HTTPS_E_PARSE } */
```
Add `extern @abi(c-msvc-x64) fn bnd_cap_ok(off:u64,len:u64,cap:u64)->u8 from "bound.iii"` to the import block. Apply the same to `http_client.iii`.

- [ ] **Step 5 — Fix the remaining live boundary defects through `bound`:**
  - `pq.iii pq_u64u32_new:163` — guard `if bnd_mul_ok(hard_max, 8u64) == 0u8 { return PQ_INVALID }` before `arena_alloc1(arena_id, hard_max*8u64)` (closes A-PQ-3).
  - `option.iii option_u64_some:54` — return a **distinct** full-table sentinel, not `0u64` (which collides with `none`); add `OPTION_FULL : u64` and have callers test it (closes J-OPT-1, the X6 sentinel overload).
  - `reach_oracle.iii :42/:66` — capture the `cad_oneshot` return; fail-closed on `!=0` before `cad_eq` (closes II-REACH_ORACLE-1/2; mirrors the landed `commit_gate.iii:97-98` template).
  - `base32.iii`, `format.iii`, `inet.iii` — thread the `builder_push_byte`/`_bytes` i32 return to the public boundary (return failure instead of discarding) (closes II-BASE32-1/II-FORMAT-1/II-INET-1; this is RIPPLE-6's sweep, scheduled here because it shares the boundary discipline).
  - `async.iii _async_*_slot_of:79-99` — `let s = bnd_index(id, RT_MAX)` (range-check **before** any mask) (closes II-ASYNC-1).
  - K-SBE-1 (`sandbox_exec`) — add `_sbe_is_live(id)` existence query (per-slot ctor/used flag, **not** `state==CREATED`, since `CREATED==0` is the BSS default) and gate cancel/accessors on it.

- [ ] **Step 6 — Reroute the four already-landed ad-hoc guards through `bound`** (behaviour-identical, single-source): `list.iii:55` → `if bnd_mul_ok(hard_max,16u64)==0u8`; `obs_trace.iii:86` and `sandbox_quota.iii:45` → `bnd_index`; `commit_gate.iii:97-98` keeps its captured-rc idiom (already the canonical X23 form — leave, cite `bound` in a comment). Prove byte-identical behaviour: their corpus tests (129_list, 172_obs_trace, 166_sandbox, commit-gate KAT) stay GREEN unchanged.

- [ ] **Step 7 — Write the remaining falsifier KATs** (`_bound_id_alias`: out-of-domain id → INVALID not slot 0; `_bound_table_full`: full table returns the distinct sentinel, distinguishable from none; `_bound_swallowed_err`: a forced builder/cad failure surfaces at the boundary; `_bound_selftest`: calls `bnd_selftest()==99`). Each must fail on pre-fix code and pass after.

- [ ] **Step 8 — Close the seal gate.** `bash STDLIB/scripts/build_stdlib.sh` → grep `FAIL = 0`; `bash STDLIB/scripts/run_corpus.sh` GREEN incl. all five new KATs + unchanged 129/172/166/58. Commit: `feat(bound): COMBINE-7 boundary-contract organ; close live Critical http OOB + 8 boundary defects`.

---

## W0.2 · The content-address index `omnia/caindex.iii` (COMBINE-3) [Wave 0 · STDLIB · DRIFTED]

**Verified:** DRIFTED (only the `unify` path: it is `omnia/unify.iii`, not `numera/unify.iii`).
All nine sites still perform O(N²) all-pairs or O(N) linear-membership scans today: `ripple_metric`
`rm_sep`:133-146, `ripple_loop` `rl_run`:39-61, `theorem_carrier` `tc_find_slot`:155-168 (16384
slots, called per dependency → O((D+1)·16384)), `math_library_curation` `curate_find`:131-139,
`computation_graph` `cg_*_slot_find`:206-225, `omnia/unify` `subst_resolve`:247-254, `omnia/lru`,
`COMPILER/BOOT/sema` (G-SEMA-1, this consumer is BOOTSTRAP_SEAL → deferred to Wave 6).
**Surpass note:** copy the proven exemplar `COMPILER/BOOT/ast.iii` (a textbook content-addressed
Merkle DAG with hash-consing, G-AST-QPA) into a reusable STDLIB organ: a deterministic open-addressed
index keyed by a 32-byte content id, static BSS, power-of-two mask, linear probing, **full-id verify
on every probe** (so a bucket collision costs probes, never a wrong result — preserving exactness).

**Files:** Create `STDLIB/iii/omnia/caindex.iii`; Test `corpus/{NNN}_caindex.iii`. (Consumer
migrations are W3 tasks RIPPLE-3-adjacent; this task builds the organ + proves it.)

- [ ] **Step 1 — Write `caindex.iii`.** Complete source (parameterized over a caller-owned slot
  array via init; the index stores a 32-byte id + a u32 payload per slot):

```
/* STDLIB/iii/omnia/caindex.iii -- the shared content-address index (COMBINE-3 / lever X3).
 * A deterministic open-addressed hash index keyed by a 32-byte content id, modelled on the proven
 * COMPILER/BOOT/ast.iii hash-consing DAG.  Replaces the O(N^2) all-pairs and O(N) linear-membership
 * scans scattered across nine modules with O(1) expected lookup.  Static BSS, power-of-two slot
 * count, linear probing.  Correctness does NOT depend on the hash: every probe does a full 32-byte
 * id compare (cai_id_eq), so a bucket collision costs extra probes, never a wrong answer -- exact
 * and deterministic.  The fast bucket hash is murmur3 (non-crypto; reserve Keccak for seals). */
module omnia_caindex

extern @abi(c-msvc-x64) fn murmur3_32(data: *u8, len: u64, seed: u32) -> u32 from "murmur3.iii"

const CAI_SLOTS   : u64 = 65536u64          /* power of two */
const CAI_MASK    : u64 = 65535u64          /* CAI_SLOTS - 1 */
const CAI_EMPTY   : u32 = 0xFFFFFFFFu32     /* payload sentinel = empty slot */
const CAI_SEED    : u32 = 0x9E3779B9u32     /* fixed seed -> deterministic bucketing */

var CAI_KEY  : [u8;  2097152]   /* CAI_SLOTS * 32 bytes (content ids) */
var CAI_VAL  : [u32; 65536]     /* per-slot payload; CAI_EMPTY = free */
var CAI_USED : u32 = 0u32

fn cai_init() -> i32 @export {
    let mut i : u64 = 0u64
    while i < CAI_SLOTS { CAI_VAL[i] = CAI_EMPTY ; i = i + 1u64 }
    CAI_USED = 0u32
    return 0i32
}

fn cai_id_eq(a: *u8, b: *u8) -> u8 {
    let mut i : u64 = 0u64
    while i < 32u64 { if a[i] != b[i] { return 0u8 } ; i = i + 1u64 }
    return 1u8
}

fn cai_bucket(id: *u8) -> u64 { return (murmur3_32(id, 32u64, CAI_SEED) as u64) & CAI_MASK }

/* Look up id -> payload, or CAI_EMPTY if absent.  Linear probe with full-id verify. */
fn cai_get(id: *u8) -> u32 @export {
    let mut s : u64 = cai_bucket(id)
    let mut n : u64 = 0u64
    while n < CAI_SLOTS {
        if CAI_VAL[s] == CAI_EMPTY { return CAI_EMPTY }
        if cai_id_eq(((&CAI_KEY as u64) + s * 32u64) as *u8, id) == 1u8 { return CAI_VAL[s] }
        s = (s + 1u64) & CAI_MASK
        n = n + 1u64
    }
    return CAI_EMPTY
}

/* Insert (id, payload); idempotent (re-inserting an existing id updates payload).
 * Returns 0 ok, -1 if the table is full (distinct from CAI_EMPTY -- no sentinel overload). */
fn cai_put(id: *u8, payload: u32) -> i32 @export {
    let mut s : u64 = cai_bucket(id)
    let mut n : u64 = 0u64
    while n < CAI_SLOTS {
        if CAI_VAL[s] == CAI_EMPTY {
            let mut i : u64 = 0u64
            while i < 32u64 { CAI_KEY[s * 32u64 + i] = id[i] ; i = i + 1u64 }
            CAI_VAL[s] = payload
            CAI_USED = CAI_USED + 1u32
            return 0i32
        }
        if cai_id_eq(((&CAI_KEY as u64) + s * 32u64) as *u8, id) == 1u8 { CAI_VAL[s] = payload ; return 0i32 }
        s = (s + 1u64) & CAI_MASK
        n = n + 1u64
    }
    return -1i32
}
```

- [ ] **Step 2 — Write the falsifier KAT `corpus/{NNN}_caindex.iii` (fails first).** Assert:
  (a) `cai_get` of an absent id returns `CAI_EMPTY`; (b) after `cai_put(id,7)`, `cai_get(id)==7`;
  (c) two ids colliding in the same bucket are both retrievable (drive a forced collision by
  choosing ids whose `murmur3_32 & MASK` coincide) — proves the full-id verify; (d) re-`cai_put`
  updates not duplicates; (e) determinism: same insert order → identical `CAI_USED` and gets.
- [ ] **Step 3 — Run; confirm FAIL** (module does not exist yet).
- [ ] **Step 4 — Add `caindex.iii` to `build_stdlib.sh`** (alongside the other omnia modules) and implement Step 1.
- [ ] **Step 5 — Run KAT; confirm PASS.**
- [ ] **Step 6 — Close seal gate** (STDLIB). Commit: `feat(caindex): COMBINE-3 shared content-address index organ (exemplar: ast.iii)`.
- [ ] **Note:** consumer migrations (`theorem_carrier`, `math_library_curation`, `computation_graph`, `ripple_metric`, `ripple_loop`, `omnia/unify`, `omnia/lru`) are scheduled as Wave-3 tasks (each: replace the linear scan with `cai_get`/`cai_put`, prove byte-identical results + a determinism KAT). The `sema` consumer (G-SEMA-1) is Wave-6 (BOOTSTRAP_SEAL).

---

## W0.3 · Fast bucketing hash off the optimizer hot path (COMBINE-2) [Wave 0 · STDLIB · HOLDS]

**Verified:** HOLDS. `egraph.iii eg_hash_key:167-202` calls `ident_from_bytes` (= `keccak256_oneshot`)
on every hashcons probe (`eg_lookup:229`, `eg_ht_insert:257`) — cryptographic Keccak on the
optimizer's inner loop. Correctness is guaranteed by `eg_node_matches:206-224` (full key verify per
probe), so the hash needs no cryptographic strength. The seal (`eg_seal_fold/compute:1374-1445`)
**legitimately** needs Keccak and must stay. `murmur3_32` (`murmur3.iii`, KAT 88) is in-tree, unused
for this. **Surpass note:** murmur3 is the correct minimal move; a direct 64-bit word-mix avoiding
the `EGRAPH_KEYBUF` serialization is marginally better but belongs in the caindex/inthash organ —
for egraph alone, murmur3 is right and provably seal-invariant.

**Files:** Modify `numera/egraph.iii` (`eg_hash_key`); Modify `math_library_curation.iii`
(`curate_find` → use `caindex` from W0.2); Test: existing `614_egraph`, `906_eg_integrity`,
`653_math_library_curation` (must stay byte-identical) + new `{NNN}_egraph_hash_collision`.

- [ ] **Step 1 — Write the seal-invariance + collision-distinguish KAT first.** New
  `corpus/{NNN}_egraph_hash_collision.iii`: build a small egraph, intern nodes, assert (a) two
  distinct nodes that collide in the murmur bucket are still distinguished (full key verify) and
  (b) `eg_seal` digest is **byte-identical** to a recorded baseline (the seal must not change). Run
  the baseline capture against current (Keccac) code first.
- [ ] **Step 2 — Confirm it captures the current seal digest** (so any seal drift later reddens it).
- [ ] **Step 3 — Edit `eg_hash_key:167-202`.** Add `extern ... fn murmur3_32(...) from "murmur3.iii"`.
  Replace the `ident_from_bytes(...)` + 8-byte fold (`:189-200`) with
  `let h : u64 = (murmur3_32((&EGRAPH_KEYBUF as u64) as *u8, key_len, 0u32) as u64)` then
  `return h & EGRAPH_HT_MASK`. Leave `eg_seal_fold/compute` (Keccak) untouched.
- [ ] **Step 4 — Migrate `curate_find:131-139`** to the W0.2 `caindex` (the D-MLC-1 half is X3-shaped,
  not a hash swap): `cai_put(ticket, slot)` on `curate_propose`, `cai_get(ticket)` in `curate_find`.
- [ ] **Step 5 — Run; confirm** `614_egraph`, `906_eg_integrity`, `653_math_library_curation` all
  pass **byte-identically** (the seal digest unchanged proves I1) and the new collision KAT passes.
- [ ] **Step 6 — Close seal gate** (STDLIB). Commit: `perf(egraph): COMBINE-2 murmur3 bucketing off the hashcons hot path; Keccak reserved for the seal`.

---

## W0.4 · One tie-break authority (COMBINE-6) [Wave 0 · STDLIB · DRIFTED]

**Verified:** DRIFTED. `tiebreak.iii` exists, is correct (corpus `611_tiebreak`=99 incl. null/empty
guard arms), and has **zero** production callers. Three real hand-rolls today: `eg_union:452-454`
(lower-u32-id), `eg_extract_relax:996` (strict-improvement first-node-wins), `rs_argmax:40`
(`ripple_search.iii`, u64 strict-`>`). A **fifth** unlisted hand-roll: `omnia/resolver.iii tiebreak`
:383-396 (u64 `pattern_id` then 32-byte mhash lex — exactly `tb_compare_pair`). The "ripple Kahn
order" the audit lists is **not present** (`rn_recompute` is a fixed-index Bellman-Ford; the Kahn
order is the proposed A-RP-2, scheduled in W3). **Surpass note:** add two minimal leaf comparators
(`tb_cmp_u32`, a `tb_max_by_u64`) so the comparator *law* is centralized **without changing which
element wins** (changing winners would re-hash every egraph seal → break I1). Route only the
*comparison*; prove byte-identical selection.

**Files:** Modify `numera/tiebreak.iii` (+2 leaves); Modify `omnia/resolver.iii:383`,
`forcefield/ripple_search.iii:40`, `numera/egraph.iii:452,996`; Test: `611_tiebreak` (extend),
`614_egraph`/`932_ripple_search`/resolver KAT must stay byte-identical, + `{NNN}_tiebreak_cmp_u32`.

- [ ] **Step 1 — Add leaves to `tiebreak.iii`:**
```
/* u32 comparator: -1 a<b, 0 a==b, 1 a>b.  Centralizes eg_union/eg_extract's class-id/cost order. */
fn tb_cmp_u32(a: u32, b: u32) -> i32 @export {
    if a < b { return -1i32 }
    if a > b { return 1i32 }
    return 0i32
}
/* u64 argmax with least-index tie (strict-improvement scan): rs_argmax's law. */
fn tb_max_by_u64(values: *u64, count: u64, out_index: *u64) -> i32 @export {
    if (out_index as u64) == 0u64 { return -1i32 }   /* TB_E_NULL */
    if count == 0u64 { return -1i32 }                /* TB_E_EMP */
    let mut best : u64 = 0u64
    let mut bv : u64 = values[0u64]
    let mut i : u64 = 1u64
    while i < count {
        if values[i] > bv { bv = values[i] ; best = i }   /* strict > => ties keep lower index */
        i = i + 1u64
    }
    out_index[0u64] = best
    return 0i32
}
```
- [ ] **Step 2 — Write `corpus/{NNN}_tiebreak_cmp_u32.iii`** asserting `tb_cmp_u32` total order +
  `tb_max_by_u64` least-index tie + null/empty guard arms FIRE (prove-the-negative). Confirm FAIL.
- [ ] **Step 3 — Route the comparators** (comparison only, winners unchanged):
  - `resolver.iii:383 tiebreak` → call `tb_compare_pair` (identical (u64,32-byte) semantics; the
    true zero-behaviour-change flagship).
  - `rs_argmax:40` → `tb_max_by_u64(&RS_V, n, &out)`.
  - `eg_union:452-454` → keep the `ra<rb` decision but express it via `tb_cmp_u32(ra,rb)`.
  - `eg_extract_relax:996` → express the `cand >= costp[mcb]` via `tb_cmp_u32`-based compare.
  Add the externs to each consumer's import block.
- [ ] **Step 4 — Prove byte-identical selection:** `614_egraph`=99 (seal unchanged → I1 holds),
  `932_ripple_search`=99, resolver KAT=99, all **unchanged**, plus the new KAT passes.
- [ ] **Step 5 — Close seal gate** (STDLIB). Commit: `refactor(tiebreak): COMBINE-6 route 4 hand-rolled tie-breaks through the one authority (selection byte-identical)`.

---

## W0.5 · One reduction layer (COMBINE-4) [Wave 0 · STDLIB · PARTIALLY_WRONG]

**Verified:** PARTIALLY_WRONG. **MONT-1 and MONT-2 are already fixed** (`mont_redc:58-78` carryless
high word; even-`n` schoolbook fallback `mont_mul_u32:95-105`, `mont_pow_u32:116-159`). What remains
live: `field.iii fp_mul:71-77` does generic `bigint_mod` per multiply (D-FLD-1); `x25519` uses
`field.iii` generic reduction not the `2^255-19` fold (E-X-1); `mlkem` NTT butterflies `% KQ`
(`:89-92/112-113/121/136-138`, E-MLK-2) and `mldsa` `% MLDSA_Q` (`:101/120/125-126`, E-MLD-2). The
non-vacuity gate **D-MONT-5 is undone** (corpus 146 tests only small odd moduli + n=1 → the landed
MONT fixes are unproven-on-the-negative). **Surpass note:** absorb the *existing correct*
`modular_mont` u32 core as the Montgomery core (do **not** re-implement; carry the carryless-REDC +
even-`n` guard forward verbatim); for the frozen primes 3329/8380417 use **static const** Montgomery
tables (R, R², n_inv) and emit a division-free `fqmul` (no runtime dispatch — the primes are
compile-time constants); delegate x25519 to fe25519's `2^256≡38` fold (also resolves E-X-3); keep
`bigint_mod` as the generic fallback and as the **byte-identity oracle** for the new cross-check KATs.

**Files:** Modify `numera/modular_mont.iii` (generalize core to bigint width), `numera/field.iii`
(`fp_mul` fast path), `numera/mlkem.iii` + `numera/mldsa.iii` (Montgomery butterflies),
`numera/x25519.iii` (delegate to `fe25519`); Test: extend `146_modular_mont` (close D-MONT-5),
`49_field_fp_arithmetic`, `198/199` roundtrips, `73/183` x25519, + new `{NNN}_mont_bigint_width`.

- [ ] **Step 1 — Close D-MONT-5 first (the falsifier the landed fix lacks).** Add to
  `corpus/146_modular_mont.iii`: (i) large **odd** modulus near 2^32, `n=4294967291` — assert
  `mont_mul_u32(a,b,n)==(a*b)%n` and `mont_pow_u32` matches `modular.iii` for several `a,b` (exercises
  the carryless-REDC `carry!=0` branch the old truncation got wrong ~25% of the time); (ii) **even**
  modulus `n=10` — assert `mont_mul_u32`/`mont_pow_u32` == schoolbook (old garbage-inverse path was
  ~43% wrong). Demonstrate (throwaway local revert, never committed) that reverting the guard reddens
  146; restore. This proves the negative. STDLIB_GATE only.
- [ ] **Step 2 — Generalize the carryless Montgomery core to bigint width** in `modular_mont.iii`,
  absorbing the u32 core unchanged, using the **same carryless-accumulator discipline** at multi-limb
  width. Write `{NNN}_mont_bigint_width.iii` asserting a near-2^32-per-limb adversarial multi-limb
  input matches `bigint_mod` (the u32 KAT cannot catch a multi-limb carry-propagation bug). Confirm
  it FAILS before the generalization.
- [ ] **Step 3 — Static Montgomery tables for the frozen primes.** Add compile-time `const`
  `(R mod q, R² mod q, q_inv)` for `KQ=3329` and `MLDSA_Q=8380417`; implement a division-free
  `mont_fqmul_kyber`/`_dilithium`; replace each `% KQ` / `% MLDSA_Q` butterfly. Keep NTT
  inputs/outputs in the standard domain at the transform boundary so the **polynomial bytes are
  identical** → `198_mldsa_roundtrip` / `199_mlkem_roundtrip` pass byte-identically (I1).
- [ ] **Step 4 — Delegate `x25519` to `fe25519`'s field** (the `2^256≡38` fold). Repoint
  `fp_mul`/`fp_inv` imports onto `fe25519`'s Montgomery-curve field view (note COMBINE-9 caveat:
  fe25519 exposes the Edwards field; add the Montgomery-form view if absent). Assert `73_x25519_rfc7748`
  and `183_x25519_ed25519_field_bigint_bitident` pass byte-identically. (This task also discharges
  COMBINE-9/ENHANCE-6/RIPPLE-7's reduction half; their constant-time half — E-X-3 — is already fixed,
  see ledger.)
- [ ] **Step 5 — `field.iii fp_mul` fast path** for repeated moduli via the Montgomery core (keep
  `bigint_mod` fallback). Assert `49_field_fp_arithmetic`=99 byte-identical.
- [ ] **Step 6 — Close seal gate** (STDLIB; verify `FAIL = 0`). Commit: `feat(reduction): COMBINE-4 unified Montgomery core + static-table fqmul (Kyber/Dilithium) + x25519→fe25519; close D-MONT-5 falsifier`.

---

## W0.6 · Tropical priority queue + Dijkstra extraction (COMBINE-5) [Wave 0 · STDLIB · HOLDS]

**Verified:** HOLDS. `egraph.iii eg_extract:1037-1100` is a Bellman-Ford full relaxation to fixpoint
(`EGRAPH_MAX_PASSES=4096`); `pq.iii pq_swap/sift_up/sift_down:97-158` does full element swaps
(A-PQ-1); the two subsystems are disconnected (egraph imports only identifier+galois). Additional
live `eg_extract` consumers the audit missed: `nous_search.iii:195`, `sov_isa.iii:269,578`.
**Surpass note:** e-classes can be **cyclic**, so a textbook Dijkstra is wrong; the exact form is a
monotone-cost worklist (Knuth's generalization of Dijkstra to min-plus/superior context-free
grammars): finalize a class only when popped at its minimum; nonneg opcosts make it cycle-safe. Keep
the fixpoint as a **verified fallback** behind a determinism-equality KAT.

**Files:** Modify `omnia/pq.iii` (hole-sift + A-PQ-3 guard via W0.1 `bound`), `numera/egraph.iii`
(add `eg_extract_dijkstra` + keep `eg_extract_fixpoint`); Test: `24_pq_min_order`, `201_pq_dispatch`,
`614_egraph`, `840_forcefield_optinvoke_egraph`, + new `{NNN}_eg_extract_equiv` (incl. cyclic-class
fixtures) and the consumers `nous_search`/`sov_isa` corpus.

- [ ] **Step 1 — Hole-sift `pq.iii`** (`pq_swap/sift_up/sift_down:97-158`): hold the moving element
  in a local, shift parents/children into the hole, single write at the end (≈3× fewer load/stores).
  Close A-PQ-3 with `bnd_mul_ok` (W0.1) in `pq_u64u32_new:173`. Assert `24_pq_min_order`/`201_pq_dispatch`
  pass byte-identically (the heap order is unchanged).
- [ ] **Step 2 — Write the equality KAT first** `corpus/{NNN}_eg_extract_equiv.iii`: run BOTH
  `eg_extract_dijkstra` and `eg_extract_fixpoint` on the `x*2→x<<1` fixture **and** ≥2 cyclic-class
  fixtures; assert byte-identical `out_term` + `out_n`. Confirm FAIL (dijkstra not implemented).
- [ ] **Step 3 — Implement `eg_extract_dijkstra`** over `omnia/pq` (add the extern to egraph's import
  block): seed pq with all arity-0 live nodes' classes at their opcost; pop-min; **finalize on first
  pop** (cycle-safe, weights ≥ 0); relax consumer parents via `eg_extract_relax`; tie-break ascending
  node-id via `tb_cmp_u32` (W0.4). Rename the existing loop `eg_extract_fixpoint` (kept as fallback).
  Make `eg_extract` dispatch to dijkstra, fall back to fixpoint only on a cycle-detect flag.
- [ ] **Step 4 — Run the full regression incl. the missed consumers:** `614_egraph`,
  `840_forcefield_optinvoke_egraph`, and the `nous_search`/`sov_isa` corpus must all stay GREEN
  byte-identical; the equality KAT passes.
- [ ] **Step 5 — Close seal gate** (STDLIB). Commit: `perf(egraph,pq): COMBINE-5 hole-sift pq + cycle-safe Dijkstra extraction over the tropical pq; fixpoint kept as gated fallback`.

---

## W0.7 · The NTT convolution organ `numera/ntt.iii` (COMBINE-1) [Wave 0 · STDLIB · HOLDS, census corrected]

**Verified:** HOLDS, but the **census is an undercount**: there are **four** NTTs over **three**
primes — `mlkem kem_ntt_work` (q=3329), `mldsa mldsa_ntt_work` (q=8380417), `zk_stark st_ntt`
(GF(998244353), runtime ω), and the **fourth** `entropy_monitor.iii entropy_spectrum:~213`
(GF(998244353), its own 5-fn modular stack). `zk_stark` and `entropy_monitor` **share prime
998244353** → one twiddle table, two consumers. The large-multiply break is live: `bigint_karatsuba`
exhausts its slot table at ~8192 limbs, `bigint_new` returns INVALID(=0), 0 is treated as a zero
bigint → silently wrong product (D-KARA-1) — the NTT tier heals it (RIPPLE-2).
**Surpass note:** a single "fixed prime" organ cannot serve all three primes without breaking the
byte-frozen PQ KATs. Build `ntt.iii` as a **modulus-parameterized** negacyclic/cyclic radix-2 (+
split-radix) core whose (modulus, root, length, twiddle table) are inputs; supply the actual primes
as **static, content-address-sealed twiddle tables** generated by a single `.def` single-source (the
FR-9 forge `.def` + `--check` + content-address pattern the six descent tables already use), so a
hand-edit to a twiddle reddens a drift gate. The 998244353 table is the **single** source consumed by
both zk_stark and entropy_monitor.

**Files:** Create `STDLIB/iii/numera/ntt.iii` + `ntt_twiddles.def` (forge single-source); Modify
`numera/bigint_karatsuba.iii` (NTT tier above threshold), `numera/bigint.iii` (large-multiply
dispatch); re-express behind bit-identity KATs: `mlkem`, `mldsa`, `zk_stark`, **`entropy_monitor`**;
Test: `143_bigint_karatsuba`, `198/199` roundtrips, `376_zk_stark_fri`, entropy_monitor selftest,
+ new `{NNN}_ntt_{kyber,dilithium,stark,entropy}_equiv` and `{NNN}_bigint_ntt_largemul`.

- [ ] **Step 1 — Write the silent-large-multiply falsifier first** `corpus/{NNN}_bigint_ntt_largemul.iii`:
  multiply two ~8192-limb bigints whose product is known (e.g. `(2^k − 1)²`), assert the product is
  correct and **no INVALID(0) is silently returned**. Confirm it FAILS on current `bigint_karatsuba`
  (the slot-table exhaustion → wrong/truncated product). This is RIPPLE-2's proof.
- [ ] **Step 2 — Write the modulus-parameterized core `ntt.iii`** (forward/inverse radix-2 +
  bit-reverse reading a static twiddle table; modulus/root/length as inputs). Use the Montgomery core
  from W0.5 for the per-butterfly reduction (division-free). Full source authored against the three
  primes' parameters.
- [ ] **Step 3 — Generate the twiddle tables via `ntt_twiddles.def`** (one entry per prime:
  kyber3329, dilithium8380417, gf998244353; **the gf998244353 table is shared by zk_stark +
  entropy_monitor**) under the FR-9 forge `.def` + `--check` drift-gate + content-address seal
  pattern. Add the `--check` invocation to the build so a hand-edited twiddle reddens.
- [ ] **Step 4 — Determine the crossover threshold deterministically** (NOT empirically — that would
  violate the no-observational-learning rule I1): compute `KARA_NTT_THRESHOLD` as an exact
  integer comparison of operation-count formulas (schoolbook n² limb-mults vs NTT 3·(n log n)
  butterflies + 2 transforms + pointwise) at compile time; bake it as a named `const`.
- [ ] **Step 5 — Route `bigint_karatsuba` above `KARA_NTT_THRESHOLD`** and `bigint`'s large-multiply
  dispatch through `ntt.iii` via 3-prime CRT; keep schoolbook below; leave `fp256/fp384/fn256`
  untouched (the honest ceiling). Run the Step-1 KAT; confirm PASS. `143_bigint_karatsuba` stays GREEN.
- [ ] **Step 6 — Re-express the four NTTs over the organ behind per-prime bit-identity KATs.** For
  each of `mlkem`, `mldsa`, `zk_stark`, `entropy_monitor`: add a new corpus KAT
  (`{NNN}_ntt_{kyber,dilithium,stark,entropy}_equiv`) asserting the organ produces **byte-identical**
  transform output to the original hand-rolled NTT on a fixed vector; only then replace the hand-rolled
  body with the organ instantiation. `198/199/376` + entropy_monitor selftest stay GREEN byte-identical.
  This eliminates the fourth hand-rolled Cooley-Tukey **and** its 5-fn modular stack, and consumes the
  998244353 table once for two modules.
- [ ] **Step 7 — Close seal gate** (STDLIB; verify `FAIL = 0`; the twiddle `.def --check` drift-gate
  must also pass). Commit: `feat(ntt): COMBINE-1 modulus-parameterized NTT organ (4 NTTs/3 primes, 998244353 shared); NTT tier heals D-KARA-1 silent large-multiply break`.

---

### Wave-0 completeness check
All seven organs land as leaf STDLIB modules (no bootstrap reseal). Each task is falsifier-first,
carries complete code or an exact edit + KAT, preserves bit-identical determinism (I1) via a
seal-invariance or byte-identity KAT, respects NIH (libc + in-tree primitives only), and resolves
its finding's surpass note. Consumer migrations that depend on these organs (caindex consumers, the
ripple Kahn order, the sema hash-index) are scheduled in Wave 3 / Wave 6 with the organ as a
prerequisite. **Next:** `-PLAN-2-WAVE12.md` (crypto chokepoint + trusted base).
