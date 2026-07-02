#!/usr/bin/env bash
# seraphyte_emit_rule.sh -- THE ONE PATCH-EMITTER: a non-human artifact that GENERATES a strength-reduction
# rule's source text from a DESCRIPTOR and inserts it into the live codegen.  This is the organ that makes
# "the compiler rewrites itself" literally true: the driver runs THIS (not a human Edit) to write the rule.
#
# UNIFIED by the reunification (III-REUNIFICATION-PLAN W2.3): the three family rules were three sibling
# scripts (this one = subk; seraphyte_emit_2shift.sh; seraphyte_emit_2sub.sh) sharing one spine -- and the
# old subk-only schema had a LATENT TRAP: called with any other NAME it would emit a 2^k-1-shaped rule under
# that name.  Now the FIRST argument selects the descriptor, and each descriptor carries its own shape:
#
#   subk   v == 2^k - 1  (k in 3..63; odd, floor 7)      ->  (x<<k) - x        one extractor, shl + subq
#   2sh    v == 2^j + 2^m (j > m >= 1; popcount 2, EVEN)  ->  (x<<j) + (x<<m)   two extractors, 2 shl + addq
#   2sub   v == 2^j - 2^m (j-m >= 3; contiguous run, EVEN)->  (x<<j) - (x<<m)   two extractors, 2 shl + subq
#
# Each shape is dispatch-disjoint (odd 2^k-1 / popcount-2 even / contiguous-run even), bv_ring/bv_bits proven.
# subk keeps its extended descriptor knobs (FLOOR / IIIOP / COP / sound|unsound) because the reseal driver's
# rollback-teeth arm injects the over-admitting variant.  Idempotent per rule.  Deterministic.  NIH: pure
# bash/awk.  No human writes the rule -- the descriptor does, through this emitter.
#
# Usage:  seraphyte_emit_rule.sh [subk [FLOOR IIIOP COP sound|unsound] | 2sh | 2shift | 2sub]
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOT="$ROOT/COMPILER/BOOT/cg_opt_rules.iii"
R3I="$ROOT/COMPILER/BOOT/cg_r3.iii"
R3C="$ROOT/COMPILER/BOOT/cg_r3.c"
W="$ROOT/STDLIB/build/_emit"; mkdir -p "$W"
say(){ printf '[emit] %s\n' "$*"; }

RULE="${1:-subk}"
[ "$RULE" = "2shift" ] && RULE="2sh"

# awk insert helpers (insert a block file's lines BEFORE/AFTER the first line containing the anchor substring)
ins_before() { awk -v a="$2" -v bf="$3" 'BEGIN{d=0} (!d && index($0,a)){ while((getline l<bf)>0) print l; close(bf); d=1 } { print }' "$1" > "$1._t" && mv "$1._t" "$1"; }
ins_after()  { awk -v a="$2" -v bf="$3" 'BEGIN{d=0} { print } (!d && index($0,a)){ while((getline l<bf)>0) print l; close(bf); d=1 }' "$1" > "$1._t" && mv "$1._t" "$1"; }

# ============================================================================================
# DESCRIPTOR subk : v == 2^k-1  ->  (x<<k) - x        (extended knobs for the reseal teeth)
# ============================================================================================
emit_subk() {
    local NAME="subk"
    local FLOOR="${2:-7}"
    local IIIOP="${3:-R3_STR_SUBQ}"
    local COP="${4:-subq}"
    local SHAPE_OK="${5:-sound}"
    if grep -q "cgopt_mul_${NAME}_admit" "$BOOT"; then say "rule '${NAME}' already present -- nothing to emit (idempotent)"; exit 0; fi

    local SHAPE_GUARD
    if [ "$SHAPE_OK" = "sound" ]; then
        SHAPE_GUARD='    let p: u64 = v + 1u64                       /* v < 2^63, so v+1 does not overflow */
    if (p & v) != 0u64 { return 0u32 }          /* v+1 must be an exact power of two: v == 2^k - 1 */'
    else
        SHAPE_GUARD='    let p: u64 = v + 1u64                       /* (unsound: shape guard DROPPED) */'
    fi

    cat >> "$BOOT" <<EOF

/* [EMITTED by seraphyte_emit_rule.sh from descriptor NAME=${NAME} FLOOR=${FLOOR} SHAPE=2^k-1 OP=${COP}]
 * is \`x * v\` a width-faithful shl-sub strength reduction?  1 iff v == 2^k-1 for k in 3..63 (v >= ${FLOOR}
 * and v+1 an exact power of two).  Then x*v == ${NAME}: (x<<k) - x mod 2^64.  v=3 (=2^2-1) is excluded
 * (floor ${FLOOR}): 3 is also 2^1+1 (shladd's by dispatch).  Replaces an imul with one shl + one ${COP}. */
fn cgopt_mul_${NAME}_admit(v: u64) -> u32 @export {
    if v < ${FLOOR}u64 { return 0u32 }
    if (v >> 63u64) != 0u64 { return 0u32 }   /* v >= 2^63: outside k<=63; also guards the v+1 overflow */
${SHAPE_GUARD}
    return 1u32
}
fn cgopt_mul_${NAME}_k(v: u64) -> u32 @export {
    let mut k: u32 = 0u32
    let mut t: u64 = v + 1u64
    while t > 1u64 { t = t >> 1u64; k = k + 1u32 }
    return k
}
EOF
    say "(1) BOOT/cg_opt_rules.iii  += cgopt_mul_${NAME}_admit/_k  (descriptor-generated rule predicate)"

    cat > "$W/_iii_ext.txt" <<EOF
extern @abi(c-msvc-x64) fn cgopt_mul_${NAME}_admit(v: u64) -> u32 from "cg_opt_rules.iii"
extern @abi(c-msvc-x64) fn cgopt_mul_${NAME}_k(v: u64) -> u32 from "cg_opt_rules.iii"
EOF
    ins_after "$R3I" 'extern @abi(c-msvc-x64) fn cgopt_mul_shladd_k(v: u64) -> u32 from "cg_opt_rules.iii"' "$W/_iii_ext.txt"

    cat > "$W/_iii_fn.txt" <<EOF
/* [EMITTED] SHIFT-AND-${COP^^} STRENGTH REDUCTION test (dual of cg_r3.c's mul_${NAME}_k -- IDENTICAL logic):
 * if op is MUL(3) and rhs == 2^k-1 (k in 3..63), return k via the single-source law cgopt_mul_${NAME}_*. */
fn r3_mul_${NAME}_k(op: u32, rhs: u32) -> u32 {
    if op != 3u32 { return 0u32 }
    if iii_ast_node_kind(R3_G_AST, rhs) != R3_K_EXPR_INT { return 0u32 }
    let v: u64 = iii_ast_expr_int_u64(R3_G_AST, rhs)
    if cgopt_mul_${NAME}_admit(v) != 1u32 { return 0u32 }
    return cgopt_mul_${NAME}_k(v)
}
EOF
    ins_before "$R3I" '/* CONSTANT-SHIFT FOLD test (dual of cg_r3.c' "$W/_iii_fn.txt"

    cat > "$W/_iii_arm.txt" <<EOF
        let s${NAME}: u32 = r3_mul_${NAME}_k(op, rhs)
        if s${NAME} != 0u32 {
            /* [EMITTED] SHIFT-AND-${COP^^}: mul by 2^k-1 -> movq %rax,%rcx; shlq \$k,%rax; ${COP} %rcx,%rax --
             * (x<<k)-x -- replacing a full imul.  Sound: x*(2^k-1) == (x<<k)-x mod 2^64.  Twin-verified prims. */
            r3_emit_expr(lhs); r3_pop_rax()
            r3_emit_arr(&R3_STR_MOVQ_RAX_RCX as u64, R3_STR_MOVQ_RAX_RCX_LEN)
            r3_emit_arr(&R3_STR_SHLQ_DOLLAR as u64, R3_STR_SHLQ_DOLLAR_LEN); r3_emit_dec(s${NAME} as u64); r3_emit_arr(&R3_STR_CM_RAX_NL as u64, R3_STR_CM_RAX_NL_LEN)
            r3_emit_arr(&${IIIOP} as u64, ${IIIOP}_LEN)
            if r3_expr_is_u32(lhs) == 1u32 { r3_emit_arr(&R3_STR_MOVL_EE as u64, R3_STR_MOVL_EE_LEN) }
            r3_push_rax(); return R3_OK
        }
EOF
    ins_before "$R3I" 'let shk: u32 = r3_shift_const_k(op, rhs)' "$W/_iii_arm.txt"
    say "(2) cg_r3.iii  += externs + r3_mul_${NAME}_k + dispatch arm (emits shl + ${COP})"

    cat > "$W/_c_fn.txt" <<EOF
/* [EMITTED] SHIFT-AND-${COP^^} STRENGTH REDUCTION test (dual of cg_r3.iii's r3_mul_${NAME}_k -- IDENTICAL
 * logic so the emitted assembly is byte-for-byte the same): rhs == 2^k-1 (k in 3..63) -> k, else 0. */
static int mul_${NAME}_k(iii_cg_r3_state_t *cg, const iii_ast_node_t *n)
{
    if (n->u.binary.op != III_BIN_MUL) return 0;
    const iii_ast_node_t *rhs = iii_ast_get(cg->ast, n->u.binary.rhs);
    if (!rhs || rhs->kind != III_AST_EXPR_INT) return 0;
    uint64_t v = rhs->u.int_.value;
    if (v < ${FLOOR}) return 0;
    if ((v >> 63) != 0) return 0;
    uint64_t p = v + 1;
    if ((p & v) != 0) return 0;
    int k = 0; uint64_t t = v + 1;
    while (t > 1) { t >>= 1; k++; }
    return k;
}
EOF
    ins_before "$R3C" '/* CONSTANT-SHIFT FOLD test (dual of cg_r3.iii' "$W/_c_fn.txt"

    cat > "$W/_c_arm.txt" <<EOF
            int s${NAME} = mul_${NAME}_k(cg, n);
            if (s${NAME} != 0) {
                /* [EMITTED] SHIFT-AND-${COP^^}: mul by 2^k-1 -> movq %rax,%rcx; shlq \$%d, %%rax; ${COP} %rcx,%rax
                 * -- (x<<k)-x -- replacing a full imul.  Sound: x*(2^k-1) == (x<<k)-x mod 2^64. */
                if (emit_expr(cg, n->u.binary.lhs) != 0) return -1;
                stack_pop_reg(cg, "rax");
                emit_line(cg, "    movq %%rax, %%rcx");
                emit_line(cg, "    shlq \$%d, %%rax", s${NAME});
                emit_line(cg, "    ${COP} %%rcx, %%rax");
                if (expr_is_u32(cg, n->u.binary.lhs))
                    emit_line(cg, "    movl %%eax, %%eax");
                stack_push_reg(cg, "rax");
                return 0;
            }
EOF
    ins_before "$R3C" 'int shk = shift_const_k(cg, n);' "$W/_c_arm.txt"
    say "(3) cg_r3.c    += mul_${NAME}_k + dispatch arm (byte-identical twin)"
    say "EMITTED rule '${NAME}' into the live codegen from descriptor -- no human wrote this source."
}

# ============================================================================================
# DESCRIPTOR 2sh : v == 2^j + 2^m (j>m>=1, popcount 2, EVEN)  ->  (x<<j) + (x<<m)
# ============================================================================================
emit_2sh() {
    if grep -q "cgopt_mul_2sh_admit" "$BOOT"; then say "rule '2sh' already present -- nothing to emit (idempotent)"; exit 0; fi

    cat >> "$BOOT" <<'EOF'

/* [EMITTED by seraphyte_emit_rule.sh, descriptor 2sh] is `x * v` a width-faithful TWO-SHIFT strength
 * reduction?  1 iff v == 2^j + 2^m with j > m >= 1 (popcount 2 and EVEN -- disjoint from pow2/shladd/subk).
 * Then x*v == (x<<j) + (x<<m) mod 2^64.  Replaces a full imul with two shifts + one add. */
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
}

# ============================================================================================
# DESCRIPTOR 2ss : v == 2^j - 2^m (j > m >= 1, j-m >= 3: contiguous run of >= 3 ones) -> (x<<j) - (x<<m)
# (verbatim port of seraphyte_emit_2sub.sh -- the LANDED rule family is named 2ss; the emission below
#  reproduces the original's generated source exactly so the idempotence guard matches reality.)
# ============================================================================================
emit_2ss() {
    if grep -q "cgopt_mul_2ss_admit" "$BOOT"; then say "rule '2ss' already present -- nothing to emit (idempotent)"; exit 0; fi

    cat >> "$BOOT" <<'EOF'

/* [EMITTED by seraphyte_emit_rule.sh, descriptor 2ss] is `x * v` a width-faithful 2-shift-SUBTRACT strength
 * reduction?  1 iff v == 2^j - 2^m with j > m >= 1 and j-m >= 3 -- i.e. v is a CONTIGUOUS run of >= 3 one-bits
 * NOT starting at bit 0 (even, popcount >= 3, the run test).  Then x*v == (x<<j) - (x<<m) mod 2^64.  Disjoint
 * from pow2/shladd/2-shift-add (popcount<=2) and subk (run from bit 0).  Replaces a full imul with two shl + one sub. */
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
}

case "$RULE" in
    subk) emit_subk "$@" ;;
    2sh)  emit_2sh ;;
    2ss|2sub) emit_2ss ;;
    *) say "unknown rule descriptor '$RULE' (known: subk, 2sh|2shift, 2ss|2sub)"; exit 2 ;;
esac
exit 0
