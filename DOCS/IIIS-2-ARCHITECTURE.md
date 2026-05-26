# iiis-2 — Stage-2 Lift Architecture

**Status:** PARTIAL SHIP.  iiis-1 sealed and bit-deterministic.
Features 1 (`loop`/`break`/`continue`) and 4 (type-alias resolution)
LANDED via iiis-0 with corpus 268 + 269.  Features 2 (cross-fn
escape analysis) and 3 (AVX-512 default dispatch) remain in design.

## What iiis-2 adds (over iiis-1)

### 1. Full control flow  [LANDED]

iiis-1 supports `if`/`while`/`for`/`match` but NOT explicit
`loop`/`break`/`continue`.  iiis-2 lifts these:

```iii
loop {
    let next : u64 = read_one()
    if next == 0u64 { break }
    if (next & 1u64) == 0u64 { continue }
    handle(next)
}
```

**Why:** patterns like ring-buffer drain, retry-until-success, and
state-machine loops require explicit `break`/`continue` semantics.
iiis-1 forces these into a `while` with sentinel checks at every
iteration — readable but inefficient.

**Implementation:** new statement kinds `STMT_LOOP`, `STMT_BREAK`,
`STMT_CONTINUE`.  Codegen tracks a stack of (continue-label,
break-label) pairs per enclosing loop.  `loop {}` emits the
continue-label at the top, the body, an unconditional jump back, and
the break-label after.  `break`/`continue` are unconditional jumps
to the innermost stack entry.

### 2. Cross-function escape analysis for static intent narrowing

iiis-1's Partial Evaluator (PE) narrows `resolve()` calls within a
SINGLE function.  iiis-2 lifts this across function boundaries: when
a fn `f()` calls `g()` and `g`'s return value is provably a static
intent (constructed from literals all the way down), the PE can
narrow `resolve(f())` to a direct call.

**Implementation:** sema computes per-fn return-intent provenance
(LITERAL_INTENT | NON_STATIC).  PE consults this at every resolve()
site that takes a non-literal intent arg.

**Why:** today every `resolve(intent_form(...))` requires a runtime
dispatch.  iiis-2 makes the WHOLE chain static when the form_id is
a literal anywhere upstream.

### 3. AVX-512 default dispatch

iiis-1 compiles to scalar x86-64.  iiis-2 emits AVX-512 by default
for arithmetic-heavy kernels.

**Implementation:** at codegen, detect arithmetic operations on
arrays/vectors longer than 8 elements.  Emit AVX-512 (vmovdqu64,
vpaddq, etc.) instead of scalar loops.  Fallback to AVX2 / SSE2
based on cpufeat at runtime via the existing dispatch mechanism.

**Why:** stdlib has chacha20, AES-CTR, poly1305 — all
arithmetic-bound.  Today's benchmarks show ~5-10× headroom available.

### 4. Type-alias resolution for static checks  [LANDED]

iiis-1 static checks read `@modifier` annotations from inline type
expressions.  iiis-2 follows TYPE_REF names to TYPE_DECL aliases:

```iii
type CapHigh = u64 @cap_required(0x300u64)
type IntentForm = u64 @hexad_kind(1u64)
type IntentCompose = u64 @hexad_kind(6u64)

fn consume(x: IntentForm) -> u64 { ... }
let y : IntentForm = source()
consume(y)                                  /* static check sees kind=1 */
```

**v1.0 implementation** (corpus 269, negative harness 269_neg):
`type_node_extract_u64()` first tries the TYPE_REF's inline
modifier list; if nothing matches, it resolves the type-ref's name
to a TYPE_DECL in the current module via `type_ref_resolve_decl()`
(O(N) over module decls — Stage-2+ adds a name-keyed table) and
checks the TYPE_DECL's modifiers AND its rhs_type's modifiers
(single-level).  Inline-first fallback ensures backward compatibility:
sources that don't use aliases see identical behavior.

Single-hop resolution: `type B = A` where A is another alias is
deferred (would require iteration).  v1 supports the canonical
flat-alias pattern.

**Why:** enables ergonomic typed-intent declarations.  Today you
write `u64 @hexad_kind(1u64)` repeatedly; with aliases, declare
`IntentForm` once and use it everywhere.

**Mandate 7 compliance:** pure structural name-lookup with bounded
recursion.  No observation, no learning, no runtime state.

## Self-host invariants

The iiis-1 → iiis-2 lift sequence mirrors the iiis-0 → iiis-1
sequence:

1. iiis-1 builds `iiis-2.exe`.
2. `iiis-2.exe` re-compiles its own source.  Output must
   sha256-equal `iiis-2.mhash`.
3. Lift is sealed when step 2 succeeds for two consecutive builds.

## What iiis-2 does NOT change

- iiis-1's four type-system features keep their existing surface
  semantics.  iiis-2 EXTENDS, doesn't break.
- Stdlib v1.0 compiles unchanged under iiis-2 (the new features
  are opt-in).
- Mandate 7 boundary remains: control flow + escape analysis +
  AVX-512 are STRUCTURAL.  No observation, no learning.

## Acceptance: when is iiis-2 "shipped"?

- All four new features wired (loop/break/continue, escape PE,
  AVX-512, type aliases).
- iiis-2 compiles iiis-2 bit-identically; `iiis-2.mhash` sealed.
- corpus 200..267 all pass under iiis-2 the same as under iiis-1.
- A new corpus tier (300+ or 400+) exists demonstrating each new
  feature.
- AVX-512 dispatch verified against scalar reference: byte-identical
  output for chacha20, AES, poly1305 KAT vectors at every input
  size.

## What iiis-2 unlocks for silicon (R2-Genesis)

- `loop`/`break`/`continue` become first-class control-flow opcodes
  in I-INSTR-V1.0 (not just primitives synthesised from `jmp`).
- Escape analysis narrows the dispatch table at silicon-issue time
  — the silicon's dispatch unit can issue a single-cycle direct
  branch when the PE proved static.
- AVX-512 default establishes the SIMD lane-width baseline for the
  silicon's vector engine; iiis-2's emitted code IS the spec for
  silicon vector op encoding.
