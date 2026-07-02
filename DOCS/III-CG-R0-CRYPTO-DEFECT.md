# cg_r0 (Ring-0 backend) crypto codegen defect — u32 WIDTH **[FIXED 2026-06-04]**
> **STATUS: HISTORICAL RECORD** — crash forensics / closed findings of their era; the fixes are landed and gated (reunification W6).

**Found:** 2026-06-04, by the C.10 KATABASIS IOCTL-gate metal deploy (the first-ever metal test of the M23 quine-seal).
**Status:** ✅ **FIXED + VERIFIED.** The defect is u32 WIDTH (NOT register pressure — the initial hypothesis below
the isolation ladder was wrong; the differential narrowing corrected it). cg_r0 was "8-byte-uniform": it emitted
every op as 64-bit and never truncated a u32 result, so high-half garbage (a wrap carry into bit 32, or a left-
shifted bit) leaked into a later `shr`/unsigned-`cmp`/`div`/`mod`. The fix mirrors cg_r3's invariant — a u32 value
stays CLEAN (high 32 = 0) in `%rax`: width-aware `movl` local loads + `movl %eax,%eax` truncation after ADD/SUB/
MUL/SHL — added to `COMPILER/BOOT/cg_r0.iii` (`r0_expr_is_u32`/`r0_tref_is_u32` + the load/mask sites). Verified
correct-by-construction by the differential oracle: `cg_r0_width_gate.sh` 10/0 (cg_r0==cg_r3 on shr/cmp/div/mod)
and `cg_r0_crypto_gate.sh` (cg_r0 sha256("abc")==FIPS). ~40 lines mirroring a proven reference.

## The defect

`cg_r0` (the Ring-0 codegen, `--ring R0`, used by `KATABASIS-DEPLOY` kernel drivers) **mis-compiles sha256**:
`cg_r0 sha256("abc")` ≠ the FIPS-180-2 vector `ba7816bf…f20015ad` (wrong from byte 0). The default backend
(`cg_r3`, gated by `build_iiis2 --check-corpus` 59/0 + `run_corpus`) compiles it correctly — proven by the
green corpus KATs `02_sha256_kat_abc`=186, `1047_quine_seal`=99.

**Pre-existing, NOT a WIP regression.** Discriminator: the committed-HEAD compiler (`git show HEAD:COMPILED/iiis-2.exe`)
also produces the wrong cg_r0 sha256 (`shacheck` exit 118 / gate byte-1 fail). The concurrent WIP touches
`cg_r0.iii` only +4 lines (vs `cg_r3.iii` 7108, `sema.iii` 4118 — a large cg_r3/sema effort), and the bug
predates it.

## Root cause (differentially isolated — cg_r0 vs the cg_r3 oracle, no hand-computed values)

`cg_r0` register allocation / spilling **corrupts state under high live-register pressure** — specifically the
full SHA-256 round body: 8 live state vars (a–h) PLUS the `Σ0/Σ1/ch/maj` sub-expressions, iterated 64×.

Isolation ladder (all via `--ring R0` vs default, XOR-fold differential):
- **OK** — every primitive: u8→u32 big-endian load, `ch=(e&f)^(~e&g)`, `maj`, `Σ` (rotr-xor), σ (rotr+shr), wrap-add chain.
- **OK** — moderate pressure: a 10-variable no-rotation loop.
- **OK** — the rotation chain alone: 8-var `h=g g=f … a=t1+t2` with 2 simple temps.
- **OK** — schedule with compound runtime indices `W[t-2]`, `W[t-15]`, …
- **DIFF (mis-compiles)** — the full SHA round body (8 state + Σ/ch/maj), with OR without the `W[k]` array read,
  with 6 explicit temps OR 2 (sub-exprs inlined). It is the *live-register count of the round*, not the array,
  not the temp count, not the rotation.

So: a classic spill defect — cg_r0's allocator mishandles the spill set once the round's live u32 count crosses
its threshold. The fix is in `COMPILER/BOOT/cg_r0.iii` (register allocation / spill), golden-moving (reseal).

## Why it stayed invisible — and the structural fix

`cg_r0` is **ungated**: `build_iiis2 --check-corpus` (59/0) and `run_corpus` exercise ONLY the default backend
(cg_r3 / stage1). Nothing ever compiled through `--ring R0` and checked the output. The KATABASIS gate's verdicts
passed metal (2026-05-23) because the gate compares a *computed* seal to a *claimed* seal — both through the same
buggy hasher, so a consistent error cancels and verdicts look right. The M23 quine-seal checks
`sha256("abc") == FIPS` — an **absolute** reference the bug can't hide from — so it fail-closed on first metal load.

**Structural fix landed this session:** `COMPILER/BOOT/cg_r0_crypto_gate.sh` — compiles each crypto module through
`--ring R0`, runs it in a Ring-3 harness (stubs only the kernel witness leaf + the cpufeat CPUID shim; III's own
cg_r0 emits the code under test), and asserts the FIPS/known-answer the gated default backend reproduces. cg_r0
divergence ⇒ GATE FAIL. Currently **FAILS on sha256** (correctly — it catches the live defect). Non-golden-moving,
in-session, III-alone. **This closes the entire bug class** — once cg_r0 is fixed, this gate keeps it fixed.
TODO (non-golden-moving follow-up): wire `cg_r0_crypto_gate.sh` into the standing build/determinism gate so the
Ring-0 backend can never again ship unverified; extend its probe set to keccak/blake2s.

## ⚠ Golden exposure

The array-fix reseal earlier this session rebuilt `COMPILED/iiis-{0,1,2}.exe` from the current sources. Because
cg_r0 is ungated, a wrong-hash Ring-0 backend is (and was already) sealed into the golden invisibly. This does
NOT affect the default-backend determinism (59/0 holds) or any Ring-3 stdlib/corpus result — only `--ring R0`
crypto output. The cg_r0 fix + this gate close it.

## C.10 status (honest)

- **CORE R3→R0 IOCTL gate capability: metal-proven 2026-05-23** (verdicts OK/REJECT_SEAL/REJECT_CAP/REJECT_HEXAD).
- **Driver build + codegen: verified this session** — gate_ioctl.sys rebuilt; cg_r0 disasm confirmed the DRIVER_OBJECT
  dispatch table (indices 13/14/16/28 exact), all WDM accessors (idx 1/3/23 exact), gate_self_attest (idx 3),
  and CP-1 (full-width null + length compares, handler gates derefs on the guard result). CP-1 logic KAT `1092`=99.
- **Metal deploy executed (operator UAC):** the driver loaded **memory-safe (NO BSOD)** and **fail-closed cleanly**
  at the M23 self-attestation (`sc start` error 31 = STATUS_UNSUCCESSFUL = `ks_engine_ok()!=1`), because
  `cg_r0 cad("abc") != FIPS`. The fail-closed design + the verified memory paths are why error 31, not a bugcheck.
- **BLOCKED:** C.10-with-M23 cannot pass metal until cg_r0 emits correct hashes. The CP-1-hardened driver source
  stays uncommitted WIP (verified, not authored by me).

## Next op (scoped, deliberate, fresh-state)

Fix `cg_r0.iii` register allocation/spill for high-pressure function bodies (the SHA round), rebuild the kernel
closure, re-run `cg_r0_crypto_gate.sh` to GREEN, then re-deploy C.10 (operator UAC) to confirm M23 goes resident +
`gate_client.exe` prints "ALL 4 GATE VERDICTS CORRECT". Reseal the golden (now with a CORRECT, gated cg_r0).
