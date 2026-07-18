#!/usr/bin/env bash
# STDLIB/sovir/run_event_waist.sh -- THE EVENT-PRIMARY WAIST GATE (family owner).
#
# svir_event.iii is route V: an SVIR executor whose ONLY product is an append-only retirement log;
# the program's output and result are read out of the log by a validating fold (state = fold over
# history -- the omnia/event_substrate inversion carried to the waist's own execution semantics).
# Stages:
#   [1] fresh-build the TUs (organ + driver + reference interp) with the pinned in-tree iiis-2
#   [2] the organ-law gates: corpus 2750 (fold laws + tamper teeth) / 2751 (replay independence +
#       two-path prefix arm) / 2752 (recurrence instrument, positive AND negative arm) -> exit 99 each
#   [3] fresh-build the PRODUCTION cg_svir harness (the same 8 TUs the sealed backend gate builds)
#   [4] THE DIFFERENTIAL: for EVERY square probe (the meaning campaign's real theater), produce the
#       real SVIR module via cg_svir, then route S (svir_interp, state-primary reference) and
#       route V (svir_event, event-primary) must agree on rc AND stdout bytes
#   [5] teeth on REAL module bytes: --tamper must refuse 193; --stats twice must be byte-identical
# Exit: 0 green | 1 red | 2 env.  Anti-vacuity: every stage prints its count; an empty arm is FATAL.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT="$III_ROOT/COMPILER/BOOT"
SQ_DIR="$BOOT/square_probes"
W="$III_ROOT/STDLIB/build/eventwaist"
mkdir -p "$W"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
[[ -x "$IIIS" ]] || { echo "[event-waist] FATAL: no iiis-2 at $IIIS"; exit 2; }
[[ -f "$LIB" ]] || { echo "[event-waist] FATAL: no libiii_native.a"; exit 2; }
say() { printf '%s\n' "$*"; }
FAIL=0

say "[event-waist] == [1] fresh TU builds (pinned $IIIS) =="
for tu in svir_event svir_event_main svir_interp; do
    rm -f "$W/$tu.o"
    "$IIIS" "$SCRIPT_DIR/$tu.iii" --compile-only --out "$W/$tu.o" >"$W/_c_$tu.log" 2>&1 || { echo "[event-waist] FATAL: compile $tu"; exit 2; }
done
say "[event-waist] 3 TUs fresh"

say "[event-waist] == [2] the organ-law gates (2750/2751/2752) =="
KATN=0
for kat in 2750_event_waist_laws 2751_event_waist_replay 2752_event_waist_recurrence; do
    KATN=$((KATN+1))
    rm -f "$W/$kat.o" "$W/$kat$BIN_SUFFIX"
    "$IIIS" "$III_ROOT/STDLIB/corpus/$kat.iii" --compile-only --out "$W/$kat.o" >"$W/_c_$kat.log" 2>&1 || { say "RED $kat: compile"; FAIL=1; continue; }
    gcc "$W/$kat.o" "$W/svir_event.o" -o "$W/$kat$BIN_SUFFIX" >"$W/_l_$kat.log" 2>&1 || { say "RED $kat: link"; FAIL=1; continue; }
    "$W/$kat$BIN_SUFFIX" >"$W/_r_$kat.out" 2>&1
    rc=$?
    if [[ $rc -eq 99 ]]; then say "PASS $kat (99)"; else say "RED $kat: rc=$rc"; FAIL=1; fi
done

say "[event-waist] == [3] fresh cg_svir harness (production front-end + SVIR backend) =="
for tu in cg_sha lex_rt lex ast parse eval cg_svir cg_svir_main; do
    "$IIIS" "$BOOT/$tu.iii" --compile-only --out "$W/h_$tu.o" >"$W/_ch_$tu.log" 2>&1 || { echo "[event-waist] FATAL: compile $tu"; exit 2; }
done
CG="$W/cg_svir$BIN_SUFFIX"
rm -f "$CG"
_ok=0
for _la in 1 2 3 4 5; do
    gcc "$W/h_cg_sha.o" "$W/h_lex_rt.o" "$W/h_lex.o" "$W/h_ast.o" "$W/h_parse.o" "$W/h_eval.o" "$W/h_cg_svir.o" "$W/h_cg_svir_main.o" "$LIB" -lws2_32 -lkernel32 -o "$CG" >/dev/null 2>&1 && [[ -x "$CG" ]] && { _ok=1; break; }
    sleep 1
done
[[ $_ok -eq 1 ]] || { echo "[event-waist] FATAL: link cg_svir"; exit 2; }
say "[event-waist] cg_svir harness fresh"

say "[event-waist] == [4] THE DIFFERENTIAL: route S (state-primary) == route V (event-primary) =="
IND_DIR="$III_ROOT/STDLIB/independence"
SQN=0; SQPASS=0; SQEXCL=0
for src in "$SQ_DIR"/sq*.iii "$IND_DIR/indep_ops.iii" "$IND_DIR/indep_isqrt.iii"; do
    [[ -f "$src" ]] || continue
    SQN=$((SQN+1)); base="$(basename "$src" .iii)"
    SW="$W/w_$base"; mkdir -p "$SW"
    "$CG" "$src" > "$SW/gen_svir.iii" 2>/dev/null
    [[ -s "$SW/gen_svir.iii" ]] || { say "RED $base: cg_svir emitted nothing"; FAIL=1; continue; }
    ( cd "$SW" && "$IIIS" gen_svir.iii --compile-only --out gen_svir.o >/dev/null 2>&1 ) || { say "RED $base: gen_svir compile"; FAIL=1; continue; }
    rm -f "$SW/route_s$BIN_SUFFIX" "$SW/route_v$BIN_SUFFIX"
    gcc "$SW/gen_svir.o" "$W/svir_interp.o" "$LIB" -lws2_32 -lkernel32 -o "$SW/route_s$BIN_SUFFIX" >/dev/null 2>&1 || { say "RED $base: route-S link"; FAIL=1; continue; }
    gcc "$SW/gen_svir.o" "$W/svir_event.o" "$W/svir_event_main.o" -o "$SW/route_v$BIN_SUFFIX" >/dev/null 2>&1 || { say "RED $base: route-V link"; FAIL=1; continue; }
    timeout 120 "$SW/route_s$BIN_SUFFIX" > "$SW/out_s.txt" 2>&1
    RCS=$?
    timeout 120 "$SW/route_v$BIN_SUFFIX" > "$SW/out_v.txt" 2>&1
    RCV=$?
    if [[ $RCV -eq 190 || $RCV -eq 192 ]]; then
        say "EXCLUDED-BY-CAPACITY $base (route-V refused $RCV; log cap is the named envelope)"
        SQEXCL=$((SQEXCL+1)); continue
    fi
    if [[ $RCS -eq 198 && $RCV -eq 198 ]]; then
        say "EXCLUDED-VACUOUS $base (both routes refuse the unresolved import -- agreement proves nothing)"
        SQEXCL=$((SQEXCL+1)); continue
    fi
    if [[ "$RCS" == "$RCV" ]] && cmp -s "$SW/out_s.txt" "$SW/out_v.txt"; then
        EVN="$(timeout 120 "$SW/route_v$BIN_SUFFIX" --stats 2>/dev/null | tr -d '\r' | grep -o 'EVN=[0-9]*' | head -1)"
        say "AGREE $base rc=$RCS bytes=$(wc -c < "$SW/out_s.txt") $EVN"
        SQPASS=$((SQPASS+1))
    else
        say "SPLIT $base: S=$RCS V=$RCV out-cmp=$(cmp -s "$SW/out_s.txt" "$SW/out_v.txt" && echo same || echo DIFF)"
        FAIL=1
    fi
done
say "[event-waist] differential: $SQPASS agree / $SQEXCL excluded / $SQN total"
if [[ $SQPASS -lt 15 ]]; then say "[event-waist] RED: fewer than 15 square agreements (anti-vacuity floor)"; FAIL=1; fi

say "[event-waist] == [5] teeth on REAL module bytes =="
TEETH_SRC="$SQ_DIR/sq06_loops.iii"
TW="$W/w_sq06_loops"
if [[ -x "$TW/route_v$BIN_SUFFIX" ]]; then
    timeout 120 "$TW/route_v$BIN_SUFFIX" --tamper >/dev/null 2>&1
    rc=$?
    if [[ $rc -eq 193 ]]; then say "TOOTH tamper-on-real-module refused 193"; else say "RED tamper tooth: rc=$rc (wanted 193)"; FAIL=1; fi
    timeout 120 "$TW/route_v$BIN_SUFFIX" --stats > "$W/_stats1.txt" 2>&1
    timeout 120 "$TW/route_v$BIN_SUFFIX" --stats > "$W/_stats2.txt" 2>&1
    if cmp -s "$W/_stats1.txt" "$W/_stats2.txt"; then
        say "TOOTH determinism: two --stats runs byte-identical ($(tr -d '\r\n' < "$W/_stats1.txt" | grep -o 'EVN=[0-9]* WIT=[0-9a-f]*' | head -1))"
    else
        say "RED determinism: --stats runs differ"; FAIL=1
    fi
else
    say "RED teeth stage: no route_v for sq06_loops"; FAIL=1
fi

say "[event-waist] == [6] THE STANDING TOOL: iii-events (route V on arbitrary user programs) =="
TOOL="$W/iii$BIN_SUFFIX"
if bash "$BOOT/build_iii.sh" --out "$TOOL" >"$W/_tool_build.log" 2>&1 && [[ -x "$TOOL" ]]; then
    # a FRESH program authored by this gate run -- the expectation comes from the NATIVE route,
    # never from a constant: two meaning-bearers, one gate-authored input.
    cat > "$W/gate_probe.iii" << 'IIIEOF'
module gate_probe
fn tri(n: u64) -> u64 {
    let mut s : u64 = 0u64
    let mut i : u64 = 1u64
    while i <= n { s = s + i  i = i + 1u64 }
    return s
}
fn main() -> i32 {
    if tri(12u64) != 78u64 { return 1i32 }
    if tri(0u64) != 0u64 { return 2i32 }
    return ((tri(11u64) % 100u64) as i32)
}
IIIEOF
    "$IIIS" "$W/gate_probe.iii" --compile-only --out "$W/gate_probe.o" >/dev/null 2>&1 \
        && gcc "$W/gate_probe.o" -o "$W/gate_probe$BIN_SUFFIX" >/dev/null 2>&1
    "$W/gate_probe$BIN_SUFFIX" >/dev/null 2>&1
    RCN=$?
    "$TOOL" events --quiet "$W/gate_probe.iii" >/dev/null 2>&1
    RCT=$?
    if [[ "$RCN" == "$RCT" ]]; then say "TOOL parity gate-authored probe: native=$RCN tool=$RCT"; else say "RED tool parity: native=$RCN tool=$RCT"; FAIL=1; fi
    TPN=0; TPOK=0
    for tsrc in sq01_arith sq05_recur sq15_crt; do
        TPN=$((TPN+1))
        NEXE="$W/w_$tsrc/route_s$BIN_SUFFIX"
        [[ -x "$NEXE" ]] || { say "RED tool parity $tsrc: no route_s"; FAIL=1; continue; }
        timeout 120 "$NEXE" > "$W/_tp_s.txt" 2>&1
        RS=$?
        timeout 120 "$TOOL" events --quiet "$SQ_DIR/$tsrc.iii" > "$W/_tp_v.txt" 2>&1
        RV=$?
        if [[ "$RS" == "$RV" ]] && cmp -s "$W/_tp_s.txt" "$W/_tp_v.txt"; then
            say "TOOL parity $tsrc rc=$RS (output bytes equal)"; TPOK=$((TPOK+1))
        else
            say "RED tool parity $tsrc: S=$RS V=$RV cmp=$(cmp -s "$W/_tp_s.txt" "$W/_tp_v.txt" && echo same || echo DIFF)"; FAIL=1
        fi
    done
    timeout 120 "$TOOL" events --tamper "$W/gate_probe.iii" >/dev/null 2>&1
    rc=$?
    if [[ $rc -eq 193 ]]; then say "TOOL tamper tooth 193"; else say "RED tool tamper: rc=$rc"; FAIL=1; fi
    timeout 120 "$TOOL" events "$W/gate_probe.iii" > "$W/_tv1.txt" 2>&1
    timeout 120 "$TOOL" events "$W/gate_probe.iii" > "$W/_tv2.txt" 2>&1
    if cmp -s "$W/_tv1.txt" "$W/_tv2.txt"; then say "TOOL determinism: verdict lines byte-identical"; else say "RED tool determinism"; FAIL=1; fi
    # THE CRYPTOGRAPHIC EXECUTION CERTIFICATE (composes omnia::exec_cert -- real sha256): reproducible
    # (same program => same receipt) AND sensitive (a different program => a different receipt).
    C1="$(timeout 120 "$TOOL" events --cert --quiet "$W/gate_probe.iii" 2>/dev/null | grep -o 'sha256=[0-9a-f]*')"
    C1B="$(timeout 120 "$TOOL" events --cert --quiet "$W/gate_probe.iii" 2>/dev/null | grep -o 'sha256=[0-9a-f]*')"
    cat > "$W/cert_variant.iii" << 'IIIEOF'
module cert_variant
fn main() -> i32 { let mut s : u64 = 0u64  let mut i : u64 = 1u64  while i <= 12u64 { s = s + (i + 1u64)  i = i + 1u64 }  return (s % 100u64) as i32 }
IIIEOF
    C2="$(timeout 120 "$TOOL" events --cert --quiet "$W/cert_variant.iii" 2>/dev/null | grep -o 'sha256=[0-9a-f]*')"
    if [[ -n "$C1" && "$C1" == "$C1B" ]]; then say "CERT determinism: $C1"; else say "RED cert determinism: $C1 vs $C1B"; FAIL=1; fi
    if [[ -n "$C2" && "$C1" != "$C2" ]]; then say "CERT sensitivity: distinct programs -> distinct receipts"; else say "RED cert sensitivity: $C1 == $C2"; FAIL=1; fi
    # THE EXECUTION-DIVERGENCE LOCATOR (--diff): trace-identical self == exit 0; a trace-divergent
    # variant == exit 1 with a locus; determinism (same pair, identical output).  Stronger than
    # result-equality: it compares the whole retirement stream, event for event.
    cat > "$W/diff_variant.iii" << 'IIIEOF'
module diff_variant
fn tri(n: u64) -> u64 { let mut s : u64 = 0u64  let mut i : u64 = 1u64  while i <= n { s = s + i  i = i + 1u64 }  return s }
fn main() -> i32 { if tri(12u64) != 78u64 { return 1i32 }  if tri(0u64) != 0u64 { return 2i32 }  return ((tri(13u64) % 100u64) as i32) }
IIIEOF
    timeout 120 "$TOOL" events --diff "$W/gate_probe.iii" "$W/gate_probe.iii" > "$W/_diff_self.txt" 2>&1; DSELF=$?
    timeout 120 "$TOOL" events --diff "$W/gate_probe.iii" "$W/diff_variant.iii" > "$W/_diff_var.txt" 2>&1; DVAR=$?
    timeout 120 "$TOOL" events --diff "$W/gate_probe.iii" "$W/gate_probe.iii" > "$W/_diff_self2.txt" 2>&1
    if [[ $DSELF -eq 0 ]] && grep -q "identical" "$W/_diff_self.txt"; then say "DIFF self-identical (exit 0): $(cat "$W/_diff_self.txt")"; else say "RED diff self: exit=$DSELF"; FAIL=1; fi
    if [[ $DVAR -eq 1 ]] && grep -q "diverge at event" "$W/_diff_var.txt"; then say "DIFF locates a real divergence (exit 1): $(cat "$W/_diff_var.txt")"; else say "RED diff variant: exit=$DVAR"; FAIL=1; fi
    if cmp -s "$W/_diff_self.txt" "$W/_diff_self2.txt"; then say "DIFF determinism: identical output on re-run"; else say "RED diff determinism"; FAIL=1; fi
else
    say "RED tool build failed (see _tool_build.log)"; FAIL=1
fi

if [[ $KATN -eq 0 || $SQN -eq 0 ]]; then echo "[event-waist] FATAL: an arm ran EMPTY"; exit 2; fi
if [[ $FAIL -ne 0 ]]; then echo "[event-waist] RED"; exit 1; fi
echo "[event-waist] GREEN: 3 organ-law gates (99) + differential $SQPASS/$SQN route-S==route-V (rc+stdout) + real-module teeth + iii-events tool arms"
exit 0
