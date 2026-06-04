# Trusted-Base Seal (SEPARATE-2 / Structural-Audit W2.4)

The III proof kernel (`numera/typecheck.iii`, the CIC checker — the sole arbiter of meaning)
delegates its **entire trusted computational base** to:

- the **CCL beta-eta reducer** `numera/ccl.iii` (Curien's categorical combinatory logic as a
  directed, confluent, terminating reduction — confluence now a machine-enumerated **theorem**
  via `ccl_critpair_enum`, W2.3), and
- the **TC ⇄ CCL translation**: `tc_to_ccl` (in `typecheck.iii`) + `ccl_to_tc` (in `ccl.iii`).

The de Bruijn thesis — *"everything reduces to this small, bounded kernel"* — is made **honest
and machine-checked** here: the source bytes of that base are content-addressed into one named
root. Any edit to the reducer or the translation MOVES the root, reddening the build until an
explicit reseal acknowledges that the trusted base changed.

```
TRUSTED_BASE_ROOT = 40209d80c5f67626cdc4392d8ca62500c1f4127f426ecd0b73d8d2bd27421135
```

> **Reseal log:**
> - `b6cadb51…` → `d6802ce2…` (2026-05-31, production-readiness audit): `ccl_to_tc` gained a reserved-INVALID
>   node guard — `if c == 0u32 { return tc_var(0u32) }`. `ccl_reduce`/`ccl_mk` return node 0 on `CCL_CAP`
>   overflow (II-CCL-2); without the guard `ccl_to_tc(0)` misread `CCL_TAG[0]` and self-recursed (`CCL_A[0]==0`)
>   to a stack overflow. Behavior for every valid node (`c != 0`) is byte-identical; the guard reuses the
>   module's existing stuck-fallback term. Kernel hardening only — the CCL reducer + confluence theorem
>   (`ccl_critpair_enum`) and `tc_to_ccl` are untouched.
> - `d6802ce2…` → `db6e9818…` (2026-06-03, mig2 keystone): `ccl.iii` gained the `CCL_REACH(h)` morphism
>   (kind 27) + `ccl_reach_c` constructor + an `iii_hexad_reachable` extern. The kernel now VERIFIES M3
>   hexad-reachability BY IOTA — `REACH(h)` reduces to `TRUE`/`FALSE` via `iii_hexad_reachable(h)`, rather
>   than trusting a baked value; `typecheck.iii` consumes `ccl_reach_c`. Also adds the node-0 INVALID guard
>   in `ccl_to_tc` (`if c == 0 { tc_var(0) }`). VERIFIED SOUND post-reseal: the full typecheck/ccl KAT suite
>   (841-882, 856-863, 935-939) + `1049_mig2_keystone` stay green; the change is additive (new tag + guard),
>   leaving every pre-existing node's behavior byte-identical. (This reseal acknowledges a kernel change that
>   landed externally mid-session; the protective drift-gate worked as designed.)

- **Definition:** `sha256( ccl.iii  ++  tc_to_ccl(typecheck.iii) )`.
- **Gate:** `bash COMPILER/BOOT/trusted_base_check.sh --check` (exit 3 on drift). Recompute
  after an intended change with `--print` and update the root above (the reseal).
- **Seal class:** STDLIB / FORGE_CLOSURE-lite — a standalone seal, deliberately NOT folded into
  the Sovereign forge manifest (`DOCS/SOVEREIGN-LEDGER.md`), so it requires no multi-level
  closure recompute.

This discharges SEPARATE-2 ("name + seal the trusted base as one content-addressed unit") and,
together with the COMBINE-12 repoint in `numera/safety_type.iii` (the phantom `numera/kernel.iii`
reference → the real `typecheck.iii` + `ccl.iii`), makes the kernel boundary legible and defended.
