# III-STDLIB — Master Inventory & System Codex

**Spec:** `DOCS/III-STDLIB.md` (Refinement Pass v2)

Programmatic access to the canonical III inventory: 47 keywords (categorised),
19 modifiers, 23 operators, 25 punctuators, 9 literal forms, 17 SE kinds,
3 compromise tiers, 4 phases, 10 Sanctum slots, 3 Trinity layers, 4 Federation
tiers, 30 conformance criteria, and the 15-member R1 specification family.

Programs query this library to know "what III is" — every count is verified
against the sealed sources at the §17 R1 specification root.

## Test

```
$ ./build/iii_stdlib_test
=== 47 passed, 0 failed ===
```

## Conformance

| Code | Status |
| --- | --- |
| Lexical inventory (§2)    | ✅ counts match: 47 / 19 / 23 / 25 / 9 |
| SE kinds (§4)              | ✅ 17 entries with codes 0x01..0x11 |
| Phase / Sanctum (§7/§8)    | ✅ 4 rings, 10 slots |
| Trinity (§9)               | ✅ 3 layers with cycle budgets |
| Federation (§12)           | ✅ 4 tiers with quorum specs |
| Conformance (§15)          | ✅ 30 acceptance criteria C-1..C-30 |
| R1 family (§17)            | ✅ 15 sealed members totalling ~412 KB |
