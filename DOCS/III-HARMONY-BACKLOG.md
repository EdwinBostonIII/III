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
| 6 | Witness the Reach: proof-carrying reach/emit + witnessed proof-of-absence | build-only | medium | low | **DONE** -- `reach_emit_witnessed`/`reach_witnessed` + the honest `REACH_UNWITNESSED` contract (wh_publish failure surfaced, never silent); KAT `1258`=99 (pre-init honesty teeth / bound emit+get fragments / 0x4D proof-of-absence / deny-silent). |
| 7 | Kernel-disposed congruence merge: e-graph proof_ok from tc_conv | build-only | medium | low | **DONE** -- `eg_union_kernel` (tc_conv disposes the external e-graph merge); KAT `1334`=99 (kernel merge / false-goal refused untouched / auto-congruence / SENT refused). |
| 8 | Width-faithful proof-carrying e-graph rules: gate eg_register_rule via BV64 two-tier | build-only | medium | low | **DONE** -- `bvd_register_rule` (two-tier BV64 gate before eg_register_rule; schematic denotations cover every instantiation); KAT `1335`=99 (admit+fire-live / Tier-1 veto / no-slot-consumed / refused rule never enters). |
| 9 | Inductive engine → Theorem Commons: learned kernel-proven universals become citable | none | medium | low | **DONE** -- `ind_forall_commons`/`_w_commons`/`_id_commons` + cite duals (Pi-closed universals admitted via tcom_admit_goal; Id limb = FULL transport universal, J under two binders); KAT `1336`=99 (9 arms, all three limbs). |
| 10 | Proof-carrying Montgomery-constant registry: BV64 certifies mod-2^32 REDC constant | none | medium | low | **DONE** -- `mont_nprime_certified` (BV64 two-tier via the lossless (n0*np+1)<<32==0 mod-2^64 lift) gates `modctx_set_nprime` storage; a live mod-ctx structurally cannot hold a wrong REDC constant; KAT `1337`=99 (Newton+kernel agree / free-reduction / off-by-one+even refused / registry teeth). |
| 11 | Composite-safe bigint extended-Euclid modular inverse (close Fermat-only soundness) | none | medium | low | **DONE** -- `fp_inv` (all-residue extended Euclid: Bezout coeff tracked mod m, refuses gcd!=1) + fp_div rewired; KAT `1338`=99 incl. THE BITE (Fermat wrong on 91, Euclid right) + multi-limb 2^64+1. |
| 12 | Merkle attestation root + succinct membership proofs for the Commons | build-only | medium | low | **DONE** -- `tcom_merkle_root`/`tcom_goal_slot`/`tcom_merkle_prove`/`tcom_merkle_verify` (composes the numera merkle organ, 1024==TCOM_MAX); stateless O(log n) membership; KAT `1339`=99 (end-to-end peer flow + forged/wrong-slot/stale teeth). |
| 13 | Discharge the memoization optimization with a proof_memo_equiv differential | none | medium | low | **DONE** -- `mq_attest_equiv` (the proof_memo_equiv differential: EQUIV witnessed on the spine; DIVERGED -> ml_mark_stale eviction + MQ_E_DIVERGED); KAT `1340`=99 (discharge / spine grew / eviction permanent / absent+null guards). |
| 14 | Wire backend_remote L4 fetch to http_client's RFC 7230 parser (chunked/Content-Length) | build-only | medium | medium | **DONE** -- `backend_remote_decode` routes the L4 body through http_client's RFC 7230 sec 3.3.3 parser (chunked decoded, Content-Length honored, EOF kept); response cap 4K->69K; KAT `1341`=99 (framing-exact, 404/garbage=absence, refuse-not-truncate, deterministic). |
| 15 | Promote reach_oracle PROVISIONAL into a first-class contagious SV_STATUS | build-only | medium | medium | **DONE** -- SV_STATUS lattice REFUSED>PROVISIONAL>OK, contagious through sv_op (refused-input laundering closed), status committed into the witness; `reach_oracle_make_sovval` completes the pre-declared fold; KAT `1342`=99 (8 arms). |
| 16 | Kernel-governed congruence RING: discharge the threaded proof_ok via tc_check | build-only | medium | medium | **DONE** -- `cgr_union_kernel` (tc_check in-module; completes the kernel-disposal family across ripple_unify/e-graph/ring); KAT `1343`=99. |
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

Wave 6-16 GATED 2026-06-09: build_stdlib 570/0 (lib 475cd783); all 11 KATs =99; FULL corpus PASS=947 FAIL=0 zero WRONG; no reseal (compiler-unreferenced additions).

Full per-item detail (change + falsifier + vet) in the workflow run record `wnb2lfl3o.output`.
