#!/usr/bin/env bash
# ============================================================================
# trusted_base_check.sh -- the TRUSTED-BASE content-address seal (SEPARATE-2 / W2.4).
#
# typecheck.iii delegates its ENTIRE trusted computational base to the CCL reducer
# (numera/ccl.iii) + the TC<->CCL translation (tc_to_ccl in typecheck.iii, ccl_to_tc in
# ccl.iii).  This gate content-addresses that base's SOURCE BYTES into one named root:
#
#   TRUSTED_BASE_ROOT = sha256( ccl.iii  ++  tc_to_ccl(typecheck.iii) )
#
# so "the trusted base is small and bounded" becomes a MACHINE-CHECKED fact (a hash gate),
# not prose: any edit to the reducer or the translation MOVES this hash, reddening the build
# until an explicit reseal acknowledges the trusted base changed.  This is the de Bruijn
# thesis made honest (the kernel's meaning has ONE small, named, sealed source of truth).
#
#   --print   emit the current root (use to (re)seal after an intended trusted-base change)
#   --check   (default) compare the current root to the recorded golden; exit 3 on drift
#
# FORGE_CLOSURE-lite: a standalone STDLIB seal, NOT folded into the Sovereign forge manifest
# (DOCS/SOVEREIGN-LEDGER.md), so it needs no multi-level closure recompute.
# ============================================================================
set -u
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CCL="$ROOT_DIR/STDLIB/iii/numera/ccl.iii"
TC="$ROOT_DIR/STDLIB/iii/numera/typecheck.iii"
SEAL="$ROOT_DIR/DOCS/TRUSTED-BASE-SEAL.md"

if [[ ! -f "$CCL" || ! -f "$TC" ]]; then
    echo "[trusted_base_check] FATAL: missing $CCL or $TC" >&2
    exit 2
fi

# tc_to_ccl spans from `fn tc_to_ccl(` to the first column-0 `}` (the function's close;
# its inner braces are indented, so `^}` matches only the closing brace).
extract_tc_to_ccl() {
    awk '/^fn tc_to_ccl\(/{f=1} f{print} (f && /^}/){exit}' "$TC"
}

compute_root() {
    { cat "$CCL"; extract_tc_to_ccl; } | sha256sum | cut -d' ' -f1
}

CUR="$(compute_root)"

case "${1:---check}" in
    --print)
        echo "$CUR"
        ;;
    --check)
        GOLD="$(grep -oE 'TRUSTED_BASE_ROOT = [0-9a-f]{64}' "$SEAL" 2>/dev/null | awk '{print $3}')"
        if [[ -z "$GOLD" ]]; then
            echo "[trusted_base_check] FATAL: no recorded golden in $SEAL (run --print to seal)" >&2
            exit 2
        fi
        if [[ "$CUR" != "$GOLD" ]]; then
            echo "[trusted_base_check] FATAL: trusted-base drift -- {ccl.iii + tc_to_ccl} changed." >&2
            echo "[trusted_base_check]   recorded: $GOLD" >&2
            echo "[trusted_base_check]   current:  $CUR" >&2
            echo "[trusted_base_check]   If intended, reseal: update TRUSTED_BASE_ROOT in DOCS/TRUSTED-BASE-SEAL.md (bash $0 --print)." >&2
            exit 3
        fi
        echo "[trusted_base_check] OK: TRUSTED_BASE_ROOT = $CUR"
        ;;
    *)
        echo "usage: trusted_base_check.sh [--check|--print]" >&2
        exit 1
        ;;
esac
