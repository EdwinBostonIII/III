# III Convergence — LIVE-vs-DOC Audit (2026-06-03)

**Why this exists.** The seven-migration "convergence" critical path (`III-APOTHEOSIS-MIGRATIONS-ARCH.md`)
was specced 2026-05-25. This session, entering the convergence at the user's direction, the live
implementation was found to be **AHEAD of its design docs in every migration checked (4× in one session)**.
Implementing against the stale docs risks the duplication trap already hit once this session (the
`@sovereign` checker — re-implemented, then reverted). **This audit re-grounds each migration against the
LIVE code**, per the discipline: *confirm status by reading the live mechanism + testing against the
objective's own falsifier — never conclude "unrealized" from a grep miss.*

## Per-migration live status

| Mig | Objective (H#) | LIVE status | Remaining |
|-----|----------------|-------------|-----------|
| **1** | `cad` collapse / one-name (H2) | ✅ **DONE** | — |
| **2** | SovVal-as-CIC: bricking/over-K → **type error** (H6) | ⚠️ **keystone unrealized AT TYPE-LEVEL** | the type-level lift |
| **3** | `@sovereign` boundary checker (H1) | ✅ **DONE** (b712142; intra-module by design) | — |
| **4** | route ALL computation through XII (H4) | ⚠️ **PARTIAL** — engine+confluence+**trit(M2)** done | gap/cost/sv_op/kernel/transforms |
| **5** | SID inverse + `Compromise` tier (H9) | ✅ **largely built** | the `Compromise<HIGH>`→mig2 type tie |
| **6** | `run_charter()` + falsifier-per-clause (H7) | ✅ **largely built** | per-clause completeness vs mig2/7 |
| **7** | 10-field `SovMorphism` ratified clauses | ⛔ blocked on mig2 + mig6 | assoc + morphism_id clauses |

### Evidence (live)
- **mig2.** `cic.c` (the doc's C trust root) **no longer exists** — ported into `STDLIB/iii/numera/typecheck.iii`
  (a far richer kernel: QTT, W-types, CCL compiler, the "Sovereign Calculus"). `typecheck.iii::sov_admit`
  (L2684) = THE SOVEREIGN MORPHISM = admit `ts` of `t` iff `tc_conv(t,ts)==1` (CCL-proven-equal) AND
  `sov_cost(ts)<=sov_cost(t)` (not costlier) — **proof-preserving cost-descent**, a DIFFERENT invariant than
  the mig2 keystone (reach/over-K → type error). The keystone is **unrealized at type-level**; the M5 runtime
  `sv_op` (`SV_STATUS_REFUSED`) still covers it at runtime. Lifting it = re-ground the doc's Route B (Cost
  inductive + `Reach:Hexad→Prop` + `LeK:Cost→Prop` + dependent SovVal ctor) against `typecheck.iii`'s TC-node
  representation. **CIC-kernel extension on the trust root — its own §F: "a kernel bug undermines everything."**
- **mig4.** `omnia/xii_rewrite.iii` has **45 rules** (R001–R045), not the doc's 40 — **R041–R045 ARE the M2
  trit ops lowered to XII** ("M7 keystone", L57; disjoint kinds ⇒ 0 new critical pairs). The remaining families
  to lower (doc order): **gap (M4 = `uncertainty.iii::unc_*`) → cost (M13) → sv_op (M5) → kernel β/ι (M9) →
  cg/transforms (M17/18)**, each gated by `xii_critpairs` (117+N must converge) + a corpus test + DRIFT reseal.
  Confluence-gated, NOT trust-kernel ⇒ a wrong rule fails the falsifier LOUDLY (safe to advance incrementally).
- **mig5.** `omnia/crystal_deps.iii` exists (rename landed). `numera/reversible.iii` has `REV_TIER_COMPROMISE_LOW`
  + the LOW/MED/HIGH classification (PAGE_FREE→LOW, CAP_RELEASE→MED, NMI_INSTALL→HIGH=bricking).
  `numera/constitution.iii::COP_REVTAG_EQ` reads the tier. The `Compromise<HIGH> doesn't type-check` tie waits on mig2.
- **mig6.** `nous/nous_charter.iii::nous_ch_run_charter`, `numera/category.iii::catl_run_charter`,
  `numera/charter_terminal.iii` (h1–h4 selftests) — all "HOLDS = verify ∧ falsify". The terminal gate exists.

## Critical path + next sound increments
1. **mig2 is the keystone dependency** — mig5's `Compromise<HIGH>`-unrepresentable and mig7's SovMorphism both
   require "a non-reachable/HIGH SovVal does not type-check," which IS mig2. It is a **CIC-kernel extension on the
   trust root** — must be done with full budget + care (a kernel bug is the maximal blast radius); NOT at the
   tail of an exhausted, twice-course-corrected session.
2. **mig4 family-lowering is the incrementally-advanceable one** — confluence-gated, not trust-kernel. Next family
   = **gap (`unc_*`)**: express each as `match_R/apply_R` over `xii_term`, MPO-decreasing, wire at R046+, re-run
   `xii_critpairs` (117+N converge = the gate), corpus test per rule, DRIFT reseal. Atomic per family.

**Bottom line:** the convergence is materially built (mig1/3 done; mig5/6 largely built; mig4 trit done). The
genuine remainder is **mig2 (type-level keystone, fresh-budget trust-kernel work)** + **mig4's 5 remaining family
lowerings (confluence-gated, incremental)**, with mig7 gated on mig2. No work was duplicated; the docs were the
stale map, the live tree the territory.
