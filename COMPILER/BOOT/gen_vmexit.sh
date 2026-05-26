#!/usr/bin/env bash
# COMPILER/BOOT/gen_vmexit.sh
#
# KATABASIS VMEXIT-set taxonomy generator (plan 6.9 / FR-9 / plan 4.8).  Single
# source of truth = iii_vmexit.def.  Regenerates the AUTO-GENERATED taxonomy
# functions in STDLIB/iii/katabasis/vmexit.iii (intercepted / handling / inverse)
# so the minimal-VMEXIT-set the III Floor handles cannot drift.  The fail-closed
# catch-all tails are the module's safety contract, emitted for any unmodelled
# exit (not table rows).
#
# Mirrors gen_cycle_family.sh:
#   --check  : regenerate into a temp, byte-compare, modify NOTHING, exit 3 on drift.
# Asserts every enum constant a row names (KVX_<kind>, KVX_H_<handling>,
# KVX_INV_<inverse>) exists.  Deterministic: LC_ALL=C, SOURCE_DATE_EPOCH=0.
set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEF="$SCRIPT_DIR/iii_vmexit.def"
VX_III="$III_ROOT/STDLIB/iii/katabasis/vmexit.iii"

[[ -f "$DEF"    ]] || { echo "$0: missing $DEF" >&2;    exit 1; }
[[ -f "$VX_III" ]] || { echo "$0: missing $VX_III" >&2; exit 1; }

CHECK_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

KINDS=(); HANDS=(); INVS=()
set +u
while IFS=$' \t' read -r kind hand inv rest; do
    case "$kind" in '#'*) continue ;; esac
    [[ -z "$kind" ]] && continue
    KINDS+=("$kind"); HANDS+=("$hand"); INVS+=("$inv")
done < <(grep -vE '^[[:space:]]*(#|$)' "$DEF")
set -u
N=${#KINDS[@]}
echo "[gen_vmexit] read $N intercepted exits from $DEF"
(( N > 0 )) || { echo "$0: no exits in $DEF" >&2; exit 2; }

CN=(); NAMEW=0
for ((i=0; i<N; i++)); do
    cn="KVX_${KINDS[i]}"
    CN+=("$cn")
    (( ${#cn} > NAMEW )) && NAMEW=${#cn}
done
chk_const() {
    if ! grep -qE "const[[:space:]]+$1[[:space:]]*:" "$VX_III"; then
        echo "$0: vmexit.iii missing constant '$1' named by iii_vmexit.def" >&2
        exit 2
    fi
}
for ((i=0; i<N; i++)); do
    chk_const "${CN[i]}"
    chk_const "KVX_H_${HANDS[i]}"
    chk_const "KVX_INV_${INVS[i]}"
done

GEN_BLOCK="$(mktemp)"
{
    printf '/* GENERATED FROM iii_vmexit.def by gen_vmexit.sh -- DO NOT EDIT BY HAND. */\n'

    printf '/* Is this exit in the minimal intercepted set?  The six modelled exits are\n'
    printf ' * intercepted; every other exit is not (it is handled by fail-close). */\n'
    printf 'fn katabasis_vmexit_intercepted(kind: u32) -> u8 @export {\n'
    printf '    let k : u32 = kind\n'
    for ((i=0; i<N; i++)); do
        printf '    if k == %-*s { return 1u8 }\n' "$NAMEW" "${CN[i]}"
    done
    printf '    return 0u8\n'
    printf '}\n'
    printf '\n'

    printf '/* The handling discipline for an exit (plan 4.8).  Any unmodelled exit falls to\n'
    printf ' * the total fail-closed catch-all. */\n'
    printf 'fn katabasis_vmexit_handling(kind: u32) -> u32 @export {\n'
    printf '    let k : u32 = kind\n'
    for ((i=0; i<N; i++)); do
        printf '    if k == %-*s { return KVX_H_%s }\n' "$NAMEW" "${CN[i]}" "${HANDS[i]}"
    done
    printf '    return KVX_H_FAIL_CLOSED\n'
    printf '}\n'
    printf '\n'

    printf '/* The SID inverse kind for an exit (plan 4.8). */\n'
    printf 'fn katabasis_vmexit_inverse(kind: u32) -> u32 @export {\n'
    printf '    let k : u32 = kind\n'
    for ((i=0; i<N; i++)); do
        printf '    if k == %-*s { return KVX_INV_%s }\n' "$NAMEW" "${CN[i]}" "${INVS[i]}"
    done
    printf '    return KVX_INV_HOST_STATE\n'
    printf '}\n'
} > "$GEN_BLOCK"

BEGIN_MARK='/* === BEGIN AUTO-GENERATED FROM iii_vmexit.def === */'
END_MARK='/* === END AUTO-GENERATED FROM iii_vmexit.def === */'
for mark in "$BEGIN_MARK" "$END_MARK"; do
    if ! grep -qF "$mark" "$VX_III"; then
        echo "$0: $VX_III missing sentinel: $mark" >&2
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
' "$VX_III" > "$NEW"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if ! cmp -s "$VX_III" "$NEW"; then
        echo "[gen_vmexit] DRIFT: $VX_III diverged from iii_vmexit.def" >&2
        rm -f "$GEN_BLOCK" "$NEW"; exit 3
    fi
    echo "[gen_vmexit] check: $VX_III current"
else
    if ! cmp -s "$VX_III" "$NEW"; then
        cp "$NEW" "$VX_III"
        echo "[gen_vmexit] rewrote $VX_III"
    else
        echo "[gen_vmexit] $VX_III already current"
    fi
fi
rm -f "$GEN_BLOCK" "$NEW"
echo "[gen_vmexit] OK ($N exits)"
