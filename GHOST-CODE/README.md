# III-GHOST-CODE — Ghost-Until-Verified Discipline

**Spec:** `DOCS/III-GHOST-CODE.md` (Wave 4, items 63-71)

Implements the verification-gate hierarchy (12 gates), the five-state
verification register (Ghost / Compromise.{LOW,MEDIUM,HIGH} / Verified), the
ghost-to-verified transition, the dispatch verdict for cap-gated invocation,
the compromise-tier propagation through call graph, and the closure-root
contribution rules (sources always; machine code only when verified).

## Files

```
GHOST-CODE/
├── include/iii/ghost_code.h
├── src/sha256.c
├── src/ghost_code.c
├── tests/test_ghost.c          57 assertions
└── tools/iii_ghost_tool.c
```

## Test

```
$ ./build/iii_ghost_test
=== 57 passed, 0 failed ===
```

## Conformance (§10)

| Code | Status |
| --- | --- |
| C-GHOST-1/2 | ✅ ghost cycles do not emit machine code (`should_emit_code` false) |
| C-GHOST-3 | ✅ verified-by-construction bypass via `register(... vbc=true)` |
| C-GHOST-4/5/6 | ✅ all 12 gates + per-gate certificates + composition |
| C-GHOST-7 | ✅ atomic transition only when complete |
| C-GHOST-8/9 | ✅ classifier + max-rule propagation |
| C-GHOST-13 | ✅ ghost dispatch returns `GHOST-NOT-EXECUTABLE` verdict |
| C-GHOST-14/15/16 | ✅ cap-gated dispatch; HIGH needs Tier-3 + Anchor + Trinity |
| C-GHOST-17/18 | ✅ closure root binds source mhash always, code mhash when verified |
| C-GHOST-20 | ✅ `revoke()` reverts to ghost; gate certificates retained for re-attempt |
