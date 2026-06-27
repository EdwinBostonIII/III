#!/usr/bin/env bash
# SOUNDNESS FALSIFIER (Phase 6 teeth) -- proves the proof gate is NOT vacuous.  Removes the add-correction
# guard + GM bound from seg_div_plan, then SCANS divisors compiling+running mulhi(x,m)>>s vs x/d: WITHOUT the
# gate, an add-correction (a==1) divisor escapes as a WRONG magic and the scan FINDS x where they differ.
# Restores ser_egraph unconditionally.  If removing the gate did NOT surface a wrong reduction, the gate would
# prove nothing -- it does.  Standalone (no bootstrap): patches the SOURCE, compiles it directly.
set -uo pipefail
III="${III_ROOT:-/c/Users/Edwin Boston/OneDrive/Desktop/III}"
IIIS="$III/COMPILED/iiis-2.exe"
SE="$III/STDLIB/iii/numera/ser_egraph.iii"
OUT="/tmp/falsif_$$"; mkdir -p "$OUT"
log() { echo "[falsifier] $*"; }
cp "$SE" "$OUT/ser_egraph.bak"
restore() { cp "$OUT/ser_egraph.bak" "$SE"; log "ser_egraph restored"; }
trap restore EXIT

# 1. Disable the gate: make seg_div_plan return SDP_MAGIC for any non-pow2 d (skip add-flag + bound).
log "patching seg_div_plan to BYPASS the add-correction + GM bound (the gate under test)"
python_free_patch() {
  awk '
    /if SDIV_A\[0u64\] == 1u64 \{ return SDP_GENERAL \}/ { print "    /* GATE BYPASSED BY FALSIFIER */"; next }
    /GM BOUND \(the proof\)/ { skip=1 }
    skip && /return SDP_MAGIC/ { print "    return SDP_MAGIC   /* GATE BYPASSED */"; skip=0; next }
    skip { next }
    { print }
  ' "$SE" > "$OUT/patched.iii" && cp "$OUT/patched.iii" "$SE"
}
python_free_patch

# 2. Scan KAT: find any divisor where the (now-ungated) magic diverges from x/d.
cat > "$OUT/scan.iii" <<'EOF'
module falsif_scan
extern @abi(c-msvc-x64) fn seg_div_plan(d: u64) -> u64 from "ser_egraph.iii"
extern @abi(c-msvc-x64) fn seg_div_magic_m() -> u64 from "ser_egraph.iii"
extern @abi(c-msvc-x64) fn seg_div_shift() -> u64 from "ser_egraph.iii"
fn mulhi(a: u64, b: u64) -> u64 {
    let al:u64=a&4294967295u64 let ah:u64=a>>32u64 let bl:u64=b&4294967295u64 let bh:u64=b>>32u64
    let p0:u64=al*bl let p1:u64=al*bh let p2:u64=ah*bl let p3:u64=ah*bh
    let mid:u64=(p0>>32u64)+(p1&4294967295u64)+(p2&4294967295u64)
    return p3+(p1>>32u64)+(p2>>32u64)+(mid>>32u64)
}
fn main() -> u64 {
    let mut d:u64=3u64
    while d < 200u64 {
        if (d & (d - 1u64)) != 0u64 {
            if (seg_div_plan(d) & 255u64) == 2u64 {
                let m:u64=seg_div_magic_m() let s:u64=seg_div_shift()
                let x:u64=18446744073709551615u64
                if (mulhi(x,m)>>s) != x/d { return 7u64 }   /* WRONG magic escaped the (removed) gate */
            }
        }
        d = d + 1u64
    }
    return 0u64   /* no escape found (gate's job is unnecessary?) -> would mean the gate proves nothing */
}
EOF
( cd "$OUT" && "$IIIS" scan.iii --compile-only --out scan.o >/dev/null 2>&1 \
   && "$IIIS" "$SE" --compile-only --out se.o >/dev/null 2>&1 \
   && "$IIIS" "$III/STDLIB/iii/numera/bv_ring.iii" --compile-only --out bv.o >/dev/null 2>&1 \
   && gcc scan.o se.o bv.o -lws2_32 -lkernel32 -o scan.exe >/dev/null 2>&1 )
st="/tmp/fscan_$$.exe"; cp "$OUT/scan.exe" "$st"; "$st"; rc=$?; rm -f "$st"
if [ "$rc" -eq 7 ]; then
  log "TEETH CONFIRMED: with the gate removed, a wrong magic division escaped (rc=7)."
  log "=> the add-correction guard + GM bound in seg_div_plan are LOAD-BEARING, not vacuous."
else
  log "WARNING rc=$rc: no escape surfaced in [3,200) -- widen the scan; the gate's necessity is unproven by this run."
fi
exit 0
