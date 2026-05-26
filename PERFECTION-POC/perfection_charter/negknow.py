"""Negative knowledge: provable ignorance as a first-class, witnessed value.

A gap is not a null and not an error -- it is a typed value that carries WHY it
is unknown and WHAT caused it. Combining values propagates provenance: an
operation on an unknown produces a derived gap whose antecedents are the gaps
that caused it, forming a content-addressed provenance DAG you can walk back to
root causes.

This is the executable form of "the system reconciles a gap by its nature": it
does not close the gap, it represents it -- soundly, totally, and with an
auditable explanation.
"""
from dataclasses import dataclass

from .mhash import mhash


@dataclass(frozen=True)
class Known:
    v: int


@dataclass(frozen=True)
class PGap:
    kind: str           # root: "essential" | "hole:<name>" | "redacted"; else "derived"
    reason: str         # human-readable explanation (never empty for a well-formed gap)
    antecedents: tuple  # tuple of PGap -- the causes (empty for a root gap)


def is_known(x):
    return isinstance(x, Known)


def is_gap(x):
    return isinstance(x, PGap)


def gap(kind, reason, antecedents=()):
    return PGap(kind, reason, tuple(antecedents))


_INT_OPS = {
    "add": lambda x, y: x + y,
    "sub": lambda x, y: x - y,
    "mul": lambda x, y: x * y,
}


def _idiv(x, y):
    """Integer division toward zero (deterministic; no float)."""
    q = abs(x) // abs(y)
    return -q if (x < 0) != (y < 0) else q


def apply_op(opname, a, b):
    """Total + sound + provenance-propagating binary operation.

    Maximal precision: the multiplicative annihilator (0 * anything == 0) holds
    even when the other operand is unknown -- so a gap is not propagated when the
    result is provably determined. Sound *and* precise.
    """
    if opname == "mul" and ((is_known(a) and a.v == 0) or (is_known(b) and b.v == 0)):
        return Known(0)
    if is_known(a) and is_known(b):
        if opname == "div":
            if b.v == 0:
                return PGap("essential", "division by zero", ())
            return Known(_idiv(a.v, b.v))
        return Known(_INT_OPS[opname](a.v, b.v))
    ants = tuple(g for g in (a, b) if is_gap(g))
    return PGap("derived", "result of %s on an unknown operand" % opname, ants)


def addr(g):
    """Content address of a gap (its place in the provenance DAG)."""
    return mhash(g)


def root_causes(g):
    """Walk provenance to the leaf (root) gaps that explain an unknown."""
    if not is_gap(g):
        return []
    if not g.antecedents:
        return [g]
    out = []
    for a in g.antecedents:
        out.extend(root_causes(a))
    return out


def well_formed(g):
    """A gap must explain itself: non-empty reason, and a derived gap must name
    at least one antecedent. This is what makes ignorance *provable* rather than
    silent.
    """
    if not is_gap(g):
        return True
    if not g.reason:
        return False
    if g.kind == "derived" and not g.antecedents:
        return False
    return all(well_formed(a) for a in g.antecedents)


def explain(g):
    """Human-readable account of why a value is unknown (for demos/audits)."""
    if not is_gap(g):
        return "known"
    roots = root_causes(g)
    return "unknown because: " + "; ".join("%s (%s)" % (r.kind, r.reason) for r in roots)
