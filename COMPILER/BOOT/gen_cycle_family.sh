#!/usr/bin/env bash
# COMPILER/BOOT/gen_cycle_family.sh
#
# KATABASIS cycle-family taxonomy generator (plan 6.9 / FR-9).  Single source of
# truth = iii_cycle_family.def.  Regenerates the AUTO-GENERATED taxonomy
# functions in STDLIB/iii/katabasis/cycle_family.iii (the family validity, the
# safety class, the SID inverse kind, and the dangerous-trio predicate) so the
# plan-3.0 nine-family taxonomy the Gate dispatch reads cannot drift.
#
# Mirrors COMPILER/BOOT/gen_svm_layout.sh / gen_census.sh:
#   --check  : regenerate into a temp, byte-compare, modify NOTHING, exit 3 on
#              drift (wired into build_stdlib.sh as a pre-build gate).
# In BOTH modes it asserts every enum constant a row names (KCF_F<id>_<name>,
# KCF_CLASS_<class>, KCF_INV_<inverse>) is defined in cycle_family.iii, so a
# .def/enum mismatch fails the build instead of producing a bad cascade.
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
DEF="$SCRIPT_DIR/iii_cycle_family.def"
CF_III="$III_ROOT/STDLIB/iii/katabasis/cycle_family.iii"

[[ -f "$DEF"    ]] || { echo "$0: missing $DEF" >&2;    exit 1; }
[[ -f "$CF_III" ]] || { echo "$0: missing $CF_III" >&2; exit 1; }

CHECK_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# Parse .def into parallel arrays; skip # comments + blank lines.
IDS=(); NAMES=(); CLASSES=(); INVS=(); DANGS=()
set +u
while IFS=$' \t' read -r id name class inv dang rest; do
    case "$id" in '#'*) continue ;; esac
    [[ -z "$id" ]] && continue
    IDS+=("$id"); NAMES+=("$name"); CLASSES+=("$class"); INVS+=("$inv"); DANGS+=("$dang")
done < <(grep -vE '^[[:space:]]*(#|$)' "$DEF")
set -u
N=${#IDS[@]}
echo "[gen_cycle_family] read $N families from $DEF"
(( N > 0 )) || { echo "$0: no families in $DEF" >&2; exit 2; }

# Families must be a dense ascending vector 1..N.
for ((i=0; i<N; i++)); do
    want=$(( i + 1 ))
    if [[ "${IDS[i]}" != "$want" ]]; then
        echo "$0: family id not dense/ascending at row $i: expected $want, got '${IDS[i]}'" >&2
        exit 2
    fi
done

# Family constant names, and the alignment width (so `{` aligns like the hand
# table did).  Also assert every referenced enum constant exists.
CN=()
NAMEW=0
for ((i=0; i<N; i++)); do
    cn="KCF_F${IDS[i]}_${NAMES[i]}"
    CN+=("$cn")
    (( ${#cn} > NAMEW )) && NAMEW=${#cn}
done
chk_const() { # $1 = constant name that MUST be defined in cycle_family.iii
    if ! grep -qE "const[[:space:]]+$1[[:space:]]*:" "$CF_III"; then
        echo "$0: cycle_family.iii missing constant '$1' named by iii_cycle_family.def" >&2
        exit 2
    fi
}
for ((i=0; i<N; i++)); do
    chk_const "${CN[i]}"
    chk_const "KCF_CLASS_${CLASSES[i]}"
    chk_const "KCF_INV_${INVS[i]}"
done

# Emit the generated block: the four taxonomy functions.
GEN_BLOCK="$(mktemp)"
{
    printf '/* GENERATED FROM iii_cycle_family.def by gen_cycle_family.sh -- DO NOT EDIT BY HAND. */\n'

    printf '/* A family id is valid iff it is one of the nine (1..9). */\n'
    printf 'fn katabasis_cycle_family_valid(family: u32) -> u8 @export {\n'
    printf '    let f : u32 = family\n'
    for ((i=0; i<N; i++)); do
        printf '    if f == %-*s { return 1u8 }\n' "$NAMEW" "${CN[i]}"
    done
    printf '    return 0u8\n'
    printf '}\n'
    printf '\n'

    printf '/* The safety class of a family (plan 3.0). */\n'
    printf 'fn katabasis_cycle_family_class(family: u32) -> u32 @export {\n'
    printf '    let f : u32 = family\n'
    for ((i=0; i<N; i++)); do
        printf '    if f == %-*s { return KCF_CLASS_%s }\n' "$NAMEW" "${CN[i]}" "${CLASSES[i]}"
    done
    printf '    return KCF_CLASS_NONE\n'
    printf '}\n'
    printf '\n'

    printf '/* The SID inverse kind of a family (plan 3.0). */\n'
    printf 'fn katabasis_cycle_family_inverse(family: u32) -> u32 @export {\n'
    printf '    let f : u32 = family\n'
    for ((i=0; i<N; i++)); do
        printf '    if f == %-*s { return KCF_INV_%s }\n' "$NAMEW" "${CN[i]}" "${INVS[i]}"
    done
    printf '    return KCF_INV_NONE\n'
    printf '}\n'
    printf '\n'

    printf '/* The three dangerous families (F2 WriteMetal, F5 Descend, F9 CoprocDispatch)\n'
    printf ' * share the one safe-write law (plan 3.9): any such cycle whose host effect is\n'
    printf ' * unprovable is rehearsed in a throwaway guest first.  1 = dangerous. */\n'
    printf 'fn katabasis_cycle_is_dangerous(family: u32) -> u8 @export {\n'
    printf '    let f : u32 = family\n'
    for ((i=0; i<N; i++)); do
        if [[ "${DANGS[i]}" == "1" ]]; then
            printf '    if f == %-*s { return 1u8 }\n' "$NAMEW" "${CN[i]}"
        fi
    done
    printf '    return 0u8\n'
    printf '}\n'
} > "$GEN_BLOCK"

BEGIN_MARK='/* === BEGIN AUTO-GENERATED FROM iii_cycle_family.def === */'
END_MARK='/* === END AUTO-GENERATED FROM iii_cycle_family.def === */'
for mark in "$BEGIN_MARK" "$END_MARK"; do
    if ! grep -qF "$mark" "$CF_III"; then
        echo "$0: $CF_III missing sentinel: $mark" >&2
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
' "$CF_III" > "$NEW"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if ! cmp -s "$CF_III" "$NEW"; then
        echo "[gen_cycle_family] DRIFT: $CF_III diverged from iii_cycle_family.def" >&2
        rm -f "$GEN_BLOCK" "$NEW"; exit 3
    fi
    echo "[gen_cycle_family] check: $CF_III current"
else
    if ! cmp -s "$CF_III" "$NEW"; then
        cp "$NEW" "$CF_III"
        echo "[gen_cycle_family] rewrote $CF_III"
    else
        echo "[gen_cycle_family] $CF_III already current"
    fi
fi
rm -f "$GEN_BLOCK" "$NEW"
echo "[gen_cycle_family] OK ($N families)"
