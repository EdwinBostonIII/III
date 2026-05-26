#!/usr/bin/env bash
# III Sovereign Boundary Audit -- the audit "mode".
#
# The in-tree compiler (cg_r3.iii :: r3_audit_sovereign) emits a machine-readable
#     # III_SOVEREIGN_AUDIT <class> <fn> p<i>
# record into each module's .o.s for every @sovereign / @sovereign_value /
# @sovereign_out-marked declaration it codegens.  This driver compiles the M31
# aether membrane and renders those records as a boundary MANIFEST -- i.e. III
# reporting its own security-boundary surface, so a reviewer can confirm every
# external-IO primitive is classified (and spot a new IO fn added unmarked: it
# simply will not appear).
#
#   SOURCE  param fills an untrusted buffer (@sovereign_out)        -- taint origin
#   SOVVAL  param accepts/carries sovereign data (@sovereign_value) -- sink/sanitiser
#   SOVFN   function-level @sovereign boundary (per-fn law subject)
#
# Records live in .o.s assembly comments only (stripped before the .o), so this
# audit is observation, never a behaviour change.
#
# Usage: bash audit_sovereign.sh [scan-dir]   (default: STDLIB/iii/aether)
#   IIIS=... overrides the compiler (default: COMPILED/iiis-2[.exe]).
set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$STDLIB_DIR/.." && pwd)"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) SFX=".exe" ;;
    *)                                  SFX=""     ;;
esac
IIIS="${IIIS:-$REPO_ROOT/COMPILED/iiis-2$SFX}"
SCAN_DIR="${1:-$STDLIB_DIR/iii/aether}"
[ -x "$IIIS" ] || { echo "[audit] FATAL: iiis not found at $IIIS" >&2; exit 2; }
[ -d "$SCAN_DIR" ] || { echo "[audit] FATAL: scan dir not found: $SCAN_DIR" >&2; exit 2; }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/sovaudit.XXXXXX")"
trap '[ -n "${TMP:-}" ] && rm -rf "$TMP"' EXIT

echo "============================================================"
echo " III SOVEREIGN BOUNDARY AUDIT"
echo "   compiler : $IIIS"
echo "   scanning : $SCAN_DIR"
echo "============================================================"

total=0
mods=0
for src in "$SCAN_DIR"/*.iii; do
    [ -f "$src" ] || continue
    name="$(basename "$src" .iii)"
    obj="$TMP/$name.o"
    "$IIIS" "$src" --compile-only --out "$obj" >"$TMP/$name.log" 2>&1 || true
    rec="$obj.s"
    [ -f "$rec" ] || rec="$TMP/$name.log"
    hits="$(grep -F 'III_SOVEREIGN_AUDIT' "$rec" 2>/dev/null \
            | sed -E 's/.*# III_SOVEREIGN_AUDIT //' | sort -u)"
    if [ -n "$hits" ]; then
        echo
        echo "$name:"
        while IFS= read -r h; do
            if [ -n "$h" ]; then
                echo "    $h"
                total=$((total+1))
            fi
        done <<< "$hits"
        mods=$((mods+1))
    fi
done

echo
echo "------------------------------------------------------------"
echo "  $total marked boundary record(s) across $mods module(s)"
echo "  (SOURCE=@sovereign_out  SOVVAL=@sovereign_value  SOVFN=@sovereign)"
echo "------------------------------------------------------------"
