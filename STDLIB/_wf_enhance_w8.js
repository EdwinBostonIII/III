export const meta = {
  name: 'iii-enhance-discovery-w8',
  description: 'Round 8: correctness + dropped-error sweep across crypto-internals / forcefield / nous / mathlib / error-propagation -- fresh subsystems',
  phases: [
    { title: 'Discover', detail: 'correctness lenses over un-swept subsystems, read-only' },
    { title: 'Verify', detail: 'adversarial reachable RED/GREEN; reject cosmetic/perf/island/PIN/already/unreachable' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'A candidate is REAL only if a KAT pins a CONCRETE behaviour delta RED-now/GREEN-after at the RESULT/exit level',
  'AND the bad state is REACHABLE by a real live caller with a real input (the W6 region_alloc false-positive was',
  'rejected because VirtualAlloc(MEM_COMMIT) bounds REG_USED far below the wrap -- ALWAYS prove reachability, not',
  'just that a bug-shaped expression exists).  DEFAULT-REJECT: (a) COSMETIC/byte-identical RESULT (probe it; do',
  'not trust reasoning); (b) ALREADY-IMPLEMENTED (grep the CONCEPT + guard; name the symbol); (c) ML-IN-DISGUISE;',
  '(d) ISLAND (no live caller); (e) DELIBERATE-DESIGN PIN -- a documented fail-open/closed / privacy-fold / domain',
  'separation -- READ the fn + comments; (f) PERF-ONLY; (g) VAPOR; (h) CHURN/DERIVABLE; (i) UNREACHABLE (the bad',
  'input cannot arise on a live path).  Prefer: a malformed input WRONGLY ACCEPTED, an arithmetic overflow that',
  'yields a WRONG answer, an error code COMPUTED then DROPPED (sibling fn propagates, this one does not -- the',
  'http_server pattern), a verify that compares a TRUNCATED value.  ALREADY DONE (do not re-report): fix_div',
  'quotient overflow; http_server builder-error propagation; resolver IF/UNDER/THEN/WITH composites; PT_RULE_',
  'SYMMETRY swap-check; rfc3339/json/base32/utf8/hex/leb128/calendar/duration recoveries; ec256 on-curve.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { candidates: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    properties: {
      title: { type: 'string' }, live_path: { type: 'string' },
      kind: { type: 'string', enum: ['false-accept', 'overflow-wrong', 'dropped-error', 'truncation-alias', 'roundtrip-break', 'off-by-one'] },
      bad_input: { type: 'string' }, caller: { type: 'string', description: 'live caller reaching the bad state' },
      gap: { type: 'string' }, red_green_kat: { type: 'string' }, exact_values: { type: 'string' },
      reachable: { type: 'string', description: 'PROOF the bad state is reachable on a live path' },
      not_already: { type: 'string' }, not_pinned: { type: 'string' }, not_cosmetic: { type: 'string' },
      gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
      effort: { type: 'string', enum: ['small', 'medium', 'large'] }, confidence: { type: 'number' },
    },
    required: ['title', 'live_path', 'kind', 'bad_input', 'caller', 'gap', 'red_green_kat', 'exact_values',
               'reachable', 'not_already', 'not_pinned', 'not_cosmetic', 'gate_tier', 'effort', 'confidence'],
  } } },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, live_path: { type: 'string' }, real: { type: 'boolean' },
    discriminator_holds: { type: 'boolean' }, reachable_live: { type: 'boolean' }, result_delta_real: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'already_impl', 'ml_disguise', 'island', 'deliberate_pin', 'perf_only', 'vapor', 'churn', 'unreachable'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' }, exact_values: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] }, impact: { type: 'number' },
  },
  required: ['title', 'real', 'discriminator_holds', 'reachable_live', 'result_delta_real', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY discovery over III (self-hosting .iii at ' + REPO + ').\nSource: ' + SRC + '. NO build/run/edit.\n\n' +
  'LENS: ' + focus + '\nFiles: ' + paths + '\n' + (hints ? 'Hint: ' + hints + '\n' : '') +
  '\nName the gap + the EXACT bad input + the LIVE caller that reaches it + WHY the result genuinely changes.' +
  ' READ the fn + comments before claiming a gap; PROVE reachability (a bug-shaped expression a caller can never' +
  ' reach is a REJECT).\n\n' + REJECT

const LENSES = [
  { key: 'crypto-internal-correctness', prompt: lp(
    'an arithmetic / length / edge-case error in a crypto PRIMITIVE that yields a wrong digest/tag/ciphertext',
    'numera/aes_gcm.iii, numera/poly1305.iii, numera/sha512.iii, numera/hmac.iii, numera/ed25519.iii, numera/ec256.iii, numera/ chacha20.iii',
    'A specific input (a block count, an aad/ct length, a counter rollover, a final-block pad) where the primitive ' +
    'computes a WRONG result vs the spec KAT, OR a length/bound that is unchecked and corrupts output.  Most are ' +
    'FIPS-KAT-covered for the happy path -- look at the EDGES (empty msg, max len, counter wrap, partial block).') },
  { key: 'dropped-error-propagation', prompt: lp(
    'a fn that DROPS a callee error code while a SIBLING fn propagates it (the http_server pattern)',
    'numera/bigint.iii, verba/builder.iii, verba/csv.iii, aether/idoc.iii, omnia/transform.iii, memoria/arena.iii, sanctus/seal.iii',
    'Find a producer that ignores a push/alloc/encode return code and reports success, where a sibling in the SAME ' +
    'or a peer module captures-and-returns it.  RED: the failing callee path returns OK; GREEN: the propagated err.' +
    '  Must be reachable (a real OOM/sealed/full condition).') },
  { key: 'forcefield-verdict-correctness', prompt: lp(
    'a sandbox/develop-up/reversible/taint check that returns the wrong verdict on an edge input',
    'forcefield/develop_up.iii, forcefield/sandbox.iii, forcefield/reversible.iii, forcefield/snapshot_lattice.iii, forcefield/taint_analysis.iii, forcefield/pleroma.iii',
    'A bound/identity/membership check that mis-classifies an edge (an empty set, a max id, a self-edge, a boundary ' +
    'address).  CAUTION: address-space separation (mem vs disk) is DELIBERATE (the TOY-TRAP) -- not a bug.  RED: ' +
    'the edge input gets the wrong allow/deny/rollback verdict; GREEN: corrected.  Reachable, not a documented PIN.') },
  { key: 'nous-mathlib-offbyone', prompt: lp(
    'an off-by-one / boundary / saturation error in nous, cost, mathlib, or sat',
    'nous/nous_search.iii, nous/nous_features.iii, omnia/cost_lattice.iii, numera/mathlib.iii, omnia/sat.iii, omnia/cost_manifold.iii',
    'A loop bound, a capacity check, a saturation clamp, or an index that is off by one or mis-handles the boundary ' +
    '(0, max, empty), producing a wrong rank/cost/sat-result.  RED: a boundary input yields the wrong scalar; GREEN: ' +
    'corrected.  Distinguish from a deliberate clamp.  Reachable.') },
  { key: 'parser-numeric-edge', prompt: lp(
    'a numeric/format parser that mis-handles an edge (overflow, leading-zero, sign, empty) on a live path',
    'verba/format.iii, numera/dec_parse.iii, verba/json.iii, verba/semver.iii, numera/q128.iii, verba/uri.iii',
    'A number/format parse that accepts an out-of-range value (silent wrap), mishandles a sign/leading-zero/empty, or ' +
    'a formatter that produces output its parser rejects.  RED: the edge input parses/formats wrong; GREEN: corrected.' +
    '  Many were hardened -- grep the guard first.') },
]

phase('Discover')
log('W8 fresh-subsystem correctness sweep: ' + LENSES.length + ' lenses')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification. CONFIRM or REFUTE by reading source. No build/run/edit.\n\nTitle: ' + c.title +
  '\nLive path: ' + c.live_path + '\nKind: ' + c.kind + '\nBad input: ' + c.bad_input + '\nCaller: ' + c.caller +
  '\nGap: ' + c.gap + '\nRED/GREEN: ' + c.red_green_kat + '\nExact: ' + c.exact_values + '\nReachable: ' + c.reachable +
  '\nNot-already: ' + c.not_already + '\nNot-pinned: ' + c.not_pinned + '\n\n' +
  'Open the fn IN FULL incl. comments. real=true ONLY if: (1) genuine gap (grep the concept + guard); (2) the bad' +
  ' state is REACHABLE by a real live caller (reachable_live) -- the SINGLE most common failure here is a' +
  ' bug-shaped expression that no caller can actually reach (region_alloc class) -> reject UNREACHABLE; (3) NOT a' +
  ' documented deliberate invariant; (4) a KAT pins an EXACT RESULT delta RED-now/GREEN-after (result_delta_real,' +
  ' not cosmetic -- probe-grade reasoning); (5) NOT perf/island/churn/already.  Give impl_sketch + exact_values +' +
  ' gate_tier + impact.  If refuted name the reject class.\n\n' + REJECT

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(verifyPrompt(c), { label: 'verify:' + lens.key, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
        .then((v) => v ? { ...v, lens: lens.key, kind: c.kind, effort: c.effort } : null)))
  }
)
const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true && v.discriminator_holds === true && v.reachable_live === true && v.result_delta_real === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W8 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
