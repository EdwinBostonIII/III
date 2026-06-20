export const meta = {
  name: 'iii-enhance-discovery-w4',
  description: 'Round 4: fresh-axis sweep -- decoder error-detail, numeric-derived, composable-missing-op, validation, format-symmetry',
  phases: [
    { title: 'Discover', detail: 'six diverse lenses for genuine lean wins, read-only' },
    { title: 'Verify', detail: 'adversarial RED/GREEN; reject cosmetic/already/ML/island/PIN/perf-only/churn' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'A candidate is REAL only if a KAT pins a CONCRETE behavior delta RED-now/GREEN-after that DISTINGUISHES',
  'old from new at the RESULT/exit level (a new accessor may RED via link-failure PROVIDED the KAT then pins',
  'EXACT correct values -- a 0/constant stub must fail).  DEFAULT-REJECT: (a) COSMETIC/byte-identical;',
  '(b) ALREADY-IMPLEMENTED (grep the CONCEPT; name the symbol); (c) ML-IN-DISGUISE (observe-and-adapt/threshold);',
  '(d) ISLAND (no live caller); (e) DELIBERATE-DESIGN PIN (in-code "caller-supplied"/"zero-behaviour-change"/',
  'determinism invariant -- READ the fn+comments); (f) PERF-ONLY (only speed/trace observable); (g) VAPOR;',
  '(h) CHURN -- a mechanical accessor with NO plausible consumer (e.g. an error-reason on a decoder nothing',
  'streams, or a getter for a value already trivially derivable from exports).  Every candidate must name a',
  'PLAUSIBLE USE that the delta enables.  Already-landed (DO NOT re-report): calendar weekday/doy, duration',
  'components, INI separator, rune utf8 error-class, hex partial-count, HTTP req/resp version, all hip NL roles',
  '(locative/conditional/reason/modal/conjunction).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { candidates: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    properties: {
      title: { type: 'string' }, live_path: { type: 'string' }, faculty: { type: 'string' },
      gap: { type: 'string', description: 'the exact value/op missing + where in source' },
      use: { type: 'string', description: 'the plausible consumer/use the delta enables (reject if none)' },
      red_green_kat: { type: 'string' }, exact_values: { type: 'string' },
      not_island: { type: 'string' }, not_already: { type: 'string' }, not_pinned: { type: 'string' },
      gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
      adjective: { type: 'string', enum: ['smarter', 'dynamic', 'intuitive'] },
      effort: { type: 'string', enum: ['small', 'medium', 'large'] }, confidence: { type: 'number' },
    },
    required: ['title', 'live_path', 'faculty', 'gap', 'use', 'red_green_kat', 'exact_values',
               'not_island', 'not_already', 'not_pinned', 'gate_tier', 'adjective', 'effort', 'confidence'],
  } } },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, live_path: { type: 'string' }, real: { type: 'boolean' },
    discriminator_holds: { type: 'boolean' }, fires_live: { type: 'boolean' }, has_real_use: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'already_impl', 'ml_disguise', 'island', 'deliberate_pin', 'perf_only', 'vapor', 'churn'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' }, exact_values: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] }, impact: { type: 'number' },
  },
  required: ['title', 'real', 'discriminator_holds', 'fires_live', 'has_real_use', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY discovery over III (self-hosting .iii at ' + REPO + ').\nSource: ' + SRC + '. NO build/run/edit.\n\n' +
  'LENS: ' + focus + '\nFiles: ' + paths + '\n' + (hints ? 'Hint: ' + hints + '\n' : '') +
  '\nName the exact gap + a PLAUSIBLE consumer the delta enables (no plausible use => reject as churn).  READ the' +
  ' fn + comments before claiming a gap.\n\n' + REJECT

const LENSES = [
  { key: 'decoder-error-detail', prompt: lp('decoders that collapse distinct errors / lose a consumed count',
    'verba/base64.iii, verba/base32.iii, verba/leb128.iii, verba/json.iii, verba/semver.iii, verba/uri.iii',
    'rune/hex already done.  Find a decoder that returns a single error sentinel for DISTINCT failures a caller ' +
    'would act on differently (truncated vs invalid-char vs overflow), or loses the count consumed.  Require a ' +
    'real streaming/diagnostic use.  Prefer ONE strong candidate over many mechanical ones.') },
  { key: 'numeric-derived', prompt: lp('numeric modules computing a derived quantity internally but not exposing it',
    'numera/bigint.iii, numera/modular.iii, numera/field.iii, numera/checked.iii, numera/fixed.iii, numera/q128.iii, numera/scalar.iii',
    'A value computed en route (bit-length, leading-zero count, is-zero/is-one fast flag, exact-quotient flag, ' +
    'remainder alongside a quotient) that callers must recompute.  Must be genuinely useful + exact-pinnable.') },
  { key: 'composable-missing-op', prompt: lp('a useful operation trivially composable from existing exports but absent',
    'verba/string.iii, verba/builder.iii, omnia/vec.iii, omnia/option.iii, omnia/result.iii, verba/path.iii, numera/bitops.iii',
    'Like calendar weekday/doy: a 1-3 line operation built from existing exports that is genuinely useful and ' +
    'missing (e.g. string trim/contains/split-count, vec last/contains, path stem/has-extension).  Reject if a ' +
    'caller can already do it in one existing call.') },
  { key: 'validation-completeness', prompt: lp('a parser/validator that accepts input it should reject (false-accept)',
    'verba/json.iii, verba/semver.iii, verba/uri.iii, verba/base64.iii, tempora/rfc3339.iii, numera/parse.iii',
    'A correctness gap (NOT a recovery): a malformed input wrongly ACCEPTED, or a valid input wrongly rejected.  ' +
    'RED: the bad input parses OK today; GREEN: it is refused (or vice versa).  This axis was mined in W62-83 ' +
    '([[project_iii_negpath_coverage_track]]) -- only report a GENUINELY new, source-confirmed gap.') },
  { key: 'struct-field-exposure', prompt: lp('a structure with a computed/stored field lacking an accessor',
    'omnia/crystal.iii, sanctus/witness.iii, numera/cad.iii, omnia/dynamic_record.iii, aether/capability.iii, omnia/lru.iii',
    'A record/crystal/witness/capability that STORES or COMPUTES a field (a tag, a count, a generation, a flag) ' +
    'with no accessor to read it, where a real consumer needs it.  Avoid byte-identical reroutes.') },
  { key: 'format-symmetry', prompt: lp('a parse/format (encode/decode) pair with an asymmetry',
    'verba/format.iii, verba/json.iii, tempora/rfc3339.iii, verba/base64.iii, verba/uri.iii, numera/hex.iii',
    'A case parse ACCEPTS that format cannot EMIT (or vice versa), or a round-trip that loses a field.  RED: ' +
    'round-trip drops/changes the value; GREEN: it survives.  Must be a real result-level delta, not cosmetic.') },
]

phase('Discover')
log('W4 fresh-axis: ' + LENSES.length + ' lenses')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification. CONFIRM or REFUTE by reading source. No build/run/edit.\n\nTitle: ' + c.title +
  '\nLive path: ' + c.live_path + '\nGap: ' + c.gap + '\nUse: ' + c.use + '\nRED/GREEN: ' + c.red_green_kat +
  '\nExact values: ' + c.exact_values + '\nNot-already: ' + c.not_already + '\nNot-pinned: ' + c.not_pinned + '\n\n' +
  'Open the fn IN FULL incl. comments. real=true ONLY if: (1) the gap is genuine (grep the concept -- not already ' +
  'done); (2) the API/fn exists; (3) NOT a documented deliberate invariant; (4) a KAT pins EXACT values ' +
  'RED-now/GREEN-after (a stub fails); (5) lands INSIDE the module / a live caller; (6) derives, never observes; ' +
  '(7) has_real_use -- a PLAUSIBLE consumer (else churn).  For NL/parse KATs CONFIRM the exact inputs.  Give ' +
  'impl_sketch + exact_values + gate_tier + impact.  If refuted name the reject class.\n\n' + REJECT

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
const confirmed = flat.filter((v) => v.real === true && v.discriminator_holds === true && v.fires_live === true && v.has_real_use === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W4 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
