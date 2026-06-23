# Closing the DDC seed residual — analysis + procedure (honest)

The DDC frontend-closure (`run_ddc.sh`) closed *frontend* implementation diversity. The remaining residual is the
**seed**: `iiis-0` is built by gcc (`COMPILER/BOOT/build_iiis0.sh`, `CC=${CC:-gcc}`), and the whole self-host
lineage `iiis-0 → iiis-1 → iiis-2` descends from it. A Thompson "trusting trust" backdoor living in the gcc
backend would be injected into the compiler binaries and could survive — invisible to any check that uses the
same gcc. This page resolves *how* to close it, and states honestly *why it cannot be closed in this environment*.

## The procedure that closes it (Wheeler Diverse Double-Compiling)

1. Build `iiis-0` **twice**: once with gcc (the existing path), once with a **second, independent C compiler** —
   independent meaning a *different codebase/backend* (clang/LLVM, or tcc/TinyCC). g++ does **not** qualify: it
   shares GCC's middle/back-end, so a backend backdoor is present in both.
2. From each `iiis-0`, run the **byte-equivalence-gated** bootstrap `iiis-0 → iiis-1 → iiis-2` (the
   `build_iiisN.sh` chain is already deterministic and gate-checked on `stage1_corpus`).
3. **Byte-compare the two `iiis-2` binaries.** If identical, a backdoor present in gcc-but-not-the-other would
   have diverged the output — so its *absence* is mathematically witnessed. The seed is diverse-double-compiled,
   and the trust no longer rests on gcc alone. (Full rigor: also DDC-compile the *self-hosted* stages, per
   Wheeler — the chain's byte-equivalence gate already provides the fixed-point half.)

## Why it cannot run here (the honest blocker)

This environment has **only GCC-family C compilers**: `gcc`, `cc` (→ gcc), `g++` (GCC backend). There is **no
clang/LLVM and no tcc**. With no independent compiler, step 1 is impossible — the seed-DDC cannot be executed,
and **the seed residual stays OPEN**. There is no honest way around this with the tools present; claiming the
seed closed would be exactly the over-claim this architecture exists to forbid.

`STDLIB/sovir/seed_ddc.sh` encodes the procedure and **guards** it: it refuses to run unless `$CC2` is set to a
genuinely independent compiler (it rejects gcc/g++/cc-as-gcc), so the closure executes the moment an independent
toolchain is installed — and never produces a false green before then.

## The alternative (also not a one-command artifact here)

A **hand-audited minimal seed**: a bootstrap small and simple enough that a human reads every line of its source
and attests no backdoor, then everything above it is DDC'd against it. III's `iiis-0` is a real C program; this
is a human review campaign, not a gated build. It is the other recognised route and is named for completeness.

## Verdict

The seed residual is **OPEN**, and now precisely characterised: it is closable by exactly one of two known
routes (independent-compiler DDC, or audited seed), the DDC route is fully scripted and tooling-gated, and the
blocker (no independent C compiler in this environment) is stated plainly. That is the clean *resolution of the
question* available here — the mechanism is in place; the one missing input is a compiler this host doesn't have.
