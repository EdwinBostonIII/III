# iiis-1 — Stage-2 Type System Architecture

**Status (Phase 3 Step 3 full-ship + Step 5 partial):** iiis-0.1
binary (`6b...e8c` → `4e...83c` → `75...a77` → `54...e96` → `09...a76` →
`6e...4e43` across the session) carries 10 trap fixes, runtime
enforcement for `@cap_required`, `@k_max`, `@hexad_kind` (fn-level),
and FOUR static compile-time propagation checks:

1. `@cap_required` cap-flow propagation (caller mask ⊇ callee mask)
2. `@hexad_kind` intent-kind propagation (param/let kind equality)
3. `@k_max` K-floor propagation (caller floor ≥ callee floor)
4. `@returns_hexad` return-kind propagation (let kind == callee return kind)

iiis-1.exe binary built and sealed at `0edbffa8980af8c6f0768ccfab0644c3ad06d4206e41950146f2f04408fbf95c`,
reproducibility-verified, with `build_iiis1.sh` mhash drift gate.

All four iiis-1 features are LANDED with both runtime and static
enforcement.  Corpus 259-265 + 4 negative-compile harnesses all
PASS.  Known gap: cg_r3.c features (the four static checks) not yet
ported to cg_r3.iii — iiis-1.full work.

iiis-1 has not yet been split into a separate binary; the iiis-0
binary with the iiis-0.1 trap fixes + iiis-1 runtime enforcers IS
the substrate today.  The self-host check (compile iiis-1 source to
bit-identical iiis-1.exe) is gated on splitting + sealing
`iiis-1.mhash`.

This document specifies the type-system extensions and the self-host
invariants that govern the eventual lift.

## Self-host invariants

The iiis-1 source MUST be compileable by iiis-0.  iiis-1 then re-compiles
its own source bit-identically.  The lift sequence:

1. Write iiis-1 in a syntax iiis-0 can parse (no new keywords reach
   iiis-0; new annotations are parsed as `@attr` and stored as opaque
   metadata).
2. iiis-0 builds `iiis-1.exe`.
3. `iiis-1.exe` re-compiles its own source.  The output binary must
   sha256-equal a sealed reference (`iiis-1.mhash`).
4. Lift is sealed when step 3 succeeds for two consecutive builds.

**Current state (Phase 3 Step 5 partial):**
- `iiis-1.exe` builds via `build_iiis1.sh` — all 18 .iii TUs compile
  through iiis-0, link via gcc, produce a binary.
- Sealed mhash: `2b2d7aa7e76a13cb239f6e009634f3d5b6b56114a72a1eea6d9e06b70cf25f95`
  (verified reproducible across two consecutive builds).
- iiis-1 reads valid `.iii` source and compiles it to valid `.o` files
  whose codegen MATCHES iiis-0 for sources that use only features the
  current .iii ports implement.
- KNOWN GAP: iiis-0 (built from C) has session-added features
  (modifier-attachment for let/param, three static type-system checks)
  that have NOT yet been ported to `parse.iii` / `cg_r3.iii`.  So
  iiis-1 cannot YET produce identical output for sources that exercise
  these features (corpus 262-264, the negative harnesses).  Lifting
  these features to .iii is iiis-1.full work.

## What iiis-1 adds (over iiis-0)

### 1. Hexad-typed values  [LANDED — RUNTIME + STATIC + RETURN-STATIC]

**v1.0 runtime layer** (corpus 261): fns annotated `@hexad_kind(K)`
with a `ctx: u64` parameter emit a prologue that asserts
`ctx.hexad_kind == K`.  Mismatch → `0xFFFFFFFFFFFFFFFF` sentinel.
K is a numeric hexad code (1=FORM, 2=BIND, ..., 6=COMPOSE, 7=SEAL).

**v1.0 STATIC param/let layer** (corpus 263, negative harness 263_neg):
parameter-level inline `@hexad_kind(K_p)` annotations on the
parameter's type are read at every call site.  When the arg is an
ident bound to a let/param/var whose declared type also carries
`@hexad_kind(K_a)`, codegen asserts `K_a == K_p`.  Mismatch → rc=14
+ `# III_INTENT_KIND_VIOLATION`.

**v1.0 STATIC return layer** (corpus 265, negative harness 265_neg):
fns annotated `@returns_hexad(K_r)` declare their return value's
intent kind.  When a let-binding consumes the call result with
declared type `@hexad_kind(K_l)`, codegen asserts `K_l == K_r`.
Mismatch → rc=14 + `# III_RETURN_KIND_VIOLATION`.

Three distinct semantic uses of hexad-kind annotations, distinct
modifier names where context-overload would be ambiguous:
- `@hexad_kind` on a FN-DECL: runtime gate (ctx.hexad_kind check)
- `@hexad_kind` on a PARAM type: static gate (arg-binding kind check)
- `@hexad_kind` on a LET-binding type: static gate (consumed by call-site param check OR return-kind check)
- `@returns_hexad` on a FN-DECL: static return-value kind tag

**Stage-2+ goals**: hexad_adjacent widening (allow FORM args where
COMPOSE is required when adjacency permits); flow through assignments
beyond direct call returns.

iiis-0 represents intents and patterns as opaque u64 handles.  iiis-1
introduces `@hexad(KIND)` as a type-level annotation:

```iii
fn compose_op(a: u64 @hexad(FORM), b: u64 @hexad(COMPOSE)) -> u64 @hexad(COMPOSE) {
    /* iiis-1 compile-time check: at every call site, the values bound
     * to a, b must have @hexad annotations matching FORM and COMPOSE
     * (or hexad_adjacent(actual, declared) == true). */
    ...
}
```

The annotation is enforced at *call sites*, not at value construction.
Pattern declarations carry implicit hexad via `pattern_hexad_kind`; the
compiler propagates this through let-bindings.

**Why:** The resolver currently checks hexad adjacency at runtime (Step
3 of resolve).  iiis-1 lifts that check to compile time for *static*
intents — zero runtime cost, plus mis-typed code rejected before sealing.

### 2. K-value bounds as type constraints  [LANDED — RUNTIME + STATIC]

**v1.0 runtime layer** (corpus 260): fns annotated `@k_max(N)` with a
`ctx: u64` parameter emit a prologue that asserts
`kchain_current(ctx.kchain_id) >= N`.  Insufficient K → same denial
sentinel.

**v1.0 STATIC layer** (corpus 264, negative harness 264_neg): when a
fn declaring `@k_max(N_A)` calls a fn declaring `@k_max(N_B)`, the
codegen asserts `N_A >= N_B`.  Rationale: the caller can execute at
K as low as `N_A`; if `N_A < N_B`, there is a non-empty K interval
`[N_A, N_B)` where the caller runs but the callee MUST deny — a
structurally-unreachable success path.  Codegen rejects with rc=14
and marker `# III_K_FLOOR_VIOLATION: caller floor N_A below callee
floor N_B (deficit D)`.

```iii
fn _leaf(ctx: u64) -> u64 @k_max(400000000u64) { ... }
fn _outer(ctx: u64) -> u64 @k_max(800000000u64) {
    /* (800M >= 400M) -> static OK. */
    let r : u64 = _leaf(ctx)
    return r
}
fn _bad(ctx: u64) -> u64 @k_max(400000000u64) {
    /* (400M < 800M) -> static FAIL: dead-on-arrival call. */
    return _leaf_high(ctx)
}
```

Pure integer comparison; Mandate 7 clean.

**Stage-2+ goals**: full budget walking through the dispatch graph
(track kchain_compose decreases between fn-entry and call sites);
static rejection of compose-sequences that drain the budget below
floor before a downstream call.

### 3. Capability as type-level  [LANDED — RUNTIME + STATIC]

**v1.0 runtime layer** (corpus 259): fns annotated `@cap_required(MASK)`
with a `ctx: u64` parameter emit a prologue that calls
`cap_verify_rights(ctx.cap_id, MASK)`.  Denied → same denial sentinel.
Privacy-preserving: external observer cannot distinguish cap-denial
from hexad-mismatch from K-underflow.

**v1.0 STATIC layer** (corpus 262, negative harness 262_neg): when a fn
declaring `@cap_required(Y)` calls a fn declaring `@cap_required(X)`,
the codegen asserts `Y ⊇ X` (i.e. `(Y & X) == X`).  Violations are
rejected at codegen with rc=14 and an asm-stream marker
`# III_CAP_FLOW_VIOLATION: caller mask 0xY insufficient for callee mask 0xX (missing 0x...)`.
Caller without `@cap_required` is unaffected — runtime gate still
applies.  The static check is a TIGHTENING for cap-typed fns: it
proves cap-flow correctness BEFORE the binary is sealed.

Pure structural integer-mask containment.  Mandate 7 clean: no
observation, no statistics, no learning — just `(Y & X) == X`.

**Stage-2+ goals**: type-flow analysis through let-bindings, propagation
across module boundaries via the dispatch table, ctx-typing so the
"granted cap" carried through ctx is also tracked in the type system.

```iii
fn _leaf_op(ctx: u64) -> u64 @cap_required(0x100u64) { ... }
fn _outer_op(ctx: u64) -> u64 @cap_required(0x300u64) {
    /* Static check: (0x300 & 0x100) == 0x100  ✓  -- compiles. */
    let r : u64 = _leaf_op(ctx)
    return r
}
fn _bad_op(ctx: u64) -> u64 @cap_required(0x100u64) {
    /* Static check: (0x100 & 0x200) == 0x000  ✗  -- codegen rc=14. */
    let r : u64 = _leaf_high(ctx)   /* _leaf_high needs 0x200 */
    return r
}
```

### 4. First-class intent types  [LANDED — STATIC]

**v1.0 implementation** (corpus 263, negative harness 263_neg):
parameter-level inline `@hexad_kind(K_p)` annotations on the type
expression of a fn parameter are now READ by the codegen at every
call site.  When the matching argument is an ident bound to a
let/param/var whose declared type carries `@hexad_kind(K_a)`, the
codegen ASSERTS `K_a == K_p`.  Mismatch → codegen rejection rc=14
with the asm marker `# III_INTENT_KIND_VIOLATION: arg N kind 0xK_a
does not match param kind 0xK_p`.

The parser (`iiip_parse_let` + `iiip_parse_param_list`) now ATTACHES
inline `@modifier` annotations to the type_ref's modifier list
instead of discarding them.  This was previously a Stage-0 ASsT
shape that the parser maintained but never populated; iiis-1
populates it on let-bindings and fn-params, which is exactly the
information codegen needs to enforce intent-kind flow.

```iii
fn _consume_form(x: u64 @hexad_kind(1u64)) -> u64 { return x }

fn main() -> u64 {
    let form_val : u64 @hexad_kind(1u64) = 0x100u64
    let compose_val : u64 @hexad_kind(6u64) = 0x600u64
    let r1 : u64 = _consume_form(form_val)     /* static OK */
    let r2 : u64 = _consume_form(compose_val)  /* static FAIL: 6 != 1 */
    return 99u64
}
```

**Bypass cases** (static check is opt-in, TIGHTENING for typed flows):
- Arg is a literal → no binding to inspect → check skipped
- Arg's let-binding has no `@hexad_kind` annotation → check skipped
- Param has no `@hexad_kind` annotation → check skipped

Three bypass cases are tested in the positive corpus (263).  The
negative harness validates that the violation case fires.

Mandate 7 clean: pure integer-equality comparison over declared
metadata.  No observation, no learning, no runtime state involved.

**Stage-2+ goals**:
- Type aliases as first-class intent declarations:
  ```iii
  type IntentForm    = u64 @hexad_kind(1u64)
  type IntentCompose = u64 @hexad_kind(6u64)
  ```
  iiis-1 already parses this (TYPE_DECL with modifiers); the static
  check just needs to follow alias indirection from TYPE_REF → binder
  → TYPE_DECL → rhs_type's modifiers.  Deferred to iiis-2.
- Type inference: when `let x = intent_form(...)` (no annotation), infer
  `@hexad_kind(1u64)` from the callee's return-type modifiers.
- Specialise dispatch tables per intent kind for cheaper PE narrowing.

## What iiis-1 does NOT add

- No nominal typing for values without `@` annotations — iiis-0 syntax
  remains the default.
- No traits / type-classes / generics — out of scope.
- No runtime type info beyond what's already in pattern metadata.
- No type inference beyond local let-binding flow.

Mandate 7 boundary: type-system additions are STRUCTURAL, not observed.
No "the compiler learned this hot path" mechanics.

## What iiis-1 fixes about iiis-0 (the trap list)

These are real codegen / parser / lexer bugs in iiis-0.  As of the
Phase 3 Step 1 push, **ten of them are already fixed in iiis-0.1**
(corpus regression tests 248–256), and the remaining ones are deferred
to iiis-1 proper.

| Trap | Status | Corpus regression |
|---|---|---|
| Signed `<`/`<=`/`>`/`>=` SIGSEGVs | **FIXED iiis-0.1** — type-aware setcc | 248_signed_compare |
| `*u32` store emits 8-byte movq with scale=8 | **FIXED iiis-0.1** — width-aware indexed store | 249_u32_indexed_access |
| u32 local has dirty high 32 bits on read | **FIXED iiis-0.1** — width-aware local load with zero-ext | (covered by 249) |
| Multi-line fn signatures parse-error | **FIXED iiis-0.1** — newline-tolerant param-list parser | 250_multiline_fn |
| `} else {` must be one line | **FIXED iiis-0.1** — newlines around `else` permitted | 251_newline_else |
| Nested `/* */` block comments | **FIXED iiis-0.1** — depth-counting lexer | 252_nested_comments |
| `_` in hex literals rejected | **FIXED iiis-0.1** — `0xFFFF_FFFF` permitted | 253_hex_underscores |
| No `mut` in fn params | **FIXED iiis-0.1** — accepted as readability marker | 254_mut_param |
| `_` alone reserved | **FIXED iiis-0.1** — discard binding in `let _` | 255_let_discard |
| No local `[T; N]` array decl | **FIXED iiis-0.1** — multi-slot reservation + ident-to-base decay | 256_local_arrays |
| Module-level `const` becomes global symbol | deferred to iiis-1 (ABI surface change) | — |
| em-dash in `/* */` comment terminates early | false attribution — em-dash works in iiis-0; previously masked by nested-comment trap | — |
| `replace_all` substring trap | Tool concern, not iiis-1 | — |

Phase 3 Step 1 iiis-0.1 milestone: 10 traps fixed without surface
changes.  All preserved by corpus regression tests.

## Implementation order

1. **iiis-0.1 (interim):** fix the most-impactful traps in iiis-0
   without changing source surface.  Specifically: module-level const
   scoping, *u32 store width, u32 zero-extension.  These are pure
   codegen fixes in `COMPILER/BOOT/cg_r3.c` and friends.
2. **iiis-1 surface (parser + semantic checker):** add
   `@hexad`/`@k_max`/`@cap_required` annotation parsing.  Initially
   they're opaque metadata; the compiler ignores them.
3. **iiis-1 semantic checks:** implement the four checks above as
   passes that read the annotation metadata and reject mismatches.
4. **iiis-1 codegen unchanged from iiis-0** for v1 — type system is a
   diagnostic layer on top, not a codegen change.
5. **Self-host check:** iiis-1 compiles iiis-1 source bit-identically.
6. **Seal iiis-1.mhash** in addition to iiis-0.mhash; the substrate now
   tracks two compiler identities.

## Acceptance: when is iiis-1 "shipped"?

- All four type-system features (hexad, K, cap, intent-types) wired
  into the parser + semantic checker.
- 100% of v1.0 stdlib compiles cleanly under iiis-1 (any required
  annotation additions are explicit pattern-set updates).
- iiis-1 compiles iiis-1 bit-identically.
- corpus 200..247 all pass under iiis-1 the same as under iiis-0.
- A NEW corpus (corpus 300+) exists that exercises each type-system
  feature with intentionally-mismatched code, verifies the iiis-1
  rejects it, verifies iiis-0 still accepts it (backward compat).

## What this unlocks for iiis-2 and iiis-3

iiis-2 adds:
- Full control-flow: explicit `loop`/`break`/`continue` with type-checked exit conditions.
- Advanced PE: cross-function escape analysis for static intent narrowing.
- AVX-512 default dispatch with structural correctness checks.

iiis-3 adds:
- Production self-host across all of stdlib + compiler.
- Reproducible-build attestation (build-environment mhash).
- Seal of `iiis-3.mhash` as the canonical production substrate identity.

## What this unlocks for silicon (R2-Genesis)

The iiis-1 type system maps to the I-INSTR-V1.0 ISA directly:
- `@hexad(KIND)` becomes an opcode-class field in the instruction
  encoding (silicon enforces hexad adjacency at decode).
- `@k_max(N)` becomes a per-instruction K-decrement, with the
  silicon's K-register tracking the budget (underflow trap).
- `@cap_required(MASK)` becomes a per-instruction privilege bit;
  silicon checks against the current cap register at issue.

iiis-1's type system isn't a software convention — it's the
specification for what silicon enforces at instruction grain.
