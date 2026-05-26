/* III-ABI — The Bootstrap-Only ABI Module.
 *
 * Implements III-ABI.md (R1.C1).  One rule: every cross-language
 * bridge in III uses `extern @abi(c-msvc-x64)` and only that.
 *
 *   * The lexer/grammar admit any IDENT for the ABI name; this
 *     module is the gatekeeper that enforces the single legal value.
 *   * Ring restriction: extern blocks are accepted only inside
 *     modules whose @ring set is a subset of {R0, R3}.
 *   * Bootstrap discipline: all extern items are typed by the
 *     restricted `extern_type` grammar (primitives, &T or *T,
 *     fixed-size arrays, intra-block aliases) — no higher-kinded
 *     III types are admitted as arguments.
 *
 * Public surface:
 *
 *   * iii_abi_validate_extern  — verify an EXTERN_DECL node.
 *   * iii_abi_lower_signature  — produce the C-MSVC-x64 calling-
 *                                convention descriptor for one
 *                                EXTERN_ITEM (fn …).
 *   * iii_abi_marshal_call     — emit a printable call-frame layout
 *                                describing the prologue/epilogue
 *                                marshalling for a lowered signature.
 *
 * NIH discipline: only libc (and the III lex/grammar libraries).
 */
#ifndef III_ABI_H
#define III_ABI_H

#include <stdint.h>
#include <stddef.h>

#include <iii/ast.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ====================================================================
 * §1.  ABI kind — only one legal value.
 * ==================================================================== */

typedef enum iii_abi_kind {
    IIIABI_KIND_NONE      = 0,
    IIIABI_C_MSVC_X64     = 1   /* the only legal cross-language bridge */
} iii_abi_kind_t;

/* The canonical spelling.  Any deviation is rejected. */
#define IIIABI_NAME_C_MSVC_X64 "c-msvc-x64"

const char *iii_abi_kind_name(iii_abi_kind_t k);

/* ====================================================================
 * §2.  Diagnostics.
 * ==================================================================== */

typedef enum iii_abi_diag_code {
    IIIABI_OK                       = 0,
    IIIABI_E_NOT_EXTERN_DECL        = 1,
    IIIABI_E_MISSING_ABI            = 2,
    IIIABI_E_BAD_ABI_NAME           = 3,
    IIIABI_E_NO_RING_ATTR           = 4,
    IIIABI_E_BAD_RING               = 5,
    IIIABI_E_FORBIDDEN_TYPE         = 6,
    IIIABI_E_NOT_EXTERN_ITEM        = 7,
    IIIABI_E_TOO_MANY_PARAMS        = 8,
    IIIABI_E_INTERNAL               = 9,
    IIIABI_E_NULL_ARG               = 10,
    IIIABI_E_BAD_ALIAS              = 11,
    IIIABI_E_NOT_FN_ITEM            = 12
} iii_abi_diag_code_t;

typedef struct iii_abi_diag {
    int      code;
    char     message[256];
    uint32_t span_start;
    uint32_t span_end;
    uint32_t line;
    uint32_t col;
} iii_abi_diag_t;

const char *iii_abi_diag_name(int code);

/* ====================================================================
 * §3.  Lowered signature — C-MSVC-x64 calling convention descriptor.
 * ==================================================================== */

typedef enum iii_abi_type_kind {
    IIIABI_T_VOID    = 0,   /* unit return  ()    */
    IIIABI_T_BOOL    = 1,
    IIIABI_T_U8      = 2,
    IIIABI_T_U16     = 3,
    IIIABI_T_U32     = 4,
    IIIABI_T_U64     = 5,
    IIIABI_T_I8      = 6,
    IIIABI_T_I16     = 7,
    IIIABI_T_I32     = 8,
    IIIABI_T_I64     = 9,
    IIIABI_T_F32     = 10,
    IIIABI_T_F64     = 11,
    IIIABI_T_PTR     = 12,  /* &T   (always 8 bytes on x64)         */
    IIIABI_T_ARRAY   = 13,  /* [T;N]                                */
    IIIABI_T_ALIAS   = 14   /* IDENT — resolved against the same    */
                            /* extern block's `type` items.         */
} iii_abi_type_kind_t;

const char *iii_abi_type_name(iii_abi_type_kind_t t);

typedef enum iii_abi_class {
    IIIABI_CLS_VOID     = 0,
    IIIABI_CLS_INTEGER  = 1,  /* passes in {rcx,rdx,r8,r9} or stack  */
    IIIABI_CLS_SSE      = 2,  /* passes in {xmm0..xmm3}    or stack  */
    IIIABI_CLS_MEMORY   = 3   /* aggregate >8 bytes — by hidden ref  */
} iii_abi_class_t;

const char *iii_abi_class_name(iii_abi_class_t c);

typedef enum iii_abi_loc {
    IIIABI_LOC_NONE         = 0,
    IIIABI_LOC_RCX          = 1,
    IIIABI_LOC_RDX          = 2,
    IIIABI_LOC_R8           = 3,
    IIIABI_LOC_R9           = 4,
    IIIABI_LOC_XMM0         = 5,
    IIIABI_LOC_XMM1         = 6,
    IIIABI_LOC_XMM2         = 7,
    IIIABI_LOC_XMM3         = 8,
    IIIABI_LOC_STACK        = 9,    /* on caller stack above shadow space */
    IIIABI_LOC_RAX          = 10,   /* return                                */
    IIIABI_LOC_XMM0_RET     = 11,   /* float/double return                   */
    IIIABI_LOC_HIDDEN_PTR   = 12    /* return-by-hidden-pointer (first arg)  */
} iii_abi_loc_t;

const char *iii_abi_loc_name(iii_abi_loc_t l);

typedef struct iii_abi_param {
    char                 name[64];     /* parameter name from source        */
    iii_abi_type_kind_t  type;
    uint32_t             size;         /* bytes                              */
    uint32_t             align;        /* bytes (power of two)               */
    iii_abi_class_t      cls;
    iii_abi_loc_t        loc;
    int32_t              stack_offset; /* bytes from rsp at call site;       */
                                       /* 0 = first slot above shadow (32)   */
    int                  by_hidden_ref;/* aggregate passed by pointer        */
    uint32_t             elem_count;   /* for arrays; 0 otherwise            */
    iii_abi_type_kind_t  elem_type;    /* for arrays / pointee               */
} iii_abi_param_t;

#define IIIABI_MAX_PARAMS 32

typedef struct iii_abi_signature {
    char                 name[128];
    iii_abi_kind_t       abi;
    uint32_t             param_count;
    iii_abi_param_t      params[IIIABI_MAX_PARAMS];
    iii_abi_param_t      ret;
    int                  hidden_ret_ptr; /* return-by-pointer in rcx          */
    uint32_t             shadow_space;   /* always 32                          */
    uint32_t             stack_arg_bytes;/* bytes for stack args after shadow  */
    uint32_t             total_stack;    /* shadow + stack_arg_bytes (16-aligned) */
} iii_abi_signature_t;

/* ====================================================================
 * §4.  Validation.
 *
 *  * `module`      — owning III_AST_MODULE node (for @ring(…) check).
 *                    May be NULL → ring check is skipped (caller's risk).
 *  * `extern_decl` — III_AST_EXTERN_DECL node to validate.
 *  * `src` / `src_len` — original source bytes (used to recover the
 *                    multi-token ABI name `c-msvc-x64`, which the
 *                    parser only stores in part).
 *  * `out_diag`    — first failing diagnostic; set even on OK.
 *
 * Returns IIIABI_OK or one of IIIABI_E_*.
 * ==================================================================== */

int iii_abi_validate_extern(const iii_ast_node_t *module,
                            const iii_ast_node_t *extern_decl,
                            const uint8_t *src, size_t src_len,
                            iii_abi_diag_t *out_diag);

/* Convenience: validate every extern_decl child of `module`.  Stops
 * at first error.  Returns IIIABI_OK if none failed. */
int iii_abi_validate_module(const iii_ast_node_t *module,
                            const uint8_t *src, size_t src_len,
                            iii_abi_diag_t *out_diag);

/* ====================================================================
 * §5.  Signature lowering.
 *
 *  * `extern_decl`  — owning EXTERN_DECL (used for alias resolution).
 *  * `extern_item`  — III_AST_EXTERN_ITEM with op_id == 0 (fn).
 *  * `sig_out`      — filled on success.
 *
 * The descriptor follows the Microsoft x64 calling convention:
 *
 *   * First four INTEGER-class arguments → rcx, rdx, r8, r9.
 *   * First four SSE-class     arguments → xmm0, xmm1, xmm2, xmm3.
 *     Each register slot is consumed positionally — slot N is RCX/XMM0
 *     for N==0, RDX/XMM1 for N==1, R8/XMM2 for N==2, R9/XMM3 for N==3.
 *   * Aggregates (>8 bytes, or non-power-of-two size) → MEMORY class:
 *     caller passes a hidden pointer in the integer slot for that
 *     position.
 *   * Remaining arguments → stack, 8-byte slots, above 32-byte shadow.
 *   * Return value:
 *       VOID                              → loc = NONE
 *       INTEGER (≤8B)                     → RAX
 *       SSE     (f32/f64)                 → XMM0
 *       MEMORY                            → hidden_ret_ptr=1, RCX holds
 *                                            pointer to caller-allocated
 *                                            return slot; remaining args
 *                                            shift one register right.
 *
 * Returns IIIABI_OK or an IIIABI_E_* code.
 * ==================================================================== */

int iii_abi_lower_signature(const iii_ast_node_t *extern_decl,
                            const iii_ast_node_t *extern_item,
                            iii_abi_signature_t *sig_out);

/* ====================================================================
 * §6.  Call-frame marshalling.
 *
 * Emits a printable description of the prologue/epilogue marshalling
 * for `sig`: which sources go into which destinations, the layout of
 * the shadow space, the stack-arg slots, and the post-call return
 * fetch.  Returns the number of bytes that would be written if the
 * buffer were unbounded (truncates at out_cap-1, always 0-terminates).
 * ==================================================================== */

size_t iii_abi_marshal_call(const iii_abi_signature_t *sig,
                            char *out_buf, size_t out_cap);

/* ====================================================================
 * §7.  Synthetic builder — for tools/tests that need a signature
 * without parsing III source.
 * ==================================================================== */

void iii_abi_signature_init(iii_abi_signature_t *sig, const char *name);
int  iii_abi_signature_set_return(iii_abi_signature_t *sig,
                                  iii_abi_type_kind_t  ret);
int  iii_abi_signature_add_param(iii_abi_signature_t *sig,
                                 const char *name,
                                 iii_abi_type_kind_t  type,
                                 uint32_t            elem_count,
                                 iii_abi_type_kind_t elem_type);
/* Recompute classification + register/stack assignments after edits. */
void iii_abi_signature_finalize(iii_abi_signature_t *sig);

#ifdef __cplusplus
}
#endif
#endif /* III_ABI_H */
