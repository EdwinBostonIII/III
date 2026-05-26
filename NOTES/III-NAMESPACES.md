# III-NAMESPACES.md

> Operational namespace policy for the Living Sealed Lattice plan.
>
> **Not part of R1.** Not part of the derivative set listed in
> `DOCS/III-INDEX.md` §1.5. This document defines naming rules
> for new modules introduced by the lattice plan, so that new
> work composes cleanly with the existing 70 sealed modules and
> the 18-module compiler bootstrap.

---

## §0 Why This Document Exists

The lattice plan creates a new file at `STDLIB/iii/omnia/sid.iii`
that exposes a small graph-navigation API over the `crystal_id`
space. The compiler already has a *different* file
`COMPILER/BOOT/sid.iii` (1225 LOC) implementing the **Side-effect
Inverse Derivation** machinery used by sema, cg, proof, and emit
during the 32-step plan generation.

The two share an English name (`sid`) but are entirely distinct
in semantics, scope, ring, and audience:

| Aspect | `COMPILER/BOOT/sid.iii` | `STDLIB/iii/omnia/sid.iii` (lattice plan) |
|---|---|---|
| Declared module | `module sid` | `module omnia_sid` |
| Domain | Side-effect Inverse Derivation | Crystal-ID dependency graph |
| Audience | Compiler internals (sema/cg/proof/emit) | User code via `omnia` namespace |
| Ring | R-2 / R-1 (compiler privileged) | R3 (user-mode utility) |
| Cap surface | None (compile-time tooling) | `crystal_*` (slot-table) |
| State scale | 256 cycle records, 17 SE kinds, 32-step plan | up to 4096 transitive-closure crystal_ids |
| Witness flow | Emits SID inverse-plan certificates | Reads existing `crystal_edges_*` tables |

Confusion between these two would manifest as: a developer reading
the compiler's `sid_*` documentation and trying to call those
functions from user code, OR vice-versa. Worse, an importer might
write `use sid` in user code and unintentionally pull in the
1225-LOC compiler module.

This document fixes the ambiguity once.

---

## §1 The Rule

**Rule N1 — Namespace separation.**

The simple identifier `sid` is reserved at the **compiler bootstrap
tier** (Ring R-2 / R-1). User-mode (`R3`) modules MUST NOT declare
`module sid` and MUST NOT `use sid` to refer to the user-mode
crystal-graph functionality.

The user-mode crystal-graph module declares
`module omnia_sid`, lives at `STDLIB/iii/omnia/sid.iii`, and is
imported via `extern @abi(c-msvc-x64) fn omnia_sid_<symbol>(...) ... from "sid.iii"` (note the file-name path is unambiguous because the `STDLIB/iii/omnia/` prefix is supplied by the build script's source-search path; the linker disambiguates by qualified module name, never by file basename).

**Rule N2 — Future namespace rule.**

For any module-name that is meaningful in *both* the compiler
bootstrap (R-2/R-1) and user-mode (R3), the user-mode module MUST
prefix the identifier with its parent directory: `omnia_X`,
`numera_X`, `verba_X`, `aether_X`, `memoria_X`, `sanctus_X`,
`tempora_X`. This convention is already followed by every existing
STDLIB module (see `STDLIB/iii/SEAL.mhash`).

The compiler bootstrap tier may use bare names (`sid`, `lex`,
`parse`, `ast`, `sema`, `cg_r0`, `cg_r3`, `cg_rm1`, `cg_rm2`, `emit`,
`link`, `jit_emit`, `proof`, `witness_alloc`, `acc`, `ceiling`,
`hexad_check`, `main`) — these are the 18 sealed compiler module
names; expanding the set requires Catalyst promotion.

**Rule N3 — Linker enforcement (already in place; no new code).**

The existing linker (`COMPILER/BOOT/link.iii`):

* Deduplicates by qualified module name via `l_find_module`
  (line 1144, 1182) — distinct names cannot accidentally fuse.
* Detects export-symbol collisions across modules via
  `l_check_collisions` (line 952) — distinct modules exporting
  the same symbol fail with `E_COLLISION = 6i32`.

Therefore Rule N1 + Rule N2 are *sufficient* — no new linker code
is required to enforce them. Adding new linker code would
duplicate existing semantics and breach **M7 (anti-bloat density)**
and **M16 (edit-first/create-rarely)**.

---

## §2 Verification

A grep over the entire III tree for `^module\s+sid\s*$` produces
exactly one hit:

```
COMPILER/BOOT/sid.iii:36: module sid
```

(Confirmed at the time of this document's authorship, against the
live `tree_root cb05397c572ff2f60a55279ec3d2e61eafcb971f1215fd402a70ad9ec824c5b8`.)

After Step 0001 of the lattice plan, the same grep will continue
to produce exactly one hit. The new file
`STDLIB/iii/omnia/sid.iii` will declare `module omnia_sid`, not
`module sid`, per Rule N1.

---

## §3 Impact on R1

This document is **operational**, not constitutional. It does not
modify R1.A1 (Lexicon), R1.A2 (Grammar), R1.A10 (Modules), or any
other R1.X. It does not require Catalyst promotion. It does not
trigger DRTM relaunch.

If a future Catalyst promotion adds a constitutional rule that
generalizes Rule N1 (e.g., a new keyword `@namespace` that the
parser enforces), this document's content can migrate into the
appropriate R1.A* document at that time, and this document
becomes redundant — at which point this document is deleted.

---

## §4 Mandate Audit

* **M3** Architecture coherence: the rule preserves the established
  18-name compiler tier and 7-prefix STDLIB tier without expanding
  either set arbitrarily.
* **M4** NIH: pure prose document, no third-party content.
* **M5** No partial implementations: rule is fully specified, with
  enforcement mechanism named.
* **M7** Anti-bloat: by recognizing the existing linker is sufficient,
  this step writes zero new code.
* **M11** Cross-file harmony review: the rule is the harmony review
  for the file pair `COMPILER/BOOT/sid.iii` vs
  `STDLIB/iii/omnia/sid.iii`.
* **M16** Edit-first / create-rarely: only one new file (this one);
  no `.iii` files modified.
* All other process-time mandates: preserved by negation (no `.iii`
  changed).

## §5 Quality-Gate Audit

Q1 (corpus pass) preserved · Q2 (mhash determinism) preserved
(no `.iii` changed) · Q3 (golden-mhash) preserved · Q4 (witness
chain) not exercised · Q5 (K-floor) not exercised · Q6 (layered
seal) chain extends from the Step 0000a anchor via
`mhash_domain("seal_step_0000b")`.

## §6 W-Discipline / D-Gates / C-Conformance

Not applicable — no `.iii` source modified.
