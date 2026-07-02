# III-APOTHEOSIS-PREP.md — priming & seeding the current tree for the overhaul
> **SUPERSEDED-BY: III-APOTHEOSIS.md** — this document is a HISTORICAL RECORD of its campaign era; the pointer target is the live doc (reunification W6, 2026-07-02).

**What this is.** The durable state machine (analogous to `CONVERGENCE-BUILD-LEDGER.md`)
for *preparing* the existing III tree so the 31 idealized modules of
`DOCS/III-APOTHEOSIS.md` integrate **bloat-free and as a breeze**. It is the architect
output of the prep pass + the canonical shared conventions every M2–M31 integration
will follow. It survives compaction; it is written to after every prep increment.

**The non-negotiable boundary.** The user is **independently implementing Module 1
(`numera/cad.iii`, the content-address collapse = migration 1)**. Everything touching
hashing / `cad` / `sha256` / `keccak256` / `mhash` / the 14× `sha256.c` retirement is
**M1's domain — DO NOT TOUCH.** `cad.iii` already exists (in progress). All prep here is
migrations 2–7 + the leaf clusters + the *non-M1* parts of M24.

**Standing discipline (same as Wave-4).** NIH; determinism-gated (FAIL=0 build + corpus
green + seal stable per increment); manual audit before any rebuild; no redundant
rebuilds; retire a C ancestor **only** once its `.iii` port passes the C's *exact* KAT
(Constitution-gated, witnessed, byte-equivalence-proven); never recklessly delete a file
I didn't create — verify consumer/forward-ref/KAT first. Auto-continue; never stop.

## Reading order / map (this doc is the integration state-machine — read top to bottom, or jump)

1. **The integration contract** — H1–H13 + the 7 migrations + the Move (what every M2–M31 satisfies).
2. **Grounded current-tree inventory** — the bloat/collision facts, scanned from source.
3. **Canonical shared conventions** — the 6 anti-bloat rules binding on every module + prep increment.
4. **Prep increments (P0–P5)** — the executed log: P1 `sid`→`crystal_deps` ✓, P2 HEXAD/src ✓,
   M24#1 14× sha256.c ✓, M24#5 POC kernel.iii (clear by absence).
5. **The H1–H13 defer-ledger (prose)** + **per-migration touches-map** — what each migration adjusts.
6. **Prep status** — the live continuing pipeline (delivered / remaining-prep / not-prep).
7. **THE INTEGRATION RESERVATION REGISTRY** — §A net-new reservations (grep-verified) · §B
   existing-module enhancement map (Edit-first) · §C corpus 700-block (verified clear) · §D
   critical-path build-order · §E pinned extern-signature map (+ `wh_publish` calibration).
8. **MIGRATION MECHANISM DESIGNS (mig 2–7)** — station-1 designs for every non-USER migration,
   incl. mig-3's inside-out boundary-migration cluster order. **Deep architect designs for mig 1–6:
   `DOCS/III-APOTHEOSIS-MIGRATIONS-ARCH.md`.**
9. **P4 — the machine-readable defer-ledger** — audit-computable integration progress.

The two genuinely net-new **module** specs live beside the other module specs in
`DOCS/CONVERGENCE-SPECS/`: **`uncertainty.spec.md`** (M4) and **`sovval.spec.md`** (M5). The
authoritative design vision is `DOCS/III-APOTHEOSIS.md` (M1–M31 + the Move + H1–H13 + the
consistency audit + the Premise Ledger); this prep doc operationalizes it for bloat-free landing.

---

## The integration contract (what every M2–M31 must satisfy)

**Harmony Invariants H1–H13** (the enmeshment seam-test; each a constitutional
meta-clause with a falsifier): H1 one value (SovVal at every boundary) · H2 one name
(`cad`) · H3 one serialization (192-byte Glyph) · H4 one engine (XII) · H5 one logic
(ternary Kleene) · H6 one kernel (CIC term) · H7 one conscience (clause+falsifier) ·
H8 one record (witness) · H9 one reversibility (SID inverse) · H10 nothing trusted
(re-checkable certificate) · H11 one category (lawful morphism) · H12 one determinism
(no float, equality-only, bit-identical) · H13 one language (no C save BOOT + `cic.c`).

**The seven implementation migrations (the critical path).** 1 `cad` collapse **[M1 —
USER]** · 2 SovVal-as-CIC-inductive (bricking/over-K become type errors) [M3/M5/M9/M13] ·
3 `@sovereign` boundary checker + boundary migration [M5/H1, the systemwide lift] ·
4 route all computation through XII (lower trit/gap/`sv_op`/kernel β·ι/`cg` to rules,
re-run `xii_critpairs`) [H4/M7] · 5 `omnia/sid`→`crystal_deps` rename + SID-inverse-in-witness
+ type-level `Compromise` [H9/M8] · 6 `run_charter()` + falsifier-per-clause as the build's
terminal gate [H7/M10] · 7 register every transform as a category morphism with
`cat_check_assoc` [H11/M12].

**The Move (per-operation contract every module implements).** Each operation is one
`sv_op`-shaped Sovereign Morphism: SovVal in → SovVal out; hexad-gated (H6), gap-aware
(H4/H5), witnessed (H8), content-addressed (H2), registered as a morphism (H11), returns
a re-checkable certificate (H10). "H1–H13 is the fold of all moves."

---

## Grounded current-tree inventory (scanned 2026-05-25)

| Fact | State | Implication for prep |
|---|---|---|
| `numera/cad.iii` | EXISTS (M1, in progress) | **off-limits** |
| `sha256.c` | 14 copies | M1/M24#1 — off-limits |
| `HEXAD/src/hexad_*.c` | present (5 files) | M24#2 retire → `omnia/hexad_*` (gated, exist) |
| `omnia/sid.iii` | navigator squatting on SID; refs: `sealed_channel`, `ripple`; build_stdlib:327; corpus 101–103 | M24#3 / migration-5 prereq — **clean non-M1 rename** |
| `omnia/either.iii`, `numera/checked.iii` | exist | M24#4 — **blocked** until `uncertainty.iii` (M4) exists |
| `uncertainty.iii`, `sovval.iii` | do NOT exist | M4/M5 net-new (implementation, not prep) |
| POC propositional `kernel.iii` | not found in STDLIB | M24#5 likely already clear |
| `NNN_neg_*` negative tests | exist (262–275) | migration-6 convention **has precedent** |
| `falsifier`/`@sovereign`/`run_charter` | unseeded (only cad.iii has "falsifier") | migrations 3/6 conventions to seed |

---

## Canonical shared conventions (THE SEED — every M2–M31 follows these)

Uniform conventions are the anti-bloat lever: no module reinvents the boundary, the
falsifier, the witness, the morphism registration. Codified here once:

1. **`@sovereign` boundary marker (H1/migration 3).** Every `@export` fn whose params
   cross a substrate boundary takes/returns Sovereign Values once M5 lands. Until then,
   new boundaries are written SovVal-ready (one `*u8`/`*u64` aggregate per the W2 idiom,
   never splayed scalars) so the migration is a type-swap, not a re-signature. The
   negative test that proves the checker fires is named **`NNN_neg_nonsovereign_<mod>.iii`**
   (extends the existing `NNN_neg_*` family).
2. **Falsifier-per-clause (H7/migration 6).** Every guarantee a module asserts is a
   constitutional clause carrying a paired **falsifier** — the exact input that turns it
   red. In `.iii`: the module's KAT already encodes positive arms; the falsifier is the
   **negative arm** (the `prove-the-negative` discipline, already standard). Migration 6
   fuses these into `run_charter()`; modules need only ensure each guarantee has a named
   negative KAT vector. No new per-module machinery.
3. **Witness-or-refuse (H8/H10/W20).** Every state transition emits a `wh_publish`
   fragment OR refuses; every result a consumer takes is re-checked against its
   certificate, never trusted. (Already the Wave-4 standard — carries forward unchanged.)
4. **Content-address via `cad` (H2).** Once M1 lands, every hash goes through `cad`
   (`cad_compute`/`cad_compose`/`cad_oneshot(suite,..)` — the real `cad.iii` API, §E). New modules call `cad`, never raw
   Keccak/SHA. (Repointing existing call sites = M1's job; new code is `cad`-native.)
5. **Morphism registration (H11/migration 7).** Every transform registers via
   `cat_add_morphism` and passes `cat_check_assoc`. New transform modules expose their op
   as a registered morphism from day one.
6. **Determinism (H12).** No float; `==`/`!=` only on signed; `[u64;N*4]` id-arrays +
   byte-pointer access; module-scope scratch; the full iiis trap catalog. (Wave-4 standard.)

These six are **binding on every prep increment and every M2–M31 module.** A new module
that violates one has failed by definition.

---

## Prep increments (ordered safest-first; each non-M1, each verification-gated)

- **P0 — DONE.** Wave-4 closed at the 9-module boundary (656–664 verified); pivot
  recorded in the ledger; this prep doc created; bloat inventory grounded; conventions
  codified above.
- **P1 — `omnia/sid` → `omnia/crystal_deps` collision clear (M24#3 / migration-5 prereq).**
  Rename file + `module omnia_sid`→`omnia_crystal_deps`; build_stdlib path `omnia/sid`→
  `omnia/crystal_deps`; repoint `sealed_channel.iii` + `ripple.iii` `from "sid.iii"`→
  `from "crystal_deps.iii"`; rename corpus 101–103 producers if they reference the path.
  Symbols stay `sid_*` (link-by-symbol; the *file/module* collision is what M8 needs
  cleared) UNLESS M8 will reuse `sid_*` symbol names — verify against the real
  `COMPILER/BOOT/sid.iii` / `numera/reversible.iii` symbol set first; rename symbols to
  `cd_*` only if they collide. **Gate:** FAIL=0 + corpus 101–103 green + seal stable.
  **Non-M1:** sid is dependency-navigation, unrelated to hashing.
  **EXECUTED (2026-05-25):** evidence-swept (refs = corpus 101-103 + ripple.iii +
  build_stdlib:327; sealed_channel was a false match — its `sid_*` are session-id locals).
  No symbol collision (navigator `sid_dependency_graph/...` vs compiler-SID `sid_load_u8/...`)
  -> file+module clarity rename, `sid_*` symbols kept (link-stable). Did: `mv sid.iii
  crystal_deps.iii`; `module omnia_sid`->`omnia_crystal_deps`; header retitled + provenance
  note; build_stdlib path; `from "sid.iii"`->`from "crystal_deps.iii"` in ripple + 101-103;
  rm stale `omnia_sid.iii.o`. compile-only crystal_deps + ripple PASS. **Gate `bs14p6u15`:
  build FAIL=0, `omnia/crystal_deps` compiled; corpus verifying.**
- **P2 — `HEXAD/src/hexad_*.c` retirement (M24#2).** Confirm `omnia/hexad_*` pass the
  hexad KAT + 144-reach check (they are corpus-gated). Then retire the 5 C ancestors as a
  witnessed amendment. **Gate:** the byte-equivalence/KAT proof + corpus green. **Care:**
  C files I didn't create — verify no live consumer references `HEXAD/src` before removal.
  **EXECUTED (2026-05-25):** investigated — HEXAD/src/*.c compiled by NO build (zero
  `.sh`/Makefile refs); `hexad_check.c` (BOOT) references HEXAD/src only in **comments**
  (not `#include`s); `omnia/hexad_*` ports are corpus-gated (P1 gate FAIL=0). Retired the
  6 superseded `hexad_*.c` (algebra/dynamic/epistemic/mobius/pfs/reach); kept
  `types_bridge.c` + `HEXAD/include/iii/hexad.h` (not the M24#2 target). **Build-invisible
  + seal-stable** (HEXAD/src in neither the compiler nor the `.iii` archive) → no re-gate
  (Directive 7); the residual `hexad_check.c/.h` comment-refs are harmless historical
  provenance. Witnessed here (the doc-form amendment). H13 advanced one step.
- **M24#1 — the 14x sha256.c + sha256_local.c retirement: DONE (2026-05-25, post-M1).**
  Unblocked by M1 (`numera/cad.iii` complete + corpus-proven `665_cad=99`). Proof gate run
  FIRST: `verify_sha256_dedup.sh` (§4.15) confirmed all 15 copies **byte-identical, drift=0**;
  cad/sha256.iii supersede (corpus 02/15 + 665); build-invisible (no build compiles them).
  Retired all 15 non-BOOT `sha256.c`/`sha256_local.c` (incl. the LEXICON canonical);
  remaining=0; **BOOT trust root + `cad.iii` untouched**. **Repurposed the §4.15 dedup gate
  into the maintained M24#1 invariant** — `verify_sha256_dedup.sh` now FAILs if any C sha256
  copy reappears (gate run: exit 0, "M24#1 holds"). NOT M1-disruptive (cad.iii is M1's
  artifact, untouched; this is the M24 follow-through cad's completion enabled).
  Per-subsystem `crypto.c` left alone (full crypto, NOT cad-superseded -> M26-domain).
- **M24#5 — the POC propositional `kernel.iii` retirement: ALREADY SATISFIED (2026-05-25).**
  Glob `**/kernel.iii` → **zero files tree-wide**: the POC's propositional shadow of the CIC
  kernel does not exist in STDLIB or anywhere — nothing to retire. `TYPES/src/cic.c` (the full
  CIC kernel: 7 inductives incl. `Trit`/`Hexad`, 7 universes) is the trust root, KEPT as the
  explicit H13 carve-out (M9/M24); the `numera/kernel.iii` port is the honest long-term H13
  completion, not yet begun. M24#5 is **closed by absence** — no deletion, no risk. (Confirms
  the prep-inventory's "M24#5 likely already clear" → CONFIRMED tree-wide.)
- **P3 — spec-vapor prune (M24#7).** Enumerate `CONVERGENCE-SPECS/*.spec.md` with NO
  built `.iii`, NO consumer, NO forward-ref. **Exclude** the Wave-4 roster specs (they ARE
  forward-refs). Delete only true orphans. **Gate:** grep proves zero consumer/forward-ref
  per deletion.
- **P4 — defer-ledger scaffold (the introspection dividend).** A machine-readable
  `H1..H13 → {satisfied | deferred-on:<migration>}` table so integration progress is
  audit-computable ("Hk holds systemwide iff no admitted move defers an obligation Hk
  depends on"). Lives in this doc + optionally a `charter`-queryable form when M10 lands.
- **P5+ — scaffolds for the net-new modules (M4 uncertainty, M5 SovVal, the
  `@sovereign` checker).** Prep-scaffold only (struct skeletons + the
  `III_NONSOVEREIGN_BOUNDARY` negative-test stub), NOT full implementation — those are the
  overhaul proper. Staged after P1–P4 so the implementer drops bodies into ready slots.

**Execution note.** P1–P3 are byte/rename/delete-heavy on a gated tree **and edit
`build_stdlib.sh`** — which M1 is concurrently editing. To honor "without disrupting
module 1," P1–P3 are **sequenced to follow M1's build-script settling** (else a
concurrent `build_stdlib` edit could collide with M1). Each is then done with a manual
audit + a full build+corpus gate, one at a time, at the Wave-4 evidence standard. The
**safe-to-run-now** prep is the design/convention/analysis layer (P0, P4, this map) —
no gated-tree mutation, no `build_stdlib` edit, no M1 collision.

---

## The H1–H13 defer-ledger (introspection dividend — integration progress is audit-computable)

"`Hk` holds systemwide iff no admitted move defers an obligation `Hk` depends on."
Live state (from the consistency audit), so any turn can see exactly what remains:

| Invariant | Status today | Lands with |
|---|---|---|
| H1 one value | **deferred** | migration 3 (`@sovereign` checker + boundary migration) — the systemwide lift |
| H2 one name | **deferred** | migration 1 (`cad` collapse) — **M1, USER** |
| H3 one serialization | **deferred** | M25 Glyph + SovVal (M5); chains off H1 |
| H4 one engine | **deferred** | migration 4 (lower trit/gap/`sv_op`/kernel/`cg` to XII rules) |
| H5 one logic | **near-satisfied** | ternary (M2) exists; "ops as XII rules" = migration 4 |
| H6 one kernel | **deferred** | migration 2 (SovVal-as-CIC-inductive; bricking/over-K → type errors) |
| H7 one conscience | **deferred** | migration 6 (`run_charter()` + falsifier-per-clause terminal gate) |
| H8 one record | **near-satisfied** | witness (M6) live; frag-ids via `cad` chain off H2 (M1) |
| H9 one reversibility | **deferred** | migration 5 (SID inverse-in-witness + type-level `Compromise`) |
| H10 nothing trusted | **satisfied (strongest-grounded)** | M11/M14 source already enforces re-check |
| H11 one category | **deferred** | migration 7 (register every transform as a morphism + `cat_check_assoc`) |
| H12 one determinism | **satisfied** | the iiis/Wave-4 discipline (no float, eq-only, bit-identical) |
| H13 one language | **deferred (carve-out)** | M24 C retirement; `cic.c` + `COMPILER/BOOT` are accepted trust-root carve-outs |

**Reading:** the systemwide lift is **H1/migration 3** (boundary migration). H10/H12
are already real (the Wave-4 substrate proves them). M1 (H2) is the user's. Everything
else chains off migrations 2/3/4/5/6/7 — and the conventions above make each a type-swap
or registration, not a re-architecture.

## Per-migration "touches" map (which current modules each migration adjusts)

So the implementer integrates without re-discovery (bloat-free):

- **Mig 2 (SovVal-as-CIC-inductive)** [M3/M5/M9/M13]: `omnia/hexad_*` (reach → refinement),
  `numera/cic`/`proof_term` (the inductive), `cost_lattice` (over-K facet) — gated by M5
  existing. Touches no boundary signatures yet.
- **Mig 3 (`@sovereign` boundary)** [M5/H1]: the *largest* — every stdlib `@export`
  boundary, cluster by cluster, after the checker + `III_NONSOVEREIGN_BOUNDARY` neg-test
  land. The W2-aggregate idiom (already universal in Wave-4) means most boundaries are
  already SovVal-shaped (one ptr), so migration is a type-swap.
- **Mig 4 (route through XII)** [M7]: `omnia/xii_rewrite` (+`xii_critpairs` re-run each
  add), `hexad_algebra` trit ops, `uncertainty` gap arith, `sovval` `sv_op`, `cic` β·ι,
  `cg`. Additive rule families; the 117→117+N confluence check is the gate.
- **Mig 5 (SID)** [M8]: **P1 here** (`omnia/sid`→`crystal_deps` rename) + `numera/reversible`
  (inverse-in-witness) + `aether/witness_hook` (carry the inverse) + hexad `Compromise` tier.
- **Mig 6 (`run_charter`)** [M10]: `numera/constitution` (+`falsifier` field per clause),
  a new `run_charter()` fusing positive corpus + `NNN_neg_*` + drift + closure, `temporal_logic`
  + `sat` (bounded model check), `obs_*` (M28) + immune (M20) registered as clauses.
- **Mig 7 (one category)** [M12]: `numera/category` (`cat_add_morphism`/`cat_check_assoc`),
  and every transform module (`tp_*` M17, `cg`/compiler M18, crypto M26, federation M19)
  registers its op. coequalizer=egraph (M11), pullback=consensus (M19) implemented.

This map + the conventions = the integration is a lookup, not a redesign.

---

## Prep status (2026-05-25) — CONTINUING (live remaining-prep pipeline below)

**★ RECONCILIATION (2026-05-25) — M1/M4/M5 IMPLEMENTED by the USER; prep re-aligned to reality.**
The USER built the value layer: `cad.iii` (M1), `uncertainty.iii` (M4), `sovval.iii` (M5) — all
**compile clean** (`--compile-only` OK) and carry a full falsifier `*_selftest`. Their real APIs
**diverge from my design-ahead specs** (M4: 16-byte ucell + `u32` gids + **i64** values +
`unc_apply`; M5: 112-byte cell + **u64** hexad + `status`; M1: `cad_*` not `ca_*`). **Reconciled
this turn:** the two CONVERGENCE-SPECS are **banner-marked SUPERSEDED** (read the `.iii`); §A =
IMPLEMENTED; §E extern map = the real `cad_`/`unc_`/`sv_` signatures (file:line); P4 MIG = mig1
**PARTIAL** (cad built but the H2 collapse-to-one is incomplete — `wh_publish` still hashes via
keccak256), M24#4 (either/checked→uncertainty) now **UNBLOCKED**. **Lesson the USER set: check
completion BEFORE acting** — I had nearly re-`Write`-n `uncertainty.iii` *that already existed*.
The prep now **serves** the real value layer (correct externs for downstream M6–M31); it does not
re-implement what the USER owns.

**Delivered (primed + seeded):**
- The architect deliverable: integration contract (H1–H13 + 7 migrations + the Move),
  the **6 canonical anti-bloat conventions**, grounded bloat inventory, the **H1–H13
  defer-ledger**, the **per-migration touches-map**.
- **The Integration Reservation Registry** (above) — net-new prefixes/module-names
  **grep-verified free**, the existing-module **enhancement map** (the Edit-first
  anti-bloat rule: only M4/M5 are `Write`, everything else is enhance-in-place), the
  corpus **700-block** reserved (above the 666 high-water mark), the authoritative
  **critical-path build-order**, and the **pinned extern-signature map** (§E). Verification
  caught **3 mis-inferred prefixes** (`groebner gb_`, `symbolic_regression symreg_`,
  `synthesis_spec ss_`) — corrected in §B before they could mislead an integrator.
- **M4 station-1 spec** — `DOCS/CONVERGENCE-SPECS/uncertainty.spec.md` (the one typed gap;
  trap-18 designed-out; externs pinned; KATs with negative arms; delegation map for M24#4).
- **M5 station-1 spec** — `DOCS/CONVERGENCE-SPECS/sovval.spec.md` (the Sovereign Value +
  the authoritative 10-field `SovMorphism` contract; `Refused` leaves `out` unwritten;
  all four facet-externs pinned; KAT-2/KAT-3 the bricking/over-K falsifiers).
- **P1 sid→crystal_deps: VERIFIED.** **P2 HEXAD/src retirement: DONE.** **M24#1 14×
  sha256.c retirement: DONE** (gate exit 0). **M24#5 POC kernel.iii: ALREADY SATISFIED**
  (zero `kernel.iii` tree-wide; cic.c kept as the H13 trust-root carve-out).

**The live remaining-prep pipeline (safe, non-blocked, design-station — auto-continuing):**
1. **`@sovereign` boundary-checker spec** (mig 3, sema-side) + the `III_NONSOVEREIGN_BOUNDARY`
   negative-test design (corpus 711) — the mechanism of the systemwide lift (H1).
2. **`run_charter()` spec** (mig 6) — falsifier-per-clause fold + terminal-gate wiring
   (positive corpus + `NNN_neg_*` + drift + closure + temporal/OBSERVATORY/immune as clauses).
3. **The XII rule-family lowering protocol** (mig 4, the T4 *hardest* — confluence is not
   modular) — the add-a-rule-family + re-run-117+N-critpairs checklist that de-risks the
   single likeliest collapse point.
4. **P4 — the machine-readable defer-ledger** (the introspection dividend, audit-computable:
   "`Hk` holds iff no admitted move defers an obligation `Hk` depends on").

**Genuinely NOT prep — the overhaul proper (collaborative / the USER's domain, like M1):**
the `.iii` **bodies** of M4/M5/etc. (pipeline stations 2–5: implement→integrate→verify→gate);
the **irreducible `@sovereign` boundary migration** (every raw-scalar boundary → SovVal,
cluster by cluster — apotheosis T3′ "irreducible"); the **wholesale C-tree retirement** (M24,
per-module exact-KAT-heavy, coordinated, irreversible — no git); **M1's hash domain** (cad).
The two station-1 specs above mean M4/M5 implementation is now drop-the-bodies-into-ready-slots
— the breeze the task asked for; the pipeline above keeps priming the rest, not halting.

---

# THE INTEGRATION RESERVATION REGISTRY (the keystone anti-collision artifact)

**Why this exists.** The #1 iiis integration failure is the **linker-global const collision**
(trap #2: a module-scope `const NAME` emits global `L_NAME`), and with 31 modules declaring
many consts each, a collision is near-certain without a reserved namespace. The #2 failure is
a **wrong extern signature** (the keccak256_oneshot / wh_publish / cap_verify_rights / ed25519
arg-order lesson — §VII). This registry pre-empts both: every net-new prefix/module-name is
**grep-verified free against the live tree (2026-05-25)**, every corpus number is reserved out
of collision range, and every extern a net-new module calls is **pinned to its real provider's
exact signature, ahead of implementation.** With this, each module is a *drop-in*, not a
rediscovery — the breeze the task demands.

## A · The two net-new modules — NOW IMPLEMENTED by the USER (2026-05-25)

Only **two** core stdlib modules in the apotheosis were genuinely net-new (everything else
enhances an existing file — see §B). The namespaces I reserved (grep-verified free) the USER then
**implemented** — `unc_`/`sv_` are now USED, not reserved:

| Module | File | Prefix | Module decl | State | Authority |
|---|---|---|---|---|---|
| **M4 Uncertainty** | `numera/uncertainty.iii` | `unc_` | `numera_uncertainty` | **IMPLEMENTED** (compiles; `unc_selftest`) | the `.iii` (spec superseded) |
| **M5 Sovereign Value** | `omnia/sovval.iii` | `sv_` | `omnia_sovval` | **IMPLEMENTED** (compiles; `sv_selftest`; USER calls it "in progress") | the `.iii` (spec superseded) |

Spec files (`DOCS/CONVERGENCE-SPECS/uncertainty.spec.md`, `…/sovval.spec.md`) exist but are
**SUPERSEDED BY THE IMPLEMENTATIONS** (banner at each spec's top): the design-ahead refined into
cleaner real code — 16-byte ucell + `u32` gids + **i64** values + `unc_apply`; 112-byte SovVal +
**u64** hexad + `status` field. The real value-layer API is pinned in §E. **Do not re-implement
M4/M5 — they are the USER's**; this prep now *serves* them (correct externs for downstream M6–M31).

## B · Existing-module enhancements (KEEP the file + prefix — do NOT create a parallel module)

The anti-bloat core: the apotheosis is mostly *deepening existing organs in place*. Creating a
new file for any of these would be the exact drift M24 forbids. Enhance the named file under
its existing prefix:

| Apotheosis module | Enhance these existing file(s) | Prefix(es) | Net-new helper, if any |
|---|---|---|---|
| M1 Content-Address | `numera/cad.iii` ← `content_addr`(`ca_`)+`sanctus/mhash`(`mh_`)+`keccak256` | `ca_` / `mh_` | **M1/USER — off-limits** |
| M2 Ternary | `numera/trit.iii` **(BUILT** — moved out of hexad_algebra, which now externs the 9 ops**)** | `iii_trit_` | trit ops → XII rules (mig 4) |
| M3 Hexad | `hexad_algebra`/`hexad_reach`/`hexad_pfs`/`hexad_epistemic`/`hexad_mobius`/`hexad_dynamic` + `hexad.iii` (umbrella selftest) | `iii_hexad_` | — (reach→refinement, mig 2) |
| M6 Witness | `aether/witness_hook`/`numera/witness_spine`/`numera/algebraic_time` | `wh_` / `ws_` / `at_` | redaction (mig, additive) |
| M7 XII | `omnia/xii_rewrite`/`xii_critpairs`/`xii_term`/`xii_horizon`/`xii_curated_*` | `xii_` | rule families (mig 4) |
| M8 SID/Reversibility | `COMPILER/BOOT/sid.iii`(`sid_`)+`numera/reversible.iii`(`rev_`/`q_`)+`hexad_mobius` | `sid_`/`rev_` | `omnia/sid`→`crystal_deps` DONE (P1) |
| M9 Kernel | `TYPES/src/cic.c` **(C trust root — keep)** + `proof_carrying`/`proof_term`/`theorem_carrier` | `pc_`/`pt_`/`tc_` | `numera/kernel.iii` = long-term H13 |
| M10 Constitution | `numera/constitution.iii`(`cons_`)+`constitution_preserver` | `cons_` | **`cons_run_charter`** (mig 6, existing prefix) |
| M11 Decision | `numera/sat`/`smt`/`groebner`/`egraph` | `sat_`/`smt_`/`gb_`/`eg_` | egraph→XII strategy (mig 4) |
| M12 Category | `numera/category.iii` | `cat_` | morphism registration (mig 7) |
| M13 Cost | `numera/cost_lattice.iii`(`cl_`)+`cost_calculus` | `cl_` | cost = 4th SovVal facet (mig 2) |
| M14 Memo | `numera/memo_lattice.iii`(`ml_`)+`aether/memo_query` | `ml_` | — (H10 already exemplary) |
| M15 Synthesis | `numera/synthesis_spec`/`symbolic_regression` | `ss_`/`symreg_` | category-search (mig 7) |
| M16 Proof-carrying | `proof_carrying`/`proof_term`/`theorem_carrier`/`curry_howard` | `pc_`/`pt_`/`tc_`/`ch_` | — |
| M17 Representation | `omnia/tp_*.iii` (~30) + `omnia/babel`/`babel_intent` | `tp_`/`bbl_` | register as morphisms (mig 7) |
| M18 Compiler | `COMPILER/BOOT/*.iii` (lex/parse/ast/sema/cg_*/emit/link) **+ C trust root** | (BOOT) | `@sovereign` checker in `sema` (mig 3) |
| M19 Federation | `aether/hotstuff*`/`fed_*`/`sealed_channel`/`node_identity` | `hs_`/`fed_`/`ni_` | pullback=consensus (mig 7) |
| M20 Immune | `aether/quarantine`(`q_`)/`bone_marrow`/`basal_probe`/`context_awareness`/`triple_check` | `q_`/`bm_` | red→quarantine wiring (mig 6) |
| M21 Time | `numera/algebraic_time`(`at_`)+`tempora/{instant,deadline,duration,calendar,rfc3339}` | `at_`/`tmp_` | LTL clauses (mig 6) |
| M22 Memory | `memoria/{region,arena,arena_safe,region_safe}` | `region_`/`arena_` | — (H12 already real) |
| M23 Katabasis | `katabasis/{gate,gate_verdict,cycle_*,caps,seal,…}` | `katabasis_` | cycle-as-SovVal (mig 2/3) |
| M25 Verba | `verba/glyph_core`(`gv3_`)+`nl_lex`/`hip`+text codecs | `gv3_`/codec prefixes | Glyph = serialized SovVal |
| M26 Crypto | `numera/` crypto suite + retire `CRYPTO-AGILITY/src` → `.iii` registry (M24) | per-primitive | suite registry over `cad` |
| M27 Collections | `omnia/{map,set,list,vec,queue,lru,fold,zip,crystal,unify,…}` | per-container | crystal=sealed-error gap |
| M28 Observability | `omnia/obs_{log,metric,trace,observatory}` | `obs_` | families→clauses (mig 6) |
| M29 Sandbox | `omnia/sandbox_{ctor,exec,quota}` | `sandbox_` | — (cost facet, mig 2) |
| M30 Resolver | `omnia/{resolver,ai_resolve,pattern_table,codegen_dispatch,…}` | `resolver_`/`ai_` | category-search (mig 7) |
| M31 Net/IO | `aether/{net,tcp,inet,http*,fs,handle,idoc}` | `net_`/`http_`/`fs_`/`handle_` | membrane (mig 3) |

**The one-line rule for an integrator:** if the apotheosis module appears in §B, you are
*editing a file that exists* (Edit-first, M16/mandate-16); only M4 and M5 (§A) are `Write`.

## C · Corpus-number reservation map

**Actual placements (the USER's sequential 665+ convention — verified 2026-05-25):** `665_cad`
(M1) · `666_trit` (M2) · `668_uncertainty` (M4) · `669_sovval` (M5) — **all wired** in
`run_corpus.sh` (`=99`) + `build_stdlib.sh` MODULES (`numera/cad`, `numera/uncertainty`,
`omnia/sovval`). [667 unused.] The USER places apotheosis-module KATs **sequentially from 665**,
NOT in my earlier 700-block guess.

- **Next module / migration KATs → continue at 670+** (sequential, the USER's live convention).
  The integrator (USER, by hand — station 3) assigns the next number; do **not** assume a block.
- My earlier **700–799 block reservation is SUPERSEDED** by the sequential convention — overflow
  only. (Dense blocks below 665: 01–110 base, 262–275 negative arms, 300–372 XII, 373–377 ZK,
  378–397 convergence/specialize, 600–664 katabasis+Wave-4.)
- Each new corpus test **carries a negative arm** (Directive 3 / convention 2) and is wired
  EXPECTED=99 in `run_corpus.sh` by the integrator (station 3, by hand — never an agent).

**Registry verified (2026-05-25, evidence not assertion):** (a) Glob `corpus/7*.iii` → only
`70`–`79` exist, **zero `7xx`** — the 700-block is genuinely clear. (b) The `NNN_neg_*` family is
real (`262_neg_cap_flow` … `275_neg_type_alias_multihop`) — `711_neg_nonsovereign_boundary`
follows the live convention exactly. (c) All §B enhancement-target paths exist
(`omnia/xii_rewrite`, `xii_critpairs`, `hexad_mobius`; `numera/reversible`, `temporal_logic`).
(d) `corpus/250_multiline_fn.iii` exists as a trap-regression test, corroborating the §E
`wh_publish` calibration (multi-line fn is tested/supported; the catalog entry is conservative).
The trap-regression corpus (`248_signed_compare`, `249_u32_indexed_access`, `250_multiline_fn`,
`252_nested_comments`, `254_mut_param`, `256_local_arrays`) is the live home for any new
trap-class test a migration needs.

## D · Build-order = the authoritative seven-migration critical path

From the apotheosis consistency audit (verbatim) — "implementation order is the critical-path
order; the compiler (M18) is the apex where all seven converge":

| # | Migration | Difficulty (apotheosis T-rating) | Leverage already in the tree |
|---|---|---|---|
| 1 | `cad` collapse (14× sha256.c → one) **[M1/USER]** | mechanical | determinism gate makes the falsifier runnable; **sha256.c retired (M24#1 DONE)** |
| 2 | SovVal-as-CIC-inductive (bricking/over-K → type errors) | moderate | `cic.c` already types `Trit`/`Hexad` (7 inductives); `pt_`→`tc_verify` proven (652) |
| 3 | `@sovereign` boundary checker + boundary migration | checker **easy** / migration **irreducible** | `sema` D-gates exist; `TYPE-HEXAD-002` *is* a compile-time reach gate |
| 4 | route all computation through XII | **hardest (T4 — confluence not modular)** | `xii_rewrite`+`xii_critpairs` (117 pairs, MPO) exist; cheapest falsifier in the system |
| 5 | `sid`→`crystal_deps` + inverse-in-witness + type `Compromise` | **easy rename (DONE: P1)** | safe-rename pattern proven (ADR-027); `reversible.iii` built |
| 6 | `run_charter()` + falsifier-per-clause + temporal/OBSERVATORY/immune | formalization | build already runs a green/red fold; `temporal_logic`/`tl_eval` built |
| 7 | register every transform as a category morphism | moderate | `category.iii` (`cat_add_morphism`/`cat_check_assoc`) built + verified |

**Accepted carve-out (H13):** `cic.c` + `COMPILER/BOOT` stay C (the trust root); the
`numera/kernel.iii` port is the honest long-term H13 completion, never faked.
**The load-bearing pair (Premise Ledger T3/T4):** proofs must be *supplied* as closed terms
(no axiom/admit/hole), and confluence must be *re-proven* after every folded rule family
(re-run the 117+N critical pairs). Neither is dischargeable by design — only by the work.

## E · Pre-verified extern-signature map (§VII discipline, done AHEAD)

The **value-layer + facet extern map** — real signatures (file:line, refreshed 2026-05-25 against
the **now-implemented** M1/M4/M5). Downstream consumers (M6–M31, the migrations, any module
trading SovVals) copy these verbatim into their `extern` block — no rediscovery, no arg-order bug.
The cad/unc/sv blocks below are the **live value-layer API**; the facet providers
(`iii_hexad_*`, `cl_*`, `cat_*`, `wh_publish`, `cons_eval_predicate`) are what M4/M5 themselves call.

```
// content-address (M1 — IMPLEMENTED in cad.iii; the one content-address, suite-tagged):
fn cad_oneshot(suite: u32, msg: *u8, len: u64, out: *u8) -> i32                    // cad.iii:53 (suite-tagged oneshot)
fn cad_compute(producer: *u8, operation: *u8, input_commit: *u8, out: *u8) -> i32  // cad.iii:72
fn cad_compose(left: *u8, right: *u8, out: *u8) -> i32                             // cad.iii:89
fn cad_begin(suite: u32) -> i32  // + cad_domain(d,dlen)->i32, cad_payload(p,plen)->i32, cad_final(out32)->i32  cad.iii:120-169 (streaming)
fn cad_eq(a: *u8, b: *u8) -> u8                                                    // cad.iii:184  (+ cad_is_zero, cad_selftest)
// M4 typed gap — IMPLEMENTED in uncertainty.iii. ucell = 16B (tag@0 KNOWN0/GAP1, i64 body@8); a gap is a u32 gid:
fn unc_apply(op: u32, a: *u8, b: *u8, out: *u8) -> i32                             // uncertainty.iii:132 (op ADD0/SUB1/MUL2/DIV3)
fn unc_set_known(cell: *u8, v: i64) -> i32                                         // uncertainty.iii:72  (value domain is i64-SIGNED)
fn unc_set_gap(cell: *u8, gid: u32) -> i32                                         // uncertainty.iii:79
fn unc_is_gap(cell: *u8) -> u8   // :86    fn unc_known_val(cell: *u8) -> i64  // :91    fn unc_gap_id(cell: *u8) -> u32  // :95
fn unc_gap_root(kind: u8, reason: u32) -> u32                                      // uncertainty.iii:101 (kinds ESSENTIAL0/HOLE1/REDACTED2/DERIVED3)
fn unc_gap_derived(a0: u32, a1: u32, na: u8, reason: u32) -> u32                   // uncertainty.iii:115 (<=2 antecedent gids)
fn unc_root_causes(gid: u32, out_ids: *u32, cap: u32) -> u32  // :175    fn unc_well_formed(gid: u32) -> u8  // :198    fn unc_gap_addr(gid: u32, out: *u8) -> i32  // :221
// M5 Sovereign Value — IMPLEMENTED in sovval.iii. cell = 112B: payload(16, M4 ucell) | hexad u64@16 | status u64@24 | witness(32)@32 | cost u64[6]@64:
fn sv_make(payload_cell: *u8, hexad: u64, cost: *u64, out: *u8) -> i32             // sovval.iii:120 (Refuses non-reachable hexad / over-budget at the boundary)
fn sv_op(op: u32, a: *u8, b: *u8, out: *u8) -> i32                                 // sovval.iii:144 (op SV_ADD0/SV_MUL2; preserves Refused by closure)
fn sv_hexad(sv: *u8) -> u64  // :70   fn sv_is_refused(sv: *u8) -> u8  // :88   fn sv_cost_ptr(sv: *u8) -> *u64  // :92   fn sv_witness_ptr(sv: *u8) -> *u8  // :95
// hexad safety (M3):
fn iii_hexad_compose6(a: u16, b: u16) -> u16                                       // hexad_algebra.iii:88
fn iii_hexad_pack6(pillars_addr: u64) -> u16                                       // hexad_algebra.iii:45
fn iii_hexad_reachable(h: u16) -> u8                                               // hexad_reach.iii:76  (the stdlib reach gate; NOT the sema symbol iii_hexad_packed_admitted)
// witness (M6) — NOTE the true shape: 12 params over 5 source lines, returns u64 frag-idx (0xFFFF… on refuse):
fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8,
              out_commit: *u8, revtag: u8, phase: u8, pillar: u16,
              antecedents: *u8, n_ante: u32,
              payload: *u8, payload_len: u32,
              out_frag_id: *u8) -> u64                                             // witness_hook.iii:144
// cost lattice (M13):
fn cl_join(c: *u64, cp: *u64, out: *u64) -> i32                                    // cost_lattice.iii:222  (lub = composite cost)
fn cl_le_product(c: *u64, cp: *u64) -> u8                                          // cost_lattice.iii:254  (≤ for K-floor / over-budget Refused)
// category (M12; mig 7 registration):
fn cat_add_morphism(src: u32, dst: u32, op: *u8, out_id: *u8) -> u32               // category.iii:285
fn cat_check_assoc(f_slot: u32, g_slot: u32, h_slot: u32) -> u8                    // category.iii:369
// constitution (M10; mig 6 clause eval):
fn cons_eval_predicate(slot: u32, opv: *u8, ante_ids: *u8, n_ante: u32) -> u8      // constitution.iii:569
```

**Calibration finding (recorded, not hand-waved).** `wh_publish` proves a **multi-line,
12-parameter** signature compiles correctly in the current iiis (a wrong param-binding would
redden the witness_spine from-seed replay KAT, corpus 633 — it is green). So the trap-catalog
entries "multi-line fn → silent corruption" and "W2 ≤4 params" are **conservative defaults, not
absolutes**: one working witness primitive does not license abandoning them, but it does mean
calling a >4-param extern like `wh_publish` is safe. **Convention for NEW modules stays W2 +
single-line** (cheap safety; the param-spill family is real) — the W2 aggregate idiom (`req:
*u8`/`*u64`) is how M4/M5 expose their own ops.

## F · The station-3 integration recipe (insertion points + EXPECTED — for the by-hand integrator)

**✓ DONE for M4/M5 (2026-05-25):** the USER fully integrated both — `build_stdlib.sh` MODULES has
`numera/cad` + `numera/uncertainty` + `omnia/sovval`; `run_corpus.sh` has `[668_uncertainty]=99` +
`[669_sovval]=99`; the launchers call `unc_selftest`/`sv_selftest`. So the M4/M5 recipe below is
**historical** (the USER placed them sequentially at 668/669; MODULES dependency order is
link-resolved, so `uncertainty` listed before `cad` is fine). It stands as the **pattern for any
future net-new module.**

Station 3 (INTEGRATE) is **by hand, never an agent** (the sacred 2→3 boundary). For the two
net-new modules the recipe is mechanical — no rediscovery at integration time:

**`build_stdlib.sh` MODULES (dependency-ordered append; do NOT reorder existing entries — that
would drift the seal):**
- **`numera/uncertainty`** — insert after `numera/content_addr` (its only non-`identifier`
  dependency; both are deep value-layer). Must precede any consumer.
- **`omnia/sovval`** — insert after the **last-listed** of its dependencies:
  { `numera/uncertainty`, `omnia/hexad_algebra`, `omnia/hexad_reach`, `aether/witness_hook`,
  `numera/cost_lattice`, `numera/category`, `numera/content_addr` }. `sovval` calls all of them,
  so place it after whichever currently appears last in MODULES.

**`run_corpus.sh` EXPECTED entries:**
- `700_uncertainty` → **99** (`unc_selftest`; KAT-1..5 — incl. the `0·unknown→Known(0)`, `÷0→gap`,
  and `udiv64` bit-63 negative arms).
- `710_sovval` → **99** (`sv_selftest`; KAT-1..6 — incl. the non-reachable-hexad and over-K
  `Refused` negative arms).
- `711_neg_nonsovereign_boundary` → a **negative compile** test (compile MUST FAIL with
  `III_NONSOVEREIGN_BOUNDARY`), wired with the **expected-rejection** convention exactly as
  `262_neg_cap_flow` … `275_neg_type_alias_multihop` are wired — *not* exit=99. (Lands with the
  mig-3 sema checker.)

**Sequencing + gate (Directive 6/7, the evidence standard):** integrate **M4 first**, gate GREEN
(FAIL=0 build + `700`=99 read by hand + corpus regression + deterministic mhash); **then M5**
(which links `unc_*`); the mig-3 checker + `711` follow once the checker is built. One build +
green corpus per module suffices (no redundant rebuilds — the changes are additive new files).

---

# MIGRATION MECHANISM DESIGNS (mig 2–7 — every non-USER migration; mig 1 is M1/USER)

> **★ Deep version (2026-05-25):** the full current-state-investigated **architect designs** for
> migrations **1–6** (objective+falsifier · current state · architecture · cross-cutting · ADRs ·
> risks · ordered roadmap) now live in **`DOCS/III-APOTHEOSIS-MIGRATIONS-ARCH.md`**. The maps below
> are the lightweight index; the arch doc is the meticulous design (incl. mig2's `cic.c` Route-B
> decision, mig3's SovVal-type recognition gap, mig5's metal-vs-runtime two-domain finding).

The two net-new *modules* (M4/M5) have CONVERGENCE-SPEC files. **Six of the seven migrations**
(all but mig 1 — M1/USER's `cad` collapse) are *mechanisms/wirings* threaded through existing
files (`cic.c`, sema, `xii_rewrite`, `reversible`/`witness_hook`, `constitution`, `category`),
not new modules — so their station-1 designs live here, co-located with the registry +
touches-map an implementer reads. Each is grounded in the apotheosis depth passes (M5·D1/M18·D1, M7/T4,
M10·D1), carries its falsifier, and names the leverage that already exists.

## Migration 3 — the `@sovereign` boundary checker (sema-side; the systemwide lift, H1)

**Mechanism (extend, don't invent).** `sema` already runs a **compile-time hexad gate**:
`iii_hexad_packed_admitted(packed)` emits **`TYPE-HEXAD-002`** (hexad unrepresentable = the
`reach` rejection, M3), **`TYPE-HEXAD-001`** (hexad missing on a cycle), **`TYPE-IRPD-001`** (raw
privileged op outside an `irpd` region) — i.e. a D-gate that *already* rejects a value by a
type-level safety property (apotheosis M18·D1, grounded). `@sovereign` is **the same kind of
gate, widened from cycles to every boundary value.**

**Surface.** `@sovereign fn f(a: A) -> B` elaborates to `f : SovMorphism(A, B)` (the 10-field
record, see `sovval.spec.md`). `sema`'s new D-gate checks `A` and `B` are **SovVal-types at the
boundary** and emits **`III_NONSOVEREIGN_BOUNDARY`** if a raw `u64`/pointer crosses. Computation
*inside* `apply` is unconstrained — the contract attaches at the boundary and nowhere else
(*deeper, not wider*; apotheosis T9: scope forced by the *text* of H1, a predicate over values
*crossing a boundary*).

**The negative test (prove-the-negative — Directive 3 / convention 2).** `corpus
711_neg_nonsovereign_boundary.iii`: a `@sovereign fn` taking a raw `u64` at its boundary **MUST
fail to compile** with `III_NONSOVEREIGN_BOUNDARY` — the checker *fires*, not merely passes on a
good (all-SovVal) boundary. Extends the existing `NNN_neg_*` family (262–275). Plus a positive
arm: an all-SovVal `@sovereign fn` compiles clean.

**Staging (the irreducible part, apotheosis T3′).** Checker **first** (this one negative test),
then migrate stdlib boundaries **cluster by cluster** in touches-map order. The **W2-aggregate
idiom is the lever**: a boundary already shaped as one `req: *u8` ptr (universal in Wave-4)
migrates by a *type-swap* (`req: *u8` → `req: SovVal`), not a re-signature — most boundaries are
already SovVal-shaped. No design removes the per-boundary labor (T3′ "irreducible"), but the
checker makes every un-migrated boundary a *red compile*, so progress is mechanically visible.

**Falsifier.** A `@sovereign` boundary that admits a raw value (the checker didn't fire); a raw
boundary the checker passes; **the checker exempting itself** (apotheosis T5 — `is_sov_morphism`
is *itself* a `SovMorphism`, checked as an instance, never by self-consistency) → red.

**The concrete boundary-migration order (inside-out — no boundary migrates twice).** The lift is
irreducible (T3′), but its *order* is forced by dependency: migrate a cluster only after the
clusters it depends on are SovVal-native, so each `@export` boundary changes exactly once. Order
is **deepest-first** (mirrors the apotheosis module order + the critical path); W2-aggregate-shaped
boundaries (one `req:*u8` ptr — universal in Wave-4) migrate by a pure type-swap.
- **Wave A — born sovereign (no migration):** M4 `uncertainty`, M5 `sovval`, and the facet
  providers they call (`hexad_*`, `witness_hook`/`witness_spine`, `cost_lattice`, `cad`). These
  *define* the SovVal, so their boundaries are SovVal by construction.
- **Wave B — engine + kernel:** `xii_rewrite`, `cic` (the inductive, mig 2), `category` (mig 7),
  `proof_carrying`/`proof_term`/`theorem_carrier`. After mig 2/4/7 they evaluate/type/register
  SovVals natively.
- **Wave C — cognition oracles:** `sat`/`smt`/`groebner`/`egraph` — goal-in / **re-checkable
  certificate-out** becomes SovVal (H10 already real via `smt_check_model`).
- **Wave D — the body (highest-traffic boundaries):** `hotstuff`/`fed_*`/`sealed_channel` (ship
  SovVals), `quarantine`/`bone_marrow` (contain/regenerate), `algebraic_time`/`tempora` (clock),
  `memoria/*` (hold).
- **Wave E — the membrane (outermost, last):** `verba/glyph_core` (SovVal ⇄ self-verifying Glyph,
  M25), crypto (`value → certificate`), collections (hold), `obs_*`/`sandbox_*`/`resolver`, and
  `net`/`tcp`/`http*`/`fs` (external bytes ⇄ SovVal). Migrating these last means the entire
  interior is SovVal-native before the membrane converts — nothing crosses untyped.

**Progress is mechanically measured** (P4 applied to the lift): with the checker on, **remaining =
the count of `III_NONSOVEREIGN_BOUNDARY` compile errors** — a monotonically-decreasing number, not
a prose estimate. The lift is "done" when that count hits zero and the corpus + charter seal hold.

## Migration 4 — the XII rule-family lowering protocol (mig 4; the T4 *hardest*, likeliest collapse)

**Why a protocol.** Routing trit (M2) / gap (M4) / `sv_op` (M5) / kernel β·ι (M9) / cost (M13) /
transforms (M17) through XII is "the one engine" (H4) — but **confluence is not modular**: two
confluent rule sets can compose to one that is *not* (apotheosis T4). This is the single point
the whole design is likeliest to collapse, and `xii_critpairs` is **the cheapest falsifier in
the system to run** — so the discipline is a fixed, repeatable checklist, run per family.

**The per-family checklist (run for *each* family, never batched):**
1. Express each op as a `match`/`apply` XII rewrite rule over `xii_term` (the existing 40-rule
   form; M2's five trit ops are the smallest, total, and anchor the critical-pair machinery — do
   them first).
2. Assign each rule an **MPO weight that strictly decreases** (RHS < LHS in the MPO order =
   termination, `CRY-XII-TERM-001`). A rule that doesn't decrease is rejected here.
3. Add the family to `xii_rewrite`'s rule set.
4. **Re-run `xii_critpairs` over 117 + N critical pairs — ALL must converge** (Newman's lemma,
   `CRY-XII-CONF-001`). A divergent pair = **STOP**: the family is not confluent with the
   existing set; resolve (orient the rule, add a joining rule) before proceeding. This step is
   the gate.
5. Add a corpus test per rule (block **720–729**) + a confluence test exercising the new
   critical pairs.
6. **Curated-kernel promotion clause (M7/M10):** any curated machine-code kernel for the family
   must be **bit-identical to its rewrite normal form** (superopt sound by construction).

**Order (least-risky first):** trit (M2) → gap (M4) → cost (M13) → `sv_op` (M5) → kernel β·ι
(M9) → `cg`/transforms (M17/M18). Each step ends at a green 117+N critpairs run before the next.

**Leverage:** `xii_rewrite` (40 sealed rules, MPO) + `xii_critpairs` (117 pairs, 7 classes,
corpus 344/371) **exist and are proven**; the protocol re-uses them as the falsifier after each
family. **Honest (T4):** the re-proof is irreducible human/compute work — the protocol makes it
*mechanical* and the falsifier *runnable*, not *cheap*.

**Falsifier.** A rule family after which `xii_critpairs` reports a divergent pair; any term with
two distinct normal forms; a rule that fails to strictly decrease the MPO measure → red.

## Migration 6 — `run_charter()` (mig 6; the terminal-gate fold, H7)

**Mechanism (the three additions to `numera/constitution.iii`).** A clause is already a
first-class object (text + LTL + 11-opcode admissibility bytecode + witness rule + deps + epoch;
`cons_eval_predicate`; `CLAUSE_RATIFICATION` witness; `CONS_MAX_CLAUSES = 1024`). The apotheosis
M10·D1 gaps: **no paired falsifier per clause; the LTL field carried but unused; the constitution
is not the build's terminal gate.** Close them:
1. **Falsifier field per clause** — a *second* 11-opcode bytecode in the `clause_payload` schema;
   then **`HOLDS = cons_eval_predicate(verify, w) ∧ cons_eval_predicate(falsify, w_bad)`** — the
   clause must *catch* a constructed bad witness, not merely pass a good one (the prove-the-
   negative discipline made structural).
2. **`cons_run_charter()`** (existing `cons_` prefix — registry §B, no new reservation): runs
   every clause's verify ∧ falsify, **seals the verdict vector into one charter seal**, and
   **fuses the four legacy suites** — the positive corpus + the `NNN_neg_*` falsifiers + the
   drift gates + the closure meta-gate — into one terminal gate: **red unless all clauses hold,
   all falsifiers catch their bad case, and the seal equals golden** (DRIFT-driven reseal on
   intended change).
3. **LTL activation** — `numera/temporal_logic.iii` / `tl_eval` is **built** (corpus 644); compile
   each temporal clause to a **bounded model-checking query** (`tl_eval` / `sat`, M11) over the
   replayable `algebraic_time` chain (M21) — "the seal is *always* reproducible," "a red verdict
   *eventually* quarantines (M20)." Register the OBSERVATORY (M28) families and the immune (M20)
   red→quarantine→bone_marrow wiring **as clauses**.

**Every prior module's falsifier becomes a constitutional clause** (M1 no-digest-collision …
M9 ⊥-uninhabited; and the M4/M5 KAT falsifiers from the specs above). The Constitution becomes
the **union of all module falsifiers** — the system auditing itself. Corpus block **730–739**.

**The authoring loop (apotheosis "The Move · D1"):** because the falsifier is executable and
`run_charter` is the green/red light that ships the build, you **write the bad move first** — the
case that must be refused — and the same gate tells you the instant your operation correctly
turns it red, *and* whether adding it preserved confluence (mig 4) and reproduced the seal. There
is no gap between "passes my tests" and "is admissible."

**Leverage:** the build **already** runs a by-hand green/red fold (corpus + negative arms +
determinism mhash — the build ledger *is* the manual development surface); `run_charter`
mechanizes it. `temporal_logic`/`tl_eval` built.

**Falsifier (apotheosis M10·D1, verbatim spirit):** a guarantee with no clause; a clause with no
falsifier bytecode; a `falsify` predicate that passes on its bad witness; an LTL field that never
reaches the model checker; a `run_charter` green under injected corruption → red.

## Migration 2 — SovVal as a CIC inductive (mig 2; the H6 keystone — bricking/over-K become *type errors*)

**Mechanism (extend the kernel that already types safety).** `TYPES/src/cic.c` is a full CIC
kernel and **already has seven inductives including `Trit` and `Hexad`** (`Hexad` = one ctor of
arity 6 over `Trit`, at `Type₀`) with a schematic ι rule, β/ζ/δ/ι/η reduction, and a 7-level
predicative/impredicative universe (no `Type:Type`) — apotheosis M9·D1, grounded. So "make safety
a type" is **not a frontier; the kernel types it today.** Mig 2 binds the runtime to it.

**The two acts.** (a) **Bind `reach` to the `Hexad` inductive:** the runtime
`iii_hexad_packed_admitted` (the sema `TYPE-HEXAD-002` gate) becomes ι-reduction over the `Hexad`
inductive, so a non-reachable composition fails **`ι`-reduction**, not a bitmap lookup. (b) **Add
the SovVal dependent record** (or an 8th inductive) `SovVal { payload : Term, hexad : Hexad,
witness : FragId, cost : Cost }` plus a new **`Cost` inductive**, with **reachability (M3) and the
K-floor (M13) as Π-typed refinements** — so `sv_op`'s refusal of a bricking/over-K composition
becomes `iii_term_typecheck` returning **`TYPE_PROOF_007_*`**, i.e. the `SV_REFUSED_*` runtime
codes of `sovval.spec.md` become *type errors*. A **gap (M4) is an open term** (a metavariable)
the kernel already elaborates — "compute with holes" is the kernel's open-term elaboration, sound
by its own rules.

**Touches (touches-map, grounded).** `cic.c` (the inductive/refinement — **the C trust root, a
careful edit gated by the existing `cic` KATs + new `TYPE_PROOF_007` negative tests**);
`omnia/hexad_*` (`reach` → refinement); `numera/cost_lattice` (the `Cost` inductive + over-K);
`numera/proof_term` (the checked term). **Depends on M5** (`sovval`) existing.

**Leverage.** `cic.c` already types `Trit`/`Hexad` (the hard kernel work is done); the
`proof_term` → `tc_verify` machinery is proven (corpus 652). Difficulty: **moderate** (apotheosis
leverage table). **Honest (T3/H13):** `cic.c` stays the C trust root; this is a careful edit to
it, and the `numera/kernel.iii` port remains the honest long-term H13 completion — not faked.

**Falsifier.** A bricking or over-K `SovVal` that type-checks; a `Hexad` term whose six trits
compose to a non-reachable pattern yet is accepted; any `Type:Type` acceptance; a closed
inhabitant of ⊥ → red.

## Migration 5 — completion: SID inverse-in-witness + type-level `Compromise` (mig 5; H9)

**State.** The collision-clear (`omnia/sid` → `crystal_deps`) is **DONE (P1, verified)** — the
name `sid` is freed for the one concept. Two acts remain.

**Act (a) — inverse-in-witness (no extra log).** The compiler (`COMPILER/BOOT/sid.iii`, the real
Side-effect Inverse Derivation) *derives* an op's inverse at rewrite time; wire that derived
inverse **into each witness fragment** (M6) so **rollback = replaying the witness chain backward**
— the inverse is *derived, not stored*, so reversible time-travel costs no extra log.
`numera/reversible.iii`'s `(tag, a, b, c, d)` undo record **is a backward witness fragment**, and
its LIFO envelopes become **views over witness-chain segments**, not a separate undo log. **The
hook already exists:** `wh_publish`'s `revtag: u8` parameter (registry §E) is the M8 reversibility
tag — the carrier is in place; mig 5 populates it with the derived inverse.

**Act (b) — type-level `Compromise`.** Classify every op as exactly one of three (a constitutional
clause, M10): **reversible** (SID-derived inverse round-trips) · **typed-irreversible**
(`Compromise<LOW|MED>`, the tier the `COP_REVTAG_EQ` opcode reads — apotheosis M10·D1) ·
**unrepresentable** (`Compromise<HIGH>` = bricking, M3 `reach` forbids construction). Safety,
reversibility, and admission collapse into *one discipline*; `hexad_mobius`'s inverse **is** the
SID inverse projected onto the safety lattice (the M3 debt paid).

**Touches.** `numera/reversible.iii` (inverse-in-witness); `aether/witness_hook.iii` (carry the
inverse via `revtag`); `omnia/hexad_mobius`; `numera/constitution.iii` (the 3-way classification
clause). **Leverage:** the safe-rename pattern is proven (ADR-027, bug #7 `tc_init`→`tck_init`,
compiler-unreferenced, no seal drift); `reversible.iii` built (corpus 634); `wh_publish`'s
`revtag` carrier exists. Difficulty: **easy** (the rename, done) + moderate (the wiring).

**Falsifier.** A forward op whose derived inverse fails to round-trip; an irreversible op with no
`Compromise` tier; a `Compromise<HIGH>` value that constructs; the name `sid` bound to two
modules (cleared by P1) → red.

## Migration 7 — register every transform as a category morphism (mig 7; H11)

**Mechanism.** `numera/category.iii` is a real finite-category engine — `cat_add_morphism`,
`cat_check_assoc` (proves `(h∘g)∘f = h∘(g∘f)`), pullback/pushout/coequalizer, with **composition
= op-word concatenation** (`w(f∘g) = w(f) ‖ w(g)`, **associative by construction**; the tempting
`Keccak256(f_id ‖ g_id)` encodes the bracketing and is **not** associative — a real `category.iii`
bug, already fixed; M12·D1). Mig 7 **registers every transform as a morphism here**: `sv_op`
(M5), the `tp_*` pipeline (M17), compiler passes (M18), crypto primitives (M26), federation
ops (M19) — each via `cat_add_morphism`, each passing `cat_check_assoc`, each ratified as a
constitutional clause (mig 6) rather than assumed.

**Implement (not assert) the universal constructions.** **coequalizer = an `egraph` equality
class** (M11 — quotient by a congruence); **pullback = federation agreement** (M19 — two nodes'
morphisms over a shared object meet at their limit; consensus *is* a limit). These identifications
must be *implemented*, not merely stated. Morphism ids route through `cad` (M1) post-collapse, so
the very *shape* of computation is content-addressed and witnessed (M6).

**Touches.** `numera/category.iii` (the registry); every transform module (`tp_*`, `cg`/compiler,
crypto, federation) registers its op; `numera/egraph` (coequalizer); `aether/hotstuff`/`fed_*`
(pullback). **Leverage:** `category.iii` (`cat_add_morphism`/`cat_check_assoc`, word-concat
associativity) **built + verified** (corpus 620); `egraph` built (614); `hotstuff` built (383).
Difficulty: **moderate**.

**Falsifier.** A composite whose op-word ≠ `w(f) ‖ w(g)` (or a nested-hash composite re-encoding
bracketing); a composition breaking `cat_check_assoc`; an operation crossing a `@sovereign`
boundary (mig 3) that is not a lawful registered morphism; a claimed pullback/coequalizer that
isn't the universal one for its diagram → red.

---

# P4 — THE MACHINE-READABLE DEFER-LEDGER (audit-computable integration progress)

The prose defer-ledger above is human-readable; this is its **computable** form — the
introspection dividend (apotheosis "The Move · D1"). The theorem: **`Hk` holds systemwide iff no
admitted move defers an obligation `Hk` depends on**. So each invariant is a boolean over a
**migration-landed state vector**, and "what remains" is a *computation*, not prose. Once M10 /
`run_charter` lands this becomes a `cons_*`-queryable clause; until then it is hand-evaluable.

**The migration-landed state vector (live, 2026-05-25):**
```
// VALUE-LAYER MODULES built by the USER (2026-05-25; all compile + carry a *_selftest): M1 cad.iii,
// M4 uncertainty.iii (16B ucell / u32 gids / i64 / unc_apply), M5 sovval.iii (112B cell). These are
// MODULES, not migrations -- but they unblock the migrations below; the real API is in §A/§E.
MIG = {
  mig1_cad          : DONE          // H2 SYSTEMWIDE. cad.iii BUILT; M24#1 sha256 retired; content_addr RETIRED; category/seal/witness_hook + the 16 production keccak content-address callers ALL repointed to cad (byte-identical; 22->14 keccak callers, the 14 = 3 primitives + node_identity KDF + 9 KAT cross-checks + h2_charter); H2 FALSIFIER built (numera/h2_charter.iii: cad==backends clause + run_charter fold + corpus 674; scripts/verify_h2_one_address.sh GREEN). All 19 modules --compile-only OK; byte-identical => corpus + determinism-golden unaffected (USER station-4 corpus-run = formal seal)
  mig2_sovval_cic   : PENDING       // SovVal as CIC inductive (bricking/over-K -> type error)
  mig3_sovereign    : DESIGNED      // checker designed (above); boundary migration NOT begun
  mig4_xii_route    : PENDING       // lower trit/gap/sv_op/kernel/cost/cg to XII rules
  mig5_sid          : PARTIAL       // rename DONE [P1]; inverse-in-witness + type-Compromise PENDING
  mig6_run_charter  : PARTIAL       // USER built the KEYSTONE: cons_clause_holds = HOLDS=verify(good) AND falsify(bad) over the COP witness-VM (673_constitution_holds, the M10 gap-a paired-falsifier). h2_charter.iii = the H2-specific module falsifier (cad==backends; corpus 674), since H2 is a hash-byte-identity property the COP VM cannot express -> it is one of the union-of-all-module-falsifiers. Remaining: cons_run_charter() terminal fold + LTL fold
  mig7_morphisms    : PENDING       // register every transform via cat_add_morphism
  M24_ctree         : PARTIAL       // #1 sha256 DONE, #2 HEXAD DONE, #5 kernel N/A; #4 either/checked->uncertainty NOW UNBLOCKED (M4 exists, delegation pending); #6/wholesale PENDING
}
LANDED(m) := (MIG[m] == DONE)        // DESIGNED/PARTIAL/IN_PROGRESS/PENDING all evaluate false
```

**The invariant predicates (each `Hk` true iff its dependency set is all-LANDED):**
```
H1  one value          := LANDED(mig3)                      // boundary migration (the systemwide lift)
H2  one name           := LANDED(mig1)                      // [M1, USER]
H3  one serialization  := LANDED(mig1) & LANDED(mig3) & LANDED(M25_glyph)
H4  one engine         := LANDED(mig4)
H5  one logic          := LANDED(mig4)                      // NEAR: M2 ternary exists; "ops as XII rules" = mig4
H6  one kernel         := LANDED(mig2)                      // the type-error-for-bricking keystone
H7  one conscience     := LANDED(mig6)
H8  one record         := TRUE                              // NEAR-exact: witness live; frag-ids via cad chain off mig1
H9  one reversibility  := LANDED(mig5)                      // rename done; inverse-in-witness remains
H10 nothing trusted    := TRUE                              // already real in M11(smt_check_model)/M14 source
H11 one category       := LANDED(mig7)
H12 one determinism    := TRUE                              // the iiis/Wave-4 substrate proves it
H13 one language       := LANDED(M24_ctree)   carve_out{ cic.c, COMPILER/BOOT }
```

**Evaluated now:** `satisfied = { H8, H10, H12 }` (three real today); everything else is
`deferred-on` its named migration. **The deferral closure = the critical path**, and it empties
in exactly the apotheosis order: `mig1 → {H2, then H3/H6/H8-exact} ; mig2 → H6 ; mig3 → H1/H3 ;
mig4 → H4/H5 ; mig5 → H9 ; mig6 → H7 ; mig7 → H11 ; M24_ctree → H13`. When `MIG` is all-`DONE`
(save the `cic.c`+BOOT carve-out), all thirteen are `TRUE` — **one body, provably**.

**Highest-scrutiny rule (apotheosis T6 — where unsoundness hides).** A move's `defer` entry is
itself a move ("unfinished-op → admitted-anyway") and **must carry a discharged, self-falsifying
"safe meanwhile"** — a clause that catches its *own* violation. So every `PENDING`/`PARTIAL`/
`DESIGNED` row above is only honest while its safe-meanwhile falsifier is green (e.g. mig3's
"safe meanwhile" is *the checker reddens every un-migrated boundary*; mig2's is *the runtime
reach/cost gate still refuses bricking/over-K via `SV_REFUSED_*`*). A deferral whose safe-meanwhile
clause passes on its own bad case is the one place a green board can hide unsoundness — these are
the **highest-scrutiny** clauses, never the lowest.

**Reading.** This block is the single artifact a future turn (or `run_charter`) consults to know
exactly what remains and why each gap is safe meanwhile. It is **parasitic on the artifacts the
migrations already produce** (apotheosis T7) — it stores no truth of its own, only folds the
state vector. Update `MIG` as each migration lands; the `Hk` predicates recompute mechanically.

### H2 completion map (mig1's one remaining piece — the consumer-repoint to `cad`)

`mig1` is PARTIAL because `cad.iii` exists but the **collapse to one address (H2)** is not yet
systemwide. The repoint targets, scoped by grep (2026-05-25) — the USER's mig1-completion
checklist; the prep maps it, does not perform it:

- **`numera/content_addr.iii` — ✓ RETIRED + de-built (this turn, verified): all consumers + the
  603/607 corpus tests repointed to `cad`, `content_addr.iii`/`380`/probe deleted, build_stdlib +
  run_corpus cleaned, ZERO `ca_*` tree-wide. `category` morphism-id/identity-op + `seal` seal-compute
  also repointed → the H2 content-address consolidation is DONE.** Historical detail — it was
  **ALREADY folded** by the USER (`ca_*` are byte-identical `cad_*` delegations — `ca_compute`
  literally `return cad_compute`); the **3 external consumers are NOW repointed to `cad_*`-direct**
  (`memo_query`/`symbolic_regression`/`seal`, all `--compile-only` OK, byte-identical so the
  corpus + seal are unaffected), so `content_addr.iii` is **consumer-free except its own `380`
  selftest → retire-ready** (M24 follow-on — the USER's irreversible, build_stdlib + corpus-380 +
  delete decision; NOT done here). **Newly flagged H2 target:** `katabasis/seal.iii:48` computes the
  cycle seal via raw `sha256_oneshot` (a content-address outside cad) → `cad_oneshot(CAD_SUITE_SHA256)`
  (byte-identical) for full H2. Original (still accurate) detail: its `ca_compute`/`ca_compose`/
  `ca_branch_key`/`ca_eq` are superseded by the **drop-in** `cad_compute`/`cad_compose`/
  `cad_branch_key`/`cad_eq` (identical signatures — §E). **Exactly 3 external consumers** repoint
  (clean type-swap), then `content_addr.iii` retires (M24): `aether/memo_query.iii:139`
  (`ca_compute`), `numera/symbolic_regression.iii:1229` (`ca_compute`), `katabasis/seal.iii:22`
  (`ca_eq`).
- **~35 modules call `keccak256_*`/`Keccak256` directly — ✓ TRIAGE COMPLETE + H2 FALSIFIER BUILT (2026-05-25):**
  the 22-file keccak universe was classified; the **16 production content-address computers repointed to cad**
  (byte-identical; `22→14` callers, the 14 all justified: 3 primitives + `node_identity` KDF + 9 KAT cross-checks
  + the `h2_charter` falsifier). The H2 falsifier is built — **`numera/h2_charter.iii`** (runtime cad==backends
  clause + run_charter fold + canary negative arm; corpus `674_h2_charter`) + **`scripts/verify_h2_one_address.sh`**
  (structural gate, **GREEN**). The triage RULE (retained for reference): a caller
  computing a *content-address* (`witness_hook` frag_id [M6·D1], `category` morphism-id [M12·D1],
  …) repoints to `cad`; a caller using keccak as a *hash primitive* (a MAC, a commitment) **keeps**
  it; the address primitives themselves — `cad.iii`, `keccak256.iii`, `identifier.iii` — **keep**
  it (cad legitimately *wraps* keccak256: that IS the one path, not a second one).
  - **Primary keccak target — `aether/witness_hook.iii`: ✓ DONE by the USER (since M5, verified 2026-05-25).**
    `wh_compute_frag_id` + the chain-root now hash via **`cad_begin(WH_SUITE_KECCAK)`/`cad_payload`/
    `cad_final`** (witness_hook.iii:107/314 — byte-identical to keccak256, so the seal does NOT
    drift), and **M6 provable-forgetting redaction is built** (`wh_redact`/`wh_is_redacted`/
    `wh_redaction_commit`, :216–231 — the apotheosis M6 enhancement, landed). The **`at_time` trap
    was correctly avoided** — `at_time` is kept in the frag-id, so it stays an *ordering* id, not
    the reproducible address (M6·D1 bug #6). **Residual (minor):** `wh_redact`'s commitment (:221)
    + the selftest still call `keccak256_oneshot` directly — route through
    `cad_oneshot(WH_SUITE_KECCAK)` for full H2 (byte-identical), or accept as a deliberate
    raw-backend use. So the primary keccak content-address target is **DONE**; H2's remainder is the
    3 `ca_*` repoints above + the rest of the keccak triage.
  - **Next keccak target — `numera/category.iii` morphism-id: a trivial one-line swap.**
    `cat_compute_word_id` computes `Keccak256(src_id‖dst_id‖op_word)` via a **single**
    `keccak256_oneshot(&CATEGORY_IDPRE, 64+wbytes, out)` (category.iii:166 — params pre-concatenated
    into `CATEGORY_IDPRE` scratch, already spill-safe, so no streaming needed). H2 repoint = swap
    `keccak256_oneshot(...)` → **`cad_oneshot(SUITE_KECCAK, ...)`** (byte-identical; the KAT-4
    bit-for-bit morphism-id holds; op-word stays flat concat — the associative M12·D1 form). Since
    `category` is also **mig7's registry** (`cat_add_morphism`), this 1-line repoint naturally lands
    with mig7.
- **H2 holds** when no content-address is computed outside `cad`. *Falsifier:* a `Keccak256` of a
  `(producer, operation, input)` triple, or a Merkle link, computed without `cad` → red. When the
  3 clean repoints + the keccak triage land, set `MIG.mig1_cad = DONE` and H2 flips TRUE.

### M24#4 map (either/checked → uncertainty — unblocked by M4, near-trivial scope)

M4 (`uncertainty.iii`) exists, so M24#4 is **unblocked**. Caller scope (grep 2026-05-25): **`either`
has ZERO external consumers** (`either_u32_*` is called only inside `either.iii` itself);
**`checked` has exactly ONE** — `numera/checked_crystal.iii` calls `checked_u(32|64)_*`. Design
note that changes the move: the real M4 **ucell is 16 bytes (tag@0 + i64@8)**, *not* u64-packable,
so `either`/`checked`'s `u64`-packed return values **cannot hold a ucell** — "delegate to the gap"
is not a clean type-swap. **Given near-zero callers, RETIREMENT is cleaner than delegation:**
`either` → delete (no callers to migrate); `checked` → migrate the single `checked_crystal`
consumer to native/`unc_`, then delete. Either path is Constitution-gated + must keep the corpus
green (the M24 rule). **Low-disruption, low-priority** (not on the value-stack critical path) — a
clean cleanup whenever the USER does the M24 pass. *Falsifier:* deleting `either`/`checked` while a
consumer still links them → red (so the `checked_crystal` migration precedes the `checked` delete).

### mig2 map (SovVal-as-CIC-inductive — the keystone "catastrophe-unsayable"; concrete `cic.c` sites)

This is the migration that turns M5's runtime `status`-Refused into a **type error**. `TYPES/src/cic.c`
(the C trust root, kept per H13) already implements the kernel it builds on (sites verified
2026-05-25):
- **7 built-in inductives** Bool/Trit/Hexad/Phase/Tier/Epoch/List (`cic.c:21`), defined by an
  internal **schema** — `sort` + `ctor_count` + `ctor_arity[8]` (`cic.c:547-555`). **`Trit` and
  `Hexad` already exist** (= M2/M3 *inside the kernel*), so safety is already typed there.
- **ι-reduction** (match-on-constructor) is `cic.c:402-407` (`scur->ctor_ind == match_ind` → arm
  `[ctor_idx]` applied to `ctor_args`); `iii_tm_ctor` (`:160`) is the constructor factory.

The mig2 additions (apotheosis M9·D1, made concrete):
1. **Add a `Cost` inductive** — cic.c has Trit/Hexad but **no `Cost`** yet; it is the carrier for
   the K-floor refinement.
2. **Add `SovVal`** as the 8th inductive / dependent record — single ctor, args `payload:Term ·
   hexad:Hexad · witness:FragId · cost:Cost`.
3. **Bind reach to the `Hexad` inductive** so a non-reachable composition fails **ι-reduction**
   (`:402`) — not the runtime `iii_hexad_reachable` bitmap M5 uses today; the K-floor binds as a
   Π-typed obligation over `Cost`. Then `sv_op`'s `SV_STATUS_REFUSED` becomes `iii_term_typecheck`
   returning the bad-inductive code (`TYPE_PROOF_007_*`).
- **The honest hard part (Premise-Ledger T3):** cic.c's ctor schema is **simple — "all constructor
  arguments [treated as] of [the same] type" (`:555`)** — so the *dependent* refinements
  (`reach(hexad)=⊤`, `cost≤K`) need a **schema extension or a Π-encoding** over Hexad/Cost. That is
  the real mig2 labor, on the C trust root, gated by cic.c's existing KATs + new `TYPE_PROOF_007`
  negative tests. Until it lands, **M5's runtime `status`-Refused is the safe-meanwhile** (P4 mig2
  = PENDING; the value is sound now, just not yet type-level).

### mig5 map (SID inverse-in-witness — near-done; the rename ✓ landed in P1)

The collision-clear (`omnia/sid`→`crystal_deps`) is DONE (P1, verified). The remaining
inverse-in-witness wiring, made concrete against the real `numera/reversible.iii` (2026-05-25):
- `reversible.iii` today keeps a **separate undo log** — `REV_REC_TAG/A/B/C/D` (8192 records, each
  a `u32 tag + 4×u64 args`), 64 transaction slots — and **already witnesses** commit/rollback via
  `wh_publish` (it externs it, `:39`; tags `REV_WIT_TAG_COMMIT/ROLLBK`). The undo record is exactly
  `(tag,a,b,c,d)` = 36 bytes (apotheosis M8·D1: "the undo record IS a backward witness fragment").
- **The carrier already exists:** `wh_publish`'s `revtag: u8` is the M8 reversibility tag, and its
  `payload`/`payload_len` can carry the 36-byte undo record. mig5 = on each forward op emit a
  fragment whose payload is the derived-inverse undo record; **rollback walks the witness chain
  backward**, replaying each via `rev_invoke_undo(undo_fn,a,b,c,d)` — so `REV_REC_*` becomes a
  **view over the witness-chain segment**, not a separate store (inverse *recorded-in-chain*, not
  separately logged; no extra log).
- **Compromise tiers** (`COP_REVTAG_EQ` in constitution reads the revtag): an op is **reversible**
  (derived inverse round-trips) | **typed-irreversible** (`Compromise<LOW|MED>`) |
  **unrepresentable** (`Compromise<HIGH>` = bricking, M3 reach forbids construction);
  `hexad_mobius`'s inverse = the SID inverse on the safety lattice (the M3 debt paid).
- *Falsifier:* a chain-recorded inverse that fails to round-trip on backward replay; an irreversible
  op with no Compromise tier; the `sid` name bound to two modules (cleared by P1). **P4 mig5 =
  PARTIAL** (rename done; inverse-in-witness + tiers remain).

### mig6 map (run_charter — the terminal gate; concrete `constitution.iii` state)

`constitution.iii` (built, corpus 632) already has most of mig6's substrate (verified 2026-05-25):
- The **11-opcode admissibility VM** exists (`COP_TRUE`..`COP_HAS_ANTE`, `:67-77`); the
  `clause_payload` schema (`:32`) `clause_id | textual | ltl_len | ltl | …` **carries the LTL
  field**, and `CONS_LTL_OFF`/`_LEN`/`_BUF` (`:85-94`) store it; `cons_eval_predicate`/`cons_find`/
  `cons_init` are built.
- **The three gaps (= apotheosis M10·D1, grep-confirmed):** (a) **no falsifier field** (`falsif` →
  0 hits); (b) **no `cons_run_charter`** (0 hits); (c) the LTL field is **carried but not folded**
  into a gate. mig6 closes them: add a 2nd 11-opcode bytecode (the falsifier) to the
  `clause_payload` schema → `HOLDS = eval(verify,w) ∧ eval(falsify,w_bad)`; write
  **`cons_run_charter()`** (existing `cons_` prefix — no new reservation) fusing positive corpus +
  `NNN_neg_*` + drift + closure into one sealed verdict (the terminal gate); compile temporal
  clauses to `tl_eval`/`sat` over `algebraic_time` (`temporal_logic.iii` built, corpus 644).
- *Falsifier:* a clause with no falsifier bytecode; a `run_charter` green under injected
  corruption. **P4 mig6 = DESIGNED** (substrate present; falsifier + run_charter + LTL-fold remain).

### mig7 map (morphism registration — concrete `category.iii` state)

- `category.iii` (built, corpus 620) has `cat_add_morphism`/`cat_check_assoc` (§E). **Grep confirms
  `cat_add_morphism` is called by NOTHING outside `category.iii` itself** — so **zero transforms
  register today**; mig7 starts from zero.
- **First target = `sv_op`** (M5 explicitly defers its registration to mig7 — `sovval.iii` declares
  no `cat_` extern). Then `tp_*` (M17, ~30), crypto primitives (M26), federation ops (M19), and the
  compiler passes (M18) each register their op + pass `cat_check_assoc`. The op-word must be **flat
  concatenation `w(f)‖w(g)`** (associative by construction — M12·D1, the fixed-bug form), never a
  nested hash. coequalizer = egraph (M11) + pullback = consensus (M19) get *implemented*, not
  asserted.
- *Falsifier:* a composite whose op-word ≠ `w(f)‖w(g)`; a transform crossing a `@sovereign`
  boundary that isn't a registered morphism. **P4 mig7 = PENDING** (zero registrations yet).
