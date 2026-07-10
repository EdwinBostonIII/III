#!/usr/bin/env bash
# COMPILER/BOOT/run_svir_backend_gate.sh — Γ1: THE SVIR BACKEND GATE (rung 2).
#
# cg_svir.iii is the PRODUCTION compiler's SVIR backend: production parse-AST
# in, SVIR v1 module out — WIDTH-FAITHFUL per SVIR-V1-CANONICAL §W (the
# definitional evaluator's law at compile time).  Three arms, one gate:
#
#   (A1) LIVE PARITY — cg_svir(P) BYTE-IDENTICAL to iiisv2(P) for the
#        WIDTH-FREE probes (i64/untyped scalars, u8 arrays).  On this
#        fragment §W degenerates to iiisv2's exact bytes; iiisv2 stays the
#        living canonicity witness where it can see.
#   (A2) GOLDEN RATCHET — mhash of cg_svir(P) for the TYPED theater (DDC
#        independence set + width probes) pinned in svir_backend_goldens.txt.
#        iiisv2 drops width by design, so canonical bytes for typed programs
#        are §W's — any drift is loud and needs an intentional reseal.
#   (B)  COMMUTING SQUARE — native(sema+cg_r3+x86) ≡ eval ≡ cg_svir→interp
#        per probe, INCLUDING the width theater (sq07/sq08).
#
# Exit: 0 green | 1 parity/golden/split | 2 env.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SQ_DIR="$SCRIPT_DIR/square_probes"
IND_DIR="$III_ROOT/STDLIB/independence"
SOVIR="$III_ROOT/STDLIB/sovir"
W="$III_ROOT/STDLIB/build/meaning/svirgate"
GOLD="$SCRIPT_DIR/svir_backend_goldens.txt"
mkdir -p "$W"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
EVAL_BIN="${EVAL_BIN:-$III_ROOT/COMPILED/iii_eval${BIN_SUFFIX}}"
LIB="$III_ROOT/STDLIB/build/iii/libiii_native.a"
[[ -x "$IIIS" && -f "$LIB" ]] || { echo "[svir-gate] FATAL: missing toolchain"; exit 2; }
# route E is a REQUIRED leg of the square: a missing evaluator must not
# silently degrade arm B to N≡S (RCE defaulted to RCN below) — FATAL instead.
[[ -x "$EVAL_BIN" ]] || { echo "[svir-gate] FATAL: no iii_eval at $EVAL_BIN — the square needs all three routes"; exit 2; }

say() { printf '%s\n' "$*"; }
mk() {
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
"$IIIS" "$SOVIR/iiisv2.iii" --compile-only --out "$W/iiisv2.o" >/dev/null 2>&1 || { echo "[svir-gate] FATAL: compile iiisv2"; exit 2; }
mk "$W/iiisv2$BIN_SUFFIX" "$W/iiisv2.o" || { echo "[svir-gate] FATAL: link iiisv2"; exit 2; }
"$IIIS" "$SOVIR/svir_interp.iii" --compile-only --out "$W/svir_interp.o" >/dev/null 2>&1 || { echo "[svir-gate] FATAL: compile svir_interp"; exit 2; }

CG="$W/cg_svir$BIN_SUFFIX"; IV="$W/iiisv2$BIN_SUFFIX"
FAIL=0

# width-free set: the rung-1 probes (i64/untyped only). sq07/sq08 are TYPED.
# NOTE: bash arrays, not space-joined strings — IFS here is newline+tab, so
# an unquoted string would NOT word-split (measured: both arms ran EMPTY).
WIDTH_FREE=(sq01_arith sq02_mem sq03_line sq04_ops sq05_recur sq06_loops)

# ═══ (A1) LIVE PARITY: cg_svir ≡ iiisv2 on the width-free fragment ═════════
say "[svir-gate] == (A1) live byte-parity (width-free fragment) =="
PARN=0
for name in "${WIDTH_FREE[@]}"; do
    src="$SQ_DIR/$name.iii"
    [[ -f "$src" ]] || continue
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

# ═══ (A2) GOLDEN RATCHET: canonical bytes of the TYPED theater ═════════════
say "[svir-gate] == (A2) golden mhash (typed canonical bytes, §W) =="
GOLDN=0; GOLD_MISS=0
declare -A GOLD_PIN
if [[ -f "$GOLD" ]]; then
    # IFS is newline+tab globally -- `read` would NOT split on the space
    # between name and hash (gname swallowed whole lines; every pin lookup
    # missed and the arm verified NOTHING while reporting GOLDEN-NEW inside
    # a GREEN gate -- the third IFS bite of this campaign).  Split locally.
    while IFS=' ' read -r gname ghash; do
        [[ -n "$gname" && "${gname:0:1}" != "#" ]] && GOLD_PIN["$gname"]="$ghash"
    done < "$GOLD"
    NPINLINES=$(grep -cEv '^\s*(#|$)' "$GOLD" || true)
    if [[ ${NPINLINES:-0} -gt 0 && ${#GOLD_PIN[@]} -eq 0 ]]; then
        echo "[svir-gate] FATAL: golden file has $NPINLINES pin lines but loader parsed 0 -- silence is not green"
        exit 2
    fi
fi
A2_LIST=("indep_toolchain:$IND_DIR" "indep_ops:$IND_DIR" "indep_bignum:$IND_DIR" "sq07_width:$SQ_DIR" "sq08_mixed:$SQ_DIR" "sq09_mixsign:$SQ_DIR" "sq10_renorm:$SQ_DIR")
: > "$W/goldens_measured.txt"
for entry in "${A2_LIST[@]}"; do
    name="${entry%%:*}"; dir="${entry##*:}"
    src="$dir/$name.iii"
    [[ -f "$src" ]] || { say "SKIP $name (absent)"; continue; }
    GOLDN=$((GOLDN+1))
    cp "$CG" "/tmp/svg_cg_$$$BIN_SUFFIX"
    "/tmp/svg_cg_$$$BIN_SUFFIX" "$src" > "$W/${name}_cg.iii" 2>/dev/null
    rm -f "/tmp/svg_cg_$$$BIN_SUFFIX"
    [[ -s "$W/${name}_cg.iii" ]] || { say "GOLDEN-RED $name: emitted nothing"; FAIL=1; continue; }
    h="$(sha256sum "$W/${name}_cg.iii" | cut -d' ' -f1)"
    printf '%s %s\n' "$name" "$h" >> "$W/goldens_measured.txt"
    pin="${GOLD_PIN[$name]:-}"
    if [[ -z "$pin" ]]; then
        say "GOLDEN-NEW $name $h (unpinned -- add to svir_backend_goldens.txt)"
        GOLD_MISS=$((GOLD_MISS+1))
    elif [[ "$pin" == "$h" ]]; then
        say "GOLDEN $name ok"
    else
        say "GOLDEN-RED $name: pinned=$pin measured=$h (intentional? reseal svir_backend_goldens.txt)"
        FAIL=1
    fi
done
if [[ $GOLD_MISS -gt 0 ]]; then
    if [[ -f "$GOLD" ]]; then
        # a measured name with no pin while the golden file EXISTS is pin-rot,
        # not a bootstrap state -- loud red (pin from goldens_measured.txt).
        say "[svir-gate] GOLDEN-MISS RED: $GOLD_MISS measured name(s) unpinned in existing $GOLD"
        FAIL=1
    else
        say "[svir-gate] no golden file yet -- measured pins in $W/goldens_measured.txt"
    fi
fi

# ═══ (B) COMMUTING SQUARE: native ≡ eval ≡ cg_svir→interp (ALL probes) ═════
say "[svir-gate] == (B) commuting square: N(cg_r3) ≡ E(eval) ≡ S(cg_svir) =="
SQN=0
for src in "$SQ_DIR"/sq*.iii; do
    [[ -f "$src" ]] || continue
    SQN=$((SQN+1)); base="$(basename "$src" .iii)"
    "$IIIS" "$src" --compile-only --out "$W/$base.o" >/dev/null 2>&1 || { say "SPLIT $base: native compile"; FAIL=1; continue; }
    mk "$W/$base$BIN_SUFFIX" "$W/$base.o" || { say "SPLIT $base: native link"; FAIL=1; continue; }
    cp "$W/$base$BIN_SUFFIX" "/tmp/svg_n_$$$BIN_SUFFIX"; timeout 60 "/tmp/svg_n_$$$BIN_SUFFIX" >/dev/null 2>&1; RCN=$?; rm -f "/tmp/svg_n_$$$BIN_SUFFIX"
    RCE="$RCN"
    if [[ -x "$EVAL_BIN" ]]; then timeout 60 "$EVAL_BIN" "$src" >/dev/null 2>&1; RCE=$?; fi
    SW="$W/w_$base"; mkdir -p "$SW"
    cp "$CG" "/tmp/svg_cg_$$$BIN_SUFFIX"; "/tmp/svg_cg_$$$BIN_SUFFIX" "$src" > "$SW/gen_svir.iii" 2>/dev/null; rm -f "/tmp/svg_cg_$$$BIN_SUFFIX"
    [[ -s "$SW/gen_svir.iii" ]] || { say "SPLIT $base: cg_svir refused (width probe on an old backend?)"; FAIL=1; continue; }
    ( cd "$SW" && "$IIIS" gen_svir.iii --compile-only --out gen_svir.o >/dev/null 2>&1 ) || { say "SPLIT $base: gen_svir compile"; FAIL=1; continue; }
    mk "$SW/route_s$BIN_SUFFIX" "$SW/gen_svir.o" "$W/svir_interp.o" || { say "SPLIT $base: route-S link"; FAIL=1; continue; }
    cp "$SW/route_s$BIN_SUFFIX" "/tmp/svg_s_$$$BIN_SUFFIX"; timeout 60 "/tmp/svg_s_$$$BIN_SUFFIX" >/dev/null 2>&1; RCS=$?; rm -f "/tmp/svg_s_$$$BIN_SUFFIX"
    if [[ "$RCN" == "$RCE" && "$RCE" == "$RCS" ]]; then
        say "SQUARE $base rc=$RCN (N=E=S)"
    else
        say "SPLIT $base: N=$RCN E=$RCE S=$RCS"
        FAIL=1
    fi
done

if [[ $PARN -eq 0 || $GOLDN -eq 0 || $SQN -eq 0 ]]; then echo "[svir-gate] FATAL: an arm ran EMPTY (A1=$PARN A2=$GOLDN B=$SQN) -- silence is not green"; exit 2; fi
if [[ $FAIL -ne 0 ]]; then echo "[svir-gate] RED"; exit 1; fi
echo "[svir-gate] GREEN: A1 parity ($PARN width-free) + A2 goldens ($GOLDN typed) + square ($SQN probes, N≡E≡S)"
exit 0
