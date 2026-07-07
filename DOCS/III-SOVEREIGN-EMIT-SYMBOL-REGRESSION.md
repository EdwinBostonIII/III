# CRASH-AUDIT — sovereign COFF emitter drops module-`var` `.global` exports

**Status:** CONFIRMED + root-caused, 2026-07-07. Detection gate built; **fix NOT yet applied** (deep emitter
surgery — read the whole COFF-symbol path first, per the crash-debugging protocol). Found while verifying
Step 5 of `III-UNIFIED-ARCHITECTURE.md` (the eidos arm). Not an eidos defect — eidos compiles clean.

## The defect (one sentence)

`iiis-2 --compile-only` (the sovereign COFF emitter, made default by commit `408eb2d7` "C4 default FLIP:
SOVEREIGN emit is the DEFAULT") emits module-level `var` symbols into `.bss`/`.data` but **fails to mark them
EXTERNAL in the COFF symbol table**, even though the compiler's own textual dump `<mod>.iii.o.s` correctly
declares `.global L_FOO`. External references to those symbols therefore do not link.

## Proof (reproducible on a clean build)

```
# 1. rebuild so libiii_native.a / *.iii.o are fresh & consistent (avoid the OneDrive-dehydration husk):
bash STDLIB/scripts/build_stdlib.sh          # rc=0, FAIL=0, coverage uncovered=0

# 2. the binary .o lacks the symbol its own .o.s declares .global:
objdump -t STDLIB/build/iii/omnia_resolver.iii.o | grep L_RES_CTX_CACHE_PTR    # -> EMPTY (0)
grep -n 'RES_CTX_CACHE_PTR' STDLIB/build/iii/omnia_resolver.iii.o.s            # -> .global L_RES_CTX_CACHE_PTR + L_RES_CTX_CACHE_PTR: .zero 8

# 3. the SAME .o.s assembled by gcc `as` DOES export it -> the .o.s is correct; the binary emitter is wrong:
gcc -c STDLIB/build/iii/omnia_resolver.iii.o.s -o /tmp/r.o
objdump -t /tmp/r.o | grep L_RES_CTX_CACHE_PTR                                  # -> present (1)
```

Scope: 26 dropped globals in `omnia_resolver` alone; 42 across the 5 force-linked side-effect modules; the
emitter drops **every** module-`var` global (a pure-function module such as `verba_base64` is clean).

## Why it reddens the FULL corpus (and why nothing caught it)

- `COMPILER/BOOT/resolver_hot.s` (hand-asm resolve() memo-hit fast path, last touched 2026-05-26) does
  `lea r9, [rip + L_RES_CTX_CACHE_PTR]` — an EXTERNAL reference to a now-dropped global.
- `run_corpus.sh` force-links `resolver_hot.o` (`-Wl,--whole-archive`, in `SIDE_EFFECT_OBJS`) into **every**
  KAT → each KAT fails at link (`undefined reference to L_RES_CTX_CACHE_PTR`).
- Bootstrap stages 4/6 run `build_iiis2/3.sh --check-corpus`, which check **`stage1_corpus`** (compile-only
  language probes) — they never link the stdlib, so they stay green. `build_stdlib.sh` only *compiles*
  modules (FAIL=0) and doesn't link the corpus. So no existing gate exercises the broken path.

## The detection gate (built this pass — the missing teeth)

`STDLIB/scripts/emit_symbol_consistency_gate.sh` — a DDC-style self-consistency check: every `.global` in
`<mod>.iii.o.s` must be a defined symbol in `<mod>.iii.o`. RED now (flags the 26/42 drops), PASS on
pure-function modules. **Not wired into `build_stdlib`** (it would redden the build mid-campaign) — wire it in
once the emitter is fixed, so this class of regression can never silently reach the corpus again.

## Fix direction — TURN-KEY spec (NOT applied; needs a focused session + a deliberate golden re-seal)

**The fix is bounded and code-located** (verified by reading the sovereign toolchain this pass):

- `STDLIB/sovtc/sovparse.iii` **already has** the data-symbol table (line ~890: "PASS 1: build the
  data-symbol table (L_* -> section, offset within section)"), section ids `TEXT=0 DATA=1 RODATA=2 BSS=3`
  (line 199), running per-section offsets `SEC_OFF[4]` (line 210), and it already distinguishes data symbols
  from `.text` labels (lines 674-675). **The gap:** the *export* list `EXP_*` (line ~241, "recorded in pass
  D, .text...") records only `.text` (function) globals; `sp_export_off/n/namelen/namebyte` have **no section
  field**.
- `STDLIB/sovtc/sovcoff.iii` line 187 emits every export hardcoding `Sec=.text` (`SEC_SYMIDX[0]`) + a `.text`
  offset.

**Minimal correct change:** (1) in sovparse, when a `.global L_FOO` names a *data* symbol, add it to `EXP_*`
with its section + section-relative offset (both already in the data-symbol table); add an `EXP_SEC[]` array
+ an `sp_export_sec(i)` accessor. (2) In sovcoff line 187, use `sp_export_sec(e)`→`SEC_SYMIDX[sec]` for the
SectionNumber and the section-relative offset for Value, instead of the hardcoded `.text`.

**Verification ORACLE (makes offset bugs impossible to ship):** for each affected module, assert the sovereign
`.o` symbol table **byte-matches** the reference produced by `gcc -c <mod>.iii.o.s -o ref.o` — same symbols,
same sections, same Values. `objdump -t` diff. (This pass proved the `as`-path `.o` is correct; the sovereign
`.o` must converge to it.)

**Golden re-seal (REQUIRED — this is the trust-critical step):** `sovcoff.iii` is folded into the compiler
(C4), and 29 `COMPILER/BOOT` modules have module-scope `var`, so the fix changes the compiler's emitted `.o`
bytes → `iiis-2`/golden moves. After the fix: verify (a) `emit_symbol_consistency_gate.sh` PASS, (b) full
`run_corpus` FAIL=0, (c) the fixpoint is self-consistent (`iiis-2 == iiis-3` byte-identical with the new
emit), (d) the golden delta is EXACTLY the expected symbol-table additions (diff old vs new). ONLY THEN
re-seal deliberately (`build_iiis1/2.sh` re-seal path) and document. If (c) breaks or (d) shows anything
beyond the symbol additions → REVERT (`git checkout -- sovparse.iii sovcoff.iii`), do not re-seal.

**Alternatives (weaker — don't undermine proven organs):** retiring `resolver_hot.s`'s hot path would work
(the cold path is proven-equivalent — `proof_resolve.iii` / APOTHEOSIS C.9, gated by `RESOLVER_FORCE_COLD`),
but it deletes a proven optimization and its equivalence proof loses its subject; assembling the affected
module via `as` reintroduces gcc against the sovereign goal. The emitter fix above is the right one.

**After the fix:** `emit_symbol_consistency_gate.sh` → PASS, then a full `run_corpus.sh` → `FAIL=0`, then wire
the gate into `build_stdlib` so bootstrap-vs-corpus can never diverge on exports again.

---

## CRASH-AUDIT Phase 1 — full-path read (2026-07-07 fix session; every file below read END-TO-END)

**Files read completely:** `STDLIB/sovtc/sovparse.iii` (1068 ln), `STDLIB/sovtc/sovcoff.iii` (204 ln),
`STDLIB/sovtc/sovld.iii` (578 ln), `COMPILER/BOOT/emit.iii` (emit-surface + in-process assemble regions),
`STDLIB/scripts/emit_symbol_consistency_gate.sh`, `run_corpus.sh` link region. Reproduction re-confirmed live:
`objdump -t omnia_resolver.iii.o | grep -c L_RES_CTX_CACHE_PTR` = **0** while `.o.s:399` declares `.global`.

### The exact mechanism (corrects the turn-key spec above in one detail)

The spec above said the export list "records only .text globals". **Not quite:** pass D records EVERY
`.global`/`.globl` name — `sp_dir1` (sovparse.iii:969-976) calls `exp_record` with no section filter, so
`L_RES_CTX_CACHE_PTR` IS in `EXP_*` with its correct name. The drop happens at **resolution**:

1. cg_r3 `.o.s` intent correct: `.global L_FOO` + `L_FOO:` + `.zero N` in `.bss` (resolver .o.s:399-400).
2. `sovparse_full` resolution loop (sovparse.iii:1058-1065): `EXP_OFF[e] = lbl_find(...)` for EVERY export.
   `lbl_find` searches `LBL_*` — built ONLY from `.text` labels (`lbl_record` gated on `CUR_SEC == SEC_TEXT`,
   lines 513 + 877). A data symbol is never in `LBL_*` → `EXP_OFF = 0xFFFFFFFF`. **← root cause (logic:
   incomplete case — resolution assumes every global is a .text function).**
3. `sovcoff_emit` NEXP count (sovcoff.iii:115) and symbol emission (sovcoff.iii:184-190) both filter
   `sp_export_off(e) != 0xFFFFFFFF` → data exports silently dropped. Line 187 additionally hardcodes
   `SectionNumber = .text` + storage class EXTERNAL for every survivor.
4. `resolver_hot.o` (gcc-as, in `SIDE_EFFECT_NAMES`, run_corpus.sh:1824-1837) is force-linked
   (`--whole-archive`, run_corpus.sh:2050) into EVERY KAT with UND refs to the dropped globals → every link
   fails. Bootstrap stages check `stage1_corpus` (compile-only) → invisible there.

### Consumer audit (who reads `EXP_*` / the emitted symbols — all three verified safe for the fix)

- **sovcoff.iii** — the fix target (above).
- **sovld.iii `find_main_off`** (83-94): filters namelen==4 + "main"; L_-prefixed data exports cannot match.
- **sovld.iii in-process COFF linker `lk_add_object`** (287-307): ALREADY handles class-2 sec>0 symbols in
  .data/.rodata/.bss (`goff = db/rob/bb + val`) — written for gcc-as objects; sovereign data exports flow
  through the same path. Sovereign-to-sovereign links carry no *named* data refs (module data refs are
  section-relative, REL_SEC 1/2/3 → the scl==3 branch at 320-330), so behavior is unchanged there.
- **emit.iii** (904-923): pass-through (`sovparse_full` → `sovcoff_emit`); the 4 sovtc members reach
  iiis-1/2/3 via `libiii_native.a` (emit.iii:70-74) → fix propagates by stdlib rebuild + compiler relink.

### Layout-fidelity check (Value oracle feasibility)

Directive census over ALL `.iii.o.s` in the build: only `.section .global .text .asciz .ascii .quad .zero
.byte .long` (+ inert `.seh*/.file/.att`). **No `.align`/`.p2align`/`.space`/`.comm` anywhere** → sovparse's
linear `SEC_OFF` accumulation equals gas's layout exactly → symbol `Value`s must byte-match the as-reference.

### Latent hazard documented (NOT a defect today; NOT fixed in this pass — scope discipline)

9 module-var names are `.global` in TWO modules each (as-path had the identical exports pre-C4, corpus green):
`L_CC_N` (eidos_coincidence, numera_costed_cat) · `L_DP_BUF` (katabasis_descent_proof, numera_dp_exact) ·
`L_MEMO_ADDR` (aether_backend_memo, eidos_memo) · `L_RA_END`/`L_RA_START` (numera_reg_alloc,
numera_ser_regalloc) · `L_RM_N` (forcefield_ripple_metric, numera_rsa) · `L_RS_N` (forcefield_ripple_search,
omnia_reverse_search) · `L_RS_V` (forcefield_ripple_search, numera_rscode) · `L_SM_COST` (nous_search_market,
sanctus_self_model). None of these pairs co-links today: none is in `SIDE_EFFECT_NAMES`, archive members pull
by need, and the pre-C4 as-path (same export surface) was corpus-green. If a future KAT pulls both members of
a pair, gcc ld errors LOUDLY (multiple definition) — detected, not silent. Root fix if it ever fires:
module-prefix cg_r3's `L_` var labels (a whole-tree .o.s + golden move; out of scope for this regression).

### The fix, exactly (applied this session)

`sovparse.iii`: (a) `var EXP_SEC : [u32; 2048]`; (b) `exp_record` zeroes `EXP_SEC[EXP_N]` (also clears stale
cross-run state); (c) `sp_export_inject` zeroes it too (sovld entry injection = .text); (d) accessor
`sp_export_sec(i) @export`; (e) resolution loop fallback: if `lbl_find` misses, search the pass-D data-symbol
table (`sp_names_eq` over `SYM_*`); on a hit with `SYM_SEC ∈ {1,2,3}` set `EXP_OFF = SYM_OFF` (section-relative)
+ `EXP_SEC = SYM_SEC`.
`sovcoff.iii`: (f) extern `sp_export_sec`; (g) ONE emission predicate `exp_ok(e)` = `off != 0xFFFFFFFF &&
SEC_PRESENT[sp_export_sec(e)] == 1` used by BOTH the NEXP count (115) and the emit loop (184) — count and
emission stay in lockstep BY CONSTRUCTION (the named-reloc index contract `2*NS + NEXP + slot` depends on it);
(h) emit `SectionNumber = (SEC_SYMIDX[sec]/2)+1` + `Value = sp_export_off(e)` instead of hardcoded `.text`.

### Phase 2 — verify in the binary + the rebuild-chain transition (measured during the fix session)

- **First machine-code proof:** after round-A (`build_stdlib` FAIL=0, fixed sovtc code into the archive) +
  `build_iiis2.sh` relink, the new iiis-2 on `stage1_corpus/24_var_global.iii` emits `L_counter` as
  `(sec 2)(scl 2)` — EXTERNAL in `.data` — where the old emitter emitted nothing. objdump-verified.
- **The `--check-corpus` red herring that wasn't:** the equivalence gate compares `IIIS0_BIN` vs the fresh
  build — and `IIIS0_BIN` is **iiis-1.exe** (`build_iiis2.sh:56`, historical variable name), NOT the C seed.
  First post-fix run: `53 passed, 7 failed` — exactly the 7 data-section probes (`24_var_global`,
  `25_array_init`, `37/48/55/56/57`), because the stale iiis-1 still carried the old archive's emitter. This
  is the expected ONE-CYCLE TRANSITION SKEW, cured by rebuilding iiis-1 against the fixed archive first.
  **Rebuild order for any emitter-behavior change: `build_stdlib` → `build_iiis1` → `build_iiis2
  --check-corpus` → fixpoint → `build_stdlib` (round B: every module .o re-emitted by the fixed compiler).**
- **iiis-0 (C seed) needs NO change:** it is a gcc/as **driver** (`emit.c:3-5`) — its .o's always exported
  data symbols (verified live: `(sec 2)(scl 2) L_counter` + gas's `.xdata/.pdata`). The seed never had the
  bug; the sovereign emitter introduced it at the C4 flip by resolving exports only through the .text label
  table.
