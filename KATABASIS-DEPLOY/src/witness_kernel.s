# iii_witness_emit_kernel - Tier-1 kernel witness bus (bare-ret leaf).
#
# Every cg_r0-emitted function calls this on enter (movq $1,%rcx) and on exit
# (movq $2,%rcx) via:  subq $32,%rsp ; callq iii_witness_emit_kernel ; addq $32,%rsp
#
# Contract (cg_r0.h D9): non-blocking (no KeWait/no spinlock), IRQL-safe up to and
# including HIGH_LEVEL, no allocator entry, preserves all registers.
#
# Tier-1 implementation is a register-preserving no-op sink: it touches NO register
# and NO memory, then returns. That trivially satisfies every clause of the contract
# at any IRQL. It is hand-written (NOT emitted by cg_r0) precisely because a cg_r0
# function would itself emit a "callq iii_witness_emit_kernel" prologue and recurse.
#
# Leaf SEH frame (no prologue) so the image has valid .pdata/.xdata unwind info.

    .att_syntax
    .text
    .global iii_witness_emit_kernel
    .seh_proc iii_witness_emit_kernel
iii_witness_emit_kernel:
    .seh_endprologue
    retq
    .seh_endproc
