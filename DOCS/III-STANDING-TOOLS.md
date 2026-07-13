# III — THE STANDING TOOLS: capabilities you can actually run

> A capability that can only be exercised by hand-writing a driver, a gate, and a build script for each
> input is not a capability — it is a demo with good manners. This document lists the tools III ships as
> **committed binaries that take real input and do the real thing**: no glue to write, no curated vectors,
> no operator in the loop. Each one is verified below on input it has never seen.

---

## `iii-prove` — prove two functions equal over ALL 2⁶⁴ inputs

```
iii-prove <a.iii> <fnA> <b.iii> <fnB>     prove fnA == fnB for EVERY input
iii-prove --list <file.iii>               list a file's provable functions
```

Build: `bash COMPILER/BOOT/build_iii_prove.sh` → `COMPILED/iii-prove`.
Source: `COMPILER/BOOT/prove_main.iii`.

This is III's disposer (`numera/ser_kinduct_sym::seq_equiv`, over `numera/bv_bits` → `numera/sat`) made
independently useful. Hand it **your** two source files and two function names. It links the compiler's own
front end (lex/ast/parse) and its own SVIR backend (`cg_svir`) *in-process* — no shelling out, no temp files,
no harness — lowers both functions, mitres their denotations, and decides:

| exit | verdict | meaning |
|---|---|---|
| 0 | **PROVEN** | equal for every input — a bit-blast UNSAT over the whole 2⁶⁴ space of each parameter. Not sampled. |
| 1 | **REFUTED** | they differ — and the **concrete counterexample is printed** |
| 2 | **UNDECIDED** | a body left the decided fragment, and the tool **says which and why** |
| 3–8 | usage / read / parse / emission / no-such-function / arity-mismatch |

**It never reports PROVEN unless it proved it.** Everything else — refutation, out-of-fragment, capacity,
solver poison — maps to REFUTED or UNDECIDED.

### The decided fragment
Straight-line ALU over parameters and constants; **constant** shift counts; structured `if/else`;
**early returns under any nesting** (path-conditioned, with totality *checked*); counter loops with constant
stride; constant-address byte memory; `DIV_U`/`REM_U` **by a constant power of two** (exactly a shift/mask).
Outside it, by design: variable shift counts, general division, calls, symbolic addresses. The general
64-bit divider bit-blasts into the multiplier wall this engine deliberately amputates — so it **abstains**
rather than approximate.

### Verified on code it had never seen
Two files of ordinary optimizations — the kind you would not merge without a proof (`STDLIB/build/mathesis/userA.iii`,
`userB.iii`):

| pair | verdict | why it is right |
|---|---|---|
| `swap32` | **PROVEN** | `(x>>32)\|(x<<32)` ≡ `(x<<32)\|(x>>32)` — OR commutes |
| `is_pow2` | **PROVEN** | `x&(x-1)==0` ≡ `x&(-x)==x` for x≠0 — a real theorem, not a coincidence |
| `pick` | **PROVEN** | the branchless mask-select really does equal the branchy one |
| `align8` | **PROVEN** | `((x+7)/8)*8` ≡ `(x+7) & ~7` — the alignment idiom, decided |
| `absdiff` | **REFUTED** | counterexample `a=0xFFFF…F, b=0x3FFF…F`: the "clever" version uses the **signed** sign-mask, giving `0x4000…0` where the unsigned original gives `0xC000…0`. **A real bug in a real optimization.** |
| `avg` | **REFUTED** | counterexample `a=b=0xFFFF…F`: the famous overflow-safe average is genuinely **not** `(a+b)/2` under wraparound — `0xFFFF…F` vs `0x7FFF…F` |

Every verdict is checkable by hand. Nothing here was curated for the tool.

### The soundness bug this tool found — and forced shut
Pointing the prover at ordinary user code immediately exposed a **false PROVEN** in the disposer itself.

The compiler lowers `if c { return b }  return a` to
`[LGET c][CONST 0][NE][IF][LGET b][RET][END][LGET a][RET]` — a `RET` **inside** an if-frame, with no `ELSE`.
`sd_denote`'s `RET` handler returned the top of stack **immediately**, so it denoted that entire body as
**`b` alone**: the condition and the `return a` path simply vanished. Consequences:

```
f(c) = if c { return 1 }  return 2
g(c) = if c { return 1 }  return 3
```
Both collapsed to the constant `1`, so `seq_equiv` called them **EQUAL**. They are not — at `c = 0` one is 2
and the other is 3. A false PROVEN is the one unrecoverable outcome the whole engine exists to prevent.

The corpus never hit it because every gate hand-writes SVIR bodies with a single trailing `RET`. **Only
pointing the capability at real code found it.** That is the entire argument for standing tools.

**Fixed** (`ser_kinduct_sym.iii`) by a path-condition accumulator: a `RET v` fires exactly where
`fire = PC & ¬RETSET`, contributing `RETV := mux(fire, v, RETV)`, `RETSET := RETSET ∨ fire`; after
`if c { … RET } END` the path condition becomes `PC ∧ ¬c`; and at end-of-body **totality is checked, not
assumed** — if `RETSET` is not provably 1, the body is refused rather than given an invented value.
The unconditional fast path is preserved node-for-node, so every straight-line and if/else-value body
(all 18 sealed mathesis theorems, every 2601/2613/2674/2675/2677/2678/2679 gate) denotes to the **identical**
circuit and keeps its exact verdict — verified: **27/27 mathesis gates green** after the fix.

Pinned forever by `corpus/2614_disposer_early_return`, which **reproduces the false PROVEN first**
(RED = 10) and only then proves the fix — so the bug can never return silently.

---

## `iii-crypto` — the post-quantum stack pointed at your files

```
iii-crypto keygen <level> <seed32> <pk> <sk>        ML-DSA (FIPS 204) keypair, deterministic in the seed
iii-crypto sign   <level> <sk> <file> <sig>         sign ANY file
iii-crypto verify <level> <pk> <file> <sig>         exit 0 = VALID, 4 = INVALID
iii-crypto seal   <key32> <nonce12> <file> <out>    ChaCha20-Poly1305 AEAD
iii-crypto open   <key32> <nonce12> <sealed> <out>  exit 0 = AUTHENTIC, 4 = FORGED (no plaintext written)
iii-crypto hash   <file>                            SHA-256
iii-crypto kem-keygen <set> <seed64> <ek> <dk>      ML-KEM (FIPS 203); set = 512 | 768 | 1024
iii-crypto kem-encaps <set> <ek> <coins32> <ct> <ss>   exit 4 = non-canonical ek REJECTED (sec 7.2)
iii-crypto kem-decaps <set> <dk> <ct> <ss>          FO implicit rejection: tampered ct DIVERGES the ss
iii-crypto slh-keygen <sset> <seed3n> <pk> <sk>     SLH-DSA (FIPS 205), both strict hash families
iii-crypto slh-sign   <sset> <sk> <file> <sig>      sset = shake-128s|192s|256s | sha2-128s|192s|256s
iii-crypto slh-verify <sset> <pk> <file> <sig>      exit 0 = VALID, 4 = INVALID
iii-crypto ed-keygen  <seed32> <pk>                 Ed25519 (RFC 8032); the seed IS the private key
iii-crypto ed-sign    <seed32> <file> <sig>         deterministic 64-byte signature
iii-crypto ed-verify  <pk> <file> <sig>             exit 0 = VALID, 4 = INVALID
iii-crypto siv-seal   <key32> <file> <out> [ad]     AES-SIV (RFC 5297): DETERMINISTIC, no nonce to misuse
iii-crypto siv-open   <key32> <sealed> <out> [ad]   exit 0 = AUTHENTIC, 4 = FORGED (AD authenticated too)
```

Build: `bash COMPILER/BOOT/build_iii_crypto.sh` → `COMPILED/iii-crypto`.
Source: `STDLIB/iii/aether/crypto_cli.iii`. `<level>` is the FIPS 204 security category `2 | 3 | 5`
(= ML-DSA-44 / -65 / -87).

The sovereign FIPS/ACVP-conformant stack (KAT-gated in the corpus) pointed at arbitrary files. Verified on
fresh input — a message and random seeds minutes old, at level 2:

| arm | observed |
|---|---|
| `keygen` | pk 1312 B, sk 2560 B — the FIPS 204 ML-DSA-44 sizes — deterministic in the seed |
| `sign` → `verify` | 2420-byte signature (the ML-DSA-44 size); `VALID`, exit 0 |
| ONE signature byte flipped (proven by `cmp`) | `INVALID`, exit 4 |
| verify under a different public key | `INVALID`, exit 4 |
| ONE message byte changed | `INVALID`, exit 4 |
| `seal` → `open` | `AUTHENTIC`, exit 0 — opened bytes identical to the input |
| ONE sealed byte flipped (proven by `cmp`) | `INVALID: authentication FAILED … (no plaintext was written)`, exit 4 — and the output file is not created |
| `hash` | agrees byte-for-byte with `sovhash`, GNU `sha256sum`, and Microsoft `certutil` on the same file |

A verifier that can only say yes is not a verifier: every reject arm above is a measured exit 4.

### The full-stack verbs, verified on fresh input (keys/seeds minutes old)

| arm | observed |
|---|---|
| ML-KEM 512/768/1024 roundtrip | ek 800/1184/1568 B, dk 1632/2400/3168 B, ct 768/1088/1568 B — the FIPS 203 sizes; encaps↔decaps shared secrets byte-identical (`cmp`), keygen deterministic in the seed |
| ONE ct byte flipped (proven by `cmp`) | decaps exits 0 but the secret silently DIVERGES — the Fujisaki-Okamoto implicit rejection, proven by comparing ss files |
| wrong dk | secret diverges |
| non-canonical ek (coefficient ≥ q) | encaps `INVALID … sec 7.2 modulus check`, exit 4 |
| SLH-DSA shake-128s + sha2-128s | keygen (pk 2n / sk 4n, deterministic) → 7856-byte signature → `VALID` exit 0; sizes 48/96 (192s) and 64/128 (256s) exact |
| SLH tampered sig / wrong pk | `INVALID`, exit 4 |
| SLH cross-family | a SHAKE-family signature does NOT verify under SHA2 — the two strict FIPS 205 families are disjoint through this tool, measured |
| Ed25519 sign → verify | 64-byte deterministic signature, `VALID` exit 0; same seed+message → identical signature (`cmp`) |
| Ed25519 tampered sig / wrong key / tampered message | `INVALID`, exit 4 — all three |
| AES-SIV seal → open | roundtrip byte-identical; same key+plaintext+AD → IDENTICAL sealed bytes (`cmp`) — RFC 5297's determinism, the property that makes nonce misuse impossible |
| AES-SIV one byte flipped / wrong AD / missing AD | `INVALID … no plaintext was written`, exit 4 — the AD is authenticated |

---

## `iii-exact` — the exact sign of Σ aᵢ√bᵢ, on your own terms

```
iii-exact "<a1> <b1> <a2> <b2> ..."      sign(a1*sqrt(b1) + a2*sqrt(b2) + ...), decided EXACTLY
iii-exact --cmp "<terms A>" "<terms B>"  decide whether (sum A) <, =, or > (sum B), EXACTLY
iii-exact --denest <a> <b> <d>           is a + b*sqrt(d) a PERFECT SQUARE in Q(sqrt(d))?
iii-exact --roots "<c0 c1 ... cd>" [lo hi]   isolate ALL real roots of c0+c1*x+...+cd*x^d into
                                         disjoint rational intervals, each with its exact
                                         MULTIPLICITY -- every printed claim bigint-recertified
iii-exact --alg-sign "<c0 ... cd>" <lo> <hi>  exact sign of THE root isolated in (lo, hi] -- AT THE
                                         ENGINE'S FULL CLASS (deg <= 960, ~4930-digit coefficients)
iii-exact --alg-cmp "<A>" <lo> <hi> "<B>" <lo> <hi>   TOTAL ORDER with DECIDABLE EQUALITY of two
                                         real algebraic numbers (the zero problem, decided by the
                                         PAIR-GCD door) -- same full class
iii-exact --alg-add "<A>" <lo> <hi> "<B>" <lo> <hi>   THE ARITHMETIC CLOSURE: construct gamma =
iii-exact --alg-mul "<A>" <lo> <hi> "<B>" <lo> <hi>   alpha+beta / alpha*beta as (an integer defining
                                         polynomial, a certified isolating window) -- roots are
                                         closed under + and * ON THIS SURFACE (deg <= 384 each,
                                         degA*degB <= 768, EITHER sign)
iii-exact --alg-inv "<A>" <lo> <hi>      THE FIELD COMPLETION: 1/alpha (exact reversal + certified
                                         window, either sign) -- with add/mul this closes
                                         +, *, and inverse, hence division
iii-exact --roots-big "<c0 .. cd>" <lo> <hi>   isolation PAST the i64 chain wall: degree <= 960,
                                         coefficients to ~4930 digits (256 limbs)
```

Build: `bash COMPILER/BOOT/build_iii_exact.sh` → `COMPILED/iii-exact`.
Source: `STDLIB/iii/aether/exact_cli.iii` (composes `aether/sqrt_sum_sign` + `aether/kfield` +
`aether/exact_denest` + `aether/sturm` + `aether/sturm_big` + `aether/algnum` over the bigint
arena). Sign modes print `-1 / 0 / +1`; exit `1` = NEGATIVE, `0` = EXACTLY ZERO, `2` = POSITIVE,
`3` = usage/parse error. `--denest` exits `0` = perfect square (root printed), `4` = genuine
extension, `5` = out-of-envelope abstain, `6` = internal refuse (the tool re-squares the root
IN-PROCESS and will not print one it did not re-verify).
No floating point anywhere in any decision.

`--roots` is two-engine by construction: the i64 Sturm chain (`aether/sturm`) PROPOSES isolating
intervals by dyadic bisection; the INDEPENDENT bigint chain (`aether/sturm_big` — limb-pool
coefficients, structurally incapable of coefficient overflow) then re-certifies **every** printed
claim in this process: the window's root count, each interval's exactly-one-root recount, and each
root's multiplicity (`root_mult2`). A disagreement is a measured exit 6 — nothing unverified
prints. Envelope (enforced; abstain outside): degree ≤ 7, |cᵢ| < 2²⁰, window endpoints |·| ≤ 2²⁰
(default window = the Cauchy bound, which strictly contains all real roots), proposal depth 24.
Exits: `0` certified | `3` parse | `5` ABSTAIN | `6` internal refuse.

`--alg-sign` / `--alg-cmp` are the ORDER STRUCTURE at the engine's FULL class (degree ≤ 960,
decimal coefficients to ~4930 digits — the same input class as `--roots-big`): an algebraic number
is (an integer polynomial, the interval (lo, hi] isolating exactly one of its real roots,
`root_count2`-certified at load). SIGN is decided by two exact faculties that must agree — COUNTING
(ONE `root_count2` against the rational 0, no refinement: `an_sign_vs_rat`'s law lifted past i64;
the exact-zero case c₀ = 0 ∧ 0 ∈ (lo,hi] is pure arithmetic) and dyadic REFINEMENT through the
same overflow-free chain.  EQUALITY (the zero problem) is decided by the `sturm_big` PAIR-GCD door
(gate 2186's G arm): the content-reduced pseudo-remainder chain seeded with (A, B) instead of
(p, p′) — gcd(A,B) has a root in the window overlap **iff** α = β; never an epsilon.  ORDER by
shared-depth dyadic refinement with distinctness ALREADY PROVEN, and NO DEPTH CAP: i64 numerators
to depth 40, then THE DEEP TIER — signed bigint window numerators in a migrating arena, counted
through `sturm_big`'s handle door (`root_count2_h`, gate 2185's self-verifying H arm) — descending
to any depth memory affords.  Termination is mathematical (the numbers are proven distinct before
refinement starts); a per-input Mignotte-style over-bound guards against defects only, and
resource exhaustion is a named abstention — physics, never a wrong sign.  `--alg-cmp` re-verifies
antisymmetry by
re-running the whole decision with the roles swapped; where the input fits the gate-2157 class
(degree ≤ 3, |cᵢ| < 2²⁰) the OLD algnum register file rides along as an independent faculty, and
where both numbers are principal square roots the Σ√ separation-bound oracle must agree (the 2157
UNIFY law, kept live).  Integer endpoints |·| ≤ 1024.
Exits: `--alg-sign` sign-mode 1/0/2; `--alg-cmp` `1` A<B | `0` EQUAL | `2` A>B (= sign(A−B));
both add `4` REFUSED (the interval does not isolate exactly one root) | `5` abstain | `6` a
cross-check failed.

`--alg-add` / `--alg-mul` / `--alg-inv` are the ARITHMETIC CLOSURE and FIELD COMPLETION
(`aether/resultant`, gates 2177/2179/2180/2186): the certified modular-CRT resultant engine (or,
for the inverse, the exact reversal `rs_inv`) CONSTRUCTS γ's integer defining polynomial over
**THE ADAPTIVE WINDOW of 512 SELF-GENERATED 30-bit primes** — generated at first use by
deterministic trial division, no table to transcribe wrong; the first 16 ARE the historical
hardcoded table (gate 2186's W arm pins them entry-for-entry AND re-verifies all 512 by the gate's
own independent trial division).  ADAPTIVE means each run uses EXACTLY the primes its own
certified bound demands — `ceil((bnd+2)/29)`, the same 29-bit-floor theorem the fixed window
rested on — so capacity is a CEILING, not a price: reconstruction below the used product's half
is unique, every output is byte-identical at any window at or above the bound, and the historical
464-bit sealed class literally re-runs its ORIGINAL 16-prime window (gate 2186's N arm pins the
used counts per arm: `N: 4 18 3 4 146`).  The certified `bnd` ceiling stands at 464 → 14848 bits —
plus the permanent norm bound, the mod-every-USED-prime consistency re-check, and the V-I.2
limb-row ABI (raw rows 256 limbs = 16384 bits, so EVERYTHING the bound certifies is deliverable —
gate 2186's R arm pins a 65-limb coefficient limb-for-limb against the gate's own independently
computed value) so coefficients beyond i64 are DELIVERED, not refused; the CLI then pins WHICH
root γ is by
refining the operands through the overflow-free bigint chain until R has exactly ONE root
(`root_count2`-certified) in γ's window — and when the i64 window formulas or the depth-20
refinement wall are outgrown, THE DEEP PINNING TIER takes over: operand windows become signed
bigint-handle pairs, γ's window is computed in handle arithmetic and counted through the handle
door (`root_count2_h`) for sum/product or the GENERAL-RATIONAL door (`root_count2_q`, gate 2185's
I arm) for the inverse's non-dyadic windows — pinning descends to any depth memory affords.
Inputs take degree ≤ 384 each with degA·degB ≤ 768 (the recovery geometry: 769 interpolation
nodes, stride-769 modular matrices), coefficients |cᵢ| < 2⁶⁰ through the overflow-guarded
19-digit parse (past-i64 digits are a parse refusal, never a silent wrap); the `bnd`
certification is PER RUN and refuses honestly inside that geometry whenever a coefficient bound
exceeds 14848 bits — validation AND refinement run entirely through the bigint chain, sound at
every depth, so the wider class is certified per run rather than inherited.  (The degree-48
widening surfaced and closed a LATENT overflow: the binomial accumulators built a falling
factorial before dividing — exact only below degree ~28; `rs_binom` now interleaves
multiply/divide so every prefix is itself a binomial coefficient, exact at any supported degree.
The D = 192 widening replaced the Cramer/Vandermonde residue recovery with per-prime LAGRANGE
interpolation — the interpolating polynomial mod p is unique, so every output stays
byte-identical, at O(n²) per prime instead of O(n⁴) — and exposed a second latent assumption: a
NEGATIVE coefficient's Garner walk tracks ~P itself at full width (~97 KB at 128 primes), which
exhausted the fixed CRT arenas that had survived 64 primes — found by gates 2473/2474, closed by
the per-coefficient-arena law everywhere.)
PRODUCT and INVERSE work at EITHER sign: a sign-definite refinement phase separates each operand
from 0 first; then the product uses [min,max] of the four endpoint products with the lower bound
widened one half-step, and the inverse uses the strict outer bracket of [2ᵏ/h, 2ᵏ/l) — the
half-open mirroring that made 1/α the frontier item, dissolved by widening instead of case-work.
Sqrt-shaped inputs get the Σ√ separation-bound oracle as an independent second faculty.  A zero
operand is detected exactly (`PRODUCT: exactly 0`; the inverse of zero is REFUSED).  The output
pair (R + window) is itself a legal `--roots`/`--roots-big` input — closure, literally.
Exits: `0` certified | `3` parse | `4` refused | `5` abstain | `6` a cross-check failed.

`--roots-big` carries isolation PAST the i64 chain wall (gate 2185: the i64 chain honestly
overflows at degree 12): degree ≤ 960 (the widened pool: 1024-coefficient rows, chain ≤ 1023 with
truncation a REFUSAL, never a silent wrong count), decimal coefficients to ~4930 digits parsed
exactly into limb rows (the archive bigint engine), counting/bisection/multiplicity all through
`sturm_big`'s pool-array chain, multiplicity through the raw-ABI door `root_mult2_cur` (gate
2186's M arm).  Sub-2⁻²⁴ clusters NO LONGER ABSTAIN: the i64 bisection records each one as a
SEED and THE DEEP SPLITTER descends through the handle door — window numerators become bigint
handles while the WIDTH numerator stays INVARIANT down one cluster's bisection tree (both
endpoints double together, so H = L + W at every depth); each deep root's multiplicity is
certified by `root_mult2_cur_h` (the deep multiplicity door, gate 2185's I arm), and deep
windows print as EXACT dyadic rationals, position-merged with the i64 windows at a common
depth under explicit exactness guards.  Termination is mathematical (distinct roots separate at
finite depth; a multiple root is ONE distinct root and keeps its multiplicity); the per-input
separation over-bound guards defects only.
Explicit window required, endpoints |·| ≤ 2⁴⁴; every doubling and rescale is pre-guarded so no
coordinate ever leaves exact i64 — out-of-guard is a measured abstention, never a rounded value.
Exits: `0` certified | `3` parse | `5` abstain (envelope / memory) | `6` refuse.

Verified on fresh input:

| input | verdict | why it is right |
|---|---|---|
| `"1 123456790 1 123456788 -2 123456789"` | `-1`, exit 1 | √(N+1)+√(N−1)−2√N < 0 by strict concavity; true value ≈ −1.8·10⁻¹³, ~20× below one ulp of the operands — **a double computes literally `0` for this sum (measured)** |
| `"2 123456789 -1 123456790 -1 123456788"` | `+1`, exit 2 | the mirror sum — the verdict flips with it |
| `"1 8 1 18 -1 50"` | `0`, exit 0 | 2√2 + 3√2 − 5√2: a TRUE zero, certified — not "smaller than a tolerance" |
| `--cmp "7 11" "1 539"` | `0`, exit 0 | 7√11 = √539 exactly (539 = 49·11) |
| `"1"` | exit 3 | odd term count → the parse error is named, never guessed around |
| `--denest 23 8 7` | exit 0 | `√(23 + 8√7) = 4 + 1·√7` — the root re-squared exactly in-process before the claim prints |
| `--denest 22 -12 2` | exit 0 | principal root `-2 + 3√2` (= 3√2 − 2): sign-normalized exactly, no floating point |
| `--denest 9 6 2` | exit 4 | THE norm trap: N = 9 = 3², yet 9+6√2 is NOT a square — the norm alone is never trusted |
| `--denest 100 2000000 2` | exit 5 | outside the proven i64 envelope (`\|a\|<2³⁰, \|b\|<2²⁰, 0<d<2²⁰`) → ABSTAIN |
| `"1x 2"` | exit 3 | trailing garbage in a number is an ERROR — measured fast, never a hang |
| `--roots "47 -70 25" 1 2` | exit 0 | THE float smoking gun: 25x²−70x+47 is POSITIVE at both ends of (1,2] (p(1)=2, p(2)=7) so every endpoint check finds nothing — the tool certifies **2** roots, `(1, 3/2]` and `(3/2, 2]` (= (7±√2)/5), each recounted through the bigint chain |
| `--roots "4 0 -3 1"` | exit 0 | (x−2)²(x+1): the root in `(0/2, 5]` has **multiplicity 2 — "TOUCHES the axis, no sign change (invisible to every sign-sampler)"**; the root in `(-5, 0/2]` (= −1) crosses; `with multiplicity: 3 of degree 3` |
| `--roots "-10 31 -25 6"` | exit 0 | non-monic (2x−1)(3x−5)(x−2): three one-root intervals bracketing 1/2, 5/3, 2 inside the derived Cauchy window (−7, 7] |
| `--roots "-1 1 0 0 1"` / `"1 1 0 0 1"` | exit 0 both | x⁴+x−1 → `2` real + `(2 non-real)`; x⁴+x+1 → `0` real — the degree-gap chain whose pseudo-remainder sign-correction is load-bearing (gate 2156's DEFECTIVE arm), certified through BOTH engines |
| `--roots "-6 11 -6 1" 1 3` | exit 0 | the half-open convention measured on (x−1)(x−2)(x−3) over (1,3]: root 1 EXCLUDED, root 3 INCLUDED → count 2 |
| `--roots "1 0 1"` | exit 0 | x²+1: `DISTINCT REAL ROOTS in (-2, 2]: 0 [bigint-certified] (all 2 roots non-real)` |
| `--roots "0 0 0"` / `--roots "1 2x 3"` | exit 3 | the zero polynomial refused by name; trailing garbage an error |
| `--roots "0 0 0 0 0 0 0 0 1"` / `--roots "1048576 1"` | exit 5 | degree 8 / a coefficient at 2²⁰: ABSTAIN — refused, not guessed |
| `--alg-cmp "-2 0 1" 1 2 "0 -2 0 1" 1 2` | **`EQUAL`, exit 0** | **THE ZERO PROBLEM, DECIDED: √2 as a root of x²−2 EQUALS √2 as a root of x³−2x — two different polynomials, one number, decided by gcd; a refine-to-epsilon impostor loops forever** |
| `--alg-cmp "-2 0 1" 1 2 "-3 0 0 1" 1 2` | `A < B`, exit 1 | √2 < ∛3 (≈1.4142 vs ≈1.4422, overlapping isolating intervals): coprime → distinct → dyadic refinement separates |
| `--alg-cmp "-2 0 1" 1 2 "-3 0 1" 1 2` | `A < B`, exit 1 | √2 < √3 with BOTH inputs sqrt-shaped: the Σ√ separation-bound oracle cross-checked the Sturm order in-process before printing |
| `--alg-cmp "-2 0 1" 1 2 "-99 70" 1 2` and reversed | exit 1 / exit 2 | √2 vs the tight rational 99/70 (70√2 = 98.9949…), both directions — antisymmetry measured |
| `--alg-cmp "1 0 -10 0 1" 3 4 "-2 0 21 0 -12 0 1" 3 4` | **`EQUAL`, exit 0** | **THE ZERO PROBLEM PAST DEGREE 3: √2+√3 as a root of x⁴−10x²+1 EQUALS √2+√3 as a root of the DEGREE-6 (x⁴−10x²+1)(x²−2) — decided by the sturm_big pair-gcd door (gcd = x⁴−10x²+1, one shared root in the overlap), never epsilon** |
| `--alg-cmp "1 0 -10 0 1" 3 4 "-10 0 1" 3 4` and reversed | exit 1 / exit 2 | √2+√3 < √10 ((√2+√3)² = 5+2√6 < 10): a degree-4-vs-degree-2 ORDER past the old envelope, antisymmetry re-verified by the full swapped re-run |
| `--alg-cmp "-⟨3N+1⟩ ⟨N⟩" 3 4 "-⟨3N+1⟩ -⟨2N+1⟩ ⟨N⟩" 3 4`, N = 10⁵⁰ | **`EQUAL`, exit 0** | **a 51-DIGIT pair-gcd**: Nx−(3N+1) and its (x+1)-multiple name the same root 3+1/N — the Euclidean chain ran on 51-digit coefficient rows |
| `--alg-cmp "-⟨3N+1⟩ ⟨N⟩" 2 4 "-3 1" 2 4` | exit 2 | 3+10⁻⁵⁰ **> 3 DECIDED at depth 1**: the machine outperforms the author's abstention prediction — 3 is a dyadic cut, so one bisection separates a 10⁻⁵⁰ gap exactly |
| `--alg-cmp "-⟨3N+1⟩ ⟨N⟩" 2 4 "-⟨6N+1⟩ ⟨2N⟩" 2 4`, N = 10⁵⁰ | exit 2 | roots 3+1/N vs 3+1/(2N), both non-dyadic, separation 5·10⁻⁵¹ ≈ 2⁻¹⁶⁷: **DECIDED A > B through the deep tier** — this exact input was the 2⁻⁴⁴ abstention row before the wall dissolved |
| the same pair at N = 10³⁰⁰ | exit 2 | separation ≈ 2⁻⁹⁹⁹: ~960 deep-tier rounds with ~1000-bit window numerators through the handle door — **DECIDED**, exactly, in seconds |
| `--alg-sign "-2 0 1" 1 2` / `"-2 0 1" -2 -1` / `"0 1" -1 1` | exit 2 / 1 / 0 | +√2 POSITIVE, −√2 NEGATIVE, the root of x EXACTLY ZERO — each verdict agreed by the counting AND refinement faculties |
| `--alg-sign "2 -3 1" 0 3` | exit 4 | `REFUSED: (0, 3] holds 2 roots … an algebraic number needs exactly 1 (isolate first: --roots)` |
| `--alg-sign "-1 -1 0 0 0 1" 1 2` | exit 2 | **degree 5 — past the old deg-3 envelope**: the real root of x⁵−x−1 (≈1.1673) POSITIVE, counting and refinement faculties agreeing through the bigint chain |
| `--alg-sign "0 0 0 -4 0 1" -1 1` / `… -3 -1` | exit 0 / exit 1 | x⁵−4x³ = x³(x²−4): the window (−1,1] holds ONLY the root 0 → **EXACTLY ZERO at degree 5** (c₀ = 0 ∧ 0 ∈ window, pure arithmetic); (−3,−1] holds −2 → NEGATIVE |
| `--alg-sign "-⟨3·10⁵⁰+1⟩ ⟨10⁵⁰⟩" 3 4` | exit 2 | a 51-DIGIT linear polynomial: the root 3+10⁻⁵⁰ signed POSITIVE through the limb rows — coefficients the old parse (18 digits) could not even carry |
| `--alg-sign "-1 1125899906842624" -1 2` | exit 2 | root 2⁻⁵⁰ in a straddling window: **+1 DECIDED** — the refinement faculty follows the counting faculty through the deep tier (this exact input was the 2⁻⁴⁴ abstention row) |
| `--alg-sign "-1 ⟨10³⁰⁰⟩" -1 2` | exit 2 | root 10⁻³⁰⁰ straddled: both faculties agree at depth ~1000 — sign has NO depth abstention left; memory is the only boundary |
| `--alg-sign "-2 0×959 1" 1 2` / deg-961 input | exit 2 / exit 5 | **degree 960**: x⁹⁶⁰−2's positive root signed POSITIVE at the widened class (every prior envelope — 3, 60, 120, 240, 480 — now strictly inside); degree 961 is the named envelope |
| `--alg-add "-2 0 1" 1 2 "-3 0 1" 1 2` | exit 0 | **√2+√3 → `1 0 -10 0 1` = x⁴−10x²+1 — the classical minimal polynomial, machine-constructed** — isolated in (2, 4], bigint-certified AND Σ√-oracle-confirmed |
| `--alg-mul "-2 0 1" 1 2 "-3 0 1" 1 2` | exit 0 | √2·√3 → `36 0 -12 0 1` = (t²−6)², the norm form (conjugate pairings coincide — multiplicity carried, the window still pins the ONE root √6) |
| `--alg-add "-2 0 0 1" 1 2 "-4 0 0 1" 1 2` | exit 0 | ∛2+∛4 → degree 9: `-216 0 0 -108 0 0 -18 0 0 1` (consistent with γ³ = 6+6γ), certified window (2, 4] |
| `--alg-add "-1 1" 0 2 "-5 0 1" 2 3` then `--alg-mul "-4 -2 1" 3 4 "-1 2" 0 1` | exit 0 both | **THE GOLDEN RATIO, composed across two invocations**: 1+√5 → `-4 -2 1` (t²−2t−4); that printed output fed back with the exact rational 1/2 (2x−1) → `-4 -4 4` = 4t²−4t−4, φ isolated in (0, 4] — the content 4 is visible: a DEFINING polynomial, never claimed minimal |
| `--roots "1 0 -10 0 1"` | exit 0 | closure the other way: `--alg-add`'s output is a legal `--roots` input — all four conjugates ±√2±√3 isolated, multiplicity 1 each |
| `--alg-mul "-2 0 1" 1 2 "0 1" -1 1` | exit 0 | `PRODUCT: exactly 0 (B is the zero algebraic number)` — detected exactly, no resultant needed |
| `--alg-mul "-2 0 1" -2 -1 "-3 0 1" 1 2` | exit 5 | negative interval: the named abstention with the exact p(−x) workaround printed |
| `--roots-big "<W12 coefficients>" 0 13` | exit 0 | **Wilkinson (x−1)…(x−12) — degree 12 IS past the i64 chain wall — all 12 roots isolated** with multiplicity 1, Σ = 12 = degree, bigint-Sturm certified |
| `--roots-big "-1208925819614629174706176 1208925819616828197961728 -2199023255553 1" 0 1099511627777` | exit 0 | **(x−2⁴⁰)²(x−1) with an 81-bit constant term: the double root at 2⁴⁰ certified `multiplicity 2 — TOUCHES`** through the raw limb door; root 1 crosses; Σ = 3 = degree |
| `--roots-big "1125899906842623 -6755399441055744 10133099161583616" 0 1` | exit 0 | **THE 2⁻²⁴ CLUSTER WALL, DISSOLVED**: roots 1/3 ± 1/(3·2²⁵), gap ≈ 2⁻²⁶ — this exact input was the sealed cluster abstention row (`2 certified but only 0 isolated`); the DEEP SPLITTER now delivers BOTH roots as exact dyadic windows `(22369620/2²⁶, 22369621/2²⁶]` and `(22369621/2²⁶, 22369622/2²⁶]`, multiplicity 1 each |
| `--roots-big "0 0 … 0 1"` (deg 961) / `"12x 1"` / `"0 0"` / window past 2⁴⁴ | exits 5/3/3/5 | envelope abstention (the boundary now 960), trailing garbage, the zero polynomial, window envelope — each named |
| `--roots-big "-2 0×24 1" 1 2` | exit 0 | **x²⁵−2 — the OLD deg-24 refusal now delivers**: 2^(1/25) isolated in (1, 2], multiplicity 1 (gate 2185's E arm pins the same boundary engine-side) |
| `--roots-big "-2 0×59 1" -2 2` | exit 0 | **x⁶⁰−2, a former boundary**: a degree-60 Sturm chain built and evaluated — both real roots ±2^(1/60) isolated, multiplicity 1 each |
| `--alg-inv "-2 0 1" 1 2` | exit 0 | 1/√2 → `-1 0 2` = 2x²−1, window (1/3, 1], Σ√-oracle-confirmed |
| `--alg-inv "1 0 -10 0 1" 3 4` | exit 0 | **1/(√2+√3) with a DEGREE-4 input** (the widened envelope): R is `1 0 -10 0 1` — **self-reversed**, the 2180 palindrome fact on the CLI; window (1/5, 1/3] pins √3−√2 |
| `--alg-inv "-2 0 0 1" 1 2` / `"-2 0 1" -2 -1` | exit 0 both | 1/∛2 → 2x³−1; **1/(−√2), the negative side** — window (−2, −1/2], the h = −1 outer-bracket case measured |
| `--alg-inv "0 1" -1 1` | exit 4 | `REFUSED: the inverse of the zero algebraic number does not exist` |
| `--alg-mul "-2 0 1" -2 -1 "-3 0 1" -2 -1` and mixed | exit 0 both | **the SIGNED product**: (−√2)(−√3) = +√6 in (1/2, 4]; (−√2)(√3) = −√6 in (−9/2, −1] — the former nonneg-only abstention replaced by real support |
| `--alg-mul "-2 0 1" 1 2 "-2 0 0 1" -1 2` | exit 0 | a ZERO-STRADDLING valid interval for β: the sign-definite phase separates it, then √2·∛2 → `-32 0 0 0 0 0 1` = **t⁶−32 exactly** (γ⁶ = 32) |
| `--alg-add "-2 0 0 0 0 0 0 1" 1 2 "-1 1" 0 2` | exit 0 | **a degree-7 input**: 2^(1/7)+1 → `-3 7 -21 35 -35 21 -7 1` = (t−1)⁷−2, the binomial row machine-constructed |
| `--alg-mul "-2 0 0 0 0 0 1" 1 2 "-2 0 0 1" 1 2` | exit 0 | 2^(1/6)·2^(1/3) = √2 through a degree-18 resultant — R = (t⁶−8)³, window (1/2, 4] pins the one positive real root (the OLD D = 18 boundary, comfortably inside the widened geometry) |
| `--alg-mul "-2 0 0 0 0 0 0 1" 1 2 "-2 0 0 1" 1 2` | exit 0 | **the OLD D = 21 abstention now DELIVERS**: 2^(1/7)·2^(1/3) = 2^(10/21) → R = `t²¹ − 1024` EXACTLY, window (1/2, 4] |
| `--alg-mul "-2 0×23 1" 1 2 "-2 0 1" 1 2` | exit 0 | **the D = 48 boundary with a DEGREE-24 OPERAND**: 2^(1/24)·√2 = 2^(13/24) → R = `(t²⁴ − 8192)²` exactly (c₀ = 2²⁶, c₂₄ = −2·8192, monic), the deg-48 window chain rebuilt per refinement round through the widened pool |
| `--alg-add "-2 0×7 1" 1 2 "-1 1" 0 2` | exit 0 | **a degree-8 operand** (past the old 7): 2^(1/8)+1 → `(t−1)⁸−2`, the binomial row `-1 -8 28 -56 70 -56 28 -8 1` machine-constructed |
| gate 2186 P2/Q arms | exit 99 | **D = 49 engine-side**: 2^(1/7)·3^(1/7) → R = (t⁷−6)⁷ (deg 49, c₀ = −6⁷); the deg-49 output re-enters the widened chain and `root_mult2_cur` certifies **multiplicity SEVEN** at 6^(1/7) — closure at the boundary, both directions |
| `--alg-mul "-2 0×23 1" 1 2 "-2 0 0 1" 1 2` | exit 0 | **the OLD D = 72 abstention now DELIVERS**: 2^(1/24)·2^(1/3) = 2^(3/8) → R = `(t²⁴−512)³` exactly (c₄₈ = −1536, c₂₄ = 786432, c₀ = −512³) — the machine's norm form, not the author's first guess |
| `--alg-mul "-2 0×47 1" 1 2 "-2 0 1" 1 2` | exit 0 | **the D = 96 boundary with a DEGREE-48 OPERAND**: 2^(1/48)·√2 = 2^(25/48) → R = `(t⁴⁸−2²⁵)²` exactly, window (1/2, 4] |
| `--alg-mul "-2 0×47 1" 1 2 "-2 0 0 1" 1 2` | exit 0 | **the OLD D = 144 refusal now DELIVERS**: 2^(1/48)·2^(1/3) = 2^(17/48) → R = `(t⁴⁸−2¹⁷)³` exactly (c₀ = −2⁵¹, c₄₈ = 3·2³⁴ = 51539607552, c₉₆ = −3·2¹⁷, monic), window (1/2, 4] |
| gate 2186 W/H arms | exit 99 | **the SELF-GENERATED prime window**: the generator reproduces the historical 16 constants entry-for-entry, delivers 512 descending primes in (2²⁹, 2³⁰) each re-verified by the GATE's own independent trial division; a 520-bit-bound sum the 16-prime window REFUSED is delivered (deg 48, c₀ spanning 8 raw limbs) and its root 10^(1/4)+√999983 counted in (1001, 1002] |
| gate 2186 P5/P6/R arms | exit 99 | **D = 384 and D = 768 engine-side**: (t⁴⁸−32)⁸ and (t⁹⁶−128)⁸ delivered and re-entered into degree-384/768 chains (ONE root in (1, 2] each; the smallest-Sylvester factorizations 16×24 and 24×32 keep the boundary provable in ~4 primes / ~1 s under the adaptive window); **the R arm crosses two historical ceilings at once** — A = x⁶⁷−a, B = x²−a with a = 2⁶⁰−1: bnd = 4209 bits (the 128-prime-era window refused this class) and R(0) = −a⁶⁹ spans **65 raw limbs** (the 64-limb-era rows refused it) — the gate re-computes a⁶⁹ with its OWN bigint chain and pins every limb: self-verifying, no transcribed constants |
| gate 2186 N arm | exit 99 | **the ADAPTIVE WINDOW gate-pinned**: `N: 4 18 3 4 146` — each arm used exactly ceil((bnd+2)/29) primes (A bnd 91 → 4, H 520 → 18, P5 80 → 3, P6 112 → 4, R 4209 → 146): a run's price is its own certificate, deterministic and observed |
| `--roots-big "-2 0×119 1" -2 2` | exit 0 | **x¹²⁰−2 through a degree-120 Sturm chain** (a former boundary): both real roots ±2^(1/120) isolated, multiplicity 1 — the O(1)-live-handle pseudo-remainder |
| gate 2185 H arm | exit 99 | **the handle door, SELF-VERIFYING**: √2 refined 100 deep through `root_count2_h`; the final width-2⁻¹⁰⁰ window is proven by EXACT SQUARING (L² < 2·4¹⁰⁰ ≤ (L+1)²) — the gate carries no transcribed constant; the certificate is computed |
| `--roots-big` with 2001-digit coefficients | exit 0 | N = 10²⁰⁰⁰+1, p = N·x − (3N+1) (primitive): the root 3 + 1/N isolated in (3, 4], multiplicity 1 — coefficients past the old 1300-digit cap, at the engine's true 256-limb row capacity |
| `--roots-big "-2 0×239 1" -2 2` | exit 0 | **x²⁴⁰−2 through a degree-240 Sturm chain** (a former boundary; gate 2185's G2 arm): both real roots ±2^(1/240) isolated, multiplicity 1 |
| `--roots-big "-2 0×479 1" -2 2` | exit 0 | **x⁴⁸⁰−2 through a degree-480 Sturm chain** (a former boundary; gate 2185's G3 arm): both real roots ±2^(1/480) isolated, multiplicity 1 |
| `--roots-big "-2 0×959 1" -2 2` / deg-961 input | exit 0 / exit 5 | **x⁹⁶⁰−2 through a degree-960 Sturm chain** (gate 2185's G4 arm pins the same boundary engine-side), sub-second: both real roots ±2^(1/960) isolated, multiplicity 1; degree 961 refused by name |
| `--roots-big "⟨10¹²⁰−1⟩ −⟨6·10¹²⁰⟩ ⟨9·10¹²⁰⟩" 0 1` | exit 0 | **a cluster at gap ≈ 6.7·10⁻⁶¹**: roots (10⁶⁰±1)/(3·10⁶⁰) — the deep splitter descends ~200 dyadic levels and prints both roots as EXACT width-2⁻²⁰⁰ dyadic windows (adjacent 60-digit numerators over 2²⁰⁰), multiplicity 1 each |
| `--alg-add "-2 0 1" 1 2 "-2199023255553 0 1099511627776" -2 -1` | exit 0 | **DEEP PINNING (the former 2⁻²⁰ wall)**: γ = √2 − √(2+2⁻⁴⁰) ≈ −2⁻⁴¹·⁵ with its conjugate +2⁻⁴¹·⁵ only ~2⁻⁴⁰·⁵ away — R = 2⁸⁰t⁴ − 9671406556919232420904960t² + 1, window `(−2/2³⁸, 0/2³⁸]` **pinned through the DEEP tier**: the window's SIGN, not its width, excludes the conjugate |
| `--alg-inv "-1 1125899906842624" 0 1` | exit 0 | **deep pinning through the GENERAL-RATIONAL door** (`root_count2_q`, gate 2185's I arm): α = 2⁻⁵⁰ → R = `-1125899906842624 1` = t − 2⁵⁰, window `(2⁵¹/3, 2⁵¹/1]` — non-dyadic denominators from the inverse-window shape, counted exactly on R's chain |
| `--alg-mul "-2 0×63 1" 1 2 "-2 0 0 1" 1 2` | exit 0 | **D = 192, a former boundary, on the CLI**: 2^(1/64)·2^(1/3) = 2^(67/192) → R = `t¹⁹² − 2⁶⁷` EXACTLY (c₀ = −147573952589676412928, monic), window (1/2, 4] — gate 2186's P4 arm pins the same D engine-side AND re-enters the deg-192 output into a degree-192 chain (exactly ONE root in (1, 2], c₀ spanning raw limbs (0, 8)) |
| `--alg-mul "-2 0×15 1" 1 2 "-2 0×23 1" 1 2` | exit 0 | **D = 384, a former boundary, on the CLI**: 2^(1/16)·2^(1/24) = 2^(5/48) → R = `(t⁴⁸−32)⁸` EXACTLY — the full binomial expansion machine-constructed (c₀ = 2⁴⁰, c₄₈ = 8·(−32)⁷ = −274877906944, c₉₆ = 28·32⁶, …, c₃₃₆ = −256, monic), window (1/2, 4] pins the ONE positive real root of the multiplicity-8 orbit |
| `--alg-mul "-2 0×23 1" 1 2 "-2 0×31 1" 1 2` | exit 0 | **the D = 768 boundary on the CLI**, ~1 s under the adaptive window: 2^(1/24)·2^(1/32) = 2^(7/96) → R = `(t⁹⁶−128)⁸` EXACTLY (c₀ = 2⁵⁶, c₆₇₂ = −1024, monic), window (1/2, 4] |
| `--alg-mul` at deg 385 / at deg 384 × deg 3 | exit 5 / exit 5 | `degree > 384 is outside the arithmetic-verb envelope` and `degree(A) * degree(B) = 1152 exceeds 768 — the recovery geometry's bound (the adaptive <= 512-prime bnd certification still applies per run inside it)` — both named |
| `--alg-add` with c₀ = −2⁶⁰ / with 19-digit 10¹⁸+3 / with a 20-digit coefficient | exit 5 / exit 0 / exit 3 | the arithmetic verbs' coefficient envelope MEASURED at its boundary: `a \|coefficient\| >= 2^60 is outside the envelope` ABSTAINS; 10¹⁸+3 (19 digits, inside 2⁶⁰) DELIVERS R = ⟨10¹⁸+3⟩t − ⟨10¹⁸+4⟩ with γ = 1+1/(10¹⁸+3) pinned in (0, 3]; past-i64 digits are an overflow-GUARDED parse refusal, never a silent wrap |
| gate 2185 G2/G3/I arms | exit 99 | the degree-240 (former) and **degree-480 (current)** chain boundaries counted from both sides; the GENERAL-RATIONAL door measured at denominator 3 (√2 ∈ (4/3, 3/2], ∉ (2/3, 4/3]) and the DEEP MULTIPLICITY door (`root_mult2_cur_h`: (x²−2)² certified **multiplicity 2** at a dyadic handle window) |

---

## `iii-typecheck` — the dependent-type kernel, on your terms

```
iii-typecheck <term-file>                      infer the term's type, or refuse
iii-typecheck --check <term-file> <type-file>  check term : type (bidirectional)
iii-typecheck --qtt <term-file>                judge QTT usage: every binder within its declared
                                               multiplicity (erased ^0 / linear ^1 / unrestricted)
iii-typecheck --lek "<c1..c6>" "<b1..b6>"      SOVEREIGNTY AS TYPES: the kernel PROVES (or refuses)
                                               cost <= budget over your own 6-vectors, by iota
iii-typecheck --reach <hexad>                  the kernel proves/refuses hexad reachability by
                                               REDUCTION through its own oracle -- never baked
```

Build: `bash COMPILER/BOOT/build_iii_typecheck.sh` → `COMPILED/iii-typecheck`.
Source: `STDLIB/iii/aether/typecheck_cli.iii` over the UNCHANGED kernel `numera/typecheck`
(lambda-Pi + predicative universes U0:U1:…, Σ, Bool, Id/J, Nat/iter/natrec, Unit, Empty, Sum,
W-types, **BV64** and **QTT**; conversion by the directed CCL oracle). The CLI is an untrusted
S-expression front end over the kernel's own constructors and serializer — the de Bruijn criterion
survives: a parse error is the TOOL's verdict (exit 3, position printed); only the kernel says
WELL-TYPED. Grammar in `--help`; binders are de Bruijn (`(var 0)` innermost). Exit `0` =
well-typed/checked/QTT-respected, `4` = the kernel REFUSED, `3` = parse, `2` = file.

BV64 grammar: `bv` (the native 64-bit machine-int type, BV : U0), `(bvlit N)` (a decimal u64),
and `bvadd bvsub bvmul bvand bvor bvxor bvshl bvlshr bvudiv : BV→BV→BV` plus the overflow
predicates `bvaddovf bvmulovf : BV→BV→Bool` — all iota-reduce mod 2⁶⁴ on literals, so the kernel
PROVES width-sensitive machine arithmetic by conversion, not by a unary Peano tower. QTT grammar:
`(lam0 A b)` erased / `(lam1 A b)` linear / `(lamw A b)` unrestricted (same `pi0/pi1/piw`);
`--qtt` requires well-typedness FIRST (QTT is a layer over infer), then runs the kernel's
`tc_qtt_ok` usage judgment. Printed types omit the quantities (the kernel carries them — they are
part of the type's identity for conversion). `--lek` builds the cost/budget registry IN-PROCESS
from your two 6-vectors (the M13 budget shape) and checks `(refl true) : Id(Bool, LEK(c,b), true)`
— LEK iota-reduces through `cl_le_product` (the product order over all six components), so
over-budget is a TYPE error, not a warning. `--reach <h>` checks the Reach proof for hexad h:
REACH(h) iota-reduces through the kernel's own reachability oracle (`iii_hexad_reachable`) — a
bricking configuration is UNCONSTRUCTABLE as a type (the mig2 SovVal law, on your arguments).

Verified on fresh input:

| input | observed |
|---|---|
| `(lam (sort 0) (lam (var 0) (var 0)))` | `WELL-TYPED : (pi (sort 0) (pi (var 0) (var 1)))` — the polymorphic identity's DEPENDENT type, with the codomain variable correctly de Bruijn-lifted to `(var 1)` by the kernel |
| `(refl true)` | `(id bool true true)` |
| `(iter zero (lam nat (succ (var 0))) (succ (succ zero)))` | `nat` |
| `(app true false)` / `(var 0)` bare / `(inl true)` bare | `ILL-TYPED`, exit 4 — wrong application, out-of-scope variable, and an unannotated checkable form all refused |
| `(ann (inl true) (sum bool nat))` | `(sum bool nat)` — the bidirectional door: annotate, or use `--check` |
| `--check (inl true) : (sum bool nat)` | `CHECKED`, exit 0 |
| `--check (sort 0) : (sort 0)` | **`REJECTED`, exit 4 — Girard's paradox arm: a kernel that accepted `U0 : U0` would prove False** |
| `--check (sort 0) : (sort 5)` | `CHECKED`, exit 0 — predicative cumulativity, measured |
| `--check (sort 0) : true` | `REJECTED: the supplied 'type' is a term, but its type is not a universe`, exit 4 |
| `(succ` / `(frob 1)` / `true junk` | parse errors at the exact byte offset, exit 3 — never the kernel's verdict |
| `(bvadd (bvlit 3) (bvlit 4))` | `WELL-TYPED : bv` |
| `--check (refl (bvlit 7)) : (id bv (bvadd (bvlit 3) (bvlit 4)) (bvlit 7))` | `CHECKED`, exit 0 — **the kernel PROVES 3+4=7 in 64-bit machine arithmetic** by iota conversion |
| the same against `(bvlit 8)` | `REJECTED`, exit 4 — a FALSE machine identity does not check |
| `--check (refl (bvlit 0)) : (id bv (bvadd (bvlit 18446744073709551615) (bvlit 1)) (bvlit 0))` | `CHECKED`, exit 0 — **mod-2⁶⁴ wraparound PROVEN: max+1 = 0** (unreachable for a unary Peano tower) |
| `bvaddovf(max, 1) = true` / `= false` | `CHECKED` / `REJECTED` exit 4 — the carry-out is a Bool the kernel computes, both arms |
| `bvmulovf(2³², 2³²) = true` | `CHECKED`, exit 0 — the full-product overflow flag |
| `(id bv (bvshl (bvlit 5) (bvlit 3)) (bvmul (bvlit 5) (bvlit 8)))` with `(refl (bvlit 40))` | `CHECKED`, exit 0 — x≪k = x·2ᵏ, both sides reduce to 40 |
| `(id bv (bvudiv (bvlit 5) (bvlit 0)) (bvlit 0))` | `REJECTED`, exit 4 — **division by zero is STUCK: the kernel will not equate 5/0 with anything, by design** |
| `(bvlit 18446744073709551616)` | `parse error at byte 27`, exit 3 — one past 2⁶⁴−1 is the TOOL's verdict, never the kernel's |
| `--qtt (lam1 bool (var 0))` | `QTT USAGE: RESPECTED … term : (pi bool bool)`, exit 0 — linear, used exactly once (the printed pi omits the quantity, as documented) |
| `--qtt (lam1 bool (if (var 0) (var 0) (var 0)))` | `QTT REJECTED`, exit 4 — scrutinee + branch = 1+1 = ω violates linear |
| `--qtt (lam1 bool (if true (var 0) (var 0)))` | **`RESPECTED`, exit 0 — the alternative-branch law: once in EACH if-branch is still exactly once (only one branch runs)** |
| `--qtt (lam0 bool true)` / `(lam0 bool (var 0))` | `RESPECTED` exit 0 / `REJECTED` exit 4 — erased means UNUSED at runtime, both arms measured |
| `--qtt (lam0 (sort 0) (lam1 (var 0) (var 0)))` | `RESPECTED … term : (pi (sort 0) (pi (var 0) (var 1)))`, exit 0 — dependent erasure: the erased type-argument appears ONLY in a type position |
| `--qtt (lam1 bool (app (var 0) (var 0)))` | `ILL-TYPED: QTT is a layer over typing`, exit 4 — the ill-typed term is refused BEFORE usage is judged |
| `--lek "1 2 3 4 5 6" "6 6 6 6 6 6"` | `WITHIN BUDGET: the kernel PROVES cost <= budget`, exit 0 |
| `--lek "1 2 3 4 5 7" "6 6 6 6 6 6"` | `OVER BUDGET: the kernel REFUSES the LeK proof`, exit 4 — ONE component over is enough (product order); **over-budget is a TYPE error** |
| `--lek "3 3 3 3 3 3" "3 3 3 3 3 3"` / five numbers | exit 0 (≤ is reflexive) / exit 3 (exactly six required) |
| `--reach 40` | `REACHABLE: hexad 40's Reach proof type-checks`, exit 0 — **40 is the lattice's first reachable id (measured by scan)** |
| `--reach 0` (…through 5, and every id below 40) | `UNREACHABLE (bricking): no Reach proof exists`, exit 4 — an unreachable configuration is unconstructable as a type |
| `--reach 70000` | exit 3 — a hexad id is 0..65535; the parse verdict is the tool's |

---

## `iii_eval` — the definitional evaluator / REPL

```
iii_eval <file.iii>      evaluate a module through the meaning-bearer
iii_eval --repl          interactive
```
Build: `bash COMPILER/BOOT/build_iii_eval.sh` → `COMPILED/iii_eval`.
The independent meaning-witness: it runs a program by *definition*, not by compiled code, and the standing
`run_meaning.sh` differential holds the two against each other on the whole corpus.

## `iiis-2` — the self-hosted compiler

```
iiis-2 <file.iii> --compile-only --out <file.o>    compile
iiis-2 --link <objs...> --out <prog>               link (no gcc in the trusted path)
iiis-2 <file.iii> --emit-svir --out <gen.iii>      emit the verifiable IR
```
Takes any `.iii`. Compiles itself (the DDC fixpoint: `iiis-2` ≡ `iiis-3`, byte-identical).

## `sovhash` — the sovereign content-address

```
sovhash <file>     plain FIPS 180-4 SHA-256 of the file's bytes
```
Minted on demand by the seal library (`COMPILER/BOOT/mhash_lib.sh`) from `STDLIB/iii/aether/sovhash.iii`
into `COMPILED/_sovhash/sovhash.exe` — one `iiis-2` compile + link. Streams any file of any size and agrees
byte-for-byte with GNU `sha256sum`, Microsoft `certutil`, and `iii-crypto hash` — independent authorships,
so a lie in one is exposed by the others.

## `run_mathesis.sh --standing` — the discovery engine

One command. No LLM, no operator anywhere in its process tree (gated: `corpus/2682`). It measures its own
compilation, synthesizes candidate theorems from the *whole declared space*, proves or refuses each, seals
what survives into a replayable content-addressed library, and folds the useful ones back into the compiler.

---

## The honest frontier (what is still library-locked)

Named, not hidden.  The three resource knobs named here earlier on 2026-07-13 CLOSED the same day:

- **The order-refinement depth cap 2⁻⁴⁴ — DISSOLVED.**  Window numerators leave i64 for signed
  bigint handles (the deep tier) counted through `sturm_big`'s new handle door (`root_count2_h`);
  refinement descends to any depth memory affords.  The 2⁻⁵⁰-sign and 5·10⁻⁵¹-order abstention
  rows above became DECIDED rows; a 2⁻⁹⁹⁹ separation decides in seconds.  Termination is
  mathematical (distinctness / nonzero-ness is proven first); the per-input separation over-bound
  guards defects only, and resource exhaustion is a named abstention.
- **The 464-bit `bnd` ceiling — LIFTED to 1856.**  The prime window is now SELF-GENERATED (the 64
  largest primes below 2³⁰ by deterministic trial division — no table to transcribe wrong, ever)
  and SELF-CERTIFYING (gate 2186's W arm re-verifies every prime with the gate's own independent
  trial division and pins the first 16 against the historical constants, so every sealed output is
  byte-identical).  A 520-bit-bound input the old window refused now delivers.
- **Geometry strides — WIDENED AGAIN** (chain 60 → 120, recovery 49 → 96), and the widening EARNED
  its keep twice over: it exposed and closed (a) the falling-factorial binomial overflow past
  degree ~28 (`rs_binom`: interleaved multiply/divide, exact at every prefix) and (b) the
  pseudo-remainder's full-row live handles, which silently exhausted the GLOBAL 64-slot handle
  table past degree ~60 — `st2_prem` now runs O(1) live handles at ANY degree through a dedicated
  ping-pong scratch pool (the wall the whole pool architecture exists to respect).

What remains, honestly:

- **Physics**: pool limbs (2097152), the per-eval 1 GiB arena ceiling, the working-row regions
  (2 × 1048576 limbs), the deep splitter's 64-root/64-limb rows, static array storage (~90 MB of
  .bss at this rung — the growth cost further stride turns actually pay), and compute time on
  genuinely-big-BOUND inputs — every one an explicit, measured refusal or a per-run price, never
  a wrong answer.
- **Geometry strides themselves** (chain degree 960, recovery D 768, the adaptive ≤ 512-prime /
  14848-bit window with 256-limb delivery rows, the 2⁶⁰ arithmetic-verb coefficient parse): each
  remains a constant-plus-arrays widening priced at one owner-family re-gate, now
  FIVE-times-rehearsed (24 → 60 → 120 → 240 → 480 → 960; 18 → 49 → 96 → 192 → 384 → 768;
  16 → 64 → 128 → 256 → 512 primes).

There is no named DEPTH item left on this surface: sign, order, equality, isolation,
cluster-splitting, multiplicity, and window-pinning all descend to any depth memory affords.
Within the certified window there is no DELIVERY gap: the 256-limb rows (16384 bits) cover the
full 14848-bit bound — everything the engine certifies, it can hand over.  And there is no
CAPACITY-TIME coupling left either: THE ADAPTIVE PRIME WINDOW (rs_setnuse) prices every run by
its OWN certified bound — ceil((bnd+2)/29) primes, gate-pinned per arm (2186 N) — so widening
the window costs the workload NOTHING (the owner family ran FASTER at rung five than at rung
four while capacity doubled: 2481 fuzzer 49 s → 1 s, gate 2186 38 s → 3 s with two MORE arms).
A run's time is the size of its own certificate; the engine's capacity is free.

(ML-KEM, SLH-DSA, Ed25519, AES-SIV, rank-1 denesting, and the CIC core left this list on 2026-07-12;
Sturm isolation + multiplicity, the algnum order structure, QTT, and BV64 left it the same day; the
three then-named items — algebraic-number ARITHMETIC, beyond-i64 coefficients, LEK/REACH — left it
before that day ended; on 2026-07-13 **`--alg-inv` closed the FIELD** (+, ·, ⁻¹, hence ÷, all
standing), the **product went signed**, the **arithmetic verbs went to degree 7 / D = 18**, and
**`--roots-big` reached the 256-limb row capacity**; later that day the LAST named capability items
closed: **the ORDER verbs left the deg-3 register file for the engine's full class** (equality by
the new `sturm_big` PAIR-GCD door, gate 2186 G; a 51-digit-coefficient EQUAL and a deg-4-vs-deg-6
EQUAL measured on the CLI) and **the geometry caps widened** (pool → 60, recovery → 49, gate 2185
D/E/F + 2186 P2/Q with (t⁷−6)⁷ and multiplicity SEVEN); the three RESOURCE knobs closed next — the
deep tier, the self-generated 64-prime window, chain 120 / recovery 96 — with two latent defects
found and fixed by the widening itself; and the day's LAST rung took the two depth walls that had
inherited the deep tier's mechanism — **`--roots-big`'s 2⁻²⁴ cluster splitting** (the deep
splitter: width-invariant handle windows, exact dyadic printing, deep multiplicity through
`root_mult2_cur_h`) and **the arithmetic verbs' 2⁻²⁰ window pinning** (the deep pinning tier,
dyadic AND general-rational doors) — while every knob turned again (chain 240, recovery 192
through the byte-identical LAGRANGE recovery, 128 primes / 3712 bits, coefficients to 2⁶⁰), and
the widening again earned its keep: the 128-prime Garner walk of a NEGATIVE coefficient exposed
the fixed-CRT-arena assumption (gates 2473/2474 caught it), closed by the per-coefficient-arena
law.  A FIFTH rung followed — chain 960 / recovery 768 / a 512-prime 14848-bit CEILING — and
carried THE INVENTION that conquered the compute-time wall the fourth rung had exposed: the
ADAPTIVE PRIME WINDOW (each run pays ceil((bnd+2)/29) primes — the same 29-bit-floor theorem,
now applied per run instead of per capacity; outputs provably byte-identical, the 464-bit sealed
class re-running its original 16-prime window; gate 2186's N arm pins the used counts), plus two
exact-value algorithmic closures (rs_consist's row residues hoisted per prime + Horner across
nodes — the hidden D³ term gone; power tables in the shift rows — the per-term O(j−i) walks
gone).  Measured: the D = 768 boundary arm costs FOUR primes (~1 s); the family's wall-clock
FELL while capacity doubled.  The cg_r3 64-local-slot ceiling fired once on the widened gate
(exit 14 — the documented trap) and the new arms' scratch moved to module scope, the house
style.  A FOURTH rung before it — chain 480 / recovery 384 / 256 primes (7424 bits) —
and its own audit fired twice before a line was run (the [200] Lagrange scratch would have
silently overflowed at D > 198; the 7424-bit window would have out-certified the 64-limb delivery
rows, so the rows widened to 128 limbs), while gate 2186's B arm caught the one site the sweep
missed within seconds of the first run (the `rs_big_limb` READ-side stride — the writer had moved
to 128-limb rows, the reader hadn't; coefficient 0 lives at offset 0 under any stride, which is
exactly why only the multi-coefficient arm saw it).  Every sealed deep row re-measured
byte-identical across the widening.  Every verb proven on both arms, every claimed line observed
output; owner family PASS=71 FAIL=0 at every rung.)

Each is a tool of the same shape as `iii-prove`: link the library, take real input, print a real verdict.
