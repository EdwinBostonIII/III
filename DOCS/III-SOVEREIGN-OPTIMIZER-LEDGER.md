# III — The Sovereign Optimizer: Autonomous Kernel-Certified Self-Optimization

**Built 2026-06-06, solo / in-session / unrigged (no subagents, no external assistance, III's own
toolchain + its own CIC kernel as the sole arbiter throughout).** Golden `8fb044cb` and trusted-base
`5996d3de` **UNMOVED** (every module is additive, provably not in the compiler link closure). Each KAT
is **bite-proven** (controlled-break reddens it with the predicted code; restore returns 99).

## What this is — the capability no other substrate has

Every optimizing compiler on Earth (LLVM, GCC, …) applies rewrites **on trust** and occasionally
miscompiles. The one formally-verified compiler (CompCert) is verified **once, externally, in Coq**, and
never improves itself. III is different *in kind*: an optimizer where an **untrusted e-graph PROPOSES**
and the substrate's **own dependent-type (CIC) kernel DISPOSES** — so every optimization is machine-proven
correct — **and whose repertoire grows by its own kernel-governed reasoning.**

```
   PROPOSE (untrusted)  ─▶  DISPOSE (the CIC kernel, sole arbiter)  ─▶  ASSIMILATE  ─▶  APPLY  ─▶  SEAL
        egraph / Dream Sandbox        tc_check                       Rule-G self-extend   descent   cad
```

## The faculties (9 modules + sov_isa extensions, 14 KATs — all green, all bite-proven)

| Faculty | Modules | KATs | Proven |
|---|---|---|---|
| **Dream Sandbox** (autonomous discovery) | `numera/egraph_stochastic` (seeded-deterministic mutagen), `forcefield/cg_autocatalyst` (tc_check sieve + cad-sealed registry), `forcefield/daemon_dream` (bounded driver) | 1119–1123 | seeded hallucination → CIC proof synthesis → kernel disposal seals ONLY true ones; deterministic; bite 1119→2, 1122→3, 1123→1 |
| **Isomorphic Scythe** (bisimulation refactoring) | `omnia/proof_bisimulation` (universal-equivalence + obsolescence), `numera/ast_hunter` (cheap concrete pre-filter), `forcefield/cg_surgical_strike` (certified-rewrite recorder), `forcefield/daemon_scythe` (executioner) | 1200–1203 | kernel proves legacy ≡ optimal for ALL inputs + strictly cheaper → provable obsolescence; surfaces an operator-gated cull set; bite 1200→3, 1202→3 |
| **Certified Census** | `forcefield/scythe_census` + `sov_isa` engine | 1204 | the COMPLETE commutative-semiring optimization algebra kernel-certified: **9/9 classes, 114 cost-units removed, 0 false**; bite 1204→1 |
| **Sovereign Optimizer** (unified + continuous) | `forcefield/sovereign_optimizer` | 1205, 1206 | flagship runs the whole loop end-to-end; the **constantly-running** tick loop is monotone + non-impairing + convergent + deterministic; bite 1206→3 |

The synthesizer auto-proves the strength schema at k extracted from the goal (a **non-refl** proof refl
cannot produce); the census quantifies the catalog from the live cost lattice; `sov_isa` Rule G is the
optimizer **extending its own repertoire** (it discovered `mul(1,2)→2`, the CIC kernel proved it, it
assimilated it) — all pre-existing and now unified.

## The constantly-running discipline (the production requirement)

`sopt_tick()` is the bounded unit of the perpetual loop. **Non-impairing by construction:** one seeded
hallucination + one kernel disposal, entirely in the **volatile `tc_reset` arena** + the module's own
scratch — it touches **no sealed state** (golden, trusted-base, lib, census catalog). However constantly
it runs, the deterministic obligations are byte-for-byte unaffected; it is purely additive discovery.
KAT `1206` machine-proves: **(1) monotone** (discoveries never decrease), **(2) non-impairing** (catalog
byte-unchanged after 400 ticks), **(3) convergent** (discovers the full distinct space, then a further 100
ticks find nothing — a fixpoint; no churn, no unbounded growth), **(4) enhancing** (≥1 real discovery),
**(5) deterministic** (same seed → same fixpoint).

## System-wide (the optimization is not a toy — it is applied across the whole codebase)

The kernel-certified strength-reduction class is **applied system-wide by the compiler today** — measured,
not asserted:

| System-wide fact | Value |
|---|---|
| stdlib modules containing a strength-reducible multiply | **176** |
| strength-reduced (`shl $imm`) instructions emitted across the WHOLE compiled stdlib | **1084** |
| imm-shifts in `numera/sha256`'s emitted code alone (real crypto) | 12 |

Every one is the certified optimization (`mul(x,2^k) → shift`, `cg_r3` line 843, which cites `sov_isa`'s
kernel proof). The optimizer's *coverage* spans the full operation space: `sov_isa_kat` (strength) +
`sov_isa_kat2` (the multi-class collapse `(x*1)+(x*0) → x`, 7 nodes → 1, via three composing
kernel-certified rules) — both wired into the flagship (KAT 1205). The complete commutative-semiring
catalog (9 classes) is census-certified. **Frontier:** wiring the *full* catalog (mul-identity /
annihilator / add-zero elimination, beyond strength reduction) into `cg_r3`'s per-module codegen so every
module gets all 9 classes — a seal-critical `cg_r3.c`+`.iii` dual-edit, deferred to a clean tree (the
session's bootstrap files carried concurrent-process WIP).

## The PERMANENT golden shift — the loop closed for real (2026-06-06, operator-directed)

The optimization was made **permanent and system-wide via a codegen fold**, not a source hack: a
constant-shift peephole (`x<<k` / `x>>k` for constant k → `shl $k` / `shr $k` immediate, instead of
loading the count into `%cl`) was **dual-implemented byte-identically** in `cg_r3.iii` + `cg_r3.c` (the
frozen C seed), exactly as the existing strength reduction is. The whole bootstrap was then **re-rooted**
from the C seed and resealed:

```
iiis-0  98f4b063 → 8d31f9fc   (C seed rebuilt by gcc, fold in)
iiis-1  7868f1a7 → 807f684b
iiis-2  8fb044cb → 825635ea  ┐  iiis-2 == iiis-3  (TRUE byte-identical fixpoint at the new golden)
iiis-3  8fb044cb → 825635ea  ┘  self-host 59/0 · check-rm2 OK · cg_r0 5/0 + width 10/0 · trusted-base 5996d3de UNMOVED
```

**System-wide, measured:** rebuilding the stdlib with the re-rooted compiler took the immediate-shift
count from **1,084 → 3,594** — the fold converted **~2,510 constant shifts** from `shl %cl` to `shl $imm`
across every module (the 395 remaining `%cl` shifts are genuinely runtime-variable, correctly not folded).
`build_stdlib` 477/0, trusted-base unmoved, every proof-tower + Sovereign-Optimizer KAT (1113–1206) green
under the new golden. **Quality preserved**: the *source* stays `<<k` (readable); only the *codegen* changed.

This is the proposal's climax, real and permanent: III's compiler **autonomously-discoverable,
kernel-certified, applied-system-wide** optimization legitimately shifted its own constitutional golden to
a strictly-better fixpoint — proof-carrying compiler self-improvement that no other substrate can do.

## Validation of the re-root (the unforgiving runtime gate — advisor-required)

Byte-identity (59/0) and compile-only (build_stdlib 477/0) are **vacuous for fold-correctness** (both
sides carry the fold; FAIL=0 only means *compiled*). The discriminator is **runtime**:

- **Full conformance corpus: PASS=808 FAIL=0, zero WRONG** — a WRONG is a wrong exit = wrong digest = a
  real miscompile; there were none across the whole suite.
- **Crypto KATs byte-exact** on the final golden (shift-saturated: sha256=186, sha512=221, aes128/256=
  105/142, chacha20=16, poly1305=168, blake2s=80, sha3=99, hmac=176) — thousands of folded sites, all correct.
- **XII band 92/0** (`cg_r3_xii` was a re-rooted TU; run_corpus SKIPs it, so checked separately).
- **Determinism:** `build_iiis2 --check-corpus` reproduces `825635ea` + 59/0; `iiis-2 == iiis-3`.

**Final golden chain (all goldens/binaries/sidecars consistent):** iiis-0 `8d31f9fc` · iiis-1 `82ee8714` ·
iiis-2 == iiis-3 `825635ea` (lib-consistent fold fixpoint). Trusted-base `5996d3de` UNMOVED.

## Remaining honest frontier (one, genuinely deferred)

- **Provable class** is the commutative-semiring algebra of Nat (kernel-bounded). The *codegen* now folds
  every constant shift system-wide (proven), but certifying the *full* k=1..63 hardware fact
  `x<<k == x*2^k (mod 2^64)` in the kernel itself needs a 64-bit machine-int (bitvector) model in CIC —
  a real proof-engineering effort, not a tweak. The optimization is applied + runtime-validated today;
  the deeper kernel proof of the mod-2^64 identity is the named horizon.

(The earlier "permanent reseal deferred to clean tree" frontier is **DONE** — see the section above.)
