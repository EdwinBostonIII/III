# III — Sovereign-Assembler Self-Hosting Fix-List

**Read-only diagnostic result (2026-06-21).** Produced by sweeping every module through `sovas` vs `gas` and
diagnosing each blocker; **touches no toolchain source**. All byte-pairs and helper models verified against
current `STDLIB/sovtc/{sovparse.iii, sovas.iii}`. The fix edits are the user's to apply (sovtc lane).

## The finding (the reframe)

The "621 hard-errors" is the **full-stdlib** number (Goal B, includes a ~70-module SIMD cluster). The milestone
the directive named — **assemble the compiler itself** — is far smaller. Measured directly over `COMPILER/`:

- **59 PASS / 6 DIFFER / 32 ERROR**, and **the union of all missing mnemonics is exactly one: `movb`.**
- The 32 ERROR split into **23 modules blocked by `movb`** + **9 blocked by one shared operand-form**
  (`movl SYM(%rip)` rip-relative load) + the 6 DIFFER byte-bugs.

So self-hosting ≈ **2 missing forms (`movb`, `movl`-rip) + 4 shared-encoder byte-bugs**, every byte gas-verified.

`sov_rex` always emits a `0x40` byte — for 32/8-bit forms emit REX **only** when `reg>=8`/`base>=8`; never call
`sov_rex` unconditionally for low regs.

## (a) Missing OPERAND FORMS

### A1 — `movb` (8-bit move) — **23 modules — the dominant blocker**
- **Dispatch:** new `movb` block in `sp_dispatch_instr`, mirroring the `movl` block (`sovparse.iii:459-466`) — same
  S1K/OPK cases (rr / store-base / load-base / store-SIB / load-SIB) + the rip-sym load (A2 pattern).
- **Helpers (`sovas.iii`):** clone the `movl` family with opcode **`0x8A` load / `0x88` store**, **no REX.W**, 8-bit
  reg field: `sov_movb_load_base`/`store_base` (twins of `sov_movl_load_base`:302 / `sov_movl_store_base`:308),
  `sov_movb_rr`, `sov_movb_load_rip_sym`/`store_rip_sym`, SIB twins as the 23-module set requires.
- **Caution:** byte regs 4-7 are `spl/bpl/sil/dil` only under a REX prefix — keep the REX-no-W when a high reg appears.

### A2 — `movl SYM(%rip),%reg` (32-bit RIP-relative LOAD; S1K==3, OPK==0) — **9 modules, one root cause**
All identical: `cg_r3_xii, cg_typeclass, jit_emit, main, iii_cg_pe_iiis1, sema_xii_adapter, affine_audit_kat,
affine_audit_sound, cg_r3_xii_adapter`. The `movl` block has S1K∈{0,2,4} but no S1K==3 → falls through to
`PARSE_ERR=1` at `sovparse.iii:466`. (`movq` has it at `:451`; the 32-bit encoders were **deliberately removed** —
`sovas.iii:411-412`.)
- **Dispatch** (before `:466`): `if S1K == 3u32 { if OPK == 0u32 { sov_movl_load_rip_sym(OPR, S1SEC, S1OFF)  return } }`
- **Helper** (`sov_load_rip_sym`:396 minus REX.W):
  ```
  fn sov_movl_load_rip_sym(reg:u32, sec:u32, off:u32) -> i32 @export {
      let mut r:u32=0u32  if reg>=8u32 { r=1u32 }
      if r!=0u32 { sov_rex(0u32,r,0u32,0u32) }
      sov_emit(0x8Bu32)  sov_modrm(0u32,reg,5u32)
      sov_rec_reloc(sec)  sov_imm((off as u32) as u64,4u32)  return 0i32 }
  ```
  Verified: `%eax`→`8B 05 <d32>`, `%r8d`→`44 8B 05 <d32>`.

### A3 — secondary, same edit region (add now to avoid a 2nd pass)
- **`movl %reg,SYM(%rip)` store** (S1K==0/OPK==3, needed by `iii_cg_pe_iiis1`): dispatch twin + `sov_movl_store_rip_sym`
  (opcode **`0x89`**, conditional REX, `sov_rec_reloc`, imm32). `sov_store_rip32`:188 is **not** reusable (omits the reloc).
- **`movslq SYM(%rip),%reg`** (movs?q block, S1K==3, MN[4]=='l'): new `sov_movslq_rip` (REX.W **`0x63`**, modrm(0,reg,5),
  reloc, imm32).

## (b) byte-DIFFER bugs (shared encoders — one fix corrects every listed module)

### B1 — `leaq disp(%base)` mis-routed to the RIP form — **2 modules** (`21_pointer`, `22_array_via_ptr`)
`leaq` at `sovparse.iii:457` is unconditional → always `sov_lea_rip_sym`. `leaq -8(%rbp),%rax`:
`48 8d 05 00 00 00 00` (+ spurious REL32) → **`48 8d 45 f8`**.
- **Dispatch:** make `:457` a S1K switch: S1K==3 → `sov_lea_rip_sym`; S1K==2 → `sov_lea_base(OPR,S1R,S1D)`; else PARSE_ERR.
- **Helper:** `sov_lea_base` = the `0x8D` twin of `sov_movl_load_base`, **reusing `sov_membase_modrm`:290** (handles
  mod 00/01/10 disp-range + rsp/r12 SIB + rbp/r13 forcing): `sov_rexwb(reg,base); sov_emit(0x8Du32); sov_membase_modrm(reg,base,disp)`. No reloc.

### B2 — `callq *%reg` → direct call — **1 module** (`26_fnptr`)
`callq` handler (`:468-479`) only reads a symbol name; `*%rax` → garbage name → `sov_call_ext` emits
`e8 00000000` + bad reloc → must be **`ff d0`**.
- **Dispatch:** after `sp_skip_ws`, peek for `'*'` (byte 42); if present, advance, parse `%reg`, call `sov_call_reg(reg)`.
- **Helper:** `fn sov_call_reg(reg:u32)->i32 @export { if reg>=8u32 { sov_emit(0x41u32) }  sov_emit(0xFFu32)  sov_modrm(3u32,2u32,reg)  return 0i32 }` (FF /2, mod=11). No reloc.

### B3 — shift-by-1 not special-cased — **2 modules** (`41_resolve_ambiguous`, `42_resolve_nomatch`)
`shrq $1,%rax`: `48 c1 e8 01` → **`48 d1 e8`**. Fix in `sov_shift_imm8` (`sovas.iii:353`); dispatch `:542-543` unchanged.
- When `(imm & 0xFF)==1`: emit `sov_rex(1,0,0,b)` + **`0xD1`** + `sov_modrm(3,ext,reg)`, **no immediate byte**. Else keep
  the `0xC1…ib` path. Covers shl=/4 shr=/5 sar=/7.

### B4 — `shlq/shrq %cl` (CL-count) not handled — **1 module** (`57_pattern_form_runtime`)
`shlq %cl,%rax` mis-encodes as `C1/4 ib` reading the stale module-level `S1I` (=3): `48 c1 e0 03` → **`48 d3 e0`**.
- **Dispatch** (`:542-543`): add a S1K guard like `addq` — `if S1K==1u32 { sov_shl_imm8(OPR, S1I as u32) } else { sov_shl_cl(OPR) }` (and `shrq`→`sov_shr_cl`).
- **Helpers:** `sov_shl_cl(reg)` = REX.W + **`0xD3`** + `sov_modrm(3,4,reg)`; `sov_shr_cl(reg)` = … `sov_modrm(3,5,reg)`. No immediate byte.

## (c) Recommended FIX ORDER (fastest to self-host)

1. **A1 `movb`** — unblocks 23 modules. Largest single win.
2. **A2 `movl`-rip-load** (one dispatch case + one helper) — unblocks the remaining 9 form-blockers. Add **A3** in the
   same edit (same region — avoids a second pass).
3. **Batch B1-B4** — all shared-encoder/dispatch fixes; apply together.
4. **Re-run the differential gate across all 32+ compiler modules.**

Rationale: form-blockers (a) come first — a form-blocker yields `rc=4` / a 0-byte `.o`, so the module is entirely
absent and **its byte-differs cannot be observed until it assembles**. The differ fixes (b) live in shared encoders,
so one fix corrects every affected module — batch, then gate once. None are optional: the leaq/shift differs would
corrupt the assembler's own rebuild, so all are required for the self-host fixpoint.

## Goal B (full-stdlib coverage) — separate, lower priority

Full 681-module sweep (corrected against `sovparse`'s actual wired set; raw "missing-mnemonic" counts over-report
wired-but-unused mnemonics like `divq/notq/idivq/movswq/jnz/setl`):

- **`movb`: 397** — same keystone, dominant at full scale too.
- **`xorl` + 32-bit ALU (`addl/subl/cmpl/andl/orl`): 123+ — near-free.** The encoder already exists
  (`sov_op32_rr`:277, `sov_xorl_rr`:322) but is **never dispatched** — each is ~1 line in `sp_dispatch_instr`.
- **SIMD cluster (~70 modules):** `vmovdqu/vpxor/vpaddq/pshufb/sha256rnds2/vzeroupper/…` — a whole new xmm/VEX/EVEX
  encoder class. **Not on the self-hosting path** (the compiler emits no SIMD). Quarantine.
- **misc:** `movw`(7), `cqto`(4), `shll/decl`(2), `setc`/`rdseed`(1) — cheap.
- **~152 operand-form residuals** (supported mnemonic, unsupported form — the movl-SIB class generalized) and
  **44 byte-DIFFERs** (incl an `omnia_xii_lower_*` cluster of ~12 → likely one shared bug).
