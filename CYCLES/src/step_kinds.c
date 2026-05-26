/* ============================================================================
 * III-CYCLES — step_kinds.c
 *
 * §5.3 step_kind band table.  Bands are inclusive [lo, hi] ranges; the
 * complete allocation occupies 0x0000..0x01FF.  iii_step_kind_band() does a
 * branchless range search over the table.
 * ============================================================================
 */
#include "cycles_internal.h"

typedef struct band_entry {
    uint16_t              lo;
    uint16_t              hi;
    iii_step_kind_band_t  band;
    const char           *name;
} band_entry_t;

static const band_entry_t g_bands[] = {
    { 0x0000, 0x000F, III_BAND_RESERVED_BOOT,          "RESERVED_BOOT" },
    { 0x0010, 0x002F, III_BAND_IRPD_PRIVILEGED_WRITE,  "IRPD_PRIVILEGED_WRITE" },
    { 0x0030, 0x004F, III_BAND_IRPD_PRIVILEGED_READ,   "IRPD_PRIVILEGED_READ" },
    { 0x0050, 0x006F, III_BAND_CYCLE_LIFECYCLE,        "CYCLE_LIFECYCLE" },
    { 0x0070, 0x007F, III_BAND_WAVEFRONT,              "WAVEFRONT" },
    { 0x0080, 0x009F, III_BAND_SANCTUM,                "SANCTUM" },
    { 0x00A0, 0x00BF, III_BAND_TRINITY,                "TRINITY" },
    { 0x00C0, 0x00CF, III_BAND_CEILING,                "CEILING" },
    { 0x00D0, 0x00EF, III_BAND_FEDERATION,             "FEDERATION" },
    { 0x00F0, 0x00FF, III_BAND_DRTM,                   "DRTM" },
    { 0x0100, 0x010F, III_BAND_VDF,                    "VDF" },
    { 0x0110, 0x012F, III_BAND_OBSERVATORY,            "OBSERVATORY" },
    { 0x0130, 0x014F, III_BAND_CATALYST,               "CATALYST" },
    { 0x0150, 0x015F, III_BAND_NARRATIVE,              "NARRATIVE" },
    { 0x0160, 0x017F, III_BAND_COGNITIVE,              "COGNITIVE" },
    { 0x0180, 0x018F, III_BAND_PFS,                    "PFS" },
    { 0x0190, 0x01AF, III_BAND_FEDERATION_RESERVED,    "FEDERATION_RESERVED" },
    { 0x01B0, 0x01C6, III_BAND_USER_RESERVED,          "USER_RESERVED" },
    { 0x01C7, 0x01CF, III_BAND_MNEME_CATALYST_PROMOTE, "MNEME_CATALYST_PROMOTE" },
    { 0x01D0, 0x01FF, III_BAND_RESERVED_FUTURE,        "RESERVED_FUTURE" }
};

#define G_BAND_COUNT  (sizeof(g_bands)/sizeof(g_bands[0]))

iii_step_kind_band_t iii_step_kind_band(uint16_t step_kind) {
    for (size_t i = 0; i < G_BAND_COUNT; ++i) {
        if (step_kind >= g_bands[i].lo && step_kind <= g_bands[i].hi) {
            return g_bands[i].band;
        }
    }
    return III_BAND_UNKNOWN;
}

const char *iii_step_kind_band_name(iii_step_kind_band_t band) {
    for (size_t i = 0; i < G_BAND_COUNT; ++i) {
        if (g_bands[i].band == band) return g_bands[i].name;
    }
    return "UNKNOWN";
}

void iii_step_kind_band_range(iii_step_kind_band_t band,
                              uint16_t *out_lo,
                              uint16_t *out_hi)
{
    for (size_t i = 0; i < G_BAND_COUNT; ++i) {
        if (g_bands[i].band == band) {
            if (out_lo) *out_lo = g_bands[i].lo;
            if (out_hi) *out_hi = g_bands[i].hi;
            return;
        }
    }
    if (out_lo) *out_lo = 0;
    if (out_hi) *out_hi = 0;
}
