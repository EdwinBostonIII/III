export const meta = {
  name: 'iii-w55-roundtrip-fidelity',
  description: 'W55: a transpiler/codec round-trip (decode(encode(x)) or encode(decode(y))) that LOSES or CORRUPTS data on a specific construct/input -- distinct from crypto round-trips (W38/40) which are covered. Over the tp_* transpiler pairs + the codec enc/dec pairs (babel/base32/64/leb128/glyph/idoc). Adversarial refute (round-trip actually holds? construct out-of-grammar? lossy-by-design?).',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const IIIDIR = ROOT + '\\STDLIB\\iii'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'tp_ast_babel', files: 'omnia/tp_iii_to_ast_bin.iii omnia/tp_ast_bin_to_iii.iii omnia/tp_iii_to_babel_json.iii omnia/tp_babel_json_to_iii.iii omnia/tp_babel_json_to_ast.iii omnia/tp_ast_to_babel_json.iii omnia/babel.iii omnia/babel_intent.iii' },
  { key: 'tp_cbor_text', files: 'omnia/tp_babel_json_cbor.iii omnia/tp_babel_cbor_json.iii omnia/tp_babel_text.iii omnia/tp_babel_text_back.iii omnia/tp_iii_hex.iii omnia/tp_raw_hex.iii omnia/tp_pe_hex.iii' },
  { key: 'tp_x86', files: 'omnia/tp_x86_assemble.iii omnia/tp_x86_disasm.iii omnia/tp_iii_to_asm.iii omnia/tp_asm_to_pe.iii' },
  { key: 'codec_int', files: 'verba/base64.iii verba/base32.iii verba/leb128.iii verba/hex.iii numera/elias.iii numera/endian.iii verba/uri.iii verba/html_escape.iii' },
  { key: 'glyph', files: 'verba/glyph_bytes.iii verba/glyph_str.iii verba/glyph_u32.iii verba/glyph_u64.iii verba/glyph_i64.iii verba/glyph_f64.iii verba/glyph_vec.iii verba/glyph_map.iii verba/glyph_set.iii verba/glyph_record.iii' },
  { key: 'wire_doc', files: 'aether/babel_wire.iii aether/idoc.iii verba/json.iii verba/csv.iii verba/ulid.iii verba/uuid.iii verba/normalise.iii verba/rune.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'encode_fn', 'decode_fn', 'line', 'construct', 'why_breaks', 'lost_or_corrupted', 'has_kat', 'reachable_export', 'confidence'],
    properties: {
      file: { type: 'string' }, encode_fn: { type: 'string' }, decode_fn: { type: 'string', description: 'the inverse fn (may be in a sibling file)' }, line: { type: 'number' },
      construct: { type: 'string', description: 'the concrete input/construct x where decode(encode(x)) != x' },
      why_breaks: { type: 'string', description: 'the mechanism: an unhandled case, a length/type tag lost, an escape not round-tripped, an overflow, a truncated field' },
      lost_or_corrupted: { type: 'string', description: 'what differs between x and decode(encode(x)) -- the observable' },
      has_kat: { type: 'boolean', description: 'is there a corpus round-trip KAT for this pair' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for ROUND-TRIP FIDELITY failures -- decode(encode(x)) != x (or encode(decode(y)) != y) on a specific construct, for a pair documented/KAT'd as a faithful round-trip.  (Crypto round-trips W38/W40 are already covered; this targets transpilers + serialization codecs.)
Read these files under ${IIIDIR}: ${g.files}

For each encode/decode (serialize/parse, to_X/from_X, put/get) PAIR:
 1. Identify the round-trip contract (the doc/KAT claims encode then decode reproduces the input).
 2. Find a CONSTRUCT/input x where the round-trip LOSES or CORRUPTS data:
    - an UNHANDLED case (a node kind / value type / escape sequence / tag the encoder emits but the decoder
      mis-reads, or vice versa).
    - a LENGTH/TYPE TAG lost or truncated (a u64 length written as u32; a type discriminant dropped).
    - a BOUNDARY value (empty, max, the largest representable, a value needing the most bytes).
    - an ESCAPE / special byte not round-tripped (quote, backslash, NUL, high bytes, multi-byte rune).
    - an OVERFLOW in the length/offset field for a large input.

HARD GATES -- drop unless ALL hold:
 - a CONCRETE input x with the exact difference between x and decode(encode(x)) (the observable).
 - the pair is CLAIMED a faithful round-trip (not a lossy/normalizing transform by design -- e.g. a canonicaliser
   that intentionally collapses forms, or a one-way lowering).  If lossy-by-design, DROP.
 - reachable from an @export; x is in the documented grammar/domain (not malformed input the decoder rejects).
 - NOT already correct: trace encode then decode by hand on x; if it reproduces x, DROP.

This tree is meticulous and most round-trips are KAT'd (often a random-stream round-trip).  The bug, if any, is
on an UNSAMPLED construct (a rare node kind, an escape, a boundary length).  ZERO findings is honest.  Only
report a round-trip failure you traced end-to-end with the concrete observable.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no round-trip fidelity failure survived the self-gate; the transpiler/codec pairs round-trip faithfully on the probed constructs' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed ROUND-TRIP FIDELITY failure in the III stdlib.

CLAIM: ${IIIDIR}\\${c.file} encode=${c.encode_fn} decode=${c.decode_fn} (line ~${c.line})
  construct: ${c.construct}
  why breaks: ${c.why_breaks}
  lost/corrupted: ${c.lost_or_corrupted}

Read BOTH the encoder and decoder source + the round-trip KAT + grep ${CORPUS}.  Trace encode(x) then
decode(...) by hand on the construct.  Kills:
 (1) ROUND-TRIP HOLDS: does decode(encode(x)) actually reproduce x?  Re-trace both directions byte by byte.  If
     it reproduces x, REFUTE (mis-trace).
 (2) LOSSY BY DESIGN: is this transform documented as normalizing/lowering/one-way (not a faithful round-trip)?
     If the pair is not contracted to be an inverse, REFUTE.
 (3) OUT-OF-GRAMMAR: is the construct outside the documented input grammar (malformed input the decoder is
     allowed to reject / the encoder never produces)?  REFUTE.
 (4) UNREACHABLE / already-tested.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the teeth (the @export encode->decode
sequence, the input x, and decode(encode(x)) != x), pre-fix vs post-fix.  Cite both source fns + the KAT.`,
    { label: `refute:${c.file}:${c.encode_fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, encode_fn: c.encode_fn, decode_fn: c.decode_fn, line: c.line,
    construct: c.construct, why_breaks: c.why_breaks, lost_or_corrupted: c.lost_or_corrupted,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, encode_fn: c.encode_fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
