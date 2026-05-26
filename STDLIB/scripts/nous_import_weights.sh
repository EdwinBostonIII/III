#!/usr/bin/env bash
# nous_import_weights.sh -- ADR-N8 IMPORT boundary (nous Phase 6).
#
# Take an out-of-tree weights file, QUARANTINE it, refuse it if empty/missing, and
# content-address it (sha256 here at the transport layer; the authoritative cad seal +
# bit-exact forward-pass check happen in-tree, gated by nous_train_load).  By the closure,
# ANY weights are safe -- a weak set only raises the gap rate -- so the boundary's job is
# integrity (a real, non-empty, addressed artifact), not trust.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WFILE="${1:-}"
QUAR="${2:-$ROOT/STDLIB/build/nous_quarantine}"
[ -n "$WFILE" ] || { echo "usage: nous_import_weights.sh <weights-file> [quarantine-dir]" >&2; exit 2; }
[ -f "$WFILE" ] || { echo "REFUSE: weights file not found: $WFILE" >&2; exit 1; }
[ -s "$WFILE" ] || { echo "REFUSE: empty weights artifact (unsealed by definition)" >&2; exit 1; }

mkdir -p "$QUAR" || { echo "FATAL: cannot create quarantine $QUAR" >&2; exit 2; }
cp "$WFILE" "$QUAR/weights.bin"
if command -v sha256sum >/dev/null 2>&1; then ADDR="$(sha256sum "$QUAR/weights.bin" | cut -d' ' -f1)"; else ADDR="sha256sum-unavailable"; fi
printf '%s  weights.bin\n' "$ADDR" > "$QUAR/manifest.txt"
echo "nous import: quarantined + addressed weights"
echo "  addr: $ADDR"
echo "  path: $QUAR/weights.bin"
echo "(in-tree, nous_train_load admits it ONLY after the cad seal verifies; quantize to"
echo " deterministic integer + verify the forward pass bit-exact vs reference vectors first.)"
exit 0
