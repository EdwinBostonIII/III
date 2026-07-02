# STOMA — the Sovereign CLI Organ: Design + Implementation Plan

> **Execution law:** inline, in-session, by hand — the no-subagents-on-III lock applies to every
> task below. Steps use checkbox (`- [ ]`) syntax. Every milestone ends at a REAL gate (a runnable
> command with a pinned expected exit/count), and no milestone's claim outruns its gate.

**Goal:** III's own terminal + shell — one console-native `.iii` binary (`stoma.exe`) that hosts any
child program with kernel-grade console fidelity, replaces the bash verdict-executive (gates, builds,
seals) by differential attrition, enforces the trap ledger as deterministic preflights, and projects
the repo's living state (ripple heartbeat, tree, sidebar) as views that always collapse to a plain
text log.

**Architecture (one paragraph):** Two planes joined only by a journal. The **wire plane** is sacred:
children run attached to a kernel-provided pseudoconsole (ConPTY) or plain pipes, their bytes pass
through untransformed and are journaled verbatim; exit codes are captured full-width. The **meaning
plane** (intent queue, trap guards, ripple watcher, tree/sidebar views, letter-precise diagnostics)
reads ONLY the journal, exit codes, and artifacts — never the wire — so no smart organ can corrupt a
build, and the failure of any smart organ degrades the face, never the plumbing. Scripts are not a
DSL: batch work is `.iii` programs linked against the same organs the interactive face uses.

**Tech stack:** `.iii` compiled by in-tree `iiis-2`; kernel32 as the sole OS membrane; sovereign path
= `sovas`/`sovld` (console-subsystem PEs proven: `STDLIB/sovtc/sovld.iii:233` emits `p16(3)`);
gcc used ONLY as probe scaffolding and the declared Tier-2 assembler witness, never in the claim.

---

## 0. Provenance — the dream, mapped

| The user's ask | The design's answer |
|---|---|
| "basic enough to be universal, agnostic, just.fucking.work" | Wire plane is boring on purpose: kernel ConPTY + pipes + full-width exit codes; every fancy organ is a projection that can die without touching the wire (Collapse Law) |
| "registers as any kind of CLI a program may need… all the right signs" | Children get a REAL console from the kernel (ConPTY), not an emulation; per-job plumbing mode (pty / pipe / share) matches what each program class expects; when STOMA itself is piped, it degrades to plain-log mode so it composes inside anything |
| "intent… auto-queue precise commands… ensure traps aren't fallen into" | Verbs expand to typed job DAGs; a static trap table (each entry citing its DOCS/memory source) runs as deterministic preflights — the ledger becomes machine law, not prose |
| "cells influence the gene and vice versa… a baby's heartbeat" | The ripple loop: fs-watch → parser-true impacted closure → queued verdicts → ledger/tree recolor → (rule-driven) follow-on jobs; downward gene→cell (edit ripples to verdicts), upward cell→gene (a RED gate marks its blame-set of sources); a deterministic homeostatic pulse, no ML |
| "sidebar to monitor everything running… click into a subfolder and just be there" | Sidebar = live projection of jobs/watches/verdicts; tree pane navigable by arrows/mouse (VT SGR mouse), Enter = cwd teleport |
| "visual navigable tree graph… gracefully collapses back into a standard text log" | Alt-screen (CSI ?1049h/l) for the tree; ALL panes project the same journal, so exiting (or any query failure) lands you on the intact plain transcript — collapse is lossless by construction |
| "warnings suuuper specific, down to the letter" | The shell grammar is lexed with byte-offset spans (compiler discipline); child diagnostics are re-anchored to file:line:col; error signatures that match a trap-table entry print the trap's citation |
| "totally sovereign and nih" | `.iii` only; kernel32 only; no ncurses/readline/xterm emulation; no new script language; sovbuild-linked artifact is the shipped claim |

**Name: STOMA** — the stomatal pore: the regulated opening through which a living organism exchanges
with the world; it opens and closes (gates), it does not transform what passes through it (membrane).
Binary `stoma.exe`; modules `stoma_*.iii` under `STDLIB/iii/aether/` beside `fs.iii`/`ws_*.iii`.
(Aesthetic veto belongs to the user; nothing below depends on the name.)

## 1. Standing (what exists, what is new) — the redundancy audit

Already owned by the substrate (REUSE, do not re-author):

| Capability | Where | Status |
|---|---|---|
| Process entry: GetCommandLineA → argv → main → ExitProcess | `STDLIB/sovtc/crt0.iii` | cited (read 2026-07-02) |
| Console-subsystem PE32+ from the sovereign linker | `STDLIB/sovtc/sovld.iii:233` (`p16(3)`) | cited |
| Spawn + wait + FULL-width exit capture from `.iii` | `STDLIB/iii/aether/ws_console.iii:34-37` | cited (STUDIO gate verb is live) |
| kernel32 file+dir IO, capability-gated, "no C runtime" | `STDLIB/iii/aether/fs.iii` (aether_fs) | cited |
| Native tree self-walk consumer | `sanctus/onelang.iii` (H13, per fs.iii:23-25) | cited |
| Native sha256 (seal math) | `numera/sha256.iii` | cited |
| Exact-verb kernel (sign/collide/relay/mod) + line-editor idiom | `ws_console.iii` | cited |
| stdout via kernel32 from `.iii` corpus exes | `corpus/990_bench_knuth_div.iii:33` | cited |

Genuinely new (grep-verified ZERO in-tree precedent): ConPTY hosting, console-mode/VT control of our
own console, directory watching, job objects, the journal/queue/trap/ripple/tree organs.

## 2. Gated facts from M0 (already run, 2026-07-02)

Probe: `STDLIB/build/stoma_probes/p0_conpty.iii` (compiled by in-tree iiis-2, gcc-linked scaffold) +
C control `conpty_ref.c`. **Result: probe exit 99** — child `cmd.exe /c echo HELLOPTY` attached to a
pseudoconsole created from `.iii`; 96 bytes of VT + the marker arrived through the pty pipe; child
exit code 0 captured; no leak.

PINNED ABI FACTS (implementers: copy, do not re-derive):

1. `CreatePseudoConsole(size: u32, hin: u64, hout: u64, flags: u32, phpc: u64) -> i32` binds from
   kernel32 and works; COORD packs as `x | y<<16` in one u32; the 5th (stack) parameter passes
   correctly under `@abi(c-msvc-x64)`.
2. `UpdateProcThreadAttribute(list, 0, 0x20016, hpc, 8, 0, 0)` — the HPCON is passed **as lpValue**
   (value form). The pointer form silently creates a console-LESS child (echo into the void, no
   attach hello). Adjudicated A/B against the C control.
3. `STARTUPINFOEXA`: zero 112 bytes; `cb=112 @ +0`; `dwFlags=0x100 (STARTF_USESTDHANDLES) @ +60`
   with hStd* left NULL; `lpAttributeList @ +104`; spawn flag `EXTENDED_STARTUPINFO_PRESENT =
   0x00080000`; attr list size for 1 attribute = 48 (probe `N`).
4. **NEW TRAP (ledger entry T-CONPTY-STDIO):** a parent with REDIRECTED stdio (gate harness, CI,
   any pipe) has its redirected handles propagated into console children EVEN WITH
   `bInheritHandles=FALSE`; the child's text then bypasses the pty. Defense (Windows Terminal's
   own): `STARTF_USESTDHANDLES` + NULL std handles on every pty spawn. Without it the child both
   attached (title sequence in the pty) AND leaked its text to the parent's stdout.
5. Pump discipline: `PeekNamedPipe` before `ReadFile` (a blind ReadFile deadlocks — the pty holds
   the write end until `ClosePseudoConsole`); after child exit keep draining ≥2s; after
   `ClosePseudoConsole` drain the tail until dry/broken. ConPTY's first frame can land well after
   child exit.
6. ConPTY hello `\x1b[?9001h\x1b[?1004h` (16 bytes) is attach-triggered — its absence is a usable
   "no client attached" diagnostic.
7. Exit-code plumbing carries values ≥256 intact via `GetExitCodeProcess` (the probe's own exit map
   used 8+n; the bash 8-bit mask is why gates must READ codes natively — motivating verb `gate`).

## 3. Laws binding every task (Global Constraints)

- **Membrane Law:** no organ transforms child bytes on the wire; views read the journal only. Any
  feature that needs child-output *meaning* reads exit codes, artifacts, or its own job records.
- **Collapse Law:** every visual organ has a text projection; `stoma --plain` never links the tree/
  alt-screen organs' failure into the wire path; when stdout is not a console (GetConsoleMode
  fails), plain mode is automatic.
- **NIH/membrane:** kernel32 externs only (purge msvcrt patterns like `ws_forge.iii:29-32` where
  touched); no third-party code, no Python anywhere.
- **No DSL:** batch scripts are `.iii` programs against `stoma_harness`; the interactive grammar is
  verbs, not a language.
- **Attrition Law:** a bash runner retires ONLY after the native verb reproduces its ledger exactly
  (same PASS/FAIL per KAT, same counts) in a differential gate; until then both run. A divergence
  STOPS the migration and is ADJUDICATED, not assumed: root-cause decides whether bash or stoma
  holds the true verdict (the trap ledger is evidence — e.g. a >255 exit code read as its 8-bit
  mask is a bash-side falsehood), the loser is fixed or documented, and the differential re-runs.
  Scope: verdict families (exit-code gates) only; bench families are advisory and never parity-
  gated. The two qualifying parity runs must span real working sessions (edits landed between)
  and run with the stoma queue idle so neither runner mutates artifacts under the other.
- **Determinism + corpus law:** after any change that touches the compiler's inputs, the standard
  determinism/corpus gates run; STOMA modules get corpus-number KATs like every organ.
- **No placeholders; no partial milestones; every claim tagged** gated-fact / cited / analogy.
- **Journal record v1 (`SJ1`)** is versioned from day 0; all views parse only via its reader.
  Journal directories are per-session (pid + launch counter in the segment path) so a nested or
  concurrent stoma never interleaves another's journal. A journal WRITE failure (disk full,
  OneDrive lock) never stalls or truncates the wire: the job is marked UNJOURNALED in the session
  ledger, the wire continues, and the face shows the wound — views may lose that job's transcript
  but the child's execution and exit code are never corrupted (M4 KAT carries a disk-full arm).
- **Safepoint commits** at each milestone's green gate, when the user authorizes.

## 4. File map (all under `STDLIB/iii/aether/` unless noted)

| File | One responsibility |
|---|---|
| `stoma_con.iii` | Our OWN console: GetStdHandle, modes (VT in/out), ReadConsoleInputW decode, WriteFile out, alt-screen enter/leave, UTF-8⇄16 |
| `stoma_proc.iii` | Pipe-mode spawn: argv quoting (crt0-compatible), env/cwd, job object kill-on-close, full u32 exit, native timeout |
| `stoma_pty.iii` | ConPTY jobs: create/attach/resize/^C(0x03)/close + the pump (facts §2) |
| `stoma_journal.iii` | `SJ1` append-only records (LF, repo-local `STDLIB/build/stoma/journal/`), size-capped segments, reader API |
| `stoma_line.iii` | Prompt, history ring, completion (verb table + fs), byte-offset caret errors |
| `stoma_verb.iii` | Verb grammar + dispatch: cd/pwd/ls/env/run/plain + substrate verbs |
| `stoma_build.iii` | `build` verb: parser-true closure (iiis-2 spawns), sovas/witness route, sovld link, manifest (replaces `sovbuild.sh`) |
| `stoma_gate.iii` | `gate` verb: compile+spawn KATs, count natively, ledger records (replaces `run_*_kats.sh` pattern) |
| `stoma_seal.iii` | `seal` verb: native sha256 + AST-anchored extraction (replaces `trusted_base_check.sh` awk) |
| `stoma_traps.iii` | Static trap table: id, deterministic signature matcher, guard action, citation |
| `stoma_queue.iii` | Typed job DAG, preflight guards, serialization of shared-artifact writers, replay |
| `stoma_ripple.iii` | Watch (`aether_fs` extension) → impacted closure → queue → recolor; debounce by content hash; watch-EXCLUDES `STDLIB/build/stoma/` |
| `stoma_tree.iii` | Tree/sidebar projections, arrows+mouse, Enter=cwd, alt-screen collapse |
| `stoma.iii` | main: mode select (interactive/plain/batch), the loop |
| `aether/fs.iii` | MODIFY: add watch surface (ReadDirectoryChangesW or poll fallback) as new exports beside Phase C/D |
| `STDLIB/scripts/run_stoma_kats.sh` | The gate for the organ family (exists until the attrition milestone consumes it too) |

## 5. Milestones

Each milestone = KATs written first → run RED → implement → run GREEN → family gate → safepoint.
Corpus numbers assigned at land time from the next free number, recorded here.

### M0 — Feasibility (DONE 2026-07-02, see §2)
- [x] ConPTY from `.iii`: probe exit **99** (gated-fact)
- [x] sovld console subsystem: `sovld.iii:233 p16(3)` (cited)
- [x] T-CONPTY-STDIO trap discovered + defense pinned (gated-fact via C control A/B)
- [ ] Residual probes folded forward: VT-mode set/restore on a real console → M1 step 1;
  `ReadDirectoryChangesW` on this OneDrive tree (vs poll fallback) → M8 step 1.

### M1 — `stoma_con.iii` (the console organ)
**Interfaces produced:** `con_init() -> i32` (0=console, 1=redirected→plain), `con_out(p: u64, n: u32) -> i32`,
`con_key() -> u32` (packed kind|code), `con_alt(enter: u32) -> i32`, `con_size() -> u64` (w<<32|h),
`con_u8to16(src,n,dst,cap) -> u32` / `con_u16to8(...)`.
- [ ] Probe first (extends M0): GetConsoleMode/SetConsoleMode with `ENABLE_VIRTUAL_TERMINAL_PROCESSING(0x4)`
  + `ENABLE_VIRTUAL_TERMINAL_INPUT(0x200)`; on redirected handles expect the documented failure →
  that IS the plain-mode detector. KAT asserts both branches (run once on console, once piped).
- [ ] KATs: VT byte-emission equality (alt-screen enter/leave emits exactly `\x1b[?1049h`/`l`);
  key-decode table over synthetic `INPUT_RECORD`s (arrows, Enter, Esc, ^C); UTF-8⇄16 round-trips
  (ASCII, 2-byte, surrogate pair, lone-surrogate rejection).
- [ ] Land + gate: `run_stoma_kats.sh` family created; expect `N/0`.

### M2 — `stoma_proc.iii` (pipe-mode spawn)
**Interfaces produced:** `proc_run(cmd: u64, cwd: u64, cap_ms: u32, jr: u64) -> i32` filling a job
record `{code: u32 FULL-width, timed_out: u8, out_seg: u64, err_seg: u64}`.
- [ ] KATs: exit 300 comes back as 300 (kills the 8-bit trap class); `cmd /c exit 259` disambiguated
  from STILL_ACTIVE (wait-first discipline); timeout kills the TREE (job object
  `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`) — KAT spawns `cmd /c "start /b cmd /c pause & pause"`-class
  nest and proves no orphan survives; quoting round-trip against crt0's tokenizer (same quote rules
  both directions).
- [ ] Wire: journal records for spawn/exit (SJ1) — journal lands here in minimal form (append+read).

### M3 — `stoma_pty.iii` (interactive jobs)
**Interfaces produced:** `pty_open(cols,rows) -> u64`, `pty_spawn(pty, cmd, cwd) -> i32`,
`pty_pump(pty) -> i32` (nonblocking slice), `pty_write(pty,p,n)`, `pty_resize`, `pty_ctrlc`, `pty_close`.
- [ ] Implementation = the probe's pinned sequence (§2 facts 1-5), productized: pump slices feed the
  journal verbatim; `pty_ctrlc` writes 0x03 to the input pipe.
- [ ] KATs: echo-marker (the probe, as a corpus KAT); VT-heavy child (spawn `cmd /c` driving a
  color/CUP sequence via `stoma_con`'s own emitter as the child payload) arrives byte-identical;
  resize emits and child observes new size (`mode con` reports it); ^C terminates a `pause` child.

### M4 — `stoma_journal.iii` + `stoma_line.iii` + `stoma_verb.iii` + `stoma.iii` (the walking skeleton)
**The Pareto milestone: after M4 STOMA is a usable shell.**
- [ ] Journal v1 full: segment rotation (16 MiB cap), LF-only writer, reader with record iterator;
  KAT: crash-mid-append leaves a parseable prefix (truncated tail record detected by length field).
- [ ] Line editor: history ring (256), completion over verb table + `aether_fs` dir_read; KATs run
  the editor headless over scripted byte input → expected line/caret outputs.
- [ ] Verbs: `cd pwd ls env run <cmd> plain` only — the `gate`/`seal`/`build` verbs land in M5/M7
  as complete implementations (no stubs registered before their milestone, per the no-placeholder
  law); every parse error prints `line:col` + caret + offending byte hex. Transcript KATs:
  scripted stdin in plain mode → byte-expected transcript out.
- [ ] `stoma.exe` links via **sovbuild** (sovereign artifact from day 1); dev loop may gcc-link but
  the gate runs the sovbuild binary. Gate: transcript family `N/0` + interactive smoke (manual).

### M5 — RECONCILED (2026-07-02): native cockpit over the CONE system

> **Why the change:** mid-M5 the assurance topology was reorganized from BATCH (the `run_*_kats.sh`
> family runners) to CONE — `verify_cone.sh` computes a dirty-cone + maintains a content-addressed
> ledger `STDLIB/build/VERIFIED.tsv` (`kat\ttuple\tPASS|WRONG\tutc`), with `seal_route.sh` splitting
> organ-change (fast `seal_sources.sh` re-pin) from compiler-change (full twin-build). Reimplementing
> a standalone native seal beside this would be an island. So M5 became: **STOMA is the native
> COCKPIT over the cone/route system**, adding only what native code does strictly better.
>
> **Delivered (`stoma_gate.iii`, corpus 2460, gate 8/0):**
> - **Full-width verdicts (the keystone).** `gate_run` spawns via `stoma_proc` and reads the TRUE
>   u32 exit code. Proven live: `exit 300` → bash `$?`=**44** (8-bit mask), stoma_gate=**300**. The
>   native verdict is RIGHTER — the amended Attrition Law made concrete. `gate_bash_would_see()` /
>   `gate_full_vs_bash_diverges()` expose the divergence as a visible fact.
> - **Native ledger reads.** `gate_ledger_load`/`gate_status`/`gate_count_pass|wrong` parse
>   `VERIFIED.tsv` in `.iii` (no grep/awk in the verdict path).
> - **`seal` verb = drive `seal_route.sh`** (reuse the proven router; no reimplementation).
> - **`gate` verb** = native ledger cockpit (`gate` tallies, `gate <kat>` status).
> - **Connect proof (falsifiable):** `verify_cone.sh --plan stoma_gate.iii` maps to `2460_stoma_gate`
>   — STOMA lives inside the cone, not an island.
>
> **Deferred to their proper milestones (honest scope):** moving the cone WALK native (grep-over-tree)
> belongs with the ripple watcher (M8); a native trusted-base seal computation was DROPPED as an
> island (the seal verb drives the existing router instead). The original batch-attrition against
> `run_field_kats.sh` is superseded by the cone connect-proof.

### M5 (original plan, superseded above) — `stoma_gate.iii` + `stoma_seal.iii`
- [ ] `gate <family>`: reads a family manifest (`.iii`-declared table, one per migrated family),
  compiles KATs via in-tree iiis-2 spawn, runs each with cap_ms=25000 default, counts natively,
  writes ledger records; prints `PASS name : exit N` lines byte-compatible with today's scripts.
- [ ] **Differential attrition gate (THE gate of the whole program):** run `run_field_kats.sh` and
  `stoma gate field` on the same tree; assert identical per-KAT verdicts and totals. Same for the
  `aether_lens` family. Divergence = STOP (kill-switch), root-cause before any further milestone.
- [ ] `seal`: native sha256 over `{ccl.iii ++ tc_to_ccl}` where `tc_to_ccl` is extracted by PARSING
  (iiis-2 AST spans, not awk regex); KAT: agrees with `trusted_base_check.sh --print` TODAY, and a
  comment-only edit inside an unrelated fn moves NEITHER; an edit inside `tc_to_ccl` moves BOTH.
- [ ] After both parities hold across 2 consecutive sessions: retire the two bash runners (leave
  tombstone pointing at the verb), per Attrition Law.

### M6 — `stoma_traps.iii` + `stoma_queue.iii` (intent)
- [ ] Trap table v1 (each entry: matcher → guard → citation): 8-bit-exit (guard: native codes),
  pipe-rc-loss (guard: queue records per-stage rc), CRLF-in-script (guard: LF writer + preflight
  scan), /tmp-source (guard: repo-local paths), timeout-25 discipline, BB_MAX_NODES env for verify
  jobs, per-KAT verify (not batch), OneDrive-lock rm-first retry, concurrent-writer serialization,
  bigint-handle-64 advisory on relevant KATs, **T-CONPTY-STDIO (from M0)**.
- [ ] Queue: verbs expand to typed DAGs (`build aether_lens` → compile→route→link→gate chain);
  preflights run before each job; failures print the trap citation letter-precisely.
- [ ] KATs: each guard has a positive AND negative arm (a job that would fall into the trap is
  refused with the citation; the guarded variant runs) — no negative-only proofs.

### M7 — `stoma_build.iii` (replace sovbuild.sh)
- [ ] Closure by parser (spawn `iiis-2 --deps`? if no such flag exists, closure = the same
  `from "x.iii"` edge set but extracted by the LEXER via a `stoma`-invoked iiis-2 run per module —
  parser-true, not regex-true; measure first: if iiis-2 lacks a deps mode, add `--deps` to the
  compiler as its own gated increment BEFORE this milestone consumes it).
- [ ] Route sovas/witness per module, link sovld, print the manifest byte-compatible with
  `sovbuild.sh`'s; differential: both build `stoma.iii` itself and byte-compare the PE.
- [ ] Retire `sovbuild.sh` per Attrition Law after 2-session parity.

### M8 — `stoma_ripple.iii` (the heartbeat)
- [ ] Probe first: `ReadDirectoryChangesW` on this OneDrive tree (events for edit/create/rename
  under sync?); if unreliable → poll walker (aether_fs dir_read + size+content-hash compare) at a
  fixed cadence; either way the WATCHER IS A HINT — truth is the hash-verified impacted closure.
- [ ] Loop: change → impacted closure (module graph from M7) → queue verdict jobs → recolor ledger
  → rule-driven follow-ons (seal drift → reseal-prompt job; RED gate → blame-set marking). Watch
  excludes `STDLIB/build/stoma/` + `COMPILED/` (no self-trigger; KAT proves a queued job's own
  artifacts cause zero requeues).
- [ ] KATs: synthetic edit to a leaf module → expected queue contents (deterministic); no-change
  pulse → empty queue; blame-set of a forced-RED KAT names exactly its closure.

### M9 — `stoma_tree.iii` (the face)
- [ ] Tree pane (arrows, PgUp/Dn, Enter=cwd-teleport, mouse via SGR 1006), sidebar (jobs/watches/
  last verdicts), alt-screen with lossless collapse (exit → plain transcript intact, KAT: render →
  collapse → journal tail byte-equal to plain-mode run of the same session script).
- [ ] Render KATs are headless: panes render to an offscreen byte grid compared against pinned
  snapshots; the VT encoding of the grid is M1-KAT'd already.

### M10 — Universality matrix + hardening
- [ ] Child matrix, each spawned via pty AND pipe modes with verdict recorded in
  `DOCS/III-STOMA-MATRIX.md`: `cmd`, `powershell`, `git status`, `bash.exe -c` (msys), `iiis-2
  --compile-only`, `sovas_main`, a VT-TUI (msys `less`), a mass-output child (find /s on WINDOWS
  dir capped), a CRLF-emitting child, exit-300 child, Ctrl-C behavior per class.
- [ ] STOMA-inside-others: Windows Terminal, conhost, VS Code terminal, `stoma | cat`-style piped
  (plain mode), inside ITSELF (nesting one level).
- [ ] Long paths (>260 via `\\?\` W-APIs), UTF-8 filenames, OneDrive lock storm (rm-first retry),
  4 GiB child output soak (ring + backpressure: bytes never dropped, UI lag only).

### M11 — Review + docs + ledger  (DONE 2026-07-02)
- [x] Adversarial self-review (no-subagents-on-III → by hand): `iii_adversarial_verify` on the
  Membrane + verdict-sovereignty claims; grepped the organ family for the cg_r3 signed-compare-on-
  array-index trap (NONE — values bound to locals throughout) and unbounded writes (`proc_quote` is
  library-only, contract documented). One honest gap surfaced + documented: pty is a verified organ
  but not yet stoma.exe's interactive default.
- [x] `DOCS/III-STOMA.md` operating doc (verbs, laws, organ table, ripple, trap table, cone
  connection, honest scope). MEMORY updated (project_iii_stoma_cli COMPLETE). Final gate 13/0.

## STATUS: COMPLETE — all milestones M0-M11 landed; gate `run_stoma_kats.sh` = 14/0 (stable).

### M11 addendum (advisor-driven): the interactive pty was wired, not just documented
The first M11 close documented "pty is a verified organ, not the interactive default" as a
non-blocking gap. A stronger review flagged that as the user's CENTRAL requirement (programs must
"think they're on their console"), so it was WIRED, not deferred:
- `stoma_fg.iii` (fg_run): foreground pty runner — child on a live pseudoconsole, output streamed +
  journaled, keystrokes translated (CR/DEL/arrows/ctrl) and forwarded. `sh_extern` uses it in
  console mode; the `tree` verb gets an alt-screen arrow-nav loop (`st_tree_interactive`).
- Corpus **2466**: console-detector child prints CON via fg_run (pty), PIPE via proc_run (pipe).
- Fixes forced: fg_run drains BEFORE ClosePseudoConsole (ConPTY discards unread output on close);
  both spawners normalize `/`→`\` in the exe token so forward-slash paths spawn (bare-name matrix
  children never hit this). Closure grew to 11 (fg+pty); native engine + sovbuild agree.

## 6. Risks → falsifiers → kill-switches

| Risk | Falsifier (cheap, early) | Kill-switch / fallback |
|---|---|---|
| ConPTY ABI from .iii | M0 probe — **already 99** | (discharged) |
| Redirected-stdio propagation variants (services, 0-handle parents) | M10 matrix rows | pipe-mode is always available per job |
| msys children misread pty | matrix `bash.exe`/`less` rows | per-job `mode=pipe` + share-console fallback mode |
| ReadDirectoryChangesW on OneDrive | M8 probe | poll walker (hash-verified) at fixed cadence |
| iiis-2 lacks a deps mode | M7 step 1 check | add `--deps` as its own gated compiler increment first |
| cg_r3 64-local ceiling / arena limits in big organs | compile-time exit 14 discipline | module split; functions small (house style) |
| Journal growth in OneDrive | segment cap + rotation KAT | move journal root outside sync dir via config record |
| Differential parity fails on a family | M5 gate itself | STOP the program at the divergence; root-cause; no further milestone until parity |

## 7. Claims ledger (conscience discipline)

- gated-fact: ConPTY-from-.iii (probe exit 99, 2026-07-02); value-form attribute; USESTDHANDLES
  defense; pump discipline. Artifacts: `STDLIB/build/stoma_probes/{p0_conpty.iii,conpty_ref.c}`.
- cited: sovld subsystem 3; aether_fs surface; ws_console spawn idiom; corpus stdout precedent.
- analogy (explicitly NOT claims): stoma/membrane biology framing; "heartbeat" naming.
- UNPROVEN until their probes: VT-mode set on this console (M1), watch semantics on OneDrive (M8) —
  both carry named fallbacks and cannot invalidate earlier milestones.
