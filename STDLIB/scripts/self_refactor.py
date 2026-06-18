#!/usr/bin/env python3
"""self_refactor.py -- III brings forth its own refactorings, compiler-verified.

The self-model SEES that some `extern ... from "X.iii"` dependencies are redundant; this
workflow turns that awareness into ACTION on III's own source: it finds every module dependency
whose imported symbols are ALL uncalled (each appears only in its own declaration), then -- and
this is the safety -- it TRIAL-REMOVES the declarations and RECOMPILES the module with the
production compiler.  Only cuts the compiler proves harmless (it still compiles -> the symbols
were genuinely dead, no call site, no relocation) are applied.  A removal that breaks the build
is reverted automatically.  III refactors itself; the compiler is the disposer.

Run:  python STDLIB/scripts/self_refactor.py            (apply verified-dead cuts)
      python STDLIB/scripts/self_refactor.py --dry-run  (report only)
"""
import os, re, sys, subprocess, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # STDLIB/
SRC = os.path.join(ROOT, "iii")
REPO = os.path.dirname(ROOT)
IIIS = os.path.join(REPO, "COMPILED", "iiis-2.exe")
ENV = dict(os.environ, SOURCE_DATE_EPOCH="0", LC_ALL="C", LANG="C", TZ="UTC0")

FROM_RE = re.compile(r'from\s+"([^"]+)\.iii"')
FN_RE = re.compile(r'\bfn\s+(\w+)')


def extern_statements(lines):
    """Yield (start_idx, end_idx_inclusive, fn_name, target) for each extern ...from "X.iii"."""
    i = 0
    n = len(lines)
    while i < n:
        if re.match(r'\s*extern\b', lines[i]):
            j = i
            buf = lines[i]
            while j < n and 'from "' not in lines[j]:
                j += 1
                if j < n:
                    buf += lines[j]
            if j < n:
                fm = FROM_RE.search(buf)
                fnm = FN_RE.search(buf)
                if fm and fnm:
                    yield (i, j, fnm.group(1), fm.group(1))
                i = j + 1
                continue
        i += 1


def compile_ok(text, name):
    with tempfile.TemporaryDirectory() as td:
        src = os.path.join(td, name + ".iii")
        obj = os.path.join(td, name + ".o")
        with open(src, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        r = subprocess.run([IIIS, src, "--compile-only", "--out", obj],
                           env=ENV, capture_output=True, text=True)
        return r.returncode == 0


def main():
    dry = "--dry-run" in sys.argv
    applied = []
    for dp, _d, fns in os.walk(SRC):
        for fn in fns:
            if not fn.endswith(".iii"):
                continue
            full = os.path.join(dp, fn)
            base = fn[:-4]
            with open(full, "r", encoding="utf-8", errors="replace") as f:
                text = f.read()
            lines = text.splitlines(keepends=True)
            stmts = list(extern_statements(lines))
            if not stmts:
                continue
            # group statements by target; a target is a candidate if EVERY imported symbol
            # from it occurs only in its own declaration (whole-file count == 1)
            by_tgt = {}
            for (s, e, name, tgt) in stmts:
                by_tgt.setdefault(tgt, []).append((s, e, name))
            dead_spans = []
            for tgt, group in by_tgt.items():
                if all(len(re.findall(r'\b' + re.escape(nm) + r'\b', text)) <= 1 for (_s, _e, nm) in group):
                    for (s, e, _nm) in group:
                        dead_spans.append((s, e, tgt))
            if not dead_spans:
                continue
            # build the trimmed text (drop every dead span's lines)
            drop = set()
            for (s, e, _t) in dead_spans:
                for k in range(s, e + 1):
                    drop.add(k)
            trimmed = "".join(l for k, l in enumerate(lines) if k not in drop)
            # the compiler is the oracle: only a cut it proves harmless is real
            if compile_ok(trimmed, base):
                tgts = sorted(set(t for (_s, _e, t) in dead_spans))
                applied.append((os.path.relpath(full, SRC).replace("\\", "/"), tgts, len(drop)))
                if not dry:
                    with open(full, "w", encoding="utf-8", newline="\n") as f:
                        f.write(trimmed)

    print("VERIFIED-DEAD dependency cuts (%s): %d module(s)"
          % ("dry-run" if dry else "APPLIED", len(applied)))
    for f, tgts, nl in applied:
        print("  %-40s  -X->  %-30s  (-%d lines)" % (f, ", ".join(tgts), nl))


if __name__ == "__main__":
    main()
