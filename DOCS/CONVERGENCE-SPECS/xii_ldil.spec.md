# 38 numera/xii_ldil.iii — Implementation Spec

## Verdict
**PARTIAL.** The gospel carries **two** candidate bodies. The **fuller** (second) draft is a near-complete pruned-SSA IR with typed values, explicit phi nodes, predecessor tracking, a parameter list, and a structural type checker — but it (a) uses const prefix `XL_`, which **collides** with the already-built `omnia/xii_lattice.iii` (`XL_CELL_BYTES`, `XL_CELL_CAP`, `XL_STORE_BYTES`, `XL_PAYLOAD_ARENA_BYTES`, `XL_LOOKUP_PER_HORIZON`, `XL_LOOKUP_ENTRIES`) — every module-level `const` is a linker-global symbol (Trap 2), so this is a hard link failure; (b) is exposed to several compiler traps in its loop/index code (u32-in-u64 pointer math on every `block * STRIDE + n` access, modulo-free but index-heavy); (c) **omits** the refinement-checker, the per-instruction linked-list cursor that the shorter draft and the downstream superoptimizer both reference (`ldil_first_insn`/`ldil_next_insn`/`ldil_insn_*`), `ldil_block_count`, and `ldil_attach_refinement`; (d) the structural type checker is shape-only (does not enforce the "operands have compatible width / no mixed signedness" property its own header promises), and never checks that the **entry** block exists or that PHI input counts match predecessor counts. This spec realizes the **maximal union** of both drafts under the assigned `LDIL_` prefix and closes every gap.

## Purpose
`numera/xii_ldil` IS the **Layered Deterministic Intermediate Language** — the single canonical SSA form into which the III front end lowers all source before code generation. It is the shared substrate of the self-hosted codegen pipeline (consumed by `cg_pure` #39 and `cg_superopt` #40). It is a *builder + query store*, not an algorithm: it owns four content arenas (functions, blocks, instructions, values), each value bearing a bit-width, a signedness flag, and an optional **refinement slot** (an index into the constitutional predicate vocabulary) that the superoptimizer and auditor use to discharge correctness proofs (Curry-Howard, M11). The instruction set is small (29 opcodes: const, integer arithmetic incl. signed/unsigned div/mod, bitwise, shifts incl. arithmetic, six comparisons, load/store, phi, the control trio br/br_cond/ret, and call), each operation total over its bit width with no implementation-defined behavior (M15). **Hexad: kind_essence + kind_form. Ring: R0. K: 1.00.**

## Public API
All builder/mutator functions return either a status (`i32`, W9/W12) or a slot id / sentinel-typed `u32` (`LDIL_SENT = 0xFFFFFFFFu32` on failure, W12). All query functions return a value or a defined miss-sentinel. Names are canonicalized to the `ldil_*` scheme (see **Constant Namespace** for the `xl_* → ldil_*` mapping that Modules 39/40 must bind to).

Lifecycle / arenas:
```
fn ldil_init() -> i32 @export
```

Functions:
```
fn ldil_new_function(name_id: *u8, ret_width: u8) -> u32 @export
fn ldil_fn_add_param(func: u32, width: u8, signed: u8) -> u32 @export
fn ldil_fn_set_entry(func: u32, block: u32) -> i32 @export
fn ldil_fn_add_block(func: u32, block: u32) -> i32 @export
fn ldil_fn_n_params(func: u32) -> u32 @export
fn ldil_fn_param_at(func: u32, idx: u32) -> u32 @export
fn ldil_fn_n_blocks(func: u32) -> u32 @export
fn ldil_fn_block_at(func: u32, idx: u32) -> u32 @export
fn ldil_fn_entry(func: u32) -> u32 @export
fn ldil_fn_ret_width(func: u32) -> u8 @export
fn ldil_fn_name_eq(func: u32, name_id: *u8) -> u8 @export
```

Values:
```
fn ldil_new_value(width: u8, signed: u8) -> u32 @export
fn ldil_set_refinement(value: u32, pred_slot: u32) -> i32 @export
fn ldil_v_width(value: u32) -> u8 @export
fn ldil_v_signed(value: u32) -> u8 @export
fn ldil_v_refinement(value: u32) -> u32 @export
fn ldil_v_definstr(value: u32) -> u32 @export
```

Blocks:
```
fn ldil_new_block(parent_func: u32) -> u32 @export
fn ldil_block_add_pred(block: u32, pred: u32) -> i32 @export
fn ldil_block_n_pred(block: u32) -> u32 @export
fn ldil_block_pred_at(block: u32, idx: u32) -> u32 @export
fn ldil_block_parent(block: u32) -> u32 @export
fn ldil_block_count(func: u32) -> u32 @export
fn ldil_block_n_instrs(block: u32) -> u32 @export
fn ldil_block_instr_at(block: u32, idx: u32) -> u32 @export
fn ldil_block_term(block: u32) -> u32 @export
fn ldil_first_insn(block: u32) -> u32 @export
fn ldil_next_insn(insn: u32) -> u32 @export
```

Instruction emitters (each appends to `block`, allocates the result value where applicable, and returns the result vreg or a status):
```
fn ldil_emit_const(block: u32, width: u8, signed: u8, imm: u64) -> u32 @export
fn ldil_emit_binop(block: u32, op: u8, a: u32, b: u32) -> u32 @export
fn ldil_emit_unop(block: u32, op: u8, a: u32) -> u32 @export
fn ldil_emit_load(block: u32, addr: u32, width: u8, signed: u8) -> u32 @export
fn ldil_emit_store(block: u32, addr: u32, value: u32) -> i32 @export
fn ldil_emit_phi(block: u32, width: u8, signed: u8) -> u32 @export
fn ldil_phi_add(phi_value: u32, pred_block: u32, value: u32) -> i32 @export
fn ldil_emit_br(block: u32, target: u32) -> i32 @export
fn ldil_emit_br_cond(block: u32, cond: u32, t_block: u32, f_block: u32) -> i32 @export
fn ldil_emit_ret(block: u32, value_or_sent: u32) -> i32 @export
fn ldil_emit_call(block: u32, callee: u32, args: *u32, n_args: u32) -> u32 @export
```

Instruction queries:
```
fn ldil_insn_opc(insn: u32) -> u8 @export
fn ldil_insn_out(insn: u32) -> u32 @export
fn ldil_insn_dst(insn: u32) -> u32 @export
fn ldil_insn_n_in(insn: u32) -> u32 @export
fn ldil_insn_in(insn: u32, idx: u32) -> u32 @export
fn ldil_insn_src(insn: u32, idx: u32) -> u32 @export
fn ldil_insn_imm(insn: u32) -> i64 @export
fn ldil_insn_phi_pred(insn: u32, idx: u32) -> u32 @export
fn ldil_insn_block(insn: u32) -> u32 @export
```

Checkers:
```
fn ldil_typecheck_function(func: u32) -> u8 @export
fn ldil_refine_check_function(func: u32) -> u8 @export
```

Notes on convention: `ldil_insn_dst` is an alias of `ldil_insn_out` and `ldil_insn_src(insn,idx)` is an alias of `ldil_insn_in(insn,idx)` — both name-pairs are exported because the two downstream consumer drafts use different names; keeping both removes the binding ambiguity at zero cost. `ldil_insn_imm` returns `i64` (the const/branch-target field; consumers that stored a `u64` via `ldil_emit_const` reinterpret the bit pattern — bit-identity preserved, W5).

## Constant Namespace
**PREFIX = `LDIL_`** — grep of `STDLIB/` confirms **zero** existing `LDIL_*` or `ldil_*` symbols (the only `xii`-named built module is `omnia/xii_lattice.iii`, which uses `XL_*`). The fuller gospel draft's `XL_*` prefix is **rejected** for collision (Trap 2); all of its constants are renamed under `LDIL_`.

Status / sentinels:
```
const LDIL_OK    : i32 =  0i32
const LDIL_E_BAD : i32 = -1i32
const LDIL_E_FULL: i32 = -2i32
const LDIL_SENT  : u32 = 0xFFFFFFFFu32
```

Opcodes (the maximal union — fuller draft's 29 ops; the shorter draft's `OP_*` numbering is superseded and noted in Gap/Fix):
```
const LDIL_OP_CONST   : u8 =  1u8
const LDIL_OP_ADD     : u8 =  2u8
const LDIL_OP_SUB     : u8 =  3u8
const LDIL_OP_MUL     : u8 =  4u8
const LDIL_OP_DIV     : u8 =  5u8    // signed
const LDIL_OP_MOD     : u8 =  6u8    // signed
const LDIL_OP_UDIV    : u8 =  7u8
const LDIL_OP_UMOD    : u8 =  8u8
const LDIL_OP_NEG     : u8 =  9u8
const LDIL_OP_AND     : u8 = 10u8
const LDIL_OP_OR      : u8 = 11u8
const LDIL_OP_XOR     : u8 = 12u8
const LDIL_OP_NOT     : u8 = 13u8
const LDIL_OP_SHL     : u8 = 14u8
const LDIL_OP_SHR     : u8 = 15u8    // logical
const LDIL_OP_SAR     : u8 = 16u8    // arithmetic
const LDIL_OP_EQ      : u8 = 17u8
const LDIL_OP_NE      : u8 = 18u8
const LDIL_OP_SLT     : u8 = 19u8    // signed
const LDIL_OP_SLE     : u8 = 20u8    // signed
const LDIL_OP_ULT     : u8 = 21u8    // unsigned
const LDIL_OP_ULE     : u8 = 22u8    // unsigned
const LDIL_OP_LOAD    : u8 = 23u8
const LDIL_OP_STORE   : u8 = 24u8
const LDIL_OP_PHI     : u8 = 25u8
const LDIL_OP_BR      : u8 = 26u8
const LDIL_OP_BR_COND : u8 = 27u8
const LDIL_OP_RET     : u8 = 28u8
const LDIL_OP_CALL    : u8 = 29u8
const LDIL_OP_NOP     : u8 =  0u8
```

Value widths:
```
const LDIL_W_8  : u8 = 0u8
const LDIL_W_16 : u8 = 1u8
const LDIL_W_32 : u8 = 2u8
const LDIL_W_64 : u8 = 3u8
```

Capacities (see Data Structures for byte sizing & bounds):
```
const LDIL_MAX_VALS       : u32 = 65536u32
const LDIL_MAX_INSTRS      : u32 = 65536u32
const LDIL_MAX_BLOCKS      : u32 = 4096u32
const LDIL_MAX_FUNCS       : u32 = 1024u32
const LDIL_MAX_INPUTS      : u32 = 8u32
const LDIL_MAX_PHI_ENTRIES : u32 = 8u32
const LDIL_MAX_PRED        : u32 = 8u32
const LDIL_MAX_PARAMS      : u32 = 16u32
const LDIL_MAX_FN_BLOCKS   : u32 = 256u32
const LDIL_MAX_BLK_INSTRS  : u32 = 256u32
const LDIL_NAME_BYTES      : u32 = 32u32    // identifier.iii canonical width
```

**Canonical symbol map (Modules 39 & 40 MUST bind to the right-hand names):**
| gospel fuller (`xl_*`) | gospel shorter (`ldil_*`) | CANONICAL |
|---|---|---|
| `xl_init` | `ldil_init` | `ldil_init` |
| `xl_new_function(ret_width)` | `ldil_new_function(name_id,n_params)` | `ldil_new_function(name_id, ret_width)` — merged (keeps name + ret_width) |
| `xl_new_block` | `ldil_new_block` | `ldil_new_block` |
| `xl_fn_set_entry` | `ldil_set_entry` | `ldil_fn_set_entry` |
| `xl_fn_add_block` | — | `ldil_fn_add_block` |
| `xl_fn_n_blocks` / `xl_fn_block_at` | — | `ldil_fn_n_blocks` / `ldil_fn_block_at` |
| `xl_block_n_instrs` / `xl_block_instr_at` / `xl_block_term` | — | `ldil_block_n_instrs` / `ldil_block_instr_at` / `ldil_block_term` |
| `xl_emit_*` | `ldil_append_*` | `ldil_emit_*` |
| `xl_instr_op/out/n_in/in/imm` | `ldil_insn_opc/dst/src/imm` | both exported (aliases) |
| `xl_v_width/v_signed/v_refinement` | — | `ldil_v_width` / `ldil_v_signed` / `ldil_v_refinement` |
| — | `ldil_first_insn`/`ldil_next_insn`/`ldil_block_count`/`ldil_attach_refinement` | retained, re-implemented over the array store |
| `XL_OP_*` | `OP_*` | `LDIL_OP_*` |
| `XL_*` (consts) | `LDIL_*` | `LDIL_*` |

## Data Structures
All storage is module-scope fixed arrays (W8); **no local `var` arrays** (Trap 7). The builder is **single-threaded / non-reentrant** by construction (one global IR under construction at a time) — this is the documented contract of the gospel body and is acceptable for a compiler pass (note it). Bound justification: the IR is built **per-function-batch** for one compilation unit; `ldil_init` resets all live flags, so the arenas are reused across units. 64K values/instrs and 4K blocks comfortably hold the largest III source function (the self-hosted compiler's own functions peak in the low thousands of instructions); 1024 funcs covers a full module's function set. These mirror the fuller gospel draft's bounds verbatim (no down-scaling, M-ambition preserved).

Functions (`LDIL_MAX_FUNCS = 1024`):
```
var LDIL_F_LIVE     : [u8;  1024]
var LDIL_F_NAME     : [u8;  32768]    // 1024 * 32 (identifier bytes)
var LDIL_F_N_PARAMS : [u32; 1024]
var LDIL_F_PARAMS   : [u32; 16384]    // 1024 * 16
var LDIL_F_ENTRY    : [u32; 1024]
var LDIL_F_RET_WIDTH: [u8;  1024]
var LDIL_F_N_BLOCKS : [u32; 1024]
var LDIL_F_BLOCKS   : [u32; 262144]   // 1024 * 256
var LDIL_F_USED     : u32 = 0u32
```

Blocks (`LDIL_MAX_BLOCKS = 4096`):
```
var LDIL_B_LIVE     : [u8;  4096]
var LDIL_B_N_INSTRS : [u32; 4096]
var LDIL_B_INSTRS   : [u32; 1048576]  // 4096 * 256
var LDIL_B_TERM     : [u32; 4096]
var LDIL_B_N_PRED   : [u32; 4096]
var LDIL_B_PRED     : [u32; 32768]    // 4096 * 8
var LDIL_B_PARENT   : [u32; 4096]
var LDIL_B_FIRST    : [u32; 4096]     // head of intra-block insn cursor (for ldil_first_insn)
var LDIL_B_LAST     : [u32; 4096]     // tail, for O(1) append-link
var LDIL_B_USED     : u32 = 0u32
```

Instructions (`LDIL_MAX_INSTRS = 65536`):
```
var LDIL_I_LIVE    : [u8;  65536]
var LDIL_I_OP      : [u8;  65536]
var LDIL_I_OUT     : [u32; 65536]
var LDIL_I_N_IN    : [u32; 65536]
var LDIL_I_IN      : [u32; 524288]    // 65536 * 8
var LDIL_I_PHI_BLK : [u32; 524288]    // parallel to LDIL_I_IN, for PHI predecessor blocks
var LDIL_I_IMM     : [i64; 65536]     // const value / branch target / call-callee
var LDIL_I_BLOCK   : [u32; 65536]     // owning block (for ldil_insn_block)
var LDIL_I_NEXT    : [u32; 65536]     // intra-block linked cursor (ldil_next_insn)
var LDIL_I_USED    : u32 = 0u32
```

Values (`LDIL_MAX_VALS = 65536`):
```
var LDIL_V_LIVE    : [u8;  65536]
var LDIL_V_WIDTH   : [u8;  65536]
var LDIL_V_SIGNED  : [u8;  65536]
var LDIL_V_REFINE  : [u32; 65536]     // predicate slot, or LDIL_SENT
var LDIL_V_DEFINSTR: [u32; 65536]
var LDIL_V_USED    : u32 = 0u32
```

Total BSS ≈ 14.0 MiB (dominated by the three 65536·4 instruction input arrays and the 1M-entry block-instr array). Static, zero-init, reused across compilation units — consistent with the substrate's "full gospel scale" discipline (no practicality down-scaling).

## Dependencies (externs)
```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
```
- `identifier.iii` — **BUILT** (Layer is below this; the shorter draft already uses `ident_copy`, the fuller uses `ident_from_bytes` + `ident_copy`; `ident_eq` is used by `ldil_fn_name_eq`). **Phase-2 action: confirm `ident_copy`/`ident_from_bytes`/`ident_eq` exact signatures in the real `identifier.iii` before sealing the externs** (per §3.5 — gospel externs are unreliable). If `ident_eq` is absent, `ldil_fn_name_eq` falls back to a 32-byte `==` loop over `LDIL_F_NAME` (zero extra deps).

**No not-yet-built dependencies.** This module is a leaf of the codegen pipeline w.r.t. construction; it does **not** call the SMT solver, the egraph, or witness_hook. (The fuller header's prose claims "a refinement checker invokes the SMT module per instruction" — see Gap/Fix: that coupling is deliberately **not** wired here. `ldil_refine_check_function` performs the *local* structural refinement check — every value with a non-sentinel refine slot has a defining instruction whose output is that value — and leaves SMT discharge to `cg_superopt` #40, which already owns the `smt_*` externs. This keeps #38 a pure IR store, preserves M13 reflection-boundedness, and avoids a build-order cycle.)

This module is itself **a dependency of**: `cg_pure` #39 and `cg_superopt` #40 (both not-yet-built). The wave scheduler must build #38 **before** #39 and #40.

## Algorithm
NIH (M1): the entire IR is a hand-rolled struct-of-arrays slab allocator; no libc beyond the `identifier.iii` name copy. No ML/heuristics (M3/M4): every id is the next free slot index, fully deterministic; no scoring, no adaptation. Determinism (M2) + bit-identity (W5): slot ids are assigned strictly by monotone counter (`*_USED`), so identical builder call sequences produce byte-identical arena contents and identical ids across runs/CPUs; all multi-byte fields are stored in native fixed-width slots (no float, no pointer escape). No recursion (W15): the only traversals (typecheck, refine-check) are nested `while` loops over fixed arrays with sentinel-flag termination (W14); no call stack growth.

- **ldil_init**: four `while` loops clear `*_LIVE` for vals/instrs/blocks/funcs; zero the four `*_USED` counters. Returns `LDIL_OK`. (Block `LDIL_B_FIRST/LAST` need not be cleared — they are only read after a block is created and its `N_INSTRS` governs validity.)
- **ldil_new_function(name_id, ret_width)**: bounds-check `LDIL_F_USED < LDIL_MAX_FUNCS` else `LDIL_SENT`; take `f = LDIL_F_USED`; `ident_copy(name_id, &LDIL_F_NAME[f*32])` (helper `ldil_f_name_ptr` computes the byte address with the u32→u64 mask, Trap 4); set entry=`LDIL_SENT`, n_params=0, n_blocks=0, ret_width, live=1; `LDIL_F_USED = f+1`; return `f`.
- **ldil_fn_add_param / ldil_fn_add_block**: bounds-checked append into `LDIL_F_PARAMS` / `LDIL_F_BLOCKS` at `func*STRIDE + n`; param also allocates a fresh value via `ldil_new_value`. Index expression uses the masked-u64 form (Trap 4).
- **ldil_new_value(width, signed)**: counter-bump allocator; set live=1, width, signed, refine=`LDIL_SENT`, definstr=`LDIL_SENT`; return id or `LDIL_SENT` when full.
- **ldil_new_block(parent_func)**: counter-bump; live=1, n_instrs=0, term=`LDIL_SENT`, n_pred=0, parent, first=`LDIL_SENT`, last=`LDIL_SENT`.
- **ldil_block_add_pred**: bounds-checked append into `LDIL_B_PRED[block*8 + n]`, n_pred++.
- **ldil_alloc_instr (internal)**: counter-bump; live=1, out=`LDIL_SENT`, n_in=0, imm=0, next=`LDIL_SENT`.
- **ldil_block_append (internal)**: append `instr` into `LDIL_B_INSTRS[block*256 + n]`, n_instrs++; AND maintain the linked cursor: if `LDIL_B_FIRST[block]==LDIL_SENT` set it to `instr`; if `LDIL_B_LAST[block]!=LDIL_SENT` set `LDIL_I_NEXT[last]=instr`; set `LDIL_B_LAST[block]=instr`; set `LDIL_I_BLOCK[instr]=block`. This dual representation (indexed array + linked list) is what unifies both gospel drafts: #39 fuller iterates by `block_instr_at`, #40 shorter iterates by `first_insn`/`next_insn`; both are O(1)-maintained here.
- **ldil_emit_const**: `out=new_value(w,s)`; `i=alloc_instr()`; sentinel-guard both; set op=CONST, out, n_in=0, imm (the `u64` immediate is stored into the `i64` slot by bit reinterpretation — `imm as i64` — preserving all 64 bits, W5); `LDIL_V_DEFINSTR[out]=i`; append. **Trap 4**: `i * LDIL_MAX_INPUTS` etc. masked before the store.
- **ldil_emit_binop(block,op,a,b)**: validate a,b in range & live (else `LDIL_SENT`); result width = `max(width[a],width[b])` via an `if` (no ordering-SIGSEGV: widths are `u8` enum values 0..3 compared with `>` — **Trap 3 caveat: u8 `>` is safe; it is only `i32/i64` ordering compares that crash**; still, to be maximally safe the skeleton compares widths via subtraction-free equality cascade — see Trap Exposure); signedness = `signed[a]`; comparisons (EQ/NE/SLT/SLE/ULT/ULE) force result width=`LDIL_W_8`, signed=0; allocate out, set op, out, n_in=2, IN[0]=a, IN[1]=b, definstr; append.
- **ldil_emit_unop(block,op,a)**: like binop with n_in=1; result width/signed inherit a.
- **ldil_emit_load(block,addr,width,signed)**: out=new_value(width,signed); op=LOAD, n_in=1, IN[0]=addr.
- **ldil_emit_store(block,addr,value)**: out=`LDIL_SENT`, op=STORE, n_in=2, IN[0]=addr, IN[1]=value; returns the append status (`i32`).
- **ldil_emit_phi(block,width,signed)**: out=new_value; op=PHI, n_in=0 (entries added later); definstr=out; append. PHI must be the first instructions of a block by SSA convention — **the builder does not enforce ordering** (caller contract); `ldil_typecheck_function` flags a PHI that appears after a non-PHI (added check, see Gap/Fix).
- **ldil_phi_add(phi_value,pred_block,value)**: locate `i=LDIL_V_DEFINSTR[phi_value]`; guard `i!=LDIL_SENT`; n=`LDIL_I_N_IN[i]`; bound `n<LDIL_MAX_PHI_ENTRIES`; store `LDIL_I_IN[i*8+n]=value`, `LDIL_I_PHI_BLK[i*8+n]=pred_block`; n_in++.
- **ldil_emit_br(block,target)**: alloc instr, op=BR, imm=`target as i64`, `LDIL_B_TERM[block]=i`, also append to the block's instr list so the cursor & `block_instr_at` see the terminator (the fuller gospel draft set `B_TERM` but did **not** append BR/BR_COND/RET to `B_INSTRS` — **bug, see Gap/Fix**; this spec appends them).
- **ldil_emit_br_cond(block,cond,t,f)**: op=BR_COND, n_in=1, IN[0]=cond, imm encodes `(f<<32)|t` as `u64` then reinterpreted to `i64` (W5 bit-preserving); set term; append.
- **ldil_emit_ret(block,value_or_sent)**: op=RET; if `value_or_sent != LDIL_SENT` then n_in=1, IN[0]=value; set term; append.
- **ldil_emit_call(block,callee,args,n_args)**: out=new_value(LDIL_W_64,0) (call result defaults to 64-bit; refinement attachable later); op=CALL; imm=`callee as i64`; copy up to `LDIL_MAX_INPUTS` (8) args from `args[k]` into `LDIL_I_IN[i*8+k]` via a counted `while` (W14), n_in=min(n_args,8). **Maximal vs. shorter draft**: the shorter draft hard-capped calls at 3 args with prose hand-waving about "auxiliary marshaling"; this spec carries the full 8-input slot the array already provides (no down-scaling). Args beyond 8 are rejected with `LDIL_SENT` (caller must lower wide calls), which is exact, not heuristic.
- **ldil_first_insn / ldil_next_insn / ldil_insn_block**: O(1) reads of `LDIL_B_FIRST` / `LDIL_I_NEXT` / `LDIL_I_BLOCK` with live+bound guards; miss → `LDIL_SENT`.
- **ldil_block_count(func)**: counted `while` over `LDIL_B_USED`, increment when `B_LIVE[i]==1 && B_PARENT[i]==func`. (The shorter draft stored parent in `LDIL_B_FUNC`; here unified as `LDIL_B_PARENT`.)
- **ldil_attach_refinement(value,block,pred_slot)**: thin alias that records the refinement on the value (`ldil_set_refinement`) — the shorter draft's `(vreg,block,pred_slot)` triple is collapsed because in pruned SSA a value's refinement is block-invariant (single definition site); the `block` arg is validated then ignored (kept for source-compat with the shorter consumer). Noted in Gap/Fix.
- **ldil_typecheck_function(func)** (structural, returns `u8` 0/1, W10): nested sentinel-flag `while` (W14, the fuller draft's exact shape, fixed): for each block in `F_BLOCKS[func]`, for each instr, for each input value — verify `v < LDIL_MAX_VALS && V_LIVE[v]==1`. **Added beyond gospel**: (1) verify `F_ENTRY[func] != LDIL_SENT` and the entry block's parent is `func`; (2) verify every block terminates (`B_TERM != LDIL_SENT`); (3) verify operand width compatibility for arithmetic/bitwise ops (both operand widths equal the instr's recorded result width family, except comparisons which yield W_8) — closing the header's promised but unimplemented "compatible width" check; (4) verify no mixed signedness on signed-specific ops; (5) verify each PHI's `n_in` equals the owning block's `n_pred`; (6) verify PHIs precede non-PHIs within a block. All comparisons are `u8`/`u32` equality (no `i32`/`i64` ordering, Trap 3). The flag `ok` is set to 0 on first violation and gates all inner work (the fuller draft's `if ok==1u8` cascade) so there is no `break` (W14).
- **ldil_refine_check_function(func)** (returns `u8`): for each value defined in `func`'s blocks with `V_REFINE != LDIL_SENT`, verify `V_DEFINSTR != LDIL_SENT` and that defining instr's `OUT == value` (the refinement is anchored to a real definition). This is the *local* (M13-bounded) check; full SMT implication discharge is `cg_superopt`'s responsibility (M11/M18 carried there). Pure structural, deterministic, no externs.

## KAT Vectors (>= 3)
A self-test harness drives the builder and checks ids + queried fields byte-for-byte. Because ids are monotone-counter assigned, all expected ids are exact.

**KAT-1 — minimal identity function `f(x)->x`.**
Sequence: `ldil_init()`; `f = ldil_new_function(name_"f", LDIL_W_64)` ⟹ `0`; `p = ldil_fn_add_param(f, LDIL_W_64, 1u8)` ⟹ value `0`; `b = ldil_new_block(f)` ⟹ `0`; `ldil_fn_add_block(f,b)`; `ldil_fn_set_entry(f,b)`; `ldil_emit_ret(b, p)`.
Expected: `ldil_fn_n_params(0)==1`, `ldil_fn_param_at(0,0)==0`, `ldil_fn_entry(0)==0`, `ldil_block_term(0)==0` (instr 0), `ldil_insn_opc(0)==LDIL_OP_RET`, `ldil_insn_n_in(0)==1`, `ldil_insn_in(0,0)==0`, `ldil_v_width(0)==LDIL_W_64`, `ldil_v_signed(0)==1u8`, `ldil_typecheck_function(0)==1u8`, `ldil_block_count(0)==1`.

**KAT-2 — const-fold-shaped body `r = (5 + 3)` then `ret r`.**
`ldil_init()`; `f=ldil_new_function(name_"g", LDIL_W_64)`; `b=ldil_new_block(f)`; `ldil_fn_add_block(f,b)`; `ldil_fn_set_entry(f,b)`;
`c5 = ldil_emit_const(b, LDIL_W_64, 1u8, 5u64)` ⟹ value `0`, instr `0`; `c3 = ldil_emit_const(b, LDIL_W_64, 1u8, 3u64)` ⟹ value `1`, instr `1`; `s = ldil_emit_binop(b, LDIL_OP_ADD, c5, c3)` ⟹ value `2`, instr `2`; `ldil_emit_ret(b, s)` ⟹ instr `3`.
Expected: `ldil_insn_opc(0)==LDIL_OP_CONST`, `ldil_insn_imm(0)==5i64`, `ldil_insn_imm(1)==3i64`, `ldil_insn_opc(2)==LDIL_OP_ADD`, `ldil_insn_in(2,0)==0`, `ldil_insn_in(2,1)==1`, `ldil_insn_out(2)==2`, `ldil_v_definstr(2)==2`, `ldil_block_n_instrs(0)==4`, `ldil_first_insn(0)==0`, `ldil_next_insn(0)==1`, `ldil_next_insn(2)==3`, `ldil_next_insn(3)==LDIL_SENT`, `ldil_typecheck_function(0)==1u8`.

**KAT-3 — diamond CFG with a phi (the SSA join correctness check).**
Build entry `b0` with `br_cond` to `b1`/`b2`; `b1`,`b2` each `br` to `b3`; `b3` has `phi` joining a value from `b1` and a value from `b2`, then `ret phi`. Wire `ldil_block_add_pred(b3,b1)`, `ldil_block_add_pred(b3,b2)`; `phi=ldil_emit_phi(b3,LDIL_W_64,1u8)`; `ldil_phi_add(phi,b1,vA)`; `ldil_phi_add(phi,b2,vB)`.
Expected: `ldil_block_n_pred(3)==2`, `ldil_block_pred_at(3,0)==1`, `ldil_block_pred_at(3,1)==2`, the phi instr `ldil_insn_opc==LDIL_OP_PHI`, `ldil_insn_n_in(phi_instr)==2`, `ldil_insn_phi_pred(phi_instr,0)==1`, `ldil_insn_phi_pred(phi_instr,1)==2`, `ldil_insn_in(phi_instr,0)==vA`, `ldil_insn_in(phi_instr,1)==vB`, and `ldil_typecheck_function(f)==1u8` (phi n_in == block n_pred, phi precedes ret). Negative sub-case: omit one `phi_add` ⟹ `ldil_typecheck_function(f)==0u8` (proves the n_in==n_pred guard FIRES on bad input, not merely passes on good input).

**KAT-4 — refinement round-trip.**
`v = ldil_new_value(LDIL_W_32, 0u8)`; `ldil_v_refinement(v)==LDIL_SENT`; `ldil_set_refinement(v, 7u32)`; `ldil_v_refinement(v)==7u32`. After binding `v` to a defining const instr, `ldil_refine_check_function(f)==1u8`; if `v` is given a refine slot but no defining instr (orphan), `ldil_refine_check_function==0u8` (negative case).

## Trap Exposure
- **Trap 1 (multi-line `fn`)**: every signature in the skeleton is single-line. The widest (`ldil_emit_br_cond`, `ldil_emit_call`) fit on one line — verified.
- **Trap 2 (linker-global const)**: the **root defect** of the fuller gospel body (`XL_*` collides with `omnia/xii_lattice.iii`). **Fix: all consts carry the assigned `LDIL_` prefix**; grep confirms zero `LDIL_*` collisions in `STDLIB/`.
- **Trap 3 (signed ordering SIGSEGV)**: the module stores branch targets and immediates as `i64`, but **never** does an `i32/i64` *ordering* compare. All bounds checks are on `u32` counters (`>=` on `u32` is safe — the trap is specifically `i64`/`i32`). The only `>`-style compare is on `u8` width enum values inside `ldil_emit_binop`; to be maximally safe the result-width selection is written as an equality cascade (`if width[b]==LDIL_W_64 {...}` etc.) rather than `width[b] > w`, eliminating any ordering compare entirely. `ldil_insn_imm` returns `i64` and consumers (#39/#40) must compare it via `==`/`!=` only — noted as a downstream contract.
- **Trap 4 (u32-in-u64-slot pointer math)**: **pervasive** — every block/instr/func index multiply (`func*256`, `block*256`, `i*8`, `block*8`) feeds array indexing. **Fix: every index expression masks to u64 first**: `((idx as u64) & 0xFFFFFFFFu64) * STRIDE`. The name-pointer helper `ldil_f_name_ptr(slot)` uses `(slot as u64 & 0xFFFFFFFFu64) * 32u64`. This is the single most important Phase-2 implementation rule for this module.
- **Trap 5 (u32 pointer-store width)**: only the `ldil_f_name_ptr` path writes through a `*u8` (via `ident_copy`, which is the provider's concern). The IR arrays are typed `[u32]`/`[u8]`/`[i64]` and written by element assignment `ARR[idx] = v` (not through a reconstructed `*u32`), so the store width is the element type — safe. No `*u32` reconstruction in this module.
- **Trap 6 (nested block comments)**: header uses only single-level `/* */`; inline annotations use `//`. No nesting.
- **Trap 7 (local var arrays)**: **none** — all arrays are module-scope (the builder is non-reentrant by contract). The KAT name buffers (`name_"f"`) are module-scope scratch in the *test* harness, not in this module.
- **Trap 8 (`} else {`)**: the skeleton uses no `else` on the emitters (early-return / sentinel-guard style); where `ldil_typecheck` needs it, `} else {` is kept on one line.
- **Trap 9 (em-dash in comment)**: all comments use ASCII `--`; no U+2014.
- **Trap 10 (`let mut` flag)**: `ldil_typecheck_function`/`ldil_refine_check_function` use a `let mut ok : u8` flag — this is the fuller draft's pattern. Per Trap 10 the *preference* is early-return, but W14 forbids `break` and these are read-only multi-pass scans where the flag-gated cascade is the sanctioned idiom (matches the gospel and is proven safe). The flag drives every inner `if ok==1u8` guard (it is not used as a loop-exit counter), so it does not hit the misbehaving checkpoint-flag pattern.
- **Trap 11 (`a % b` after call)**: **none** — this module performs no modulo. (The IR *represents* MOD/UMOD opcodes but never executes them; codegen #39 does.)
- **Trap 12 (`@specialize *T` stride)**: **none** — no generics; all arrays are concrete-typed.

## Gap / Fix List
1. **`XL_` prefix collision (CRITICAL, Trap 2).** Fuller gospel `const XL_*` collides with built `omnia/xii_lattice.iii`. **Fix:** rename all consts to `LDIL_*` (done in this spec); provide the `xl_*→ldil_*` symbol map so #39/#40 bind correctly.
2. **Naming schism between the two drafts.** Fuller uses `xl_*`, shorter uses `ldil_*`; their respective #39/#40 consumers extern the matching scheme. **Fix:** canonicalize to `ldil_*` (the assigned-prefix family), export `ldil_insn_dst`/`ldil_insn_src` aliases for `out`/`in`, and publish the binding table. Phase-2 must update the #39/#40 specs to the canonical names.
3. **Terminators not appended to the block instr list (fuller draft bug).** `xl_emit_br/br_cond/ret` set `XL_B_TERM` but never call `xl_block_append`, so `xl_block_n_instrs`/`xl_block_instr_at` and any linear walk **miss the terminator** — a code generator iterating by `block_instr_at` would emit a block with no branch. **Fix:** all three emitters append to the instr list AND set `B_TERM`; the linked cursor (`B_FIRST/LAST/I_NEXT`) is maintained too.
4. **Missing intra-block instruction cursor.** The shorter draft and the shorter #40 consumer require `ldil_first_insn`/`ldil_next_insn`/`ldil_insn_opc/dst/src/imm`; the fuller draft dropped them in favor of indexed access. **Fix:** add `LDIL_B_FIRST`, `LDIL_B_LAST`, `LDIL_I_NEXT`, `LDIL_I_BLOCK` and maintain both representations in `ldil_block_append` (O(1)). Export the full cursor + query surface.
5. **`ldil_block_count`, `ldil_attach_refinement` absent from fuller draft.** **Fix:** re-implement over the array store (`block_count` = live+parent scan; `attach_refinement` = alias to `set_refinement`, block arg validated-then-ignored because SSA refinements are definition-site-invariant).
6. **Type checker is shape-only; header over-promises.** Fuller `xl_typecheck_function` checks only "inputs live + block terminates," yet its header claims width-compatibility and the prose claims SMT-backed refinement discharge. **Fix:** strengthen the structural checker to also verify entry-exists, operand-width compatibility, no-mixed-signedness, PHI `n_in==n_pred`, and PHI-precedes-non-PHI (all `==`/`!=`, Trap-3-safe). Refinement *implication* (SMT) is explicitly **out of scope** for #38 and deferred to #40 (avoids a build-order cycle and honors M13). Documented, not silently dropped.
7. **`ldil_refine_check_function` is new.** The fuller draft has no refinement checker at all despite the header. **Fix:** add a *local* anchor check (every refined value has a defining instr whose OUT is that value) — the M13-bounded portion that belongs in the IR store.
8. **`ldil_new_function` signature merge.** Fuller takes only `ret_width` (loses the function name); shorter takes `(name_id, n_params)` (loses ret_width, and pre-seeds params instead of `fn_add_param`). **Fix:** merged signature `(name_id, ret_width)`; params added via `ldil_fn_add_param` (cleaner, matches the value-allocating param model). `LDIL_F_NAME` storage retained; `ldil_fn_name_eq` added for the front end / linker to resolve calls by name.
9. **Call arg cap.** Shorter draft hard-capped calls at 3 args (down-scaling with prose hand-wave); fuller draft omitted `call` entirely. **Fix:** carry the full 8-input slot the array already provides; reject >8 with `LDIL_SENT` (exact refusal, M5 reversibility-or-refusal). No marshaling fiction.
10. **Opcode-set divergence.** Shorter draft's `OP_*` (27 ops, distinct LOAD_8..64/STORE_8..64 widths, no DIV/MOD/UDIV/UMOD/NEG/NOT/SAR/SLE/ULE/PHI-by-that-name) vs fuller's 29 `XL_OP_*`. **Fix:** adopt the fuller set (richer, total over bit width, M15) under `LDIL_OP_*`; load/store width is carried on the **value** (`width` arg to `ldil_emit_load`/the stored value's width) rather than in the opcode — strictly more expressive and matches the typed-value model. The shorter draft's width-in-opcode is noted as superseded.
11. **Mandate posture.** M1 ✓ (libc + identifier.iii only). M2 ✓ (counter ids, no float). M3/M4 ✓ (no learning/heuristics anywhere). M5 ✓ (full arenas → refusal via `LDIL_SENT`/`LDIL_E_FULL`, never corruption). M11/M18 ✓ (refinement slots are first-class proof carriers; local anchor checked here, implication discharged by #40). M13 ✓ (no self-reasoning; SMT coupling deliberately externalized). M15 ✓ (29 total ops). M19 ✓ (every op has a cost-vector contribution consumed by the cost calculus via #40; the IR records enough — opcode + widths — for that lookup). **No mandate violation remains.** W-laws: W2 (max 4 params — `ldil_emit_br_cond` has 4 ✓, `ldil_emit_const` has 4 ✓, `ldil_emit_call` has 4 ✓); W8 ✓ (all arenas fixed, bounds justified); W9/W12 ✓ (i32 status / sentinel u32); W10 ✓ (`u8` for the two checkers + name_eq); W13 ✓ (no fn exceeds 20 locals — typecheck is the densest at ~10); W14 ✓ (sentinel-flag loops, no `break`); W15 ✓ (no recursion).
12. **Reentrancy contract.** Like the gospel body, the builder is single-IR/non-reentrant (module-scope arenas, Trap 7 territory). **Fix:** explicitly documented as the contract; `ldil_init` is the reset boundary between compilation units. Acceptable for a serialized compiler pass; flagged so no caller assumes concurrent IRs.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/xii_ldil.iii
 *
 * III STDLIB - numera::xii_ldil
 *
 * Layered Deterministic Intermediate Language (LDIL). Pruned SSA over a
 * struct-of-arrays slab. Typed values (width + signedness + optional
 * refinement predicate slot), explicit phi nodes with predecessor blocks,
 * dual block-instr representation (indexed array + O(1) linked cursor).
 * Shared base of the self-hosted codegen pipeline (cg_pure #39, cg_superopt #40).
 *
 * Builder is single-IR / non-reentrant; ldil_init() is the reset boundary.
 * Refinement IMPLICATION (SMT discharge) is out of scope here -- it lives in
 * cg_superopt #40; this module only records slots and checks local anchoring.
 *
 * Hexad: kind_essence + kind_form.  Ring: R0.  K: 1.00.
 * Discipline: W2, W8, W13, W14, W15.
 */

module numera_xii_ldil

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"

const LDIL_OK    : i32 =  0i32
const LDIL_E_BAD : i32 = -1i32
const LDIL_E_FULL: i32 = -2i32
const LDIL_SENT  : u32 = 0xFFFFFFFFu32

const LDIL_OP_NOP     : u8 =  0u8
const LDIL_OP_CONST   : u8 =  1u8
const LDIL_OP_ADD     : u8 =  2u8
const LDIL_OP_SUB     : u8 =  3u8
const LDIL_OP_MUL     : u8 =  4u8
const LDIL_OP_DIV     : u8 =  5u8
const LDIL_OP_MOD     : u8 =  6u8
const LDIL_OP_UDIV    : u8 =  7u8
const LDIL_OP_UMOD    : u8 =  8u8
const LDIL_OP_NEG     : u8 =  9u8
const LDIL_OP_AND     : u8 = 10u8
const LDIL_OP_OR      : u8 = 11u8
const LDIL_OP_XOR     : u8 = 12u8
const LDIL_OP_NOT     : u8 = 13u8
const LDIL_OP_SHL     : u8 = 14u8
const LDIL_OP_SHR     : u8 = 15u8
const LDIL_OP_SAR     : u8 = 16u8
const LDIL_OP_EQ      : u8 = 17u8
const LDIL_OP_NE      : u8 = 18u8
const LDIL_OP_SLT     : u8 = 19u8
const LDIL_OP_SLE     : u8 = 20u8
const LDIL_OP_ULT     : u8 = 21u8
const LDIL_OP_ULE     : u8 = 22u8
const LDIL_OP_LOAD    : u8 = 23u8
const LDIL_OP_STORE   : u8 = 24u8
const LDIL_OP_PHI     : u8 = 25u8
const LDIL_OP_BR      : u8 = 26u8
const LDIL_OP_BR_COND : u8 = 27u8
const LDIL_OP_RET     : u8 = 28u8
const LDIL_OP_CALL    : u8 = 29u8

const LDIL_W_8  : u8 = 0u8
const LDIL_W_16 : u8 = 1u8
const LDIL_W_32 : u8 = 2u8
const LDIL_W_64 : u8 = 3u8

const LDIL_MAX_VALS       : u32 = 65536u32
const LDIL_MAX_INSTRS      : u32 = 65536u32
const LDIL_MAX_BLOCKS      : u32 = 4096u32
const LDIL_MAX_FUNCS       : u32 = 1024u32
const LDIL_MAX_INPUTS      : u32 = 8u32
const LDIL_MAX_PHI_ENTRIES : u32 = 8u32
const LDIL_MAX_PRED        : u32 = 8u32
const LDIL_MAX_PARAMS      : u32 = 16u32
const LDIL_MAX_FN_BLOCKS   : u32 = 256u32
const LDIL_MAX_BLK_INSTRS  : u32 = 256u32
const LDIL_NAME_BYTES      : u32 = 32u32

/* Functions */
var LDIL_F_LIVE     : [u8;  1024]
var LDIL_F_NAME     : [u8;  32768]
var LDIL_F_N_PARAMS : [u32; 1024]
var LDIL_F_PARAMS   : [u32; 16384]
var LDIL_F_ENTRY    : [u32; 1024]
var LDIL_F_RET_WIDTH: [u8;  1024]
var LDIL_F_N_BLOCKS : [u32; 1024]
var LDIL_F_BLOCKS   : [u32; 262144]
var LDIL_F_USED     : u32 = 0u32

/* Blocks */
var LDIL_B_LIVE     : [u8;  4096]
var LDIL_B_N_INSTRS : [u32; 4096]
var LDIL_B_INSTRS   : [u32; 1048576]
var LDIL_B_TERM     : [u32; 4096]
var LDIL_B_N_PRED   : [u32; 4096]
var LDIL_B_PRED     : [u32; 32768]
var LDIL_B_PARENT   : [u32; 4096]
var LDIL_B_FIRST    : [u32; 4096]
var LDIL_B_LAST     : [u32; 4096]
var LDIL_B_USED     : u32 = 0u32

/* Instructions */
var LDIL_I_LIVE    : [u8;  65536]
var LDIL_I_OP      : [u8;  65536]
var LDIL_I_OUT     : [u32; 65536]
var LDIL_I_N_IN    : [u32; 65536]
var LDIL_I_IN      : [u32; 524288]
var LDIL_I_PHI_BLK : [u32; 524288]
var LDIL_I_IMM     : [i64; 65536]
var LDIL_I_BLOCK   : [u32; 65536]
var LDIL_I_NEXT    : [u32; 65536]
var LDIL_I_USED    : u32 = 0u32

/* Values */
var LDIL_V_LIVE    : [u8;  65536]
var LDIL_V_WIDTH   : [u8;  65536]
var LDIL_V_SIGNED  : [u8;  65536]
var LDIL_V_REFINE  : [u32; 65536]
var LDIL_V_DEFINSTR: [u32; 65536]
var LDIL_V_USED    : u32 = 0u32

/* --- internal helpers --- */
fn ldil_f_name_ptr(slot: u32) -> *u8 {
    // TODO: body per Algorithm § (mask slot to u64, *32, &LDIL_F_NAME[..])
}
fn ldil_alloc_instr() -> u32 {
    // TODO: body per Algorithm § (counter-bump; live=1, out=SENT, n_in=0, imm=0, next=SENT)
}
fn ldil_block_append(block: u32, instr: u32) -> i32 {
    // TODO: body per Algorithm § (indexed append + maintain FIRST/LAST/NEXT + set I_BLOCK)
}

/* --- lifecycle --- */
fn ldil_init() -> i32 @export {
    // TODO: body per Algorithm § (clear 4 LIVE arrays; zero 4 USED counters)
}

/* --- functions --- */
fn ldil_new_function(name_id: *u8, ret_width: u8) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_add_param(func: u32, width: u8, signed: u8) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_set_entry(func: u32, block: u32) -> i32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_add_block(func: u32, block: u32) -> i32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_n_params(func: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_param_at(func: u32, idx: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_n_blocks(func: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_block_at(func: u32, idx: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_entry(func: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_ret_width(func: u32) -> u8 @export {
    // TODO: body per Algorithm §
}
fn ldil_fn_name_eq(func: u32, name_id: *u8) -> u8 @export {
    // TODO: body per Algorithm § (ident_eq on LDIL_F_NAME[func*32], or 32-byte == fallback)
}

/* --- values --- */
fn ldil_new_value(width: u8, signed: u8) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_set_refinement(value: u32, pred_slot: u32) -> i32 @export {
    // TODO: body per Algorithm §
}
fn ldil_v_width(value: u32) -> u8 @export {
    // TODO: body per Algorithm §
}
fn ldil_v_signed(value: u32) -> u8 @export {
    // TODO: body per Algorithm §
}
fn ldil_v_refinement(value: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_v_definstr(value: u32) -> u32 @export {
    // TODO: body per Algorithm §
}

/* --- blocks --- */
fn ldil_new_block(parent_func: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_block_add_pred(block: u32, pred: u32) -> i32 @export {
    // TODO: body per Algorithm §
}
fn ldil_block_n_pred(block: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_block_pred_at(block: u32, idx: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_block_parent(block: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_block_count(func: u32) -> u32 @export {
    // TODO: body per Algorithm § (live + parent scan)
}
fn ldil_block_n_instrs(block: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_block_instr_at(block: u32, idx: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_block_term(block: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_first_insn(block: u32) -> u32 @export {
    // TODO: body per Algorithm § (read LDIL_B_FIRST with guards)
}
fn ldil_next_insn(insn: u32) -> u32 @export {
    // TODO: body per Algorithm § (read LDIL_I_NEXT with guards)
}

/* --- instruction emitters --- */
fn ldil_emit_const(block: u32, width: u8, signed: u8, imm: u64) -> u32 @export {
    // TODO: body per Algorithm § (imm as i64 bit-reinterpret into LDIL_I_IMM)
}
fn ldil_emit_binop(block: u32, op: u8, a: u32, b: u32) -> u32 @export {
    // TODO: body per Algorithm § (width via equality cascade; comparisons -> W_8/unsigned)
}
fn ldil_emit_unop(block: u32, op: u8, a: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_emit_load(block: u32, addr: u32, width: u8, signed: u8) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_emit_store(block: u32, addr: u32, value: u32) -> i32 @export {
    // TODO: body per Algorithm §
}
fn ldil_emit_phi(block: u32, width: u8, signed: u8) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_phi_add(phi_value: u32, pred_block: u32, value: u32) -> i32 @export {
    // TODO: body per Algorithm §
}
fn ldil_emit_br(block: u32, target: u32) -> i32 @export {
    // TODO: body per Algorithm § (append to instr list AND set B_TERM)
}
fn ldil_emit_br_cond(block: u32, cond: u32, t_block: u32, f_block: u32) -> i32 @export {
    // TODO: body per Algorithm § (imm = (f<<32)|t as u64, reinterpret i64; append + term)
}
fn ldil_emit_ret(block: u32, value_or_sent: u32) -> i32 @export {
    // TODO: body per Algorithm § (append + term)
}
fn ldil_emit_call(block: u32, callee: u32, args: *u32, n_args: u32) -> u32 @export {
    // TODO: body per Algorithm § (copy up to 8 args via counted while; imm = callee as i64)
}

/* --- instruction queries (dst/src are aliases of out/in) --- */
fn ldil_insn_opc(insn: u32) -> u8 @export {
    // TODO: body per Algorithm §
}
fn ldil_insn_out(insn: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_insn_dst(insn: u32) -> u32 @export {
    // TODO: body per Algorithm § (alias of ldil_insn_out)
}
fn ldil_insn_n_in(insn: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_insn_in(insn: u32, idx: u32) -> u32 @export {
    // TODO: body per Algorithm §
}
fn ldil_insn_src(insn: u32, idx: u32) -> u32 @export {
    // TODO: body per Algorithm § (alias of ldil_insn_in)
}
fn ldil_insn_imm(insn: u32) -> i64 @export {
    // TODO: body per Algorithm §
}
fn ldil_insn_phi_pred(insn: u32, idx: u32) -> u32 @export {
    // TODO: body per Algorithm § (read LDIL_I_PHI_BLK[insn*8+idx])
}
fn ldil_insn_block(insn: u32) -> u32 @export {
    // TODO: body per Algorithm §
}

/* --- refinement alias (shorter-draft compat) --- */
fn ldil_attach_refinement(value: u32, block: u32, pred_slot: u32) -> i32 @export {
    // TODO: body per Algorithm § (validate block, then set_refinement on value)
}

/* --- checkers --- */
fn ldil_typecheck_function(func: u32) -> u8 @export {
    // TODO: body per Algorithm § (sentinel-flag nested while; entry-exists, inputs-live,
    //       width-compat, no-mixed-sign, term-exists, phi n_in==n_pred, phi-precedes-non-phi)
}
fn ldil_refine_check_function(func: u32) -> u8 @export {
    // TODO: body per Algorithm § (every refined value has DEFINSTR whose OUT==value)
}
```
