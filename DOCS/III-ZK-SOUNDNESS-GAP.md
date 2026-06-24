# III zk layer — the soundness gap (honest ledger), found by the discriminating test

> **One line:** `air_stark_verify` accepts a proof of a FALSE computation (a forged interior/transition trace
> cell), so III's STARK does **not** soundly prove computation. Boundary constraints and proof-integrity *are*
> enforced; the **transition-constraint soundness (FRI low-degree binding) is not.** The session's "ZK-ATTESTED"
> claims overstated this and are corrected here.

## How it was found (the test that separates a zkVM from a constraint demo)

The per-opcode gadgets (`zk_svir_add/sub/mul/.../prog`) each hand-write a trace as constant arrays, hand-write the
AIR constraints, and call `air_constraints_hold()` (returns 1), then perturb one chosen cell and confirm it returns
0. That is **prover-side satisfiability** — "I transcribed my own arithmetic correctly, and the specific tamper I
picked is caught." It is **not** a zero-knowledge proof an independent verifier checks, and "99 first try" is
near-tautological (verify the arithmetic by hand, then confirm the same arithmetic passes).

The discriminating test (`STDLIB/sovir/zk_svir_attest.iii`) does the un-fakeable thing instead:
1. the trace is **computed** by running a recurrence (`c0' = c0*c1, c1' = c1+c0` over GF(998244353)) — nothing
   hand-authored;
2. `air_stark_prove()` emits a **real proof object** (Merkle-committed trace roots, Fiat-Shamir challenges +
   queries, a FRI certificate, openings);
3. `air_stark_verify()` checks it **without the witness** (re-derives the FS challenges, verifies every Merkle
   opening, the AIR constraint `CP[q]·Z_H(q) == air_combine_opened` at the random query points, and the FRI folding);
4. a **false** computation (one cell broken) is then proven and verified.

## The result (measured, reproducible: `zk_svir_attest.exe` → exit 92)

| case | forged cell | `air_constraints_hold` | `air_stark_verify` |
|---|---|---|---|
| honest | — | 1 (holds) | **0 = ACCEPT** (correct) |
| **interior forge** | `trace[4][0]` (transition-constrained) | **0 (violated)** | **0 = ACCEPT** ← unsound |
| boundary forge | `trace[0][0]` (pinned by `air_add_boundary`) | 0 (violated) | nonzero = REJECT (correct) |

So the verifier **accepts a proof whose trace violates the transition constraint** (interior forge), while it
correctly **rejects** a violated *boundary* pin. The forge genuinely breaks the constraint (the diagnostic confirms
`air_constraints_hold` returns 0 before proving — it is not a test artifact). I use the API identically to the
working `proof_stark.iii::ps_prove_valid` (setup → fill → prove → verify), so it is not misuse.

## Why (mechanism — hypothesis, to be confirmed in the fix)

`air_stark_verify` line 755 checks `CP[q]·Z_H(q) == air_combine_opened` — but this holds **by construction**: the
prover builds `CP[x] = combine[x]·Z_H(x)^{-1}` pointwise on the LDE, so the consistency check passes for *any* trace,
honest or forged. The actual computational soundness must therefore come **entirely from FRI proving `CP` is
LOW-DEGREE** — an honest trace makes `combine` divisible by `Z_H` so `CP` is a genuine degree-≈`n` polynomial, while a
forged trace makes `CP` a degree-≈`d-1` object (`d` = LDE size). The verifier accepting the forged case means the FRI
degree bound is **too loose** (≈`d`, the LDE size, rather than the tight ≈`n`), so FRI is effectively vacuous: every
`CP` of degree `< d` passes. The boundary openings are checked directly against pinned values, which is why the
boundary forge is caught.

## The honest ledger — what III's zk layer actually provides today

- **PROVEN:** per-opcode AIR systems are *satisfiable/violated* correctly (`air_constraints_hold` is 1 on honest,
  0 on any constraint-breaking cell — a real, deterministic check, but **prover-side**, not a proof).
- **PROVEN:** the STARK's *proof-integrity* — Merkle openings + FRI folding of the committed `CP` round-trip, and
  tampering the *proof* is rejected (`zk_air_stark_selftest`).
- **PROVEN:** *boundary* constraints are soundly enforced by the verifier.
- **NOT PROVEN (the gap):** *transition-constraint* soundness. `air_stark_verify` accepts a proof of a computation
  that violates its transition constraints. So "the SVIR ISA is attestable in zero knowledge" is **false as stated**;
  what exists is a per-opcode constraint library + a STARK whose low-degree binding is not tight.

## The fix (the real next bottleneck to surpass)

Make the FRI degree bound **tight**: the verifier must reject a `CP` of degree greater than the composition
polynomial's true bound (≈`n`, not the LDE size `d`). Concretely, audit `air_stark_prove`'s `CP` construction +
FRI-layer count `NL` and `air_stark_verify`'s final-layer / degree check so that a degree-`(d-1)` `CP` (the forged
case) folds to an **inconsistent** final value and is rejected. `zk_svir_attest.exe` returns **99** when fixed (both
forges rejected) and **92** while the gap remains — it is the regression oracle for the fix.

## Discipline note

This gap was invisible to every "99" in the gadget reports because those checks have **no external oracle** — the
expected answer is designed to appear. The DDC work earlier was sound precisely because it *had* an oracle (two
independent compilers must agree byte-for-byte). `zk_svir_attest` restores an oracle to the zk layer: an independent
verifier that must reject a false statement. Until it returns 99, the zk attestation is not sound, and no report
should claim otherwise.
