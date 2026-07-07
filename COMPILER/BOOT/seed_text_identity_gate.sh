#!/usr/bin/env bash
# seed_text_identity_gate.sh -- the seed<->self-host CODE-IDENTITY gate (the honest bar for iiis-0 vs iiis-2).
#
# THE QUESTION THIS CLOSES.  The frozen C seed `iiis-0` diverges from the self-hosted `iiis-2` on 27 of the
# stage1_corpus programs.  That divergence was tracked as "benign, washes out at the iiis-2==iiis-3 fixpoint" --
# an ASSERTION.  This gate replaces the assertion with a PROOF + an enforced, falsifiable check.
#
# WHAT THE DIVERGENCE ACTUALLY IS (root-caused, not guessed -- see DOCS/III-SEED-RODATA-DIVERGENCE.md):
#   * The `.text` (machine code) emitted by iiis-0 and iiis-2 is BYTE-IDENTICAL for every stage1_corpus program.
#   * The `.text` relocations are byte-identical and resolve to code symbols.  Where `.rodata` DIVERGES (the 27),
#     NO relocation references it -- those provenance strings are INERT (unreachable by running code).  This gate
#     ENFORCES that per-program: a divergent `.rodata` that IS referenced reddens the gate (RODATAREF).  (The 3
#     programs that do reference `.rodata` -- string literals -- have BYTE-IDENTICAL `.rodata`, so they are safe.)
#   * The entire whole-object divergence lives in `.rodata`: the module-provenance string pool
#     ("unify.iii", "arena.iii", "msvcrt", ...).  iiis-0's emit.c packs it run-together without dedup/NUL-tidy;
#     iiis-2's emit.iii dedups + NUL-terminates it tighter.  Since nothing relocates against `.rodata`, those
#     bytes are INERT metadata -- unreachable by the running program.  Hence: semantically null.
#
# THE TRUST-BEARING INVARIANT (this is what carries trust, and this is what we ENFORCE here):
#   For every stage1_corpus program, iiis-0 and iiis-2 must agree byte-for-byte on the CONTENT of every section
#   EXCEPT `.rodata`, and on every relocation.  i.e. identical code, identical data, identical control/unwind,
#   identical symbolic references -- divergence is permitted ONLY in the inert `.rodata` string pool.
#   Whole-object byte-identity of a FROZEN seed (which would require iiis-2 to reproduce emit.c's string-pool
#   quirk) is the WRONG bar and is deliberately not required.  "Identity where it carries trust, not everywhere."
#
# THE TEETH (run `--selftest`): the .text comparison detects a real code difference -- compiling two DIFFERENT
# programs and feeding them to the same comparator MUST report a .text divergence (RED).  A gate that cannot go
# red proves nothing.
#
# SCOPE (honest): this is the stage1_corpus PROXY for seed<->self-host code identity.  It is NOT the seed-DDC
# (Thompson) residual -- that remains separately OPEN (DOCS/SEED-DDC-ANALYSIS.md), needing an independent-lineage
# C compiler this host lacks.  This gate proves the self-host introduced ZERO codegen divergence vs the seed; it
# does not, by itself, attest the seed's own provenance.
#
# Usage:  bash seed_text_identity_gate.sh [--selftest] [--verbose]
# Exit:   0 = GATE PASS (code/data/relocs identical; divergence confined to inert .rodata)
#         1 = GATE FAIL (a non-.rodata section or a relocation diverged -- a REAL difference)
#         2 = ENV error (missing binary/tool)
set -uo pipefail
umask 022
export LC_ALL=C LANG=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT="$SCRIPT_DIR"
CORPUS="$BOOT/stage1_corpus"
I0="$III_ROOT/COMPILED/iiis-0.exe"
I2="$III_ROOT/COMPILED/iiis-2.exe"

VERBOSE=0; SELFTEST=0
for a in "$@"; do case "$a" in
  --verbose) VERBOSE=1 ;; --selftest) SELFTEST=1 ;;
  -h|--help) sed -n '1,40p' "$0"; exit 0 ;;
  *) echo "unknown arg: $a" >&2; exit 2 ;;
esac; done

log(){ printf '[seed-id] %s\n' "$*" >&2; }
command -v objcopy >/dev/null 2>&1 || { log "FAIL: objcopy not found (need binutils)"; exit 2; }
command -v objdump >/dev/null 2>&1 || { log "FAIL: objdump not found (need binutils)"; exit 2; }
command -v sha256sum >/dev/null 2>&1 || { log "FAIL: sha256sum not found (required as the seal WITNESS)"; exit 2; }
[ -x "$I0" ] || { log "FAIL: missing $I0"; exit 2; }
[ -x "$I2" ] || { log "FAIL: missing $I2"; exit 2; }
[ -d "$CORPUS" ] || { log "FAIL: missing corpus $CORPUS"; exit 2; }

# SEAL AUTHORSHIP (basal law): the seed seal-drift check below is an ATTESTATION,
# so it is sovereign-authored + GNU-witnessed (mhash_lib.sh).  REQUIRED: this gate
# runs after the stdlib exists (bootstrap stage 5), so the hasher is mintable.
# The per-SECTION hashes further down are equality PROBES for diff diagnosis,
# not seals -- they stay authorship-neutral (the documented boundary).
. "$BOOT/mhash_lib.sh"
mhash_init --require-sovereign || { log "FAIL: sovereign seal authorship unavailable"; exit 2; }

# --- EVERGREEN SEED-SEAL HYGIENE -------------------------------------------------------------------------------
# The seed's binary hash is build-variant-sensitive (different builds of iiis-0 emit IDENTICAL codegen but DIFFER
# in their own .text/.rodata -> the byte-hash flaps while the FUNCTION is invariant; see DOCS/III-TOOLCHAIN-MANIFEST.md).
# So the seed's TRUE trust is the codegen-equivalence proven below (iiis-0 ≡ iiis-2), NOT this byte-hash.  But the
# .mhash must still honestly attest the bytes it seals: a rebuild-without-reseal is the exact "seal-drift" this
# catches -- the seal can never be allowed to silently lie about which binary it covers.
I0_MHASH="$I0.mhash"
if [ -f "$I0_MHASH" ]; then
  sealed="$(cut -d' ' -f1 "$I0_MHASH")"
  actual="$(mhash_file "$I0")" || { log "FAIL: sovereign hash of the seed failed"; exit 2; }
  if [ "$sealed" != "$actual" ]; then
    log "FAIL: seed seal-drift -- iiis-0.exe ($actual) != its .mhash seal ($sealed)."
    log "      After confirming codegen-equivalence (below), re-seal sovereignly:  (. COMPILER/BOOT/mhash_lib.sh && cd COMPILED && printf '%s  iiis-0.exe\\n' \"\$(mhash_file iiis-0.exe)\" > iiis-0.exe.mhash)"
    exit 1
  fi
  [ "$VERBOSE" -eq 1 ] && log "seed seal: consistent ($actual)"
fi

W="$(mktemp -d "${TMPDIR:-/tmp}/seed-id.XXXXXX")"
trap '[ -n "${W:-}" ] && rm -rf "$W"' EXIT

# Compile $1=binary $2=relpath(from BOOT) $3=outfile ; one retry defeats transient resource failures.
compile(){ ( cd "$BOOT" && { timeout 25 "$1" "$2" --compile-only --out "$3" >/dev/null 2>&1 \
                          || timeout 25 "$1" "$2" --compile-only --out "$3" >/dev/null 2>&1; } ); }

# Section name list of an object (column-2 of objdump -h rows).
sections(){ objdump -h "$1" 2>/dev/null | awk '/^[[:space:]]+[0-9]+[[:space:]]/{print $2}'; }

# sha256 of the raw CONTENT of section $2 in object $1 (empty-sentinel if the section is absent/zero-length).
secsha(){ local f="$1" s="$2" b="$W/sec.bin"
  if objcopy -O binary --only-section="$s" "$f" "$b" 2>/dev/null && [ -s "$b" ]; then sha256sum "$b" | cut -d' ' -f1
  else echo "EMPTY:$s"; fi; }

# Normalised relocation dump (drop the filename header line so only records remain).
relocs(){ objdump -r "$1" 2>/dev/null | sed '1,2d'; }

# Compare two objects under the trust-bearing invariant.  Echoes a verdict token; return 0=benign, 1=REAL diverge.
# NOTE: seed_obj_equiv.sh is the CANONICAL single-definition oracle, and is exactly what build_iiis1.sh --check-corpus
# runs per program.  This gate INLINES the same logic on purpose: delegating to a per-program subprocess adds ~400
# Windows process spawns over the 60-program corpus (minutes -> timeout).  Keep the two in sync; oracle is the truth.
#   TEXTDIFF -> .text differs [fatal] | RELOCDIFF -> relocs differ [fatal] | SECSET -> section sets differ [fatal]
#   SECDIFF:S -> non-.rodata section S differs [fatal] | RODATAREF -> a divergent .rodata IS referenced [fatal]
#   RODATA -> only inert .rodata differs [ok] | IDENTICAL -> whole object byte-identical [ok]
compare(){ local o0="$1" o2="$2"
  if cmp -s "$o0" "$o2"; then echo "IDENTICAL"; return 0; fi
  if [ "$(secsha "$o0" .text)" != "$(secsha "$o2" .text)" ]; then echo "TEXTDIFF"; return 1; fi
  if [ "$(relocs "$o0")" != "$(relocs "$o2")" ]; then echo "RELOCDIFF"; return 1; fi
  local s0 s2; s0="$(sections "$o0" | grep -vx '.rodata' | sort)"; s2="$(sections "$o2" | grep -vx '.rodata' | sort)"
  if [ "$s0" != "$s2" ]; then echo "SECSET"; return 1; fi
  local s
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    if [ "$(secsha "$o0" "$s")" != "$(secsha "$o2" "$s")" ]; then echo "SECDIFF:$s"; return 1; fi
  done <<< "$s0"
  if   objdump -r "$o0" 2>/dev/null | awk 'NF>=3{print $3}' | grep -q 'rodata' \
    || objdump -r "$o2" 2>/dev/null | awk 'NF>=3{print $3}' | grep -q 'rodata'; then echo "RODATAREF"; return 1; fi
  echo "RODATA"; return 0
}

if [ "$SELFTEST" -eq 1 ]; then
  log "selftest: proving the .text comparison has teeth (two DIFFERENT programs must report TEXTDIFF)"
  compile "$I0" "stage1_corpus/01_return_const.iii" "$W/st_a.o" || { log "selftest compile A failed"; exit 2; }
  compile "$I0" "stage1_corpus/30_byte_index.iii"   "$W/st_b.o" || { log "selftest compile B failed"; exit 2; }
  v="$(compare "$W/st_a.o" "$W/st_b.o")"; rc=$?
  if [ "$v" = "TEXTDIFF" ] && [ $rc -ne 0 ]; then
    log "selftest PASS: comparator reports '$v' (rc=$rc) on two different programs -- the gate is not vacuous."
    exit 0
  else
    log "selftest FAIL: expected TEXTDIFF/rc!=0, got '$v'/rc=$rc -- the .text check is broken."
    exit 1
  fi
fi

n=0; textsame=0; rodata=0; identical=0; fails=0
FAILED=""
for prog in "$CORPUS"/*.iii; do
  name="$(basename "$prog" .iii)"; n=$((n+1))
  o0="$W/$name.0.o"; o2="$W/$name.2.o"
  if ! compile "$I0" "stage1_corpus/$name.iii" "$o0"; then log "WARN: iiis-0 could not compile $name (skipped)"; continue; fi
  if ! compile "$I2" "stage1_corpus/$name.iii" "$o2"; then log "WARN: iiis-2 could not compile $name (skipped)"; continue; fi
  # keystone: .text identical regardless of verdict path
  [ "$(secsha "$o0" .text)" = "$(secsha "$o2" .text)" ] && textsame=$((textsame+1))
  v="$(compare "$o0" "$o2")"; rc=$?
  case "$v" in
    IDENTICAL) identical=$((identical+1)) ;;
    RODATA)    rodata=$((rodata+1)); [ "$VERBOSE" -eq 1 ] && log "ok   $name : divergence confined to inert .rodata" ;;
    *)         fails=$((fails+1)); FAILED="$FAILED $name($v)"; log "FAIL $name : $v" ;;
  esac
done

log "-------------------------------------------------------------"
log "stage1_corpus programs compiled by both : $n"
log ".text (code) byte-identical iiis-0==iiis-2 : $textsame / $n"
log "whole-object identical                     : $identical"
log "divergence confined to inert .rodata       : $rodata"
log "REAL (non-.rodata) divergences             : $fails"
if [ "$fails" -ne 0 ]; then
  log "GATE FAIL -- a trust-bearing section or relocation diverged:$FAILED"
  exit 1
fi
if [ "$textsame" -ne "$n" ]; then
  log "GATE FAIL -- .text not identical on all programs ($textsame/$n)"
  exit 1
fi
log "GATE PASS -- iiis-0 and iiis-2 emit byte-identical code+data+relocs for all $n stage1_corpus programs;"
log "             the only divergence is the inert .rodata provenance string pool (unreachable by running code)."
exit 0
