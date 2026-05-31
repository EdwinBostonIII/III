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
TRUSTED_BASE_ROOT = b6cadb51a9f4648d1b679b54d8743efc45ea6906c0e0c67e061506659fed3d0b
```

- **Definition:** `sha256( ccl.iii  ++  tc_to_ccl(typecheck.iii) )`.
- **Gate:** `bash COMPILER/BOOT/trusted_base_check.sh --check` (exit 3 on drift). Recompute
  after an intended change with `--print` and update the root above (the reseal).
- **Seal class:** STDLIB / FORGE_CLOSURE-lite — a standalone seal, deliberately NOT folded into
  the Sovereign forge manifest (`DOCS/SOVEREIGN-LEDGER.md`), so it requires no multi-level
  closure recompute.

This discharges SEPARATE-2 ("name + seal the trusted base as one content-addressed unit") and,
together with the COMBINE-12 repoint in `numera/safety_type.iii` (the phantom `numera/kernel.iii`
reference → the real `typecheck.iii` + `ccl.iii`), makes the kernel boundary legible and defended.
