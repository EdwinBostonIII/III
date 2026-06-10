# Trusted-Base Seal (SEPARATE-2 / Structural-Audit W2.4)

The III proof kernel (`numera/typecheck.iii`, the CIC checker — the sole arbiter of meaning)
delegates its **entire trusted computational base** to:

- the **CCL beta-eta reducer** `numera/ccl.iii` (Curien's categorical combinatory logic as a
  directed, confluent, terminating reduction — confluence now a machine-enumerated **theorem**
  via `ccl_critpair_enum`, W2.3), and
- the **TC ⇄ CCL translation**: `tc_to_ccl` (in `typecheck.iii`) + `ccl_to_tc` (in `ccl.iii`).

The de Bruijn thesis — *"everything reduces to this small, bounded kernel"* — is made **honest
and machine-checked** here: the source bytes of that base are content-addressed into one named
root. Any edit to the reducer or the translation MOVES the root, reddening the build until an
explicit reseal acknowledges that the trusted base changed.

```
TRUSTED_BASE_ROOT = f155a7de0d19afddc141c361ade25c53c7c873a77745fec0f41964e68cc63374
```

> **Reseal log:**
> - `4d5bb214…` → `f079dd81…` (2026-06-06, BV64 substitution soundness fix — found by the adversarial
>   audit workflow): the BV64 morphism tags (29–38) are numerically `>= CCL_ATOM` (8) and `>= CCL_TRUE` (9),
>   so they accidentally satisfied two categorical rules meant for the original CLOSED-constant range:
>   `ccl_strengthen`'s `if tag >= CCL_ATOM { return v }` and `ccl_step`'s COMP weakening `if atag >= CCL_ATOM
>   { return a }` BOTH treated a BV **operation** node (e.g. `bvadd(Snd, lit)`, which references the bound
>   variable `#0`) as a weakening-invariant constant — so a BV op under a SUBSTITUTED binder would silently
>   DROP the substitution (a latent unsoundness: a β-redex through a BV operand reduced to the wrong term).
>   FIX: both sites now special-case the BV op tags (30–38) to recurse STRUCTURALLY — `ccl_strengthen`
>   strengthens each operand (failing if it depends on `#0`), and the COMP rule DISTRIBUTES the composition
>   `bvop(A,B) o b -> bvop(A o b, B o b)` (mirroring the existing `PAIR` rules). A `BVLIT` (tag 29) IS a
>   genuine closed value and correctly still weakens. The KAT (`1213`) gained cases 33–36 (a BV op under a
>   β-reduced binder: `(λy. y+5) 3 == 8`, `(λy. y+y) 3 == 6`, `(λy. y<<1) 4 == 8`, and the negative
>   `(λy. y+5) 3 != 9`) — which RED before the fix, GREEN after. The 32-vector KAT, the ~1200-case
>   differential (`1214`), and the 14-rule adversarial audit (all SOUND, terminates + confluent) re-verified.
>   Additive + structural; `BVLIT`/atoms/data-ctors behave byte-identically. (`tc_rigid_head` also gained
>   `TC_BV`/`TC_BVLIT` as rigid heads — outside the sealed `tc_to_ccl`, so it does not affect this root.)
> - `5996d3de…` → `4d5bb214…` (2026-06-06, BV64 machine-int model — the named optimizer horizon): `ccl.iii`
>   gained the **BV64 bitvector morphisms** (kinds 29–38: `CCL_BVLIT` + `BVADD/BVSUB/BVMUL/BVAND/BVOR/BVXOR/BVSHL`
>   + the overflow predicates `BVADDOVF/BVMULOVF`), their constructors, the `ccl_bv_fold` iota (closed-literal
>   NATIVE mod-2^64 evaluation + the Z/2^64 monoid/semiring identity collapses + the single definitional rule
>   `x<<k == x*2^(k&63)`), a `ccl_step` dispatch arm, **mandatory `ccl_struct_eq` cases** (a BVLIT compares its
>   64-bit value, op nodes recurse — without this two distinct literals would hit the equal-tag fallthrough and the
>   kernel would prove FALSE equalities), and `ccl_to_tc` read-back; `tc_to_ccl` (in `typecheck.iii`) gained the
>   matching BV compile cases (the type → atom 2055, ops → the flat CCL primitives). The kernel now VERIFIES 64-bit
>   machine arithmetic BY IOTA — `x<<k == x*2^k (mod 2^64)` for a SYMBOLIC x in ONE step, overflow-checked constant
>   folding, the multi-class collapse — exactly the REACH(h)/LEK move at scale. The trusted surface is only the
>   closed-literal evaluator + textbook ring identities (the full symbolic ring DECISION stays in the UNTRUSTED
>   proposer `numera/bv_ring`, never the kernel). ADDITIVE: new tags + a flat dispatch arm; every pre-existing
>   node's behaviour is byte-identical (BV tags ≥29 never collide with the 1..28 fragment). VERIFIED SOUND
>   post-reseal: `1211_bv_kernel` (the 32-vector BV KAT, incl. soundness negatives) = 99, the full typecheck/ccl
>   KAT suite + proof tower + Sovereign-Optimizer KATs (1113–1211) green, `build_stdlib` FAIL=0, golden compiler
>   (iiis-0..3) UNMOVED (ccl/typecheck are stdlib, not in the bootstrap link closure — confirmed). The protective
>   drift-gate worked as designed: it reddened the build until this acknowledgement.
> - `40209d80…` → `5996d3de…` (2026-06-04, induction keystone): `ccl_eta_contract` no longer
>   eta-contracts `lam x. C x → C` when the head `C` is a data constructor / eliminator (tag ≥
>   `CCL_TRUE`). A bare constructor is not a standalone function in this kernel, so the contracted form
>   failed `tc_check` as a function — concretely `(lam n. succ n) : Nat→Nat` mangled to bare `succ`
>   under `tc_shift_k`, diverging `tc_natrec`'s IH-type shift from the reconstructed step type and
>   blocking ALL nat-induction. Sound + complete-for-well-typed (a bare constructor never legitimately
>   appears standalone; a genuine function constant `CCL_ATOM` still eta-contracts). Unblocks the
>   inductive frontier. Full proof corpus re-verified green.
> - `b6cadb51…` → `d6802ce2…` (2026-05-31, production-readiness audit): `ccl_to_tc` gained a reserved-INVALID
>   node guard — `if c == 0u32 { return tc_var(0u32) }`. `ccl_reduce`/`ccl_mk` return node 0 on `CCL_CAP`
>   overflow (II-CCL-2); without the guard `ccl_to_tc(0)` misread `CCL_TAG[0]` and self-recursed (`CCL_A[0]==0`)
>   to a stack overflow. Behavior for every valid node (`c != 0`) is byte-identical; the guard reuses the
>   module's existing stuck-fallback term. Kernel hardening only — the CCL reducer + confluence theorem
>   (`ccl_critpair_enum`) and `tc_to_ccl` are untouched.
> - `d6802ce2…` → `db6e9818…` (2026-06-03, mig2 keystone): `ccl.iii` gained the `CCL_REACH(h)` morphism
>   (kind 27) + `ccl_reach_c` constructor + an `iii_hexad_reachable` extern. The kernel now VERIFIES M3
>   hexad-reachability BY IOTA — `REACH(h)` reduces to `TRUE`/`FALSE` via `iii_hexad_reachable(h)`, rather
>   than trusting a baked value; `typecheck.iii` consumes `ccl_reach_c`. Also adds the node-0 INVALID guard
>   in `ccl_to_tc` (`if c == 0 { tc_var(0) }`). VERIFIED SOUND post-reseal: the full typecheck/ccl KAT suite
>   (841-882, 856-863, 935-939) + `1049_mig2_keystone` stay green; the change is additive (new tag + guard),
>   leaving every pre-existing node's behavior byte-identical. (This reseal acknowledges a kernel change that
>   landed externally mid-session; the protective drift-gate worked as designed.)

- **Definition:** `sha256( ccl.iii  ++  tc_to_ccl(typecheck.iii) )`.
- **Gate:** `bash COMPILER/BOOT/trusted_base_check.sh --check` (exit 3 on drift). Recompute
  after an intended change with `--print` and update the root above (the reseal).
- **Seal class:** STDLIB / FORGE_CLOSURE-lite — a standalone seal, deliberately NOT folded into
  the Sovereign forge manifest (`DOCS/SOVEREIGN-LEDGER.md`), so it requires no multi-level
  closure recompute.

This discharges SEPARATE-2 ("name + seal the trusted base as one content-addressed unit") and,
together with the COMBINE-12 repoint in `numera/safety_type.iii` (the phantom `numera/kernel.iii`
reference → the real `typecheck.iii` + `ccl.iii`), makes the kernel boundary legible and defended.
