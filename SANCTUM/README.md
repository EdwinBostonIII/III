# III-SANCTUM — Ring -2 Discipline

**Doc-ID:** A8 / R1.A8 = `8d0ba7ac9885295fa7046a3a2b0e1dfae1755e22a4fa297279b29e452fe8c548`
**Spec:** `DOCS/III-SANCTUM.md`

Ring -2 surface for III: exactly 10 sealed call slots (slot 0 INVALID guard;
slots 1..9 functional), the 8-step Sealed-Cycle Box, the Trinity-Gate
admission, the DRTM relaunch (sovereign reset), the Phantom NVRAM key/value
store, Phoenix bookmarks, CRCC key export, chronos epoch advance, the
compromise quote, and the §5.5 predictive specialisation hooks.

## Layout

```
SANCTUM/
├── include/iii/sanctum.h         Public API.
├── src/
│   ├── sanctum_internal.h
│   ├── crypto.c                  SHA-256 / HMAC / HKDF.
│   ├── sanctum.c                 8-step box, 10 slots, DRTM, PFS, Phoenix, CRCC.
│   └── r1_a8.c                   Closure-identity constant.
├── tests/test_sanctum.c          87 assertions.
└── tools/iii_sanctum_tool.c      CLI: info / seals / box-steps / demo / hash.
```

## Test

```
$ ./build/iii_sanctum_test
=== 87 passed, 0 failed ===
```

## Conformance (per spec §9)

| Criterion | Status |
| --- | --- |
| C-SAN-1 — exactly 10 sealed-call slots | ✅ `XII_SANCTUM_SEAL_COUNT == 10` |
| C-SAN-2 — every entry executes the 8-step box with hardenings | ✅ `iii_sanctum_call_trace_t.executed[]` and `.hardening` |
| C-SAN-3 — Trinity-Gate before dispatch; aborted-cycle witness on reject | ✅ `iii_trinity_admit()` + `XII_STEP_KIND_SANCTUM_TRINITY_REJECT` |
| C-SAN-4 — DRTM-relaunch produces 312-byte chained quote | ✅ `sizeof(iii_drtm_quote_t) == 312`, prior_quote_mhash threading |
| C-SAN-5 — Sanctum memory accesses cannot crash from a well-typed call | ✅ all access through bounded API; no raw pointers |
| C-SAN-6 — predictive specialisation hot-path | ✅ `iii_sanctum_specialize()` and `trace.specialized_path` |
| C-SAN-NIH — hand-rolled trampoline / no third-party hardening | ✅ no external crypto; trampoline modelled inline |
