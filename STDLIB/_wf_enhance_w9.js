export const meta = {
  name: 'iii-enhance-discovery-w9',
  description: 'Round 9: DEAD-STRUCTURE hunt -- a faculty that PRODUCES rich structure a live consumer DROPS (the hip->resolve pattern, generalized to other subsystems)',
  phases: [
    { title: 'Discover', detail: 'producer-emits-rich / consumer-drops-it lenses over un-mined subsystems, read-only' },
    { title: 'Verify', detail: 'adversarial: is the rich output REALLY dropped on a LIVE path, and does honoring it change the RESULT? reject cosmetic/by-design/island/already' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'This round hunts the hip->resolve PATTERN generalized: a PRODUCER computes/emits a rich structure (a field, a',
  'sub-record, a classification, a proof, a set of options) that a LIVE CONSUMER on the same data path IGNORES,',
  'FLATTENS, or DROPS -- so the producer\'s effort is wasted and honoring it would make the system materially',
  'smarter.  A candidate is REAL only if: (1) the producer genuinely emits the rich structure (name the field +',
  'fn); (2) a LIVE consumer (a real caller, not a KAT) receives it and provably drops/flattens it; (3) honoring it',
  'changes an OBSERVABLE RESULT (probe-grade -- NOT a witness-chain-only or internal-path-only change that leaves',
  'the return value identical; the ai_resolve composite was COSMETIC because the meta dispatch is a constant);',
  '(4) honoring it does NOT violate a DELIBERATE design separation (the NL understand/execute split, privacy folds,',
  'capability gating, address-space separation are INTENTIONAL -- READ the comments).  DEFAULT-REJECT: cosmetic/',
  'byte-identical-result; by-design separation; ALREADY-honored (grep the consumer); ISLAND (no live consumer);',
  'PERF-only; a producer whose output is ALREADY fully consumed.  ALREADY DONE: hip->resolve composites (IF/THEN/',
  'WITH/UNDER now honored); fix_div/http_server/rfc3339/json/base32/utf8/leb128/PT_SYMMETRY/sandbox-X19.  The NL',
  'surface is COMPLETE + by-design understand-only -- do NOT re-report ai_resolve/hip/resolver composite gaps.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { candidates: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    properties: {
      title: { type: 'string' }, producer: { type: 'string', description: 'fn + the rich structure it emits' },
      consumer: { type: 'string', description: 'the LIVE consumer fn that drops/flattens it + line' },
      dropped: { type: 'string', description: 'the exact rich value dropped' },
      observable_delta: { type: 'string', description: 'the OBSERVABLE result that changes when honored (not witness/internal-only)' },
      red_green_kat: { type: 'string' }, exact_values: { type: 'string' },
      live_consumer: { type: 'string', description: 'proof the consumer is a real live caller' },
      not_bydesign: { type: 'string', description: 'why honoring it does NOT violate a deliberate separation' },
      not_already: { type: 'string' }, not_cosmetic: { type: 'string' },
      gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
      scale: { type: 'string', enum: ['massive', 'medium', 'small'] }, confidence: { type: 'number' },
    },
    required: ['title', 'producer', 'consumer', 'dropped', 'observable_delta', 'red_green_kat', 'exact_values',
               'live_consumer', 'not_bydesign', 'not_already', 'not_cosmetic', 'gate_tier', 'scale', 'confidence'],
  } } },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, real: { type: 'boolean' },
    producer_emits: { type: 'boolean' }, consumer_drops_live: { type: 'boolean' }, observable_delta_real: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'by_design', 'already_honored', 'island', 'perf_only', 'vapor', 'fully_consumed'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' }, exact_values: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] }, impact: { type: 'number' },
  },
  required: ['title', 'real', 'producer_emits', 'consumer_drops_live', 'observable_delta_real', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY discovery over III (self-hosting .iii at ' + REPO + ').\nSource: ' + SRC + '. NO build/run/edit.\n\n' +
  'LENS: ' + focus + '\nFiles: ' + paths + '\n' + (hints ? 'Hint: ' + hints + '\n' : '') +
  '\nFind a PRODUCER that emits rich structure a LIVE CONSUMER drops/flattens, where honoring it changes an' +
  ' OBSERVABLE result (not an internal-path/witness-only change).  READ both fns + comments; a deliberate' +
  ' separation is NOT a gap.\n\n' + REJECT

const LENSES = [
  { key: 'cost-optimizer-consumer', prompt: lp(
    'a cost/optimizer/ripple faculty that COMPUTES a richer ranking/plan/frontier than its live consumer uses',
    'omnia/cost_lattice.iii, omnia/cost_manifold.iii, omnia/ripple.iii, omnia/pareto_frontier.iii, omnia/xii.iii, omnia/sov_isa.iii, omnia/cg_r3.iii',
    'A cost/optimizer computes a full frontier/ordering/plan but the consumer takes only the top-1 or a flattened ' +
    'scalar, dropping the richer structure (alternatives, the second-best, the gradient).  Honoring it = the ' +
    'consumer picks differently / exposes the richer plan.  Beware: a deterministic single-winner may be a PIN.') },
  { key: 'nous-proposer-consumer', prompt: lp(
    'the nous proposer emits ranked candidates but a live consumer takes only one / ignores the ranking',
    'nous/nous_search.iii, nous/nous_features.iii, nous/nous_conjecture.iii, nous/nous_policy.iii, omnia/self_improve.iii, omnia/self_reformatter.iii',
    'nous ranks the next term/candidate; does a live consumer use the FULL ranking (top-k, the scores) or collapse ' +
    'to top-1, dropping nous\'s richer signal?  Honoring = the consumer considers more candidates / uses the score.' +
    '  Distinguish from a deliberate single-best contract.') },
  { key: 'proof-witness-consumer', prompt: lp(
    'a prover/seal emits a rich proof/witness/cert structure a live consumer reduces to a bool',
    'omnia/proof_term.iii, omnia/kernel_proof.iii, sanctus/pcc.iii, sanctus/witness.iii, omnia/smt.iii, numera/merkle.iii',
    'A prover produces a structured proof/witness (steps, substitutions, a counterexample, a path) but the consumer ' +
    'checks only pass/fail, dropping the structure that could drive a better decision / error message / next step.' +
    '  Honoring must change an OBSERVABLE result, not just internal richness.') },
  { key: 'parse-richness-consumer', prompt: lp(
    'a parser emits a rich AST/typed structure a live consumer flattens to a scalar/bool',
    'verba/json.iii, verba/uri.iii, verba/semver.iii, aether/idoc.iii, aether/http.iii, verba/markup.iii, omnia/babel.iii',
    'A parser builds a rich structure (typed nodes, query params, prerelease tags, headers) but a live consumer ' +
    'collapses it (e.g. presence-only, first-only), dropping fields a caller needs.  Honoring = the consumer ' +
    'exposes/acts on the dropped field.  Distinct from the already-done json/uri/rfc3339 recoveries.') },
  { key: 'capability-context-consumer', prompt: lp(
    'a capability/context/governance faculty carries rich attenuation/lineage a live consumer ignores',
    'aether/capability.iii, aether/cap_forge.iii, omnia/call_context.iii, omnia/governance.iii, omnia/kchain.iii, forcefield/taint_analysis.iii',
    'A cap/context carries rich structure (attenuation mask, parent lineage, taint set, K-history) that a live ' +
    'consumer reduces to a single check, dropping the richer authority/provenance.  Honoring = a finer-grained ' +
    'decision.  Beware: capability minimalism + privacy folds are DELIBERATE -- only report a true dropped-richness.') },
]

phase('Discover')
log('W9 dead-structure hunt: ' + LENSES.length + ' lenses (producer-emits-rich / consumer-drops-it)')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification. CONFIRM or REFUTE by reading source. No build/run/edit.\n\nTitle: ' + c.title +
  '\nProducer: ' + c.producer + '\nConsumer (live): ' + c.consumer + '\nDropped: ' + c.dropped +
  '\nObservable delta: ' + c.observable_delta + '\nRED/GREEN: ' + c.red_green_kat + '\nExact: ' + c.exact_values +
  '\nLive-consumer: ' + c.live_consumer + '\nNot-by-design: ' + c.not_bydesign + '\nNot-already: ' + c.not_already + '\n\n' +
  'Open BOTH the producer and consumer fns IN FULL incl. comments. real=true ONLY if: (1) the producer really emits' +
  ' the rich structure; (2) a LIVE consumer (real caller, not just a KAT) provably DROPS/flattens it' +
  ' (consumer_drops_live); (3) honoring it changes an OBSERVABLE RESULT -- CRUCIAL: not a witness-chain-only or' +
  ' internal-path-only change that leaves the return identical (the ai_resolve composite was COSMETIC for exactly' +
  ' this reason: constant dispatch) (observable_delta_real); (4) honoring does NOT violate a DELIBERATE separation' +
  ' (NL understand/execute, privacy fold, capability minimalism, address-space) -- READ the comments -> by_design.' +
  '  Give impl_sketch + exact_values + gate_tier + impact.  If refuted name the reject class precisely.\n\n' + REJECT

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(verifyPrompt(c), { label: 'verify:' + lens.key, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
        .then((v) => v ? { ...v, lens: lens.key, scale: c.scale, confidence: c.confidence } : null)))
  }
)
const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true && v.producer_emits === true && v.consumer_drops_live === true && v.observable_delta_real === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W9 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
