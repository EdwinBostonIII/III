# Sovereign Ledger — The Forge Manifest

Signed registry of every Sovereign Artifact in III. One row per fundamental invariant, bound by the
Generative Sovereignty discipline (see `DOCS/SOVEREIGN_FORGE.md`): a single SOURCE `.def`, a
GENERATOR with a `--check` drift gate, the CONSUMERS it emits, a machine-checked PROOF that fixes the
source as the unique correct solution, and a content-addressed SEAL.

This file is itself a Sovereign Artifact (it carries its own row, §row 0). Its closure root —
Keccak over all rows' seal-hashes — appends to `MHASH-LEDGER.md` and emits one witness-spine fragment
(`STDLIB/iii/sanctus/witness.iii`), and is signed by the Founders-Anchor via the existing
`COMPILER/BOOT/sign_xii_manifest.c` path. Per **M20** the ledger may seal its own contents but no
proof herein asserts the substrate's own soundness (that remains the iiis-2 ≡ iiis-3 bootstrap fixed
point).

**Status legend:** `CONFORMANT` = full 5-tuple wired + proof green + sealed · `RETROFIT` = generator
exists, missing drift-gate/proof/manifest binding · `SPRAWL` = hand-copied, no single source ·
`STAGED` = scaffolded, execution pending · `SEAL-CRITICAL` = touches compiled compiler / admission
boundary, governed by CRASH-DEBUGGING PROTOCOL.

---

## Manifest rows

| # | Artifact | Source `.def` | Generator | Consumers (current) | Proof gate | Seal | Cost vec | Status | Fwd-ref |
|---|----------|---------------|-----------|---------------------|-----------|------|----------|--------|---------|
| 0 | **Forge Manifest** (this file) | `DOCS/SOVEREIGN-LEDGER.md` | `sign_xii_manifest.c` (reused) | `build_stdlib.sh`, `subsystem_test_gate.sh` | manifest-closure-check (every `gen_*` has a row) | Keccak over all rows | — | STAGED | #8 family |
| 1 | **Compositions** | `COMPILER/BOOT/iii_compositions.def` ✓ | `gen_compositions.sh` ✓ (`--check` ✓) | `iii_compositions.h` → `cg_r3.c`; `omnia/prespec.iii` | well-formedness (pending) | pending | pending | RETROFIT (closest to conformant) | — |
| 2 | **SHA-256** | `iii_sha256.def` (to author: K[64]/IV from primes, D3) | `gen_sha256.sh` (to author) | **16+ hand-copied** `.c`: LEXICON, CATALYST, CATALYST-EXT, FEDERATION, FOUNDERS-ANCHOR, GENESIS-VECTOR, GHOST-CODE, MODULES, OBSERVABILITY, PLANETARY, POLYMORPHIC-DATA, SANDBOX, SOVEREIGN-WEB, TRINITY + `numera/sha256.iii` + `stage1_port/sha256.iii` | KAT (FIPS-180-4) + **byte-identity across all sites** | pending | pending | SPRAWL → target F1 | #7 |
| 3 | **CIC inductives** | `iii_cic_inductives.def` (to author) | `gen_cic.sh` (to author) | `TYPES/src/cic.c` recognizer + proof-cache keys | positivity + guardedness; 6 accepted byte-exact | pending | pending | STAGED (spec done #25) | #25 |
| 4 | **IRPD method-table** | `iii_irpd.def` (to author) | `gen_irpd.sh` (to author) | `COMPILER/BOOT/sid.c` + `sema.c` | byte-identical dispatch from both | pending | pending | STAGED | #9 |
| 5 | **XII rule-set** | `iii_xii_rules.def` (to author) | `gen_xii_rules.sh` (to author) | `omnia/xii_rewrite.iii` (R001–R044) + `omnia/xii_critpairs.iii` | confluence (all enabled critical pairs join byte-equal) — already holds | pending | pending | RETROFIT (theorem proven, generation pending) | #22 |
| 6 | **Hexad** (Forge Citizen #1) | `iii_hexad.def` (to author) | `gen_hexad.sh` (to author) | `COMPILER/BOOT/hexad_check.{c,iii}`, `stage1_port/hexad_check.iii`, `TYPES/src/hexad.c`, `HEXAD/src/hexad_algebra.c`, `sid` gate, `xii_asym_reach6.h` (144-admission) | **`HEXAD/tests/hexad_bricking_proof.c`** (GREEN: T1=0, T2=6/6, T3=0, 144 admissible) | pending | pending | SEAL-CRITICAL → target F5 | #8 |

### Pre-existing bespoke generators to fold in (RETROFIT)

These already generate, but lack the unified `--check`/proof/manifest binding. They join the ledger
as their citizens are forged (XII family → rows as F4 lands; trinity certs → its own row):

- `COMPILER/BOOT/gen_xii_r1.c` — XII R1 seed
- `COMPILER/BOOT/gen_xii_manifest.c` + `sign_xii_manifest.c` — XII manifest (signature primitive reused by row 0)
- `COMPILER/BOOT/gen_xii_lattice.c` — 126 patterns × 7 ISA targets (the multi-backend prototype; generalized at F6)
- `COMPILER/BOOT/gen_xii_anchor_keypair.c` — Founders-Anchor keypair (signs this ledger)
- `COMPILER/BOOT/gen_trinity_certs.c` — Trinity certificates

### KATABASIS descent citizens (CONFORMANT — Forged ahead of the F1+ ballot)

The KATABASIS descent (`DOCS/III-KATABASIS.md` FR-9 / plan 6.9) requires its hardware-bound tables
to be single-sourced so the safety typing and the verified silicon facts cannot drift. These six
are fully wired — source `.def` + generator + `--check` drift gate in `build_stdlib.sh` + KAT proof
+ content-address seal — and were Forged **additively** with byte-identical `.o`, so the metal-tested
`gate_resident.sys` (`472152e3…`) is unchanged (only svm_layout, cycle_family, bar_layout sit in that closure; census, vmexit, ring_lattice are standalone). Per-row seal recipe:
`sha256( iii_<art>.def || gen_<art>.sh || katabasis/<art>.iii || <primary KAT>.iii )` — the FULL Forge content address (source + generator + generated output + machine-checked proof,
per `SOVEREIGN_FORGE.md` §1) — NOT a reduced source-only digest; the drift gate independently
enforces `consumer == generator(def)`. Full 64-char hashes below (M6: the hash is the identity).

| # | Artifact | Source `.def` | Generator | Consumers | Proof gate | Seal (full sha256: def\|\|gen\|\|consumer\|\|KAT) | Cost | Status |
|---|----------|---------------|-----------|-----------|-----------|------|------|--------|
| K1 | **SVM layout** | `iii_svm_layout.def` ✓ | `gen_svm_layout.sh` ✓ (`--check` ✓) | `katabasis/svm_layout.iii` — region classifier + per-offset hexad (the §4.7 WriteMetal brick defense) | corpus 390 (svm hexad) + 391 (cycle-term dominance) | `4810b9b4640560ae961d038bd4c0660bdf047bdfba1e65e377c551b6f054884d` | K 1.00 | CONFORMANT |
| K2 | **Cycle family** | `iii_cycle_family.def` ✓ | `gen_cycle_family.sh` ✓ (`--check` ✓) | `katabasis/cycle_family.iii` — the plan-3.0 nine-family taxonomy the Gate dispatch reads | corpus 392 (cycle_family) + byte-identical `.o` `7e162b69…` | `80795a275c9f4836661e6deedbb98ea53d1b5a14e13f53fa9187205dccb35289` | K 1.00 | CONFORMANT |
| K3 | **Census** | `iii_census.def` ✓ | `gen_census.sh` ✓ (`--check` ✓, +count-coupling guard) | `katabasis/census.iii` — the 16 verified AD103/Ryzen facts (the Census Crystal expectation) | corpus 603 (census, +OOB-index drift negatives W5.1) | `6515e244edea0ff900982a1a4fce37ae73bdc669abc1ce078d815ec67467bf2b` | K 1.00 | CONFORMANT |
| K4 | **BAR layout** | `iii_bar_layout.def` ✓ | `gen_bar_layout.sh` ✓ (`--check` ✓) | `katabasis/bar_layout.iii` — the AD103 GPU BAR address map (F9/CoprocDispatch write typing) | corpus 394 (bar typing **+ `katabasis_bar_cycle_admissible` action-parameterized arm, gap #33**) + byte-identical `.o` `c0e7d840…` | `27e6f389e62c9b3d373a8eaf35262e16b46d5ee77d0c95b8afc1fb836c90dd26` | K 1.00 | CONFORMANT |
| K5 | **VMEXIT set** | `iii_vmexit.def` ✓ | `gen_vmexit.sh` ✓ (`--check` ✓) | `katabasis/vmexit.iii` — the minimal deterministic VMEXIT set (the R-1 Floor's exit taxonomy) | corpus 600 (vmexit) + byte-identical `.o` `2ff4ec9b…` | `75c646c14b735f2dcfd4102b965e544622a852bc22d514ad890e966c13c690d2` | K 1.00 | CONFORMANT |
| K6 | **Ring lattice** | `iii_ring_lattice.def` ✓ | `gen_ring_lattice.sh` ✓ (`--check` ✓) | `katabasis/ring_lattice.iii` — the legal ring-transition lattice (the lawful src->dst crossings); **re-sealed for the II-RING_LATTICE-1/2 domain guard** (out-of-range/u32-wrapping ids can no longer alias a legal key) | corpus 601 (ring_lattice, +alias/wrap negatives) | `77a631b71f1275bc4a1b4033d04395cf00350cf335375f8a21398efd685b86af` | K 1.00 | CONFORMANT |

---

## Closure

```
Forge closure root = Keccak-256( concat( sort_by_name( row[i].seal_hash ) ) )
```

Appended to `DOCS/MHASH-LEDGER.md` on each seal; witnessed via `sanctus/witness.iii`; signed by the
Founders-Anchor. Verification: `subsystem_test_gate.sh` recomputes the closure root and checks the
Anchor signature; mismatch is fatal (analogue of the D8 closure-pin `MOD-RES-001`).

**Current closure:** the manifest closure root (Keccak over ALL rows' seal-hashes) remains
uncomputed while the broad citizens rows 1–6 are unsealed (scaffold stage F0; the first broad seal
lands with the SHA-256 citizen, F1). The six KATABASIS descent citizens (K1–K6) are, however,
individually content-address-sealed with the full-spec seals K1-K6 AND carry a **computed descent
sub-closure root** `4cf5b98a12eadecab7b7b130e655cbb5643898de80a42c1c3c92f7da06f02b7e`
(= `sha256` over the sorted K1-K6 seal-hashes; recomputed and checked by `COMPILER/BOOT/forge_check.sh`),
and are drift-gated **today** — so the descent's FR-9 mandate ("the
whole descent is FORGED") holds for all six descent data tables (svm_layout, cycle_family, census, bar_layout, vmexit, ring_lattice): editing any of
their `.def` sources regenerates the consumer and a hand-edit fails `build_stdlib.sh`.

**W5.2 (RIPPLE-11 level D) — the descent's Keccak-256 closure root, now LIVE.** The §Closure
formula above (`Keccak-256( concat( sorted seal-hashes ) )`) is no longer "uncomputed / not
recomputable in toolset": `COMPILER/BOOT/forge_manifest_keccak.sh` recomputes it over the SAME
sorted K1-K6 seal-hashes that feed the SHA-256 descent root (NIH — hand-rolled over the in-tree
`numera/keccak.iii` via `forge_keccak_driver.iii`, no third-party Keccak). The descent's Keccak-256
closure root is **`eaf25921ac3848ee5392d93b7bf842339f18fd861fb25a43dc36ca9bb91fd0c5`** (Keccak-256
over `sort(K1..K6 seals)`; recomputed + checked by `subsystem_test_gate.sh`). Editing any descent
citizen now reddens **all three** closure levels (per-citizen drift, the SHA-256 descent root, AND
this Keccak-256 root) in one pass — the half-sealed-manifest hazard is structurally impossible. The
*broad-citizen* manifest root (Keccak over ALL rows incl. the not-yet-sealed F1+ broad citizens)
still awaits the first broad seal (F1); the recompute *tool*, however, exists today.

---

## Reseal log

**2026-06-03 — K4 BAR-layout re-seal (KAT-strengthening, verification-backed).** Gap-backlog #33
strengthened the bar_layout **primary KAT** (corpus `2412_katabasis_bar_typing.iii`) with the
`katabasis_bar_cycle_admissible` action-parameterized arm (POS-action→admissible, NEG-action→refused,
POS-action-to-host-RAM→refused). Because the K4 full-spec seal recipe is
`sha256(iii_bar_layout.def ‖ gen_bar_layout.sh ‖ katabasis/bar_layout.iii ‖ primary-KAT)`, the
**KAT change legitimately moved the K4 seal** — `bar_layout.iii`/`.def`/`gen_bar_layout.sh` are all
byte-identical to HEAD (`git` clean), and the other five descent seals (svm_layout, cycle_family,
census, vmexit, ring_lattice) match the ledger **exactly**, localizing the change to K4. Soundness
verified BEFORE reseal: `gen_bar_layout.sh --check` OK (.def→.iii consistent); corpus 394 = 99 on the
live lib (the strengthened KAT passes); all three new roots **mechanically derived from tool output**,
none hand-computed:
- K4 seal `55b70d16…` → `27e6f389…`  (`forge_check.sh --print`)
- descent SHA-256 sub-closure root `b21588fb…` → `bf18bbf0…`  (`forge_check.sh --print`)
- descent Keccak-256 closure root `830164ae…` → `c5d46fbd…`  (`forge_manifest_keccak.sh --print`)

Post-reseal verification: `forge_check.sh` GREEN **and** `forge_manifest_keccak.sh` GREEN (both gates,
no one-gate-green/other-red split). The not-yet-computed broad-citizen all-rows manifest root (F1+) is
unaffected. This is a stdlib-gate reseal of a descent data table's KAT binding — the `iiis` compiler
golden binaries are untouched (no `build_iiisN` reseal).

**2026-06-20 — K3 Census CRLF→LF repair (debloat line-ending damage, binary-neutral).** Commit
`f2c9e8d5` ("CUT 97 dead extern imports") was run through a Python pass that flipped **54 source files**
LF→CRLF, including `katabasis/census.iii`. Because `gen_census.sh` emits **LF**, the byte-exact census
drift gate (`gen_census.sh --check`) had silently failed every `build_stdlib.sh` since that commit
(census was the only CRLF file among the six drift-gated descent citizens, so it was the one that
surfaced). Repair: the 54 files were normalized CRLF→LF (`sed 's/\r$//'`), **content byte-identical sans
`\r`** (verified: each `git show HEAD:f | tr -d '\r'` == working file), and **proven binary-neutral**
(census/`xii_rewrite`/`xii_term` compile to byte-identical `.o` under CRLF vs LF — the lexer skips `\r`,
so `libiii_native.a` and its `.mhash` are unchanged). The K3 full-spec seal recipe
`sha256(iii_census.def ‖ gen_census.sh ‖ katabasis/census.iii ‖ primary-KAT)` includes `census.iii`
source bytes, so the line-ending repair legitimately moved the K3 seal. The other five descent seals
(svm_layout, cycle_family, bar_layout, vmexit, ring_lattice) were already LF and match the ledger
exactly, localizing the change to K3. Soundness verified BEFORE reseal: `gen_census.sh --check` OK
(.def→.iii consistent); all three new roots **mechanically derived from tool output**, none hand-computed:
- K3 census seal `8a508388…` → `6515e244…`  (`forge_check.sh --print`)
- descent SHA-256 sub-closure root `35b5471d…` → `4cf5b98a…`  (`forge_check.sh --print`)
- descent Keccak-256 closure root `c5d46fbd…` → `eaf25921…`  (`forge_manifest_keccak.sh --print`)

Post-reseal verification: `forge_check.sh` GREEN **and** `forge_manifest_keccak.sh` GREEN. The `iiis`
compiler golden binaries are untouched (no `build_iiisN` reseal); the binary `libiii_native.a.mhash` is
unchanged (CRLF→LF is binary-neutral). The other 53 normalized files are non-citizen source hygiene
(no per-file seal; binary-neutral), restoring the tree to its pre-`f2c9e8d5` LF state.
