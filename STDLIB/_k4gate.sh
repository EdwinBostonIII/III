#!/usr/bin/env bash
set -u
cd "C:/Users/Edwin Boston/OneDrive/Desktop/III" || exit 99
R="$(pwd)"; I="$R/COMPILED/iiis-2.exe"; G=8
echo "=== K4 RESEAL GATE (sign-aware cast-extend; seed re-root) ==="
bash COMPILER/BOOT/build_iiis0.sh > /tmp/k_i0.log 2>&1; echo "i0 rc=$? -> $(cut -d' ' -f1 COMPILED/iiis-0.exe.mhash 2>/dev/null)"; sleep $G
bash COMPILER/BOOT/build_iiis1.sh > /tmp/k_i1.log 2>&1; echo "i1 rc=$? -> $(cut -d' ' -f1 COMPILED/iiis-1.exe.mhash 2>/dev/null)"; sleep $G
bash COMPILER/BOOT/build_iiis2.sh --check-corpus > /tmp/k_i2.log 2>&1; echo "i2 rc=$? -> $(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash 2>/dev/null)"; grep -E 'corpus equivalence|do_thing.*21|cg_r0-gate. PASS=|cg_r0-wgate. PASS=|FAIL' /tmp/k_i2.log | head; sleep $G
bash COMPILER/BOOT/build_iiis3.sh > /tmp/k_i3.log 2>&1; echo "i3 rc=$? -> $(cut -d' ' -f1 COMPILED/iiis-3.exe.mhash 2>/dev/null)"; sleep $G
IIIS="$I" bash STDLIB/scripts/build_stdlib.sh > /tmp/k_build.log 2>&1; echo "stdlib rc=$? $(grep -oE 'FAIL = [0-9]+' /tmp/k_build.log|tail -1)"; sleep $G
IIIS="$I" bash STDLIB/scripts/run_corpus.sh > /tmp/k_corpus.log 2>&1; echo "corpus rc=$? $(grep -E 'PASS=' /tmp/k_corpus.log|tail -1)"; echo "--- reddened (if any) ---"; grep -E 'WRONG' /tmp/k_corpus.log | head; echo "--- key KATs ---"; grep -E '1113_|1114_|1207_|121[0-2]_' /tmp/k_corpus.log; sleep 3
IIIS="$I" bash STDLIB/scripts/run_xii_corpus.sh > /tmp/k_xii.log 2>&1; echo "xii rc=$? $(grep -E 'PASS=' /tmp/k_xii.log|tail -1)"; sleep 3
IIIS="$I" bash STDLIB/scripts/run_nous_corpus.sh > /tmp/k_nous.log 2>&1; echo "nous rc=$? $(grep -E 'GREEN|RUN_NOUS' /tmp/k_nous.log|tail -1)"; sleep 3
IIIS="$I" bash COMPILER/BOOT/cg_seam_gate.sh > /tmp/k_seam.log 2>&1; echo "seam rc=$? $(grep -E 'PASS=' /tmp/k_seam.log|tail -1)"
echo "=== K4 DONE === i0=$(cut -d' ' -f1 COMPILER/BOOT/iiis-0.mhash) i1=$(cut -d' ' -f1 COMPILED/iiis-1.exe.mhash) i2=$(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash) i3=$(cut -d' ' -f1 COMPILED/iiis-3.exe.mhash)"
