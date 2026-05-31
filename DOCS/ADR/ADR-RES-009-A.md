# ADR-RES-009-A — Resolver Seal: Coefficient-Table Refreeze (supersedes ADR-RES-009)

## Status

ACCEPTED. Supersedes **ADR-RES-009** (which remains the architecture of record for the two-seal
design; this ADR corrects the frozen coefficient encoding only).

## Context

The Structural Audit (KEEP-1) found that the frozen coefficient table sealed by
`SEAL_RESOLVER.mhash` does **not decode to its documented magnitudes**. Per-row decode of
`sanctus/seal_resolver.iii::COEFF_TABLE_BYTES` (33 × u64, little-endian, 264 bytes) shows 27 of 33
rows correct and **6 rows drifted by a transcription typo** (not a deliberate value):

| Coefficient(s) | Documented | Frozen bytes (LE) | Decoded (wrong) | Corrected bytes (LE) |
|---|---|---|---|---|
| COMPOSE / PASSAGE / ESSENCE / MOTION / SUBSTANCE base | 900,000,000 | `00 35 A4 35` | 899,953,920 | `00 E9 A4 35` |
| P_EFFECTS_UNDECLARED | 700,000,000 | `00 FF 7E 29` | 696,188,672 | `00 27 B9 29` |

The five 900M rows carried `0x35` in byte[1] — a copy of byte[3] — where `0xE9` belongs
(900,000,000 = `0x35A4E900`). The 700M row carried `0x297EFF00` where `0x29B92700` belongs.

ADR-RES-009 also names the coefficient source as `omnia/resolver.iii` (`COEFF_TABLE_BEGIN..END`),
while the realized seal hashes the table embedded in `sanctus/seal_resolver.iii`; and ADR-RES-001
states the seal "hashes `omnia/resolver.iii`'s source bytes", which the implementation does not.
This ADR reconciles both to the realized derivation.

## Decision

1. **The documented magnitudes are canonical.** They are the system K-values (1.00, 0.90, 0.50,
   … scaled ×1e9) used identically across `omnia/resolution_init.iii` (`_meta_register` non-root
   activation base = `900000000`) and `sanctus/calculus_v1.iii`. The drifted bytes were never a
   value decision; they are corrected to encode the documented magnitudes exactly.

2. **Recompute the frozen array** so every row's little-endian u64 decodes to its comment
   (`seal_resolver_coeff_u64(idx)` is the authoritative decoder; corpus 951 asserts the equality).

3. **Seal derivation of record** (correcting ADR-RES-009 §Decision and the ADR-RES-001 claim):
   `SEAL_RESOLVER.mhash = mhash( "SEAL_RESOLVER\0\0\0" || COEFF_TABLE_BYTES(264) ||
   each occupied 168-byte registry slot || the 5 mhash-domain strings(80) )`, computed by
   `sanctus/seal_resolver.iii::seal_resolver_compute()`. The coefficient bytes live in
   `seal_resolver.iii` (not `omnia/resolver.iii`); the seal covers *those* bytes.

4. **Reissue the seal.** `seal_resolver_verify()` is self-consistent (snapshot → recompute →
   byte-compare), and no artifact pins the prior seal value (no golden constant, no corpus byte
   assertion — verified tree-wide), so the reissue is a pure recompute: the seal value moves once,
   transparently, with no dependent break. Q7 check (d) and M22 continue to pass (they assert
   self-consistency, not a fixed value).

## Consequences

- The resolver seal value changes once (the corrected table). The closure root that absorbs it
  (`closure_compute_with_resolver`) recomputes consistently; both remain drift-gated.
- A future reader who sees `899,953,920` / `696,188,672` decoded from these bytes would (rightly)
  flag drift; after this refreeze the bytes decode exactly to the documented magnitudes, removing
  the false-drift trap.

## Falsifier

`corpus/951_seal_resolver_refreeze.iii`: (a) every decoded coefficient equals its documented
magnitude — in particular the six corrected rows (`seal_resolver_coeff_u64(2)==900000000`,
`(28)==700000000`); (b) the seal **binds** the table — flipping any coefficient byte changes the
recomputed seal, and restoring it returns the original (proving the seal is not vacuous over the
coefficients).

## Lineage

Supersedes ADR-RES-009 (FROZEN). Authored at Structural-Audit Wave 5 (W5.3 / KEEP-1).
