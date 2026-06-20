export const meta = {
  name: 'iii-defect-discovery-w24-protocol2',
  description: 'Protocol-invariant round 2 -- governance siblings + un-mined lifecycles (illegal transition accepted)',
  phases: [
    { title: 'Discover', detail: 'governance-family siblings + intent/cap/federation/crystal lifecycles' },
    { title: 'Verify', detail: 'confirm with a concrete op-sequence wrongly accepted' },
  ],
}

const FOCUS = [
  'FOCUS: STATE-MACHINE / LIFECYCLE invariants -- an ILLEGAL transition WRONGLY ACCEPTED (returns OK',
  'instead of an error).  EXEMPLAR JUST FIXED: governance_vote checked only the slot id, not the state,',
  'so a vote in a non-PROVEN state was accepted; every OTHER governance transition checks its exact',
  'precondition state.  Hunt for the SAME pattern: a @export transition/mutator that acts WITHOUT checking',
  'the entity is in the required state.  A finding is REAL only with a CONCRETE @export call sequence that',
  'SHOULD be rejected (per the documented lifecycle) but is accepted.',
  '',
  'DO NOT REPORT (refuted already): governance_vote (FIXED); sandbox_exec_kind/ctx (they ALREADY call',
  'sandbox_state()==SENTINEL as a LIVE check at the @export entry); the region/bigint/arena ABA on',
  'release-without-drop (DOCUMENTED caller contract "drop_arena before release" + the arena WITNESS guards',
  'realloc-ABA, not plain reset -- intentional design, not a bug).  Also do NOT report a "stale field not',
  'reset on slot reuse" unless a documented contract is violated AND it is observable + sensitive.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        defect_class: { type: 'string' }, description: { type: 'string' },
        legal_lifecycle: { type: 'string' }, illegal_sequence: { type: 'string' },
        observed_accept: { type: 'string' }, is_export: { type: 'boolean' }, confidence: { type: 'number' },
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
    real: { type: 'boolean' }, traced_behavior: { type: 'string' }, fix: { type: 'string' },
    teeth: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'

const LENSES = [
  {
    key: 'governance-siblings',
    prompt: 'Deep-read the GOVERNANCE-FAMILY siblings of the just-fixed governance_vote: ' + REPO + '/STDLIB/iii/' +
      'aether/branch_governance.iii and ' + REPO + '/STDLIB/iii/numera/reflection_governance.iii (+ any other ' +
      '*_governance / *_vote / *_propose / *_ratify).  governance_vote was missing a state-precondition check ' +
      '(it acted in any state).  Find the SAME pattern in these siblings: a @export vote/propose/ratify/promote/' +
      'transition that mutates without verifying the entity is in the required state.  Quote the legal lifecycle ' +
      'and the illegal transition the code accepts.\n' + FOCUS,
  },
  {
    key: 'intent-resolver-dispatch',
    prompt: 'Deep-read the INTENT/RESOLVER dispatch lifecycle in ' + REPO + '/STDLIB/iii/omnia/ (resolver.iii, ' +
      'intent.iii, calculus_v1, the binding steps + dispatch state).  Find a dispatch/bind/commit accepted for ' +
      'an entity in the wrong state (unresolved intent dispatched, binding that skips a required step, a commit ' +
      'before the proof/witness).  Show the concrete out-of-state sequence.\n' + FOCUS,
  },
  {
    key: 'capability-session-lifecycle',
    prompt: 'Deep-read the CAPABILITY / SESSION / HANDSHAKE lifecycle in ' + REPO + '/STDLIB/iii/aether/ ' +
      '(capability.iii, cap_handshake.iii, cap_forge.iii).  Lifecycle: init -> attenuate -> (handshake open -> ' +
      'use -> close) / revoke.  Find a transition accepted in the wrong state: use of an un-opened or closed ' +
      'session, attenuation after seal, a handshake step out of order, double-open, or a revoked cap still ' +
      'authorizing.  Note: a plain bounds-OOB is NOT this lens.  Show the concrete sequence.\n' + FOCUS,
  },
  {
    key: 'federation-seal-quorum-ordering',
    prompt: 'Deep-read the FEDERATION / SEAL / QUORUM ordering in ' + REPO + '/STDLIB/iii/aether/fed_*.iii and ' +
      REPO + '/STDLIB/iii/sanctus/seal_*.iii + attest.iii.  Find an ORDERING/threshold violation: admit before ' +
      'quorum met, seal before inputs bound, a tier/threshold compare off by one (>= vs >), a missing freshness/' +
      'nonce (replay), verify against a not-yet-computed digest.  (The hotstuff CORE was reviewed clean; only ' +
      'report fed_*/seal_* with an airtight concrete counterexample.)  Show the out-of-order sequence.\n' + FOCUS,
  },
  {
    key: 'crystal-proof-witness-lifecycle',
    prompt: 'Deep-read the CRYSTAL / PROOF / WITNESS lifecycle in ' + REPO + '/STDLIB/iii/omnia/ (crystal.iii, ' +
      'crystal_deps.iii, proof_ripple_*.iii) + ' + REPO + '/STDLIB/iii/sanctus/ (the witness chain, seal_resolver).  ' +
      'Find a transition accepted in the wrong state: sealing an incomplete crystal, reading a digest before ' +
      'it is finalized, a witness appended after the chain is sealed, a proof attached to a non-pending object.  ' +
      'Show the concrete out-of-state sequence.\n' + FOCUS,
  },
]

phase('Discover')
log('W24 protocol-2 discovery: ' + LENSES.length + ' lenses (gov-siblings + intent/cap/federation/crystal)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III lifecycle defect by HAND-TRACING the state logic on the concrete sequence (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClass: ' + c.defect_class + '\n' +
  'Legal lifecycle: ' + c.legal_lifecycle + '\nClaimed illegal sequence (should REJECT): ' + c.illegal_sequence +
  '\nClaimed wrong acceptance: ' + c.observed_accept + '\n\n' +
  'Open the file, read ' + c.fn + ' + the state guards + state constants in full, and HAND-EXECUTE the illegal ' +
  'sequence. Mark REAL only if: (1) reachable via @export; (2) the documented lifecycle forbids it; (3) your ' +
  'trace shows the code ACCEPTS it (returns success/mutates) rather than erroring; (4) it is a genuine invariant ' +
  'violation, not a documented contract/relaxation, and NOT one of the DO-NOT-REPORT items. Show your hand-trace ' +
  '+ the missing guard + a concrete teeth sequence. If the code REJECTS it (a guard you missed -- e.g. a ' +
  'state()==SENTINEL liveness check at the @export entry), mark real=false and quote the guard.\n' + FOCUS

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
log('W24 protocol-2 discovery complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
