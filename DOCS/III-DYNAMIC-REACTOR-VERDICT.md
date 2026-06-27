# III ⊗ Dynamic Reactor — adjudication (Zero-Instigate Execution Plan)

**What this is.** A conscience-grounded adjudication of the proposed "Dynamic Reactor": run the
autopoietic Seraphyte loop continuously in-memory instead of via bash-spawned native `.exe` per
ripple. Applied with `iii_gate` + `iii_invariant_guard` + `iii_adversarial_verify`, read-first
against the live tree. The plan has a sound, valuable core and one **soundness-critical flaw** that
must not be built as stated.

**Tags.** `[cited]` = read in source; `[adversary]` = survived/failed adversarial attack;
`[judgt]` = architectural judgment.

---

## 0. Verdict in one paragraph

The Reactor's **sound core already exists** — `forcefield/daemon_dream` is the resident
autocatalytic synthesis daemon, and `forcefield/ripple_loop` is the in-memory model loop that
"propose → DECIDE → apply-in-model → loop until DRY" without spawning a process or editing a file
`[cited: ripple_loop.iii:1-6; daemon_dream.iii:1-8]`. III **already separates** the fast in-memory
loop from the slow proof-gated applier (the file write + full reseal). Two of the plan's claims are
**refuted by evidence**: (1) "the OS process-spawn is the bottleneck / millions of optimizations per
second" — the resident loop already avoids per-candidate OS spawn; the rate limit is the **CIC
kernel proof**, which the Reactor cannot remove without removing soundness. (2) Phase IV's "hot-swap
the live `cg_r3` rule table, gated only by a per-rule Crystal, with the byte-fixpoint reseal
relegated to a lazy background thread" — this **breaks III's "cannot emit wrong code" guarantee**.
The genuine, sound, new piece is **Phase III's incremental delta-fold** (wake + fold only the new
events, O(delta)). Build that; keep the proof gate; do not bypass the byte-fixpoint.

**Ripple Merge update (verified this pass — the sound Reactor is ~90% already built).** The substrate
the corrected Reactor needs already exists and is gated as the *Ripple Merge*:
- `omnia/involution` — the `{BELOW,REFLECT}` canonical engine (the "one primitive").
- `eidos/epoch` — the **deterministic multi-writer epoch fold**: writers (its header names "planner,
  optimizer, nous, Seraphytes") submit pending ripples; `epoch_seal` sorts by content-address H and
  folds `State_n = Fold(State_{n-1}, SortedEpoch_n)` so the witness is a pure function of the SET,
  order-independent, **byte-identical** `[cited: epoch.iii:1-7]`. **This IS Phase III** (and it is
  already incremental *across epochs* — each seal folds the new epoch onto the prior state).
- `eidos/membrane` — the **lazy proof membrane**: VACUOUS ticks verify FREE (a geometry tick never
  touches the prover), CRYSTAL self-edits verify via the existing `crystal_verify`; proof orbits the
  atom, checked only for self-edits `[cited: membrane.iii:1-8]`. **This IS the Reactor's proof gate.**
- KATs 2126-2129 gate them; **Gate 7 = subsumption gated on byte-identical replication.**

The decisive fact: the *actual* build **kept the byte-identical gate** — it did exactly what Phase IV
must NOT do (bypass it). So the corrected Reactor is **~90% realized, soundly**: the deterministic
epoch fold (III), the lazy proof gate (membrane), and the one-primitive engine all exist with the byte
gate intact. **The only genuine remaining piece is making the loop RESIDENT** — a continuous daemon
over `epoch_seal` with the Seraphytes as live epoch writers (`daemon_dream` is the resident precedent).
Phase IV (live hot-swap bypass) stays REFUTED; Phase II (SVIR-interpreted Seraphytes) stays a research arc.

---

## 1. What already exists (do not rebuild — wire to it)

- **Resident synthesis daemon:** `forcefield/daemon_dream` — "THE ENGINE of the Autocatalytic
  Synthesis Loop… asynchronous background daemon," `daemon_dream_run(seed, n_cycles, budget)`
  `[cited: daemon_dream.iii:1-36]`. This *is* Phase I's "boot-once resident loop."
- **In-memory model loop:** `forcefield/ripple_loop` — operates on the model (ripple_metric graph +
  congruence union-find), converges to the dedup'd structure, "does NOT edit .iii files — that is
  the applier (Inc 4), behind commit_gate + the full reseal/corpus gate" `[cited: ripple_loop.iii:1-6]`.
- **The two-tier split (the key fact):** III already runs a FAST in-memory model loop and a SLOW
  proof-gated file applier. The Reactor's "fast loop + lazy file write" is largely this architecture.
- **Rule emission:** `cg_opt_rules` is compile-time-proven CODE (admit/shift functions) whose
  soundness is the CIC certifier **plus** the byte-for-byte `iiis-0==iiis-2` / byte-fixpoint gate
  `[cited: cg_opt_rules.iii:1-10]` — *not* a runtime-swappable data table.
- **SVIR VM:** `sovir/zk_svir_*` exists but is a constrained zk-execution VM, not a full interpreter
  for the Seraphytes' capability set (CIC kernel, bigint, e-graph). `[cited]`

---

## 2. The four phases, adjudicated

| Phase | Claim | Verdict |
|---|---|---|
| **I — resident boot-once loop** | hold the BSS once, poll loop, no per-ripple spawn | **ALREADY REALIZED** (`daemon_dream` + `ripple_loop`). Wire to it; don't rebuild. `[cited]` |
| **III — incremental delta-fold + wake-on-epoch** | sleep, wake on pointer advance, fold only the delta O(delta) | **SOUND + genuine new piece.** `event_substrate` now has rewind/provenance (the dome re-home); the missing primitive is a cursor fold (fold `[cursor, count)`, advance a running witness). Build this. `[judgt]` |
| **II — Seraphytes as SVIR bytecode, hot-swappable** | recompile ser_* to SVIR, resident interpreter, swap by instruction pointer | **RESEARCH ARC.** Needs a full SVIR interpreter covering CIC/bigint/e-graph; `zk_svir_vm` is far short. Marginal benefit (Seraphytes change rarely). Defer; not near-term. `[judgt]` |
| **IV — live hot-swap of the running compiler's rules, reseal lazy** | per-rule Crystal admits a rule into the LIVE `cg_r3`; byte-fixpoint reseal → background | **REFUTED — UNSOUND.** See §3. Build the *gated* version instead. `[adversary]` |

---

## 3. Phase IV is unsound — the adversarial refutation (kept verbatim because it is load-bearing)

**Claim:** a per-rule Crystal proof, with the byte-fixpoint reseal relegated to lazy background,
preserves "the system improves itself and cannot emit wrong code."

- **Unstated hypothesis (false):** that a per-rule proof ⇒ whole-compiler soundness. It does not.
  The per-rule proof shows `x*7 == (x<<3)-x`; it does **not** show that adding the rule to `cg_r3`
  leaves the compiler byte-stable, non-interacting with other rules, and corpus-correct. The
  byte-fixpoint + corpus is a **system-level** invariant the per-rule proof cannot establish.
- **Self-reference break:** `cg_r3` is self-hosting — it compiles itself and the Seraphytes.
  Hot-swapping its rules **mid-compile** makes it no longer a fixed function during a compilation;
  the `iiis-2==iiis-3` byte-fixpoint is precisely the check that the compiler-compiling-itself
  reaches a fixed point, and a live swap destroys that determinism.
- **Negative arm (real):** a rule sound *in isolation* can change register allocation / spill / a
  neighboring rule's interaction and break some of the ~6000 corpus programs. The corpus gate
  catches this; Phase IV relegates it to "lazy background," so the live compiler **emits with the
  un-corpus-gated rule before the gate runs.**
- **Precondition violated at the call site:** the current safe-to-use precondition is "passed the
  full reseal." Phase IV uses the rule when only the per-rule proof holds.

**Verdict: REFUTED.** The byte-fixpoint reseal + corpus **is** the system soundness gate. The
per-rule Crystal is necessary, not sufficient. Bypassing the gate for memory-speed trades away the
one guarantee that makes III III.

---

## 4. The corrected Reactor (sound, and most of it already stands)

> **Resident DISCOVERY + PROOF (fast, in-memory) — `daemon_dream` + `ripple_loop` + the incremental
> delta-fold. A proven optimization becomes a content-addressed crystal in a QUEUE. PROMOTION to the
> live compiler stays behind the byte-fixpoint + corpus gate — never bypassed. The live compiler only
> ever uses gate-passed rules.**

What changes vs the proposal: the *speed* win is real for **discovery + per-rule proof** (resident,
incremental, no OS spawn) — which is exactly what `daemon_dream` already does and the incremental
fold makes O(delta). The *live-compiler mutation* stays gated. You get a continuously-running
discovery reactor that never stops finding + proving optimizations at memory speed, and a gated
applier that promotes them soundly — without the bypass.

The "millions/sec" figure applies to the *event fold + candidate enumeration*, not to *proven,
promoted optimizations* (each of those costs a real CIC proof + the system gate). State both
honestly: the reactor is continuous and low-latency-per-event; promotion is proof-bound.

---

## 5. The sound build sequence (each its own verified cycle)

1. **Incremental delta-fold** in `omnia/event_substrate`: a cursor fold (`evt_witness_from(cursor,
   acc)` continues the rolling hash over `[cursor, count)`), so a resident consumer folds only new
   events. Sound (incremental witness == full witness), contained, KAT-gated. *(Phase III primitive.)*
2. **Wire the delta-fold into `daemon_dream`** so the resident synthesis loop folds only the epoch
   delta per wake — the genuine "wake + O(delta)" of Phase III, with a live consumer (no island).
3. **Proven-rule queue:** an admitted optimization → a content-addressed crystal on the queue
   (reuse `proof_ripple_unified`'s move-crystal).
4. **Gated incremental applier:** promote queued rules through the byte-fixpoint + corpus gate
   (made *incremental* — re-verify only the affected emission, then the fixpoint — but **never
   bypassed**). This is the sound version of "the system learns"; it stays as fast as the proof
   allows, no faster.

Phase II (SVIR-interpreted Seraphytes) is deferred as a research arc with marginal benefit.

---

## 6. Named limits & conscience verdict

- The proof is the rate limit, not the OS. No architecture makes a real CIC proof free. `[adversary]`
- The byte-fixpoint + corpus is non-negotiable for live-compiler changes. `[adversary]`
- Phase II needs a full SVIR interpreter that does not exist; treat as research, not a build. `[judgt]`
- The resident discovery reactor is genuinely valuable and ~80% already built (`daemon_dream`,
  `ripple_loop`); the new work is the incremental fold + its wiring + the gated queue. `[judgt]`

*Method: `iii_session_law` → `architect` framework → `iii_gate` → `iii_deep_think` →
`iii_invariant_guard` → read-first (ripple_loop / cg_opt_rules / daemon_dream) → `iii_adversarial_verify`
(Phase IV soundness = REFUTED). No agents. The build is the §5 sequence, the proof gate intact.*
