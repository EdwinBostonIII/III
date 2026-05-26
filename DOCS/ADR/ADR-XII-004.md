# ADR-XII-004: Structural Kernel-Fragment Fallback for Uncurated Lattice Cells

## Status
Accepted (Phase XII-η, sealed at the same Manifest mhash as the rest of XII).

## Context

The Horizon Set has 126 productive patterns × 7 deployment targets = 882 maximal `(horizon, target)` cells. Hand-curating every cell with full-fidelity per-pattern assembly is a multi-year curator-engineer task: each cell requires a math specification, an ISA-level encoding, validation against published reference implementations, and test-vector certification.

The original `xii_emit_gen.iii::_content_addressed_body` fallback for uncurated cells emitted SHA-256-derived **noise** bytes:

```
payload[i] = SHA-256(horizon_id || target || k_cost || chunk_idx)[i & 31]
```

That guaranteed bit-determinism and content-addressing, but the bytes were **not executable as the pattern's semantics** — they were random-looking junk that the assembler would accept and the CPU would attempt to decode, almost certainly trapping on an illegal opcode at first instruction.

This created two problems:
1. Any `@lattice`-annotated function that resolved to an uncurated `(horizon, target)` cell would crash at LDIL-inline time (or at first execution of the inlined NOPs).
2. The SML/ATM mhash check would accept the noise — content-addressing was honored — but the runtime behavior was garbage.

The operator demanded **every** `(horizon, target)` cell emit real ISA bytes, not 10 more or 100 more, every one.

## Decision

Replace `_content_addressed_body` with **`_structural_body`**, which emits the horizon's primary-op kernel ISA from `xii_kernel_emit.iii`'s 168 sealed fragments (24 kernels × 7 targets):

```
fn _structural_body(horizon_id, target, body_size, out) -> u32 {
    let primary : u8 = xii_horizon_primary_op(horizon_id)
    let frag_len : u32 = xii_kernel_emit_fragment(primary, target, out)
    if frag_len == 0u32 { return 0u32 }
    if frag_len >= body_size { return body_size }
    let pad_count : u32 = body_size - frag_len
    let pad_ptr : *u8 = (out as u64 + frag_len as u64) as *u8
    xii_nop_fill(target as u32, pad_ptr, pad_count)
    return body_size
}
```

The hand-curated overrides registered via `xii_emit_gen_override` still take precedence (checked first by `_find_override`). The fallback runs only when no curated cell is registered for the requested `(horizon, target)` pair.

## Consequences

### Positive
- **Every cell lands real machine code.** A horizon whose primary_op is `F.COMPOSE` emits the bytes `48 09 c8` (`or rax, rcx`) on x86_avx2 — actual executable code. `K07_SEAL` emits the SHA-256RNDS2 sequence. `F.LOOP` emits a counted loop skeleton. Etc.
- **Determinism preserved.** The 168 kernel fragments are sealed in `xii_kernel_emit.iii`'s byte arrays; their content is bit-deterministic by construction. The fallback's output is fully determined by `(horizon_id, target)` and the sealed kernel-emit tables.
- **SML/ATM continue to pass.** Each cell's payload mhash is unchanged structurally — `xii_emit_gen_cell_mhash` still computes SHA-256 over the actual bytes emitted.
- **LDIL inlining produces a valid function body.** The kernel fragment + NOP pad fills the placeholder; the function returns via the legacy epilogue.
- **Curation upgrade path is trivial.** When the curator hand-codes a full-fidelity sequence for `(horizon, target)`, they register it via `xii_emit_gen_override` and the fallback no longer fires for that pair. One-line change per cell.

### Negative
- **Composite horizons get only the primary-op semantics.** A pattern like `H003 chacha20_block = F.LOOP(F.COMPOSE(K05_ACT($st,COL), K05_ACT($st,DIAG)), 10)` resolves to `F.LOOP` as its primary_op. Without a hand-curated override, the structural fallback emits just `xii_kernel_emit`'s F.LOOP fragment — not the unrolled 20-round body. The function executes but doesn't perform a real ChaCha20 block. Hand-curated overrides for hot-path patterns (which exist for H003, H012, H022, H051, etc.) prevent this.
- **Skeletal vs full-fidelity is now invisible at the cell mhash level.** Both produce real ISA bytes; both have content-addressed mhashes. Distinguishing "this cell is the kernel fragment fallback" vs "this cell is the curated composite" requires checking the registration tables, not the cell payload.

### Trade-offs Accepted
- **Coverage vs algorithmic precision:** the fallback gives 100 % coverage with the trade-off that uncurated composite patterns execute their primary-op kernel only. Curated patterns execute the full composite. The curator decides per pattern whether the kernel-only fallback is adequate (e.g., for rare patterns, register-chain fallback at runtime catches the gap) or whether full-fidelity assembly is required.

## Alternatives Considered

| Approach | Rejected because |
|----------|------------------|
| Keep SHA-256 noise fallback | Uncurated cells crash on execution. Operator demanded real ISA bytes for every cell. |
| Hand-curate all 882 cells | Multi-year curator-engineer effort. Operator demanded leverage, not 10 more or 100 more. |
| Emit `int3` for uncurated cells | "Real bytes" but execution-trapping, defeating LDIL's zero-cycle inline goal. |
| Emit `ret` for uncurated cells | Real, won't crash, but composite semantics totally lost; less useful than kernel fragment. |
| Per-target NOP-only fill | Won't crash but does no work. Curator gets no per-pattern feedback. |

## References

- `STDLIB/iii/omnia/xii_emit_gen.iii::_structural_body` (implementation)
- `STDLIB/iii/omnia/xii_kernel_emit.iii` (168 sealed kernel fragments)
- `STDLIB/iii/omnia/xii_curated_payloads.iii` + sibling files (43+ hand-curated overrides)
- ADR-XII-001 (sealed curation foundation — the override mechanism here is the canonical curated form)
