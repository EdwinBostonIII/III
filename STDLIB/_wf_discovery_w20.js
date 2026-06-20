export const meta = {
  name: 'iii-defect-discovery-w20',
  description: 'Finer numera re-sweep + other-dir accessor sweep + sibling lens, adversarially refuted',
  phases: [
    { title: 'Discover', detail: 'finer-grained directory slices, read-only' },
    { title: 'Verify', detail: 'adversarially refute each candidate against the real source' },
  ],
}

const DONOTREPORT = [
  'DO NOT REPORT these KNOWN non-defects:',
  '- (ptr,len) convention: a fn reading/writing exactly len bytes of a CALLER buffer (murmur3, crc32,',
  '  timing_safe_eq, str_ascii_eq_ci, babel set_payload, builder_push_bytes, cad_payload). ONLY report',
  '  when the destination/source is a FIXED INTERNAL module-level array [T;K] indexed past K.',
  '- Already-guarded: an explicit idx>=CAP / idx>=*_MAX / *_POOL / *_SLOTS / *_N / *_NODES check before',
  '  the access, OR the index routes through a guarded helper (*_slot_of returning a sentinel). A bare',
  '  (x & 0xFFFFFFFF) / (x & *_U32MASK) mask is a TRUNCATION, NOT a bound.',
  '- ALREADY FIXED (waves 9-19, do not re-report): k0_referee, dijkstra, fe25519, fp256/fn256/zk_field/',
  '  knapsack/segment_tree, the wave-11 analysis set (dce/dominators/gvn/kmp/list_schedule/reg_alloc/',
  '  rewrite_schedule/sccp/congruence_closure/taint_analysis/threshold_vault/sieve), egraph',
  '  eg_test_flip_bit, heaplet, liveness, matrix_ring, bv_bits, omega_engine, sep_logic, csl.',
  '- Self-test / KAT helpers ARE reportable IF @export and they OOB on a hostile index.',
  '- Intentional design documented in a comment; can-not-fail lifecycle.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        properties: {
          file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
          defect_class: { type: 'string' }, description: { type: 'string' },
          array_and_size: { type: 'string' }, is_export: { type: 'boolean' },
          is_write: { type: 'boolean' }, teeth: { type: 'string' },
          why_real: { type: 'string' }, confidence: { type: 'number' },
        },
        required: ['file', 'fn', 'line', 'defect_class', 'description', 'array_and_size', 'is_export', 'is_write', 'teeth', 'why_real', 'confidence'],
      },
    },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
    real: { type: 'boolean' }, array_and_size: { type: 'string' }, fix: { type: 'string' },
    teeth_index: { type: 'string' }, is_write: { type: 'boolean' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'

const sweepPrompt = (scope) =>
  'Lens: COMPREHENSIVE @export accessor-bounds sweep (waves 11/18/19 each found MORE gaps -- assume ' +
  'more remain). Scope: ' + scope + ' under ' + REPO + '/STDLIB/iii . For EVERY .iii file in scope, ' +
  'list its @export functions; for any that takes an index/handle/slot/id/pos/node/block parameter and ' +
  'READS or WRITES a FIXED module-level array (var X : [T;K]) at an offset derived from that param, READ ' +
  'the function and confirm whether a guard (param >= K or >= the module *_MAX/*_POOL/*_SLOTS/*_N/*_NODES ' +
  'constant, or a *_slot_of sentinel route) exists BEFORE the access. Report ONLY the unguarded ones, ' +
  'noting is_write (OOB WRITE = clean setter teeth; OOB READ may be benign-valued unless the fn returns a ' +
  'distinct ERROR SENTINEL on guard). Also flag any internal fn called by an @export with an unvalidated ' +
  'index reaching a fixed array.\n' + DONOTREPORT

const LENSES = [
  { key: 'numera-a-e', prompt: sweepPrompt('numera/ files whose basename starts a,b,c,d,e') },
  { key: 'numera-f-l', prompt: sweepPrompt('numera/ files whose basename starts f,g,h,i,j,k,l') },
  { key: 'numera-m-r', prompt: sweepPrompt('numera/ files whose basename starts m,n,o,p,q,r') },
  { key: 'numera-s-z', prompt: sweepPrompt('numera/ files whose basename starts s,t,u,v,w,x,y,z') },
  { key: 'omnia', prompt: sweepPrompt('omnia/ (all files)') },
  { key: 'aether', prompt: sweepPrompt('aether/ (all files)') },
  { key: 'nous-verba-tempora-hexad', prompt: sweepPrompt('nous/ , verba/ , tempora/ , hexad/ and any other small dirs') },
  { key: 'sanctus-memoria-forcefield-katabasis', prompt: sweepPrompt('sanctus/ , memoria/ , forcefield/ , katabasis/') },
  {
    key: 'sibling-of-recent-fix',
    prompt: 'Lens: SIBLING-OF-RECENT-FIX. In ' + REPO + ', git log --oneline -20. The wave-19 fixes were ' +
      'bv_bits/omega_engine/sep_logic/csl. Check their CONSUMERS for their own unguarded @export ' +
      'accessors: forcefield/bv_dispose.iii, forcefield/cg_autocatalyst.iii (use bv_bits), and anything ' +
      'using csl/sep_logic. Also re-examine any module where wave 18/19 guarded SOME accessors -- did it ' +
      'have OTHER @export fns indexing the SAME fixed array that were missed? Report confirmed unguarded ' +
      'siblings only.\n' + DONOTREPORT,
  },
]

phase('Discover')
log('W20 discovery: ' + LENSES.length + ' lenses (4 finer numera slices + omnia/aether/others + sibling)')

const refutePrompt = (c) =>
  'Adversarially REFUTE or CONFIRM this III defect candidate by READING the source (read-only; no build/run).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClass: ' + c.defect_class + '\n' +
  'Array+size: ' + c.array_and_size + '\nClaim: ' + c.description + '\n\n' +
  'Open the file, read ' + c.fn + ' in full + the array declaration. Mark REAL only if ALL hold: ' +
  '(1) @export or reachable from one; (2) indexes a FIXED module-level array by an attacker-supplied ' +
  'value with NO param>=CAP guard on the path (a & MASK is NOT a guard); (3) a gentle exactly-1-past ' +
  'index reddens the OLD lib -- a WRITE gives a clean setter -1-vs-0 differential; a READ needs the fn ' +
  'to return a distinct ERROR SENTINEL on guard (else it is benign-pinned, note that); (4) NOT a ' +
  'DO-NOT-REPORT class. Give the array name+size, the one-line guard, the 1-past teeth index, is_write. ' +
  'If NOT real, quote the existing guard line or name the DO-NOT-REPORT class.\n' + DONOTREPORT

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(refutePrompt(c), { label: 'verify:' + c.fn, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    ))
  }
)

const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true)
log('W20 discovery complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
