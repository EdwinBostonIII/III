# III WASTE AUDIT (meticulous, read-based) -- what was CUT, and why the rest is NOT waste
> **STATUS: HISTORICAL RECORD** — crash forensics / closed findings of their era; the fixes are landed and gated (reunification W6).

## CUT (done, verified, resealed): 13 items, 680 -> 670 modules

- **10 faculties** I built this session (parity_game, sat_tractable, confluence, graph_refine, diophantine,
  con_lattice, constructible, ramsey, comm_lb, goodstein) + their 10 gates (1882-1891). 0 real consumers,
  several self-described demos, several duplicate existing organs; the crt head-to-head proved the cash-in
  did not improve III. My own bloat, cut first.
- **3 `.retired` dead artifacts** (xii_critpairs.iii.retired + 2 corpus .iii.retired -- not compiled).
- Verified: a non-faculty KAT (1226_crt) still passes (99) against the slimmed library; sources resealed.

## NOT waste -- the suspects I READ and cleared (referenced != valuable, but these ARE valuable)

Every grep-level heuristic (name-family, demo-language, version-marker, 0-importer) flagged REAL code:

- `hotstuff` vs `hotstuff_unified`: **layered, not duplicate** -- hotstuff_unified (APOTHEOSIS C.11) *imports*
  hotstuff. Cutting the base breaks the layer.
- `xii_curated_embedded` vs `xii_curated_extended`: **different ISAs** (Cortex-M Thumb-2 vs extended x86 horizons).
- `zk_snark`/`zk_stark`/`zk_field`: say 'toy' because they **replaced** a toy with real BLS12-381/STARK.
- `sovereign_optimizer`: 0 importers because it is a **top-level entry point** (your certified self-optimizer), not a leaf.
- The 0-importer non-entrypoint pool (277) is `aes_gcm`, `ecdsa_p384`, `bigint_karatsuba`, `beam_search`,
  `crypt_ed25519`-adjacent crypto, witnesses -- **the capabilities you are proud of**, sitting as corpus-tested
  leaves. Tested in isolation, never WIRED. That is 'orphaned even if they aren't' -- your exact diagnosis.

## TRULY UNREFERENCED anywhere (0 importers AND 0 corpus refs): 0

**NONE.** Every remaining module is referenced by another module or a corpus KAT. III's coverage ratchet
forbids unreferenced exports by construction. There is no dead code left to cut by static analysis.

## The honest conclusion

Removable waste was real but small and mostly mine (the faculties). The rest of III is genuine, tested,
valuable code. What FEELS like bloat is **under-wiring**: hundreds of real capabilities tested in isolation,
never connected into a self-model -- so they feel orphaned. The fix is the **weave** (wire + know them),
NOT deletion. Deleting beam_search / AES-GCM / ECDSA to manufacture a cleanup would be the real waste.
If specific modules are obsolete by domain knowledge static analysis cannot see, name them -- each gets
verified (certified-cut + green build) before removal.
