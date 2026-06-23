# III — ccsv → iiis-0 Seed-DDC Gap Map

**Goal:** grow `ccsv` (the from-scratch non-gcc C compiler) until it compiles the `iiis-0` C seed
(`COMPILER/BOOT/*.c`), so `seed_ddc.sh` can run with `CC2=ccsv` and close the last trust residual.

**Method (verify-before-scope):** enumerate the seed's feature requirements per file, rather than blind-grinding
toward "26K lines." Each discovered gap = one gated increment (the rhythm that landed hex/for/qualifiers earlier).

---

## 1. The seed, by size (COMPILER/BOOT/*.c)

| tier | files | lines |
|---|---|---|
| **small / clean** | rm2_driver, iiis1_link_stubs, gen_xii_anchor_keypair, verify_xii_manifest, sign_xii_manifest, gen_xii_horizons, gen_xii_r1, gen_xii_lattice | 21–235 |
| **medium** | ceiling, gen_trinity_certs, gen_xii_manifest, acc, hexad_check, proof, witness_alloc, sid | 175–593 |
| **compiler core** | jit_emit, link, emit, cg_rm2, cg_rm1, main, cg_r0, sema, lex, ast, cg_r3, parse | 821–3819 |

## 2. Feature-gap frequency (constructs ccsv does NOT yet support)

`sizeof` is **pervasive** (almost every file). The compiler core (`ast`, `parse`, `cg_r3`, `sema`) is dense with
`switch`, **function pointers**, ternary `?:`, and `goto` (ast.c: 53 gotos, 55 ternaries). The small/medium files
are far cleaner — `ceiling.c` needs only `sizeof` (4×) of the scanned set.

| construct | where it concentrates | difficulty |
|---|---|---|
| `sizeof` | everywhere (ast 47, emit 30, parse 29, lex 21, ...) | MED — entangled w/ the type-size model (§4) |
| ternary `?:` | ast 55, sema 51, cg_r3 43, parse 41 | LOW — lower to IF/ELSE; gcc-gatable |
| `switch`/`case` | ast 18, cg_r3 13, cg_r0 11, main 9 | MED — jump/if-cascade |
| function pointers | ast 36, lex 7, parse 8, main 9 | HIGH — call-through-value + fn-addr table |
| `goto`/labels | ast 53 (only) | MED — SVIR has no arbitrary jump; needs structuring or a label dispatch |
| array struct fields | ceiling (SHA ctx), link 3, parse 6 | MED — struct field of array type + offset |
| `do…while` | ast 6, main 4, parse 4, cg* | LOW — loop variant |
| `float`/`double` | main 3, sema 2, cg_r3 1 | HIGH — SVIR is integer-only (likely out of scope / refactor) |

## 3. Parse-level status (the permissive-parsing caveat)

ccsv currently PARSES every small/medium file incl. `ceiling.c` without choking (`ccsv_rc=0`, and the emitted
`.iii` compiles through iiis-2). **This is necessary but NOT sufficient:** ccsv is permissive — unknown constructs
mis-parse (e.g. `sizeof`→nothing, fn-ptr call→wrong) WITHOUT erroring. So "compiles" must never be read as
"correct"; every seed file needs a CORRECTNESS check (run + differential vs gcc / known output), not just a
parse-through. The crypto suite is the proof ccsv's codegen is correct on real code; the seed work extends that
verification to the seed's own constructs.

## 4. THE DEEP BOTTLENECK — the type-size model (must be surfaced)

ccsv compiles C to **SVIR, an i64 stack machine**, so every integer is 8 bytes: `int`, `uint32_t`, even `uint16_t`
are all i64 (with width-MASKING for wraparound, but 8-byte STORAGE). Byte arrays are the one exception (the recent
`uint8_t[]`→stride-1 work). Consequences:

- `sizeof(int)`=8 (C: 4); `sizeof(uint32_t)`=8 (C: 4); `sizeof(uint32_t[8])`=64 (C: 32).
- A struct's layout/size under ccsv differs from standard C.

For **behavioral** correctness this is often fine (the crypto suite is bit-exact because it uses explicit widths +
masking, and never depends on `sizeof`/layout). But the **seed-DDC standard is byte-identity** (per project canon:
"byte-diff = supply-chain, not DDC"). iiis-0 is a compiler that serializes exact bytes; if its codegen ever depends
on host `sizeof`/struct layout, ccsv's i64 model would diverge the output. **This is the central architectural
question for `CC2=ccsv`:**

- **(a) make it ideal** — give ccsv a real C type-size model (`int`=4, `uint16_t`=2, `uint32_t`=4) with SVIR
  sub-64-bit memory ops (LOAD16/32, STORE16/32) + proper offsets. Big, but the `uint8_t[]` work already proved the
  pattern (element-size-driven stride). The "surpass the bottleneck" path.
- **(b) prove iiis-0 is size-agnostic** — if the seed uses explicit widths for its TARGET output and never lets
  host `sizeof`/layout leak into emitted bytes, ccsv's i64 host model is behaviorally transparent and byte-identity
  can still hold. Requires auditing iiis-0's serialization paths.

Either way, this is named here so it is not discovered late.

## 5. Worklist (ordered: unblock the most, lowest entanglement first)

1. **ternary `?:`** — LOW effort, gcc-gatable, very common. *(first increment)*
2. **`sizeof`** (ccsv-consistent: int=8, char/uint8_t=1, struct=STSZ, ptr=8, array=N·elem) — pervasive; gate on
   ccsv's own consistency (not vs gcc, per §4).
3. **array struct fields** — unblocks `ceiling.c`'s SHA context + serialization code.
4. **`do…while`**, **global scalars**, **comma in for**, more libc builtins.
5. **`switch`/`case`** — if-cascade or jump table.
6. **function pointers** — the compiler-core gate (ast/parse/cg_r3); call-through-value + fn-addr table.
7. **`goto`/labels** (ast.c) — structurer or label-dispatch loop.
8. **the type-size model (§4)** — the architectural decision; gated by the user's (a)/(b) choice.

## 6. Recommended path

Climb the tiers: clear ternary + sizeof + array-struct-fields (unblocks the small/medium files behaviorally),
verify a *runnable* medium file end-to-end against gcc, THEN take the §4 decision before the compiler core (where
fn-pointers + the type-size model both bite). Each step stays a single gated, differential-checked commit.
