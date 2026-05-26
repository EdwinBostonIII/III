# ADR-IIIS1-001 — Static Type-System Checks for iiis-1

## Status

ACCEPTED.  Implemented across this session.  All four iiis-1 features
have AT LEAST runtime enforcement; three have static teeth.

## Context

The iiis-1 architecture document (`docs/IIIS-1-ARCHITECTURE.md`)
specifies four type-system features:

1. Hexad-typed values (`@hexad_kind`)
2. K-value bounds as type constraints (`@k_max`)
3. Capability as type-level (`@cap_required`)
4. First-class intent types

Phase 3 Step 2 landed all four annotations as parseable opaque
metadata.  Phase 3 Step 3 landed runtime enforcement for #1, #2, #3
(corpus 261, 260, 259).  Feature #4 stayed in the design column —
the architecture doc proposed type-aliases (`type IntentForm = intent
@primitive(FORM)`) which would require a new `intent` primitive type
and binder-based alias resolution.

This ADR documents the static checks added to close the v1.0 type
system, operationalising feature #4 as parameter-level
`@hexad_kind` propagation (the structurally-equivalent expression of
"first-class intent" within iiis-0's existing AST shape) AND adding
two further static checks that catch caller-callee type violations
at codegen time.

## Decision

Three static checks land at the EXPR_CALL emission site in
`COMPILER/BOOT/cg_r3.c`.  Each fires only when BOTH sides of the
type relationship are annotated; legacy untagged code is unaffected.

### Check 1 — `@cap_required` cap-flow propagation

When a caller fn declares `@cap_required(Y)` and calls a callee fn
declared `@cap_required(X)`, codegen asserts `(Y & X) == X`.
Violation → rc=14 with marker `# III_CAP_FLOW_VIOLATION: caller mask
0xY insufficient for callee mask 0xX (missing 0x...)`.

Rationale: caller is guaranteed to hold at most mask Y; callee
requires mask X; if Y doesn't contain X, the runtime gate at the
callee MUST deny.  Reject at compile time.

Corpus: `262_cap_flow_static.iii` (positive),
`262_neg_cap_flow.iii` (negative, via `test_cap_flow_static_negative.sh`).

### Check 2 — `@hexad_kind` parameter intent-kind propagation

When a callee fn parameter declares an inline `@hexad_kind(K_p)`
annotation AND the arg is an ident bound to a let/param/var whose
declared type also carries `@hexad_kind(K_a)`, codegen asserts
`K_a == K_p`.  Mismatch → rc=14 with marker `# III_INTENT_KIND_VIOLATION:
arg N kind 0xK_a does not match param kind 0xK_p`.

This operationalises feature #4 (first-class intent types) using
existing iiis-0 AST machinery — no new `intent` primitive needed.
The kind annotation is a numeric hexad code (1..7); flow is
proven structurally.

The parser was extended (`parse.c` / `iiip_parse_let` and
`iiip_parse_param_list`) to attach inline `@modifier` annotations
to the type_ref's modifier list instead of discarding them.  This
populates the AST shape already present in iiis-0 but previously
unused.

Corpus: `263_intent_kind_static.iii` (positive),
`263_neg_intent_kind.iii` (negative, via `test_intent_kind_static_negative.sh`).

### Check 3 — `@k_max` K-floor propagation

When a caller fn declares `@k_max(N_A)` and calls a callee fn
declared `@k_max(N_B)`, codegen asserts `N_A >= N_B`.  If `N_A <
N_B`, the caller can enter at K=N_A < N_B and the callee MUST deny
— a structurally-unreachable success path.  Violation → rc=14 with
marker `# III_K_FLOOR_VIOLATION: caller floor N_A below callee floor
N_B (deficit D)`.

Pure integer comparison; parallel to cap-flow.

Corpus: `264_k_floor_static.iii` (positive),
`264_neg_k_floor.iii` (negative, via `test_k_floor_static_negative.sh`).

### Check 4 — `@returns_hexad` return-kind propagation

When a callee fn declaration carries `@returns_hexad(K_r)` AND a
let-binding consumes its result with declared type
`@hexad_kind(K_l)`, codegen asserts `K_l == K_r`.  Mismatch →
rc=14 with marker `# III_RETURN_KIND_VIOLATION: let kind 0xK_l does
not match callee return kind 0xK_r`.

Distinct modifier name (`@returns_hexad` vs `@hexad_kind`) preserves
the FN-level `@hexad_kind` semantics (caller-ctx gate at prologue)
and adds return-value type-tagging without semantic conflict.  The
check fires at STMT_LET emission, before evaluating the value
expression, so violations are caught structurally without runtime
side-effects.

Corpus: `265_return_kind_static.iii` (positive),
`265_neg_return_kind.iii` (negative, via `test_return_kind_static_negative.sh`).

## Mandate 7 compliance

All three checks are STRUCTURAL: integer mask containment, integer
equality, integer comparison.  No observation, no statistics, no
learning.  Annotations are explicitly declared by the programmer;
the codegen reads them.

## Self-host status

`build_iiis1.sh` produces `iiis-1.exe` with sealed mhash
`0edbffa8980af8c6f0768ccfab0644c3ad06d4206e41950146f2f04408fbf95c`,
verified reproducible across 3 consecutive builds.  Verification
gate added to `build_iiis1.sh` (mhash drift = build fail).

KNOWN GAP: the three static checks live in `cg_r3.c` only.  The
parallel `cg_r3.iii` source (used by iiis-1's build pipeline)
predates them.  iiis-1 therefore produces older codegen for
sources that would trigger the static checks.  Closing this gap
requires porting ~150 lines of cg_r3.c logic to cg_r3.iii — left to
iiis-1.full work.

Parser sync IS complete: `parse_impl.c` synced from `parse.c`, so
iiis-1 now ATTACHES let-modifiers correctly (corpus 263 produces
bit-identical output via iiis-0 and iiis-1).

## Consequences

Type system now has compile-time teeth for THREE of the four
features.  Sources that opt into typed flows get structural
guarantees BEFORE binary sealing.  Legacy untagged code is
unaffected — these are TIGHTENINGS, not constraints.

The Phase 3 Step 5 acceptance criterion ("iiis-1 compiles iiis-1
bit-identically") holds for the SUBSET of source not touching
cg_r3.c's unported checks.  Full bit-identity awaits cg_r3.iii
porting.

## Alternatives Considered

**Type-alias resolution at codegen**: chase TYPE_REF → binder
(TYPE_DECL) → rhs_type.modifiers to follow `type IntentForm = u64
@hexad_kind(1u64)` aliases.  Deferred: requires sema to set binder
on TYPE_REF nodes (currently only EXPR_IDENT carries binders).
Stage-2+ work.

**K-budget flow analysis**: track `kchain_compose` decreases through
the dispatch graph.  Deferred: requires explicit flow analysis
(escape analysis lite).  v1.0 ships the simpler caller-callee
floor invariant.

**Return-type intent-kind tracking**: when a fn returns `u64
@hexad_kind(K)` and the caller binds it to a let with a different
kind, reject.  Not yet wired (would require return-type modifier
attachment + STMT_LET emission check).  Future iiis-1.x.

## References

- `COMPILER/BOOT/cg_r3.c` EXPR_CALL handler — the three checks
- `COMPILER/BOOT/parse.c` — iiip_parse_let, iiip_parse_param_list
  (modifier attachment)
- `STDLIB/corpus/262_*.iii`, `263_*.iii`, `264_*.iii` — positive
  conformance tests
- `STDLIB/corpus/{262,263,264}_neg_*.iii` — negative conformance tests
- `STDLIB/scripts/test_{cap_flow,intent_kind,k_floor}_static_negative.sh`
  — harnesses for the negative tests
- `docs/IIIS-1-ARCHITECTURE.md` — the architecture doc this implements
- `docs/III-V1.0-STATE.md` — substrate state summary
