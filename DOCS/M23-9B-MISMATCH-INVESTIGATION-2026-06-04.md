# M23 9b behavioral quine-seal MISMATCH — investigation (2026-06-04)

Status: **RESOLVED + PROVEN ON METAL (2026-06-04, .sys a91b667b).** quine_attest_client.exe exit 99:
"M23 SUCCESS (capability 11) - the running driver's below-OS .text measurement EQUALS the
independently-recomputed on-disk seal." All 4 gate verdicts also correct; no BSOD; clean DriverUnload.
Root cause was NOT a byte difference (live==file over the code is real) — it was cg_r0's **slotted
digest OUTPUT**, closed by byte-packed emit + a VirtualSize (code-only) measure. See §RESOLUTION.

## RESOLUTION (2026-06-04)
Root cause: `cad_oneshot_packed` had a byte-packed INPUT read (the BSOD fix) but `sha256_final`'s
OUTPUT write `out[i]=byte` strides by 8 under cg_r0 -> the digest is written one byte per u64 slot.
So the driver's `G_ATTEST [u64;4]` captured only digest[0..3] and `gate_attest_report` shipped
`{d0,0x7, d1,0x7, d2,0x7, d3,0x7}`. The 4 verdicts passed because the cg_r0-internal `cad_eq` reads
the SAME slotted layout (self-consistent); M23 failed because the cg_r3 client reads byte-packed.
The crypto gate missed it because `cad_packed_fips` compared slotted-OUT to slotted-EXP (both stride 8).

Fix (backend-agnostic, surgical to the cross-backend path):
- `sha256_emit_bp` / `keccak256_final_bp`: write the digest with 4 u64 STORES (byte-packed on BOTH
  backends), reading the slotted SHA_H / sponge words. `sha256_oneshot_packed_bp` /
  `cad_oneshot_packed_bp` use them. `sha256_final` + `cad_eq` + the cycle seal STAY slotted (their
  cg_r0-internal consumers read slotted; unbroken; verdicts still 228).
- `ks_self_measure` uses `ks_measure_bp` -> `cad_oneshot_packed_bp`: G_ATTEST is now the universal
  byte-packed digest the Ring-3 client expects.
- `ks_text_size`: the driver parses its OWN PE at runtime (`ks_rd_byte` packed idiom) for the .text
  SizeOfRawData, so the self-measure length AUTO-MATCHES the client (same field) -- retires the
  fragile baked `KS_TEXT_LEN` (0x14e00->0x16000->0x17600 ...).

Verified III-alone: cg_r0 driver-measure == cg_r3 client-measure == python sha256(.text) = 0x460053c1;
`ks_text_size`=SizeOfRawData (PE-parse correct); cg_r0-gate PASS=4 (NEW `cad_packed_bp_fips` reads the
output byte-packed, the prove-the-negative the old gate lacked); width 10/0; stage1 59/0; check-rm2 OK;
4 verdicts 228 (cycle seal untouched); iiis-1 stable; iiis-2 resealed `4dc56712 -> 7a5f8090`; lib
`42dfd9e7`; .sys `9de95df8`. Deploy ExpectedHash updated.

---
ORIGINAL INVESTIGATION (the path to the root cause — kept for the record):
This note tracks the *separate* 9b attestation mismatch (`quine_attest_client.exe`
exit 7: live `.text` measure != independently-recomputed on-disk seed).

## What is proven CORRECT (III alone, Ring-3)
- **Client recompute is right.** `ks_measure((&FILE)+0x400, 0x16000)` over the on-disk `gate_ioctl.sys`
  `.text` = `fe22e3f6…` = Python `sha256(.text[0x400:0x400+0x16000])` ground truth. (rec probe sel=3/4/5:
  direct-cad O[0]=0xfe, ks_measure O[0]=0xfe, O[3]=0xf6 — all match.)
- **cad_oneshot_packed is right at every size**, BOTH backends: cg_r0 and cg_r3 each reproduce the
  Python sha256 of a byte-packed pattern at 0x100/0x1000/0x4000/0x8000/0x10000/0x16000.
- **Deployed client is current**: its `ks_measure` calls `cad_oneshot_packed` (not the slotted
  `cad_oneshot`); PE parse reads SizeOfRawData(off16)=0x16000 + PointerToRawData(off20)=0x400.
- **Lengths agree**: driver `KS_TEXT_LEN`=0x16000 / `KS_TEXT_RVA`=0x1000 (read from the deployed
  `.sys` `.rodata`); client uses SizeOfRawData=0x16000. Same 0x16000 bytes.
- **Signed vs unsigned `.sys` `.text` are byte-identical** (sha256 `fe22e3f6` both).

## Why live `.text` SHOULD equal file `.text` (triple-confirmed — no load-time patching of `.text`)
- `.reloc`: 30 relocs, ALL target `.data` (0 in `.text` 0x1000–0x17000).
- No Load Config directory (RVA=0) ⇒ **no DVRT** ⇒ kernel applies no dynamic-value/retpoline
  import-optimization relocs.
- **Zero** indirect IAT calls (`call *disp(%rip)`) in `.text`; IAT lives at RVA 0x67058 (`.idata`,
  outside `.text`). Nothing in `.text` is loader-patched.

## The contradiction
Same bytes, same length, same (verified-correct) `cad_oneshot_packed`. Client (Ring-3) = `fe22e3f6`.
Driver (kernel) `G_ATTEST` != that ⇒ exit 7. Every static avenue says they must be equal.

## Prime remaining suspect: the WITNESS LEAF (kernel-only difference)
cg_r0 emits `call iii_witness_emit_kernel` at every function entry/exit. In the Ring-3 harness it is a
no-op STUB; in the kernel it is the REAL leaf. The `.text` self-measure feeds 0x16000 bytes through
`sha256_update_byte` — ~90K calls, each wrapped in witness entry/exit. A cumulative state bug
(clobbered callee-saved reg / aliased memory) in the real leaf would corrupt the long accumulation
yet leave the SHORT cycle-seal hash (len-48, the one driving the 4 verdicts) correct — exactly the
observed split (4 verdicts PASS, 9b FAIL).

Disconfirms SHA-NI: the `.sys` contains ZERO `sha256rnds2`/`sha256msg` — kernel hashing is scalar
(correct). Not an import/reloc patch (above). Not a stale client (above). Not the length (above).

## Next diagnostics (in order)
1. Read `iii_witness_emit_kernel` source/emission: does the real leaf preserve ALL regs the cad path
   relies on across the call, and does its ring-buffer write alias any sha256 global?
2. If the leaf is pure, link the REAL leaf into the Ring-3 rec probe and re-measure — does the result
   diverge from `fe22e3f6` once the real leaf is present? (isolates leaf-vs-stub as the cause).
3. If confirmed: fix the leaf's preservation, OR suppress witness emission on the measure path, OR
   measure via a witness-free code path. Re-deploy; expect exit 99.
