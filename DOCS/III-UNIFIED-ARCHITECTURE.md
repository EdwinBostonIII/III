# III — THE UNIFIED ARCHITECTURE (the orchestration)

**What this is.** The single structure that ties every component and capability of III into one
production-ready, self-referential whole — *greater than the sum of its parts* by construction, not by
assertion. Written against the live tree, **measured** (rev. 3: rev. 2 measured the dependency graph; rev. 3
measured the import-resolution mechanism and *retracted* a rev. 2 over-claim — both structural invariants
now stand on green, reproducible gates, §3/§11). It does **not** invent a new architecture: the cheapest
pattern is the one already latent in the tree. Its job is to make that latent structure **load-bearing and
enforced**, name the decisions that are expensive to reverse, and order the remaining realization so the
whole closes under one gate.

**Claim tags** (as in `III-ARCHITECTURE-AUDIT.md`): `[meas]` = measured against the live graph *this pass*;
`[gated]` = a passing corpus/KAT/gate witness; `[cited]` = read in source at `file:line`; `[judgt]` =
architectural judgment. **DOCUMENTED ≠ VERIFIED** — every gate named below is re-run, not relayed; exit
codes are 8-bit.

---

## 0. The verdict in one paragraph

III is **already** one architecture, written formally in `III-INTERIOR-LOGIC-ATLAS.md`: every faculty is a
pair *(P, D)* — a generator and a **total, decidable disposer that never reads a statistic**
(`D ⊥ freq/sample/param`), modules couple **only by shared symbols**, and `Σ` self-mutates under the same `D`
`[cited: interior-logic-atlas.md:42-48]`. The felt "disjointedness" is not the absence of a structure; it is
the **realization gap** between that clean spine and a 3,171-file body that grew in waves. The ideal
end-state is therefore not a rewrite and not "everything becomes event-based." It is **one law, many kinds,
layered substrates**, organized as **a closed trust floor with a production body routed through it.** The
headline result of the measurement pass: **the trust floor is audit-closed — every one of its 13 members
imports only libc or another floor member; zero edges reach up into the body** `[meas]`, and that invariant
is now **enforced by a gate** (`STDLIB/sovir/floor_closure_gate.sh`, green, teeth proven). *That closure —
not any single clever module — is what makes the whole exceed the sum:* III compiles itself, verifies its
own output against an 82-line anchor that depends on nothing outer, seals with a hash it computes, and proves
its capabilities with programs it compiled — a loop that closes on a floor a human can audit in one sitting.
Today that loop is real in every arc but **not yet witnessed by one gate** (`run_completion.sh` is unbuilt; 4
of its 6 sub-gates are absent — §9). Closing that is the whole of the remaining work. Confidence: **high** on
the structure (now measured), **medium** on the effort to close (§10).

---

## 1. The forces (what actually shapes the structure)

**Functional (the behaviors that drive structure — not every feature):**
- **F1.** Compile III → native PE/COFF, self-hosted, deterministically (`iiis-2`, 99 `.iii` in
  `COMPILER/BOOT`) `[gated: bootstrap_from_clean 7/7]`.
- **F2.** Reduce every trust claim to one small, self-contained checker (`SVIR` + `svir_verify.iii`, 82
  lines, opcodes `0x01–0x89`, **imports nothing** `[meas]`) `[cited: STDLIB/sovir/svir_verify.iii:1-82]`.
- **F3.** Prove each capability by a compiled-and-run `.iii` program, not an external harness (the corpus,
  1,776 KATs) `[gated: run_corpus FAIL=0]`.
- **F4.** Bind every artifact to a content hash the system itself computes (the seal chain; basal law
  `[cited: commit e98e7ad7]`).
- **F5.** Remove gcc/ld from the *trusted* build path (the sovereign toolchain: `ccsv → SVIR → sovas →
  sovcoff → sovld`) `[gated: sovereign exit-99, 1-DLL binary]`.

**Non-functional, with the numbers that are real:**
- **Determinism is absolute, not "fast."** The bootstrap must reproduce **byte-identical**: `iiis-2 ==
  iiis-3`, seed↔self-host identity 60/60 `[gated]`. This is the load-bearing NFR; it dominates every other.
- **Auditability of the trust floor is a size + closure budget.** The anchor is 82 lines *and imports
  nothing* — "the whole system's trust anchors here" `[cited: svir_verify.iii:4]`. Any growth of the ISA, or
  any new floor import, spends this budget; the floor-closure gate makes the second kind of spend a hard stop.
- **Coverage is a ratchet, down-only.** Pins: uncovered ≤ 5, gate ≤ 2, dark ≤ 14 `[cited: L7]`.
  "Production-ready" means these reach **0**, and the *full* `build_stdlib` gate becomes the standard green.
- **TCB is measured, not assumed.** Sovereign x86 imports **1 DLL (kernel32)** `[gated]`; the irreducible
  floor is CPU/microcode + OS loader + the `msvcrt` libc shim, to be named in `DOCS/III-TCB.md` (absent — R7).

**Scale of the body (refreshed, `[meas]` this pass — corrects a first-draft error):**
- **811** faculty modules across the 12 `(P,D)` subsystems (numera 308 · aether 157 · omnia 155 · verba 46 ·
  sanctus 29 · nous 28 · forcefield 25 · eidos 25 · katabasis 22 · tempora 6 · memoria 5 · intent 5) — **not
  the ~2,900 the first draft claimed** (that conflated the corpus). · **1,776** corpus KATs (R6, the proof
  surface) · **99** compiler modules (R3) · ~130 sovereign-toolchain/SVIR modules (R1–R2) · **3,171** `.iii`
  total.

**Constraints the structure must not fight (the codebase's own conventions):**
- **No Python** in any build/gate/judgment path `[cited: L4]`; **no subagents** on this tree (hard rule);
  **the weave is the one primitive** (fix the substrate, wire existing faculty, author nothing III already
  discovers); **seal cascade law** (edit a sealed source → re-run `seal_sources.sh` same step, L3); **sibling
  protocol** (files with uncommitted parallel-session edits are frozen — right now `ccsv.iii`, `sovas.iii`,
  `sovparse.iii`; the sovereign frontier is in flight, L6).

---

## 2. The one structure — a closed floor, a body routed through it

The architecture **is the dependency direction.** The measurement pass (§3) shows it is not a single naive
nesting but **two regions with two different invariants**:

### 2.1 The regions

```
   ╔══════════════════════════════════════════════════════════════════════════╗
   ║  THE PRODUCTION BODY  (a shared-symbol WEAVE — coupled by `from "X.iii"`)   ║
   ║                                                                            ║
   ║   R6  apps + corpus     iii_studio · mech · sovhash · aether mains ·        ║
   ║                         1,776 corpus KATs (the capability proof surface)    ║
   ║   R5  (P,D) faculties   numera·omnia·aether·verba·nous·eidos·sanctus·       ║
   ║       811 modules       forcefield·katabasis·intent·memoria·tempora         ║
   ║   R3  the compiler      lex·parse·sema·cg_r3·emit  (COMPILER/BOOT)          ║
   ║          │                                                                 ║
   ║          │  R3 depends DOWN on a subset of R5 — the "compiler substrate":   ║
   ║          │  keccak · ser_egraph · xii_{term,rewrite,canonicalise,horizon} · ║
   ║          │  cg_opt_rules  (8 edges, one-directional, CYCLE-FREE [meas])     ║
   ║          ▼                                                                  ║
   ║   ═══ every trust claim of the body routes DOWN through the floor ═══       ║
   ╠══════════════════════════════════════════════════════════════════════════╣
   ║  THE TRUST FLOOR  (AUDIT-CLOSED: imports only libc / within-floor [meas])   ║
   ║                                                                            ║
   ║   R2  sovereign path    ccsv · iiisv · iiisv2 · sovas · sovparse ·          ║
   ║                         sovcoff · sovld     (→ SVIR → native PE, no gcc/ld)  ║
   ║   R1  the anchor        svir_verify (82 lines, imports ∅) + svir_prog +      ║
   ║                         svir_{x86,wasm,interp,dis} backends                 ║
   ║   R0  irreducible TCB   CPU/microcode · kernel32 · msvcrt libc shim         ║
   ╚══════════════════════════════════════════════════════════════════════════╝
        THE SEAL SPINE (orthogonal): seal_sources.sh · mhash_lib.sh (sovhash,
        sovereign-minted, GNU veto-witness) · SEAL.mhash · the forge (dual root)
```

**The correction rev. 2 makes** `[meas]`: the rings are a **trust partial order, not a directory nesting.**
The compiler (R3) is *not* simply inner to the whole stdlib — it is a privileged consumer that sits **above**
the ~8 R5 faculties it needs (keccak to seal, the e-graph to optimize, XII for proof-carrying codegen) and
**below** the trust floor it emits through (`sovas/sovcoff/sovld`). Those 8 compiler-substrate faculties were
measured to **not** import back into R3 — the sub-graph is acyclic, so "R3 depends on part of R5" is a clean
one-directional edge set, not a cycle.

### 2.2 The two invariants (this is the enforceable heart of the design)

**I1 — Floor closure (hard; MEASURED-TRUE; ENFORCED).** No member of the trust floor imports anything
outside `{libc} ∪ {floor}`. This is what lets a 3,171-file system have a trust floor a human can read in one
sitting: the floor can be audited *in isolation*, because nothing in it transitively pulls in un-audited body
code. *Status:* all 13 floor members clean `[meas]`. *Enforcement:* `STDLIB/sovir/floor_closure_gate.sh`
(green today; teeth proven — inject one outward import → rc=1; `--selftest` proves both arms). *This is the
single most important invariant in the system, and it now has teeth.*

**I2 — Body acyclicity + convergence (ENFORCED; MEASURED-GREEN).** The production body (R3+R5+R6) is a
shared-symbol weave; its invariant is (a) **no un-allowlisted import cycles and no duplicate `@export`
symbol**, and (b) the whole body's trust **routes down through the floor** (Φ1: the seed compiles via
`ccsv → SVIR`; the emit fold: `iiis-2` emits via `sovas` in-process). *Enforcement (already exists — I do not
duplicate it):* `build_stdlib.sh:255-289` runs the native cartographer as an architectural-invariant gate
that **fails the build, before any compile,** on a new cycle or an export collision `[cited]`; intentional
exceptions live in `III-CARTOGRAPHER/gate_allow.json`. *Status this pass* `[meas]`: `carto --gate` → **PASS**
on **1,181 nodes / 2,255 edges** — 0 duplicate exports, 0 un-allowlisted cycles. The compiler-depends-on-
keccak/e-graph/XII edges are **not** violations — they are acyclic `[meas]`. *One honest caveat:* the gate is
a **SOFT** dependency (the cartographer lives outside the sealed tree, so its absence *skips* the gate rather
than breaking the bootstrap — a deliberate choice so the core needs no sibling tool). So I2 is enforced
*whenever the tool is present*, which is the normal build.

**Why this is the architecture and not an imposition** `[judgt]`. It matches the audit's empirical finding
exactly — *only `aether` has a standalone `main`; every other domain is pure library, called not run* — which
is precisely what a closed-floor / weave-body structure predicts. The rings are read out of the system's own
import graph, not drawn onto it (§3).

---

## 3. Ring conformance — MEASURED (the evidence spine)

The claims above are graph facts, verified this pass by extracting every `from "X.iii"` edge and classifying
its endpoints. This section is the audit trail; re-run the one-liners to reproduce.

**I1 — the floor is closed** `[meas]`. Every floor member's complete import set:

| Floor member | Imports | Verdict |
|---|---|---|
| `svir_verify.iii` (the anchor) | *(none)* | closed |
| `svir_prog.iii` | *(none)* | closed |
| `svir_x86.iii`, `svir_wasm.iii` | `msvcrt`, `svir_prog.iii` | closed |
| `svir_interp.iii`, `svir_dis.iii` | `msvcrt`, `gen_svir.iii`¹ | closed |
| `ccsv.iii`, `iiisv.iii`, `iiisv2.iii` | `msvcrt` only | closed |
| `sovas.iii` | `msvcrt` only | closed |
| `sovparse.iii` | `sovas.iii` | closed |
| `sovcoff.iii`, `sovld.iii` | `msvcrt`, `sovas.iii`, `sovparse.iii` | closed |

¹ `gen_svir.iii` is a **generated** floor artifact (absent statically; produced and compiled-against at gate
time) — within-floor by construction. **Result: 13 members, 0 outward edges.** `floor_closure_gate.sh` → PASS.

**I2 — the compiler's dependence on the body** `[meas]`. R3 imports 33 distinct modules: ~22 R3-internal, **3
R2** (`sovas/sovcoff/sovparse` — the emit fold landing, an *inward* edge ✓), and **8 genuine R5** substrate
faculties (`keccak`, `ser_egraph`, `cg_opt_rules`, `xii_{term,rewrite,canonicalise,horizon}`, `xii_ldil`).
Each of the 8 was checked for a back-edge into R3 (`lex/parse/sema/cg_r3/emit/ast/main`): **none found** — the
sub-graph is acyclic.

**The basename-collision smell — measured BENIGN** `[meas]` (this corrects rev. 2, which called it a
hazard — see §11). 8 basenames are duplicated tree-wide (`_c` is build scratch; 7 real source dups:
`cg_opt_rules · field · parse · resolver_replay · ripple · weave · xii_ldil`), and two (`cg_opt_rules`,
`xii_ldil`) are compiler imports. **This is not a failure mode.** Two independent facts contain it: (1)
**resolution is by symbol, not filename order** — `build_stdlib.sh` compiles each module *separately* to
`.o`, and `link.iii` binds each import by qualified symbol name plus a content-addressed `closure_mhash`
`[cited: link.iii export table]`, so a `from "field.iii"` resolves to a *symbol*, not to whichever file
sorts first; (2) the colliding modules are **export-disjoint** — `eidos/field` vs `numera/field` share 0
exports, the `ripple` trio shares 0 across all pairs `[meas]` — and the moment any two shared a symbol, the
I2 gate (above) would fail the build before compile. So the collisions are a naming *smell* (worth a rename
for readability), not a trust problem. The residual cost is cosmetic; ADR-5's real cost is islands, not
collisions (§6).

---

## 4. The unification thesis — "greater than the sum" is the closed loop

The parts are individually real. The *surplus* is that they form a **closed, self-referential loop** in which
each subsystem's output is another's trust input — and the loop bottoms out on a floor that (I1, measured)
depends on nothing above it:

```
   (P,D) faculty  ──emit──▶  cg_r3  ──lower──▶  SVIR  ──verify──▶  svir_verify  ──accept──▶ native PE
        ▲                                          │              (imports ∅ — the floor)      │
        │ prove                                    │ attest                                    │ run
     corpus KAT ◀──compile── iiis-2 ◀──build── libiii_native.a          zkVM (~2^-86)      exit code
        │                       ▲                    ▲                      │                   │
        └──────── seed iiis-0 ──┘   seal_sources / sovhash ◀── the forge (dual root) ◀──────────┘
```

Read as one sentence: *a faculty is emitted by the compiler that was bootstrapped from a seed, lowered to an
ISA verified by an 82-line anchor that imports nothing, run to an exit code a KAT asserts, sealed by a hash
the system itself computes, and the seal binds the very toolchain that produced it.* **The falsifiable form:**
the whole exceeds the sum iff there is one gate whose green requires every arc to hold *and* is itself produced
by the loop. That gate is `run_completion.sh` (§9) — **unbuilt; 2 of 6 sub-gates exist.** Each subsystem's
role in the loop is what forbids it from being an island: the closure loop is the anti-island invariant made
positive.

---

## 5. The load-bearing interfaces (the contracts expensive to change)

Guard these; let everything else stay cheap.

1. **The SVIR ISA** (`DOCS/SVIR-V1-CANONICAL.md`, enforced by `svir_verify.iii`, opcodes `0x01–0x89`). The
   narrowest, most expensive interface: every backend (x86/wasm/r0), every lowering (`cg_r3`, elective
   XII→SVIR), and the zkVM bind to it. *Rule:* an opcode is added only when a real construct forces it
   (history: `CALL_INDIRECT` was last, added only when the seed's function pointers demanded it).
2. **The floor membership** (`floor_closure_gate.sh`'s `FLOOR_FILES`). *The floor's definition is now a
   checked list.* Adding a member is an architectural act — it widens what "sovereign floor" means and the
   gate re-audits closure. This interface did not exist before rev. 2; it turns I1 from prose into a pin.
3. **The `(P,D)` faculty contract** (`Ax D1–D4`): a generator + a **total decidable** disposer, `D ⊥ stat`.
   The module ABI of the 811-module body; it is what makes shared-symbol coupling sound.
4. **The seal / mhash chain** (`seal_sources.sh` seals `STDLIB/iii/**` only; `mhash_lib.sh`/`sovhash`;
   `SEAL.mhash`; the forge dual root). Self-authored provenance; every edit to a sealed source pays the cascade.
5. **`libiii_native.a`** — the single stdlib link boundary (714 modules, mhash-pinned).
6. **The corpus KAT ABI** — compile with `iiis-2`, link `libiii_native.a` + libc, run as native PE, exit code
   == deterministic expected; unique numbering (twins excepted); family-runner registration.
7. **The `from "X"` import resolution** — bound by qualified **symbol + content-addressed `closure_mhash`**
   at link (`link.iii`), *not* by filename order. Duplicate exports and new cycles are already enforced by
   the `build_stdlib` cartographer gate (I2). No `from`-ambiguity gate is warranted — rev. 2 proposed one;
   rev. 3 measured the resolution and the existing enforcement and retracted it as redundant (§11). Basename
   uniqueness is a readability nicety, not a load-bearing contract.
8. **The bootstrap fixpoint** — `iiis-0` (frozen C seed) → `iiis-1` → `iiis-2` → `iiis-3`, byte-identity gated
   on `stage1_corpus`.

---

## 6. The ADR decisions (each a trade-off; the cost is named or it is not a decision)

**ADR-1 — One narrow, self-contained IR (SVIR) as the trust waist.** *Chosen:* every execution claim lowers
to one small ISA verified by one 82-line checker that **imports nothing** `[meas]`. *Rejected:* per-domain
verifiers / trusting the native compiler directly. *Discriminating reason:* a human-auditable trust floor is
possible only if trust funnels through something small *and closed*. *Cost given up:* SVIR is **deliberately
inexpressive** — high-level constructs (XII terms, exact-real intervals, UI events) must be *lowered* to it,
extra work and an extra place bugs hide. The 82-line + zero-import budget is a permanent tax on every new
capability's execution semantics.

**ADR-2 — Two invariants: a closed floor, an acyclic body routed through it.** *Chosen:* enforce strict
inward closure on R0–R2 (I1) and acyclicity + convergence on R3–R6 (I2), as *separate* rules. *Rejected:* a
single "everything nests inward" rule (the first-draft framing — measurement showed it false: the compiler
depends *up* on 8 R5 faculties, which is correct, not a violation). *Discriminating reason:* the trust
property (nothing un-audited beneath the floor) and the health property (no cycles in the body) are different
claims with different enforcement; conflating them either forbids legal edges or permits illegal ones. *Cost
given up:* two gates to maintain instead of one clean slogan, and an explicit, defended list of which R5
faculties are "compiler substrate."

**ADR-3 — `(P,D)` with `D ⊥ statistic` as the module contract.** *Chosen:* total, decidable, derivation-only
admission. *Rejected:* learned/statistical/heuristic disposers. *Discriminating reason:* determinism-absolute
(the load-bearing NFR) forbids admission depending on a sample. *Cost given up:* **whole solution classes are
off the table** — anything whose best answer is statistical must be reformulated as decidable or left an
honest `UNKNOWN` (the tree already does: transcendental zero-test returns `UNKNOWN`). A real, chosen ceiling.

**ADR-4 — Layered substrates: event-fold *and* arenas, not one storage model.** *Chosen:* append-only
event-fold where state is witnessed/reversed/audited; fixed-slot arenas where the loop is hot. *Rejected:*
"everything becomes event-based." *Discriminating reason:* event-fold structurally avoids four object-model
bugs (exhaustion-corruption, aliasing, manual lifecycle, no-witness) — but a rolling-hash fold on a hot inner
loop is the wrong cost. *Cost given up:* two storage models, and an explicit arena↔fold boundary.

**ADR-5 — Shared-symbol coupling (the weave), no explicit wiring.** *Chosen:* modules relate only by shared
symbols; reachability is *computed* (the cartographer), not declared. *Rejected:* an explicit dependency
manifest / DI container. *Discriminating reason:* it is what keeps the `(P,D)` schema uninterpreted — rename a
symbol and every proposition stands. *Cost given up, now measured:* **islands become possible** (`au_*`,
`aff_*` today) — code no reachability reaches. So the architecture carries a **dark-surface ratchet** to make
islands a gate failure, not silent rot. (Rev. 2 also charged "basename collisions make edges ambiguous"; rev.
3 measured that away — resolution is by symbol + `closure_mhash`, and the I2 gate already fails on duplicate
exports, so the collisions are a cosmetic smell, not a cost of the weave — §3, §11.) The real price is the
reachability police; the name-uniqueness police is unnecessary.

**ADR-6 — Corpus-as-proof, sealed, over an external harness.** *Chosen:* capabilities proven by
compiled-and-run `.iii`, no third-party harness. *Discriminating reason:* "III proves III" must be literal.
*Cost given up:* a 1,776-KAT corpus that must stay green and uniquely numbered, plus a renumbering ceremony
on collision — heavier than `pytest`, the price of self-proof.

**ADR-7 — Self-authored seals (the basal law).** *Chosen:* III computes its own seal hashes (`sovhash`,
sovereign-primary) with a GNU tool only as a *veto-witness*. *Discriminating reason:* a system that cannot
author its own provenance is not sovereign at the floor. *Cost given up:* the seal path now depends on the
compiler being correct (a FIPS-180-4 self-KAT guards it); a sovereign/witness disagreement is a hard stop.

---

## 7. Stress the design — scale, failure, change

**Scale.** *Parallel:* the corpus (1,776 independent KATs), the R5 compiles (independent TUs), the seal chain
(content-addressed). *Serial by design:* the seed (one artifact that must compile *completely* — the Φ1 long
pole), the SVIR verifier (one checker every trust claim funnels through — the singularity is the point), the
coverage ratchet (whole-tree). These do not and should not parallelize.

**Failure (single points, blast radius, containment).**
- *`svir_verify` bug* → whole trust closure compromised (max blast radius). *Contained by:* 82 lines,
  total/decidable, **imports nothing** (I1 — nothing beneath it can be wrong *by dependency*), adversary KATs
  (forged-LOAD/non-perm/corrupted-root reject). The correct place to concentrate risk.
- *A new floor import slips in* → the audit-in-isolation property silently breaks. *Contained by:*
  `floor_closure_gate.sh` (rc=1 on any outward edge) — new in rev. 2.
- *Seed miscompile* → bootstrap breaks. *Contained by:* byte-identity gate on `stage1_corpus`.
- *Island export* → dead code claiming coverage. *Contained by:* the dark-surface ratchet.
- *Duplicate `@export` symbol or a new import cycle* → a link bomb / structural breach. *Contained by:* the
  `build_stdlib` cartographer gate — **fails the build before any compile** (`build_stdlib.sh:255-289`); green
  this pass (1,181 nodes, PASS). *Residual:* the gate is SOFT (skips if the cartographer is absent) — the
  deliberate design so the sealed core needs no sibling tool; when the tool is present (the normal build) it
  is enforced. Basename collisions are *not* a failure mode here — they resolve by symbol, not filename (§3).

**Change (the requirement that will actually come).** "A new capability / backend / opcode." Absorbed because
SVIR is the narrow waist: a new backend re-verifies against the *same* anchor; a new capability is a new
`(P,D)` faculty + a KAT (no change to R1–R4); a new opcode is the *only* change that touches the expensive
interface, forced through the one file where it is visible and gated. Deferred to the last responsible moment:
XII→SVIR one-object lowering (elective — shared-fold binding already sound) and live-OS Ring −1
(designed, deliberately uncrossed — an authorization boundary, not a capability gap).

---

## 8. The realization program (simplest-first, each step gated, sibling-respected)

The trust floor (Φ1) is the keystone and longest pole; author-diversity follows it; coverage and the
conscience sweep run in parallel; the structural dedup earns the surplus; the capstone gate is last. **The
sovereign frontier (`ccsv/sovas/sovparse`) is sibling-owned now — steps 1–2 coordinate; do not clobber (L6).**

- **[✔ mostly] Step 0 — Enforce the invariants (cheap, do first).** I1: `floor_closure_gate.sh` **built,
  green, teeth proven** this pass. I2: **already enforced** by the `build_stdlib` cartographer gate — verified
  **PASS** this pass (1,181 nodes, 0 dup-exports, 0 un-allowlisted cycles); no new gate built (rev. 3 retracted
  the redundant `from`-ambiguity gate — §11). *Optional follow-up:* wire `floor_closure_gate.sh` into
  `build_stdlib` as a SOFT gate for symmetry with I2 — a seal-aware edit, best done when the tree is quiescent
  (it touches a spine script). This is the down payment that makes every later step's "don't regress the
  structure" checkable.
- **[ ] Step 1 — Close the trust floor (Φ1 / R1).** `ccsv` compiles all 6 seed modules to SVIR, every
  function verifies, sovereign-built `iiis-0` is **byte-identical** to the gcc-built seed on `stage1_corpus`.
  *Status:* structural zero (`verify_fail 0/865`); behavioral campaign in flight. *Exit gate:* build
  `run_seed_sovereign.sh` (absent). *Falsifier:* flip one emitted opcode → `svir_verify` reddens.
- **[ ] Step 2 — The sovereign emit fold (F5; active frontier C1→C2→C3).** C1 landed (`sovtc` in
  `libiii_native.a`). C2/C3: `emit.iii` calls `sovas/sovcoff/sovld` **in-process** → `iiis-2` emits native PE
  with **zero gcc/ld**. *Falsifier:* a gcc dependency reappears → `run_evergreen` reddens.
- **[ ] Step 3 — Author-diversity DDC (Φ2): `crosslang=YES`.** `ccsv ≡ iiisv` on the seed lineage. *Exit
  gate:* `run_ddc.sh` + a `seed` axis, rc=0.
- **[≈ mostly] Step 4 — Coverage ratchet to zero (Φ4).** Measured green this pass: `build_stdlib` →
  **uncovered=0** (pin 0), dark-surface=1 (pin 1), under-proven=1 (pin 2). The independence campaign closed the
  uncovered gap; the residual dark=1/under-proven=1 sit at their pins. *Exit gate:* `build_stdlib
  --check-corpus` rc=0, ratchet all-zero.
- **[✔ resolved / ⚠ deeper find] Step 5 — the `eidos` web/cli/display arm.** The ledger's compile-stage RED
  (KATs 1985–1993, 2000, 2001 at lex/parse/emit/link) is **RESOLVED** — all 14 eidos KATs now compile rc=0
  (verified this pass). *But verifying the full pipeline surfaced a deeper, confirmed, non-eidos regression:*
  the **C4-default sovereign COFF emitter drops module-`var` `.global` exports** (`objdump`: sovereign `.o`=0
  vs `.o.s`→`as`=1), so `resolver_hot.o`'s hand-asm fast path can't link — and since it is force-linked into
  every KAT, **the full `run_corpus` is link-red**, masked because bootstrap only runs compile-only
  `stage1_corpus`. Root cause + repro + fix direction: `DOCS/III-SOVEREIGN-EMIT-SYMBOL-REGRESSION.md`.
  Detection gate built (the teeth stage1_corpus lacked): `STDLIB/scripts/emit_symbol_consistency_gate.sh`
  (RED now; PASS on pure-function modules; not yet wired into `build_stdlib`). *The fix is deep emitter surgery
  on a freshly-landed sovereign path — it gets the crash-protocol (read the whole COFF-symbol path, write
  findings, verify in bytes), not a hasty edit.*
- **[ ] Step 6 — Fold `{BELOW, REFLECT}` into one primitive.** Order+involution over content-addressed nodes
  recurs in ≥3 engines `[gated 2140 (R²=id) / 2141]`. Make it one shared faculty — a substrate dedup, the
  clearest structural "greater than the sum." *Cost:* touches sealed sources → seal cascade; schedule after
  the sovereign frontier settles.
- **[≈ partial] Step 7 — Conscience + evergreen + TCB (Φ3 + Φ7).** **`DOCS/III-TCB.md` written** this pass
  (the irreducible TCB = CPU/microcode · OS loader · kernel32 · msvcrt, named + measured; §3 records the one
  open sovereignty gap). `run_conscience.sh` / `run_evergreen.sh` remain — and `run_evergreen` (self-build
  sovereignly) is **blocked** by the emitter regression (Step 5): programs needing cross-module data exports
  can't sovereign-build until that lands.
- **[◐ unblocked ] Step 8 — Weld the capstone `run_completion.sh` (§9).** The keystone blocker is GONE:
  the Step-5 emitter regression was fixed 2026-07-07 in its focused, protocol-gated session (root cause =
  export resolution through the .text-only label table; fix = `EXP_SEC` + `exp_ok` lockstep predicate;
  oracle: sovereign symtab == gcc-as reference on ALL 719 modules; fixpoint held; the consistency gate is
  now WIRED into `build_stdlib`). Remaining before the weld: `run_seed_sovereign.sh` (Step 1's exit gate,
  the long-pole ccsv campaign) — the capstone can only be green once that lands.

*Elective (defer):* Φ5 (XII→SVIR one-object) and Φ6 (lift NQ=16 → production). Hardening, not structure.

---

## 9. The completion invariant — the one gate that witnesses the whole closure

Realized when one meta-gate is green **and is itself sovereign-built:**

```
run_completion.sh   ⇐  ALL of:
  floor_closure_gate.sh        EXISTS✔  — I1: the trust floor is audit-closed        (built rev.2)
  run_grand_unification.sh     EXISTS   — the unified pipeline (Ω.a/d+b+F2+e+f+g+Ω7)
  run_seed_sovereign.sh        ABSENT   — Step 1: trust floor closed (ccsv builds iiis-0, byte-DDC)
  run_ddc.sh [+ seed axis]     EXISTS   — Step 3: DDC closed incl. author-diversity lineage
  run_conscience.sh            EXISTS   — Step 7 (built 2026-07-07): auto-discovers every run_*.sh (50
                                          lines: 9 spine + 41 discovered, excludes carry printed reasons);
                                          full-sweep run pending a quiet tree
  build_stdlib --check-corpus  EXISTS*  — Step 4: coverage ratchet all-zero  (*full gate, not run_corpus)
  run_zk_audit.sh              EXISTS✔  — Φ6 (built 2026-07-07): 49 gadgets, 9 claimers audited, 0
                                          violations; teeth proven (NBATCH 4→2 → rc=1)
  run_evergreen.sh             EXISTS   — Step 7 (built 2026-07-07): sovbuild every `fn main` under
                                          sovir+sovtc, witness=0 enforced, strict no-stubs scan (0 markers);
                                          full run pending (unblocked by the Step-5 emitter fix)
```

One of eight is absent (down from four — 2026-07-07 built `run_zk_audit` [green+teeth], `run_conscience`
and `run_evergreen` [authored, full sweeps scheduled]; only `run_seed_sovereign.sh` — the Step-1 ccsv
campaign's exit gate — remains). The **I2 structural gate** (no cycle / no dup-export) is *not* a
missing row — it is already folded into `build_stdlib` (the cartographer gate, §2.2), green this pass; only
I1 needed a dedicated gate because nothing checked floor-import closure before. **That table is the
orchestration gap in one screen.** The capstone is not a dashboard — it is a proof obligation, green iff the
loop closes. When it is green and sovereign-built, the only trusted thing left is the silicon and the libc
shim.

---

## 10. Calibrated confidence + the load-bearing assumption

**Confidence: HIGH** on the structure — now *measured*, not asserted. The floor closure (I1), the compiler's
cycle-free dependence on its substrate (I2), and the corrected counts are graph facts reproducible from the
one-liners in §3; the surplus claim is falsifiable (one capstone gate); and the central invariant has teeth.

**Confidence: MEDIUM** on the effort to close — Step 1 (trust floor) is a campaign weeks in and is the long
pole; Steps 4–7 are bounded but broad.

**The one assumption that, if wrong, most changes the design:** that **the SVIR ISA can express every
capability's execution while staying small enough to audit** (the 82-line + zero-import budget of ADR-1). The
whole trust architecture rests on this one narrow, *closed* waist. If XII→SVIR lowering, `CALL_INDIRECT`,
exact-real evaluation, or a future backend forces the ISA past one-sitting-auditable — or forces a floor
member to import upward — then "one auditable waist" fails and the design must fork to a **tiered anchor**: a
tiny core verifier plus separately-audited, individually-small extension verifiers, each still total,
decidable, and floor-closed. That is the fork to watch; today the budget holds (82 lines, `0x01–0x89`, 13
members with zero outward edges), and `floor_closure_gate.sh` is what makes "still holds" a fact you can
re-check in one second rather than a hope.

---

## 11. Revision note (what measurement changed — DOCUMENTED ≠ VERIFIED cuts both ways)

**Rev. 1 → 2 (measured the dependency graph):**
1. **"Arrows point inward" (one invariant) → two invariants (I1 floor-closure, I2 body).** The first draft's
   single nesting was falsified: the compiler legitimately depends *up* on 8 R5 faculties.
2. **Asserted floor closure → MEASURED + ENFORCED.** All 13 floor members' imports were extracted and
   classified (§3); `floor_closure_gate.sh` was built, run green, teeth proven (inject → rc=1, revert → rc=0).
3. **"~2,900 R5 modules" → 811 faculty modules** (the ~2,900 conflated the 1,776 corpus; corrected in §1).

**Rev. 2 → 3 (measured the *resolution* mechanism, and it refuted a rev. 2 claim):**
4. **Retracted: the "basename-collision hazard."** Rev. 2 called the 8 dups "the one uncontained failure mode"
   and proposed a `from`-ambiguity gate. Measurement showed both halves wrong: (a) imports resolve by symbol +
   content-addressed `closure_mhash` at link, not by filename order; (b) the colliding modules are
   export-disjoint, *and* `build_stdlib.sh:255-289` already fails the build on any duplicate `@export` or new
   cycle. The collisions are a cosmetic smell; the proposed gate would have been **redundant** — not built
   (capability-redundancy law). §3, §5, §6, §7 corrected.
5. **I2 upgraded "measured, open (3 cycles)" → "ENFORCED + green."** The cartographer gate in `build_stdlib`
   was run this pass: PASS on 1,181 nodes / 2,255 edges, 0 dup-exports, 0 un-allowlisted cycles. Both
   invariants now have teeth: I1 via a gate I added, I2 via a gate that already existed and I under-credited.
6. **Surplus reframed (rev. 2, retained):** "greater than the sum" is anchored on the *measured floor closure*,
   with `{BELOW,REFLECT}` a secondary dedup.

*The lesson the tree teaches, applied to its own architecture doc: a claim in a doc is evidence of intent, not
fact. Rev. 2 measured the graph and got the structure right; it asserted the resolution mechanism and got it
wrong. Rev. 3 measured the mechanism. Both gates are now green and reproducible from the one-liners herein.*

---

*Companions (this one orchestrates; those execute or evidence): `III-INTERIOR-LOGIC-ATLAS.md` (formal spine) ·
`III-REUNIFICATION-PLAN.md` (W0–W8) · `III-COMPLETION-PLAN.md` (Φ1–Φ7) · `III-ARCHITECTURE-AUDIT.md`
(one-law/many-kinds) · `III-SYSTEMS-MAP.md` (genuine-output census) · `III-SOVEREIGN-STACK-ARCHITECTURE.md`
(R2 detail). Enforcement: `STDLIB/sovir/floor_closure_gate.sh` (I1).*
