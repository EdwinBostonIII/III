# III-CODEGEN-PATTERNS — Pattern-Driven Code Generation

**Status: FROZEN.** Part of FROZEN SPECIFICATION III-RES-FROZEN-001 (§7B). Cross-reference: ADR-RES-005, ADR-RES-006.

## 1. Concept

The III compiler's per-AST-kind emission cascade (originally `cg_r3.iii:919-963` and parallel cascades in `cg_rm1.iii`/`cg_rm2.iii`/`cg_r0.iii`) is replaced by **registered lowering patterns** in `omnia/codegen_patterns.iii`. Every AST kind becomes a registered `pattern_t`. The compiler walks the AST top-down and dispatches each node through `resolve()`; the matched pattern's `dispatch_fn` produces the bytes.

This unifies codegen with the X→Y transformation system: a codegen step IS a transform (FORM_III → FORM_X86_ASM); a Babel encode IS a transform (FORM_III → FORM_BABEL_JSON); a disassembly IS a transform (FORM_X86_BYTES → FORM_X86_ASM).

## 2. Slot Layout

The 4096-slot global pattern registry (sealed at boot):

| Range | Population | Purpose |
|-------|-----------|---------|
| 0..15 | 16 meta-patterns | Roots; never directly dispatched |
| 16..39 | 24 transform patterns | (src_form, dst_form) pairs |
| **40..46** | **7 codegen-call patterns** | **Function-call lowering** |
| **47..66** | **20 codegen-AST-kind patterns** | **Per-AST-kind lowering** |
| 67..4095 | zero-initialised | Never matchable |

## 3. The Seven Call-Family Patterns (Slots 40..46)

| Slot | Pattern | When matched | What it emits |
|------|---------|--------------|---------------|
| 40 | `cg_call_direct_extern` | Callee is K_EXPR_IDENT bound to extern | `callq sym` REL32 |
| 41 | `cg_call_direct_local` | Callee is K_EXPR_IDENT bound to local fn decl | `callq sym` REL32 |
| 42 | `cg_call_indirect_via_local` | Callee is local fn-ptr var | `pop %rax; call *%rax` |
| 43 | `cg_call_indirect_via_expr` | Callee is non-IDENT expression | `pop %rax; call *%rax` |
| 44 | `cg_resolver_self` | Callee is `iii_resolve` | Direct callq (whitelist; bypasses resolver) |
| 45 | `cg_call_extern_msvc` | Callee is C-ABI extern | `callq sym` + extern marker |
| 46 | `cg_call_pe_iat_thunk` | Callee is PE-imported symbol | IAT thunk path |

The whitelist at slot 44 prevents infinite recursion: when the resolver's own implementation calls itself (e.g., one resolve() invokes another), the call is emitted directly rather than re-routed through the resolver.

## 4. The Twenty Per-AST-Kind Patterns (Slots 47..66)

| Slot | Pattern | AST kind |
|------|---------|----------|
| 47 | `cg_lower_binary` | K_EXPR_BINARY |
| 48 | `cg_lower_unary` | K_EXPR_UNARY |
| 49 | `cg_lower_ident` | K_EXPR_IDENT |
| 50 | `cg_lower_literal` | K_EXPR_LITERAL |
| 51 | `cg_lower_index` | K_EXPR_INDEX |
| 52 | `cg_lower_deref` | K_EXPR_DEREF |
| 53 | `cg_lower_addrof` | K_EXPR_ADDROF |
| 54 | `cg_lower_cast` | K_EXPR_CAST |
| 55 | `cg_lower_fnptr` | K_EXPR_FNPTR |
| 56 | `cg_lower_field` | K_EXPR_FIELD |
| 57 | `cg_lower_if` | K_STMT_IF |
| 58 | `cg_lower_while` | K_STMT_WHILE |
| 59 | `cg_lower_for` | K_STMT_FOR |
| 60 | `cg_lower_return` | K_STMT_RETURN |
| 61 | `cg_lower_block` | K_STMT_BLOCK |
| 62 | `cg_lower_let` | K_STMT_LET |
| 63 | `cg_lower_assign` | K_STMT_ASSIGN |
| 64 | `cg_lower_decl_fn` | K_DECL_FN |
| 65 | `cg_lower_decl_var` | K_DECL_VAR |
| 66 | `cg_lower_decl_const` | K_DECL_CONST |

## 5. The Compiler's Main Loop

```iii
fn r3_emit_expr(ast: u64, node: u64) -> i32 {
    let intent_id : u64 = intent_new_lower_ast_node(ast, node, ast_node_kind(ast, node))
    let ctx_id : u64 = call_context_new(...)
    let result : u64 = resolve(g_codegen_pattern_set, intent_id, ctx_id)
    if result_u64_is_ok(result) == 0u8 { return R3_FAIL }
    let emit_handle : u64 = result_u64_unwrap_or(result, 0u64)
    r3_emit_handle(emit_handle)
    return R3_OK
}
```

The 184 lines of original cascade become this 8-line dispatch.

## 6. Adding A New AST Kind

Per ADR-RES-004 / HC-1, no admission post-boot. Adding a new lowering pattern requires:

1. New specification document with new ID (replaces FROZEN SPEC III-RES-FROZEN-001).
2. New entry in `omnia/codegen_patterns.iii` register function.
3. New `r3_emit_*` helper in `cg_r3.iii`.
4. New ADR documenting the addition.
5. Full corpus regression.
6. Re-seal `iiis-0.mhash` AND `SEAL_RESOLVER.mhash`.

## 7. Byte-Level Emission

For function calls, the emitted byte sequence (FROZEN SPEC §7.4) is:

```
mov r8, set_id (imm32)         48 C7 C0 .. .. .. ..
lea rcx, [rip + intent_table]  48 8D 0D .. .. .. ..
lea rdx, [rip + ctx_scratch]   48 8D 15 .. .. .. ..
sub rsp, 32                    48 83 EC 20
call iii_resolve               E8 .. .. .. ..
add rsp, 32                    48 83 C4 20
test rax, rax                  48 85 C0
je <error_label>               74 ..
```

Total 25 bytes per resolver-call invocation.

## 8. Verification

- Corpus 1..30: original tests still produce their original exit codes.
- Corpus 52: `52_call_via_resolver.iii` verifies the 25-byte sequence emits at every callsite.
- §V.G0003: objdump audit confirms every callq targets `iii_resolve` or whitelisted self-call.

## 9. Cross-Reference

- ADR-RES-005 (rationale).
- FROZEN SPEC §7 (compiler lowering).
- FROZEN SPEC §7B (X→Y unification).
- FROZEN SPEC §Z.C.9.full (full source).
- FROZEN SPEC §F.D.CG_R3.append.full (27 r3_emit_* bodies).
