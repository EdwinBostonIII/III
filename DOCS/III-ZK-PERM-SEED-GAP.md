# III zkVM — the grand-product permutation SEED-PIN gap (found + FIXED 2026-06-24)

> **✅ FIXED across all consumers.** An adversarial Workflow (`zk-soundness-audit-2`) found + empirically
> demonstrated a **CRITICAL** soundness hole in the production zkVM's memory-consistency (grand-product
> permutation) argument: it pinned **neither accumulator seed**.

## The gap

The memory-consistency check proves the program-order access multiset equals the sorted-order multiset via a
**grand product**: separate running-product accumulators `P_k` (program) and `S_k` (sorted), with
`P_k[i+1] = P_k[i]·encf(access_i)`, and a boundary check `P_k[last] == S_k[last]`. A sound grand product
**requires the start pin `P_k[0]==S_k[0]==1` (the `Z(1)=1` identity)** in addition to the final equality.

The III verifiers checked **only** `P_k[63]==S_k[63]`. The transition constraints are pure recurrences that fix
`acc[i+1]` from `acc[i]` but never constrain the seed `acc[0]` — a free trace cell. So a malicious prover:
1. commits a **memory-inconsistent (non-permutation)** trace (program multiset ≠ sorted multiset);
2. seeds `S_k[0] = Pi_p_k · inv(Pi_s_k)` (Pi = the honest product), keeping `P_k[0]=1`;
3. then `S_k[63] = S_k[0]·Pi_s_k = Pi_p_k = P_k[63]` for every `k`, so the boundary passes, and every recurrence
   holds, so the transition CP + FRI pass → **a false statement is ACCEPTED**.

This defeated the production ~2⁻⁸⁶ soundness claim ("a non-permutation is REJECTED by the k=4 boundary").

## Reproduce-then-fix

- **Reproduced:** `zk_fused_attack.iii` (verifier copied verbatim, only the prover seed-rigs) → exit 99, 3/3
  deterministic; exit 99 requires (a) genuine non-perm, (b) honest-seed REJECTS, (c) rig transitions hold,
  (d) rig boundary ACCEPTS — isolating the missing `acc[0]` pin as the sole cause.
- **Fixed:** every grand-product boundary check now **pins both seeds to 1** at the (merkle-opened, where
  committed) row-0 leaf, in addition to the final equality. With both seeds = 1, `P_k[63]==S_k[63]` forces
  `Pi_p_k==Pi_s_k` → genuine permutation.
- **Verified:** the same attack with the seed-pinned verifier → exit 53 (rig boundary REJECTS), 3/3; honest
  paths unregressed (`run_ext4_committed.sh` EXIT 0, `run_zk.sh` EXIT 0); permanent regression
  `corpus/2300_zk_fused_perm_seedrig` → 99.

## Consumers fixed

| file | check | fix |
|------|-------|-----|
| `sovir/zk_fused_committed.iii` (PRODUCTION ~2⁻⁸⁶) | `boundary_ok` (open_col) | seed pin at row-0 opened leaf |
| `sovir/zk_fused_prod.iii` (live gate) | `boundaries_ok` (in-memory) | `P_k[0]==S_k[0]==1` |
| `sovir/zk_perm_k3prod.iii` (live gate, k=3) | `boundaries_ok` (in-memory) | `P_k[0]==S_k[0]==1` |
| `sovir/zk_fused_forge63.iii` | `boundary_ok` (open_col) | seed pin at row-0 opened leaf |

Not affected: `zk_ext4_perm` (constraint-only, no boundary), `zk_perm_malicious`, `zk_svir_mem_dynamic`,
`zk_svir_vm_fused` (use `air_add_boundary`, which pins the seed cell to a value).

## Scope correction

This corrects the session's earlier "production sound on 3 axes" claim — that covered the trace LDE + CP-FRI +
query binding (the **transition** soundness, genuinely sound). The **permutation** argument was a **4th axis**
not checked; it is now sound.

## SEPARATE, DISTINCT FINDING — the last-access (row 63) exclusion  **[✅ FIXED 2026-06-24]**

> **FIXED + verified (reproduce-then-fix).** `boundary_ok`/`boundaries_ok` now fold access 63 into the final product
> (`P_k[63]·encf(prog₆₃) == S_k[63]·encf(sort₆₃)`, re-deriving the same FS challenges). `zk_fused_forge63` 42→99
> (last-access forge now REJECTED); committed's `main` gained a (LA) arm so `run_ext4_committed` gates it on the REAL
> boundary_ok (EXIT 0); propagated to `zk_fused_prod` + `zk_perm_k3prod` (live zk gate EXIT 0, honest 99). The
> permutation argument now constrains ALL 64 accesses — seed (row 0) + every interior + the last (row 63).
>
> *(original analysis:)*

The grand-product recurrence runs `while i < 63` (`zk_fused_committed.iii:215`), so `P_k[63] = prod_{i=0..62}` —
**access 63 (the last row, a LOAD) is EXCLUDED from the product** (the i→i+1 recurrence has no successor at row 63).
The sorted-order read-consistency loop (line 223, cyclic `inx=(i+1)&63`) is on the SORTED columns and does NOT link
the forged PROGRAM access 63. So a malicious prover forges `VP[63]` (the last load value) → it is in neither the
product (excluded) nor a transition (no row-64 successor) → **ACCEPTED**. `zk_fused_forge63.iii` DEMONSTRATES this:
its `main` returns **rc=42** ("read-inconsistent trace ACCEPTED: verify==1 AND boundary==1") for `forge==3` (`VP[63]`).
Present in `zk_fused_committed` (production) + `zk_fused_prod` + `zk_perm_k3prod` (all share the `i<63` product).

**FIX RECIPE (the boundary must include the last access):** in `boundary_ok`/`boundaries_ok`, after the seed pin,
check `P_k[63]·encf(prog_63) == S_k[63]·encf(sort_63)` instead of `P_k[63]==S_k[63]` — i.e. open the access-63
columns (program AP/VP/WP = cols 1,2,3 and sorted AS/VS/WS = cols 4,5,6 at row 63), re-derive the perm challenges
(`air_perm_a`/`air_perm_beta` from the committed access roots; they are currently local to `build()`), compute
`encf` (line 119) for both, and fold the last term into the comparison. `zk_fused_forge63` (rc 42→21) is the
reproduce-then-fix gate. Deep (re-derive challenges + 6 opens + encf across 4 files) — the next focused effort,
to be done with the same reproduce-then-fix rigor as the seed pin, not rushed.
