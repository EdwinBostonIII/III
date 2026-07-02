# III STUDIO — the sovereign exact-mathematics IDE

`iii_studio.exe` (repo root; rebuilt by `STDLIB/scripts/build_studio.sh`) is one native window in which
III's exact substrate is **worked with**, not demonstrated: model physics, run exact calculations, compile
code with the real compiler, run real gates — every pixel, glyph, and verdict computed by III itself.

## What it is

ONE shell (`iii_studio.iii`) + ONE visual identity (`studio_theme.iii`) + SIX live workspaces, all on the
existing III-GLASS substrate (`ui_win` / `ui_raster` / `ui_font` / `ui_vfont` / `ui_exact`) — composed, not
re-authored. No toolkit, no HTML, no imported asset: the font is exact vector outlines, the rounded cards
and icons are the exact-AA circle engine (KAT 2081), the palette is one module.

| workspace | key | what it REALLY does |
|---|---|---|
| **HOME**    | F1 | the observatory: the exact ray-cast render as a live auto-orbiting hero (zero-drift integer turntable + determinism signature), system numbers as exact vector digits (783 modules / 5108 edges read from `world_graph`), launcher rows that spawn real sibling exes (`CreateProcessA` → LIVE/FAIL) |
| **FORGE**   | F2 | the IDE core: load any file (Ctrl+L), edit (WM_CHAR ring + arrows), save (Ctrl+S), **F7 compiles with the real `COMPILED/iiis-2.exe`** (spawn → wait → real exit code + real stderr painted). Truncated loads LOCK save to protect the original. |
| **BENCH**   | F3 | exact physics: summon spheres/ellipsoids/photons (S/E/P), move them (arrows/PgUp/PgDn), drag-orbit — every frame `wb_kernel` re-decides contact (integer sign + exact gap²/depth²), photon nearest-hit (n=3 Σ√ ordering), relay comparison (n=4 Σ√) |
| **LENS**    | F4 | the gated exact ray-caster (2155+2158) at 3×: left/right re-renders the REAL organ on its exact turntable; the frame's determinism **signature** is printed live — same step, same signature, always |
| **ZOOM**    | F5 | exact-integer camera (scale SN/32): precise Lissajous curves + the studio's real architecture, crisp at ANY magnification; past 4× the map **dissolves into the live e-graph** (`ser_egraph` saturating MUL(x,7)), deeper still the bit-blast SAT netlist |
| **CONSOLE** | F6 | the sovereign CLI: `sign a b …` (exact Σ√ sign via `sqrtsum_lazy3`), `collide`/`relay` (wb_kernel), `mod m r c init` (**proves** the invariant over all 2⁶⁴ via `sks_mod_prove_linear`), `gate NNNN` (spawns `STDLIB/build/kats/NNNN.exe`, reports the real exit code), `help` |

## Verified live (PrintWindow captures + posted WM_KEYDOWN/WM_CHAR)

- CONSOLE answered the 2155 marquee near-tie `sign 4 1 -2 2005652 2 1999992` → **+1 POSITIVE, exactly**;
  `mod 7 3 7 3` → **PROVEN over all 2^64**; `gate 2155` → **real exit code 99 PASS**.
- FORGE F7 → **COMPILED CLEAN — iiis-2 exit 0** (green badge is the compiler's own exit code).
- BENCH Tab + 6×Left → **OVERLAPPING depth² = 2716** (hand-verified: 104²−90² = 10816−8100).
- LENS right-arrow → step 1/35 with a **different** determinism signature than step 0 (derived, not decorative).
- ZOOM +×8 → the live e-graph replaced the map (nodes coloured by proven-equal class).

## Gates

- `STDLIB/scripts/run_aether_lens_kats.sh` — structural compile of the whole studio family + corpus runs.
- **Corpus 2169 `studio_kernel`** (exit 99): `wbk_collide_sign` all three arms (exact tangency boundary);
  `wbk_order_sign` against hand-derived ray quadratics (B=−20,Δ=16 vs B=−10,Δ=4) both directions + exact tie +
  the halved 2155 marquee near-tie; `wbk_relay_sign` strict both ways + the genuine surd identity
  √2+√8−√8−√2 = 0; `studio_trig` anchors + whole-table antisymmetry/quarter-shift/monotonicity.
- 2155 + 2158 remain green alongside (PASS=3 FAIL=0).

## Build

`bash STDLIB/scripts/build_studio.sh` — compiles ~27 modules with the in-tree iiis-2, links one exe, and also
produces the real gate binaries `STDLIB/build/kats/2155.exe` / `2158.exe` that the console spawns.

## Engineering notes

- `ui_win` gained a **WM_KEYDOWN ring** (`ui_getkey`, additive alongside `ui_key`): the studio drains ALL queued
  keys per frame, so no keypress is lost to a slow frame. (Found when posted key pairs collapsed under load.)
- Module-var **expression initializers silently don't apply** (`var X : i64 = 0i64 - 1i64` stayed 0); set such
  values in the init function. Bit the FORGE's rc badge.
- The shell's exit code is diagnostic: 3 = window quit, 7 = frame-guard ceiling.
- Every string literal drawn with an explicit length was audited mechanically (literal length vs declared count).
