export const meta = {
  name: 'iii-w58-zero-default-collision',
  description: 'W58: the cad-W29 collision class, semantic -- a module-global STATE var defaults to 0 (uninit/cold), but 0 is ALSO a VALID mode/suite/kind/state enum value, so a cold/default-state @export call reads state==0 as that valid mode and takes the WRONG branch (instead of detecting uninit) -> a silently-wrong result.  Over the modules a structural grep flagged (a value-0 enum + a state var).  Adversarial refute (0 is a guarded uninit sentinel? cold state unreachable? branch harmless?).',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'proof_reflect', dir: NUMERA, files: 'proof_carrying.iii proof_term.iii reflection_constrained.iii theorem_carrier.iii certified_morphism.iii quine_verifier.iii safety_type.iii' },
  { key: 'rewrite_engine', dir: NUMERA, files: 'mem_rewrite.iii relational_ematch.iii reversible.iii symbolic_regression.iii category.iii sccp.iii sep_logic.iii' },
  { key: 'dispatch_hash', dir: NUMERA, files: 'sha256_dispatch.iii slhdsa.iii hdl.iii isel.iii tso.iii uncertainty.iii smt.iii' },
  { key: 'self_synth', dir: NUMERA, files: 'golden_shift.iii self_engine.iii math_library_curation.iii algo_synth.iii conjecture_refute.iii optimality_cert.iii cost_lattice_synth.iii' },
  { key: 'omnia_state', dir: OMNIA, files: 'async.iii sandbox_exec.iii sandbox_ctor.iii self_reformatter.iii resolver_memo.iii governance.iii spec_probe.iii dynamic_impact.iii' },
  { key: 'aether_state', dir: ROOT + '\\STDLIB\\iii\\aether', files: 'cap_handshake.iii fed_admit.iii hotstuff.iii sealed_channel.iii context_awareness.iii branch_governance.iii reach_oracle.iii', absolute: true },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'state_var', 'zero_enum', 'cold_path', 'wrong_branch_taken', 'wrong_observable', 'reachable_export', 'has_kat', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      state_var: { type: 'string', description: 'the module-global state var that defaults to 0 (BSS-zero) and is READ as a mode' },
      zero_enum: { type: 'string', description: 'the VALID enum/mode constant whose value is also 0 (so default-0 == this valid mode)' },
      cold_path: { type: 'string', description: 'the @export call on cold/default state (no init/begin first) that reads state==0' },
      wrong_branch_taken: { type: 'string', description: 'the wrong branch the cold state==0 selects (the valid-mode branch instead of an uninit guard)' },
      wrong_observable: { type: 'string', description: 'the silently-wrong result via @export' },
      reachable_export: { type: 'boolean' }, has_kat: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for the cad-W29 DEFAULT-ZERO-COLLISION class.  cad's bug: CAD_ACTIVE defaults to 0 (BSS), and 0 == CAD_SUITE_SHA256, so a cad call WITHOUT cad_begin took the SHA256 branch on an uninit backend -> a silently-wrong (empty) digest.
Read these files in ${g.dir === OMNIA ? 'STDLIB/iii/omnia' : (g.absolute ? 'the given aether paths' : NUMERA)}: ${g.files}

Find: a module-global STATE var (mode/suite/kind/active/phase) that DEFAULTS to 0 (BSS-zero, never explicitly
initialized to a non-zero sentinel), where 0 is ALSO a VALID enum value of that mode -- AND a reachable @export
reads the state on COLD/default state (no init/begin/setup called first) and takes the VALID-MODE-0 branch
(producing a wrong result) INSTEAD of detecting "uninitialized" and erroring/initializing.

The SAFE patterns (do NOT report): the state's 0-value is an explicit "INVALID/UNINIT/NONE" sentinel that the
code GUARDS (e.g. an "if state == 0 return ERR" check or an "if not INITED then init"); or the @export always initializes
before reading; or 0 is not a valid mode (the enum starts at 1).
The BUG pattern: default-0 state silently means a real mode, and a cold call computes a wrong answer on it.

HARD GATES -- drop unless ALL hold:
 - state defaults to 0 (BSS, no init-to-nonzero) AND 0 is a documented VALID mode (not an uninit sentinel).
 - a reachable @export reads the state cold (callable before init) and takes the mode-0 branch.
 - a SILENTLY-WRONG observable results (a wrong value/digest/verdict), NOT a clean error or a harmless default.
 - NOT guarded: there is no "state==0 / not-inited" check protecting the cold path.

cad was the one real instance; most modules either guard the cold state, init-first, or use 0 as an explicit
uninit sentinel they check.  ZERO findings is honest.  Only report a collision you traced (default-0 == valid
mode, cold @export takes the wrong branch, wrong observable).  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no default-zero collision survived the self-gate; modules guard the cold state / init-first / use 0 as a checked uninit sentinel' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed DEFAULT-ZERO-COLLISION (cad-W29 class) in the III stdlib.

CLAIM: ${c.file} ${c.fn} (line ~${c.line}) state=${c.state_var} zero_enum=${c.zero_enum}
  cold path: ${c.cold_path}
  wrong branch: ${c.wrong_branch_taken}
  wrong observable: ${c.wrong_observable}

Read the source + grep ${CORPUS}.  Kills:
 (1) GUARDED: is there a "state==0 / not-INITED" check (or an init-first contract) protecting the cold
     path?  If the cold state is detected, REFUTE.
 (2) 0 IS AN UNINIT SENTINEL: is 0 actually the documented INVALID/NONE value the code checks, NOT a valid mode?
     Read the enum + the comparison.  If 0 means "none" and is guarded, REFUTE.
 (3) COLD UNREACHABLE: must an @export init/begin/setup run before the reading @export (by contract / by the only
     call sequence)?  If cold-read cannot happen, REFUTE.
 (4) HARMLESS / mis-read: does the mode-0 branch actually produce a correct/benign result on cold state?  REFUTE.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the teeth (the cold @export call returning
the wrong value vs the correct/guarded value), pre-fix vs post-fix, and the fix (guard state==0 / init).  Cite
source lines + the enum definition.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, state_var: c.state_var, zero_enum: c.zero_enum,
    cold_path: c.cold_path, wrong_branch_taken: c.wrong_branch_taken, wrong_observable: c.wrong_observable,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
