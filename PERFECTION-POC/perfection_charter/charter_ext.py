"""Charter extension: four foundational capabilities, each a falsifiable
predicate, built additively on the untouched base charter.

  Pi15  Negative knowledge      -- provable ignorance with provenance
  Pi16  Compute-with-holes      -- sound partial computation + conservative resolve
  Pi17  Provable forgetting     -- reversible redaction (integrity+continuity+blast)
  Pi18  Quine-seal              -- reflective self-verifying fixpoint

The base modules are not modified, so the base 15 predicates and their seal must
remain identical -- which is Pi8 (conservative extension) demonstrated at the
level of the system's own evolution.
"""
import random

from .charter import run_audit as base_audit, PREDICATES as BASE_PREDICATES
from .mhash import mhash
from . import negknow as nk
from . import holes as H
from . import forgetting as F
from . import quineseal as Q
from . import hexad
from . import sovval as SV
from .witnesscommons import Commons

# The base seal, re-pinned across the gap-filling passes that added real kernel
# soundness (Pi1), decidability (Pi2), inductive recursion + SN (Pi21), strict
# positivity (Pi22), and hand-rolled-hash fidelity (Pi20). Each was an
# intentional, audited DRIFT-driven reseal -- the predicate set grew.
BASE_SEAL = "16fe0950bc35faca77f3ae9f9e85e5d1bba0c417ef01b603c6beebbba78abe95"


# --------------------------------------------------------------------------- #
# corpora / fixtures
# --------------------------------------------------------------------------- #
def _gen_hexpr(rng, depth):
    if depth <= 0 or rng.randint(0, 9) < 3:
        if rng.randint(0, 1) == 0:
            return ("lit", rng.randint(-5, 5))
        return ("hole", ("x", "y", "z")[rng.randint(0, 2)])
    op = ("add", "sub", "mul")[rng.randint(0, 2)]
    return (op, _gen_hexpr(rng, depth - 1), _gen_hexpr(rng, depth - 1))


def _hole_corpus(n=30):
    rng = random.Random(99)
    return [_gen_hexpr(rng, 4) for _ in range(n)]


# A chain mixing a redaction target, a dependent witness, and an independent one.
_FORGET_SPECS = [
    ("g0", "lit", [], 10),
    ("g1", "lit", [], 20),
    ("sum", "add", [0, 1], None),     # seq 2 -> 30  (redaction target)
    ("g3", "lit", [], 5),
    ("dep", "add", [2, 3], None),     # seq 4 -> 35  (depends on 2)
    ("indep", "mul", [1, 3], None),   # seq 5 -> 100 (independent of 2)
]


def _forget_chain():
    return F.build_chain(_FORGET_SPECS)


# --------------------------------------------------------------------------- #
# Pi15 -- negative knowledge
# --------------------------------------------------------------------------- #
def pi15_verify():
    g = nk.apply_op("mul",
                    nk.gap("hole:x", "x not set"),
                    nk.gap("essential", "beyond comprehension"))
    roots = nk.root_causes(g)
    return (nk.well_formed(g) and len(roots) == 2
            and all(r.reason for r in roots) and g.kind == "derived")


def pi15_falsify():
    silent = nk.gap("derived", "", ())          # a derived gap with no provenance
    return not nk.well_formed(silent)            # malformed ignorance is caught


# --------------------------------------------------------------------------- #
# Pi16 -- compute-with-holes
# --------------------------------------------------------------------------- #
def pi16_verify():
    full = {"x": 3, "y": 4, "z": 5}
    for e in _hole_corpus():
        try:
            if not H.partial_sound(e, {}, full):           # Known partials agree with full
                return False
        except Exception:
            return False                                   # must be total
        if not H.is_conservative(e, {}, full):
            return False
        if not H.is_conservative(e, {"x": 3}, {"x": 3, "y": 4}):
            return False
    return True


def pi16_falsify():
    e = ("add", ("lit", 1), ("hole", "x"))
    honest = H.evaluate_partial(e, {})           # -> gap (sound)
    guessed = H.evaluate_guessing(e, {})         # -> 1 (fabricated concrete)
    return nk.is_gap(honest) and isinstance(guessed, int)


# --------------------------------------------------------------------------- #
# Pi17 -- provable forgetting
# --------------------------------------------------------------------------- #
def pi17_verify():
    chain = _forget_chain()
    p = F.proves_forgetting(chain, 2, "subject erasure request")
    return p["integrity"] and p["continuity"] and p["gone"] and p["blast"]


def pi17_falsify():
    chain = _forget_chain()
    # bad mode 1: naive delete -> chain integrity breaks
    naive = [w for w in chain if w.seq != 2]
    broke = not F.verify(naive)
    # bad mode 2: silent redact (value 0, not a gap) -> a dependent stays concrete
    silent = F._reseal(chain, 2, nk.Known(0))
    deps = F.dependents(chain, 2) - {2}
    leaked = any(nk.is_known(silent[j].value) for j in deps)
    return broke and leaked


# --------------------------------------------------------------------------- #
# Pi18 -- quine-seal
# --------------------------------------------------------------------------- #
def pi18_verify():
    payload = [("Pi", i) for i in range(3)]
    manifest = Q.source_manifest(Q.package_dir())
    behavior = Q.full_behavior_manifest()        # DEEP: every package function's bytecode
    seal = Q.quine_seal(payload, manifest, behavior)
    commits_to_source = "quineseal.py" in manifest and "charter_ext.py" in manifest
    # deep coverage: helpers, not just predicates, are sealed
    commits_to_behavior = ("negknow.well_formed" in behavior
                           and "holes.evaluate_partial" in behavior
                           and "kernel.infer" in behavior)
    return (Q.verify_fixpoint(seal, payload, manifest, behavior)
            and commits_to_source and commits_to_behavior)


def pi18_falsify():
    payload = [("Pi", i) for i in range(3)]
    manifest = Q.source_manifest(Q.package_dir())
    behavior = Q.full_behavior_manifest()
    seal = Q.quine_seal(payload, manifest, behavior)
    tampered = dict(behavior)
    tampered["negknow.well_formed"] = "00" * 32  # a deep HELPER's bytecode 'changed'
    return not Q.verify_fixpoint(seal, payload, manifest, tampered)


# --------------------------------------------------------------------------- #
# Pi19 -- the Sovereign Value (the deepening integration)
# --------------------------------------------------------------------------- #
def pi19_verify():
    commons = Commons()
    a = SV.sv_lift(3, hexad.SAFE_HEXAD)
    b = SV.sv_lift(4, hexad.SAFE_HEXAD)
    r = SV.sv_op("mul", a, b, commons=commons, producer="t")
    if SV.is_refused(r):
        return False
    ok_payload = nk.is_known(r.payload) and r.payload.v == 12      # payload composed
    ok_hexad = hexad.is_representable(r.hexad)                     # hexad composed + safe
    ok_witness = len(commons.chain) == 1 and commons.verify()     # witness emitted
    g = SV.sv_op("add", SV.sv_gap(nk.gap("essential", "x"), hexad.SAFE_HEXAD), b)
    ok_gap = (not SV.is_refused(g)) and nk.is_gap(g.payload)       # gap rides the value
    return ok_payload and ok_hexad and ok_witness and ok_gap


def pi19_falsify():
    bricking = SV.SovVal(nk.Known(1), hexad.BRICKING_OPS["capsule_update"])
    safe = SV.sv_lift(5, hexad.SAFE_HEXAD)
    refused = SV.is_refused(SV.sv_op("add", bricking, safe))       # composition refused
    naive_h = SV.compose6(bricking.hexad, safe.hexad)              # skipping the guard...
    naive_illegal = not hexad.is_representable(naive_h)            # ...yields an illegal hexad
    return refused and naive_illegal


EXT_PREDICATES = [
    {"id": "Pi15", "scope": "core", "title": "Negative knowledge (provenance)",   "verify": pi15_verify, "falsify": pi15_falsify},
    {"id": "Pi16", "scope": "core", "title": "Compute-with-holes (sound partial)", "verify": pi16_verify, "falsify": pi16_falsify},
    {"id": "Pi17", "scope": "core", "title": "Provable forgetting (redaction)",    "verify": pi17_verify, "falsify": pi17_falsify},
    {"id": "Pi18", "scope": "core", "title": "Quine-seal (behavioral fixpoint)",   "verify": pi18_verify, "falsify": pi18_falsify},
    {"id": "Pi19", "scope": "core", "title": "Sovereign Value (unified)",          "verify": pi19_verify, "falsify": pi19_falsify},
]


def run_ext_audit():
    base = base_audit()
    ext = []
    for p in EXT_PREDICATES:
        v = bool(p["verify"]())
        f = bool(p["falsify"]())
        ext.append({"id": p["id"], "title": p["title"], "scope": p["scope"],
                    "verify": v, "falsify": f, "holds": v and f})
    combined = base["results"] + ext
    all_hold = all(r["holds"] for r in combined)
    base_unchanged = base["seal"] == BASE_SEAL          # Pi8 at evolution scale
    payload = [{k: r[k] for k in ("id", "verify", "falsify", "holds")} for r in combined]
    manifest = Q.source_manifest(Q.package_dir())
    behavior = Q.full_behavior_manifest()                    # source AND deep behavior
    qseal = Q.quine_seal(payload, manifest, behavior)
    fixpoint_ok = Q.verify_fixpoint(qseal, payload, manifest, behavior)
    return {"base": base, "ext": ext, "combined": combined, "all_hold": all_hold,
            "base_unchanged": base_unchanged, "qseal": qseal, "fixpoint_ok": fixpoint_ok}
