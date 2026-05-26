# III-CATALYST — Dynamic Transformation Catalyst

**Doc-ID:** B1 / R1.B1
**Spec:** `DOCS/III-CATALYST.md`

The eight promotion gates, per-tick rate caps (8 cycles, 4 phase, 16 module
fusion, 1 keyword), seven synthesis categories, operator overrides
(pause / resume / revoke / constrain / reject), and witness emission
(`MNEME_CATALYST_PROMOTE` / `CATALYST_REJECT` / `CATALYST_RATE_CAP` etc).

## Test

```
$ ./build/iii_catalyst_test
=== 35 passed, 0 failed ===
```

## Conformance (§7)

| Code | Status |
| --- | --- |
| C-CAT-1 | ✅ all eight gates evaluated and emitted as sub-witnesses |
| C-CAT-2 | ✅ per-tick rate caps for cycle, phase, module-fusion, keyword |
| C-CAT-3 | ✅ promote witness mhash binds candidate + counter + 8 sub-witnesses |
| C-CAT-4 | ✅ inviolable rules enforced: hexad/coherence/codegen/flag |
| C-CAT-5 | ✅ pause/resume/revoke/constrain witnessed and persistent |
