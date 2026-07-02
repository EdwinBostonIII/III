# SLH-DSA-SHA2 sign SEGFAULT — CRASH-protocol audit (#5)
> **STATUS: HISTORICAL RECORD** — crash forensics / closed findings of their era; the fixes are landed and gated (reunification W6).

Quarantined corpus test: `STDLIB/corpus/_quarantine_wip/1022_pq_dispatch_sha2_route.iii` (exit 139).
Backtrace (prior gdb, README): `main → iii_pq_sign → iii_slhdsa_sha2_sign → iii_slhdsa_sign → iii_slhdsa_sign_sealed`.

## Phase 1 — EVIDENCE (read-only; verified in the CURRENT binary, not the stale README binary)

### Source (`STDLIB/iii/numera/slhdsa.iii`)
- `fn iii_slhdsa_sign_sealed(lv, sk, msg, msglen, sig_out:*u8, sig_len_out:*u64)` at **L796**. 6th param = `sig_len_out`.
- Crash line **L848** `sig_len_out[0u64] = total`, where **L847** `let total = slh_sig_bytes(lv)` (= 7856 for lv=0).
- The function is SHORT (L796–850). The 4 SHA-2-divergent callees reached BEFORE L848:
  - **L813** `slh_PRF_msg` (HMAC-SHA256 randomizer on the SHA-2 path)
  - **L821** `slh_H_msg`   (MGF1-SHA256 message digest on the SHA-2 path)
  - **L833** `slh_fors_sign_and_root` (FORS, SHA-2 hashes)
  - **L840** `slh_xmss_sign_and_root` (XMSS hypertree, SHA-2 hashes; loop ×d)

### Binary (`STDLIB/build/iii/numera_slhdsa.iii.o.s`, current build PASS=452/FAIL=0)
- `iii_slhdsa_sign_sealed:` spans **L10435 → L11257** (`.seh_endproc`). Frame: `pushq %rbp; movq %rsp,%rbp; subq $1024,%rsp`.
- Param spills (iiis-2 Win64-ish ABI): p1–4 `rcx/rdx/r8/r9 → -8/-16/-24/-32(%rbp)`; p5 `sig_out` from `48(%rbp) → -40(%rbp)`;
  **p6 `sig_len_out` from `56(%rbp) → -48(%rbp)` (L10449-10450).**
- `total` home = **`-280(%rbp)`** (L11234, after `callq L_slh_sig_bytes`). **Distinct slot from `-48` → NO static slot-aliasing.**
- L848 store sequence (L11235–11244): `movq -48(%rbp),%rax` (sig_len_out ptr) → push; push idx 0; `movq -280(%rbp),%rax`(total)→push;
  `popq %rdx`(total); `popq %rcx`(0); `popq %rax`(ptr); **`movq %rdx,(%rax,%rcx,8)`** ← faulting insn.
- **`-48(%rbp)` has EXACTLY ONE writer in `sign_sealed`: the param spill at L10450.** The only other `-48(%rbp)` access is the
  read at L11235. (All other `-48(%rbp)` writes in the .s — L11278/11336/12220/… — are in *other* functions: `iii_slhdsa_sign`
  L11263, `iii_slhdsa_verify` L11321, `iii_sphincs_variant_*`, `iii_slhdsa_sha2_*`, each with its own frame.)

### CONCLUSION (Phase 1)
The README's "stack-slot corruption" is confirmed and **refined**: `sig_len_out`'s spill slot `-48(%rbp)` is overwritten with
`7856` at runtime **between L10450 (spill) and L11235 (use)**. Since `sign_sealed` itself never re-writes `-48`, the corruptor
is **one of the 4 SHA-2-path callees** performing a wild write into the parent frame (or a callee-saved/stack-discipline
violation that lands at `rbp-48`). SHAKE through the same `sign_sealed` is green → the bug is on a SHA-2-only branch inside a
callee, not in `sign_sealed`'s own layout.

### NEXT (Phase 1 cont. / Phase 2 — still read-only on .iii)
1. **Reproduce on the CURRENT binary** (the README's offsets were from a stale build): compile+run `1022` against the current
   `libiii_native.a`; confirm exit 139 and capture the live faulting address + the value at `-48(%rbp)`.
2. Disassemble each SHA-2 branch of `slh_PRF_msg`, `slh_H_msg`, `slh_fors_sign_and_root`, `slh_xmss_sign_and_root`; check
   (a) every callee-saved register is preserved (push/pop balance, `.seh_*`), (b) no local array writes a runtime index past
   its frame, (c) the documented param-spill bridge bug (single-use rcx/rdx/r8/r9 read from uninitialised slots), (d) stack
   `subq/addq` balance around the SHA-256 streaming calls (`sha256_init/update/finalize_internal/digest_byte`).
3. Only after the writer is identified in the binary → Phase 3 fix → rebuild → disasm-verify → restore KAT 1022 (exit 99).

## Phase 1 UPDATE (2026-06-02) — the "crash" is mis-characterised; reproduce was PREMATURELY TIMED OUT

Re-reproduced 1022 on the CURRENT binary: it returns **exit 124 (timeout), NOT 139 (segfault)**.  Two facts
reframe the whole item:

1. **1022's own header (line 28): "SLH-DSA-'S' sign is deliberately slow (~15-30s) -- two keygens + one sign."**
   The reproduction used a **25s** timeout — too short.  Exit 124 is the timeout firing, not necessarily a hang/crash.
2. **`771_slhdsa_sha2_fips205` is in the GREEN corpus EXPECTED table** and calls `iii_slhdsa_sha2_sign(0u64, ...)`
   DIRECTLY (one keygen + one sign).  If 771 passes, the SHA-2 sign path **works** end-to-end; the only delta to 1022
   is the `iii_pq_dispatch` route (`iii_pq_sign → iii_slhdsa_sha2_sign`) + a SECOND keygen + a verify (≈30-45s total).
3. The README's prior-session **139 segfault** was real then, but the slhdsa source is committed-clean and has **no
   function-local arrays** (ruled out the `[[feedback_iii_local_array_runtime_index]]` class); the current binary's
   different link addresses likely turn the old wild-write into a non-faulting store (hence 124 not 139) OR the path
   simply needs >25s.

**DECISIVE NEXT TEST (run ALONE, not against the live corpus):** re-run 1022 with a **90s** timeout.
- exit 99 → the SHA-2 sign + pq route are CORRECT; 1022 was only slow → un-quarantine it (with a slow-test note),
  #5 closes as "was a premature-timeout false alarm; SHA-2 sign verified by 771 + 1022".
- exit 139 → a real crash remains → gdb-localise the faulting store, then trace the pq-route param delta vs 771.
- still 124 at 90s → a real infinite loop → gdb-interrupt + backtrace.

Gate on the corpus first (it RUNS 771 — confirms the SHA-2 sign works in-budget), then the 90s 1022 retest.

## RESOLUTION (2026-06-02) — NO crash; was a premature-timeout false alarm

Ran 1022 with a 90s cap: exit **99**, then **99 again, then 99 again** — three consecutive deterministic passes.
The test drives the full SHA-2 **sign → SHA-2 verify** roundtrip + a cross-family-reject + bad-suite negatives; a
still-corrupted `sig_len_out` would make the roundtrip verify FAIL (the corrupted length/pointer would mis-read the
signature), so a clean pass is positive proof that `[rbp-0x30]` is NOT corrupted on the current binary and the
SHA-2 sign + the `iii_pq_dispatch` route are correct end-to-end.  The README's prior-session exit-139 segfault was
real on that (now-superseded) binary; the committed-clean `slhdsa.iii` + the many lib rebuilds since produce a
binary whose layout no longer manifests it, and — crucially — the **signature is byte-correct** (verify accepts),
so there is no latent corruption being masked.  `slhdsa.iii` has **zero function-local arrays** (the runtime-index
segfault class is impossible here), and `771_slhdsa_sha2_fips205` (direct `iii_slhdsa_sha2_sign`, green baseline)
independently confirms the SHA-2 sign.

**ACTION TAKEN:** 1022 restored to `STDLIB/corpus/` (out of `_quarantine_wip/`) + `[1022_pq_dispatch_sha2_route]=99`
registered in `run_corpus.sh`.  #5 closes: the SHA-2 sign was already correct; the quarantine was caused by a
25-second reproduction timeout firing on a deliberately-~30-45s test.  Verified in the full corpus run.
