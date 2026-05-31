#!/usr/bin/env bash
# STDLIB/scripts/ripple_extract.sh -- the Topological Extraction EXECUTOR (Phase B2).
#
# Writes a NEW .iii file = an H10 ORIGIN CERTIFICATE header + the extracted payload, registers it
# in build_stdlib's MODULES, and proves the post-state green through GATE0-3; KEEPS iff every gate
# passes, else atomically REVERTS (deletes the new file + removes its MODULES registration +
# rebuilds the library from the good source).  This is Inc 5's inductive safety invariant extended
# from EDIT to CREATION: the tree is verified-green BEFORE and AFTER, so III is never left broken.
#
# Topological Extraction only: the payload must already be proven (B1's rx_certify_extract -- C1
# capability conservation, C2 MDL boundary penalty, C3 acyclic insertion, C4 H10). This tool is the
# impure EXECUTOR; the .iii decider is the pure proof.  The H10 stamp in the header is the witnessed
# intent marker -- the Sovereign Ripple Loop reads it and ABSTAINS from merging the file back
# (anti-thrashing).  The Proposer guesses the file's name; the Decider attaches it to the
# content-addressed (cad) proven payload.
#
# Usage: ripple_extract.sh <subsphere> <leaf> <payload_file> <pass> <congruence> <delta_j>
#   payload_file = a valid .iii module body (its `module` decl + the extracted functions).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
GOLDEN_IIIS="196b0c5f5159329b2e419aecb561ee57980d62bcc892ea84f260559bcdfaa990"
BS="$ROOT/STDLIB/scripts/build_stdlib.sh"

SUBSPHERE="$1"; LEAF="$2"; PAYLOAD="$3"; PASS="$4"; CONG="$5"; DJ="$6"
NEWFILE="$ROOT/STDLIB/iii/$SUBSPHERE/$LEAF.iii"
MODKEY="$SUBSPHERE/$LEAF"

if [ -e "$NEWFILE" ]; then echo "[ripple_extract] FATAL: $NEWFILE already exists" >&2; exit 1; fi
if [ ! -f "$PAYLOAD" ]; then echo "[ripple_extract] FATAL: no payload $PAYLOAD" >&2; exit 1; fi

PCAD="$(sha256sum "$PAYLOAD" | cut -d' ' -f1)"

# --- compose F = H10 Origin Certificate header + the extracted payload ---
{
  echo "/* H10 ORIGIN CERTIFICATE -- Topological Extraction (a witnessed relocation of proven"
  echo " * shared logic; NOT generative synthesis)."
  echo " *   extracted on pass $PASS ; cross-module congruence: {$CONG} ; delta-J: +$DJ"
  echo " *   payload content-address (cad): $PCAD"
  echo " * The Sovereign Ripple Loop reads this stamp and ABSTAINS from merging this file back"
  echo " * into its parents -- the anti-thrashing witness (the H10 intent marker). */"
  cat "$PAYLOAD"
} > "$NEWFILE"

# --- GATE 0 (fast, pre-registration): the new file must compile standalone ---
echo "[ripple_extract] GATE 0: standalone compile of new file $MODKEY"
if ! "$IIIS" "$NEWFILE" --compile-only --out /tmp/re_new.o > /tmp/re_g0.log 2>&1; then
    echo "[ripple_extract] REJECT @GATE0 (new file does not compile) -> rm (nothing was registered)"
    rm -f "$NEWFILE"; exit 2
fi

# --- register the new module in MODULES (insert before the array's closing paren) ---
bs_bak="$(mktemp)"; cp "$BS" "$bs_bak"
awk -v key="    \"$MODKEY\"" '
    /^MODULES=\(/ { inm=1 }
    inm && /^\)/  { print key; inm=0 }
    { print }
' "$bs_bak" > "$BS"
revert() { rm -f "$NEWFILE"; cp "$bs_bak" "$BS"; rm -f "$bs_bak"; bash "$BS" > /tmp/re_revert.log 2>&1; }

# --- GATE 1: the whole library still builds (FAIL = 0) with the new module ---
echo "[ripple_extract] GATE 1: build_stdlib (FAIL=0)"
if ! bash "$BS" > /tmp/re_bs.log 2>&1 || ! grep -q 'FAIL = 0' /tmp/re_bs.log; then
    echo "[ripple_extract] REJECT @GATE1 (build_stdlib / cartographer) -> revert (rm + unregister)"
    revert; exit 3
fi
# --- GATE 2: LIBNATIVE -- the bootstrap compiler is byte-unchanged ---
echo "[ripple_extract] GATE 2: compiler unchanged (LIBNATIVE)"
i2="$(sha256sum "$ROOT/COMPILED/iiis-2.exe" | cut -d' ' -f1)"
if [ "$i2" != "$GOLDEN_IIIS" ]; then echo "[ripple_extract] REJECT @GATE2 (compiler drift) -> revert"; revert; exit 4; fi
# --- GATE 3: zero behavioral regression across the full corpus ---
echo "[ripple_extract] GATE 3: full corpus (FAIL=0)"
if ! bash "$ROOT/STDLIB/scripts/run_corpus.sh" > /tmp/re_rc.log 2>&1 || ! grep -qE 'FAIL=0' /tmp/re_rc.log; then
    echo "[ripple_extract] REJECT @GATE3 (corpus regression) -> revert"; revert; exit 5
fi

echo "[ripple_extract] KEEP -- new file $MODKEY written + verified green. lib mhash: $(awk '{print $1}' "$ROOT/STDLIB/build/iii/libiii_native.a.mhash")"
rm -f "$bs_bak"
exit 0
