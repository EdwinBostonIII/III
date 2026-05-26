# KATABASIS Gate `.sys` — Emission & Deploy Audit (CRASH-PROTOCOL Phase 1)

Status: **EVIDENCE COMPLETE.** No `.iii`/`.c` edits made during evidence gathering.
Date: 2026-05-23. Toolchain probed live, not assumed.

This is the Phase-1 (EVIDENCE) artifact mandated by the CRASH DEBUGGING PROTOCOL,
adapted to a *construction* (not post-crash) audit: read every line of the
emission→assemble→link path, prove every claim in emitted output, write findings
**before** touching any source.

---

## 0. Toolchain (probed)

| Tool | Version | Role |
|------|---------|------|
| `gcc` | 15.2.0 (x86_64-posix-seh, MinGW-Builds) | assembler frontend (`-c -x assembler`) + linker driver |
| `ld` | GNU binutils 2.45 | PE32+ linker (via gcc) |
| `objdump` | GNU binutils 2.45 | disassembly / PE inspection |
| `COMPILED/iiis-2.exe` | 2026-05-23 06:20 | the self-hosted III compiler (cg_r0 path) |

NIH check: ADR-021 (`emit.iii:9`) explicitly permits `gcc/ld/objcopy/objdump` on the
host side. Using them to assemble/link is **within** the III NIH floor. No third-party
libraries are linked into the driver (`-nostdlib`).

iiis-2 CLI: `--ring R0 | --out P | --emit-asm-only | --compile-only | --link | --print-mhash`.
`--emit-asm-only --out X` writes `X.s`. `--compile-only` writes the `.o`.

---

## 1. What cg_r0 emits (read in full: `COMPILER/BOOT/cg_r0.iii`, 1079 lines)

Per `iii_cg_r0_emit_module` (cg_r0.iii:1025):
1. Header comments + `.att_syntax`.
2. String pool → `.rdata,"dr"`.
3. Pass 1: harvest `@irp_handler` cycles.
4. Pass 2: emit each R0-eligible fn/cycle/sealed via `r0_emit_function`.
5. `r0_emit_irp_dispatch_table` → 28-entry `_iii_IrpDispatchTable` in `.rdata`,
   plus a self-defined `_iii_IrpNotImplemented` (`movabsq $0xC00000BB,%rax; retq`).

`r0_emit_function` (cg_r0.iii:884) per function:
- section select (`INIT` for `@entry`, `PAGE` for `@paged`, else `.text`);
- `.global L_p_<name>` (+ `DriverEntry` alias if `@entry`/named `driver_entry`);
- SEH prologue: `push %rbp; .seh_pushreg; mov %rsp,%rbp; sub $1024,%rsp; .seh_stackalloc 1024; .seh_endprologue`;
- **witness ENTER**: `movq $1,%rcx; subq $32,%rsp; callq iii_witness_emit_kernel; addq $32,%rsp`;
- param spill (first 4 → `-(slot+1)*8(%rbp)`);
- body;
- fall-through return `movabsq $0x0,%rax` (STATUS_SUCCESS) **or** explicit `return`;
- **witness EXIT**: `pushq %rax; movq $2,%rcx; subq $32,%rsp; callq iii_witness_emit_kernel; addq $32,%rsp; popq %rax`;
- epilogue `mov %rbp,%rsp; pop %rbp; retq`; `.seh_endproc`.

DriverEntry contract (D1): an `@entry` fn or fn named `driver_entry` is REJECTED
(`R0_E_SIG_MISMATCH`) unless it has exactly 2 params. Verified emitted as both
`L_p_driver_entry:` and `DriverEntry:` (`_probe/t_param.s.s:6-9`).

### External-symbol dependency set of an emitted driver
For a function that uses **no** parameters and **no** indexed stores, the ENTIRE set of
symbols the emitted `.o` references but does not define is:

> **`iii_witness_emit_kernel`** — and nothing else.

`_iii_IrpDispatchTable` / `_iii_IrpNotImplemented` are self-defined; `DriverEntry` is the
entry; there are **no** ntoskrnl imports, **no** CRT. (Confirmed in `_probe/t_param.s.s`.)

---

## 2. PROVEN codegen defects (emitted asm cited; emit-only, no edits)

### BUG-1 — param-0 clobber (CONFIRMED)
`_probe/t_param.iii`: `fn driver_entry(drv:u64,reg:u64)->u64 { return drv }`
emits (`_probe/t_param.s.s`):
```
18:  movq $1, %rcx        /* IIIW_ENTER — overwrites rcx == param0 (drv) */
19:  subq $32, %rsp
20:  callq iii_witness_emit_kernel
21:  addq $32, %rsp
22:  movq %rcx, -8(%rbp)   /* spills 1 (not drv) into slot0 */
23:  movq %rdx, -16(%rbp)  /* param1 survives only if witness preserves rdx */
24:  movq -8(%rbp), %rax   /* `return drv` returns 1, NOT the DriverObject */
```
Root cause: witness ENTER is emitted (cg_r0.iii:911-915) **before** the param-spill loop
(cg_r0.iii:916-936); the loop reads `%rcx` as param0 after it was repurposed for the
IIIW_ENTER code. **Fix:** move param spill to *before* the witness ENTER emission.
(This also relaxes the witness contract: params are on the stack before the call.)

### BUG-2 — witness-EXIT 16-byte misalignment (CONFIRMED)
`_probe/t_param.s.s:27-30`: a single `pushq %rax` precedes `subq $32,%rsp; callq`,
so the EXIT call enters at `rsp%16==0` (MS x64 wants `==8`). Harmless for a **leaf**
witness (no SSE, no nested call); a latent bugcheck for any real callee using aligned SSE.
**Fix:** preserve the return value across the EXIT call with an even number of 8-byte
pushes (push twice / pop twice) — restoring alignment. ENTER is already correct.

### BUG-3 — indexed store miscompile + scratch/slot-0 aliasing (CONFIRMED)
`_probe/t_index.iii`: `fn store2(p:u64,v:u64)->u64 { p[1u64]=v; return 0u64 }`
emits (`_probe/t_index.s.s:25-33`):
```
25:  movq %rax, -8(%rbp)        /* save val; -8(%rbp) ALIASES local slot 0 (param p) */
26:  movq -8(%rbp), %rax        /* emit obj(p): slot0 already overwritten by val */
...
32:  movq -8(%rbp), %rax        /* reload scratch (=v) into base reg */
33:  movq %rdx, (%rax,%rcx,8)   /* store %rdx (unset) to [v + 1*8] */
```
Three compounding faults (cg_r0.iii:778-785): the hard-coded `-8(%rbp)` scratch aliases
local slot 0; `obj` is reloaded as the saved value; the store uses `%rdx` which was never
loaded with the value. **Fix:** use a scratch slot that cannot alias a local (e.g. a
reserved high frame offset), load the value into the register the store actually uses,
and order obj/idx/val so none clobbers another.

---

## 3. Gaps in the link/emit surround (not codegen bugs)

- **GAP-4 — no entry flag.** `LF_PE_SYS` (`emit.iii`) = `-shared -nostdlib -Wl,--subsystem,native`
  but never sets `-Wl,-e,DriverEntry`. A correct driver link must add it (else ld defaults
  the entry to start-of-`.text`). The manual build path below sets it explicitly.
- **GAP-5 — module-level `var` data not emitted.** `iii_cg_r0_emit_module` emits string pool +
  functions + IRP table only; module-scope `var ARR:[...]` is referenced (`leaq L_p_ARR(%rip)`)
  but never defined → undefined symbol at link. Tier-2 logic needing globals must account for this.
- **GAP-6 — DriverEntry does not install the dispatch table.** `cg_r0.h` D2 describes
  `DriverObject->MajorFunction[i] = _iii_IrpDispatchTable[i]`, but the `.iii` port emits the
  table without an install loop. Irrelevant to a minimal driver; required for a real I/O driver.

---

## 4. Strategy — two tiers (honest scope)

### Tier 1 — minimal self-unloading Gate `.sys` (DEPLOYABLE NOW, current iiis-2)
A `driver_entry(PDRIVER_OBJECT, PUNICODE_STRING)` that ignores its params and returns a
**custom error NTSTATUS** (`0xE0000001`, customer-defined). Properties:
- Uses no parameters and no indexed stores ⇒ **none** of BUG-1/2/3 affect correctness.
- Exercises the full emitted path: SEH prologue, witness ENTER, body, witness EXIT, epilogue.
- The one external symbol `iii_witness_emit_kernel` is satisfied by a hand-written **bare-`ret`
  leaf** (preserves all registers, IRQL-safe, no CRT, no imports) — exit-misalign is harmless.
- Returns an error ⇒ Windows **immediately unloads** the driver after DriverEntry (no resident
  code, no DriverUnload needed, no reboot). The specific status proves DriverEntry executed.
- **Safety:** service created `type=kernel start=demand` — never auto/boot-loaded, so a
  worst-case bugcheck is recoverable by a single reboot (no boot loop). System Restore point first.

This is the foundational milestone of the descent's *emission* path: proof the III toolchain
produces a loadable, executing Ring-0 image from `.iii`. It is a **complete, correct** artifact —
not a stub — for exactly that purpose.

### Tier 2 — resident gate driver running `katabasis_gate_admit` in Ring 0 (SUBSEQUENT)
Requires, in order: (a) fix BUG-1/2/3 in cg_r0 (+ rebuild iiis-2, determinism gate, corpus);
(b) GAP-4 entry flag (have it); (c) a full **kernel-safety dependency-closure audit** of the
katabasis modules + their `omnia`/hexad deps (today implemented partly in C/libiii_native for
user mode — must be proven pure-`.iii` and kernel-safe, or ported, before any Ring-0 link);
(d) set `DriverObject->DriverUnload` (needs BUG-1 fix); (e) disassemble-verify; (f) gated load.
**"The descent is successful" is NOT claimed until a real gate `.sys` loads and runs.**

---

## 5. Verification gates (every step proven before the next)
1. Emitted `.s` read for every driver function.
2. `.o` disassembled (`objdump -d`) — machine code matches intent; SEH present.
3. `.sys` PE inspected (`objdump -x`): `IMAGE_SUBSYSTEM_NATIVE`, `AddressOfEntryPoint`→DriverEntry,
   `.reloc` present, **zero** imports, no CRT.
4. Witness leaf disassembled — confirmed a true `ret`, register-preserving.
5. Sign+deploy script: System Restore point → self-signed test cert (trusted Root+TrustedPublisher)
   → `Set-AuthenticodeSignature` → PE-checksum repair → `sc create type=kernel start=demand` →
   operator UAC-accepts → `sc start` → interpret status → `sc delete`. Boot-safe throughout.

---

## 6. RESULTS — Tier-1 VERIFIED & DEPLOY-READY (Phase 2/3 complete)

Build: `KATABASIS-DEPLOY/build_gate_sys.sh` (deterministic). Artifacts in `KATABASIS-DEPLOY/`.

| Property | Evidence | Verdict |
|----------|----------|---------|
| Entry == DriverEntry | `objdump -f` start `0x140001000` == `.text` base; raw `AddressOfEntryPoint` RVA `0x1000`+ImageBase | PASS |
| PE32+ / NT-native | `Magic 020b`, `Subsystem 1` (objdump -p + raw header) | PASS |
| DriverEntry code correct | `objdump -d`: prologue → witness ENTER `call …1060` → `movabs $0xc00000bb,%rax` → witness EXIT `call …1060` → balanced epilogue → `ret` | PASS |
| Witness leaf safe | `iii_witness_emit_kernel @ …1060` = single `c3 ret`, touches nothing, register-preserving | PASS |
| Calls resolve internally | both witness calls are `e8` rel-calls to `…1060`; no import thunk | PASS |
| No imports / exports / CRT | `objdump -p` "DLL Name" empty; `.edata` absent; `.idata` null terminator only | PASS |
| Relocatable | `HAS_RELOC`, `.reloc` 0x40 present | PASS |
| PE checksum valid | `ld`=`0x2080`, independent recompute=`0x2080` (match → fixer proven) | PASS |
| Deterministic | rebuild → identical `sha256 12a7730c…6aab0` | PASS |

Deploy: `KATABASIS-DEPLOY/sign_and_deploy.ps1` — PARSE OK; all cmdlets/tools present
(`New-SelfSignedCertificate`, `Set-AuthenticodeSignature`, `Import/Export-Certificate`,
`Checkpoint-Computer`, `Get-WinEvent`, `sc.exe`, `bcdedit.exe`); checksum-fixer reproduces
`ld`'s value. Pins the known-good hash before signing; signs a copy; `start=demand` (boot-safe);
self-cleaning; `-Uninstall` teardown.

**Expected on the operator's UAC-accepted run:** `sc start` fails with **Win32 error 50**
(ERROR_NOT_SUPPORTED) ⇒ DriverEntry executed in Ring 0 and returned STATUS_NOT_SUPPORTED;
the toolchain produced a kernel image that LOADED and RAN without bugcheck; driver auto-unloaded.
(Load-rejection would instead give 193/577/1275 — distinguishable.)

**NOT YET CLAIMED:** "the descent is successful" — that awaits the operator's load result AND
Tier-2 (resident gate logic). Tier-1 proves the *emission/load* path only.

## 7. cg_r0 codegen fixes — DONE & VERIFIED (Task 4)
BUG-1/2/3 fixed in `cg_r0.iii` (BUG-1/2 also mirrored in `cg_r0.c` for source fidelity; BUG-3
was already correct in C). Rebuilt iiis-2 (mhash `d74b064f…`, deterministic). Proven in machine code:
- **BUG-1**: `mov %rcx,-0x8(%rbp); mov %rdx,-0x10(%rbp)` now PRECEDE `mov $0x1,%rcx` → `return drv`
  returns the real DriverObject, not `1`.
- **BUG-2**: witness EXIT uses two `push %rax` / two `pop %rax` → call lands at `rsp%16==8` (ABI).
- **BUG-3**: `p[i]=v` → `push val; obj→rax; idx→push; pop rcx(idx),rax(obj),rdx(val);
  movq %rdx,(%rax,%rcx,8)` — no slot-0-aliasing scratch, no unset `%rdx`.

Gates: STDLIB corpus **330/0**; stage1 equivalence iiis-1≡iiis-2 **57/0**.

Tier-1 `gate.sys` rebuilt from the fixed compiler and re-verified — **deterministic hash
`63ba66291f75882d69b2a5db46d69240b61327ef4be6fd39840f83589d6107cc`** (`TimeDateStamp` pinned to 0
via `--no-insert-timestamp` after the determinism check caught a per-link timestamp; deploy script
re-pinned + re-parsed; checksum-fixer re-validated `ld==computed==0x359c`).

Noted residual `.iii`/`.c` divergence (gate-invisible — no R0 in stage1_corpus; module globals
not emitted): cg_r0.iii omits the C's D13 `.if/.warning`, D14 `mfence/sfence`, and FIELD-assign
branch. Documented for a later faithful reconciliation pass; none affects Tier-1 or the proven bugs.

## 8. Remaining: Tier-2 (resident gate logic running in Ring 0)
- Kernel-safety dependency-closure audit of the katabasis modules + omnia/hexad deps before any
  Ring-0 link (today partly C/libiii_native for user mode; must be proven pure-`.iii` + kernel-safe
  or ported).
- Set `DriverObject->DriverUnload` (now feasible: BUG-1/3 fixed) for a cleanly-unloadable resident driver.
- **"The descent is successful" is claimed only when a real gate `.sys` loads and runs** — Tier-1
  proves the emission/load path; Tier-2 proves the decision logic in-kernel.

## 9. Tier-1 PROVEN ON METAL + Tier-2 kernel-safety audit (2026-05-23)

**Tier-1 loaded and executed in Ring 0** on the operator's machine (UAC-accepted run). Corroborated
three independent ways: SCM **Event 7000** = "…failed to start … *The request is not supported*"
(= `STATUS_NOT_SUPPORTED`, our exact return); `sc start` **Win32 50**; service **self-deleted**
(nothing resident); `gate.signed.sys` **Authenticode = Valid**. ⇒ the III `.iii`→Ring-0
emission→load→execute→unload path works on real hardware, **no bugcheck**.

### Kernel-safety dependency-closure audit of `katabasis_gate_admit` — PURE `.iii`
Every `extern` in the closure is `from "*.iii"` (inter-module, MS x64 ABI), **not** C. The leaf deps
(hexad_algebra, hexad_reach, sha256, capability, content_addr, xii_term, cycle_family) have **no**
`from "*.c"` and **no** malloc/calloc/free/memcpy/memset/printf. **The gate logic needs zero
C-porting to be kernel-safe.**

Storage model: fixed module-level `var` **BSS** arrays + a **bump-allocator arena** (no heap):
`xii_term XII_TERM_ARENA [u8;32768]` + `XII_TERM_NEXT`; sha256 SHA_K/W/H/BUF (+lazy `SHA_INIT`);
hexad_reach `HXR_BITMAP[144]` (+lazy `HXR_INIT`); census `KCEN_FACTS[16]`; seal `KCS_BUF/TMP`;
content_addr + hexad_algebra scratch. All zero-init BSS, lazy-filled ⇒ **no ExAllocatePool**.

### Tier-2 blockers — all in the cg_r0 BACKEND (logic is ready)
- **GAP-5 (central):** cg_r0 emits NO module-level `var`/`const` data; the closure depends entirely
  on module BSS. Fix = **mirror cg_r3's data pass into cg_r0** (cg_r3 already emits module data —
  the user-mode corpus relies on it): uninit `var`→`.bss`, init `var=v`→`.data`, `const`→`.rdata`.
- **ntoskrnl imports:** a resident, R3-invokable gate needs `Io{Create,Delete}Device`,
  `Io{Create,Delete}SymbolicLink`, `IoCompleteRequest`, … cg_r0 emits no imports → needs an IAT path.
- **GAP-6:** install the IRP dispatch table + create the device in DriverEntry (IRP_MJ_DEVICE_CONTROL → admit).
- **DriverUnload** (now feasible: BUG-1/3 fixed) for clean unload.
- Stack budget: verify gate call-depth × 1024-byte frames < 12 KB kernel stack.

Tier-2 increment order: (1) cg_r0 module-data emission (GAP-5) + KAT; (2) cg_r0 ntoskrnl imports;
(3) `gate_driver.iii` Tier-2 (device + dispatch + unload + admit); (4) link the pure-`.iii` closure +
driver into a resident `.sys`; (5) disasm-verify; (6) gated load + R3 IOCTL exercise.

## 10. Tier-2 Inc-1 + Inc-2 DONE: the gate DECISION linked as a Ring-0 driver (2026-05-23)

cg_r0 backend brought to data-parity with cg_r3; the full pure-`.iii` gate-admit closure linked
into a resident driver. All cg_r0 changes: corpus **330/0**, equivalence **57/0**, deterministic iiis-2.

cg_r0 changes:
- **Inc-1 (GAP-5):** module-level `var`/`const` data emission (`.rodata`/`.data`/`.bss`; 8-byte-uniform
  `.quad`/`.zero count*8`) + global-ident binder dispatch (const/scalar-var → value-load `movq`;
  array/fn → address `leaq`). Verified in machine code (relocs: const→.rodata, array→.bss, var→.data).
- **r0_emit_hex signed-idiv fix:** `% 16`/`/ 16` (idiv → wrong for top-bit-set values; negative consts
  emitted as `0xV`) → `& 15`/`>> 4` (mirrors r3_emit_hex). `-1` now emits `0xffffffffffffffff`.
- **IRP table gated on driver_entry-present** (was unconditional): the driver module emits it (its 28
  `.quad` refs also give the `.sys` its `.reloc`); pure logic modules don't → no duplicate `_iii_IrpDispatchTable`.

`KATABASIS-DEPLOY/build/gate_resident.sys` — 18-module gate-admit closure (hexad_algebra/reach,
xii_term, sha256/keccak256/keccak/content_addr, capability, svm/bar_layout, cycle_family/admit/term,
seal, caps, gate_verdict, gate, admit) + driver + witness leaf → PE32+ NT-native driver. **Verified:**
entry==DriverEntry, **deterministic `sha256 55f17f43…`**, PE checksum valid (`0x10c11`), `.reloc` present,
**ZERO imports** (no ntoskrnl/CRT), `.bss` 284 KB (the bump arena), **max call depth 6 frames ≈ 6.2 KB
≪ 12 KB** kernel stack (no recursion). `verify_gate_resident.sh` 10/10.

DriverEntry runs the 4-case gate selftest (corpus 609) **in Ring 0** and returns `0xC00000BB`
(sc-start Win32 **error 50**) iff all four verdicts (OK/REJECT_SEAL/REJECT_CAP/REJECT_HEXAD) are
correct ⇒ the gate **decision** verified executing in-kernel. Self-cleaning. Deploy:
`sign_and_deploy.ps1` (re-pinned to `55f17f43`); `build_gate_resident.sh`; `verify_gate_resident.sh`.

## 11. NEXT (after the operator validates gate_resident on metal): R3-invokable IOCTL gate
ntoskrnl imports (`Io{Create,Delete}Device`/`SymbolicLink`, `IoCompleteRequest`) + device +
`IRP_MJ_DEVICE_CONTROL` dispatch + `DriverUnload`, so R3 queries the gate via `DeviceIoControl`.
**Rationally gated on the gate_resident on-metal result** — it validates cg_r0 compiles the gate
logic correctly in-kernel before the IOCTL layer is built atop it (no building on an unvalidated base).
