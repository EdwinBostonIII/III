# III HEXAD — The Asymmetric Ternary Ground (R1.A6)

Implements `DOCS/III-HEXAD.md` in full. Provides the asymmetric ternary
algebra over `{NEG, ZERO, POS}`, the 6-trit hexad packed into a `u16`,
the **144-byte reachability bitmap `xii_asym_reach6`** that realises the
**Representability Theorem**, plus Dynamic / Epistemic / Möbius hexads.

NIH discipline: pure C11, only libc; SHA-256 from `libiii_lex.a`; brick
metadata cross-checked against `libiii_types.a`.

## Build

```
HEXAD\build\build.bat        REM Windows / mingw-w64 gcc
```

Produces:

- `build\libiii_hexad.a`
- `build\iii_hexad_tool.exe`
- `build\iii_hexad_test.exe`

## Module layout

```
include\iii\hexad.h          public API
src\hexad_algebra.c          §1, §2 trit/hexad algebra and packing
src\hexad_reach.c            §3 144-byte xii_asym_reach6 bitmap
src\hexad_pfs.c              §4 Representability Theorem (six bricks)
src\hexad_dynamic.c          §5 Dynamic-Hexad promotion (Catalyst)
src\hexad_epistemic.c        §6 Epistemic Hexads
src\hexad_mobius.c           §7 Möbius Hexads (inverse pair)
src\types_bridge.c           cross-check against libiii_types.a
tools\iii_hexad_tool.c       CLI tool
tests\hexad_test.c           85 tests (0 failures)
```

## Hexad encoding

A hexad is a 6-tuple of trits. The packed form is the **balanced
ternary index** (NEG=0, ZERO=1, POS=2 as digit values, summed
`Σ digit_i · 3^i`), giving a single `u16` in `[0, 728]`.

| Pillar | Pos | Semantics                          | Class         |
|--------|-----|------------------------------------|---------------|
| P1     | 0   | Inverse-Derivability               | structural    |
| P2     | 1   | Causality-Depth                    | structural    |
| P3     | 2   | Consent-Recency                    | structural    |
| P4     | 3   | Replication-Tier                   | structural    |
| P5     | 4   | Adversariality-Class               | informational |
| P6     | 5   | Coherence-Impact                   | informational |

A hexad is **structurally admitted** iff none of P1..P4 is `NEG`. The
default 144-byte `xii_asym_reach6` bitmap therefore has exactly
`2^4 · 3^2 = 144` bits set out of 729.

### Trit numerics

- Balanced:  `NEG=-1, ZERO=0, POS=+1`  (used by API)
- Asymmetric weight: `NEG=-2, ZERO=0, POS=+1`  (`iii_trit_weight`)
- Pack digit: `NEG=0, ZERO=1, POS=2`

### Asymmetric algebra (§1.2)

Tables encoded in `src/hexad_algebra.c`:

- `NOT`: `NEG↔POS`, `ZERO→ZERO` (involutive).
- `AND`: NEG dominates.
- `OR`:  POS dominates.
- `SUM` ("add"): NEG-biased: `NEG+ZERO=NEG`, `POS+ZERO=POS`,
  `POS+NEG=ZERO`.
- `MUL`: ZERO is annihilator, `NEG·NEG=POS` (recovery cancels damage),
  `NEG·POS=NEG` (damage propagates).

`SUB(a,b) = SUM(a, NOT(b))`.

### Hexad composition (§2.4)

`compose(a,b)` applies `AND` on P1..P4 (NEG dominates: damage compounds)
and `OR` on P5..P6 (POS dominates: recovery propagates). Pillar-wise
broadcasts `add`/`sub`/`mul` and `neg6` (full NOT) are also exposed.
The `active_neg` operator is the §3.5 reduction-inverse (negate P2..P5,
i.e. positions 1..4, leave 0 and 5).

## The Representability Theorem (§4)

The six PFS bricking ops are listed verbatim from §4.2 and confirmed
unreachable in `xii_asym_reach6`:

| Op                | Hexad (P1..P6)                | Pack | NEG-in |
|-------------------|-------------------------------|------|--------|
| `capsule_update`  | (NEG, NEG, NEG, NEG, ZERO, ZERO) | 324 | 1,2,3,4 |
| `microcode_load`  | (NEG, NEG, NEG, ZERO, ZERO, ZERO)| 351 | 1,2,3   |
| `bootorder_set`   | (NEG, NEG, ZERO, NEG, ZERO, ZERO)| 333 | 1,2,4   |
| `real_nvram_write`| (NEG, ZERO, NEG, NEG, ZERO, ZERO)| 327 | 1,3,4   |
| `me_psp_mailbox`  | (ZERO, NEG, NEG, NEG, ZERO, ZERO)| 325 | 2,3,4   |
| `smram_write`     | (NEG, NEG, NEG, NEG, NEG, ZERO)  | 243 | 1,2,3,4,5 |

`iii_hexad_pfs_kind(h)` returns the PFS enum for a packed hexad (or
`III_PFS_NONE`).

## Tool

```
iii_hexad_tool pack <t0> <t1> <t2> <t3> <t4> <t5>
iii_hexad_tool unpack <H>
iii_hexad_tool reach <H>
iii_hexad_tool pfs <H>
iii_hexad_tool pfs-list
iii_hexad_tool bitmap-dump
iii_hexad_tool bitmap-hash
iii_hexad_tool bitmap-stats
iii_hexad_tool compose <H1> <H2>
iii_hexad_tool algebra add|sub|mul <H1> <H2>
```

Trits accepted as `NEG|ZERO|POS` or `-1|0|+1`.

## Conformance

All §11 conformance criteria (C-HEX-1 .. C-HEX-6) covered:

- C-HEX-1 — bitmap byte-identical and SHA-256 reproducible.
- C-HEX-2 — six PFS hexads unrepresentable.
- C-HEX-3 — `compose` deterministic per §2.4.
- C-HEX-4 — Dynamic-Hexad promotion strictly monotonic; structural-NEG
  hexads always rejected.
- C-HEX-5 — `iii_hexad_epistemic_escalates` triggers when
  `confidence < 0.85`.
- C-HEX-6 — `iii_hexad_mobius_admits` enforces coherence floor.

## Build artefacts

| Metric                | Value |
|-----------------------|-------|
| Files                 | 11 |
| Lines of code         | 1149 |
| Tests passed          | 85 |
| `xii_asym_reach6` SHA-256 | `c99ca183b8a2b35703709cd05db4210b8c4b7dd4d3d02dc4951592bd745538c0` |

`R1.A6 = SHA-256(canonical_byte_form(DOCS/III-HEXAD.md))` is sealed
elsewhere; `xii_asym_reach6_mhash` is the bitmap SHA-256 above.
