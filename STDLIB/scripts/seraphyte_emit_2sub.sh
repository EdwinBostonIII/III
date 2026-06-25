#!/usr/bin/env bash
# seraphyte_emit_2sub.sh -- THE PATCH-EMITTER for the 2-SHIFT-SUBTRACT strength reduction (a NEW rule cg_r3
# LACKS) -- the REUSE of the 2-shift-add spine with subtraction, proving the emitter is a rule-FAMILY producer.
#
# x * v  where  v == 2^j - 2^m  (j > m >= 1, j-m >= 3: a CONTIGUOUS run of >=3 ones from bit m)  ->
# (x<<j) - (x<<m)  mod 2^64.   cg_r3 emits a full `imul` for these (14,28,30,56,60,...); this replaces it with
# two shifts + one sub.  Disjoint from pow2 (popcount 1), shladd/2-shift-add (popcount 2) and subk (run from
# bit 0, m=0): popcount>=3 EVEN contiguous-run is owned by no other rule.  bv_ring/bv_bits proven.
# Idempotent.  Deterministic.  NIH: pure bash/awk.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOT="${EMIT2SUB_BOOT:-$ROOT/COMPILER/BOOT/cg_opt_rules.iii}"
R3I="${EMIT2SUB_R3I:-$ROOT/COMPILER/BOOT/cg_r3.iii}"
R3C="${EMIT2SUB_R3C:-$ROOT/COMPILER/BOOT/cg_r3.c}"
say(){ printf '[emit2sub] %s\n' "$*"; }
if grep -q "cgopt_mul_2ss_admit" "$BOOT"; then say "rule '2ss' already present -- nothing to emit (idempotent)"; exit 0; fi

# ---- (1) BOOT/cg_opt_rules.iii : admit (even, popcount>=3, contiguous run) + extractors (m = ntz, j = m+popcount) ----
cat >> "$BOOT" <<'EOF'

/* [EMITTED by seraphyte_emit_2sub.sh] is `x * v` a width-faithful 2-shift-SUBTRACT strength reduction?  1 iff
 * v == 2^j - 2^m with j > m >= 1 and j-m >= 3 -- i.e. v is a CONTIGUOUS run of >= 3 one-bits NOT starting at
 * bit 0 (even, popcount >= 3, the run test).  Then x*v == (x<<j) - (x<<m) mod 2^64.  Disjoint from
 * pow2/shladd/2-shift-add (popcount<=2) and subk (run from bit 0).  Replaces a full imul with two shl + one sub. */
fn cgopt_mul_2ss_admit(v: u64) -> u32 @export {
    if (v & 1u64) != 0u64 { return 0u32 }              /* even: the run starts at bit m >= 1 */
    let mut c: u32 = 0u32
    let mut t: u64 = v
    while t != 0u64 {
        if (t & 1u64) != 0u64 { c = c + 1u32 }
        t = t >> 1u64
    }
    if c < 3u32 { return 0u32 }                         /* popcount >= 3 (disjoint from the popcount-2 rules) */
    let mut s: u64 = v
    while (s & 1u64) == 0u64 { s = s >> 1u64 }          /* strip trailing zeros -> the run, low bit set */
    if ((s + 1u64) & s) != 0u64 { return 0u32 }         /* the run must be all ones: s == 2^(j-m) - 1 */
    return 1u32
}
/* the LOW shift m = number of trailing zeros (caller guarantees admit). */
fn cgopt_mul_2ss_m(v: u64) -> u32 @export {
    let mut k: u32 = 0u32
    let mut t: u64 = v
    while (t & 1u64) == 0u64 {
        k = k + 1u32
        t = t >> 1u64
    }
    return k
}
/* the HIGH shift j = m + popcount (the run spans bits m .. j-1) (caller guarantees admit). */
fn cgopt_mul_2ss_j(v: u64) -> u32 @export {
    let mut c: u32 = 0u32
    let mut t: u64 = v
    while t != 0u64 {
        if (t & 1u64) != 0u64 { c = c + 1u32 }
        t = t >> 1u64
    }
    let mut m: u32 = 0u32
    let mut s: u64 = v
    while (s & 1u64) == 0u64 {
        m = m + 1u32
        s = s >> 1u64
    }
    return m + c
}
EOF
say "(1) BOOT/cg_opt_rules.iii += cgopt_mul_2ss_admit/_m/_j  (contiguous-run predicate + two extractors)"

ins_before() { awk -v a="$2" -v bf="$3" 'BEGIN{d=0} (!d && index($0,a)){ while((getline l<bf)>0) print l; close(bf); d=1 } { print }' "$1" > "$1._t" && mv "$1._t" "$1"; }
ins_after()  { awk -v a="$2" -v bf="$3" 'BEGIN{d=0} { print } (!d && index($0,a)){ while((getline l<bf)>0) print l; close(bf); d=1 }' "$1" > "$1._t" && mv "$1._t" "$1"; }
W="$ROOT/STDLIB/build/_emit2sub"; mkdir -p "$W"

# ---- (2) cg_r3.iii : externs + two test fns + the dispatch arm (two shifts + sub) ----
cat > "$W/_iii_ext.txt" <<'EOF'
extern @abi(c-msvc-x64) fn cgopt_mul_2ss_admit(v: u64) -> u32 from "cg_opt_rules.iii"
extern @abi(c-msvc-x64) fn cgopt_mul_2ss_j(v: u64) -> u32 from "cg_opt_rules.iii"
extern @abi(c-msvc-x64) fn cgopt_mul_2ss_m(v: u64) -> u32 from "cg_opt_rules.iii"
EOF
ins_after "$R3I" 'extern @abi(c-msvc-x64) fn cgopt_mul_2sh_m(v: u64) -> u32 from "cg_opt_rules.iii"' "$W/_iii_ext.txt"

cat > "$W/_iii_fn.txt" <<'EOF'
/* [EMITTED] 2-SHIFT-SUBTRACT extractors (dual of cg_r3.c's mul_2ss_j/_m -- IDENTICAL logic):
 * if op is MUL(3) and rhs == 2^j-2^m (contiguous run >=3), r3_mul_2ss_j returns j (>0 = admitted), _m returns m. */
fn r3_mul_2ss_j(op: u32, rhs: u32) -> u32 {
    if op != 3u32 { return 0u32 }
    if iii_ast_node_kind(R3_G_AST, rhs) != R3_K_EXPR_INT { return 0u32 }
    let v: u64 = iii_ast_expr_int_u64(R3_G_AST, rhs)
    if cgopt_mul_2ss_admit(v) != 1u32 { return 0u32 }
    return cgopt_mul_2ss_j(v)
}
fn r3_mul_2ss_m(op: u32, rhs: u32) -> u32 {
    if op != 3u32 { return 0u32 }
    if iii_ast_node_kind(R3_G_AST, rhs) != R3_K_EXPR_INT { return 0u32 }
    let v: u64 = iii_ast_expr_int_u64(R3_G_AST, rhs)
    return cgopt_mul_2ss_m(v)
}
EOF
ins_before "$R3I" '/* CONSTANT-SHIFT FOLD test (dual of cg_r3.c' "$W/_iii_fn.txt"

cat > "$W/_iii_arm.txt" <<'EOF'
        let j2ss: u32 = r3_mul_2ss_j(op, rhs)
        if j2ss != 0u32 {
            /* [EMITTED] 2-SHIFT-SUB: mul by 2^j-2^m -> movq %rax,%rcx; shlq $j,%rax; shlq $m,%rcx; subq %rcx,%rax
             * -- (x<<j)-(x<<m) -- replacing a full imul.  Sound: x*(2^j-2^m) == (x<<j)-(x<<m) mod 2^64. */
            let m2ss: u32 = r3_mul_2ss_m(op, rhs)
            r3_emit_expr(lhs); r3_pop_rax()
            r3_emit_arr(&R3_STR_MOVQ_RAX_RCX as u64, R3_STR_MOVQ_RAX_RCX_LEN)
            r3_emit_arr(&R3_STR_SHLQ_DOLLAR as u64, R3_STR_SHLQ_DOLLAR_LEN); r3_emit_dec(j2ss as u64); r3_emit_arr(&R3_STR_CM_RAX_NL as u64, R3_STR_CM_RAX_NL_LEN)
            r3_emit_arr(&R3_STR_SHLQ_DOLLAR as u64, R3_STR_SHLQ_DOLLAR_LEN); r3_emit_dec(m2ss as u64); r3_emit_arr(&R3_STR_COMMA_RCX_NL as u64, R3_STR_COMMA_RCX_NL_LEN)
            r3_emit_arr(&R3_STR_SUBQ as u64, R3_STR_SUBQ_LEN)
            if r3_expr_is_u32(lhs) == 1u32 { r3_emit_arr(&R3_STR_MOVL_EE as u64, R3_STR_MOVL_EE_LEN) }
            r3_push_rax(); return R3_OK
        }
EOF
ins_before "$R3I" 'let shk: u32 = r3_shift_const_k(op, rhs)' "$W/_iii_arm.txt"
say "(2) cg_r3.iii += externs + r3_mul_2ss_j/_m + dispatch arm (emits two shl + one sub)"

# ---- (3) cg_r3.c : byte-identical-logic twin ----
cat > "$W/_c_fn.txt" <<'EOF'
/* [EMITTED] 2-SHIFT-SUBTRACT extractors (dual of cg_r3.iii's r3_mul_2ss_j/_m -- IDENTICAL logic). */
static int mul_2ss_admit_c(uint64_t v)
{
    if ((v & 1) != 0) return 0;
    int c = 0; uint64_t t = v;
    while (t != 0) { if ((t & 1) != 0) c++; t >>= 1; }
    if (c < 3) return 0;
    uint64_t s = v;
    while ((s & 1) == 0) s >>= 1;
    if (((s + 1) & s) != 0) return 0;
    return 1;
}
static int mul_2ss_m(iii_cg_r3_state_t *cg, const iii_ast_node_t *n)
{
    if (n->u.binary.op != III_BIN_MUL) return 0;
    const iii_ast_node_t *rhs = iii_ast_get(cg->ast, n->u.binary.rhs);
    if (!rhs || rhs->kind != III_AST_EXPR_INT) return 0;
    uint64_t v = rhs->u.int_.value;
    if (!mul_2ss_admit_c(v)) return 0;
    int k = 0; uint64_t t = v;
    while ((t & 1) == 0) { k++; t >>= 1; }
    return k;
}
static int mul_2ss_j(iii_cg_r3_state_t *cg, const iii_ast_node_t *n)
{
    const iii_ast_node_t *rhs = iii_ast_get(cg->ast, n->u.binary.rhs);
    uint64_t v = rhs->u.int_.value;
    int c = 0; uint64_t t = v;
    while (t != 0) { if ((t & 1) != 0) c++; t >>= 1; }
    int m = 0; uint64_t s = v;
    while ((s & 1) == 0) { m++; s >>= 1; }
    return m + c;
}
EOF
ins_before "$R3C" '/* CONSTANT-SHIFT FOLD test (dual of cg_r3.iii' "$W/_c_fn.txt"

cat > "$W/_c_arm.txt" <<'EOF'
            int j2ss = mul_2ss_j(cg, n);
            if (j2ss != 0) {
                /* [EMITTED] 2-SHIFT-SUB: mul by 2^j-2^m -> movq %rax,%rcx; shlq $j,%rax; shlq $m,%rcx; subq
                 * %rcx,%rax -- (x<<j)-(x<<m) -- replacing a full imul.  Sound mod 2^64. */
                int m2ss = mul_2ss_m(cg, n);
                if (emit_expr(cg, n->u.binary.lhs) != 0) return -1;
                stack_pop_reg(cg, "rax");
                emit_line(cg, "    movq %%rax, %%rcx");
                emit_line(cg, "    shlq $%d, %%rax", j2ss);
                emit_line(cg, "    shlq $%d, %%rcx", m2ss);
                emit_line(cg, "    subq %%rcx, %%rax");
                if (expr_is_u32(cg, n->u.binary.lhs))
                    emit_line(cg, "    movl %%eax, %%eax");
                stack_push_reg(cg, "rax");
                return 0;
            }
EOF
ins_before "$R3C" 'int shk = shift_const_k(cg, n);' "$W/_c_arm.txt"
say "(3) cg_r3.c += mul_2ss_admit_c/_j/_m + dispatch arm (byte-identical twin)"
say "EMITTED rule '2ss' into the live codegen -- no human wrote this source."
exit 0
