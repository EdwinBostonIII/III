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
