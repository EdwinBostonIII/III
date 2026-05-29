# III → Silicon: certified combinator-to-gate synthesis, the physical cost lattice, the hardware AEU

*Design for lowering III's proven-optimal computation onto hardware primitives — `/architect` +
`/math-olympiad` rigor, 2026-05-29. III-native (the referenced `ΣΕΡΑΦ-*.logos` files are absent;
these are the III-compatible equivalents built on III's own kernel/trit/cost/egraph/safety organs).*

---

## 0 · Verdict (calibrated — what is genuinely achievable, named honestly)

All three mechanics are achievable **as certified, III-native capabilities** — with one hard
boundary drawn by the same rigor the math-olympiad lens demands: **name the part that specializes
to an intractable problem and exclude it, rather than pretend.**

| Mechanic | Achievable (decidable, kernel-certified) | Honestly EXCLUDED (intractable / out of NIH scope) |
|---|---|---|
| 1. combinator → netlist | a deterministic, **truth-table-CERTIFIED** lowering of the boolean/combinator graph to a gate netlist (BinaryGate/TernaryGate/DFlipFlop); a content-addressed "hex netlist" | a proprietary **FPGA bitstream** (needs the vendor's place-&-route + closed encoders) — III emits the certified netlist the toolchain (vendor / Yosys+nextpnr) consumes |
| 2. physical cost lattice | **gate count**, **logic depth** (critical-path gate-delay = longest path in the netlist DAG), a **fan-out wire proxy**, and the **Landauer thermodynamic energy lower bound** (irreversible-bit-ops × kT·ln2) — all decidable; the e-graph picks min-physical-cost | **"shortest physical wire paths on silicon"** = optimal **placement** = NP-hard, and the exact silicon joules need a fab model — III gives the topological proxy + the *universe's thermodynamic floor*, not the placed routing |
| 3. axioms in silicon | III's foundational axioms as a **parallel combinational verifier netlist** (all predicates evaluated at once → the abstract "one cycle"), **certified ≡** the kernel's axiom check; zero CPU instructions | "burned into the FPGA" = the toolchain synthesizes the emitted netlist; the achievable clock *period* is bounded by the AEU's logic depth (mechanic 2 computes it) |

**The III value the design delivers that no conventional HLS toolchain does:** the netlist is
*proven* to compute the same function as the combinator-level spec (truth-table equivalence, kernel-
checkable) — "pure algebraic translation, no heuristics, no AI" is literally true because the
equivalence is a discharged proof, not a hope. The toolchain places & routes; III guarantees the
gates are *correct by construction*.

---

## MECHANIC 1 → HW1 · Certified combinator→gate lowering  (`numera/hdl.iii`)

**The map.** A combinator/boolean term that denotes a *finite* (boolean / trit) function lowers
1-to-1 onto gates — this is exactly the realizable fragment SKI/CCL share with hardware (a
combinational circuit computes a fixed finite function; sequential state is the DFlipFlop). The
homomorphism: each boolean connective → one **BinaryGate** (`NOT/AND/OR/XOR/NAND`, NAND universal);
each trit op (`trit.iii`) → one **TernaryGate** (`TNOT/TAND/TOR`); feedback/state → **DFlipFlop**.
`I`→BUF (a wire), `K`→CONST.

**Certification (the whole point).** `hdl_equiv(net_a, net_b, n)` = exhaustive truth table over all
`2^n` (binary) or `3^n` (trit) input assignments → 1 iff the two netlists compute the *identical*
function. The lowering is accepted only when `hdl_equiv(lowered, source) == 1`. Decidable (n ≤ ~16);
a mis-lowering is caught (the falsifier). Gates are added in topological order, so `hdl_eval` is one
linear pass over a value array (no recursion, no allocator).

**KAT 923:** XOR built directly vs. XOR built from 4 NANDs → `hdl_equiv == 1` (the NAND-decomposition
is *proven* equivalent); XOR vs AND → `hdl_equiv == 0` (a wrong netlist is rejected); the trit De
Morgan law `TNOT(TAND a b) ≡ TOR(TNOT a, TNOT b)` certified over all 9 trit pairs + a trit falsifier.

---

## MECHANIC 2 → HW2 · The physical cost lattice  (`numera/phys_cost.iii`)

The cost lattice stops costing x86/ARM instructions and costs **silicon**:
- `pc_gate_count(net)` — physical gate count.
- `pc_logic_depth(net)` — the critical path: the longest gate-chain in the netlist DAG (= the
  gate-delay that bounds the clock period). Computed by a DAG longest-path pass.
- `pc_fanout_cost(net)` — total fan-out (a *topological* wire proxy; NOT placed wire capacitance —
  see §0).
- `pc_landauer_yj(net)` — the thermodynamic floor: `irreversible_bit_ops × kT·ln2`, in fixed-point
  yoctojoules (kT·ln2 ≈ 2871 yJ at 300 K). The genuine "physical micro-joule limit of the universe"
  for the algorithm — an irreducible *lower bound*, not the (process-dependent, higher) silicon draw.
- `pc_better(a, b)` — the lattice order: fewer gates, then shallower depth, then lower energy. The
  e-graph (`egraph`/`sov_isa`) extracts the min-physical-cost member of an equivalence class.

**KAT 924:** the same function as 1 XOR gate vs. 4 NANDs — both proven equivalent (HW1), `pc_better`
picks the 1-gate realization; `pc_logic_depth` and `pc_landauer_yj` computed; a falsifier (the
costlier realization is never preferred; depth/energy monotone in gate count for these cases).

---

## MECHANIC 3 → HW3 · The hardware Axiom Enforcement Unit  (`numera/aeu.iii`)

III's foundational axioms become a **parallel combinational verifier**. Using III's own axiom layer
(not SERAPHIM's 25 — the III-native set): every datum is checked against all axioms *simultaneously*
(an AND-tree over the axiom predicates = combinational, one abstract cycle, zero CPU cycles):
- **AX-REACH** — the datum's hexad is reachable (the 144/729 reachable hexads; `safety_type`/hexad).
- **AX-TYPE** — the datum is well-typed (`safety_type` judgment: a non-reachable Hexad term is ⊥).
- **AX-SEAL** — the datum's content-address matches its declared seal (`cad`).
- (extensible — each axiom is one parallel predicate lane.)

`aeu_check(datum)` = the conjunction (the verifier's output). Crucially, the AEU is *also* emitted
as an `hdl` netlist (the AND-tree of the axiom-predicate circuits) and **certified `hdl_equiv` to
`aeu_check`** — the silicon verifier provably equals the kernel's check.

**KAT 925:** a valid datum (reachable hexad, well-typed, sealed) → `aeu_check == 1` (all lanes pass);
an axiom-violating datum (unreachable hexad) → `aeu_check == 0` (caught in the same pass — the
prove-the-negative); the AEU netlist `hdl_equiv` the predicate.

---

## How it composes with the existing system

`ripple_loop` finds the proven-optimal combinator monolith → **HW1** lowers it to a *certified* gate
netlist → **HW2** extracts the min-physical-cost equivalent (gates/depth/Landauer) → **HW3** wraps it
in the axiom-enforcing verifier. The output is a content-addressed netlist that is (a) proven to
compute the intended function, (b) physical-cost-minimal among proven equivalents, and (c)
axiom-guarded in hardware — handed to the place-&-route toolchain for the silicon itself.

## ADRs
- **ADR-S1 — Certify, never trust the lowering.** A netlist ships only when `hdl_equiv` proves it ≡
  the source (truth table). Same propose-and-check law: the lowering may be mechanical, the
  acceptance is a proof.
- **ADR-S2 — Decidable physical costs only; exclude NP-hard P&R.** gate-count/depth/fan-out/Landauer
  are computed exactly; optimal placement/routing and proprietary bitstreams are the toolchain's, and
  the design says so (no overclaim).
- **ADR-S3 — Landauer is a *lower bound*, labelled as such.** III computes the thermodynamic floor,
  not the silicon draw — honest physics.
- **ADR-S4 — III-native axioms.** The AEU enforces III's own foundational invariants (hexad reach,
  safety_type, cad-seal), not an external axiom list; each is one parallel predicate lane.
- **ADR-S5 — Compose existing organs.** Built on `trit` (TernaryGate), `cost_lattice`/`egraph`
  (selection), `safety_type`/`cad` (axioms); net-new = `hdl` + `phys_cost` + `aeu`.

## Risks
| Risk | Mitigation |
|---|---|
| A mis-lowered netlist ships wrong logic | `hdl_equiv` truth-table proof gates every netlist; falsifier KAT |
| Truth-table blow-up for wide functions | exhaustive ≤ ~16 inputs; beyond, lower per-output-cone / structural homomorphism (op→gate preserves semantics by construction) |
| Overclaiming "silicon" | §0/ADR-S2 — III emits the certified netlist; the toolchain does P&R; stated plainly |
| Landauer mistaken for real draw | ADR-S3 — labelled a lower bound (the universe's floor) |

## Roadmap (one piece at a time, each sealed like the prior integrations)
- **HW1 `numera/hdl.iii`** — gate primitives + `hdl_eval`/`hdl_equiv` (binary + trit certification) +
  the deterministic lowering + `hdl_seal` (cad). KAT 923 (XOR≡NAND, trit De Morgan, falsifiers).
- **HW2 `numera/phys_cost.iii`** — gate-count/logic-depth/fan-out/Landauer + `pc_better` min-select.
  KAT 924.
- **HW3 `numera/aeu.iii`** — the parallel axiom verifier + its certified netlist. KAT 925.

Each: write → adversarial KAT (prove-the-negative) → `build_stdlib` 4xx/0 → cartographer GATE PASS →
compiler `4e138415` unchanged (LIBNATIVE) → full corpus green → seal MHASH-LEDGER → commit.

---

## Bolsters (Silicon Frontier v2) — refinements that strengthen the three mechanics

Designed 2026-05-29 (`/architect` + `/math-olympiad`). Each bolsters a mechanic; each sealed piece
by piece like HW1–HW3, every claim honestly scoped.

**SX1 — Sequential circuits (the DFlipFlop made real)** [bolsters HW1, corpus 926]. Today `hdl` is
combinational (DFlipFlop ≈ a wire). SX1 adds clocked state: a per-gate `HG_STATE`, `hdl_step` (a
combinational pass where each DFF outputs its HELD state, then a latch pass: next-state = the DFF's
input), `hdl_seq_init`, `hdl_set_a` (close a feedback loop), `hdl_dff_state`. III now lowers STATEFUL
hardware — registers, counters, finite-state machines — not just combinational logic. **Decidable:**
a synchronous circuit's behaviour over N clock cycles is a bounded evaluation, not the halting
problem. KAT 926: a toggle flip-flop (DFF fed by `NOT` of its own output) yields the trace 1,0,1,0; a
self-held DFF stays constant (the contrast/falsifier). The DFlipFlop the spec names becomes genuine.

**SX2 — Realistic physical cost: gate delay + wire capacitance** [bolsters HW2, corpus 927]. Today
depth is uniform (1/gate) and "wire" is in-edge count. SX2 adds the literal mechanic: per-gate-TYPE
delay (`pc_gate_delay`: NAND/AND/OR = 1, XOR = 2, trit gates = 2 — the real relative delays) →
`pc_crit_delay` (the *weighted* critical path), and fan-out capacitance (`pc_fanout_cap`: per net,
the number of consumers it drives = its capacitive load — a sharper proxy than in-edge count). Still
NOT NP-hard placed routing (ADR-S2 stands — the topological proxy, refined, not a fab model). KAT
927: an XOR-deep path costs more weighted delay than a NAND-deep path of equal gate-count; a
high-fan-out net costs more capacitance.

**SX3 — The certified netlist optimizer (the E-graph "select fewest gates")** [bolsters HW1+HW2,
corpus 928]. Today the frontier LOWERS + CERTIFIES + COSTS but does not OPTIMIZE. SX3
(`numera/hdl_opt.iii`) adds the selection: PROVEN-equivalent cost-reducing rewrites
(double-negation elimination `NOT(NOT x) ⇒ x`; idempotent `AND(x,x)/OR(x,x) ⇒ x`), each
truth-table-certified, with `pc_live_gate_count` (gates reachable from the output) reflecting the
reduction. The optimizer returns a certified-equivalent, physically-cheaper realization. **Honest
scope (pattern #4): exact minimum-gate synthesis is NP-hard (the Minimum Circuit Size Problem); the
optimizer finds the LOCAL min under the proven rewrite set — never the global min** — exactly the
ripple optimizer's "local-optimal under sound moves" discipline. KAT 928: `NOT(NOT a)` optimizes to
`a` (live-gates 2 → 0), certified ===; `AND(x,x) → x`; an already-minimal netlist is unchanged (the
falsifier).

**SX4 — The scalable, multi-axiom AEU** [bolsters HW3, corpus 929]. Today the AEU is a fixed 2-lane
verifier. SX4 adds an n-lane verdict (`aeu_check_n` over a lane-bit array) + a general AND-tree
netlist certified === the n-way conjunction, plus a third real axiom lane. The AEU scales to III's
full axiom set — every datum verified against all axioms in one parallel pass. KAT 929: a 3-lane
verify; a violation in ANY lane caught; the n-lane AND-tree certified === the conjunction.

Order: SX1 → SX2 → SX3 (uses SX2's cost) → SX4, each LIBNATIVE + corpus-green + sealed.
