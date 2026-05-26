# III-CATALYST-EXT — Catalyst Extensions

**Spec:** `DOCS/III-CATALYST-EXT.md` (Wave 8, items 72-78)

Causal-DAG-driven hypothesis synthesis, counterfactual replay, 8-gate
composite-cycle promotion (Anchor restraint, hexad admit, SID inverse,
counterfactual replay, coherence floor, rate cap, Trinity, Anchor
cosignature), per-tick / per-epoch rate caps, post-promotion coherence
monitoring + de-promotion, Founder's Anchor restraint with attack-pattern
halt, and JIT compile / deoptimize records.

## Test

```
$ ./build/iii_catalyst_ext_test
=== 35 passed, 0 failed ===
```

## Conformance (§8)

| Code | Status |
| --- | --- |
| C-CXT-1 | ✅ causal-DAG observe/get_edge with confidence Q14 |
| C-CXT-2 | ✅ counterfactual replay returns VERIFIED / FAILED_* |
| C-CXT-3 | ✅ 8-gate promotion with first-failure reporting |
| C-CXT-4 | ✅ rate cap 8/tick, 1024/epoch |
| C-CXT-5 | ✅ post-promotion coherence monitoring + de-promote |
| C-CXT-6 | ✅ Anchor restraint filter + attack-pattern alarm |
| C-CXT-7 | ✅ JIT compile / deoptimize records with mhash |
