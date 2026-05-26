/* jit_emit_accessors.c
 *
 * Flat accessor surface for iii_jit_buf_t — needed because the
 * Stage-0 .iii dialect cannot dereference struct fields through a
 * pointer.  Mirrors the pattern in ast_accessors.c.
 *
 * Every wrapper takes the buffer pointer as `uint64_t buf` and
 * returns/accepts scalar values.  Indexed access into the bytes
 * blob and reloc table is exposed as raw read/write helpers.
 */

#include "jit_emit.h"
#include <stddef.h>
#include <stdint.h>
#include <string.h>

static inline iii_jit_buf_t *AS_BUF(uint64_t b)
{
    return (iii_jit_buf_t *)(uintptr_t)b;
}

uint64_t iii_jit_buf_bytes(uint64_t b)        { return (uint64_t)(uintptr_t)AS_BUF(b)->buf; }
uint64_t iii_jit_buf_cap(uint64_t b)          { return (uint64_t)AS_BUF(b)->cap; }
uint64_t iii_jit_buf_used(uint64_t b)         { return (uint64_t)AS_BUF(b)->used; }
uint32_t iii_jit_buf_overflow(uint64_t b)     { return (uint32_t)AS_BUF(b)->overflow; }
uint32_t iii_jit_buf_err(uint64_t b)          { return (uint32_t)AS_BUF(b)->err; }
uint64_t iii_jit_buf_last_insn_off(uint64_t b){ return (uint64_t)AS_BUF(b)->last_insn_off; }
uint64_t iii_jit_buf_relocs(uint64_t b)       { return (uint64_t)(uintptr_t)AS_BUF(b)->relocs; }
uint64_t iii_jit_buf_reloc_cap(uint64_t b)    { return (uint64_t)AS_BUF(b)->reloc_cap; }
uint64_t iii_jit_buf_reloc_used(uint64_t b)   { return (uint64_t)AS_BUF(b)->reloc_used; }

uint32_t iii_jit_buf_set_used(uint64_t b, uint64_t v)
{ AS_BUF(b)->used = (size_t)v; return 0; }
uint32_t iii_jit_buf_set_err(uint64_t b, uint32_t v)
{ AS_BUF(b)->err = (iii_jit_err_t)v; return 0; }
uint32_t iii_jit_buf_set_overflow(uint64_t b, uint32_t v)
{ AS_BUF(b)->overflow = (int)v; return 0; }
uint32_t iii_jit_buf_set_last_insn_off(uint64_t b, uint64_t v)
{ AS_BUF(b)->last_insn_off = (size_t)v; return 0; }
uint32_t iii_jit_buf_set_reloc_used(uint64_t b, uint64_t v)
{ AS_BUF(b)->reloc_used = (size_t)v; return 0; }

uint64_t iii_jit_sizeof_reloc(void) { return (uint64_t)sizeof(iii_jit_reloc_t); }
uint64_t iii_jit_sizeof_buf(void)   { return (uint64_t)sizeof(iii_jit_buf_t); }

/* One-shot init helpers — Stage-0 .iii cannot assign through a struct
 * pointer to fields it doesn't have a setter for (`buf`, `cap`,
 * `relocs`, `reloc_cap`).  These bring those fields under the same
 * accessor surface as the rest, with full reset semantics matching
 * iii_jit_init() / iii_jit_attach_relocs() in jit_emit.c. */
uint32_t iii_jit_init_c(uint64_t b, uint64_t bytes, uint64_t cap)
{
    iii_jit_buf_t *buf = AS_BUF(b);
    buf->buf            = (uint8_t *)(uintptr_t)bytes;
    buf->cap            = (size_t)cap;
    buf->used           = 0;
    buf->overflow       = 0;
    buf->err            = III_JIT_E_OK;
    buf->last_insn_off  = 0;
    buf->relocs         = NULL;
    buf->reloc_cap      = 0;
    buf->reloc_used     = 0;
    return 0;
}

uint32_t iii_jit_attach_relocs_c(uint64_t b, uint64_t r, uint64_t cap)
{
    iii_jit_buf_t *buf = AS_BUF(b);
    buf->relocs     = (iii_jit_reloc_t *)(uintptr_t)r;
    buf->reloc_cap  = (size_t)cap;
    buf->reloc_used = 0;
    return 0;
}
