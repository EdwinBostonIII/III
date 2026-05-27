#!/usr/bin/env bash
# C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\gen_compositions.sh
#
# III Composition table generator. Single source of truth =
# iii_compositions.def. This script regenerates two artifacts from
# the .def, structurally eliminating any possibility of drift:
#
#   1. COMPILER/BOOT/iii_compositions.h       (consumed by cg_r3.c)
#   2. STDLIB/iii/omnia/prespec.iii           (auto-replaced section
#                                              between the sentinels:
#                                                /* === BEGIN AUTO-
#                                                   GENERATED ... */
#                                                /* === END AUTO-
#                                                   GENERATED ... */)
#
# Reproducibility: deterministic given identical .def + same
# environment (LC_ALL=C, SOURCE_DATE_EPOCH=0, sorted enumeration).

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DEF="$SCRIPT_DIR/iii_compositions.def"
OUT_H="$SCRIPT_DIR/iii_compositions.h"
PRESPEC_III="$III_ROOT/STDLIB/iii/omnia/prespec.iii"

[[ -f "$DEF"         ]] || { echo "$0: missing $DEF" >&2;         exit 1; }
[[ -f "$PRESPEC_III" ]] || { echo "$0: missing $PRESPEC_III" >&2; exit 1; }

# --check (Stage 3.7 drift gate): regenerate into temps, byte-compare to
# the on-disk iii_compositions.h + prespec.iii, modify NOTHING, and exit 3
# on drift.  This catches a hand-edit to prespec.iii (or the .h) that
# diverged from the single source of truth iii_compositions.def, instead
# of silently overwriting it.  Wired into build_stdlib.sh as a pre-build
# gate so a drifted prespec fails the build.
CHECK_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# Parse .def into 6 parallel arrays. Override IFS for the per-line
# split so whitespace (space + tab) tokenises the fields.
SEQS=(); PRIMS=(); HEXADS=(); KS=(); LITS=(); FNS=()
set +u
while IFS=$' \t' read -r seq prim hexad k lit fn rest; do
    # strip trailing comment from final field if any
    case "$seq" in '#'*) continue ;; esac
    [[ -z "$seq" ]] && continue
    SEQS+=("$seq")
    PRIMS+=("$prim")
    HEXADS+=("$hexad")
    KS+=("$k")
    LITS+=("$lit")
    FNS+=("$fn")
done < <(grep -vE '^[[:space:]]*(#|$)' "$DEF")
set -u

N=${#SEQS[@]}
echo "[gen_compositions] read $N entries from $DEF"

# ─── Emit C header for cg_r3 ─────────────────────────────────────────
OUT_H_TMP="$(mktemp)"
{
    cat <<'EOF'
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\iii_compositions.h
 *
 * GENERATED FROM iii_compositions.def. DO NOT EDIT BY HAND.
 * Re-generate via: bash COMPILER/BOOT/gen_compositions.sh
 *
 * Single source of truth for the III composition table. cg_r3.c
 * consumes this header for its Partial Evaluator narrow table.
 * prespec.iii's runtime bulk-registration is regenerated from the
 * SAME .def. Drift between cg_r3 and prespec is structurally
 * impossible: both come from iii_compositions.def.
 */
#ifndef III_COMPOSITIONS_H
#define III_COMPOSITIONS_H

#include <stdint.h>

typedef struct {
    uint32_t    seq_idx;
    uint8_t     primitive_id;
    uint8_t     hexad_bag;
    uint32_t    k_value;
    uint64_t    literal_form_id;
    const char *dispatch_fp_name;
} iii_composition_entry_t;

static const iii_composition_entry_t III_COMPOSITION_TABLE[] = {
EOF
    for ((i=0; i<N; i++)); do
        printf '    { %su, %su, %su, %su, %suLL, "%s" },\n' \
            "${SEQS[i]}" "${PRIMS[i]}" "${HEXADS[i]}" "${KS[i]}" "${LITS[i]}" "${FNS[i]}"
    done
    cat <<'EOF'
};

#define III_COMPOSITION_TABLE_LEN \
    (sizeof(III_COMPOSITION_TABLE) / sizeof(III_COMPOSITION_TABLE[0]))

/* Synthetic composition_hash encoding (must match prespec.iii). */
static inline uint64_t iii_composition_synth_hash(uint32_t seq_idx,
                                                  uint8_t  primitive_id,
                                                  uint8_t  hexad_bag)
{
    uint64_t s = (uint64_t)seq_idx & 0xFFFFu;
    uint64_t p = ((uint64_t)primitive_id & 0xFFu) << 16;
    uint64_t h = ((uint64_t)hexad_bag    & 0xFFu) << 24;
    uint64_t m = 0x494E5450ULL << 32;
    return s | p | h | m;
}

#endif /* III_COMPOSITIONS_H */
EOF
} > "$OUT_H_TMP"
if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if ! cmp -s "$OUT_H_TMP" "$OUT_H"; then
        echo "[gen_compositions] DRIFT: $OUT_H differs from iii_compositions.def-generated output" >&2
        rm -f "$OUT_H_TMP"; exit 3
    fi
    rm -f "$OUT_H_TMP"
    echo "[gen_compositions] check: $OUT_H current"
else
    cp "$OUT_H_TMP" "$OUT_H"; rm -f "$OUT_H_TMP"
    echo "[gen_compositions] wrote $OUT_H"
fi

# ─── Generate the iii block to inject into prespec.iii ───────────────
GEN_BLOCK="$(mktemp)"
{
    printf '    /* SEQ_IDX %s entries follow; encoding mirrors\n' "$N"
    printf '     * iii_composition_synth_hash() in iii_compositions.h. */\n'
    for ((i=0; i<N; i++)); do
        seq="${SEQS[i]}"
        prim="${PRIMS[i]}"
        hex="${HEXADS[i]}"
        k="${KS[i]}"
        fn="${FNS[i]}"
        printf '    {\n'
        printf '        let h : u64 = _prespec_synth_hash(%su32, %su8, %su8)\n' "$seq" "$prim" "$hex"
        printf '        let m : u64 = prespec_pack_meta(%su8, %su8, %su32)\n' "$prim" "$hex" "$k"
        printf '        let f : u64 = (&%s) as u64\n' "$fn"
        printf '        if prespec_register(h, m, f, 0u32) == PRESPEC_OK { count = count + 1u32 }\n'
        printf '    }\n'
    done
} > "$GEN_BLOCK"

# ─── Generate the externs block (module-scope, before fn body) ───────
GEN_EXTERNS="$(mktemp)"
{
    declare -A SEEN_FN
    for ((i=0; i<N; i++)); do
        fn="${FNS[i]}"
        if [[ -z "${SEEN_FN[$fn]+x}" ]]; then
            SEEN_FN[$fn]=1
            printf 'extern @abi(c-msvc-x64) fn %s(a: u64, b: u64, c: u64, d: u64) -> u64 from "_unused.iii"\n' "$fn"
        fi
    done
} > "$GEN_EXTERNS"

# ─── Inject into prespec.iii between sentinels (TWO sentinel pairs) ──
BEGIN_REG_MARK='/* === BEGIN AUTO-GENERATED FROM iii_compositions.def === */'
END_REG_MARK='/* === END AUTO-GENERATED FROM iii_compositions.def === */'
BEGIN_EXT_MARK='/* === BEGIN AUTO-GENERATED EXTERNS FROM iii_compositions.def === */'
END_EXT_MARK='/* === END AUTO-GENERATED EXTERNS FROM iii_compositions.def === */'

for mark in "$BEGIN_REG_MARK" "$END_REG_MARK" "$BEGIN_EXT_MARK" "$END_EXT_MARK"; do
    if ! grep -qF "$mark" "$PRESPEC_III"; then
        echo "$0: $PRESPEC_III is missing sentinel: $mark" >&2
        rm -f "$GEN_BLOCK" "$GEN_EXTERNS"
        exit 2
    fi
done

NEW_PRESPEC="$(mktemp)"
awk -v breg="$BEGIN_REG_MARK" -v ereg="$END_REG_MARK" \
    -v bext="$BEGIN_EXT_MARK" -v eext="$END_EXT_MARK" \
    -v reg_block="$GEN_BLOCK" -v ext_block="$GEN_EXTERNS" '
    BEGIN { in_reg = 0; in_ext = 0 }
    {
        if (index($0, breg) > 0) {
            print
            while ((getline line < reg_block) > 0) print line
            close(reg_block)
            in_reg = 1
            next
        }
        if (index($0, bext) > 0) {
            print
            while ((getline line < ext_block) > 0) print line
            close(ext_block)
            in_ext = 1
            next
        }
        if (index($0, ereg) > 0) { in_reg = 0 }
        if (index($0, eext) > 0) { in_ext = 0 }
        if (!in_reg && !in_ext) print
    }
' "$PRESPEC_III" > "$NEW_PRESPEC"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    # Stage 3.7 drift gate: prespec.iii's auto-generated section must
    # byte-match the .def output.  Drift = a hand-edit; fail the build.
    if ! cmp -s "$PRESPEC_III" "$NEW_PRESPEC"; then
        echo "[gen_compositions] DRIFT: $PRESPEC_III diverged from iii_compositions.def (hand-edit in the auto-generated section?)" >&2
        rm -f "$GEN_BLOCK" "$GEN_EXTERNS" "$NEW_PRESPEC"
        exit 3
    fi
    echo "[gen_compositions] check: $PRESPEC_III current"
else
    # Atomic replace — only if content changed (preserves mtime when stable).
    if ! cmp -s "$PRESPEC_III" "$NEW_PRESPEC"; then
        cp "$NEW_PRESPEC" "$PRESPEC_III"
        echo "[gen_compositions] rewrote $PRESPEC_III"
    else
        echo "[gen_compositions] $PRESPEC_III already current"
    fi
fi

# ─── Generate the PE composition table (.iii, for iii_cg_pe_iiis1.iii) ──
# Mirrors III_COMPOSITION_TABLE: parallel PE_PRIM[u8]/PE_LIT[u64]/PE_NOFF[u32]
# arrays + a NUL-terminated PE_NAMES blob. The .iii PE returns
# &PE_NAMES + PE_NOFF[i] as the dispatch-name pointer (byte-identical names
# to the C table → byte-identical cg_r3 codegen).
PE_III="$SCRIPT_DIR/iii_cg_pe_iiis1.iii"
BEGIN_PE_MARK='/* === BEGIN AUTO-GENERATED PE TABLE FROM iii_compositions.def === */'
END_PE_MARK='/* === END AUTO-GENERATED PE TABLE FROM iii_compositions.def === */'

if [[ -f "$PE_III" ]]; then
    for mark in "$BEGIN_PE_MARK" "$END_PE_MARK"; do
        if ! grep -qF "$mark" "$PE_III"; then
            echo "$0: $PE_III is missing sentinel: $mark" >&2
            rm -f "$GEN_BLOCK" "$GEN_EXTERNS" "$NEW_PRESPEC"
            exit 2
        fi
    done

    GEN_PE="$(mktemp)"
    {
        prim_vals=""; lit_vals=""; noff_vals=""; names_bytes=""
        sep_p=""; sep_l=""; sep_o=""; sep_n=""
        off=0
        for ((i=0; i<N; i++)); do
            prim_vals+="${sep_p}${PRIMS[i]}u8";  sep_p=", "
            lit_vals+="${sep_l}${LITS[i]}u64";   sep_l=", "
            noff_vals+="${sep_o}${off}u32";      sep_o=", "
            fn="${FNS[i]}"
            len=${#fn}
            for ((c=0; c<len; c++)); do
                ch="${fn:c:1}"
                printf -v code '%d' "'$ch"
                names_bytes+="${sep_n}${code}u8"; sep_n=", "
                off=$((off+1))
            done
            names_bytes+="${sep_n}0u8"; sep_n=", "
            off=$((off+1))
        done
        total=$off
        printf '/* === BEGIN AUTO-GENERATED PE TABLE FROM iii_compositions.def === */\n'
        printf 'const PE_N : u64 = %su64\n' "$N"
        printf 'var PE_PRIM : [u8; %s] = [%s]\n' "$N" "$prim_vals"
        printf 'var PE_LIT : [u64; %s] = [%s]\n' "$N" "$lit_vals"
        printf 'var PE_NOFF : [u32; %s] = [%s]\n' "$N" "$noff_vals"
        printf 'var PE_NAMES : [u8; %s] = [%s]\n' "$total" "$names_bytes"
        printf '/* === END AUTO-GENERATED PE TABLE FROM iii_compositions.def === */\n'
    } > "$GEN_PE"

    NEW_PE="$(mktemp)"
    awk -v bpe="$BEGIN_PE_MARK" -v epe="$END_PE_MARK" -v pe_block="$GEN_PE" '
        BEGIN { in_pe = 0 }
        {
            if (index($0, bpe) > 0) {
                while ((getline line < pe_block) > 0) print line
                close(pe_block)
                in_pe = 1
                next
            }
            if (index($0, epe) > 0) { in_pe = 0; next }
            if (!in_pe) print
        }
    ' "$PE_III" > "$NEW_PE"

    if [[ "$CHECK_ONLY" -eq 1 ]]; then
        if ! cmp -s "$PE_III" "$NEW_PE"; then
            echo "[gen_compositions] DRIFT: $PE_III diverged from iii_compositions.def (hand-edit in the auto-generated PE table?)" >&2
            rm -f "$GEN_BLOCK" "$GEN_EXTERNS" "$NEW_PRESPEC" "$GEN_PE" "$NEW_PE"
            exit 3
        fi
        echo "[gen_compositions] check: $PE_III current"
    else
        if ! cmp -s "$PE_III" "$NEW_PE"; then
            cp "$NEW_PE" "$PE_III"
            echo "[gen_compositions] rewrote $PE_III"
        else
            echo "[gen_compositions] $PE_III already current"
        fi
    fi
    rm -f "$GEN_PE" "$NEW_PE"
fi

rm -f "$GEN_BLOCK" "$GEN_EXTERNS" "$NEW_PRESPEC"
echo "[gen_compositions] OK ($N entries)"
