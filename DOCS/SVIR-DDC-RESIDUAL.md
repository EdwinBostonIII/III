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
iiis-0 — the diverse-toolchain prerequisite the original residual lacked. NOT yet closed: the **DDC chain itself** —
`iiis-0_msvc → iiis-1 → iiis-2`, compared **byte-for-byte** to the gcc-lineage reference `iiis-2`. Agreement there
is the actual proof that the gcc-built seed carries no Thompson backdoor. The hard prerequisite (build the seed with
a diverse toolchain) is done; the chain run + comparison is the next step, and it is now a tractable, gated task
rather than "we lack any independent compiler." This is genuine progress from "frontend closed" toward "root
closed" — stated precisely, not as a headline.
