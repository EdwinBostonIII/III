#!/usr/bin/env bash
# STDLIB/scripts/ripple_apply.sh -- the Sovereign Ripple Loop APPLIER (Inc 5).
#
# The gated file-editing EXECUTION arm.  The .iii decision engine (ripple_metric / ripple_unify /
# ripple_loop / ripple_cut) certifies WHAT to refactor; this tool EXECUTES the certified edit on a
# real .iii file, proves the post-state green through the full build+seal+corpus gate, and KEEPS
# iff every gate passes -- otherwise it atomically REVERTS (and rebuilds the library from the good
# source).  It is a TOOL, not an .iii module, because it touches the OS membrane (write, build,
# git); the .iii engine stays pure.
#
# THE INDUCTIVE SAFETY INVARIANT: the tree is verified-green BEFORE and AFTER every applier step,
# so III is never left broken.  Safety depends on the GATE being honest, NOT on the edit being
# right -- a wrong edit is caught and reverted.  Two independent proofs guard every change: the
# .iii certification (behavior-preservation, BEFORE the edit) and this gate (the backstop).
#
# Usage:  ripple_apply.sh <target_file> -- <edit_cmd...>
#   <edit_cmd> mutates <target_file> in place (the certified refactoring; e.g. a sed -i or patch).
# Exit:  0 = applied + verified green (KEEP);  2..5 = rejected by gate N, reverted.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
# the current golden compiler fixed point (a LIBNATIVE refactoring must leave it byte-identical)
GOLDEN_IIIS="4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85"

TARGET="$1"; shift
[ "${1:-}" = "--" ] && shift
EDIT_CMD="$*"

if [ ! -f "$TARGET" ]; then echo "[ripple_apply] FATAL: no such file: $TARGET" >&2; exit 1; fi

bak="$(mktemp)"; cp "$TARGET" "$bak"
restore_file() { cp "$bak" "$TARGET"; }
rebuild_lib()  { bash "$ROOT/STDLIB/scripts/build_stdlib.sh" > /tmp/ra_revert.log 2>&1; }

echo "[ripple_apply] APPLY to $TARGET:  $EDIT_CMD"
eval "$EDIT_CMD"

# --- GATE 0 (fast): the edited file must still compile standalone (instant syntax backstop). ---
echo "[ripple_apply] GATE 0: standalone compile"
if ! "$IIIS" "$TARGET" --compile-only --out /tmp/ra_pre.o > /tmp/ra_g0.log 2>&1; then
    echo "[ripple_apply] REJECT @GATE0 (does not compile) -> revert file (library untouched)"
    restore_file; rm -f "$bak"; exit 2
fi

# --- GATE 1: the whole library still builds (FAIL = 0). ---
echo "[ripple_apply] GATE 1: build_stdlib (FAIL=0)"
if ! bash "$ROOT/STDLIB/scripts/build_stdlib.sh" > /tmp/ra_bs.log 2>&1 || ! grep -q 'FAIL = 0' /tmp/ra_bs.log; then
    echo "[ripple_apply] REJECT @GATE1 (build_stdlib) -> revert + rebuild"
    restore_file; rebuild_lib; rm -f "$bak"; exit 3
fi

# --- GATE 2: the refactoring is LIBNATIVE -- the bootstrap compiler is byte-UNCHANGED. ---
echo "[ripple_apply] GATE 2: compiler unchanged (LIBNATIVE)"
i2="$(sha256sum "$ROOT/COMPILED/iiis-2.exe" | cut -d' ' -f1)"
if [ "$i2" != "$GOLDEN_IIIS" ]; then
    echo "[ripple_apply] REJECT @GATE2 (compiler drift $i2 != golden) -> revert + rebuild"
    restore_file; rebuild_lib; rm -f "$bak"; exit 4
fi

# --- GATE 3: ZERO behavioral regression across the full corpus. ---
echo "[ripple_apply] GATE 3: full corpus (FAIL=0)"
if ! bash "$ROOT/STDLIB/scripts/run_corpus.sh" > /tmp/ra_rc.log 2>&1 || ! grep -qE 'FAIL=0' /tmp/ra_rc.log; then
    echo "[ripple_apply] REJECT @GATE3 (corpus regression) -> revert + rebuild"
    restore_file; rebuild_lib; rm -f "$bak"; exit 5
fi

echo "[ripple_apply] KEEP -- refactoring verified green. lib mhash: $(awk '{print $1}' "$ROOT/STDLIB/build/iii/libiii_native.a.mhash")"
rm -f "$bak"
exit 0
