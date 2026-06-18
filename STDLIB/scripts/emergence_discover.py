#!/usr/bin/env python3
"""emergence_discover.py -- the DISCOVER stage of the Emergence Forge.

III's "what have I built but not yet used ON MYSELF" radar.

The substrate has paid for an enormous amount of capability.  The leanest way to make
III drastically smarter is NOT to add new islands -- it is to find capability that ALREADY
EXISTS but is not yet wired into an organ that acts, and fold it in (the omnia/self_atlas ->
ripple_extract C3 compound, W1, was exactly this: a complete self-model that no generative
organ consulted).  This script is the engine that finds the NEXT such seam.

For every @export'd faculty in STDLIB/iii it counts the faculty's MODULE consumers (other
modules that `extern ... fn NAME ... from "M.iii"` it).  An export with zero module-consumers
is an INERT capability: built, sealed, tested by its corpus -- but load-bearing on NOTHING.
Inert organs are ranked by the organ's self-model BLAST RADIUS (omnia/self_atlas impact), so
the highest-leverage seam surfaces first.  Oracle-shaped exports (predicates a generative organ
would consult -- *_reaches / *_safe / *_would_* / *_steepest / ...) are flagged: an inert
oracle is the richest vein (it is self-knowledge nothing yet acts on).

ADVISORY, like the lens's redundant-dependency proposals: an export consumed only by corpus
tests or reached only through runtime dispatch/resolver indirection LOOKS inert but is not --
the agent adjudicates each candidate before wiring it.  The point is to rank the search, not
to auto-edit.

Pure read-only analysis of III's own source + self-model.  Reuses gen_self_atlas's graph
authority (identical nodes / edges / impact), so the radar can never diverge from the map.

Run:  python STDLIB/scripts/emergence_discover.py            # top inert organs
      python STDLIB/scripts/emergence_discover.py --all      # full census
      python STDLIB/scripts/emergence_discover.py --oracles  # inert ORACLES only
"""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_self_atlas as G

# fn NAME ( ... ) ... @export   (params/return may span lines; @export precedes the body brace)
EXPORT_RE = re.compile(r'\bfn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\([^)]*\)[^{]*?@export')
# extern ... fn NAME ... from "TARGET.iii"   (the consumer edge, per-faculty).
# DOTALL + lazy gaps so MULTI-LINE externs (params spanning lines, e.g. commit_gate's
# pleroma_cohere) match too -- else their target is falsely flagged inert.
EXTERN_RE = re.compile(r'\bextern\b.*?\bfn\s+([A-Za-z_][A-Za-z0-9_]*)\b.*?\bfrom\s+"([^"]+)\.iii"', re.DOTALL)

# oracle-shaped export-name fragments: a predicate/measure a generative organ would CONSULT.
ORACLE_HINTS = ("reach", "impact", "safe", "cycle", "would", "steepest", "potential", "rank",
                "score", "level", "depends", "dominate", "blast", "hub", "redundant", "acyclic",
                "closes", "certify", "admit", "decide", "verdict", "cohere", "improves", "valid")

# corpus/KAT entrypoints look inert (no MODULE consumer) but are NOT seams -- they are test harness.
TEST_SUFFIXES = ("_selftest", "_kat", "_test", "_probe", "_diag", "_bench", "_falsifier")
def _is_test_fn(fn):
    low = fn.lower()
    return low.startswith("test_") or any(low.endswith(s) for s in TEST_SUFFIXES) or "_kat_" in low


def module_paths():
    paths = {}
    for dp, _d, fns in os.walk(G.SRC):
        for fn in fns:
            if fn.endswith(".iii"):
                base = fn[:-4]
                if base in getattr(G, "EXCLUDE_BASENAMES", set()):
                    continue
                paths.setdefault(base, os.path.join(dp, fn))
    return paths


def census():
    nodes, edges = G.collect()
    M = G.analyze(nodes, edges)
    idx = {n: i for i, n in enumerate(M["node_names"])}
    impact = M["impact"]
    paths = module_paths()

    exports = {}                 # module -> sorted list of @export fn names
    consumers = {}               # (target_module, fn) -> set(consumer modules)
    for base, p in sorted(paths.items()):
        try:
            text = open(p, "r", encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        exports[base] = sorted(set(EXPORT_RE.findall(text)))
        for fn, tgt in EXTERN_RE.findall(text):
            consumers.setdefault((tgt, fn), set()).add(base)

    rows = []
    for base, exps in exports.items():
        if not exps:
            continue
        inert = [fn for fn in exps
                 if not _is_test_fn(fn)
                 and len(consumers.get((base, fn), set()) - {base}) == 0]
        if not inert:
            continue
        i = idx.get(base)
        imp = impact[i] if i is not None else 0
        oracles = [fn for fn in inert if any(h in fn.lower() for h in ORACLE_HINTS)]
        rows.append({"module": base, "impact": imp, "n_export": len(exps),
                     "inert": inert, "oracles": oracles})
    # rank: an inert ORACLE on a high-blast-radius organ is the richest seam.
    rows.sort(key=lambda r: (-(len(r["oracles"]) > 0), -r["impact"], -len(r["inert"]), r["module"]))
    return rows, M


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    rows, M = census()
    total_inert = sum(len(r["inert"]) for r in rows)
    print("=" * 78)
    print("III EMERGENCE DISCOVER  --  inert capability radar (built but unwired)")
    print("=" * 78)
    print("self-model ........ %d nodes / %d edges   emergence index %d"
          % (len(M["node_names"]), len(M["edges"]), M["emergence"]))
    print("inert exports ..... %d across %d organs   (advisory: corpus-only / dispatch-"
          % (total_inert, len(rows)))
    print("                    indirect exports look inert but are not -- agent adjudicates)")
    print("-" * 78)
    if mode == "--oracles":
        rows = [r for r in rows if r["oracles"]]
        print("INERT ORACLES (self-knowledge nothing generative yet consults -- the W1 vein):")
    else:
        print("STEEPEST INERT ORGANS (rank by blast-radius; * = exports an inert ORACLE):")
    shown = rows if mode == "--all" else rows[:25]
    for r in shown:
        star = "*" if r["oracles"] else " "
        head = r["oracles"][:6] if r["oracles"] else r["inert"][:6]
        more = ("  (+%d more)" % (len(r["inert"]) - len(head))) if len(r["inert"]) > len(head) else ""
        print("  %s impact %4d  %-26s  %s%s" % (star, r["impact"], r["module"], ", ".join(head), more))
    print("=" * 78)
    return 0


if __name__ == "__main__":
    sys.exit(main())
