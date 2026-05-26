/* Operator table — 23 operators per §6.1.  Each is keyed by its
 * codepoint(s); doubled forms get matched first via maximal munch. */
#include <stdint.h>
#include <stddef.h>

typedef struct {
    int id;
    uint32_t cp1;
    uint32_t cp2;     /* 0 = single-codepoint */
} op_entry_t;

/* The 23 operators (id matches §6.1 numbering 1..23). */
static const op_entry_t OPS[] = {
    { 1, 0x27F2, 0      }, /* ⟲ Inverse */
    { 2, 0x2295, 0      }, /* ⊕ Cycle Compose */
    { 3, 0x2297, 0      }, /* ⊗ Glyph Materialize */
    { 4, 0x29C9, 0      }, /* ⧉ Hexad Compose */
    { 5, 0x27D0, 0      }, /* ⟐ Trinity Gate */
    { 6, 0x21BB, 0      }, /* ↻ Replay */
    { 7, 0x27E1, 0      }, /* ⟡ Witness Emit */
    { 8, 0x27C1, 0      }, /* ⟁ Ceiling Check */
    { 9, 0x29D7, 0      }, /* ⧗ Möbius Coherence */
    {10, 0x27F4, 0      }, /* ⟴ Phase Cross */
    {11, 0x29C8, 0      }, /* ⧈ Cap Acquire/Release */
    {12, 0x27F5, 0      }, /* ⟵ Epoch Bridge */
    {13, 0x29CA, 0      }, /* ⧊ VDF Squaring */
    {14, 0x27F6, 0      }, /* ⟶ Federation Replicate */
    {15, 0x2A01, 0      }, /* ⨁ Amendment Apply */
    {16, 0x27F2, 0x27F2 }, /* ⟲⟲ Full Inverse Replay */
    {17, 0x229B, 0      }, /* ⊛ Catalyst Promote */
    {18, 0x29C4, 0      }, /* ⧄ OBSERVATORY Saturate */
    {19, 0x27D0, 0x27D0 }, /* ⟐⟐ Narrative Reflect */
    {20, 0x29C7, 0      }, /* ⧇ Uncertainty Query */
    {21, 0x27E1, 0x27E1 }, /* ⟡⟡ Explain */
    {22, 0x29CB, 0      }, /* ⧋ Propose */
    {23, 0x27F4, 0x27F4 }  /* ⟴⟴ Negotiate */
};

#define OP_COUNT (sizeof(OPS)/sizeof(OPS[0]))

/* Look up a single-codepoint operator.  Returns id (1..23) or 0 if not an operator. */
int iii_lex_operator_single(uint32_t cp) {
    for (size_t i = 0; i < OP_COUNT; i++) {
        if (OPS[i].cp2 == 0 && OPS[i].cp1 == cp) return OPS[i].id;
    }
    return 0;
}

/* Look up a doubled operator. */
int iii_lex_operator_double(uint32_t cp1, uint32_t cp2) {
    for (size_t i = 0; i < OP_COUNT; i++) {
        if (OPS[i].cp2 == cp2 && OPS[i].cp1 == cp1 && cp2 != 0) return OPS[i].id;
    }
    return 0;
}

size_t iii_lex_operator_count(void) { return OP_COUNT; }
int iii_lex_operator_at(size_t i, uint32_t *out_cp1, uint32_t *out_cp2) {
    if (i >= OP_COUNT) return 0;
    if (out_cp1) *out_cp1 = OPS[i].cp1;
    if (out_cp2) *out_cp2 = OPS[i].cp2;
    return OPS[i].id;
}
