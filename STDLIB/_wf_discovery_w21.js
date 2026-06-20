export const meta = {
  name: 'iii-defect-discovery-w21',
  description: 'Byte-pointer typed-array OOB + fresh axes (sequence/refcount, decoder-len, overflow) + sibling, refuted',
  phases: [
    { title: 'Discover', detail: 'byte-pointer lead + fresh axes + final accessor sweep, read-only' },
    { title: 'Verify', detail: 'adversarially refute each candidate against the real source' },
  ],
}

const DONOTREPORT = [
  'DO NOT REPORT these KNOWN non-defects:',
  '- (ptr,len) convention: a fn reading/writing exactly len bytes of a CALLER buffer. ONLY report when',
  '  the destination/source is a FIXED INTERNAL module-level array [T;K] accessed past its true extent.',
  '- Already-guarded: an explicit idx>=CAP / >=*_MAX/*_POOL/*_SLOTS/*_N/*_NODES check before the access,',
  '  OR the index routes through a guarded *_slot_of/alloc that returns a sentinel. A bare (x & MASK) is',
  '  a TRUNCATION, NOT a bound. A count bounded at PUSH time (e.g. rs_add: if i>=MAX return) makes any',
  '  later argmax/index over that count in-bounds -- TRACE the count before claiming OOB.',
  '- ALREADY FIXED (waves 9-20): k0_referee, dijkstra, fe25519, fp256/fn256/zk_field/knapsack/',
  '  segment_tree, the wave-11 analysis set, egraph eg_test_flip_bit, heaplet, liveness, matrix_ring,',
  '  bv_bits, omega_engine, sep_logic, csl, temporal_logic.  ripple_search rs_strict_best is SAFE (refuted).',
  '- Intentional design documented in a comment; can-not-fail lifecycle.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        defect_class: { type: 'string' }, description: { type: 'string' },
        array_and_size: { type: 'string' }, is_export: { type: 'boolean' },
        is_write: { type: 'boolean' }, teeth: { type: 'string' },
        why_real: { type: 'string' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'defect_class', 'description', 'array_and_size', 'is_export', 'is_write', 'teeth', 'why_real', 'confidence'],
    } },
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

const LENSES = [
  {
    key: 'byte-ptr-numera',
    prompt: 'Lens: BYTE-POINTER typed-array OOB (the temporal_logic class). In ' + REPO + '/STDLIB/iii/numera/, ' +
      'find every place that casts a fixed module-level array to a BYTE/word pointer at a computed offset -- ' +
      'patterns like `(&ARR as u64 + idx) as *u8`, `(base + i*STRIDE) as *u8/*u32/*u64`, or bb_bit-style ' +
      '`ARR[n*STRIDE + i]` -- where the offset idx derives from an @export parameter. The BUG: the bound check ' +
      '(if any) is against the ELEMENT COUNT but the access is BYTE-addressed (so the real bound is the byte ' +
      'size = elements*sizeof), OR there is no bound at all. Exemplar: temporal_logic tl_val_set/get indexed ' +
      'TL_VAL[u64;524288] by idx=s*4096+p through a *u8 cast with no idx>=4194304 (byte) guard. READ each ' +
      'candidate to confirm the @export reachability + the missing/element-vs-byte bound.\n' + DONOTREPORT,
  },
  {
    key: 'byte-ptr-rest',
    prompt: 'Lens: BYTE-POINTER typed-array OOB (the temporal_logic class) across ' + REPO + '/STDLIB/iii/ ' +
      'EXCEPT numera/ (omnia, aether, forcefield, sanctus, memoria, nous, verba, tempora, katabasis, hexad). ' +
      'Same pattern: a fixed module-level array cast to *u8/*u32/*u64 at a computed offset derived from an ' +
      '@export param, with the bound checked against element count (not byte size) or not at all. READ each ' +
      'candidate to confirm.\n' + DONOTREPORT,
  },
  {
    key: 'sequence-refcount-contract',
    prompt: 'Lens: sequence/rank/LRU/refcount CONTRACT bugs (the resolver_memo class). In ' + REPO + '/STDLIB/iii, ' +
      'examine modules with a sequence/recency/refcount/eviction counter NOT yet audited: aether/backend_memo, ' +
      'aether/memo_query, omnia/obs_log, omnia/obs_trace, omnia/jit_fuse, sanctus/demote, omnia/lru (re-check), ' +
      'any *_SEQ/_LRU/evict/victim/refcount/recency. Find an update/re-store that wrongly changes an eviction ' +
      'rank, a refcount that desyncs (double-free, decrement-below-zero, leak), or eviction-victim selection ' +
      'inconsistent with the documented policy. Read the insert/update/evict/get/drop logic + give an ' +
      'observable teeth sketch.\n' + DONOTREPORT,
  },
  {
    key: 'decoder-len-and-overflow',
    prompt: 'Lens: untrusted-length->fixed-buffer (huffman class) + integer overflow/underflow in size math ' +
      '(fix_div/bitw_bytelen class). In ' + REPO + '/STDLIB/iii, audit decoders NOT cleared: verba/base32, ' +
      'numera/hex, verba/csv, verba/ini, numera/proof_term, numera/identifier, verba/glyph_core, ' +
      'verba/intent_form, numera/rscode, numera/rscode_ec, aether/inet6, aether/http_client, numera/mldsa, ' +
      'numera/bigint -- any @export reading a length/count from input then using it as a fixed-array loop ' +
      'bound/index unvalidated, OR computing a*b / a+b / a<<n / a-b for a size/offset/index that can WRAP or ' +
      'UNDERFLOW to bypass a later bound. Read the function to confirm reachable + observable.\n' + DONOTREPORT,
  },
  {
    key: 'sibling-of-recent-fix',
    prompt: 'Lens: SIBLING-OF-RECENT-FIX. The wave-20 fix was temporal_logic (byte-pointer trace OOB). Check its ' +
      'CONSUMERS for their own unguarded @export accessors or byte-pointer addressing: constitution.iii, ' +
      'constitution_preserver.iii, hotstuff.iii. Also: any module where waves 18/19/20 guarded SOME accessors ' +
      'of a fixed array -- did it have OTHER @export fns touching the SAME array that were missed? And re-scan ' +
      'modules with a *_val_set/_val_get or *_at/_set byte-addressed pair. Report confirmed unguarded siblings.\n' + DONOTREPORT,
  },
]

phase('Discover')
log('W21 discovery: ' + LENSES.length + ' lenses (byte-ptr x2 + sequence/refcount + decoder/overflow + sibling)')

const refutePrompt = (c) =>
  'Adversarially REFUTE or CONFIRM this III defect candidate by READING the source (read-only; no build/run).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClass: ' + c.defect_class + '\n' +
  'Array+size: ' + c.array_and_size + '\nClaim: ' + c.description + '\n\n' +
  'Open the file, read ' + c.fn + ' in full + the array declaration + (for byte-pointer cases) the element ' +
  'size and the TRUE byte extent. Mark REAL only if ALL hold: (1) @export or reachable; (2) accesses a FIXED ' +
  'module-level array past its TRUE extent by an attacker-supplied value with NO adequate guard (element-count ' +
  'guard on a byte-addressed access is INADEQUATE; trace any push-time count bound before claiming OOB); ' +
  '(3) a gentle exactly-1-past index reddens the OLD lib -- a WRITE gives a clean -1/sentinel-vs-0 differential, ' +
  'a READ needs a distinct error sentinel else benign-pinned; (4) NOT a DO-NOT-REPORT class. Give the array+true ' +
  'extent, the one-line guard, the 1-past teeth index, is_write. If NOT real, quote the existing guard or the ' +
  'count-bound that makes it safe, or name the DO-NOT-REPORT class.\n' + DONOTREPORT

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
log('W21 discovery complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
