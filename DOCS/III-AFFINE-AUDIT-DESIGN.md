# DESIGN: `--affine-audit` — the Fully-Automatic Inward Turn (SW-INWARD-AUTO)

*Status: DESIGN (to implement if the full gate is green). The compiler-track completion of the Sovereign
Witness: III statically extracts each typed-array access pattern from its OWN AST and PROVES it in-bounds,
so the analyzer built to judge external programs certifies III's own source — automatically, every build.*

---

## 1. Goal & honest scope

A new compiler mode `iiis-2 --affine-audit FILE.iii` that, after parse+sema (the AST is built), walks every
function and **proves every typed-array index access is in-bounds**, or **REFUTES** it with a location, or
**ABSTAINS** (skips) when the access is not in the soundly-analyzable shape. A build gate runs it over the
whole stdlib; any REFUTED fails the build. This is the inward turn made automatic: no hand-written contract
(unlike corpus 419) — the descriptor is extracted from the AST itself.

**What is soundly auto-checkable (in scope):** an index into a **resolvable typed array** `var/let ARR :
[T; SIZE]` (SIZE known at compile time), where the index is **affine in an enclosing loop counter** with a
literal/const bound — e.g. `XCHD_BUCKETS[bucket_idx*16 + slot]` with `XCHD_BUCKETS : [u8; 2304]` (the scan-5
class). Proof = the inlined `sw_prove_affine` closed form (wrap-aware u64).

**What is NOT (explicit ABSTAIN — never a false PROVEN):**
- **Pointer accesses** `p[i]` where `p : *T` (the scan-5/6 *audit_records/record_count* sites): the bound is
  a runtime `count` param, NOT known at compile time. The witness's manual descriptors (corpus 419) remain
  the tool there; the auto-pass cannot soundly prove a runtime-bounded access and MUST abstain.
- A non-literal / non-const loop bound, a non-affine or call-derived index, an array whose decl the pass
  cannot resolve, a runtime-variable index with no enclosing affine loop. All -> ABSTAIN (skip), per the
  load-bearing soundness rule: faithfully represent the semantics or ABSTAIN, never PROVEN.

This is a genuine subset (typed-array affine-OOB, the xii_chd class), not the whole scan-5/6 surface — and
that honest boundary is the design, not a gap.

## 2. Feasibility (verified against source 2026-05-31)

All AST accessors already exist (no C-seed change needed for the walk):
`iii_ast_fn_body`, `iii_ast_block_stmt_count/at`, `iii_ast_while_cond/body`, `iii_ast_let_value/type`,
`iii_ast_index_object/index`, `iii_ast_binary_lhs/rhs/op`, `iii_ast_ident_name_offset/length`,
`iii_ast_expr_int_u64`, `iii_ast_expr_hex_u64`, `iii_ast_type_array_count`, `iii_ast_node_kind`.
Kind constants: `R3_K_STMT_WHILE=70`, `R3_K_STMT_LET=20`, `R3_K_EXPR_BINARY=49`, `R3_K_EXPR_INDEX`,
`R3_K_EXPR_IDENT=45`, `R3_K_EXPR_INT=37`, `R3_K_EXPR_HEX=38`, `R3_K_TYPE_ARR=17`, `R3_K_FN_DECL=4`,
`R3_K_VAR_DECL=74`.
Binary op codes: `1=ADD 2=SUB 3=MUL 9=SHL 13=LT 14=LE 15=GT 16=GE`.
`main(argc, argv)` already flag-dispatches (`--compile-only`, `--link`, `--diag=json`) -> clean `--affine-audit` hook.

## 3. The pass (new file `COMPILER/BOOT/affine_audit.iii`)

```
aa_audit_module(ast) -> u32   // 0 = all PROVEN/ABSTAIN; >0 = count of REFUTED (build fails)
  for each top-level decl that is R3_K_FN_DECL:
    aa_walk_stmt(fn_body, loop_ctx = NONE)

aa_walk_stmt(node, loop_ctx):
  k = node_kind(node)
  if k == STMT_WHILE:
     lc = aa_parse_loop_cond(while_cond(node))   // -> {var_off, var_len, bound_u64} or INVALID
     aa_walk_block(while_body(node), lc)           // body sees the loop var + bound
  elif k == block:  for each stmt: aa_walk_stmt(stmt, loop_ctx)
  elif k == STMT_LET: aa_walk_expr(let_value(node), loop_ctx)   // (track let-bound affine temps: §5)
  elif k == STMT_IF/FOR/MATCH/...: recurse into sub-blocks with the same loop_ctx
  else: aa_walk_expr(expr_of(node), loop_ctx)

aa_walk_expr(node, loop_ctx):
  recurse into all sub-exprs first (binary lhs/rhs, call args, index obj/idx, unary)
  if node_kind(node) == EXPR_INDEX:
     arr = index_object(node); idx = index_index(node)
     size = aa_resolve_array_size(arr)              // §4; 0xFFFF.. = unresolvable -> ABSTAIN
     if size == UNRESOLVABLE: return                 // ABSTAIN (pointer / unknown)
     aff = aa_match_affine(idx, loop_ctx)            // §5 -> {base, stride, count} or NOT_AFFINE
     if aff == NOT_AFFINE: return                    // ABSTAIN
     v = aa_prove_affine(aff.base, aff.stride, aff.count, size)   // inlined sw_prove_affine
     if v != PROVEN: aa_report_refuted(node, v, aff, size); REFUTED_COUNT += 1
```

## 4. `aa_resolve_array_size(arr)` — the crux

For `arr` an `EXPR_IDENT`: resolve the name (offset,length into the source) to its declaration, then to its
type, then to `type_array_count`. Reuse the path cg_r3 already uses to type an index object
(`r3_index_obj_elem_kind` resolves the element; we need the COUNT). Two cases:
- **module-global `var ARR : [T; N]`** — look up in the global symbol table by name -> var-decl -> let_type
  (R3_K_TYPE_ARR) -> `type_array_count`. (xii_chd's XCHD_BUCKETS, lru's arrays, SW_WREC, etc.)
- **local `let x : [T; N]`** — resolve in the current fn's locals.
If the resolved type is `R3_K_TYPE_PTR` or not an array, or the name is unresolved -> UNRESOLVABLE -> ABSTAIN.
*Implementation note:* this is the only piece needing care; the increment-1 fallback (below) sidesteps full
local resolution by handling module-global arrays first (where the scan-5 class lives).

## 4b. LOAD-BEARING SOUNDNESS: the loop-range guarantee (worked out during implementation)

`while i < N { body }` guarantees `i < N` only at the TOP of the body. A mid-body mutation (`i = i + k`
BEFORE an access) can make `i >= N` at the access -> assuming `i in [0,N)` there would be an UNSOUND PROVEN.
The sound rules (all verified, else ABSTAIN):
- **i0 = 0**: the loop var's binder must be a `let i = 0` (literal-0 init). (`i` is u-typed so `i >= 0`; with
  i0=0 and the LT condition, `i in [0,N)` at the loop top.) A non-zero / non-literal init -> ABSTAIN.
- **access-before-mutation** *(SUPERSEDED — the shipped pass uses the stronger whole-subtree pre-scan:
  `aa_count_writes` over the ENTIRE body subtree must total exactly 1, and `aa_last_stmt_writes` must place
  that sole write at the trailing top-level statement; an in-order flag misses a write nested in an `if`,
  which the subtree scan catches. The `aa_addr_taken` guard above is the 4th rule. Original narration kept
  for history)*: walk the body statements IN ORDER with an `i_mutated` flag (init 0). An access
  is checked against `[0,N)` ONLY while `i_mutated == 0`; once a statement ASSIGNS the loop var (`i = ...`),
  set `i_mutated = 1` and all SUBSEQUENT accesses ABSTAIN (i's value is no longer condition-bounded). The
  canonical idiom (`{ ...uses i...; i = i+1 }`) -> every access is sound; mid-body mutation -> later accesses
  ABSTAIN. This is exact-as-an-upper-bound: any actual i at a pre-mutation access satisfies `i < N` (condition)
  and `i >= 0` (u-type), so proving over `[0,N)` covers it. The loop STEP is irrelevant to this bound (the
  actual i values are a subset of [0,N) regardless of step), so no step analysis is needed -- only LT/LE form +
  i0=0 + access-before-first-mutation.
- cond must be `IDENT(i) < N` (op LT) or `<= N` (op LE -> count N+1); N a literal or a const-ident resolving
  to a literal (via binder -> CONST_DECL -> const_decl_value). Anything else -> ABSTAIN.
- **address-escape (4th rule, found in review)**: `aa_count_writes` counts only *syntactic* `i = …`. A
  non-syntactic mutation -- `&i` escaping into a call (`mutate(&i)`) -- is a `STMT_EXPR` scored as 0 writes,
  so the sole-trailing-write rule would wrongly rule the loop sound and PROVE the access (a FALSE PROVEN).
  Closed by `aa_addr_taken(body, i)`: scan the WHOLE body subtree for a unary address-of (op 5) whose
  operand is the loop var; ABSTAIN the loop if found. SCOPE (honest prove-the-negative): this closes the
  IN-BODY escape by construction. A *pre-loop alias* (`let p = &i` OUTSIDE the body, then `mutate(p)` inside)
  is not in the body subtree and is NOT scanned -- so the guard is sound for in-body escape PLUS the
  empirically-verified absence of any `&counter` (direct or aliased) in-tree (`&counter` occurs 0x anywhere,
  and `&local` is bogus so nothing mutates a counter through a pointer). It changes no PROVEN count.
  Verified by `s_addr_escape` in `affine_audit_sound.iii` (without the guard: false PROVEN; with it: ABSTAIN).

## 5. `aa_match_affine(idx, loop_ctx)` — sound affine recognition

Recognize, for the enclosing loop var `i` (from loop_ctx) with bound `N`:
- `i`                         -> {base 0, stride 1, count N}
- `i * S` / `S * i` (lit S)   -> {base 0, stride S, count N}
- `i << K` (lit K)            -> {base 0, stride 2^K, count N}
- `(affine) + C` (lit C)      -> base += C   (e.g. `i*16 + slot` where slot is a const/param -> base=slot if
                                  slot resolves to a constant; else the +slot term -> bound base by slot's
                                  type max IF slot is a typed small value, else ABSTAIN)
- a `let t = i*S` then `arr[t]` -> track `t` as an affine temp in a small per-loop table (name->affine).
Anything else (two loop vars, a call, a non-literal stride, `slot` not const-bounded) -> NOT_AFFINE -> ABSTAIN.
Conservative `+ base` handling: if `base` is not a compile-time constant, ABSTAIN (don't guess) UNLESS it is
a parameter whose type bounds it (e.g. a value `< 16` by an earlier guard) -- increment-1 ABSTAINS on
non-constant base to stay trivially sound; a later increment can fold guards.

## 6. `aa_prove_affine` — inlined, identical to the witness

The exact `sw_prove_affine` closed form, re-implemented in the compiler (the compiler does not link
libiii_native.a): count==0 -> PROVEN; detect `(count-1)*stride` u64 wrap -> REFUTED_WRAP; else
`base+(count-1)*stride >= size` -> REFUTED_BOUNDS(first i); else PROVEN. ~30 lines, u64-exact. (Same
algorithm corpus 416 already adversarially verifies, so its soundness is established.)

## 7. main hook + output

`main`: detect `--affine-audit` in argv; run the normal lex+parse+sema to build the AST, then call
`aa_audit_module(ast)` INSTEAD of codegen; print each REFUTED as `FILE:line: affine-audit: <arr> index may
reach <addr> >= size <N> (i=<ce>)` (text) and exit nonzero if REFUTED_COUNT>0; exit 0 otherwise. ABSTAIN is
silent (or `--affine-audit=verbose` lists abstentions for transparency).

## 8. Determinism / golden-drift / reseal

Adding the flag + the pass changes the compiler SOURCE -> iiis-2.exe BARE hash drifts -> a reseal is
required (build_iiis2). CRITICAL: the pass runs ONLY under `--affine-audit`; the `--compile-only` codegen
path is UNCHANGED -> iiis-1 and iiis-2 still produce byte-identical `.o` on stage1_corpus -> the
byte-equivalence gate (`build_iiis2 --check-corpus`) still passes -> a CLEAN reseal (only the BARE golden
hash updates; no corpus drift). Follow ADR-027 + the fragile-port safeguards: build through iiis-0->1->2->3,
verify iiis-2==iiis-3 fixed point, update the golden BARE hash, re-run stage1_corpus byte-equiv.

## 9. The gate + KAT

- **gate:** `scripts/affine_audit_gate.sh` runs `iiis-2 --affine-audit` over every stdlib `.iii`; FAIL if any
  REFUTED. Added to the build discipline (a quick gate).
- **prove-the-negative KAT:** two tiny fixtures -- `aa_safe.iii` (`var A:[u8;100]; while i<10 { A[i*4] }` ->
  audit exits 0) and `aa_unsafe.iii` (`var A:[u8;100]; while i<10 { A[i*16] }` -> 9*16=144 >= 100 -> audit
  exits nonzero with the REFUTED line). The unsafe fixture is the constructible negative: the auto-pass
  must catch it. Plus `aa_abstain.iii` (`p[i]` on a `*u8` param -> audit exits 0, ABSTAIN, no false REFUTE).

## 10. Implementation order (each step verified before the next; compiler-change discipline)

```
AA-1  aa_prove_affine (inlined check) + a standalone unit harness proving it matches corpus 416 cases.   [low risk]
AA-2  aa_resolve_array_size for MODULE-GLOBAL arrays only (the scan-5 locus).                             [the crux]
AA-3  aa_match_affine (the i / i*S / i<<K / +const shapes) + the loop-cond parser.                        [pattern]
AA-4  aa_walk_* recursion + EXPR_INDEX hook; ABSTAIN everywhere not matched.                              [walk]
AA-5  main --affine-audit hook (run sema then audit; nonzero on REFUTED).                                 [wire]
AA-6  RESEAL (build_iiis2 -> fixed point; stage1 byte-equiv holds; update golden BARE hash).              [determinism]
AA-7  affine_audit_gate.sh over the stdlib + the 3 KAT fixtures; quick-gate green.                        [gate]
AA-8  run the auto-pass over the stdlib -> triage any REFUTED (real bug -> fix; false -> tighten ABSTAIN). [the payoff]
```

**The payoff (AA-8):** running `--affine-audit` over III's whole stdlib turns the Witness from a
hand-fed certifier (419) into III continuously, automatically proving its own typed-array accesses safe —
the analyzer and the self-enhancer finally one organ. Every REFUTED it finds is a real scan-5-class bug the
human scans might miss; every PROVEN is a machine-checked safety certificate that re-verifies each build.

## VALIDATION RESULTS (landed 2026-05-31)

The pass shipped as `COMPILER/BOOT/affine_audit.iii` (in `PORTED_TUS`), wired via `--affine-audit` after
sema in `main.iii`. Verified end-to-end on a LOCAL non-installed iiis-2, then resealed into the installed
compiler:

- **KAT** (`affine_audit_kat.iii`): `AA P=1 A=1 R=1` + `AA REFUTED sz=16 i=16` — PROVEN / REFUTED (with the
  correct first-OOB witness) / ABSTAIN (pointer) all correct on ground truth, through a cast+paren-wrapped
  access.
- **Soundness probe** (`affine_audit_sound.iii`): `AA P=1 A=5 R=0` — all five no-false-PROVEN traps ABSTAIN:
  nested-if write, two-writes, signed loop var, mutation-before-access, AND the `&i` address-escape (the
  last two found in review; the address-escape would be a false PROVEN without `aa_addr_taken`).
- **Scale** (539 files, all sema'd standalone): **PROVEN=8299, ABSTAIN=11814, REFUTED=1** — the single
  REFUTED is the KAT's deliberate OOB; ZERO false positives across the entire real codebase.
- **Codegen byte-equivalence**: stage1 corpus 59/59 byte-identical (iiis-1 vs the new iiis-2) — the audit is
  genuinely dormant by default; the reseal is codegen-neutral.
- **Reseal**: golden BARE hash `196b0c5f…` -> `5eae8780…`; `build_iiis2 --check-corpus` = 59 passed, 0 failed.

Two soundness gaps were found and closed DURING review (not after): (1) `EXPR_BLOCK` vs `FORWARD_BLOCK`
block-kind dispatch; (2) the `&counter` address-escape (`aa_addr_taken`, op-5 ADDR, ARG-unwrapped). A third
fix — `ARG(57)` unwrap via `iii_ast_arg_value` — restored the call-argument accesses (`foo(arr[i])`) that
were silently skipped, raising PROVEN 7978 -> 8299 with still zero genuine REFUTED.
