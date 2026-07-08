# III — Γ2c + Γ4/Σ0 + Γ3: arm64 host, the spore, retargeting closure (EXECUTED)

> **STATUS: EXECUTED, ALL GATES GREEN (2026-07-08).** This ledger records the session that took the
> GERMINATION map (`III-GERMINATION-MAP.md`) from ANALYSIS to three executed rungs. Every claim below is
> backed by a gate that ran `rc=0` this day on this machine; logs in `COMPILED/_mx2.log`,
> `_retgt3.log`, `_germ5.log` (final regression sweep, all three in sequence, rebuilt assembler).

## 1. What landed

### Γ2c — AArch64 host (`svir_arm64.iii`, 429 ln; gate = `run_host_matrix.sh`)
The fourth execution host, and the first FOREIGN ISA. One sovereign stage: SVIR v1/v2 → complete static
ELF64 AArch64 executable (fixed-width encoder; software eval stack in x28 — sidesteps AArch64's SP-16
alignment fault; MOVZ+MOVK×3 constants so pass-1 byte positions == pass-2; PRINT_CHAR = `svc write`,
exit = `svc exit`; same 198/199 trap sentinels as every host). Matrix now: **verify + interp + win64 +
wasm + sysv + arm64**, 10 programs, one row each — all agree; fact's 20! byte-identical across
win64/sysv/arm64/golden; OOB CALL_INDIRECT traps 199 on every real executor; perturbed-byte falsifiers
on BOTH ELF routes; anchor grew ZERO lines (the Γ2 law, gate-checked). `HOSTS.pin` is now
`win64 sysv-elf wasm interp arm64` (down-only).

**Executor bootstrap (measured, the hard-won part):** WSL1's mmap rejects `MAP_FIXED_NOREPLACE` with
`EOPNOTSUPP` (real pre-4.17 kernels *ignored* unknown mmap flags; WSL1 rejects). qemu ≥ 8 probes
guest_base with that flag and reads every probe as "in use" → unusable under WSL1. **qemu 7.2
(bookworm) parses `/proc/self/maps` instead and works.** Bootstrap (idempotent, wired into the matrix
gate): `dpkg -x` (NOT install) `qemu-user 7.2` + `libcapstone4` into `/opt/q72` + 4 trixie runtime libs
via apt; debs cached in `COMPILED/_hostcache/`. Diagnosis chain that found it: perl raw-syscall mmap
probe (EOPNOTSUPP confirmed) → strace of both qemu versions.

### Γ4/Σ0 — the self-carrying spore (`run_germinate.sh`)
**Σ0 = ONE deterministic tar (`--sort=name --mtime=@0 --mode=a+rx,u+w`, pack-twice byte-identical;
spore identity = sha256).** Members (120): the 97-line anchor SOURCE; every program's RAW SVIR;
BOTH translator SVIRs (`elfw.svbin`, `a64w.svbin`); win64 germs (verify/dump/emit ×3 ISAs/toolchain =
sovas+sovlink+crt0); **Linux-native regrowth germs for BOTH ISAs**; the parent's per-host binaries
(DDC references); the rc+fact oracle; and `germinate.sh` itself — the spore carries its own protocol.

**Germination is falsifiable regrowth on VIRGIN prefixes** (no repo, no gcc, no node, no iiis-2;
the win leg runs under `env -i PATH=/usr/bin:/bin`):
- WIN prefix: integrity → anchor re-accepts 10/10 → svir-DDC 10/10 → **REGROWS 30/30 per-host binaries
  byte-identical to parent** → executes at oracle.
- LINUX prefix (delivery copy is the only `/mnt/c` touch): integrity → carried sysv 10/10 + a64 10/10
  at oracle → **L4: REGROWS 20/20 target binaries (x86-64 AND AArch64) ON LINUX from waist-translator
  germs — zero Windows, zero PE toolchain** → a Linux-regrown AArch64 binary runs at oracle under qemu.
- Falsifiers: (A) flipped spore member byte → integrity reds; (B) flipped parent binary, integrity
  SKIPPED → byte-DDC reds (hash-independent teeth); (C) pack-reproducibility.

### Γ3 — RETARGETING CLOSURE (`svir_elf_w.iii`, `svir_arm64_w.iii`, `svir_compose.iii`; gate = `run_retarget.sh`)
**The translators are now waist objects.** Each was transcribed into the iiisv subset (decimal/hex
opcode arithmetic, INP[] linear-memory input, svir_putc output, memory contract: PLEN_ at mem[16..23],
INP at mem[24..)) and compiles .iii→SVIR→anchor: **svir_elf_w = 12,119 B, svir_arm64_w = 12,587 B of
ANCHOR-ACCEPTED SVIR.** `svir_compose` fuses translator-SVIR + program-SVIR (as the data segment) into
ONE runnable module. Gates, all green:
- **T2 byte-match law: 20/20** — waist-route emission (module run on the win64 PE route) is
  BYTE-IDENTICAL to the native emitters, both ISAs, all 10 programs.
- **T4 fixpoint:** `translator(translator+sum) == native(translator+sum)` byte-exact (45,145 B), and
  the self-translated **Linux germ ran on Linux and re-emitted sum's ELF byte-identically**.
- **A6 cross-ISA germ:** an x86-64 Linux ELF that REGROWS AArch64 binaries on Linux, byte-identical,
  and the regrown a64 binary runs at oracle under qemu. *Toolchain-for-ISA-B carried as SVIR, regrown
  on ISA-A, no ARM hardware, no foreign toolchain.*
- T5 teeth: flipped input byte → different emission.

### iiisv frontend growth (additive, PROVEN: regenerated GEN modules byte-identical before/after)
hex literals (`0x…`); `[u64; N]` arrays (×8 scaling, LOAD64/STORE64, 8-aligned bases); module scalar
`var NAME : T = 0` → 8-byte memory cells; `svir_putc(e)` builtin (PRINT_CHAR + call-shaped depth);
flat-scope `let` re-declaration binds the same slot; bare `return` before `}` = `return 0` (was: ate
the `}` and emitted a value-less RETURN → anchor underflow rc=8 — found via per-fn `_vprobe.iii`);
buffers SRC 256K / TK 32K / MOD 128K / BODY 32K.

### Sovereign assembler: the silent-truncation class KILLED (`sovas.iii`, `sovas_main.iii`)
Found in the binary (objdump): PE `.data` capped at 0xFFFFF — `sov_data_emit` silently dropped bytes
past 1 MiB (history: same class at 8 KiB ate seed tables; at 1 MiB ate the 4 MiB svir_mem `.zero`
tail → composed-translator PEs segfaulted at table offsets past 1 MiB). Fix: DATA/RODATA buffers →
**4 MiB + slack (the SVIR memory-model max)** AND **overflow is now LOUD** — `SOV_OVF` flag on every
sink (text/data/rodata), `sovas_main` exits 5 instead of emitting a truncated object. Proven both
arms: `.zero 5000000` → rc=5, no object; `.zero 4194215` → rc=0, 4,194,446-byte object. Full
three-gate regression after rebuild: matrix rc=0, retarget rc=0, germinate rc=0.

## 2. New capabilities (none existed this morning)
1. III programs run natively on a second ISA (AArch64) through a one-stage sovereign translator.
2. III exists as a single reproducible artifact that regrows and re-verifies itself on virgin
   prefixes on two OSes — the release form.
3. A host's retargeting toolchain travels as ~12.5 KB of anchor-verified SVIR and regrows ON that
   host (including cross-ISA), answering trusting-trust at the host level with byte-exact fixpoints.
4. The sovereign assembler can carry a full 4 MiB svir_mem image and can no longer truncate silently.

## 3. Environment traps recorded (for the standing ledger)
- qemu ≥ 8 unusable under WSL1 (MAP_FIXED_NOREPLACE → EOPNOTSUPP → "in use"); qemu 7.2 works.
- qemu-user enforces the execute bit like execve: files extracted by tar as 0644 or created by shell
  redirect need chmod +x on lxfs (drvfs fakes 0777 and masks the class).
- `wsl.exe` writes at offset 0 of a shared redirected handle, clobbering earlier bash output —
  give WSL legs their own capture file and `cat` it.
- MSYS tar records no x-bit for `.elf` files; force `--mode=a+rx,u+w` in deterministic tars.

## 4. Standing frontier (unchanged by this session, next in the queue)
Γ0/Λ0 S4: parse.c error-recording corruption when main.c is the entry TU (`III-LAMBDA0-LINK-CAMPAIGN.md`)
→ run_completion 8/8. Γ1 body-onto-waist at corpus scale; Γ2b wasm first-class at corpus scale;
Γ5 evergreen extension (germinate + retarget wired into run_evergreen).
