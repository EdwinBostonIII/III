#!/usr/bin/env bash
# COMPILER/BOOT/forge_check.sh
#
# The Sovereign Forge CLOSURE META-GATE (DOCS/SOVEREIGN_FORGE.md §2: "a pile of
# generators is not a system; the spine is the manifest"). It makes the KATABASIS
# Forge family SELF-VERIFYING -- one command proves the whole manifest is
# internally consistent, beyond the per-citizen --check drift gates:
#
#   (A) NO ORPHAN GENERATOR : every COMPILER/BOOT/gen_*.sh is named by a row in
#                             DOCS/SOVEREIGN-LEDGER.md (a generator can't exist off-ledger).
#   (B) SEAL INTEGRITY      : each citizen's full-spec content address
#                             sha256( def || generator || consumer.iii || primary KAT )
#                             is recorded verbatim in the ledger (M6: the hash is the identity;
#                             changing any artifact without re-sealing is a violation).
#   (C) CLOSURE INTEGRITY   : the K1-K6 descent sub-closure root = sha256( sort(seals) ) is recorded.
#   (D) DRIFT INTEGRITY     : every per-citizen gen_<t>.sh --check passes (consumer == generator(def)).
#
# Modes:
#   (default)  verify -- exit 0 iff (A)(B)(C)(D) all hold, exit 4 on any violation. Read-only.
#   --print    recompute and PRINT the authoritative seals + sub-closure root (to paste into the
#              ledger after a legitimate .def change -- the "re-seal" step). Exit 0.
#
# Read-only in verify mode; deterministic (LC_ALL=C, sorted seals). Mirrors the D8 closure-pin
# discipline. Wired into build_stdlib.sh as a post-drift-gate meta-check.
set -uo pipefail
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LEDGER="$III_ROOT/DOCS/SOVEREIGN-LEDGER.md"

MODE=verify
for arg in "$@"; do
    case "$arg" in
        --print) MODE=print ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

[[ -f "$LEDGER" ]] || { echo "forge_check: missing $LEDGER" >&2; exit 4; }

fail=0
err(){ echo "  VIOLATION: $1" >&2; fail=1; }

# The KATABASIS Forge citizens and their primary KAT corpus number (SOVEREIGN-LEDGER K1-K6).
CITIZENS="svm_layout cycle_family census bar_layout vmexit ring_lattice"
katfile(){
    local n
    case "$1" in
        svm_layout)   n=390 ;;
        cycle_family) n=392 ;;
        bar_layout)   n=394 ;;
        vmexit)       n=600 ;;
        ring_lattice) n=601 ;;
        census)       n=603 ;;
        *) return 1 ;;
    esac
    ls "$III_ROOT"/STDLIB/corpus/${n}_*.iii 2>/dev/null | head -1
}

# (A) no orphan generator (verify mode only).
if [[ "$MODE" = verify ]]; then
    for g in "$SCRIPT_DIR"/gen_*.sh; do
        b="$(basename "$g")"
        grep -qF "$b" "$LEDGER" || err "(A) orphan generator -- no ledger row names it: $b"
    done
fi

# (B)+(D) per citizen; accumulate seals for (C).
SEALS=""
PRINT_ROWS=""
for t in $CITIZENS; do
    def="$SCRIPT_DIR/iii_$t.def"
    gen="$SCRIPT_DIR/gen_$t.sh"
    con="$III_ROOT/STDLIB/iii/katabasis/$t.iii"
    kat="$(katfile "$t")"
    miss=0
    for f in "$def" "$gen" "$con" "$kat"; do
        if [[ -z "$f" || ! -f "$f" ]]; then err "($t) missing artifact: '${f:-<no KAT>}'"; miss=1; fi
    done
    [[ "$miss" = 1 ]] && continue
    if [[ "$MODE" = verify ]]; then
        bash "$gen" --check >/dev/null 2>&1 || err "(D) drift gate fails for $t (consumer != generator(def))"
    fi
    s="$(cat "$def" "$gen" "$con" "$kat" | sha256sum | cut -d' ' -f1)"
    SEALS="${SEALS}${s}"$'\n'
    PRINT_ROWS="${PRINT_ROWS}$(printf '  %-13s %s' "$t" "$s")"$'\n'
    if [[ "$MODE" = verify ]]; then
        grep -qF "$s" "$LEDGER" || err "(B) $t seal $s NOT recorded in ledger (artifact changed without re-sealing)"
    fi
done

# (C) descent sub-closure root = sha256( sorted seals concatenated ).
root="$(printf '%s' "$SEALS" | sed '/^$/d' | sort | tr -d '\n' | sha256sum | cut -d' ' -f1)"

if [[ "$MODE" = print ]]; then
    echo "Full-spec seals  sha256( iii_<t>.def || gen_<t>.sh || katabasis/<t>.iii || primary KAT ):"
    printf '%s' "$PRINT_ROWS"
    echo "Descent sub-closure root  sha256( sort(seals) ):"
    echo "  $root"
    exit 0
fi

grep -qF "$root" "$LEDGER" || err "(C) descent sub-closure root $root NOT recorded in ledger"

if [[ "$fail" = 0 ]]; then
    echo "[forge_check] OK: 6 KATABASIS citizens drift-clean + full-spec-sealed; sub-closure root $root recorded; no orphan generators."
    exit 0
fi
echo "[forge_check] FORGE CLOSURE VIOLATION -- the manifest is not self-consistent (run 'forge_check.sh --print' to re-seal after a legitimate .def change)." >&2
exit 4
