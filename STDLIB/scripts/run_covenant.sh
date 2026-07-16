#!/usr/bin/env bash
# STDLIB/scripts/run_covenant.sh -- THE AUTARKEIA Alpha-3 GATE: THE COVENANT (DOCS/III-AUTARKEIA-MAP.md).
#
# Alpha-2 gave III a sovereign JUDGE.  Alpha-3 makes trust EVERGREEN and COMPOUNDING: a testament is
# not a snapshot but a link in a chain whose *core* is host- and generation-invariant by construction,
# enforced by iii-judge and co-signed by a live ML-DSA quorum -- every faculty already in the tree, no
# island.  This gate proves the covenant end to end:
#
#   [build]  iii-testament + iii-witness + iii-judge + iii-crypto, all from source (pinned iiis-2 + archive).
#   [emit]   three testaments over the LIVE committed tree:
#              gen0   (parent none)               -- derivation A
#              gen0b  (parent none)               -- derivation B, INDEPENDENT of A
#              gen1   (parent gen0)               -- the next generation, chained
#   [core]   core(T) = the HOST- and GENERATION-invariant subset of `iii-testament show`
#              (TREE root, SEED count, BEARER kats, MATHESIS RECORD heads, CERT values) -- explicitly
#              EXCLUDING generation/parent/pk/TOOLS/EXEC/SPORE -- folded to a single root by iii-judge.
#   [equation] THE COVENANT EQUATION, proven on this host:
#              core(gen0) == core(gen0b)   two INDEPENDENT derivations agree  (the cross-host precondition)
#              core(gen1) == core(gen0)    core is generation-invariant while gen/parent DID change
#              => "evergreen as an equation": the sealed core is a pure function of committed truth.
#   [ratchet] iii-judge pin enforces the MONOTONE LAW on the generation counter (0,1 up = PASS; a
#              regression to 0 = BREAK).  A generation may never go backward.
#   [FED]    a live ML-DSA (FIPS 204) 3-of-3 quorum CO-SIGNS the covenant core via iii-crypto; a
#              tampered core is co-signed by NONE (adversarial).  No new protocol -- the sealed faculty.
#
# Exit 0 = the covenant holds ; 1 = a named red ; 2 = env.  Slow by design (three SLH-DSA-256s signings).
#
# SCOPE (honest): the covenant EQUATION and its full enforcement + FED quorum are proven here on one
# host.  core(T) is host-invariant BY CONSTRUCTION (it omits the per-ISA TOOLS digests); the physical
# second Gamma host that makes the 2-host claim concrete is future germination work (Alpha-3 tail).
set -u
IFS=$'\n\t'
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) X=".exe" ;;
    *)                                  X=""    ;;
esac
W="$ROOT/STDLIB/build/covenant"; mkdir -p "$W"
say() { printf '%s\n' "$*"; }
FAIL=0
red() { say "RED  $*"; FAIL=1; }
grn() { say "PASS $*"; }

# ---- build the four tools from source ----
say "[covenant] == build iii-testament + iii-witness + iii-judge + iii-crypto =="
bash "$ROOT/COMPILER/BOOT/build_iii_testament.sh" --out "$W/iii-testament$X" >"$W/b_t.log" 2>&1 || { red "iii-testament build"; exit 1; }
bash "$ROOT/COMPILER/BOOT/build_iii_witness.sh"   --out "$W/iii-witness$X"   >"$W/b_w.log" 2>&1 || { red "iii-witness build"; exit 1; }
bash "$ROOT/COMPILER/BOOT/build_iii_judge.sh"     --out "$W/iii-judge$X"     >"$W/b_j.log" 2>&1 || { red "iii-judge build"; exit 1; }
bash "$ROOT/COMPILER/BOOT/build_iii_crypto.sh"    --out "$W/iii-crypto$X"    >"$W/b_c.log" 2>&1 || { red "iii-crypto build"; exit 1; }
T="$W/iii-testament$X"; V="$W/iii-witness$X"; JU="$W/iii-judge$X"; CR="$W/iii-crypto$X"
grn "four tools built from source"

# ---- manifest over the committed tree ----
MAN="$W/MANIFEST.txt"
( cd "$ROOT" && git ls-files -- \
    'COMPILER/BOOT/*.iii' 'COMPILER/BOOT/*.c' 'COMPILER/BOOT/*.h' 'COMPILER/BOOT/*.sh' \
    'STDLIB/iii/**/*.iii' 'STDLIB/sovir/*.iii' 'STDLIB/sovir/*.sh' \
    'STDLIB/corpus/*.iii' 'STDLIB/scripts/*.sh' 'DOCS/*.md' 'DOCS/*.log' 'DOCS/*.txt' \
    2>/dev/null | LC_ALL=C sort -u > "$MAN" )
NMAN=$(wc -l < "$MAN" | tr -d ' ')
[ "$NMAN" -gt 100 ] || { red "manifest too small ($NMAN)"; exit 1; }
grn "manifest: $NMAN committed files"

# ---- ephemeral SLH-DSA key for the testament emissions ----
head -c 96 /dev/urandom > "$W/seed.bin" 2>/dev/null || { say "[covenant] env: no /dev/urandom"; exit 2; }
"$T" keygen "$W/seed.bin" "$W/pk.bin" "$W/sk.bin" >/dev/null 2>&1 || { red "keygen"; exit 1; }
grn "SLH-DSA keypair (ephemeral, gate proves MECHANICS)"

# ---- emit gen0, gen0b (independent), gen1 (chained) ----
say "[covenant] == emit gen0, gen0b (independent), gen1 (chained to gen0) =="
( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/gen0.dat"  none        none ) >"$W/e0.log"  2>&1 || { red "emit gen0";  exit 1; }
( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/gen0b.dat" none        none ) >"$W/e0b.log" 2>&1 || { red "emit gen0b"; exit 1; }
( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/gen1.dat"  "$W/gen0.dat" none ) >"$W/e1.log"  2>&1 || { red "emit gen1";  exit 1; }
grn "three testaments emitted ($(wc -c < "$W/gen0.dat") / $(wc -c < "$W/gen0b.dat") / $(wc -c < "$W/gen1.dat") B)"

# the chain must verify with its parent (witness), or the covenant is vacuous
( cd "$ROOT" && "$V" verify "$W/gen1.dat" "$W/pk.bin" "$W/gen0.dat" ) >/dev/null 2>&1 \
    && grn "gen1 verifies against parent gen0 (link + continuity + monotone)" \
    || red "gen1 did not verify against gen0"

# ---- core(T): the host- and generation-invariant subset, folded by iii-judge ----
core_of() {   # <dat> <tag>  -> echoes the 64-hex covenant core root
    local dat="$1" tag="$2"
    "$T" show "$dat" > "$W/show_$tag.txt" 2>&1 || { red "show $tag"; return 1; }
    # host- & generation-invariant lines ONLY (drop generation/parent/pk/SPORE/TOOLS/EXEC):
    grep -E '^(TREE|SEED|BEARER|RECORD|CERT) ' "$W/show_$tag.txt" > "$W/core_$tag.txt"
    "$JU" fold "$W/core_$tag.txt" 2>/dev/null | grep -o 'root=[0-9a-f]*' | sed 's/root=//'
}
say "[covenant] == core(T) = iii-judge fold of the host-invariant show lines =="
CA="$(core_of "$W/gen0.dat"  A)"
CB="$(core_of "$W/gen0b.dat" B)"
C1="$(core_of "$W/gen1.dat"  1)"
NLINES=$(wc -l < "$W/core_A.txt" | tr -d ' ')
[ "$NLINES" -ge 5 ] && grn "core carries $NLINES host-invariant rows (TREE/SEED/BEARER/RECORD/CERT)" \
    || red "core suspiciously small ($NLINES rows)"

# ---- THE COVENANT EQUATION ----
say "[covenant] == THE COVENANT EQUATION =="
if [ -n "$CA" ] && [ "$CA" = "$CB" ]; then
    grn "core(gen0) == core(gen0b): two INDEPENDENT derivations agree ($CA)"
else red "covenant equation broken: core(gen0)=$CA core(gen0b)=$CB"; fi

# gen0 and gen1 MUST differ in generation/parent -- else the invariance test is trivial
G0="$(grep '^generation ' "$W/show_A.txt" 2>/dev/null)"
G1="$(grep '^generation ' "$W/show_1.txt" 2>/dev/null)"
if [ -n "$G0" ] && [ "$G0" != "$G1" ]; then
    grn "generation/parent DID advance (gen0: '${G0}'  ->  gen1: '${G1}')"
else red "generation/parent did not advance -- invariance test would be vacuous"; fi

if [ -n "$CA" ] && [ "$C1" = "$CA" ]; then
    grn "core(gen1) == core(gen0): the core is GENERATION-INVARIANT -- evergreen as an equation"
else red "evergreen equation broken: core(gen1)=$C1 core(gen0)=$CA"; fi

# ---- MONOTONE LAW via iii-judge pin ----
say "[covenant] == monotone law: iii-judge pin ratchets the generation counter =="
rm -f "$W/gen_led.txt"
"$JU" pin "$W/gen_led.txt" generation 0 up >/dev/null 2>&1; r0=$?
"$JU" pin "$W/gen_led.txt" generation 1 up >/dev/null 2>&1; r1=$?
"$JU" pin "$W/gen_led.txt" generation 0 up >/dev/null 2>&1; r2=$?
if [ "$r0" -eq 0 ] && [ "$r1" -eq 0 ] && [ "$r2" -eq 1 ]; then
    grn "pin: gen 0->1 accepted (up), regression to 0 REFUSED (BREAK) -- a generation cannot go backward"
else red "monotone ratchet: r0=$r0 r1=$r1 r2=$r2 (want 0 0 1)"; fi

# ---- FED: a live ML-DSA 3-of-3 quorum CO-SIGNS the covenant core ----
say "[covenant] == FED: ML-DSA (FIPS 204) 3-of-3 quorum co-signs the covenant core =="
printf '%s' "$CA" > "$W/core.bin"
q=0
k=1
while [ "$k" -le 3 ]; do
    printf '%-32.32s' "III-COVENANT-FED-QUORUM-KEY-$k" > "$W/fed_seed_$k.bin"   # EXACTLY 32 B by construction
    "$CR" keygen 2 "$W/fed_seed_$k.bin" "$W/fed_pk_$k.bin" "$W/fed_sk_$k.bin" >/dev/null 2>&1 || red "fed keygen $k"
    "$CR" sign   2 "$W/fed_sk_$k.bin"  "$W/core.bin" "$W/fed_sig_$k.bin"       >/dev/null 2>&1 || red "fed sign $k"
    if "$CR" verify 2 "$W/fed_pk_$k.bin" "$W/core.bin" "$W/fed_sig_$k.bin" >/dev/null 2>&1; then q=$((q+1)); fi
    k=$((k+1))
done
[ "$q" -eq 3 ] && grn "FED quorum: 3-of-3 ML-DSA co-signatures verify over the covenant core" \
    || red "FED quorum only $q-of-3 verified"

# adversarial: a tampered core must be co-signed by NONE
printf '%s' "${CA}00" > "$W/core_bad.bin"
qb=0
k=1
while [ "$k" -le 3 ]; do
    if "$CR" verify 2 "$W/fed_pk_$k.bin" "$W/core_bad.bin" "$W/fed_sig_$k.bin" >/dev/null 2>&1; then qb=$((qb+1)); fi
    k=$((k+1))
done
[ "$qb" -eq 0 ] && grn "FED adversarial: a tampered core is co-signed by NONE (0-of-3)" \
    || red "tampered core accepted by $qb signer(s)"

say ""
if [ "$FAIL" -eq 0 ]; then
    say "[covenant] ALL GREEN -- AUTARKEIA Alpha-3: the covenant holds."
    say "[covenant] core = $CA  (host- & generation-invariant; iii-judge-folded; ML-DSA 3-of-3 co-signed)"
    exit 0
else
    say "[covenant] RED -- a check failed above."
    exit 1
fi
