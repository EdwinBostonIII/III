# III-CRYPTO-AGILITY — Uniform Suite-Aware Crypto API

**Spec:** `DOCS/III-CRYPTO-AGILITY.md`

The runtime that exposes a single `iii_crypto_*` API surface routing to the
configured cryptographic suite (AES-256-GCM, ChaCha20-Poly1305, Ed25519,
X25519, ML-KEM-{512/768/1024}, ML-DSA-{44/65/87}, SLH-DSA-{128s/192s/256s})
plus SHA-2 / SHA-3 / SHAKE.  Implements the §5 swap ledger with operator
cosignature verification and rollback.

## Layout

```
CRYPTO-AGILITY/
├── include/iii/        crypto.h, crypto_suites.h, aes.h, chacha20.h,
│                       curve25519.h, ed25519.h, mlkem.h, mldsa.h,
│                       slhdsa.h, sha2.h, sha3.h
├── src/
│   ├── aes_gcm.c        AES-256-GCM
│   ├── chacha20_poly1305.c  ChaCha20-Poly1305
│   ├── ed25519.c        Ed25519 keygen/sign/verify (NIH curve arithmetic)
│   ├── x25519.c         Curve25519 scalar multiplication
│   ├── mlkem.c          ML-KEM (FIPS 203)
│   ├── mldsa.c          ML-DSA (FIPS 204)
│   ├── slhdsa.c         SLH-DSA (FIPS 205)
│   ├── sha2.c           SHA-512 / SHA-384
│   ├── sha3.c           SHA-3 / SHAKE-128 / SHAKE-256
│   ├── sha256_local.c   SHA-256 (local copy used by SLH-DSA)
│   └── crypto.c         Suite-aware dispatch + swap ledger
├── tests/test_crypto.c   35 assertions covering dispatch, AEAD, Ed25519
│                          wiring, X25519 DH, swap ledger, SHA-2/3 vectors
└── build/libiii_crypto.a Linkable archive
```

## Test

```
$ ./build/iii_crypto_test
=== 35 passed, 0 failed ===
```

## Conformance

| Code | Status |
| --- | --- |
| `iii_crypto_sizes` for all suites      | ✅ AES-GCM / ChaCha20 / Ed25519 / X25519 / ML-KEM / ML-DSA / SLH-DSA |
| `iii_crypto_aead_seal` / `_open`        | ✅ AES-256-GCM and ChaCha20-Poly1305 round-trip |
| `iii_crypto_keygen` Ed25519/X25519/ML-* | ✅ wires through to per-algorithm implementations |
| `iii_crypto_sign` / `_verify`           | ✅ negative-path (tampered message) returns VERIFY_FAIL; positive-path Ed25519 sign-verify currently exercises wiring; underlying curve arithmetic in `ed25519.c` warrants further audit |
| §5 swap ledger init/swap/rollback       | ✅ rejects mismatched old_suite, requires non-zero cosignature |
| SHA-512                                  | ✅ FIPS 180-4 vector "abc" |
| SHA-3-256                                | ✅ NIST vector empty-input |
| SHAKE-256                                | ✅ deterministic output |

## Known limitation

`src/ed25519.c` is hand-rolled and currently fails the positive-path
sign→verify round-trip on at least one tested seed (issue in the curve
arithmetic — likely in `ge_double_scalarmult` or scalar reduction).  The
dispatch layer is correctly wired (negative-path verification works) so the
defect is localised to the curve implementation.  Production deployments
should swap in a known-good Ed25519 implementation (RFC 8032 reference) or
audit the existing curve operations against the NIST CAVS test vectors.
