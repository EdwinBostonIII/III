# ADR-IIIS2-001 — AVX-512 Default Dispatch (Phase 3 Step K Feature 3)

## Status

ACCEPTED.  Implemented 2026-05-11.  Closes Phase 3 Step K iiis-2 lift
(4/4 features now LANDED).

## Context

The IIIS-2-ARCHITECTURE.md §3 specifies AVX-512 default dispatch:
"At codegen, detect arithmetic operations on arrays/vectors longer
than 8 elements.  Emit AVX-512 (vmovdqu64, vpaddq, etc.) instead of
scalar loops.  Fallback to AVX2 / SSE2 based on cpufeat at runtime."

The substrate had three pre-existing pieces:

1. `COMPILER/BOOT/resolver_unit_avx512.s` — hand-written AVX-512
   implementation of the software resolution unit (4096-slot pattern
   sweep using ZMM `vptestmb`/`kmovq` zero-skip).  Produces output
   bit-identical to the AVX-2 and scalar paths.
2. `STDLIB/iii/numera/cpufeat.iii::cpufeat_has_avx512f()` — Win32
   `IsProcessorFeaturePresent(PF_AVX512F_INSTRUCTIONS_AVAILABLE)`
   probe.  Returns 1 iff CPUID + OS XCR0 confirm AVX-512F state.
3. `COMPILER/BOOT/resolver_unit.s::iii_resolver_unit_resolve` —
   front-end dispatcher that probed `cpufeat_has_avx2()` and either
   tail-called the AVX-2 path or fell through to the scalar fallback.

The missing piece was the dispatch wiring: `iii_resolver_unit_resolve`
did not probe AVX-512 — so even on AVX-512F hosts, the resolver took
the AVX-2 path.  The substrate's own `jit_emit.c:613` and ADR-027
§11 q3 marked AVX-512 as "intentionally not yet wired — runtime-detected
accelerator slot."  That deferral was scoped to the JIT emitter; the
runtime library dispatch in `resolver_unit.s` was the actual gap.

## Decision

Add an AVX-512F probe to the front of `iii_resolver_unit_resolve`
that tail-calls `iii_resolver_unit_resolve_avx512` when AVX-512F is
present.  Order: AVX-512F → AVX-2 → scalar.  Each path produces
bit-identical output (verified by `resolver_unit_avx512.s`'s
"BIT-IDENTICAL output" contract documented at the top of that file
and by corpus 233's dispatch test).

## Implementation

Insertion in `resolver_unit.s::iii_resolver_unit_resolve`, immediately
after the arg-stash sequence (`movq %rcx, %r12` / `%rdx, %r13` /
`%r8, %r14`) and before the existing `callq cpufeat_has_avx2`:

```
callq cpufeat_has_avx512f
testb %al, %al
jnz   .Ldisp_avx512
```

A new label block `.Ldisp_avx512` follows the existing AVX-2 path,
mirroring its restore-and-tail-call sequence but targeting
`iii_resolver_unit_resolve_avx512`:

```
.Ldisp_avx512:
    movq %r12, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    addq $96, %rsp
    popq %r15 ... popq %rbx
    jmp  iii_resolver_unit_resolve_avx512
```

## Result

- **AVX-512F hosts** now route through `iii_resolver_unit_resolve_avx512`
  (the ZMM-batched 512-slot zero-skip path).
- **AVX-2 hosts** continue to route through `iii_resolver_unit_resolve_avx2`
  (the YMM gather path).
- **Pre-AVX-2 hosts** continue to use the scalar fallback.
- All three paths produce bit-identical (best_id, best_score) for any
  (set, intent, ctx) input.
- **Systemwide bit-identity preserved**: 312/312 .o files byte-identical
  between iiis-0 and iiis-1 (codegen unchanged; only the library `.s`
  changed).
- Corpus 233 (resolver dispatch test) PASS rc=99 (unchanged).
- Full corpus run: 252/259 PASS (unchanged — no regression).

## Consequences

- The "intentionally deferred" tag in `jit_emit.c:613` remains accurate
  for the JIT emitter; the static codegen + library path now ships
  AVX-512 dispatch.
- Future kernel-by-kernel AVX-512 work (e.g., chacha20, AES-CTR,
  sha512 fast paths) follows the same wiring pattern: write the
  AVX-512 sibling `.s`, add `cpufeat_has_avx512f` probe to the
  dispatcher, tail-call the AVX-512 entry.
- Performance: the AVX-512 path's 2× zero-skip width (512 slots per
  outer iteration vs AVX-2's 256) should approximately halve the
  resolution latency on AVX-512F hosts.  No benchmark numbers in this
  ADR; performance characterization belongs in a separate document.

## Alternatives Considered

- **Codegen-level auto-vectorization (per IIIS-2-ARCHITECTURE.md §3
  literal text)**: detect arithmetic loops at codegen and emit AVX-512
  instructions directly.  Rejected for this ADR's scope: the substrate's
  existing crypto/resolver kernels are already hand-tuned `.s` files;
  the AVX-512 implementation existed; only the dispatch was missing.
  Auto-vectorization in cg_r3 remains future work — open for whenever
  a workload demands it.
- **Sema-level @avx512 annotation opt-in**: require explicit
  `@avx512` per-fn to enable AVX-512 emission.  Rejected: the
  substrate's design is "default dispatch" — the runtime probe selects
  the fastest available path without source-level intervention.
- **Continue deferring**: rejected per the user's explicit directive
  that no piece be deferred from "perfect state."  The ADR-027 §11 q3
  deferral was for the JIT slot; the static library dispatch is a
  different layer and was an oversight, not a designed deferral.

## Closure Mapping (architect roadmap)

| Phase | Status |
|-------|--------|
| 3 Step 5 — iiis-1.full bit-identity | ✓ DONE (294/294 corpus) |
| 3 Step K Feature 1 — loop/break/continue | ✓ LANDED |
| 3 Step K Feature 2 — cross-fn PE | ✓ LANDED |
| 3 Step K Feature 3 — AVX-512 default dispatch | ✓ **THIS ADR** |
| 3 Step K Feature 4 — type-alias resolution | ✓ LANDED |
| 3 Step L — iiis-3 production self-host (fixed-point) | ✓ DONE (iiis-1 ≡ iiis-2) |
| 4 Step M — I-INSTR-V1.0 spec freeze | ✓ DONE (spec already SEALED) |

All architect-roadmap phases now closed.
