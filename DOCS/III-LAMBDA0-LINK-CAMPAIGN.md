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
| 19-TU frontier measurement | **DONE** (below) — 2,569 fns, 21 fails in 5 TUs |
| svir_ld.iii (the linker) | **NOT STARTED** — design frozen (below) |
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
| cg_rm1.c | ~~4~~ **1** | emit_vmexit_dispatch_table | (a)+(b) fixed 3; the last: `x = <nothing>` post-if — undiagnosed, dis tail `60 44 11:3@-1` |
| jit_emit.c | 7 | iii_jit_self_test (**rc=2 unknown-opcode!**), swap_crystal, linear_owned_check, trampoline_{code_ptr,code_size,version,reset} | `G_STRUCTARR[i].field` rvalue (global struct-array element FIELD read) emits nothing; self_test emits an unknown byte (separate; inspect) |
| link.c | ~~4~~ **3** | iii_link_cmp_entry, iii_link_sort_entries, iii_link_build_manifest | sha256_final **FIXED** by the COMMA-STATEMENT class (`h->buf[56+i]=v, bits>>=8;` → stmt_end() recurses into pstmt for each clause; probe p_link f2, interp==gcc==79). cmp_entry trio: NOT the cast-decl shape (probe f1 passes) — re-diagnose (memcmp/strcmp chains? `(a->f, b->f, 32)` arg shapes?) |

Standing: **2,569 fns / 11 fails = 99.6% structural.** Landed this session: 46e6b7e2 (v2/CALL2),
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
