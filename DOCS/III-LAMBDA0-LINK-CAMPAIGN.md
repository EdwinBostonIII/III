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
