#!/usr/bin/env python3
"""emergence_cycle.py -- III's self-improvement loop, made runnable.

ONE cycle of the factory-in-motion:

  1. RE-MAP    regenerate III's self-model from its own current source
               (STDLIB/scripts/gen_self_atlas.py -> omnia/self_atlas_data.iii + the dashboard).
  2. RE-FORGE  recompile the self-model organs (self_atlas, self_atlas_data, self_atlas_lens)
               with the production compiler.
  3. VERIFY    compile + link + run the self-model corpus (1666-1669); every one must return 99
               -- this re-proves the self-model + lens + the Python<->.iii cross-check after any
               change to III's source (the model stays HONEST as III grows).
  4. SURFACE   print the ranked self-improvement candidates from the dashboard (the steepest
               hub, the cycle cores, the orphans, the redundant-dependency refactor proposals).

Run it after ANY change to STDLIB/iii to see how III's self-image -- and the next thing the
substrate wants improved -- has moved.  Idempotent and deterministic.

No WSL required: drives iiis.exe + gcc directly (portable on this Windows host).
"""
import os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
STDLIB = os.path.dirname(HERE)
ROOT = os.path.dirname(STDLIB)
IIIS = os.path.join(ROOT, "COMPILED", "iiis-2.exe")
SRC = os.path.join(STDLIB, "iii")
BUILD = os.path.join(STDLIB, "build", "iii")
CORPUS = os.path.join(STDLIB, "corpus")
CBUILD = os.path.join(STDLIB, "build", "corpus")
LIB = os.path.join(BUILD, "libiii_native.a")
REPORT = os.path.join(ROOT, "_emergence_report.txt")

ORGANS = ["omnia/self_atlas", "omnia/self_atlas_data", "omnia/self_atlas_lens"]
# test -> (extra organ objs it needs beyond libiii_native.a)
TESTS = {
    "1666_self_atlas":        ["omnia_self_atlas"],
    "1667_self_atlas_real":   ["omnia_self_atlas", "omnia_self_atlas_data"],
    "1668_self_atlas_lens":   ["omnia_self_atlas", "omnia_self_atlas_lens"],
    "1669_self_atlas_report": ["omnia_self_atlas", "omnia_self_atlas_data", "omnia_self_atlas_lens"],
}
ENV = dict(os.environ, SOURCE_DATE_EPOCH="0", LC_ALL="C", LANG="C", TZ="UTC0")


def run(cmd, **kw):
    return subprocess.run(cmd, env=ENV, capture_output=True, text=True, **kw)


def step(msg):
    print("\n== %s ==" % msg, flush=True)


def compile_iii(src, obj):
    r = run([IIIS, src, "--compile-only", "--out", obj])
    if r.returncode != 0:
        print("  COMPILE FAIL %s\n%s%s" % (src, r.stdout, r.stderr))
        return False
    return True


def main():
    if not os.path.exists(IIIS):
        print("FATAL: compiler not found: %s" % IIIS); return 2
    if not os.path.exists(LIB):
        print("FATAL: %s missing -- run build_stdlib.sh first" % LIB); return 2
    os.makedirs(CBUILD, exist_ok=True)

    step("1. RE-MAP  (regenerate III's self-model from its own source)")
    r = run([sys.executable, os.path.join(HERE, "gen_self_atlas.py")])
    print(r.stdout.strip() or r.stderr.strip())
    if r.returncode != 0:
        return 1

    step("2. RE-FORGE  (recompile the self-model organs)")
    for mod in ORGANS:
        obj = os.path.join(BUILD, mod.replace("/", "_") + ".iii.o")
        if not compile_iii(os.path.join(SRC, mod + ".iii"), obj):
            return 1
        print("  ok  %s" % mod)

    step("3. VERIFY  (self-model corpus 1666-1669 must each return 99)")
    all_ok = True
    for base, organs in TESTS.items():
        src = os.path.join(CORPUS, base + ".iii")
        obj = os.path.join(CBUILD, base + ".o")
        exe = os.path.join(CBUILD, base + ".exe")
        if not compile_iii(src, obj):
            all_ok = False; continue
        organ_objs = [os.path.join(BUILD, o + ".iii.o") for o in organs]
        link = ["gcc", obj] + organ_objs + [LIB, "-lws2_32", "-lkernel32", "-o", exe]
        lr = run(link)
        if lr.returncode != 0:
            print("  LINK FAIL %s\n%s%s" % (base, lr.stdout, lr.stderr)); all_ok = False; continue
        rr = run([exe])
        status = "PASS" if rr.returncode == 99 else "FAIL (rc=%d)" % rr.returncode
        if rr.returncode != 99:
            all_ok = False
        print("  %-26s %s" % (base, status))

    step("4. SURFACE  (the self-improvement candidates III sees in itself)")
    if os.path.exists(REPORT):
        with open(REPORT, "r", encoding="ascii", errors="replace") as f:
            print(f.read())

    print("=" * 60)
    print("EMERGENCE CYCLE: %s" % ("GREEN -- self-model honest, all checks pass"
                                   if all_ok else "RED -- a self-model check failed (see above)"))
    print("=" * 60)
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
