# III-XII Confluence-Core Certificate — Architecture (R1)

*Enhanced from the operator's draft after verifying every load-bearing claim against the live
engine (corpus 813/814, `xii_joinability`, `xii_termination`, `xii_canonicalise`, `nous_policy`).
This document supersedes the retracted `CRY-XII-CONF-001` global-confluence seal.*

---

## 0. Verification verdict on the source draft

| Draft claim | Verdict | Resolution in this design |
|---|---|---|
| XII terminates (measure decrease, `xii_termination`) | **TRUE** | Tier 0; the lex-triple `(canon_weight, node_count, assoc_penalty)`, not the simple weight |
| XII confluent from innermost upward; `xii_canonicalise` stable | **TRUE** (innermost-confluence) | Tier 1 floor + §1 |
| Newman: for terminating systems, local confluence ⟺ confluence | **TRUE** | the governing theorem |
| **Non-joining pairs are "at the root"** | **FALSE — inverted** | **Every root overlap JOINS** (`xjn_gate_root`=GREEN, corpus 813); all 35 non-joins are **subterm** overlaps. This inversion is load-bearing (see §1). |
| **"Only two honest routes": KB completion or stop demanding** | **INCOMPLETE** | A third exists and is best for 15/35: **structural elimination** (§3, route S). |
| Confluence is a scoped certificate, not a global verdict | **TRUE + excellent** | §2, sharpened to a *graded* core |
| Certificate = sealed, content-addressed, witnessed III object | **TRUE + excellent** | §5, hardened (rule-set mhash binds *semantics*; re-checkable, not only hash-matched) |
| Reachability + cost-equivalence discharge routes | **TRUE + sound** | §3 routes R and C; cost-route scope-limited (§3.C, §6) |
| **§6: nous's reorderable set is disproven (R008 in range)** | **FALSE for current nous; valid for future** | `nous_policy` preserves R-block cascade order (ADR-N11); only block-swaps the LHS-disjoint trit block. The certificate's nous payload is the *equivalence classes* a future ADR-N2 reorderer must respect (§7). |
| Tier 1 strategy-determinism floor licenses H12 now | **TRUE + excellent** | Tier 1, kept verbatim in spirit |
| Failure modes bounded (eject / Tier-3 / widen cost) | **TRUE** | §8 |

**Net:** the draft's *architecture* (sealed scoped certificate, tiered floor, bounded failure) is
sound and is the backbone here. Three factual claims that touched ground truth were wrong; each
correction strengthens the design. The largest substantive addition is **route S (structural
elimination)** and the **fullness-of-system layer map (§7)** the draft did not cover.

---

## 1. The governing facts (corrected)

Three verified facts, stated precisely:

1. **Termination holds** (`xii_termination`, corpus 814) via the well-founded lexicographic triple
   `(canon_weight, node_count, assoc_penalty)` — gate green with prove-the-negative teeth. This is
   the precondition that makes Newman's reading valid and is a standing dependency of the certificate.

2. **Every ROOT overlap joins** (`xjn_gate_root`=1, corpus 813). XII is therefore **locally confluent
   at the node level**.

3. **All 35 non-joins are SUBTERM overlaps** — an inner rule on a child versus an outer rule on the
   parent (R001×R008 is `xjn_check_subterm(s1,s8,pos=1)`). The family is closed: every non-join has
   an associativity rule (R001–R004) or a B-family lift (R005–R012) involved; the lift is the *outer*
   rule in 28/35; `assoc_either_side`=15; `neither`=0.

**Why "subterm, not root" is load-bearing.** `xii_canonicalise` (`_canon_walk_cap`) is **bottom-up**:
it fully canonicalises a node's children *before* trying any rule at the node, and re-canonicalises
after each firing. A subterm overlap requires the *outer* rule to fire *before* the inner child is
reduced — the exact order a bottom-up walk **never takes**. Hence:

> **Local confluence at the root + bottom-up traversal + termination ⇒ a unique normal form under
> the strategy = INNERMOST-CONFLUENCE.** This is what makes `xii_canonicalise` a deterministic total
> function. Had the failures been at the *root* (as the draft stated), innermost evaluation would not
> save them — the root is evaluated last. The correction is the foundation of Tier 1, not a footnote.

The Newman corollary is unchanged and honest: because XII terminates, a genuine non-joining critical
pair means XII is **not globally confluent**. That is a true statement about *all-orders* confluence,
which III does not have and — as §7 shows — does not require.

---

## 2. The reframe: a GRADED, scoped certificate

Confluence is not a debt owed by the whole engine; it is a certificate scoped to a fragment, and a
non-confluent terminating system routinely contains a large confluent core. The right question is
**"what is the confluent core, and where exactly does it end?"** — and the answer is *measured*, not
proven into existence.

The draft's binary in/out core is enhanced to a **graded core**, because not all discharges are
equally strong, and clients care about the difference (§7):

- **Grade S (structurally confluent):** the overlap is rendered *unrepresentable*; the pair joins
  genuinely. Strongest — real local confluence, by construction.
- **Grade R (confluent on the reachable language):** the overlap never occurs in the image of
  `xii_canonicalise`; the pair cannot fire in practice. Strong — syntactic-NF-unique on real terms.
- **Grade C (confluent modulo cost-equivalence):** the two normal forms differ syntactically but are
  equal under `numera/cost_lattice`. Weaker — **does not** give a unique *syntactic* NF (see §7 on
  content-addressing).
- **Boundary (undischarged):** neither S, R, nor C succeeds; recorded with its bounded response (§8).

The certificate's central output is this graded partition over **all 40 rules** (maximal scope — the
whole boundary map future-proofs every client, not only nous). **Standard of done: the boundary is
drawn accurately and completely.** A certificate reporting "no boundary" would be a *failed
instrument*; its correctness is the fidelity of the map.

---

## 3. The discharge-route lattice (try strongest first)

For each non-joining pair, attempt the routes in preference order; the first that succeeds fixes the
pair's grade. **This ordering is itself the design** — it spends structural strength where it is cheap
and falls back only as forced.

**Route S — structural elimination (NEW; best for the 15 assoc pairs).** Make the divergent overlap
unrepresentable. Concretely: enforce associativity *canonically at the fusion constructor* — right-lean
F.COMPOSE/F.THEN/F.WITH, left-lean F.UNDER, at `xii_term_make_fusion2`. Then a left-nested compose
cannot exist, R001–R004 cannot fire as the inner rule, and every assoc×anything subterm overlap
*structurally cannot form*. This converts a *proof obligation that must be maintained* into a
*construction that cannot regress*. It is neither KB (adds no rules — it *removes* R001–R004 as live
rules) nor resignation. Cost: a determinism-critical change to the universal constructor + a manifest
reseal (the canonical form shifts). Verified mechanism: §1's bottom-up walk already *behaves* as if
left-nesting were transient; route S makes it ontological.

> **ROUTE-S DISCHARGE FOR THE ASSOC FAMILY — VERIFIED (this session).** Per §3's relocated-obligation
> framing, route S owes two proofs; both hold for the 15 assoc-involved pairs:
> - **Obligation #2 (no legitimate rule wants the non-canonical form):** scanned the full 49-rule
>   structural table (`xii_rule_patterns._xrp_fill`). The *only* rules with `root∈{FCOMPOSE,FTHEN,FWITH}
>   ∧ ca=same-kind` (left-nested) or `root=FUNDER ∧ cb=FUNDER` (right-nested) are slots 0–3 = **R001–R004**
>   — exactly the rules route S removes. Every other compose/then/with/under rule constrains its
>   children to specific basis kinds or ANY. **R042** (`FCOMPOSE, ca=K01, cb=FCOMPOSE`) matches the
>   *right-nested* (canonical) chain — it wants what route S produces.
> - **Obligation #1 (the constructor maintains the invariant on every build path):** audited every
>   direct child-mutation site in `xii_rewrite` (`set_child_a/b`). They are: R001–R004's mutations
>   (removed); the B-lift applies (build via `make_fusion2` → canonical); R032 (swaps two FORM *leaves*
>   — no nesting); R042 (transposes chain heads — *preserves* right-nesting). Once `make_fusion2`
>   canonicalises and R001–R004 are gone, **no path constructs a left-nested compose.**
>
> **The elegant corroboration:** R042's own comment states it is the hand-built "sort modulo
> associativity completion" that *"closes the R001/R032 critical pair."* The engine already ran
> Knuth-Bendix-by-hand for that pair. Route S subsumes it: removing R001 evaporates the R001/R032 pair
> R042 was patching, while R042+R032 persist as the FORM-sort on the guaranteed right-nested spine. So
> route S finishes structurally a direction the engine began rule-by-rule. **Consequence: the 15
> assoc-involved non-joins discharge together by construction; the boundary drops 35 → 20 on the first
> move.** Residual route-S verification owed at implementation: after the constructor change + R001–R004
> removal, re-run `xii_joinability` and confirm (a) non-join count = 20, (b) the sort rules R032/R042 on
> the canonical spine introduce no *new* non-join (sorting a right-nested spine is confluent — verify,
> don't assume), then the determinism-critical bootstrap reseal.

**Route R — reachability discharge.** Prove the divergent overlap lies outside the image of
`xii_canonicalise` on the reachable term language. For the assoc cases this is *the same fact* route S
makes structural: a left-nested compose is not in the image (canonicalise right-associates it). Route R
is the **non-invasive** form (a discharged proof obligation, no engine change); route S is the
**permanent** form (the constructor enforces what R asserts). Prefer S when the construction is clean;
fall to R when changing the constructor is too costly for the pair.

**Route C — cost-confluence discharge.** Where the overlap is reachable and the two branches extract to
the same representative under `numera/cost_lattice` (or to two the system already treats as equal), the
NFs differ syntactically but agree where cost decides. Grade C. **Scope limit (critical, §7):** a
Grade-C pair does **not** yield a unique syntactic NF, so it does **not** restore content-address
equality — it serves only clients that compare under cost (e.g., a future reordering nous, federation
with heterogeneous proposers). State the equivalence relation explicitly and prove it for the pair;
never assert it by metaphor.

**Route T — targeted completion (Tier 3; only if forced).** Run Knuth-Bendix for the *single* resistant
pair — a local, bounded application, not the global blow-up that makes KB dangerous. Held in reserve
(§8); never built pre-emptively.

---

## 4. The layered tiers

Each lower tier holds regardless of the tiers above, so the charter always has something true to assert.

- **Tier 0 — Termination.** Held (`xii_termination`). The precondition; kept current as a certificate
  dependency.
- **Tier 1 — Strategy determinism (the unconditional floor).** `xii_canonicalise` is exactly one
  strategy (leftmost-innermost / bottom-up, root competition broken by the fixed cascade priority), so
  for any term it yields exactly one value. Determinism holds **by construction of the strategy and owes
  nothing to confluence.** What is forfeited *only here* is path-independence. **This licenses H12 today,
  truthfully, as "deterministic by fixed strategy"** — the confluence question stops blocking the
  charter immediately. (Unchanged from the draft; it is exactly right.)
- **Tier 2 — The graded confluent-core certificate (the work).** Apply §3's route lattice to every
  non-joining pair; emit the graded partition (§2) + the derived reorder-equivalence classes (§6). This
  upgrades H12 from "deterministic by fixed strategy" to "…and innermost-confluent, with core C graded
  and its complement witnessed and bounded."
- **Tier 3 — Targeted completion, reserved.** Route T, per-pair, only as a §8 response. YAGNI: holding
  it in reserve is what keeps cost bounded.

---

## 5. The certificate as a sealed, RE-CHECKABLE III object

The certificate is not a DOCS file that rots while rules drift beneath it. It is a sealed,
content-addressed, witnessed object in the system's own currency — the feature that makes this fit III
specifically. It carries:

- the **rule-set mhash** it was proven against — **binding the rule *semantics*, not only the
  structural pattern table** (hardened over the draft): the mhash must cover `xii_rewrite`'s guards and
  RHS (e.g., the mhash of `xii_rewrite`'s rule object code / the manifest rule crystals), because a
  guard or RHS change with an unchanged structural LHS would otherwise escape detection and silently
  invalidate the proof;
- the full non-joining-pair enumeration from `xii_critpair_enum` / `xii_joinability`;
- per pair, a **grade tag (S/R/C/boundary)** and its discharge proof;
- the derived **reorder-equivalence classes** (§6), which `nous_policy` (and any future ADR-N2 model)
  consumes in place of an asserted set.

**Two verification depths (the Key Move: never trust, re-check).**
1. **Boot (fast, hash-only):** `run_charter` H12 verifies `certificate.rule_mhash == live_rule_mhash`.
   Change any rule and the hashes diverge; the charter fails loudly and at once. This is "the gate moved
   from your vigilance into the binary."
2. **Deep (periodic / CI, re-prove):** re-run the discharge prover and the joinability/termination gates
   against the live rules and confirm the certificate's grades still hold. The hash-match trusts the
   seal; the deep re-prove *earns* it. III's discipline forbids a seal that only ever asserts itself —
   so the certificate ships with the re-prover that regenerates it, and the two must agree.

The seal/witness machinery here does the thing it is genuinely good at — sealing a proof — rather than
being contorted into an execution engine.

---

## 6. The nous correction (precise)

**Current `nous_policy` is confluence-safe and needs no rescue.** It preserves the R-block cascade order
exactly (ADR-N11) and only block-swaps the trit block (kinds 25–29), which is LHS-disjoint from the
R-rules (no critical pairs). R001×R008's non-join — a subterm overlap — is irrelevant to a policy that
never reorders R001 against R008. The draft's "the set is not certified, it is claimed" mis-locates the
problem.

**What IS owed:**
- **Honesty fix (cheap):** `nous_policy`'s header phrase *"certified-reorderable rules (R001–R044 +
  trit)"* over-claims. R001–R044 within-block reorderability is neither exercised nor certified; only the
  disjoint trit block moves. Reword to "kind-aware block reorder: trit block (LHS-disjoint, freely
  movable) relative to the R-block (cascade order preserved)."
- **Forward payload (the real value):** line 22's planned ADR-N2 model — *"reorder within a
  confluence-equivalence class"* — is the genuine future client of Tier 2. The certificate's derived
  equivalence classes define precisely the within-R-block reorderings that preserve the normal form;
  R001 and R008 fall in **different** classes (their subterm interaction is order-sensitive). Until
  ADR-N2 lands, this is latent; the certificate makes it ready, not urgent.

This is the honest version of "decide confluence unblocks nous": it does not unblock a current hazard
(there is none) — it equips the *future* reorderer with proven equivalence classes instead of an
asserted set.

---

## 7. Fullness of the system — what the certificate touches

The draft scoped the certificate to nous + H12. The certificate's grades have system-wide consequences
that must be stated, because different clients need different grades.

- **Content-addressing (`numera/cad`, value identity = NF mhash).** Identity is the *syntactic* NF's
  mhash. This depends only on **Tier 1 determinism** (same term → same NF → same address), **not** on
  confluence. Consequence of non-confluence: content-addressing may **under-deduplicate** (two
  semantically-equal terms that canonicalise to different NFs get different addresses) — but it **never
  mis-identifies** (it never calls distinct things equal). Grade-S/R discharges (unique syntactic NF)
  preserve full addressing fidelity; **Grade-C discharges do NOT** restore address equality (the NFs
  stay syntactically distinct). So `cad` relies on the **S+R syntactic core**, never on C.
- **Federation / multi-node reproducibility (`aether/*`, consensus, bit-identity).** Nodes agree on the
  NF because they **all run the same `xii_canonicalise`** (one engine, H4) — Tier 1 alone, confluence
  not required. *But* the moment heterogeneous proposers (different nous models per node) reorder rules,
  agreement requires the reordering to stay within the certificate's **equivalence classes** (S/R for
  syntactic agreement; C only if the consensus compares under cost). This is the federation reason the
  equivalence-class output (§6) matters beyond a single node.
- **The H-charter.** H4 ("one engine") is what makes fixed-strategy determinism federation-safe; H12
  ("determinism") is upgraded by the certificate. The certificate should be consumed by `run_charter`
  as the H12 body (§5); H4 should cite it as proof that the one engine is a *deterministic normaliser*.
- **The proof kernel (`TYPES/cic.c`, `numera/safety_type`).** III re-checks every proof. The discharge
  proofs (reachability, cost-equivalence) are first-class proof obligations; the deep re-prover (§5) is
  their re-checker. A route-S discharge is special — it needs no standing proof because the construction
  removes the rule; it is the only grade that *cannot* silently regress, which is why it is preferred.
- **The manifest / seal (`xii_manifest.bin`, the retired `CRY-XII-CONF-001`).** The manifest must carry
  *this* certificate in place of the false global-confluence crystal. DOCS/III-XII.md §9.2–§9.4 already
  state the retraction; the manifest reseal completes it.
- **Bit-identity / the determinism gate.** Building the certificate is **additive** (a sealed object +
  consumers), and must not perturb engine codegen — except route S, which intentionally changes the
  canonical form and therefore requires a full `build_iiis*`→reseal pass under the crash/determinism
  protocol. Tiers 0–2 (minus route S) are seal-neutral; route S is the one determinism-critical edit.

---

## 8. Failure modes and bounded responses

A pair fails Tier 2 when it is reachable (R fails), structurally essential (S inapplicable or too
costly), and genuinely cost-divergent (C fails) — i.e. the two NFs are relied upon to be equal but are
not equal under any defensible cost relation. **This is a true soundness hole, and finding it is a gift
— it was present whether or not you looked.** Responses, all bounded and chosen in advance, so an
impasse is impossible:

1. **Eject** the offending rule from the reorder-equivalence class — shrinks the core, keeps it sound.
2. **Route T** (targeted KB) for that one pair.
3. **Widen the cost-equivalence relation** — *only* if the two forms truly are interchangeable for every
   client of §7 (in particular, never to paper over a content-address distinction `cad` depends on).
4. **Route S retrofit** — if the pair is assoc-involved, make it structural and remove the rule.

Every outcome routes to a defined next action; the certificate records which was taken.

---

## 9. Module map

**Consumed (existing):** `omnia/xii_termination` (Tier 0), `omnia/xii_canonicalise` (Tier 1 strategy +
route-S host), `omnia/xii_critpair_enum`, `omnia/xii_rule_overlap`, `omnia/xii_joinability` (the
non-joining partition + `xjn_njtab_*` diagnostics), `numera/cost_lattice` (route C), `numera/cad`
(certificate content-addressing), `omnia/xii_admission` (`xad_globally_confluent`=0, already honest),
`nous_policy` (equivalence-class consumer).

**Built (new):**
- `omnia/xii_strategy_det` — the Tier-1 strategy-determinism proof object (one strategy ⇒ one value);
  the cheapest, first to land, licenses H12 immediately.
- `omnia/xii_discharge` — the per-pair prover: try S → R → C, emit grade + proof; the deep re-prover.
- `omnia/xii_conf_cert` — the sealed, content-addressed, witnessed certificate object (rule-*semantics*
  mhash, graded pairs, equivalence classes).
- `numera/h12_charter` body extension — verify `cert.rule_mhash == live_rule_mhash` at boot.
- (Route S, if chosen) the canonical-associativity constructor change in `omnia/xii_term` +
  `xii_rewrite` R001–R004 retirement + the bootstrap reseal.

---

## 10. Definition of done and the clause it licenses

Done when: every non-joining pair from the full 40-rule enumeration is graded S/R/C **or** recorded as a
boundary pair with its §8 response chosen; the derived equivalence classes are sealed into the
certificate and consumed by `nous_policy`; the certificate binds the rule *semantics* mhash; the deep
re-prover regenerates the certificate and agrees with the seal; and `run_charter` H12 verifies by hash
comparison at boot.

At that point H12 reads, truthfully and in calibrated language:

> *XII normalisation is **deterministic by fixed strategy** (Tier 1, unconditional); **innermost-confluent**
> (root-local confluence + bottom-up + termination); **confluent on the certified core C**, graded S/R/C
> per pair; and the complement of C is **enumerated, witnessed, and bounded**, each boundary pair carrying
> its chosen response.*

That is what a trustworthy autonomous system says about itself. It does not claim global confluence,
which it lacks and does not need. It claims it **knows and witnesses its own boundary** — the stronger
and the only honest thing to claim.

---

## 11. Decision log

- **ADR-C1.** Route 2 ("measure the core"), not route 1 (KB), as the default — KB risks non-termination;
  the core is the truthful artifact.
- **ADR-C2.** The core is **graded** (S/R/C), not binary — clients (§7) need to know discharge strength;
  `cad` relies on S+R, never C.
- **ADR-C3.** Structural elimination (route S) is preferred over reachability (route R) for assoc pairs —
  a construction cannot regress; a proof obligation can. Accept the determinism-critical reseal route S
  costs, for the 15 pairs it permanently closes.
- **ADR-C4.** The certificate binds rule **semantics** mhash, not the structural pattern table.
- **ADR-C5.** Two verification depths: hash-match at boot, re-prove deep. No self-asserting seal.
- **ADR-C6.** `nous_policy` current behaviour is safe; fix only the over-claiming wording now; the
  equivalence classes are a forward payload for ADR-N2.

## 12. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Route S regresses the canonical form / breaks consumers | determinism seal drift; corpus red | full `build_iiis*` + fixpoint + corpus under the crash protocol; route S is opt-in per the 15 pairs |
| Reachability proof (route R) is unmaintained, rules drift | a Grade-R discharge silently becomes false | the rule-semantics mhash bind (ADR-C4) + deep re-prove (ADR-C5) catch drift loudly |
| Cost-equivalence (route C) widened to paper over a real distinction | `cad` under/mis-dedup | §8(3) forbids widening past any §7 client's needs; C never counts toward the syntactic core |
| A boundary pair is a true soundness hole | latent wrong-equality somewhere | §8 — finding it is the win; eject/Tier-3/widen, all bounded |
| Certificate proves the pattern table, not the semantics | guard/RHS change escapes | ADR-C4 |

## 13. Roadmap

1. `xii_strategy_det` (Tier 1 object) → H12 reads "deterministic by fixed strategy" **now**.
2. `xii_discharge` route lattice S→R→C over the 35 pairs → grade every pair; identify any boundary.
3. `xii_conf_cert` sealed object + `nous_policy` equivalence-class consumption + wording fix.
4. H12 body = hash-match; deep re-prover wired to CI.
5. (Optional, perfect) route S for the 15 assoc pairs → bootstrap reseal → upgrade their grade to S.
6. Manifest carries the certificate; retire `xii_critpairs`.
