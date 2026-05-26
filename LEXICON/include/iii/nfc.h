/* NFC verification — minimal scope per spec.
 * The only non-ASCII identifier-like keyword is `möbius` and the only operators
 * are precomposed math symbols.  We reject decomposed forms: specifically the
 * decomposed möbius `o` U+006F U+0308.  This module exposes a checker that
 * scans the decoded codepoint stream for any base+combining-mark sequence that
 * has a precomposed NFC form within the allowed lexicon set.
 */
#ifndef III_NFC_H
#define III_NFC_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Returns true if cp is a combining mark we forbid in identifier-like position
 * (currently only U+0308 combining diaeresis is checked since that is the
 * only decomposition path leading to a lexicon codepoint). */
bool iii_nfc_is_forbidden_combining(uint32_t cp);

/* Returns true if (base, combiner) would compose to a single NFC codepoint
 * that the lexicon recognises (used to reject decomposed möbius). */
bool iii_nfc_decomposed_is_lexicon(uint32_t base, uint32_t combiner);

#ifdef __cplusplus
}
#endif
#endif
