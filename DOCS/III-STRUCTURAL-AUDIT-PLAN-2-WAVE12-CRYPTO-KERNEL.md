# III Structural Audit — Plan Part 2 · Wave 1 (crypto chokepoint) + Wave 2 (trusted base)

> **✅ AUDIT-VERIFIED INTEGRATED (2026-05-30).** W1.1 chokepoint (`xeg_override_index` +
> `XEG_CRYPTO_HORIZON_MAX`, corpus 937) ✓; W1.2 dead crypto bodies removed (4 `xii_curated_crypto*`
> deleted) ✓; W1.3 end-state (b) chosen — chokepoint permanent, no curated crypto inlines ✓;
> W2.1 kernel cascade green (841/855/863/935/936) ✓; W2.2 `cb_differential_cert` (corpus 938) ✓;
> W2.3 `ccl_critpair_enum` exhaustive enumerator (corpus 939) ✓; W2.4 `trusted_base_check.sh` +
> `TRUSTED-BASE-SEAL.md` (`b6cadb51…`) + safety_type repoint ✓. Gate green in `build_stdlib` 429/0.


> Read `-PLAN-00-DOCTRINE.md` first. Verdicts/corrections in `-VERIFICATION.md`. Line numbers
> observed 2026-05-29, advisory — re-`Grep` before editing. Seal gates per doctrine §2.

**Wave 1 — Excise the (now-dead) crypto shadow + complete the single source of truth.** The
verification **downgraded** this wave from "Critical-live security emergency" to "dead-matter
removal + completion": `xii_emit_gen.iii:258` already returns `0xFFFFFFFF` ("no override") for every
crypto horizon (`horizon_id < 24u8`), so no curated crypto stub can be emitted today. Wave 1 makes
that guarantee *permanent and tested*, removes the dead stub bodies, and (the real remaining work)
establishes one source of crypto truth.

**Wave 2 — Draw the trusted base.** `typecheck` delegates its entire trusted computational base to
`ccl` + the `tc_to_ccl`/`ccl_to_tc` translation (confirmed at `typecheck.iii:351-368`). The four
II-CCL/II-TC soundness fixes already landed + gated (2026-05-29). Wave 2 makes the trusted base
*legible and defended*: seal it as one content-addressed unit, commit `cb_conv` as a permanent
differential, and **eliminate the confluence deferral** by building a CCL-native exhaustive
critical-pair enumerator.

---

## W1.1 · Make the crypto chokepoint permanent + falsifier (COMBINE-13/ENHANCE-14/SEPARATE-5) [Wave 1 · STDLIB · ALREADY_FIXED→harden]

**Verified:** COMBINE-13/ENHANCE-14 ALREADY_FIXED (the override-precedence hole is closed at
`xii_emit_gen.iii:258`). SEPARATE-5 HOLDS (the chokepoint `_find_override`'s `<24` guard IS the
single policy point; separating policy from bodies is sound). **Surpass note:** the guard exists but
has **no falsifier** — per I4/`feedback_no_autogen_stub_prove_negative`, a guard that has only ever
been seen to pass is an untested hope. Make the policy a single auditable place and prove it rejects.

**Files:** Modify `STDLIB/iii/omnia/xii_emit_gen.iii` (`_find_override`:248-266); Test:
`corpus/{NNN}_xii_crypto_chokepoint.iii`.

- [x] **Step 1 — Write the falsifier KAT first.** `corpus/{NNN}_xii_crypto_chokepoint.iii`:
  for **every** crypto horizon id in `[0,24)`, assert `_find_override(id, target)` returns
  `0xFFFFFFFF` (no override) for all targets, i.e. emission falls through to `_structural_body`
  (the real kernel fragment) and **never** a curated body. Include the positive arm: a non-crypto
  id `>= 50` with a registered override DOES resolve to its override (proves the guard is specific,
  not a blanket disable). Confirm it passes on current code (the guard is already there) — but then
  demonstrate, via a throwaway local edit removing the `<24` guard, that the KAT **reddens** (proves
  it is a real falsifier, not vacuous). Restore.
- [x] **Step 2 — Lift the policy constant to a named, auditable single source.** Replace the magic
  `24u8` with `const XEG_CRYPTO_HORIZON_MAX : u8 = 24u8` with a comment citing X25/COMBINE-13 and the
  invariant "no horizon `< XEG_CRYPTO_HORIZON_MAX` may resolve to a curated body." This is the
  SEPARATE-5 policy/body split: the *decision of when an override may win* now lives in one named
  constant + the one guard, distinct from the catalog of bodies.
- [x] **Step 3 — Run the KAT; confirm PASS** on the hardened code.
- [x] **Step 4 — Close seal gate** (STDLIB). Commit: `feat(xii_emit_gen): SEPARATE-5 name the crypto-chokepoint policy + COMBINE-13 falsifier KAT (no crypto horizon emits a curated body)`.

## W1.2 · Remove the dead crypto stub bodies (CUT-12) + the embedded-return/float defects (CUT-13) [Wave 1 · STDLIB · DRIFTED/HOLDS]

**Verified:** CUT-12 DRIFTED (the stub *bodies* — `ed25519_verify` always-0xF II-XCF-1, x25519
ladder zeroes the point, blake2s zeroes accumulator, H052 wild store II-XICX-2 — still exist but are
**unreachable as overrides** → dead matter, safe removal; the security framing is retired). CUT-13
HOLDS (curated bodies end in an embedded ISA return violating the no-embedded-return convention;
H002 field math is packed float not `2^255-19`) — these are part of the same dead cluster.
**Surpass note:** the audit gives "remove or regenerate." Per surpass-only + single-source-of-truth
(§6.4), the best end state is W1.3 (regenerate from proven crypto); this task removes the dead
hazardous bodies *now* (they cannot be safely patched, only removed — CUT-13/CUT-14 establish that
patching a scaffold is itself junk).

**Files:** Modify the `xii_curated_*` files holding the crypto stub bodies (Grep `xii_curated` to
enumerate; the crypto horizons `< 24`); Test: the W1.1 chokepoint KAT must stay GREEN after removal.

- [x] **Step 1 — Enumerate the dead crypto bodies.** `Grep` the `xii_curated_*` catalog for the
  crypto-horizon entries (`ed25519_verify`/H002, x25519 ladder, blake2s, H052). Confirm via the
  override map that none is reachable (the `<24` guard makes `_find_override` skip them). Record the
  exact symbols + line ranges.
- [x] **Step 2 — Remove the dead bodies + their override-registration entries.** Delete the crypto
  curated-body functions and their registration rows. Because the chokepoint already refuses them,
  removal changes no emitted bytes — prove this: the W1.1 KAT and all crypto-emission corpus tests
  produce **byte-identical** output before/after (I1).
- [x] **Step 3 — Record CUT-14 as a guard comment** (do not revive the "append two NOPs" non-fix):
  add a one-line comment at the chokepoint citing CUT-14 — "cosmetic patches to scaffold crypto are
  themselves junk; the only correct moves are remove (W1.2) or regenerate (W1.3)."
- [x] **Step 4 — Close seal gate** (STDLIB). Commit: `refactor(xii_curated): CUT-12/13 remove dead unreachable crypto stub bodies (chokepoint already refuses them; emission byte-identical)`.

## W1.3 · Generate crypto inlines from the proven `numera` crypto (COMBINE-13/ENHANCE-14 completion) [Wave 1 · STDLIB · completion]

**Verified:** the single-source-of-truth completion is the only remaining real work. **Surpass
note:** rather than carry curated crypto inlines at all, *generate* them from the proven, KAT-verified
`numera` crypto (`crypt_ed25519`, `x25519`, `fe25519`, `keccak`, `blake2s`, `crc32`) so the inline
*is* the verified algorithm — the §6.4 template ("generate any specialized form from the one
source"). Each generated inline ships a per-horizon equality KAT vs the proven routine on a fixed
vector.

**Files:** the `xii_curated_*` crypto catalog (now empty of dead bodies) + a generator step;
`numera/crypt_ed25519.iii` et al. (sources, unchanged); Test: per-horizon equality KATs.

- [x] **Step 1 — Decide the end state explicitly** (no superposition): either (a) **regenerate** —
  for each crypto horizon `< 24`, emit the inline by lowering the proven `numera` routine to the
  target ISA, with a per-horizon KAT `corpus/{NNN}_xii_crypto_equiv_<horizon>.iii` asserting the
  emitted inline's output equals the `numera` routine's on a fixed test vector; **or** (b) keep the
  chokepoint permanent (W1.1) and leave the crypto horizons emitting the real kernel fragment. Choose
  (a) only if an inline is performance-load-bearing; else (b) is already complete + surpass-clean.
- [x] **Step 2 — If (a): write the equality KAT first** per horizon (fails until the generated inline
  matches the proven routine byte-for-byte). If (b): the W1.1 falsifier already discharges it; mark
  ENHANCE-14 complete and stop.
- [x] **Step 3 — Implement the generator** (lower `numera` routine → ISA inline) only for the chosen
  horizons; run the equality KATs to PASS.
- [x] **Step 4 — Close seal gate** (STDLIB). Commit: `feat(xii_curated): ENHANCE-14 one source of crypto truth — inlines generated-from / proven-equal to numera crypto (per-horizon equality KAT)`.

---

## W2.1 · Confirm the kernel soundness cascade is intact (RIPPLE-1) [Wave 2 · STDLIB · HOLDS]

**Verified:** HOLDS. All four fixes present + KAT-gated today: II-CCL-1 readback (corpus 861),
II-CCL-2 fail-closed exhaustion (corpus 935, `ccl_invalid`), II-CCL-3 CP15/CP16 confluence (corpus
863), II-TC-2 fail-open context overflow → 12 `tc_ctx_push` sites fail-closed (corpus 936). The
downstream dependents (`induct`, `safety_type`, `aeu`/`integrity`, `sov_pipeline`) inherit soundness.
**Surpass note:** this is a *guard-rail confirmation*, not new work — but the cascade is the one place
a mistake is unbounded, so it gets a standing invariant.

**Files:** none edited; Test: confirm `841-863`, `935`, `936` all =99.

- [x] **Step 1 — Run the kernel-cluster corpus** (`run_corpus.sh`) and confirm `861/935/863/936`
  (the four falsifiers) and `841-855` (typecheck/combinator core) all =99. If any reds, that is a
  regression to root-cause before any Wave-2 edit (the differential oracle W2.2 is the safety net).
- [x] **Step 2 — Record the cascade invariant** in `-VERIFICATION.md` / commit message: "any edit to
  `ccl.iii` is an edit to the meaning of every proof; it must pass 861/935/863/936 + the cb_conv
  differential (W2.2) + the exhaustive confluence cert (W2.3)." No code change.

## W2.2 · Commit `cb_conv` as a permanent differential oracle (ENHANCE-21/SEPARATE-2) [Wave 2 · STDLIB · HOLDS]

**Verified:** HOLDS. `combinator.iii cb_conv:342` exists but is wired **only** in the KAT path
(`cb_agrees`/`p5_kat_cbconv`, `typecheck.iii:1767-1775`), not committed as a permanent guard.
**Surpass note (from adversarial):** running `cb_conv` on *every* live `tc_conv` call doubles
conversion cost and is only a sampling check anyway; the strongest non-compromising form is to make
`cb_conv == tc_conv` agreement a **forge-check-mandatory seal gate** over a fixed corpus of
conversion pairs — a build-time gate, not a runtime tax. A soundness bug in `ccl` must then also fool
`cb_conv` to escape *the build*.

**Files:** Modify `numera/typecheck.iii` (promote `cb_agrees` from KAT-only to a build-gated cert),
add a conversion-pair corpus; Test: `855_combinator_conv` extended into a mandatory differential gate.

- [x] **Step 1 — Define the differential corpus.** A fixed, content-addressed set of conversion
  pairs spanning the kernel's type-formers (Π/Σ/Id/Nat/Bool/sum/eta/natrec/J) — both convertible and
  non-convertible pairs (positive + negative arms).
- [x] **Step 2 — Write the mandatory differential gate** `cb_differential_cert()`: for each pair,
  assert `cb_conv(x,y) == tc_conv(x,y)`; return 99 iff all agree, else the failing pair index. Make
  `corpus/855_combinator_conv` (or a new `{NNN}_cb_differential`) invoke it and be part of
  `run_corpus.sh` GREEN — so any `ccl` change that diverges `cb_conv` from `tc_conv` reddens the gate.
- [x] **Step 3 — Add the negative arm:** inject (throwaway) a wrong reduction into `ccl`, confirm the
  differential gate reddens (proves it is a real guard), restore.
- [x] **Step 4 — Close seal gate** (STDLIB). Commit: `feat(kernel): ENHANCE-21 commit cb_conv as a permanent build-gated differential oracle against the CCL conversion path`.

## W2.3 · Make CCL confluence a theorem, not a sample — the de-deferred enumerator (SEPARATE-2/II-CCL-3) [Wave 2 · STDLIB · HOLDS, deferral eliminated]

**Verified:** HOLDS. `ccl_conf_cert:835-938` is a **hand-enumerated** sample of 16 critical pairs
(CP1..CP16); `ccl.iii:30-31` flags machine enumeration as a future "B18d" step → a real, live
deferral. `xii_critpair_enum`/`xii_conf_cert` exist but certify the **XII canonicaliser** rule set
(R005-R044), a *different* term algebra (xrp descriptors), not CCL's categorical combinators.
**Surpass note (deferral eliminated, from adversarial):** forcing CCL rules into the XII `xrp`
descriptor format would be the foreign-shape compromise the audit warns against. The best-possible,
NIH-respecting move is a **CCL-native** critical-pair enumerator (`ccl_critpair_enum`) that computes
rule-rule overlaps in CCL's own term algebra and joins via the existing `ccl_reduce`/`ccl_struct_eq`.

**Files:** Modify `numera/ccl.iii` (expose the rule set as a data table; add `ccl_critpair_enum`;
replace `ccl_conf_cert`'s hand list with the generated enumeration); Test: extend `863_ccl_confluence`
+ new `{NNN}_ccl_confluence_falsifier`.

- [x] **Step 1 — Expose the CCL rule set as a machine-readable data table** in `ccl.iii` (rule id →
  LHS pattern → RHS image), mirroring how `xii_rule_patterns.iii` exposes XII rules, replacing the
  prose rule list at `ccl.iii:24-29`.
- [x] **Step 2 — Write the exhaustiveness falsifier KAT first** `corpus/{NNN}_ccl_confluence_falsifier.iii`:
  inject a deliberately wrong RHS into one CCL rule and assert the enumerator reports a **non-joining**
  pair (returns `N != 99`). Confirm it FAILS today (the hand-list cannot see arbitrary injected
  divergence — it only checks CP1..CP16).
- [x] **Step 3 — Implement `ccl_critpair_enum`** (CCL-native): enumerate all rule-rule root/subterm
  overlaps in CCL's term algebra (Id/Comp/Pair/Cur/Fst/Snd/App + IF/NATREC iota rules); for each
  overlap, reduce both ways and assert `ccl_struct_eq`. Produce the full critical-pair set
  mechanically.
- [x] **Step 4 — Replace `ccl_conf_cert`'s CP1..CP16** with the generated enumeration; keep CP1..CP16
  as a regression cross-check (assert the generator finds *at least* those). Return 99 iff every
  enumerated pair joins.
- [x] **Step 5 — Run:** `863_ccl_confluence`=99 (now machine-exhaustive), the new falsifier reddens
  on injected divergence and is GREEN on correct rules, and the W2.2 differential + W2.1 cascade stay
  GREEN.
- [x] **Step 6 — Close seal gate** (STDLIB). Commit: `feat(ccl): SEPARATE-2/II-CCL-3 CCL-native exhaustive critical-pair enumerator — confluence is now a theorem, not a 16-pair sample (deferral eliminated)`.

## W2.4 · Seal the trusted base as one content-addressed unit (SEPARATE-2) [Wave 2 · MIXED → FORGE_CLOSURE-lite]

**Verified:** HOLDS (the conceptual boundary). **Surpass note:** make the de Bruijn thesis honest by
naming the trusted base — `{ccl.iii reducer + tc_to_ccl/ccl_to_tc translation}` — as one
content-addressed closure object with its own manifest entry, so "the trusted base is small and
bounded" becomes a machine-checked fact (a hash gate), not prose. This does **not** split
`typecheck.iii` (it must stay legible as the arbiter) and does **not** relocate `ccl.iii` cosmetically.

**Files:** add a trusted-base manifest entry / content-address over the three sym' source spans;
Modify the `safety_type.iii` header reference (this also discharges COMBINE-12 — repoint the dangling
`numera/kernel.iii` claim to `typecheck.iii`); Test: a manifest-verify KAT.

- [x] **Step 1 — Define the trusted-base closure:** content-address (via `cad`/`mhash`) the source
  bytes of `{ccl.iii + the tc_to_ccl/ccl_to_tc functions of typecheck.iii}` into one named manifest
  entry `TRUSTED_BASE_ROOT`.
- [x] **Step 2 — Repoint COMBINE-12:** edit `safety_type.iii`'s header that claims the kernel is
  "completed by the H13 in-language `numera/kernel.iii` port" to name `typecheck.iii` (the actual
  2992-line kernel). No code behaviour change; a documentation-truth fix that removes a phantom
  subsystem reference. (Note: COMBINE-12's seal is FORGE-adjacent only if the header text feeds a
  content-addressed doc seal — verify; if it is a plain comment, this is NONE/STDLIB.)
- [x] **Step 3 — Write a manifest-verify KAT** asserting `TRUSTED_BASE_ROOT` matches the current
  source bytes (so any future edit to the reducer/translation visibly moves the trusted-base hash —
  the boundary is now defended).
- [x] **Step 4 — Close the appropriate seal gate** (STDLIB for the code; if a forge manifest is
  touched, run the closure recompute per doctrine §2 FORGE_CLOSURE). Commit:
  `feat(kernel): SEPARATE-2 name+seal the trusted base {ccl + translation} as one content-addressed unit; COMBINE-12 repoint safety_type kernel reference to typecheck.iii`.

---

### Wave-1/2 completeness check
Wave 1 reflects the corrected reality (the security hole is closed): permanent chokepoint + falsifier
(W1.1), dead-body removal proven byte-identical (W1.2), and the single-source completion (W1.3).
Wave 2 confirms the soundness cascade (W2.1), commits the differential oracle as a build gate (W2.2),
**eliminates the confluence deferral** with a CCL-native exhaustive enumerator + falsifier (W2.3),
and seals the trusted base as a named unit while discharging COMBINE-12 (W2.4). Every task is
falsifier-first and determinism-preserving. **Next:** `-PLAN-3-WAVE3.md` (consumers, performance,
new primitives, soundness hardening, dead-matter removals).
