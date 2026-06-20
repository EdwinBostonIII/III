export const meta = {
  name: 'iii-defect-discovery-w19',
  description: 'Comprehensive tree-wide @export accessor-bounds re-sweep + fresh lenses, adversarially refuted',
  phases: [
    { title: 'Discover', detail: 'directory-partitioned accessor sweep + fresh lenses, read-only' },
    { title: 'Verify', detail: 'adversarially refute each candidate against the real source' },
  ],
}

const DONOTREPORT = [
  'DO NOT REPORT these KNOWN non-defects:',
  '- (ptr,len) convention: a fn reading/writing exactly len bytes of a CALLER buffer (murmur3, crc32,',
  '  timing_safe_eq, str_ascii_eq_ci, babel set_payload, builder_push_bytes, cad_payload). ONLY report',
  '  when the destination/source is a FIXED INTERNAL module-level array [T;K] indexed past K.',
  '- Already-guarded: an explicit idx>=CAP / idx>=*_MAX / idx>=*_POOL / idx>=*_SLOTS / idx>=*_N check',
  '  before the access, OR the index routes through a guarded helper (e.g. *_slot_of that returns a',
  '  sentinel for a bad id). A bare (x & 0xFFFFFFFF) / (x & *_U32MASK) mask is a TRUNCATION, NOT a bound.',
  '- ALREADY FIXED (waves 9-18, do not re-report): k0_referee, dijkstra, fe25519, fp256/fn256/zk_field/',
  '  knapsack/segment_tree, dce/dominators/gvn/kmp/list_schedule/reg_alloc/rewrite_schedule/sccp/',
  '  congruence_closure/taint_analysis/threshold_vault/sieve (the wave-11 set), egraph eg_test_flip_bit,',
  '  heaplet, liveness, matrix_ring.',
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
          array_and_size: { type: 'string', description: 'the fixed array indexed + its declared size + the bound constant' },
          is_export: { type: 'boolean' }, teeth: { type: 'string' },
          why_real: { type: 'string' }, confidence: { type: 'number' },
        },
        required: ['file', 'fn', 'line', 'defect_class', 'description', 'array_and_size', 'is_export', 'teeth', 'why_real', 'confidence'],
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
    teeth_index: { type: 'string' }, is_write: { type: 'boolean', description: 'true if the OOB is a WRITE (clean setter teeth), false if a READ (may be benign-valued)' },
    refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'

const sweepPrompt = (dirs) =>
  'Lens: COMPREHENSIVE @export accessor-bounds sweep (wave-11 was INCOMPLETE -- it missed heaplet/' +
  'liveness/matrix_ring, just fixed in wave-18, so other modules are likely also unguarded). Scan ' +
  'EVERY .iii file under these dirs of ' + REPO + '/STDLIB/iii : ' + dirs + '. For each, list its ' +
  '@export functions; for any that takes an index/handle/slot/id/pos/block parameter and then READS ' +
  'or WRITES a FIXED module-level array (var X : [T;K]) at an offset derived from that parameter, READ ' +
  'the function and confirm whether a guard (param >= K, or >= the module *_MAX/*_POOL/*_SLOTS/*_N/*_CAP ' +
  'constant, or a *_slot_of-style sentinel route) exists BEFORE the access. Report ONLY the unguarded ' +
  'ones. Note whether the OOB is a WRITE (high value, clean setter teeth) or a READ. Prefer modules ' +
  'with handle pools / slot tables / fixed scratch arrays.\n' + DONOTREPORT

const LENSES = [
  { key: 'sweep-numera-a', prompt: sweepPrompt('numera/ (files A-M by name)') },
  { key: 'sweep-numera-b', prompt: sweepPrompt('numera/ (files N-Z by name)') },
  { key: 'sweep-omnia', prompt: sweepPrompt('omnia/') },
  { key: 'sweep-aether', prompt: sweepPrompt('aether/') },
  { key: 'sweep-nous-verba-tempora', prompt: sweepPrompt('nous/ , verba/ , tempora/') },
  { key: 'sweep-sanctus-memoria-forcefield-kat', prompt: sweepPrompt('sanctus/ , memoria/ , forcefield/ , katabasis/ , and any other dirs not listed') },
  {
    key: 'sibling-of-recent-fix',
    prompt: 'Lens: SIBLING-OF-RECENT-FIX. In ' + REPO + ', git log --oneline -20 and git show the last ~12 ' +
      'commits. For each recently-FIXED module, find the UN-fixed sibling on an adjacent path. SPECIFICALLY ' +
      'check the CONSUMERS of the wave-18 fixes: sep_logic.iii and csl.iii (use heaplet), reg_alloc.iii ' +
      '(uses liveness) -- do THEY have their own @export accessors that index a fixed array by an ' +
      'unvalidated param? Also re-examine egraph for any non-eg_find-routed index @export beyond ' +
      'eg_test_flip_bit. Report confirmed unguarded siblings.\n' + DONOTREPORT,
  },
  {
    key: 'decoder-and-sequence',
    prompt: 'Lens: untrusted-input length->fixed-buffer (huffman class) + sequence/refcount contract ' +
      '(resolver_memo class). In ' + REPO + '/STDLIB/iii, audit decoders NOT yet cleared: verba/base32, ' +
      'numera/hex, verba/csv, verba/ini, numera/proof_term, numera/identifier, verba/glyph_core, ' +
      'verba/intent_form, numera/rscode, numera/rscode_ec, aether/inet6, aether/http_client -- any reading ' +
      'a length/count from input then using it as a fixed-array loop bound/index unvalidated. AND cache ' +
      'modules: aether/backend_memo, aether/memo_query, omnia/obs_log, omnia/jit_fuse, sanctus/demote -- ' +
      'any update/refcount that desyncs an eviction rank or count. Read the function to confirm.\n' + DONOTREPORT,
  },
]

phase('Discover')
log('W19 discovery: ' + LENSES.length + ' lenses (6 accessor-sweep slices + sibling + decoder/sequence)')

const refutePrompt = (c) =>
  'Adversarially REFUTE or CONFIRM this III defect candidate by READING the source (read-only; no build/run).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClass: ' + c.defect_class + '\n' +
  'Array+size: ' + c.array_and_size + '\nClaim: ' + c.description + '\nClaimed teeth: ' + c.teeth + '\n\n' +
  'Open the file, read ' + c.fn + ' in full + the array declaration. Mark REAL only if ALL hold: ' +
  '(1) @export or reachable from one; (2) indexes a FIXED module-level array by an attacker-supplied ' +
  'value with NO param>=CAP guard on the path (a & MASK is NOT a guard); (3) a gentle exactly-1-past ' +
  'index reddens the OLD lib -- prefer a WRITE (clean setter -1-vs-0 differential); a READ may be ' +
  'benign-valued (note that); (4) NOT a DO-NOT-REPORT class. Give the array name+size, the one-line ' +
  'guard, the 1-past teeth index, and is_write. If NOT real, quote the existing guard line or name the ' +
  'DO-NOT-REPORT class.\n' + DONOTREPORT

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
log('W19 discovery complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
