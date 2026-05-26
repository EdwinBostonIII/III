# CRASH-AUDIT: gate_resident.sys BSOD (2026-05-23)

Per CRASH DEBUGGING PROTOCOL. Phases 1+2 (evidence + verify-in-binary) complete BEFORE any edit.

## Bugcheck (C:\Windows\Minidump\052326-12265-01.dmp, parsed via DUMP_HEADER64)
- **0x1E KMODE_EXCEPTION_NOT_HANDLED**
- P1 = 0xC0000005 (access violation), P3 = 0 (**read**), P4 = 0xFFFFFFFFFFFFFFFF (read from **-1**)
- P2 = faulting RIP = 0xfffff80090f4665c
- Driver DllBase = 0xfffff80090f40000 (EntryPoint = base+0x1000 confirms ours) → **faulting RVA = 0x665c**, in `.text`.

## Faulting instruction (objdump gate_resident.sys @ VA 0x14000665c, fn `L_p_cap_attenuate`)
```
14000664d: lea CAP_RIGHTS(%rip),%rax     ; rax = &CAP_RIGHTS
140006655: mov -0x20(%rbp),%rax          ; rax = cap_slot_of(parent_id) result (ps)
14000665a: pop %rcx                       ; rcx = ps
14000665b: pop %rax                       ; rax = &CAP_RIGHTS
14000665c: mov (%rax,%rcx,8),%rax  <-- FAULT: CAP_RIGHTS[ps], ps an unguarded invalid slot
```

## ROOT CAUSE (verified in the codegen, not guessed)
`cap_attenuate` (capability.iii:121-127):
```
let ps : u32 = cap_slot_of(parent_id)
if ps == 0xFFFFFFFFu32 { return CAP_INVALID }      // 123  GUARD
if CAP_REVOKED[ps] == 1u8 { return CAP_INVALID }    // 124  GUARD
let no_env_mask : u64 = 0x7FFFFFFFFFFFFFFFu64       // 126
let parent_rights : u64 = CAP_RIGHTS[ps] & no_env_mask  // 127  FAULT
```
The emitted code runs `let ps` → `let no_env_mask` → `CAP_RIGHTS[ps]` — **the two `if` guards (123,124) emitted ZERO machine code.** The deleted guard didn't stop the invalid slot; `CAP_RIGHTS[ps]` dereferenced an unguarded index → AV.

**Mechanism:** `cg_r0.iii` has **NO `if` (STMT_IF, kind 69) handling**. cg_r3 has it (`R3_K_STMT_IF`, `iii_ast_if_cond/then/else`, emission @cg_r3.iii:2407); it was never ported to cg_r0. cg_r0's `emit_stmt` falls through unknown statements to `emit_expr` → `R0_E_UNSUPPORTED` (emits nothing); **`r0_emit_block` ignores the return** → the statement is **silently dropped**. The gate closure has **215 `if` statements** (+ `while`), all silently deleted. It "compiled 18/18" with its guard/control-flow logic gone. cg_r3 also has `STMT_WHILE` (kind ~) — cg_r0 lacks that too.

**Why never caught:** every prior R0 test was `if`-free (Tier-1 `return 0xc00000bb`, smoke, t_param/t_index/t_data). The corpus exercises `if`/`while` but only through cg_r3. cg_r0's control-flow gap had zero coverage until the closure.

## FIX (Phase 3)
1. **Fail-loud (meta-fix):** `r0_emit_block` + `r0_emit_stmt` PROPAGATE `R0_E_UNSUPPORTED`; `iii_cg_r0_emit_module`/`r0_emit_function` FAIL on it — cg_r0 can never silently drop a construct again; every remaining gap becomes a named compile error.
2. **Port the missing control flow** from cg_r3: `STMT_IF` (+else/else-if), `STMT_WHILE` (+`BREAK`/`CONTINUE` if used), and whatever else fail-loud surfaces.
3. Rebuild iiis-2; recompile the closure with **no UNSUPPORTED errors** (proof: no silent drops).
4. Re-disassemble `cap_attenuate` — the `if ps==0xFFFFFFFF { return }` guard MUST be present (cmp/jz).
5. Re-link + re-verify gate_resident.sys; corpus 330/0 + equivalence 57/0.
6. Operator re-deploys (demand-start, self-cleaning) → error 50 = gate decision correct in Ring 0.

## CORRECTION TO PRIOR CLAIM
The "Tier-2 Inc-2 verified" status was WRONG: the closure was structurally linked + disassembly-checked
at the PE/entry level, but I did NOT verify the closure's *control flow* survived cg_r0. It did not.
Fail-loud closes that verification gap permanently. The descent is NOT successful until gate_resident
loads and the selftest returns error 50.

---

## PHASE 3 — FIX IMPLEMENTED (2026-05-23)

1. **cg_r0 control flow ported** (cg_r0.iii): `STMT_IF` (+else/else-if) and `STMT_WHILE`, mirroring
   cg_r3. Label counter made module-global monotonic (was per-function → `L_if_end_1` collisions).
2. **Fail-loud meta-fix** (cg_r0.iii): `r0_emit_block`/`r0_emit_stmt`/`r0_emit_function` PROPAGATE
   every emit error; an unsupported construct is now a NAMED compile error, never a silent drop.
3. **Kernel-safe crypto** — the un-dropped `if cpufeat_has_avx512f()` exposed two facts: (a) the real
   numera::cpufeat imports `IsProcessorFeaturePresent` **from kernel32** (illegal in Ring 0, breaks the
   zero-imports invariant); (b) `_sha_sched4_avx512`/`_kk_chi_avx512` are EVEX `metal{}` blocks that
   must NEVER run in-kernel (no KeSaveExtendedProcessorState → FP-state corruption). Fix:
   - `KATABASIS-DEPLOY/src/cpufeat_kernel.iii`: `cpufeat_has_avx512f()` → `0u8` (resolves the only
     link reference; no import; statically forces the scalar branch).
   - `gate_resident.iii` driver_entry now pins `sha256_sched_force(1)` + `keccak_chi_force_path(1)`
     FIRST — a second, independent guarantee the EVEX blocks are unreachable.

## PHASE 2/3 — VERIFIED IN THE BINARY (objdump -dr; build/obj/*.dis)

- **cap_attenuate guard RESTORED** (capability.o `L_p_cap_attenuate`): after `call L_p_cap_slot_of` →
  `ps`, the emitted code is `movabs rax,0xffffffff ; cmp rax,rcx ; sete al ; test rax,rax ; je`
  to the continue-block, with the fall-through `return CAP_INVALID`. The guard now executes BEFORE
  the `mov rax,[rax+rcx*8]` (`CAP_RIGHTS[ps]`) that faulted at the BSOD. Second guard
  `if CAP_REVOKED[ps]==1` likewise present. (`==` → `sete`, the SAFE compare, not the signed-order trap.)
- **cap_env_init control flow RESTORED** (was wholly dropped): real `cmp/sete/je` emitted — root cap
  registers, so `cap_slot_of(root)` succeeds end-to-end (the deeper reason the chain crashed).
- **cpufeat shim** (cpufeat_kernel.o): `movabs rax,0x0 ; ret` (return value preserved across the
  witness exit-hook via push/pop). Returns 0. ✔
- **driver forces scalar first** (gate_resident.o `DriverEntry`): first two real calls are
  `sha256_sched_force(1)` (rcx=1) then `keccak_chi_force_path(1)` (rcx=1), before arena_reset /
  cap_env_init / cap_attenuate. ✔
- **scalar dispatch** (sha256.o `_sha_sched4`, keccak.o `_kk_chi`): `FORCE==1 → je` falls through to
  `call …_scalar`; the EVEX `…_avx512` is reachable only from the `FORCE==2` and `cpufeat==1` branches,
  both unreachable (FORCE=1 + shim=0). EVEX dead code present but statically unexecutable. ✔
- **witness hook** (witness_kernel.s `iii_witness_emit_kernel`): bare `.seh_proc … retq` leaf —
  preserves all registers/memory, IRQL-safe to HIGH_LEVEL, contributes valid `.pdata`/`.xdata` unwind.
- **zero imports**: `.idata` is a single all-zero (null) import descriptor; IAT dir size 0; strings
  scan finds no `*.dll`/kernel32/ntoskrnl. Zero-imports invariant holds.
- **kernel stack** (build/stackdepth.py over the full call graph): acyclic (no recursion); uniform
  0x400 frames; deepest path = DriverEntry→gate_admit→cycle_seal_verify→cycle_seal→sha256_oneshot→
  sha256_update→sha_block→_sha_sched4→_sha_sched4_scalar→sha_rotr→witness = 11 frames,
  **peak 10,728 B = 10.5 KiB = 43.7% of the 24 KiB x64 kernel stack.** Safe.

## PHASE 4 — REGRESSION + DETERMINISM (pre-deploy gate)

- iiis-2 determinism-gated rebuild: **OK**, mhash `d55cf0b0…` (cg_r0.iii baked in, exit 0).
- Stage1 compiler corpus: **57/0**. STDLIB R3 corpus: **330/0** — incl. `607/608/609 katabasis_*`
  (609 = the exact 4-case gate selftest the driver mirrors). The gate DECISION is proven in user mode.
- gate_resident.sys rebuilt from the verified iiis-2 → **byte-identical** hash (reproducible).
- Independent `verify_gate_resident.sh`: **10/10 PASS**.

## PINNED ARTIFACT
`gate_resident.sys` sha256 = **b756791ca716fe9231442ed304a72375241570856cec1243512fc0e83c2b8f90**
(re-pinned in verify_gate_resident.sh + sign_and_deploy.ps1; prior 55f17f43 superseded.)

**STATUS: ready for operator re-deploy.** Success criterion unchanged: `sc start` Win32 **error 50**
(STATUS_NOT_SUPPORTED) ⇔ all four gate verdicts correct in Ring 0, then self-unload.
