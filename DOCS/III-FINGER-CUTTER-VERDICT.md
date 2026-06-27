# III — The Finger-Cutter Verdict

> *"Look through your III directory. Somewhere there is an entire windows/gnn/etc suite of
> everything anybody could imagine, but in III… we wire your helmet to track it and find the
> finger-cutter."*

A reconnaissance of the sovereign III suite: identify the one self-amputating component, point
the cartographer at it, and rule **LIVE vs SHEATHED**. Read-only; no sealed source was touched.

---

## 1 · The suite ("everything… but in III")

The cartographer's live scan (`III-CARTOGRAPHER/III-SYSTEMS-MAP.md`, **scan #80, 2026-06-21
15:38**) is the inventory — it is not re-authored here, it is cited:

| | |
|---|---|
| `.iii` modules | **834** across **16 domains** |
| Dependency edges | 1790 · max depth 22 |
| The OS / "Windows-as-guest" layer | `aether` (70) + `katabasis` (22): `develop_up`, `sealed_box`, `enclave`, `sentinel`, `vmexit`, `svm_layout`, `ring_lattice`, `hypervisor_entropy_seal`, `flow_firewall`, `determinism_firewall` |
| Number / proof / crypto core | `numera` (282): bigint, galois, keccak, rsa, mlkem, zk_snark/stark |
| The XII rewrite engine | `omnia` (157) |
| Language / NL stack | `verba` (46): glyph v3, nl_lex, nl_parse, hip, ontology |
| The proposer "soul" | `nous` (28) · sealing `sanctus` (31) · optimizer `forcefield` (26) |

"Take it for ourselves" = **know and own what III already self-hosts.** The catalog already
exists and regenerates on scan; the deliverable below is the *finding*, not a parallel inventory.

## 2 · The helmet is already tracking the cutter

The native tracker `III-CARTOGRAPHER/carto.exe` (rebuilt 2026-06-20) surfaces all five organs of
the cutter by name and role in today's map — no wiring gap:

- `daemon_scythe`        — **THE EXECUTIONER** (L16, deepest layer)
- `cg_surgical_strike`   — **THE AST REWRITER** (L15)
- `ast_hunter`           — **TARGET ACQUISITION** (L1)
- `proof_bisimulation`   — **THE EQUIVALENCE ENGINE** (L14)
- `scythe_census`        — **THE CERTIFIED OPTIMIZATION CENSUS** (L14)

## 3 · The finger-cutter: **the Isomorphic Scythe**

The amputation faculty. It HUNTS an optimal replacement, PROVES universal equivalence + strict
cost improvement in the CIC kernel, and RECORDS the certified rewrite — surfacing the set of
legacy functions *mathematically proven redundant* ("negative tech debt"):

```
daemon_scythe ──> ast_hunter ──> egraph_stochastic        (cheap candidate search — pure)
      │            (TARGET ACQUISITION)
      └─────────> cg_surgical_strike ──> proof_bisimulation ──> sov_isa, typecheck
                   (in-memory cull registry)   (CIC equivalence kernel — pure)
```

It is the *finger*-cutter, not merely a cutter, because the hazard is **self**-amputation: a
scythe that could cut its own sealed source or re-root its own trust.

## 4 · Verdict — **SHEATHED** (blade contained; proven in source AND binary)

The three autonomous self-cut verbs the design explicitly forbids —
`scythe_cull_source` (delete sealed `.iii` source), `scythe_rehash_domain` +
`scythe_trigger_fixpoint` (autonomously re-run `build_iiis2` so the golden shifts) — were
checked across the entire 834-module tree:

| Discriminator | Result |
|---|---|
| `scythe_cull_source` / `scythe_trigger_fixpoint` / `scythe_rehash_domain` defined anywhere? | **No** — appear ONLY as forbidden-in-comment text (`daemon_scythe.iii:9,12`); zero `fn`/`@export`/call sites tree-wide |
| `build_iiis2` trigger reachable from the chain? | **No** — single occurrence is comment-only (`daemon_scythe.iii:13`) |
| Any source-write / process-spawn primitive in the 4 chain files? (`fopen`/`popen`/`system`/`fwrite`/`exec`/`unlink`) | **None** |
| **Full transitive extern-closure** (BFS over every `from "….iii"`, deduped — incl. the `sov_isa↔cg_autocatalyst↔bv_commons` cycle) | **78 modules.** Verified, not characterized. |
| Closure's entire **OS boundary** (every non-`.iii` extern) | `iii_cpuid` / `iii_xgetbv` (CPU-feature **reads**) + `VirtualAlloc` / `VirtualFree` (memory). **No file API, no process API, no `build_iiis2`** imported anywhere |
| Write/spawn/build verb ever **called** across the 78-module closure | **None** (every broad-scan hit was comment prose, a hashmap `remove`, or a `"abc"` literal — zero real call sites) |
| Exported surface | `scythe_hunt_cycle`, `scythe_run`, `daemon_scythe_kat`, `css_reset/count/all_proven`, `cg_verify_graph_integrity`, `cg_redirect_record`, `css_selftest` — **all prove-and-surface / in-memory registry; none mutate disk** |

The chain is **mathematically closed over computation** — verified transitively, not by name:
across its full 78-module reachable closure the *only* OS surface is reading CPUID and allocating
memory. It can discover, prove, and *surface* a cull set, but it imports no primitive — and calls
none — that could edit source, touch the network, or re-root the seal. The blade has no handle
that reaches the filesystem.

### Binary proof (pinned `COMPILED/iiis-2.exe`, `BB_MAX_NODES=128`, sealed `libiii_native.a`)

```
corpus/1203_daemon_scythe.iii  →  daemon_scythe_kat  EXIT = 99
    (4 kernel-certified culls · every cull proven-equivalent · deterministic replay ·
     NEGATIVE: a legacy whose optimal match lies outside the scan range is NOT culled)

css_selftest (cg_surgical_strike)  →  EXIT = 99
    (records the proven pair · REJECTS the unproven pair with ZERO state change)
```

## 5 · Where the blade's handle actually is

The only path that *does* cut — deleting the obsolete source + reseal (the "Golden Shift") — is
**OPERATOR-gated** (M20 / ADR-FORGE-4), by design and by construction: a compiled `.iii → .exe`
cannot rewrite the content-addressed sealed source at runtime, and an autonomous golden shift
would break the determinism/reproducibility contract (a self-mutating fixed point is not a fixed
point). **The hunter proposes; the CIC kernel disposes; the human holds the blade.** Sheathed.
