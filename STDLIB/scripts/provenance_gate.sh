#!/usr/bin/env bash
# provenance_gate.sh -- down-only ratchet on PHANTOM `from "*.c"` provenance tags (independence H).
#
# THE FACT (falsified 2026-07-06): 742 of the 779 `from "*.c"` extern tags name .c files that DO NOT
# EXIST (ast_accessors.c, sema_accessors.c, lex_runtime.c, emit_accessors.c, cg_r3_xii.c,
# sema_xii_adapter.c) -- the symbols are @export-defined in the real .iii modules (ast.iii, sema.iii,
# ...) and resolved by NAME at link time.  The compiler NEVER opens the file: proven because the tree
# builds + runs green while those files are absent.
#
# BUT the tag is EMITTED into the object as an `.ascii "<name>\0"` provenance string, so rewriting a tag
# is CODEGEN-NEUTRAL (the .text/instructions are byte-identical -- verified by diffing .o.s) yet
# GOLDEN-MOVING (the emitted string bytes change).  Therefore the bulk rewrite to the real .iii providers
# must ride a compiler RE-SEAL (batched with the sovereign-default re-seal), NOT a "byte-identical goldens"
# assumption.  This gate does NOT rewrite; it PINS the phantom-tag census down-only so the count can only
# shrink as the rewrite lands, and a NEW phantom tag (a fresh lie) reddens the build.
#
# rc captured directly.  Exit 0 = at/under pin; 3 = over pin (a phantom tag was added); 2 = env.
set -u
export LC_ALL=C
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PIN_FILE="${PROVENANCE_PIN_FILE:-$SCRIPT_DIR/provenance_pin.txt}"
say(){ printf '[provenance] %s\n' "$*"; }

[ -f "$PIN_FILE" ] || { say "FATAL: pin file missing: $PIN_FILE"; exit 2; }
PIN="$(awk -F= '/^PHANTOM_C_TAGS_MAX=/{print $2; exit}' "$PIN_FILE")"
[ -n "$PIN" ] || { say "FATAL: PHANTOM_C_TAGS_MAX absent from $PIN_FILE"; exit 2; }

# Count `from "X.c"` tags whose X.c does NOT exist under COMPILER/BOOT (the phantom ones).  A tag whose
# .c really exists (hexad_check.c, iii_cg_pe_iiis1.c) is a genuine C TU reference -- not counted.
count=0
while IFS= read -r line; do
    c="$(printf '%s\n' "$line" | sed -E 's/.*from "([^"]*\.c)".*/\1/')"
    [ -z "$c" ] && continue
    if [ ! -f "$ROOT/COMPILER/BOOT/$c" ] && [ ! -f "$ROOT/STDLIB/iii/$c" ]; then count=$((count+1)); fi
done < <(grep -rhoE 'from "[^"]*\.c"' "$ROOT/COMPILER/BOOT" "$ROOT/STDLIB/iii" --include="*.iii" 2>/dev/null)

say "phantom from-\"*.c\" tags = $count (pin $PIN, down-only)"
if [ "$count" -gt "$PIN" ]; then
    say "RED: phantom-tag census $count > pin $PIN -- a NEW phantom .c tag was added; point it at the real .iii provider"
    exit 3
fi
say "GATE GREEN"
exit 0
