#include "iii/nfc.h"

bool iii_nfc_is_forbidden_combining(uint32_t cp) {
    /* Combining diaeresis is the only mark that decomposes a lexicon codepoint
     * (möbius's ö = U+006F + U+0308).  Reject it anywhere it follows an ASCII
     * 'o' or 'O' in identifier-like positions (caller checks context). */
    return cp == 0x0308u;
}

bool iii_nfc_decomposed_is_lexicon(uint32_t base, uint32_t combiner) {
    if (combiner == 0x0308u) {
        if (base == 0x006Fu /* o */ || base == 0x004Fu /* O */) return true;
    }
    return false;
}
