#!/usr/bin/env bash
# STDLIB/scripts/run_event_waist.sh -- S8 ownership shim: the EVENT-PRIMARY WAIST family runner
# lives at STDLIB/sovir/run_event_waist.sh (its campaign home); run_corpus.sh's S8 manifest teeth
# require every cited family runner to exist beside the manifest, so this shim delegates.
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../sovir/run_event_waist.sh" "$@"
