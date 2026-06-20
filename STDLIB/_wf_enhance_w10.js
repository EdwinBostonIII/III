export const meta = {
  name: 'iii-enhance-discovery-w10',
  description: 'Round 10: dead-structure producer-consumer hunt on the UN-MINED heavyweight subsystems (forcefield/develop-up, sovereign-witness, memoria, tempora, crypto-internals, self-improve)',
  phases: [
    { title: 'Discover', detail: 'producer-emits-rich/consumer-drops-it over un-swept subsystems, read-only' },
    { title: 'Verify', detail: 'adversarial: live consumer, OBSERVABLE delta, not by-design/island/unreachable' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'Hunt the hip->resolve PATTERN (the one MASSIVE lever this arc): a PRODUCER computes/emits rich structure that a',
  'LIVE CONSUMER on the same path IGNORES/FLATTENS/DROPS.  REAL only if: (1) the producer genuinely emits it (name',
  'the field+fn); (2) a LIVE consumer (real caller, not a KAT) provably drops it; (3) honoring it changes an',
  'OBSERVABLE RESULT (probe-grade -- NOT witness-chain-only/internal-only; the ai_resolve composite was COSMETIC',
  'because dispatch returns a constant, and resolver next_score was an ISLAND with no consumer); (4) honoring does',
  'NOT violate a DELIBERATE separation.  This arc has REPEATEDLY been burned by 4 reject classes -- weight them',
  'HEAVILY: (a) UNREACHABLE (region_alloc/SHA-512/AES-GCM 2^61-byte, tcp & 0xFFFFFFFF -- the bad input is',
  'physically/practically impossible); (b) BY-DESIGN (governance cap==0 system-level, kchain underflow Phase-A',
  'deferred-to-Phase-C + consumed by quality Q5, json sticky-error-latch, NL surface understand-only via',
  'meta_dispatch_unreachable, replay mhash-only per FROZEN SPEC); (c) ISLAND (babel_intent send/receive have ZERO',
  'live callers; resolver next_score; any @export with no non-KAT caller); (d) PERF-ONLY.  Before reporting, GREP',
  'the consumer concept + PROVE a live non-KAT caller reaches the drop with a real input.  ALREADY DONE/MINED: hip',
  '->resolve composites; fix_div; http_server/q128_f64/sandbox/http X19; PT_SYMMETRY; rfc3339/json/base32/utf8/hex/',
  'leb128.  cost/nous/prover/parser/capability were swept in W9 (0 buildable) -- do NOT re-report those.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { candidates: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    properties: {
      title: { type: 'string' }, producer: { type: 'string' }, consumer: { type: 'string', description: 'the LIVE consumer fn + line' },
      dropped: { type: 'string' }, observable_delta: { type: 'string' },
      live_caller: { type: 'string', description: 'a SPECIFIC non-KAT caller that reaches the drop' },
      red_green_kat: { type: 'string' }, exact_values: { type: 'string' },
      not_bydesign: { type: 'string' }, not_island: { type: 'string' }, not_unreachable: { type: 'string' }, not_cosmetic: { type: 'string' },
      gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
      scale: { type: 'string', enum: ['massive', 'medium', 'small'] }, confidence: { type: 'number' },
    },
    required: ['title', 'producer', 'consumer', 'dropped', 'observable_delta', 'live_caller', 'red_green_kat',
               'exact_values', 'not_bydesign', 'not_island', 'not_unreachable', 'not_cosmetic', 'gate_tier', 'scale', 'confidence'],
  } } },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, real: { type: 'boolean' },
    producer_emits: { type: 'boolean' }, consumer_drops_live: { type: 'boolean' }, observable_delta_real: { type: 'boolean' }, live_caller_exists: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'by_design', 'island', 'unreachable', 'already', 'perf_only', 'vapor'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' }, exact_values: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] }, impact: { type: 'number' },
  },
  required: ['title', 'real', 'producer_emits', 'consumer_drops_live', 'observable_delta_real', 'live_caller_exists', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY discovery over III (self-hosting .iii at ' + REPO + ').\nSource: ' + SRC + '. NO build/run/edit.\n\n' +
  'LENS: ' + focus + '\nFiles: ' + paths + '\n' + (hints ? 'Hint: ' + hints + '\n' : '') +
  '\nFind a PRODUCER emitting rich structure a LIVE CONSUMER drops, honoring it changes an OBSERVABLE result, and a' +
  ' SPECIFIC non-KAT caller reaches it.  READ both fns + comments; a deliberate separation / island / unreachable' +
  ' is a REJECT.\n\n' + REJECT

const LENSES = [
  { key: 'forcefield-developup-consumer', prompt: lp(
    'a forcefield/develop-up/encapsulation faculty computes a rich verdict/taint/snapshot a live consumer flattens',
    'forcefield/develop_up.iii, forcefield/pleroma.iii, forcefield/ripple.iii, forcefield/forked_walk.iii, forcefield/snapshot_lattice.iii, forcefield/taint_analysis.iii, forcefield/reversible.iii',
    'A sealed-box / develop-up organ computes a structured result (a taint set, a snapshot delta, a behavioral diff, ' +
    'a forced-fork outcome) that a live caller reduces to a bool/scalar, dropping the structure.  Honoring = a finer ' +
    'decision.  PROVE a non-KAT caller + an observable delta (not witness-only).') },
  { key: 'sovereign-witness-consumer', prompt: lp(
    'a sovereign-witness / observe / seal organ emits a rich analysis a live consumer reduces to pass/fail',
    'sanctus/observe.iii, sanctus/witness.iii, sanctus/seal.iii, sanctus/replay.iii, omnia/proof_term.iii, omnia/sovereign_cert.iii',
    'An offline analyzer (lift/analyze/seal) produces a structured witness (a counterexample, a bounded-MC trace, a ' +
    'proof path) a live consumer collapses to a bool.  Honoring must change an OBSERVABLE result.  Beware: replay/' +
    'seal mhash-only checks are FROZEN-SPEC by-design.') },
  { key: 'memoria-tempora-consumer', prompt: lp(
    'a memory/time organ computes richer info (provenance, lifetime, civil breakdown) a live consumer drops',
    'memoria/arena.iii, memoria/region.iii, memoria/span.iii, memoria/tempaloc.iii, tempora/instant.iii, tempora/deadline.iii, tempora/duration.iii',
    'An arena/region/span carries provenance/lifetime/typed-handle info, or a time organ computes a civil/duration ' +
    'breakdown, that a live consumer ignores.  Honoring = the consumer exposes/acts on it.  Distinct from the ' +
    'already-done duration/calendar accessors.  Reject churn accessors with no consumer.') },
  { key: 'crypto-suite-consumer', prompt: lp(
    'a crypto organ computes a rich result (a recovery id, a cofactor, a validity reason) a live consumer reduces',
    'numera/ec256.iii, numera/ed25519.iii, numera/rsa.iii, numera/mlkem.iii, numera/aes_gcm.iii, numera/hmac.iii, numera/merkle.iii, numera/pq_dispatch.iii',
    'A sign/verify/KEM organ computes a structured outcome (a recovery id, an error reason distinct from generic ' +
    'fail, a partial validity) a live consumer collapses to ok/fail, dropping a distinction a caller needs.  Honor ' +
    '= the distinction surfaces.  Beware: privacy-folds (constant-time, NOMATCH-folding) are DELIBERATE.') },
  { key: 'selfimprove-optimizer-consumer', prompt: lp(
    'a self-improvement/optimizer organ computes a rich plan/candidate-set a live consumer takes only the head of',
    'omnia/self_improve.iii, omnia/self_reformatter.iii, omnia/ripple_optimizer.iii, omnia/topo_extract.iii, omnia/kernel_proof.iii, omnia/certified_morphism.iii',
    'A self-optimizer produces a ranked set of rewrites/candidates/morphisms but the live executor applies only the ' +
    'first, dropping the alternatives / the proof-carrying metadata.  Honoring = the executor considers more / ' +
    'carries the proof.  Must have a live executor (not a KAT) + an observable delta.') },
]

phase('Discover')
log('W10 dead-structure hunt on UN-MINED subsystems: ' + LENSES.length + ' lenses')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification. CONFIRM or REFUTE by reading source. No build/run/edit.\n\nTitle: ' + c.title +
  '\nProducer: ' + c.producer + '\nConsumer (live): ' + c.consumer + '\nDropped: ' + c.dropped +
  '\nObservable delta: ' + c.observable_delta + '\nLive caller: ' + c.live_caller + '\nRED/GREEN: ' + c.red_green_kat +
  '\nExact: ' + c.exact_values + '\nNot-by-design: ' + c.not_bydesign + '\nNot-island: ' + c.not_island +
  '\nNot-unreachable: ' + c.not_unreachable + '\n\n' +
  'Open BOTH the producer and consumer fns IN FULL incl. comments, AND grep for the consumer\'s live (non-KAT)' +
  ' callers. real=true ONLY if: (1) producer emits the rich structure; (2) a LIVE non-KAT consumer drops it' +
  ' (consumer_drops_live + live_caller_exists -- if the only callers are corpus/KAT files, set live_caller_exists' +
  ' false and reject ISLAND); (3) honoring changes an OBSERVABLE result (observable_delta_real -- not witness/' +
  'internal-only -> else cosmetic); (4) NOT a deliberate separation (by_design); (5) NOT unreachable.  This arc has' +
  ' a HIGH false-positive rate from these 4 classes -- be skeptical, grep the callers, prove reachability.  Give' +
  ' impl_sketch + exact_values + gate_tier + impact.  If refuted name the reject class precisely.\n\n' + REJECT

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(verifyPrompt(c), { label: 'verify:' + lens.key, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
        .then((v) => v ? { ...v, lens: lens.key, scale: c.scale } : null)))
  }
)
const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true && v.producer_emits === true && v.consumer_drops_live === true && v.observable_delta_real === true && v.live_caller_exists === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W10 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
