/* III Grammar — canonical AST byte serialization + R1.A2 mhash.
 *
 * Per-node chunk layout (little-endian, byte-for-byte):
 *   u16  kind
 *   u16  child_count
 *   u32  interned_id
 *   u64  int_value
 *   u8[32] mhash_value
 *   u16  hexad_packed
 *   u8   int_suffix
 *   u16  op_id
 *   u32  string_len
 *   u8[string_len] string_payload
 *
 * Children are written immediately after the parent's chunk in
 * pre-order traversal.  Source spans, line/col, child_cap, and
 * doc_offset are NOT part of the canonical form (they are not part
 * of grammatical identity per §12).
 *
 * Modifier canonicalization (§10.6): when a parent's direct children
 * include any *_MODIFIER kinds, the modifier children are sorted
 * (stable-ordered) by (kind, interned_id, op_id, payload bytes) before
 * being serialized.  Their relative positions among the parent's
 * children are preserved (i.e., we sort only the slots that are modifiers,
 * leaving non-modifier slots untouched).
 *
 * NIH discipline: only libc + iii_sha256.
 */
#include "iii/ast_print.h"
#include "iii/ast.h"
#include "iii/sha256.h"

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>

/* ---------- growing byte buffer ---------- */

typedef struct {
    uint8_t *data;
    size_t   len;
    size_t   cap;
    int      oom;
} buf_t;

static void buf_init(buf_t *b) {
    b->cap = 4096;
    b->len = 0;
    b->oom = 0;
    b->data = (uint8_t*)malloc(b->cap);
    if (!b->data) { b->oom = 1; b->cap = 0; }
}

static void buf_reserve(buf_t *b, size_t n) {
    if (b->oom) return;
    if (b->len + n <= b->cap) return;
    size_t nc = b->cap ? b->cap : 1;
    while (nc < b->len + n) nc *= 2;
    uint8_t *nd = (uint8_t*)realloc(b->data, nc);
    if (!nd) { b->oom = 1; return; }
    b->data = nd;
    b->cap  = nc;
}

static void buf_u8(buf_t *b, uint8_t v) {
    buf_reserve(b, 1);
    if (b->oom) return;
    b->data[b->len++] = v;
}

static void buf_u16(buf_t *b, uint16_t v) {
    buf_reserve(b, 2);
    if (b->oom) return;
    b->data[b->len++] = (uint8_t)(v & 0xFF);
    b->data[b->len++] = (uint8_t)((v >> 8) & 0xFF);
}

static void buf_u32(buf_t *b, uint32_t v) {
    buf_reserve(b, 4);
    if (b->oom) return;
    b->data[b->len++] = (uint8_t)(v & 0xFF);
    b->data[b->len++] = (uint8_t)((v >> 8) & 0xFF);
    b->data[b->len++] = (uint8_t)((v >> 16) & 0xFF);
    b->data[b->len++] = (uint8_t)((v >> 24) & 0xFF);
}

static void buf_u64(buf_t *b, uint64_t v) {
    buf_reserve(b, 8);
    if (b->oom) return;
    for (int i = 0; i < 8; i++) {
        b->data[b->len++] = (uint8_t)((v >> (i * 8)) & 0xFF);
    }
}

static void buf_bytes(buf_t *b, const uint8_t *p, size_t n) {
    buf_reserve(b, n);
    if (b->oom) return;
    if (n) memcpy(b->data + b->len, p, n);
    b->len += n;
}

/* ---------- modifier classification ---------- */

static int is_modifier_kind(iii_ast_kind_t k) {
    switch (k) {
        case III_AST_CYCLE_MODIFIER:
        case III_AST_FUNCTION_MODIFIER:
        case III_AST_TYPE_MODIFIER:
        case III_AST_MOBIUS_CANDIDATE_MODIFIER:
        case III_AST_WAVEFRONT_MODIFIER:
            return 1;
        default:
            return 0;
    }
}

/* ---------- per-node serialization ---------- */

static void write_node(buf_t *b, const iii_ast_node_t *n);

static void write_node_self(buf_t *b, const iii_ast_node_t *n) {
    /* NULL node: emit canonical sentinel (kind=0, payload=0, no children).
     * This makes the canonical encoding total — caller may pass NULL for
     * absent optional sub-trees and the byte stream is well-defined. */
    if (!n) {
        buf_u16(b, 0);
        buf_u16(b, 0);
        buf_u32(b, 0);
        buf_u64(b, 0);
        for (int i = 0; i < 32; i++) buf_u8(b, 0);
        buf_u16(b, 0);
        buf_u8(b, 0);
        buf_u16(b, 0);
        buf_u32(b, 0);
        return;
    }

    buf_u16(b, (uint16_t)n->kind);
    buf_u16(b, (uint16_t)n->child_count);
    /* When a node carries a literal `string_payload`, the identifier
     * is fully captured by those bytes — write a stable 0 for
     * `interned_id` so that two parses that intern the same text under
     * different (parser-local) ids still produce the same canonical
     * bytes (and therefore the same R1.A2 mhash). */
    buf_u32(b, (n->string_payload && n->string_len) ? 0u : n->interned_id);
    buf_u64(b, n->int_value);
    buf_bytes(b, n->mhash_value, 32);
    buf_u16(b, n->hexad_packed);
    buf_u8 (b, n->int_suffix);
    buf_u16(b, n->op_id);
    uint32_t sl = (uint32_t)((n->string_payload && n->string_len) ? n->string_len : 0);
    buf_u32(b, sl);
    if (sl) buf_bytes(b, n->string_payload, sl);
}

/* Compare two modifier children for canonical ordering. */
static int cmp_mod(const iii_ast_node_t *a, const iii_ast_node_t *b) {
    if (!a && !b) return 0;
    if (!a) return -1;
    if (!b) return  1;
    if (a->kind != b->kind) return (a->kind < b->kind) ? -1 : 1;
    if (a->interned_id != b->interned_id)
        return (a->interned_id < b->interned_id) ? -1 : 1;
    if (a->op_id != b->op_id)
        return (a->op_id < b->op_id) ? -1 : 1;
    if (a->int_value != b->int_value)
        return (a->int_value < b->int_value) ? -1 : 1;
    if (a->hexad_packed != b->hexad_packed)
        return (a->hexad_packed < b->hexad_packed) ? -1 : 1;
    int mc = memcmp(a->mhash_value, b->mhash_value, 32);
    if (mc) return mc;
    size_t al = a->string_payload ? a->string_len : 0;
    size_t bl = b->string_payload ? b->string_len : 0;
    size_t ml = al < bl ? al : bl;
    if (ml) {
        int sc = memcmp(a->string_payload, b->string_payload, ml);
        if (sc) return sc;
    }
    if (al != bl) return (al < bl) ? -1 : 1;
    if (a->child_count != b->child_count)
        return (a->child_count < b->child_count) ? -1 : 1;
    return 0;
}

/* Insertion sort over indices (small N expected; stable). */
static void sort_indices(uint32_t *idx, size_t n,
                         iii_ast_node_t *const *children) {
    for (size_t i = 1; i < n; i++) {
        uint32_t v = idx[i];
        size_t j = i;
        while (j > 0 && cmp_mod(children[idx[j-1]], children[v]) > 0) {
            idx[j] = idx[j-1];
            j--;
        }
        idx[j] = v;
    }
}

static void write_children(buf_t *b, const iii_ast_node_t *n) {
    if (!n || n->child_count == 0) return;

    uint32_t cc = n->child_count;

    /* Find modifier slots. */
    uint32_t *mod_slots = NULL;
    size_t    mod_n = 0;
    for (uint32_t i = 0; i < cc; i++) {
        const iii_ast_node_t *c = n->children[i];
        if (c && is_modifier_kind(c->kind)) mod_n++;
    }

    iii_ast_node_t **emit = n->children;
    iii_ast_node_t **owned = NULL;

    if (mod_n > 1) {
        mod_slots = (uint32_t*)malloc(sizeof(uint32_t) * mod_n);
        owned = (iii_ast_node_t**)malloc(sizeof(iii_ast_node_t*) * cc);
        if (mod_slots && owned) {
            size_t k = 0;
            for (uint32_t i = 0; i < cc; i++) {
                if (n->children[i] && is_modifier_kind(n->children[i]->kind))
                    mod_slots[k++] = i;
                owned[i] = n->children[i];
            }
            /* Sort the modifier nodes (by content), then place them
             * back into the modifier slots in canonical order. */
            uint32_t *order = (uint32_t*)malloc(sizeof(uint32_t) * mod_n);
            if (order) {
                for (size_t i = 0; i < mod_n; i++) order[i] = mod_slots[i];
                sort_indices(order, mod_n, n->children);
                for (size_t i = 0; i < mod_n; i++) {
                    owned[mod_slots[i]] = n->children[order[i]];
                }
                free(order);
                emit = owned;
            }
        }
    }

    for (uint32_t i = 0; i < cc; i++) {
        write_node(b, emit[i]);
    }

    free(mod_slots);
    free(owned);
}

static void write_node(buf_t *b, const iii_ast_node_t *n) {
    write_node_self(b, n);
    if (b->oom) return;
    write_children(b, n);
}

/* ---------- public API ---------- */

int iii_ast_canonical(const iii_ast_node_t *root,
                      uint8_t **out_buf, size_t *out_len)
{
    if (!out_buf || !out_len) return -1;
    *out_buf = NULL;
    *out_len = 0;

    buf_t b;
    buf_init(&b);
    if (b.oom) return -1;

    write_node(&b, root);

    if (b.oom) {
        free(b.data);
        return -1;
    }
    *out_buf = b.data;
    *out_len = b.len;
    return 0;
}

void iii_ast_mhash(const iii_ast_node_t *root, uint8_t out[32])
{
    uint8_t *buf = NULL;
    size_t   len = 0;
    if (iii_ast_canonical(root, &buf, &len) != 0) {
        memset(out, 0, 32);
        return;
    }
    iii_sha256(buf, len, out);
    free(buf);
}
