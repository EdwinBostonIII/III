# Phase XII-ι — Real `xii_horizon_construct` from III-XII §26.8

Status: **COMPLETE & VERIFIED** (Phase 4 gate passed). Originally
DESIGN/AUDIT (Phase 2 of CRASH-PROTOCOL — written before any `.iii` edit).

## Completion record (Phase XII-iota)

All 126 productive patterns (H001..H126) implemented spec-exact per S26.8
with byte-exact S26.18 SHA-256-resolved named subforms (`xii_subforms_compute`),
free `$variable` operands, recursive nested H-refs, literal/symbolic loop
counts, guard/reserved (H127..H144) -> `XHR_NULL_REF`. Rigorous line-by-line
manual audit of every id 0..125 vs the S26.8 catalog completed; all fidelity
defects found and fixed (25 abbreviated resolver names corrected to byte-exact;
9 resolvers added; ~20 structural builder corrections incl. id29 free-K09,
id54 spurious-COMPOSE removal, id116/117 DOM_RESOLVE_OK/FAIL). S26.8 shorthand
names (e.g. `SCOPED`, `PROV`) resolve to the S26.18-canonical `*_FORM` value
(S26.18 is the authoritative name->value table).

Verification (evidence, not assertion):
- `iiis-0` STDLIB compile of `xii_horizon.iii`: rc=0.
- `iiis-0` gate `301bdaf0...d4` unchanged; `iiis-1` `5d36fc29...`,
  `iiis-2` `3ffaa427...` each deterministic (2x identical), resealed
  (bare-hash format).
- **Triple bit-identity preserved**: iiis-1 57/57 + iiis-2 57/57 corpus
  equivalence (construct is off the byte-emission path, as predicted in S7).
- XII corpus 92/93 (only pre-existing non-XII `299_bit_identity_probe`);
  344/357/364/371 green. Zero regression.

The structural-placeholder body (`id*2` synthetic subforms) is eliminated. Replaces the structural-placeholder body of
`STDLIB/iii/omnia/xii_horizon.iii::xii_horizon_construct` with the
spec-exact 144-pattern algebra terms per `DOCS/III-XII.md` §26.8 + §26.18,
resolving named subforms through `numera/xii_subforms.iii`.

Standard enforced: *no placeholders, no workarounds, even if harder.* The
current body builds `xii_term_make_basis(0, id*2)` synthetic shapes — a
genuine placeholder. The fix is the real spec term per pattern.

---

## 1. Evidence summary (Phase 1 complete)

- **Spec catalog**: §26.8.1–§26.8.11, `H001..H144`. 126 productive
  (H001..H126), 12 guard (H127..H138), 6 reserved (H139..H144). Each
  productive entry carries a closed `math_expr` (nested XII algebra term).
- **Subform encoding** (§26.18): every symbolic name resolves to
  `low_Nbits(SHA-256("PREFIX:" ‖ name))`, N per kernel field width.
  Implemented by `numera/xii_subforms.iii::xii_subforms_compute(prefix_id,
  name_ptr, name_len, bits) -> u32` (NIH SHA-256 via `sha256_oneshot`).
  Direct enums for MEAN/GRANT/REFLECT (`XSF_MEAN_*`, `XSF_GRANT_*`,
  `XSF_SCOPE_*`); `xii_subforms_lift_encode(from,to,cap_ref)` for K17.
  Spec doc's `xii_kernel_subforms.iii` filename is stale → actual file
  `numera/xii_subforms.iii`.
- **Term ctors** (`xii_term.iii`, externed in `xii_horizon.iii`):
  `xii_term_make_basis(kind:u8, sub:u32)`,
  `xii_term_make_fusion2(kind:u8, a:u32, b:u32)`,
  `xii_term_make_if(p,t,e)`, `xii_term_make_loop(body:u32, count:u64)`.
- **Kind codes** (from `xii_rewrite.iii`): K01_FORM=0 … K18_REFLECT=17;
  FCOMPOSE=18, FTHEN=19, FWITH=20, FUNDER=21, FIF=22, FLOOP=23.
- **Consumer / risk**: `xii_horizon_construct` is invoked by **nothing**
  (only def + doc-comments + 2 unused externs in `cg_r3_xii.c` /
  `xii_horizon.h`). The real iiis-2 `@lattice` emit path
  (`r3_pe_lattice_emit`) emits sized NOPs and never calls it. Therefore
  the constructed term is **NOT on the triple-bit-identity byte path** —
  LOW reseal risk. Still: rebuild + reseal + triple-identity + corpus must
  be verified empirically (CRASH-PROTOCOL — never assert).
- Full pipeline realisation (term → canonicalise → MPHF → real Lattice
  cell bytes) is **blocked** by the sealed-sanctum Lattice ceremony
  (DOCS Closure / Curation-Remaining item 5) — an external process
  boundary, not a code task. In scope: the honest spec-faithful
  constructor (the documented term-construction seam). Out of scope:
  fabricating sealed ceremony Lattice bytes.

## 2. Construction contract (per pattern)

`xii_horizon_construct(id)` returns the canonical **template** term for
`H(id+1)` (id 0-based → H001 at id 0). Template = the §26.8 `math_expr`
with:

- **Named subforms** (`COL`, `SHA256_RND`, `WITNESS_FORM`, `LE_FORM`, …):
  RESOLVED to their sealed value via `xii_subforms_compute` (or the direct
  `XSF_*` enum / `lift_encode`). This is exactly what the placeholder
  fails to do and what makes the term spec-faithful.
- **`$variable` operands** (`$m`, `$h`, `$prv`, `$n`, …): FREE — these are
  the per-call holes the (future, ceremony-sealed) emit_gen fills. Encoded
  as the subform-field-zero of the bearing kernel (operand slots 0). This
  matches the original design comment ("exact [operand] values are filled
  by the per-target emit_gen module"); only the NAMED subforms are sealed
  at construction.
- **Nested `H` references** (`H006 = F.LOOP(H005, $n)`; `H082 = H045`):
  built by recursive `xii_horizon_construct(ref_id)`. The catalog is a DAG
  (refs always point to already-defined ids); a depth bound (≤16) guards
  against spec error.
- **Loop counts**: literal (`10`,`14`,`24`,`255`,`256`) → that `u64`;
  symbolic (`$n`,`$iter`,`$rounds`) → `0u64` sentinel ("variable count",
  filled per-call). `H031 = F.LOOP(F.LOOP(H030,$N),$N)` → nested loops,
  both count 0.
- **Guard cells H127..H138 and reserved H139..H144**: return
  `XHR_NULL_REF` (kept — the existing `XHT_GUARD` path already does this;
  guard/reserved have no productive term by §26.8.10/11).

### Kernel operand encodings (from `xii_rewrite.iii` / §26.1)
- `K04_MEAN(lhs,rhs)` subform = `(equiv_kind<<18)|(rhs<<9)|lhs`; template
  uses `equiv_kind` per the named form if given (e.g. `EQ_FORM` →
  MEAN with `XSF_MEAN_*`/computed), lhs/rhs operand slots = 0 (free).
- `K17_LIFT(from,to,$cap)` = `xii_subforms_lift_encode(from,to,0)` (cap
  free). Literal rings in spec (`K17_LIFT(0u3,7u3,$cap)`) → from=0,to=7.
- `K05_ACT($x,NAME)` = basis(K05, ACT-resolved(NAME)); operand `$x` free.
- `K07_SEAL($x,NAME)`/`K08_PROVE`/`K09_QUERY` = basis(kind,
  resolved(NAME)); operands free.
- `K02_BIND`,`K03_CONVEY`,`K10_GRANT`,`K11_GOVERN`,`K18_REFLECT`,
  `K06_COMPOSE_NULL`: per §26.8 — `K06_COMPOSE_NULL` = the null ground
  form `basis(K06_COMPOSE, NULL_GROUND_FORM=0xFFFFFFFF)`; `K18_REFLECT`
  with `scope=` → `basis(K18, XSF_SCOPE_*)`; `K10_GRANT` atten name →
  `XSF_GRANT_*`.

## 3. Implementation strategy

Replace the shallow `_templ_set` shape table + generic constructor with a
**per-pattern explicit builder**: a `_h_construct_NNN()` helper (or a
single large `when`/`if` cascade keyed on id) that emits the exact spec
tree, plus a shared **named-subform resolver** layer that wraps
`xii_subforms_compute` with the ~156 names as byte buffers (module-scope
`var [u8;N]` scratch, single-line, memoised like the existing
`xii_subforms_act_poly_mult` pattern).

iiis-1 traps to honour (from CLAUDE.md / memory): single-line `fn`
decls; no nested `/* */`; ASCII `--` not em-dash in comments; no `(`
directly after `return`/operator (bind to local first — see
`xii_subforms.iii::if_mask`); module-scope const names prefixed
(`XHC_…`); flat-scope unique locals; active-flag drives `while`; no local
`var` arrays inside fn bodies (module-scope scratch, unique names);
in-place vs returned-ref discipline (term ctors return fresh refs — no
mutation concern here).

Anti-bloat: the 156 name buffers are unavoidable sealed data (NIH; the
names ARE the spec). Memoise each (DONE flag + cached value) so repeated
construction is O(1) and deterministic. No observational/statistical
anything.

## 4. Verification plan (Phase 4 gate — all must pass)

1. Manual line-by-line audit of every pattern builder vs §26.8 table.
2. `build_stdlib.sh` (libiii_native.a) — `xii_horizon.iii` +
   `xii_subforms.iii` compile clean under iiis-0.
3. Rebuild iiis-1/iiis-2; **deterministic reseal** (2× identical builds)
   of `iiis-{1,2}.mhash` (bare-hash format — see
   `feedback_determinism`); iiis-0 unchanged.
4. **Triple bit-identity 57/57** for iiis-1 AND iiis-2 (corpus
   equivalence) — empirically, since `xii_horizon_construct` is off the
   byte path the expectation is no codegen change; verify, don't assume.
5. XII corpus via fixed `run_xii_corpus.sh` — `357_xii_horizon_reach`,
   `364_xii_horizon_metadata`, `360_xii_e2e_demo`, `344`, `371` all
   green; PASS ≥ prior 92/93 (only pre-existing non-XII `299`).
6. Add a corpus probe (or extend an existing horizon test) asserting a
   sample of constructed terms have the spec-correct kernel kinds +
   resolved (non-`id*2`) subforms — proves the placeholder is gone with
   evidence, not assertion.

## 5. ADR-XII-ι-1

**Status**: Accepted (design). **Context**: `xii_horizon_construct` was a
structural placeholder (synthetic `id*2` subforms); user directed the
maximal path ("Both, sequentially"). **Decision**: implement the
spec-exact 144-pattern template terms, resolving named subforms via the
existing `xii_subforms.iii` SHA-256 derivation; `$var` operands stay free
(documented emit_gen seam); guards/reserved return NULL_REF. Do NOT
fabricate sealed-ceremony Lattice bytes (process boundary). **Consequences**:
`xii_horizon.iii` gains a per-pattern builder + ~156 memoised
subform-name resolvers; the public API becomes honest/test-exercisable;
no byte-path/bit-identity change expected (verified). **Alternatives
rejected**: keep placeholder (workaround); remove function (user chose
implement); full pipeline realisation (blocked by sealed ceremony).
