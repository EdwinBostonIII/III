# III-WHOLE-TREE-SWEEP — every file verified by execution (2026-07-02)

**Order:** every file, made to do what it is supposed to do, one file at a time, no stopping.
**Operationalization:** "supposed to do" = each file's own gate, runner, or named consumer; the
proof is exit codes measured without pipes, never prose. Tests are the discipline, not the
deliverable — this document records what was found and fixed, and what now runs.

**Denominator:** 4370 tracked files — 1820 core corpus KATs, 809 STDLIB/iii organs, 99 COMPILER
.iii, 52 scripts (incl. the sibling session's build_mech.sh), runners, docs, seals, artifacts.

## What was found and fixed (four fix commits, every red measured to root cause first)

**`bc297a83` — 2 orphans of 809 organs.** ui_egraph_app.iii (atlas shell) and ui_topo.iii
(topo.exe shell): live root executables whose sources no script named — silent-rot risk. Wired
into run_ui_kats' compile gate (+ ui_egraph); extended gate 13/0.

**`b6e924b7` — 5 structural-gate reds.**
- verify_h2_one_address: zk_air's Fiat–Shamir binding + erasure_store's 2 shard content-addresses
  called keccak256 directly. Repointed to cad_oneshot(KECCAK) — byte-identical; H2 HOLDS.
- verify_sha256_dedup: flagged sovir/sha256.c — but sovir/ is the ccsv C-compiler test corpus
  (input-under-test, never linked). Excluded, same class as the gate's BOOT carve-out.
- fast_check hygiene: root-litter BMPs traced to the aether runner passing repo-root as 2158's
  WORKDIR — the gate littered the root itself. Renders now land in build/aether.
- cg_optrules_bind_gate ×2: cor_selftest measured 41s against a stale 30s budget (63-rule table);
  the x*6 negative expired when the certified shl+add family grew to cover 6=4+2 — replaced with
  x*19 (verified imul-no-shift today).

**`2165733e` — 8 core-corpus reds (the first full 1500–2499 pass in the tree's history).**
- 5× CWD coupling: the eidos atlas cohort walks the relative path "iii" — verdicts depended on the
  invoker's directory. KATs 1985/1986/2000 + the cli dispatcher (1993/2001) now probe STDLIB/iii
  and fall back; verified 99/99 from both directories.
- 2× stale pins: 2025/2026 pinned optimizer costs from before the landed imul re-price
  (EG_MUL=4). Actual values measured first; only the naive-multiply values moved.
- 1754: gilr_proves' congruence judge — one bit-blast SAT solve on the k=32 Mersenne miter —
  exceeds the entire 600s budget on every kernel version buildable (multiplication has no small
  OBDD). Replaced with a bv_ring polynomial proof over the split substitution x := H·2^k + L
  (ring-universal ⟹ bit-split-universal; wrong multipliers still refuse). >600s → ~0s.

**`fcf09323` — the capstone's one swallowed red.** stage1_corpus reported FAIL=1 while the
capstone stayed green: 58_udiv_highbit was unregistered AND its verdict degenerate (returned
q+r = 2^63 → exit truncates to 0), AND the stage1 runner had no exit statement — always rc=0.
All three fixed; tooth verified (mis-registration now reddens rc=1).

## The record

- Core corpus: **1584 PASS / 0 FAIL** (capstone run; 5 development slices before it: 1576 PASS
  with the 8 reds fixed in between; SKIPs are family/XII-delegated, judged by their own gates).
- Families: XII 92/0 + antidrift; sqrtsum 69/0; field 20/0; stoma 14/0; ui 13/0; ripple 9/0;
  bigcov 7/0; topo 6/0; aether 3/0; bench 5/0 correctness; autogenesis + nous GREEN with their
  propose-only/differential gates; stage1 55/0.
- Negative/static gates 8/8 with rejection evidence; live-HTTP reach E2E exit 99.
- build_stdlib ×3 (after each organ change): FAIL = 0; ratchets uncovered 0≤0, under-proven 0≤2,
  dark-surface 1≤1. affine/onelang/sovereignty/seraphyte-goldtests/cone-selftest all rc=0.
- Ledgers: 809/809 organs and 52/52 scripts with named evidence verdicts.

## Traps recorded (so they are paid for once)

- A pipe swallows the rc (`gate | tail` reports tail's 0) — measure with `rc=$?` or a log file.
- A trailing `&` backgrounds the whole `&&` chain, commit included.
- Probes capped below the real budget mask marginal cases — 1754 needed the full-600s solo run.
- A red on an unmodified file during multi-session work: read the gate's own c.log in its
  /tmp/tmp.* dir before assuming a tree defect (2167 was a sibling's mid-edit snapshot).
- Runners without an exit statement return the last echo's 0 — a tally is not a verdict.

## Seal state (executed at tree quiescence, all measured)

- **Final aggregate** (all 15 runners under sound rc propagation, after the stage1 exit-hole fix):
  rc=0, runners=15 failed=0.
- **Twin-build determinism** (forced by the BOOT-class stage1 edits through seal_route):
  **BIT-IDENTICAL**; 810 modules sealed; SOURCES.mhash = CLOSURE re-pinned
  (9f111112785e0652…).
- **Cone ledger**: 2186_resultant_abi re-verified through its family (failures=0);
  `verify_cone --check` → **stale=0**.
- **world_graph.iii** regenerated from the quiescent tree: 810 nodes / 5402 edges (was 806/5368 —
  the sweep's and the sibling session's new organs entered), compiles rc=0, within caps.
