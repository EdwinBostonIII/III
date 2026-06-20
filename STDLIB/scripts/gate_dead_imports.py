#!/usr/bin/env python3
# STDLIB/scripts/gate_dead_imports.py -- III self-model consistency gate (the WEAVE invariant).
#
# III maintains TWO independently-built self-models: self_atlas's `from "X.iii"` IMPORT graph
# (gen_self_atlas.py) and corpus_coverage's caller->callee CALL graph (its own lexer). They must
# AGREE: every declared `extern ... fn SYM ... from "X.iii"` must be a symbol the module actually
# CALLS. A declared-but-never-called extern is DEAD PLUMBING -- a phantom dependency edge in the
# self-model and the precise "waste/NIH-breach that gets referenced" that whole-module orphan
# scans cannot see.
#
# This gate RE-DERIVES the diff from the live source tree (no hand-maintenance, no committed data
# to rot) and FAILS (exit 1) if any dead import exists. It is the evergreen enforcer: the moment
# someone adds an `extern` they never call, the build catches it -- either wire the call, or drop
# the decl. (Established clean at commit f2c9e8d5: 3930 intra-III externs, 0 dead.)
#
# Discipline baked in (each a bug caught while building this): comments stripped but strings KEPT
# for decl-detection (externs need `from "X.iii"`); per-file detection (basename collisions like
# omnia/ripple vs forcefield/ripple are real); strings blanked for the reference count.
#
# Usage:  python STDLIB/scripts/gate_dead_imports.py [--list]
#   exit 0 = clean (no dead imports); exit 1 = dead imports found (printed); exit 2 = usage error.
import os, re, sys, collections

ROOT = os.path.join(os.path.dirname(__file__), "..", "iii")
ROOT = os.path.normpath(ROOT)
LIST = ("--list" in sys.argv)
BS = 92

def strip_comments(src):
    out = []; i = 0; n = len(src)
    while i < n:
        c = src[i]
        if c == '/' and i+1 < n and src[i+1] == '*':
            depth = 1; i += 2
            while i < n and depth > 0:
                if src[i] == '/' and i+1 < n and src[i+1] == '*': depth += 1; i += 2
                elif src[i] == '*' and i+1 < n and src[i+1] == '/': depth -= 1; i += 2
                else: i += 1
            out.append(' ')
        elif c == '/' and i+1 < n and src[i+1] == '/':
            while i < n and src[i] != '\n': i += 1
            out.append(' ')
        elif c == '"':
            out.append('"'); i += 1
            while i < n and src[i] != '"':
                if ord(src[i]) == BS: out.append(src[i:i+2]); i += 2
                else: out.append(src[i]); i += 1
            if i < n: out.append('"'); i += 1
        else:
            out.append(c); i += 1
    return ''.join(out)

def blank_strings(s):
    out = []; i = 0; n = len(s)
    while i < n:
        if s[i] == '"':
            out.append(' '); i += 1
            while i < n and s[i] != '"':
                if ord(s[i]) == BS: i += 2
                else: i += 1
            i += 1; out.append(' ')
        else:
            out.append(s[i]); i += 1
    return ''.join(out)

def main():
    files = {}
    basenames = set()
    for dp, _, fn in os.walk(ROOT):
        for f in fn:
            if f.endswith(".iii"):
                rel = os.path.relpath(os.path.join(dp, f), ROOT).replace("\\", "/")[:-4]
                files[rel] = os.path.join(dp, f)
                basenames.add(f[:-4])
    ext_re = re.compile(r'extern\s+@abi\([^)]*\)\s+fn\s+(\w+)\s*\(.*?\bfrom\s+"([^"]+)"', re.S)
    dead = []
    total = 0
    for rel, path in files.items():
        src = open(path, encoding='utf-8', errors='replace').read()
        cc = strip_comments(src)
        decls = list(ext_re.finditer(cc))
        body = cc
        for m in sorted(decls, key=lambda mm: -mm.start()):
            body = body[:m.start()] + (' ' * (m.end()-m.start())) + body[m.end():]
        body = blank_strings(body)
        selfb = rel.split("/")[-1]
        for m in decls:
            sym = m.group(1); tgt = m.group(2)
            tgt = tgt[:-4] if tgt.endswith(".iii") else tgt
            tgtb = tgt.split("/")[-1]
            if tgtb not in basenames or tgtb == selfb:
                continue
            total += 1
            if re.search(r'(?<![A-Za-z0-9_])'+re.escape(sym)+r'(?![A-Za-z0-9_])', body) is None:
                dead.append((rel, sym, tgtb))
    print(f"[gate_dead_imports] {len(files)} files, {total} intra-III extern decls, {len(dead)} dead")
    if dead:
        print("[gate_dead_imports] FAIL -- declared-but-never-called externs (dead plumbing):")
        for rel, sym, tgt in sorted(dead):
            print(f"    {rel}.iii  declares {sym}  from {tgt}  -- NEVER CALLED (wire the call, or drop the decl)")
        return 1
    print("[gate_dead_imports] PASS -- import graph == call graph (no dead plumbing)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
