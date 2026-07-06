# III — Full-System Independence & Production-Readiness Audit

**Date:** 2026-07-06
**Scope:** every tracked file in the III tree (4,488 files) — what the system *sets out
to do* vs. what it can do *independently*, in a production-ready way, free of Claude and
free of the external toolchain it claims not to need.
**Method (manual, main-session):** the auditor (a) ran the real bootstrap / self-host /
sovereign / trust gates for executed evidence; (b) read the load-bearing source directly —
the C seed TUs, the compiler spine (`emit.iii`, `link.iii`, `main.iii`), and the full
sovereign toolchain (`sovas.iii`, `sovld.iii`, `sovcoff.iii`) line by line; (c) ran
tree-wide scans over ALL `.iii` for stubs, external-process calls, and C dependencies,
and read every hit; (d) classified all 811 stdlib modules by exported-symbol +
KAT-importer + stdlib-importer evidence and read every outlier; (e) hunted the corpus for
tautological (cannot-fail) tests; (f) cross-checked capability against INDEPENDENT
lineages (coreutils/OpenSSL/binutils), never III's own tests. The companion
`DOCS/III-FILE-BY-FILE-LEDGER.md` holds the per-file/per-scan ledger. Nothing here is
asserted from a doc or a memory note; every headline is backed by a command that ran or a
file:line that was read. **On evidence: a green self-gate proves only that the gate ran —
capability claims below rest on the source itself plus independent-lineage differentials,
with self-gates used only as corroboration.**

---

## 0. VERDICT (read this first)

III is **not garbage, and not yet independent.** It is a **genuinely real, verified,
self-hosting compiler** whose *codegen is sovereign* but whose *last-mile assemble+link
defaults to gcc/ld*, plus a **real, byte-identical, self-hosting sovereign assembler +
linker** that is currently **opt-in, gcc-bootstrapped, and SIMD-incomplete** rather than
the default. The distance from here to "reproduces itself with zero external toolchain"
is **small, enumerable, and closable** — it is not a rewrite.

| Question | Answer | Evidence (executed) |
|---|---|---|
| Does the self-hosted compiler exist and run? | **Yes** | `iiis-2.exe --help` → exit 0 |
| Is the self-host a true fixed point? | **Yes** | `iiis-2.exe` ≡ `iiis-3.exe` **byte-identical** (sha256 `853b2f…cf3b`) |
| Did the self-host introduce codegen drift vs the C seed? | **No** | `seed_text_identity_gate.sh` → **60/60** byte-identical .text+data+relocs; selftest confirms the gate can go red |
| Is there a real gcc-free assembler + linker? | **Yes** | `sovas.iii` (39 KB) + `sovld.iii`/`sovcoff.iii`; `run_fixpoint.sh` → **ALL PASS** (13/13 self-host, byte-identical to gas/ld) |
| Can a program be built end-to-end with **no gcc in the link path**? | **Yes (opt-in)** | `sovbuild.sh prog_sat.iii` → PE32+ 20,992 B, route manifest **sovereign=2 witness=0**, runs **exit 99** |
| Does the **default** compiler pipeline avoid gcc? | **No** | `emit.iii:872` `iii_emit_assemble` → `system("gcc -c -x assembler …")`; `emit.iii:55` `extern system from "msvcrt"`; iiis-2 `--link` observed invoking `ld.exe`/`collect2.exe` |
| Does the tree rebuild from clean on a stock toolchain? | **Yes (gated, 2026-07-06)** | `bootstrap_from_clean.sh` **6/6 GREEN on a pristine clone** (544s): seed 20s → stdlib 714 modules + 3 ratchets 284s → iiis-1 **GOLDEN** 9s → iiis-2 **GOLDEN**+corpus 101s → seed↔self-host `.text` identity 69s → fixpoint 61s.  FOUR latent reds found + fixed en route (§2.3) |
| Is any runtime path Claude/AI-in-the-loop? | **No (in the trusted path)** | no compiler/stdlib module calls an AI at runtime; `omnia/ai_resolve` is a deterministic pattern resolver (pending Ring-1 confirmation) |

**One-sentence headline:** *III's front-end and code generator are sovereign and
provably self-hosting; its assemble-and-link last mile still rides on gcc/ld by default,
and a real but opt-in sovereign toolchain closes that gap for applications but not yet for
the compiler itself — three concrete work-items stand between today and full toolchain
independence.*

---

## 1. WHAT III SETS OUT TO BE

From the DOCS corpus, the completion plan, and the code:

- **A sovereign, self-hosting systems language + compiler** (`.iii`), bootstrapped from a
  frozen ~35 KLOC C seed (`iiis-0`) into a self-compiling toolchain (`iiis-2`/`iiis-3`),
  with **diverse double compilation (DDC)** to bound the Thompson trusting-trust attack.
- **A large, KAT-gated standard library** (811 `.iii` source modules): full classical
  crypto, post-quantum (ML-DSA/ML-KEM/SLH-DSA), zero-knowledge proof systems, an entire
  compiler-optimization/verification organ set (SSA/GVN/DCE/SCCP/isel/regalloc/abstract
  interpretation/SAT/e-graph), data structures, text/format, networking, a BFT federation
  layer, a Ring-0 kernel-descent substrate (KATABASIS), and exact-geometry/physics organs.
- **A sovereign toolchain** (`sovtc`: `sovas` assembler, `sovld` linker, `sovcoff`) so the
  final `.o`→PE step needs no GNU binutils.
- **Applications** proving the stack: `mech` (exact mechanism workbench), `iii_studio`
  (exact-math IDE), `stoma` (sovereign CLI).

The ambition is coherent and largely **implemented**, not vaporware. The audit's job is to
separate *implemented + verified + wired* from *implemented-but-island* from
*documented-but-not-delivered*.

---

## 2. INDEPENDENCE — THE TOOLCHAIN SPINE (Ring 0, executed)

This is the crux of "capable independently, void of Claude." The pipeline has four stages;
their sovereignty differs and must not be blurred:

```
  .iii  ──[lex/parse/sema/cg — 99 sovereign .iii modules]──▶  .o.s (x86-64 asm text)   ✅ SOVEREIGN
  .o.s  ──[assemble]────────────────────────────────────────▶  .o  (COFF object)
             ├─ DEFAULT:  system("gcc -c -x assembler")                                 ❌ gcc-as
             └─ OPT-IN :  sovas.iii (Tier-1)                                             ✅ sovereign
                          └─ Tier-2 SIMD/SHA-NI/AES-NI/AVX-512 → gcc-as "witness"        ⚠️ gcc fallback
  .o    ──[link]─────────────────────────────────────────────▶  .exe (PE32+)
             ├─ DEFAULT:  system("gcc"/"ld")                                             ❌ gcc/ld
             └─ OPT-IN :  sovld.iii / sovlink_main                                       ✅ sovereign
```

### 2.1 What is genuinely sovereign (verified)
- **The compiler front-end + codegen.** 99 `.iii` modules (lex, parse, sema, cg_r3, cg_r0,
  cg_rm1, cg_rm2, emit, link, main, …). The C surface still linked into `iiis-2` is
  **effectively zero** real TUs — the only non-ported `.c` files are `_lexharness.c` /
  `_astharness.c`, which are standalone behavioral probes (75 lines total), not compiler
  logic. The compiler *is* `.iii`.
- **The sovereign assembler + linker.** `run_fixpoint.sh` proves `sovas` and `sovld` build
  byte-identical copies of *themselves* (gen2==gen1 on 13/13 inputs), `sovas`'s `.text`
  matches gas byte-for-byte on all 7 toolchain modules, and `sovld` re-links `sovas`
  identically to the gcc-linked reference and reproduces itself bit-for-bit. **ALL PASS.**
- **End-to-end application sovereignty (opt-in).** `sovbuild.sh prog_sat.iii` compiled →
  assembled (sovas) → linked (sovld) with **gcc nowhere in the link path**, produced a
  20,992-byte PE32+, and it ran to the sentinel exit 99.

### 2.2 What still depends on gcc/ld (the gap)
1. **Default assemble + link.** `emit.iii` (the emitter iiis-2 actually runs) is a faithful
   port of the C seed's "gcc/ld driver": `iii_emit_assemble` → `system("gcc -c -x
   assembler …")` (`emit.iii:872,906`), `iii_emit_link` → `system(gcc/ld)`
   (`emit.iii:1046,1075`). **Every production build** — `build_stdlib.sh`, `run_corpus.sh`,
   `build_iiis1/2/3`, `build_mech.sh`, `build_studio.sh`, and `iiis-2 --link` — uses gcc
   for the last two stages. The sovereign route is exercised *only* by `sovbuild.sh` /
   `run_fixpoint.sh`.
2. **Sovereign-tool bootstrap.** The sovereign tools are themselves *gcc-linked into
   existence* the first time: `gcc … -o sovas_main.exe`, `gcc … -o sovlink_main.exe`
   (`sovbuild.sh:41-42`, `run_fixpoint.sh:26-27`). The fixpoint proves they can *then*
   reproduce themselves gcc-free, but the initial existence is gcc's.
3. **Tier-2 SIMD.** `sovas` cannot yet encode SHA-NI/AES-NI/AVX-512 mnemonics; modules that
   emit them fall back to a **gcc-as "witness"** (`sovbuild.sh:56`), plus hand-written
   `cpuid_helper.s` assembled by gcc.
4. **The Thompson seed anchor.** The C seed is gcc-compiled (expected for a seed). DDC
   mitigations exist and are **honestly scoped**: `run_ddc.sh` closes *front-end* diversity
   (two independent `.iii`→SVIR emitters converge byte-identically); `seed_ddc_msvc.sh`
   adds gcc-vs-MSVC *lineage* diversity; `seed_text_identity_gate.sh` explicitly states it
   is a proxy and that the true independent-lineage seed-DDC "remains separately OPEN,
   needing an independent-lineage C compiler this host lacks." No overclaim at the gate
   level — the residual is documented, not hidden.

### 2.2b Main-session line-level spine read (primary evidence, not gate output)
The auditor personally read, line by line: `emit.iii` (1,104), `link.iii` (module-closure
layer), `sovas.iii` (629), `sovld.iii` (304), `sovcoff.iii` (203). Findings:

- **`emit.iii` delivers exactly what it declares** — a determinism-hardened gcc/ld driver:
  overflow-checked command construction, forced reproducibility env, witness JSON that
  *records gcc/ld version hashes* (the dependence is declared, not hidden), a golden-mhash
  gate after link, and an inline NIH FIPS-180-4 SHA-256 (constants verified). No
  pretend-success paths; every failure is a distinct error code.
- **`link.iii` is NOT a binary linker** — it is the module-closure/manifest layer (Tarjan
  SCC cycle detection, closure mhashes, export-visibility lattice, sealed manifest).
  Binary linking inside the compiler is only `emit.iii`→gcc/ld; III's only native
  object-level linker is `sovld`.
- **`sovas.iii` is a real x86-64 encoder** — REX/ModRM/SIB with the rbp/r13-disp8 and
  rsp/r12-SIB edge cases, gas-exact imm8 short forms, shift-by-1 `D1`, two-operand
  `imul`, full 8/16/32/64 move families, RIP-relative REL32 in the gas addend convention,
  **plus legacy-encoded SSE + SHA-NI already implemented**. The remaining Tier-2 gap is
  **VEX/EVEX (AVX2/AVX-512) only** — smaller than the route-manifest wording suggests.
  Its comment history is differential-gate-driven (every recorded bug was caught by
  byte-compare vs gas) — the strongest non-self-graded test methodology in the tree.
- **`sovld.iii` is a genuine from-scratch PE32+ image writer** (headers, .idata with
  ILT/IAT/hint-name, FF 25 thunks, REL32 patching, virtual-only .bss). Real limits: **DLL
  routing knows only kernel32/msvcrt** (exact-name table + case heuristic) — so GUI/network
  programs (user32/gdi32/ws2_32: mech, studio) cannot link sovereignly yet; no ASLR/NX
  DllCharacteristics; fixed image base. This makes P1's real work precise: plumb the DLL
  name from source `extern … from "dll"` through sovas/sovcoff into sovld and drop the
  heuristic.
- **`sovcoff.iii` is a complete COFF object writer** (REL32 records, contract-ordered
  symbol table, string table).
- Hygiene: `extern … from "emit_accessors.c"` tags in emit/cg_r3/emit_sanctum are **stale**
  — those accessors live in `ast.iii:4335+` (`@export`); the C file no longer exists.
  `sovas.iii`'s header claims a wrong path (`omnia/`). Cosmetic, but misleading.

### 2.2c Independent-lineage differentials (main-session, non-self-graded)
- **SHA-256 triple-lineage agreement**: III's own `.iii` implementation (`sovhash.exe`,
  built from `aether/sovhash.iii` via numera/cad) vs GNU coreutils vs OpenSSL 3.5.6 —
  byte-identical digests on "abc", the empty input (padding edge), and a 798 KB multi-block
  binary. III's crypto correctness here is evidenced by agreement of unrelated
  implementations, not by its own tests.
- **Sovereign PE independent inspection**: binutils `objdump -p` parses `prog_sat.sov.exe`
  as a well-formed PE32+ (entry, subsystem CUI, kernel32 import), `file(1)` concurs, and
  the Windows loader executed it (exit 99) — three judges that share no code with sovld.

### 2.3 Clean-rebuild breakages — CLOSED 2026-07-06 (four reds, four fixes, gate green)
From-clean reproduction was red **four** ways when first exercised (this audit knew two;
`bootstrap_from_clean.sh` itself caught the other two).  Each fix has an individually
observed red→green; the six-stage gate then went green end-to-end on a pristine clone.
- `emit.c` vs gcc 15.2 `-Werror=attributes` (observed: rc=3, `emit.c:43:8 '_popen'
  redeclared without dllimport`).  Root cause: fix #32 (2026-07-05, one day AFTER the last
  iiis-0 rebuild) added bare `popen`/`pclose` prototypes for ccsv host-import registration;
  MinGW's `<stdio.h>` maps `popen`→`_popen` carrying `dllimport`, so the bare redeclaration
  "drops" the attribute.  FIX: `-Wno-attributes` in `build_iiis0.sh` + `build_iiis1.sh`
  cflags (the two scripts that gcc-compile `emit.c`).  The seed source is deliberately
  untouched — the prototypes are load-bearing for ccsv, and `dllimport` is a call-site
  optimisation hint only (every sealed build predating gcc-15 shipped attribute-less).
- `_lexharness.c`/`_astharness.c` (behavioral probes: own `main()`, `#include` a production
  TU wholesale) swept into every link (observed: rc=4 with **100** ld `multiple definition`
  errors at iiis-0's own link).  FIX: `! -name '_*.c'` — the probe convention, present and
  future — at all SIX filter sites: `build_iiis0.sh` compile list AND its witness
  `SRC_LIST_JSON` (which was also missing the `verify_*`/`rm2_driver` exclusions and thus
  mis-attested the compiled source list), `build_iiis1/2/3.sh`, `build_iiis0_msvc.sh`.
- **(found by the gate)** A PRISTINE CLONE reds the stdlib drift gates before any tool runs:
  Git-for-Windows' SYSTEM-level `core.autocrlf=true` smudges LF blobs to CRLF at checkout
  (this repo's LOCAL `core.autocrlf=false` does not travel with clones), and
  `gen_svm_layout.sh --check` et al. byte-compare.  FIX: `.gitattributes` with `* -text` —
  byte-faithful checkouts at every config scope on every host.
- **(found by the gate)** The coverage/reachability ratchets inside `build_stdlib.sh` were
  blind to `STDLIB/sovir/kats` (the crusher campaign's executed KAT corpus): a fresh scan
  reported **32 phantom-uncovered `au_*` exports** (the live tree's 0-count report was
  STALE — last written before the au_ surface landed on 07-04).  FIX: `corpus_coverage.iii`
  now walks a `;`-separated multi-root corpus (exports still derive ONLY from the modules
  root, so scope widening can mark surface covered but never add surface — the safe
  direction for a down-only ratchet); `cov_gate_driver.iii` passes
  `STDLIB/corpus;STDLIB/sovir/kats`; KAT 1391 exit=99 (single-root behavior unchanged).
  The 8 residual names (`au_fz_*`×4, `au_probe_*`×3, `au_report_why` — consumed until now
  only by ephemeral script-generated probes under `build/`) got a durable two-path consumer:
  `_au_observability_kat.iii` (exit 99: MAP-vs-COPY fuzz counts, census-linked locate
  including the honest not-found path, DEFER-why=7 vs CRUSHED-why=0), wired into
  `run_legA.sh` — leg-A **33/33 PASS**.  Census after: uncovered 0≤0, reach 1≤1, gate 1≤2.

The rot mechanism, root-caused: seed/source changes landed 07-04→07-06 with their campaign
gates green but **no from-clean rebuild ever ran after them** — the tree drifted red within
a day of the last build.  `bootstrap_from_clean.sh` (§5 P0, now landed) is the ratchet that
keeps "the seed rebuilds from clean" continuously true — the literal definition of the
independence the owner is asking for.

---

## 3. WHAT IS PROVEN-REAL (executed gate ledger)

| Gate | Result | What it establishes |
|---|---|---|
| `iiis-2.exe --help` | exit 0 | self-hosted compiler runs |
| `cmp iiis-2.exe iiis-3.exe` | identical | self-host **fixed point** |
| `seed_text_identity_gate.sh` | 60/60, GATE PASS | seed ≡ self-host codegen; **has teeth** (selftest → TEXTDIFF) |
| `run_fixpoint.sh` | ALL PASS | sovereign assembler+linker **self-host, byte-identical to gas/ld** |
| `sovbuild.sh prog_sat.iii` | PE32+, exit 99, 0 gcc-witness | end-to-end **gcc-free** application build works |
| `build_iiis0.sh --check-deterministic` | **FAIL (emit.c)** | clean seed rebuild **broken** on gcc 15.2 |
| corpus `run_corpus.sh` | **PASS=1574 FAIL=12 SKIP=233 / 1586** (99.2%) | the real conformance surface — 12 real failures, not a green-wash (e.g. `2450_au_crush_conform` exit=11 parse-fail) |

### 3.1 First-hand capability cross-checks (auditor, read-only)
- **Classical crypto is vector-gated, not self-graded.** The published known-answer
  constants are present in the corpus: SHA-256("abc")=`ba7816bf…`, SHA-512=`ddaf35a1…`,
  Ed25519 RFC8032 pub `d75a9801…`, AES-128 FIPS-197 key `2b7e1516…`, ChaCha20 RFC8439,
  SHA-3/Keccak FIPS-202, ECDSA P-256 NIST. Breadth is real: 8 sha256, 8 sha512, 12
  ed25519, 11 aes, 10 rsa, 7 ecdsa corpus programs, etc. → **classical crypto is
  production-grade and verified against real vectors.**
- **Post-quantum is a yellow flag.** ML-KEM/ML-DSA/SLH-DSA have corpus programs (mlkem 3,
  mldsa 4, slhdsa 5) but a search for NIST FIPS-203/204 KAT vector constants returned
  **zero** — suggesting structural/round-trip tests rather than official-vector gating.
  *(Pending the crypto-postquantum cluster for confirmation; if true, "PQ crypto works" is
  weaker than "PQ crypto matches the NIST ACVP vectors.")*
- **The "island-suspect" subspheres are KAT-gated, not dead.** forcefield (physics) is
  imported by **110** corpus KATs, eidos by 87, nous by 51, katabasis by 37. The memory's
  "physics = DEMOS" note applied to the integration *showcases*, not the underlying
  exact-math organs, which are genuinely exercised. The finer distinction — *KAT-gated
  library* vs *wired into a shipping product* (the exact trap XII fell into, §4) — is
  resolved per-cluster in §4. **Bottom line: these are real, tested capabilities; the open
  question is product-integration, not existence.**

---

## 4. CAPABILITY CLUSTERS (Ring 1 — read-only fan-out, adversarially verified)

> Each cluster was read module-by-module against III's own rubric; every reported gap was
> then adversarially refuted-by-default against live source. Only **CONFIRMED** findings are
> listed. *(This section is populated as the 36-cluster fan-out completes; the first
> completed cluster is recorded below. Rate-limited clusters are being re-run.)*

### 4.x XII subsystem — **library REAL, codegen integration is a DEAD BRANCH** (confirmed)
- **Sets out to be:** the sealed algebraic canonicalisation-and-emission layer wired into
  cg_r3 — "the fixed point … after XII there is no further compiler layer" (`III-XII.md:33`).
- **Actually is:** a substantial, KAT-exercised *library* (real ISA emit tables, term arena,
  SHA-256 content-addressed cell store, rewrite engine) that is **never invoked during any
  real compilation.** The sole wire into codegen — the `@lattice` gate at `cg_r3.iii:3574` —
  fires only for functions annotated `@lattice`, and **no `.iii` source in the tree carries
  `@lattice`** (`cg_r3.iii:1772` self-states "no source file uses @lattice and this returns
  0"). So `r3_pe_canonicalise` / `r3_pe_lattice_emit` are link-referenced but dead; the
  startup-loaded Lattice (`main.c:1122`) is never consulted at codegen time.
- **Confirmed findings:** dead codegen branch (`cg_r3.iii:3574`), inert loaded lattice
  (`xii_lattice.iii:196`, no live lookup caller), and **doc overclaims** in `III-XII.md`
  (:33 "fixed point"; :1789 "C-XII-28: cg_r3 … wired and pass all corpus" — vacuously true,
  zero corpus tests carry `@lattice`).
- **Independence:** no external/AI dep at runtime; corpus harness links with gcc (accepted
  discipline, `III-XII.md:60` says so — not a sovereignty overclaim).
- **Production-ready:** **no** (as an operative compiler layer); the library is KAT-green.

*(Remaining clusters: compiler-frontend/codegen/c-surface, sovereign-toolchain, crypto
{hashes, mac/kdf/aead, asymmetric, post-quantum}, zero-knowledge, numera {bignum, analysis
passes, solvers/egraph/sat, verification organs, ECC/compression, algorithms, remainder},
aether {networking, federation, remainder}, omnia {structures, resolver/intent, transform
codecs, remainder}, verba, sanctus, nous, forcefield, eidos, katabasis, tempora/memoria,
sovir/DDC/zkVM, apps, docs A/B — inserted on completion.)*

---

## 5. THE PATH TO FULL INDEPENDENCE (concrete, no hand-waving)

Ordered by leverage. None is a rewrite; each is a bounded, gate-able work-item.

**P0 — Make "rebuilds from clean" a green gate. ✅ DONE 2026-07-06.**
`COMPILER/BOOT/bootstrap_from_clean.sh` landed and ran **6/6 GREEN on a pristine clone**
(544s; per-stage numbers in the §1 table).  All four §2.3 reds fixed with observed
red→green.  One deliberate refinement over the spec above: the clean is PER-ARTIFACT and
dependency-ordered rather than a blind up-front wipe — each `iiis-N` binary is deleted
immediately before the stage that must recreate it, and `iiis-2` only AFTER the stdlib has
used it, because stage 4's golden mhash must REPRODUCE that exact binary (the loop
closure).  *Independence you don't continuously reproduce is independence you don't have* —
run this gate after any seed/BOOT/stdlib-wide change.

**P1 — Make the sovereign toolchain the DEFAULT emit path, not opt-in (days).**
Add an `--emit=sovereign` mode (and flip the default once green) so `iii_emit_assemble`/
`iii_emit_link` route through in-process `sovas`/`sovld` instead of `system("gcc")`. The
codegen already produces the `.o.s` both consume; this is a routing change in `emit.iii`
plus linking `sovas`/`sovld` as libraries into `iiis-2`. Gate: rebuild `build_stdlib` +
`run_corpus` with gcc **removed from PATH**; every program must still compile, link, and
hit its expected exit.

**P2 — Close sovas Tier-2 (SIMD/SHA-NI/AES-NI/AVX-512) so the gcc-as witness disappears
(days–weeks).** Extend `sovas.iii`'s encoder to the VEX/EVEX + SHA/AES mnemonics the crypto
modules emit; port `cpuid_helper.s`/`bench_helpers.s` to sovas-encodable form or emit them
from `.iii`. Gate: `sovbuild.sh` on the full crypto closure reports **witness=0**, and each
sovereign `.text` stays byte-identical to gas (extend `run_fixpoint.sh`'s cmp to the SIMD
modules).

**P3 — Bootstrap the sovereign tools without gcc (days).** Replace the one-time `gcc … -o
sovas_main.exe` with a self-hosted mint: sov-assemble + sov-link the tool sources using the
*previous sealed* sovereign tool binaries (a committed, mhash-sealed `sovas_main.exe` /
`sovlink_main.exe` play the seed role the C `iiis-0` plays for the compiler). Gate:
`run_fixpoint.sh` with gcc removed from PATH still ALL-PASS.

**P4 — Close the Thompson seed residual (weeks, host-dependent).** Land an
independent-lineage C compiler (clang/tcc/MSVC) on a build host and run the true seed-DDC:
build `iiis-0` under two unrelated C toolchains and diff the full downstream chain to `.o`
byte-identity (the framework — `seed_ddc_msvc.sh`, author-diversity — already exists;
`seed_text_identity_gate.sh` names this as the open residual). This retires "trust the seed
compiler" — the last non-III link in the chain.

**P5 — Wire or retire the dead branches (ongoing).** XII: either annotate real functions
`@lattice` so the canonicalise/emit path actually runs in a gated compilation (and dial back
the `III-XII.md` "fixed point" prose to match), or mark it explicitly as an
opt-in-experimental optimizer. Apply the same "wired or honestly-labeled" rule to every
island the fan-out surfaces (§4).

**Definition of done (the owner's bar):** a green `bootstrap_from_clean.sh` that, on a host
with **no gcc/ld/gas on PATH**, reproduces `iiis-2` byte-identically, rebuilds the full
stdlib + passes `run_corpus`, and links every artifact through `sovld` — with the seed's own
provenance closed by an independent-lineage DDC. At that point III reproduces itself, end to
end, with zero external toolchain and zero AI in the loop.

---

## 6. HONEST FRAMING NOTES

- "Sovereign" is overloaded in this tree across **three** distinct meanings — (1) sovereign
  *toolchain* (no gcc/ld), (2) `@sovereign` IO-*boundary* taint marking (`audit_sovereign.sh`),
  (3) the `ccl.iii` small *trusted typecheck base* (`trusted_base_check.sh`). This audit's
  independence verdict is about sense (1); the other two are real but answer different
  questions and should not be cited as toolchain-independence evidence.
- The project's **gate-level honesty is high**: the trust gates state their own scope and
  open residuals rather than overclaiming. Where overclaims exist they are in **doc prose**
  (e.g. XII "fixed point"), caught in §4 — the machinery under them is more modest than the
  narration.

---

## 7. MANUAL SWEEP — CONSOLIDATED FINDINGS (main session, every file class accounted)

**Coverage.** Load-bearing SOURCE read directly (C seed TUs, compiler spine, sovtc trio);
ALL 811 stdlib `.iii` classified by hard evidence with every outlier read; ALL `.iii`
scanned tree-wide for stubs/external-deps/C-deps with every hit read; corpus tautology-hunted
+ spot-read; artifacts/data/scripts classified by type; the load-bearing `.sh` read directly.
Not every one of the 1,820 corpus tests nor all 398 docs was line-read individually — those
are accounted for by class + scan + sampling, and stated as such.

### Independence — what the manual reading PROVES (call-graph + filesystem level)
1. **No hidden external-process anywhere but `emit.iii`.** `system|popen|exec|CreateProcess`
   across all `.iii` matches only the *word* "system" in comments/UI. Nothing in the stdlib
   or compiler secretly invokes gcc/python/a shell.
2. **The C-accessor "dependency" is phantom.** 766+ `from "*.c"` tags reference
   `ast_accessors.c`/`sema_accessors.c`/`lex_runtime.c`/`emit_accessors.c` etc. — **none of
   which exist on disk**; the symbols are `@export`-defined in `.iii` (`lex_rt.iii`, `ast.iii`)
   and resolved by name. The active compiler+stdlib need **no C accessor layer**.
3. **Only external runtime surface = standard Windows** (kernel32/user32/gdi32) + msvcrt.
   No third-party libraries.
4. **Void of Claude is TOTAL and structural.** No AI/LLM/network-inference call site exists
   anywhere; `ai_resolve` is a deterministic NL→intent→pattern-resolve engine ("no statistical
   learning"); every `claude` string is `.claude` directory-SKIP logic. The system *cannot*
   reach an AI at runtime — there is no such call.
5. **No shipped fake-success stubs.** 108 stub/placeholder keyword hits, all read: false
   positives, past-tense remediations, honest fail-closed gaps (`jit_emit` AVX-512 →
   `NOT_IMPLEMENTED`), or chokepoint-blocked scaffolds (`xii_emit_gen` crypto). Zero fakes reach
   a shipped path.

### Capability — what is REAL vs OVERSTATED (from the source, corroborated independently)
- **Compiler front-end + codegen: REAL and sovereign.** 99 `.iii` modules; generates its own
  x86-64 machine code (`.o.s`) with zero external tools. Seed↔self-host codegen identical 60/60
  (gate has teeth). Self-host fixpoint iiis-2 ≡ iiis-3 byte-identical.
- **Sovereign assembler+linker: REAL, self-hosting, byte-identical to gas/ld — but opt-in.**
  `sovas`/`sovld`/`sovcoff` read in full: genuine encoder + PE/COFF writers; `run_fixpoint`
  ALL-PASS. Real limits: VEX/EVEX (AVX2/512) unencoded → gcc-as witness; `sovld` routes only
  kernel32/msvcrt (GUI/net apps can't link sovereignly yet); gcc-bootstrapped tools.
- **Classical crypto: REAL, production-grade.** FIPS/RFC vectors present + verified; III's own
  SHA-256 byte-identical to coreutils AND OpenSSL on 3 inputs incl. edge cases (independent
  lineages, not self-grading).
- **Post-quantum (ML-KEM/DSA, SLH-DSA): PRESENT, weakly-anchored.** Corpus tests exist; **no
  NIST KAT vector constants found** — structural/determinism tests, not official-vector-gated.
- **811 stdlib modules: 779 reachable+gated, 14 apps, 18 thin, 0 orphan islands.** "Reachable"
  ≠ "correct": the XII optimizer is KAT-green yet a **dead codegen branch** (no source carries
  `@lattice`; confirmed in `iiis1_link_stubs.c` + `cg_r3.iii:1772`), with `III-XII.md`
  overclaiming it as the operative "fixed point."
- **Degenerate transform codecs.** Of 26 `tp_*`, several deliver less than their FORM_X→FORM_Y
  name claims — `tp_iii_to_c99` byte-wraps (no transpile), `tp_x86_disasm` byte-dumps (no
  decode), `tp_ast_dot`/`tp_iii_to_ast_bin` trivial. Honestly commented; nominally "complete."
- **Corpus is not tautological.** Exit codes depend on computed values checked against a pinned
  `EXPECTED[]` table; crypto expectations are FIPS/RFC-anchored. Non-crypto capability KATs use
  author-chosen expected constants → prove determinism + internal consistency, not independent
  ground truth.

### Production-readiness gaps (the honest "not yet" list)
1. ~~Clean rebuild is RED~~ **FIXED + GATED 2026-07-06** — four reds (the two above plus
   clone-autocrlf drift and ratchet scan-scope blindness) closed; `bootstrap_from_clean.sh`
   6/6 GREEN on a pristine clone (§2.3).
2. **Default emit path = gcc/ld** — the sovereign path is real but not wired as default.
3. **766+ stale `from "*.c"` provenance tags** misrepresent non-existent C deps (source honesty).
4. **PQ crypto not NIST-KAT-gated; XII dead branch + doc overclaim; degenerate codecs.**

### The distance to true independence (unchanged from §5, now source-confirmed)
P0 ✅ DONE (2026-07-06, gate 6/6 green); P1 make `sovas`+`sovld` the DEFAULT emit; P2 close `sovas`
VEX/EVEX so the gcc-as witness disappears; P3 self-mint the sovereign tools (drop the gcc
bootstrap); P4 close the Thompson seed residual with an independent-lineage C compiler; P5 wire
or honestly relabel the dead/degenerate branches (XII, the baseline codecs); + add NIST ACVP
vectors to the PQ suite. None is a rewrite. **Done = a host with no gcc/ld/gas on PATH
reproduces `iiis-2` byte-identically, rebuilds the stdlib, and links every artifact through
`sovld` — with the seed's provenance closed by an independent-lineage DDC.**
