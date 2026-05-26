# 05b numera/rev_invoke.iii — Implementation Spec

## Verdict
NEW (no gospel body) — this micro-module does **not** exist in `III_CONVERGENCE_GOSPEL.md`; it is the sibling indirect-call primitive that `numera/reversible.iii` (Module 05) declares as an extern (`reversible.spec.md` Gap B / Dependencies / skeleton line 243). Designed here from first principles. **Design verdict: NATIVE u64 fn-ptr call — NO `metal {}` block.** The realized substrate already lowers an indirect call through a `u64`-typed function address with the exact 4-argument C-msvc-x64 callee shape this module needs; a hand-written Win64 asm trampoline is therefore unnecessary, would duplicate compiler-managed ABI/shadow-space handling, and would add inline-asm trap surface for zero benefit. (This **supersedes** the speculative "`metal {}` Win64 indirect `call`" language in `reversible.spec.md` Gap B, which was written before the native 4-arg idiom was confirmed in the realized tree.)

## Purpose
`numera::rev_invoke` is the substrate's single sanctioned **indirect-call trampoline**: it IS the act of replaying an undo by address. It exists so `numera/reversible.iii` can invoke recorded backward-continuation functions (whose addresses it stores as `u64` in `REV_UNDO_FN[]`) while `reversible.iii` itself stays pure `.iii` (no inline asm, no `metal`). It takes a callee address plus the four `u64` undo arguments and calls the callee with the fixed C-msvc-x64 ABI `fn(a:u64,b:u64,c:u64,d:u64)->i32`, propagating the callee's `i32` result. **Hexad:** `kind_motion` (it IS the transfer of control to a recorded address — pure passage, no stored state). **Ring:** R-1 (sub-kernel privileged substrate — an indirect `call` through an arbitrary address is a privileged control-flow act). **K-vector:** 1.00 — total: every input `(undo_fn,a,b,c,d)` either calls a valid callee and returns its `i32`, or (null target) returns a fixed sentinel; there is no failure mode and no allocation.

## Public API
Single-line (Trap 1). Return conventions per fn (W9/W12).

```
fn rev_invoke_undo(undo_fn: u64, a: u64, b: u64, c: u64, d: u64) -> i32 @export
```
Calls the function at address `undo_fn` with the C-msvc-x64 signature `fn(a:u64,b:u64,c:u64,d:u64)->i32`, passing `a,b,c,d`, and returns the callee's `i32` verbatim. **5 params — the ONE sanctioned >4-arg extern surface in the substrate** (W2 governs the *callee* shape, which is 4 args; the trampoline carries one extra word — the target address — which cannot be folded without re-introducing a per-call indirection table). Return value is the callee's status (the built-in undo bodies all return `REV_OK = 0i32` on success, negative on error per W9); `rev_invoke_undo` itself adds the null-target sentinel `REVINV_NULL_TARGET = -1i32` (W9 negative-i32 error; W12 status return). Treat the return as opaque-passthrough except for that one sentinel.

```
fn revinv_kat_target(a: u64, b: u64, c: u64, d: u64) -> i32 @export
```
Module-scope KAT target (callee under test). Writes `a` into `REVINV_KAT_BUF[0]` (a module-scope `[u64;1]`) and returns `(b as i32)`. **4 params — W2-OK** — it IS the mandated trampoline-callee shape, so it doubles as the canonical example of a conforming undo body. Exported so the self-test can take its address as `revinv_kat_target as u64` and so the Phase-2 corpus driver can link it.

```
fn revinv_selftest() -> u64 @export
```
KAT entry (house convention: `*_selftest() -> u64 @export`, cf. `algebraic_time.iii:41`, `identifier.iii:115`, `content_addr.iii:92`). Takes `revinv_kat_target as u64`, calls `rev_invoke_undo(addr, 0xCAFEu64, 7u64, 0u64, 0u64)`, and asserts (a) `REVINV_KAT_BUF[0] == 0xCAFEu64` (arg `a` reached the callee) AND (b) the return `== 7i32` (arg `b`→return propagated through the trampoline). Returns `0u64` on PASS, a non-zero bitmask of failed checks otherwise. (Pure value; not a sentinel-return — matches the `-> u64` self-test convention where 0 = all-pass.)

## Constant Namespace
**PREFIX = `REVINV_`** — tree-wide ripgrep over `C:\Users\Edwin Boston\OneDrive\Desktop\III\**\*.iii` for `REVINV_`, `module numera_rev_invoke`, `fn rev_invoke_undo`, and `fn revinv_` returned **NO matches** (zero collision). Module name `numera_rev_invoke` is unique (no existing `rev_invoke*` source file anywhere in the tree). Note: the public fn `rev_invoke_undo` and the test fns `revinv_kat_target` / `revinv_selftest` are likewise collision-free.

| const | type | value | note |
|---|---|---|---|
| `REVINV_OK` | i32 | `0i32` | success passthrough mirror (W9); equals the callee's `REV_OK` on the happy path. Documentary — `rev_invoke_undo` returns the *callee's* value, not this. |
| `REVINV_NULL_TARGET` | i32 | `-1i32` | sentinel returned when `undo_fn == 0u64` (null-target guard; M5). Distinct negative i32 (W9). |
| `REVINV_KAT_EXPECT_A` | u64 | `0xCAFEu64` | KAT: expected value deposited into `REVINV_KAT_BUF[0]`. |
| `REVINV_KAT_EXPECT_RET` | i32 | `7i32` | KAT: expected propagated return (`b as i32`). |

(Only four module-level consts; all `REVINV_`-prefixed so each emits a unique linker-global `L_REVINV_*` — Trap 2 satisfied.)

## Data Structures
All module-scope (Trap 7 — no local `var` arrays).

| name | type | size | bound justification (W8) |
|---|---|---|---|
| `REVINV_KAT_BUF` | `[u64; 1]` | 1 | the KAT target's observable sink: `revinv_kat_target` writes arg `a` here so `revinv_selftest` can prove arg-`a` delivery. A 1-element `[u64;1]` (not a scalar) so `&REVINV_KAT_BUF[0]` / indexed write is well-defined under iiis-0's documented byte/array-address rule (same posture as `resolver.iii`'s `RES_CTX_CACHE_PTR : [u64;1]`). Non-reentrant (single-threaded substrate use); acceptable — the self-test is serialized, and the production callees (reversible.iii's undo bodies) do not use this buffer. |

No production state. The trampoline itself is **stateless** (pure control transfer); `REVINV_KAT_BUF` exists solely for the self-test. Address-of-static (`&REVINV_KAT_BUF[0]`) is taken **only inside this file** (W1/W3); no global pointer escapes. The callee address passed to `rev_invoke_undo` originates in the *caller* (reversible.iii's `REV_UNDO_FN[]`, itself populated only by addresses of reversible.iii's own static fns) — rev_invoke does not mint or store addresses, so no W1/W3 escape originates here.

## Dependencies (externs)
**None.** This is a leaf micro-module: it imports nothing and is imported by `numera/reversible.iii` (Module 05). The native indirect call is emitted by the compiler's own lowering (no extern, no `metal`). Not-yet-built dependency count: **0**. (Wave scheduling: `rev_invoke.iii` has no predecessors and MUST be scheduled **before** Module 05 `reversible.iii`, which lists it as its sole not-yet-built dependency.)

## Algorithm
NIH (M1): the only mechanism is a native language indirect call — no library, no third-party code, no asm. No ML/heuristics (M3/M4): control flow is a single null-check + one call; no counting, observation, or threshold. Determinism (M2) / bit-identity (W5): for a fixed `(undo_fn,a,b,c,d)` the emitted call transfers control to the same address with the same register/stack image every run, on every conforming x64 host, and returns whatever the callee returns — the trampoline adds no nondeterministic state. No recursion (W15): straight-line; the trampoline never calls itself (the callee is an arbitrary undo body, which by reversible.iii's contract is a leaf op that does NOT re-enter the reversible API — `reversible.spec.md` Gap K). Cost (M19): O(1), a single `call` plus return; bounded.

- **`rev_invoke_undo(undo_fn, a, b, c, d)`** — null guard then native indirect call:
  1. `let target : u64 = undo_fn` — **bind the parameter to a local first** (mitigates the documented Win64 single-use-parameter spill trap from the CRASH-PROTOCOL: a parameter used only once may be read from an uninitialized stack slot; binding to a named local forces a stable home). All five params are likewise read into locals (`let pa : u64 = a` … `let pd : u64 = d`) before the call so the spill bug cannot misfeed arguments. (≤ 6 named locals — well under W13's 20.)
  2. `if target == 0u64 { return REVINV_NULL_TARGET }` — null-target guard (M5: an indirect `call 0` would fault and is unrecoverable). Documented contract: the production caller (`reversible.spec.md` `rev_rollback`/`rev_nest_rollback`) already guards `fn_addr != 0u64` before invoking, so in practice `rev_invoke_undo` receives a non-null target; this guard is defense-in-depth (returns a sentinel rather than executing a wild call) and is exercised by KAT 3. **NB (Trap, sibling of #16-bit-null family):** the guard MUST compile to a 64-bit `test rax,rax`; written as `target == 0u64` (a `u64` literal) it is an unsigned 64-bit equality, which the realized compiler lowers correctly (the documented 16-bit-null hazard is specific to certain `0q`/pointer forms — using an explicit `0u64` against a `u64` local is the safe shape, identical to `resolver.iii`'s `if cached_p == 0u64`).
  3. `let f : u64 = target` — the **proven native fn-ptr idiom** (`fold.iii:98`, `resolver.iii:609,746`): assign the `u64` address to a fresh local named `f`, then call it.
  4. `return f(pa, pb, pc, pd)` — native indirect call with the 4-arg C-msvc-x64 ABI. The compiler's registered lowering (codegen pattern slots 42/43, `cg_call_indirect_via_local` / `cg_call_indirect_via_expr` in `III-CODEGEN-PATTERNS.md §3`) emits the `call *reg` sequence, **manages the 32-byte shadow space and stack alignment, and preserves callee-saved registers itself** (CRASH-PROTOCOL §0.6 register discipline is satisfied by the compiler's own prologue/epilogue + call lowering, exactly as for the existing `f(0u64,0u64,0u64,ctx)` call in `resolver.iii:747`). The callee returns `i32` in `eax`; the function's `-> i32` return type carries it back verbatim. **Bit-identity of arg passing:** binding params to locals (step 1) guarantees `a→rcx, b→rdx, c→r8, d→r9` are sourced from defined stack homes, so the 4 arguments land in the correct registers deterministically.

  *Why native and not metal:* The realized tree already calls a **4-arg** `u64` function address natively and W2-cleanly (`resolver.iii:744-748` — `value = f(0u64, 0u64, 0u64, ctx)` where `f` is `pattern_dispatch_fn(p_win)`, a runtime `u64` address). The callee shape there (4× word-sized args → `i32`/`u64` return) is identical in arity and register layout to this module's `fn(a,b,c,d:u64)->i32`. The only delta vs. resolver is that resolver's callee returns `u64` and ours returns `i32`; the indirect-call lowering is return-type-agnostic (it reads `rax`/`eax` per the declared return type — the same `call *reg` bytes). Therefore a hand-written `metal {}` Win64 trampoline (rcx=undo_fn → shuffle rdx→rcx,r8→rdx,r9→r8,[rsp+0x28]→r9, sub rsp,0x20, call rcx, add rsp,0x20) is **redundant**: it would re-implement, in raw asm, exactly what the compiler already emits correctly — and per CRASH-PROTOCOL the gauge-in-metal / hand-asm-stack-balance hazards make inline asm strictly riskier than the proven native path. **Maximal + safest = native.**

  *Argument-shuffle note (resolves the briefing's metal-ABI question):* In the hypothetical metal form, the 5→4 ABI bridge would need rcx=undo_fn, rdx=a, r8=b, r9=c, [rsp+0x28]=d on entry, then move rdx→rcx, r8→rdx, r9→r8, [rsp+0x28]→r9 to form the callee's `(a,b,c,d)`. The **native** form makes this shuffle the compiler's responsibility: `f(pa,pb,pc,pd)` is a normal 4-arg call, so the compiler loads `pa→rcx, pb→rdx, pc→r8, pd→r9` directly from their stack homes — there is no manual register shuffle to get wrong, which is precisely why native is safer. The 5th incoming param (`d`, at `[rsp+0x28]` in rev_invoke's own frame) is read by the compiler as a normal stacked parameter; binding it to `pd` (step 1) guarantees a defined read before it is re-passed as the callee's 4th arg.

- **`revinv_kat_target(a, b, c, d)`** — `REVINV_KAT_BUF[0u64] = a` (8-byte store of a genuine `u64` param through a `[u64;1]` index — full-width `movq` is correct, NOT the Trap-5 u32-origin hazard); `return (b as i32)`. `c`/`d` are unused (named to honor the 4-arg callee shape). Deterministic, leaf, no externs — the canonical conforming undo body.

- **`revinv_selftest()`** — `let addr : u64 = revinv_kat_target as u64` (fn-address idiom, cf. `zk_prune.iii:40` `(&ZKP_W as u64)` and the `rev_undo_* as u64` registrations reversible.iii performs); `REVINV_KAT_BUF[0u64] = 0u64` (clear sink); `let r : i32 = rev_invoke_undo(addr, REVINV_KAT_EXPECT_A, 7u64, 0u64, 0u64)`; build a failure bitmask: bit 0 set if `REVINV_KAT_BUF[0u64] != REVINV_KAT_EXPECT_A`, bit 1 set if `r != REVINV_KAT_EXPECT_RET` (i32 equality only — Trap 3 / W11); `return mask` (0u64 = PASS). No recursion, single straight-line check.

## KAT Vectors (>= 3)
A self-test (`revinv_selftest`) checks these byte/value-for-value; they are the Phase-2 acceptance gate.

1. **Arg-`a` delivery + return propagation (the core proof).** `REVINV_KAT_BUF[0]=0`; `r = rev_invoke_undo(revinv_kat_target as u64, 0xCAFEu64, 7u64, 0u64, 0u64)`. **Expected:** `REVINV_KAT_BUF[0] == 0xCAFEu64` (arg `a` arrived in `rcx` and was stored) **AND** `r == 7i32` (arg `b` arrived in `rdx`, was cast to i32, returned in `eax`, and propagated unchanged through the trampoline). This single vector proves the whole contract: address dispatch + arg passing (`a`,`b`) + i32 return propagation.

2. **Distinct second invocation (no residual state / determinism).** After KAT 1, `REVINV_KAT_BUF[0]=0`; `r2 = rev_invoke_undo(revinv_kat_target as u64, 0x1234_5678_9ABC_DEF0u64, 42u64, 0xFFu64, 0xEEu64)`. **Expected:** `REVINV_KAT_BUF[0] == 0x123456789ABCDEF0u64` (full 64-bit arg `a`, proving the high 32 bits survive — guards any u32-truncation regression) **AND** `r2 == 42i32`. `c=0xFF`,`d=0xEE` are ignored by the target (proves extra args are harmless and the trampoline does not corrupt them into the result). Re-running with the same inputs yields the identical pair (M2/W5 bit-identity).

3. **Null target → sentinel, no wild call (M5 negative case).** `r3 = rev_invoke_undo(0u64, 0xDEADu64, 0xBEEFu64, 0u64, 0u64)`. **Expected:** `r3 == REVINV_NULL_TARGET (-1i32)` **AND** `REVINV_KAT_BUF[0]` is **unchanged** from its pre-call value (proves the guard short-circuited BEFORE any call — the callee never ran, so the sink was not written). This proves the M5 guard *fails closed* on a null address rather than faulting — the mandated negative-case proof (per MEMORY discipline: prove the guard FAILS on bad input, not just that the happy path passes).

(KAT 3 is the load-bearing negative test; KATs 1–2 prove the positive contract with a full-width 64-bit value to catch truncation.)

## Trap Exposure
- **Trap 1 (multi-line fn):** EXPOSED (the 5-param `rev_invoke_undo` signature is the longest). Avoidance: every `fn` signature on **one physical line**, including `fn rev_invoke_undo(undo_fn: u64, a: u64, b: u64, c: u64, d: u64) -> i32 @export`.
- **Trap 2 (const prefix linker-global):** EXPOSED. Avoidance: all four consts `REVINV_`-prefixed; collision-checked clean tree-wide.
- **Trap 3 (signed ordering compare SIGSEGV):** NOT EXPOSED. The only i32 comparisons are equalities (`r != REVINV_KAT_EXPECT_RET`, `r3 == REVINV_NULL_TARGET`); the only other compare is `target == 0u64` (unsigned 64-bit equality). No `< <= > >=` on any signed value (W11).
- **Trap 4 (u32-in-u64-slot pointer math):** NOT EXPOSED. No u32 locals enter pointer arithmetic; `REVINV_KAT_BUF` is indexed by a `u64` literal (`0u64`), and all five params are genuine `u64`.
- **Trap 5 (u32 pointer store width):** NOT EXPOSED. The single store (`REVINV_KAT_BUF[0u64] = a`) writes a genuine `u64` param into a `[u64;1]` — an 8-byte `movq` is the correct width (same as `reversible.spec.md`'s `rev_undo_mem_u64`). No u32-origin value is stored through a wider pointer.
- **Trap 6 (nested block comments):** NOT EXPOSED — no nested `/* */`; ASCII only.
- **Trap 7 (local var arrays):** NOT EXPOSED. `REVINV_KAT_BUF` is **module-scope**; no function-local `var [..]`. (Documented non-reentrant — acceptable, the only state is the serialized KAT sink.)
- **Trap 8 (`} else {`):** NOT EXPOSED — guard-clause early-return style (`if target == 0u64 { return ... }`), no `if/else`. Any `else` added in Phase 2 must be `} else {` on one line.
- **Trap 9 (em-dash in comment):** EXPOSED (header prose). Avoidance: ASCII `--` everywhere; no U+2014.
- **Trap 10 (`let mut` checkpoint flag):** NOT EXPOSED — no mutated flag; the self-test builds its result via direct equality tests into a `mut` mask written once-per-bit (or, preferably, computed as `(c0bit | c1bit)` without a re-tested flag).
- **Trap 11 (modulo-after-call):** NOT EXPOSED — no `%` operator anywhere.
- **Trap 12 (`@specialize *T` stride):** NOT EXPOSED — not generic; no `@specialize`.
- **CRASH-PROTOCOL Win64 param-spill (not in the 12 but load-bearing here):** EXPOSED (this module's entire job is passing 5 params, some "used once"). Avoidance: **bind every parameter to a named local before the indirect call** (`let pa=a` … `let pd=d`, `let target=undo_fn`), forcing defined stack homes so the documented single-use-parameter-not-spilled bug cannot misfeed `rcx/rdx/r8/r9`. This is the most important correctness measure in the module and the reason the algorithm is specified that way.

## Gap / Fix List
NEW module — there is no gospel body to repair. What this spec **establishes / verifies**:
- **Native-vs-metal decision RESOLVED → native.** Verified by reading the realized native fn-ptr idiom: `fold.iii:97-108` (`fn fold_u8_u32_via_fn(..., step: u64)` → `let f : u64 = step; f(acc, v)`) and `resolver.iii:733-748` (`let f : u64 = dispatch_fp; value = f(0u64, 0u64, 0u64, ctx)` — a 4-arg native indirect call, the exact callee arity needed). Confirmed by `III-CODEGEN-PATTERNS.md §3` slots 42/43 (registered indirect-call lowering, `pop %rax; call *%rax`). **No `metal {}` required.** This corrects/supersedes the speculative metal-trampoline language in `reversible.spec.md` Gap B (written before the 4-arg native idiom was confirmed against the realized tree).
- **5-param extern is sanctioned and unavoidable.** The trampoline carries `undo_fn` + 4 callee args = 5; the callee shape stays 4 (W2-clean). This is the substrate's single `>4-arg` extern surface by design (`reversible.spec.md` Dependencies line 129). Documented and justified, not a violation.
- **Null-target safety (M5).** `undo_fn == 0u64` returns `REVINV_NULL_TARGET` instead of faulting on `call 0`. The production caller (reversible.iii) already pre-guards `fn_addr != 0u64`; this module's guard is defense-in-depth and is proven by KAT 3 (negative case — sink unchanged, sentinel returned).
- **Param-spill hardening.** All params bound to locals before the call (CRASH-PROTOCOL trap) — the one subtle correctness requirement, called out in the Algorithm and Trap-Exposure sections.
- **Mandate posture.** M1 (NIH — zero externs, zero asm, native control transfer), M2/M15 (deterministic, total over its bit width), M3/M4 (no learning/heuristics — one null-check + one call), M5 (no brick — null guard fails closed), M7 (ring R-1 — privileged indirect control flow), M19 (O(1) bounded cost). M6/M8/M9/M10 (witness/capability/reversibility) are **out of scope by design**: this is a pure control-transfer primitive — the *caller* (`reversible.iii`) owns the reversible envelope, capability gating, and witness emission; routing those through a control-transfer trampoline would violate single-responsibility and force this leaf module to take dependencies it must not have. M11-M14/M16-M18/M20 are not in this module's remit (no proof terms, branches, memo, or theorem carriers) — out of scope, not violated.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/rev_invoke.iii
 *
 * III STDLIB - numera::rev_invoke
 *
 * The substrate's single sanctioned indirect-call trampoline.
 * Given a callee address (as u64) and four u64 arguments, it calls
 * the callee with the C-msvc-x64 ABI fn(a,b,c,d:u64)->i32 and returns
 * the callee's i32 result. numera/reversible.iii uses this to replay
 * recorded undo functions by address while staying pure .iii (no asm).
 *
 * Decision: NATIVE u64 fn-ptr call (no metal block). The compiler's
 * registered indirect-call lowering (codegen patterns slots 42/43)
 * emits call *reg and manages the 32-byte shadow space + callee-saved
 * registers; the proven native idiom is fold.iii:97-108 and
 * resolver.iii:733-748 (a 4-arg native indirect call). A hand-asm
 * Win64 trampoline would only re-implement that, with added risk.
 *
 * This module is stateless in production; the only module-scope buffer
 * (REVINV_KAT_BUF) exists for the self-test and is non-reentrant.
 *
 * Hexad: kind_motion.  Ring: R-1.  K: 1.00 (total -- null target -> sentinel).
 * Discipline: W2 (callee = 4 params; trampoline = 5, the one sanctioned
 * exception), W9 (negative i32 errors), W12 (status return), W13 (<=20
 * locals), W14 (no break -- straight line), W15 (no recursion).
 * CRASH-PROTOCOL: every parameter is bound to a local before the
 * indirect call so the Win64 single-use-param spill bug cannot misfeed
 * rcx/rdx/r8/r9.
 */

module numera_rev_invoke

const REVINV_OK             : i32 =  0i32
const REVINV_NULL_TARGET    : i32 = -1i32
const REVINV_KAT_EXPECT_A   : u64 = 0xCAFEu64
const REVINV_KAT_EXPECT_RET : i32 = 7i32

/* Self-test sink (module-scope; Trap 7). [u64;1] so the indexed
 * address is well-defined under iiis-0's byte/array-address rule. */
var REVINV_KAT_BUF : [u64; 1]

fn rev_invoke_undo(undo_fn: u64, a: u64, b: u64, c: u64, d: u64) -> i32 @export {
    // TODO: body per Algorithm --
    //   let target : u64 = undo_fn  (bind params to locals: spill-bug guard)
    //   let pa : u64 = a  let pb : u64 = b  let pc : u64 = c  let pd : u64 = d
    //   if target == 0u64 { return REVINV_NULL_TARGET }   (M5 null guard, 64-bit eq)
    //   let f : u64 = target                              (native fn-ptr idiom)
    //   return f(pa, pb, pc, pd)                          (4-arg C-msvc-x64 indirect call)
}

fn revinv_kat_target(a: u64, b: u64, c: u64, d: u64) -> i32 @export {
    // TODO: body per Algorithm --
    //   REVINV_KAT_BUF[0u64] = a    (genuine u64 store; 8-byte movq correct)
    //   return (b as i32)
    //   (c, d unused -- named to honor the 4-arg callee shape)
}

fn revinv_selftest() -> u64 @export {
    // TODO: body per Algorithm --
    //   let addr : u64 = revinv_kat_target as u64
    //   REVINV_KAT_BUF[0u64] = 0u64
    //   let r : i32 = rev_invoke_undo(addr, REVINV_KAT_EXPECT_A, 7u64, 0u64, 0u64)
    //   build failure mask: bit0 if REVINV_KAT_BUF[0] != REVINV_KAT_EXPECT_A,
    //                       bit1 if r != REVINV_KAT_EXPECT_RET   (i32 equality only)
    //   (extend with KAT 2 full-width value + KAT 3 null-target sentinel check)
    //   return mask    (0u64 = all-pass)
}
```
