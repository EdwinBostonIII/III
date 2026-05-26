"""Compute-with-holes: sound partial computation under partial information.

Evaluate an expression that still contains unresolved holes. The guarantee
(soundness-of-partial): a node is Known if and only if all of its transitive
inputs are known; otherwise it is a provenance-bearing gap that points at the
holes it is waiting on. Resolving holes later is conservative -- every value
that was already concrete is byte-identical afterward (Pi8 at value scale).

Expr := ("lit", int) | ("hole", name) | (op, Expr, Expr)  for op in add/sub/mul
"""
from .negknow import Known, gap, is_known, is_gap, apply_op
from .mhash import mhash


def evaluate_partial(expr, env):
    """env maps resolved hole-name -> int. Total; never raises."""
    kind = expr[0]
    if kind == "lit":
        return Known(expr[1])
    if kind == "hole":
        name = expr[1]
        if name in env:
            return Known(env[name])
        return gap("hole:" + name, "hole %r not yet resolved" % name)
    a = evaluate_partial(expr[1], env)
    b = evaluate_partial(expr[2], env)
    return apply_op(kind, a, b)


def partial_sound(expr, env, full_env):
    """The true soundness-of-partial guarantee: if the partial evaluation under
    `env` is Known, then the fully-resolved evaluation under `full_env` agrees
    exactly. (A gap is always sound.)

    This is the correct invariant -- stronger than the naive "Known iff no holes
    remain", and compatible with precision rules like the 0-annihilator, where
    `0 * hole` is soundly Known despite an unresolved hole.
    """
    partial = evaluate_partial(expr, env)
    full = evaluate_partial(expr, full_env)
    if is_known(partial):
        return is_known(full) and full.v == partial.v
    return True


def known_nodes(expr, env):
    """mhash(subexpr) -> value for every subexpression that is Known."""
    out = {}

    def walk(e):
        v = evaluate_partial(e, env)
        if is_known(v):
            out[mhash(e)] = v.v
        if e[0] in ("add", "sub", "mul"):
            walk(e[1])
            walk(e[2])

    walk(expr)
    return out


def is_conservative(expr, env0, env1):
    """Resolving more holes (env0 subset of env1) must not move any value that
    was already concrete under env0.
    """
    before = known_nodes(expr, env0)
    after = known_nodes(expr, env1)
    return all(after.get(k) == v for k, v in before.items())


# --- the unsound alternative, for the falsifier -----------------------------
def evaluate_guessing(expr, env):
    """NOT sound: guesses an unresolved hole as 0 -> fabricates a concrete answer
    where the honest engine would report a gap.
    """
    kind = expr[0]
    if kind == "lit":
        return expr[1]
    if kind == "hole":
        return env.get(expr[1], 0)  # the guess
    a = evaluate_guessing(expr[1], env)
    b = evaluate_guessing(expr[2], env)
    return {"add": a + b, "sub": a - b, "mul": a * b}[kind]
