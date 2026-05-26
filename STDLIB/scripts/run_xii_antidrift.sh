#!/usr/bin/env bash
# STDLIB/scripts/run_xii_antidrift.sh -- XII anti-drift verification suite.
# Per DOCS/III-XII.md S26.17.
#
# 8 checks, each a REAL deterministic verification of a sealed XII artifact:
#   1. Manifest mhash matches golden
#   2. Lattice replay byte-identical (deterministic regeneration)
#   3. reach6 bitmap (xii_horizon_reach)
#   4. Confluence empirical (random terms, multiple reduction orders)
#   5. Critical-pair convergence (the real 122-pair set)
#   6. MPHF collision-free
#   7. Hexad reach6 invariant / horizon metadata
#   8. Founders-Anchor signature valid
#
# Reconciliation (best-judgment, per the gospel's "navigate functional
# mismatches"): the prior version invoked `iiis --replay-lattice`,
# `--verify-anchor-signature`, `--run-critpairs-test`, etc. -- compiler
# subcommands that do not exist (iiis answers "unknown argument").  Each check
# is now wired to the actual verifier that DOES exist: the deterministic
# lattice generator (gen_xii_lattice), the XII verification corpus tests (which
# call sanctus/xii_antidrift.iii's xii_antidrift_check_* functions), and the
# standalone manifest-signature verifier (verify_xii_manifest).
#
# Three prior bugs fixed: (a) the lattice byte-equal branch never incremented
# CHECKS_PASSED; (b) check 3 had an empty body; (c) the critical-pair count was
# the 117 miscount.  route-S UPDATE: the hand-enumerated critical-pair set
# (corpus 344/371, retired) is SUPERSEDED by the structural confluence-core --
# checks 4+5 now verify root-overlap joinability (813_xii_joinability) AND
# termination (814_xii_termination), which by Newman's lemma certify the
# canonicaliser is a confluent normaliser on the reorderable set.

set -uo pipefail   # deliberately NOT -e: run all 8 checks even if one fails.
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
IIIS="${IIIS:-$REPO/COMPILED/iiis-2.exe}"
BOOT="$REPO/COMPILER/BOOT"
LIB="$REPO/STDLIB/build/iii/libiii_native.a"
COMPILED="$REPO/COMPILED"

CHECKS_PASSED=0
CHECKS_FAILED=0
ok()  { echo "[antidrift] PASS: $1"; CHECKS_PASSED=$((CHECKS_PASSED + 1)); }
nok() { echo "[antidrift] FAIL: $1"; CHECKS_FAILED=$((CHECKS_FAILED + 1)); }

# Compile+link+run an XII verification corpus test; pass iff its exit code
# matches the test's expected code (3rd arg; the XII corpus default is 0, the
# same EXPECTED-table discipline run_xii_corpus.sh uses).
corpus_check() {
    local name="$1"; local tf="$2"; local exp="${3:-0}"
    local base; base="$(basename "$tf" .iii)"
    local obj="/tmp/ad_${base}.o"; local exe="/tmp/ad_${base}.exe"
    if "$IIIS" "$REPO/STDLIB/corpus/$tf" --compile-only --out "$obj" >/dev/null 2>&1 \
       && gcc "$obj" "$LIB" -lws2_32 -lkernel32 -lmsvcrt -o "$exe" >/dev/null 2>&1; then
        cp "$exe" "${exe}.run" 2>/dev/null || true
        "${exe}.run" >/dev/null 2>&1
        if [ $? -eq "$exp" ]; then ok "$name"; else nok "$name (exit != $exp)"; fi
    else
        nok "$name (build failed)"
    fi
}

echo "[antidrift] check 1: Manifest mhash"
if [ -f "$BOOT/xii_manifest.bin" ] && [ -f "$BOOT/xii_manifest.mhash.golden" ]; then
    exp="$(tr -d '[:space:]' < "$BOOT/xii_manifest.mhash.golden")"
    act="$(sha256sum "$BOOT/xii_manifest.bin" | cut -d' ' -f1)"
    if [ "$exp" = "$act" ]; then ok "manifest mhash"; else nok "manifest drift (exp=$exp act=$act)"; fi
else
    nok "manifest (not sealed)"
fi

echo "[antidrift] check 2: Lattice replay (deterministic regeneration)"
if [ -x "$COMPILED/gen_xii_lattice" ] && [ -f "$COMPILED/xii_lattice.bin" ]; then
    rm -rf /tmp/ad_lat && mkdir -p /tmp/ad_lat/COMPILED
    if "$COMPILED/gen_xii_lattice" /tmp/ad_lat >/dev/null 2>&1 \
       && cmp -s /tmp/ad_lat/COMPILED/xii_lattice.bin "$COMPILED/xii_lattice.bin"; then
        ok "lattice replay byte-identical"
    else
        nok "lattice replay diverged"
    fi
    rm -rf /tmp/ad_lat
else
    nok "lattice (not generated)"
fi

echo "[antidrift] check 3: reach6 bitmap"
corpus_check "reach6 bitmap" "357_xii_horizon_reach.iii"

echo "[antidrift] check 4: confluence -- root-overlap joinability + residual non-join count (structural)"
corpus_check "confluence (root-overlap, structural)" "813_xii_joinability.iii" 99

echo "[antidrift] check 5: termination -- lexicographic measure strictly decreases (structural)"
corpus_check "termination (lex-triple measure)" "814_xii_termination.iii" 99

echo "[antidrift] check 6: MPHF collision-free"
corpus_check "mphf collision-free" "355_xii_mphf_construct.iii"

echo "[antidrift] check 7: hexad reach6 invariant"
corpus_check "reach6 invariant" "364_xii_horizon_metadata.iii"

echo "[antidrift] check 8: Founders-Anchor signature"
if [ -x "$COMPILED/verify_xii_manifest.exe" ] && [ -f "$BOOT/xii_manifest.bin" ]; then
    cp "$COMPILED/verify_xii_manifest.exe" /tmp/ad_vxm.exe 2>/dev/null || true
    if /tmp/ad_vxm.exe "$BOOT/xii_manifest.bin" >/dev/null 2>&1; then
        ok "anchor signature"
    else
        nok "anchor signature"
    fi
else
    nok "anchor signature (verifier or manifest missing)"
fi

echo "[antidrift] $CHECKS_PASSED passed, $CHECKS_FAILED failed"
if [ "$CHECKS_FAILED" -gt 0 ] || [ "$CHECKS_PASSED" -ne 8 ]; then exit 3; fi
echo "[antidrift] OK: all 8 checks passed"
exit 0
