# POLYMORPHIC-DATA/ — Superseded by `STDLIB/iii/verba/glyph_*.iii`

The C reference implementation in `POLYMORPHIC-DATA/src/` is **not** linked
by the live build chain. The active production implementation is the full
**Glyph V3 192-byte canonical-form family** — **16 form modules + 1 core
infrastructure module = 17 `.iii` files**:

```
STDLIB/iii/verba/glyph_core.iii        — (infrastructure) zero / read / write / mhash / validate
STDLIB/iii/verba/glyph_u8.iii          — form 0x10 — u8
STDLIB/iii/verba/glyph_u32.iii         — form 0x11 — u32
STDLIB/iii/verba/glyph_u64.iii         — form 0x12 — u64
STDLIB/iii/verba/glyph_i64.iii         — form 0x13 — i64
STDLIB/iii/verba/glyph_f64.iii         — form 0x14 — f64
STDLIB/iii/verba/glyph_str.iii         — form 0x20 — UTF-8 string
STDLIB/iii/verba/glyph_bytes.iii       — form 0x21 — byte-blob
STDLIB/iii/verba/glyph_vec.iii         — form 0x30 — homogeneous vec
STDLIB/iii/verba/glyph_map.iii         — form 0x31 — map
STDLIB/iii/verba/glyph_set.iii         — form 0x32 — set
STDLIB/iii/verba/glyph_enum.iii        — form 0x33 — sum type
STDLIB/iii/verba/glyph_record.iii      — form 0x34 — product type
STDLIB/iii/verba/glyph_crystal.iii     — form 0x40 — crystal_id with edges
STDLIB/iii/verba/glyph_witness.iii     — form 0x41 — witness record
STDLIB/iii/verba/glyph_proof.iii       — form 0x42 — proof certificate
STDLIB/iii/verba/glyph_recursive.iii   — form 0x50 — glyph-of-glyph
```

**Canonical form-id numbering (RITCHIE Stage 1.7 — source-of-truth = the
`GV3_FORM_*` constants in the `.iii` sources + the registry in
`glyph_core.iii` lines 19–24):** scalars 0x10–0x14, text 0x20–0x21,
collections 0x30–0x34, structured 0x40–0x42, recursive 0x50. **No form-id
overlaps** — the prior note claiming `glyph_record` and `glyph_witness` both
use 0x41 was incorrect (record is 0x34, witness is 0x41). The C reference's
0x00..0x25 scheme in `POLYMORPHIC-DATA/include/iii/polymorphic.h` is a
derivative interpretation and is renumbered to this canonical scheme in
RITCHIE Stage 8 (Stage 1.7 pins the canonical numbering here + in
`DOCS/III-POLYMORPHIC-DATA.md`).

## What this directory still contains

| File | Role |
|---|---|
| `README.md` | D12 specification narrative — keep. |
| `src/*.c` | C reference implementation — historical. |
| `tests/*.c` | Reference test bench — historical. |

## Action policy

* **Do not** add new functionality to `src/` or `tests/`. New work goes
  into the appropriate `STDLIB/iii/verba/glyph_*.iii` module.
* **Do** keep `README.md` updated when the spec evolves.

## Cross-reference

* Spec: `DOCS/III-POLYMORPHIC-DATA.md` (D12)
* Live impls: 16 form modules + `glyph_core.iii` = 17 `STDLIB/iii/verba/glyph_*.iii` files
* Index: `R1-SUBSYSTEMS.md` (repo root) — search for `POLYMORPHIC-DATA/`
