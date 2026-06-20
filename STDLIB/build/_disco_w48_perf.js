export const meta = {
  name: 'iii-w48-perf-headroom-2',
  description: 'W48: extend the algorithmic perf-headroom hunt to the perf-UN-probed subsystems (aether net/consensus, sanctus fs, forcefield ripple, verba parse/codec, nous). Same byte-identity + hotness + KAT gates as W47, adversarial refute.',
  phases: [
    { title: 'Find', detail: 'per-subsystem algorithmic-headroom scan' },
    { title: 'Refute', detail: 'adversarially verify byte-identity + hotness + non-load-bearing-naivety' },
  ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const IIIDIR = ROOT + '\\STDLIB\\iii'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'aether_net', files: 'aether/http.iii aether/http_server.iii aether/http_client.iii aether/tcp.iii aether/net.iii aether/babel_wire.iii aether/idoc.iii aether/sealed_channel.iii aether/topology_atlas.iii aether/snapshot_lattice.iii aether/reach_core.iii aether/reach_store.iii' },
  { key: 'aether_consensus', files: 'aether/hotstuff.iii aether/hotstuff_unified.iii aether/hotstuff_predict.iii aether/fed_admit.iii aether/fed_sybil.iii aether/fed_tier.iii aether/witness_compactor.iii aether/memo_compactor_coordination.iii aether/pattern_set_federation.iii aether/shape_negotiator.iii aether/cap_forge.iii' },
  { key: 'sanctus_fs', files: 'sanctus/corpus_coverage.iii sanctus/onelang.iii sanctus/observe.iii sanctus/mhash.iii sanctus/kchain.iii sanctus/witness.iii sanctus/quality.iii sanctus/closure.iii sanctus/seal_resolver.iii sanctus/resolver_replay.iii sanctus/xii_curate.iii' },
  { key: 'forcefield_ripple', files: 'forcefield/ripple.iii forcefield/ripple_search.iii forcefield/ripple_extract.iii forcefield/ripple_unify.iii forcefield/ripple_loop.iii forcefield/ripple_synthesizer.iii forcefield/pleroma.iii forcefield/scythe_census.iii forcefield/sovereign_optimizer.iii forcefield/cg_autocatalyst.iii forcefield/forked_walk.iii' },
  { key: 'verba_parse', files: 'verba/json.iii verba/csv.iii verba/regex.iii verba/glob.iii verba/normalise.iii verba/parse.iii verba/pattern.iii verba/base64.iii verba/base32.iii verba/string.iii verba/glyph_map.iii verba/glyph_set.iii verba/glyph_vec.iii verba/markup.iii' },
  { key: 'nous_search', files: 'nous/nous_search.iii nous/nous_lattice.iii nous/nous_value.iii nous/nous_synth.iii nous/nous_train.iii nous/nous_costlin.iii nous/nous_features.iii nous/nous_completion.iii nous/nous_conjecture.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'kind', 'current_complexity', 'proposed_complexity', 'proposed_algo', 'byte_identity_argument', 'corpus_kat', 'hot_evidence', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      kind: { type: 'string', enum: ['quadratic_loop', 'linear_scan_keyed', 'redundant_recompute', 'full_rebuild_incremental', 'other'] },
      current_complexity: { type: 'string' }, proposed_complexity: { type: 'string' },
      proposed_algo: { type: 'string' }, byte_identity_argument: { type: 'string' },
      corpus_kat: { type: 'string' }, hot_evidence: { type: 'string' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_win', 'reason'],
  properties: { is_real_win: { type: 'boolean' }, reason: { type: 'string' }, measurement_plan: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are finding ALGORITHMIC performance headroom in the III stdlib -- a faster algorithm with PROVABLY byte-identical output.  Crypto + compiler-core excluded.
Read these files under ${IIIDIR}: ${g.files}

Kinds: quadratic_loop (O(n^2) where sort/hash/two-pointer gives the SAME result), linear_scan_keyed (linear
search over a sorted/keyed struct where binary/hash gives the SAME element), redundant_recompute (loop-invariant
value recomputed each iteration -> hoist/memo), full_rebuild_incremental (rebuild-from-scratch where an
incremental update is byte-identical).

HARD GATES -- drop unless ALL hold:
 - byte-IDENTICAL output (no tie-break/order/rounding change).  State the argument.
 - genuinely HOT: n is caller-controllable and can be LARGE.  A loop bounded by a tiny fixed constant (handle
   table <=64, register/limb counts, a 256-byte alphabet, a digest length) is NOT hot -- DROP.  Trace the bound.
 - has a corpus KAT (name it; NONE if absent) and is reachable from an @export.

This tree is heavily optimized; most loops are tiny-bounded or already optimal.  ZERO findings is an honest
likely answer.  Only report headroom with a concrete faster algo + byte-identity argument + hotness evidence
(the iteration bound traced to a caller-controllable large n).  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no algorithmic-headroom candidate survived the self-gate across the un-probed subsystems; perf vein appears closed tree-wide' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed ALGORITHMIC perf win.  Kill it unless REAL, byte-identical, and hot.

CLAIM: ${c.file} ${c.fn} (line ~${c.line}) kind=${c.kind}
  ${c.current_complexity} -> ${c.proposed_complexity}; algo: ${c.proposed_algo}
  byte-identity: ${c.byte_identity_argument}; KAT: ${c.corpus_kat}; hot: ${c.hot_evidence}

Read the source + the KAT.  Kills: (1) byte-identity FALSE (tie-break/order/rounding differs) -> behavior
change, refute.  (2) NOT HOT -- trace the loop bound to a tiny fixed constant -> refute.  (3) naive form
load-bearing (stability / constant-time / a differential-oracle base) -> refute.  (4) already-optimal /
mis-read.  (5) no real headroom for the actual n.  Default is_real_win=FALSE unless it survives all.  If real,
give a measurement_plan (input size + the differential KAT proving byte-identity).  Cite source lines + KAT.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_win)
log(`Refute complete: ${confirmed.length} real win(s) of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, kind: c.kind,
    current_complexity: c.current_complexity, proposed_complexity: c.proposed_complexity,
    proposed_algo: c.proposed_algo, byte_identity_argument: c.byte_identity_argument,
    corpus_kat: c.corpus_kat, measurement_plan: c.verdict.measurement_plan, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_win))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
