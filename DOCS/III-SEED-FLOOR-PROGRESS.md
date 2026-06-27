# III — Φ1 Seed Trust-Floor Progress (ccsv → iiis-0 C seed)

**Goal (Φ1/R1, the keystone residual of DOCS/III-COMPLETION-PLAN.md):** grow `ccsv` (STDLIB/sovir/ccsv.iii,
a from-scratch non-gcc C→SVIR compiler) until it compiles the iiis-0 C seed (`COMPILER/BOOT/{lex,sema,emit,
ast,cg_r3,parse}.c`) **correctly**, so `seed_ddc.sh CC2=ccsv` can close the binary DDC and the trusted build
path is sovereign at the bottom (no gcc compiling the seed).

## The reliable instrument (durable; built + validated this session)
- `STDLIB/sovir/run_seed_verify.sh` — per-function SVIR verify over the 6 seed modules. **3 controls gate it**
  before any reading is trusted (positive hand `_ve_goodmod`, negative hand `_ve_badmod`, pipeline `sha256.c`)
  + a self-check (first-nonzero per-fn rc == whole-module `svir_verify` rc).
- `STDLIB/sovir/verify_each.iii` (per-fn verify_body walk) ; `STDLIB/sovir/svir_dis.iii` (opcode+running-depth
  tracer; classifies underflow). `svir_verify.iii` now `@export`s `verify_body`.
- `ccsv file.c dbg` now dumps STN/SFN/AN/CN/FN counts + per-STRUCT field metadata + the fn name-map — the
  ground-truth localizer that solved the prior session's 38-round HARD-STOP.

## Verified state: 183 → 39 seed verify-failures (144 cleared, 79%) — lex.c at STRUCTURAL ZERO; BOTH BOSSES CLOSED
Per module now (re-measured 2026-06-26, `run_seed_verify.sh`, deterministic): **lex 0 · sema 5 · emit 4 ·
ast 10 · cg_r3 2 · parse 18** = 39 over 488 functions. **`lex.c` is the first seed module at structural zero.**

**FIX #36 — `sizeof(p->field[i])` (iii_ast_rollback, 42→39, cleared 3 fns: 1 ast + 2 cg_r3).** Same recurring root
family as #33/#34/#35: the esizeof `sizeof(p->field)` handler consumed `->field` (giving the field's POINTER size
8) then returned, leaving `[i]` unconsumed -> 0x00.  For `sizeof(ast->hashcons[i])` the answer is the ELEMENT/pointee
struct size (`sizeof(slot_t)`).  Fix: after `->field`, `if cp(Q_LBR){ sz = fieldpt>=0 ? STSZ[pointee] : fieldelem ;
skip [i]; eat(]) }`.  Verified `_szi`=36 == gcc=36 (value); `_ami` (memset(&p[i],0,sizeof(p[i]))) clears; cleared
iii_ast_rollback + 2 cg_r3 fns, run_ccsv green, 0 regression.  ★ The "tail-dropping" family now spans index/member
chains AND sizeof — a general-fix multiplier (each root clears multiple fns across modules).

**★★ KEYSTONE NEXT — FUNCTION POINTERS / INDIRECT CALLS (a FEATURE, not a tail-drop).** `iii_ast_walk_post` (idx 80)
+ ~5-6 more ast residue fns (walk_pre, iterate_children, zipper_descend, walk_state_create, diff_recurse — the
visitor pattern) are blocked because **ccsv has NO function-pointer support**: a function NAME used as a value
(`_fa`: pass `visit` as an arg) AND an indirect call (`_fc`: `vfn fn=add; fn(3,4)`) BOTH emit all-`0x00`.  This is
the single highest-leverage remaining item (one feature unblocks the whole walker cluster).  DESIGN: a fn-pointer
VALUE = the SVIR function INDEX (small int); name-as-value -> `CONST fidx`; indirect call `fn(a,b)` -> push args,
push the index, **new opcode CALL_INDIRECT** (immediate=argcount; pops the index off the stack, calls fn[index]).
FIVE components, ALL must pass all-4: (1) ccsv codegen [fn-name->CONST fidx ; `fn(args)`->CALL_INDIRECT ; parse
`T (*p)(...)` locals/params], (2) SVIR opcode CALL_INDIRECT [a free byte; interp op_w=1], (3) svir_interp [pop idx,
recurse like 0x70], (4) x86 backend [the HARD part: a computed call by index — dispatch table over the fn-offset
table the linker already builds], (5) wasm backend [native `call_indirect` + a funcref table].  NOT rushed at an
extreme-session tail; a focused multi-backend session.  The 4 truly-fn-ptr-FREE ast residues are serialize_buf /
deserialize_buf / zipper_sibling — continuable meanwhile.

**FIX #34/#35 — nested-UNION-member lvalues (iii_canonical_node_bytes, 43→42).** The canonical-serialization fn
(huge `switch(n->kind)`) uses two union-chain constructs ccsv botched.  (#34) **`&n->u.<variant>.<field>`** — the
`&p->field` handler (696) emitted `ptr+first-offset` then RETURNED, leaving `.member.field` unconsumed -> residue;
the READ chain (849) walks members via `fieldpt` but the `&` path didn't.  Fix: walk the member chain summing
offsets (union members at +0), emit `ptr+acc`.  Verified `_um`=14 (was 139+segfault), `_r1`=5; controls clean.
(#35) **`n->u.<variant>.arrayfield[k]`** — the `p->f0.f1.f2..` read chain (888) eloaded the last member without
consuming a trailing `[k]` (same dangling-`[k]` class as #33, but through a union) -> loaded `[0]` + 0x00.  Fix:
at the last member, `if cp(Q_LBR){ +k*fieldelem }` before the load.  Verified `_uh2`=18 (=6×3, memset-clean READ),
iii_canonical_node_bytes CLEARED, run_ccsv green, 0 regression.  ★ Same root family as #33 (a postfix `[k]`/member
chain not walked to the end) — recurring ccsv gap: whenever a handler `return`s after one field, it forgets the
tail.  LATENT (not in seed residue, uses pointers): the struct-VALUE store `v.u.member.arrayfield[i] = e` (`_uh3`).

**FIX #33 — `structarray[i].arrayfield[k]` nested-lvalue, FIXED in ccsv (45→43, cleared iii_hashcons_grow + 1 more).**
The doubly-indexed lvalue (a struct-array element's ARRAY field, indexed) emitted `0x00` for the dangling `[k]`
(rc=2 in isolation; rc=8 inside a fn) AND read/wrote the wrong cell — 7 seed sites, floor-INVISIBLE as a value bug
but it also residued.  Root: SIX ccsv handlers (READ 836 `T[i].field`, 844 `p[i].field`, 895 `p->arrfield[i].sub`
+ STORE 1376/1384/1341) each loaded/stored the field then RETURNED without consuming a trailing `[k]`.  Fix (all
six, uniform): after the field address, `if cp(Q_LBR) { ebin; eat(]); estride(fieldelem); ADD }` before the
load/store — adds `k*subelem`.  Three lvalue SHAPES covered: local struct-array `a[i].mhash[k]` (`_c4`=5), local
pointer `p[i].mhash[k]` (`_cp`=14), and the seed's ptr-FIELD `ast->hashcons[i].mhash[k]` (`_cseed`=14).  All
value-verified (was 0/garbage), gcc + svir_interp agree, run_ccsv green, 0 regression.  The earlier `_sva` "struct
array-copy drops the field" was a PHANTOM — it was a victim of this read bug in its own value-check, not a separate
copy defect (now `_sva`=16).  ★ A GENERAL ccsv codegen gap (not one fn) — fixing the root cleared 2 fns + 7 sites.

**FIX #32 — `iii_ast_create` CLEARED (46→45) — TWO roots, cracked by the advisor's reduce-to-CLEAR method.** After
~15 faithful repros came back CLEAN (the trigger was real-struct-tied, un-reproducible), I stopped repro-probing and
ran truncation-to-CLEAR bisection on the REAL ast.c (gate = "idx 21 absent", NOT the offset which shifts with byte
edits).  4 cuts pinned it to line 454 (`ast->string_payloads = (const uint8_t **)calloc(16, sizeof(const uint8_t *))`).
Two independent roots there: (a) **reg_fields registered a DOUBLE-ptr field `const uint8_t **string_payloads` with
the 2nd `*` AS the name** (consumed only ONE `*`) -> `ast->string_payloads` un-findable; fix = consume ALL `*` (like
#29 but for FIELDS; `_dpf` proves the field now names + offsets at 392).  (b) **`sizeof(<pointer-type>)` as a calloc
arg** left a value on the stack (`sizeof(uint32_t)` scalar is fine; `sizeof(const uint8_t *)` pointer is NOT) — a
discriminating seed test (sizeof->`8u` CLEARED; drop-the-cast did NOT) isolated it; Adjustment-1 fix = literal `8u`
(== one payload pointer).  Both land: idx 21 CLEARED, gcc rc=0, floor 45, run_ccsv green.  ★ Method that cracked a
"deep" fn: when repros all go clean, the trigger is real-struct-tied — reduce-to-CLEAR on the real fn + discriminating
seed edits, never more synthetic repros.  Latent ccsv gap noted: sizeof-of-pointer-type as a call-arg (worked around).

**FIX #30 — `iii_pool_grow` CLEARED (47→46) via reduce-by-removal to the LAST orphan + Adjustment 1.** The
advisor's "move the number" lesson realized: a multi-orphan fn only clears when EVERY orphan falls.  Reduce-by-
removal on the REAL ast.c (back up → delete pools → recompile → check rc 18) pinned the residual to the mhash pool,
then to **`sizeof((*mh)[0])`** (sizeof of a deref-INDEX; the ~50 plain `sizeof(*p)` sites are clean, only this one
deref-index site breaks).  Adjustment 1 (rewrite the gnarly C, not teach ccsv): `sizeof((*mh)[0])` -> `32u` (==
what the very next `memset` already uses), gcc syntax-rc=0 + behavior-preserving.  Combined with #29 (struct
double-ptr local), iii_pool_grow's two orphans both crushed -> CLEARED.  ★ Method that WORKS: reduce-by-removal on
the real fn to the last orphan; per-orphan choose ccsv-fix vs C-rewrite; the floor moves in FUNCTION-steps.

**FIX #31 (partial) — `sizeof(*field)` rewrite + iii_ast_create reduce-by-removal (IN PROGRESS).** Auto-continued
to `iii_ast_create` (idx 21, DEEPLY multi-orphan).  Found+fixed one orphan: **`sizeof(*ast->string_payloads)`**
(sizeof of a deref of a pointer FIELD) -> residue, vs `sizeof(*localvar)` clean; the ONLY such site in the seed,
Adjustment-1 rewrite (superseded — see FIX #32 above, which CLEARED iii_ast_create: the actual roots were the
double-ptr-field naming + `sizeof(<pointer-type>)`-as-calloc-arg, NOT the sizeof-of-deref-field).  Lesson kept:
offset SHIFTS with byte edits — confirm an orphan by behavior-preserving rewrite (the fn must CLEAR), not by the
offset number moving.

**★ PINNED NEXT TARGET — `iii_hashcons_grow` (idx 38) + a GENERAL floor-invisible value bug.** Probing its rehash
loop surfaced a ccsv defect bigger than the one fn: **`structarray[i].arrayfield[k]`** (a struct-array element's
ARRAY field, doubly-indexed) reads/writes the WRONG address — `_c4` (`a[1].mhash[0]`)=0 not 5, while `a.mhash[0]`
(single struct), `a[1].ni` (scalar field), and the pointer-decomposed `uint8_t *m=a[1].mhash; m[0]` (`_c5`) all
WORK.  So ccsv loses the `[i]` struct-stride when a `[k]` field-array-index follows.  **7 seed sites** (ast.c:672-675
`hashcons[i].mhash[k]`, ast.c:2232/2276 `stack[i].children[k]`, link.c:259 `modules[idx].dep_idx[k]`) — all
residue-CLEAN but VALUE-WRONG (the floor can't see them).  PLUS a struct-value array-copy `p[pos]=ast->hashcons[i]`
that drops the array field (`_sva`=9 not 16).  iii_hashcons_grow is multi-issue (rc=8 residue + these 2 value bugs);
do NOT half-clear its residue while value bugs remain.  FIX = ccsv root (the nested-lvalue address path in eprim) —
GENERAL, fixes all 7 + the struct-copy; a fresh focused session, not an extreme-session tail.  Method: `_c4`/`_c5`
are the discriminator (direct doubly-indexed WRONG vs pointer-decomposed RIGHT).

**FIX #27 — complex C declarator: `iii_pool_mhash` (ast) — TWO roots, both value-verified.** Signature
`uint8_t (**iii_pool_mhash(..))[32]` (function returning ptr-to-ptr-to-array).  (a) **Function-declarator suffix**:
after the params `)`, the trailing `)[32]` sat before the body `{`; cfn ran prescan + `eat(Q_LB)` from the wrong
point -> body mis-compiled (rc=8; in the seed a 21KB body that overlapped following fns).  Fix: cfn skips tokens
between the params `)` and `{` (bounded by `;`/EOF).  (b) **Pointer-to-array STRUCT FIELD** `uint8_t (*small_mhash)
[32]` registered as a 1-BYTE field (el=1) -> `nf=2 sz=2`, **mis-offsetting every later field** (a FLOOR-INVISIBLE
ast-struct-layout bug, like #26).  Fix: reg_fields scalar branch handles `TYPE (*NAME)[N]` -> 8B ptr (name after
`(*`).  Result: struct now `nf=2 sz=16` (off 0,8); `_decloff`/`_decl2` (deref pmhash's returned ptr)=99,
`_decl`=41, `_swret`=6, all-4; floor 48→47, run_ccsv green.  ★ The value-check (lesson #26) caught (b): part (a)
alone CLEARED the residue but `_decl2`=1 (wrong) — residue-clear would have shipped a silent-wrong partial fix.

**FIX #28 — ≥8B compound literal, the Latent-Axiom Guillotine (Adjustment 2).** The seed's only ≥8B site is
`iiip_parse_arg`'s `iii_src_pos_t pos = (iii_src_pos_t){0,0,0,0}` (DIRECT init); the old >8B path SKIPPED it ->
correct ONLY if the frame happened to be zeroed (floor-invisible fragility).  Fix: (a) the local-init skips the
redundant `(T)` so `T x=(T){..}` falls into the brace-init (per-field store into x) -> ROBUSTLY correct for any
size, all-zero OR non-zero (verified `_cl16ok`=10, `_br16ok`=26 — and the earlier `_cl16nz`=210 was `1234&0xFF`,
an 8-BIT EXIT-CODE measurement error I caught via my own "suspect the measurement" note, no code churn).  (b) a
≥8B compound literal in a NON-direct context (ternary branch / call arg, which needs a temp+address path not yet
built) sets `CLOVF` -> emit_module returns 9 + `!!!CCSV_COMPOUND_LITERAL_OVERFLOW!!!` (LOUD build-refusal, never a
silent-wrong binary; `_cl16arg` exit=9 confirmed).  Floor 47 (correctness, not residue); run_ccsv green; ≤8B
unregressed (`_puint`=56, `_ptint`=99).  ★ Adjustment 1 (Ontological Pruning) ADOPTED as strategy: rewrite a gnarly
C seed construct (behavior-preserving, gcc-verified) when the ccsv fix would be riskier.  Adjustment 3 (2D
type-arity auditor) DEPRIORITIZED: the live bug class is struct-LAYOUT (caught by dbg field-count + value-check),
not SVIR stack-width (the SVIR is untyped 8-byte slots) — it wouldn't have caught #26/#27.

**FIX #29 — struct DOUBLE-pointer local `T **p = call()` (a real codegen gap; does NOT move the floor — honest).**
The `TypedefName *p` local handler did `C=C+2` (assumed ONE `*`), so `node_t **arr = iii_pool_array(..)` landed on
the 2nd `*` and DROPPED the init -> residue (`_g3a`/`_grow2` reproduced; `int **`/scalar `int32_t **` were already
clean — struct double-ptr only).  Fix: consume ALL `*`; `T *p`->struct ptr (LPT), `T **p`+ -> plain ptr whose
pointee is an 8B pointer (`*p`=LOAD64, exactly `*arr = nodes_p`).  `_grow2` clears + interp=1; 0 regression.  BUT
**floor stayed 47** — `iii_pool_grow` (idx 18) is DEEPLY MULTI-ORPHAN: nodes-pool fixed, mhash-pool clean
(`_gmh`/`_gmh2`/`_gmh3` all rc8=[]), yet the fn still rc=8 — a residual orphan in the for-loop / `sizeof(struct)`
arithmetic / another pool that the faithful repros don't capture.

**★ ADVISOR CORRECTION (confirmed empirically): the floor moves in FUNCTION-steps, not construct-steps.** The
remaining 47 are gnarly multi-orphan fns; a correct construct-fix (like #29) clears a CONSTRUCT but not a FUNCTION,
so the number doesn't budge until a fn's LAST orphan falls.  Two correct gated-green fixes this turn (#28 hardening,
#29 struct-dptr) moved the floor 0.  The rate 56→55→54→48→47→47→47 has stalled.  The discipline "value-check each
fix" is necessary but NOT sufficient — the missing rule is "spend the turn on FLOOR-MOVING work": pick a fn and
crush ALL its orphans (or rewrite it via Adjustment 1), don't stop at one construct.  Next: reduce-by-removal on
the REAL `iii_pool_grow` (edit ast.c, bisect) to find the residual orphan — OR pick a SINGLE-orphan fn to actually
drop the number.

**BACKLOG:** `iiip_parse_block` rc=8 (MULTI-ORPHAN, 2nd underflow @body-off 382).  `iii_pool_grow` rc=8 (residual
orphan beyond nodes/mhash).  Method: REDUCE/PROBE + confirm-by-removal + VALUE-check (UNDER 256!), per-fn, to the LAST orphan.

**FIX #25 — struct COMPOUND LITERAL `(StructType){f0,f1,..}` (≤8B), the seed's `(iii_ast_list_t){0u,0u}` (×17)** —
54→48 (parse 24→18, **−6**). ccsv read `(list_t){..}` as a CAST then a stray `{` -> the value mis-emitted ->
verify rc=8.  Fix (eprim `(`-handler, BEFORE the cast recognition): `( StructTypedef ) {` with `stidx>=0 &&
STSZ<=8` -> PACK the field inits into one value via shift/OR (no temp/frame): `econst(0)` acc; per field
`ebin(0); mask(hardcoded 0xFF/0xFFFF/0xFFFFFFFF by SFEL); SHL 8*SFOFF; OR`; un-given tail stays 0.  Leaves the
packed ≤8B struct-value (matches the ≤8B representation), so it composes in a ternary branch.  VALIDATED correct
(NOT just residue-clear): `_pcint`/`_puint` direct=56, `_ptint` ternary-of-literals=99, `_svtint` (the seed's
`cond ? commit() : (T){0,0}`)=99, `_cl_cast`/`_svcl`=99; all-4 + interp; 0 regressions (run_ccsv green).

**★ THE METHOD WIN (advisor): REDUCE/PROBE, never guess — and the gate is REMOVAL-confirmation + VALUE-check,
not residue-clear.** This turn the advisor's discipline corrected ~5 wrong hypotheses in a row: (1) "ternary is
the root" -> reduction showed the COMPOUND LITERAL is; (2) "iiip_parse_block clears with one fix" -> removal showed
it's MULTI-ORPHAN (the chunk-by-signature hope is DEAD — signatures cluster by the underflow SYMPTOM, not the
root); (3) "addr-below-control-flow ternary bug" -> the reorder fix REFUTED it; (4) "ternary-of-struct-VALUES is a
pre-existing value bug" -> a phantom: the repros used **bare `unsigned`** struct fields, which hit a SEPARATE bug;
(5) the real root of the wrong values = **`{ unsigned a; unsigned b; }` registers nf=1 sz=4** (2nd bare-`unsigned`
field LOST) — caught only by `ccsv file.c dbg` showing the field count. Lesson reaffirmed: a green/residue-clear
gate is not a correctness gate; confirm by removing the suspect AND checking the runtime VALUE.

**FIX #26 — bare type-SPECIFIER struct field (`unsigned`/`signed`/`long`/`short` with NO following dtype) — a
FLOOR-INVISIBLE SEED CORRECTNESS BUG.** `isqual` (ccsv.iii:162) classifies `unsigned`/`signed`/`long`/`short` as
qualifiers, so `reg_fields`' skipquals ATE them -> a bare `unsigned NAME` field lost its type, dropped the field,
and **mis-offset every field after it**.  `unsigned int NAME` survived only because `int` (a dtype) follows.  The
advisor caught that I'd ASSERTED "the seed uses uint32_t so it's unaffected" WITHOUT checking — it's FALSE:
`sema.c:218 unsigned ring_mask;` (field 2 of the annotation struct) hit this -> sema silently mis-handled ring
annotations + everything after ring_mask. rc=0 (no residue), wrong value -> **the floor metric could not see it.**
Fix (skipquals now tracks a bare specifier `sawspec`/`specsz`=4/4/8/2; the scalar branch registers `sq=q` the
NAME with that size).  Verified: `{unsigned a;unsigned b}`->nf=2 sz=8 (was nf=1 sz=4), `long`->8B, `unsigned
char`->1B, `unsigned int`/`const unsigned char *`/`uint32_t` UNCHANGED; floor stays 48 (correctness, not residue —
0 regression), run_ccsv green.  ★ This is the advisor's load-bearing lesson made concrete: **a green/residue-clear
gate is NOT a correctness gate.** A floor-invisible value bug in the seed (the thing being severed) outweighs N
residue clears — and the only way to find it was to grep the seed for the trigger instead of assuming.

**BACKLOG (separate):** ≥8B compound literals `(iii_src_pos_t){0,0,0,0}` (16B) still fall to the broken cast path
(FIX #25 guards `STSZ<=8` — needs a temp+address path).  `iiip_parse_block` remains rc=8 — MULTI-ORPHAN (a 2nd
underflow at body-off 382 beyond the compound literal).  Signature-clustering is DEAD as a chunk strategy
(clusters by underflow SYMPTOM, not root — proven by removal this turn).  Method going forward: REDUCE/PROBE +
confirm-by-removal + VALUE-check, per-function.

**FIX #24 — enum-typedef-name CAST `(kind_t)expr`** — 55→54 (parse 25→24, `iiip_binop_for`). `is_type_start`
recognized a typedef-name cast only when `stidx>=0`; enum typedefs (registered as members, not as a struct type,
`stidx<0`) were missed, so `(iii_binop_t)tbl[i].op` fell to the comma/paren path -> the RHS value never emitted ->
`STORE32` underflow (the missing-value the trace showed). Fix (eprim `(`-handler, after the standard cast block,
before the comma fallback): `( NAME ) <expr-start>` where NAME is an UNKNOWN identifier (`stidx<0 && lidx<0 &&
abase<0 && cidx<0 && !label-kw`) and the `)` is followed by an expression-start token -> treat as an enum/forward
typedef cast = **i64-noop** (`C+=3; eprim()`; the destination store truncates; safe for negatives). Behaviorally
certified all-4=99 + svir_interp=99 (`_ec2.c` `int y=(kind_t)x`, `_ecast.c` the iiip_binop_for shape); 0
regressions (run_ccsv green, only crosslang).

**★ TOOL: the SVIR Stack Auditor is `_ve_trace.iii` (NOT a new svir_stack_audit.iii — that would duplicate it).**
`_ve_trace` IS the opcode-arity stack-depth walker (mirrors `verify_body`'s per-opcode `depth` delta = the
proposed `OP_DELTA`/`sp`). Enhanced to **dual-mode**: `TARGET>=nfunc` -> SUMMARY (idx rc BND ufOff per rc=8 fn);
`TARGET<nfunc` -> full TRACE (`off:op:depth | <<O`) of that function. It pinpointed `iiip_binop_for`'s underflow
at offset 346 (STORE32) -> enabled isolating the `(EnumTypedef)` cast that 4 structural repros missed. (The `<<O`
boundary-residue flag is NOISY — a false-positive at mid-statement depth; the UNDERFLOW offset is the clean pin,
which `_ve_trace` already reports. The user's Phase-3 "embed before sks_prove" decorates the membrane island —
skipped.)  The factory: `run_residue_hunt.sh <module>` -> first rc=8 fn + its C body ; `_ve_trace` TARGET=<idx>
-> the orphan opcode ; isolate -> fix -> `run_ccsv.sh` gate. This is the per-function loop for the heterogeneous tail.

**FIX #23 — chained struct-field assignment (`out.a = out.b = out.c = 0`), the DOT field-assignment-EXPRESSION** —
56→55 (parse 26→25, `iiip_node_pos`). ccsv handled `v.field = e` only as a STATEMENT (consume+drop); chained,
the inner `out.b = ..` is an EXPRESSION that must leave its value -> the unconsumed values were the rc=8 residue.
Fix (ebin minp==0, the DOT complement of the existing `s->field = rhs` ARROW handler): on `ident.ident =`
(avtype>=0, not `==`/`.f.f`/`.f[i]`), `emit_vbase(C,foff)` (frame-aware) ; rhs ; mask ; SET tmp ; GET tmp ; STORE ;
GET tmp -> **store AND leave the value** so the chain folds. Behaviorally certified all-4=99 + svir_interp=99
(`_chainfld.c`: `out.a=out.b=out.c=out.d=7` -> 14); 0 regressions (run_ccsv green, only crosslang). The
falsifier-loop continues: emit/ast/cg_r3 residue fns have ADDITIONAL constructs beyond the chain (each its own
decode→repro→fix→gate). NOTE: the floor work is now runtime-unblocked by BOTH bosses (Boss-1 recursive-&local +
Boss-2 recursive struct-value local, SHADOW_ON=1 default) — a cleared fn will RUN correctly in recursion.
Each fix below is **behaviorally certified** (its own `test_X.c` → verifier + sovereign-x86 + wasm + gcc all
99) and **regression-clean** (the full ~30-case `run_ccsv.sh` crypto/feature suite stays green). The ONLY red
in `run_ccsv.sh` is the **pre-existing** `crosslang=NO` (committed drift between test.c and indep_toolchain.iii;
a Φ3 conscience-sweep item, NOT introduced here — **empirically re-proven 2026-06-26**: `ccsv(test.c)` is
byte-identical with/without fix #21, and `crosslang=NO` holds with fix #21 reverted).

| # | Fix | Lever | Root |
|---|-----|-------|------|
| 1 | else-if misparse (`is_ctrl_kw` guards `is_fn`) | −75 | `} else if (c) {` matched the typedef-return-fn pattern → a spurious `if` fn per else-if |
| 2 | wasm nested-return (`cfn` last-top-level-stmt) | wasm | a return nested in if/loop skipped the trailing default return → wasm empty-stack fallthru reject |
| 3 | BUG-A: `reg_type` skips field qualifiers | layout | `const uint8_t *src` registered the TYPE as the field name + int(4) |
| 4 | BUG-B: forward-ref embedded structs (reg_fields fixpoint) | −15 | `iii_arena_t arena` sized as int(4) because its struct was registered LATER |
| 5 | `call()->field` (`fn_ret_struct`) | −2 | field access on a fn-call result (parser `iiip_peek2(st)->kind`) |
| 6 | designated-init arrays (move prescan_enum; named-const size + `[Di]=`) | −2 | `static const char *NAMES[CONST]={[X]=v}` kind-name tables |
| 7 | `sizeof(p->arrayfield)` (SFSZ + esizeof) | −3 | `memset(out->mhash,0,sizeof(out->mhash))` left dangling `->field` tokens → stray DROP |
| 8 | `p[i].field` read+store (LPT-driven elem+field) | −1 | pointer-indexed struct-element field `s[0].id` emitted a `0x00` opcode (iii_intern_grow) |
| 9 | **global `g++`/`g--` statement** (abase + load/+1/store) | correctness | the `NAME++;` stmt handler emitted only for locals (`li>=0`); a **global** scalar fell through to a NO-OP → the increment was silently dropped. Found via the Boss-1 ceiling hunt (frame-independent); `test_globalinc.c` all-4=99. |
| 10 | **global `g op= e` compound-assign** (`+=`/`-=`/`*=`/…) | correctness | SAME class as #9: the `x op= e ;` stmt handler emitted only for locals; a **global** scalar `g += x` fell to a NO-OP → silently dropped (`g = g+x` worked, `c->v += x` worked — only globals broke). Found via the Boss-1 hunt (my "uint64-shift-to-call" latent repros were really this — `callee`'s dropped `gs += x`). `test_globalinc.c` extended, all-4=99; frame-independent (helps the floor). |
| 11 | **global prefix `++g`/`--g`** (`elvalinc` global case) | correctness | SAME class: `elvalinc` handled only locals (`li>=0`); a global `++g` fell to `eprim()` (a plain READ, no store) → increment dropped. Added the global load/±1/store (pre→new, post→old). `test_globalinc.c`, all-4=99. |
| 12 | **global pointer init `*p = &G`** | correctness | the file-scope scalar-init handler wrote `= numeric` and `= named-const` but **dropped `= &GLOBAL`** → the pointer stayed 0. Added `&NAME`/bare-global-decay → `data_putn(abase(NAME))`. Write/modify through the now-correct pointer (`*p=e`, `*p+=e`) certified. `test_globalptr.c`. |
| 13 | **global pointer deref-READ `*gp`** (rvalue, direct dtypes) | correctness | the deref fallback did a single `LOAD64` → read the POINTER's address, not `*p` (needs TWO loads: `LOAD64(gp value)` then `eload(pointee)`). Added APSZ/APSG (pointee width+sign, mirror LPSZ/LPSG) + a global-pointer deref case. `int*/unsigned int*/char*/unsigned char*` read/store/compound, widths {4,1}, all-4=99; **teeth: a width-mutant reddens the gate** (x86 1 vs 99); discharge `ccsv.iii:641`. SCOPE: typedef'd global SCALARS + `short`/`long` are pre-existing separate gaps (a bare typedef/`short`/`long` global scalar fails with no pointer — the `dtype(q)` gate), out of scope. |
| 14 | **for-init DECLARATIONS of non-int type** (`for(unsigned k=0;…)`, `for(const T *c=…)`) — **SEED 85→83** | structural+correctness | `for_init` gated on `dtype(C)` AFTER `skipquals()`, but `unsigned`/`signed`/`long`/`short` ARE `isqual` → skipquals ate them; typedef/struct-pointer types also fell to the for-init EXPRESSION path → it eval'd the *type name* as an expression → under-emit → **verify-fail**. Fix: detect the decl BEFORE skipquals (`is_type_start` + the opaque-pointer pattern, mirroring pstmt), capture the sign, robust base-skip, and set `LPT` so `c->field` resolves. Found by categorizing the 85 (svir_dis) → reproducing `for(unsigned…)`/`for(T*…)`. **First metric move: 85→83** (lex 6→4); `test_forinit.c` (unsigned/signed/multi-int) all-4=99; regression-clean. Pointer for-inits now VERIFY but their runtime is gated by a SEPARATE pre-existing bug — `local *p = &GLOBAL_struct; p->field` (no loop needed) — repro `_latent_local_structptr_to_global_deref.c`, the likely behavioral gate for the seed's list-walk idioms. |
| 15 | **multi-star local declarator `T **p = e`** (the pool-accessor init) | correctness | the local-decl declarator skipped only ONE `*` (`if cp(Q_MUL)`, not `while`) → for `int **pf = call()` the name landed on the 2nd `*`, `pf` was never registered, and the init **call's result was DROPPED** (verify-fail + wrong runtime). Single-pointer worked (control). Fix: `if`→`while` (skip all stars) + track depth so a double+ pointer's pointee width is 8. `test_dblptr.c` (`T**=call`, `*pf`, deref-to-local index) all-4=99; regression-clean. SEED still 83 — the seed's pool accessor `&(*pf)[slot]` needs the COMPANION gap too: **`(*pf)[i]`** — postfix `[i]` on a PARENTHESIZED base drops the index (needs pointee-of-pointee stride: `int**`'s inner element is `int`=4, not the tracked `LPSZ`=8). Repro `_latent_paren_deref_index.c`. Also found (real, NOT seed-relevant — seed has 0): global struct VALUE initializers `static T g={…}` are dropped (struct allocates + runtime-writes fine; only the `={…}` init). |
| 16 | **`(*pp)[i]` / `&(*pp)[slot]`** — the pool-accessor element ops (companion to #15) — **SEED 83→82** | structural+correctness | postfix `[i]` on a PARENTHESIZED base `(*pf)[i]` dropped the index (the `(…)` handler returned without consuming `[i]`). Added an `LPP` field (ULTIMATE element size = base type, distinct from `LPSZ`=immediate-pointee=8 for a `T**`), set at the pointer declarator; handle `&(*ident)[i]` in the `&` handler and `(*ident)[i]` rvalue in the eprim paren handler — both as `LOAD64(ident)` then `i*LPP + …`. With #15 the double-pointer pool accessor is COMPLETE (init + `*pf` + `(*pf)[i]` + `&(*pf)[slot]`). `test_dblptr.c` (full) all-4=99; **seed 83→82**; regression-clean. |
| 17 | **`(*pp)[i] = e` STORE through a dereffed double-pointer** (companion to #16's read) — **SEED 82→78** | structural+correctness | `pstmt` had no `(…)`-lvalue handler, so `(*bd)[slot] = v` (the seed pool write, e.g. `iii_ast_set_binder_id`) fell to the expr-statement `ebin+DROP` → the store's value under-emitted → **eval-stack underflow (rc=8)**. The READ `(*pp)[i]` was already handled (eprim:680); added the symmetric STORE in pstmt: `LOAD64(ident)` then `i*LPP + offset` address, `eat(=)`, `ebin(e)`, `estore(LPP)`. Found by `svir_dis` depth-trace (the `83@-1`/`72@-1` underflow signature) → reproduced `(*bd)[i]=e`. `test_dblptr_index.c` (read+store) all-4=99; **seed 82→78** (ast 23→19, 4 pool functions whose last blocker this was); regression-clean (run_ccsv 1 FAIL = crosslang). |
| 18 | **brace-init struct local `Foo h = {e0,e1,…}`** — **SEED 78→71** | structural+correctness | the struct-value-local init handler did `ebin(0)` which cannot parse `{…}` → the init store got a value but no address (`83@-1`) → **underflow**. Added a brace-init case: for each comma element store it to field `STFB[stc]+i` at offset `SFOFF`/width `SFEL`, then zero the un-given tail (C `{0}` semantics). The seed's `iii_ast_list_t h={0,0}` (list/walk-state commits) + many position/state inits. `test_brace_init.c` (full + partial `{0}` + struct-return) all-4=99; **seed 78→71** (−7 across ast, parse, lex, sema, emit); regression-clean. |
| 19 | **nested struct field on a struct-array element `p->arr[i].sub.subsub` + the inline-array-base `fe==8` bug** — **SEED 71→70** | structural+correctness | the `p->arr[i].subfield` read (eprim:823) + store (pstmt:1242) handlers stopped after the *first* subfield (`C=C+2; eload/emit_av`), leaving a trailing `.subsub` dangling → malformed opcode (**rc=2**) on the seed symbol-table idiom `cg->locals[i].name.length`. Extended both to continue the member chain via `fieldpt` (mirror of the `p->f0.f1.f2` handler). Isolation then exposed a *separate pre-existing* bug: the **inline struct-array field** base (`local_t locals[8]` inline) wrongly `LOAD64`s the field as a pointer — the read guarded on `fe==8`, the store LOAD64'd unconditionally; both now gated on `fieldisarr==0` (pointer only). `test_nested_field.c` (ptr + inline bases × nested + single, read+store) all-4=99; **seed 71→70**, now behaviorally valid (not a structural-only pass); regression-clean. |
| 20 | **`SRET_ON=1`** (struct-by-value return master switch enabled) — **SEED 70→69** | feature-enable | the hidden-pointer sret ABI for `T x=f()` struct-VALUE returns + struct-VALUE params (copy-in) turned on (ccsv.iii:182); gated by `test_structparam`/`test_structval` all-4=99. Net floor 70→69. |
| 21 | **`call(...).field` on a struct-VALUE (sret) return** — **SEED 69→66** (2026-06-26) | structural+correctness | the COMPLEMENT of fix #5: #5 handled `call()->field` for a `StructType *` (pointer) return (`fn_ret_struct`); but a function returning a struct **BY VALUE** (sret, `fn_ret_sval`, e.g. the seed's `iiip_node_pos(st,id)` returning `iii_src_pos_t` 16B) followed by **`.field`** (DOT) had NO handler — the bare-call path emitted `CALL` with no hidden dest, left the result unconsumed, and the `.field` dangled → parser desync → **eval-stack residue → underflow (rc=8)** and one **rc=2**. Fix (eprim:752, dest-FIRST like `T x=f()` at pstmt:1075): on `fn_ret_sval(fn)>=0` AND a `.` immediately after the matching `)`, allocate a temp buffer (MTOP), push it as the hidden sret arg0, emit the visible args, `CALL fi (dest+args)`, `DROP` the dummy result, then load the `.field` (incl an inline `.f.f` chain) from the buffer. **Behaviorally correct** (the store happens to a real buffer; the field is read from it), not a structural mask — **certified by an executed KAT** `STDLIB/sovir/test_callfield_sret.c` (wired into `run_ccsv.sh` cfeat): `mkpos(3).b==13, mkpos(5).c==10, mkquad(7).hi==107, mkpos(2).a+mkquad(1).top==203` agree **all-4 = 99** (verifier + sovereign-x86 + wasm + gcc), the same standard as fixes #1–19. Verified through the advisor's 3-part gate: **(1)** seed 69→66; **(2)** per-fn rc diff = 0 regressions, 3 fixed (parse idx 44 `iiip_parse_arg` 8→0, idx 49 `iiip_parse_type_simple` 2→0, idx 79 `iiip_parse_struct_decl` 8→0); **(3)** `run_ccsv` cfeat all-99, `crosslang=NO` proven pre-existing (test.c byte-identical with/without — verified by reverting the fix). **CAVEAT (advisor):** the temp dest is a fixed-MTOP address (the same class the Boss-1 §documents as a reentrancy risk); SAFE here because the buffer is consumed within a single statement and the only seed caller `iiip_node_pos` is non-recursive — but a future `f().field` where `f` can re-enter before the load would need an SSP-relative dest (fold into the Boss-1 rework). **This is one piece of the documented sret-struct-by-value critical path (§"remaining is DOMINATED by struct-by-value")** — it clears the *rvalue field-extract* sub-case; the bulk (struct-by-value **params/returns in recursive** parse/sema fns) remains gated on the Boss-1 shadow-stack rework. Root-cause instrument added: `STDLIB/build/sovir/_ve_trace.iii` (per-fn `verify_body` mirror that buckets underflows by root: residue-accumulation / mis-parse / missing-operand). |
| 22 | **ENUM / forward-typedef-name LOCAL decl** (`kind_t x = e;` / `kind_t y;`) — **SEED 66→56, lex.c → 0** (2026-06-26) | structural+correctness | the seed's `iii_abi_kind_t abi = decl->u.extern_decl.abi;` (`sema_check_extern_abi`) + 9 more across lex/parse. ccsv registers enum **members** (`cidx`→CNV) but never the enum's typedef **name** as a TYPE → `kind_t localvar` (two identifiers, `stidx<0`) was unrecognized → fell to the expr-stmt path → **leading-DROP eval-stack underflow (rc=8)**, which DESYNCs the whole function (cascade). The param loop (`cfn:~1721`) and struct-field loop (`reg_type:~1602`) already consumed an unknown typedef-name as a scalar; the **local-var-decl** path (`pstmt`) lacked it. Fix (`pstmt`, after the struct-VALUE-typedef block): a TIGHTLY-guarded case — C an identifier that is `is_type_start==0` AND `is_label_kw==0` AND `stidx<0` AND `lidx<0` AND `abase<0` AND `cidx<0`, C+1 a name, C+2 a scalar terminator (`;` or `=`) → register C+1 as an i64 scalar local (`LW=0,LSZ=8,LSG=0`), emit the init (`ebin;emit_lset`) or nothing. `T a,b`/`T a[N]`/`T a(..)` stay the old skip; **registered** struct typedefs (`stidx>=0`) are untouched (the struct-VALUE path above still owns them). **Behaviorally certified** `STDLIB/sovir/test_enumdecl.c` (wired into `run_ccsv.sh`): `kind_t x=b->k` arrow-init + `kind_t y;` no-init + a registered-struct `box_t bx` with `.field` — **all-4=99** (verifier + sovereign-x86 + wasm + gcc). 3-gate: **(1)** 66→56 (−10); **(2)** 0 regressions (per-fn rc diff); FIXED: lex 35/36/37/38, sema 29, parse 36/46/55/81/83; **(3)** `run_ccsv` cfeat all-99, crosslang=NO pre-existing. **`lex.c` reaches STRUCTURAL ZERO** — the de-risk milestone (a non-recursive module at 0; behavioral end-to-end of lex is the next confirm). The cascade is why one decl-recognition fix cleared 10 functions. ★ **AUDIT (advisor-demanded, tested not reasoned):** the fix's `stidx<0` guard fires ONLY on enum-kind locals (`iii_token_kind_t`/`iii_abi_kind_t`/`iii_schema_field_kind_t` — registered as members, name stidx<0); the struct-by-value locals those 10 fns also declare (`iii_token_t` stidx=0 sz=104, `iii_src_pos_t` stidx=4 sz=16, `iii_ast_list_t` stidx=2 sz=8 — **all REGISTERED**, verified via `ccsv … dbg`) are UNTOUCHED (struct-value path owns them). So **NO false-pass** (no scalar-ized struct). **CALIBRATION:** the enum-decl *construct* is certified all-4=99 (the KAT); the 10 *seed functions* are **STRUCTURALLY cleared** — their full RUNTIME correctness, where they pass/return `iii_src_pos_t`/`iii_token_t` BY VALUE inside recursive-descent parsers, is the **pre-existing Boss-1-gated residue** (NOT introduced here). "Behavioral confirmation" of the seed fns themselves awaits the linker / a lex.c end-to-end run / Boss-1. |

★ The prior session's unpinned **fn70** (LD4-vs-LD8 on `iii_lex_arena_bytes`, HARD-STOP at 38 rounds) is
**SOLVED** — it was BUG-B (the field registered as int(4)), one layer above the eprim eload sites they searched.

## ★ CRITICAL PATH the structural count HIDES (advisor-confirmed)
Driving 86→0 is **necessary but NOT sufficient** for the trust floor. Confirmed-live blockers off the count:
1. **Reentrancy / shadow-stack — CONFIRMED BROKEN.** A recursive struct-value KAT runs `vf=99 x86=1 wasm=1
   gcc=99`: `&local`/struct-value spills use a FIXED MTOP address → clobber across recursion. parse.c + sema.c
   are recursive-descent, so their runtime correctness (and **struct-by-value**, below) is gated on landing the
   shadow-stack fix (core-proven y1/y2 CRASH→99 last session but reverted on a ceiling_sha_full x86 regression).
2. **Cross-module linking** — the 6 seed modules call each other (ccsv's CALL is a 1-byte intra-module index).
3. **Runtime library** — fopen/fwrite (emit.c I/O), etc.

## ★ The remaining 85 is DOMINATED by ONE feature: struct-by-value (measured, all 4 core modules)
Not scattered parser bugs — the bulk is **struct-by-value** (`iii_src_text_t`, `iii_ast_list_t`, `iii_src_pos_t`
passed/returned BY VALUE) + **recursion**, both gated on the **shadow-stack** reentrancy fix:
- parse: `iii_src_pos_t` (iiip_node_pos/pos_of/pos_span) ; sema: `iii_ast_list_t args` (sema_decode_hexad_args) ;
  cg_r3: `iii_src_text_t name` (local_lookup_slot, emit_field_label) ; ast: `iii_ast_list_t` return (list_commit).
- **The focused next effort (THE critical path):** (1) land the shadow-stack reentrancy rework so spill/struct-value
  addressing is SSP-relative not fixed-MTOP (recursive struct-value KAT goes GREEN; resolve the ceiling_sha_full
  x86 regression that reverted it last time — better tools now); THEN (2) the hidden-pointer/sret struct-by-value
  ABI (reuses p->field + emit_bcopy + call()->field infra). **Gate MUST be a recursive struct-value KAT** or it
  falsely-blesses (advisor). This single feature+prerequisite clears the large majority of the remaining 85.
- Decode-heavy tail (smaller, non-blocked): scanner helper-call chains (iii_scan_*), I/O subsystem (fopen/fwrite
  in emit), local-typedef + linked-list (iii_lex_seal), `call()[i]`, global struct initializers, macro bodies,
  fn-pointers → CALL_INDIRECT (Φ1.3). Then Φ1.4 completeness (`nfunc==source fns`) + Φ1.5 run_seed_sovereign.sh.

**De-risk milestone (advisor):** when a *non-recursive* module (lex is closest, 7 left) hits structural-zero,
run it behaviorally end-to-end (diff vs gcc) BEFORE chasing the next module's count — that catches verify≠runtime.
See memory `project_iii_ccsv_seed_codegen_gaps` UPDATEs 60-63 for the full detail.

## BOSS 1 (shadow-stack reentrancy) — Step 1 IMPLEMENTED, mechanism PROVEN, GATED OFF (ceiling regression unpinned)
Implemented the advisor-designed **fb_local** shadow-stack for `&local` spills behind a master switch
`SHADOW_ON` (ccsv.iii:181, **default 0 = OFF = the protected floor**). Sites: SSP cell + `emit_frame_addr`/
`emit_ret` + prologue + `ladd`/`emit_lget`/`emit_lset`/`&local` + the 3 RETURNs, all `if SHADOW_ON`-gated.
- **PROVEN (SHADOW_ON=1):** recursive `&local` KAT `recur(&x)` runs **vf/x86/wasm/gcc=99** (was x86-clobber).
  The fb_local design (frame base in an SVIR local, `LOCAL_GET fb+off`, cell touched only prologue/epilogue) is
  svir_x86-safe (the advisor's predicted sidestep held — the isolation `cell-load→+off→store` is all-99).
- **Found+fixed a real design bug:** `SSP_CELL=8` collided with the program's LOW global data (the SSP write
  corrupted a global) → moved to a reserved cell `982776` (just below FMT_SCRATCH, above the shadow region).
- **BUT regresses `ceiling_sha_full` at SHADOW_ON=1** (x86=1 AND wasm=1 = an SVIR-logic interaction, not
  addressing). **UNPINNED after ~13 faithful isolations + 3 disassemblies** — every faithful repro (frame main,
  nested frames, &scalar-in-loop, uint8_t &locals, large struct w/ buf[64], void*-cast + memcpy-in-while, struct-
  field index) PASSES; only the EXACT 5-fn ceiling program triggers it. cl_sha_final's disassembly is correct
  (prologue + pad spill + &pad pass all right). So **GATED OFF (SHADOW_ON=0)** per the advisor's decision rule →
  floor restored: ceiling/crypto green, seed 85, 25 milestones.
- **★ NEW pre-existing bug found (frame-INDEPENDENT, fails with Boss-1 OFF too):** `for(i<n){ g_arr[g_idx]=p[i];
  g_idx++; }` — a global-array store indexed by a **global** modified in the loop — runs x86=1/gcc=99 (repro
  `_n1.c`). NOT in the seed's idioms (it uses struct-field/local indices) but a genuine codegen defect for Φ3.
- **Boss 2 (sret struct-by-value): NOT started.** Also needs Step 2 (struct-value `LVB` shadow stack): the
  recursive struct-value KAT `_svr.c` stays x86=1 even at SHADOW_ON=1 (Step 1 only relocated `&local`/`LMEM`).
- **Conscience verdict — Boss 1: STATED-NOT-DISCHARGED** (realized + recursive-&local falsifier green; the
  ceiling falsifier reddens → gated off, not PROVEN-IN-CODE). **Boss 2: not started.** The horizon is NOT closed.
- **Next-session focused task:** with SHADOW_ON=1, disassemble the REAL ceiling cl_sha_final's `while(buflen!=56)
  cl_sha_update(&zero)` loop + the lenbe/out interaction, diffing the &zero address-comp against a known-good
  frame access in the SAME binary (the advisor's "read the hex at the fault" — the 5-fn program emergent bug).
- **★ DEEP NARROWING (digest-diff bisection, 10+ DBG probes — eliminates almost everything):** Boss-1 ON digest
  `2fc1808a…` (vs correct `ba7816bf…`; floor matches gcc). Systematically RULED OUT: main's frame (global-ctx
  still fails), the `&pad`/`&zero` padding (c->buf[0..63] PROVEN correct — DBG4+DBG7), c->h corruption (c->h=H0
  PROVEN correct before the block — DBG10), `cl_sha_block` itself (CORRECT called directly from a frame fn with a
  hand-built block — DBG8), `cl_sha_update` as intermediate (CORRECT for a single 64-byte update from a frame fn
  — DBG9), lenbe local-vs-global (BOTH fail). **The bug fires ONLY in the full 54-separate-update path** (pad +
  52×&zero-loop + lenbe → triggers cl_sha_block) — and at the trigger, c->buf AND c->h are PROVABLY correct yet
  the block's output is wrong+deterministic. ⇒ **the corruption is in EXECUTION-STATE (a register / eval-stack
  residue the 54-update path leaves), invisible to any C-level probe — only x86/wasm single-stepping pins it.**
  This is the exact, defensible boundary: ccsv's shadow-stack *codegen* is correct (disassembly + 13 isolations);
  the defect is a backend/runtime state-residue triggered only by this emergent multi-update pattern.
- **★★ ROOT NARROWED TO ONE STATEMENT (minimal repro pair saved):** `STDLIB/sovir/_boss1_ceiling_FAILS_on.c`
  (cl_sha_final's `unsigned long long bits=…; lenbe[i]=(uint8_t)(bits>>(56-8*i))`) FAILS at ON; the IDENTICAL
  file with lenbe hardcoded (`_boss1_ceiling_WORKS.c`) is CORRECT at ON. **That single uint64 variable-shift
  loop computing lenbe is the entire trigger.** BUT it's **context-sensitive**: a standalone uint64 var-shift
  loop in a frame fn (`_u64.c`) works fine ON+OFF — the corruption fires ONLY when the uint64-shift lenbe is
  *followed by* the `cl_sha_update(lenbe)`→`cl_sha_block` sequence. The lenbe VALUES are provably correct
  (DBG7), so the uint64-shift leaves an execution-state residue that the subsequent block-call mishandles —
  deterministic on BOTH x86 and wasm, invisible to any C probe. **NEXT: build a SVIR value-tracer (.iii
  interpreter over gen_svir) — execute `_boss1_ceiling_FAILS_on.c`'s SVIR and trace the diverging local/stack
  vs OFF; that's the single-step substitute and the definitive pin.** (Repro is 1 statement → the trace is short.)

### ★★ BOSS-1 RE-OPENED (2026-06-26) — the regression is a ccsv SVIR-CODEGEN bug, NOT a backend bug
The UPDATE-63 conclusion ("ccsv codegen correct; backend execution-state residue") is **OVERTURNED**, decisively
and reproducibly. THE EXPERIMENT (`SHADOW_ON=1`, `_boss1_ceiling_FAILS_on.c` → ccsv → both backends): sovereign-x86
AND wasm print the **byte-identical** wrong digest `2fc1808a…` (correct `ba7816bf…`). ADVERSARIAL CHECK (the
"independent backends" hypothesis, iii_adversarial_verify): `svir_x86.iii` + `svir_wasm.iii` extern ONLY
`svir_ptr/svir_len` (the raw SVIR bytes), share NO decoder, each has its own dispatch loop → two INDEPENDENT
executors agreeing on the same wrong digest ⇒ **the SVIR bytes encode the wrong computation** ⇒ a ccsv codegen
bug (`svir_verify=99` structural, but semantically wrong). Conscience verdict **SURVIVES (high)**; the
shared-decoder escape is ruled out. TRIGGER (surgical FAILS-vs-WORKS diff): the single differing expression
`lenbe[i]=(uint8_t)(bits>>(56-8*i))` (uint64 VARIABLE-shift) vs the constant ternary — so the bug is **how ccsv
emits `uint64 >> variable` at SHADOW_ON=1**, corrupting shared state (SSP_CELL / a slot) read by the SUBSEQUENT
`cl_sha_update→cl_sha_block`. Context-sensitive: `_b1min.c` (var-shift + frame + a SIMPLE subsequent call) does
NOT repro (x86@ON=wasm@ON=99) — it needs the 54-update nesting. **The old "disassemble the backend" next-step is
WRONG** (no backend bug exists). **CORRECT NEXT:** build the reference SVIR value-tracer (executes `gen_svir`
faithfully with memory+calls+the exact SSP_CELL=982776/SHADOW_TOP=917504 layout) — a 3rd independent executor
that confirms ccsv a 3rd way AND traces the exact diverging SSP_CELL/slot vs the WORKS run → pin the codegen bug →
fix ccsv → gate on recursive-struct-value KAT + ceiling_sha_full BOTH green at SHADOW_ON=1. Floor protected
throughout (every experiment toggled `SHADOW_ON` and reverted to 0; SHADOW_ON=0 confirmed, conform.exe=99).
**Conscience status: attribution DONE + SURVIVES-high; the exact-opcode pin + the codegen fix REMAIN (the tracer
is the scoped fresh-focus build).**

### ★★★ BOSS-1 FIXED (2026-06-26) — SHADOW_ON=1 is now the DEFAULT; the reverted shadow-stack is live
Built the reference SVIR value-tracer `STDLIB/sovir/svir_interp.iii` (a 3rd INDEPENDENT executor: full ISA +
memory + CALL stack). FAITHFUL (prints `ba7816bf` for the OFF SHA) and REPRODUCES the bug (`2fc1808a` for the ON
SHA — a 3rd confirmation, shared-decoder escape eliminated). Its const-data-corruption watch (any STORE below the
data length) **PINNED** the root: at ON, `mypad` writes `pad`/`zero` into CL_K@32/40 because the frame-base value
was **24** = its `bits` local — **`CUR_FB` (frame-base slot) collides with the 1st body local**. The prologue
reserved `CUR_FB=LN; LN++` but never bumped `NLOC`, so the per-statement `LN=NLOC` reset reclaimed `CUR_FB`'s slot
and `bits=24` clobbered the frame base. **FIX (ccsv.iii:1749, 1 line):** `if LN>NLOC {NLOC=LN}` — the EXACT idiom
already at `ladd:229` + switch-selector `1217`, missing only here. **VALIDATED @SHADOW_ON=1+fix:** recursive-&local
KAT all-4=99 + svir_interp=99 (OFF crashes it); ceiling_sha_full x86+wasm+verifier+gcc all 99 == ba7816bf;
run_ccsv green (only pre-existing crosslang); **seed floor 56 unchanged**. Conscience: adversarial_verify
**SURVIVES-high** (fix is monotonic; teeth = removing it reddens ceiling; OFF inert), check_discharge
**DISCHARGED @1749**. **SHADOW_ON=1 is now the default** (`ccsv.iii:181`) — the ceiling regression that forced OFF
for ~13 prior-session isolations is GONE. ★ New durable tool: `svir_interp.iii` (the reference oracle).
**REMAINDER (Boss-2):** struct-VALUE `LVB` locals still fixed-MTOP at ON → recursive struct-value
(`iii_src_pos_t`/`iii_token_t` by value in recursive parse/sema) still breaks; Boss-2 = make `LVB` frame-relative
like &-taken scalars. The 56 structural residue is struct-by-value CODEGEN (rc=8 stack residue) — separate codegen
work. Both are the remainder; Boss-1 (&local recursion + ceiling-clean) is DONE.

## NEXT TARGETS pinned (2026-06-26, post fix #21, floor 66) — root-bucketed by `_ve_trace.iii`
The 66 = 63 rc=8 (eval-stack underflow) + 3 rc=2. The 63 rc=8 bucket by ROOT (boundary-depth discriminator):
- **60 RESIDUE (accumulation)** — DOMINATED by struct-by-value params/returns in **recursive** parse/sema
  (`iii_src_pos_t`/`iii_ast_list_t`/`iii_src_text_t` by value). **GATED on Boss-1 shadow-stack** (UPDATE 63,
  STATED-NOT-DISCHARGED) — the recursive-struct-value KAT is verify-99-runs-wrong until SSP-relative spills land.
- **3 MIS-PARSE (non-blocked, distinct roots — the tractable next fixes):**
  1. `sema_check_extern_abi` (sema 29) — `iii_abi_kind_t abi = decl->u.extern_decl.abi;`: an **unregistered
     typedef'd-enum LOCAL decl** → not recognized as a decl → falls to expr-stmt → leading-DROP underflow.
     (Enum-typedef PARAMS + FIELDS already handled — UPDATE 8; this is the local-VAR-decl case.)
  2. `iii_pool_mhash` (ast 14) — NOT the `(**)[N]` declarator (that IS handled: `fn_nametok:1359` finds the
     name inside `(**name(...))`, `fn_has_body:1392` skips the trailing `)[N]`). The remaining failure is a
     **body/boundary anomaly** — its measured `blen=21153` is absurd for a tiny `switch(pool){case…return
     &ast->field;}`, so the per-fn body length is mis-computed (the switch + `return &ast->field`, or a
     boundary drift from a neighbour). A fresh decode (the value-tracer / a minimal `(**)[N]`+switch repro).
  3. `iiip_parse_modifier_after_at` (parse 46) — **CLEARED by fix #22** (its first bad decl was the enum-kind
     local `iii_token_kind_t k`); so post-#22 only ONE non-residue mis-parse remains: `iii_pool_mhash`.
- The whole-program driver + the residue ratchet + the conformance gate (`au_conform_bound`) are membrane
  capabilities, NOT consumers of the seed pipeline — they do not move this floor.
