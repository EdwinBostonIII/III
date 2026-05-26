/* III-ABI — call-frame marshalling description.
 *
 * Emits a printable description of the prologue / epilogue
 * marshalling for a lowered C-MSVC-x64 signature.  This is not
 * machine code; it is the C-equivalent of the call-site code the
 * compiler will emit, plus the synthesized cycle wrapper required by
 * III-ABI.md §1.2.3 (C-ABI-3): forward → invoke; inverse →
 * Compromise<MEDIUM>; witness records argv/return; hexad
 * EXTERN_C_CALL.
 *
 * The output is line-oriented and stable; tests can hash it.
 */
#include "abi_internal.h"

#include <stdio.h>
#include <string.h>

static const char *cls_short(iii_abi_class_t c) {
    switch (c) {
        case IIIABI_CLS_VOID:    return "VOID";
        case IIIABI_CLS_INTEGER: return "INTEGER";
        case IIIABI_CLS_SSE:     return "SSE";
        case IIIABI_CLS_MEMORY:  return "MEMORY";
    }
    return "?";
}

size_t iii_abi_marshal_call(const iii_abi_signature_t *sig,
                            char *out_buf, size_t out_cap) {
    size_t pos = 0;
    if (!sig) {
        if (out_buf && out_cap) out_buf[0] = '\0';
        return 0;
    }
    if (out_buf && out_cap) out_buf[0] = '\0';

    iiiabi_appendf(out_buf, out_cap, &pos,
        "; ===== C-MSVC-x64 call frame: %s =====\n",
        sig->name[0] ? sig->name : "<anon>");
    iiiabi_appendf(out_buf, out_cap, &pos,
        "; abi          = %s\n", iii_abi_kind_name(sig->abi));
    iiiabi_appendf(out_buf, out_cap, &pos,
        "; param_count  = %u\n", (unsigned)sig->param_count);
    iiiabi_appendf(out_buf, out_cap, &pos,
        "; shadow_space = %u  (caller-reserved [rsp+0..+31])\n",
        (unsigned)sig->shadow_space);
    iiiabi_appendf(out_buf, out_cap, &pos,
        "; stack_args   = %u\n", (unsigned)sig->stack_arg_bytes);
    iiiabi_appendf(out_buf, out_cap, &pos,
        "; total_stack  = %u  (16-byte aligned)\n",
        (unsigned)sig->total_stack);
    iiiabi_appendf(out_buf, out_cap, &pos,
        "; return       = %s class=%s loc=%s%s\n",
        iii_abi_type_name(sig->ret.type),
        cls_short(sig->ret.cls),
        iii_abi_loc_name(sig->ret.loc),
        sig->hidden_ret_ptr ? "  (hidden ret-ptr in rcx)" : "");

    /* --- Prologue: synthesized cycle (C-ABI-3) ------------------- */
    iiiabi_appendf(out_buf, out_cap, &pos,
        "; ----- prologue (synthesized cycle, hexad=EXTERN_C_CALL) -----\n");
    iiiabi_appendf(out_buf, out_cap, &pos,
        "cycle.begin EXTERN_C_CALL forward=invoke inverse=Compromise<MEDIUM>\n");
    iiiabi_appendf(out_buf, out_cap, &pos,
        "witness.emit args={");
    for (uint32_t i = 0; i < sig->param_count; ++i) {
        iiiabi_appendf(out_buf, out_cap, &pos, "%s%s",
                       i ? "," : "",
                       sig->params[i].name[0] ? sig->params[i].name : "_");
    }
    iiiabi_appendf(out_buf, out_cap, &pos, "}\n");

    /* --- Stack reservation --------------------------------------- */
    iiiabi_appendf(out_buf, out_cap, &pos,
        "sub  rsp, %u                       ; reserve shadow + stack args\n",
        (unsigned)sig->total_stack);

    /* --- Hidden return ptr (if any) ------------------------------ */
    if (sig->hidden_ret_ptr) {
        iiiabi_appendf(out_buf, out_cap, &pos,
            "lea  rcx, [ret_slot]             ; hidden return pointer "
            "(MEMORY-class return, %u bytes)\n",
            (unsigned)sig->ret.size);
    }

    /* --- Argument moves ----------------------------------------- */
    for (uint32_t i = 0; i < sig->param_count; ++i) {
        const iii_abi_param_t *p = &sig->params[i];
        if (p->loc == IIIABI_LOC_STACK) {
            iiiabi_appendf(out_buf, out_cap, &pos,
                "mov  qword [rsp+%u], %-12s ; arg[%u] %s : %s%s%s "
                "(class=%s, %u B, align %u)\n",
                (unsigned)(sig->shadow_space + (uint32_t)p->stack_offset),
                p->name[0] ? p->name : "_arg_",
                (unsigned)i,
                p->name[0] ? p->name : "_",
                iii_abi_type_name(p->type),
                p->by_hidden_ref ? " (by hidden &)" : "",
                p->elem_count ? " (array)" : "",
                cls_short(p->cls),
                (unsigned)p->size,
                (unsigned)p->align);
        } else {
            iiiabi_appendf(out_buf, out_cap, &pos,
                "mov  %-4s, %-18s ; arg[%u] %s : %s%s%s "
                "(class=%s, %u B, align %u)\n",
                iii_abi_loc_name(p->loc),
                p->name[0] ? p->name : "_arg_",
                (unsigned)i,
                p->name[0] ? p->name : "_",
                iii_abi_type_name(p->type),
                p->by_hidden_ref ? " (by hidden &)" : "",
                p->elem_count ? " (array)" : "",
                cls_short(p->cls),
                (unsigned)p->size,
                (unsigned)p->align);
        }
    }

    /* --- The call ------------------------------------------------ */
    iiiabi_appendf(out_buf, out_cap, &pos,
        "call %s\n", sig->name[0] ? sig->name : "_target_");

    /* --- Return capture ----------------------------------------- */
    if (sig->ret.cls == IIIABI_CLS_INTEGER) {
        iiiabi_appendf(out_buf, out_cap, &pos,
            "mov  ret_slot, rax              ; capture INTEGER return "
            "(%u B)\n", (unsigned)sig->ret.size);
    } else if (sig->ret.cls == IIIABI_CLS_SSE) {
        iiiabi_appendf(out_buf, out_cap, &pos,
            "movsd ret_slot, xmm0            ; capture SSE return "
            "(%u B)\n", (unsigned)sig->ret.size);
    } else if (sig->ret.cls == IIIABI_CLS_MEMORY) {
        iiiabi_appendf(out_buf, out_cap, &pos,
            "; MEMORY return materialised in caller-allocated [ret_slot] "
            "(%u B)\n", (unsigned)sig->ret.size);
    }

    /* --- Stack restore ------------------------------------------ */
    iiiabi_appendf(out_buf, out_cap, &pos,
        "add  rsp, %u                       ; release frame\n",
        (unsigned)sig->total_stack);

    /* --- Epilogue: cycle.end ------------------------------------ */
    iiiabi_appendf(out_buf, out_cap, &pos,
        "witness.emit ret=%s\n",
        sig->ret.cls == IIIABI_CLS_VOID ? "()" : "ret_slot");
    iiiabi_appendf(out_buf, out_cap, &pos,
        "cycle.end EXTERN_C_CALL\n");

    return pos;
}
