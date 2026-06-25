# EIDOS Event-Driven Audit — the Seraphyte organs vs the ripple substrate

**Thesis (EIDOS):** EVENT is primary, STATE is the fold. Everything is meant to be a `<verb,a,b>` ripple on
the log; an organ's *inputs* are events it reads, its *verdict* is a witnessed event it emits, and the
verification membrane (`ser_pipeline`) is ONE replayable, content-addressed fold over those verdicts — not a
pile of isolated function calls. `ser_intent` is the reference pattern (declare/propose/merge = `evt_perceive`
events, `in_witness` = `evt_witness`). `eidos/ripple`'s `V_REFLECT` is the involution; `event_substrate`'s
`evt_detect_cycle` is the paradox gate.

**The finding (grep audit, substrate calls per organ):**

| organ | substrate calls | verdict |
|---|---|---|
| ser_intent | 9 (evt_*) | ✅ event-driven (the reference) |
| ser_absint | 8 (evt_*) | ✅ event-driven (emits SMT-obligation events) |
| ser_eidos | 22 (field_*) | ✅ witnesses on eidos/field |
| ser_pipeline | 3 (field_*) | ✅ partial — the fold |
| **ser_causal** | 0 → **fixed** | ❌→✅ was a pure island; now rides the log (this audit) |
| ser_tgraph | 0 | ❌ ISLAND — and it's an LTL checker whose trace *should be* the event log |
| ser_kinduct | 0 | ❌ ISLAND — k-induction over reachable states = folds of event sequences |
| ser_kinduct_sym | 0 | ❌ ISLAND |
| ser_tdriver | 0 | ❌ ISLAND — the temporal choreographer, composes the three above |
| ser_egraph | 0 | ❌ island for its *verdict* (the data structure itself is fine) |
| ser_petri | 0 | ❌ island for its verdict |
| ser_antiunify | 0 | ❌ island for its verdict |
| ser_cegis | 0 | ❌ island for its verdict (CEGIS rounds = events) |
| ser_cascade / cascade2 / regalloc | 0 | ❌ island for their verdicts |
| ser_fsm | 0 | ⚠ the kinduct substrate; could fold from events |

The damning part: the **temporal organs** (causal, kinduct, tgraph, tdriver) — the ones whose *entire job is
events and time* — were the pure-function islands. The data-structure/kernel organs being pure is defensible;
a temporal verifier ignoring the event log is the architectural bug.

## Per-tool architecture (judgment)

Two distinct event-driven relationships, applied per tool:
- **CONSUME**: the organ's *input* is the event log (only the temporal organs — their trace/FSM/ordering ARE
  the events).
- **EMIT**: the organ's *verdict* is a witnessed event (every organ, so the membrane folds one log).

### Tier A — ENTIRELY event-driven (consume + emit). The temporal organs.
- **`ser_causal`** — DONE (corpus 2055). Ripples are perceived events; `caus_collapse` reads them and emits
  the witnessed collapse certificate; commute ⟺ the `V_REFLECT` swap is valid. Pure `caus_commute` kept as the
  kernel for existing callers (`ser_tdriver`).
- **`ser_tgraph`** — the LTL trace must BE the `evt_perceive` log. Add `stg_check_events(formula, root)` that
  binds atoms to event kinds and evaluates over `evt_count()` events. The membrane (deadlock-freedom of the
  real choreography) then runs on the real event stream, not a synthetic `tl_trace`.
- **`ser_kinduct`** — the FSM's reachable states are folds of event sequences. Either fold `ser_fsm` from
  `event_substrate` (transitions = events) or, minimally, witness `ski_universal_g`'s verdict on the log so a
  proof is a replayable event. The base/step stay pure.
- **`ser_tdriver`** — orchestrates causal+kinduct+tgraph; once they consume the log it composes over one
  stream, and emits the alignment verdict as a witnessed event.
- **`ser_kinduct_sym`** — small; EMIT its symbolic verdict as an event (split).

### Tier B — SPLIT (pure kernel + EMIT verdict as a witnessed event). The computational organs.
The kernels stay pure (that's correct — a proof/fuzz/saturation is not temporal). Only their *verdict* joins
the log so the membrane can fold it:
- **`ser_egraph`** — saturation/extraction stays pure; emit the discovered rule (the synthesized form + its
  bv_ring/gold verdict) as a ripple. `seg_intuit` (the backward read) already stays.
- **`ser_petri`** — fuzz stays pure; emit the refute/pass verdict as an event.
- **`ser_antiunify`** — matcher stays pure; emit the discovered family as an event.
- **`ser_cegis`** — synth stays pure; but each CEGIS round (propose → counterexample → refine) is naturally an
  event sequence — emit per-round events + the final descriptor (partial-consume is justified here).
- **`ser_cascade` / `ser_cascade2` / `ser_regalloc`** — emit cost/coverage/spill verdicts as events (low
  priority; they feed the membrane fold).

### Tier C — already correct.
`ser_intent`, `ser_absint`, `ser_eidos`, `ser_pipeline` — keep. Verify `ser_absint`'s emission is complete.

### `ser_fsm` — judgment: keep, optionally unify.
It's a clean registerable transition table and a fine substrate for the generalized k-induction. The purer
EIDOS form would *derive* it from the event log (states = distinct fold values, transitions = events), folding
it into `event_substrate`. Worth doing once `ser_kinduct` consumes the log; not urgent.

## What this buys (the architectural payoff, not decoration)
One log, one fold. When every verdict is a witnessed event: the whole membrane is **replayable** (re-fold →
same verdicts), **content-addressed** (the witness binds the reasoning), and **composable** (organs read each
other's verdicts off the log instead of being wired by hand). The temporal organs additionally gain their
*natural input* — the events they were always supposed to reason about. That is the difference between a pile
of pure functions and an event-driven verification substrate.

## Correction (this turn, per review) — the bar for "event-driven"
The first `ser_causal` rewrite was COSMETIC and is the kind of thing this whole effort exists to kill: a
write-only "epoch verdict" event nothing read, plus a pack→perceive→read→unpack round-trip to the same pure
function. The event log was decoration, not load-bearing. It was caught and replaced with the genuine version:
`caus_collapse` is now a FOLD over the logged ripples producing the causal epoch partition (consumable via
`caus_epoch_of`), and the realized `O(N!)→O(epochs)` reduction is MEASURED (`caus_orderings_to_check`,
6→1/6→3/2→2). **The bar: the verdict must emerge from folding the log and be consumable — not the API shape
bolted on to pass a grep.** Every Tier-A/B item below is held to that bar.

## Status
- DONE this pass (genuine, executed): pruned the e-graph palindrome law-duplicates (kept `seg_intuit`);
  `ser_causal` made event-driven via a real fold (2055); `ser_tgraph` consumes the event log as its LTL trace
  (2056); `event_substrate` gained positional readers (`evt_payload_at/kind_at/prio_at`).
- NEXT, in order of architectural payoff: `ser_tdriver` (orchestrate one stream) → `ser_kinduct` (witness;
  consume the epoch partition) → the Tier-B verdict-emissions. Each KAT-gated, executed, held to the bar above.
- OWED: `build_stdlib` green since `d4b12beb` (predicted gate-outcome-ratchet hit) — clears before the Tier-B
  sweep.
