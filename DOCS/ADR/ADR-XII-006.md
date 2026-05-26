# ADR-XII-006: 117-Pair Critical-Pair Convergence Enumeration as Live Tests, Not Theorem Citation

## Status
Accepted (Phase XII-η).

## Context

`DOCS/III-XII.md` S9.2 documents 117 critical pairs across 7 classes (C1..C7) whose convergence (canonical-form structural equality after two distinct reduction paths) is the precondition for confluence of the 40-rule rewrite system. Newman's lemma + termination (S9.3) then upgrades local confluence to global confluence, yielding decidability of canonical form (S9.4).

The first draft of `xii_critpairs.iii` covered 18 of the 117 pairs as **named real two-path tests** (CP-001..107 spanning the 7 classes), with the remaining 99 pairs covered by parameterised expansion helpers like `_cp_c1_pair(op_outer, op_inner)` that the operator caught as **tautological**:

```iii
let t1 : u32 = build_overlap(args)     // builds T
let t2 : u32 = build_overlap(args)     // builds T identically
let c1 : u32 = xii_canonicalise(t1)
let c2 : u32 = xii_canonicalise(t2)
return xii_rewrite_struct_eq(c1, c2)   // trivially true: canonicalise is deterministic
```

That established the precedent: a "two-path" critical-pair test must drive **two different reduction sequences** from one overlap term — otherwise it proves `canonicalise` is a function, not that the rule system converges on overlapping rewrites.

A second draft proposed citing the **Knuth-Bendix completion** that the curator runs on paper at day-zero (S9.2 references "hand-curated" confluence). The day-zero proof is the formal record, sealed as `CRY-XII-CONF-001`. The compile-time and corpus-time checks could merely verify `CRY-XII-CONF-001 == sealed_value`.

The operator rejected the citation approach: "every fucking one. not ten more. every fucking one."

## Decision

Every one of the 117 spec-target critical pairs is a **live empirical two-path test** in `STDLIB/iii/omnia/xii_critpairs.iii`. Each test:

1. Calls `xii_term_arena_reset()` to clear the term arena.
2. Builds the overlap term twice — `T_a` and `T_b` — using freshly-allocated arena slots so they are independent references.
3. Applies **two different** rule_ids to the two copies via `xii_rewrite_apply_specific(rule_id, t)` — for example, R001 on `T_a`, R017 on `T_b`. The dispatcher's `XRW_LAST_RULE_FIRED` protocol confirms the rule actually fired (otherwise `XCP_NULL_REF` is returned and the test bails).
4. Returns `_cp_converges(pa, pb)` which canonicalises each path and compares with `xii_rewrite_struct_eq`.

The 117 are organised as 31 named class-check tests (`_cp_001`..`_cp_107`) called from the 7 per-class check functions (`_cp_c1_class_check`..`_cp_c7_class_check`), plus 86 extended-class tests (`_cp_200`..`_cp_291`) called from `_cp_extended_class_check`. All 8 checks are aggregated by `xii_critpairs_verify_all()`.

`xii_critpairs_actual_count()` returns `117u32`, equal to `xii_critpairs_pair_count()`.

The day-zero `CRY-XII-CONF-001` proof crystal continues to exist as the formal record, but the runtime tests are now the **empirical confirmation** that the spec target is honored. Drift between the two (e.g., a future edit changes one of the 40 rules but a CP test still passes by accident) is caught because every CP test drives a real rule application; if the modified rule produces an unconvergent rewrite, the corresponding CP test fails.

## Consequences

### Positive
- **Live empirical proof at every corpus run.** Confluence is not a claim in a doc; it's a check that runs every time `corpus/371_xii_critpairs_real.iii` is executed.
- **Regression-tight.** Any change to the 40 rewrite rules that breaks convergence on any of the 117 pairs fails at corpus time. The 40 rules are now bound to 117 empirical witnesses.
- **No tautological side.** Every test drives two **different** rule applications on freshly-allocated arena copies. The dispatcher's last-rule-fired protocol verifies the rules actually fired.
- **Substrate for future expansion.** When the rule set evolves (e.g., a Catalyst-promoted append adds rule R041), adding new critical pairs against existing rules is a one-line-each addition to `_cp_extended_class_check`.

### Negative
- **Corpus runtime cost.** Running all 117 tests on every `bash STDLIB/scripts/run_xii_corpus.sh` adds ~117 × (build overlap + canonicalise×2 + struct_eq) microseconds. Order-of-magnitude estimate: 10–50 ms per corpus invocation. Acceptable.
- **Maintenance volume.** ~2700 lines of CP-test code in `xii_critpairs.iii`. Each test is short (~15-20 lines) and stereotyped; the volume is mechanical, not conceptually dense.
- **Some pairs are structural variants of others.** A small subset of the 117 (estimated ~20%) test rule pairs whose convergence pattern is structurally equivalent to another pair in the same class. Genuinely redundant in proof-theoretic terms; included for completeness with the spec target.

### Trade-offs Accepted
- **Empirical vs proof-theoretic ground.** The day-zero KB-completion is the formal proof; the 117 tests are empirical witnesses bound to the runtime rule implementations. Both must agree (the rule code matches the proof; the tests confirm the rule code converges). Either failing flags an integrity issue.

## Alternatives Considered

| Approach | Rejected because |
|----------|------------------|
| 18 named + 99 tautological parameterised helpers | Caught as tautological by operator; proves canonicalise is a function, not confluence |
| 18 named + cite `CRY-XII-CONF-001` for remainder | Operator demanded live empirical confirmation, not citation |
| Auto-generate 117 tests from a rule-pair table | Generator becomes a non-NIH dependency surface; each pair has structural specifics (root vs inner application, NULL vs basis operands, predicate vs non-predicate IFs) that a generator can't infer mechanically |
| Random sampling of 100 critical pairs from the 117 | Coverage non-deterministic across runs; sample-induced gaps possible |
| Lattice-replay implicit coverage | The lattice already replays canonicalisation but does not isolate per-pair rule applications; corpus failure would not point at the specific pair that broke |

## References

- `STDLIB/iii/omnia/xii_critpairs.iii` (117 tests + 8 aggregators)
- `STDLIB/iii/omnia/xii_rewrite.iii::xii_rewrite_apply_specific` (the dispatcher that makes per-rule application possible)
- `STDLIB/corpus/371_xii_critpairs_real.iii` (corpus runner that calls `xii_critpairs_verify_all`)
- `DOCS/III-XII.md` S9.2 (117-pair spec target)
- `feedback_no_tautological_proofs.md` (operator's tautology rule)
- ADR-XII-001 (sealed curation foundation including CRY-XII-CONF-001)
