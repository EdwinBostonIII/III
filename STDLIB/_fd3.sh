#!/usr/bin/env bash
set -u
cd "C:/Users/Edwin Boston/OneDrive/Desktop/III" || exit 99
I="$(pwd)/COMPILED/iiis-2.exe"
IIIS="$I" bash STDLIB/scripts/build_stdlib.sh > /tmp/fd3_build.log 2>&1
echo "build rc=$? $(grep -oE 'FAIL = [0-9]+' /tmp/fd3_build.log|tail -1)"
IIIS="$I" bash STDLIB/scripts/run_corpus.sh > /tmp/fd3_corpus.log 2>&1
echo "corpus rc=$? $(grep -E 'PASS=' /tmp/fd3_corpus.log|tail -1)"
grep -E '1211_commons_cite_reuse|1210_commons_feed' /tmp/fd3_corpus.log
echo "=== FD3 DONE ==="
