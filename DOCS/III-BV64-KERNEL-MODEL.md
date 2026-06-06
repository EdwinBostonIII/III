# III — BV64: the CIC Kernel's Native 64-Bit Machine-Int (Bitvector) Model

**Built 2026-06-06, solo / in-session / unrigged — III's own pinned `iiis-2` toolchain + its own
CIC kernel as the sole arbiter throughout. The trusted-base drift gate caught the change and was
explicitly resealed; the golden compiler (`iiis-0..3`) is UNMOVED.**

## The named horizon, closed

`DOCS/III-SOVEREIGN-OPTIMIZER-LEDGER.md` named exactly one remaining frontier:

> *"certifying the full k=1..63 hardware fact `x<<k == x*2^k (mod 2^64)` in the kernel itself needs a
> 64-bit machine-int (bitvector) model in CIC — a real proof-engineering effort, not a tweak … the
> deeper kernel proof of the mod-2^64 identity is the named horizon."*

This is that model. The CIC kernel (`numera/typecheck.iii` + its CCL reducer `numera/ccl.iii`) now
**VERIFIES 64-bit machine arithmetic BY IOTA** — the same move `REACH(h)` made for hexad-reachability
(`TRUSTED-BASE-SEAL.md`), at scale. Before, the optimizer's width facts were proven over **unbounded
Peano `Nat`** (`x<<k = x` doubled `k` times `== x*2^k` as *ideal integers*), a deep k-induction tower
(the reason `TC_CAP` was raised to 131072) that **never modelled wraparound**; the mod-2^width
truncation was waved through "by congruence." Now `x<<k == x*2^k (mod 2^64)` is the **true,
width-sensitive machine fact**, proven by a single iota step with a bare `refl` certificate.

## What the kernel now proves (all by its own conversion / `tc_check` — no oracle)

- **Closed constant folding, mod 2^64**: `bvadd/bvsub/bvmul/bvand/bvor/bvxor(lit,lit)` fold by NATIVE
  u64 wraparound. `MAX+1 == 0`, `2^32 * 2^32 == 0 (mod 2^64)`.
- **The width identity** `x<<k == x*2^k (mod 2^64)` for a **SYMBOLIC** `x`, by ONE iota — verified at
  `k ∈ {1,5,31,63}` and as a kernel-checked **theorem** `⊢ (λx:BV. refl(x<<1)) : Π(x:BV). Id(BV, x<<1, x*2)`.
- **The x86-64 count mask**: `x<<64 == x` (`64 & 63 = 0`), `x<<65 == x<<1`.
- **Overflow-checked folding**: `bvaddovf/bvmulovf(lit,lit)` reduce to `true`/`false` by iota
  (carry-out of bit 63; full-product `> 2^64`).
- **The multi-class collapse** `(x*1)+(x*0) == x` (7 nodes → 1) via the monoid/semiring identities.
- **Soundness negatives (must REJECT)**: distinct literals are non-convertible (`bvlit 2 ≠ bvlit 3`);
  the off-by-one shift is refused (`x<<1 ⊬ x*4`); `x ≠ x+1`.

KAT: `STDLIB/corpus/1213_bv_kernel.iii` → `tc_bv_kat()` (32 vectors incl. the negatives) = **99**, bite-proven.

## Design — the minimal trusted surface (the de Bruijn criterion preserved)

The model is added as **flat CCL primitive morphisms** (the `REACH`/`LEK` pattern), NOT the point-free
App/Comp spine. The trusted reducer surface (in `ccl.iii`, inside the sealed base) is deliberately tiny:

| Trusted addition (`ccl.iii`) | What |
|---|---|
| kinds 29–38 | `CCL_BVLIT` (a u64 value as `A=lo32,B=hi32`) + `BVADD/BVSUB/BVMUL/BVAND/BVOR/BVXOR/BVSHL` + `BVADDOVF/BVMULOVF` |
| `ccl_bv_fold(op,a,b)` | closed-literal NATIVE mod-2^64 evaluation + the Z/2^64 **monoid/semiring identity collapses** (the absorbing/identity elements: `+0, *1, *0, &0, &~0, \|0, \|~0, ^0`) + the single definitional rule `x<<k == x*2^(k&63)` |
| `ccl_step` BV arm | reduce operands leftmost-outermost, then fire one rule; a literal is its own normal form |
| `ccl_struct_eq` BV cases | **soundness-critical**: a `BVLIT` is equal only when its 64-bit value matches (else two distinct literals hit the equal-tag fallthrough → false equalities); op nodes recurse |
| `ccl_to_tc` BV cases | read-back of a BV normal form (a literal, or a neutral op-tree like `bvmul(x, lit)`) |
| `tc_to_ccl` BV cases | the type → atom 2055; each op → its flat CCL primitive (the seal-moving half, in `typecheck.iii`) |

**Why this is the right boundary (advisor-confirmed).** A neutral operand (a free variable `x`) never
matches a literal guard, so `x` stays neutral and **no polynomial over `x` is ever canonicalised in the
trusted base**. `x<<k` and `x*2^k` both normalise to `bvmul(x, lit 2^k)` and structural compare proves
them equal — without importing a multivariate-polynomial engine into the kernel. The full **symbolic
ring DECISION** stays in the **UNTRUSTED proposer** `numera/bv_ring` (PROPOSE/DISPOSE, the split the
system already runs on). Every trusted rule is a one-line textbook identity of the ring Z/2^64.

The non-trusted half (typing, constructors, KAT, optimizer wiring) lives outside `tc_to_ccl` and does
not move the seal — `TC_BV*` tags, `tc_bv*` constructors, `tc_infer` BV typing (`BV:U0`; ops `:BV→BV→BV`;
overflow preds `:BV→BV→Bool`), and the `tc_bv_kat`.

## The optimizer shift (the unary path subsumed for width facts)

`numera/sov_isa.iii`'s constant-shift fold certification now **routes through BV**: `sov_shift_fold_term/
goal` are BV-native (`Π(x:BV). Id(BV, x<<1, x*2)`, certificate = bare `refl`), and `sov_shift_fold_witness`
proves the codegen-relevant family `k ∈ {1,5,31,63}` + the count mask + overflow folding + the off-by-one
negative — every fact a tiny refl proof, **no Peano tower**. The old proof's "mod-2^width closed by
congruence" step was *valid* for the ideal-integer equality (equal values stay equal under truncation),
but it never modelled the x86-64 count mask (`k&63`) and gave no width-native overflow flag; the BV proof
captures both **directly**. `sov_feed_commons` admits this width-native `thm:shift_fold` into the Theorem
Commons (kernel re-verified at admit). The inductive symbolic-`k` strength SCHEMA (`sov_sr_term`,
ideal-integer) remains as a separate, complementary capability (its congruence argument is sound, not a
handwave — it simply does not model fixed-width truncation/masking, which BV now does); `TC_CAP` stays
131072 for it.

## Trusted-base reseal (precedented; golden unmoved)

The drift gate (`COMPILER/BOOT/trusted_base_check.sh`) reddened the build until reseal — working exactly
as designed. `TRUSTED_BASE_ROOT`: `5996d3de… → 4d5bb214…` (logged in `TRUSTED-BASE-SEAL.md`). `ccl.iii`
and `typecheck.iii` are stdlib, NOT in the `iiis-2` bootstrap link closure (`build_iiis2.sh` references
them zero times), so this is a STANDALONE trusted-base reseal — **not** a golden `iiis-0..3` re-root.
The change is additive: BV tags ≥29 never collide with the 1..28 fragment, so every pre-existing node's
behaviour is byte-identical. The self-host fixpoint (`iiis-2 == iiis-3` byte-identical) is therefore
unaffected **by construction** — it was not re-run because the bootstrap inputs are provably unchanged;
re-running `build_iiis2 --check-corpus` would reproduce the existing golden bit-for-bit.

## Verification (III alone, unrigged)

- `trusted_base_check.sh --check` = OK at `4d5bb214…`.
- `build_stdlib.sh` = **PASS=478, FAIL=0** (the lib carries the BV model).
- `run_corpus.sh` = **PASS=815, FAIL=0, SKIP=100, zero WRONG** — the full conformance corpus, no
  regression. `1213_bv_kernel`=99; the BV-routed `1207_shift_fold_certified`=99; the whole proof tower +
  Sovereign-Optimizer + `bv_ring` + commons (1204–1213) green. `run_xii_corpus.sh` = **92/0**.
- **Randomized differential soundness gate** `1214_bv_kernel_differential` = **99**, beyond the hand-picked
  vectors. (A) — the STRONG half — 600 random all-literal trees over `{+,-,*,&,|,^,<<}`: the kernel CONFIRMS
  the native-`u64` value AND REJECTS the off-by-one `v^1` in every case (definitive vs the Z/2^64 ground
  truth; exercises every fold / wrap / overflow / `struct_eq` path). (B) — a LIGHTER cross-check — 600 random
  symbolic tree pairs assert `tc_conv==1 ⟹ bv_equal==1` against the sound `bv_ring` decider; honestly, the
  kernel's syntactic conv equates almost only reflexive `a vs a` pairs, so this half is mostly non-vacuous on
  trivial pairs — the real symbolic-soundness weight is carried by the closed half (A) and the adversarial
  audit below, not by part (B).
- **`1210_commons_feed`=99** — the lone pre-existing baseline `WRONG` is now solidly green. (Root cause:
  a OneDrive mid-sync rewrite of `libiii_native.a` during the baseline run — the byte-identical `.o` links
  to a passing binary against the stable lib; the proof logic was always sound. The BV-native fold also
  replaces the fragile 100k-node Peano tower with a tiny robust refl proof, hardening it further.)
- Independence baseline (pre-change, III alone): self-builds its entire stdlib (478/0); trusted base
  sealed; full conformance corpus green.
- **Adversarial soundness audit** (`bv64-soundness-audit` workflow, 17 agents): one empirical skeptic per
  iota rule, each BUILDING + RUNNING a probe that tries to make the kernel accept a FALSE equality —
  **14/14 rules SOUND**, the reducer **terminates + is confluent**, no false equality reachable.
- **A real bug the audit caught + fixed (the audit earning its keep):** the BV tags (29–38) are numerically
  `>= CCL_ATOM`, so a BV **operation** node (e.g. `bvadd(Snd, lit)`, which references the bound variable)
  was wrongly treated as a closed weakening-invariant constant by `ccl_strengthen` and the `ccl_step` COMP
  weakening — so a BV op under a SUBSTITUTED binder dropped the substitution (latent unsoundness, unexercised
  by the literal/flat KAT + differential). FIX: both sites now distribute/strengthen STRUCTURALLY into the
  BV operands (BVLIT stays a closed value). KAT `1213` gained cases 33–36 (a BV op under a β-reduced binder:
  `(λy.y+5) 3 == 8`, `(λy.y+y) 3 == 6`, `(λy.y<<1) 4 == 8`, and the negative `(λy.y+5) 3 != 9`) — RED before,
  GREEN after. Trusted base re-sealed `4d5bb214… → f079dd81…` (see `TRUSTED-BASE-SEAL.md`); the full KAT +
  differential + corpus re-verified GREEN. This is the PROPOSE/DISPOSE discipline applied to the kernel's
  own development: an adversarial fleet proposed a break, the kernel's tests disposed of it, the trusted
  base shrank its bug surface.
- `tc_rigid_head` gained `TC_BV`/`TC_BVLIT` (sound fast-reject completeness; outside the sealed region).

## Compositional follow-on — `forcefield/bv_dispose`: the width-faithful two-tier optimizer disposer

The BV model + the existing sound decider `numera/bv_ring` compose into a capability neither has alone — a
runtime **two-tier disposal gate** for autonomous machine-arithmetic optimization (`STDLIB/iii/forcefield/
bv_dispose.iii`, KAT `1216_bv_dispose=99`):

- **Tier 1 — `bv_ring` (untrusted, SOUND) cheaply REFUTES.** A candidate rewrite `lhs == rhs` over Z/2^64
  whose two sides are not equal as canonical polynomials is DEFINITELY meaning-changing → rejected with no
  kernel arena spent. `bv_ring` is sound (it only ever declines a valid rewrite, never blesses an invalid
  one), so its veto is always trustworthy.
- **Tier 2 — the BV64 CIC kernel (trusted) width-faithfully DISPOSES.** Only a Tier-1 survivor is converted
  by the kernel's native BV iota (mod-2^64, x86 count-mask) — the SOLE arbiter of admission.

This extends the autonomous optimizer's sieve (`forcefield/cg_autocatalyst`) from the ideal-integer Peano
strength domain into the TRUE machine-word ring. The KAT proves it admits the width family (`x<<k==x*2^k`)
+ the multi-class collapse, rejects the meaning-changing rewrites, and — elegantly — that the kernel is
SOVEREIGN: `x-x==0` is `bv_ring`-decidable, yet the kernel's syntactic conv does not fold a symbolic
`x-x`, so the disposer correctly DECLINES it (`bv_ring` may propose more than the kernel certifies, never
less). A sound external decider proposing and a width-native proof kernel disposing, as one gate, is
uniquely-III.
