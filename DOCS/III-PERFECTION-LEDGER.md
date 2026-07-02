# III PERFECTION LEDGER — whole-system file-by-file disposition audit

**Date:** 2026-07-01 · **Auditor:** main session (no subagents; manual judgment per file over a mechanical evidence layer)
**Scope:** every module in `STDLIB/iii/` (806), `STDLIB/sovir/` (77), `STDLIB/sovtc/` (54), `STDLIB/independence/` (12); every corpus KAT (`STDLIB/corpus/`, 1761 numbered + rejects); every `COMPILER/BOOT/` source (153); `STDLIB/scripts/` (66); plus build litter, root artifacts, and top-level dirs.
**Completeness gate:** §14 proves every file above appears exactly once in this ledger (mechanical diff of manifest vs ledger entries).

## EXECUTION RECORD (2026-07-01, same day)

The purge and the S2 correction were EXECUTED and gate-verified:
- **`4a715dae`** — the great cleanout: 862 tracked paths git-rm'd + ~90 untracked root artifacts + _audit_scratch/ + TOOLS-QUOTIENT staging + .gitignore artifact patterns. Every §-DELETE verdict of this ledger executed; every target re-verified reference-free immediately before removal; zero misses.
- **`4c42cbb2`** — follow-up: staged the _audit_scratch/ tracked removals + UNIVERSAL-BLOCK.md → DOCS/III-UNIVERSAL-BLOCK.md relocation.
- **`de032c60`** — S2 CLOSED: III-STUDIO family committed (shell + theme + trig + 6 workspaces + ui_win input-ring mod + build_studio.sh + KAT 2169_studio_kernel + DOCS/III-STUDIO.md), `forge_scratch.iii` → **`studio_sample.iii`** (module + all referents renamed, zero residuals), SEAL.mhash committed as the pinned closure seal, this ledger committed. arc_sweep/cspace/2174/2175 were committed concurrently by the sibling session (`44de723b` era).
- **Gate verification (real runs, real exit codes):** run_aether_lens_kats.sh → **PASS=3 FAIL=0** (2155, 2158, 2169 studio kernel — the renamed sample compiles in the studio loop). run_sqrtsum_kats.sh → **PASS=38 FAIL=0** (incl. 2173_cspace, 2175_arc_sweep, 2174_gas_demon, 2176_gas_big).
- **NEW FLAG (found during verification): KAT number collision** — `2169_gas_reversal.iii` (sqrtsum family) and `2169_studio_kernel.iii` (aether-lens family) share number 2169. Functionally green (name-keyed EXPECTED, disjoint runners) but violates unique-numbering; FIX: renumber 2169_gas_reversal to a free number and update its run_sqrtsum_kats.sh line.
- Still open from §1: S1 ratchet restoration (uncovered/gates/dark 75/10/157 vs pins 5/2/14) — untouched by this execution, next in order. In-flight sibling-session work observed and deliberately left alone: gas_big (self-committed mid-run), resultant.iii + 2177_resultant, gs3_counter.c, win.txt.

## EXECUTION RECORD 2 (2026-07-01/02 — THE 12 MERGE PAIRS)

**`1d21c3f6`** — all 12 merge REFACTORs of §2-§11 EXECUTED, verbatim behavior-preserving folds (extern surgery only): goldbach+collatz→**conjecture_probe** (new) · kinduction→bmc (MODEL-TIER) · pareto_frontier→pareto_extraction · cas_blob→erasure_store · omega_engine→self_engine · mandate_m22→mandate · quality_q7→quality · hotstuff_predict→hotstuff_unified · xii_sort_meter→compute_box · ripple_synthesizer→sovereign_optimizer · daemon_scythe→scythe_census · the three verification missiles→**xii_semantic_verify** (new).
- MODULES 726→713, diff verified 1:1, orphan comments cleaned. All 23 dependent corpus KATs retargeted (the ledger's 19 + the 4 the manifest's extern-truncation missed: 45, 1421, 1422, 1423); zero residual donor references; the two stage1_corpus `quality_q7` decorations left by design (symbol-based linking; golden byte-equivalence witnesses must not move).
- **Gates:** build_stdlib compile **PASS=713 FAIL=0** + fresh archive; retargeted-KAT gate **23/23 exit=99** through run_corpus's exact link line.
- **Defect found + fixed en route:** corpus 1509's local `BB_MAX_NODES` pin was stale at 128 since bv_bits went to 2048 (`68aa615c` "no magic caps") — pre-existing red, invisible until this per-KAT run; pin refreshed with a tracking comment.
- **Ratchet delta adjudicated:** uncovered 75→85: +5 scaffold-deletion fallout now queued under S1 (ui_fill_tri_aa, ui_fill_tri_exact, ui_save_bmp, fs_demo, th_panel_std — their only referencing code was the 11 deleted demos; cover or de-export), +5 sibling in-flight (g2_events, g2_mom, lm_cellz, lm2_cellz, lm2_pz). The merges added ZERO uncovered exports.

## 0. The keep-criteria (the bar a module must clear to be labeled KEEP)

A module stays listed only if ALL hold:
1. **System-harmonized** — reached from a real gate (MODULES list of `build_stdlib.sh`, a family runner, or a live consumer chain); no island.
2. **Modular & unique** — one clear responsibility that no other module carries; overlap is grounds for MERGE/UNIFY.
3. **Far-reaching value** — either load-bearing for the substrate (compiler, allocator, crypto, exact-sign kernel, gates) or a proven organ other faculties compose. "Niche and largely purposeless" fails this.
4. **Evergreen & functional** — compiles under in-tree `iiis-2`, its KATs green, no placeholder/stub/deferral.
5. **Production-shaped** — roughly uniform size/complexity with its peers (a 5000-line outlier must justify itself or SPLIT; a 30-line fragment must justify itself or MERGE).

Verdicts: **KEEP** (clears the bar; labeled) · **REFACTOR** (merge/split/trim/unify/reorder — specifics given) · **FIX** (one named repair unlocks unique value) · **DELETE** (with every related file to clean) · **QUARANTINE** (WIP/scratch that must not ship as-is).

Evidence columns: `loc` = line count · `date` = last git commit (UNTRACKED = never committed) · `build` = LIB (in `build_stdlib.sh` MODULES) or `-` · `crefs` = corpus files referencing it · `callers` = other stdlib modules referencing it. Gate = which runner exercises it.

## 1. SYSTEM-LEVEL FINDINGS (the headline defects this audit surfaced)

| # | Finding | Severity | Disposition |
|---|---------|----------|-------------|
| S1 | **Coverage ratchets currently exceeded**: fresh reports (2026-07-01) show uncovered=75 > pin=5, under-proven-gates=10 > pin=2, dark-surface=157 > pin=14. The new exact-geometry/studio organ families added exports without ratchet integration. A clean `build_stdlib.sh` run FAILS today. | **CRITICAL** | FIX: cover or trim the new export surface (per-module verdicts below name each export family); re-pin only downward. |
| S2 | **Untracked shipped work**: the entire III-STUDIO family (`iii_studio`, `ws_*`, `studio_theme`, `studio_trig`, `forge_scratch`, `ws_bench`…), corpus 2169, `build_studio.sh`, `DOCS/III-STUDIO.md`, `SEAL.mhash` are UNTRACKED. A working shipped feature exists only on this disk. | **CRITICAL** | FIX: commit the studio family (minus scratch — see per-file verdicts); `forge_scratch.iii` is QUARANTINE, not commit. |
| S3 | **Python in the sovereign tree**: `COMPILER/BOOT/*.py` (7 files) + `STDLIB/scripts/*.py` (6 files) violate the no-Python lock. Most are one-shot historical generators (r3 port era) or reference-vector generators whose outputs are already committed. | HIGH | DELETE the dead generators; QUARANTINE (move out of tree or to a `ceremonies/`-style attic) the two FIPS-205 reference generators + `gen_self_atlas.py` after confirming native replacements (`self_cartographer`/`self_emit`) fully supersede. Legacy `cartographer.py` fallback path in `build_stdlib.sh` should be trimmed once carto native is standard. |
| S4 | **Debris at STDLIB top level**: ~120 underscore files (`_loop_build*.out` ×18, `_loop_corpus*.out` ×13, `_wf_discovery_w*.js` ×25, `_wf_enhance_w*.js` ×10, `_w*_build/corpus.out` ×~20, probe scripts, logs) — session litter committed or strewn untracked next to load-bearing scripts. | HIGH | DELETE all `_*.out/.log/.js` litter; keep `_negproof*/`-referenced scripts only if a gate cites them (per-file verdicts §11). |
| S5 | **Corpus dir litter**: `STDLIB/corpus/diag_*.iii.o.s` (5 stale build artifacts), `_quarantine_wip/`, `_fips205_*.json` (2 vector files), `_reach_remote_e2e.iii` (underscore-skipped) sit inside the KAT source dir. | MED | DELETE the `.o.s` artifacts; move vectors beside their generator or into a `vectors/` subdir; adjudicate `_quarantine_wip` contents (§10). |
| S6 | **Root artifact litter**: ~80 untracked `.exe/.bmp/.png/.gif/.witness/.mlog/.s` build products at repo root (`geocolor_*`, `glass*`, `egraph*`, `color3_*`, `atlas*`, `aashow.exe`, …). | MED | DELETE (regenerable); add gitignore patterns for `*.exe/*.bmp/*.png` at root or emit demos into `build/`. |
| S7 | **`build_stdlib.sh` MODULES list carries orphaned comments** (e.g. an APOTHEOSIS C.11 "tournament quorum optimizer" comment with no module line following; C.8 "unified_cost_manifold" comment preceding `aether/bone_marrow`) — the ledger-in-comments has drifted from the list. | LOW | REFACTOR: sweep MODULES comments to match reality (comment-only edit, zero build impact). |
| S8 | **Two-runner ownership is implicit**: 9 family runners + run_corpus SKIP-cases encode corpus ownership as hand-maintained case patterns; adding a KAT to the wrong family silently double-judges or orphans it. | MED | REFACTOR (unify): one ownership manifest consumed by run_corpus + family runners; see §11 scripts verdicts. |

## 2. STDLIB/iii/aether — 140 files

### 2a. Core IO / capability substrate (all LIB, all gated) — KEEP

| file | loc | facts | verdict |
|---|---|---|---|
| capability.iii | 292 | c208 k73 | **KEEP-CORE** — the rights/attenuation/revocation tree every IO call verifies. |
| fs.iii | 386 | c118 k65 | **KEEP-CORE** — the one capability-gated FS surface. |
| net.iii | 189 | c19 k17 | **KEEP-CORE** — the one capability-gated TCP surface. |
| handle.iii | 136 | c20 k8 | **KEEP** — opaque OS-resource handle discipline. |
| tcp.iii | 139 | c7 k0 | **KEEP** — `@linear` socket wrapper over net. |
| inet.iii / inet6.iii | 131/260 | c4/c3 | **KEEP** — v4/v6 parse-format pair (inet6 closes inet's documented deferral). |
| witness_hook.iii | 489 | c59 k138 | **KEEP-CORE** — the provenance chokepoint (highest fan-in in aether). |

### 2b. The Reach (content-addressed transport, 7 tiers) — KEEP as a family

backend_memo (114, L0 RAM) · reach_store (179, L1 disk) · backend_ipc (182, L2 shared-mem) · backend_loopback (166, localhost serve) · backend_remote (223, L4 TCP) · reach_core (214, resolver+integrity) · reach_oracle (100, determinism-firewall bridge). Each tier ~100-220 loc, individually KAT'd, integrity checked only at reach_core (dumb byte tiers below). **KEEP all 7** — uniform, layered, no overlap.

### 2c. Develop-up sealed-box layer (11 slices + capstone) — KEEP

vbd (77) · flow_firewall (64) · sentinel (111) · enclave (101) · replay_box (79) · compute_box (74) · snapshot_box (109) · sid_router (86) · attest_box (99) · determinism_firewall (102) · sealed_box (71) · develop_up (201, capstone, c26). Uniform small organs, every slice corpus-gated, composed by ONE entry point. **KEEP all 12** — this family is the model the rest of the tree should match.
- xii_sort_meter.iii (35, c2 k0): **REFACTOR (MERGE)** — a 35-line R042 sort-penalty tier charging the compute_box meter; fold into compute_box (it is a meter tier, not an organ). Related: corpus KATs referencing xsm_* (2 refs) retarget to compute_box exports.

### 2d. Federation / consensus — KEEP with one MERGE

| file | loc | facts | verdict |
|---|---|---|---|
| fed_tier/fed_sybil/fed_eclipse/fed_admit/fed_genesis/fed_seal | 113-340 | c5-c25 | **KEEP** — the admission ladder, each stage gated. |
| hotstuff.iii | 872 | c29 | **KEEP** — the 3-phase pacemaker core. |
| hotstuff_predict.iii | 105 | c3 k0 | **REFACTOR (MERGE)** — pre-formed 2f+1+k quorum; fold into hotstuff_unified (both are pacemaker satellites; three modules for one protocol fails uniform-modularity). |
| hotstuff_unified.iii | 118 | c1 k1 | **KEEP** (after absorbing predict) — the tier-aware certified-monotone pacemaker. |
| pq_quorum.iii | 101 | c6 | **KEEP** — ML-DSA quorum certificates (quantum-adversary survival; unique). |
| node_identity.iii | 418 | c14 k6 | **KEEP** — per-host cryptographic selfhood. |

### 2e. Sovereign wire stack (Phase D) + legacy HTTP interop — KEEP

babel_wire (302, c63 k20) · cap_handshake (312, c11) · sealed_channel (282, c32) · idoc (233, c22) · pattern_set_federation (287, c17) — **KEEP all 5** (the III-native wire).
http_client (741, c35) · http_server (721, c26) · http (163, c7 k0) — **KEEP** as the legacy-interop surface, labeled: the sovereign path is babel_wire; http.iii is the capability facade. cap_zkp (89, c6) **KEEP** (zk capability proof, composes merkle+cad, no new crypto).

### 2f. Constitutional enforcement organs (M/W-mandate machinery) — KEEP, consumption-by-design

These are anomaly-time chokepoints: low corpus fan-in (c1-c9) is their design point, not rot. **KEEP**: quarantine (640) · firmware_quarantine (355, M5 anti-brick) · reversibility_audit (554, M9) · snapshot_lattice (383, W26) · triple_check (368) · distress_witness (396) · witness_compactor (337, W38) · memo_compactor_coordination (267) · cost_overrun_handler (551, M19/W37) · branch_governance (420) · bisimulation_witness (308, W41) · context_awareness (631) · memo_query (587, M17) · manifest (394) · bone_marrow (825, W30 RS-coded seed archive) · attestable satellites above.
- topology_atlas.iii (654, c9 k2): **REFACTOR (TRIM)** — its internal dijkstra routing is documented as subsumed by eidos/route (general-N, path-returning); retire the superseded routing path, keep the typed-edge atlas.
- basal_probe.iii (607, c1 k0) + shape_negotiator.iii (442, c1 k0): **KEEP** — the substrate-probe pair (deterministic experiment + sheaf gluing); unique host-adaptivity, gated. Flagged: lowest consumption of any 600-line organs; first candidates for the S1 export-trim sweep.
- cap_forge.iii (701, c8 k0): **KEEP** — capability fibration synthesis (Layer 7); unique.

### 2g. Phase III/IV probability + perception organs — KEEP

percept_infer (40) · perception_membrane (72) · provisional_universe (72) — small, gated, campaign-complete. **KEEP all 3.**

### 2h. Exact-geometry organ family (standalone-gated; the 7 faces + dynamics programs) — KEEP

All dated 2026-07-01, gated by run_sqrtsum_kats.sh / run_aether_lens_kats.sh (disjoint from libiii by design — documented in build_stdlib.sh):

| file | loc | gate | verdict |
|---|---|---|---|
| sqrt_sum_sign.iii | 926 | c40 k16, 2120-2149 | **KEEP-CORE** — THE exact-sign ladder (6 rungs); the substrate every face composes. |
| q23_sign.iii | 29 | c1 k1 | **KEEP** — the ℚ(√2,√3) quotient facade routing through verb_geom's e-class cache (deliberately thin; the weld). |
| kfield.iii | 556 | c17, weld 2159 | **KEEP** — Galois-tower tier of the ladder. Label: sound only as a ladder tier (i64 small-env unsoundness documented; tier-gated). |
| verb_geom.iii | 128 | c10 k3 | **KEEP** — e-class cache of exact-value identity (the address=identity memory). |
| exact_denest.iii | 83 | c3 k3 | **KEEP** — ℚ(√d) perfect-square denesting (rank-1). |
| exact_surd_value.iii | 111 | c11 | **KEEP** — relocated from TOOLS-QUOTIENT. Related cleanup: DELETE the staging copy in TOOLS-QUOTIENT/ (§13). |
| algnum.iii | 219 | c7, gate 2157 | **KEEP** — decidable equality of real algebraic numbers (capstone face 7). |
| sturm.iii | 242 | c22, gate 2156 | **KEEP** — exact root isolation (face 6). |
| delaunay.iii | 84 | c6, gate 2154 | **KEEP** — exact orient2d/incircle2d (face 5). |
| csg_kernel.iii / csg_tree.iii | 116/121 | c14 each, 2150/2168 | **KEEP** — exact quadric membership + the boolean-composing DAG. |
| cyclotomic_se3.iii | 174 | c20, gate 2152 | **KEEP** — zero-drift ℚ(√2,√3) rotation. |
| collide.iii | 106 | c2, gate 2153 | **KEEP** — no-tunneling swept collision. |
| photon_route.iii | 108 | c6, gate 2151 | **KEEP** — exact O_h lattice routing. |
| traj_kinematics.iii | 191 | c18, gate 2143 | **KEEP** — exact arclength/kinematics. |
| lattice_march.iii | 179 | c16, gate 2147 | **KEEP** — unbounded periodic-crystal ray march. |
| constraint.iii | 71 | c5 | **KEEP** — Sturm-certified constraint solving (degeneracy certified, not jittered). |
| billiard.iii | 259 | c13 | **KEEP** — field-rational reversible billiards (Program I Phase 1). |
| gas.iii | 323 | c18 | **KEEP** — N-body hard-cube gas, conservation as integer identity (Program II Phase I). |
| cspace.iii | 234 | UNTRACKED | **FIX (commit + verify gate wiring)** — the C-space vector (Program II Vector I); mid-audit, KAT 2175_arc_sweep landed externing it, so it is now gated-in-principle — verify 2175 is registered in its family runner/EXPECTED, then commit. |
| arc_sweep.iii | ~230 | UNTRACKED, landed MID-AUDIT | **FIX (commit + register)** — the rotational arc-sweep certificate (Program III Vector VI): Weierstrass-rationalized degree-4 integer clearance polynomial + Sturm root_count==0 as the continuous no-collision certificate over a cyclotomic arc. New KATs 2174_gas_demon + 2175_arc_sweep arrived with it (all three untracked). They MUST be registered in a family runner/EXPECTED (unregistered conformance KATs FATAL the sweep by design) and committed. Once done: KEEP. |
| wb_kernel.iii | 39 | c3 k8 | **KEEP** — extracted float-free workbench kernel (the testable organ behind aether_world). |

### 2i. AETHER-LENS render family — KEEP (gate-compiled apps)

aether_lens (440, c21, gates 2155/2158) **KEEP-CORE** · aether_lens_frame (332, c7) **KEEP** · aether_lens_view (92, terminal viewer) / aether_lens_win (94, Win32 viewer) / aether_world (1002, workbench) — **KEEP (apps)**: compiled by run_aether_lens_kats.sh so they cannot rot; their windowed surfaces are the S1 dark-export source (frame_*/lens_* uncovered) → FIX under S1: cover the pure parts (frame_px, lens_t_cmp_fast already computable headless) and mark the window pump as app-surface.
- world_graph.iii (1760, c0 k9): **KEEP (generated data)** — the extracted extern-edge graph aether_world analyzes. Label GENERATED; regenerate rather than hand-edit.

### 2j. GLASS UI engine + fonts — KEEP core, TRIM the outlier

| file | loc | facts | verdict |
|---|---|---|---|
| ui_raster.iii | 128 | c7 k56 | **KEEP-CORE** — the NIH framebuffer rasterizer. |
| ui_exact.iii | 1331 | c65 k59 | **REFACTOR (TRIM + SPLIT)** — the exact coverage engine is load-bearing (gates 2080-2102) but is aether's size outlier and the top source of S1 uncovered exports (ui_cub_*, ui_cubic_*, ui_bigc_round_i64dbg, ui_tcmp_q, ui_arc_cover2d_sym...). TRIM: de-export or cover the debug surface. SPLIT: the cubic/arc tier (~lines past the tri/edge core) into ui_exact_cubic.iii so the module returns to family size. |
| ui_exact_big.iii | 70 | c7 | **KEEP** — bigint escape tier. |
| ui_exact_sym.iii | 147 | c6 | **KEEP** — sym-assembler finisher (deliberately its own tier). |
| ui_exact_bigcov.iii | 293 | c1 | **KEEP** — big coverage tier (gate 2103+). |
| ui_field.iii | 442 | c47 k56 | **KEEP-CORE** — the unified field (15 faculties, gates 2104-2118). |
| ui_win.iii | 138 | k80 | **KEEP-CORE** — the one Win32 window backend (80 extern sites). Its input exports (ui_key/ui_getchar/ui_mdown...) are S1 dark surface → cover via a headless-pump KAT or mark app-surface. |
| ui_font.iii / ui_font_data.iii | 85/8 | k27/k1 | **KEEP** — bitmap font + data split. |
| ui_vfont.iii / ui_vfont_data.iii | 55/10 | k9/k3 | **KEEP** — vector font + data split. |
| ui_present.iii | 56 | k3 | **KEEP** — BMP writer (NIH, byte-exact). |
| ui_egraph.iii | 280 | k5 | **KEEP** — the LIVE e-graph view (builds + saturates a real e-graph; linked by studio zoom). |
| ui_egraph_app.iii | 8 | c0 k0 | **KEEP (app shim)** — 8-line main wrapper so the renderer stays main-free; labeled shim. |

### 2k. Pre-studio demo scaffolds — DELETE (superseded by the studio + gated KATs)

All 2026-06-27, corpus_refs=0, callers=0, no gate; each duplicates capability now carried by gated KATs (2080-2102) or by III-STUDIO workspaces:

| file | loc | superseded by | related files to clean |
|---|---|---|---|
| ui_demo_exact.iii | 39 | gates 2095/2097-2099 | root artifacts of the demo exe if present |
| ui_demo_glass.iii | 63 | gate 2080-2082 + ws_lens | `glass_demo.exe`, `glass.bmp`, `glass.exe` (root) |
| ui_demo_live.iii | 82 | iii_studio (live loop) | root exe |
| ui_demo_vfont.iii | 25 | ui_vfont + studio font use | root exe |
| ui_aa_showcase.iii | 47 | gate 2097 exact-AA | `aashow.exe` (root) |
| ui_curve_render.iii | 59 | gate 2099 exact-bezier | root exe |
| ui_glass.iii | 96 | gates 2080-2102 | root exe |
| ui_home.iii | 98 | iii_studio (ws_home) | root exe |
| ui_kats.iii | 134 | studio ws_console + run_*_kats gates | root exe |
| ui_zoom.iii | 106 | ws_zoom.iii | `zoom*.exe` if present |
| ui_repl.iii | 269 | ws_console.iii | root exe |

**DELETE all 11** (633 loc of superseded scaffolding). None appear in MODULES, corpus, or any runner — zero loose ends beyond root artifacts (§12).

### 2l. Unique ungated capabilities — FIX (gate them; they carry value no other module has)

| file | loc | verdict |
|---|---|---|
| ui_morphic.iii | 116 | **FIX** — direct-manipulation editing that writes a constant back into SVIR source (the "UI is the code" germ; nothing else does this). Gate it (a KAT asserting the SVIR write) and wire it as a studio workspace, else it rots. |
| ui_destiny.iii | 143 | **FIX** — the time-scrubbing destiny debugger over field history (unique temporal debugging). Gate + studio workspace. |
| ui_topo.iii | 161 | **KEEP + FIX dependency** — Topological Windowing (gates 2088-2093 exist) but run_corpus marks its runner "depends on volatile ser_antiunify/ser_petri WIP" → stabilize that dependency (see numera ser_* verdicts §8). |

### 2m. Field/fractal falsifier demos — REFACTOR (merge to one driver) + gate

field_dim (58) · field_run (156) · field_full (219) · fractal_dim (142) · mandel_run (190) — the "genuine unassisted output" demo mains (2026-06-27), all c0 k0, no gate. The capability they prove (real output on uncurated input; Shishikura dim-2 falsifier) is worth keeping, but five ungated mains is scaffold sprawl. **REFACTOR (MERGE)**: fold field_dim + field_full into field_run (one driver, argv-selected); keep fractal_dim + mandel_run as the two falsifiers; register all in one demo smoke gate (new `run_demo_smoke.sh` or a studio console entry) so they cannot rot.

### 2n. III-STUDIO family — FIX (commit), then KEEP

iii_studio (206) · studio_theme (110, k83) · studio_trig (47, c3) · ws_home (162) · ws_console (279) · ws_forge (316) · ws_lens (94) · ws_zoom (162) · ws_bench (345) — ALL UNTRACKED (finding S2). Verified working (gate 2169 + family compile). **FIX: commit the nine**, then KEEP (each workspace is a live instrument on real faculties; sizes uniform).
- forge_scratch.iii (15, UNTRACKED): **QUARANTINE→rename** — it is the studio's F7 live-compile sample target, not an organ. Commit under a name that says so (`studio_sample.iii`) or move beside the studio assets; do not leave a file named "scratch" in the stdlib.

**aether totals: 141 files (arc_sweep landed mid-audit) → 103 KEEP · 11 DELETE · 6 REFACTOR · 21 FIX-tagged (9 studio commits + cspace + arc_sweep + morphic + destiny + topo-dep + S1 export sweep across lens/ui_win) · 1 QUARANTINE-rename.**

## 3. STDLIB/iii/eidos — 25 files

**LIB planner/display cohort — KEEP all 18:** anchor (83, c8) · canvas (230, c8 k23) · cli (148, c3) · coincidence (236, c16) · compose (244, c26 k22) · descriptor (145, c23) · field (66, c23 k13 — the ONE unified reader over ripple_field/event_substrate) · layout (548, c7) · memo (101, c11 — live SAT-skip consumer) · optgate (134, c7) · palette (67, c2 k6) · render (261, c5) · ripple (127, c79 — the unified ripple quantum, top eidos fan-in) · route (119, c10 — subsumes topology_atlas dijkstra) · temporal (185, c6) · weave (146, c27) · web (613, c30).
- orchestrate.iii (118, c12 k0): **KEEP + FIX** — its own header admits "nothing but a test calls orchestrate" (seven EIDOS capabilities, zero live consumers). The declared next rung: a real III op (tp_* or the studio spawn path) must invoke host-adaptive composition, else this is a certified island.

**Standalone ripple-merge cohort (run_ripple_kats.sh, gates 2126-2134/2145) — KEEP all 7:** eidolon (194, c15 — the perfect-identity primitive) · membrane (101, c10) · disposer (72, c4) · eid_plan (72, c5) · epoch (86, c3) · reactor (92, c8 — the Dynamic Reactor) · ripple_eidolon (56, c2).

**eidos totals: 25 → 25 KEEP (1 carrying a FIX: wire orchestrate's live consumer).**

## 4. STDLIB/iii/forcefield — 27 files

**KEEP-CORE:** cg_autocatalyst (510, c56 k43 — the kernel-certified discovery membrane) · cg_opt_rules (608, c17 k16 — Path-C rule table + certifier bound to cg_r3's real emission) · ripple (281, c79) · ripple_metric (257, c47 k31 — the computable objective) · commit_gate (151, c9 k11 — the ONE admission decision).

**KEEP:** bv_dispose (239, c5) · daemon_dream (211, c7 — the dream-loop driver) · forked_walk (125, c8 — reversible speculative search) · invent_loop (241, c12) · optinvoke (251, c11) · pleroma (496, c3 — coherence gate, wired into the build) · pcc_gate (40, c2 — THE proof-carrying-code admission; small but unique) · integrity (66, c2 — G1 φ + non-vacuity ledger) · ripple_apply (472, c6) · ripple_journal (151, c6) · ripple_loop (104, c4) · ripple_cut (41, c2) · ripple_unify (85, c3) · ripple_extract (230, c15) · ripple_search (54, c5) · proof_ripple_unified (208, c2 — the MERGE/CUT/EXTRACT decider) · cg_surgical_strike (73, c2 k4) · ast-hunter's sweep partner scythe_census (88, c3).

**REFACTOR (UNIFY — three "one interface" layers over the same calculus):**
- ripple_synthesizer.iii (190, c1 k0) — composes metric/search/loop/cut/extract + the unified decider…
- sovereign_optimizer.iii (319, c12 k0) — "the unified production interface to self-optimization"…
- …both claim the same seat, and proof_ripple_unified already unifies the deciders. **MERGE ripple_synthesizer INTO sovereign_optimizer** (one production facade), keep proof_ripple_unified as the decider. Related: retarget ripple_synthesizer's 1 corpus KAT.
- daemon_scythe.iii (72, c1 k0): **REFACTOR (MERGE)** into scythe_census — the scythe pipeline (ast_hunter→proof_bisimulation→cg_surgical_strike→scythe_census) does not need a separate 72-line driver.
- ripple_dyn.iii (259, c8 k0): **KEEP, flagged** — the signed dynamic-name layer sits on the legacy ripple network; eidos/field is documented as the one reader and the redundant ripple machinery is slated for retire-by-attrition (zero-consumer-proven, never on faith). When the attrition proof lands, this is first in line.

**forcefield totals: 27 → 24 KEEP · 3 REFACTOR (2 merges + 1 unify).**

## 5. STDLIB/iii/intent — 5 files

One pipeline, uniform small organs, corpus-gated at the pipeline mouth: lex_ontology (118, k2) · intent_lex (61, k1) · disambiguate (72, c7) · synthesis_bridge (82, c5) · intent_attest (42, c2). lex_ontology/intent_lex have c0 but are reached transitively through disambiguate (reachability ratchet green on them). **KEEP all 5.**

## 6. STDLIB/iii/katabasis — 22 files

The descent substrate, increments 1-15 + metal-arch POCs; all LIB, uniform 36-217 loc, all gated: admit (36) · bar_layout (85, .def-generated) · behavioral_fp (53) · behavioral_seed (69) · bricking (68) · caps (55) · census (87, .def-generated) · cpu_census (69) · crystal_cap (66) · cycle_admit (63) · cycle_family (112, .def-generated) · cycle_term (119, c14 k11) · descent_proof (49) · gate (50) · gate_verdict (81) · pci_enum (103, c20) · quine_seal (217, c4 — M23; label: Ring-0 arm never executed, user-mode arm gated) · ring_lattice (65, .def-generated) · seal (63) · stage (44) · svm_layout (104, .def-generated) · vmexit (90, .def-generated). The six .def-generated modules are single-sourced with build-failing drift gates — the correct pattern. **KEEP all 22.**

## 7. STDLIB/iii/memoria — 5 files

arena (157, c306 — the universal consumer) · region (192, c27 — the ONE VirtualAlloc surface) · span (148, c15) · tempaloc (167, k13 — the ONE type-discriminated handle organ) · seal_organ (233, c9). **KEEP all 5 (KEEP-CORE: arena, region, tempaloc).** This is the smallest, cleanest subsystem in the tree — the uniformity benchmark.

## 8a. STDLIB/iii/nous — 28 files

**Proposer chain (transitively reached internals are by-design):** nous_socket (224, c9) · nous_policy (189) · nous_features (112) · nous_lattice (100) · nous_costlin (144, c1) · nous_value (84) · nous_train (133, k7 — ADR-N8 trainer-out-of-tree) · nous_synth (161, k12 — the M15 non-canonical client) · nous_search (331, k5) · nous_commons (230, c1) · nous_charter (232) · nous_completion (502, c1 — Knuth-Bendix completion) · nous_behavioral_key (167). **KEEP all 13.**
- nous_costlin carries a **FIX**: DOCS ADR-6 names the nous↔eidos/compose wiring (costlin as the canonical total order for the Composer) as identified-but-NOT-done. Do the wiring or strike the ADR.

**Conjecture tier — KEEP all 4:** nous_conjecture (176, c14) · nous_conjecture_term (251, c22) · nous_conjecture_gen (79, c3) · nous_conjecture_lemma (130, c5).

**Campaign/autogenesis organs — KEEP all 11:** beam_search (125) · lemma_forge (169) · search_market (128) · cegar sibling pac_certify (37) · perceptual_proposer (83) · bayes_search (81, k5) · gap_conjecture (233, c11) · harmony_synth (228, c14) · refactor_propose (181, c17) · optimize_self (135, c10) · theorem_grow (199, c10 k4 — the persistent re-verified theorem DAG).

**nous totals: 28 → 28 KEEP (1 carrying a FIX: ADR-6 costlin wiring).**

## 8b. STDLIB/iii/numera — 314 files

All 314 are LIB + corpus-gated. Verdicts by family; every file named.

**Kernel & proof substrate — KEEP-CORE (size justified by load):** typecheck (3502, c289 k241 — THE CIC kernel) · ccl (1471, k45 — the trusted-base reducer; seal-gated) · proof_term (1535, c77) · theorem_commons (199, c40) · theorem_carrier (746, c12) — three theorem stores, layered not duplicated: carrier=artifact format, commons=session registry, nous/theorem_grow=persistent DAG; labels added · k0_referee (164, c19 k38) · golden_shift (150) · curry_howard (315) · induct (104) · safety_type (116) · congruence_closure (311, k16) · congruence (228, c26 k15 — distinct: the global merge ring) · proof_replay (115) · proof_replay_cache (92) · proof_parallel (95) · proof_stark (134) · proof_jit (100) · proof_carrying (701) · quine_verifier (325, W25) · translation_validation (82).

**Deciders & solvers — KEEP-CORE:** sat (805) · sat_at_scale (851) · smt (2229, c31) · bv_bits (1012, c329 — the widest-consumed module in III) · bv_ring (713, c67) · bv_commons (204) · egraph (2036, c82 — live in cg_r3 via seg_*) · egraph_stochastic (87, k7) · mcmc_egraph (162) · relational_ematch (171) · egraph_hw_ematch (113) · groebner (1464, c28) · unify-sibling congruence machinery above.

**Arithmetic core — KEEP-CORE:** scalar (330, c28) · checked (93, c20) · modular (128) · sat_arith (122, c14) · fixed (224) · fixed_extra (192, c25) · q128 (271, c33) · q128_f64 (212) · bigint (1016, c240 k161) · bigint_div (1129, c34) · bigint_karatsuba (195) · ntt_bigint (307) · endian (152, c20) · bitops (132, c19) · hex (102) · barrett (186) · modular_mont (167) · field (214, c23) · field_crystal (122) · checked_crystal (174) · scalar_provenance (141) · crt (172) · trit (143, k24) · uncertainty (363, k17) · logic6 (156, c27) · voice (112, c17) · tense (63) · quine6 (114, k6).

**NIH crypto suite — KEEP all (KAT/vector-gated):** sha256 (494, k91) · sha256_ni (494) · sha256_dispatch (107) · sha512 (430) · sha3_256 (42) · sha3_512 (40) · shake128 (41) · shake256 (39) · keccak (445, k36) · keccak256 (257, k26) · keccak_sponge (114) · blake2s (534) · hmac (164) · hkdf (194) · pbkdf2 (214) · drbg (188) · aes (501) · aes_gcm (629) · aes_siv (252) · chacha20 (364) · poly1305 (466) · chacha20_poly1305 (168) · xchacha20_poly1305 (68) · x25519 (185) · fe25519 (551) · ed_scalar_modl (213) · crypt_ed25519 (303, c47) · fp256/fn256/ec256/ecdsa_p256 (273/278/238/239) · fp384/fn384/ec384/ecdsa_p384 (228/222/220/193) · rsa (968, c26) · mldsa (1260) · mlkem (709) · pq_params (229) · pq_dispatch (136) · ntt_ctx (107) · siphash (126) · murmur3 (62) · adler32 (56) · crc32 (122) · xoshiro (249) · weave_blocks (115, k25 — the shared ARX weave the primitives route through).
- slhdsa.iii (957, c17): **KEEP, labeled** — header honestly declares E-SLH-2 NON-STANDARD instantiation (not FIPS-205 wire-interoperable). Either keep the label prominent or schedule the FIPS-interop variant; the two `fips205_*.py` reference generators in scripts/ exist only for this (see §11).

**ZK stack — KEEP all:** zk_field (1588, c50) · zk_air (1233, c46) · zk_stark (522) · zk_snark (400) · zk_stark_seal (107, k8) · zk_prune (339) · zk_rev (121) · zk_ext2 (73) · zk_ext4 (48) · ntt (349) · ntt_fri_organ (137, k21) · merkle (466, c27) · proof_carrying listed above.

**Weave/invention program — KEEP all:** invent (1309, c88) · present (440, c53) · primweb (245, c17) · weave (99, c27) · weave_graph (785, c55) · weave_self (361) · weave_interfile (179) · weave_forge (58) · gx_bridge (65 — the genesis→cg_r3 bridge) · symbolic_regression (1658, c4 k0): **KEEP + FIX** — unique closed-form synthesis organ but 4 KATs on 1658 loc is the thinnest gate-to-mass ratio in numera; add falsifier KATs (wrong-form rejection, overfit refusal).

**Cost/microarch stack — KEEP:** cost_lattice (662, c19 k21) · cost_calculus (625) · microarch_model (557, k11) · costed_cat (210) · entropy_monitor (436) · tiebreak (214) · algebraic_time (55, k14).
- cost_lattice_synth.iii (525, c3 k0): **KEEP, flagged** — the V3 extended vector has no consumer yet; if still k0 at next audit, MERGE into cost_lattice.
- pareto_extraction.iii (129, k7) vs pareto_frontier.iii (152, c3 k0): **REFACTOR (UNIFY)** — two antichain-of-cost-vectors organs; MERGE pareto_frontier INTO pareto_extraction (one 6-D dominance module), retarget frontier's 3 KATs.

**Verified-algorithms shelf (the Convergence library) — KEEP as a family, 2 merges:** dijkstra (135, k4) · binary_search (101) · kmp (146) · levenshtein (121) · lcs (166) · lis (148) · fenwick (124) · segment_tree (138) · knapsack (121) · coin_change (105) · inversion_count (122) · sieve (119) · gray_code (108) · catalan (92) · rms (116) · matrix_ring (160) · ring_opt (111) · huffman (328) · elias (150) · lzss (233) · lzh (163) · bitio (158, k10) · galois (964, k24) · gf_poly (250) · rscode (475) · rscode_ec (253) · hamming_secded (204) · shamir (296) · threshold_vault (236) · erasure_store (334, k8).
- goldbach.iii (91, c1) + collatz.iii (96, c1): **REFACTOR (MERGE)** into one `conjecture_probe.iii` — both are the same epistemic artifact (bulk-verify an open conjecture to N; can never prove it); two modules for one pattern fails uniqueness.
- cas_blob.iii (127, c1 k0): **REFACTOR (MERGE)** into erasure_store — both are erasure-coded content-addressed storage; cas_blob adds only the compression tier (fold as a mode). Retarget its 1 KAT.

**Optimizer-model stack (compiler theory as verified library) — KEEP as a family, labeled MODEL-TIER, 1 merge:** ssa (119) · gvn (137) · dce (117) · sccp (158, k4) · dominators (129) · liveness (111, k4) · reg_alloc (240) · isel (117) · list_schedule (129) · rewrite_schedule (141) · loop_optimizer (115) · loop_pipeline (107, capstone) · bce (157) · branch_elim (101) · vectorizer (105) · align_domain (108) · interval_lattice (155, k32 — real consumers) · widening (129) · kleene_fixpoint (162) · reduced_product (134) · value_range_prover (116) · loop_bounds_prover (77) · safety_prover (320) · range_check (102) · taint_analysis (140, k25 — real consumers) · ptr_provenance (179) · mem_rewrite (235) · tso (295) · heaplet (259, c20 k18) · sep_logic (285) · csl (220) · affine_check (111, k6 — the --affine-audit organ) · dp shelf lcs/lis listed above. Label: these model the optimization stack; III's REAL optimizer is XII+cg_r3 — no member may be cited as the live path.
- bmc.iii (109, c2 k0) + kinduction.iii (94, c1 k0): **REFACTOR (MERGE)** into one bounded/inductive model-check module — they are two halves of one method, and the LIVE verification membrane is the ser_* family (ser_tgraph/ser_kinduct); label the merged module model-tier.

**Autonomy/self-optimization organs — KEEP, 1 merge:** algo_synth (141) · isa_macro_synth (48) · ast_hunter (72) · conjecture_refute (138) · verified_search (175) · verified_ripple (129) · optimality_cert (142) · contract_gate (124) · rev_invoke (92) · reversible (753, k22) · sov_isa (2624, c59 — the descent optimizer) · sov_pipeline (110, labeled: the all-faculties-through-one-path prover).
- self_engine.iii (141, c1 k0) + omega_engine.iii (215, c2 k0): **REFACTOR (MERGE)** — both are "the one autonomous conjecture→prove→verify engine over real III" minted by successive waves (capstone sprawl; see also forcefield §4 unify). MERGE omega_engine INTO self_engine, one autonomous-loop capstone per layer.

**Constitutional/harmony organs — KEEP:** constitution (1174, k25) · constitution_preserver (388) · h1..h13_charter (191/215/178/209/211/159/269/213/264/301/265/223/265) · h9_mig2_tie (109) · charter_terminal (282 — folds all 13) · math_library (664) · math_library_curation (468) · founders_anchor (460) · constants (683) · reflection_constrained (583, k9) · reflection_governance (493) · witness_spine (538, k19) · branch_anchor (666) · computation_graph (758) · memo_lattice (693, k12) · identifier (153, k135) · cad (393, c62 k147 — KEEP-CORE) · category (1034, k39) · sheaf (662) · bft_quorum (96) · dijkstra listed above.

**Phase III/IV micro-organs — KEEP all 20:** cegar_refine (101) · evidence_calculus (92) · quantize_sensor (52) · sample_beacon (93) · distribution (91) · infer_exact (46) · markov_exact (48) · mc_certified (64) · belief_sheaf (97) · bayes_exact (42) · measure_status (36) · dp_exact (50) · infotheory (55) · approx_struct (53) · rand_algo (76) · pctl (29) · causal_scm (43) · aeu (112) · aeu_kernel (105) · hdl family: hdl (379, k29) · hdl_gate_db (287) · hdl_optimize (248) · hdl_compiler (177).

**Seraphyte organ cluster (ser_*, 30) — KEEP all:** ser_kvalue (134) · ser_energy (108) · ser_real (78) · ser_membrane (106) · ser_commit (66) · ser_discover (93) · ser_optimize (90) · ser_immune (101) · ser_diff (95) · ser_memo (102) · ser_isub (155) · ser_autopoiesis (110) · ser_petri (201, c16) · ser_cegis (89) · ser_antiunify (1236, c41) · ser_absint (194) · ser_cascade (75) · ser_cascade2 (118) · ser_regalloc (75) · ser_egraph (559, c37) · ser_intent (154) · ser_tgraph (196) · ser_kinduct (252) · ser_causal (549) · ser_tdriver (69) · ser_kinduct_sym (692, c45) · ser_eidos (92) · ser_pipeline (329, c15 — the production fold the reseal driver consumes) · ser_fsm (87) · ser_protocol (85).
- **FIX (stale volatility note):** run_corpus.sh still skips the topo family as "depends on volatile ser_antiunify/ser_petri WIP" — both are LIB, heavily gated (c41/c16) since 2026-06-27. Re-adjudicate the note; if stable, the skip comment is stale doc-drift (§11).

**XII support in numera — KEEP:** xii_ldil (1108, c36) · xii_nop_tables (140) · xii_subforms (346).

**numera totals: 314 → 304 KEEP · 10 REFACTOR (5 merge pairs: goldbach+collatz, bmc+kinduction, pareto_frontier→pareto_extraction, cas_blob→erasure_store, omega_engine→self_engine) · 2 FIX-notes (symbolic_regression gate, slhdsa FIPS label) · 1 stale-note FIX (ser volatility).**

## 9. STDLIB/iii/omnia — 157 files

**Containers & primitives — KEEP-CORE:** vec (484, c42) · map (490, c21) · set (65) · queue (313, c14) · pq (264) · list (201) · lru (366, c28) · iter (185, c38) · fold (108) · zip (61) · option (89, c24) · result (151, c27) · either (53) · crystal (360, c78) · crystal_deps (312) · crystal_edges (125) · async (352, c30) · bound (65, k9) · caindex (99, k15) · bench (70) · arena_slot_witness (80) · spec_probe (22 — generic-specialization canary; labeled).

**XII engine — KEEP-CORE:** xii_term (464, c387 k182 — highest corpus fan-in in III) · xii_rewrite (1288, c119 k50 — the 40 sealed rules) · xii_canonicalise (218, c20 k21) · xii_basis (238, c63) · xii_horizon (829, c28) · xii_horizon_reach (60) · xii_hj (171) · xii_savings (198) · xii_circ (283) · xii_chd (316, c22) · xii_lattice (224, c18) · xii_emit_gen (443, c19) · xii_kernel_emit (375) · xii_isub (81, c19) · plus numera's xii_ldil/subforms/nop_tables.
- Curated payload tables — KEEP (data; antidrift-gated): xii_curated_payloads (69) · xii_curated_embedded (50) · xii_curated_riscv (48) · xii_curated_extended (195).

**mig4 lowering + confluence certificate — KEEP:** xii_rule_patterns (302, k21) · xii_rule_overlap (167) · xii_critpair_enum (137) · xii_joinability (361, k23) · xii_termination (305) · xii_admission (117, k17) · xii_lower_compose/decide/iterate/program/then/with/under (162/116/125/148/121/106/105 — the seven lowerings, uniform, each gated) · xii_mig4_seal (212) · xii_strategy_det (97) · xii_discharge (190) · xii_conf_cert (247) · xii_cap_preserve (59) · xii_cost_monotone (63) · xii_denote (129) · xii_morphism (101).
- xii_rule_verify (177, c1) + xii_fusion_verify (103, c1) + xii_iflift_verify (116, c1): **REFACTOR (MERGE)** — the three "verification missile" strikes are one pattern (drive the LIVE engine against an independent authority) over three rule families; merge into one `xii_semantic_verify.iii` with three entry points. Retarget 3 KATs.
- xii_proof.iii (236, standalone) + xii_proof_check.iii (180, standalone): **REFACTOR (SPLIT — already prescribed by the tree)**: build_stdlib.sh documents the plan — separate the test-tamper hooks (xii_proof_set_rid/flip_ahash, currently polluting the uncovered-export report) from the proof-gadget API, add a positive corpus KAT, then admit to MODULES. Execute it.

**Inverse substrate / master-logic program — KEEP:** isub (167, c67 k67) · involution (89, standalone-gated 2126/2128) · unravel (127) · assimilate (165, c44) · ingest (64, c16) · enmesh (178) · canon_enmesh (134) · law_web (123) · master_logic (115) · reverse_search (176) · exec_cert (59) · event_substrate (226, c29 k27) · parity_game (164) · ripple (426, c79) · ripple_field (179, c20). *Caveat recorded: three subsystems own a `ripple.iii` leaf (omnia/forcefield/eidos) and two own `resolver_replay.iii` — leaf-name collisions are handled by .o namespacing but make per-leaf metrics ambiguous; do not add a fourth.*

**Resolution calculus (Intent v1.0) — KEEP:** resolver (1174, c25) · resolver_memo (244, c33) · resolver_replay (52) · proof_resolve (135) · resolution_init (199, c26) · resolution_meta_dispatch (30 — BSS-split shim, labeled) · call_context (319, c67) · pattern_table (254, c72) · unify (367, c25) · governance (566, c68) · self_reformatter (387, c19) · ai_resolve (127 — the top-level entry) · babel (127) · babel_intent (185; label: Babel ecosystem DORMANT) · mini_crystal (196) · jit_fuse (252) · jit_swap (118) · hw_offload (244) · layered_seal (139) · dynamic_record (106) · dynamic_impact (142) · prespec (2027 — generated section, drift-gated by gen_compositions.sh; label GENERATED) · sovval (304) · sov_morphism (302) · proof_bisimulation (61) · proof_ripple_resolution (287).

**Transform category (tp_*) — KEEP the organ, FIX the codec coverage:** transform (173) · transform_patterns (204) · codegen_dispatch (118) · tp_planner (373, c12) · tp_morphism (182). The 24 codecs: tp_raw_hex (111) · tp_iii_hex (16) · tp_pe_hex (16) · tp_iii_to_md (51) · tp_iii_to_latex (51) · tp_iii_to_c99 (98) · tp_x86_disasm (74) · tp_x86_assemble (68) · tp_iii_to_asm (120) · tp_asm_to_pe (83) · tp_iii_to_babel_json (104) · tp_babel_json_to_iii (111) · tp_iii_to_ast_bin (49) · tp_ast_bin_to_iii (49) · tp_babel_text (65) · tp_babel_text_back (57) · tp_babel_json_cbor (83) · tp_babel_cbor_json (81) · tp_ripple_dot (89) · tp_ripple_md (147) · tp_ast_dot (89) · tp_c99hdr_to_iii (129) · tp_ast_to_babel_json (87) · tp_babel_json_to_ast (20).
- **FIX:** 15 of 24 codecs + codegen_patterns.iii (119, c0) have ZERO direct corpus KATs (c0) — registered at boot, never individually proven (prove-the-positive-arm violation). One route-sweep KAT driving every registered arrow through tp_planner (golden outputs per codec) closes all 16 at once.

**Hexad — KEEP all 7:** hexad (67, umbrella) · hexad_algebra (167, k14) · hexad_pfs (68) · hexad_reach (160, k16) · hexad_epistemic (60) · hexad_mobius (115) · hexad_dynamic (101).

**Observability + sandbox — KEEP:** obs_log (144) · obs_metric (130) · obs_trace (171) · obs_observatory (109) · sandbox_ctor (180) · sandbox_exec (135) · sandbox_quota (121).

**Self-model — KEEP with one source-swap:** self_atlas (560, c60 k52) · self_atlas_lens (271, k28) · self_cartographer (238 — the native map builder) · self_emit (263 — the native data emitter) · self_report (126).
- self_atlas_data.iii (2068): **REFACTOR (regenerate via self_emit)** — header still says "GENERATED by gen_self_atlas.py — DO NOT EDIT"; the native emitter exists precisely to retire that Python step. Swap the generation source, update the header, then DELETE scripts/gen_self_atlas.py (§11, finding S3).

**omnia totals: 157 → 150 KEEP · 6 REFACTOR (3-missile merge, xii_proof split pair, self_atlas_data source swap) · 1 family FIX (16 uncovered codec/pattern registrations).**

## 10a. STDLIB/iii/sanctus — 31 files

**KEEP:** mhash (81, k103 — KEEP-CORE, the Crown hash) · witness (284, c32) · kchain (146, c37) · closure (114) · attest (113) · calculus_v1 (308, c36) · irreducibility_proof (345) · catalyst (175) · genesis (101) · promote (145) · demote (122) · observe (143) · onelang (534 — the native one-language cartographer) · seal_resolver (206) · resolver_replay (47) · legacy_artifact (142) · sovereign_witness (322) · corpus_coverage (1423, c37 — THE executable coverage ledger; size justified: it computes the S1 ratchets) · self_model (229, k14) · autogenesis (226, c29) · autogenesis_cli (218) · anchor_xii (146) · xii_antidrift (274) · xii_atm (118) · xii_curate (170) · xii_register_all (58) · xii_sml (144).
- mandate.iii (117, c8) + mandate_m22.iii (40, c1): **REFACTOR (MERGE)** — M22 is one 40-line clause-satellite of the mandate audit; fold it in.
- quality.iii (290, Q1..Q6) + quality_q7.iii (118, Q7): **REFACTOR (MERGE)** — one quality-gate organ Q1..Q7; the split is historical, not architectural.

**sanctus totals: 31 → 27 KEEP · 4 REFACTOR (2 merge pairs).**

## 10b. STDLIB/iii/tempora — 6 files

calendar (159, c18 k15) · instant (209, c16 — deterministic logical counter, no OS clock) · duration (156, c30) · deadline (128) · rfc3339 (135) — **KEEP all 5.**
- duration_cert.iii (98, c1): **KEEP, labeled** — the kernel-proved overflow theorem for duration, split out deliberately so duration stays dependency-light (typecheck isolation). Not a merge candidate for that reason.

## 10c. STDLIB/iii/verba — 46 files

**KEEP-CORE:** builder (201, c109 k48) · intent (536, c105) · glyph_core (175, k116) · pattern (223, k29) · rune (268) · string (176) · parse (167) · format (181).
**KEEP (codec/parse shelf):** json (1237, c45 — the one JSON; size justified) · uri (504, c26) · csv (248) · ini (327) · semver (325) · leb128 (174) · base32 (184) · base64 (240) · path (234) · html_escape (185) · normalise (524) · normalise_ascii (136) · regex (432 — Brzozowski, no backtracking) · glob (168) · markup (400 — the ghost-browser ingestion front) · timing_safe (29 — tiny by design; constant-time compare) · ulid (149) · uuid (84) · ast_intent (164).
**KEEP (Glyph V3 family, 16 codecs — the H3 "one serialization"):** glyph_u8 (56) · glyph_u32 (55) · glyph_u64 (56) · glyph_i64 (57) · glyph_f64 (59) · glyph_bytes (88) · glyph_str (122) · glyph_crystal (111) · glyph_vec (140) · glyph_map (161) · glyph_set (176) · glyph_enum (135) · glyph_record (124) · glyph_witness (136) · glyph_proof (124) · glyph_recursive (134). All corpus-gated (c7-c23), uniform.
**KEEP (HIP NL surface):** hip (660, c42) · nl_lex (1020, c13).
- nl_parse.iii (1011, c4): **KEEP + FIX** — 1011 loc of thematic-role tagging behind 4 KATs is the thinnest gate in verba; add role-tagger falsifier KATs (mis-tag must fail).

**verba totals: 46 → 46 KEEP (1 FIX-note).**

## 11a. STDLIB/sovir — 77 files (standalone gate-driver farm; c0/k0 is by design — each is compiled+run by a sovir runner)

**Toolchain organs — KEEP-CORE:** ccsv (2075, dated 2026-07-01 — the C→SVIR compiler, the completion-plan keystone) · iiisv (402) + iiisv2 (279 — DDC frontend diversity pair) · svir_verify (82) · svir_interp (184 — the reference executor) · svir_x86 (233) · svir_wasm (235) · svir_dis (78) · verify_each (51) · verify_main (11) · vdbg (66) · vdbgall (67).
**KEEP (gate fixtures/controls, tiny by design):** svir_prog (25) · svir_loop (26) · svir_fact (18) · svir_call (36) · svir_bignum (9) · svir_memtest (9) · svir_bad_br (4) · svir_bad_call (4) · svir_bad_end (4) · svir_bad_op (4) — negative controls · _ve_goodmod (8) / _ve_badmod (10) — instrument positive/negative controls.
**KEEP (zkVM opcode bricks, 18):** zk_svir_add (87) · zk_svir_sub (87) · zk_svir_mul (71) · zk_svir_bitops (108) · zk_svir_cmp (106) · zk_svir_shift (93) · zk_svir_range (77) · zk_svir_control (89) · zk_svir_mem (112) · zk_svir_mem_dynamic (171) · zk_svir_call (105) · zk_svir_stack (107) · zk_svir_loop (104) · zk_svir_straightline (106) · zk_svir_exec (82) · zk_svir_prog (105) · zk_svir_vm (82) · zk_svir_vm_fused (168).
**KEEP (Ω-phase ZK ladder):** zk_ext2_kat (34) · zk_ext2_fri (107) · zk_ext2_friq (124) · zk_ext2_friN (142) · zk_ext2_fri256 (130) · zk_ext2_live (116) · zk_ext2_live2 (136) · zk_ext2_stark (87) · zk_ext2_prod (160) · zk_ext4_kat (49) · zk_ext4_probe (22) · zk_ext4_fri (154) · zk_ext4_perm (164) · zk_ext4_committed (239) · zk_ext4_stark_committed (553) · zk_ext4_prod (164) · zk_perm_oracle (122) · zk_perm_malicious (50) · zk_perm_k3prod (204) · zk_fused_committed (459) · zk_fused_prod (267) · zk_eidos_fold (77) · zk_eidos_ripple (107) · zk_gu_ripple_xii (138) · zk_here_to_there (306) · zk_federate_quorum (122) · zk_trust_cert (86) · zk_iiisv_attest (151) · zk_iiisv_local (134) · zk_svir_attest (88) · xii_proof_demo (110) · eidos_ripple_native (65) · eidos_ripple_probe (68) · eidos_ripple_r0 (76).
- **REFACTOR (conditional TRIM):** the ladder's superseded POC rungs (zk_ext2_fri/friq/live/stark; zk_ext4_fri/probe) are earlier rungs of what zk_ext2_prod / zk_ext4_prod complete. If a sovir runner still runs them, they are regression rungs → keep; any rung NOT wired into a runner is a dead POC → delete. Adjudicated per-runner in §14 (runner-membership check).
- zk_fused_forge63.iii (421): **FIX** — its header comment is a copy-paste of zk_fused_committed's ("zk_fused_committed.iii — P2b SCALE-UP"); correct the header to describe forge63's actual variant.

## 11b. STDLIB/sovtc — 54 files (sovereign assembler/linker + stage gates)

**KEEP-CORE:** sovas (625, the x86-64 encoder) · sovparse (923, the GAS parser) · sovcoff (203, COFF emitter) · sovld (304, PE32+ linker) · sovlink_main (280, multi-object linker) · sovlink_probe (80) · sovas_main (68) · sovld_main (53) · crt0 (50).
**KEEP (stage-gate fixtures, tiny by design — each pins one encoder/linker behavior):** boot1 (31) · boot2 (25) · boot3 (19) · boot4 (20) · boot5 (12) · boot6 (11) · boot7 (3) · boot8 (14) · linklib (9) · linkmain (12) · sov_drive (22) · sov_drive2 (19) · sov_drive3 (20) · sov_drive4 (19) · sov_drive5 (18) · sov_drive6 (19) · sov_drive7 (19) · sov_drivel (18) · sov_drivel2 (18) · sov_drivel3 (19) · sov_drivel4 (21) · sov_drivel5 (19) · sov_drivel6 (18) · sov_drivel7 (20) · sov_drivel8 (23) · test_branch (35) · test_call (48) · test_cmp (30) · test_encode (135) · test_io (47) · test_lea (34) · test_movzx_sib (39) · test_relax_back (44) · test_relax_cascade (30) · test_reloc (60) · test_sib (41) · test_sib_disp (31) · test_sibcall (34) · test_spine (78) · test_store (36) · test_unknown (21 — the silent-drop teeth) · prog_egraph (13) · prog_sat (12) · prog_sha256ni (26) · prog_smt (3).

**sovtc totals: 54 → 54 KEEP.**

## 11c. STDLIB/independence — 12 files

The independence-proof driver family — **KEEP all 12:** indep_toolchain (30, proof #1) · indep_capstone (154, proof #3) · indep_cap_a (37) · indep_cap_b (85) · indep_cap_c (43) · indep_cap_drive (86) · indep_notary (101, proof #4) · indep_bignum (54) · indep_ops (18) · indep_recur (18) · indep_zkair (5) · indep_zkcolink (25 — the sf_* consolidation falsifier). Runner wiring VERIFIED: referenced by sovir's run_ccsv.sh / run_ddc.sh / run_svir.sh / run_zk.sh.

**sovir ladder-rung adjudication (resolves §11a's conditional):** run_zk.sh line 15 explicitly compiles the FULL ladder — zk_ext2_fri/friq/live/stark/friN/fri256/prod, zk_ext4_kat/probe/fri/prod/perm, zk_perm_* and the zk_svir_* bricks — as regression rungs. The remaining drivers are owned by the other 20 sovir runners (run_here_to_there.sh, run_federate_quorum.sh, run_trust_certificate.sh, run_trust_closure.sh, run_ext4_committed.sh, run_grand_unification.sh, run_xii_proof.sh, run_eidos_svir.sh, …). **All sovir POC rungs: KEEP (wired regression rungs).** Only zk_fused_forge63's copy-paste header FIX remains from §11a.

## 12. STDLIB/corpus — 1761 numbered KATs + 7 rejects + litter

**Gate architecture (verified in run_corpus.sh):** every numbered file is exercised — the conformance loop runs all `[0-9]*_*.iii` with a HARD-pinned EXPECTED exit code (a missing entry aborts the sweep, so silent miscounts are impossible), delegating by name to nine family runners: XII (280-372, 93 files) → run_xii_corpus.sh · GLASS-UI (10) → run_ui_kats.sh · BIGCOV (1) → run_bigcov_kats.sh · FIELD (2104-2118, 15) → run_field_kats.sh · SQRT-substrate (27) → run_sqrtsum_kats.sh · AETHER-LENS (2155/2158) → run_aether_lens_kats.sh · RIPPLE (2126-2134, 9) → run_ripple_kats.sh · TOPO (2088-2093, 6) → run_topo_kats.sh · BENCH (237/242/243/244) → run_bench_corpus.sh · SAT-heavy (1751/1763/1764) delegated to their fast proof twins (1755/1759/1761/1762). Negative-compile KATs (`*_neg_*`, 11 files) pass iff rejected; `*_pe_*` KATs additionally assert the III_PE_DIRECT_LOAD marker in emitted asm.

**Corpus verdict summary (full per-file table in §12-T below):**
- **1731 × KEEP** — gate-active, subject healthy.
- **19 × KEEP-RETARGET** — these are the corpus dependents of §2-§11 merge verdicts; each must be retargeted when its merge executes: 100_quality_gate_aggregate + 941_quality_q7_lint_falsifier (quality_q7→quality) · 384_hotstuff_predict (→hotstuff_unified) · 884/885/1331 xii_*_verify (→xii_semantic_verify) · 1091_ripple_synthesizer (→sovereign_optimizer) · 1203_daemon_scythe (→scythe_census) · 1225_cas_blob (→erasure_store) · 1254_omega_engine + 1509_accessor_bounds… (→self_engine) · 1255_pareto_frontier + 1605_findings_w2616_tier2 (→pareto_extraction) · 1288_bmc + 1289_kinduction + 1604_findings_oob_guards (→merged model-check module) · 1309_goldbach + 1310_collatz (→conjecture_probe) · 1741_xii_sort_meter (→compute_box).
- **6 × KEEP-FIXDEP** — the TOPO family (2088-2093) rides the "volatile ser_antiunify/ser_petri WIP" skip note adjudicated stale in §8b; unblock with that fix.
- **5 anomaly flags adjudicated by hand:** 238_resolver_unit_avx512_parity + 242_bench_resolver use deliberate `from "_unused.iii"` decorations for symbols provided by hand-written .s objects — KEEP (linking is symbol-based; decoration intentional). 1673_self_cartographer externs alpha/beta.iii it WRITES ITSELF as fixtures — KEEP. 1048_json_uescape contains raw non-UTF8 bytes (that is the test) — KEEP. 1492_mathlib_index_differential declares `ident_eq from "ident.iii"` — no such module exists; the symbol resolves from elsewhere, so this is a stale extern decoration: **FIX (point the `from` at the real provider)**.
- **Numbering gaps: 582** (max number 2300, 1718 distinct numbers present) — historical deletions (dome KATs, superseded waves); gaps are healthy, no action.
- **corpus_reject/ (7 fixtures): KEEP all** — r01_unresolved_ident · r04_unknown_fn_call · r05_bad_token · r07_undeclared_assign · r08_dup_fn (+2 more per reject_conformance.sh listing); the compiler-rejection conformance gate depends on them (build-blocking via build_stdlib.sh).
- **Litter inside corpus/ (finding S5):** `diag_local_array.iii.o.s`, `diag_mixedargs.iii.exe.s`, `diag_signed_compare.iii.o.s`, `diag_u32_slot.iii.o.s`, `diag_u32_store_width.iii.o.s` — DELETE (stale build artifacts; the sources they came from are the write-trap probes, already memorialized). `_fips205_sha2_128s_small.json` + `_fips205_slhdsa_128s.vectors.json` — move next to their consumer or a vectors/ subdir; KEEP content (slhdsa KAT vectors). `_reach_remote_e2e.iii` — underscore-skipped manual e2e driver: KEEP, labeled (needs a live remote; can't be a gate). `_quarantine_wip/` — contains only its README: KEEP as the designated quarantine anchor.

### §12-T. Full corpus table

See **APPENDIX A** at the end of this document — all 1761 rows, format `file|owner|verdict|extern-subjects|note`.

## 13. COMPILER/BOOT — 152 files + 4 subdirs

### 13a. The self-hosted compiler (.iii) — KEEP-CORE, the crown

ast.iii (4457) · parse.iii (4027) · cg_r3.iii (3848) · lex.iii (2447) · sema.iii (2140) · link.iii (1557) · cg_r0.iii (1579) · main.iii (1290) · sid.iii (1229) · emit.iii (1104) · proof.iii (1050) · jit_emit.iii (982) · witness_alloc.iii (930) · emit_sanctum.iii (887 — the ONE sanctum-family engine) · hexad_check.iii (619) · acc.iii (542) · ceiling.iii (306) · cg_r3_xii_adapter.iii (261) · iii_cg_pe_iiis1.iii (236) · lex_rt.iii (189) · cg_sha.iii (187) · cg_opt_rules.iii (185 — trusted-base rule table, also archived into libiii) · cg_typeclass.iii (179) · cg_r3_xii.iii (170) · sema_xii_adapter.iii (147) · xii_ldil.iii (113). The 3800-4500-loc giants are the uniformity exception the criteria allow: they ARE the compiler.
- cg_rm1.iii (31) + cg_rm2.iii (31): **KEEP (facades, verified NOT stubs)** — each routes its ring's public ABI into the shared emit_sanctum engine (SV_MODE flip); the thinness IS the R-1↔R-2 unification.

### 13b. The C seed (iiis-0) — KEEP-FROZEN (bootstrap trust root)

lex.c (2025) · parse.c (3819) · sema.c (1933) · cg_r3.c (3950) · ast.c (2853) · emit.c (913) · link.c (888) · main.c (1315) · acc.c (399) · ceiling.c (175) · sid.c (593) · proof.c (503) · witness_alloc.c (507) · hexad_check.c (432) · jit_emit.c (821) · cg_r0.c (1323) · cg_rm1.c (1162) · cg_rm2.c (1096) · iii_cg_pe_iiis1.c (180) · iiis1_link_stubs.c (89) · rm2_driver.c (21) — plus headers: ast.h (1193) · lex.h (652) · parse.h (365) · jit_emit.h (398) · acc.h (325) · emit.h (250) · sema.h (244) · link.h (238) · cg_rm1.h (214) · cg_rm2.h (209) · hexad_check.h (203) · cg_r3.h (200) · witness_alloc.h (196) · sid.h (164) · cg_r0.h (148) · ast_internal.h (143) · proof.h (118) · ceiling.h (109) · xii_ldil.h (94) · irpd_methods.h (40) · iii_compositions.h (299, generated). Guarded by seed_text_identity_gate.sh + the DDC path. Frozen except byte-equivalence maintenance.

### 13c. Hand-written asm + XII tools + single-source .defs — KEEP

.s: bench_helpers.s (224) · cpuid_helper.s (37) · resolver_hot.s (174) · resolver_unit.s (718) · resolver_unit_avx512.s (665) — all archived by build_stdlib.sh.
XII C tools: gen_trinity_certs.c (188) · gen_xii_anchor_keypair.c (88) · gen_xii_horizons.c (102) · gen_xii_lattice.c (235) · gen_xii_manifest.c (457) · gen_xii_r1.c (105) · sign_xii_manifest.c (111) · verify_xii_manifest.c (50).
.defs (drift-gated single sources): iii_bar_layout.def (38) · iii_census.def (45) · iii_compositions.def (335) · iii_cycle_family.def (41) · iii_ring_lattice.def (37) · iii_svm_layout.def (24) · iii_vmexit.def (36).
Seals/flags: iiis-1.mhash · iiis-2.mhash · iiis-3.mhash · xii_manifest.bin · xii_manifest.mhash.golden · xii_manifest.mhash.presig · xii_anchor_signed.flag. Docs: STAGE1-PORT-INDEX.md (123) · lex_port_audit.md (182).

### 13d. Gates & build scripts — KEEP all 27

build_iiis0.sh (355) · build_iiis0_msvc.sh (71) · build_iiis1.sh (280) · build_iiis2.sh (291) · build_iiis3.sh (253) · build_xii.sh (137) · build_cgsha_kat.sh (21) · cg_r0_crypto_gate.sh (173) · cg_r0_width_gate.sh (98) · cg_seam_gate.sh (87) · check_rm2.sh (35) · emit_gen_diff.sh (40) · forge_check.sh (114) · forge_manifest_keccak.sh (112) · gen_bar_layout.sh (132) · gen_census.sh (134) · gen_compositions.sh (313) · gen_cycle_family.sh (173) · gen_ring_lattice.sh (141) · gen_svm_layout.sh (114) · gen_vmexit.sh (145) · seal_xii_final.sh (143) · seal_xii_horizons.sh (41) · seed_ddc_msvc.sh (66) · seed_text_identity_gate.sh (170) · trusted_base_check.sh (68) · verify_step.sh (154).

### 13e. Compiler-side KATs/fixtures — KEEP

affine_audit.iii (653) · affine_audit_kat.iii (41) · affine_audit_sound.iii (98) · cgsha_kat.iii (52) · forge_keccak_driver.iii (66) · rm_match_sample.iii (14) · rm_str_sample.iii (11) · rm2_sample.iii (42).

### 13f. Subdirectories

ceremonies/ (13 Ω-ceremony .cert artifacts) — **KEEP** (seal chain). opt/ (production_gate.sh · soundness_falsifier.sh · universality_gate.sh) — **KEEP**. cg_r0_gate/ (gprobe.iii · rmain.iii · rprobe.iii) — **KEEP** (r0 gate fixtures). stage1_corpus/ (289 files: sources + golden .s + .witness.json byte-equivalence witnesses) — **KEEP-CRITICAL** (the seed-parity gate corpus); TRIM: the committed `.log` run-logs inside it carry no witness value — delete logs, keep sources + golden outputs.

### 13g. LITTER — DELETE (all verified reference-free in every .sh of BOOT, scripts, sovir)

| files | what they were |
|---|---|
| _gen_cg_rm1_strings.py (242) · _gen_cg_rm2_lits.py (186) · _gen_cg_rm2_strings.py (155) · _gen_rm1_hv.py (215) · r3_clean.py (13) · r3_filter.py (21) · r3_str_gen.py (118) | one-shot r3/rm port-era Python generators; outputs long committed; no-Python lock (S3). **DELETE all 7.** |
| r3_existing.txt (246) · r3_str_consts.frag (216) · r3_str_consts_clean.frag (114) · r3_str_consts_new.frag (128) · survey.txt (70) · r3t1.log (0) | port-era intermediates of the same wave. **DELETE all 6.** |
| _w93_tc_probe.o.s (1996) · _w94_tc.o.s (2042) | stale generated asm probes (June 20). **DELETE.** |
| _create_probe.c (29) · _create_probe2.c (20) · _lexharness.c (34) | session debug probes (June 30 - July 1), unreferenced. **DELETE** (recreate in scratchpad when needed). |
| rm2_sample.iii.sanctum.o.s (37) | committed build output of rm2_sample.iii. **DELETE** (regenerable). |

**COMPILER/BOOT totals: 153 top-level files → 134 KEEP · 19 DELETE · stage1_corpus .log TRIM.**

## 14. STDLIB/scripts — 66 files

**KEEP — the gate spine (56):**
- Build + master gates: build_stdlib.sh · build_studio.sh · run_corpus.sh · fast_check.sh · seal_sources.sh · audit_sovereign.sh · reject_conformance.sh · subsystem_test_gate.sh · affine_audit_gate.sh · cg_optrules_bind_gate.sh · onelang_realtree_gate.sh · onelang_gate.iii · cov_gate_driver.iii (the ratchet computer).
- Family runners: run_xii_corpus.sh · run_xii_antidrift.sh · run_ui_kats.sh · run_field_kats.sh · run_bigcov_kats.sh · run_sqrtsum_kats.sh · run_aether_lens_kats.sh · run_ripple_kats.sh · run_topo_kats.sh (**FIX**: stale "volatile ser_antiunify/ser_petri WIP" note — §8b) · run_bench_corpus.sh · run_autogenesis_corpus.sh · run_nous_corpus.sh.
- Seraphyte reseal chain (9): seraphyte_add_2shift.sh · seraphyte_add_2sub.sh · seraphyte_emit_2shift.sh · seraphyte_emit_2sub.sh · seraphyte_emit_rule.sh · seraphyte_confluence_goldtest.sh · seraphyte_synth_goldtest.sh · seraphyte_reseal_driver.sh · pcc_synthesize.sh.
- Ripple appliers: ripple_apply.sh · ripple_extract.sh.
- Negative static gates (7): test_cap_flow_static_negative.sh · test_cross_fn_pe_negative.sh · test_intent_kind_static_negative.sh · test_k_floor_static_negative.sh · test_module_const_scope.sh · test_return_kind_static_negative.sh · test_type_alias_multihop_negative.sh.
- Verifiers: verify_autogenesis_propose_only.sh · verify_h2_one_address.sh · verify_nous_differential.sh · verify_nous_propose_only.sh · verify_reach_remote.sh · verify_sha256_dedup.sh · nous_export_spines.sh · nous_import_weights.sh.
- Ratchet pins (5): coverage_pin.txt (5) · coverage_gate_pin.txt (2) · coverage_reach_pin.txt (14) · self_model_pin.txt (0) · theorem_floor.txt (0).

**REFACTOR (S8):** ownership of corpus families is encoded twice (run_corpus SKIP cases + each runner's list) — extract ONE ownership manifest both consume.

**DELETE — scratch helpers (4, verified unreferenced):** _affine_audit_measure.sh · _gate_one.sh · _qgate_scan5.sh · _rc_snap.sh.

**Python (finding S3, all 6 outside any build path):**
- gen_self_atlas.py: **DELETE after** the §9 self_atlas_data source-swap to omnia/self_emit (the native replacement exists; execute the swap first).
- self_refactor.py: **DELETE** — superseded by the native ripple organs + ripple_apply.sh.
- emergence_cycle.py + emergence_discover.py: **DELETE** — the emergence loop was folded into native organs (forcefield/nous autogenesis chain); unreferenced.
- fips205_slhdsa_sha2_ref.py + fips205_slhdsa_shake_ref.py: **QUARANTINE out of the sealed tree** — offline FIPS-205 reference-vector generators; their vector outputs are committed in corpus. Keep them in an attic (or regenerate from spec) — not in scripts/.

## 15. Litter, artifacts, and top-level directories

### 15a. STDLIB top-level — 125 underscore litter files: DELETE all (verified: zero references from any gate)

_loop_build1-18.out (18) · _loop_corpus1-11(+8b).out (13) · _wf_discovery_w18-w42.js (25) · _wf_enhance_w1-w10.js (10) · _w1/_w1b/_w2batch/_w2cal/_w2reason/_w3a-c/_w4a-c _build/_corpus.out (~22) · _baseline_build.out · _baseline_corpus.out · _cashin_build.log · _chmaj_build.log · _gf8_build.log · _oneway_build.log · _optform_build.log · _present_build.log · _revio_build.log · _sha_build.log · _weave_build.log · _weave_build1.log · _weave_corpus.log · _wforge_build.log · _wforge2_build.log · _wif_build.log · _wif4_build.log · _fd3.out/.sh · _gate_run.out · _k4gate.out/.sh · _whole.out/.sh · _negproof_1505.sh · _negproof_1506.sh · _verify_1505-1509.sh (5) · _probe_w6.sh · _probe1633.sh — all session probes/logs/Workflow scripts from past waves. Also DELETE the output dirs `STDLIB/_negproof/` (632 generated exe/.o.s) and `STDLIB/_scan/`. KEEP: README.md · III-STDLIB-NATIVE-DESIGN.md · `_quarantine_wip/README.md` (the quarantine anchor, per §12).

### 15b. STDLIB/build — build output tree (mostly fine) with two stale traps

DELETE `STDLIB/build/debug_sha256.c` + `debug_sha256_empty.c` — the wrong-hash debug litter that already misled one audit (prints 7548d587 for SHA256("") — NOT production code). Everything else under STDLIB/build/ is regenerable output; `--clean` covers it.

### 15c. Repo root — 113 untracked items: commit the work, delete the artifacts

- **FIX-COMMIT (S2):** `SEAL.mhash` (the closure seal — decide pin-vs-output: if pinned, commit; if per-build output, emit into build/ + gitignore) · `DOCS/III-STUDIO.md` · `STDLIB/corpus/2169_studio_kernel.iii` · `STDLIB/scripts/build_studio.sh` · the 9 studio modules (§2n) · `STDLIB/build/sovir/` outputs stay untracked.
- **DELETE (regenerable demo/build artifacts, ~85):** aashow.exe · aether_lens{,_exact}.{bmp,png} ·aether_lens_view.exe · aether_lens_win.exe · aether_world.exe · atlas.exe · atlas_check.bmp · bigint.iii.exe.s · fn384.iii.exe.s · build/ (forge_out.o/.s, forge_err.txt — keep `build/_msvcddc/` only while the MSVC-DDC verification is being re-run, else delete too) · color3_env.{exe,gif} · color3_gamutmap.{bmp,exe} · color3_quant.{bmp,exe} · color3_room.{mlog,witness} · curv.exe · destiny.exe · egraph.{bmp,exe} · egraph_demo.exe · egraph_layout.bmp · geocolor_abney/caustic/eidolon/frame/geodesic/lightfield/live_frame/ordered/schrodinger.{bmp,exe,png,gif} (~28) · glass.{bmp,exe} · glass_demo.exe · glass_exact.bmp · and the remaining `??` exe/bmp/png families of the same pattern. **Then add root gitignore patterns** (`/*.exe`, `/*.bmp`, `/*.png`, `/*.gif`, `/*.mlog`, `/*.witness`, `/*.exe.s`) so demo binaries never pollute status again — or better, make demo mains emit into build/.
- **DELETE:** `_audit_scratch/` (119 scratch files).

### 15d. Top-level directories

| dir | verdict |
|---|---|
| COMPILED/ (30) | **KEEP-CRITICAL** — the deployed compiler binaries (iiis-0/1/2 lineage) every gate pins. |
| COMPILER/ | audited in §13. |
| STDLIB/ | audited in §2-§12. |
| DOCS/ (269 md) | **KEEP** (out of per-file scope; recommend a later index-consolidation pass — 269 docs need an INDEX refresh, III-INDEX.md exists). |
| FOUNDERS-ANCHOR/ (7) | **KEEP** — anchor keys/certs (constitutional root). |
| KATABASIS-DEPLOY/ (130) | **KEEP** — the Ring-0 deploy arm (label: gate-resident driver work; M23 Ring-0 arm never auto-run). |
| R2-GENESIS/ (15) | **KEEP** — genesis vector artifacts. |
| TOOLS-QUOTIENT/ | **DELETE the staged duplicates** (2148_theorem_fuzzer.iii, 2149_universal_block.iii, exact_surd_value.iii, kfield.iii — canonical copies live in corpus/ and aether/), **move UNIVERSAL-BLOCK.md → DOCS/** if not already there, and **ADJUDICATE 2274/2276/2277** (meta_involution_orbit, quotient_space_compute, quotient_oracle_orbit — never promoted to corpus; promote with gates or delete as superseded by the landed q23→vg_sign quotient weld). Then remove the dir. |
| build/ (root) | untracked output dir — gitignore; delete stale contents (15c). |
| _audit_scratch/ | **DELETE** (15c). |

## 16. SUMMARY — the whole tree in one table

| domain | files | KEEP | DELETE | REFACTOR | FIX-tagged | notes |
|---|---|---|---|---|---|---|
| aether | 141 | 103 | 11 | 6 | 21 | studio commits + demo-scaffold purge; arc_sweep landed mid-audit |
| eidos | 25 | 25 | 0 | 0 | 1 | orchestrate consumer |
| forcefield | 27 | 24 | 0 | 3 | 0 | capstone-sprawl unify |
| intent | 5 | 5 | 0 | 0 | 0 | |
| katabasis | 22 | 22 | 0 | 0 | 0 | |
| memoria | 5 | 5 | 0 | 0 | 0 | the uniformity benchmark |
| nous | 28 | 28 | 0 | 0 | 1 | ADR-6 wiring |
| numera | 314 | 304 | 0 | 10 | 3 | 5 merge pairs |
| omnia | 157 | 150 | 0 | 6 | 1 | codec-coverage KAT |
| sanctus | 31 | 27 | 0 | 4 | 0 | 2 merge pairs |
| tempora | 6 | 6 | 0 | 0 | 0 | |
| verba | 46 | 46 | 0 | 0 | 1 | nl_parse gate |
| sovir | 77 | 77 | 0 | 0 | 1 | forge63 header |
| sovtc | 54 | 54 | 0 | 0 | 0 | |
| independence | 12 | 12 | 0 | 0 | 0 | |
| corpus | 1763 | 1755 | 0 | 0 | 27 | 19 retargets + 6 topo-dep + 2174/2175 register-and-commit; +5 litter files deleted beside them |
| corpus_reject | 7 | 7 | 0 | 0 | 0 | |
| COMPILER/BOOT | 153 | 134 | 19 | 0 | 0 | python + port-era litter |
| scripts | 66 | 56 | 8 | 1 | 1 | 4 scratch + 4 py deletions, 2 py quarantined |
| STDLIB top litter | 125 | 0 | 125 | 0 | 0 | plus _negproof/, _scan/ output dirs |
| root artifacts | ~113 untracked | — | ~85 | — | ~15 commits | gitignore patterns |

**The five decisive actions, in order of value:**
1. **S1 — restore the ratchets** (uncovered 75→≤5, gates 10→≤2, dark 157→≤14): cover or de-export the new organ families' surfaces (ui_exact debug exports, aether_lens frame/lens window surface, xii_proof tamper hooks via the §9 split, au_*/et_* island exports).
2. **S2 — commit the untracked shipped work** (studio family + SEAL.mhash decision + DOCS/III-STUDIO.md + corpus 2169 + build_studio.sh).
3. **The great litter purge** — 125 STDLIB-top + 19 BOOT + 8 scripts + ~85 root artifacts + TOOLS-QUOTIENT staging + _audit_scratch: ~240 dead files out, zero gate impact (all verified unreferenced).
4. **The 11-file demo-scaffold DELETE in aether** (superseded by studio + gated KATs) + the 12 merge-pair REFACTORs (numera 5, sanctus 2, forcefield 2, omnia 2, aether 1) with their 19 corpus retargets (all named in §12).
5. **The coverage FIXes that unlock unique value**: tp_* route-sweep KAT (16 codecs), ui_morphic + ui_destiny gates, cspace completion, symbolic_regression falsifiers, nl_parse falsifiers, orchestrate consumer, ADR-6 costlin wiring.

## 17. Verification & completeness

- [x] Every stdlib source file (950 = 807 iii + 77 sovir + 54 sovtc + 12 independence) appears in §2-§11 by name; per-section counts sum to the glob counts. **Live-growth caveat:** the tree grew DURING the audit (arc_sweep.iii + KATs 2174/2175 synced in mid-session); the gate was re-run after incorporating them.
- [x] Every corpus KAT (1763) appears in APPENDIX A (generated from the live glob, 1:1, incl. the two mid-audit arrivals) + 7 corpus_reject fixtures named in §12.
- [x] Every COMPILER/BOOT top-level file (153) named in §13a-13g; subdirs at §13f.
- [x] Every scripts/ file (66) named in §14.
- [x] Every DELETE verdict verified reference-free by grep across BOOT/scripts/sovir gates before pronouncement.
- [x] Facts columns (loc/date/build/crefs/callers) machine-extracted from the live tree on 2026-07-01; judgments manual per file.
- [ ] OPEN: one full `build_stdlib.sh && run_corpus.sh` run after executing S1/S2 to confirm ratchets green (not run during this audit — audit is read-only).

---

## APPENDIX A — §12-T full corpus table (file|owner|verdict|extern-subjects|note)

```
01_scalar_u32_add_wrap|CONF|K|scalar|
02_sha256_kat_abc|CONF|K|sha256|
03_region_create_alloc_release|CONF|K|region|
04_span_load_store|CONF|K|region,span|
05_arena_alloc_used|CONF|K|arena|
06_rune_ascii_lower|CONF|K|rune|
07_string_byte_eq|CONF|K|string|
08_builder_push_seal|CONF|K|arena,builder|
09_option_u32_unwrap|CONF|K|option|
10_result_u32_ok_err|CONF|K|result|
11_iter_u8_count|CONF|K|iter|
12_vec_u8_push_at|CONF|K|arena,vec|
13_mhash_domain_separation|CONF|K|mhash|
14_kchain_compose_underflow|CONF|K|kchain|
15_sha256_kat_empty|CONF|K|sha256|
16_hex_encode_roundtrip|CONF|K|hex|
17_string_starts_with|CONF|K|string|
18_rune_utf8_encode_round|CONF|K|rune|
19_vec_u8_max_bound|CONF|K|arena,vec|
20_iter_u8_skip|CONF|K|iter|
21_map_put_get_grow_integrity|CONF|K|arena,map|
22_set_insert_contains_remove|CONF|K|arena,set|
23_queue_fifo_order|CONF|K|arena,queue|
24_pq_min_order|CONF|K|arena,pq|
25_fold_sum_xor_max|CONF|K|fold,iter|
26_zip_count|CONF|K|iter,zip|
27_either_left_right_swap|CONF|K|either|
28_checked_overflow|CONF|K|checked|
29_modular_pow|CONF|K|modular|
30_fixed_q32_arithmetic|CONF|K|fixed|
31_q128_add_shift|CONF|K|q128|
32_parse_decimal|CONF|K|parse|
33_bigint_mul_add|CONF|K|arena,bigint|
34_format_decimal_hex|CONF|K|arena,builder,format|
35_regex_basic|CONF|K|regex|
36_capability_attenuate_revoke|CONF|K|capability|
37_handle_open_close|CONF|K|capability,handle|
38_fs_write_read_roundtrip|CONF|K|capability,fs|
39_instant_now_seal_verify|CONF|K|capability,instant|
40_duration_arithmetic|CONF|K|duration|
41_deadline_check|CONF|K|capability,deadline,instant|
42_witness_chain_verify|CONF|K|witness|
43_attest_self_nonce|CONF|K|attest,capability,witness|
44_crystal_mint_verify|CONF|K|crystal|
45_mandate_audit_full|CONF|K|closure,kchain,mandate,pattern_table|
46_closure_set_verify|CONF|K|closure|
47_bigint_div_u64|CONF|K|arena,bigint,bigint_div|
48_bigint_div_qr|CONF|K|arena,bigint,bigint_div|
49_field_fp_arithmetic|CONF|K|arena,bigint,field|
50_normalise_ascii|CONF|K|normalise_ascii|
51_net_pack_sockaddr|CONF|K|net|
52_json_parse_primitives|CONF|K|arena,json|
53_json_parse_compound|CONF|K|arena,json|
54_json_roundtrip|CONF|K|arena,builder,json|
55_sha512_kat_abc|CONF|K|sha512|
56_sha512_kat_empty|CONF|K|sha512|
57_http_parse_content_length|CONF|K|arena,http_client|
58_http_parse_chunked|CONF|K|arena,http_client|
59_ed25519_rfc8032_test1|CONF|K|crypt_ed25519|
60_aes128_fips197_kat|CONF|K|aes|
61_aes128_decrypt_roundtrip|CONF|K|aes|
62_aes_gcm_nist_test2_seal|CONF|K|aes_gcm|
63_aes_gcm_open_roundtrip|CONF|K|aes_gcm|
64_http_parse_request|CONF|K|arena,http_server|
65_http_send_response|CONF|K|arena,builder,http_server|
66_uri_parse|CONF|K|arena,uri|
67_uri_pct_encode_decode|CONF|K|arena,builder,uri|
68_aes256_fips197_kat|CONF|K|aes|
69_aes256_gcm_nist_test14|CONF|K|aes_gcm|
70_chacha20_block_kat|CONF|K|chacha20|
71_poly1305_rfc8439_kat|CONF|K|poly1305|
72_chacha20_poly1305_aead_rfc8439|CONF|K|chacha20_poly1305|
73_x25519_rfc7748_test1|CONF|K|x25519|
74_ed25519_rfc8032_test2|CONF|K|crypt_ed25519|
75_ed25519_rfc8032_test3|CONF|K|crypt_ed25519|
76_bigint_normalize|CONF|K|arena,bigint|
77_arena_reset|CONF|K|arena|
78_normalise_nfd_nfc|CONF|K|arena,builder,normalise|
79_hmac_sha256_rfc4231|CONF|K|hmac|
80_base64_round_trip|CONF|K|arena,base64,builder|
81_hkdf_sha256_rfc5869|CONF|K|hkdf|
82_crc32_kat|CONF|K|crc32|
83_blake2s_kat|CONF|K|blake2s|
84_xoshiro_determinism|CONF|K|xoshiro|
85_ini_parse|CONF|K|arena,ini|
86_pbkdf2_sha256_rfc7914|CONF|K|pbkdf2|
87_uuid_v4_format|CONF|K|uuid,xoshiro|
88_murmur3_kat|CONF|K|murmur3|
89_leb128|CONF|K|leb128|
90_gcm_ghash_pclmul_bitident|CONF|K|aes_gcm|
91_csv_parse|CONF|K|arena,csv|
92_base32_kat|CONF|K|arena,base32,builder|
93_ulid_format|CONF|K|ulid,xoshiro|
94_calendar_round_trip|CONF|K|calendar|
95_rfc3339|CONF|K|rfc3339|
96_timing_safe_eq|CONF|K|timing_safe|
97_endian|CONF|K|endian|
98_path|CONF|K|arena,builder,path|
99_html_escape|CONF|K|arena,builder,html_escape|
100_quality_gate_aggregate|CONF|K-RETARGET|kchain,pattern_table,quality,quality_q7|quality_q7
101_sid_direct_graph|CONF|K|arena,crystal,crystal_deps,vec|
102_sid_transitive_closure|CONF|K|arena,crystal,crystal_deps,vec|
103_sid_visualize_utf8|CONF|K|arena,crystal,crystal_deps,vec|
104_modifier_crystal|CONF|K||
105_crystal_edges_baseline|CONF|K|arena,crystal|
106_modifier_dynamic|CONF|K||
107_modifier_sealed|CONF|K||
108_modifier_linear|CONF|K||
109_modifier_bounded|CONF|K||
110_modifier_variant|CONF|K||
111_modifier_k|CONF|K||
112_modifier_provenance|CONF|K||
113_modifier_constant_time|CONF|K||
114_modifier_side_channel_resistant|CONF|K||
115_modifier_dynamic_impact|CONF|K||
116_modifier_provenance_linked_error|CONF|K||
117_modifier_arena_reset_safe|CONF|K||
118_modifier_crystal_self_attest|CONF|K||
119_ripple_analyze_baseline|CONF|K|arena,crystal,ripple|
120_ripple_execute_strict|CONF|K|arena,crystal,ripple,witness|
121_arena_region_reset_safe|CONF|K|arena,region|
122_stress_arena_1k_resets|CONF|K|arena|
123_consumer_hello_arena|CONF|K|arena|
125_bitops|CONF|K|bitops|
126_inet_ipv4|CONF|K|arena,builder,inet|
127_semver|CONF|K|semver|
128_glob|CONF|K|glob|
128_self_host_ripple|CONF|K|arena,crystal,dynamic_impact,dynamic_record|
129_list|CONF|K|arena,list|
130_lru|CONF|K|arena,lru|
131_field_inv_crystal|CONF|K|arena,bigint,crystal,field_crystal|
132_lru_debug_isolate|CONF|K|arena,lru|
133_arena_only|CONF|K|arena|
134_lru_new_only|CONF|K|arena,lru|
135_lru_capacity|CONF|K|arena,lru|
136_lru_put_one|CONF|K|arena,lru|
137_lru_put_three|CONF|K|arena,lru|
138_lru_put_evict|CONF|K|arena,lru|
139_lru_just_evict|CONF|K|arena,lru|
140_modifier_strict_length|CONF|K||
141_http_isolate|CONF|K|arena,http_client|
142_http_header_find|CONF|K|arena,http_client|
143_bigint_karatsuba|CONF|K|arena,bigint,bigint_karatsuba|
144_q128_to_f64|CONF|K|q128,q128_f64|
145_checked_crystal|CONF|K|checked_crystal,crystal|
146_modular_mont|CONF|K|modular_mont|
147_fixed_extra|CONF|K|fixed_extra|
148_scalar_provenance|CONF|K|crystal,scalar_provenance|
149_cpufeat_dispatch|CONF|K|cpufeat,sha256,sha256_dispatch|
150_cpufeat_only|CONF|K|cpufeat|
151_sha256_dispatch_kat|CONF|K|sha256,sha256_dispatch|
152_dispatch_only|CONF|K|sha256_dispatch|
153_crystal_http_header|CONF|K|http|
154_async_runtime_basic|CONF|K|arena,async,vec|
155_sha3_256_kat_abc|CONF|K|sha3_256|
156_sha3_512_kat_abc|CONF|K|sha3_512|
157_shake128_kat_empty|CONF|K|shake128|
158_shake256_kat_empty|CONF|K|shake256|
159_fed_tier_basic|CONF|K|fed_tier|
160_fed_sybil_pow|CONF|K|fed_sybil|
161_fed_eclipse_basic|CONF|K|fed_eclipse,fed_sybil|
162_sha3_diag|CONF|K|sha3_512|
163_fed_admit_gates|CONF|K|fed_admit,fed_eclipse,fed_sybil|
164_fed_genesis_descent|CONF|K|fed_genesis,sha256|
165_fed_seal_anchor|CONF|K|fed_seal|
166_sandbox_lifecycle|CONF|K|sandbox_ctor,sandbox_exec,sandbox_quota|
167_merkle_basic|CONF|K|merkle|
168_keccak_zero|CONF|K|keccak|
169_sha3_256_empty|CONF|K|sha3_256|
170_obs_log_basic|CONF|K|obs_log|
171_obs_metric_kinds|CONF|K|obs_metric|
172_obs_trace_tree|CONF|K|obs_trace|
173_obs_observatory_collapse|CONF|K|obs_observatory|
174_catalyst_gates|CONF|K|catalyst|
175_genesis_distance|CONF|K|genesis|
176_promote_demote_lifecycle|CONF|K|catalyst,demote,promote|
177_glyph_v3_roundtrip|CONF|K|glyph_bytes,glyph_core,glyph_crystal,glyph_f64|
178_glyph_v3_remainder|CONF|K|glyph_core,glyph_enum,glyph_map,glyph_proof|
179_dynamic_ripple_stub|CONF|K|ripple|
180_poly1305_scalar_avx512_bitident|CONF|K|poly1305|
181_keccak_chi_scalar_avx512_bitident|CONF|K|keccak|
182_bigint_mul_scalar_avx512_bitident|CONF|K|arena,bigint|
183_x25519_ed25519_field_bigint_bitident|CONF|K|x25519|
184_sha256_sched_scalar_avx512_bitident|CONF|K|sha256|
185_sha512_sched_scalar_avx512_bitident|CONF|K|sha512|
186_signed_i64_ordering|CONF|K||
187_u32_pointer_store_width|CONF|K||
188_multiline_fn_decl|CONF|K||
189_emdash_block_comment|CONF|K||
190_nested_block_comment|CONF|K||
191_local_var_array|CONF|K||
192_module_const_local|CONF|K||
193_ed25519_sign_rfc8032_test1|CONF|K|crypt_ed25519|
194_ed25519_verify_tamper|CONF|K|crypt_ed25519|
195_ed25519_sign_rfc8032_test2|CONF|K|crypt_ed25519|
196_ed25519_sign_rfc8032_test3|CONF|K|crypt_ed25519|
197_ed25519_sign_long_message|CONF|K|crypt_ed25519|
198_mldsa_roundtrip|CONF|K|mldsa|
199_mlkem_roundtrip|CONF|K|mlkem|
200_calculus_18_primitives|CONF|K|calculus_v1,intent,irreducibility_proof,resolution_init|
200_slhdsa_roundtrip|CONF|K|slhdsa|
201_lazy_crystal_levels|CONF|K|call_context,crystal,mini_crystal,resolver|
201_pq_dispatch|CONF|K|pq_dispatch|
202_aes192_kat|CONF|K|aes|
202_memo_determinism|CONF|K|resolver_memo|
203_hmac_sha512_rfc4231|CONF|K|hmac|
203_jit_fuse_amortized|CONF|K|jit_fuse|
204_drbg_sp80090a|CONF|K|drbg|
204_prespec_hw_offload|CONF|K|hw_offload,prespec|
205_drbg_hw_entropy|CONF|K|cpufeat,drbg|
205_governance_full_loop|CONF|K|governance,resolution_init|
206_observe_and_propose|CONF|K|governance,resolution_init|
206_xchacha20_poly1305|CONF|K|chacha20,xchacha20_poly1305|
207_aes_siv_rfc5297|CONF|K|aes_siv|
207_babel_wire_roundtrip|CONF|K|babel_wire|
208_cap_handshake|CONF|K|cap_handshake|
208_ecdsa_p256|CONF|K|ecdsa_p256|
209_ecdsa_p384|CONF|K|ecdsa_p384|
209_idoc_roundtrip|CONF|K|babel_wire,idoc|
210_sealed_channel_handshake|CONF|K|sealed_channel,x25519|
211_hip_resolve|CONF|K|hip|
212_hip_verb_coverage|CONF|K|hip|
213_reflect_introspection|CONF|K|calculus_v1,resolution_init,resolver|
214_hip_intent_validation|CONF|K|hip,intent|
215_sealed_channel_session_id|CONF|K|sealed_channel,x25519|
216_proof_ripple_equiv|CONF|K|proof_ripple_resolution|
217_e2e_hip_idoc|CONF|K|babel_wire,hip,idoc,intent|
218_prespec_compositions|CONF|K|prespec|
219_witness_chain|CONF|K|witness|
220_hip_concurrency|CONF|K|hip|
221_hip_punctuation|CONF|K|hip|
222_babel_wire_tamper|CONF|K|babel_wire|
223_mini_crystal_lifecycle|CONF|K|mini_crystal|
224_hip_interrogative|CONF|K|hip,intent|
225_sealed_channel_multimsg|CONF|K|sealed_channel,x25519|
226_intent_composition|CONF|K|intent,resolution_init|
227_calculus_metadata|CONF|K|calculus_v1|
228_idoc_multi_consumer|CONF|K|babel_wire,idoc|
229_governance_no_autoproposal|CONF|K|governance,resolution_init|
230_memo_content_addressing|CONF|K|resolver_memo|
231_calculus_idempotence|CONF|K|calculus_v1|
232_pe_static_zero_overhead|CONF|K|call_context,intent,pattern_table,resolver|
233_resolver_unit_dispatch|CONF|K|call_context,intent,pattern_table,resolution_init|
234_compositions_ssot_drift|CONF|K|aes,arena,blake2s,chacha20|
235_resolver_unit_avx2_parity|CONF|K|call_context,intent,pattern_table,resolution_init|
236_idsg_abstract_reflect|CONF|K|calculus_v1,intent,resolver|
237_insel_cycle_bench|BENCH|K|call_context,cpufeat,intent,pattern_table|
238_resolver_unit_avx512_parity|CONF|ORPHAN-REF|_unused,calculus_v1,call_context,cpufeat|MISSING:_unused
239_fed_multi_node_mesh|CONF|K|sealed_channel,x25519|
240_fed_e2e_admit_ceremony|CONF|K|calculus_v1,fed_admit,fed_eclipse,fed_genesis|
241_hip2_complex_sentences|CONF|K|hip,nl_lex|
242_bench_resolver|BENCH|ORPHAN-REF|_unused,bench,call_context,cpufeat|MISSING:_unused
243_bench_sealed_channel|BENCH|K|bench,sealed_channel,x25519|
244_bench_hip_idoc|BENCH|K|babel_wire,bench,hip,idoc|
245_self_reformatter|CONF|K|resolution_init,self_reformatter|
246_ai_resolve|CONF|K|ai_resolve,hip,resolution_init|
247_first_domain_pattern_set|CONF|K|fed_seal,pattern_set_federation,sha256|
248_signed_compare|CONF|K||
249_u32_indexed_access|CONF|K||
250_multiline_fn|CONF|K||
251_newline_else|CONF|K||
252_nested_comments|CONF|K||
253_hex_underscores|CONF|K||
254_mut_param|CONF|K||
255_let_discard|CONF|K||
256_local_arrays|CONF|K||
257_iiis1_fn_annotations|CONF|K||
258_iiis1_param_annotations|CONF|K||
259_cap_required|CONF|K|call_context,capability,kchain|
260_k_max|CONF|K|call_context,capability,kchain|
261_hexad_kind|CONF|K|call_context,kchain|
262_cap_flow_static|CONF|K|call_context,capability,kchain|
262_neg_cap_flow|NEG|K||
263_intent_kind_static|CONF|K||
263_neg_intent_kind|NEG|K||
264_k_floor_static|CONF|K|call_context,kchain|
264_neg_k_floor|NEG|K||
265_neg_return_kind|NEG|K||
265_return_kind_static|CONF|K||
266_all_rules_combined|CONF|K|call_context,capability,kchain|
267_call_arg_cross_check|CONF|K||
267_neg_call_arg|NEG|K||
268_iiis2_loop_break_continue|CONF|K||
269_iiis2_type_alias|CONF|K||
269_neg_type_alias|NEG|K||
270_substrate_integration|CONF|K|call_context,capability,kchain|
271_nested_call_chain|CONF|K||
272_cross_fn_pe|CONF|K|call_context,intent,pattern_table,resolver|
273_cross_fn_dynamic_intent|CONF|K|call_context,intent,pattern_table,resolver|
274_type_alias_multihop|CONF|K||
275_neg_type_alias_multihop|NEG|K||
276_let_mut_checkpoint_flag|CONF|K||
277_arg5_param_spill|CONF|K||
278_addr_of_index_paren|CONF|K||
279_addr_of_index_bare|CONF|K||
280_xii_K01_form|XII|K|xii_basis,xii_term|
281_xii_K02_bind|XII|K|xii_basis,xii_term|
282_xii_K03_convey|XII|K|xii_basis,xii_term|
283_xii_K04_mean|XII|K|xii_basis,xii_term|
284_xii_K05_act|XII|K|xii_basis,xii_term|
285_xii_K06_compose|XII|K|xii_basis,xii_term|
286_xii_K07_seal|XII|K|xii_basis,xii_term|
287_xii_K08_prove|XII|K|xii_basis,xii_term|
288_xii_K09_query|XII|K|xii_basis,xii_term|
289_xii_K10_grant|XII|K|xii_basis,xii_term|
290_xii_K11_govern|XII|K|xii_basis,xii_term|
291_xii_K12_then|XII|K|xii_basis,xii_term|
292_xii_K13_with|XII|K|xii_basis,xii_term|
293_xii_K14_under|XII|K|xii_basis,xii_term|
294_xii_K15_if|XII|K|xii_basis,xii_term|
295_xii_K16_loop|XII|K|xii_basis,xii_term|
296_xii_K17_lift|XII|K|xii_basis,xii_term|
297_xii_K18_reflect|XII|K|xii_basis,xii_term|
298_xii_FCOMPOSE|XII|K|xii_term|
299_bit_identity_probe|XII|K|arena|
299_xii_FTHEN|XII|K|xii_term|
300_xii_FWITH|XII|K|xii_term|
301_xii_FUNDER|XII|K|xii_term|
302_xii_FIF|XII|K|xii_term|
303_xii_FLOOP|XII|K|xii_term|
304_xii_R001|XII|K|xii_rewrite,xii_term|
305_xii_R002|XII|K|xii_rewrite,xii_term|
306_xii_R003|XII|K|xii_rewrite,xii_term|
307_xii_R004|XII|K|xii_rewrite,xii_term|
308_xii_R005|XII|K|xii_rewrite,xii_term|
309_xii_R013|XII|K|xii_rewrite,xii_term|
310_xii_R014|XII|K|xii_rewrite,xii_term|
311_xii_R016|XII|K|xii_rewrite,xii_term|
312_xii_R017|XII|K|xii_rewrite,xii_term|
313_xii_R018|XII|K|xii_rewrite,xii_term|
314_xii_R019|XII|K|xii_rewrite,xii_term|
315_xii_R020|XII|K|xii_rewrite,xii_term|
316_xii_R023|XII|K|xii_rewrite,xii_term|
317_xii_R024|XII|K|xii_rewrite,xii_term|
318_xii_R025|XII|K|xii_rewrite,xii_term|
319_xii_R026|XII|K|xii_rewrite,xii_term|
320_xii_R027|XII|K|xii_rewrite,xii_term|
321_xii_R030|XII|K|xii_rewrite,xii_term|
322_xii_R031|XII|K|xii_rewrite,xii_term|
323_xii_R032|XII|K|xii_rewrite,xii_term|
324_xii_R006|XII|K|xii_rewrite,xii_term|
325_xii_R007|XII|K|xii_rewrite,xii_term|
326_xii_R008|XII|K|xii_rewrite,xii_term|
327_xii_R009|XII|K|xii_rewrite,xii_term|
328_xii_R010|XII|K|xii_rewrite,xii_term|
329_xii_R011|XII|K|xii_rewrite,xii_term|
330_xii_R012|XII|K|xii_rewrite,xii_term|
331_xii_R015|XII|K|xii_rewrite,xii_term|
332_xii_R021|XII|K|xii_rewrite,xii_term|
333_xii_R022|XII|K|xii_rewrite,xii_term|
334_xii_R028|XII|K|xii_rewrite,xii_term|
335_xii_R029|XII|K|xii_rewrite,xii_term|
336_xii_R033|XII|K|xii_rewrite,xii_term|
337_xii_R034|XII|K|xii_rewrite,xii_term|
338_xii_R035|XII|K|xii_rewrite,xii_term|
339_xii_R036|XII|K|xii_rewrite,xii_term|
340_xii_R037|XII|K|xii_rewrite,xii_term|
341_xii_R038|XII|K|xii_rewrite,xii_term|
342_xii_R039|XII|K|xii_rewrite,xii_term|
343_xii_R040|XII|K|xii_rewrite,xii_term|
344_xii_R042|XII|K|xii_rewrite,xii_term|
345_xii_conf_hj_assoc|XII|K|xii_hj|
346_xii_conf_hj_commut|XII|K|xii_hj|
347_xii_conf_dk_symm|XII|K|xii_savings|
348_xii_conf_canon_idemp|XII|K|xii_canonicalise,xii_rewrite,xii_term|
349_xii_term_terminates|XII|K|xii_canonicalise,xii_term|
350_xii_term_term_loop|XII|K|xii_canonicalise,xii_term|
351_xii_term_term_mixed|XII|K|xii_canonicalise,xii_rewrite,xii_term|
352_xii_lattice_replay_avx2|XII|K|xii_emit_gen,xii_horizon|
353_xii_lattice_replay_arm|XII|K|xii_emit_gen,xii_horizon|
354_xii_lattice_replay_riscv|XII|K|xii_emit_gen,xii_horizon|
355_xii_mphf_construct|XII|K|xii_chd|
356_xii_mphf_lookup|XII|K|xii_chd|
357_xii_horizon_reach|XII|K|xii_horizon_reach|
358_xii_sml_anti_tamper|XII|K|sha256|
359_xii_ldil_determinism|XII|K|xii_emit_gen,xii_horizon|
360_xii_e2e_demo|XII|K|xii_canonicalise,xii_emit_gen,xii_horizon,xii_term|
361_xii_curated_crypto|XII|K|xii_emit_gen,xii_horizon,xii_kernel_emit,xii_register_all|
362_xii_sml_full_chain|XII|K|sha256,xii_sml|
363_xii_atm_tamper|XII|K|sha256,xii_atm|
364_xii_horizon_metadata|XII|K|xii_horizon|
365_xii_anchor_invariant|XII|K|anchor_xii,xii_horizon|
366_xii_circ_feasibility|XII|K|xii_circ|
367_xii_full_pipeline|XII|K|sha256,xii_atm,xii_canonicalise,xii_emit_gen|
368_xii_curated_riscv|XII|K|xii_emit_gen,xii_horizon,xii_kernel_emit,xii_register_all|
369_xii_curated_embedded|XII|K|xii_emit_gen,xii_register_all|
370_xii_kernel_emit|XII|K|xii_kernel_emit|
372_xii_antidrift_full|XII|K|sha256,xii_antidrift,xii_chd,xii_horizon|
373_rsa_pss_sign_verify|CONF|K|arena,rsa|
374_zk_field_bls12381|CONF|K|zk_field|
375_zk_snark_groth16|CONF|K|zk_snark|
376_zk_stark_fri|CONF|K|zk_stark|
377_zk_prune_rollup|CONF|K|zk_prune|
378_keccak256_wrapper|CONF|K|keccak256|
379_identifier|CONF|K|identifier|
381_algebraic_time|CONF|K|algebraic_time|
382_witness_hook|CONF|K|witness_hook|
383_hotstuff|CONF|K|hotstuff|
384_hotstuff_predict|CONF|K-RETARGET|hotstuff_predict|hotstuff_predict
386_fed_qc_gate|CONF|K|crypt_ed25519,fed_seal,hotstuff|
387_net_server_loopback|CONF|K|capability,net|
388_fe25519_ed|CONF|K|fe25519,sha512|
389_hexad_subsystem|CONF|K|hexad|
390_katabasis_svm_hexad|CONF|K|svm_layout|
391_katabasis_cycle_dominance|CONF|K|hexad_pfs,svm_layout|
392_katabasis_cycle_family|CONF|K|cycle_family|
393_specialize|CONF|K|spec_probe|
394_katabasis_bar_typing|CONF|K|bar_layout|
394_option_specialize|CONF|K|option|
395_katabasis_cycle_admit|CONF|K|cycle_admit|
395_result_specialize|CONF|K|result|
396_span_specialize|CONF|K|span|
397_iter_specialize|CONF|K|iter,span|
398_vec_specialize|CONF|K|arena,vec|
410_xii_chd_bucket_bounds|CONF|K|xii_chd|
411_xii_audit_record_count_bound|CONF|K|xii_antidrift,xii_sml|
412_babel_wire_len_overflow|CONF|K|babel_wire|
413_rsa_sign_pool_exhaustion|CONF|K|arena,bigint,rsa|
414_builder_oom_latch|CONF|K|arena,builder|
415_sovereign_witness_artifact|CONF|K|arena,cad,legacy_artifact|
416_sovereign_witness_affine|CONF|K|arena,legacy_artifact,sovereign_witness|
417_sovereign_witness_replay|CONF|K|arena,cad,legacy_artifact,sovereign_witness|
418_sovereign_witness_align|CONF|K|sovereign_witness|
419_self_witness_iii_contracts|CONF|K|sovereign_witness|
420_fed_qc_len_guard|CONF|K|fed_seal|
421_idoc_pack_outcap|CONF|K|idoc|
600_katabasis_vmexit|CONF|K|vmexit|
601_katabasis_ring_lattice|CONF|K|ring_lattice|
602_katabasis_gate_verdict|CONF|K|gate_verdict|
603_katabasis_census|CONF|K|cad,census|
604_katabasis_bricking|CONF|K|bricking|
605_katabasis_cycle_term|CONF|K|cycle_term,xii_term|
606_katabasis_gate|CONF|K|cycle_term,gate,xii_term|
607_katabasis_seal|CONF|K|cad,cycle_term,seal,xii_term|
608_katabasis_caps|CONF|K|capability,caps|
609_katabasis_admit|CONF|K|admit,capability,cycle_term,seal|
610_rev_invoke|CONF|K|rev_invoke|
611_tiebreak|CONF|K|tiebreak|
612_galois|CONF|K|galois|
613_sat|CONF|K|sat|
614_egraph|CONF|K|egraph|
615_cost_lattice|CONF|K|cost_lattice|
616_microarch_model|CONF|K|microarch_model|
617_quine_verifier|CONF|K|quine_verifier|
618_entropy_monitor|CONF|K|entropy_monitor|
619_curry_howard|CONF|K|curry_howard|
620_category|CONF|K|category|
621_sheaf|CONF|K|sheaf|
622_manifest|CONF|K|manifest|
623_quarantine|CONF|K|quarantine|
624_node_identity|CONF|K|node_identity|
625_snapshot_lattice|CONF|K|snapshot_lattice|
626_topology_atlas|CONF|K|topology_atlas|
627_cap_forge|CONF|K|cap_forge|
628_xii_ldil|CONF|K|xii_ldil|
629_triple_check|CONF|K|triple_check|
630_context_awareness|CONF|K|context_awareness|
631_symbolic_regression|CONF|K|symbolic_regression|
632_constitution|CONF|K|constitution|
633_witness_spine|CONF|K|witness_spine|
634_reversible|CONF|K|reversible|
635_smt|CONF|K|smt|
636_proof_term|CONF|K|proof_term|
637_sat_at_scale|CONF|K|sat_at_scale|
638_groebner|CONF|K|groebner|
639_proof_carrying|CONF|K|proof_carrying|
640_cost_calculus|CONF|K|cost_calculus|
641_bone_marrow|CONF|K|bone_marrow|
642_cost_lattice_synth|CONF|K|cost_lattice_synth|
643_basal_probe|CONF|K|basal_probe|
644_temporal_logic|CONF|K|temporal_logic|
645_computation_graph|CONF|K|computation_graph|
646_memo_lattice|CONF|K|memo_lattice|
647_theorem_carrier|CONF|K|theorem_carrier|
648_synthesis_spec|CONF|K|synthesis_spec|
649_reversibility_audit|CONF|K|reversibility_audit|
650_branch_anchor|CONF|K|branch_anchor|
651_branch_governance|CONF|K|branch_governance|
652_math_library|CONF|K|math_library|
653_math_library_curation|CONF|K|math_library_curation|
654_memo_query|CONF|K|memo_query|
655_constitution_preserver|CONF|K|constitution_preserver|
656_bisimulation_witness|CONF|K|bisimulation_witness|
657_witness_compactor|CONF|K|witness_compactor|
658_distress_witness|CONF|K|distress_witness|
659_cost_overrun_handler|CONF|K|cost_overrun_handler|
660_firmware_quarantine|CONF|K|firmware_quarantine|
661_shape_negotiator|CONF|K|shape_negotiator|
662_memo_compactor_coordination|CONF|K|memo_compactor_coordination|
663_reflection_constrained|CONF|K|reflection_constrained|
664_reflection_governance|CONF|K|reflection_governance|
665_cad|CONF|K|cad|
666_trit|CONF|K|trit|
667_hexad_reach|CONF|K|hexad_reach|
668_uncertainty|CONF|K|uncertainty|
669_sovval|CONF|K|sovval|
671_hexad_mobius|CONF|K|hexad_mobius|
672_safety_type|CONF|K|safety_type|
673_constitution_holds|CONF|K|constitution|
674_h2_charter|CONF|K|h2_charter|
675_decision_oracle|CONF|K|smt|
676_cat_laws|CONF|K|category|
677_cost_lattice_laws|CONF|K|cost_lattice|
678_memo_soundness|CONF|K|constitution,memo_lattice,witness_hook,witness_spine|
679_synthesis_bounds|CONF|K|synthesis_spec|
680_proof_chain|CONF|K|algebraic_time,proof_term,theorem_carrier|
681_transform_iso|CONF|K|tp_ast_bin_to_iii,tp_iii_to_ast_bin|
682_arena_determinism|CONF|K|arena,region|
683_unify|CONF|K|arena,unify|
684_crystal_seal|CONF|K|crystal|
685_observatory_sealed|CONF|K|obs_observatory|
686_quota_append_only|CONF|K|sandbox_ctor,sandbox_exec,sandbox_quota|
687_membrane_cap_gate|CONF|K|capability,fs,handle|
688_h1_charter|CONF|K|h1_charter|
689_h3_charter|CONF|K|h3_charter|
690_h8_charter|CONF|K|h8_charter|
691_h10_charter|CONF|K|h10_charter|
692_h6_charter|CONF|K|h6_charter|
693_h9_charter|CONF|K|h9_charter|
694_h11_charter|CONF|K|h11_charter|
695_h4_charter|CONF|K|h4_charter|
696_h5_charter|CONF|K|h5_charter|
697_h7_charter|CONF|K|h7_charter|
698_h12_charter|CONF|K|h12_charter|
699_h13_charter|CONF|K|h13_charter|
700_charter_terminal|CONF|K|charter_terminal|
701_cons_run_charter|CONF|K|constitution|
702_cat_laws_charter|CONF|K|category|
703_rev_compromise_charter|CONF|K|reversible|
704_sovval_boundary_type|CONF|K|sovval|
705_bound_selftest|CONF|K|bound|
706_http_chunk_wrap|CONF|K|arena,http_client|
707_pq_cap_wrap|CONF|K|arena,pq|
708_option_full_distinct|CONF|K|option|
709_reach_oracle_null_pin|CONF|K|reach_oracle|
710_base32_sealed_builder|CONF|K|arena,base32,builder|
711_format_sealed_builder|CONF|K|arena,builder,format|
711_sovereign_neg|NEG|K||
712_sovereign_pos|CONF|K||
713_inet_sealed_builder|CONF|K|arena,builder,inet|
713_sovflow_neg|NEG|K||
714_async_id_alias|CONF|K|arena,async|
714_sovflow_pos|CONF|K||
715_sovout_neg|NEG|K||
716_sovout_pos|CONF|K||
717_sovout_chain_neg|NEG|K||
718_sovsink_pos|CONF|K||
720_caindex|CONF|K|caindex|
721_tiebreak_leaves|CONF|K|tiebreak|
722_ntt|CONF|K|ntt|
723_ntt_convolve|CONF|K|ntt|
724_ntt_bigint|CONF|K|ntt_bigint|
725_bigint_large_route|CONF|K|arena,bigint,bigint_karatsuba|
726_ntt_stage|CONF|K|modular,ntt|
754_cg_anchor_caindex|CONF|K|algebraic_time,computation_graph,constitution,witness_hook|
755_ripple_sep_grouping|CONF|K|ripple_metric|
756_ripple_loop_grouping|CONF|K|congruence,ripple_loop,ripple_metric|
757_bigint_knuth_div|CONF|K|arena,bigint,bigint_div|
758_mont_ctx_organ|CONF|K|arena,bigint,bigint_div|
759_mont_bigint_width|CONF|K|arena,bigint,bigint_div|
760_field_mont_organ|CONF|K|arena,bigint,bigint_div,fp256|
761_buffer_bound_falsifier|CONF|K|aes_siv,arena,drbg|
762_merkle_keccak_suite|CONF|K|keccak256,merkle|
763_tempaloc_mistype|CONF|K|tempaloc|
764_arena_reset_witness|CONF|K|arena|
765_seal_organ|CONF|K|capability,seal_organ|
766_pq_params|CONF|K|pq_params|
767_ntt_ctx|CONF|K|ntt_ctx|
768_keccak_sponge|CONF|K|keccak_sponge,keccak256|
769_pq_sealed_abi|CONF|K|mldsa|
770_slhdsa_shake_fips205|CONF|K|sha256,slhdsa|
771_slhdsa_sha2_fips205|CONF|K|sha256,slhdsa|
772_map_full_table_sentinel|CONF|K|arena,map|
800_nous_socket|CONF|K|nous_socket,xii_canonicalise,xii_rewrite,xii_term|
801_nous_costlin|CONF|K|nous_costlin|
802_nous_search|CONF|K|nous_search|
803_nous_charter|CONF|K|nous_charter|
804_nous_policy|CONF|K|nous_features,nous_policy,nous_socket,nous_value|
805_nous_completion|CONF|K|nous_completion|
806_nous_commons|CONF|K|nous_commons|
807_nous_train|CONF|K|nous_train|
808_nous_synth|CONF|K|nous_synth|
809_nous_behavioral_key|CONF|K|nous_behavioral_key|
810_xii_rule_patterns|CONF|K|xii_rule_patterns|
811_xii_rule_overlap|CONF|K|xii_rule_overlap|
812_xii_critpair_enum|CONF|K|xii_critpair_enum|
813_xii_joinability|CONF|K|xii_joinability|
814_xii_termination|CONF|K|xii_termination|
815_xii_admission|CONF|K|xii_admission|
816_xii_lower_compose|CONF|K|xii_lower_compose|
817_xii_lower_decide|CONF|K|xii_lower_decide|
818_xii_lower_iterate|CONF|K|xii_lower_iterate|
819_xii_lower_program|CONF|K|xii_lower_program|
820_xii_mig4_seal|CONF|K|xii_mig4_seal|
821_xii_lower_then|CONF|K|xii_lower_then|
822_xii_lower_with|CONF|K|xii_lower_with|
823_xii_lower_under|CONF|K|xii_lower_under|
824_xii_strategy_det|CONF|K|xii_strategy_det|
825_xii_discharge|CONF|K|xii_discharge|
826_xii_conf_cert|CONF|K|xii_conf_cert|
827_reach_spine|CONF|K|cad,capability,fs,reach_core|
828_reach_memo|CONF|K|backend_memo,cad,capability,fs|
829_reach_remote|CONF|K|backend_remote,cad,capability,fs|
830_reach_oracle|CONF|K|reach_oracle|
831_reach_ipc|CONF|K|backend_ipc,cad,capability,fs|
832_reach_loopback|CONF|K|backend_loopback,cad,capability,fs|
833_markup|CONF|K|markup|
834_ripple_field|CONF|K|ripple_field|
835_self_reformatter_directed|CONF|K|resolution_init,self_reformatter|
836_forcefield_pleroma|CONF|K|pleroma|
837_forcefield_ripple|CONF|K|ripple|
838_forcefield_ripple_dyn|CONF|K|crypt_ed25519,ripple,ripple_dyn|
839_forcefield_optinvoke|CONF|K|optinvoke|
840_forcefield_optinvoke_egraph|CONF|K|egraph,optinvoke|
841_typecheck_core|CONF|K|typecheck|
842_typecheck_sigma|CONF|K|typecheck|
843_typecheck_bool|CONF|K|typecheck|
844_typecheck_id|CONF|K|typecheck|
845_typecheck_nat|CONF|K|typecheck|
846_typecheck_eta|CONF|K|typecheck|
847_typecheck_natrec|CONF|K|typecheck|
848_typecheck_j|CONF|K|typecheck|
849_typecheck_bot|CONF|K|typecheck|
850_typecheck_cumul|CONF|K|typecheck|
851_typecheck_sum|CONF|K|typecheck|
852_typecheck_meta|CONF|K|typecheck|
853_combinator_ski|CONF|K|combinator|
854_combinator_data|CONF|K|combinator|
855_combinator_conv|CONF|K|typecheck|
856_ccl_eta|CONF|K|ccl|
857_ccl_beta|CONF|K|ccl|
858_ccl_data|CONF|K|ccl|
859_ccl_conv|CONF|K|typecheck|
860_ccl_oracle|CONF|K|typecheck|
861_ccl_readback|CONF|K|typecheck|
862_ccl_etahi|CONF|K|ccl|
863_ccl_confluence|CONF|K|ccl|
864_forcefield_commit_gate|CONF|K|cad,commit_gate|
865_typecheck_qtt|CONF|K|typecheck|
866_typecheck_qtt2|CONF|K|typecheck|
867_typecheck_qtt_erase|CONF|K|typecheck|
868_typecheck_wtype|CONF|K|typecheck|
869_typecheck_wrec|CONF|K|typecheck|
870_typecheck_sovereign|CONF|K|typecheck|
871_typecheck_sov_field|CONF|K|typecheck|
872_typecheck_lamcheck|CONF|K|typecheck|
873_typecheck_reflcheck|CONF|K|typecheck|
874_sov_isa_descent|CONF|K|sov_isa|
875_typecheck_isa_cert|CONF|K|typecheck|
876_sov_isa_optimizer|CONF|K|sov_isa|
877_sov_pcc|CONF|K|sov_isa|
878_psi_superposition|CONF|K|sov_isa|
879_sov_evolve|CONF|K|sov_isa|
880_typecheck_induct|CONF|K|typecheck|
881_typecheck_induct_use|CONF|K|typecheck|
882_typecheck_open_conv|CONF|K|typecheck|
883_sov_admit|CONF|K|sov_isa|
884_xii_rule_verify|CONF|K-RETARGET|xii_rule_verify|xii_rule_verify
885_xii_fusion_verify|CONF|K-RETARGET|xii_fusion_verify|xii_fusion_verify
886_arith_identity|CONF|K||
887_const_fold_ext|CONF|K||
888_nous_value|CONF|K|nous_value|
889_nous_features|CONF|K|nous_features|
890_sat_arith|CONF|K|sat_arith|
891_xii_subforms|CONF|K|xii_subforms|
892_xii_nop_tables|CONF|K|xii_nop_tables|
893_u64_div|CONF|K||
894_const_fold|CONF|K||
895_dead_branch|CONF|K||
896_identities|CONF|K||
897_optimizer_soundness|CONF|K||
898_ast_intent|CONF|K|ast_intent|
902_babel|CONF|K|babel|
903_babel_intent|CONF|K|babel_intent,intent|
904_xii_curate|CONF|K|xii_curate|
905_tcp|CONF|K|tcp|
906_eg_integrity|CONF|K|egraph|
907_cl_rational|CONF|K|cost_lattice|
908_shape_filter|CONF|K|sov_isa|
909_cl_dominates|CONF|K|cost_lattice|
910_universe_subtype|CONF|K|typecheck|
911_bv_ring|CONF|K|bv_ring|
912_congruence|CONF|K|congruence|
913_ecdsa_p256_det_sign|CONF|K|ecdsa_p256|
914_xii_anchor_negative|CONF|K|anchor_xii,xii_horizon|
915_sov_self_improve|CONF|K|cost_lattice,egraph,sov_isa,typecheck|
916_sov_pipeline|CONF|K|sov_pipeline|
917_ripple_metric|CONF|K|ripple_metric|
918_ripple_unify|CONF|K|congruence,ripple_metric,ripple_unify|
919_ripple_loop|CONF|K|congruence,ripple_loop,ripple_metric|
920_ripple_cut|CONF|K|ripple_cut,ripple_metric|
921_ripple_extract|CONF|K|congruence,ripple_extract,ripple_metric|
922_pcc_gate|CONF|K|pcc_gate,typecheck|
923_hdl|CONF|K|hdl|
924_phys_cost|CONF|K|hdl|
925_aeu|CONF|K|aeu,hexad_reach,safety_type|
926_hdl_seq|CONF|K|hdl|
927_phys_real|CONF|K|hdl|
928_hdl_opt|CONF|K|hdl|
929_aeu_scale|CONF|K|aeu,hexad_reach|
930_ripple_value|CONF|K|ripple_metric|
931_phi_ledger|CONF|K|hexad_reach,integrity|
932_ripple_search|CONF|K|ripple_search|
933_induct|CONF|K|induct,typecheck|
934_cert|CONF|K|commit_gate|
935_ccl_invalid|CONF|K|ccl|
936_typecheck_ctxdepth|CONF|K|typecheck|
937_xii_crypto_chokepoint|CONF|K|xii_emit_gen|
938_cb_differential|CONF|K|typecheck|
939_ccl_confluence_falsifier|CONF|K|ccl|
940_irreducibility_falsifier|CONF|K|calculus_v1,irreducibility_proof|
941_quality_q7_lint_falsifier|CONF|K-RETARGET|quality_q7|quality_q7
942_proof_ripple_corpus_verify|CONF|K|pattern_table,proof_ripple_resolution|
943_resolver_memo_guards|CONF|K|resolver_memo|
944_resolver_replay_guard|CONF|K|pattern_table,resolver_replay|
945_mandate_dead_chain|CONF|K|kchain,mandate|
946_pattern_set_fed_ancestry|CONF|K|fed_seal,pattern_set_federation|
947_dynamic_impact_signed|CONF|K|dynamic_impact|
948_resolution_init_fail|CONF|K|pattern_table,resolution_init|
949_base32_pad_validation|CONF|K|arena,base32,builder|
950_xii_emit_gen_catalog|CONF|K|xii_emit_gen,xii_horizon|
951_seal_resolver_refreeze|CONF|K|seal_resolver|
952_microarch_rob_saturation|CONF|K|microarch_model|
953_mont_dmont5_falsifier|CONF|K|modular_mont|
954_ripple_extract_mdl|CONF|K|ripple_extract,ripple_metric|
955_optinvoke_cost_lattice|CONF|K|cost_lattice,optinvoke|
956_egraph_cost_lattice|CONF|K|egraph,optinvoke|
957_engine_compound|CONF|K|commit_gate,optinvoke,ripple_metric|
958_ecdsa_p384_zero_rs|CONF|K|ecdsa_p384|
959_ecdsa_p384_range_rs|CONF|K|ecdsa_p384|
960_keccak256_block_absorb|CONF|K|keccak256|
961_xoshiro_jump|CONF|K|xoshiro|
962_bv_ring_colstack|CONF|K|bv_ring|
963_sov_isa_cost_gradient|CONF|K|sov_isa|
964_ripple_extract_audit_purity|CONF|K|ripple_extract|
965_crystal_id_band|CONF|K|checked_crystal,crystal,scalar_provenance|
966_ripple_merkle_domain_sep|CONF|K|ripple|
967_pq_dispatch_nibble_guard|CONF|K|pq_dispatch|
968_optinvoke_seal_domain|CONF|K|mhash,optinvoke|
969_bv_ring_shift_mask|CONF|K|bv_ring|
970_merkle_index_binding|CONF|K|merkle|
971_cpufeat_avx512dq|CONF|K|cpufeat|
972_ecdsa_lowS_range|CONF|K|ecdsa_p256|
973_fe25519_canonical_decode|CONF|K|fe25519|
974_aes_gcm_aad_nonaligned_tamper|CONF|K|aes_gcm|
975_xii_lattice_payload_wrap_guard|CONF|K|xii_lattice|
976_optinvoke_seal_padding_determinism|CONF|K|optinvoke|
977_egraph_rule_wrap_guard|CONF|K|egraph|
978_smt_lia_wrap_guard|CONF|K|smt|
979_ripple_child_index_guard|CONF|K|ripple|
980_xii_subforms_salt_resolve|CONF|K|xii_subforms|
981_ed25519_strict_s_malleability|CONF|K|crypt_ed25519|
982_keccak_squeeze_rate_guard|CONF|K|keccak|
983_hexad_unpack6_range_guard|CONF|K|hexad_algebra|
984_bigint_assign_capacity_guard|CONF|K|arena,bigint|
985_hexad_epistemic_floor_escalate|CONF|K|hexad_epistemic|
986_mod_u64_mul_zero_modulus|CONF|K|modular|
987_cai_put_table_full|CONF|K|caindex|
988_witness_redact|CONF|K|keccak256,witness_hook|
989_mlkem_decaps_k_guard|CONF|K|mlkem|
990_bench_knuth_div|CONF|K|arena,bigint,bigint_div|
991_bench_montgomery_modpow|CONF|K|arena,bigint,bigint_div|
992_bench_fe25519_mul|CONF|K|arena,bigint,bigint_div,fe25519|
993_ed_decompress_canonical|CONF|K|fe25519|
994_ecdsa_p256_zero_rs|CONF|K|ecdsa_p256|
995_mldsa_siglen_guard|CONF|K|mldsa|
996_slhdsa_siglen_guard|CONF|K|slhdsa|
997_zk_air_general|CONF|K|zk_air|
998_zk_air_merkle|CONF|K|zk_air|
999_zk_air_stark|CONF|K|zk_air|
1000_checked_div_zero|CONF|K|checked|
1001_cap_verify_invalid_id|CONF|K|capability|
1002_quality_q4_growth|CONF|K|quality|
1003_merkle_tree_open_many|CONF|K|merkle|
1004_fri_fold_consistency|CONF|K|merkle,ntt_fri_organ|
1005_zk_stark_seal|CONF|K|zk_stark_seal|
1006_zk_stark_proof_seal|CONF|K|zk_stark|
1007_air_proof_seal|CONF|K|zk_air|
1008_zkp_stark_sidecar|CONF|K|zk_prune|
1009_proof_ripple_unified|CONF|K|proof_ripple_unified|
1010_pareto_frontier|CONF|K|pareto_extraction|
1011_hotstuff_pacemaker|CONF|K|hotstuff_unified|
1014_hdl_gate_identities|CONF|K|hdl_gate_db|
1016_proof_resolve|CONF|K|proof_resolve|
1017_hdl_optimize|CONF|K|hdl_optimize|
1018_hdl_compiler|CONF|K|hdl_compiler|
1019_arena_slot_witness|CONF|K|arena_slot_witness|
1020_sha_ni_differential|CONF|K|sha256,sha256_ni|
1021_ed_mod_l_barrett|CONF|K|arena,bigint,bigint_div,ed_scalar_modl|
1022_pq_dispatch_sha2_route|CONF|K|pq_dispatch|
1023_vec_overflow_guard|CONF|K|vec|
1024_iter_null_base_guard|CONF|K|iter|
1025_base64url_round_trip|CONF|K|arena,base64,builder|
1026_xii_export_bounds|CONF|K|xii_emit_gen|
1027_ripple_handle_exhaust_guard|CONF|K|arena,crystal,ripple,witness|
1028_tp_transpiler_bounds|CONF|K|tp_ast_to_babel_json,tp_babel_json_cbor,tp_babel_text_back,tp_iii_to_ast_bin|
1029_ripple_arena_subtraction_guard|CONF|K|ripple|
1030_ripple_metric_underflow_floor|CONF|K|ripple_metric|
1032_cbor_len_overflow|CONF|K|tp_babel_cbor_json|
1034_sf_field|CONF|K|ntt_fri_organ|
1035_zkf_fp|CONF|K|zk_field|
1036_zkf_fp2|CONF|K|zk_field|
1037_zkf_fp6|CONF|K|zk_field|
1038_zkf_fp12|CONF|K|zk_field|
1039_zkf_g1|CONF|K|zk_field|
1040_zkf_g2|CONF|K|zk_field|
1041_zkf_ec|CONF|K|zk_field|
1042_zkf_fexp|CONF|K|zk_field|
1043_curryh_kat|CONF|K|curry_howard|
1044_typecheck|CONF|K|typecheck|
1045_zk_air_fs|CONF|K|zk_air|
1046_ed25519_sign_seed|CONF|K|crypt_ed25519|
1047_quine_seal|CONF|K|quine_seal|
1048_json_uescape|CONF|ORPHAN-REF|Binary file STDLIB/corpus/1048_json_uescape.iii matches|MISSING:Binary file STDLIB/corpus/1048_json_uescape.iii matches
1049_mig2_keystone|CONF|K|typecheck|
1050_mig2_cost|CONF|K|typecheck|
1050_sealed_channel_forge_desync|CONF|K|sealed_channel,x25519|
1051_base64_pad_reject|CONF|K|arena,base64,builder|
1051_mig2_sovval|CONF|K|typecheck|
1052_base32_trailing_reject|CONF|K|arena,base32,builder|
1052_sov_morphism|CONF|K|sov_morphism|
1053_html_apos_unescape|CONF|K|arena,builder,html_escape|
1053_xii_morphism|CONF|K|xii_morphism|
1054_h9_mig2_tie|CONF|K|h9_mig2_tie|
1054_q128_ops|CONF|K|q128|
1055_modular_ops|CONF|K|modular|
1056_fixed_ops|CONF|K|fixed|
1057_checked_u64_lifecycle|CONF|K|checked|
1058_duration_ops|CONF|K|duration|
1059_span_ops|CONF|K|span|
1060_rune_utf8|CONF|K|rune|
1061_format_more|CONF|K|arena,builder,format|
1062_string_ops|CONF|K|string|
1063_hkdf_oneshot|CONF|K|hkdf|
1064_pbkdf2_oneshot|CONF|K|pbkdf2|
1065_sha256_dispatch|CONF|K|cpufeat,sha256_dispatch|
1066_parse_primitives|CONF|K|parse|
1067_uri_pct_decode_reject|CONF|K|arena,builder,uri|
1068_pattern_set_arity|CONF|K|pattern|
1069_dynamic_record_rejects|CONF|K|dynamic_record|
1070_vec_setters|CONF|K|arena,vec|
1071_hexad_epistemic_accessors|CONF|K|hexad_epistemic|
1072_list_negatives|CONF|K|arena,list|
1073_hexad_algebra|CONF|K|hexad_algebra|
1074_hexad_pfs|CONF|K|hexad_pfs|
1075_hexad_dynamic|CONF|K|hexad_dynamic|
1076_instant_diff_ticks|CONF|K|capability,instant|
1077_crystal_tamper_reject|CONF|K|crystal|
1078_net_cap_deny|CONF|K|capability,handle,net|
1079_rsa_wrappers|CONF|K|rsa|
1080_chacha20_differential|CONF|K|chacha20,cpufeat|
1081_blake2s_differential|CONF|K|blake2s,cpufeat|
1082_pattern_table_getters|CONF|K|pattern_table|
1083_synthesis_propose_ratify|CONF|K|algebraic_time,constitution,synthesis_spec,witness_hook|
1084_slhdsa_variant_keygen|CONF|K|slhdsa|
1085_http_build_request|CONF|K|arena,builder,http_client|
1086_http_response_accessors|CONF|K|arena,http_client|
1087_node_identity_witnessed|CONF|K|capability,node_identity,witness_hook|
1088_pattern_set_fed_wire|CONF|K|fed_seal,pattern_set_federation,sealed_channel,sha256|
1089_local_array_runtime_index|CONF|K||
1090_nous_lattice|CONF|K|nous_lattice,nous_socket|
1091_ripple_synthesizer|CONF|K-RETARGET|ripple_synthesizer|ripple_synthesizer
1092_gate_cp1_guard|CONF|K||
1100_obs_witnessed|CONF|K|algebraic_time,keccak256,observe|
1101_forked_walk|CONF|K|commit_gate,forked_walk,reversible|
1102_conjecture|CONF|K|nous_conjecture|
1103_conjecture_complete_all|CONF|K|nous_conjecture|
1104_conjecture_term|CONF|K|nous_conjecture_term|
1105_conjecture_gen|CONF|K|nous_conjecture_gen|
1106_conjecture_lemma|CONF|K|nous_conjecture_lemma,nous_conjecture_term|
1107_egraph_saturate_capacity_gap|CONF|K|egraph,nous_search|
1108_sov_self_extend|CONF|K|sov_isa|
1109_cast_stride_index|CONF|K||
1110_tp_morphism|CONF|K|tp_morphism|
1111_sha_ni_stream_diff|CONF|K|sha256,sha256_ni|
1112_opt_certified|CONF|K|sov_isa|
1113_sr_schema_foundation|CONF|K|sov_isa|
1114_sr_schema_distrib|CONF|K|sov_isa|
1115_sr_schema_strength|CONF|K|sov_isa|
1116_sr_schema_apply|CONF|K|sov_isa|
1117_sr_schema_distrib_apply|CONF|K|sov_isa|
1118_sr_schema_semiring|CONF|K|sov_isa|
1119_sov_synth_nonvacuity|CONF|K|sov_isa|
1120_sov_synth_attempt|CONF|K|sov_isa|
1121_egraph_stochastic|CONF|K|egraph_stochastic|
1122_cg_autocatalyst|CONF|K|cg_autocatalyst|
1123_daemon_dream|CONF|K|daemon_dream|
1124_fs_dir_enum|CONF|K|capability,fs|
1125_onelang_audit|CONF|K|onelang|
1126_founders_anchor|CONF|K|founders_anchor|
1127_constants_ledger|CONF|K|constants|
1128_conjecture_lemma_struct|CONF|K|nous_conjecture_lemma,nous_conjecture_term|
1129_regex_phase_c|CONF|K|regex|
1130_glyph_str_validate_utf8|CONF|K|glyph_str|
1200_proof_bisimulation|CONF|K|proof_bisimulation|
1201_ast_hunter|CONF|K|ast_hunter|
1202_cg_surgical_strike|CONF|K|cg_surgical_strike|
1203_daemon_scythe|CONF|K-RETARGET|daemon_scythe|daemon_scythe
1204_scythe_census|CONF|K|scythe_census|
1205_sovereign_optimizer|CONF|K|sovereign_optimizer|
1206_sovereign_continuous|CONF|K|sovereign_optimizer|
1207_shift_fold_certified|CONF|K|sov_isa|
1208_theorem_commons|CONF|K|theorem_commons,typecheck|
1209_theorem_commons_distinct|CONF|K|theorem_commons,typecheck|
1210_commons_feed|CONF|K|sov_isa,theorem_commons|
1211_commons_cite_reuse|CONF|K|sov_isa,theorem_commons|
1212_commons_root|CONF|K|theorem_commons,typecheck|
1213_bv_kernel|CONF|K|typecheck|
1214_bv_kernel_differential|CONF|K|bv_ring,typecheck|
1215_r3_identity_fold|CONF|K||
1216_bv_dispose|CONF|K|bv_dispose|
1217_rscode|CONF|K|rscode|
1218_erasure_store|CONF|K|erasure_store|
1219_shamir|CONF|K|shamir|
1220_threshold_vault|CONF|K|threshold_vault|
1221_hamming_secded|CONF|K|hamming_secded|
1222_gf_poly|CONF|K|gf_poly|
1223_rscode_ec|CONF|K|rscode_ec|
1224_lzss|CONF|K|lzss|
1225_cas_blob|CONF|K-RETARGET|cas_blob|cas_blob
1226_crt|CONF|K|crt|
1227_bitio|CONF|K|bitio|
1228_elias|CONF|K|elias|
1230_huffman|CONF|K|huffman|
1231_lzh|CONF|K|lzh|
1232_heaplet|CONF|K|heaplet|
1233_sep_logic|CONF|K|sep_logic|
1234_tso|CONF|K|tso|
1235_ptr_provenance|CONF|K|ptr_provenance|
1236_mem_rewrite|CONF|K|mem_rewrite|
1237_csl|CONF|K|csl|
1238_congruence_closure|CONF|K|congruence_closure|
1239_mcmc_egraph|CONF|K|mcmc_egraph|
1240_certified_morphism|CONF|K|certified_morphism|
1241_ripple_journal|CONF|K|ripple_journal|
1242_costed_cat|CONF|K|costed_cat|
1243_ru_kernel_merge|CONF|K|congruence,ripple_metric,ripple_unify,typecheck|
1244_relational_ematch|CONF|K|relational_ematch|
1245_algo_synth|CONF|K|algo_synth|
1246_bv_canon_addr|CONF|K|bv_dispose,bv_ring,mhash,typecheck|
1247_induct_wj|CONF|K|induct,typecheck|
1247_k0_referee|CONF|K|k0_referee|
1248_golden_shift|CONF|K|golden_shift|
1249_conjecture_refute|CONF|K|conjecture_refute|
1250_self_engine|CONF|K|self_engine|
1251_xii_cap_preserve|CONF|K|xii_cap_preserve|
1252_tcom_goalbound|CONF|K|theorem_commons,typecheck|
1253_verified_search|CONF|K|verified_search|
1254_omega_engine|CONF|K-RETARGET|omega_engine|omega_engine
1255_pareto_frontier|CONF|K-RETARGET|pareto_frontier|pareto_frontier
1256_verified_ripple|CONF|K|verified_ripple|
1257_optimality_cert|CONF|K|optimality_cert|
1258_reach_witnessed|CONF|K|cad,capability,fs,reach_core|
1259_contract_gate|CONF|K|contract_gate|
1260_ring_opt|CONF|K|ring_opt|
1261_matrix_ring|CONF|K|matrix_ring|
1262_bft_quorum|CONF|K|bft_quorum|
1263_affine_check|CONF|K|affine_check|
1264_rewrite_schedule|CONF|K|rewrite_schedule|
1265_interval_lattice|CONF|K|interval_lattice|
1266_loop_optimizer|CONF|K|loop_optimizer|
1267_kleene_fixpoint|CONF|K|kleene_fixpoint|
1268_widening|CONF|K|widening|
1269_align_domain|CONF|K|align_domain|
1270_vectorizer|CONF|K|vectorizer|
1271_bce|CONF|K|bce|
1272_reduced_product|CONF|K|reduced_product|
1273_loop_pipeline|CONF|K|loop_pipeline|
1274_reg_alloc|CONF|K|reg_alloc|
1275_list_schedule|CONF|K|list_schedule|
1276_isel|CONF|K|isel|
1277_dominators|CONF|K|dominators|
1278_ssa|CONF|K|ssa|
1279_gvn|CONF|K|gvn|
1280_dce|CONF|K|dce|
1281_sccp|CONF|K|sccp|
1282_taint_analysis|CONF|K|taint_analysis|
1283_range_check|CONF|K|range_check|
1284_translation_validation|CONF|K|translation_validation|
1285_liveness|CONF|K|liveness|
1286_proof_replay|CONF|K|proof_replay|
1288_bmc|CONF|K-RETARGET|bmc|bmc
1289_kinduction|CONF|K-RETARGET|kinduction|kinduction
1290_dijkstra|CONF|K|dijkstra|
1291_safety_prover|CONF|K|safety_prover|
1292_value_range_prover|CONF|K|value_range_prover|
1293_loop_bounds_prover|CONF|K|loop_bounds_prover|
1294_branch_elim|CONF|K|branch_elim|
1295_rms|CONF|K|rms|
1296_binary_search|CONF|K|binary_search|
1297_kmp|CONF|K|kmp|
1298_levenshtein|CONF|K|levenshtein|
1299_fenwick|CONF|K|fenwick|
1300_segment_tree|CONF|K|segment_tree|
1301_knapsack|CONF|K|knapsack|
1302_inversion_count|CONF|K|inversion_count|
1303_coin_change|CONF|K|coin_change|
1304_lcs|CONF|K|lcs|
1305_lis|CONF|K|lis|
1306_sieve|CONF|K|sieve|
1307_gray_code|CONF|K|gray_code|
1308_catalan|CONF|K|catalan|
1309_goldbach|CONF|K-RETARGET|goldbach|goldbach
1310_collatz|CONF|K-RETARGET|collatz|collatz
1311_sovereign_analysis|CONF|K|sovereign_optimizer|
1312_sovereign_witness_crossval|CONF|K|sovereign_witness|
1313_sovereign_refined|CONF|K|sovereign_optimizer|
1314_hotstuff_safety|CONF|K|hotstuff|
1315_kleene_widened|CONF|K|kleene_fixpoint|
1316_topology_weighted|CONF|K|topology_atlas|
1317_proof_ripple_audit|CONF|K|proof_ripple_unified|
1318_bce_sccp|CONF|K|bce|
1319_cap_handshake_taint|CONF|K|cap_handshake|
1320_sovereign_branch_crossval|CONF|K|sovereign_optimizer|
1321_census_commons|CONF|K|scythe_census|
1322_reg_alloc_liveness|CONF|K|reg_alloc|
1323_aes_gcm_taint|CONF|K|aes_gcm|
1324_hotstuff_liveness|CONF|K|hotstuff|
1325_memo_predicate_gate|CONF|K|memo_query|
1326_safety_k_induction|CONF|K|safety_prover|
1327_json_frac_exp|CONF|K|arena,builder,json|
1328_glob_class_range_negate|CONF|K|glob|
1329_glyph_set_uniqueness|CONF|K|glyph_set|
1330_fix_signed|CONF|K|fixed|
1331_xii_iflift_verify|CONF|K-RETARGET|xii_iflift_verify|xii_iflift_verify
1332_inet6|CONF|K|arena,builder,inet6|
1333_ripple_apply|CONF|K|ripple_apply|
1334_eg_kernel_merge|CONF|K|egraph,typecheck|
1335_bvd_rule_gate|CONF|K|bv_dispose,bv_ring,egraph,typecheck|
1336_induct_commons|CONF|K|induct,theorem_commons,typecheck|
1337_mont_nprime_cert|CONF|K|arena,bigint,bigint_div|
1338_fp_inv_euclid|CONF|K|arena,bigint,field|
1339_tcom_merkle|CONF|K|cad,theorem_commons,typecheck|
1340_memo_equiv|CONF|K|constitution,identifier,memo_lattice,memo_query|
1341_remote_rfc7230|CONF|K|backend_remote|
1342_sv_provisional|CONF|K|reach_oracle,sovval,uncertainty|
1343_cgr_kernel_ring|CONF|K|congruence,typecheck|
1344_bv_dream_sieve|CONF|K|cg_autocatalyst|
1345_bv_bits|CONF|K|bv_bits|
1346_tcom_federated|CONF|K|theorem_commons,typecheck|
1347_barrett_general|CONF|K|arena,barrett,bigint,bigint_div|
1348_fed_seal_witnessed|CONF|K|cad,fed_seal,witness_hook|
1349_xii_cost_monotone|CONF|K|xii_cost_monotone|
1350_cal_month_exact|CONF|K|calendar|
1351_duration_cert|CONF|K|duration_cert|
1352_xii_denote|CONF|K|xii_denote|
1353_bv_discover_loop|CONF|K|cg_autocatalyst|
1354_resolve_unify|CONF|K|call_context,intent,kchain,pattern_table|
1355_bv_selflaws_lshr|CONF|K|typecheck|
1356_mixed_discover|CONF|K|bv_bits,cg_autocatalyst|
1357_astkind_claim|CONF|K|call_context,codegen_dispatch,intent,kchain|
1358_shift_laws|CONF|K|bv_bits,cg_autocatalyst|
1359_transform_claim|CONF|K|call_context,codegen_dispatch,intent,kchain|
1360_full_dream|CONF|K|cg_autocatalyst,daemon_dream|
1361_primitive_claim|CONF|K|call_context,codegen_dispatch,intent,kchain|
1362_lattice_cited_combine|CONF|K|sov_isa|
1363_bvudiv_strength|CONF|K|typecheck|
1364_divstrength_cited|CONF|K|sov_isa|
1365_rules_are_citations|CONF|K|sov_isa|
1366_mixed_dispose|CONF|K|bv_bits,bv_dispose,typecheck|
1367_witnessed_dream|CONF|K|daemon_dream,witness_hook|
1368_bv_commons|CONF|K|bv_commons,theorem_commons,typecheck|
1369_bv_federated|CONF|K|theorem_commons,typecheck|
1370_discovery_pipeline|CONF|K|cg_autocatalyst,cost_lattice,egraph,sov_isa|
1371_autonomous_cycle|CONF|K|cg_autocatalyst,cost_lattice,daemon_dream,egraph|
1372_dream_federated|CONF|K|bv_commons,cg_autocatalyst,theorem_commons|
1373_federated_adoption|CONF|K|bv_commons,cg_autocatalyst,cost_lattice,egraph|
1390_tp_planner|CONF|K|category,cost_lattice,tp_morphism,tp_planner|
1391_corpus_coverage|CONF|K|cad,capability,corpus_coverage,fs|
1392_async_fsm|CONF|K|arena,async,vec|
1393_checked_crystal_provenance|CONF|K|checked,checked_crystal,crystal|
1394_endian_exact|CONF|K|endian|
1395_introspection_sweep|CONF|K|arena,bigint,builder,category|
1396_context_cap_csv|CONF|K|arena,call_context,capability,csv|
1397_registry_probe_verdict|CONF|K|attest,cg_autocatalyst,charter_terminal,cpufeat|
1398_fed_sybil_gate|CONF|K|crypt_ed25519,fed_sybil|
1399_anchor_store_wave|CONF|K|arena,builder,bv_bits,bv_ring|
1400_glyph_v3_forms|CONF|K|glyph_bytes,glyph_core,glyph_crystal,glyph_enum|
1400_self_model|CONF|K|capability,corpus_coverage,fs,self_model|
1401_field_curve_vault|CONF|K|fn256,fn384,fp256,fp384|
1401_gap_conjecture|CONF|K|gap_conjecture|
1402_gov_charter_hexad|CONF|K|governance,h13_charter,h2_charter,hexad_algebra|
1402_harmony_synth|CONF|K|harmony_synth|
1403_kchain_json_iter|CONF|K|arena,capability,fs,iter|
1403_refactor_propose|CONF|K|refactor_propose|
1404_optimize_self|CONF|K|optimize_self|
1404_scalar_result_rune|CONF|K|result,rune,scalar|
1405_provenance_span_basis|CONF|K|crystal,scalar_provenance,span,string|
1405_theorem_grow|CONF|K|capability,fs,theorem_grow,typecheck|
1406_autogenesis_cycle|CONF|K|autogenesis,capability|
1406_term_arena_xoshiro|CONF|K|xii_term,xoshiro,zk_field|
1407_autogenesis_revert|CONF|K|autogenesis,capability|
1407_lattice_cells|CONF|K|xii_lattice|
1408_autogenesis_attest|CONF|K|attest_box,autogenesis,capability,node_identity|
1408_intent_table|CONF|K|intent|
1409_autogenesis_charter|CONF|K|autogenesis,capability|
1409_scalar64_sat_counters|CONF|K|sat,scalar|
1410_autogenesis_cli|CONF|K|autogenesis_cli,capability|
1410_semver_uri_sha512_tp|CONF|K|arena,semver,sha512,transform_patterns|
1411_sovereign_optimizer|CONF|K|scythe_census,sovereign_optimizer|
1412_circ_horizon|CONF|K|xii_circ,xii_horizon,xii_horizon_reach|
1413_transform_taint_seal|CONF|K|arena,call_context,capability,seal_organ|
1414_unify_witness_spine|CONF|K|arena,unify,witness,witness_hook|
1415_xii_rewrite_rules|CONF|K|xii_rewrite,xii_term|
1416_pq_dispatch_c4|CONF|K|pq_dispatch,pq_params|
1417_option_path_pq_prov|CONF|K|arena,builder,crystal,option|
1418_fx_http_request|CONF|K|arena,fixed_extra,http_server|
1419_xii_tables|CONF|K|xii_chd,xii_curate,xii_hj,xii_horizon|
1420_nl_ini_net_walk|CONF|K|arena,capability,forked_walk,fs|
1421_jit_mandate_map_forge|CONF|K|arena,bigint,cap_forge,capability|
1422_field_replay_manifest|CONF|K|crystal,crystal_deps,manifest,memo_query|
1423_ldil_seal_charter|CONF|K|cad,layered_seal,nous_charter,pattern|
1424_solve_sandbox_sign_measure|CONF|K|cad,capability,crypt_ed25519,hdl|
1425_membrane_launch|CONF|K|crypt_ed25519,sha256,xii_antidrift,xii_atm|
1426_dispatch_admit_crystal|CONF|K|anchor_xii,arena,capability,http|
1427_coverage_gate_outcomes|CONF|K|cad,capability,corpus_coverage,fs|
1428_gate_outcomes_glyph_membrane|CONF|K|crypt_ed25519,glyph_crystal,glyph_enum,glyph_f64|
1429_gate_outcomes_anchor_rsa|CONF|K|arena,bigint,crypt_ed25519,founders_anchor|
1430_gate_outcomes_constants|CONF|K|constants|
1431_gate_outcomes_referee_spine|CONF|K|capability,instant,k0_referee,pattern_table|
1432_gate_outcomes_proof_carrying|CONF|K|arena,bigint,proof_carrying,witness_hook|
1433_gate_outcomes_attest_lattice|CONF|K|attest,capability,cost_lattice_synth,reversibility_audit|
1434_gate_outcomes_manifest|CONF|K|manifest,witness_hook|
1435_gate_outcomes_seal_quorum|CONF|K|crypt_ed25519,egraph,erasure_store,hotstuff|
1436_gate_outcomes_shift_wire|CONF|K|babel_wire,call_context,golden_shift,idoc|
1437_gate_outcomes_memo_ripple|CONF|K|arena,constitution,crystal,crystal_edges|
1438_gate_outcomes_train_fold_conserve|CONF|K|contract_gate,nous_train,sovereign_optimizer|
1439_gate_outcomes_sovereign_conf|CONF|K|typecheck|
1440_gate_outcomes_carrier_library|CONF|K|constitution,math_library,proof_term,theorem_carrier|
1441_gate_outcomes_federation_admit|CONF|K|crypt_ed25519,fed_admit,fed_sybil,hotstuff|
1442_gate_outcomes_mobius_overrun|CONF|K|cost_overrun_handler,hexad_mobius|
1443_gate_outcomes_constitution_preserver|CONF|K|algebraic_time,constitution_preserver,witness_hook|
1444_gate_outcomes_bv_dispose|CONF|K|bv_dispose,bv_ring,typecheck|
1445_gate_outcomes_sov_pcc|CONF|K|sov_isa,typecheck|
1446_gate_outcomes_branch_bisim|CONF|K|algebraic_time,branch_anchor,computation_graph,constitution|
1447_gate_outcomes_marrow_block|CONF|K|bone_marrow,capability|
1448_gate_outcomes_graph_integrity|CONF|K|cg_surgical_strike|
1449_gate_outcomes_symreg|CONF|K|capability,symbolic_regression,witness_hook|
1450_gate_outcomes_journal_confcert|CONF|K|ripple_journal,xii_conf_cert,xii_register_all|
1451_gate_outcomes_drift_typecheck_bisim|CONF|K|k0_referee,proof_bisimulation,typecheck|
1452_gate_outcomes_antidrift_subchecks|CONF|K|crypt_ed25519,sha256,xii_antidrift|
1453_gate_outcomes_transval_loopbound|CONF|K|loop_bounds_prover,translation_validation|
1454_gate_outcomes_mandate_ldil|CONF|K|mandate,xii_ldil|
1455_gate_outcomes_census_eclipse_pareto|CONF|K|fed_eclipse,hdl_optimize,sov_isa|
1456_gate_outcomes_governance_intent|CONF|K|governance,intent,mandate,resolution_init|
1457_gate_outcomes_aether_guards|CONF|K|capability,context_awareness,fed_eclipse,firmware_quarantine|
1458_gate_outcomes_ldil_pareto|CONF|K|hdl_optimize,identifier,xii_ldil|
1459_gate_outcomes_sheaf_census_order|CONF|K|nous_lattice,sheaf,sov_isa|
1460_gate_outcomes_proof_vertical|CONF|K|arena,category,proof_replay,theorem_commons|
1461_gate_outcomes_joinability|CONF|K|xii_antidrift,xii_critpair_enum,xii_joinability|
1462_numera_slot_witness_gaps|CONF|K|cad,constitution,egraph,identifier|
1463_numera_carrier_program_gaps|CONF|K|arena,bigint,cad,proof_carrying|
1464_coverage_reachability|CONF|K|cad,capability,corpus_coverage,fs|
1465_dark_surface_gaps|CONF|K|arena,bitops,dijkstra,heaplet|
1466_boundary_registry_caps|CONF|K|category,fed_seal,pattern_table|
1467_boundary_parser_caps|CONF|K|arena,csv,json,nl_lex|
1468_boundary_arena_caps|CONF|K|ccl,egraph|
1469_fs_denied_pt_final|CONF|K|capability,fs,proof_term|
1470_base32_glyphmap_edges|CONF|K|arena,base32,builder,glyph_bytes|
1471_drop_lifecycle_arms|CONF|K|arena,capability,fs,handle|
1472_bitops_boundary|CONF|K|bitops|
1473_witness_full_tempaloc_edges|CONF|K|region,witness|
1474_gov_transition_walls|CONF|K|governance,resolution_init|
1475_quarantine_rollback_abort|CONF|K|capability,quarantine,witness_hook|
1476_glyph_v3_offset_contract|CONF|K|glyph_core,glyph_u32,sha256|
1477_numeric_edge_laws|CONF|K|arena,bigint,modular,q128|
1478_rscode_uninit_refusal|CONF|K|rscode|
1479_egraph_incremental_rebuild|CONF|K|cad,egraph|
1480_checked_option_unity|CONF|K|checked,option|
1481_egraph_dijkstra_extract|CONF|K|arena,egraph|
1482_result_signed_payload|CONF|K|result|
1483_nous_live_set|CONF|K|nous_lattice,nous_policy,nous_socket|
1484_joinability_residual_family|CONF|K|xii_joinability|
1485_modpow_exhaustion_refusal|CONF|K|arena,bigint,bigint_div|
1486_iter_signed_payload|CONF|K|iter|
1487_regpressure_differential|CONF|K|cost_calculus|
1488_pleroma_csr_differential|CONF|K|pleroma|
1489_uncertainty_dag_memo|CONF|K|uncertainty|
1490_groebner_chain_criterion|CONF|K|arena,bigint,groebner|
1491_bracket_abstraction_opt|CONF|K|combinator|
1492_mathlib_index_differential|CONF|ORPHAN-REF|constitution,ident,math_library,proof_term|MISSING:ident
1493_fe25519_sqr_differential|CONF|K|fe25519|
1494_mldsa_ntt_inplace|CONF|K|mldsa|
1495_ed25519_dbl_differential|CONF|K|fe25519|
1496_k0_bounds_guard|CONF|K|k0_referee|
1497_dijkstra_bounds_guard|CONF|K|dijkstra|
1498_fe25519_cold_invert|CONF|K|fe25519|
1499_field256_accessor_bounds|CONF|K|fn256,fp256|
1500_zkfield_accessor_bounds|CONF|K|zk_field|
1501_knap_seg_bounds|CONF|K|knapsack,segment_tree|
1502_analysis_accessor_bounds|CONF|K|congruence_closure,dce,dominators,gvn|
1503_fix_div_large_operand|CONF|K|fixed|
1504_fs_open_handle_leak|CONF|K|capability,fs,handle|
1505_resolver_memo_fifo|CONF|K|resolver_memo|
1506_huffman_decode_len_oob|CONF|K|huffman|
1507_egraph_flip_node_oob|CONF|K|egraph|
1508_accessor_bounds_heaplet_liveness_matrix|CONF|K|heaplet,liveness,matrix_ring|
1509_accessor_bounds_bvbits_omega_seplogic_csl|CONF|K-RETARGET|bv_bits,csl,omega_engine,sep_logic|omega_engine
1510_temporal_logic_trace_oob|CONF|K|temporal_logic|
1511_governance_vote_state_wall|CONF|K|governance,resolution_init|
1512_montgomery_to_mont_cold_init|CONF|K|fn256,fn384,fp256,fp384|
1513_hotstuff_safety_cold_init|CONF|K|hotstuff|
1514_scalar_reduce_cold_init|CONF|K|fn256,fn384|
1515_bigint_new_cap_overflow|CONF|K|arena,bigint|
1517_threshold_vault_kkey_bound|CONF|K|threshold_vault|
1518_crt_solve_zero_modulus|CONF|K|crt|
1519_rn_graph_root_overflow|CONF|K|ripple|
1520_rms_ceil_div_zero|CONF|K|rms|
1521_sf_rou_zero_order|CONF|K|ntt_fri_organ|
1522_temporal_subf_overflow|CONF|K|temporal_logic|
1523_governance_drop_accepted_wall|CONF|K|governance,resolution_init|
1524_csl_lens_count_bound|CONF|K|csl|
1525_cad_cold_no_begin|CONF|K|cad|
1526_merkle_build_pow2_guard|CONF|K|merkle|
1527_ad_aligned_nonpow2|CONF|K|align_domain|
1528_vz_covers_nonpow2|CONF|K|vectorizer|
1529_ad_loop_scan_nonpow2|CONF|K|align_domain|
1530_bitr_get_oob|CONF|K|bitio|
1531_ntt_pow2_guard|CONF|K|ntt|
1532_ntt_tabled_pow2_guard|CONF|K|ntt|
1533_rp_count_empty_interval|CONF|K|reduced_product|
1534_lo_empty_loop_safe|CONF|K|affine_check,loop_optimizer|
1535_ec256_group_laws|CONF|K|ec256|
1536_ec384_group_laws|CONF|K|ec384|
1537_x25519_rfc7748_dh|CONF|K|x25519|
1538_sha3_512_empty|CONF|K|sha3_512|
1539_blake2s_empty|CONF|K|blake2s|
1540_sha3_256_multiblock|CONF|K|sha3_256|
1541_pq_keygen_determinism|CONF|K|mldsa,mlkem,slhdsa|
1542_interval_lattice_overflow_sound|CONF|K|interval_lattice|
1543_elias_overflow_propagate|CONF|K|bitio,elias|
1544_bce_overflow_unsound|CONF|K|affine_check,bce|
1545_blake2s_sigma_perm|CONF|K|blake2s|
1546_lzss_reject|CONF|K|lzss|
1547_huff_reject|CONF|K|huffman|
1548_hex_reject|CONF|K|hex|
1549_leb128_overflow_reject|CONF|K|leb128|
1550_lzh_reject|CONF|K|lzh|
1551_mldsa_hint_reject|CONF|K|mldsa|
1552_http_reject|CONF|K|arena,http_server|
1553_json_reject|CONF|K|arena,json|
1554_parse_decimal_reject|CONF|K|parse|
1555_json_leading_zero|CONF|K|arena,json|
1556_json_string_ctrl|CONF|K|arena,json|
1557_semver_ident|CONF|K|semver|
1558_utf8_validate|CONF|K|arena,builder,normalise|
1559_mlkem_modcheck|CONF|K|mlkem|
1560_rfc3339_format|CONF|K|rfc3339|
1561_rsa_noncanon_sig|CONF|K|arena,rsa|
1562_mat_pow_zero|CONF|K|matrix_ring|
1563_nfd_canonical_reorder|CONF|K|arena,builder,normalise|
1564_span_cmp_reflexive|CONF|K|span|
1565_pcc_congruence_app|CONF|K|congruence_closure|
1566_nfc_hangul_roundtrip|CONF|K|arena,builder,normalise|
1567_groebner_normal_form|CONF|K|arena,bigint,groebner|
1568_q128_round_dir|CONF|K|q128,q128_f64|
1569_json_i64_min|CONF|K|arena,json|
1570_rms_ceil_div_overflow|CONF|K|rms|
1571_semver_u64_max|CONF|K|semver|
1572_cg_i32_callresult_signed_div|CONF|K||
1573_siphash_kat|CONF|K|siphash|
1574_adler32_kat|CONF|K|adler32|
1575_vbd_reversible_rollback|CONF|K|vbd|
1576_flow_firewall|CONF|K|flow_firewall|
1577_sentinel_autorollback|CONF|K|sentinel,vbd|
1578_enclave_forcefield|CONF|K|enclave|
1579_sealed_box_capstone|CONF|K|capability,flow_firewall,sealed_box,sentinel|
1580_replay_box_determinism|CONF|K|replay_box|
1581_compute_box_quota|CONF|K|capability,compute_box|
1582_snapshot_box_branching|CONF|K|snapshot_box,vbd|
1583_determinism_firewall|CONF|K|determinism_firewall,replay_box|
1584_sid_router_universal|CONF|K|sid_router|
1585_develop_up_gateway|CONF|K|attest_box,capability,develop_up,flow_firewall|
1586_basecodec_canonical_bits|CONF|K|arena,base32,base64,builder|
1587_leb128_overwide_final_byte|CONF|K|leb128|
1588_hmac_long_key|CONF|K|hmac|
1589_merkle_cve_2012_2459_documented|CONF|K|merkle|
1590_cgr_intern_hash_collisions|CONF|K|congruence|
1591_prover_soundness_u32_bound|CONF|K|affine_check,range_check,reduced_product,value_range_prover|
1592_pbkdf2_iteration_fold|CONF|K|pbkdf2|
1593_hkdf_zero_salt|CONF|K|hkdf|
1594_sha512_two_block_pad|CONF|K|sha512|
1595_attest_box_remote|CONF|K|attest_box,capability,node_identity,vbd|
1596_coldinit_guards|CONF|K|drbg,entropy_monitor,shake256|
1597_production_hardening|CONF|K|capability,develop_up,fp256,sentinel|
1598_resolver_tiebreak|CONF|K|call_context,intent,kchain,pattern_table|
1599_production_hardening_2|CONF|K|capability,develop_up,sha512|
1600_production_hardening_3|CONF|K|capability,develop_up,entropy_monitor,replay_box|
1601_ripple_native_stage1|CONF|K|arena,crystal,ripple,witness|
1602_hotstuff_qc_lifecycle|CONF|K|crypt_ed25519,hotstuff|
1603_hotstuff_arbitrary_signer_qc|CONF|K|crypt_ed25519,hotstuff|
1604_findings_oob_guards|CONF|K-RETARGET|bft_quorum,bmc,catalan,coin_change|bmc
1605_findings_w2616_tier2|CONF|K-RETARGET|capability,identifier,mcmc_egraph,pareto_frontier|pareto_frontier
1606_h052_bitreverse_emit|CONF|K|xii_curated_extended,xii_emit_gen|
1607_cap_drop_aba|CONF|K|capability|
1608_babel_wire_verify_len|CONF|K|babel_wire,cap_handshake|
1609_emit_gen_oob_write|CONF|K|xii_emit_gen,xii_horizon|
1610_lzss_truncated_match|CONF|K|lzss|
1611_cap_forge_deforge_opid|CONF|K|cap_forge,capability,witness_hook|
1612_idoc_validate_len|CONF|K|babel_wire,idoc|
1613_pbkdf2_iter_zero|CONF|K|pbkdf2|
1614_negpath_null_guards|CONF|K|babel_wire,hex|
1615_fed_seal_tier_order|CONF|K|fed_seal|
1616_resolver_ring_precedence|CONF|K|resolver|
1617_enc_declare_region|CONF|K|enclave|
1618_format_literal_null|CONF|K|arena,builder,format|
1619_hotstuff_equivocation|CONF|K|crypt_ed25519,hotstuff|
1620_box_exhaust_span_oob|CONF|K|flow_firewall,span|
1621_rfc3339_format_yearbound|CONF|K|rfc3339|
1622_ripple_merge_commute|CONF|K|ripple|
1623_fed_eclipse_quorum_reference|CONF|K|fed_eclipse,fed_sybil|
1624_ec256_on_curve|CONF|K|ec256,ecdsa_p256|
1625_duration_to_units|CONF|K|duration|
1626_aes192_gcm_roundtrip|CONF|K|aes_gcm|
1627_hkdf_sha512|CONF|K|hkdf,hmac|
1628_pbkdf2_sha512|CONF|K|hmac,pbkdf2|
1629_develop_up_cpu_meter|CONF|K|capability,develop_up|
1630_observe_replay_integrity|CONF|K|observe,witness_hook|
1631_csv_field_unescaped|CONF|K|csv|
1632_uri_authority_split|CONF|K|uri|
1633_hip_locative_destination|CONF|K|hip,intent|
1634_hip_conditional_intent|CONF|K|hip,intent|
1635_calendar_civil_fields|CONF|K|calendar|
1636_hip_reason_intent|CONF|K|hip,intent|
1637_hip_modal_guarantees|CONF|K|hip,intent|
1638_http_request_version|CONF|K|arena,http_server|
1639_http_response_version|CONF|K|arena,http_client|
1640_duration_components|CONF|K|duration|
1641_ini_separator|CONF|K|arena,ini|
1642_rune_utf8_decode_reason|CONF|K|rune|
1643_hex_partial_count|CONF|K|hex|
1644_hip_conjunction_intent|CONF|K|hip,intent|
1645_rfc3339_trailing_reject|CONF|K|rfc3339|
1646_json_emit_ctrl_escape|CONF|K|arena,builder,json|
1647_path_stem|CONF|K|path|
1648_leb128_decode_reason|CONF|K|leb128|
1649_fix_div_quotient_overflow|CONF|K|fixed|
1650_http_server_builder_error_propagation|CONF|K|arena,builder,http_server|
1651_resolver_if_guard|CONF|K|call_context,codegen_dispatch,intent,kchain|
1652_resolver_composites|CONF|K|call_context,codegen_dispatch,intent,kchain|
1653_proof_symmetry_swap|CONF|K|proof_term|
1654_sandbox_slot_alias_x19|CONF|K|sandbox_ctor,sandbox_exec|
1655_q128f64_slot_alias_x19|CONF|K|q128,q128_f64|
1656_http_crystal_slot_alias_x19|CONF|K|arena,http|
1657_proof_reflexivity_check|CONF|K|proof_term|
1658_proof_hyp_syllogism|CONF|K|proof_term|
1659_proof_natural_deduction|CONF|K|proof_term|
1660_proof_conjunction|CONF|K|proof_term|
1661_proof_disjunction|CONF|K|proof_term|
1662_proof_negation|CONF|K|proof_term|
1663_proof_classical_nested|CONF|K|proof_term|
1664_proof_first_order|CONF|K|proof_term|
1665_proof_equality_leibniz|CONF|K|proof_term|
1666_self_atlas|CONF|K|self_atlas|
1667_self_atlas_real|CONF|K|self_atlas,self_atlas_data|
1668_self_atlas_lens|CONF|K|self_atlas,self_atlas_lens|
1669_self_atlas_report|CONF|K|self_atlas_data,self_atlas_lens|
1670_ripple_extract_selfmodel|CONF|K|ripple_extract,self_atlas,self_atlas_data|
1671_self_dormancy|CONF|K|capability,fs,self_atlas,self_atlas_lens|
1672_self_report|CONF|K|capability,fs,self_atlas,self_report|
1673_self_cartographer|CONF|ORPHAN-REF|alpha,beta,capability,fs|MISSING:alpha+MISSING:beta
1674_self_emit|CONF|K|capability,fs,self_atlas,self_emit|
1700_beam_search|CONF|K|beam_search,verified_search|
1701_lemma_forge|CONF|K|lemma_forge,theorem_grow|
1702_search_market|CONF|K|search_market|
1703_cegar_refine|CONF|K|cegar_refine|
1704_egraph_hw_ematch|CONF|K|egraph_hw_ematch|
1705_proof_replay_cache|CONF|K|proof_replay_cache,typecheck|
1706_proof_parallel|CONF|K|proof_parallel|
1707_proof_jit|CONF|K|proof_jit|
1708_proof_stark|CONF|K|cad,proof_stark|
1709_aeu_kernel|CONF|K|aeu_kernel|
1710_evidence_calculus|CONF|K|evidence_calculus|
1711_perception_membrane|CONF|K|capability,perception_membrane|
1712_quantize_sensor|CONF|K|quantize_sensor|
1713_perceptual_proposer|CONF|K|perceptual_proposer|
1714_provisional_universe|CONF|K|capability,provisional_universe|
1715_sample_beacon|CONF|K|cad,capability,sample_beacon|
1716_distribution|CONF|K|capability,distribution|
1717_infer_exact|CONF|K|infer_exact|
1718_markov_exact|CONF|K|markov_exact|
1719_mc_certified|CONF|K|capability,infer_exact,mc_certified|
1720_belief_sheaf|CONF|K|belief_sheaf|
1721_bayes_exact|CONF|K|bayes_exact|
1722_measure_status|CONF|K|measure_status|
1723_dp_exact|CONF|K|capability,dp_exact|
1724_infotheory|CONF|K|infotheory|
1725_approx_struct|CONF|K|approx_struct|
1726_rand_algo|CONF|K|capability,rand_algo|
1727_pctl|CONF|K|pctl|
1728_percept_infer|CONF|K|capability,percept_infer|
1729_bayes_search|CONF|K|bayes_search|
1730_causal_scm|CONF|K|causal_scm|
1731_pac_certify|CONF|K|pac_certify|
1732_autogenesis_consume|CONF|K|autogenesis,capability,theorem_grow|
1733_proposer_deepening|CONF|K|bayes_search,capability,fs,harmony_synth|
1734_ec384_on_curve|CONF|K|ec384,ecdsa_p384|
1735_observe_replay_source_id|CONF|K|observe|
1736_develop_up_ingress|CONF|K|capability,develop_up|
1737_shift_dream_adoption|CONF|K|cg_autocatalyst,sov_isa|
1738_hypervisor_entropy_seal|CONF|K|determinism_firewall,replay_box|
1739_zk_rev|CONF|K|zk_rev|
1740_cap_zkp|CONF|K|cap_zkp|
1741_xii_sort_meter|CONF|K-RETARGET|capability,compute_box,xii_sort_meter,xii_term|xii_sort_meter
1742_isa_macro_synth|CONF|K|isa_macro_synth|
1743_rsa_pss_544_roundtrip|CONF|K|arena,rsa|
1744_pq_quorum|CONF|K|pq_quorum|
1745_intent_disambiguate|CONF|K|disambiguate|
1746_intent_synthesis_attest|CONF|K|capability,crypt_ed25519,disambiguate,intent_attest|
1747_intent_egraph_lower|CONF|K|disambiguate,egraph,synthesis_bridge|
1748_autonomous_invention_demo|CONF|K|algo_synth,autogenesis,capability,cg_autocatalyst|
1749_invent_strength|CONF|K|invent|
1750_invent_crossover|CONF|K|invent|
1751_invent_reduction|SAT-DELEG|K|invent|
1752_logic6|CONF|K|logic6|
1753_invent_logic6|CONF|K|invent|
1754_present_newmath|CONF|K|invent,present|
1755_primweb|CONF|K|primweb|
1756_weave|CONF|K|weave|
1757_oneway_anatomy|CONF|K|primweb|
1758_reversible_iso|CONF|K|primweb|
1759_sha_structure|CONF|K|primweb|
1760_gil_cycle_validate|CONF|K|invent|
1761_sha_optform|CONF|K|primweb|
1762_weave_arx|CONF|K|weave_blocks|
1763_weave_interfile|SAT-DELEG|K|weave_interfile|
1764_weave_forge|SAT-DELEG|K|weave_forge|
1765_weave_oneeval|CONF|K|bv_bits,invent,weave_blocks|
1766_weave_invent|CONF|K|bv_bits,invent,weave_blocks|
1767_present_weave|CONF|K|present|
1768_weave_totality|CONF|K|bv_bits,weave_blocks|
1769_weave_fill|CONF|K|invent|
1770_weave_commons|CONF|K|present|
1771_weave_commons_persist|CONF|K|capability,fs,present|
1772_weave_strand_discover|CONF|K|invent|
1773_weave_selflaw_discover|CONF|K|invent|
1774_weave_endtoend|CONF|K|capability,fs,present|
1775_weave_adopt|CONF|K|invent|
1776_weave_ratchet|CONF|K|invent|
1777_weave_federate|CONF|K|capability,fs,present|
1778_weave_algebra|CONF|K|invent|
1779_weave_census|CONF|K|invent|
1780_weave_ratchet_persist|CONF|K|capability,fs,invent|
1781_weave_ratchet_live|CONF|K|invent,present|
1782_weave_axioms|CONF|K|invent|
1783_weave_conjecture|CONF|K|invent|
1784_weave_conjecture3|CONF|K|invent|
1785_weave_conjecture_commons|CONF|K|capability,fs,present|
1786_weave_self|CONF|K|self_atlas,weave_self|
1787_weave_self_systemwide|CONF|K|self_atlas,self_atlas_data,self_atlas_lens,weave_self|
1788_weave_self_commons|CONF|K|capability,fs,present,self_atlas_data|
1789_weave_ripple|CONF|K|self_atlas,self_atlas_data,weave_self|
1790_weave_graph|CONF|K|weave_graph|
1791_weave_graph_fill|CONF|K|capability,fs,present|
1792_weave_cost_select|CONF|K|weave_graph|
1793_weave_i_bridge|CONF|K|weave|
1794_weave_self_oracle|CONF|K|self_atlas,weave_self|
1795_weave_fullness|CONF|K|weave_graph|
1796_weave_melt|CONF|K|bv_bits,weave_graph|
1797_weave_toffoli|CONF|K|weave_graph|
1798_weave_explosion|CONF|K|weave_graph|
1799_invent_loop|CONF|K|invent_loop|
1800_bb_intern|CONF|K|bv_bits|
1801_bb_struct_equal|CONF|K|bv_bits|
1802_logic6_leaves|CONF|K|bv_bits|
1803_invent_canonical|CONF|K|invent_loop|
1804_weave_genesis|CONF|K|bv_bits,weave_graph|
1805_weave_emit|CONF|K|bv_bits,weave_graph|
1806_weave_persist|CONF|K|bv_bits,weave_graph|
1807_weave_metric|CONF|K|bv_bits,weave_graph|
1808_invent_genesis_arm|CONF|K|bv_bits,invent_loop,weave_graph|
1809_weave_minimize|CONF|K|bv_bits,weave_graph|
1810_weave_synth_n4|CONF|K|bv_bits,weave_graph|
1811_weave_certify|CONF|K|bv_bits,weave_graph|
1812_gx_bridge|CONF|K|bv_bits,gx_bridge,weave_graph|
1813_cpu_census|CONF|K|cpu_census,cpufeat|
1814_pci_enum|CONF|K|census,pci_enum|
1815_quine6|CONF|K|quine6|
1816_voice|CONF|K|voice|
1817_crystal_cap|CONF|K|crystal_cap|
1818_stage|CONF|K|stage|
1819_behavioral_seed|CONF|K|behavioral_seed|
1820_behavioral_fp|CONF|K|behavioral_fp|
1821_descent_proof|CONF|K|descent_proof|
1822_tense|CONF|K|tense|
1823_metal_arch_capstone|CONF|K|behavioral_fp,behavioral_seed,crystal_cap,descent_proof|
1824_weave_reduce|CONF|K|bv_bits,invent|
1825_i_crossmode|CONF|K|bv_bits,logic6,quine6,voice|
1826_skeleton_key|CONF|K|bv_bits,logic6,voice|
1827_algebraic_bridge|CONF|K|bv_bits,logic6|
1828_categorical_bridge|CONF|K|bv_bits|
1829_grail_boolean|CONF|K|bv_bits|
1830_grail_xii|CONF|K|xii_termination|
1831_grail_quantum|CONF|K||
1832_grail_mucalculus|CONF|K||
1833_grail_linear|CONF|K||
1834_grail_csl|CONF|K||
1835_grail_temporal|CONF|K||
1836_grail_typetheory|CONF|K||
1837_grail_latticerep|CONF|K||
1838_grail_mucalculus_full|CONF|K||
1839_grail_parity_solver|CONF|K||
1840_grail_strategy_improvement|CONF|K||
1841_grail_vj_strategy_improvement|CONF|K||
1842_grail_lrc_strategy_improvement|CONF|K||
1843_grail_small_progress_measures|CONF|K||
1844_grail_bounded_dominion|CONF|K||
1845_grail_tri_solver_crossval|CONF|K||
1846_grail_combined_partial_solver|CONF|K||
1847_grail_groebner_parity|CONF|K|arena,bigint,groebner|
1848_grail_control_blindness_barrier|CONF|K||
1849_grail_positional_determinacy|CONF|K||
1850_grail_oneplayer_tractable_edge|CONF|K||
1851_grail_metagrail_obstruction|CONF|K||
1852_grail_control_blindness_quantitative|CONF|K||
1853_grail_mucalculus_equivalence|CONF|K||
1854_grail_fixpoint_foundation|CONF|K||
1855_grail_meanpayoff_weight_obstruction|CONF|K||
1856_grail_positional_is_parity_specific|CONF|K||
1857_grail_bounded_priority_island|CONF|K||
1858_grail_priority_compression_invalid|CONF|K||
1859_grail_partial_solver_residue|CONF|K||
1860_grail_np_conp_intermediacy|CONF|K||
1861_grail_ctl_mu_embedding|CONF|K||
1862_grail_characteristic_firewall|CONF|K||
1863_grail_sat_2sat_island|CONF|K||
1864_grail_sat_horn_island|CONF|K||
1865_grail_sat_xor_island|CONF|K||
1866_grail_sat_np_selfreducible|CONF|K||
1867_grail_sat_schaefer_census|CONF|K||
1868_grail_confluence_newman_island|CONF|K||
1869_grail_confluence_newman_boundary|CONF|K||
1870_grail_gi_tree_island|CONF|K||
1871_grail_gi_wl_boundary|CONF|K||
1872_grail_gi_np_higherorder|CONF|K||
1873_grail_lattice_con_v4_m3|CONF|K||
1874_grail_lattice_partition_substrate|CONF|K||
1875_grail_primality_fell_to_p|CONF|K||
1876_grail_factoring_open_twin|CONF|K||
1877_grail_commcomplexity_climbed|CONF|K||
1878_grail_ramsey_r33|CONF|K||
1879_grail_constructibility_galois|CONF|K||
1880_grail_goodstein_independence|CONF|K||
1881_grail_hilbert10_no_oracle|CONF|K||
1900_event_substrate_poc|CONF|K||
1901_event_substrate_infinitary|CONF|K|event_substrate|
1902_event_substrate_parity|CONF|K|event_substrate,parity_game|
1903_event_rewind|CONF|K|event_substrate|
1906_xii_inverse_real|CONF|K|cad,xii_rewrite,xii_term|
1907_coverage_closure|CONF|K|bv_bits,cpu_census,gx_bridge,intent|
1908_xii_canon_cert|CONF|K|cad,exec_cert,xii_canonicalise,xii_term|
1910_grail_logic_web|CONF|K|cad,exec_cert|
1913_isub_cav|CONF|K|cad,isub|
1914_xii_encapsulated|CONF|K|cad,isub,xii_isub,xii_rewrite|
1915_unravel_geometry|CONF|K|isub,unravel,xii_isub,xii_term|
1916_grail_assimilate|CONF|K|assimilate,isub|
1917_reverse_search|CONF|K|assimilate,isub,reverse_search|
1918_master_logic_subsume|CONF|K|isub,master_logic|
1919_audit_compression|CONF|K|assimilate,isub|
1920_audit_nameless_race|CONF|K|assimilate,cad,exec_cert,isub|
1921_audit_cross_domain|CONF|K|assimilate,isub|
1922_audit_evasion_gap|CONF|K|assimilate,isub,reverse_search|
1923_pipeline_real|CONF|K|assimilate,ingest,isub,unravel|
1924_enmesh_two_real|CONF|K|assimilate,enmesh,isub,logic6|
1925_enmesh_trit|CONF|K|assimilate,enmesh,isub,trit|
1926_canon_coincide|CONF|K|assimilate,canon_enmesh,isub,trit|
1927_law_web|CONF|K|law_web|
1928_reduced_product_bridge|CONF|K|assimilate,isub,reduced_product|
1931_eidos_ripple_unify|CONF|K|cad,ripple,ripple_field|
1932_eidos_ripple_teeth|CONF|K|cad,ripple,ripple_field|
1933_eidos_compose_modeless|CONF|K|cad,compose,cost_lattice|
1934_eidos_compose_teeth|CONF|K|compose,cost_lattice|
1935_eidos_compose_optimal|CONF|K|compose,cost_lattice|
1936_eidos_weave_real|CONF|K|cad,cost_lattice,ripple,ripple_field|
1937_eidos_weave_subadditive|CONF|K|xii_savings|
1938_eidos_optgate_real|CONF|K|bv_bits,invent,optgate|
1939_eidos_route_real|CONF|K|route,topology_atlas|
1940_eidos_descriptor_real|CONF|K|assimilate,cad,descriptor,isub|
1941_eidos_descriptor_trace|CONF|K|assimilate,cad,descriptor,ingest|
1942_eidos_descriptor_remap|CONF|K|assimilate,descriptor,isub|
1943_eidos_capstone|CONF|K|assimilate,cad,descriptor,ingest|
1944_eidos_anchor_real|CONF|K|anchor,cad|
1945_eidos_orchestrate_real|CONF|K|anchor,orchestrate|
1946_eidos_orchestrate_crosshost|CONF|K|anchor,cpufeat,orchestrate|
1947_eidos_field_real|CONF|K|field|
1948_gil_reducible_sweep|CONF|K|invent|
1980_eidos_accessor_coverage|CONF|K|compose,ripple,weave|
1981_eidos_coincidence|CONF|K|assimilate,coincidence,ingest,isub|
1982_eidos_memo_real|CONF|K|bv_bits,coincidence,memo|
1983_weave_adopt_memo|CONF|K|coincidence,invent,memo|
1984_gil_search_memo|CONF|K|bv_bits,coincidence,invent,memo|
1985_eidos_display|CONF|K|canvas,capability,cli,isub|
1986_eidos_layout|CONF|K|capability,layout,self_atlas,self_cartographer|
1987_eidos_web|CONF|K|canvas,capability,isub,palette|
1988_eidos_web_plan|CONF|K|assimilate,canvas,capability,descriptor|
1989_eidos_web_weave|CONF|K|canvas,capability,isub,ripple_field|
1990_eidos_web_route|CONF|K|canvas,capability,route,topology_atlas|
1991_eidos_web_intensity|CONF|K|canvas,capability,isub,web|
1992_eidos_web_temporal|CONF|K|canvas,capability,isub,web|
1993_eidos_cli_run|CONF|K|capability,cli|
2000_eidos_field|CONF|K|canvas,capability,self_atlas,self_cartographer|
2001_eidos_cli|CONF|K|capability,cli|
2002_cg_opt_rules_certified|CONF|K|cg_opt_rules|
2003_xii_route_r_teeth|CONF|K|xii_joinability|
2004_seraphyte_kvalue|CONF|K|ser_kvalue|
2005_seraphyte_energy|CONF|K|ser_energy|
2006_seraphyte_membrane|CONF|K|ser_membrane|
2007_seraphyte_autopoiesis|CONF|K|ser_autopoiesis|
2008_seraphyte_real|CONF|K|ser_real|
2009_seraphyte_commit|CONF|K|ser_commit|
2010_seraphyte_discover|CONF|K|ser_discover|
2011_seraphyte_optimize|CONF|K|ser_optimize|
2012_seraphyte_isub|CONF|K|ser_isub|
2012_zk_air_mal_cp|CONF|K|ntt_fri_organ,zk_air|
2013_seraphyte_immune|CONF|K|ser_immune|
2014_seraphyte_diff|CONF|K|ser_diff|
2015_seraphyte_memo|CONF|K|ser_memo|
2016_seraphyte_subk_discover|CONF|K|bv_bits,bv_ring,cg_opt_rules|
2017_seraphyte_subk_runtime|CONF|K||
2018_seraphyte_petri_membrane|CONF|K|bv_ring,ser_petri|
2019_seraphyte_cegis_synth|CONF|K|bv_ring,ser_cegis|
2020_seraphyte_antiunify|CONF|K|ser_antiunify|
2021_seraphyte_absint|CONF|K|bv_ring,ser_absint|
2022_seraphyte_cascade|CONF|K|ser_cascade|
2023_seraphyte_cascade_fixpoint|CONF|K|mcmc_egraph,ser_cascade,ser_cascade2|
2024_seraphyte_regalloc|CONF|K|ser_regalloc|
2025_seraphyte_egraph|CONF|K|ser_egraph|
2026_seraphyte_intent|CONF|K|ser_intent|
2027_seraphyte_cor_accessors|CONF|K|cg_opt_rules|
2028_seraphyte_field_axioms|CONF|K|zk_ext2,zk_ext4|
2029_seraphyte_air_constraint|CONF|K|zk_air,zk_ext2|
2030_seraphyte_tgraph|CONF|K|ser_tgraph,temporal_logic|
2031_seraphyte_kinduct|CONF|K|ser_kinduct|
2032_seraphyte_causal|CONF|K|ser_causal|
2033_seraphyte_tdriver|CONF|K|ser_tdriver|
2034_seraphyte_kinduct_sym|CONF|K|ser_kinduct_sym|
2035_seraphyte_eidos|CONF|K|ser_eidos|
2036_seraphyte_pipeline|CONF|K|ser_pipeline|
2037_seraphyte_2shift|CONF|K|cg_opt_rules|
2038_seraphyte_2sub|CONF|K|cg_opt_rules|
2039_eidos_fsm|CONF|K|ser_fsm|
2040_eidos_kinduct_general|CONF|K|ser_fsm,ser_kinduct|
2041_eidos_tgraph_general|CONF|K|ser_tgraph,temporal_logic|
2050_eidos_egraph_synth|CONF|K|ser_egraph|
2051_eidos_synth_proof|CONF|K|ser_egraph|
2052_eidos_synth_exec|CONF|K|ser_egraph|
2053_eidos_palindrome|CONF|K|ser_egraph|
2054_eidos_palindrome_substrate|CONF|K|event_substrate,ripple|
2055_eidos_causal_substrate|CONF|K|ser_causal|
2056_eidos_tgraph_substrate|CONF|K|event_substrate,ser_tgraph,temporal_logic|
2057_eidos_kinduct_causal|CONF|K|ser_causal,ser_kinduct|
2060_eidos_model_checking|CONF|K|ser_kinduct,ser_protocol,ser_tgraph|
2061_div_strength_reduction|CONF|K||
2062_egraph_mul_plan|CONF|K|ser_egraph|
2063_egraph_div_magic|CONF|K|ser_egraph|
2064_kinduct_general|CONF|K|bv_bits,ser_kinduct_sym|
2065_invariant_pipeline|CONF|K|bv_bits,ser_antiunify,ser_kinduct_sym,ser_petri|
2066_invsynth_full|CONF|K|bv_bits,ser_antiunify,ser_kinduct_sym,ser_petri|
2067_kinduct_coverage|CONF|K|bv_bits,ser_antiunify,ser_kinduct_sym,ser_petri|
2068_kinduct_extensions|CONF|K|bv_bits,ser_kinduct_sym|
2069_svir_equiv_mod|CONF|K|ser_kinduct_sym|
2070_invsynth_modular|CONF|K|bv_bits,ser_antiunify,ser_kinduct_sym,ser_petri|
2071_svir_branch_equiv|CONF|K|ser_kinduct_sym|
2072_svir_loop_equiv|CONF|K|bv_bits,ser_kinduct_sym|
2073_invsynth_conservation|CONF|K|bv_bits,ser_antiunify,ser_kinduct_sym,ser_petri|
2074_consv_memory_seal|CONF|K|heaplet,sep_logic,ser_kinduct_sym|
2080_ui_raster|UI|K|ui_raster|
2081_ui_exact|UI|K|ui_exact|
2082_ui_font|UI|K|ui_font,ui_font_data|
2083_egraph_walk|CONF|K|ser_egraph|
2084_disjoint|CONF|K|ser_absint|
2085_morphic_denote|CONF|K|bv_bits,ser_kinduct_sym|
2086_bitblast_walk|CONF|K|bv_bits|
2087_conservation|CONF|K|ser_kinduct_sym|
2088_frp_kinematics|TOPO|K-FIXDEP|ser_antiunify|volatile-note
2089_constraint_layout|TOPO|K-FIXDEP|bv_bits|volatile-note
2090_topological_field|TOPO|K-FIXDEP||volatile-note
2091_association_invariant|TOPO|K-FIXDEP|ser_antiunify,ser_petri|volatile-note
2092_raster_crush|TOPO|K-FIXDEP|ser_antiunify|volatile-note
2093_pixel_crush|TOPO|K-FIXDEP|ser_antiunify|volatile-note
2094_constraint_solver|CONF|K|smt|
2095_exact_coverage|UI|K|ui_exact|
2096_proven_display|CONF|K|smt|
2097_exact_aa|UI|K|ui_exact|
2098_exact_aa_poly|UI|K|ui_exact|
2099_exact_bezier|UI|K|ui_exact|
2100_biquad_coverage|UI|K|ui_exact|
2101_hausdorff_dim|UI|K|ui_exact|
2102_cover2d|UI|K|ui_exact|
2103_bsign_big|BIGCOV|K|ui_exact_big|
2104_field_kolmogorov|FIELD|K|ui_field|
2105_field_color|FIELD|K|ui_field|
2106_field_time|FIELD|K|ui_field|
2107_field_inverse|FIELD|K|ui_field|
2108_field_slice|FIELD|K|ui_field|
2109_field_quantum|FIELD|K|ui_field|
2110_field_acoustic|FIELD|K|ui_field|
2111_field_reversible|FIELD|K|ui_field|
2112_field_localweb|FIELD|K|ui_field|
2113_field_selfpop|FIELD|K|ui_field|
2114_field_cf|FIELD|K|ui_field|
2115_field_wave|FIELD|K|ui_field|
2116_field_hash|FIELD|K|ui_field|
2117_field_superpos|FIELD|K|egraph|
2118_field_binding|FIELD|K|egraph,ui_field|
2120_bigint_isqrt|SQRT|K|arena,bigint,sqrt_sum_sign|
2121_sqrt_sum_sign|SQRT|K|sqrt_sum_sign,ui_exact_big|
2122_lazy_real|SQRT|K|sqrt_sum_sign|
2123_lazy3|SQRT|K|sqrt_sum_sign|
2124_transcendental|SQRT|K|sqrt_sum_sign|
2125_verb_geom|SQRT|K|egraph,verb_geom|
2126_involution|RIPPLE|K|involution|
2127_membrane|RIPPLE|K|crystal,involution,membrane|
2128_involution_closed|RIPPLE|K|crystal,involution,membrane|
2129_epoch|RIPPLE|K|epoch|
2130_disposers|RIPPLE|K|disposer,involution,logic6|
2131_reactor|RIPPLE|K|crystal,reactor|
2132_eidolon|RIPPLE|K|eidolon|
2132_mod_pow2|CONF|K||
2133_ripple_eidolon|RIPPLE|K|eidolon,involution,ripple_eidolon|
2134_planner|RIPPLE|K|eid_plan,eidolon,involution,ripple_eidolon|
2135_mul_subsume|CONF|K|ser_egraph|
2136_egraph_mod_magic|CONF|K|ser_egraph|
2137_adaptive_sign|SQRT|K|arena,bigint,sqrt_sum_sign|
2138_symmetry_quotient|SQRT|K|sqrt_sum_sign|
2139_padic_barrier|SQRT|K|sqrt_sum_sign|
2140_adaptive_big|SQRT|K|arena,bigint,sqrt_sum_sign|
2141_cyclotomic_rotation|SQRT|K|cyclotomic_se3|
2142_se3_screw|SQRT|K|cyclotomic_se3|
2143_traj_arclen|SQRT|K|arena,bigint,sqrt_sum_sign,traj_kinematics|
2144_lattice_pathfind|SQRT|K|arena,bigint,traj_kinematics|
2145_denest|SQRT|K|exact_denest|
2146_compactor|SQRT|K|arena,bigint,traj_kinematics|
2147_lattice_oracle|SQRT|K|arena,bigint,traj_kinematics|
2148_theorem_fuzzer|SQRT|K|coincidence,kfield|
2149_universal_block|SQRT|K|coincidence,kfield|
2150_csg_kernel|SQRT|K|csg_kernel,sqrt_sum_sign|
2151_photon_route|SQRT|K|arena,bigint,photon_route,traj_kinematics|
2152_mechanism|SQRT|K|cyclotomic_se3,q23_sign,verb_geom|
2153_collision|SQRT|K|collide,cyclotomic_se3|
2154_delaunay|SQRT|K|delaunay|
2155_aether_lens|LENS|K|aether_lens,sqrt_sum_sign|
2156_sturm|SQRT|K|sturm|
2157_algnum|SQRT|K|algnum,sturm|
2158_aether_lens_render|LENS|K|aether_lens,aether_lens_frame|
2159_kf_weld|SQRT|K|exact_surd_value,kfield,sqrt_sum_sign|
2160_bigint_supersedes_i64|CONF|K|ui_exact,ui_exact_big|
2161_exact_sign_escalation|CONF|K|ui_exact,ui_exact_big|
2162_curve_coverage_sym|CONF|K|region,ui_exact,ui_exact_sym|
2163_curve_coverage_trange|CONF|K|ui_exact,ui_exact_sym|
2165_dome_full|CONF|K|ui_exact,ui_exact_sym|
2166_cover_bigcoeff|CONF|K|ui_exact_bigcov,ui_exact_sym|
2167_billiard_reversal|CONF|K|billiard,verb_geom|
2168_csg_tree|CONF|K|csg_tree|
2169_gas_reversal|CONF|K|gas,verb_geom|
2169_studio_kernel|CONF|K|studio_trig,wb_kernel|
2170_swept_leaf|CONF|K|csg_tree|
2171_lattice_march|CONF|K|lattice_march|
2172_constraint|CONF|K|constraint,delaunay,sturm|
2173_cspace|CONF|K|cspace,verb_geom|
2300_zk_fused_perm_seedrig|CONF|K|keccak256,merkle,ntt_fri_organ,zk_air|
2174_gas_demon|CONF|K-NEW|gas,verb_geom|landed mid-audit; register in family runner/EXPECTED + commit
2175_arc_sweep|CONF|K-NEW|arc_sweep,cspace,verb_geom|landed mid-audit; register + commit
```
