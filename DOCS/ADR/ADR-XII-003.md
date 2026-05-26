# ADR-XII-003: Hexad-Resonant 144-Pattern Horizon Cardinality

## Status
Accepted (Phase XII-γ, sealed at Phase XII-ζ Ω12)

## Context

The Horizon Set is the closed, sealed catalog of canonical-form patterns for which the Lattice carries per-target machine code. The cardinality of this set must be:

- **Small enough** for human curation to be tractable (each pattern requires a math definition, hexad/K/cap metadata, structural template, and 7 per-target byte sequences).
- **Large enough** to cover the high-value compositions of the closed algebra (18 basis × 6 fusion = 24 operators) such that real workloads hit the Horizon on their hot paths.
- **Sealed** — frozen at day-zero and never expanded except via Catalyst-promoted append (per `DOCS/III-XII.md` S25 mutation discipline).

Earlier drafts of XII proposed Horizon sets of various sizes: 127 (arbitrary prime), 128 (power-of-two), 256 (one byte), 512. None were derived from substrate-intrinsic constants.

## Decision

**The Horizon Set is 144 patterns** = 6 × 24 = `|HEXAD_KINDS|` × `|XII_ALGEBRA|`.

This is a hexad-resonant cardinality. It is selected so:

1. **Each pattern occupies one cell** in a 6 × 24 matrix indexed by `(primary_hexad_kind, primary_operator)`. The matrix structure is the design.
2. **126 productive cells + 18 guard/reserved cells** (12 guard + 6 reserved). The 12 guard cells occupy intersections that are structurally forbidden (e.g., `(ORIGIN, F.COMPOSE)` per `H127`) and dispatch with `XII-CANON-099` rejection.
3. **The `xii_horizon_reach` bitmap is 144 bits = 18 bytes** — a hexad-resonant compact form (note: 18 = 6 × 3).
4. **The existing `xii_asym_reach6` HEXAD bitmap is 144 bytes** (per `DOCS/III-HEXAD.md` §3.6). XII reuses this exact geometry conceptually, providing direct semantic compatibility with the substrate's bricking-by-construction proofs.

## Consequences

### Positive
- **Hexad-resonant accountability:** every cell has a hexad assignment from the productive set {FORM, SUBSTANCE, PASSAGE, ESSENCE, MOTION, ORIGIN}; bricking-class compositions are structurally absent. Theorem 4.4 (Bricking-Free Closure) follows.
- **Matrix-organised curation review:** the 6×24 layout makes "every cell has an owner" reviewable by hexad row. A curator auditing the MOTION row (rule-of-thumb: state-changing ops) inspects exactly 24 patterns; same for ORIGIN's seal-class ops.
- **MPHF-friendly:** 144 is small enough that CHD (`xii_chd.iii`) constructs a collision-free hash on first attempt for well-chosen canonical-hash inputs.
- **Compact reach6 bitmap:** 18 bytes is small enough to live in a single cache line. Per-pattern productivity check is one byte load + one bit test.
- **Self-similar to existing substrate:** 144 ≡ HEXAD's reach6 byte count. No new "magic number" introduced.

### Negative
- **Limited expansion headroom:** if a future R2 revision needs >144 patterns, the cap forces either (a) a Catalyst-promoted bump (with federation broadcast), or (b) reuse of register-chained fallback for the additional patterns. Both are friction, by design.
- **Some natural patterns get squeezed:** e.g., the cryptographic hot-path category (initially planned at ~30 patterns) was tightened to 24 to fit the 6×24 matrix. A few less-common variants (e.g., separate sha512_block and sha3_512_block) had to be merged or relegated to register-chained fallback.
- **6 of 144 cells are reserved-not-yet-used:** small overhead for future capability without a clear current use.

## Alternatives Considered

| Cardinality | Rationale | Rejected because |
|-------------|-----------|------------------|
| 127 (prime) | Arbitrary; "feels right" | No substrate connection. Why 127 not 131? |
| 128 (power-of-two) | Convention | Hexad-blind. Even with 128 cells, the natural assignment is "16 per hexad kind plus 32 extras" — arbitrary partitioning. |
| 256 (one byte) | Convenient encoding | Curation cost doubles for marginal coverage benefit. |
| 64 (small) | Easier curation | Too constraining; many useful patterns fall to register-chained fallback. |
| 96 (= 6 × 16) | Hexad-resonant smaller | Insufficient coverage; 16 patterns per hexad too few for crypto + arithmetic + memory + governance subdivisions. |
| 216 (= 6³) | Hexad-resonant cube | Excessive curation cost; many cells would be empty. |
| 432 (= 6 × 72) | Hexad-resonant larger | Same issue. Curation effort scales with cell count. |

## Forward Compatibility

**The 144 number is final for XII.** Future R2 may introduce a different cardinality if the algebra itself is extended (e.g., a 25-operator algebra would suggest 6 × 25 = 150). XII binaries are not forward-compatible with such an extension; a different `XII_R1` would isolate them.

For Catalyst-promoted appends within R1 / XII current spec, the 18 reserved cells (`H139..H144`) plus the 12 guard cells (`H127..H138`) provide expansion room without changing the 144 cap. Guard cells can be re-purposed via governance promotion if their forbidden combination becomes admissible.

## References

- `DOCS/III-XII.md` S10 + S26.8 (Horizon Set specification + 144-pattern catalog)
- `DOCS/III-HEXAD.md` §3 (hexad ground, `xii_asym_reach6`)
- `STDLIB/iii/omnia/xii_horizon.iii` (metadata table for all 144)
- `STDLIB/iii/omnia/xii_horizon_reach.iii` (18-byte productive-flag bitmap)
- `STDLIB/iii/omnia/xii_chd.iii` (CHD MPHF for 144 hashes)
