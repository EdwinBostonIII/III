#!/usr/bin/env bash
# COMPILER/BOOT/gen_bar_layout.sh
#
# KATABASIS GPU BAR address-map generator (plan 6.9 / FR-9 / FR-7).  Single
# source of truth = iii_bar_layout.def.  Regenerates the AUTO-GENERATED bound
# constants (KBAR_<region>_LO/_HI) + the region classifier
# (katabasis_bar_region) in STDLIB/iii/katabasis/bar_layout.iii, so the verified
# AD103 BAR windows and their F9/CoprocDispatch write typing cannot drift from
# the silicon (plan 0.2 / the 0.6 allowlist).
#
# Mirrors COMPILER/BOOT/gen_svm_layout.sh / gen_census.sh / gen_cycle_family.sh:
#   --check  : regenerate into a temp, byte-compare, modify NOTHING, exit 3 on
#              drift (wired into build_stdlib.sh as a pre-build gate).
# In BOTH modes it asserts each KBAR_REGION_<region> enum constant exists.
# Deterministic: LC_ALL=C, SOURCE_DATE_EPOCH=0, ascending enumeration.
set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEF="$SCRIPT_DIR/iii_bar_layout.def"
BAR_III="$III_ROOT/STDLIB/iii/katabasis/bar_layout.iii"

[[ -f "$DEF"     ]] || { echo "$0: missing $DEF" >&2;     exit 1; }
[[ -f "$BAR_III" ]] || { echo "$0: missing $BAR_III" >&2; exit 1; }

CHECK_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# Parse .def into parallel arrays; skip # comments + blank lines.
REGIONS=(); LOS=(); HIS=()
set +u
while IFS=$' \t' read -r region lo hi rest; do
    case "$region" in '#'*) continue ;; esac
    [[ -z "$region" ]] && continue
    REGIONS+=("$region"); LOS+=("$lo"); HIS+=("$hi")
done < <(grep -vE '^[[:space:]]*(#|$)' "$DEF")
set -u
N=${#REGIONS[@]}
echo "[gen_bar_layout] read $N BAR windows from $DEF"
(( N > 0 )) || { echo "$0: no BAR windows in $DEF" >&2; exit 2; }

# Assert each region-id enum constant exists (hand-written, above the block).
for ((i=0; i<N; i++)); do
    if ! grep -qE "const[[:space:]]+KBAR_REGION_${REGIONS[i]}[[:space:]]*:" "$BAR_III"; then
        echo "$0: bar_layout.iii missing constant KBAR_REGION_${REGIONS[i]} named by iii_bar_layout.def" >&2
        exit 2
    fi
done

# Emit the generated block: bound constants + the ascending classifier cascade.
GEN_BLOCK="$(mktemp)"
{
    printf '/* GENERATED FROM iii_bar_layout.def by gen_bar_layout.sh -- DO NOT EDIT BY HAND. */\n'
    printf '/* Verified BAR bounds (ascending; plan 0.2 / the 0.6 allowlist).  u64 unsigned. */\n'
    for ((i=0; i<N; i++)); do
        printf 'const KBAR_%s_LO : u64 = %s\n' "${REGIONS[i]}" "${LOS[i]}"
        printf 'const KBAR_%s_HI : u64 = %s\n' "${REGIONS[i]}" "${HIS[i]}"
    done
    printf '\n'
    printf '/* Classify a physical address into its GPU BAR (or NONE).  Ascending cascade\n'
    printf ' * using only unsigned `<` (the signed-compare trap is signed-only; the BAR\n'
    printf ' * bounds are monotone ascending so a `<` cascade is exact). */\n'
    printf 'fn katabasis_bar_region(phys: u64) -> u32 @export {\n'
    printf '    let p : u64 = phys\n'
    prev=""
    for ((i=0; i<N; i++)); do
        r="${REGIONS[i]}"
        if [[ -z "$prev" ]]; then
            locmt="below $r: host RAM / low MMIO"
        else
            locmt="gap: $prev end .. $r start"
        fi
        printf '    if p < KBAR_%s_LO { return KBAR_REGION_NONE }   /* %s */\n' "$r" "$locmt"
        printf '    if p < KBAR_%s_HI { return KBAR_REGION_%s }   /* %s */\n' "$r" "$r" "$r"
        prev="$r"
    done
    printf '    return KBAR_REGION_NONE   /* above %s */\n' "$prev"
    printf '}\n'
} > "$GEN_BLOCK"

BEGIN_MARK='/* === BEGIN AUTO-GENERATED FROM iii_bar_layout.def === */'
END_MARK='/* === END AUTO-GENERATED FROM iii_bar_layout.def === */'
for mark in "$BEGIN_MARK" "$END_MARK"; do
    if ! grep -qF "$mark" "$BAR_III"; then
        echo "$0: $BAR_III missing sentinel: $mark" >&2
        rm -f "$GEN_BLOCK"; exit 2
    fi
done

NEW="$(mktemp)"
awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v blk="$GEN_BLOCK" '
    BEGIN { ins = 0 }
    {
        if (index($0, b) > 0) {
            print
            while ((getline line < blk) > 0) print line
            close(blk)
            ins = 1
            next
        }
        if (index($0, e) > 0) { ins = 0 }
        if (!ins) print
    }
' "$BAR_III" > "$NEW"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if ! cmp -s "$BAR_III" "$NEW"; then
        echo "[gen_bar_layout] DRIFT: $BAR_III diverged from iii_bar_layout.def" >&2
        rm -f "$GEN_BLOCK" "$NEW"; exit 3
    fi
    echo "[gen_bar_layout] check: $BAR_III current"
else
    if ! cmp -s "$BAR_III" "$NEW"; then
        cp "$NEW" "$BAR_III"
        echo "[gen_bar_layout] rewrote $BAR_III"
    else
        echo "[gen_bar_layout] $BAR_III already current"
    fi
fi
rm -f "$GEN_BLOCK" "$NEW"
echo "[gen_bar_layout] OK ($N BAR windows)"
