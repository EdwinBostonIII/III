"""Confluence (Pi3) and strong normalization (Pi4).

The confluent system normalizes additive expressions over integer literals and
variables to a canonical sum. We reduce each term by TWO genuinely different
orders (left-subtree-first vs right-subtree-first) and require: identical normal
form, but DIFFERENT visit traces -- so the confluence check cannot be passing by
reducing the same way twice (the anti-tautology requirement).

Pi4: the normalizer is structurally recursive over a finite tree, so it always
terminates. The falsifier feeds a looping abstract rewrite system to a
bounded-step driver, which must report non-termination.
"""
from .mhash import mhash

# Expr := ("lit", int) | ("var", str) | ("add", Expr, Expr)


def _merge(nf_a, nf_b):
    const = nf_a["const"] + nf_b["const"]
    varc = dict(nf_a["vars"])
    for k, c in nf_b["vars"].items():
        varc[k] = varc.get(k, 0) + c
    varc = {k: v for k, v in varc.items() if v != 0}
    return {"const": const, "vars": varc}


def _leaf_nf(expr):
    if expr[0] == "lit":
        return {"const": expr[1], "vars": {}}
    if expr[0] == "var":
        return {"const": 0, "vars": {expr[1]: 1}}
    return None


def normalize_left(expr, trace):
    """Reduce left subtree fully before right."""
    leaf = _leaf_nf(expr)
    if leaf is not None:
        trace.append(("leaf", expr))
        return leaf
    left = normalize_left(expr[1], trace)
    right = normalize_left(expr[2], trace)
    trace.append(("merge", "L"))
    return _merge(left, right)


def normalize_right(expr, trace):
    """Reduce right subtree fully before left (different order)."""
    leaf = _leaf_nf(expr)
    if leaf is not None:
        trace.append(("leaf", expr))
        return leaf
    right = normalize_right(expr[2], trace)
    left = normalize_right(expr[1], trace)
    trace.append(("merge", "R"))
    return _merge(left, right)


def confluent_on(expr):
    """Returns (same_normal_form, traces_differed) for one expression."""
    tl, tr = [], []
    nf_l = normalize_left(expr, tl)
    nf_r = normalize_right(expr, tr)
    same_nf = mhash(nf_l) == mhash(nf_r)
    traces_differed = mhash(tl) != mhash(tr)
    return same_nf, traces_differed


# --- strong normalization on the REAL expression algebra (Pi4) --------------
def node_count(expr):
    if expr[0] in ("lit", "var"):
        return 1
    return 1 + node_count(expr[1]) + node_count(expr[2])


def reduce_step(expr):
    """One small-step rewrite: fold a constant op, else descend leftmost. Returns
    a strictly smaller term, or None if already normal. Each fold removes an op
    node and two literal leaves, replacing them with one literal (-2 nodes).
    """
    if expr[0] in ("lit", "var"):
        return None
    op = expr[0]
    l, r = expr[1], expr[2]
    if l[0] == "lit" and r[0] == "lit":
        folded = {"add": l[1] + r[1], "sub": l[1] - r[1], "mul": l[1] * r[1]}[op]
        return ("lit", folded)
    nl = reduce_step(l)
    if nl is not None:
        return (op, nl, r)
    nr = reduce_step(r)
    if nr is not None:
        return (op, l, nr)
    return None


def normalizes(expr, cap=100000):
    """Drive reduce_step to a fixpoint. Returns (terminated, measure_decreasing):
    a genuine strong-normalization check on the real algebra with a well-founded
    measure (node_count strictly decreases on every step).
    """
    cur = expr
    m = node_count(cur)
    steps = 0
    decreasing = True
    while True:
        nxt = reduce_step(cur)
        if nxt is None:
            return True, decreasing
        nm = node_count(nxt)
        if nm >= m:
            decreasing = False
        cur, m = nxt, nm
        steps += 1
        if steps > cap:
            return False, decreasing


def runs_to_fixpoint(step, start, cap=2000):
    """Bounded driver for an arbitrary rewrite step (used by the Pi4 falsifier on
    a deliberately non-terminating rule).
    """
    cur = start
    for _ in range(cap):
        nxt = step(cur)
        if nxt is None or nxt == cur:
            return True
        cur = nxt
    return False


# --- generic abstract rewrite system (for the falsifiers) -------------------
def ars_normal_forms(start, rules, step_cap=1000):
    """Explore every distinct outcome of applying `rules` (a dict term->list of
    successors) until no rule applies or the step cap is hit.

    Returns (set_of_normal_forms, terminated). Used to expose non-confluence
    (more than one normal form) and non-termination (cap hit).
    """
    seen = set()
    normal_forms = set()
    frontier = [start]
    steps = 0
    while frontier:
        steps += 1
        if steps > step_cap:
            return normal_forms, False  # did not terminate
        term = frontier.pop()
        if term in seen:
            continue
        seen.add(term)
        succ = rules.get(term, [])
        if not succ:
            normal_forms.add(term)
        else:
            frontier.extend(succ)
    return normal_forms, True
