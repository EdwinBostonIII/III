export const meta = {
  name: 'iii-enhance-discovery-w5',
  description: 'Round 5: CONSUMER-side -- does a live path act on the richer intent kinds/guarantees hip now produces, or drop them?',
  phases: [
    { title: 'Discover', detail: 'consumer-side producer/consumer-gap lenses, hard use-bar, read-only' },
    { title: 'Verify', detail: 'adversarial RED/GREEN end-to-end; reject cosmetic/already/ML/island/PIN/perf/churn' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'A candidate is REAL only if a KAT pins a CONCRETE behavior delta RED-now/GREEN-after at the RESULT/exit level',
  '(a new accessor may RED via link-failure PROVIDED it then pins EXACT values -- a 0/constant stub must fail).',
  'DEFAULT-REJECT: (a) COSMETIC/byte-identical; (b) ALREADY-IMPLEMENTED (grep the CONCEPT; name the symbol);',
  '(c) ML-IN-DISGUISE; (d) ISLAND (no live caller); (e) DELIBERATE-DESIGN PIN (READ the fn+comments);',
  '(f) PERF-ONLY; (g) VAPOR; (h) CHURN -- a mechanical accessor/handler with NO plausible consumer, or one a',
  'caller can already do in one existing call.  HARD USE-BAR: every candidate must name the END-TO-END flow it',
  'unblocks (producer X already emits this; consumer Y now acts on it instead of dropping it).  This round is',
  'the CONSUMER side of work already landed: hip now emits PRIMITIVE_IF(15)/UNDER(14)/WITH(13)/THEN(12)',
  'composites + sets intent_required_guarantees (MODAL).  Already-landed (DO NOT re-report): all the hip',
  'PRODUCER roles, calendar/duration/ini/rune/hex/leb128/path/rfc3339/json/HTTP recoveries.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { candidates: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    properties: {
      title: { type: 'string' }, live_path: { type: 'string', description: 'the CONSUMER fn that drops/mishandles' },
      producer: { type: 'string', description: 'what already PRODUCES the richer data' },
      dropped: { type: 'string', description: 'the exact value/structure the consumer drops, + line' },
      end_to_end: { type: 'string', description: 'the end-to-end flow the fix unblocks' },
      red_green_kat: { type: 'string' }, exact_values: { type: 'string' },
      not_island: { type: 'string' }, not_already: { type: 'string' }, not_pinned: { type: 'string' },
      gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
      adjective: { type: 'string', enum: ['smarter', 'dynamic', 'intuitive'] },
      effort: { type: 'string', enum: ['small', 'medium', 'large'] }, confidence: { type: 'number' },
    },
    required: ['title', 'live_path', 'producer', 'dropped', 'end_to_end', 'red_green_kat', 'exact_values',
               'not_island', 'not_already', 'not_pinned', 'gate_tier', 'adjective', 'effort', 'confidence'],
  } } },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, live_path: { type: 'string' }, real: { type: 'boolean' },
    discriminator_holds: { type: 'boolean' }, fires_live: { type: 'boolean' }, end_to_end_real: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'already_impl', 'ml_disguise', 'island', 'deliberate_pin', 'perf_only', 'vapor', 'churn'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' }, exact_values: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] }, impact: { type: 'number' },
  },
  required: ['title', 'real', 'discriminator_holds', 'fires_live', 'end_to_end_real', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY consumer-side discovery over III (self-hosting .iii at ' + REPO + ').\nSource: ' + SRC +
  '. NO build/run/edit.\n\nLENS: ' + focus + '\nFiles: ' + paths + '\n' + (hints ? 'Hint: ' + hints + '\n' : '') +
  '\nFind a CONSUMER that receives data a PRODUCER already emits but DROPS or mishandles the richer part.  Name' +
  ' the end-to-end flow the fix unblocks.  READ the consumer fn + comments before claiming a gap.\n\n' + REJECT

const LENSES = [
  { key: 'intent-composite-consumer', prompt: lp(
    'do live consumers of intents ACT on the composite kinds (IF/UNDER/WITH/THEN) or only the primitives?',
    'sanctus/calculus_v1.iii, omnia/codegen_dispatch.iii, omnia/resolver.iii, omnia/ai_resolve.iii, omnia/babel_intent.iii, omnia/resolution_init.iii',
    'hip now emits IF(15)/UNDER(14)/WITH(13)/THEN(12) composites (each with sub-intent ids in partial_arg 0/1).' +
    '  Does any live consumer that dispatches on intent_goal_kind handle ONLY 1-11 and silently drop/misroute a' +
    ' 12-15 composite (e.g. lowering, evaluation, dispatch, validation)?  RED: a composite intent is dropped/' +
    'mis-evaluated; GREEN: its sub-intents are recursed/dispatched.  Confirm the consumer is a LIVE path.') },
  { key: 'guarantee-consumer', prompt: lp(
    'does any live path act on intent_required_guarantees (which MODAL now sets), or ignore it?',
    'omnia/resolver.iii, sanctus/calculus_v1.iii, omnia/governance.iii, omnia/codegen_dispatch.iii, omnia/babel_intent.iii',
    'hip now stamps required_guarantees from the modal force.  Does a live dispatcher/resolver/validator READ' +
    ' intent_required_guarantees and change behavior (stricter check / different route), or is it written-but-' +
    'never-read?  RED: a STRONG-modal intent routes identically to an unset one; GREEN: it is gated differently.') },
  { key: 'babel-intent-composite-roundtrip', prompt: lp(
    'does babel_intent serialize/deserialize the FULL composite intent (nested guard/body), or flatten it?',
    'omnia/babel_intent.iii, omnia/babel.iii, aether/idoc.iii, verba/intent.iii',
    'babel_intent emits goal_kind + fields.  For an IF/WITH/UNDER/THEN intent the meaning is in partial_arg 0/1' +
    ' (sub-intent ids).  Does the serializer EMIT the nested structure (so a round-trip reconstructs the' +
    ' composite), or drop the children -> a lossy round-trip?  RED: round-trip of a composite loses the body/' +
    'guard; GREEN: it survives.  Reject if already recursive or if no consumer round-trips intents.') },
  { key: 'producer-consumer-general', prompt: lp(
    'OTHER producer-consumer gaps: a field one side emits that the receiving side drops on a live path',
    'aether/idoc.iii, omnia/babel_wire.iii, aether/reach_core.iii, omnia/transform.iii, omnia/governance.iii, sanctus/observe.iii',
    'Distinct from intents.  A producer writes a field/flag/count into a wire/record/envelope that the live' +
    ' consumer never reads (or vice versa) -- making the produced data dead.  RED: the consumer behaves the same' +
    ' whether the field is set or not; GREEN: it now honors it.  Must be a real end-to-end flow, not churn.') },
]

phase('Discover')
log('W5 consumer-side: ' + LENSES.length + ' lenses (hard use-bar)')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification. CONFIRM or REFUTE by reading source. No build/run/edit.\n\nTitle: ' + c.title +
  '\nConsumer (live_path): ' + c.live_path + '\nProducer: ' + c.producer + '\nDropped: ' + c.dropped +
  '\nEnd-to-end: ' + c.end_to_end + '\nRED/GREEN: ' + c.red_green_kat + '\nExact: ' + c.exact_values +
  '\nNot-already: ' + c.not_already + '\nNot-pinned: ' + c.not_pinned + '\n\n' +
  'Open the CONSUMER fn IN FULL incl. comments. real=true ONLY if: (1) the consumer genuinely drops/mishandles' +
  ' the richer data (open it; grep the concept) -- not already handled; (2) the producer really emits it;' +
  ' (3) NOT a documented deliberate invariant; (4) a KAT pins an EXACT end-to-end RESULT delta RED-now/GREEN-' +
  'after (a stub fails); (5) the consumer is a LIVE path (a real caller, not only a KAT); (6) derives, never' +
  ' observes; (7) end_to_end_real -- the fix unblocks a concrete flow (else churn).  Give impl_sketch +' +
  ' exact_values + gate_tier + impact.  If refuted name the reject class precisely.\n\n' + REJECT

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(verifyPrompt(c), { label: 'verify:' + lens.key, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
        .then((v) => v ? { ...v, lens: lens.key, effort: c.effort, adjective: c.adjective } : null)))
  }
)
const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true && v.discriminator_holds === true && v.fires_live === true && v.end_to_end_real === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W5 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
