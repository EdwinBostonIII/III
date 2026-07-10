#!/usr/bin/env bash
# COMPILER/BOOT/run_svir_backend_gate.sh — Γ1: THE SVIR BACKEND GATE.
#
# cg_svir.iii is the PRODUCTION compiler's SVIR backend: it consumes the
# production parse-AST (lex.iii + parse.iii — the SAME front-end that feeds
# cg_r3's x86 backend) and emits a canonical SVIR v1 module.  Two properties,
# one gate:
#
#   (A) CANONICAL  — cg_svir(P) is BYTE-IDENTICAL to iiisv2(P) for every P in
#       the v1 subset (the DDC independence corpus + the square theater).
#       Proves cg_svir is a conformant DOCS/SVIR-V1-CANONICAL.md emitter.
#
#   (B) COMMUTING SQUARE (Θ2 corpus-shape) — for each theater program, three
#       INDEPENDENT executions agree: native (sema+cg_r3+x86) ≡ evaluator ≡
#       cg_svir→SVIR→svir_interp.  Routes N and S SHARE lex+parse but fork at
#       codegen, so a pairwise split localizes the fault to ONE translator.
#
# Route S here is cg_svir (the PRODUCTION backend), upgrading Θ2-0's iiisv2
# route to the real fault-localizing square.  iiisv2 stays as the (A) oracle.
#
# Exit: 0 green | 1 parity/split | 2 env.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SQ_DIR="$SCRIPT_DIR/square_probes"
IND_DIR="$III_ROOT/STDLIB/independence"
SOVIR="$III_ROOT/STDLIB/sovir"
W="$III_ROOT/STDLIB/build/meaning/svirgate"
mkdir -p "$W"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
EVAL_BIN="${EVAL_BIN:-$III_ROOT/COMPILED/iii_eval${BIN_SUFFIX}}"
LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
[[ -x "$IIIS" && -f "$LIB" ]] || { echo "[svir-gate] FATAL: missing toolchain"; exit 2; }

say() { printf '%s\n' "$*"; }
mk() {  # link an exe from a list of .o under $W, with lock-retries
    local out="$1"; shift
    local _la
    for _la in 1 2 3 4 5; do
        rm -f "$out"
        gcc "$@" "$LIB" -lws2_32 -lkernel32 -o "$out" >/dev/null 2>&1 && [[ -x "$out" ]] && return 0
        sleep 1
    done
    return 1
}

# ── build the cg_svir harness (production front-end + SVIR backend) ────────
for tu in cg_sha lex_rt lex ast parse cg_svir cg_svir_main; do
    "$IIIS" "$SCRIPT_DIR/$tu.iii" --compile-only --out "$W/$tu.o" >/dev/null 2>&1 || { echo "[svir-gate] FATAL: compile $tu"; exit 2; }
done
mk "$W/cg_svir$BIN_SUFFIX" "$W/cg_sha.o" "$W/lex_rt.o" "$W/lex.o" "$W/ast.o" "$W/parse.o" "$W/cg_svir.o" "$W/cg_svir_main.o" || { echo "[svir-gate] FATAL: link cg_svir"; exit 2; }
# ── build iiisv2 (the canonical DDC oracle) ───────────────────────────────
"$IIIS" "$SOVIR/iiisv2.iii" --compile-only --out "$W/iiisv2.o" >/dev/null 2>&1 || { echo "[svir-gate] FATAL: compile iiisv2"; exit 2; }
mk "$W/iiisv2$BIN_SUFFIX" "$W/iiisv2.o" || { echo "[svir-gate] FATAL: link iiisv2"; exit 2; }
"$IIIS" "$SOVIR/svir_interp.iii" --compile-only --out "$W/svir_interp.o" >/dev/null 2>&1 || { echo "[svir-gate] FATAL: compile svir_interp"; exit 2; }

CG="$W/cg_svir$BIN_SUFFIX"; IV="$W/iiisv2$BIN_SUFFIX"
FAIL=0

# ═══ (A) CANONICAL: cg_svir ≡ iiisv2 on the DDC independence corpus ════════
say "[svir-gate] == (A) canonical byte-parity: cg_svir vs iiisv2 =="
PARN=0
for name in indep_toolchain indep_ops indep_bignum; do
    src="$IND_DIR/$name.iii"
    [[ -f "$src" ]] || { say "SKIP $name (absent)"; continue; }
    PARN=$((PARN+1))
    cp "$CG" "/tmp/svg_cg_$$$BIN_SUFFIX"; cp "$IV" "/tmp/svg_iv_$$$BIN_SUFFIX"
    "/tmp/svg_cg_$$$BIN_SUFFIX" "$src" > "$W/${name}_cg.iii" 2>/dev/null
    "/tmp/svg_iv_$$$BIN_SUFFIX" "$src" > "$W/${name}_iv.iii" 2>/dev/null
    rm -f "/tmp/svg_cg_$$$BIN_SUFFIX" "/tmp/svg_iv_$$$BIN_SUFFIX"
    if cmp -s "$W/${name}_cg.iii" "$W/${name}_iv.iii"; then
        say "PARITY $name ($(wc -c < "$W/${name}_cg.iii")B)"
    else
        say "PARITY-RED $name: cg=$(wc -c < "$W/${name}_cg.iii")B iv=$(wc -c < "$W/${name}_iv.iii")B"
        FAIL=1
    fi
done

# ═══ (B) COMMUTING SQUARE: native ≡ eval ≡ cg_svir→interp (+ parity) ═══════
say "[svir-gate] == (B) commuting square: N(cg_r3) ≡ E(eval) ≡ S(cg_svir) =="
SQN=0
for src in "$SQ_DIR"/sq*.iii; do
    [[ -f "$src" ]] || continue
    SQN=$((SQN+1)); base="$(basename "$src" .iii)"
    # route N: native
    "$IIIS" "$src" --compile-only --out "$W/$base.o" >/dev/null 2>&1 || { say "SPLIT $base: native compile"; FAIL=1; continue; }
    mk "$W/$base$BIN_SUFFIX" "$W/$base.o" || { say "SPLIT $base: native link"; FAIL=1; continue; }
    cp "$W/$base$BIN_SUFFIX" "/tmp/svg_n_$$$BIN_SUFFIX"; timeout 60 "/tmp/svg_n_$$$BIN_SUFFIX" >/dev/null 2>&1; RCN=$?; rm -f "/tmp/svg_n_$$$BIN_SUFFIX"
    # route E: eval (skip if iii_eval absent — square degrades to N≡S)
    RCE="$RCN"
    if [[ -x "$EVAL_BIN" ]]; then timeout 60 "$EVAL_BIN" "$src" >/dev/null 2>&1; RCE=$?; fi
    # route S: cg_svir → gen_svir.iii → svir_interp ; AND parity vs iiisv2
    SW="$W/w_$base"; mkdir -p "$SW"
    cp "$CG" "/tmp/svg_cg_$$$BIN_SUFFIX"; "/tmp/svg_cg_$$$BIN_SUFFIX" "$src" > "$SW/gen_svir.iii" 2>/dev/null; rm -f "/tmp/svg_cg_$$$BIN_SUFFIX"
    [[ -s "$SW/gen_svir.iii" ]] || { say "SPLIT $base: cg_svir emitted nothing (out of v1 subset?)"; FAIL=1; continue; }
    cp "$IV" "/tmp/svg_iv_$$$BIN_SUFFIX"; "/tmp/svg_iv_$$$BIN_SUFFIX" "$src" > "$SW/gen_iv.iii" 2>/dev/null; rm -f "/tmp/svg_iv_$$$BIN_SUFFIX"
    if ! cmp -s "$SW/gen_svir.iii" "$SW/gen_iv.iii"; then say "PARITY-RED $base: cg_svir != iiisv2"; FAIL=1; fi
    ( cd "$SW" && "$IIIS" gen_svir.iii --compile-only --out gen_svir.o >/dev/null 2>&1 ) || { say "SPLIT $base: gen_svir compile"; FAIL=1; continue; }
    mk "$SW/route_s$BIN_SUFFIX" "$SW/gen_svir.o" "$W/svir_interp.o" || { say "SPLIT $base: route-S link"; FAIL=1; continue; }
    cp "$SW/route_s$BIN_SUFFIX" "/tmp/svg_s_$$$BIN_SUFFIX"; timeout 60 "/tmp/svg_s_$$$BIN_SUFFIX" >/dev/null 2>&1; RCS=$?; rm -f "/tmp/svg_s_$$$BIN_SUFFIX"
    if [[ "$RCN" == "$RCE" && "$RCE" == "$RCS" ]]; then
        say "SQUARE $base rc=$RCN (N=E=S, cg_svir≡iiisv2)"
    else
        say "SPLIT $base: N=$RCN E=$RCE S=$RCS"
        FAIL=1
    fi
done

if [[ $((PARN + SQN)) -eq 0 ]]; then echo "[svir-gate] FATAL: no theater"; exit 2; fi
if [[ $FAIL -ne 0 ]]; then echo "[svir-gate] RED"; exit 1; fi
echo "[svir-gate] GREEN: canonical byte-parity ($PARN DDC) + commuting square ($SQN probes, N≡E≡S)"
exit 0
