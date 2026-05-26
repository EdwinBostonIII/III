# Cryptographic Primitive Inventory

Every cryptographic primitive in the substrate's native `.iii` STDLIB, with its
canonical file and KAT/corpus coverage. The discipline (D3 / NIH): the substrate
links **no** external cryptographic library; every primitive is hand-rolled in
`.iii` over libc + arena only. This inventory is grounded in the actual
`STDLIB/iii/numera/` tree (not the idealized `crypt/` namespace of the source
plan).

## Hashes

| Algorithm | File | KAT |
|-----------|------|-----|
| SHA-256 | `numera/sha256.iii` (+ `sha256_dispatch.iii`) | FIPS 180-4; corpus 02/15 |
| SHA-512 | `numera/sha512.iii` | FIPS 180-4 |
| SHA3-256 | `numera/sha3_256.iii` | FIPS 202 |
| SHA3-512 | `numera/sha3_512.iii` | FIPS 202 |
| Keccak-f1600 | `numera/keccak.iii` | FIPS 202 |
| SHAKE-128 / SHAKE-256 | `numera/shake128.iii`, `shake256.iii` | FIPS 202 (XOF; used by ML-KEM/ML-DSA/SLH-DSA) |
| BLAKE2s | `numera/blake2s.iii` | RFC 7693 |

## MAC / KDF / DRBG

| Algorithm | File | KAT |
|-----------|------|-----|
| HMAC (SHA-256 / SHA-512) | `numera/hmac.iii` | RFC 4231; corpus 203 |
| Poly1305 | `numera/poly1305.iii` | RFC 8439 |
| HMAC-DRBG-SHA-512 + RDRAND/RDSEED | `numera/drbg.iii` | SP 800-90A; corpus 204/205 |

## Symmetric / AEAD

| Algorithm | File | KAT |
|-----------|------|-----|
| AES-128/256 (+ derived S-box) | `numera/aes.iii` | FIPS 197 |
| AES-GCM | `numera/aes_gcm.iii` | NIST GCM vectors |
| AES-SIV-CMAC-256 | `numera/aes_siv.iii` | RFC 5297; corpus 207 |
| ChaCha20 / HChaCha20 | `numera/chacha20.iii` | RFC 8439 |
| ChaCha20-Poly1305 | `numera/chacha20_poly1305.iii` | RFC 8439 |
| XChaCha20-Poly1305 | `numera/xchacha20_poly1305.iii` | draft-irtf-cfrg-xchacha; corpus 206 |

## Asymmetric (classical)

| Algorithm | File | Status |
|-----------|------|--------|
| Ed25519 sign + verify | `numera/crypt_ed25519.iii` | sign added §4.1; RFC 8032 §7.1 |
| X25519 | `numera/x25519.iii` | RFC 7748 |
| ECDSA P-256 | `numera/ecdsa_p256.iii` (+ `fp256`/`fn256`/`ec256`) | SEALED; corpus 208 (const-time Montgomery CIOS, RCB add) |
| ECDSA P-384 | `numera/ecdsa_p384.iii` (+ `fp384`/`fn384`/`ec384`) | SEALED; corpus 209 |
| RSA-3072/4096 RSASSA-PSS | `numera/rsa.iii` | **WIP** — EMSA-PSS/MGF1 self-test passes; modexp has an open value-dependent fault (forward-ref #1/#2); own Montgomery modexp in progress |

## Asymmetric (post-quantum, FIPS 203/204/205)

| Algorithm | File | Status |
|-----------|------|--------|
| ML-KEM (Kyber) 512/768/1024 | `numera/mlkem.iii` | native NTT q=3329, FO transform |
| ML-DSA (Dilithium) 44/65/87 | `numera/mldsa.iii` | native NTT q=8380417 |
| SLH-DSA (SPHINCS+) | `numera/slhdsa.iii` | WOTS+/FORS/XMSS/hypertree |

## Notes

- The substrate's canonical hash for content-addressing/witness is **SHA-256**
  today; the idealized plan's "migrate everything to Keccak-256 + delete
  keccak_alt" does **not** match reality — there is exactly one `keccak.iii`
  and no `keccak_alt.iii`, and SHA-256 is load-bearing (closure roots, SEAL).
  No consolidation churn is warranted.
- The §4 KAT vectors that pass (corpus 198–209) are candidate entries for
  `DOCS/MATH_LIBRARY_QUEUE.md` (forward-reference #10).
- SHA-256 is hand-rolled in 6+ places (codegen + subsystems); enforcing
  byte-identity across copies is **forward-reference #7** (§4.15).
