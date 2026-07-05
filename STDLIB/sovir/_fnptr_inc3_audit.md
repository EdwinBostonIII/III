# fn-ptr INC-3 audit — CALL_INDIRECT on the SOVEREIGN backends (x86 computed call + wasm call_indirect), OOB trapping

Completes the feature INC-1 (ccsv codegen + ISA, `_fnptr_inc1_audit.md`) and INC-2 (field-indirect calls,
`_fnptr_inc2_audit.md`) left explicitly open: the sovereign x86 and wasm translators could not run 0x73 at all.
Everything below is a measured fact from this stroke (2026-07-05), not an expectation.

## RED first (falsifier-first, pre-change readings on the extended gate)

`run_fnptr_gate.sh` was extended BEFORE the backends were touched (x86 arm = svir_x86 -> sovas_main ->
sovlink_main + crt0_sov -> PE -> run; wasm arm = svir_wasm -> node run_wasm.mjs; plus the OOB vehicle):

    FAIL test_fnptr.c  (vf=0 interp=99 x86=1 wasm=1 gcc=99)     <- INC-1/2 oracles green, sovereign arms dead
    FAIL test_fnptr2.c (vf=0 interp=99 x86=0 wasm=1 gcc=99)
    FAIL oob-trap      (interp=199 x86=99 wasm=99)              <- THE FALSE-ACCEPT: silent completion at 99

The OOB vehicle `_svir_ci_oob.iii` (hand-laid, nfunc=2, fn0 = `CONST 5 ; CALL_INDIRECT 0 ; DROP ; CONST 99 ;
RET`) is built to complete CLEANLY at 99 when an executor does NOT trap — so the pre-change x86=99/wasm=99 is
exactly the silent-dispatch hole svir_interp.iii:123 names ("a real x86/wasm backend MUST TRAP here").

## The x86 lowering (svir_x86.iii)

- **Site (0x73 handler, after the 0x70 CALL handler):** `popq %r10` (the runtime index — %r10 is
  call-clobbered, never an argument register, and the arg-setup strings never touch it), then the arg setup
  **byte-for-byte identical to CALL** (after the pop the eval stack IS a CALL's entry state, so the same
  `%r11` base / `-8(%rbp)` rsp-save / align / shadow+stackargs sequence applies, same `8*ac` formula), then
  `callq __svci ; movq -8(%rbp), %rsp ; pushq %rax`.
- **__svci switchboard** (emitted once per module iff `mod_has_ci`): for k in 0..nfunc-1
  `cmpq $k, %r10 ; jz <main|Lfnk>` — the jz is a TAIL-jump, so the dispatched target sees exactly a direct
  call's stack (the caller's `callq __svci` return address on top; Win64 stack-args at the same rsp offsets).
  Fall-through = no function matched = OOB: `andq $-16,%rsp ; subq $32,%rsp ; movq $199,%rcx ;
  callq ExitProcess` (kernel32 import — already in sovld's known-import table, resolved by sovlink; verified
  by the 199 exit below). The chain IS the bounds check — no jae, no address table, no new relocation kind.
- **Scanners:** `max_local`, `mod_has_print`, `mod_has_mem` learned `0x73 -> skip 1` (a missed imm byte
  desyncs every later opcode in the body); new `mod_has_ci` walker.
- **Emitted .s inspected** (test_fnptr.c, 4 fns — machine-verify, not just exit codes):

        __svci:
        cmpq $0, %r10
        jz main
        cmpq $1, %r10
        jz Lfn1
        cmpq $2, %r10
        jz Lfn2
        cmpq $3, %r10
        jz Lfn3
        andq $-16, %rsp
        subq $32, %rsp
        movq $199, %rcx
        callq ExitProcess

  and the indirect site carries the single `popq %r10` before the standard arg block.

## The wasm lowering (svir_wasm.iii)

- **Site:** `i32.wrap_i64` (0xA7, the popped SVIR i64 index) + `call_indirect` (0x11) with
  typeidx = `IC + FN_N + ci_type_pos(ac)`, tableidx 0. Wasm's operand order ([args..., i32 index]) matches
  SVIR's (index pushed after the args) with no shuffling.
- **Types:** one `(ac x i64) -> i64` appended per DISTINCT arg-count seen at 0x73 sites (`CI_ACS`,
  first-seen order, deterministic; 256 slots = total for a u8 ac, no silent cap), after the per-fn types.
- **Table (id 4):** one funcref table, min=max=FN_N. **Elem (id 9):** active segment, table 0, offset 0,
  slot k = defined func k+IC for k in 0..FN_N-1 — SVIR's index space VERBATIM (ccsv registration order =
  module position = table slot), so index-space agreement holds by construction and the engine's own bounds
  check traps OOB natively.
- **Scanners:** build_body's nloc scan, `body_has_print`, `body_has_mem` learned `0x73 -> skip 1`.
- All three additions are CONDITIONAL on a 0x73 occurring (byte-stability below).

## GREEN (post-change gate, all measured)

    PASS test_fnptr.c  (svir_verify=0 svir_interp=99 x86=99 wasm=99 gcc=99)
    PASS test_fnptr2.c (svir_verify=0 svir_interp=99 x86=99 wasm=99 gcc=99)
    PASS oob-trap      (interp=199 x86=199 wasm=1(native trap))

- The KATs' add/sub INDEX-SPACE-AGREEMENT teeth (swap -> wrong result -> not 99) now execute on the real
  hardware path and the wasm engine, not only the interp.
- `test_fnptr2.c` gained `putchar(107)` — the IC=1 composition tooth: the wasm env.putc import shifts every
  func index; table/elem/type indices must follow the shift (they do; a forgotten `+IC` in elem would
  dispatch one function off and the ACC teeth would redden).
- OOB pins: interp 199 (sentinel), x86 199 (ExitProcess trap — proves the import path end-to-end), wasm 1
  (RuntimeError table-bounds, node uncaught). The pre-change 99/99 false-accept is dead.

## Byte-stability (additive-change proof, measured)

`ccsv(sha256.c)` (no fn-ptrs) translated before vs after the change:

    cmp _sha_before.s    _sha_after.s     -> identical (31340 bytes)
    cmp _sha_before.wasm _sha_after.wasm  -> identical (2519 bytes)

## Honest boundaries (stated, not hidden)

- **ac/params mismatch:** wasm's call_indirect ALSO type-checks (ac must equal the target's param count) and
  would trap where x86/interp execute with garbage args. ccsv never emits such SVIR (C calls match
  prototypes) and svir_verify cannot check a runtime index, so no gated corpus diverges; the stricter oracle
  can only over-trap, never silently mis-dispatch. Out-of-contract SVIR only.
- **__svci at seed scale:** a 100+-fn module emits a 100+-entry chain (~2 instrs/fn, once per module). The
  KAT scale (4 fns) is what runs today; seed modules with fn-ptrs (ast/emit/parse) exercise the chain the
  day they run behaviorally (they are still floor residue). sovas's branch relaxation (rel8->rel32,
  test_relax_*) covers the long-jump case structurally.
- wasm OOB rc=1 is node's uncaught-RuntimeError exit code (the host's behavior, pinned by measurement), not
  a chosen sentinel like 199.
- **`jz main` taken-arm (adversarial pass finding):** no KAT dials fn0 indirectly (a C program would have to
  call main through a pointer), so __svci's k=0 branch is proven assembled-and-not-taken (the OOB run
  executes THROUGH it to the trap) but its taken path is unexercised. It differs from the exercised
  `jz Lfn<k>` arms only in the label operand, resolved by the same sovparse label table `callq main`
  already uses. Exercised the day a corpus dials 0; mechanism-identical today.
