# SVIR DDC — what is closed, and what is NOT (the honest residual)

The DDC frontend-closure gate (`STDLIB/sovir/run_ddc.sh`) is green: two emitters with genuinely different
internal algorithms — `iiisv` (recursive precedence-climbing) and `iiisv2` (explicit shunting-yard) — emit
**byte-identical** canonical SVIR for every real program, both verifier-accepted, both still running to 99 on
x86 (sovereign) and WASM. This page states precisely what that does and does not prove, because over-claiming a
trust property is the one failure this whole architecture exists to prevent.

## What IS closed

**Frontend implementation diversity.** A backdoor introduced into *one* emitter's lowering — that is absent from
the other — changes its output bytes, so the `cmp` reddens and the gate fails. Two independent implementations of
the same canonical encoding (`DOCS/SVIR-V1-CANONICAL.md`) agreeing byte-for-byte is the genuine shape of Diverse
Double-Compiling at the frontend: diversity in *implementation*, convergence in *output*. This is real, and it is
gated, not asserted.

## What is NOT closed (named, not hidden)

1. **The seed.** Both `iiisv` and `iiisv2` are *compiled* by `iiis-2`, whose lineage descends from the gcc-built
   `iiis-0` seed. A Thompson-style backdoor living in that shared seed would be injected into **both** emitter
   binaries identically — their outputs would still match, and the gate would stay green. Frontend agreement
   cannot see a seed backdoor. Closing this requires an **audited seed** (a minimal, hand-verifiable bootstrap)
   or a **genuinely diverse build toolchain** for the emitters. This is the deepest remaining hurdle (Phase 6).

2. **Author diversity.** Both emitters were written by the same author in the same session. They differ in
   *algorithm* (precedence-climbing vs shunting-yard), which catches a class of implementation-divergent bugs and
   demonstrates the **mechanism** — but a backdoor an author would place in one, they could place in both. Real
   social DDC needs **independent authorship/teams** writing to the same canonical spec. What is delivered here is
   the *mechanism* (canonical spec + N implementations + byte-identical gate), ready for independent parties to
   plug a third emitter into.

## The honest verdict

This phase moves SVIR from "one frontend you must trust" to "a frozen canonical encoding + a small auditable
verifier + two independent implementations that provably agree." That is a real, gated step toward supply-chain
sovereignty. It is **not** "Thompson defeated" — that headline requires the seed closed and independent
authorship. Both are named here as the remaining work, and the mechanism built here is exactly what they slot
into.

---

## UPDATE (2026-06) — the "genuinely diverse build toolchain" is FOUND, and the seed builds under it

Residual item #1 above names the deepest hurdle: closing the seed needs *"a genuinely diverse build toolchain"*
for the bootstrap — a compiler **not** descended from the gcc that built iiis-0, so a Thompson backdoor in gcc
cannot ride identically into the comparison. **That toolchain is present on the host: MSVC `cl.exe`** (Microsoft's
compiler, an independent lineage from gcc/mingw).

**Status: the independent CC2 is built and runs.** `COMPILER/BOOT/build_iiis0_msvc.sh` compiles the full iiis-0 TU
set (same filter as `build_iiis0.sh`) with MSVC and links a working `iiis-0_msvc.exe` (prints its real Stage-0 CLI,
rc=0). Reproducible, FAIL=0 across all 19 TUs.

**Seed footprint = one gcc-byte-identical rename.** The seed source is unchanged except a single local variable in
`cg_r3.c` (`cdecl` → `callee_decl`; `cdecl` is an MSVC reserved word). Verified: gcc's `.o` of `cg_r3.c` is
**bit-identical** before/after (same `-frandom-seed`), so the gcc reference build and its `iiis-0.mhash` golden are
untouched. The other two MSVC quirks are carried as **build flags, never source edits** — `/std:c11`
(`_Static_assert` in `sid.c`) and `/Dpopen=_popen /Dpclose=_pclose` (POSIX pipe spelling in `emit.c`). A
source-level `#ifdef` shim was tried and **rejected** because adding lines shifts `__LINE__` and reddens the
byte-identity gate — build-flag portability is invisible; source shims are not. The seed stays frozen.

**What this closes, and what it does NOT (yet).** CLOSED: an *independent-lineage* compiler now produces a working
iiis-0 — the diverse-toolchain prerequisite the original residual lacked.

**THE DDC SWEEP — DONE at the `.o` level (gated).** `COMPILER/BOOT/seed_ddc_msvc.sh` compiles `.iii` sources with
BOTH seeds (`COMPILED/iiis-0.exe` gcc-lineage and `build/_msvcddc/iiis-0_msvc.exe` MSVC-lineage), `--compile-only`,
and byte-compares the object output, in two phases:
- **CHAIN** — every iiis-1 ported source (the TUs `iiis-1` itself is built from): **23/23 byte-identical, 0 diverged.**
- **BROAD WITNESS** — every other reachable `.iii` (BOOT + STDLIB/sovir): **50/50 byte-identical, 0 diverged**
  (7 unsupported by the minimal stage-0 seed, legitimately — not divergences).
- *(2026-07-04 re-run: the reachable witness set has grown with the tree — now **105/105 byte-identical,
  0 diverged** (8 unsupported); rc=0. The closure tracks the living tree, not a frozen snapshot.)*

**Result: ~50 diverse programs, two independent compiler lineages, IDENTICAL object code, zero divergence —
reproducible, exit 0.** This is precisely "the seed compiled by an independent toolchain and the outputs verified
byte-for-byte": **the gcc-built seed carries no output-altering Thompson backdoor that MSVC's lineage does not also
carry.** The deepest residual hurdle — a *seed* backdoor invisible to frontend agreement — is now directly tested
and refuted at the iiis-0 → iiis-1 codegen step, across a wide, diverse witness set (an attacker's backdoor would
have to be byte-invisible across all ~50 programs *and* present identically in both gcc and MSVC lineages).

## UPDATE (2026-07-04) — item 1a CLOSED: the binary-level DDC is now byte-for-byte

The build non-determinism that confounded the whole-binary compare is fixed in `build_iiis1.sh`
by exactly the two leaks this doc predicted plus their measured repair:

- **Path-form mismatch**: gcc-on-Windows records `__FILE__`/debug paths in the MIXED form
  (`C:/Users/...`) while the prefix-maps carried only the msys form (`/c/Users/...`) — on this
  spaced host path the mixed-form strings never matched a map key. Fix: map both forms
  (`cygpath -m` variants added).
- **PE clock leak**: the link carried no `--no-insert-timestamp`; the COFF/export TimeDateStamps
  took the wall clock. Fix: `-Wl,--no-insert-timestamp`.

**Measured (2026-07-04):**
- Same-seed determinism: two back-to-back `build_iiis1.sh` runs → **BYTE-IDENTICAL** iiis-1.exe
  (previously 425 varying bytes under the same reproducible env).
- **Cross-lineage whole-binary DDC**: iiis-1 built with the gcc-lineage seed vs the MSVC-lineage
  seed (`IIIS0=build/_msvcddc/iiis-0_msvc.exe`, env override added) → **BYTE-IDENTICAL**. The
  claim this section could previously make only at the `.o` level now holds for the ENTIRE
  stage-1 compiler binary: a seed-lineage backdoor would have to produce identical whole-binary
  bytes through two unrelated compiler lineages.
- Functional sanity: the deterministic binary builds OK; the `--check-corpus` twin gate shows the
  SAME 33/27 verdict as the unmodified script (verified side-by-side) — that red is the separate,
  deliberate `58_udiv_highbit` falsifier tracking the cg_r3.c seed-emitter backport, not a
  determinism artifact.

Remaining after this update: **author-diversity** (item 2) and the irreducible TCB (item 3) only.

**Honest remaining scope (precise, not a headline — 2026-06 text, item 1a since closed above).** (1) The rigorous proof is at the **`.o` level** — fixed
output paths, back-to-back per-source compiles, so it is drift- and timestamp-clean. (1a) A **full `iiis-1.exe`
binary** comparison was attempted and found **confounded by build non-determinism in this environment, not by any
seed divergence**: two *same-seed* `build_iiis1.sh` runs produce *different* binaries even under the reproducible
env (`SOURCE_DATE_EPOCH=0` …), because the space in the host path breaks `-ffile-prefix-map` and PE
timestamps/temp-dir paths leak into the link. The *seed-dependent* inputs — the `.iii.o` — are proven byte-identical
across lineages (re-confirmed by a live drift-check), so the binary variance is a pre-existing build-reproducibility
issue (the project's own `iiis-1.mhash` golden is flaky in this env for the same reason), **independent of the DDC
question.** Fixing that reproducibility (normalize the path map / strip the PE timestamp) would make the binary-level
DDC clean too; until then the `.o`-level agreement plus the link-determinism *property* (which reproducible builds
are supposed to provide) is the precise claim. (2) DDC's premise stands: MSVC must not be backdoored *identically* to
gcc (independent lineages make this implausible, which is the whole point). (3) The irreducible TCB — CPU/microcode,
OS loader — is never DDC-removable; this shrinks it by removing the *compiler-lineage* trust. This is real movement
from "frontend closed" to "the seed's codegen is independently witnessed byte-for-byte" — stated precisely, with the
binary-level confound named rather than papered over.
