/* C:\Users\Edwin Boston\OneDrive\Desktop\III\FORCEFIELD\cpuid_helper.s
 *
 * Native CPUID + XGETBV primitives for P4.1 (cpufeat C-separation).  Replaces
 * the kernel32 IsProcessorFeaturePresent umbilical with on-die feature reads.
 * Win64 ABI: integer args rcx, rdx, r8, r9; return in rax; rbx is callee-saved
 * (CPUID clobbers ebx, so it is preserved here).
 *
 *   iii_cpuid(leaf:u32 [rcx], subleaf:u32 [rdx], out:*u32[4] [r8])
 *       writes eax,ebx,ecx,edx to out[0..3].
 *   iii_xgetbv(xcr:u32 [rcx]) -> u64
 *       returns (edx<<32)|eax of the named XCR (XCR0 = 0).  Requires
 *       CR4.OSXSAVE; the caller must gate on CPUID.1:ECX[27] (OSXSAVE) first,
 *       else XGETBV faults #UD.
 */
    .text

    .globl iii_cpuid
iii_cpuid:
    pushq   %rbx
    movl    %ecx, %eax          /* leaf    */
    movl    %edx, %ecx          /* subleaf */
    cpuid
    movl    %eax,  0(%r8)
    movl    %ebx,  4(%r8)
    movl    %ecx,  8(%r8)
    movl    %edx, 12(%r8)
    popq    %rbx
    ret

    .globl iii_xgetbv
iii_xgetbv:
    movl    %ecx, %ecx          /* xcr index (already in ecx via rcx) */
    xgetbv                      /* -> edx:eax */
    shlq    $32, %rdx
    movl    %eax, %eax          /* zero-extend eax into rax */
    orq     %rdx, %rax
    ret
