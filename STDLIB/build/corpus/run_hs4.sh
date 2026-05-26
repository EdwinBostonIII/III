#!/usr/bin/env bash
# V1 Stage 5 — 4-node HotStuff socket harness driver.
# Compiles + links the node and coordinator against libiii_native.a, stages
# them to /tmp (AV-path discipline), starts the coordinator (the test network),
# then 4 node instances (each running aether/hotstuff.iii).  The coordinator
# drives N_BLOCKS rounds and exits 99 iff all four nodes commit the same
# block_mhash at every height (lockstep).
#
# Usage: bash run_hs4.sh
# Exit: coordinator's exit code (99 = lockstep pass).
set -u
ROOT="/c/Users/Edwin Boston/OneDrive/Desktop/III"
cd "$ROOT" || exit 2
IIIS="COMPILED/iiis-2.exe"
LIB="STDLIB/build/iii/libiii_native.a"
ND="STDLIB/build/corpus/_hs4_node.iii"
CD="STDLIB/build/corpus/_hs4_coord.iii"

echo "[hs4] compiling node + coordinator..."
"$IIIS" "$ND" --compile-only --out /tmp/hs4node.o  || { echo "node compile FAIL"; exit 3; }
"$IIIS" "$CD" --compile-only --out /tmp/hs4coord.o || { echo "coord compile FAIL"; exit 3; }
gcc /tmp/hs4node.o  "$LIB" -lws2_32 -lkernel32 -lmsvcrt -o /tmp/hs4node.exe  || { echo "node link FAIL";  exit 4; }
gcc /tmp/hs4coord.o "$LIB" -lws2_32 -lkernel32 -lmsvcrt -o /tmp/hs4coord.exe || { echo "coord link FAIL"; exit 4; }
cp /tmp/hs4coord.exe /tmp/hs4coord_run.exe
cp /tmp/hs4node.exe  /tmp/hs4node_run.exe

echo "[hs4] starting coordinator + 4 nodes..."
/tmp/hs4coord_run.exe & CPID=$!
/tmp/hs4node_run.exe & N1=$!
/tmp/hs4node_run.exe & N2=$!
/tmp/hs4node_run.exe & N3=$!
/tmp/hs4node_run.exe & N4=$!
wait $CPID
CRC=$?
echo "[hs4] coordinator exit=$CRC  (99 = all heights lockstep)"
# nodes exit on DONE; reap any stragglers
kill $N1 $N2 $N3 $N4 2>/dev/null
wait $N1 $N2 $N3 $N4 2>/dev/null
exit $CRC
