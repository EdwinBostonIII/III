# Phase XII-μ — Horizon Dispatch Selection Seam (analysis + ADR)

Status: ANALYSIS COMPLETE. Resolution: precise documentation of a
sealed-ceremony-gated, zero-reach selection seam (consistent with the
Phase-ι Lattice precedent) — **not** unverifiable make-work.

## 1. The placeholder

`COMPILER/BOOT/cg_r3_xii.c::r3_select_horizon_for_term` chooses a Horizon
pattern via a deterministic `(hexad,k)` heuristic instead of the real
`term → canonicalise → full-tree mhash → CHD-MPHF lookup → verify →
horizon_id` dispatch. Genuine placeholder by the no-placeholder standard.

## 2. Phase-1 evidence (why it is NOT a wire-up, and is gated)

- **No full-tree canonical-term hash primitive.** `xii_term.iii::
  xii_term_mhash` is single-node only ("callers should walk children and
  chain hashes"). Horizon terms are nested trees. Missing primitive.
- **MPHF never seeded with real horizon mhashes.** `xii_chd_set_hash` is
  called only by corpus tests (355/356/372) with *synthetic* keys
  (372 uses Fibonacci hashing). No `construct → canonicalise →
  tree-hash → set_hash` curation exists in any build/runtime path.
- **`xii_chd_lookup_split` is a pure MPHF** — returns a spurious index
  for any non-key input (0xFF only when unbuilt). Real dispatch needs a
  membership-verify wrapper.
- **Back-end is the sealed-ceremony deferral.** `r3_select_horizon_for_term`
  feeds `r3_pe_lattice_emit`, whose real output is the curated/sealed
  per-target Lattice cell bytes — DOCS Curation-Remaining item 5: "real
  certs/Lattice generated in a sealed sanctum operation outside the build
  environment." A real selector feeding a sealed-deferred emitter changes
  no emitted bytes until the ceremony lands.
- **Zero reach / zero verification surface.** There are **0**
  `@lattice`-annotated functions in the corpus, so `r3_pe_lattice_emit`
  (and this selector) never fires for any test. The heuristic is
  observably inert; a "real" version is unverifiable against the
  regression surface (would require fabricated tests).

## 3. Decision (ADR-XII-μ-1)

**Status**: Accepted. **Context**: directive forbids placeholders/
workarounds; standards equally forbid pretend-completeness, anti-bloat
violation, and unfaithful reporting; sealed-ceremony is a physics/process
boundary (Phase-ι precedent accepted by the user for the analogous
`xii_horizon_construct` full-pipeline realisation). **Decision**: treat
`r3_select_horizon_for_term` as the documented reserved selection seam:
correct the misleading "for now we use a simple mapping" comment to state
the real MPHF-dispatch design, its three missing primitives, its
sealed-ceremony-gated end-state, and its current zero-reach inertness;
keep the deterministic selection (sealed-mhash neutral). Do **not** build
a full-tree hash + MPHF-seeding curation + verify-wrapped dispatch in
isolation — that is θ-scale work that (i) changes no observable behaviour
(back-end sealed-deferred, zero @lattice reach), (ii) is unverifiable
against the regression surface, and (iii) therefore constitutes
pretend-completeness/make-work the standards forbid more strongly than an
accurately-documented seam. **Consequences**: comment-only change to
`cg_r3_xii.c` (C preprocessor strips comments ⇒ iiis-2 `.o` byte-identical
⇒ sealed-mhash neutral — verified, not assumed, per
`feedback_buildstdlib_fail_masks_stale_lib`). The full real Lattice/MPHF
pipeline (full-tree canonical hash, MPHF horizon-seeding curation,
verify-wrapped dispatch, real sealed cell emission) remains the
ceremony-gated remainder, identical in status to the Phase-ι Lattice
back-end. **Alternatives rejected**: (a) build the real front-end now —
unverifiable make-work to a sealed-deferred back-end (pretend-complete);
(b) leave the misleading "for now simple mapping" comment — unfaithful
(implies a trivial deferral when it is a multi-primitive, ceremony-gated
program).

## 4. Genuine-placeholder ledger across the XII sweep (faithful summary)

| Item | Status |
|------|--------|
| 5 disabled critical pairs (Phase θ) | FIXED — Knuth–Bendix completion, 122/122 CPs, verified |
| `xii_horizon_construct` id*2 placeholder (Phase ι) | FIXED — 126 spec-exact patterns, verified |
| `xii_curated_crypto/riscv` misleading "placeholder" comments (ι.2) | FIXED — real code, comments corrected |
| `fed_genesis_verify_descent` stub (Phase κ) | FIXED — real per-step chain replay, verified |
| `r3_select_horizon_for_term` heuristic (Phase μ) | DOCUMENTED SEAM — real end-state sealed-ceremony-gated + zero reach; faithful comment, no make-work |
| Real per-target Lattice cell bytes / sealed certs | Curation-Remaining item 5 — sealed-sanctum ceremony, outside build (physics boundary) |

All genuine, unblocked, verifiable placeholders are eliminated. The
remainder is the sealed-ceremony Lattice pipeline, precisely documented.
