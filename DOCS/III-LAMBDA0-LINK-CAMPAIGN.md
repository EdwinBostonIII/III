# Λ0 WHOLE-SEED LINK CAMPAIGN — live state ledger

> **STATUS: IN FLIGHT (2026-07-08).** The Φ1/Λ0 chain after the v2/CALL2 + doubles rungs: link all
> nineteen iiis-0 TUs into ONE verified SVIR v2 module. Every number here was measured this session.

## Where the chain stands

| Rung | State |
|---|---|
| SVIR v2 container + CALL2 (>255 fns) | **LANDED** 46e6b7e2 — all 6 consumers + ccsv; teeth oob=9/trunc=1 |
| seed-runtime teeth repair (in-tree fixture) | **LANDED** 98ade8e1 |
| ccsv EXACT DOUBLES + opaque-cast + fm variadic/stringize | **LANDED** ff061807 — 22-case KAT bit-exact vs gcc hardware on interp/x86/wasm |
| 7-TU structural zero (1,210 fns) + ratchet pin | **LANDED** ff061807 (run_seed_verify: main.c added, `verify_fail=0` is a hard pin) |
| ccsv link-prep: `vmap` FNV manifest + `--membase` + strict `dbg` | **LANDED** 6fa6cec0 |
| 19-TU frontier | **CLOSED 9cc9597c** — 0 fails / 2,569 fns, ALL NINETEEN TUs at structural zero |
| svir_ld.iii + run_seed_link.sh | **GREEN** — 19 TUs -> ONE v2 module (1,214,998 B); G1 svir_verify=VALID; G2 statics 476,928 < 917,504; G3 no-arg parity interp==gcc==2 |
| run_seed_sovereign.sh (capstone arc Φ1) | ABSENT (the honest RED) |

## The 19-TU truth (build_iiis0.sh's own filter)

main lex sema emit ast cg_r3 parse **+ acc ceiling cg_r0 cg_rm1 cg_rm2 hexad_check iii_cg_pe_iiis1
jit_emit link proof sid witness_alloc**. gen_*/sign_*/verify_*/xii*/iiis1_*/rm2_driver/_* are excluded
by the build script itself (separate tools / harnesses).

**First-contact measurement (never-ccsv'd TUs):** ceiling 14/0, cg_rm2 181/0, hexad_check 101/0,
iii_cg_pe_iiis1 78/0, proof 150/0, sid 157/0, witness_alloc 100/0 — **seven of twelve at structural
zero immediately** (the class-fix corpus generalizes). Remaining 21 fails:

| TU | fails | named fns | diagnosed class |
|---|---|---|---|
| acc.c | ~~1~~ **0** | ~~iii_acc_emit_audit~~ | **FIXED**: `prescan_fptd_globals()` (file-scope fn-ptr-typedef globals = 8B scalars; must run AFTER prescan_struct which fills FPTD) + indirect-call-through-GLOBAL arm (LOAD64 cell → CALL_INDIRECT) |
| cg_r0.c | ~~5~~ **0** | — | **FIXED** by two classes: (a) `(cast)&local` — prescan_addrof called `)`-then-`&` binary; now walks back to the matching `(` and recognizes casts → the local spills (probe p_castaddr, interp==gcc==71); (b) chained-arrow POINTER-SUBSCRIPT tail `cg->ast->source_buf[off+i]` (probe p_label2, interp==gcc==198) |
| cg_rm1.c | ~~4~~ **0** | — | **ZERO**: the last was the ENUM-CONST array dimension (`T slots[III_HV_...]`) — prescan_structarr now cidx-sizes it |
| jit_emit.c | ~~7~~ **1** | iii_jit_self_test (**rc=2 unknown-opcode**) | the trampoline six were the enum-dim class (G_JIT_TRAMPOLINE) — FIXED; self_test emits an unknown byte — inspect |
| link.c | ~~4~~ **3** | iii_link_cmp_entry, iii_link_sort_entries, iii_link_build_manifest | sha256_final **FIXED** by the COMMA-STATEMENT class (`h->buf[56+i]=v, bits>>=8;` → stmt_end() recurses into pstmt for each clause; probe p_link f2, interp==gcc==79). cmp_entry trio: NOT the cast-decl shape (probe f1 passes) — re-diagnose (memcmp/strcmp chains? `(a->f, b->f, 32)` arg shapes?) |

Standing: **2,569 fns / 4 fails = 99.84% structural** (jit_emit 1 rc=2; link 3 re-diagnosis pending — the cast-decl-pair probe PASSES, so cmp_entry trio is a different shape). Landed this session: 46e6b7e2 (v2/CALL2),
98ade8e1 (teeth), 311a81fb (witness), ff061807 (doubles + 7-TU zero), 6fa6cec0 (link-prep),
4091e375 ((cast)& + ledger), + the chained-arrow / fptd-global / comma-statement classes.

## Link-plan numbers (7-TU extraction; rerun for 19 after the fixes)

- 535 defs + 675 import refs (7 TUs). Defs link BY POSITION; imports resolve BY NAME.
- 9 duplicate def names = the static sha256 family; **imported by nobody** → keep all copies, zero ambiguity.
- Unresolved-by-design (CRT boundary whitelist for executor shims): clock fclose fgets fopen fprintf
  fputc fputs fread fseek ftell fwrite pclose popen rewind system tmpfile.
- FNV manifest (fn-name-as-value sites; `ccsv f.c vmap` → trailing `//V emitfn bodyoff fidx` lines):
  main 2, ast 9, parse 1 → 12 sites feed 97 CALL_INDIRECTs. Values are rewritten to GLOBAL indices at
  their creation sites; dispatch sites inherit correctness. Global fn0 = main.c's main (no stored
  handler can be 0 → `if (handler)` null-checks stay sound).
- Memory: per-TU statics (7 TUs) total 180,878 B — 5× under the shared fixed layout (shadow cell
  982776 / VA_BUF 983040 / HEAP_BASE 1048576, all deliberately SHARED; one bump-heap cursor cell).
  `--membase N` compile-time-relocates a TU's statics (MTOP starts at N): two-pass driver = pass 1
  measure MTOPs (dbg header prints MTOP), pass 2 recompile at cumulative bases → every baked address
  (econst + data-section pointer slots) correct by construction. Linked data section = copy each TU's
  data bytes AT its membase (holes zero-fill).

## svir_ld design (frozen)

Inputs per TU: `X.svbin` (raw container via svir_dump), `X.names` (dbg), `X.vmap` (FNV lines).
main.c FIRST (its fn0 = global entry 0), then the rest in build_iiis0's sort order.
1. Parse containers (v1/v2); classify imports (body == `0x8A len name`, blen==2+len).
2. Global index map: defs by position per-TU; imports by NAME against the def symtab (dup def names
   that are imported → HARD ERROR; measured zero today); still-unresolved names → dedup, re-emit as
   0x8A imports at the tail (executor loud/shim behavior preserved).
3. Rewrite bodies op-walking with the anchor's width table (01+8, 10/11/50/51+1, 70+2, 73+1, 74+3,
   8A+1+len): CALL/CALL2 target remap; emit 0x70 if gi<256 else 0x74 (deterministic); FNV sites
   (input body offsets) rewrite the CONST_I64 operand to the global index.
4. Emit ONE v2 container as a gen_svir `.iii` text (emit_module format) + concatenated data section.
Exit gates: `svir_verify(linked)=0`; interp(no-argv linked) rc == gcc iiis-0 no-arg rc; then the
stage1_corpus byte-match (task #4, run_seed_sovereign.sh).

## Session build artifacts (STDLIB/build/_v2bt/)

ccsv_d.exe (current ccsv), {main,lex,sema,emit,ast,cg_r3,parse}.{svbin,names,imports,defnames,vmap},
nx_*.{iii,o,names} (the 12 new TUs), svan.awk (container analyzer), unresolved.txt, td_* (double KAT).

## THE LINK IS GREEN (2026-07-08, second session)

`run_seed_link.sh` end-to-end: per-TU extraction at cumulative membases (main first; total statics
476,928 B — 52% of the 917,504 ceiling), `svir_ld` resolves 19 containers into ONE v2 module of
**1,214,998 bytes** — and the 97-line anchor verifies it: **svir_verify(whole seed) = VALID**.
First execution: `interp(linked, no argv)` exits **2 == gcc iiis-0's no-arg rc** — the usage path
crosses no resolved import (undeclared stdio = compile-time no-ops; stderr TEXT is dropped, the
exit CODE is the contract at this rung).

Bugs the link surfaced and fixed en route:
- ccsv membase now shifts DLEN/strings/statics as one cursor (prescan_arr's `MTOP=DLEN` had
  obliterated the base) while SDAT stays local-indexed (`data_put*` subtract MEMBASE); the emitted
  data section is the LOCAL image, placed at the TU's base by the linker.
- **v1 u16 data-length overflow**: a >64 KB data image silently truncated mod 65,536 — jit_emit's
  140 KB image was truncated EVEN STANDALONE (pre-existing, invisible to the structural floor).
  The container now switches to v2 when `data > 65,535` as well as when `FN > 255`.  jit standalone
  re-verified `# 93 0 0 0` with v2 data.
- svir_ld //D sanity forensics (`want/got` + base/ei/foff tail fields in the manifest) — how the
  truncation was found.

## Next (task #4 road)

1. Host-shim rung: svir_interp dispatches the 16-name CRT whitelist (fopen/fread/fwrite/fclose/
   clock/...) to the host — upgrades G3 from exit-code parity to REAL compile runs.
2. argv delivery into the linked seed under the interp (main(argc, argv) locals).
3. `run_seed_sovereign.sh`: linked seed compiles stage1_corpus; emitted artifacts byte-match
   gcc-built iiis-0's. Then run_completion.sh 8/8.

## THE SEED EXECUTES — and the parse-runtime frontier (2026-07-08, session 3)

The linked whole-seed now RUNS as a compiler (commit 76901783). Proven working end-to-end:
- **Host shims** (svir_interp): fopen/fclose/fread/fwrite/fseek/ftell/rewind/fgets/clock dispatch to
  the CRT by import-name; a full fseek/ftell/fread read-path round-trips a file byte-exact.
- **argv delivery**: interp stages argv into MEM[4,190,000..] (top — the first try at 900,000 collided
  with the shadow stack descending from 917,504); argv pointer, indexing, string content, strcmp exact.
- **char\*\* width fix** (latent ccsv bug argv exposed): a `char **argv` PARAM gave `argv[i]` char-width
  (1) not pointer-width (8) → the pointer truncated to its low 16 bits. Param loop now tracks pointer
  depth. 19-TU structural zero HELD (2,569/0), lex behavioral IDENTICAL, re-link verify=VALID.

**The frontier (S4 of run_seed_sovereign.sh):** the seed lexes correctly (never LEX_FAIL=10) but
`iii_parse_module` returns **false on even a bare `module m`** (PARSE_FAIL=11 vs gcc's 0). Because rc
is 11 not 198, *no fprintf import was hit* → parse returned false while recording ZERO errors: a
parse.c runtime bug on the simplest path. parse.c is at structural zero but has **no behavioral
harness**, so this is the first time it has ever executed — the documented "structural zero is
necessary but not sufficient." Input bisection (all vs gcc):

| input | seed | gcc |
|---|---|---|
| `module m` | 11 | 0 |
| `module m` + `fn f() -> u64 { }` | 11 | 0 |

**Next campaign (task #4 finish):** build a parse.c behavioral harness (like _lexharness), run
`iii_parse_module` on `module m` through ccsv→interp vs gcc, trace the diverging op. The most likely
suspects, in order: (1) the lex→parse token hand-off wiring in iii_run_pipeline through the interp;
(2) a parse.c internal state-machine op that structural-zero can't see (an uninit read, a wrong
branch); (3) a residual ccsv codegen bug in a construct parse.c uses that lex.c doesn't. Then S4 goes
byte-identical and run_completion.sh's seed_sovereign member closes.

## Parse-runtime frontier LOCALIZED (session 3, cont.) — _parseharness differential

Built `COMPILER/BOOT/_parseharness.c` (the parse twin of _lexharness): runs lex→ast→parse on a fixed
snippet, prints `PARSE ok=<0|1> ec=<errcount> nd=<ndecl>` + per-error `code/line/col/saw`. Uses the
public headers (separate objects) so the per-TU static sha256 helpers don't collide. Differential:

| route | output |
|---|---|
| gcc (lex.c+ast.c+parse.c) | `PARSE ok=1 ec=0 nd=1` |
| ccsv-per-TU → svir_ld → interp | `PARSE ok=0 ec=2 nd=1` + `err[0] code=1118864 line=0 col=0 saw=0` + `err[1] code=2 ...` |

**Pinpointed:** the AST builds correctly through the interp (`nd=1` matches gcc), so lex, ast, and the
link are all fine. parse.c records **2 spurious errors** that gcc doesn't — `err[0]`'s code is a
DETERMINISTIC garbage `0x111790` (a corrupted struct field, stable across runs → a layout/logic bug,
not an uninit read). The bug is isolated to **parse.c's error-recording path**, exercised only at full
parse execution (structural-zero can't see it; lex.c's harness passes; this is the first time parse.c
has ever run).

**The next campaign (S4 close):** dis-trace which parse.c op records the two errors on
`module m\nfn f() -> u64 { return 7u64 }` — likely the decl-loop termination / EOF handling or the
error-struct write (the 0x111790 code suggests a wrong field offset or a pointer written where the
`int code` belongs). The `_parseharness` differential makes each hypothesis a ~90s rebuild-and-compare.
When ec matches (0) and the compile is byte-identical, run_seed_sovereign S4 goes green and
run_completion.sh's seed_sovereign member closes — FULL CAPABILITIES in the plan-of-record sense.

## S4 campaign (session 4): FOUR bugs fixed, the seed reads its source

Pushing run_seed_sovereign S4 (the linked seed compiles a .iii byte-identical to gcc iiis-0). Built the
_parseharness differential (lex→ast→parse, token-dump + per-error codes, static/heap/file-read modes)
and a svir_ld `map` mode (global symbol table). Chain of bugs found and fixed:

1. **`T t = *fn()` struct-copy** (e6893a9e): parse-primary's `iii_token_t t = *iiip_peek(st)` read
   `t.kind=0` (direct deref read 5) → switch default → spurious EXPECTED_EXPR. ccsv's struct-value
   local init handled `=call()`, `=var`, `=p->field` but NOT `= *ptrExpr`. FIXED. Parse harness closed
   (interp `ok=1 ec=0 nd=1` == gcc), 19-TU structural zero held.

2. **SEEK/EOF constants** (ec31f85b): `<stdio.h>` skipped → `SEEK_SET/CUR/END`, `EOF` undefined in
   main.c → `fseek` garbage whence → `ftell` returned 83 for a 45-byte file. ccsv now predefines them.

3. **CRT stdio imports** (ec31f85b): fopen/fseek/ftell/fread/fclose/fwrite/fgets from `<stdio.h>`
   (skipped) had no prototype → prescan_imports never registered them → their CALLs mis-dispatched in
   the linked seed (fopen returned garbage; only `clock` worked, declared by the double-runtime). ccsv
   now appends a CRT prototype prelude (`crt_tail`, via `src_has_word "fopen"`) — non-varargs file-I/O
   only (fprintf/fputc/fputs OMITTED: varargs mis-shape breaks 12 fns; stderr-only, not on the success
   path). Interp shims fprintf/fputc/fputs/fflush/signal/getenv as no-ops.

4. (char** element width, from session 3, 76901783 — same class.)

**MEASURED milestone:** the linked sovereign seed now READS ITS SOURCE correctly (traced `LN=45
module aa\nfn foo…` — was garbage `LEN=83`). rc advanced 11(parse)→2(read)→11(parse). 19-TU structural
ZERO holds (0/2,578).

**The remaining frontier (S4 still red):** with correct source reaching parse, the full 19-TU seed
STILL returns PARSE_FAIL — yet BOTH the 4-TU parse harness AND the 18-TU harness (all seed TUs except
main.c, using the harness's own main) parse the same input correctly (`ok=1`). So the divergence is
SPECIFIC to main.c being the entry TU. Ruled out (each tested): membase (harness at 350K passes),
cross-TU static collision (18-TU harness passes), the read path (source reaches parse intact),
iii_argv_canon_mhash and the source mhash (disabled, no change). The suspect set narrows to main.c's
`main()`/`iii_run_pipeline` env: a memory interaction (heap/AST-arena layout, or a high-global-index
CALL2/fn-ptr remap that only the +356-fn main.c pushes parse.c over) that corrupts parse's execution
while leaving the source buffer intact. Attack: instrument parse.c's first recorded error IN the seed
(minimal perturbation) to see if it's the same t.kind=0 class at a second struct-copy site, or a new
class; and diff the linked parse.c body (4-TU vs 19-TU link) for a CALL/CALL2 that remaps differently.

## S4 UNBLOCKED (session 5, 2026-07-08): parse WORKS — frontier moved 11→16

The "parse.c runtime divergence" was a MISDIAGNOSIS. The real chain, found by bisection (place a TU at a
high membase, probe a string literal `"rb"` through the interp — it read 0; traced svbin→svir_ld→linked
.iii all CORRECT, but `ib()` in the interp read 0; `objdump -h linked.o` showed `.data` = **0x000FFFFF**
(1,048,575) while the array is `[u8; 1,236,822]`):

1. **STALE iiis-2 / 1 MiB sovas truncation (THE root S4 blocker).** `COMPILED/iiis-2.exe` (built 07-07
   23:46, commit f0247b0e era) linked an OLD `STDLIB/sovtc/sovas.iii` whose `DATA_BUF` was `[u8; 1048576]`
   with `if DATA_LEN < 1048575` and **no overflow flag** — it SILENTLY truncated `.data` at 0xFFFFF. The
   4 MiB fix (`[u8; 4194368]`, LOUD `SOV_OVF`) was committed LATER (c9c4d733, 07-08 15:22), so the binary
   lagged the source. The linked seed's data above container offset ~1.07 M — i.e. every TU at membase ≳
   287 K: **jit_emit, lex@367394, link, parse@419628, sema, sid, witness_alloc** — read as ZERO. lex's
   `III_KEYWORDS` table was zeroed → `module` lexed as an identifier (k4) not a keyword (k12) → parse
   failed → rc=11. **Fix:** `build_stdlib.sh` (FAIL=0) → `build_iiis2.sh` rebuilt the chain with the 4 MiB
   sovas. Verified: `[u8;1236822]` array now emits `.data`=0x12df56 (full); corpus determinism HELD 12/12
   (iiis-1 == iiis-2 — the sovas buffer size is irrelevant to sub-1 MiB programs). rc 11 → 198.

2. **ccsv crt_tail only triggered on `fopen` (a real ccsv bug).** After the truncation fix the seed hit an
   UNRESOLVED IMPORT (198). First: `system` — iiis-0's `emit.c` is a gcc/ld DRIVER: it shells
   `gcc -c -x assembler … -o out.o out.s` via C `system()` after `putenv`-forcing SOURCE_DATE_EPOCH=0/LC_ALL=C.
   Added `system`/`putenv` interp shims (the .s is written through the fopen/fwrite shims; system() runs
   host gcc). rc 198 → 16. Then the .s was written EMPTY: `cg_write_bytes` calls `fwrite`, but ccsv appends
   the CRT import prototypes (`crt_tail`) only when a TU uses `fopen` — the codegen TUs (cg_r3/cg_r0/cg_rm1/
   cg_rm2/…) write the .s via `fwrite` and NEVER call `fopen`, so their `fwrite` was UNDECLARED → compiled
   to a call that never reached the shim (FW=0). **Fix:** `crt_tail` now triggers on `fwrite` OR `fopen`
   (ccsv.iii ~line 2766). The cg header now writes (FW=5, 155 B, byte-matches gcc's header).

**Remaining S4 frontier — a VALUE-level garbage-high-32 codegen bug in the cg path (NOT address).**
Instrumenting exec_fn by global fn-index pinned it precisely: on `module sovcap\nfn main()->u64{return
7u64}` the cg calls `cg_write_bytes` exactly **5×** (the 5 header lines: the two `#` comments, `.att_syntax`,
`.file`, `.section .rodata`) and then **`emit_function` (cg_r3 G310) is NEVER called** (`ef=0, cg_writef=0,
emit_stmt=0`). So the cg writes the header and the module decl/function loop then skips the `FN_DECL` case —
`mod->u.module_.decls.count` reads 0 or `d->kind` mismatches. Crucially this is TRUE EVEN WITH interp
address-masking (`a & 0xFFFFFFFF` → DR 88→0): masking clean addresses does NOT make `emit_function` run.
So the fault is a **value**-level garbage-high-32 bug, not an address one — some computed value in the cg's
decl/function loop (a count or an AST-node-kind) carries junk in bits 32..63 (e.g. `iii_history_append`
stores `history_count = (7<<32)|4`), and `msb`/address-masking can't repair a *value* that flows through a
comparison. Note: several earlier "garbage" reads (a=token-addr, v=`(7<<32)|4`) turned out to be LEGIT
8-byte struct-copy chunks of two adjacent u32 token fields — NOT the bug; the real defect is narrower.
Root = a ccsv (or interp) op that fails to zero-extend a 32-bit intermediate before it's stored/compared
as 64-bit — exercised for the FIRST time now the full compile runs. Next: trace the exact value the cg's
`for i<decls.count` / `switch(d->kind)` reads (fn indices: iii_ast_root_module G108, iii_ast_get G132,
iii_ast_list_at G136, cg_r3 emit_function G310). S4 = rc 16 (was 11).

## S4 ROOT CAUSE PINNED (session 6, 2026-07-08): ccsv mis-compiles `p->arr[p->cnt++] = v` — the AST arena append

The session-5 "Next" was executed with an instrumented interp (`STDLIB/build/_s4probe/svir_interp_tr.iii`:
per-G call counters gated on the first cg fwrite + arg/ret rings on G132/G136).  Measured, on the repro
`module sovcap / fn main() -> u64 { return 7u64 }` (seed_rc=16, fw=5, exactly as session 5):

- `c108=2 c132=4 c136=2 c310=0` — the cg's TWO module fetches ran, **the decl loops DID iterate**, and
  `emit_function` was never dispatched.
- G136 (list_at) received the decls list as the by-value chunk `4294967297` = `{offset=1, count=1}` —
  **`decls.count` is CORRECT**; the garbage-high-32 / count-reads-0 hypotheses are DEAD at this level.
- G136 **returned 48** — and G132 then received `a=48` (pool 0, slot 48: not a node index; the sentinel
  path swallows it, `d->kind` matches nothing, the loop ends silently; rc=16 from the empty emission).
  The module node itself is `805306372` = 0x30000004 (pool 3, slot 4) — 48 = 0x30 is its POOL BYTE.
- The full-run ring `d=0:48 ×4, d=5:48 ×2` (fw-phase:ret for every list_at on THAT list): **48 from the
  first pre-cg read** — the arena slot was corrupt from PARSE-time write.  Corollary: sema's "green" was
  VACUOUS — sema.c:832's walk got the same 48, iii_ast_get'd the sentinel, and `continue`d past the one
  decl; it type-checked NOTHING and reported no errors.

The write site is `ast.c:1227` — `ast->list_arena[ast->list_used++] = node_index;` — and the C SHAPE
mis-compiles, reproduced OUTSIDE the seed (falsifiers COMMITTED as `STDLIB/sovir/_s4_probe4.c` /
`_s4_probe4b.c`; scratch copies + the instrumented interp in `STDLIB/build/_s4probe/`, recreatable
from the hook description above):
- `probe4b.c` (the EXACT shape: helper `app(A *ast, unsigned v) { ast->arena[ast->used++] = v; }`):
  gcc=99 ; ccsv->interp=**7** ; ccsv->svir_x86->sovereign-exe=**7**.  Both sovereign routes agree ->
  the defect is in CCSV'S EMITTED SVIR (the interp is exonerated; the two independent executors
  faithfully run the same wrong ops).  used++ advances; the STORED VALUE reads back wrong.
- `probe4.c` (dot-variant on globals: `g.arena[g.used++] = v`): gcc=99, ccsv->interp=**20** — the
  post-increment on the index FIELD is LOST entirely (used stays 1).  A sibling handler, differently
  broken.
- Contrast probes that PASS both routes (the shapes the cg loop itself uses): `probe1.c` (depth-3 union
  chain in a loop condition + chain-to-struct by-value arg) = 99/99; `probe2.c` (+ nested-call-arg,
  const, call-init pointer) = 99/99/99.  The READ side (`arena[list.offset + i]`, ast.c:1409) scales
  correctly — only the append's indexed-store-with-member-post-increment shape corrupts.

**Class**: ccsv pointer-FIELD indexed STORE where the index is a MEMBER POST-INCREMENT — the store
misses/mis-scales the element write (48 = the value's top byte visible at the correct element offset =
a ~3-byte-low landing), and in the dot-variant the ++ never lands.  The fix belongs in ccsv's pstmt
store walker (the `p->arr[i] = v` family, index-expression = `member++`); falsifiers = probe4/probe4b
+ rerun run_seed_sovereign S4 (rc must move past 16) + the _tr trace (list_at must return 0x30000003-
class indices and c310 must go >0).  NOT YET FIXED — next session's first edit.

## S4 FIX LANDED (session 6b, same day): C POINTER ARITHMETIC — EV_PSZ stride scaling in ccsv

The session-6 store-walker hypothesis was REFINED by op-dumping the emitted SVIR (probe-only
`svir_opdump.iii`): the arrow append `ast->arena[ast->used++] = v` compiles CORRECTLY (probe4b's F1:
temps, ++, ×4, deref, STORE32 all right — its rc=7 came from the CHECKER's dot-global read, a
separate defect).  The REAL killer, found by op-dumping the LINKED SEED's fn 127
(`iii_ast_open_list_commit`): the memcpy dest **`ast->list_arena + ast->list_used`** compiled as a
RAW byte ADD — ccsv had NO C pointer arithmetic (`LOAD64 arena; LOAD32 used; ADD` — no ×4).  With
used=1 the appended index `[NN 00 00 30]` landed at arena bytes 1..4, so the element read at bytes
4..7 returned 48.  Parse corrupted its OWN arena through the open-list commit; the append/read
functions were innocent.

**Fix (ccsv.iii)**: `EV_PSZ` — pointee-stride side-channel mirroring EV_SGN/EV_DBL.  Set by pointer
prims (pointer LOCAL via LPSZ — now RESET per-slot in ladd, stale-slot leakage killed; global
scalar-pointer via apsz; ARRAY DECAY = aesize; `p->ptrfield` read via fieldptsz).  Consumed by
ebin's additive ops: ptr+int / ptr−int scale the INT by estride(pointee); int+ptr mirrors through a
temp; ptr−ptr divides back to an element count.  char* = stride 1 = estride no-op (byte-identical).

**Proof (all measured)**: `_s4_probe7.c` (4-class battery: local ptr+int / FIELD ptr+int / ptr−ptr /
int+ptr) gcc=99, interp=99, sovereign-x86=99.  `_s4_probe6.c` (the FULL ast.c push/grow/realloc
sequence) 99/99/99.  probes 1/2/5 stay 99.  `run_ccsv.sh` ALL strokes green including the whole-seed
verify_fail 0/865 floor.  THE SEED (19-TU relink, fresh): trace now shows `list_at -> 805306371`
(0x30000003, the REAL fn-decl node), `emit_function RUNS` (c310=1), fw 5→32 writes, and the seed
EMITS a .o (632 B).  Every session-6 falsifier bar MET.

**Frontier MOVED (still rc=16, much deeper)**: the emitted .o differs from gcc-iiis-0's: 17 vs 16
COFF symbols + section-size deltas, and the seed exits 16 (the D11 keep-walking error path: some
emit_function sub-step records an error while emission continues).  `objdump -t` diff (measured):
the seed's `.text` scnlen = **0x0** (ref 0x30 — the body never emitted), the **`main` symbol is
MISSING**, and two data sections are exactly 4 bytes short (0x5→0x1, 0xc→0x8 — the ".asciz name"
is EMPTY).  One cause fits all three: **the fn NAME (`d->u.fn_decl.name`, an iii_src_text_t) reads
back EMPTY at emit time** (offset/length pair zero or the source-buf read fails) → no label, no
.globl, empty ring3 string, body emission errors (rc 16).  Next microscope: dump the seed-written
.s TEXT and trace the name.offset/length values through emit_function's source-buf reads
(`iii_ast_source_buf(cg->ast)[name.offset+i]` — the call()[i] shape).
Still open (falsifiers committed, non-blocking for S4): the dot-global pointer-field indexed READ
(`g.arena[1]` → inline-array mangle; _s4_probe4b rc=7) and dot-global indexed STORE with member
post-inc (`g.arena[g.used++]=v` loses the ++; _s4_probe4 rc=20) — the seed never uses these shapes;
`sizeof(unsigned int)` evaluates as 8 (two-token type; `sizeof(uint32_t)`=4 is correct).

## S4 CLOSED (session 7, 2026-07-08): the sovereign seed compiles BYTE-IDENTICAL — 4 defects, each probe-pinned

**THE GATE PRINTS**: `S4 compile parity : GREEN -- interp(linked) .o BYTE-IDENTICAL to gcc iiis-0.
THE SOVEREIGN SEED COMPILES.` (`run_seed_sovereign.sh` rc=0, all four stages green; the interp'd,
ccsv-compiled, svir_ld-linked 19-TU seed compiles `fn main() -> u64 { return 7u64 }` to a 706-byte .o
that `cmp`s equal to gcc-built iiis-0's, .s byte-identical too, exit codes 0==0.)

Session 6b left rc=16 with `.text` 0x0 + `main` symbol missing.  The .s diff (both survive as
`_sov_fn_{g,s}.o.s`) split the symptom in two: the name-bearing strings were EMPTY and every
FORMATTED instruction line was a bare newline while `cg_write_str` literals landed intact.  Four
root causes, in discovery order:

1. **ccsv vsnprintf/vsprintf/snprintf returned constant 0** (`econst(0)` after `emit_fmt`) — read
   directly from the builtin's lowering.  cg_r3's `emit_line`/`cg_writef` copy `buf[0..n)` with
   `n = vsnprintf(..)`, so every formatted line wrote 0 bytes + `'\n'`.  Fix: a `t0` temp captures
   the dst start; the builtins return `td_final − t0` (the written count, C semantics).  `emit_fmt`
   also gained the `%l+` length-modifier skip (`%llx/%llu/%lld` → `%x/%u/%d`; they were emitting
   `lx`/`lu` literals).  Falsifier `_s4_probe8.c` (the emit_line shape: 2 named + varargs,
   `sizeof buf` paren-less, n gating the copy): baseline interp=60, now 99.
2. **Struct-valued ASSIGNMENT was missing** — the decl-INIT forms (`T t = p->field` / `= f()` /
   `= *p` / `= var`, ccsv 1577-1587) existed; the bare ASSIGN statements fell through to scalar
   paths: `t = st->lookahead` clobbered a slot (frame bytes stayed zero), `*out = t` stored 8 bytes
   of the RHS *address* (`emit_av(8)` on a >8B pointee), `nn->u.fn_decl.name = iiip_text_of(&name)`
   and `g_name = f()` were parsed then DROPPED (line-1872 fallback / aisc≠1 skip).  parse.c's token
   flow (advance → expect `*out=t` → `text_of` → fn_decl store, plus the lookahead2 promote
   `st->lookahead = st->lookahead2`) is EXACTLY these shapes — the fn name was zero IN THE AST, so
   emit honestly wrote `.asciz ""`, no `.global main`, label `L_`.  Fix: `srhs_ok` (pure predicate)
   + `emit_srhs_addr` (RHS address into a temp: var / `*ptrExpr` / `p->field`) + `emit_scopy_to`
   (byte-loop copy, mirrors `emit_bcopy_v`), grafted into FOUR dest sites — assign (≤8B packed
   STORE64 for any rvalue incl. calls/ternaries + >8B copy + `= f()` sret), deref-dest, plain
   arrow-field (≤8B packed / >8B copy / sret; `fieldptsz==0` excludes struct-POINTER fields —
   those stay 8B scalar stores), arrow-dot-chain final-field.  Falsifiers `_s4_probe9/9b/10/10b/10c.c`
   (read side was already green — 9/9b pinned that; 10=91, 10b=50, 10c=40 baselines) — all 99 now.
3. **`cg->pe_static_fp[i] = NULL` wrote byte 0 AT ADDRESS i** — `const char *pe_static_fp[128]`
   is an INLINE ARRAY of pointers; `fieldptsz>0` (char pointee = 1) sent `p->field[i]` store AND
   read through the scalar-POINTER deref arm (LOAD64 the field, +i×1, 1-byte access).  emit_function
   (G310)'s reset loop swept [0,127] with zeros — measured live by the interp value-tracer
   (`LW=128[0,127]`) — wiping main.c's low data image incl. the `"rb"` mode literal at addr 63 used
   by `iii_mhash_file`'s read-back `fopen` → `fopen(path, "")` → NULL → **silent EMIT_FAIL 16 with a
   byte-correct .o already on disk** (both error fprintfs are unregistered no-ops).  The four
   chain-`[k]` sites already carried `fieldisarr` guards; the two DIRECT `p->field[i]` arms (store
   1862, read 1275) now do too.  Falsifier `_s4_probe11.c` (pointer-array field: reset loop +
   neighbor integrity + element round-trip + low-memory canary): all 99.
4. **`ferror` was unregistered + unshimmed** — `iii_mhash_file` calls it on every read-back (706 <
   8192 → first fread iteration).  Registered in ccsv's `crt_tail` (import 0x8A), shimmed in
   `svir_interp` (host passthrough).

**The microscope that found #3/#4** (now a permanent gated instrument, `FPRINTF_DBG` in
svir_interp.iii, OFF by default — the ARGV_DBG precedent): silent-fprintf fmt dump, per-fopen
path+mode+result, system/ferror rc traces, low-address write watch with `LW=count[min,max]`
extent, and the startup data-image window.  The decisive traces: `FO=_s7f.o,63=:0` (mode string
EMPTY at a KNOWN-carried address) then `W!=310@0+1=0 … LW=128[0,127]` (the writer + exact extent).

**Verification (all measured this session)**: probes 8/9/9b/10/10b/10c/11 = **99 on gcc + interp +
svir_verify + sovereign-x86-native** (sovas+sovlink, 4-way each); `run_ccsv.sh` rc=0 with the
whole-seed floor **verify_fail 0/865** (twice: after the struct/vsnprintf fixes, again after
crt_tail+fieldisarr); `run_fnptr_gate.sh` ALL PASS (the edited interp's teeth);
`run_seed_sovereign.sh` **rc=0, S1-S4 ALL GREEN** — S4 stays in the gate as regression teeth.

Open (ledgered, seed-unused, falsifiers named): global `char *X = "lit";` pointer-init reads wrong
(probe11's first draft hit it; the seed has ZERO such globals — grep-verified across all 19 TUs);
the session-6b dot-global leftovers above; `%0Nx`-style width pads in emit_fmt (main.c diagnostics
only — never on the compile-success path); the interp's BADW const-image watchdog counts the seed's
legitimate writable statics (g_orch etc.) because ccsv carries them INSIDE the data image — a
layout-classification refinement, not a correctness defect (the byte-identical .o is the proof).

## CORPUS-SCALE PARITY (session 8, 2026-07-08): the next rung after S4

S4 proved ONE trivial module.  The rung: every `COMPILER/BOOT/stage1_corpus/*.iii` (60 programs,
the same set `build_iiis1.sh --check-corpus` pins iiis-1 with) through seed.exe vs gcc iiis-0 —
rc parity + byte-identical .o, both compilers invoked from BOOT_DIR with the same relative input.

**The first sweep failed 50/50 — and the harness itself was the trigger.**  File 01 passed a
hand-run (rc=0, byte-identical) yet failed the sweep at EMIT_FAIL 16; the only delta was the
sweep's LONGER --out basename.  Bisect: out-path ≤76 chars green, ≥77 red — i.e. the assemble
command crossing **256 chars** (`cmd(L) = 3L + 29`; 255 pass / 258 fail).

**Root cause (ccsv, function-scope resolution missing)**: prescan_arr registers every local array
into the A-table with NO scope key, and every accessor (abase/aesize/alen/avtype/…) resolved
first-match-by-NAME across the whole TU.  emit.c declares `char cmd[256]` (audit, line 333),
`cmd[1024]` (387), `cmd[2048]` (iii_emit_assemble, 568), `cmd[16384]` (link, 625) — so assemble's
`sizeof cmd` read **256** (the FIRST registration), `iii_emit_appendf` saw `n=258 ≥ cap−off=256`,
returned −1 → E_CMD_OVERFLOW → "assemble failed" → 16, with a COMPLETE byte-correct .s on disk and
system() never called.  The shim-call stream (SC:/CL: tracer added to the FPRINTF_DBG microscope)
pinned it: the pass run reaches `SC:system(cmd,238)`; the fail run's last emit-phase shim is the
PHASE_END clock (its printed args are stale locals-frame residue — `176754,256` = cmd's address +
strlen, initially misread as a corrupted dispatch).

**Fix 1 — function-scoped A-table (ccsv.iii)**: `map_bodies()` (one post-lex pass; per-token
TOP-LEVEL brace-body id, file scope = 0) + `ABID` column stamped at all EIGHT A-append sites
(prescan_arr ×3, prescan_structarr ×3, file-scope scalars, reg_var) + `aidx(t)` — a same-body
entry wins, else the first FILE-SCOPE entry, a local of another body never matches (C scope) —
replacing the name loop in all 11 accessors (alen_by_name keeps name-only but prefers ABID==0).

**Fix 2 — the fix's own regression, root-caused to a PRE-EXISTING phantom generator**: probe9b
99→78 under scoping.  ccsv dbg (extended with an A-table dump: name/base/esz/avt/**bid**) showed
main's body full of phantom `SRC`/`POOL` struct-array entries (avt = the ANONYMOUS union's index,
n = the USE-SITE indices 3,4,5,6!).  Mechanism: anonymous aggregates register with a ZERO-LENGTH
name; punctuation tokens carry TL=0; `neq(0-len, 0-len)` compares zero bytes → MATCH — so
`stidx(';')==the-anon` and every `; NAME [ i ]` statement prescan_structarr'd a phantom
struct-array at MTOP.  Benign for years under first-match order (registered AFTER the real
entries); ACTIVE the moment same-body entries win.  Fix: `stidx` zero-length guard BOTH ways
(a TL=0 token never matches; an STNL=0 type is never found by name — anons are anon_lookup's).
Phantom storage gone shrank the linked seed image 1317177 → 1297209 bytes.

**Falsifier `_s4_probe12.c`** (two-path proven: gcc 99 / pre-fix ccsv 61): same-named `cmd[64]`
then `cmd[512]` in different fns — sizeof through both (paren + paren-less), the appendf shape
crossing 256 formatted chars, same-named-local storage isolation across a call, local-shadows-
global with the global's bytes intact.  Post-fix: **99 on ALL FIVE executors** (gcc, interp,
svir_verify=0, sovereign-x86-native via sovas+sovlink, wasm).

**Verification (all measured this session)**: probes 8/9/9b/10/10b/10c/11/12 all 99 via interp;
`run_ccsv.sh` rc=0, FAIL=0 (whole-seed floor holds); `run_fnptr_gate.sh` ALL PASS (5 executors +
OOB teeth); `run_seed_sovereign.sh` rc=0 S1–S4 ALL GREEN with the re-linked seed; ccsv.o and
ccsv(emit.c) output both run-to-run byte-deterministic.  New gate: `run_seed_corpus.sh` — all 60
corpus programs, LONG out names kept deliberately as this defect's permanent teeth.

Open (ledgered, this session): (a) on the pre-fix ERROR path, `fprintf(stderr, "assemble failed")`
never reached the interp's fprintf shim (no FP!/SC trace) — error-path-only, invisible to rc/.o
parity, unresolved; (b) `static char X[32]`-style quals cause a DOUBLE A-registration (one per
decl-prefix token; first-match hides it, one dead storage span per qualified global array); (c) the
dbg mode now dumps the A-table (name/base/esz/n/avt/bid) and struct STNO/STNL — permanent
instruments.

### Session 8, defect 2: bare GLOBAL struct var passed BY VALUE sent its ADDRESS

The post-fix corpus map (pass=6 fail=54) split by signature: ~30× rc=12 (SEMA_FAIL, incl. plain
`24_var_global`), 4× rc=14 (CG), 6× rc=124 (hang), 3× rc=199 (the interp's OOB CALL_INDIRECT trap —
55/56/57_..._form_runtime), 4× byte-diverge.  The 199s prove out-of-range fn-ptr indices at runtime;
CI-tracing 24_var_global showed ONE indirect call `CI:44/5@735` (caller = cg_r3's local_lookup_slot,
target = main.c's iii_d_mul!) then a clean unwind to 12 — initially read as a missed //V rewrite.

Minimal-repro discipline caught two false trails: (1) the first minis initialized via
`G.locals[i].f = v` — the LEDGERED session-6b dot-global-chained-store gap (seed-unused) — so they
failed for a reason unrelated to the seed; re-built with pointer stores (`cg->locals[i].f = v`) the
seed-exact lookup STILL failed 61 with ZERO indirect calls (the rogue CI is a downstream symptom,
not the root).  (2) The atom (probe ladder mini7-9): `r_param(txt_t name){return name.length;}`
called with a BARE GLOBAL struct var — `r_param(NM)` — returned garbage at ANY arg position, while
deref (`*nm`), arrow-field (`l1->name`), and local-copy passes were all correct.

Root cause: eprim's global-ident tail had two arms — `aisc==1` (scalar → LOAD) and the decay arm
(`econst(base)` → ADDRESS, right for bare ARRAYS).  A reg_var'd struct VAR (avtype≥0, ALEN==0)
fell into decay: its ADDRESS went into the by-value arg slot, so the callee's field reads decoded
an address (length = addr>>32).  Every sema/parse lookup keyed on a global `txt_t` passed by value
failed — the whole 12-class.  The LOCAL analog (line ~1315) already did this right (≤8B → LOAD64
packed; >8B → address, the aliased convention).  Fix: the global tail now mirrors it — avtype≥0 &&
ALEN==0 && STSZ∈{1,2,4,8} → `econst(base); eload(STSZ)`; struct ARRAYS (ALEN≥1) still decay; >8B
struct vars keep the aliased pass-by-pointer convention.  Falsifier `_s4_probe13.c` (bitmask over
five pass modes; gcc=32): pre-fix ccsv = 49 (bits 0+4 = bare-global at positions 1 and 2), post-fix
= 32 on gcc + interp.  Probes 8–12 all hold 99.

### Session 8, defect 3 (THE corpus killer): field arrays dimensioned by NAMED CONSTANTS collapsed to ONE element

The by-value fix (defect 2) changed NOTHING on the corpus — identical 54-fail signatures, identical
seed image size: the seed never passes a bare global struct by value (probe13 caught a REAL ccsv
defect but a PROXY of the corpus failure — the ledgered proxy-repro trap, hit live).  The honest
chain that followed, all MEASURED:

- run_seed_link.sh's own comment resolved the fprintf mystery: **undeclared stdio calls in TUs
  without crt_tail are compile-time no-ops** — sema.c/parse.c diagnostics DROP by design; only
  main.c's crt_tail'd fprintf reaches the shim.  So silent 12s carry recorded-but-unprintable errors.
- The at-exit memory dump of sema state (deterministic heap @1119112) read **error_count=4** with
  ER0 = "duplicate declaration of..." and ER1..3 = code 2 "parser produced an error node" —
  sema was reacting HONESTLY to a corrupted PARSE.
- The 4-TU _parseharness (ccsv→svir_ld→interp) parses 24_var_global CLEAN (ok=1 ec=0 nd=2) — same
  code, same input as the 19-TU seed which mangles it: an environment-emergent defect.
- A store-watch on the parse-state block (deterministic @1090792, 536B) caught the writer:
  **iiip_bc_push stored 0x4_0000_002C — the packed iii_src_text_t {offset=44,length=4} = the token
  'main' — at st+416 = pratt_trace**.  parse.c declares
  `iiip_prod_id_t bc_stack[III_PARSE_BREADCRUMB_CAP]` and
  `iii_src_text_t bc_detail[III_PARSE_BREADCRUMB_CAP]`: ccsv's reg_fields resolved [NAMED_CONST]
  dims ONLY in the scalar-dtype arm (the old link.c sym[III_LINK_SYM_CAP] fix); the STRUCT-TYPED
  and ENUM/FWD-TYPEDEF field arms accepted only NUMERIC dims — both breadcrumb arrays registered
  as ONE element, so every bc_push beyond depth 0 overlaid witness_ctx/witness_committed/
  witness_sink/pratt_trace/reg_decl/reg_stmt/reg_primary.  The overlay explains the whole failure
  spectrum: garbage pratt_trace → CALL_INDIRECT 44 (in-range wrong dispatch, the rc=12 sema class
  via clobbered reg tables + error nodes), other spray values → rc=124 hangs and rc=199 OOB traps
  (55/56/57).  Fields BEFORE +264 (errors/error_count/depth) stay safe — why the shallow harness
  verdict passed and why S4's trivial module never tripped it.
- Fix: the cidx([NAMED_CONST]) fallback added to BOTH remaining field arms + `SFSZ` (total field
  bytes) now STORED in those arms (it never was — sizeof(p->field) on struct/enum-element arrays
  returned the ELEMENT size).  Falsifier `_s4_probe14.c` (enum-elem stack[#define CAP] +
  struct-elem detail[enum ECAP], sizeof-ratio + element round-trip + neighbor guards): gcc 99 /
  pre-fix ccsv 60 / post-fix 99.  Probes 8-13 all hold.

### Session 8, defect 4: `typedef struct TAG ALIAS;` reg_var'd the ALIAS as a struct VARIABLE

Round-3 gates: floor rc=0 FAIL=0 and fnptr ALL PASS with the field-array fix — but the seed LINK
went red: G2 statics 89,162,168 >> 917,504 ("svir_ld: data image overflow"), link.c's membase
jumping +88.7MB.  The A-dump showed an entry literally named `iii_link_state_t` (avt=96, file
scope): prescan_struct's `struct TAG NAME` arm has no typedef guard, so link.h's forward typedef
`typedef struct iii_link_state iii_link_state_t;` parsed as `struct TAG varname;` and reg_var'd a
phantom static of STSZ bytes.  It ALWAYS did — the phantom was ~90KB while field arrays collapsed
(defect 3 masked it under the ceiling); correct sizing exposed it (iii_link_state_t truly is
~85MB: modules[1024] × ~87KB dep_names/exports — gcc parks the real instance on the HEAP via
calloc; only the phantom was static).  Fix: both struct/union `TAG NAME` arms skip when t-1 is
`typedef` (the TypedefName arm already had the istk(t-1) guard).  link.c MTOP 88,729,661 → 23,045;
probes 8-14 all hold.  Also this session: SFSZ (total field bytes) was never STORED by the
struct-typed and enum-typedef field arms — sizeof(p->field) on those returned the ELEMENT size —
now stored (the layout offsets were right; only the sizeof read was short).

### Session 8, consequence: the interp's world grows to 128 MiB

With field arrays truly sized, round 4 went 0/60 -- WORSE -- including 01_return_const (rc=14):
`iii_link_state_t` is genuinely ~85MB and main.c calloc's ONE unconditionally even under
--compile-only.  gcc hosts that allocation trivially (heap); the interp's 4 MiB MEM could not --
the bump heap ran past the top and mb/msb's bounds checks silently DROPPED every write beyond 4 MiB
(deterministic corruption, not a crash; ccsv's calloc is bump-fresh-zero so no 85MB write loop
exists).  The seed source is frozen (seed-identity); the interp's memory model is Lambda-0 tooling:
MEM grows 4 MiB -> 128 MiB (decl + mb/msb bounds), argv staging relocates to the new top
(134,213,424/134,213,680), seed-side compile-time layout (statics<917504 / shadow / VA_BUF /
HEAP_BASE=1MiB) untouched.  x86/wasm backend memory models are NOT yet grown -- they never execute
the seed (KATs only); ledgered as the germination-side follow-up when a sovereign-native seed run
lands.

### Session 8, the 12-class bisect state (LIVE frontier — precise flip pair secured)

The mhash/membase leads were RIG ARTIFACTS: ccsv resolves `#include "lex.h"` relative to the MAIN
FILE's directory — probes built in the scratch dir silently DROP the include and every lex/parse
call compiles as an undeclared no-op returning its LAST ARG (the "TOKS k=0 / rc=&tk=917000" class).
ccsv should fail LOUDLY on an unresolved local include (improvement, not yet landed).  All rig
files must live in COMPILER/BOOT.

Honest facts (all re-measured with in-BOOT rigs, 24_var_global, 19-TU links):
- The seed's LEXER is correct (lookahead.kind store-watch = the clean harness's token stream).
- sema records: 1× "duplicate declaration of 'main'" + 3× "parser produced an error node"
  (records dumped from sema state @heap; the messages' byte-2 corruption is cosmetic).
- _parseharness (±mhash, ±argv-parse, 4-TU/19-TU/20-TU-with-main-passenger): ALL CLEAN.
- main.c verbatim with ONLY the iii_run_pipeline call redirected to a reconstructed pipeline
  (bis_pipeline, same 8-arg signature, same statements incl. sema..emit graft): CLEAN end-to-end.
- Variant algebra on iii_run_pipeline (true text, in place): prologue+parse only (P) = GREEN;
  +ring (R) = GREEN; +sema/sid (Q, S, even with the hexad/acc/ceil inits dropped) = RED 12;
  fn moved to file end (T) = RED (position exonerated).
- THE ANTIDOTE: the reconstruction's report block (`ec = iii_parse_error_count(p); nd; mod =
  iii_ast_get(root); 4 put-calls; putchar`) inserted between parse and sema masks the defect
  (U2 GREEN); removing it (U3) or leaving only the ec line (U4) = RED.  One ~7-line insertion
  in ONE function flips the sema verdict — a compile-state boundary inside ccsv's cfn for this
  fn (NOT temp-slot saturation: pstmt resets LN=NLOC per statement).

NEXT (fresh context): diff the compiled fn bodies of the U2(green) vs U4(red) single-TU modules
(m_gen__mainprobe.iii in the scratch kit) — the first structural divergence inside
iii_run_pipeline's body names the miscompiled construct directly.  Recipes for every variant are
in the session transcript; the scratch kit (ccsv_fix.exe, m_B.rsp chain, svir_interp_dbg5) rebuilds
from the committed tree.
