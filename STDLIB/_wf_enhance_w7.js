export const meta = {
  name: 'iii-enhance-discovery-w7',
  description: 'Round 7: dropped-negative-verdict / unsound-gate sweep -- recover-the-discarded applied to FAIL signals',
  phases: [
    { title: 'Discover', detail: 'verdict-drop / alias-on-truncation / verify-edge lenses over verifier+gate+prover+crypto, read-only' },
    { title: 'Verify', detail: 'adversarial RED/GREEN false-accept delta; reject cosmetic/perf/island/deliberate-PIN/already/churn' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

const REJECT = [
  'A candidate is REAL only if a KAT pins a CONCRETE false-accept (or false-reject) delta RED-now/GREEN-after at',
  'the RESULT/exit level that DISTINGUISHES old from new: a SPECIFIC malformed/adversarial input that the live',
  'path WRONGLY ACCEPTS today (verify returns OK / violation dropped) and CORRECTLY REJECTS after (or vice versa).',
  'DEFAULT-REJECT: (a) COSMETIC/byte-identical RESULT (probe it; do not trust reasoning); (b) ALREADY-IMPLEMENTED',
  '(grep the CONCEPT; name the guard); (c) ML-IN-DISGUISE; (d) ISLAND (no live caller -- a verify nobody calls);',
  '(e) DELIBERATE-DESIGN PIN -- a documented fail-CLOSED/fail-OPEN choice or a privacy-fold (e.g. fed_eclipse',
  'fail-closed is INTENTIONAL; ai_resolve folds AMBIGUOUS->NOMATCH on purpose) -- READ the fn + comments;',
  '(f) PERF-ONLY; (g) VAPOR; (h) CHURN -- a guard whose absence cannot actually be reached, or a duplicate of an',
  'existing check.  HARD BAR: the bad state must be REACHABLE by a real caller with a real input, and the verdict',
  'must currently be SILENTLY DROPPED or computed-on-a-truncated-value (prefix/16-bit alias) so distinct inputs',
  'collide.  Prefer the recover-the-discarded shape: a violation/fail code the code COMPUTES then THROWS AWAY.',
  'ALREADY DONE (do not re-report): rfc3339 trailing-reject; json emit escape; base32 full hardening; all hip',
  'roles; calendar/duration/ini/rune/hex/leb128/path/HTTP recoveries.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: { candidates: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    properties: {
      title: { type: 'string' }, live_path: { type: 'string', description: 'the verify/gate fn that drops the verdict' },
      kind: { type: 'string', enum: ['dropped-violation', 'fail-open', 'alias-truncation', 'verify-edge', 'skipped-check'] },
      bad_input: { type: 'string', description: 'the SPECIFIC adversarial input wrongly accepted today' },
      caller: { type: 'string', description: 'the live caller that reaches the bad state' },
      gap: { type: 'string' }, red_green_kat: { type: 'string' }, exact_values: { type: 'string' },
      reachable: { type: 'string', description: 'proof the bad state is reachable by a real caller' },
      not_already: { type: 'string' }, not_pinned: { type: 'string', description: 'why this is NOT a deliberate fail-open/fail-closed/privacy-fold' },
      not_cosmetic: { type: 'string' },
      gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
      adjective: { type: 'string', enum: ['smarter', 'dynamic', 'intuitive'] },
      effort: { type: 'string', enum: ['small', 'medium', 'large'] }, confidence: { type: 'number' },
    },
    required: ['title', 'live_path', 'kind', 'bad_input', 'caller', 'gap', 'red_green_kat', 'exact_values',
               'reachable', 'not_already', 'not_pinned', 'not_cosmetic', 'gate_tier', 'adjective', 'effort', 'confidence'],
  } } },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, live_path: { type: 'string' }, real: { type: 'boolean' },
    discriminator_holds: { type: 'boolean' }, reachable_live: { type: 'boolean' }, false_accept_real: { type: 'boolean' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'already_impl', 'ml_disguise', 'island', 'deliberate_pin', 'perf_only', 'vapor', 'churn'] },
    reason: { type: 'string' }, impl_sketch: { type: 'string' }, exact_values: { type: 'string' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] }, impact: { type: 'number' },
  },
  required: ['title', 'real', 'discriminator_holds', 'reachable_live', 'false_accept_real', 'reject_class', 'reason'],
}

const lp = (focus, paths, hints) =>
  'READ-ONLY discovery over III (self-hosting .iii at ' + REPO + ').\nSource: ' + SRC + '. NO build/run/edit.\n\n' +
  'LENS: ' + focus + '\nFiles: ' + paths + '\n' + (hints ? 'Hint: ' + hints + '\n' : '') +
  '\nFind a verify/gate/check fn that COMPUTES a fail/violation signal then DROPS it (returns OK anyway), or that' +
  ' compares a TRUNCATED/prefix value so distinct inputs alias, or accepts a malformed input it should reject.' +
  ' Name the EXACT bad input + the live caller that reaches it.  READ the fn + comments FIRST -- a documented' +
  ' fail-closed/fail-open/privacy-fold is a PIN, not a bug.\n\n' + REJECT

const LENSES = [
  { key: 'sanctus-verdict-drop', prompt: lp(
    'a violation COMPUTED then dropped (returns OK) in the seal/witness/quality verifiers',
    'sanctus/witness.iii, sanctus/observe.iii, sanctus/quality.iii, sanctus/mhash.iii, sanctus/seal.iii, sanctus/replay.iii, sanctus/integrity.iii',
    'A verify that detects a mismatch/violation in a branch but still falls through to a success return, or a' +
    ' loop that breaks on the first match without checking the rest.  RED: a tampered/invalid witness verifies' +
    ' OK; GREEN: it is rejected.  Must be reachable by a real caller.') },
  { key: 'alias-truncation', prompt: lp(
    'an equality/verify that compares a TRUNCATED or prefix value, letting distinct inputs alias',
    'sanctus/mhash.iii, numera/sha256.iii, numera/hmac.iii, numera/ct.iii, omnia/cad.iii, verba/string.iii, numera/cmp.iii',
    'A digest/tag/id compare that checks only N of M bytes (or a 16-bit/8-bit compare on a wider value -- the' +
    ' documented test-ax-ax trap), so two distinct inputs pass as equal.  RED: a forged value with the same' +
    ' prefix verifies; GREEN: full-width compare rejects.  Confirm the compare width in source.') },
  { key: 'crypto-verify-edge', prompt: lp(
    'a signature/MAC/tag/key verify that accepts a malformed, truncated, or out-of-range input',
    'numera/ec256.iii, numera/ed25519.iii, numera/rsa.iii, numera/mlkem.iii, numera/aes_gcm.iii, numera/hmac.iii, numera/poly1305.iii',
    'A verify missing a bound/length/range/identity check (a point not on the curve, a zero/one tag, a wrong-' +
    'length input, a non-canonical scalar) that it ACCEPTS.  Many were hardened (grep the guard -- e.g. ec256' +
    ' on-curve already added).  RED: the malformed input verifies OK; GREEN: rejected.  Security-relevant.') },
  { key: 'gate-fail-open', prompt: lp(
    'a capability/governance/policy gate that defaults to ALLOW when its input is unset/invalid (NOT a documented fail-open)',
    'aether/capability.iii, aether/cap_forge.iii, omnia/governance.iii, omnia/call_context.iii, forcefield/pleroma.iii, aether/fed_admit.iii',
    'A gate where an uninitialized/zero/out-of-range field takes the permit branch.  CAUTION: many fail-closed/' +
    'open choices are DELIBERATE (fed_eclipse fail-closed is intentional) -- only report if the permissive branch' +
    ' is clearly an oversight (no comment, contradicts siblings).  RED: unset cap permits; GREEN: denied.') },
  { key: 'prover-skipped-check', prompt: lp(
    'a sound check SKIPPED on one path in the provers, letting an invalid proof/term through',
    'omnia/proof_term.iii, omnia/kernel_proof.iii, sanctus/pcc.iii, omnia/smt.iii, omnia/bounded_mc.iii, omnia/egraph.iii, omnia/xii.iii',
    'A proof/term checker that validates most cases but has a branch (a node kind, an operator, an arity) it' +
    ' accepts WITHOUT checking, so a malformed proof certifies.  RED: a crafted invalid proof passes; GREEN:' +
    ' rejected.  Distinguish from a deliberately-trusted axiom.  Reseal-tier if it touches cg_r3 -- flag it.') },
]

phase('Discover')
log('W7 verdict-drop sweep: ' + LENSES.length + ' lenses (verifier/gate/prover/crypto)')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification. CONFIRM or REFUTE by reading source. No build/run/edit.\n\nTitle: ' + c.title +
  '\nLive path: ' + c.live_path + '\nKind: ' + c.kind + '\nBad input: ' + c.bad_input + '\nCaller: ' + c.caller +
  '\nGap: ' + c.gap + '\nRED/GREEN: ' + c.red_green_kat + '\nExact: ' + c.exact_values +
  '\nReachable: ' + c.reachable + '\nNot-pinned: ' + c.not_pinned + '\nNot-already: ' + c.not_already + '\n\n' +
  'Open the verify/gate fn IN FULL incl. comments. real=true ONLY if: (1) it genuinely drops a verdict / compares' +
  ' truncated / accepts malformed (read it; grep the guard) -- not already checked; (2) the bad state is' +
  ' REACHABLE by a real live caller with a real input (reachable_live); (3) it is NOT a documented deliberate' +
  ' fail-open/fail-closed/privacy-fold (deliberate_pin) -- READ the comments; (4) a KAT pins the EXACT false-' +
  'accept RED-now/GREEN-after -- the bad input ACCEPTED today, REJECTED after (false_accept_real); (5) NOT' +
  ' cosmetic/perf/island/churn.  Give impl_sketch + exact_values + gate_tier + impact (security-relevant = high).' +
  '  If refuted name the reject class precisely.\n\n' + REJECT

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
const confirmed = flat.filter((v) => v.real === true && v.discriminator_holds === true && v.reachable_live === true && v.false_accept_real === true && v.reject_class === 'none')
confirmed.sort((a, b) => (b.impact || 0) - (a.impact || 0))
log('W7 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
