export const meta = {
  name: 'iii-w39-nonnumera-sweep',
  description: 'W39: comprehensive corner-input defect sweep across the ~335 NON-numera modules (verba parse/codecs, sanctus fs, aether net/wire, tempora date/time, omnia, forcefield, nous, katabasis, memoria). Lens battery: same-function asymmetry, law/roundtrip, overflow-before-use, unenforced-precondition, parse/date corners. WRONG-VALUE gate + adversarial refute.',
  phases: [
    { title: 'Find', detail: 'per-subsystem corner-defect scan' },
    { title: 'Refute', detail: 'adversarially kill each candidate' },
  ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const IIIDIR = ROOT + '\\STDLIB\\iii'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'verba_codecs_parse', files: 'verba/base32.iii verba/base64.iii verba/leb128.iii verba/uri.iii verba/html_escape.iii verba/hip.iii verba/ulid.iii verba/uuid.iii verba/semver.iii verba/json.iii verba/csv.iii verba/ini.iii verba/glob.iii verba/regex.iii verba/pattern.iii verba/parse.iii verba/normalise.iii verba/normalise_ascii.iii verba/rune.iii verba/string.iii verba/format.iii verba/timing_safe.iii verba/markup.iii verba/path.iii verba/semver.iii' },
  { key: 'verba_glyph_intent', files: 'verba/glyph_bytes.iii verba/glyph_core.iii verba/glyph_str.iii verba/glyph_u32.iii verba/glyph_u64.iii verba/glyph_u8.iii verba/glyph_i64.iii verba/glyph_f64.iii verba/glyph_vec.iii verba/glyph_map.iii verba/glyph_set.iii verba/glyph_record.iii verba/glyph_enum.iii verba/glyph_recursive.iii verba/glyph_proof.iii verba/glyph_witness.iii verba/glyph_crystal.iii verba/builder.iii verba/transform_form.iii verba/intent.iii verba/intent_form.iii verba/ast_intent.iii verba/nl_lex.iii verba/nl_parse.iii verba/pattern_form.iii' },
  { key: 'sanctus_fs_parse', files: 'sanctus/corpus_coverage.iii sanctus/onelang.iii sanctus/calculus_v1.iii sanctus/observe.iii sanctus/mhash.iii sanctus/quality.iii sanctus/quality_q7.iii sanctus/attest.iii sanctus/witness.iii sanctus/kchain.iii sanctus/closure.iii sanctus/genesis.iii sanctus/irreducibility_proof.iii sanctus/legacy_artifact.iii sanctus/mandate.iii sanctus/mandate_m22.iii sanctus/promote.iii sanctus/demote.iii sanctus/catalyst.iii sanctus/seal_resolver.iii sanctus/resolver_replay.iii sanctus/sovereign_witness.iii sanctus/anchor_xii.iii sanctus/xii_antidrift.iii sanctus/xii_atm.iii sanctus/xii_curate.iii sanctus/xii_sml.iii sanctus/xii_register_all.iii' },
  { key: 'aether_net_wire', files: 'aether/http.iii aether/http_client.iii aether/http_server.iii aether/net.iii aether/tcp.iii aether/inet.iii aether/inet6.iii aether/babel_wire.iii aether/idoc.iii aether/sealed_channel.iii aether/backend_ipc.iii aether/backend_loopback.iii aether/backend_remote.iii aether/backend_memo.iii aether/handle.iii aether/fs.iii aether/manifest.iii aether/node_identity.iii aether/snapshot_lattice.iii aether/topology_atlas.iii' },
  { key: 'aether_consensus_fed', files: 'aether/hotstuff.iii aether/hotstuff_heal.iii aether/hotstuff_predict.iii aether/hotstuff_predict_opt.iii aether/hotstuff_unified.iii aether/fed_admit.iii aether/fed_eclipse.iii aether/fed_genesis.iii aether/fed_seal.iii aether/fed_sybil.iii aether/fed_tier.iii aether/cap_forge.iii aether/cap_handshake.iii aether/capability.iii aether/reach_core.iii aether/reach_oracle.iii aether/reach_store.iii aether/shape_negotiator.iii aether/triple_check.iii aether/memo_query.iii aether/quarantine.iii aether/firmware_quarantine.iii aether/pattern_set_federation.iii' },
  { key: 'tempora_memoria_nous_kat', files: 'tempora/calendar.iii tempora/deadline.iii tempora/duration.iii tempora/duration_cert.iii tempora/instant.iii tempora/rfc3339.iii memoria/arena.iii memoria/region.iii memoria/seal_organ.iii memoria/span.iii memoria/tempaloc.iii nous/nous_search.iii nous/nous_value.iii nous/nous_costlin.iii nous/nous_lattice.iii nous/nous_features.iii nous/nous_completion.iii nous/nous_conjecture.iii nous/nous_synth.iii katabasis/bar_layout.iii katabasis/census.iii katabasis/ring_lattice.iii katabasis/svm_layout.iii katabasis/gate_verdict.iii' },
  { key: 'forcefield_ripple', files: 'forcefield/ripple.iii forcefield/ripple_apply.iii forcefield/ripple_cut.iii forcefield/ripple_dyn.iii forcefield/ripple_extract.iii forcefield/ripple_journal.iii forcefield/ripple_loop.iii forcefield/ripple_metric.iii forcefield/ripple_search.iii forcefield/ripple_synthesizer.iii forcefield/ripple_unify.iii forcefield/pleroma.iii forcefield/scythe_census.iii forcefield/daemon_scythe.iii forcefield/cg_autocatalyst.iii forcefield/cg_surgical_strike.iii forcefield/forked_walk.iii forcefield/bv_dispose.iii forcefield/optinvoke.iii forcefield/pcc_gate.iii forcefield/commit_gate.iii forcefield/integrity.iii' },
  { key: 'omnia_containers_resolver', files: 'omnia/option.iii omnia/result.iii omnia/either.iii omnia/list.iii omnia/map.iii omnia/set.iii omnia/vec.iii omnia/queue.iii omnia/zip.iii omnia/fold.iii omnia/iter.iii omnia/lru.iii omnia/pattern_table.iii omnia/sovval.iii omnia/sov_morphism.iii omnia/governance.iii omnia/caindex.iii omnia/bound.iii omnia/resolver.iii omnia/resolver_memo.iii omnia/prespec.iii omnia/unify.iii omnia/proof_resolve.iii omnia/babel.iii omnia/transform.iii' },
  { key: 'omnia_xii_tp', files: 'omnia/xii_canonicalise.iii omnia/xii_rewrite.iii omnia/xii_rule_overlap.iii omnia/xii_rule_verify.iii omnia/xii_joinability.iii omnia/xii_termination.iii omnia/xii_critpair_enum.iii omnia/xii_chd.iii omnia/xii_lattice.iii omnia/xii_cost_monotone.iii omnia/xii_savings.iii omnia/tp_x86_assemble.iii omnia/tp_x86_disasm.iii omnia/tp_iii_hex.iii omnia/tp_raw_hex.iii omnia/tp_pe_hex.iii omnia/tp_babel_json_cbor.iii omnia/tp_babel_cbor_json.iii omnia/tp_planner.iii omnia/tp_morphism.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'angle', 'defect', 'corner_input', 'expected', 'actual_buggy', 'reachable_export', 'already_tested', 'confidence'],
    properties: {
      file: { type: 'string', description: 'relative path under STDLIB/iii' },
      fn: { type: 'string' }, line: { type: 'number' },
      angle: { type: 'string', enum: ['same_function_asymmetry', 'law_or_roundtrip', 'overflow_before_use', 'unenforced_precondition', 'parse_or_date_corner'] },
      defect: { type: 'string', description: 'the concrete wrong-value mechanism; for asymmetry name BOTH branches' },
      corner_input: { type: 'string' }, expected: { type: 'string' }, actual_buggy: { type: 'string' },
      reachable_export: { type: 'boolean' }, already_tested: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason', 'refutation_attempted'],
  properties: {
    is_real_defect: { type: 'boolean' }, reason: { type: 'string' },
    refutation_attempted: { type: 'string' }, proposed_teeth: { type: 'string' },
  },
}

const FIND_PROMPT = (g) => `You are auditing the III self-hosted systems language for REAL corner-input correctness defects that produce a WRONG COMPUTED VALUE (not merely a missing defensive return code). This sweep targets the NON-numera subsystems.
Read these files under ${IIIDIR}: ${g.files}

Angles (report only these):
(0) same_function_asymmetry [HIGH PRIORITY]: the function guards/clamps a condition in ONE branch/mode/loop but
    a PARALLEL one does NOT, so a corner mishandled. Cite BOTH branches with line numbers. (This fingerprint
    found 2 real bugs: rp_count's RP_ANY vs parity modes, loop_optimizer interval vs affine.)
(A) law_or_roundtrip: a documented/required identity that BREAKS on a corner -- encode/decode, parse/emit,
    compress/decompress, idempotence, a+b==b+a -- at 0, empty, max, single element, all-same, boundary length.
(B) overflow_before_use: a multiply/shift feeding an alloc LENGTH or array INDEX, unchecked -> wrap -> too-small
    alloc / wrapped index.
(C) unenforced_precondition: a doc-stated precondition the code READS but does not ENFORCE, producing a wrong
    VALUE (not just an OOB that wants a defensive guard) when a reachable caller violates it. SKIP power-of-2.
(D) parse_or_date_corner: parsing/codec/date-time specific -- empty input, truncated/malformed input, an
    off-by-one in a parse loop bound, a month/day/leap-year/overflow edge, a base32/64 padding edge, a UTF/rune
    boundary, a length field that disagrees with the buffer -> a WRONG decoded/parsed/computed value.

HARD GATES -- drop unless ALL hold:
 - reachable_export: a real @export carries caller-controllable input to the defect.
 - WRONG VALUE, not contract-only: the function produces an incorrect COMPUTED result on the corner. If the only
   fix is a defensive 'return error' with no wrong-value differential, DROP (hardening, not a defect).
 - NOT vacuous: a wrong result for an empty/contradictory/sentinel premise that is vacuously correct -> DROP.
   (A wrong COUNT/length/parsed-value of an empty/degenerate input IS a real defect.)
 - NOT the documented contract: grep ${CORPUS} for the fn name AND read its doc-comment. If the 'wrong' behavior
   is PROMISED, DROP. already_tested=true if a corpus test asserts the exact corner.
 - concrete: name the exact corner_input and exact expected-vs-actual.

Most code is correct and KAT'd. Returning ZERO findings is a good honest answer. Only report a defect you can
defend with a specific input + specific wrong output. Return JSON per schema.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))

const candidates = found.filter(Boolean).flat()
  .filter(f => f.reachable_export && !f.already_tested && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) past self-gate (of ${found.filter(Boolean).flat().length} raw)`)

if (candidates.length === 0) {
  return { confirmed: [], note: 'no candidates survived the per-agent self-gate; the non-numera subsystems appear corner-clean on the probed inputs' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier. A prior agent claims a REAL corner-input WRONG-VALUE defect in a III non-numera module. KILL it if you can.

CLAIM:
  file: ${IIIDIR}\\${c.file}
  fn: ${c.fn}  (line ~${c.line})   angle: ${c.angle}
  defect: ${c.defect}
  corner input: ${c.corner_input}
  expected: ${c.expected}   claimed buggy actual: ${c.actual_buggy}

Read the ACTUAL source (and the fn's doc-comment); trace the relevant code by hand; grep ${CORPUS} for the fn name. Try every kill:
 (1) Is the 'buggy' output the DOCUMENTED contract / a deliberate sentinel? Quote the doc.
 (2) CONTRACT-ONLY? Is the only fix a defensive 'return error' with NO wrong-COMPUTED-value differential? If the
     corner just reads adjacent memory / returns a code but computes no incorrect result -> hardening, REFUTE.
 (3) VACUOUS -- wrong only for an empty/contradictory premise that is vacuously correct? (A wrong
     count/length/parsed-value of a degenerate input is NOT vacuous.)
 (4) UNREACHABLE -- does every @export path validate/clamp the corner before the defect?
 (5) ALREADY TESTED / mis-traced -- re-derive the actual value by hand; if the claim mis-read the code, REFUTE.
 (6) For same_function_asymmetry: verify BOTH branches in source -- does the 'guarded' one really guard, and is
     the 'unguarded' one really reachable with the same corner?

Default is_real_defect=FALSE unless it SURVIVES all. If real, give the exact value-differential teeth (the
@export call, pre-fix vs post-fix return) a falsifier KAT asserts. Cite the source lines you traced.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))

const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)

return {
  confirmed: confirmed.map(c => ({
    file: c.file, fn: c.fn, line: c.line, angle: c.angle, defect: c.defect,
    corner_input: c.corner_input, expected: c.expected, actual_buggy: c.actual_buggy,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason,
  })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
