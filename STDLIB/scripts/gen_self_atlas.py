#!/usr/bin/env python3
"""gen_self_atlas.py -- emit omnia/self_atlas_data.iii + the emergence dashboard.

III-CARTOGRAPHER's core, brought INSIDE III's toolchain.  Walks STDLIB/iii's source, extracts
the module-dependency graph from each module's `extern ... from "X.iii"` edges, and emits:

  1. omnia/self_atlas_data.iii  -- the generated organ that loads III's OWN graph into
     omnia/self_atlas at runtime (so the generative organs query III's ACTUAL structure), PLUS
     satlas_data_expect_*() functions carrying the lens signals computed here in Python.  The
     corpus cross-check (1669) asserts the in-III lens reproduces these EXACTLY -- so this
     renderer can never silently diverge from the .iii authority.

  2. _emergence_report.txt  -- the human/agent dashboard: coupling, the steepest hub, the most
     depended-upon module, the cycle cores, orphans, and the ranked redundant-dependency
     refactor proposals (advisory; III never edits its own source blind).

Nodes = STDLIB/iii module basenames; edges = `from "X.iii"` deps within the stdlib self-closure.
Node ids are assigned in SORTED basename order, so the self-model -- and self_atlas's content
commitment over it -- is canonical (a pure function of the source, not of walk order).

The Python graph analysis MIRRORS self_atlas's exact semantics (reachability via paths of
length >= 1; a node is in a cycle iff it reaches itself), and is pinned equal to the .iii lens
by corpus 1669 -- so it is a verified render of the authority, not an independent island.
"""
import os, re
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # STDLIB/
SRC  = os.path.join(ROOT, "iii")
OUT  = os.path.join(SRC, "omnia", "self_atlas_data.iii")
REPORT = os.path.join(os.path.dirname(ROOT), "_emergence_report.txt")  # III repo root

EXCLUDE_BASENAMES = {"self_atlas_data"}
FROM_RE = re.compile(r'from\s+"([^"]+)\.iii"')


def collect():
    nodes = {}
    files = []
    for dirpath, _dirs, filenames in os.walk(SRC):
        for fn in filenames:
            if not fn.endswith(".iii"):
                continue
            base = fn[:-4]
            if base in EXCLUDE_BASENAMES:
                continue
            files.append((base, os.path.join(dirpath, fn)))
            nodes.setdefault(base, os.path.join(dirpath, fn))
    edges = set()
    for base, full in files:
        try:
            with open(full, "r", encoding="utf-8", errors="replace") as f:
                text = f.read()
        except OSError:
            continue
        for m in FROM_RE.finditer(text):
            tgt = m.group(1)
            if tgt != base and tgt in nodes:
                edges.add((base, tgt))
    return sorted(nodes.keys()), sorted(edges)


def _bfs(adj, start, ban=None):
    """Nodes reachable from start via a path of length >= 1 (start included only on a cycle).
    Mirrors self_atlas's BFS exactly.  ban = a single directed edge (u,v) to exclude."""
    seen = set()
    q = deque([start])
    while q:
        cur = q.popleft()
        for nb in adj.get(cur, ()):
            if ban is not None and cur == ban[0] and nb == ban[1]:
                continue
            if nb not in seen:
                seen.add(nb)
                q.append(nb)
    return seen


def analyze(node_names, edges):
    idx = {n: i for i, n in enumerate(node_names)}
    N = len(node_names)
    out_adj = {i: [] for i in range(N)}
    in_adj = {i: [] for i in range(N)}
    eids = []
    for a, b in edges:
        ia, ib = idx[a], idx[b]
        out_adj[ia].append(ib)
        in_adj[ib].append(ia)
        eids.append((ia, ib))
    fanin = [len(in_adj[i]) for i in range(N)]
    fanout = [len(out_adj[i]) for i in range(N)]

    in_cycle = [i in _bfs(out_adj, i) for i in range(N)]
    impact = [len(_bfs(in_adj, i) - {i}) for i in range(N)]
    depends = [len(_bfs(out_adj, i) - {i}) for i in range(N)]

    redundant = []
    for (a, b) in eids:
        if b in _bfs(out_adj, a, ban=(a, b)):
            redundant.append((a, b))

    orphans = [i for i in range(N) if fanin[i] == 0 and fanout[i] == 0]
    roots = [i for i in range(N) if fanin[i] == 0]
    leaves = [i for i in range(N) if fanout[i] == 0]
    cycle_nodes = [i for i in range(N) if in_cycle[i]]
    coupling = (len(edges) * 1000) // N if N else 0
    max_fanin = max(fanin) if fanin else 0
    argmax_fanin = fanin.index(max_fanin) if fanin else 0xFFFFFFFF
    top_hub_impact = max(impact) if impact else 0
    top_hub = impact.index(top_hub_impact) if impact else 0xFFFFFFFF

    return {
        "node_names": node_names, "edges": eids,
        "fanin": fanin, "fanout": fanout, "impact": impact,
        "redundant": redundant, "orphans": orphans, "roots": roots,
        "leaves": leaves, "cycle_nodes": cycle_nodes, "coupling": coupling,
        "max_fanin": max_fanin, "argmax_fanin": argmax_fanin,
        "top_hub": top_hub, "top_hub_impact": top_hub_impact,
        "emergence": (sum(impact) * 1000) // len(edges) if edges else 0,
        "max_depends": max(depends) if depends else 0,
        "argmax_depends": depends.index(max(depends)) if depends else 0xFFFFFFFF,
    }


def _chunked(lines, size):
    for i in range(0, len(lines), size):
        yield lines[i:i + size]


def emit(M):
    node_names, edges = M["node_names"], M["edges"]
    name_lines = ['    satlas_intern("%s", %du64)' % (n, len(n)) for n in node_names]
    edge_lines = ['    satlas_link("%s", %du64, "%s", %du64)'
                  % (node_names[a], len(node_names[a]), node_names[b], len(node_names[b]))
                  for (a, b) in edges]

    P = []
    P.append('/* C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III\\STDLIB\\iii\\omnia\\self_atlas_data.iii')
    P.append(' *')
    P.append(' * GENERATED by STDLIB/scripts/gen_self_atlas.py -- DO NOT EDIT BY HAND.')
    P.append(' *')
    P.append(' * III\'s own module-dependency graph (the cartographer brought INSIDE III), loaded into')
    P.append(' * omnia::self_atlas so the generative organs can query III\'s ACTUAL structure.  Carries')
    P.append(' * the lens signals computed at generation time as satlas_data_expect_*(); corpus 1669')
    P.append(' * asserts the in-III lens reproduces them exactly (renderer pinned to the authority).')
    P.append(' *')
    P.append(' * %d nodes, %d edges.  Regenerate: python STDLIB/scripts/gen_self_atlas.py' % (len(node_names), len(edges)))
    P.append(' *')
    P.append(' * Hexad: kind_essence (a faithful self-image).  Ring: R0.  K: 1.00.  NIH: self_atlas only.')
    P.append(' * Discipline: W2 (<=4 params), W13 (0 locals), W14/W15 (straight-line calls, no loops). */')
    P.append('')
    P.append('module omnia_self_atlas_data')
    P.append('')
    P.append('extern @abi(c-msvc-x64) fn satlas_reset() -> i32 from "self_atlas.iii"')
    P.append('extern @abi(c-msvc-x64) fn satlas_intern(name_ptr: u64, len: u64) -> u32 from "self_atlas.iii"')
    P.append('extern @abi(c-msvc-x64) fn satlas_link(fp: u64, fl: u64, tp: u64, tl: u64) -> i32 from "self_atlas.iii"')
    P.append('')

    node_helpers = []
    for k, group in enumerate(_chunked(name_lines, 240)):
        nm = "satlas_data_nodes_%d" % k
        node_helpers.append(nm)
        P.append('fn %s() -> i32 {' % nm); P.extend(group); P.append('    return 0i32'); P.append('}'); P.append('')
    edge_helpers = []
    for k, group in enumerate(_chunked(edge_lines, 240)):
        nm = "satlas_data_edges_%d" % k
        edge_helpers.append(nm)
        P.append('fn %s() -> i32 {' % nm); P.extend(group); P.append('    return 0i32'); P.append('}'); P.append('')

    P.append('/* Load III\'s module-dependency self-model.  Idempotent (resets first). */')
    P.append('fn satlas_data_load() -> i32 @export {')
    P.append('    satlas_reset()')
    for h in node_helpers:
        P.append('    %s()' % h)
    for h in edge_helpers:
        P.append('    %s()' % h)
    P.append('    return 0i32')
    P.append('}')
    P.append('')
    P.append('fn satlas_data_node_count() -> u32 @export { return %du32 }' % len(node_names))
    P.append('fn satlas_data_edge_count() -> u32 @export { return %du32 }' % len(edges))
    P.append('')
    P.append('/* Lens signals computed at generation time -- corpus 1669 pins the in-III lens to these. */')
    P.append('fn satlas_data_expect_coupling()      -> u32 @export { return %du32 }' % M["coupling"])
    P.append('fn satlas_data_expect_orphans()       -> u32 @export { return %du32 }' % len(M["orphans"]))
    P.append('fn satlas_data_expect_roots()         -> u32 @export { return %du32 }' % len(M["roots"]))
    P.append('fn satlas_data_expect_leaves()        -> u32 @export { return %du32 }' % len(M["leaves"]))
    P.append('fn satlas_data_expect_cycle_nodes()   -> u32 @export { return %du32 }' % len(M["cycle_nodes"]))
    P.append('fn satlas_data_expect_redundant()     -> u32 @export { return %du32 }' % len(M["redundant"]))
    P.append('fn satlas_data_expect_max_fanin()     -> u32 @export { return %du32 }' % M["max_fanin"])
    P.append('fn satlas_data_expect_top_hub_impact() -> u32 @export { return %du32 }' % M["top_hub_impact"])
    P.append('fn satlas_data_expect_emergence()     -> u32 @export { return %du32 }' % M["emergence"])
    P.append('fn satlas_data_expect_max_depends()   -> u32 @export { return %du32 }' % M["max_depends"])
    P.append('')

    with open(OUT, "w", encoding="ascii", newline="\n") as f:
        f.write("\n".join(P))


def write_report(M):
    nn = M["node_names"]
    def nm(i):
        return nn[i] if 0 <= i < len(nn) else "<none>"
    R = []
    R.append("=" * 78)
    R.append("III EMERGENCE DASHBOARD  --  self-model of STDLIB/iii (generated, verified)")
    R.append("=" * 78)
    R.append("nodes ............. %d" % len(nn))
    R.append("edges ............. %d" % len(M["edges"]))
    R.append("coupling .......... %d  (avg out-degree x1000)" % M["coupling"])
    R.append("emergence index ... %d  (sum of blast-radii / edges x1000 -- the C-A-B leftover:" % M["emergence"])
    R.append("                       transitive consequence the wiring carries beyond its edges)")
    R.append("")
    R.append("STEEPEST HUB (largest blast radius -- changing it ripples furthest):")
    R.append("    %s  (impact %d)" % (nm(M["top_hub"]), M["top_hub_impact"]))
    R.append("MOST DEPENDED-UPON (largest direct fan-in):")
    R.append("    %s  (fan-in %d)" % (nm(M["argmax_fanin"]), M["max_fanin"]))
    R.append("DEEPEST INTEGRATOR (transitively uses the most of III -- emergence concentrates here):")
    R.append("    %s  (depends on %d)" % (nm(M["argmax_depends"]), M["max_depends"]))
    R.append("")
    R.append("CYCLE CORES (%d modules in a feedback cycle):" % len(M["cycle_nodes"]))
    R.append("    " + ", ".join(nm(i) for i in M["cycle_nodes"]) if M["cycle_nodes"] else "    (none)")
    R.append("")
    R.append("ORPHANS (%d isolated modules -- no dependents AND no dependencies):" % len(M["orphans"]))
    R.append("    " + ", ".join(nm(i) for i in M["orphans"]) if M["orphans"] else "    (none)")
    R.append("")
    R.append("REDUNDANT-DEPENDENCY REFACTOR PROPOSALS (%d; target still reachable without the edge;" % len(M["redundant"]))
    R.append("advisory -- a graph-redundant edge may still carry live symbols, so cuts are operator-gated):")
    if M["redundant"]:
        for (a, b) in M["redundant"][:40]:
            R.append("    %-28s -X->  %s" % (nm(a), nm(b)))
        if len(M["redundant"]) > 40:
            R.append("    ... and %d more" % (len(M["redundant"]) - 40))
    else:
        R.append("    (none)")
    R.append("")
    R.append("=" * 78)
    with open(REPORT, "w", encoding="ascii", newline="\n") as f:
        f.write("\n".join(R) + "\n")


def main():
    node_names, edges = collect()
    M = analyze(node_names, edges)
    emit(M)
    write_report(M)
    print("nodes=%d edges=%d coupling=%d cycle_nodes=%d redundant=%d orphans=%d -> %s"
          % (len(node_names), len(edges), M["coupling"], len(M["cycle_nodes"]),
             len(M["redundant"]), len(M["orphans"]), OUT))
    print("report -> %s" % REPORT)


if __name__ == "__main__":
    main()
