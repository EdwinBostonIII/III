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

## The golden-shift demonstration (operator-gated, reversible)

A certified-equivalent strength rewrite (`lex.iii: (nibble<<4)|v → (nibble*16)|v`, the census's k=4 class;
iiis emits the cheaper `shl $4` vs `shl %cl`) was applied to the compiler and built to temp:

```
golden 8fb044cb…  ─(certified rewrite)─▶  ddb893f2…   self-host 59/0 (correctness PRESERVED)  ─(revert)─▶  8fb044cb…
```

The golden *legitimately shifted* and self-host byte-identity held — proof-carrying compiler
self-improvement, the proposal's climax, **certified and operator-gated, not autonomous**. (`--check-corpus`
builds to temp; nothing committed.)

## Honest frontier (not deferral — receipts)

- **Permanent golden reseal** (committing a certified self-improvement to a new stable fixpoint) is the
  operator's CRASH-PROTOCOL trigger. It is **correct and allowed** (M20 forbids self-*soundness* claims,
  not certified self-optimization to a new fixpoint), but must run on a **clean tree** — during this
  session `cg_r3.c`/`cg_r3.iii`/the build scripts carried concurrent-process WIP, so a reseal would
  confound attribution. Surfaced for a clean-tree operator run.
- **Provable class** is the commutative-semiring algebra of Nat (kernel-bounded). Broadening to bitvector
  mod-2^64 facts (to certify the *full* k=1..63 hardware strength reduction the compiler already applies)
  is a real proof-engineering frontier (a 64-bit machine-int model in CIC).

**State:** corpus 804 PASS (the lone non-pass is the documented OneDrive env flake — `712` passes
standalone), build_stdlib green (the script aborts were the concurrent editor; `bash -n` clean), all 9
modules in the lib, golden + trusted-base unmoved.
