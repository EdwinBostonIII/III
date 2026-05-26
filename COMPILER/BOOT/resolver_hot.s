/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\resolver_hot.s
 *
 * Hand-written x86-64 fast path for omnia::resolver::resolve() memo-hit.
 *
 * iii_resolve_hot(set, intent, ctx) -> u64
 *
 *   Returns 0 on miss (caller falls through to the iiis-0-compiled
 *   slow path, which produces bit-identical witness output).
 *   Returns (payload | 0x8000000000000000) on success.
 *
 * Miss path is ~6 instructions (cheapest discriminator first: the
 * ctx-pointer digest cache check) so cold/miss workloads pay <20 cyc.
 *
 * MS x64 ABI: rcx=set, rdx=intent, r8=ctx, returns rax.
 *
 * Note: We do NOT push rbp/sub rsp on the miss path — the cheap
 * pre-check returns immediately without setting up a frame.
 */

    .intel_syntax noprefix
    .text
    .global iii_resolve_hot
    .seh_proc iii_resolve_hot
iii_resolve_hot:
    /* === Cheapest miss discriminator: ctx-digest cache pointer compare. ===
     * If ctx isn't the one we last cached the digest for, the slow
     * path will need to compute fresh SHA-256 anyway, so bail
     * immediately.  No frame setup required. */
    lea     r9, [rip + L_RES_CTX_CACHE_PTR]
    cmp     r8, [r9]
    jne     .Lhot_quickmiss

    /* === Cheapest second discriminator: input nullness ===
     * Only checked when ctx-cache hit (so rare hot path). */
    test    rcx, rcx
    jz      .Lhot_quickmiss
    test    rdx, rdx
    jz      .Lhot_quickmiss
    /* r8 already proven non-NULL by cache hit (cache stores live ptr) */

    /* === Now build a real frame for the longer body. === */
    push    rbp
    .seh_pushreg rbp
    mov     rbp, rsp
    .seh_setframe rbp, 0
    sub     rsp, 64
    .seh_stackalloc 64
    .seh_endprologue

    /* spill ctx for indirect-call arg4 */
    mov     [rbp - 16], r8

    /* === g_pattern_table_sealed must be 1 === */
    lea     r9, [rip + L_g_pattern_table_sealed]
    movzx   r9d, byte ptr [r9]
    test    r9d, r9d
    jz      .Lhot_miss

    /* digest first 8 bytes */
    lea     r9, [rip + L_RES_CTX_CACHE_DIG]
    mov     r10, [r9]                   /* r10 = digest_first_8 */

    /* intent_id at offset 0 */
    mov     r11, [rdx]                  /* r11 = intent_id */

    /* memo_key = set ^ (intent_id * golden) ^ digest8 */
    movabs  rax, 0x9e3779b97f4a7c15
    imul    rax, r11
    xor     rax, rcx
    xor     rax, r10
    /* rax = memo_key */

    /* slot = key & 0xFFF */
    mov     r9, rax
    and     r9, 0xFFF

    /* MEMO_LIVE[slot] (stride 1) must be 1 */
    lea     r10, [rip + L_MEMO_LIVE]
    movzx   r10d, byte ptr [r10 + r9]
    test    r10d, r10d
    jz      .Lhot_miss

    /* MEMO_KEY_HASH[slot] (stride 8) == key */
    lea     r10, [rip + L_MEMO_KEY_HASH]
    cmp     [r10 + r9*8], rax
    jne     .Lhot_miss

    /* MEMO_DISPATCH_FP[slot] (stride 8) -> spill */
    lea     r10, [rip + L_MEMO_DISPATCH_FP]
    mov     r11, [r10 + r9*8]
    test    r11, r11
    jz      .Lhot_miss
    mov     [rbp - 8], r11

    /* MEMO_PATTERN_ID[slot] (stride 8 — iiis-0 oversize) -> rax */
    lea     r10, [rip + L_MEMO_PATTERN_ID]
    mov     rax, [r10 + r9*8]
    cmp     rax, 4096
    jae     .Lhot_miss

    /* pattern slot ptr = g_pattern_table + pid * 168 */
    imul    rax, rax, 168
    lea     r10, [rip + L_g_pattern_table]
    add     rax, r10

    /* k_value = pattern[128] (u64) */
    mov     r10, [rax + 128]
    movabs  r9, 1000000000
    cmp     r10, r9
    ja      .Lhot_miss

    /* === kchain_compose inline === */
    /* kid = ctx[40] (u8) */
    mov     r8, [rbp - 16]              /* restore ctx */
    movzx   rcx, byte ptr [r8 + 40]
    test    rcx, rcx
    jz      .Lhot_miss
    cmp     rcx, 32
    ja      .Lhot_miss
    dec     rcx                         /* slot index 0..31 */

    /* KCHAIN_LIVE[slot] (stride 1) must be 1 */
    lea     r11, [rip + L_KCHAIN_LIVE]
    movzx   r11d, byte ptr [r11 + rcx]
    test    r11d, r11d
    jz      .Lhot_miss

    /* fixed-point multiply: rdx:rax = KCHAIN_CURRENT[slot] * k_value */
    lea     r11, [rip + L_KCHAIN_CURRENT]
    mov     rax, [r11 + rcx*8]
    mul     r10                         /* rdx:rax = cur * k_value */
    div     r9                          /* rax = (cur * k_value) / 1e9 */
    mov     [r11 + rcx*8], rax

    /* if new_cur < FLOOR_FX[slot] -> set UNDERFLOW[slot] = 1 */
    lea     r11, [rip + L_KCHAIN_FLOOR_FX]
    cmp     rax, [r11 + rcx*8]
    jae     .Lkchain_no_under
    lea     r11, [rip + L_KCHAIN_UNDERFLOW]
    mov     byte ptr [r11 + rcx], 1
.Lkchain_no_under:

    /* FAST PATH counter */
    lea     r9, [rip + L_RES_FAST_PATH_HITS]
    inc     qword ptr [r9]

    /* indirect dispatch: value = fp(0, 0, 0, ctx) */
    xor     ecx, ecx
    xor     edx, edx
    xor     r8d, r8d
    mov     r9, [rbp - 16]
    call    qword ptr [rbp - 8]

    /* pack payload: (value & 0x7FFF...F) << 1, set MSB success flag */
    movabs  r10, 0x7FFFFFFFFFFFFFFF
    and     rax, r10
    shl     rax, 1
    movabs  r10, 0x8000000000000000
    or      rax, r10

    add     rsp, 64
    pop     rbp
    ret

.Lhot_miss:
    xor     eax, eax
    add     rsp, 64
    pop     rbp
    ret

.Lhot_quickmiss:
    xor     eax, eax
    ret
    .seh_endproc
