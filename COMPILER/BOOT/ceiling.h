/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\ceiling.h
 *
 * III Stage-0 Ceiling Membership Ledger — public interface.
 *
 * The "ceiling" is the substrate-wide whitelist of admissible cycles —
 * a 65,536-bit (8 KiB) bitmap indexed by 16-bit `cycle_kind` (per
 * witness_alloc.h's allocation policy: kinds start at
 * III_WALLOC_CYCLE_KIND_BASE = 0x0200 and grow monotonically).
 *
 * This module is the BOOT mirror of TRINITY's Layer-1 SCBA bit-test
 * (per III-TRINITY.md §1.3 / TRINITY/include/iii/trinity.h::iii_scba_*).
 * The runtime SCBA is indexed by the first 16 bits of BLAKE3 over a
 * reduction's post-state; the BOOT ceiling is indexed directly by
 * cycle_kind because at compile time we have already allocated stable
 * IDs (per witness_alloc.c) and the 1:1 cycle_kind ↔ post-state-prefix
 * mapping holds for every cycle that walloc admitted.
 *
 * ─── DETERMINISM (ADR-027) ───────────────────────────────────────────
 *
 *   The bitmap is a pure function of the sequence of
 *     iii_ceil_init_denied();
 *     iii_ceil_admit_kind(k_1);
 *     iii_ceil_admit_kind(k_2);
 *     ...
 *   No time, PID, or pointer-derived data is folded in.
 *   iii_ceil_bitmap_mhash() is SHA-256 over the canonical 8192-byte
 *   form; two iiis-0 invocations on the same source produce the same
 *   digest.
 *
 * ─── SEAL DISCIPLINE ─────────────────────────────────────────────────
 *
 *   The pipeline calls iii_ceil_init_denied() once at sema entry,
 *   admits one bit per discovered cycle as walloc completes, and
 *   then iii_ceil_seal()s the bitmap.  Post-seal, iii_ceil_admit_kind
 *   returns III_CEIL_E_SEALED and does NOT mutate.  Codegen and link
 *   query iii_ceil_admitted_kind() freely; the seal is a defense-in-
 *   depth invariant gate (parallel to iii_acc_seal in acc.h).
 *
 * Strict NIH (ADR-021): only stdlib + III BOOT headers.  No external
 * crypto.  Hand-rolled SHA-256 lives statically inside ceiling.c.
 */

#ifndef III_BOOT_CEILING_H
#define III_BOOT_CEILING_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Constants ──────────────────────────────────────────────────── */

#define III_CEIL_BITS    65536u
#define III_CEIL_BYTES   (III_CEIL_BITS / 8u)   /* 8192 bytes = 8 KiB */

/* ─── Stable error codes (ABI; never reused) ─────────────────────── */

#define III_CEIL_OK            0
#define III_CEIL_E_SEALED      1
#define III_CEIL_E_NULL_ARG    2
#define III_CEIL_E_INTERNAL    99

/* ─── Lifecycle ──────────────────────────────────────────────────── */

/* Clear the bitmap to deny-all and reset the seal.  Called once per
 * pipeline run.  Idempotent in spirit (re-calling re-zeroes), but per
 * the seal discipline only the first call before any
 * iii_ceil_admit_kind is meaningful. */
void iii_ceil_init_denied(void);

/* Admit (allow) a single cycle_kind.  Returns III_CEIL_OK on success,
 * III_CEIL_E_SEALED if the bitmap is sealed (no mutation occurred). */
int iii_ceil_admit_kind(uint16_t cycle_kind);

/* Deny (clear) a single cycle_kind.  Symmetric to admit; returns the
 * same status codes.  Used by SID's Compromise-tier rejection paths. */
int iii_ceil_deny_kind(uint16_t cycle_kind);

/* Test admission.  Returns true iff the bit is set.  Safe to call
 * before init (returns false: deny-all by default). */
bool iii_ceil_admitted_kind(uint16_t cycle_kind);

/* Seal the bitmap.  Subsequent admit/deny return III_CEIL_E_SEALED.
 * Idempotent: re-sealing returns III_CEIL_OK. */
int iii_ceil_seal(void);

/* Whether the bitmap is currently sealed. */
bool iii_ceil_is_sealed(void);

/* ─── Witness / introspection ────────────────────────────────────── */

/* Copy the canonical 8192-byte bitmap into `out`. */
void iii_ceil_canonical_bytes(uint8_t out[III_CEIL_BYTES]);

/* SHA-256 over the canonical 8192-byte bitmap.  Stable across runs;
 * suitable for closure-root inclusion. */
void iii_ceil_bitmap_mhash(uint8_t out[32]);

/* Convenience: count of currently-admitted cycle_kinds. */
uint32_t iii_ceil_count_admitted(void);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_CEILING_H */
