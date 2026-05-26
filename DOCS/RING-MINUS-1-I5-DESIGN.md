# KATABASIS I5 — The Live-OS Bluepill: Exhaustive Safety-First Design

> DESIGN ONLY. Nothing here is executed without the operator's explicit, separate go. This is the
> architecture for the one rung the doctrine [PD-0] gates: virtualizing the **running** Windows OS so III's
> hypervisor sits beneath it and its sovereign gate adjudicates the OS's dangerous operations — built so
> the live OS is **never** wedged, even on a bug. Foundations proven on metal: I0→I4 + [E7] (see
> `RING-MINUS-1-MILESTONE.md`). This document is the plan to make the impossible safe.

---

## 0. THE PRIME DIRECTIVE

**The live OS must survive every failure mode.** Not "usually." Every one. A wrong VMCB, a wrong VMEXIT
handler, a hang, a brick attempt, a power glitch — each must leave the machine recoverable by at most one
normal reboot, and ideally with no reboot at all. Every design choice below is subordinate to this. Where
ambition and the prime directive conflict, the prime directive wins; where they don't, we are maximally
ambitious.

Three independent properties enforce it:
1. **Rehearsed** — every mechanism is proven with a *disposable* guest before it ever touches the live OS.
2. **Reversible** — III can release the live OS at any instant (un-bluepill), and the bluepill is never
   persistent (a reboot un-does it unconditionally).
3. **Refused** — the live OS cannot brick itself or III: brick-class operations are gate-rejected at the
   Ring −1 boundary, memory is NPT-CoW-reversible, and dangerous ops are shadow-rehearsed in a throwaway
   before the live OS is allowed to perform them.

---

## 1. WHAT I5 IS — AND WHY IT IS CATEGORICALLY HARDER THAN I0→I4

I0→I4 ran a **disposable guest** (a few bytes; a fault loses only the throwaway). I5's "guest" is **the
running Windows OS itself**: III captures the live CPU state into a VMCB and executes VMRUN so that the OS
*continues from the instruction after VMRUN, now virtualized*. The thread that issues VMRUN **becomes** the
guest; III's hypervisor is dormant until the guest takes an intercepted action (a VMEXIT), at which point
III runs in the host context, decides, and resumes.

This is the classic "bluepill," and it has **no CHARIOT precedent** (CHARIOT only ran disposable guests).
The single irreducible risk: the captured VMCB must describe the live OS *exactly*, or the guest resumes
with wrong state and wedges. Everything in this design exists to make that capture provably correct
**before** it is pointed at the live OS, and to make the result reversible if it is somehow still wrong.

---

## 2. THREAT MODEL (every way it can go wrong, and the answer)

| # | failure | consequence if unmitigated | mitigation |
|---|---|---|---|
| T1 | wrong captured state (CR3/segments/EFER/...) | guest = corrupt OS → triple-fault | **I5-a capture-rehearsal**: VMRUN the *real captured state* with a *throwaway RIP* first; a bad capture wedges only the throwaway |
| T2 | wrong VMEXIT handler (GPR clobber, bad resume) | OS resumes corrupt → wedge | **I5-c full-GPR handler rehearsal** with a disposable guest that uses all 16 GPRs; byte-gated |
| T3 | the OS hangs (handler loops / livelocks) | machine frozen | **watchdog/deadman**: a second core (or HPET) releases the bluepill if the OS heartbeat stalls |
| T4 | the OS (or malware in it) attempts a brick | permanent brick (§0.6) | **gate-reject at Ring −1** (hexad-unrepresentable, proven I3-i) + **NPT-CoW** (proven I4) + **shadow-rehearsal** |
| T5 | multi-core race (other cores see half-state) | inconsistent SMP state → wedge | **single-core bluepill first** (blast radius = one thread); SMP only after single-core is proven, via synchronized IPI |
| T6 | NMI/MCE/SMI during the bluepill window | host/guest state confusion | CLGI masks across the transition; NMI/MCE intercepts route to fail-safe-release; SMM is observe-only [out of scope] |
| T7 | III's HV itself faults | host #PF/#GP in Ring −1 | HV is pure, non-paged, byte-verified, stack-bounded (proven discipline); an HV fault triggers fail-safe-release |
| T8 | unexpected/unmodelled VMEXIT | undefined behavior | **fail-safe default**: any unmodelled exit → release the OS un-virtualized (never guess) |

---

## 3. THE CAPTURE (every field the VMCB needs for the live-OS guest)

The capture is **read-only** of the live CPU (it changes nothing); VMRUN is the only state-changing step,
so everything up to VMRUN is abortable at zero cost.

**Manually captured (read the registers/tables):**
- `CR0, CR2, CR3, CR4` — the live paging state (CR3 = the OS's PML4 root). The crux of T1.
- `EFER` — the live value **with SVME forced set** (APM 15.5.1: guest EFER.SVME must be 1 or VMRUN→INVALID).
- `RFLAGS` (pushfq), `RSP` (current), `RIP` = the label immediately after VMRUN.
- `CS/SS/DS/ES` selectors (read) + **long-mode-fixed** base=0/limit=0xFFFFFFFF/attrib (in long mode these
  are architecturally flat; we do NOT trust a stale read of hidden parts — we set the known long-mode attrs).
- `GDTR, IDTR` (sgdt/sidt — base+limit), `DR6, DR7`.

**Captured by VMSAVE (the per-thread / syscall state, with correct hidden parts):**
- `FS, GS` (+ their non-zero bases — the TEB/KPCR pointers), `TR, LDTR` (+ hidden parts), `STAR, LSTAR,
  CSTAR, SFMASK, KernelGSBase`. VMSAVE writes exactly these into the VMCB state-save, so we never hand-compute
  them — the single most error-prone part is delegated to the CPU.

**Control area (minimal-intercept — see §5):** ASID≠0, NP_ENABLE=1 + N_CR3 (the III-built NPT identity map
over the OS's physical memory, NOT the OS's CR3 — nested paging is separate), TLB_CONTROL=1, IOPM/MSRPM bases,
and the **smallest intercept set** that the gate needs.

> Design rule: prefer VMSAVE/architectural-fixed values over hand-computed reads. The fewer fields we
> compute, the fewer ways T1 happens. The capture-rehearsal (I5-a) then proves whatever we did compute.

---

## 4. THE BLUEPILL TRANSITION (the irreducible moment)

On one pinned core, at high IRQL, with interrupts masked:
```
   ... build VMCB (control + captured state, §3) ...
   mov  rax, vmcb_phys
   clgi                         ; mask all interrupts incl NMI across the transition
   vmsave                       ; fold the live FS/GS/TR/LDTR/syscall MSRs INTO the guest VMCB
   ; (host basic state is saved to VM_HSAVE_PA by VMRUN; restored on #VMEXIT)
   vmrun                        ; the live OS becomes the guest; it RESUMES at the captured RIP =
.after_vmrun:                   ;   the next instruction, as if nothing happened
   ...                          ; (this path runs only as the guest, post-bluepill)
```
The genius and the danger are the same: after VMRUN the guest's RIP = `.after_vmrun`, so **the live OS keeps
running, bit-for-bit as before**, except it is now a guest. III's HV only wakes on a VMEXIT. If the capture
was right, the OS notices nothing; if it was wrong, the OS faults — which is why §3's state is rehearsed
first (I5-a) and why the un-bluepill (§7) exists.

---

## 5. THE HV VMEXIT LOOP (long-running, minimal-intercept, full-GPR)

Unlike the disposable guests (1–2 exits), the live OS generates a VMEXIT for every *intercepted* op forever.
The HV entry point (hand-asm, the one place III runs as host) must:
1. **Save ALL 16 guest GPRs** immediately (the OS uses every register — unlike the VMMCALL guest). RAX/RSP/
   RIP/RFLAGS come from the VMCB; RBX/RCX/RDX/RBP/RSI/RDI/R8–R15 are live in the physical regs → pushed.
2. **Dispatch on EXITCODE** through the proven minimal VMEXIT set (`katabasis/vmexit.iii`, fail-closed):
   the gate-relevant brick-class ops → §6; benign-but-intercepted ops → emulate+resume; **anything
   unmodelled → fail-safe-release (§7), never guess (T8).**
3. **Restore ALL 16 GPRs**, advance RIP per the exit semantics (or leave it for fault re-execution), VMRUN.

**Minimal-intercept principle:** intercept *only* what the gate must see (the brick-class: specific MSR
writes, specific NP faults, VMMCALL, SMI/INIT/SHUTDOWN). Everything else runs native (no VMEXIT) → the OS
runs at near-native speed and the handler surface (where T2 lives) is as small as possible. Every added
intercept is a deliberate, justified, byte-gated decision.

Performance/correctness: the handler is pure, non-paged, stack-bounded (the proven cg_r0/hand-asm
discipline), and must be re-entrant-safe w.r.t. its own (masked) interrupts.

---

## 6. THE §0.6 THREE-WAY BRICK CLOSURE — COMPOSED AND APPLIED LIVE

Each mechanism is already proven individually; I5 composes them against the live OS:
1. **Refused (hexad-unrepresentable).** A live-OS brick-class action VMEXITs → III runs `katabasis_gate_admit`
   on it (the cycle's hexad is non-reachable) → **REJECT_HEXAD** → the op is blocked (skip/inject-#GP) and the
   OS continues. *Proven at the Ring −1 VMEXIT in I3-i.* The OS cannot brick itself through an intercepted op.
2. **Reversible (NPT-CoW).** Writes to protected physical pages NPF → III copies-on-write (original preserved
   in a journal) → the write lands on the copy → any bad write is reversible by restoring the journal.
   *Proven interception in I4.*
3. **Rehearsed (shadow-rehearsal) — the live application of [PD-0].** Before *allowing* a live-OS dangerous-
   but-not-flatly-rejected op, III replays it in a **disposable guest** seeded with the relevant state; if the
   throwaway bricks, III refuses the live op. The disposable-guest ladder (I2–I4) is the rehearsal engine; here
   it runs *inline*, live. This is the third closure made dynamic.

The closure is **AND, not OR**: an op must pass all applicable mechanisms. A brick needs to defeat hexad-
rejection AND escape NPT-CoW AND survive the shadow-rehearsal — three independent walls, each proven.

---

## 7. REVERSIBILITY — III NEVER TRAPS THE OS

- **Un-bluepill (operator- or watchdog-triggered).** On the next VMEXIT (or a deliberate VMMCALL hypercall
  from a control thread), III: restores the guest's full state to the physical CPU, `vmload`s the host extra-
  state, `STGI`, clears EFER.SVME + VM_HSAVE_PA, frees the region — and **returns to the OS un-virtualized**,
  exactly as before the bluepill. The OS keeps running; III simply steps out from underneath it.
- **Watchdog / deadman (T3).** A heartbeat (the OS, or a control thread, bumps a counter) is monitored by an
  un-bluepilled core (or the HPET). If the heartbeat stalls beyond a bound, the watchdog forces un-bluepill →
  the OS recovers. A hang is not fatal.
- **Fail-safe default (T7/T8).** Any HV fault, any unmodelled exit → un-bluepill. III defaults to *release*,
  never to *guess*.
- **Reboot floor.** The bluepill is RAM-only and demand-started: an unconditional reboot un-does it. System
  Restore is taken before. There is always a floor beneath the floor.

---

## 8. THE I5 REHEARSAL LADDER (rehearse EVERYTHING with disposable guests; bluepill LAST)

I5 is itself a ladder, [PD-0] applied recursively. Only I5-d touches the live OS; I5-a/b/c prove its
mechanisms on throwaways first.

- **I5-a — Capture-rehearsal (THE keystone safety move).** Capture the live CPU state (§3) into a VMCB, but
  set the guest RIP to a *throwaway* `vmmcall` placed at a known-mapped guest-virtual address (e.g., inside
  III's own resident page, which the live CR3 maps). VMRUN runs a guest with the **real captured paging /
  segments / EFER** but a **fake RIP** → if it reaches the vmmcall and exits `0x81`, the captured state is
  *proven loadable* by the CPU **without ever bluepilling the OS**. A bad capture wedges only the throwaway.
  This converts T1 from "bet the machine" into "test the throwaway."
- **I5-b — Un-bluepill rehearsal.** Prove the release path (§7) returns cleanly to the host context, using a
  disposable guest. Prove the watchdog forces release on a stalled heartbeat.
- **I5-c — Full-GPR VMEXIT-handler rehearsal.** A disposable guest that sets all 16 GPRs to sentinels, does a
  VMMCALL; the handler saves/restores all 16; verify on resume the guest sees its sentinels intact (byte-gated
  + on-metal echo, the I3-ii technique scaled to 16 registers).
- **I5-d — THE BLUEPILL (single core).** Only after I5-a/b/c PASS: VMRUN with the live OS (RIP=`.after_vmrun`)
  on one pinned core. Prove it lives: a control thread issues a deliberate VMMCALL → VMEXIT → III's gate runs
  → resume → the OS continues → un-bluepill. The OS ran virtualized and was released, untouched.
- **I5-e — Gate-protects-the-live-OS.** With the OS bluepilled, have a control thread attempt a brick-class op
  (a benign, instrumented one) → III intercepts → gate REJECT_HEXAD → the op is blocked → the OS is provably
  protected from a brick it tried to commit. The §0.6 defense, live.
- **I5-f (future, gated separately) — SMP bluepill.** All cores, via synchronized IPI. Out of scope until
  single-core (I5-d/e) is long-proven.

---

## 9. GO/NO-GO FOR I5-d (the actual bluepill) — ALL must hold

1. I5-a capture-rehearsal: PASS (the live state is CPU-loadable, proven on a throwaway).
2. I5-b un-bluepill + watchdog: PASS.
3. I5-c full-GPR handler: PASS.
4. Gate-at-VMEXIT (I3-i), NPT-CoW (I4), shadow-rehearsal engine: proven + wired.
5. Minimal-intercept VMCB: every intercept justified + byte-gated; fail-safe-default verified for every
   unmodelled exit.
6. Single core; the other 31 untouched.
7. Watchdog armed; heartbeat live.
8. Operator's EXPLICIT go + System Restore checkpoint + demand-start + test-signed; UAC the only trigger.
9. Determinism: the bluepill VMCB byte-reproducible; witness attests the HV `.text`.

If any item is not green, I5-d does not run. There is no "probably."

---

## 10. SAFETY ENVELOPE (standing, every I5 rung)

Single-core blast radius · disposable-guest rehearsal before every live step · CLGI/STGI + DISPATCH(or
higher) across privileged windows · pure non-paged byte-verified stack-bounded HV · fail-safe-release default
· watchdog/deadman · NPT-CoW journal · gate-reject of bricks · operator-gated + reboot-recoverable + System
Restore · deterministic + witnessed. NIH throughout (libc + III BOOT + mingw `libntoskrnl.a` only).

---

## 11. OPEN QUESTIONS / RISKS still to retire (track in the ledger)

- **Q-I5-1:** the throwaway-RIP placement for I5-a — a `vmmcall` at a guest-virtual address the live CR3 maps
  (III's resident page) vs a fresh identity page added to the live page tables. Decide at I5-a build.
- **Q-I5-2:** Hyper-V/VBS coexistence — confirmed OFF on this box (probe: EFER.SVME=0). I5 assumes no other
  hypervisor holds SVM. Re-probe immediately before I5-d.
- **Q-I5-3:** the exact minimal intercept set for "protect against §0.6 bricks but run near-native" — derive
  from the proven brick taxonomy (`katabasis/` svm_layout/bar_layout/cycle_family) + APM appendix B; byte-gate.
- **Q-I5-4:** watchdog mechanism — an un-bluepilled core spinning on a heartbeat vs HPET vs the LAPIC timer
  intercept. Lowest-risk: an un-bluepilled sibling core (single-core bluepill leaves 31 free).
- **Q-I5-5:** NMI/MCE (T6) handling under bluepill — intercept → fail-safe-release initially (don't attempt to
  reflect them into the guest until proven).

## 12. EXECUTION PLAN (granular; each rung evidence-first, byte-gated, operator-gated; NO live bluepill until I5-d's gate)

1. Harvest the live-state capture sequence (read CR0-4/EFER/seg/GDTR/IDTR/DR + VMSAVE) → hand-asm shims +
   byte-gate vs the AMD APM. *(read-only of the live CPU; safe.)*
2. **I5-a** capture-rehearsal driver + IOCTL → operator deploy → confirm `0x81` (capture loadable). 
3. **I5-b** un-bluepill + watchdog rehearsal → deploy → confirm clean release.
4. **I5-c** full-GPR handler rehearsal → deploy → confirm 16/16 sentinels.
5. Wire the minimal-intercept VMCB + the gate + NPT-CoW + the shadow-rehearsal engine (compose proven parts).
6. **I5-d GO/NO-GO review (§9)** → on operator's explicit go only → the single-core bluepill → prove-live →
   un-bluepill.
7. **I5-e** gate-protects-live → deploy → confirm a brick attempt is rejected.
8. (Deferred, separate decision) I5-f SMP.

Each step is its own gate_floor-style artifact: cg_r0 driver + hand-asm shims, disasm-verified, deterministic
hash pinned, deployed only behind the UAC with a restore point. The disposable-guest ladder (I0→I4) is the
proven substrate every rung builds on. **The live OS is bluepilled exactly once in this plan — at I5-d, behind
its own explicit gate — and is releasable the instant after.**
