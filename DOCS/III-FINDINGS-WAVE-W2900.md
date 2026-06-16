# III Findings Wave W2900 — coverage/proof strengthening (renewable loop pivot)

After the defect/perf axes saturated (yields 13->5->1->14-negligible), the loop pivoted to coverage
strengthening: a discovery Workflow (40 agents) found weak/shallow KATs + un-asserted negative/property
paths, classified strengthen-vs-latent-defect. Pure KAT additions cannot regress product code; the
latent-defect class still surfaces real bugs (like the W72-80 false-accepts).

## Latent defect FIXED
- [x] **numera.pbkdf2 pbkdf2_sha256_set_iter** -- accepted c=0 silently (RFC 8018 5.2: c MUST be >= 1);
  since U_1 is computed before the fold loop, c=0 produced byte-identical output to c=1 -- a weak-key
  on misconfiguration. The sibling setters set_salt/derive validate their params; set_iter did not.
  FIXED: reject c==0 with PBKDF2_E_INIT. KAT 1613.

## Coverage strengthened (negative-path / defining-property KATs, all PASS)
- [x] numera.hex.hex_encode null-src/null-out guards (KAT 1614)
- [x] aether.babel_wire.set_ctx_digest / set_payload null-source guards (KAT 1614)
- [x] aether.fed_seal.fed_seal_anchor parent-must-be-strictly-higher-tier (pt<=ct -> E_BADTIER) (KAT 1615)
- [x] omnia.resolver.pr_less_than_cr strict ring precedence RM2<RM1<R0<R3 (reflexive/antisymmetric) (KAT 1616)
- [x] aether.enclave.enc_declare degenerate-region (lo>=hi -> E_REFUSED, the W2616 guard) + admit gate (KAT 1617)

## Coverage strengthened (micro-batch 2)
- [x] verba.format.format_literal null-base-with-len>0 -> FMT_E_NULL (KAT 1618, builder+arena fixture)
- [x] aether.hotstuff.hs_handle_vote Byzantine equivocation: a VALIDLY-signed vote over a conflicting
  block (!= the bound HS_VOTE_BLOCK) is rejected HS_E_BAD_QC -- non-tautological (the KAT proves the
  Ed25519 sig is valid via an independent ed25519_verify, then shows the vote refused). KAT 1619.

All 10 coverage findings from the discovery workflow are now addressed (1 latent defect fixed + 9
negative-path/property KATs).
