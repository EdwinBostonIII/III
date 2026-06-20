#!/usr/bin/env bash
set -u
cd "C:/Users/Edwin Boston/OneDrive/Desktop/III" || exit 99
R="$(pwd)"; I="$R/COMPILED/iiis-2.exe"
echo "=== WHOLE SYSTEM RUN ==="
IIIS="$I" bash STDLIB/scripts/build_stdlib.sh > /tmp/w_build.log 2>&1; echo "build rc=$? $(grep -oE 'FAIL = [0-9]+' /tmp/w_build.log|tail -1) lib=$(cut -d' ' -f1 STDLIB/build/iii/libiii_native.a.mhash)"; sleep 5
IIIS="$I" bash STDLIB/scripts/run_corpus.sh > /tmp/w_corpus.log 2>&1; echo "corpus rc=$? $(grep -E 'PASS=' /tmp/w_corpus.log|tail -1)"; grep -E '121[0-2]_' /tmp/w_corpus.log; sleep 3
IIIS="$I" bash STDLIB/scripts/run_xii_corpus.sh > /tmp/w_xii.log 2>&1; echo "xii rc=$? $(grep -E 'PASS=' /tmp/w_xii.log|tail -1)"; sleep 3
IIIS="$I" bash STDLIB/scripts/run_nous_corpus.sh > /tmp/w_nous.log 2>&1; echo "nous rc=$? $(grep -E 'GREEN|RUN_NOUS' /tmp/w_nous.log|tail -1)"; sleep 3
IIIS="$I" bash COMPILER/BOOT/cg_seam_gate.sh > /tmp/w_seam.log 2>&1; echo "seam rc=$? $(grep -E 'PASS=' /tmp/w_seam.log|tail -1)"; sleep 5
bash COMPILER/BOOT/build_iiis2.sh --check-corpus > /tmp/w_self.log 2>&1; echo "selfhost rc=$? iiis2=$(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash)"; grep -E 'corpus equivalence|do_thing.*21|cg_r0-gate. PASS=|cg_r0-wgate. PASS=' /tmp/w_self.log|head; sleep 3
IIIS="$I" bash STDLIB/scripts/verify_h2_one_address.sh > /tmp/w_h2.log 2>&1; echo "h2 rc=$? $(grep -iE 'HOLDS|FAIL' /tmp/w_h2.log|tail -1)"
IIIS="$I" bash STDLIB/scripts/audit_sovereign.sh > /tmp/w_sov.log 2>&1; echo "sovereign rc=$?"
IIIS="$I" bash STDLIB/scripts/verify_sha256_dedup.sh > /tmp/w_dedup.log 2>&1; echo "dedup rc=$? $(grep -iE 'OK|FAIL' /tmp/w_dedup.log|tail -1)"
bash COMPILER/BOOT/trusted_base_check.sh > /tmp/w_tb.log 2>&1; echo "trusted_base rc=$? $(grep -iE 'OK.*ROOT|FAIL' /tmp/w_tb.log|tail -1)"
echo "=== WHOLE SYSTEM DONE ==="
