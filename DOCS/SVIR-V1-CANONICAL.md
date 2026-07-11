# SVIR v1 — Canonical Byte-Exact Encoding Specification

> The contract for the integer language. An emitter is **canonical** iff, for any accepted `.iii` program, it
> emits *exactly* these bytes. Two implementation-independent emitters that both satisfy this spec are
> byte-identical (the DDC frontend-closure gate). The auditable verifier (`svir_verify`) accepts a module iff
> it is structurally valid per this spec. Date 2026-06-23.

## 0. Identity — a deterministic integer language

SVIR is **i64-only**: every value is a signed 64-bit integer. There is **no floating point, no objects, no
general pointers, no dynamic dispatch**. This is deliberate: cryptography, hashing, ZK constraint systems, and
ledger state-transitions are exact integer math, and an integer-only machine yields **bit-identical results
across architectures** (x86 / WASM / RISC-V) — the precondition for ZK-provable and cross-architecture-
reproducible execution. SVIR is unsuitable for general-purpose software by design; its domain is high-assurance
integer computation. Memory is a single flat little-endian byte buffer addressed from 0.

## 1. Module format

```
[u8  func_count]
per function (in canonical order, §3):
  [u8  params]        ; parameter count (locals 0..params-1 are the parameters)
  [u8  nresults]      ; always 1 in v1
  [u16 LE body_len]   ; body length in bytes
  [body_len bytes]    ; the op stream (§2)
```
Function 0 is the entry point (the translators export it as `main`).

## 2. Opcode table (the full integer ISA)

| Op | Byte | Operands | Stack effect |
|---|---|---|---|
| `CONST_I64` | `0x01` | i64 LE (8 B) | → push imm |
| `LOCAL_GET` | `0x10` | u8 slot | → push local[slot] |
| `LOCAL_SET` | `0x11` | u8 slot | pop → local[slot] |
| `ADD SUB MUL SDIV SREM` | `0x20 0x21 0x22 0x23 0x24` | — | a,b → (a op b) |
| `AND OR XOR SHL SHR_U` | `0x25 0x26 0x27 0x28 0x29` | — | a,b → (a op b) |
| `EQ NE LT_S GE_S LE_S GT_S` | `0x30 0x31 0x32 0x33 0x34 0x35` | — | a,b → (a cmp b) ? 1 : 0 |
| `BLOCK LOOP IF ELSE END` | `0x40 0x41 0x42 0x43 0x44` | — | structured control |
| `BR` | `0x50` | u8 depth | branch to depth-th enclosing construct |
| `BR_IF` | `0x51` | u8 depth | pop cond; branch if nonzero |
| `RETURN` | `0x60` | — | pop → function result |
| `CALL` | `0x70` | u8 funcidx, u8 argcount | pop argcount args; push result |
| `PRINT_CHAR` | `0x71` | — | pop; emit low byte to stdout |
| `DROP` | `0x72` | — | pop; discard |
| `LOAD8` | `0x80` | — | pop addr; push mem[addr] (zero-extended) |
| `STORE8` | `0x81` | — | pop value, pop addr; mem[addr] = value & 0xFF |

Compare/`BR_IF`/`IF` conds are i64 0/1. `SDIV`/`SREM` are signed. Operand encoding: `i64`=8-byte LE, `u8`=1 byte,
`u16`=2-byte LE.

## 3. Canonicality rules (what makes the encoding UNIQUE per source)

These pin every free choice so two emitters converge byte-for-byte.

1. **Function order.** `main` is function 0. The remaining functions follow in **source order**. (Emitters scan
   for the function named `main` first, then the rest as they appear.)
2. **Local slot allocation.** Parameters get slots `0..params-1` in declaration (left-to-right) order. Each
   subsequent `let [mut] x` gets the next slot, in source order. A slot is never reused.
3. **Constants.** `CONST_I64 = 0x01` then the value as an 8-byte little-endian two's-complement i64. Integer
   literals lose any `uNN`/`iNN` suffix (all i64).
4. **Expression lowering = postfix.** Operands are lowered left-to-right, then the operator op-byte. Precedence
   (high→low): `* / %` (mul/div/mod) > `+ -` > `<< >>` > `< > <= >=` > `== !=` > `&` > `^` > `|`. All operators
   left-associative. Parentheses override precedence; they emit no bytes.
5. **`while c { b }`** → `BLOCK LOOP <c> CONST_I64 0 EQ BR_IF 1 <b> BR 0 END END` (loop while `c != 0`; break via
   `(c==0) → BR_IF 1`).
6. **`if c { t }`** → `<c> IF <t> END`. **`if c { t } else { e }`** → `<c> IF <t> ELSE <e> END`.
7. **`let [mut] x : T = e`** → `<e> LOCAL_SET slot(x)`. **`x = e`** → `<e> LOCAL_SET slot(x)`.
8. **`return e`** → `<e> RETURN`. An expression statement (e.g. a bare call) → `<e> DROP`.
9. **`f(a0, a1, …)`** → `<a0> <a1> … CALL funcidx(f) argcount`. Args lowered left-to-right; `funcidx` per §3.1.
10. **Module arrays.** `var d : [T; N]` at module scope is assigned a base offset in linear memory: the first
    such array gets base 0, each subsequent array `base += N` (declaration order). `d[i]` (load) →
    `<i>` then (if base>0) `CONST_I64 base ADD` then `LOAD8`. `d[i] = e` (store) → `<i>` then (if base>0)
    `CONST_I64 base ADD` then `<e>` then `STORE8`.
11. **No dead bytes.** Emitters emit nothing for type annotations, the `module` header, `mut`, or whitespace.

## 4. Subset boundary (v1)

Accepted: `module`; `fn NAME(p:T, …) -> T { … }`; `let [mut] x:T = e`; `x = e`; `if`/`else`; `while`; `return`;
calls; module-scope `var NAME:[T;N]`; the §2 operators; integer literals; locals; array index load/store.
Not in v1 (a canonical emitter must reject or not encounter): wider/other types, structs, function pointers,
nested expressions in array sizes, an output primitive other than via the runtime, floating point.

## 5. Determinism guarantee

A canonical emitter is a pure function of the source bytes: same `.iii` in → same SVIR bytes out, every run.
(Verified for `iiisv`: byte-identical ×2 on `indep_toolchain`/`indep_ops`/`indep_bignum` — see SVIR-DDC-FINDINGS.)

## 6. Post-v1 growth (2026-06→07): the living ISA + the v2 container

§0–§5 are the **frozen v1 contract** (the DDC frontend-closure scope, 2026-06-23) and stay authoritative for
it. The set below was added by the Φ1 seed campaign; the anchor (`STDLIB/sovir/svir_verify.iii`, 97 lines) is
normative — this section transcribes it.

### 6.1 Opcodes added since v1 (implemented in all five consumers: verify / interp / x86 / wasm / dis)

| Op | Byte | Operands | Stack effect / rule |
|---|---|---|---|
| `CALL_INDIRECT` | `0x73` | u8 argcount | pop fn-index (stack top, pushed after the args), pop argcount args → push result (net −argcount). The index is runtime data, so there is **no static check**: an out-of-range index must **trap at execution** (interp bounds-check → 199; x86 `__svci` switchboard; wasm native `call_indirect` over a funcref table). `run_fnptr_gate.sh` pins the OOB trap on every executor. |
| `LOAD64 / STORE64` | `0x82 / 0x83` | — | pop addr → push 8-byte LE load (net 0) / pop value, pop addr → store 8 bytes (net −2) |
| `LOAD16_U LOAD16_S LOAD32_U LOAD32_S` | `0x84 0x85 0x86 0x87` | — | pop addr → push zero-/sign-extended load (net 0) |
| `STORE16 / STORE32` | `0x88 / 0x89` | — | pop value, pop addr → store low 2 / 4 bytes (net −2) |
| `IMPORT` | `0x8A` | u8 namelen, name bytes | net 0. The whole body of a **declared-not-defined** external function is exactly this decl; a `CALL`/`CALL2` to its funcidx resolves **by name at link** (the sovld phase). Executing an unresolved import fails LOUDLY (interp 198, x86 `ExitProcess(198)` stub, wasm `unreachable`) — never silently. Body scanners must skip the name bytes (a name byte that collides with an opcode must not be decoded). |
| `CALL2` | `0x74` | u16 LE funcidx, u8 argcount | `CALL`'s discipline with a wide index: pop argcount args → push result (net −argcount+1). Static `funcidx < func_count` check (error 9). The >255-function call form. |

### 6.2 The v2 container (additive — v1 saturates at 255 functions)

`COMPILER/BOOT/main.c` alone registers 334 functions (78 defs + 256 imports) — the v1 `[u8 func_count]`
header cannot carry it (the pre-v2 emitter wrote the literal `334u8`, which the downstream `.iii` compile
silently wrapped to 78 — the measured rc=9 class), and the linked whole-seed (~2,300 fns) is out of reach
entirely. v2 widens only the module envelope:

```
[0x00]                ; version marker — illegal as v1 (v1 rejects func_count==0, error 1)
[u16 LE func_count]   ; functions from offset 3; per-function header UNCHANGED (§1)
… functions …
[u32 LE data_len][data bytes]   ; the optional trailing data section length widens u16 → u32
```

Rules: **(a)** every v1 module is byte-untouched — measured 2026-07-08 by the two-path regression: the
HEAD ccsv and the v2 ccsv emit **byte-identical** modules for all six ≤255-fn seed modules
(lex/sema/emit/ast/cg_r3/parse.c) plus four control programs, while main.c gains exactly the v2 header
(`0u8,78u8,1u8` = marker + LE16(334)); **(b)** an emitter chooses v2 only when a count demands it (ccsv:
`FN > 255`); **(c)** `CALL2` is legal in v1 and v2 bodies alike — the verifier checks its index against the
container's func_count either way; **(d)** teeth (`run_svir_v2.sh`): a v2 header whose function bytes stop
early is error 1; a `CALL2` funcidx ≥ func_count is error 9; the 300-fn generator module must run 99 on
verify + interp + sovereign x86 (kernel32-only) + wasm.

Anchor cost of the entire post-v1 set: `svir_verify.iii` 82 → 97 lines — within the one-sitting audit
budget (ADR-1).

## §W — WIDTH LOWERING (Θ2-full rung 2: the faithful typed fragment)

SVIR v1 values are width-free 64-bit cells.  The typed fragment of .iii is
lowered onto them by THE NORMAL-FORM INVARIANT, transcribed from the
definitional evaluator (eval.iii, the square-adjudicated law):

> Every value on the SVIR stack and in every local slot is held in eval's
> canonical 64-bit form for its static tag: **unsigned w-byte values are
> zero-extended** (high bits 0), **signed w-byte values are sign-extended**,
> untyped literal values are raw, bool is 0/1.

Static tags follow eval exactly: literal suffixes; declared types on
let/param/const/var/return; `ev_unify` for binops (untyped adopts the typed
side; equal width + equal sign passes; equal width + MIXED SIGN is REFUSED
[class mixed-sign] until the instrument adjudicates it; mixed width takes the
WIDER tag — row 10b); casts take the target; comparison results are bool.

### W.1 op lowering (ut = unified tag, w = width(ut))

| .iii op | lowering |
|---|---|
| `+ - *` | `0x20/0x21/0x22`, then RENORM(ut) if w<8 |
| `& \| ^` | `0x25/0x26/0x27` bare (bitops are closed under normal forms) |
| `/ %` signed | `0x23/0x24`, then RENORM(ut) if w<8 |
| `/ %` unsigned or untyped | `0x2A/0x2B` (DIV_U/REM_U), no renorm |
| `<<` | `0x28` bare, then RENORM(lhs tag).  NARROW SHIFTS RUN WIDE (sq07 adjudication 2026-07-09): the count masks &63 — the op's own law is the language's; `5u32<<33 == 0`, not `5<<1`.  (ev_shmask's old &31 arm was model extrapolation beyond p10's in-range pins.) |
| `>>` | `0x29` bare on the WIDE normal form, then RENORM(lhs tag) if signed.  ONE LAW (p10 + sq07): the 64-bit normal-form value shifts logically with count &63; at w=8 that is p10's logical shr, while NARROW SIGNED operands see their sign-extension bits shift in — arithmetic in effect — `(-5i32)>>1 == -3`, and the renorm re-signs the w-bit pattern. |
| `== !=` | `0x30/0x31` bare (normal forms are equal iff values are equal) |
| `< <= > >=` signed | `0x32/0x34/0x35/0x33` bare (operands are sign-extended) |
| `< <= > >=` unsigned w∈{1,2,4} | bare (normal forms are positive in i64) |
| `< <= > >=` unsigned w=8 or untyped | BIAS both operands — `CONST 0x8000000000000000; XOR` inserted after the LHS bytes and appended after the RHS bytes — then the signed op.  (a^2^63) <ₛ (b^2^63) ⇔ a <ᵤ b |
| unary `-` | `CONST 0` before the operand, `0x21`, RENORM(t) |
| unary `~` | operand, `CONST -1, 0x27`, RENORM(t) |
| unary `!` (bool) | `CONST 1` before the operand, `0x21` |

RENORM(t) for w<8: unsigned → `CONST mask(w); AND` (zx); signed →
`CONST mask(w); AND; CONST 2^(8w-1); XOR; CONST 2^(8w-1); SUB` (sx).
RENORM emits NOTHING for w=8, w=0 (untyped), bool, or class-identical seams —
minimal emission is part of the canonical byte definition.

### W.2 seams (ev_adapt's emitted image)

let/assign-to-local/call-arg/return adapt the value to the slot's tag:
renorm fires only when the slot is narrow (w<8) AND the value's tag differs.
An INT/HEX literal adapts by FOLDING: the CONST payload carries
norm(value, slot-tag) and no renorm bytes are emitted.  bool adapts to any
int slot bare (already 0/1).  A width STORE truncates by itself (row 10:
narrowing stores ARE the renorm) — index/module-cell stores emit no renorm.
Untyped `let` slots widen to u64 (eval's let law).

### W.3 memory cells

Module `var` cells sit at MTOP offsets (from 16), stride = element size.
Loads extend per the ELEMENT's signedness: 1B `0x80` (+sx(1) if i8 — v1 has
no signed byte load), 2B `0x84/0x85`, 4B `0x86/0x87`, 8B `0x82`.
Stores truncate: `0x81/0x88/0x89/0x83`.  Array index scales:
`idx; CONST esz; MUL` (esz>1), then `CONST base; ADD` (base>0).

### W.4 canonicity domains

* **Width-free fragment** (i64/untyped scalars + u8 arrays — everything
  iiisv2 expresses): the lowering above degenerates to iiisv2's exact bytes
  (all renorms/biases/masks vanish; i64 div/mod/compares are the bare signed
  ops; `>>` is bare 0x29 by the logical-shr law).  iiisv2 remains the live
  canonicity witness here (gate arm A1).
* **Typed fragment**: canonical bytes are defined by THIS section and pinned
  by golden mhash ratchet (gate arm A2) — iiisv2 cannot see types by design.
* Known byte-forks from rung 1 on typed programs (semantic fixes, adjudicated
  by the three-route square): u64/untyped ordered compares gain the bias
  pair; unsigned/untyped `/ %` move 0x23/0x24 → 0x2A/0x2B; narrow arithmetic
  gains renorms; typed element cells gain width ops and esz scaling.

### W.5 refusal law

Everything outside the fragment REFUSES with a named class on stderr
(`svir-unsup class=<name> kind=<n>`, emit rc 2 → `iiis --emit-svir` exits 16):
struct, ptr, string, extern-fn (call sites), fnptr, mixed-sign, type,
const-expr, var-init, local-array, const-array, expr-kind, stmt-kind, cap,
suffix, ident, lvalue, bool-op, unit-value, decl-kind.  NO SILENT
MISCOMPILES: an unknown construct can never emit partial bytes (sticky
SV_UNSUP poisons the module).  The corpus sweep census
(run_svir_corpus_gate.sh) is the burn-down ledger for these classes.

### W.6 unsigned division ops (v1 op-table addendum)

| op | name | semantics |
|---|---|---|
| 0x2A | DIV_U | pop b, a; push a÷b unsigned; b=0 → 0 |
| 0x2B | REM_U | pop b, a; push a mod b unsigned; b=0 → 0 |

Both already live in svir_interp (Λ0); this section admits them to the
canonical emitter surface.  iiisv2 (width-free) never emits them.

### W.7 (§W.mix) — the mixed-sign unification law (Θ4 rows 13/13b, 2026-07-10)

Unified tag for a binary op = (max(width_a, width_b), signed_a OR signed_b);
untyped adopts the typed side; shifts take the VALUE side's tag alone.
Operand values are NEVER adapted across the seam — each is consumed in its
own §W normal form; only the RESULT renormalizes to the unified tag.
Sign-sensitive ops (DIV/REM, ordered compares) select the SIGNED opcode iff
the unified tag is signed.  EQ/NE compare the raw wide forms.

Emitter consequences: sv_unify constructs mk_int(max-width, either-signed)
— bit-identical to the wider operand's tag when signs AGREE (every
pre-row-13 golden byte-unchanged, verified across all 7 pins); the
SVU_MIXED_SIGN refusal retires (guards remain, dead).  and/or/xor gain a
result renorm whenever the unified tag is narrow UNLESS both operands are
TYPED SAME-SIGN — the only provably-closed case (mx37 measured: untyped
operands are raw wide values; `(u8|511)` keeps 0x1FF at the temp and the
named/temp spellings split natively; closure under normal forms requires
both sides IN normal form).  Same law rung: unary NEG/BNOT results renorm
to the operand's tag (mx40/41 — negq on INT_MIN escapes wide; notq
re-signs zx values).

### W.8 — the canonical init preamble (S-frontier slice 2, 2026-07-10)

Module cells (scalars and typed arrays) with NONZERO initializers hold
their language-defined values through a canonical preamble at the ENTRY
fn's head (fn 0 — main-first order): declaration order, array elements
ascending, each store = CONST(cell-address) CONST(value) width-store —
byte-identical shape to the assignment lowering.  ZERO values are SKIPPED:
the interp world is pre-zeroed, so the zero-skip is semantics-free and
keeps canonical bytes minimal (the declared-extent zero law's dual).
The VALUES are read from the definitional evaluator's collected world
(iii_ev_const_value for scalars, iii_ev_elem_value per array element —
CTFE initializers included), so every route folds module data through the
ONE meaning object.  Unevaluable initializers refuse (var-init class,
loud).  iiisv2 (width-free) never emits the preamble; the A1 parity set
contains no initialized cells.

### W.9 — the frame arena (S-frontier slice 3, 2026-07-10)

Local `var x : [T; N]` lives in a PER-ACTIVATION arena in linear memory.
Two ops join the executable surface:

| op | name | semantics |
|---|---|---|
| 0x8B | ARENA [u16 ext] | save the arena mark into this frame; reserve ext bytes at the mark; ZERO them (eval's fresh-world law); advance the mark |
| 0x8C | ABASE | push this frame's arena base |

(0x8A stays the Λ0 IMPORT-body marker — never an executed op.)  The arena
grows UP from 8 MiB (module cells live at 16..MTOP, far below).  EVERY
activation save/restores the arena mark (the exec wrapper), so a frame's
arrays die with it and recursion gets fresh isolated extents.  The
emitter computes the extent by a statement pre-walk (same traversal order
as emission → same total), emits 0x8B iff extent > 0 (before the entry
preamble), assigns offsets in encounter order, and addresses elements as
idx*esz + ABASE + offset — the module-array shape with 0x8C for the base.
Bare local-array idents refuse (lvalue class), bracket-init locals are
not grammar.  NAMED OPEN CORNER (adjudication deferred): FIRST-READ of a
never-written local array is 0 on E/S (world/arena zero law) but stack
garbage on N — the corpus never pinned it; probes test only defined
behavior until a Θ4 row adjudicates.

### W.10 — the CRT tier (S-frontier slice 4, 2026-07-10)

Tier-whitelisted extern declarations lower to IMPORT records — the Λ0
form [params][1][bodylen:u16 LE][0x8A][namelen][name bytes] — appended
after the real fn records (v1 fncount is a u8: the total caps at 255);
calls emit as plain CALL to the import's index.  THE TIER (Θ1's
adjudicated builtin law, one list both routes cite): malloc = zeroed
bump allocation returning an SVIR OFFSET (tier memory lives IN linear
memory and flows through the width ops — NOT a host pointer); free =
noop; putchar = real stdout, returns its char (C law); VirtualAlloc =
bump (MEM_COMMIT zero-fill ≡ the pre-zeroed world); VirtualFree = TRUE;
Sleep = noop.  The interp's tier heap grows UP from 64 MiB (disjoint:
module cells < 1 MiB, seed heap 1→8 MiB, §W.9 arenas 8 MiB+, argv near
the top).  The EMITTER whitelists — sentinel 198 (unresolved import)
stays unreachable from conformant modules; non-tier externs (including
`use`-imports: single-file emission makes cross-module fns externs)
refuse until the svir_ld closure-link rung.  NAMED UNPINNED CORNER
(sq14's class): reads of never-written malloc memory are 0 on E/S
(zeroed worlds) but garbage on N (CRT malloc) — probes test defined
behavior only.
