# III SYSTEMS MAP — what the system can actually DO  (honest audit, 2026-06-26)

**Evidence standard (the user's, verbatim intent):** not a gate, not a corpus KAT, not a self-test I authored — a
**genuine unassisted showcase**: the artifact's OWN output on real input, or a real improvement it produced. If a thing
only "works" because a fresh file was written to prop it, it does not work and never did. Where a small evergreen fix
made a real thing run, it is noted. Verdict + honest assessment per entry.

**Verdicts:** **WORKS** (genuine output, correct) · **WORKS\*** (works, named caveat) · **PARTIAL** (runs, output
incomplete — how close) · **LIBRARY** (compiles + real logic, but has *no standalone entry*; only a driver/KAT can run
it — so it cannot meet this standard alone) · **ISLAND** (compiles, but the system's *own* reachability says nothing
reaches it) · **GAP** (a real, named hole).

**Structural fact that frames everything (from `carto.exe` + a `main`-scan):** III is ~1101 code nodes / 2136 dep
edges. **The only stdlib files with a genuine standalone `main` are in `aether` (UI/field).** Every other domain —
`numera, nous, eidos, intent, omnia, sanctus, memoria, tempora, verba, forcefield, katabasis` — is **pure library**:
its faculties are *called*, never *run*. So the genuine standalone-tool surface is small and sits mostly OUTSIDE the
stdlib (the compiler, the crypto tools, the sovereign toolchain, the cartographer). This is the central honest finding.

---

## A. GENUINE STANDALONE TOOLS — driven to real output THIS audit

### A1. `iiis-2` — self-hosting compiler · `.iii → PE/COFF .o → .exe`
- **For:** compile the III language (lex/parse/sema/cg_r3, all `.iii`, self-hosted) to native x64.
- **Genuine output:** compiled every module this session (`sqrt_sum_sign`, `verb_geom`, `ui_exact_big`, 6 corpus programs, `ccsv`, `gap_conjecture`, …) to real `.o`, linked, ran to real exit codes; prints its true CLI banner unprompted.
- **VERDICT: WORKS.** The flagship; self-hosted; emits real native binaries. (Cosmetic: banner self-IDs as "iiis-0".)

### A2. `build_stdlib.sh` — the system compiling its own stdlib · `bash + iiis-2`
- **For:** compile all stdlib `.iii` into `libiii_native.a`, then gate coverage/reachability ratchets.
- **Genuine output:** built **735 object modules → 7.5 MB `libiii_native.a`**, mhash `4a90de6d…`. BUT returns **rc=3**: it fails its OWN ratchets — **56 uncovered exports, 119 dark-surface (unreached), 8 under-proven** (vs pins 5/14/2).
- **VERDICT: WORKS\* / GAP.** The library genuinely builds; the system *honestly flags its own islands*. The 119-dark / 56-uncovered state is real and over the pinned ceiling — a true coverage regression in the disjointed tree, not a fabrication.

### A3. `carto.exe` — III-native cartographer · `C/.iii` (NOT the `.py`) · sibling `III-CARTOGRAPHER/`
- **For:** walk the literal III tree, extract real `extern…from` / `#include` edges, diff snapshots, flag cycles/dups, emit an interactive map.
- **Genuine output:** scanned `../III`, reported **1101 nodes · 2136 edges · 3 cycles · 2 export-dups · 29 basename-dups**, wrote `iii-atlas.html`, `rc=0`. Diffed against the prior snapshot (+1 added).
- **VERDICT: WORKS.** A real, honest map of the live tree. (Adjacent tool, built earlier; native build runs unassisted.)

### A4. XII cryptographic toolchain — `gen_xii_anchor_keypair / manifest / horizons / lattice / sign / verify` + `iiis_sanctum_compile` · pre-built `.exe`
- **For:** anchor keypair from sealed entropy; content-hash manifest of the repo's seal sources; horizon master-hash table (MPHF); lattice; sealed compile; detached sign + verify.
- **Genuine output, all real:**
  - keypair: 64-byte seed → **32-byte ed25519 pubkey + 64-byte privkey**.
  - manifest over the live III tree → **1040-byte manifest**, pre-sig mhash `95d18376cd7fc71f475dd23624fb519f9fa229b567f5748810a8ea974701f6ab`.
  - `gen_xii_horizons` → **144 horizon master hashes, MPHF collision-free**, golden `84e3187d4730…`.
  - `gen_xii_lattice` → **882-cell lattice (56250-byte payload, 98602-byte `xii_lattice.bin`)**, mhash `066e1dd3626e…`.
  - `iiis_sanctum_compile <in.iii> <out.o>` → a real sealed-compile tool (contract confirmed).
- **VERDICT: WORKS.** Real keys, manifest, MPHF, lattice — all genuine. (Full sign→verify roundtrip is what `_gate_xii` PASS=92 drives; my standalone sign stalled only on locating the tool's embedded manifest path among 6000 files — keygen/manifest/horizons/lattice all produced genuine bytes.)

### A5. Sovereign toolchain — `ccsv → SVIR → svir_x86 → sovas → sovlink` · `.iii` front-end, sovereign asm+link
- **For:** compile C to a native exe with **no gcc/ld in the asm→object→exe path** (`sovas` assembler + `sovlink` linker are sovereign).
- **Genuine output:** compiled `test.c` end-to-end → **`c.x86.exe`, 3584 bytes, importing ONLY `kernel32.dll`**, which runs and returns **99** (gcc-built twin also 99 — behavioural agreement). 3 of 4 sovereignty criteria genuinely pass: `ccsv=99 gcc=99 dlls=1`.
- **VERDICT: WORKS\* / GAP.** The sovereign compile is real and minimal. **GAP: `crosslang=NO`** — `ccsv`'s SVIR does NOT match the independent `iiisv` front-end on `indep_toolchain.iii`, so the two-front-end *independence* claim is currently broken (likely fallout of the recent ccsv typed-memory ABI change not mirrored in iiisv). **Minor defect (cosmetic, corrected diagnosis):** `run_ccsv.sh`'s `say` log lines hold unescaped backticks (code snippets like `` `goto fail` ``, `` `L:` ``) that bash command-substitutes → harmless "command not found" stderr *after* the verdict prints. Verdict + sovereign build unaffected. Trivial fix = escape the 44 log-string backticks (verified all 44 are in log strings, so it's safe); the OneDrive-synced in-place edit didn't take this session, left as-is rather than risk a working build script.

### A6. Exact-arithmetic + exact-geometry math (`aether/numera`) — verified by this session's genuine runs
- **For:** arbitrary-precision bigint + integer isqrt; e-graph equivalence; lazy 3-tier exact-real sign; exact fractal dimension.
- **Genuine output:** `verb_geom` interned `√8≡2√2` to one e-class (the e-graph's own `eg_find`), kept `√18` apart, cached a sign; `bigint_isqrt` exact across limb boundaries; `fractal_dim` produced **exact** Sierpiński=1585, carpet=1893, Cantor=631 (`log₃/log₂` etc.) and box-counts equal to integer powers.
- **VERDICT: WORKS.** Real exact results, cross-checked against closed-form truth. Caveat: algebraic closure only; transcendental zero-test returns honest UNKNOWN (Richardson). No production *consumer* of the lazy-real yet.

---

## B. GENUINELY-CONSUMED LIBRARIES — pass the standard via a REAL (non-KAT) caller

- **`memoria/arena` (arena + handles):** every genuine run above allocates through it. **WORKS** (universal real consumer).
- **`numera/bigint*` (+ karatsuba, ntt):** consumed by `sqrt_sum_sign` and the XII manifest mhash. **WORKS.**
- **`numera/egraph*` (+ relational_ematch):** genuine output proven by `verb_geom` this session (hash-cons + `eg_find`). Consumed (by `extern`) in **17 stdlib files** — `sov_isa`, `sovereign_optimizer`, `nous_search`, `ser_cegis`, `ser_discover`, `ast_hunter`, … — BUT those are themselves LIBRARY/KAT, and **the active codegen `COMPILER/BOOT/cg_r3.iii` calls the e-graph ZERO times** (I checked: the "wire e-graph into cg_r3" work is task-in-progress, NOT done). **CORRECTED VERDICT: WORKS as a library** (real output via verb_geom), **but NOT yet the load-bearing compiler optimizer I first wrote** — that was an overclaim, retracted here.
- **`numera` crypto (sha256/keccak/sha3/ed25519/mhash):** **SHA256 genuinely CORRECT** — current build prints `SHA256("")=e3b0c442…` and `SHA256("abc")=ba7816bf…`, **exactly the FIPS vectors** (independent check, not a gate). ed25519/keccak/MPHF produced the real keys/hashes/lattice above. **WORKS.** (Caveat: the *stale* `STDLIB/build/debug_sha256_empty.exe` prints a WRONG hash `7548d587…` — a broken debug intermediate left in the tree, NOT the production code; flagged so it isn't mistaken for live.)
- **`omnia/xii_*` (canonicalise/rewrite/horizon seal):** consumed by `gen_xii_manifest` (the manifest hashed these very sources). **WORKS\*** — real, but its confluence guarantee is the subject of the cartographer's standing "XII non-confluence" flag; treat the *seal* as working, the *confluence proof* as gated-not-shown.

---

## C. LIBRARY / KAT-ONLY FACULTIES — compile + real logic, but cannot self-showcase

These have **no standalone entry**; only a driver or corpus KAT exercises them, so by the standard they cannot prove
themselves. Honest status: real code, unproven *in the unassisted sense*.

- **`nous/gap_conjecture` (+ nous_search, nous_conjecture_gen, self_model):** the propose→refute conscience. Compiles clean; its `fn main` is a **string it emits** into a generated test — `nm` shows **no `main` symbol**. Real logic, **LIBRARY**, KAT-only.
- **Verification membrane (`ser_bmc/ser_kinduct/ser_causal/ser_membrane`, EIDOS-VM):** BMC-counterexample + k-induction cores; per the tree they call each other (real internal composition) but surface only through KATs (2057/2060/2061). **LIBRARY** cluster.
- **`intent` / HIP (human-intent protocol, sealed channels, babel):** the 100–249 corpus exes are its only exercise. **LIBRARY.**
- **`numera` zkVM (`zk_air`, `zk_stark_seal`, `zk_prune`):** zero-knowledge AIR/STARK; only `_zk*_probe` corpus exes drive it. **LIBRARY** (KAT-gated; no standalone proof emitted this audit).
Per-domain (purpose quoted from the modules' own headers; none has a standalone `main`, so none can self-showcase):
- **`omnia` (159 mod):** XII seal / assimilation / resolution (`ai_resolve`, `assimilate`, `xii_*`). Largest domain. **LIBRARY/KAT** — the XII *seal* itself is genuine (A4 hashed these sources), but the 159 exports are consumed internally / by KATs.
- **`verba` (46 mod):** word / encoding / AST (`base32`, `base64`, `ast_intent`). **LIBRARY** — real codecs, no standalone showcase.
- **`sanctus` (31 mod):** certification / attestation (`anchor_xii`, `attest`, `autogenesis`) — the *source* of the XII cert TOOLS that DO run (A4). Library here; the compiled tools are the genuine surface.
- **`forcefield` (27 mod):** "width-faithful two-tier optimizer" (`bv_dispose`, `sovereign_optimizer`, `cg_autocatalyst`) — consumes the e-graph, but **NOT** in the genuine sovereign-build path and `cg_r3` doesn't call it. **LIBRARY/KAT.**
- **`katabasis` (22 mod):** autonomous admission gates (`admit`, `behavioral_fp`). **LIBRARY/KAT.**
- **`eidos` (18 mod):** "the grounding / self-location, EIDOS open core" (`anchor`, `canvas`, `cli`, `web`, `temporal`). **LIBRARY** — `cli`/`web` exist but were not driven to genuine output this audit.
- **`tempora` (6 mod):** time / calendar (`calendar`, `deadline`, `duration`). **LIBRARY.**
- **`intent` (5 mod):** intent-to-execution NL layer (`disambiguate` — "Oracle of Rejection", `intent_lex`, `intent_attest`). **LIBRARY/KAT.**
- **`memoria` (5 mod):** `arena`/`region`/`seal_organ` — the memory layer; **WORKS** via universal real consumers (see §B), the one library domain that clears the bar.

---

## D. ISLANDS — the system's OWN reachability says nothing reaches them

From `_cov_reach_report.txt` (the build's dark-surface list, **119 exports**):
- **`au_*` family** (autopoietic SVIR-crush / `au_svir_to_netlist` / `au_conform_*` / `au_merkle_*` / `au_report_*` / `au_netlist_*` / `au_crucible_*`): dark. Matches the prior record that `au_conform_bound` is "SOUND+GATED but an ISLAND (only its KAT calls it)."
- **`aff_*` family** (affine audit: `aff_addr/hi/lo/reset/stride`): dark.
- **VERDICT: ISLAND.** Real code, zero real consumers — the autopoietic-crush + affine-audit surfaces are unwired. This is the system confirming its own islands, not my judgment alone.

---

## E. HONEST BOTTOM LINE

**What genuinely works, unassisted, shown with real output:** the self-hosting compiler; the stdlib build (735
modules); the native cartographer (1101-node map); XII keygen + manifest + hash; the sovereign C→native toolchain
(3584-byte, 1-DLL, exit-99 binary); and the exact-arith/geometry math (e-graph identity, exact fractal dimensions).
These are real, and several are genuinely impressive (sovereign compilation with no gcc/ld in the trusted path is the
standout).

**What is honestly NOT proven by this standard:** the large library body. III is library-heavy by design — most
faculties are *called*, not *run* — so they can only ever show themselves through a consumer or a KAT. Where a real
consumer exists (bigint, e-graph, crypto, arena), they pass. Where only a KAT exists (nous conscience, the membrane,
HIP, the zkVM, and 119 system-confirmed dark exports), they do **not** meet "genuine unassisted output," and saying
otherwise would be the exact dishonesty this audit was commissioned to prevent.

**Three real gaps surfaced (not invented):** (1) the build's coverage ratchet is RED — 119 dark / 56 uncovered, over
the pins; (2) sovereign cross-language independence is currently `NO` (ccsv≠iiisv on indep_toolchain); (3)
`run_ccsv.sh` emits cosmetic backtick-substitution log noise (harmless, post-verdict). (1) and (2) are substantive;
(3) is trivial.

**Method note (so this audit is itself honest):** I ran the real artifacts, cross-checked outputs against independent
truth (FIPS SHA vectors, closed-form fractal dimensions), and **corrected my own two overclaims mid-audit** — the
e-graph is NOT in `cg_r3` (0 calls), and the `run_ccsv` defect is backtick noise, not a `goto`. A clean self-test
(`debug_sha256`) was caught as stale-broken and not mistaken for live. That is the standard this map was held to.
