# III — omnia::event_substrate
### The inverted substrate: the EVENT is primary, STATE is the side effect; finite folds + the infinitary (parity) fold
> **Date:** 2026-06-20 · **Author pass:** /architect · /creative-solve · advisor-reviewed
> **Status:** ORGAN BUILT + VERIFIED (KAT 1901 exit 99, teeth 13). Registration + live non-test consumer STAGED (§7).
> **Files:** `STDLIB/iii/omnia/event_substrate.iii` (organ) · `STDLIB/corpus/1900_event_substrate_poc.iii`
> (finite POC) · `STDLIB/corpus/1901_event_substrate_infinitary.iii` (infinitary KAT).

---

## 1. THESIS → REQUIREMENTS

From the Parity wall: what survived was a **relationship in verb form** — the winner is decided by what
RECURS in the observed history, never by an instantaneous number; perceiving participation moves the
outcome more than a theorem. So invert ripple: the EVENT (a perceived `(tick, observer, kind, priority,
payload)`) is primary on an append-only monotonic log; **STATE = a deterministic FOLD over a prefix.**

| FR | Requirement | Verified by |
|----|-------------|-------------|
| FR-1 | Append-only perception is the only mutator; no stored state cell | organ: `evt_perceive` is the sole writer |
| FR-2 | FINITE folds: max-priority / winner / moves-only / observe-count over a prefix | 1900 + 1901 scenes |
| FR-3 | INFINITARY fold: parity acceptance over a lasso (stem·cycle^ω) = parity of max priority IN THE CYCLE | 1901 scene A |
| FR-4 | Lasso is FOUND not assumed: payload-recurrence detection (`evt_detect_cycle`) | 1901 scene C |
| FR-5 | Witnessed + reversible: same history ⇒ same root; a prefix re-derives the past | 1901 scene D |
| FR-6 | NOT observational learning: fixed pure folds, no counting-to-adapt/threshold | Mandate 7; folds are pure |

**NFR:** deterministic (logical tick, not wall clock); Ring R0; K=1.00 (pure functions of one log); NIH
libc-only, zero externs; collision-free `evt_`/`EVT_` namespace (the `es_` prefix was taken by the
erasure-shard organ — caught via `nm` before any seal).

---

## 2. THE INFINITARY FOLD (the /creative-solve core)

An infinite perceived stream that is eventually periodic = a **lasso**: a finite `stem` then an
infinitely-repeated `cycle`. The parity winner = parity of the highest priority seen **infinitely
often**. In a lasso only the CYCLE recurs i.o.; the stem occurs once. Therefore:

> **inf_winner(lasso) = parity( max{ priority(e) : e ∈ cycle } )** — the stem (transients) drops out.

This is finite, deterministic, witnessed — and it IS the parity-game acceptance condition. The deepening
of the thesis: it is not mere observance that decides, but **observance that RECURS**. An odd OBSERVE in
the cycle flips the winner; the same OBSERVE in the stem does not (1901 scene B, both arms).

`evt_detect_cycle` finds the lasso by scanning for the first payload (a repeated game-position / a
repeated rewrite-term) that recurs, setting the cycle to `[first_occurrence, here)`. One mechanism, two
consumers (§6).

---

## 3. COMPONENT / API (organ `omnia_event_substrate`)

```
evt_reset()                                      -- clear the log
evt_perceive(observer,kind,priority,payload)->tick  -- the ONLY mutator (kind: 0=MOVE, 1=OBSERVE)
evt_count() -> u32
-- FINITE folds (prefix [0,upto)):
evt_maxprio / evt_winner / evt_maxprio_moves / evt_winner_moves / evt_observe_count / evt_witness
-- LASSO / INFINITARY:
evt_find_payload(value,upto) -> idx|NOTFOUND
evt_detect_cycle() -> cycle_len   (0 = no recurrence = terminating; sets cycle_start)
evt_mark_cycle(idx) / evt_cycle_start()
evt_inf_maxprio() / evt_inf_winner()             -- fold over [cycle_start, count)
```
Witness = multiply-add poly rolling hash over the 5-tuple per event (pure `*`,`+`).

---

## 4. VERIFICATION (teeth, not vibes)

- 1901 → **exit 99** (14 assertions, distinct codes).
- **Teeth:** collapse the infinitary fold to fold-from-0 (= the finite fold) → 1901 fails at exactly
  code **13** (the transient-drop "finite and infinitary MUST differ" assertion). The infinitary fold is
  provably not the finite fold relabeled.
- Compiled with the pinned `COMPILED/iiis-2.exe`; links from inside a copy of `libiii_native.a` (no
  symbol collision after the `evt_` rename).

---

## 5. DECISION LOG

- **ADR-1 (no fabricated XII loop).** XII *terminates*, so forcing the infinitary fold onto a hand-driven
  `apply_specific` cycle XII would never produce is the toy/false-claim pattern. REJECTED. The infinitary
  fold's real home is parity-game plays (the grail 1839–1847 lineage), demonstrated honestly in 1901-C.
- **ADR-2 (XII wire = finite certificate + termination witness).** When wired to XII, fold the FINITE
  folds + witness over the REAL normalization trace (a replayable rewrite-trace certificate) and run
  cycle-detection as an HONEST NEGATIVE (no recurrence ⇒ a termination witness). Do not force infinitary.
- **ADR-3 (construction-canonicalization finding).** Low XII rules (R001 assoc, R002 then-assoc, …) are
  retired into the constructors (`xii_term_make_fusion2` canonicalizes at build), so `apply_one` is a
  no-op on freshly-built terms — the firing stream to fold lives at CONSTRUCTION, not `apply_one`. The
  XII wire must hook construction events or a non-canonicalizing rule path. (Drove ADR-1/2.)

---

## 6. CONSUMERS (one mechanism, two homes)

- **Parity-game play** (the real home): payload = position id; a revisited position closes the lasso;
  `evt_inf_winner` IS the game's winner. Live wiring target: the grail parity solver (1839–1847).
- **XII rewrite trace**: payload = term hash; a recurrence is a rewrite loop, its absence a termination
  witness. Per ADR-3 the hook is construction-level, not `apply_one`.

---

## 7. STAGED (honest next steps — blocked, not punted)

1. **Register** `omnia/event_substrate` in `build_stdlib.sh` MODULES + 1900/1901 in `run_corpus.sh`
   EXPECTED, then **reseal**. Blocked by the known `build_stdlib` forge_check hang in this env (memory:
   seal is intact, the hang is environmental) — needs a clean-build moment. Until then the organ is
   verified-but-unregistered (a loose, proven file, NOT yet a sealed module).
2. **Live non-test consumer** so it is not a dead island: wire `evt_*` to fold a real parity-solver play
   (preferred) or the XII construction stream (per ADR-3).
3. **Infinitary depth**: multi-observer perception; nested/multiple cycles beyond the single lasso.

## 8. RISKS

| Risk | Mitigation |
|------|-----------|
| Stays a dead island (the very thing being cleaned up) | §7.2 is the gating next step; organ already computes a *named* thing (parity acceptance), not a demo |
| Reseal never run ⇒ drift between file and sealed archive | §7.1 staged explicitly; tree left green (seal untouched) rather than half-sealed |
| Toy-trap on the XII wire | ADR-1/2 forbid the fabricated loop; finite-certificate + honest-negative only |
