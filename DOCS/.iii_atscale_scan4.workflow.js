export const meta = {
  name: 'iii-at-scale-scan4-noncrypto-gates-and-bounds',
  description: 'Read-only fan-out over NON-crypto subsystems: vacuous gates (dead/untested reject), cross-organ consistency gaps, and unchecked-input/bounds gaps (parsers, memory, admission gates, the proof kernel)',
  phases: [
    { title: 'Scan', detail: 'one Explore agent per non-crypto subsystem cluster' },
    { title: 'Verify', detail: 'adversarially confirm each finding is REAL + a genuine bug (not by-design), default-refute' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const CLUSTERS = [
  { name: 'verba-parsers', path: 'STDLIB/iii/verba', hint: 'json/csv/ini/regex/semver/path/base32/format/nl_lex -- malformed-input rejection, length/bounds guards, overflow on untrusted input' },
  { name: 'memoria',       path: 'STDLIB/iii/memoria', hint: 'arena/region/lru -- capacity guard, reset-safety, OOB on index, double-free/use-after-reset, alignment' },
  { name: 'kernel-cic',    path: 'STDLIB/iii/numera',  hint: 'typecheck/ccl proof kernel + congruence + sat/smt/groebner -- conversion/induction/universe guards, ctx-depth bounds, well-formedness rejects' },
  { name: 'xii-engine',    path: 'STDLIB/iii/omnia',   hint: 'xii admission/confluence/termination/joinability/critpair + resolver guards -- can each gate REJECT, is the reject tested, are sibling lowerings consistent' },
  { name: 'aether-fed',    path: 'STDLIB/iii/aether',  hint: 'federation admission (tier/sybil-pow/eclipse/qc) + hotstuff safety + pattern-set ancestry -- each admission gate must reject a bad peer/proposal; is it tested' },
  { name: 'katabasis',     path: 'STDLIB/iii/katabasis', hint: 'descent admission: cycle-term/bricking/cap/seal/gate-verdict/vmexit/ring-lattice guards -- reject path reachable + tested; sibling region classifiers consistent' },
  { name: 'sanctus-seals', path: 'STDLIB/iii/sanctus', hint: 'mandate/quality/kchain/irreducibility/promote/seal_resolver -- each quality/seal gate must be able to FAIL a bad artifact; prove-the-negative present' },
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
          kind: { type: 'string', enum: ['vacuous_gate', 'unification_gap', 'unchecked_input', 'bounds_gap'] },
          symbol: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },
          rationale: { type: 'string' },     // what bad input/state it permits; cite file:line + the relevant KAT
          fix: { type: 'string' },
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
Find GENUINE, certifiable self-enhancement candidates the sharpened Ripple engine cares about:
 (A) VACUOUS GATE -- a gate/check/predicate whose REJECT path is structurally unreachable OR untested
     (no KAT observes it returning its reject value). A gate that cannot say NO is a rubber stamp.
 (B) UNCHECKED INPUT / BOUNDS GAP -- a function that trusts an untrusted length/index/count without a
     guard, so a malformed input drives an OOB read/write, overflow, or accept of malformed data
     (parsers + memory are the usual sites). Show the exact input that breaks it.
 (C) UNIFICATION GAP / CROSS-ORGAN INCONSISTENCY -- sibling organs that SHOULD enforce the same
     invariant where one omits it (like the P-384 vs P-256 ECDSA gap just fixed in numera).
For EACH: cite file:line, read the actual code AND the corpus KAT, and explain concretely what bad
input/state it permits. Be SOURCE-GROUNDED and CALIBRATED: III is heavily KAT'd and prove-the-negative
disciplined; a difference that is BY-DESIGN (a fixed-size type/contract, an intentional fast-path, a
check enforced by the caller's type) is NOT a bug -- say so explicitly. NEVER invent; a true "all gates
load-bearing + inputs guarded" is a valuable correct answer. Rank by est_value (1-5; 5 = clear bug).`,
    { label: `s4:${c.name}`, phase: 'Scan', schema: FIND_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const all = scans.flatMap(s => (s && s.findings) ? s.findings.map(x => ({ ...x, cluster: s.cluster })) : [])
log(`${all.length} raw findings across ${scans.length} non-crypto clusters`)

phase('Verify')
const top = all.filter(f => f.est_value >= 3).sort((a, b) => b.est_value - a.est_value).slice(0, 12)
if (top.length === 0) {
  log('No est_value>=3 findings -- non-crypto gates load-bearing + inputs guarded (honest abstention).')
  return { confirmed: [], raw_count: all.length, scanned: scans.length, verdict: 'noncrypto-frontier-optimal' }
}
const verified = (await parallel(top.map(f => () =>
  agent(
`Adversarially VERIFY this III finding. DEFAULT TO refuted (real=false) if uncertain.
Finding: ${JSON.stringify(f)}
Read the cited files + the relevant corpus KAT under ${ROOT}. Confirm: (1) the gap is REAL (show the
exact code path / input that reaches the bad state without a guard, or the reject arm no KAT exercises);
(2) it is a genuine BUG, NOT by-design (a fixed-size type, a caller-enforced precondition, an intentional
policy/fast-path makes it NOT a gap -- if so, REFUTE); (3) a fix would preserve behavior on valid input +
not create a cycle. Return {real, why (cite file:line), blockers}. A false finding refuted here saves a
wrong self-edit.`,
    { label: `v4:${f.kind}`.slice(0, 40), phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    .then(v => ({ ...f, verdict: v })))))
  .filter(Boolean)

const confirmed = verified.filter(v => v.verdict && v.verdict.real)
return { confirmed, raw_count: all.length, scanned: scans.length, verified: verified.length }
