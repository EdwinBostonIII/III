# 44 aether/triple_check.iii — Implementation Spec

## Verdict
**PARTIAL** — the gospel candidate body is structurally near-complete and algorithmically sound (correct unanimity / 2-of-3 majority / 3-way-fatal voting, correct disagreement witnessing), but it is **not buildable as written**: it (a) declares a **fabricated extern `tc_invoke4` from "BOOT/resolver_unit.s"** for indirect dispatch that does not exist and is unnecessary — III has native fn-ptr-via-`u64`-local indirect calls; (b) commits **four Trap-7 violations** (function-local `var [u8;N]` arrays in `tc_publish_disagreement`); (c) uses the **wrong const PREFIX** (`TC_` instead of the assigned `TRIPLE_`); (d) has **Trap-4 unmasked `slot as u64`** pointer arithmetic; and (e) uses non-house `&ARR[expr]` element-address and `*out_result =` deref-store forms. The voting logic and witness routing are correct and retained verbatim. All gaps are closed below.

## Purpose
`aether::triple_check` provides **algebraic consensus on critical operations**: for any operation whose result the substrate must be provably correct about (signing a federation message, evaluating a constitutional predicate, computing a boot-path crypto primitive), three **independently authored** implementations of the same logical function are registered under one operation id and invoked on identical inputs. The runtime compares the three `u64` results and proceeds **only on unanimity** (`TRIPLE_OK`); exactly-two-agree yields the majority value plus a `disagree_2_1` witness fragment so the federation can correlate the dissenting implementation across nodes; three-way disagreement is a **hard fatal** (`TRIPLE_DISAGREE_FATAL`) with a `disagree_fatal` witness and escalation to the immune-scrub / tissue-regen pillars. There is no voting heuristic and no "best of" — agreement is exact `u64` bit-equality (M2/M4/M15). **Hexad: kind_witness + kind_repair. Ring: R-1. K: 1.00.**

## Public API
```iii
fn tc_init() -> i32 @export
fn tc_register(op_id: *u8, impls: *u64) -> i32 @export
fn tc_execute(op_id: *u8, args: *u64, out_result: *u64) -> i32 @export
fn tc_disagreement_count() -> u32 @export
```
Return-status convention:
- `tc_init` → `TRIPLE_OK` (0) always (W12).
- `tc_register` → `TRIPLE_OK` on success, `TRIPLE_E_FULL` (-3) if the 256-slot table is full (W9 negative-i32 error). `impls` points to a caller-owned `[u64; 3]` = `{fn_a, fn_b, fn_c}`, each taken via `(&fn) as u64` (see Trap Exposure / Gap §G2). W2-aggregate: collapses the gospel's 4-arg `(op_id, fn_a, fn_b, fn_c)` to 2 params.
- `tc_execute` → `TRIPLE_OK` (0) on unanimity; `TRIPLE_DISAGREE_2_1` (1, **non-negative status, not an error**) with the majority written to `out_result[0]`; `TRIPLE_DISAGREE_FATAL` (-1) on 3-way split (nothing written); `TRIPLE_E_NOTFOUND` (-2) if `op_id` is unregistered. `args` points to a caller-owned `[u64; 4]` = the canonical `{arg0,arg1,arg2,arg3}` passed to every implementation. W2-aggregate: collapses the gospel's 6-arg signature to 3 params.
- `tc_disagreement_count` → cumulative count of 2_1+fatal disagreement events since `tc_init` (sentinel-typed `u32`, W12).

Internal (non-`@export`) helpers: `tc_op_ptr(slot: u32) -> *u8`, `tc_find(op_id: *u8) -> u32` (sentinel `0xFFFFFFFFu32`), `tc_publish_disagreement(slot: u32, results: *u64, fatal: u8) -> i32` (W2-aggregated from the gospel's 5-arg form).

## Constant Namespace
**PREFIX = `TRIPLE_`** (assigned). Grep of `STDLIB/` for `TRIPLE_`, `tc_`, and `triple_check`: **zero existing definitions — no collision** (the gospel's `TC_` prefix is dropped; `TC_` was also collision-free but `TRIPLE_` is the dispatched prefix). Public *function* names keep the `tc_` form (function symbols are not subject to Trap-2 const-collision, and `tc_*` is the documented public surface in the gospel prose — renaming would break callers).

| const | type | value |
|---|---|---|
| `TRIPLE_OK` | `i32` | `0i32` |
| `TRIPLE_DISAGREE_2_1` | `i32` | `1i32` |
| `TRIPLE_DISAGREE_FATAL` | `i32` | `-1i32` |
| `TRIPLE_E_NOTFOUND` | `i32` | `-2i32` |
| `TRIPLE_E_FULL` | `i32` | `-3i32` |
| `TRIPLE_MAX_OPS` | `u32` | `256u32` |
| `TRIPLE_ID_BYTES` | `u64` | `32u64` |
| `TRIPLE_PAYLOAD_LEN` | `u64` | `56u64` |

(`TRIPLE_ID_BYTES`/`TRIPLE_PAYLOAD_LEN` added vs gospel to name the two magic constants 32 and 56 — anti-bloat: replaces inline literals, no new behavior.)

## Data Structures
All module-scope (W6/W8 static slot tables; no local `var` arrays — Trap 7). Bound = `TRIPLE_MAX_OPS` = 256, justified: triple-check is reserved for the handful of substrate-critical operations (federation signing, constitutional predicate eval, boot-path crypto); 256 distinct critical operations is an order of magnitude beyond the realized critical-op surface and matches the gospel's stated bound.

| name | type | size (bytes) | justification |
|---|---|---|---|
| `TRIPLE_LIVE` | `[u8; 256]` | 256 | per-slot liveness flag |
| `TRIPLE_OP_ID` | `[u8; 8192]` | 8192 | 256 × 32-byte op ids |
| `TRIPLE_FN_A` | `[u64; 256]` | 2048 | impl-A fn-ptr per slot |
| `TRIPLE_FN_B` | `[u64; 256]` | 2048 | impl-B fn-ptr per slot |
| `TRIPLE_FN_C` | `[u64; 256]` | 2048 | impl-C fn-ptr per slot |
| `TRIPLE_USED` | `u32 = 0u32` | 4 | high-water slot count |
| `TRIPLE_DISAGREE` | `u32 = 0u32` | 4 | cumulative disagreement counter |
| `TRIPLE_PRODUCER` | `[u8; 32]` | 32 | producer id = `ident("aether::triple_check")` |
| `TRIPLE_OPID_DIS_21` | `[u8; 32]` | 32 | op id for the 2_1 witness |
| `TRIPLE_OPID_DIS_FAT` | `[u8; 32]` | 32 | op id for the fatal witness |
| `TRIPLE_INITED` | `u8 = 0u8` | 1 | init-once guard |
| `TRIPLE_IN_C` | `[u8; 32]` | 32 | **hoisted** (was local `var in_c`): in_commit scratch |
| `TRIPLE_OUT_C` | `[u8; 32]` | 32 | **hoisted** (was local `var out_c`): out_commit scratch |
| `TRIPLE_PL` | `[u8; 56]` | 56 | **hoisted** (was local `var pl`): witness payload (op_id‖ra‖rb‖rc) |
| `TRIPLE_FID` | `[u8; 32]` | 32 | **hoisted** (was local `var fid`): frag-id sink |

Non-reentrancy note: the four hoisted scratch buffers make `tc_publish_disagreement` non-reentrant. Acceptable: `tc_execute` is a serialized critical-path operation (the substrate is single-threaded at R-1; disagreement publication runs to completion before the next `tc_execute`). Flagged per Trap-7 guidance.

## Dependencies (externs)
All providers are **already built** (Batch 1–2 realized substrate). **No not-yet-built dependencies.**

| extern signature | provider | NN | built? |
|---|---|---|---|
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `numera/identifier.iii` | 01 | yes |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | `numera/identifier.iii` | 01 | yes |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | `numera/identifier.iii` | 01 | yes |
| `fn wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `aether/witness_hook.iii` | 07 | yes |
| `fn wh_chain_root(out_id: *u8) -> i32` | `aether/witness_hook.iii` | 07 | yes |

Verified against the real provider files: `numera/identifier.iii` exports all three `ident_*` at the exact signatures the gospel declares (gospel filename `"identifier.iii"` resolves by basename — correct). `aether/witness_hook.iii` exports `wh_publish` (12-field hook, W2-excepted in its own header) and `wh_chain_root` at the exact signatures. **`wh_publish`/`wh_chain_root` are the §3.5-blessed witness emit primitives** — the gospel got these right (no `ws_emit_fragment` fiction present).

**Deleted extern (gospel defect):** `extern @abi(c-msvc-x64) fn tc_invoke4(fn_ptr:u64, a0:u64, a1:u64, a2:u64, a3:u64) -> u64 from "BOOT/resolver_unit.s"` — this symbol **does not exist** and is **not needed**. III natively lowers an indirect call through a `u64` local (`cg_call_indirect_via_local`, III-CODEGEN-PATTERNS.md #42 → `pop %rax; call *%rax`). Replaced by the in-language idiom (Algorithm §tc_execute).

## Algorithm

### `tc_init`
Zero all 256 `TRIPLE_LIVE` slots (sentinel loop, W14); set `TRIPLE_USED = 0`, `TRIPLE_DISAGREE = 0`. Compute the three fixed identifiers via `ident_from_bytes` (hand-rolled Keccak256 content addressing, M1/M6): `TRIPLE_PRODUCER = ident("aether::triple_check")` (20 bytes), `TRIPLE_OPID_DIS_21 = ident("aether::triple_check::disagree_2_1")` (34 bytes), `TRIPLE_OPID_DIS_FAT = ident("aether::triple_check::disagree_fatal")` (36 bytes). Set `TRIPLE_INITED = 1`. Deterministic (M2): same string literals → byte-identical ids every run. Returns `TRIPLE_OK`.

### `tc_register(op_id, impls)`
Lazy-init if `TRIPLE_INITED == 0`. If `TRIPLE_USED >= TRIPLE_MAX_OPS` return `TRIPLE_E_FULL`. Append at slot `s = TRIPLE_USED`; `TRIPLE_USED = s + 1`; `TRIPLE_LIVE[s] = 1`; `ident_copy(op_id, tc_op_ptr(s))`; load `TRIPLE_FN_A[s]=impls[0]`, `TRIPLE_FN_B[s]=impls[1]`, `TRIPLE_FN_C[s]=impls[2]`. The three `u64` values are **raw code addresses** the caller obtained via `(&fn) as u64` (NOT bare identifier — see Trap §10/G2). Returns `TRIPLE_OK`. Append-only registry → no rewrite, reversibility-trivial (M5/M9).

### `tc_op_ptr(slot)`
`return ((&TRIPLE_OP_ID as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8` — **masked** `slot as u64` (Trap 4) before the ×32 pointer arithmetic; house-style base-pointer form (Trap-free, replaces gospel's `&ARR[expr]`).

### `tc_find(op_id)`
Sentinel-loop `i` over `[0, TRIPLE_USED)`; for each `TRIPLE_LIVE[i] == 1`, `if ident_eq(tc_op_ptr(i), op_id) == 1u8 { return i }`. Fall through → `return 0xFFFFFFFFu32` (absence sentinel; callers gate with `== / != 0xFFFFFFFFu32`, never ordering — W11). Linear scan over ≤256 slots; deterministic, no recursion (W15).

### `tc_execute(op_id, args, out_result)` — the core
1. `slot = tc_find(op_id)`; `if slot == 0xFFFFFFFFu32 { return TRIPLE_E_NOTFOUND }`.
2. Load the four canonical args once into locals: `a0=args[0] … a3=args[3]` (also satisfies the param-spill discipline — values are reused across three calls, so they are forced to stack).
3. **Native indirect dispatch** (replaces fabricated `tc_invoke4`), exact fold.iii/resolver.iii idiom:
   ```
   let fa : u64 = TRIPLE_FN_A[slot]   let ra : u64 = fa(a0, a1, a2, a3)
   let fb : u64 = TRIPLE_FN_B[slot]   let rb : u64 = fb(a0, a1, a2, a3)
   let fc : u64 = TRIPLE_FN_C[slot]   let rc : u64 = fc(a0, a1, a2, a3)
   ```
   Each `u64` local invoked with the canonical 4-arg signature compiles to `cg_call_indirect_via_local` (#42). The three implementations are pure deterministic functions of `(a0..a3)` (M2) — identical inputs → identical `u64` per impl; only an *authoring* divergence between implementations produces a mismatch, which is exactly what the vote detects.
4. **Unanimity:** `if ra == rb { if rb == rc { out_result[0u64] = ra; return TRIPLE_OK } }` (house-style `out[0]=` store, replaces `*out_result =`).
5. **Majority (exactly two agree):** compute `have_maj`/`majority` by three pairwise `==` tests (the gospel's exact three-`if` form; bit-equality only, M15). `if have_maj == 1u8 { out_result[0u64] = majority; TRIPLE_DISAGREE = TRIPLE_DISAGREE + 1u32; tc_publish_disagreement(slot, args→{ra,rb,rc}, 0u8); return TRIPLE_DISAGREE_2_1 }`.
6. **Three-way fatal:** `TRIPLE_DISAGREE = TRIPLE_DISAGREE + 1u32; tc_publish_disagreement(slot, {ra,rb,rc}, 1u8); return TRIPLE_DISAGREE_FATAL`. Nothing written to `out_result` (M5: no fabricated "consensus" on a 3-way split; refusal, not guess).

Determinism/bit-identity (W5): the vote is pure `u64` equality over deterministic implementations; the disagreement payload is a fixed-layout little-endian serialization → the witness frag-id (Keccak256 in `wh_publish`) is byte-reproducible from recorded inputs (M10).

### `tc_publish_disagreement(slot, results, fatal)`
`results` is a `*u64` to `{ra, rb, rc}` (W2 aggregate of the gospel's 3 separate `u64` params). Build the 56-byte payload in `TRIPLE_PL`: bytes [0..31] = `tc_op_ptr(slot)[0..31]` (the op id), bytes [32..39] = `ra` LE, [40..47] = `rb` LE, [48..55] = `rc` LE (sentinel byte-extraction loop, `(v >> (k*8)) & 0xFFu64`). `wh_chain_root(&TRIPLE_IN_C)` → current chain root as in_commit. `ident_from_bytes(&TRIPLE_PL, 56, &TRIPLE_OUT_C)` → out_commit = content hash of the disagreement record. Then route through the real witness primitive: `wh_publish(&TRIPLE_PRODUCER, opid, &TRIPLE_IN_C, &TRIPLE_OUT_C, 1u8 /*revtag*/, 8u8 /*phase*/, 4u16 /*pillar*/, &TRIPLE_PL /*ante (n=0)*/, 0u32, &TRIPLE_PL, 56u32, &TRIPLE_FID)` where `opid = &TRIPLE_OPID_DIS_21` when `fatal == 0`, `&TRIPLE_OPID_DIS_FAT` when `fatal == 1` (two `if` guards, no `break`/ordering — W14). Returns `TRIPLE_OK`. M6/M16: the dissent is anchored (in_commit = chain root) and ratifiable (out_commit recomputable).

### `tc_disagreement_count`
`return TRIPLE_DISAGREE`. Pure read (M2). This is a **transparent event counter for audit/witness correlation, NOT a learning signal** — nothing in the module reads it back to change behavior (M3: no count-and-promote, no threshold-trigger). Flagged explicitly so Phase 2 does not turn it into adaptive logic.

## KAT Vectors (>= 3)
Self-test `tc_selftest() -> u64` (99 = pass), using three module-scope test implementations registered via `(&fn) as u64`:

- **Test impls** (each `fn(u64,u64,u64,u64)->u64`): `tc_kat_sum(a0,a1,a2,a3) = a0+a1+a2+a3`; a second identical-by-construction `tc_kat_sum2` returning the same sum; a `tc_kat_xor(a0,a1,a2,a3) = a0^a1^a2^a3`.

1. **Unanimity** → `TRIPLE_OK`, majority value, no disagreement count change.
   Register `op_U` with `{sum, sum2, sum}`. `args = {2,3,4,5}`. Expect `tc_execute == 0i32 (TRIPLE_OK)`, `out_result[0] == 14u64`, `tc_disagreement_count()` unchanged (== 0 at this point). All three agree (2+3+4+5 = 14).

2. **Two-of-three majority** → `TRIPLE_DISAGREE_2_1`, majority written, count += 1, one 2_1 witness fragment emitted.
   Register `op_M` with `{sum, sum2, xor}`. `args = {1,2,4,8}`. sum=sum2=15, xor=15 → **all agree** (bad vector); instead use `args = {1,2,4,7}`: sum=sum2=14, xor=1^2^4^7=0 → majority 14. Expect `tc_execute == 1i32 (TRIPLE_DISAGREE_2_1)`, `out_result[0] == 14u64`, `tc_disagreement_count() == 1u32`, and `wh_next_idx()` advanced by exactly 1 (one fragment published with op id == `ident("aether::triple_check::disagree_2_1")`).

3. **Three-way fatal** → `TRIPLE_DISAGREE_FATAL`, nothing written, count += 1, one fatal witness fragment emitted.
   Register `op_F` with three pairwise-distinct impls `{sum, xor, tc_kat_first}` where `tc_kat_first(a0,..)=a0`. `args = {1,2,4,8}`: sum=15, xor=15 (collision) — instead `args = {3,5,6,9}`: sum=23, xor=3^5^6^9=9, first=3 → all three distinct. Expect `tc_execute == -1i32 (TRIPLE_DISAGREE_FATAL)`, `out_result[0]` **unmodified** (pre-seed sentinel `0xDEADu64`, assert still `0xDEAD`), `tc_disagreement_count() == 2u32`, one fragment with op id == `ident("aether::triple_check::disagree_fatal")`.

4. **Not-found** → `TRIPLE_E_NOTFOUND`. `tc_execute(unregistered_id, args, out)` returns `-2i32`; `out_result` unmodified; count unchanged.

(Witness frag-id byte-reproducibility is covered transitively by `keccak256_kat`/`wh_selftest` in the already-built providers; this module's KAT asserts the *vote outcomes, counter deltas, and fragment-emission counts*, which are its own contract.)

## Trap Exposure
| Trap | Touched? | Avoidance |
|---|---|---|
| 1. Multi-line `fn` decl | yes (all sigs) | Every signature is single-line in the skeleton (incl. the 12-field `wh_publish` extern kept on logical lines — **must be physically one line**; flagged for Phase 2). |
| 2. `const` linker-global | yes | All consts prefixed `TRIPLE_`; grep-confirmed zero collision in `STDLIB/`. |
| 3. Signed-int ordering compare | yes | Return codes compared by `==/!=` only; `tc_find` sentinel gated by `== 0xFFFFFFFFu32`; never `< 0` on an i32. (W11.) |
| 4. u32-in-u64-slot garbage | **yes** | `tc_op_ptr` masks `(slot as u64) & 0xFFFFFFFFu64` before `*32` pointer math. `tc_find`/`slot` are u32 used only as loop/index counters, not raw pointer bases, but the one pointer-forming site is masked. |
| 5. u32 pointer-store width | no | All stores are `u8` (`TRIPLE_PL[k] = ...`) or `u64` array slots (`TRIPLE_FN_A[s] = impls[i]`, naturally 8-byte) or `out_result[0u64] = u64`. No `*u32` byte-store. |
| 6. Nested `/* */` | no | Single-level block comments; ASCII only. |
| 7. Local `var` arrays | **yes (gospel violation)** | The gospel's `var in_c/out_c/pl/fid` inside `tc_publish_disagreement` are **hoisted to module scope** as `TRIPLE_IN_C/OUT_C/PL/FID`. Non-reentrancy noted (serialized R-1 critical path). |
| 8. `} else {` one line | no | Algorithm uses guard-`if` chains (gospel style), no `else`. |
| 9. Em-dash in comment | n/a | All comments ASCII `--`. |
| 10. `let mut` checkpoint flag | minor | `have_maj`/`changed`-style flags follow the gospel's set-once pattern (set to 1 in a guard, read after); not used as a mutated loop checkpoint. No early-return-vs-flag hazard. |
| 11. `a % b` after call | no | No modulo anywhere; byte extraction uses `& 0xFFu64` shift-mask. |
| 12. `@specialize *T` stride | no | Not generic; all arrays concrete-typed. |
| **Indirect-call SEGV (Trap-10 family)** | **yes — critical** | Implementations are taken via `(&fn) as u64`, NEVER bare identifier (bare ident emits internal `L_<name>` ≠ exported symbol → undefined → SEGV; documented in `resolution_init.iii:89-95`). Invocation uses `let f : u64 = TRIPLE_FN_x[slot]` then `f(a0,a1,a2,a3)` — the proven `cg_call_indirect_via_local` (#42) / fold.iii idiom. |

## Gap / Fix List
- **G1 — Fabricated `tc_invoke4` extern (FATAL build blocker).** Gospel declares `extern fn tc_invoke4(...) from "BOOT/resolver_unit.s"`; no such symbol exists. **Fix:** delete the extern; dispatch with the native fn-ptr-via-`u64`-local idiom `let f : u64 = TRIPLE_FN_A[slot]; let ra : u64 = f(a0,a1,a2,a3)` (verified in `omnia/fold.iii:97-108`, `omnia/resolver.iii:733-748`; lowered by `cg_call_indirect_via_local`, III-CODEGEN-PATTERNS.md #42).
- **G2 — fn-ptr take must be `(&fn) as u64` (SEGV hazard).** Callers of `tc_register` (and the KAT) must pass implementation addresses obtained via `(&fn) as u64`, not bare identifiers. **Fix:** documented in API + Trap table; KAT registers all test impls via `(&tc_kat_sum) as u64` etc.
- **G3 — Trap-7: four function-local `var [u8;N]` arrays.** `tc_publish_disagreement` declares `var in_c:[u8;32]`, `var out_c:[u8;32]`, `var pl:[u8;56]`, `var fid:[u8;32]`. **Fix:** hoist to module scope `TRIPLE_IN_C/OUT_C/PL/FID`; note serialized non-reentrancy.
- **G4 — Wrong PREFIX.** Gospel uses `TC_` for consts/vars. **Fix:** rename all module-level consts and vars to `TRIPLE_` (assigned prefix); keep `tc_*` public function names.
- **G5 — W2 violations (>4 params).** Gospel `tc_execute` has 6 params, `tc_register` 4 (OK), `tc_publish_disagreement` 5. **Fix:** `tc_execute(op_id, args:*u64, out_result)` (3) with `args→[u64;4]`; `tc_register(op_id, impls:*u64)` (2) with `impls→[u64;3]`; `tc_publish_disagreement(slot, results:*u64, fatal)` (3). `wh_publish`'s 12 params are the documented W2-excepted multi-field witness hook (per witness_hook.iii header) — left as the extern requires.
- **G6 — Trap-4: unmasked `slot as u64` in `tc_op_ptr`.** **Fix:** mask `(slot as u64) & 0xFFFFFFFFu64` before `*32`.
- **G7 — Non-house element-address + deref-store.** Gospel uses `&TC_OP_ID[(slot)*32]` and `*out_result = ra`. **Fix:** base-pointer form `((&TRIPLE_OP_ID as u64) + off) as *u8` and `out_result[0u64] = ra` (matches witness_hook.iii / identifier.iii house style).
- **G8 — M3 guard on `tc_disagreement_count`.** The counter must remain a transparent audit/correlation read; **Fix:** documented that nothing reads it back to alter behavior (no count-and-promote / threshold-trigger). Phase 2 must not add adaptive logic on it.
- **Mandate compliance verified:** M1 (only `ident_*`/`wh_*` externs, hand-rolled vote), M2/M15 (exact `u64` bit-equality vote), M3/M4 (no learning, no "best-of" heuristic — unanimity or refusal), M5 (3-way → refuse, never fabricate consensus), M6/M10/M16 (disagreement anchored to chain root, out_commit content-hashed and reproducible), M7 (R-1 retained), M8 (optional cap-gating available via `cap_verify_rights` if Phase 2 restricts `tc_register`; not mandated by gospel — noted, not added). W2/W8/W9/W10/W11/W12/W14/W15 all satisfied per the table above. No not-yet-built dependencies.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/triple_check.iii
 *
 * III STDLIB - aether::triple_check
 *
 * Algebraic consensus on critical operations via three independent
 * implementations. Three impls of one logical fn(u64,u64,u64,u64)->u64
 * compute on identical args; the runtime proceeds only on unanimity.
 * Two-of-three yields the majority + a disagree_2_1 witness; three-way
 * is a hard fatal + disagree_fatal witness.
 *
 * Indirect dispatch uses the native iiis u64-fn-ptr call (NOT a BOOT
 * extern): impls are registered as (&fn) as u64 addresses and invoked
 * via `let f : u64 = TRIPLE_FN_x[slot]  f(a0,a1,a2,a3)`.
 *
 * Public API:
 *   tc_init() -> i32
 *   tc_register(op_id: *u8, impls: *u64) -> i32         -- impls -> [u64;3] {a,b,c}
 *   tc_execute(op_id: *u8, args: *u64, out_result: *u64) -> i32  -- args -> [u64;4]
 *   tc_disagreement_count() -> u32
 *
 * Hexad: kind_witness + kind_repair.  Ring: R-1.  K: 1.00.
 * Discipline: W2 (aggregates), W8 (256-slot bound), W11, W14, W15;
 *             Trap-7 scratch hoisted (serialized, non-reentrant).
 */
module aether_triple_check

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const TRIPLE_OK            : i32 =  0i32
const TRIPLE_DISAGREE_2_1  : i32 =  1i32
const TRIPLE_DISAGREE_FATAL: i32 = -1i32
const TRIPLE_E_NOTFOUND    : i32 = -2i32
const TRIPLE_E_FULL        : i32 = -3i32
const TRIPLE_MAX_OPS       : u32 = 256u32
const TRIPLE_ID_BYTES      : u64 = 32u64
const TRIPLE_PAYLOAD_LEN   : u64 = 56u64

var TRIPLE_LIVE        : [u8;  256]
var TRIPLE_OP_ID       : [u8;  8192]      /* 256 * 32 */
var TRIPLE_FN_A        : [u64; 256]
var TRIPLE_FN_B        : [u64; 256]
var TRIPLE_FN_C        : [u64; 256]
var TRIPLE_USED        : u32 = 0u32
var TRIPLE_DISAGREE    : u32 = 0u32
var TRIPLE_PRODUCER    : [u8; 32]
var TRIPLE_OPID_DIS_21 : [u8; 32]
var TRIPLE_OPID_DIS_FAT: [u8; 32]
var TRIPLE_INITED      : u8 = 0u8

/* Hoisted scratch (Trap 7: no function-local var arrays). Serialized -> non-reentrant. */
var TRIPLE_IN_C        : [u8; 32]
var TRIPLE_OUT_C       : [u8; 32]
var TRIPLE_PL          : [u8; 56]
var TRIPLE_FID         : [u8; 32]

fn tc_op_ptr(slot: u32) -> *u8 { return ((&TRIPLE_OP_ID as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8 }

fn tc_init() -> i32 @export {
    // TODO: body per Algorithm §tc_init -- zero TRIPLE_LIVE, reset counters,
    // compute TRIPLE_PRODUCER / TRIPLE_OPID_DIS_21 / TRIPLE_OPID_DIS_FAT via ident_from_bytes, set TRIPLE_INITED.
}

fn tc_register(op_id: *u8, impls: *u64) -> i32 @export {
    // TODO: body per Algorithm §tc_register -- lazy-init guard; TRIPLE_E_FULL bound check;
    // append slot; ident_copy op_id; TRIPLE_FN_A/B/C[s] = impls[0..2].
}

fn tc_find(op_id: *u8) -> u32 {
    // TODO: body per Algorithm §tc_find -- sentinel loop over [0,TRIPLE_USED); ident_eq match -> i; else 0xFFFFFFFFu32.
}

fn tc_publish_disagreement(slot: u32, results: *u64, fatal: u8) -> i32 {
    // TODO: body per Algorithm §tc_publish_disagreement -- build TRIPLE_PL (op_id || ra||rb||rc LE);
    // wh_chain_root -> TRIPLE_IN_C; ident_from_bytes(TRIPLE_PL,56) -> TRIPLE_OUT_C;
    // wh_publish with TRIPLE_OPID_DIS_21 (fatal==0) or TRIPLE_OPID_DIS_FAT (fatal==1), pillar 4, phase 8, revtag 1.
}

fn tc_execute(op_id: *u8, args: *u64, out_result: *u64) -> i32 @export {
    // TODO: body per Algorithm §tc_execute --
    //   slot = tc_find(op_id); if 0xFFFFFFFFu32 -> TRIPLE_E_NOTFOUND.
    //   a0..a3 = args[0..3].
    //   let fa : u64 = TRIPLE_FN_A[slot]  let ra : u64 = fa(a0,a1,a2,a3)   (likewise fb/rb, fc/rc) -- native indirect call.
    //   unanimity (ra==rb && rb==rc) -> out_result[0]=ra, TRIPLE_OK.
    //   pairwise majority -> out_result[0]=majority, TRIPLE_DISAGREE++, publish(fatal=0), TRIPLE_DISAGREE_2_1.
    //   else -> TRIPLE_DISAGREE++, publish(fatal=1), TRIPLE_DISAGREE_FATAL (out_result untouched).
}

fn tc_disagreement_count() -> u32 @export { return TRIPLE_DISAGREE }

/* ---- self-test (99 = pass): 3 module-scope impls, registered via (&fn) as u64 ---- */
var TRIPLE_T_IMPLS : [u64; 3]
var TRIPLE_T_ARGS  : [u64; 4]
var TRIPLE_T_OUT   : [u64; 1]
var TRIPLE_T_OPU   : [u8; 32]
var TRIPLE_T_OPM   : [u8; 32]
var TRIPLE_T_OPF   : [u8; 32]
var TRIPLE_T_OPX   : [u8; 32]

fn tc_kat_sum(a0: u64, a1: u64, a2: u64, a3: u64) -> u64 { return a0 + a1 + a2 + a3 }
fn tc_kat_sum2(a0: u64, a1: u64, a2: u64, a3: u64) -> u64 { return a0 + a1 + a2 + a3 }
fn tc_kat_xor(a0: u64, a1: u64, a2: u64, a3: u64) -> u64 { return ((a0 ^ a1) ^ a2) ^ a3 }
fn tc_kat_first(a0: u64, a1: u64, a2: u64, a3: u64) -> u64 { return a0 }

fn tc_selftest() -> u64 @export {
    // TODO: body per KAT Vectors --
    //   tc_init();
    //   K1 unanimity: impls={(&tc_kat_sum),(&tc_kat_sum2),(&tc_kat_sum)} as u64, op_U, args={2,3,4,5}
    //       -> TRIPLE_OK, out==14, count==0.
    //   K2 majority: impls={sum,sum2,xor}, op_M, args={1,2,4,7} -> TRIPLE_DISAGREE_2_1, out==14, count==1.
    //   K3 fatal:    impls={sum,xor,first}, op_F, args={3,5,6,9}, pre-seed out=0xDEAD
    //       -> TRIPLE_DISAGREE_FATAL, out unchanged (0xDEAD), count==2.
    //   K4 not-found: tc_execute(op_X, args, out) -> TRIPLE_E_NOTFOUND, count==2.
    //   return 99u64 on all-pass.
}
```
