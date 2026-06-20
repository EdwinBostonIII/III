export const meta = {
  name: 'iii-defect-discovery-w18',
  description: 'Read-only fan-out to find memory-safety/correctness defects in III stdlib, adversarially refuted',
  phases: [
    { title: 'Discover', detail: '5 lenses scan the tree read-only for defect candidates' },
    { title: 'Verify', detail: 'adversarially refute each candidate against the real source' },
  ],
}

const DONOTREPORT = [
  'DO NOT REPORT these KNOWN non-defects (refuted in prior waves):',
  '- (ptr,len) convention: a fn reading/writing exactly len bytes of a CALLER buffer (murmur3, crc32,',
  '  timing_safe_eq, str_ascii_eq_ci, babel set_payload, builder_push_bytes). The length IS the contract;',
  '  a raw pointer size cannot be validated. ONLY report when the destination is a FIXED INTERNAL array',
  '  (module-level [T;K]) indexed past K.',
  '- Already-guarded: routes the index through a guarded helper (eg_find now does a>=MAX -> SENT), or has',
  '  an explicit idx>=CAP check before the access.',
  '- A mask (& 0xFFFFFFFF or & X_U32MASK) is a 32-bit TRUNCATION, NOT a bound. But it IS guarded if a',
  '  separate idx>=CAP check exists.',
  '- Self-test / KAT helpers are STILL reportable IF @export and they do an unguarded OOB on a hostile',
  '  index (eg_test_flip_bit was exactly this).',
  '- Intentional design documented in a comment; can-not-fail lifecycle.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    candidates: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          file: { type: 'string' },
          fn: { type: 'string' },
          line: { type: 'number' },
          defect_class: { type: 'string' },
          description: { type: 'string' },
          is_export: { type: 'boolean' },
          teeth: { type: 'string' },
          why_real: { type: 'string' },
          confidence: { type: 'number' },
        },
        required: ['file', 'fn', 'line', 'defect_class', 'description', 'is_export', 'teeth', 'why_real', 'confidence'],
      },
    },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    file: { type: 'string' },
    fn: { type: 'string' },
    line: { type: 'number' },
    real: { type: 'boolean' },
    bound_const: { type: 'string' },
    fix: { type: 'string' },
    teeth_index: { type: 'string' },
    refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'

const LENSES = [
  {
    key: 'u32mask-index-writer',
    prompt: 'Lens: the "mask mistaken for a bound" OOB class. In ' + REPO + '/STDLIB/iii, ~16 modules define a constant *_U32MASK : u64 = 0xFFFFFFFF (topology_atlas, nous_charter, nous_commons, nous_lattice, nous_policy, category, charter_terminal, groebner, modular_mont, reversible, smt, sov_morphism, xii_discharge, xii_rule_patterns, xii_termination, egraph). Find every @export function that takes an untrusted index/slot/pos/node parameter, applies & X_U32MASK (a 32-bit TRUNCATION, not a bound), then READS or WRITES a fixed module-level array [T;K] at that masked index WITHOUT a separate idx>=K (or >=*_MAX_*) check. Exemplar already fixed: egraph eg_test_flip_bit did EGRAPH_N_SYM[node_idx & EGRAPH_U32MASK] ^= 1 with no bound -> OOB. For each module, grep its @export fns, read each that takes an index, confirm whether a bound check exists; report ONLY the unguarded ones.\n' + DONOTREPORT,
  },
  {
    key: 'untrusted-len-decoder',
    prompt: 'Lens: untrusted-input length/count -> fixed-buffer index or loop bound (the huffman class). In ' + REPO + '/STDLIB/iii, already-cleared this session: huffman[FIXED], lzh, lzss, json, base64, inet, http_server, calendar, rfc3339 (do NOT re-audit). Audit these REMAINING decoders/parsers: verba/base32.iii, numera/hex.iii, verba/csv.iii, verba/ini.iii, numera/proof_term.iii, numera/identifier.iii, verba/glyph_core.iii, verba/intent_form.iii, numera/rscode.iii, numera/rscode_ec.iii, aether/inet6.iii, aether/http_client.iii, numera/mldsa.iii, numera/bigint.iii. Find any @export that reads a length/count/size from input bytes then uses it as a loop bound writing a FIXED internal array, or indexes a fixed table by an input-derived value, WITHOUT validating it against the array capacity. Read the actual function to confirm.\n' + DONOTREPORT,
  },
  {
    key: 'sequence-rank-contract',
    prompt: 'Lens: sequence/rank/LRU/refcount CONTRACT bugs (the resolver_memo class). In ' + REPO + '/STDLIB/iii, examine cache/pool/memo modules with a sequence/recency/refcount counter: aether/backend_memo.iii, aether/memo_query.iii, omnia/obs_log.iii, omnia/obs_trace.iii, omnia/jit_fuse.iii, sanctus/demote.iii, numera/identifier.iii, and any module with _SEQ / _LRU / evict / victim / refcount / recency. Exemplar already fixed: resolver_memo memo_insert bumped the sequence on an UPDATE, violating its own "update in place, same seq" + FIFO contract. Find any cache where (a) an update/re-store of an existing key wrongly changes its eviction rank, (b) a refcount can desync (double-decrement, decrement-below-zero, leak), or (c) eviction-victim selection is inconsistent with the documented policy. Read the insert/update/evict/get logic; report the function + the exact contract violated + an observable teeth sketch.\n' + DONOTREPORT,
  },
  {
    key: 'sibling-of-recent-fix',
    prompt: 'Lens: the SIBLING-OF-RECENT-FIX method (highest yield in a hardened tree). Run, in ' + REPO + ', git log --oneline -25 and git show --stat on the last ~12 commits to find modules recently FIXED for a memory-safety/correctness defect (messages with fix( / OOB / guard / falsifier). For each, read the fix (git show <sha> -- <file>) to learn which PATH was guarded, then read the SAME module for the UN-fixed SIBLING: the other bit-width (256 vs 384), the other index type (class-id vs node-idx), the other call site, the transitive consumer, the symmetric setter/getter. Exemplars: wave-16 found huffman from the lzh thread; wave-17 found eg_test_flip_bit as the node-index sibling of the eg_find class-id fix. Report each sibling you CONFIRM by reading the source is still unguarded.\n' + DONOTREPORT,
  },
  {
    key: 'size-arith-overflow',
    prompt: 'Lens: integer overflow/underflow in size/offset/length arithmetic feeding an allocation, loop bound, or array index (the fix_div / bitw_bytelen class). In ' + REPO + '/STDLIB/iii, find @export-reachable functions computing a*b, a+b, a<<n, or a-b where the result becomes an allocation size, loop bound, or array index, AND an attacker-influenced input can WRAP (u32/u64 overflow) or UNDERFLOW (a-b with b>a) to a wrong value that bypasses a later bound check or under-allocates. Focus: serialization size math, buffer-length math in builders/arenas, offset arithmetic in decoders, count*stride in matrix/tensor/poly/ntt modules, capacity math. Read the function to confirm the wrap/underflow is REACHABLE and OBSERVABLE.\n' + DONOTREPORT,
  },
]

phase('Discover')
log('W18 read-only discovery: ' + LENSES.length + ' lenses fanning out across the III stdlib')

const refutePrompt = (c) => {
  return 'Adversarially REFUTE or CONFIRM this III defect candidate by READING the actual source (read-only; do NOT build or run anything).\n\n' +
    'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClaimed defect (' + c.defect_class + '): ' + c.description + '\n' +
    'Claimed teeth: ' + c.teeth + '\n\n' +
    'Open the file, read ' + c.fn + ' in full plus the declarations of any array it indexes. Mark REAL only if ALL hold: ' +
    '(1) the entry point is @export or reachable from one; (2) it indexes/loops a FIXED internal array by an attacker-supplied ' +
    'value with NO idx>=CAP guard anywhere on the path (a & MASK is NOT a guard); (3) a GENTLE exactly-1-past probe (index == ' +
    'array length) reddens the OLD lib via a return-value difference, never a wild OOB; (4) it is NOT any DO-NOT-REPORT class. ' +
    'Give the array name + declared size, the one-line guard to add, and the exact 1-past teeth index with old-vs-new return ' +
    'values. If NOT real, say precisely which guard already exists (quote the line) or which DO-NOT-REPORT class it is.\n' + DONOTREPORT
}

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
log('W18 discovery complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
