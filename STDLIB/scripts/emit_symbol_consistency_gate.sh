#!/usr/bin/env bash
# emit_symbol_consistency_gate.sh -- catches a class of sovereign-emitter regression that the
# bootstrap's stage1_corpus (compile-only) path cannot see:
#
#   INVARIANT (emitter self-consistency): every symbol the compiler marks `.global` in a module's
#   textual dump (<mod>.iii.o.s) MUST appear as a DEFINED (non-UND) symbol in the binary object
#   (<mod>.iii.o).  If the .o.s says `.global L_FOO` but the .o's symbol table lacks L_FOO, then any
#   EXTERNAL reference to L_FOO (e.g. the hand-written resolver_hot.s fast path) fails to link -- and
#   the full run_corpus (which force-links resolver_hot.o into every KAT) goes link-red, while
#   bootstrap stays green because stage1_corpus never links the stdlib.
#
# This is a DDC-style self-consistency check: the emitter's two outputs (binary .o, textual .o.s) must
# agree on exported symbols.  Green = they agree.  Red = an emitter regression dropped an export.
#
# No Python (L4).  Read-only; touches no .iii / no emitted byte -> zero seal impact.  Uses objdump for
# the binary symbol table (nm agrees; objdump -t is authoritative on this COFF).
#
# Usage:
#   bash emit_symbol_consistency_gate.sh            # scan every build/iii/<mod>.iii.o(.s) pair
#   bash emit_symbol_consistency_gate.sh <mod>...   # scan named modules (basename, no ext)

set -u
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
BUILD="$ROOT/STDLIB/build/iii"

# The binary symbol lister.  objdump -t prints defined symbols with a section index; UND = undefined.
defined_syms() { objdump -t "$1" 2>/dev/null | awk '$0 !~ /\*UND\*/ {print $NF}'; }

if [ "$#" -gt 0 ]; then
    mods=(); for m in "$@"; do mods+=("$BUILD/$m.iii.o.s"); done
else
    mods=("$BUILD"/*.iii.o.s)
fi

scanned=0; diverged=0; div_syms=0
for osrc in "${mods[@]}"; do
    [ -f "$osrc" ] || continue
    obj="${osrc%.s}"                       # <mod>.iii.o.s -> <mod>.iii.o
    [ -f "$obj" ] || continue
    scanned=$((scanned+1))
    # symbols the compiler DECLARED global in its own textual dump
    globals=$(grep -oE '^\s*\.global[l]?\s+[A-Za-z_.$][A-Za-z0-9_.$]*' "$osrc" | awk '{print $2}' | sort -u)
    [ -z "$globals" ] && continue
    # dropped = declared-global MINUS defined-in-.o (one comm join, not a grep per symbol)
    dropped=$(comm -23 <(printf '%s\n' "$globals") <(defined_syms "$obj" | sort -u))
    if [ -n "$dropped" ]; then
        echo "DIVERGENCE in $(basename "$obj"):"
        while IFS= read -r g; do
            [ -z "$g" ] && continue
            echo "    .global $g declared in .o.s but NOT exported in the .o (external refs to it will not link)"
            div_syms=$((div_syms+1))
        done <<< "$dropped"
        diverged=$((diverged+1))
    fi
done

echo "-------------------------------------------------------------"
echo "modules scanned: $scanned ; modules with dropped exports: $diverged ; symbols dropped: $div_syms"
if [ "$diverged" -eq 0 ]; then
    echo "EMIT SYMBOL CONSISTENCY: PASS (.o.s .global set == .o exported set)"
    exit 0
else
    echo "EMIT SYMBOL CONSISTENCY: FAIL -- the sovereign emitter dropped $div_syms declared global export(s)."
    echo "  => full run_corpus link-reds on every KAT that force-links resolver_hot.o; bootstrap (stage1_corpus) cannot see it."
    exit 1
fi
