#!/usr/bin/env bash
# COMPILER/BOOT/run_repl_kat.sh — Θ4 THE MOUTH: the REPL transcript KAT.
# Feeds meaning_repl.txt into `iii_eval --repl` and byte-compares the FULL
# stdout against the pinned meaning_repl.rexp.  Falsifier: any transcript
# drift (banner, prompts, values, acceptance messages) reddens.
# Exit: 0 green | 1 drift | 2 env.  Run from anywhere; execution is staged
# to /tmp and pinned to the repo root CWD (the REPL resolves imports as if
# its cell lived in COMPILER/BOOT).
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
EVAL_BIN="${EVAL_BIN:-$III_ROOT/COMPILED/iii_eval${BIN_SUFFIX}}"
[[ -x "$EVAL_BIN" ]] || { echo "[repl-kat] FATAL: no iii_eval"; exit 2; }
[[ -f "$SCRIPT_DIR/meaning_repl.txt" ]]  || { echo "[repl-kat] FATAL: no transcript script"; exit 2; }
[[ -f "$SCRIPT_DIR/meaning_repl.rexp" ]] || { echo "[repl-kat] FATAL: no pinned expectation"; exit 2; }
STAGED="/tmp/repl_kat_$$${BIN_SUFFIX}"
cp "$EVAL_BIN" "$STAGED"
OUT="/tmp/repl_kat_$$.out"
( cd "$III_ROOT" && timeout 60 "$STAGED" --repl < "$SCRIPT_DIR/meaning_repl.txt" > "$OUT" 2>&1 )
rc=$?
rm -f "$STAGED"
if [[ $rc -ne 0 ]]; then echo "[repl-kat] RED: repl exited rc=$rc"; rm -f "$OUT"; exit 1; fi
if ! cmp -s "$OUT" "$SCRIPT_DIR/meaning_repl.rexp"; then
    echo "[repl-kat] RED: transcript drift"
    diff "$SCRIPT_DIR/meaning_repl.rexp" "$OUT" | head -10
    rm -f "$OUT"
    exit 1
fi
rm -f "$OUT"
echo "[repl-kat] GREEN: transcript byte-identical"
exit 0
