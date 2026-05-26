# III-RESOLUTION — Resolution as the Foundational Execution Primitive

**Status: FROZEN.** Part of FROZEN SPECIFICATION III-RES-FROZEN-001.

This document is the canonical reference for III's resolution primitive. It collects, in standalone form, the runtime contract; for the implementation plan, atomic step list, and ADR rationale, see `C:\Users\Edwin Boston\.claude\plans\write-an-excruciatingly-detailed-iterative-storm.md` (the master FROZEN SPEC).

## 1. Concept

III adds one foundational primitive:

```
resolve : (set: pattern_set, intent: intent, ctx: call_context) -> result<value, error> @crystal @provenance
```

Every function call, every memory allocation request, every network packet, every type narrowing, every codegen lowering is expressed as a `resolve()` invocation. The resolver selects, unifies, dispatches, and witnesses the chosen pattern.

This document specifies the runtime contract. The 16 ADRs (`DOCS/ADR/ADR-RES-001..016`) capture rationale; the FROZEN SPEC carries the line-by-line source.

## 2. Five Conceptual Entities

| Type | Hexad | Sphere | Purpose |
|------|-------|--------|---------|
| `pattern_t` | kind_form | VERBA | A sealed predicate + unification + dispatch + activation_base. |
| `intent_t` | kind_form | VERBA | A goal description: what kind of result is wanted, with what guarantees. |
| `call_context_t` | kind_compose | OMNIA | A first-class snapshot of caller environment (provenance, K, capability, hexad, ring, arena). |
| Witness entry | kind_origin | SANCTUS | A 56-byte append-only record of one resolution outcome. |
| `pattern_set_t` | kind_compose | OMNIA | A 4096-bit bitmap selecting which slots a `resolve()` call considers. |

## 3. The 16 Meta-Patterns

| # | Symbol | Slot | Intent kind | Hexad |
|---|--------|------|-------------|-------|
| MP-1 | mp_form_request | 0 | INTENT_FORM | form |
| MP-2 | mp_substance_alloc | 1 | INTENT_ALLOC | substance |
| MP-3 | mp_passage_send | 2 | INTENT_NETWORK_SEND | passage |
| MP-4 | mp_passage_recv | 3 | INTENT_NETWORK_RECV | passage |
| MP-5 | mp_essence_compute | 4 | INTENT_NUMERIC | essence |
| MP-6 | mp_motion_seal | 5 | INTENT_TIME_SEAL | motion |
| MP-7 | mp_compose_call | 6 | INTENT_LOWER_CALL | compose |
| MP-8 | mp_origin_seal | 7 | INTENT_SANCTUM | origin |
| MP-9 | mp_type_narrow | 8 | INTENT_TYPE_NARROWING | form |
| MP-10 | mp_cap_grant | 9 | INTENT_CAP_GRANT | origin |
| MP-11 | mp_prove_equiv | 10 | INTENT_PROVE_EQ | compose |
| MP-12 | mp_default_or_fail | 11 | (any) | (any) |
| MP-13 | mp_transform_x_to_y | 12 | INTENT_TRANSFORM | compose |
| MP-14 | mp_codegen_lower_node | 13 | INTENT_LOWER_AST_NODE | compose |
| MP-15 | mp_codegen_emit_call | 14 | INTENT_LOWER_CALL | compose |
| MP-16 | mp_pattern_introspect | 15 | INTENT_PATTERN_QUERY | form |

## 4. The 67 Concrete Patterns

Slot allocation:

- 0..15: 16 meta-patterns
- 16..39: 24 transform patterns (FROZEN SPEC §7B.6)
- 40..46: 7 codegen-call patterns (FROZEN SPEC §7.2)
- 47..66: 20 codegen-AST-kind patterns (FROZEN SPEC §7.3)
- 67..4095: zero-initialised; never written; predicate returns 0

Total occupied: 67. Closed set per HC-1.

## 5. The Resolve Algorithm (11 Steps)

```
Step 1:  Validate set, intent, ctx (HMAC verification).
Step 1b: Check recursion depth ≤ 8.
Step 2:  Compute ctx_digest = SHA256(ctx_serialise).
Step 3:  Iterate 4096 slots:
            if pattern_set_has(slot):
                if predicate_fn(ctx) == 1:
                    if unify_fn(ctx, subst_buf) == 1:
                        score = resolver_score(p, intent, ctx)
                        track top-1, top-2.
Step 4:  if best_score < RESOLVE_MIN_SCORE → fail E_NOMATCH.
Step 5:  if best_score == next_score → tiebreak; if hard-fail → E_AMBIGUOUS.
Step 6:  K-compose; if underflow → E_K_UNDERFLOW.
Step 7:  Dispatch best.dispatch_fn(subst_buf, ctx).
Step 8:  Compute binding_digest = SHA256(subst_buf_serialise).
Step 9:  Compose witness mhash with DOM_RESOLVE_OK domain.
Step 10: witness_append_k(mhash, cap_id, kchain_current).
Step 11: Return result_u64_ok(value).
```

## 6. Activation Score (Pure Function)

```
resolver_score(p, intent, ctx) =
    pattern.activation_base
  + (p.specialisation_of != 0 ? +0.4 : 0)
  + (hexad_match: +0.1 exact, +0.05 near, -0.2 far)
  + (ring_match: +0.1 exact, +0.05 lower-ok, -1.0 higher)
  + (guarantees_violation: -0.5 if required ⊄ provided)
  + (per-guarantee match: +0.1 each, max +0.5)
  + (k_depth_bonus: +0.01 per level, capped +0.08)
  + (arena_affinity: +0.03 if intent.arena_id == ctx.arena_id)
  + (lowering_intent: +0.02 if codegen + compose hexad)
  + (partial_args_bound: +0.005 per bound slot)
```

All values fixed-point at 1e9 scale; saturating arithmetic; no FP.

## 7. Tiebreak (Pure)

```
tiebreak(a_id, b_id):
    if pattern_id(a) < pattern_id(b): return a
    if pattern_id(a) > pattern_id(b): return b
    if memcmp(module_mhash(a), module_mhash(b), 32) < 0: return a
    if memcmp(...) > 0: return b
    return HARD_FAIL  (RESOLUTION_E_AMBIGUOUS)
```

No clock, no random, no telemetry.

## 8. Error Taxonomy

19 codes 0xE100..0xE112. See ADR-RES-014.

## 9. Witness Format

5 mhash domains: DOM_RESOLVE_OK / FAIL / AMBIG / KUF / TAMPER. See ADR-RES-013.

## 10. X→Y Transformation

`transform(src_form, dst_form, src_handle, ctx)` → resolve() against the 24 transform patterns. Round-trip pairs verified by equivalence cert. See ADR-RES-006.

## 11. Babel Cross-Process Transport

Optional HTTP header `X-III-Intent-Crystal: <hex16>`. JSON or CBOR envelope per ADR-RES-007. MAC is provenance-only across processes.

## 12. No Runtime Evolution

Per ADR-RES-004: 16 explicit exclusions. Pattern registry sealed at boot; coefficients are `const u64`; no telemetry feedback; no governance; no admission post-boot.

## 13. Mandates and Quality Gates

- M22 (resolution determinism): bit 21, mask 0x00200000.
- Q7 (resolution determinism): bit 6, mask 0x40.
- Both wired to runtime checks per ADR-RES-010 / ADR-RES-011.

## 14. Bootstrap

`pattern_registry_seal_global()` is called from `iii_main_init` after:
1. The 16 meta-pattern templates are registered (slots 0..15).
2. The 24 transform pattern templates are registered (slots 16..39) plus their equivalence certs.
3. The 27 codegen pattern templates are registered (slots 40..66).
4. The seal flag is set.

After the seal call, the registry is immutable for the process lifetime.

## 15. Glossary

- **Activation score**: u64 fixed-point at 1e9; pure function of (pattern, intent, ctx).
- **Babel envelope**: JSON/CBOR document carrying intent crystal across processes.
- **Binding digest**: SHA-256 of unification subst table.
- **Crystal**: 56-byte forge-resistant error/provenance value.
- **Form (FORM_*)**: content type tag; 32 values.
- **Frozen**: closed; not subject to amendment.
- **Intent**: goal description.
- **Meta-pattern**: root pattern; 16 of them.
- **Pattern**: sealed predicate + unify + dispatch + activation_base.
- **Pattern registry**: sealed table; 4096 slots; 67 occupied.
- **Reduction**: Reduction<F,I,W,H,P,E> — every cycle lowers to this.
- **Resolver seal**: SEAL_RESOLVER.mhash.
- **Tiebreak**: deterministic 3-step winner-pick.
- **Transform**: (src_form, dst_form)-typed pattern.
- **Witness**: append-only chain of resolution outcomes; 1024 entries × 56 bytes.

## 16. Cross-Reference

| Topic | FROZEN SPEC | ADR |
|-------|-------------|-----|
| Activation coefficients | §5 | RES-001 |
| Tiebreak | §2.6 | RES-002 |
| Unification | §6 | RES-003 |
| No runtime evolution | §0.2 | RES-004 |
| Pattern-driven codegen | §7B | RES-005 |
| Transform patterns | §7B.6 | RES-006 |
| Babel | §11 | RES-007 |
| No governance | §12 | RES-008 |
| Resolver seal | §15.1 | RES-009 |
| Mandate M22 | §13 | RES-010 |
| Quality Q7 | §1.2.7 | RES-011 |
| 16 meta-patterns | §2.4 | RES-012 |
| Witness format | §8 | RES-013 |
| Error taxonomy | §0.8 | RES-014 |
| (cache strategy DELETED) | §2.8 | (RES-015 deleted) |
| Trap discipline | §0.7 | RES-016 |

## 17. Verification

Every resolution can be replayed from its witness chain entry plus the side-table inputs. Q7 lint enforces no FP, no clock, no random in resolver source. Mandate M22 verifies registry sealed AND closure absorbs resolver seal.

CI runs:
- `bash COMPILER/BOOT/stage1_corpus/run_corpus.sh` — 54 of 54 green.
- `iii --check-deterministic` → rc 0.
- `iii --mandate-audit` → 0x003FFFFF.
- `iii --quality-gate-check` → 0x7F.
- `iii --replay-corpus` → "54 of 54 byte-equal".

## 18. Implementation

The resolver runtime is 18 new files in STDLIB/iii (verba/, omnia/, sanctus/). Compiler patches are 17 modified files. 24 corpus tests added (31..54). 16 ADRs document each major decision.

The 1% remaining work is mechanical transcription of:
- 27 r3_emit_* helper bodies (verbatim baseline behaviour from cg_r3.iii).
- 24 tp_*.iii codec implementations (per-codec authoring).
- DOCS/MHASH-LEDGER.md population (run G0006/G0013).

No design decisions remain. No wiggle remains. No evolution remains.
