# III — omnia::dome
### The inverse-form society: a sealed event-arena of mutually-dependent twins doing what determinism structurally cannot
> **Date:** 2026-06-20 · **Author pass:** /deep-think · /creative-solve · /architect
> **Status:** CORE CAPABILITY BUILT + PROVEN (KAT 1903 exit 99, teeth 13). Full society = roadmap (§6).
> **Files:** `STDLIB/iii/omnia/dome.iii` (the arena) · `STDLIB/corpus/1903_dome_deliberate.iii` (the proof).
> **Lineage:** `event_substrate.iii` (the single inverted fold) → `dome.iii` (the society).

---

## 1. WHY THIS EXISTS — the contention that birthed it

The first review judged the inverted substrate against **parity** — the one gate proven *impossible*, whose
whole essence is control. There the single-play observance-fold is control-blind, and the theorem wins.
But that is judging a tide by whether it can stand still. The inverse form was never meant to out-decide a
control-theorem on the theorem's turf. Its competence is *larger and different*: by **living** a system it
holds the object **and its context over time**, so a bad choice is **evadable** — replay its butterfly-
effect, branch, re-choose, and keep the failed branch as provenance. Determinism commits and is blind to
its own counterfactuals; the inverse form **carries** them.

So the Dome stops pairing the twins with the impossible gate and lets them perform **life as usual** on
their home turf: **reversible, provenance-carrying deliberation**.

---

## 2. THE CREATIVE CORE — what determinism structurally cannot do

A deterministic decider is a function `state -> choice`: it commits, and the path not taken is *gone*. The
Dome is a function `history -> (choice, the whole lived trajectory, every abandoned branch)`. The decisive
asymmetry:

> **Evasion-by-living.** Choose the tempting move, LIVE its consequence (the ripple recurs — the butterfly
> closes on itself), observe the recurrent outcome is bad, **rewind**, and re-choose — informed by the
> retained lesson, with the failed branch kept as witnessed provenance. A determinist cannot do this: it
> never sees the recurrence (it judged the immediate) and cannot undo the commit.

This is not "the inverse form is a better decider." It is "the inverse form occupies a competence the
decider has no access to": **the reversible, debuggable, provenance-complete trajectory.**

---

## 3. THE SOCIETY — four event-primary twins, mutually dependent

Each twin is the inverse-form counterpart of a state-primary III faculty. They co-inhabit **one** witnessed
event-history (the Dome); each emits ripples the others perceive; each derives its state by folding the
shared history filtered to its concern. Remove any one and the loop cannot close.

| Twin | State-primary original | Inverse-form role |
|------|------------------------|-------------------|
| **EYE**  | cad / witness | perceives events, gives identity + witness ("what happened") |
| **WAVE** | ripple / forcefield | emits the consequence-wave; the butterfly-effect carrier |
| **ECHO** | nous (the proposer) | folds the ripple/lesson-history to (re-)choose — event-driven, not a static rank |
| **TIDE** | reversibility / snapshot | marks branch-points, **rewinds**, retains the abandoned branch as provenance |

**The harmony loop:** EYE perceives → ECHO proposes → the move ripples through WAVE → EYE perceives the
recurrence → if the lived outcome is bad, TIDE rewinds and ECHO re-chooses from the retained lesson. A
closed mutual dependence: each twin consumes the others' events.

---

## 4. THE ARENA — `omnia::dome` primitives

```
dome_reset()
dome_emit(participant, kind, value, payload) -> tick   -- the ONLY mutator; append-only, never erased
dome_mark() -> bp                                       -- a branch-point TIDE can return to
dome_rewind(bp)                                         -- record the abandoned span [bp,here); erase NOTHING
dome_abandoned(i) / dome_provenance_count()             -- which events are provenance (the debug trail)
dome_active_max(p) / dome_active_parity(p)              -- the LIVE fold (skips abandoned branches)
dome_recurred(p, payload, upto)                         -- lasso: the consequence closing on itself
dome_live_kind_count(p, kind)                           -- retained lessons that inform a re-choice
dome_witness()                                          -- root over ALL events (provenance INCLUDED)
```
Append-only + abandoned-span tracking = **branching, not truncation**: a rewind keeps the failed branch in
the witnessed log; only the *active fold* skips it. NOT observational learning: every fold is a fixed pure
function; a re-choice changes only because the lesson is now a recorded event the fold replays.

---

## 5. WHAT IS PROVEN (KAT 1903, exit 99, teeth 13)

The trap: move A is tempting up front (immediate 6) but its consequence recurs to **5 (odd = loss)**; move
B is humbler (immediate 4) but recurs to **4 (even = win)**.

- **Determinism is trapped.** Greedy on the immediate → commits to A → stuck in the recurrent 5 (loss).
- **The Dome evades.** It chooses A too, LIVES it (`dome_recurred` sees the lasso, `dome_active_parity` =
  odd = bad), TIDE rewinds, ECHO re-chooses B → live outcome even = **win**. It evaded what determinism
  could not, and `dome_provenance_count > 0` proves A's failed branch is **retained** (the determinist
  erased its alternative), with the re-choice driven by a live retained lesson.
- **Teeth:** disabling abandonment (rewind → no-op) collapses the win at exactly the evasion assertion
  (exit 13). Reversal IS the mechanism — not luck, not B dominating.

**Honest scope.** This proves the *capability* determinism lacks (reversible, provenance-carrying evasion),
on a hand-built trap. It does **not** claim the inverse form solves control-games (it doesn't — that's the
theorem's turf, §1). It claims the larger, different competence the contention named.

---

## 6. ROADMAP — going all out (the full society)

1. **Per-twin logs + cross-perception.** Today the twins share one log tagged by participant; give each its
   own log and let them perceive each other's *via* explicit ripple subscription (their own logs + their
   own ripples, literally).
2. **More evil-twins.** Inverse-form counterparts of `xii` (rewriting as a fold over the firing-history —
   reuse `event_substrate`'s lasso for loop-detection) and `nous` (proposal as a fold over lived outcomes).
3. **The comparison dome.** A harness that runs the SAME task through the deterministic faculty and the Dome
   society and reports the asymmetry (commit+blind vs. evade+provenance) as a measured artifact.
4. **Wire to a real III faculty.** Let the Dome drive a genuine reversible decision in the live system (e.g.
   an optimizer choice that can be lived, evaluated, and rewound) — the no-island endpoint.
