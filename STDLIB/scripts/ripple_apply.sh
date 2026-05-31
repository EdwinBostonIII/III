#!/usr/bin/env bash
# STDLIB/scripts/ripple_apply.sh -- the Sovereign Ripple Loop APPLIER (Inc 5; BATCH 3: multi-file atomic).
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
# BATCH 3 -- MULTI-FILE ATOMICITY: a coordinated refactoring (e.g. an extraction that writes a new
# file AND re-points its callers) touches several files at once.  ALL targets named before `--` are
# backed up together and REVERTED together on any gate failure -- so a rejected change can never
# leave the tree half-mutated (the previous single-$TARGET backup reverted only one file, silently
# stranding the edit's other writes).  Single-target invocation is byte-for-byte the old behaviour.
#
# Usage:  ripple_apply.sh <target_file> [<target_file> ...] -- <edit_cmd...>
#   <edit_cmd> mutates the target file(s) in place (the certified refactoring; e.g. a sed -i / patch).
# Exit:  0 = applied + verified green (KEEP);  2..5 = rejected by gate N, all targets reverted;  1 = usage.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
# the current golden compiler fixed point (a LIBNATIVE refactoring must leave it byte-identical)
GOLDEN_IIIS="196b0c5f5159329b2e419aecb561ee57980d62bcc892ea84f260559bcdfaa990"

# --- collect the target SET: every arg up to `--` (atomically backed up + reverted together). ---
TARGETS=()
while [ $# -gt 0 ] && [ "$1" != "--" ]; do TARGETS+=("$1"); shift; done
[ "${1:-}" = "--" ] && shift
EDIT_CMD="$*"

if [ "${#TARGETS[@]}" -lt 1 ]; then echo "[ripple_apply] FATAL: no target(s) before --" >&2; exit 1; fi
for t in "${TARGETS[@]}"; do
    if [ ! -f "$t" ]; then echo "[ripple_apply] FATAL: no such file: $t" >&2; exit 1; fi
done

# --- atomic backup of the whole set (indexed backups in one scratch dir) ---
BAKDIR="$(mktemp -d)"
BAK=()
_i=0
for t in "${TARGETS[@]}"; do BAK+=("$BAKDIR/$_i.bak"); cp "$t" "$BAKDIR/$_i.bak"; _i=$((_i+1)); done
restore_files() { local j=0; for t in "${TARGETS[@]}"; do cp "${BAK[$j]}" "$t"; j=$((j+1)); done; }
cleanup_bak()   { rm -rf "$BAKDIR"; }
rebuild_lib()   { bash "$ROOT/STDLIB/scripts/build_stdlib.sh" > /tmp/ra_revert.log 2>&1; }

echo "[ripple_apply] APPLY to ${TARGETS[*]}:  $EDIT_CMD"
eval "$EDIT_CMD"

# --- GATE 0 (fast): EVERY edited .iii target must still compile standalone (instant syntax backstop). ---
echo "[ripple_apply] GATE 0: standalone compile (${#TARGETS[@]} target(s))"
for t in "${TARGETS[@]}"; do
    case "$t" in
        *.iii)
            if ! "$IIIS" "$t" --compile-only --out /tmp/ra_pre.o > /tmp/ra_g0.log 2>&1; then
                echo "[ripple_apply] REJECT @GATE0 ($t does not compile) -> revert all (library untouched)"
                restore_files; cleanup_bak; exit 2
            fi
            ;;
    esac
done

# --- GATE 1: the whole library still builds (FAIL = 0). ---
echo "[ripple_apply] GATE 1: build_stdlib (FAIL=0)"
if ! bash "$ROOT/STDLIB/scripts/build_stdlib.sh" > /tmp/ra_bs.log 2>&1 || ! grep -q 'FAIL = 0' /tmp/ra_bs.log; then
    echo "[ripple_apply] REJECT @GATE1 (build_stdlib) -> revert all + rebuild"
    restore_files; rebuild_lib; cleanup_bak; exit 3
fi

# --- GATE 2: the refactoring is LIBNATIVE -- the bootstrap compiler is byte-UNCHANGED. ---
echo "[ripple_apply] GATE 2: compiler unchanged (LIBNATIVE)"
i2="$(sha256sum "$ROOT/COMPILED/iiis-2.exe" | cut -d' ' -f1)"
if [ "$i2" != "$GOLDEN_IIIS" ]; then
    echo "[ripple_apply] REJECT @GATE2 (compiler drift $i2 != golden) -> revert all + rebuild"
    restore_files; rebuild_lib; cleanup_bak; exit 4
fi

# --- GATE 3: ZERO behavioral regression across the full corpus. ---
echo "[ripple_apply] GATE 3: full corpus (FAIL=0)"
if ! bash "$ROOT/STDLIB/scripts/run_corpus.sh" > /tmp/ra_rc.log 2>&1 || ! grep -qE 'FAIL=0' /tmp/ra_rc.log; then
    echo "[ripple_apply] REJECT @GATE3 (corpus regression) -> revert all + rebuild"
    restore_files; rebuild_lib; cleanup_bak; exit 5
fi

echo "[ripple_apply] KEEP -- refactoring verified green. lib mhash: $(awk '{print $1}' "$ROOT/STDLIB/build/iii/libiii_native.a.mhash")"
cleanup_bak
exit 0
