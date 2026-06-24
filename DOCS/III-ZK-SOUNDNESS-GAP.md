# III zk layer — the soundness gap, found AND FIXED by the discriminating test

> **✅ RESOLVED.** The gap below was closed. Root cause: `air_build_cp` divided `combine` by `Z_H = x^n-1` (vanishes
> on all `n` rows), but the transition binds only rows `0..n-2`, so the correct vanishing poly is `Z_T = Z_H/(x -
> ω^{n-1})`; and `CP` was built pointwise (degree `d-1`, vacuous FRI). Fix: build `CP` as the TRUE quotient
> `combine·(x-ω^{n-1}) / Z_H` (= `combine/Z_T`) via INTT → coefficient shift → NTT, and apply the same `(x-ω^{n-1})`
> factor in the two verifier-side checks (`air_stark_verify` line-755, `air_cp_consistent_at`). Now `CP·Z_H ==
> combine·(x-ω^{n-1})` holds for honest traces and FAILS at FS-random openings for forged ones. **`zk_svir_attest`
> reads 99** (honest accepts, interior + boundary forges rejected by the MATH); zk gate 15/15 green; STARK corpus
> (proof_stark, zk_air_stark, zk_stark_fri, zk_rev, zk_stark_seal) all 99 — no regression. III's STARK soundly
> proves a real computation, verified by an independent witness-free verifier. The historical analysis follows.



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

## The fix — DEEPER than the FRI bound (confirmed by attempting it)

First attempt: tighten the FRI to fold to the blowup size `AIR_B` (proving degree `< n`) instead of to 1 (proving
degree `< d`, vacuous). Applied as a one-line change to `air_stark_prove`'s fold loop, recompiled, run against the
oracle → **the HONEST proof stopped verifying** (`zk_svir_attest` → exit 1). That failure is the real diagnosis:
**the honest `CP` is ALSO not low-degree**, so tightening the FRI rejects it too.

Root cause, precise: `air_build_cp` (line ~228) builds `CP` **pointwise** as `combine·inv(Z_H)`, and sets `CP[j]=0`
on the **trace domain** (`j & (AIR_B-1) == 0`, where `Z_H=0`). The LDE is the multiplicative **subgroup** of size
`d=AIR_B·n`, which *contains* the trace subgroup of size `n`. So at the `n` trace-domain points the true quotient is
a `0/0` limit, and the code substitutes `0` — making `CP` a degree-`(d-1)` interpolation of *{0 on the trace domain,
combine/Z_H elsewhere}* rather than the genuine degree-`<n` quotient. This is high-degree for **honest and forged
alike**; folding to size 1 (degree `< d`) accepted both, which is why the gap was invisible.

**The real fix (substantial, the honest next bottleneck):** evaluate the LDE on a **coset** `g·⟨ω⟩` (with `g` a
generator NOT in the subgroup) so `Z_H(x_j) = x_j^n - 1 ≠ 0` for *every* `j`. Then `CP[j] = combine[j]·inv(Z_H[j])`
is the true quotient everywhere (no trace-domain special case), degree `< n` for honest, degree `~d-1` for forged.
THEN tighten the FRI (fold `log₂(n)` times to size `AIR_B`, require the final layer constant). This touches
`air_build_lde`, `air_build_cp`, the FRI fold/eval in both `air_stark_prove` and `air_stark_verify`, and `Z_H`
evaluation — a careful, multi-function change to the whole STARK, not a one-liner. It must be done deliberately (a
subtly-wrong STARK that *appears* to verify is worse than a known-gap one).

`zk_svir_attest.exe` is the regression oracle throughout: **92** = the gap (today), **1** = honest broken (a partial
fix), **99** = sound (honest accepts, both forges reject). Do not claim ZK soundness until it reads 99.

## Discipline note

This gap was invisible to every "99" in the gadget reports because those checks have **no external oracle** — the
expected answer is designed to appear. The DDC work earlier was sound precisely because it *had* an oracle (two
independent compilers must agree byte-for-byte). `zk_svir_attest` restores an oracle to the zk layer: an independent
verifier that must reject a false statement. Until it returns 99, the zk attestation is not sound, and no report
should claim otherwise.

## The SECOND landmine — the permutation argument (⚠️ STILL UNSOUND IN-PROTOCOL; the FS-α "fix" was self-graded)

> **⚠️ REOPENED (advisor-surfaced, malicious-prover test). The FS-α "fix" below was INSUFFICIENT and self-graded.**
> `zk_perm_oracle=99` only proved the *honest* α (= `derive(trace)`) rejects *one hand-picked* forge -- it never let a
> MALICIOUS prover CHOOSE α. The discriminating test `zk_perm_malicious.iii` does: it bakes a NON-permutation
> `{3,3,5,10}` (vs program `{3,7,5,9}`) with the prover's OWN colliding `α'=11` into the constraints and runs the FULL
> STARK. **`air_stark_verify` ACCEPTS it (exit 50)** -- because the permutation challenge α is set by `air_add_term`
> BEFORE proving and `air_stark_verify` NEVER re-derives it from the committed trace (it re-derives only the
> *combination* alphas, `air_derive_alphas`). So the permutation is **unsound in-protocol**, and **ZK-MEMORY +
> ZK-FUSED inherit it** (their permutation pillar is forgeable; their "99" is self-graded, the same flaw one level up).
> **THE REAL FIX:** `air_stark_verify` must re-derive α (and β) from the committed trace roots and reject any proof
> not using that α -- i.e. the grand-product challenge must be a STARK-managed Fiat-Shamir value bound to the
> commitment, not a baked constant. `zk_perm_malicious` flips 50->99 when fixed. SOUND meanwhile: the TRANSITION-ONLY
> pillars (ZK-STACK/OPCODE/LOOP/OMEGA-E) -- they don't use the permutation and rest on the re-derived combination
> alphas. The Z_T quotient fix and the two overflow-bug fixes also stand. The (insufficient) FS-α history follows.

### (insufficient) the FS-α attempt
> `zk_perm_oracle` reads **99**: it reproduces the fixed-α=11
> unsoundness (the forge `{3,3,5,10}` is accepted), then shows the fix — **α derived by Fiat-Shamir from a non-linear
> (square-mixing) hash of the access values VO++VS** — REJECTS the same forge, while still ACCEPTING an honest
> permutation (a permutation's grand product is **α-invariant**, so correctness is preserved). The adaptive attack
> (pick a non-permutation that collides at the *known* α) is defeated: α now depends non-linearly on the values, so
> the prover commits to them before α is determined and cannot solve for a collision. Gated `PERMUTATION : FS-alpha
> SOUND`. Residual: the demo seeds the hash from the values directly (full deployment derives α from the STARK's
> committed column roots), and the 30-bit field bounds grinding (a larger field hardens it). The memory/copy argument
> is now safe to make load-bearing — which unblocks LOCAL_GET/SET, branches, and loops. Historical detail follows.

### (historical) the gap as originally found

The Z_T fix above made the **transition** quotient sound. It did **nothing** for the **grand-product permutation**
argument (`zk_svir_mem`, the memory/stack-consistency brick). That argument proves multiset equality by
`∏(α − v_i)` over two orders with **α a fixed public constant (11)** — and a fixed public α is unsound against an
adaptive prover, who picks a NON-permutation whose product *collides* at that one α.

- **Oracle (`STDLIB/sovir/zk_perm_oracle.iii`, exit 50 = UNSOUND):** the honest sorted multiset `{3,5,7,9}` has
  `∏(11−x) = 8·6·4·2 = 384`. The non-permutation `{3,3,5,10}` (factor 384 as `8·8·6·1`) has `∏(11−x) = 384` too.
  It is **not** a permutation of the program order `{3,7,5,9}`, yet the boundary `aS_4 = 384` is satisfied and every
  transition holds — so `air_constraints_hold` AND `air_boundaries_hold` **both accept the forged memory trace**.
  `zk_svir_mem`'s own NEG-B only ever used a non-permutation whose product *differs* (576≠384), so it never caught this.
- **Why it isn't currently exploited:** the sound attestations (`ZK-SOUNDNESS`, `ZK-FOLD`, `ZK-RIPPLE`) use only the
  sound **transition** STARK; none routes through the permutation. So the gap is **quarantined**, gated as
  `PERMUTATION-QUARANTINE` (reports 50, does not fail), and the oracle stands guard.
- **The fix (the named follow-on, required before ANY memory/loop/LOAD-STORE zkVM):** derive α by **Fiat-Shamir from
  the committed `v`-column roots** (commit-then-challenge, exactly as `air_derive_alphas` does for the composition
  coefficients), so α is unknown when the prover commits its accesses and cannot be collided. `zk_perm_oracle` flips
  to **99** when this lands. Do not wire the permutation into a sound zkVM until it does — that would re-enter the
  self-confirming-99 failure through a different door.
