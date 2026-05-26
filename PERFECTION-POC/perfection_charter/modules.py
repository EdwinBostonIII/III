"""Non-malign composition (Pi14) and gap-containment (C1).

Three modules talk ONLY through gap-aware, content-addressed values and the
witness commons -- never through hidden state:

  A : produces a record {p: Known, q: Known|Gap}
  B : consumes A.p only          ->  Known
  C : consumes A.q               ->  Known|Gap

Properties demonstrated:
  * Non-interference (Pi14a): B's output is identical whether A.q is Known or a
    Gap -- B cannot be perturbed by data it does not depend on.
  * Gap-containment (C1): when A.q is a Gap, B stays a correct Known and C
    yields an honest Gap. The gap is confined to the edge that consumes it; it
    never becomes a wrong concrete value elsewhere.
  * Commons benefit (Pi14b): C can verify A's witness from the shared commons
    even though A never calls C.

Falsifier: a malign module that writes a hidden side channel, plus a 'leaky' B
that reads it -- bypassing the verified boundary. B's output then changes when
only the malign module ran, which the non-interference check must catch.
"""
from .gapval import Known, Gap, is_gap, is_known, g_add, g_mul
from .witnesscommons import Commons
from .mhash import mhash


def module_a(seed_p, q_value):
    return {"p": Known(seed_p), "q": q_value}


def module_b(rec):
    p = rec["p"]                       # f(p) = 3p + 1
    return g_add(g_mul(p, Known(3)), Known(1))


def module_c(rec):
    q = rec["q"]                       # g(q) = q + 100
    return g_add(q, Known(100))


def b_noninterference() -> bool:
    p = 7
    r_known = module_a(p, Known(42))
    r_gap = module_a(p, Gap("essential"))
    return mhash(module_b(r_known)) == mhash(module_b(r_gap))


def gap_contained() -> bool:
    r = module_a(7, Gap("essential"))
    return is_known(module_b(r)) and is_gap(module_c(r))


def commons_third_party_benefit() -> bool:
    commons = Commons()
    r = module_a(7, Known(42))
    commons.append("A", "produce", r)              # value-only; inputs default ()
    found = commons.find(mhash(r))                 # C looks A up without A calling C
    return found is not None and found.producer == "A"


# --- side-channel falsifier -------------------------------------------------
_LEAK = {"v": 0}


def _malign_module():
    _LEAK["v"] += 1000                 # hidden write, bypassing the value bus


def _module_b_leaky(rec):
    base = module_b(rec)
    if is_gap(base):
        return base
    return Known(base.v + _LEAK["v"])  # bad: mixes in hidden global state


def pure_b_stable_under_malign() -> bool:
    """The honest B is unaffected when only the malign module runs."""
    _LEAK["v"] = 0
    rec = module_a(7, Known(42))
    before = mhash(module_b(rec))
    _malign_module()
    after = mhash(module_b(rec))
    return before == after


def side_channel_detected() -> bool:
    """True iff we catch the leaky B changing while its declared input did not."""
    _LEAK["v"] = 0
    rec = module_a(7, Known(42))
    before = mhash(_module_b_leaky(rec))
    _malign_module()
    after = mhash(_module_b_leaky(rec))
    return before != after
