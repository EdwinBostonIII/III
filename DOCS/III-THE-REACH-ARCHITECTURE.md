# III — THE REACH: the content-addressed transport substrate

## Executive summary

The Reach is the maximal solo-network rework of III's `aether` domain. It redefines "the network"
not as a wire but as **addressed-value transport across a boundary**, expressed as two primitives:

- `reach(address) -> value | GAP` — resolve a content-address, **verify the bytes re-hash to it**, witness it.
- `emit(value) -> address` — content-address + locally store + witness; idempotent.

Every other transport (disk, IPC, loopback peers, HTTP, far peers) is a **backend** behind those two
primitives, ordered nearest-first into a lattice. Because the address is a content hash (`cad`), every
result is **tamper-evident by construction** (you cannot be lied to about content). Because "unreachable"
is a **typed GAP** (`uncertainty`), offline never errors — it merely shrinks the reachable set. The
internet is the *last, optional* backend tier, so III runs at full local capacity offline and grows more
self-sufficient with use (anything fetched once is content-verified and local forever).

This realizes the apotheosis **M31 IO-membrane** (corpus 687: every fs/net crossing must
`cap_verify_rights`; inputs enter quarantined) as a content-addressed transport, and folds in the
"network-as-XII reversible term" discipline (later phase). It is maximally NIH: built entirely out of
III's own primitives — `cad`/`keccak256` (addressing), `fs` (store), `uncertainty` (GAP), `capability`
(gating), `witness_*` (provenance), `xii` (the reversible term lowering).

## Requirements

### Functional
- FR-1 `reach(addr, cap, out, max, *out_len, *out_gid) -> {OK, GAP, DENIED}` — resolve `addr` through the
  backend lattice nearest-first; verify `cad(bytes) == addr`; on OK fill `out`/`*out_len`; on miss/corrupt
  set `*out_gid` (a typed gap) and return GAP. NEVER return bytes that mismatch `addr`.
- FR-2 `emit(value, cap, *out_addr) -> {OK, DENIED, GAP}` — content-address the value, store it, return the
  address. Idempotent (same value -> same address -> no-op store).
- FR-3 Backend lattice, nearest-first, pluggable: **L0** memo (RAM) · **L1** content-store (disk) ·
  **L2** IPC/shared-mem · **L3** loopback-peer (intra-machine federation) · **L4** remote (HTTP / far peer).
  First tier that satisfies wins; a satisfied fetch is written back *down* the lattice (cache-fill).
- FR-4 Integrity by construction: L1..L4 results are re-hashed and compared to the requested address;
  mismatch is never returned (the backend is treated as not-holding-a-valid-copy).
- FR-5 Offline contract: a backend that cannot answer returns not-here (never an error, never an indefinite
  block — budget-bounded); all tiers miss -> a typed GAP `{addr, reason}`.
- FR-6 Two value kinds: **immutable-by-address** (content-addressed, reproducible — the deterministic core
  consumes only these or GAPs) vs **oracle-by-endpoint** (live API/RPC — addressed by request, tagged
  provisional + oracle-pinned, quarantined from the deterministic core).
- FR-7 `reach`/`emit` are XII terms: normal form + termination certificate + H9 inverse (`emit^-1`=forget,
  `reach^-1`=the witnessed replay record).
- FR-8 Capability-gated per the M31 membrane: `reach` needs READ; `emit` needs READ|WRITE|CREATE; a future
  "far-reach" right gates L4 so a sandbox can be unforgeably offline-only.

### Non-functional
| Category | Requirement | Target |
|---|---|---|
| Determinism | immutable path reproducible | `reach(addr)` -> same value/GAP on any run/machine |
| Determinism | oracle path quarantined | a claimed-determined value never transitively depends on an oracle or on connectivity |
| Availability (offline) | full local capacity offline | L0-L3 local; L4 last+optional; offline = GAP, not failure |
| Integrity | tamper-evident | every returned value re-hashes to its address; no transport-trust for integrity |
| NIH | libc + BOOT only | libc sockets/file + reuse of existing III primitives; zero third-party |

### Constraints
- iiis dialect: single-line fn signatures; `==`/`!=` (+ unsigned `<`) only; byte-by-byte LE; params bound to
  locals before use; module-scope scratch (no local arrays); `@export` for cross-module; ASCII-only comments.
- `fs` (Phase C) has no mkdir yet -> Phase 1 store is a single append-log file (no directory dependency).
- Additive only: new modules appended last in `build_stdlib` MODULES (iiis-0 BSS-layout sensitivity).

## Architecture

Pattern: **layered resolver over a backend lattice** (the deterministic core sees one `reach`/`emit`
interface; backends are kind-tagged, not fn-pointer, for determinism). The internet is one backend, never
the definition of the network.

```
reach(addr) -> L0 memo (RAM, this run)        | all LOCAL -- full capacity offline
            -> L1 content-store (disk)         | (persistence = time-transport)
            -> L2 IPC / shared-mem (siblings)  |
            -> L3 loopback-peer (intra-machine)| reuses fed_*/hotstuff/witness
            -> L4 remote (HTTP / far peer)      <- the ONLY tier needing wifi; last + optional
   miss/corrupt at every tier -> typed GAP (uncertainty); never an error
```

## Components

| Module | Responsibility | Status |
|---|---|---|
| `aether/reach_store` | L1 content-addressed disk store (append-log `[addr32][len8 LE][value]`; put/has/get; dumb bytes, integrity verified by caller) | **Phase 1 — built** |
| `aether/reach_core` | the `reach`/`emit` primitives + the resolver; re-hash-verify; GAP on miss/corrupt; cap-gate | **Phase 1 — built** |
| `corpus/827_reach_spine` | KAT: round-trip, determinism, GAP, integrity-reject teeth, cap-denied teeth | **Phase 1 — built** |
| `aether/reach_term` | lower `reach`/`emit` through XII as witnessed reversible normal-form terms | Phase 2 |
| `aether/backend_memo` | L0 in-RAM hot cache | Phase 2 |
| `aether/backend_remote` | L4 HTTP fetch (`http_client`/`net` guts), content-verifying the response; cache-fill-down | Phase 3 |
| `aether/reach_oracle` | the quarantined live-API path (provisional + oracle-pinned + cap-gated; offline=GAP) | Phase 4 |
| `aether/backend_ipc`, `aether/backend_loopback` | L2 shared-mem + L3 intra-machine federation (reuses `fed_*`/`hotstuff`) | Phase 5 |

Existing `aether` becomes the *guts* of backends (no rewrite, no deletion): `net`/`http_client`/`tcp` ->
`backend_remote`; `fs` -> `reach_store`; `capability`/`handle` gate every tier; `witness_hook` records every
reach/emit; `fed_*`/`hotstuff` -> `backend_loopback`.

## Data flow

`emit(value)`: cap-check (READ|WRITE|CREATE) -> `addr = cad_oneshot(SHA256, value)` -> `reach_store_put`
(idempotent) -> return `addr`.

`reach(addr)`: cap-check (READ) -> L1 `reach_store_get` -> if found, recompute `cad(bytes)` and `cad_eq`
against `addr`: match -> OK; mismatch -> do not return the bytes, fall through -> (future: try L2-L4) ->
all miss -> `unc_gap_root(HOLE, reason)` -> GAP. Witnessed throughout (Phase 2).

## Cross-cutting

- **Determinism firewall (the keystone):** immutable-by-address values feed the deterministic core
  (reproducible); oracle-by-endpoint values are tagged provisional + oracle-pinned and quarantined. The only
  place the network touches non-determinism is walled off and typed.
- **Witness:** every reach/emit emits a fragment (replayable, auditable) — Phase 2.
- **Capability (M31):** per-tier gating; READ for reach, READ|WRITE|CREATE for emit; far-reach its own right.
- **Reversibility (H9):** `emit^-1` = forget/GC; `reach^-1` = the witnessed replay record — Phase 2.
- **Content-address = integrity:** no transport-trust for integrity; TLS (Phase 3) is confidentiality only.

## Decision log (ADRs)
- ADR-R1 the address is the integrity proof (content-addressed transport; no transport-trust for integrity).
- ADR-R2 offline is a typed GAP, never an error; the remote tier is last + optional.
- ADR-R3 two value kinds; oracle is provisional + quarantined from the deterministic core.
- ADR-R4 backends are kind-tagged dispatch (not fn-pointer) for determinism.
- ADR-R5 `reach`/`emit` are XII terms (witnessed, reversible, normal-form) — Phase 2.
- ADR-R6 the internet is a cache-filling backend (ingest-once-local-forever), not a runtime dependency.
- ADR-R7 The Reach is the content-addressed realization of the apotheosis M31 IO-membrane (corpus 687).

## Risks
| Risk | Mitigation |
|---|---|
| Oracle non-determinism leaks into the core | provisional tag + quarantine + a recompute must refuse oracle values (Phase 4 KAT teeth) |
| Backend lattice re-entrancy/cycles | resolver is strictly acyclic L0->L4, budget-bounded |
| Store unbounded growth | GC via `emit^-1` + `witness_compactor` retention (Phase 2+) |
| Loopback peer is malicious | the existing sybil/eclipse/cap gates apply intra-machine (Phase 5) |
| `fs` lacks mkdir | Phase 1 single-file store; a configured store dir lands with fs Phase D dir-ops |

## Implementation roadmap
1. **Phase 1 — local spine (reach_store + reach_core + corpus 827).** Fully offline; emit/reach round-trip;
   tamper-reject; GAP; cap-gate. **[built; verifying via build_stdlib FAIL=0 + corpus 827=99 + no regression]**
2. **Phase 2 — reach_term (XII lowering) + backend_memo (L0) + witness/reversible integration.**
3. **Phase 3 — backend_remote (HTTP) + cache-fill-down.** Content-verified fetch; offline->GAP; ingest-once.
4. **Phase 4 — reach_oracle (quarantined provisional live-API path).** Recompute-refuses-oracle teeth.
5. **Phase 5 — backend_ipc + backend_loopback (intra-machine peers reusing fed_*).**

Each phase gated by `build_stdlib` FAIL=0 + the corpus KATs (with proven negative arms) + the cartographer
`--gate` (no new duplicate `@export`, no new un-allowlisted cycle).
