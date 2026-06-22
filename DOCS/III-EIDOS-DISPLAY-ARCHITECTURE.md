# III-EIDOS-DISPLAY-ARCHITECTURE — the system display & CLI that EIDOS deserves

*Architect pass for Edwin's directive: "a system display and CLI that humiliates all others",
seated in EIDOS. Authored Damien, 2026-06-21. Companion to III-EIDOS-ARCHITECTURE.md.*

## 0. The one-sentence thesis

The batcave is already a content-addressed geometry; it has simply never been **looked at**. EIDOS
quanta carry an identity (`sha256` content-address), a verb/capability, endpoints, and a gradient
potential — every datum a picture needs. The display does not *decorate* that structure with a
visualization; it **projects the structure that is already there** onto a plane we can read.

## 1. Requirements

**FR-1** Render the REAL batcave — the live `self_atlas` graph after `self_cartographer` walks the
        actual `iii/` tree — never a hand-built demo web. (The EIDOS isub web is empty until a real
        trace drives the bus; leading with it would render nothing. — `eidos/descriptor` caveat.)
**FR-2** Color is an **active participant, not paint**: a node's color is *derived from its
        content-address* (`color = palette(sha256(identity))`). Two content-identical things are the
        same color by construction; coincidence is *visible*. (Edwin: "color must be intrinsic.")
**FR-3** The 2D plane is a **law**, not a canvas: a fixed deterministic projection from the quantum's
        N-dim coordinates (identity × stratum × verb × potential) to (col,row). The plane holds only
        (color); WE recover the higher structure because the projection is legible — x and color from
        identity, y from architectural depth. ("the plane doesn't comprehend its own dimensionality,
        but we can see it.")
**FR-4** A **hyper-efficient rasterizer**: native framebuffer, integer Bresenham edges, truecolor
        ANSI via Unicode half-blocks (2 vertical pixels per character cell), with run-length color
        coalescing (emit an SGR escape only when the color changes along a scanline).
**FR-5** An **in-house CLI** (`eidos_cli`) composing every relevant primitive — arena, builder,
        format, fs, self_atlas, self_atlas_lens, self_cartographer, eidos/{descriptor,ripple} — into
        one command that produces the image.

**NFR — determinism** same atlas → byte-identical image (the III core invariant).
**NFR — completeness** every node is iterated; nothing is silently capped or dropped; off-plane and
        pixel-coincident counts are *reported*, never swallowed.
**NFR — NIH** libc-free; only in-tree organs. **No islands**: the display reads the real organs; it
        re-authors none of them (it is the visual sibling of `self_report`, which writes the one-line
        summary of the same `self_atlas`).

## 2. Pattern & component decomposition (layered, single-source-of-truth color law)

```
        ┌─────────────────────────── eidos/cli ───────────────────────────┐
        │  scarto_map(iii/) → render_atlas() → serialize → fs_write(.ans)  │  the CLI
        └───────────┬───────────────────────────────────┬─────────────────┘
                    │                                     │
            ┌───────▼────────┐                   ┌────────▼─────────┐
            │  eidos/render  │  projection law   │   eidos/canvas   │  the plane + rasterizer
            │  N-dim → (c,r) │ ───plot/line───▶  │  framebuffer +   │
            │  + caption     │                   │  half-block ANSI │
            └───┬────────┬───┘                   └──────────────────┘
                │        │
   self_atlas ◀─┘        └─▶ eidos/palette   ← THE color law (single source of truth)
   self_atlas_lens          color = fold(sha256(identity)) → vivid RGB
   sha256 / isub_cav        (same law for an atlas node's name-hash AND an EIDOS quantum's cav)
```

| Component | Responsibility (one sentence) | Composes |
|---|---|---|
| `eidos/palette` | The color law: a 32-byte identity digest → one vivid packed RGB, deterministically. | — (pure) |
| `eidos/canvas` | The plane: a module-scope framebuffer, integer plot/line, half-block truecolor ANSI serializer with run-length color coalescing. | builder, format |
| `eidos/render` | The projection law: place each node by (identity→x, stratum→y), color by palette, draw edges then nodes; emit a lens caption; count off-plane/coincident. | self_atlas(+lens), sha256, palette, canvas |
| `eidos/cli`  | The command: walk the real tree, render, write the `.ans` artifact. | self_cartographer, render, canvas, arena, builder, fs |

## 3. Key decisions (ADRs)

- **ADR-1 Color = content-address (FR-2).** Rejected: a categorical palette keyed by subsystem
  (paint, not participant). Chosen: `palette(sha256(name))` for atlas nodes / `palette(isub_cav)`
  for EIDOS quanta — one law over 32-byte digests. Consequence: color carries identity; the same
  block is the same color everywhere; the color law is itself testable (and gated, see §4).
- **ADR-2 Identity governs position too (FR-3).** x is derived from the *same* digest that gives
  color; y from `satlas_level` (architectural depth). The horizontal axis and the hue are two
  readouts of one identity — the projection is the "law/space" that exposes hidden dimensions.
- **ADR-3 Half-blocks over ASCII glyphs (FR-4).** `▀` (U+2580) with fg=top-pixel, bg=bottom-pixel
  doubles vertical resolution; the source stays ASCII (these are output bytes). Run-length
  coalescing makes a sparse image small and fast.
- **ADR-4 File artifact, not stdout (FR-5).** `fs` is file-handle based (no stdout handle exposed);
  the CLI writes `build/eidos_map.ans`, viewable with `cat` (ANSI preserved). Same discipline as
  `self_report`, which writes its summary to a file.
- **ADR-5 Gate on invariants, never a magic hash.** A frozen expected-hash reddens on every module
  add; a frozen synthetic web is the vacuous-gate trap. The KAT renders the REAL tree and gates on
  (determinism, completeness-vs-`satlas_node_count`, the color-identity law) — invariants that can't
  go stale. (Synthesis §"the vacuous gate epidemic"; `feedback_apply_to_real_not_toy`.)

## 4. The gate (corpus 1985) — prove the negative

1. `scarto_map(iii/)` populates the real `self_atlas`; **fail if node count is 0** (catches a
   vacuous render over an empty registry).
2. **Determinism:** render twice from the same atlas → `canvas_sig()` equal.
3. **Completeness:** `render_iterated() == satlas_node_count()` (no silent cap); report off-plane
   and pixel-coincident counts.
4. **Color-identity law:** two distinct `isub_cav` triples → distinct `palette` colors, AND
   `palette` recomputes to the documented fold over a known digest (proves it is not a stub).
5. Writes `build/eidos_map.ans` as the viewable artifact. Returns 99.

## 5. Layout — `eidos/layout` (Phase 2)

The Phase-1 X-axis was `hash(identity)` — meaningless, so edges crossed at random (a hairball).
`eidos/layout` makes X carry **topology** via deterministic **barycentric crossing-minimisation**
(Sugiyama): the strata are the layers; within each layer nodes are reordered toward the mean position
of their neighbours, swept down/up `LAY_SWEEPS` times, stable insertion sort, `(barycentre, key, id)`
total order. Pure integer, no float. Result on the live tree: total order-span **1956653 → 802436**
(≈ 59% tighter) — connected modules pull together.

Two decisions made it both *correct* and *beautiful*:
- **Identity-keyed (ADR-6).** Initial order and tie-breaks key on `hash(name)`, then node id, so the
  layout is a **pure function of (names, edges)** — *designed* to be invariant to directory-walk order.
  Proven byte-identical cross-run on a stable walk (corpus 1985); the residual `id` final-tiebreak fires
  only on an exact `(barycentre, key)` collision, a vanishingly rare walk-dependence, not a proof of
  full reorder-invariance. The node-id-keyed version was deterministic only by FS luck.
- **Radial/orbital projection (ADR-7).** Stratum → radius (foundational core at centre, the cyclic
  band orbiting the rim), within-layer order → angle. A ring holds a fat layer far better than a line
  (the 176-node cyclic cluster has ~5× the room), and barycentric angular alignment turns edges into
  short radial spokes — a mandala, not a hairball. Cos/sin from an integer Q12 table built by rotation
  recurrence (no float, no hardcoded table). `layout_set_proj(0|1)` switches stripes/radial.
- **Gradient edges.** `canvas_line` interpolates `CANVAS_PEN → CANVAS_PEN2`, so an edge flows from the
  source module's identity-colour to the target's — colour-as-content-address taken to its conclusion.

Gated by **corpus 1986** on projection-independent invariants: a sort self-test (proves the sort
sorts — a broken sort otherwise yields deterministic garbage that still places every node),
determinism, completeness, layer-0 monotonicity against the *stored* barycentres, and a non-strict
span-quality check (barycentre never worsens vs the un-ordered baseline; the value is *reported* in
the 1985 caption, not frozen).

**Equal-area ring packing (ADR-8).** The radial core crowded because a linear `radius = f(level)` put
populous strata on short inner circumferences. The fix: a layer's ring sits at `r = rmax·√(cumfrac)`
(integer `lay_isqrt`), so cumulative *disk area* tracks cumulative node fraction — a populous stratum
is pushed outward to a longer circumference. Plus a golden-ish per-ring angular offset so spokes don't
align radially. Result: **`coincide` 140 → 36** on the live tree. Residual overlap is *reported* and
colour-disambiguated (the later-drawn identity wins the pixel — the content-addressed tie-break).

## 6. The temporal axis — `eidos/temporal` (Phase 4)

A still image has no time. `eidos/temporal` adds it: the batcave is revealed **stratum-by-stratum**
(the bottom-up construction order — foundational primitives first, apps and the cyclic rim last), one
tick per stratum recorded into the real `eidos/field` organ, so every frame carries a **temporal
witness** (`field_temporal_witness` — a content-addressed seal of the revealed prefix). Output is a
**flipbook**: each frame is `ESC[2J ESC[H` (clear+home) + the image + a `FIELD t=k/N revealed=R
witness=…` banner; a player steps it, `cat` shows the last frame. Geometry/colour are the same radial
mandala, *grown in time*. Gated by **corpus 2000**: one event per stratum, frame determinism,
completeness (final frame = every node), monotone reveal, distinct per-frame witnesses, rebuild
determinism. Live run: 15 frames, revealed climbs 176 → 695, each frame a distinct witness.

## 7. The unified command — `eidos/cli` (Phase 4 / FR-5)

`eidos_cli_run(verb, cap, path)` is the one entry point, dispatching every view of III:
`MAP` (the module-graph mandala), `WEB` (the live isub content-web, driving a real `xii_isub_normalize`
trace), `PLAN` (the web + the Composer's `desc_plan` geodesic overlay), `FIELD` (the temporal flipbook).
Each view writes a truecolor `.ans` and self-labels via its caption (the legend); an **unknown verb is
refused** (returns 0 — never a silent wrong render). It composes the whole stack —
self_cartographer + eidos/{render,layout,canvas,palette,web,temporal} + xii (the trace driver) + fs —
the literal "CLI that takes advantage of every primitive." Gated by **corpus 2001** (all four views
render + the bad verb is rejected).

## 8. Roadmap — status

- **Phase 1 ✅** four organs + gate + real-tree mandala (corpus 1985).
- **Phase 2 ✅** `eidos/layout`: barycentric crossing-min + radial projection + gradient edges +
  identity-keyed determinism + **equal-area packing** (corpus 1986).
- **Phase 3 ✅** EIDOS-web over a real isub trace — `eidos/web` (sibling process; corpus 1987–1992):
  the content-web, plan/route overlays, weave-executed plan, topology projection, ripple intensity.
- **Phase 4 ✅** the temporal flipbook (`eidos/temporal`, corpus 2000) + the unified CLI
  (`eidos/cli`, corpus 2001). The display + CLI are complete and gated.
- *Open polish (non-blocking):* sunflower (phyllotaxis) intra-annulus packing for the very densest
  strata; a live event-trace source for `FIELD` beyond the construction-order reveal.
