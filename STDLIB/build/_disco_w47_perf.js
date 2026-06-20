export const meta = {
  name: 'iii-w47-perf-headroom',
  description: 'W47: find ALGORITHMIC perf headroom (O(n^2)->O(n log n), linear-scan-of-keyed->binary/hash, redundant-recompute->hoist/memo, full-rebuild->incremental) with PROVABLY byte-identical output and a corpus KAT to anchor. Adversarially refute (really hot? byte-identity real? naive required?).',
  phases: [
    { title: 'Find', detail: 'per-group algorithmic-headroom scan' },
    { title: 'Refute', detail: 'adversarially verify hotness + byte-identity + non-load-bearing-naivety' },
  ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'dp_string', dir: NUMERA, files: 'coin_change.iii knapsack.iii lcs.iii lis.iii levenshtein.iii kmp.iii inversion_count.iii catalan.iii binary_search.iii sieve.iii' },
  { key: 'graph_solver', dir: NUMERA, files: 'dijkstra.iii dominators.iii sat.iii sat_arith.iii sat_at_scale.iii smt.iii bmc.iii kinduction.iii congruence_closure.iii groebner.iii' },
  { key: 'egraph_rewrite', dir: NUMERA, files: 'egraph.iii egraph_stochastic.iii relational_ematch.iii mcmc_egraph.iii reduced_product.iii widening.iii interval_lattice.iii' },
  { key: 'analysis_opt', dir: NUMERA, files: 'sccp.iii gvn.iii dce.iii liveness.iii loop_optimizer.iii vectorizer.iii value_range_prover.iii reg_alloc.iii isel.iii list_schedule.iii ssa.iii dominators.iii' },
  { key: 'codes_struct', dir: NUMERA, files: 'rscode.iii rscode_ec.iii huffman.iii lzss.iii lzh.iii gf_poly.iii merkle.iii segment_tree.iii fenwick.iii matrix_ring.iii bv_bits.iii' },
  { key: 'omnia_rewrite', dir: OMNIA, files: 'xii_canonicalise.iii xii_rewrite.iii xii_joinability.iii xii_termination.iii xii_critpair_enum.iii resolver.iii resolver_memo.iii unify.iii map.iii set.iii lru.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'kind', 'current_complexity', 'proposed_complexity', 'proposed_algo', 'byte_identity_argument', 'corpus_kat', 'hot_evidence', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string', description: 'the @export (or reachable-from-@export) hot function' }, line: { type: 'number' },
      kind: { type: 'string', enum: ['quadratic_loop', 'linear_scan_keyed', 'redundant_recompute', 'full_rebuild_incremental', 'other'] },
      current_complexity: { type: 'string', description: 'e.g. O(n^2) over N up to <cap>' },
      proposed_complexity: { type: 'string' },
      proposed_algo: { type: 'string', description: 'the concrete faster algorithm + why output is the SAME (not an approximation)' },
      byte_identity_argument: { type: 'string', description: 'why the faster version produces byte-identical output to the current one (the differential-oracle premise)' },
      corpus_kat: { type: 'string', description: 'the corpus test that anchors this fn correctness (you grepped). If none, say NONE.' },
      hot_evidence: { type: 'string', description: 'why this is genuinely hot/reachable with non-trivial n (the iteration count is caller-controllable and can be large)' },
      confidence: { type: 'number' },
    },
  } } },
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_win', 'reason'],
  properties: {
    is_real_win: { type: 'boolean' }, reason: { type: 'string' },
    measurement_plan: { type: 'string', description: 'if real: how to microbenchmark old vs new (input size, the differential KAT that proves byte-identity)' },
  },
}

const FIND_PROMPT = (g) => `You are finding ALGORITHMIC performance headroom in the III stdlib -- a faster algorithm with PROVABLY byte-identical output (not an approximation, not a different result).  The crypto and compiler-core are excluded (already instruction-optimized / fragile).
Read these files in ${g.dir}: ${g.files}

Look for these kinds ONLY:
 - quadratic_loop: a nested loop O(n^2) over the same array where a sort+linear-scan O(n log n), a hash O(n),
   or a prefix-sum/two-pointer O(n) gives the SAME result.
 - linear_scan_keyed: an O(n) linear search/argmin over a structure that is SORTED or has a key, where binary
   search O(log n) or a hash index O(1) gives the SAME element.
 - redundant_recompute: a value recomputed every loop iteration (or every call) that is loop-invariant /
   memoizable -> hoist or cache, output unchanged.
 - full_rebuild_incremental: a structure rebuilt from scratch when an incremental update suffices (the egraph
   W3.7 parents-index precedent), output byte-identical.

HARD GATES -- drop unless ALL hold:
 - byte-IDENTICAL output: the faster algo must give the EXACT same result (same bytes / same value / same
   element / same order).  If it changes ANYTHING observable (a tie-break, an ordering, a rounding), DROP --
   that is a behavior change, not a perf win.  State the byte-identity argument concretely.
 - genuinely HOT: the iteration count n is caller-controllable and can be large in real use.  A loop bounded by
   a tiny fixed constant (<=64, a register count, a digest length) is NOT hot -- DROP.
 - has a corpus KAT: name the corpus test that anchors the fn's correctness (so the differential oracle can be
   gated).  If there is NO KAT, still report but mark corpus_kat=NONE (lower priority).
 - reachable from an @export.

This tree is already heavily optimized (sovereign/ripple/XII optimizers, cg_r3 folds).  Most loops are either
tiny-bounded or already optimal.  Returning ZERO findings is an honest, likely answer.  Only report headroom
you can defend with a concrete faster algorithm AND a byte-identity argument AND hotness evidence.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))

const candidates = found.filter(Boolean).flat().filter(f => f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)

if (candidates.length === 0) {
  return { confirmed: [], note: 'no algorithmic-headroom candidate survived the self-gate; the algorithm-heavy modules appear already-optimal or tiny-bounded' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed ALGORITHMIC perf win in the III stdlib.  Kill it unless it is a REAL, byte-identical, hot win.

CLAIM:
  file: ${c.file}  fn: ${c.fn}  (line ~${c.line})  kind: ${c.kind}
  current: ${c.current_complexity}  ->  proposed: ${c.proposed_complexity}
  algo: ${c.proposed_algo}
  byte-identity: ${c.byte_identity_argument}
  corpus KAT: ${c.corpus_kat}   hot evidence: ${c.hot_evidence}

Read the ACTUAL source and the named corpus KAT.  Try every kill:
 (1) BYTE-IDENTITY FALSE: does the faster algo REALLY give the exact same output?  Check tie-breaks, ordering,
     overflow/rounding, the exact element returned on ties.  If any observable differs, REFUTE (behavior change).
 (2) NOT HOT: is n actually bounded by a tiny fixed constant (a register/limb/digest count, a <=64 cap)?  Trace
     the bound back to its definition.  If n is small-fixed, the "O(n^2)" is O(1) in practice -> REFUTE.
 (3) NAIVE REQUIRED: is the naive form load-bearing (numerical stability, a deliberately-simple proven path that
     a differential oracle depends on, constant-time for side-channel resistance)?  If so, REFUTE.
 (4) ALREADY OPTIMAL / mis-read: does the code already do the fast thing, or did the claim mis-read it?
 (5) NO HEADROOM: is the proposed complexity actually NOT better for the real n (e.g. hash overhead > linear
     for small n)?

Default is_real_win=FALSE unless it SURVIVES all.  If real, give a measurement_plan: the input size to
microbenchmark old-vs-new at, and the differential KAT (old fn kept as oracle vs new) that proves byte-identity.
Cite the source lines + the KAT.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))

const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_win)
log(`Refute complete: ${confirmed.length} real win(s) of ${candidates.length}`)

return {
  confirmed: confirmed.map(c => ({
    file: c.file, fn: c.fn, line: c.line, kind: c.kind,
    current_complexity: c.current_complexity, proposed_complexity: c.proposed_complexity,
    proposed_algo: c.proposed_algo, byte_identity_argument: c.byte_identity_argument,
    corpus_kat: c.corpus_kat, measurement_plan: c.verdict.measurement_plan, reason: c.verdict.reason,
  })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_win))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
