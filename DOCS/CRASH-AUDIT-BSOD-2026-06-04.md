# CRASH AUDIT — BSOD 0x50 PAGE_FAULT_IN_NONPAGED_AREA (gate_ioctl.sys, 2026-06-04)
> **STATUS: HISTORICAL RECORD** — crash forensics / closed findings of their era; the fixes are landed and gated (reunification W6).

Status: **FIXED + verified in Ring-3 and in the binary; gates green; goldens resealed. Metal
re-deploy is the only remaining step (operator-gated UAC).**
Protocol: user CLAUDE.md CRASH PROTOCOL — Phase 1 (evidence) ✓, Phase 2 (verify-in-binary) ✓,
Phase 3 (fix) ✓, Phase 4 (metal re-test) = pending the UAC. No .iii/.sh edits before this audit.

## 9. RESOLUTION (applied + verified, 2026-06-04)

Fix = the packed-read idiom, NOT a backend rewrite (advisor-steered):
- `sha256_oneshot_packed` (sha256.iii) + `cad_oneshot_packed`/`cad_keccak_packed` (cad.iii): read the
  source as `*u64` (stride 8 IS correct for u64 — a qword == one slot) and feed shift-extracted LE
  bytes via `sha256_update_byte` / a slotted keccak scratch.
- `ks_measure` (quine_seal.iii) + the cycle seal (seal.iii) now call the packed variant.
  `KS_TEXT_LEN` rebaked `0x14e00 -> 0x16000` (= `.data_RVA(0x17000) - .text_RVA(0x1000)` = full
  mapped `.text`; two-pass converged — the movabs immediate doesn't resize `.text`).

Verification (III alone):
- Ring-3 guard-page: old `*u8` path SEGFAULTs (139), packed path exits 99 — **reproduces THEN stops**.
- Absolute FIPS: cg_r0 `cad_oneshot_packed` of the 56-byte NIST vector == `0x248d6a61` (not a peer
  differential). Prove-the-negative: the old slotted path gives `OUT[0]=0x6F != 0x24`.
- corpus PASS=780 FAIL=0 (seal value byte-preserved: old byte-packed == new packed in cg_r3).
- cg_r0 crypto gate 3/3 (sha256 1-block + byte-packed multi-block FIPS + guard-page over-read).
- ks_selftest += byte-packed-input FIPS check (the KAT that originally missed this).
- Binary: `ks_measure -> call L_p_cad_oneshot_packed`; `sha256_oneshot_packed` calls
  `sha256_update_byte` (×9) and NEVER `sha256_update` (the over-reading `*u8` copy loop). Dispatch
  IOCTL `0x222000/4/8` intact; 55 `movl %eax,%eax` u32 masks intact; gate-admit verdict cg_r0==cg_r3.
- gate_ioctl.sys = `4bffca9b215a903fb5dcac453cbc5ba7af2b87014750cdb1ba28ae6c485ba5a6` (reproduced
  under the rebuilt iiis-2 -> cg_r0 codegen deterministic). iiis-1 golden stable; iiis-2 golden
  resealed `3b9986c9 -> 6be6af39` (legitimate stdlib re-bundle; cg_r0.iii unchanged so no codegen
  drift). Deploy ExpectedHash updated.

## 1. The crash (hard evidence)

Kernel dump `C:\Windows\Minidump\060426-11000-01.dmp` (PAGEDU64, 6.5 MB), header bugcheck:

```
BugCheck 0x00000050  (PAGE_FAULT_IN_NONPAGED_AREA)
  p1 = 0xfffff804b5ee9000   faulting address (the READ target; p2=0 => read)
  p3 = 0xfffff804b5e8a7ba   faulting instruction
```

Base-independent invariant `p1 - p3 = 0x5e846`. Load base `0xfffff804b5e80000` =>
`RVA(p3)=0xa7ba`, `RVA(p1)=0x69000`. PE `SizeOfImage=0x69000`; `.bss` ends RVA `0x66190`.
**The faulting read is exactly at the image boundary** — first unmapped page past the image. That
clean match fixes the base. The only indexed read at page-offset `0x7ba` is `L_p_sha256_update+0x185`:
```
14000a7ba:  48 8b 04 c8   mov (%rax,%rcx,8),%rax    ; rax=input, rcx=off+k, SCALE 8
```
Source `STDLIB/iii/numera/sha256.iii:286` (streaming copy loop):
```
SHA_BUF[idx] = input[off + k]     // input:*u8 -> element stride MUST be 1
```

## 2. Why now (post-M23), not before

Prior deploy fail-closed at the M23 quine-seal (separate cg_r0 u32-width defect, since fixed+gated).
With M23 passing the driver goes resident and reaches gate_ioctl -> gate-admit closure ->
katabasis_cycle_seal -> cad -> sha256_update on **multi-block cycle data**. The 1-block self-attest
("abc") is correct; the >=2-block cycle hash is the first multi-block sha256 the resident driver runs.

## 3. Root cause — cg_r0 stride-8 on an assignment-RHS pointer/array index

cg_r0 mis-compiles a pointer/array element read **when it is the RHS of an assignment**: it emits a
scale-8 SIB with the index value in `rcx` (`mov (rax,rcx,8)` = stride 8) instead of folding
`index*elem_size` (1 for u8) into the base with `rcx=0`. Standalone reads fold correctly.

Minimal reproduction (Ring-3, cg_r0): `DST[idx] = src[off+k]`, `src:*u8`
```
cl_copy(&S,8) -> DST[5] = 41 (== SRC[40] == SRC[5*8]); expected 6 (SRC[5])
disasm: mov (%rax,%rcx,8), rcx = off+k (nonzero) -> stride 8
```
These FOLD correctly (rcx=0) as standalone reads, returning the right value: `SRC[5]`, `SRC[ii]`,
`SRC[ii+jj]`, `p[5]`, `p[n]`, `p[ii+jj]`.

Absolute-FIPS confirmation (56-byte NIST vector, digest `0x248d6a61…`):
- cg_r0 sha256_oneshot top word `0xED…`  WRONG
- cg_r0 init/update/final               WRONG (different wrong value)
- cg_r3 sha256_oneshot  `0x248d6a61`     CORRECT (99)
=> defect is **cg_r0-only**, in element-read codegen, not in sha256.iii.

## 4. Why every gate missed it (false-green analysis)

- cg_r0 crypto gate only hashes "abc" (1 block); the corruption is in multi-block accumulation.
- cg_r0 multi-block differential compared cg_r0 vs cg_r3; cg_r3 carries its own index defect
  (`(&arr as *u8)[i]` cast-form reads stride-8: q3_ptrcast cg_r3=41), so both agreed on a
  wrong-but-equal answer => false 99. A differential vs a peer that shares the bug is not a proof.
  Must test vs the absolute FIPS constant.
- Ring-3 gate-admit did not fault: OOB read lands in mapped userspace .bss (no fault), verdict
  unaffected (spurious read). Only the kernel's unmapped boundary bugchecks.

## 5. Fix plan (Phase 3/4 — pending)

1. cg_r0.iii element-load / assignment-RHS index codegen: fold the byte offset (or use SIB
   scale=elem_size) on the RHS path, matching the standalone-read path.
2. Characterize the cg_r3 cast-form stride-8 (`(&arr as *u8)[i]`) — separate latent defect; sha256
   uses the param form so cg_r3 sha256 is correct, but fix or document the cast form.
3. Re-verify (Ring-3, III alone): cl_copy->6; cg_r0 nist oneshot+update == 0x248d6a61; gate-admit
   verdicts == cg_r3; full corpus; 59/0 determinism; check_rm2.
4. Strengthen gates: crypto gate += multi-block absolute-FIPS vector; width/stride gate +=
   `arr[i]=ptr[expr]` assignment-RHS pattern vs absolute expected.
5. Rebuild gate_ioctl.sys; disasm copy loop to prove fold/scale-1; re-verify BSOD-critical paths
   unchanged. Only then re-deploy on metal (user UAC).

## 6. Disposition of the deployed u32-width fix

The u32-width fix (movl loads + masks) is correct and independently gated; NOT implicated here. This
is a distinct pre-existing cg_r0 element-read stride defect, exposed because M23 now passes. Keep it.

## 7. CONFIRMED faulting call (KTRAP_FRAME extraction) — corrects §3's example

Scanned the dump for the faulting RIP (`p3`), located the page-fault KTRAP_FRAME (validated by
`rax + rcx*8 == p1`), read the *original* registers:
```
rax (input) = 0xfffff804b5e81000  = base + 0x1000  = the driver .text start (RVA 0x1000)
rcx (index) = 53248 (0xd000)
rax + rcx*8 = 0xfffff804b5e80000 + 0x1000 + 0x68000 = 0xfffff804b5ee9000 = p1  (exact)
```
The faulting call is **`ks_self_measure` -> `ks_measure(base+0x1000, KS_TEXT_LEN=0x14e00, out)`**
(quine_seal.iii) — sha256 over the driver's own **byte-packed `.text` image**. With cg_r0's `*8`
stride the copy loop walks 8x and crosses the image boundary at index `0xd000` (< the intended
`0x14e00`), into the first unmapped page. It runs in `gate_self_attest` immediately after
`ks_engine_ok` (M23 "abc") passes, so the crash is **mid-driver_entry; the driver never goes
resident**. (Prior advisor note: the len-48 cycle seal CANNOT reach `0x69000` — max read
`input+376` — and gprobe ran it without faulting. The seal is a *latent wrong-hash* bug, not this
BSOD; it is in scope to fix but is not the crash.)

Root mechanism (unchanged): cg_r0 is 8-byte-uniform; `*u8` indexing reads SLOTS (`+k*8`). A
slotted `[u8]` array (e.g. the crypto gate's "abc" IN) reads correctly; **byte-packed external data**
(the `.text` image, a `[u64]` cast to `*u8`) does not — it over-reads 8x.

## 8. Fix strategy (advisor-disciplined) — pending, NOT yet applied

Hard line (advisor): NO metal redeploy until the crash REPRODUCES then STOPS in Ring-3 with a
guard page. Sequence:
1. Guard-page repro (Ring-3, III): VirtualAlloc a buffer + trailing PAGE_NOACCESS, point a cg_r0
   cad/sha256 at it with a byte length; the `*8` over-read must fault (AV) — reproducing the BSOD
   safely in userspace.
2. Fix the byte-packed-hash paths the cg_r0-idiomatic way: read the source as `*u64` (stride 8 is
   CORRECT for u64 in the 8-byte-uniform model) and feed bytes (shift-extract) to `sha256_update_byte`
   (which writes `SHA_BUF[slot]=byte`, correct). This yields the byte-wise FIPS hash with no `*u8`
   over-read. Apply to `ks_measure` (.text) AND the cycle seal (KCS_BUF) — no latent bug left.
   Verify the build-time `.text` seed is byte-wise so the runtime measure still matches.
3. Prove: guard-page no longer faults; cg_r0 sha256 of a byte-packed multi-block buffer == absolute
   FIPS (`0x248d6a61` for the 56-byte NIST vector); gate-admit verdicts; full corpus; 59/0; check_rm2.
4. Strengthen gates: crypto gate += byte-packed multi-block absolute-FIPS vector; add a guard-page
   over-read gate so this class faults loudly in CI, not on metal.
5. Rebuild gate_ioctl.sys; disasm to prove the measure path no longer `*8`-over-reads; re-verify
   BSOD-critical paths unchanged; reseal iiis-1/2 if cg_r0.iii changed; THEN metal (user UAC).

Deeper generalization (separate, deliberate — NOT under post-BSOD fatigue): make cg_r0 fully
element-size-aware (byte-packed layout + element-sized stride, matching cg_r3). The u64-feed fix
above is the correct idiom within the current model and resolves every byte-packed hash in the
kernel; the element-aware port broadens it but is the highest-blast-radius backend edit and is
done as its own gated project, not inline with a crash fix.
