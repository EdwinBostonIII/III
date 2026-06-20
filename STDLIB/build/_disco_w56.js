export const meta = {
  name: 'iii-w56-ds-invariants',
  description: 'W56: a DATA-STRUCTURE INVARIANT (heap property, union-find consistency, hash-table collision resolution, ring-buffer wrap, DLL surgery, BST/segment-tree shape) VIOLATED by a specific reachable operation SEQUENCE -- observable via an @export read returning a wrong answer. Distinct from accessor-bounds (indices) -- this is structural invariant corruption. Adversarial refute.',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'heap_priority', dir: NUMERA, files: 'heaplet.iii segment_tree.iii fenwick.iii inversion_count.iii' },
  { key: 'unionfind', dir: NUMERA, files: 'congruence_closure.iii congruence.iii egraph.iii relational_ematch.iii' },
  { key: 'hashtable', dir: OMNIA, files: 'map.iii set.iii lru.iii resolver_memo.iii xii_chd.iii caindex.iii' },
  { key: 'queue_ring', dir: OMNIA, files: 'queue.iii list.iii vec.iii fold.iii zip.iii iter.iii pattern_table.iii' },
  { key: 'numera_struct', dir: NUMERA, files: 'sat.iii smt.iii bv_bits.iii matrix_ring.iii sep_logic.iii csl.iii witness_spine.iii' },
  { key: 'aether_struct', dir: ROOT + '\\STDLIB\\iii\\aether', files: 'reach_store.iii snapshot_lattice.iii topology_atlas.iii handle.iii witness_compactor.iii cap_forge.iii', absolute: true },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'invariant', 'op_sequence', 'wrong_observable', 'correct_observable', 'mechanism', 'reachable_export', 'has_kat', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      invariant: { type: 'string', description: 'the structural invariant violated (heap property, parent-pointer consistency, no-duplicate-keys, FIFO order, DLL prev/next coherence, segment-tree node = sum of children)' },
      op_sequence: { type: 'string', description: 'the concrete reachable @export call sequence that breaks it' },
      wrong_observable: { type: 'string', description: 'the wrong answer a subsequent @export read returns' },
      correct_observable: { type: 'string' },
      mechanism: { type: 'string', description: 'why the invariant breaks: a missing sift/rebalance, a stale parent pointer, a collision overwrite, a wrap miscompute, a DLL splice bug' },
      reachable_export: { type: 'boolean' }, has_kat: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for DATA-STRUCTURE INVARIANT VIOLATIONS -- a structural invariant broken by a reachable operation SEQUENCE, observable as a wrong @export read.  (Distinct from accessor-bounds OOB, already swept -- this is about the structure becoming INTERNALLY INCONSISTENT and returning a wrong answer.)
Read these files ${g.absolute ? 'at the given paths' : 'in ' + (g.dir === OMNIA ? 'STDLIB/iii/omnia' : NUMERA)}: ${g.files}

For each data structure, identify its INVARIANT and find a reachable @export operation SEQUENCE that breaks it:
 - HEAP: a push/pop sequence that leaves the heap property violated -> pop returns a non-min/max.
 - UNION-FIND: a union/find sequence that leaves stale parent pointers -> find returns the wrong root / two
   merged sets report different roots / equality query wrong.
 - HASH TABLE / MAP / SET: a collision at capacity, an insert-after-delete, a resize -> get returns a stale/wrong
   value, a key reports absent when present (or vice versa), a duplicate key.
 - QUEUE / RING BUFFER: a wrap-around (fill past capacity then drain) -> pop returns out of FIFO order or a stale
   slot.
 - DLL (lru): an evict/promote/remove sequence -> prev/next become incoherent -> a traversal misses or repeats a
   node / the LRU victim is wrong.
 - SEGMENT TREE / FENWICK: an update sequence -> a range query returns a wrong aggregate (node != combine of
   children).

HARD GATES -- drop unless ALL hold:
 - a CONCRETE reachable @export op-sequence + the wrong @export read it produces (give wrong-vs-correct).
 - the structure is CLAIMED to maintain the invariant (it is the point of the structure).
 - reachable: every op in the sequence is an @export with caller-controllable args, within the documented
   capacity/domain (NOT overflowing a fixed table -- that is a different, swept class; the bug is the structure
   going inconsistent on a VALID sequence).
 - NOT already correct: hand-simulate the op-sequence step by step; if the structure stays consistent and the
   read is right, DROP.

This tree is meticulous; structures usually maintain their invariants + KAT them (often a randomized op-sequence
vs a naive reference).  The bug, if any, is on an UNSAMPLED sequence (a specific collision, a wrap at exactly
capacity, a union order).  ZERO findings is honest.  Only report an invariant break you hand-simulated with the
wrong read.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no data-structure invariant violation survived the self-gate; the structures maintain their invariants on the probed sequences' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed DATA-STRUCTURE INVARIANT VIOLATION in the III stdlib.

CLAIM: ${c.file} ${c.fn} (line ~${c.line}) invariant=${c.invariant}
  op sequence: ${c.op_sequence}
  -> wrong read: ${c.wrong_observable} vs correct ${c.correct_observable}
  mechanism: ${c.mechanism}

Read the source + the KAT + grep ${CORPUS}.  HAND-SIMULATE the op-sequence step by step on the actual code.
Kills:
 (1) INVARIANT MAINTAINED: does the code actually maintain the invariant through the sequence (a sift/rebalance/
     parent-update/collision-chain you missed)?  If the read is correct, REFUTE (mis-simulation).
 (2) OUT-OF-CAPACITY / out-of-contract: does the sequence overflow a fixed table or violate a documented
     precondition?  That is a different (swept) class -> REFUTE for this lens.
 (3) UNREACHABLE: can the op-sequence actually be produced by @export calls?  If an op is internal-only or the
     state is unconstructible, REFUTE.
 (4) ALREADY-TESTED / mis-read.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the teeth (the @export op-sequence + the
wrong read), pre-fix vs post-fix.  Cite source + the step-by-step simulation.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, invariant: c.invariant,
    op_sequence: c.op_sequence, wrong_observable: c.wrong_observable, correct_observable: c.correct_observable,
    mechanism: c.mechanism, proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
