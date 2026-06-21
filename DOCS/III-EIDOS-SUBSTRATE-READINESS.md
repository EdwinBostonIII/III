# III — EIDOS Substrate Readiness Map
### The leverage base, verified: every organ EIDOS wraps, its exact API, ready/gap, and the FR it backs
> **Date:** 2026-06-20 · **Author pass:** /architect · /deep-think · /math-olympiad (adversarial, native) · advisor-disciplined
> **Companion to:** `III-EIDOS-ARCHITECTURE.md` (the architecture; authored separately). **This doc does NOT
> design EIDOS** — it prepares + verifies the stdlib substrate EIDOS will invoke, grounded in the real
> signatures (read top-to-bottom) + the canonical build (`PASS=674 / FAIL=0`, mhash `6b1c027b`, all 3 coverage
> ratchets 0). Goal: EIDOS rests on **gated facts**, not assumptions.

---

## 0. VERDICT — the substrate is READY; one note (`dome`)

Every organ the EIDOS leverage base names **exists and is sealed in MODULES + KAT-green** (the canonical
build covers all of them) — **except `omnia/dome`**, which exists but is **not in MODULES** (a loose research
organ; its only KAT `1903` was retracted as toy, `III-INVERSE-LIBRARY.md` §1). **No blocking gap:** the
rewind + provenance + anti-geometry capability EIDOS FR-5/§3.3 wants from `dome` is available **sealed** via
`omnia/reverse_search` (`rs_*`, built + sealed this session) and the branch-retaining fold via
`event_substrate`/`isub`. EIDOS should wrap `reverse_search` (sealed) for rewind, and treat `dome_rewind` as
optional/unsealed — or seal `dome` behind a real (non-toy) KAT first.

Two findings make EIDOS's two riskiest assumptions **stronger than the architecture cautiously claims** (§2, §3).

---

## 1. THE VERIFIED API MAP (exact externs EIDOS will use)

| Organ (sealed) | Real API (signatures verified) | Backs |
|----------------|--------------------------------|-------|
| `omnia/ripple_field` | `rf_reset()` · `rf_add_node(prim:u8,hex:u8)->u32` · `rf_add_edge(from:u32,to:u32)` · `rf_edge_field(pf,pt,hf,ht:u8)->i64` · `rf_node_potential(idx:u32)->i64` · **`rf_inverse_potential(idx:u32)->i64`** · `rf_steepest()->u32` · `rf_rank(h:u8)->u32` | FR-1 spatial · FR-3 direction |
| `omnia/isub` | `isub_reset()` · `isub_emit(verb,a,b:u32)->u64` · `isub_cav_into(...)` · `isub_witness_into(out32)` · accessors | FR-1 temporal · FR-7 identity |
| `omnia/event_substrate` | `evt_perceive(...)` · `evt_winner/maxprio(upto)` · `evt_detect_cycle` (lasso) | FR-1 temporal fold |
| `omnia/reverse_search` | `rs_search_evade/naive` · `rs_fixpoint_evade` · `rs_provenance_count` · `rs_is_trap` (anti-geometry) | FR-5 rewind (sealed) |
| `omnia/assimilate` | `assim_add(verb,a,b)` · `assim_meet/join/complement` · `assim_leq` | FR-2/7 web (executable) |
| `omnia/master_logic` | `ml_named_is_redundant()` · `ml_shatter_logic6()` | FR-9 retire-by-attrition |
| `omnia/unravel` | `unravel_is_chain/height/has_lasso/verb` (real-trace → geometry) | FR-2 descriptor bootstrap |
| `omnia/exec_cert` / `numera/cad` | `xc_begin/event_byte/seal` · `cad_oneshot/eq` (sha256) | integrity / witness ROOT |
| `numera/cost_lattice` | `cl_join/meet(*u64)` · `cl_dominates(a,b)->u8` | FR-4 cost |
| `numera/pareto_frontier` | `pf_setup()` · `pf_dominates(a,b)->u32` · `pf_on_frontier(k)` · `pf_scalarize(w_lat,w_ene)->u32` | FR-4 prune |
| `numera/microarch_model` | `ma_init()` · `ma_simulate(ops,n,deps,dep_n,out_cycles)` · `ma_trace_hash` | FR-4 energy/latency vector |
| `nous/nous_socket` | **`nous_rank(ctx_term:u32, kind:u32, out_order:*u64, cap:u32)`** · `nous_active()` · `nous_should_engage(kind)` | FR-3 proposer (§3.4.1) |
| `omnia/xii_canonicalise` | `xii_canonicalise(t)->u32` · `xii_canonicalise_last_steps()` | FR-3 plan canonicalise |
| `aether/{topology_atlas,pq_quorum,snapshot_lattice}` · `numera/reversible` | federation + snapshot + undo | FR-8 distribute · FR-5/6 reverse |
| `katabasis/{cpu_census,behavioral_seed}` | the silicon/behavioral identity crystal | FR-6 LATCH (proven) |

All sealed; `dome` is the lone unsealed leverage organ (see §0).

---

## 2. FINDING — FR-1's substrate is already GATED (not just a conjecture)

The architecture marks FR-1 ("ripple ≡ inverse-event") **NEW + CONJECTURE (Slice 0)**. The *substrate* for it
is stronger than that: `ripple_field`'s own header + corpus **`834` (= 99, sealed)** already prove the exact
structure FR-1 leans on —

```
field(from,to) = sign(rank(hex_to) − rank(hex_from)) · dK(prim_from, prim_to)        [pure, sealed content]
ANTISYMMETRY  : rf_edge_field(a,b) == − rf_edge_field(b,a)   (forward = node_potential ; inverse = inverse_potential)
```

This is precisely EIDOS §3.1's map: the spatial **sign IS the order verb** (BELOW climbs toward ORIGIN), and
the **antisymmetry IS the order-reversing involution** (REFLECT). So one half of the unification (the spatial
ripple with a forward/inverse dual whose sign encodes a `{BELOW,REFLECT}`-shaped order) is a **gated fact
today**, and `isub` provides the other half (the same `<verb,a,b>` as a content-addressed event). **Slice 0
is therefore a *binding* step (prove ONE content-address binds the two live reads), not a from-scratch
discovery** — the two reads, with compatible geometry, already exist and are green. *(Adversarial caveat,
math-olympiad discipline: `834` proves the antisymmetry of the SPATIAL field; it does NOT prove the spatial
magnitude `dK` equals a temporal fold over `isub` events — that magnitude≡fold equality is the genuine open
half Slice 0 must still gate. The sign/involution half is done; the magnitude half is not.)*

---

## 3. FINDING — §3.4.1's `nous`-over-XII-term assumption holds at the API level

The architecture flags (§3.4.1) that the planner's proposer assumes `nous` *"ranks the next TERM"* over XII
terms, and that EIDOS must encode a quantum's eidos as an XII term for `nous` to rank it natively. Verified:
`nous/nous_socket` exposes **`nous_rank(ctx_term: u32, …)`** — it ranks over a `ctx_term`, an XII term index.
So the proposer is **already XII-term-native**; the remaining work is the *encoding faithfulness*
(eidos → XII term), which is EIDOS's Slice-0 test, not a missing substrate. The fallback the doc names (a thin
descriptor-ranker, still no ML) is only needed if that encoding fails — the proposer API itself is ready.

---

## 4. THE ONE GAP — `dome` unsealed (and its sealed cover)

`omnia/dome` (the branch-retaining rewind: `dome_rewind`/`dome_provenance_count`/`dome_recurred` lasso) is a
real, pure mechanism but is **not in MODULES** and its KAT `1903` is the retracted toy. EIDOS has three clean
options, in order of preference:
1. **Wrap `reverse_search` (sealed) for rewind+anti-geometry** + `event_substrate` for the fold — covers
   FR-5 with zero new risk. *(Recommended; what's already green.)*
2. Seal `dome` behind a **new real (non-toy) KAT** proving the rewind *mechanism* (not the retracted
   "evade-by-living theorem") — a small, honest increment if EIDOS specifically wants `dome_rewind`.
3. Leave `dome` loose and link it as a side-effect object (the `run_corpus` mechanism) — discouraged (an
   unsealed dependency for a production layer).

---

## 5. READINESS CHECKLIST (vs `III-EIDOS-ARCHITECTURE.md` §12 ledger)

- **EXISTS / sealed / green:** isub, exec_cert, cad, event_substrate, reverse_search, assimilate,
  master_logic, unravel, logic6, ripple_field, cost_lattice, pareto_frontier, microarch_model, nous,
  xii_canonicalise, aether (topology_atlas/pq_quorum/snapshot_lattice), reversible, observe, katabasis census
  — **all confirmed in MODULES + covered by the canonical build (PASS=674/FAIL=0).**
- **EXISTS / unsealed:** `dome` — §4.
- **EXISTS / PROVEN:** katabasis identity census — `cpu_census`/`behavioral_seed` present.
- **Composability — substrate-level:** the FR-1 sign/involution half is gated (`834`); `nous` is XII-term
  native. The remaining composability (magnitude≡fold; ripple+cost+nous jointly planning) is **Slice 0's job**
  — the architecture already schedules it, and the pieces it composes are all live + green.

**Net:** the leverage base is prepared and optimal. EIDOS can be authored against the verified APIs above with
no missing organ; its two riskiest assumptions have a gated substrate foundation; the only housekeeping is the
`dome` decision (§4), for which a sealed alternative already exists.
