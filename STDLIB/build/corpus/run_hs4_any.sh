#!/usr/bin/env bash
# V1 Stage 5 — generic 4-node HotStuff harness driver.
# Usage: bash run_hs4_any.sh <coordinator.iii>   (default: lockstep coordinator)
set -u
ROOT="/c/Users/Edwin Boston/OneDrive/Desktop/III"
cd "$ROOT" || exit 2
IIIS="COMPILED/iiis-2.exe"
LIB="STDLIB/build/iii/libiii_native.a"
COORD="${1:-STDLIB/build/corpus/_hs4_coord.iii}"
"$IIIS" STDLIB/build/corpus/_hs4_node.iii --compile-only --out /tmp/ha_node.o || { echo "node compile FAIL"; exit 3; }
"$IIIS" "$COORD"                          --compile-only --out /tmp/ha_coord.o || { echo "coord compile FAIL"; exit 3; }
gcc /tmp/ha_node.o  "$LIB" -lws2_32 -lkernel32 -lmsvcrt -o /tmp/ha_node.exe  || { echo "node link FAIL";  exit 4; }
gcc /tmp/ha_coord.o "$LIB" -lws2_32 -lkernel32 -lmsvcrt -o /tmp/ha_coord.exe || { echo "coord link FAIL"; exit 4; }
cp /tmp/ha_coord.exe /tmp/ha_coord_run.exe
cp /tmp/ha_node.exe  /tmp/ha_node_run.exe
echo "[hs4] $COORD : starting coordinator + 4 nodes..."
/tmp/ha_coord_run.exe & CPID=$!
/tmp/ha_node_run.exe & N1=$!
/tmp/ha_node_run.exe & N2=$!
/tmp/ha_node_run.exe & N3=$!
/tmp/ha_node_run.exe & N4=$!
wait $CPID
CRC=$?
echo "[hs4] coordinator exit=$CRC"
kill $N1 $N2 $N3 $N4 2>/dev/null
wait $N1 $N2 $N3 $N4 2>/dev/null
exit $CRC
