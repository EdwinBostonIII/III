# III Independence Closure — Implementation Plan

> **For agentic workers:** this plan executes in a SINGLE context — recorded III feedback: **no subagents on this tree**. Steps use checkbox (`- [ ]`) syntax for tracking. Every `.iii`/`.sh`/`.py` edit is preceded by the CRASH-DEBUGGING read discipline where it applies (compiler-spine changes especially).

> **EXECUTION LEDGER (2026-07-06, single session, each item committed + gated).** What is DONE vs
> what REMAINS, with the evidence and — where a step is blocked — the precise reason (no faked greens):
>
> | Phase | State | Evidence / precise residual |
> |---|---|---|
> | ⊥ BASAL LAW | **DONE** | `mhash_lib.sh` (III authors seals), `basal_census_gate.sh` = anchor stage 7; teeth rc3/95/97 |
> | A sovld multi-DLL | **DONE (prior session)** | 5-DLL id table + N-DLL `.idata`; ws2_32 app runs 99 |
> | B sovas VEX/EVEX | **DONE (prior session)** | crypto closure `witness=0`; + **sovas `mulq` (F7/4) this session** → sovas now encodes EVERY compiler mnemonic (846/847 tree modules assemble sovereignly, 844 byte-identical to gas; only aes_gcm→witness) |
> | C1 sovtc in archive | **DONE** | golden-NEUTRAL (iiis-1 mhash `8449a980` unmoved); collision-scanned 0/183 |
> | C2 in-process assemble | **DONE** | `iii_emit_assemble_sovereign` + per-module witness fallback; `emit_sovereign_gate.sh` GREEN (prog_sat/cg_r3/main/emit `.text`==gas) |
> | C3 in-process link | **DONE (loose-object)** | merge folded into `sovld.iii` (one definition; `sovlink_main` a thin shell), `iii_emit_link_sovereign`; run_fixpoint byte-identical; prog_sat→99. **Residual:** the compiler's default program-link passes the `.a` ARCHIVE (not loose COFF) → a loose-object build model is the follow-on |
> | C4 RE-SEAL | **DONE** | the C2/C3 fold makes the compiler EMBED the sovereign toolchain (emit.iii references sov_*/sovld_link_* → the archive members are pulled into iiis-1/2/3), so the goldens MOVED: iiis-1 `8449a980`→`d3a6751d`, iiis-2/iiis-3 `853b2f…`→`e786b820` (fixpoint HOLDS, corpus 60/0, deterministic twice, sovereign-authored seals). Re-sealed + audit fixpoint-hash updated. The compiler now CONTAINS its own gcc-free assembler+linker |
> | C4 default FLIP | **DONE** | `G_EMIT_MODE` 1→0: sovereign assemble is the DEFAULT (gcc = `--emit=witness` opt-out). Blocker resolved SOUNDLY: `seed_text_identity_gate.sh` reworked from post-assembly `.o` (whose `.reloc`/`.pdata` differ sovcoff-vs-gcc) to the `.o.s` CODEGEN (assembler-agnostic, stronger); premise verified (iiis-0≡iiis-2 `.o.s` 60/60), teeth re-proven. Whole chain+stdlib sovereign-assembled; fixpoint HOLDS (iiis-2==iiis-3==`4c8cec40`, corpus 60/0); **bootstrap 9/9 GREEN under sovereign default**. SEH-safe: III has no exception model, `.pdata` is dead metadata |
> | D1 self-mint | **DONE** | sealed gen-0 seed mints gen1 with no gcc; run_fixpoint + sovbuild prog_sat proven with gcc AND ld OFF PATH; anchor stage 9 |
> | D2 stages | **DONE** | stage 8 witness-zero + stage 9 run_fixpoint-gcc-off, both green |
> | D1 self-mint tools | **REMAINS** | seal gen-0 `sovas_main`/`sovlink_main` seeds via `mhash_file`; unblocks run_fixpoint gcc-off |
> | D2 anchor stages | **PARTIAL** | stage 8 `witness_zero_gate` WIRED + green; stage 9 (run_fixpoint gcc-off) blocked on D1 |
> | E XII @lattice LIVE | **DONE** | corpus 1936 + `xii_live_gate.sh` (teeth); **census breach #1 discharged (ledger 5→4)** |
> | F PQ NIST KATs | **BLOCKED (named)** | mlkem/mldsa/slhdsa have the KAT-shaped surface + internal roundtrip/determinism corpus tests, but official ACVP vectors are multi-MB (fetch caps 10 MB; the summariser won't transcribe thousands of hex bytes verbatim). Bounded external-data acquisition remains |
> | G1/G2 codecs | **REMAINS** | `tp_x86_disasm` (74 ln) + `tp_iii_to_c99` (98 ln) still degenerate; self-contained rewrites |
> | H provenance | **PARTIAL** | 742 phantom tags PINNED down-only (`provenance_gate.sh`, teeth); FALSIFIED the plan's premise (tag is emitted as an `.ascii` string → codegen-neutral but golden-moving), so the bulk rewrite rides the C4 re-seal |
>
> Anchor grew 6→8 stages (seal-authorship 2b + basal census 7 + witness-zero 8), each green.

**Goal:** Make every claim in `DOCS/III-INDEPENDENCE-AUDIT.md` literally true — the default emit path is sovereign (in-process `sovas`/`sovld`, gcc a demoted opt-out witness), `sovas` encodes the VEX/EVEX the crypto modules actually emit (witness→0), `sovld` routes any Win32 DLL, the sovereign tools self-mint from a sealed seed (no gcc bootstrap), XII is the operative optimizer it is documented as (not a dead branch), PQ crypto is gated on official NIST vectors, the two degenerate codecs become a real transpiler and a real decoder, and the 779 stale `from "*.c"` provenance tags tell the truth.

**Architecture:** One spine, closed end to end. `iiis-2` already compiles `.iii → .o.s` (assembly text); the sovereign toolchain (`sovas`/`sovld`) already turns that into a PE with no gcc/ld — but only as an *out-of-compiler orchestrator* (`sovbuild.sh`) and only for the integer + legacy-SSE instruction tier. This plan **completes the sovereign path (VEX/EVEX + multi-DLL), folds it into `emit.iii` so the compiler itself IS the sovereign emitter, then re-seals the bootstrap chain** so `bootstrap_from_clean.sh` proves the whole thing on a host with no gcc/ld/gas on PATH. XII, PQ-KATs, codecs, and provenance are independent truth-restorations that ride the same "wired to an existing gate, ratcheted down-only" discipline.

**Tech Stack:** `.iii` (self-hosted III language, compiled by `COMPILED/iiis-2.exe`); bash gates under `COMPILER/BOOT/` and `STDLIB/scripts/`; the sovereign toolchain under `STDLIB/sovtc/`; MinGW gcc 15.2 / binutils as the *witness* only (differential byte-gates), never in the trusted path once closed.

## Global Constraints

Copied verbatim from the audit, the CLAUDE.md law, and the recorded session memory. Every task's requirements implicitly include this section.

- **NO ISLANDS.** Nothing new is authored until it is consumed by an existing organ or gate. Every artifact this plan adds must be *called* by a real caller and *checked* by a real gate. "Connect to named subsystems, don't build islands." Name the caller in each task.
- **LEAN = exactly-fitted, not small.** Encode precisely the instruction forms the tree emits; decode precisely what the encoder produces; embed precisely the official vectors. No speculative generality (no AVX-512 opcodes nothing emits), no scaffolding without a consumer.
- **PERFECT THE EXISTING SYSTEM FIRST.** No new material until the existing system is enmeshed and green. Reuse before authoring; grep the CONCEPT before building (capability-redundancy audit).
- **DOWN-ONLY RATCHETS.** Every new gate count (witness modules, `.c`-tag count, uncovered-export census) may only shrink. A number above its pin FAILS the build. Raise a pin only with explicit reviewed justification.
- **DETERMINISM.** Two builds over the same tree are byte-identical. `SOURCE_DATE_EPOCH=0`, `LC_ALL=C`, `TZ=UTC0`. Run the determinism gate after every codegen/toolchain change.
- **THE ANCHOR GATE.** `bash COMPILER/BOOT/bootstrap_from_clean.sh` must return 0 (6/6) on a pristine byte-faithful clone after any seed/BOOT/stdlib-wide change. This is the definition of done for every spine phase.
- **BYTE-FAITHFUL CLONES.** `.gitattributes` `* -text` is in force; sandbox validation clones to a non-OneDrive path with `core.autocrlf=false`.
- **NIH STRICT.** libc/kernel32 only at the host boundary; no third-party libraries linked. The one legitimate external *data* input is published NIST/FIPS/RFC test vectors, embedded as constants exactly as the SHA-256 KAT already is.
- **NO PYTHON.** Assess value by reading + judgment, not word-matching. Gates are bash + `.iii`.
- **HOST:** Windows 11, PowerShell primary + Git-Bash for POSIX gates. The `.o.s` is GAS-syntax AT&T assembly (the MinGW target).
- **MEASUREMENT TRAPS (recorded):** capture `rc` directly, never through a pipe (`grep`/`tee` launder exit codes); probe exit codes are 8-bit (`$? & 0xFF`); use `tr -cd '\r' | wc -c` for CRLF detection, not `grep -c $'\r'`; `build_stdlib` FAIL can mask a stale lib — grep the `FAIL = 0` line, not just `rc`.
- **iiis WRITE-TRAPS (still live in `.iii`):** bind a signed `i32/i64` to a local before an ordering compare (`<`/`>` read unsigned otherwise); hoist `arr[i]` out of a signed-order compare; `*/` inside a block comment closes it early; cg_r3 has a 64-local-slot ceiling (silent exit 14) — split large fns.
- **SEAL AUTHORSHIP (THE BASAL LAW, Phase ⊥ — LANDED).** Every seal/attestation in the trusted path is AUTHORED by III's own FIPS-KAT'd SHA-256 via `COMPILER/BOOT/mhash_lib.sh` (`mhash_file`/`mhash_stdin`); GNU `sha256sum` is the veto-witness only.  A raw `sha256sum`-authored seal is a census breach (`basal_census_gate.sh` clause B, down-only pin).  Any hashing step this plan's phases add MUST route through `mhash_lib.sh`.

## Sequencing — and why it inverts the audit's P-numbering

The audit lists P1 (default-flip) before P2 (close `sovas`). Research (this plan's §0 board) found `STDLIB/sovtc` is **not** in `libiii_native.a`, so the in-process fold re-seals the compiler chain — and a re-seal is only byte-clean if the sovereign path is already **complete and witness-free**. Therefore the sovereign path must be *finished* (Phases A+B) **before** the default is flipped and the chain re-sealed (Phase C). The dependency graph:

```
A  sovld multi-DLL routing ──┐
B  sovas VEX/EVEX ───────────┴─► C  emit.iii fold + default flip + RE-SEAL ─► D  self-mint sov tools
                                                                                (drops the last gcc)
E  XII wired real ┐
F  PQ NIST KATs   ├─ independent truth-restorations; each wires to an existing gate, ratchets down-only,
G  real codecs    │  and can land in any order relative to A–D (G's disassembler reuses B's opcode table).
H  provenance     ┘
X  doc-truth pass  — folded into E and the final commit of each phase (prose matches machinery).
```

Leverage order for execution: **A → B → C → D** (the spine, highest leverage, each gated by `bootstrap_from_clean` + `run_fixpoint`), then **G-disasm** (reuses B), then **E, F, H** (independent). A worker may parallelize E/F/H against the spine since they touch disjoint files.

---

# PHASE ⊥ — THE BASAL LAW (LANDED 2026-07-06; precedes and governs A–H)

**The law.** The exact-math / crypto / algebra / geometry organs are BASAL — the toolchain's own
decision and attestation substrate — never a "subsphere" the spine routes around.  A sound organ
the trusted path does not consume is a named, down-only BREACH, not a footnote.  Enforcement is
machine-checked: `COMPILER/BOOT/basal_census_gate.sh` (bootstrap stage 7) over
`basal_census_pins.txt`.

**What was false when this plan was first written.** Every seal in the compiler spine — the
iiis-0/1/2/3 `.mhash` goldens (`build_iiis0.sh:289`, `build_iiis1.sh:234`, `build_iiis2.sh:206`,
`build_iiis3.sh:198`), the determinism twins, the seed seal-drift check
(`seed_text_identity_gate.sh:73`), the trusted-base root (`trusted_base_check.sh:40`), and the
archive seal (`build_stdlib.sh:1844` — SOFT: `if command -v sha256sum`, silently skippable) — was
authored by GNU coreutils alone.  III's own FIPS-gated SHA-256 (`numera/cad` via
`aether/sovhash.iii`) had two peripheral consumers.  This plan's own Phase D reached for raw
`sha256sum` to attest the sovereign seeds.  The systems map's reachability audit concurrently
listed the verification membrane, zkVM, and forcefield optimizer as LIBRARY and the `au_*` proof
family as ISLAND.  That is the "subsphere" failure, named.

**What is machine-checked now.**
- **Crypto authors the membrane** (clause A).  `COMPILER/BOOT/mhash_lib.sh` mints `sovhash` from
  source with the sealed in-tree compiler (candidate order iiis-2 → iiis-1 → iiis-3, matching the
  anchor's per-stage deletion schedule), self-KATs it against FIPS 180-4 vectors ("abc" + empty; a
  minted-but-wrong hasher is fatal in EVERY mode, rc 95), then authors every spine seal; GNU
  `sha256sum` is demoted to veto-witness (disagreement = rc 97, fail-closed).  Same algorithm ⇒
  every golden VALUE unchanged byte-for-byte.  8 spine scripts welded; the archive seal is now
  REQUIRED, not soft.  `bootstrap_from_clean.sh` stage 2b retro-attests the one unmintable window
  (the pristine-clone stage-1 seed seal) sovereignly within the same run.
- **Algebra decides codegen** (clause C — pre-existing, now pinned).  cg_r3's mul-by-const and
  shl+add emissions are `bv_ring`-proven plans (`cg_r3.iii:232,898,2574`); iiis-1/2/3 link the
  prover closure (ser_egraph→bv_ring, bv_bits→sat — `build_iiis1.sh:216`).  Floor pinned
  (`BVRING_MIN=3`), archive-link presence checked per build script.
- **Crypto precedents stay wired** (clause D): the forge Keccak root (in-tree `numera/keccak`) and
  the `seal_sources.sh` witness TRIANGLE (III/GNU/Microsoft).
- **Raw-hash ratchet** (clause B): non-witness `sha256sum` lines across the spine script set,
  pinned at the measured **38**, down-only — GNU-authored seals cannot creep back in.
- **The island ledger is down-only** (clause F): 5 named breaches with existence-checked organ
  paths and named discharge welds — `xii-lattice-dead-branch` (discharged by Phase E below),
  `au-conform-island`, `ser-membrane-kat-only`, `zkvm-kat-only`, `forcefield-optimizer-unwired`.
  Adding an island without a reviewed pin edit REDDENS the anchor.

**Geometry's basal seat** is every spatial surface, where it already rules gated: exact predicates
and the Σ√ sign kernel under UI/mech/dynamics (gates 2150–2184), the spatial e-graph as the native
UI, the unified-field derivation.  The census does not fabricate a geometry edge into the linker;
the law binds each organ at its real seat.  Phases E and G below are the next two sanctioned
ledger discharges (XII lattice algebra live in cg_r3; the disassembler as the encoder's proven
inverse).

**Teeth, proven at landing:** census GREEN on the real pins; RED (rc 3) under doctored pins for
both ratchets; FIPS-KAT arm rc 95; lying-author arm rc 97; the stale-ledger arm caught two wrong
organ paths during authoring and forced the correction.

---

# PHASE A — `sovld` routes any Win32 DLL (audit P2b)

**Why first:** smallest, unblocks the GUI/network apps the audit flags as un-linkable sovereignly, and the data structures (`DLL_USED/COUNT/NAMERVA : [u32; 4]`) are already sized for it — only loop bounds and the 2-entry name table are hardcoded to 2. No re-seal (sovld is not in the compiler).

**Consumer that drives it:** a new corpus program that imports `ws2_32` (`WSAStartup`) linked by `sovbuild.sh`; `run_fixpoint.sh` continues to gate self-host.

### Task A1: Generalize `ext_dll_of` to a DLL-id table

**Files:**
- Modify: `STDLIB/sovtc/sovld.iii:82-118` (`ext_dll_of`), `:119-123` (`dll_name_len`,`emit_dll_name`)
- Read first (whole, per discipline): `STDLIB/sovtc/sovld.iii` in full — the `.idata` builder at `:155-260` consumes these.

**Interfaces:**
- Produces: `ext_dll_of(slot:u32) -> u32` now returns a DLL id in `0..NDLL-1` where `NDLL` grows from 2 to 5 (`kernel32=0, msvcrt=1, user32=2, gdi32=3, ws2_32=4`).
- Consumes: `name_eq(slot, lit, len)` (existing, `:72-77` area), `sov_ext_namebyte(slot, i)` (existing).

- [ ] **Step 1: Add the failing gate** — write `STDLIB/sovtc/kats/_sovld_ws2_route.iii` (a probe module) that interns the name `WSAStartup` via the linker's public intern path and asserts `ext_dll_of` returns 4 (ws2_32). Model it on the existing sovld internals; run it through the fixpoint harness pattern. Expected before the fix: returns 1 (msvcrt, via the lowercase fallback) — RED.

```
/* _sovld_ws2_route.iii — teeth for multi-DLL routing (Phase A). */
module sovld_ws2_route_kat
extern @abi(c-msvc-x64) fn sov_cn_clear() -> i32 from "sovas.iii"
extern @abi(c-msvc-x64) fn sov_cn_push(ch: u32) -> i32 from "sovas.iii"
extern @abi(c-msvc-x64) fn sov_ext_intern_pub() -> u32 from "sovas.iii"
extern @abi(c-msvc-x64) fn sovld_ext_dll_of_pub(slot: u32) -> u32 from "sovld.iii"  /* NEW export, Step 3 */
var NM : [u8; 11] = [87u8,83u8,65u8,83u8,116u8,97u8,114u8,116u8,117u8,112u8,0u8] /* "WSAStartup" */
fn main() -> u64 {
    sov_cn_clear()
    let mut i : u64 = 0u64
    while NM[i] != 0u8 { sov_cn_push(NM[i] as u32)  i = i + 1u64 }
    let slot : u32 = sov_ext_intern_pub()
    if sovld_ext_dll_of_pub(slot) != 4u32 { return 1u64 }   /* ws2_32 */
    return 99u64
}
```

- [ ] **Step 2: Run it to confirm RED.** Compile+link via the fixpoint object set (`iiis-2 --compile-only`, gcc-link against `sovld.o sovas.o sovparse.o` for the probe only). Expected: exit 1.

- [ ] **Step 3: Rewrite `ext_dll_of` as an id table + export a public wrapper.** Replace the two hardcoded blocks with an ordered name→id table covering the API names the tree's apps import (enumerate them: `grep -rhoE '"[A-Za-z][A-Za-z0-9]+" as \*u8' STDLIB/iii/aether STDLIB/iii/**/ui_*.iii` for the socket/GDI/user calls). Add ws2_32 (`WSAStartup`,`WSACleanup`,`socket`,`bind`,`listen`,`accept`,`connect`,`send`,`recv`,`closesocket`,`htons`,`inet_addr`,`select`), user32 (`MessageBoxA`,`CreateWindowExA`,`DefWindowProcA`,`GetMessageA`,`DispatchMessageA`,`PostQuitMessage`,`RegisterClassExA`,`LoadCursorA`,`ShowWindow`,`UpdateWindow`), gdi32 (`GetDC`,`BitBlt`,`CreateCompatibleDC`,`SelectObject`,`CreateDIBSection`,`DeleteObject`). Keep the UPPER-first→kernel32 else→msvcrt heuristic as the final fallback. Add `fn sovld_ext_dll_of_pub(slot: u32) -> u32 @export { return ext_dll_of(slot) }`.

- [ ] **Step 4: Run the probe → GREEN (exit 99).**

- [ ] **Step 5: Commit.**
```bash
git add STDLIB/sovtc/sovld.iii STDLIB/sovtc/kats/_sovld_ws2_route.iii
git commit -m "III sovld: DLL routing is a 5-entry id table (kernel32/msvcrt/user32/gdi32/ws2_32), teeth green"
```

### Task A2: Table-drive the `.idata` builder for N DLLs

**Files:**
- Modify: `STDLIB/sovtc/sovld.iii:155-260` (the import-directory builder: the `while d < 2u32` loops at `:165,:168,:179`, `dnum = DLL_USED[0]+DLL_USED[1]` at `:162`, and the import-directory-table writer near `:230-245`).

**Interfaces:**
- Consumes: `DLL_USED/DLL_COUNT/DLL_NAMERVA/DLL_ILTRVA/DLL_IATRVA : [u32; 4]` — **widen every `[u32; 4]` to `[u32; 8]`** (5 DLLs today, headroom to 8; a `var` array grow is safe).
- Produces: an `.idata` with one import descriptor per *used* DLL, in id order.

- [ ] **Step 1: Add the failing gate** — extend `_sovld_ws2_route.iii`'s `main` (or a sibling `_sovld_multidll_link.iii`) to actually be linked into a tiny PE that imports one symbol from ws2_32 AND one from kernel32, driven by `sovbuild.sh` on a new corpus program `STDLIB/corpus/1935_ws2_sovereign.iii` (calls `WSAStartup`/`WSACleanup`, returns 99). Expected before the fix: `sovbuild.sh` links a PE whose import table only names ≤2 DLLs → the loader cannot resolve `WSAStartup` → run exit ≠ 99 (RED).

- [ ] **Step 2: Confirm RED** — `bash STDLIB/sovtc/sovbuild.sh STDLIB/corpus/1935_ws2_sovereign.iii` prints `sovereign=… witness=…` then `RUN exit≠99`.

- [ ] **Step 3: Replace the `< 2u32` loops with `< NDLL` and `DLL_USED[0]+DLL_USED[1]` with a summed loop.** Add `const NDLL : u32 = 5u32`. Rewrite `dll_name_len`/`emit_dll_name` as table lookups over a `DLL_NAMES` byte-pool + `DLL_NAMELEN : [u32; 8]` (append `user32.dll`,`gdi32.dll`,`ws2_32.dll`). The import-directory-table writer (`:230-245`) already iterates `dd`; extend its bound to `NDLL` and its per-DLL RVA math (already per-`d`).

- [ ] **Step 4: GREEN** — `sovbuild.sh …/1935_ws2_sovereign.iii` → `RUN exit=99`.

- [ ] **Step 5: Regression** — `bash STDLIB/sovtc/run_fixpoint.sh` still `ALL PASS` (the 2-DLL self-host path is the `NDLL≥2` special case).

- [ ] **Step 6: Commit.**
```bash
git add STDLIB/sovtc/sovld.iii STDLIB/corpus/1935_ws2_sovereign.iii
git commit -m "III sovld: .idata builder is N-DLL table-driven; ws2_32 app links + runs sovereign (99)"
```

---

# PHASE B — `sovas` encodes the VEX/EVEX the tree actually emits (audit P2a)

**Why:** this is what makes `witness=0` reachable, which is the precondition for a byte-clean default flip (Phase C). **Lean scope, measured from the tree:** exactly 7 modules emit VEX/EVEX (`numera/{bigint,blake2s,chacha20,keccak,poly1305,sha256,sha512}`), and the distinct mnemonic set is ~25: `vpaddd vpaddq vpmuludq vpmullq vpxor vpxord vpxorq vpor vpandq vpslld vpsrld vpsrlq vprold vprord vprolq vpshufd vpermq vpternlogq vpbroadcastq vmovdqu vmovdqu64 vzeroupper` (+ the mem/broadcast operand forms). Encode exactly these.

**Consumer that drives it:** `run_fixpoint.sh`'s `.text == gas` differential cmp, **extended to the 7 SIMD modules**; and `sovbuild.sh`'s witness counter reaching 0 on the crypto closure.

### Task B1: VEX 2-byte / 3-byte prefix emitter core

**Files:**
- Modify: `STDLIB/sovtc/sovas.iii` — add a `── AVX / VEX ──` section after the SSE block (`:273-360` region). Read the whole SSE block first (it establishes the reg/mem operand helpers `sov_modrm`,`sov_membase_modrm`,`sov_sib_modrm_disp`,`sov_rec_reloc` you will reuse verbatim).

**Interfaces:**
- Produces: `sov_vex2(r:u32, vvvv:u32, l:u32, pp:u32)`, `sov_vex3(r:u32,x:u32,b:u32, mmmmm:u32, w:u32, vvvv:u32, l:u32, pp:u32)` — emit the C5/C4 prefix bytes; `sov_vex_rr(op,dst,src1,src2,l,pp,mmmmm,w)` — the reg-reg 3-operand form (`vpxor %s2,%s1,%d` AT&T order → `reg=dst, vvvv=src1, rm=src2`).
- Consumes: `sov_emit(b)`, `sov_modrm(mod,reg,rm)` (existing).

- [ ] **Step 1: Failing byte-KAT.** Add `STDLIB/sovtc/kats/_sovas_vex_bytes.iii`: for each of `vpxor %xmm1,%xmm2,%xmm3`, `vpaddd %ymm4,%ymm5,%ymm6`, `vzeroupper`, call the encoder and `cmp` the produced bytes against the exact gas output (obtain once via `echo 'vpxor %xmm1,%xmm2,%xmm3' | gcc -c -x assembler - -o /tmp/v.o && objdump -d /tmp/v.o` — hardcode the hex as the expected constant, the same way `sov_*` KATs pin gas bytes). Expected: RED (encoder absent).

- [ ] **Step 2: Confirm RED.**

- [ ] **Step 3: Implement `sov_vex2`/`sov_vex3`/`sov_vex_rr`.** VEX.2B = `C5 [~R vvvv L pp]`; VEX.3B = `C4 [~R ~X ~B mmmmm] [W vvvv L pp]`. `pp`: none=0, 66=1, F3=2, F2=3. `mmmmm`: 0F=1, 0F38=2, 0F3A=3. Use 2-byte form when `x==0 && b==0 && w==0 && mmmmm==1`, else 3-byte (the gas selection rule — verify byte-identity against gas per mnemonic).
```
fn sov_vex2(r: u32, vvvv: u32, l: u32, pp: u32) {
    sov_emit(0xC5u32)
    let rr : u32 = (1u32 - r) & 1u32
    sov_emit((rr << 7u32) | (((15u32 - (vvvv & 15u32)) & 15u32) << 3u32) | ((l & 1u32) << 2u32) | (pp & 3u32))
}
fn sov_vex3(r: u32, x: u32, b: u32, mmmmm: u32, w: u32, vvvv: u32, l: u32, pp: u32) {
    sov_emit(0xC4u32)
    sov_emit((((1u32-r)&1u32) << 7u32) | (((1u32-x)&1u32) << 6u32) | (((1u32-b)&1u32) << 5u32) | (mmmmm & 31u32))
    sov_emit(((w & 1u32) << 7u32) | (((15u32-(vvvv&15u32))&15u32) << 3u32) | ((l & 1u32) << 2u32) | (pp & 3u32))
}
```

- [ ] **Step 4: GREEN on the 3-instruction KAT.**

- [ ] **Step 5: Commit.**
```bash
git add STDLIB/sovtc/sovas.iii STDLIB/sovtc/kats/_sovas_vex_bytes.iii
git commit -m "III sovas: VEX 2B/3B prefix core + vpxor/vpaddd/vzeroupper byte-identical to gas"
```

### Task B2: The VEX mnemonic table the crypto tree emits

**Files:**
- Modify: `STDLIB/sovtc/sovas.iii` (extend the AVX section); the `.o.s` parser dispatch (find the mnemonic-dispatch in `sovas.iii` where `vpaddd`/etc. text must map to the encoder — grep `sov_movdqu_rr\|mnemonic\|parse` to locate the parser's opcode switch).

**Interfaces:**
- Produces one `@export fn sov_<mnem>_…` per mnemonic in the measured set, each in the reg-reg, reg-mem(disp/base), and rip-relative forms the modules use (mirror the existing `sov_movdqu_{rr,load_base,store_base,load_rip_sym,load_sib}` family). imm8 forms for `vpshufd/vpermq/vprold/vprord/vprolq/vpternlogq`.

- [ ] **Step 1: Failing differential** — extend `run_fixpoint.sh`'s per-module `.text == gas` loop to include the 7 SIMD modules. Add them to the module list; expected RED (sovas can't yet encode → `.text` differs / sovas errors on the mnemonic).

- [ ] **Step 2: Confirm RED** — `bash STDLIB/sovtc/run_fixpoint.sh` prints `FAIL sov-assemble numera_sha256 differs from gas`.

- [ ] **Step 3: Implement the mnemonic set** (VEX.128/256, pp/mmmmm/w per Intel SDM Vol 2). Wire each into the parser's opcode dispatch. Encode ONLY these mnemonics; a mnemonic outside the set must still cleanly error (nonzero exit) so `sovbuild.sh` counts it as a witness rather than mis-encoding. EVEX-only forms (`vmovdqu64 vpxord vpxorq vpandq vprold vprord vprolq vpmullq vpbroadcastq vpternlogq`) route to Task B3.

- [ ] **Step 4: partial GREEN** — the VEX-encodable subset of the 7 modules now matches gas; EVEX ones still RED (Task B3).

- [ ] **Step 5: Commit.**
```bash
git add STDLIB/sovtc/sovas.iii STDLIB/sovtc/run_fixpoint.sh
git commit -m "III sovas: VEX mnemonic set (vpaddd/vpxor/vpshufd/vpermq/... reg/mem/rip); fixpoint extended to SIMD modules"
```

### Task B3: EVEX 4-byte prefix + the AVX-512 forms the tree emits

**Files:**
- Modify: `STDLIB/sovtc/sovas.iii` (add `── EVEX / AVX-512 ──`).

**Interfaces:**
- Produces: `sov_evex(r,x,b,r2, mmm, w, vvvv, pp, z,l2,l1,bcast,v2,aaa)` — the 4-byte `62 [P0 P1 P2]` prefix; and `sov_<mnem>` for `vmovdqu64 vpxord vpxorq vpandq vprold vprord vprolq vpmullq vpbroadcastq vpternlogq` in the forms used (note `vpternlogq` takes imm8; `vpbroadcastq` broadcasts a GPR/mem).

- [ ] **Step 1: Failing byte-KAT** — add `vpternlogq $0x96,%zmm1,%zmm2,%zmm3` and `vmovdqu64 %zmm4,%zmm5` to `_sovas_vex_bytes.iii` with gas-pinned expected bytes. RED.

- [ ] **Step 2: Confirm RED.**

- [ ] **Step 3: Implement `sov_evex` + the 10 EVEX mnemonics.** EVEX = `62 [~R ~X ~B ~R2 0 0 mmm] [W vvvv 1 pp] [z L2 L1 b ~V2 aaa]`. For the crypto forms: `aaa=0` (no masking), `z=0`, `b=0` (no broadcast except `vpbroadcastq`), `L1L2` = 512-bit → `10`. Verify each against gas byte-for-byte.

- [ ] **Step 4: GREEN** — `_sovas_vex_bytes.iii` exit 99, AND `run_fixpoint.sh` now `PASS sov-assemble` on all 7 SIMD modules.

- [ ] **Step 5: The witness-zero gate** — run `bash STDLIB/sovtc/sovbuild.sh STDLIB/corpus/<a crypto program that pulls sha256+sha512+keccak>.iii`; assert the manifest line reads `sovereign=N witness=0`. Add this assertion as a new gate `STDLIB/sovtc/witness_zero_gate.sh` (greps the manifest for `witness=0`, captures rc directly).

- [ ] **Step 6: Commit.**
```bash
git add STDLIB/sovtc/sovas.iii STDLIB/sovtc/kats/_sovas_vex_bytes.iii STDLIB/sovtc/witness_zero_gate.sh
git commit -m "III sovas: EVEX/AVX-512 tail (vpternlogq/vmovdqu64/vpxord/...); crypto closure witness=0, .text==gas on all 7 SIMD modules"
```

---

# PHASE C — `emit.iii` IS the sovereign emitter; default flips; chain re-seals (audit P1)

**Ontological core:** `emit.iii` stops *shelling out to* an assembler/linker and *becomes* the assembler/linker. `sovas_main.iii`/`sovlink_main.iii` are the file-boundary shells around the `sov_*` core; their capability folds into `emit.iii`'s nature. gcc/ld demote from spine to an explicit `--emit=witness` opt-out kept only for differential auditing.

**Cost, named (this is the ADR):** folding `sovtc` into the compiler changes `iiis-1/2/3` golden mhashes → the seed-identity + fixpoint chain must **re-seal in the same commit**, and the new goldens must reproduce green. This is why Phases A+B (witness=0, `.text==gas`) come first: the fold is only byte-clean when the sovereign path already reproduces gas exactly. **Rejected alternative:** keep the sovereign path as `sovbuild.sh` only (no fold) — rejected because the audit's claim is that the *default emit path* (i.e. `iiis-2 foo.iii -o foo.exe`) is sovereign, which is false unless `emit.iii` itself routes sovereignly; an out-of-compiler orchestrator leaves the compiler's own emit on gcc.

### Task C1: Put `sovtc` into `libiii_native.a`

**Files:**
- Modify: `STDLIB/scripts/build_stdlib.sh` — add `sovas sovparse sovcoff sovld` to the module build list so their `.o` enter the archive both `iiis-1` and `iiis-2` link. Read `build_stdlib.sh`'s MODULES ordering block first; place `sovtc` after its deps (`sovas` before `sovld`, `sovparse` before `sovld`).

- [ ] **Step 1:** confirm current absence — `grep -c sovas STDLIB/scripts/build_stdlib.sh` → expect 0.
- [ ] **Step 2:** add the four modules to the ordered list with a comment: `# sovtc: the sovereign toolchain, now linked INTO the compiler (emit.iii calls sov_* in-process)`.
- [ ] **Step 3:** `bash STDLIB/scripts/build_stdlib.sh --clean && bash STDLIB/scripts/build_stdlib.sh`; grep `FAIL = 0` (not rc). Expect the four new `OK` lines and the archive to contain `sovas.iii.o` (`ar t STDLIB/build/iii/libiii_native.a | grep sovas`).
- [ ] **Step 4: Commit.**
```bash
git add STDLIB/scripts/build_stdlib.sh
git commit -m "III stdlib: sovtc (sovas/sovparse/sovcoff/sovld) enters libiii_native.a — prerequisite for the in-process emit fold"
```

### Task C2: `emit.iii` gains a sovereign assemble path behind `--emit`

**Files:**
- Modify: `COMPILER/BOOT/emit.iii` — add `iii_emit_assemble_sovereign(asm_path, out_obj_path)` mirroring `sovas_main.iii`'s file→`sov_*`→COFF flow; keep `iii_emit_assemble` (the gcc path) intact, renamed in spirit to the witness path. Add a module-level `G_EMIT_MODE : u32` (0=sovereign default, 1=witness/gcc) and `iii_emit_set_mode(m)`.
- Modify: `COMPILER/BOOT/main.iii:~694,~931,~942` — parse `--emit=sovereign|witness` (default sovereign), call `iii_emit_set_mode`, and route `iii_emit_assemble` → the mode-dispatcher.
- Read first (whole): `STDLIB/sovtc/sovas_main.iii` (the orchestration you are absorbing) and `emit.iii:872-1046` (both current shell-outs).

**Interfaces:**
- Consumes (all already `@export` in the now-linked `sovtc`): `sov_reset`, `sov_data_reset`, the parser entry that drives `sovas` over a `.o.s` buffer (the function `sovas_main.iii` calls — identify it), `sovcoff`'s `.o` writer.
- Produces: `iii_emit_assemble_sovereign(asm_path:u64, out_obj_path:u64) -> u32` returning `III_EMIT_OK`/error, byte-identical `.o` to the gcc path's `.text`.

- [ ] **Step 1: Failing test** — add `COMPILER/BOOT/emit_sovereign_gate.sh`: compile a trivial `.iii` (`prog_sat.iii`) with `iiis-2 --compile-only` to `.o.s`, then call the new sovereign assemble (via a tiny harness or `sovas_main` as proxy) and `cmp .text` against the gcc-assembled `.o`. Expected RED (function absent).
- [ ] **Step 2: Confirm RED.**
- [ ] **Step 3: Implement `iii_emit_assemble_sovereign`** by absorbing `sovas_main.iii`'s read→assemble→emit-COFF sequence, calling the in-process `sov_*` exports; write the `.o` with `emit.iii`'s existing file-write helpers. Add the `G_EMIT_MODE` dispatcher in `iii_emit_assemble`.
- [ ] **Step 4: GREEN** — `.text` byte-identical to gcc on `prog_sat`.
- [ ] **Step 5:** DO NOT rebuild the compiler yet (that is C4). Commit the source change.
```bash
git add COMPILER/BOOT/emit.iii COMPILER/BOOT/main.iii COMPILER/BOOT/emit_sovereign_gate.sh
git commit -m "III emit.iii: in-process sovereign assemble path (--emit=sovereign default; witness=gcc opt-out); byte-identical .o proven"
```

### Task C3: `emit.iii` links sovereignly via `sovld` in-process

**Files:**
- Modify: `COMPILER/BOOT/emit.iii:912-1046` (`iii_emit_link`) — add `iii_emit_link_sovereign(...)` absorbing `sovlink_main.iii`; route through `G_EMIT_MODE`.
- Read first: `STDLIB/sovtc/sovlink_main.iii` in full.

- [ ] **Step 1: Failing test** — extend `emit_sovereign_gate.sh` to link `prog_sat` sovereignly in-process and assert the PE runs to its expected exit (99). RED.
- [ ] **Step 2: Confirm RED.**
- [ ] **Step 3: Implement** `iii_emit_link_sovereign` from `sovlink_main.iii`'s orchestration (gather objs → `sovld` → PE). Sanctum format path stays on the witness linker for now (it uses a linker script; note it as a scoped residual in the gate output — no silent cap).
- [ ] **Step 4: GREEN** — `prog_sat.exe` built end-to-end in-process, runs exit 99.
- [ ] **Step 5: Commit.**
```bash
git add COMPILER/BOOT/emit.iii COMPILER/BOOT/emit_sovereign_gate.sh
git commit -m "III emit.iii: in-process sovereign link via sovld; prog_sat builds+runs sovereign end-to-end from the compiler itself"
```

### Task C4: Re-seal the bootstrap chain with the sovereign-emitter compiler

**Files:**
- Modify (regenerated, not hand-edited): `COMPILER/BOOT/iiis-1.mhash`, `iiis-2.mhash`, `iiis-3.mhash` — the sealed goldens.
- Modify: `DOCS/III-INDEPENDENCE-AUDIT.md` §1 table row 40 (`default pipeline avoids gcc` → **Yes**) and §5 P1 → DONE, and `DOCS/III-SOVEREIGN-TOOLCHAIN.md` if present.

- [ ] **Step 1:** Run the full chain in the sandbox clone: `build_iiis0 → build_stdlib → build_iiis1 → build_iiis2`. The new `iiis-1/2` mhashes differ from the sealed goldens (expected — intentional change). Record both.
- [ ] **Step 2:** Re-seal: update the three `.mhash` goldens to the new reproducible values (this is the `build_iiis1.sh:238` "intentional changes require re-sealing" path). Re-run twice to confirm byte-stability (determinism).
- [ ] **Step 3: THE ANCHOR GATE** — `bash COMPILER/BOOT/bootstrap_from_clean.sh` on a pristine clone → 6/6 GREEN with the re-sealed goldens. Then the harder gate: **remove gcc/ld/gas from PATH** and re-run stages 2+4+6 (assemble+link now in-process sovereign); every program still compiles, links, hits its exit. Capture rc directly.
- [ ] **Step 4:** `run_corpus` with gcc off PATH — every corpus program green (the audit DoD's "rebuilds the full stdlib + passes run_corpus + links through sovld").
- [ ] **Step 5: Commit (the flip).**
```bash
git add COMPILER/BOOT/iiis-1.mhash COMPILER/BOOT/iiis-2.mhash COMPILER/BOOT/iiis-3.mhash DOCS/III-INDEPENDENCE-AUDIT.md
git commit -m "III P1 DONE: sovereign emit is the DEFAULT; compiler chain re-sealed; bootstrap_from_clean 6/6 GREEN with gcc OFF PATH"
```

---

# PHASE D — Self-mint the sovereign tools; drop the last gcc bootstrap (audit P3)

**Why:** after C, the compiler emits sovereignly, but `run_fixpoint.sh`/`sovbuild.sh` still `gcc`-link the *gen-1 tool binaries* (`sovas_main.exe`, `sovlink_main.exe`). Mint them from a committed, mhash-sealed gen-0 seed — the exact role `iiis-0` plays for the compiler.

**Consumer that drives it:** `run_fixpoint.sh` with gcc removed from PATH must still `ALL PASS`.

### Task D1: Seal a gen-0 `sovas_main.exe`/`sovlink_main.exe`

**Files:**
- Create: `STDLIB/sovtc/seed/sovas_main.seed.exe`, `sovlink_main.seed.exe` (committed binaries), `STDLIB/sovtc/seed/sovseed.mhash` (their sha256).
- Modify: `STDLIB/sovtc/run_fixpoint.sh:~35-40`, `STDLIB/sovtc/sovbuild.sh` `ensure_tools()` — replace the `gcc … -o sovas_main.exe` / `-o sovlink_main.exe` lines with: assemble the tool `.o.s` via the **sealed gen-0 seed exe**, link via the sealed seed linker; assert the seed mhash before use.

- [ ] **Step 1:** Build today's gen-1 `sovas_main.exe`/`sovlink_main.exe` once (still via gcc), verify they self-host (`run_fixpoint` green), then freeze them as the `.seed.exe` seeds and record `sovseed.mhash`.
- [ ] **Step 2: Failing gate** — rewrite `run_fixpoint.sh` bootstrap to use the seeds; add `command -v gcc` guard that, when gcc is ABSENT, must still reach `ALL PASS`. Run with gcc temporarily off PATH BEFORE wiring the seed → RED (`FAIL gen1 sovas_main`).
- [ ] **Step 3: Confirm RED.**
- [ ] **Step 4:** Wire the seed-mint: `"$SEED/sovas_main.seed.exe" "$OUT/sovas.o.s" > … ` etc.; assert the seed seals via `mhash_file` (source `COMPILER/BOOT/mhash_lib.sh` — sovereign-authored, GNU-witnessed, per the Phase-⊥ SEAL AUTHORSHIP constraint) against `sovseed.mhash` before running it (fail-closed on tamper).
- [ ] **Step 5: GREEN with gcc OFF PATH** — `run_fixpoint.sh` `ALL PASS`; the gen-2 tools are byte-identical to the sealed seeds (the fixpoint proves the seed reproduces itself).
- [ ] **Step 6:** Update `sovbuild.sh ensure_tools()` identically; `sovbuild.sh <crypto program>` with gcc off PATH → `witness=0`, runs 99.
- [ ] **Step 7: Commit.**
```bash
git add STDLIB/sovtc/seed/ STDLIB/sovtc/run_fixpoint.sh STDLIB/sovtc/sovbuild.sh
git commit -m "III P3: sovereign tools self-mint from a sealed gen-0 seed; run_fixpoint + sovbuild ALL PASS with gcc OFF PATH"
```

### Task D2: Fold the toolchain gate into the anchor

**Files:**
- Modify: `COMPILER/BOOT/bootstrap_from_clean.sh` — add **stage 8: `run_fixpoint.sh` (gcc off PATH)** and **stage 9: `witness_zero_gate.sh`** after the basal-census stage (stage 7, landed in Phase ⊥), so the anchor proves toolchain self-host + witness-zero every run.

- [ ] **Step 1:** add stages 8/9 with the same `run_stage` discipline (rc captured directly, log tail on fail).
- [ ] **Step 2:** pristine-clone run → 9/9 GREEN.
- [ ] **Step 3: Commit.**
```bash
git add COMPILER/BOOT/bootstrap_from_clean.sh
git commit -m "III anchor: bootstrap_from_clean now 8/8 — adds sovereign-toolchain self-host + witness-zero stages"
```

---

# PHASE E — XII is the operative optimizer, not a dead branch (audit §4, P5)

**Decision (make-good, not retire):** the owner's mandate is to make the overclaims true. XII is documented as the operative fixed point; so **wire it**, don't relabel it. The minimum that makes `III-XII.md:1789` ("cg_r3 … wired and pass all corpus") literally true is: at least one real corpus program carries `@lattice`, the `cg_r3.iii:3574` gate takes the XII branch on it, the `r3_pe_canonicalise → r3_compute_circ → r3_pe_lattice_emit` path emits real bytes, and a differential gate proves the XII path ran (not the legacy path) AND the program still runs correctly.

**Consumer that drives it:** a new corpus program + a byte-disassembly gate (the audit names "Corpus test 360 e2e demo byte-disassembly audit" as the intended witness).

### Task E1: A real `@lattice` corpus program that must take the XII branch

**Files:**
- Create: `STDLIB/corpus/1936_xii_lattice_live.iii` — a small function annotated `@lattice` whose body is a static-circumstance computation XII should canonicalize + inline, returning a known value (exit 99).
- Read first: `cg_r3.iii:3569-3583` (the gate), `cg_r3_xii.iii` (the emit path), `xii_ldil.iii` (the fill), `DOCS/III-XII.md` §16 (the LDIL contract).

- [ ] **Step 1: Failing gate** — `COMPILER/BOOT/xii_live_gate.sh`: compile `1936_xii_lattice_live.iii`, disassemble the `@lattice` function, assert the XII call-site descriptor / inlined-cell byte-signature is present (the `r3_pe_lattice_emit` NOP-placeholder + descriptor), AND the program runs exit 99. Expected RED today (no `@lattice` in corpus → gate never taken → descriptor absent).
- [ ] **Step 2: Confirm RED** — disasm shows the legacy `r3_emit_block` output, no XII descriptor.
- [ ] **Step 3:** Make the pipeline actually emit. Walk `r3_pe_canonicalise/r3_compute_circ/r3_pe_lattice_emit` (in `cg_r3_xii.iii` via the adapter) and the `xii_ldil.iii` fill; complete whatever the "staged: requires the AST→XII-term mapper and sealed-Lattice-cell-store to land" note (`cg_r3.iii:1771`) actually leaves unfinished — the mapper `r3_ast_to_xii_term` and the cell store. Minimal real path: canonicalize the annotated body to an XII term, select a productive horizon, inline its sealed cell bytes (or emit the descriptor + LDIL fill).
- [ ] **Step 4: GREEN** — disasm shows the XII descriptor/inlined cell; program exits 99; determinism gate byte-stable.
- [ ] **Step 5: Corpus regression** — full `run_corpus` green (the XII branch fires ONLY on the annotated program; every other program unchanged — prove by byte-diffing a sample of non-XII `.o` before/after).
- [ ] **Step 6: Commit.**
```bash
git add STDLIB/corpus/1936_xii_lattice_live.iii COMPILER/BOOT/cg_r3_xii.iii COMPILER/BOOT/xii_ldil.iii COMPILER/BOOT/xii_live_gate.sh
git commit -m "III XII: @lattice is LIVE — cg_r3 gate takes the XII path on corpus 1936; LDIL emits+inlines; byte-disasm gate green"
```

### Task E2: Make `III-XII.md` prose match the machinery

**Files:**
- Modify: `DOCS/III-XII.md:33` ("fixed point"), `:1789` (C-XII-28), and the `cg_r3.iii:1772` comment ("no source file uses @lattice and this returns 0" → "corpus 1936 exercises this; `xii_live_gate.sh` gates it").
- Modify: `DOCS/III-INDEPENDENCE-AUDIT.md` §4 XII cluster (dead-branch finding → **wired, gated by `xii_live_gate.sh`**).

- [ ] **Step 1:** rewrite the three prose sites to state exactly what is now true (one live gate, one corpus program, the descriptor byte-signature) — no more, no less. Delete "fixed point" where it overclaims universality; keep it only where the rewrite theorem (`CRY-XII-DEC-001`) actually holds.
- [ ] **Step 2:** grep the docs for other `@lattice`/"wired"/"fixed point" claims; truth them or cite the gate.
- [ ] **Step 3: Commit.**
```bash
git add DOCS/III-XII.md DOCS/III-INDEPENDENCE-AUDIT.md COMPILER/BOOT/cg_r3.iii
git commit -m "III XII docs: prose matches machinery — 'operative on the gated path' replaces 'fixed point' overclaim; cg_r3 comment cites the live gate"
```

---

# PHASE F — Post-quantum crypto gated on official NIST vectors (audit §4, P5)

**The one legitimate external input:** published NIST FIPS-203/204/205 (ML-KEM/ML-DSA/SLH-DSA) KAT vectors, embedded as constants exactly as the SHA-256 KAT embeds FIPS-180. This makes "PQ crypto matches the NIST ACVP vectors" true instead of "PQ crypto is internally deterministic."

**Consumer that drives it:** new corpus KAT programs pinning official expected bytes; wired into `run_corpus`.

### Task F1: ML-KEM (FIPS 203) known-answer test

**Files:**
- Create: `STDLIB/corpus/1937_mlkem_nist_kat.iii` — pins one official ACVP vector: given the exact `d||z` keygen seed, assert `ek`/`dk` match; given the exact encaps `m`, assert `c`/`K` match. Return 99 iff all bytes match; distinct non-99 codes per mismatch stage.
- Reference: the NIST ACVP-server ML-KEM vectors (`gen-val` known-answer set) or the FIPS-203 IPD KAT files. Embed the first vector's bytes as `var` arrays (like `02_sha256_kat_abc.iii` embeds "abc").

- [ ] **Step 1:** obtain one official ML-KEM-768 KAT triple (seed, expected ek/dk, expected c/K) from the NIST ACVP vector set; record provenance (URL + vector id) in the file header.
- [ ] **Step 2: Failing test** — write the KAT calling `iii_mlkem_keygen/encaps/decaps` (the module's public surface, `mlkem.iii`); expected RED only if the module diverges from NIST (it may already pass — if so this converts an *ungated* capability into a *gated* one, which is the point; the test still must be able to go RED — prove by perturbing one expected byte and seeing non-99).
- [ ] **Step 3:** if the module diverges, root-cause per systematic-debugging (the module claims byte-compat with the C ref "for cross-KAT" — the divergence, if any, is a real bug); fix `mlkem.iii`. If it already matches, no code change — the gate is the deliverable.
- [ ] **Step 4: GREEN** — exit 99; the byte-perturbation control goes non-99 (teeth).
- [ ] **Step 5: Commit.**
```bash
git add STDLIB/corpus/1937_mlkem_nist_kat.iii STDLIB/iii/numera/mlkem.iii
git commit -m "III PQ: ML-KEM-768 gated on official NIST FIPS-203 ACVP vector (keygen+encaps+decaps byte-exact); teeth proven"
```

### Task F2: ML-DSA (FIPS 204) and SLH-DSA (FIPS 205) KATs

**Files:**
- Create: `STDLIB/corpus/1938_mldsa_nist_kat.iii`, `STDLIB/corpus/1939_slhdsa_nist_kat.iii` — same pattern (deterministic-signing KAT: fixed seed + message → exact signature bytes; verify accepts; a flipped signature byte → verify rejects).
- Modify (only if divergence): `STDLIB/iii/numera/mldsa.iii`, `slhdsa.iii`.

- [ ] **Step 1:** obtain one official ML-DSA-65 and one SLH-DSA-SHA2-128s deterministic KAT each; header provenance.
- [ ] **Step 2: Failing tests** (or perturbation-teeth if already matching).
- [ ] **Step 3:** fix module(s) only on real divergence.
- [ ] **Step 4: GREEN** both; verify-reject control fires.
- [ ] **Step 5:** update `DOCS/III-INDEPENDENCE-AUDIT.md` §4 PQ cluster (`no NIST KAT vectors` → **gated on FIPS-203/204/205 ACVP vectors, corpus 1937-1939**) and the §7 gaps list item 1 (PQ line → fixed).
- [ ] **Step 6: Commit.**
```bash
git add STDLIB/corpus/1938_mldsa_nist_kat.iii STDLIB/corpus/1939_slhdsa_nist_kat.iii STDLIB/iii/numera/mldsa.iii STDLIB/iii/numera/slhdsa.iii DOCS/III-INDEPENDENCE-AUDIT.md
git commit -m "III PQ: ML-DSA-65 + SLH-DSA-128s gated on official NIST vectors; audit PQ gap closed"
```

---

# PHASE G — Real transpiler + real decoder (audit §4, P5)

### Task G1: `tp_x86_disasm` becomes the inverse of the (now-complete) encoder

**Why enmeshed, not island:** after Phase B, `sovas` encodes a known instruction set. The honest disassembler is precisely its inverse — decode exactly what `sovas`/`cg_r3` emit. **Round-trip gate:** `disasm(assemble(mnem)) == mnem` and `assemble(disasm(bytes)) == bytes` over the corpus `.o.s` instruction stream.

**Files:**
- Rewrite: `STDLIB/iii/omnia/tp_x86_disasm.iii` (currently 74 lines emitting `.byte` directives) — a real length-decoder + mnemonic printer for the REX/ModRM/SIB/VEX/EVEX forms the tree emits.
- Consumer: `STDLIB/iii/omnia/tp_x86_assemble.iii` (the existing round-trip partner) + a new gate.

- [ ] **Step 1: Failing round-trip gate** — `STDLIB/corpus/1940_disasm_roundtrip.iii`: take a byte sequence for `mov`/`add`/`callq`/`vpxor`, disassemble to mnemonic text, re-assemble via `tp_x86_assemble`/`sovas`, assert byte-identity. RED (current disasm emits `.byte`, which re-assembles to itself but is not a decode — detect by asserting the disasm output contains the mnemonic string `"mov"`, not `".byte"`).
- [ ] **Step 2: Confirm RED.**
- [ ] **Step 3:** implement the decoder: prefix/REX/VEX/EVEX classification → opcode table (shared with `sovas`'s encoder table — factor the opcode↔mnemonic map into one place so encoder and decoder cannot drift) → ModRM/SIB/disp/imm length + operand render. Lean = exactly the forms in the corpus stream.
- [ ] **Step 4: GREEN** — round-trip byte-identical on the sampled stream; output is real mnemonics.
- [ ] **Step 5:** point the XII byte-disasm gate (`xii_live_gate.sh`, Phase E) at this real decoder instead of a hand-rolled hex check — the disassembler now serves an existing consumer.
- [ ] **Step 6: Commit.**
```bash
git add STDLIB/iii/omnia/tp_x86_disasm.iii STDLIB/corpus/1940_disasm_roundtrip.iii COMPILER/BOOT/xii_live_gate.sh
git commit -m "III codec: tp_x86_disasm is a real decoder (inverse of sovas); round-trip byte-gated; drives the XII disasm gate"
```

### Task G2: `tp_iii_to_c99` becomes a real transpiler over the exercised construct set

**Files:**
- Rewrite: `STDLIB/iii/omnia/tp_iii_to_c99.iii` (currently 98 lines wrapping source as a C string) — emit real C99 per III construct, bounded to the constructs the corpus round-trip exercises.
- Consumer: `STDLIB/iii/omnia/transform_patterns.iii` (registers slot 26) + a new round-trip gate that compiles the emitted C with the witness gcc and runs it.

- [ ] **Step 1: Failing gate** — `STDLIB/corpus/1941_c99_transpile.iii`: transpile a small III function (`fn add(a,b)->u64 { return a+b }`), assert the output is real C (`grep` for `uint64_t add` / `return a + b`, NOT `static const char* iii_source`). RED.
- [ ] **Step 2: Confirm RED.**
- [ ] **Step 3:** implement the construct-directed transpile (fn decl→C fn, `let`→typed local, arithmetic/compare/call/`if`/`while`/`return` → C equivalents), bounded to the corpus's construct set; a construct outside the set fails loudly (no silent byte-wrap fallback).
- [ ] **Step 4: GREEN** — output is real C; a witness-gcc compile+run of the emitted C reproduces the III program's result (round-trip semantic gate).
- [ ] **Step 5:** update `DOCS/III-INDEPENDENCE-AUDIT.md` §4 codec cluster (`byte-wraps` / `byte-dumps` → **real transpile/decode, round-trip gated, corpus 1940-1941**).
- [ ] **Step 6: Commit.**
```bash
git add STDLIB/iii/omnia/tp_iii_to_c99.iii STDLIB/corpus/1941_c99_transpile.iii DOCS/III-INDEPENDENCE-AUDIT.md
git commit -m "III codec: tp_iii_to_c99 is a real construct-directed transpiler; semantic round-trip gated via witness gcc; audit codec gap closed"
```

---

# PHASE H — Provenance-tag honesty (audit §7 item 3)

**The fact (verified §0):** 779 `from "*.c"` tags name `.c` files that do not exist; the symbols are `@export`-defined in `.iii` and resolved by NAME at link time — the string is provenance metadata the compiler does NOT open. So the rewrite is mechanical and a full rebuild is the safety gate.

**Consumer that drives it:** a new down-only ratchet `provenance_gate.sh` that greps the tree for `from "…​.c"` and fails on any count above its pin (target pin 0).

### Task H1: Prove the tag is advisory, then bulk-rewrite

**Files:**
- Modify: every `.iii` under `COMPILER/BOOT` and `STDLIB/iii` carrying `from "X.c"` → `from "X.iii"` (the real providing module) where a same-named `.iii` exports the symbol; where the provider is a host DLL the tag already says `msvcrt`/`kernel32` (leave those). Map each `X.c` to its real `X.iii` by the exported symbol.
- Create: `STDLIB/scripts/provenance_gate.sh`, `STDLIB/scripts/provenance_pin.txt`.

- [ ] **Step 1: Falsify the "advisory" claim cheaply FIRST** (debug-systematic): pick ONE tag (`sema.iii:26 from "ast.c"`), rewrite to `from "ast.iii"`, rebuild `iiis-1` + run the identity gate. If byte-identical → the tag is advisory (safe to bulk-rewrite). If it breaks → STOP; the tag is load-bearing and the whole approach changes. Expected: byte-identical.
- [ ] **Step 2:** build the `X.c → X.iii` map: for each distinct `.c` tag, `grep -rl "@export.*<a symbol it provides>"` to find the real `.iii`. Record the map in the gate's header (auditable).
- [ ] **Step 3: Bulk-rewrite** with a single, reviewed substitution per distinct tag (avoid the `replace_all` double-application trap: patterns are `from "ast.c"`→`from "ast.iii"`, non-overlapping). Do NOT touch `msvcrt`/`kernel32`/`.iii` tags.
- [ ] **Step 4: THE SAFETY GATE** — `bootstrap_from_clean.sh` full run (8/8) on a pristine clone. Byte-identical goldens (the tags are advisory, so codegen is unchanged — if a golden moves, a tag was load-bearing → revert that one, investigate). This is the real proof.
- [ ] **Step 5:** write `provenance_gate.sh` (grep `from "[^"]*\.c"` across `COMPILER STDLIB`, count, compare to `provenance_pin.txt`; capture rc directly; down-only). Set pin to the post-rewrite count (target 0). Add it as **stage 10** of `bootstrap_from_clean.sh`.
- [ ] **Step 6: Commit.**
```bash
git add COMPILER/BOOT/*.iii STDLIB/iii/**/*.iii STDLIB/scripts/provenance_gate.sh STDLIB/scripts/provenance_pin.txt COMPILER/BOOT/bootstrap_from_clean.sh
git commit -m "III provenance: 779 phantom from-\"*.c\" tags rewritten to real .iii providers; provenance_gate ratchet (pin 0) is bootstrap stage 9; chain byte-identical"
```

---

# CROSS-CUTTING — the closure gate and the audit's Definition-of-Done

### Task Z1: `bootstrap_from_clean.sh` is the single closure gate (10 stages)

By the end, the anchor gate proves the entire audit DoD in one green run on a **gcc-free** pristine clone:

| Stage | Proves | Phase |
|-------|--------|-------|
| 1 seed | C seed rebuilds | P0 (done) |
| 2 stdlib (+2b seal retro-attest) | 714 modules + 3 ratchets + **sovtc in archive**; seed seal sovereignly co-signed | C1 / ⊥ (2b LANDED) |
| 3 iiis-1 golden | mixed stage reproduces, sovereign-sealed | P0 / re-seal C4 |
| 4 iiis-2 golden+corpus | **sovereign-emitter** compiler reproduces | C4 |
| 5 seed↔self-host identity | `.text` identity | P0 |
| 6 fixpoint | iiis-2==iiis-3 | P0 / C4 |
| 7 basal census | THE BASAL LAW: sovereign seal authorship, algebra-in-codegen floor, island-breach ledger down-only | ⊥ (LANDED) |
| 8 sovereign toolchain self-host | `run_fixpoint` gcc-off-PATH | D2 |
| 9 witness-zero | crypto closure `witness=0` | D2 / B3 |
| 10 provenance | zero phantom `.c` tags | H1 |

- [ ] **Step 1:** confirm all 9 stages green on a pristine clone **with gcc/ld/gas removed from PATH** (the owner's literal bar).
- [ ] **Step 2:** final audit reconciliation — `DOCS/III-INDEPENDENCE-AUDIT.md` §1 headline, §5 P1/P2/P3/P5 → DONE, §7 gaps 1-4 → closed, and the "distance to independence" paragraph rewritten to what (if anything) remains (P4 Thompson seed-DDC, the one honestly-external residual needing a second-lineage C compiler — out of scope here, explicitly).
- [ ] **Step 3: Commit.**
```bash
git add DOCS/III-INDEPENDENCE-AUDIT.md
git commit -m "III independence: audit reconciled — P1/P2/P3/P5 closed; bootstrap_from_clean 9/9 GREEN with gcc OFF PATH; only P4 (second-lineage seed-DDC) remains, scoped"
```

---

## Self-Review (run against the audit's §5 + §7)

**Spec coverage:**
- P1 default sovereign emit → Phase C (C1-C4). ✓
- P2 sovas Tier-2 VEX/EVEX → Phase B (B1-B3), witness=0 gate. ✓
- P2b sovld multi-DLL → Phase A (A1-A2). ✓  *(A is P2b, split from the audit's P2 for correct sequencing.)*
- P3 self-mint tools → Phase D. ✓
- P5 XII wired → Phase E; codecs → Phase G; PQ-KAT → Phase F. ✓
- Provenance honesty (§7.3) → Phase H. ✓
- P4 Thompson seed-DDC → explicitly OUT OF SCOPE (needs a second-lineage C compiler on the host; named in Z1 as the sole remaining residual). ✓ (gap acknowledged, not silently dropped)

**Placeholder scan:** no "TBD"/"add error handling"/"similar to". Each task names exact files, the RED→GREEN cycle, the gate, and the commit. The two places that legitimately require *fetching external data* (NIST vectors, F1/F2) name the exact source and vector and embed-as-constant method — not a placeholder, a bounded acquisition step.

**Type/name consistency:** `iii_emit_set_mode`/`G_EMIT_MODE`/`iii_emit_assemble_sovereign`/`iii_emit_link_sovereign` used consistently C2↔C3↔C4; `sovld_ext_dll_of_pub` defined A1, consumed A1 test; `witness_zero_gate.sh` defined B3, wired D2; `xii_live_gate.sh` defined E1, repointed G1; `provenance_gate.sh` defined H1, wired as stage 9. Consistent.

**Ordering soundness (the discriminating decision):** A+B (complete+witness-free sovereign path) precede C (fold+re-seal) because a re-seal is only byte-clean when `.text==gas` and `witness=0` already hold — verified by §0 research that `sovtc ∉ libiii_native.a` today. D follows C (tools self-mint after the compiler is sovereign). E/F/G/H are independent and parallelizable; G-disasm intentionally follows B to reuse the opcode table (no drift, no island).

**Kill-switches (per-phase):** C4 — if the re-sealed chain is not byte-reproducible twice, STOP (nondeterminism in the sovereign path, not a sealing detail). H1 — if the one-tag falsification moves a golden, STOP (tags are load-bearing; the whole phase is wrong). B3 — if any SIMD `.text` cannot be made byte-identical to gas, that mnemonic stays a declared witness (no silent mis-encode); `witness=0` is the honest gate, and a residual witness is reported, never hidden.
