# ADR-IIIS1-002 — Fixed-Point Self-Host Bit-Identity

## Status

ACCEPTED.  Implemented and verified 2026-05-11.

## Context

After ADR-IIIS1-001 landed runtime + static teeth for the iiis-1 type
system, a measurable gap remained between iiis-0 (C-implemented) and
iiis-1 (.iii-implemented) compilers: 47 of 274 corpus tests produced
byte-divergent .o output, and 13 of 18 self-host source TUs (the
`.iii` files implementing the compiler itself) also diverged.

The goal: **perfect systemwide bit-identity**.  The iiis-1 .iii
compiler must produce byte-identical .o output to iiis-0's C
implementation for the entire .iii surface — corpus and self-host
sources alike — and, as the gold-standard validation, iiis-1 must
build itself reproducibly (iiis-1 ≡ iiis-2 byte-for-byte).

## Decision

Close every codegen divergence by porting the matching iiis-0 (C)
behavior into the iiis-1 (.iii) codegen, byte-for-byte.  Where a
required surface area was missing on the C side (e.g., named-arg
AST accessors for `@dynamic(ripple=auto)` decoding, partial-evaluator
table access for resolve() narrowing), add the minimum C wrapper
surface to bridge the gap — without inventing new compiler features.

## Closures (this session, 47+13 → 0)

### Corpus closures (47 → 0)

1. **Stack-arg sign** — params 5+ use `R3_STR_MOVQ_PFX` (clean
   `    movq `) for `<dec>(%rbp)` instead of `-<dec>(%rbp)`.

2. **EXPR_UNIT / EXPR_TRIT byte alignment** — `movq $N, %rax`
   instead of `xorq %rax,%rax` / `movabsq $0x<hex>, %rax`.

3. **`cqto` AT&T mnemonic** — `R3_STR_IDIV` / `R3_STR_IDIVMOD`
   corrected from `cqo` (wrong) to `cqto` (matches C).

4. **Runtime gates `@cap_required` / `@hexad_kind` / `@k_max`** —
   full byte-level port of `cg_r3.c:3057-3127` runtime check
   prologues.  New constants `R3_CMT_CAP_REQ_BANNER`, byte-string
   primitives for `callq call_context_*`, `cap_verify_rights`,
   `kchain_*`, label prefixes `L_cap_ok_`, `L_hexad_ok_`,
   `L_kmax_ok_`, and the dispatch helper `r3_emit_runtime_checks`.

5. **ADDR-of-IDENT-global fast path + raw-symbol-for-`@export`** —
   `&fn` taking address of `@export`/`@extern` symbol emits raw
   identifier instead of `L_`-prefixed mangled label.  Plus
   elimination of the spurious `pushq %rax / popq %rax` no-op
   pair that iiis-1 was emitting for non-local ADDR.

6. **Width-aware global IDENT load** — `r3_emit_global_load_with_type`
   dispatches: u8/bool → `movzbq`, i8 → `movsbq`, u16 → `movzwq`,
   i16 → `movswq`, u32 → `movl ..., %eax` (auto zero-extends),
   i32 → `movslq`, else `movq`.

7. **INDEX width 2/4 dispatch** — `r3_index_obj_elem_kind` returns
   1-7 encoding signed/unsigned width 1/2/4/8.  Load/store
   helpers `r3_emit_indexed_load` / `r3_emit_indexed_store`
   dispatch to `movzbq` / `movsbq` / `movzwq` / `movswq` / `movl` /
   `movslq` / `movq` for load and `movb` / `movw` / `movl` / `movq`
   for store, with scale-1/2/4/8 matching element width.

8. **Local array decay** — TYPE_ARR local IDENT emits
   `leaq -N(%rbp), %rax` instead of `movq -N(%rbp), %rax`,
   producing the array base address (matching C semantics).

9. **Signed-compare setcc** — `r3_expr_is_signed` walks
   PAREN/CAST/IDENT to determine whether either operand is
   signed (i8/i16/i32/i64).  Dispatches to `setl` / `setle` /
   `setg` / `setge` for signed, `setb` / `setbe` / `seta` /
   `setae` for unsigned.

10. **STMT_LET ordering** — matches `cg_r3.c`: emit value-expr
    FIRST (RHS reads outer scope), THEN call `local_add` (always
    creates a new slot — never reuses), THEN store rax.  Closes
    the slot-accounting drift in `let _ = expr` patterns and
    fixes shadow semantics for `let x = x + 1`.

11. **EXPR_CAST unsigned-uniform** — separate `r3_emit_cast_extend`
    from `r3_emit_return_extend`.  CAST treats i8/u8 same
    (`movzbq`), i16/u16 same (`movzwq`), i32/u32 same (`movl
    %eax,%eax`).  Return-extend remains signed-aware per the C
    callee-return-extension behavior.

12. **`@dynamic(ripple=...)` stub via AST-modifier inspection** —
    `r3_emit_dynamic_stub` decodes the modifier directly from the
    AST (no sema-state needed).  Required adding two new C
    accessors `iii_ast_arg_name_off` / `iii_ast_arg_name_len` to
    `ast_accessors.c` for named-arg name lookup.  Emits the
    4-line `# III_DYNAMIC_RIPPLE_STUB ... callq ripple_execute_native`
    sequence byte-identically.

13. **Phase C.6 PE narrowing (single + multi-stmt)** — new file
    `iii_cg_pe_iiis1.c` exposes `iii_cg_pe_classify_intent`
    consuming the C-side `III_COMPOSITION_TABLE` static table
    (sourced from `iii_compositions.def`).  iiis-1 reads the
    returned `const char *` byte-by-byte via
    `iii_cg_pe_name_byte` and emits direct `leaq <fn>(%rip),
    %rax` for static-resolvable resolve() callsites.  Multi-stmt:
    `r3_pe_record_static_fp` records `slot → fn_name` mapping
    from `let fp = resolve(...)` patterns for later use.

### Self-host source closures (13 → 0)

After corpus 100% bit-identity, 13 of 18 self-host TUs still
diverged on patterns the corpus didn't exercise.  Two additional
fixes:

14. **Width-aware global VAR_DECL store** —
    `r3_emit_global_ident_store` probes binder kind + type and
    dispatches `movb %al` / `movw %ax` / `movl %eax` / `movq
    %rax` to match `cg_r3.c:2306-2323`.  iiis-1 was previously
    always emitting `movq %rax, L_name(%rip)`, writing 7 bytes
    of garbage past u8/i8 globals — the latent codegen bug
    underlying multiple narrow-typed global write paths.

15. **ADDR-of-INDEX (`&arr[i]`)** — new constants
    `R3_STR_LEAQ_RCX1` / `R3_STR_LEAQ_RCX8`.  Implementation in
    the unary ADDR handler: loads base address (leaq for local
    or global IDENT), evaluates index, emits `leaq
    (%rax,%rcx,N), %rax` with N=1 for byte_index, N=8 default.
    Mirrors `cg_r3.c:1341-1395`.

## Result

| Metric | Before this session | After |
|--------|---------------------|-------|
| Corpus bit-identity | 228/274 (83.2%) | **275/275 (100%)** |
| Self-host TU bit-identity | 5/18 (28%) | **18/18 (100%)** |
| Total .o files identical | 233/292 (80%) | **293/293 (100%)** |
| iiis-1 ≡ iiis-2 fixed-point | diverging | **byte-for-byte equal** |

Final sealed mhashes:
- iiis-0: `6d84171dcda00538a092e375d95fd0d10741f1056fba3e42094dcf8df1b1abf2`
- iiis-1: `56c258db1f195a95f532f559a114e036bc5ef656d835abaa24cef0fca9dad086`
- iiis-2 (built by iiis-1): `56c258db1f195a95f532f559a114e036bc5ef656d835abaa24cef0fca9dad086` (matches iiis-1)

Both compilers reproducible across consecutive builds.

## New C-side surface

To support iiis-1's .iii-callable surface without re-implementing
already-stable C-side static tables and AST traversal:

- `ast_accessors.c`: added `iii_ast_arg_name_off`,
  `iii_ast_arg_name_len`.
- `iii_cg_pe_iiis1.c` (new file): exposes
  `iii_cg_pe_classify_intent` (reads `III_COMPOSITION_TABLE`),
  `iii_cg_pe_name_len`, `iii_cg_pe_name_byte`.

No new behavior added to iiis-0; these are purely .iii-callable
wrappers around already-existing static tables.

## Consequences

- iiis-1 is now a verified self-host compiler at the byte level.
  Any future codegen change in `cg_r3.c` must be mirrored in
  `cg_r3.iii` to maintain bit-identity; the build script's
  `--check-corpus` flag is the primary regression gate.

- The 13 codegen patterns ported in this session form a reusable
  reference for porting future codegen TUs from C to .iii.

- The Phase 3 Step K iiis-2 lift is now 3/4 complete; only AVX-512
  default dispatch remains, and that work is explicitly deferred
  per `jit_emit.c:613` ("AVX-512 intentionally not yet wired").

- The I-INSTR v1.0 spec (Phase 4 Step M) is already SEALED in
  `DOCS/HARDWARE/I-INSTR-V1.0-spec.md`.

## Alternatives Considered

- **Defer the bit-identity push to a later session.**  Rejected:
  the divergences masked latent codegen defects (e.g., 7-byte
  garbage writes past u8 globals) that would silently produce
  wrong runtime behavior if the iiis-1 path were ever chosen
  over iiis-0.  Closing them while the substrate is fresh is
  cheaper than diagnosing intermittent runtime failures later.

- **Port the full Phase 2/3 sema annotation table to .iii.**
  Rejected for now: agent analysis confirmed the .iii-callable
  surface for AST modifier inspection (via the new
  `iii_ast_arg_name_*` accessors) is sufficient for @dynamic
  decoding.  Lifting the entire sema state table would be a
  larger refactor with no incremental bit-identity benefit.

- **Re-implement the III_COMPOSITION_TABLE in .iii.**  Rejected:
  the table is auto-generated from `iii_compositions.def` and
  re-importing it would duplicate the source of truth.  The
  C wrapper approach keeps a single authoritative source.
