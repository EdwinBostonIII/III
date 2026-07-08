# III — THE GERMINATION MAP (Γ): the biggest ambition above the waist lift

> **EXECUTION STATUS (2026-07-08, same day):** Γ2a EXECUTED (`run_host_matrix.sh`, commit 3fc553b3) ·
> **Γ2c EXECUTED** (arm64 host in the matrix, qemu-7.2-under-WSL1 executor) · **Γ4/Σ0 EXECUTED**
> (`run_germinate.sh`: the self-carrying spore, virgin-prefix regrowth on win64 AND Linux) ·
> **Γ3 EXECUTED at host-closure scale** (`run_retarget.sh`: BOTH translators as anchor-verified waist
> objects, 20/20 byte-match, self-translation fixpoint, cross-ISA Linux germs).  Ledger:
> `III-GAMMA-RETARGET-SPORE.md`.  Still open: Γ0 S4 parse frontier; Γ1/Γ2b at corpus scale; Γ5.
>
> **STATUS: ANALYSIS (LOCATED, not executed).** A systems-map pass (2026-07-08) answering one question:
> *what is the largest unification effort III can take on — beyond the waist lift already located — to make
> the system independently functional in all contexts, evergreen, production ready.*
> Every number marked **[measured]** was produced by a command run against the live tree during this pass;
> claims from docs/ledgers are marked **[recorded]**. This doc locates and programs; it executes nothing.
> Companions: `III-UNIFICATION-LEVERAGE-MAP.md` (Λ, the waist lift — this doc SUBSUMES it as Γ's first arc),
> `III-COMPLETION-PLAN.md` (Φ1–Φ7), `III-LAMBDA0-LINK-CAMPAIGN.md` (Γ0's live ledger),
> `III-SOVEREIGN-STACK-ARCHITECTURE.md` (the SVIR spine).

---

## 0. The verdict in one paragraph

The waist lift (Λ) turns III into **one verified computer** — but a verified computer that still lives on
exactly one substrate (win64) and exists only as this repo on this machine. The biggest ambition available,
the one that cashes "*independently functional in all contexts, evergreen, production ready*" as a single
falsifiable invariant, is **Γ — THE GERMINATION**: make III a **substrate-independent, self-carrying,
self-regenerating verified organism**. Concretely: one artifact — **the SPORE (Σ)** = { the ≤100-line trust
anchor, the entire system as anchor-verified SVIR (seed + toolchain + organs + the translators themselves),
per-host germ binaries with their .iii sources, and the 1,831-KAT oracle } — from which the whole system
**regrows on any host in a growing HOST CLOSURE**, every regrowth byte-DDC'd against its parent, every
capability required to agree across **all** routes (native-win64 × native-sysv × wasm × interp × future
hosts). Adding a host costs **one ~300-line .iii translator** verified by the same anchor — the measured
size class of the three translators that already exist. Γ strictly contains Λ (Λ0–Λ5 are its first arcs)
and terminates in a property no system in the tree — and no mainstream system anywhere — has: **existence
detached from substrate**: III can prove what it computes, prove what built it, and carry both proofs to
any machine and regrow there.

---

## 1. The map (boundary, components, couplings, loops)

**Boundary — and the point of Γ.** Inside: the repo + sibling tools. Outside: the OS loader, the CRT, the
CPU (the named irreducible TCB), node (wasm witness), frozen gcc (witness only). The prior map treated this
boundary as fixed. **Γ's paradigm move is that the boundary itself becomes a parameter the system carries:**
the OS/loader dependence stops being an environmental assumption and becomes a per-host, ~300-line,
anchor-verified module *inside* the system. The substrate is demoted from "environment" to "interchangeable
port."

**Components (fresh measurements, with deltas from the 07-07 map):**

| Component | Measure (2026-07-08) | Delta / note |
|---|---|---|
| Trust anchor `svir_verify.iii` | **97 lines** | was 82 — grew for the v2 container + CALL2 (0x74), the >255-fn enabler; ADR-1 one-sitting-audit budget still holds |
| Host translators | `svir_x86` **331 ln**, `svir_wasm` **300 ln**, `svir_interp` **277 ln** | the measured cost class of "one more host" |
| Sovereign SVIR linker `svir_ld` | **391 ln** | just proved at scale: 19 TUs → ONE anchor-verified v2 module [recorded, log-confirmed] |
| C-subset frontend `ccsv` | **2,803 ln** | compiles the whole 19-TU seed to structural zero: **0 fails / 2,569 fns** [recorded] |
| Self-hosted compiler (lex/parse/sema/cg_r3 .iii) | **12,484 lines** | the Γ3 lowering scope — all four phases are .iii already |
| Capability body | **811 modules**, of which **37 touch OS symbols** | ⇒ **95.4% pure** (37/811; was 32 — tree grew) |
| Corpus | **1,831 KATs**; **69 use aether**, **~8** WriteFile-class, **17 metal**; the 348 "msvcrt" hits are **malloc/free only** | heap is already *inside* the waist (size-tracked heap, 4 MiB linear memory) ⇒ **~96% of the proven capability surface is waist-expressible** |
| Host set today | **{win64-native, wasm-under-node}** — greps find **no ELF, no SysV, no AArch64 anywhere** | "all contexts" is currently two contexts, one of them via node |
| Spine | `run_seed_sovereign.sh` EXISTS (S4 red), `run_completion.sh` + `run_evergreen.sh` exist | Λ0 in flight; frontier = parse.c corruption when main.c is the entry TU [recorded, ledger] |

**The load-bearing coupling.** Unchanged from the Λ map at the first order: the body reaches the waist at
one point (the R0 fold). Γ adds the second-order observation: **the waist reaches the world at exactly one
kind of point too — the translator.** Everything above the translator (anchor, seed, compiler, organs,
proofs) is already host-neutral bytes. The entire win64-boundedness of III lives in: 3 translator modules,
37 aether modules, 10 metal fast paths, and the toolchain's PE/COFF writers. That is a **measured, small,
enumerable** dependence surface — the whole "all contexts" problem is ~50 modules out of ~880.

**Feedback loops:**
- **B1 (balancing, healthy):** the ratchets — corpus determinism, coverage pins, floor closure, carto.
  They defend the current equilibrium and will contain any Γ divergence to one red axis.
- **R1 (reinforcing, the engine):** the closure loop — faculty→cg_r3→seal→gate→faculty. Built the body.
- **R2 (reinforcing, starved — Λ feeds it):** the trust loop — waist-verified artifacts as trusted inputs.
- **R3 (reinforcing, DOES NOT EXIST YET — Γ creates it): the germination loop.** Every new host adds an
  independent execution route; every route multiplies the differential oracle (1,831 KATs × N routes must
  agree); a stronger oracle makes evolution — optimizer changes, new organs, new hosts — safer; safer
  evolution adds hosts and organs faster. **Under Γ, diversity becomes fuel:** the system gets *more*
  trustworthy as it spreads. This inverts the porting dynamic every normal system suffers (each port
  weakens QA). Neither Λ (two routes, one host) nor Φ (one host) can start this loop; it is the emergent
  property that makes Γ "greater than the sum."

---

## 2. Why this is the pick — candidates, Meadows-ranked (weakest → strongest)

1. **Tune parameters** (more KATs, NQ knobs, ratchet hygiene — Φ4/Φ6). Programmed, valuable, structural-nothing.
2. **Consumer-surface unification** (Studio/field breadth, W0–W8). Polices an equilibrium; doesn't change it.
3. **Weld the capstone** — run_completion 8/8. The strongest move *inside* the current goal; blocked on
   exactly Γ0/Λ0's S4 frontier; already the plan of record.
4. **Λ — the waist lift** (body through the waist). The 07-07 pick: paradigm change to "one verified
   computer." Still correct — **and now demoted to Γ's first arc**, because it leaves two absolutes the
   system does not need to accept: *one substrate* and *existence bound to this repo on this machine*.
5. **Autopoietic seed synthesis** (Leg A proven [recorded]). Depth on the floor — strengthens the seed's
   story, doesn't widen the system's world. A Γ4 hardening rung, not the frame.
6. **Cross-repo merger with the .sov/CHARIOT world** (SVIR as the shared waist for both sovereign
   languages; ccsv proves foreign-language→SVIR works). Genuinely inventive — but out of this tree's
   boundary; named as horizon, not pick.
7. **⟨THE PICK⟩ Γ — THE GERMINATION: boundary transcendence.** Above "change the goal" sits Meadows'
   last rung: *transcend the paradigm the boundary encodes.* Λ made verification ambient; Γ makes
   **existence portable**: the system carries its own substrate-relation as verified content (translators
   as waist objects), regrows from one artifact, and turns every port into new verification strength (R3).
   Everything below feeds it; nothing above it exists in the tree.

**The one-sentence discriminator:** Λ answers *"is every III computation verified?"*; Γ answers *"does III
itself — computations, compiler, proofs, and portability — exist as one verified object that no particular
machine, OS, or repo is allowed to be load-bearing for?"*

**What "impossible → possible" cashes to (honest novelty claim):** the components exist separately in the
world — DDC (Wheeler), verified compilers (CompCert), portable bytecode (wasm), reproducible builds. No
system unifies **all five** properties in one self-carrying object: (exact mathematics) + (proof-carrying
results) + (self-hosting fixpoint under a ≤100-line auditable anchor) + (byte-DDC across independent
builders) + (regrowth on arbitrary hosts from a single artifact). That unified object is new.

---

## 3. The Γ program (each rung: exit gate + falsifier, house discipline)

**Γ0 — Close the seed loop (= Λ0; IN FLIGHT, ledgered).** The whole 19-TU seed is at structural zero
(0/2,569 [recorded]), linked to ONE anchor-verified v2 module, executing, reading its source; the live
frontier is parse.c's corruption when main.c is the entry TU (S4, `III-LAMBDA0-LINK-CAMPAIGN.md`).
*Exit gate:* `run_seed_sovereign.sh` green → `run_completion.sh` 8/8 = FULL CAPABILITIES, defined sense.
*Falsifier:* one flipped opcode reddens the anchor; one perturbed seed byte reddens the byte-DDC.

**Γ1 — Body onto the waist (= Λ1–Λ3).** First organs lowered (SVIR backend beside cg_r3's x86 emitter);
ISA-closure audit against the anchor (the anchor does NOT grow to meet the body — ADR-1); the corpus
becomes a **differential oracle**: every routed module's KATs run on both routes and must agree, up-only
ratchet. Scope now measured: ~96% of the corpus is waist-expressible (heap included — malloc/free maps to
the in-waist allocator).
*Exit gate:* `run_body_svir.sh` — per organ: anchor-accept AND route-agreement. *Falsifier:* divergence
reddens the axis; de-routing a module reddens the ratchet.

**Γ2 — HOST CLOSURE (the first genuinely new rung).** The waist's host set grows; **the anchor grows by
ZERO lines** (hosts differ below the waist, never in it — the architectural property that keeps Γ cheap).
Ordered by measured cost:
- **Γ2a — x86-64-SysV/ELF (Linux-class hosts).** Reuses svir_x86's instruction encoder; deltas are the
  ABI (arg registers), an ELF64 writer (`sovelf`, the `sovcoff` sibling — same class of work), and a
  ~20-line entry/exit stub. Decisive measured fact: **pure organs need NO libc** — 0 `extern fn` in the
  body, heap in-waist — so the first Linux organ runs with zero host libraries.
- **Γ2b — wasm first-class.** The corpus differential runs under wasm at scale (precedent: DDC x86+wasm=99
  [recorded]); the browser becomes a host, not a demo.
- **Γ2c — AArch64.** The honest big rock: a NEW encoder (fixed-width ISA; svir_x86-class module by
  structure, not a port). Named cost, not hidden.
- **Γ2d (horizon, explicitly unscheduled) — UEFI/bare-metal germ.** The CHARIOT-adjacent rung: III with
  no OS under it at all.
*Exit gate:* `run_host_matrix.sh` — same KATs, same outputs, axis {win64, sysv, wasm, …}; **down-only host
ratchet** (a host once green never leaves the matrix). *Falsifier:* any per-host output divergence reddens
that host's column; an anchor diff > 0 lines during Γ2 reddens the rung itself.

**Γ3 — RETARGETING CLOSURE (= Λ5, extended to the translators).** The compiler (12,484 ln .iii [measured])
routes through the waist — and so do the **translators themselves** (331/300/277 ln [measured], already
.iii): the spore carries its own retargeting capability, so a new host never needs a foreign toolchain.
Fixpoint obligations: the waist-run compiler byte-matches the native fixpoint on `stage1_corpus`; the
waist-run translator byte-matches the germ binary that booted its host — **trusting-trust answered at the
host level** (every germ is verified *ex post* by the child it boots).
*Exit gate:* fixpoint + translator-regrowth byte-identity gates. *Falsifier:* either byte-divergence reddens.

**Γ4 — Σ, THE SPORE + `run_germinate.sh`.** Package { anchor, system-SVIR, translator sources + germ
binaries, corpus oracle } as ONE self-verifying artifact. Germination on a **virgin prefix** (no repo, no
gcc, no node): germ → seed SVIR → toolchain → full system → all gates → **regrowth-DDC** (child artifacts
byte-match parent where defined). The in-repo precedent is P0 `bootstrap_from_clean` 6/6 [recorded]; Γ4 is
that claim made repo-independent and host-independent. **The spore is the release artifact — the
production form.**
*Exit gate:* `run_germinate.sh` rc=0 on a clean prefix, per host in the matrix. *Falsifier:* perturb any
spore byte → germination reddens.

**Γ5 — THE LIVING INVARIANT (evergreen as a property, not a slogan).** `run_evergreen.sh` extended to:
germinate + N-route corpus differential + fixpoint + GU legs on a REAL organ result (absorbs Λ4:
canonicalise where a term exists, zk-attest folds/kernels — selective by design, stated), continuously.
Optimizer/e-graph evolution is admitted **only** under the N-route oracle + the byte-match law. "Evergreen"
then means: *the system re-derives itself, verified, anywhere, forever* — and every result it ships is a
proof-carrying artifact any germinated node can check without re-execution.
*Exit gate:* extended `run_evergreen.sh` green = the completion invariant's successor. *Falsifier:* any
placeholder, host regression, route divergence, or fixpoint break reddens.

**Scheduling fact (measured, load-bearing):** Γ0 and Γ2a are **independent** — the host-closure rung needs
svir_x86 + a container writer (floor members outside the seed path), so Γ does not serialize on the S4
parse frontier. Two frontiers can burn at once without contention.

---

## 4. What Γ delivers that III cannot do today (the "beyond" list)

1. **Run anywhere:** pure organs native on Linux-class hosts and first-class in browsers — today the
   capability set is win64 + node-mediated wasm only [measured].
2. **An N-route differential compiler oracle:** 1,831 KATs × {win64, sysv, wasm, interp, arm64…} —
   compiler-correctness amplification that *scales with every port* (R3), instead of decaying with it.
3. **Existence independent of repo and host:** regrowth from Σ on a virgin prefix — today the ceiling is
   pristine-clone bootstrap inside the repo [recorded].
4. **Retargeting from inside:** a new host costs one ~300-line .iii module verified by the 97-line anchor —
   no foreign compiler, assembler, or linker ever enters the trusted path again.
5. **The host-level trusting-trust answer:** germ binaries verified ex post by regrowth byte-identity —
   the seed-DDC method [recorded] promoted from one host to every host.
6. **A heterogeneous verified fabric:** Ω.g federation over nodes that are *different machines* running
   *the same verified object*, exchanging proof-carrying exact-math results — the GU generalized from one
   demo on one host to the system's ambient mode everywhere.

---

## 5. Named limits and risks (the cost, or it is not a decision)

- **The 37 OS-facing modules [measured]** are a per-host shim layer, named and matrixed: a capability that
  touches window/net/fs exists on a host exactly when that host's shim set exists. UI (STOMA) stays win64
  until someone pays for its shim — stated per-host, never claimed globally.
- **The 10 metal modules / 17 metal KATs [measured]:** native fast paths are per-encoder-host; the pure-.iii
  siblings are the portable truth; equivalence KATs bind each pair [standing decision, carried].
- **Doubles:** the C seed needed a host-shimmed double runtime [recorded, S4]; the waist stays float-free
  ([measured: no f64/float in svir_verify]); the body is integer-exact by construction. Named exclusion,
  unchanged by Γ.
- **AArch64 is new work** (an encoder, not a port) and **UEFI is a horizon**, both stated as such — no
  schedule-flattering.
- **ADR-1 audit budget:** the anchor is 97 lines [measured] and Γ2 must add **zero**; any host whose
  support demands anchor growth has violated the design and the rung's falsifier catches it.
- **Γ0's S4 frontier is live** (parse.c corruption under main.c entry [recorded]) — Γ0 owns it; Γ2a does
  not stall on it.
- **Failure cascade & the breaker:** floor drift cascades everywhere — the byte-DDC is the breaker (Γ0);
  a route/host divergence is contained to one matrix cell by Γ1/Γ2's differential gates; a germination
  failure is contained to the spore gate and cannot silently regress the parent (down-only ratchets).
- **Environment traps carried:** OneDrive dehydration/locks, CRLF, stale-exe relinks — the standing
  feedback ledger applies to every new gate script.

---

## 6. Confidence + what would confirm or refute this model

**Calibrated confidence:** HIGH on the structure and every [measured] number (produced this pass, commands
in the ledger). MEDIUM-HIGH that Γ2a lands at translator-class cost — encoder reuse + a sovcoff-sibling
writer is measured-precedent work; the unknown is linkage/entry minutiae on the SysV side. MEDIUM on Γ3/Γ4
mechanics (waist-run translator performance; virgin-prefix germination details) and on AArch64 effort.

**Watch to confirm (each cheap, each decisive):**
(a) **Γ0 S4 closes** → run_completion 8/8 — the plan-of-record floor under everything;
(b) **the first ELF organ** (e.g. bigint isqrt on a Linux host, zero libc) — confirms the "pure organs
need no host libraries" claim end-to-end;
(c) **the first regrowth-DDC** — child byte-matches parent where defined; any systematic divergence means
the canonicalisation spec is under-pinned (tighten it, the Φ2 method);
(d) **the anchor diff during Γ2 is zero lines** — confirms hosts live below the waist;
(e) **the first N=3 corpus differential** (win64 × wasm × interp on routed organs) — early divergences in
cg_r3 optimizations would be the oracle *working*; divergences in translators mean harden the waist first.

**The one-sentence answer:** *finish the seed loop, lift the body onto the waist — then make the whole of
III one anchor-verified, self-regenerating object with a growing host closure (Γ): the spore that can land
on any machine, regrow the entire verified system, prove what it computes and what built it, and get more
trustworthy — not less — with every new substrate it colonizes.*
