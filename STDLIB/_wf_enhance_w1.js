export const meta = {
  name: 'iii-enhance-discovery-w1',
  description: 'Lean capability-compound discovery: mature faculties that fire only in a KAT, moved onto III live paths',
  phases: [
    { title: 'Discover', detail: 'capability-delta lenses over III live compile/runtime paths, read-only' },
    { title: 'Verify', detail: 'adversarial RED-on-old / GREEN-on-new discriminator; reject cosmetic/already/ML/island' },
  ],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const SRC = REPO + '/STDLIB/iii'

// The four classes a candidate MUST NOT be (advisor + harmony-audit evidence).
const REJECT = [
  'A candidate is REAL only if it produces a CONCRETE behavior delta provable by a KAT that is',
  'RED (fails / different exit) on the CURRENT code and GREEN after the change. The KAT must DISTINGUISH',
  'old from new. DEFAULT-REJECT these four classes (they dominated the last audit):',
  '  (a) COSMETIC / byte-identical reroute: a "new" path that emits the same bytes / same result as today',
  '      (the cad_oneshot(SHA256) == sha256_oneshot pattern). A KAT that passes IDENTICALLY on old+new = reject.',
  '  (b) ALREADY-IMPLEMENTED: grep the CONCEPT (not a name prefix). If the live path already consults the',
  '      faculty, or an equivalent wire-in exists, reject. Name the existing symbol if so.',
  '  (c) ML-IN-DISGUISE: any count-and-promote, observe-and-adapt, threshold-trigger, frequency/score-weighted',
  '      heuristic that LEARNS from runtime. III forbids observational/statistical learning. Proven/derived =',
  '      ok; observed-and-adapted = reject.',
  '  (d) ISLAND: a new module that NO live caller invokes. Lean = wire INTO an existing module / live path.',
  '      A thin new module is ok ONLY if an existing live path immediately calls it.',
  'Also reject: VAPOR (the faculty/API does not actually exist as described), and NOT-LIVE (fires only when a',
  'KAT explicitly calls a *_witnessed/*_certified variant; the real path never reaches it AND wiring it to the',
  'real path is out of scope / unsafe).',
].join('\n')

// The sharpest "drastically smarter" form, per the advisor: a mature faculty that currently fires ONLY inside
// a corpus KAT, moved onto III's REAL live compile/runtime path. Discriminator: "does this fire on III's own
// code, or only in a test?"
const DISCRIMINATOR =
  'PRIORITISE the highest-leverage lean compound: a faculty whose output is COMPUTED-BUT-DISCARDED or' +
  ' AVAILABLE-BUT-NOT-CONSULTED on a real live path, where wiring it in makes III behave measurably' +
  ' differently on its OWN code (not just in a test). For every candidate answer explicitly: (1) what fires' +
  ' TODAY on the live path, (2) what fires AFTER, (3) the single assertion that is RED now / GREEN after.'

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          title: { type: 'string' },
          live_path: { type: 'string', description: 'file:fn — the REAL compile/runtime chokepoint whose behavior changes' },
          faculty: { type: 'string', description: 'the already-built mature faculty wired in (module/fn names)' },
          currently: { type: 'string', description: 'what fires TODAY on the live path (e.g. only KAT NNN exercises X)' },
          delta: { type: 'string', description: 'what III does differently AFTER — concrete behavior change' },
          red_green_kat: { type: 'string', description: 'the single assertion RED on current code, GREEN after' },
          not_island: { type: 'string', description: 'the existing module this lands INSIDE, or the live caller of a thin new module' },
          not_already: { type: 'string', description: 'grep-the-concept evidence it is not already live' },
          gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
          adjective: { type: 'string', enum: ['smarter', 'dynamic', 'intuitive'] },
          effort: { type: 'string', enum: ['small', 'medium', 'large'] },
          confidence: { type: 'number' },
        },
        required: ['title', 'live_path', 'faculty', 'currently', 'delta', 'red_green_kat',
                   'not_island', 'not_already', 'gate_tier', 'adjective', 'effort', 'confidence'],
      },
    },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    title: { type: 'string' }, live_path: { type: 'string' }, faculty: { type: 'string' },
    real: { type: 'boolean' },
    discriminator_holds: { type: 'boolean', description: 'is there genuinely a RED-on-old / GREEN-on-new KAT?' },
    fires_live: { type: 'boolean', description: 'does it change III real compile/runtime behavior, not just a test?' },
    reject_class: { type: 'string', enum: ['none', 'cosmetic', 'already_impl', 'ml_disguise', 'island', 'vapor', 'not_live'] },
    reason: { type: 'string' },
    impl_sketch: { type: 'string', description: 'concrete wire-in: file, fn, the edit, the KAT arms' },
    gate_tier: { type: 'string', enum: ['libnative', 'cg_r3_reseal', 'trusted_base_reseal'] },
    impact: { type: 'number', description: '0-100 how much smarter/dynamic/intuitive III becomes' },
  },
  required: ['title', 'real', 'discriminator_holds', 'fires_live', 'reject_class', 'reason'],
}

const lensPrompt = (focus, paths, hints) =>
  'READ-ONLY capability-compound discovery over III (a self-hosting .iii language+OS at ' + REPO + ').\n' +
  'Source root: ' + SRC + '. NO build, NO run, NO edits — read source only.\n\n' +
  'LENS: ' + focus + '\n' +
  'Live paths to inspect: ' + paths + '\n' +
  (hints ? 'Where to look: ' + hints + '\n' : '') + '\n' +
  DISCRIMINATOR + '\n\n' +
  'Find lean compounds: an EXISTING mature faculty whose proven capability is not yet consulted on this live' +
  ' path. Report each as a candidate with its live_path, the faculty, what fires today vs after, and the' +
  ' RED/GREEN assertion. Lean = land INSIDE an existing module; no islands.\n\n' + REJECT

const LENSES = [
  {
    key: 'compiler-optimizer',
    prompt: lensPrompt(
      'SMARTER COMPILER — does the live codegen cg_r3 consult III\'s proven optimization faculties?',
      'COMPILER/BOOT/*cg_r3*.iii (the live backend), sema.iii; and the optimizers xii_canonicalise, sov_isa, ' +
      'cost_lattice, egraph, prespec, jit_fuse, hw_offload.',
      'cg_r3 already folds some constants (see project: sov_calc_optimizer_in_compiler). Find a PROVEN, ' +
      'byte-safe transform exercised only in a corpus KAT (e.g. a strength-reduction, identity fold, or ' +
      'specialization in prespec/jit_fuse/hw_offload) that the live emit path does NOT apply but could, ' +
      'emitting byte-identically to the hand-proven target. gate_tier=cg_r3_reseal for cg_r3 edits.'),
  },
  {
    key: 'resolve-nous',
    prompt: lensPrompt(
      'SMARTER RESOLUTION — does the live resolve() consult the nous proposer / cost faculties to disambiguate?',
      'omnia/resolver.iii resolve(), omnia/pattern_table.iii, omnia/unify.iii; nous/nous_value, nous/nous_policy, ' +
      'nous/nous_search, nous/nous_features; cost_lattice / pareto.',
      'nous is exercised in KATs 800-809. Does the LIVE resolve()/dispatch rank ambiguous candidates by a ' +
      'proven cost/value order, or by first-match? Find a place where a built ranking faculty would change ' +
      'which candidate wins, with a RED/GREEN KAT showing a different (better, deterministic) pick.'),
  },
  {
    key: 'xii-live-rules',
    prompt: lensPrompt(
      'SMARTER OPTIMIZER COVERAGE — proven algebraic identities NOT yet registered as live XII rules.',
      'omnia/xii_register_all.iii (the live rule registry), xii_rewrite.iii, xii_canonicalise.iii; and the ' +
      'independent authorities xii_rule_verify, xii_fusion_verify, xii_denote, numera/math_library, numera/trit ' +
      '(Kleene), numera/bv_bits self-laws.',
      'A rule proven sound by an independent authority (a verify module / math_library theorem) but NOT in the ' +
      'live xii_register_all set means the optimizer is leaving proven simplifications on the table for ALL III ' +
      'code. Find one; the RED/GREEN KAT = canonicalise(term) yields the simpler normal form only after. ' +
      'gate_tier=libnative (rules are data) unless it edits the trusted reducer.'),
  },
  {
    key: 'develop-up-bridges',
    prompt: lensPrompt(
      'MORE DYNAMIC — inert hooks in the develop_up hypervisor / sealed-box encapsulation layer.',
      'aether/develop_up.iii, aether/sealed_box, aether/replay_box, aether/compute_box, aether/snapshot_box, ' +
      'aether/sid_router, aether/determinism_firewall, aether/flow_firewall, aether/sentinel; the bridges ' +
      'taint_analysis, reversible, observe, behavioral_key.',
      'The hypervisor encapsulates legacy as opaque math objects via 3 semantic bridges (taint / enlightened-guest ' +
      '/ behavioral). Find a COMPUTED-BUT-UNCONSUMED signal — a taint flag, behavioral fingerprint, or determinism ' +
      'verdict the gateway computes but does not ACT on (no gate decision, no rollback trigger). Wiring it makes ' +
      'develop_up react where it currently passes through. RED/GREEN = a hostile/divergent input now refused/rolled ' +
      'back where it was previously admitted.'),
  },
  {
    key: 'hip-intent',
    prompt: lensPrompt(
      'MORE INTUITIVE — gaps between natural-language RECOGNITION and intent DISPATCH.',
      'verba/hip.iii, verba/nl_lex.iii, verba/nl_parse.iii, omnia/babel*, aether/idoc.iii, the intent calculus ' +
      'sanctus/calculus_v1, verba/intent*, verba/glyph_* serializers.',
      'Find an intent verb / sentence form / interrogative that nl_parse RECOGNISES (produces a token/AST node) ' +
      'but hip does NOT DISPATCH to a resolve()/action — recognition without effect. Or an idoc/babel consumer ' +
      'that exists but no live producer feeds. RED/GREEN = the sentence now resolves to the correct action/verb ' +
      'where it previously fell through to a default/error.'),
  },
  {
    key: 'forcefield-loop',
    prompt: lensPrompt(
      'MORE DYNAMIC + SMARTER — does the autocatalytic self-improvement loop feed the LIVE optimizer?',
      'forcefield/sovereign_optimizer, forcefield/daemon_dream, forcefield/daemon_scythe, forcefield/commit_gate, ' +
      'forcefield/cg_autocatalyst, numera/sov_isa, numera/egraph_stochastic, numera/theorem_commons.',
      'The loop PROVES new optimizations (kernel-certified). Does a certified discovery actually become a ' +
      'consulted rule on a subsequent optimize/compile (gated by commit_gate), or does it stop at a corpus KAT, ' +
      'never affecting later behavior? Find the break between "proven" and "consulted-live". NOTE: a golden/source ' +
      'shift needs an operator gate — prefer wiring a certified fact into a CONSULTED registry the optimizer ' +
      'already reads, not an autonomous golden mutation.'),
  },
  {
    key: 'observe-witness-live',
    prompt: lensPrompt(
      'MORE DYNAMIC — do III\'s REAL operations publish to the observatory / witness spine?',
      'sanctus/observe.iii, aether/witness_hook.iii, omnia/obs_observatory, omnia/obs_trace, sanctus/attest, ' +
      'aether/reach_core (witnessed variant).',
      'A *_witnessed/*_observed variant exists and is hit only by a KAT, while the REAL operation (the plain ' +
      'variant used on the live path) publishes nothing. Find a live operation that should leave a replayable ' +
      'witness/trace but does not, where the witnessed variant is already built. RED/GREEN = the observatory/spine ' +
      'now contains the operation\'s fragment after a real call. Reject if publishing is byte-identical no-op.'),
  },
  {
    key: 'theorem-reuse',
    prompt: lensPrompt(
      'SMARTER — does the live optimizer/kernel CITE proven theorems to skip re-proving?',
      'numera/theorem_commons.iii, numera/bv_commons, numera/curry_howard, numera/proof_carrying, ' +
      'omnia/certified_morphism, numera/sov_isa (extraction), numera/egraph (eg_extract).',
      'theorem_commons stores kernel-verified statements citable by content-address. On the LIVE optimize/extract ' +
      'path, does the optimizer CITE a commons theorem (O(1) hash lookup) instead of re-running tc_check, or does ' +
      'it always re-prove? Find a re-prove that a live citation would replace. RED/GREEN = the second proof of the ' +
      'same goal is served from the commons (a distinct observable: cite-count up, no re-derivation) — must be a ' +
      'real behavior delta, not cosmetic.'),
  },
]

phase('Discover')
log('W1 enhance-discovery: ' + LENSES.length + ' capability-delta lenses (smarter/dynamic/intuitive)')

const verifyPrompt = (c) =>
  'READ-ONLY adversarial verification of an III capability-compound candidate. Open the source and CONFIRM or' +
  ' REFUTE. No build/run/edit.\n\n' +
  'Title: ' + c.title + '\nLive path: ' + c.live_path + '\nFaculty: ' + c.faculty + '\n' +
  'Currently (claimed): ' + c.currently + '\nDelta (claimed): ' + c.delta + '\n' +
  'RED/GREEN KAT (claimed): ' + c.red_green_kat + '\nNot-island (claimed): ' + c.not_island + '\n' +
  'Not-already (claimed): ' + c.not_already + '\n\n' +
  'Read the live_path function AND the faculty in full. Mark real=true ONLY if ALL hold:\n' +
  '  (1) the live path genuinely does NOT already consult the faculty (open it; grep the concept) — else already_impl;\n' +
  '  (2) the faculty/API exists exactly as described — else vapor;\n' +
  '  (3) the delta is a REAL behavior change on III\'s own code, provable by a KAT RED-now/GREEN-after that\n' +
  '      DISTINGUISHES old from new — else cosmetic or not_live;\n' +
  '  (4) it lands INSIDE an existing module OR a thin new module a live path immediately calls — else island;\n' +
  '  (5) it derives/proves, never observes-and-adapts — else ml_disguise.\n' +
  'Set fires_live, discriminator_holds, reject_class, gate_tier, and an impl_sketch (the exact file:fn edit + KAT' +
  ' arms) and impact 0-100. If refuted, name the existing symbol / the reject class precisely.\n\n' + REJECT

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
log('W1 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed, examined: flat.length, all: flat }
