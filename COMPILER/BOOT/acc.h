/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\acc.h
 *
 * III Stage-0 Algebraic Cycle Composition (Wall-Y) — public interface.
 *
 * Mirrors the runtime ACC of CONSTITUTIONAL/include/acc.h: a cycle's
 * "constitutional impact" is a 6-component Z₃ vector; cycle
 * composition is componentwise (mod 3) addition; admission is a
 * 729-bit bitmap test indexed by the composed state.
 *
 * For Stage 0 the bitmap is bootstrap-permissive: all 729 entries are
 * admitted by default until the constitutional ceiling is computed and
 * installed (per CONSTITUTIONAL/include/acc.h::xii_acc_init bootstrap
 * mode).  Codegen narrows the bitmap as cycles are registered.
 *
 * Strict NIH (ADR-021): libc only.  Deterministic / reproducible
 * (ADR-027): no time, pid, or pointer-derived data is committed to any
 * persistent output (the canonical bitmap fingerprint is content-only).
 *
 * Runtime / codegen parity contract (see "Layout parity" section near
 * the bottom of this header for byte-exact details):
 *
 *   - The Z₃⁶ component encoding {NEG→2, ZERO→0, POS→1} is identical to
 *     CONSTITUTIONAL/include/acc.h (lines ≈28-31, 74-85).
 *   - The base-3 packing is THE canonical Wall-Y index; see
 *     III_ACC_INDEX_IS_BIG_ENDIAN_TRIT below.  Identical to
 *     xii_acc_state_to_z3_index() at CONSTITUTIONAL/include/acc.h:77-85.
 *   - The 12 × uint64_t bitmap word layout is identical to
 *     g_xii_acc_admitted_z3_bitmap at CONSTITUTIONAL/include/acc.h:107.
 *   - The boot-side state struct is intentionally NOT 32-byte aligned
 *     (no AVX hot path here); it is layout-equivalent on the comp[]
 *     prefix.  See III_ACC_PARITY_NOTE.
 *
 * Spec refs: CONSTITUTIONAL/include/acc.h §"Plan §42 / I-18";
 * cycle-types.h kind allocations (bringup-range 0x00B0..0x00CF cited
 * by xii_acc_mark_deltas_loaded); ADR-021 (NIH); ADR-027
 * (reproducibility / golden bytes).
 */

#ifndef III_BOOT_ACC_H
#define III_BOOT_ACC_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---------------------------------------------------------------- *
 *  Constants                                                        *
 * ---------------------------------------------------------------- */

/* Six Z₃ components per state.  Each in {0, 1, 2}. */
#define III_ACC_COMP_COUNT      6u

/* Cardinality of the state space: 3^6 = 729. */
#define III_ACC_STATE_CARD      729u

/* In-memory bitmap layout: 12 × uint64_t = 768 bits ≥ 729.  This
 * matches CONSTITUTIONAL/include/acc.h's XII_ACC_Z3_BITMAP_WORDS so
 * the boot bitmap can be `memcpy`'d directly into the runtime's
 * g_xii_acc_admitted_z3_bitmap. */
#define III_ACC_Z3_BITMAP_WORDS 12u

/* Canonical SERIALIZED bitmap byte length used for hashing /
 * golden-bytes / over-the-wire transport.
 *
 * = ceil(729 / 8) = 92 bytes  (NOT 91; ceiling, not floor).
 *
 * Within byte 91 (the 92nd byte), only the low (729 - 8*91) = 1 bit is
 * meaningful; the upper 7 bits MUST be zero in the canonical form.
 * This is what iii_acc_canonical_bytes() emits, and it is what
 * iii_acc_bitmap_fingerprint() / SHA-256 are computed over.
 *
 * The 4 trailing bytes that exist in the in-memory 96-byte (12×u64)
 * representation but NOT in the canonical 92-byte form are NEVER
 * hashed and MUST NOT be relied on by consumers. */
#define III_ACC_BITMAP_CANON_BYTES 92u

/* Confirmation of the canonical index encoding.  Defined as a
 * documentation token — not a feature flag. */
#define III_ACC_INDEX_IS_BIG_ENDIAN_TRIT 1
/*  idx = ((((comp[0]*3 + comp[1])*3 + comp[2])*3 + comp[3])*3
 *           + comp[4])*3 + comp[5]
 *  i.e. comp[0] is the MOST significant trit.  This matches the
 *  runtime mirror at CONSTITUTIONAL/include/acc.h:77-85; deviating
 *  from it would silently desynchronise the boot bitmap from the
 *  installed runtime ceiling. */

/* ---------------------------------------------------------------- *
 *  Stable error codes                                               *
 *                                                                   *
 *  Numeric values are part of the ABI; once shipped they MUST NOT   *
 *  be renumbered.                                                   *
 * ---------------------------------------------------------------- */
typedef enum {
    III_ACC_OK                 =  0,
    III_ACC_E_INVALID_TRIT     = -1, /* component value not in {0,1,2}    */
    III_ACC_E_OUT_OF_RANGE     = -2, /* index ≥ 729 or comp index ≥ 6     */
    III_ACC_E_NULL             = -3, /* required pointer was NULL          */
    III_ACC_E_BITMAP_LOCKED    = -4, /* mutation attempt after iii_acc_seal */
    III_ACC_E_NOT_SEALED       = -5, /* self-check requested before seal    */
    III_ACC_E_SELF_CHECK_FAIL  = -6  /* fingerprint mismatch vs sealed     */
} iii_acc_status_t;

/* ---------------------------------------------------------------- *
 *  State type                                                       *
 * ---------------------------------------------------------------- */

typedef struct {
    uint32_t comp[III_ACC_COMP_COUNT];   /* each in {0, 1, 2} = Z₃ */
} iii_acc_state_t;

/* ---------------------------------------------------------------- *
 *  Inline composition + canonical encoding                          *
 *                                                                   *
 *  Kept inline (and identical in shape to the runtime mirror) so    *
 *  that boot-time code paying for a function call is the exception, *
 *  not the rule.                                                    *
 * ---------------------------------------------------------------- */

/* Z₃ addition LUT.  9-entry table; replaces (a+b)%3 with a single
 * load.  Worth it for two reasons:
 *   (1) trivially proof-checkable (the table is the spec);
 *   (2) on small uarchs avoids the modulo idiom entirely.
 * Defined in acc.c; declared here so the inline composer can use it. */
extern const uint8_t g_iii_acc_z3_add_lut[9];

static inline void iii_acc_compose(iii_acc_state_t *out,
                                   const iii_acc_state_t *a,
                                   const iii_acc_state_t *b)
{
    for (unsigned i = 0; i < III_ACC_COMP_COUNT; i++) {
        const uint32_t ai = a->comp[i];
        const uint32_t bi = b->comp[i];
        /* LUT path is valid iff inputs are in-range; for adversarial
         * inputs we fall back to the branchless mod-3 form so that
         * malformed states never index out of the table. */
        if (ai < 3u && bi < 3u) {
            out->comp[i] = g_iii_acc_z3_add_lut[ai * 3u + bi];
        } else {
            const uint32_t s = (ai % 3u) + (bi % 3u);
            out->comp[i] = (s >= 3u) ? (s - 3u) : s;
        }
    }
}

/* Canonical state index 0..728.  See III_ACC_INDEX_IS_BIG_ENDIAN_TRIT
 * above for the byte-exact contract.  Returned as u16 — sufficient,
 * since the codomain is [0, 729). */
static inline uint16_t iii_acc_state_to_z3_index(const iii_acc_state_t *s)
{
    uint32_t idx = 0u;
    for (unsigned i = 0; i < III_ACC_COMP_COUNT; i++) {
        idx = idx * 3u + (s->comp[i] % 3u);
    }
    return (uint16_t)idx;
}

/* Inverse: decompose a canonical index back into trit components.
 * Useful for audit hooks and golden-bytes diffing.  Returns
 * III_ACC_E_OUT_OF_RANGE if idx ≥ 729. */
iii_acc_status_t iii_acc_index_to_state(uint16_t idx, iii_acc_state_t *out);

/* ---------------------------------------------------------------- *
 *  Bitmap mutation                                                  *
 * ---------------------------------------------------------------- */

/* Initialise the admitted bitmap to bootstrap-permissive (all 729
 * bits set; the high 39 bits of the 768-bit window cleared).  The
 * caller (codegen / sema) narrows the bitmap by zeroing inadmissible
 * indices once the ceiling is computed.  Resets the seal. */
void iii_acc_init_permissive(void);

/* Set / clear / test a single bit in the bitmap.  The mutators return
 * a status; the test returns 0/1 (and 0 for out-of-range, matching
 * the runtime mirror's tolerant semantics). */
iii_acc_status_t iii_acc_admit_index(uint32_t idx);   /* 0..728 */
iii_acc_status_t iii_acc_deny_index (uint32_t idx);
int              iii_acc_is_admitted_index(uint32_t idx);

/* ---------------------------------------------------------------- *
 *  Admission queries (dual API)                                     *
 *                                                                   *
 *  Documented invariant: for any well-formed state s,               *
 *      iii_acc_admit_state(s)                                       *
 *   == iii_acc_admit_vector(s->comp)                                *
 *   == iii_acc_is_admitted_index(iii_acc_state_to_z3_index(s)).     *
 * ---------------------------------------------------------------- */
int iii_acc_admit_state (const iii_acc_state_t *s);
int iii_acc_admit_vector(const uint32_t comp[III_ACC_COMP_COUNT]);

/* Backward-compatible aliases for the original surface. */
int iii_acc_admitted        (const iii_acc_state_t *s);
int iii_acc_compose_admitted(const iii_acc_state_t *a,
                             const iii_acc_state_t *b);

/* ---------------------------------------------------------------- *
 *  Diagnostics                                                      *
 * ---------------------------------------------------------------- */

/* Exact popcount of admitted states over the canonical 729-bit
 * window.  Bits beyond index 728 are masked off and never
 * contribute.  Codomain: [0, 729]. */
uint32_t iii_acc_count_admitted(void);

/* Emit the canonical 92-byte serialized form into `out`.  This is
 * the ONLY supported persistent representation.  Trailing 7 bits of
 * byte 91 are zeroed.  Returns III_ACC_E_NULL if out is NULL. */
iii_acc_status_t iii_acc_canonical_bytes(uint8_t out[III_ACC_BITMAP_CANON_BYTES]);

/* Deterministic 64-bit fingerprint (FNV-1a) over the canonical
 * 92-byte form.  Cheap; suitable for inner-loop self-check.
 * Content-only — no time / pointer / pid input. */
uint64_t iii_acc_bitmap_fingerprint(void);

/* SHA-256 (32 bytes) of the canonical 92-byte form.  Used as the
 * witness for ceiling-installation provenance and golden-bytes
 * tests.  Implementation is internal (acc.c) — strict NIH, libc-only,
 * portable byte-oriented. */
iii_acc_status_t iii_acc_bitmap_sha256(uint8_t out[32]);

/* ---------------------------------------------------------------- *
 *  Audit hook                                                       *
 *                                                                   *
 *  Off by default.  When set, invoked on every operation that       *
 *  CHANGES a bit in the bitmap (admit / deny that flips a value).   *
 *  No-op operations (writing the same value) are NOT reported, to   *
 *  keep the audit stream a true delta log.                          *
 *                                                                   *
 *  The hook itself MUST be deterministic for ADR-027 compliance —   *
 *  callers are responsible for not committing nondeterministic      *
 *  data through it.                                                 *
 * ---------------------------------------------------------------- */

typedef enum {
    III_ACC_AUDIT_ADMIT = 1, /* prior 0 → new 1 */
    III_ACC_AUDIT_DENY  = 2  /* prior 1 → new 0 */
} iii_acc_audit_kind_t;

typedef void (*iii_acc_audit_fn)(uint16_t cycle_kind,
                                 uint16_t state_index,
                                 uint8_t  prior_bit,
                                 uint8_t  new_bit,
                                 iii_acc_audit_kind_t kind,
                                 void    *ctx);

/* The cycle_kind tag attributed to subsequent mutations until the
 * next call.  Initialised to 0 (untagged).  This is a thread-local
 * concept morally, but Stage-0 is single-threaded so a global is
 * acceptable. */
void iii_acc_set_audit_cycle_kind(uint16_t cycle_kind);

/* Install (or clear, with fn=NULL) the audit sink. */
void iii_acc_set_audit_sink(iii_acc_audit_fn fn, void *ctx);

/* ---------------------------------------------------------------- *
 *  Seal / lock                                                      *
 *                                                                   *
 *  Post-ceiling-install, callers freeze the bitmap.  Subsequent     *
 *  admit / deny attempts return III_ACC_E_BITMAP_LOCKED and do NOT  *
 *  invoke the audit sink (no event = no change).                    *
 * ---------------------------------------------------------------- */

/* Seal the bitmap.  Records the current SHA-256 internally for use
 * by iii_acc_self_check().  Subsequent seals are idempotent (re-record
 * fingerprint of current state — but only if the bitmap is in fact
 * unchanged; otherwise returns III_ACC_E_BITMAP_LOCKED, since the
 * lock has already prevented all changes). */
iii_acc_status_t iii_acc_seal(void);

/* Whether the bitmap is currently sealed. */
int iii_acc_is_sealed(void);

/* Recompute the SHA-256 of the canonical bitmap and compare against
 * the value recorded at seal time.  Returns III_ACC_OK on match,
 * III_ACC_E_NOT_SEALED if seal was never called,
 * III_ACC_E_SELF_CHECK_FAIL on mismatch.  Pure invariant gate. */
iii_acc_status_t iii_acc_self_check(void);

/* ---------------------------------------------------------------- *
 *  Hexad decode                                                     *
 * ---------------------------------------------------------------- */

/* Decode a 12-bit hexad (per CONSTITUTIONAL/include/safety-class.h
 * packing) into an ACC state.  Storage code → Z₃:
 *   NEG  (0) → 2  (mod-3 representative of -1)
 *   ZERO (1) → 0
 *   POS  (2) → 1
 *   INVALID (3) → 0  (canary already caught upstream).
 *
 * This encoding is identical to xii_acc_state_t.comp[] semantics at
 * CONSTITUTIONAL/include/acc.h:28-31. */
void iii_acc_state_from_hexad(uint16_t hexad, iii_acc_state_t *out);

/* ---------------------------------------------------------------- *
 *  Layout parity (III_ACC_PARITY_NOTE)                              *
 *                                                                   *
 *  Boot-side iii_acc_state_t:                                       *
 *    offset 0  : uint32_t comp[6]   (24 bytes)                      *
 *    sizeof    : 24                                                 *
 *                                                                   *
 *  Runtime xii_acc_state_t (CONSTITUTIONAL/include/acc.h:46-51):    *
 *    offset 0  : uint32_t comp[6]   (24 bytes)                      *
 *    offset 24 : uint32_t _pad[2]   ( 8 bytes)                      *
 *    sizeof    : 32  (and __aligned(32) for AVX-256 single-load)    *
 *                                                                   *
 *  The first 24 bytes (the comp[] prefix) are byte-identical, and   *
 *  index encoding / composition match exactly.  Boot deliberately   *
 *  omits the AVX padding because Stage-0 has no AVX hot path and    *
 *  carrying it would inflate every constexpr table by 33%.          *
 *                                                                   *
 *  Bitmap layout — IDENTICAL between boot and runtime:              *
 *    12 × uint64_t (little-endian on every supported target),       *
 *    bit i is admitted iff (word[i/64] >> (i%64)) & 1.              *
 *  The boot bitmap can therefore be installed verbatim into         *
 *  runtime g_xii_acc_admitted_z3_bitmap via memcpy.                 *
 * ---------------------------------------------------------------- */

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_ACC_H */
