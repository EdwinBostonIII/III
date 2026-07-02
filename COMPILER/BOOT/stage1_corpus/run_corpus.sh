#!/usr/bin/env bash
# Stage-1 verification corpus runner.
# For each NN_*.iii: compile via iiis-0, link, run, report exit code.
# Expected exit codes are encoded in a parallel table below.
set -u
IFS=$'\n\t'
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IIIS0="C:/Users/Edwin Boston/OneDrive/Desktop/III/COMPILED/iiis-0.exe"

declare -A EXPECTED=(
    [01_return_const]=7
    [02_arithmetic]=8
    [03_let_local]=32
    [04_call_other]=42
    [05_param]=42
    [06_bitwise]=250        # 0xFA
    [07_compare]=1
    [08_match]=42
    [09_unary]=0            # ~(all-ones u64) = 0; byte-range exit (see 09_unary.iii)
    [10_extern]=0
    [11_assign]=42
    [12_const_decl]=42
    [13_for_loop]=10        # 0+1+2+3+4
    [14_modifier_cycle]=42
    [15_string_literal]=71  # 0x4847 low byte
    [16_if_else]=42
    [17_while]=55           # 1+2+3+4+5+6+7+8+9+10
    [18_else_if]=2
    [19_cast]=255           # 0x1FF & 0xFF
    [20_sizeof]=4
    [21_pointer]=42
    [22_array_via_ptr]=99
    [28_extern_msvc]=0
    [27_string_index]=67     # 'C' = 67
    [24_var_global]=42
    [26_fnptr]=42
    [25_array_init]=5
    [23_struct_decl]=0       # parses + registers struct; full instance codegen Stage-2
    [29_struct_instance]=42  # F8.5 — struct field read/write
    [30_byte_index]=42       # F-A1/F-A2 — heap byte read/write via *u8
    # FROZEN SPEC III-RES-FROZEN-001 — 24 resolution corpus tests
    [31_sat_arith]=1
    [32_intent_seal]=1
    [33_unify_basic]=1
    [34_unify_occurs]=0      # cycle detected → fail = pass
    [35_unify_arity]=0       # arity mismatch → fail = pass
    [36_unify_depth]=1       # bounded walk succeeds (no occurs cycle)
    [37_pattern_register_after_seal]=0  # post-seal register refused
    [38_score_table]=1
    [39_resolve_simple]=1
    [40_resolve_tiebreak]=1
    [41_resolve_ambiguous]=1  # 0xE101 low byte = 0x01
    [42_resolve_nomatch]=2    # post Intent Calculus v1.0 (R2-GENESIS Phase A.1): PRIMITIVE_FORM meta-pattern wins; ctx kid=0 has no kchain; K-composition Step 6 returns E_RESOLVE_K_UNDERFLOW (0xE102), low byte = 0x02
    [43_resolve_no_recompute_observable]=1
    [44_metapattern_set]=16
    [45_replay_witness]=1
    [46_q7_gate_pos]=1
    [47_q7_gate_neg]=0
    [48_m22_audit]=1
    [49_proof_ripple_pattern]=1
    [50_sid_inverse]=1
    [51_resolve_syntax]=42
    [52_call_via_resolver]=42
    [53_resolve_no_self_recursion]=1
    [54_transform_iii_to_asm]=1
    [55_intent_form_runtime]=1
    [56_transform_form_runtime]=1
    [57_pattern_form_runtime]=1
    [58_udiv_highbit]=58
)

PASS=0; FAIL=0; SKIP=0
RESULTS=()

for src in "$HERE"/[0-9][0-9]_*.iii; do
    base="$(basename "$src" .iii)"
    out="$HERE/${base}.exe"
    log="$HERE/${base}.log"
    rm -f "$out" "$out.s" "$out.o" "$out.witness.json" "$log"

    # Try emit-asm-only first (always-on smoke).
    "$IIIS0" --ring R3 --emit-asm-only --out "$out" "$src" >"$log" 2>&1
    asm_rc=$?

    if [[ $asm_rc -ne 0 ]]; then
        RESULTS+=("FAIL  $base : iiis-0 exit=$asm_rc (see $log)")
        FAIL=$((FAIL + 1))
        continue
    fi

    # Try full pipeline (assemble + link).
    "$IIIS0" --ring R3 --out "$out" "$src" >>"$log" 2>&1
    full_rc=$?
    if [[ $full_rc -ne 0 ]]; then
        # Stdlib-dependent tests (FROZEN SPEC III-RES-FROZEN-001 corpus 31..54)
        # need libiii_native.a on the link line. Retry with stdlib in scope.
        STDLIB_AR="$HERE/../../../STDLIB/build/iii/libiii_native.a"
        if [[ -f "$STDLIB_AR" ]]; then
            obj="${out}.o"
            "$IIIS0" --ring R3 --compile-only --out "$obj" "$src" >>"$log" 2>&1
            comp_rc=$?
            if [[ $comp_rc -eq 0 ]]; then
                gcc -o "$out" "$obj" "$STDLIB_AR" -lws2_32 -lkernel32 -lmsvcrt 2>>"$log"
                relink_rc=$?
                if [[ $relink_rc -eq 0 ]] && [[ -x "$out" ]]; then
                    full_rc=0
                fi
            fi
        fi
        if [[ $full_rc -ne 0 ]]; then
            RESULTS+=("ASM-ONLY $base : asm OK; assemble/link exit=$full_rc")
            SKIP=$((SKIP + 1))
            continue
        fi
    fi

    if [[ ! -x "$out" ]]; then
        RESULTS+=("FAIL  $base : no output binary")
        FAIL=$((FAIL + 1))
        continue
    fi

    # Run.
    "$out" >>"$log" 2>&1
    actual_rc=$?
    expected_rc="${EXPECTED[$base]:-?}"
    if [[ "$actual_rc" == "$expected_rc" ]]; then
        RESULTS+=("PASS  $base : exit=$actual_rc")
        PASS=$((PASS + 1))
    else
        RESULTS+=("WRONG $base : exit=$actual_rc expected=$expected_rc")
        FAIL=$((FAIL + 1))
    fi
done

echo "=========================================================="
echo " Stage-1 Verification Corpus Results"
echo "=========================================================="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "----------------------------------------------------------"
echo "  PASS=$PASS  FAIL=$FAIL  ASM-ONLY=$SKIP  TOTAL=$((PASS+FAIL+SKIP))"
echo "=========================================================="
# SOUNDNESS (whole-tree sweep 2026-07-02): this script previously ENDED at the echo above, so its
# process exit was always 0 -- a FAIL=1 tally (e.g. the unregistered 58_udiv_highbit) sailed through
# run_all_corpora's rc check and the capstone stayed green on a red.  A red must redden the sweep.
[[ "$FAIL" == 0 ]] && exit 0 || exit 1
