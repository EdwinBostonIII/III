# Mandate Engine — Tier 0b: the MCP conscience goes CHECKED

> **For agentic workers:** Use `superpowers:executing-plans` (subagents BARRED). Different repo:
> `C:\Users\Edwin Boston\OneDrive\Desktop\iii-master-mcp\` (sibling, self-owned, safe to edit).

**Goal:** Swap the iii-master MCP's judgment surface from advisory scaffold to real III verbs:
the PRAXIS judgment and the DOKIMASIA assay become spawnable tools, and `iii_gate`'s done-claim
branch renders the LIVE verdict instead of only a checklist.

**Architecture:** Two new CHECKED tools spawn the compiled engines built in Tiers 0-1
(`STDLIB/build/praxis/praxis_cli.exe`, `STDLIB/build/ontos/dokimasia_cli.exe`) via `spawnSync`
with argv arrays (no shell). Engine-absent is an honest named absence, never fake enforcement.
`iii_gate` composes the praxis verdict into its done-claim obligations. Version 1.1.0 -> 1.2.0.

**Tech Stack:** zero-dep Node (`server/iii-master-mcp.mjs`), zero-dep test driver
(`test/test-mcp.mjs`), engines from the III tree at `III_ROOT`.

## Global Constraints

- ZERO third-party dependencies; single-file server; stdout is protocol-only.
- Engines resolved under `III_ROOT` (default sibling `../../III`); missing engine => named
  absence text, exit-code semantics documented in the tool description.
- Pin lines filtered by the same grammar as the Stop judge: `^\[[a-z0-9_]+ < [a-z0-9_]+\]$`.
- Tests must pass with and without a session trace present: deterministic cases use explicit
  `trace` arguments, never the live `.praxis/` state.

---

### Task 1: the two CHECKED verbs

**Files:**
- Modify: `server/iii-master-mcp.mjs` (engine paths near `VERIFY_SH`; two tool fns after
  `toolCheckDischarge`; TOOLS entries; dispatch cases; version bump)

**Interfaces:**
- Produces: `iii_praxis_judge {claim?, trace?, session_id?}` -> STANDS/DEFECT/STALE with the
  engine's real exit code; `iii_dokimasia {verdicts}` -> HEARD/REFUSED with the assay numbers.

- [ ] **Step 1: engine paths + helpers** — after the `VERIFY_SH` line add:

```js
const PRAXIS_CLI   = join(III_ROOT, "STDLIB", "build", "praxis", "praxis_cli.exe").replace(/\\/g, "/");
const DOKIMASIA_CLI = join(III_ROOT, "STDLIB", "build", "ontos", "dokimasia_cli.exe").replace(/\\/g, "/");
const PRAXIS_DIR   = join(III_ROOT, ".praxis").replace(/\\/g, "/");
const PIN_RE = /^\[[a-z0-9_]+ < [a-z0-9_]+\]$/;
```

(and add `readdirSync`, `statSync` to the `node:fs` import.)

- [ ] **Step 2: `toolPraxisJudge` + `toolDokimasia`** — insert after `toolCheckDischarge` (full code in the executed edit; behavior: resolve pins from `args.trace` string or the session/newest `.praxis` trace file, filter by `PIN_RE`, spawn the engine with `[pins + " [done < gate_green]", claim]`, map exit 0/1/3 to STANDS/DEFECT/STALE; dokimasia validates `/^[01]{2,256}$/` then spawns, maps exit 0/1 to HEARD/REFUSED and passes the assay line through).

- [ ] **Step 3: register both in `TOOLS`, dispatch them in `callTool`, bump `SERVER_VERSION` to "1.2.0"**

### Task 2: iii_gate's done-claim goes live; the law names the new verbs

- [ ] **Step 1:** in `toolGate`, when the done-trigger matched, append a `LIVE VERDICT` section
rendering `toolPraxisJudge({trace: args.trace})` (or the named absence). Add optional `trace` to
`iii_gate`'s inputSchema.
- [ ] **Step 2:** `toolSessionLaw` text: add the two verbs to the CHECKED faculty paragraph.
- [ ] **Step 3:** `toolAdversarialVerify` closing line: an LM verdict counts as evidence elsewhere
only after `iii_dokimasia` hears it over a pinned probe set containing known-bad mutants.

### Task 3: tests — 13 tools, deterministic checked cases

- [ ] **Step 1:** in `test/test-mcp.mjs`: expect 13 tools; add the two names to the expected list;
add calls: `iii_dokimasia {verdicts:"11110000"}` (HEARD + `image=2 bits=1`), `{verdicts:"1111"}`
(REFUSED rubber stamp), `iii_praxis_judge {trace:"[edit_x < sha_aa] [gate_green < exit_zero]", claim:"[done < exit_zero]"}`
(STANDS), `{trace:"[gate_green < exit_zero] [edit_x < sha_aa]"}` (STALE), `{trace:"[readme < prose]"}`
(DEFECT), and `iii_gate {action:"claim it is done", trace:"[edit_x < sha_aa] [gate_green < exit_zero]"}`
(contains `LIVE VERDICT` and `STANDS`).
- [ ] **Step 2:** run `node test/test-mcp.mjs` — expect ALL GREEN, exit 0.
- [ ] **Step 3:** commit in the sibling repo.
