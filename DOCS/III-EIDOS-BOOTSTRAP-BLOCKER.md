# III EIDOS — Bootstrap Blocker: gcc-15.2.0 exposes a latent C-seed memory bug

**Status:** the e-graph work is complete and verified; the FULL bootstrap rebuild (which recompiles
the hand-written C seed `iiis-0`) is blocked by a toolchain-exposed latent bug — **not** by the e-graph work.

## What is proven (the change; each item proof-gated as stated)
- `cg_r3.iii` + `ser_egraph.iii`: the e-graph DRIVES cg_r3's mul-by-constant lowering (proof-gated by bv_ring),
  plus **magic-number division** (`seg_div_plan`, Granlund-Montgomery-bound-proven for all x).
- KAT `2062` (mul plan) and `2063` (magic div) pre-flight to **99** (forms classified + proven + executed).
- `soundness_falsifier.sh` **fires** (rc=7): removing the GM bound lets a wrong reduction escape → the gate is
  load-bearing, not vacuous.
- `build_stdlib` gate **GREEN** (729 KATs, FAIL=0, coverage/under-proven/dark-surface ratchets at pin) with the
  new `seg_mul_plan`/`seg_div_plan` exports.
- The **working committed iiis-0 compiles the e-graph-wired `cg_r3.iii`** (rc=0, 487 KB obj) — the e-graph lands
  through it without recompiling the seed.

## The blocker (diagnosed, isolated)
Rebuilding the C seed `iiis-0` with the current toolchain produces a binary that **infinite-loops compiling
`acc.iii`** (542 lines, deep recursion). Evidence, each a controlled test:

| Test | Result |
|---|---|
| committed iiis-0 (older gcc) on acc.iii | **rc=0** (works, 20 KB obj) |
| control iiis-2 (cg_r3.iii) on acc.iii | rc=0 (works) — so acc.iii is fine |
| rebuilt iiis-0 from **my** cg_r3.c on acc.iii | rc=124 HANG |
| rebuilt iiis-0 from **reverted/original** cg_r3.c | rc=124 HANG (so NOT my change) |
| rebuilt iiis-0 at **-O0** | rc=124 HANG (so NOT optimization-aggressive UB) |
| iiis-0 on a trivial module | rc=0 (so iiis-0 isn't globally broken) |
| only source diff vs HEAD | `cg_r3.c` (mine); `iii_compositions.h` regenerated **identically** |

**Conclusion:** same C source → different binary → hang. The variable is the **toolchain (gcc 15.2.0)**, which
exposes a latent memory bug in the hand-written C recursive-descent (`parse.c`/`sema.c`) — the layout-sensitive
`&local`/struct-spill clobber. The older-gcc committed binary's layout dodged it; every current build trips it
on acc.iii's deep recursion.

## Paths forward
1. **Land the e-graph through the committed seed (done here):** build iiis-1/2/3 from `cg_r3.iii` via the
   working committed iiis-0; byte-check (stage1) + iiis-2==iiis-3 fixpoint + run_corpus + objdump confirm the
   e-graph drives codegen. Phase 0's *seed-side* div fix is deferred (it needs a seed rebuild).
2. **Fix the C-seed bug (unblocks Phase 0 + a clean seed rebuild):** find the clobber via ASan/UBSan or the
   known `SHADOW_ON=0` / fixed-MTOP reentrancy site, then enable/repair it so the seed rebuilds under gcc 15.2.
   The `58_udiv_highbit` falsifier + the byte-identical `cg_r3.c` twin fix are ready to go green the moment the
   seed can be rebuilt.

`cg_r3.c`'s Phase-0 fix is kept in the source (byte-identical to `cg_r3.iii`'s split) — correct and ready; only
its *bootstrapping* is blocked.
