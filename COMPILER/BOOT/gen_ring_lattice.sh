#!/usr/bin/env bash
# COMPILER/BOOT/gen_ring_lattice.sh
#
# KATABASIS ring-transition lattice generator (plan 6.9 / FR-9 / plan 4.6).
# Single source of truth = iii_ring_lattice.def.  Regenerates the AUTO-GENERATED
# constructor cascade (katabasis_ring_constructor) in
# STDLIB/iii/katabasis/ring_lattice.iii, encoding each legal (src,dst) crossing
# as key = src_code*5 + dst_code so the lawful ring crossings cannot drift.
#
# Mirrors gen_cycle_family.sh:
#   --check  : regenerate into a temp, byte-compare, modify NOTHING, exit 3 on drift.
# Asserts every enum constant a row names (KRL_<src>, KRL_<dst>, KRL_C_<ctor>)
# exists.  Deterministic: LC_ALL=C, SOURCE_DATE_EPOCH=0.
set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEF="$SCRIPT_DIR/iii_ring_lattice.def"
RL_III="$III_ROOT/STDLIB/iii/katabasis/ring_lattice.iii"

[[ -f "$DEF"    ]] || { echo "$0: missing $DEF" >&2;    exit 1; }
[[ -f "$RL_III" ]] || { echo "$0: missing $RL_III" >&2; exit 1; }

CHECK_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# Ring code map (KRL_R3=0 .. KRL_RM4=4); error on an unknown ring name.
ring_code() {
    case "$1" in
        R3)  RC=0 ;; R0)  RC=1 ;; RM1) RC=2 ;; RM2) RC=3 ;; RM4) RC=4 ;;
        *)   echo "$0: unknown ring '$1' in $DEF" >&2; exit 2 ;;
    esac
}

SRCS=(); DSTS=(); CTORS=(); KEYS=()
set +u
while IFS=$' \t' read -r src dst ctor rest; do
    case "$src" in '#'*) continue ;; esac
    [[ -z "$src" ]] && continue
    ring_code "$src"; sc=$RC
    ring_code "$dst"; dc=$RC
    SRCS+=("$src"); DSTS+=("$dst"); CTORS+=("$ctor"); KEYS+=("$(( sc * 5 + dc ))")
done < <(grep -vE '^[[:space:]]*(#|$)' "$DEF")
set -u
N=${#SRCS[@]}
echo "[gen_ring_lattice] read $N legal crossings from $DEF"
(( N > 0 )) || { echo "$0: no crossings in $DEF" >&2; exit 2; }

# Assert the referenced enum constants exist; compute key-literal column width.
chk_const() {
    if ! grep -qE "const[[:space:]]+$1[[:space:]]*:" "$RL_III"; then
        echo "$0: ring_lattice.iii missing constant '$1' named by iii_ring_lattice.def" >&2
        exit 2
    fi
}
KEYW=0
for ((i=0; i<N; i++)); do
    chk_const "KRL_${SRCS[i]}"
    chk_const "KRL_${DSTS[i]}"
    chk_const "KRL_C_${CTORS[i]}"
    lit="${KEYS[i]}u32"
    (( ${#lit} > KEYW )) && KEYW=${#lit}
done

# Re-derive a ring's code for the comment (src*5+dst breakdown).
code_of() { case "$1" in R3) echo 0;; R0) echo 1;; RM1) echo 2;; RM2) echo 3;; RM4) echo 4;; esac; }

GEN_BLOCK="$(mktemp)"
{
    printf '/* GENERATED FROM iii_ring_lattice.def by gen_ring_lattice.sh -- DO NOT EDIT BY HAND. */\n'
    printf '/* The single legal constructor for a src->dst crossing, or NONE.  The pair is\n'
    printf ' * encoded as key = src*5 + dst (rings 0..4), so a flat key cascade is exact.\n'
    printf ' * Only the five lawful descents map to a constructor; all else is NONE -- a ring\n'
    printf ' * cannot be skipped (R3 reaches only R0) nor ascended through this relation. */\n'
    printf 'fn katabasis_ring_constructor(src: u32, dst: u32) -> u32 @export {\n'
    printf '    let a : u32 = src\n'
    printf '    let b : u32 = dst\n'
    printf '    let key : u32 = (a * 5u32) + b\n'
    for ((i=0; i<N; i++)); do
        sc="$(code_of "${SRCS[i]}")"; dc="$(code_of "${DSTS[i]}")"
        printf '    if key == %-*s { return KRL_C_%s }   /* %s(%s) -> %s(%s) */\n' \
               "$KEYW" "${KEYS[i]}u32" "${CTORS[i]}" "${SRCS[i]}" "$sc" "${DSTS[i]}" "$dc"
    done
    printf '    return KRL_C_NONE\n'
    printf '}\n'
} > "$GEN_BLOCK"

BEGIN_MARK='/* === BEGIN AUTO-GENERATED FROM iii_ring_lattice.def === */'
END_MARK='/* === END AUTO-GENERATED FROM iii_ring_lattice.def === */'
for mark in "$BEGIN_MARK" "$END_MARK"; do
    if ! grep -qF "$mark" "$RL_III"; then
        echo "$0: $RL_III missing sentinel: $mark" >&2
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
' "$RL_III" > "$NEW"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if ! cmp -s "$RL_III" "$NEW"; then
        echo "[gen_ring_lattice] DRIFT: $RL_III diverged from iii_ring_lattice.def" >&2
        rm -f "$GEN_BLOCK" "$NEW"; exit 3
    fi
    echo "[gen_ring_lattice] check: $RL_III current"
else
    if ! cmp -s "$RL_III" "$NEW"; then
        cp "$NEW" "$RL_III"
        echo "[gen_ring_lattice] rewrote $RL_III"
    else
        echo "[gen_ring_lattice] $RL_III already current"
    fi
fi
rm -f "$GEN_BLOCK" "$NEW"
echo "[gen_ring_lattice] OK ($N crossings)"
