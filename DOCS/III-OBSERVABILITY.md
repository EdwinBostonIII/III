# III-OBSERVABILITY.md — Always-Available System Information Architectural Mandate

**Document Identity:** OBSERVABILITY / Architectural Mandate / Wave 2 / Items 26-32
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-2+ implementation.** This document specifies the architectural mandate for the OBSERVATORY collapse (per Stateful Neumann S15) and the always-available system-info regime.
**Version:** 1.0 — 2026-05-03 (Wave 2.1)
**Sources:** All 15 R1-sealed specs; III-PERFORMANCE.md; III-CYCLES (A5); III-CATALYST (B1); existing CHARIOT/XII OBSERVATORY plane (`OBSERVATORY/*.c`).
**Cluster integrated:** items 26 (OBSERVATORY collapse into evaluator), 27 (always-available system info), 28 (12-family threshold library), 29 (saturation predicates as first-class effects), 30 (WLISHI live introspection), 31 (system-wide health metrics), 32 (operator query API).
**Sibling Wave-2 doc:** III-ZK-PRUNING.md (item 175, audit-chain compression).

---

## §0. Preamble — Observability is Not a Plane, It is a Property

Conventional systems treat observability as a separate plane: a logging subsystem, a metrics aggregator, a tracing collector, an audit-chain replicator. Each is a separate process, with its own bugs, latencies, schemas, and consistency guarantees. The operator queries the observability plane to learn about the system's state — and may receive stale, lossy, or inconsistent data because the plane is *external* to the substrate it observes.

**III rejects this.** Observability is not a plane in III; it is a **property of every cycle invocation**. Per Stateful Neumann §3.4 / S15, the OBSERVATORY plane *vanishes as a separate subsystem*. Saturation evaluation becomes a per-cycle property checked inline by the cycle dispatcher's evaluation frame. Each cycle declares its sufficiency gate; the dispatcher evaluates it inline; saturation triggers downstream effects (causal inference, Catalyst hypothesis, operator alarm).

The result: **the substrate has total real-time knowledge of itself**. Every operational property is computed inline; every threshold crossing is observed at the moment it occurs; every saturation event is witnessed; every operator query returns *current* state, not stale-replicated state.

This document specifies the seven items integrated into the architecture:

1. **§1** — The OBSERVATORY collapse mandate (item 26)
2. **§2** — The 12-family threshold library (item 28)
3. **§3** — Saturation predicates as first-class effects (item 29)
4. **§4** — Always-available system info: the substrate-wide State surface (item 27)
5. **§5** — WLISHI live introspection layer (item 30)
6. **§6** — System-wide health metrics (item 31)
7. **§7** — Operator query API: `system.observe(...)` (item 32)
8. **§8** — Conformance criteria
9. **§9** — Final statement

---

## §1. The OBSERVATORY Collapse (Item 26)

### §1.1 The mandate

The 21-schema OBSERVATORY plane (per CHARIOT/XII `OBSERVATORY/*.c` ~30 files) is **eliminated as a separate subsystem**. Its functionality moves into:

- The cycle dispatcher (per III-CYCLES §3): inline sufficiency-gate evaluation.
- The standard library (per III-STDLIB / `LOGOS/STDLIB/sufficiency/`): the 12 threshold families.
- The witness emission path (per III-CYCLES §6.4): inline saturation reporting via witness flags.

### §1.2 The new annotation

Every cycle that requires observability gains a `@track(...)` annotation:

```iii
cycle process_request(req: Request) -> Response
    @ring(R0)
    @hexad(REQUEST_PROCESS)
    @track(
        accumulator: latency_ns,
        threshold: hoeffding(0.95, 100),
        on_saturation: { emit_alarm(alarm_kind: HIGH_LATENCY) }
    )
{
    forward { ... }
}
```

The `@track` annotation:

- `accumulator`: the per-cycle observable (e.g., latency, throughput, error rate).
- `threshold`: a sufficiency gate from the 12-family library.
- `on_saturation`: a closure invoked when the threshold's saturation predicate becomes true.

### §1.3 Implementation in the dispatcher

The dispatcher (per III-CYCLES §3) gains a per-cycle inline check:

```iii
fn dispatch_cycle(cycle: Cycle, args: ...) -> Result {
    // Standard cycle dispatch...
    let result = invoke_forward_handler(cycle, args)

    // Observability collapse: inline saturation check.
    when cycle.has_track_annotation -> {
        cycle.accumulator.update(measure(result))
        when cycle.threshold.is_saturated(cycle.accumulator) -> {
            cycle.on_saturation.invoke()
            emit_witness(WITNESS_FLAG_SATURATION_FIRED)
        }
    }

    return result
}
```

The check costs **~5-15 cycles** when annotated, **0 cycles** when un-annotated. Vs the prior CHARIOT/XII architecture (separate observability thread, witness-bus tap, schema registry) which cost ~200-500 cycles in cross-thread synchronization per observed cycle.

### §1.4 Net file impact

Per Stateful Neumann §3.4: ~30 OBSERVATORY files retired. Functionality preserved in ~5 STDLIB files + dispatcher inline.

### §1.5 The lossless guarantee

The collapse **does not lose information**. The 21 prior OBSERVATORY schemas correspond to the 12 threshold families × specific accumulator types; the substrate retains the same observability semantics, just inline rather than in a separate plane.

---

## §2. The 12-Family Threshold Library (Item 28)

### §2.1 The library

The standard library exports 12 sufficiency-gate families, each a closure-pinned function returning a `Threshold` value:

| Family | Constructor | Accumulator | Saturation Predicate |
|--------|-------------|-------------|----------------------|
| Hoeffding | `hoeffding(confidence, n_min)` | sample mean ± half-width | half-width ≤ ε |
| Multinomial | `multinomial(confidence, n_min, k_categories)` | category counts | each category n_i ≥ n_min/k |
| Wilson | `wilson(confidence, n_min)` | binomial proportion | confidence interval width ≤ ε |
| Poisson | `poisson(confidence, n_min)` | event count | √n / λ ≤ ε |
| Coupon | `coupon_collector(k, confidence)` | distinct-events seen | n ≥ k log k * coupon_factor(confidence) |
| CMSketch | `cmsketch(width, depth, confidence)` | count-min sketch | ε-approximate |
| OrderStat | `order_stat(quantile, confidence, n_min)` | sample order stats | confidence interval ≤ ε |
| Nyquist | `nyquist(sample_rate, signal_band)` | sample stream | sample_rate ≥ 2 × signal_band |
| ESS | `effective_sample_size(target)` | weighted sample stream | ESS ≥ target |
| Heaps | `heaps(alpha, beta, n_min)` | distinct-token count | Heaps' Law fit converged |
| RuleOfThree | `rule_of_three(confidence)` | zero-event count | n ≥ -ln(1 - confidence) / 3 |
| Multinomial-Dirichlet | `multinomial_dirichlet(prior, confidence)` | Dirichlet posterior | posterior credible interval ≤ ε |

### §2.2 Each family is hand-rolled

Per the NIH discipline (per III-FOUNDERS-ANCHOR.md / standards), each threshold family is hand-rolled from the relevant statistical literature, with full constant-time discipline (where applicable):

- **Hoeffding** from Hoeffding 1963.
- **Wilson** from Wilson 1927.
- **Multinomial-Dirichlet** from Bishop 2006 / FrequenciesAreFunctions.
- **Coupon** from Feller 1968 / Motwani-Raghavan.
- **CMSketch** from Cormode-Muthukrishnan 2005.
- **Heaps' Law** from Heaps 1978.
- etc.

Each family ships with KAT (Known-Answer Test) fixtures verifying its saturation predicate produces correct results on synthetic data with known ground truth.

### §2.3 Closure-pinning

Each threshold family's source is closure-pinned (per III-MODULES). Modifying a family's algorithm requires Tier-3 amendment + Founder's Anchor cosignature. This protects against silent statistical errors that would corrupt the substrate's observability.

### §2.4 Composition

Multiple thresholds may be composed via the `Threshold.and(...)` / `Threshold.or(...)` / `Threshold.until(...)` combinators:

```iii
let composed = hoeffding(0.95, 100).and(wilson(0.99, 50))
```

Composition produces a new `Threshold` whose saturation predicate is the boolean combination.

---

## §3. Saturation Predicates as First-Class Effects (Item 29)

### §3.1 The mandate

Saturation events are first-class effects (per III-EFFECTS / A4). They are:

- **Witnessed**: emit a witness with `WITNESS_FLAG_SATURATION_FIRED`.
- **Hexad-classified**: hexad `OBS_SATURATION_FIRE` (POS pillar 1, ZERO pillars 2-6, ZERO pillar 4).
- **Cap-gated**: receivers of saturation events must hold `cap<observe>` for the relevant cycle's domain.
- **Trinity-gated**: cross-tier propagation of saturation events requires Trinity gate evaluation (transient → host_file → federation requires Trinity admission).

### §3.2 Saturation effect kind

```iii
effect SaturationFire {
    cycle_kind: CycleKind,
    threshold_family: ThresholdFamily,
    accumulator_value: Glyph,
    saturation_witness_mhash: mhash,
    timestamp: u64,
}
```

### §3.3 The cap discipline

```iii
cycle observe_saturation(cap: cap<observe<Domain::REQUEST_PROCESS>>) -> SaturationFire? {
    forward {
        // Pulls the next saturation event from the per-CPU saturation queue.
        // Returns None if no event ready.
    }
}
```

Holding `cap<observe<X>>` is itself Trinity-gated; only operators with the appropriate ceiling can acquire it.

### §3.4 Saturation backpressure

If the saturation queue fills (operator not consuming), the substrate emits `compromise.medium` with reason `saturation-backpressure`. This is itself a witnessable event; the operator can audit and remediate.

---

## §4. Always-Available System Info — the State Surface (Item 27)

### §4.1 The mandate

Every property of the substrate is **queryable in O(1) time** without spinning up a query thread or aggregating from external storage. The substrate exposes a **State surface**:

```iii
namespace system.state {
    fn current_epoch() -> u64
    fn closure_root() -> mhash
    fn r1_composite_root() -> mhash
    fn drtm_quote_chain_length() -> u64
    fn anchor_pubkey() -> bytes[32]
    fn active_cryptographic_suite() -> u64
    fn federation_peer_count() -> u32
    fn audit_chain_height() -> u64
    fn audit_chain_root() -> mhash
    fn catalyst_promotion_count() -> u32
    fn mobius_coherence_q14() -> u32
    fn per_cpu_witness_ring_occupancy(cpu: u32) -> u32  // 0..100 percent
    fn current_cycle_rate_per_sec() -> u32
    fn recent_compromise_classes() -> [CompromiseRecord; 16]
    fn anchor_witness_silence_seconds() -> u64
    fn last_drtm_relaunch_timestamp() -> u64
    fn observatory_saturated_cycle_kinds() -> [CycleKind; N]
    fn current_wavefront_size() -> u32
    fn proof_kernel_invariants_held() -> bool
    fn sealed_cycle_box_states() -> [SealedCycleBoxState; 10]
    fn pkru_register_per_cpu(cpu: u32) -> u32
    fn npt_class_summary() -> NptClassSummary
    fn iommu_ipt_summary() -> IommuIptSummary
    fn jit_compiled_cycle_count() -> u32
    fn causal_dag_edge_count() -> u32
    fn federation_quorum_state() -> QuorumState
    fn pending_amendment_proposals() -> [AmendmentProposal; N]
    fn zk_pruning_compaction_ratio() -> Q14   // see III-ZK-PRUNING.md
}
```

### §4.2 The implementation discipline

Each function:

- Returns in **O(1) time** (cache-pinned counters; no spinlocks; no inter-CPU broadcasts).
- Reads from **per-CPU NUMA-local replicas** (per III-PERFORMANCE.md §3.3, §15).
- Returns the **current** value (not a snapshot or eventually-consistent stale value); a single read of an atomic counter.

### §4.3 The cap discipline

Each query function requires:

```iii
fn current_epoch() -> u64
    @ring(R3)
    @hexad(STATE_QUERY)
    @cap(observe<system_state>)
```

Holding `cap<observe<system_state>>` is granted by default to the operator and to ceiling-admitted observers. Federation peers requesting state queries must pass Trinity (per the federation tier).

### §4.4 Performance impact

Each State query: **~3-5 cycles** (single L1-cache-pinned read + return). Per-second, the substrate can answer **~800M State queries** without performance impact.

---

## §5. WLISHI Live Introspection Layer (Item 30)

### §5.1 The mandate

The WLISHI (Witnessed Live Introspection of Substrate History) layer (per Stateful Neumann §3.4) provides **interactive operator exploration** of the substrate's state and history.

### §5.2 The REPL surface

```
> system.state.current_epoch
=> 17

> system.state.recent_compromise_classes(limit=8)
=> [
     { class: COMPROMISE_LOW, reason: "anchor-invariant-violation", count: 3, last_seen_epoch: 17 },
     ...
   ]

> system.audit.replay(epoch_range: 15..17, cycle_kind: REQUEST_PROCESS)
=> [witness, witness, ...]

> system.causal.explain(witness_mhash: <hash>)
=> Causal chain:
     witness <hash-1> → cycle CYCLE_A (90% confidence)
     cycle CYCLE_A → cycle CYCLE_B (87% confidence)
     ...

> system.counterfactual.run(rewind_to: <hash>, intervene_with: { ... }, replay_to: <hash>)
=> Diverged at: <hash-X>
   Factual chain: ...
   Counterfactual chain: ...

> system.catalyst.audit_anchor_attempts(epoch_range: 14..17)
=> [{ candidate_id: ..., reason: "would-modify-anchor-pubkey", rejected_at_epoch: 15 }, ...]
```

### §5.3 The witness chain integration

Every WLISHI query is itself a witnessed cycle. The operator's interactive session is preserved in the audit chain. This means:

- Past sessions are replayable.
- Operator queries at high tier (e.g., suite-swap directives) are auditable.
- The substrate's "memory" of operator interaction is itself in the Reduction graph.

### §5.4 Implementation

`LOGOS/STDLIB/wlishi/` — the REPL parser + query dispatcher + result formatter. Hand-rolled NIH; no readline / linenoise / GNU history.

---

## §6. System-Wide Health Metrics (Item 31)

### §6.1 The metrics

The substrate continuously computes and exposes the following health metrics (each accessible via §4 State surface):

| Metric | Definition | Healthy Range |
|--------|------------|---------------|
| Möbius coherence Q14 | Rolling-sum Möbius coherence over last 16384 cycles | ≥ 0.75 (Q14 ≥ 12288) |
| Witness ring occupancy | % of per-CPU ring used | < 75% (sustained); < 90% (peak) |
| Audit chain commit lag | μs between witness emission and BCWL-index commit | < 1ms (p99) |
| Catalyst rate | Promotions per chronos tick | ≤ 8 (per `XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK`) |
| Causal-DAG edge confidence | Mean edge confidence in DAG | ≥ 0.5 |
| Federation quorum availability | % of expected peers responsive | ≥ 95% (for tier ≤ host_file); ≥ 100% (for constitutional) |
| Compromise rate (LOW) | LOW compromise events per epoch | ≤ baseline + 3σ |
| Compromise rate (MEDIUM) | MEDIUM compromise events per epoch | ≤ baseline + 1σ |
| Compromise rate (HIGH) | HIGH compromise events per epoch | == 0 (any HIGH triggers operator alarm) |
| JIT compilation success rate | % of promoted candidates that successfully JIT-compile | ≥ 99% |
| Saturation event rate | Events / sec from `@track`-annotated cycles | varies by workload; baseline + 3σ flag |
| Anchor witness silence | Seconds since last operator-Anchor-injected witness | < operator-configured threshold |

### §6.2 Health-state aggregation

The substrate computes an aggregate **health score** (Q14) over all metrics:

```iii
fn substrate_health_q14() -> u32 {
    // Geometric mean of normalized metrics, weighted by criticality.
    let mut prod_q14: Q14 = Q14_ONE
    for (metric, weight) in HEALTH_METRICS {
        let normalized = normalize(metric.current_value, metric.healthy_range)
        prod_q14 = prod_q14 * pow_q14(normalized, weight)
    }
    return prod_q14
}
```

Health score below 0.5 (Q14 < 8192) emits `compromise.medium` with reason `substrate-degraded-health`.

### §6.3 The operator dashboard

The operator can view all metrics + the aggregate score via:

```
> system.health
Substrate Health: 0.87 (Q14: 14254)
  Möbius coherence: 0.84 (Q14: 13763)  ✓ healthy
  Witness ring occupancy:
    cpu0: 23%  ✓
    cpu1: 31%  ✓
    cpu2: 28%  ✓
    ...
  Audit chain commit lag p99: 0.4ms  ✓
  Catalyst rate: 5/tick  ✓
  Causal-DAG edge confidence: 0.62  ✓
  Federation quorum availability: 100%  ✓
  Compromise (LOW): 12/epoch (baseline 8 ± 3)  ✓
  Compromise (MEDIUM): 1/epoch (baseline 0.3)  ⚠
  Compromise (HIGH): 0  ✓
  JIT success: 99.8%  ✓
  Anchor witness silence: 18 sec  ✓
```

Implementation: `LOGOS/STDLIB/observability/health_dashboard.lgs`.

---

## §7. Operator Query API — `system.observe(...)` (Item 32)

### §7.1 The mandate

The operator can compose arbitrary queries over substrate state via `system.observe(...)`:

```iii
namespace system.observe {
    fn cycles_in_epoch(epoch: u64) -> u64
    fn cycles_of_kind(kind: CycleKind, epoch_range: Range<u64>) -> u64
    fn witnesses_with_flag(flag: WitnessFlag, epoch_range: Range<u64>) -> [Witness]
    fn saturation_events(cycle_kind: CycleKind, epoch_range: Range<u64>) -> [SaturationFire]
    fn cap_acquisitions(cap_kind: CapKind, epoch_range: Range<u64>) -> [CapAcquireRecord]
    fn amendments(tier: Tier, epoch_range: Range<u64>) -> [AmendmentRecord]
    fn catalyst_promotions(epoch_range: Range<u64>) -> [PromotionRecord]
    fn jit_compilations(epoch_range: Range<u64>) -> [JitCompileRecord]
    fn federation_peer_state(peer_id: PeerId) -> PeerState
    fn proof_kernel_invariants_violations(epoch_range: Range<u64>) -> [InvariantViolation]
    fn anchor_witness_chain(epoch_range: Range<u64>) -> [AnchorWitness]
}
```

Each function is itself a witnessed cycle (per the same discipline as §5.3).

### §7.2 The query plan

Each query is decomposed into:

1. A range scan over the audit chain (per BCWL index).
2. A filter by witness flag / cycle kind / etc.
3. An optional projection (e.g., extract only saturation values).

The query plan is **closure-pinned** (the planner's source cannot be modified at runtime). This protects against query-injection attacks where an attacker supplies a custom query plan that bypasses cap checks.

### §7.3 The query budget

Queries that would scan more than `XII_OBSERVABILITY_QUERY_MAX_WITNESSES = 1_000_000` witnesses require **explicit operator consent** via Trinity gate (operator-acknowledged that the query is expensive). This prevents queries that accidentally consume substrate resources for hours.

### §7.4 The query witness

Every query emits:

- `WITNESS_FLAG_QUERY_INITIATED` (when the query begins).
- `WITNESS_FLAG_QUERY_COMPLETED` (when results are returned).
- The query's parameters and result-mhash are part of the witness body.

This ensures the operator's queries are themselves auditable. A future operator can replay past queries.

---

## §8. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-OBS-1 | The OBSERVATORY plane is collapsed into the dispatcher; no separate observability subsystem in the build (per item 26) |
| C-OBS-2 | All 12 threshold families pass their KAT corpus on synthetic data (per item 28) |
| C-OBS-3 | Threshold families are closure-pinned; modification requires Tier-3 + Anchor cosignature |
| C-OBS-4 | Threshold composition (`and`, `or`, `until`) produces correct boolean combinations |
| C-OBS-5 | `@track` annotation overhead is <15 cycles per cycle when no saturation fires |
| C-OBS-6 | `@track` annotation overhead is 0 cycles for un-annotated cycles |
| C-OBS-7 | Saturation-fire effect is witnessed; `WITNESS_FLAG_SATURATION_FIRED` is set |
| C-OBS-8 | Saturation effect is hexad-classified `OBS_SATURATION_FIRE` |
| C-OBS-9 | Saturation effect requires `cap<observe<Domain>>` for receiver |
| C-OBS-10 | State-surface queries return in <5 cycles |
| C-OBS-11 | State-surface queries read from per-CPU NUMA-local replicas |
| C-OBS-12 | WLISHI REPL queries are witnessed and replayable |
| C-OBS-13 | Health-score aggregate computes correctly per §6.2 formula |
| C-OBS-14 | Aggregate score < 0.5 emits `compromise.medium` |
| C-OBS-15 | `system.observe(...)` queries respecting `XII_OBSERVABILITY_QUERY_MAX_WITNESSES` cap |
| C-OBS-16 | Query plan is closure-pinned; runtime-modifiable plans are rejected |
| C-OBS-17 | Query parameters and result-mhash are included in query witness body |
| C-OBS-18 | The 21-schema legacy OBSERVATORY semantics are preserved by the inline implementation |
| C-OBS-19 | Pre-existing CHARIOT/XII OBSERVATORY tests pass against the collapsed implementation |
| C-OBS-20 | All `system.state.*` and `system.observe.*` functions return current (not stale) values |

---

## §9. Final Statement

The OBSERVATORY collapse is the architectural commitment that observability is not a plane in III; it is a property of every cycle. The 21-schema OBSERVATORY plane retires; its semantics inline into the dispatcher; the operator gains O(1) queries against the entirety of substrate state.

This is the answer to items 26-32. Wave 2.1 is the realization that the substrate's self-knowledge is itself a substrate primitive, not a queryable add-on.

*Wave 2.1 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03.*
