# ADR-XII-002: Retirement of the Silicon Target, Commitment to Single Software-Native Path

## Status
Accepted (Phase XII-δ, sealed at Phase XII-ζ Ω12)

## Context

The first draft of XII included an 8th deployment target named `silicon`, which would have used I-INSTR v1.1 (the proposed 3-opcode extension to the v1.0 Intent Calculus ISA: `CANONICALISE`, `LATTICE_LOOKUP`, `HORIZON_MATCH`). The plan was:
- HRU (Hardware Resolution Unit) silicon implementing the 3 new opcodes
- 1-cycle dynamic dispatch via on-chip Lattice cache
- Manifest mhash baked into fused-ROM at chip manufacture
- DRTM-relaunch coupling for chip-level tamper integrity

The substrate operator raised a structural objection: "commit to one path that doesn't require me to buy something else or risk bricking my computer."

## Decision

The silicon target is **permanently retired** from XII. XII commits to a **single, software-native execution path** on commodity CPUs (x86-64, ARM64, RISC-V64, Cortex-M class), seven targets total. Two software inventions replace the silicon path:

1. **Link-Time Lattice Inliner (LDIL)** — sealed linker pass that walks `.iii_xii_calls` descriptors, looks up each `(horizon_id, circ_encoding)` against the Lattice, and inlines the cell's byte payload directly at the call site in `.text`. Result: **zero-cycle** dispatch on static-circumstance paths. The static lookup is paid once at link time, not at runtime, and the runtime sees only straight-line code.

2. **Software Measured Launch (SML)** — sealed loader prologue inserted into every XII binary's entry path. At program startup it (a) `mmap`s its own binary, (b) recomputes the Manifest mhash and compares to embedded golden, (c) verifies the Founders-Anchor Ed25519 signature, (d) walks the LDIL audit log re-verifying each inlined cell's SHA-256 against the binary's `.text`. Cost: ~10μs once per program run. On mismatch, the binary refuses to start (rc=6). The user's machine is unaffected.

3. **Anti-Tamper Membrane (ATM)** — continuous-time integrity verification at 1/1024-fusion cadence. Catches rowhammer-class bit-flips and debugger-injected runtime tampering that pass SML but tamper post-startup. Defense-in-depth the silicon path lacked.

## Consequences

### Positive
- **No hardware cost.** Runs on any commodity CPU the operator already owns.
- **No bricking risk.** A tampered binary refuses to start; the machine is untouched.
- **Strictly faster on hot paths.** LDIL inlining is zero-cycle; silicon `LATTICE_LOOKUP` was 1 cycle + indirect jump.
- **Portable.** Binaries compile once, run anywhere with a matching deployment target.
- **Federation interop simpler.** No silicon-vs-software peer split.
- **Defense-in-depth ATM** absent from the silicon path.

### Negative
- **Dynamic-circumstance dispatch** (rare path, ~3% of dispatches in corpus 280..369 weighted analysis) costs 2–4 cycles instead of silicon's hypothetical 1 cycle. Net weighted-mean: LDIL is ~10% faster, so the trade is favourable.
- **Manifest tamper detection** moves from instant (fused-ROM) to ~10μs at startup (SHA-256 + ed25519_verify). Acceptable for desktop/server; embedded scenarios with sub-microsecond startup budgets need careful evaluation.

### Forward-Compatibility
The retirement is **permanent**. No future R2 evolution may re-introduce I-INSTR v1.1's opcodes (0x12..0x14) without explicit federation-wide constitutional amendment. XII binaries are **not** forward-compatible with hypothetical future silicon that adds these opcodes; they would still take the software path.

The existing I-INSTR v1.0 reference RTL (`R2-GENESIS/silicon/resolver_unit.v`) remains valid for its **original purpose** (silicon-direct resolution of the 18 Intent Calculus primitives), but is **not** a target of XII.

## Alternatives Considered

| Approach | Rejected because |
|----------|------------------|
| Silicon-only path | Required custom hardware purchase. Bricking risk on tampered Manifest. |
| Software + silicon both supported | Federation split. Two-codepath maintenance. Optional complexity, per operator's directive. |
| Software default, silicon optional | Same as above; complexity remains. |
| FPGA-only path | Still hardware. Different hardware. Same objections. |
| WASM target | Adds runtime VM (third-party). Violates H-1 NIH. |

## References

- `DOCS/III-XII.md` S16 (LDIL + SML + ATM), S16.7 (permanent retirement clause)
- `DOCS/III-XII.md` S25 (XII_R1 closure including manifest/lattice/reach6 mhashes)
- ADR-XII-001 (sealed curation foundation)
- `STDLIB/iii/sanctus/xii_sml.iii` (SML implementation)
- `STDLIB/iii/sanctus/xii_atm.iii` (ATM implementation)
- `COMPILER/BOOT/xii_ldil.c` (LDIL implementation in C)
