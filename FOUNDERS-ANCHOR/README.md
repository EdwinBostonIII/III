# III-FOUNDERS-ANCHOR — Structural Veto Layer (R-3)

> **C IMPLEMENTATION RETIRED (H13 "one language", 2026-06-06).** The C veto
> implementation (`src/founders_anchor.c`, `include/iii/founders_anchor.h`,
> `tests/`, `build/`) has been ported to `STDLIB/iii/numera/founders_anchor.iii`
> (faithful: identical Ed25519 directive encodings, SHA-256 fingerprint, Shamir
> GF(2^8) custody; corpus `1126_founders_anchor`=99). This directory is retained
> ONLY as the operator's **key-custody vault** — `SEALED_OPERATOR_SECRET/`,
> `anchor_pubkey.bin`, `anchor_seed.TESTONLY.bin`, `_GENESIS_CEREMONY_PENDING.md`
> are key material (NOT code) and are preserved. The runtime veto now lives in
> `.iii`; III guards its own founder in its own language.

**Spec:** `DOCS/III-FOUNDERS-ANCHOR.md` (Wave 0.5, item 178)

The structural Skynet-prevention layer.  An anchor public key is closure-
pinned at substrate genesis; the seven authorities (Tier-3 veto, DRTM
reset, pfs_deny_quote, suite-swap cosignature, witness injection, Catalyst
halt, promotion revocation) are gated by Anchor-signed directives at the
proof-kernel level (R-3).  Includes Shamir 2-of-3 secret-share split for
air-gapped key custody, plus the protocol-level invariant check that
rejects any proof certificate touching the closure-pinned anchor fields.

## Test

```
$ ./build/iii_founders_test
=== 24 passed, 0 failed ===
```

## Conformance

| Code | Status |
| --- | --- |
| C-FA-1 | ✅ public key + fingerprint, frozen flag |
| C-FA-2 | ✅ sign / verify / tampered-signature rejection |
| C-FA-3 | ✅ amend-apply: no-quorum / FNDR-VETO-MISSING / OK paths |
| C-FA-4 | ✅ DRTM reset / PFS deny / witness-inject / catalyst-halt / revoke verifications |
| C-FA-5 | ✅ Shamir 2-of-3 split + reconstruct (GF(2^8) AES poly) |
| C-FA-6 | ✅ invariant check rejects modify-pubkey / disable-PFK / synthesize-substitute |
| C-FA-7 | ✅ runtime halt / resume gates Catalyst |
