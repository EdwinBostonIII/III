#!/usr/bin/env bash
# COMPILER/BOOT/covenant_ceremony.sh -- THE COVENANT CEREMONY (the mandatory
# rebuild road after ANY parliament chamber adopts: NOMOS rewrite law or GLOSSA
# vocabulary).  stdlib -> iiis-2 double-build determinism -> iiis-3 fixpoint ->
# reseal goldens.  The verification surfaces (run_corpus.sh with the standing
# arms + iii-ergon census [ex run_standing_tools.sh, retired] + run_meaning.sh) are launched SEPARATELY after
# this core holds: they are hours-long judges, and this script's contract is
# the byte-seal itself.
#
# LAW: never run while a corpus / meaning instance is live -- they link the
# archive and invoke iiis-2.exe continuously (the shared-staging and hot-binary
# traps).  Caller checks; this script re-checks loudly.
#
# Exit: 0 covenant core GREEN | 2 env | 3 stdlib red | 4 compiler build red
#     | 5 determinism broken | 6 fixpoint broken | 7 hot-tree refusal
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT" || exit 2
TAG="[covenant]"
log() { printf '%s %s\n' "$TAG" "$*"; }

if ps -ef 2>/dev/null | grep -E "[r]un_corpus|[r]un_meaning" >/dev/null; then
    log "REFUSED: a corpus/meaning judge is live (archive + iiis-2 are hot) -- wait for it"
    exit 7
fi

log "[1] stdlib (the archive absorbs any newly sealed organs)"
bash STDLIB/scripts/build_stdlib.sh > COMPILED/_covenant_stdlib.log 2>&1
rc=$?
grep -E "FAIL = " COMPILED/_covenant_stdlib.log | tail -1
if [ $rc -ne 0 ]; then log "STDLIB_RC=$rc RED -- stop"; exit 3; fi
grep -q "FAIL = 0" COMPILED/_covenant_stdlib.log || { log "stdlib FAIL!=0 -- stop (the stale-lib mask trap)"; exit 3; }
log "STDLIB green"

log "[2] iiis-2 build A"
bash COMPILER/BOOT/build_iiis2.sh --mode release > COMPILED/_covenant_b2a.log 2>&1
rc=$?
[ $rc -ne 0 ] && { log "B2A_RC=$rc RED -- stop"; tail -5 COMPILED/_covenant_b2a.log; exit 4; }
M1=$(grep -o "mhash: [0-9a-f]*" COMPILED/_covenant_b2a.log | tail -1 | awk '{print $2}')
log "B2A mhash=$M1"

log "[3] iiis-2 build B (determinism)"
bash COMPILER/BOOT/build_iiis2.sh --mode release > COMPILED/_covenant_b2b.log 2>&1
rc=$?
[ $rc -ne 0 ] && { log "B2B_RC=$rc RED -- stop"; exit 4; }
M2=$(grep -o "mhash: [0-9a-f]*" COMPILED/_covenant_b2b.log | tail -1 | awk '{print $2}')
log "B2B mhash=$M2"
if [ -z "$M1" ] || [ "$M1" != "$M2" ]; then log "DETERMINISM BROKEN ($M1 vs $M2) -- stop"; exit 5; fi
log "DETERMINISM HOLDS"
printf '%s\n' "$M1" > COMPILER/BOOT/iiis-2.mhash

log "[4] iiis-3 (the fixpoint)"
bash COMPILER/BOOT/build_iiis3.sh --mode release > COMPILED/_covenant_b3.log 2>&1
rc=$?
[ $rc -ne 0 ] && { log "B3_RC=$rc RED -- stop"; tail -5 COMPILED/_covenant_b3.log; exit 6; }
if cmp -s COMPILED/iiis-2.exe COMPILED/iiis-3.exe; then
    log "FIXPOINT HOLDS: iiis-2 == iiis-3 byte-for-byte"
    printf '%s\n' "$M1" > COMPILER/BOOT/iiis-3.mhash
else
    log "FIXPOINT BROKEN -- stop"
    exit 6
fi
log "COVENANT CORE GREEN (mhash $M1) -- now run the judges: run_corpus.sh, iii-ergon census (the standing fleet, ex run_standing_tools -- retired 2026-07-17), run_meaning.sh"
exit 0
