export const meta = {
  name: 'apotheosis-capability-fanout',
  description: 'Implement + adversarially verify III Capability-Apotheosis capabilities in isolated worktrees',
  phases: [
    { title: 'Implement' },
    { title: 'Verify' },
  ],
}

const DOC = 'DOCS/III-CAPABILITY-APOTHEOSIS.md'

// capability table: id, doc line range, tier ('stdlib' implement+gate | 'audit' audit-only), scope
const CAPS = [
  { id: 'C.2', lines: '280-307', tier: 'stdlib',
    scope: 'Classical crypto (RSA-PSS / ECDSA P-256+P-384 / Ed25519 / X25519). Per the design: delete RSA private Montgomery and route it to the shared S.2 CIOS organ (mont_load_raw / mont_cios_run / mont_store_raw in numera/bigint_div.iii); ECDSA P-384 gains RFC-6979 deterministic nonce; remove any dead _verify; X25519/Ed25519 gain algebra-kind tags in fz_algebra (EDWARDS / MONTGOMERY) + ed_mod_l; a new numera/bigint_io octet-marshalling organ. Conformance oracles you SHOULD embed as data: RFC 8032 (Ed25519), RFC 7748 (X25519), RFC 6979 (ECDSA), FIPS 186 / Wycheproof vectors. Precedent: corpus already embeds FIPS-197 / RFC-8439 / RFC-7748 / FIPS-205 vectors.' },
]

const REPORT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['capability', 'worktree_path', 'status', 'delta_vs_doc', 'build_result', 'escalations', 'risks', 'integration_notes'],
  properties: {
    capability: { type: 'string' },
    worktree_path: { type: 'string', description: 'absolute path of this agent worktree (git rev-parse --show-toplevel)' },
    status: { type: 'string', enum: ['implemented', 'audited', 'partial', 'blocked'] },
    delta_vs_doc: { type: 'string', description: 'what already existed in live code (certified, not re-added) vs what was genuinely implemented; corrected stale anchors' },
    files_new: { type: 'array', items: { type: 'string' } },
    files_modified: { type: 'array', items: { type: 'string' } },
    shared_files_touched: { type: 'array', items: { type: 'string' }, description: 'build_stdlib.sh / run_corpus.sh / shared organs (ntt/keccak/merkle/bigint) flagged for careful merge' },
    build_result: { type: 'string', description: 'the build_stdlib PASS/FAIL line, or n/a (audit)' },
    kats: { type: 'array', items: { type: 'object', additionalProperties: false, properties: {
      name: { type: 'string' },
      exit_code: { type: 'string' },
      expected: { type: 'string' },
      negative_arms: { type: 'string', description: 'the concrete bad inputs the KAT asserts are REJECTED' },
      vacuity_note: { type: 'string', description: 'why this KAT is NOT a round-trip tautology' },
    } } },
    conformance_oracle: { type: 'string', description: 'named external oracle (RFC/NIST/Wycheproof vector) embedded, or none' },
    escalations: { type: 'array', items: { type: 'string' }, description: 'compiler/golden/.def/metal/hardware actions the orchestrator must do manually' },
    risks: { type: 'array', items: { type: 'string' } },
    integration_notes: { type: 'string', description: 'cross-capability dependencies, ordering, merge hints; for audit tier the corrected file-by-file plan' },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['capability', 'verdict', 'holes', 'vacuity_risks', 'placeholders_found', 'unflagged_escalations', 'summary'],
  properties: {
    capability: { type: 'string' },
    verdict: { type: 'string', enum: ['SOUND', 'HOLES', 'INSUFFICIENT_EVIDENCE'] },
    holes: { type: 'array', items: { type: 'object', additionalProperties: false, properties: {
      location: { type: 'string' },
      why: { type: 'string' },
      severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
      fixable: { type: 'string' },
    } } },
    vacuity_risks: { type: 'array', items: { type: 'string' } },
    placeholders_found: { type: 'array', items: { type: 'string' } },
    unflagged_escalations: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string' },
  },
}

function brief(cap) {
  const lines = [
    'You are implementing ONE capability of the III self-hosted language Capability Apotheosis inside an ISOLATED git worktree. III is a self-hosted, determinism-gated, byte-conformance-critical language/compiler ecosystem. Quality bar: production-ready, no compromise, no placeholders.',
    '',
    'FIRST: run pwd and git rev-parse --show-toplevel -- that is YOUR worktree root; report it verbatim as worktree_path. All paths below are relative to it. Your edits MUST PERSIST: do not git checkout / clean / stash / revert them at the end.',
    '',
    'LEAD INSTRUCTION -- VERIFY-THEN-CERTIFY (the proven III method; ignoring it produces churn):',
    '  Read ' + DOC + ' your section spanning lines ' + cap.lines + ' (section ' + cap.id + ') AND lines 634-651 (Implementation caveats + Z whole-organism). The doc file:line anchors are ROUTINELY STALE/drifted (real examples: rsa_modexp doc-said 388 was actually 637; E-PQD-2 doc-said 43 was actually 32) and MUCH of your section may ALREADY exist in live code. Your FIRST deliverable is the verified DELTA between the doc design and the LIVE code: grep + Read the named files, CERTIFY what is already done (do NOT re-implement it), implement ONLY the genuine remaining deltas. Put this in delta_vs_doc with corrected anchors.',
    '',
    'HARD CONSTRAINTS (the determinism-critical surface is RESERVED to the orchestrator -- never touch it):',
    '  - Edit ONLY: STDLIB/iii/**/*.iii, STDLIB/corpus/*.iii, and to register your module STDLIB/scripts/build_stdlib.sh + STDLIB/scripts/run_corpus.sh.',
    '  - DO NOT touch: COMPILED/iiis-2.exe or its golden (.mhash / .witness.json); COMPILER/BOOT (ESPECIALLY iii_compositions.def -- it cascades into the compiler); lex/parse/sema/cg_ source. DO NOT run build_iiis2.sh or ANY reseal.',
    '  - If your capability genuinely REQUIRES a compiler/golden/.def change: DO NOT do it. Describe it precisely in escalations for the orchestrator to perform.',
    '  - NIH: libc + III BOOT headers ONLY. Hand-roll everything. No third-party dependencies.',
    '  - NO placeholders / stubs / TODO-punts / pretend-success / deferrals. Complete implementations only. If a part cannot be safely completed, put it in risks -- never fake it.',
    '',
    'FALSIFIER-FIRST KATs (the single most important quality gate):',
    '  Every KAT MUST have REAL negative arms that FAIL on bad input. A round-trip-only / tautological KAT is a FAILURE: III C.1 SLH-DSA keypair bugs PASSED round-trip yet were wrong -- only a conformance vector plus a negative arm caught them. Your KAT first job is to assert that BAD input is REJECTED (wrong tag, flipped bit, forged signature, out-of-range, wrong nonce). Where a real external conformance oracle exists (RFC/NIST/Wycheproof vectors), embed the vectors and assert byte-exact -- that is conformance DATA, not an NIH breach.',
    '',
    '.iii COMPILER TRAPS (live, avoid): an end-comment marker inside a block comment closes it early; a function-LOCAL var array indexed by a RUNTIME var SIGSEGVs (hoist to a module global); i32 signed ordering compiles UNSIGNED (use i64 or equality); string literals are NOT NUL-terminated (use a NUL-terminated byte array for libc string fns); a nonzero i64 literal immediately before a brace misparses (wrap in a u32-returning helper). Build hygiene: a MODIFIED existing module must compile to its CANONICAL object name or ar adds a duplicate and the linker uses STALE code; build_stdlib FAIL masks a stale lib -- always confirm the FAIL = 0 line.',
    '',
    'GATES (run in YOUR worktree; quick gates only -- full corpus/bench/reseal is the orchestrator final step):',
    '  1. bash STDLIB/scripts/build_stdlib.sh 2>&1 | tail -6 -- confirm FAIL = 0 (capture the PASS/FAIL line into build_result).',
    '  2. Compile each new KAT standalone with the in-tree COMPILED/iiis-2.exe (DO NOT rebuild it) and run it; corpus convention is exit 99 = success. Capture exit codes.',
    '  Pin COMPILED/iiis-2.exe verbatim; do not autodiscover another binary (a stale binary caused 20 phantom regressions historically).',
    '',
    'Deliver the structured report. Be exhaustive in escalations / risks / integration_notes: the orchestrator manually reviews every file you wrote, so flag every shared-file edit and every cross-capability assumption.',
  ]
  return lines.join('\n')
}

function implPrompt(cap) {
  if (cap.tier === 'audit') {
    const a = [
      'TIER: AUDIT-ONLY. Section ' + cap.id + ' is golden-moving / metal / hardware -- NOT a buildable stdlib .iii module you may complete here. DO NOT implement golden-moving, Ring-0 / metal, or hardware-RTL changes.',
      'Produce instead (status audited): (1) delta_vs_doc = a precise verified audit of what already exists in live code vs the design, with corrected file:line anchors; (2) integration_notes = a CORRECTED, ordered, file-by-file implementation plan for the orchestrator to execute manually (fixing every stale anchor); (3) kats = the KAT DESIGNS (name + exactly which positive and negative arms would prove it) -- describe, do not build; (4) escalations = every compiler/golden/.def/metal/hardware action required. build_result = n/a (audit). Read the real files; do not trust the doc anchors.',
      'SCOPE: ' + cap.scope,
    ]
    return brief(cap) + '\n\n' + a.join('\n')
  }
  const s = [
    'TIER: STDLIB -- implement to completion in your worktree and prove with quick gates.',
    'SCOPE: ' + cap.scope,
    'Workflow: (1) verify-then-certify the delta; (2) implement genuine deltas with NO placeholders; (3) write falsifier-first KAT(s) with real negative arms (embed conformance vectors where an oracle exists); (4) register in build_stdlib.sh (canonical object name) + add the EXPECTED entry to run_corpus.sh; (5) gate: build_stdlib FAIL = 0 + each KAT standalone exit 99. Report everything, including any shared organ you touched.',
  ]
  return brief(cap) + '\n\n' + s.join('\n')
}

function verifyPrompt(report, cap) {
  const v = [
    'You are an ADVERSARIAL VERIFIER in the math-olympiad dual-context-isolation discipline. You did NOT write this code and you are NOT grading it -- you are ATTACKING its proof to find where it is vacuous, faked, or unsafe.',
    'Capability: section ' + cap.id + '. The implementing agent reported (JSON):',
    JSON.stringify(report),
    '',
    'You MAY read any files under worktree_path to verify claims (Read / Grep / Bash). Run these attacks:',
    '  1. KAT VACUITY (highest priority): for each KAT, does its NEGATIVE arm ACTUALLY FAIL on bad input, or is it a round-trip / tautology a wrong implementation would also pass? (III precedent: C.1 keypair bugs passed round-trip but were wrong.) If a KAT claims conformance, is there a REAL named external oracle (RFC/NIST/Wycheproof vector embedded), or is conformance just self-consistency? Actually inspect the KAT source.',
    '  2. PLACEHOLDERS/STUBS: grep new/modified files for TODO, stub, unimplemented, pretend-success, a hardcoded return that fakes success, a dead branch masquerading as dispatch.',
    '  3. NIH BREACH: any dependency beyond libc + III BOOT headers?',
    '  4. UNFLAGGED ESCALATIONS: did it touch or need to touch COMPILED/iiis-2.exe, the golden, COMPILER/BOOT (iii_compositions.def), or lex/parse/sema/cg_ source WITHOUT listing it in escalations? Did it run a reseal?',
    '  5. H-2 / DOC-LITERAL TRAP: did it allocate inside a hot path (arena per call) where the design demands caller-owned fixed buffers?',
    '  6. BUILD REALITY: does build_result actually show FAIL = 0? Do claimed KAT exit codes match the convention (99 = pass)?',
    '',
    'Return the structured verdict. Cite file:line for every hole. SOUND only if negative arms genuinely fail on bad input AND there are no placeholders / unflagged escalations.',
  ]
  return v.join('\n')
}

phase('Implement')
const results = await pipeline(
  CAPS,
  (cap) => agent(implPrompt(cap), { label: 'impl:' + cap.id, phase: 'Implement', isolation: 'worktree', schema: REPORT_SCHEMA }),
  (report, cap) => agent(verifyPrompt(report, cap), { label: 'verify:' + cap.id, phase: 'Verify', schema: VERDICT_SCHEMA })
    .then((verdict) => ({ cap: cap.id, report: report, verdict: verdict }))
)

return results
