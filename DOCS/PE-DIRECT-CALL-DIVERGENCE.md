# Phase XII-ν — Close the PE Direct-Call Triple-Bit-Identity Divergence

Status: **CLOSED / IMPLEMENTED + VERIFIED (RITCHIE Stage 3.1, 2026-05-21).**
The `r3_try_pe_direct_call` no-op stub described below (§1) was **removed and
replaced with a real INLINE implementation** in cg_r3.iii's EXPR_CALL
callq-selection (the `pe_hit` branch, cg_r3.iii:1944-2010) — mirroring
cg_r3.c's single-flow 3-way callq branch (cg_r3.c:1718-1779), placed AFTER
arg-eval+shadow (the structurally-correct point the old stub could not
reach). **VERIFICATION (§4): iiis-0 (cg_r3.c) ≡ iiis-1 (cg_r3.iii) `.o`
byte-identical on the two PE-narrowing modules `omnia/ai_resolve.iii` +
`omnia/transform.iii` (`let r = resolve(set,intent,ctx)` static-intent), AND
on ALL 100 `omnia/*.iii` modules (IDENTICAL=100 DIFFER=0).** task #44 / task
#19 PE-direct class CLOSED. (iiis-2/iiis-3 full-chain triple-bit-identity →
RITCHIE Stage 3.3.) The §1-§5 below are the original (now-stale, May-18)
ANALYSIS+ADR that specified the fix; retained for provenance. Contract C13:
this header reconciles the stale "NOT implemented in this pass" (§5).

---
### ORIGINAL ANALYSIS+ADR (May-18, pre-implementation — retained for provenance)


## 1. The defect (genuine, no-placeholder + bit-identity standards)

`COMPILER/BOOT/cg_r3.iii::r3_try_pe_direct_call` (line ~2484) is a no-op
`return 0u32` placeholder (its own comment: "Currently no-op
placeholder; full multi-stmt elision needs args-eval + cleanup").

The C reference `cg_r3.c` **implements** PE direct-call elision
(1706–1793): when an `EXPR_CALL` callee is an `EXPR_IDENT` bound to a
local slot recorded in the PE static-fp map, it emits
`    # III_PE_DIRECT_CALL <fn>\n    callq <fn>\n` (raw unmangled symbol)
instead of the indirect `emit_expr(callee); pop rax; callq *%rax`.

Consequence: for any function whose source hits the PE multi-stmt
narrowing (a `let fp = resolve(set, intent, ctx)` with static intent,
then `fp(...)`), **iiis-0 emits a 5-byte direct `callq` while
iiis-1/iiis-2 emit indirect** → byte divergence → violates the
iiis-0≡iiis-1≡iiis-2 invariant. Invisible to the 57 stage1 probes
(which contain no resolver/HIP narrowing); manifests in resolver-heavy
STDLIB — precisely the task-#19 residual divergence class.

## 2. Phase-1 evidence (infra present; only the emit body missing)

cg_r3.iii ALREADY has the full PE-map machinery:
- `R3_PE_SLOT[64]`, `R3_PE_NAME_ADDR[64]`, `R3_PE_NAME_LEN[64]`,
  `R3_PE_COUNT` (cg_r3.iii:618-621).
- `r3_pe_record_static_fp(slot,addr,len)` (2418), wired from the
  STMT_LET path (2041-2044 via `r3_pe_classify_let_value`, 2464).
- `r3_pe_get_static_fp(slot) -> u64` (2430; sets `R3_G_PE_NAME_LEN`).
- The `# III_PE_DIRECT_CALL ` 25-byte literal (608) — already defined.
- Single-stmt sibling `r3_try_pe_resolve` already implemented + called
  at the same site (1879); `r3_try_pe_direct_call` called next (1880),
  caller does `if pe_dc == 1u32 { return R3_OK }`.

Structural fact (the "args-eval + cleanup" the comment cites): the
caller invokes `r3_try_pe_direct_call` BEFORE its own
align/arg-eval/reg-pop/shadow code and returns immediately on a hit.
So the function must emit the **entire** call sequence itself, byte
-identical to cg_r3.c's pe_direct path (cg_r3.c 1678–1840) and to
cg_r3.iii's own normal EXPR_CALL tail — differing ONLY in the callq
form.

## 3. ADR-XII-ν-1 — exact fix specification

`r3_try_pe_direct_call(call_node, callee, argc)`:
1. If `callee` kind ≠ `R3_K_EXPR_IDENT` → return 0.
2. `slot = r3_local_lookup_slot(callee's name off/len)`; if no local
   slot → return 0 (top-level decl: not PE-direct).
3. `name_addr = r3_pe_get_static_fp(slot)`; if 0 → return 0
   (`R3_G_PE_NAME_LEN` is set as a side effect).
4. Otherwise emit, **byte-identical to cg_r3.c 1678–1840 pe_direct
   path and cg_r3.iii's normal EXPR_CALL tail (callq substituted)**:
   - `reg_args=min(argc,4)`, `stack_args=argc>4?argc-4:0`,
     `align_pad=((R3_G_STACK_DEPTH+stack_args)&1)`.
   - if align_pad: `R3_STR_ALIGN8` (`subq $8,%rsp`), depth+1.
   - reverse arg-eval: `ai=argc; while ai>0 { ai--; a=arg_at(node,ai);
     r3_emit_expr(arg_value(a)) }` (exact loop cg_r3.iii uses @1884).
   - pops: `reg_args>=1 r3_pop_rcx; >=2 r3_pop_rdx; >=3
     R3_STR_POPR8_NL depth-1; >=4 R3_STR_POPR9_NL depth-1`.
   - `R3_STR_SUB32_RSP`, depth+4.
   - emit `    # III_PE_DIRECT_CALL ` (lit @608) + name bytes
     (`name_addr`,`R3_G_PE_NAME_LEN`) + `\n` + `    callq ` + same name
     + `\n`  — RAW symbol (no `L_`), matching cg_r3.c 1774-1779.
   - `R3_STR_ADD32_RSP`, depth-4.
   - if align_pad: `addq $8,%rsp`, depth-1 (exact cg_r3.iii form).
   - if stack_args: `addq $(stack_args*8),%rsp`, depth-=stack_args.
   - return-type narrowing: fetch callee binder's declared return type;
     emit movzbq/movsbq/movzwq/movswq/movl/movslq per u8|bool / i8 /
     u16 / i16 / u32 / i32 (u64+/ptr = no-op) — byte-identical to
     cg_r3.c 1814-1838 and cg_r3.iii's normal-tail equivalent.
   - push rax (call result → TOS), exact cg_r3.iii form.
   - return 1.

**Constraint**: every emitted byte (mnemonics, immediates, the marker
comment, whitespace, newlines, stack_depth deltas) must equal what
cg_r3.iii emits on its NORMAL path for the identical call MINUS the
callee-eval/`callq *%rax` (replaced by the marker + `callq <fn>`), AND
equal cg_r3.c's pe_direct emission. The normal-tail bytes are the
authority (they already satisfy 57/57); copy them verbatim, substitute
only the callq.

## 4. Verification requirement (Phase 4 — stricter than usual)

57/57 stage1 equivalence is INSUFFICIENT here (no stage1 probe exercises
PE narrowing). Required:
1. Read EVERY line of cg_r3.iii's normal EXPR_CALL emission tail
   (~1884–2010) before editing; the pe-direct emission must be a
   verbatim copy with only the callq substituted.
2. Rebuild iiis-0/1/2; deterministic reseal (2× identical).
3. **Full-corpus** triple-bit-identity: not just stage1 — every STDLIB
   module + corpus `.o` compiled by iiis-1 AND iiis-2 must be
   byte-identical to iiis-0's, INCLUDING resolver/HIP modules that hit
   the PE-narrowed path. Net residual byte-divergence count must
   decrease toward 0 (task #19), never increase.
4. A targeted probe: a module with `let fp=resolve(set,intent,ctx); fp(..)`
   static-intent pattern compiled by all three → identical `.o`.
5. XII corpus 92/93 + stdlib corpus PASS=250 baseline (no regression).

## 5. ADR decision

**Status**: Accepted (analysis/spec). The defect is genuine and
in-scope (no-placeholder + the triple-bit-identity invariant + task
#19). The fix is fully specified above (§3) — a byte-exact mirror of an
already-correct path. **It is NOT implemented in this pass**: per the
CRASH-PROTOCOL ("read every participating line; never rush an edit to
divergence-critical code; the find→edit→break→repeat pattern is
forbidden"), a ~130-line byte-exact rewrite of the substrate's core
call-lowering must be executed with the complete line-by-line read of
cg_r3.iii's normal tail and full-corpus divergence-closure verification
(§4) — a dedicated, exhaustive undertaking, not a session-tail edit
where a single wrong byte breaks the substrate's core invariant
system-wide. Recorded as task #44 (deepest in-scope genuine defect; the
core of task #19). **Alternatives rejected**: rushing the edit now
(violates CRASH-PROTOCOL; catastrophic-if-imperfect on core-invariant
code); leaving the misleading "no-op placeholder" comment without a
precise spec (unfaithful — understates a real bit-identity divergence).
