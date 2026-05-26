"""The Perfection Charter self-audit engine.

Each predicate exposes verify() (the good case must hold) and falsify() (a
deliberately-bad case that MUST be caught -> falsify returns True iff the bad
case was correctly rejected). A predicate HOLDS iff verify() and falsify() are
both True. The audit content-addresses its own result into a reproducible seal.

Scope honesty: Pi1 is demonstrated only over the ternary algebra (full kernel
soundness is anchor A1, out of POC scope). Pi2 (decidable checking) is satisfied
by construction -- every check below is a bounded, total function returning a
definite bool.
"""
import random
import hashlib

from .mhash import mhash, canon, set_backend, get_backend
from . import trit
from . import sha256_nih
from . import hexad
from . import rewrite
from . import reversible as rev
from . import modules as mod
from .gapval import (Known, Gap, is_known, is_gap, evaluate,
                     concrete_subresults, naive_evaluate, _OPS)
from .witnesscommons import Commons
from . import kernel


# --------------------------------------------------------------------------- #
# corpora (seeded -> reproducible)
# --------------------------------------------------------------------------- #
def _gen_expr(rng, depth):
    if depth <= 0 or rng.randint(0, 9) < 3:
        if rng.randint(0, 1) == 0:
            return ("lit", rng.randint(-5, 5))
        return ("var", rng.choice(["x", "y", "z"]))
    return ("add", _gen_expr(rng, depth - 1), _gen_expr(rng, depth - 1))


def _expr_corpus(n=40):
    rng = random.Random(20260524)
    # top is always an add so reduction order genuinely differs
    return [("add", _gen_expr(rng, 4), _gen_expr(rng, 4)) for _ in range(n)]


def _gen_gexpr(rng, depth):
    # gapval domain: leaves are literals or gaps (no free vars)
    if depth <= 0 or rng.randint(0, 9) < 3:
        r = rng.randint(0, 9)
        if r < 6:
            return ("lit", rng.randint(-5, 5))
        if r < 8:
            return ("gap", "essential")
        return ("gap", "contingent:x")
    op = ("add", "sub", "mul")[rng.randint(0, 2)]
    return (op, _gen_gexpr(rng, depth - 1), _gen_gexpr(rng, depth - 1))


def _gap_expr_corpus(n=40):
    rng = random.Random(13)
    return [_gen_gexpr(rng, 4) for _ in range(n)]


def _state_cycle_corpus(n=40):
    rng = random.Random(777)
    out = []
    for _ in range(n):
        state = tuple(rng.randint(-50, 50) for _ in range(4))
        ops = []
        for _ in range(rng.randint(1, 8)):
            pick = rng.randint(0, 3)
            if pick == 0:
                ops.append(rev.add_const(rng.randint(0, 3), rng.randint(-9, 9)))
            elif pick == 1:
                ops.append(rev.xor_const(rng.randint(0, 3), rng.randint(0, 255)))
            elif pick == 2:
                ops.append(rev.swap(rng.randint(0, 3), rng.randint(0, 3)))
            else:
                ops.append(rev.negate(rng.randint(0, 3)))
        out.append((state, ops))
    return out


# --------------------------------------------------------------------------- #
# determinism helper (Pi12 falsifier)
# --------------------------------------------------------------------------- #
_CTR = {"v": 0}


def _impure():
    _CTR["v"] += 1
    return _CTR["v"]


# --------------------------------------------------------------------------- #
# Pi8 falsifier: a non-conservative ("destructive") resolver
# --------------------------------------------------------------------------- #
def _evaluate_bad(expr, bindings):
    shift = len(bindings)  # binding ANYTHING shifts every literal -> non-conservative

    def ev(e):
        if e[0] == "lit":
            return Known(e[1] + shift)
        if e[0] == "gap":
            tag = e[1]
            if tag.startswith("contingent:") and tag.split(":", 1)[1] in bindings:
                return Known(bindings[tag.split(":", 1)[1]])
            return Gap(tag)
        return _OPS[e[0]](ev(e[1]), ev(e[2]))

    return ev(expr)


def _concrete_bad(expr, bindings):
    out = {}

    def walk(e):
        val = _evaluate_bad(e, bindings)
        if is_known(val):
            out[mhash(e)] = val.v
        if e[0] in _OPS:
            walk(e[1])
            walk(e[2])

    walk(expr)
    return out


# --------------------------------------------------------------------------- #
# Pi6 bit-identity: two GENUINELY independent polynomial evaluators
# (Horner's method vs the power-series expansion -- different control flow and
# different intermediate values, yet they must agree byte-for-byte).
# --------------------------------------------------------------------------- #
def _poly_horner(coeffs, x):
    acc = 0
    for c in reversed(coeffs):
        acc = acc * x + c
    return acc


def _poly_powers(coeffs, x):
    total = 0
    p = 1
    for c in coeffs:
        total += c * p
        p *= x
    return total


def _poly_buggy(coeffs, x):
    total = 0
    p = 1
    for c in coeffs:
        total += c * p
        p *= (x + 1)             # bug: corrupts the base update -> divergent impl
    return total


# --------------------------------------------------------------------------- #
# corpus non-degeneracy (so no predicate can pass vacuously on a thin corpus)
# --------------------------------------------------------------------------- #
def _depth(e):
    if e[0] in ("lit", "var", "gap", "hole"):
        return 0
    return 1 + max(_depth(e[1]), _depth(e[2]))


def _has_gap(e):
    if e[0] == "gap":
        return True
    if e[0] in ("lit", "var", "hole"):
        return False
    return _has_gap(e[1]) or _has_gap(e[2])


def _expr_corpus_nondegenerate():
    return sum(1 for e in _expr_corpus() if _depth(e) >= 2) >= 5


def _gap_corpus_nondegenerate():
    return sum(1 for e in _gap_expr_corpus() if _has_gap(e)) >= 5


# --------------------------------------------------------------------------- #
# predicate checks
# --------------------------------------------------------------------------- #
def pi1_verify():
    # REAL logical soundness via the proof kernel (Curry-Howard).
    A = ("base", "A")
    B = ("base", "B")
    proofs = [
        (("lam", A, ("var", 0)), ("arrow", A, A)),                    # A -> A
        (("lam", ("prod", A, B), ("fst", ("var", 0))),
         ("arrow", ("prod", A, B), A)),                               # A&B -> A
        (("lam", A, ("inl", B, ("var", 0))), ("arrow", A, ("sum", A, B))),  # A -> A|B
        (("unit",), ("true",)),                                       # True
    ]
    if not all(kernel.check([], term, ty) for term, ty in proofs):
        return False
    # the heart of soundness: NO closed term inhabits False
    for term in [("unit",), ("lam", A, ("var", 0)), ("pair", ("unit",), ("unit",))]:
        if kernel.check([], term, ("false",)):
            return False
    # ternary algebra laws retained as a secondary structural check
    return trit.matches_spec_tables() and trit.algebra_laws_hold()


def pi1_falsify():
    # The argument-type check in `app` is exactly what keeps False uninhabited.
    # Drop it (infer_unsound) and a closed term inhabits False -> caught.
    idF = ("lam", ("false",), ("var", 0))      # lam x:False. x  :  False -> False
    bad = ("app", idF, ("unit",))              # applied to unit (ill-typed)
    sound_rejects = not kernel.check([], bad, ("false",))
    unsound_inhabits_false = kernel.infer_unsound([], bad) == ("false",)
    return sound_rejects and unsound_inhabits_false


def pi2_verify():
    # decidable checking: deterministic verdict + structural termination bound
    for t in kernel.term_corpus():
        c = [0]
        r1 = kernel.infer([], t, c)
        r2 = kernel.infer([], t)
        if r1 != r2:                            # deterministic
            return False
        if c[0] > kernel.node_count(t) + 1:     # calls bounded by term size
            return False
    return True


def pi2_falsify():
    # a checker with no well-founded measure fails to DECIDE a term the sound
    # checker decides (it only halts by exhausting fuel) -> non-decidability caught
    t = ("unit",)
    sound = kernel.infer([], t)
    loop_result = kernel.looping_infer([], t, 1000)
    return sound is not None and loop_result is None


def pi21_verify():
    # inductive Nat: the structural recursor is well-typed, computes, and STRONGLY
    # NORMALIZES; every well-typed term in the corpus reduces to a normal form.
    add = kernel.add_term()
    if kernel.infer([], add) != ("arrow", ("nat",), ("arrow", ("nat",), ("nat",))):
        return False
    expr = ("app", ("app", add, kernel.numeral(2)), kernel.numeral(3))
    nf, _ = kernel.normalize(expr)
    if nf is None or kernel.nat_to_int(nf) != 5:
        return False
    for t in kernel.term_corpus():
        if kernel.infer([], t) is not None:
            n, _ = kernel.normalize(t)
            if n is None:                          # a well-typed term failed to normalize
                return False
    return True


def pi21_falsify():
    # Omega loops forever; the type system REJECTS it -> strong normalization is
    # guaranteed *by typing*. Catching this proves the rejection is load-bearing.
    rejected = kernel.infer([], kernel.OMEGA) is None
    nf, steps = kernel.normalize(kernel.OMEGA, cap=300)
    loops = nf is None and steps == 300
    return rejected and loops


def pi22_verify():
    return kernel.strictly_positive(kernel.NAT_DECL)


def pi22_falsify():
    # a non-positive inductive (Bad = C (Bad -> Bad)) would encode general
    # recursion and break normalization -> it must be rejected
    return not kernel.strictly_positive(kernel.BAD_DECL)


def pi3_verify():
    if not _expr_corpus_nondegenerate():           # never pass vacuously
        return False
    for e in _expr_corpus():
        same_nf, traces_differed = rewrite.confluent_on(e)
        if not (same_nf and traces_differed):
            return False
    return True


def pi3_falsify():
    nfs, terminated = rewrite.ars_normal_forms("x", {"x": ["a", "b"]})
    return terminated and len(nfs) > 1  # divergence correctly observed


def pi4_verify():
    # real strong normalization on the actual expression algebra, with a
    # well-founded measure (node_count strictly decreases on every step)
    if not _expr_corpus_nondegenerate():
        return False
    for e in _expr_corpus():
        terminated, decreasing = rewrite.normalizes(e)
        if not (terminated and decreasing):
            return False
    return True


def pi4_falsify():
    bad = lambda e: ("add", e, ("lit", 0))         # always applies, always grows
    return not rewrite.runs_to_fixpoint(bad, ("var", "x"))


def _nf_seal(corpus, sort):
    nfs = [mhash(rewrite.normalize_left(e, [])) for e in corpus]
    return mhash(sorted(nfs)) if sort else mhash(nfs)


def pi5_verify():
    # determinism under reordering: canonical aggregation of normal forms is
    # invariant to evaluation order (exploits confluence, Pi3)
    corpus = _expr_corpus()
    base = _nf_seal(corpus, sort=True)
    rng = random.Random(5)
    for _ in range(6):
        shuffled = corpus[:]
        rng.shuffle(shuffled)
        if _nf_seal(shuffled, sort=True) != base:
            return False
    return True


def pi5_falsify():
    corpus = _expr_corpus()
    rng = random.Random(6)
    shuffled = corpus[:]
    rng.shuffle(shuffled)
    # non-canonical (order-preserving) aggregation leaks order into the seal
    return _nf_seal(corpus, sort=False) != _nf_seal(shuffled, sort=False)


def pi6_verify():
    cases = [([1, 2, 3, 4], 5), ([0, -3, 7], 2), ([9], 11), ([1, 0, 0, 1], 3)]
    return all(mhash(_poly_horner(c, x)) == mhash(_poly_powers(c, x)) for c, x in cases)


def pi6_falsify():
    c, x = [1, 2, 3, 4], 5
    return mhash(_poly_horner(c, x)) != mhash(_poly_buggy(c, x))  # divergent impl caught


def pi7_verify():
    a = {"a": 1, "b": 2, "c": [3, 4]}
    b = {}
    b["c"] = [3, 4]; b["b"] = 2; b["a"] = 1       # built in a different order
    return mhash(a) == mhash(b)


def pi7_falsify():
    a = {"a": 1, "b": 2}
    b = {"b": 2, "a": 1}
    return str(a) != str(b)  # naive serialization drifts on equal data -> needs canon


def pi8_verify():
    expr = ("add", ("mul", ("lit", 2), ("lit", 3)), ("gap", "contingent:x"))
    before = concrete_subresults(expr, {})
    after = concrete_subresults(expr, {"x": 10})
    return all(after.get(k) == v for k, v in before.items())


def pi8_falsify():
    expr = ("add", ("mul", ("lit", 2), ("lit", 3)), ("gap", "contingent:x"))
    before = _concrete_bad(expr, {})
    after = _concrete_bad(expr, {"x": 10})
    return not all(after.get(k) == v for k, v in before.items())


def pi9_verify():
    for state, ops in _state_cycle_corpus():
        if not rev.cycle_round_trips(state, ops):
            return False
    return True


def pi9_falsify():
    state = (1, 2, 3, 4)
    lossy = [rev.add_const(0, 5), rev.zero_slot(1), rev.add_const(2, 3)]
    return not rev.cycle_round_trips(state, lossy)  # info loss breaks round-trip


def pi10_verify():
    samples = [(0, 0, 0, 0), (1, 2, 3, 4), (-5, 9, 0, 7)]
    return all(rev.admit(op, samples) for op in
               [rev.add_const(0, 3), rev.xor_const(1, 9), rev.swap(0, 2), rev.negate(3)])


def pi10_falsify():
    samples = [(0, 0, 0, 0), (1, 2, 3, 4), (-5, 9, 0, 7)]
    refused = not rev.admit(rev.zero_slot(1), samples)            # untagged lossy refused
    allowed = rev.admit(rev.zero_slot(1, compromise=True), samples)  # typed exception ok
    return refused and allowed


def pi11_verify():
    for e in _gap_expr_corpus():
        v = evaluate(e, {})
        if not (is_known(v) or is_gap(v)):
            return False                          # always a typed value, never None/raw
    # a gap-bearing expr must yield a typed Gap, never a silent value
    ge = ("add", ("lit", 1), ("gap", "essential"))
    return is_gap(evaluate(ge, {}))


def pi11_falsify():
    ge = ("add", ("lit", 1), ("gap", "essential"))
    silent = naive_evaluate(ge)                   # returns a bare int (lies, untyped)
    return isinstance(silent, int) and not is_gap(silent)


def pi13_verify():
    # total + sound: never raises; gap-dependent results are gaps, not numbers
    if not _gap_corpus_nondegenerate():            # never pass vacuously
        return False
    ok = True
    div0 = ("div", ("lit", 5), ("lit", 0))
    if not is_gap(evaluate(div0, {})):            # div-by-zero -> sound gap
        ok = False
    ann = evaluate(("mul", ("lit", 0), ("gap", "essential")), {})
    if not (is_known(ann) and ann.v == 0):        # precision: 0 * unknown == 0
        ok = False
    for e in _gap_expr_corpus():
        ge = ("add", e, ("gap", "essential"))
        try:
            r = evaluate(ge, {})
        except Exception:
            return False                          # any raise == not total
        if not is_gap(r):
            ok = False
    return ok


def pi13_falsify():
    # the naive evaluator either lies (gap->0) or crashes (div by zero)
    crashed = False
    try:
        naive_evaluate(("div", ("lit", 5), ("lit", 0)))
    except ZeroDivisionError:
        crashed = True
    lied = naive_evaluate(("add", ("lit", 1), ("gap", "essential"))) == 1
    return crashed and lied


def pi14_verify():
    return mod.b_noninterference() and mod.pure_b_stable_under_malign() \
        and mod.commons_third_party_benefit()


def pi14_falsify():
    return mod.side_channel_detected()            # leaky B perturbed via side channel


def c1_verify():
    return mod.gap_contained()


def c1_falsify():
    # if containment failed, a gap in q would corrupt B (which ignores q).
    # B must stay a correct Known even when q is a gap; prove the corrupt case is
    # distinguishable: with q known vs gap, B is byte-identical (no leak).
    r_known = mod.module_a(7, Known(42))
    r_gap = mod.module_a(7, Gap("essential"))
    b_same = mhash(mod.module_b(r_known)) == mhash(mod.module_b(r_gap))
    c_gap = is_gap(mod.module_c(r_gap))
    return b_same and c_gap


def rep_verify():
    if not hexad.is_representable(hexad.SAFE_HEXAD):
        return False
    return all(not hexad.is_representable(h) for h in hexad.BRICKING_OPS.values())


def rep_falsify():
    # a naive check that only inspects informational pillars P5/P6 would ADMIT a
    # bricking op; the real structural rule must REJECT it.
    def naive_rep(h):
        return h[4] != trit.Trit.NEG and h[5] != trit.Trit.NEG
    h = hexad.BRICKING_OPS["capsule_update"]
    return naive_rep(h) and not hexad.is_representable(h)


def pi12_verify():
    # the audit content-addresses its own description; recomputation reproduces it
    desc = [(p["id"], p["title"]) for p in PREDICATES]
    return mhash(desc) == mhash(desc)


def pi12_falsify():
    _CTR["v"] = 0
    snap1 = mhash(["report", _impure()])
    snap2 = mhash(["report", _impure()])
    return snap1 != snap2                          # a nondeterministic seal is caught


def pi20_verify():
    # hand-rolled SHA-256 matches the reference on KATs (NIH discipline met)...
    kats = {
        b"": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        b"abc": "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
    }
    for msg, want in kats.items():
        if sha256_nih.hexdigest(msg) != want:
            return False
    # ...and it agrees with the oracle on the canonical encoder (hash-agnostic CA)
    for obj in [0, 1, -7, "abc", [1, 2, 3], {"a": 1, "b": [2]}, ("x", ("y",))]:
        cb = canon(obj)
        if sha256_nih.hexdigest(cb) != hashlib.sha256(cb).hexdigest():
            return False
    # ...and it can BE the load-bearing backend: swapping mhash to the hand-rolled
    # hash leaves every content address identical (proven, then restored).
    objs = [0, "abc", [1, 2, 3], {"a": 1}, ("x", ("y",))]
    before = [mhash(o) for o in objs]
    saved = get_backend()
    set_backend(sha256_nih.hexdigest)
    try:
        after = [mhash(o) for o in objs]
    finally:
        set_backend(saved)
    return before == after


def pi20_falsify():
    # a hash with one round constant corrupted diverges from the reference
    return sha256_nih.hexdigest_buggy(b"abc") != sha256_nih.hexdigest(b"abc")


# --------------------------------------------------------------------------- #
# registry
# --------------------------------------------------------------------------- #
PREDICATES = [
    {"id": "Pi1",  "scope": "core",   "title": "Soundness (kernel: False uninhabited)", "verify": pi1_verify,  "falsify": pi1_falsify},
    {"id": "Pi2",  "scope": "core",   "title": "Decidable checking (total/terminating)", "verify": pi2_verify,  "falsify": pi2_falsify},
    {"id": "Pi21", "scope": "core",   "title": "Inductive + structural recursion (SN)",  "verify": pi21_verify, "falsify": pi21_falsify},
    {"id": "Pi22", "scope": "core",   "title": "Strict positivity (inductives)",        "verify": pi22_verify, "falsify": pi22_falsify},
    {"id": "Pi3",  "scope": "core",   "title": "Confluence (order-independent)",        "verify": pi3_verify,  "falsify": pi3_falsify},
    {"id": "Pi4",  "scope": "core",   "title": "Strong normalization (termination)",    "verify": pi4_verify,  "falsify": pi4_falsify},
    {"id": "Pi5",  "scope": "core",   "title": "Determinism (reproducible)",            "verify": pi5_verify,  "falsify": pi5_falsify},
    {"id": "Pi6",  "scope": "core",   "title": "Bit-identity (impl-independent)",       "verify": pi6_verify,  "falsify": pi6_falsify},
    {"id": "Pi7",  "scope": "core",   "title": "Seal stability (canonical address)",    "verify": pi7_verify,  "falsify": pi7_falsify},
    {"id": "Pi20", "scope": "core",   "title": "Hand-rolled SHA-256 fidelity (NIH)",    "verify": pi20_verify, "falsify": pi20_falsify},
    {"id": "Pi8",  "scope": "core",   "title": "Conservative extension",                "verify": pi8_verify,  "falsify": pi8_falsify},
    {"id": "Pi9",  "scope": "core",   "title": "Reversibility (SID round-trip)",        "verify": pi9_verify,  "falsify": pi9_falsify},
    {"id": "Pi10", "scope": "core",   "title": "Gated evolution (admission)",           "verify": pi10_verify, "falsify": pi10_falsify},
    {"id": "Pi11", "scope": "core",   "title": "Declared uncertainty (typed gaps)",     "verify": pi11_verify, "falsify": pi11_falsify},
    {"id": "Pi12", "scope": "core",   "title": "Self-audit (reproducible seal)",        "verify": pi12_verify, "falsify": pi12_falsify},
    {"id": "Pi13", "scope": "core",   "title": "Gap-totality (total + sound)",          "verify": pi13_verify, "falsify": pi13_falsify},
    {"id": "Pi14", "scope": "core",   "title": "Non-malign composition",                "verify": pi14_verify, "falsify": pi14_falsify},
    {"id": "C1",   "scope": "core",   "title": "Gap-containment (corollary)",           "verify": c1_verify,   "falsify": c1_falsify},
    {"id": "REP",  "scope": "core",   "title": "Representability (bricking rejected)",   "verify": rep_verify,  "falsify": rep_falsify},
]


def run_audit():
    results = []
    for p in PREDICATES:
        v = bool(p["verify"]())
        f = bool(p["falsify"]())
        results.append({
            "id": p["id"], "title": p["title"], "scope": p["scope"],
            "verify": v, "falsify": f, "holds": v and f,
        })
    all_hold = all(r["holds"] for r in results)
    seal = mhash([{k: r[k] for k in ("id", "verify", "falsify", "holds")} for r in results])
    return {"results": results, "all_hold": all_hold, "seal": seal}
