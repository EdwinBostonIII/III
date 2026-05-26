# 39 numera/cg_pure.iii — Implementation Spec

## Verdict
PARTIAL — Two gospel copies exist (gospel lines 11077–11617 and 12497–13275). The SECOND copy is the fuller, internally-consistent design (3 passes: live-interval computation, linear-scan allocation **with spilling**, branch-fixup emission; opcode numbering byte-identical to Module 38 `xl_*`). This spec is built from copy-2 and folds in copy-1's *correct* compare/branch lowering. As written, copy-2 **will not compile** (every register-pool table is a local `var` array — Trap 7) and is functionally incomplete or wrong on six axes: (a) no `CG_MODE_R3`/`CG_MODE_RM1` and **zero** RM1 privileged emission — the single largest miss vs. the maximal dispatch; (b) no prologue/epilogue and callee-saved registers (RBX,R12–R15) are allocated but never preserved (ABI break); (c) parameters never bound to incoming ABI argument registers; (d) spill slots are *assigned* but never reserved on the stack nor stored/reloaded — spilled values silently read RAX; (e) `OP_EQ` clears the flags with `xor` *after* `cmp`, and `OP_BR_COND` compares `cond,cond` (always ZF=1) — both emit wrong machine code; (f) output capacity is hardcoded to 1 MiB ignoring the caller's buffer (overrun → M5 bricking risk). All are closed below.

## Purpose
`cg_pure` is the pure-III x86-64 code generator: it lowers one `xii_ldil` (XII-LDIL, Module 38) SSA function to byte-exact x86-64 machine code via **linear-scan register allocation** over the 16 GPRs under the chosen ABI (caller/callee split), emitting REX / opcode / ModR/M / SIB / displacement / immediate explicitly. It is the strictly-more-capable register-allocating successor to the stack-machine `COMPILER/BOOT/cg_r0.iii`. Two modes: `CGP_MODE_R3` (userspace, no privileged instructions) and `CGP_MODE_RM1` (Ring −1, may emit LGDT/LIDT/MOV CRn/WBINVD/etc., capability-gated). **Hexad:** kind_motion. **Ring:** R0 (the generator runs in R0; emitted code targets the ring named by the mode). **K-vector:** 0.99 (per the fuller copy-2 header).

## Public API
All public fns return `i32` status (W9/W12): `CGP_OK`(0) or a negative error. The 6-argument `cg_compile` of copy-1 **violates W2 (≤4 params)**; this spec passes the compile request as an aggregate by pointer (W2-clean) and exposes thin convenience setters.

```
fn cg_init() -> i32 @export
fn cg_request_begin(func: u32, mode: u8) -> i32 @export
fn cg_request_set_buffer(out_buf: *u8, out_cap: u64) -> i32 @export
fn cg_request_set_witness(producer: *u8, enable: u8) -> i32 @export
fn cg_compile(out_len: *u64) -> i32 @export
fn cg_compile_capability(cap_id: u64, out_len: *u64) -> i32 @export
fn cg_last_error() -> i32 @export
```

- `cg_init()` — load the register-pool encoding table; idempotent; `CGP_OK`.
- `cg_request_begin(func, mode)` — start a compile request for LDIL function `func`; `mode` ∈ {`CGP_MODE_R3`,`CGP_MODE_RM1`}; resets per-request state; returns `CGP_E_MODE` if mode invalid.
- `cg_request_set_buffer(out_buf, out_cap)` — bind the caller's output buffer **and its true capacity** (closes the hardcoded-cap defect); `CGP_E_BAD` on null.
- `cg_request_set_witness(producer, enable)` — optionally enable an M6 witness fragment over (func, mode, output-commit); `producer` is a 32-byte identifier; `enable`=0 disables.
- `cg_compile(out_len)` — run the 3-pass pipeline for an **R3** request and write `*out_len`. Returns `CGP_E_MODE` if the bound mode is `CGP_MODE_RM1` (privileged emission requires the capability entry point).
- `cg_compile_capability(cap_id, out_len)` — the **capability-gated** entry (M8): permits `CGP_MODE_RM1` privileged emission iff `cap_verify_rights(cap_id, CGP_RIGHT_EMIT_PRIV)` returns 1; otherwise `CGP_E_CAP`. For an R3 request it behaves as `cg_compile`.
- `cg_last_error()` — last error code latched by the most recent compile (diagnostics; W12 sentinel-typed).

Return-status convention: every `@export` fn returns `i32` with `== CGP_OK` / `!= CGP_OK` testing only (W9/W11). The internal `cg_emit_*` encoder helpers also return `i32` and are **not** `@export`.

## Constant Namespace
PREFIX = `CGP_` . **Grep result:** `grep -r "CGP_" STDLIB/` → **no matches** (no collision). `numera_cg_pure`, `cg_init`, `cg_compile`, `cg_compile_function`, `cg_emit_byte` → **no matches** in `STDLIB/` (clear). Note: copy-1 and copy-2 both used the bare `CG_` prefix (`CG_OK`, `CG_MODE_R3`, `CG_REG_RAX`, `CG_MAX_VALS`, …). Bare `CG_` is **too collision-prone** (each is a linker-global `L_CG_*` per Trap 2; cg_superopt/cg_r0 share the namespace) — every constant below is re-prefixed `CGP_`.

Module-level constants (name : type = value):

```
CGP_OK          : i32 =  0i32
CGP_E_BAD       : i32 = -1i32
CGP_E_OOR       : i32 = -2i32      // output buffer exhausted
CGP_E_MODE      : i32 = -3i32      // invalid / disallowed mode
CGP_E_REG       : i32 = -4i32      // allocation impossible
CGP_E_CAP       : i32 = -5i32      // capability check failed (RM1)
CGP_E_PRIV      : i32 = -6i32      // privileged op requested in R3

CGP_MODE_R3     : u8  = 0u8
CGP_MODE_RM1    : u8  = 1u8

// --- LDIL opcodes (MUST equal Module 38 XL_OP_* numbering) ---
CGP_OP_CONST    : u8 =  1u8
CGP_OP_ADD      : u8 =  2u8
CGP_OP_SUB      : u8 =  3u8
CGP_OP_MUL      : u8 =  4u8
CGP_OP_DIV      : u8 =  5u8
CGP_OP_MOD      : u8 =  6u8
CGP_OP_UDIV     : u8 =  7u8
CGP_OP_UMOD     : u8 =  8u8
CGP_OP_NEG      : u8 =  9u8
CGP_OP_AND      : u8 = 10u8
CGP_OP_OR       : u8 = 11u8
CGP_OP_XOR      : u8 = 12u8
CGP_OP_NOT      : u8 = 13u8
CGP_OP_SHL      : u8 = 14u8
CGP_OP_SHR      : u8 = 15u8
CGP_OP_SAR      : u8 = 16u8
CGP_OP_EQ       : u8 = 17u8
CGP_OP_NE       : u8 = 18u8
CGP_OP_SLT      : u8 = 19u8
CGP_OP_SLE      : u8 = 20u8
CGP_OP_ULT      : u8 = 21u8
CGP_OP_ULE      : u8 = 22u8
CGP_OP_LOAD     : u8 = 23u8
CGP_OP_STORE    : u8 = 24u8
CGP_OP_PHI      : u8 = 25u8
CGP_OP_BR       : u8 = 26u8
CGP_OP_BR_COND  : u8 = 27u8
CGP_OP_RET      : u8 = 28u8
CGP_OP_CALL     : u8 = 29u8

// --- x86-64 register encodings (low 3 bits; high bit via REX) ---
CGP_REG_RAX : u8 =  0u8
CGP_REG_RCX : u8 =  1u8
CGP_REG_RDX : u8 =  2u8
CGP_REG_RBX : u8 =  3u8
CGP_REG_RSP : u8 =  4u8
CGP_REG_RBP : u8 =  5u8
CGP_REG_RSI : u8 =  6u8
CGP_REG_RDI : u8 =  7u8
CGP_REG_R8  : u8 =  8u8
CGP_REG_R9  : u8 =  9u8
CGP_REG_R10 : u8 = 10u8
CGP_REG_R11 : u8 = 11u8
CGP_REG_R12 : u8 = 12u8
CGP_REG_R13 : u8 = 13u8
CGP_REG_R14 : u8 = 14u8
CGP_REG_R15 : u8 = 15u8

// --- allocator pool sizing ---
CGP_N_REGS         : u32 = 14u32        // RSP(4),RBP(5) excluded from pool
CGP_N_CALLER_SAVED : u32 =  9u32        // RAX,RCX,RDX,RSI,RDI,R8,R9,R10,R11
CGP_MAX_VALS       : u32 = 65536u32
CGP_MAX_INSTRS     : u32 = 65536u32
CGP_MAX_BLOCKS     : u32 = 4096u32
CGP_MAX_FIXUPS     : u32 = 4096u32
CGP_MAX_ORDER      : u32 = 65536u32     // linear-scan order array bound
CGP_SENT           : u32 = 0xFFFFFFFFu32
CGP_REG_NONE       : u8  = 0xFFu8

// --- frame / spill ---
CGP_SPILL_SLOT_BYTES : u64 = 8u64       // each spill slot is one qword
CGP_SHADOW_BYTES     : u64 = 32u64      // Win64 shadow space for emitted CALLs
CGP_STACK_ALIGN      : u64 = 16u64

// --- ABI argument registers (Win64 integer arg order) ---
CGP_ARG0 : u8 = 1u8   // RCX
CGP_ARG1 : u8 = 2u8   // RDX
CGP_ARG2 : u8 = 8u8   // R8
CGP_ARG3 : u8 = 9u8   // R9
CGP_MAX_ABI_ARGS : u32 = 4u32

// --- capability right bit (M8); confirm exact bit vs aether/capability.iii ---
CGP_RIGHT_EMIT_PRIV : u64 = 0x0000000000000040u64   // PLACEHOLDER — see Gap list

// --- SETcc / Jcc secondary opcodes (0F xx) ---
CGP_SETE  : u8 = 0x94u8
CGP_SETNE : u8 = 0x95u8
CGP_SETL  : u8 = 0x9Cu8
CGP_SETLE : u8 = 0x9Eu8
CGP_SETB  : u8 = 0x92u8
CGP_SETBE : u8 = 0x96u8
CGP_JE    : u8 = 0x84u8
CGP_JNE   : u8 = 0x85u8
CGP_JL    : u8 = 0x8Cu8
CGP_JLE   : u8 = 0x8Eu8
CGP_JB    : u8 = 0x82u8
CGP_JBE   : u8 = 0x86u8
```

## Data Structures
All allocator/scratch state is **module-scope** (Trap 7: local `var` arrays do not compile — copy-2's `order`, `pref`, `phys_busy`, `phys_owner`, `reg_busy`, `reg_owner` are all illegal locals and are hoisted here). The module is **non-reentrant** (single-threaded compile; acceptable for a serialized code generator — noted, matching cg_r0's singleton state model).

| Name | Type | Size | Bound justification (W8) |
|---|---|---|---|
| `CGP_REG_ENC` | `[u8; 14]` | 14 | Pool index → x86 reg encoding; fixed 14 usable GPRs. |
| `CGP_REG_CALLEE` | `[u8; 14]` | 14 | 1 if pool slot is callee-saved (RBX,R12–R15) → save/restore. |
| `CGP_V_FIRST` | `[u32; 65536]` | 65536 | First-def position per value; bound = `CGP_MAX_VALS` (matches Module 38 `XL_MAX_VALS`). |
| `CGP_V_LAST` | `[u32; 65536]` | 65536 | Last-use position per value. |
| `CGP_V_REG` | `[u32; 65536]` | 65536 | Assigned pool index, or `CGP_SENT` if spilled/unset. |
| `CGP_V_SPILL` | `[u32; 65536]` | 65536 | Stack slot index when spilled, else `CGP_SENT`. |
| `CGP_INSTR_POS` | `[u32; 65536]` | 65536 | Linear scheduling position per instr; bound = `CGP_MAX_INSTRS`. |
| `CGP_BLOCK_POS` | `[u32; 4096]` | 4096 | Byte offset of each block in output; bound = `CGP_MAX_BLOCKS`. |
| `CGP_ORDER` | `[u32; 65536]` | 65536 | Values sorted by first-def for the scan; bound = `CGP_MAX_VALS`. |
| `CGP_REG_BUSY` | `[u8; 14]` | 14 | Active-set occupancy per pool slot. |
| `CGP_REG_OWNER` | `[u32; 14]` | 14 | Value currently owning each pool slot, or `CGP_SENT`. |
| `CGP_FIXUP_OFF` | `[u64; 4096]` | 4096 | Patch byte offset; bound = `CGP_MAX_FIXUPS`. |
| `CGP_FIXUP_TGT` | `[u32; 4096]` | 4096 | Target block id of each fixup. |
| `CGP_FIXUP_PCEND` | `[u64; 4096]` | 4096 | rel32 reference point (byte after disp). |
| `CGP_WIT_PRODUCER` | `[u8; 32]` | 32 | Witness producer identifier (M6). |
| `CGP_WIT_COMMIT` | `[u8; 32]` | 32 | Output commit (hash of emitted bytes) scratch. |

Module-scope scalars (request state — replaces copy-2's globals, prefixed):
`CGP_OUT:u64`, `CGP_LEN:u64`, `CGP_CAP:u64`, `CGP_SPILL_N:u32`, `CGP_FIXUP_N:u32`, `CGP_FUNC:u32`, `CGP_MODE:u8`, `CGP_FRAME_BYTES:u64`, `CGP_WIT_ENABLE:u8`, `CGP_LAST_ERR:i32`, `CGP_INITED:u8`.

Pool ordering (set by `cg_init`, copy-2 verbatim with callee flags): index 0..8 = caller-saved {RAX,RCX,RDX,RSI,RDI,R8,R9,R10,R11} (`CGP_REG_CALLEE`=0), index 9..13 = callee-saved {R12,R13,R14,R15,RBX} (`CGP_REG_CALLEE`=1). Caller-saved are tried first so call-free ranges avoid save/restore cost (deterministic, not heuristic — fixed pool order).

## Dependencies (externs)
Each provider with its gospel module number. **Module 38 is NOT-YET-BUILT** (no `STDLIB/**/xii_ldil.iii`; confirmed by glob) — the wave scheduler must order Module 38 before this module. Module-38 `xl_*` signatures verified against the FULLER gospel copy (gospel lines 12425–12489): exact match.

```
// --- Module 38 numera/xii_ldil.iii (NOT-YET-BUILT) ---
extern @abi(c-msvc-x64) fn xl_fn_n_blocks(func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_block_at(func: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_n_params(func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_param_at(func: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_n_instrs(block: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_instr_at(block: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_term(block: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_op(instr: u32) -> u8 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_out(instr: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_n_in(instr: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_in(instr: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_imm(instr: u32) -> u64 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_v_width(value: u32) -> u8 from "xii_ldil.iii"     // for sized LOAD/STORE
extern @abi(c-msvc-x64) fn xl_v_signed(value: u32) -> u8 from "xii_ldil.iii"    // SAR vs SHR / SLT vs ULT cross-check

// --- Module ~aether/capability.iii (BUILT) — systemic defect #5: cap_verify does NOT exist ---
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"

// --- Module aether/witness_hook.iii (BUILT) — systemic defect #2: ws_emit_fragment does NOT exist ---
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

// --- Module numera/keccak256.iii (BUILT) — systemic defect #1: keccak256_* live here, NOT keccak.iii ---
extern @abi(c-msvc-x64) fn keccak256_oneshot(input: *u8, len: u64, out_32: *u8) -> i32 from "keccak256.iii"
```

Not-yet-built deps: **1** (`xii_ldil.iii`, Module 38). Built deps used: `capability.iii`, `witness_hook.iii`, `keccak256.iii` (all only for the optional M6/M8 surface; the pure R3 lowering needs only Module 38).

## Algorithm
Three deterministic passes (copy-2's architecture), made correct and ABI-complete. No floating point, no ML, no heuristic (M2/M3/M4). No recursion (W15) — every traversal is an explicit `while` over module-scope arrays.

### `cg_init`
Fill `CGP_REG_ENC[0..13]` = {0,1,2,6,7,8,9,10,11,12,13,14,15,3} and `CGP_REG_CALLEE[0..13]` = {0,0,0,0,0,0,0,0,0,1,1,1,1,1}. Set `CGP_INITED=1`. Deterministic table write.

### Pass 1 — `cg_compute_live(func)` (live intervals)
Init all `CGP_V_FIRST[i]=CGP_SENT`, `CGP_V_LAST[i]=0`, `CGP_V_REG[i]=CGP_SENT`, `CGP_V_SPILL[i]=CGP_SENT` for `i ∈ [0,CGP_MAX_VALS)`. Walk blocks in `xl_fn_block_at` order; within each block walk instrs then the terminator, assigning a monotonically increasing linear `pos` (`CGP_INSTR_POS[instr]=pos`). For the def value `out` (if `!= CGP_SENT`): set `CGP_V_FIRST[out]` if unset, update `CGP_V_LAST[out]`. For each input `v` (`xl_instr_in`): update first/last. **Param seeding:** before the block walk, for each `p = xl_fn_param_at(func,k)` set `CGP_V_FIRST[p]=0` (params are live from entry) — closes the param-binding gap at interval level. Determinism: positions are a pure function of block/instr order, identical every run (M2). Comparison `pos > CGP_V_LAST[out]` is a **`u32` ordering compare** — legal (Trap 3 covers only signed `i32`/`i64`; `u32` `<`/`>` is used throughout STDLIB, e.g. bitops `while i < N`).

### Pass 2 — `cg_linear_scan()` (allocation with spilling)
1. Reset `CGP_REG_BUSY[r]=0`, `CGP_REG_OWNER[r]=CGP_SENT` for `r ∈ [0,CGP_N_REGS)`; `CGP_SPILL_N=0`.
2. Build `CGP_ORDER` = all values with `CGP_V_FIRST != CGP_SENT`, in ascending value-id order (`n` entries).
3. **Stable insertion sort** of `CGP_ORDER` by ascending `CGP_V_FIRST`. **W14/insertion-sort trap fix** (see memory `feedback_iiis1_insort_active_flag`): the inner loop MUST be driven by its own guard, not a fake-break. Form:
   `let mut q=p; while (q != 0u32) && (CGP_V_FIRST[CGP_ORDER[q-1]] > CGP_V_FIRST[CGP_ORDER[q]]) { swap; q = q - 1u32 }`.
   This is the canonical hand-rolled stable sort (NIH, M1). Ties (equal first-def) keep ascending value-id → fully deterministic (M2). (Copy-2's two-`if` `q=0` form is the documented clobber trap and is rejected.)
4. Linear scan over `CGP_ORDER[0..n)`: for value `v` with `start=CGP_V_FIRST[v]`:
   - **Expire:** free every pool slot whose owner's `CGP_V_LAST < start`.
   - **Assign:** scan pool indices `0..CGP_N_REGS` for the first free slot (caller-saved first by pool order). If found, mark busy/owner, `CGP_V_REG[v]=slot`.
   - **Spill (no free slot):** find the active owner with the latest `CGP_V_LAST` (the "furthest" interval). If that victim ends later than `v`, spill the victim (`CGP_V_SPILL[victim]=CGP_SPILL_N++`, `CGP_V_REG[victim]=CGP_SENT`) and give its slot to `v`; else spill `v` itself (`CGP_V_SPILL[v]=CGP_SPILL_N++`). This is textbook linear-scan-with-spill (Poletto–Sarkar), hand-rolled. Deterministic: victim choice is "max last, lowest pool index on tie" (the `>` strict-greater scan keeps the first/lowest index — note this in code).
5. Compute `CGP_FRAME_BYTES`: callee-saved-used count is computed by a final pass over the pool (any slot ever marked owner with `CGP_REG_CALLEE=1`); frame = `CGP_SPILL_N * CGP_SPILL_SLOT_BYTES`, rounded up so that `(pushed-callee count*8 + 8 ret-addr + frame)` is 16-aligned at each emitted CALL, plus `CGP_SHADOW_BYTES` if the function emits any `OP_CALL`. Pure arithmetic, deterministic.

### Pass 3 — emission (`cg_emit_prologue` → per-block `cg_emit_instruction` → `cg_emit_epilogue` → fixups)
Byte-exact encoders (copy-2's `cg_emit_*`, retained verbatim where correct; the encoder family is faithful to the Intel manual). Helpers: `cg_split_reg` (u16 lo|hi<<8), `cg_rex(w,r,x,b)`, `cg_emit_modrm_reg_reg(op,dst,src)`, `cg_emit_mov_reg_imm`, add/sub/and/or/xor/cmp/imul/neg/not (`F7 /3`,`/2`), shl/shr/sar (`D3 /4,/5,/7`), setcc, `mov_reg_mem`/`mov_mem_reg` (disp32 form for spill/RBP), push/pop, jmp/jcc (fixup-recording), ret. **New encoders required (privileged, RM1 only):** `cg_emit_lgdt(base_reg)` (`0F 01 /2`), `cg_emit_lidt(base_reg)` (`0F 01 /3`), `cg_emit_mov_cr(cr_idx,reg)` (`0F 22 /r`) and `cg_emit_mov_from_cr` (`0F 20 /r`), `cg_emit_wbinvd` (`0F 09`), `cg_emit_invlpg(mem_reg)` (`0F 01 /7`), `cg_emit_cli`(`0xFA`)/`cg_emit_sti`(`0xFB`), `cg_emit_hlt`(`0xF4`). Every privileged encoder begins `if CGP_MODE != CGP_MODE_RM1 { CGP_LAST_ERR = CGP_E_PRIV; return CGP_E_PRIV }` (M7 ring wall; M8 — these are only reachable from `cg_compile_capability` after `cap_verify_rights`).

- **`cg_emit_prologue`**: `push rbp` (`0x55`); `mov rbp, rsp` (`48 89 E5`); for each callee-saved pool slot actually used, `push rN`; `sub rsp, CGP_FRAME_BYTES` (`48 81 EC imm32`). Closes the ABI gap. Spill slot `s` lives at `[rbp - (s+1)*8]`.
- **Parameter binding** (first thing after prologue): for `k ∈ [0,min(nparams,4))`, if param value `p=xl_fn_param_at(func,k)` is register-allocated, `mov dst, argreg(k)`; if spilled, `mov [rbp - slot], argreg(k)`. argreg = {RCX,RDX,R8,R9} (Win64). Closes the param gap. (>4 params: read from `[rbp + 16 + 8*(k-4)]`.)
- **`cg_emit_instruction(instr)`** — per-opcode lowering. For binary ops the dest-aliasing move + op pattern is copy-2's. **Spill-aware operand fetch** (closes the spill gap): a helper `cg_load_operand(v, scratch_reg) -> u8` returns the value's register; if `v` is spilled it emits `mov scratch_reg, [rbp - slot]` and returns `scratch_reg` (scratch = R10/R11, reserved when any spill exists). After computing a spilled dest, `cg_store_result(v, reg)` emits `mov [rbp - slot], reg`. `cg_reg_enc_of` must return `CGP_REG_NONE` (not RAX) for spilled values so a missing spill path is a hard error, not silent RAX aliasing.
  - **`OP_EQ`/`NE`/`SLT`/`SLE`/`ULT`/`ULE` correctness fix:** emit `cmp a,b` **then** `setcc dst_low8` **then** `movzx dst, dst_low8` (copy-1's correct pattern). Copy-2's `xor dst,dst` *after* `cmp` destroys ZF before SETcc — **rejected**. setcc map: EQ→SETE, NE→SETNE, SLT→SETL, SLE→SETLE, ULT→SETB, ULE→SETBE. movzx r64,r8 = `REX.W 0F B6 /r`.
  - **`OP_BR_COND` correctness fix:** `imm` packs `t_blk=imm[31:0]`, `f_blk=imm[63:32]`. Emit `test cond,cond` (`48 85 /r` with reg=rm=cond) — **not** copy-2's `cmp cond,cond` which forces ZF=1 — then `jne t_blk` (`0F 85` + fixup), then `jmp f_blk` (`E9` + fixup). If `f_blk` is the textual next block, the trailing `jmp` may be elided (deterministic: elide iff `f_blk == xl_fn_block_at(func, bi+1)`).
  - **`OP_BR`**: `jmp tgt` (`E9` + fixup); elide if target is the next block.
  - **`OP_CONST`**: `mov reg, imm64` (`REX.W B8+rd` + imm64). Imm is exact (W5/M15).
  - **`OP_SHL/SHR/SAR`**: `mov rcx, shamt`; dest-alias move; `D3 /4|/5|/7`. (RCX is in the pool; if RCX currently owns a live value the scan must be told RCX is clobbered here — see Gap "shift clobber".)
  - **`OP_LOAD/STORE`**: sized by `xl_v_width(addr_val)` — 64-bit `mov` for W_64 (`8B`/`89`), 32-bit (drop REX.W), 16-bit (`66` prefix), 8-bit (`8A`/`88`). Copy-2 hardcoded 64-bit; sized form closes a correctness gap. disp=0 base form, with the `[rbp]`→disp8 and `[rsp/r12]`→SIB special cases (copy-1's `cg_emit_load64` handled rm==5 and rm==4 explicitly; copy-2's `mov_reg_mem` handles base_lo==5 only — **must also handle base_lo==4 SIB**, else `[r12]`/`[rsp]` mis-encode; flagged).
  - **`OP_NEG/NOT`**: `F7 /3` / `F7 /2`.
  - **`OP_DIV/MOD/UDIV/UMOD`**: not in either copy. Lower as: move dividend→RAX; `cqo`(`48 99`) for signed or `xor rdx,rdx` for unsigned; `idiv src`(`F7 /7`) or `div src`(`F7 /6`); result RAX (DIV/UDIV) or RDX (MOD/UMOD) → dst. RAX/RDX must be reserved across this (flagged as clobber). **Trap 11 (modulo-after-call) does NOT apply** — this is emitted x86 `idiv`, not an III `%` operation.
  - **`OP_RET`**: if it has an input, `mov rax, retval`; then `cg_emit_epilogue`; then `ret` (`0xC3`).
  - **`OP_CALL`**: move ≤4 args into {RCX,RDX,R8,R9}; ensure 32-byte shadow already reserved in frame; `call rel32` (`E8` + fixup to callee — for intra-module direct calls) or via reg; result RAX→dst. (Cross-function call resolution is the linker's job; here emit the fixup. Flagged: callee-as-block-id vs symbol — copy-1 emitted a placeholder rel32 only.)
  - **`OP_PHI`**: SSA phi. Linear-scan lowering: phi is resolved at predecessor block ends by inserting parallel copies into the phi's register (standard "phi elimination"). Neither copy implements it. Specify: during emission, at each block terminator, for every phi in each successor, emit `mov phi_reg, incoming_value_reg` (with a parallel-copy swap-cycle breaker using R11 as temp). Flagged as a substantial gap.
- **`cg_emit_epilogue`**: `add rsp, CGP_FRAME_BYTES`; `pop rN` for callee-saved (reverse order); `pop rbp` (`0x5D`); (caller emits `ret`). Single shared epilogue; every `OP_RET` jumps through it (or it is inlined — deterministic either way; inline chosen to avoid an extra label).
- **Fixup resolution**: copy-2's loop — `rel32 = block_pos - pc_end`, written little-endian byte-by-byte through `*u8` (Trap 5-safe: explicit per-byte stores, never a `*u32` store of a u32 local). Deterministic.
- **Witness (M6, optional)**: if `CGP_WIT_ENABLE==1`, after `*out_len` is set, `keccak256_oneshot(CGP_OUT, CGP_LEN, CGP_WIT_COMMIT)` then `wh_publish(CGP_WIT_PRODUCER, opid="cg_pure::compile", in_commit=<func-id bytes>, out_commit=CGP_WIT_COMMIT, revtag=1, phase=…, pillar=…, antecedents=0, n_ante=0, payload=0, payload_len=0, out_frag_id=…)`. Reproducible byte-identically from (func, mode) (M10). Routed through `wh_publish` (systemic defect #2), hashed via `keccak256_oneshot` (defect #1).

### Determinism & bit-identity (M2/W5)
Output bytes are a pure function of the LDIL function structure + mode: pass-1 positions are order-deterministic; pass-2 sort is stable with value-id tiebreak and the victim rule is "max-last / min-index"; pass-3 encoders are fixed byte sequences. No clock, no RNG, no float, no observed counters (M3). Same function → identical bytes on every run and every CPU.

### Capability gate (M8) & ring wall (M7)
`cg_compile` refuses `CGP_MODE_RM1` (`CGP_E_MODE`). `cg_compile_capability` permits RM1 only when `cap_verify_rights(cap_id, CGP_RIGHT_EMIT_PRIV)==1u8` (gate via `==`, W11); else `CGP_E_CAP`. Every privileged encoder independently re-checks `CGP_MODE==CGP_MODE_RM1` (defense in depth; an R3 request can never emit a privileged byte → no bricking, M5).

## KAT Vectors (>= 3)
Each compiles a tiny hand-built LDIL function and asserts the emitted bytes **exactly**. (Phase-2 builds the LDIL via Module 38's builder; expected bytes verified against the Intel encoding by hand here.)

1. **Identity return (param→RAX), R3.** Function `f(x:u64){ ret x }`, 1 param, 1 block: `[BR_COND none]`→ just `RET x`. With `x` allocated to RCX (arg0) and no spills/callee regs/calls → frame 0.
   Expected bytes (prologue `push rbp;mov rbp,rsp`, param bind `mov rcx→(reg of x)`; x already in RCX so the entry `mov rax,rcx`, epilogue `pop rbp`, `ret`):
   `55  48 89 E5  48 89 C8  5D  C3`
   (`55`=push rbp; `48 89 E5`=mov rbp,rsp; `48 89 C8`=mov rax,rcx; `5D`=pop rbp; `C3`=ret). Asserts prologue/epilogue + param-in-RCX + RET-to-RAX.

2. **Const + add, R3.** `g(){ t0=CONST 5; t1=CONST 37; t2=ADD t0,t1; ret t2 }`. Allocator gives t0→RAX, t1→RCX (caller-saved order), t2 reuses RAX (t0 dead after add).
   Expected: `55 48 89 E5` `48 B8 05 00 00 00 00 00 00 00` (mov rax,5) `48 B9 25 00 00 00 00 00 00 00` (mov rcx,37) `48 01 C8` (add rax,rcx) `5D C3`. Asserts `mov r64,imm64` little-endian (5,37) + `add r,r` ModR/M (0xC8 = mod11 reg=rcx(1) rm=rax(0)) + dest-alias elision.

3. **Equality compare, R3 (the EQ flag-fix regression guard).** `h(){ a=CONST 1; b=CONST 1; e=EQ a,b; ret e }`, e→a's reg after both dead. Expected the **correct** `cmp;sete;movzx` (NOT `cmp;xor;sete`): for a→RAX,b→RCX,e→RAX:
   `... 48 39 C8` (cmp rax,rcx) `0F 94 C0` (sete al) `48 0F B6 C0` (movzx rax,al) `... C3`. Asserts the flags are read by SETE before any clobber → byte `0F 94` immediately follows the `cmp`, with **no** `xor` between. (A body that emits `48 31 C0` between `48 39 C8` and `0F 94` FAILS — this is the copy-2 bug detector.)

4. **Conditional branch, R3 (the BR_COND fix guard).** Two blocks; `OP_BR_COND cond,B1,B2`. Assert the compare opcode is **`85` (TEST)**, not `39` (CMP), and the reg/rm fields equal `cond`: bytes `48 85 Cx` then `0F 85 <rel32>` then (if B2≠next) `E9 <rel32>`. A body emitting `48 39 ..` (cmp cond,cond) FAILS.

5. **Spill smoke (≥10 simultaneously-live values), R3.** Build 15 live CONSTs all used by one final ADD chain so >14 are live at a point → forces ≥1 spill. Assert: (a) `CGP_SPILL_N >= 1` after pass 2; (b) prologue contains `48 81 EC <frame>=non-zero`; (c) at the spilled value's use there is a `mov reg, [rbp - disp]` reload (`48 8B 4D xx` or `48 8B 8D xx xx xx xx`). Guards the spill-store/reload path that copy-2 omits entirely.

6. **RM1 privileged gate (M7/M8).** `cg_request_begin(f, CGP_MODE_RM1)` then `cg_compile(&n)` → returns `CGP_E_MODE`. Then `cg_compile_capability(bad_cap, &n)` with a cap lacking `CGP_RIGHT_EMIT_PRIV` → `CGP_E_CAP`. With a granting cap, a function containing a (Phase-2 LDIL) WBINVD intrinsic emits exactly `0F 09`. **Prove-the-negative** (per memory `feedback_no_autogen_stub_prove_negative`): the two refusals MUST be exercised, not just the success path.

## Trap Exposure
- **Trap 1 (multi-line fn):** Every signature above is single-line. The 6-param copy-1 `cg_compile` is eliminated (also a W2 win); no signature wraps.
- **Trap 2 (const linker-global):** Every const is `CGP_`-prefixed; bare `CG_` (copy-1/copy-2) rejected. Grep-confirmed no `CGP_` collision.
- **Trap 3 (signed ordering SIGSEGV):** No `i32`/`i64` `<`/`<=`/`>`/`>=`. All ordering compares are on **`u32`** (positions, value ids, pool indices) — legal. Error/status compares use `==`/`!=` only (W9/W11). The `rel32` computation uses `i32` arithmetic but only subtraction + bit-masking, **no `i32` ordering** (copy-2's fixup loop is clean here; preserve it).
- **Trap 4 (u32-in-u64 ptr math):** Output addressing uses `CGP_OUT:u64 + CGP_LEN:u64` (both u64) — no u32-in-u64. Spill disp computed as `(slot+1)*8` in u64. Any place a u32 value index feeds `&ARR[idx]` indexing is plain array indexing (compiler emits the element stride), not manual `base + idx*stride` pointer math — so the masking hazard does not arise; if Phase 2 hand-computes a byte address from a u32, it MUST mask `(idx as u64) & 0xFFFFFFFFu64` first.
- **Trap 5 (u32 ptr store width):** Fixup patching and `cg_emit_byte` write through `*u8` one byte at a time; **no** `*u32` store. Preserved from copy-2.
- **Trap 6 (nested block comments):** None used; only `//` and single-level `/* */`.
- **Trap 7 (local var arrays):** **PRIMARY FIX.** copy-2's `order`,`pref`,`phys_busy`,`phys_owner`,`reg_busy`,`reg_owner` and copy-1's `pref`,`phys_busy`,`phys_owner` are all illegal locals → hoisted to the module-scope `CGP_ORDER`/`CGP_REG_BUSY`/`CGP_REG_OWNER` tables. Non-reentrancy noted (singleton compile, matches cg_r0).
- **Trap 8 (`} else {`):** The lowering uses `when`-style `if` chains (one branch per opcode, early `return`); any `else` is written `} else {` on one line.
- **Trap 9 (em-dash in comments):** All comments ASCII; use `--` not `—`.
- **Trap 10 (`let mut` checkpoint flag):** The sort/scan use counters that genuinely drive loop conditions (not boolean checkpoint flags); `assigned`/`spill` use the `CGP_SENT` sentinel + early structural decisions, not a mutated bool-flag. (Avoids the `feedback_iiis0_let_mut_flag_bug` shape.)
- **Trap 11 (`a % b` after call):** The generator performs **no** III-level `%`/`/`. Integer div/mod appear only as *emitted* x86 `idiv`/`div` bytes. So the param-spill modulo trap does not apply. (Module 38's `sop_init` `o % 10` is a different module.)
- **Trap 12 (`@specialize *T` stride):** This module is not generic; no `@specialize`. N/A.

## Gap / Fix List
PARTIAL — concrete gaps in the (fuller) copy-2 body, each with its fix:

1. **Trap-7 local arrays (won't compile).** Fix: hoist all 6 allocator arrays to module scope (`CGP_*` tables above).
2. **No two-mode support / zero privileged emission (largest miss).** Fix: add `CGP_MODE_R3`/`CGP_MODE_RM1`, the `cg_compile`/`cg_compile_capability` split, and the full privileged encoder set (LGDT/LIDT/MOV CRn/WBINVD/INVLPG/CLI/STI/HLT) with per-encoder mode re-check (M7) and capability gate (M8). copy-1 had the mode *constants* but never emitted a privileged byte; copy-2 lacked even the constants.
3. **No prologue/epilogue; callee-saved not preserved (ABI break).** Fix: `cg_emit_prologue`/`cg_emit_epilogue` with `push rbp;mov rbp,rsp;sub rsp,frame`, push/pop of used callee-saved {RBX,R12–R15}.
4. **Parameters never bound to ABI arg registers.** Fix: param-binding sequence right after prologue (Win64 RCX,RDX,R8,R9; stack for >4); param values seeded live-from-entry in pass 1.
5. **Spilling half-implemented** — slots assigned, never reserved/stored/reloaded; `cg_reg_enc_of` silently returns RAX for spilled. Fix: reserve `CGP_SPILL_N*8` in the frame, emit reloads via `cg_load_operand`/stores via `cg_store_result`, and make `cg_reg_enc_of` return `CGP_REG_NONE` for spilled (hard error if a spill path is missed).
6. **`OP_EQ` emits `xor dst,dst` after `cmp`, destroying ZF before `setcc`** (wrong machine code). Fix: `cmp;setcc dst8;movzx dst,dst8` (copy-1's correct order). Same fix for NE/SLT/SLE/ULT/ULE (copy-2 only had EQ).
7. **`OP_BR_COND` emits `cmp cond,cond` (always ZF=1) → branch never taken.** Fix: `test cond,cond` (`85 /r`) then `jne t_blk`, `jmp f_blk` (elide trailing jmp to fall-through).
8. **Output capacity hardcoded `CG_CAP=1048576` ignoring caller buffer (overrun → M5 bricking).** Fix: `cg_request_set_buffer(out_buf,out_cap)` carries the true capacity; `cg_emit_byte` checks against it.
9. **`cg_compile` 6 params (copy-1) violates W2.** Fix: request-by-aggregate (`cg_request_begin`+setters+`cg_compile(out_len)`). **Cross-module note:** gospel Module 40 `cg_superopt` declares `extern cg_compile(func,mode,entry_block,out_buf,out_cap,out_len)`; that extern must be updated to the request-style API. Flag for the wave scheduler (Module 40 depends on this signature).
10. **`mov_reg_mem`/`mov_mem_reg` handle `[rbp]`(base_lo==5) but not `[rsp]`/`[r12]`(base_lo==4 → SIB required).** Fix: add the SIB (`0x24`) special case (copy-1's `cg_emit_load64`/`store64` had it; copy-2 dropped it). Without it, any load/store through R12 or a spill base of RSP mis-encodes.
11. **LOAD/STORE width hardcoded 64-bit.** Fix: size by `xl_v_width` (8/16/32/64 via `66` prefix / REX.W drop / `8A`/`88`). M15 totality over the value's bit width.
12. **`OP_DIV/MOD/UDIV/UMOD` unimplemented** (in LDIL opcode set, absent in both copies). Fix: RAX/RDX-based `cqo`+`idiv` / `xor rdx,rdx`+`div` lowering, with RAX/RDX reserved across.
13. **`OP_PHI` unimplemented.** Fix: predecessor-end parallel-copy phi elimination with an R11 cycle-breaker. (SSA join correctness — without it any multi-block function with phis mis-compiles.)
14. **`OP_CALL` unimplemented** (copy-1 emitted only a placeholder rel32; copy-2 omitted it). Fix: arg marshalling into {RCX,RDX,R8,R9}, shadow space, `call rel32`+fixup, RAX→dst.
15. **Shift/div register clobbers not modeled in the allocator.** `OP_SHL/SHR/SAR` clobber RCX; `OP_DIV/…` clobber RAX,RDX. The scan must treat these as fixed clobbers at those positions (reserve, or spill the live owner around the instruction). Fix: a clobber pre-pass marking RCX/RAX/RDX busy across those instrs; documented as part of pass 2.
16. **No witness (M6) for the generator's own state transition.** Fix: optional `wh_publish` over the output commit (hashed by `keccak256_oneshot`), reproducible from (func,mode) (M10). Uses the REAL emit/hashing symbols (systemic defects #1,#2).
17. **`cap_verify` / `ws_emit_fragment` would be fictitious externs.** Fix: declared as `cap_verify_rights` (defect #5) and `wh_publish` (defect #2); `keccak256_oneshot` from `keccak256.iii` (defect #1). **`CGP_RIGHT_EMIT_PRIV` bit value is a PLACEHOLDER** — Phase 2 MUST read `aether/capability.iii` for the real privileged-emit right-bit constant and the witness `phase`/`pillar` codes; do not invent.
18. **`at_now` (defect #4):** not used by this module (no algebraic-time dependency). Noted for completeness; if Phase 2 wants to stamp the witness with algebraic time it must call the real `at_current`/`at_advance` from `numera/algebraic_time.iii`, never `at_now`.

What is correct in copy-2 and preserved verbatim: the `cg_emit_byte`/`u32`/`u64` emitters, `cg_split_reg`, `cg_rex`, `cg_emit_modrm_reg_reg` and the ALU/shift/setcc/imul/neg/not encoders, the jmp/jcc fixup-recording mechanism, the fixup-resolution byte-patch loop, and the live-interval pass shape. The linear-scan spill *policy* (victim = furthest end) is sound; only its *emission* side was missing.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/cg_pure.iii
 *
 * III STDLIB - numera::cg_pure
 *
 * Pure III x86-64 code generator. Three-pass pipeline:
 *   1. live-interval computation per value (cg_compute_live)
 *   2. linear-scan register allocation with spilling (cg_linear_scan)
 *   3. prologue / per-instruction byte encoding / epilogue / fixups
 *
 * Register file: pool index -> x86 encoding. RSP(4),RBP(5) reserved.
 * Modes: CGP_MODE_R3 (userspace), CGP_MODE_RM1 (Ring -1, cap-gated).
 *
 * Hexad: kind_motion.  Ring: R0.  K: 0.99.
 * Discipline: W2, W8, W11, W13, W14, W15.
 */

module numera_cg_pure

// ---- Module 38 numera/xii_ldil.iii (NOT-YET-BUILT) ----
extern @abi(c-msvc-x64) fn xl_fn_n_blocks(func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_block_at(func: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_n_params(func: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_fn_param_at(func: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_n_instrs(block: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_instr_at(block: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_block_term(block: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_op(instr: u32) -> u8 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_out(instr: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_n_in(instr: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_in(instr: u32, idx: u32) -> u32 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_instr_imm(instr: u32) -> u64 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_v_width(value: u32) -> u8 from "xii_ldil.iii"
extern @abi(c-msvc-x64) fn xl_v_signed(value: u32) -> u8 from "xii_ldil.iii"

// ---- BUILT deps (optional M6/M8 surface only) ----
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(input: *u8, len: u64, out_32: *u8) -> i32 from "keccak256.iii"

// ---- consts: see "Constant Namespace" for the complete CGP_ list ----
const CGP_OK   : i32 =  0i32
const CGP_E_BAD: i32 = -1i32
const CGP_E_OOR: i32 = -2i32
const CGP_E_MODE: i32 = -3i32
const CGP_E_REG: i32 = -4i32
const CGP_E_CAP: i32 = -5i32
const CGP_E_PRIV: i32 = -6i32
const CGP_MODE_R3 : u8 = 0u8
const CGP_MODE_RM1: u8 = 1u8
// ... (all CGP_OP_*, CGP_REG_*, CGP_N_*, CGP_MAX_*, CGP_SENT, CGP_REG_NONE,
//      CGP_SPILL_SLOT_BYTES, CGP_SHADOW_BYTES, CGP_ARG0..3, CGP_RIGHT_EMIT_PRIV,
//      CGP_SETE..CGP_JBE  exactly as listed in Constant Namespace) ...

// ---- module-scope data (Trap-7 hoist; see Data Structures) ----
var CGP_REG_ENC   : [u8;  14]
var CGP_REG_CALLEE: [u8;  14]
var CGP_V_FIRST   : [u32; 65536]
var CGP_V_LAST    : [u32; 65536]
var CGP_V_REG     : [u32; 65536]
var CGP_V_SPILL   : [u32; 65536]
var CGP_INSTR_POS : [u32; 65536]
var CGP_BLOCK_POS : [u32; 4096]
var CGP_ORDER     : [u32; 65536]
var CGP_REG_BUSY  : [u8;  14]
var CGP_REG_OWNER : [u32; 14]
var CGP_FIXUP_OFF : [u64; 4096]
var CGP_FIXUP_TGT : [u32; 4096]
var CGP_FIXUP_PCEND: [u64; 4096]
var CGP_WIT_PRODUCER: [u8; 32]
var CGP_WIT_COMMIT  : [u8; 32]

var CGP_OUT   : u64 = 0u64
var CGP_LEN   : u64 = 0u64
var CGP_CAP   : u64 = 0u64
var CGP_SPILL_N : u32 = 0u32
var CGP_FIXUP_N : u32 = 0u32
var CGP_FUNC  : u32 = 0u32
var CGP_MODE  : u8 = 0u8
var CGP_FRAME_BYTES : u64 = 0u64
var CGP_WIT_ENABLE  : u8 = 0u8
var CGP_LAST_ERR    : i32 = 0i32
var CGP_INITED      : u8 = 0u8

// ---- byte emitters (verbatim-correct from copy-2) ----
fn cg_emit_byte(b: u8) -> i32 { /* TODO: bounds-check vs CGP_CAP per Algorithm */ return CGP_OK }
fn cg_emit_u32(v: u32) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_u64(v: u64) -> i32 { /* TODO */ return CGP_OK }
fn cg_split_reg(reg_enc: u8) -> u16 { /* TODO: lo | hi<<8 */ return 0u16 }
fn cg_rex(w: u8, r: u8, x: u8, b: u8) -> u8 { /* TODO */ return 0x40u8 }

// ---- ALU / mov / shift / cmp / setcc encoders (copy-2 retained) ----
fn cg_emit_mov_reg_imm(reg_enc: u8, imm: u64) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_modrm_reg_reg(opcode: u8, dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_mov_reg_reg(dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_add_reg_reg(dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_sub_reg_reg(dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_and_reg_reg(dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_or_reg_reg(dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_xor_reg_reg(dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_cmp_reg_reg(dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_test_reg_reg(a_enc: u8, b_enc: u8) -> i32 { /* TODO: 0x85 /r (BR_COND fix) */ return CGP_OK }
fn cg_emit_imul_reg_reg(dst_enc: u8, src_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_neg_reg(dst_enc: u8) -> i32 { /* TODO: F7 /3 */ return CGP_OK }
fn cg_emit_not_reg(dst_enc: u8) -> i32 { /* TODO: F7 /2 */ return CGP_OK }
fn cg_emit_shl_reg_cl(dst_enc: u8) -> i32 { /* TODO: D3 /4 */ return CGP_OK }
fn cg_emit_shr_reg_cl(dst_enc: u8) -> i32 { /* TODO: D3 /5 */ return CGP_OK }
fn cg_emit_sar_reg_cl(dst_enc: u8) -> i32 { /* TODO: D3 /7 */ return CGP_OK }
fn cg_emit_setcc(cc_opcode: u8, dst_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_movzx_r64_r8(dst_enc: u8, src_enc: u8) -> i32 { /* TODO: REX.W 0F B6 /r (EQ fix) */ return CGP_OK }
fn cg_emit_idiv_reg(divisor_enc: u8) -> i32 { /* TODO: F7 /7 */ return CGP_OK }
fn cg_emit_div_reg(divisor_enc: u8) -> i32 { /* TODO: F7 /6 */ return CGP_OK }
fn cg_emit_cqo() -> i32 { /* TODO: 48 99 */ return CGP_OK }

// ---- memory / sized load-store (adds SIB base==4 case + width) ----
fn cg_emit_mov_reg_mem_w(dst_enc: u8, base_enc: u8, disp: i32, width: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_mov_mem_reg_w(base_enc: u8, disp: i32, src_enc: u8, width: u8) -> i32 { /* TODO */ return CGP_OK }

// ---- control flow ----
fn cg_emit_ret() -> i32 { /* TODO: 0xC3 */ return CGP_OK }
fn cg_emit_jmp(target_block: u32) -> i32 { /* TODO: E9 + fixup */ return CGP_OK }
fn cg_emit_jcc(cc_opcode: u8, target_block: u32) -> i32 { /* TODO: 0F xx + fixup */ return CGP_OK }
fn cg_emit_push_reg(reg_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_pop_reg(reg_enc: u8) -> i32 { /* TODO */ return CGP_OK }
fn cg_emit_call_rel32(target_func: u32) -> i32 { /* TODO: E8 + fixup */ return CGP_OK }

// ---- RM1 privileged encoders (each: mode re-check then bytes) ----
fn cg_emit_lgdt(base_enc: u8) -> i32 { /* TODO: guard RM1; 0F 01 /2 */ return CGP_OK }
fn cg_emit_lidt(base_enc: u8) -> i32 { /* TODO: guard RM1; 0F 01 /3 */ return CGP_OK }
fn cg_emit_mov_to_cr(cr_idx: u8, reg_enc: u8) -> i32 { /* TODO: guard RM1; 0F 22 /r */ return CGP_OK }
fn cg_emit_mov_from_cr(reg_enc: u8, cr_idx: u8) -> i32 { /* TODO: guard RM1; 0F 20 /r */ return CGP_OK }
fn cg_emit_wbinvd() -> i32 { /* TODO: guard RM1; 0F 09 */ return CGP_OK }
fn cg_emit_invlpg(mem_enc: u8) -> i32 { /* TODO: guard RM1; 0F 01 /7 */ return CGP_OK }
fn cg_emit_cli() -> i32 { /* TODO: guard RM1; 0xFA */ return CGP_OK }
fn cg_emit_sti() -> i32 { /* TODO: guard RM1; 0xFB */ return CGP_OK }
fn cg_emit_hlt() -> i32 { /* TODO: guard RM1; 0xF4 */ return CGP_OK }

// ---- passes ----
fn cg_compute_live(func: u32) -> i32 { /* TODO: Pass 1 per Algorithm; seed params live-from-entry */ return CGP_OK }
fn cg_linear_scan() -> i32 { /* TODO: Pass 2; stable insort (W14 guard-driven), expire/assign/spill, clobber pre-pass */ return CGP_OK }
fn cg_compute_frame() -> i32 { /* TODO: callee-used count + spill bytes, 16-align, +shadow if any CALL */ return CGP_OK }

fn cg_reg_enc_of(value: u32) -> u8 { /* TODO: pool->enc, CGP_REG_NONE if spilled */ return CGP_REG_NONE }
fn cg_load_operand(value: u32, scratch_enc: u8) -> u8 { /* TODO: reload spill into scratch, else its reg */ return CGP_REG_NONE }
fn cg_store_result(value: u32, reg_enc: u8) -> i32 { /* TODO: store to spill slot if spilled */ return CGP_OK }

fn cg_emit_prologue(func: u32) -> i32 { /* TODO: push rbp;mov rbp,rsp;push callee;sub rsp,frame */ return CGP_OK }
fn cg_emit_param_binding(func: u32) -> i32 { /* TODO: move RCX,RDX,R8,R9 (and stack args) into param regs/slots */ return CGP_OK }
fn cg_emit_epilogue() -> i32 { /* TODO: add rsp,frame;pop callee (rev);pop rbp */ return CGP_OK }
fn cg_emit_phi_copies(block: u32, next_block: u32) -> i32 { /* TODO: parallel copies into successor phis, R11 cycle-break */ return CGP_OK }
fn cg_emit_instruction(instr: u32, func: u32, bi: u32) -> i32 { /* TODO: per-opcode lowering per Algorithm; EQ/BR_COND fixes; spill-aware operands */ return CGP_OK }

// ---- witness (M6, optional) ----
fn cg_emit_witness() -> i32 { /* TODO: keccak256_oneshot(out,len)->commit; wh_publish(...) */ return CGP_OK }

// ---- public API ----
fn cg_init() -> i32 @export { /* TODO: fill CGP_REG_ENC + CGP_REG_CALLEE; idempotent */ return CGP_OK }
fn cg_request_begin(func: u32, mode: u8) -> i32 @export { /* TODO: validate mode; reset request state */ return CGP_OK }
fn cg_request_set_buffer(out_buf: *u8, out_cap: u64) -> i32 @export { /* TODO: bind buffer+true cap */ return CGP_OK }
fn cg_request_set_witness(producer: *u8, enable: u8) -> i32 @export { /* TODO: copy 32B producer, set flag */ return CGP_OK }
fn cg_compile(out_len: *u64) -> i32 @export { /* TODO: R3 only; run passes; refuse RM1 with CGP_E_MODE */ return CGP_OK }
fn cg_compile_capability(cap_id: u64, out_len: *u64) -> i32 @export { /* TODO: cap_verify_rights gate for RM1; else as cg_compile */ return CGP_OK }
fn cg_last_error() -> i32 @export { return CGP_LAST_ERR }
```
