# III-GENESIS-VECTOR — Polymorphic Deployment Installer

**Spec:** `DOCS/III-GENESIS-VECTOR.md` (Wave 10.2, item 177)

The legitimate-channel deployment vector: operator-owned code-signing
certificates (DigiCert / Sectigo / GlobalSign / Comodo / Apple Developer ID /
GPG), polymorphic packaging per platform (MSI / DEB / RPM / PKG), Trinity
pre-discharge bundle, software-only DRTM relaunch, and post-install
verification.  No exploits.  No misrepresentation.  Full operator legal
accountability via legitimate signing.

## Test

```
$ ./build/iii_genesis_test
=== 25 passed, 0 failed ===
```

## Conformance (§9)

| Code | Status |
| --- | --- |
| C-GV-1 | ✅ certificate validity (issuer, period, revocation) |
| C-GV-2 | ✅ Trinity pre-discharge bundle: 4-flag check + bundle mhash |
| C-GV-3 | ✅ entry rejects unsigned / revoked / Trinity-incomplete |
| C-GV-4 | ✅ software DRTM relaunch returns quote_mhash bound to closure root + bundle |
| C-GV-5 | ✅ verify reports binary / closure / cert / DRTM-consistency outcome |
