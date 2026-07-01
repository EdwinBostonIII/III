# III — Exact Photonic / Stress-Load Lattice Routing

**Artifact:** `STDLIB/iii/aether/photon_route.iii` (organ) + `STDLIB/corpus/2151_photon_route.iii` (gate).
**Gate:** `run_sqrtsum_kats.sh` → `PASS 2151_photon_route : exit 99`, suite `PASS=19 FAIL=0` (no regression).
**Delegated** in `run_corpus.sh` skip-list (~line 1816) to its owning gate.

## The problem

Signals (photons) and stress-loads route through massive 3D crystalline lattices. Float pathfinders collapse on
near-ties (two routes equal to within float ε), so they pick a longer, lossier path — **excess routing loss**.

## The insight (first principles)

Routing on a symmetric lattice splits in two:

- **Bulk (pristine crystal):** the octahedral group **O_h** (48 symmetries) preserves edge lengths, so the shortest
  origin→(dx,dy,dz) path depends only on the **O_h-canonical form** — the sorted magnitudes `p≥q≥r`. The exact geodesic
  is the greedy `r·(1,1,1) + (q−r)·(1,1,0) + (p−q)·(1,0,0)`: `r` body-diagonals (√3), `q−r` face-diagonals (√2), `p−q`
  axis steps (√1). **O(1), zero per-node memory** — it routes through *millions* of nodes without enumerating one.
- **Defects (broken/forbidden nodes):** a bounded local **search** — the frontier-compacted exact Dijkstra, whose peak
  memory tracks the **frontier width**, not the enclosed volume.

Both produce a route as a **per-class amount vector** `(a axis, b face, c body)` whose exact length is
`a√1 + b√2 + c√3` — a sum of square roots. That single shared representation is what lets the three organs compose:
the **oracle emits it**, the **comparator (`traj_len_sign`) consumes it**, the **detour (`lattice_shortest_path_c`)
produces it**. `photon_route.iii` gives all three their **first organ-level consumer** — it elevates the previous
modules from KAT-only primitives into a routing organ. (`photon_route` itself is KAT-consumed, like the rest of the
2120–2147 sqrt-sum cluster — not yet application-wired; the honest phrasing is "consumes `traj_kinematics`".)

**Zero-loss = zero *excess* routing loss:** the router always selects the exact-minimum-length route, so it never adds
avoidable loss by mis-ranking a near-tie. (Not literally zero photon loss — physics forbids that.)

## Exactness scope (honest)

- **Unconditional & separately gated:** (a) the O_h bulk geodesic is exactly shortest on the pristine lattice
  [2147: oracle == exact Dijkstra, greedy beats all 3 elementary diagonal exchanges]; (b) each local detour is exactly
  shortest within its subgraph [2144/2146]; (c) `traj_len_sign` never mis-ranks two route lengths [2143/2121].
- **Hypothesis (NOT claimed):** a *global* route = bulk legs spliced with detours is globally shortest only when defects
  are **isolated** (neighborhoods don't overlap). Dense-defect regions need a full bounded search. 2151 gates the
  pieces, not the splice. Scope: cubic king-move lattice (O_h).

## Conscience: theorem-to-machine (six rungs)

1. **STATEMENT.** (a) For `(dx,dy,dz)∈ℤ³` with king-moves of squared-length ∈{1,2,3}, let `(p,q,r)=sort⁻(|dx|,|dy|,|dz|)`;
   the minimum path length is `r√3+(q−r)√2+(p−q)√1`, O(1)/O(1)-memory. (b) For non-negative integer amounts,
   `sign((a₁√1+b₁√2+c₁√3)−(a₂√1+b₂√2+c₂√3)) ∈ {−1,0,+1}` is exact.
2. **HYPOTHESES.** (i) cubic king-move lattice (moves' squared-lengths ∈{1,2,3}); (ii) greedy body/face/axis
   decomposition is optimal; (iii) i64/bigint envelope (amounts are bigint → workspace-scale exact); (iv) route lengths
   are per-class integer amounts.
3. **DISCHARGE (checked).** oracle — `photon_route.iii:55,63` (`lattice_dist_oracle`), DISCHARGED; comparator —
   `photon_route.iii:76` (`traj_len_sign`), DISCHARGED; optimality (ii) — gate `2147`; compare exactness — gate `2143/2121`.
4. **REALIZATION.** `photon_route.iii` (`plr_bulk`, `plr_cmp_len`, `plr_detour_solve`) + `2151_photon_route.iii`. Runs:
   compile rc=0; link rc=0; direct run exit 99; `run_sqrtsum_kats.sh` → `PASS 2151`, `19/0`. Observables:
   `B: 300000 400000 300000 h=1000000` · `Z: elo -344 ehi 641 exact 1 pick 0` · `D: 1 0 7 cmp -1 unr 0`.
5. **FALSIFIER (teeth).** Mutate a bulk amount → Arm BULK → exit 10; break the near-tie sign / remove the straddle →
   Arm ZERO-LOSS → exit 20; corrupt the detour amounts / comparator / reachability guard → Arm DETOUR → exit 30.
   **Demonstrated:** mutating the detour expectation `7→6` on a scratch copy reddened the gate to **exit 30**.
6. **VERDICT: PROVEN-IN-CODE** within scope (cubic king-move lattice; per-piece exactness unconditional; global splice
   stated as hypothesis, not claimed).

## Adversarial verdict — SURVIVES (high) within scope

- **Unstated hypothesis:** greedy-decomposition *optimality* (e.g. `2√2=2.83` vs `√3+1=2.73` ⟹ body+axis is cheaper —
  the greedy picks it). Discharged by gate `2147` (oracle == exact Dijkstra). Stated, not assumed.
- **Edge cases:** `(0,0,0)`→length 0; single-axis `(n,0,0)`→`n` axis; negative coords via `|·|`; million-scale amounts
  fit i64 and `traj_len_sign` uses bigint mags (no overflow); `plr_cmp_len` uses disjoint `PLR_A/PLR_B` buffers.
- **Degenerate pass:** `plr_cmp_len` returns `0` only via the exact-zero certification (genuine); the near-tie arm proves
  a non-equal near-tie returns `±1`; **negative arm** proves an unreachable detour target returns `0` (never a false path).
- **Precondition at call site:** `traj_len_sign` needs radicands ≥0 (`PLR_RAD={1,2,3}`) and bigint-handle mags (from
  `bigint_from_u64`); `lattice_shortest_path_c` needs edge amounts as handles alive across the solve (persistent arena `tar`).

## Completion contract (all boxes, with evidence)

| Obligation | Evidence |
|---|---|
| POSITIVE | `2151` exit 99 (in-harness) |
| NEGATIVE | unreachable target → `unr 0`; fixed-precision straddle `[-344,+641]` (naive method fails) |
| TEETH | mutant `7→6` → exit 30 (proven) |
| REALIZATION | first shipped consumer of `lattice_dist_oracle` + `traj_len_sign` + `lattice_shortest_path_c` |
| DETERMINISM | pure integer/bigint; gate-owned, delegated in `run_corpus` (no core-seal drift) |
| CORPUS | `run_sqrtsum` 19/0; new test `2151` added; `run_corpus` delegates it |
| BINARY | no codegen/metal change (pure `.iii` organ) — N/A |
| CALIBRATION | per-piece exactness = gated-fact; global splice = stated hypothesis; zero-loss = zero-excess (defined) |

## The observables

```
B: 300000 400000 300000 h=1000000   # displacement (1e6, 7e5, 3e5) → 3e5 axis + 4e5 face + 3e5 body = 1e6 hops, O(1), zero node memory
Z: elo -344 ehi 641 exact 1 pick 0  # 577√1 vs 408√2: fixed precision f=10 STRADDLES (−344<0<641); exact compare = +1; router picks the shorter relay
D: 1 0 7 cmp -1 unr 0               # defect blocks direct 10√1; exact search finds 7√2 (=√98<10); cmp confirms shorter; unreachable node → 0 (reject)
```

**Caveat on the `f=10` straddle (honesty):** `f=10` *stands in for any fixed precision*. f64 (f=52) resolves the specific
577/408 constant fine — the sound claim is that the **unbounded Pell family** (577/408 → 1393/985 → …) defeats *any*
fixed precision `f`, so no float format is uniformly safe; `f=10` merely exhibits the mechanism at legible scale. The
adaptive/exact predicate pays the instance's true precision and always resolves it.
