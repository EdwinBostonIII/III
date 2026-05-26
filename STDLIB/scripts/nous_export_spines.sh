#!/usr/bin/env bash
# nous_export_spines.sh -- ADR-N8 EXPORT boundary (nous Phase 6).
#
# The trainer is OUT-OF-TREE; the only thing that crosses the boundary outward is
# CERTIFIED training material, by an explicit file dump.  This script bundles the
# certified nous corpus (the proven-green training-signal sources) into an export
# directory with a content-addressed manifest.  Nothing in-tree is mutated.
#
# At M13 the live witnessed-search spines (witness_spine segments) are not yet
# persisted, so the certified corpus is the boundary proxy; when searches deposit to
# the commons + spine (M19 federation era), extend the SOURCES list to dump those
# segments.  The discipline is the point: only CERTIFIED material leaves, addressed.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$ROOT/STDLIB/build/nous_export}"
mkdir -p "$OUT" || { echo "FATAL: cannot create $OUT" >&2; exit 2; }

# the certified nous corpus (each is EXPECTED=99 in run_corpus.sh)
SOURCES=(800_nous_socket 801_nous_costlin 802_nous_search 803_nous_charter \
         804_nous_policy 805_nous_completion 806_nous_commons 807_nous_train)

MAN="$OUT/manifest.txt"; : > "$MAN"
n=0
for t in "${SOURCES[@]}"; do
    src="$ROOT/STDLIB/corpus/$t.iii"
    [ -f "$src" ] || continue
    cp "$src" "$OUT/"
    if command -v sha256sum >/dev/null 2>&1; then h="$(sha256sum "$src" | cut -d' ' -f1)"; else h="sha256sum-unavailable"; fi
    printf '%s  %s\n' "$t" "$h" >> "$MAN"
    n=$((n+1))
done
echo "nous export: $n certified spine sources -> $OUT (manifest: $MAN)"
echo "(the out-of-tree trainer consumes these; weights return via nous_import_weights.sh,"
echo " and are admitted in-tree only after nous_train_load's cad seal verifies.)"
exit 0
