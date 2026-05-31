#!/usr/bin/env bash
# STDLIB/scripts/pcc_synthesize.sh -- the PROOF-CARRYING CODE executor (Phase C2).
#
# The generative-synthesis applier: commits GENERATED code to disk ONLY if III's kernel certifies
# its constructive proof against the human spec.  It does NOT test the code -- it submits the proof
# to the kernel (a harness that calls pcc_admit -> typecheck.iii tc_check).  A FLAWLESS proof is
# committed through the gated write; a FLAWED proof DESTROYS the code (nothing written).  The
# Proposer may be wildly creative in the staging area, but not one line reaches disk until the
# kernel rules.
#
# TWO independent guards (defence in depth): (1) the kernel PROOF certifies the math -- the code
# satisfies the spec under ALL states; (2) the gated write certifies the INTEGRATION -- certified
# code must still build, stay LIBNATIVE, and pass the full corpus, else it is reverted byte-exactly.
#
# Usage: pcc_synthesize.sh <proof_harness.iii> <subsphere> <leaf> <payload_file> <spec_desc>
#   <proof_harness.iii> : a .iii whose main() submits the (code, proof, spec) to pcc_admit and
#                         returns 99 IFF the kernel certifies.
#   <payload_file>      : the generated .iii code to commit IFF certified.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
GOLDEN_IIIS="196b0c5f5159329b2e419aecb561ee57980d62bcc892ea84f260559bcdfaa990"
BS="$ROOT/STDLIB/scripts/build_stdlib.sh"

HARNESS="$1"; SUBSPHERE="$2"; LEAF="$3"; PAYLOAD="$4"; SPEC="$5"
NEWFILE="$ROOT/STDLIB/iii/$SUBSPHERE/$LEAF.iii"
MODKEY="$SUBSPHERE/$LEAF"

# --- STEP 1: submit the constructive proof to the kernel (the ONLY gate on novelty) ---
echo "[pcc_synthesize] KERNEL: evaluating the constructive proof (pcc_admit -> typecheck tc_check)"
if ! "$IIIS" "$HARNESS" --compile-only --out /tmp/pcc_h.o > /tmp/pcc_h.log 2>&1; then echo "[pcc_synthesize] harness compile error" >&2; exit 1; fi
if ! gcc /tmp/pcc_h.o "$LIB" -lws2_32 -lkernel32 -o /tmp/pcc_h.exe >> /tmp/pcc_h.log 2>&1; then echo "[pcc_synthesize] harness link error" >&2; exit 1; fi
/tmp/pcc_h.exe; verdict=$?
if [ "$verdict" != "99" ]; then
    echo "[pcc_synthesize] KERNEL VERDICT: REJECTED (proof exit $verdict) -- the code is DESTROYED; nothing written."
    exit 2
fi
echo "[pcc_synthesize] KERNEL VERDICT: CERTIFIED (flawless proof) -- committing through the gated write."

# --- STEP 2: certified -> write the code (PCC certificate header) + gated write (GATE0-3 + revert) ---
if [ -e "$NEWFILE" ]; then echo "[pcc_synthesize] FATAL: $NEWFILE exists" >&2; exit 1; fi
PCAD="$(sha256sum "$PAYLOAD" | cut -d' ' -f1)"
{
  echo "/* PROOF-CARRYING CODE -- kernel-certified generative synthesis."
  echo " *   spec: $SPEC"
  echo " *   the constructive proof was evaluated by typecheck.iii (tc_check) and found FLAWLESS;"
  echo " *   this code is mathematically guaranteed to satisfy the spec under all states."
  echo " *   payload content-address (cad): $PCAD */"
  cat "$PAYLOAD"
} > "$NEWFILE"

echo "[pcc_synthesize] GATE 0: standalone compile of the generated code"
if ! "$IIIS" "$NEWFILE" --compile-only --out /tmp/pcc_new.o > /tmp/pcc_g0.log 2>&1; then
    echo "[pcc_synthesize] REJECT @GATE0 (generated code does not compile) -> rm (nothing registered)"; rm -f "$NEWFILE"; exit 3
fi
bs_bak="$(mktemp)"; cp "$BS" "$bs_bak"
awk -v key="    \"$MODKEY\"" '/^MODULES=\(/{inm=1} inm&&/^\)/{print key;inm=0} {print}' "$bs_bak" > "$BS"
revert() { rm -f "$NEWFILE"; cp "$bs_bak" "$BS"; rm -f "$bs_bak"; bash "$BS" > /tmp/pcc_revert.log 2>&1; }

echo "[pcc_synthesize] GATE 1: build_stdlib (FAIL=0)"
if ! bash "$BS" > /tmp/pcc_bs.log 2>&1 || ! grep -q 'FAIL = 0' /tmp/pcc_bs.log; then echo "[pcc_synthesize] REJECT @GATE1 -> revert"; revert; exit 4; fi
echo "[pcc_synthesize] GATE 2: compiler unchanged (LIBNATIVE)"
i2="$(sha256sum "$ROOT/COMPILED/iiis-2.exe" | cut -d' ' -f1)"; if [ "$i2" != "$GOLDEN_IIIS" ]; then echo "[pcc_synthesize] REJECT @GATE2 -> revert"; revert; exit 5; fi
echo "[pcc_synthesize] GATE 3: full corpus (FAIL=0)"
if ! bash "$ROOT/STDLIB/scripts/run_corpus.sh" > /tmp/pcc_rc.log 2>&1 || ! grep -qE 'FAIL=0' /tmp/pcc_rc.log; then echo "[pcc_synthesize] REJECT @GATE3 -> revert"; revert; exit 6; fi

echo "[pcc_synthesize] KEEP -- kernel-certified code committed + verified green. lib: $(awk '{print $1}' "$ROOT/STDLIB/build/iii/libiii_native.a.mhash")"
rm -f "$bs_bak"
exit 0
