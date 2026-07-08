# III — Γ2a HOST CLOSURE: the SysV/ELF native host rung (EXECUTED)

> **STATUS: VERIFIED-IN-CODE (executed 2026-07-08).** The first non-win64 NATIVE host route in III.
> Every claim below was produced by `run_host_matrix.sh` against the live tree; the ELF binaries were
> executed on a real Linux userland (WSL1 Debian, `Linux 4.4.0-26100-Microsoft`). Companion:
> `III-GERMINATION-MAP.md` (Γ, the frame; this closes its rung Γ2a). Gate: `STDLIB/sovir/run_host_matrix.sh`.

---

## 0. The result in one paragraph

III now runs on **three native hosts and an interpreter from one SVIR program set**: win64 (kernel32-only
PE), **SysV/ELF64 Linux (new)**, wasm (node), and the reference interp. The new route is a single sovereign
stage — `svir_elf.iii` (SVIR → static ELF64 executable) — that emits a **complete, runnable Linux binary
with ZERO imports, ZERO libc, ZERO host toolchain**: PRINT_CHAR is the `write(2)` syscall, exit is
`exit(2)` (syscall 60), and the 4 MiB `svir_mem` is a second `PT_LOAD` the kernel zero-fills. The host set
grew **{win64, wasm} → {win64, wasm, sysv-elf}** and the anchor grew by **zero lines** — the architectural
law that makes host closure cheap (hosts live *below* the waist). 10 programs (5 hand-authored SVIR + 4
frontend-compiled `.iii`, including a real Newton integer-sqrt organ + the OOB trap vehicle) agree on every
host; `fact`'s 20! prints byte-identically across win64, sysv, and an independent golden; the OOB
CALL_INDIRECT trap fires uniformly (199); a perturbed ELF byte fails the run (teeth).

---

## 1. What was built

| Artifact | Kind | Lines | Role |
|---|---|---|---|
| `STDLIB/sovir/svir_elf.iii` | NEW translator (floor member) | ~430 | SVIR v1/v2 → static ELF64 x86-64-SysV executable, direct machine code, two-pass |
| `STDLIB/sovir/run_host_matrix.sh` | NEW gate | ~130 | the {win64, sysv-elf, wasm, interp}+anchor matrix, falsifiers, down-only host ratchet |
| `STDLIB/sovir/HOSTS.pin` | NEW ratchet file | 4 | pinned host set (down-only): win64, sysv-elf, wasm, interp |
| `STDLIB/independence/indep_isqrt.iii` | NEW organ | ~25 | Newton integer sqrt — the first real *algorithmic* organ across all host routes (Γ1 down payment) |

**Design (why it is one sovereign stage, not a pipeline).** The win64 route is SVIR→`.s`→sovas→sovld→PE
(three sovereign tools). ELF has no such asm/link chain in-tree, so `svir_elf` emits **machine code and the
ELF container directly** in two passes: pass 1 walks every function measuring byte positions (function
starts, structured-control labels, helper addresses) into `FSTART[]`/`LBL[]`; pass 2 re-walks and prints.
The walk is deterministic, so both passes allocate identical label ids and the pass-1 addresses are exact.
All jumps/calls are fixed-width rel32, so no relaxation is needed. Binary stdout uses the wasm-route's proven
`_setmode(O_BINARY)+putchar` emission path.

**The SysV deltas from `svir_x86` (op-for-op otherwise identical lowering):** args in
`rdi rsi rdx rcx r8 r9` (6 regs, no 32-byte shadow); incoming stack params at `[rbp+16+8*(j-6)]`; traps are
`exit(198)` (unresolved-import stub) / `exit(199)` (`__svci` OOB) via syscall 60 — the same sentinels the
interp returns and win64 raises via `ExitProcess`; `__putc` = `write(1,&ch,1)`; `__svci` = the cmpq/jz
tail-dispatch switchboard with SysV encodings. Same eval-stack machine, same frame shape, same `-8(%rbp)`
call-rsp-save slot as the win64 route.

---

## 2. Measured results (run_host_matrix.sh, rc=0)

```
LAW anchor-zero-diff : svir_verify.iii untouched (hosts live BELOW the waist)
sum        verify=99  interp=99  win64=99  wasm=99  sysv=99   ok
loop       verify=99  interp=99  win64=99  wasm=99  sysv=99   ok
call       verify=99  interp=99  win64=99  wasm=99  sysv=99   ok
fact       verify=99  interp=99  win64=99  wasm=99  sysv=99   ok
bignum     verify=99  interp=99  win64=99  wasm=99  sysv=99   ok
cioob      verify=99  interp=199 win64=199 wasm=1   sysv=199  ok      (OOB trap: uniform 199; wasm native trap)
toolchain  verify=99  interp=99  win64=99  wasm=99  sysv=99   ok
ops        verify=99  interp=99  win64=99  wasm=99  sysv=99   ok
bignum2    verify=99  interp=99  win64=99  wasm=99  sysv=99   ok
isqrt      verify=99  interp=99  win64=99  wasm=99  sysv=99   ok      (Newton isqrt organ, all hosts)
fact stdout win64 == golden 20! (byte-identical, raw host bytes)
fact stdout sysv  == golden 20! (byte-identical, raw host bytes)
fact stdout interp== golden 20! (digit-identical; CRLF text-mode normalized)
FALSIFIER perturbed-ELF-byte -> rc=1 != 99 (teeth confirmed)
HOST MATRIX GREEN
```

**Foreign-witness (readelf, the emitted `sum.elf`):** `ELF 64-bit LSB executable, x86-64, SYSV, statically
linked, no section header`; entry `0x400078`; one `PT_LOAD` R+E at vaddr `0x400000`; `bignum` (touches
`svir_mem`) carries the second `PT_LOAD` RW as designed. `objdump` disassembly of the text matches the
intended lowering (movabs/imul/cqto/idiv/cmp/sete… then the syscall exit). The binary imports nothing.

**The interp-stdout note (honest):** the interp is the gcc-compiled *reference tool*; its msvcrt `putchar`
runs in Windows console **text mode**, so its trailing `\n` becomes `\r\n`. It is not a shipped host binary,
so its `fact` row is compared CR-normalized — the digit stream is identical; only the line-terminator
representation is text-mode. The two SHIPPED host binaries (win64 kernel32-`WriteFile`, sysv `write(2)`)
emit **raw bytes** and are strictly byte-identical to the golden.

---

## 3. Falsifiers (teeth, all live in the gate)

- **anchor-zero-diff LAW:** `git diff --quiet svir_verify.iii` — host closure that grows the anchor reddens
  the rung itself. (Γ2's binding law: hosts differ *below* the waist, never in it.)
- **perturbed ELF byte:** overwrite one text byte with `0x90` → the run must NOT return 99 (measured: rc=1).
- **OOB CALL_INDIRECT:** the `_svir_ci_oob` module completes cleanly to 99 *iff* the executor fails to trap;
  every real host must return 199 (wasm: native table-bounds trap, non-99/non-0).
- **down-only host ratchet:** `HOSTS.pin` lists the pinned hosts; a pinned host that stops executing here
  reddens the gate.
- **cross-host stdout differential:** `fact`'s 20! must be byte-identical across the raw-byte hosts and an
  independent node golden.

---

## 4. Scope, limits, and what remains open (named, not hidden)

- **Pure organs only, by design and by measurement.** The ELF route needs **zero libc** because the body is
  `extern fn`-free and its heap is in-waist. Organs that touch OS symbols (the 37 aether modules) are a
  per-host shim layer — not part of this rung; a windowing/net capability exists on Linux exactly when its
  shim set exists there.
- **The Linux host here is WSL1** (a real Linux userland over the NT kernel). The ELF is a genuine static
  SysV binary; running it on bare Linux/qemu-user is the same binary. WSL1 executes it via its syscall
  translation — `write`, `exit`, and the `PT_LOAD` mmap are all in WSL1's supported set.
- **Integer-exact only:** no floats (the waist is float-free by design); unchanged by this rung.
- **Determinism:** the two-pass emitter is fully deterministic (no `Date`/`rand`); re-emitting the same SVIR
  yields byte-identical ELF.

---

## 5. Confidence + confirmation

**VERIFIED-IN-CODE**: the emitter compiles under the in-tree `iiis-2`, the ELFs execute on real Linux to the
expected exit codes, `fact` stdout is byte-identical cross-host, and every falsifier reddens on mutation.
**Watch (carried to Γ2c AArch64):** the same two-pass direct-emit pattern retargets to a fixed-width ISA;
the open cost there is a new instruction encoder, not the framework. **The one-sentence result:** *a pure
III computation, compiled to SVIR, now becomes a self-contained Linux executable that imports nothing and
runs identically to its win64 and wasm siblings — the host set grew by one, the trust anchor by zero.*
