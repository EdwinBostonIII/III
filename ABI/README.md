# III-ABI — `extern @abi(c-msvc-x64)` (R1.C1)

Implementation of the III ABI module per `DOCS/III-ABI.md`. Validates,
lowers, and marshals the **single legal cross-language bridge** in III.

## The single rule

> The only legal foreign ABI is `c-msvc-x64`, written
> `extern @abi(c-msvc-x64) { … }`.
> Permitted only in modules whose ring is `R0` (sanctum) or `R3`
> (user). Forbidden in `R-1` and `R-2` (TYPE-EXTERN-001).

There is no other ABI. `c-sysv-x64`, `system-v`, `aapcs`, etc. are
diagnosed `BAD_ABI_NAME`. Non-`c-msvc-x64` text inside `@abi(...)` is
the canonical compiler-error path.

## Calling-convention reference (Microsoft x64)

| Slot # | INTEGER class | SSE class |
|:------:|:-------------:|:---------:|
| 0 | `RCX` | `XMM0` |
| 1 | `RDX` | `XMM1` |
| 2 | `R8`  | `XMM2` |
| 3 | `R9`  | `XMM3` |
| ≥4 | stack `[rsp+32+8·k]` | stack `[rsp+32+8·k]` |

Slot positions are **shared**: an INTEGER and an SSE arg both consume
slot N — INTEGER goes to the GPR for slot N, SSE goes to the XMM for
slot N, and the next arg uses slot N+1 regardless of class.

| Item | Value |
|------|-------|
| Shadow space | **32 B** (caller reserves `[rsp+0..+31]`) |
| Stack alignment at `call` | **16 B** |
| Aggregates ≤ 8 B and power-of-two | passed inline as INTEGER |
| All other aggregates / arrays > 8 B | **MEMORY** — caller passes a hidden `&` in the INTEGER slot |
| Return INTEGER | `RAX` |
| Return SSE     | `XMM0` |
| Return MEMORY  | hidden `&out` is **prepended** as arg-0 in `RCX`; remaining args shift right one slot |
| Return `()`/void | no register |

## Synthesized cycle

Each `extern @abi(c-msvc-x64)` call site is wrapped in a synthesized
cycle whose forward hexad is **`EXTERN_C_CALL`** with inverse
**`Compromise<MEDIUM>`** (per spec §1.4 / `DOCS/III-ABI.md`).

## Build

```
cmd /c ABI\build\build.bat
```

Produces:

* `ABI\build\libiii_abi.a` — static library (NIH C11, `-Werror`)
* `ABI\build\iii_abi_tool.exe` — CLI driver
* `ABI\build\iii_abi_test.exe` — self-checking test runner

## Test

```
ABI\build\iii_abi_test.exe
```

Expected tail line:

```
=== 65 passed, 0 failed ===
```

## CLI

```
iii_abi_tool.exe validate <file.iii>
iii_abi_tool.exe lower    <file.iii>
iii_abi_tool.exe marshal-demo
```

## Public API (essentials)

```c
#include <iii/abi.h>

iii_abi_diag_t d;
int rc = iii_abi_validate_extern(module, extern_decl, src, src_len, &d);

iii_abi_signature_t sig;
rc = iii_abi_lower_signature(extern_decl, extern_item, &sig);

char buf[4096];
size_t n = iii_abi_marshal_call(&sig, buf, sizeof buf);
```

`iii_abi_signature_t` carries up to 32 lowered parameter slots, the
return-class location, `shadow_space=32`, `stack_arg_bytes`, the
16-aligned `total_stack`, and the `hidden_ret_ptr` flag.

## Layout

```
ABI/
├── include/iii/abi.h        — public API
├── src/                     — abi_helpers, abi_validate, abi_lower, abi_marshal
├── tools/iii_abi_tool.c     — CLI
├── tests/test_abi.c         — 65 assertions
└── build/build.bat          — build script
```

## Known parser interaction

The bootstrap GRAMMAR parser tokenises `c-msvc-x64` as five tokens
(IDENT-PUNCT-IDENT-PUNCT-IDENT) and currently records two
recovery-diagnostic notes (`expected RPAREN`, `expected LBRACE`) before
re-synchronising at the brace. The validator therefore reads the
real ABI name **directly from the source bytes** spanning the
`extern_decl` node, which is robust to that recovery. Lowering tests
in this module construct `EXTERN_ITEM` AST nodes directly to bypass the
recovery loss; this is documented inline in `tests/test_abi.c`.
