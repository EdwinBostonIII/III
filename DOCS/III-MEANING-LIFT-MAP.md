# III — THE MEANING LIFT (Θ): the summit above germination

> **Θ0 EXECUTED + GREEN (2026-07-09, same session as the location pass).** The definitional
> evaluator EXISTS and is gated: `COMPILER/BOOT/eval.iii` (+`eval_main.iii`) built by
> `build_iii_eval.sh` from {cg_sha, lex_rt, lex, ast, parse} + the evaluator — sema/sid/cg/emit/link
> provably absent from the binary (the link closure is the independence proof).
> `run_meaning.sh` verdict (same-session final): **selftest 3/3 arms · probe floor 16/16 · corpus
> differential 110/112 pass · 0 divergence · 0 unsupported · ratchet pinned 110 (up-only)**. The
> ONLY exclusions are 2 eval-timeouts (1865/1870 heavy solver islands; the tree-walker is a
> definitional object, not a fast one) — every other semantically-reachable extern-free KAT agrees
> across both meaning-bearers. Falsifiers all two-path-proven:
> evaluator teeth (ADD sabotage → p02 rc=1; restore → 99), comparator DIVERGE arm (fake route),
> UNSUPPORTED-never-PASS arm (match construct). **The instrument fired in production on its first
> differential run** — divergence ledger row 1 (signed `>>` is LOGICAL) is the first machine-pinned
> semantic fact of the .iii language.
>
> **SESSION 2 (2026-07-09, same day): the instrument's compiler-side catches FIXED.** Ledger rows
> 6 (partial-init global-array tail aliasing) and 7 (const-array addressing SIGSEGV) closed in
> cg_r3; the sovereign assembler gained the missing `.short` arm (u16 data was silently dropped).
> Landing discipline: full chain green — stdlib · iiis-1 · iiis-2 `--check-corpus` 60/60 ·
> **self-host fixpoint iiis-2 ≡ iiis-3 byte-identical** (mhash `20d4ea59…`) · run_corpus **1594/0**
> · meaning gate **probes 17/17** (p16 tails re-asserted + new p17: widths 1/2/4/8, var+const arms)
> · corpus differential 110/112 · 0 divergence · ratchet 110. The evaluator learned const arrays
> (world objects, var-style) — a Θ1 prerequisite landed early.
>
> **STATUS: LOCATED + Θ0 EXECUTED (2026-07-09).** A systems-map pass answering one
> question: *what is the largest NIH unification above Γ — the most ambitious enhancement the tree can
> take that is not already located by an existing map?* Every number marked **[measured]** was produced
> by a command run against the live tree during this pass; **[recorded]** claims cite docs/ledgers.
> Companions: `III-UNIFICATION-LEVERAGE-MAP.md` (Λ), `III-GERMINATION-MAP.md` (Γ — this doc sits ABOVE
> it, as Γ sat above Λ), `III-COMPLETION-PLAN.md` (Φ), `III-LAMBDA0-LINK-CAMPAIGN.md` (Γ0 live ledger).

---

## 0. The verdict in one paragraph

Λ made III **one verified computer**; Γ made it a **substrate-independent self-regenerating organism**.
Both verify by the same epistemology: **measurement of artifacts** — byte-identity, fixpoint, DDC,
determinism, anchor acceptance. What no rung of Φ/Λ/Γ touches is the layer those measurements silently
presuppose: **what a .iii program MEANS**. Today the meaning of .iii is *whatever the 12,484-line
self-hosted compiler emits* [measured: lex 2,447 + parse 4,034 + sema 2,140 + cg_r3 3,863], anchored
only to **itself** (fixpoint) and to **yesterday** (corpus determinism). Every route in Γ's N-route
oracle — native, wasm, interp, arm64 — shares that one front-end, so the entire oracle is
**common-mode blind**: a semantic defect in sema or cg_r3 corrupts every route identically and all
gates stay green. The summit above Γ is **Θ — THE MEANING LIFT**: give .iii its meaning as a
**first-class verified object** — a definitional evaluator, written in .iii, consuming the compiler's
own parse-AST but **nothing downstream of it**, executing the same corpus differentially against the
compiled routes, forever. The organism that could already regrow anywhere becomes the organism that
**carries its own semantics**: the first language whose definition is a program in the language itself,
pinned to its implementation by a growing differential gate, with divergences adjudicated and ledgered
— and, on the high rungs, judged by the CIC kernel the system already built.

---

## 1. The gap, measured (why this is real and open)

| Fact | Measure | Consequence |
|---|---|---|
| Executors of .iii source | **exactly 1** — the iiis-2 pipeline (all Γ routes fork BELOW cg_r3's front) | no independent witness of meaning exists |
| `svir_interp` | 277 ln [recorded, Γ map] | executable semantics **of SVIR**, not of .iii; fed by the same front-end |
| ccsv | 2,803 ln [recorded] | independent front-end **for C**, not for .iii |
| CIC kernel (`numera/typecheck.iii` + `ccl.iii`) | EXISTS: QTT layer, **BV64 machine-int model**, theorem commons, trusted-base seal [recorded: III-BV64-KERNEL-MODEL] | proves *mathematical facts* (optimizer width laws by `refl`); knows **nothing of .iii programs as objects** |
| AST accessor surface | **274 exported accessors** in ast.iii [measured] | the front-end is ALREADY a consumable library — the evaluator's entire input vocabulary exists |
| Corpus | 1,830 KATs; **122 extern-free** (pure, single-file); of those 0 struct / 5 match / 1 metal / 60 `for` [measured] | a ready-made differential theater with a natural coverage ladder |
| Redundancy audit | no evaluator/REPL/def-interp anywhere: jit_emit = x86 encoder, proof.iii = certificate emitter, nl_lex/nl_parse = NL, kernel CCL reduces kernel terms [measured, grep+read] | Θ0 is NEW, not a rebuild |

**The one-sentence discriminator.** Γ answers *"does III exist independently of any machine?"*;
Θ answers *"does the MEANING of III exist independently of its implementation?"* — today it does not:
compiler and spec are the same artifact, so the system cannot even STATE "the compiler is wrong."

**Why this is the pick (Meadows-ranked against the alternatives).**
1. *More corpus/ratchet hygiene* — parameter tuning; structural nothing.
2. *Γ1 executed* (cg_r3 SVIR backend; the named open arc) — big, but already located by Γ; and its
   differential oracle inherits the common-mode blindness until Θ0 exists. **Θ0 is upstream of Γ1's
   value**: with the evaluator in place, every route Γ1 adds gets adjudicable meaning for free.
3. *Beyond-determinism organs C/E* [recorded: III-BEYOND-DETERMINISM-CONTEMPLATION] — explicitly a
   values fork awaiting the author's direction; not for a session to seize.
4. **⟨THE PICK⟩ Θ** — transcend the last unexamined absolute: *the identity of language and
   implementation.* Everything below feeds it (parse-AST as library, corpus as theater, kernel as
   judge, zkVM as attestor, spore as carrier); nothing above it exists in the tree.

**Honest novelty claim.** Definitional interpreters exist (McCarthy's LISP eval, the Scheme reports);
differential compiler testing exists (csmith-class); proof kernels exist. No system unifies:
(self-hosted systems language) + (definitional evaluator IN the language, over the production
front-end's own AST) + (whole-KAT-corpus differential gate as a permanent ratchet) + (an in-tree CIC
kernel positioned to judge the divergences) + (spore-carried, host-independent regrowth of the whole
claim). That unified object is new — and it is the piece that turns III's "verified" from
*consistency* into *correctness-against-stated-meaning*.

---

## 2. The Θ program (each rung: exit gate + falsifier, house discipline)

**Θ0 — THE SECOND MEANING (this session).** `eval.iii` + `eval_main.iii` in COMPILER/BOOT: a
definitional evaluator consuming lex+parse output via the 274-accessor API — **independent of sema,
sid, cg\_\*, emit, link** (the adjudicated layers). Dynamic value discipline (width × signedness tags,
two's-complement wraparound, unsigned/signed compare by tag, short-circuit logicals, x86-mask shift
counts — each pinned by probes, not assumed); flat byte world (globals, frames, string payloads —
locals live in world memory so `&local` is real); own binding/scope stack (shadowing, block scope);
own control flow (break/continue/return statuses). Driver protocol: `III_EVAL_OK ret=0x…` on stdout +
program rc; `III_EVAL_UNSUPPORTED`/`III_EVAL_TRAP` + rc 213/214 (extern-free KATs cannot print, so
stdout is a clean side-channel [measured: 122 files, 0 externs]).
*Exit gate:* `run_meaning.sh` — probe ladder green (every probe: eval rc == native rc, BOTH routes
freshly built from the same source by the pinned in-tree iiis-2) + corpus ratchet over the 122
extern-free KATs with an **up-only covered-count pin**.
*Falsifier (two-path):* the gate's negative arm runs a deliberately-diverging probe pair and MUST
report the divergence (comparator teeth); a semantic mutation of eval.iii MUST redden the ladder;
restoring MUST green it.

**Θ1 — THE LOADER (theater growth).** Resolve `extern … from "file.iii"` closures the way the linker
does; evaluate multi-module KATs; per-shim honesty for the OS boundary (the same 37-module ledger
discipline Γ uses [recorded]). The ratchet's denominator grows 122 → 1,830 with the frontier always
printed — the run_seed_corpus "honest frontier" pattern [recorded: S8].
*Exit gate:* ratchet strictly monotone; every skip named with its missing capability.
*Falsifier:* a KAT that diverges reddens; de-listing a covered KAT reddens.

> **Θ1 EXECUTED + SEALED (2026-07-09 session 2): THE LOADER LIVES.** Verdict (final green sweep):
> selftest 4 arms (incl. the OUTPUT-DIVERGE tooth) · REPL transcript byte-pinned · probe floor
> **19/19** (p18 multi-module + p19 shims/output joined) · corpus **595/1,819 pass · 0 divergence
> on BOTH axes** (rc + program-output bytes) · **ratchet 110 → 595** (up-only, 5.4×) · frontier
> named in full: 1,038 unsupported (663 poison-extern calls · 254 type-adaptation gaps · 113
> world-capacity · 7 misc), 56 eval-timeouts (solver islands), 130 native-skips (dedicated-runner
> families whose extra objects live outside the archive link universe — future per-family table).
> Mechanics landed: module registry + per-module symbol columns + flat fn table with extern ALIASES
> (linker-faithful), EV_AST/EV_SRC context switch per call frame, four-phase driver
> (load/collect/bind/run — binds after loads because stdlib closures have REAL cycles: ccl↔typecheck),
> builtin tier msvcrt {malloc,free,putchar} + kernel32 {VirtualAlloc,VirtualFree,Sleep} with
> world-arena semantics, poison externs erroring only at CALL. Gate v2: whole corpus, native-verdict
> cache keyed on sealed identities (mhash+mhash+sha, incl. LFAIL/NTIME verdicts), eval-verdict cache
> keyed per-binary (selftest fake routes can never collide), OUTPUT comparison axis, 8-way cache
> warmer. First production catches of the OUTPUT axis: 2488/2489 — adjudicated as COMPARATOR
> artifacts (rows 8-9 below), fixed + toothed.
>
> **Θ1 design (2026-07-09 session 2, measured).** Corpus: 1,830 KATs; 1,708 with externs;
> **1,363 pure-.iii-extern** (loader alone covers them); the entire C/DLL boundary of the remaining
> 345 is **malloc(260) / free(213) / putchar(72)** + 4 one-offs [measured]. `from "X"` is provenance,
> not linkage — resolution is flat by symbol (proof: the tree's `from "lex_runtime.c"` externs resolve
> against lex_rt.iii's exports; the file lex_runtime.c no longer exists). Loader law: load `from
> "X.iii"` by basename search {importer dir, COMPILER/BOOT, STDLIB/iii/*/}, transitively; bind extern
> fns by NAME against the flat fn table (the linker's namespace law); vars/consts/types stay
> module-LOCAL (Stage 3.18). Mechanics: module registry (ast, src, len) per module id; fn-table entry
> gains a module id (the spare u32 at +12); glob/type tables gain a parallel module-id column;
> cross-buffer name compare (ev_name_eq_x); EV_AST/EV_SRC/EV_CURMOD switch per call frame.
> Shims are eval-BUILTINS: msvcrt malloc → world bump alloc (bounds-checked), free → no-op,
> putchar → real stdout write; any other C/DLL extern = clean UNSUPPORTED naming the symbol.

**Θ2 — THE COMMUTING SQUARE (absorbs Γ1's oracle).** When the cg_r3 SVIR backend lands (Γ1, the open
arc), the gate becomes three-route: `eval(src) ≡ native(src) ≡ svir_interp(cg_svir(src))` per KAT.
Divergence localizes the fault to {front-end+eval | cg_x86 | cg_svir/translator} — the microscope the
Λ0 campaign builds by hand today [recorded: S8 flip-pair method], made permanent and mechanical.
*Exit gate:* three-route agreement on the covered set. *Falsifier:* any pairwise split reddens its axis.

> **Γ1 EXECUTED (2026-07-09 s2d): THE SVIR BACKEND OF THE PRODUCTION COMPILER LIVES.**
> `COMPILER/BOOT/cg_svir.iii` (a new compiler TU, in PORTED_TUS ×3) consumes the PRODUCTION parse-AST
> (lex.iii + parse.iii — the same front-end feeding cg_r3's x86 backend) and emits canonical SVIR v1.
> The insight that made it small: iiisv2 hand-rolls a shunting-yard because it has its own parser, but
> the production parser ALREADY resolved precedence into the binary-expr tree, so canonical postfix is
> a plain POSTORDER walk (eval.iii was the exact walk template). Wired as `iiis --emit-svir` in
> main.iii (early-exit after parse; no sema/cg/emit/link). **Gate `run_svir_backend_gate.sh` GREEN:**
> (A) CANONICAL — cg_svir ≡ iiisv2 BYTE-IDENTICAL on the full DDC independence corpus (indep_toolchain
> 1321B / indep_ops 893B / indep_bignum 2819B) proving cg_svir is a conformant SVIR-V1-CANONICAL
> emitter; (B) THE COMMUTING SQUARE now runs route S = the PRODUCTION backend (cg_svir, shares
> lex+parse with route N) — N(sema+cg_r3+x86) ≡ E(eval) ≡ S(cg_svir→svir_interp) on all 6 square
> probes, each also cg_svir≡iiisv2. Falsifier two-path-proven: an ADD→SUB opcode mutation reddens
> BOTH axes (parity + square) and the square LOCALIZES the fault to S alone (N=E=55, S=127); restore →
> green. Θ2 is no longer Γ1-blocked: the square's route S is now the compiler's own SVIR backend, so
> fault-localization is {front-end+eval | cg_x86 | cg_svir} for real.

> **Γ1 rung 2 EXECUTED (2026-07-09 s2d): THE BACKEND BECOMES WIDTH-FAITHFUL — Θ2-FULL OPENS.**
> cg_svir grows THE NORMAL-FORM LOWERING (SVIR-V1-CANONICAL **§W**): every stack/local value held in
> eval's canonical 64-bit form (unsigned zero-extended, signed sign-extended), type tags derived from
> the parse AST exactly as eval derives them (suffixes, declared types, ev_unify's wider-wins,
> ev_adapt's renorm-at-seams with literal folding), and the width law emitted precisely where
> ev_binop/ev_adapt apply it: zx/sx renorm after narrow add/sub/mul/shl and signed div/mod/shr,
> bias-XOR pairs for u64/untyped ordered compares (LHS bias byte-INSERTED post-hoc — the postorder
> walk learns the law only after the RHS tag), DIV_U/REM_U (0x2A/0x2B, already in svir_interp since
> Λ0) for unsigned division, width-typed loads/stores (0x80-0x89) with esz-scaled indexing for typed
> module arrays and scalar cells, loop/break/continue via an emitter control-frame stack that mirrors
> the interp's runtime frames (ELSE arms excluded — 0x43 pops the IF frame), and EXPLICIT REFUSAL
> classes for everything outside the fragment (`svir-unsup class=… kind=…` on stderr; NO silent
> miscompiles — the rung-1 silent-skip poison is dead). On the width-free fragment the lowering
> DEGENERATES to iiisv2's exact bytes — gate arm (A1) live-parity 6/6 held on the FIRST run.
> Typed canonical bytes are pinned by golden mhash (arm A2, `svir_backend_goldens.txt`: DDC ×3 +
> sq07/sq08). THE SQUARE GREW WIDTH TEETH: sq07 (u64 bias/DIV_U discriminators with exactly one
> bit63-set side, narrow wrap, wide-count law, i8/u32 element cells, narrowing casts) and sq08
> (row-10b mixed-width seams) — 8/8 N≡E≡S. Falsifier two-path: bias law disabled → sq07 splits
> N=E=90 S=61, localized to S; restore → green. (First falsifier draft did NOT fire — check 61
> compared two bit63-set values, where signed≡unsigned; the probe was STRENGTHENED to discriminate.
> A gate arm that ran EMPTY under IFS=newline-tab was likewise caught and now FATALs — silence is
> not green.) Authoring sq07 adjudicated TWO unpinned semantic corners (ledger rows 11/12: narrow
> shifts run WIDE &63; narrow signed `>>` is arithmetic-in-effect via the wide normal form) — the
> width theater found real meaning-law gaps before route S ever gated, and E+S agreeing on BOTH wrong
> models until native entered the theater is the measured proof that three routes — with the
> incumbent among them — are what break common-mode blindness. Re-embed chain v2 sealed the rung:
> fixpoint c2b8ac78 (5th of the session), corpus, all gates, warm, meaning gate, and THE FIRST
> CORPUS-SQUARE CENSUS (run_svir_corpus_gate.sh: rc-axis N≡S per non-negative KAT, S-frontier census
> as the named burn-down ledger, up-only PASS ratchet in svir_corpus_ratchet.txt).
>
> **LEDGER ROW 15 — THE CENSUS'S MAIDEN CATCH (2026-07-10).** The first corpus-wide sweep FIRED:
> 251_newline_else split N=99/S=4; route E adjudicated 99 with the incumbent (2-vs-1) → route-S
> defect. Hand-decoding the emitted 57-byte module showed the `else if` arm's compare and both tail
> arms ABSENT: sv_s_if fed the else arm to sv_block, and block_stmt_count on a NON-block (an
> else-if arm is a bare STMT_IF node) reads 0 — the arm emitted EMPTY with no refusal, and the
> fall-through default-return synthesizer masked the hole with `return 0`. Rung 2's named-refusal
> discipline had killed the expression-level silent skips; this was the last STATEMENT-arm seam.
> FIX: `sv_arm` transcribes eval's definitional `ev_exec_block_or_stmt` dispatch (block → sv_block,
> statement → sv_stmt, unknown kinds → LOUD SVU_STMT_KIND) for BOTH if-arms; sq11_elseif joins the
> square (3-arm chain, nested else-if in a loop, corpus-251's newline shape; pre-fix S=2 measured).
> NO existing theater could have seen it — sq01–08 audited clean of else-if, DDC clean, iiisv2
> cannot parse the form (pblock after `else` expects `{`) — only the corpus-wide census had the
> reach. The first census (RED, sealed as evidence): total=1820 pass=99 diverge=1 unsup=1588
> s-timeout=2 s-defect=0 native-skip=130; S-frontier first-blocker classes extern-fn 1246 /
> ptr ≈218 / var-init ≈85 / const-expr 35 / local-array 3. ZERO S_DEFECTs corpus-wide: the backend
> refused, never broke — except the one semantic drop the instrument existed to catch. Census-key
> wart for the next cg_svir chain: ptr/var-init rows key on raw NODE handles (kind=5368…/8053…),
> splintering the ledger; normalize the refusal payload to the AST kind. **Chain v2b (the sv_arm
> fix aboard, fixpoint d0cfe5b6 — the campaign's 6th) re-sealed every phase: corpus 1595/0,
> svir-gate A1 6/6 + A2 goldens 5/5 NO-DRIFT + square 9/9 (sq11 first run), iiisv2 square 6/6,
> meaning GREEN (597/1820, 0 divergence, ratchet 597 HELD), and THE SECOND CENSUS GREEN:
> pass=100, diverge=0 — 251→PASS the SOLE movement. Ratchet PINNED at 100 (up-only from here).**
>
> **ROWS 13/13b (2026-07-10, mx01-mx41): THE MIXED-SIGN LAW — eval CONFORMS, ALL THREE ROUTES.**
> 34-probe adjudication through the pinned compiler: binops consume operands in their OWN §W wide
> normal forms (NO cross-adaptation); div/mod and ordered compares run SIGNED IFF EITHER operand is
> signed, at ANY width pair (the incumbent's own `r3_either_is_signed` + signed setcc constants ARE
> the law in source); `==`/`!=` compare the RAW WIDE FORMS (`-1i32 != 4294967295u32` natively);
> unified result tag = (max width, signed-if-either). Row 13 retires eval's equal-width mixed-sign
> refusal; row 13b REFINES 10b — wider-TAG-wins is wrong when signs differ (falsifiers mx30
> N=223/E=0, mx31 N=2/E=1, mx32 N=1/E=2: eval was measurably wrong on u64⊗i32 shapes). ev_binop's
> operand pre-norm and unsigned div/mod pre-mask DELETED — the same narrow-register extrapolation
> class as ev_shmask's dead &31 (they truncated literals and re-signed operands the incumbent
> consumes raw: mx17 eq, `u8 < 300`-class, `u8var / 300`-class). sq09_mixsign squared rc=93 N≡E≡S
> on its first three-route run.
>
> **ROW 14(a-e) (same campaign): cg_r3 NARROW-TEMP RENORM DEFECT — WRONG-CODE, adjudicated AGAINST
> the incumbent on internal incoherence.** The renorm after narrow add/sub/mul/shl was
> `movl %eax,%eax` whenever the lhs walk said size-4 (i32 INCLUDED) and ABSENT for u8/u16, shr,
> unary neg/bnot and untyped-operand bitwise: (a) i32 temps zero-extended — `(a+b) < 0i32` with
> a=-2,b=1 returned FALSE natively while the NAMED spelling returned TRUE (mx26/27: referential
> transparency breached, two spellings of one expression disagreeing); (b) `255u8+1u8 != 0u8`
> natively (mx28/29); (c) the lhs-u32 gate TRUNCATED u32+u64 sums (mx33); (d) blind to CALL
> results and INDEX elements; (e) unary NEG/BNOT never renormed — `(~0u8) as u64` kept wide -1
> (mx40, named/temp split) and `-INT_MIN` escaped positive (mx41); bitwise closure holds ONLY
> both-typed-same-sign (mx37: `(u8|511)` kept 0x1FF at the temp, named/temp split). FIX: the ONE
> unified-tag walk (`iii_tc_expr_utag`/`iii_tc_utag_unify` in cg_typeclass — the R2 single-source
> law; `iii_tc_expr_is_signed`/`is_u64` untouched, cg_r0+sanctum byte-stable) + sign-aware §W
> renorm (`r3_utag_renorm` reusing the EXISTING extension strings; R3_STR_EXT_MOVL is
> byte-identical to R3_STR_MOVL_EE so every u32 site keeps byte-identical output). Renorm arms:
> add/sub/mul/shl = ut-narrow any sign; div/mod = ut-narrow signed; shr = ut-narrow signed (row
> 12); and/or/xor = ut-narrow unless both-typed-same-sign; unary neg/bnot = operand-tag narrow.
> Op-selection signedness (div/mod/setcc + the three unsigned fold gates) switched to the unified
> walk — identical on flat operands, closes the NESTED-mixed seam. NAMED OPEN CORNER (mx35,
> permanent falsifier): suffixed-LITERAL temps skip renorm natively — the parser drops suffixes;
> fix = suffix records in the AST, batched with the front-end touch. sq10_renorm squared rc=97
> N≡E≡S (14 teeth); p21 joined the meaning floor (21/21).
>
> **ROW 15b — THE A2 ARM VERIFIED NOTHING (the third IFS bite).** The golden-pin loader ran
> `read -r gname ghash` under the gate's global IFS=newline+tab — no space-split, gname swallowed
> whole lines, the pin map loaded EMPTY, and every svir-gate run since the goldens file existed
> reported GOLDEN-NEW inside a GREEN verdict while verifying nothing. Caught when chain v3's run
> showed all five pinned names as NEW with hashes IDENTICAL to their pins (the no-drift prediction
> held; only the verification was hollow). FIX: local IFS on the read + a loader self-check that
> FATALs when the file has pin lines but zero parse + GOLDEN-MISS-with-existing-file is RED
> (pin-rot is loud). LAW: any space-splitting `read` under the gates' global IFS must set LOCAL
> IFS. sq10's first authoring also hit the var-init frontier class through route S (nonzero-init
> module array — dry-validation had only run N/E): zero-init + runtime element stores; the
> S-route probe discipline is now "emit through cg_svir BEFORE landing".
>
> **CHAIN v3 SEALED (2026-07-10): fixpoint eca48370 (7th; iiis-1 b6369881), corpus 1595/0 with
> ZERO recorded-under-defect reds, svir-gate A1 6/6 + A2 7/7 (REAL verification, 7 pins incl.
> sq09 4e619b03/sq10 ec93651a) + square 11/11 N≡E≡S, iiisv2 square 6/6, meaning 21/21 probes +
> 597/1820 + 0 divergence + ratchet 597 HELD through the full eval re-sweep with the new law
> live, census pass=100 diverge=0 s-defect=0 ratchet=100 HELD, mixed-sign census rows = 0.**
>
> **S-FRONTIER SLICE 1 (2026-07-10, chain v4): const-expr RETIRED — Θ3's engine joins Γ1's
> backend.** `sv_prescan_const`'s non-literal arm now asks `iii_ev_const_value` — the SAME
> definitional-evaluator export cg_r3's comptime uses — so all three routes fold module consts
> through ONE meaning object by construction; the value arrives already slot-normal; unevaluable
> initializers refuse loudly as before. The svir-gate harness grew eval.o (8 TUs — an
> undefined-symbol catch made BEFORE the chain by the row-15b pre-landing discipline, which also
> proved sq12_comptime 96≡96≡96 three-route pre-landing via a fresh harness and pinned its golden
> ad25504b). PINNED GRAMMAR FACT (from an rc=5 parse-fail bisect): module-level `const` REQUIRES
> its type annotation — `const N = expr` does not parse. Chain v4 sealed: fixpoint 8th
> BYTE-IDENTICAL, corpus 1595/0, A2 8/8, square 12/12 N≡E≡S, meaning 21/21 + ratchet 597 HELD,
> census GREEN ratchet=100 HELD with **const-expr 35 → 0 (class EXTINCT)** — all 35 re-blocked on
> deeper frontiers (none flipped PASS; the honest delta). Burn-down ledger now: extern-fn 1276 /
> ptr 225 / var-init 84 / local-array 3.
>
> **S-FRONTIER SLICE 2 (2026-07-10, chain v5): var-init RETIRED — §W.8 THE CANONICAL INIT
> PREAMBLE.** Nonzero-initialized module cells store their language-defined values at the ENTRY
> fn's head (fn 0, main-first): declaration order, elements ascending, ZERO values SKIPPED (the
> interp world is pre-zeroed — minimal canonical bytes, the declared-extent zero law's dual),
> store shape byte-identical to the assignment lowering. The VALUES come from the definitional
> evaluator's collected world — `iii_ev_const_value` for scalars (it reads var slots; the p20
> precedent) plus the NEW export `iii_ev_elem_value` for per-element array reads (same
> per-AST-cached CTFE world) — so every route folds module data through the ONE meaning object,
> CTFE initializers included. NO interp change (cells are world addresses; the world is
> pre-zeroed). sq13_varinit proven three-route 97≡97≡97 PRE-LANDING (scalar / CTFE scalar /
> mixed-zero u32 array / u16 widths / post-init mutation); golden pinned 28b63f97; A2 9 pins.
> Chain v5 sealed: 9th BYTE-IDENTICAL fixpoint, corpus 1595/0, A2 9/9 + square 13/13 N≡E≡S,
> meaning 21/21 + ratchet 597 HELD, census GREEN **pass=103 — THE FIRST RATCHET RISE (100→103,
> pinned)**: three KATs' only blocker was their module-data init and they now run route S
> end-to-end; **var-init 84 → 0 (class EXTINCT — the second retired in two slices)**. Burn-down
> ledger now THREE classes: extern-fn 1338 / ptr 244 / local-array 3.
>
> **S-FRONTIER SLICE 3 (2026-07-10, chain v6): local-array RETIRED — §W.9 THE FRAME ARENA.**
> Local `var x : [T; N]` lives in a per-activation arena: ops 0x8B ARENA [u16 ext] (save the mark
> into the frame, reserve, ZERO — eval's fresh-world law — advance) and 0x8C ABASE (push the
> frame's base); 0x8A untouched (the Λ0 IMPORT marker). Arena base 8 MiB; EVERY exec activation
> save/restores the mark (wrapper split exec_fn→exec_fn_body covers all return paths) so
> recursion gets fresh isolated extents. The emitter pre-walks the statement tree for the extent
> (same traversal order as emission), emits 0x8B iff nonzero before the §W.8 preamble, and
> addresses elements as idx*esz + ABASE + offset through the ONE index-address choke point
> (loads and stores both). sq14 proven 98≡98≡98 PRE-LANDING including the RECURSION-ISOLATION
> tooth; golden e7481e98; A2 10 pins. **THE PRE-LANDING DISCIPLINE FIRED A THIRD TIME**: the
> first draft's zero-read tooth split N=90 vs E=S=98 — FIRST-READ of a never-written local array
> is 0 on E/S (world/arena law) but STACK GARBAGE on N; the corpus never pinned it (191/256/1089
> all write-then-read) — NAMED OPEN CORNER, adjudication deferred, probes test defined behavior
> only. The census-key normalization rode along (sv_refuse resolves node-handle payloads to AST
> kinds): the ledger collapsed from ~50 splintered rows to FOUR readable lines. Chain v6 sealed:
> 10th BYTE-IDENTICAL fixpoint, corpus 1595/0, A2 10/10 + square 14/14 N≡E≡S, meaning 21/21 +
> ratchet 597 HELD, census GREEN **pass=106 — SECOND RATCHET RISE (103→106, pinned): all three
> local-array KATs flipped straight to PASS; local-array 3 → 0 (THIRD class EXTINCT in three
> slices)**. The frontier is TWO classes: **extern-fn@CALL 1338 / ptr@{TYPE 193, UNARY 50,
> PAREN 1}** — and the extern-fn mass's true rung is named: route S linking each KAT's
> use-closure through svir_ld (Λ0's linker) into whole-program SVIR — gate v3, the next summit.
>
> **S-FRONTIER SLICE 4 (2026-07-11, chain v7): §W.10 THE CRT TIER — the import plumbing gate v3
> requires, proven three-route.** Tier-whitelisted externs (malloc/free/putchar/VirtualAlloc/
> VirtualFree/Sleep — Θ1's adjudicated law, ONE list both routes cite) lower to Λ0-form IMPORT
> records ([params][1][bl:u16][0x8A][nl][name], fncount u8-capped) and the interp's shim_call
> answers: malloc = zeroed bump at 64 MiB returning SVIR OFFSETS (tier memory lives IN the
> world), free noop, putchar char-law, VirtualAlloc ≡ MEM_COMMIT-zero bump. Registration probes
> save/restore the refusal state (an uncalled decl must not poison). TWO probe traps self-caught
> pre-landing: the first sq15 draft's deref teeth were ptr-class (malloc memory is only
> reachable through pointers — the NEXT rung), and zero-read teeth would split N (CRT garbage)
> from E/S (zeroed worlds) — the sq14 unpinned-corner class. sq15 rewritten pointer-free
> (putchar char-law, malloc align/disjoint/monotone, free callable): 96≡96≡96 FIRST RUN;
> golden ab5b5cdd; A2 11 pins. Chain v7 sealed: 11th BYTE-IDENTICAL fixpoint, corpus 1595/0,
> A2 11/11 + square 15/15 N≡E≡S, meaning 21/21 + ratchet 597 HELD, census GREEN ratchet=106
> HELD with the ledger BYTE-UNCHANGED (extern-fn 1338 / ptr 193+50+1): every extern-fn
> first-blocker is a `use`-import — the HONEST zero, exactly the forecast; the tier's value is
> the plumbing the closure link consumes. §W.11 (addresses without SVIR v2) opens next: ptr
> tags = eval's ev_mk_ptr packing verbatim, U_ADDR = the index choke-point's bytes without the
> load, deref = the width ops — zero new opcodes, zero eval/cg_r3/interp edits expected; ONE
> model corner named at design time (&local-SCALAR: SVIR locals are slots vs eval's
> world-resident locals — refuses in S until the slot→arena promotion increment).
>
> **§W.11 SEALED (2026-07-11, chain v8b): THE PTR CLASS COLLAPSED 244 → 5 — THIRD RATCHET RISE
> (106→112).** Pointers landed with ZERO new opcodes: tags transcribe ev_mk_ptr verbatim
> (width-8 values, pointee at bits 24/32/40), &lvalue = the index choke-point's address bytes
> without the load, deref/p[i] = the width ops, *p=v = address+adapted-value+width-store, casts
> and seams follow ev_adapt/ev_norm, BOTH-PTR eq/neq compare raw addresses. THE PROBE LOOP
> CAUGHT THREE MORE ARMS (sv_s_let/sv_e_cast/sv_e_binop ptr gates) AND **ROW 16 — A NATIVE
> DEFECT, the WATCH note's suspect FIRED**: cg_r3's &arr[i] leaq scales were 1/8-only, so
> &u32arr[i] landed at i*8 (sq16 tooth 83: N=83 vs E=97, adjudicated by the evaluator); FIX =
> full elem-kind scale dispatch (LEAQ_RCX2/RCX4 join). TWO probe-authoring traps recorded:
> slash-star prose in block comments OPENS nested comments (the depth-counting lexer — all
> three routes lex-failed identically), and the SEED's parse-recursion cap killed a 7-deep
> else-if chain at chain v8's first launch (rc=3 in 7s) → **NEW LAW: compiler-TU pre-flights
> run under BOTH iiis-0 and iiis-2**. Chain v8b sealed: 12th BYTE-IDENTICAL fixpoint, corpus
> 1595/0 (zero recorded-under-defect reds for row 16 — the scale shape appears in no corpus
> expectation), A2 12/12 + square 16/16 N≡E≡S (sq16 rc=97 all routes incl. the FIXED native),
> meaning 21/21 + 597 HELD + 0 divergence, census pass=112 diverge=0 s-defect=0. Frontier now:
> **extern-fn 1564 (the svir_ld closure rung's mass — grew as ptr-declaring use-importers
> re-classified) / ptr residue 5 / string 7 (surfaced from behind ptr declarations)**.
>
> **§W.11b SEALED (2026-07-11, chain v9): THE CAST-FORM SUBSCRIPT — FOURTH RATCHET RISE
> (112→114); the pre-closure frontier is EXHAUSTED.** The three ptr@PAREN rows were one shape —
> `(p as *u8)[j]` (corpus 1109/1092/1111, the q3_ptrcast idiom) — landed as ONE arm: the index
> choke point paren-skips its object and accepts ANY ptr-tagged object EXPRESSION (obj +
> idx*esz(pointee), obj-first canonical order; reads AND writes). sq17 96≡96≡96 FIRST RUN with
> the two-compiler pre-flight green; golden f36572c4; A2 13 pins. Chain v9 sealed: 13th
> BYTE-IDENTICAL fixpoint, corpus 1595/0, A2 13/13 + square 17/17 N≡E≡S, meaning 21/21 + 597
> HELD, census pass=114 diverge=0 s-defect=0 (two cast-subscript KATs flipped PASS; one
> re-blocked extern-fn). **THE LEDGER'S FINAL PRE-CLOSURE FORM: extern-fn 1565 (THE CLOSURE
> RUNG — gate v3 via svir_ld, designs grounded and staged) / ptr@UNARY 2 (fnptr-adjacent, named
> refusals by design) / string 7 (closure-gated — use-imports behind the literals). Every
> tractable single-file class is retired: 6 slices, 4 ratchet rises (100→114), the square grew
> from 6 to 17 probes, and the S-frontier census did exactly what it was built to do — name
> every gap, adjudicate every split, and burn down to the one true summit.**

**Θ3 — COMPTIME (the language grows a feature from its own meaning).** The evaluator becomes the
compiler's const-expression engine: `const X: T = f(...)` evaluated at compile time by the
definitional evaluator — the known const-expr-init wart [recorded: LENS/STUDIO trap ledger] dies not
by a patch but by the spec and the compiler SHARING one meaning object. CTFE lands as: cg_r3 asks the
evaluator; divergence between comptime and runtime is structurally impossible for the evaluated slice.
*Exit gate:* const-init KATs, both-route. *Falsifier:* a comptime/runtime value split reddens.

**Θ4 — THE ADJUDICATION PROTOCOL + THE MOUTH.** Every eval≠native divergence gets a ledger row:
either an evaluator fix (a **spec clarification**, documented language fact) or a compiler defect (the
oracle's catch — route to the standing fix discipline). Plus the REPL organ: iii_eval behind STOMA /
STUDIO as the interactive mouth of the language (consumers already live [recorded]).
*Exit gate:* divergence ledger has zero OPEN rows at seal time. *Falsifier:* an unledgered divergence
found by sweep reddens.

> **Θ4 EXECUTED (2026-07-09 session 2): THE MOUTH LIVES.** `iii_eval --repl` — decls accumulate
> (an `extern … from "x.iii"` line IS the import syntax; the Θ1 loader resolves it — no invented
> REPL commands), expressions evaluate in a fresh world per line, values print as `= 0x<16-hex>`.
> First session: `7u64*6u64`→0x2a, `fn sq…` (ok), `sq(12u64)`→0x90, `const KK…` (ok),
> `KK + sq(2u64)`→0x68. Exit gate LIVE: `run_repl_kat.sh` byte-compares the full transcript against
> the pinned `meaning_repl.rexp`, wired into run_meaning.sh; falsifier two-path-proven (sabotaged
> pin → RED + diff; re-pin → GREEN). The adjudication protocol below is the standing law (rows 6/7
> executed it). STOMA verb = named follow-up.
>
> **Θ4 design (2026-07-09 session 2).** (a) THE PROTOCOL, stated as standing law: every gate-red
> divergence (rc axis or output axis) gets its ledger row IN THE SAME SESSION it fires; a row is
> either *compiler-incumbent* (evaluator conforms; the behavior becomes a documented language fact
> pinned by a probe in BOTH routes) or *compiler-defect* (a fix campaign with its own regression
> discipline — rows 6/7 are the precedents). A seal requires zero OPEN rows. (b) THE MOUTH:
> `iii_eval --repl` — line loop over stdin (`__acrt_iob_func(0)` direct extern, no lex_rt touch);
> declarations accumulate as module text; an expression line wraps as `fn _repl_N() -> u64` and the
> accumulated module re-lexes/re-parses whole (trivial at REPL scale), evaluates, prints `= 0x…`;
> `:load <file.iii>` pulls modules through the Θ1 loader; errors print the named eval codes.
> Consumer: STOMA verb. *Exit gate:* a scripted REPL transcript KAT (stdin script → full stdout
> byte-compare vs pinned .rexp). *Falsifier:* transcript drift reddens; an unledgered divergence
> found by sweep reddens.

**Θ5 — THE JUDGED STEP (kernel + zk + spore; the horizon rung).** Connect the meaning object to the
truth machines: (a) evaluator step-laws for the arithmetic fragment stated against the CIC kernel's
BV64 model (the kernel already speaks mod-2^64 with `refl` certificates [recorded]); (b) the
certified-rewrite precedent (cg_opt_rules ↔ kernel [recorded: BV64 ledger]) widened toward
translation certificates; (c) `run_zk.sh`-class attestation of evaluator runs; (d) the spore carries
the evaluator + gate so every germinated host re-verifies MEANING, not just bytes — the self-evident
spore. Stated as horizon with named unknowns (proof-engineering scale), not scheduled flat.
*Falsifier per leg:* kernel rejection / attestation mismatch / spore-regrowth meaning-gate red.
> **Θ5d dependency (measured 2026-07-09 s2):** the Σ0 spore carries SVIR bytes + fused germs — no
> .iii sources, no compiler (`run_germinate.sh` header). iii_eval joins the spore only once it is
> routed through the SVIR waist ⇒ Θ5d waits on Γ1, exactly like Θ2. The Γ1-independent Θ5 legs are
> (a) kernel step-laws and (c) zk attestation of evaluator runs.
>
> **Θ5(a) rung 0 EXECUTED (2026-07-09 s2): THE JUDGED STEP opens.** Measured first: the sealed Θ1
> sweep shows `1213_bv_kernel` **PASS** — the definitional evaluator EXECUTES THE CIC KERNEL
> (typecheck+ccl pulled through the loader) and reproduces all 32 BV64 vectors including the
> soundness negatives. On that measured base, `2498_meaning_kernel_step.iii` states the JOINT law:
> nine vectors each computed once in the PROGRAM'S OWN arithmetic (executed by whichever
> meaning-bearer runs it) and once inside the kernel (BV64 iota-fold), judged by `tc_conv`, with a
> negative arm (the kernel must refuse 2+2≡5). Vectors sit on the pinned semantic edges: wraparound
> add/mul, underflow, bitwise triple, high-half shift, and THE x86 COUNT MASK (x<<64 == x — where
> kernel k&63, native SHL cl-mask, and the evaluator's pinned mask semantics all meet). The standing
> differential (run_meaning) then holds evaluator ≡ native ≡ kernel on these vectors forever.
> Deeper step-laws (symbolic theorems over eval's AST) remain the named proof-engineering horizon.
>
> **Θ5(c) rung 0 EXECUTED (2026-07-09 s2): ATTESTED MEANING.** `run_meaning_zk.sh` over
> `sq03_line` (the attestable straight-line cell): ONE iiisv2 emission feeds both arms — (1) the
> commuting square holds on it (N=E=S rc=12), (2) `zk_iiisv_attest` parses THE SAME gen_svir bytes
> and STARK-proves the execution (honest accepted; a forged stack-top REJECTED BY THE MATH).
> Verdict: `[mzk] GREEN`. An execution whose meaning all three bearers pin is now zk-proven —
> byte-shared by construction. Named residual (the gadget's own header): straight-line only;
> locals/loops arithmetization is the zkVM frontier, and corpus-wide attestation rides Γ1 with Θ2.
> The square gate itself now sweeps 3/3 (sq01 arith+loops, sq02 memory, sq03 the attested cell).
>
> **Θ2 rung 0 (2026-07-09 s2): the square opens WITHOUT waiting for Γ1.** Route S exists today:
> `iiisv2` (.iii→SVIR, the DDC shunting-yard emitter) → `gen_svir` module → `svir_interp` (the SVIR
> reference executor) — an execution path forking at the SOURCE, sharing nothing below the front.
> `run_meaning_square.sh` + `square_probes/` assert three-route rc agreement; a pairwise split
> NAMES its axis (N≠E,E=S → compiled route; E alone → evaluator; S alone → SVIR emitter/interp).
> HONEST THEATER LIMIT: SVIR v1 drops width suffixes (all i64, SVIR-V1-CANONICAL §3.3), so route S
> runs only the explicit width-free probe theater until Γ1's width-faithful backend absorbs the
> oracle corpus-wide.

**Scheduling fact:** Θ0 touches ONLY new files + one new gate script — the live Γ0/Λ0 bisect state
(ccsv, session 8b) is untouched and can burn in parallel. Θ2 waits on Γ1; nothing else serializes.

### The Θ4 divergence ledger (every row = the instrument firing; append-only)

| # | Date | Probe/KAT | rcN vs rcE | Adjudication | Standing fact |
|---|------|-----------|------------|--------------|---------------|
| 1 | 2026-07-09 | p10_shift check 8 | 8 vs 99 | **compiler is incumbent** → evaluator conformed | `>>` is a **LOGICAL** shift for ALL integer types in .iii — signed operands do NOT get SAR. Pinned with teeth in both routes (p10 asserts the 0x7FFF… bit pattern). If the language ever chooses arithmetic shr, cg_r3 changes and p10 reddens the other way. |
| 2 | 2026-07-09 | p14 (parse-level) | — | **language fact** (not a divergence): `&&`/`||`/`!` do not exist as tokens — 0 corpus uses, parse rejects; nested `if` is the idiom | Probe p14 re-pinned to bit-op semantics; evaluator keeps LAND/LOR/NOT arms for the AST kinds should they ever gain surface syntax. |
| 3 | 2026-07-09 | (build) | — | **front-end facts** recovered by construction: parser drops literal suffixes (evaluator re-reads them from source via position records); local `var` parses as STMT_LET with null value; `iii_parse_module` returns 1-on-success; bracket-init `[a,b,…]` = EXPR_PARALLEL and exists at MODULE scope only (`iiip_parse_let` has no bracket path) | Recorded here so no future consumer re-derives them the hard way. |
| 4 | 2026-07-09 | 887/895 | 213 vs 99 | **compiler is incumbent** → evaluator conformed | bool → int is a legal adaptation (`return 5u64 == 5u64` from a `-> u64` fn yields 0/1). |
| 5 | 2026-07-09 | 895 | 213 vs 99 | **compiler is incumbent** → evaluator conformed | if/while conditions accept INTEGER operands; truth = nonzero (`if ON` with `ON : u32`). |
| 6 | 2026-07-09 | p16 partial-init arm | 6 vs 99 | **CLOSED (session 2, same day) — compiler defect, FIXED** | A partially-initialized global array (`var P : [u32;4] = [7u32, 9u32]`) was emitted at **listed** size, so its tail **aliased the next global** (RED arm, machine bytes: `.data` = 16 B, `P[3] ≡ Q[1]`, repro rc 223 vs eval 0). Fix: both PARALLEL arms of `r3_emit_data_decls` emit `.zero (N−listed)×sizeof(elem)` — the declared-extent law, = the evaluator's meaning. GREEN arm proven: `.data` = 24 B with zeroed tail, repro rc 0 ≡ eval, p16 tail checks re-asserted (probe floor 17/17). Swept: stage1 equivalence 60/60 · **self-host fixpoint iiis-2 ≡ iiis-3 BYTE-IDENTICAL** · run_corpus **1594/0** · meaning gate 110/112, 0 divergence, ratchet 110. Goldens iiis-{1,2,3}.mhash re-sealed (intentional-change law). |

| 7 | 2026-07-09 | constidx repro (session 2) | 139 (SIGSEGV) vs 8 | **compiler defect — found by hand-probe while building p17** | Const-ARRAY addressing never worked: `r3_emit_global_ident`'s CONST_DECL arm value-loaded the first quad of `.rodata` and the index path dereferenced it as a base pointer (machine proof: `mov 0x0(%rip),%rax` + `mov (%rax,%rcx,8)`); `r3_index_obj_elem_kind` also lacked a CONST_DECL arm (stride 8 regardless of element). Fixed in the same pass as row 6: const-array ident → `leaq` + element-width stride, mirroring the var-array arms. Evaluator side widened symmetrically (const arrays were UNSUP_TYPE; now var-style world objects — required by Θ1's theater regardless). p17 pins var+const arms at widths 1/2/4/8. |

**WATCH (named suspect, not yet probed):** the ADDR-of-INDEX path (`&arr[i]`, cg_r3.iii ≈2514)
emits only scales 1 and 8 — `&u32arr[i]` / `&u16arr[i]` would compute base + i×8, disagreeing with
the width-aware load/store path. Needs its own probe + fix pass (p18 candidate).

**STALE GATE (found + measured this session):** `build_iiis1.sh --check-corpus` (iiis-0 ↔ iiis-1
byte-equivalence) has been incomparable since the sovereign-emit overhaul: the .iii lineage writes
minimal COFF (empty sections skipped), frozen iiis-0 writes gcc-as-style full COFF. 0/60 is its
steady state — proven by three-way hash: old-iiis-1 (git HEAD) ≡ fresh-iiis-1 ≡ pinned-iiis-2, all
`40a18e…` on 01_return_const, vs iiis-0's 706-byte full-COFF object. The LIVE equivalence gate is
`build_iiis2.sh --check-corpus` (iiis-1 ↔ iiis-2, both sovereign). An honest cross-divide oracle
would compare link+run BEHAVIOR, not bytes — future work, named here.

| 8 | 2026-07-09 | 2488/2489 (output axis, first firing) | rc equal; 156B vs 148B / 104B vs 100B | **comparator defect — the instrument's OWN extraction was asymmetric** | msys sed strips `\r` from lines it rewrites: the eval side's protocol-strip pass lost CRLF while the native side kept it → false OUT_DIVERGE on any multi-line output. Adjudicated by raw-byte proof (both routes emit identical CRLF streams; symmetric `tr -d '\r'` normalization → byte-identical). Fixed on BOTH sides + the (d2) selftest arm hardened to multi-line output so the class has a permanent tooth. Comparison is now CR-insensitive + trailing-newline-insensitive — the two NAMED softnesses of the output axis. |
| 9 | 2026-07-09 | probe floor flake (p01/p08/p18, sweep 1) | stochastic, 3 distinct codes | **gate-environment defect — OneDrive stale read-after-write** | Rapidly-rewritten scratch files under the OneDrive tree served STALE content (measured 1/40 on the exact gate invocation shape): the probes' eval output read back as prior-run bytes → misclassification. The read-side sibling of the staged-exec trap. Fixed: every same-invocation read-back file lives in /tmp; the cache dir stays on OneDrive because its reads are settled (written whole runs earlier); fresh-branch rc is kept live instead of re-read. |
| 10 | 2026-07-09 | sq02 (the square's FIRST catch) | E=213 vs N=S=196 | **evaluator STRICTER than incumbent → conformed** (two laws) | (10) ADAPTATION: the compiled route adapts ANY int to ANY int slot by width-renormalization (narrowing stores truncate movb/movw/movl; widening re-extends by target signedness) — ev_adapt's same-width+same-sign-only arm was the named root of the code=102 frontier class; now `ev_norm(v, want)` universally. (10b) BINARY UNIFY: mixed-WIDTH operands take the WIDER tag — natively the narrow side loads extended per its OWN signedness and the op runs wide; evaluator values are stored pre-normalized so no transformation needed. Equal-width mixed-SIGN stays refused until a differential adjudicates it. Θ2-0's square fired on its FIRST run and localized the axis to E alone — the instrument naming its own softness. |
| 11 | 2026-07-09 | sq07 check 66 (authoring pass, N=66 E=90) | `5u32<<33`: N=0, E(model)=10 | **evaluator model EXTRAPOLATION → conformed** | NARROW SHIFTS RUN WIDE: the compiled route executes every shift in the 64-bit unit (count &63) and the operand width renormalizes the RESULT — `5u32<<33 == 0`, not `5<<(33&31)`. ev_shmask's &31 arm modeled "narrow ops in 32-bit registers", extrapolating beyond p10's pins — p10's counts are all IN-RANGE, where the two masks cannot be told apart. Measured u8/u16/u32 with out-of-range counts (shp1-3): the wide law is uniform. ev_shmask → 63 universally; §W lowers narrow shifts BARE + renorm. |
| 12 | 2026-07-09 | sq07 check 68 (post-11 pass, N=68 E=S=90) | `(-5i32)>>1`: N=-3, E=S(model)=0x7FFFFFFD | **evaluator pre-mask arm → conformed (p10 REFINED, not overturned)** | ONE SHIFT LAW: the WIDE normal-form value shifts logically; at w=8 that IS p10's logical shr (no extension bits), but NARROW SIGNED operands see their sign-extension bits shift in — arithmetic **in effect** — because the incumbent shifts the sign-extended 64-bit pattern and truncates. eval's `mv = av & mask(w)` pre-mask modeled a narrow-register shift the incumbent never performs; deleted. §W's `>>` row lowers to bare 0x29 + signed renorm — and route S agreed with E on BOTH wrong models before the fix, proving the common-mode blindness Θ0 warned about is broken ONLY by the three-route square with native in the theater. |

**Θ2 rung 0 VERDICT (2026-07-09 s2): `[square] GREEN: 2/2 three-route agreement` — the commuting
square HOLDS (sq01 N=E=S=61; sq02 N=E=S=196 after rows 10/10b). Three independent executions of
.iii source — sema+cg_r3+x86, the definitional evaluator, and iiisv2→SVIR→svir_interp — agree.**

### Row-6 fix audit (2026-07-09 session 2, written BEFORE the edit — evidence-before-action)

**Defect sites (read in full).** `cg_r3.iii r3_emit_data_decls`: const-PARALLEL arm (≈3714-3722)
and var-PARALLEL arm (≈3740-3748) both emit one data directive per **listed** branch and ignore the
declared count. The `.bss` arm (≈3759-3764) already sizes by count (×8 — a **recorded deliberate**
stage-0 stride paranoia, per the cg_r3.c twin's comment at its ≈3808; its rationale is stale — r3
indexing is width-aware via `r3_index_obj_elem_kind` — but the direction is safe-fat; untouched).

**The law being landed.** A module-scope bracket-init array `[T; N] = [e…]` emits **exactly
N × sizeof(T) bytes**: listed elements, then `.zero (N−listed)×sizeof(T)` when N > listed. This is
the evaluator's pinned meaning (`ev_fill_array`: pre-zeroed region; overfill → UNSUPPORTED).

**Measured couplings (all [measured] this session).**
- Tree-wide exposure: **1,425** module-scope bracket-inits; **zero underfilled** outside probe p16 →
  the fix is **layout-neutral for everything that exists**; only new programs gain tails.
- Frozen seed: `cg_r3.c` carries the same listed-size law; it is NOT touched (Λ0's live ccsv
  substrate + DDC seals). Safe because `build_iiis1.sh --check-corpus` (iiis-0 ↔ iiis-1) and
  `build_iiis2.sh --check-corpus` (iiis-1 ↔ iiis-2) compare emissions on `stage1_corpus`, which has
  **zero partial inits** [measured] — byte-equivalence unaffected. Seed divergence recorded here,
  same pattern as the CLAUDE.md seed-trap ledger.
- Assembler (same law, second gap): `sovparse.iii sp_dir1` handles `.quad/.long/.byte/.zero/.ascii`
  — **no `.short`** — while `r3_emit_gas_data_hex(width==2)` emits `.short` for `[u16;N]` inits →
  silently dropped bytes. Measured: **zero** u16/i16 bracket-inits tree-wide, **zero** `.short` in
  any built `.s` → adding the handler is layout-neutral. Fix: `.short` arm (OFF+=2, `sp_emit_val(…,2)`),
  mirroring `.long`. `.zero` semantics verified correct in ALL sections (data: real zero bytes;
  bss: reserve) at sovparse.iii:1020-1027.
- **Overfill finding** (new, this audit): `emit.iii:264 STR_LDSCRIPT_HDR : [u8;64]` lists **66**;
  `STDLIB/iii/omnia/xii_curated_riscv.iii:41 XCR_H058_RISCV : [u8;16]` lists **20**. Both *depend*
  on listed-size over-emission today; the pad-only fix leaves them byte-identical. Declarations are
  lies — queued for truth-restoration after consumer-length check (separate, zero-emission-delta).
- Rebuild chain (sovparse lives in `libiii_native.a`; cg_r3.iii is a PORTED_TU):
  `build_stdlib.sh` → `build_iiis1.sh` → `build_iiis2.sh --check-corpus` → `run_corpus.sh` →
  `build_iii_eval.sh` → `run_meaning.sh` (p16 tails re-asserted + new p17 u16-init probe).

---

## 3. What Θ delivers that III cannot do today

1. **State "the compiler is wrong"** — for the first time the system has a second, independent
   meaning-bearer for .iii; today the sentence is unformulable [measured: 1 executor].
2. **Unblind the oracle** — sema/cg defects become catchable; every existing route shares them today.
3. **A mechanical microscope** — the Λ0-style meaning-vs-code diff, hand-built per campaign today,
   becomes a standing instrument (Θ2).
4. **CTFE** — a language feature born from the meaning object; kills a documented wart (Θ3).
5. **An executable spec** — new-host, new-backend, new-optimizer work gets a definitional referee;
   ports stop being leaps of faith (this is Γ's R3 loop, strengthened at the TOP of the pipeline).
6. **The road to proof** — the kernel finally gets the object it was missing (programs as meanings,
   not just optimizer facts); zk attestation gets a semantic payload; the spore gets self-evidence (Θ5).

## 4. Named limits and risks

- **Shared lex+parse.** The evaluator reuses the front half — a lexer/parser defect corrupts both
  routes. Named boundary: independence begins BELOW parse. Partial mitigation exists (ccsv's
  independent C front-end at the seed level; parse's own harnesses [recorded]); full front-end
  diversity is future work, stated, not claimed.
- **The incumbent meaning is the compiled route.** Θ0 PINS current semantics; it does not overrule
  them. A divergence defaults to "evaluator fixed to match, fact documented" unless the compiled
  behavior contradicts a documented language commitment — then it's a compiler defect. The protocol
  is Θ4; no silent authority transfer.
- **Coverage honesty.** 122/1,830 is the opening theater [measured]; metal (17 KATs), externs,
  structs/match arrive by rung. Every exclusion is named in the gate output — no silent caps.
- **Performance.** A tree-walker is slow; the gate bounds per-KAT time and the corpus slice is
  chosen accordingly. Speed is a non-goal for a definitional object.
- **Environment traps carried:** OneDrive lock/dehydration (rm-first + retry, staged /tmp exec),
  CRLF, stale-exe relink, 8-bit rc observation — the standing feedback ledger applies; the gate
  compares both routes through the SAME observation channel so truncation cancels.

## 5. Confidence + what would confirm or refute

HIGH on the gap being real and open (grep-audited; the only .iii executor is the pipeline) and on
Θ0's mechanics (accessor API read; corpus theater measured). MEDIUM-HIGH on first-session coverage
breadth (the 122-set spans scalars/arrays/control-flow/calls/strings [measured] — sized, but semantics
edges like shift-count masking and signed div must be probed, and probes decide, not intent).
MEDIUM on Θ5 proof-engineering scale (named horizon).

**Watch to confirm:** (a) first probe-ladder green = the evaluator exists as a meaning-bearer;
(b) first corpus ratchet number = the honest frontier; (c) the first REAL divergence adjudicated —
either kind is the instrument working; (d) Γ1's backend landing turns the gate three-route with zero
redesign — confirms Θ0's oracle-shape was right.

**The one-sentence answer:** *above the organism that regrows anywhere sits the organism that knows
what it means: lift the meaning of .iii out of its one implementation into a definitional evaluator
the system itself runs, differentially, against its whole proven corpus, forever — then let the
kernel judge, the zkVM attest, and the spore carry the proof.*

---

> **LEDGER ROW 17 — sizeof SILENT-ZERO IN TWO BEARERS (2026-07-14; found by ROUTE V's bootstrap-theater
> differential, fixed + chain-sealed same session).** THE FIND: `20_sizeof` (stage1_corpus) split
> four-way — native=4, eval=0, route-S=0, route-V=0. Localization: the PARSER always writes
> `sizeof.resolved = 0` (parse.iii's primary arm zeroes NODE_U+8; "parser-resolved" was aspirational);
> cg_r3 alone carries the fallback law (`r3_type_ref_byte_size`: scalar names u8/i8/bool→1, u16/i16→2,
> u32/i32→4, u64/i64→8, len>4 excluded, else 8); eval.iii:1245 and cg_svir.iii:1128 TRUSTED the
> never-filled field and silently produced 0 — the silent-wrongness class, invisible to every theater
> until route V met the bootstrap corpus (sizeof appears in NO square probe, NO independence probe, NO
> extern-free STDLIB KAT). ADJUDICATION: *native-incumbent* — the fallback law IS the language fact;
> both bearers now mirror it EXACTLY via per-TU helpers (`ev_sizeof_value`, `sv_sizeof_value`) that
> deliberately do NOT use their richer alias/array type machinery (richer-than-the-oracle is how a
> bearer CREATES divergence; sizeof-of-alias/array/pointer = 8 is the pinned fact, adjudicable later
> ACROSS ALL THREE together). THE CHAIN (sanctioned reseal): iiis-1 rebuilt + re-sealed (a6e468ae…),
> iiis-2 rebuilt (56b21679…) with stage1 parity 60/60, iiis-3 **BYTE-IDENTICAL FIXPOINT** (56b21679…,
> fixpoint seals updated from 4cc76c7d…), run_ddc GREEN, svir-backend gate GREEN with **A2 goldens
> 13/13 HELD** (sizeof absent from the typed theater — no reseal), tools re-minted, meaning gate
> re-run against the fixed eval, event gates GREEN. THE STANDING PIN: run_event_corpus.sh's theater
> now includes stage1_corpus — `20_sizeof rc=4` is a covered row, ratchet **83 → 104** (three-way
> native≡eval≡route-V = 104/104, eval-vs-routeV = 0). The instrument chain that caught this did not
> exist four commits ago: the event-primary waist → its standing tool → its corpus differential →
> the bootstrap theater — a NEW bearer's first sweep of an OLD corpus found a defect every existing
> gate had structural reason to miss.
