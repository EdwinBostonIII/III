/* III-STDLIB inventory database. */
#include "iii/stdlib.h"
#include <string.h>
#include <stdio.h>

/* ----------------------------------------------------------------------------
 * Names
 * ---------------------------------------------------------------------------- */
const char *iii_kw_category_name(iii_kw_category_t c) {
    switch (c) {
        case III_KW_FUNDAMENTAL:    return "fundamental";
        case III_KW_ARCHITECTURAL:  return "architectural";
        case III_KW_CONCURRENCY:    return "concurrency";
        case III_KW_QUERY:          return "query";
        case III_KW_COGNITIVE:      return "cognitive";
        case III_KW_PROVENANCE:     return "provenance";
        case III_KW_CRYPTOGRAPHIC:  return "cryptographic";
        case III_KW_DISTRIBUTED:    return "distributed";
        case III_KW_GOVERNANCE:     return "governance";
        case III_KW_SAFETY:         return "safety";
        case III_KW_ESCAPE:         return "escape";
        case III_KW_INTEROP:        return "interop";
        case III_KW_META:           return "meta";
        default:                    return "unknown";
    }
}

const char *iii_symbol_status_name(iii_symbol_status_t s) {
    switch (s) {
        case III_SYM_KEEP:      return "KEEP";
        case III_SYM_KEEP_NOTE: return "KEEP-NOTE";
        case III_SYM_REVIEW:    return "REVIEW";
        case III_SYM_FLAG:      return "FLAG";
        case III_SYM_RESOLVED:  return "RESOLVED";
        case III_SYM_OPEN:      return "OPEN";
        case III_SYM_BY_DESIGN: return "BY-DESIGN";
        case III_SYM_CLARIFY:   return "CLARIFY";
        default:                return "unknown";
    }
}

/* ----------------------------------------------------------------------------
 * Keywords (47) — verbatim from III-LEXICON.md §1, table at §2.1.
 * ---------------------------------------------------------------------------- */
static const iii_keyword_t kKeywords[III_STDLIB_KEYWORD_COUNT] = {
    /* 1-6 fundamental */
    {"witness",          III_KW_FUNDAMENTAL,   true,  "III-CYCLES.md §4.1"},
    {"glyph",            III_KW_FUNDAMENTAL,   true,  "III-LEXICON.md §4.1.1"},
    {"cycle",            III_KW_FUNDAMENTAL,   true,  "III-CYCLES.md §1, §2"},
    {"hexad",            III_KW_FUNDAMENTAL,   true,  "III-HEXAD.md §1, §2"},
    {"cap",              III_KW_FUNDAMENTAL,   true,  "III-TYPES.md §7"},
    {"phase",            III_KW_FUNDAMENTAL,   true,  "III-PHASES.md §1"},
    /* 7-14 architectural */
    {"sanctum",          III_KW_ARCHITECTURAL, true,  "III-SANCTUM.md"},
    {"drtm",             III_KW_ARCHITECTURAL, true,  "III-SANCTUM.md §4"},
    {"observatory",      III_KW_ARCHITECTURAL, true,  "III-CATALYST.md §3"},
    {"catalyst",         III_KW_ARCHITECTURAL, true,  "III-CATALYST.md"},
    {"möbius",           III_KW_ARCHITECTURAL, false, "III-LEXICON.md §4.1.2"},
    {"trinity",          III_KW_ARCHITECTURAL, true,  "III-TRINITY.md"},
    {"ceiling",          III_KW_ARCHITECTURAL, true,  "III-MODULES.md §5"},
    {"sid",              III_KW_ARCHITECTURAL, true,  "III-CYCLES.md §3"},
    /* 15-16 concurrency */
    {"wavefront",        III_KW_CONCURRENCY,   true,  "III-EFFECTS.md §7"},
    {"waac",             III_KW_CONCURRENCY,   true,  ""},
    /* 17-18 query */
    {"witness_stream",   III_KW_QUERY,         true,  "III-CYCLES.md §4.5"},
    {"glyph_stream",     III_KW_QUERY,         true,  ""},
    /* 19-25 cognitive */
    {"narrative",        III_KW_COGNITIVE,     true,  "III-LEXICON.md §4.1.5"},
    {"explain",          III_KW_COGNITIVE,     true,  ""},
    {"propose",          III_KW_COGNITIVE,     true,  ""},
    {"negotiate",        III_KW_COGNITIVE,     true,  ""},
    {"commit",           III_KW_COGNITIVE,     true,  ""},
    {"reflect",          III_KW_COGNITIVE,     true,  ""},
    {"uncertainty",      III_KW_COGNITIVE,     true,  ""},
    /* 26-27 provenance */
    {"epoch",            III_KW_PROVENANCE,    true,  ""},
    {"vdf",              III_KW_PROVENANCE,    true,  ""},
    /* 28-30 cryptographic */
    {"mhash",            III_KW_CRYPTOGRAPHIC, true,  ""},
    {"closure",          III_KW_CRYPTOGRAPHIC, true,  ""},
    {"anchor",           III_KW_CRYPTOGRAPHIC, true,  ""},
    /* 31 distributed */
    {"federation",       III_KW_DISTRIBUTED,   true,  "III-FEDERATION.md"},
    /* 32 governance */
    {"amend",            III_KW_GOVERNANCE,    true,  ""},
    /* 33-35 safety */
    {"bricking",         III_KW_SAFETY,        true,  "III-HEXAD.md §4"},
    {"irreversible",     III_KW_SAFETY,        true,  ""},
    {"pure",             III_KW_SAFETY,        true,  ""},
    /* 36 escape */
    {"metal",            III_KW_ESCAPE,        true,  ""},
    /* 37 interop */
    {"extern",           III_KW_INTEROP,       true,  "III-ABI.md"},
    /* 38-47 meta */
    {"self_host",        III_KW_META,          true,  ""},
    {"promote",          III_KW_META,          true,  ""},
    {"observe",          III_KW_META,          true,  ""},
    {"coherence",        III_KW_META,          true,  ""},
    {"inverse",          III_KW_META,          true,  ""},
    {"manifest",         III_KW_META,          true,  ""},
    {"glyph_bound",      III_KW_META,          true,  ""},
    {"mobius_candidate", III_KW_META,          true,  ""},
    {"schema",           III_KW_META,          true,  ""},
    {"module",           III_KW_META,          true,  ""}
};

const iii_keyword_t *iii_stdlib_keyword_at(unsigned i) {
    return (i < III_STDLIB_KEYWORD_COUNT) ? &kKeywords[i] : NULL;
}

const iii_keyword_t *iii_stdlib_keyword_lookup(const char *name) {
    if (!name) return NULL;
    for (unsigned i = 0; i < III_STDLIB_KEYWORD_COUNT; ++i) {
        if (strcmp(kKeywords[i].name, name) == 0) return &kKeywords[i];
    }
    return NULL;
}

/* ----------------------------------------------------------------------------
 * Modifiers (19)
 * ---------------------------------------------------------------------------- */
static const iii_modifier_t kModifiers[III_STDLIB_MODIFIER_COUNT] = {
    {"@ring",                    "@ring(ring_set)",                       "type, fn, cycle, module, import, metal block"},
    {"@hexad",                   "@hexad(NAME)",                          "type, cycle, fn, wavefront"},
    {"@tier",                    "@tier(transient/host_file/...)",        "type, cycle, value"},
    {"@epoch",                   "@epoch(N)",                             "type, value"},
    {"@cap",                     "@cap(perm, range)",                     "type"},
    {"@sanctum_only",            "(no args)",                             "fn, cycle, type"},
    {"@irreversible",            "(no args)",                             "cycle"},
    {"@pure",                    "(no args)",                             "fn, cycle"},
    {"@closure",                 "@closure(mhash_lit)",                   "module, use"},
    {"@replicates",              "@replicates(local/broadcast/...)",      "fn, cycle"},
    {"@plan_anchor",             "@plan_anchor(IDENT)",                   "cycle, module"},
    {"@admits_caps",             "@admits_caps(IDENT, ...)",              "cycle"},
    {"@prerequisites",           "@prerequisites(IDENT, ...)",            "cycle"},
    {"@candidate_for_promotion", "(no args)",                             "mobius_candidate"},
    {"@mobius_coherence",        "@mobius_coherence(coherence_expr)",     "cycle, wavefront"},
    {"@witness_elide",           "(no args; legal only on @pure)",        "cycle, fn"},
    {"@hot_path",                "(no args)",                             "cycle, fn"},
    {"@chronos_bypass",          "(no args; operator-only cap)",          "cycle, fn"},
    {"@epoch_bridge",            "(no args)",                             "fn, cycle"}
};

const iii_modifier_t *iii_stdlib_modifier_at(unsigned i) {
    return (i < III_STDLIB_MODIFIER_COUNT) ? &kModifiers[i] : NULL;
}

const iii_modifier_t *iii_stdlib_modifier_lookup(const char *name) {
    if (!name) return NULL;
    for (unsigned i = 0; i < III_STDLIB_MODIFIER_COUNT; ++i) {
        if (strcmp(kModifiers[i].name, name) == 0) return &kModifiers[i];
    }
    return NULL;
}

/* ----------------------------------------------------------------------------
 * Operators (23)
 * ---------------------------------------------------------------------------- */
static const iii_operator_t kOperators[III_STDLIB_OPERATOR_COUNT] = {
    {"\xE2\x9F\xB2",     "U+27F2",                  "Inverse",               11},
    {"\xE2\x8A\x95",     "U+2295",                  "Cycle Compose",          6},
    {"\xE2\x8A\x97",     "U+2297",                  "Glyph Materialize",     10},
    {"\xE2\xA7\x89",     "U+29C9",                  "Hexad Compose",          6},
    {"\xE2\x9F\x90",     "U+27D0",                  "Trinity Gate",           6},
    {"\xE2\x86\xBB",     "U+21BB",                  "Replay",                11},
    {"\xE2\x9F\xA1",     "U+27E1",                  "Witness Emit",          11},
    {"\xE2\x9F\x81",     "U+27C1",                  "Ceiling Check",          6},
    {"\xE2\xA7\x97",     "U+29D7",                  "Mobius Coherence",       3},
    {"\xE2\x9F\xB4",     "U+27F4",                  "Phase Cross",            5},
    {"\xE2\xA7\x88",     "U+29C8",                  "Cap Acquire/Release",    5},
    {"\xE2\x9F\xB5",     "U+27F5",                  "Epoch Bridge",           5},
    {"\xE2\xA7\x8A",     "U+29CA",                  "VDF Squaring",           7},
    {"\xE2\x9F\xB6",     "U+27F6",                  "Federation Replicate",   7},
    {"\xE2\xA8\x81",     "U+2A01",                  "Amendment Apply",        7},
    {"\xE2\x9F\xB2\xE2\x9F\xB2", "U+27F2 U+27F2",   "Full Inverse Replay",   11},
    {"\xE2\x8A\x9B",     "U+229B",                  "Catalyst Promote",       8},
    {"\xE2\xA7\x84",     "U+29C4",                  "Observatory Saturate",   8},
    {"\xE2\x9F\x90\xE2\x9F\x90", "U+27D0 U+27D0",   "Narrative Reflect",      9},
    {"\xE2\xA7\x87",     "U+29C7",                  "Uncertainty Query",      3},
    {"\xE2\x9F\xA1\xE2\x9F\xA1", "U+27E1 U+27E1",   "Explain",                9},
    {"\xE2\xA7\x8B",     "U+29CB",                  "Propose",                8},
    {"\xE2\x9F\xB4\xE2\x9F\xB4", "U+27F4 U+27F4",   "Negotiate",              9}
};

const iii_operator_t *iii_stdlib_operator_at(unsigned i) {
    return (i < III_STDLIB_OPERATOR_COUNT) ? &kOperators[i] : NULL;
}

const iii_operator_t *iii_stdlib_operator_lookup(const char *symbol) {
    if (!symbol) return NULL;
    for (unsigned i = 0; i < III_STDLIB_OPERATOR_COUNT; ++i) {
        if (strcmp(kOperators[i].symbol, symbol) == 0) return &kOperators[i];
    }
    return NULL;
}

/* ----------------------------------------------------------------------------
 * Punctuators (25)
 * ---------------------------------------------------------------------------- */
static const iii_punctuator_t kPunctuators[III_STDLIB_PUNCTUATOR_COUNT] = {
    {"(",  "U+0028", "Group / argument list / tuple"},
    {")",  "U+0029", "Group / argument list / tuple"},
    {"{",  "U+007B", "Block"},
    {"}",  "U+007D", "Block"},
    {"[",  "U+005B", "Index / array"},
    {"]",  "U+005D", "Index / array"},
    {"<",  "U+003C", "Generic / comparison"},
    {">",  "U+003E", "Generic / comparison"},
    {",",  "U+002C", "List separator"},
    {";",  "U+003B", "Statement separator"},
    {":",  "U+003A", "Type annotation"},
    {"::", "U+003A x2", "Path separator"},
    {".",  "U+002E", "Field/method access"},
    {"..", "U+002E x2", "Range"},
    {"=",  "U+003D", "Assignment"},
    {"==", "U+003D x2", "Equality"},
    {"!=", "U+0021 U+003D", "Inequality"},
    {"\xE2\x89\xA5", "U+2265", "Greater-or-equal"},
    {"\xE2\x89\xA4", "U+2264", "Less-or-equal"},
    {"->", "U+002D U+003E", "Function/cycle return arrow"},
    {"=>", "U+003D U+003E", "Match-arm arrow"},
    {"|",  "U+007C", "Pattern alternative; sanctum-frame binding"},
    {"_",  "U+005F", "Wildcard / unused binding"},
    {"?",  "U+003F", "Hole / metavariable"},
    {"&",  "U+0026", "Borrow / reference"}
};

const iii_punctuator_t *iii_stdlib_punctuator_at(unsigned i) {
    return (i < III_STDLIB_PUNCTUATOR_COUNT) ? &kPunctuators[i] : NULL;
}

/* ----------------------------------------------------------------------------
 * Literal forms (9)
 * ---------------------------------------------------------------------------- */
static const iii_literal_form_t kLiterals[III_STDLIB_LITERAL_FORM_COUNT] = {
    {"INT_LIT",         "dec/hex/bin/oct + suffix",      "u8..u64, i8..i64", "LEX §9.1"},
    {"MHASH_LIT",       "exactly 64 hex digits prefixed 0x", "mhash",        "LEX §9.3"},
    {"TRIT_LIT",        "NEG/ZERO/POS/Nt form",          "Trit",             "LEX §9.4"},
    {"HEXAD_LIT",       "6-tuple of trits in parens",    "Hexad",            "LEX §9.5"},
    {"Q14_LIT",         "int.frac with q/q14 suffix",    "Q14",              "LEX §9.6"},
    {"STRING_LIT",      "\"...\"",                       "string",           "LEX §9.7.1"},
    {"BYTE_STRING_LIT", "b\"...\"",                      "[u8; N]",          "LEX §9.7.2"},
    {"RAW_STRING_LIT",  "r\"...\" or r#\"...\"#",        "string (raw)",     "LEX §9.7.3"},
    {"HEX_STRING_LIT",  "h\"...\"",                      "[u8; N]",          "LEX §9.7.4"}
};

const iii_literal_form_t *iii_stdlib_literal_form_at(unsigned i) {
    return (i < III_STDLIB_LITERAL_FORM_COUNT) ? &kLiterals[i] : NULL;
}

/* ----------------------------------------------------------------------------
 * SE kinds (17)
 * ---------------------------------------------------------------------------- */
static const iii_se_kind_entry_t kSeKinds[III_STDLIB_SE_KIND_COUNT] = {
    {0x01, "MSR_WRITE",         "Model-Specific Register write"},
    {0x02, "CR_WRITE",          "Control-Register write"},
    {0x03, "NPT_ENTRY_WRITE",   "Nested Page Table entry write"},
    {0x04, "VMCB_FIELD_WRITE",  "Virtual Machine Control Block field write"},
    {0x05, "IOMMU_DTE_WORD",    "IOMMU Device Table Entry word write"},
    {0x06, "AVIC_TBL_WRITE",    "Advanced Virtual Interrupt Controller table write"},
    {0x07, "MSRPM_BIT_SET",     "MSR Permission Map bit set"},
    {0x08, "IOPM_BIT_SET",      "I/O Permission Map bit set"},
    {0x09, "PKRU_WRITE",        "Protection-Key Rights for User pages write"},
    {0x0A, "XCR0_WRITE",        "XCR0 (extended-state) write"},
    {0x0B, "CAP_ACQUIRE",       "Capability acquire"},
    {0x0C, "CAP_RELEASE",       "Capability release"},
    {0x0D, "PAGE_ALLOC",        "Physical-page allocation"},
    {0x0E, "PAGE_FREE",         "Physical-page free"},
    {0x0F, "DPC_ARM",           "Deferred-procedure-call arm"},
    {0x10, "DPC_CANCEL",        "Deferred-procedure-call cancel"},
    {0x11, "NMI_INSTALL",       "Non-Maskable Interrupt installation"}
};

const iii_se_kind_entry_t *iii_stdlib_se_kind_at(unsigned i) {
    return (i < III_STDLIB_SE_KIND_COUNT) ? &kSeKinds[i] : NULL;
}

/* ----------------------------------------------------------------------------
 * Compromise tiers (3)
 * ---------------------------------------------------------------------------- */
static const iii_compromise_tier_entry_t kTiers[III_STDLIB_COMPROMISE_TIER_COUNT] = {
    {"Compromise.LOW",    "Reversibility deferred or minor irreversibility"},
    {"Compromise.MEDIUM", "Multiple gate failures; cap-gated execution"},
    {"Compromise.HIGH",   "Critical gates failed; Trinity + cosig required"}
};

const iii_compromise_tier_entry_t *iii_stdlib_compromise_tier_at(unsigned i) {
    return (i < III_STDLIB_COMPROMISE_TIER_COUNT) ? &kTiers[i] : NULL;
}

/* ----------------------------------------------------------------------------
 * Phase / Sanctum / Trinity / Federation
 * ---------------------------------------------------------------------------- */
static const iii_phase_entry_t kPhases[III_STDLIB_PHASE_COUNT] = {
    {"R-2", "Sanctum",     0},
    {"R-1", "Hypervisor",  1},
    {"R0",  "Kernel",      2},
    {"R3",  "User",        3}
};

const iii_phase_entry_t *iii_stdlib_phase_at(unsigned i) {
    return (i < III_STDLIB_PHASE_COUNT) ? &kPhases[i] : NULL;
}

static const iii_sanctum_slot_entry_t kSlots[III_STDLIB_SANCTUM_SLOT_COUNT] = {
    {0, "INVALID",            "Structural-guard; never callable"},
    {1, "drtm_relaunch",      "DRTM relaunch + new epoch"},
    {2, "pfs_var_set",        "Phantom NVRAM variable set"},
    {3, "pfs_deny_quote",     "Deny a DRTM quote"},
    {4, "crcc_key_export",    "Export a CRCC key under sub-key"},
    {5, "phoenix_emergency",  "Emergency Phoenix bookmark + snapshot"},
    {6, "chronos_set_epoch",  "Advance witnessed-time epoch"},
    {7, "compromise_quote",   "Emit a compromise-class DRTM quote"},
    {8, "phoenix_bookmark",   "Non-emergency Phoenix bookmark"},
    {9, "compile_module",     "Stage-4 self-host compilation in Sanctum"}
};

const iii_sanctum_slot_entry_t *iii_stdlib_sanctum_slot_at(unsigned i) {
    return (i < III_STDLIB_SANCTUM_SLOT_COUNT) ? &kSlots[i] : NULL;
}

static const iii_trinity_layer_entry_t kLayers[III_STDLIB_TRINITY_LAYER_COUNT] = {
    {1, "SCBA",         "Lightweight 65,536-bit bitarray test",    1,    2},
    {2, "ACC Wall-Y",   "Composed-delta admission",               15,   40},
    {3, "Trinity Gate", "Full intent x cap x causality x sanctum",80,  300}
};

const iii_trinity_layer_entry_t *iii_stdlib_trinity_layer_at(unsigned i) {
    return (i < III_STDLIB_TRINITY_LAYER_COUNT) ? &kLayers[i] : NULL;
}

static const iii_federation_tier_entry_t kFedTiers[III_STDLIB_FEDERATION_TIER_COUNT] = {
    {"transient",      "Local only",       "1 (originating CPU)"},
    {"host_file",      "Peer pull",        "quorum-3-2"},
    {"federation",     "Broadcast",        "quorum-5-3 + fragment_replicate"},
    {"constitutional", "Full quorum",      "unanimous"}
};

const iii_federation_tier_entry_t *iii_stdlib_federation_tier_at(unsigned i) {
    return (i < III_STDLIB_FEDERATION_TIER_COUNT) ? &kFedTiers[i] : NULL;
}

/* ----------------------------------------------------------------------------
 * Conformance criteria (30)
 * ---------------------------------------------------------------------------- */
static const iii_conformance_entry_t kConf[III_STDLIB_CONFORMANCE_COUNT] = {
    {"C-1",  "Closure root computed deterministically"},
    {"C-2",  "Phase polymorphism produces N lowerings for N-ring set"},
    {"C-3",  "Cycle SID 32-step plan executes"},
    {"C-4",  "Hexad bitmap admits the canonical reachable set"},
    {"C-5",  "Sanctum exposes exactly 10 sealed slots"},
    {"C-6",  "Crypto agility: suite swap preserves chain"},
    {"C-7",  "Closure-pinned imports enforced"},
    {"C-8",  "Federation tier-gated outbound"},
    {"C-9",  "Predictive Trinity hot-path < 5 cycles"},
    {"C-10", "Epistemic escalation triggers below 0.85q"},
    {"C-11", "Ring-gated module promotion follows decision tree"},
    {"C-12", "Codegen validation runs before deployment"},
    {"C-13", "Deployment flags emitted (SAFE_APPROVED/etc)"},
    {"C-14", "Inverse replay restores prior state"},
    {"C-15", "Catalyst eight-gate promotion"},
    {"C-16", "Witness chain BCWL O(log n) replay"},
    {"C-17", "Coherence floor enforced"},
    {"C-18", "Three-layer Trinity ceiling"},
    {"C-19", "Mobius manifold remains coherent under load"},
    {"C-20", "DRTM quote chain verifies"},
    {"C-21", "Bricking forms structurally absent"},
    {"C-22", "Six PFS hexads unrepresentable"},
    {"C-23", "Wavefront commits atomically"},
    {"C-24", "Cap balance: every acquire has matching release"},
    {"C-25", "Per-CPU NUMA-local witness ring"},
    {"C-26", "Compromise tier propagation through composition"},
    {"C-27", "Federation peer authentication via DRTM-rooted key"},
    {"C-28", "Frontend hides module structure from operator"},
    {"C-29", "ZK-rollup compaction preserves audit invariants"},
    {"C-30", "Anchor cosignature on every constitutional amendment"}
};

const iii_conformance_entry_t *iii_stdlib_conformance_at(unsigned i) {
    return (i < III_STDLIB_CONFORMANCE_COUNT) ? &kConf[i] : NULL;
}

/* ----------------------------------------------------------------------------
 * R1 family
 * ---------------------------------------------------------------------------- */
static const iii_r1_family_entry_t kR1[III_STDLIB_R1_FAMILY_COUNT] = {
    {"R1.A1",  "III-LEXICON.md",     70934},
    {"R1.A2",  "III-GRAMMAR.bnf",    63475},
    {"R1.A3",  "III-TYPES.md",       51148},
    {"R1.A4",  "III-EFFECTS.md",     27068},
    {"R1.A5",  "III-CYCLES.md",      30075},
    {"R1.A6",  "III-HEXAD.md",       25432},
    {"R1.A7",  "III-PHASES.md",      23450},
    {"R1.A8",  "III-SANCTUM.md",     26509},
    {"R1.A9",  "III-TRINITY.md",     22762},
    {"R1.A10", "III-MODULES.md",     22555},
    {"R1.B1",  "III-CATALYST.md",    12415},
    {"R1.B2",  "III-FEDERATION.md",   7488},
    {"R1.B3",  "III-CONFORMANCE.md", 11623},
    {"R1.C1",  "III-ABI.md",          6017},
    {"R1.IDX", "III-INDEX.md",       11530}
};

const iii_r1_family_entry_t *iii_stdlib_r1_at(unsigned i) {
    return (i < III_STDLIB_R1_FAMILY_COUNT) ? &kR1[i] : NULL;
}

/* ----------------------------------------------------------------------------
 * Self-check
 * ---------------------------------------------------------------------------- */
bool iii_stdlib_self_check(void) {
    /* Ensure every table is fully populated. */
    if (iii_stdlib_keyword_at(III_STDLIB_KEYWORD_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_modifier_at(III_STDLIB_MODIFIER_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_operator_at(III_STDLIB_OPERATOR_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_punctuator_at(III_STDLIB_PUNCTUATOR_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_literal_form_at(III_STDLIB_LITERAL_FORM_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_se_kind_at(III_STDLIB_SE_KIND_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_phase_at(III_STDLIB_PHASE_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_sanctum_slot_at(III_STDLIB_SANCTUM_SLOT_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_trinity_layer_at(III_STDLIB_TRINITY_LAYER_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_federation_tier_at(III_STDLIB_FEDERATION_TIER_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_conformance_at(III_STDLIB_CONFORMANCE_COUNT - 1u) == NULL) return false;
    if (iii_stdlib_r1_at(III_STDLIB_R1_FAMILY_COUNT - 1u) == NULL) return false;
    return true;
}

/* ----------------------------------------------------------------------------
 * Render
 * ---------------------------------------------------------------------------- */
size_t iii_stdlib_render(char *out, size_t cap) {
    if (!out || cap == 0) return 0;
    int n = snprintf(out, cap,
        "{\"keywords\":%u,\"modifiers\":%u,\"operators\":%u,\"punctuators\":%u,"
        "\"literal_forms\":%u,\"se_kinds\":%u,\"compromise_tiers\":%u,"
        "\"phases\":%u,\"sanctum_slots\":%u,\"trinity_layers\":%u,"
        "\"federation_tiers\":%u,\"conformance\":%u,\"r1_family\":%u}",
        III_STDLIB_KEYWORD_COUNT, III_STDLIB_MODIFIER_COUNT,
        III_STDLIB_OPERATOR_COUNT, III_STDLIB_PUNCTUATOR_COUNT,
        III_STDLIB_LITERAL_FORM_COUNT, III_STDLIB_SE_KIND_COUNT,
        III_STDLIB_COMPROMISE_TIER_COUNT, III_STDLIB_PHASE_COUNT,
        III_STDLIB_SANCTUM_SLOT_COUNT, III_STDLIB_TRINITY_LAYER_COUNT,
        III_STDLIB_FEDERATION_TIER_COUNT, III_STDLIB_CONFORMANCE_COUNT,
        III_STDLIB_R1_FAMILY_COUNT);
    return (n > 0) ? (size_t)n : 0u;
}
