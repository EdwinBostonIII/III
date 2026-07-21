# Mandate Engine — Tier 2: HOROS, METRON, PHRONESIS

> **For agentic workers:** Use `superpowers:executing-plans` (subagents BARRED — no subagents on III).

**Goal:** The depth tier: function contracts refusable by name (HOROS), cost envelopes and
descriptive redundancy measured not asserted (METRON), and mental-model lenses with exact
discharge predicates (PHRONESIS).

**Architecture:** Three organs, ONE substrate. HOROS registers per-export obligation scrolls and
discharges them by EIDOLOS entailment over an evidence house — dogfooded on PRAXIS's own exports,
with a gate tooth that greps the LIVE `praxis.iii` export list and refuses any export lacking a
registered boundary-stone (the RATCHET made mechanical for the subject organ). METRON judges a
declared envelope `steps <= c*n` against counts measured EXACTLY by the real `exec_cert` fold
under real `px_pin` calls, and measures redundancy as verdict-table shadowing via the Tier 0
ONTOS meters. PHRONESIS is a lens table whose discharge COMPOSES PRAXIS (`px_begin/px_pin/
px_stand/px_judge`) — a lens is an obligation scroll the evidence must determine.

**Tech Stack:** `.iii` via `COMPILED/iiis-2.exe`; gates mirror `ontos_gate.sh` (organ carries its
selfprove `main`, linked FIRST under `--allow-multiple-definition`).

## Global Constraints

- Lowercase idents in every scroll. RED-first per organ (arms reference the organ's fns before
  they exist only within the same new file — so RED here = the gate red until the organ is whole;
  the negative arms ARE the teeth). Every `@export` consumed by an arm or the gate.
- Honest boundaries, named in-file: HOROS enforcement rides the GATE before the link step (true
  compiler-refusal is future work); METRON envelopes are measured at specific n (asymptotic
  inference is undecidable — a measured envelope with refusal is what a mandate needs);
  PHRONESIS discharges the lens's OBLIGATION (whether an agent invoked the lens sincerely is
  not decidable — the obligation is).

---

### Task 1: HOROS — the boundary-stone (`STDLIB/iii/omnia/horos.iii` + `STDLIB/scripts/horos_gate.sh`)

**Interfaces:** `hr_register(name, obligation) -> u64` (slot or REFUSE if full/dup),
`hr_count() -> u64`, `hr_discharge(i, evidence) -> u64` (1 = the evidence house determines the
obligation; 0 = REFUSED), `hr_find(name) -> i64` (@export, slot or -1), `horos_selfprove() -> u64`.
Registers all 8 PRAXIS exports (`px_begin px_pin px_stand px_judge px_count px_seal px_fresh
praxis_selfprove`) with real obligations; ARM negative = an undischargeable obligation REFUSED.
Gate tooth: `grep -oE '^fn (px_[a-z_]+|praxis_selfprove)' STDLIB/iii/omnia/praxis.iii` names must
each appear in a `hr_register("...")` line of `horos.iii` — a praxis export without a stone reddens.

- [ ] Organ written; discharge = px composition (begin/pin(evidence)/stand/judge(obligation))
- [ ] Gate: compile horos+praxis+eidolos+exec_cert+isub+idfold, horos.o FIRST; selfprove=0;
      export-coverage tooth; two-run determinism
- [ ] Commit: "HOROS: every export carries a boundary-stone, and the undischarged is refused by name"

### Task 2: METRON — the measure (`STDLIB/iii/omnia/metron.iii` + `STDLIB/scripts/metron_gate.sh`)

**Interfaces:** `mt_pin_cost(n) -> u64` (exact xc_len delta of ONE real `px_pin` of an n-byte
scroll = n+1), `mt_quad_cost(n) -> u64` (exact total of the real quadratic prefix-pinning
process), `mt_envelope(steps, c, n) -> u64` (0 = within `c*n`, 1 = VIOLATION), `mt_redundant(n)
-> u64` (1 = oracle B's verdict table is a FLAT shadow of A's over n probes — measured via
`ont_tbl_set`/`ont_image_ext`), `metron_selfprove() -> u64`. Arms: linear process holds its
envelope at n=8/16/32; quadratic process VIOLATES the same envelope at n=32 (the refusal is
real); identical tables measured redundant, differing tables not; envelope arithmetic exact.

- [ ] Organ written; costs measured from the LIVE exec_cert counter around real px_pin calls
- [ ] Gate: compile metron+praxis+eidolos+exec_cert+isub+idfold+ontos(+its deps), metron.o FIRST;
      selfprove=0; two-run determinism
- [ ] Commit: "METRON: the envelope is measured and the violation refused; redundancy is a shadow, measured"

### Task 3: PHRONESIS — practical judgment (`STDLIB/iii/omnia/phronesis.iii` + `STDLIB/scripts/phronesis_gate.sh`)

**Interfaces:** `ph_obligation(lens) -> u64` (the obligation scroll: 1 first-principles
`[conclusion < pinned]`, 2 pre-mortem `[cause < falsifier_ran]`, 3 pareto `[rank < measurement]`,
4 inversion `[negation < refuted_pin]`, 5 adversary `[verdict < assay]`, 6 calibration
`[confidence < frequency]`; 0 for unknown), `ph_discharge(lens, evidence) -> u64` (1 = the
evidence determines the lens's obligation, 0 = REFUSED, 2 = unknown lens NAMED refusal),
`phronesis_selfprove() -> u64`. Arms: each of the six lenses discharged by a real evidence chain
AND refused on a broken one (12 arms) + unknown-lens refusal.

- [ ] Organ written; discharge composes PRAXIS — no new judging substrate
- [ ] Gate: compile phronesis+praxis+eidolos+exec_cert+isub+idfold, phronesis.o FIRST;
      selfprove=0; two-run determinism
- [ ] Commit: "PHRONESIS: a lens is an obligation the evidence must determine, or it is refused"
