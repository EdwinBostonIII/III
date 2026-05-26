#!/usr/bin/env bash
# Stage 3.18 multi-module test for module-scope const locality.
#
# Two modules each declare `const SHARED_K` (different values).  Pre-fix,
# both emitted a GLOBAL `L_SHARED_K` -> link collision.  Post-fix, const
# symbols are module-LOCAL, so the two .o files combine without a
# "multiple definition" error.  Asserts:
#   1. both modules compile,
#   2. ld -r of the two .o succeeds (no multiple-definition),
#   3. neither .o exports a GLOBAL (scl 2) L_SHARED_K symbol.

set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-0$BIN_SUFFIX}"
[[ -x "$IIIS" ]] || { echo "[const-scope] FATAL: iiis not found ($IIIS)" >&2; exit 2; }

TMP="$III_ROOT/STDLIB/build/const_scope"
mkdir -p "$TMP"
printf 'module mcs_a\nconst SHARED_K : u32 = 111u32\nfn mcs_a_get() -> u32 @export { return SHARED_K }\n' > "$TMP/mcs_a.iii"
printf 'module mcs_b\nconst SHARED_K : u32 = 222u32\nfn mcs_b_get() -> u32 @export { return SHARED_K }\n' > "$TMP/mcs_b.iii"

"$IIIS" "$TMP/mcs_a.iii" --compile-only --out "$TMP/mcs_a.o" >"$TMP/a.log" 2>&1 || { echo "[const-scope] FAIL: mcs_a compile"; exit 1; }
"$IIIS" "$TMP/mcs_b.iii" --compile-only --out "$TMP/mcs_b.o" >"$TMP/b.log" 2>&1 || { echo "[const-scope] FAIL: mcs_b compile"; exit 1; }

# Assert no GLOBAL (scl 2) L_SHARED_K in either object.
if objdump -t "$TMP/mcs_a.o" 2>/dev/null | grep -E "scl   2" | grep -q "SHARED_K"; then
    echo "[const-scope] FAIL: mcs_a still exports a GLOBAL L_SHARED_K (collision-prone)"; exit 1
fi
if objdump -t "$TMP/mcs_b.o" 2>/dev/null | grep -E "scl   2" | grep -q "SHARED_K"; then
    echo "[const-scope] FAIL: mcs_b still exports a GLOBAL L_SHARED_K (collision-prone)"; exit 1
fi

# Partial-link the two objects: a global same-named const would be a
# "multiple definition" error here.
set +e
ld -r "$TMP/mcs_a.o" "$TMP/mcs_b.o" -o "$TMP/combined.o" 2>"$TMP/ld.log"
LD_RC=$?
set -e
if [[ $LD_RC -ne 0 ]] || grep -qi "multiple definition" "$TMP/ld.log" 2>/dev/null; then
    echo "[const-scope] FAIL: ld -r collision (rc=$LD_RC):"; grep -i "multiple\|SHARED_K" "$TMP/ld.log" | head -3
    exit 1
fi

echo "[const-scope] PASS: two modules share const SHARED_K without collision (local symbols, ld -r rc=0)"
exit 0
