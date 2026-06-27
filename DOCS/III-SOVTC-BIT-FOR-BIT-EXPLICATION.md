# III SOVTC — Bit-for-Bit Exhaustive Explication

> **What this document is.** A file-by-file, byte-level account of every one of the **53 files** in
> `STDLIB/sovtc/` — III's *sovereign toolchain*: the subsystem that takes the AT&T-syntax assembly
> emitted by III's own compiler (`iiis-2` / `cg_r3`) and turns it into native Windows machine code,
> COFF `.o` objects, and PE32+ `.exe` executables **with zero external tools** (no `gcc`, no `ld`,
> no `gas`), then *proves* it self-hosts byte-identically.
>
> It is written to be exhaustive: where a file constructs machine-code bytes, COFF header fields, or
> PE header fields, the exact byte values, their bit decomposition, and *why* each is what it is are
> spelled out and cross-checked against the canonical expected byte arrays in the `test_*.iii` files
> and the magic-number assertions in the gate scripts. Nothing byte-level is asserted from memory
> where the repo pins it.

---

## 0. Reading conventions (fixed once, used in all 53 sections)

**Hex bytes.** Machine-code and header bytes are written as two-hex-digit values, space-separated,
low address first (the order they appear in the file/stream): `48 89 e5`. Where a value is
little-endian multi-byte (the normal case for x86-64 displacements/immediates and for COFF/PE
fields), I give the *stored* byte order and, when useful, the logical value: `90 01 00 00` = LE
`0x00000190` = 400.

**x86-64 instruction layout.** A long-mode integer instruction is decoded in this fixed field order,
and I decompose it the same way every time:

```
[legacy prefixes] [REX] [opcode] [ModRM] [SIB] [displacement] [immediate]
```

- **REX** = `0100 WRXB` (high nibble always `4`). `W`=1 → 64-bit operand size; `R` = high bit of the
  ModRM.reg field; `X` = high bit of the SIB.index field; `B` = high bit of ModRM.rm / SIB.base /
  opcode-embedded reg. So `48` = REX.W only; `4C` = REX.W+R; `49` = REX.W+B; `4D` = REX.W+R+B.
- **ModRM** = `mod(2) reg(3) rm(3)`, written as the byte and decomposed `mod=__ reg=__ rm=__`.
  `mod=11` register-direct; `mod=00/01/10` memory with 0/disp8/disp32 (rm=100 means "SIB follows",
  rm=101 with mod=00 means RIP-relative disp32).
- **SIB** = `scale(2) index(3) base(3)`; effective address = base + index·2^scale + disp.
- Register numbering (low 3 bits; the 4th bit is the REX extension): `rax=0 rcx=1 rdx=2 rbx=3
  rsp=4 rbp=5 rsi=6 rdi=7`, `r8..r15 = 8..15`.

**COFF / PE fields.** Given as `offset: bytes → value (meaning)`. All multi-byte integers in COFF and
PE are little-endian. The two magics this toolchain pins are reused throughout:
- `64 86` = `IMAGE_FILE_MACHINE_AMD64` (0x8664 LE) — the first two bytes of every COFF object `sovcoff`
  emits, and the gate's proof that a driver wrote a real object to stdout.
- `4d 5a` = ASCII `"MZ"` — the DOS-header magic that begins every PE; the gate's proof that `sovld`
  wrote a real PE to stdout.

**Exit code 99.** Every runnable artifact in this subsystem signals success by exiting **99**
(`rc == 99`). This is the III house convention; a test that "passes" is one whose process exit code
is exactly 99. (8-bit truncated — see the `boot1` arithmetic: 90+9+10 = 109, and 109 is the *checked
total*, not the exit code; the program returns 99 only when that total is correct.)

**`.iii` source facts referenced.** `@export` marks a symbol visible to the linker; `extern
@abi(c-msvc-x64) fn … from "lib"` declares an imported function with the Microsoft x64 calling
convention; `var X : [T; N]` is a module-level array (lands in `.data`/`.bss`); `metal { … }` blocks
(where they appear) emit literal bytes. These are the III-language primitives the toolchain is both
*written in* and *processes*.

---

## Dependency-ordered file map (the order of the 53 sections below)

1. **Orchestration (gates)** — `run_sovtc.sh`, `run_sovboot.sh`, `run_fixpoint.sh`
2. **Runtime foundation** — `crt0.iii`
3. **Core library (the "big four")** — `sovparse.iii`, `sovas.iii`, `sovcoff.iii`, `sovld.iii`
4. **Front-end mains / link helpers** — `sovas_main.iii`, `sovld_main.iii`, `sovlink_main.iii`,
   `sovlink_probe.iii`, `linklib.iii`, `linkmain.iii`
5. **Bootstrap programs** — `boot1.iii` … `boot8.iii`
6. **COFF driver programs** — `sov_drive.iii` … `sov_drive7.iii`
7. **PE/linker driver programs** — `sov_drivel.iii` … `sov_drivel8.iii`
8. **Encoder unit tests** — `test_*.iii` (16)

The order is bottom-up by dependency: the gates define *what correctness means*; `crt0` is the
runtime everything links against; the big four are the engine; the mains wrap the engine as file CLIs;
the boot/driver/test programs are inputs that pin behavior. Reading the byte-constructing source
(`sovas`/`sovcoff`/`sovld`) *is* the bit-for-bit explanation; the `test_*` expected arrays verify it.

---

# GROUP 1 — ORCHESTRATION (THE GATES)

These three Bash scripts are not part of the shipped toolchain; they are its *definition of correct*.
They never appear in the link line of any artifact. They exist to run the toolchain against inputs and
assert, byte-for-byte, that the output matches an independent reference (`gas`/`gcc`/the OS loader).
Reading them first fixes the meaning of every "PASS" the rest of the system is built to earn.

---

## File 1 of 53 — `run_sovtc.sh` (5105 bytes) — the unit/integration gate

**Role.** The decoupled self-test gate for the toolchain *as a library linked into test drivers*. It
runs three escalating tiers: (A) 15 pure-encoder unit tests, (B) 7 COFF "emit a real `.o`, gcc links
it, the OS runs it" tests, (C) 8 `sovld` "lay out a real PE32+, the OS loads+runs it, no gcc/ld" tests.

**Why it is *not* a corpus test (lines 2–9).** The header comment states the architectural reason: the
toolchain's test exes link `sovas.o` + `sovparse.o` **directly on the `gcc` command line**, not through
the stdlib archive `libiii_native.a`. `STDLIB/corpus/`'s runner (`run_corpus.sh`) FATALs on any test
lacking an `EXPECTED` entry and assigns sequential corpus numbers; a meta-tool with a bespoke link
requirement would both fail that contract and contend for corpus numbers with other tracks. So this
runner is a standalone gate. Success convention: **each test exits 99; overall exit 0 = all pass.**

**Preamble (lines 10–16).**
- `set -uo pipefail` — `-u` unset-variable is an error; `-o pipefail` a pipeline fails if any stage
  fails. (Note: no `-e`; the script manages failures explicitly via the `fail` flag so it can run
  *all* tests and report every failure rather than aborting on the first.)
- `ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"` — resolves the III repo root two levels
  above `sovtc/` (i.e. `…/III`).
- `IIIS="$ROOT/COMPILED/iiis-2.exe"` — the **pinned in-tree compiler**. (A standing project hazard is
  an autodiscovered stale `iiis`; pinning the exact path avoids the phantom-regression trap.)
- `ARCH="$ROOT/STDLIB/build/iii/libiii_native.a"` — the III native stdlib archive that the toolchain
  modules call into (string/memory/io primitives).
- `SOVTC` = the source dir; `OUT="$ROOT/STDLIB/build/sovtc"` = scratch output, `mkdir -p`'d.

**Compile the engine once (lines 18–19).** `iiis-2 sovas.iii --compile-only --out sovas.o` and likewise
`sovparse.iii`. `--compile-only` stops at the object file (no link). A failure here is FATAL (`exit 2`)
because nothing downstream can run without the engine. These two `.o` are reused by every test below.

**Tier A — encoder unit tests (lines 21–27).** `fail=0`, then a `for t in …` over 15 names:
`test_encode test_spine test_reloc test_store test_lea test_unknown test_call test_cmp test_branch
test_sibcall test_sib test_sib_disp test_movzx_sib test_relax_back test_relax_cascade`. For each:
1. `iiis-2 $t.iii --compile-only --out $t.o` — compile the test; failure → `FAIL $t (compile)`,
   set `fail=1`, `continue`.
2. `gcc $t.o sovas.o sovparse.o $ARCH -lws2_32 -lkernel32 -o $t.exe` — link the test object against the
   engine objects, the stdlib archive, and the two Windows import libs (Winsock + kernel32). Failure →
   `FAIL $t (link)`. **This is the "direct on the line" link the header comment referred to.**
3. `timeout 25 $t.exe; rc=$?` — run with a 25-second wall cap (Defender's exec-scan can stall a fresh
   exe; the cap is a known env workaround). `rc==99` → `PASS`, else `FAIL $t (exit $rc)`.

These tests never touch COFF/PE; they call into `sovas` directly, encode a hand-specified instruction,
and `assert` the produced bytes equal a literal expected array (the canonical byte ground-truth — see
Group 8). Exit 99 means every assertion held.

**Tier B — COFF "links-and-runs" gates (lines 29–42).** First compile `sovcoff.iii → sovcoff.o`
(failure flagged, not fatal). Then loop over 7 colon-encoded triples
`SRC:EXE:LBL` —
`sov_drive:drive:text-only`, `sov_drive2:drive2:reloc-data`, `sov_drive3:drive3:extern-call`,
`sov_drive4:drive4:rodata`, `sov_drive5:drive5:bss`, `sov_drive6:drive6:longname`,
`sov_drive7:drive7:movzbq`. The labels name *exactly which COFF feature* each driver exercises
(plain text section; a REL32 relocation into `.data`; an external call needing a symbol-table entry;
read-only data; uninitialized `.bss`; a >8-char section/symbol name needing the string table; a
`movzbq` byte-load encoding). Per driver:
1. compile `$SRC.iii → $SRC.o`;
2. `gcc $SRC.o sovas.o sovparse.o sovcoff.o $ARCH -lws2_32 -lkernel32 -o $EXE.exe` — note `sovcoff.o`
   is now on the line; the driver, when run, will *call `sovcoff` to emit a COFF object to stdout*;
3. `timeout 25 $EXE.exe > $EXE.o` — **run the driver, capturing its stdout into a file named `$EXE.o`.**
   The driver's whole job is to print a COFF object;
4. `magic=$(od -An -tx1 -N2 $EXE.o | tr -d ' \n')` — read the first **two bytes** as hex; assert
   `magic == "6486"`. That is `64 86` = `IMAGE_FILE_MACHINE_AMD64` — the proof the stdout is a real
   AMD64 COFF object *and* that stdout wasn't polluted by stray prints. A mismatch → FAIL with the
   actual magic reported;
5. `gcc $EXE.o -o $EXE-run.exe` — **hand the sovereign-emitted `.o` to gcc's `ld`**; if gcc can link
   it, the object is structurally valid;
6. `timeout 10 $EXE-run.exe; rc=$?` — run it; `rc==99` → PASS `coff/$LBL`. So Tier B proves: *III's
   own COFF writer produces objects a real system linker accepts and the OS executes correctly.*

**Tier C — `sovld` PE gates (lines 44–56).** Compile `sovld.iii → sovld.o`. Loop over 8 triples:
`sov_drivel:lpe:ret-only`, `…2:lpe2:data-global`, `…3:lpe3:import`, `…4:lpe4:import2`,
`…5:lpe5:multidll`, `…6:lpe6:msvcrt-only`, `…7:lpe7:relax`, `…8:lpe8:dlltable`. Labels enumerate the
PE features: a single-`.text` ret-only image; a `.data` global with an applied internal REL32; one
imported function; two imports; imports from multiple DLLs; imports from msvcrt only; branch
relaxation; and the DLL import-directory table. Per driver:
1. compile `$SRC.iii`;
2. `gcc $SRC.o sovas.o sovparse.o sovld.o $ARCH … -o $EXE-drv.exe` — note `sovld.o` (not `sovcoff.o`)
   on the line; the driver, when run, *lays out a whole PE32+ image to stdout*;
3. `timeout 25 $EXE-drv.exe > $EXE.exe` — run the driver; **its stdout IS the final `.exe`**;
4. `pemagic=$(od … -N2 …)`; assert `== "4d5a"` (ASCII `MZ`) — the DOS header magic that begins every
   PE. Proof the driver wrote a real PE and stdout is clean;
5. `timeout 10 $EXE.exe; rc=$?` — **the OS loader loads and runs the sovereign PE directly**; `rc==99`
   → PASS `ld/$LBL (sovereign PE32+ -- no gcc/ld -- loads+runs)`. Tier C is the strongest claim: an
   executable built end-to-end by III, accepted by the Windows loader itself.

**Verdict (lines 58–59).** `fail==0` → print `ALL PASS`, `exit 0`; else `FAILURES PRESENT`, `exit 1`.

**Cross-file role.** This file is the contract that `sovas` (Tier A bytes), `sovcoff` (Tier B magic
`64 86` + linkable object), and `sovld` (Tier C magic `4d 5a` + loadable image) are all written to
satisfy. The `EXE.o`/`EXE.exe` filename reuse (a driver named `drive` writes `drive.o`; a driver named
`lpe` writes `lpe.exe`) is the tell that *the driver's stdout is the artifact under test.*

---

## File 2 of 53 — `run_sovboot.sh` (3381 bytes) — the sovereign-bootstrap gate

**Role.** Where `run_sovtc.sh` unit-tests hand-embedded snippets, this gate drives **whole, real,
multi-function III programs** through III's own *file-driven* assembler (`sovas_main`) and
assembler+linker (`sovld_main`), and gates the result byte-differentially against `gas`. It is the
"does the toolchain work on actual compiler output" proof.

**The four-step pipeline per program (header, lines 2–11).** For each program `prog.iii`:
1. `iiis-2 prog.iii` → `prog.o.s` — real `cg_r3` assembly emission (AT&T text).
2. `sovas_main prog.o.s` → `prog_sov.o` — a sovereign COFF object whose **`.text` is required to be
   BYTE-IDENTICAL to gas's** assembly of the same `.s`.
3. gcc-link `prog_sov.o` and run → expect 99 (the sovereign `.o` is linkable and semantically correct).
4. `sovld_main prog.o.s` → `prog.exe`, run → expect 99 (a native PE, **no gcc/ld/gas anywhere**).
The header names the spine: *byte-differential vs gas* — a single wrong instruction byte reddens step 2
even if the program would have run. `boot1` is described as the u64 path (movq, sibling calls, data
reloc); `boot2` as the u32 path (movl, `movl disp(%rbp)`, `movl` SIB array access) — forms boot1 omits.

**Preamble (lines 12–18).** `set -u`; `ROOT` two levels up; `IIIS`, `SOV` (= sovtc), `OUT=
$ROOT/STDLIB/build/_sovboot`; `mkdir -p`; `fail=0`.

**Build the toolchain + the two file-driven tools (lines 20–25).** Loop compiles `sovas sovparse
sovcoff sovld sovas_main sovld_main` each to `$OUT/$m.o`. Then:
- `gcc sovas_main.o sovparse.o sovcoff.o sovas.o -lkernel32 -o sovas_main.exe` — the file-driven
  assembler: reads a `.s` path from argv, emits a COFF `.o` to stdout. Its link set is exactly
  {front-end, parser, coff-writer, encoder}.
- `gcc sovld_main.o sovld.o sovparse.o sovas.o -lkernel32 -o sovld_main.exe` — the file-driven
  assembler+linker: reads a `.s`, emits a PE to stdout. Link set {front-end, linker, parser, encoder}
  — note **no `sovcoff`**: `sovld` writes the PE image directly, it does not go through a COFF file.

**The per-program loop (lines 27–44)** over `boot1 … boot8`:
1. `iiis-2 $prog.iii --compile-only --out $prog.o` — this *also* leaves `$prog.o.s` next to it (the
   compiler's textual emission), captured as `S="$OUT/$prog.o.s"`.
2. **Step 2 — byte-differential `.o` (lines 30–35):**
   - `gcc -c -x assembler $S -o ${prog}_gcc.o` — gas assembles the same `.s` (reference).
   - `sovas_main.exe $S > ${prog}_sov.o` — III assembles it.
   - `objcopy -O binary --only-section=.text` extracts the raw `.text` of each into `_s.t` / `_g.t`.
   - `cmp -s _s.t _g.t` — if equal, `PASS $prog .text BYTE-IDENTICAL to gas (N bytes)`; else FAIL.
     **This is the literal bit-for-bit proof of the encoder.**
3. **Step 3 — sovereign `.o` links and runs (lines 36–39):** `gcc ${prog}_sov.o -lkernel32 -o
   ${prog}_sov.exe`; run; `rc==99` → PASS.
4. **Step 4 — full sovereign PE (lines 40–43):** `sovld_main.exe $S > $prog.exe`; run; `rc==99` →
   `PASS $prog.exe (SOVEREIGN PE -- no gcc/ld/gas) runs 99`.

**Verdict (lines 46–47).** `fail==0` → `ALL PASS` else `FAILURES`; `exit $fail`.

**Cross-file role.** This gate is why `boot1..boot8` exist and why each targets distinct codegen forms
(see Group 5): together they force `sovas` to encode every instruction shape `cg_r3` actually emits,
and the `cmp` against gas makes "I encoded it" mean "I encoded it *the same bytes* a 40-year-old
reference assembler does."

---

## File 3 of 53 — `run_fixpoint.sh` (4549 bytes) — the self-host fixpoint gate

**Role.** The capstone. It proves the toolchain reproduces **itself**: III's assembler and linker,
built once via gcc (the allowed one-time bootstrap), then used to rebuild working copies of themselves
with **no gcc/ld/gas in the loop**, and the second-generation tools come out **byte-identical** to the
first. This is the classic compiler self-hosting fixpoint, applied to an assembler+linker.

**The claim (header, lines 2–12).** Bootstrap is allowed exactly once: `iiis-2` compiles the toolchain
`.iii → .o` and gcc links *only the gen1 tools*. Everything below is sovereign. Two self-host loops:
- **ASSEMBLER self-host:** `sovlink(crt0 + sovas_main + sovparse + sovcoff + sovas)` = a gen2 `sovas`;
  gen2 must equal gen1 on **all 13 inputs** (its own 5 sources + `boot1..8`), byte-for-byte.
- **LINKER self-host:** `sovlink(crt0 + sovlink_main + sovld + sovparse + sovas)` = the sovereign
  linker; it must re-link `sovas` byte-identical to the gcc-linked gen1, and reproduce **itself**
  bit-for-bit (which also exercises `crt0`'s multi-argument command-line parse).

**Bootstrap (lines 22–27).** Compile `sovas sovparse sovcoff sovld sovas_main sovlink_main crt0` to
`.o`. Then gcc-link the two gen1 tools: `sovas_main.exe` (= {sovas_main, sovparse, sovcoff, sovas}) and
`sovlink_main.exe` (= {sovlink_main, sovld, sovparse, sovas}). **This is the only gcc invocation that
touches a tool; from here gcc is never used to build a tool again.**

**Sov-assemble every module, byte-gated (lines 29–36).** For each of `crt0 sovas_main sovparse sovcoff
sovas sovld sovlink_main`: `sovas_main.exe $m.o.s > ${m}_sov.o` (III assembles the tool's own
assembly), `gcc -c -x assembler $m.o.s -o ${m}_g.o` (gas reference), extract `.text` of each, `cmp`.
PASS = `sov-assemble $m .text == gas`. So the assembler is first proven correct on *its own source's
assembly* before being trusted to relink itself — the toolchain assembles the very bytes it is made of.

**Assembler self-host (lines 38–49).** `sovlink_main.exe crt0_sov.o sovas_main_sov.o sovparse_sov.o
sovcoff_sov.o sovas_sov.o > sovas_self.exe` — the gen2 assembler, built from sovereign objects by the
sovereign linker (crt0 first so its `cstart` is the entry). Then for each input `m` in {the 5 tool
sources + boot1..8}: assemble with `sovas_self.exe` → `_self.o` and with gen1 `sovas_main.exe` →
`_ref.o`; `cmp -s` and require `_self.o` non-empty; count `ident`. PASS iff `ident == tot` and
`tot>0`: `ASSEMBLER self-hosts: gen2==gen1 on N/N inputs`. **gen2 == gen1 on every input is the
fixpoint.**

**Linker self-host (lines 51–56).**
- `sovlink_main.exe crt0_sov.o sovlink_main_sov.o sovld_sov.o sovparse_sov.o sovas_sov.o >
  sovlink_self.exe` — the sovereign linker built from sovereign objects.
- `sovlink_self.exe (…sovas object set…) > sovas_via_selflink.exe`; `cmp` against `sovas_self.exe`
  (the gcc-linker-built gen2): PASS `LINKER re-links sovas == gcc-linker output` — the sovereign
  linker's PE layout is bit-identical to what gcc's `ld` produced earlier.
- `sovlink_self.exe (…linker object set…) > sovlink_self2.exe`; `cmp` against `sovlink_self.exe`: PASS
  `LINKER reproduces itself bit-for-bit` — the linker is a fixpoint of itself.

**Verdict (lines 58–59).** All green → `ALL PASS -- assembler + linker both self-host, byte-identical,
no gcc/ld/gas`; else `FAILURES`; `exit $fail`.

**Cross-file role.** This is the reason `crt0.iii`, `sovas_main.iii`, and `sovlink_main.iii` exist as
separate entry modules: they are the link-time "main"s that turn the engine library into runnable
generations. The fixpoint is what elevates the subsystem from "an assembler that works" to "a
sovereign toolchain" — its output is a closed loop that needs no foreign tool to reproduce.

---

# GROUP 2 — RUNTIME FOUNDATION

---

## File 4 of 53 — `crt0.iii` (2422 bytes) — the C-runtime startup shim for sovereign PEs

**The problem it solves (header, lines 1–6).** When the Windows loader transfers control to a PE's
`AddressOfEntryPoint`, it does **not** pass `argc`/`argv` — `rcx`/`rdx` are undefined garbage at that
instant. In a normal C program the CRT (`mainCRTStartup`) is what calls `GetCommandLine`, splits it
into an argv vector, and only *then* calls `main(argc, argv)`. `sovld` (the sovereign linker) by
default sets the PE entry straight to the program's `main` — fine for an argument-*less* main (the
`boot1..8` programs, the `run_sovtc` drivers), but fatal for a main that reads `argv[1]`: `sovas_main`
does `CreateFileA(argv[1])`, and with `argv` pointing at undefined stack it `strlen`s junk and crashes.
`crt0` supplies the missing runtime. When a tool needs argv, it is linked with `crt0` **first**, and
`sovld` is told the entry is `crt0`'s `cstart`, which builds argv and then calls `main`.

**Module + imports (lines 7–11).**
- `module crt0`.
- `extern @abi(c-msvc-x64) fn GetCommandLineA() -> u64 from "kernel32"` — returns a pointer to the
  process command-line as a NUL-terminated ANSI string (`LPSTR`), typed here as `u64` (raw pointer).
- `extern … fn ExitProcess(code: u32) -> u32 from "kernel32"` — terminates the process with an exit
  code (the value the gates read as `rc`).
- `extern … fn main(argc: i32, argv: u64) -> u64 from "sovas_main.iii"` — the forward declaration of
  the program's `main`. The `from "sovas_main.iii"` is the *default* binding; at link time the actual
  `main` provided in the link set is used (for the linker self-host, that is `sovlink_main`'s `main`).
  The signature is the MS x64 ABI: `argc` in `ecx`, `argv` (pointer to the argv array) in `rdx`.

**Static buffers (lines 13–14).**
- `var ARGV : [u64; 256]` — the argv vector itself: up to 256 pointers, each pointing into `CBUF`.
- `var CBUF : [u8; 16384]` — a 16 KiB scratch buffer holding the tokenized, NUL-separated argument
  text. Tokens are copied here (not pointed into the original command line) so each can be individually
  NUL-terminated. Both are module-level `var`s → they live in `.bss`/`.data` (statically addressed,
  which sidesteps the known "function-local array indexed by a runtime variable segfaults" trap).

**`fn cstart() -> u64 @export` (lines 16–50).** `@export` so the linker can name it as the PE entry.
The body is a hand-written `CommandLineToArgv`-style tokenizer:
- `let s : *u8 = GetCommandLineA() as *u8` — the raw command line.
- Cursors: `argc` (count), `o` (write cursor into `CBUF`), `i` (read cursor into `s`), `go=1` (outer
  loop control). All `u32`.
- **Outer loop `while go == 1`:**
  - `while s[i] == 32u8 { i = i + 1 }` — skip inter-token ASCII spaces (`0x20`).
  - `if s[i] == 0u8 { go = 0 }` — end of string → stop.
  - else begin a token: if `argc < 256`, record `ARGV[argc] = (&CBUF as u64) + o` — the start address
    of this token inside `CBUF`. (The bound check silently drops args past 256 rather than overflowing
    `ARGV`.)
  - `inq=0` (inside-quotes flag), `t=1` (inner loop control).
  - **Inner loop `while t == 1`** copying one token, char `c = s[i]`:
    - `c == 0` → end of string, `t=0` (token ends).
    - `c == 34u8` (`"`, double-quote) → toggle `inq` (0↔1) and advance `i` **without copying** the
      quote — quotes delimit, they are not part of the value.
    - `c == 32u8` (space): if `inq==1` it is a *literal* space inside a quoted token → copy it
      (`CBUF[o]=c; o++; i++`); if `inq==0` the space ends the token → `t=0`.
    - any other char → copy it (`CBUF[o]=c; o++; i++`).
  - After the inner loop: `CBUF[o] = 0u8; o++` — NUL-terminate this token so `argv[k]` is a valid C
    string; `argc++`.
- **Invoke and exit (lines 47–49):** `let rc : u64 = main(argc as i32, (&ARGV) as u64)` — call the
  program's main with the built vector (`&ARGV` is the base of the pointer array, i.e. `char**`).
  `ExitProcess(rc as u32)` — terminate with main's return value (so `return 99` in a tool becomes the
  process exit code the gate checks). `return 0u64` is unreachable (ExitProcess never returns) but
  satisfies the type checker.

**Bit-for-bit relevance.** `crt0` is itself one of the modules the fixpoint gate assembles and links
sovereignly (`crt0_sov.o` appears first in every `sovlink_main` invocation in `run_fixpoint.sh`), so
its own emitted bytes are byte-gated against gas like any other module. Functionally it is the reason
the multi-argument self-host (`sovlink_self.exe crt0_sov.o … > sovlink_self2.exe`) can read its five
input paths at all: without `cstart` populating `ARGV`, the sovereign linker's `main` would never see
its argument list.

---

# GROUP 3 — THE CORE LIBRARY (THE "BIG FOUR")

`sovparse` (parse AT&T text → drive encoders), `sovas` (encode → x86-64 bytes), `sovcoff` (wrap bytes
in a COFF `.o`), `sovld` (lay bytes into a PE32+). The byte-level substance of the whole subsystem
lives here. Each is read in full before its section is written; reading the byte-constructing source
*is* the bit-for-bit explanation, and the `test_*` arrays (Group 8) independently verify it.

---

## File 5 of 53 — `sovparse.iii` (50372 bytes, 862 lines) — the GAS (.s) parser & multi-pass driver

**Role.** `sovparse` is the *front half* of the assembler: it reads cg_r3's AT&T-syntax `.s` text and
turns each line into calls on `sovas`'s encoder API, accumulating `.text` machine bytes (and, in the
data pass, `.data`/`.rodata`/`.bss` bytes). It owns everything *symbolic* — labels, sections, the
symbol/export tables, branch target resolution and branch *relaxation* — while `sovas` owns the raw
opcode bytes. The header (lines 1–14) states the scope arc: integer-core mnemonics over reg/imm/disp
operands first (byte-identical to gcc, gated by corpus 1935), then relocations, branches, and full SIB
as increments — all of which are present in the file as read.

### The encoder API surface (lines 17–105) — 90 `extern` declarations into `sovas.iii`

Every `extern @abi(c-msvc-x64) fn sov_* … from "sovas.iii"` is one encoder entry `sovparse` can call.
They group by what x86-64 form they emit; this list *is* the instruction repertoire of the toolchain:
- **Stack/flow:** `sov_push_r`/`sov_pop_r` (50+r / 58+r), `sov_ret` (C3), `sov_cqto` (48 99),
  `sov_call_ext`/`sov_call_reg`/`sov_call_rel32` (E8 / FF /2), the `sov_cn_*` name buffer for external
  call symbols.
- **Reg↔reg & reg↔imm ALU (64-bit):** `sov_mov_rr`, `sov_movabs` (B8+r imm64), `sov_mov_imm32`,
  `sov_add_rr`/`sub`/`cmp`/`and`/`or`/`xor`/`test`/`imul_rr`, and the `*_imm32` variants.
- **32-bit variants (`l` suffix):** `sov_movl_rr`, `sov_xorl_rr`, `sov_addl_rr`, … (no REX.W).
- **Memory forms:** `sov_store_base`/`sov_load_base` (`disp(%base)`), the width-specific
  `sov_movw_*`/`sov_movb_*`/`sov_movl_*` stores/loads, the SIB forms `sov_*_sib` (`disp(%b,%i,sc)`),
  and the RIP-relative symbol forms `sov_*_rip_sym` (which emit a relocation).
- **Sign/zero extension:** `sov_movzbq`/`movzwq` (0F B6/B7), `sov_movsbq`/`movswq` (0F BE/BF),
  `sov_movslq` (63), plus their `_sib`/`_mem`/`_rip` memory variants.
- **Unary F7 group:** `sov_neg_r`/`sov_not_r`/`sov_imul_r`/`sov_idiv_r`/`sov_div_r`.
- **Shifts:** `sov_shl_imm8`/`sov_shr_imm8` (C1 /4,/5), `sov_shl_cl`/`sov_shr_cl` (D3).
- **Branches:** `sov_jcc_rel8`/`sov_jmp_rel8`/`sov_jcc_rel32`/`sov_jmp_rel32`, `sov_setcc`.
- **RNG:** `sov_rdrand`/`sov_rdseed`.
- **Data sections:** `sov_data_reset`/`sov_data_emit(sec,b)`/`sov_bss_add(n)`.
- **Bookkeeping:** `sov_reset` (clear the byte buffer), `sov_len` (current `.text` length — used as the
  live offset for label recording and displacement math).

### ASCII constants (lines 107–125, 133–135)

Characters are written as numeric `u32` constants (`C_SP=32`, `C_HASH=35`, `C_DOT=46`, `C_COLON=58`,
`C_PCT=37` `%`, `C_DOL=36` `$`, `C_LP=40` `(`, `C_RP=41` `)`, `C_COM=44` `,`, `C_MIN=45` `-`, `C_0=48`,
`C_9=57`, `C_x=120`, `C_a..C_z`, `C_US=95` `_`, `C_AU=65` `A`, `C_ZU=90` `Z`) to avoid any char-literal
assumptions in the self-hosting compiler. This matters because the *whole parser is a giant
numeric-ASCII state machine* — mnemonics and register names are matched as tuples of these codes.

### Parser state (lines 127–166)

- **Input cursor:** `IN_PTR` (base), `IN_LEN`, `IN_POS` (read offset). `CUR_OFF` records the byte
  offset of the last line start before a `PARSE_ERR`, exported via `sov_err_pos()` for located failure.
- **Operand decode registers (lines 137–145):** one decoded operand lands in `OPK` (kind), `OPR`
  (register or mem base), `OPD` (mem displacement `i32`), `OPI` (immediate `i64`), `OPSEC`/`OPOFF`
  (resolved section + offset for a `sym(%rip)` operand — the disp32 addend), `OPINDEX`/`OPSCALE` (SIB).
  **The operand-kind taxonomy is fixed and used everywhere:** `0=reg`, `1=imm`, `2=mem disp(%base)`,
  `3=sym(%rip)`, `4=SIB disp(%base,%index,scale)`.
- **Section ids (lines 148–152):** `TEXT=0 DATA=1 RODATA=2 BSS=3 OTHER=9`.
- **Data-symbol table (lines 153–159):** `SYM_NAME` (flat name bytes, **32 per slot**), `SYM_NLEN`,
  `SYM_SEC`, `SYM_OFF`, count `SYM_N`; `SEC_OFF[4]` is the running byte offset per section; `CUR_SEC`
  the current section.
- **`.text` label table (lines 162–166):** `LBL_NAME`/`LBL_NLEN`/`LBL_OFF`/`LBL_N` — built in the
  layout pass so branches and sibling calls can resolve a target name to a `.text` byte offset.
  `SP_PASS` selects the pass (1=layout, 2=final).

### Symbol/label/export helpers (lines 168–246)

- `lbl_record(slot,slen2)` copies the name from `SYM_NAME` scratch slot `slot` into `LBL_NAME[LBL_N]`
  and stores `LBL_OFF[LBL_N] = sov_len()` — i.e. the *current* `.text` offset is this label's address.
  Capacity 8192 (the comment notes cg_r3 has 998 `.text` labels, so the old 64 dev cap was raised).
- `lbl_name_eq`/`lbl_find` linear-search the label table by name, returning the offset or `0xFFFFFFFF`.
- **Export table (lines 191–216):** `EXP_*` holds the `.global` names (the COFF *defined externals*).
  `exp_record` appends a name; the `sp_export_*` accessors are `@export`ed so `sovcoff`/`sovld` can
  enumerate exports (`sp_export_n`, `…_off`, `…_namelen`, `…_namebyte`). **`sp_export_inject(off)`**
  (lines 207–216) is the linker hook: it appends an export literally named `main` (bytes `109 97 105
  110` = `m a i n`) at offset `off`, so the merged image gets a single entry-point symbol.

### Lexer primitives (lines 218–292)

- `is_ident_start`/`is_ident` (underscore, letters, digits), `sp_read_name_into(slot)` reads an
  identifier into a 32-byte slot and returns its length (truncating past 32), `sp_names_eq` compares
  two slots.
- Character access: `sp_ch()` returns the current byte (0 past EOF), `sp_ch1()` peeks one ahead,
  `sp_adv()` increments, `sp_skip_ws()` skips spaces+tabs, `sp_skip_line()` skips to and past the next
  newline.
- `is_digit`/`is_lower`/`hexv` (hex digit value). `sp_num()` (lines 272–292) parses a signed integer:
  optional leading `-`; if `0x` prefix, accumulate base-16 (`val = val*16 + hexv(c)`); else base-10
  (`val = val*10 + (c-'0')`); negate if signed. Returns `i64`.

### Register-name decode `sp_reg()` (lines 294–319) — the intricate part

Reads up to 3 leading register characters (`rn0,rn1,rn2`), then consumes any trailing chars (so
`r10d`, `eax`, etc. are fully eaten). Mapping:
- **`r8..r15`:** if `rn0 == 114` (`r`) and `rn1` is a digit, `v = rn1-'0'`, and if a third digit is
  present `v = v*10 + (rn2-'0')` → 8..15.
- **named registers:** pick the identifying 2-char base — `(rn0,rn1)` for a 2-char name, `(rn1,rn2)`
  for a 3-char `r`/`e`-prefixed name (so `rax`/`eax`/`ax`/`al` all resolve via `(a,x)`/`(a,l)`). Then:
  `b='x'(120)` or `b='l'(108)` with `a='a'(97)→0`, `a='c'(99)→1`, `a='d'(100)→2`, `a='b'(98)→3`
  (rax/rcx/rdx/rbx and their sub-widths); `sp(115,112)→4`, `bp(98,112)→5`, `si(115,105)→6`,
  `di(100,105)→7`. Unrecognized → `0xFF`. **This is why `al`, `ax`, `eax`, `rax` all encode reg-number
  0:** the size is carried by the mnemonic suffix, not the register number.

### Operand decode `sp_operand()` (lines 322–355)

Dispatches on the first non-space char: `%`→register (`OPK=0`), `$`→immediate (`OPK=1`, `sp_num`),
an identifier→`sym(%rip)` (`OPK=3`: read the name, resolve section+offset via the data-symbol table,
and if it resolves to `.text` use the real label offset from `LBL`; then consume the literal
`(%rip)`), otherwise memory (`OPK=2`): optional signed displacement, then `(%base[,%index,scale])`; a
comma after the base promotes it to SIB (`OPK=4`) capturing `OPINDEX` and `OPSCALE`.

### Mnemonic matching (lines 357–371)

`sp_mnem` reads the identifier into `MN[0..]` (first 8 chars). `mn_is(a,b,c,d,n)` returns 1 iff the
mnemonic is exactly `n` chars and `MN[0..n]` equals the ASCII codes `a,b,c,d`. So `movq` is
`mn_is(109,111,118,113,4)` = `m,o,v,q`; this numeric form recurs for every instruction.

### Sibling calls & branch relaxation (lines 384–474)

- `sp_sibcall(nlen)`: a `callq L_x` where `L_x` is a `.text` label → a 5-byte `E8 disp32` with **no
  relocation**. In layout pass it emits a placeholder (`sov_call_rel32(0)`); in final pass it computes
  `rel = off - (site + 5)` (the call's displacement is relative to the *next* instruction, i.e. site+5)
  and emits it.
- **Branch relaxation state (lines 397–404):** parallel arrays `BR_SITE` (byte offset), `BR_BIG`
  (0=rel8 / 1=rel32), `BR_JMP`, `BR_CC`, `BR_TNAME`/`BR_TLEN` (target name), capacity 16384.
- `sp_branch_size`: rel8 = 2 bytes; rel32 = 5 (`jmp`) or 6 (`jcc`, because of the `0F` prefix).
- `sp_emit_branch` dispatches to the right encoder by size+kind.
- `sp_relax_check()` (lines 416–435): after a layout pass, for each still-REL8 branch, recompute
  `rel = off - (site+2)`; if it no longer fits `[-128,127]`, set `BR_BIG=1` and mark `changed`. The
  whole layout is then re-run; iterating to a fixpoint (this is **branch relaxation**).
- `sp_try_branch()` (lines 438–474): recognizes the jump mnemonics by ASCII tuple and assigns the
  **x86 condition code (tttn)**: `jmp` (unconditional), `jz/je`→4, `jne/jnz`→5, `jl`→12, `jle`→14,
  `jg`→15, `jge`→13, `jb`→2, `jbe`→6, `ja`→7, `jae`→3. (These are exactly the low nibble of the
  `0x70+cc` / `0x0F 0x80+cc` opcode and the `setcc` opcode — see `sovas`.) In layout pass it records
  the site/target and emits a placeholder; in final pass it resolves and emits at the relaxed size.

### Instruction dispatch `sp_dispatch_instr()` (lines 485–646) — the heart

A flat early-return cascade. Each `if mn_is(…)` recognizes one mnemonic, reads exactly the operands it
needs (`sp_operand`/`sp_two_ops`), and calls the matching `sov_*` encoder. Highlights of the bit-level
mapping:
- `pushq`/`popq`/`retq`/`cqto`/`rdrand`/`rdseed` — direct.
- `movq` (lines 492–503): one mnemonic, **seven** operand-shape dispatches keyed on `(S1K,OPK)` —
  reg→reg, reg→`disp(%base)` (store), `disp(%base)`→reg (load), imm→reg, `sym(%rip)`→reg (load+reloc),
  reg→`sym(%rip)` (store+reloc), reg→SIB and SIB→reg. This is where AT&T's overloaded `mov` is
  demultiplexed into distinct encoders.
- `leaq` (504–513): `.text`-label `sym(%rip)` → `sov_lea_rip_local` (resolved inline, **no reloc**);
  data-symbol `sym(%rip)` → `sov_lea_rip_sym` (rip-rel **+ reloc**); `disp(%base)` → `sov_lea_base`;
  SIB → `sov_lea_sib`.
- `movabsq` → `sov_movabs` (B8+r imm64). `movl`/`movb`/`movw` mirror `movq` at 32/8/16-bit widths.
- `callq` (545–559): `*%reg` → `sov_call_reg` (FF /2); a name resolving to a `.text` symbol →
  `sp_sibcall` (E8+disp, no reloc); otherwise an external call → push the name into `sov_cn_*` and
  `sov_call_ext` (E8 + a relocation against the named symbol).
- ALU `addq/subq/cmpq` choose imm-form vs rr-form by `S1K`; `testq/andq/orq/xorq` are rr-only.
- `setCC` (569–579): every `setX` mnemonic mapped to the same cc codes as branches, into `sov_setcc`.
- `movzx`/`movsx` (581–626): keyed on the size letter in `MN[4]` (`b`=98, `w`=119, `l`=108) and the
  source kind (SIB/mem/rip/reg) it picks the 0F second-opcode `0xB6/0xB7` (zero-extend byte/word),
  `0xBE/0xBF` (sign-extend byte/word), or the `63` `movslq` path.
- F7 unary (`negq/notq/idivq/divq`), `imulq` (0F AF /r), shifts (`shlq/shrq` imm8 vs `%cl`), and the
  32-bit ALU `xorl/addl/subl/andl/orl/cmpl` (reg-reg only; `xorl %eax,%eax` is the dominant zeroing
  idiom). Finally `sp_try_branch()`; an unmatched mnemonic sets `PARSE_ERR=1` (loud, located failure).

### The three passes (lines 648–862)

`sovparse(ptr,len)` (651–685) is **one** encode pass: it resets `sovas`, walks the buffer line by line,
skips blanks/comments/directives (directives go through `sp_dir1` to track `CUR_SEC`), and for an
identifier line decides label (`name:` → in layout pass record the `.text` offset) vs instruction
(`sp_dispatch_instr`). Returns `-1` on `PARSE_ERR`.

`sp_build_symtab` + `sp_dir1` (687–831) are **pass D** (`SP_PASS=0`): they build the data-symbol table
(label→section,offset), record `.global` exports, *and emit the actual data-section bytes once*.
`sp_dir1` handles `.section`/`.text`/`.data`/`.bss`/`.rodata` (sets `CUR_SEC`), `.global`, and the data
emitters `.quad`(8B)/`.long`(4B)/`.byte`/`.zero`/`.ascii`/`.asciz` — each advancing `SEC_OFF[CUR_SEC]`
and, in pass D, emitting little-endian bytes via `sov_data_emit` (or reserving BSS via `sov_bss_add`).
`sp_emit_val` writes `n` little-endian bytes of a value; `sp_emit_string` handles `\0 \n \t \r \\ \"`.

`sovparse_full(ptr,len)` (835–861) is the **public entry** and orchestrates **D → L → F**:
1. **D:** `sp_build_symtab` (symbols, exports, data bytes).
2. **L (iterated):** reset all branches to REL8, run `sovparse` with `SP_PASS=1` to record label
   offsets, then `sp_relax_check`; repeat while anything grew (capped at 8 iterations) — this is the
   **relaxation fixpoint** that makes branch encodings stable.
3. After layout, resolve each export's `.text` offset (`EXP_OFF[e] = lbl_find(name)`).
4. **F:** `SP_PASS=2`, run `sovparse` once more to resolve all branch/sibling displacements and emit
   the final bytes. The resulting `sovas` byte buffer + relocation table are the assembled output.

**Cross-file role.** `sovparse` is the only caller of `sovas`'s ~90 encoders; `sovcoff`/`sovld` consume
its outputs (the `sov_*` byte buffer, the reloc table, and the `sp_export_*` symbol enumeration). The
two-pass-with-relaxation design is precisely what lets the emitted `.text` come out byte-identical to
gas, because gas performs the same relaxation — a naive one-pass assembler would pick rel32 where gas
picks rel8 and the `cmp` in `run_sovboot.sh` would redden.

---

## File 6 of 53 — `sovas.iii` (34456 bytes, 565 lines) — the x86-64 encoder core

**Role.** The correctness-critical heart: it turns a decoded instruction (mnemonic + register/imm/mem
operands) into the *exact* machine-code bytes gcc-as would emit, appended to a byte buffer. Every
`sov_*` encoder `sovparse` calls lives here. The differential KAT (corpus 1934) gates byte-identity
against gcc's real output; "a wrong byte reddens the gate" (header, lines 1–14). Register numbering is
fixed: `rax=0 rcx=1 rdx=2 rbx=3 rsp=4 rbp=5 rsi=6 rdi=7 r8..r15=8..15`.

### State (lines 17–55)

- **The output buffer:** `SOV_BUF : [u8; 1048576]` (1 MiB), length `SOV_LEN`, cap `SOV_CAP`. This *is*
  the assembled `.text`. `sov_len()` returns `SOV_LEN` (the live offset `sovparse` uses for labels and
  displacement math); `sov_at(i)` reads back a byte.
- **Relocation table (lines 21–26):** parallel arrays `REL_OFF` (the disp32 *field* offset within
  `.text` that the linker must patch), `REL_SEC` (target = section id 1/2/3 for a data reloc, or **0**
  meaning "a named symbol"), `REL_SYM` (for named relocs, the extern-symbol slot), count `REL_N`.
- **Extern symbol table (lines 28–33):** `EXT_NAME` (32 bytes/slot), `EXT_NLEN`, `EXT_N` — the targets
  of `callq`-to-named-symbol relocs (and later COFF/import symbols). `CN_BUF`/`CN_LEN` is the scratch
  the parser pushes a call-target name into before `sov_call_ext`.
- **Data-section assembly (lines 35–55):** `DATA_BUF`/`RODATA_BUF` (1 MiB each, but write-capped at
  8192 — see note), `DATA_LEN`/`RODATA_LEN`, `BSS_SIZE`. **Crucial lifecycle fact:** these persist
  across the two `.text` encode passes — `sov_reset()` (per pass) does *not* clear them; only
  `sov_data_reset()` does, once in pass D. `sov_data_emit(sec,b)` appends a byte to `.data`(1) or
  `.rodata`(2); `sov_bss_add(n)` grows the BSS size; `sov_data_len`/`sov_data_at`/`sov_bss_size` read
  them back (consumed by `sovcoff`/`sovld`).

### Reset & relocation surface (lines 57–99)

`sov_reset` zeroes `SOV_LEN`, `REL_N`, `EXT_N`, `CN_LEN` (the per-pass clear). `sov_reloc_n/off/sec/sym`
expose the reloc table. `sov_rec_reloc(sec)` appends a reloc at the *current* `SOV_LEN` for a section
target (named slot = `0xFFFFFFFF`); `sov_rec_reloc_at(off,sec,sym)` is the **linker** entry that records
a reloc at an explicit offset (used for merged-image data relocs and import calls). `sov_cn_clear`/
`sov_cn_push` fill `CN_BUF`; `sov_ext_intern` find-or-adds `CN_BUF` to the extern table and returns its
slot; `sov_ext_n`/`…_namelen`/`…_namebyte` enumerate it. **`sov_call_ext` (lines 91–97)** is the canonical
external call: emit `E8`, intern the name, record a reloc at the (now-current) disp32 field with
`REL_SEC=0` (named) and `REL_SYM=slot`, then emit a 4-byte **zero** disp32 (the gas addend convention —
the linker fills the real displacement). So `callq foo` → `E8 00 00 00 00` + one named reloc.

### Emit primitives (lines 101–135) — the byte machinery every encoder shares

- `sov_emit(b)` appends one byte (masked to 8 bits) if under cap. `sov_text_emit` is its `@export`
  wrapper for the linker; `sov_patch(i,b)` overwrites an already-emitted byte (linker fixups).
- **`sov_text_pad16()` (lines 111–114):** after the final encode, append `0x90` (NOP) until
  `SOV_LEN` is a multiple of 16 — matching gas's verified `.text` section-end alignment. Append-only,
  so it shifts no label/reloc (all precede the pad).
- `sov_imm(val,n)` emits `n` **little-endian** bytes of `val` (`(val >> 8k) & 0xFF` for k=0..n-1) —
  every displacement and immediate goes through this, which is why all multi-byte fields are LE.
- **`sov_rex(w,r,x,b)`** emits `0x40 | (w<<3) | (r<<2) | (x<<1) | b` — the REX prefix, exactly the
  `0100 WRXB` form from the conventions. `sov_rexwb(reg,rm)` is the common case: REX.W=1, R = (reg≥8),
  B = (rm≥8), X=0.
- **`sov_modrm(md,reg,rm)`** emits `(md<<6) | ((reg&7)<<3) | (rm&7)` — the ModRM byte. (The high 4th
  bit of reg/rm is carried by REX.R/REX.B, hence the `&7`.)

### Instruction families (exact byte templates)

**Stack (lines 138–147).** `pushq %reg` → optional `41` (REX.B if reg≥8) then `50+(reg&7)`; `popq` →
`58+(reg&7)`. (No REX.W: push/pop default to 64-bit operand size in long mode.)

**Reg↔reg & imm moves (lines 151–166).** `movq %src,%dst` → `REX.W 89 /r`, ModRM `mod=11 reg=src
rm=dst` (AT&T `mov src,dst` → opcode 89 stores reg→rm, so reg=src). `movabsq $imm64,%reg` → `REX.W
(B from reg≥8) B8+(reg&7)` + 8-byte LE imm. `movq $imm32,%reg` → `REX.W C7 /0` ModRM `mod=11 reg=0
rm=reg` + 4-byte LE imm (sign-extended at execution).

**General memory operand `sov_membase_modrm` (lines 299–308)** — the shared `disp(%base)` encoder used
by load/store/lea/movb/movl/movw. Selects `mod`: `disp==0 && base∉{rbp,r13}` → `mod=00`; `disp==0 &&
base∈{rbp,r13}` → `mod=01` with a disp8=0 (rbp/r13 can't be encoded mod=00); fits int8 → `mod=01
disp8`; else `mod=10 disp32`. If `base&7==4` (rsp/r12) it must emit a no-index SIB byte `sov_sib(0,4,
base)` (because rm=100 means "SIB follows"). The caller emits REX + opcode first. (Comment records the
historical bug: a rbp-disp8-only version truncated `movq %rax,-0x88(%rbp)`; the byte-gate caught it.)
So `movq %reg,disp(%base)` → `REX.W 89 + membase_modrm`; load → `8B`.

**RIP-relative (no symbol) (lines 179–199).** `store/load/lea disp32(%rip)` → `REX.W 89/8B/8D`, ModRM
`mod=00 reg=reg rm=101` (the rm=101+mod=00 RIP form), + 4-byte LE disp32. The 32-bit `sov_store_rip32`
omits REX entirely (`89 05 disp32`).

**SIB memory (lines 201–255).** `sov_scalelog` maps scale 1/2/4/8 → log 0/1/2/3. `sov_sib(scale,index,
base)` emits `(scalelog<<6)|((index&7)<<3)|(base&7)`. `sov_sib_modrm_disp` chooses mod the same way as
membase (rbp/r13 base with disp0 forces disp8). The 64-bit forms `sov_load_sib_d`/`sov_store_sib_d` →
`REX.W 8B/89 + ModRM(rm=100) + SIB + disp`; the 32-bit `sov_movl_*_sib` drop REX.W (REX only if any of
reg/index/base ≥ 8, via `sov_rex_sib_w0`). `sov_movzx_sib` → `REX.W 0F <op2> + SIB+disp` (op2 = B6
movzbq / B7 movzwq / BE movsbq / BF movswq); the comment's worked example `movzbq (%rax,%rcx,1),%rax =
48 0f b6 04 08` decodes as REX.W=48, 0F B6, ModRM `04`=`mod00 reg000 rm100(SIB)`, SIB `08`=`scale0
index001(rcx) base000(rax)`. `sov_movsxd_sib` → `REX.W 63 + SIB+disp` (movslq, no 0F).

**ALU reg,reg (lines 257–267).** `sov_alu_rr(op,dst,src)` → `REX.W <op> /r` with ModRM `mod=11 reg=src
rm=dst`. Opcodes: add=`01` sub=`29` cmp=`39` and=`21` or=`09` xor=`31` test=`85` (the standard `op
r/m,r` direction-0 forms).

**ALU $imm,%reg (lines 269–284) — a byte-identity hot spot.** `sov_alu_imm32(ext,reg,imm)`: emit REX.W,
then if `imm ∈ [-128,127]` use the **short** form `83 /ext ib` (1-byte sign-extended immediate), else
`81 /ext id` (4-byte). ext: add=/0 sub=/5 cmp=/7. The comment pins it: `add $0x10` must be `48 83 c0
10`, **not** `48 81 c0 10 00 00 00` — gcc always picks the short form when it fits, so the encoder must
too or the `.text` differs.

**32-bit reg,reg (lines 285–338).** `sov_op32_rr(op,dst,src)` → no REX.W; REX.R if src≥8 or REX.B if
dst≥8 (single-high simplification, sufficient for cg_r3's int32 use), then `<op> /r` ModRM `mod=11
reg=src rm=dst`. Family: movl=`89` xorl=`31` addl=`01` subl=`29` andl=`21` orl=`09` cmpl=`39`
testl=`85`. `xorl %eax,%eax` (the zeroing idiom) → `31 c0`. `sov_movl_load_base`/`…_store_base` use
`8B`/`89` + membase, REX only if reg/base ≥ 8. `sov_movzx_mem`/`sov_movslq_mem` extend from memory
(`REX.W 0F op2`/`REX.W 63` + membase). `sov_movsbq`/`movswq` reg→reg → `REX.W 0F BE/BF /r`.

**F7 unary group (lines 350–366).** `sov_f7(ext,reg)` → `REX.W F7 /ext`: not=/2 neg=/3 (mul=/4)
imul=/5 div=/6 idiv=/7. **`sov_imul_rr` (lines 362–364)** is *separate* and correct for the two-operand
multiply cg_r3 actually emits: `REX.W 0F AF /r` ModRM `mod=11 reg=dst rm=src` — the comment records that
using the one-operand F7/5 form here was a real bug (it ignores the destination and clobbers rdx),
caught on boot1 by the differential gate (ran fine, encoded wrong).

**Shifts (lines 368–390).** `sov_shift_imm8(ext,reg,imm)` → `REX.W`, then if imm==1 the special `D1
/ext` (shift-by-1, **no** immediate byte), else `C1 /ext ib`. shl=/4 shr=/5 (sar=/7). `sov_shift_cl` →
`REX.W D3 /ext` (shift by `%cl`, no immediate).

**Indirect call (lines 385–388).** `callq *%reg` → optional `41` (REX.B), `FF /2` ModRM `mod=11 reg=2
rm=reg`; `callq *%rax` = `ff d0`. (Comment: the parser previously mis-read `*%rax` as a symbol name and
emitted a bogus `E8`+reloc.)

**setCC (lines 394–401).** `sov_setcc(cc,reg8)` → for reg8≥4 a REX (to access spl/bpl/sil/dil or
r8b+), then `0F (90+cc) /0` ModRM `mod=11 reg=0 rm=reg8`. cc codes match the branch tttn table
(b=2 ae=3 e=4 ne=5 be=6 a=7 l=12 ge=13 le=14 g=15).

**movzx/movslq reg→reg (lines 403–413).** `movzbq` `REX.W 0F B6 /r`; `movzwq` `0F B7`; `movslq` `REX.W
63 /r`.

**Control flow (lines 416–421).** `jcc rel8` → `70+cc` + 1-byte rel; `jmp rel8` → `EB` + rel8; `jcc
rel32` → `0F (80+cc)` + 4-byte LE rel; `jmp rel32` → `E9` + rel32; `call rel32` → `E8` + rel32; `ret` →
`C3`. (These are the encoders the relaxation logic in `sovparse` selects between.)

**RIP-relative to a symbol (relocation sites, lines 427–484).** `movq/lea sym(%rip),%reg` etc. emit
`mod=00 rm=101` then **`sov_rec_reloc(sec)`** (record a REL32 at the disp32 field) then a disp32 = the
symbol's offset within its section (the gas addend convention; the reloc targets the *section*).
Variants: `sov_load_rip_sym` (8B), `sov_store_rip_sym` (89), `sov_lea_rip_sym` (8D), the 32-bit
`sov_movl_load_rip_sym`/`…_store_rip_sym` (no REX.W; REX emitted *only* if reg≥8 — the comment stresses
that `sov_rex` always emits a `0x40` byte, so `%eax` must be `8B 05 <rel32>` with no REX),
`sov_movslq_rip` (63), `sov_movzx_rip` (0F op2), `sov_movb_*_rip_sym` (88/8A), `sov_movw_store_rip_sym`
(66 89). **`sov_lea_rip_local` (lines 452–457)** is the no-reloc same-section variant: it resolves the
RIP displacement *inline* as `disp = off - (sov_len() + 4)` exactly as gas does (rip points just past
the 4-byte field), avoiding a spurious reloc that previously crashed the self-host fixpoint.
`sov_lea_base` is the `leaq disp(%base),%reg` (`REX.W 8D` + membase, no reloc — for `&local`).

**8-bit moves (lines 488–523).** `movb` store=`88`/load=`8A`, no REX.W, REX only for r8b+/r8-base or
high reg; base, rip, reg-reg, and SIB forms — cg_r3 stores `%al`/`%dl` (regs 0,2) so the spl/bpl REX
case never arises. `movb %reg,(%base,%index,scale)` is the `arr[i]=v` u8-store form `88 14 08` (worked
example for `(%rax,%rdx,1)` with `%dl`).

**16-bit moves (lines 526–548).** `movw` = `0x66` operand-size prefix + the movl opcodes (89/8B), no
REX.W. Base/load/SIB-store/rip-store forms.

**Misc (lines 549–564).** `cqto` (sign-extend `%rax`→`%rdx:%rax` before `idivq`) → `REX.W 99` = `48 99`.
`sov_lea_sib` → `REX.W 8D + SIB`. `rdrand %reg` → `REX.W 0F C7 /6`; `rdseed %reg` → `REX.W 0F C7 /7`.

**Cross-file role.** `sovas` is the byte authority. `sovparse` decides *which* encoder and *what
operands*; `sovas` decides *which bytes*. The relocation table it builds is consumed verbatim by
`sovcoff` (turned into COFF relocation records) and by `sovld` (patched in directly during PE layout).
The `test_*` files in Group 8 call these encoders and assert the exact byte arrays — they are the
external proof that the templates above are correct; the comments throughout this file are a fossil
record of every byte that was once wrong and the gate that caught it.

---

## File 7 of 53 — `sovcoff.iii` (10129 bytes, 204 lines) — the COFF `.o` object emitter

**Role.** The assembler back-end: it takes `sovas`'s assembled `.text`, the `.data`/`.rodata`/`.bss`
section bytes, and the in-memory reloc/extern tables, plus `sovparse`'s export list, and writes a valid
PE/COFF object that gcc's `ld` accepts — to **stdout**, in binary mode. This is the file whose first two
output bytes are the `64 86` magic Tier B of `run_sovtc.sh` checks.

### Imports and binary stdout (lines 17–35, 48–50, 98)

It pulls the assembled artifacts from `sovas` (`sov_len`/`sov_at` for `.text`, `sov_data_len`/`…_at`,
`sov_bss_size`, the `sov_reloc_*` table, the `sov_ext_*` extern table) and the exports from `sovparse`
(`sp_export_*`). Output is via `putchar`; **`_setmode(1, 0x8000)`** (line 98) sets fd 1 (stdout) to
`_O_BINARY` so a `0x0A` byte is **not** translated to `0D 0A` on Windows — essential, because the
output is binary, not text. `w8`/`w16`/`w32` (lines 48–50) write 1/2/4 bytes **little-endian**.

### The symbol-table ordering contract (header lines 9–11; `reloc_symidx`, lines 91–95)

This is the invariant the whole file is organized around, because relocations reference symbols *by
index*: **(1)** section symbols first — `.text/.data/.rodata/.bss`, each occupying **two** entries (the
symbol + 1 aux record); **(2)** exported functions; **(3)** extern (undefined) symbols. Therefore a
data reloc (`REL_SEC` 1/2/3) maps to its section symbol's index `SEC_SYMIDX[s]`; a named reloc
(`REL_SEC==0`) maps to `(2*NS + NEXP + slot)` — sections (2 entries each) + exports + the extern slot.

### Section name & characteristics tables (lines 53–64)

`w_secname(id)` emits the fixed 8-byte ASCII name padded with NULs: `.text`=`2e 74 65 78 74 00 00 00`,
`.data`, `.rodata` (uses all 8 bytes: `2e 72 6f 64 61 74 61 00`), `.bss`. `sec_chars(id)` returns the
`Characteristics` dword: `.text`=`0x60500020` (CNT_CODE 0x20 | ALIGN_16 0x00500000 | MEM_EXECUTE
0x20000000 | MEM_READ 0x40000000); `.data`=`0xC0500040` (CNT_INITIALIZED_DATA 0x40 | ALIGN_16 |
READ | WRITE 0x80000000); `.rodata`=`0x40500040` (initialized, READ only); `.bss`=`0xC0500080`
(CNT_UNINITIALIZED_DATA 0x80 | ALIGN_16 | READ | WRITE).

### Symbol Name field encoding `w_symname` (lines 68–88)

A COFF symbol Name is 8 bytes. If the name is ≤8 chars it is stored **inline** (right-padded with
NULs). Otherwise the field is `00 00 00 00` followed by a 4-byte **string-table offset** — and the
offset is `4 + STR_LEN`, the `+4` accounting for the string table's leading 4-byte size word. The name
bytes + a NUL terminator are appended to `STR_BUF`. (This is exactly why `sov_drive6` is the "longname"
gate — it forces the string-table path.)

### Layout computation `sovcoff_emit` prologue (lines 97–135)

1. `sov_text_pad16()` — pad `.text` to a 16-byte boundary first (gas-match), *then* read `sov_len`.
2. Determine section presence: `.text` always present; `.data`/`.rodata`/`.bss` present iff non-empty.
   `NS` = count of present sections.
3. `NEXP` = exports whose `.text` offset resolved (`!= 0xFFFFFFFF`). `next` = extern count.
   `nsym = 2*NS + NEXP + next`; `nreloc = sov_reloc_n()`.
4. **File offsets:** `hdrs = 20 + 40*NS` (file header + one section header per present section). Raw
   data begins at `hdrs`; each present non-`.bss` section is assigned `PointerToRawData = cur_ptr` and
   `cur_ptr += rawlen` (`.bss` gets `RawPtr=0`, no file bytes). Section symbol indices are assigned
   `cur_sym += 2` per section. After raw data: `text_relptr = rawdata_end` (if any relocs);
   `symptr = rawdata_end + nreloc*10` (each relocation record is 10 bytes).

### The bytes, in file order (lines 137–202)

- **IMAGE_FILE_HEADER (20 bytes, line 138):** `w16(0x8664)` → **`64 86`** (Machine = AMD64 — the magic);
  `w16(NS)` (NumberOfSections); `w32(0)` (TimeDateStamp = 0, deterministic); `w32(symptr)`
  (PointerToSymbolTable); `w32(nsym)` (NumberOfSymbols); `w16(0)` (SizeOfOptionalHeader = 0, objects
  have none); `w16(0)` (Characteristics = 0).
- **Section headers (40 bytes each, lines 141–156)** in `.text/.data/.rodata/.bss` order: 8-byte name;
  `VirtualSize=0`; `VirtualAddress=0`; `SizeOfRawData=rawlen`; `PointerToRawData=rawptr`;
  `PointerToRelocations` = `text_relptr` for `.text` else 0; `PointerToLinenumbers=0`;
  `NumberOfRelocations` = `nreloc` for `.text` else 0; `NumberOfLinenumbers=0`; `Characteristics`.
- **Raw section data (lines 158–162):** all `.text` bytes (`sov_at`), then `.data`, then `.rodata`
  (`.bss` emits nothing — it is uninitialized).
- **Relocation records (10 bytes each, lines 164–166):** for each reloc — `w32(VirtualAddress =
  reloc_off)`, `w32(SymbolTableIndex = reloc_symidx)`, `w16(Type = 4)`. **Type 4 =
  `IMAGE_REL_AMD64_REL32`** (32-bit relative, the only relocation kind this toolchain emits).
- **Symbol table (18 bytes per record, lines 168–196):**
  - *Section symbols* (+ aux): Name = secname; `Value=0`; `SectionNumber=(symidx/2)+1`; `Type=0`;
    `StorageClass=3` (`IMAGE_SYM_CLASS_STATIC`); `NumberOfAuxSymbols=1`. Then the **aux record** (18
    bytes): `Length=rawlen`, `NumberOfRelocations` (= `nreloc` for `.text`, else 0), then zeros.
  - *Export symbols:* Name (via `w_symname`); `Value=export_off`; `SectionNumber=.text#`; `Type=0`;
    `StorageClass=2` (`IMAGE_SYM_CLASS_EXTERNAL`); `aux=0`.
  - *Extern symbols:* Name; `Value=0`; `SectionNumber=0` (undefined → the linker must resolve it);
    `StorageClass=2`; `aux=0`.
- **String table (lines 198–201):** `w32(4 + STR_LEN)` (total size including the size word) then the
  accumulated `STR_BUF` bytes (the long names, NUL-separated).

**Cross-file role.** `sovcoff` is the bridge from "bytes in RAM" to "a file gcc/ld understands." Its
output is what Tier B of `run_sovtc.sh` feeds back to `gcc` (proving structural validity) and runs
(proving semantic correctness). It is *not* used by the `sovld` path — `sovld` lays out a PE directly
from the same `sovas` tables, bypassing the COFF intermediate. The symbol-ordering contract here and in
`reloc_symidx` is the single most fragile cross-file invariant: if `sovcoff`'s ordering and the index
math in `reloc_symidx` ever disagreed, every relocation would point at the wrong symbol and the linked
program would jump into garbage.

---

## File 8 of 53 — `sovld.iii` (16542 bytes, 305 lines) — the PE32+ linker / image writer

**Role.** `sovld` replaces gcc's `ld` entirely: from the *same* `sovas` tables `sovcoff` reads, it lays
out a complete, loadable **PE32+ executable** to binary stdout — sections with section-aligned RVAs,
applied internal relocations, a full multi-DLL import directory, and jump thunks. Its first two output
bytes are the `4d 5a` (`MZ`) magic Tier C of `run_sovtc.sh` checks; the OS loader then runs the result.

### Writers and helpers (lines 38–63)

`p8`/`p16`/`p32`/`p64` write 1/2/4/8 bytes little-endian, each bumping `LDPOS` (the running file
offset). `ppad(target)` emits zero bytes until `LDPOS == target` (section/file alignment padding).
`alignup(v,a) = (v + (a-1)) & (0 - a)` — round up to a power-of-two boundary (`0-a` is the two's-
complement mask `~(a-1)`). `wr32`/`rd32` patch/read a 32-bit LE value inside `TEXTBUF` (the in-RAM copy
of `.text`+thunks) — used to apply relocations and write thunk displacements.

### Entry-point and import classification (lines 64–123)

- `find_main_off()` scans the exports for one literally named `main` (bytes `109 97 105 110`) and
  returns its `.text` offset; absent, returns 0 (`.text+0`). This is the PE `AddressOfEntryPoint`.
- `ext_dll_of(slot)` decides which DLL an imported symbol lives in: **0 = kernel32, 1 = msvcrt**. It is
  an *exact table* of known names first (notably the lowercase kernel32 `lstr*` functions and the
  Win32 API set — `ExitProcess`, `WriteFile`, `VirtualAlloc`, …, and the CRT set — `putchar`, `malloc`,
  `memcpy`, …), then a **case heuristic fallback**: an UPPER-case-first name → kernel32, else msvcrt.
  (The exact table exists precisely because the heuristic mis-routes lowercase kernel32 names.)
- `dll_name_len`/`emit_dll_name` produce `kernel32.dll\0` (13 bytes) / `msvcrt.dll\0` (11 bytes).

### Image layout `sovld_emit` (lines 125–220)

1. Binary stdout (`_setmode(1,0x8000)`); copy `.text` into `TEXTBUF`.
2. **Thunk reservation:** each of the `k` imports needs a 6-byte jump thunk appended to `.text`, so
   `new_textlen = textlen + k*6`. `.text` RVA = `0x1000`; memory size = `alignup(new_textlen,0x1000)`;
   raw size = `alignup(new_textlen,0x200)`.
3. `.data` present iff `sov_data_len(1)>0`; `.idata` present iff `k>0`. RVAs are assigned sequentially
   (`cur_rva`), each section memory-aligned to `0x1000`.
4. **`.idata` sub-layout (lines 156–182)** when imports exist, in this fixed order from `idata_rva`:
   - **Import Directory Table (IDT):** `(dnum+1)*20` bytes — one 20-byte `IMAGE_IMPORT_DESCRIPTOR` per
     used DLL plus a null terminator (`dnum` = number of DLLs actually used).
   - **ILTs (Import Lookup Tables):** per used DLL, `(count+1)*8` bytes (8-byte entries, PE32+).
   - `iat_dir_rva` = the first IAT's RVA (the value the IAT data-directory points at).
   - **IATs (Import Address Tables, contiguous):** per used DLL, `(count+1)*8`. Each import's IAT-entry
     RVA is recorded in `EXT_IATRVA[i]` (used to compute its thunk displacement).
   - **Hint/Name table:** per import, `alignup(2 + namelen + 1, 2)` (2-byte hint + name + NUL, word
     aligned); RVAs in `EXT_HNRVA[i]`.
   - **DLL name strings:** per used DLL.
5. **`.bss` (lines 183–189):** virtual-only (no file bytes); RVA assigned if `sov_bss_size()>0`. The
   comment records the bug where dropping `.bss` made any program with a large uninitialized array
   (boot7's 1 MB array, sovas's multi-MB buffers) touch unmapped memory and segfault.
6. `size_of_image = cur_rva` (the total memory footprint, the PE `SizeOfImage`).

### Thunks & relocation application (lines 192–210)

- **Thunks (lines 193–200):** for each import `s2`, at `.text` offset `textlen + s2*6`, write `FF 25`
  (`jmp *[rip+disp32]`, the indirect-jump-through-IAT idiom) then `disp32 = EXT_IATRVA[s2] -
  (thunk_rva + 6)` (RIP points just past the 6-byte instruction). So a call to an imported function
  jumps to its thunk, which jumps through the IAT slot the loader filled.
- **Relocations (lines 201–210):** for each reloc, compute a REL32 displacement and patch `TEXTBUF`:
  - `rsec==1` (`.data`): `disp = (data_rva + addend) - (text_rva + roff + 4)` (the in-field addend
    `rd32(roff)` is the symbol's section offset).
  - `rsec==0` (named/import call): `disp = (text_rva + textlen + sym*6) - (text_rva + roff + 4)` — i.e.
    the call's target is the import's **thunk** (at `textlen + sym*6`).
  - `rsec==3` (`.bss`): `disp = (bss_rva + addend) - (text_rva + roff + 4)`.

### File-offset assignment (lines 212–220)

`entry_rva = text_rva + find_main_off()`. `nsec = 1 + has_data + has_idata + has_bss`. Headers occupy
the first `0x200` bytes; raw section data begins at `0x200 + text_raw`, then `.data` (`data_raw =
alignup(datalen,0x200)`), then `.idata` (`idata_raw`). `.bss` has no file bytes.

### The header bytes, in file order (lines 222–244)

- **DOS header:** `p8(77) p8(90)` → **`4d 5a`** (`MZ`); pad to `0x3C`; `p32(0x40)` = `e_lfanew` (PE
  header at file offset 0x40).
- **PE signature (0x40):** `50 45 00 00` (`PE\0\0`).
- **COFF file header (20 bytes):** `p16(0x8664)` (Machine AMD64); `p16(nsec)`; `p32(0)` TimeDateStamp;
  `p32(0)` PointerToSymbolTable; `p32(0)` NumberOfSymbols; `p16(0xF0)` SizeOfOptionalHeader = 240
  (the PE32+ optional header size with 16 data dirs); `p16(0x23)` Characteristics =
  `RELOCS_STRIPPED(0x01) | EXECUTABLE_IMAGE(0x02) | LARGE_ADDRESS_AWARE(0x20)`.
- **Optional header (PE32+), lines 226–235:** `p16(0x20B)` Magic = PE32+; `p8(14) p8(0)` linker
  version 14.0; `p32(text_raw)` SizeOfCode; `p32(data_raw+idata_raw)` SizeOfInitializedData; `p32(0)`
  SizeOfUninitializedData; `p32(entry_rva)` AddressOfEntryPoint; `p32(text_rva)` BaseOfCode;
  `p64(0x40000000,1)` ImageBase = `0x0000000140000000` (the standard PE32+ exe base); `p32(0x1000)`
  SectionAlignment; `p32(0x200)` FileAlignment; `p16(6) p16(0)` OS version 6.0; `p16(0) p16(0)` image
  version; `p16(6) p16(0)` subsystem version 6.0; `p32(0)` Win32VersionValue; `p32(size_of_image)`;
  `p32(0x200)` SizeOfHeaders; `p32(0)` CheckSum; `p16(3)` Subsystem = `IMAGE_SUBSYSTEM_WINDOWS_CUI`
  (console); `p16(0)` DllCharacteristics; then the four stack/heap reserve/commit qwords
  `p64(0x100000,0)`/`p64(0x1000,0)`/`p64(0x100000,0)`/`p64(0x1000,0)` (1 MiB reserve, 4 KiB commit
  each); `p32(0)` LoaderFlags; `p32(16)` NumberOfRvaAndSizes.
- **Data directories (16 × 8 bytes, lines 236–244):** all zero **except** index **1 = IMPORT**
  (`idt_rva`, size `(dnum+1)*20`) and index **12 = IAT** (`iat_dir_rva`, size `iat_total`) when imports
  exist. (These two directories are what makes the Windows loader resolve imports at load time.)

### Section headers & raw data (lines 246–302)

- **Section headers (40 bytes each):** `.text` (`Characteristics 0x60000020` = CODE|EXECUTE|READ),
  `.data` (`0xC0000040` = INIT_DATA|READ|WRITE), `.idata` (`0xC0000040`), `.bss` (`0xC0000080` =
  UNINIT_DATA|READ|WRITE, zero raw pointer/size). Each carries VirtualSize, VirtualAddress (RVA),
  SizeOfRawData, PointerToRawData, and zeroed reloc/linenumber fields.
- **Raw data:** pad to `0x200`; emit all `new_textlen` `TEXTBUF` bytes (`.text` + patched thunks); pad;
  `.data` bytes; then the **`.idata` payload** (lines 270–301): the IDT descriptors (`OriginalFirstThunk
  = ILT_RVA`, TimeDateStamp 0, ForwarderChain 0, `Name = DLL_NAMERVA`, `FirstThunk = IAT_RVA`) + a null
  descriptor; the ILTs (per DLL, each import's `p64(HNRVA,0)` + a null qword); the IATs (identical to
  the ILTs — the loader overwrites them with real addresses at load); the hint/name table (2-byte hint
  `0` + name + NUL + even pad); and the DLL name strings.

**Cross-file role.** `sovld` is the terminal stage of the *no-foreign-tools* path: `sovparse` → `sovas`
→ `sovld` → a running `.exe`, with `gcc`/`ld`/`gas` nowhere in sight. It and `sovcoff` are siblings,
both consuming the `sovas` tables, but `sovcoff` produces a relocatable object (needs a later link) and
`sovld` produces a final image (needs nothing). The thunk + IAT machinery here is the reason `crt0`'s
argv handling matters: a tool linked by `sovld` enters at `find_main_off()`'s target, so a tool that
needs argv must export `cstart` as `main` (which `sp_export_inject` arranges in the linker mains).

---

# GROUP 4 — FRONT-END MAINS / LINK HELPERS

The big four are a *library*: every entry is `@export`ed and called from elsewhere; none has a `main`.
This group provides the `main`s that turn the library into runnable tools — a file-driven assembler, a
file-driven assembler+linker, a multi-object linker — plus a COFF-reader probe and the two-module link
test inputs. All of them share the same Win32 file-read idiom: `CreateFileA(GENERIC_READ,
OPEN_EXISTING)` → loop `ReadFile` into a static buffer → `CloseHandle`, returning the byte count.

---

## File 9 of 53 — `sovas_main.iii` (3009 bytes, 68 lines) — the file-driven assembler tool

**Role.** `sovas_main <input.s>` reads a `.s` file from disk and writes a COFF `.o` to stdout. This is
the tool `run_sovboot.sh` step 2 invokes (`sovas_main prog.o.s > prog_sov.o`) and the fixpoint gate
uses as the gen1 assembler. Exit codes: `2` no argv, `3` read failed, `4` assembly error (loud), `0`
`.o` emitted.

- **Imports:** `CreateFileA`/`ReadFile`/`CloseHandle` (kernel32), `sovparse_full`/`sov_err_pos`
  (sovparse), `sovcoff_emit` (sovcoff), `putchar` (msvcrt). Constants: `GENERIC_READ=0x80000000`,
  `OPEN_EXISTING=3`, `SHARE_READ=1`, `ATTR_NORMAL=0x80`, `INVALID_HANDLE=0xFFFFFFFFFFFFFFFF`,
  `SBUF_MAX=1 MiB`. `SBUF` (1 MiB) holds the source; `NXFER` (8 bytes) receives `ReadFile`'s
  bytes-transferred out-param.
- `read_file(path)` (lines 38–56): open; loop `ReadFile` into `&SBUF + off`, reading the 32-bit
  transferred count out of `NXFER` (`p[0]`), accumulating `off` until a read returns 0 bytes or fails;
  close; return total length.
- `sm_print_fail()` (lines 17–26): on a parse error, print the failing source line — from
  `sov_err_pos()`'s recorded line-start offset up to the next `\n` — to stdout (no `.o` is emitted on
  failure, so stdout is free). This lets a sweep collect the exact first-unhandled construct.
- `main(argc,argv)` (lines 58–68): require `argc≥2`; `path = argv[1]`; `read_file`; if 0 → `3`; run
  `sovparse_full(&SBUF, n)` and on nonzero print the failing line and return `4`; else `sovcoff_emit()`
  (COFF to stdout) and return `0`. **The `argv[1]` read is exactly why `crt0` exists** — when this tool
  is sovereign-linked, it must enter through `cstart`, not directly at `main`, or `argv` is garbage.

---

## File 10 of 53 — `sovld_main.iii` (2211 bytes, 53 lines) — the file-driven assembler+linker tool

**Role.** `sovld_main <input.s> > out.exe` — identical front to `sovas_main` but the back end is
`sovld_emit` instead of `sovcoff_emit`, so the output is a complete native PE32+ executable (`.iii →
(iiis) .s → (sovld_main) .exe`, the whole back half sovereign, no gcc/ld/gas). Used by
`run_sovboot.sh` step 4. Same constants, same `read_file`, same exit codes (`2/3/4/0`). The only
difference from File 9 is line 51: `sovld_emit()` (PE to stdout) where File 9 calls `sovcoff_emit()`.
It does **not** import `sovcoff` — the PE path bypasses the COFF intermediate entirely.

---

## File 11 of 53 — `sovlink_main.iii` (12495 bytes, 281 lines) — the sovereign multi-object linker

**Role.** `sovlink_main a.o b.o … > out.exe` — reads N sov-emitted COFF objects, **merges** their
sections, **resolves** cross-module symbols (keeping each object's locals local), **relocates**, and
emits a PE via `sovld_emit`. This is the link half of the self-host fixpoint (`run_fixpoint.sh` builds
gen2 `sovas` and the sovereign linker with it). `.rodata` is folded into `.data` (sovld has no separate
`.rodata`); imports are handled via the same unresolved-name → DLL path as `sovld`.

- **The COFF reader (lines 49–91):** `rd8/rd16/rd32` little-endian reads of `OBJBUF` (8 MiB). `secid`
  classifies a section by the 2nd byte of its name (`t/d/r/b` → 0/1/2/3). `parse_obj` reads the file
  header (`O_NS=rd16(2)`, `O_SYMPTR=rd32(8)`, `O_NSYM=rd32(12)`) and each 40-byte section header
  (`RAWLEN=+16`, `RAWPTR=+20`, `RELPTR=+24`, `NRELOC=+32`). `sym_name(idx)` reads symbol `idx` (record
  size 18): if the first 4 Name bytes are 0 it's a string-table reference (`O_SYMPTR + O_NSYM*18 +
  rd32(so+4)`), else an inline ≤8-char name. **This reader is the exact inverse of `sovcoff`'s
  writer** — the same 20/40/18/10-byte record sizes and field offsets.
- **`add_object()` — pass 1 (lines 116–201):** parse; record this object's merge bases (`tb=sov_len()`
  text, `db=sov_data_len(1)` data, `bb=sov_bss_size()` bss). Locate each section, then append its raw
  bytes into `sovas`'s buffers via `sov_text_emit`/`sov_data_emit(1,…)`/`sov_bss_add` (`.rodata`
  appended into `.data` right after this object's `.data`, base `rob`). Collect **defined globals**
  (StorageClass `scl==2`, `sec>0`) into the global table `GSYM_*` with their *merged* offsets (text/
  data/rodata/bss base + value). Then process `.text` relocations:
  - **section reloc** (`scl==3`): the field holds an addend. `.text→.text` → patch inline (`(tb +
    addend) - (merged + 4)`, a self-relative REL32). `.data`/`.rodata`/`.bss` → rewrite the field to
    `base + addend` and record a reloc via `sov_rec_reloc_at(merged, rsec, …)` so `sovld` later applies
    the section RVA.
  - **defined global in this object** (`sec>0`) → resolve inline (`(tb + val) - (merged + 4)`).
  - **undefined** (`sec==0`) → stash `(merged_offset, name)` in `ST_*` for pass 2.
- **`resolve()` — pass 2 (lines 204–219):** for each stashed reloc, `gsym_find` the name. If found
  (cross-module call) → patch inline (`tgt - (off+4)`). If not found → it's a **DLL import**: push the
  name into `sov_cn_*`, intern it (`sov_ext_intern_pub`), and record a `rsec==0` reloc — exactly the
  named-reloc shape `sovld` turns into a thunk.
- **Entry selection (lines 221–247, 275–277):** `find_cstart` (name `cstart` = `99 115 116 97 114
  116`) is preferred — if `crt0` was linked in, enter through its argv shim; else `find_main` (name
  `main`). `sp_export_inject(entry)` registers the chosen offset as the export named `main`, which
  `sovld`'s `find_main_off` then reads as `AddressOfEntryPoint`.
- **`main` (lines 262–280):** loop over every argv path, `read_file` into `OBJBUF`, `add_object`;
  then `resolve`, pick the entry, inject it, and `sovld_emit`.

**Cross-file role.** This is the only file that *reads* a COFF object (everything else writes them), and
it does so by being the precise mirror of `sovcoff`. It reuses `sovas`'s byte buffer and reloc table as
the merge workspace (`sov_text_emit`/`sov_patch`/`sov_rec_reloc_at`), then hands off to `sovld` for PE
layout — so the merged multi-object image goes through the exact same image writer as a single-module
program.

---

## File 12 of 53 — `sovlink_probe.iii` (3189 bytes, 81 lines) — the COFF-reader probe (stage 1)

**Role.** A throwaway diagnostic that isolates the COFF *reader* before merge/resolve/relocate were
built on it. `sovlink_probe a.o` parses one sov-emitted object and prints `NS=…` (sections), `SY=…`
(symbols), and per-section `s: <id> <rawlen> <nreloc>`. It was gated by diffing its output against
`objdump -h/-t/-r` — "prove the reader before building on it." Returns **99** on success.

- Same `rd8/rd16/rd32`, `secid`, and `read_file` (into a 4 MiB `OBJBUF`) as `sovlink_main` — this file
  is where that reader was first written and proven. `putu` is a recursive decimal printer; `sp`/`nl`
  print space/newline.
- `main` reads `NS=rd16(2)`, `nsym=rd32(12)`, prints them, then for each section header (`20+40*i`)
  prints `secid`, `SizeOfRawData (sh+16)`, `NumberOfRelocations (sh+32)`. Returns 99. No toolchain
  coupling (only kernel32 + `putchar`) — it is deliberately self-contained so the reader's correctness
  is established independently of the encoder/linker.

---

## File 13 of 53 — `linklib.iii` (333 bytes, 9 lines) — link test input, module B

**Role.** One half of the two-module link gate. `module linklib` defines an `@export`ed `lib_answer()`
and exercises three linker features in nine lines: a **local** read-only string `"lib"` (an `L_str_0`
local symbol — must stay local across the link), and a **1 MiB `.bss` array** `LBUF` (exercises the
linker's `.bss` merge + sovld's virtual-only `.bss` section). `lib_answer` writes `LBUF[1048575]=9`,
checks the string's first byte is `'l'` (108) and the BSS write read back as 9, and returns `42`. The
1 MiB array is specifically there to prove `.bss` is mapped (the bug `sovld`'s comment records).

---

## File 14 of 53 — `linkmain.iii` (567 bytes, 13 lines) — link test input, module A

**Role.** The other half: `module linkmain` with `main`. It declares `extern lib_answer from
"linklib.iii"` (a **cross-module call** — the symbol the linker must resolve from module B's exports)
and `extern putchar from "msvcrt"` (a **DLL import** — the unresolved-name → thunk path). `main` prints
`'K'` + newline via the imported `putchar`, calls `lib_answer()`, checks its own local string starts
with `'m'` (109) and that `lib_answer` returned 42, and returns **99**. Together `linkmain`+`linklib`
force the linker to handle, in one link: a cross-module call, per-module locals, a `.bss` merge, and a
DLL import — the minimal program that touches every `sovlink_main` code path.

---

# GROUP 5 — BOOTSTRAP PROGRAMS (`boot1` … `boot8`)

These are **real, self-contained, multi-function III programs** fed through the whole sovereign pipeline
by `run_sovboot.sh` (and the assembler-self-host leg of `run_fixpoint.sh`). They are not arbitrary —
each is engineered to isolate exactly one codegen form (`sovas`) or PE feature (`sovld`) that the prior
boots do not exercise, so a regression reddens a *specific* boot. Every one returns **99** on success;
the `.text` of each (boots 1–4) is `cmp`'d byte-for-byte against gas. Exhaustive coverage of these
short files means naming the form each pins and the bytes that result — they have no other content.

---

## File 15 of 53 — `boot1.iii` (1131 bytes) — the u64 beachhead

Already introduced (File-4 cross-reference); restated in its bootstrap role. `module sovtc_boot1`:
`add2`/`mul2` (leaf `addq`/`imulq` helpers, **sibling-called** from `main` → `E8`+computed disp32, no
reloc), `sum_table` (a `while` fold over the module array `TABLE : [u64;4] = {1,2,3,4}` → `.data`
section + a **data relocation** to load `TABLE[i]` + a **backward branch** for the loop), and `main`
(calls all three: 40+50=90, 3·3=9, 1+2+3+4=10 → 109 → returns 99). It is "the u64 path": every move is
`movq`, so it exercises REX.W reg/reg, `movabsq`/`mov $imm32`, `imulq` (0F AF), the data-reloc RIP form,
sibling `call rel32`, and conditional/`jmp` branches — but **no** 32-bit, 8-bit, shift, or import forms.
Integer-only (no SIMD/SEH) so it stays in `sovas` Tier-1.

## File 16 of 53 — `boot2.iii` (730 bytes) — the u32 path

`module sovtc_boot2`. The deliberate complement to boot1: everything is `u32`, so it forces the forms
boot1 never emits — `movl` reg/reg, **`movl disp(%rbp)`** (u32 stack-local load/store, the single most
common cg_r3 form the early differential sweep was missing), and a u32 module array `T32 : [u32;4]`
(4-byte `.long` data + a u32 SIB/RIP load). `add32` adds two u32; `sum32` folds the array; `main`
checks 40+59=99 and 10+20+30+40=100, returns 99. Where boot1 pins the REX.W path, boot2 pins the
**no-REX.W** path (and the "emit REX only when a register ≥ r8" rule in `sov_movl_*`).

## File 17 of 53 — `boot3.iii` (742 bytes) — `movb` 8-bit stores (self-host keystone)

`module sovtc_boot3`. Isolates the two `movb` *store* forms cg_r3 actually emits: `put(p,v)` does
`p[0]=v` → `movb %reg,(%base)` (opcode `88`, base register, no disp), and `BG = 7` → `movb %al,
L_BG(%rip)` (opcode `88` + RIP-relative + a `.bss`/`.data` reloc). Both use `%al`/`%dl` (regs 0/2), so
the `spl/bpl/sil/dil` REX special case never arises (reads come back as `movzbq`, already covered by
boot1's region). `main`: write 99 to a stack buffer and 7 to the global, read both back, return 99 iff
correct.

## File 18 of 53 — `boot4.iii` (618 bytes) — shift encodings (B3/B4)

`module sovtc_boot4`. Isolates the two shift special-cases: **shift by constant 1** → `D1 /ext` (the
comment pins `shrq $1` = `48 d1 e8`, **not** `48 c1 e8 01`), and **shift by a variable** → `%cl` /
`D3 /ext` (`shrq %cl` = `48 d3 e8`). `shifts(x,n)` computes `x>>1`, `x>>n`, `x<<1`, `x<<n`; `main`
checks `shifts(16,2)` = 8+4+32+64 = 108, returns 99. This is the one boot that would *run correctly*
with the wrong (generic `C1 … imm`) encoding for `>>1`, so only the byte-`cmp` vs gas catches a
regression — the precise reason the bootstrap gate is byte-differential, not just run-based.

## File 19 of 53 — `boot5.iii` (466 bytes) — the import path (single DLL)

`module sovtc_boot5`. The first program with an **import**: one msvcrt function (`putchar`). Boots 1–4
have zero imports, so `sovld`'s `.idata`/ILT/IAT/thunk machinery had literally never executed until
this. `main` prints `'I'` (73) + newline and returns 99. If the sovereign PE prints `I` and exits 99,
the entire import apparatus — descriptor, lookup table, address table, hint/name table, and the
`FF 25` thunk — is proven live end-to-end.

## File 20 of 53 — `boot6.iii` (453 bytes) — multi-DLL imports

`module sovtc_boot6`. Imports from **two** DLLs at once: `putchar` (msvcrt) + `ExitProcess`
(kernel32). This exercises `sovld`'s per-DLL grouping (`ext_dll_of` → one import descriptor per DLL,
separate ILT/IAT runs). `main` prints `'K'` (75)+newline then `ExitProcess(99)` — so success is signaled
through a kernel32 call rather than a `ret`, additionally proving the kernel32 thunk resolves.

## File 21 of 53 — `boot7.iii` (143 bytes) — large `.bss`

`module sovtc_boot7`. Three lines: a 1 MiB uninitialized array `BIG : [u8;1048576]` and a `main` that
writes `BIG[1048575]=7`, reads it back, returns 99. This isolates `sovld`'s **virtual-only `.bss`**: a
megabyte that must be *mapped but not stored in the file* (`SizeOfRawData`/`PointerToRawData` = 0,
`VirtualSize` = 1 MiB). Before `.bss` was handled, touching `BIG` hit unmapped memory and segfaulted —
this is the smallest program that forces the section to be allocated at load. (At 143 bytes it is the
smallest `.iii` in the whole tree; exhaustive here genuinely *is* these three lines.)

## File 22 of 53 — `boot8.iii` (600 bytes) — `.bss` + `.idata` + multiple imports per DLL

`module sovtc_boot8`. Combines the two axes boot7 and boot5/6 each isolate: a 1 MiB `.bss` array **and**
imports — and specifically **multiple imports from one DLL** (`GetCurrentProcessId` + `GetTickCount`,
both kernel32) plus `putchar` (msvcrt). `main` calls both kernel32 functions, writes/reads `BIG`, prints
`'B'`(66)+newline, and returns 99 iff the BSS write held and both API calls returned > 0. This forces
`sovld` to lay out `.bss` and `.idata` *in the same image* with a DLL that has more than one import (a
2-entry ILT/IAT run) — the final corner the earlier boots leave uncovered.

---

# GROUP 6 — COFF DRIVER PROGRAMS (`sov_drive` … `sov_drive7`)

These are the Tier-B drivers of `run_sovtc.sh`. Each is a tiny III program that **embeds a verbatim
`cg_r3` `.s` emission as a string literal**, runs `sovparse_full` then `sovcoff_emit`, and thereby
prints a COFF `.o` to stdout (which the harness redirects to a file, links with gcc, and runs). The
shared idiom: `extern sovparse_full + sovcoff_emit`; `slen(s)` scans for the byte `126` (`~`) sentinel —
because III string literals are **not** NUL-terminated, the embedded `.s` ends with `~`, and `slen`
returns the length up to it; `main` assembles, returns `1` on a parse error (so the harness sees no
valid `.o`), else emits and returns `0`. Crucially the embedded `.s` is **real compiler output**, not a
hand-written stub — so each driver proves the genuine chain `.iii → cg_r3 .s → sovas/sovparse/sovcoff →
.o → ld → run`. Each driver's label in the gate names the exact COFF path it pins.

---

## File 23 of 53 — `sov_drive.iii` (1507 bytes) — `text-only`

Embeds the verbatim cg_r3 output for `fn main() -> u64 { return 99 }` — the full prologue/epilogue frame
(`pushq %rbp` / `movq %rsp,%rbp` / `subq $1024,%rsp` / `movabsq $0x63,%rax` / push-pop / `leave`-style
`movq %rbp,%rsp` / `popq %rbp` / `retq`), the default-return stub, and the `.rodata` + `.iii.ring3` +
`.asciz "main"` data lines cg_r3 emits. It gates the **plain text-section COFF** path (one `.text`, one
export symbol `main`, no relocations) end-to-end: the `.o` it prints is the simplest valid object, and
the gate confirms gcc links it and it exits 99.

## File 24 of 53 — `sov_drive2.iii` (1254 bytes) — `reloc-data`

Embeds cg_r3 output for `var G : u64 = 99; fn main() -> u64 { return G }`. The `.s` declares `L_G:` in
`.data` with `.quad 0x63` and reads it via `movq L_G(%rip),%rax`. This produces a **two-section COFF**
(`.text`+`.data`) with one **REL32 relocation** from `.text` to the `.data` section symbol — gating
`sovcoff`'s data-section emission, the `sov_rec_reloc(SEC_DATA)` path in `sovas`, and the data-reloc
symbol-index (`SEC_SYMIDX[1]`) in `reloc_symidx`.

## File 25 of 53 — `sov_drive3.iii` (1443 bytes) — `extern-call`

Embeds cg_r3 output for a `main` that calls `putchar('A')` (Win64 shadow-space `subq $32`/`addq $32`
around the call) then returns 99. The `callq putchar` emits a **named** REL32 relocation to the
undefined external `putchar`. This is the gate for the named-reloc symbol-index formula `2*NS + NEXP +
slot` and the emission of an **undefined** symbol record (`SectionNumber=0`, `StorageClass=EXTERNAL`) —
which gcc then resolves against msvcrt at link.

## File 26 of 53 — `sov_drive4.iii` (1257 bytes) — `rodata`

Embeds cg_r3 output for `let s = "c"; return 99` — a `.text`+`.rodata` object with `L_str_0:` `.ascii
"c\0"` and `leaq L_str_0(%rip),%rax` (a REL32 to the `.rodata` section). Gates three things at once:
`.rodata` section emission, `.ascii` raw-byte emission (`sp_emit_string`), and the **rodata** section
symbol's reloc index (`SEC_SYMIDX[2]`).

## File 27 of 53 — `sov_drive5.iii` (1121 bytes) — `bss`

Embeds cg_r3 output for `var BIG : [u64;64]; fn main(){return 99}` — declares `L_BIG:` in `.bss` with
`.zero 512`. The resulting COFF has a `.bss` section with `SizeOfRawData=512` but `PointerToRawData=0`
(uninitialized, no file bytes). Gates `sovcoff`'s `.bss` handling and the `sov_bss_add` path (the
`.zero` directive in `sp_dir1` routes to `sov_bss_add` when `CUR_SEC==SEC_BSS`).

## File 28 of 53 — `sov_drive6.iii` (1268 bytes) — `longname`

Embeds cg_r3 output for a `main` that calls `GetCurrentProcessId` (kernel32) then returns 99. The
function name is **>8 characters**, so it forces the COFF **string table** path in `w_symname` (the
`00 00 00 00` + 4-byte offset name field, with the name appended to `STR_BUF`). It additionally pins the
`movl %eax,%eax` reg-reg dispatch (cg_r3's u32-result zero-extend) — two paid-for paths in one driver.

## File 29 of 53 — `sov_drive7.iii` (1460 bytes) — `movzbq` (self-checking)

Embeds cg_r3 output for `let s = "c"; return s[0]` — which loads the string's first byte via **`movzbq
(%rax,%rcx,1),%rax`** and returns it. The design is self-checking: `'c'` = 99, so the SIB byte-read
result **is** the process exit code — a wrong SIB encoding produces a wrong byte and the gate fails
because the exit is not 99 (no separate assertion needed). The object is `.text`+`.rodata` with the
`.ascii "c\0"` + `leaq` reloc of drive4, plus the SIB `movzbq` whose bytes `48 0f b6 04 08` are pinned
by the run result itself.

---

# GROUP 7 — PE/LINKER DRIVER PROGRAMS (`sov_drivel` … `sov_drivel8`)

The Tier-C drivers of `run_sovtc.sh`. Structurally identical to the Group-6 COFF drivers — embed a
verbatim cg_r3 `.s` (terminated by `~`), `slen` it, `sovparse_full`, return `1` on error — but the back
end is **`sovld_emit`**, so each prints a complete **PE32+ executable** to stdout (no gcc/ld). The
harness redirects that to `lpeN.exe` and the **OS loader runs it directly**; exit 99 means the
sovereign image loaded and ran. Each `sov_drivelN` isolates one `sovld` feature, named by its gate label.

---

## File 30 of 53 — `sov_drivel.iii` (843 bytes) — `ret-only`

The minimal PE: `.text` of just `movabsq $99,%rax` / `retq`. No frame, no data, no imports. Entry =
`.text+0` (no `main` export, so `find_main_off` returns 0). A ret-only entry returns into the loader's
`RtlUserThreadStart`, which treats `rax` as the exit code → 99. This gates the bare image layout: DOS
stub, PE header, optional header, a single `.text` section, and the loader actually mapping and
executing it.

## File 31 of 53 — `sov_drivel2.iii` (1125 bytes) — `data-global`

cg_r3 output for `var G = 99; fn main(){return G}`: `.text` + `.data` (`L_G: .quad 0x63`) with the
RIP-relative load `movq L_G(%rip),%rax`. This forces `sovld` to lay out a second section **and apply the
internal REL32 relocation itself** (`rsec==1`: `disp = (data_rva + addend) - (text_rva + roff + 4)`) —
the data-global path. Entry = `main`; returns G = 99.

## File 32 of 53 — `sov_drivel3.iii` (1347 bytes) — `import`

cg_r3 output for a `main` that calls `ExitProcess(99)` (kernel32). This is the first sovld driver to
build a **full import directory**: one IDT descriptor, an ILT, an IAT, the hint/name entry for
`ExitProcess`, the `kernel32.dll` string, and a `FF 25` thunk; the named REL32 call is patched to the
thunk's RVA. The loader binds `ExitProcess`; `main` calls it with 99; the process exits 99.

## File 33 of 53 — `sov_drivel4.iii` (1617 bytes) — `import2` (multiple imports, one DLL)

cg_r3 output for a `main` calling **two** kernel32 functions — `GetTickCount()` then `ExitProcess(99)`.
This exercises the general-`k` import paths the single-import drivers leave untested: **two** thunks,
**two** ILT and **two** IAT entries plus their null terminators, the **cumulative hint/name RVA
accumulator** (ExitProcess's hint/name RVA depends on GetTickCount's padded size), and the **odd-length
pad branch** (`GetTickCount` is 12 chars → `2 + 12 + 1 = 15`, odd → a pad byte to word-align the next
entry). A mislocated import would crash or fall through to `rax=0`; only `ExitProcess(99)` firing yields
99.

## File 34 of 53 — `sov_drivel5.iii` (1483 bytes) — `multidll`

cg_r3 output for a `main` importing from **two DLLs**: `putchar('A')` (msvcrt) then `ExitProcess(99)`
(kernel32). `sovld` groups the imports by DLL (`putchar` lowercase → msvcrt; `ExitProcess` upper →
kernel32), emitting **two** import descriptors each with its own ILT/IAT/name, two thunks, and patching
each call to its own thunk. The loader binds both DLLs; main prints `'A'` and exits 99.

## File 35 of 53 — `sov_drivel6.iii` (1231 bytes) — `msvcrt-only`

cg_r3 output for a `main` calling only `putchar('A')` (msvcrt), then a ret-only exit (99). This is the
regression gate for a specific bug: when **kernel32 is not used**, the IAT data directory must point at
the **first *used* DLL's IAT** (msvcrt) — not blindly at `DLL[0]` (kernel32). It proves the
`iat_dir_rva` computation walks `DLL_USED` rather than assuming DLL index 0 is present.

## File 36 of 53 — `sov_drivel7.iii` (1374 bytes) — `relax` (branch relaxation in a real PE)

A `main` whose `jz L_end` must jump over a block of **14 `movabsq $1,%rax`** instructions — well over
127 bytes — forcing `sovparse`'s relaxation to grow the branch from REL8 (`74`) to REL32 (`0f 84`) and
compute the right disp32 (the comment recon's `0f 84` at disp `0x117`). `rax=0` so the `jz` is taken;
if the relaxed branch reaches `L_end` (past the block) `main` returns 99; a wrong size/displacement
lands mid-block (executing a `movabsq $1` → `rax=1`) or crashes. This is the relaxation machinery
(Files 5's `sp_relax_check`/`sp_try_branch`) proven in a loaded, running image — not just a byte `cmp`.

## File 37 of 53 — `sov_drivel8.iii` (1231 bytes) — `dlltable` (extern→DLL table + ABI alignment)

A `main` that calls **`lstrlenA`** — a *lowercase* kernel32 function the case heuristic would mis-route
to msvcrt. Only `ext_dll_of`'s exact **table** routes `lstrlenA` to kernel32; with the heuristic alone
the import would be unresolved and the loader would reject the image. Two subtleties the comment pins:
(1) `lstrlenA`'s argument is the `.text` base `0x140001000` (mapped READ+EXEC; an early NUL in the code
bytes bounds the read, so no over-read); (2) `subq $40,%rsp` at entry aligns RSP to a 16-byte boundary
at each `callq` — entry RSP is 8 (mod 16), and `40 ≡ 8 (mod 16)` makes RSP ≡ 0, the x64-ABI alignment
SSE-using imports like `lstrlenA` require (a bare hand-written stub that skips this faults inside the
import). Then `ExitProcess(99)`. Both kernel32; emitted via sovld, no gcc/ld.

---

# GROUP 8 — ENCODER UNIT TESTS (`test_*.iii`, 16 files)

**These files hold the canonical ground-truth bytes.** Where the big four *construct* bytes, these
tests *assert* them against arrays that are `gcc-as`'s real output (verified by `objdump` of live module
objects). The shared harness: a `GOLD : [u8; N]` literal of the expected bytes; the embedded `.s`
terminated by `~` (126) and measured by `slen`; `sovparse(_full)` then a byte-by-byte compare via
`sov_at(i)`; **a distinct failure code per byte/instruction** (e.g. `return 13 + i`) so any wrong byte
is pinpointed; exit **99** iff every byte matches. Reading these *verifies* the entire Group-3 account —
each decoded golden byte below confirms a `sovas`/`sovparse` template stated earlier. (15 of the 16 run
in `run_sovtc.sh`'s Tier A; `test_io` is the standalone argv/IO proof.)

---

## File 38 of 53 — `test_encode.iii` (11386 bytes) — the master encoder battery (corpus 1934)

The widest gate: ~46 single-instruction checks, each `sov_reset()` → one encoder call → `pN(expected
bytes)` → `chk()` (which compares `sov_len()` and every byte), with failure codes 11–56. It is the
primary verification of File 6. Representative golden bytes, decoded against the templates:
`push %rbp` = `55`; `pop %rcx` = `59`; `mov %rsp,%rbp` = `48 89 e5` (REX.W, 89, ModRM `e5`=mod11
reg=4(rsp) rm=5(rbp)); `movabs %rax,0x20` = `48 b8 20 00 00 00 00 00 00 00`; `mov $0,%rax` = `48 c7 c0`
+ 4 zero bytes; `mov %rax,-8(%rbp)` = `48 89 45 f8` (mod01 disp8 `f8`=−8); `lea 0x24000(%rip),%rax` =
`48 8d 05 00 40 02 00` (disp32 LE of 0x24000); `store_sib8` = `88 14 08`; ALU `add/sub/cmp/and/or/xor
%rcx,%rax` = `48 {01,29,39,21,09,31} c8`; **`sub $0x400,%rsp` = `48 81 ec 00 04 00 00`** (imm32 form,
doesn't fit int8) vs **`add $0x10,%rax` = `48 83 c0 10`** (imm8 short form) — the two halves of the
byte-identity hot spot; F7 `neg/not/imul/idiv/div` = `48 f7 {d8,d0,e9,f9,f1}`; shifts `48 c1 {e0,e8}
03`; `setb/setne %al` = `0f {92,95} c0`; `movzbq/movzwq/movslq` = `48 0f b6 c0` / `48 0f b7 c0` / `48
63 c0`; branches `74 44` / `eb 99` / `0f 84 …` / `e9 …` / `e8 …`; `ret` = `c3`; the **high-reg REX**
path `push %r8` = `41 50` and `mov %r8,%r9` = `4d 89 c1` (REX.W+R+B); and the no-REX 32-bit
`movl %ecx,%eax` = `89 c8`, `xorl %eax,%eax` = `31 c0`, `movsbq/movswq` = `48 0f {be,bf} c0`.

## File 39 of 53 — `test_spine.iii` (3058 bytes, corpus 1935) — a whole real function

The spine proof: it parses the **actual** cg_r3 AT&T output for a 3-argument `a+b+c` function (38
instructions) and requires the result to equal gcc's 96-byte `.text` exactly (`GOLD[96]`). Failure
codes: `11` parse error, `12` wrong length, `13+i` byte `i` diverged. This is where the *parser* (not
just the encoder) is first proven end-to-end on real input — including the MS-x64 argument spill
`movq %rcx,-8(%rbp)` / `movq %rdx,-16(%rbp)` / **`movq %r8,-24(%rbp)` = `4c 89 45 e8`** (REX.W+R
because `%r8`), the `pushq`/`popq` stack-shuffle codegen idiom, and the `leave`-equivalent `movq
%rbp,%rsp` / `popq %rbp` / `retq`.

## File 40 of 53 — `test_reloc.iii` (3497 bytes) — the load-reloc spine

Parses `fn(){ return A + B }` (A@.data+0, B@.data+8) and gates **both** the 79 `.text` bytes **and** the
relocation table. Golden facts: `movq L_A(%rip),%rax` = `48 8b 05 00 00 00 00` (disp32 **0** = A's
section offset), `movq L_B(%rip),%rax` = `48 8b 05 08 00 00 00` (disp32 **8** = B's offset); two REL32
relocs to `.data` (sec id 1) at field offsets `0x0e` and `0x1b`. This proves the "disp32 = symbol's
section offset (gas addend convention)" rule from `sovas`'s rip-sym encoders and the `sov_rec_reloc`
table population.

## File 41 of 53 — `test_store.iii` (2331 bytes) — the store-reloc path

Parses `fn(v){ A = v }` and gates the operand-order-sensitive **89-class store**: `movq %rax,L_A(%rip)`
= `48 89 05 00 00 00 00` plus one reloc to `.data` at field `0x18`. (65 `.text` bytes; codes 11/12/13/
14+i.) Confirms `sov_store_rip_sym` emits the same `mod=00 rm=101` form as the load but with opcode 89.

## File 42 of 53 — `test_lea.iii` (2133 bytes) — the lea-reloc path (.rodata)

Parses a string-returning fn and gates `leaq L_str_0(%rip),%rax` = `48 8d 05 00 00 00 00` + a reloc to
**`.rodata` (section id 2)** at field `0x0e` (47 bytes). Confirms `sov_lea_rip_sym` and the `.rodata`
section-id path in `sovparse`'s symbol table.

## File 43 of 53 — `test_unknown.iii` (1030 bytes) — the silent-drop teeth (negative test)

Not a byte test — a *behavioral* one. It asserts that an **unhandled mnemonic** (`xchgq`) makes
`sovparse_full` return **nonzero** (code 11 if it doesn't), and that a **handled** mnemonic (`retq`)
still returns 0 (code 12 if it errors). This guards the `PARSE_ERR=1` "loud, located failure" path in
`sp_dispatch_instr` — proving the assembler never silently emits nothing for an instruction it doesn't
understand (a footgun that would produce a wrong-but-runnable binary).

## File 44 of 53 — `test_call.iii` (3106 bytes) — the named-symbol call reloc

Parses a fn calling the extern `sov_ext_fn` and gates the full named-call contract: 63 `.text` bytes
including the Win64 shadow-space `subq $32,%rsp` = `48 83 ec 20` and `callq` = `e8 00 00 00 00`; **one
reloc at field `0x1c` with sec=0 (NAMED, not a section)**; and that the interned extern table holds
exactly one name, `"sov_ext_fn"` (checked byte-by-byte against `ENAME`). This is the verification of
`sov_call_ext` (E8 + named reloc + zero disp32) and the `sov_ext_intern` table.

## File 45 of 53 — `test_cmp.iii` (2215 bytes) — comparison codegen

Parses `(a>b) as u64` and gates the `cmpq` + `seta` + `movzbq` sequence (80 bytes, no branch/reloc):
the golden stream contains `cmpq %rcx,%rax` = `48 39 c8`, **`seta %al` = `0f 97 c0`** (cc=7 → opcode
0x97), `movzbq %al,%rax` = `48 0f b6 c0`. Confirms the `setcc`/`movzbq` dispatch wiring in
`sp_dispatch_instr`.

## File 46 of 53 — `test_branch.iii` (2909 bytes) — two-pass intra-`.text` branch

Parses a real `if` function and gates the branch resolver: **`jz L_if_end_1` → `74 19`** (REL8, no
reloc; `rel8 = off − (site+2) = 0x19`), with the surrounding `testq %rax,%rax` = `48 85 c0`. Requires
122 `.text` bytes and **zero relocations** (code 12 if any) — proving `sovparse`'s LAYOUT pass records
the label offset and the FINAL pass computes a correct self-relative rel8 with no relocation entry.

## File 47 of 53 — `test_sibcall.iii` (2546 bytes) — sibling call

Two functions in one `.s`; the caller's `callq L_sov_sc_callee` must become **`e8 bc ff ff ff`** (rel32
= `0 − (0x3f+5) = −68` = `0xFFFFFFBC`), with **zero relocs** (99 bytes). This is the same two-pass LBL
machinery as branches, applied to a 5-byte `E8` call — verifying `sp_sibcall`.

## File 48 of 53 — `test_sib.iii` (2989 bytes) — SIB memory + `.bss` relocs

Parses a real array fn `A[3]=99; return A[3]` and gates SIB store/load: **`movq %rdx,(%rax,%rcx,8)` =
`48 89 14 c8`** (ModRM `14`=mod00 reg=2(rdx) rm=100(SIB); SIB `c8`=scale3(×8) index=1(rcx) base=0(rax))
and `movq (%rax,%rcx,8),%rax` = `48 8b 04 c8`; plus two `leaq L_A(%rip)` relocs to **`.bss` (sec 3)** at
fields `0x0e` and `0x33` (100 bytes). Confirms `sov_store_sib_d`/`sov_load_sib_d` and the scale-log
encoding.

## File 49 of 53 — `test_sib_disp.iii` (1546 bytes) — SIB with displacement

Gates the three SIB displacement modes against gas (22 bytes): `8(%rax,%rcx,8)` → `48 89 54 c8 08`
(mod01 disp8), `16(...)` load → `48 8b 44 c8 10` (mod01), `200(...)` → `48 89 94 c8 c8 00 00 00`
(mod10 disp32, `0xc8`=200 LE), and `(%rax,%rcx,8)` → `48 89 04 c8` (mod00, no disp). This is the direct
verification of the mod-selection logic in `sov_sib_modrm_disp`.

## File 50 of 53 — `test_movzx_sib.iii` (1992 bytes) — sign/zero-extend from SIB

Gates the full movz/movs-from-SIB table (44 bytes): `movzbq` = `48 0f b6 …`, `movzwq` = `48 0f b7 …`,
`movsbq` = `48 0f be …`, `movswq` = `48 0f bf …`, `movslq` (movsxd) = `48 63 …`; with the scale field
visible across `,1`→SIB `08`, `,2`→`48`, `,4`→`88`, and disp8/disp32 variants. Verifies
`sov_movzx_sib`/`sov_movsxd_sib` and the `op2` byte selection in `sp_dispatch_instr`'s movzx/movsx arms.

## File 51 of 53 — `test_relax_back.iii` (2269 bytes) — backward REL32, all condition codes

Places `L0`, 130 bytes of filler (13× `movabsq $0` = `48 b8` + 8 zeros), then `jmp/je/jne/jl/jg L0` —
each target >127 bytes **back**, forcing REL8→REL32 with a **negative** disp32. Golden: `jmp` = `e9 79
ff ff ff`, `je` = `0f 84 73 ff ff ff`, `jne` = `0f 85 6d ff ff ff`, `jl` = `0f 8c 67 ff ff ff`, `jg` =
`0f 8f 61 ff ff ff` (159 bytes total). Verifies the rel32 jcc opcodes (`0f 80+cc`) and that relaxation
handles backward (negative) displacements.

## File 52 of 53 — `test_relax_cascade.iii` (2271 bytes) — the relaxation fixpoint

The subtlest gate: `je Aend` *fits* REL8 while `jmp Bfar` is REL8, but `jmp Bfar`'s target is >127 away
so it grows REL8→REL32 (+3 bytes), which shifts `Aend` 3 bytes farther → `je`'s displacement crosses
127 → `je` must **also** grow. Only a fixpoint that re-checks after each grow round resolves this; a
single pass would (wrongly) leave `je` as REL8. Golden final: `je Aend` = `0f 84 81 00 00 00` (disp
129) and `jmp Bfar` = `e9 82 00 00 00` (disp 130), total 266 bytes. **This is the direct proof that
`sovparse_full`'s iterated L-pass relaxation loop (`sp_relax_check` to a fixpoint) matches gas exactly**
— the single most sophisticated correctness property in the parser.

## File 53 of 53 — `test_io.iii` (1882 bytes) — the argv + Win32 file-read goodie gate

The standalone proof that the *tooling* foundation works: `main(argc,argv)` takes the CRT's argv, opens
`argv[1]` with `CreateFileA(GENERIC_READ)`, reads it in a `ReadFile` loop into `SBUF`, and returns
`bytes_read & 0xFF`. Run on `boot1.o.s` (4691 bytes) the exit code is `4691 & 0xFF = 83`. It proves
**both** the CRT argv hand-off **and** the real-Win32 read loop — exactly the two mechanisms `crt0`
(File 4) and the file-driven mains (`sovas_main`/`sovld_main`/`sovlink_main`) depend on. It is the
smallest end-to-end check that the sovereign tools can actually read a file named on their command line.

---

# CLOSING SYNTHESIS — what is happening *across* all 53 files

**The one sentence.** `sovtc` is a complete, self-hosting, foreign-tool-free path from III source to a
running Windows executable: `iiis-2` compiles `.iii` → AT&T `.s`; **`sovparse`** reads that text and
drives **`sovas`**, which encodes the exact x86-64 bytes; **`sovcoff`** wraps them in a COFF object (for
gcc-interop verification) or **`sovld`** lays them directly into a PE32+ image; **`sovlink_main`** merges
many objects; **`crt0`** supplies the argv runtime; and three gate scripts prove, byte-for-byte, that
the output matches gas/gcc/the-OS-loader and that the toolchain reproduces *itself*.

**The data flow (the spine).** There is exactly one shared workspace: `sovas`'s buffers — `SOV_BUF`
(`.text`), `DATA_BUF`/`RODATA_BUF`/`BSS_SIZE` (data sections), the `REL_*` reloc table, and the `EXT_*`
extern table. `sovparse` *fills* them (multi-pass: D builds symbols+data, L lays out labels with branch
relaxation, F emits final bytes). `sovcoff` and `sovld` *read* them (the only two consumers), and
`sovlink_main` both reads input objects *and* refills the same buffers to merge. Every file in Groups
5–8 is either an *input* to this pipeline (boot/driver programs) or an *assertion* about its output
(tests/gates).

**Why correctness is provable, not asserted.** Three independent oracles pin the bytes: (1) gas — the
`run_sovboot`/`run_fixpoint` `objcopy`+`cmp` of `.text` against `gcc -c`; (2) the OS loader — the
`run_sovtc` Tier-B/C runs of sovereign `.o`/`.exe` to exit 99; (3) the `GOLD[]` arrays in the `test_*`
files, which are gas output frozen into the source. The magics `64 86` (COFF) and `4d 5a` (PE) are the
cheap structural checks; the byte-`cmp` and exit-99 are the deep ones. Nothing in this document about a
byte was reconstructed from memory where one of these oracles pins it.

**The closed loop (why it is "sovereign").** `run_fixpoint.sh` is the keystone: gcc builds gen1 tools
*once*, then the tools rebuild themselves — `sovlink(crt0 + sovas_main + sovparse + sovcoff + sovas)` =
gen2 `sovas`, and gen2 == gen1 byte-for-byte on all 13 inputs; the sovereign linker re-links `sovas`
identically to gcc's `ld` and reproduces *itself* bit-for-bit. After the one-time bootstrap, no gcc, no
ld, no gas appears anywhere — the toolchain is a fixpoint of its own output.

**The engineering pattern visible in the file set.** Each capability is introduced by the *smallest
program that forces it* and locked by the *narrowest oracle that catches a regression*: boot1→boot8
walk the codegen forms (u64→u32→movb→shifts→import→multidll→bss→bss+idata); sov_drive→7 walk the COFF
features; sov_drivel→8 walk the PE features; test_* freeze the exact bytes with per-byte failure codes.
The `~`-sentinel embedded-`.s` idiom (string literals aren't NUL-terminated) and the universal exit-99
convention thread all 53 files together. The fossil-record comments in `sovas`/`sovld` (each naming a
byte that was once wrong and the gate that caught it) are the audit trail of how this byte-exactness was
actually achieved.

*End of explication — all 53 files in `STDLIB/sovtc/` covered. (Related files elsewhere in the tree, as
they are named, can be appended below.)*

