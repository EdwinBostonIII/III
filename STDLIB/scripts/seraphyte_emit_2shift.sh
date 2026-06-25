#!/usr/bin/env bash
# seraphyte_emit_2shift.sh -- THE PATCH-EMITTER for the 2-SHIFT strength reduction (a NEW rule cg_r3 LACKS).
#
# x * v  where  v == 2^j + 2^m  (j > m >= 1, popcount 2, EVEN)  ->  (x<<j) + (x<<m)  mod 2^64.
# cg_r3 currently emits a full `imul` for these factors (6,10,12,20,...); this rule replaces it with two
# shifts + one add.  Disjoint from pow2 (popcount 1), shladd (2^k+1, odd) and subk (2^k-1, odd): popcount-2
# EVEN is owned by no other rule, so dispatch cannot misfire.  The identity is bv_ring/bv_bits proven.
#
# A non-human artifact GENERATES the rule's source from the (implicit) descriptor {shape: 2^j+2^m even,
# op: add, second-shift target: %rcx}, mirroring seraphyte_emit_rule.sh -- the descriptor carries TWO shift
# amounts (j,m) and the arm has TWO extractors, the genuinely-different shape the subk emitter could not make.
# Idempotent.  Deterministic.  NIH: pure bash/awk.  No human writes the rule.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOT="${EMIT2SH_BOOT:-$ROOT/COMPILER/BOOT/cg_opt_rules.iii}"
R3I="${EMIT2SH_R3I:-$ROOT/COMPILER/BOOT/cg_r3.iii}"
R3C="${EMIT2SH_R3C:-$ROOT/COMPILER/BOOT/cg_r3.c}"
say(){ printf '[emit2sh] %s\n' "$*"; }
if grep -q "cgopt_mul_2sh_admit" "$BOOT"; then say "rule '2sh' already present -- nothing to emit (idempotent)"; exit 0; fi

# ---- (1) BOOT/cg_opt_rules.iii : the admit predicate + the two shift extractors (j = high bit, m = low bit) ----
cat >> "$BOOT" <<'EOF'

/* [EMITTED by seraphyte_emit_2shift.sh] is `x * v` a width-faithful TWO-SHIFT strength reduction?  1 iff
 * v == 2^j + 2^m with j > m >= 1 (popcount 2 and EVEN -- disjoint from pow2/shladd/subk).  Then
 * x*v == (x<<j) + (x<<m) mod 2^64.  Replaces a full imul with two shifts + one add. */
fn cgopt_mul_2sh_admit(v: u64) -> u32 @export {
    if (v & 1u64) != 0u64 { return 0u32 }              /* must be EVEN (low bit m >= 1) */
    let mut c: u32 = 0u32
    let mut t: u64 = v
    while t != 0u64 {
        if (t & 1u64) != 0u64 { c = c + 1u32 }
        t = t >> 1u64
    }
    if c != 2u32 { return 0u32 }                       /* exactly two set bits */
    return 1u32
}
/* the HIGH set-bit position j (caller guarantees cgopt_mul_2sh_admit(v)==1). */
fn cgopt_mul_2sh_j(v: u64) -> u32 @export {
    let mut k: u32 = 0u32
    let mut hi: u32 = 0u32
    let mut t: u64 = v
    while t != 0u64 {
        if (t & 1u64) != 0u64 { hi = k }
        k = k + 1u32
        t = t >> 1u64
    }
    return hi
}
/* the LOW set-bit position m (caller guarantees cgopt_mul_2sh_admit(v)==1). */
fn cgopt_mul_2sh_m(v: u64) -> u32 @export {
    let mut k: u32 = 0u32
    let mut t: u64 = v
    while (t & 1u64) == 0u64 {
        k = k + 1u32
        t = t >> 1u64
    }
    return k
}
EOF
say "(1) BOOT/cg_opt_rules.iii += cgopt_mul_2sh_admit/_j/_m  (popcount-2 even predicate + two extractors)"

# awk insert helper: insert block file's lines BEFORE the first line containing the anchor substring.
ins_before() { awk -v a="$2" -v bf="$3" 'BEGIN{d=0} (!d && index($0,a)){ while((getline l<bf)>0) print l; close(bf); d=1 } { print }' "$1" > "$1._t" && mv "$1._t" "$1"; }
ins_after()  { awk -v a="$2" -v bf="$3" 'BEGIN{d=0} { print } (!d && index($0,a)){ while((getline l<bf)>0) print l; close(bf); d=1 }' "$1" > "$1._t" && mv "$1._t" "$1"; }
W="$ROOT/STDLIB/build/_emit2sh"; mkdir -p "$W"

# ---- (2) cg_r3.iii : externs + two test fns + the dispatch arm (two shifts + add) ----
cat > "$W/_iii_ext.txt" <<'EOF'
extern @abi(c-msvc-x64) fn cgopt_mul_2sh_admit(v: u64) -> u32 from "cg_opt_rules.iii"
extern @abi(c-msvc-x64) fn cgopt_mul_2sh_j(v: u64) -> u32 from "cg_opt_rules.iii"
extern @abi(c-msvc-x64) fn cgopt_mul_2sh_m(v: u64) -> u32 from "cg_opt_rules.iii"
EOF
ins_after "$R3I" 'extern @abi(c-msvc-x64) fn cgopt_mul_subk_k(v: u64) -> u32 from "cg_opt_rules.iii"' "$W/_iii_ext.txt"

cat > "$W/_iii_fn.txt" <<'EOF'
/* [EMITTED] TWO-SHIFT STRENGTH REDUCTION extractors (dual of cg_r3.c's mul_2sh_j/_m -- IDENTICAL logic):
 * if op is MUL(3) and rhs == 2^j+2^m (j>m>=1), r3_mul_2sh_j returns j (>0 = admitted), r3_mul_2sh_m returns m. */
fn r3_mul_2sh_j(op: u32, rhs: u32) -> u32 {
    if op != 3u32 { return 0u32 }
    if iii_ast_node_kind(R3_G_AST, rhs) != R3_K_EXPR_INT { return 0u32 }
    let v: u64 = iii_ast_expr_int_u64(R3_G_AST, rhs)
    if cgopt_mul_2sh_admit(v) != 1u32 { return 0u32 }
    return cgopt_mul_2sh_j(v)
}
fn r3_mul_2sh_m(op: u32, rhs: u32) -> u32 {
    if op != 3u32 { return 0u32 }
    if iii_ast_node_kind(R3_G_AST, rhs) != R3_K_EXPR_INT { return 0u32 }
    let v: u64 = iii_ast_expr_int_u64(R3_G_AST, rhs)
    return cgopt_mul_2sh_m(v)
}
EOF
ins_before "$R3I" '/* CONSTANT-SHIFT FOLD test (dual of cg_r3.c' "$W/_iii_fn.txt"

cat > "$W/_iii_arm.txt" <<'EOF'
        let j2sh: u32 = r3_mul_2sh_j(op, rhs)
        if j2sh != 0u32 {
            /* [EMITTED] TWO-SHIFT: mul by 2^j+2^m -> movq %rax,%rcx; shlq $j,%rax; shlq $m,%rcx; addq %rcx,%rax
             * -- (x<<j)+(x<<m) -- replacing a full imul.  Sound: x*(2^j+2^m) == (x<<j)+(x<<m) mod 2^64. */
            let m2sh: u32 = r3_mul_2sh_m(op, rhs)
            r3_emit_expr(lhs); r3_pop_rax()
            r3_emit_arr(&R3_STR_MOVQ_RAX_RCX as u64, R3_STR_MOVQ_RAX_RCX_LEN)
            r3_emit_arr(&R3_STR_SHLQ_DOLLAR as u64, R3_STR_SHLQ_DOLLAR_LEN); r3_emit_dec(j2sh as u64); r3_emit_arr(&R3_STR_CM_RAX_NL as u64, R3_STR_CM_RAX_NL_LEN)
            r3_emit_arr(&R3_STR_SHLQ_DOLLAR as u64, R3_STR_SHLQ_DOLLAR_LEN); r3_emit_dec(m2sh as u64); r3_emit_arr(&R3_STR_COMMA_RCX_NL as u64, R3_STR_COMMA_RCX_NL_LEN)
            r3_emit_arr(&R3_STR_ADDQ as u64, R3_STR_ADDQ_LEN)
            if r3_expr_is_u32(lhs) == 1u32 { r3_emit_arr(&R3_STR_MOVL_EE as u64, R3_STR_MOVL_EE_LEN) }
            r3_push_rax(); return R3_OK
        }
EOF
ins_before "$R3I" 'let shk: u32 = r3_shift_const_k(op, rhs)' "$W/_iii_arm.txt"
say "(2) cg_r3.iii += externs + r3_mul_2sh_j/_m + dispatch arm (emits two shl + one add)"

# ---- (3) cg_r3.c : byte-identical-logic twin ----
cat > "$W/_c_fn.txt" <<'EOF'
/* [EMITTED] TWO-SHIFT STRENGTH REDUCTION extractors (dual of cg_r3.iii's r3_mul_2sh_j/_m -- IDENTICAL logic
 * so the emitted assembly is byte-for-byte the same): rhs == 2^j+2^m (j>m>=1) -> j/m, else 0. */
static int mul_2sh_admit_c(uint64_t v)
{
    if ((v & 1) != 0) return 0;
    int c = 0; uint64_t t = v;
    while (t != 0) { if ((t & 1) != 0) c++; t >>= 1; }
    return (c == 2) ? 1 : 0;
}
static int mul_2sh_j(iii_cg_r3_state_t *cg, const iii_ast_node_t *n)
{
    if (n->u.binary.op != III_BIN_MUL) return 0;
    const iii_ast_node_t *rhs = iii_ast_get(cg->ast, n->u.binary.rhs);
    if (!rhs || rhs->kind != III_AST_EXPR_INT) return 0;
    uint64_t v = rhs->u.int_.value;
    if (!mul_2sh_admit_c(v)) return 0;
    int hi = 0, k = 0; uint64_t t = v;
    while (t != 0) { if ((t & 1) != 0) hi = k; k++; t >>= 1; }
    return hi;
}
static int mul_2sh_m(iii_cg_r3_state_t *cg, const iii_ast_node_t *n)
{
    const iii_ast_node_t *rhs = iii_ast_get(cg->ast, n->u.binary.rhs);
    uint64_t v = rhs->u.int_.value;
    int k = 0; uint64_t t = v;
    while ((t & 1) == 0) { k++; t >>= 1; }
    return k;
}
EOF
ins_before "$R3C" '/* CONSTANT-SHIFT FOLD test (dual of cg_r3.iii' "$W/_c_fn.txt"

cat > "$W/_c_arm.txt" <<'EOF'
            int j2sh = mul_2sh_j(cg, n);
            if (j2sh != 0) {
                /* [EMITTED] TWO-SHIFT: mul by 2^j+2^m -> movq %rax,%rcx; shlq $j,%rax; shlq $m,%rcx; addq
                 * %rcx,%rax -- (x<<j)+(x<<m) -- replacing a full imul.  Sound mod 2^64. */
                int m2sh = mul_2sh_m(cg, n);
                if (emit_expr(cg, n->u.binary.lhs) != 0) return -1;
                stack_pop_reg(cg, "rax");
                emit_line(cg, "    movq %%rax, %%rcx");
                emit_line(cg, "    shlq $%d, %%rax", j2sh);
                emit_line(cg, "    shlq $%d, %%rcx", m2sh);
                emit_line(cg, "    addq %%rcx, %%rax");
                if (expr_is_u32(cg, n->u.binary.lhs))
                    emit_line(cg, "    movl %%eax, %%eax");
                stack_push_reg(cg, "rax");
                return 0;
            }
EOF
ins_before "$R3C" 'int shk = shift_const_k(cg, n);' "$W/_c_arm.txt"
say "(3) cg_r3.c += mul_2sh_admit_c/_j/_m + dispatch arm (byte-identical twin)"
say "EMITTED rule '2sh' into the live codegen -- no human wrote this source."
exit 0
