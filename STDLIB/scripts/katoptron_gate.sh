#!/usr/bin/env bash
# katoptron_gate.sh -- THE MIRROR'S PRE-FLIGHT RITE, re-derived from clean objects every run.
#
# KATOPTRON (omnia/katoptron.iii) prices a compile BEFORE it is spent: it walks source bytes
# (brace depth, nested comments, strings, escapes) and derives (top-level decls, fn count, max
# LIVE declaration slots in any one fn, and the LINE that worst fn begins on).  kt_preflight
# judges that shape against the compiler's two standing walls -- the 1024-decl sema cap
# (sema.iii:292 SEMA_DECL_CAP) and the 64-slot local ceiling whose signature is a SILENT exit 14.
#
# WHY THE TEETH ARE A DIFFERENTIAL, NOT A PIN.  A stored expectation ("the ceiling is 64") tests
# only what its author foresaw, and can be edited toward.  This gate instead asks the LIVE
# compiler where its own wall is, every run, and demands the mirror agree -- at the exact
# boundary, and on the nested case where a syntactic count would be wrong.  If cg_r3 ever raises
# SEMA_DECL_CAP or the slot ceiling moves, this gate follows it without being told.
#
#   1. THE ORGAN GREEN     kt_selfprove = 0 (arms 320..324), byte-deterministic over two runs.
#   2. THE DIFFERENTIAL    on generated corpora spanning the boundary, katoptron's verdict
#                          agrees with iiis-2's ACTUAL exit status -- including the nested case
#                          (69 decls in disjoint scopes) that a syntactic sum would falsely
#                          refuse, and the flat case (65) that genuinely refuses.
#   3. THE TREE CENSUS     preflight over every .iii, reported.  INFORMATIONAL: a source that
#                          would breach is a finding about the TREE, not about the mirror, and
#                          must not redden the organ's own gate.
# Exit 0 = green; non-zero = the failed stage.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/katoptron"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"
cd "$ROOT"

[ -x "$IIIS" ] || { echo "[katoptron_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[katoptron_gate] no archive: $ARC (run build_stdlib.sh)"; exit 2; }

cc_one() {
    # settle-retry: the OneDrive/AV race is counted, never silent
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ] && [ -f "$out" ]; then
            [ "$try" -gt 1 ] && echo "[katoptron_gate] settle-retry x$((try-1)) on $(basename "$src")"
            return 0
        fi
        sleep 1
    done
    echo "[katoptron_gate] COMPILE FAIL rc=$rc $(basename "$src")"
    tail -6 "$out.log"
    return 1
}

cc_one "$ROOT/STDLIB/iii/aether/klisi.iii"        "$T/klisi.o"         || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"          "$T/isub.o"          || exit 2
cc_one "$ROOT/STDLIB/iii/numera/idfold.iii"       "$T/idfold.o"        || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"       "$T/eidolos.o"       || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/katoptron.iii"     "$T/katoptron.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/katoptron_cli.iii" "$T/katoptron_cli.o" || exit 2

rm -f "$T/katoptron.exe"
gcc -o "$T/katoptron.exe" \
    "$T/katoptron_cli.o" "$T/katoptron.o" "$T/klisi.o" "$T/eidolos.o" "$T/isub.o" "$T/idfold.o" \
    "$ARC" -lws2_32 -lkernel32 > "$T/link.log" 2>&1 \
    || { echo "[katoptron_gate] LINK FAIL"; tail -14 "$T/link.log"; exit 3; }
KT="$T/katoptron.exe"

# ---- 1. THE ORGAN GREEN, byte-deterministic --------------------------------
"$KT" prove > "$T/run1.txt" 2>&1; rc1=$?
"$KT" prove > "$T/run2.txt" 2>&1; rc2=$?
if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ]; then
    echo "[katoptron_gate] SELF-REFUSED rc1=$rc1 rc2=$rc2"; tail -8 "$T/run1.txt"; exit 4
fi
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[katoptron_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 5; }
grep -q "^KATOPTRON PROVEN" "$T/run1.txt" || { echo "[katoptron_gate] NOT PROVEN"; cat "$T/run1.txt"; exit 6; }

# ---- 2. THE DIFFERENTIAL: the mirror vs the LIVE compiler -------------------
# Corpora are generated here, so no expectation is stored anywhere; the compiler's own exit
# status is the answer key, asked fresh every run.
D="$T/diff"; rm -rf "$D"; mkdir -p "$D"
gen_flat() {   # $1 = count of flat lets in one fn
    { echo "module g$1"; echo "fn big() -> u64 {"
      i=0; while [ "$i" -lt "$1" ]; do echo "    let a$i : u64 = ${i}u64"; i=$((i+1)); done
      echo "    return a0"; echo "}"; } > "$D/flat$1.iii"
}
gen_nested() { # $1 = lets per scope, in two DISJOINT scopes (max live ~= $1+1)
    { echo "module n$1"; echo "fn big() -> u64 {"; echo "    let r : u64 = 0u64"
      echo "    if r == 0u64 {"
      i=0; while [ "$i" -lt "$1" ]; do echo "        let a$i : u64 = ${i}u64"; i=$((i+1)); done
      echo "        r = a0"; echo "    }"
      echo "    if r == 0u64 {"
      i=0; while [ "$i" -lt "$1" ]; do echo "        let b$i : u64 = ${i}u64"; i=$((i+1)); done
      echo "        r = b0"; echo "    }"
      echo "    return r"; echo "}"; } > "$D/nest$1.iii"
}
gen_decls() {  # $1 = EXACT count of top-level decls: ($1-1) consts + 1 fn
    local nc=$(( $1 - 1 ))
    { echo "module d$1"
      i=0; while [ "$i" -lt "$nc" ]; do echo "const D$i : u32 = ${i}u32"; i=$((i+1)); done
      # NOT `use` -- reserved word in .iii (as is `from`); a parse error here would masquerade
      # as a wall disagreement and make this differential test the wrong thing entirely.
      echo "fn dmain() -> u32 { return D0 }"; } > "$D/decl$1.iii"
}
gen_flat 60; gen_flat 64; gen_flat 65; gen_flat 80; gen_flat 200
gen_nested 34          # 69 decls written, ~35 ever live -- the case syntax gets wrong
gen_nested 70          # 141 written, ~71 live -- genuinely over, even scope-aware
# THE DECL WALL, differentially, AT THE RAZOR'S EDGE.  katoptron's KM_WALL is a constant it
# carries; the compiler's is SEMA_DECL_CAP.  Nothing structural keeps them equal, and a silent
# divergence is exactly how cg_r3.iii crossed the wall unnoticed.  Straddling the EXACT boundary
# (2048 accepts, 2049 refuses -- measured) catches an off-by-one in EITHER the value or the
# comparison (`>` vs `>=`), not just a gross mismatch: 2048 must clear in both, 2049 must refuse
# in both.  If SEMA_DECL_CAP ever moves and KM_WALL does not, one of these disagrees and reddens.
gen_decls 2000; gen_decls 2048; gen_decls 2049; gen_decls 2100

mismatch=0
for f in "$D"/*.iii; do
    "$IIIS" "$f" --compile-only --out "$f.o" > "$f.cc.log" 2>&1; crc=$?
    "$KT" preflight "$f" > "$f.kt.log" 2>&1;                     krc=$?
    if { [ "$crc" -eq 0 ] && [ "$krc" -ne 0 ]; } || { [ "$crc" -ne 0 ] && [ "$krc" -eq 0 ]; }; then
        echo "[katoptron_gate] DISAGREEMENT on $(basename "$f"): compiler rc=$crc, katoptron rc=$krc"
        cat "$f.kt.log"; mismatch=1
    fi
done
[ "$mismatch" -eq 0 ] || { echo "[katoptron_gate] the mirror does not match the substrate"; exit 7; }

# The boundary must actually BE a boundary -- if the compiler accepted everything, the
# differential above would pass vacuously and prove nothing.
"$IIIS" "$D/flat64.iii" --compile-only --out "$D/b64.o" >/dev/null 2>&1 || { echo "[katoptron_gate] flat64 should compile"; exit 7; }
"$IIIS" "$D/flat65.iii" --compile-only --out "$D/b65.o" >/dev/null 2>&1 && { echo "[katoptron_gate] flat65 should REFUSE -- no live boundary, differential is vacuous"; exit 7; }

# ---- 3. THE TREE CENSUS (informational) ------------------------------------
find "$ROOT/STDLIB/iii" "$ROOT/COMPILER/BOOT" -name '*.iii' 2>/dev/null | sort > "$T/allfiles.txt"
# -d '\n': this tree lives under a path with a space in it ("Edwin Boston"), and xargs' default
# whitespace splitting silently turns every path into two unopenable fragments.
xargs -a "$T/allfiles.txt" -d '\n' "$KT" preflight > "$T/census.txt" 2>&1 || true
SCANNED=$(wc -l < "$T/allfiles.txt")
UNREAD=$(grep -c '^katoptron: cannot open' "$T/census.txt" || true)
BREACH=$(grep -c '^katoptron: REFUSED' "$T/census.txt" || true)
# A census that could not READ the tree reports zero breaches, which is indistinguishable from a
# clean tree.  Refuse to present an unread census as an all-clear.
if [ "${UNREAD:-0}" -gt 0 ]; then
    echo "[katoptron_gate] CENSUS BROKEN: $UNREAD of $SCANNED sources unreadable -- a zero here would be a lie"
    grep -m3 '^katoptron: cannot open' "$T/census.txt"
    exit 8
fi

echo "[katoptron_gate] THE MIRROR IS GREEN -- self-proven, byte-deterministic, and AGREEING WITH THE"
echo "                 LIVE COMPILER at its own boundary (flat 64 clear / 65 refused; 69 nested clear):"
sed 's/^/                 /' "$T/run1.txt"
echo "                 tree census: $(wc -l < "$T/allfiles.txt") sources scanned, $BREACH would breach"
if [ "${BREACH:-0}" -gt 0 ]; then
    echo ""
    echo "                 FINDINGS (about the TREE, not the mirror -- this gate stays green):"
    grep '^katoptron: REFUSED' "$T/census.txt" | sed 's/^/                   /'
fi
exit 0
