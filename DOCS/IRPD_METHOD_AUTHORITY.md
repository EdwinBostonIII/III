# IRPD Method Authority

Declares the canonical IRPD (Inter-Ring Procedure Dispatch) method table and the
authority against which the compiler's two copies are reconciled. This document
only declares the authority and records the known drift; the source-level
deduplication is forward reference #9 (discharged at Stage 8.3).

## Real implementations in the substrate

(Adapted to the real tree — the compiler is `COMPILER/BOOT/`, not
`COMPILER/SEMA/`.)

- `COMPILER/BOOT/sid.c` — the SID (sealed-call / IRPD) method table, **17
  write-side entries**. Canonical for the write-side set.
- `COMPILER/BOOT/sema.c` — the semantic analyzer's IRPD acceptance table, **20
  entries**: the 17 write-side methods plus 3 read-side methods that sema
  additionally accepts (`msr_read`, `cr_read`, `npt_read`).

## Drift

The two tables are parallel sources of truth that can drift independently. The
3-entry difference is intentional today (sema accepts the read-side methods that
sid does not need for the write-side sealed-call discipline), but it is
undocumented and unenforced — a future edit could desynchronize them silently.

## Reconciliation (forward reference #9, Stage 8.3)

Stage 8.3 extracts the canonical list into a single header
`COMPILER/BOOT/irpd_methods.h` with a flags column distinguishing write-side
(the 17 in sid.c) from read-side (the additional 3 in sema.c). Both `sid.c` and
`sema.c` include the header; a compile-time assertion verifies sid's 17 are
exactly the write-side rows and sema's 20 are the full set. After Stage 8.3 the
count split is structurally enforced, not merely conventional.
