export const meta = {
  name: 'apotheosis-frontier',
  description: 'Close the parallelizable apotheosis frontier: C.12 Verilog RTL completion + C.10 Ring-0 read-only crash-path audit, in isolated worktrees',
  phases: [
    { title: 'Frontier' },
  ],
}

const REPORT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['unit', 'worktree_path', 'status', 'summary', 'files_new', 'files_modified', 'gate_status', 'escalations', 'risks', 'integration_notes'],
  properties: {
    unit: { type: 'string' },
    worktree_path: { type: 'string' },
    status: { type: 'string', enum: ['implemented', 'audited', 'partial', 'blocked'] },
    summary: { type: 'string' },
    files_new: { type: 'array', items: { type: 'string' } },
    files_modified: { type: 'array', items: { type: 'string' } },
    gate_status: { type: 'string', description: 'how it was verified (tool + result), or precisely why it cannot be gated in this environment' },
    toolchain: { type: 'string', description: 'which of iverilog/vvp/verilator/yosys/z3 are present (C.12); n/a for C.10' },
    escalations: { type: 'array', items: { type: 'string' }, description: 'golden/metal/reseal/kernel-link/toolchain actions the orchestrator must do' },
    risks: { type: 'array', items: { type: 'string' } },
    integration_notes: { type: 'string' },
  },
}

const HARD = [
  'You are working inside an ISOLATED git worktree on the III system (self-hosted, determinism-gated). FIRST run pwd + git rev-parse --show-toplevel and report it as worktree_path; your edits MUST PERSIST (no git checkout/clean/revert at the end).',
  'HARD CONSTRAINTS (reserved to the orchestrator -- never touch): COMPILED/iiis-2.exe and its golden (.mhash/.witness.json); COMPILER/BOOT/** (esp. iii_compositions.def); lex/parse/sema/cg_*.iii; do NOT run build_iiis2.sh or any reseal; do NOT edit any STDLIB/iii/*.iii except a pure inert doc-comment if your unit explicitly calls for one. Anything else that would require those -> describe in escalations, do not do it.',
  'NIH: hand-roll everything; libc + III BOOT only for .iii. (Verilog/SystemVerilog RTL is the hardware realization itself, not a third-party dep.) NO placeholders/stubs/TODO-punts/pretend-success; if a part cannot be safely completed or gated here, put it in risks/escalations with precise detail -- never fake it.',
].join('\n')

function verilogPrompt() {
  return HARD + '\n\n' + [
    'UNIT: C.12 -- Hardware realization (R2-GENESIS Verilog RTL of the resolver). Read DOCS/III-CAPABILITY-APOTHEOSIS.md lines 564-583 (your section) + lines 634-651 (caveats). The live file R2-GENESIS/silicon/resolver_unit.v EXISTS (~484 lines) and realizes resolver.iii 12-step resolution; resolver_unit_formal.sv + the equivalence corpus are ABSENT.',
    'VERIFY-THEN-CERTIFY first: read resolver_unit.v end-to-end and resolver.iii (omnia/) so the RTL is a faithful twin; report the actual current state (which of the 7 gaps are already closed) before editing.',
    'DELIVER (status=implemented or partial): close the 7 structural gaps the doc specifies -- (1) the 8-wide 3-stage pairwise-max tournament tree replacing slot-0 selection (the true argmax); (2) the memo unit write path; (3) SHA-256-truncated-to-128-bit content-address key (replacing the weak XOR); (4) the sealed K-cost ROM bound to sealed_root_mhash; (5) the full 960-bit witness record; (6-7) the I-INSTR v1.0 control+status fields. THEN the capstone: resolver_unit_formal.sv (synthesize->gate netlist->SMT-prove equivalence to resolver.iii) + a 12-case equivalence corpus test_200_18_primitives.sv (+11 more) asserting byte-identical verdicts vs resolver.iii, with a NEGATIVE arm (a deliberately-wrong RTL tournament that picks slot 0 must FAIL the equivalence corpus).',
    'TOOLCHAIN: run `which iverilog vvp verilator yosys z3 sby 2>&1` (and version). If a simulator is present, COMPILE+RUN the equivalence corpus and report exit/results in gate_status. If absent, the .v/.sv are correct-by-construction artifacts that CANNOT be gated here -- say so precisely in gate_status + toolchain + escalations (this is a verified environment block, not a hidden defer). Report the `toolchain` field with exactly what is present.',
    'You MAY add a single inert doc-comment to omnia/resolver.iii cross-referencing the Phase-C.5 shortcut as the same audited spec-deviation the RTL encodes (doc C.12 item 4) -- nothing functional, no hash move. Report it in files_modified.',
  ].join('\n')
}

function ring0AuditPrompt() {
  return HARD + '\n\n' + [
    'UNIT: C.10 -- Katabasis descent gate & Ring-0 deploy. This is KERNEL / Ring-0 / BSOD territory. The user CRASH PROTOCOL is ABSOLUTE: PHASE 1 is READ-ONLY EVIDENCE GATHERING. You MUST NOT edit or create any .iii / .c / .sov source, and you MUST NOT attempt any kernel build or deploy. Your entire deliverable is a precise, exhaustive READ-ONLY crash-path audit + build plan written to ONE new doc file in your worktree (DOCS/CRASH-AUDIT-C10-r3-ioctl.md).',
    'Read DOCS/III-CAPABILITY-APOTHEOSIS.md lines 517-538 (your section). Then read end-to-end, READ-ONLY: katabasis/gate.iii (katabasis_gate_admit, _decide_term), katabasis/{cycle_family,ring_lattice,vmexit,bricking}.iii, COMPILER/BOOT/cg_r0.iii (the r0_emit_sym_run kernel-import primitive -- READ ONLY, do not edit), and any KATABASIS-DEPLOY/src/gate_resident.* if present. Confirm what already exists vs what the doc calls the one wiring gap (the R3 IOCTL bridge r3_ioctl_driver.c, currently ABSENT).',
    'PRODUCE in DOCS/CRASH-AUDIT-C10-r3-ioctl.md: (1) the verified current state (gate complete? proven-on-metal HIST?); (2) an enumerated crash-path analysis for the proposed r3_ioctl_driver.c kernel driver -- every IRQL/probe/buffer/IOCTL-METHOD/UAF/stack-balance hazard, numbered, per CRASH PROTOCOL; (3) the exact, ordered build plan (DriverEntry, KatabasisGateIOCTL forwarding the intent manifest to katabasis_gate_admit, NTSTATUS mapping, the ntoskrnl link) so the future metal session is one focused, audited step; (4) escalations = everything that requires an explicit trigger (kernel build toolchain, a Ring-0 test target, the BSOD-risk deploy) -- these are environment/trigger blocks, NOT defers.',
    'status=audited; gate_status = "read-only crash-path audit (CRASH PROTOCOL Phase 1); no code built -- kernel deploy is trigger-gated". files_new = the audit doc. files_modified = []. NO source edits whatsoever.',
  ].join('\n')
}

phase('Frontier')
const results = await parallel([
  () => agent(verilogPrompt(), { label: 'C.12:verilog', phase: 'Frontier', isolation: 'worktree', schema: REPORT_SCHEMA }),
  () => agent(ring0AuditPrompt(), { label: 'C.10:ring0-audit', phase: 'Frontier', isolation: 'worktree', schema: REPORT_SCHEMA }),
])

return results
