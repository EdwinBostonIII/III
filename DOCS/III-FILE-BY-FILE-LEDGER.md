# III — Manual File-by-File Audit Ledger

Auditor: main session, reading each file directly (no subagents). One row per file:
verdict ∈ {REAL, REAL-gcc (works but depends on gcc/ld in a claimed-sovereign path),
ISLAND (no consumer/gate), STUB, OVERCLAIM, TAUTOLOGICAL (test cannot fail),
ARTIFACT (build output), DATA, JUNK}. Independence is judged from the SOURCE, not from
the file's own tests.

Started: 2026-07-06

## COMPILER/BOOT — the C seed (iiis-0) + tools. Read directly.

| file | verdict | what it is / independence note (from source) |
|---|---|---|
| cg_r0.c (1323) | REAL | Ring-0 (kernel .sys) codegen; hand-emitted gas mnemonics, inline NIH SHA-256 (K-consts verified FIPS-180-4), no CRT in emitted image. Seed TU (ported to cg_r0.iii). |
| iii_cg_pe_iiis1.c (180) | REAL | Partial-evaluator: classifies resolve(intent) callsites to a dispatch fn via iii_compositions table; bounded recursion depth 8. Real analysis, single-source-of-truth .def. |
| iiis1_link_stubs.c (89) | REAL (+confirms XII dead-branch) | No-op stubs for XII symbols when XII off (iiis-1). Source states r3_pe_canonicalise/r3_compute_circ/r3_pe_lattice_emit "are never called… exist only as link-time symbols." Independently corroborates the XII finding. |
| rm2_driver.c (21) | REAL (test driver) | Ring-2 sanctum reseal gate runner; asserts do_thing(7)==21 etc. via computed values → exit 21. NON-tautological (distinct fail codes 1..4). |
| _lexharness.c (34) | REAL, probe — excluded from links (P0 FIXED 2026-07-06) | Behavioral probe: #include "lex.c", own main(). Was swept into every link (observed: 100 ld multiple-definition errors); now excluded via `! -name '_*.c'` at all six build-filter sites; bootstrap_from_clean.sh 6/6 green. |
| _astharness.c (41) | REAL, probe — excluded from links (P0 FIXED 2026-07-06) | Same class as _lexharness.c. |
| emit.c (936) | REAL-gcc | The gcc/ld driver: system("gcc -c -x assembler"), system(gcc/ld). Honest header says so. This is the DEFAULT-path external dep. Seed TU (→emit.iii). |

## TREE-WIDE MANUAL SCANS (main session, every .iii source in scope)

### Stub / pretend-success scan — RESULT: zero shipped fakes
108 keyword hits across all .iii; read each. Every one is (a) a false positive ("not a
`return 1` stub … FALSIFIABLE", "no longer a stub", "DOS stub" for PE emit, intentional
`@dynamic` ripple-stub codegen), (b) an HONEST fail-closed gap (jit_emit.iii AVX-512:
`jit_poison` + return `III_JIT_E_NOT_IMPLEMENTED` — never fakes success), or (c) a scaffold
explicitly BLOCKED from emission (xii_emit_gen.iii refuses curated crypto inlines at a
chokepoint so the fail-open ed25519 scaffold can never ship). base64/dynamic_impact
"placeholder"/"unimplemented" notes are past-tense remediations; decoders + aggregate_ux
now real. **No fake-success stub reaches a shipped path.**

### External-process scan — RESULT: only emit.iii shells out
`system|popen|exec|CreateProcess` across all .iii matches ONLY the word "system" in
comments/UI strings. The single place III invokes an external process is `emit.iii`'s
gcc/ld driver (the documented default-emit dependency). No stdlib module secretly calls
gcc/python/a shell. Independent capability confirmed at the call-graph level.

### C-accessor dependency — RESULT: PHANTOM (stdlib is more C-free than it claims)
766+ `extern … from "*.c"` tags (ast_accessors.c ×407, sema_accessors.c ×222,
lex_runtime.c ×84, emit_accessors.c ×24, …). **None of those .c files exist on disk**
(verified absent) and build_iiis2's ALL_C matches none of them. The symbols are
`@export`-defined in `.iii` (iii_lex_malloc_c→lex_rt.iii, iii_ast_node_kind &
iii_emit_buf_read_u8_c→ast.iii); the III linker resolves by name. So the active
compiler+stdlib require NO C accessor layer — the tags are vestigial. **Finding
(hygiene, tree-wide): 766+ stale `from "*.c"` provenance tags misrepresent non-existent
C dependencies.** Positive for independence, negative for source honesty.

### Real runtime OS surface — RESULT: standard Windows only
Non-msvcrt externs: kernel32 (135), user32 (34), gdi32 (6). Standard OS import surface
for a native Windows program — not a third-party/library dependency. msvcrt (CRT) is the
libc boundary. No other DLLs.

## STDLIB/iii — per-module classification (all 811, evidence-based)
Method: exported-fn count + corpus-KAT importers + stdlib importers, then read every outlier.
- **779 REAL** — exported AND (KAT-gated or stdlib-imported). NOTE: "REAL" = reachable/wired,
  NOT proven-correct (a module can be KAT-green yet degenerate — see below). Correctness is
  judged by the executed corpus + the tautology hunt, not by this reachability metric.
- **14 apps** — 0 @export because they are `fn main` PROGRAMS: mech, iii_studio, stoma, sovhash,
  ui_topo, aether_world, field_run, mandel_run, fractal_dim, the ui_*_app launchers. All have
  entry points; all are gcc-LINKED (sovereign-compilable, not sovereign-linked — see main doc).
- **18 THIN** (0 KAT, 1 importer) — mostly transform codecs + 3 xii_curated_*. Read directly.
- **0 orphan islands.**

### FINDING — degenerate transform codecs (omnia/tp_*)
Of 26 tp_* codecs, several are self-admitted **baselines that do NOT perform the semantic
transform their FORM_X→FORM_Y name claims**, satisfying the round-trip contract trivially:
- tp_iii_to_c99: emits `static const char* iii_source="<escaped bytes>";` — a byte-wrap, NOT a
  III→C transpiler (header: "The full III-to-C99 transpiler is per-construct authoring work").
- tp_x86_disasm: emits `.byte 0xNN` directives — a byte-dump, NOT an instruction decoder.
- tp_ast_dot: emits "node:source" with the source as a single label — NOT a real AST graph.
- tp_iii_to_ast_bin: baseline that only round-trips through its inverse.
Honestly commented, but the registry/name overstates the delivered capability. The hex/serialize
codecs (raw_hex, iii_hex, pe_hex, babel_json↔cbor) are genuine.

## TAUTOLOGY HUNT (corpus KATs) — RESULT: not tautological; crypto FIPS-anchored
The corpus test architecture: run_corpus.sh holds an EXPECTED[] exit-code table (a missing
entry is a HARD error — no silent `expected=?`); each KAT computes a value and returns it as
its exit code, checked against the pinned expected. 251/1820 files have no internal `if`, but
that is NOT tautology — the assertion is EXTERNAL:
- 02_sha256_kat_abc: computes sha256("abc"), returns byte0 (=0xBA=186) as exit; harness pins
  186. Break SHA → returned byte changes → FAIL. Real KAT, non-vacuous.
- 1047_quine_seal: `return ks_selftest()` — delegates to the module's 5-step selftest (returns
  99 iff all computed checks hold; the header describes a flip-one-byte prove-the-negative).
Honest nuance (the user's point, correctly scoped): the EXPECTED values are same-repo. For
CRYPTO they are externally anchored (FIPS/RFC vectors — ba7816bf, ddaf35a1, 2b7e1516 verified
present); for non-crypto capability KATs (e.g. "field dimension = 99") the expected constant is
author-chosen, so those prove DETERMINISM + internal consistency, not external ground truth.
The corpus disproves "the tests are fake"; it does not, alone, prove every capability against an
independent oracle. Independent-oracle evidence exists only where cross-lineage differentials run
(SHA vs coreutils/openssl; PE vs binutils) — §2.2c of III-INDEPENDENCE-AUDIT.md.

## Executed corpus run: COMPLETED (exit 0). run_corpus.sh => PASS=1574 FAIL=12 SKIP=233
## TOTAL=1586 (SKIP = XII 280..372 owned by run_xii_corpus.sh + perf benchmarks + family-owned
## UI/stoma/sqrtsum KATs run by their own scripts). 99.2% pass; 12 REAL failures -- a concrete
## small defect count, NOT a green-washed "all pass". One named: 2450_au_crush_conform exit=11
## (parse/compile fail) expected=99; the other 11 scrolled past the captured tail (a background
## re-run names all 12). Strongest single whole-system "does it work" datapoint, alongside
## seed-identity 60/60 + iiis-2==iiis-3 + the sovereign fixpoint.

## The 12 corpus failures (named, from failure-capture re-run) — a concrete fix-list
Eleven of twelve cluster in ONE subsystem (eidos web/cli/display arm); one is unrelated.
| KAT | exit | stage (exit code meaning) |
|---|---|---|
| 1985_eidos_display | 10 | LEX_FAIL |
| 1986_eidos_layout | 11 | PARSE_FAIL |
| 1987_eidos_web | 19 | (late stage) |
| 1988_eidos_web_plan | 16 | EMIT_FAIL |
| 1989_eidos_web_weave | 15 | LINK_FAIL |
| 1990_eidos_web_route | 16 | EMIT_FAIL |
| 1991_eidos_web_intensity | 16 | EMIT_FAIL |
| 1992_eidos_web_temporal | 15 | LINK_FAIL |
| 1993_eidos_cli_run | 10 | LEX_FAIL |
| 2000_eidos_field | 10 | LEX_FAIL |
| 2001_eidos_cli | 11 | PARSE_FAIL |
| 2450_au_crush_conform | 11 | PARSE_FAIL (unrelated to eidos) |

### FINDING (refines earlier "eidos is real") — eidos web/cli/display arm is RED
eidos (lazy exact-real / UI substrate, 25 modules, 87 corpus-KAT importers) is genuinely
wired, but its web/cli/display CLUSTER fails to reach exit 99: 11 KATs red at lex/parse/emit/
link stages (10/11/15/16/19). The eidos *field/ripple/egraph* core passes; the *web/cli/
display/layout* presentation arm is broken. Concrete, localized regression — not vaporware,
not green. (Was NOT visible to my reachability metric, which said "eidos REAL"; only the
EXECUTED corpus surfaced it — vindicating the run over the static classification.)

## VERIFIED FIXES landing DURING this audit (git log + source re-read, then gate re-run)
The findings this audit raised were acted on in real commits; I verified each in the source:
- **P0 (clean rebuild) — FIXED + PINNED.** `bootstrap_from_clean.sh` added (6-stage,
  anti-launder); `! -name '_*.c'` now excludes the harness TUs at all build-filter sites;
  `build_iiis0.sh:196` adds `-Wno-attributes` for the gcc-15 popen/_popen issue. Commit
  bb4a71a8 "P0: bootstrap_from_clean GATE GREEN 6/6". (Re-running it myself to re-confirm.)
- **P2 sovas VEX — FIXED.** Commit 96f27f98: full measured VEX 2B/3B set (vpxor/vpaddd/vpor/
  vpshufd/vpslld/vpsrld/vpaddq-y/vmovdqu/vzeroupper) byte-identical to gas; teeth proven
  (perturb→exit 11); sovtc + fixpoint ALL PASS. Shrinks the gcc-as witness surface.
- **P2 sovld multi-DLL — FIXED.** Commits e397409c + 5b4e2a01: DLL routing is now a 5-DLL id
  table (kernel32/msvcrt/user32/gdi32/ws2_32), N-DLL .idata builder; a ws2_32 app links + runs
  SOVEREIGN (exit 99); objdump confirms both DLLs in the import table. So GUI/net apps can now
  link without gcc/ld — the sovld 2-DLL limit I found is closed.

## P0 RE-VERIFIED BY THE AUDITOR'S OWN EXECUTION (2026-07-06, not a commit message)
Ran `bootstrap_from_clean.sh` myself from the current tree. Result: **GATE GREEN, 6/6**:
  STAGE 1 seed          PASS  9s
  STAGE 2 stdlib scratch PASS 162s  (714 modules, FAIL=0 guard satisfied)
  STAGE 3 iiis-1        PASS  4s
  STAGE 4 iiis-2+corpus PASS 59s
  STAGE 5 seed<->self-host identity PASS 43s
  STAGE 6 iiis-3 fixpoint+corpus    PASS 33s
Independent confirmation: the freshly-rebuilt COMPILED/iiis-2.exe sha256 =
853b2fbb58b59618803a19b8c6b69fa93013caeb55600bd7a5ca3e4a7aaecf3b = the committed golden,
EXACTLY; and iiis-2 == iiis-3 byte-identical after the clean rebuild. **"The tree rebuilds
from clean" is now EXECUTED-verified, not asserted.** Honest scope: on a host WITH gcc/binutils
(P0); removing them from the trusted path is P1/P2 (sovas/sovld default + witness closure), on
which real progress landed this session (VEX set + 5-DLL sovld).
