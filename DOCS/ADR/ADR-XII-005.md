# ADR-XII-005: iiis-1 Link Compatibility via Stub Compilation Unit, Not Build Workaround

## Status
Accepted (Phase XII-η).

## Context

iiis-2's `cg_r3.iii` was extended to contain the Phase-XII-η dispatch gate that fires the XII pipeline for `@lattice`-annotated functions:

```
let xii_lat : u8 = sema_xii_anno_has_in_ast(R3_G_AST, node, R3_XII_ANNO_LATTICE)
if xii_lat == 1u8 {
    xii_set_current_sema_state(R3_G_SEMA)
    r3_pe_canonicalise(R3_G_SEMA, node as u64)
    let xii_circ : u32 = r3_compute_circ(R3_G_SEMA, node as u64)
    r3_pe_lattice_emit(R3_G_SEMA, node as u64, xii_circ)
    xii_set_current_sema_state(0u64)
} else {
    r3_emit_block(body)
}
```

Five XII symbols are referenced unconditionally: `sema_xii_anno_has_in_ast`, `xii_set_current_sema_state`, `r3_pe_canonicalise`, `r3_compute_circ`, `r3_pe_lattice_emit`.

In **iiis-2** these resolve to the real implementations in `sema_xii_adapter.c` and `cg_r3_xii.c`, both compiled under `-DIIIS_XII_ENABLED`.

In **iiis-1** (the bit-identity intermediate that self-hosts iiis-0 via the `.iii` ports of cg_r3, sema, ast, etc.), `build_iiis1.sh` deliberately excludes every `*xii*.c` source file. This keeps iiis-1's compile surface minimal and matches the operator's directive that iiis-1 is the "pure ported intermediate," not the XII-aware compiler. But that leaves cg_r3.iii.o's references to the five XII symbols unresolved → link fails.

Three approaches were considered.

### A. Conditional emission in cg_r3.iii
Have iiis-0 emit the gate only if some `#ifdef` (or .iii equivalent) is set. **Rejected.** .iii has no preprocessor. Threading a runtime flag through cg_r3.iii would add branches that diverge iiis-1 from iiis-2 codegen output for **every** function (not just `@lattice`-annotated), breaking the 369/369 corpus bit-identity.

### B. `-Wl,--allow-unresolved-symbols=undefined`
Pass a linker flag so iiis-1's link doesn't fail on the unresolved XII symbols. **Rejected.** Hides real symbol errors; the next time a genuine link error appears, it's silently swallowed. Same family of bypass-the-problem flag as `--allow-multiple-definition` that we explicitly dropped in this XII closure.

### C. Stub compilation unit with `#ifndef IIIS_XII_ENABLED` bodies
Create a new C file `iiis1_link_stubs.c` whose body is wrapped in `#ifndef IIIS_XII_ENABLED ... #endif`. The file provides no-op definitions of the five XII symbols. Under iiis-1's build (no `-D`), the stubs compile and provide link-time definitions. Under iiis-2's build (`-DIIIS_XII_ENABLED`), the stubs are guarded out and the real implementations take over.

The new file's filename starts with `iiis1_`, so the existing `*xii*.c` exclusion pattern doesn't match it and the iiis-1 build picks it up. For iiis-0 (which has no XII gate to satisfy), a one-line exclusion `! -name 'iiis1_*.c'` is added to `build_iiis0.sh` to preserve iiis-0's sealed mhash.

**Accepted.**

## Decision

Add `COMPILER/BOOT/iiis1_link_stubs.c` containing `#ifndef IIIS_XII_ENABLED` stubs for the five XII symbols cg_r3.iii references:

```c
uint8_t  sema_xii_anno_has_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind);
uint32_t sema_xii_anno_get_u32_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind, uint32_t default_val);
void     xii_set_current_sema_state(uint64_t sema_state_handle);
uint64_t xii_get_current_sema_state(void);
int32_t  r3_pe_canonicalise(uint64_t ast, uint64_t fn_node);
uint32_t r3_compute_circ(uint64_t ast, uint64_t fn_node);
int32_t  r3_pe_lattice_emit(uint64_t ast, uint64_t fn_node, uint32_t circ);
```

All stubs return values that cause the `cg_r3.iii` gate to short-circuit to the legacy `r3_emit_block(body)` path:

- `sema_xii_anno_has_in_ast` → returns 0 (no annotation found)
- `xii_set_current_sema_state` → no-op
- `r3_pe_canonicalise` → returns 0
- `r3_compute_circ` → returns 0
- `r3_pe_lattice_emit` → returns 0

`build_iiis0.sh` is updated to exclude `iiis1_*.c` from both its compile list and its source-list-JSON manifest, preserving iiis-0's sealed mhash.

## Consequences

### Positive
- **Triple bit-identity preserved on non-XII inputs.** Every corpus test that doesn't use `@lattice` produces identical codegen output across iiis-0 → iiis-1 → iiis-2.
- **No linker bypass flags.** `iiis-1` links cleanly without `--allow-unresolved-symbols=undefined`; real link errors stay loud.
- **No `.iii`-side fork in the gate.** cg_r3.iii has a single canonical implementation. The runtime behavior change (gate fires vs. falls through) is determined entirely by which definition of `sema_xii_anno_has_in_ast` the linker chose.
- **iiis-0 mhash unchanged.** The new file is excluded from iiis-0's build via a one-line `! -name 'iiis1_*.c'` pattern addition.
- **iiis-2 unaffected.** Under `-DIIIS_XII_ENABLED` the stubs are absent (guarded out); the real implementations win.

### Negative
- **One extra C file in `COMPILER/BOOT/`.** Conceptual overhead: someone unfamiliar with the build matrix needs to understand why this exists. Mitigated by the file's docblock and this ADR.
- **iiis-1.mhash drifts on first build after this change.** Intentional; re-seal per the documented re-sealing workflow.

### Trade-offs Accepted
- **Build-time guard duplication.** The `#ifndef IIIS_XII_ENABLED` guard appears in both `iiis1_link_stubs.c` (defines stubs when off) and `sema_xii_adapter.c` / `cg_r3_xii_adapter.c` (define reals when on). The duplication is necessary because the two files compile in different toolchain configurations; consolidating would require a build-time symbol-injection scheme that violates NIH.

## Alternatives Considered (Detail)

| Approach | Rejected because |
|----------|------------------|
| A: conditional emission in cg_r3.iii | .iii has no preprocessor; runtime flag would diverge non-XII codegen |
| B: linker flag to ignore unresolved | Hides real link errors; same anti-pattern family as `--allow-multiple-definition` |
| Renaming gate's calls to optional indirect-call thunks | Adds runtime indirection; opaque to LDIL static analysis |
| Splitting cg_r3.iii into cg_r3_base.iii + cg_r3_xii.iii (only included in iiis-2) | Two PORTED_TU branches to maintain; bit-identity verification doubles |

## References

- `COMPILER/BOOT/iiis1_link_stubs.c` (the stub file)
- `COMPILER/BOOT/build_iiis0.sh` line 219+ (the `iiis1_*.c` exclusion)
- `COMPILER/BOOT/build_iiis1.sh` (compiles the stub file because it doesn't match `*xii*.c`)
- `COMPILER/BOOT/build_iiis2.sh` (defines `-DIIIS_XII_ENABLED`, guards out the stubs)
- `DOCS/XII-IMPLEMENTATION.md` "Link compatibility" subsection
- ADR-XII-001 (sealed curation context for why the gate exists)
