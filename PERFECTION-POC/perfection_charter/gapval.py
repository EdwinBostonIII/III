"""Gap-aware values (Pi13) + contingent resolution (Pi8).

UNIFIED SUBSTRATE: this module no longer defines its own gap type. It delegates
to `negknow` for the single value type (Known | PGap) and the total, sound,
provenance-bearing, maximally-precise arithmetic. The earlier separate
`gapval.Gap` is gone -- that was drift, and the charter forbids drift.

What remains here is the expression-tree layer: evaluation, contingent
resolution (Pi8), and the deliberately-unsound `naive_evaluate` foil used by the
Pi13 falsifier.

  Expr := ("lit", int) | ("gap", tag) | (op, Expr, Expr)  for op in add/sub/mul/div
"""
from .negknow import Known, PGap, gap as _gap, is_known, is_gap, apply_op
from .mhash import mhash


def Gap(tag):
    """Back-compat constructor: a root gap that explains itself."""
    return _gap(tag, "gap:%s" % tag)


def _mk(op):
    def f(a, b):
        return apply_op(op, a, b)
    return f


# op-name -> total/sound function (also consumed by the charter's Pi8 falsifier)
_OPS = {op: _mk(op) for op in ("add", "sub", "mul", "div")}


def g_add(a, b):
    return apply_op("add", a, b)


def g_sub(a, b):
    return apply_op("sub", a, b)


def g_mul(a, b):
    return apply_op("mul", a, b)


def g_div(a, b):
    return apply_op("div", a, b)


def evaluate(expr, bindings=None):
    """Sound, total evaluation. `bindings` resolves contingent gaps by name."""
    bindings = bindings or {}
    kind = expr[0]
    if kind == "lit":
        return Known(expr[1])
    if kind == "gap":
        tag = expr[1]
        if tag.startswith("contingent:"):
            name = tag.split(":", 1)[1]
            if name in bindings:
                return Known(bindings[name])
        return _gap(tag, "gap:%s" % tag)
    return apply_op(kind, evaluate(expr[1], bindings), evaluate(expr[2], bindings))


def concrete_subresults(expr, bindings=None):
    """mhashes of every subexpression that evaluated to a Known value (Pi8)."""
    bindings = bindings or {}
    out = {}

    def walk(e):
        val = evaluate(e, bindings)
        if is_known(val):
            out[mhash(e)] = val.v
        if e[0] in _OPS:
            walk(e[1])
            walk(e[2])

    walk(expr)
    return out


def naive_evaluate(expr):
    """NOT sound. Treats gaps as 0 (a lie) and raises on div-by-zero (a crash).
    Exists only so the charter can prove the gap-aware evaluator avoids both.
    """
    kind = expr[0]
    if kind == "lit":
        return expr[1]
    if kind == "gap":
        return 0
    a = naive_evaluate(expr[1])
    b = naive_evaluate(expr[2])
    if kind == "add":
        return a + b
    if kind == "sub":
        return a - b
    if kind == "mul":
        return a * b
    if kind == "div":
        return a // b
    raise KeyError(kind)
