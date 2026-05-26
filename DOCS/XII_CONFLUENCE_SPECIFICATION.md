# XII Confluence Specification & Status

This document is the authority for the substrate's XII term-rewriting confluence.
It was requested as a forward-looking specification, but a survey of the real
substrate establishes that **XII confluence is already achieved** — by an engine
substantially richer than the idealized 12-rule sketch. This document therefore
records the canonical real implementation, the completion that closed the last
divergences, and the one genuine residual (feeding the confluence theorems into
the math-library queue once an admission tactic exists).

## Status: ACHIEVED

The substrate's XII algebra is **not** twelve rules; it is **44** (`R001`–`R044`)
in `STDLIB/iii/omnia/xii_rewrite.iii`, with a full critical-pairs corpus in
`STDLIB/iii/omnia/xii_critpairs.iii` and a completion record at
`DOCS/XII-CONFLUENCE-COMPLETION.md` (Phase XII-θ). The idealized plan's
`numera/xii_rule_table.iii` + `numera/xii_confluence_check.iii` + `hexad.iii` /
`ring.iii` / `k_invariant.iii` do not exist and are not needed — the real engine
predates and exceeds them.

## Canonical artifacts (the authority)

| Artifact | Role |
|----------|------|
| `STDLIB/iii/omnia/xii_rewrite.iii` | the 44 rewrite rules (`R001`–`R044`), `match_R0xx`/`apply_R0xx`, `xii_rewrite_apply_one`, `xii_rewrite_last_rule_fired` |
| `STDLIB/iii/omnia/xii_canonicalise.iii` | `xii_canonicalise` → `_canon_walk` drives `apply_one` to fixpoint, bottom-up (full normalization) |
| `STDLIB/iii/omnia/xii_critpairs.iii` | the critical-pair corpus; `_cp_converges` canonicalises both sides to fixpoint and asserts byte-equal normal forms |
| `STDLIB/iii/omnia/xii_basis.iii`, `xii_hj.iii`, `xii_subforms.iii` | the kernel basis, Hilbert–Jacobson table, and subform algebra the rules operate over |
| `DOCS/XII-CONFLUENCE-COMPLETION.md` | the Knuth-Bendix completion record (Phase XII-θ) |
| `DOCS/III-XII.md` | the prose specification of the XII system |

## Kernel / kind alphabet (real, from `xii_rewrite.iii`)

The term algebra is over K-kernels and forms, not the idealized
`0x20`-hexad-compose sketch:
- **Kernels:** `K06_COMPOSE` (compose), `K12_THEN` (sequential then), `K17_LIFT`
  (lift). Loop/compose constructors `F.LOOP` (FLOOP) and `F.COMPOSE` (FCOMPOSE).
- **Forms:** `FORM`, `BIND`; the sentinels `NULL_GROUND_FORM = 0xFFFFFFFF` and
  `TRIVIAL_LIFT_FORM = 0xFFFFFFFD`; the derived nulls `K06_NULL` (`K06_COMPOSE`
  over `NULL_GROUND_FORM`, `_is_compose_null`) and `K12_NULL` (`K12_THEN` over
  `NULL_GROUND_FORM`, `_is_then_null`).
- **Representative rules:** `R001` (COMPOSE re-association), `R013`/`R014`/`R015`
  (loop-unit collapse), `R024` (LIFT chain), `R025` (`K17_LIFT(r,r) → TRIVIAL`),
  `R032` (`COMPOSE(FORM,FORM)` sort).

## Knuth-Bendix completion (Phase XII-θ) — the divergences that were closed

Five critical pairs were genuinely non-joinable in the pre-completion algebra;
they were **completed** (not disabled) per the substrate's "no workaround"
standard, by adding orienting rules:

| CP | Rules | Cause | Closed by |
|----|-------|-------|-----------|
| CP-212 | R001 × R032 | R001 re-association permanently separates the two direct-child FORMs that R032 needs | completion rule |
| CP-230 | R001 × R032 | as CP-212 (trailing FORM operand) | completion rule |
| CP-266 | R032 × R032 | 3-FORM spine unreachable by pairwise R032+R001 | completion rule + test rebuild |
| CP-222 | R024 × R025 | missing `THEN(TRIVIAL,x) → x` categorical identity | completion rule + test rebuild |
| CP-286 | (none) | `F.LOOP(K06_NULL,n)` had no rule for n≠1 | `R041` (`F.LOOP(K06_NULL,n) → K06_NULL`) |

The completion is **4 rules + 1 guard** (`R041`–`R044` + a guard). The rule
survey confirms `R041`–`R044` are present in `xii_rewrite.iii`; the 5 CPs are
re-enabled in `xii_critpairs.iii` (line ~3414: "Phase XII-theta: CP-212/222/230/
266/286 re-enabled as real two-path drivers after Knuth-Bendix completion").

## Confluence theorem identifier (for the math-library queue)

When the math-library admission tactic lands (**forward-reference #10**), each
confluent critical pair `(R_i, R_j)` is admitted as a theorem with id
`Keccak-256(rule_i_id ‖ rule_j_id ‖ "xii_confluence")`, statement = the byte
concatenation `(rule_i_id, rule_j_id, converged_normal_form)`, discharging tactic
`TAC_AUTO` (decidable: `_cp_converges` already proves it). The theorem **source**
is the existing `xii_critpairs.iii` corpus, not a new harness.

## Verification gate

The confluence gate is the existing XII critical-pairs corpus: every enabled
critical pair canonicalises both rewrite paths to a byte-equal normal form,
including the 5 re-enabled completion CPs. Run via the substrate's corpus runner
(`STDLIB/scripts/run_corpus.sh`); the XII corpus reports zero non-joinable pairs.

## Residual (the only open item)

The 44 confluence theorems cannot yet be **committed as math-library-queue
entries** because the queue has no admission tactic (forward-reference #10).
Until that lands, `DOCS/MATH_LIBRARY_QUEUE.md` correctly remains lean and the
confluence proof lives in the corpus. No XII *implementation* work remains.
