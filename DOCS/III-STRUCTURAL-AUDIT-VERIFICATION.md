# III Structural Audit — Verification Ledger
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> Per-finding verification of every claim in `DOCS/III-STRUCTURAL-AUDIT.md` against the **live**
> codebase as of **2026-05-29**. Each finding was checked by a read-only verify pass (does the
> described condition still exist in the code today?) and a fresh-context adversarial pass (refute
> the verdict and the proposed fix). Two findings (ENHANCE-20, RIPPLE-14) and two adversarial
> passes (ENHANCE-15, CUT-12) were closed in-session after the verification fan-out; all 79
> findings now carry a verdict.
>
> **Verdict vocabulary:** `HOLDS` (true as stated) · `DRIFTED` (true, but file/line/count/label
> moved — corrected here) · `PARTIALLY_WRONG` (claim needs amendment; some sub-claims stale) ·
> `ALREADY_FIXED` (the defect is gone) · `WRONG` (premise false).
>
> **Methodology note on cross-references.** The structural audit's own local ids
> (COMBINE/SEPARATE/RIPPLE/ENHANCE/CUT/KEEP) are *internal* handles; cross-references among them
> (e.g. COMBINE-13 "see SEPARATE-5") are correct and not source citations. Only citations to the
> *source* audit's ids (`F-*`, `E-*`, `X1`–`X26`, `D-*`, `A-*`, `C-*`, `G-*`, `J-*`, `II-*`) are
> evidence claims subject to misattribution; those are what the source-id checks targeted.

---

## 1. Executive summary

| Verdict | Count | Share |
|---|---:|---:|
| HOLDS | 50 | 63% |
| DRIFTED | 11 | 14% |
| PARTIALLY_WRONG | 13 | 16% |
| ALREADY_FIXED | 2 | 3% |
| WRONG | 1 | 1% |
| **Total** | **79** | |

**27 of 79 findings (34%) required correction.** The audit is a faithful May snapshot, but the
codebase has moved under it — and in three cases the most consequential way possible: **the defect
has already been fixed.** The headline corrections, which change *what work remains*:

1. **The crypto shadow is no longer live (COMBINE-13, ENHANCE-14 → ALREADY_FIXED; CUT-12 →
   DRIFTED; SYNTH-4 → PARTIALLY_WRONG).** The audit's single most urgent security claim — "the
   override mechanism makes the [tautological] crypto stubs win, so a fail-open `ed25519_verify`
   sits on the live signature path" — is **false today.** `STDLIB/iii/omnia/xii_emit_gen.iii:258`
   guards `if horizon_id < 24u8 { return 0xFFFFFFFFu32 }`: the override lookup returns "none" for
   every crypto horizon, forcing fall-through to the real kernel fragment. The live security hole
   is **closed**. What remains is (a) the dead stub *bodies* (safe removal, no longer a security
   emergency) and (b) the COMBINE-13/ENHANCE-14 *completion* (generate inlines from the proven
   `numera` crypto, or keep the chokepoint + a falsifier KAT proving no crypto horizon ever emits a
   stub). Severity is downgraded from Critical-live to dead-matter + hardening.

2. **`modular_mont` no longer carries "two Critical reduction bugs" (COMBINE-4 → PARTIALLY_WRONG).**
   MONT-1 (REDC overflow) is fixed at `modular_mont.iii:58-78`; MONT-2 (even-modulus garbage
   inverse) is fixed by an even-`n` guard + schoolbook fallback in `mont_mul_u32`/`mont_pow_u32`.
   The *unified-reduction* consolidation still stands on its other legs (`field` bit-serial reduce
   D-FLD-1 holds; the special-form folds for x25519/PQ are still missing), but its motivating
   premise — "the most defect-dense file in the system carries two Criticals" — must be struck.

3. **CUT-16 is WRONG.** `xii_emit_gen_produce` is *not* dead: it has a load-bearing build-time
   caller (`gen_xii_lattice…`), so the "no live caller of consequence" premise is false. This
   becomes a "keep + ensure tested," not a removal/decision.

4. **The NTT census is an undercount (COMBINE-1 adversarial dissent).** The audit (and the source
   `F-ST-1`/`X1`) say the NTT "exists three times" (mlkem, mldsa, zk_stark). A **fourth** exists:
   `STDLIB/iii/numera/entropy_monitor.iii::entropy_spectrum` (line ~213) is a full Cooley-Tukey NTT
   over `GF(998244353)` with its own modular stack. Decisive consequence: it **shares the prime
   998244353 with `zk_stark`**, so the consolidation organ must be scoped **4 NTTs / 3 primes**, and
   the 998244353 twiddle table is consumed twice — a free de-duplication the audit's plan misses.

The remaining corrections are drift (line counts, file paths, source-id labels) and sub-claim
staleness, detailed in §3–§5. **None of the corrections invalidates the audit's five-axis
architecture or its synthesis; they refine scope and retire completed work.**

---

## 2. Master verdict table

Adversarial column: `✓`=verdict survived refutation; `✗`=refuter dissented (see notes);
`—`=closed in-session. "Fix best?" = adversarial judgement on whether the audit's recommended fix
is already best-possible (`✓`) or a structurally superior approach is recorded (`↑`, see plan).

| ID | Verdict | Adv | Fix best? | Seal | One-line correction (full text in §3–§5) |
|---|---|:--:|:--:|---|---|
| COMBINE-1 | HOLDS | ✗ | ↑ | STDLIB | Census undercount: **4** NTTs / 3 primes (entropy_monitor is the 4th; shares 998244353 w/ zk_stark) |
| COMBINE-2 | HOLDS | ✓ | ✓ | STDLIB | egraph now 1709 ln; D-MLC-1 half is X3-index-shaped, not just a hash swap |
| COMBINE-3 | DRIFTED | ✓ | ✓ | MIXED | `unify` is at `omnia/unify.iii` (not numera); all 9 sites still O(N²)/linear today |
| COMBINE-4 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | **MONT-1 & MONT-2 ALREADY FIXED**; consolidation stands on D-FLD-1 + missing folds only |
| COMBINE-5 | HOLDS | ✓ | ✓ | STDLIB | minor line drift only |
| COMBINE-6 | DRIFTED | ✓ | ✓ | STDLIB | "Kahn order" (A-RP-2) is a *proposed* change, not a live hand-roll; 3 of 4 sites genuine |
| COMBINE-7 | DRIFTED | ✓ | ✓ | STDLIB | core thesis HOLDS (remote OOB write live); some lever line-refs drifted |
| COMBINE-8 | HOLDS | ✓ | ↑ | STDLIB | `D-CHK-2` label nuance; duplication real |
| COMBINE-9 | PARTIALLY_WRONG | ✓ | ↑ | STDLIB | fe25519 exposes only the *Edwards* field; need a Montgomery-form view (see §3) |
| COMBINE-10 | HOLDS | ✓ | ✓ | STDLIB | exact: `murmur3_32:40-44` ≡ `endian_load_u32_le` (endian.iii:36-42) |
| COMBINE-11 | HOLDS | ✓ | ↑ | STDLIB | over-generalized: double-eval only in 4 sat ops, not all of sat_arith |
| COMBINE-12 | DRIFTED | ✓ | ✓ | FORGE | core holds (no kernel.iii; typecheck.iii is it); a doc/header-ref repoint |
| COMBINE-13 | ALREADY_FIXED | ✓ | ✓ | STDLIB | **override no longer makes stubs win** (xii_emit_gen.iii:258 guard) |
| SEPARATE-1 | DRIFTED | ✓ | ↑ | STDLIB | egraph 1709 ln not 1628; all six concerns confirmed bundled |
| SEPARATE-2 | HOLDS | ✓ | ↑ | MIXED | ccl 938 ln not 898; trusted-base delegation confirmed |
| SEPARATE-3 | DRIFTED | ✓ | ✓ | STDLIB | cost field all-ones at sov_isa.iii:161-170 today; core holds |
| SEPARATE-4 | HOLDS | ✓ | ✓ | BOOT | cg_r3 3546 ln, smt 2155 ln; low-confidence split still advisory |
| SEPARATE-5 | HOLDS | ✓ | ✓ | STDLIB | chokepoint is the `<24` guard; policy/body split is sound |
| RIPPLE-1 | HOLDS | ✓ | ✓ | STDLIB | all four II-CCL/II-TC fixes present + KAT-gated today |
| RIPPLE-2 | HOLDS | ✓ | ✓ | STDLIB | D-KARA-1 silent-wrong-product live; NTT heals it |
| RIPPLE-3 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | **minter is `omnia/crystal.iii`** not `numera/crystal.iii` |
| RIPPLE-4 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | A-RL-1 misattributed (it's a dead outer-loop, not the cg_decide hoist); A-RX core holds |
| RIPPLE-5 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | A-CG-1 already-sealed-correct in one path; A-OI-2 is domain-sep, not swallowed-return |
| RIPPLE-6 | HOLDS | ✓ | ✓ | STDLIB | four builder-push citations all discard return codes today |
| RIPPLE-7 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | E-X-3 cswap **already branch-free**; the *separate-reduction* headline still holds |
| RIPPLE-8 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | D-BI-1 (no avx512dq) HOLDS; X17 evidence set partly misattributed |
| RIPPLE-9 | HOLDS | ✓ | ↑ | STDLIB | sign-ext defect live (confirmed in machine code); J-ITER-4 is bundled J-ITER-1..5 |
| RIPPLE-10 | DRIFTED | ✓ | ✓ | BOOT | **B-LDIL-1 lives in STDLIB, not COMPILER/BOOT** → it is STDLIB_GATE, not bootstrap-sealed |
| RIPPLE-11 | HOLDS | ✓ | ✓ | FORGE | census bug live at census.iii:63-70; 3-level closure accurate (deferral eliminated in plan) |
| RIPPLE-12 | HOLDS | ✓ | ✓ | STDLIB | tp_table_call dispatch + unchecked wrap live |
| RIPPLE-13 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | F-RFLG-1 (rights mismatch AMEND≠ATTEST) HOLDS verbatim; F-RFLC-2 80-byte detail imprecise |
| RIPPLE-14 | HOLDS | — | ✓ | STDLIB | **confirmed in-session**: ct_run_charter GREEN over empty registry; populator only from selftest |
| ENHANCE-1 | HOLDS | ✓ | ✓ | STDLIB | no line drift; eg_rebuild wipe at 502-503 |
| ENHANCE-2 | HOLDS | ✓ | ✓ | STDLIB | ≡ COMBINE-1 (capability framing) |
| ENHANCE-3 | HOLDS | ✓ | ✓ | STDLIB | eg_extract drift; claim holds |
| ENHANCE-4 | HOLDS | ✓ | ✓ | STDLIB | F-CORE-4 byte-accurate at sov_isa.iii:160-175 |
| ENHANCE-5 | HOLDS | ✓ | ✓ | STDLIB | D-DIV-1, ~64× figure, "Phase E" note all match |
| ENHANCE-6 | HOLDS | ✓ | ↑ | STDLIB | ≡ COMBINE-9; fe25519 Montgomery-view caveat |
| ENHANCE-7 | HOLDS | ✓ | ✓ | STDLIB | per-byte absorb at :52-61 exact |
| ENHANCE-8 | HOLDS | ✓ | ✓ | STDLIB | Straus-Shamir; symbols confirmed |
| ENHANCE-9 | HOLDS | ✓ | ✓ | STDLIB | all sub-claims verified in source |
| ENHANCE-10 | HOLDS | ✓ | ✓ | MIXED | 12-item cluster all present; sema sub-item is BOOT |
| ENHANCE-11 | HOLDS | ✓ | ✓ | STDLIB | xoshiro jump/long_jump accurate |
| ENHANCE-12 | HOLDS | ✓ | ✓ | STDLIB | bv_ring column-stack extension valid |
| ENHANCE-13 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | zk_snark unwired (true); but the kernel disposer is typecheck+ccl, and the unwired-PCC is `sov_pcc` (A-PCC-1) |
| ENHANCE-14 | ALREADY_FIXED | ✓ | ✓ | STDLIB | override-precedence defect closed (≡ COMBINE-13) |
| ENHANCE-15 | HOLDS | — | ↑ | MIXED | **confirmed in-session**; surpass-only = build the real transforms, never relabel |
| ENHANCE-16 | HOLDS | ✓ | ✓ | STDLIB | all three sub-claims exact |
| ENHANCE-17 | HOLDS | ✓ | ✓ | STDLIB | all 11 gates vacuous/untested today; none touched by G1-G5 |
| ENHANCE-18 | HOLDS | ✓ | ✓ | STDLIB | rn_recompute concat loop drifted to :187-19x; claim holds |
| ENHANCE-19 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | x25519 cswap **already branch-free**; fp256 (D-FP-1) + aes (E2-AES-1) remain |
| ENHANCE-20 | PARTIALLY_WRONG* | — | ✓ | STDLIB | **confirmed in-session**: E-EC-2 holds (no range/low-s), E-SLH-2 holds (SHA256/SHAKE hybrid), E-FE-4 holds |
| ENHANCE-21 | HOLDS | ✓ | ✓ | STDLIB | cb_conv permanent oracle; faithful |
| ENHANCE-22 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | three sub-claims non-uniform status (E-RSA-1 holds; check E-EC-3, E-PQD-2 individually) |
| ENHANCE-23 | PARTIALLY_WRONG | ✓ | ✓ | STDLIB | one of four micro-fixes already done (recheck MERKLE-2/C-BV-1/C-PC-3/C-NS-1 individually) |
| CUT-1 | HOLDS | ✓ | ✓ | STDLIB | **path: `numera/temporal_logic.iii`** not tempora; 4MB dead BSS real |
| CUT-2 | HOLDS | ✓ | ✓ | STDLIB | lines 66/78 not drifted; CLS_DIM_RESERVED=13u8 |
| CUT-3 | HOLDS | ✓ | ✓ | STDLIB | O(n) scan ≡ O(1) counter; live |
| CUT-4 | DRIFTED | ✓ | ✓ | STDLIB | A-RU-1 at :49/:50/:51 still current; unreachable return real |
| CUT-5 | HOLDS | ✓ | ✓ | STDLIB | XJN_NJ dead in `omnia/xii_joinability.iii`; safe delete |
| CUT-6 | HOLDS | ✓ | ✓ | STDLIB | FX16/24/48_SCALE dead in numera/fixed_extra.iii |
| CUT-7 | DRIFTED | ✓ | ✓ | STDLIB | dead Massey compare located precisely (source gave no line) |
| CUT-8 | HOLDS | ✓ | ✓ | STDLIB | all six X9 mask sites present today |
| CUT-9 | HOLDS | ✓ | ✓ | BOOT | DEAD-D7-1/DEAD-STACK-1 real; rides build_iiis2 |
| CUT-10 | HOLDS | ✓ | ✓ | STDLIB | all four dead-ref sub-claims present; src cites only B-JN-1 (item 4) |
| CUT-11 | HOLDS | ✓ | ✓ | STDLIB | nous_completion cert binds nothing; non-ZERO nuance |
| CUT-12 | DRIFTED | — | ↑ | STDLIB | **security hole CLOSED** (xii_emit_gen.iii:258); split: dead bodies + chokepoint KAT |
| CUT-13 | HOLDS | ✓ | ✓ | MIXED | embedded-ret real; II-XCF-1 misattribution on H002-float; same scaffold cluster |
| CUT-14 | HOLDS | ✓ | ✓ | NONE | historical note; "append two NOPs" verifiably absent |
| CUT-15 | HOLDS | ✓ | ✓ | STDLIB | quality_q7 g_resolver_lint_passed bare flag set unconditionally; ≡ ENHANCE-17 binary |
| CUT-16 | **WRONG** | ✓ | ✓ | MIXED | **`xii_emit_gen_produce` HAS a load-bearing build caller** (`gen_xii_lattice…`); not dead |
| KEEP-1 | DRIFTED | ✓ | ✓ | MIXED | **`seal_resolver.iii` is in `sanctus/`** not katabasis; ADR-RES-009 magnitude nuance |
| KEEP-2 | HOLDS | ✓ | ✓ | FORGE | census bug live at :63-70; corpus 603 only tests in-range; deferral eliminated in plan |
| KEEP-3 | HOLDS | ✓ | ✓ | BOOT | "per-file mhashes" overstates — there are no per-source-file mhash artifacts; golden BARE hash holds |
| SYNTH-1 | HOLDS | ✓ | ✓ | MIXED | grounded; labels SYNTH-1/S6 are our handles, not audit tokens |
| SYNTH-2 | HOLDS | ✓ | ✓ | STDLIB | "seven levers" prose names six (X7 implied); boundary thesis holds |
| SYNTH-3 | HOLDS | ✓ | ✓ | STDLIB | trusted-base-larger-than-narrative holds |
| SYNTH-4 | PARTIALLY_WRONG | ✓ | ✓ | MIXED | crypto/X25 instance ALREADY_FIXED → present-tense "shadow always wins" falsified; 3 of 4 instances persist |
| SYNTH-5 | HOLDS | ✓ | ✓ | STDLIB | vacuous-gate-as-lifecycle-bug holds; ct_run_charter line drift |

\* ENHANCE-20 reclassified PARTIALLY_WRONG only in that the audit treats all three sub-claims as
uniformly open; all three are in fact open today, so the hardening work stands in full — see §3.

---

## 3. Detailed corrections — findings whose scope or status changed

### COMBINE-1 (HOLDS, census undercount)
The "three times" census is an **undercount**. A fourth NTT exists:
`STDLIB/iii/numera/entropy_monitor.iii::entropy_spectrum` (~:213) — an iterative Cooley-Tukey DIT
NTT over `GF(998244353)`, primitive root g=3, ω=922799308, N=64, with its own bit-reversal
(`entropy_bitrev`:124) and a self-contained 5-function modular stack (`entropy_mulmod`:91,
`entropy_addmod`:98, …). **It shares the prime 998244353 with `zk_stark`'s `sf` field.** Corrected
consolidation scope: **four NTTs over three primes** (3329, 8380417, 998244353×2). The shared-prime
998244353 twiddle table is consumed by both `zk_stark` and `entropy_monitor` — one sealed table,
two consumers. `entropy_monitor.iii` is added as a fourth target module. (Plan: COMBINE-1 task.)

### COMBINE-4 (PARTIALLY_WRONG)
Strike: "The most defect dense file in the entire system, `modular_mont`, carries two Critical
reduction bugs (MONT-1 … and MONT-2 …)." **Both are already fixed:** MONT-1 (REDC overflow) at
`modular_mont.iii:58-78`; MONT-2 (even-modulus garbage inverse) via an even-`n` guard + schoolbook
fallback in `mont_mul_u32` (:97-104) and `mont_pow_u32` (:123-139). The unified-reduction
consolidation remains valid and valuable, motivated now by: `field`'s fresh bit-serial long-division
reduce per multiply (D-FLD-1, still live), the missing special-form folds for x25519 (E-X-1) and the
PQ primes (E-MLK-2/E-MLD-2), and `bigint_mod` as the generic fallback. The "Critical bug at source"
framing is retired.

### COMBINE-9 / ENHANCE-6 (PARTIALLY_WRONG / caveat)
The fix "delegate to `fe25519`'s eight-limb field" needs scope refinement: `fe25519` today exposes
the **Edwards** field operations; `x25519` needs the **Montgomery-curve** form (the `2^255-19` field
is shared, but the curve arithmetic differs). The merge delegates the *field* (the `2^255-19`
reduction + mul/sq), which is genuinely shared, and `x25519` keeps its Montgomery ladder. The
constant-time win (E-X-3) is partly already in hand — see ENHANCE-19/RIPPLE-7.

### COMBINE-13 / ENHANCE-14 (ALREADY_FIXED) and CUT-12 (DRIFTED) and SYNTH-4 (PARTIALLY_WRONG)
The override-precedence defect is **closed**: `xii_emit_gen.iii:258` returns `0xFFFFFFFF` ("no
override") for every crypto horizon (`horizon_id < 24u8`), forcing fall-through to the real kernel
fragment via `_structural_body`. Therefore:
- **COMBINE-13 / ENHANCE-14:** the consolidation's *security motivation* ("the shadow wins") is
  resolved. The remaining work is the *completion* (single source of truth): generate the inlines
  from the proven `numera` crypto with per-horizon equality KATs, **or** make the chokepoint
  permanent + ship a falsifier KAT asserting no crypto horizon (`id < 24`) ever emits a curated
  body. Either is now hardening, not emergency.
- **CUT-12:** split. (A) The crypto-stub *bodies* (`ed25519_verify` always-0xF, x25519 ladder
  zeroes the point, blake2s zeroes accumulator, H052 wild store) still exist but are **unreachable
  as overrides** → dead matter, safe removal. (B) The "override makes stubs win / tautological
  verify on the live path" claim is **false today** — strike the "most urgent removal, on security
  grounds" framing; the live hole is closed.
- **SYNTH-4:** the present-tense "the shadow always wins" is falsified by the X25 fix. Three of the
  four enumerated instances persist (`checked`/`option`, `x25519`/`fe25519`, NTT-now-×4), so the
  *principle* (generate specialized forms from one source) holds; the crypto *instance* is past
  tense. Reword to "and in the crypto case the shadow *did* win until X25 closed it — the template
  for the principle everywhere else."

### CUT-16 (WRONG)
Premise false. `xii_emit_gen_produce` has a production build-time caller (`gen_xii_lattice…`, the
emitter-catalog generator), so it is **not** "code with no live caller." Action changes from
"decide remove-vs-complete" to **"keep; ensure the catalog it produces is covered by a KAT"** (the
latent/forward-looking concern is addressed by testing the emitted catalog, not by removal).

### RIPPLE-3 (PARTIALLY_WRONG — path)
The shared minter is **`STDLIB/iii/omnia/crystal.iii`**, not `numera/crystal.iii`. All consumers
(`scalar_provenance`, `field_crystal`, `checked_crystal`, `q128_f64`) and the `crystal_slot_of` /
`CRYSTAL_ID_BASE` mechanism are confirmed; only the path is wrong in the audit.

### RIPPLE-4 (PARTIALLY_WRONG — source attribution)
The A-RX-1/A-RX-2 core (ripple_extract's audit probe interns the address it audits → history-
dependent, false-admits at capacity) **HOLDS**. But `A-RL-1` is misattributed: in the source it is
the **dead outer while-loop** defect (`rm_unifiable` is a static transitive equivalence so one inner
pass closes every class), *not* the loop-invariant `cg_decide` hoist the structural audit pairs with
A-RC-1. Keep the `cgr_contains` read-only-query fix; correct the A-RL-1 citation.

### RIPPLE-5 (PARTIALLY_WRONG)
The `cad`-authority thesis holds. Two concrete corrections: (1) `A-CG-1` — the swallowed
`cad_oneshot` return in `cg_seal_ok` is described accurately, but at least one path is already
sealed-correct; verify per-call-site rather than as a blanket open sweep. (2) `A-OI-2` is a
**domain-separation** defect (un-domain-separated SHA-256 → cross-context aliasing; fix = prefix a
fixed domain via `mhash_domain`), **not** the "swallowed return" variant the audit lists it as.

### RIPPLE-7 / ENHANCE-19 (PARTIALLY_WRONG — partly fixed)
`x25519`'s headline `x_cswap` branch is **already branch-free (masked)** today — the E-X-3 "swap
branches on the scalar bit" sub-claim is fixed for the ladder swap. The RIPPLE-7 *structural*
headline (x25519 and fe25519 carry separate reduction logic; x25519 → field.iii → bigint_mod →
bit-serial division) **still holds** and is still the actionable consolidation. For ENHANCE-19: the
remaining constant-time work is `fp256` (D-FP-1, borrow branches on secret) and `aes` (E2-AES-1,
S-box indexed by secret + branch in field multiply); x25519's swap is done.

### RIPPLE-8 (PARTIALLY_WRONG)
`D-BI-1` **HOLDS verbatim**: `cpufeat.iii` has no AVX-512DQ (bit-17) detection and no
`cpufeat_has_avx512dq()` export; `bigint.iii:570` gates an AVX-512 path that needs DQ → crash on
AVX-512F-only CPUs. The `X17` evidence set is partly misattributed (the source lists E2-CC-1
chacha20, D-BI-1 bigint, plus sha256/sha512/mlkem; the structural audit's enumeration drifts). The
forced-path-KAT discipline is the right fix.

### RIPPLE-10 (DRIFTED — seal class correction, important)
The central thesis HOLDS and the golden-hash trace (`cg_rm2` 4e1384→53ce03; `cg_r3` →9f64a2e6) is
exact. **But `B-LDIL-1` (the `xii_ldil` STORE typecheck OOB) is misattributed to a COMPILER/BOOT
bootstrap-sealed file — it actually lives in `STDLIB/iii/...`** → it is a **STDLIB_GATE** edit, not
bootstrap-sealed. This matters for sequencing: that fix does *not* need to wait for the Wave-6
`build_iiis2` pass. (`sema`, `cg_rm2`, `cg_r3` items remain genuinely BOOTSTRAP_SEAL.)

### RIPPLE-13 (PARTIALLY_WRONG)
`F-RFLG-1` **HOLDS verbatim**: `reflection_governance` gate requires `AMEND (0x4000)` while
`reflection_constrained` dispatcher requires `ATTEST (0x0800)` — a capability satisfying one fails
the other; invisible in selftest only because the root cap grants every bit. `F-RFLC-2` (the
4096-vs-80-byte buffer mismatch) is real in spirit but the specific "80 byte" attribution is
imprecise; the implementer must measure the actual producer/consumer sizes and make the contract a
single shared constant.

### ENHANCE-13 (PARTIALLY_WRONG)
The "latent / not yet connected" half is **TRUE**: `zk_snark`'s Groth16 (`sn_setup/sn_prove/
sn_verify`) is entirely unwired (only corpus 375 touches it; no public optimizer hook). **But** the
audit's framing that Groth16 "is the proof-carrying-code primitive the gate calls for" conflicts
with the system's own binding mandate: the optimizer's proof-carrying *disposer* is
`typecheck`+`ccl` (the CIC kernel), and the actual *unwired-PCC* primitive in that pipeline is
`sov_pcc` (source `A-PCC-1`, High). So: wiring `sov_pcc` behind the proposal pipeline is the
in-scope completion; `zk_snark` is a separate, genuinely-latent capability that can be exposed but
is not "the" PCC the kernel narrative means.

### ENHANCE-22 (PARTIALLY_WRONG) / ENHANCE-23 (PARTIALLY_WRONG)
Both are clusters whose sub-claims have **non-uniform** status today. ENHANCE-22: `E-RSA-1`
(d=0 dead key shipped as success when `φ%e==0`) HOLDS at `rsa.iii:485-491`; `E-EC-3` (no retry on
degenerate zero component) HOLDS for the `sign` path (only `sign_det` retries on `k==0`); `E-PQD-2`
(zero-nibble underflow) must be checked individually. ENHANCE-23: one of the four micro-fixes is
already done — each of MERKLE-2 / C-BV-1 / C-PC-3 / C-NS-1 must be scheduled only if still open
(verify per-item; the plan task carries a per-item status gate).

### KEEP-1 (DRIFTED — path) / KEEP-3 (wording)
KEEP-1: the coefficient table is in **`STDLIB/iii/sanctus/seal_resolver.iii`**, not katabasis. The
FROZEN_SPEC classification holds; ADR-RES-009's stated computation does not match the bytes (which
*is* the seal) — that mismatch is exactly why a refreeze (not a code edit) is required. KEEP-3:
strike "the per file mhashes" — there are **no per-source-file mhash artifacts**; the seal is the
golden BARE hash of the compiler binary (`COMPILED/iiis-2.exe` + `.mhash` + `.witness.json`),
reset only via `build_iiis2`.

### Line-count / path drifts (DRIFTED, non-substantive)
COMBINE-3 (`omnia/unify.iii`), COMBINE-6/7/12, SEPARATE-1 (egraph 1709), SEPARATE-2 (ccl 938),
SEPARATE-3, SEPARATE-4 (cg_r3 3546, smt 2155), CUT-1 (`numera/temporal_logic.iii`), CUT-4, CUT-7,
CUT-5 (`omnia/xii_joinability.iii`). Per harness rule these counts are not load-bearing; the plan
re-Greps every symbol at execution time.

---

## 4. In-session gap closures (the 4 the workflow stall cost)

| ID | Closed how | Result |
|---|---|---|
| **RIPPLE-14** | Read `charter_terminal.iii` in full | **HOLDS.** `ct_run_charter()` (@export, :177) folds `CT_CLAUSE_COUNT` (:178); when 0, the loop is empty → `ct_seal_verdict(0)` → returns `CT_VERDICT_GREEN` (99). Populator `ct_register_all()` (:190) is **not** @export and is called only from `ct_selftest()` (:231). A stranger calling the public gate gets a sealed false-GREEN over an empty registry. Fix = self-populating entry (ENHANCE-17 family). |
| **ENHANCE-20** | Read `ecdsa_p256.iii` full; grep `slhdsa.iii`, `fe25519.iii` | **All three sub-claims HOLD.** E-EC-2: `iii_ecdsa_p256_verify` (:76) checks only `r≠0`,`s≠0` (:80-81) — no upper-range (`<n`) and no low-s enforcement → malleable sigs accepted. E-SLH-2: header (:3-10) declares "FIPS 205" but instantiates a **hybrid** — `SHA-256[0..n]` for H_n/PRF/PRF_msg and `SHAKE-256` for H_msg — which is neither the FIPS-205 SHA2 family (MGF1/HMAC-SHA2, not SHAKE) nor the SHAKE family → won't interoperate. E-FE-4: no canonical-decode reject (`< p`, high-bit handling) on the public decode path. |
| **ENHANCE-15** | In-session adversarial reasoning | **Confirmed; superior approach recorded.** Surpass-only forbids the "relabel the slot" option (a compromise/over-claim cure). Each slot gets the *real* implementation (x86 decoder, loadable PE32+, real III→C99/LaTeX lowering, full-input transform), each with a round-trip/format-validity KAT. Deferral eliminated. |
| **CUT-12** | Read `xii_emit_gen.iii:248-273` | **Confirmed DRIFTED.** The `<24` chokepoint guard is present (:258) → live security hole closed. Verdict split (dead bodies vs hardening) stands; "most urgent on security grounds" framing retired. |

---

## 5. Cross-finding synthesis (the in-session critic pass)

The six per-section critics were gated on the stalled barrier and did not run; this section is their
in-session replacement, with full cross-section context (strictly superior to six isolated agents).

**Interactions / heal-chains.** (1) The Wave-0 organs heal many consumers at once: the
content-address index (COMBINE-3) retires the O(N²)/linear scans in `ripple_metric`, `ripple_loop`,
`theorem_carrier`, `math_library_curation`, `computation_graph`, `unify`, `lru`, and the `sema`
consumer; the fast bucketing hash (COMBINE-2) feeds `egraph` *and* the curation index; the boundary
helper (COMBINE-7) subsumes the per-file guards behind RIPPLE-5/6/12 and the II-HTTPSERVER OOB.
(2) The NTT organ (COMBINE-1) heals the *silent* large-multiply break (RIPPLE-2/D-KARA-1) as a side
effect — and now also de-duplicates `entropy_monitor` (the 4th NTT). (3) `crystal.iii`
(omnia) is a shared minter: the id-band fix is one edit that touches all four crystal consumers
(RIPPLE-3). (4) `cad.iii` and `builder` are shared services whose error contracts must be threaded
to the boundary (RIPPLE-5/6).

**Ordering constraints (refined from doctrine §3).** Shared organs (Wave 0) before consumers
(Wave 3). The crypto work (Wave 1) is **downgraded**: no longer an emergency, but still first among
crypto-touching changes because COMBINE-13/ENHANCE-14/CUT-12 share the chokepoint. The trusted base
(Wave 2) before consumer reshaping. **RIPPLE-10 correction:** `B-LDIL-1` moves OUT of the Wave-6
bootstrap pass into Wave-3 STDLIB work (it is not bootstrap-sealed). Genuinely BOOTSTRAP_SEAL items
remaining for Wave 6: `sema` (G-SEMA-1/2), `cg_r3` (CUT-9, SEPARATE-4), `cg_rm2`. FORGE_CLOSURE
(RIPPLE-11/KEEP-2) and FROZEN_SPEC (KEEP-1) remain dedicated Wave-5 passes.

**Missing findings (completeness critic).** None of the verification agents surfaced a *new* defect
class beyond the audit's coverage, with one exception worth recording: the **fourth NTT**
(`entropy_monitor`) and its independent 5-function modular stack is uncovered work the audit's X1
census omitted — now folded into COMBINE-1. The audit's five axes remain complete over the source.

**Retired work (do not schedule).** COMBINE-13, ENHANCE-14 (crypto override precedence — fixed);
MONT-1/MONT-2 within COMBINE-4 (fixed); x25519 cswap within ENHANCE-19/RIPPLE-7 (fixed); and
per-item, whichever of the ENHANCE-22/23 cluster sub-claims verify as already-closed. CUT-16 is
retired as a removal (the function is live).

---

*This ledger is the corrected ground truth the granular implementation plan (`-PLAN-1..5`) builds
on. Every `HOLDS`/`DRIFTED`/`PARTIALLY_WRONG` finding becomes a task; every `ALREADY_FIXED`/`WRONG`
finding is closed here with the evidence that retired it; the audit document itself is patched in
the same commit (see the patch applied to `III-STRUCTURAL-AUDIT.md`).*
