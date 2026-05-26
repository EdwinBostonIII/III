#!/usr/bin/env python
"""Mutation self-test for the extension predicates (Pi15-Pi19).

Corrupt the substrate behind each capability and require the extended audit to
go red for exactly that predicate, then confirm GREEN + reproducible quine-seal
after restore. In-memory monkeypatch only -- source files untouched.
"""
import sys

from perfection_charter import charter_ext as X
from perfection_charter import negknow as nk
from perfection_charter import holes as H
from perfection_charter import forgetting as F
from perfection_charter import quineseal as Q
from perfection_charter import sovval as SV


def _holds(rep, pid):
    for r in rep["combined"]:
        if r["id"] == pid:
            return r["holds"]
    return None


def _expect_red(label, pid, fails):
    r = X.run_ext_audit()
    if r["all_hold"] or _holds(r, pid):
        fails.append(label)


def run():
    base = X.run_ext_audit()
    if not base["all_hold"]:
        return ["baseline extended audit must hold before mutation testing"]
    fails = []

    # Pi15: ignorance must explain itself -> break well_formed
    o = nk.well_formed
    nk.well_formed = lambda g: True
    _expect_red("Pi15 not caught (well_formed corrupted)", "Pi15", fails)
    nk.well_formed = o

    # Pi16: make partial evaluation GUESS holes -> a Known partial now disagrees
    # with the full resolution, breaking soundness-of-partial.
    o = H.evaluate_partial
    _guess = H.evaluate_guessing
    H.evaluate_partial = lambda e, env: nk.Known(_guess(e, env))
    _expect_red("Pi16 not caught (partial eval made unsound/guessing)", "Pi16", fails)
    H.evaluate_partial = o

    # Pi17: redaction writes a silent 0 instead of a typed gap
    o = F.redact
    F.redact = lambda chain, k, reason: F._reseal(chain, k, nk.Known(0))
    _expect_red("Pi17 not caught (redaction made silent)", "Pi17", fails)
    F.redact = o

    # Pi18: behavioral fixpoint always accepts
    o = Q.verify_fixpoint
    Q.verify_fixpoint = lambda *a, **k: True
    _expect_red("Pi18 not caught (fixpoint check corrupted)", "Pi18", fails)
    Q.verify_fixpoint = o

    # Pi19: drop the representability guard -> bricking compositions slip through
    o = SV.is_representable
    SV.is_representable = lambda h: True
    _expect_red("Pi19 not caught (representability guard removed)", "Pi19", fails)
    SV.is_representable = o

    # restore -> GREEN, base intact, quine-seal reproducible
    restored = X.run_ext_audit()
    if not restored["all_hold"]:
        fails.append("extended audit did not return to all-hold after restore")
    if not restored["base_unchanged"]:
        fails.append("base seal drifted after restore")
    if restored["qseal"] != base["qseal"]:
        fails.append("quine-seal not reproducible after restore")
    return fails


if __name__ == "__main__":
    fails = run()
    print("=" * 60)
    if fails:
        print("EXTENSION MUTATION SELF-TEST: FAIL")
        for f in fails:
            print("  - " + f)
        print("=" * 60)
        sys.exit(1)
    print("EXTENSION MUTATION SELF-TEST: PASS")
    print("  audit went RED for all 5 injected corruptions (Pi15-Pi19),")
    print("  GREEN again after restore with identical quine-seal.")
    print("=" * 60)
    sys.exit(0)
