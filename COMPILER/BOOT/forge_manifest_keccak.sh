#!/usr/bin/env bash
# COMPILER/BOOT/forge_manifest_keccak.sh
#
# W5.2 (RIPPLE-11 level D): the THIRD forge closure level -- the manifest Keccak-256 root.
# DOCS/SOVEREIGN-LEDGER.md §Closure defines  Forge closure root = Keccak-256( concat( sorted
# citizen seal-hashes ) ).  Pre-W5.2 this level was "uncomputed -- not recomputable in toolset":
# there was no Keccak recompute step, only forge_check.sh's SHA-256 descent root.  This tool
# BUILDS that step (it does not route around it) using the in-tree numera/keccak.iii via a tiny
# driver (forge_keccak_driver.iii) -- NIH, no new dependency.
#
# The input is IDENTICAL to forge_check.sh's level-C input (the six citizen seals, sorted,
# LC_ALL=C, concatenated, no trailing newline), so the SHA-256 and Keccak-256 levels are
# consistent: editing any forge citizen changes BOTH roots and reddens BOTH gates.
#
# Modes:
#   (default)  verify -- exit 0 iff the recomputed manifest root is recorded in the ledger; 4 on drift.
#   --print    recompute and PRINT the manifest root (to paste into the ledger after a legit reseal).
#
# Deterministic (LC_ALL=C, sorted seals). Wired into subsystem_test_gate.sh after forge_check.sh.
set -uo pipefail
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LEDGER="$III_ROOT/DOCS/SOVEREIGN-LEDGER.md"
IIIS="$III_ROOT/COMPILED/iiis-2.exe"
LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
DRIVER_SRC="$SCRIPT_DIR/forge_keccak_driver.iii"

MODE=verify
for arg in "$@"; do
    case "$arg" in
        --print) MODE=print ;;
        *) echo "$0: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

[[ -f "$LEDGER"     ]] || { echo "forge_manifest_keccak: missing $LEDGER" >&2; exit 4; }
[[ -f "$IIIS"       ]] || { echo "forge_manifest_keccak: missing compiler $IIIS" >&2; exit 3; }
[[ -f "$LIB"        ]] || { echo "forge_manifest_keccak: missing $LIB (run build_stdlib.sh first)" >&2; exit 3; }
[[ -f "$DRIVER_SRC" ]] || { echo "forge_manifest_keccak: missing driver $DRIVER_SRC" >&2; exit 3; }

# The KATABASIS Forge citizens + primary KAT (identical mapping to forge_check.sh).
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

# Full-spec seals (same recipe as forge_check.sh).
SEALS=""
for t in $CITIZENS; do
    def="$SCRIPT_DIR/iii_$t.def"
    gen="$SCRIPT_DIR/gen_$t.sh"
    con="$III_ROOT/STDLIB/iii/katabasis/$t.iii"
    kat="$(katfile "$t")"
    for f in "$def" "$gen" "$con" "$kat"; do
        [[ -n "$f" && -f "$f" ]] || { echo "forge_manifest_keccak: missing artifact for $t: '${f:-<no KAT>}'" >&2; exit 4; }
    done
    s="$(cat "$def" "$gen" "$con" "$kat" | sha256sum | cut -d' ' -f1)"
    SEALS="${SEALS}${s}"$'\n'
done

# Level-C input: sorted seals, no trailing newline (matches forge_check.sh's descent root).
INPUT="$(printf '%s' "$SEALS" | sed '/^$/d' | sort | tr -d '\n')"

# Build the Keccak driver (NIH keccak over libiii_native.a).
OBJ="$III_ROOT/STDLIB/build/forge_keccak_driver.iii.o"
EXE="$III_ROOT/STDLIB/build/forge_keccak_driver.exe"
"$IIIS" "$DRIVER_SRC" --compile-only --out "$OBJ" >/dev/null 2>&1 \
    || { echo "forge_manifest_keccak: driver compile failed" >&2; exit 3; }
gcc "$OBJ" "$LIB" -lws2_32 -lkernel32 -o "$EXE" >/dev/null 2>&1 \
    || { echo "forge_manifest_keccak: driver link failed" >&2; exit 3; }

# Run in a clean dir (the driver reads forge_keccak_in.tmp / writes forge_keccak_out.tmp in cwd;
# stage in /tmp to dodge the OneDrive/Defender exec heuristic, as the corpus harness does).
WORK="$(mktemp -d 2>/dev/null || echo /tmp)"
cp "$EXE" "$WORK/fkd.exe"
printf '%s' "$INPUT" > "$WORK/forge_keccak_in.tmp"
( cd "$WORK" && ./fkd.exe ) || { echo "forge_manifest_keccak: driver run failed" >&2; rm -rf "$WORK"; exit 3; }
ROOT="$(cat "$WORK/forge_keccak_out.tmp" 2>/dev/null)"
rm -rf "$WORK"

if [[ -z "$ROOT" || ${#ROOT} -ne 64 ]]; then
    echo "forge_manifest_keccak: driver produced no 64-char root (got '${ROOT}')" >&2
    exit 3
fi

if [[ "$MODE" = print ]]; then
    echo "Manifest closure root  Keccak-256( sort(K1..K6 seals) ):"
    echo "  $ROOT"
    exit 0
fi

if grep -qF "$ROOT" "$LEDGER"; then
    echo "[forge_manifest_keccak] OK: manifest Keccak-256 closure root $ROOT recorded (level D live)."
    exit 0
fi
echo "[forge_manifest_keccak] MANIFEST CLOSURE VIOLATION -- recomputed Keccak root $ROOT is NOT in the ledger (a forge citizen changed without re-sealing level D). Re-seal: 'forge_manifest_keccak.sh --print' then update DOCS/SOVEREIGN-LEDGER.md." >&2
exit 4
