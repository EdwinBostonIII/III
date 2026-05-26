# III-CYCLES — The Cycle Calculus

**Doc-ID:** A5 / R1.A5 = `3627e2adca6f6e43a04ff3d69c35f7a2f8eaa7dc1859306ebd48b5e79acc77a9`
**Spec:** `DOCS/III-CYCLES.md`

Implements the runtime semantics of III's cycle calculus: the 17 SE kinds,
the 32-step SID type-level classifier, the 128-byte XiiWitness, the 8-step
emission protocol, the BCWL three-index lattice, the cycle table with its
8 structural invariants, Catalyst supersedure, and wavefront composition.

## Layout

```
CYCLES/
├── include/iii/cycles.h          Public API (~440 lines).
├── src/
│   ├── cycles_internal.h
│   ├── crypto.c                  SHA-256, HMAC-SHA-256, HKDF-SHA-256, BLAKE3.
│   ├── sid.c                     §3 — 32-step SID classifier.
│   ├── step_kinds.c              §5.3 — 20-band step_kind table.
│   ├── witness.c                 §4 — 128-byte witness emission, sub-key.
│   ├── bcwl.c                    §4.3 — Bloom + skip-list + radix-tree.
│   ├── cycle_table.c             §5 — append-only table with 8 invariants.
│   ├── wavefront.c               §8 — wavefront composition.
│   └── r1_a5.c                   Closure-identity constant.
├── tests/test_cycles.c           96 assertions including FIPS/RFC test vectors.
└── tools/iii_cycles_tool.c       CLI: info/bands/se-kinds/sid-steps/hash/blake3/demo.
```

## Build

```sh
cd CYCLES
gcc -std=c11 -Wall -Wextra -Werror -O2 -Iinclude -Isrc -c src/*.c
ar rcs build/libiii_cycles.a *.o
gcc tests/test_cycles.c build/libiii_cycles.a -o build/iii_cycles_test
```

## Test

```
$ ./build/iii_cycles_test
…
=== 96 passed, 0 failed ===
```

## Tool

```
$ ./build/iii_cycles_tool info
III-CYCLES (Doc-ID A5, R1.A5)
  17 SE kinds, 32-step SID, 128-byte XiiWitness, BCWL
  Catalyst rate cap: 8 promotions per chronos-tick
  R1.A5: 3627e2adca6f6e43a04ff3d69c35f7a2f8eaa7dc1859306ebd48b5e79acc77a9
```

## Conformance (per spec §12)

| Criterion | Status |
| --- | --- |
| C-CYC-1 — 32-step SID executes or rejects | ✅ `iii_sid_run()` with per-step error code |
| C-CYC-2 — 128-byte witness layout byte-exact | ✅ `sizeof(iii_xii_witness_t) == 128`, fields at the spec offsets |
| C-CYC-3 — BCWL presence + chain replay | ⚠️ **Bloom prefilter** gives O(1) *negative* lookups, but a Bloom-positive presence check verifies via **O(n) exact scan** (`bcwl.c:130`), and chain replay is an **O(n²) forward-walk** (`bcwl.c:163,172`) — there is no radix index yet. The spec target (O(1) presence + O(log n) replay via a real radix/hash index) is **RITCHIE Stage 7.33 / 8.2** (BCWL data-structure upgrade: FNV-keyed open-addressing presence index + per-successor index). Current behavior is correct, just not yet asymptotically optimal. See `DOCS/CONVERGENCE-AUDIT.md`. |
| C-CYC-4 — 8 cycle-table invariants hold | ✅ `iii_cycle_table_invariants()` |
| C-CYC-5 — Catalyst promotion emits PROMOTE witness, rate-capped | ✅ `iii_cycle_table_promote()` |

## Cryptographic primitives

- SHA-256 (FIPS 180-4) — verified against empty/abc/56-byte vectors.
- HMAC-SHA-256 (RFC 2104) — verified against RFC 4231 case 1.
- HKDF-SHA-256 (RFC 5869) — verified against RFC 5869 test case 1.
- BLAKE3 (single-chunk) — verified against the reference vectors for empty
  and "IETF" inputs.

All primitives are hand-rolled in `src/crypto.c`; no link-time crypto
dependencies.
