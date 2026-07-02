#!/usr/bin/env bash
# run_stoma_kats.sh -- gate for the STOMA sovereign-CLI organ family (DOCS/III-STOMA-PLAN.md).
# DISJOINT standalone gate (concurrent-writer law): compiles the stoma_* organs once, then each
# corpus KAT compiles+links+runs for its TRUE exit code (99 = pass).  kernel32-only organs.
set -u
III="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
I2="$III/COMPILED/iiis-2.exe"
A="$III/STDLIB/iii/aether"
OUT="$III/STDLIB/build/stoma_kats"
mkdir -p "$OUT"
pass=0; fail=0

ORGANS="stoma_con stoma_proc stoma_pty stoma_journal stoma_line stoma_verb stoma_shell"
for m in $ORGANS; do
    "$I2" "$A/$m.iii" --compile-only --out "$OUT/$m.o" 2>"$OUT/$m.c.log" \
        || { echo "FAIL $m : organ compile"; tail -3 "$OUT/$m.c.log"; exit 1; }
done

run() {
    local name="$1" want="$2"; shift 2
    "$I2" "$III/STDLIB/corpus/$name.iii" --compile-only --out "$OUT/$name.o" 2>"$OUT/$name.c.log" \
        || { echo "FAIL  $name : compile"; tail -3 "$OUT/$name.c.log"; fail=$((fail+1)); return; }
    rm -f "$OUT/$name.exe"
    gcc "$OUT/$name.o" "$@" -lkernel32 -o "$OUT/$name.exe" 2>"$OUT/$name.l.log" \
        || { echo "FAIL  $name : link"; grep -i undefined "$OUT/$name.l.log" | head -3; fail=$((fail+1)); return; }
    timeout 60 "$OUT/$name.exe" >"$OUT/$name.run.log" 2>&1
    local rc=$?
    if [[ "$rc" == "$want" ]]; then echo "PASS  $name : exit $rc"; pass=$((pass+1));
    else echo "FAIL  $name : exit $rc (want $want)"; tail -2 "$OUT/$name.run.log"; fail=$((fail+1)); fi
}

run 2455_stoma_con   99 "$OUT/stoma_con.o"
run 2456_stoma_proc  99 "$OUT/stoma_proc.o"
run 2457_stoma_pty   99 "$OUT/stoma_pty.o"
run 2458_stoma_line  99 "$OUT/stoma_line.o"
run 2459_stoma_shell 99 "$OUT/stoma_verb.o" "$OUT/stoma_proc.o" "$OUT/stoma_journal.o" "$OUT/stoma_shell.o"

# ---- stoma.exe walking-skeleton: build (gcc dev-link here; sovbuild parity is the M5/M7 gate) + plain-mode smoke ----
"$I2" "$A/stoma.iii" --compile-only --out "$OUT/stoma.o" 2>"$OUT/stoma.c.log" \
    || { echo "FAIL stoma.iii : compile"; tail -3 "$OUT/stoma.c.log"; fail=$((fail+1)); }
if [[ -f "$OUT/stoma.o" ]]; then
    gcc "$OUT/stoma.o" "$OUT/stoma_con.o" "$OUT/stoma_line.o" "$OUT/stoma_verb.o" \
        "$OUT/stoma_shell.o" "$OUT/stoma_proc.o" "$OUT/stoma_journal.o" "$OUT/stoma_pty.o" \
        -lkernel32 -o "$OUT/stoma.exe" 2>"$OUT/stoma.l.log" \
        || { echo "FAIL stoma.exe : link"; grep -i undefined "$OUT/stoma.l.log" | head -3; fail=$((fail+1)); }
fi
if [[ -f "$OUT/stoma.exe" ]]; then
    # plain-mode smoke: pipe a script, expect help text + echo marker + exit-0 line in the transcript
    SMOKE="$( printf 'help\ncmd /c echo SMOKE_OK\nexit\n' | (cd "$OUT" && timeout 60 ./stoma.exe) 2>/dev/null )"
    if echo "$SMOKE" | grep -q 'STOMA verbs' && echo "$SMOKE" | grep -q 'SMOKE_OK' && echo "$SMOKE" | grep -q '\[exit 0\]'; then
        echo "PASS  stoma.exe : plain-mode smoke (help + spawn + exit)"; pass=$((pass+1))
    else
        echo "FAIL  stoma.exe : plain-mode smoke"; echo "--- transcript:"; echo "$SMOKE" | head -8; fail=$((fail+1))
    fi
fi

echo "=== STOMA KAT gate: PASS=$pass FAIL=$fail ==="
[[ "$fail" == 0 ]] && exit 0 || exit 1
