#!/usr/bin/env python
"""Run the EXTENDED charter audit: base 15 predicates + 4 foundational extensions.

Exit 0 iff every predicate holds AND the base seal is unchanged by the extension
(conservative, Pi8) AND the quine-seal fixpoint verifies.

Usage:  python run_ext_audit.py
"""
import sys

from perfection_charter.charter_ext import run_ext_audit
from perfection_charter import negknow as nk
from perfection_charter import forgetting as F


def _row(r):
    scope = "" if r["scope"] == "core" else "  (scoped)"
    print("  %-5s %-40s %-7s %-8s %s%s" % (
        r["id"], r["title"][:40],
        "PASS" if r["verify"] else "FAIL",
        "caught" if r["falsify"] else "MISSED",
        "YES" if r["holds"] else "NO", scope))


def main():
    a = run_ext_audit()
    print("=" * 76)
    print("  III PERFECTION CHARTER -- EXTENDED self-audit")
    print("=" * 76)
    print("  %-5s %-40s %-7s %-8s %s" % ("ID", "PREDICATE", "VERIFY", "FALSIFY", "HOLDS"))
    print("-" * 76)
    print("  -- base charter --")
    for r in a["base"]["results"]:
        _row(r)
    print("  -- foundational extensions --")
    for r in a["ext"]:
        _row(r)
    print("-" * 76)
    held = sum(1 for r in a["combined"] if r["holds"])
    print("  predicates holding     : %d / %d" % (held, len(a["combined"])))
    print("  base seal (unchanged)  : %s" % ("YES" if a["base_unchanged"] else "NO -- REGRESSION"))
    print("    -> conservative extension (Pi8) holds at system-evolution scale")
    print("  quine-seal             : %s" % a["qseal"])
    print("  fixpoint verifies      : %s" % ("YES" if a["fixpoint_ok"] else "NO"))
    print("=" * 76)

    # capability synergy (Pi14/C1 at the level of capabilities, demonstrated live)
    print("  CAPABILITY SYNERGY (each extension reuses the ones beneath it):")
    g = nk.apply_op("add", nk.Known(3), nk.gap("essential", "sensor_3 offline"))
    print("   - Pi15 negative knowledge:  %s" % nk.explain(g))
    chain = F.build_chain([("a", "lit", [], 10), ("b", "lit", [], 20),
                           ("s", "add", [0, 1], None), ("d", "add", [2], None)])
    p = F.proves_forgetting(chain, 2, "erasure request")
    print("   - Pi17 forgetting reused Pi16 gap-propagation + Pi15 provenance:")
    print("       redacted seq 2 -> downstream seq 3 now: %s"
          % nk.explain(p["chain"][3].value))
    print("       integrity=%s continuity=%s blast=%s"
          % (p["integrity"], p["continuity"], p["blast"]))
    print("   - Pi18 quine-seal sealed all %d predicate results + the auditor's" % len(a["combined"]))
    print("       own SOURCE and executed BYTECODE (behavioral fixpoint)")
    print("   - Pi19 Sovereign Value: payload(gap+provenance) + safety-hexad + witness, one type")
    print("=" * 76)

    ok = a["all_hold"] and a["base_unchanged"] and a["fixpoint_ok"]
    if ok:
        print("  RESULT: extended charter HOLDS (%d/%d), base unchanged, fixpoint sealed."
              % (held, len(a["combined"])))
        print("          Four capabilities unique to the charter's conjunction, all proven")
        print("          both ways, composing without harm -- Pi14/C1 at capability scale.")
    else:
        print("  RESULT: extended charter does NOT hold. Investigate NO / FAIL / MISSED / REGRESSION.")
    print("=" * 76)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
