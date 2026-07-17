#!/usr/bin/env bash
# STDLIB/scripts/run_mathesis.sh -- S8 ownership shim: the MATHESIS family runner lives at
# STDLIB/sovir/run_mathesis.sh (its campaign home); run_corpus.sh's S8 manifest teeth require
# every cited family runner to exist beside the manifest, so this shim delegates.
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../sovir/run_mathesis.sh" "$@"
