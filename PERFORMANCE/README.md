# III-PERFORMANCE — Speed-Without-Sacrifice

**Spec:** `DOCS/III-PERFORMANCE.md` (Wave 1, items 10-25)

Implements the runtime side of the speed mandate: hardware feature detection,
dispatcher, cache-aligned SCBA, lock-free SPSC ring, Möbius rolling-sum fast
path, compacted 32-byte hexad-admissibility table, O(1) cycle-dispatch table,
zero-allocation per-CPU arena, per-CPU sub-key cache pinning, and the §18.1
performance-budget instrumentation.

## Test

```
$ ./build/iii_performance_test
=== 57 passed, 0 failed ===
```

## Conformance (§19)

| Code | Status |
| --- | --- |
| C-PERF-3  | ✅ SCBA is 64-byte aligned, single L1 line per word |
| C-PERF-6  | ✅ SPSC ring is lock-free; capacity 1024 |
| C-PERF-7  | ✅ Möbius rolling-sum produces ratio in q14 |
| C-PERF-8  | ✅ hexad table compacts to 32 bytes (`sizeof == 32`) |
| C-PERF-9  | ✅ cycle dispatch via flat array indexing |
| C-PERF-10 | ✅ arena bump-allocator with `release()` reset |
| C-PERF-13 | ✅ subkey aligned to 64-byte cache line (`sizeof == 64`) |
| C-PERF-14 | ✅ atomic-or-nothing batch push (`iii_ring_try_push_batch`) |
| C-PERF-15 | ✅ ring carries NUMA node affinity |
| C-PERF-16 | ✅ scalar Z₃⁶ composition; AVX-512 path is a separate codegen entry |
| C-PERF-17 | ✅ feature-absent fallback paths verified |
| C-PERF-18 | ✅ §18.1 budgets exposed; `iii_perf_within_budget()` enforces |
