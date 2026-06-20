export const meta = {
  name: 'iii-enhance-discovery-w6',
  description: 'Round 6: broad correctness + recover-the-discarded sweep across UN-MINED subsystems',
  phases: [
    { title: 'Discover', detail: 'correctness/capability lenses over un-mined verba/numera/aether/omnia/tempora/sanctus, read-only' },
    { title: 'Verify', detail: 'adversarial RED/GREEN result-delta; reject cosmetic/perf-only/churn/derivable/PIN/already' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'A candidate is REAL only if a KAT pins a CONCRETE behavior delta RED-now/GREEN-after at the RESULT/exit',
  'level that DISTINGUISHES old from new (a new accessor may RED via link-failure PROVIDED it then pins EXACT',
  'values).  DEFAULT-REJECT: (a) COSMETIC/byte-identical RESULT (e.g. a "fix" whose output equals the old',
  'output -- probe it, do not trust reasoning); (b) ALREADY-IMPLEMENTED (grep the CONCEPT; name the symbol);',
  '(c) ML-IN-DISGUISE; (d) ISLAND (no live caller); (e) DELIBERATE-DESIGN PIN (READ the fn + comments);',
  '(f) PERF-ONLY (semantics-preserving / only speed-or-size observable -- an optimization is NOT a result',
  'delta); (g) VAPOR; (h) CHURN/DERIVABLE -- a getter a caller already gets in one existing call, or a trivial',
  'wrapper.  HARD BAR: prefer CORRECTNESS gaps (a malformed input wrongly ACCEPTED, a round-trip that LOSES a',
  'field, an overflow that yields a WRONG answer) and genuinely-missing operations -- these have real result',
  'deltas.  ALREADY DONE (do not re-report): all hip NL roles; calendar weekday/doy; duration components; INI',
  'separator; rune utf8 + hex + leb128 error-class; path_stem; HTTP req/resp version; rfc3339 trailing-reject;',
  'json emit control-char escaping.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { candidates: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    properties: {
      title: { type: 'string' }, live_path: { type: 'string' }, kind: { type: 'string', enum: ['false-accept', 'roundtrip-break', 'overflow-wrong', 'missing-op', 'compute-unexpose', 'dispatch-gap'] },
      gap: { type: 'string' }, use: { type: 'string' }, red_green_kat: { type: 'string' }, exact_values: { type: 'string' },
      not_island: { type: 'string' }, not_already: { type: 'string' }, not_pinned: { type: 'string' }, not_cosmetic: { type: 'string', description: 'why the RESULT genuinely changes (not byte-identical)' },
      gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
      adjective: { type: 'string', enum: ['smarter', 'dynamic', 'intuitive'] },
      effort: { type: 'string', enum: ['small', 'medium', 'large'] }, confidence: { type: 'number' },
    },
    required: ['title', 'live_path', 'kind', 'gap', 'use', 'red_green_kat', 'exact_values', 'not_island', 'not_already', 'not_pinned', 'not_cosmetic', 'gate_tier', 'adjective', 'effort', 'confidence'],
  } } },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, live_path: { type: 'string' }, real: { type: 'boolean' },
    discriminator_holds: { type: 'boolean' }, fires_live: { type: 'boolean' }, result_delta_real: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'already_impl', 'ml_disguise', 'island', 'deliberate_pin', 'perf_only', 'vapor', 'churn'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' }, exact_values: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] }, impact: { type: 'number' },
  },
  required: ['title', 'real', 'discriminator_holds', 'fires_live', 'result_delta_real', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY discovery over III (self-hosting .iii at ' + REPO + ').\nSource: ' + SRC + '. NO build/run/edit.\n\n' +
  'LENS: ' + focus + '\nFiles: ' + paths + '\n' + (hints ? 'Hint: ' + hints + '\n' : '') +
  '\nName the gap + a plausible consumer + WHY the RESULT genuinely changes (not byte-identical).  Prefer' +
  ' correctness gaps.  READ the fn + comments before claiming a gap.\n\n' + REJECT

const LENSES = [
  { key: 'verba-parsers-correctness', prompt: lp(
    'false-accept / round-trip-break in verba parsers+serializers NOT yet mined',
    'verba/markup.iii, verba/glob.iii, verba/pattern.iii, verba/format.iii, verba/base32.iii, verba/ulid.iii, verba/uuid.iii, verba/semver.iii, verba/normalise.iii, verba/string.iii',
    'A malformed input wrongly ACCEPTED (like rfc3339), or an emitter producing output its parser rejects (like ' +
    'json emit), or a parse/format asymmetry that loses a field.  Confirm the bad input parses OK today + the ' +
    'fix refuses it (or vice versa) -- a real exit/result delta.') },
  { key: 'numera-overflow-wrong', prompt: lp(
    'overflow / edge-case that yields a WRONG answer (not just a missing guard) in numera math',
    'numera/bigint.iii, numera/modular.iii, numera/field.iii, numera/fixed.iii, numera/q128.iii, numera/checked.iii, numera/scalar.iii, numera/barrett.iii',
    'A specific input where the op returns a MATHEMATICALLY WRONG result (silent overflow/truncation/wraparound), ' +
    'with a KAT pinning the correct value vs the wrong one.  NOT a missing-accessor; a wrong-answer bug.  Avoid ' +
    'already-guarded paths (many were hardened in prior waves -- grep the guard).') },
  { key: 'omnia-missing-op', prompt: lp(
    'genuinely-missing COMMON operation on a data structure (not derivable in one existing call)',
    'omnia/vec.iii, omnia/map.iii, omnia/set.iii, omnia/list.iii, omnia/lru.iii, omnia/queue.iii, omnia/pq.iii, omnia/option.iii, omnia/result.iii, omnia/iter.iii, omnia/fold.iii',
    'An operation a real caller needs that is ABSENT and NOT a one-call wrapper (reject vec_last/has_x churn). ' +
    'E.g. map_get_or_default, set_intersect/union, vec_insert_at/remove_at, iter_take/drop, pq_peek -- only if ' +
    'genuinely absent + not trivially derivable.  Pin exact values.') },
  { key: 'aether-protocol-gap', prompt: lp(
    'a parsed-but-unsurfaced field / capability gap on a live network path (NOT http version, done)',
    'aether/http.iii, aether/http_client.iii, aether/http_server.iii, aether/inet.iii, aether/inet6.iii, aether/tcp.iii, aether/net.iii, verba/uri.iii',
    'A header / status-reason / connection flag / address field parsed-and-dropped, or a builder that cannot emit ' +
    'something the parser accepts.  Real result delta, live caller, not cosmetic.') },
  { key: 'serializer-roundtrip', prompt: lp(
    'a glyph/codec round-trip that loses or corrupts a field',
    'verba/glyph_core.iii, verba/glyph_str.iii, verba/glyph_bytes.iii, verba/glyph_vec.iii, verba/glyph_map.iii, verba/base64.iii, verba/csv.iii, verba/leb128.iii',
    'Encode-then-decode of some value that does NOT recover the original (a lossy/buggy round-trip), pinned by ' +
    'exact input != output.  Distinct from the already-done error-class recoveries.') },
  { key: 'tempora-sanctus-memoria', prompt: lp(
    'correctness / compute-unexpose in the time / seal / memory modules not yet mined',
    'tempora/instant.iii, tempora/deadline.iii, tempora/calendar.iii, sanctus/mhash.iii, sanctus/witness.iii, sanctus/quality.iii, memoria/arena.iii, memoria/region.iii, memoria/span.iii',
    'A civil/temporal correctness gap (a boundary wrongly handled), or a computed-but-unexposed value with a real ' +
    'use (NOT weekday/doy, done).  Real result delta.') },
]

phase('Discover')
log('W6 broad sweep: ' + LENSES.length + ' lenses (un-mined subsystems, correctness-weighted)')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification. CONFIRM or REFUTE by reading source. No build/run/edit.\n\nTitle: ' + c.title +
  '\nLive path: ' + c.live_path + '\nKind: ' + c.kind + '\nGap: ' + c.gap + '\nUse: ' + c.use +
  '\nRED/GREEN: ' + c.red_green_kat + '\nExact: ' + c.exact_values + '\nNot-cosmetic: ' + c.not_cosmetic +
  '\nNot-already: ' + c.not_already + '\nNot-pinned: ' + c.not_pinned + '\n\n' +
  'Open the fn IN FULL incl. comments. real=true ONLY if: (1) genuine gap (grep the concept); (2) API exists;' +
  ' (3) NOT a documented deliberate invariant; (4) a KAT pins EXACT values RED-now/GREEN-after at the RESULT' +
  ' level -- CRUCIAL: the result must genuinely CHANGE (if old output == new output it is COSMETIC, reject);' +
  ' (5) LIVE path / caller; (6) derives, never observes; (7) result_delta_real -- NOT perf-only/cosmetic/churn/' +
  'derivable.  Give impl_sketch + exact_values + gate_tier + impact.  If refuted name the reject class.\n\n' + REJECT

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(verifyPrompt(c), { label: 'verify:' + lens.key, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
        .then((v) => v ? { ...v, lens: lens.key, kind: c.kind, effort: c.effort, adjective: c.adjective } : null)))
  }
)
const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true && v.discriminator_holds === true && v.fires_live === true && v.result_delta_real === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W6 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
