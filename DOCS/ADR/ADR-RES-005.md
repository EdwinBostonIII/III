# ADR-RES-005 — Pattern-Driven Codegen

## Status

FROZEN.

## Context

The user's binding directive added: "consider how the system's working codegen should be altered, if at all, to both accommodate reading code FROM patterns and also x code to y code/x file to y file rapid conversion."

Existing III codegen at `cg_r3.iii:919-963` (and parallels in cg_rm1, cg_rm2, cg_r0) hardcodes 184 lines of `if k == K_xxx { … emit … }` cascade per ring. New target architectures, optimisations, or IR variants would require parallel rewrites of every cascade.

## Decision

Replace hardcoded cascades with **registered lowering patterns** in `omnia/codegen_patterns.iii`. Each AST kind becomes a registered `pattern_t` whose `dispatch_fn` is the verbatim baseline emission logic.

The compiler's main loop becomes:

```iii
for each AST node:
    intent = INTENT_LOWER_AST_NODE with shape = node
    result = resolve(g_codegen_pattern_set, intent, ctx)
    emit(result.bytes)
```

### Slot Allocation

| Range | Population |
|-------|-----------|
| 40..46 | 7 codegen-call patterns (cg_call_direct_extern, cg_call_direct_local, cg_call_indirect_via_local, cg_call_indirect_via_expr, cg_resolver_self, cg_call_extern_msvc, cg_call_pe_iat_thunk) |
| 47..66 | 20 per-AST-kind patterns (cg_lower_binary, cg_lower_unary, cg_lower_ident, …, cg_lower_decl_const) |

27 codegen patterns total. Closed set per HC-1 #14.

## Consequences

- Adding/replacing a lowering requires authoring a new pattern source AND a new specification document. This is intentional friction: it preserves determinism.
- The original 184 lines of cascade are preserved verbatim in dispatch_fn bodies; behaviour is bit-identical pre/post migration (verified by C0007 byte-equal test).
- The compiler loop becomes uniform: one resolve() call per node.

## Alternatives Refused

### Plug-In Compiler Architecture With Runtime-Loadable Lowering

Refused: dynamic loading violates HC-1 #1 (no admission post-boot).

### Multiple Compiler Backends As Cmd-Line Option

Refused: equivalent to a feature flag, refused per HC-1 #12.

### Keep Hardcoded Cascades; Add Pattern Layer Above

Refused: two redundant lowering paths means two attack surfaces, two paths for traps, twice the audit. The migration is total.

## Audit

- §7 carries lowering specification.
- §7B carries the pattern-driven codegen architecture.
- §Z.C.9.full carries verbatim source for all 27 codegen patterns.
- §F.D.CG_R3.append.full carries the 27 r3_emit_* helper bodies.

## Lineage

Authored: step R0005 of §I. Closed.
