#!/usr/bin/env bash
# STDLIB/scripts/run_testament.sh -- THE AUTARKEIA Alpha-0/Alpha-1 GATE (DOCS/III-AUTARKEIA-MAP.md).
#
# One command that proves the TESTAMENT machinery end to end:
#   [build]   iii-testament + iii-witness build from source through the pinned iiis-2 + the archive.
#   [keygen]  a deterministic SLH-DSA-SHA2-256s keypair from a seed FILE (ephemeral for the gate).
#   [emit]    a generation-0 testament.dat over the LIVE tree: 3,600+ committed files Merkle-rooted,
#             the mathesis records pinned, the FORGE chain RE-WALKED from its committed bytes, the
#             RADICAL certificate re-derived, the standing tools + spore scripts digested, SLH-DSA-signed.
#   [show]    the sealed pins print (the pin-migration source).
#   [tier-1]  the stranger's minutes-check: format + signature + key pin, NO toolchain, NO tree.
#   [full]    the total re-derivation against the committed tree (every digest recomputed).
#   [tamper]  the FULL battery, each class its DISTINCT red: body byte (11) / wrong key (11) /
#             manifest (14) / file content (14) / generation link (12) / key-continuity (15) /
#             monotone law (15) -- plus a chained gen-1 that verifies GREEN with its parent.
#   [determ]  two emissions on an unchanged tree share a BYTE-IDENTICAL unsigned body.
#   [pin]     THE PIN-MIGRATION PROOF: the testament's RADICAL certificate == the value run_mathesis.sh
#             computes in bash (sha256(head|rows|chain)) -- the truth that lived as a bash string is now
#             re-derivable from the SIGNED spine.  Bash is demoted from author of the pin to a consumer.
#
# Exit 0 = every check green ; 1 = a named red ; 2 = env.  Slow by design (two SLH-DSA-256s signings).
set -u
IFS=$'\n\t'
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) X=".exe" ;;
    *)                                  X=""    ;;
esac
W="$ROOT/STDLIB/build/testament"; mkdir -p "$W"
say() { printf '%s\n' "$*"; }
FAIL=0
red() { say "RED  $*"; FAIL=1; }
grn() { say "PASS $*"; }

# ---- build the two tools ----
say "[testament] == build iii-testament + iii-witness =="
bash "$ROOT/COMPILER/BOOT/build_iii_testament.sh" --out "$W/iii-testament$X" >"$W/build_t.log" 2>&1 \
    || { red "iii-testament build (see $W/build_t.log)"; exit 1; }
bash "$ROOT/COMPILER/BOOT/build_iii_witness.sh" --out "$W/iii-witness$X" >"$W/build_w.log" 2>&1 \
    || { red "iii-witness build (see $W/build_w.log)"; exit 1; }
T="$W/iii-testament$X"; V="$W/iii-witness$X"
grn "both tools built from source"

# ---- the manifest over the committed tree (working-tree state of every tracked path) ----
MAN="$W/MANIFEST.txt"
( cd "$ROOT" && git ls-files -- \
    'COMPILER/BOOT/*.iii' 'COMPILER/BOOT/*.c' 'COMPILER/BOOT/*.h' 'COMPILER/BOOT/*.sh' \
    'STDLIB/iii/**/*.iii' 'STDLIB/sovir/*.iii' 'STDLIB/sovir/*.sh' \
    'STDLIB/corpus/*.iii' 'STDLIB/scripts/*.sh' 'DOCS/*.md' 'DOCS/*.log' 'DOCS/*.txt' \
    2>/dev/null | LC_ALL=C sort -u > "$MAN" )
NMAN=$(wc -l < "$MAN" | tr -d ' ')
[ "$NMAN" -gt 100 ] || { red "manifest too small ($NMAN)"; exit 1; }
grn "manifest: $NMAN committed files"

# ---- keygen (ephemeral: the gate proves MECHANICS, not the canonical seal) ----
head -c 96 /dev/urandom > "$W/seed.bin" 2>/dev/null || { say "[testament] env: no /dev/urandom"; exit 2; }
"$T" keygen "$W/seed.bin" "$W/pk.bin" "$W/sk.bin" >/dev/null 2>&1 || { red "keygen"; exit 1; }
[ "$(wc -c < "$W/pk.bin")" -eq 64 ] && [ "$(wc -c < "$W/sk.bin")" -eq 128 ] || { red "key sizes"; exit 1; }
grn "keygen: pk 64 B, sk 128 B"

# ---- emit gen-0 ----
( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/gen0.dat" none none ) >"$W/emit0.log" 2>&1 \
    || { red "emit gen-0 (see $W/emit0.log)"; exit 1; }
grn "emit gen-0 ($(wc -c < "$W/gen0.dat") B): $(tail -1 "$W/emit0.log")"

# ---- show + the recorded pins ----
"$T" show "$W/gen0.dat" > "$W/show.txt" 2>&1 || { red "show"; exit 1; }
grep -q "^RECORD DOCS/MATHESIS-RADICAL-ROUND1.log .* head=2a84e3b73394d86ed00a1146af0bc3c7cb3cd20bd06b83f922cdbfbd9e7ca7f8 rows=195 chain=5023$" "$W/show.txt" \
    && grn "RADICAL pins re-derived (head 2a84e3b7.., 195 rows, chain 5023)" \
    || red "RADICAL pins drifted in the testament"
grep -q "^RECORD DOCS/MATHESIS-FORGE-ROUND1.log .* head=c28e85ac423faa3945927b9398d358dbaec2ed63901a93d523bc72b017ab978e rows=69 chain=69$" "$W/show.txt" \
    && grn "FORGE chain re-walk reproduced the sealed head (c28e85ac.., 69 rows)" \
    || red "FORGE chain re-walk head drifted"

# ---- tier-1 (no tree) ----
"$V" verify "$W/gen0.dat" "$W/pk.bin" >/dev/null 2>&1 && grn "Tier-1 verify (format+signature+key-pin)" || red "Tier-1 verify"
# ---- full (re-derive vs tree) ----
( cd "$ROOT" && "$V" verify "$W/gen0.dat" "$W/pk.bin" none . "$MAN" ) >/dev/null 2>&1 \
    && grn "full re-derivation against the tree" || red "full verify"

# ---- the tamper battery: each its DISTINCT red ----
tam() { local label="$1" want="$2"; shift 2; ( cd "$ROOT" && "$@" ) >/dev/null 2>&1; local rc=$?
        if [ "$rc" -eq "$want" ]; then grn "tamper $label -> $rc (distinct)"; else red "tamper $label want=$want got=$rc"; fi; }
cp "$W/gen0.dat" "$W/tA.dat"; printf '\xFF' | dd of="$W/tA.dat" bs=1 seek=200 count=1 conv=notrunc 2>/dev/null
tam "body-byte" 11 "$V" verify "$W/tA.dat" "$W/pk.bin"
head -c 64 /dev/urandom > "$W/wrongpk.bin" 2>/dev/null
tam "wrong-key" 11 "$V" verify "$W/gen0.dat" "$W/wrongpk.bin"
sed '1d' "$MAN" > "$W/man_tam.txt"
tam "manifest"  14 "$V" verify "$W/gen0.dat" "$W/pk.bin" none . "$W/man_tam.txt"
# file-content tamper: backup -> flip -> verify -> restore (sha256-guarded)
CF="$ROOT/STDLIB/corpus/2600_mathesis_admit.iii"
if [ -f "$CF" ]; then
    cp "$CF" "$W/cf.bak"; H0=$(sha256sum "$CF" | cut -d' ' -f1); printf '\n' >> "$CF"
    tam "file-content" 14 "$V" verify "$W/gen0.dat" "$W/pk.bin" none . "$MAN"
    cp "$W/cf.bak" "$CF"; H1=$(sha256sum "$CF" | cut -d' ' -f1)
    [ "$H0" = "$H1" ] && grn "content-tamper file restored byte-identical" || red "content-tamper RESTORE FAILED"
fi

# ---- determinism: a second emission shares the byte-identical unsigned body ----
( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/gen0b.dat" none none ) >/dev/null 2>&1 || { red "second emit"; }
if [ -f "$W/gen0b.dat" ]; then
    # SLH-DSA-SHA2-256s signing is DETERMINISTIC (FIPS 205, hedged variant not used), so the
    # WHOLE FILE -- signature included -- must reproduce byte-for-byte on an unchanged tree.
    if cmp -s "$W/gen0.dat" "$W/gen0b.dat"; then
        grn "determinism: FULL FILE byte-identical across two emissions (deterministic signing)"
    else red "determinism: emissions diverged"; fi
fi

# ---- THE PIN-MIGRATION PROOF: testament RADICAL cert == bash sha256sum ----
TS_CERT=$(grep '^CERT RADICAL ' "$W/show.txt" | sed 's/.*value=//')
BASH_CERT=$(printf '%s' "2a84e3b73394d86ed00a1146af0bc3c7cb3cd20bd06b83f922cdbfbd9e7ca7f8|195|5023" | sha256sum | cut -d' ' -f1)
if [ "$TS_CERT" = "$BASH_CERT" ] && [ -n "$TS_CERT" ]; then
    grn "PIN MIGRATION: testament RADICAL cert == bash sha256sum ($TS_CERT)"
else red "PIN MIGRATION: cert mismatch (testament=$TS_CERT bash=$BASH_CERT)"; fi

# ---- the COVENANT classes, proven here too: generation link (12) + key-continuity/monotone (15) ----
say "[testament] == the generation chain + the covenant tamper classes =="
( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/gen1.dat" "$W/gen0.dat" none ) >"$W/emit1.log" 2>&1 \
    && grn "gen-1 emitted, chained to gen-0" \
    || red "gen-1 emit (see $W/emit1.log)"
tam "gen-1 verify WITH parent gen-0 -> 0 (link+continuity+monotone all green)" 0 \
    "$V" verify "$W/gen1.dat" "$W/pk.bin" "$W/gen0.dat"
# wrong parent: a testament may NEVER be its own parent -- its stored parent digest cannot
# equal its own file hash (and its generation index cannot be its own predecessor).
tam "generation-link (self-parent) -> 12" 12 \
    "$V" verify "$W/gen1.dat" "$W/pk.bin" "$W/gen1.dat"
# key swap: a fresh keypair may not continue the chain -- emit-side continuity refusal.
head -c 96 /dev/urandom > "$W/seed2.bin"
"$T" keygen "$W/seed2.bin" "$W/pk2.bin" "$W/sk2.bin" >/dev/null 2>&1 || red "second keygen"
tam "key-continuity (emit with a swapped keypair) -> 15" 15 \
    "$T" emit . "$MAN" "$W/sk2.bin" "$W/pk2.bin" "$W/gen1bad.dat" "$W/gen0.dat" none
# monotone law: dropping ONE corpus KAT from the manifest shrinks BEARER (and TREE) vs the
# parent -- the walk completes and the MONOTONE refusal fires (emit-side).
grep -v '^STDLIB/corpus/2600_mathesis_admit\.iii$' "$MAN" > "$W/man_small.txt"
tam "monotone law (one KAT dropped vs parent) -> 15" 15 \
    "$T" emit . "$W/man_small.txt" "$W/sk.bin" "$W/pk.bin" "$W/gen1small.dat" "$W/gen0.dat" none

say ""
if [ "$FAIL" -eq 0 ]; then say "[testament] ALL GREEN -- the AUTARKEIA spine + witness are proven end to end."; exit 0
else say "[testament] RED -- a check failed above."; exit 1; fi
