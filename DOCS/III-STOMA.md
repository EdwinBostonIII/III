# STOMA — the Sovereign CLI Organ (operating doc)

STOMA is III's own terminal/shell: one console-native `.iii` binary (`stoma.exe`) that hosts any
child program with kernel-grade console fidelity, computes verdicts natively (full-width exit codes,
no bash 8-bit mask), enforces the project's trap ledger as deterministic preflights, and projects
the repo's living state — the ripple heartbeat and a navigable tree — as views that always collapse
to a plain text log.

Built entirely in `.iii` over `kernel32` (no C runtime, no third party). Charter + milestone history:
`DOCS/III-STOMA-PLAN.md`. Universality evidence: `DOCS/III-STOMA-MATRIX.md`. Family gate:
`STDLIB/scripts/run_stoma_kats.sh` (14/0, run from repo root).

**Build status:** `stoma.exe` builds and runs **both** via gcc (dev loop) and via the **sovereign**
path (`sovbuild.sh` → `sovas`/`sovld`, **no `ld`**): the sovld-linked PE32+ (8 sovereign + 3 witness
modules) runs the shell, spawns children, and exits cleanly. Verified: `stoma verbs` + a spawned
child + `[exit 0]` from the sovereign binary.

Getting there fixed a real **sovereign-toolchain** bug STOMA surfaced: the assembler/linker stored
symbol names at a **32-byte-per-slot** stride, truncating 33-char imports like
`InitializeProcThreadAttributeList` → the loader couldn't resolve the truncated name → exit 127.
Root-caused (the `.o.s` had the full name; the COFF object had it truncated) and fixed at all three
layers — `sovparse` (`.o.s` tokenizer cap + SYM/LBL/EXP/BR name strides), `sovas` (EXT_NAME intern),
`sovlink_main` (GSYM/ST tables) — all 32→64 with arrays resized. The toolchain self-test
(`run_sovtc.sh`) is ALL PASS after the change (incl. `coff/longname`, `ld/import*`), so no regression.
STOMA's own `.iii` is sovereign-clean (kernel32-only, no CRT).

## The two laws

- **Membrane Law.** No organ transforms child bytes on the wire. `stoma_proc` (pipe) and `stoma_pty`
  (pseudoconsole) pass bytes verbatim and journal them byte-for-byte. Only `pty_cook` produces a
  VT-stripped *view* for the meaning plane (search/tree); the wire stays raw.
- **Collapse Law.** Every visual organ has a plain-text projection driven by the SAME model, so
  exiting any view — or any view failing — lands on the intact plain log with zero information loss.
  `--plain` (or a redirected stdout) never links the tree/alt-screen path.

## Verbs

| Verb | Does |
|---|---|
| `cd <dir>` / `pwd` / `ls [pat]` / `env <NAME>` | OS state via kernel32 (no CRT) |
| `help` | list verbs |
| `plain` | force plain mode |
| `tree [dir]` | render the navigable tree's plain projection (arrow-nav + status colours in a console) |
| `gate [<kat>]` | native cockpit over the cone ledger: `gate` shows `VERIFIED.tsv` tallies, `gate <kat>` shows one KAT's status — read natively, no grep/awk |
| `seal [files…]` | drive the province router `seal_route.sh` (organ vs compiler seal) |
| `exit` | leave |
| *anything else* | spawn as an external job (pipe-captured), stdout + `[exit N]` to the transcript |

Every parse error is letter-precise: `err@<byteoff>: <reason>` + the line + a caret column.

## Organs (`STDLIB/iii/aether/stoma_*.iii`)

| Organ | Responsibility | KAT |
|---|---|---|
| `stoma_con` | our console: VT modes, key decode, alt-screen, UTF-8⇄16 | 2455 |
| `stoma_proc` | pipe-mode spawn: full-width exit, job-object tree-kill, capture | 2456 |
| `stoma_pty` | ConPTY jobs: attach/pump/resize/^C + cooked projection | 2457 |
| `stoma_journal` | SJ1 append-only journal: rotation, torn-tail-safe reader, UNJOURNALED-on-fault | 2459 |
| `stoma_line` | line editor: history ring, completion, byte-offset caret | 2458 |
| `stoma_verb` | verb grammar + tokenizer (crt0-compatible quoting) | (2459) |
| `stoma_shell` | dispatch integration (no main): built-ins + journal wiring | 2459 |
| `stoma_gate` | native verdict executive + `VERIFIED.tsv` reader | 2460 |
| `stoma_traps` | deterministic trap table (matcher → action → citation) | 2461 |
| `stoma_queue` | typed job DAG: trap preflights → full-width verdicts, serial | 2461 |
| `stoma_build` | native import-closure engine (sovbuild-parity) | 2462 |
| `stoma_ripple` | content-hash pulse → reverse impact / blame set | 2463 |
| `stoma_tree` | navigable tree/sidebar, dual render (VT + plain) | 2464 |
| `stoma_fg` | foreground pty runner: child on a live console, keys forwarded | 2466 |
| `stoma` | main: mode select + interactive/plain loops + alt-screen tree | (smoke) |

## The ripple heartbeat (cell⇄gene)

`stoma_ripple` hashes every indexed source module (FNV-1a); a *pulse* returns exactly the modules
whose content moved (debounced — an unchanged module never fires). Truth is content, not clocks: a
directory-watch event is only a hint to pulse now, so OneDrive's event coalescing / phantom touches
cannot cause a false verdict. Downward (gene→cell): a changed module → its reverse **impacted set**
(every module/KAT that transitively imports it) re-queues. Upward (cell→gene): a RED verdict → its
**blame set** (the forward closure — the sources that could be responsible). Deterministic; no ML.

## The trap ledger

`stoma_traps` holds the project's hard-won traps as fixed matchers with citations; `stoma_queue`
runs each job through them before it executes (BLOCK / REWRITE / WARN):

| Trap | Rule | Action | Cite |
|---|---|---|---|
| TR_TMP | `/tmp` in a job | BLOCK | tmp-path-split |
| TR_EXIT8 | want-exit > 255 | WARN (native reads full width) | probe-exit-8bit |
| TR_CRLF | script file has CRLF | WARN | edit-tool-crlf |
| TR_TIMEOUT | cap_ms == 0 | REWRITE → 25 s bound | env-quirks |
| TR_CONPTY | pty spawn w/o USESTDHANDLES | (structural) | T-CONPTY-STDIO |
| TR_CONCUR | shared-artifact writers | serial by construction | concurrent-writer |
| TR_BIGINT | >64 live bigint handles | (advisory) | bigint-handle-64 |
| TR_PIPE_RC | piped rc lost | per-stage codes | probe-exit-8bit |

## Connection to the cone system (not an island)

STOMA is the **native cockpit** over the existing cone infrastructure, not a reimplementation:
`gate` reads `verify_cone.sh`'s `VERIFIED.tsv` ledger natively; `seal` drives `seal_route.sh`; and
`verify_cone.sh --plan stoma_gate.iii` maps to `2460_stoma_gate` (proven in the gate) — STOMA's
organs live inside the cone. The native adds are full-width verdicts and content-addressed reads.

## Interactive path (WIRED + verified)

On a real console, `stoma.exe` runs external commands on a **foreground pseudoconsole**
(`sh_extern` → `fg_run` → `stoma_pty`): the child gets a real console, its bytes stream to the
terminal live and to the journal, and keystrokes flow back to it. Verified headlessly by corpus
**2466**: the console-detector child prints `CON` through `fg_run` (pty) and `PIPE` through
`proc_run` (pipe) — the exact "the program thinks it's on its console" claim. The `tree` verb enters
an alt-screen arrow-key navigation loop (`st_tree_interactive`) and collapses back to the intact log
on Enter/Esc. Redirected/plain mode still uses pipe capture (correct there).

Two fixes this required: `fg_run` drains the pty to dry **before** `ClosePseudoConsole`
(ConPTY discards unread output on close); and both spawners normalize `/`→`\` in the **first token**
(exe path) so forward-slash paths spawn via `CreateProcessA` while argument slashes (`/c`) are
preserved.

## Honest scope (what is NOT yet true)

- **msys/git bash: transport fidelity only.** STOMA spawns exactly what the OS resolves and captures
  the true exit code; bash-from-a-native-PE is environmentally fragile here (WSL-stub PATH shadow;
  MSYS2 fork/quote quirks) — an MSYS2 concern, documented in the matrix.
- **Hardening not yet KAT-automated:** long paths (`\\?\`), UTF-8 filenames end-to-end, OneDrive
  lock-storm soak, multi-GiB output soak, and STOMA-inside-Windows-Terminal/VS-Code. The organs are
  built for these (u16 W-API converters; capture caps + drain-and-count) but lack automated KATs.
- **`proc_quote`** (exported helper) writes into the caller's buffer without a cap param — its
  contract requires `dst` room for `alen+2`; it is library-only (the shell dispatches the raw line),
  not in the product path.

## Build + verify

```
bash STDLIB/scripts/run_stoma_kats.sh                       # family gate: 14/0 (run from repo root)
# gcc-linked stoma.exe (the verified product) is built + smoke-tested inside the gate above.
bash STDLIB/sovtc/sovbuild.sh STDLIB/iii/aether/stoma.iii out.exe   # sovereign link (sovld, no ld) -- runs
printf 'help\n<cmd>\nexit\n' | ./out.exe                            # plain-mode drive (sovereign build)
```
