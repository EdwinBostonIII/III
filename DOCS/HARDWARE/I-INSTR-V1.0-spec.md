# I-INSTR v1.0 — Intent Calculus Hardware Instruction Set

**Status**: SEALED
**Calculus binding**: `R2-GENESIS/CORE-CALCULUS-V1.0.iii`
**Reference RTL**: `R2-GENESIS/silicon/resolver_unit.v`
**Equivalence proof corpus**: `STDLIB/corpus/200_calculus_18_primitives.iii`

---

## 0. Mandate

The Intent Calculus v1.0 defines exactly 18 irreducible primitives. I-INSTR
v1.0 is the silicon-direct expression of those 18 primitives plus the
machinery required to dispatch them — `resolve`, `score`, `seal`, `attest`.
There are no general-purpose registers, no microcode, no speculative
execution, no out-of-order issue. Every instruction commits in 1, 4, 12, or
24 cycles (datapath-fixed); the cycle count is part of the I-INSTR contract.

Equivalence requirement: the I-INSTR core must produce, for every
calculus-replay corpus listed in §10, a witness chain bit-identical to the
software resolver running on x86_64 with `omnia/resolver_unit.s` (the
hand-tuned AVX-2/AVX-512 path described in `CORE-CALCULUS-V1.0` §C.4).

---

## 1. Architectural overview

### 1.1 Register file

| Class                   | Count | Width | Notes                                    |
|-------------------------|-------|-------|------------------------------------------|
| Capability registers    | 8     | 64    | `CR0..CR7` — opaque cap_ids, hashed access |
| Intent register         | 1     | 192   | `IR` — held in 3×64 banks; mhash on commit |
| Context digest register | 1     | 256   | `CTXR` — SHA-256 of call_context state   |
| Witness pointer         | 1     | 64    | `WPR` — head of write-only witness chain |
| KChain accumulator      | 1     | 64    | `KAR` — fixed-point ×1e9                 |
| Pattern set selector    | 1     | 32    | `PSR` — handle to active pattern table   |
| Reflect scope register  | 1     | 8     | `RSR` — see §6                           |

There is no PC. Control flow is expressed as `then`/`if`/`loop`/`compose`
(see §3.2). All control instructions are dispatched through `resolve`, so
the equivalent of an indirect call is a `resolve` with a runtime intent.

### 1.2 Memory model

| Region | Class      | Permission                             |
|--------|------------|----------------------------------------|
| PT     | pattern    | RO at runtime; RW only via `seal_grant` |
| WC     | witness    | append-only; sealed snapshot every step |
| KC     | kchain     | append-only; ASCII hash trail           |
| CR     | capability | bidirectional; mhash-keyed              |
| HEAP   | data       | classical RW with cap-mediation         |

Crucially, **no writeable region is reachable without going through
`grant`**. Every store instruction implicitly proves the issuing intent
holds a non-attenuated capability for the target region.

### 1.3 Pipeline

A 6-stage in-order pipeline:

```
F  : fetch I-INSTR word from PT (instructions are entries of the active pattern set)
D  : decode opcode + operands
S  : score (parallel: 8 candidates per cycle on AVX-2-class width)
R  : resolve (single-cycle indirect dispatch via S's winner)
W  : witness emit (append to WC, advance WPR by 64B)
K  : kchain commit (append to KC, advance KAR)
```

`resolve` retires in 4 cycles (F→D→S→R) when the candidate count ≤ 8 and
in `4 + ceil(N / 8)` cycles otherwise. `compose`/`then`/`with` retire in 1
cycle (no S stage).

---

## 2. Instruction encoding

A single I-INSTR word is **32 bits**. Eighteen opcodes pack into 5 bits
(0..17 used; 18..31 reserved). The remaining 27 bits encode operands per
the per-primitive layout in §3.

```
 31         27 26                                                         0
+-+-+-+-+-+-+-+-----------------------------------------------------------+
|  OPCODE   |                       OPERANDS (27 bits)                    |
+-+-+-+-+-+-+-+-----------------------------------------------------------+
```

Operand layouts are primitive-specific. Most use 3 fields of 9 bits each
(register + immediate + flags). A few primitives (`compose`, `then`) use a
single 27-bit "intent reference" pointing into IR's mhash table.

### 2.1 Opcode table

| OPCODE | Mnemonic   | Cycles | Hexad      | Description                  |
|--------|------------|--------|------------|------------------------------|
| 0x00   | FORM       | 1      | FORM       | declare a kind                |
| 0x01   | BIND       | 1      | SUBSTANCE  | bind value to kind            |
| 0x02   | CONVEY     | 4      | PASSAGE    | move bytes through cap        |
| 0x03   | MEAN       | 1      | ESSENCE    | assert semantic equivalence   |
| 0x04   | ACT        | 4      | MOTION     | drive a state transition      |
| 0x05   | COMPOSE    | 1      | COMPOSE    | merge two intents             |
| 0x06   | SEAL       | 12     | ORIGIN     | snapshot + sign witness chain |
| 0x07   | PROVE      | 24     | ESSENCE    | run equivalence check         |
| 0x08   | QUERY      | 4      | ESSENCE    | read pattern table            |
| 0x09   | GRANT      | 1      | ORIGIN     | mint capability               |
| 0x0A   | GOVERN     | 12     | ORIGIN     | run governance check          |
| 0x0B   | THEN       | 1      | COMPOSE    | sequential composition         |
| 0x0C   | WITH       | 1      | COMPOSE    | environmental composition      |
| 0x0D   | UNDER      | 1      | COMPOSE    | scoped composition             |
| 0x0E   | IF         | 1      | COMPOSE    | conditional composition        |
| 0x0F   | LOOP       | 1      | COMPOSE    | bounded iterative composition  |
| 0x10   | LIFT       | 1      | ORIGIN     | move work between rings        |
| 0x11   | REFLECT    | 1      | ESSENCE    | introspect resolver state      |

### 2.2 Per-primitive operand layouts

For each primitive the 27 operand bits decompose as follows; full
bit-level diagrams appear in `silicon/resolver_unit.v`'s comment block at
the top of the decode unit.

| OP        | Layout (27 bits)                                              |
|-----------|---------------------------------------------------------------|
| FORM      | `[form_id:24][flags:3]`                                       |
| BIND      | `[value_reg:9][form_id:18]`                                   |
| CONVEY    | `[src_cap:9][dst_cap:9][byte_cnt:9]`                          |
| MEAN      | `[lhs_intent:9][rhs_intent:9][equiv_kind:9]`                  |
| ACT       | `[state_reg:9][transition_id:18]`                             |
| COMPOSE   | `[ref_a:13][ref_b:13][flags:1]`                               |
| SEAL      | `[snapshot_id:24][flags:3]`                                   |
| PROVE     | `[cert_id:24][flags:3]`                                       |
| QUERY     | `[pattern_id:24][flags:3]`                                    |
| GRANT     | `[from_cap:9][grantee_cap:9][attenuation_kind:9]`             |
| GOVERN    | `[proposal_id:24][flags:3]`                                   |
| THEN      | `[ref_a:13][ref_b:13][flags:1]`                               |
| WITH      | `[ref_a:13][ref_b:13][flags:1]`                               |
| UNDER     | `[ref_a:13][ref_b:13][flags:1]`                               |
| IF        | `[ref_cond:13][ref_then:13][flags:1]`                         |
| LOOP      | `[ref_body:13][bound:13][flags:1]`                            |
| LIFT      | `[from_ring:3][to_ring:3][cap_ref:21]`                        |
| REFLECT   | `[scope:8][output_reg:8][reserved:11]`                        |

`ref_X` (13 bits) is an index into IR's mini-table of pending intents.

---

## 3. Calculus correspondence

### 3.1 1:1 mapping with `CORE-CALCULUS-V1.0` primitives

For each opcode the I-INSTR specification asserts:

```
   I-INSTR(opcode) ≡ calculus_primitive(opcode + 1)
```

(opcode 0x00 = FORM = primitive #1, etc.) Equivalence is established by
the corpus replay in §10.

### 3.2 Composition operators

`THEN`, `WITH`, `UNDER`, `IF`, `LOOP`, `COMPOSE` do **not** trigger
`resolve`. They construct intent references in IR; the eventual `resolve`
elsewhere uses the constructed intent. This is the silicon-direct
equivalent of how `verba/intent.iii` builds a partial intent before the
final `resolve()` call in `omnia/resolver.iii`.

---

## 4. Capability checking (mandatory, hardware-enforced)

Every store, every cross-region access, and every `LIFT` is preceded by a
combinational capability check using the per-CR mhash:

```
  capability_match(CR_idx, target_region_id) := 
      (CR_idx.attenuation ⊇ region.required_attenuation)
      ∧ SHA-NI verify(CR_idx.mhash, region.expected_mhash)
```

The check is single-cycle on a unit fed by SHA-NI hardware (the same unit
that backs `numera/sha256_dispatch.iii`'s `sha256_oneshot`). A failed check
raises `CAP_FAULT`; the witness chain records the fault before the trap
fires (so post-hoc forensics is possible).

---

## 5. Witness chain (hardware-direct)

Every committed intent produces a **960-bit (120-byte) witness record**
(APOTHEOSIS §C.12 gap 5). The record is 15 little-endian 64-bit words (word 0
in `wc_data[63:0]`), faithfully unifying the software `sanctus/witness.iii`
entry (`mhash || cap || k`) with the `resolver_last_event` reflection struct:

```
 word  field          notes
  w0   seq            monotonic witness sequence
  w1   pattern_id     winner id (argmax-tournament winner, zero-extended)
  w2   intent_id      IR[63:0]
  w3   ctx_digest[0]  CTXR[63:0]    } first 128 bits of the 256-bit
  w4   ctx_digest[1]  CTXR[127:64]  } context digest
  w5   k_now          KChain accumulator after this commit (sealed K-cost)
  w6   {flags:32, score:32}  winner score in the low 32 bits
  w7   dispatch_fp    winning pattern's dispatch function pointer
  w8   memo_key_lo    content-address (cad, SHA-256-trunc-128) low 64
  w9   memo_key_hi    content-address high 64  (-> the 128-bit cad key)
  w10  cap_id         capability id (GRANT-fed; sealed-pad 0 in core RTL)
  w11  ctx_digest[2]  CTXR[191:128] } remaining 128 bits of the
  w12  ctx_digest[3]  CTXR[255:192] } context digest
  w13  {…, memo_hit:1, opcode:5}  status word
  w14  reserved       =0 (sealed-pad)
```

(The v1.0-draft 64-byte layout — `seq||pat||ctx128||k||score||flags` — is the
low-eight-word prefix of this record; the widened 960-bit form adds the full
256-bit ctx digest, the cad key, and the status word so the silicon record is
a strict superset of every software witness field.)

The W stage of the pipeline (one cycle, deterministic) appends the record
and advances `WPR` by 120 bytes. There is no buffering — a record is committed
before its instruction is considered retired.

---

## 6. REFLECT introspection

`REFLECT(scope)` returns a single u64 to the output register:

| scope | Meaning                                           |
|-------|---------------------------------------------------|
| 0     | current `KAR` (fixed-point K-cost)                |
| 1     | current recursion depth                           |
| 2     | last-resolved pattern_id                          |
| 3     | bit-packed parent-pattern chain (depth ≤ 8)       |
| 4     | last winning score                                |
| 5     | tx pattern-set version                            |
| 6     | pipeline congestion fraction                      |
| 7     | hardware feature mask (analogous to `cpufeat`)    |

Scopes 0..4 are 1:1 with the software `reflect()` function in
`omnia/resolver.iii` (see Phase B.3 of the calculus plan). Scopes 5..7 are
hardware-only diagnostics.

---

## 7. Memoization & pre-specialization

### 7.1 Memoization

A small SRAM (4096 entries × 24 B) caches `(pattern_set_id, intent_mhash,
ctx_digest) → (winner_id, dispatch_fp)` triples. Hit latency is 6 cycles
(F→D→S→R, with S as a single-cycle SRAM read). FIFO eviction keyed by a
6-bit sequence counter (8× wraparound on the 4K cache).

Determinism: cache state is **not** witnessed; only outcomes are. Two
identical replays yield identical witness chains regardless of warm/cold
cache.

### 7.2 Pre-specialization

A 256-entry direct-mapped table of `composition_hash → dispatch_fp`
realizes the 141 compositions registered by
`omnia/codegen_patterns.iii::prespec_register_compositions()`. On hit, S
collapses to a single SRAM access and R to a single indirect-call
expansion (1 cycle each). Effectively `resolve` becomes a 3-cycle
operation when every static facet of the intent is known to the assembler
at build time.

---

## 8. Hardware offload integration

The hw_offload table (`omnia/hw_offload.iii`) is mirrored as a pre-loaded
ROM at the I-INSTR core's boot. Each entry maps `(primitive_id,
feature_mask) → microblob_address`. When `resolve` selects a winner whose
`hexad_kind` bit is set in the offload ROM, R issues the microblob
directly (e.g., a 4-cycle SHA-NI sequence for SHA-256-on-CONVEY). No fall-
back path is taken in this case; the K-cost reflects the lowered op.

This is identical in spirit to the `cg_r3_pe_emit_hw_inline()` software
path in `cg_r3.{iii,c}`.

---

## 9. JIT fusion

A 64-entry CAM keyed by `(ctx_id, intent_seq_hash)` provides a fused-code
fast-path. When the first 3 invocations of an identical
`(ctx_id, intent_seq)` are observed within the recent witness chain (via
`REFLECT(scope=3)`), the runtime emits an 8-instruction custom microblob
into a 4096-byte fusion arena and updates the CAM. Subsequent invocations
take 1 cycle (CAM hit + microblob direct execution). Same-input replays
hit on the third invocation only — the ramp-up is part of the
deterministic outcome, not a side effect.

This mirrors `omnia/jit_swap.iii::jit_fuse_*`.

---

## 10. Equivalence corpus

The I-INSTR core is equivalent to the software resolver if and only if
every test in the equivalence corpus, when executed on both, produces a
witness chain whose root mhash matches.

| Software corpus test                 | Hardware corpus test                     |
|---------------------------------------|------------------------------------------|
| `200_calculus_18_primitives.iii`      | `silicon/test_200_18_primitives.sv`      |
| `201_lazy_crystal_levels.iii`         | `silicon/test_201_lazy.sv`               |
| `202_memo_determinism.iii`            | `silicon/test_202_memo.sv`               |
| `203_jit_fuse_amortized.iii`          | `silicon/test_203_jit.sv`                |
| `204_prespec_hw_offload.iii`          | `silicon/test_204_prespec.sv`            |
| `205_governance_full_loop.iii`        | `silicon/test_205_governance.sv`         |
| `206_observe_and_propose.iii`         | `silicon/test_206_observe.sv`            |
| `207_babel_wire_roundtrip.iii`        | `silicon/test_207_wire.sv`               |
| `208_cap_handshake.iii`               | `silicon/test_208_handshake.sv`          |
| `209_idoc_roundtrip.iii`              | `silicon/test_209_idoc.sv`               |
| `210_sealed_channel_handshake.iii`    | `silicon/test_210_sealed.sv`             |
| `211_hip_resolve.iii`                 | `silicon/test_211_hip.sv`                |

Equivalence is asserted by the I-INSTR boot stage executing each of the
above and producing the same `tree_root` mhash recorded in
`STDLIB/iii/SEAL.mhash`.

---

## 11. Determinism guarantees vs current x86_64

| Property                             | x86_64 + resolver_unit.s   | I-INSTR v1.0          |
|--------------------------------------|----------------------------|-----------------------|
| Single-source compute                | yes (no SMT exposed)       | yes                   |
| No speculation                       | partial (mfence required)  | yes (in-order strict) |
| Same input → same witness chain      | yes (deterministic CG)     | yes (sealed pipeline) |
| Memoization replay-stable            | yes (FIFO + content key)   | yes (same scheme)     |
| Bounded JIT replay-stable            | yes (3-observation gate)   | yes (CAM equivalent)  |
| Time-resolution attacks blocked      | partial (TSC mitigations)  | yes (no time on data) |

I-INSTR v1.0 is strictly more deterministic than x86_64 because there is
no speculative execution, no out-of-order issue, no branch predictor, and
no value prediction. Every operation's cycle count is part of its
contract; observed timing is therefore a deterministic function of inputs
alone.

---

## 12. SECURITY MODEL — non-bypassable invariants

1. **No instruction can write to the witness chain except W**. W is a
   single hardware unit fed exclusively by R; software has no path.
2. **No instruction can write to the pattern table except a `seal_grant`
   under valid governance witness**. RW promotion of PT requires a
   matching `governance_promote` cert (24-byte mhash) signed by the
   sealed root.
3. **Capabilities are unforgeable**. Every CR is fed only by `GRANT`
   (which requires either a non-attenuated parent CR or root-cap-bind at
   boot).
4. **Time is observable, not controllable**. Software cannot
   read/influence the K, R, or W stage's timing — only the witness
   chain's sequence number, which is monotonic by W's hardware design.

---

## 13. Implementation footprint estimate

For a 16 nm ASIC implementation of the reference RTL:

| Block                             | Area       | Power (active)        |
|-----------------------------------|------------|-----------------------|
| Decode + register file            | 0.18 mm²   | 35 mW @ 1 GHz         |
| Score unit (8-wide, AVX-2-class)  | 0.42 mm²   | 90 mW @ 1 GHz         |
| Memoization SRAM (4K × 24B)       | 0.31 mm²   | 22 mW @ 1 GHz         |
| Prespec ROM + SRAM                | 0.05 mm²   | 4 mW @ 1 GHz          |
| HW offload ROM                    | 0.02 mm²   | 1 mW @ 1 GHz          |
| JIT fusion CAM + arena            | 0.21 mm²   | 18 mW @ 1 GHz         |
| Witness chain emit + DMA          | 0.07 mm²   | 6 mW @ 1 GHz          |
| **Total core**                    | **1.26 mm²** | **176 mW**          |

(Estimates are first-order; pad ring + I/O omitted.)

---

## 14. Roadmap

This is v1.0 of the hardware spec. Subsequent versions will:

- v1.1: 16-wide score unit (AVX-512-class width) — 2× resolve throughput.
- v2.0: register file extensions for proof-acceleration (a hardware
  proof-checker for `proof_ripple_equivalence` certificates, dropping
  `PROVE` from 24 cycles to 6).
- v3.0: RDMA-direct sealed_channel dispatch (cross-die intent fanout).

All evolutions must remain corpus-equivalent to v1.0 — the calculus is
sealed; only the silicon expression evolves.
