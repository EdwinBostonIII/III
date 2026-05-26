# ADR-RES-014 — Error Taxonomy

## Status

FROZEN.

## Context

Resolution can fail in 19 distinct ways. A flat code namespace allows cause-determination from the integer value alone, supporting forensic traceability via crystal cause chains.

## Decision

Codes 0xE100..0xE112, declared in `omnia/result.iii` (FROZEN SPEC §0.8):

| Code | Symbol | Meaning |
|-----:|--------|---------|
| 0xE100 | `RESOLUTION_E_NOMATCH` | Best score below `RESOLVE_MIN_SCORE`. |
| 0xE101 | `RESOLUTION_E_AMBIGUOUS` | Tie persisted past tiebreak (registry corruption). |
| 0xE102 | `RESOLUTION_E_K_UNDERFLOW` | Composing K dropped below floor. |
| 0xE103 | `RESOLUTION_E_DEPTH` | Recursion depth exceeded. |
| 0xE104 | `RESOLUTION_E_CAP_DENIED` | dispatch_fn refused on capability check. |
| 0xE105 | `RESOLUTION_E_REGISTRY_TAMPER` | set_root_mhash failed verification. |
| 0xE106 | `RESOLUTION_E_INTENT_TAMPER` | intent_id failed verification. |
| 0xE107 | `RESOLUTION_E_CTX_TAMPER` | ctx_id failed verification. |
| 0xE108 | `RESOLUTION_E_UNIFY_FAILED` | All candidates failed unification. |
| 0xE109 | `RESOLUTION_E_DISPATCH_FAULT` | dispatch_fn returned an error crystal. |
| 0xE10A | `RESOLUTION_E_GUARANTEE_VIOLATION` | Result lacks required guarantees. |
| 0xE10B | `RESOLUTION_E_HEXAD_MISMATCH` | Result hexad ≠ requested. |
| 0xE10C | `RESOLUTION_E_RING_VIOLATION` | Candidate's ring exceeds caller. |
| 0xE10D | `RESOLUTION_E_INTENT_INVALID` | Intent partial_args_mask references unfilled slot. |
| 0xE10E | `RESOLUTION_E_REGISTRY_FULL` | Tried to register past sealed cap. |
| 0xE10F | `RESOLUTION_E_ARITY_OVERFLOW` | Pattern arity > 32. |
| 0xE110 | `RESOLUTION_E_OCCURS_CHECK` | Unify cycle detected. |
| 0xE111 | `RESOLUTION_E_BUFFER_OVERFLOW` | subst_buf would exceed 256 bytes. |
| 0xE112 | `RESOLUTION_E_DETERMINISM_BUG` | Rebuild produced different witness mhash (Q7 fail). |

19 codes. No 0xE113.

## Failure Crystal

Every failure mints a crystal:

```
crystal.error_code = §0.8 code
crystal.site_hash  = SHA256 with appropriate domain (DOM_RESOLVE_FAIL/AMBIG/KUF/TAMPER)
crystal.cap_id     = ctx.cap_id (or 0 if ctx invalid)
crystal.cause      = parent_intent_crystal_id (or 0 if root)
crystal.k_fixed    = kchain_current(ctx.kchain_id)
crystal.msg_hash   = SHA256("III_RESOLVE_MSG" || error_code_le4 || pattern_id_le8 || intent_id_le8)
crystal.mac        = HMAC over body
```

Crystals chain via `cause` for forensic traceability.

## Consequences

- 19 distinct fault categories observable by auditor.
- Caller can branch on error code (e.g., retry with different intent, log and abort, mint compensating ripple).
- Crystal MAC ensures errors cannot be forged after the fact.

## Alternatives Refused

### String-Encoded Errors

Refused: not deterministically hashable, not constant-time-comparable, not space-efficient.

### Hierarchical Error Codes (e.g., 0xE1.major.minor)

Refused: flat namespace simpler; 19 codes don't justify hierarchy.

### Errno-Style Single Number Without Crystal

Refused: errno offers no provenance, no MAC, no cause chain. Crystals carry full forensic context.

## Audit

- §0.8 carries the canonical table.
- §2.7 of FROZEN SPEC.
- §F.D.RESULT carries the const declarations.

## Lineage

Authored: step R0014 of §I. Closed.
