#!/usr/bin/env bash
# PRODUCTION GATE (DOCS/III-EIDOS plan Phase 4) -- the standing check for every change to the e-graph-wired
# compiler.  Composes the FULL set of gates; ALL must be green or the change is not production-ready:
#
#   1. build_stdlib            -- libiii_native.a rebuilds; coverage/under-proven/dark-surface ratchets at pin.
#   2. iiis-0 == iiis-1 byte   -- the diverse-double-compile root (gcc seed vs .iii), on stage1_corpus.
#   3. iiis-1 == iiis-2 byte   -- + cg_r0/cg_rm2 Ring-0/-2 end-to-end gates.
#   4. iiis-2 == iiis-3 byte   -- THE self-hosted fixpoint.
#   5. run_corpus              -- behavioral equivalence over the whole STDLIB corpus, incl. 2062/2063 (the
#                                 e-graph mul/div KATs) AND the bb_*/sat prover KATs compiled by the NEW iiis-2
#                                 -- the anti-circularity guard: a miscompiled proof oracle would redden here.
#   6. determinism             -- build_iiis0 --check-deterministic (byte-identical on two runs).
#   7. universality_gate.sh    -- random un-pre-shaped constants: e-graph form vs imul/divq reference on the CPU.
#
# The soundness invariant (emitted => proven) is STRUCTURAL: cg_r3 reaches a non-naive emission only behind
# seg_mul_plan's bv_ring proof or seg_div_plan's GM bound -- there is no other path to r3_emit of a reduced form.
set -uo pipefail
III="${III_ROOT:-/c/Users/Edwin Boston/OneDrive/Desktop/III}"
BOOT="$III/COMPILER/BOOT"; STDLIB="$III/STDLIB"
log() { echo "[prod-gate] $*"; }
fail() { log "GATE FAIL: $1"; exit 1; }

log "[1] build_stdlib (archive + coverage gate)"
( cd "$STDLIB/scripts" && bash build_stdlib.sh ) >/tmp/pg_stdlib.log 2>&1 || fail "build_stdlib"
grep -q "GATE PASS" /tmp/pg_stdlib.log || fail "build_stdlib gate not PASS"

log "[2] iiis-1 build + --check-corpus (iiis-0 vs iiis-1 byte-equivalence)"
( cd "$BOOT" && bash build_iiis1.sh --check-corpus ) >/tmp/pg_i1.log 2>&1 || fail "iiis-1 / byte-check vs iiis-0"

log "[3] iiis-2 build + --check-corpus (iiis-1 vs iiis-2 + cg_r0/rm2 gates)"
( cd "$BOOT" && bash build_iiis2.sh --check-corpus ) >/tmp/pg_i2.log 2>&1 || fail "iiis-2 / byte-check vs iiis-1"

log "[4] iiis-3 build + --check-corpus (iiis-2 == iiis-3 FIXPOINT)"
( cd "$BOOT" && bash build_iiis3.sh --check-corpus ) >/tmp/pg_i3.log 2>&1 || fail "iiis-3 fixpoint"

log "[5] run_corpus (behavioral; e-graph KATs 2062/2063 + prover KATs under the NEW compiler)"
( cd "$STDLIB/scripts" && bash run_corpus.sh ) >/tmp/pg_corpus.log 2>&1 || fail "run_corpus"

log "[6] determinism firewall (iiis-0 byte-identical on two runs)"
( cd "$BOOT" && bash build_iiis0.sh --check-deterministic ) >/tmp/pg_det.log 2>&1 || fail "determinism"

log "[7] universality gate (random constants -> e-graph form vs imul/divq reference on the CPU)"
IIIS="$III/COMPILED/iiis-2.exe" III_ROOT="$III" bash "$BOOT/opt/universality_gate.sh" >/tmp/pg_univ.log 2>&1 || fail "universality"

log "=== PRODUCTION GATE GREEN: the e-graph-wired compiler is production-ready on every axis. ==="
exit 0
