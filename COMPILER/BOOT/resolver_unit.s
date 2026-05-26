/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\resolver_unit.s
 *
 * III COMPILER/BOOT - Software Resolution Unit v1.2
 * (front-end dispatcher + AVX-2 vectorized + scalar fallback).
 *
 * Hand-written Win64 dispatch loops that walk a 4096-slot pattern set
 * and return the (best_id, best_score) pair for the given (set,
 * intent, ctx) triple. This file replaces the v1.1 AVX-only entry
 * with a runtime-dispatched front end that probes cpufeat_has_avx2
 * and selects between an AVX-2 vectorized inner loop (8 candidates
 * per inner iteration via vpgatherqq + vpmovmskb) and a scalar
 * fallback. Output is bit-identical between the two paths.
 *
 * Public symbols:
 *   iii_resolver_unit_resolve(set_ptr, intent_ptr, ctx_ptr) -> u64
 *     Front-end dispatcher. Probes cpufeat_has_avx2():
 *       - returns 1u8 -> tail-calls iii_resolver_unit_resolve_avx2
 *       - else        -> falls into scalar path (inlined)
 *     Returns: ((best_id & 0xFFFFFFFF) << 32) | (best_score & 0xFFFFFFFF)
 *     best_id == 0xFFFFFFFF when no pattern matched.
 *
 *   iii_resolver_unit_resolve_avx2(set_ptr, intent_ptr, ctx_ptr) -> u64
 *     AVX-2 vectorized resolver. Same return contract.
 *     Required ISA: AVX2 + BMI1 (tzcnt, blsr).
 *
 * Calling convention: MS x64 ABI, all entries.
 *   rcx = set_ptr   (pattern_set bitmap, 512 bytes = 4096 bits)
 *   rdx = intent_ptr (intent_t)
 *   r8  = ctx_ptr    (call_context)
 *   Return: rax (packed u64)
 *
 * BIT-IDENTICALITY
 *   The two implementations walk slots in the SAME order (slot 0..4095
 *   ascending), call resolver_score with the SAME (p, intent, ctx)
 *   triple for every occupied slot, and apply the SAME strict-`>`
 *   tiebreak (best wins on >, otherwise next wins on > of next_score).
 *   Since resolver_score is a pure function of inputs and the pattern
 *   table is read-only at this point, both paths return the SAME
 *   packed u64 for any (set, intent, ctx).
 *
 * AVX-2 STRATEGY (resolve_avx2)
 *   1. Outer 256-bit chunk skip: vmovdqu + vptest. ZF=1 means all
 *      256 slot-bits in this chunk are zero -> jump 256 slots in 3
 *      cycles. For sealed tables (~67 occupied of 4096), >90% of
 *      address space is skipped.
 *   2. Per-byte gather: when a byte has set bits, build a vpgatherqq
 *      mask whose lane sign-bits come from the 8 bits of the byte,
 *      and pre-load 8 pattern_id qwords (offset 0 of pattern_t) in
 *      parallel. This warms L1 for the subsequent scalar
 *      resolver_score calls.
 *   3. Per-bit scoring: tzcnt + blsr iterate set bits in low->high
 *      order. For each occupied lane (pattern_id != 0), call
 *      resolver_score and update best/next with strict-`>` tiebreak.
 *
 * SCALAR STRATEGY (resolve_scalar)
 *   Plain loop slot=0..4095:
 *     pattern_set_has(set, slot)
 *     pattern_table_get(slot)
 *     resolver_score(p, intent, ctx)
 *     update best/next with strict-`>` tiebreak.
 *
 *   The dispatcher does NOT call pattern_set_has/pattern_table_get
 *   from the AVX-2 path; instead it derives table_base once via a
 *   single base-find, then computes addresses arithmetically. The
 *   scalar path uses pattern_set_has/pattern_table_get as before
 *   (matching the iii reference implementation).
 *
 * DETERMINISM
 *   No clock, no random, no thread state. Pure function of inputs +
 *   read-only pattern table. Same input -> same output. Builds are
 *   reproducible via SOURCE_DATE_EPOCH=0 + `ar rcsD`.
 *
 * CONSTANTS
 *   PATTERN_BYTES = 168  (verified: STDLIB/iii/omnia/pattern_table.iii line 33)
 *
 * SEH
 *   Standard Win64 unwind: .seh_pushreg for each callee-saved GPR,
 *   .seh_stackalloc for the local frame, .seh_endprologue/.seh_endproc.
 *   xmm6..xmm15 are not touched (we use only xmm0..xmm7/ymm0..ymm7),
 *   so no .seh_savexmm bookkeeping needed.
 */

    .text

    /* Read-only constants for vector lane math.
     *   LANE_OFFSETS_168_LO[i] = i*168       for i in [0..3]
     *   LANE_OFFSETS_168_HI[i] = (i+4)*168   for i in [0..3]
     *   LANE_SHIFTS_LO[i]      = i           for i in [0..3]
     *   LANE_SHIFTS_HI[i]      = i+4         for i in [0..3]
     * 168 == PATTERN_BYTES (one pattern_t in pattern_table.iii). */
    .section .rdata, "dr"
    .p2align 5
LANE_OFFSETS_168_LO:
    .quad 0
    .quad 168
    .quad 336
    .quad 504
LANE_OFFSETS_168_HI:
    .quad 672
    .quad 840
    .quad 1008
    .quad 1176
    .p2align 5
LANE_SHIFTS_LO:
    .quad 0
    .quad 1
    .quad 2
    .quad 3
LANE_SHIFTS_HI:
    .quad 4
    .quad 5
    .quad 6
    .quad 7

    .text

    /* ===================================================================
     * iii_resolver_unit_resolve
     *
     * Front-end dispatcher. Probes cpufeat_has_avx2(); on AVX2 hosts
     * tail-calls iii_resolver_unit_resolve_avx2 with the SAME register
     * arguments. On non-AVX2 hosts, falls through to the inlined scalar
     * loop. Tail call preserves the Win64 stack frame requirements
     * (caller's home space remains valid for the callee).
     *
     * Stack frame: 64 bytes (32-byte shadow + 32-byte spill of rcx/rdx/r8/return).
     * One callee-saved GPR is touched along the scalar path (rbx, rsi,
     * rdi, r12..r15); push them all in the prologue regardless of which
     * branch is taken so SEH unwind is correct.
     * =================================================================== */

    .global iii_resolver_unit_resolve
    .seh_proc iii_resolver_unit_resolve
iii_resolver_unit_resolve:
    pushq %rbx
    .seh_pushreg %rbx
    pushq %rsi
    .seh_pushreg %rsi
    pushq %rdi
    .seh_pushreg %rdi
    pushq %r12
    .seh_pushreg %r12
    pushq %r13
    .seh_pushreg %r13
    pushq %r14
    .seh_pushreg %r14
    pushq %r15
    .seh_pushreg %r15
    /* 56 bytes pushed + 8 byte return = 64 byte misalignment.
     * Allocate 96 bytes -> total 160 -> 16-aligned. */
    subq $96, %rsp
    .seh_stackalloc 96
    .seh_endprologue

    /* Stash incoming args in callee-saved regs (survive the call). */
    movq %rcx, %r12     /* r12 = set_ptr */
    movq %rdx, %r13     /* r13 = intent_ptr */
    movq %r8,  %r14     /* r14 = ctx_ptr */

    /* iiis-2 Phase 3 Step K Feature 3: AVX-512 default dispatch.
     * Probe AVX-512F FIRST.  When present, the avx512 sibling produces
     * bit-identical output to the AVX-2 and scalar paths but processes
     * 512 slots per outer iteration via ZMM vptestmb/kmovq, doubling
     * the AVX-2 zero-skip width.  Falls through to AVX-2 / scalar
     * probes on hosts without AVX-512F. */
    callq cpufeat_has_avx512f
    testb %al, %al
    jnz  .Ldisp_avx512

    /* Probe AVX-2. */
    callq cpufeat_has_avx2
    testb %al, %al
    jz   .Ldisp_scalar

    /* AVX-2 path: restore arg regs and tail-call the vector entry.
     * Tail-call avoids a redundant nested SEH frame. We must restore
     * the prologue-pushed registers BEFORE the jmp, since the callee
     * has its own prologue and would otherwise see a corrupted view. */
    movq %r12, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    addq $96, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rdi
    popq %rsi
    popq %rbx
    jmp  iii_resolver_unit_resolve_avx2

    /* AVX-512 path: restore arg regs and tail-call the AVX-512 entry.
     * Same restore-then-jmp pattern as AVX-2; the avx512 sibling has
     * its own prologue and SEH frame. */
.Ldisp_avx512:
    movq %r12, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    addq $96, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rdi
    popq %rsi
    popq %rbx
    jmp  iii_resolver_unit_resolve_avx512

    /* ── Scalar fallback (inlined). ─────────────────────────────────────
     *
     * Plain loop slot = 0..4095:
     *   if pattern_set_has(set, slot) == 0 -> continue
     *   p = pattern_table_get(slot); if p == 0 -> continue
     *   s = resolver_score(p, intent, ctx)
     *   strict-`>` update of (best, next).
     *
     * Register usage on this path:
     *   r12 = set_ptr, r13 = intent_ptr, r14 = ctx_ptr (preserved across calls)
     *   ebx = best_id (low 32), rsi = best_score
     *   edi = next_id (low 32), r15 = next_score
     *   r10d = loop counter (slot)
     */
.Ldisp_scalar:
    movl $0xFFFFFFFF, %ebx
    xorq %rsi, %rsi
    movl $0xFFFFFFFF, %edi
    xorq %r15, %r15
    xorl %r10d, %r10d

.Lscalar_loop:
    cmpl $4096, %r10d
    jge  .Lscalar_done

    /* pattern_set_has(set, slot) -> al */
    movq %r12, %rcx
    movl %r10d, %edx
    callq pattern_set_has
    testb %al, %al
    jz   .Lscalar_next

    /* pattern_table_get(slot) -> rax (= p, or 0 if pattern_id == 0) */
    movl %r10d, %ecx
    callq pattern_table_get
    testq %rax, %rax
    jz   .Lscalar_next

    /* resolver_score(p, intent, ctx) -> rax */
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    callq resolver_score

    /* strict-`>` tiebreak update.
     *   if (s > best) { next = best; best = (slot, s); }
     *   else if (s > next) { next = (slot, s); }
     */
    cmpq %rsi, %rax
    jbe  .Lscalar_tieornext
    /* rotate best -> next, then set best */
    movl %ebx, %edi
    movq %rsi, %r15
    movl %r10d, %ebx
    movq %rax, %rsi
    jmp  .Lscalar_next
.Lscalar_tieornext:
    cmpq %r15, %rax
    jbe  .Lscalar_next
    movl %r10d, %edi
    movq %rax, %r15

.Lscalar_next:
    incl %r10d
    jmp  .Lscalar_loop

.Lscalar_done:
    /* Pack ((best_id & 0xFFFFFFFF) << 32) | (best_score & 0xFFFFFFFF) */
    movq %rsi, %rax
    movl %ebx, %ecx
    shlq $32, %rcx
    orq  %rcx, %rax

    addq $96, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rdi
    popq %rsi
    popq %rbx
    retq

    .seh_endproc

    /* ===================================================================
     * iii_resolver_unit_resolve_avx2
     *
     * AVX-2 vectorized resolver. Identical output contract to scalar.
     *
     * STAGE 1: scalar base-find (locate first occupied slot, derive
     *          table_base from pattern_table_get + slot*168 subtract).
     * STAGE 2: scalar tail to next 256-bit chunk boundary.
     * STAGE 3: AVX-2 outer chunk loop with vptest skip + per-byte
     *          vpgatherqq pre-load + per-bit tzcnt scoring.
     *
     * Stack frame: 224 bytes (16-aligned after 7 push + ret addr).
     *
     * STACK LAYOUT (after prologue)
     *   [rsp + 0x00] - 32-byte shadow (Win64 callee scratch)
     *   [rsp + 0x20] - 32-byte spill of the current bitmap chunk (ymm0)
     *   [rsp + 0x40] - 32-byte gather result lanes 0..3 (pattern_ids)
     *   [rsp + 0x60] - 32-byte gather result lanes 4..7
     *   [rsp + 0x80] - 32-byte per-lane scratch (unused by current path)
     *   [rsp + 0xA0] - u64 table_base
     *   [rsp + 0xA8] - u64 slot_base for current byte
     *   [rsp + 0xB0] - u64 saved byte index r11
     *   [rsp + 0xB4] - u32 saved lane (within current byte)
     *   [rsp + 0xB8] - u32 remaining_bits (bitmap_byte after blsr peeling)
     *   [rsp + 0xBC] - u32 saved slot_id
     *   [rsp + 0xC0] - u32 spilled best_id
     *   [rsp + 0xC4] - u32 spilled next_id
     *   [rsp + 0xC8] - u64 spilled best_score
     *   [rsp + 0xD0] - u64 spilled next_score
     *   [rsp + 0xD8] - u64 pad to keep frame 16-aligned
     *   total: 0xE0 = 224 bytes
     * =================================================================== */

    .global iii_resolver_unit_resolve_avx2
    .seh_proc iii_resolver_unit_resolve_avx2
iii_resolver_unit_resolve_avx2:
    pushq %rbx
    .seh_pushreg %rbx
    pushq %rsi
    .seh_pushreg %rsi
    pushq %rdi
    .seh_pushreg %rdi
    pushq %r12
    .seh_pushreg %r12
    pushq %r13
    .seh_pushreg %r13
    pushq %r14
    .seh_pushreg %r14
    pushq %r15
    .seh_pushreg %r15
    subq $224, %rsp
    .seh_stackalloc 224
    .seh_endprologue

    /* Persist incoming args. */
    movq %rcx, %r12
    movq %rdx, %r13
    movq %r8,  %r14

    /* Initialize best/next.
     *   ebx = best_id = 0xFFFFFFFF, rsi = best_score = 0
     *   edi = next_id = 0xFFFFFFFF, r15 = next_score = 0
     */
    movl $0xFFFFFFFF, %ebx
    xorq %rsi, %rsi
    movl $0xFFFFFFFF, %edi
    xorq %r15, %r15

    /* ── STAGE 1: locate table_base ───────────────────────────────────
     *
     * Walk scalar-style for the first occupied slot, call
     * pattern_table_get(slot), and subtract slot*168 to recover the
     * table base. The first slot is fully scored too (preserves
     * slot-index order for tiebreak identicality).
     */
    xorl %r10d, %r10d
.Lavx_base_find:
    cmpl $4096, %r10d
    jge  .Lavx_done                  /* empty set */
    vzeroupper
    movq %r12, %rcx
    movl %r10d, %edx
    callq pattern_set_has
    testb %al, %al
    jnz  .Lavx_base_have_bit
    incl %r10d
    jmp  .Lavx_base_find
.Lavx_base_have_bit:
    vzeroupper
    movl %r10d, %ecx
    callq pattern_table_get
    testq %rax, %rax
    jnz  .Lavx_base_have_ptr
    /* bit set but pattern_id == 0 -> skip */
    incl %r10d
    jmp  .Lavx_base_find
.Lavx_base_have_ptr:
    /* table_base = rax - slot*168 */
    movq %rax, %r11                  /* r11 = slot_ptr */
    movl %r10d, %eax
    imulq $168, %rax, %rax
    subq %rax, %r11
    movq %r11, 0xA0(%rsp)            /* spill table_base */

    /* Score the first occupied slot.
     * p = table_base + slot*168 (= original slot_ptr). */
    movq 0xA0(%rsp), %rax
    movl %r10d, %ecx
    imulq $168, %rcx, %rcx
    addq %rcx, %rax                  /* rax = p */
    vzeroupper
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    callq resolver_score             /* rax = score */
    cmpq %rsi, %rax
    jbe  .Lavx_base_tieornext
    movl %ebx, %edi
    movq %rsi, %r15
    movl %r10d, %ebx
    movq %rax, %rsi
    jmp  .Lavx_base_after
.Lavx_base_tieornext:
    cmpq %r15, %rax
    jbe  .Lavx_base_after
    movl %r10d, %edi
    movq %rax, %r15
.Lavx_base_after:
    incl %r10d                       /* advance past first occupied slot */

    /* ── STAGE 2: scalar tail to next chunk boundary ────────────────── */
    movl %r10d, %r9d
    orl  $255, %r9d
    incl %r9d                        /* r9d = next chunk_base */
.Lavx_tail_scalar:
    cmpl %r9d, %r10d
    jge  .Lavx_outer
    cmpl $4096, %r10d
    jge  .Lavx_done
    vzeroupper
    movq %r12, %rcx
    movl %r10d, %edx
    callq pattern_set_has
    testb %al, %al
    jz   .Lavx_tail_next
    vzeroupper
    movl %r10d, %ecx
    callq pattern_table_get
    testq %rax, %rax
    jz   .Lavx_tail_next
    movq %rax, %r11                  /* r11 = p */
    vzeroupper
    movq %r11, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    callq resolver_score
    cmpq %rsi, %rax
    jbe  .Lavx_tail_tieornext
    movl %ebx, %edi
    movq %rsi, %r15
    movl %r10d, %ebx
    movq %rax, %rsi
    jmp  .Lavx_tail_next
.Lavx_tail_tieornext:
    cmpq %r15, %rax
    jbe  .Lavx_tail_next
    movl %r10d, %edi
    movq %rax, %r15
.Lavx_tail_next:
    incl %r10d
    jmp  .Lavx_tail_scalar

    /* ── STAGE 3: AVX-2 outer chunk loop ─────────────────────────────
     *
     * r10d = chunk_base (multiple of 256). For each chunk:
     *   load 32 bytes (256 bits) of bitmap into ymm0
     *   vptest -> skip whole chunk if zero
     *   else process 32 bytes * 8 bits = 256 slots
     */
.Lavx_outer:
    cmpl $4096, %r10d
    jge  .Lavx_done

    /* &bitmap[chunk_base/8] = r12 + chunk_base/8. */
    movl %r10d, %eax
    shrl $3, %eax
    movq %r12, %r11
    addq %rax, %r11                  /* r11 = &bitmap[r10d/8] */

    /* Load 256 bits of bitmap. Unaligned-safe. */
    vmovdqu (%r11), %ymm0

    /* vptest sets ZF iff all 256 bits AND together to zero. */
    vptest %ymm0, %ymm0
    jz   .Lavx_chunk_skip            /* empty chunk -> skip 256 slots */

    /* Non-empty chunk: spill best/next so we can use rbx/rsi/rdi/r15
     * as scratch through the byte loop, and spill the bitmap chunk
     * so we can read individual bytes by index without per-byte
     * vpextrb (which requires immediate-encoded indices). */
    movl %ebx, 0xC0(%rsp)
    movl %edi, 0xC4(%rsp)
    movq %rsi, 0xC8(%rsp)
    movq %r15, 0xD0(%rsp)
    vmovdqu %ymm0, 0x20(%rsp)

    /* Walk bytes 0..31 of the chunk in order. r11 = byte index. */
    xorq %r11, %r11

.Lavx_byte_loop:
    cmpq $32, %r11
    jae  .Lavx_chunk_done

    /* Load this byte from the spilled bitmap. */
    movzbl 0x20(%rsp, %r11), %eax    /* eax = bitmap_byte */
    testl %eax, %eax
    jz   .Lavx_byte_skip             /* all 8 slots in this byte unset */

    /* slot_base = r10d (chunk_base) + r11*8 (byte_idx*8). */
    movl %r11d, %ecx
    shll $3, %ecx                    /* ecx = r11*8 */
    movl %r10d, %edx
    addl %ecx, %edx                  /* edx = slot_base */
    movq %rdx, 0xA8(%rsp)            /* spill slot_base */
    movq %r11, 0xB0(%rsp)            /* spill byte index */
    movl %eax, 0xB8(%rsp)            /* spill remaining_bits */

    /* ── Build per-lane absolute pointer vectors ────────────────────
     *
     * base_offset = table_base + slot_base * 168
     * ymm1 = LANE_OFFSETS_168_LO + broadcast(base_offset)
     * ymm2 = LANE_OFFSETS_168_HI + broadcast(base_offset)
     *
     * After this:
     *   ymm1[i] = &table[slot_base + i]      for i = 0..3
     *   ymm2[i] = &table[slot_base + (i+4)]  for i = 0..3
     */
    movq 0xA0(%rsp), %r8             /* r8 = table_base */
    movl %edx, %ecx                  /* ecx = slot_base (zero-ext) */
    imulq $168, %rcx, %rcx
    addq %rcx, %r8                   /* r8 = base_offset */

    /* Broadcast r8 across 4 qword lanes of ymm3.
     * ymm3 = [r8, r8, r8, r8] */
    vmovq %r8, %xmm3
    vpbroadcastq %xmm3, %ymm3

    /* Load lane-offset constants. */
    leaq LANE_OFFSETS_168_LO(%rip), %rcx
    vmovdqa (%rcx), %ymm1
    leaq LANE_OFFSETS_168_HI(%rip), %rcx
    vmovdqa (%rcx), %ymm2

    /* Add base_offset to each lane.
     * ymm1[i] = r8 + i*168       (absolute address, lane i)
     * ymm2[i] = r8 + (i+4)*168   (absolute address, lane i+4) */
    vpaddq %ymm3, %ymm1, %ymm1
    vpaddq %ymm3, %ymm2, %ymm2

    /* ── Build vpgatherqq mask from bitmap_byte ─────────────────────
     *
     * For lane i (i=0..7), mask_lane[i].sign_bit must be 1 iff
     * bit i of bitmap_byte is set.
     *   ymm5 = broadcast(byte) >> [0,1,2,3], then << 63   (lanes 0..3)
     *   ymm4 = broadcast(byte) >> [4,5,6,7], then << 63   (lanes 4..7)
     * The other 63 bits per lane are don't-care; vpgatherqq tests
     * only the sign bit.
     *
     * vpgatherqq CLEARS its mask operand on completion (architectural
     * side-effect), so we never read ymm4/ymm5 after the gather.
     */
    movl 0xB8(%rsp), %ecx            /* ecx = bitmap_byte */
    movzbl %cl, %ecx                 /* defensive zero-ext */
    vmovq %rcx, %xmm4
    vpbroadcastq %xmm4, %ymm4
    vmovdqa %ymm4, %ymm5

    leaq LANE_SHIFTS_LO(%rip), %rcx
    vmovdqa (%rcx), %ymm6            /* ymm6 = [0,1,2,3] */
    leaq LANE_SHIFTS_HI(%rip), %rcx
    vmovdqa (%rcx), %ymm7            /* ymm7 = [4,5,6,7] */

    vpsrlvq %ymm6, %ymm5, %ymm5      /* ymm5[i] = byte >> i      */
    vpsrlvq %ymm7, %ymm4, %ymm4      /* ymm4[i] = byte >> (i+4)  */
    vpsllq $63, %ymm5, %ymm5         /* ymm5[i] = (byte>>i)<<63  */
    vpsllq $63, %ymm4, %ymm4         /* ymm4[i] = (byte>>(i+4))<<63 */

    /* ── vpgatherqq: parallel pattern_id loads ──────────────────────
     *
     * vpgatherqq mask, (base_gpr, index_ymm, scale), dst
     *   dst[i] = mem[base + index[i]*scale]   for lanes with mask sign=1
     *
     * We want absolute-address gather, so base_gpr = 0, scale = 1, and
     * index = absolute address. r11 currently holds the byte index;
     * spilled at 0xB0 above. Reuse r11 as the zero base register.
     *
     * The qword loaded is the first 8 bytes of pattern_t (offset 0 =
     * pattern_id field). Nonzero pattern_id => slot occupied; this
     * matches pattern_table_get's check.
     */
    xorq %r11, %r11

    /* Init dst to zero so unloaded lanes read as pattern_id == 0
     * (skipped by the per-bit loop). */
    vpxor %ymm6, %ymm6, %ymm6
    vpxor %ymm7, %ymm7, %ymm7

    vpgatherqq %ymm5, (%r11, %ymm1, 1), %ymm6
    vpgatherqq %ymm4, (%r11, %ymm2, 1), %ymm7

    /* Spill 8 pattern_ids to stack for scalar lane inspection. */
    vmovdqu %ymm6, 0x40(%rsp)        /* lanes 0..3 */
    vmovdqu %ymm7, 0x60(%rsp)        /* lanes 4..7 */

    /* Reload byte index and remaining_bits. */
    movq 0xB0(%rsp), %r11
    movl 0xB8(%rsp), %r9d            /* r9d = remaining_bits */

    /* ── Per-bit scoring loop ───────────────────────────────────────
     *
     * For each set bit in r9d (low->high via tzcnt):
     *   lane = tzcnt(r9d)
     *   pattern_id = stack[0x40 + lane*8]
     *   if pattern_id == 0: skip
     *   slot_id = slot_base + lane
     *   p = table_base + slot_id*168
     *   s = resolver_score(p, intent, ctx)
     *   strict-`>` update of best/next (in spilled memory).
     *   blsr the lowest set bit; loop.
     */
.Lavx_bit_loop:
    testl %r9d, %r9d
    jz   .Lavx_bit_done

    tzcntl %r9d, %ecx                /* ecx = lane */
    movl %ecx, 0xB4(%rsp)            /* save lane */

    movl %ecx, %eax
    movq 0x40(%rsp, %rax, 8), %r8    /* r8 = pattern_id of lane */
    testq %r8, %r8
    jz   .Lavx_bit_skip

    movq 0xA8(%rsp), %rdx            /* rdx = slot_base */
    addl %ecx, %edx                  /* edx = slot_id */

    movq 0xA0(%rsp), %r8             /* r8 = table_base */
    movl %edx, %eax
    imulq $168, %rax, %rax
    addq %rax, %r8                   /* r8 = p */

    movl %edx, 0xBC(%rsp)            /* save slot_id */

    vzeroupper
    movq %r8, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    callq resolver_score             /* rax = score */

    movl 0xB8(%rsp), %r9d            /* reload remaining_bits */
    movl 0xBC(%rsp), %edx            /* reload slot_id */

    /* strict-`>` update on spilled best/next.
     *   best_id  at 0xC0 (4 bytes), next_id  at 0xC4 (4 bytes)
     *   best_score at 0xC8 (8 bytes), next_score at 0xD0 (8 bytes)
     */
    cmpq 0xC8(%rsp), %rax
    jbe  .Lavx_tieornext
    /* rotate best -> next, then set best */
    movl 0xC0(%rsp), %ecx
    movl %ecx, 0xC4(%rsp)
    movq 0xC8(%rsp), %rcx
    movq %rcx, 0xD0(%rsp)
    movl %edx, 0xC0(%rsp)
    movq %rax, 0xC8(%rsp)
    jmp  .Lavx_bit_skip
.Lavx_tieornext:
    cmpq 0xD0(%rsp), %rax
    jbe  .Lavx_bit_skip
    movl %edx, 0xC4(%rsp)
    movq %rax, 0xD0(%rsp)

.Lavx_bit_skip:
    blsrl %r9d, %r9d                 /* clear lowest set bit */
    movl %r9d, 0xB8(%rsp)
    jmp  .Lavx_bit_loop

.Lavx_bit_done:
    movq 0xB0(%rsp), %r11            /* reload byte index */

.Lavx_byte_skip:
    incq %r11
    cmpq $32, %r11
    jb   .Lavx_byte_loop

.Lavx_chunk_done:
    /* Reload best/next from spill. */
    movl 0xC0(%rsp), %ebx
    movl 0xC4(%rsp), %edi
    movq 0xC8(%rsp), %rsi
    movq 0xD0(%rsp), %r15

.Lavx_chunk_skip:
    addl $256, %r10d
    jmp  .Lavx_outer

.Lavx_done:
    vzeroupper

    /* Pack ((best_id & 0xFFFFFFFF) << 32) | (best_score & 0xFFFFFFFF). */
    movq %rsi, %rax
    movl %ebx, %ecx
    shlq $32, %rcx
    orq  %rcx, %rax

    addq $224, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rdi
    popq %rsi
    popq %rbx
    retq

    .seh_endproc
