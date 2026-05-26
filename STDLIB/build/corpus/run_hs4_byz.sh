#!/usr/bin/env bash
# V1 Stage 5 — Byzantine-safety harness driver (node 3 sends conflicting votes).
set -u
ROOT="/c/Users/Edwin Boston/OneDrive/Desktop/III"
cd "$ROOT" || exit 2
IIIS="COMPILED/iiis-2.exe"
LIB="STDLIB/build/iii/libiii_native.a"
"$IIIS" STDLIB/build/corpus/_hs4_node.iii      --compile-only --out /tmp/hb_node.o  || { echo "node compile FAIL"; exit 3; }
"$IIIS" STDLIB/build/corpus/_hs4_coord_byz.iii --compile-only --out /tmp/hb_coord.o || { echo "coord compile FAIL"; exit 3; }
gcc /tmp/hb_node.o  "$LIB" -lws2_32 -lkernel32 -lmsvcrt -o /tmp/hb_node.exe  || { echo "node link FAIL";  exit 4; }
gcc /tmp/hb_coord.o "$LIB" -lws2_32 -lkernel32 -lmsvcrt -o /tmp/hb_coord.exe || { echo "coord link FAIL"; exit 4; }
cp /tmp/hb_coord.exe /tmp/hb_coord_run.exe
cp /tmp/hb_node.exe  /tmp/hb_node_run.exe
echo "[byz] starting coordinator + 4 nodes (node 3 Byzantine)..."
/tmp/hb_coord_run.exe & CPID=$!
/tmp/hb_node_run.exe & N1=$!
/tmp/hb_node_run.exe & N2=$!
/tmp/hb_node_run.exe & N3=$!
/tmp/hb_node_run.exe & N4=$!
wait $CPID
CRC=$?
echo "[byz] coordinator exit=$CRC  (99 = safety held; 30 = safety VIOLATED)"
kill $N1 $N2 $N3 $N4 2>/dev/null
wait $N1 $N2 $N3 $N4 2>/dev/null
exit $CRC
