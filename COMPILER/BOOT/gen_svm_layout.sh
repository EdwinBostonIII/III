#!/usr/bin/env bash
# COMPILER/BOOT/gen_svm_layout.sh
#
# KATABASIS SVM-layout generator (plan 6.9).  Single source of truth =
# iii_svm_layout.def.  Regenerates the AUTO-GENERATED section of
# STDLIB/iii/katabasis/svm_layout.iii -- the region classifier
# (katabasis_svm_region) + the per-offset hexad (katabasis_svm_region_hexad) --
# so the §4.7 safety typing structurally cannot drift from the §0.4 layout.
#
# Mirrors COMPILER/BOOT/gen_compositions.sh (the established .def pattern):
#   --check  : regenerate into a temp, byte-compare, modify NOTHING, exit 3 on
#              drift (wired into build_stdlib.sh as a pre-build gate).
# Deterministic: LC_ALL=C, SOURCE_DATE_EPOCH=0, ordered enumeration.
set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEF="$SCRIPT_DIR/iii_svm_layout.def"
SVM_III="$III_ROOT/STDLIB/iii/katabasis/svm_layout.iii"

[[ -f "$DEF"     ]] || { echo "$0: missing $DEF" >&2;     exit 1; }
[[ -f "$SVM_III" ]] || { echo "$0: missing $SVM_III" >&2; exit 1; }

CHECK_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# Parse .def into parallel arrays (skip # comments + blank lines).
IDS=(); NAMES=(); LOS=(); HIS=(); HEXS=()
set +u
while IFS=$' \t' read -r id name lo hi hex rest; do
    case "$id" in '#'*) continue ;; esac
    [[ -z "$id" ]] && continue
    IDS+=("$id"); NAMES+=("$name"); LOS+=("$lo"); HIS+=("$hi"); HEXS+=("$hex")
done < <(grep -vE '^[[:space:]]*(#|$)' "$DEF")
set -u
N=${#IDS[@]}
echo "[gen_svm_layout] read $N regions from $DEF"

# Emit the generated .iii block (region classifier + per-offset hexad).
GEN_BLOCK="$(mktemp)"
{
    printf '/* GENERATED FROM iii_svm_layout.def -- DO NOT EDIT BY HAND.\n'
    printf ' * Regenerate: bash COMPILER/BOOT/gen_svm_layout.sh\n'
    printf ' * The SVM-offset region classifier + per-offset hexad, single-sourced so\n'
    printf ' * the plan-4.7 safety typing cannot drift from the plan-0.4 layout. */\n'
    printf 'fn katabasis_svm_region(offset: u32) -> u32 @export {\n'
    printf '    let o : u32 = offset\n'
    for ((i=0; i<N; i++)); do
        printf '    if o < %su32 { return KSVM_REGION_%s }\n' "${HIS[i]}" "${NAMES[i]}"
    done
    printf '    return KSVM_REGION_OOB\n'
    printf '}\n'
    printf '\n'
    printf 'fn katabasis_svm_region_hexad(offset: u32) -> u16 @export {\n'
    printf '    let o : u32 = offset\n'
    for ((i=0; i<N; i++)); do
        printf '    if o < %su32 { return %su16 }\n' "${HIS[i]}" "${HEXS[i]}"
    done
    printf '    return 324u16\n'
    printf '}\n'
} > "$GEN_BLOCK"

BEGIN_MARK='/* === BEGIN AUTO-GENERATED FROM iii_svm_layout.def === */'
END_MARK='/* === END AUTO-GENERATED FROM iii_svm_layout.def === */'
for mark in "$BEGIN_MARK" "$END_MARK"; do
    if ! grep -qF "$mark" "$SVM_III"; then
        echo "$0: $SVM_III missing sentinel: $mark" >&2
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
' "$SVM_III" > "$NEW"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if ! cmp -s "$SVM_III" "$NEW"; then
        echo "[gen_svm_layout] DRIFT: $SVM_III diverged from iii_svm_layout.def" >&2
        rm -f "$GEN_BLOCK" "$NEW"; exit 3
    fi
    echo "[gen_svm_layout] check: $SVM_III current"
else
    if ! cmp -s "$SVM_III" "$NEW"; then
        cp "$NEW" "$SVM_III"
        echo "[gen_svm_layout] rewrote $SVM_III"
    else
        echo "[gen_svm_layout] $SVM_III already current"
    fi
fi
rm -f "$GEN_BLOCK" "$NEW"
echo "[gen_svm_layout] OK ($N regions)"
