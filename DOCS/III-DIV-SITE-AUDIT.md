# III — Division-Site Soundness Audit (Phase 0, Task 0.3)

**Question.** Does cg_r3's `x / 2^k → x >> k` strength reduction ever fire on a **signed**
operand, where it would be *unsound* (signed division rounds toward zero, so
`(-1) / 2 == 0` but `(-1) >> 1 == -1`)?

## The gate (correct by construction)

The reduction is emitted only behind an explicit unsigned gate, in both twins:

- `COMPILER/BOOT/cg_r3.iii:2609-2619` — `let dpk = r3_div_pow2_k(op, rhs); if dpk != 0 { if r3_either_is_signed(lhs, rhs) == 0 { …emit shr… } }`
- `COMPILER/BOOT/cg_r3.c:1573-1585` — `int dpk = div_pow2_k(cg, n); if (dpk) { if (!expr_is_signed(lhs) && !expr_is_signed(rhs)) { …emit shr… } }`

A signed operand makes `r3_either_is_signed == 1`, so the `shr` branch is **structurally
unreachable** for signed division — it falls through to the general division path, which
(after Phase 0's fix) emits `cqto; idivq` for signed and `xorl %edx,%edx; divq` for unsigned.
So the reduction is sound **by construction**.

## Empirical sweep (the retrospective's "unverified signed sites")

Grep of `STDLIB/iii` for a signed-typed (`i8/i16/i32/i64`) value divided by a power-of-2
constant — the only case that could be mis-reduced if the gate ever leaked:

| Site | Finding |
|---|---|
| `eidos/layout.iii:363-364` — `(w / 2u32) as i64`, `(h / 2u32) as i64` | **UNSIGNED** division (`w`,`h` are `u32` — the `2u32` literal type-pins them); the `as i64` is a *post*-division cast. Correctly reducible to `shr`. Not a signed division. |
| (all others) | No signed division by a power-of-2 constant found. Signed divisions in the tree use **runtime** divisors (general `idivq` path, never the strength-reduction path). |

The retrospective specifically flagged "binary search `(hi-lo)/2` over `i64` indices." No such
**signed** `÷2^k` site exists in STDLIB: midpoint/index arithmetic uses unsigned (`u64`/`usize`)
operands (correctly reduced to `shr`) or runtime divisors (not reduced).

## Verdict

**SOUND.** The div→shr reduction is gated unsigned-only by construction in both twins, and the
empirical sweep finds **zero** signed-÷-by-pow2 sites that the gate would need to block — it is
both correct and vacuously safe. The C8 row of `III-EIDOS-SESSION-RETROSPECTIVE.md` (finale
"unverified signed sites") is resolved: there are none.
