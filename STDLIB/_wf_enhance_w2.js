export const meta = {
  name: 'iii-enhance-discovery-w2',
  description: 'Round 2 lean capability compounds: deep NL/intent vein + fresh subsystems, sharpened verifier',
  phases: [
    { title: 'Discover', detail: 'capability-delta lenses, hip/intent deep + fresh subsystems, read-only' },
    { title: 'Verify', detail: 'adversarial RED/GREEN; reject cosmetic/already/ML/island/deliberate-PIN/perf-only' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'A candidate is REAL only if it yields a CONCRETE behavior delta provable by a KAT that is RED (different',
  'exit / result) on CURRENT code and GREEN after, the KAT DISTINGUISHING old from new. DEFAULT-REJECT:',
  '  (a) COSMETIC / byte-identical reroute: same result/bytes as today (cad_oneshot==sha256_oneshot pattern).',
  '  (b) ALREADY-IMPLEMENTED: grep the CONCEPT, not a prefix; if the live path already does it, reject + name it.',
  '  (c) ML-IN-DISGUISE: count-and-promote, observe-and-adapt, threshold/frequency/score learning -> forbidden.',
  '  (d) ISLAND: a new module no live caller invokes. Lean = wire INTO an existing live path.',
  '  (e) DELIBERATE-DESIGN PIN: the current behavior is documented in-code as an intentional invariant',
  '      ("zero-behaviour-change", determinism choice, "deliberately", a pinning corpus test). Overriding it',
  '      is a REGRESSION, not an enhancement. READ the function + its comments before claiming a gap.',
  '  (f) PERF-ONLY: the only observable is speed/trace/cycle-count, not a result/exit delta -> NOT a valid',
  '      RED/GREEN (a functional KAT passes identically on old + new).',
  '  (g) VAPOR: the faculty/API/constant does not actually exist as described.',
  'Prefer compounds where an EXISTING mature faculty\'s output is computed-but-discarded or available-but-not-',
  'consulted on a REAL live path, so III behaves differently on its OWN inputs (not just in a test).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          title: { type: 'string' },
          live_path: { type: 'string' }, faculty: { type: 'string' },
          currently: { type: 'string' }, delta: { type: 'string' },
          red_green_kat: { type: 'string' }, not_island: { type: 'string' },
          not_already: { type: 'string' }, not_pinned: { type: 'string', description: 'evidence the current behavior is NOT a documented deliberate invariant' },
          gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
          adjective: { type: 'string', enum: ['smarter', 'dynamic', 'intuitive'] },
          effort: { type: 'string', enum: ['small', 'medium', 'large'] },
          confidence: { type: 'number' },
        },
        required: ['title', 'live_path', 'faculty', 'currently', 'delta', 'red_green_kat',
                   'not_island', 'not_already', 'not_pinned', 'gate_tier', 'adjective', 'effort', 'confidence'],
      },
    },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, live_path: { type: 'string' }, faculty: { type: 'string' },
    real: { type: 'boolean' }, discriminator_holds: { type: 'boolean' }, fires_live: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'already_impl', 'ml_disguise', 'island', 'deliberate_pin', 'perf_only', 'vapor', 'not_live'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
    impact: { type: 'number' },
  },
  required: ['title', 'real', 'discriminator_holds', 'fires_live', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY capability-compound discovery over III (self-hosting .iii language+OS at ' + REPO + ').\n' +
  'Source root: ' + SRC + '. NO build/run/edit -- read source only.\n\nLENS: ' + focus + '\nLive paths: ' + paths +
  '\n' + (hints ? 'Where to look: ' + hints + '\n' : '') +
  '\nFor each candidate: (1) what fires TODAY on the live path, (2) what fires AFTER, (3) the single assertion' +
  ' RED now / GREEN after. CRUCIAL: before claiming a gap, READ the function AND its comments -- if the current' +
  ' behavior is a documented deliberate invariant, it is NOT a gap (reject). Lean = land INSIDE an existing' +
  ' module; no islands.\n\n' + REJECT

const LENSES = [
  { key: 'hip-roles-deep', prompt: lp(
    'INTUITIVE -- remaining dropped/under-used semantic roles in hip\'s NL->intent projection.',
    'verba/hip.iii _hip_project_verb + hip_resolve; verba/nl_parse.iii roles; verba/intent.iii constructors.',
    'hip already wires VERB/PATIENT/SOURCE/DESTINATION/INSTRUMENT/LOCATION(new)/CONDITION(new). Find roles still ' +
    'DROPPED that map to a real intent slot/primitive: BENEFICIARY (for X), OF (X of Y, mereological), MODAL ' +
    '(must/should -> intent_set_required_guarantees), a 2nd INSTRUMENT, or a verb whose mapping ignores an ' +
    'available role. Each must have a registered-word KAT sentence (nl_lex is hash-exact; verify the words exist). ' +
    'This vein already produced 2 confirmed compounds -- mine the rest.') },
  { key: 'intent-calculus-coverage', prompt: lp(
    'SMARTER -- Intent Calculus primitives producible from NL but not produced by hip/babel.',
    'sanctus/calculus_v1.iii, verba/intent.iii (then/with/under/loop/lift/reflect/abstract/grant/govern/compose), ' +
    'verba/hip.iii, omnia/babel.iii, omnia/babel_intent.iii.',
    'intent.iii exports rich combinators (intent_then/with/under/loop/compose/grant/govern). Does hip or babel ' +
    'PRODUCE these from NL surface forms (sequencing "then", composition "and", iteration "while/each")? Find a ' +
    'surface form recognized by nl_parse (CONJ/then/each) that hip drops instead of composing via the matching ' +
    'calculus primitive. RED/GREEN = the sentence yields the composite intent kind, not a single primitive.') },
  { key: 'idoc-babel-glyph', prompt: lp(
    'DYNAMIC -- producer/consumer gaps in the idoc/babel/glyph serialization stack.',
    'aether/idoc.iii, omnia/babel.iii, omnia/babel_intent.iii, verba/glyph_*.iii, aether/babel_wire.iii.',
    'Find a built consumer/decoder with no live producer (or vice versa), or a glyph type/intent field that ' +
    'serializes but does not round-trip, or an idoc field computed but never emitted/consumed. RED/GREEN = a ' +
    'round-trip that loses-then-recovers a field, distinguishable by reading it back. Reject byte-identical reroutes.') },
  { key: 'tempora-civil', prompt: lp(
    'INTUITIVE -- civil-time conveniences computed-but-unexposed or parse/format asymmetries.',
    'tempora/calendar.iii, tempora/rfc3339.iii, tempora/duration.iii, tempora/instant.iii, tempora/deadline.iii.',
    'Find a civil-time capability the modules COMPUTE internally but do not expose, or an asymmetry where parse ' +
    'accepts a form that format cannot emit (or vice versa), or a duration/calendar convenience (weekday, ' +
    'day-of-year, ISO week) derivable from existing fields but absent. RED/GREEN = the new accessor returns the ' +
    'correct civil value where today there is none. AVOID adding an island -- it must extend an existing module.') },
  { key: 'aether-net-capability', prompt: lp(
    'DYNAMIC -- capability gaps on the live HTTP/URI/TCP request-response path.',
    'aether/http.iii, aether/http_client.iii, aether/http_server.iii, verba/uri.iii, aether/tcp.iii, aether/inet.iii.',
    'Find a parsed-but-unused HTTP/URI element (a header, a URI component, a status class) that a live builder/' +
    'responder could honor but ignores, or a request/response field computed but not threaded. RED/GREEN = the ' +
    'built request/response now reflects the element where today it is dropped. Reject if it is already honored.') },
  { key: 'cross-faculty-live-consult', prompt: lp(
    'DYNAMIC+SMARTER -- a mature analyzer whose verdict is computed but NOT acted on at a live gateway.',
    'aether/develop_up.iii, aether/sealed_box/replay_box/compute_box/snapshot_box, aether/flow_firewall.iii, ' +
    'aether/sentinel.iii, numera/taint_analysis.iii, numera/reversible.iii, aether/determinism_firewall.iii.',
    'DISTINCT from round-1 refutations (taint-path surfacing, sentinel spectral, du_ingress -- all refuted). Find a ' +
    'DIFFERENT computed-but-unconsumed verdict: a determinism/reversibility/quota check whose RESULT a live ' +
    'gateway computes but does not branch on (admit/refuse/rollback). RED/GREEN = a divergent/hostile input is now ' +
    'refused/rolled-back where it was admitted. Must fire on a REAL caller, not only a corpus KAT.') },
]

phase('Discover')
log('W2 enhance-discovery: ' + LENSES.length + ' lenses (hip/intent deep + fresh subsystems)')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification of an III capability-compound candidate. CONFIRM or REFUTE by reading' +
  ' source. No build/run/edit.\n\nTitle: ' + c.title + '\nLive path: ' + c.live_path + '\nFaculty: ' + c.faculty +
  '\nCurrently: ' + c.currently + '\nDelta: ' + c.delta + '\nRED/GREEN: ' + c.red_green_kat +
  '\nNot-island: ' + c.not_island + '\nNot-already: ' + c.not_already + '\nNot-pinned: ' + c.not_pinned + '\n\n' +
  'Open the live_path fn AND the faculty IN FULL, including comments. real=true ONLY if ALL hold:\n' +
  '  (1) the live path does NOT already do it (grep the concept) -- else already_impl;\n' +
  '  (2) the faculty/API/constant exists exactly -- else vapor;\n' +
  '  (3) the current behavior is NOT a documented deliberate invariant -- else deliberate_pin;\n' +
  '  (4) a KAT RED-now/GREEN-after DISTINGUISHES old from new at the RESULT/exit level -- else cosmetic/perf_only;\n' +
  '  (5) it lands INSIDE an existing module / live caller -- else island; (6) derives, never observes -- else ml.\n' +
  'For hip candidates, CONFIRM the KAT sentence words are registered in nl_lex (hash-exact, no stemming).\n' +
  'Give impl_sketch (file:fn + edit + KAT arms), gate_tier, impact 0-100. If refuted, name the reject class.\n\n' + REJECT

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(verifyPrompt(c), { label: 'verify:' + lens.key, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
        .then((v) => v ? { ...v, lens: lens.key, effort: c.effort, adjective: c.adjective } : null)
    ))
  }
)

const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true && v.discriminator_holds === true && v.fires_live === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W2 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
