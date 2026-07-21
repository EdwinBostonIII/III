# PARATHEKE — the standing deposit: reasoning that survives the session

*Status: LANDED + GATED, **all four paths** (`STDLIB/scripts/paratheke_gate.sh`,
exit 0, eight sections, byte-deterministic; registered in the standalone-organ
sweep). Born 2026-07-21 at n=3; grown the same day by the loop (e4), the web
atom (e5), and ONTOS's observed-jurisdiction theorem (e6: `[variance <
observed] [observed < provisional] ⊢ [variance < provisional]` — the seating of
the electron variance behind the wall, re-earned by the logos every read) —
ledger head `k7ca65076f6d4fb2f`, n=6.*

## The gap this closes

Every organ re-derives itself and forgets. PRAXIS traces are deliberately
session-keyed; KERYGMA reseals and drops; the exact-order verdict on the real R1
head was earned, sealed, embodied — and evaporated when the process exited.
Nothing a session established survived to the next as *standing, re-derivable
knowledge*. PARATHEKE is the missing binding: **Path A (the standing ledger)
fused with the first instance of Path B (the oracle ratchet)**, composed
entirely from organs that already exist.

## The fork, named and decided

The genuine fork was: *what makes a deposit permanent — the stored verdict, or
the stored derivability?* A stored verdict is a frozen golden: cheap to check,
dead the moment the body evolves, and silently wrong if the body regresses. The
decision: **store the question, never trust the answer**. An entry holds

- the **question** (krisis terms, or an order pair),
- the **claimed verdict** — kept *only* as a contradiction tripwire,
- the **engine pin** (sha256 head of the deciding source),
- the **chain** (the previous entry's EIDOLOS scroll address).

The cost, honestly named: standing is body-dependent. A checkout without the
deciding organs cannot claim the ledger stands — it refuses by name instead.
That is kardia's law made cross-session: permanence-under-reverification, never
frozen goldens.

## The law

Reading the ledger = re-earning every entry through the LIVE kernel:

| observation | verdict |
|---|---|
| body re-derives, pin current | **STANDS** |
| body re-derives, pin drifted | **DUE** — heal by *appending* a superseding entry (`of_eN`, fresh pin); never rewrite |
| body disagrees with the record | **REFUSED (contradiction)** — the ledger was bent or the body regressed; both stop the line |
| any byte bent anywhere | **REFUSED at the exact link** — the next entry's `prev_k` names it |

**Contradiction dominates DUE**: the verdict is re-derived *first*; pins are
consulted only after agreement, so a body regression can never hide behind "the
engine changed, just re-earn". Supersession waives *only* the pin check — a
superseded entry still re-earns its body forever.

## Entries are scrolls

One line = one EIDOLOS house; the entry's content-address IS its scroll address
(`eol_read` → `eol_lawcheck` → `eol_addr`). The chain is itself made of claims:

```
[e1 < paratheke] [prev_k0000000000000000 < e1] [kind_krisis < e1] [verdict_p < e1]
  [t0_p_m…0001_ep…0064_b…0001 < e1] … [pin_ka6ca2e77a950622c < e1]
[e3 < paratheke] [prev_k6b7f1e824a678530 < e3] [kind_order < e3]
  [winner_k00000000000060d8 < e3] [loser_k0000000000000785 < e3]
  [order_k4fb43306a4e2e16f < e3] [pin_k705b5316eb05ae07 < e3]
```

ONE builder writes this form; mint **refuses to write anything it did not just
re-derive** (deposit-by-rederivation); parse enforces the exact claim order, so
`mint(parse(x)) == x` is a proven selfprove arm, not a hope.

## The genesis ledger (the first oracle-ratchet instance)

`STDLIB/iii/omnia/paratheke.jrnl` (tracked):

1. **e1** — the truncation refutation `(2^100 + 2^30) − 2^100 = +1`: the claim
   that refutes fixed-tier ties, re-earned by `kr_sign`'s exact dyadic path.
2. **e2** — the exact surd zero `2√2 − √8 = 0`: the separation-bound path
   certifying an exact zero.
3. **e3** — **the R1 head order**: the oracle proposed; the membrane re-derived
   it exactly (two engines, 7165 live dims, sign +1, zero width); mantis sealed
   `[k…0785 < k…60d8]`. The deposit holds the pair (24792, 1925) and re-earns
   the seal through the *same sealer* (`man_seal_order`) on every read —
   deposited address `k4fb43306a4e2e16f` = **5743271528433377647**, the exact
   canonical address `kerygma_embody_verdict` binds to the embodied self. The
   measurement obligation is discharged transitively by `ethos_r1_gate` (the
   connected proof web), pinned to `ethos_r1_probe.iii`.

III consumed the oracle and keeps only what it re-derives itself.

## The organs

- `STDLIB/iii/omnia/paratheke.iii` — the library organ: the one builder, the
  exact-grammar parser, mint/stand/re-earn, and `paratheke_selfprove` (pure, no
  filesystem — the sweep-gate contract): mint-by-rederivation, the round-trip
  identity, content-address separation, the chain tooth (one bent pin nybble
  breaks the *next* link), contradiction-over-DUE, supersession that waives only
  pins, refusal of the empty deposit, determinism.
- `STDLIB/iii/omnia/paratheke_cli.iii` — the carrier: file I/O and the live pins
  (sha256 heads hashed *by the CLI itself*, never trusted from the caller).
  Modes: selfprove / `genesis` / `stand` / `reearn`. Exit 0 STANDS, 1 REFUSED
  (named), 2 usage/io, 4 DUE.
- `STDLIB/scripts/paratheke_gate.sh` — A: pure law ×2 byte-identical; B: the
  real tracked ledger stands (a DUE ledger self-heals by append, then must
  stand); C: three teeth, three *different* named refusals (contradiction /
  chain-bent-at-this-link / DUE pin-drift); D: byte-determinism; E: the
  discharge edge through `ethos_r1_gate` (pure law always; the real 671B walk
  when the Feast is present — it was, and it bore the verdict).

## Foundation stone

The chain stands on EIDOLOS address canonicalization. If the logos itself
evolves, every link reddens at once — that is *correct* (the substrate
drifted); the ledger is then reborn by `genesis`, deliberately and visibly, a
new covenant. Pins are 64-bit sha256 heads: drift detection, not adversarial
security — named, not hidden.

## Reproduce

```
bash STDLIB/scripts/paratheke_gate.sh          # the whole law, exit 0
STDLIB/build/paratheke/paratheke_cli.exe \
  stand STDLIB/iii/omnia/paratheke.jrnl \
  STDLIB/iii/numera/krisis.iii STDLIB/build/mantis/ethos_r1_probe.iii
```

A later session runs `stand` from a fresh process: every entry is re-earned
against the *current* living body — it stands, goes DUE and heals by append, or
reddens itself with the drift named. Self-cleaning permanence.

## The remaining paths — LANDED

**Path B — the oracle door** (`propose <ledger> <srcs> <p|n|z> <s,m,e,b>…`): an
outside CLAIMED verdict enters; the kernel re-derives; only agreement deposits
(rc 0, the ratchet clicks). Disagreement is **ORACLE REFUTED** (rc 1) and
deposits *nothing* — the lie dies at the door, proven in the gate by a forged
claim leaving the ledger byte-identical. The mint cannot even express an
unearned verdict: it derives before it writes.

**Path C — the growth loop** (`grow`): the ledger reads ITSELF (the ANAMNESIS
reading), folds two standing krisis bodies into their union question under the
PTYXIS discipline (hold generators, decide by the exact predicate — the term
cap and the kernel's named walls; the shadow is skipped, never forced), the
kernel decides, and the deposit lands with `from_eN` provenance. Real first
click: **e4** = e1 ∪ e2 — five terms mixing 2^100-scale dyadics with √2/√8
radicals, decided `+1` by the separation-bound path. The gate proves two
consecutive clicks are NOVEL (pair-provenance dedupe) and both stand.

**Path D — the web atom** (`entail <ledger> <srcs> <w0..w5> [from]`): a theorem
deposit — premises `[w0<w1] [w2<w3]`, conclusion `[w4<w5]` — that the LOGOS
re-derives on every read (`eol_entails` over the carried premises). NOT a
tautology: disconnected premises are expressible and are **refused at the
mint** (selfprove arm 37), so only true theorems ever enter the chain. Real
first edge: **e5** `from_e3` — premises `[k…0785 < k…60d8]` (the real R1 order)
and `[k…60d8 < decided]`, conclusion `[k…0785 < decided]`, re-proven by the
barometer every read; bend one premise word and the logos refuses (gate G).
Entail entries pin `eidolos.iii` — each kind pins its own deciding engine.

## The horizon (named, not stubbed)

MANTIS/HERMENEUS proposals shelling the same `propose` door with their own
`kind_`s; ZETESIS emergence seeding `grow` beyond pairwise unions; the fleet
web — every organ's selfprove verdict a scroll in the same house, katoptron's
structural wall generalized to semantic entailment.
