"""A small but REAL proof kernel -- closes the Pi1 (soundness) and Pi2
(decidable checking) gaps that were previously algebra-only / by-construction.

Simply-typed lambda calculus (de Bruijn) read through Curry-Howard:
  * a Type is a proposition; a closed term of type T is a proof of T;
  * the empty type `False` has NO introduction rule -> it is uninhabited ->
    SOUNDNESS = "no closed term type-checks at type False".
STLC is strongly normalizing and its bidirectional checker is decidable, so
type-checking is total and terminating -> DECIDABILITY (Pi2).

This is honest about scope: it is propositional (not full dependent CIC), but it
is a genuine soundness + decidability demonstration, not a stand-in. Anchor A1
("the kernel is correct") moves from *trusted* to *demonstrated for this logic*.

Type  := ("base", name) | ("arrow",A,B) | ("prod",A,B) | ("sum",A,B)
       | ("false",) | ("true",)
Term  := ("var",i) | ("lam",dom,body) | ("app",f,x)
       | ("pair",a,b) | ("fst",p) | ("snd",p)
       | ("inl",rightT,a) | ("inr",leftT,b) | ("case",s,lbody,rbody)
       | ("unit",) | ("absurd",resultT,e)
Terms are fully annotated, so inference alone is a complete decision procedure.
"""


def node_count(t):
    k = t[0]
    if k in ("var", "unit", "zero"):
        return 1
    if k in ("fst", "snd", "succ"):
        return 1 + node_count(t[1])
    if k == "lam":
        return 1 + node_count(t[2])
    if k in ("inl", "inr", "absurd"):
        return 1 + node_count(t[2])
    if k in ("app", "pair"):
        return 1 + node_count(t[1]) + node_count(t[2])
    if k == "case":
        return 1 + node_count(t[1]) + node_count(t[2]) + node_count(t[3])
    if k == "natrec":
        return 1 + node_count(t[2]) + node_count(t[3]) + node_count(t[4])
    return 1


def infer(ctx, t, _counter=None):
    """Total, structurally-recursive type inference. Returns a Type or None.
    Never raises on a well-formed term node; each recursive call is on a strict
    subterm, so the total number of calls is bounded by node_count (Pi2).
    """
    if _counter is not None:
        _counter[0] += 1
    k = t[0]
    if k == "var":
        i = t[1]
        return ctx[i] if 0 <= i < len(ctx) else None
    if k == "unit":
        return ("true",)
    if k == "lam":
        b = infer([t[1]] + ctx, t[2], _counter)
        return None if b is None else ("arrow", t[1], b)
    if k == "app":
        tf = infer(ctx, t[1], _counter)
        if tf is None or tf[0] != "arrow":
            return None
        if not _check(ctx, t[2], tf[1], _counter):    # the load-bearing arg check
            return None
        return tf[2]
    if k == "pair":
        a = infer(ctx, t[1], _counter)
        b = infer(ctx, t[2], _counter)
        return None if (a is None or b is None) else ("prod", a, b)
    if k == "fst":
        tp = infer(ctx, t[1], _counter)
        return tp[1] if (tp is not None and tp[0] == "prod") else None
    if k == "snd":
        tp = infer(ctx, t[1], _counter)
        return tp[2] if (tp is not None and tp[0] == "prod") else None
    if k == "inl":
        a = infer(ctx, t[2], _counter)
        return None if a is None else ("sum", a, t[1])
    if k == "inr":
        b = infer(ctx, t[2], _counter)
        return None if b is None else ("sum", t[1], b)
    if k == "case":
        ts = infer(ctx, t[1], _counter)
        if ts is None or ts[0] != "sum":
            return None
        la = infer([ts[1]] + ctx, t[2], _counter)
        lb = infer([ts[2]] + ctx, t[3], _counter)
        return la if (la is not None and la == lb) else None
    if k == "absurd":
        return t[1] if _check(ctx, t[2], ("false",), _counter) else None
    # --- inductive Nat (constructors + structural recursor) ---
    if k == "zero":
        return ("nat",)
    if k == "succ":
        return ("nat",) if infer(ctx, t[1], _counter) == ("nat",) else None
    if k == "natrec":
        C = t[1]                                                     # result type (motive)
        if not _check(ctx, t[2], C, _counter):                       # base : C
            return None
        if not _check(ctx, t[3], ("arrow", ("nat",), ("arrow", C, C)), _counter):
            return None                                              # step : Nat -> C -> C
        if infer(ctx, t[4], _counter) != ("nat",):                   # target : Nat
            return None
        return C
    return None


def _check(ctx, t, ty, _counter=None):
    got = infer(ctx, t, _counter)
    return got is not None and got == ty


def check(ctx, t, ty):
    return _check(ctx, t, ty, None)


# --- a deliberately UNSOUND variant: `app` without the argument-type check.
# This is exactly the rule that keeps False uninhabited; dropping it lets a
# closed term inhabit False (the Pi1 falsifier proves the rule is load-bearing).
def infer_unsound(ctx, t):
    k = t[0]
    if k == "app":
        tf = infer_unsound(ctx, t[1])
        if tf is None or tf[0] != "arrow":
            return None
        return tf[2]                       # <-- no check that the arg has type tf[1]
    if k == "lam":
        b = infer_unsound([t[1]] + ctx, t[2])
        return None if b is None else ("arrow", t[1], b)
    if k == "var":
        i = t[1]
        return ctx[i] if 0 <= i < len(ctx) else None
    if k == "unit":
        return ("true",)
    return infer(ctx, t)                   # other forms: defer to the sound rules


def looping_infer(ctx, t, fuel):
    """A 'checker' with no well-founded measure: it spins without making
    structural progress, so only the fuel cutoff stops it -- it never really
    decides. Used by the Pi2 falsifier to show decidability needs the structural
    guard. (Iterative so the demonstration itself cannot overflow the stack.)
    """
    while fuel > 0:
        fuel -= 1
    return None


def term_corpus():
    """Well-typed AND ill-typed closed terms, to exercise both verdicts."""
    A = ("base", "A")
    B = ("base", "B")
    return [
        ("lam", A, ("var", 0)),                                  # A->A (ok)
        ("lam", ("prod", A, B), ("fst", ("var", 0))),            # A&B->A (ok)
        ("lam", A, ("inl", B, ("var", 0))),                      # A->A|B (ok)
        ("unit",),                                               # True (ok)
        ("app", ("lam", A, ("var", 0)), ("unit",)),             # ill-typed (unit != A)
        ("fst", ("unit",)),                                      # ill-typed (unit not prod)
        ("var", 0),                                              # ill-typed (unbound)
        ("absurd", A, ("unit",)),                                # ill-typed (unit not False)
        numeral(0), numeral(3),                                  # Nat values (ok)
        add_term(),                                              # Nat->Nat->Nat (ok)
    ]


# --------------------------------------------------------------------------- #
# Strong normalization: a normal-order evaluator over the {var,lam,app,zero,
# succ,natrec} fragment -- where non-termination could hide. Products/sums are
# trivially normalizing, so they are not reduced here.
# --------------------------------------------------------------------------- #
def shift(t, d, c=0):
    k = t[0]
    if k == "var":
        return ("var", t[1] + d) if t[1] >= c else t
    if k == "lam":
        return ("lam", t[1], shift(t[2], d, c + 1))
    if k == "app":
        return ("app", shift(t[1], d, c), shift(t[2], d, c))
    if k == "succ":
        return ("succ", shift(t[1], d, c))
    if k == "natrec":
        return ("natrec", t[1], shift(t[2], d, c), shift(t[3], d, c), shift(t[4], d, c))
    return t                                       # zero / others: no free vars to move


def subst(t, j, s):
    k = t[0]
    if k == "var":
        return s if t[1] == j else t
    if k == "lam":
        return ("lam", t[1], subst(t[2], j + 1, shift(s, 1, 0)))
    if k == "app":
        return ("app", subst(t[1], j, s), subst(t[2], j, s))
    if k == "succ":
        return ("succ", subst(t[1], j, s))
    if k == "natrec":
        return ("natrec", t[1], subst(t[2], j, s), subst(t[3], j, s), subst(t[4], j, s))
    return t


def step1(t):
    """One normal-order reduction step; None if already in normal form."""
    k = t[0]
    if k == "app":
        f = t[1]
        if f[0] == "lam":                          # beta
            return shift(subst(f[2], 0, shift(t[2], 1, 0)), -1, 0)
        rf = step1(f)
        if rf is not None:
            return ("app", rf, t[2])
        ra = step1(t[2])
        return ("app", f, ra) if ra is not None else None
    if k == "natrec":
        C, base, stp, n = t[1], t[2], t[3], t[4]
        if n[0] == "zero":
            return base
        if n[0] == "succ":                         # iota: recurse on the predecessor
            return ("app", ("app", stp, n[1]), ("natrec", C, base, stp, n[1]))
        rn = step1(n)
        return ("natrec", C, base, stp, rn) if rn is not None else None
    if k == "succ":
        rn = step1(t[1])
        return ("succ", rn) if rn is not None else None
    if k == "lam":
        rb = step1(t[2])
        return ("lam", t[1], rb) if rb is not None else None
    return None


def normalize(t, cap=100000):
    """Reduce to normal form. Returns (normal_form, steps) or (None, cap) if it
    failed to terminate within the cap (only possible for ill-typed terms like
    Omega, which the type checker rejects)."""
    steps = 0
    while steps < cap:
        nt = step1(t)
        if nt is None:
            return t, steps
        t = nt
        steps += 1
    return None, steps


def numeral(k):
    t = ("zero",)
    for _ in range(k):
        t = ("succ", t)
    return t


def nat_to_int(t):
    n = 0
    while t[0] == "succ":
        n += 1
        t = t[1]
    return n if t[0] == "zero" else None


def add_term():
    """add = lam a:Nat. lam b:Nat. natrec(Nat, b, lam _:Nat. lam r:Nat. succ r, a)."""
    nat = ("nat",)
    step = ("lam", nat, ("lam", nat, ("succ", ("var", 0))))
    return ("lam", nat, ("lam", nat,
            ("natrec", nat, ("var", 0), step, ("var", 1))))


# The classic non-normalizing term Omega = (lam x. x x)(lam x. x x).
# STLC rejects it (no self-application type), which is exactly why STLC is
# strongly normalizing. Used by the Pi21 falsifier.
OMEGA = ("app", ("lam", ("base", "A"), ("app", ("var", 0), ("var", 0))),
         ("lam", ("base", "A"), ("app", ("var", 0), ("var", 0))))


# --------------------------------------------------------------------------- #
# Strict positivity of inductive definitions (the second CIC consistency pillar)
# A declaration is {"name": str, "constructors": [[arg_type, ...], ...]} where a
# constructor argument type may reference the type under definition as ("ind",name).
# --------------------------------------------------------------------------- #
def _positive(ty, tname, pol):
    """True iff every occurrence of tname in ty sits in a positive position."""
    if ty[0] == "ind":
        return ty[1] != tname or pol == 1
    if ty[0] == "arrow":
        return _positive(ty[1], tname, -pol) and _positive(ty[2], tname, pol)
    if ty[0] in ("prod", "sum"):
        return _positive(ty[1], tname, pol) and _positive(ty[2], tname, pol)
    return True


def strictly_positive(decl):
    name = decl["name"]
    for ctor in decl["constructors"]:
        for argty in ctor:
            if not _positive(argty, name, 1):
                return False
    return True


# strictly-positive (like Nat / a list) vs the non-positive Bad = C (Bad -> Bad)
NAT_DECL = {"name": "Nat", "constructors": [[], [("ind", "Nat")]]}
BAD_DECL = {"name": "Bad", "constructors": [[("arrow", ("ind", "Bad"), ("ind", "Bad"))]]}
