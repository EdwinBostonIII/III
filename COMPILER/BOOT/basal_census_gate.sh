#!/usr/bin/env bash
# COMPILER/BOOT/basal_census_gate.sh -- THE BASAL LAW, enforced.  (bootstrap stage 7)
#
# LAW: the exact-math / crypto / algebra / geometry organs of III are BASAL --
# the toolchain's own decision and attestation substrate -- never a "subsphere"
# the spine routes around.  Prose versions of this law have failed repeatedly
# (the systems map's own reachability audit lists sound organs as LIBRARY and
# ISLAND while the spine did its arithmetic and sealing with coreutils).  This
# gate turns the law into a build-failing invariant with five measured clauses:
#
#   A  SEAL AUTHORSHIP     every spine seal script routes attestation through
#                          mhash_lib.sh (III's FIPS-KAT'd SHA-256 authors every
#                          seal; GNU sha256sum is the veto-witness)
#   B  RAW-HASH RATCHET    raw `sha256sum` invocation lines across the spine
#                          script set may only SHRINK (down-only pin): GNU-
#                          authored seals cannot silently creep back in
#   C  ALGEBRA IN CODEGEN  cg_r3's bv_ring-proven emit plans stay load-bearing
#                          (mul-by-const + shl+add certified rewrites), and all
#                          three compiler builds keep linking the prover closure
#                          (ser_egraph -> bv_ring, bv_bits -> sat) via the archive
#   D  CRYPTO PRECEDENTS   the forge keccak root (in-tree numera/keccak) and the
#                          seal_sources witness TRIANGLE (III/GNU/MS) stay wired
#   F  ISLAND BREACHES     the pinned ledger of sound-but-unwired exact organs
#                          may only SHRINK; growth without a reviewed pin edit is
#                          exactly the failure this law exists to prevent.  Each
#                          ledger line names its organ (existence-checked, so a
#                          stale ledger also fails) and its discharge path.
#
# Pins: COMPILER/BOOT/basal_census_pins.txt.  BASAL_PINS_FILE overrides the pin
# path (teeth-testing).  Raising a pin or adding a BREACH line is a reviewed
# edit of the pins file, never an implicit drift.
#
# Static: greps only, no build, sub-second.  Scoped to named dirs (never walks
# .claude or build outputs).  rc captured directly; exit 0 green, 3 clause RED,
# 2 environment/pins error.
set -u
export LC_ALL=C LANG=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT="$SCRIPT_DIR"
SCRIPTS="$III_ROOT/STDLIB/scripts"
PINS="${BASAL_PINS_FILE:-$BOOT/basal_census_pins.txt}"

log()  { printf '[basal-census] %s\n' "$*" >&2; }
red()  { log "RED: $*"; RED=1; }
RED=0

[[ -f "$PINS" ]] || { log "FATAL: pins file missing: $PINS"; exit 2; }
pin() { # pin <KEY> -> value; missing key is a pins-file error
    local v
    v="$(awk -F= -v k="$1" '$1==k{print $2; exit}' "$PINS")"
    [[ -n "$v" ]] || { log "FATAL: pin $1 absent from $PINS"; exit 2; }
    printf '%s\n' "$v"
}

# --- A: SEAL AUTHORSHIP -------------------------------------------------------
# Every spine seal script sources mhash_lib.sh and computes via mhash_file/_stdin.
SPINE=(
    "$BOOT/build_iiis0.sh"
    "$BOOT/build_iiis1.sh"
    "$BOOT/build_iiis2.sh"
    "$BOOT/build_iiis3.sh"
    "$BOOT/seed_text_identity_gate.sh"
    "$BOOT/bootstrap_from_clean.sh"
    "$BOOT/trusted_base_check.sh"
    "$SCRIPTS/build_stdlib.sh"
)
for f in "${SPINE[@]}"; do
    [[ -f "$f" ]] || { red "A: spine script missing: $f"; continue; }
    grep -q "mhash_lib\.sh" "$f" || red "A: $(basename "$f") does not source mhash_lib.sh (seal authorship lost)"
    grep -Eq "mhash_file|mhash_stdin" "$f" || red "A: $(basename "$f") never calls mhash_file/mhash_stdin"
done
[[ $RED -eq 0 ]] && log "A: seal authorship sovereign across ${#SPINE[@]} spine scripts"

# --- B: RAW-HASH RATCHET ------------------------------------------------------
# Count non-comment, non-`command -v` lines invoking sha256sum across the spine
# script set (mhash_lib.sh itself excluded -- it IS the witness call site).
RAW_MAX="$(pin RAW_SHA_MAX)"
RAW_COUNT=0
for f in "$BOOT"/*.sh "$SCRIPTS"/*.sh; do
    [[ -f "$f" ]] || continue
    [[ "$(basename "$f")" == "mhash_lib.sh" ]] && continue
    n="$(awk '
        /^[[:space:]]*#/      { next }        # comments
        /command -v sha256sum/{ next }        # witness prerequisite probes
        /sha256sum/           { c++ }
        END                   { print c+0 }
    ' "$f")"
    RAW_COUNT=$((RAW_COUNT + n))
done
if [[ "$RAW_COUNT" -gt "$RAW_MAX" ]]; then
    red "B: raw sha256sum lines = $RAW_COUNT > pin $RAW_MAX (a GNU-authored hash crept in; route it through mhash_lib.sh or justify a reviewed pin raise)"
else
    log "B: raw sha256sum lines = $RAW_COUNT <= pin $RAW_MAX (down-only)"
fi

# --- C: ALGEBRA IN CODEGEN ----------------------------------------------------
BVRING_MIN="$(pin BVRING_MIN)"
CGR3="$BOOT/cg_r3.iii"
if [[ -f "$CGR3" ]]; then
    BV="$(grep -c "bv_ring" "$CGR3")"
    if [[ "$BV" -lt "$BVRING_MIN" ]]; then
        red "C: cg_r3.iii bv_ring-proven sites = $BV < pin $BVRING_MIN (certified-rewrite machinery regressed)"
    else
        log "C: cg_r3.iii bv_ring-proven sites = $BV >= $BVRING_MIN (mul-plan + shl+add certification live)"
    fi
else
    red "C: cg_r3.iii missing"
fi
for f in "$BOOT/build_iiis1.sh" "$BOOT/build_iiis2.sh" "$BOOT/build_iiis3.sh"; do
    grep -q "libiii_native\.a" "$f" \
        || red "C: $(basename "$f") no longer links the prover closure archive (ser_egraph->bv_ring, bv_bits->sat)"
done

# --- D: CRYPTO PRECEDENTS -----------------------------------------------------
[[ -f "$BOOT/forge_manifest_keccak.sh" ]] \
    || red "D: forge_manifest_keccak.sh missing (in-tree keccak forge root)"
grep -q "forge_manifest_keccak" "$SCRIPTS/subsystem_test_gate.sh" 2>/dev/null \
    || red "D: forge keccak root unwired from subsystem_test_gate.sh"
grep -q "TRIANGLE-VERIFIED" "$SCRIPTS/seal_sources.sh" 2>/dev/null \
    || red "D: seal_sources witness triangle (III/GNU/MS) removed"
[[ $RED -eq 0 ]] && log "D: forge keccak + witness triangle wired"

# --- F: ISLAND-BREACH LEDGER (down-only) ---------------------------------------
BREACH_MAX="$(pin BREACH_MAX)"
BREACH_COUNT="$(grep -c '^BREACH:' "$PINS")"
if [[ "$BREACH_COUNT" -gt "$BREACH_MAX" ]]; then
    red "F: breach ledger has $BREACH_COUNT entries > pin $BREACH_MAX (an island was ADDED; wire it or make the reviewed case)"
else
    log "F: island breaches = $BREACH_COUNT <= pin $BREACH_MAX (down-only; discharge paths named in the ledger)"
fi
# Ledger honesty: every breach's named organ must still exist (stale ledger = RED).
while IFS= read -r line; do
    organ="$(printf '%s\n' "$line" | sed -n 's/.*organ=\([^ |]*\).*/\1/p')"
    opath="${organ%%:*}"
    [[ -n "$opath" && -e "$III_ROOT/$opath" ]] \
        || red "F: breach ledger names a missing organ: $organ (stale ledger -- update the line)"
done < <(grep '^BREACH:' "$PINS")

# -------------------------------------------------------------------------------
if [[ $RED -ne 0 ]]; then
    log "GATE RED -- the basal law is breached"
    exit 3
fi
log "GATE GREEN -- the exact organs are load-bearing where the law requires"
exit 0
