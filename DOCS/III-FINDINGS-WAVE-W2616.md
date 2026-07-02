# III Findings Wave W2616 — recovered from the rate-limited discovery workflow (wf_2616d435-59b)
> **STATUS: HISTORICAL RECORD** — crash forensics / closed findings of their era; the fixes are landed and gated (reunification W6).

70 unique grounded findings (discover agents read real code; verify phase rate-limited, so hand-verify
each here, default-skeptical). Status: [ ] todo, [x] fixed, [~] verified-not-real/declined, [D] deferred.

## TIER 1 — accessor-bounds OOB / cold-init hardening (proven-valuable, safe sibling-guard pattern)
- [x] nous_conjecture:48,60,92 (sev5) — nc_add_rule/nc_reach_into/nc_creates_cycle symbol >= NC_MAX_SYM OOB. FIXED.
- [ ] matrix_ring:55 (sev4) — mat_mul/mat_eq index MAT_E[8*4] by untrusted slot ids, no bound.
- [ ] hamming_secded:120 (sev4) — ham_decode OOB write HAM_BITS[72] on syndrome>71 (3+ bit errors).
- [ ] temporal_logic:302 (sev3) — tl_trace_eval len==0 underflows ll-1 -> ~2^64 loop.
- [ ] temporal_logic:512 (sev3) — tl_trace_eval forwards untrusted formula_slot into tl_kat_run unbounded.
- [ ] coin_change:38 (sev3) — coin_dp(amt) OOB COIN_DP[21] for amt>=21.
- [ ] catalan:35 (sev3) — catalan_conv/formula OOB CATALAN_C[12] for n>=12 + u32 overflow.
- [ ] hdl:233,366 (sev3) — hdl_set_a/hdl_set_b store unchecked target; hdl_opt_dn/idem read HG_KIND[g] unbounded.
- [ ] fp256:267 (sev3) — fp_*_x slot-arith exports lack the slot bound the setters carry (fp384 too).
- [ ] taint_analysis:99 (sev3) — taint_sink_violates unchecked node index (siblings bound i<TNT_CAP).
- [ ] mcmc_egraph:61 (sev3) — mcmc_cost/greedy/search read MCMC_COST[64] unchecked.
- [ ] pareto_frontier:73 (sev3) — pf_dominates indexes PF_LAT/PF_ENE[6] unchecked.
- [ ] lzss:111 (sev3) — lzss_decompress reads ip[inp+1] match token w/o 2-bytes-remain check (OOB read).
- [ ] threshold_vault:67 (sev2) — tv_keyshare_ptr returns &TV_KEYSH+i*32 unchecked (sibling _x bounds i).
- [ ] identifier:53 (sev2) — ident_cmp deref a/b without the null guard siblings have.
- [ ] cap_forge:379 (sev2) — cf_forge_restrict deref sub_resource/out_cap without null guards.
- [ ] mlkem:636 (sev2) — ML-KEM @export deref pk/sk/ct/ss/seed/coins with no null guard (+ mldsa).
- [ ] mldsa:863 (sev2) — iii_mldsa_keygen/sign/verify never validate level; non-{2,3,5} -> silent ML-DSA-87.
- [ ] bft_quorum:38 (sev2) — bq_min_overlap_ok shifts by untrusted nbits (UB nbits>=32 + 2^nbits scan).
- [ ] bmc:58 (sev2) — bmc_* use untrusted target/bad as shift count (UB >=32).
- [ ] hotstuff_predict:36 (sev2) — hsp_init f=(n-1)/3 no n==0 guard -> underflow (hs_init same pattern).

## TIER 2 — correctness defects (need careful verification/fix)
- [x] xii_curated_extended:57,60 (sev5/4) -- H052 bitreverse x86 was a 1-bit ROTATE; ARM64 str x0,[x0] mem-corruption. FIXED: x86 full SWAR bit-reverse (gcc-assembled, objdump-lifted, OFFLINE-EXECUTED: bitrev(1)=msb + involution), ARM64 ldr x1/rbit x1/str x1,[x0]. Live-served (id 51 > chokepoint 24). KAT 1606 EXIT=99.
- [x] xii_emit_gen:308 (sev4) -- _structural_body wrote the full (<=20-byte) kernel fragment to out BEFORE the body_size check -> OOB WRITE for small expected_size ([plen+elen, plen+frag-1]). FIXED: emit to a bounded scratch + copy min(frag_len, max_avail=expected_size-body_start). Proven byte-IDENTICAL at 256 (full-catalog sha256 0x160AF7F2 unchanged) and differential: KAT 1609 returns 100 (canary clobbered) on the old path, 99 on the fixed path.
- [x] babel_wire:201,265 (sev3/4) -- payload-read OOB: unpack_payload_byte trusts header-claimed payload_len with no in_len; cap_accept_offer (live consumer) read 32 payload bytes without checking offer_len>=100. FIXED: babel_wire_verify_len(in_buf,in_len) gate (overflow-safe, returns 1 iff in_len>=68+plen), wired into cap_accept_offer. idoc_resolve_facet/facet_count take no in_len -> documented as caller-must-gate. Payload AUTHENTICATION (CRC covers header only) is a separate wire-format change, not done here. KAT 1608 EXIT=99.
- [ ] capability:230 (sev3) — cap_is_revoked doesn't walk parent chain (descendant of revoked reports live).
- [x] capability:244 (sev3) -- cap_drop ABA: id=slot+1 and cap_alloc_slot reuses freed slots, so dropping a cap with live descendants lets a later attenuate re-mint the id and silently re-parent them. FIXED: refuse drop while live descendants exist (bottom-up). KAT 1607 EXIT=99.
- [ ] enclave:68 (sev3) — enc_declare accepts inverted region (lo>=hi), returns OK protecting nothing.
- [ ] fed_eclipse:142 (sev3) — eclipse gate default-OPEN when unconfigured (should fail-closed).
- [~] vectorizer:61 (sev3) -- vz_equivalent (1u32<<n) for n>=32 is UB but FAILS SAFE (grouping always equivalent for valid inputs -> only a conservative scalar fallback, never unsound). Set aside as UB-hygiene, not a soundness defect.
- [ ] nous_conjecture_gen:52 (sev3) — NG_SQ_GE predicate u32 overflow -> spurious counterexample.
- [ ] sieve:62 / collatz:29 / goldbach:53 / affine_check:65 / chacha20_poly1305:100 — u32 overflow/range.
- [ ] xii_lattice:196 (sev3) — lookup uses 0 for both unset and valid cell idx 0 (sentinel collision).
- [ ] xii_curated_riscv:41 (sev3) — XCR_H058 declared [u8;16] but 20 elements initialized.
- [ ] hmac:123 (sev2) — hmac_sha256 leaves outer hash mid-computation in shared singleton.
- [ ] nous_commons:93 (sev3) — content cert omits the KEY -> key-substitution passes re-verify.
- [ ] nous_value:62 (sev3) — weights-addr content-addresses advisory constants not the ranker order.

## TIER 3 — capability gaps / stub / doc-overclaim (judgment + larger effort)
- [ ] fed_genesis:260 (sev4) — FOUNDERS-ANCHOR pubkey=SHA256(domain), no private key (verify intent first).
- [ ] founders_anchor:42 (sev3) — SUITE_SWAP authority declared, never implemented ("seven" but six exist).
- [ ] zk_snark:238 (sev3) — Groth16 setup/prove/verify non-@export; only selftest exposed.
- [ ] aes_siv:131 (sev3) — single-AD only; RFC 5297 S2V is vector AD1..ADn.
- [ ] huffman:174 (sev3) — encoder fails on code length >64; docstring overclaims.
- [ ] nous_synth:103,107 / nous_completion:97,233 / handle:78 / cost_overrun:272 / math_library_curation:34 — stub/capability.
- [ ] DOC: bigint:20, xii_mig4_seal:187, xii_rewrite:5, xii_curated_extended:24, xii_lattice:19, pq_params:9, synthesis_spec:768, zip:9, xii_horizon:135, nous_policy:83, nous_commons:177 — stale/overclaim docstrings.

NOTE: mlkem:697 (FO implicit-reject secret-dependent branch) — sev3 hardening, constant-time; verify against the module's stated obliviousness stance before touching (delicate, KAT-anchored).
