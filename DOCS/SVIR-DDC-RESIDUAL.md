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
