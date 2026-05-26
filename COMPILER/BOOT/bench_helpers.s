/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\bench_helpers.s
 *
 * III COMPILER/BOOT - Sealed cycle-counting + serialisation helpers v1.0
 *
 * Hand-written Win64 leaf routines that expose the x86 timestamp counter
 * and CPUID-based serialisation primitives to the III benchmark suite.
 * These are NIH (RDTSC / RDTSCP / CPUID / PAUSE issued directly via gas
 * inline encoding); no third-party dependency, no libc call.
 *
 * Public symbols (Win64 ABI, MS x64):
 *
 *   bench_rdtsc -> u64
 *     Serializing RDTSC: lfence; rdtsc; pack edx:eax -> rax; lfence; ret.
 *     The leading lfence prevents speculative reads of the counter from
 *     being moved before earlier instructions in the caller; the trailing
 *     lfence prevents subsequent instructions from being issued before
 *     the counter is committed. Suitable for measuring short code
 *     intervals when RDTSCP is unavailable.
 *
 *   bench_rdtscp -> u64
 *     Non-serializing-prefix RDTSCP: rdtscp; pack edx:eax -> rax; ret.
 *     RDTSCP itself is a partial serializing instruction (it waits for
 *     all previous instructions to retire before reading the counter)
 *     so no leading lfence is required. The cpu_id sideband byte
 *     written to ecx is discarded.
 *
 *   bench_cpuid_serialize -> void
 *     Issues a single CPUID with eax=0 (vendor-id query) purely for its
 *     architectural full-serialisation side effect: every prior
 *     instruction retires and every subsequent instruction is fetched
 *     after CPUID. Preserves all caller-saved registers that CPUID
 *     overwrites (rax/rbx/rcx/rdx) by saving / restoring rbx (the only
 *     callee-saved register CPUID touches in MS x64 ABI) and leaving
 *     rax/rcx/rdx undefined on return, which Win64 callers may freely
 *     re-use as caller-saved scratch.
 *
 *   bench_pause_loop -> void
 *     Emits 16 PAUSE instructions back-to-back. Used as a fixed-cost
 *     spin-wait delay between samples in pipeline / branch-predictor
 *     bench setups. PAUSE is a single-byte hint (F3 90) that signals
 *     spin-wait to the CPU and lets sibling SMT threads run; it does
 *     not modify any architectural state.
 *
 * Calling convention: MS x64 ABI for every entry.
 *   Arguments: none for any of the four routines.
 *   Return:    bench_rdtsc / bench_rdtscp -> rax (packed u64 cycle count)
 *              bench_cpuid_serialize / bench_pause_loop -> void
 *
 * Register clobber summary (caller-visible):
 *   bench_rdtsc           clobbers rax, rdx (Win64 caller-saved -- legal).
 *   bench_rdtscp          clobbers rax, rcx, rdx (Win64 caller-saved -- legal).
 *   bench_cpuid_serialize clobbers rax, rcx, rdx (caller-saved); rbx is
 *                         preserved via push/pop.
 *   bench_pause_loop      clobbers nothing observable (PAUSE is a hint).
 *
 * SEH
 *   bench_rdtsc / bench_rdtscp / bench_pause_loop are leaf functions
 *   with no stack allocation and no callee-saved register touches. They
 *   are bracketed with .seh_proc / .seh_endproc and a single
 *   .seh_endprologue (zero-byte prologue) so the Win64 unwinder sees
 *   a well-formed UNWIND_INFO record for each (required by SEH
 *   verification on Win10+; optional for leaf functions in older
 *   spec but emitted here for uniformity with resolver_unit.s).
 *
 *   bench_cpuid_serialize touches rbx (callee-saved). It pushes rbx in
 *   its prologue (.seh_pushreg %rbx) and restores it before ret.
 *
 * DETERMINISM
 *   RDTSC / RDTSCP read a free-running counter and are by definition
 *   non-deterministic across invocations. They are NOT used in any
 *   determinism-gated build path (witness, mhash, kchain). Use limited
 *   to STDLIB benchmark harness output (verba/bench wrapper).
 *
 * REPRODUCIBILITY
 *   The .o this file produces depends only on its bytes plus gas
 *   version. SOURCE_DATE_EPOCH=0 / TZ=UTC0 / LC_ALL=C are set by
 *   build_stdlib.sh, mirroring resolver_unit.s.
 */

    .text

    /* ===================================================================
     * bench_rdtsc -> u64
     *
     * lfence -> serialise prior loads
     * rdtsc  -> EDX:EAX = TSC
     * shl    -> RDX << 32
     * or     -> RAX |= RDX shifted
     * lfence -> serialise subsequent insns against the read
     * ret
     *
     * Leaf. Zero stack alloc. Zero callee-saved touches. RAX/RDX are
     * caller-saved in MS x64 -- writing them is legal without spill.
     * =================================================================== */

    .global bench_rdtsc
    .seh_proc bench_rdtsc
bench_rdtsc:
    .seh_endprologue
    lfence
    rdtsc
    shlq $32, %rdx
    orq  %rdx, %rax
    lfence
    retq
    .seh_endproc

    /* ===================================================================
     * bench_rdtscp -> u64
     *
     * rdtscp -> EDX:EAX = TSC, ECX = IA32_TSC_AUX (discarded)
     * shl    -> RDX << 32
     * or     -> RAX |= RDX shifted
     * ret
     *
     * RDTSCP issues an implicit partial fence (waits for retirement of
     * all prior instructions) so no leading lfence is required. Trailing
     * speculation is permissible because the caller is expected to use
     * matching pre-/post-RDTSCP measurement semantics. ECX is clobbered
     * (caller-saved in MS x64).
     * =================================================================== */

    .global bench_rdtscp
    .seh_proc bench_rdtscp
bench_rdtscp:
    .seh_endprologue
    rdtscp
    shlq $32, %rdx
    orq  %rdx, %rax
    retq
    .seh_endproc

    /* ===================================================================
     * bench_cpuid_serialize -> void
     *
     * Issues CPUID(eax=0) for its full-serialisation architectural side
     * effect. CPUID overwrites EAX/EBX/ECX/EDX. Of these, EBX is
     * callee-saved in the Win64 ABI -- we MUST preserve it across the
     * call. EAX/ECX/EDX are caller-saved; we leave them clobbered.
     *
     * Stack frame: 0 bytes alloc; one push (rbx, 8 bytes) + return
     * address (8 bytes) = 16 bytes -- already 16-aligned at the CPUID
     * issue point (CPUID has no alignment requirement in any case).
     * =================================================================== */

    .global bench_cpuid_serialize
    .seh_proc bench_cpuid_serialize
bench_cpuid_serialize:
    pushq %rbx
    .seh_pushreg %rbx
    .seh_endprologue
    xorl %eax, %eax     /* CPUID leaf 0 = vendor-id query (cheapest) */
    cpuid
    popq %rbx
    retq
    .seh_endproc

    /* ===================================================================
     * bench_pause_loop -> void
     *
     * Emits PAUSE x16 back-to-back. Each PAUSE is a 2-byte hint
     * (F3 90 in machine code) with no architectural side effects. Total
     * footprint: 32 bytes of PAUSE + ret. Used as a fixed delay between
     * samples in spin-wait benchmark scenarios.
     *
     * Leaf. Zero stack alloc. Zero register touches.
     * =================================================================== */

    .global bench_pause_loop
    .seh_proc bench_pause_loop
bench_pause_loop:
    .seh_endprologue
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    pause
    retq
    .seh_endproc

    /* ===================================================================
     * iii_resolver_unit_resolve_avx2  (WEAK forwarding alias)
     * iii_resolver_unit_resolve_avx512 (WEAK forwarding alias)
     *
     * Phase C.4 sub-tasks A2 and A4 will introduce dedicated AVX-2-only
     * and AVX-512-only Software Resolution Unit entrypoints in separate
     * .s files. Until those land, corpus 237 (which benches all three
     * paths separately) needs these symbol names to resolve at link
     * time. We provide WEAK jmp thunks to the existing
     * iii_resolver_unit_resolve (defined in resolver_unit.s, which
     * already contains the AVX-2 batched code path unconditionally).
     *
     * When the strong A2/A4 definitions land in their dedicated .s
     * files, mingw-w64's BFD linker silently replaces these weak
     * thunks with the strong symbols. Corpus 237 then transparently
     * benches the differentiated machine code -- no corpus changes
     * required.
     *
     * The weak symbol's UNWIND state inherits from the jmp target
     * (resolver_unit.s's iii_resolver_unit_resolve has a full SEH
     * record). A tail-jmp into a SEH-bracketed function is legal
     * under the Win64 ABI when the source has no allocated frame.
     *
     * Both thunks are zero-frame leaves (only the jmp + tail).
     * =================================================================== */

    .weak iii_resolver_unit_resolve_avx2
iii_resolver_unit_resolve_avx2:
    jmp iii_resolver_unit_resolve

    .weak iii_resolver_unit_resolve_avx512
iii_resolver_unit_resolve_avx512:
    jmp iii_resolver_unit_resolve
