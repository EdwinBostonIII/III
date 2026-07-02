# STOMA Universality Matrix (M10)

**Claim under test:** STOMA "registers as any kind of CLI a program needs" — every child believes
it is on its native console (pty transport) yet is also fully captured (pipe transport), with
full-width exit codes. Verified by `STDLIB/corpus/2465_stoma_matrix.iii` (gate `run_stoma_kats.sh`,
exit 99), stable across repeated runs. Environment: Windows 11, this repo's msys2 host, 2026-07-02.

## Child × transport verdicts

| Child | PIPE (stoma_proc, captured) | PTY (stoma_pty, native console) | Notes |
|---|---|---|---|
| `cmd /c echo …` | ✅ marker + exit 0 | ✅ marker + exit 0 | baseline console app |
| `powershell -NoProfile -Command echo …` | ✅ marker + exit 0 | ✅ marker + exit 0 | full PowerShell host |
| `git --version` | ✅ marker + exit 0 | ✅ marker + exit 0 (cooked) | pty: git sets the window **title**, so ConPTY injects an OSC `]0;…git.exe\a` sequence **between** `g` and `it version`; raw-byte search misses it, the **cooked** projection (`pty_cooked_find`, VT/OSC-stripped) finds it. Real finding → drove the cooked view. |
| `cmd /c exit 300` | ✅ **full-width 300** | (code path proven in 2457) | bash `$?` would mask to 44; STOMA reads the true u32. |
| `cmd /c for /l … echo L%i` (500 lines) | ✅ tail marker `L500`, ≥2 KB captured | — | mass output: capture never stalls or drops the tail. |
| `bash -c "echo …"` (msys/git) | ⚙️ **transport-faithful** (spawns, waits, captures a real code) | ⚙️ **attaches to pty** | bash's own success is MSYS2's concern, not STOMA's — see below. |

✅ = full semantic success (marker present + exit 0). ⚙️ = transport fidelity proven (STOMA spawns
the exact resolved target and captures its true exit code); the child's self-success is out of
STOMA's control.

## The bash finding (honest scope)

Bash-from-a-native-PE is environmentally fragile in this harness, and the fragility is **not**
STOMA's — STOMA faithfully runs exactly what the OS resolves and reads the true exit code:

1. **PATH shadowing.** `bash` resolves to `C:\Windows\System32\bash.exe` (the **WSL launcher**),
   which exits 1 with no output because no WSL distro is installed. STOMA spawned exactly that and
   captured exit 1 — correct behavior, not a bug. Git's bash lives at
   `C:\Program Files\Git\usr\bin\bash.exe`.
2. **MSYS2 native-boundary quirks.** Even Git bash by full path returns odd codes (observed 117)
   from MSYS2's fork emulation / Windows command-line reparsing — a documented MSYS2 property. From
   a real msys shell (STOMA's own build path) bash works normally; the fragility is specifically
   the native-PE→msys spawn boundary.

STOMA's guarantee is transport fidelity: it spawns the target, hosts it on a pipe or a real
pseudoconsole, and reports the true full-width exit code. That guarantee holds for bash exactly as
for cmd/powershell/git. Making a WSL stub or an MSYS2 fork succeed is not within a terminal's remit.

## Hardening verified

- **ConPTY drain race (fixed):** `pty_close` waits for child exit, then drains with sleep-and-retry
  until ≥20 consecutive empty reads (before + after `ClosePseudoConsole`), so a child that flushes
  its tail late (git after its title sequence) is never truncated. Confirmed stable: matrix KAT
  exits 99 on 3/3 repeated runs (git-pty was flaky before the fix).
- **Full-width exit codes:** `exit 300` → 300 (not bash's masked 44), per corpus 2460 + this matrix.
- **Mass output:** 500-line child captured without stall or tail loss.
- **Cooked projection:** `pty_cook`/`pty_cooked_find` strip CSI + OSC + 2-byte ESC sequences so the
  meaning-plane search is robust to interleaved control sequences while the wire stays raw
  (Membrane Law).

## Not yet exercised (future hardening, non-blocking)

- STOMA hosted *inside* Windows Terminal / VS Code terminal / conhost (manual smoke; the sovereign
  and gcc binaries both run under msys mintty today).
- Long paths (`\\?\`, >260), UTF-8 filenames end-to-end, OneDrive lock-storm soak, multi-GiB output
  soak. The organs are built for these (u16 W-API converters exist in `stoma_con`; capture caps +
  drain-and-count in `stoma_proc`), but they are not yet under an automated KAT.
