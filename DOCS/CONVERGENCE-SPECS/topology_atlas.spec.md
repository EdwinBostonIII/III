# 36 aether/topology_atlas.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically near-complete and idiomatic, but it (a) declares `keccak256_init/update/final` from the WRONG provider (`keccak.iii` instead of `keccak256.iii` — systemic Defect #1), (b) uses **function-local `var` arrays** (`dist`, `queue`, `order`, `kb`, `kb2`, `out_c`, `in_c`, `fid`) which do NOT parse in iiis-0 (Trap 7) and must move to module scope, (c) uses the assigned PREFIX `TA_`/`ta_` instead of the dispatched `TOPOA_`/`topoa_` (must be renamed), and (d) uses the `&ARR[expr]` element-address form that iiis-0 mis-lowers (must become `((&ARR as u64)+off) as *u8`). The BFS, neighborhood, domain, and canonical-publish algorithms are correct in intent and W-law-clean once the scaffolding traps are closed.

## Purpose
`aether::topology_atlas` is the **hardware adjacency sheaf**: a deterministic, append-only category whose objects are physical hardware regions (CPU logical core, NUMA node, memory bank, PCI device, IOMMU group, cache-coherency domain, interrupt controller, power island) and whose morphisms are typed adjacency edges (same-socket, same-NUMA, PCIe-path, cache-coherent, shared-interrupt, same-power). It answers three exact queries — minimum-edge **distance** under a given edge-kind, the **neighborhood** of a region under a kind, and **same-domain** membership (the equivalence closure under a kind) — and publishes a canonical `TOPOLOGY_ATLAS` witness fragment over the sorted region+edge lists. The structure is a typed undirected multigraph with BFS reachability; it generalizes verbatim to a federation peer/link atlas (regions↔peers, edges↔links), reconciling the dispatch one-liner ("federation topology atlas / peers-links") with the gospel body (hardware sheaf) — same abstract machine, no semantic change. **Hexad: kind_essence + kind_witness. Ring: R0. K: 0.99.**

## Public API
All return-status conventions per W9 (negative `i32` errors) / W10 (`u8` booleans 0/1) / W12 (every public fn returns a status or a sentinel-typed value).

```
fn topoa_init() -> i32 @export
fn topoa_register_region(region_id: *u8, kind: u8) -> u32 @export
fn topoa_add_edge(a: u32, b: u32, edge_kind: u8) -> i32 @export
fn topoa_distance(a: u32, b: u32, edge_kind: u8) -> u32 @export
fn topoa_neighbors(a: u32, edge_kind: u8, out: *u32, out_n: *u32) -> i32 @export
fn topoa_in_same_domain(a: u32, b: u32, edge_kind: u8) -> u8 @export
fn topoa_publish_atlas() -> u64 @export
```

Return semantics:
- `topoa_init` → `TOPOA_OK` (0) always.
- `topoa_register_region` → slot index `u32` on success, sentinel `TOPOA_SENT` (`0xFFFFFFFFu32`) when the region table is full or `region_id` is null. (Sentinel-typed value, W12.)
- `topoa_add_edge` → `TOPOA_OK` / `TOPOA_E_BAD` (`-1`) for out-of-range endpoint, dead endpoint, or edge table full.
- `topoa_distance` → minimum edge count (`u32`); `TOPOA_SENT` (`0xFFFFFFFFu32`) when unreachable / bad / dead endpoint. `0` when `a == b`.
- `topoa_neighbors` → `TOPOA_OK` / `TOPOA_E_BAD`; writes the neighbor slot list to `out[0..*out_n)` and the count to `*out_n`. Caller guarantees `out` holds `TOPOA_MAX_REGIONS` u32 (worst case).
- `topoa_in_same_domain` → `1u8` if reachable under `edge_kind`, else `0u8` (W10).
- `topoa_publish_atlas` → witness fragment index `u64`; `0xFFFFFFFFFFFFFFFFu64` on `wh_publish` failure (sentinel-typed, W12).

Helper (non-export, internal): `fn topoa_r_id_ptr(slot: u32) -> *u8` — byte-pointer into the region-id table.

## Constant Namespace
PREFIX = `TOPOA_` . Grep result: `^const TOPOA_` and `\bTOPOA_` across `STDLIB/iii` → **no matches** (zero collision). The gospel body's `TA_*` prefix also has zero collisions, but the dispatch assigns `TOPOA_`, so every `TA_*` → `TOPOA_*` and `ta_*` → `topoa_*`. Confirmed there is no existing `topoa_*`/`topoa` symbol anywhere in STDLIB.

| const | type | value | note |
|---|---|---|---|
| `TOPOA_OK`             | i32 |  `0i32`          | status ok (W9) |
| `TOPOA_E_BAD`          | i32 | `-1i32`          | generic bad-arg / full (W9, compare via `==`/`!=` only — W11) |
| `TOPOA_SENT`           | u32 | `0xFFFFFFFFu32`  | absence / unreachable sentinel (matches `cons_find`/witness sentinel idiom) |
| `TOPOA_KIND_CORE`          | u8 | `0u8` | region kind: CPU logical core |
| `TOPOA_KIND_NUMA`          | u8 | `1u8` | NUMA node |
| `TOPOA_KIND_MEMORY_BANK`   | u8 | `2u8` | memory bank |
| `TOPOA_KIND_PCI_DEVICE`    | u8 | `3u8` | PCI device |
| `TOPOA_KIND_IOMMU_GROUP`   | u8 | `4u8` | IOMMU group |
| `TOPOA_KIND_CACHE_DOMAIN`  | u8 | `5u8` | cache-coherency domain |
| `TOPOA_KIND_INTERRUPT_CTL` | u8 | `6u8` | interrupt controller |
| `TOPOA_KIND_POWER_ISLAND`  | u8 | `7u8` | power island |
| `TOPOA_EK_SAME_SOCKET`     | u8 | `0u8` | edge kind: same socket |
| `TOPOA_EK_SAME_NUMA`       | u8 | `1u8` | same NUMA node |
| `TOPOA_EK_PCIE_PATH`       | u8 | `2u8` | PCIe path |
| `TOPOA_EK_CACHE_COHERENT`  | u8 | `3u8` | cache coherent |
| `TOPOA_EK_SHARED_INTERRUPT`| u8 | `4u8` | shared interrupt |
| `TOPOA_EK_SAME_POWER`      | u8 | `5u8` | same power island |
| `TOPOA_MAX_REGIONS`    | u32 | `4096u32`  | static region-table bound (W8) |
| `TOPOA_MAX_EDGES`      | u32 | `16384u32` | static edge-table bound (W8) |
| `TOPOA_PILLAR`         | u16 | `6u16`     | witness pillar id for the atlas fragment |
| `TOPOA_PHASE`          | u8  | `5u8`      | witness phase id |

(No `MAX`/`OK`/`BUF_LEN`-style bare names — all prefixed, satisfying Trap 2.)

## Data Structures
All module-scope, statically sized (W8). **No function-local `var` arrays** (Trap 7 — the gospel's locals are hoisted here). Single-threaded / non-reentrant; `topoa_distance` uses module-scope BFS scratch, so concurrent distance queries are not permitted — acceptable for a deterministic single-threaded substrate map; **flagged** (see Gap/Fix).

Region table (max 4096 regions — one per logical hardware region on a large server; 4096 cores/NUMA/PCI objects bounds any realistic single-node topology):
| name | type | size (bytes) | bound justification |
|---|---|---|---|
| `TOPOA_R_LIVE`  | `[u8; 4096]`   | 4096   | liveness bit per region slot |
| `TOPOA_R_ID`    | `[u8; 131072]` | 131072 | 4096 × 32-byte identifiers |
| `TOPOA_R_KIND`  | `[u8; 4096]`   | 4096   | region kind per slot |
| `TOPOA_R_COUNT` | `u32`          | —      | live-region counter |

Edge table (max 16384 edges — ~4 typed edges per region average over 4096 regions; covers dense socket/NUMA/PCIe meshes):
| name | type | size | bound justification |
|---|---|---|---|
| `TOPOA_E_LIVE`  | `[u8;  16384]` | 16384 | liveness bit per edge slot |
| `TOPOA_E_A`     | `[u32; 16384]` | 65536 | edge endpoint A (region slot) |
| `TOPOA_E_B`     | `[u32; 16384]` | 65536 | edge endpoint B (region slot) |
| `TOPOA_E_KIND`  | `[u8;  16384]` | 16384 | edge kind |
| `TOPOA_E_COUNT` | `u32`          | —     | live-edge counter |

BFS / canonicalization scratch (hoisted from gospel locals — Trap 7 fix):
| name | type | size | purpose |
|---|---|---|---|
| `TOPOA_BFS_DIST`  | `[u32; 4096]` | 16384 | per-region BFS distance (init to `TOPOA_SENT`) |
| `TOPOA_BFS_QUEUE` | `[u32; 4096]` | 16384 | explicit BFS queue (W15 — no recursion) |
| `TOPOA_ORDER`     | `[u32; 4096]` | 16384 | canonical region-slot ordering for publish |
| `TOPOA_KB1`       | `[u8; 1]`     | 1     | single-byte kind scratch for keccak update |
| `TOPOA_OUTC`      | `[u8; 32]`    | 32    | out_commit (Keccak of atlas) scratch |
| `TOPOA_INC`       | `[u8; 32]`    | 32    | in_commit (chain root) scratch |
| `TOPOA_FID`       | `[u8; 32]`    | 32    | published fragment-id sink |

Witness identity (computed once in `topoa_init`):
| name | type | size | purpose |
|---|---|---|---|
| `TOPOA_PRODUCER` | `[u8; 32]` | 32 | `ident_from_bytes("aether::topology_atlas")` |
| `TOPOA_OPID_PUB` | `[u8; 32]` | 32 | `ident_from_bytes("aether::topology_atlas::publish")` |
| `TOPOA_INITED`   | `u8`       | —  | init-once guard |

Total static footprint ≈ 0.31 MiB — well within the small code model's RIP-relative reach. No dynamic allocation; W6/W7 satisfied (module-scope arenas with explicit `topoa_init` lifecycle).

## Dependencies (externs)
All providers are **already built** (verified present in `STDLIB/iii`). **No not-yet-built dependencies.**

```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
```

Provider module numbers (for the wave scheduler):
- `identifier.iii` — numera, built. (`ident_cmp` returns `-1/0/+1` lexicographic; `ident_copy`/`ident_from_bytes` over 32-byte ids; `IDENT_BYTES = 32`.)
- `keccak256.iii` — numera, Module ~06, built. **Provider corrected from the gospel's bogus `keccak.iii`** (Defect #1). `keccak256_init/update/final` are the streaming API here; `keccak.iii` exports only `keccak_f1600/absorb/squeeze` and would fail to link.
- `witness_hook.iii` — aether, Module 07, built. `wh_publish` matches the gospel signature byte-for-byte (verified L144–148 of the built file); `wh_chain_root` verified L216. Precondition: `wh_init(initial_time)` must have run during boot before `topoa_publish_atlas` (else `wh_publish` returns the `0xFFFF…FFFF` sentinel) — this is a system-boot ordering invariant, not this module's responsibility (Defect #6 getters NOT needed: this module never reads fragment fields back).
- `keccak256_oneshot` is available as an alternative to the streaming triple; the algorithm here streams the (variable-length) sorted atlas, so the streaming API is the correct choice (oneshot would require a contiguous serialized buffer).

## Algorithm

### `topoa_init() -> i32`
Zero `TOPOA_R_LIVE[0..4096)` and `TOPOA_E_LIVE[0..16384)` via two `while` counters (W14 sentinel loop, no `break`); set `TOPOA_R_COUNT = 0`, `TOPOA_E_COUNT = 0`; compute the two witness identifiers with `ident_from_bytes` over the fixed producer/op strings (lengths: `"aether::topology_atlas"` = 22, `"aether::topology_atlas::publish"` = 31); set `TOPOA_INITED = 1`; return `TOPOA_OK`. Deterministic — fixed string inputs → fixed identifiers (M2). Idempotent.

### `topoa_register_region(region_id, kind) -> u32`
Lazy-init guard (`if TOPOA_INITED == 0u8 { topoa_init() }`). If `region_id` is null (`(region_id as u64) == 0u64`) return `TOPOA_SENT`. Linear scan for the first dead slot (`TOPOA_R_LIVE[i] == 0u8`); on hit, `ident_copy(region_id, topoa_r_id_ptr(i))`, set kind, set live, increment count, return `i`. Full table → `TOPOA_SENT`. Append-only assignment of the lowest free slot makes slot numbering a deterministic function of insertion order (M2). No edge is ever mutated/removed → reversibility-by-construction (M9: the only state change is monotonic add; absence of a destroy op means no irreversible transition).

### `topoa_add_edge(a, b, edge_kind) -> i32`
Range/liveness guards on `a` and `b` (`>= TOPOA_MAX_REGIONS` → bad; `TOPOA_R_LIVE[.] == 0u8` → bad). These are **unsigned** `u32` compares (NOT Trap 3 — Trap 3 is signed ordering only; unsigned `>=` is legal and used identically in the built exemplars). Linear scan for first dead edge slot; record `(a, b, edge_kind)`, set live, increment, return `TOPOA_OK`. Full → `TOPOA_E_BAD`. Edges are stored **undirected** (queried symmetrically); duplicate edges are permitted (multigraph) and do not affect distance/neighborhood results because BFS marks-visited and neighbor emission is de-duplicated only by reachability, not by edge identity — duplicates are idempotent for distance, additive for raw neighbor listing (documented; a caller wanting unique neighbors filters, or we add a dedupe pass — see Gap/Fix optional hardening).

### `topoa_distance(a, b, edge_kind) -> u32` — BFS, explicit queue (W15)
Guards as above → `TOPOA_SENT`. `a == b` → `0u32`. Initialize `TOPOA_BFS_DIST[0..MAX_REGIONS)` to `TOPOA_SENT` (sentinel loop). Seed: `TOPOA_BFS_DIST[a] = 0`, push `a` to `TOPOA_BFS_QUEUE`, head `qh=0`, tail `qt=1`. Main loop is the gospel's **single-flag sentinel form** (W14, no `break`): `while qh < qt { if found == 0u8 { … } if found == 1u8 { qh = qt } }`. Inside the not-yet-found branch: pop `cur = queue[qh]`, `qh += 1`; if `cur == b` set `result = dist[cur]`, `found = 1`; else scan all `TOPOA_MAX_EDGES`, and for each **live** edge of matching kind compute the `other` endpoint (`E_A==cur → other=E_B`; `E_B==cur → other=E_A`; undirected), and if `other != TOPOA_SENT && dist[other] == TOPOA_SENT` set `dist[other] = dist[cur] + 1` and enqueue. The `found==1 → qh=qt` line drains the queue to exit the loop without `break`. Returns `result` (`TOPOA_SENT` if never found). **Determinism (M2):** edges are scanned in fixed slot order and BFS visits in FIFO order, so the discovered distance and the visitation order are a pure function of the (slot-ordered) graph — bit-identical across runs (W5). No floats, no heuristics (M3/M4); distance is the exact graph metric. Cost is bounded `O(V·E)` per query under the static `V≤4096`, `E≤16384` bound (M19). **Edge case:** an edge whose endpoint slot was never the `cur` yields `other = TOPOA_SENT` and is skipped — this also correctly handles the (impossible-by-guard) self-loop where both `E_A` and `E_B` equal `cur` (the second assignment would set `other` to `cur` itself, but since `dist[cur]` is already set, it is not re-enqueued).

### `topoa_neighbors(a, edge_kind, out, out_n) -> i32`
Guards → `TOPOA_E_BAD`. Single linear pass over all edge slots; for each live edge of matching kind, compute `other` (undirected), and if `other != TOPOA_SENT` append `other` to `out[n++]`. Write `*out_n = n`; return `TOPOA_OK`. Deterministic slot-order emission (M2). The list may contain duplicate `other` values if duplicate edges exist (see `add_edge` note).

### `topoa_in_same_domain(a, b, edge_kind) -> u8`
`d = topoa_distance(a, b, edge_kind)`; return `1u8` if `d != TOPOA_SENT` else `0u8`. This realizes the **sheaf/equivalence-closure** semantics: "same domain under kind K" ≡ "reachable under K", and reachability under a fixed kind is reflexive (a==b → 0), symmetric (undirected edges), and transitive (BFS over the closure) — the equivalence relation the gospel's sheaf condition requires (M2, exact).

### `topoa_publish_atlas() -> u64` — canonical Keccak256 commitment + witness fragment
1. **Collect** live region slots into `TOPOA_ORDER[0..n)`.
2. **Canonical sort** `TOPOA_ORDER` by 32-byte `region_id` using **insertion sort** (no recursion, W15; W14 inner sentinel: `q` driven to `0u32` to stop, not `break`). Swap predicate: `ident_cmp(id[order[q-1]], id[order[q]]) == 1i32` (left greater → swap). The stop test `ident_cmp(...) != 1i32 { q = 0u32 }` terminates the inner loop. Sorting by content (not slot) makes the commitment **insertion-order-independent** (M2/W5): two atlases with the same regions+edges added in any order produce the identical hash.
3. **Hash** with the streaming Keccak256 triple: `keccak256_init()`; for each region in canonical order, `keccak256_update(id, 32)` then `keccak256_update(&kind, 1)`; then for each **live** edge in slot order, `keccak256_update(A_id, 32)`, `keccak256_update(B_id, 32)`, `keccak256_update(&edge_kind, 1)`; `keccak256_final(TOPOA_OUTC)`. **NOTE (correctness hardening — see Gap/Fix):** the gospel hashes edges in raw *slot* order, which is NOT canonical (insertion-order-dependent). The maximal-intent fix is to also canonicalize the edge stream (sort live edges by `(A_id, B_id, edge_kind)`), so the commitment is a pure function of the *graph*, not of insertion history. This spec adopts the canonical-edge form.
4. `wh_chain_root(TOPOA_INC)` to fetch the prior chain root as `in_commit`.
5. `wh_publish(TOPOA_PRODUCER, TOPOA_OPID_PUB, TOPOA_INC, TOPOA_OUTC, revtag=0u8, phase=TOPOA_PHASE, pillar=TOPOA_PILLAR, antecedents=TOPOA_OUTC, n_ante=0u32, payload=TOPOA_OUTC, payload_len=32u32, out_frag_id=TOPOA_FID)`; return its `u64` index. **Witness (M6/M10):** the fragment id is Keccak256 over all fields including the atlas commitment; given the recorded regions+edges, the commitment — and therefore the fragment — is byte-recomputable (M10). `revtag=0` marks it reversible (M9/W16). Time advances monotonically inside `wh_publish` via `at_advance` (W17) — this module does not touch algebraic time directly.

## KAT Vectors (>= 3)
A Phase-2 `topoa_kat() -> u64` self-test (returns `99u64` on full pass; a distinct small code per failing vector) must check, byte-for-byte:

1. **Distance / line graph.** `topoa_init()`. Register 4 regions r0..r3 with distinct ids `id="A"`,`"B"`,`"C"`,`"D"` (via `ident_from_bytes`), kind `CORE`. Add edges `(0,1)`,`(1,2)`,`(2,3)` kind `SAME_NUMA`. Assert: `topoa_distance(0,3,SAME_NUMA) == 3u32`; `topoa_distance(0,2,SAME_NUMA) == 2u32`; `topoa_distance(3,0,SAME_NUMA) == 3u32` (symmetry); `topoa_distance(0,0,SAME_NUMA) == 0u32`; `topoa_distance(0,3,SAME_SOCKET) == 0xFFFFFFFFu32` (wrong kind → unreachable); `topoa_in_same_domain(0,3,SAME_NUMA) == 1u8`; `topoa_in_same_domain(0,3,SAME_SOCKET) == 0u8`.

2. **Neighbors & disconnected.** Continue from (1); add region r4 id `"E"` kind `CORE` with NO edges. Assert: `topoa_neighbors(1, SAME_NUMA, out, &n)` → `n == 2u32` and `{out[0],out[1]} == {0u32, 2u32}` (slot order: edge (0,1) emits 0, edge (1,2) emits 2 → `out[0]==0`, `out[1]==2`); `topoa_distance(0,4,SAME_NUMA) == 0xFFFFFFFFu32` (isolated); `topoa_neighbors(4, SAME_NUMA, out, &n)` → `n == 0u32`.

3. **Canonical-publish determinism (order independence).** Build atlas P: init, register r0=`"A"`,r1=`"B"` (CORE), edge `(0,1)` kind `SAME_SOCKET`; capture `cP = TOPOA_OUTC` after the internal hash of `topoa_publish_atlas()` (expose via a test getter or recompute). Build atlas Q in a fresh `topoa_init()`: register r0=`"B"`,r1=`"A"` (CORE) — reversed insertion — edge `(0,1)` kind `SAME_SOCKET`. Assert the 32-byte commitment of Q **equals** that of P (canonical sort makes insertion order irrelevant). Additionally assert the empty-atlas commitment is the fixed Keccak256 of the empty stream: `topoa_init()` then publish with zero regions → `TOPOA_OUTC == Keccak256("")` = `c5 d2 46 01 86 f7 23 3c 92 7e 7d b2 dc c7 03 c0 e5 00 b6 53 ca 82 27 3b 7b fa d8 04 5d 85 a4 70` (standard Keccak-256 empty-input vector, matching `keccak256.iii::keccak256_kat`'s first byte check `0xc5`).

4. **Witness chaining (bonus).** After vector 3's publish, `wh_get_frag_id(idx, fid)` must equal the `TOPOA_FID` returned via `out_frag_id`, and the fragment must be non-revoked — confirming the fragment is recorded and recomputable (M10). (Requires `wh_init` to have run at boot.)

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED. The `wh_publish` extern and signatures are long; every `fn`/`extern fn` prefix MUST be a single physical line (the skeleton below writes the `wh_publish` extern on one line — do NOT wrap it as the gospel did across L164–168).
- **Trap 2 (const linker-global)** — AVOIDED via the `TOPOA_` prefix on every const (grep-confirmed zero collision; bare `OK`/`MAX`/`SENT` never used).
- **Trap 3 (signed ordering SIGSEGV)** — NOT EXPOSED. All comparisons are either `u32`/`u8`/`u64` unsigned (`>=`, `<` on counters and bounds — legal) or sentinel **equality** (`== TOPOA_SENT`, `!= 1i32`, `== 1i32`). No signed `i32`/`i64` `< / <= / > / >=`. The `ident_cmp` result is tested only with `== 1i32` / `!= 1i32` (equality), never ordered.
- **Trap 4 (u32-in-u64-slot garbage)** — EXPOSED in `topoa_r_id_ptr(slot)`: `(&TOPOA_R_ID as u64) + (slot as u64) * 32u64` does pointer math on a `u32` slot. AVOIDANCE: mask `(slot as u64) & 0xFFFFFFFFu64` before the multiply (or keep `slot` in a `u64` local first). Apply the same mask anywhere an edge/region `u32` index feeds address arithmetic (`E_A[e]`, `E_B[e]`, `order[k]` when used as the id-ptr argument — pass through `topoa_r_id_ptr`, which masks once).
- **Trap 5 (u32 pointer store width)** — NOT EXPOSED. No `*u32` element store originates from a u32-in-slot value; `out[n]` in `topoa_neighbors` is a caller buffer written `out[n as u64] = other` where `other` is a freshly-loaded `u32` — store the **u64-indexed** `*u32` element; if Phase-2 disassembly shows an 8-byte `movq` clobber, fall back to four `*u8` byte stores. Flagged for the implementer to verify in the binary.
- **Trap 6 (nested `/* */`)** — AVOIDED. Header/comments use no nested block comments; inline notes use `//` or `(...)`.
- **Trap 7 (local `var` arrays)** — WAS EXPOSED in the gospel (`dist`, `queue`, `order`, `kb`, `kb2`, `out_c`, `in_c`, `fid` were all function-local `var [..]`). FIXED by hoisting ALL of them to module scope (`TOPOA_BFS_DIST/QUEUE/ORDER/KB1/OUTC/INC/FID`). This is the single largest structural correction; the exemplar `witness_hook.iii` documents the identical reconciliation.
- **Trap 8 (`} else {` one line)** — controlled: the only `if/else` (the streaming `keccak256_update` pos-wrap is inside the provider, not here) — this module uses single-`if` guards with no `else`, so no exposure; if any `else` is introduced, keep `} else {` on one line.
- **Trap 9 (em-dash in comment)** — AVOIDED. All comments use ASCII `--`, never `—`.
- **Trap 10 (`let mut` checkpoint-flag)** — PARTIALLY EXPOSED. `topoa_distance` uses `let mut found : u8` as a checkpoint flag with the `if found==0 {…} if found==1 { qh=qt }` early-drain pattern. This is the gospel's existing tested shape and is structurally an early-exit-via-flag, but the implementer should prefer the queue-drain (`qh = qt`) — which IS the early-return-equivalent — over branching on the flag for further work. Acceptable as written; flagged.
- **Trap 11 (`a % b` after call)** — NOT EXPOSED. No modulo anywhere in the module.
- **Trap 12 (`@specialize *T` stride)** — NOT EXPOSED. No generics; all arrays are concrete-typed.

## Gap / Fix List (PARTIAL → fixes to apply in Phase 2)
1. **Wrong keccak provider (systemic Defect #1).** Gospel: `extern keccak256_init/update/final from "keccak.iii"`. FIX: `from "keccak256.iii"` (verified: those three live in `keccak256.iii` L46/52/62; `keccak.iii` exports only `keccak_f1600/absorb/squeeze` and linking against it fails). Applied in the skeleton.
2. **Function-local `var` arrays (Trap 7).** Gospel declares `dist`,`queue`,`order`,`kb`,`kb2`,`out_c`,`in_c`,`fid` inside fn bodies — these do not parse in iiis-0. FIX: hoisted to the module-scope `TOPOA_BFS_*`/`TOPOA_ORDER`/`TOPOA_KB1`/`TOPOA_OUTC`/`TOPOA_INC`/`TOPOA_FID` arrays. (Forces single-threaded distance/publish — see #6.)
3. **Prefix mismatch.** Gospel uses `TA_`/`ta_`; dispatch assigns `TOPOA_`/`topoa_`. FIX: rename every symbol (consts, vars, fns). Both prefixes are collision-free, but the dispatch is authoritative.
4. **`&ARR[expr]` element-address form.** Gospel writes `&TA_R_ID[(slot)*32]`, `&kb[0u64]`, `&out_c[0u64]`, etc. iiis-0 mis-lowers `&ARR[expr]` for module-scope arrays. FIX: use `((&ARR as u64) + offset) as *u8` (the exemplar `witness_hook.iii`/`fed_admit.iii` idiom). Applied throughout.
5. **Non-canonical edge hashing in `publish_atlas`.** Gospel sorts regions but hashes edges in raw slot order, so the commitment depends on edge-insertion order — violates the "deterministic map" intent (a *graph*, not an *edge-insertion log*, should hash identically). FIX (maximal intent): canonicalize the edge stream too — build an edge-order array, insertion-sort live edges by the triple `(A_id, B_id, edge_kind)` (using `ident_cmp` on the two endpoint ids then a `u8` kind tiebreak via equality cascade), and hash in that order. Requires one more module-scope scratch `TOPOA_E_ORDER : [u32; 16384]`. KAT 3 enforces order-independence.
6. **Reentrancy (W6/W7 note, not a defect).** Because BFS scratch is module-scope, `topoa_distance`/`topoa_publish_atlas` are not reentrant; nested or concurrent calls corrupt the queue. This is inherent to iiis-0's no-local-array constraint and acceptable for a single-threaded deterministic substrate. FLAGGED so callers serialize topology queries.
7. **`wh_init` precondition.** `topoa_publish_atlas` calls `wh_publish`, which returns the `0xFFFF…` sentinel unless `wh_init` ran at boot. Not this module's job to init the global witness hook; documented as a boot-order invariant. No Defect #6 getter dependency (this module never reads fragment fields back).
8. **Mandate audit — all PASS:** M1 NIH (only identifier/keccak256/witness_hook STDLIB deps, all hand-rolled; no third-party). M2/W5 determinism (slot-order + content-sorted, no floats). M3/M4 (exact graph metric; no counting/learning/thresholds). M5 (append-only; no destroy op → cannot brick). M6/M10 (publishes a recomputable witness fragment). M7 (Ring R0 as gospel header). M8/M9 (read/query ops need no capability; the only state-mutating ops are monotone adds + a reversible witness publish — `revtag=0`; no privileged/irreversible action exists to gate, so no `cap_verify_rights` dependency is warranted — **flagged** as a deliberate non-use rather than the missing-cap Defect #5). M15/M19 (all ops total over their bit width and `O(V·E)`-bounded). No M-violation found in the gospel body beyond the trap/provider issues above.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/topology_atlas.iii
 *
 * III STDLIB - aether::topology_atlas -- the hardware adjacency sheaf.
 *
 * Objects: physical hardware regions (core / numa / memory-bank / pci /
 * iommu-group / cache-domain / interrupt-ctl / power-island).
 * Morphisms: typed undirected adjacency edges. Queries: minimum-edge
 * distance, neighborhood, and same-domain (equivalence closure) under a
 * given edge kind. Publishes a canonical TOPOLOGY_ATLAS witness fragment.
 *
 * Hexad: kind_essence + kind_witness.  Ring: R0.  K: 0.99.
 * Discipline: W2, W8, W13, W14, W15 (no recursion; BFS uses an explicit
 *             module-scope queue).  All comments ASCII (Trap 9).
 */

module aether_topology_atlas

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const TOPOA_OK    : i32 =  0i32
const TOPOA_E_BAD : i32 = -1i32
const TOPOA_SENT  : u32 = 0xFFFFFFFFu32

const TOPOA_KIND_CORE          : u8 = 0u8
const TOPOA_KIND_NUMA          : u8 = 1u8
const TOPOA_KIND_MEMORY_BANK   : u8 = 2u8
const TOPOA_KIND_PCI_DEVICE    : u8 = 3u8
const TOPOA_KIND_IOMMU_GROUP   : u8 = 4u8
const TOPOA_KIND_CACHE_DOMAIN  : u8 = 5u8
const TOPOA_KIND_INTERRUPT_CTL : u8 = 6u8
const TOPOA_KIND_POWER_ISLAND  : u8 = 7u8

const TOPOA_EK_SAME_SOCKET     : u8 = 0u8
const TOPOA_EK_SAME_NUMA       : u8 = 1u8
const TOPOA_EK_PCIE_PATH       : u8 = 2u8
const TOPOA_EK_CACHE_COHERENT  : u8 = 3u8
const TOPOA_EK_SHARED_INTERRUPT: u8 = 4u8
const TOPOA_EK_SAME_POWER      : u8 = 5u8

const TOPOA_MAX_REGIONS : u32 = 4096u32
const TOPOA_MAX_EDGES   : u32 = 16384u32
const TOPOA_PILLAR      : u16 = 6u16
const TOPOA_PHASE       : u8  = 5u8

var TOPOA_R_LIVE   : [u8;  4096]
var TOPOA_R_ID     : [u8;  131072]   // 4096 * 32
var TOPOA_R_KIND   : [u8;  4096]
var TOPOA_R_COUNT  : u32 = 0u32

var TOPOA_E_LIVE   : [u8;  16384]
var TOPOA_E_A      : [u32; 16384]
var TOPOA_E_B      : [u32; 16384]
var TOPOA_E_KIND   : [u8;  16384]
var TOPOA_E_COUNT  : u32 = 0u32

var TOPOA_BFS_DIST : [u32; 4096]
var TOPOA_BFS_QUEUE: [u32; 4096]
var TOPOA_ORDER    : [u32; 4096]
var TOPOA_E_ORDER  : [u32; 16384]    // canonical edge order (Gap/Fix #5)
var TOPOA_KB1      : [u8; 1]
var TOPOA_OUTC     : [u8; 32]
var TOPOA_INC      : [u8; 32]
var TOPOA_FID      : [u8; 32]

var TOPOA_PRODUCER : [u8; 32]
var TOPOA_OPID_PUB : [u8; 32]
var TOPOA_INITED   : u8 = 0u8

// Byte-pointer into the region-id table.  Mask slot before pointer math (Trap 4).
fn topoa_r_id_ptr(slot: u32) -> *u8 { return ((&TOPOA_R_ID as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8 }

fn topoa_init() -> i32 @export {
    // TODO: body per Algorithm topoa_init -- zero both LIVE tables (W14 loops),
    // reset counts, ident_from_bytes the producer ("...topology_atlas", len 22)
    // and publish op ("...topology_atlas::publish", len 31), set TOPOA_INITED.
}

fn topoa_register_region(region_id: *u8, kind: u8) -> u32 @export {
    // TODO: body per Algorithm -- lazy init guard; null-check region_id -> SENT;
    // first-dead-slot scan; ident_copy + kind + live + count++; full -> SENT.
}

fn topoa_add_edge(a: u32, b: u32, edge_kind: u8) -> i32 @export {
    // TODO: body per Algorithm -- range+liveness guards (unsigned, not Trap 3);
    // first-dead-edge-slot scan; record (a,b,kind), live, count++; full -> E_BAD.
}

fn topoa_distance(a: u32, b: u32, edge_kind: u8) -> u32 @export {
    // TODO: body per Algorithm -- guards -> SENT; a==b -> 0; init TOPOA_BFS_DIST
    // to SENT; seed queue; W14 single-flag drain loop (no break); scan live edges
    // of matching kind, relax unvisited neighbors; return result/SENT. (W15.)
}

fn topoa_neighbors(a: u32, edge_kind: u8, out: *u32, out_n: *u32) -> i32 @export {
    // TODO: body per Algorithm -- guards -> E_BAD; single pass over live edges of
    // matching kind; append undirected 'other' to out[n++]; *out_n = n; OK.
}

fn topoa_in_same_domain(a: u32, b: u32, edge_kind: u8) -> u8 @export {
    // TODO: body per Algorithm -- d = topoa_distance(...); return (d != SENT)?1:0.
}

fn topoa_publish_atlas() -> u64 @export {
    // TODO: body per Algorithm -- collect live regions into TOPOA_ORDER; insertion
    // -sort by region_id (ident_cmp == 1i32 swap; W15/W14); collect+insertion-sort
    // live edges into TOPOA_E_ORDER by (A_id,B_id,kind) (Gap/Fix #5); keccak256_init
    // /update (region id+kind, then edge A_id+B_id+kind) /final -> TOPOA_OUTC;
    // wh_chain_root -> TOPOA_INC; return wh_publish(PRODUCER, OPID_PUB, INC, OUTC,
    // 0u8, TOPOA_PHASE, TOPOA_PILLAR, OUTC, 0u32, OUTC, 32u32, TOPOA_FID).
}
```
