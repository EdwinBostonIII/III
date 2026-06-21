# III — `sovparse` Operand Model (the reference to keep open while adding forms)

Read-only map of the operand-state variables every `sp_dispatch_instr` case consumes, so adding a form is
mechanical and a mis-wire is obvious. Ground truth: `STDLIB/sovtc/sovparse.iii` lines 109-117, 334-341, 283-315,
442-446. **No new variables are needed for the remaining integer forms** (`movb`, B1-B4) — they all reuse this model.

## 1. Two operands, one tagged shape

AT&T order is `op SRC, DST`. `sp_two_ops()` (`:442`) parses both and leaves them in two parallel register-sets:

- **`S1*` = the SOURCE** (first operand) — a *saved copy* taken right after parsing operand 1.
- **`OP*` = the DEST** (second/last operand) — left live in the `OP*` set.

A unary op (`pushq`, `negq`, `setcc`, shifts' reg) calls `sp_operand()` directly → operand lands in `OP*` only.

Each operand is a **tagged union**: a *kind tag* (`S1K`/`OPK`) plus a payload whose valid fields depend on the tag.

## 2. The kind tags and their VALID payload fields

| Tag `K` | Operand | VALID payload fields | Other fields are STALE — do not read | A `.s` example |
|:---:|---|---|---|---|
| **0** | register | `R` = reg# 0-15 | I, D, SEC, OFF, INDEX, SCALE | `%rax` → R=0 |
| **1** | immediate | `I` = i64 value | R, D, SEC, OFF, … | `$5` → I=5 |
| **2** | mem `disp(%base)` | `R` = **base** reg, `D` = disp | I, SEC, OFF, INDEX, SCALE | `-8(%rbp)` → R=5, D=-8 |
| **3** | sym `(%rip)` | `SEC` + `OFF` = resolved symbol | **R is NOT used** (RIP-relative), I, D, … | `L_x(%rip)` → SEC/OFF |
| **4** | SIB `disp(%b,%i,sc)` | `R`=base, `INDEX`, `SCALE`, `D`=disp | I, SEC, OFF | `8(%rax,%rcx,4)` |

Note `R` does double duty: the **register** for kind 0, the **mem base** for kinds 2/4. For kind 3 `R` is meaningless.
(The stale comment at `:109` lists only 0-3 — **kind 4 = SIB** was added later; update it when you pass through.)

Field name → variable: `K→{S1K,OPK}  R→{S1R,OPR}  D→{S1D,OPD}  I→{S1I,OPI}  SEC→{S1SEC,OPSEC}  OFF→{S1OFF,OPOFF}  INDEX→{S1INDEX,OPINDEX}  SCALE→{S1SCALE,OPSCALE}`.

## 3. The dispatch contract (the discipline that prevents every DIFFER bug)

A binary-op case (see `movq` `:454`, `movl` `:457`) MUST:

1. `sp_two_ops()` — fill `S1*` (src) and `OP*` (dst).
2. **Branch on the TAGS `(S1K, OPK)` first** — this selects the encoding form.
3. Read **only the payload fields valid for those tags** (the table above), then call the matching `sov_*` helper.
4. Fall through to `PARSE_ERR = 1u32` for an unhandled `(S1K, OPK)` (loud, located).

> **THE RULE (the whole DIFFER-bug class in one line):** *never read `SEC/OFF`, `I`, `INDEX/SCALE`, or `D`
> without first confirming the matching `K`.* `S1*` carries the **previous** instruction's values, so an
> unguarded read encodes garbage — `leaq` read `S1SEC/S1OFF` on a kind-2 operand (B1), `shlq` read a stale
> `S1I=3` on a kind-0 `%cl` (B4). Both fixes = **add the missing `S1K` branch.** Same root cause.

The standard `(S1K, OPK)` form-matrix (as `movq` wires it):

| `(S1K,OPK)` | meaning | fields used | helper shape |
|:---:|---|---|---|
| (0,0) | reg → reg | `S1R`, `OPR` | `sov_*_rr(OPR, S1R)` |
| (1,0) | imm → reg | `S1I`, `OPR` | `sov_*_imm32(OPR, S1I)` |
| (2,0) | `disp(%base)` → reg (**load**) | `S1R`,`S1D`, `OPR` | `sov_load_*(OPR, S1R, S1D)` |
| (0,2) | reg → `disp(%base)` (**store**) | `S1R`, `OPR`,`OPD` | `sov_store_*(S1R, OPR, OPD)` |
| (3,0) | `sym(%rip)` → reg (**rip load**) | `S1SEC`,`S1OFF`, `OPR` | `sov_*_load_rip_sym(OPR, S1SEC, S1OFF)` |
| (0,3) | reg → `sym(%rip)` (**rip store**) | `S1R`, `OPSEC`,`OPOFF` | `sov_*_store_rip_sym(S1R, OPSEC, OPOFF)` |
| (4,0) | SIB → reg (**load**) | `S1R`,`S1INDEX`,`S1SCALE`,`S1D`, `OPR` | `sov_load_sib_d(OPR, S1R, S1INDEX, S1SCALE, S1D)` |
| (0,4) | reg → SIB (**store**) | `S1R`, `OPR`,`OPINDEX`,`OPSCALE`,`OPD` | `sov_store_sib_d(S1R, OPR, OPINDEX, OPSCALE, OPD)` |

## 4. The remaining forms, mapped to this model (so you don't lose sight)

- **`movb` (A1) — pure clone of `movl` over the SAME variables.** Same `(S1K,OPK)` matrix, same fields; ONLY the
  encoder bytes change (opcode `0x8A` load / `0x88` store, **no REX.W**, 8-bit reg). Don't add state — copy the
  `movl` block's dispatch shape and swap the helper family.
- **`movl`-rip (A2/A3 — done).** (3,0) reads `S1SEC/S1OFF`+`OPR`; the (0,3) store reads `S1R`+`OPSEC/OPOFF`. ✓
- **B1 `leaq` `disp(%base)`.** Make `:457` a `S1K` switch: `S1K==3` → `S1SEC/S1OFF` (rip-sym); `S1K==2` →
  `S1R/S1D` (base+disp). The bug was *no switch* → always read `S1SEC/S1OFF`.
- **B2 `callq *%reg`.** Indirect call is **outside** the `OP*` model — `callq` has its own operand path
  (`SYM_*`/name). Peek for `'*'`, parse the reg directly, emit `FF /2`. It is not a kind; don't force it into one.
- **B3 shift-by-1.** Encoder-only (`sov_shift_imm8`); it reads `S1I` (the count). Special-case `I==1` → `D1` form.
- **B4 `shlq %cl`.** Switch `S1K`: `==1` → `S1I` (imm count); `==0` → the `%cl` form (source reg must be `%cl`=1).
  The bug was *no switch* → read the stale `S1I`.

## 5. One-glance invariants

- `S1*` = source, `OP*` = dest. A binary helper is almost always `sov_op(OPR_or_dst_fields, S1_src_fields)`.
- Tag before payload. An unguarded `SEC/OFF/I/INDEX/SCALE/D` read is the DIFFER-bug signature.
- New integer forms add **dispatch cases + encoder helpers**, never new operand variables — the model above is complete through SIB.
- `sov_rex` always emits a `0x40` byte → for 8/32-bit forms emit REX only when a reg/base `>= 8`.
