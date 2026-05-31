export const meta = {
  name: 'iii-sovereign-witness-real-vs-symbolic',
  description: 'Read-only classification of the III modules the Sovereign Witness spec leans on: for each, does it ACTUALLY DO the thing (emit ring-transition code, drive real VMCB/NPT, run a real SMT/e-graph search, open real sockets) or is it a SYMBOLIC model / exit-code corpus fixture? This decides whether the Witness can be built as real composition or would be a green-but-fake stub.',
  phases: [
    { title: 'Classify', detail: 'one Explore agent per Witness module-cluster; classify REAL vs PARTIAL vs SYMBOLIC with source evidence' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const CLUSTERS = [
  { name: 'ring-hypervisor', mods: 'katabasis, svm_layout, microarch_model, ring_lattice, vmexit',
    hint: 'The "exist outside the TV" descent. Does katabasis EMIT real Ring-0/-1/-2 transition machine code / a real IOCTL or VMRUN / real MSR writes (look for metal{} blocks, @abi ioctl/magic-msr/vmrun-trampoline, ntoskrnl imports, actual VMCB/NPT pointer writes), or does it MODEL the ring lattice as a typed data structure that returns admit/deny verdicts as exit codes with no hardware effect? svm_layout: real VMCB/NPT field offsets written to hardware, or a layout/offset TABLE consumed by a model? Cite the strongest evidence either way.' },
  { name: 'state-capture-replay', mods: 'reversible, branch_anchor, cad, witness_spine, content_addr, mhash',
    hint: 'The "freeze / snapshot / rewind / content-address the legacy state" claims. reversible: does it checkpoint/rollback REAL process or machine memory (mmap, page copy, register save), or is it an in-process transaction LOG of its own data structures? branch_anchor: real reality fork (process/VM fork), or a symbolic branch record? cad/content_addr/mhash: real content-addressed hashing (these are likely REAL sha256) -- confirm. What can actually be frozen/addressed today?' },
  { name: 'analysis-proof', mods: 'smt, egraph, computation_graph, temporal_logic, proof_term',
    hint: 'The "prove exactly what the legacy program will do" / omniscience claims. smt: a REAL SMT search (DPLL/CDCL, simplex) that decides satisfiability, or a bounded/symbolic checker over fixed inputs? egraph: real equality saturation (e-class union-find + rewrite to fixpoint), or a fixture? computation_graph + temporal_logic: real bounded-model-checking over an arbitrary lifted program, or evaluation of a fixed encoded example? Be precise: "decides arbitrary instances" vs "passes encoded KAT instances". Note explicitly any claim that is undecidable for arbitrary programs (full functional equivalence / "what the program WILL do").' },
  { name: 'io-membrane', mods: 'net, inet, http, io, fs (the OS membrane + ripple-net glue)',
    hint: 'The "synthesize the exact RAM the legacy system would have if it received a packet, inject it, no packet on the wire" claim. net/inet/http: do they open REAL sockets / send REAL bytes (libc socket/send/recv via @abi), or parse/encode protocol bytes in-memory (real, useful) with no actual network? Is there any path that writes another process memory space / injects synthesized state? What is the net module relationship to ripple functions (the user mentioned the net is meant to handle some ripple functions)?' },
]

const CLASS_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['cluster', 'modules'],
  properties: {
    cluster: { type: 'string' },
    modules: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['name', 'classification', 'what_it_actually_does', 'evidence', 'witness_role', 'undecidable_or_impossible'],
        properties: {
          name: { type: 'string' },
          classification: { type: 'string', enum: ['REAL', 'PARTIAL', 'SYMBOLIC', 'ABSENT'] },
          what_it_actually_does: { type: 'string' },     // one precise sentence
          evidence: { type: 'string' },                   // file:line + the tell (metal{}/ioctl/socket vs pure-logic/exit-code)
          witness_role: { type: 'string' },               // what role it could legitimately play in an OFFLINE witness pipeline
          undecidable_or_impossible: { type: 'string' },  // any spec claim resting on it that is undecidable/physically impossible, or "none"
        },
      },
    },
  },
}

phase('Classify')
const results = (await parallel(CLUSTERS.map(c => () =>
  agent(
`Read-only SOURCE classification of III modules for the "${c.name}" cluster: ${c.mods}. Root: ${ROOT}.
For EACH module, READ THE ACTUAL .iii (and any .c) source and classify it REAL / PARTIAL / SYMBOLIC / ABSENT:
- REAL = it actually performs the physical/computational effect (emits real machine code / drives hardware
  via metal{} or an @abi ioctl/msr/vmrun extern / opens a real socket / runs a real decision procedure that
  handles arbitrary instances).
- SYMBOLIC = it MODELS the effect as typed data + logic that returns verdicts/exit codes, validated by
  exit-code corpus KATs, with NO real hardware/OS/network effect (this is the dominant III pattern -- say so
  plainly when true; it is NOT a criticism, it is the fact the architecture needs).
- PARTIAL = real in part (e.g. real Ring-0 IOCTL primitive exists but the hypervisor/SMM path is unwired).
${c.hint}
Be SOURCE-GROUNDED: cite file:line and the concrete tell (a metal{} block / an @abi(...) ioctl|magic-msr|
vmrun extern / an ntoskrnl import / a libc socket call = REAL; pure u32/u64 logic returning exit codes +
an NN_*.iii KAT = SYMBOLIC). Do NOT flatter the code; "this is a symbolic model" is the valuable honest
answer. For each module also state the legitimate role it COULD play in an OFFLINE witness (III ingests a
captured artifact produced by some external tool, as a content-addressed bounded data structure, and runs
whatever analysis actually works). And flag any spec claim resting on it that is undecidable for arbitrary
programs or physically impossible as specified.`,
    { label: `cls:${c.name}`, phase: 'Classify', schema: CLASS_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const flat = results.flatMap(r => (r && r.modules) ? r.modules.map(m => ({ ...m, cluster: r.cluster })) : [])
const real = flat.filter(m => m.classification === 'REAL').length
const partial = flat.filter(m => m.classification === 'PARTIAL').length
const symbolic = flat.filter(m => m.classification === 'SYMBOLIC').length
log(`classified ${flat.length} modules: ${real} REAL, ${partial} PARTIAL, ${symbolic} SYMBOLIC`)
return { modules: flat, summary: { real, partial, symbolic, total: flat.length } }
