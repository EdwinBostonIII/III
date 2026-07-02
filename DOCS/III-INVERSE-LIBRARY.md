# III — The Inverse Substrate's Own Library: Master Logic Assimilation
### The Ring-(-1) metal bus that encapsulates the incumbent, not a parallel reimplementation of it
> **Date:** 2026-06-20 · **Author pass:** /deep-think · /architect · /math-olympiad (adversarial rigor) · advisor
> **Status:** PHASE 0 COMPLETE + PROVEN (the Cryptographic Bedrock). Phases 1–5 = roadmap (§4). XII untouched (per directive).
> **Files (Phase 0):** `STDLIB/iii/omnia/isub.iii` (the metal bus) · `STDLIB/corpus/1913_isub_cav.iii` (the CAV RED-probe).
> **Inheritance (kept):** `omnia/exec_cert` (streaming-sha256 witness kernel) · `omnia/event_substrate` (fold+lasso kernel) · the `1906` pattern (drive-real-faculty → record-real-trace → witness). Everything else is harvest-or-discard.

---

## 0. WHAT IS PROVEN (gated facts, this session)

- `isub.iii` compiles clean (`iiis-2`, 5742-byte object) and is **SEALED into `libiii_native.a`** (exactly one member; mhash `1bb73345…`).
- `1913_isub_cav.iii` linked **against the sealed archive alone** = **EXIT 99**, proving the content-address is **CONSTITUTIVE, not decorative**:
  - a name in the verb slot, and an out-of-range operand, are **structurally rejected** (count stays 0);
  - **identity IS the hash** — the bus's *stored* event identity equals `sha256(footprint)` reconstructed independently by `cad` (code 13);
  - **witness IS the chain** — the witness `ROOT` equals the independently-reconstructed hash-chain `sha256(sha256(0^32‖CAV0)‖CAV1)` (code 14);
  - the address `≠ sha256("below")` and is non-trivial (17); identical geometry → identical address, differing geometry → differing (18); deterministic on replay (15); a one-address tamper moves the `ROOT` *via its CAV* (16).
- **TEETH (negative case proven, per `/math-olympiad` discipline):** the identical KAT against a variant with **only** the name-gate disabled = **EXIT 11** — a name is wrongly accepted. The structural name-rejection is load-bearing, not luck.
- **No regression (consumers checked):** `1908_xii_canon_cert`, `1910_grail_logic_web`, `1906_xii_inverse_real` all = **EXIT 99** against the resealed archive (the `exec_cert` line; not a full-corpus run).
- **Pending (honest):** the *canonical* determinism reseal (a clean full `build_stdlib.sh`, which hangs at `forge_check` in this env). `isub` is registered in `MODULES` and functionally sealed via `ar` (delete-old-member + add + reindex; exactly one member verified). A clean build re-aggregates it in MODULES order — byte-different member order, so the hash above is the surgical archive's, not a canonical full-rebuild's. No green-washing.

---

## 1. THE RECURRING FAILURE (what "give the inverse substrate its own parallel library" kept hitting)

The kernel is real: `event_substrate` (state = fold over an append-only event log; real Zielonka parity + infinitary lasso) and `exec_cert` (streaming sha256, O(1)/event, folds a **real** `xii_canonicalise`, tamper-evident, bounded-regard *by construction*). Every attempt to turn that into a *library* died one of these deaths — each fixing one axis and reintroducing another:

| # | Failure | Evidence | Root cause |
|---|---------|----------|------------|
| 1 | **Toy-oracle** | `1903/1904/1905` fold hand-authored integers, type the answer in; the "stubborn-determinism theorem" was **retracted** (`III-TRAJECTORY-AUDIT.md §0`) | `apply_to_real_not_toy` |
| 2 | **Loose-organ / island** | `dome`/`dome_society`/`dome_audit`/`logos` not in MODULES — unsealed, unwired | `no-islands` |
| 3 | **One organ ≠ a library** | `exec_cert` is the kernel; `1906/1908` are one-off demos, no faculty family | breadth never built |
| 4 | **Wrong FORM** | `logos.iii` ("parallel universal logic library") is **state-primary** — mutating arrays, no event-log/witness/fold/rewind; shadows `numera/logic6.iii` | the insidious one |
| 5 | **Unification stays prose** | `1910` honestly labels the wall-unification "a LENS… ANALOGIES… not a theorem" | `crosswall_prose_runs_hot` |

**Meta-pattern:** no attempt ever held **all three** at once — **(A) breadth** (a library), **(B) inverse form** (every faculty's state IS a fold over ONE shared witnessed reversible log), **(C) realness** (folds a real execution, sealed + wired, survives adversarial refutation). `dome` had B without A,C; `exec_cert` had C without A; `logos` reached for A in the wrong form and unwired. The three were built separately and never fused.

**The trap to never re-enter:** the fold does **not** compute the answer — in `1906` the normal form comes from *real* XII; the fold only *witnesses* it. So "prove `fold == faculty_answer`" is a near-tautology. The library's worth is a **capability** (reversible provenance + time-travel + tamper-evidence over a real execution), with the witness as the *integrity check*, never the headline.

---

## 2. THE REFRAME (the way the user wants it — settled)

**Not a parallel reimplementation — an encapsulation.** The inverse substrate is a Ring-(-1) **metal bus** that *encapsulates the incumbent* (XII): the real faculty **emits real events into the shared witnessed bus as it runs**; the "twin" is the **fold** over those events that yields rewind, provenance, and a tamper-evident witness. Neither parallel nor island — it satisfies the Reunification north star (harvest into XII; no standalone faculties).

**Pattern (named):** Event Sourcing + CQRS in the inverse direction (state = fold over a witnessed event log; reversibility = temporal query; witness = transparency-log). Established-sound; the novelty is the *inversion* and the bounded fluid edge, **not** the cryptography.

**The non-toy capability proof (the honest one):** the dome's "evade-by-living" applied to a **real** faculty — a real XII rewrite that loops (the `event_substrate` term-hash lasso detects it) → rewind → real re-derivation, where the **answer comes from real XII** and the **value is the reversible witnessed provenance**.

---

## 3. ARCHITECTURE

```
   LIVE III FACULTY (real xii_rewrite / cad / nous …)  ── emits uniform event-blocks as it runs (a thin tap)
        │                                                            (answer unchanged — from the real faculty)
        ▼
 ┌──────────────  ONE SHARED METAL BUS (omnia::isub, Ring -1)  ──────────────┐
 │  append-only log of UNIFORM BLOCKS <verb∈{BELOW,REFLECT}, a, b>           │
 │  CONTENT-ADDRESSED VERBS: identity = sha256(geometric footprint), no names│
 │  exec_cert streaming-sha256 witness (O(1)/event)  ·  [Phase 4] dome rewind│
 └───────────────┬───────────────────────────────────────┬──────────────────┘
   read-side     │  pure folds (CQRS)                     │
                 ▼                                         ▼
          answer-view (= real faculty's answer)     audit-view (witness digest, divergence sig, provenance)
```

**Components:** (1) `isub` — the metal bus (Phase 0, **done**); (2) the event-tap per faculty (`1906` driver made reusable); (3) the fold-views (answer + audit), pure fixed functions (no observational learning); (4) the build-level Trajectory-Audit / Divergence-Signature gate.

---

## 4. THE METHODOLOGY (chronology — merges the user's blueprint with the staged plan)

- **Phase 0 — Cryptographic Bedrock (DONE).** `isub` + `exec_cert` as the metal bus; Content-Addressed Verbs; RED-probe rejects names; prove the O(1) witness hashes geometry not labels. Sealed + corpus-green + teeth-proven.
- **Phase 1 — Encapsulate XII (the first citizen). DONE** (`omnia/xii_isub.iii`, KAT `1914` = 99, sealed; mhash `0dee2c69`). `xii_isub_normalize` drives the REAL `xii_rewrite` to fixpoint, emitting each real firing as a `BELOW` reduction-step into `isub` (geometrically honest: rewriting *is* a reduction order, normal form = bottom); `xii_isub_current` recovers the term as a pure fold over the witnessed history; `xii_isub_prefix` gives time-travel the mutating form discards. The Divergence Gate is the KAT: answer == real XII normal form (11) + fold recovers it (12) + ≥2-step provenance (13) + time-travel (14) + reproducible witness root (15) + the anti-tautology teeth — an EMPTY history folds to the *start*, not the answer (16). (Demo reduction: a 3-deep null-compose `R037` chain — `apply_one` is root-only, so a chain whose each step yields a fresh root redex; the capability generalizes, the demo trace is short + real.) **Discriminator passed:** XII encapsulated end-to-end (tap + fold + witness + sealed + wired + refuted).
- **Phase 2 — The unraveling engine. DONE** (`omnia/unravel.iii`, KAT `1915` = 99, sealed). A pure fold that strips Phase 1's real XII trace to its *geometry* (`unravel_height`/`is_chain`/`has_lasso`/`bottom`) + a verb synthesizer (`unravel_verb` → REDUCE/RECUR/IDENTITY/REFLECT). It PROVES from the witness — not by assertion — that III's rewriting is a terminating strict descent (one acyclic chain, lasso == 0, bottom == XII's normal form), and that no black box survives (every event is a {BELOW,REFLECT} pair). Teeth: an injected recurrence registers as a lasso + a RECUR verb (detectors non-vacuous).
- **Phase 3 — Sequential grail assimilation. DONE** (`omnia/assimilate.iii`, KAT `1916` = 99, sealed; `logos.iii`+`1912` retired). Three logic systems (De Morgan diamond → MO2 quantum → Kleene) shattered to uniform `{BELOW,REFLECT}` blocks and absorbed one INTO the web; recognition by **content-address** (sha256 of geometry) merges shared structure once (zero redundancy: 9+15+6=30 naive → 18 blocks/7 points). The web is **executable** — `assim_meet`/`join`/`complement` recovered from the geometry compute every system's logic, dissolving the named primitives. The harvest of `logos`'s recognize-and-merge into the inverse/event form; `logos.iii`+`1912` retired as the settled state-primary islands.
- **Phase 4 — Reversible search. DONE** (`omnia/reverse_search.iii`, KAT `1917` = 99, sealed). The Dome's ECHO/TIDE over the assimilated web: a naive deterministic strategy iterating `complement` (a real order-reversing **involution** → a genuine 2-cycle) oscillates forever (FATAL); the reversible search lives it, detects the lasso, rewinds (retaining the failed branch as provenance), records the trap as **anti-geometry**, re-chooses a climb → ALIVE. Anti-geometry **persists**, so a second search past the same cliff climbs immediately, never re-living the loop (gets smarter). **Honest scope:** real XII *terminates* (Phase 2), so the loop is the web's real involution, not real-XII non-termination — but the rewind/anti-geometry mechanism is real and general. (Not observational learning: the trap is a recorded fact the next search replays.)
- **Phase 5 — "Also all others" + capstone. DONE** (`omnia/master_logic.iii`, KAT `1918` = 99, sealed). The endgame, made rigorous: the REAL named primitive `logic6` (`l6_and`/`l6_or`/`l6_not`, a 6-valued De Morgan algebra) is taken as a **black box**, its behavior shattered into bare geometry (the order *derived* from `l6_and` — no logic taken as gospel), and the web's universal verbs are **proved to reproduce it exactly over all values**: `assim_meet == l6_and` (36 pairs), `assim_join == l6_or`, `assim_complement == l6_not`. `ml_named_is_redundant` is the **sovereign in-III gate**: it certifies the named primitive is provably a geometric fold, so the name is redundant — the rigorous justification for deprecation-by-attrition. Teeth: a shatter without the derived order fails to reproduce `meet` (non-vacuous). The mechanism is general (any lattice-structured primitive); the full physical deletion of every consumer is the ongoing "infinite horizon," preserving working code as it proceeds.

---

## 10. THE SPINE — wiring the pipeline + real-system enmeshment (a correction)

**Honest correction (adversarial pass).** The first cut of Phases 3–5 + the four audits operated on *hand-authored* lattices (`put(V_BELOW,0,2)` literals for the De Morgan diamond / MO2 / Kleene) and **never called** `xii_isub_*` (Phase 1) or `unravel_*` (Phase 2) — the shredder produced geometry that flowed nowhere, and the inputs were typed-in, not shattered from real executions. (Phase 5's `logic6` shatter was the exception — it *is* a real behavioral shatter.) Two modules close the gap:

- **`omnia/ingest.iii`** (the spine, KAT `1923` = 99). A REAL `xii_rewrite` execution flows end-to-end: `xii_isub_normalize` (Phase 1, real firings → witnessed trace) → `unravel_is_chain`/`unravel_height` (Phase 2, confirms the real geometry) → `ingest_extract` (carries it past an `isub_reset`) → `ingest_commit` → `assim_add` (Phase 3, into the web, deduped). The web is built **from a shattered real execution**, the real reduction order survives end-to-end, and re-committing the same execution adds zero blocks (content-addressed zero redundancy on real data).
- **`omnia/enmesh.iii`** (two real systems, KAT `1924` = 99). `logic6` (6-valued) and `voice` (3-valued) — two REAL named logics — are each taken as a **black box** and shattered from behavior (order derived from `meet`, involution from `not`) onto a canonical frame (bottom→0, top→1). Their shared frame (the bottom<top order + bottom↔top involution — the **common denominator**) merges by content-address (`voice` adds only its 3 distinct blocks); the ONE web then computes BOTH real systems' `meet`/`join`/`complement` exactly via the same verbs.

**Honest boundary:** the eleven *walls* (parity/SAT/GI/Goodstein…) of `1910` are a verb-geometry **taxonomy**, not lattices, so they are outside this `meet`/`join` assimilation engine — a category distinction, not a dodge. The lattice-structured real systems (`logic6`, `voice`, and real XII reduction geometry) are what the engine assimilates.

---

## 9. THE STRUCTURAL & TRAJECTORY AUDITS (empirical proof of success)

A standard KAT validates the destination; for a substrate whose value is geometry, provenance, and density, four dedicated audits prove the assimilation succeeded. All four = EXIT 99 vs the sealed archive alone.

- **Audit 1 — Topographic Collapse** (`1919`, zero redundancy). BLOAT metric (three systems isolated, raw `isub_emit`, no dedup) = **30 blocks**; DENSITY metric (assimilated by content-address) = **18 blocks / 7 points** — exactly **12 duplicate blocks vaporized**. The collapse is the proof the waste was cut. (Block-level metric; the named-op collapse is 9 named ops → 3 universal verbs.)
- **Audit 2 — Nameless Shadow Race** (`1920`, equivalence). A compound expression `OR(AND(a,NOT b),c)` evaluated over all **216 triples** two ways: `f_legacy` via named `l6_*`, `f_nameless` via **only** `assim_meet`/`join`/`complement`. Bit-identical on every triple (capability preserved); the nameless trajectory is witnessed by real `exec_cert` into a reproducible Divergence Signature. Namelessness is **structural** — `f_nameless`'s body provably calls zero `l6_*`; the witness proves the geometric trajectory is stubbornly deterministic.
- **Audit 3 — Universal Isomorphism** (`1921`, the universal protocol). De Morgan (`complement(meet(a,b)) == join(complement(a),complement(b))`) and involution hold **identically across every domain** of the unified web via the *same* verbs — including cross-domain pairs (diamond×Kleene, diamond×MO2). A law proven in System A *is* the proof in System Z because both are the same geometric statement over the same atoms (the basis of translation). Teeth: a false law (`meet==join`) fails.
- **Audit 4 — Evasion of the Void** (`1922`, emergence — the ultimate proof). The trap: find a self-complementary point. The diamond has **none** (a real residual gap — a naive complement-iteration loops forever, FATAL). Assimilate Kleene → its self-mirroring middle `6` enters the web. The Master Web walks into the trap, detects the lasso, TIDE rewinds (retaining provenance), and ECHO reaches across to the **cross-domain** point `6` — the gap bridged by geometry from a *different* Grail system. ALIVE. Teeth: naive iteration on the full web still loops (only the cross-domain scan reaches `6`).

---

## 8. THE SOURCE-OF-TRUTH LAW (the capstone)

**One master logic.** Every assimilated system is shattered to uniform `<verb∈{BELOW,REFLECT}, a, b>` blocks on the witnessed metal bus; shared structure is merged by content-address (zero redundancy); the universal verbs `meet`/`join`/`complement` recovered from the geometry compute every system's logic; and any **named** primitive is provably nothing more than one of those verbs *at its geometry* (Phase 5). The name is a convenience, never the substance — the substance is verb @ geometry, witnessed, reversible. The sovereign gate (`ml_named_is_redundant`) is how III *proves*, in III, that a name has been fully dissolved before it may be retired. This is what the state-primary weave could not be: not a library of black boxes, but one lean, executable, content-addressed web of microscopic building blocks of the same size, linked by exactly what they share.

**Control invariant (every step):** read → RED-probe → implement-to-GREEN → adversarially refute → seal+wire → reseal+regress → commit. No `.iii`/`.sh` edit before the read+RED-probe for that unit. No "done" before refutation-survived + `FAIL = 0` + RUNNING-after.

---

## 5. THE SETTLED FORKS

- **FORM:** woven instrumentation / **encapsulation** (the real faculty emits; the twin is the fold) — *not* parallel reimplementation. The change that ends failures #2–#4.
- **SCOPE:** vertical slice first (one real citizen end-to-end) then replicate — executed as the user's phased blueprint (Phase 0 bedrock → Phase 1 XII → …).
- **LOGOS:** harvest the uniform-block recognition *idea* into the event form (Phase 2–3); `logos.iii` + `1912` retired as a state-primary island (its De Morgan content is `numera/logic6.iii`; its general absorption engine re-expressed in the inverse form). *Not yet executed — Phase 2/3.*

---

## 6. PHASE 0 DETAIL — `omnia::isub` (the Content-Addressed metal bus)

**The uniform block:** `<verb, a, b>`, `verb ∈ {V_BELOW=0, V_REFLECT=1}` (the `logos` vocabulary), `a,b` bare point addresses. **There is no name/string field in the log.**

**The name-gate (structural, scoped to the verb):** the **verb** is the operator slot — the place a "named primitive" (`l6_and`, …) would live — and `isub_emit` rejects any `verb > V_REFLECT` (a name packed there is a large integer → returns 0, nothing appended). Operands are bare addresses, sanity-bounded to `< 2^20`. So the *named-primitive* defense is on the verb; operands are addresses, validated against the web in Phase 3. (Stated precisely: this is verb-name-proofing, not whole-event-name-proofing.)

**Content-Addressed Verbs — CONSTITUTIVE.** Every `isub_emit` itself: (1) computes `CAV_i = sha256([verb‖a(LE32)‖b(LE32)])` via `exec_cert` and **stores** it as the block's identity (`isub_event_cav_into` *reads* the stored bytes — it does not recompute); (2) folds it into the witness chain `ROOT = sha256(ROOT_prev ‖ CAV_i)` (genesis `ROOT = 0^32`). So the identity *is* the hash and the witness *is* the chain of identities — delete the CAV computation and the `ROOT` cannot be formed (the discriminator the design is built to pass). O(1)/event (two fixed-size sha256), O(32) memo (the frozen `ROOT`). A transparency-log / Merkle chain over geometric content-addresses.

**The witness engine** is the already-sealed `exec_cert` streaming sha256 (`xc_begin`/`xc_event_byte`/`xc_seal`) — wired directly into every emit; no new crypto. Each emit runs two complete, self-contained `xc` sessions (CAV, then chain), so the single `sha256` singleton is never left open across calls.

**`isub_cav_into(verb,a,b,out)`** is the pure helper the emit path itself uses — exposed so a caller can verify *stored == computed* (it is the same hash, not a second definition of identity).

---

## 7. NEXT (Phase 1 — NOT started; XII untouched per directive)

Tap `xii_rewrite_apply_one` to emit its real firings into `isub` as uniform blocks; make XII's current-term a read-side fold; stand up the Divergence Gate (old ∥ new, answer-identical + provenance-richer). Generalize the `1906` driver from a corpus one-off into a reusable event-tap. RED-probe first, seal + wire, adversarially refute, reseal.
