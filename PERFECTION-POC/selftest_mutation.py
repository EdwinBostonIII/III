#!/usr/bin/env python
"""Mutation self-test for the base charter -- proves it DISCRIMINATES.

Corrupt the substrate behind each predicate and require the audit to go red for
exactly that predicate, then confirm GREEN + identical seal after restore. Covers
the real kernel soundness (Pi1), decidability (Pi2), hand-rolled hash (Pi20), and
the de-faked Pi4/Pi5/Pi6, alongside REP/Pi9.
"""
import sys

from perfection_charter import charter, hexad, trit
from perfection_charter import reversible as rev
from perfection_charter import rewrite as RW
from perfection_charter import kernel
from perfection_charter import sha256_nih


def _holds(rep, pid):
    for r in rep["results"]:
        if r["id"] == pid:
            return r["holds"]
    return None


def _expect_red(label, pid, fails):
    r = charter.run_audit()
    if r["all_hold"] or _holds(r, pid):
        fails.append(label)


def run():
    base = charter.run_audit()
    if not base["all_hold"]:
        return ["baseline must hold before mutation testing"]
    fails = []

    # Pi1 (soundness): a checker that accepts anything inhabits False
    o = kernel.check
    kernel.check = lambda ctx, t, ty: True
    _expect_red("Pi1 not caught (kernel.check accepts everything)", "Pi1", fails)
    kernel.check = o

    # Pi2 (decidability): break the structural termination bound
    o = kernel.node_count
    kernel.node_count = lambda t: 0
    _expect_red("Pi2 not caught (termination bound broken)", "Pi2", fails)
    kernel.node_count = o

    # Pi21 (strong normalization): the normalizer never reaches a normal form
    o = kernel.normalize
    kernel.normalize = lambda t, cap=100000: (None, cap)
    _expect_red("Pi21 not caught (normalizer corrupted)", "Pi21", fails)
    kernel.normalize = o

    # Pi22 (positivity): accept a non-positive inductive (would break SN)
    o = kernel.strictly_positive
    kernel.strictly_positive = lambda d: True
    _expect_red("Pi22 not caught (positivity check corrupted)", "Pi22", fails)
    kernel.strictly_positive = o

    # REP: every hexad 'representable' -> bricking ops slip through
    o = hexad.is_representable
    hexad.is_representable = lambda h: True
    _expect_red("REP not caught (is_representable corrupted)", "REP", fails)
    hexad.is_representable = o

    # Pi4: normalizer reports non-termination
    o = RW.normalizes
    RW.normalizes = lambda e, cap=100000: (False, True)
    _expect_red("Pi4 not caught (normalizes corrupted)", "Pi4", fails)
    RW.normalizes = o

    # Pi5: aggregation made order-dependent
    o = charter._nf_seal
    charter._nf_seal = lambda corpus, sort: charter.mhash(
        [charter.rewrite.normalize_left(e, []) for e in corpus])
    _expect_red("Pi5 not caught (aggregation order-dependent)", "Pi5", fails)
    charter._nf_seal = o

    # Pi6: one 'independent' impl made buggy
    o = charter._poly_powers
    charter._poly_powers = charter._poly_buggy
    _expect_red("Pi6 not caught (independent impl corrupted)", "Pi6", fails)
    charter._poly_powers = o

    # Pi9: round-trip always passes
    o = rev.cycle_round_trips
    rev.cycle_round_trips = lambda s, ops: True
    _expect_red("Pi9 not caught (round-trip corrupted)", "Pi9", fails)
    rev.cycle_round_trips = o

    # Pi20: hand-rolled hash silently broken
    o = sha256_nih.hexdigest
    sha256_nih.hexdigest = sha256_nih.hexdigest_buggy
    _expect_red("Pi20 not caught (hand-rolled hash corrupted)", "Pi20", fails)
    sha256_nih.hexdigest = o

    # restore -> GREEN, identical seal
    restored = charter.run_audit()
    if not restored["all_hold"]:
        fails.append("did not return to all-hold after restore")
    if restored["seal"] != base["seal"]:
        fails.append("seal drifted after restore")
    return fails


if __name__ == "__main__":
    fails = run()
    print("=" * 60)
    if fails:
        print("MUTATION SELF-TEST: FAIL")
        for f in fails:
            print("  - " + f)
        print("=" * 60)
        sys.exit(1)
    print("MUTATION SELF-TEST: PASS")
    print("  audit went RED for all 10 injected corruptions (Pi1, Pi2, Pi21,")
    print("  Pi22, REP, Pi4, Pi5, Pi6, Pi9, Pi20), GREEN again w/ identical seal.")
    print("=" * 60)
    sys.exit(0)
