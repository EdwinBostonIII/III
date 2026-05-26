# III ARCHITECTURE SNAPSHOT — 2026-05-08

A one-page system snapshot. Replaces the need to skim 50+ entries of
`LATTICE-CHANGELOG.md` to discover what's where; the changelog remains
the append-only history.

---

## §1. The system in one paragraph

III is a sealed, self-hosting NIH compiler ecosystem. The bootstrap
compiler `iiis-0` is hand-written C in `COMPILER/BOOT/`, compiled by
`build_iiis0.sh` into `COMPILED/iiis-0.exe`. That binary compiles the
**246-module sealed stdlib** (`STDLIB/iii/`, sealed by
`STDLIB/iii/SEAL.mhash` + the source-side `STDLIB/build/SOURCES.mhash`
closure-root `458d8f5f…`) into `STDLIB/build/iii/libiii_native.a`, which is
linked into the **STDLIB conformance corpus** (`STDLIB/corpus/`, 375 `.iii`
files) driven by `STDLIB/scripts/run_corpus.sh`. Everything outside that
chain is either parallel reference work (32 R1 subsystem dirs), in-progress
self-host (`COMPILER/BOOT/*.iii` + `stage1_port/`), or specification
(`DOCS/`).

> **Count provenance (RITCHIE Stage 0.3, 2026-05-20):** the original
> snapshot stated "198-module / 179 conformance tests". The live tree at
> convergence-start carried 246 `.iii` modules (aether 20, memoria 5,
> numera 45, omnia 100, sanctus 23, tempora 5, verba 48) and 375 corpus
> `.iii` files. The `198`/`179` figures were the 2026-05-08 counts; this
> doc is amended to the live counts per Contract C13 (drift reconciliation).
> See `DOCS/CONVERGENCE-AUDIT.md §0.3` and `DOCS/MHASH-LEDGER.md §RITCHIE/0.3`.
>
> **V1 Stages 0–1 maximalist pass (2026-05-22):** the live tree now carries
> **262** `.iii` modules — the convergence-start 246 plus 16 added by §4 crypto
> (ML-DSA, ML-KEM, SLH-DSA, pq_dispatch, DRBG, AES-SIV, XChaCha20-Poly1305, and
> the ECDSA-P256/P-384 field/curve/scalar + RSA modules). The box figures below
> are updated to 262. (numera grew 45→61; other namespaces unchanged.)

## §2. The four trees

```
III/
├── live build chain ──────────────────────────────────────────────────┐
│   COMPILER/BOOT/*.c              bootstrap compiler (iiis-0)         │
│   COMPILER/BOOT/build_iiis0.sh   builds COMPILED/iiis-0.exe          │
│   STDLIB/iii/*.iii               262 sealed stdlib modules           │
│   STDLIB/iii/SEAL.mhash          closure root + per-module hashes    │
│   STDLIB/build/SOURCES.mhash     262-module source seal (Stage 0.3)  │
│   STDLIB/build/CLOSURE.mhash     source closure-root 458d8f5f…       │
│   STDLIB/scripts/seal_sources.sh regenerates SOURCES + CLOSURE       │
│   STDLIB/scripts/build_stdlib.sh builds STDLIB/build/iii/*.iii.o     │
│   STDLIB/corpus/*.iii            375 conformance test files          │
│   STDLIB/scripts/run_corpus.sh   runs the corpus                     │
│   COMPILED/iiis-0.exe            the deployed compiler binary        │
│   COMPILED/iiis-0.exe.mhash      determinism witness                 │
│   COMPILER/BOOT/iiis-0.mhash     golden hash for the binary          │
│                                                                       │
├── self-host port (stage 1, in progress) ───────────────────────────┐ │
│   COMPILER/BOOT/*.iii            18 stage-1 mirror TUs              │ │
│   COMPILER/BOOT/stage1_port/     5 boot-mirror sketches             │ │
│   COMPILER/BOOT/stage1_corpus/   57 stage-1 corpus tests            │ │
│   COMPILER/BOOT/smoke/           7 smoke tests                      │ │
│   STAGE1/PROBE/                  43 feature probes                  │ │
│                                                                       │ │
├── R1 reference implementations ────────────────────────────────────┐ │ │
│   ABI/  CATALYST/  CATALYST-EXT/  CONFORMANCE/  CONSTANTS/          │ │ │
│   CRYPTO-AGILITY/  CYCLES/  EFFECTS/  ERRORS/  FEDERATION/          │ │ │
│   FOUNDERS-ANCHOR/  GENESIS-VECTOR/  GHOST-CODE/  GRAMMAR/          │ │ │
│   HEXAD/  INTEGRATION/  LEGACY-INGESTION/  LEXICON/  MODULES/       │ │ │
│   OBSERVABILITY/  PERFORMANCE/  PHASES/  PLANETARY/                 │ │ │
│   POLYMORPHIC-DATA/  PORTABILITY/  R2-GENESIS/  SANCTUM/            │ │ │
│   SANDBOX/  SOVEREIGN-WEB/  TRINITY/  TYPES/  ZK-PRUNING/           │ │ │
│                                                                       │ │ │
└── specification + ledgers ─────────────────────────────────────────┐ │ │ │
    DOCS/III-INDEX.md             constitutional master index        │ │ │ │
    DOCS/README.md                navigation overlay                 │ │ │ │
    DOCS/III-*.md                 14 R1-sealed docs + 16 derivative  │ │ │ │
    DOCS/MHASH-LEDGER.md          binary hash history                │ │ │ │
    DOCS/MANDATE-LEDGER.md        M1..M22 audit history              │ │ │ │
    NOTES/LATTICE-CHANGELOG.md    operational changelog (append-only)│ │ │ │
    NOTES/III-NAMESPACES.md       module namespace conventions       │ │ │ │
    NOTES/III-MONOMORPHIC.md      generics strategy memo             │ │ │ │
    NOTES/ARCHITECTURE.md         this file                          │ │ │ │
    R1-SUBSYSTEMS.md              index of the 32 reference impls    │ │ │ │
    BUILD-ARTIFACTS.md            what should never be committed     │ │ │ │
```

## §3. Build chain in one command

```bash
# 1. Compile the bootstrap compiler (one-shot; idempotent).
bash COMPILER/BOOT/build_iiis0.sh
# Output: COMPILED/iiis-0.exe (also .mhash, .witness.json)
# Verify: golden hash from COMPILER/BOOT/iiis-0.mhash

# 2. Compile the 262 stdlib modules (those registered in build_stdlib.sh).
IIIS=COMPILED/iiis-0.exe bash STDLIB/scripts/build_stdlib.sh
# Output: STDLIB/build/iii/*.iii.o + libiii_native.a

# 3. Run the 179 conformance tests.
IIIS=COMPILED/iiis-0.exe bash STDLIB/scripts/run_corpus.sh
# Expected: PASS=179 FAIL=0

# Optional: stage-1 corpus (57 tests verifying language features).
bash COMPILER/BOOT/stage1_corpus/run_corpus.sh

# Unified one-shot driver (added 2026-05-08).
bash run_all_corpora.sh
```

## §4. Determinism gates

Every build run is reproducible bit-for-bit. The discipline:

```
LC_ALL=C  LANG=C  TZ=UTC0  SOURCE_DATE_EPOCH=0  CCACHE_DISABLE=1
gcc -frandom-seed=$basename -ffile-prefix-map=$PWD=. -O2 -DNDEBUG
ld --build-id=none
sort -V deterministic enumeration
sha256sum mhash records into the witness sidecar
```

The build script emits `iiis-0.exe.mhash` and the script
`build_iiis0.sh --check-deterministic` builds twice and compares;
divergence exits with `III_EXIT_NONDETERMINISM = 6`.

## §5. NIH discipline

* libc + Win32 (`-lws2_32 -lkernel32 -lmsvcrt`) only.
* No third-party libs. No `dlsym`. No fn-pointer dispatch (use
  opaque kind tags + `when` cascade per `NOTES/III-MONOMORPHIC.md`).
* Crypto: SHA-256/512, AES-128/256, AES-GCM, ChaCha20, Poly1305,
  ChaCha20-Poly1305, Ed25519, X25519, HMAC, HKDF, PBKDF2, Blake2s,
  CRC32, MurmurHash3, SHA-3 (Keccak), SHAKE128/256 — all hand-rolled
  in `STDLIB/iii/numera/*.iii`.

## §6. Active phase progression

Per `LATTICE-CHANGELOG.md` §0–§50:

* **Phase 0** (reconciliation) — complete.
* **Phase 1** (`omnia/sid.iii` crystal-graph) — complete.
* **Phase 2** (14 modifier vocabulary additions: `@crystal`, `@dynamic`,
  `@sealed`, `@linear`, `@bounded`, `@variant`, `@k`, `@provenance`,
  `@constant_time`, `@side_channel_resistant`, `@dynamic_impact`,
  `@provenance_linked_error`, `@arena_reset_safe`, `@crystal_self_attest`)
  — sema decode + cg_r3 stub emission complete (Tier 1, 2026-05-08).
* **Phase 3** (`omnia/ripple.iii` core) — complete.
* **Phase 4** (reset-safe memory + witness equivalence) — complete.
* **Phase 5** (compiler ripple integration: `cg_r3` lowering, `jit_emit`
  trampoline, `emit` layered seal, `sema` impact aggregation,
  self-host ripple) — complete (Tier 1, 2026-05-08).
* **Phase 6–13** (numeric tower, crypto provenance, networking/async,
  data/parsing, collection provenance, ecosystem tooling, governance,
  final integration) — partial; see changelog entries §40–§50 for status.
* **Phase 14h** (Glyph V3 polymorphic-data forms) — complete (16 of 16
  forms in `STDLIB/iii/verba/glyph_*.iii`).

## §7. The 2026-05-08 architectural refactor (this snapshot)

Items 1–10 of the audit verdict, executed in this pass:

1. **Purge** of 738 generated artifacts (assembly dumps, smoke leftovers,
   probe build artifacts, `.iiifrag` generator outputs, `.tmp` scratch).
2. **`BUILD-ARTIFACTS.md`** at repo root — discipline doc + one-shot
   purge command.
3. **`DOCS/README.md`** — navigation overlay on the 36 spec docs;
   complements (does not replace) the constitutional `III-INDEX.md`.
4. **`R1-SUBSYSTEMS.md`** at repo root — index of the 32 parallel C
   reference implementations with three-state classification (REFERENCE-IMPL
   / SUPERSEDED-BY-STDLIB / PARTIAL-OVERLAP / EMPTY-PLACEHOLDER).
5. **`COMPILER/BOOT/STAGE1-PORT-INDEX.md`** — `.c` ↔ `.iii` port-status
   pairing for all 18 bootstrap TUs.
6. **`STAGE1/BOOT/` → `COMPILER/BOOT/stage1_port/`** — colocated all
   stage-1 work under one roof.
7. **`_SUPERSEDED_BY.md`** markers in 6 subsystem dirs (CATALYST,
   FEDERATION, GENESIS-VECTOR, OBSERVABILITY, POLYMORPHIC-DATA, SANDBOX) —
   pointers to the live `STDLIB/iii/` replacements.
8. **`run_all_corpora.sh`** at repo root — single-command driver for both
   `STDLIB/corpus/` (179 tests) and `COMPILER/BOOT/stage1_corpus/`
   (57 tests).
9. **`build_stdlib.sh --clean`** flag — symmetric with `build_iiis0.sh`.
10. **`NOTES/ARCHITECTURE.md`** — this file.

After items 1–10, the repo passes one continuous discipline pass: every
generated artifact is gone or documented, every spec doc is indexed,
every subsystem is classified, every stage-1 file is colocated, every
build script has `--clean`, and one driver runs every corpus.

## §8. Pointers

| To learn... | Read |
|---|---|
| ...the language constitution | `DOCS/III-INDEX.md` |
| ...the spec docs | `DOCS/README.md` (then individual `DOCS/III-*.md`) |
| ...what's R1-sealed vs derivative | `DOCS/README.md` §1 + §2 |
| ...the 32 R1 reference impls | `R1-SUBSYSTEMS.md` |
| ...the self-host port progress | `COMPILER/BOOT/STAGE1-PORT-INDEX.md` |
| ...what should never be committed | `BUILD-ARTIFACTS.md` |
| ...recent operational history | `NOTES/LATTICE-CHANGELOG.md` |
| ...module namespace rules | `NOTES/III-NAMESPACES.md` |
| ...generics strategy | `NOTES/III-MONOMORPHIC.md` |
| ...mandate audit history | `DOCS/MANDATE-LEDGER.md` |
| ...binary hash history | `DOCS/MHASH-LEDGER.md` |
