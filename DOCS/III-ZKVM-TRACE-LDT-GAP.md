# III — CRITICAL zkVM soundness hole: the committed STARK has NO low-degree test on the TRACE  **[FIXED 2026-06-24]**
> **STATUS: HISTORICAL RECORD** — crash forensics / closed findings of their era; the fixes are landed and gated (reunification W6).

> **STATUS UPDATE 2026-06-24 — the first fix (`6e6cc75b`) was INSUFFICIENT (FS audit found two deeper holes); BOTH
> are now FIXED + verified by reproduce-then-fix. Production was verified unaffected throughout.**
> - **HOLE 1 FIXED:** trace_fri_commit no longer commits layer 0 separately — its commitment IS TROOT, and verify()
>   folds layer 0 from `open_trace(TROOT)`, so the LDT folds the SAME trace line-755 reads (no decoupled column).
>   `build_attack_decoupled`/`zk_trace_attack_decoupled` REPRODUCE the hole (rc=8 ACCEPT) and confirm the fix (rc 8→99
>   REJECT); the gadget's (S3) check gates it.
> - **HOLE 2 FIXED:** queries seed from `keccak(CP_final_root || trace_final_root)`, binding the CP commitment before
>   the queries (the interpolation-based reproduction is a separate sub-project; the binding fix is argued structurally).
> - Gadget `main()` rc=99 again — but now its self-tests model the COUPLED **and** DECOUPLED provers (not just coupled);
>   `run_ext4_committed.sh` EXIT 0. (Original analysis below, retained.)
> 1. **Binding gap:** the trace FRI (`TFA`/`TFROOT`, the LDT) is a SEPARATE Merkle commitment from the
>    constraint-tested trace (`TROOT`/`TLEAF`); `verify()` ties them ONLY pointwise at the 16 queries
>    (`open_leaf_tf(0,DOM,q0)==lift(fq)`). A prover commits `TROOT` on a violating trace + the trace-FRI on a
>    DECOUPLED low-degree decoy `L=honest LDE` → the LDT passes on the decoy; the violation is caught only if a query
>    hits the tamper point (~0.6, grindable). My self-test only folded the COUPLED tampered `TLEAF`, so it never
>    modeled this — false assurance. **Fix:** make the trace-FRI layer 0 BE the `TROOT`-committed trace (single
>    commitment, no decoupled column), bound globally not just at queries.
> 2. **Adaptive-CP (deeper, pre-existing):** the queries derive from `keccak(final TFROOT)` ALONE — they do NOT bind
>    the CP roots `ROOT[*]`. A prover commits a genuinely degree-<N violating trace, computes the queries offline, then
>    interpolates a degree-<N CP satisfying line-755 at exactly those ≤16 points (`zh≠0` off-H lets CP solve for any
>    combine) → bad set = 1 point, grindable to ~1. Defeats the claimed ~2⁻¹⁶ AND the production ~2⁻⁸⁶. **Fix:** derive
>    the query challenge from a RUNNING TRANSCRIPT absorbing every root in commit order (`TROOT`, `ROOT[*]`, `TFROOT[*]`)
>    so the CP commitment is bound before the queries; chain the fold challenges off the transcript too.
>
> ---
> *(original first-fix note, now known insufficient:)* `trace_fri_commit()` adds a FRI low-degree test directly on
> the committed trace LDE (lifted to GF(p⁴); layer 0 tied to `TROOT` by a per-query consistency open); `verify()`
> checks its final-constant + fold-consistency. The executable attack (`build_attack`/`zk_trace_attack_k`) now finds
> NO accepting `kk` (was rc=6 ACCEPT → now rc=99), and the gadget's own (S)/(S2) checks confirm the attack is
> rejected **specifically by the trace LDT** (code ≥20, load-bearing — not a dead check). Honest accepts; V/O/R still
> reject.
>
> **SCOPE CORRECTION (verified 2026-06-24 — the gap is gadget-SPECIFIC, not systemwide):** the decoupling attack
> requires a verifier that reads a STORED, separately-openable trace decoupled from the CP. That is true ONLY of this
> gadget (`zk_ext4_stark_committed`): it stores `TLEAF`, `open_trace` opens it, and `combine` is recomputed from the
> opened value — so a malicious prover stores a high-degree `TLEAF` ≠ the honest CP's LDE. **`zk_fused_committed` (the
> ~2⁻⁸⁶ full-fused) is NOT vulnerable:** its `verify()` computes the constraint via `air_combine_ext4_at` over the
> **LIVE air LDE** (`air_lde_at`, which `air_build_lde` constructs as degree-<N by interpolation), and `open_col`
> binds `air_lde_at` to the per-column commitments — the committed trace is inherently low-degree, so no high-degree
> decoupled trace can be opened. (Trade-off: reading the live air state makes it less "witness-free" than the gadget's
> stored-commitment design — a separate, lesser concern, not a soundness hole.) **`zk_air::air_stark_verify`** has a
> DIFFERENT, already-documented gap (`DOCS/III-ZK-SOUNDNESS-GAP.md`): its CP FRI folds to 1 (vacuous "degree < d")
> and `air_build_cp` puts CP=0 on the trace domain (non-coset LDE) — the fix there is the **coset LDE** (substantial,
> tracked), which subsumes any trace-degree concern. So this gadget's trace-LDT fix is COMPLETE for the gadget; no
> blanket carry is owed. (The `~2⁻⁸⁶` figure is the full-fused at 128 queries; this N=16/16-query gadget is ~2⁻¹⁶.)

**Found:** 2026-06-24, by an adversarial soundness-audit Workflow (5 surfaces, each finding independently
re-checked by a second refuter; the polynomial identity in the attack advisor-reconfirmed). **Severity:
CRITICAL** — a malicious prover can produce an ACCEPTING proof for a FALSE statement, bypassing the
claimed ~2⁻⁸⁶ production soundness.

## The gap

`STDLIB/sovir/zk_ext4_stark_committed.iii::verify()` (and the shared `STDLIB/iii/numera/zk_air.iii::
air_stark_verify`) bind the execution TRACE column to the proof by a **Merkle root only** (`TROOT`,
`merkle_compute_root` at build:157; `open_trace` Merkle-opens it at 119-126/217-221). Merkle binds
**values, not degree.** FRI (`foldp4`) runs **exclusively on the CP layers** (`FA`/`FB`, the composition
polynomial — build:168-189, verify:234-252). **No FRI low-degree test, and no DEEP out-of-domain
quotient, ever touches the trace.** The sole tie between the committed trace and the constraint is the
**pointwise** line-755 identity `zh·CP == fac·combine` (verify:230-233), checked at 16 FS-random points.

## The attack (high-degree trace, honest CP — they are committed separately)

Because the trace and the CP are committed under *different* roots (`TROOT` vs `ROOT[0]`) and nothing
forces the trace to be the LDE whose quotient is the CP:

1. Commit `TLEAF` = the honest degree-<16 LDE `P_h` at the 48 non-H points (indices `q%4!=0`), but a
   tampered, genuinely **degree-63** trace at the 16 H points (`0,4,…,60`): rows 0-4 honest, row5 :=
   row4²+1 (the violation of `next=cur²` at row 4), rows 6..15 re-squared forward (only row 4 breaks).
2. Commit `CP := alpha·Q_h` where `Q_h` is the **honest** base-field quotient codeword (genuinely
   degree<16) and `alpha` is the FS challenge from `TROOT`. **FRI ACCEPTS CP** — it is genuinely
   low-degree (folding 64→32→16→8→4 yields a constant final layer; verify:208-210).
3. At any trace point `q0=4r`: `zh = OM[(N·q0)&63]-1 = OM[0]-1 = 0`, so line-755 degenerates to the
   **direct per-row check** `combine == 0`, i.e. `f[r+1]-f[r]² == 0` (alpha cancels). The tampered trace
   satisfies this at every row **except r=4** (query index `q0=16`). At the 48 non-H points `zh≠0` and the
   honest identity `zh·CP==fac·combine` holds (CP=alpha·Q_h, trace untouched there). So **|bad set| = 1
   of 64**.
4. Accept probability = `(63/64)^16 ≈ 0.78` single-shot; grinding the violation magnitude (`TF[5]+=k` →
   different `TROOT`/`alpha`/query-set) amplifies to ≈1 in 1-2 attempts.

The verifier returns 1 (ACCEPT) for a committed trace that violates the transition constraint. The
`~2⁻⁸⁶`/`~2⁻⁸¹` numbers silently presume a low-degree trace the protocol never enforces, so the asserted
bound is **false** — a genuine soundness gap, NOT an honest probabilistic cap.

`zk_air.iii::air_stark_verify` shares the gap and is *more* cleanly broken: `air_derive_queries` (719)
SKIPS trace points (`q%B==0`), so an H-confined tamper is never even sampled → accept ≈ 1.

## The fix (bind the trace to low degree)

Per the audit's `fix_hint` (auditor + refuter + advisor concur): run a **FRI low-degree test on the
trace LDE** (degree < N=16), OR fold the trace into the FRI'd composition via DEEP quotients
`(f(x)-f(z))/(x-z)` at an out-of-domain `z`. **Sufficiency:** with `deg(trace) < 16`, `G = zh·CP -
fac·combine` has degree < 32, so vanishing at 16 of 64 random points forces `G≡0`, hence the constraint
on every trace row. `Z_H`/`Z_T` and the boundary factor are already CORRECT — no change there.

**Plan:** (1) add a malicious-prover NEGATIVE test that commits the high-degree decoupled trace + honest
CP — currently ACCEPTS (proves the hole); (2) add a trace FRI-LDT (lift the base-field trace LDE to
GF(p⁴), fold+commit its layers, verify final-constant + fold-consistency per query); (3) prove the
honest case still ACCEPTS and the attack now REJECTS; (4) carry the same fix into `zk_air.iii`.

## Clean surfaces (audited, no hole)

- **Merkle binding** — deterministically sound (recompute-and-compare, index-bit sides, 0x00/0x01 domain
  separation; `merkle.iii:341-348/325-326/66-67`). Residual: a header succinctness claim ("never reads a
  whole layer") is overstated (it re-serializes every queried layer) — more conservative, not a gap.
- **GF(p⁴) field arithmetic** — `p=998244353` prime, `g=2+u` a verified quadratic non-residue (Legendre
  `g^((p²-1)/2)=-1`), so `v²-g` irreducible and GF(p⁴) is a genuine field (no zero-divisors); mul/inv/reduce
  match the derived formulas; inv(0)=0 → reject. BLS12-381 `p` = canonical prime.
- **Grand-product permutation** — `air_stark_verify` re-derives the permutation challenge from the
  committed access-column roots; the k challenges come from disjoint digest windows; `zk_perm_malicious`
  is a genuine cheating prover that is correctly REJECTED (exit 99).
