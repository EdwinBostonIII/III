/* III TYPES — Hexad / asymmetric ternary kernel.
 *
 * Implements the native ternary algebra (§11.2) and the reachability
 * bitmap (§4.3 — Representability Theorem as a typing rule).
 *
 * Asymmetric trit composition table (per spec preamble + §3.5):
 *   ZERO is identity.
 *   POS ⊙ POS = POS.
 *   NEG ⊙ NEG = NEG.
 *   NEG ⊙ POS = NEG  (NEG dominates).
 *   POS ⊙ NEG = NEG  (NEG dominates; "NEG dominates POS in pillar trits 1–4").
 *
 * Negation: swap NEG ↔ POS, leave ZERO.
 *
 * NIH discipline: only libc.
 */
#include "iii/types_hexad.h"
#include "iii/sha256.h"
#include <string.h>

uint16_t iii_hexad_pack(const iii_hexad_t *h) {
    uint16_t v = 0;
    uint16_t base = 1;
    for (int i = 0; i < 6; ++i) {
        v = (uint16_t)(v + (uint16_t)h->pillar[i] * base);
        base = (uint16_t)(base * 3);
    }
    return v;
}

void iii_hexad_unpack(uint16_t packed, iii_hexad_t *out) {
    for (int i = 0; i < 6; ++i) {
        out->pillar[i] = (iii_trit_t)(packed % 3);
        packed = (uint16_t)(packed / 3);
    }
}

bool iii_hexad_eq(const iii_hexad_t *a, const iii_hexad_t *b) {
    for (int i = 0; i < 6; ++i) if (a->pillar[i] != b->pillar[i]) return false;
    return true;
}

iii_trit_t iii_trit_compose(iii_trit_t a, iii_trit_t b) {
    if (a == III_TRIT_ZERO) return b;
    if (b == III_TRIT_ZERO) return a;
    if (a == III_TRIT_NEG || b == III_TRIT_NEG) return III_TRIT_NEG;
    return III_TRIT_POS;
}

iii_trit_t iii_trit_neg(iii_trit_t a) {
    switch (a) {
    case III_TRIT_NEG:  return III_TRIT_POS;
    case III_TRIT_POS:  return III_TRIT_NEG;
    case III_TRIT_ZERO: return III_TRIT_ZERO;
    }
    return III_TRIT_ZERO;
}

iii_hexad_t iii_hexad_compose(const iii_hexad_t *a, const iii_hexad_t *b) {
    iii_hexad_t out;
    for (int i = 0; i < 6; ++i)
        out.pillar[i] = iii_trit_compose(a->pillar[i], b->pillar[i]);
    return out;
}

iii_hexad_t iii_hexad_neg(const iii_hexad_t *a) {
    /* §3.5: r ⟲ negates pillars 1..4 (the "active" pillars) and
     * preserves pillars 0 and 5 (the structural pillars). */
    iii_hexad_t out = *a;
    for (int i = 1; i <= 4; ++i) out.pillar[i] = iii_trit_neg(a->pillar[i]);
    return out;
}

/* Bitmap: 729 bits → packed in 92 bytes; we reserve 144 to match the
 * spec's 144-byte block. */
static uint8_t g_bitmap[III_HEXAD_BITMAP_BYTES];
static int     g_bitmap_init = 0;

iii_hexad_t iii_hexad_brick(iii_brick_t which) {
    iii_hexad_t h = { { III_TRIT_ZERO, III_TRIT_ZERO, III_TRIT_ZERO,
                        III_TRIT_ZERO, III_TRIT_ZERO, III_TRIT_ZERO } };
    /* Per spec §4.3 — pillars 0..5 are listed left-to-right. */
    switch (which) {
    case III_BRICK_CAPSULE_UPDATE:
        /* (NEG, NEG, NEG, NEG, ZERO, ZERO) — pillars 0..3 NEG */
        h.pillar[0] = h.pillar[1] = h.pillar[2] = h.pillar[3] = III_TRIT_NEG;
        break;
    case III_BRICK_MICROCODE_LOAD:
        /* (NEG, NEG, NEG, ZERO, ZERO, ZERO) — pillars 0..2 NEG */
        h.pillar[0] = h.pillar[1] = h.pillar[2] = III_TRIT_NEG;
        break;
    case III_BRICK_BOOTORDER_SET:
        /* (NEG, NEG, ZERO, NEG, ZERO, ZERO) — pillars 0,1,3 NEG */
        h.pillar[0] = h.pillar[1] = h.pillar[3] = III_TRIT_NEG;
        break;
    case III_BRICK_REAL_NVRAM_WRITE:
        /* (NEG, ZERO, NEG, NEG, ZERO, ZERO) — pillars 0,2,3 NEG */
        h.pillar[0] = h.pillar[2] = h.pillar[3] = III_TRIT_NEG;
        break;
    case III_BRICK_ME_PSP_MAILBOX:
        /* (ZERO, NEG, NEG, NEG, ZERO, ZERO) — pillars 1,2,3 NEG */
        h.pillar[1] = h.pillar[2] = h.pillar[3] = III_TRIT_NEG;
        break;
    case III_BRICK_SMRAM_WRITE:
        /* (NEG, NEG, NEG, NEG, NEG, ZERO) — pillars 0..4 NEG */
        h.pillar[0] = h.pillar[1] = h.pillar[2] =
            h.pillar[3] = h.pillar[4] = III_TRIT_NEG;
        break;
    case III_BRICK__COUNT: break;
    }
    return h;
}

const char *iii_hexad_brick_name(iii_brick_t w) {
    switch (w) {
    case III_BRICK_CAPSULE_UPDATE:   return "capsule_update";
    case III_BRICK_MICROCODE_LOAD:   return "microcode_load";
    case III_BRICK_BOOTORDER_SET:    return "bootorder_set";
    case III_BRICK_REAL_NVRAM_WRITE: return "real_nvram_write";
    case III_BRICK_ME_PSP_MAILBOX:   return "me_psp_mailbox";
    case III_BRICK_SMRAM_WRITE:      return "smram_write";
    case III_BRICK__COUNT: break;
    }
    return "unknown";
}

static void bitmap_init(void) {
    if (g_bitmap_init) return;
    /* Default: every hexad in the 0..728 range is admitted (bit set). */
    memset(g_bitmap, 0xFF, sizeof g_bitmap);
    /* Clear bits past 728 (lie in the padding area). */
    for (uint32_t i = III_HEXAD_BITMAP_SLOTS; i < III_HEXAD_BITMAP_BYTES * 8; ++i)
        g_bitmap[i / 8] = (uint8_t)(g_bitmap[i / 8] & ~(1u << (i % 8)));
    /* Clear the six bricking hexads. */
    for (int b = 0; b < (int)III_BRICK__COUNT; ++b) {
        iii_hexad_t h = iii_hexad_brick((iii_brick_t)b);
        uint16_t p = iii_hexad_pack(&h);
        g_bitmap[p / 8] = (uint8_t)(g_bitmap[p / 8] & ~(1u << (p % 8)));
    }
    g_bitmap_init = 1;
}

bool iii_hexad_packed_admitted(uint16_t packed) {
    bitmap_init();
    if (packed >= III_HEXAD_BITMAP_SLOTS) return false;
    return (g_bitmap[packed / 8] >> (packed % 8)) & 1u;
}

bool iii_hexad_admitted(const iii_hexad_t *h) {
    return iii_hexad_packed_admitted(iii_hexad_pack(h));
}

void iii_hexad_bitmap_hash(uint8_t out[32]) {
    bitmap_init();
    iii_sha256(g_bitmap, sizeof g_bitmap, out);
}
