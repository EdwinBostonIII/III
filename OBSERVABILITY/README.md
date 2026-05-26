# III-OBSERVABILITY — Always-Available System Information

**Spec:** `DOCS/III-OBSERVABILITY.md` (Wave 2.1, items 26-32)
**Status:** Derivative architectural mandate — observability becomes a property
of every cycle, not a separate plane.

Implements the OBSERVATORY collapse, the 12-family threshold library,
saturation predicates as first-class effects, the always-available State
surface, the WLISHI live introspection layer, system-wide health metrics,
and the operator query API.

## Layout

```
OBSERVABILITY/
├── include/iii/observability.h
├── src/
│   ├── sha256.c
│   ├── thresholds.c           12 threshold families (Hoeffding..Multinomial-Dirichlet).
│   └── runtime.c              Trackers, State surface, queries, WLISHI parser.
├── tests/test_observability.c  67 assertions.
└── tools/iii_observability_tool.c
```

## Threshold families (§2)

| Family | Source | Saturation |
| --- | --- | --- |
| Hoeffding | Hoeffding 1963 | half-width ≤ ε |
| Multinomial | combinatorial | each cat ≥ n_min/k |
| Wilson | Wilson 1927 | CI width ≤ ε |
| Poisson | classical | √n/λ ≤ ε |
| Coupon collector | Feller 1968 | n ≥ k log(k/(1-c)) |
| CM-sketch | Cormode-Muthukrishnan 2005 | n ≥ width × depth |
| Order-statistic | rank statistics | quantile half-width ≤ ε |
| Nyquist | sampling theorem | Fs ≥ 2·B |
| ESS | importance sampling | (Σw)²/Σw² ≥ target |
| Heaps | Heaps 1978 | V ≈ K·N^β |
| Rule-of-three | zero-event | n ≥ -ln(1-c)/3 |
| Multinomial-Dirichlet | Bishop 2006 | posterior CI ≤ ε |

## Test

```
$ ./build/iii_observability_test
=== 67 passed, 0 failed ===
```

## Conformance (§8)

| Code | Status |
| --- | --- |
| C-OBS-1 | ✅ collapsed: no separate observability plane; `iii_observability_observe()` runs inline |
| C-OBS-2 | ✅ each family verified with synthetic data and known thresholds |
| C-OBS-3 | ✅ R1-pinned constants; modify requires Tier-3 amendment |
| C-OBS-4 | ✅ `iii_th_compose()` produces correct AND/OR/UNTIL boolean combinations |
| C-OBS-5 | ✅ observe overhead is a few cycles (no syscalls, no locks) |
| C-OBS-7 | ✅ saturation events queued, popped via `iii_observability_pop_saturation` |
| C-OBS-10 | ✅ State-surface queries are O(1) struct reads |
| C-OBS-13 | ✅ `iii_observability_health_score()` geometric-mean aggregate |
| C-OBS-15 | ✅ query rejects > XII_OBSERVABILITY_QUERY_MAX_WITNESSES without consent |
| C-OBS-17 | ✅ result_mhash binds query parameters + audit-chain root |
