export const meta = {
  name: 'iii-at-scale-enhancement-scan',
  description: 'Read-only fan-out over III subsystems to surface GENUINE, certifiable self-enhancement candidates (extraction sites, vacuous gates, unification gaps) for the sharpened Ripple engine',
  whenToUse: 'BATCH 4: run the sharpened self-enhancement engine at scale over III\'s own source (read-only analysis; certification + writes stay in-session).',
  phases: [
    { title: 'Scan', detail: 'one Explore agent per subsystem cluster finds candidates, source-grounded' },
    { title: 'Verify', detail: 'adversarially confirm the top candidates are REAL, default-refute' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const CLUSTERS = [
  { name: 'numera',    path: 'STDLIB/iii/numera',     hint: 'math/crypto/proof-kernel core (bigint, fields, sha, keccak, ccl, typecheck, egraph, cost_lattice)' },
  { name: 'omnia',     path: 'STDLIB/iii/omnia',      hint: 'XII rewrite engine + resolver + decision procedures + curated kernels' },
  { name: 'sanctus',   path: 'STDLIB/iii/sanctus',    hint: 'seals, mandates, quality gates, calculus, kchain' },
  { name: 'forcefield',path: 'STDLIB/iii/forcefield', hint: 'the Ripple optimizer itself (metric/unify/cut/extract/loop/commit_gate/integrity/pcc/optinvoke)' },
  { name: 'aether',    path: 'STDLIB/iii/aether',     hint: 'federation, consensus (hotstuff), pattern-set, sybil/eclipse' },
  { name: 'verba',     path: 'STDLIB/iii/verba',      hint: 'text/parsing/format (json, csv, ini, regex, semver, glyph, nl_lex)' },
  { name: 'tempmem',   path: 'STDLIB/iii/tempora + STDLIB/iii/memoria', hint: 'time (calendar/instant/deadline/rfc3339) + memory (arena/region/lru)' },
  { name: 'katabasis', path: 'STDLIB/iii/katabasis',  hint: 'descent/CHARIOT substrate (svm/cycle/census/bar/vmexit/ring/gate)' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['cluster', 'candidates'],
  properties: {
    cluster: { type: 'string' },
    candidates: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['type', 'files', 'symbol', 'rationale', 'est_value', 'certifiable', 'risk'],
        properties: {
          type: { type: 'string', enum: ['duplication', 'vacuous_gate', 'unification', 'other'] },
          files: { type: 'array', items: { type: 'string' } },   // file:line citations
          symbol: { type: 'string' },                            // the routine/gate/organ
          rationale: { type: 'string' },                         // why it's a genuine candidate
          est_value: { type: 'integer', minimum: 1, maximum: 5 },// 5 = high-value
          certifiable: { type: 'boolean' },                      // can the engine prove it safe (cap-conservation / non-vacuity / behavior-preservation)?
          risk: { type: 'string' },
        },
      },
    },
  },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['real', 'why', 'blockers'],
  properties: { real: { type: 'boolean' }, why: { type: 'string' }, blockers: { type: 'string' } },
}

phase('Scan')
const scans = (await parallel(CLUSTERS.map(c => () =>
  agent(
`Read-only analysis of the III subsystem "${c.name}" under ${ROOT}/${c.path} (${c.hint}).
Find GENUINE self-enhancement candidates the now-sharpened Sovereign Ripple engine could certify + apply:
 (1) CROSS-MODULE DUPLICATION -- the same routine/logic appearing byte-near-identically in 2+ files: an
     EXTRACTION candidate (III's NEW multi-file atomic applier can safely pull it into ONE file + re-point
     callers). Cite exact files + the symbol + why they are behaviorally equivalent.
 (2) VACUOUS GATE -- a gate/predicate/KAT that cannot say NO (always returns the same verdict, or its
     negative arm is unreachable/untested): a prove-the-negative gap to close.
 (3) UNIFICATION GAP -- two organs computing the SAME thing via independent code paths that could diverge
     (exactly like BATCH 1's two value models, or BATCH 2's two cost models, both since unified to a single
     authority): a single-authority unification.
Be SOURCE-GROUNDED: cite file:line for every claim; read the actual code, do not guess.
Be HONEST and CALIBRATED: III has already been heavily deduped (a prior self-certification found 0 truly
mergeable duplications -> frontier-optimal abstention). If this subsystem is already lean, report FEWER or
ZERO candidates. NEVER invent a candidate to fill the list -- a true "0 candidates, already optimal" is a
valuable, correct answer. Rank each by est_value (1-5) and whether the engine can CERTIFY it safe.`,
    { label: `scan:${c.name}`, phase: 'Scan', schema: FIND_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const allCands = scans.flatMap(s => (s && s.candidates) ? s.candidates.map(x => ({ ...x, cluster: s.cluster })) : [])
log(`${allCands.length} raw candidates across ${scans.length} scanned clusters`)

phase('Verify')
const top = allCands
  .filter(c => c.est_value >= 3 && c.certifiable)
  .sort((a, b) => b.est_value - a.est_value)
  .slice(0, 12)
if (top.length === 0) {
  log('No est_value>=3 certifiable candidates -- III is frontier-optimal here (honest abstention, like the prior self-cert).')
  return { confirmed: [], raw_count: allCands.length, scanned: scans.length, verdict: 'frontier-optimal-abstention' }
}
const verified = (await parallel(top.map(c => () =>
  agent(
`Adversarially VERIFY this III self-enhancement candidate. DEFAULT TO refuted (real=false) if uncertain.
Candidate: ${JSON.stringify(c)}
Read the cited files under ${ROOT}. Then:
 - DUPLICATION: are the routines TRULY behaviorally equivalent (same semantics under all inputs, not just
   similar names/shape)? Would extracting them break any caller, change any ABI, or close a dependency cycle?
 - VACUOUS GATE: is the negative arm REALLY unreachable / untested, or is it exercised by a KAT elsewhere?
 - UNIFICATION: do the two code paths REALLY compute the identical function (prove it, do not assume)?
Return {real, why (cite file:line), blockers}. A false candidate refuted here SAVES a wrong self-edit.`,
    { label: `verify:${c.type}:${c.symbol}`.slice(0, 48), phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    .then(v => ({ ...c, verdict: v })))))
  .filter(Boolean)

const confirmed = verified.filter(v => v.verdict && v.verdict.real)
return { confirmed, raw_count: allCands.length, scanned: scans.length, verified: verified.length }
