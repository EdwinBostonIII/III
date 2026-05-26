/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\hexad_check.h
 *
 * III Stage-0 Hexad Admission Bitmap (xii_asym_reach6) — public interface.
 *
 * Purpose: implement the asymmetric-ternary representability theorem of
 * III-HEXAD.md §3 + §4 as a deterministic, byte-canonical bitmap and
 * provide trit/hexad arithmetic that the rest of the BOOT pipeline
 * (sema, sid, proof, codegen) consults.
 *
 * Bitmap parity contract:
 *   This module's 144-byte bitmap is byte-for-byte identical to the
 *   runtime mirror produced by TYPES/src/hexad.c::bitmap_init() — the
 *   default rule is "every hexad in [0,728] admitted, then clear the
 *   six PFS bricking hexads, then zero the padding bits past 728".
 *   iii_hexad_bitmap_mhash() therefore returns the same SHA-256 as
 *   the runtime's iii_hexad_bitmap_hash() at startup.  This is what
 *   lets a witness emitted by an iiis-0 compile and a witness emitted
 *   by the future Stage-1+ runtime carry the same closure-root bytes
 *   in the bitmap-mhash slot.
 *
 * Trit encoding (matches TYPES/types_hexad.h::iii_trit_t):
 *     NEG  = 0
 *     ZERO = 1
 *     POS  = 2
 *
 *   This is also exactly the AST encoding (iii_ast_trit_t in ast.h),
 *   so AST-trit → hexad-pillar-trit is a no-op cast as long as we
 *   reject III_TRIT_AST_INVALID (=3) at the boundary.
 *
 * Packed encoding (matches TYPES/src/hexad.c::iii_hexad_pack):
 *     packed = sum_{p=0..5} pillar[p] * 3^p
 *
 *   This is ternary base-3 packing with pillar[0] as the LEAST
 *   significant digit (NOT base-2 bitfields with 2 bits per pillar).
 *   The codomain is [0, 728] = 729 distinct hexads.  The HEXAD
 *   library's u16 hexad ABI uses the same convention.
 *
 * Composition (per III-HEXAD §2.4 + TYPES/src/hexad.c::iii_trit_compose):
 *     ZERO ⊙ x  =  x          (ZERO is identity)
 *     x ⊙ ZERO  =  x
 *     NEG ⊙ x   =  NEG        (NEG dominates everything)
 *     x ⊙ NEG   =  NEG
 *     POS ⊙ POS =  POS
 *
 *   Note: this is a SIMPLIFIED rule compared to the spec's
 *   pillar-position-aware AND-on-P1..P4 + OR-on-P5..P6 rule.  The
 *   simplified rule matches what TYPES/src/hexad.c ships with
 *   today; the BOOT mirror tracks the runtime exactly so the
 *   composed hexad of any cycle is the same in boot and in runtime.
 *
 *   The SPEC-CORRECT pillar-position-aware rule already exists in
 *   HEXAD/src/hexad_algebra.c (iii_trit_and = NEG-dominant for P1..P4
 *   structural pillars; iii_trit_or = POS-dominant for P5..P6 epistemic
 *   pillars).  Unifying BOOT + TYPES onto that spec-correct rule — and
 *   landing the canonical compose in the live STDLIB module
 *   omnia/hexad.iii — is RITCHIE Convergence Stage 8.1 (a closure-root
 *   rotation event; see DOCS/CONVERGENCE-AUDIT.md).  Until Stage 8.1,
 *   boot and runtime intentionally share the simplified rule so their
 *   composed hexads stay bit-identical.
 *
 * Strict NIH (ADR-021): only stdlib + III BOOT headers.  No external
 * crypto or ternary library.  Hand-rolled SHA-256 lives in main.c and
 * is reused by linking; an internal re-implementation here would risk
 * divergence and is therefore avoided.  Bitmap-hash is exposed as
 * iii_hexad_bitmap_mhash() — the implementation in hexad_check.c uses
 * its own compact SHA-256 (private static, byte-canonical) to keep this
 * TU strictly self-contained for cross-TU compilation order
 * insensitivity (per build_iiis0.sh's deterministic-enumeration policy).
 */

#ifndef III_BOOT_HEXAD_CHECK_H
#define III_BOOT_HEXAD_CHECK_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "ast.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Constants (parity with TYPES/types_hexad.h) ────────────────── */

#define III_HEXAD_PILLAR_COUNT      6u
#define III_HEXAD_BITMAP_SLOTS      729u    /* 3^6 */
#define III_HEXAD_BITMAP_BYTES      144u    /* 1152-bit reservation; 92 used */

/* Trit values (matches both AST and TYPES library). */
#define III_HEXAD_TRIT_NEG          0u
#define III_HEXAD_TRIT_ZERO         1u
#define III_HEXAD_TRIT_POS          2u
#define III_HEXAD_TRIT_INVALID      3u    /* sentinel; never appears in pack */

/* The six PFS bricking-class operations.  Their hexads are explicitly
 * cleared in the bitmap; the iii_hexad_packed_admitted() query returns
 * false for any of them.  Numeric values are stable wire ids
 * (parallel to TYPES/types_hexad.h::iii_brick_t). */
typedef enum {
    III_BRICK_CAPSULE_UPDATE      = 0,
    III_BRICK_MICROCODE_LOAD      = 1,
    III_BRICK_BOOTORDER_SET       = 2,
    III_BRICK_REAL_NVRAM_WRITE    = 3,
    III_BRICK_ME_PSP_MAILBOX      = 4,
    III_BRICK_SMRAM_WRITE         = 5,
    III_BRICK__COUNT              = 6
} iii_brick_t;

/* ─── Lifecycle ─────────────────────────────────────────────────── */

/* Initialise the static 144-byte bitmap.  Idempotent: subsequent calls
 * are no-ops.  Call sites in main.c invoke this once before sema runs;
 * direct callers (sid, proof, codegen) may re-invoke without cost. */
void iii_hexad_check_init(void);

/* Whether iii_hexad_check_init has been invoked since process start. */
bool iii_hexad_check_is_init(void);

/* ─── Admission queries ─────────────────────────────────────────── */

/* True iff the packed hexad is in [0, 728] AND its bitmap bit is set
 * AND it is not one of the six PFS bricking hexads.  False for any
 * out-of-range input.  Implicitly invokes iii_hexad_check_init(). */
bool iii_hexad_packed_admitted(uint16_t packed);

/* True iff the six pillar trits compose to an admitted hexad.  Any
 * pillar that is III_HEXAD_TRIT_INVALID or out-of-range causes the
 * query to return false. */
bool iii_hexad_pillars_admitted(const uint8_t pillars[6]);

/* ─── Construction / inspection ─────────────────────────────────── */

/* Pack six pillar trits (NEG/ZERO/POS = 0/1/2) into the canonical
 * ternary packing (matches TYPES/src/hexad.c::iii_hexad_pack).  Out-of-
 * range or INVALID pillar produces 0xFFFFu (a sentinel that fails the
 * admitted() check and the [0,728] range bound). */
uint16_t iii_hexad_pack_pillars(const uint8_t pillars[6]);

/* Inverse: decompose a packed value into six pillars (LSB first).
 * Inputs >= 729 fill pillars with III_HEXAD_TRIT_INVALID. */
void iii_hexad_unpack_pillars(uint16_t packed, uint8_t out_pillars[6]);

/* Read a single pillar's trit from a packed hexad.  Returns
 * III_HEXAD_TRIT_INVALID if pillar_index >= 6 or packed >= 729. */
uint8_t iii_hexad_pillar(uint16_t packed, unsigned pillar_index);

/* AST-trit → hexad-pillar-trit converter (handles the III_TRIT_AST_*
 * encoding and rejects III_TRIT_AST_INVALID).  Used by sema and sid
 * when consuming III_AST_EXPR_HEXAD / III_AST_PAT_HEXAD payloads. */
uint16_t iii_hexad_pack_from_ast_trits(const iii_ast_trit_t trits[6]);

/* Reverse: hexad → six AST trits (with INVALID sentinel for out-of-
 * range inputs).  Used by codegen for hexad pretty-printing. */
void iii_hexad_unpack_to_ast_trits(uint16_t packed, iii_ast_trit_t out[6]);

/* ─── Composition ───────────────────────────────────────────────── */

/* Pillarwise asymmetric composition (mirror of
 * TYPES/src/hexad.c::iii_trit_compose + iii_hexad_compose).
 * Returns 0xFFFFu if either input is out of range. */
uint16_t iii_hexad_compose_packed(uint16_t a, uint16_t b);

/* Negation: swap NEG ↔ POS, leave ZERO (mirror of
 * TYPES/src/hexad.c::iii_trit_neg).  Used by SID's inverse-of-inverse
 * round-trip check. */
uint16_t iii_hexad_neg_packed(uint16_t packed);

/* Active negation: §3.5 of III-TYPES — flip pillars 1..4 only,
 * preserve pillars 0 and 5 (mirror of
 * TYPES/src/hexad.c::iii_hexad_neg).  Used by Möbius-pair validity
 * checks downstream. */
uint16_t iii_hexad_active_neg_packed(uint16_t packed);

/* ─── PFS table ─────────────────────────────────────────────────── */

/* Return the canonical packed hexad for the named bricking-class
 * operation.  Out-of-range input returns 0xFFFFu. */
uint16_t iii_hexad_brick_packed(iii_brick_t which);

/* Static-rdata name string for a brick id ("capsule_update", etc.). */
const char *iii_hexad_brick_name(iii_brick_t which);

/* ─── Witness / introspection ───────────────────────────────────── */

/* Copy the canonical 144-byte bitmap into `out`.  Idempotent;
 * iii_hexad_check_init is invoked implicitly. */
void iii_hexad_canonical_bytes(uint8_t out[III_HEXAD_BITMAP_BYTES]);

/* SHA-256 over the canonical 144-byte bitmap.  Stable across runs;
 * suitable for closure-root inclusion.  Byte-identical to the runtime
 * mirror (TYPES/src/hexad.c::iii_hexad_bitmap_hash). */
void iii_hexad_bitmap_mhash(uint8_t out[32]);

/* Convenience: count of admitted hexads (= 729 minus the six
 * cleared bricks = 723 in the canonical bitmap). */
uint32_t iii_hexad_count_admitted(void);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_HEXAD_CHECK_H */
