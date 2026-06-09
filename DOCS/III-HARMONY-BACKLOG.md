# III — Harmony Enhancement Backlog (continuous never-cease loop)

Produced by the `iii-harmony-discovery` workflow (76 agents, 7.8M tokens, 29 vetted of 76 raw), 2026-06-06.
Execution order = vet-rank (strong→viable), then seal-light, then small effort, then low risk. Each item:
implement fully (no placeholders) → compile → build_stdlib → item falsifier KAT → full corpus stays 830/0 zero
WRONG → reseal/re-root if needed → ledger → auto-continue. Preserve determinism, bit-identity, fixpoint,
trusted base, cg_seam at all times.

| # | item | seal | effort | risk | status |
|---|------|------|--------|------|--------|
| 1 | Kernel-disposed certified merge: tc_check discharges ripple_unify↔congruence proof_ok | none | small | low | **DONE** — `ru_certify_unify_kernel` + KAT `1243`=99 (3-arm: kernel-merge / false-goal refused / intent-veto). Also fixed pre-existing `costed_cat` cc_* ↔ cost_calculus collision (renamed→ccat_*). build 506/0. |
| 2 | bv_ring canonical content-address: pairwise decider → content-addressed normal form | build-only | small | low | **DONE** — `bv_canon_serialize` (normal form) + `bvd_canon_addr` (domain-sep, kernel-gated 32B class id); KAT `1246`=99 (8 arms). build 508/0. |
| 3 | Complete the inductive bridge: certified universals over W-types (wrec) + identity/path | none | small | low | **DONE** — `ind_forall_w` + `ind_forall_id` in induct.iii; KAT `1247`=99 (W±, Id± path-dependent motive). seal `f079dd81` unmoved. build 510/0. |
| 4 | Capability-preservation gate: optimizer never mints a capability (M3 bricking) | none | small | low | **DONE** — `omnia/xii_cap_preserve` (`xcp_gate`: cap_set(RHS)⊆cap_set(LHS) over all 45 rules + teeth); KAT `1251`=99. build 511/0. |
| 5 | Goal-bound Theorem Commons: content-address the kernel's serialized goal term | build-only | medium | low | **DONE** — `tc_serialize` (injective, OUTSIDE tc_to_ccl → seal `f079dd81` unmoved) + `tcom_admit_goal`/`tcom_cite_goal`; KAT `1252`=99 (binding + no-false-merge + false-goal rejected). build 511/0. |
| 6 | Witness the Reach: proof-carrying reach/emit + witnessed proof-of-absence | build-only | medium | low | TODO |
| 7 | Kernel-disposed congruence merge: e-graph proof_ok from tc_conv | build-only | medium | low | TODO |
| 8 | Width-faithful proof-carrying e-graph rules: gate eg_register_rule via BV64 two-tier | build-only | medium | low | TODO |
| 9 | Inductive engine → Theorem Commons: learned kernel-proven universals become citable | none | medium | low | TODO |
| 10 | Proof-carrying Montgomery-constant registry: BV64 certifies mod-2^32 REDC constant | none | medium | low | TODO |
| 11 | Composite-safe bigint extended-Euclid modular inverse (close Fermat-only soundness) | none | medium | low | TODO |
| 12 | Merkle attestation root + succinct membership proofs for the Commons | build-only | medium | low | TODO |
| 13 | Discharge the memoization optimization with a proof_memo_equiv differential | none | medium | low | TODO |
| 14 | Wire backend_remote L4 fetch to http_client's RFC 7230 parser (chunked/Content-Length) | build-only | medium | medium | TODO |
| 15 | Promote reach_oracle PROVISIONAL into a first-class contagious SV_STATUS | build-only | medium | medium | TODO |
| 16 | Kernel-governed congruence RING: discharge the threaded proof_ok via tc_check | build-only | medium | medium | TODO |
| 17 | Width-faithful Dream Sieve: route autocatalytic discovery through bv_dispose | none | large | medium | TODO |
| 18 | bv_bits: mixed arithmetic+bitwise equivalence decider (bit-blast → sat.iii) | none | large | medium | TODO |
| 19 | Proof-carrying FEDERATED Commons: kernel deserialize + tcom_receive re-checks peer proof | build-only | large | medium | TODO |
| 20 | General bigint Barrett reduction organ unifying ed_scalar_modl | none | large | medium | TODO |
| 21 | BV64 self-cancellation & idempotence iota: x-x=0, x^x=0, x&x=x, x\|x=x (trusted reducer) | trusted-base-reseal | medium | medium | TODO |
| 22 | bvlshr: add logical right-shift to the BV64 kernel model (cg_r3 SHR fold) | trusted-base-reseal | large | medium | TODO |
| 23 | Witness the fed_seal cross-tier anchor chain: replayable provenance | build-only | small | low | TODO |
| 24 | Wire bv_dispose into an autonomous WIDTH-FAITHFUL discovery loop | build-only | medium | low | TODO |
| 25 | Kernel-certified saturating duration algebra (tempora/duration overflow) | build-only | medium | low | TODO |
| 26 | Third verification strike: independent denotational gate for the IF-lift / equal-branch | none | medium | low | TODO |
| 27 | Cost-monotonicity gate: prove XII optimizer never increases summed K-cost | none | medium | low | TODO |
| 28 | Month-exact civil-date validity: injective calendar accept-domain | build-only | medium | low | TODO |
| 29 | Wire pattern.unify_fn into resolve(): activate the dead Robinson unification path | none | large | medium | TODO |

Full per-item detail (change + falsifier + vet) in the workflow run record `wnb2lfl3o.output`.
