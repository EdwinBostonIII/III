# III — Capability Apotheosis (the Final-Form sister of III-CAPABILITY-VERIFICATION.md)

**For every capability verified in `III-CAPABILITY-VERIFICATION.md`, this file designs its most ambitious, most useful, most system-harmonious, most inventive *final form* — and then writes the exact, ordered, file-by-file, primitive-level change plan to realize it.**

This is the *constructive* sister of the verification file. The verification file asked *"what is true today?"* This file asks *"what is the apex this capability can become, and precisely how do we get there?"* — and is unafraid to **reinvent primitives** where a primitive is the thing holding a capability back.

Method: `/architect` (real architectural pass — requirements, trade-offs, ADR rationale, ordered roadmap), `/math-olympiad` rigor (final forms must be *provably* correct, not plausibly correct), `/simplify` + `/refactor` (the apex is **leaner**, not merely bigger — bloat removed for a provably-better, smaller system). Built one capability at a time, compounding: each capability's final form is harmonized with every prior decision (the *apotheosis method* — current → enhance → compound-with-priors → final).

---

## 0 · How to read this file

Each capability is elaborated as a self-contained section with a fixed shape:

1. **Final Form** — the idealized capability in one paragraph: what it *becomes*. Ambitious, concrete, harmonious.
2. **Why this is the apex** (`/architect` + `/math-olympiad`) — the requirements it must meet, the trade-offs decided (with the losing option named), the invariant/theorem that makes it *provably* the right shape, and what it reuses from the shared substrate (§ S).
3. **Reinvented primitives** — any primitive replaced or newly forged, with its old form, new form, and *why the old one was the ceiling*.
4. **Ordered file-by-file change plan** — the authoritative deliverable: an ordered list of every specific change to every specific `.iii` (and supporting) file, with `file:line` anchors, in build/dependency order, each line stating *what changes, to what, and why*. New modules, deletions, and KAT additions included.
5. **Proof obligation upgrade** — the new falsifier-first KAT(s) that pin the final form (negative arms included), and the determinism/seal consequence.
6. **Harmony ledger entry** — what this capability now *exports to* and *assumes from* the rest of the system, so the next capability composes with it.

Status legend: `◇ designed` (final form + change plan complete) · `◷ in design` (workflow grounding/diverging) · `· queued`.

---

## 1 · The Harmony Charter — the unifying substrate (the architect backbone)

Harmony is not decoration; it is the single highest-leverage architectural decision. The verification pass proved the system's emergent value lives in *shared organs* (the seal chain; the one NTT serving four primes; the `trit` de-duplication) and that its one measured **pessimization** — RSA Montgomery modpow running ~2.4× *slower* than the Knuth-division schoolbook (verification §III.16) — was caused by a primitive (`REDC`) that **allocated per limb-step** while its competitor (Knuth division) ran allocation-free on raw limbs. **The lesson is the charter:** the apex is reached by forging *one* allocation-free, raw-limb arithmetic substrate that every higher capability draws from, so a win in the substrate is a win everywhere at once.

The charter fixes four substrate-wide invariants that every capability below must honor (each is elaborated and made real in §S):

- **H-1 · One limb model.** A single canonical raw-limb representation (`u32` digit / `u64` accumulator, radix 2³²) shared by bigint, every prime field (`fe25519`, `fp256/384`, scalar fields `fn256/384`), Montgomery `REDC`, and the NTT. No capability invents its own limb layout. *(Trade-off decided: uniform radix-2³² over per-field hand-tuned radixes — we accept a small constant-factor cost in one or two fields to gain one provable, shared, allocation-free core. Simpler + harmonious beats locally-optimal-but-isolated.)*
- **H-2 · Allocation-free hot paths.** Every inner arithmetic loop (multiply, reduce, divide, REDC, NTT butterfly) operates on caller-provided fixed raw-limb buffers — *zero* arena/handle allocation inside the loop. This is the direct fix for the §III.16 pessimization and the design rule that makes Montgomery actually win. Allocation, where unavoidable, is hoisted out of the timed region.
- **H-3 · Shared organs, single proof surface.** A capability needs a transform/reduction/hash → it *reuses* the substrate organ (`ntt`, `REDC`, `keccak`/`sha2`, `cad`/`mhash`) and adds *zero* hand-rolled copies. Every shared organ has exactly one falsifier-first KAT that all its consumers inherit.
- **H-4 · Provable, sealed, separator-clean.** Every final form carries (a) a total-correctness statement checked by a negative-armed KAT, (b) a determinism/seal consequence (does the golden move? — it moves only if intended, ADR-027), and (c) idiomatic separator-free III (the verification pass proved auditors mis-flag valid one-line III; the apex code is written so intent is unambiguous).

These four invariants are the through-line. Every section's *Why-apex* cites which it leans on.

---

## 2 · The capability roadmap (dependency-ordered, compounding)

Designed in dependency order so harmony compounds upward: the substrate (§S) is forged first; each capability (§C) is then built on a substrate that is already final. Each entry maps to its verification-file origin and the Part-IV fine-grained capabilities it subsumes/elevates.

### Substrate — §S (the reinvented foundation; forged first)
- `◇ S.1` **Unified raw-limb arithmetic core** — *H-1/H-2.* (subsumes verification §II.6 bigint + the 16 `numera-bigint-arith` caps' representational base)
- `◇ S.2` **Bigint arithmetic** — multiply dispatch (schoolbook/AVX-512/Karatsuba/NTT), Knuth-D division, **allocation-free Montgomery REDC** (fixes §III.16). (§II.6, §III.15–16, 16 caps)
- `◇ S.3` **Prime-field & curve substrate** — `fe25519`, `fp256/384`, `fn256/384`, `ec256/384`, `field`, `galois`, `modular`, `modular_mont` on the one limb model. (part of §II.3/§II.4, §III.17, 16 `classical-ecc` caps)
- `◇ S.4` **The one NTT organ** — modulus-parameterized, tabled-Montgomery, serving every NTT-friendly prime + bigint-multiply. (§II.3 NTT, 11 `pqc-ntt` caps)
- `◇ S.5` **Hash / MAC / AEAD / KDF / RNG organ** — `sha2`/`keccak`/`blake2s`/`poly1305`/AEAD/KDF/DRBG, scalar↔AVX-512 bit-identity. (§II.5, 26 `symmetric-hash` caps)
- `◇ S.6` **The seal & content-address chain** — `cad` → `mhash` → `merkle` → `witness`, closed by the byte-identity fixed-point. (§II.2)
- `◇ S.7` **Arena / region / time substrate** — the allocation + monotonic-time discipline (H-2's backing). (§II.11 alloc, 10 `memoria-tempora` caps)

### Capabilities — §C (built on the final substrate)
- `◇ C.1` **Post-quantum crypto** — ML-KEM/ML-DSA/SLH-DSA on §S.4 + §S.5. (§II.3, 11 caps)
- `◇ C.2` **Classical crypto** — X25519/Ed25519/RSA-PSS/ECDSA on §S.2/§S.3 + §S.5. (§II.4, §III, 16 caps)
- `◇ C.3` **Zero-knowledge zk-STARK** — FRI prover+verifier on §S.4/§S.6. (§II.7)
- `◇ C.4` **Self-hosting compiler & byte-identity reseal** — lex/parse/sema/cg_*. (§II.1, 19 `compiler-boot` caps)
- `◇ C.5` **Math / logic / verification substrate** — theorem carrier, bisimulation, e-graph, LTL, constitution VM, commit-gate. (§II.8, 25 `logic-verify` caps)
- `◇ C.6` **XII term-rewriting** — rules, confluence/termination certs, lowering pipeline. (§II.12, 32 `omnia-xii` caps)
- `◇ C.7` **Ripple Calculus & emergent self-optimization** — the self-measuring/self-refactoring loop. (§II.9, §V, 19 `forcefield` caps)
- `◇ C.8` **Microarchitecture / HDL / physical-cost & silicon** — ROB/ports, netlist, cost lattice, AEU. (§II.10, 31 `silicon-zk` caps)
- `◇ C.9` **Systems & sovereign layer** — resolver/crystal, transpilers, containers, HTTP/net, verba. (§II.11, `resolver-crystal`/`transform-containers`/`verba`/`aether`-core caps)
- `◇ C.10` **Katabasis descent & Ring-0 deploy** — gate substrate + the on-metal kernel deploy. (§II.13, 14 `katabasis` caps + `KATABASIS-DEPLOY`)
- `◇ C.11` **Distributed BFT consensus & federation** — HotStuff + Sybil/eclipse/tier defense. (verification §IV.4, `aether` consensus caps)
- `◇ C.12` **Hardware realization** — the `R2-GENESIS` Verilog RTL of the resolver, completed. (verification §IV.4)
- `◇ C.13` **The "nothing ships unproven" gate stack** — determinism, seal, cartographer, drift, falsifier-first corpus. (§II.14)
- `◇ C.14` **Performance apex** — the final-form fast paths (the measured §III speedups taken to their ceiling). (§III)
- `◇ C.15` **Nous proposer** — the decision-guidance faculty. (28 `nous` caps)

---

## S · The substrate (final forms)

*(Designed first; the §C capabilities depend on these being final. Sections fill in as each design workflow lands.)*

### S.1 — The unified raw-limb arithmetic core `◇ designed`

**Final Form.** One arithmetic substrate, two layers, zero ambiguity. The **compute layer** is uniformly *radix-2³² digit · u64 accumulator*: every inner loop that multiplies, reduces, divides, or transforms operates on `u32` digits with a `u64` accumulator holding exactly one `(hi,lo)` digit pair — this is already true of Knuth-D (`KD_*`), the CIOS Montgomery (`MM_*`), and the NTT (`NTT_*`), and the apex makes it the *named, sole* compute contract. The **storage layer** stays *radix-2⁶⁴ `u64` limbs* in the proven 64-slot arena table — a thin, cheap bridge (`bigint_get_limb` → two `u32` halves) feeds the compute layer. Buffers in every hot path are *caller-owned and fixed*; allocation, where unavoidable, produces exactly one output handle and is hoisted out of the timed region. This is the substrate every §S and §C capability draws on, and it is the literal embodiment of the Harmony Charter H-1/H-2.

**Why this is the apex** (`/architect`). The decisive trade-off is **uniform-compute / retained-storage vs. a full radix-2³² rewrite of bigint storage** (proposed by one design angle). *Decision: uniform compute, retained `u64` storage* (**ADR-S1**). Rationale: the measured wins that matter — Knuth-D 177–258× (`990`), Montgomery 2.3–2.6× after CIOS (`991`), fe25519 6.9× (`992`) — *all already live in the compute layer*; the `u64`→`u32` split costs two shifts per limb and is invisible in the profiles. A storage rewrite touches every one of the 16 bigint-family files and every consumer for *no measured gain* and large regression risk — it violates "simple until proven otherwise." H-1 is satisfied where it pays (compute), and not imposed where it only risks (storage). The one place module-global buffers are mandatory is the documented `iiis-2` trap: a function-local `var [T;N]` indexed by a runtime variable SIGSEGVs, so `KD_*`/`MM_*`/`NTT_*` are module-global by necessity, not by accident — the apex *documents this as the invariant's backing*, so no future refactor "tidies" them into locals and crashes.

**Reinvented primitive — the `modulus_ctx` descriptor.** The one genuinely new primitive, and the keystone of substrate harmony. Today the bigint-width Montgomery (`mont_mul_bigint`) recomputes `n'` per call, and each NIST field (`fp256`, `fp384`, `fn256`, `fn384`) carries its *own* hand-rolled CIOS loop. The apex forges a single value type:

```
modulus_ctx = { s: u32,            // u32-digit count of n
                digits: [u32; s],  // n in radix-2^32, little-endian
                n_prime0: u32,      // -n^-1 mod 2^32  (== 1 for the NIST primes — free reduction)
                free_reduction: u8, // 1 iff n_prime0 == 1 (Montgomery-friendly)
                r2: [u32; s] }      // R^2 mod n, for one-shot to-Montgomery transforms
```

computed **once** per modulus and consumed by *both* the bigint modpow and every prime field. It is what lets one organ serve RSA, ECDSA's `fp256/fn256`, and P-384's `fp384/fn384` *without* any field losing its `n'[0]=1` free-reduction fast path. Old form: per-call `n'` recompute + four duplicated CIOS loops. New form: compute-once descriptor + one organ. *Why the old form was the ceiling:* duplication is the thing the Ripple Calculus (§V) flags as negative-`x` — four copies of one algorithm is four proof surfaces and four places a bug hides.

**Harmony ledger entry.** Exports to all of §S/§C: the `u32`-digit compute contract, the `modulus_ctx` descriptor, and the module-global-buffer invariant (with its `iiis`-trap justification). Assumes nothing below it — this is the floor.

---

### S.2 — Bigint arithmetic `◇ designed`

**Final Form.** Arbitrary-precision integers with a *single* multiply tower and a *single*, allocation-free Montgomery organ. Multiply dispatches by width through one ladder — schoolbook (`bigint_mul:646`) → AVX-512 8-limb (`_big_mul8_avx512:530`, AVX-512DQ-gated) → Karatsuba (`bigint_mul_karatsuba:106`) → 2-prime NTT (`bigint_mul_ntt:160`) — with the cutovers tuned to the radix-2³² digit count, not re-derived per caller. Division is Knuth Algorithm D on fixed `KD_*` limbs (the proven 177–258× oracle, unchanged). Modular exponentiation routes odd moduli through the **CIOS Montgomery organ** (`mont_mul_bigint:571`, now allocation-free, measured 2.3–2.6× faster than schoolbook+Knuth) — and the apex *elevates that organ* with a persistent `modulus_ctx` (no per-call `n'` recompute inside a 4096-bit modpow's ~6000 multiplies) and two **fused reductions**: `mont_mul_add` (`REDC(a·b)+c`, two accumulator passes not three) and `mont_mul_sq` (`REDC(a²)`, exploiting squaring symmetry to nearly halve the partial products). `q128` generalizes to a `@specialize`-monomorphized `q_generic⟨bits⟩` covering 128/256/512 from one source.

**Why this is the apex** (`/architect` + `/math-olympiad`). Trade-off **Montgomery-CIOS vs. Knuth-Barrett (KBR)** for the shared reduction organ. *Decision: CIOS Montgomery* (**ADR-S2**). Rationale: for modular *exponentiation* — the dominant cost in RSA and the reason this organ exists — Montgomery is the textbook winner because it removes division from the inner loop entirely, and the measurement agrees (991: 2.3–2.6× faster *after* the allocation fix). Barrett (the bold reinvention angle) needs a per-modulus reciprocal `μ` and a quotient correction *per multiply*; against `n'[0]=1` NIST-prime Montgomery (where reduction is nearly free) it cannot win, and it would re-open the proof surface the CIOS path already closes. Barrett is recorded as **considered-and-rejected**, retained only as the conceptual basis of Knuth-D's `q̂` estimate (which it already is). The `/math-olympiad` invariant that makes CIOS *provably* correct: after the interleaved multiply-reduce pass the accumulator is `< 2n`, so exactly **one** conditional subtraction canonicalizes — this is the loop post-condition the KAT must pin, not merely a round-trip.

**Reinvented primitives.**
- **`mont_mul_bigint` → a `modulus_ctx`-driven organ.** Old: recompute `n'` each call, one CIOS pass. New: accept `modulus_ctx` (precomputed `n'`, `r2`, `free_reduction`); the modpow caller builds the ctx once. *Old ceiling:* the per-call `mont_nprime64` Newton iteration (5 doublings) is wasted ~6000× in one RSA-4096 modpow.
- **`mont_mul_add`, `mont_mul_sq` (new fused ops).** Old: square-and-multiply modpow issues separate `REDC(a·a)` then `REDC(·)` then add. New: fuse the post-multiply add and the squaring into the CIOS pass. *Old ceiling:* three accumulator traversals where two suffice; squaring redundantly forms both `aᵢ·aⱼ` and `aⱼ·aᵢ`.
- **`q128` → `q_generic⟨bits⟩` (`@specialize`).** Old: a bespoke two-`u64` module. New: one generic body monomorphized to 128/256/512. *Old ceiling:* a fixed-width island that can't grow; three future width-modules become one.

**Ordered file-by-file change plan.**
1. `numera/bigint.iii` — **add** `modulus_ctx` as a slot-table value type (alongside the existing 64-slot model, no storage rewrite); **add** `mod_ctx_build(n) -> ctx_id` (computes `s`, `digits`, `n_prime0` via `mont_nprime64`, `free_reduction`, `r2`). Multiply ladder (`bigint_mul:646` + dispatch at `:570`) unchanged in behavior; **annotate** the radix-2³² cutover constants. *Why:* introduce the descriptor at the storage layer it lives in, without disturbing the proven core.
2. `numera/bigint_div.iii` — **refactor** `mont_mul_bigint:571` to accept a `ctx_id` instead of `n` (load `n'`, `digits` from the ctx; delete the per-call `mont_nprime64:547` call from the hot path, keep the function for `mod_ctx_build`). **Add** `mont_mul_add` and `mont_mul_sq` beside it on the same `MM_*` scratch. Knuth-D (`kd_*:222–336`) **unchanged** — it is the oracle. *Why:* this is where the organ lives; the ctx removes the only remaining per-call waste.
3. `numera/bigint_div.iii` — **refactor** `bigint_modpow_mont:705` to build the `modulus_ctx` once at entry and pass `ctx_id` through the square-and-multiply loop, calling `mont_mul_sq`/`mont_mul_add`. *Why:* the modpow is the sole place the per-call recompute was costing thousands of redundant Newton iterations.
4. `numera/q128.iii` — **rewrite** as `@specialize`-monomorphized `q_generic⟨bits⟩`; keep `q128_*` as the `⟨128⟩` instantiation (API-stable). *Why:* unify three potential width-modules into one; `/refactor` win.
5. `numera/bigint_karatsuba.iii` — **retune** `KARA_THRESHOLD`/`KARA_NTT_THRESHOLD` comments and values to the radix-2³² digit count (the NTT cutover is already correct at ~2048 digits). *Why:* make the dispatch boundaries speak one unit.
6. `numera/rsa.iii` — **route** `rsa_modexp` (`:388`) to the ctx-driven `bigint_modpow_mont`; build the ctx from the public modulus once per signature. *Why:* the consumer inherits the organ's win with no duplicated logic.

**Proof obligation upgrade.** Extend `corpus 759` (the bigint-Montgomery oracle): assert (a) `mont_mul_bigint(ctx,a,b) == a·b·R⁻¹ mod n` against an independent schoolbook+Knuth reduction at three RSA widths (already present), **plus** (b) the *negative arm* — feed an even modulus and a modulus with `n'[0]≠1` and assert the organ rejects/falls back rather than silently producing garbage, and (c) the loop post-condition `0 ≤ result < n` exactly (one conditional subtract suffices). `bench 991` already pins the speed reversal. Determinism: the ctx is pure-functional of `n`; the golden hash moves only if `mont_mul_bigint`'s emission changes (ADR-027) — a ctx refactor that preserves emitted bytes does **not** drift the seal.

**Harmony ledger entry.** Exports the `modulus_ctx` builder and the CIOS organ (`mont_mul_bigint`/`_add`/`_sq`) as the **shared reduction organ** every odd-modulus consumer reuses (§S.3 fields, §C.1 PQ, §C.2 RSA/ECDSA). Assumes §S.1's `u32`-digit compute contract and module-global `MM_*` invariant.

---

### S.3 — Prime-field & curve substrate `◇ designed`

**Final Form.** Every prime field collapses onto *one* reduction organ while *keeping* the per-prime fast path that earns its speed. The four NIST fields — `fp256`, `fn256`, `fp384`, `fn384` — stop carrying four hand-rolled CIOS loops (`fp_mul:162`, `fq_mul:130`, …) and instead each hold a static `modulus_ctx` (built once at `fp256_init`/`fp384_init`) and call the **shared** `mont_mul_bigint` organ — but because their `modulus_ctx` records `free_reduction=1` (the `p[0]=2³²−1 ⇒ n'[0]=1` property of the NIST primes), the organ takes its free-reduction branch and *no field loses a cycle*. `fe25519` stays sovereign: its multiply (`fz_mul:95`) keeps the pseudo-Mersenne reduction (`2²⁵⁶ ≡ 38 mod (2²⁵⁵−19)` ⇒ fold high limbs with `38·FZ_T[k+8]`, deferred freeze), the thing that makes it measured-6.9×; it is *not* absorbed, because Montgomery would be strictly slower for this prime. The curves (`ec256`, `ec384`) and their consumers (`ecdsa_p256/p384`, `x25519`, `crypt_ed25519`) are untouched at the call site — they inherit the dedup for free.

**Why this is the apex** (`/architect` + `/refactor`). Two trade-offs. **(1) Consolidate the four CIOS copies vs. keep them.** *Decision: consolidate through the descriptor-parameterized organ* (**ADR-S3a**) — four identical algorithms are four proof surfaces (the §V negative-`x` smell); routing them through one organ deletes ~150 duplicated lines and gives all four a single KAT, *while* the `free_reduction` flag preserves the `n'[0]=1` speed that naive consolidation would have thrown away (the subtle correctness/perf reconciliation the verification of `fp256.iii:10` made visible). **(2) Absorb `fe25519` into the generic organ vs. keep it specialized.** *Decision: keep specialized* (**ADR-S3b**) — `2²⁵⁵−19` is a pseudo-Mersenne prime; the `×38` fold is fundamentally cheaper than any Montgomery pass, and the bench proves it. Harmony does **not** mean "one code path for all"; it means "one organ where the algebra is the same, sovereign specialization where the algebra is genuinely different." That distinction is the architectural heart of this section.

**Reinvented primitives.**
- **Four per-field CIOS loops → one `modulus_ctx` + the shared organ.** Old: `fp_mul`/`fq_mul`/`fn_mul`/`fn384_mul` each inline CIOS with private scratch (`FP_T[10]`, `FQ_T`, …). New: each becomes a ~12-line wrapper (slots→`u32` buffer→`mont_mul_bigint(ctx)`→slots). *Old ceiling:* the duplication that made a reduction bug fixable in only one of four places.
- **`fe25519` deferred-freeze reduction → affirmed and documented as the pseudo-Mersenne sovereign path.** Not changed; promoted from "incidental" to "named invariant" so no future "unify everything" pass breaks it.

**Ordered file-by-file change plan.**
1. `numera/fp256.iii` — at `fp256_init`, **build** the static `modulus_ctx` for `p256` (`free_reduction=1`); **replace** `fp_mul:162`'s inline CIOS body (and the `FP_T[10]` scratch, `:24`) with a wrapper calling `mont_mul_bigint(ctx_p256, …)`. Keep the slot API (`fp_mul(r,a,b)`) byte-identical at the boundary. *Why:* delete the first CIOS copy; gain the shared KAT; keep `n'[0]=1`.
2. `numera/fn256.iii` — same transform for the P-256 *scalar* field (`fn_mul`), ctx from the curve order `n`. *Why:* second copy deleted.
3. `numera/fp384.iii` — same for `fq_mul:130` (12-limb), ctx for `p384`. *Why:* third copy.
4. `numera/fn384.iii` — same for the P-384 scalar field. *Why:* fourth copy; the four-into-one consolidation is complete.
5. `numera/fe25519.iii` — **no algorithmic change**; **add** a header invariant comment at `fz_mul:95` naming the pseudo-Mersenne `×38` reduction as the *sovereign* path and the reason it is exempt from ADR-S3a. *Why:* protect the measured 6.9× from a future over-unification.
6. `numera/field.iii`, `numera/field_crystal.iii`, `numera/galois.iii` — **audit** for any remaining inline reduction; route generic odd-modulus reduction to the organ, leave `GF(2⁸)`/characteristic-2 (`galois`) untouched (different algebra). *Why:* close the consolidation; respect the algebra boundary.
7. `numera/modular.iii` — **retain** as the fallback for non-Montgomery-friendly / even moduli; mark it explicitly as the generic escape hatch. *Why:* totality — the organ handles odd moduli; this covers the rest.

**Proof obligation upgrade.** One **field-reduction KAT** (extend `corpus 49`/`131` and the P-256/384 KATs): for each field, assert `mont_mul_bigint(ctx,a,b)` equals the field's pre-consolidation output bit-for-bit on a fixed vector set (a *differential* test against the retained reference) — this is the negative-armed guard that consolidation changed *nothing observable*. Plus: assert `free_reduction` actually fired for the NIST primes (a perf-invariant probe, advisory). `bench 992` pins `fe25519` stays specialized-fast. Determinism: the four wrapper rewrites change emitted bytes in `fp*/fn*` → the golden **does** move once, intentionally (a real reseal, ADR-027), and the differential KAT proves behavior held.

**Harmony ledger entry.** Exports: every NIST field now *consumes* the §S.2 organ (one proof surface for five fields' reductions); `fe25519` exports its sovereign-path invariant. Assumes §S.2's `modulus_ctx` + organ and §S.1's compute contract. §C.2 (classical crypto) and §C.1 (PQ, via `fp`-style arithmetic) inherit this directly.

---

### S.4 — The one NTT organ `◇ designed`

**Final Form.** The single modulus-parameterized NTT (`ntt_ct_forward_tabled:155`, `ntt_gs_inverse_tabled:191`) is affirmed as *the* transform organ — four consumers (ML-KEM `q=3329`, ML-DSA `q=8380417`, zk-STARK & entropy_monitor `q=998244353`) and the 2-prime Garner bigint-multiply (`bigint_mul_ntt:160`) share one Montgomery-tabled core, already lean (the speculative third Garner prime is *already* gone — `ntt_bigint.iii` is 2-prime `NB_P1/NB_P2`). The apex adds exactly one forward-looking capability and one piece of provability, and *resists* gratuitous change: a documented **REDC-fused inverse butterfly** horizon — `ntt_gs_inverse_redc` would fold the Montgomery reduction into the Gentleman-Sande butterfly (`b' = REDC(diff·ζ_mont)` inline) instead of a separate post-transform reduction pass, shrinking the inverse NTT's reduction count from O(n) trailing to fused-per-butterfly — staged but not yet cut, because the current organ is correct, shared, and on the measured-fast path.

**Why this is the apex** (`/architect`). The trade-off is **change vs. restraint**. *Decision: affirm + document, do not rewrite* (**ADR-S4**). Rationale: this organ is already the verification file's exemplar of harmony (one core, four primes); its scores from the design panel were deliberately *conservative* (ambition 6) precisely because the right move for a proven shared organ is to protect it, not to churn it. The single honest simplification the panel proposed (delete the third prime) was found **already done** on verification — a reminder that the apex of a finished thing is to *certify it finished*, add the next horizon as a named option, and move the energy to where it pays. The fused-butterfly horizon is real future speed (it removes a whole O(n) reduction sweep from every inverse NTT, i.e. every decaps/verify), but it is gated behind a differential KAT because a butterfly-fused reduction is exactly where an off-by-one in the Montgomery domain hides.

**Reinvented primitive (staged horizon).** **`ntt_gs_inverse_redc`** — old: inverse NTT then a separate mod-`q` normalization sweep. New (staged): Gentleman-Sande butterfly with inline `REDC`, output already in `[0,q)`. *Why the old form is the ceiling:* the trailing reduction sweep is pure overhead the algebra does not require; folding it in is the last constant-factor on the PQ hot path. Staged, not cut, per ADR-S4.

**Ordered file-by-file change plan.**
1. `numera/ntt_bigint.iii` — **no deletion needed** (the third prime is already absent); **update** the `NB_MAXN` comment (`:37`) to state the *true* 2-prime ceiling (~8192 limbs) rather than any speculative figure, and **add** a KAT-anchored note that `k1≠0` is exercised by `corpus 722–725`. *Why:* certify-finished; remove a stale ceiling claim.
2. `numera/ntt.iii` — **add** a module-docstring block (`:1–25`) naming the `ntt_gs_inverse_redc` REDC-fused-butterfly horizon, its expected win (one fewer O(n) sweep per inverse), and its gating KAT requirement. *Why:* the next-speed option is recorded where the next engineer will find it, not lost.
3. `numera/bigint_div.iii` — **add** a one-line cross-reference comment at `:542` linking the CIOS organ to the NTT's shared-organ pattern (both are "one core, many consumers"). *Why:* make the harmony explicit in-source.
4. *(staged, behind ADR-S4)* `numera/ntt.iii` — implement `ntt_gs_inverse_redc` + a differential KAT proving bit-identity to the current inverse-then-normalize on all four primes, *before* any consumer switches. *Why:* the horizon, cut only when its proof is green.

**Proof obligation upgrade.** Affirm `corpus 722–725` (NTT / convolve / bigint / large-route) as the organ's KAT; **add** the differential arm for the staged fused butterfly *when* it lands (bit-identity vs. the current path on all four moduli — the negative-armed guard against a Montgomery-domain off-by-one). Determinism: documentation-only changes do **not** move the golden; the staged butterfly, when cut, is a deliberate reseal gated on its differential KAT.

**Harmony ledger entry.** Exports the one NTT organ to §C.1 (PQ), §C.3 (zk-STARK), §S.2 (bigint-multiply); exports the fused-butterfly horizon as a named future. Assumes §S.1's compute contract and §S.2's `REDC` (which the staged butterfly would call inline).

---

> **§S.1–S.4 harmony summary (the architect backbone, now concrete).** One compute contract (radix-2³² digit, §S.1) · one reduction organ (CIOS Montgomery + `modulus_ctx`, §S.2) serving bigint modpow *and* all four NIST fields (§S.3) with the `n'[0]=1` free-reduction preserved · one sovereign exception where the algebra differs (`fe25519` pseudo-Mersenne, §S.3) · one transform organ (NTT, §S.4) serving four primes + bigint-multiply. Net `/simplify`/`/refactor` yield: **four duplicated field-CIOS loops deleted**, per-call `n'` recompute removed from every modpow, `q128` generalized to one `@specialize` body — a *leaner* substrate that is also *faster* (the §III.16 reversal is now structural, not incidental) and carries *fewer* proof surfaces. Every §C capability below compounds onto exactly this.
### S.5 — Hash / MAC / AEAD / KDF / RNG organ `◇ designed`

**Final Form.** A digest substrate where every primitive is a *thin composition over one shared core*, and the few that still hand-roll are brought into line. Three cores stand: **one Keccak-f[1600] sponge** (`keccak.iii:270`) already serving SHA3-256/512, SHAKE128/256, Keccak-256 *and* the seal chain's `cad`/`mhash` (§S.6); **one SHA-2 compression** (SHA-256/512) with the scalar↔AVX-512 **bit-identity dispatch** that `corpus 180/181/184` pins; **one Poly1305 MAC** (radix-2²⁶ `GF(2¹³⁰−5)`, `@constant_time`) feeding *all three* AEADs (ChaCha20-Poly1305, AES-GCM-via-GHASH, AES-SIV). The apex closes the last gaps to total uniformity: CPU-feature detection is **memoized once** (`cpufeat_summary_cached`) instead of re-probed per call; the KDFs (`hkdf`, `pbkdf2`) — today arena-allocating on every call (`hkdf.iii:39` `arena_new(8192)`) — gain **bring-your-own-buffer oneshot** variants on fixed module buffers (H-2); ChaCha20 gains the *same* force-path dispatch shape as SHA-256 (`cc20_block_dispatch`); and every documented buffer bound (`aes_siv` `SIV_TBUF[65536]` E2-SIV-1, `drbg` `DRBG_IN[1024]/SEED[768]` D-DRBG-1) becomes a *guarded* bound with a negative-armed test rather than a comment.

**Why this is the apex** (`/architect` + `/refactor`). This organ is already the verification file's exemplar of harmony, so the architect move is **completion, not reinvention** (the panel agreed — ambition 8, harmony 9). The decided trade-off is **H-2-purity vs. arena-convenience** in the KDFs: *decision — add oneshot fixed-buffer variants, retain the arena path* (**ADR-S5**), because a TLS handshake calls HKDF on a hot path where a per-call `arena_new(8192)` is exactly the allocation H-2 forbids, but the streaming arena API stays for the rare large-output case. The one honest limit named, not hidden: **AES uses a table S-box with a cache-timing side channel** (E2-AES-1); the apex *records this as a known limit* and stages a bitsliced/`@constant_time` AES as the horizon (the `prove` angle's contribution) rather than pretending the table is constant-time. The SHA-NI dispatch branch is today a software stub (`sha256_dispatch.iii:62` routes both paths to software) — the apex either completes the `SHA256RNDS2` path *or* deletes the dead branch; it does not leave a stub masquerading as a dispatch.

**Reinvented primitives.**
- **`cpufeat_summary_cached` (memoize).** Old: each crypto module re-runs CPUID/XGETBV on first use. New: one cached `u32` bitmask computed at substrate init. *Old ceiling:* repeated serializing CPUID in hot dispatch.
- **`hkdf_sha256_oneshot` / `pbkdf2_sha256_oneshot` (BYO-buffer).** Old: `arena_new` per call. New: fixed `*_WORK_*` module buffers, caller owns output. *Old ceiling:* allocation on the KDF hot path violates H-2.
- **`cc20_block_dispatch` (dispatch uniformity).** Old: ChaCha20 has one path; SHA-256 has a force-path selector. New: ChaCha20 gets the same `CC20_FORCE_PATH` (0=auto/1=scalar/2=avx2/3=avx512) so *all* vectorized primitives share one dispatch idiom and one bit-identity gate. *Old ceiling:* inconsistent dispatch = inconsistent test surface.

**Ordered file-by-file change plan.**
1. `numera/cpufeat.iii` — **add** `CPUFEAT_SUMMARY_CACHE:u32` + `CPUFEAT_CACHED:u8` + `cpufeat_summary_cached()` (compute once, return cached); point every `cpufeat_has_*` consumer at it. *Why:* one detection, memoized.
2. `numera/hkdf.iii` — **add** fixed `HKDF_WORK_{SALT[256],MSG[4096],T[32]}` + `hkdf_sha256_oneshot(salt,ikm,info,out,len)`; keep the arena path for >4096-byte outputs. *Why:* H-2 on the handshake hot path.
3. `numera/pbkdf2.iii` — **add** fixed `PBK_WORK_{SALT[256],MSG[4096],T,U}` + `pbkdf2_sha256_oneshot(pw,salt,iters,out,len)`. *Why:* same.
4. `numera/chacha20.iii` — **add** `CC20_FORCE_PATH`; rename `cc20_block`→`cc20_block_scalar`; add `cc20_block_dispatch`. *Why:* dispatch uniformity + a bit-identity gate matching SHA-256's.
5. `numera/sha256_dispatch.iii` — **resolve the stub** at `:62`: either implement the `SHA256RNDS2` SHA-NI path (gated `cpufeat_has_sha`) *or* delete the dead branch and state SW-only. *Why:* no stub masquerading as dispatch (H-4).
6. `numera/aes.iii` (+ `aes_gcm`, `aes_siv`) — **add** the documented buffer-bound *guards* (reject `pt_len > 65536` etc. with a distinct error) and a header note staging bitsliced constant-time AES. *Why:* turn E2-AES-1/E2-SIV-1 from comments into guarded, tested limits.

**Proof obligation upgrade.** Extend the AEAD KATs (`corpus 71/72`) with the **negative arm**: a one-byte tag/ciphertext flip must make `*_open` *reject* (return failure, not plaintext). Add the **buffer-bound falsifiers**: feed `SIV_TBUF`/`DRBG_IN` an oversize input and assert the new guard fails *closed* (the `prove-the-negative` mandate). Affirm the scalar↔AVX-512 bit-identity gates (`180/181/184`) extend to `cc20_block_dispatch`. Constant-time: a timing-invariance probe for Poly1305 (advisory). Determinism: the new buffers/oneshots don't change emitted hash bytes → golden unmoved unless the SHA-NI path lands (then an intentional reseal with a bit-identity gate to the SW path).

**Harmony ledger entry.** Exports the three cores (Keccak sponge, SHA-2 compression, Poly1305) as the shared digest organs to §S.6 (seal uses Keccak/SHA-2), §C.1 (PQ uses SHAKE/Keccak), §C.2 (signatures use SHA-2/512), §C.3 (zk uses Keccak for Fiat-Shamir). Assumes §S.7's arena for the retained streaming path.

---

### S.6 — The seal & content-address chain `◇ designed`

**Final Form.** The system's identity-and-integrity capability — owned today by no single file but emergent across `cad → mhash → merkle → witness` (the §V 300+-consumer chain) — becomes *one named organ with one proof surface*, and sheds its two structural liabilities. `cad.iii` (the dual-mode content-address collapse, `cad_oneshot:53` / `cad_begin…cad_final:120–169`) and `mhash` are the entry; `merkle.iii` is **parametrized by a hash-function pointer** so one tree serves both the SHA-256 seal and the Keccak-256 commitment instead of two; and `witness_spine.iii` — today a **2-mebi-entry open-addressing hash table** (`WSPINE_HT_IDX[1048576]`, a gospel-scale `.bss`) — is reinvented as a **radix-256 tree keyed by the 32-byte seal ID**: O(32) *deterministic-depth* lookup (no linear probe, constant-time), and *sparse* memory (the 2 Mi table evaporates). Reentrancy arrives via `seal_context_tag` opaque handles replacing the non-reentrant `CAD_ACTIVE` flag, and epochs gain **explicit Merkle-ladder roots** (`epoch_root[e] = Keccak256(intro ‖ [start,end) ‖ prior_root ‖ frags)`) instead of implicit from-zero replay. A new `seal.iii` makes the atomic seal fragment a first-class value, and **verifiable redaction** (`wh_redact` + `redaction_commit`) lets the witness *provably forget* without breaking the chain.

**Why this is the apex** (`/architect` + `/math-olympiad`). The decisive trade-off is **fused-atomic-seal-now vs. staged convergence**; *decision — stage it* (**ADR-S6**), because this chain has 300+ consumers and the byte-identity fixed-point depends on its emitted bytes, so the apex is reached by *increments each of which preserves the frag-id chain byte-for-byte* (Phase 1: route `witness_hook`'s three Keccak sites through `cad`, byte-identity preserved; Phase 2: the radix tree + reentrancy + epoch ladder, each behind a differential KAT). The radix-256 tree is the `/math-olympiad`-clean win: lookup depth is *exactly* 32 (one byte of the ID per level) — a **constant**, not an amortized average — which removes both the probe-cluster pathology *and* the 2 Mi worst-case allocation; the invariant to pin is "the radix tree returns the same fragment for every ID the HT did" (a total differential). Merkle hash-parametrization is the `/refactor` win: two near-identical tree builders collapse to one.

**Reinvented primitives.**
- **`witness_spine` open-addressing HT → radix-256 tree.** Old: `WSPINE_HT_IDX[1048576]` linear-probe (2 Mi `.bss`, probe-cluster worst case). New: 256-way radix tree on the ID bytes, O(32) deterministic, sparse. *Old ceiling:* a giant fixed table whose worst case is both slow and memory-enormous.
- **`CAD_ACTIVE` flag → `seal_context_tag`.** Old: one global "a seal is open" boolean (non-reentrant). New: opaque `u32` handles, each naming a distinct in-flight seal with its own scratch. *Old ceiling:* no concurrent/nested sealing.
- **`merkle` → hash-parametrized.** Old: separate SHA-256 and Keccak tree paths. New: `merkle_compute_root(leaves, n, leaf_size, hash_fn_ptr, out)`. *Old ceiling:* duplicated tree logic per hash.
- **Verifiable redaction (`wh_redact`/`redaction_commit`) — new.** Provable forgetting: a hole carries a commitment proving *what* was removed without revealing it.

**Ordered file-by-file change plan.**
1. `numera/witness_hook.iii` — **route** its three Keccak sites through `cad` (extern `cad_begin/payload/final`); **add** `WH_REDACTED` + `wh_redact`/`wh_is_redacted`/`wh_redaction_commit`. *Why:* Phase-1 byte-identity dedup + provable forgetting.
2. `numera/seal.iii` — **NEW** atomic-seal-fragment module (domain `producer‖opid‖in_commit‖out_commit`, Keccak256-sealed). *Why:* make the seal a first-class, testable value.
3. `numera/merkle.iii` — **parametrize** `merkle_compute_root` by `hash_fn_ptr`; keep the SHA-256 default as a wrapper. *Why:* one tree, two hashes.
4. `numera/witness_spine.iii` — **replace** `WSPINE_HT_*` open-addressing with `WSPINE_RADIX_*` (256-way tree); add `WSPINE_EPOCH_START` + Merkle-ladder `epoch_root`. *Why:* O(32)-deterministic, sparse, the gospel-BSS killed.
5. `STDLIB/scripts/build_stdlib.sh` — **register** `numera_seal` (after `numera_keccak`); **reorder** `numera_witness_spine` after `numera_merkle`. *Why:* build-safe dependency order.
6. `STDLIB/corpus/` + `run_corpus.sh` — **add** `witness_redact` (redaction falsifiers, codes 16–21) and `seal_spine_integration` (seal-id byte-identity + radix-vs-HT differential), registered `=99`. *Why:* the negative-armed proofs.

**Proof obligation upgrade.** The **differential** is the heart: the radix tree must return the *same* fragment for every ID the HT returned (total), and `seal_final` must equal a `Keccak256` recompute of the canonical preimage (byte-identity). The **negative arms**: a forged witness is rejected; a redaction whose commitment doesn't match is rejected (codes 16–21). Determinism: Phase 1 is byte-identity (golden unmoved); Phase 2's structural changes are an *intentional* reseal gated on the differential KAT — the seal chain *is* the golden's basis, so this is the one place a deliberate move is expected and proven safe.

**Harmony ledger entry.** Exports the one seal organ (`cad`→`mhash`→`merkle`→`witness`) + the atomic `seal.iii` to *every* sealing consumer (the compiler's byte-identity gate §C.4, the katabasis gate §C.10, the commit-gate §C.5, zk Merkle commitments §C.3). Consumes §S.5's Keccak/SHA-2 cores. This is the highest-fan-in organ in the system; its single proof surface is the system's integrity guarantee.

---

### S.7 — Arena / region / time substrate `◇ designed`

**Final Form.** The allocation-and-time floor that *backs* H-2 itself. One **handle-dispatch organ** (`tempaloc.iii`) replaces the per-module slot tables of `region`, `instant`, and `deadline` with a single type-discriminated table (`HANDLE_TYPE[512]`, one `tempaloc_slot_of(handle, expected_type)` doing one bounds-check + one falsifiable type-check). Reset becomes **provable**: `arena_reset_with_witness(arena, witness_hash)` requires the caller to pass `sha256(state_addr ‖ state_len)` and *verifies* it before resetting — so a reset can be *proven* correct rather than trusted — which **retires the advisory `clear_fn` registry entirely** (`arena_safe.iii` + `region_safe.iii` deleted: their `*_register_clear_fn` was caller-invoked-manually advice, never enforced). Time is made honest: `instant_tick` is a *deterministic logical counter*, so `deadline_in` stops dividing it by `1 000 000` as if it were `GetTickCount64` milliseconds (the confirmed `deadline.iii:74` bug) and instead treats the delta as logical ticks with explicit semantics. `calendar` gains a pure `cal_decompose_unix`, and a small `seal_organ` batches instant-seals so civil-time witnesses aren't recomputed.

**Why this is the apex** (`/architect` + `/simplify`). Two trade-offs. **(1) Per-module slot tables vs. one dispatch organ.** *Decision — unify* (**ADR-S7a**): `region`/`instant`/`deadline` each re-implement "allocate a slot, check it's live, check its type"; one `tempaloc` organ does it once with one proof surface, and the type discriminator makes a mis-typed handle a *caught* error, not UB. **(2) Advisory reset vs. provable reset.** *Decision — provable* (**ADR-S7b**): the `clear_fn` registry was the system's one un-enforced "trust me" — exactly the kind of advisory the `prove-the-negative` discipline forbids; replacing it with a witness-hash that the reset *checks* turns a convention into a theorem and lets two files (`arena_safe`, `region_safe`, 99 lines) be deleted. The deadline fix is a plain correctness repair (a logical clock is not a wall clock). Net `/simplify`: two files deleted, three slot tables collapsed to one, one real bug fixed.

**Reinvented primitives.**
- **`tempaloc_slot_of` (unified type-discriminated dispatch).** Old: three private slot tables. New: one `HANDLE_TYPE[512]` table, upper-byte type tag, single bounds+type check. *Old ceiling:* triplicated dispatch, no cross-type safety.
- **`arena_reset_with_witness` (provable reset).** Old: advisory `clear_fn` the caller might forget. New: reset verifies `sha256(state)` before proceeding. *Old ceiling:* an un-enforced convention in the allocation floor.
- **Logical-tick `deadline`.** Old: `delta_nanos / 1e6` on a non-millisecond counter. New: explicit logical-tick arithmetic. *Old ceiling:* a wall-clock assumption baked into a deterministic clock.

**Ordered file-by-file change plan.**
1. `memoria/tempaloc.iii` — **NEW** unified handle organ (`HANDLE_TYPE/LIVE/SLOT[512]`, `tempaloc_slot_of(handle,expected_type)`). *Why:* one dispatch, one proof surface.
2. `memoria/region.iii` — **delegate** slot dispatch to `tempaloc_slot_of(id, TYPE_REGION)`; remove `REG_TABLE`. *Why:* consume the organ.
3. `memoria/arena.iii` — **thin** to an `@inline` façade over `region`; **add** `arena_reset_with_witness`; remove `ARENA_INVALID`. *Why:* provable reset + dedup.
4. `memoria/arena_safe.iii`, `memoria/region_safe.iii` — **DELETE** (advisory `clear_fn` registry retired by ADR-S7b). *Why:* replace a convention with a theorem; −99 lines.
5. `tempora/instant.iii` — **delegate** to `tempaloc_slot_of(id, TYPE_INSTANT)`; **add** `instant_now_sealed` via the `seal_organ`. *Why:* unify dispatch; batch civil-time seals.
6. `tempora/deadline.iii` — **fix** `:74`: treat the delta as logical ticks; remove the `/1e6` ms conversion + the `GetTickCount64` comment. *Why:* correctness — logical clock ≠ wall clock.
7. `tempora/calendar.iii` — **add** pure `cal_decompose_unix(unix)->(y,m,d,h,mm,s)`; keep `cal_unix_to_civil` as a wrapper. *Why:* a side-effect-free decompose the seal organ reuses.
8. `memoria/seal_organ.iii` — **NEW** batch instant-seal (`seal_instant`/`seal_verify` with civil bounds-check). *Why:* don't recompute civil-time witnesses.
9. `STDLIB/scripts/build_stdlib.sh` — **register** `tempaloc`, `seal_organ`; **remove** `arena_safe`, `region_safe`. *Why:* build-safe.

**Proof obligation upgrade.** The **negative arm** that makes the reset a theorem: `arena_reset_with_witness` fed a *wrong* witness hash must *refuse* (return failure, not reset) — a falsifier that proves a reset can't be faked. A `tempaloc` mis-type test: a `TYPE_REGION` handle passed where `TYPE_INSTANT` is expected must be *caught*. A `deadline` correctness KAT in logical ticks (no wall-clock). Affirm `corpus 121–123` (arena/region reset-safe) against the new witness path. Determinism: deleting `arena_safe`/`region_safe` removes compiler-unreferenced symbols → does **not** drift `iiis-1/2` (per the determinism memory); the `tempaloc` refactor moves the golden once (intentional), gated by the reset/type falsifiers.

**Harmony ledger entry.** Exports the allocation discipline (caller-owned fixed buffers, provable reset) that *every* §S.2–S.5 hot path and §C capability assumes when it says "allocation-free"; exports the logical-clock and the `seal_organ`. This is the floor beneath H-2 — the reason "allocation-free hot path" is a checkable claim and not a hope.

---

> **§S.5–S.7 harmony summary (the substrate is now whole).** The digest cores (§S.5) *feed* the seal chain (§S.6: `cad`/`mhash`/`merkle` are Keccak/SHA-2 compositions), which *anchors* every consumer's integrity; the allocation-and-time floor (§S.7) *backs* the "allocation-free" claim that §S.2–S.5 all make. Cross-batch `/simplify` yield across §S.5–S.7: the 2 Mi witness `.bss` replaced by a sparse radix tree, two advisory `*_safe` files deleted, three time/alloc slot tables collapsed to one organ, two KDFs given H-2 oneshots, one real `deadline` bug fixed, one masquerading SHA-NI stub resolved — a substrate that is leaner, provable end-to-end (every reset/seal/reduction now has a negative-armed falsifier), and ready for every §C capability to compound onto. **The substrate (§S.1–S.7) is complete.**

## C · The capabilities (final forms)

### C.1 — Post-quantum cryptography (ML-KEM / ML-DSA / SLH-DSA) `◇ designed`

**Final Form.** The three FIPS schemes become *pure consumers* of the final substrate plus three crisp fixes. Every transform routes through the **one §S.4 NTT organ** via a per-modulus `ntt_ctx` descriptor (the §S.1 `modulus_ctx` pattern applied to transforms: `{q, zeta_addr, q_inv_neg, n}` prebuilt for `q∈{3329, 8380417, 998244353}`); every hash routes through the **one §S.5 Keccak sponge**, now leased from an 8-slot `keccak_sponge` pool (`lease`/`release` guards) so seed-expansion and Fiat-Shamir cannot race on a shared state buffer; every modular reduction is the **one §S.2 Montgomery** core. Three fixes land the verification findings: (1) a **unified `pq_params` descriptor** — nine prebuilt structs (`{scheme, level, n, q, k, l, eta, du, dv, …}`) with O(1) `descriptor[suite_id]` lookup — *retires* the fragile nibble arithmetic (`pq_dispatch.iii:43`, E-PQD-2, whose `0−1→u64::MAX` underflow was a real hazard); (2) a **sealed output ABI** — `iii_mldsa_sign_sealed(level, sk, msg, msglen, sig_out: *u8, sig_len_out: *u64) -> i32` — so the signature-length output is an *explicit* `*u64`, not the `siglen as *u8` cast that made the type lie about direction (`mldsa.iii:1041`, `slhdsa.iii:665`); (3) a **strict FIPS-205 family split** — `slhdsa_sha2.iii` (`H_msg = MGF1-SHA-256`) and `slhdsa_shake.iii` (SHAKE-256 throughout) — replacing the self-consistent-but-non-interoperable SHA-2/SHAKE hybrid, so III's SLH-DSA is wire-compatible with the FIPS-205 SLH-DSA-SHA2 and SLH-DSA-SHAKE families.

**Why this is the apex** (`/architect` + `/math-olympiad`). Trade-off **interoperable strict FIPS-205 vs. the self-consistent hybrid**: *decision — split to strict* (**ADR-C1**), because a post-quantum library whose signatures *only verify against itself* fails the one job of a standard (the hybrid was correct, just sovereign — and crypto interop is non-negotiable). Trade-off **descriptor table vs. nibble decode**: *decision — descriptor* — O(1) and unfalsifiable beats bit-extraction with an underflow guard bolted on. The `/math-olympiad` invariant the sealed ABI buys: the length write is now *type-checked* to land in a `u64` the caller owns, eliminating the class of bug where a length write past a too-small buffer corrupts the stack — the type system, not a comment, enforces it. Substrate reuse is total: the verification pass already proved the NTT serves four primes; the apex makes PQ *add zero* hand-rolled transform/hash/reduction code (H-3).

**Reinvented primitives.**
- **`pq_params` descriptor** (replaces six parameter functions + nibble decode). *Old ceiling:* arithmetic parameter encoding with an underflow hazard.
- **Sealed output ABI** (`*_sign_sealed` with explicit `*u64`). *Old ceiling:* a C-idiom cast that misrepresented parameter direction — an un-typed footgun.
- **`slhdsa_sha2` / `slhdsa_shake` (strict FIPS-205 split).** *Old ceiling:* a hybrid that broke interoperability.
- **`ntt_ctx` + `keccak_sponge` pool** (descriptors/pool over the §S organs). *Old ceiling:* per-scheme zeta init duplication + a single shared Keccak state that assumed single-threaded use.

**Ordered file-by-file change plan.**
1. `numera/pq_params.iii` — **CREATE** the nine-descriptor table + `pq_params_for(suite_id)`. *Why:* O(1) parameters, E-PQD-2 retired.
2. `numera/ntt_ctx.iii` — **CREATE** the per-`q` NTT descriptor over the §S.4 organ. *Why:* one transform, parameter-driven.
3. `numera/keccak_sponge.iii` — **CREATE** the 8-slot lease/release sponge pool over §S.5. *Why:* reentrant hashing, no race-on-reuse.
4. `numera/slhdsa_sha2.iii`, `numera/slhdsa_shake.iii` — **CREATE** the two strict FIPS-205 families; **RETIRE** `slhdsa.iii` (rename `…_sphincs_variant.iii`, header-deprecated, retained for back-compat). *Why:* interop.
5. `numera/mldsa.iii`, `numera/mlkem.iii` — **UPDATE** to consume `pq_params`/`ntt_ctx`/`keccak_sponge`; **add** the `*_sign_sealed` entry; keep the old entry as a deprecated wrapper. *Why:* substrate consumption + sealed ABI.
6. `numera/pq_dispatch.iii` — **REWRITE** as `pq_dispatch_sealed` over `pq_params` (single typed ABI; retire the dual direct/`_c4` interface confusion). *Why:* one router, one ABI.
7. `STDLIB/corpus/198,199,200` + new `pq_sealed_abi` KAT — **UPDATE/ADD**. *Why:* the proofs below.

**Proof obligation upgrade.** Add the **strict FIPS-205 KAT vectors** (interop oracle — a NIST vector must verify, and a vector from the *hybrid* must NOT verify against the strict family — the negative arm proving the split is real). Add the **AEAD-style negative arm** for KEM/sign: a one-bit-flipped ciphertext fails `decaps` to an *independent* shared secret (implicit-reject), a tampered signature fails `verify`. The **sealed-ABI falsifier**: a `sig_len_out` write is bounds-checked. Determinism: new descriptor/pool files are pure → golden unmoved; the FIPS-205 split changes emitted signature bytes for SLH-DSA → an intentional reseal gated on the interop KAT.

**Harmony ledger entry.** Consumes §S.2 (Montgomery), §S.4 (NTT via `ntt_ctx`), §S.5 (Keccak via the sponge pool). Exports `pq_params` + the sealed ABI as the PQ public surface; the FIPS-205 strict families are the canonical SLH-DSA (the zk batch's duplicate proposal defers here, §C.3). Adds **zero** hand-rolled substrate copies.

---

### C.2 — Classical crypto (RSA-PSS · ECDSA · Ed25519 · X25519) `◇ designed`

**Final Form.** Five classical schemes collapse onto the substrate through one `modparam` descriptor (`{id, modulus_bits, organ_id, reduction_tag}`) and shed their private duplicates. **RSA-PSS deletes its hand-rolled Montgomery** (`rm_mont_mul:593`, `rm_csub:553`, `rm_dbl:578`, `rm_extract:530`, ~100 lines) and routes `rsa_modexp` through the **§S.2 shared CIOS organ** — the *measured-fast* path (991: 2.3–2.6× over schoolbook+Knuth) that its private `rm_*` path was a slower, separately-proven copy of. **ECDSA-P256/P384 share the §S.3 unified NIST fields**; P-384 gains the deterministic RFC-6979 sign P-256 already has (`ecdsa_p384.iii:131`), and the dead non-exported `iii_ecdsa_p256_verify` (`:153`) is removed in favor of the exported `…_verify_x`. **X25519 and Ed25519 share `fe25519`** but tag every field op with an **algebra-kind** (`MONTGOMERY` for the X25519 ladder, `EDWARDS` for Ed25519) via a small `fz_algebra` dispatcher, so one field serves two curve forms *explicitly* rather than by convention; Ed25519's scalar reduction becomes a pseudo-Mersenne `ed_mod_l` (mirroring `fe25519`'s sovereign style) instead of a generic `bigint_mod`. A `bigint_io` organ unifies the big-endian/little-endian octet marshalling all four schemes hand-rolled.

**Why this is the apex** (`/architect` + `/refactor`). Trade-off **RSA's private Montgomery vs. the shared organ**: *decision — delete `rm_*`, route to §S.2* (**ADR-C2**), because two Montgomery implementations are two proof surfaces and one is measurably slower; the shared organ is the §III.16-reversed fast path, and deleting ~100 lines while *gaining* speed is the `/simplify` ideal. Trade-off **one field for two curves — implicit vs. tagged**: *decision — algebra-kind tags* — `fe25519` stays sovereign-fast (the §S.3 `×38` reduction), but the EDWARDS/MONTGOMERY tag makes the two curves' differing point laws *explicit and checkable* rather than a latent assumption. The dead-export removal is the cartographer-gate hygiene (one public verify, not two).

**Reinvented primitives.**
- **`modparam` descriptor** (one registry for RSA/P-256/P-384/Ed25519/X25519 moduli). *Old ceiling:* baked-in modulus constants per file.
- **RSA → §S.2 organ dedup** (delete `rm_mont_mul` et al.). *Old ceiling:* a private, slower, separately-proven Montgomery.
- **`fz_algebra` algebra-kind dispatch + `ed_mod_l` pseudo-Mersenne scalar.** *Old ceiling:* implicit curve-form sharing + a generic `bigint_mod` for a special prime `L`.
- **`bigint_io` (unified BE/LE marshalling).** *Old ceiling:* four hand-rolled `os2ip`/`i2osp` variants.

**Ordered file-by-file change plan.**
1. `numera/modparam.iii` — **CREATE** the modulus descriptor + `modparam_for(id)`. *Why:* one registry, no baked constants.
2. `numera/bigint_io.iii` — **CREATE** `bigint_to_octet`/`octet_to_bigint(…, endian)`. *Why:* one marshalling, four call sites unified.
3. `numera/rsa.iii` — **REFACTOR**: delete `rm_extract/rm_csub/rm_dbl/rm_mont_mul` (`:530–634`); route `rsa_modexp` (`:637`) through §S.2 `bigint_modpow_mont` with a `modulus_ctx` built once; use `bigint_io` for `os2ip`/`i2osp`. *Why:* the dedup + the measured-fast path.
4. `numera/ed_scalar_modl.iii` — **CREATE** `ed_mod_l` (pseudo-Mersenne `L = 2²⁵²+δ`). *Why:* the sovereign-style scalar reduction.
5. `numera/crypt_ed25519.iii` — **REFACTOR** `ed_hash_finalize` to call `ed_mod_l`; tag field ops `EDWARDS`. *Why:* substrate + explicit algebra.
6. `numera/fz_algebra.iii` — **CREATE** the algebra-kind dispatcher over `fe25519`. *Why:* one field, two curve forms, explicit.
7. `numera/x25519.iii` — **REFACTOR** field ops to the `MONTGOMERY` tag. *Why:* explicit ladder algebra.
8. `numera/ecdsa_p384.iii` — **REFACTOR** `iii_ecdsa_p384_sign_det` to DRBG-derived RFC-6979 `k` (match P-256). `ecdsa_p256.iii` — **STABLE** (the canonical pattern); remove dead `iii_ecdsa_p256_verify:153`. *Why:* deterministic sign everywhere; dead-export hygiene.

**Proof obligation upgrade.** Affirm the RFC oracles (7748 X25519, 8032 Ed25519, PSS, 6979 ECDSA — `corpus 73/59/74/75/373/913`). **Negative arms**: a forged signature is rejected; ECDSA enforces low-`S` (reject high-`S`, `corpus 972`); the RSA dedup is gated by a **differential** KAT (the §S.2-routed `rsa_modexp` is bit-identical to the deleted `rm_*` path on the same vectors — proving the dedup changed nothing). Constant-time probe for the X25519 ladder (`@constant_time` affirmed). Determinism: deleting `rm_*` changes `rsa.iii`'s emitted bytes → intentional reseal, gated on the differential KAT.

**Harmony ledger entry.** Consumes §S.2 (RSA Montgomery), §S.3 (NIST fields, `fe25519`), §S.5 (SHA-2/512 for PSS/Ed25519). Exports `modparam`, `bigint_io`, `fz_algebra` as classical-crypto infrastructure reusable by §C.10/§C.11 (TLS-like and consensus signing). Net: ~100 RSA lines deleted, one dead export removed, four marshalling copies unified.

---

### C.3 — Zero-knowledge: the composable zk-STARK `◇ designed`

**Final Form.** The zk-STARK graduates from a *demonstration* to a *general proving engine*. Today the AIR is hard-wired to one column and one constraint (`zk_stark.iii:10`: `x_{i+1} = x_i² + c`); the apex introduces a **general AIR DSL** (`zk_air.iii`): `air_compile` accepts column declarations (fixed/advice), polynomial **transition** constraints (degree ≤ 2 over shifted columns), and explicit **boundary** constraints, lowering them to a composition-polynomial generator — so the system can prove *arbitrary* low-degree constraint systems, not one toy recurrence. FRI folding becomes a **modulus-parameterized organ** (`ntt_fri_organ`) that shares the **§S.4 NTT** (so PQ and zk are *one* transform, `q=998244353` derived alongside the lattice primes), the trace/composition/FRI Merkle trees use the **§S.6 hash-parametrized `merkle`**, the Fiat-Shamir transcript hashes through the **§S.5 Keccak**, and the whole proof is **content-address-sealed** via the §S.6 chain (`zk_stark_seal`: `cad(trace_root ‖ cp_root ‖ fri_roots ‖ queries ‖ boundary)`) so a proof has a verifiable identity in the witness spine.

**Why this is the apex** (`/architect` + `/math-olympiad`). Trade-off **fixed demo-AIR vs. general DSL**: *decision — generalize* (**ADR-C3**), because a zk system that can only attest `x²+c` proves nothing anyone needs; the AIR DSL is the difference between a benchmark and a capability, and the `/math-olympiad` rigor is in the soundness argument staying intact — degree-≤2 transition constraints keep the composition polynomial's degree bounded so the FRI low-degree test remains complete and sound. Trade-off **a private FRI-NTT vs. the shared organ**: *decision — share* — FRI's butterfly *is* an NTT; routing it through §S.4 means the (staged) REDC-fused butterfly horizon (ADR-S4) speeds zk *and* PQ at once. The proof-sealing is the harmony capstone: a STARK proof becomes a first-class sealed artifact in the same content-address chain (§S.6) that anchors the compiler and the gate.

**Reinvented primitives.**
- **General AIR DSL (`air_compile`).** Old: one hard-coded constraint. New: a constraint-system compiler (columns + polynomial transition/boundary). *Old ceiling:* a single-recurrence demo masquerading as a prover.
- **`ntt_fri_organ` (modulus-parameterized FRI over §S.4).** Old: inlined field/fold ops in `zk_stark.iii`. New: one folding organ shared with PQ. *Old ceiling:* a private transform duplicating the NTT.
- **`zk_stark_seal` (content-address proof commitment).** Old: a proof was an anonymous byte blob. New: a sealed artifact with an identity in the witness spine (§S.6).

**Ordered file-by-file change plan.**
1. `numera/zk_air.iii` — **CREATE** the AIR compiler (`air_compile(constraints, n) -> ctx`, type-checker, composition-poly generator). *Why:* general circuits.
2. `numera/ntt_fri_organ.iii` — **CREATE** `fri_commit_layer`/`fri_eval_and_fold` over the §S.4 NTT (modulus-parameterized). *Why:* one transform for PQ + zk.
3. `numera/ntt.iii` — **ADD** `ntt_mult_field_elem(a,b,q,ω)` export (the field-mul the FRI organ needs). *Why:* expose the organ primitive cleanly.
4. `numera/zk_stark.iii` — **REFACTOR**: delete inlined `st_build_lde_cp`/`st_fs_field_compute` field ops (now in organs); consume `zk_air` + `ntt_fri_organ` + the §S.6 `merkle`. *Why:* substrate consumption; ~100 lines deleted.
5. `numera/zk_stark_seal.iii` — **CREATE** `zk_stark_proof_cad(proof_ctx)` over the §S.6 `cad`/`merkle`. *Why:* sealed proof identity.
6. `numera/zk_prune.iii` — **EXTEND** with `zkp_stark_sidecar_build` (AIR-aware pruning). *Why:* prune general circuits.
7. *(SLH-DSA strict FIPS-205 is owned by §C.1; this batch's duplicate proposal is dropped — one canonical home.)*

**Proof obligation upgrade.** Affirm `corpus 376` (prove→verify round trip) and **generalize** it: prove a *multi-column* constraint system end-to-end (the AIR DSL's existence proof). **Negative arms**: a proof with a tampered FRI layer is rejected; a witness that violates a transition constraint fails to prove; the sealed proof's `cad` mismatches if any commitment is altered (the seal's negative arm). Determinism: the AIR DSL + organs change `zk_stark.iii` emission → intentional reseal, gated on the round-trip + negative KATs.

**Harmony ledger entry.** Consumes §S.4 (NTT via `ntt_fri_organ`), §S.5 (Keccak Fiat-Shamir), §S.6 (`merkle`/`cad` for commitments + proof seal). Exports the AIR DSL as a *general verifiable-computation* surface reusable by §C.5 (proof-carrying) and §C.13 (the gate's proofs). The FRI/NTT sharing means §S.4's fused-butterfly horizon accelerates zk and PQ together.

---

> **§C.1–C.3 harmony summary (crypto is now pure substrate-consumer).** All three families add **zero** hand-rolled transform/hash/reduction code: PQ and zk share the **one NTT** (§S.4); RSA, ECDSA, and PQ share the **one Montgomery** (§S.2); every scheme hashes through the **one Keccak/SHA-2** (§S.5); zk's proofs and the witness seal through the **one chain** (§S.6). The verification findings are closed: the SLH-DSA hybrid → strict FIPS-205 families, the output-param ABI → sealed `*u64`, RSA's private Montgomery → the shared organ (~100 lines deleted), the dead ECDSA export removed, the fixed demo-AIR → a general DSL. Crypto is *leaner* (duplicates deleted) and *more interoperable* and *more general* — built entirely on a substrate that was already proven final.

### C.4 — Self-hosting compiler & byte-identity reseal `◇ designed`

**Final Form.** The crown jewel keeps its proof and sheds its triplication. The proof is unchanged and supreme: the **byte-identity fixed-point** (`build_iiis2.sh --check-corpus` compiles all 59 `stage1_corpus` programs through *both* `iiis-1` and `iiis-2` and asserts byte-identical `.o` — verified 59/0), backed by determinism env (`LC_ALL=C/TZ=UTC0/SOURCE_DATE_EPOCH=0`) and the `mhash`/`witness.json` seal (§S.6). Three unifications land on top. **(1) One proof carrier** (`proof_term.iii`): an algebraic *union* of phase certificates (`lex/parse/sema/sid/walloc/cg/link`, 32–48 B each) on a fixed 64 KB arena (§S.7), sealed into an append-only lattice once `sema` completes — *retiring nine hand-rolled error-record structs* (`ERR_LEX[24]`/`ERR_PARSE[48]`/`ERR_SEMA[32]`/… in `main.iii`). **(2) One ring-agnostic emitter** (`emit_generic.iii`, parametrized by `ring_config_t = {register_table[16], calling_conv_cb, opcode_lut[256], reserved_ranges}`): the four codegens (`cg_r3/r0/rm1/rm2`) differ *only* in register table, calling convention, reserved kernel ranges, and opcode encoding — their `emit_block/emit_stmt/emit_expr/emit_opcode` *logic* is identical, so it collapses to one emitter with per-ring config (the verification pass already found `cg_r3` serves all rings by auto-detect — this makes it explicit; ~970 lines of duplicated emit bodies deleted from `cg_r3` alone). **(3) One XII-lowering organ** (`xii_organ.iii`, *shared with §C.6*). And `main.iii`'s privately-inlined SHA-256 routes to the §S.5 organ (dedup with `ceiling.iii`).

**Why this is the apex** (`/architect` + `/math-olympiad`). The trade-off is **four ring codegens vs. one parametric emitter under the byte-identity gate**: *decision — unify via `ring_config_t`* (**ADR-C4**), because the gate makes the refactor *provably safe* — the unified emitter must reproduce every current `.o` byte-for-byte or `--check-corpus` reddens, so the most aggressive dedup in the system (970 lines) is also the most safely verifiable (the verification pass demonstrated the gate catches a controlled emitter break → 0/57). The `/math-olympiad` insight: the byte-identity fixed-point is a *machine-checked theorem* that `iiis-2 = iiis-2 ∘ iiis-2` on the corpus — the compiler is its own proof object, and the apex preserves that exactly while shrinking the trusted surface from four emitters to one + four configs.

**Reinvented primitives.**
- **`proof_term` unified certificate** (union of phase certs on a sealed lattice). *Old ceiling:* nine ad-hoc error structs, no composable transcript.
- **`emit_generic` + `ring_config_t`** (one emitter, four configs). *Old ceiling:* four near-identical emit bodies — four places a codegen bug hides.
- **`xii_organ`** (shared lowering engine, §C.6). *Old ceiling:* compiler-side and stdlib-side XII lowering as separate implementations.

**Ordered file-by-file change plan.**
1. `COMPILER/BOOT/ring_config.iii` — **NEW** `ring_config_t` + the four ring configs (R3/R0/RM1/RM2). *Why:* isolate the per-ring differences.
2. `COMPILER/BOOT/proof_term.iii` — **NEW** the phase-certificate union + sealed lattice (`proof_lattice_seal`/`_emit_*_cert`) on the §S.7 arena, §S.6-sealed. *Why:* one composable proof transcript.
3. `COMPILER/BOOT/emit_generic.iii` — **NEW** the parametric emitter (`emit_state_t`, generic register alloc, `ring_config`-driven dispatch). *Why:* one emit logic.
4. `COMPILER/BOOT/cg_r3.iii` — **REFACTOR**: delete `emit_block/stmt/expr/opcode` bodies (~970 lines); keep R3 config + `iii_cg_r3_create`. `cg_r0/rm1/rm2.iii` — **REFACTOR**: delegate to `emit_generic`, retain ring-specific config (R0 syscall ABI, RM1/RM2 register alloc). *Why:* the four-into-one dedup, gate-proven.
5. `COMPILER/BOOT/sema.iii`, `main.iii` — **INTEGRATE** the proof lattice (seal after `sema_run`, emit per-phase certs); route `main.iii`'s SHA-256 to §S.5. *Why:* the transcript + the hash dedup.
6. `COMPILER/BOOT/xii_organ.iii` + `cg_r3_xii_adapter.iii` — **NEW/REFACTOR** to the shared lowering organ (§C.6). *Why:* one XII organ across compiler + stdlib.

**Proof obligation upgrade.** *The* proof is `build_iiis2.sh --check-corpus` = **59/0 byte-identical** — the unified emitter is the ultimate differential KAT (every `.o` byte-stable through the refactor, or the golden moves and the gate fails). Negative arm: a deliberate `emit_generic` perturbation must redden `--check-corpus` (the verification pass proved this works → 0/57). Determinism: this is the one capability where the golden *is* the deliverable — any intended emitter change is a deliberate, gate-proven reseal (ADR-027); the proof-lattice/config files are pure → no drift unless emission changes.

**Harmony ledger entry.** Consumes §S.5 (SHA-256), §S.6 (`mhash`/witness seal), §S.7 (the cert arena). Exports `proof_term` (the proof-term IR §C.5 reuses) and `xii_organ` (the lowering organ §C.6 reuses) — two of this batch's deepest cross-capability unifications. *(Design only; the live compiler/reseal is not edited here.)*

---

### C.5 — Math / logic / verification substrate `◇ designed`

**Final Form.** The verification faculties converge on *one proof-term IR and one composing gate*. The four proof carriers (`theorem_carrier`, `proof_carrying`, `proof_term`, `curry_howard`) collapse into the **same proof-term IR the compiler forges in §C.4** — a single Curry-Howard term language in which a lexer certificate, a SAT refutation, a bisimulation witness, and a constitution verdict are all *the same kind of object* (H-3 across the compiler/logic boundary). The **e-graph** is promoted to a first-class integrity organ: its undersold `GF(2⁸)` Reed-Solomon + Keccak-Merkle *self-heal* (`egraph.iii:29,95`) becomes a named, reusable resilience layer (any module's node stream can self-correct). **Bisimulation** (`computation_graph.iii`) keeps its iron rule — *no equivalence claim without a witness* — now emitting that witness as a proof-term. **LTL bounded model checking** (`temporal_logic.iii`, `corpus 644`) and the **constitution 11-opcode admissibility VM** (`constitution.iii:79-89`) are affirmed and re-expressed over the shared IR. And the **commit-gate becomes the explicit apex composer**: `cg_decide` (`commit_gate.iii:68`) does not *reimplement* soundness — it *composes* five organs into one verdict — RULE soundness (the §C.6 XII admission), constitution admissibility (the VM), ripple soundness (§C.7), seal integrity (§S.6), and the KERNEL dimension (the prover itself) — refusing a self-edit with `CG_REJECT_KERNEL` precisely when the prover underwriting every other verdict is down (`corpus 864`).

**Why this is the apex** (`/architect` + `/math-olympiad`). Trade-off **per-subsystem proof carriers vs. one Curry-Howard IR**: *decision — unify* (**ADR-C5**), because the compiler (§C.4), the logic kernel, and the gate all need "a proof object that composes," and four dialects is three translation layers and four proof surfaces; one IR makes a compiler certificate and a SAT refutation *composable in the same gate*. The `/math-olympiad` discipline is enforced structurally: bisimulation/confluence proofs must **drive different rules on each side** (a same-term-twice "proof" is rejected — the project's no-tautological-proof law), and LTL is honestly *bounded* (it refutes within depth `k`, it does not claim unbounded liveness — the limit is named, not hidden). The commit-gate's composition is the architectural climax: soundness is *assembled*, not re-asserted, and its kernel-refusal is the system's "do not edit yourself while blind" theorem.

**Reinvented primitives.**
- **One Curry-Howard proof-term IR** (shared with §C.4's `proof_term`). *Old ceiling:* four proof carriers that couldn't compose.
- **E-graph self-heal as a named organ** (`GF(2⁸)` RS + Keccak-Merkle). *Old ceiling:* a powerful resilience layer buried inside `egraph`, unusable elsewhere.
- **Commit-gate as explicit 5-organ composer.** *Old ceiling:* the composition was implicit; making it explicit lets each dimension's proof be inspected.

**Ordered file-by-file change plan.**
1. `numera/proof_term.iii` (+ `theorem_carrier.iii`, `proof_carrying.iii`, `curry_howard.iii`) — **CONSOLIDATE** into one Curry-Howard IR aligned with §C.4's `proof_term`; keep thin compatibility wrappers. *Why:* one composable proof object.
2. `numera/egraph.iii` — **EXPORT** the RS+Merkle self-heal (`eg_selfheal`) as a standalone integrity organ; affirm `eg_find:364`/`eg_union:434`. *Why:* reuse the resilience.
3. `numera/computation_graph.iii` — **AFFIRM** the witness-or-abstain rule; emit the bisimulation witness as a proof-term. *Why:* no equivalence without a witness, now composable.
4. `numera/temporal_logic.iii`, `constitution.iii`, `constitution_preserver.iii`, `induct.iii` — **RE-EXPRESS** verdicts over the shared IR; affirm the 11-opcode VM and the bounded-`k` honesty. *Why:* one verdict type.
5. `omnia/commit_gate.iii` — **REFACTOR** `cg_decide:68` to compose the five organ-verdicts explicitly (each a proof-term), preserving `CG_REJECT_KERNEL`. *Why:* the apex composition, inspectable.
6. `numera/sat*.iii`, `smt.iii`, `category.iii`, `sheaf.iii`, `groebner.iii`, `quine_verifier.iii`, `typecheck.iii`, `ccl.iii` — **ROUTE** their certificates through the IR. *Why:* the whole logic tree speaks one proof language.

**Proof obligation upgrade.** The commit-gate's **negative arm** is the headline: with the prover forced down, `cg_decide` must return `CG_REJECT_KERNEL` (refuse), not admit (`corpus 864` exercises every reject arm). Confluence/bisimulation KATs must **drive different rules each side** (the no-tautological-proof guard). LTL: a property false within `k` is refuted; one true-only-beyond-`k` is honestly *not* claimed. Determinism: the IR consolidation changes emitted bytes in the logic modules → an intentional reseal gated on the gate + bisimulation negative arms.

**Harmony ledger entry.** Consumes §S.5 (Keccak for e-graph Merkle), §S.6 (seal), §C.4's `proof_term` IR. Exports the composed commit-gate (the admission authority §C.10/§C.13 invoke) and the e-graph self-heal organ. The gate *composes* §C.6 (XII rules) + §C.7 (ripple) + the constitution + the seal — the densest composition in the system.

---

### C.6 — XII term-rewriting system `◇ designed`

**Final Form.** The ~40-file XII constellation resolves into *one term organ, one confluence certifier, one lowering organ*. `xii_term` (the 157-fan-in term substrate) and the rewrite engine become a canonical **`xii_organ`** — *the same organ the compiler lowers through in §C.4* — with `apply_one`'s in-place-mutation contract made explicit (firing detected by `xii_rewrite_last_rule_fired`, never `next == cur`, per the hard-won trap). The confluence machinery (`xii_rule_overlap` → `xii_critpair_enum` → `xii_joinability` → `xii_conf_cert`) collapses into one **certifier** that, given an admitted rule set, emits a confluence certificate *or rejects*; `xii_termination` rides alongside. The seven lowering passes (`xii_lower_{compose,decide,iterate,program,then,under,with}`) become one parametric lowering pipeline inside `xii_organ`. Confluence and termination remain certified **per admitted rule set** (the honest scope — not the undecidable global claim), and the curated payloads (`xii_curated_*`) are the proven rule corpus.

**Why this is the apex** (`/architect` + `/refactor`). Trade-off **seven lowering files + a scattered confluence pipeline vs. one organ + one certifier**: *decision — unify* (**ADR-C6**), because the seven lowering passes share a term-walk skeleton and the four confluence files are one pipeline cut into stages; consolidating them gives one rewriting organ with one KAT surface, and — the deepest harmony — *that organ is identical to the compiler's `xii_organ` (§C.4)*, so the language's own lowering and the stdlib's term rewriting stop being two implementations of one idea. The `/math-olympiad` honesty is the scope discipline: the certifier proves *these* rules confluent/terminating (critical pairs joinable, a terminating order exists), and is explicit that the general problem is undecidable — it certifies, it does not claim to have solved Church-Rosser in general.

**Reinvented primitives.**
- **`xii_organ`** (unified rewrite + 7-pass lowering, shared with §C.4). *Old ceiling:* seven lowering files + a compiler-side copy.
- **One confluence certifier** (`overlap→critpair→joinability→conf_cert` as one). *Old ceiling:* a four-file pipeline with four proof surfaces.
- **Explicit `apply_one` firing contract.** *Old ceiling:* the in-place/`last_rule_fired` subtlety lived in tribal memory, a latent bug magnet.

**Ordered file-by-file change plan.**
1. `omnia/xii_organ.iii` — **NEW/CONSOLIDATE** the rewrite engine + the seven `xii_lower_*` passes into one parametric organ (shared with §C.4); affirm the `xii_rewrite_last_rule_fired` firing contract. *Why:* one rewriting organ.
2. `omnia/xii_conf_cert.iii` — **CONSOLIDATE** `xii_rule_overlap`/`xii_critpair_enum`/`xii_joinability` into one certifier emitting a confluence certificate or a rejection. *Why:* one confluence proof surface.
3. `omnia/xii_termination.iii` — **AFFIRM** the terminating-order check; integrate with the certifier. *Why:* total certification (confluent ∧ terminating).
4. `omnia/xii_admission.iii` — **REFACTOR** to gate rule-set admission on a green confluence+termination certificate (reject non-confluent sets). *Why:* the negative arm — bad rule sets don't enter.
5. `omnia/xii_curated_*.iii` — **AFFIRM** as the proven rule corpus; route through the unified admission. *Why:* the curated payloads are the trusted rules.
6. `omnia/xii_canonicalise.iii`, `xii_term.iii` — **AFFIRM** as the shared term substrate the organ walks. *Why:* one term representation (the 157-fan-in organ).

**Proof obligation upgrade.** The XII corpus band (280–372, delegated to `run_xii_corpus.sh`) is the organ's KAT. **Negative arms**: a non-confluent rule set is *rejected* by admission (not silently lowered); a critical pair that fails to join fails the certificate; the confluence test **drives different rules on each side** (the no-tautological-proof law). Affirm `apply_one`'s firing detection via `last_rule_fired`. Determinism: consolidating the lowering/confluence files changes emitted bytes → intentional reseal gated on the XII band + the non-confluence rejection arm.

**Harmony ledger entry.** Exports `xii_organ` (shared with §C.4 compiler lowering) and the confluence certifier (consumed by §C.5's commit-gate RULE dimension). Consumes §S.6 (seal for the curated-payload integrity). The compiler/logic/XII triangle now shares two organs (`proof_term`, `xii_organ`) — the batch's defining unification.

---

### C.15 — Nous proposer (sound-move-only decision guidance) `◇ designed`

**Final Form.** The proposer becomes a *lattice of proven-sound moves with proof witnesses* — and **never** a learner. Three primitive structures (a hardcoded 49-element reorder permutation, a 3-outcome trichotomy, a flat 9-byte tag) unify into a proof-witnessed algebra: **NOL** (Nous Order Lattice) — a block-partitioned directed graph of *proven-safe* reorderings (must-fire-first / general / trit blocks), replacing `nous_socket`'s hardcoded arrays with reorders each carrying a soundness proof; **QVT** (Qualified Verdict Type) — `{outcome, proof_weight, proof_cad, completion_bound}`, replacing the bare trichotomy with a *typechecked, sealed* verdict; **RCM** (Recursive Certificate Merkle) — a binary proof tree (leaves = `(pair_id, join_witness)`), replacing the flat 9-byte completion tag and fixing CUT-11's vacuity *recursively* (the cert now binds the whole `(n_pairs, budget, verdict)` derivation, not a 4-byte stub). The decoupling is the point: **what is safe to do** is proven once and static (NOL); **what to try next** is the dynamic proposer over that proven-safe set. The kernel (§C.5) proves and decides; the proposer only *proposes from a proven-sound move-set*.

**Why this is the apex** (`/architect` + the no-ML invariant). The non-negotiable trade-off is **statistical proposer vs. proven-sound proposer**: *decision — proven-sound, always* (**ADR-C15**) — III forbids observational/statistical learning (count-and-promote, observe-and-adapt, threshold-trigger are ML in disguise), so the proposer's moves are members of the NOL, *each a theorem of safety*, and the proposer's only freedom is *ordering* within the proven-safe set, never *inventing* a move from observed frequencies. This is the Ripple-Calculus discipline (§C.7) applied to proposal: propose freely *within the proven-sound lattice*, the kernel decides. The `/math-olympiad` upgrade is RCM's non-vacuity: CUT-11 proved a 4-byte tag made every certificate identical (vacuous); the recursive Merkle cert is *provably* distinct per derivation — a negative-armed fix to a real vacuous-proof bug.

**Reinvented primitives.**
- **NOL** (proven-safe reorder lattice). *Old ceiling:* a hardcoded 49-permutation with no soundness witness.
- **QVT** (qualified, sealed verdict). *Old ceiling:* a bare 3-outcome enum carrying no proof.
- **RCM** (recursive certificate Merkle). *Old ceiling:* the 4-byte vacuous CUT-11 tag.

**Ordered file-by-file change plan.**
1. `nous/nous_lattice.iii` — **NEW** NOL: the block-partitioned proven-safe reorder graph + `nol_propose(ctx, kind)`. *Why:* sound reorders, witnessed.
2. `nous/nous_verdict.iii` — **NEW** QVT: `{outcome, proof_weight, proof_cad, completion_bound}` + `qvt_classify`. *Why:* typechecked, sealed verdicts.
3. `nous/nous_rcm.iii` — **NEW** RCM: the recursive certificate Merkle (fixes CUT-11 recursively). *Why:* non-vacuous completion proof.
4. `nous/nous_socket.iii`, `nous_policy.iii` — **RETIRE** the hardcoded `NOUS_CASCADE`/`NOUS_ASCEND` arrays and the kind-aware reorder; re-express as NOL queries. *Why:* delete the unwitnessed reorders.
5. `nous/nous_search.iii`, `nous_completion.iii`, `nous_commons.iii` — **REFACTOR** to consume QVT/RCM; `nous_search` stays the e-graph client; `nous_commons` uses the RCM cost-hint for resumption priority. *Why:* the dynamic proposer over the proven-safe lattice.

**Proof obligation upgrade.** The defining **negative arm**: the proposer *abstains* on any move not in the NOL (an unproven reorder is never proposed — the no-ML guard made executable). RCM non-vacuity: two different `(n_pairs, budget)` derivations must yield *different* certificates (the CUT-11 falsifier). A structural check that **no statistical/observational learning exists** in the proposer path (sound-move-only). Determinism: new lattice/verdict/RCM modules change `nous` emission → intentional reseal gated on the abstention + non-vacuity arms.

**Harmony ledger entry.** Consumes §S.6 (Merkle/`cad` for RCM and `proof_cad`), §C.5 (the kernel that proves/decides), §C.7 (the Ripple-Calculus propose-freely/kernel-decides discipline). Exports the NOL/QVT/RCM proposer surface to §C.7's ripple loop. The proposer is the system's one "creative" faculty — and the apex keeps it creative *only within the proven-sound*.

---

> **§C.4–C.6 + C.15 harmony summary (the reasoning core shares organs).** The compiler (§C.4), the logic kernel (§C.5), and XII (§C.6) now share **two** organs — one `proof_term` Curry-Howard IR and one `xii_organ` lowering engine — so a compiler certificate, a SAT refutation, and an XII confluence proof are *the same kind of object*, composable in *one* commit-gate (§C.5) that assembles RULE-soundness (§C.6) + constitution + ripple (§C.7) + seal (§S.6) + the prover into a single admit/reject. The proposer (§C.15) feeds that gate *only proven-sound moves* — never a learned one. Net: four proof carriers → one IR, seven XII lowering files + four confluence files → two organs, the proposer's three primitive structs → one witnessed lattice algebra, and the compiler's four emit bodies → one config-driven emitter — all under the byte-identity fixed-point that proves the compiler is its own theorem.

### C.7 — Ripple Calculus & emergent self-optimization `◇ designed`

**Final Form.** The system's self-measurement-and-self-refactoring becomes *one move-IR, one proof oracle, one driver* — the apex of the apotheosis method itself, since this is the loop that *performs* apotheosis on the live tree. The five components (`ripple_metric` G2, `ripple_search` G3, `ripple_loop`, `ripple_cut`, `ripple_extract`) unify under a canonical **`ripple_term`** move IR — `move_merge(i,j,π) | move_cut(e,π) | move_extract(f,exports,π)` — every structural move is one value in one type. A **`proof_ripple_unified`** organ collapses the five proof dimensions into one decider: `proof_ripple_decision(t) → crystal_id` mints *iff all five proofs hold* (capability-conservation, MDL-improvement, acyclicity, congruence-faithfulness, H10 anti-thrashing), else rejects. A **`ripple_synthesizer`** is the single driver — `propose → value(`J`) → select(argmax) → prove → apply-or-abstain` — with `ripple_loop/search/cut/extract` retained as its subroutines. The metric is unchanged in spirit and *structurally ML-free*: `J = good − noise − separation` (MDL) reads **only sealed structural fields** (primitive-identity 0–23, hexad-kind 1–7), **never** call counts or timings — the no-observational-learning invariant made mechanical. The decider is `commit_gate.cg_decide_ripple(t)`, so a move is admitted only when the prover is up (else `CG_REJECT_KERNEL` blocks *all* moves — the loop self-edits nothing while blind). The executor (`ripple_extract.sh`) stays gate-or-revert (GATE0 standalone-compile → GATE1 build green → GATE2 compiler-unchanged → GATE3 corpus green, atomic revert on any fail). And it stays **honestly local**: frontier-local argmax over e-graph-reachable proven rewrites, certified abstention (`s₀∈M`) when nothing strictly beats the incumbent — never a global-optimum claim (that specializes to NP-hard).

**Why this is the apex** (`/architect` + `/math-olympiad` + the no-ML invariant). Trade-off **five loosely-coupled components vs. one synthesizer over a move IR**: *decision — unify under `ripple_term`* (**ADR-C7**), because the five share a "propose-prove-apply" skeleton and five proof surfaces is five places soundness can crack; one move-IR + one oracle gives the self-modifier a *single* theorem to satisfy per move. The `/math-olympiad` core is the **well-founded termination**: each applied move strictly decreases separation (ring size shrinks) while `J` strictly increases, so the loop provably converges to a *local* optimum — and the honesty is the ceiling itself (`III-RIPPLE-OPTIMIZER-ARCHITECTURE.md` §0): "optimal" means *local-optimal under proven-sound moves over the decidable fragment, with abstention everywhere else." The no-ML invariant is not a promise but a *structural* property: the metric's inputs are sealed content-addresses, so it *cannot* observe-and-adapt even if asked.

**Reinvented primitives.**
- **`ripple_term` (canonical move IR).** *Old ceiling:* merge/cut/extract as three separate code paths, three proof shapes.
- **`proof_ripple_unified` (five-dimension oracle).** *Old ceiling:* the five proofs scattered across `proof_ripple`/`ripple_metric`/`ripple_cut`/`ripple_extract`.
- **`ripple_synthesizer` (single driver) + `ripple_checkpoint` (sealed outcome).** *Old ceiling:* no single entry point; no sealed record of a self-optimization pass.

**Ordered file-by-file change plan.**
1. `omnia/ripple_term.iii` — **NEW** the move-IR enum. *Why:* one move type.
2. `forcefield/proof_ripple_unified.iii` — **NEW** the five-dimension decider (`proof_ripple_decision(t) → crystal_id|reject`). *Why:* one proof surface.
3. `forcefield/ripple_synthesizer.iii` — **NEW** the loop driver calling `ripple_loop/search/cut/extract` as subroutines. *Why:* one entry, propose→prove→apply.
4. `forcefield/ripple_checkpoint.iii` — **NEW** the sealed post-pass artifact (`{closure_root, decision_certs[], final_ring_size, moves}`). *Why:* a provable record of each pass.
5. `forcefield/ripple_metric.iii` — **EXTEND** `rt_eval_j(t,n,e)` (evaluate a move's post-`J`); **affirm** the sealed-fields-only (ML-free) input set. *Why:* value the move-IR; keep it ML-free.
6. `omnia/commit_gate.iii` — **ADD** `cg_decide_ripple(t)` (the ripple dimension of §C.5 made move-IR-aware). *Why:* the kernel decides each move.
7. `forcefield/ripple_loop.iii`, `ripple_search.iii`, `ripple_cut.iii`, `ripple_extract.iii` — **KEEP** as subroutines (no behavioral edit). *Why:* the proven pieces stay; only the orchestration unifies.

**Proof obligation upgrade.** Every applied ripple is a theorem (the `ripple_extract.sh` GATE0–3 chain; **negative arm**: any gate red → atomic revert, tree never left broken). The metric is **certified-monotone + non-gameable** (a non-improving move is rejected; a move whose inputs aren't sealed structural fields is rejected — the anti-gaming arm). The **abstention arm**: when no move strictly beats the incumbent, `ripple_search` returns the certified `s₀∈M`. The **no-ML arm**: a structural check that the metric path reads zero observational fields. Determinism: the synthesizer/IR/oracle change emitted bytes → intentional reseal gated on the monotonicity + abstention + revert arms.

**Harmony ledger entry.** *This is the organ that improves every other.* It measures and refactors all of §S + §C; its decisions flow through §C.5's commit-gate (the ripple dimension *is* this); it consumes §S.6 (seal/crystal for `proof_ripple_decision`), the §C.5 e-graph (reachable frontier), and §C.15's proposer (proven-sound moves only). The trit de-dup and the four-copies→one-NTT unification are this loop's outputs — the apotheosis method, alive in the tree.

---

### C.8 — Microarchitecture / HDL / physical-cost & silicon `◇ designed`

**Final Form.** Three loosely-coupled subsystems (the ROB/port microarch simulator, the per-opcode cost calculus, the combinator→netlist HDL) converge on **one cost-silicon IR with provably-sound extraction**. A `unified_cost_manifold` replaces the *opaque event-loop* microarch simulator (`microarch_model.iii`, `ROB_CAP=224`/`EXEC_PORTS=10`) with **closed-form DP cost formulas** (`uc_formula_latency/throughput/regpressure`, O(n log n)) that are queryable *during* e-graph saturation, not only at extraction — so cost steers rewriting. One `uc_cost` call returns a **6-D cost vector**, and netlist selection is a **Pareto frontier** over the 6-D product lattice (the antichain of non-dominated designs, `pareto_extraction.iii`) rather than a single scalar minimum. HDL becomes a clean `hdl_compiler` (SKI/CCL combinator parse → normalize → netlist), and the **E-graph netlist optimizer** keeps a proof DB of 20+ gate identities, *each proven once* via a 2ᵏ truth table, selecting the fewest-gate equivalent (reusing the §C.5 e-graph organ). It remains, honestly, a **model** — analytic ROB/port + analytic gate-cost — not a cycle-accurate RTL simulator or a tapeout; the cost it computes *feeds the performance apex* (§C.14).

**Why this is the apex** (`/architect` + `/math-olympiad`). Trade-off **opaque event-loop simulation vs. closed-form cost queryable during saturation**: *decision — closed-form DP* (**ADR-C8**), because an event loop can only price a *finished* design at extraction time, whereas closed-form formulas price *candidate* rewrites mid-saturation, making the optimizer cost-aware (a strictly more powerful synthesis). Trade-off **scalar cost-min vs. Pareto frontier**: *decision — Pareto* — physical cost is genuinely multi-dimensional (latency vs. area vs. power vs. reg-pressure), and collapsing to a scalar hides the real trade space; the antichain is the honest answer. The `/math-olympiad` guarantee is the HDL certification: every gate identity is proven by *exhaustive* 2ᵏ truth table (`hdl_equiv2`), so the netlist optimizer's rewrites are bit-exact by construction — a wrong netlist is impossible, not merely unlikely.

**Reinvented primitives.**
- **Closed-form DP cost (`uc_formula_*`)** replacing the event-loop sim. *Old ceiling:* cost only at extraction, invisible to the optimizer.
- **6-D Pareto extraction (`pe_pareto_frontier`).** *Old ceiling:* a scalar minimum hiding the trade space.
- **E-graph gate-identity proof DB (`hdl_compiler` + `hdl_equiv2`).** *Old ceiling:* per-call certification re-derived each time.

**Ordered file-by-file change plan.**
1. `numera/unified_cost_manifold.iii` — **NEW** (~700 lines): the closed-form cost organ (`uc_cost → [6-D vector]`). *Why:* one cost source, queryable during saturation.
2. `numera/cost_calculus.iii` — **CONSOLIDATE** into `unified_cost_manifold` (remove per-opcode table instantiation). *Why:* dedup.
3. `numera/microarch_model.iii` — **DEPRECATE** the event loop; retain `ma_simulate_req`/`ma_trace_hash` for back-compat KAT (`corpus 952`). *Why:* keep the KAT oracle, retire the opaque core.
4. `numera/hdl_compiler.iii` — **NEW** (~500 lines): SKI/CCL combinator → normalized netlist. `hdl.iii` — **DEPRECATE**, retain `hdl_eval`/`hdl_equiv2` (the truth-table certifier). *Why:* clean lowering + retained certification.
5. `numera/pareto_extraction.iii` — **NEW** (~250 lines): the 6-D frontier antichain. *Why:* multi-dimensional cost selection.
6. `numera/cost_lattice.iii` — **EXTEND** with the 6-D meet/join/compare order `pareto_extraction` uses. `numera/egraph.iii` — **RETAIN** (the optimizer reuses `eg_saturate/eg_union`). *Why:* the lattice order + the shared e-graph.

**Proof obligation upgrade.** The HDL **negative arm**: a non-equivalent netlist is *rejected* by the exhaustive 2ᵏ truth-table certifier (`hdl_equiv2`) — bit-exact lowering or no lowering. The Pareto frontier is a *true antichain* (no member dominates another — checkable). The cost lattice's meet/join obey the lattice laws. Affirm `corpus 952/963` (ROB saturation / ISA cost gradient). Determinism: the consolidation moves emitted bytes → intentional reseal gated on the truth-table + antichain arms.

**Harmony ledger entry.** Consumes §C.5's e-graph (saturation/extraction) and §S.7 (the cost arena). Exports `uc_cost` (the 6-D cost the §C.14 perf-apex and the §C.7 ripple `J` consult for cost-aware refactoring) and the certified `hdl_compiler`. The cost manifold is the bridge between III's reasoning and its silicon (§C.12 Verilog) — analytic, honest, and bit-exact where it certifies.

---

### C.9 — Systems & sovereign layer `◇ designed`

**Final Form.** The broad systems layer — ~24 transpilers, the resolver/crystal engine, the container library, the aether net stack, the 44-module verba text faculty — collapses onto **six reinvented organs driven by the §C.4/§C.6 proof compiler**. **(1) `form_ir`**: every transpiler (`tp_ast/babel/c99/latex/md/x86/…`) converges to one `form_ir_t {kind, arity, payload}` with **one 7-pass lowering stack** (`parse → normalize → unify → specialize → schedule → emit → validate`), replacing 24 bespoke emitters with one pluggable IR. **(2) `arena_slot`**: every container (`list/map/set/vec/queue/lru`) + `crystal` allocates through one `arena_slot_alloc(arena, kind, hard_max)` over §S.7. **(3) `proof_resolve`**: the resolver is wrapped in a **seal-gate that resolves the verification finding** — the Phase-C.5 hot-fast-path (`resolver.iii:505-509`) that *bypassed the "no shortcut" 11-step contract* is now admitted *only* with a `proof_term` certifying the shortcut is **behaviorally equivalent** to the full contract (or rejected) — the violation becomes a *proven* optimization. **(4) `verba_format_ir`**: one format dispatcher for all 44 verba modules (`JSON/CSV/LaTeX/…`). **(5) `reach_oracle`**: a sealed-reach capability gate for aether (`net/http/tcp/inet/async`), closing the under-verified network-init path. **(6) `arena_slot_witness`**: a container-honesty proof (alloc/free balanced). And `caindex.iii` — flagged *no-corpus-test* — gets its KAT.

**Why this is the apex** (`/architect` + `/refactor`). Trade-off **24 transpiler emitters vs. one IR + lowering**: *decision — one `form_ir` + 7-pass stack* (**ADR-C9a**), because 24 emitters is 24 places a lowering bug hides and zero shared optimization; one IR routed through the §C.6 `xii_organ`/§C.4 `proof_term` makes every transpilation a *proof-carrying* lowering. Trade-off **the resolver's contract-violating shortcut — delete vs. prove**: *decision — prove it* (**ADR-C9b**) — the Phase-C.5 fast-path is a *real* optimization (it's measured-fast), so the apex doesn't delete it; it *discharges the contract violation* by requiring a `proof_resolve` certificate that the shortcut equals the 11-step result, turning a latent inconsistency into a sealed theorem. This is the architectural lesson of the whole document: an optimization that violates a stated invariant is fixed by *proving the invariant still holds*, not by removing the optimization.

**Reinvented primitives.**
- **`form_ir` + 7-pass `ir_lower`** (one transpiler IR). *Old ceiling:* 24 emitters, no shared lowering/optimization.
- **`arena_slot`** (one container allocator). *Old ceiling:* per-container alloc duplication.
- **`proof_resolve` (seal-gated resolver).** *Old ceiling:* the Phase-C.5 shortcut violated the 11-step contract un-discharged.
- **`reach_oracle` / `verba_format_ir` / `arena_slot_witness`** (sealed net-reach / one format dispatch / container honesty).

**Ordered file-by-file change plan.**
1. `omnia/form_ir.iii` + `omnia/ir_lower.iii` — **NEW** the unified transpiler IR + 7-pass lowering (routed through §C.6 `xii_organ` → §C.4 `proof_term`). *Why:* one proof-carrying lowering.
2. `omnia/tp_*.iii` (~24 files) — **MODIFY** each to emit `form_ir_t` instead of hand-rolled bytes. *Why:* converge on the IR.
3. `omnia/arena_slot.iii` + `arena_slot_witness.iii` — **NEW** the container slot organ + honesty proof; **MODIFY** `list/map/set/vec/queue/lru` to delegate. *Why:* one allocator, proven balanced.
4. `omnia/proof_resolve.iii` — **NEW** `proof_resolve_call(set, intent, ctx, steps_mask) → (payload, proof_term)`; **wrap** `resolver.resolve()` so the Phase-C.5 shortcut carries an equivalence proof. *Why:* discharge the contract violation.
5. `verba/verba_format_ir.iii` — **NEW** the one format dispatcher for the 44 verba modules. *Why:* one format surface.
6. `aether/reach_oracle.iii` — **NEW** the sealed-reach gate for `net/http/tcp/inet/async`; **add** the missing net-init corpus test. *Why:* close the under-verified network path.
7. `STDLIB/corpus/` — **ADD** `caindex` KAT (the no-corpus-test finding). *Why:* the content-address index gets its proof.

**Proof obligation upgrade.** The headline **negative arm**: `proof_resolve` *rejects* the Phase-C.5 shortcut if it is **not** behaviorally equivalent to the 11-step contract (the contract violation can no longer pass un-proven). Transpiler round-trips: each `tp_*` lowering validated by `ir7_validate`. Container honesty: `arena_slot_witness` asserts alloc/free balance (a leak is caught). New KATs for `caindex` and aether net-init (closing the no-corpus-test orphans). Determinism: the IR/organ rewrites move emitted bytes across the systems layer → intentional reseal gated on the equivalence + round-trip + honesty arms.

**Harmony ledger entry.** Consumes §S.7 (`arena_slot`), §C.4 (`proof_term`), §C.6 (`xii_organ` lowering), §S.6 (seal for `proof_resolve`/`reach_oracle`). Exports `form_ir` (the universal transpiler IR), `arena_slot` (the container floor), and `proof_resolve` (the seal-gated resolution every higher consumer trusts). The systems layer becomes proof-carrying end-to-end — and the one stated-invariant violation in the tree is discharged into a theorem.

---

> **§C.7–C.9 harmony summary (the system optimizes, models, and serves — all proof-carrying).** The ripple loop (§C.7) is the organ that *performs* this whole apotheosis on the live tree — measuring `C−(A+B)` with an ML-free certified-monotone metric and applying only gate-proven, locally-optimal, reversible moves. The cost manifold (§C.8) prices candidates *during* synthesis and feeds both the ripple `J` and the perf-apex (§C.14), with bit-exact certified HDL. The systems layer (§C.9) collapses 24 transpilers to one proof-carrying IR, every container to one witnessed allocator, and *discharges* the resolver's one contract violation into a sealed equivalence theorem. Net `/simplify`: 24 emitters → 1 IR, 5 ripple components → 1 synthesizer, microarch+cost+HDL → 1 cost-silicon IR, per-container alloc → 1 slot organ — and three verification findings (resolver shortcut, caindex/net no-corpus-test) closed.

### C.10 — Katabasis descent gate & Ring-0 deploy `◇ designed`

**Final Form.** III's descent beneath Windows (R3 → R0 → R-1 → R-2) resolves to *one gate decision, expressed once and descended*. The insight: `katabasis_gate_admit` — which chains seal → capability → hexad → inverse-derivability into a verdict (`gate.iii`, `_decide_term`) — *is the §C.5 commit-gate's admission logic specialized to the descent domain*; the apex makes that explicit, so the same five-dimension composition that refuses an unsound self-edit at R3 refuses an unsound cycle at R0. The nine-family cycle taxonomy (`cycle_family.iii`), the ring-transition lattice (`ring_lattice.iii`: R3→R0 via IOCTL, R0→R-1 via magic-MSR, no skipping/no ascent), the minimal fail-closed VMEXIT set (`vmexit.iii`), and the six `.def`-single-sourced, drift-gated, content-address-sealed data tables (svm/bar/vmexit/ring_lattice/census/cycle_family) all stand — they are already the §C.13 gate discipline applied to silicon. The one *wiring* gap closes: an **R3 IOCTL bridge** (`r3_ioctl_driver`) connects user-mode intent to the kernel-resident gate via `cg_r0`'s `r0_emit_sym_run` kernel-import primitive, so `gate_resident.iii`'s Ring-0 `DriverEntry` selftest (4-case gate, SHA-256 seal, NTSTATUS) becomes a *live* admission path, not just a selftest. The "proven on metal (Ring-0, Tier-2, no BSOD)" remains honestly `⟦HIST⟧` — a runtime event source-audit cannot reproduce — and the apex *names it as such*, staging the live `ntoskrnl` link as the next verifiable step rather than claiming it done.

**Why this is the apex** (`/architect` + `/math-olympiad`). The trade-off is **a separate descent gate vs. the commit-gate descended**: *decision — descend the one gate* (**ADR-C10**), because admission soundness should have *one* definition whether the object is a source edit (R3) or a hardware cycle (R0/R-1); two gates is two trust roots. The `/math-olympiad` spine is the **bricking theorem** (`bricking.iii`): the gate is *complete* — it exhaustively characterizes exactly when a cycle is unrepresentable (`hexad_reachable = false`), so "fail-closed" is a *proven* total, not a default. The data tables' `.def`-single-source + `--check` drift gate + content-address seal mean the descent's *facts* (which VMEXITs, which ring edges) cannot drift un-noticed — the same single-source discipline §C.13 generalizes.

**Reinvented primitives.**
- **Gate-as-descended-commit-gate** (`katabasis_gate_admit` expressed as the §C.5 composition at R0). *Old ceiling:* the descent gate and the commit-gate as two admission definitions.
- **`r3_ioctl_driver` (the live R3→R0 bridge).** *Old ceiling:* the Ring-0 gate ran only as a selftest, not a live admission path.

**Ordered file-by-file change plan.**
1. `katabasis/gate.iii` — **REFACTOR** `katabasis_gate_admit` to invoke the §C.5 commit-gate composition specialized to descent (seal/cap/hexad/inverse as four of the gate's dimensions). *Why:* one admission definition, two rings.
2. `katabasis/{cycle_family,ring_lattice,vmexit,census,svm_layout,bar_layout}.iii` — **AFFIRM** the six `.def`-sourced drift-gated sealed tables (no hand-edits). *Why:* descent facts stay single-sourced.
3. `katabasis/bricking.iii` — **AFFIRM** the exhaustive unrepresentability theorem as the fail-closed proof. *Why:* fail-closed is a total, proven.
4. `KATABASIS-DEPLOY/src/r3_ioctl_driver.c` — **NEW** kernel-mode R3→R0 bridge (`KatabasisGateIOCTL` forwards the intent manifest to `katabasis_gate_admit`). *Why:* the live admission path.
5. `COMPILER/BOOT/cg_r0.iii` — **AFFIRM** `r0_emit_sym_run` (the kernel-import primitive the bridge uses); *(design only — the live compiler is not edited)*. *Why:* the kernel-call routing.
6. `KATABASIS-DEPLOY/src/gate_resident.iii` — **EXTEND** the `DriverEntry` selftest into the live IOCTL-driven gate (retain the selftest arm). *Why:* selftest → live admission.

**Proof obligation upgrade.** Affirm `corpus 390–395, 600–609` (gate verdicts, family/inverse, ring lattice, VMEXIT, the six table reseals). **Negative arms**: an unsound cycle is *rejected* with the precise `KG_REJECT_{SEAL,CAP,HEXAD,IRREVERSIBLE}` arm; an unmodelled VMEXIT *fails closed* (reverts via the SID host-state pre-image); a hand-edited `.def` table reddens the `--check` drift gate. The bricking theorem's exhaustiveness is the completeness proof. Determinism: `cg_r0`/the live driver are *not* edited here (design only); the `katabasis/*.iii` gate refactor moves the stdlib hash, an intentional reseal gated on the verdict arms.

**Harmony ledger entry.** Consumes §C.5 (the commit-gate composition it descends), §S.6 (seal for cycle terms), §C.13 (the `.def` drift-gate discipline). Exports the live Ring-0 admission path. The descent is the commit-gate's reach extended from source to silicon — one admission, R3 to R-2.

---

### C.11 — Distributed BFT consensus & federation `◇ designed`

**Final Form.** The HotStuff stack — Byzantine-safe but rigid — becomes a *certified-monotone, tier-aware, sound-admission* consensus. A `hotstuff_unified` pacemaker replaces the hardcoded three-phase pipeline with a **certified-monotone tier-aware scheduler** whose timeout is a *constitutional constant* (§C.5), exposing each tier's quorum requirement explicitly while preserving Byzantine safety (the `mhash` vote-block match, `hotstuff.iii:74`). Predictive quorum becomes a **tournament-backed optimizer** (`hotstuff_predict_opt`) with deterministic Byzantine-availability proofs — replacing the conservative `k=1` redundancy with a provably load-balanced peer selection (and *not* a learned one: peer scoring is over *sealed* failure/latency facts, never observed-and-adapted — the no-ML invariant). The six-file federation layer (`fed_admit` tiered admission, `fed_sybil` proof-of-work Sybil resistance, `fed_eclipse` eclipse defense, `fed_tier`, `fed_genesis`, `fed_seal`) is affirmed, with admission discharging through the commit-gate: a node joins only on a *proven* tier certificate, and every vote-block seals via the §S.6 chain.

**Why this is the apex** (`/architect` + the no-ML invariant). Trade-off **adaptive (learned) quorum vs. proven-sound quorum**: *decision — proven-sound* (**ADR-C11**), because a consensus layer that *learns* whom to trust from observed behavior is an attack surface (an adversary trains it); the apex selects quorums by *proof* over sealed facts (PoW for Sybil, sealed failure certificates for availability), so Byzantine safety is a theorem, not a trained expectation. The `/math-olympiad` core is unchanged and supreme: safety = "no two honest nodes commit conflicting blocks," enforced by the `mhash` vote-block match (two blocks with the same height but different `mhash` cannot both gather a quorum). The tier-aware pacemaker's monotonicity (timeouts only increase within a view) is the liveness lever, certified.

**Reinvented primitives.**
- **`hotstuff_unified` (certified-monotone tier-aware pacemaker).** *Old ceiling:* a hardcoded three-phase pipeline blind to tier/network.
- **`hotstuff_predict_opt` (tournament quorum optimizer, proof-based).** *Old ceiling:* conservative `k=1` with no optimality proof — and the temptation to make it *learned*.

**Ordered file-by-file change plan.**
1. `aether/hotstuff_unified.iii` — **NEW** (~450 lines): the tier-aware certified-monotone pacemaker (constitutional timeout). *Why:* adaptive pacing without learning.
2. `aether/hotstuff_predict_opt.iii` — **NEW** (~280 lines): the tournament quorum optimizer with Byzantine-availability proofs over *sealed* peer facts. *Why:* proven load balance, no ML.
3. `aether/hotstuff.iii` — **MODIFY** `hs_init` (`:89`) to call `hsu_init` (pass-through, retain the legacy path); affirm the `mhash` vote-block safety. *Why:* adopt the pacemaker, keep safety.
4. `aether/hotstuff_predict.iii` — **MODIFY**: rename `hsp_predict_quorum` → `…_legacy`; route to `hotstuff_predict_opt`. *Why:* the optimized quorum.
5. `aether/{fed_admit,fed_sybil,fed_eclipse,fed_tier,fed_genesis,fed_seal}.iii` — **AFFIRM**; route admission through the §C.5 commit-gate with a proven tier certificate; vote-blocks seal via §S.6. *Why:* sound admission, sealed consensus.

**Proof obligation upgrade.** Affirm `corpus 159–165` (federation tier/Sybil/eclipse/admit/genesis/seal). **Negative arms**: two conflicting blocks at one height cannot both reach quorum (the `mhash` safety falsifier); a Sybil node without valid PoW is *rejected* by `fed_sybil`; an eclipse attempt is detected by `fed_eclipse`; **the no-ML arm** — a structural check that peer scoring reads only sealed facts, never observed frequencies. Determinism: the new pacemaker/optimizer move the stdlib hash, an intentional reseal gated on the safety + Sybil + no-ML arms.

**Harmony ledger entry.** Consumes §C.5 (commit-gate admission), §S.6 (vote-block seal), §S.5 (`mhash`/Keccak). Exports the consensus surface to any multi-node III deployment. Byzantine safety by proof, federation admission by certificate — never by a learned trust model.

---

### C.12 — Hardware realization (R2-GENESIS Verilog RTL) `◇ designed`

**Final Form.** The `resolver_unit.v` (484-line Verilog realization of the `resolver.iii` 12-step resolution primitive) is *completed* and *proven byte-identical to its software twin*. Seven structural gaps close: (1) the score reduction's hardcoded slot-0 selection becomes a **3-stage pairwise-max tournament tree** (8-wide → 4 → 2 → 1, the true argmax the software computes); (2) the memo unit's write path is implemented; (3) its content-address key moves from a weak XOR to a **SHA-256-truncated-to-128-bit** hash (matching the software `cad`); (4) the K-cost policy constants move into a **sealed ROM** whose `K_cost_table_mhash` binds to the `sealed_root_mhash`; (5) the witness record is completed to the full 960-bit structure; (6–7) the I-INSTR v1.0 control + status fields. Then the capstone: a **silicon↔software equivalence proof** — a 12-test equivalence corpus (`test_200_18_primitives.sv …`) plus a formal harness (`resolver_unit_formal.sv`) synthesizing the RTL to a gate-level netlist and SMT-proving it computes the *same* verdict as `resolver.iii` on every input. This is the III→silicon bridge made *real and verified*: a software organ and its hardware realization proven the same artifact.

**Why this is the apex** (`/architect` + `/math-olympiad`). Trade-off **a preserved-but-incomplete RTL demo vs. a completed, formally-equivalent core**: *decision — complete + prove equivalence* (**ADR-C12**), because a hardware "realization" that picks slot 0 instead of the tournament winner does not *realize* the resolver — it approximates it; the apex makes the RTL a faithful twin and *proves* the faithfulness (the strongest possible claim: not "we ported it" but "it is provably the same function"). The `/math-olympiad` instrument is the equivalence corpus + SMT harness: byte-identical verdicts across the I-INSTR v1.0 spec's 12 cases, with the formal harness closing the gap between "passes 12 tests" and "is equivalent." The resolver's Phase-C.5 software shortcut (§C.9) is documented in the RTL as the same *proven* spec-deviation, so software and silicon agree even on the optimization.

**Reinvented primitives.**
- **3-stage tournament-max score reduction.** *Old ceiling:* slot-0 selection — not the argmax.
- **SHA-256-truncated memo key + sealed K-cost ROM.** *Old ceiling:* XOR key + hardcoded constants (un-sealed, un-bound).
- **Silicon↔software equivalence proof.** *Old ceiling:* a preserved artifact with no equivalence claim.

**Ordered file-by-file change plan.**
1. `R2-GENESIS/silicon/resolver_unit.v` — **COMPLETE** (484→~700 lines): the 8-wide 3-deep tournament tree (replace lines 359–415), the memo write path + SHA-256-trunc key, the sealed K-cost ROM, the full 960-bit witness. *Why:* a faithful twin.
2. `R2-GENESIS/silicon/test_200_18_primitives.sv` (+11 more) — **NEW** the 12-case equivalence corpus. *Why:* byte-identical verdicts vs. `resolver.iii`.
3. `R2-GENESIS/silicon/resolver_unit_formal.sv` — **NEW** the formal harness (synthesize → gate netlist → SMT-prove equivalence). *Why:* equivalence, not just tests.
4. `omnia/resolver.iii` — **DOCUMENT** the Phase-C.5 shortcut as the same audited spec-deviation the RTL encodes (cross-ref §C.9 `proof_resolve`). *Why:* software and silicon agree on the optimization.

**Proof obligation upgrade.** The **equivalence proof** is the obligation: every one of the 12 I-INSTR v1.0 cases yields a byte-identical verdict from `resolver_unit.v` and `resolver.iii` (the differential), and the SMT harness proves it for *all* inputs (not just the 12). **Negative arm**: a deliberately-wrong RTL tournament (picks slot 0) fails the equivalence corpus. The §C.8 `unified_cost_manifold` prices the netlist (gate count / delay). Determinism: RTL/testbenches are outside the `.iii` seal; the `resolver.iii` doc-comment is inert (no hash move).

**Harmony ledger entry.** Consumes `resolver.iii` (§C.9, the spec it realizes), §S.6 (`cad`/SHA-256 for the memo key + sealing), §C.8 (cost). Exports the verified hardware twin. III now spans source to silicon with a *proof* connecting them — the deepest "one artifact, two substrates" harmony in the system.

---

### C.13 — The nothing-ships-unproven gate stack `◇ designed`

**Final Form.** The defining property becomes *one in-tree, NIH, always-runs provable admission*. The stack stands — the **determinism gate** (byte-identity reseal 59/0), the **conformance corpus** 619/0 (falsifier-first, negative arms mandatory), the **forge-closure + trusted-base seals** (`sanctus/*`), the **per-`.def` drift gates** — but its one deviation is closed: the **cartographer** (no duplicate `@export`, no un-allowlisted dependency cycle) was a *soft, external Python* gate (`III-CARTOGRAPHER/cartographer.py`, **skipped if absent** — a hole in the NIH guarantee), and the apex rewrites it as an **in-tree sealed `.iii` gate** (`cartographer.iii` + a sealed `cartographer_allowlist.iii` `@crystal` data module) that is *mandatory, deterministic, and self-hosted* — a DFS cycle detector + dup-export scanner that runs every build and cannot be skipped. The whole stack is then expressed as *one* admission predicate: a build ships iff **(determinism ∧ corpus ∧ seal ∧ drift ∧ cartography)** all hold, each emitting a sealed proof that discharges through the commit-gate's falsifier-first ledger. The result: the "nothing ships unproven" property is itself *unskippable and NIH* — no external dependency can silently disable a gate.

**Why this is the apex** (`/architect` + `/math-olympiad`). Trade-off **soft external cartographer vs. in-tree NIH gate**: *decision — in-tree NIH* (**ADR-C13**), because a gate that is "skipped if absent" is not a gate — it is a suggestion; for a system whose entire identity is "nothing ships unproven," a *skippable* architectural-invariant check is the one crack in the foundation, and closing it (a self-hosted `.iii` cartographer) makes the NIH claim total. The `/math-olympiad` framing: the gate stack is a *conjunction of falsifiable predicates*, and the apex's contribution is *totality* — every predicate is in-tree, deterministic, and mandatory, so the admission theorem has no escape hatch. The negative-arm discipline (the project's "prove the negative") is elevated to the stack itself: each gate must be shown to *fail* on a planted violation (a dup export, an un-allowlisted cycle, a drifted `.def`, a non-byte-identical reseal), not merely to pass.

**Reinvented primitives.**
- **In-tree NIH cartographer** (`cartographer.iii` + sealed allowlist). *Old ceiling:* a soft external Python gate, skipped if absent — the one non-NIH crack.
- **The gate stack as one admission predicate** (determinism ∧ corpus ∧ seal ∧ drift ∧ cartography), discharged through the commit-gate ledger. *Old ceiling:* five separate gates with no unified, proven conjunction.

**Ordered file-by-file change plan.**
1. `omnia/cartographer.iii` — **NEW** (~400 lines): the in-tree DFS cycle detector + dup-`@export` scanner (a faithful, deterministic port of `cartographer.py`). *Why:* close the NIH crack.
2. `omnia/cartographer_allowlist.iii` — **NEW** sealed `@crystal` data module: the allowed-cycle allowlist (no functions, content-addressed). *Why:* the allowlist is sealed, not a JSON sidecar.
3. `STDLIB/scripts/build_stdlib.sh` — **PATCH** (`:238–256`): replace the conditional Python cartographer with the mandatory in-tree `.iii` invocation (no skip-if-absent). *Why:* unskippable.
4. `STDLIB/corpus/` — **ADD** cartographer falsifiers: a planted duplicate `@export` and a planted un-allowlisted cycle must each *fail* the gate. *Why:* prove the negative.
5. `sanctus/*.iii` + `COMPILER/BOOT/build_iiis2.sh` — **AFFIRM** the determinism/forge/trusted-base seals + the 59/0 byte-identity gate as the stack's other conjuncts. *Why:* the full admission predicate.

**Proof obligation upgrade.** The **negative arms are the point**: a duplicate `@export` *fails* cartography; an un-allowlisted cycle *fails*; a drifted `.def` *fails* drift; a non-byte-identical reseal *fails* determinism; a corpus negative-arm that *accepts* bad input *fails* the corpus. The admission theorem: a build ships iff all five conjuncts hold, each proven to reject its violation. Determinism: the cartographer is compiler-unreferenced → does **not** drift `iiis-1/2` (per the determinism memory); it moves only the stdlib/library hash.

**Harmony ledger entry.** Consumes §S.6 (seals), §C.5 (the commit-gate ledger the gate proofs discharge through), the §C.10 `.def` drift discipline. Exports the unskippable, NIH, total admission. This is the capability that *guarantees every other capability* — and the apex makes it self-hosted to the last gate.

---

### C.14 — Performance apex (the measured fast paths at their ceiling) `◇ designed`

**Final Form.** Performance becomes a *proven composition under one discipline*: every fast path (1) measures against its own oracle or best-generic baseline on **identical operands**, (2) **gates correctness absolutely** (bit-identity, `q·b+r==a`, or field-equality mod p) *before* timing, and (3) reports a **clock-invariant cycle ratio**. The three measured wins are the floor, not the ceiling: Knuth Algorithm-D division **177–258×** (`990`), RSA Montgomery modpow **2.3–2.6× faster** after the CIOS allocation-free REDC reversed the pessimization (`991`), Curve25519 `fz_mul` **6.9×** (`992`) — all on module-global radix-2³² scratch (the §S.1 substrate). The apex adds the *mechanistic* layer: a `cost_lattice_unified` derives each path's cycle bound from the §C.8 microarchitectural model (ROB/port) rather than only hand-measuring, so a *regression is provable* (a path slower than its derived bound fails a gate, not just an advisory). The staged accelerators land behind their differential KATs: the NTT REDC-fused inverse butterfly (ADR-S4, one fewer O(n) sweep per decaps/verify) and the SHA-NI dispatch path (§S.5). The bench corpus (`990/991/992`, owned by `run_bench_corpus.sh`) is the perf *proof*; the §C.13 gate-stack runs it.

**Why this is the apex** (`/architect` + `/math-olympiad`). Trade-off **hand-measured advisory budgets vs. mechanistically-derived provable bounds**: *decision — derive the bound* (**ADR-C14**), because an absolute cycle budget is machine-relative (the §C.13/`run_bench_corpus.sh` discipline correctly treats it as advisory), whereas a *ratio* against an oracle on the same host is clock-invariant *and* a bound derived from the ROB/port model (§C.8) is a *provable* expectation — together they turn "fast on my machine" into "provably faster than its baseline, and within its derived bound." The `/math-olympiad` rigor is the correctness-before-timing gate: a fast path is *first* proven bit-identical to its reference (the differential), *then* timed — so speed can never be bought with wrongness (the lesson of the §III.16 episode, where measurement caught a pessimization a source-read missed). The honest ceiling is named: these are constant-factor wins on a proven-correct substrate, not asymptotic miracles.

**Reinvented primitives.**
- **`cost_lattice_unified` (mechanistic provable bound).** Old: hand-measured advisory budgets. New: cycle bounds derived from the §C.8 ROB/port model — a regression is a *gate failure*. *Old ceiling:* "fast on this host" was unfalsifiable.
- **The ratio-with-correctness-gate discipline** (one harness shape for all fast paths). *Old ceiling:* per-bench ad-hoc timing.

**Ordered file-by-file change plan.**
1. `corpus/990_bench_knuth_div.iii`, `991_bench_montgomery_modpow.iii`, `992_bench_fe25519_mul.iii` — **AFFIRM** as the perf oracles (correctness-gated, clock-invariant ratio); these *are* the proof. *Why:* measured, not asserted.
2. `numera/cost_lattice_unified.iii` — **NEW** the mechanistic cycle-bound derivation over the §C.8 cost manifold; a path slower than its bound fails. *Why:* provable regression detection.
3. `numera/bigint_div.iii` — **AFFIRM** Knuth-D + the CIOS REDC (`mont_mul_bigint`, the §S.2 organ); the 991 reversal is structural. *Why:* the measured-fast core.
4. `numera/fe25519.iii`, `ntt.iii` — **AFFIRM** `fz_mul` + the shared NTT; **stage** the REDC-fused inverse butterfly (ADR-S4) behind its differential KAT. *Why:* the next constant factor, gated.
5. `numera/sha256_dispatch.iii` — **RESOLVE** the SHA-NI path (implement or delete the stub, §S.5). *Why:* no stub masquerading as dispatch.
6. `STDLIB/scripts/run_bench_corpus.sh` — **AFFIRM** as the perf-corpus owner (correctness hard-fail, timing advisory + the new mechanistic bound). *Why:* the gate-stack's perf proof.

**Proof obligation upgrade.** Every fast path **gates correctness before timing** (bit-identity / `q·b+r==a` / field-equality) — speed can never be bought with wrongness (the **negative arm**: a path that's fast but wrong fails the correctness gate, exit ≠ 99). The mechanistic bound: a path slower than its derived cycle bound *fails* (a provable regression, not an advisory). The staged butterfly/SHA-NI land only behind a differential KAT (bit-identity to the current path). Determinism: the bench/cost files are perf-only (correctly excluded from the seal — `corpus 244`'s own rule); the staged accelerators, when cut, are intentional reseals gated on their differentials.

**Harmony ledger entry.** Consumes §S.1/S.2/S.4 (the measured organs), §C.8 (`unified_cost_manifold` for the mechanistic bound), §C.13 (the gate-stack that runs the bench corpus). Exports the perf-proof discipline. Performance is, finally, a *theorem with a number* — correctness-gated, clock-invariant, and bounded.

---

## Implementation caveats (read before cutting code)

This is a *design* document — the spec for the implementation phase, not the code itself. Three caveats govern how to read the change plans:

1. **Cross-tree "shared organ" = one design + two faithful implementations + a differential KAT — not one physical module.** The self-hosting compiler (`COMPILER/BOOT/`) bootstraps *separately* from the stdlib (`STDLIB/iii/`) and cannot `extern` its modules. So where a "shared organ" spans both trees — the `proof_term` Curry-Howard IR (compiler `proof.iii` + stdlib `numera/proof_term.iii`) and `xii_organ` (compiler `cg_r3_xii_adapter` + stdlib `omnia/xii_*`) — "one organ" means *one IR design, implemented faithfully in both trees and held byte-aligned by a differential KAT*, **not** a single file both import. Within one tree (e.g. the four NIST fields sharing one stdlib Montgomery organ, §S.3; the 24 transpilers sharing one `form_ir`, §C.9) "shared" *is* a single module.

2. **Line anchors are point-in-time; re-grep before cutting.** Every `file:line` was verified against the tree at design time, but the tree moves concurrently (this pass personally caught `rsa_modexp` drift `:388 → :637`). An implementer must re-grep each anchor against the live file before editing — the anchors are *locators to confirm*, not coordinates to trust blindly (same discipline as the verification file's Part-IV tier note).

3. **Granularity: 22 capability *areas*, with the 398 fine-grained items folded in.** This file designs the 22 capability areas of `III-CAPABILITY-VERIFICATION.md` (§II / §III / §IV-families / §V); the 398 individual Part-IV inventory items are *subsumed* into their area's final form and change plan (e.g. the 26 symmetric-hash items live under §S.5), not given 398 separate sections — they are the contents of the files each plan names.

---

## Z · The whole organism (all 22 capabilities, harmonized)

With §S.1–S.7 and §C.1–C.15 designed, III resolves into *one harmonized organism* built on a single substrate and a single discipline. **One arithmetic floor** — a radix-2³² allocation-free compute contract with one CIOS-Montgomery organ (serving bigint-modpow and every NIST field), one NTT organ (serving four PQ/zk primes and bigint-multiply), one digest organ (one Keccak sponge, one SHA-2 dispatch, one Poly1305), one seal chain (`cad→mhash→merkle→witness`, its 2 Mi BSS replaced by a radix tree), and one provable allocation/time floor. **One reasoning core** — a single Curry-Howard `proof_term` IR and a single `xii_organ` shared by the self-hosting compiler, the logic kernel, and the rewriting system (one IR *design* faithfully twinned across the separately-bootstrapped compiler and stdlib trees, held aligned by a differential KAT — see *Implementation caveats*), composed by a commit-gate that *assembles* soundness from rule-confluence + the constitution VM + the ripple metric + the seal + the prover, and fed only proven-sound moves by a proposer that **never learns**. **One self-improving loop** — the Ripple Calculus measuring `C−(A+B)` with an ML-free certified-monotone metric and applying only gate-proven, locally-optimal, atomically-reversible moves (the very method this document embodies). **One descent** — the same gate, expressed once, reaching from a source edit at R3 to a hardware cycle at R-2. **One span from source to silicon** — a software resolver and its Verilog twin *proven the same function*. And **one unskippable, NIH, total admission** — determinism ∧ corpus ∧ seal ∧ drift ∧ cartography — that guarantees every capability above ships only when proven, with the performance claims kept *measured*, not asserted. The defining property of the verification file — *nothing ships unproven* — is, in the apotheosis, also *nothing duplicated, nothing un-sealed, nothing learned, and nothing skippable*: a leaner, provable, self-measuring whole, where a win in the substrate is a win everywhere at once.

*Every capability from `III-CAPABILITY-VERIFICATION.md` now has its most ambitious, most harmonious, most provable final form — and the exact, ordered, file-by-file, primitive-level change plan to realize it. The sister file is complete.*
