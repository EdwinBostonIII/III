export const meta = {
  name: 'iii-at-scale-scan2-vacuous-and-unification',
  description: 'Read-only fan-out over III: find VACUOUS GATES (dead/untested reject paths -> prove-the-negative gaps) and UNIFICATION GAPS (two organs computing the same function via divergent code) for the sharpened Ripple engine',
  phases: [
    { title: 'Scan', detail: 'one Explore agent per gate-heavy subsystem cluster' },
    { title: 'Verify', detail: 'adversarially confirm each finding is REAL, default-refute' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
// gate-heavy + decision-heavy clusters (where vacuous gates + divergent organs are most likely)
const CLUSTERS = [
  { name: 'forcefield', path: 'STDLIB/iii/forcefield', hint: 'the Ripple optimizer + commit_gate + integrity + pcc + optinvoke -- the trust root itself' },
  { name: 'sanctus',    path: 'STDLIB/iii/sanctus',    hint: 'seals, mandates, quality gates, kchain, calculus, irreducibility, promote' },
  { name: 'omnia-xii',  path: 'STDLIB/iii/omnia',      hint: 'XII admission/confluence/termination/joinability + resolver guards + curated kernels' },
  { name: 'numera-kernel', path: 'STDLIB/iii/numera',  hint: 'typecheck/ccl proof kernel + congruence + sat/smt/groebner + cost_lattice + egraph' },
  { name: 'numera-crypto', path: 'STDLIB/iii/numera',  hint: 'crypto guards: bigint/field/ecdsa/ed25519/mlkem/keccak range+canonical+malleability checks' },
  { name: 'aether',     path: 'STDLIB/iii/aether',     hint: 'federation admission gates (tier/sybil/eclipse/qc) + pattern-set ancestry + hotstuff safety' },
  { name: 'katabasis',  path: 'STDLIB/iii/katabasis',  hint: 'descent admission: cycle/bricking/cap/seal/gate-verdict/vmexit/ring guards' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['cluster', 'findings'],
  properties: {
    cluster: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['kind', 'symbol', 'files', 'rationale', 'fix', 'est_value', 'risk'],
        properties: {
          kind: { type: 'string', enum: ['vacuous_gate', 'unification_gap'] },
          symbol: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },   // file:line citations
          rationale: { type: 'string' },                          // why it's genuinely vacuous / divergent
          fix: { type: 'string' },                                // the concrete remedy (make reject reachable + KAT, or unify to one authority)
          est_value: { type: 'integer', minimum: 1, maximum: 5 },
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
Find TWO classes of genuine, certifiable self-enhancement the sharpened Sovereign Ripple engine cares about:
 (A) VACUOUS GATE -- a predicate / gate / admission-check whose REJECT path is DEAD (structurally
     unreachable: the condition can never be false / the early-return is shadowed) OR UNTESTED (no KAT
     ever observes it returning its reject/0 value). A gate that cannot say NO is a rubber stamp. Cite
     the function (file:line) AND check the corpus KATs that exercise it -- is the negative arm proven?
     The FIX is to make the reject genuinely reachable + add a prove-the-negative KAT arm.
 (B) UNIFICATION GAP -- two organs/functions computing the SAME mathematical function via INDEPENDENT
     code paths that could silently diverge (exactly like BATCH 1's two value models or BATCH 2's two
     cost models, both since unified to one authority). NOT byte-identical copies (those are a separate
     scan) -- these are SEMANTICALLY-equal-but-separately-implemented. The FIX is to make one the single
     authority the other defers to.
Be SOURCE-GROUNDED: cite file:line; read the actual code + the relevant corpus KAT.
Be HONEST and CALIBRATED: III has heavy prove-the-negative coverage (phi_nv, 917/930, per-organ KATs).
Most gates ARE load-bearing. If this subsystem's gates all genuinely reject + are tested, report FEWER or
ZERO findings -- a true "all gates load-bearing, no divergence" is a valuable correct answer. NEVER invent
a finding. Rank each by est_value (1-5).`,
    { label: `scan2:${c.name}`, phase: 'Scan', schema: FIND_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const all = scans.flatMap(s => (s && s.findings) ? s.findings.map(x => ({ ...x, cluster: s.cluster })) : [])
log(`${all.length} raw findings across ${scans.length} scanned clusters`)

phase('Verify')
const top = all.filter(f => f.est_value >= 3).sort((a, b) => b.est_value - a.est_value).slice(0, 12)
if (top.length === 0) {
  log('No est_value>=3 findings -- III\'s gates are load-bearing + organs unified here (honest abstention).')
  return { confirmed: [], raw_count: all.length, scanned: scans.length, verdict: 'gates-load-bearing-no-divergence' }
}
const verified = (await parallel(top.map(f => () =>
  agent(
`Adversarially VERIFY this III self-enhancement finding. DEFAULT TO refuted (real=false) if uncertain.
Finding: ${JSON.stringify(f)}
Read the cited files + the relevant corpus KAT under ${ROOT}. Then:
 - VACUOUS GATE: is the reject path REALLY unreachable/untested? Prove it -- find the exact input that
   SHOULD trigger reject and show no code path / no KAT reaches it. If a KAT elsewhere DOES exercise the
   negative arm, the finding is REFUTED (the gate is load-bearing).
 - UNIFICATION GAP: do the two paths REALLY compute the identical function under all inputs (prove it),
   and would unifying preserve behavior + not create a cycle?
Return {real, why (cite file:line), blockers}. A false finding refuted here SAVES a wrong self-edit.`,
    { label: `verify2:${f.kind}`.slice(0, 40), phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    .then(v => ({ ...f, verdict: v })))))
  .filter(Boolean)

const confirmed = verified.filter(v => v.verdict && v.verdict.real)
return { confirmed, raw_count: all.length, scanned: scans.length, verified: verified.length }
