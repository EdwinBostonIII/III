# Phase XII-κ — Real FOUNDERS-ANCHOR Genesis Descent Chain Replay

Status: **COMPLETE & VERIFIED** (Phase 4 gate passed). Originally
DESIGN/AUDIT (Phase 2 of CRASH-PROTOCOL — written before any `.iii` edit).
Security-critical: `aether/fed_genesis.iii` is R3 Crown (`kind_origin`),
the federation trust-root descent verifier.

## Completion record (Phase XII-κ)

`fed_genesis_verify_descent` now performs full per-step cryptographic
chain replay: `h[0]==genesis`, `h[N-1]==closure`, and for every
`i∈[0,N-2]` `h[i+1]==SHA-256(DOMAIN ‖ LE64(i) ‖ h[i])` with
`DOMAIN="III_FED_GENESIS_DESCENT_v1"` (26-byte source-visible literal,
`_fed_desc_domain_init`, mirroring `_anchor_init` — no opaque sealed
table). The self-referential header relation was corrected. `corpus/164`
rebuilt to construct cryptographically-valid chains and assert an
interior-tamper rejection (the case the stub wrongly accepted).

Verification (evidence):
- `fed_genesis.iii` + `corpus/164` compile rc=0.
- `corpus/164` rc=**99** (success sentinel): valid→1, endpoint tampers→0,
  zero-step→0, **interior h1 tamper→0**, restore→1.
- Instrumented probe (since removed) proved the interior loop runs 2
  iterations for N=3, all 32-byte compares match for a valid chain, and a
  mismatch is detected for a tampered chain.
- iiis-0 gate `301bdaf0…` unchanged; iiis-1 `5d36fc29…`, iiis-2
  `3ffaa427…` deterministic (2× identical) + verify OK + resealed;
  **triple bit-identity 57/57 + 57/57** (verify_descent is federation
  runtime, not referenced by the compilers, so their mhash is legitimately
  unchanged); XII corpus 92/93; full stdlib corpus PASS=250 (baseline,
  zero regression).

### Process correction (faithful record)

During this phase a Phase-XII-ι.2 comment edit to `xii_curated_riscv.iii`
had introduced `sha256sig*/sum*` — the `*/` closed the `/* */` block
comment early, so `build_stdlib` had been **FAILing** on that module and
`libiii_native.a` was **stale**. The earlier ι.2 "comment-only no-op /
determinism-gate-satisfied / triple-identity 57/57" conclusion was a
**false positive** (downstream tests linked the stale `.a`; iiis-1/2
mhash were unchanged because the `.a` was never rebuilt, not because the
edit was codegen-neutral). Root cause fixed (comment rephrased without
`*/`); `build_stdlib` now `FAIL=0` with a real re-aggregation, and the
state above is genuinely verified. Lesson recorded in memory
`feedback_buildstdlib_fail_masks_stale_lib`.

Standard enforced: *no workarounds / no placeholders, even if harder.*
`fed_genesis_verify_descent` is currently a Stage-0 stub (endpoint-only:
`h[0]==genesis ∧ h[N-1]==closure`, **no intermediate cryptographic check**).
That is a genuine partial implementation of a security boundary — it would
accept ANY interior chain bytes between two correct endpoints. This phase
replaces it with full per-step cryptographic replay.

---

## 1. Evidence (Phase 1 complete)

- `fed_genesis.iii` (215 lines) read in full. Stub at lines 87–126. The
  header (lines 19–24) states the step relation as
  `h[i+1] = SHA-256(domain ‖ step_idx_le_8 ‖ h[i] ‖ h[i+1])` — **self-
  referential / un-verifiable as written** (a spec-text defect; corrected
  below).
- Auditable-domain pattern already in-file: `_anchor_init` builds the
  source-visible literal `"III_FOUNDERS_ANCHOR_v1"` (22 bytes) and SHA-256s
  it for the anchor pubkey, explicitly "so the binary's trust root is fully
  auditable from the source-visible domain string alone." The descent
  domain follows the same discipline ⇒ **no opaque sealed constant table is
  needed**; the header's "Full chain replay lands when the seal-step domain
  bytes are sealed into a constant table" deferral is unnecessary.
- Sole consumer of `fed_genesis_verify_descent`: `corpus/164_fed_genesis_
  descent.iii` (read in full). `corpus/240` uses the *separate*
  `fed_genesis_descent_with_anchor` (ed25519 gate — unchanged here);
  `corpus/175` is genesis_distance (no `verify_descent` call). Blast
  radius = corpus 164 only.
- Corpus 164 builds chain `[h0=genesis(0x10..0x2F), h1=0xAA×32,
  h2=closure(0xC0..0xDF)]` and asserts `verify_descent==1`. `h1` is
  arbitrary — the test was calibrated to the *stub*. Real replay therefore
  requires the test's chain be rebuilt with cryptographically-valid links
  (correcting the test to actually exercise real verification — not a
  workaround; both impl and its test were endpoint-only and must be
  upgraded together).
- iiis trap review: existing file uses unsigned `while i < 32u64`
  successfully ⇒ unsigned `<` is safe (the W11/iiis-0 ordering-compare
  SIGSEGV trap is **signed-only**; descent counters are u32/u64). Honour:
  single-line fns; no `(` after `return` (bind a local); no nested
  `/* */`; ASCII `--`; `FED_*`-prefixed module consts; unique flat-scope
  locals; no local `var` arrays (module scratch).

## 2. Canonical recurrence (corrects the self-referential header)

```
DOMAIN  := ASCII "III_FED_GENESIS_DESCENT_v1"            (26 bytes, source-visible)
step i  (for i = 0 .. N-2):
    pre   := DOMAIN ‖ LE64(i) ‖ h[i]                     (26 + 8 + 32 = 66 bytes)
    require  h[i+1] == SHA-256(pre)
endpoints:
    require  h[0]   == FED_GENESIS_ROOT
    require  h[N-1] == closure_root
N == 1 : endpoint-only (h[0]==genesis ∧ h[0]==closure), no step.
N == 0 : reject (unchanged).
nulls / genesis-unset : reject (unchanged).
```

`LE64(i)` = the 8-byte little-endian encoding of the u64 step index
(domain-separates each link so a step can't be replayed at another index).
Constant-time-ish: the comparison accumulates a `diff` byte over all 32
bytes (no early-out), matching the existing endpoint-compare style.

## 3. Implementation plan (`fed_genesis.iii`)

- Module scratch (unique names): `FED_DESC_DOMAIN : [u8;26]`,
  `FED_DESC_BUF : [u8;66]`, `FED_DESC_HASH : [u8;32]`,
  `FED_DESC_INIT : u8 = 0u8`.
- `_fed_desc_domain_init()` — one-shot fill of the 26 ASCII bytes
  (`I I I _ F E D _ G E N E S I S _ D E S C E N T _ v 1`), flag-gated like
  `_anchor_init`.
- Rewrite `fed_genesis_verify_descent`: keep all guards
  (null/zero/unset/endpoint). Add the per-step loop: for `i` in
  `0 .. n-2`, fill `FED_DESC_BUF` = DOMAIN ‖ LE64(i) ‖ h[i],
  `sha256_oneshot(buf,66,FED_DESC_HASH)`, accumulate-compare vs h[i+1];
  any mismatch ⇒ return 0. All steps pass + endpoints match ⇒ 1.
- Fix the header doc block: replace the self-referential relation and the
  "Stage-0 stub … sealed into a constant table" deferral with the §2
  canonical recurrence and a note that the domain is the auditable
  source-visible literal (no sealed table).

## 4. Corpus 164 rebuild (test the REAL behaviour)

- Add `extern sha256_oneshot` + a local `_le64` filler + the same 26-byte
  DOMAIN literal.
- Build the chain cryptographically: `h0 = genesis`; for `i=0,1`:
  `h[i+1] = SHA-256(DOMAIN ‖ LE64(i) ‖ h[i])`; `closure = h[2]`.
- Retain every existing assertion semantics: valid chain ⇒ 1;
  tamper closure ⇒ 0; tamper h0 ⇒ 0; restore ⇒ 1; zero-step ⇒ 0.
- ADD a new assertion proving the interior is now checked: tamper `h1`
  (a middle hash) by one byte ⇒ `verify_descent == 0` (a case the stub
  would have wrongly accepted). This is the regression-proof that the
  stub is gone.
- Update the file header comment ("boundary-only chain replay" → real
  per-step SHA-256 chain replay).

## 5. Verification gate (Phase 4 — all must pass, evidence not assertion)

1. Manual line-by-line audit of the new loop vs §2.
2. `iiis-0` standalone compile of `fed_genesis.iii` + `corpus/164`: rc 0.
3. `build_stdlib` (fed_genesis.iii ∈ libiii_native.a) clean.
4. iiis-0 gate `301bdaf0…` unchanged; iiis-1/iiis-2 deterministic (2×
   identical) + resealed (bare-hash); **triple bit-identity 57/57+57/57**.
5. `corpus/164` rc = 99 (its success sentinel) under the rebuilt chain,
   incl. the new interior-tamper-rejects assertion.
6. Full XII corpus ≥ prior 92/93 (only pre-existing non-XII `299`); the
   stdlib corpus `164` PASS. Zero regression.

## 6. ADR-XII-κ-1

**Status**: Accepted (design). **Context**: `fed_genesis_verify_descent`
was an endpoint-only Stage-0 stub of a security boundary; user directive
forbids placeholders/workarounds even if harder. **Decision**: implement
full per-step `h[i+1]==SHA-256(DOMAIN‖LE64(i)‖h[i])` replay with an
auditable source-visible domain literal (no opaque sealed table — the
deferral excuse is removed); correct the self-referential header relation;
rebuild corpus 164 to construct cryptographically-valid chains and add an
interior-tamper-rejection assertion. **Consequences**: `fed_genesis.iii`
gains ~1 helper + a verification loop + scratch; corpus 164 becomes a real
test of real verification; libiii_native.a changes ⇒ iiis-1/iiis-2 reseal
(iiis-0 unchanged). **Alternatives rejected**: keep stub (placeholder,
forbidden); sealed-table domain (unnecessary indirection — auditable
literal is strictly better and matches `_anchor_init`); leave header
self-referential (spec defect).
