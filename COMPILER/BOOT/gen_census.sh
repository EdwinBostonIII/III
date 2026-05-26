#!/usr/bin/env bash
# COMPILER/BOOT/gen_census.sh
#
# KATABASIS Silicon Census fact-vector generator (plan 6.9 / FR-9).  Single
# source of truth = iii_census.def.  Regenerates the AUTO-GENERATED fact
# assignments inside katabasis_census_init() in
# STDLIB/iii/katabasis/census.iii, so the verified silicon facts (plan 0.1-0.2)
# structurally cannot drift from their single source.
#
# Mirrors COMPILER/BOOT/gen_svm_layout.sh (the established .def pattern):
#   --check  : regenerate into a temp, byte-compare, modify NOTHING, exit 3 on
#              drift (wired into build_stdlib.sh as a pre-build gate).
# In BOTH modes it also asserts the three count-dependent constants in
# census.iii equal N / 8N, so adding a fact here without updating the array
# dimension / fact_count / hash length is a build-stopping error (never a
# silent buffer overflow).
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
DEF="$SCRIPT_DIR/iii_census.def"
CEN_III="$III_ROOT/STDLIB/iii/katabasis/census.iii"

[[ -f "$DEF"     ]] || { echo "$0: missing $DEF" >&2;     exit 1; }
[[ -f "$CEN_III" ]] || { echo "$0: missing $CEN_III" >&2; exit 1; }

CHECK_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# Parse .def into parallel arrays (idx, value, comment-rest); skip # + blank.
IDXS=(); VALS=(); CMTS=()
set +u
while IFS=$' \t' read -r idx val rest; do
    case "$idx" in '#'*) continue ;; esac
    [[ -z "$idx" ]] && continue
    IDXS+=("$idx"); VALS+=("$val"); CMTS+=("$rest")
done < <(grep -vE '^[[:space:]]*(#|$)' "$DEF")
set -u
N=${#IDXS[@]}
echo "[gen_census] read $N facts from $DEF"
(( N > 0 )) || { echo "$0: no facts in $DEF" >&2; exit 2; }

# Facts must be a dense ascending vector 0..N-1 (the hash is over a flat array).
for ((i=0; i<N; i++)); do
    if [[ "${IDXS[i]}" != "$i" ]]; then
        echo "$0: fact idx not dense/ascending at row $i: expected $i, got '${IDXS[i]}'" >&2
        exit 2
    fi
done

# Alignment widths for a clean canonical block (index token [Nu64] + value).
IDXW=0; VALW=0
for ((i=0; i<N; i++)); do
    tok="[${IDXS[i]}u64]"
    (( ${#tok} > IDXW )) && IDXW=${#tok}
    (( ${#VALS[i]} > VALW )) && VALW=${#VALS[i]}
done

# Emit the generated block (the N fact assignments).
GEN_BLOCK="$(mktemp)"
{
    printf '    /* GENERATED FROM iii_census.def by gen_census.sh -- DO NOT EDIT BY HAND. */\n'
    for ((i=0; i<N; i++)); do
        printf '    KCEN_FACTS%-*s = %-*s  /* %s */\n' \
               "$IDXW" "[${IDXS[i]}u64]" "$VALW" "${VALS[i]}" "${CMTS[i]}"
    done
} > "$GEN_BLOCK"

BEGIN_MARK='/* === BEGIN AUTO-GENERATED FROM iii_census.def === */'
END_MARK='/* === END AUTO-GENERATED FROM iii_census.def === */'
for mark in "$BEGIN_MARK" "$END_MARK"; do
    if ! grep -qF "$mark" "$CEN_III"; then
        echo "$0: $CEN_III missing sentinel: $mark" >&2
        rm -f "$GEN_BLOCK"; exit 2
    fi
done

# Count-coupling guard: structural constants must equal N (array dim, fact_count)
# and 8N (hash byte length).  A mismatch fails BOTH --check and regenerate.
HASHLEN=$(( N * 8 ))
chk_const() { # $1 human label, $2 ERE that MUST match a line in census.iii
    if ! grep -qE "$2" "$CEN_III"; then
        echo "$0: census.iii $1 not consistent with $N facts (expected /$2/)" >&2
        rm -f "$GEN_BLOCK"; exit 2
    fi
}
chk_const "array dimension"  "var[[:space:]]+KCEN_FACTS[[:space:]]*:[[:space:]]*\[u64;[[:space:]]*${N}\]"
chk_const "fact_count"       "katabasis_census_fact_count\(\)[^{]*\{[[:space:]]*return[[:space:]]+${N}u64"
chk_const "hash byte-length" "sha256_oneshot\(&KCEN_FACTS as \*u8, ${HASHLEN}u64,"

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
' "$CEN_III" > "$NEW"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if ! cmp -s "$CEN_III" "$NEW"; then
        echo "[gen_census] DRIFT: $CEN_III diverged from iii_census.def" >&2
        rm -f "$GEN_BLOCK" "$NEW"; exit 3
    fi
    echo "[gen_census] check: $CEN_III current"
else
    if ! cmp -s "$CEN_III" "$NEW"; then
        cp "$NEW" "$CEN_III"
        echo "[gen_census] rewrote $CEN_III"
    else
        echo "[gen_census] $CEN_III already current"
    fi
fi
rm -f "$GEN_BLOCK" "$NEW"
echo "[gen_census] OK ($N facts, hash length ${HASHLEN})"
