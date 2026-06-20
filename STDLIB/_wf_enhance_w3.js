export const meta = {
  name: 'iii-enhance-discovery-w3',
  description: 'Round 3: recover-the-discarded sweep (parse-but-discard / compute-but-unexpose) across parsers+civil+NL',
  phases: [
    { title: 'Discover', detail: 'recover-the-discarded lenses across parsers/decoders/civil/format/NL, read-only' },
    { title: 'Verify', detail: 'adversarial RED/GREEN; reject cosmetic/already/ML/island/deliberate-PIN/perf-only' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'A candidate is REAL only if it yields a CONCRETE behavior delta provable by a KAT RED (different exit/result)',
  'on CURRENT code, GREEN after, the KAT DISTINGUISHING old from new. For a NEW accessor the RED may be a',
  'link-failure (symbol absent) PROVIDED the KAT then pins EXACT correct values (a stub returning 0 must fail).',
  'DEFAULT-REJECT: (a) COSMETIC/byte-identical; (b) ALREADY-IMPLEMENTED (grep the CONCEPT; name the symbol);',
  '(c) ML-IN-DISGUISE (observe-and-adapt/threshold/frequency learning -- forbidden); (d) ISLAND (no live caller);',
  '(e) DELIBERATE-DESIGN PIN (in-code "caller-supplied"/"zero-behaviour-change"/determinism invariant -- READ the',
  'fn + comments first); (f) PERF-ONLY (only speed/trace observable, not a result delta); (g) VAPOR (API absent).',
  'STRONGLY PREFER the proven pattern: a value the code already PARSES or COMPUTES but then DISCARDS / never',
  'exposes -- recovering it is real, derives nothing new, and pins exact values.  AVOID "make faculty X consult',
  'faculty Y" (those keep failing: address-space confusion, determinism pins, caller contracts).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { candidates: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    properties: {
      title: { type: 'string' }, live_path: { type: 'string' }, faculty: { type: 'string' },
      discarded_value: { type: 'string', description: 'the exact value parsed/computed then dropped, + where' },
      delta: { type: 'string' }, red_green_kat: { type: 'string' },
      exact_values: { type: 'string', description: 'concrete input->expected pairs the KAT pins' },
      not_island: { type: 'string' }, not_already: { type: 'string' }, not_pinned: { type: 'string' },
      gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
      adjective: { type: 'string', enum: ['smarter', 'dynamic', 'intuitive'] },
      effort: { type: 'string', enum: ['small', 'medium', 'large'] }, confidence: { type: 'number' },
    },
    required: ['title', 'live_path', 'faculty', 'discarded_value', 'delta', 'red_green_kat', 'exact_values',
               'not_island', 'not_already', 'not_pinned', 'gate_tier', 'adjective', 'effort', 'confidence'],
  } } },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, live_path: { type: 'string' }, real: { type: 'boolean' },
    discriminator_holds: { type: 'boolean' }, fires_live: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'already_impl', 'ml_disguise', 'island', 'deliberate_pin', 'perf_only', 'vapor', 'not_live'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' }, exact_values: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] }, impact: { type: 'number' },
  },
  required: ['title', 'real', 'discriminator_holds', 'fires_live', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY recover-the-discarded discovery over III (self-hosting .iii at ' + REPO + ').\nSource: ' + SRC +
  '. NO build/run/edit.\n\nLENS: ' + focus + '\nFiles: ' + paths + '\n' + (hints ? 'Hint: ' + hints + '\n' : '') +
  '\nHunt for a value the code PARSES or COMPUTES then DISCARDS or never exposes.  For each: name the exact' +
  ' discarded value + line, the new accessor/field, and CONCRETE input->expected pairs the KAT pins.  Before' +
  ' claiming a gap, READ the fn + comments (a "caller-supplied"/"can be added later" that is actually wired' +
  ' elsewhere is not a gap).\n\n' + REJECT

const LENSES = [
  { key: 'uri-url-parsers', prompt: lp('text parsers that drop a parsed component',
    'verba/uri.iii, verba/semver.iii, verba/path.iii, verba/glob.iii',
    'uri: does it expose scheme/userinfo/host/port/path/query/fragment, or parse-and-drop some? semver: build/' +
    'prerelease/major/minor/patch all exposed? path: drive/extension/stem? Find a component parsed but not exposed.') },
  { key: 'data-codecs', prompt: lp('binary/text codecs that compute-but-drop a field',
    'verba/json.iii, verba/csv.iii, verba/ini.iii, verba/base64.iii, verba/base32.iii, verba/leb128.iii, verba/ulid.iii, verba/uuid.iii',
    'json: number subtype (int vs frac vs exp)? csv: field/row counts, quoting flag? leb128: byte-count consumed? ' +
    'ulid: timestamp vs randomness split? uuid: version/variant nibble?  Find a computed-but-unexposed datum.') },
  { key: 'civil-time-format', prompt: lp('civil/time/format values computed internally but unexposed',
    'tempora/rfc3339.iii, tempora/duration.iii, tempora/instant.iii, tempora/deadline.iii, verba/format.iii',
    'rfc3339: offset sign/hours/minutes, fractional seconds? duration: component breakdown (days/hours/min/sec)? ' +
    'NOTE calendar weekday/doy ALREADY DONE (do not re-report). Find a civil field derivable+unexposed.') },
  { key: 'crypto-hash-meta', prompt: lp('crypto/encoding that drops a useful derived value',
    'numera/hex.iii, numera/crc32.iii, numera/adler32.iii, numera/siphash.iii, verba/normalise.iii, verba/rune.iii',
    'rune: codepoint width/category? normalise: whether any change occurred (NFC/NFD no-op flag)? hex: odd-length ' +
    'detection? Find a value the routine computes en-route but never returns.  Avoid byte-identical reroutes.') },
  { key: 'nl-intent-surface', prompt: lp('NL surface forms recognized but not dispatched (complete the calculus bridge)',
    'verba/hip.iii, verba/nl_parse.iii, verba/intent.iii, omnia/babel.iii',
    'hip already wires VERB/PATIENT/SOURCE/DESTINATION/INSTRUMENT/LOCATION/CONDITION/REASON/MODAL.  Find a STILL-' +
    'dropped surface: CONJ (and/then -> intent_then/intent_with/intent_compose), BENEFICIARY (for X), OF (X of Y), ' +
    'or a verb whose mapping ignores an available role.  KAT sentence words MUST be nl_lex-registered (hash-exact).') },
  { key: 'protocol-net', prompt: lp('network/protocol fields parsed but not surfaced',
    'aether/http.iii, aether/http_client.iii, aether/http_server.iii, aether/inet.iii, aether/inet6.iii, aether/tcp.iii',
    'NOTE http req/resp VERSION already DONE (do not re-report).  Find another: a header parsed but not indexed, a ' +
    'reason-phrase, a Connection/keep-alive flag, an inet flags/scope field parsed-and-dropped.') },
]

phase('Discover')
log('W3 recover-the-discarded: ' + LENSES.length + ' lenses')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification. CONFIRM or REFUTE by reading source. No build/run/edit.\n\nTitle: ' + c.title +
  '\nLive path: ' + c.live_path + '\nFaculty: ' + c.faculty + '\nDiscarded value: ' + c.discarded_value +
  '\nDelta: ' + c.delta + '\nRED/GREEN: ' + c.red_green_kat + '\nExact values: ' + c.exact_values +
  '\nNot-already: ' + c.not_already + '\nNot-pinned: ' + c.not_pinned + '\n\n' +
  'Open the live_path fn IN FULL incl. comments. real=true ONLY if: (1) the value is genuinely parsed/computed' +
  ' then dropped/unexposed (not already exposed -- grep the concept); (2) the API/fn/constant exists; (3) NOT a' +
  ' documented deliberate invariant; (4) a KAT pins EXACT correct values RED-now/GREEN-after (a 0-stub must fail);' +
  ' (5) lands INSIDE the module / a live caller; (6) derives, never observes.  For NL candidates CONFIRM the KAT' +
  ' sentence words are nl_lex-registered (hash-exact, no stemming).  Give impl_sketch + exact_values + gate_tier' +
  ' + impact 0-100.  If refuted name the reject class precisely.\n\n' + REJECT

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
const confirmed = flat.filter((v) => v.real === true && v.discriminator_holds === true && v.fires_live === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W3 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
