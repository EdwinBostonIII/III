#!/usr/bin/env bash
# bootstrap_from_clean.sh — the P0 gate of DOCS/III-INDEPENDENCE-AUDIT.md.
#
# "Independence you don't re-run is independence you no longer have."  This
# gate proves the WHOLE toolchain regenerates from source on this host, in
# dependency order, with every artifact deleted immediately before the step
# that must recreate it (so a silently-skipped rebuild can never read green):
#
#   stage 1  build_iiis0.sh                 gcc compiles the C seed (witness-attested)
#   stage 2  build_stdlib.sh --clean+build  the COMMITTED in-tree iiis-2 compiles all
#                                           STDLIB modules from scratch; FAIL must == 0
#   stage 3  build_iiis1.sh                 fresh iiis-0 compiles the ported .iii TUs;
#                                           output golden-mhash-sealed
#   stage 4  build_iiis2.sh --check-corpus  fresh iiis-1 builds iiis-2; the golden mhash
#                                           CLOSES THE LOOP: the rebuilt iiis-2 must be
#                                           byte-identical to the committed binary that
#                                           compiled the stdlib in stage 2
#   stage 5  seed_text_identity_gate.sh     iiis-0 vs iiis-2: .text/.data/.reloc identity
#                                           on stage1_corpus (divergence only in inert .rodata)
#   stage 6  build_iiis3.sh --check-corpus  iiis-2 rebuilds itself; byte-identical binary
#                                           + byte-identical corpus output = the fixpoint
#   stage 7  basal_census_gate.sh           the BASAL LAW ratchet: the exact-math organs
#                                           are load-bearing in the trusted path (seal
#                                           authorship sovereign, algebra in codegen,
#                                           island-breach ledger down-only)
#   stage 8  witness_zero_gate.sh           the crypto closure (sha256/sha3/sha512) assembles
#                                           through sovas with ZERO gcc-as (route manifest
#                                           witness=0) -- sovas encodes every mnemonic it emits
#   stage 9  run_fixpoint.sh (gcc OFF PATH) the sovereign toolchain self-mints from the sealed gen-0
#                                           SEED with NO gcc/ld anywhere: gen2==gen1, linker
#                                           reproduces itself bit-for-bit (Independence D1)
#
# SEAL AUTHORSHIP (basal law, mhash_lib.sh): every .mhash above is AUTHORED by
# III's own FIPS-KAT'd SHA-256 (aether/sovhash over numera/cad); GNU sha256sum
# is the cross-witness that can veto but not author.  Stage 1 runs before the
# stdlib archive exists (the one unmintable window) — stage 2b below retro-
# attests the stage-1 seed seal sovereignly the moment the archive is built.
#
# CLEAN SEMANTICS (per-artifact, dependency-ordered — deliberately NOT a blind
# up-front wipe): iiis-2.exe is deleted only AFTER stage 2 has used it, because
# the stdlib is compiled by the committed iiis-2 and the trust anchor is that
# stage 4 must REPRODUCE that exact binary against its golden mhash.
#
# HONEST SCOPE (per the audit): P0 proves from-clean reproduction on a host
# WITH gcc/binutils.  It does not remove them from the trusted path — that is
# P1 (sovas/sovld as default emit) and P2 (close the gcc-as witness).
#
# Usage:  bash bootstrap_from_clean.sh [-h|--help]
# Exit:   0 = GATE GREEN (all nine stages)
#         N = 1..9, the first red stage
#         99 = environment/prerequisite error
set -uo pipefail
umask 022
export LC_ALL=C LANG=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT="$SCRIPT_DIR"
COMPILED="$III_ROOT/COMPILED"
STDLIB_SCRIPTS="$III_ROOT/STDLIB/scripts"
LOGDIR="$COMPILED/_bootstrap_logs"

case "$*" in
  -h|--help) sed -n '2,50p' "$0"; exit 0 ;;
  "") : ;;
  *) printf 'unknown argument: %s\n' "$*" >&2; exit 99 ;;
esac

log()   { printf '[bootstrap-clean] %s\n' "$*" >&2; }

# --- prerequisites -----------------------------------------------------------
command -v gcc       >/dev/null 2>&1 || { log "ENV: gcc not found";       exit 99; }
command -v ar        >/dev/null 2>&1 || { log "ENV: ar not found";        exit 99; }
command -v objcopy   >/dev/null 2>&1 || { log "ENV: objcopy not found";   exit 99; }
command -v objdump   >/dev/null 2>&1 || { log "ENV: objdump not found";   exit 99; }
command -v sha256sum >/dev/null 2>&1 || { log "ENV: sha256sum not found"; exit 99; }
[[ -x "$COMPILED/iiis-2.exe" ]] || { log "ENV: committed COMPILED/iiis-2.exe missing — stage 2 needs it to compile the stdlib (checkout state incomplete?)"; exit 99; }

rm -rf "$LOGDIR"
mkdir -p "$LOGDIR"

# run_stage <n> <name> <logfile> <fn-or-cmd...>
# rc is captured DIRECTLY (no pipes — a pipe would launder the exit code).
run_stage() {
    local n="$1" name="$2" logf="$3"; shift 3
    log "STAGE $n: $name"
    local t0=$SECONDS rc
    "$@" > "$logf" 2>&1
    rc=$?
    local dt=$(( SECONDS - t0 ))
    if [[ $rc -ne 0 ]]; then
        log "STAGE $n FAIL rc=$rc (${dt}s) — log: $logf; last lines:"
        tail -n 25 "$logf" >&2
        exit "$n"
    fi
    log "STAGE $n PASS (${dt}s)"
}

stage1_seed() {
    rm -rf "$COMPILED/_obj_boot"
    rm -f  "$COMPILED"/iiis-0.exe "$COMPILED"/iiis-0.exe.mhash "$COMPILED"/iiis-0.exe.witness.json
    bash "$BOOT/build_iiis0.sh"
}
stage2_stdlib() {
    bash "$STDLIB_SCRIPTS/build_stdlib.sh" --clean && bash "$STDLIB_SCRIPTS/build_stdlib.sh" || return $?
    # stage 2b — SEAL AUTHORSHIP retro-attestation (basal law): stage 1 sealed the
    # seed on a pristine clone where the sovereign hasher was unmintable (no
    # archive yet).  The archive now exists: mint III's own FIPS-KAT'd SHA-256 and
    # RE-ATTEST the stage-1 seed seal sovereignly, closing the one GNU-only
    # window.  From here every stage seals sovereign-primary.
    . "$BOOT/mhash_lib.sh" || return 1
    mhash_init --require-sovereign || return 1
    local seed="$COMPILED/iiis-0.exe" sealed got
    [[ -f "$seed.mhash" ]] || { log "stage 2b: missing $seed.mhash"; return 1; }
    sealed="$(awk '{print $1; exit}' "$seed.mhash")"
    got="$(mhash_file "$seed")" || return 1
    if [[ "$got" != "$sealed" ]]; then
        log "stage 2b: SEED SEAL RETRO-ATTESTATION FAILED: sovereign=$got sealed=$sealed"
        return 1
    fi
    log "stage 2b: seed seal sovereignly co-signed (III authored, GNU witnessed)"
}
stage3_iiis1() {
    rm -f "$COMPILED"/iiis-1.exe "$COMPILED"/iiis-1.exe.mhash "$COMPILED"/iiis-1.exe.witness.json
    bash "$BOOT/build_iiis1.sh"
}
stage4_iiis2() {
    # Only now may the committed iiis-2 be deleted: stage 2 is done with it,
    # and the golden mhash inside build_iiis2.sh must reproduce it exactly.
    rm -f "$COMPILED"/iiis-2.exe "$COMPILED"/iiis-2.exe.mhash "$COMPILED"/iiis-2.exe.witness.json
    bash "$BOOT/build_iiis2.sh" --check-corpus
}
stage5_identity() {
    bash "$BOOT/seed_text_identity_gate.sh"
}
stage6_fixpoint() {
    rm -f "$COMPILED"/iiis-3.exe "$COMPILED"/iiis-3.exe.mhash "$COMPILED"/iiis-3.exe.witness.json
    bash "$BOOT/build_iiis3.sh" --check-corpus
}
stage7_census() {
    bash "$BOOT/basal_census_gate.sh"
}
stage8_witness_zero() {
    bash "$III_ROOT/STDLIB/sovtc/witness_zero_gate.sh"
}
stage9_fixpoint_gccoff() {
    # Prove the sovereign toolchain self-mints with NO gcc/ld: strip every MinGW/gcc dir from PATH,
    # then run the fixpoint (it bootstraps gen1 from the sealed seed, no gcc).  rc captured directly.
    local cleanpath
    cleanpath="$(printf '%s' "$PATH" | tr ':' '\n' | grep -viE 'mingw|/gcc' | paste -sd: -)"
    PATH="$cleanpath" bash -c '
        command -v gcc >/dev/null 2>&1 && { echo "[stage9] gcc STILL on PATH -- strip failed"; exit 2; }
        bash "'"$III_ROOT"'/STDLIB/sovtc/run_fixpoint.sh"
    '
}

run_stage 1 "seed rebuild (build_iiis0.sh)"                 "$LOGDIR/1_iiis0.log"    stage1_seed
run_stage 2 "stdlib from scratch (build_stdlib.sh)"         "$LOGDIR/2_stdlib.log"   stage2_stdlib
# rc==0 alone can mask a stale lib (see memory: build_stdlib FAIL masks stale
# lib) — require the explicit zero-failure summary line in the log too.
grep -q "FAIL = 0" "$LOGDIR/2_stdlib.log" || { log "STAGE 2 FAIL: 'FAIL = 0' summary absent from log (stale-lib guard)"; exit 2; }
run_stage 3 "iiis-1 rebuild (build_iiis1.sh)"               "$LOGDIR/3_iiis1.log"    stage3_iiis1
run_stage 4 "iiis-2 rebuild + corpus (build_iiis2.sh)"      "$LOGDIR/4_iiis2.log"    stage4_iiis2
run_stage 5 "seed<->self-host identity gate"                "$LOGDIR/5_identity.log" stage5_identity
run_stage 6 "iiis-3 fixpoint + corpus (build_iiis3.sh)"     "$LOGDIR/6_iiis3.log"    stage6_fixpoint
run_stage 7 "basal law census (basal_census_gate.sh)"       "$LOGDIR/7_census.log"   stage7_census
run_stage 8 "crypto-closure witness-zero (witness_zero_gate.sh)" "$LOGDIR/8_witness0.log" stage8_witness_zero
run_stage 9 "sovereign toolchain self-mint, gcc OFF PATH (run_fixpoint.sh)" "$LOGDIR/9_fixpoint_gccoff.log" stage9_fixpoint_gccoff

log "GATE GREEN: full toolchain regenerated from clean, sovereignly sealed, basal census green, crypto closure witness-zero, sovereign toolchain self-mints gcc-free (logs: $LOGDIR)"
exit 0
