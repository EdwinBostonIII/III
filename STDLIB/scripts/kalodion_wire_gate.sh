#!/usr/bin/env bash
# kalodion_wire_gate.sh -- THE LIVE WIRE RITE: the membrane's producer run
# over a REAL TCP socket.
#
# The census proves the framing law PURELY (kalodion 405..409, no I/O).  This
# gate proves the last line -- that a live connection's bytes reach the framer
# -- against an ACTUAL localhost peer: real capabilities minted, a real socket
# carrying real records, the SAME door judging them (the torn reconnect line
# heard as UNHEARD).  Network I/O lives HERE, in a gate, never in the census
# condition-of-motion (which must stay pure and never flake).  This mirrors
# the tree's existing law/gate split (summit gate vs census).
#
# Exit 0 = the wire ran and the door judged; non-zero = the failed stage.
# A listen/connect failure (a locked-down or network-denied box) exits 5/6
# with a NAMED reason -- never a silent pass.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/kalodion"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
cd "$ROOT"

[ -x "$IIIS" ] || { echo "[wire_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[wire_gate] no archive: $ARC"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[wire_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[wire_gate] COMPILE FAIL rc=$rc $(basename "$src")"
    tail -4 "$out.log"
    return 1
}

cc_one "$ROOT/STDLIB/iii/aether/kalodion.iii"   "$T/kalodion.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/aether/xenos.iii"      "$T/xenos.o"      || exit 2
cc_one "$ROOT/STDLIB/iii/aether/xring.iii"      "$T/xring.o"      || exit 2
cc_one "$ROOT/STDLIB/iii/aether/net.iii"        "$T/net.o"        || exit 2
cc_one "$ROOT/STDLIB/iii/aether/capability.iii" "$T/capability.o" || exit 2
cc_one "$ROOT/STDLIB/iii/aether/handle.iii"     "$T/handle.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"     "$T/eidolos.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"        "$T/isub.o"       || exit 2
cc_one "$ROOT/STDLIB/iii/verba/lexicon.iii"     "$T/lexicon.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/verba/json.iii"        "$T/json.o"       || exit 2
cc_one "$ROOT/STDLIB/iii/verba/builder.iii"     "$T/builder.o"    || exit 2
cc_one "$ROOT/STDLIB/iii/memoria/arena.iii"     "$T/arena.o"      || exit 2
cc_one "$ROOT/STDLIB/build/kalodion/klwire_main.iii" "$T/klwire_main.o" || exit 2

gcc -o "$T/klwire.exe" \
    "$T/klwire_main.o" "$T/kalodion.o" "$T/xenos.o" "$T/xring.o" \
    "$T/net.o" "$T/capability.o" "$T/handle.o" \
    "$T/eidolos.o" "$T/isub.o" "$T/lexicon.o" "$T/json.o" "$T/builder.o" "$T/arena.o" \
    "$ARC" -lws2_32 -lkernel32 \
    || { echo "[wire_gate] LINK FAIL"; exit 3; }

rm -f "$ROOT/STDLIB/data/xenos.gbk"
"$T/klwire.exe" > "$T/wire.txt" 2>&1
rc=$?
cat "$T/wire.txt"
if [ "$rc" -ne 0 ]; then
    echo "[wire_gate] WIRE RED rc=$rc"
    exit 4
fi
grep -q "^THE LIVE WIRE RAN:" "$T/wire.txt" || { echo "[wire_gate] no wire confirmation"; exit 6; }
echo "[wire_gate] THE LIVE WIRE IS GREEN -- a real TCP socket fed the vein and the door judged it."
exit 0
