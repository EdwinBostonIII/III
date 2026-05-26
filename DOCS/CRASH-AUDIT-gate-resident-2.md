# CRASH-AUDIT #2: gate_resident.sys BSOD (2026-05-23, build b756791c)

CRASH PROTOCOL. Phases 1+2 (evidence + verify-in-binary) complete BEFORE any .iii/.py edit.
This is the SECOND BSOD. The first (audit #1) was a dropped `if` guard; this is a different,
deeper root cause in cg_r0's EXPRESSION lowering, plus the meta-bug that let it ship.

## Bugcheck (C:\Windows\Minidump\052326-10453-01.dmp, DUMP_HEADER64 parse)
- **0x1E KMODE_EXCEPTION_NOT_HANDLED**
- P1 = 0xC0000005 (access violation); **P3 = 1 = WRITE** (audit #1 was a read); **P4 = 0x30 = faulting write address**
- P2 = faulting RIP = 0xfffff8009a006fa0
- Driver DllBase = 0xfffff8009a000000 (RVA 0x6fa0 disassembles cleanly) → fault in `.text`.
- Faulting CONTEXT (@file 0xffe0): **Rax = 0x30, Rcx = 0** → store address = Rax + Rcx*8 = 0x30.
- Zero imports ⇒ RIP is necessarily inside our own image (we call nothing external but the witness leaf).

## Faulting instruction (objdump gate_resident.sys @ RVA 0x6fa0, inside L_p_sha256_final)
```
140006fa0:  48 89 14 c8   mov QWORD PTR [rax+rcx*8], rdx   ; rax=out_32=0x30, rcx=0  -> write to 0x30
```
This is `out_32[base+0] = ...` in `sha256_final` (sha256.iii:331). `out_32` (param0, correctly
spilled to [rbp-0x8] at 0x6c4b BEFORE the witness hook — no BUG-1 clobber) holds **0x30**.
So the *caller* handed `sha256_final` a bogus output pointer.

## ROOT CAUSE (verified in machine code; numbered crash chain)
1. Driver case → `katabasis_gate_admit(c1, &G_SEAL)` → `katabasis_cycle_seal_verify` →
   `katabasis_cycle_seal(c, &KCS_TMP as u64)` (seal.iii:58) →
   `sha256_oneshot(&KCS_BUF as *u8, 48u64, o as *u8)` (seal.iii:48) → `sha256_final(o)`.
2. **cg_r0 has NO `EXPR_CAST` lowering.** Its expr-kind constants (cg_r0.iii:56-77) define
   INT…RAW_ASM/PARALLEL but **no `R0_K_EXPR_CAST`**; `r0_emit_expr` (cg_r0.iii:643) has no CAST
   case, so a cast node (kind 72) falls through to the `R0_E_UNSUPPORTED` tail (cg_r0.iii:788)
   and **emits no value onto the push/pop eval stack.**
3. Consequence at the call site — `sha256_oneshot(&KCS_BUF as *u8, 48u64, o as *u8)` machine code:
   ```
   e964: movabs rax,0x30   ; the literal 48u64 (=0x30) -- the ONLY arg that lowered
   e96e: push rax
   e96f: pop r8            ; r8 (out_32 / arg3) = 48 = 0x30   <-- !!
   e971: pop rdx           ; rdx (len / arg2)   = stale
   e972: pop rcx           ; rcx (input / arg1) = stale
   e977: call sha256_oneshot
   ```
   `&KCS_BUF as *u8` and `o as *u8` lowered to NOTHING (no push); only the plain literal `48u64`
   pushed. The 3-arg pop therefore shifts: the message length **48 (0x30) lands in r8 = out_32**.
   `sha256_oneshot` forwards it to `sha256_final`, which writes the digest to 0x30 → write-AV.
   (In `cycle_seal_verify` itself, `&KCS_TMP as u64` likewise emits nothing: only `c` is pushed,
   `pop rdx`=c, `pop rcx`=stale → cycle_seal gets a garbage out_addr too. Same defect.)
4. Confirmation that `&GLOBAL` alone is fine: `cycle_seal` lowers `&KCS_BUF` for the `KCS_BUF[i]=`
   writes via `lea rax,[rip+0x4bc24] # 14005a4d0` (a real relocated address). It is **the `as`
   cast wrapper** that drops the value, not address-of.

## THE META-BUG (why a broken build linked "clean" and shipped)
`r0_emit_expr` DOES return `R0_E_UNSUPPORTED` for the cast (cg_r0.iii:788), but **its internal
recursive call sites ignore the return**: the `EXPR_CALL` argument loop (cg_r0.iii:754) calls
`r0_emit_expr(arg)` and discards the result; so do BINARY (710), UNARY (699), FIELD (733),
INDEX (746), MATCH (773/775), the callee (765), and `STMT_LET` (801). Last turn's fail-loud
sealed the *statement* layer (emit_block/emit_stmt/emit_function) but **expression-tree recursion
still swallows errors.** So the cast's error was generated and thrown away; the gate "compiled
18/18" with its casts silently emitting nothing.

## WHY AUDIT #1's VERIFICATION MISSED IT
Audit #1 fixed/disassembled the guard functions and the dispatch; it never disassembled a
*cast-argument call site*. The corpus that proves the seal logic (607/609) runs through **cg_r3**,
which lowers casts correctly — so the corpus cannot catch a cg_r0-only cast gap. cg_r0 has no
self-test that exercises casts. (Audit #1 also recorded "6 frames ~6.2KB" stack — measured before
control flow was emitted; audit #1's re-measure gave 11 frames / 10.5KB. Both predate THIS fix.)

## FIX (Phase 3) — two parts, both required
1. **Add `EXPR_CAST` lowering to cg_r0** as a VALUE PASS-THROUGH (mirrors the existing PAREN case,
   cg_r0.iii:669), since cg_r0 is 8-byte-uniform (it narrows nowhere; a cast is a no-op on the
   uniform 64-bit representation, and the gate needs only internal self-consistency, which the
   in-kernel seal/verify recompute provides — it never compares against a cg_r3 hash):
   - `const R0_K_EXPR_CAST: u32 = 72u32`  (matches R3_K_EXPR_CAST)
   - `extern ... fn iii_ast_cast_value(ast,node) -> u32 from "sema_accessors.c"`
   - `if k == R0_K_EXPR_CAST { return r0_emit_expr(iii_ast_cast_value(R0_G_AST, node)) }`
2. **Complete fail-loud through the expression tree:** make every internal `r0_emit_expr(...)`
   call propagate `R0_E_UNSUPPORTED` (CALL args + callee, BINARY, UNARY, FIELD, INDEX, MATCH,
   and STMT_LET). After this, ANY remaining cg_r0 expression gap becomes a NAMED build error,
   never a Ring-0 BSOD. Rebuild → if other unsupported exprs surface, fix each; expect clean.

## VERIFY (Phase 4)
- Rebuild iiis-2 (determinism gate); recompile the closure with NO `R0_E_UNSUPPORTED`.
- Re-disassemble `cycle_seal_verify` + `cycle_seal`: `&KCS_TMP` / `&KCS_BUF as *u8` / `o as *u8`
  must now each push a value, and `sha256_oneshot` must receive rcx=&KCS_BUF, rdx=48, r8=o (real
  out pointer in .bss, e.g. 0x14005a500), NOT 0x30.
- corpus 330/0 + stage1 57/0 + determinism + byte-reproducible gate; re-pin hash; operator redeploy.
- Success criterion unchanged: `sc start` Win32 **error 50**.

## RESULT (Phase 3 applied + Phase 4 verified, 2026-05-23)
**Fix applied to cg_r0.iii:** (1) `R0_K_EXPR_CAST=72` + `iii_ast_cast_value` extern + the CAST case
as a value pass-through (`if k == R0_K_EXPR_CAST { return r0_emit_expr(iii_ast_cast_value(...)) }`,
mirrors PAREN); (2) **completed fail-loud** — every internal `r0_emit_expr`/`r0_emit_block`/
`r0_emit_stmt` recursion now propagates `R0_E_UNSUPPORTED` (CALL args+callee, BINARY, UNARY, FIELD,
INDEX, MATCH expr+stmt, STMT_LET/RETURN/ASSIGN/IF-cond/WHILE-cond/FOR/WAVEFRONT). An expression gap
can no longer silently ship.

**Rebuild:** iiis-2 determinism gate OK (mhash d2c26748). Gate closure compiled with **zero
UNSUPPORTED** (so casts were the only expression gap). Fail-loud then un-hid one real dependency —
`iii_hexad_pfs` (called as `iii_hexad_pfs(op) as u32` in hexad_reach.iii:69, previously swallowed by
the cast) — resolved by adding `omnia/hexad_pfs` (pure-.iii, dep `iii_hexad_pack6` already linked) to
the closure (now 19 modules).

**Verified in the NEW binary (472152e3):**
- `cycle_seal_verify`: `&KCS_TMP as u64` now emits `lea rax,[rip+0x4b43f] # 14005b530 <KCS_TMP>`
  (real .bss), and the cycle_seal call gets `rcx=cycle_idx, rdx=&KCS_TMP` (was: garbage → 0x30).
- `cycle_seal`: `sha256_oneshot(&KCS_BUF as *u8, 48, o as *u8)` now pushes all three args →
  `rcx=&KCS_BUF (0x14005b500), rdx=48, r8=o` (the REAL out pointer). The `48` (0x30) goes to rdx (len)
  not r8 (out). The exact BSOD-#2 mechanism is gone.
- Driver vars correct: `L_p_G_SEAL`→.bss 0x140016000, `L_p_G_WRONG`→.bss 0x140016100 (writable).
  No new write-AV (the `.weak._iii_IrpNotImplemented.L_p_G_SEAL` disasm label is an objdump artifact;
  the real G_SEAL symbol is in .bss).
- Stack: acyclic, peak 10,728 B = 43.7% of 24 KiB. Zero imports (null .idata). Byte-reproducible.
- corpus: stdlib **330/0** (incl. 607/608/609), stage1 **57/0**. verify_gate_resident.sh **10/10**.

**Pinned artifact** sha256 = **472152e3c6c21894e3b8dda83a9b00b1deb521e93309dfe20ac84a80a262651b**
(re-pinned in verify_gate_resident.sh + sign_and_deploy.ps1; b756791c superseded). Ready for the
operator's UAC-gated re-deploy.

## PHASE 4 — TESTED ON METAL (2026-05-23): PASS
Operator ran sign_and_deploy.ps1 (472152e3, signature Valid, checksum 0x1ffdf, demand-start).
`sc start IIIKatabasisGate` → **Win32 error 50 (STATUS_NOT_SUPPORTED = 0xC00000BB)** — DriverEntry
returns that ONLY when all four gate verdicts (OK / REJECT_SEAL / REJECT_CAP / REJECT_HEXAD) are
correct. **No bugcheck; machine stayed up; service self-unloaded (self-cleaning).** The full gate
DECISION — cycle-term build in the BSS arena, SHA-256/keccak content-address seal, capability
verification, hexad admissibility — executed correctly in Ring 0. BSOD #2 (and #1) are FIXED on
hardware. Tier-2 (the gate decision resident in-kernel) is achieved.
