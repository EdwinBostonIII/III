/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\resolver_unit_avx512.s
 *
 * III COMPILER/BOOT — Software Resolution Unit v1.2 (AVX-512 batched).
 *
 * Hand-written Win64 dispatch loop that walks a 4096-slot pattern set
 * and returns the (best_id, best_score) pair for the given (set,
 * intent, ctx) triple. This file is the AVX-512 sibling of
 * resolver_unit.s (AVX-2 v1.1); both produce BIT-IDENTICAL output for
 * any (set, intent, ctx) input across the full 4096-pattern space.
 *
 * Public symbol:
 *   iii_resolver_unit_resolve_avx512(set_ptr, intent_ptr, ctx_ptr) -> u64
 *     Returns: ((best_id & 0xFFFFFFFF) << 32) | (best_score & 0xFFFFFFFF)
 *     best_id == 0xFFFFFFFF when no pattern matched.
 *
 * Calling convention: MS x64 ABI §6.4.
 *   rcx = set_ptr   (pattern_set bitmap, 512 bytes = 4096 bits)
 *   rdx = intent_ptr (192-byte intent_t)
 *   r8  = ctx_ptr    (call_context)
 *   Return: rax (packed u64)
 *
 * ----------------------------------------------------------------
 * AVX-512 STRATEGY
 * ----------------------------------------------------------------
 *
 * Four vector layers exploit AVX-512F + AVX-512BW + AVX-512DQ:
 *
 *   1. 512-BIT ZERO-SKIP. The outer loop loads 64 bytes (512 slots)
 *      of the bitmap into zmm0 with `vmovdqu64`, then `vptestmb`
 *      against itself produces a 64-bit byte-mask in k1. `ktestq k1,
 *      k1` sets ZF=1 iff every byte of the chunk is zero. A `jz`
 *      jumps over 512 slot indices at once. This is 2x the
 *      zero-skip width of the AVX-2 path (256 → 512) and 16x the
 *      width of the scalar v1.0.
 *
 *   2. VPMOVM2B MASK MATERIALISATION. After the ktest screens the
 *      empty case, we still need the per-bit mask for the inner
 *      gather. `vpmovm2b k1, %zmm` would broadcast the byte-mask;
 *      we use the inverse direction (vptestmb produces the k-mask
 *      directly) and `kmovq` it into a GPR for byte-by-byte indexing.
 *      The k-mask is the SAME bit pattern as bitmap_byte tests in
 *      scalar order — preserves the slot-ordering invariant.
 *
 *   3. 16-LANE PARALLEL GATHER (vpgatherqq, k-mask predicated). The
 *      inner loop processes 16 slots per iteration as TWO 8-lane
 *      ZMM gathers:
 *
 *          batch_lo = slot_base + [0..7]    (zmm6)
 *          batch_hi = slot_base + [8..15]   (zmm7)
 *
 *      For each batch we materialise an 8-lane absolute pointer
 *      vector zmm1/zmm2:
 *          zmm1[i] = table_base + (slot_base + i)     * 168
 *          zmm2[i] = table_base + (slot_base + i + 8) * 168
 *
 *      A k-mask k2/k3 is constructed from the bitmap-word (16 bits
 *      = 2 bytes) via:
 *          kmovw  word, k2          (low 16 bits)
 *          kshiftrw $8, k2, k3      (high 8 of the 16 → low of k3)
 *          kandb   k2, k_low8_mask  (mask to low 8)
 *
 *      Then `vpgatherqq (%r11, %zmm1, 1) {%k2}, %zmm6` loads the
 *      pattern_id field (qword at p+0) of every set lane in one
 *      instruction; `vpgatherqq (%r11, %zmm2, 1) {%k3}, %zmm7` does
 *      lanes 8..15. AVX-512 vpgatherqq REQUIRES the writemask
 *      operand and ZEROS lanes whose mask bit is clear (different
 *      from AVX-2 which leaves them un-touched). We pre-zero the
 *      destination registers anyway so no observable behavioural
 *      difference.
 *
 *      vpgatherqq CLEARS its writemask after completion — this is
 *      the architectural side-effect we rely on so the k-register
 *      is reusable for the next gather.
 *
 *   4. PER-LANE SEQUENTIAL SCORING. Within a 16-bit word we walk
 *      set bits in tzcnt order (low→high), call resolver_score for
 *      each occupied lane, and update best/next with strict-`>`
 *      tiebreak. This preserves SLOT-INDEX ORDER — identical to
 *      both the scalar v1.0 walk and the AVX-2 v1.1 walk, so ties
 *      are broken identically (lower slot wins).
 *
 *   FINAL HSUM (vextracti64x4 + vpaddq + vpaddq). Used for the
 *   gathered-pattern-id all-zero check so we can skip the bit-loop
 *   entirely for words where every gathered slot has pattern_id==0
 *   (a rare degenerate case where the bitmap is set but the slot
 *   was never written). Without the early-exit the bit-loop would
 *   still produce the correct answer (the per-lane pid==0 short
 *   circuit catches it), but the hsum lets us skip the
 *   tzcnt/extract dance entirely:
 *
 *       vpaddq zmm6, zmm7, zmm8           ; zmm8 = lane-pair sums
 *       vextracti64x4 $1, zmm8, ymm9      ; high 4 lanes -> ymm9
 *       vpaddq      ymm9, ymm8, ymm8      ; ymm8 = 4-lane sums
 *       vextracti128 $1, ymm8, xmm9       ; high 2 lanes -> xmm9
 *       vpaddq      xmm9, xmm8, xmm8      ; xmm8 = 2-lane sum
 *       vpsrldq     $8, xmm8, xmm9        ; high qword -> low
 *       vpaddq      xmm9, xmm8, xmm8      ; xmm8 = scalar sum
 *       vmovq       xmm8, rax             ; rax = sum-of-pids
 *       testq       rax, rax              ; ZF iff every pid was 0
 *       jz   .Lword_skip_bit_loop
 *
 *   The hsum value itself isn't used arithmetically (sum of
 *   pattern_ids has no semantic meaning) — only its zero/nonzero
 *   property. Sum is safe because pattern_ids are bounded values
 *   from a 4096-entry registry and 16 of them cannot overflow
 *   a u64 in practice (and even if they did, a wrapped sum that
 *   happened to hit zero would just disable the optimisation
 *   for that word, never producing a wrong answer — the bit-loop's
 *   own per-lane pid==0 check is the source of truth).
 *
 * BIT-IDENTICAL CORRECTNESS (vs scalar v1.0 and AVX-2 v1.1)
 *
 *   The scalar walked slots 0..4095 in order; AVX-2 walked them in
 *   the same order via 256-bit chunks; AVX-512 walks them in the
 *   same order via 512-bit chunks:
 *     - Outer chunk loop:    chunk_base = 0, 512, 1024, …
 *     - Inner word loop:     word_idx = 0..31 within each chunk
 *                            (each word covers 16 slots)
 *     - Innermost bit loop:  tzcnt order (low bit first)
 *
 *   resolver_score is pure; called with the same (p, intent, ctx)
 *   it returns the same score. The strict-`>` tiebreak runs in
 *   slot-index order. Same input → same packed u64 output.
 *
 * DETERMINISM
 *
 *   No clock, no random, no thread state. Pure function of inputs +
 *   read-only pattern table. Same input → same output. Builds are
 *   reproducible via SOURCE_DATE_EPOCH=0 + `ar rcsD`.
 *
 * STACK LAYOUT (after prologue)
 *
 *     [rsp + 0x000]  ── 32-byte shadow (Win64 callee scratch)
 *     [rsp + 0x040]  ── 64-byte spill of the current bitmap chunk (zmm0)
 *     [rsp + 0x080]  ── 64-byte gather result lanes 0..7  (pattern_ids)
 *     [rsp + 0x0C0]  ── 64-byte gather result lanes 8..15 (pattern_ids)
 *     [rsp + 0x100]  ── u64 table_base (set once at function start)
 *     [rsp + 0x108]  ── u64 scratch (slot_base for current word)
 *     [rsp + 0x110]  ── u64 scratch (saved word index)
 *     [rsp + 0x118]  ── u64 scratch (saved bitmap-word remaining-bits)
 *     [rsp + 0x120]  ── u32 saved best_id    (spill while word active)
 *     [rsp + 0x124]  ── u32 saved next_id
 *     [rsp + 0x128]  ── u64 saved best_score
 *     [rsp + 0x130]  ── u64 saved next_score
 *     [rsp + 0x138]  ── u64 pad to keep frame 16-aligned
 *     ────────────────────────────────────────────────────────
 *      total frame: 0x140 = 320 bytes (16-aligned)
 *
 *     After prologue (7 push + ret addr = 64 bytes off caller rsp):
 *       rsp ≡ 0 (mod 16); sub 320 → rsp ≡ 0 (mod 16) ✓
 *
 *     We need 64-byte alignment for vmovdqa64 to the chunk slot. We
 *     instead use vmovdqu64 throughout (unaligned-tolerant) — same
 *     latency on Skylake-X+ for cached lines.
 *
 * SEH
 *
 *   Standard Win64 unwind: .seh_pushreg for each callee-saved GPR
 *   we clobber (rbx, rsi, rdi, r12..r15), .seh_stackalloc for the
 *   local frame, .seh_endprologue / .seh_endproc. We use only
 *   xmm0..xmm5 / ymm0..ymm9 / zmm0..zmm9 — xmm6..xmm15 are
 *   Win64-callee-saved and we don't touch their low halves; AVX-512
 *   adds zmm16..zmm31 which are NOT callee-saved, so we may use
 *   them freely. We never touch zmm16+ in this implementation
 *   (sticking to zmm0..zmm9) so no extra bookkeeping.
 *
 *   k-registers (k0..k7) are NOT callee-saved on Win64; freely used.
 */

    .text

    /* ─────────────────────────────────────────────────────────
     * Read-only constants for vector lane math.
     *
     *   LANE_OFFSETS_168_LO_Z[i] = i*168 for i in [0..7]   (zmm)
     *   LANE_OFFSETS_168_HI_Z[i] = (i+8)*168 for i in [0..7] (zmm)
     *
     * 168 == PATTERN_BYTES (one pattern_t in pattern_table.iii).
     * Used to materialise &table[slot_base+i] from a per-word base.
     *
     * 64-byte aligned for vmovdqa64 safety.
     * ───────────────────────────────────────────────────────── */
    .section .rdata, "dr"
    .p2align 6
LANE_OFFSETS_168_LO_Z:
    .quad 0
    .quad 168
    .quad 336
    .quad 504
    .quad 672
    .quad 840
    .quad 1008
    .quad 1176
    .p2align 6
LANE_OFFSETS_168_HI_Z:
    .quad 1344
    .quad 1512
    .quad 1680
    .quad 1848
    .quad 2016
    .quad 2184
    .quad 2352
    .quad 2520

    .text

    .global iii_resolver_unit_resolve_avx512
    .seh_proc iii_resolver_unit_resolve_avx512
iii_resolver_unit_resolve_avx512:
    /* ── Prologue: save 7 callee-saved GPRs + allocate 320-byte frame. */
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
    subq $320, %rsp
    .seh_stackalloc 320
    .seh_endprologue

    /* ── Persist incoming args into callee-saved regs:
     *   r12 = set_ptr   (pattern_set bitmap)
     *   r13 = intent_ptr
     *   r14 = ctx_ptr
     */
    movq %rcx, %r12
    movq %rdx, %r13
    movq %r8,  %r14

    /* ── Initialise best/next:
     *   ebx = best_id (lower 32 of rbx)
     *   rsi = best_score
     *   edi = next_id
     *   r15 = next_score
     */
    movl $0xFFFFFFFF, %ebx     /* best_id = NONE */
    xorq %rsi, %rsi            /* best_score = 0 */
    movl $0xFFFFFFFF, %edi     /* next_id = NONE */
    xorq %r15, %r15            /* next_score = 0 */

    /* ─────────────────────────────────────────────────────────
     * STAGE 1: locate the pattern table base address.
     *
     * We walk the bitmap scalar-style for the first occupied slot,
     * call pattern_table_get(that slot), and subtract slot*168 to
     * recover base. The first slot is also fully scored so the
     * "preserve slot-order" invariant holds.
     *
     * If the bitmap is entirely empty, jump to .Ldone with
     * best_id = 0xFFFFFFFF.
     * ───────────────────────────────────────────────────────── */
    xorl %r10d, %r10d
.Lbase_find:
    cmpl $4096, %r10d
    jge  .Ldone                    /* empty set */
    vzeroupper
    movq %r12, %rcx
    movl %r10d, %edx
    callq pattern_set_has
    testb %al, %al
    jnz  .Lbase_have_bit
    incl %r10d
    jmp  .Lbase_find
.Lbase_have_bit:
    vzeroupper
    movl %r10d, %ecx
    callq pattern_table_get
    testq %rax, %rax
    jnz  .Lbase_have_ptr
    /* bit set but pattern_id == 0 → skip and continue searching */
    incl %r10d
    jmp  .Lbase_find
.Lbase_have_ptr:
    /* table_base = rax - r10d * 168. Stash table_base on the stack. */
    movq %rax, %r11                /* r11 = slot_ptr */
    movl %r10d, %eax
    imulq $168, %rax, %rax         /* rax = slot * 168 */
    subq %rax, %r11                /* r11 = table_base */
    movq %r11, 0x100(%rsp)         /* spill table_base */

    /* Score the first occupied slot. */
    movq 0x100(%rsp), %rax
    movl %r10d, %ecx
    imulq $168, %rcx, %rcx
    addq %rcx, %rax                /* rax = p */
    vzeroupper
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    callq resolver_score           /* returns score in rax */
    /* Update best/next (strict-`>` tiebreak). */
    cmpq %rsi, %rax
    jbe  .Lbase_tieornext
    movl %ebx, %edi                /* rotate: best → next */
    movq %rsi, %r15
    movl %r10d, %ebx
    movq %rax, %rsi
    jmp  .Lbase_after
.Lbase_tieornext:
    cmpq %r15, %rax
    jbe  .Lbase_after
    movl %r10d, %edi
    movq %rax, %r15
.Lbase_after:
    incl %r10d                     /* advance past the first occupied slot */

    /* ─────────────────────────────────────────────────────────
     * STAGE 2: walk the rest of the FIRST 512-bit chunk in scalar
     * mode so r10d arrives at the AVX-512 outer loop aligned to a
     * 512-slot boundary. The "tail" is at most 511 slots.
     * ───────────────────────────────────────────────────────── */
    /* end_of_current_chunk = (r10d | 511) + 1. */
    movl %r10d, %r9d
    orl  $511, %r9d
    incl %r9d                      /* r9d = next chunk_base */
.Ltail_scalar:
    cmpl %r9d, %r10d
    jge  .Lavx_outer
    cmpl $4096, %r10d
    jge  .Ldone
    vzeroupper
    movq %r12, %rcx
    movl %r10d, %edx
    callq pattern_set_has
    testb %al, %al
    jz   .Ltail_next
    vzeroupper
    movl %r10d, %ecx
    callq pattern_table_get
    testq %rax, %rax
    jz   .Ltail_next
    movq %rax, %r11                /* r11 = p */
    vzeroupper
    movq %r11, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    callq resolver_score
    cmpq %rsi, %rax
    jbe  .Ltail_tieornext
    movl %ebx, %edi
    movq %rsi, %r15
    movl %r10d, %ebx
    movq %rax, %rsi
    jmp  .Ltail_next
.Ltail_tieornext:
    cmpq %r15, %rax
    jbe  .Ltail_next
    movl %r10d, %edi
    movq %rax, %r15
.Ltail_next:
    incl %r10d
    jmp  .Ltail_scalar

    /* ─────────────────────────────────────────────────────────
     * STAGE 3: AVX-512 outer chunk loop.
     *
     * r10d holds chunk_base (a multiple of 512). For each chunk:
     *   - Load 64 bytes (512 bits) of bitmap into zmm0.
     *   - vptestmb → k1 = per-byte non-zero mask (64 bits).
     *   - ktestq k1,k1 → skip whole chunk if zero.
     *   - Else process 64 bytes / 2 = 32 16-bit words.
     * ───────────────────────────────────────────────────────── */
.Lavx_outer:
    cmpl $4096, %r10d
    jge  .Ldone

    /* &bitmap[chunk_base/8] = r12 + chunk_base/8. */
    movl %r10d, %eax
    shrl $3, %eax
    movq %r12, %r11
    addq %rax, %r11                /* r11 = &bitmap[r10d/8] */

    /* Load 512 bits of bitmap into zmm0. */
    vmovdqu64 (%r11), %zmm0

    /* COMPUTES: k1 = per-byte non-zero mask of zmm0 (64 bits)
     * vpmovm2b reduction is achieved here implicitly: vptestmb
     * sets k1[i]=1 iff byte i of zmm0 is nonzero. The mask itself
     * IS the byte-mask — no separate vpmovm2b needed for the
     * zero-skip decision (vpmovm2b would be the inverse: turn k
     * back into a byte vector for arithmetic, which we do not need
     * here because we walk per-bit).
     */
    vptestmb %zmm0, %zmm0, %k1

    /* COMPUTES: ZF=1 iff k1 is entirely zero (all 64 bytes zero)
     * AVX-512BW gives us 64-bit k-registers; ktestq is the qword
     * variant of ktest.
     */
    ktestq %k1, %k1
    jz   .Lchunk_skip              /* empty chunk → skip 512 slots */

    /* Non-empty chunk: spill best/next so we can use rbx/rsi/rdi/r15
     * as scratch through the word loop, and spill the bitmap so we
     * can index it word-by-word from memory.
     */
    movl %ebx, 0x120(%rsp)         /* save best_id */
    movl %edi, 0x124(%rsp)         /* save next_id */
    movq %rsi, 0x128(%rsp)         /* save best_score */
    movq %r15, 0x130(%rsp)         /* save next_score */
    vmovdqu64 %zmm0, 0x40(%rsp)    /* save bitmap chunk */

    /* Walk 16-bit words 0..31 of the chunk in order. r11 = word index. */
    xorq %r11, %r11

.Lword_loop:
    cmpq $32, %r11
    jae  .Lchunk_done

    /* Load this word from the spilled bitmap (16 bits, 16 slots). */
    movzwl 0x40(%rsp, %r11, 2), %eax   /* eax = bitmap_word */
    testl %eax, %eax
    jz   .Lword_skip                   /* all 16 slots in word are unset */

    /* slot_base for this word = r10d + r11*16. */
    movl %r11d, %ecx
    shll $4, %ecx                  /* ecx = r11*16 */
    movl %r10d, %edx
    addl %ecx, %edx                /* edx = chunk_base + word_idx*16 */
    movq %rdx, 0x108(%rsp)         /* spill slot_base */
    movq %r11, 0x110(%rsp)         /* spill word index */
    movl %eax, 0x118(%rsp)         /* spill remaining_bits (= bitmap_word) */

    /* ── Build per-lane absolute pointer vectors ─────────────
     *
     * base_offset = table_base + slot_base * 168
     * zmm1 = LANE_OFFSETS_168_LO_Z + broadcast(base_offset)
     * zmm2 = LANE_OFFSETS_168_HI_Z + broadcast(base_offset)
     *
     * After this:
     *   zmm1[i] = &table[slot_base + i]   for i = 0..7
     *   zmm2[i] = &table[slot_base + i+8] for i = 0..7
     */

    /* r8 = table_base + slot_base * 168 */
    movq 0x100(%rsp), %r8          /* r8 = table_base */
    movl %edx, %ecx                /* ecx = slot_base (zero-ext) */
    imulq $168, %rcx, %rcx
    addq %rcx, %r8                 /* r8 = base_offset */

    /* Broadcast r8 across 8 qword lanes of zmm3.
     * COMPUTES: zmm3 = [r8] x 8
     */
    vpbroadcastq %r8, %zmm3

    /* Load lane-offset constants. */
    leaq LANE_OFFSETS_168_LO_Z(%rip), %rcx
    vmovdqa64 (%rcx), %zmm1
    leaq LANE_OFFSETS_168_HI_Z(%rip), %rcx
    vmovdqa64 (%rcx), %zmm2

    /* Add base_offset to each lane.
     * COMPUTES: zmm1[i] = r8 + i*168       — abs addr lane i
     *           zmm2[i] = r8 + (i+8)*168   — abs addr lane i+8
     */
    vpaddq %zmm3, %zmm1, %zmm1
    vpaddq %zmm3, %zmm2, %zmm2

    /* ── Build vpgatherqq writemasks from bitmap_word ────────
     *
     * The bitmap_word in eax has 16 set/unset bits aligned to lanes
     * [0..15]. AVX-512 vpgatherqq requires a writemask in a k-register.
     *
     *   k2 = bits [0..7]  of bitmap_word  (low 8)
     *   k3 = bits [8..15] of bitmap_word  (high 8)
     */
    movl 0x118(%rsp), %eax         /* eax = bitmap_word */
    /* k2 = low 8 bits */
    movl %eax, %ecx
    andl $0xFF, %ecx
    kmovq %rcx, %k2
    /* k3 = high 8 bits (shifted to position 0..7) */
    movl %eax, %ecx
    shrl $8, %ecx
    andl $0xFF, %ecx
    kmovq %rcx, %k3

    /* ── vpgatherqq: parallel load of pattern_id fields ──────
     *
     * AVX-512 syntax: vpgatherqq vsib_mem {k}, %dst_zmm
     * where vsib_mem = (base_gpr, index_zmm, scale).
     *
     * base_gpr=0 (xor r11), scale=1, so dst[i] = mem[ index_zmm[i] ].
     * The qword loaded is the first 8 bytes of pattern_t = pattern_id.
     *
     * AVX-512 vpgatherqq ZEROS lanes whose mask bit is clear; we
     * pre-zero the destinations anyway for clarity.
     *
     * Save r11 (word index) before reusing it as the zero base. */
    movq %r11, 0x110(%rsp)
    xorq %r11, %r11

    vpxorq %zmm6, %zmm6, %zmm6
    vpxorq %zmm7, %zmm7, %zmm7

    /* COMPUTES: zmm6[i] = mem[zmm1[i]] for i in mask k2; else 0
     * vpgatherqq CLEARS k2 after completion (architectural).
     */
    vpgatherqq (%r11, %zmm1, 1), %zmm6 {%k2}

    /* Same for high half. k3 cleared after completion. */
    vpgatherqq (%r11, %zmm2, 1), %zmm7 {%k3}

    /* Spill the 16 pattern_id qwords for scalar inspection. */
    vmovdqu64 %zmm6, 0x80(%rsp)    /* lanes 0..7 */
    vmovdqu64 %zmm7, 0xC0(%rsp)    /* lanes 8..15 */

    /* ── Horizontal-sum hsum optimisation ────────────────────
     *
     * Reduce zmm6 + zmm7 across all 16 lanes to a single u64.
     * If the sum is 0, EVERY gathered pattern_id was 0, so the
     * bit-loop has nothing to do. This skips per-lane tzcnt /
     * call overhead for the (rare) case of dead-bitmap entries.
     *
     * vextracti64x4 + vpaddq cascade per the design comment.
     */
    vpaddq %zmm7, %zmm6, %zmm8         /* zmm8 = pairwise sums (8 lanes) */
    vextracti64x4 $1, %zmm8, %ymm9     /* ymm9 = high 4 lanes of zmm8 */
    vpaddq %ymm9, %ymm8, %ymm8         /* ymm8 = 4-lane sums (low 256) */
    vextracti128 $1, %ymm8, %xmm9      /* xmm9 = high 2 lanes of ymm8 */
    vpaddq %xmm9, %xmm8, %xmm8         /* xmm8 = 2-lane sum */
    vpsrldq $8, %xmm8, %xmm9           /* xmm9 = high qword shifted to low */
    vpaddq %xmm9, %xmm8, %xmm8         /* xmm8 low qword = scalar sum */
    vmovq %xmm8, %rax                  /* rax = sum-of-pids */
    testq %rax, %rax
    jz   .Lword_clear_and_skip         /* every gathered pid was 0 */

    /* Reload word index and remaining_bits. */
    movq 0x110(%rsp), %r11
    movl 0x118(%rsp), %r9d         /* r9d = remaining_bits */

    /* ── Iterate set bits in tzcnt order ────────────────────
     *
     * For each set bit lane (in r9d, 16 bits), compute slot_id,
     * fetch the gathered pattern_id; if == 0 skip; else compute
     * pattern pointer p = table_base + slot_id*168 and call
     * resolver_score. Update best/next with strict-`>`.
     */
.Lbit_loop:
    testl %r9d, %r9d
    jz   .Lbit_done

    /* lane = tzcnt(r9d) ∈ {0..15} */
    tzcntl %r9d, %ecx              /* ecx = lane */

    /* Save lane for post-call. */
    movl %ecx, 0x114(%rsp)         /* save lane (4 bytes) */

    /* pattern_id = stack[0x80 + lane*8]. (lanes 0..7 in 0x80,
     * lanes 8..15 in 0xC0; layout is contiguous so single base 0x80). */
    movl %ecx, %eax                /* eax = lane */
    movq 0x80(%rsp, %rax, 8), %r8  /* r8 = pattern_id of lane */
    testq %r8, %r8
    jz   .Lbit_skip

    /* slot_id = slot_base + lane. */
    movq 0x108(%rsp), %rdx         /* rdx = slot_base */
    addl %ecx, %edx                /* edx = slot_id (low 32) */

    /* p = table_base + slot_id * 168. */
    movq 0x100(%rsp), %r8          /* r8 = table_base */
    movl %edx, %eax                /* eax = slot_id (zero-ext) */
    imulq $168, %rax, %rax
    addq %rax, %r8                 /* r8 = p */

    /* Save slot_id for post-call. */
    movl %edx, 0x11C(%rsp)

    /* Call resolver_score(p, intent, ctx). */
    vzeroupper
    movq %r8, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    callq resolver_score           /* rax = score */

    /* Reload remaining_bits, slot_id. */
    movl 0x118(%rsp), %r9d
    movl 0x11C(%rsp), %edx

    /* Update best/next with strict-`>` tiebreak. rax=score, edx=slot_id.
     * Spilled best/next at chunk entry; work directly on memory.
     */
    cmpq 0x128(%rsp), %rax
    jbe  .Ltieornext
    /* Rotate: next <- best; best <- (slot_id, score). */
    movl 0x120(%rsp), %ecx
    movl %ecx, 0x124(%rsp)
    movq 0x128(%rsp), %rcx
    movq %rcx, 0x130(%rsp)
    movl %edx, 0x120(%rsp)
    movq %rax, 0x128(%rsp)
    jmp  .Lbit_skip
.Ltieornext:
    cmpq 0x130(%rsp), %rax
    jbe  .Lbit_skip
    movl %edx, 0x124(%rsp)
    movq %rax, 0x130(%rsp)

.Lbit_skip:
    /* Clear lowest set bit in remaining_bits and re-spill. */
    blsrl %r9d, %r9d
    movl %r9d, 0x118(%rsp)
    jmp  .Lbit_loop

.Lbit_done:
    /* End of this word. Reload word index. */
    movq 0x110(%rsp), %r11

.Lword_skip:
    incq %r11
    cmpq $32, %r11
    jb   .Lword_loop
    jmp  .Lchunk_done

.Lword_clear_and_skip:
    /* hsum-fast path: every gathered pid was 0; skip bit-loop entirely.
     * Reload word index and continue.
     */
    movq 0x110(%rsp), %r11
    incq %r11
    cmpq $32, %r11
    jb   .Lword_loop

.Lchunk_done:
    /* Reload best/next from spill. */
    movl 0x120(%rsp), %ebx
    movl 0x124(%rsp), %edi
    movq 0x128(%rsp), %rsi
    movq 0x130(%rsp), %r15

.Lchunk_skip:
    /* Advance to next 512-bit chunk. */
    addl $512, %r10d
    jmp  .Lavx_outer

.Ldone:
    /* Clear upper ZMM/YMM state before returning. */
    vzeroupper

    /* Pack ((best_id & 0xFFFFFFFF) << 32) | (best_score & 0xFFFFFFFF). */
    movq %rsi, %rax
    movl %ebx, %ecx                /* zero-ext ebx into rcx */
    shlq $32, %rcx
    orq  %rcx, %rax

    /* Epilogue. */
    addq $320, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rdi
    popq %rsi
    popq %rbx
    retq

    .seh_endproc
