#!/usr/bin/env python
"""Run the III Perfection Charter self-audit.

Exit code 0 iff every predicate HOLDS (its good case verifies AND its bad case
is correctly caught). The run is deterministic: we execute the whole audit twice
and confirm the content-address seal is byte-identical (Pi5/Pi12 in action).

Usage:  python run_audit.py
"""
import sys

from perfection_charter.charter import run_audit


def main():
    a = run_audit()
    b = run_audit()  # second pass -> the seal must match (determinism)

    print("=" * 72)
    print("  III PERFECTION CHARTER -- self-audit (proof of concept)")
    print("=" * 72)
    print("  Each predicate must VERIFY (good case holds) and be FALSIFIABLE")
    print("  (bad case is caught). HOLDS = verify AND falsify.")
    print("-" * 72)
    print("  %-5s %-38s %-7s %-8s %s" % ("ID", "PREDICATE", "VERIFY", "FALSIFY", "HOLDS"))
    print("-" * 72)
    for r in a["results"]:
        scope = "" if r["scope"] == "core" else "  (scoped)"
        print("  %-5s %-38s %-7s %-8s %s%s" % (
            r["id"],
            r["title"][:38],
            "PASS" if r["verify"] else "FAIL",
            "caught" if r["falsify"] else "MISSED",
            "YES" if r["holds"] else "NO",
            scope,
        ))
    print("-" * 72)
    held = sum(1 for r in a["results"] if r["holds"])
    total = len(a["results"])
    print("  predicates holding : %d / %d" % (held, total))
    print("  run-1 seal         : %s" % a["seal"])
    print("  run-2 seal         : %s" % b["seal"])
    deterministic = a["seal"] == b["seal"]
    print("  deterministic      : %s" % ("YES (seals identical)" if deterministic else "NO"))
    print("=" * 72)

    ok = a["all_hold"] and deterministic
    if ok:
        print("  RESULT: charter HOLDS -- all %d predicates verified and falsified," % total)
        print("          and the audit is reproducible. Baseline is self-consistent.")
    else:
        print("  RESULT: charter does NOT hold. Investigate the NO / FAIL / MISSED rows.")
    print("=" * 72)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
