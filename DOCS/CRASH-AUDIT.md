# CRASH-AUDIT — Phase XII-φ: iiis u32-in-u64-slot codegen retrofit

CRASH-PROTOCOL governed. Phase 1 = EVIDENCE only (read-only; NO
.iii/.c/.py edits until this audit is complete AND a reproduction is
obtained). This file is the mandated Phase-1 artifact.

## 0. Trigger

`STDLIB/iii/numera/sha256.iii:19-27` documents an "IIIS-2 CODEGEN
WORKAROUND": every u32-producing expression masked `& 0xFFFFFFFFu32`
because "the deployed Stage-2 compiler stores u32 locals in 64-bit
stack slots and uses 64-bit arithmetic (addq, shrq, shlq); multi-operand
u32 sums overflow into high 32 bits and leak through subsequent loads".
Claims "Phase E (compiler retrofit) will remove the masks once iiis
emits proper 32-bit ops." Matches the CLAUDE.md documented trap
"u32-in-u64-Slot Garbage Bug".

Standard 3 (fix ALL workarounds, root not symptom, even if harder) ⇒
the directive-correct fix is the compiler, not the masks. Standard
5/6 + CRASH-PROTOCOL ⇒ full evidence + reproduction before any edit
(this is the most bit-identity-critical change in the substrate:
u32 codegen touches every u32 op in every module → iiis-0/1/2 mhash,
all 246 .o, the whole corpus, triple-identity, determinism seals).

## 1. Blast radius (workaround sites — bounded)

`& 0xFFFFFFFFu32` genuine mask sites are concentrated, NOT pervasive
(many `0xFFFFFFFFu32` hits are unrelated sentinels e.g.
xii_critpairs `XCP_NULL_REF`):

- numera/sha256.iii : 2     numera/blake2s.iii : 11
- numera/crc32.iii  : 3     numera/sha512.iii  : 0  (uses u64)

The compiler FIX has unbounded blast radius (every u32 op); the
workaround REMOVAL has bounded radius (the crypto modules above +
the corpus masks). KAT guards: corpus 02 (sha256 abc=186), 15
(sha256 empty=227), 83 (blake2s=80), 82 (crc32=203).

## 2. Mechanism located (read-only)

cg_r3.c (C reference; cg_r3.iii must byte-mirror it):

- `byte_width("u32") = 4` (cg_r3.c:519); `pointer_element_width`
  u32→4 (747/781).
- **Width-aware LOCAL load EXISTS and explicitly targets this trap**:
  cg_r3.c:1090-1135 — comment *"preserving any garbage in the high 4
  bytes for a u32 … (the u32-in-u64-slot trap)"*; u32 ⇒
  `mov_op="movl"` ⇒ `movl -slot(%rbp),%eax` (writing %eax auto-zeros
  high 32 of %rax). Global load same (1162-1198, "implicit
  zero-extend to rax"). Cast/narrow path `movl %eax,%eax`
  (1031-1052).
- cg_r3.iii mirrors: line 342 comment; `r3_emit_local_load_width_aware`
  (665) emits `movl -slot(%rbp),%eax` for the u32 TYPE_REF case (684);
  movslq/movzwq/movswq/movzbq/movsbq for i32/u16/i16/u8/i8 (688-704).
- BUT: the width-aware load falls back to `r3_emit_local_load_default`
  = 8-byte `movq -slot(%rbp),%rax` (cg_r3.iii:707/710-711) when the
  ident's type is NOT statically resolvable at the load site
  (bid==0 / tnode==0 / tk!=R3_K_TYPE_REF, 667-680).
- Store path: `r3_emit_store_rax_slot` (cg_r3.iii:714) is
  UNCONDITIONAL 8-byte `movq %rax,-slot(%rbp)` — high garbage in
  %rax (from 64-bit addq/shlq/shrq on u32 operands) is persisted.

## 3. Open question (settle by REPRODUCTION, not assumption)

The mitigation in §2 means the bug is NOT unmitigated in the current
compiler. Two hypotheses, must be decided empirically:

- **H1 (stale comment):** the width-aware load IS the "Phase E"
  retrofit, already landed. Multi-operand u32 arithmetic that is
  re-loaded through a typed local/global gets zero-extended on load,
  so results are correct WITHOUT masks → sha256.iii masks are
  redundant cruft (Standard-3 stale-workaround removal: delete masks,
  re-prove KATs).
- **H2 (residual leak):** a path still bypasses the width-aware load
  (untyped temporaries; arithmetic chained in %rax without an
  intervening typed reload; the unconditional 8-byte store feeding a
  default 8-byte load). Masks still required → deeper Phase-3
  codegen fix (store-width-by-type and/or arith-result narrowing),
  byte-mirrored cg_r3.c ↔ cg_r3.iii.

## 4. Next Phase-1 step (in progress)

Build a minimal reproduction probe (NEW corpus test = evidence
instrument, not an edit to compiler/.iii under audit): multi-operand
u32 sums + shifts WITHOUT masks, compiled by COMPILED/iiis-2.exe,
asserting 32-bit wraparound. rc determines H1 vs H2. Then complete
the binary-level read (disassemble the probe's u32 ops in the .o) and
append results here before ANY fix.

NO .iii/.c/.py edit until §3 is resolved with binary evidence.

## 5. RESOLUTION — H1 confirmed (Phase-1/2 evidence complete)

Reproduction probe (multi-operand u32 sums + `>>`/`<<`/rotr, NO masks),
compiled by each stage, run:

- iiis-0.exe rc=0   iiis-1.exe rc=0   iiis-2.exe rc=0

All three produce correct 32-bit-wrapping results unmasked. Binary
proof (objdump of the iiis-2 .o): every u32 local load is
`8b 45 xx` = `mov -0xN(%rbp),%eax` — a 32-bit movl into %eax that
architecturally zero-extends into %rax. Arithmetic is 64-bit
(`48 01 c8` addq, `48 d3 e8` shrq, `48 d3 e0` shlq) but each operand
is re-loaded width-aware (high 32 re-zeroed) before every use, so
"u32-in-u64-slot garbage" cannot accumulate. This is the
cg_r3.c:1090-1135 / cg_r3.iii:665-707 width-aware mitigation — it has
ALREADY landed and is triple-identical (rc=0 on all 3 stages).

**Conclusion: H1.** The `sha256.iii:19-27` "Phase E will fix" comment
is STALE; the compiler already emits proper 32-bit zero-extending
loads. The `& 0xFFFFFFFFu32` masks (sha256/blake2s/crc32) are
REDUNDANT, not load-bearing.

**Decision:** the directive-correct fix (Standard 3) is NOT a
compiler-codegen change (the compiler is provably correct on all 3
stages — an unbounded edit here would be unjustified and dangerous).
It is a BOUNDED stale-workaround removal: per affected module, delete
the redundant masks + correct the stale comment, then PROVE redundancy
per-module by its FIPS/KAT oracle (corpus 02 sha256 abc=186, 15
empty=227, 83 blake2s=80, 82 crc32=203) producing the EXACT expected
rc AND triple-bit-identity holding AND no full-corpus/determinism
regression. Per-module, KAT-gated — never blanket (a module whose KAT
fails after removal keeps its masks and is recorded as a residual
pattern for a targeted look; that is the no-declare-victory rule).

The CRASH-PROTOCOL did its job: reproduction-before-edit averted an
unbounded, unnecessary change to the most bit-identity-critical code.
Phase 1+2 evidence COMPLETE; Phase 3 (bounded removal) may proceed
under the per-module KAT gate.

## 6. §5 WAS WRONG — H1 REFUTED by the sha256.iii KAT (own the error)

Phase 3 attempt on sha256.iii: removed all 38 `& SHA_U32_MASK`,
recompiled, ran the FIPS oracle. **corpus 02_sha256_kat_abc rc=250
(≠186); 15_sha256_kat_empty rc=117 (≠227).** The masks are
**LOAD-BEARING** for sha256's real code paths on the deployed iiis-2.
**H1 is FALSE** here; H2-local holds.

Root error: §5's "masks redundant" generalised from a reproduction
probe that was a *proxy* — multi-operand sums + a single rotr — and
did NOT exercise sha256's actual pattern (e.g. the W-schedule
`(w16 + s0 + w7 + s1)`, the `(h+big_s1+ch+kk+ww)` 5-term T1 feeding
`(d+t1)`/`(t1+t2)` chained through `mut` locals across 64 rounds, or
`sha_rotr`'s `(xm<<(32-n))` composed with `^`). The probe passed
(rc=0 ×3) but proved nothing about THIS module. Classic
"found-one-thing-declared-victory" — the per-module KAT gate (the
no-declare-victory rule I wrote into §5) caught it exactly as
designed.

ACTION TAKEN: sha256.iii reverted byte-exact to the masked version
(no VCS — reconstructed from the verbatim in-context reads), re-built,
re-run: **02 rc=186 ✓, 15 rc=227 ✓, triple-identity 7e9be211 ×3,
build_stdlib FAIL=0.** FIPS correctness restored; substrate whole.

REVISED CONCLUSION:

- The sha256/blake2s/crc32 masks are NOT redundant cruft. They are a
  **necessary, FIPS-proven, honestly-documented accommodation** of a
  REAL residual iiis-2 u32-codegen limitation that the width-aware
  *load* mitigation (§2) does not fully cover for these patterns.
  This is the faithful-seam class (like sealed-ceremony / FROZEN-SPEC,
  Phases μ/ο): a documented, correct, necessary workaround — NOT a
  defect to rip out — UNTIL the compiler is genuinely retrofitted.
- The blanket "Phase 3 bounded removal across blake2s/crc32" plan is
  INVALID (rested on refuted H1) and is ABANDONED. No further mask
  removal without a per-module KAT proving redundancy AFTER a real
  compiler fix.
- The genuine root defect (iiis-2 u32 codegen still leaks for the
  sha256 pattern class) is REAL but its only correct fix is the
  compiler retrofit, which requires (a) a reproduction minimised from
  sha256.iii's EXACT leaking expression (NOT a generic proxy), then
  (b) the full CRASH-PROTOCOL on cg_r3.c/cg_r3.iii (the substrate's
  most bit-identity-critical code; genuinely tasks #16/#17 scope).
  This is a large, properly-pending phase — it will not be
  fake-closed.

Lesson: a generic probe is INSUFFICIENT evidence to declare a
specific module's workaround redundant. Only that module's own
oracle (its KAT) proves it. H1 vs H2 must be decided with the EXACT
failing pattern, never a proxy.

## 7. ROOT FIX LANDED (compiler), with an honest residual

Sound FIPS-oracle bisection of the REAL sha256.iii (not a probe):
re-masking expression classes one at a time under corpus 02/15
localised the load-bearing masks to EXACTLY `sha_rotr`. Binary
disasm of `L_sha_rotr` showed `shlq %cl,%rax` (64-bit) for the u32
`x << (32-n)` with the result's only cleanup being the trailing
`& 0xFFFFFFFF` (`and %rcx,%rax`). Defect: a `u32`-typed left-shift
is emitted as a 64-bit shift with no truncation — `u32 << k` must be
mod 2^32.

Fix (cg_r3.c AND cg_r3.iii, byte-equivalent): `expr_is_u32` /
`type_node_is_u32` (and `r3_expr_is_u32` / `r3_tref_is_u32`)
mirroring the existing `*_is_signed` trio; at `III_BIN_SHL`, after
`shlq`, emit `movl %eax,%eax` (zero-extends eax→rax) IFF the lhs is
PROVABLY u32/i32. Conservative: every non-provably-32-bit shift is
byte-identical to before.

Verified: iiis-0/1/2 rebuilt; triple-bit-identity HOLDS
(sha256/xii_critpairs/x25519 i0==i2); deterministic
(0f4ac80c/0fb14dde/528c0d49 reproduce); goldens resealed
(bare-hash). Whole substrate GREEN: build 246/0, corpus 258/0/0,
xii 93/0, 16 crypto KATs (02=186, 15=227, x25519=195, …).

HONEST RESIDUAL (no overclaim): the `<<` fix is necessary but NOT
sufficient for sha256's INTEGRATED build — with `sha_rotr` fully
unmasked the corpus KAT still fails 253/25 (vs the isolated iiis-0
link giving 186/227, same `.o`), so an additional cause tied to the
`--whole-archive` link context remains unisolated. Therefore the
sha256/blake2s/crc32 masks are RETAINED (load-bearing, FIPS-proven,
documented in sha256.iii header). The compiler-codegen defect itself
is genuinely fixed and sealed; the sha256-integrated residual is an
open, honestly-recorded narrower question — not fake-closed, not
guessed at.

---

# CRASH-AUDIT — RSA / bigint modexp "len-0 collapse" (forward-refs #1/#2)

CRASH-PROTOCOL governed. Phase 1 = EVIDENCE ONLY (read-only; NO .iii/.py
edit until this audit + a reproduction with binary evidence is complete).
Trigger: forward-ref #1/#2 ("value-dependent fault in bigint mul/div over
long modexp chains, collapses to len-0") + the prior session's
`rsa_test_fermat` returning 0 (i.e. 2^(p-1) mod p != 1).

## 1. Crash path — FULLY READ (every line, this session)

- `numera/rsa.iii`: rm_* CIOS Montgomery (rm_copy/extract/csub/dbl/mont_mul,
  515-628), `rsa_modexp` (631-705), all test fns (707-805),
  `rsa_u64_modexp`/`rsa_mr_base`/`rsa_is_prime`/`rsa_rand_candidate`/
  `rsa_gen_prime`/`rsa_keygen` (358-497).
- `numera/bigint.iii`: slot model + accessors (44-130), length/cmp/normalize
  helpers (219-405), `bigint_mul` + `_big_mul8_scalar` + `_big_mul8_avx512`
  + `bigint_mul_u64` (504-725).
- `numera/bigint_div.iii`: ENTIRE FILE — `bigint_div_u64`, `bigint_div_qr`,
  `bigint_mod`, `bigint_modpow`, `bigint_msb_position`.

## 2. CONFOUND — the prior "Fermat=0" does NOT, by itself, implicate rsa_modexp

`rsa_test_fermat` (rsa.iii:735) -> `rsa_gen_prime` -> `rsa_is_prime` ->
`rsa_mr_base` -> **`bigint_modpow`** (bigint_div.iii:199; called at rsa.iii
386 & 393) — the STDLIB modpow, NOT the rm_* workaround. Miller-Rabin
primality therefore runs on `bigint_modpow` -> `bigint_mul`/`bigint_mod`
(`bigint_div_qr`) — EXACTLY the functions #2 names as faulty. If those are
the broken component, `rsa_gen_prime` returns a COMPOSITE that broken
Miller-Rabin wrongly accepted, and `2^(p-1) mod p != 1` holds LEGITIMATELY,
with the rm_* Montgomery path entirely innocent. The Fermat probe conflates
two independent questions — (a) did gen_prime return a real prime?
(bigint_modpow), (b) is rsa_modexp correct? (rm_*) — and must be decoupled.

## 3. Source-level algorithm correctness (verified by reading, this session)

- `rm_mont_mul`: matches canonical Koç CIOS; multiply-accumulate
  `T[j]+a[j]*b[i]+c` bounded <= 2^64-1 (no u64 overflow); reduction indices
  and final `rm_csub` correct. Exercised at nw=1 by `2^10 mod 1001`. SOUND.
- `rsa_modexp` setup: R mod N = 2^(32nw)-N valid for top-bit-set N (true for
  the test prime); 32nw doublings -> R^2 mod N. SOUND.
- `bigint_mul` scalar path: schoolbook; the final-carry position `i+lb` is
  provably untouched by rows < i (max position written by row i' is i'+lb < i+lb),
  so the no-propagation final-carry store cannot lose a carry. Length walk
  correct. SOUND.
- `bigint_div_qr` / `bigint_mod` / `bigint_modpow`: textbook bit-serial
  long division + square-and-multiply. SOUND.

## 4. PRIME SUSPECT (decide by reproduction, NOT assumption — §6 lesson)

The ONLY component not proven-correct by reading is `_big_mul8_avx512`
(bigint.iii:529-563): a hand-written AVX-512 metal block asserted
"bit-identical to `_big_mul8_scalar`" but NEVER verified at the binary
level. It fires only for >=8-limb operands (>=512-bit) via
`cpufeat_has_avx512f()` dispatch — precisely "long modexp chains" with big
numbers, and precisely why nw=1 / small tests pass. Metal blocks are the
top trap class here (CLAUDE.md gauge-in-metal; this file's own u32 history).

HYPOTHESIS H-AVX: `_big_mul8_avx512` diverges from scalar for some limb
values => `bigint_mul` wrong for >=8-limb operands => every `bigint_modpow`
product over RSA-sized operands wrong => Miller-Rabin lies => gen_prime
returns composite => Fermat fails. NOT PROVEN. Alternative H-DEEP: scalar
path or `bigint_div_qr` also wrong (would mean the bug is not the SIMD).

## 5. Reproduction plan (differential, REAL pattern, NO proxy)

`bigint_force_path(1=scalar, 2=avx512)` (bigint.iii:574) exists for exactly
this. Decisive test needing no known answer: compute `bigint_mul(A,B)` for
>=8-limb A,B under force(1) vs force(2) and byte-compare the limbs —
divergence ALONE proves a bug (module claims bit-identity). Anchors:
(i) known-answer (2^512-1)*2 = 2^513-2 (hand-checkable); (ii) clean modexp
oracle — a HARDCODED known 512-bit prime p, `bigint_modpow(2, p-1, p)` MUST
== 1, decoupled from gen_prime. rc decides H-AVX vs H-DEEP.

Per the §6 lesson (proxy probe wrongly cleared a real workaround): the
decision uses the EXACT failing pattern (real bigint_mul on real >=8-limb
operands / real modpow), never a generic proxy. NO .iii edit until this
resolves with Phase-2 binary disasm of the divergent op.

## 6. RESOLUTION — reproduction complete; #1/#2 root-caused (bigint fault is STALE)

Reproductions built as separate evidence instruments
(STDLIB/build/corpus/_rsa_probe{1..7}.iii), iiis-2 compiled, gcc-linked
against libiii_native.a, run. (One additive @export instrument,
`rsa_test_rm_vs_lib`, was added to rsa.iii per the project's established
rsa_test_* pattern — a permanent regression, not a logic change.)

- probe1 rc=89: KNOWN-ANSWER (2^512-1)^2 = 2^1024-2^513+1
  (limbs [1, 0x7, 0xFFFFFFFFFFFFFFFE, 0xFF*7]). bigint_mul scalar ==
  avx512 == auto, all byte-exact; bigint_div_qr exact (P/A=A, P mod A=0);
  host HAS avx512. => bigint_mul/div correct on all-ones.
- probe2 rc=99: 39-seed varied scalar-vs-avx512 mul differential (all
  identical); modpow(2,10,1001)=23; **M521 Fermat 2^(2^521-2) mod
  (2^521-1) == 1** (real ~520-squaring chain, 9 limbs). => bigint
  mul/div/modpow CORRECT, including the exact #2 "long modexp chain"
  condition. H-AVX REFUTED by reproduction (no divergent op exists, so
  the planned Phase-2 disasm is moot — §3's methodology working as
  designed: reproduction can refute before disasm).
- probe3 rc=108: rsa_modexp (rm_*) vs trusted bigint_modpow, top-bit-set
  512-bit modulus, ~448-bit exponent: bigint_cmp == 0, result len 8.
  => rm_* Montgomery CORRECT vs oracle over a long exponent.
- probe4 rc=99: rsa_pss_selftest (PSS encode/verify_em + tamper, 3072)
  = 99; keygen(256) + (2^d)^e mod n == 2 = 1. => PSS layer + tamper +
  keygen + modexp round-trip correct.
- probe5 rc=12: keygen(320), sign(sLen=0) -> verify FAILED. CAUSE:
  rsa_pss_verify HARDCODES sLen=32 (rsa.iii:804) while rsa_pss_sign takes
  sLen; sLen=0 sign vs sLen=32 verify => correct rejection. NOT an rm_*
  bug — a test-harness sLen mismatch (and a real latent API asymmetry).
- probe6 rc=99: rsa_debug_path (trusted bigint_modpow round-trip +
  serialization + verify_em, sLen consistent) = 99. => os2ip/i2osp
  serialization + key + verify_em all correct.
- probe7 rc=99 (24s): keygen(576) + sign(sLen=32) + verify (=1) + tamper
  (=0). **Full fused RSA correct end-to-end at a real size, standard PSS.**

CONCLUSION:
- #2 ("bigint mul/div collapses to len-0"): **STALE.** The bigint layer is
  provably correct (probe1/2). Fixed in a prior session; the
  rsa.iii:499-504 comment and the tracker row are out of date.
- #1 (RSA sign/verify functional): **the math is correct end-to-end**
  (probe7). Genuine remaining work: (a) the missing corpus test; (b) the
  rsa_pss_verify hardcoded-sLen asymmetry (rejects any sLen!=32 signature
  — a real latent bug); (c) stale comments (module header says
  "via bigint_modpow" but sign/verify use rm_*).
- The prior session's "Fermat=0" was the rsa_gen_prime confound from
  BEFORE the bigint fix (Miller-Rabin ran on the then-broken
  bigint_modpow), now resolved.

Phase 3 (fix) authorized: correct the stale comments; give rsa_pss_verify
an sLen parameter (RFC-8017-symmetric; fixes the latent asymmetry and
lets a small modBits/sLen corpus test run fast); add a permanent
keygen->sign->verify->tamper corpus test; rebuild + full corpus +
triple-bit-identity + determinism reseal.

## 7. FIX LANDED + VERIFIED BY RUNNING (Phase 3/4 complete)

Changes (numera/rsa.iii unless noted):
- rsa_pss_verify: added `sLen` parameter (was hardcoded 32) -- RFC-8017-
  symmetric; fixes the latent asymmetry (verify silently rejected any
  sLen != 32 signature).  Sole caller rsa_debug_real updated to pass sLen.
- Stale comments corrected: module header ("RSA primitive via bigint_modpow"
  -> rsa_modexp Montgomery for sign/verify, bigint_modpow for keygen MR);
  rm_* block comment ("bigint collapses to len-0" -> bigint is correct,
  rm_* retained for PERFORMANCE not correctness).
- Added @export rsa_test_rm_vs_lib (rm_* vs trusted bigint_modpow regression).
- NEW corpus test STDLIB/corpus/373_rsa_pss_sign_verify.iii (EXPECTED=99):
  rsa_pss_selftest + keygen(320) -> sign(sLen=0) -> verify -> tamper.
- HARNESS FIX: STDLIB/scripts/build_stdlib.sh now pins the in-tree
  COMPILED/iiis-2 compiler FIRST.  It previously fell back to a stale
  PATH / Program Files iiis (the May-11 build) which phantom-FAILed ~7
  crypto modules (bigint/sha256/sha512/keccak/blake2s/aes_gcm/chacha20)
  on newer AVX-512 metal syntax -- the documented stale-$IIIS trap.
  run_corpus.sh already had this pin; build_stdlib.sh did not.

Verification (Phase 4 -- RUN, not asserted):
- build_stdlib (pinned): FAIL = 0; libiii_native.a = ca436285...
- twin build (no IIIS, exercising the patch's default pin): FAIL = 0;
  lib = ca436285... BIT-IDENTICAL -> deterministic.
- run_corpus.sh: PASS=293 FAIL=0 SKIP=98 (was 292/0; +1 = test 373;
  zero regressions; bit-identity tests 180-185 green).
- corpus 373 standalone AND via harness: exit 99.

#1 and #2 DISCHARGED in FORWARD_REFERENCES.md.  RSA is functional
end-to-end (keygen, PSS sign, PSS verify, tamper-reject).  Compiler
binaries iiis-0/1/2 unchanged (rsa.iii is compiler-unreferenced stdlib
=> no compiler-seal drift per ADR-027); stdlib lib is deterministic.

## 8. ADDENDUM -- Miller-Rabin Montgomery speedup (RSA keygen now practical)

rsa_mr_base's two bigint_modpow calls -> rsa_modexp (rm_* Montgomery CIOS).
MR candidates (rsa_rand_candidate) are top-bit-set odd, satisfying
rsa_modexp's R2 precondition; rm_* is proven == bigint_modpow (sec.6 probe3)
but is O(limbs^2)/multiply with NO bit-serial division, so RSA keygen drops
from infeasible-at-3072 to fast: keygen-512 < 1s (probe8), key valid via the
smallbase (2^d)^e==2 round-trip (=> the Montgomery-MR primality is correct).
The in-module forward reference (rsa_mr_base at L382 -> rsa_modexp at L656)
resolves cleanly (iiis is whole-module two-pass).  Verified: build FAIL = 0,
lib 282590e5...; corpus PASS=293 FAIL=0 incl. test 373; zero regression.
This makes FORWARD_REFERENCES #3's RSA-suite path testable at real sizes.
