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

**Result: ~50 diverse programs, two independent compiler lineages, IDENTICAL object code, zero divergence —
reproducible, exit 0.** This is precisely "the seed compiled by an independent toolchain and the outputs verified
byte-for-byte": **the gcc-built seed carries no output-altering Thompson backdoor that MSVC's lineage does not also
carry.** The deepest residual hurdle — a *seed* backdoor invisible to frontend agreement — is now directly tested
and refuted at the iiis-0 → iiis-1 codegen step, across a wide, diverse witness set (an attacker's backdoor would
have to be byte-invisible across all ~50 programs *and* present identically in both gcc and MSVC lineages).

**Honest remaining scope (precise, not a headline).** (1) This proves the codegen step at the `.o` level for all
ported TUs; the *link* into `iiis-1.exe` and the further `iiis-1 → iiis-2` rung are deterministic given identical
`.o`, so the substantive proof is the object agreement — but a full chain-to-`iiis-2` byte-compare is the natural
next gate. (2) DDC's premise stands: MSVC must not be backdoored *identically* to gcc (independent lineages make
this implausible, which is the whole point). (3) The irreducible TCB — CPU/microcode, OS loader — is never
DDC-removable; the achievable end state is the smallest practical TCB, and this shrinks it by removing the
*compiler-lineage* trust. This is real movement from "frontend closed" to "the seed's codegen is independently
witnessed byte-for-byte" — stated precisely.
