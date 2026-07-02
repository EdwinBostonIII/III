#!/usr/bin/env bash
# seal_route.sh -- THE SEAL SPLIT (reunification L10 addition, 2026-07-02).
#
# The sovereignty goodies (DDC / twin-build BIT-IDENTICAL / GCC-independence) are COMPILER-province
# properties; STDLIB organ edits cannot break them.  The old habit re-proved the expensive twin build
# on every seal touch.  This router isolates the goodies without weakening them:
#
#   organ change   (STDLIB/**)            -> seal_sources.sh          (pure hashing re-pin: seconds)
#   compiler change (COMPILER/** BOOT/**) -> seal_sources.sh --verify (the full twin-build goodie)
#   --audit                               -> force the full --verify (the periodic belt)
#
# usage: seal_route.sh [--audit] <changed-file>...
set -u
III="$(cd "$(dirname "$0")/../.." && pwd)"
SEAL="$III/STDLIB/scripts/seal_sources.sh"
mode="organ"
[[ "${1:-}" == "--audit" ]] && { mode="compiler"; shift; }
for f in "$@"; do
    case "$f" in
        COMPILER/*|*/COMPILER/*|BOOT/*|*/BOOT/*|COMPILED/*|*/COMPILED/*) mode="compiler";;
    esac
done
if [[ "$mode" == "compiler" ]]; then
    echo "[seal-route] compiler province touched (or --audit): full twin-build verify"
    bash "$SEAL" && bash "$SEAL" --verify
else
    echo "[seal-route] organ change only: hash re-pin (twin-build goodie not owed)"
    bash "$SEAL"
fi
