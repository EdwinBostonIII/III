# ADR-RES-001 — Activation Coefficient Table

## Status

FROZEN.

## Spec

Part of FROZEN SPECIFICATION III-RES-FROZEN-001. Section §5 of the spec contains the canonical coefficient table. This ADR documents the rationale.

## Context

The resolver's `resolver_score(pattern, intent, context) → u64` chooses among candidate patterns. The output ranks candidates so that the highest score wins; ties go to deterministic tiebreak (ADR-RES-002).

Coefficients must be:
- Deterministic — same inputs produce same score, bit-equal across hosts.
- Bounded — score fits in 2³¹ to leave headroom in u64 arithmetic.
- Explainable — every weight has a documented reason.
- Non-tunable post-deployment — no setter API; values are `const u64` declarations.

Floating-point is forbidden (HC-7) because IEEE-754 strict mode is not portable across compilers and platforms; integer fixed-point at scale 1e9 (so 1.0 = 1_000_000_000u64) gives nine decimal digits of precision with deterministic arithmetic.

## Decision

Thirty-three coefficients, declared as `const u64` in `omnia/resolver.iii`. Saturating addition/subtraction/multiplication via `numera/sat_arith.iii`. Threshold `RESOLVE_MIN_SCORE = 100_000_000` (0.1) below which no candidate is admitted.

### Bases (10 constants)

| Symbol | Value | Reason |
|--------|------:|--------|
| `RESOLVER_BASE_ROOT_META_PATTERN` | 1_000_000_000 | Root meta-pattern is a "first-class citizen"; 1.0 leaves room for both bonuses and penalties. |
| `RESOLVER_BASE_FORM_PATTERN` | 1_000_000_000 | Form-kind patterns serve user-visible data needs; equal to root. |
| `RESOLVER_BASE_COMPOSE_PATTERN` | 900_000_000 | Compose-kind is one tier below form; 0.9 reflects that. |
| `RESOLVER_BASE_PASSAGE_PATTERN` | 900_000_000 | Passage = boundary crossing; same priority as compose. |
| `RESOLVER_BASE_ESSENCE_PATTERN` | 900_000_000 | Essence = numerical/cryptographic; same priority. |
| `RESOLVER_BASE_MOTION_PATTERN` | 900_000_000 | Motion = sealed measurement; same priority. |
| `RESOLVER_BASE_SUBSTANCE_PATTERN` | 900_000_000 | Substance = crystallised memory; same priority. |
| `RESOLVER_BASE_ORIGIN_PATTERN` | 1_000_000_000 | Origin = SANCTUS crown; equal to root. |
| `RESOLVER_BASE_DEFAULT_PATTERN` | 500_000_000 | Default-or-fail (MP-12) loses every contest unless nothing else matches. |
| `RESOLVER_BASE_SPECIALISATION_BUMP` | 200_000_000 | A specialisation outscores its parent by +0.2 (when proof verified). |

### Modifiers (15 constants)

| Symbol | Value | Reason |
|--------|------:|--------|
| `RESOLVER_W_GUARANTEE_LINEAR_MATCH` | 100_000_000 | +0.1 per matched guarantee; five guarantees ⇒ max +0.5, equal to violation penalty. |
| `RESOLVER_W_GUARANTEE_BOUNDED_MATCH` | 100_000_000 | Same. |
| `RESOLVER_W_GUARANTEE_CONSTANT_TIME_MATCH` | 100_000_000 | Same. |
| `RESOLVER_W_GUARANTEE_PURE_MATCH` | 100_000_000 | Same. |
| `RESOLVER_W_GUARANTEE_SEAL_MATCH` | 100_000_000 | Same. |
| `RESOLVER_W_HEXAD_EXACT` | 100_000_000 | Hexad-kind exact alignment matters; +0.1. |
| `RESOLVER_W_HEXAD_NEAR` | 50_000_000 | Adjacent sphere (form↔compose, etc.) gets half-credit. |
| `RESOLVER_W_RING_EXACT` | 100_000_000 | Same ring as caller; +0.1. |
| `RESOLVER_W_RING_LOWER_OK` | 50_000_000 | More-privileged callee (ring number lower) is acceptable; +0.05. |
| `RESOLVER_W_K_DEPTH_PER_LEVEL` | 10_000_000 | Provenance depth bonus per level; +0.01. |
| `RESOLVER_W_K_DEPTH_CAP` | 80_000_000 | Cap at +0.08 (8 levels). |
| `RESOLVER_W_ARENA_AFFINITY` | 30_000_000 | Result lives in caller's arena ⇒ less data movement; +0.03. |
| `RESOLVER_W_PROOF_BACKED_SPECIALISATION` | 200_000_000 | Verified equivalence cert adds +0.2 on top of specialisation_bump. |
| `RESOLVER_W_INTENT_FLAG_LOWERING` | 20_000_000 | Codegen patterns get +0.02 nudge when intent.goal_kind == LOWER_AST_NODE. |
| `RESOLVER_W_PARTIAL_ARG_BOUND` | 5_000_000 | Per partially-bound arg in intent; rewards specificity. |

### Penalties (5 constants)

| Symbol | Value | Reason |
|--------|------:|--------|
| `RESOLVER_P_GUARANTEE_VIOLATION` | 500_000_000 | Hard demote (-0.5) when required ⊄ provided. |
| `RESOLVER_P_HEXAD_FAR` | 200_000_000 | Cross-sphere (e.g., form vs essence) gets -0.2. |
| `RESOLVER_P_RING_HIGHER` | 1_000_000_000 | Ring escalation forbidden; -1.0 effectively eliminates the candidate. |
| `RESOLVER_P_EFFECTS_UNDECLARED` | 700_000_000 | Audit-time only; -0.7 for undeclared effects. |
| `RESOLVER_P_ARITY_MISMATCH` | 300_000_000 | Pattern arity disagrees with intent; -0.3. |

### Thresholds (3 constants)

| Symbol | Value | Reason |
|--------|------:|--------|
| `RESOLVE_MIN_SCORE` | 100_000_000 | Below 0.1, no match. Floor for the default-or-fail pattern. |
| `RESOLVE_AMBIGUITY_EPSILON` | 0 | Exact-equality required to declare ambiguity. |
| `RESOLVER_MAX_RECURSION_DEPTH` | 8 | Bounded recursion (I-6); fits the K-depth-cap of 8 levels exactly. |

## Worked Example (matches §5.3)

Three candidates for `intent { goal_kind: INTENT_FORM, expected_hexad_kind: kind_form, required_guarantees: GUARANTEE_PURE | GUARANTEE_BOUNDED }`, `ctx { ring: R0, arena: 0xABCD, recursion_depth: 2 }`:

| Candidate | base | hexad | ring | guarantees | k_depth | arena | spec | total |
|-----------|------|-------|------|-----------|---------|-------|------|-------|
| A: form, R0, PURE+BOUNDED | 1.0e9 | +0.1 | +0.1 | +0.2 | +0.02 | +0.03 | 0 | 1.45e9 |
| B: compose, R0, PURE | 0.9e9 | +0.05 | +0.1 | -0.5 (BOUNDED missing) | +0.02 | +0.03 | 0 | 0.60e9 |
| C: form, R0, PURE+BOUNDED, spec_of=A | 1.0e9 | +0.1 | +0.1 | +0.2 | +0.02 | +0.03 | +0.4 | 1.85e9 |

C wins. Verified by corpus test 38.

## Bound Verification

Maximum possible additive total:
- Best base = 1.0e9
- Specialisation = +0.4 (bump 0.2 + proof 0.2)
- 5 guarantee matches = +0.5
- Hexad exact = +0.1
- Ring exact = +0.1
- K-depth cap = +0.08
- Arena affinity = +0.03
- Lowering flag = +0.02
- 16 partial-args = +0.08

Total ≤ 2.31e9 < 2³¹ × 2 ≈ 4.29e9. Safe. The u64 storage offers another 32 bits of headroom against overflow even with saturating arithmetic.

## Consequences

- Every score computation is reproducible bit-for-bit.
- The seal `SEAL_RESOLVER.mhash` covers these constants; any change is detected at build time.
- The values support the §5.3 worked example exactly — verified by corpus 38.
- Any future revision requires a new specification document; this one is closed.

## Alternatives Refused

### Floating-Point Coefficients

> "Use f64 with strict IEEE-754 rounding."

Refused per HC-7. IEEE-754 strict mode requires per-callsite `set_round_to_nearest` invocations, is not portable across compilers (gcc strict-mode flags differ from MSVC), and certain sub-normal handling differs across CPUs. Integer fixed-point eliminates this entire class of drift.

### Tunable At Runtime

> "Allow `set_coefficient(name, value)` for live ops."

Refused per HC-1 #2. Any runtime mutation is evolution by another name.

### Learned Via Training

> "Run a training corpus; observe outcomes; adjust weights."

Refused per HC-1 #3 (no telemetry feedback). Training requires telemetry. Telemetry is forbidden.

### Auto-Computed From Pattern Properties

> "Compute base = function(arity, hexad, ring) algorithmically."

Refused: shifts the design problem from "what should each base be" to "what should the function be"; same problem, less audit-friendly. Hand-tuned constants with a written rationale are auditable directly.

## Audit

- §5 of FROZEN SPEC carries the canonical table.
- §5.1 carries the verbatim score function.
- §5.2 carries the worked example.
- §L.10 (Score Bounded Lemma) verifies the upper bound.
- Corpus test 38 verifies the worked example numerically.
- `SEAL_RESOLVER.mhash` covers the constants by hashing the source bytes of `omnia/resolver.iii`.

## Lineage

- Authored: step R0002 of §I.
- Closed: this revision is the final ADR. Subsequent changes require a new specification ID.
