# III-PLANETARY — Planetary-Scale Federation

**Spec:** `DOCS/III-PLANETARY.md` (Wave 9, items 79-85)

Hierarchical federation (cells / districts / regions / substrate),
attacker-peer detection (six signal kinds), peer quarantine, Sybil-resistant
admission (DRTM + unique fingerprint + bounded PoW), eclipse-attack
multipath connectivity assessment, network partition recovery, and witness
chain reconciliation.

## Test

```
$ ./build/iii_planetary_test
=== 23 passed, 0 failed ===
```

## Conformance (§8)

| Code | Status |
| --- | --- |
| C-PL-1 | ✅ four-level hierarchy enum + closure-pinned constants |
| C-PL-2 | ✅ six attack signals detected; severity classification |
| C-PL-3 | ✅ quarantine sets live=false; double-quarantine returns ALREADY |
| C-PL-4 | ✅ admission requires DRTM + unique FP + PoW + binding hash |
| C-PL-5 | ✅ multipath disjointness ≥ MULTIPATH_MIN |
| C-PL-6 | ✅ partition state tracking |
| C-PL-7 | ✅ reconcile classifies in-sync / behind / ahead / diverged / partitioned |
