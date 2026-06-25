#!/usr/bin/env bash
# seraphyte_emit_rule.sh -- THE PATCH-EMITTER: a non-human artifact that GENERATES a strength-reduction
# rule's source text from a DESCRIPTOR and inserts it into the live codegen.  This is the organ that makes
# "the compiler rewrites itself" literally true: the driver runs THIS (not a human Edit) to write the rule.
#
# A strength-reduction rule of the shl+OP family is fully determined by a small descriptor:
#     NAME    -- the rule id (subk)
#     SHAPE   -- the admitted factor shape (v == 2^k - 1)  -> the admit predicate body
#     FLOOR   -- the smallest owned factor (7) -- below it the factor belongs to a sibling rule by dispatch
#     IIIOP   -- the cg_r3.iii emit string constant for the second op (R3_STR_SUBQ)
#     COP     -- the cg_r3.c emit mnemonic for the second op (subq)
#     IDENT   -- the proven identity, for the generated comments  ((x<<k)-x)
# Given the descriptor, the emitter instantiates the SAME schema the shl+add rule already uses (recombination
# within the existing Logos, not ex nihilo) and writes FIVE source edits across the three codegen files:
#   (1) BOOT/cg_opt_rules.iii  : the rule-table predicate pair  cgopt_mul_${NAME}_admit / _k
#   (2) cg_r3.iii              : the externs, the test fn r3_mul_${NAME}_k, and the dispatch emit arm
#   (3) cg_r3.c                : the byte-identical-logic twin (test fn + dispatch arm)
# Idempotent (skips if the rule is already present).  Deterministic.  NIH: pure bash/awk.  No human writes
# the rule -- the descriptor does, through this emitter.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOT="$ROOT/COMPILER/BOOT/cg_opt_rules.iii"
R3I="$ROOT/COMPILER/BOOT/cg_r3.iii"
R3C="$ROOT/COMPILER/BOOT/cg_r3.c"
W="$ROOT/STDLIB/build/_emit"; mkdir -p "$W"

# ---- THE DESCRIPTOR (this is the only rule-specific input; everything below is schema instantiation) ----
NAME="${1:-subk}"
FLOOR="${2:-7}"
IIIOP="${3:-R3_STR_SUBQ}"
COP="${4:-subq}"
# shape predicate fragments for v == 2^k - 1 (the descriptor's SHAPE).  An over-admit (drop the shape check)
# is what the driver injects to test the gate's teeth; here we emit the SOUND shape.
SHAPE_OK="${5:-sound}"   # 'sound' = full 2^k-1 check; 'unsound' = drop the shape guard (for rollback teeth)

say(){ printf '[emit] %s\n' "$*"; }
if grep -q "cgopt_mul_${NAME}_admit" "$BOOT"; then say "rule '${NAME}' already present -- nothing to emit (idempotent)"; exit 0; fi

# the shape guard line is emitted only in 'sound' mode; 'unsound' drops it (an over-admitting bad dream)
if [ "$SHAPE_OK" = "sound" ]; then
  SHAPE_GUARD='    let p: u64 = v + 1u64                       /* v < 2^63, so v+1 does not overflow */
    if (p & v) != 0u64 { return 0u32 }          /* v+1 must be an exact power of two: v == 2^k - 1 */'
else
  SHAPE_GUARD='    let p: u64 = v + 1u64                       /* (unsound: shape guard DROPPED) */'
fi

# ---- (1) BOOT rule-table predicate pair: appended (module functions are order-independent) ----
cat >> "$BOOT" <<EOF

/* [EMITTED by seraphyte_emit_rule.sh from descriptor NAME=${NAME} FLOOR=${FLOOR} SHAPE=2^k-1 OP=${COP}]
 * is \`x * v\` a width-faithful shl-${COp:-sub} strength reduction?  1 iff v == 2^k-1 for k in 3..63 (v >= ${FLOOR}
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

# awk insert helpers (insert a block file's lines BEFORE the first line containing the anchor substring)
ins_before() { awk -v a="$2" -v bf="$3" 'BEGIN{d=0} (!d && index($0,a)){ while((getline l<bf)>0) print l; close(bf); d=1 } { print }' "$1" > "$1._t" && mv "$1._t" "$1"; }
ins_after()  { awk -v a="$2" -v bf="$3" 'BEGIN{d=0} { print } (!d && index($0,a)){ while((getline l<bf)>0) print l; close(bf); d=1 }' "$1" > "$1._t" && mv "$1._t" "$1"; }

# ---- (2) cg_r3.iii : externs, test fn, dispatch arm ----
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

# ---- (3) cg_r3.c : byte-identical-logic twin ----
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
                /* [EMITTED] SHIFT-AND-${COP^^}: mul by 2^k-1 -> movq %rax,%rcx; shlq \$k,%rax; ${COP} %rcx,%rax
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
exit 0
