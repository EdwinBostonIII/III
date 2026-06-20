export const meta = {
  name: 'iii-defect-discovery-w23-protocol',
  description: 'State-machine / lifecycle protocol-invariant audit -- an illegal transition wrongly ACCEPTED',
  phases: [
    { title: 'Discover', detail: 'deep-read lifecycle state machines for accepted-illegal-transition bugs' },
    { title: 'Verify', detail: 'confirm with a concrete op-sequence that is wrongly accepted' },
  ],
}

const FOCUS = [
  'FOCUS: STATE-MACHINE / LIFECYCLE protocol invariants, NOT bounds/arithmetic.  Hunt for an ILLEGAL',
  'state transition that the code WRONGLY ACCEPTS (returns OK/success instead of an error), a state that',
  'can be SKIPPED, a precondition that is NOT checked, a USE-AFTER-DROP / DOUBLE-DROP / double-free, a',
  'refcount/used-count that can desync, or an operation valid only in state X that succeeds in state Y.',
  'A finding is REAL only if you can name a CONCRETE sequence of @export calls that SHOULD be rejected',
  '(per the documented lifecycle) but the code accepts (returns success / mutates state).  Quote the',
  'documented legal transitions, then show the illegal one the code allows.  Speculative is NOT a finding.',
  'Prefer transitions the existing KAT does not exercise (it tests the happy path, not every illegal edge).',
  'NOTE: the consensus core (hotstuff quorum/lock/commit, fed_seal tiers) was reviewed CLEAN in a prior',
  'wave -- only report a consensus bug with an airtight concrete counterexample.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        defect_class: { type: 'string' }, description: { type: 'string' },
        legal_lifecycle: { type: 'string', description: 'the documented legal transitions' },
        illegal_sequence: { type: 'string', description: 'the concrete @export call sequence that should be rejected but is accepted' },
        observed_accept: { type: 'string', description: 'what the code returns/does (the wrong acceptance)' },
        is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'defect_class', 'description', 'legal_lifecycle', 'illegal_sequence', 'observed_accept', 'is_export', 'confidence'],
    } },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
    real: { type: 'boolean', description: 'true ONLY if you traced the state logic and confirmed the illegal sequence is accepted' },
    traced_behavior: { type: 'string', description: 'your hand-trace: what the code does on the illegal sequence' },
    fix: { type: 'string' }, teeth: { type: 'string', description: 'the concrete sequence + expected-reject vs observed-accept' },
    refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'

const LENSES = [
  {
    key: 'governance-lifecycle',
    prompt: 'Deep-read the GOVERNANCE proposal state machine in ' + REPO + '/STDLIB/iii/ (omnia/governance.iii, ' +
      'aether/* governance, numera/reflection_governance.iii, and the constitution/charter modules).  The ' +
      'documented lifecycle (see corpus 205_governance_full_loop, 1474_gov_transition_walls): PENDING -> ' +
      'SANDBOXED -> PROVEN/REJECTED (and CANCELLED).  Find a transition that is wrongly accepted: e.g. ' +
      'sandboxing a non-PENDING proposal, proving an un-sandboxed one, transitioning from a terminal state, ' +
      'or acting on an unknown proposal id.  Check the guards use the EXACT current state (== not >=).\n' + FOCUS,
  },
  {
    key: 'sandbox-capability-lifecycle',
    prompt: 'Deep-read the SANDBOX + CAPABILITY lifecycle in ' + REPO + '/STDLIB/iii/ (aether/capability.iii, ' +
      'aether/cap_handshake.iii, aether/cap_forge.iii, the sandbox modules, handle.iii).  Lifecycle: ' +
      'mint/create -> attenuate -> use -> drop/revoke.  Find: USE-AFTER-DROP (a dropped cap/handle/session ' +
      'still works), DOUBLE-DROP (dropping twice corrupts the table or double-frees), attenuation that ' +
      'WIDENS rights instead of narrowing, or a revoked capability still authorizing.  Show the concrete ' +
      'mint->drop->use sequence that wrongly succeeds.\n' + FOCUS,
  },
  {
    key: 'resource-pool-lifecycle',
    prompt: 'Deep-read RESOURCE-POOL lifecycle in ' + REPO + '/STDLIB/iii/ (memoria/arena.iii, memoria/region.iii, ' +
      'memoria/seal_organ.iii, the handle/slot tables in queue/pq/bigint/groebner).  alloc -> use -> release/' +
      'reset.  Find: use-after-release (a released slot/region still readable), double-release (release twice ' +
      'desyncs the free count or the ABA witness), reset-while-live (reset invalidates live handles silently), ' +
      'or an allocation that succeeds past capacity.  Show the concrete sequence.\n' + FOCUS,
  },
  {
    key: 'federation-seal-ordering',
    prompt: 'Deep-read the FEDERATION / SEAL / ATTEST protocol ordering in ' + REPO + '/STDLIB/iii/ (aether/' +
      'fed_*.iii, sanctus/seal_*.iii, sanctus/attest.iii, the quorum/admit logic).  Find an ORDERING violation: ' +
      'an operation accepted out of order (seal before the inputs are bound, admit before the quorum is met, ' +
      'verify against a not-yet-computed digest), a missing freshness/nonce check (replay), or a tier/threshold ' +
      'comparison that is off (>= vs > letting one-too-few through).  Show the concrete out-of-order sequence.\n' + FOCUS,
  },
  {
    key: 'intent-resolver-dispatch',
    prompt: 'Deep-read the INTENT / RESOLVER dispatch lifecycle in ' + REPO + '/STDLIB/iii/omnia/ (resolver.iii, ' +
      'intent.iii, the calculus_v1 binding steps, the dispatch state).  Find: a dispatch accepted for an ' +
      'unresolved/unbound intent, a binding that skips a required step (digest/witness), a memo HIT that ' +
      'returns a result for the WRONG (set,intent,ctx) key (a hash collision not re-checked against the full ' +
      'key), or a state read before it is written.  Show the concrete sequence.\n' + FOCUS,
  },
]

phase('Discover')
log('W23 protocol-invariant discovery: ' + LENSES.length + ' lifecycle lenses (governance/sandbox-cap/resource/federation/intent)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III lifecycle/protocol defect by HAND-TRACING the state logic on the concrete sequence (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClass: ' + c.defect_class + '\n' +
  'Legal lifecycle: ' + c.legal_lifecycle + '\nClaimed illegal sequence (should be REJECTED): ' + c.illegal_sequence +
  '\nClaimed wrong acceptance: ' + c.observed_accept + '\n\n' +
  'Open the file, read ' + c.fn + ' + the state-transition guards + the state constants in full, and HAND-EXECUTE ' +
  'the illegal sequence step by step. Mark REAL only if: (1) the sequence is reachable through @export calls; ' +
  '(2) the documented/intended lifecycle FORBIDS it; (3) your hand-trace shows the code ACCEPTS it (returns ' +
  'success / mutates state) rather than returning an error; (4) it is a genuine invariant violation, not an ' +
  'intentional documented relaxation. Show your hand-trace + the guard that is missing/wrong. If the code ' +
  'actually REJECTS the sequence (a guard you missed), mark real=false and quote the guard.\n' + FOCUS

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(refutePrompt(c), { label: 'verify:' + c.fn, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    ))
  }
)

const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true)
log('W23 protocol discovery complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
