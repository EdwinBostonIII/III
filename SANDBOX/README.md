# III-SANDBOX — The Perfect Sandbox

**Spec:** `DOCS/III-SANDBOX.md` (Wave 10.1, items 86-90)

First-class sandbox primitive providing total isolation, total observation,
total reproducibility, total reversibility, and total decomposability.
Implements the lifecycle state machine, NPT/MPK/IOMMU isolation flags,
snapshot/restore/fork (counterfactual branching), parent-child anchor of
audit chains, and compromise propagation.

## Files

```
SANDBOX/
├── include/iii/sandbox.h
├── src/sha256.c
├── src/sandbox.c
├── tests/test_sandbox.c          51 assertions
└── tools/iii_sandbox_tool.c
```

## Test

```
$ ./build/iii_sandbox_test
=== 51 passed, 0 failed ===
```

## Conformance (§7)

| Code | Status |
| --- | --- |
| C-SAND-1 | ✅ first-class type via `iii_sandbox_descriptor_t` |
| C-SAND-2 | ✅ lifecycle state machine: created → running → suspended/snapshotted → terminated → discarded |
| C-SAND-3 | ✅ per-sandbox NPT class + MPK key + IOMMU context |
| C-SAND-9 | ✅ snapshot captures memory + CPU + caps + files + network |
| C-SAND-10 | ✅ snapshot composite mhash binds all 5 components + chain tip |
| C-SAND-11 | ✅ restore replays composite mhash deterministically |
| C-SAND-12 | ✅ fork creates counterfactual branch with `forked_from` linkage |
| C-SAND-15 | ✅ recursion depth ≤ XII_SANDBOX_MAX_RECURSION_DEPTH (16) |
| C-SAND-16 | ✅ every operation increments witness count |
| C-SAND-19 | ✅ compromise propagates to parent on `propagate_compromise()` |
