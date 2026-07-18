#!/usr/bin/env bash
# COMPILER/BOOT/nomos_seal.sh -- THE NOMOS SEAL CEREMONY.
#
# The machine legislates its own compilation: friction-held ISA laws become
# COMPILER/BOOT/cg_phys_rules.iii (consulted by cg_r3's nomos arm).  A rule
# row reaches the compiler ONLY through this ceremony:
#
#   [0] leaf rebuild        iii-substrate rebuilt from source (pinned iiis-2)
#   [1] LEGALITY            katabasis discovery admission: `iii-substrate isa 4`
#                           must exit 0 (ADMIT) -- the ledger the rules derive
#                           from is itself admitted
#   [2] GENERATION          `iii-substrate nomos <FUEL>` -- global pre-stated
#                           criteria, every disposition counted (the fairness arm)
#   [3] TRUTH               iii-prove PROVEN over ALL 2^64 for EVERY row
#                           (bit-blast UNSAT, never sampled); ONE red deletes
#                           the candidate module -- nothing lands
#   [4] NEGATIVE ARM        a wrong cheap side must be REFUTED (the prover is
#                           not a rubber stamp)
#   [5] THE PARLIAMENT       a drift is a PROPOSAL, not an install.  It lands only
#                           on III's AUTONOMOUS UNANIMOUS CONSENT (katabasis/
#                           nomos_consent.iii is the law; this script is its driver).
#                           Four voters, each able to REFUSE:
#                             * SELF-AGREEMENT -- a SECOND independent generation
#                               must reproduce the same set-id (the machine agrees
#                               with itself; a one-run artifact is tabled)
#                             * TRUTH          -- every row PROVEN over 2^64 [3]
#                             * TEETH          -- the negative arm refused [4]
#                             * CONTINUITY     -- the compiler-LIVE core does not
#                               shrink (no silent erosion of operative law)
#                           CONCUR installs + reseals; any dissent TABLES the
#                           proposal (sealed constitution stands) and names the
#                           dissenting voter.  An unchanged set never rewrites bytes.
#
# After a NEW seal lands: the covenant ceremony is MANDATORY --
#   build_iiis2 -> build_iiis3 (fixpoint) -> build_stdlib -> corpus -> reseal
#   goldens (see DOCS/III-MATHESIS-MAP.md, the NOMOS section).
#
# Usage: bash nomos_seal.sh [--fuel N]
# Exit:  0 sealed-or-unchanged | 2 env | 3 admission red | 4 generation red
#      | 5 truth red (a row failed iii-prove) | 6 negative-arm red
#      | 7 proposal TABLED (III did not consent -- the constitution stands)
#      | 8 glossa press red | 9 glossa truth red | 10 glossa toothless
#      | 11 glossa proposal TABLED (the tongue stands)
# The ceremony has TWO CHAMBERS: I (NOMOS, the rewrite law) and II (GLOSSA,
# the vocabulary) -- a lawful chamber-I outcome never blocks chamber II.

set -uo pipefail
IFS=$'\n\t'
export LC_ALL=C LANG=C TZ=UTC0

TAG="[nomos-seal]"
log() { printf '%s %s\n' "$TAG" "$*" >&2; }
die() { printf '%s RED: %s\n' "$TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FUEL=25000
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fuel) FUEL="$2"; shift 2 ;;
        *) die 2 "unknown arg: $1" ;;
    esac
done

SUB="$ROOT/COMPILED/iii.exe"
PROVE="$ROOT/COMPILED/iii-prove.exe"
SEALED="$ROOT/COMPILER/BOOT/cg_phys_rules.iii"
# The work dir must live OUTSIDE the walked tree: probe .iii files carry @export fns,
# and an in-repo mirror of exports reds the carto architectural gate (the documented
# in-repo-mirror trap -- hit live by this ceremony's first landing).
W="$(mktemp -d "${TMPDIR:-/tmp}/nomos-seal.XXXXXX")"
log "work dir: $W (kept for audit; outside the repo by law)"

[[ -x "$PROVE" ]] || die 2 "iii-prove not found: $PROVE"

# [0] the generator is rebuilt from source -- no stale-tool seals
bash "$SCRIPT_DIR/build_iii.sh" >"$W/build.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] || die 2 "iii-substrate rebuild failed (see $W/build.log)"

# [1] LEGALITY: the discovery loop itself must be admitted by katabasis
"$SUB" substrate isa 4 >"$W/isa.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] || die 3 "katabasis admission is not ADMIT (rc=$rc, see $W/isa.log)"
log "legality: isa admission ADMIT"

# [2] GENERATION: global criteria, counted dispositions
"$SUB" substrate nomos "$FUEL" "$W" >"$W/nomos.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] || die 4 "nomos generation red (rc=$rc, see $W/nomos.log)"
ROWS="$(grep -o 'rows=[0-9]*' "$W/nomos.log" | head -1 | cut -d= -f2)"
SID="$(grep -o 'NOMOS-SET id=[0-9]*' "$W/nomos.log" | head -1 | cut -d= -f2)"
[[ -n "$ROWS" && -n "$SID" ]] || die 4 "nomos output carries no rows=/id= (see $W/nomos.log)"
[[ -f "$W/cg_phys_rules.iii" ]] || die 4 "generator wrote no module"
log "generation: $ROWS rows, set id $SID (jurisdiction $FUEL)"

# [3] TRUTH: every row PROVEN over all 2^64, or nothing lands
i=0
while [[ $i -lt $ROWS ]]; do
    "$PROVE" "$W/nomos_r${i}d.iii" f "$W/nomos_r${i}c.iii" f >"$W/prove_r${i}.log" 2>&1
    rc=$?
    if [[ $rc -ne 0 ]]; then
        rm -f "$W/cg_phys_rules.iii"
        die 5 "row $i NOT PROVEN (rc=$rc) -- candidate module DELETED (see $W/prove_r${i}.log)"
    fi
    i=$((i+1))
done
log "truth: $ROWS/$ROWS rows PROVEN over all 2^64 (bit-blast UNSAT)"

# [4] NEGATIVE ARM: the prover must refuse a wrong cheap side
printf 'module nomos_neg\nfn f(x: u64, y: u64) -> u64 @export { return x + 1u64 }\n' > "$W/nomos_neg.iii"
"$PROVE" "$W/nomos_r0d.iii" f "$W/nomos_neg.iii" f >"$W/prove_neg.log" 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    rm -f "$W/cg_phys_rules.iii"
    die 6 "NEGATIVE ARM RED: a wrong cheap side was PROVEN -- prover unsound, module DELETED"
fi
TEETH=1
log "negative arm: wrong cheap REFUTED (rc=$rc) -- the gate has teeth"

# [5] THE PARLIAMENT.  A drift is a PROPOSAL; it lands only on III's autonomous
# unanimous consent.  An unchanged rule set never convenes a parliament (bytes
# stable) -- and a lawful chamber-I outcome never blocks CHAMBER II (GLOSSA).
NOMOS_RC=0
NOMOS_NOTE=""
NOMOS_CHANGED=1
if [[ -f "$SEALED" ]]; then
    OLD="$(grep -o 'cgphys_set_id() -> u64 @export { return [0-9]*' "$SEALED" | grep -o '[0-9]*$')"
    if [[ "$OLD" == "$SID" ]]; then
        log "seal: rule set UNCHANGED (id $SID) -- sealed constitution untouched, no amendment tabled"
        NOMOS_NOTE="unchanged (rows=$ROWS id=$SID)"
        NOMOS_CHANGED=0
    else
        log "proposal: DRIFT old=$OLD new=$SID -- convening the parliament (autonomous consent required)"
    fi
fi
if [[ $NOMOS_CHANGED -eq 1 ]]; then

# VOTER [1] SELF-AGREEMENT: a SECOND independent generation must reproduce the set-id.
# The machine must agree with ITSELF that this is the legislature -- not one run's noise.
W2="$(mktemp -d "${TMPDIR:-/tmp}/nomos-selfcheck.XXXXXX")"
"$SUB" substrate nomos "$FUEL" "$W2" >"$W2/nomos.log" 2>&1
SID2="$(grep -o 'NOMOS-SET id=[0-9]*' "$W2/nomos.log" | head -1 | cut -d= -f2)"
SELF_AGREE=0
if [[ -n "$SID2" && "$SID2" == "$SID" ]]; then SELF_AGREE=1; fi
log "voter[1] self-agreement: run1 id=$SID run2 id=${SID2:-none} -> $([[ $SELF_AGREE -eq 1 ]] && echo CONCUR || echo REFUSE)"
rm -rf "$W2"

# VOTER [4] CONTINUITY: the compiler-LIVE core (class-0 involutions the compiler fires)
# must not shrink -- no silent erosion of operative law.  (Truth[2] + Teeth[3] gathered above.)
LIVE_NEW="$(grep -c 'class 0  ' "$W/cg_phys_rules.iii" 2>/dev/null || echo 0)"
LIVE_OLD=0
[[ -f "$SEALED" ]] && LIVE_OLD="$(grep -c 'class 0  ' "$SEALED" 2>/dev/null || echo 0)"
CONTINUOUS=0
if [[ "$LIVE_NEW" -ge "$LIVE_OLD" ]]; then CONTINUOUS=1; fi
log "voter[4] continuity: compiler-live old=$LIVE_OLD new=$LIVE_NEW -> $([[ $CONTINUOUS -eq 1 ]] && echo CONCUR || echo REFUSE)"

# THE RULING is the ORGAN's, never this script's: compile katabasis_nomos_consent with
# the four verdicts and let it decide.  The probe lives in $W (outside the tree, the
# carto in-repo-mirror law); the organ is linked from source, no archive dependency.
cat > "$W/consent_probe.iii" <<EOF
module nomos_consent_probe
extern @abi(c-msvc-x64) fn katabasis_nomos_consent(a: u32, b: u32, c: u32, d: u32) -> u32 from "nomos_consent.iii"
fn main() -> i32 { return katabasis_nomos_consent(${SELF_AGREE}u32, 1u32, ${TEETH}u32, ${CONTINUOUS}u32) as i32 }
EOF
IIIS2="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
"$IIIS2" "$W/consent_probe.iii" --compile-only --out "$W/consent_probe.o" >"$W/consent.log" 2>&1 \
    && "$IIIS2" "$ROOT/STDLIB/iii/katabasis/nomos_consent.iii" --compile-only --out "$W/nomos_consent.o" >>"$W/consent.log" 2>&1 \
    && gcc "$W/consent_probe.o" "$W/nomos_consent.o" "$LIB" -lws2_32 -lkernel32 -o "$W/consent_probe.exe" >>"$W/consent.log" 2>&1 \
    || die 7 "consent probe failed to build (see $W/consent.log)"
"$W/consent_probe.exe"; VERDICT=$?

case "$VERDICT" in
    0) : ;;  # CONCUR
    1) NOMOS_RC=7; NOMOS_NOTE="TABLED -- voter[1] SELF-DISAGREEMENT (the machine did not reproduce the set; the constitution stands)" ;;
    2) NOMOS_RC=7; NOMOS_NOTE="TABLED -- voter[2] UNTRUE (a row failed 2^64 proof; the constitution stands)" ;;
    3) NOMOS_RC=7; NOMOS_NOTE="TABLED -- voter[3] TOOTHLESS (the negative arm did not refute; the constitution stands)" ;;
    4) NOMOS_RC=7; NOMOS_NOTE="TABLED -- voter[4] DISCONTINUOUS (the compiler-live core would erode; the constitution stands)" ;;
    *) NOMOS_RC=7; NOMOS_NOTE="TABLED -- consent organ returned an unknown dissent code $VERDICT" ;;
esac
if [[ $NOMOS_RC -eq 0 ]]; then
    log "parliament: UNANIMOUS CONSENT (self-agreement + truth + teeth + continuity) -- the amendment is adopted"
    cp "$W/cg_phys_rules.iii" "$SEALED"
    NOMOS_NOTE="ADOPTED (rows=$ROWS id=$SID)"
else
    log "$NOMOS_NOTE"
fi
fi
# ========================= CHAMBER II: GLOSSA ================================
# The machine mints its own VOCABULARY (words = language-level named operators;
# see STDLIB/iii/aether/substrate_cli.iii, THE GLOSSA TIER).  Same constitutional
# road as chamber I: generation with counted dispositions, truth over ALL 2^64
# (THE LADDER OF SPELLINGS -- single-local-difference links, transitivity),
# teeth, then AUTONOMOUS UNANIMOUS CONSENT via katabasis_glossa_consent
# (chamber II of the parliament organ) with TWO extra voters: COLLISION
# (a word name declared anywhere outside the tongue refuses -- deterministic
# whole-tree scan) and WORD-CONTINUITY (a sealed word may never silently
# vanish -- programs speak it).
GLOSSA_RC=0
GLOSSA_NOTE=""
IIIS2="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
GW="$W/glossa"
mkdir -p "$GW"
"$SUB" substrate glossa "$GW" >"$GW/press.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] || die 8 "glossa press red (rc=$rc, see $GW/press.log)"
GSID="$(grep -o 'GLOSSA-SET id=[0-9]*' "$GW/press.log" | head -1 | grep -o '[0-9]*$')"
GWORDS="$(grep -o 'words=[0-9]*' "$GW/press.log" | head -1 | cut -d= -f2)"
[[ -n "$GSID" && -n "$GWORDS" ]] || die 8 "glossa press carries no id=/words= (see $GW/press.log)"
[[ -f "$GW/cg_glossa_rules.iii" && -f "$GW/glossa.iii" ]] || die 8 "glossa press wrote no artifacts"
log "glossa generation: $GWORDS words, set id $GSID"

# TRUTH: every ladder link PROVEN over all 2^64, or nothing lands
GLINKS=0
for f0 in "$GW"/gw*_s0.iii; do
    [[ -f "$f0" ]] || continue
    gbase="${f0%_s0.iii}"
    j=0
    while [[ -f "${gbase}_s$((j+1)).iii" ]]; do
        "$PROVE" "${gbase}_s${j}.iii" f "${gbase}_s$((j+1)).iii" f >"$GW/prove_$(basename "$gbase")_l${j}.log" 2>&1
        rc=$?
        if [[ $rc -ne 0 ]]; then
            rm -f "$GW/cg_glossa_rules.iii" "$GW/glossa.iii"
            die 9 "ladder link $(basename "$gbase") s${j}->s$((j+1)) NOT PROVEN (rc=$rc) -- lexicon DELETED"
        fi
        GLINKS=$((GLINKS+1)); j=$((j+1))
    done
done
log "glossa truth: $GLINKS/$GLINKS ladder links PROVEN over all 2^64 (bit-blast UNSAT)"

# TEETH: a corrupted spelling must be REFUTED
sed -e 's/6148914691236517205/6148914691236517204/g' -e 's/module glossa_w5s0/module glossa_wneg/' \
    "$GW/gw5_s0.iii" > "$GW/gw_neg.iii"
"$PROVE" "$GW/gw_neg.iii" f "$GW/gw5_s1.iii" f >"$GW/prove_neg.log" 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
    rm -f "$GW/cg_glossa_rules.iii" "$GW/glossa.iii"
    die 10 "GLOSSA TOOTHLESS: a corrupted spelling was PROVEN -- prover unsound, lexicon DELETED"
fi
GTEETH=1
log "glossa teeth: corrupted spelling REFUTED (rc=$rc)"

# VOTER: COLLISION -- no word name declared anywhere outside the tongue.
# (_neg corpus files are lawful shadows: they exist to be REFUSED by sema.)
GNAMES="$(grep -o 'MINT [a-z0-9]*' "$GW/press.log" | awk '{print $2}')"
GCOLLIDE=1
for nm in $GNAMES; do
    hits="$(grep -rlE "fn[[:space:]]+${nm}[[:space:]]*\(" "$ROOT/STDLIB" "$ROOT/COMPILER" --include='*.iii' 2>/dev/null | grep -v 'aether/glossa\.iii' | grep -v '_neg' || true)"
    if [[ -n "$hits" ]]; then
        log "voter[collision]: word '$nm' is declared outside the tongue:"
        printf '%s\n' "$hits" | while IFS= read -r hline; do log "    $hline"; done
        GCOLLIDE=0
    fi
done
log "voter[collision]: $([[ $GCOLLIDE -eq 1 ]] && echo CONCUR || echo REFUSE)"

# VOTER: SELF-AGREEMENT -- a second independent press must reproduce the id
GW2="$(mktemp -d "${TMPDIR:-/tmp}/glossa-selfcheck.XXXXXX")"
"$SUB" substrate glossa "$GW2" >"$GW2/press.log" 2>&1
GSID2="$(grep -o 'GLOSSA-SET id=[0-9]*' "$GW2/press.log" | head -1 | grep -o '[0-9]*$')"
GSELF=0
[[ -n "$GSID2" && "$GSID2" == "$GSID" ]] && GSELF=1
log "voter[self-agreement]: run1 id=$GSID run2 id=${GSID2:-none} -> $([[ $GSELF -eq 1 ]] && echo CONCUR || echo REFUSE)"
rm -rf "$GW2"

# VOTER: WORD-CONTINUITY -- every sealed word survives into the candidate
GCONT=1
GSEALED_ORGAN="$ROOT/STDLIB/iii/aether/glossa.iii"
if [[ -f "$GSEALED_ORGAN" ]]; then
    while IFS= read -r oldw; do
        grep -q "fn ${oldw}(" "$GW/glossa.iii" || { log "voter[continuity]: sealed word '$oldw' vanished from the candidate"; GCONT=0; }
    done < <(grep -oE '^fn [a-z0-9_]+\(' "$GSEALED_ORGAN" | sed -e 's/^fn //' -e 's/($//' -e 's/(//')
fi
log "voter[continuity]: $([[ $GCONT -eq 1 ]] && echo CONCUR || echo REFUSE)"

# An unchanged lexicon never rewrites bytes and never convenes the chamber.
GSEALED_TABLE="$ROOT/COMPILER/BOOT/cg_glossa_rules.iii"
GOLD=""
[[ -f "$GSEALED_TABLE" ]] && GOLD="$(grep -o 'cgglossa_set_id() -> u64 @export { return [0-9]*' "$GSEALED_TABLE" | grep -o '[0-9]*$')"
if [[ -n "$GOLD" && "$GOLD" == "$GSID" ]]; then
    GLOSSA_NOTE="unchanged (words=$GWORDS id=$GSID)"
    log "glossa seal: lexicon UNCHANGED (id $GSID) -- sealed tongue untouched"
else
    [[ -n "$GOLD" ]] && log "glossa proposal: DRIFT old=$GOLD new=$GSID -- convening chamber II (autonomous consent required)"
    # THE RULING is the organ's (katabasis_glossa_consent), never this script's.
    cat > "$W/gconsent_probe.iii" <<EOF
module glossa_consent_probe
extern @abi(c-msvc-x64) fn katabasis_glossa_consent(a: u32, b: u32, c: u32, d: u32, e: u32) -> u32 from "nomos_consent.iii"
fn main() -> i32 { return katabasis_glossa_consent(${GSELF}u32, 1u32, ${GTEETH}u32, ${GCOLLIDE}u32, ${GCONT}u32) as i32 }
EOF
    "$IIIS2" "$W/gconsent_probe.iii" --compile-only --out "$W/gconsent_probe.o" >"$W/gconsent.log" 2>&1 \
        && "$IIIS2" "$ROOT/STDLIB/iii/katabasis/nomos_consent.iii" --compile-only --out "$W/nomos_consent2.o" >>"$W/gconsent.log" 2>&1 \
        && gcc "$W/gconsent_probe.o" "$W/nomos_consent2.o" "$LIB" -lws2_32 -lkernel32 -o "$W/gconsent_probe.exe" >>"$W/gconsent.log" 2>&1 \
        || die 11 "glossa consent probe failed to build (see $W/gconsent.log)"
    "$W/gconsent_probe.exe"; GVERDICT=$?
    case "$GVERDICT" in
        0) : ;;
        1) GLOSSA_RC=11; GLOSSA_NOTE="TABLED -- voter SELF-DISAGREEMENT (press drift; the tongue stands)" ;;
        2) GLOSSA_RC=11; GLOSSA_NOTE="TABLED -- voter UNTRUE (a ladder link failed; the tongue stands)" ;;
        3) GLOSSA_RC=11; GLOSSA_NOTE="TABLED -- voter TOOTHLESS (the tongue stands)" ;;
        4) GLOSSA_RC=11; GLOSSA_NOTE="TABLED -- voter COLLIDING (a word is declared outside the tongue; the tongue stands)" ;;
        5) GLOSSA_RC=11; GLOSSA_NOTE="TABLED -- voter DISCONTINUOUS (a sealed word would vanish; the tongue stands)" ;;
        *) GLOSSA_RC=11; GLOSSA_NOTE="TABLED -- unknown dissent code $GVERDICT" ;;
    esac
    if [[ $GLOSSA_RC -eq 0 ]]; then
        log "parliament chamber II: UNANIMOUS CONSENT (self-agreement + truth + teeth + uniqueness + continuity) -- the lexicon is adopted"
        cp "$GW/cg_glossa_rules.iii" "$GSEALED_TABLE"
        cp "$GW/glossa.iii" "$GSEALED_ORGAN"
        GLOSSA_NOTE="ADOPTED (words=$GWORDS id=$GSID, $GLINKS links proven)"
    else
        log "$TAG $GLOSSA_NOTE"
    fi
fi

# ------------------------------ THE VERDICTS --------------------------------
printf '%s NOMOS:  %s\n'  "$TAG" "$NOMOS_NOTE"
printf '%s GLOSSA: %s\n' "$TAG" "$GLOSSA_NOTE"
if [[ "$NOMOS_NOTE" == ADOPTED* || "$GLOSSA_NOTE" == ADOPTED* ]]; then
    printf '%s a chamber ADOPTED -- the covenant ceremony is MANDATORY:\n' "$TAG"
    printf '%s   bash COMPILER/BOOT/covenant_ceremony.sh   (stdlib -> iiis-2 determinism -> iiis-3 fixpoint -> goldens)\n' "$TAG"
    printf '%s   then the judges: run_corpus.sh + iii-ergon census (ex run_standing_tools.sh, retired 2026-07-17) + run_meaning.sh\n' "$TAG"
fi
FINAL_RC=0
[[ ${NOMOS_RC:-0} -ne 0 ]] && FINAL_RC=${NOMOS_RC}
[[ $GLOSSA_RC -ne 0 && $FINAL_RC -eq 0 ]] && FINAL_RC=$GLOSSA_RC
exit $FINAL_RC
