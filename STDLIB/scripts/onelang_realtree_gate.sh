#!/usr/bin/env bash
# onelang_realtree_gate.sh -- the REAL-TREE one-language audit (Harmony Invariant H13, systemwide).
#
# The F6 apotheosis audit found the charter folds a per-organ MECHANISM check (onelang_selftest on a
# SYNTHETIC tree) but never asserts the REAL tree is one-language-pure (onelang_gate_cwd's caller
# "tolerates VIOLATION").  Run on the live tree, III's own scanner (STDLIB/iii/sanctus/onelang.iii)
# reported VIOLATION with 15 unaccounted-C GAP files -- which on inspection are 14 ccsv (C->SVIR
# frontend) INPUT fixtures under STDLIB/sovir/ (the C the frontend COMPILES, not III implementation;
# none in build_iiis2/build_stdlib) + 1 UNTRACKED root scratch (gs3_counter.c).  The classifier's
# HARNESS bucket was too narrow; it now accounts for sovir/ (the fix that earned this gate).
#
# THIS GATE is the standing real-tree assertion: the COMMITTED III artifact is one-language-pure --
# ZERO git-TRACKED .c/.h fall in onelang's GAP bucket (i.e. outside bootstrap COMPILER/BOOT+SANCTUM,
# the retired LEXICON/GRAMMAR, the harness tests/tools/KATABASIS/test_*/sovir).  Untracked working-tree
# scratch is tolerated (it is not the artifact -- exactly as onelang skips build/ and .git).  The
# bucket regex below MIRRORS onelang.iii::ol_classify verbatim; a NEW unaccounted tracked C file
# reddens here.  Exit 0 = pure; 1 = a tracked one-language violation (listed).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# onelang.iii::ol_is_skip_dir -- directories the scanner never descends (not the artifact):
SKIP='(^|/)\.git/|(^|/)\.claude/|(^|/)build/|(^|/)_audit_scratch/'
# onelang.iii::ol_classify buckets (path-substring / filename-prefix), as a single exclusion regex:
#   BOOTSTRAP : COMPILER/BOOT, SANCTUM          DEAD : LEXICON, GRAMMAR
#   HARNESS   : tests/, tools/, KATABASIS, test_* basename, sovir/
ACCOUNTED='COMPILER/BOOT|SANCTUM|LEXICON|GRAMMAR|/tests/|/tools/|KATABASIS|(^|/)test_[^/]*$|/sovir/'

gaps="$(git ls-files '*.c' '*.h' 2>/dev/null | grep -vE "$SKIP" | grep -vE "$ACCOUNTED" || true)"
n=$(printf '%s' "$gaps" | grep -c . || true)

echo "[onelang-realtree] git-tracked .c/.h, unaccounted by onelang's buckets (GAP) = $n"
if [ "$n" -eq 0 ]; then
  echo "[onelang-realtree] GREEN -- the COMMITTED III artifact is ONE-LANGUAGE pure: no C survives save the"
  echo "                   bootstrap trust root (COMPILER/BOOT + SANCTUM) + the retired LEXICON/GRAMMAR +"
  echo "                   the harness (tests/tools/KATABASIS/test_*/sovir ccsv-input corpus). H13 holds on the REAL tree."
  exit 0
else
  echo "[onelang-realtree] VIOLATION -- $n tracked unaccounted C file(s) (a one-language regression):"
  printf '%s\n' "$gaps" | sed 's/^/    /'
  exit 1
fi
