#!/usr/bin/env python3
# KATABASIS gate_resident.sys -- kernel stack-depth bound.
# Builds the cross-module call graph from objdump -dr over every linked .o,
# finds the longest call path from DriverEntry, detects recursion, and sums
# actual per-frame stack cost vs the x64 kernel stack (0x6000 = 24 KiB).
import os, re, subprocess, sys

OBJDIR = os.path.join(os.path.dirname(__file__), "obj")
OBJS = [f for f in os.listdir(OBJDIR) if f.endswith(".o")]

func_re  = re.compile(r"^[0-9a-f]+ <([^>]+)>:")
sub_re   = re.compile(r"sub\s+rsp,0x([0-9a-f]+)")
call_re  = re.compile(r"\bcall\s+[0-9a-f]+ <([^>]+)>")
reloc_re = re.compile(r"IMAGE_REL_AMD64_REL32\s+(\S+)")

frame = {}                  # fn -> prologue sub rsp bytes (max seen)
edges = {}                  # fn -> list of callees (in call order, dups ok)
defined = set()

for o in OBJS:
    out = subprocess.run(["objdump","-dr","-M","intel", os.path.join(OBJDIR,o)],
                         capture_output=True, text=True).stdout
    lines = out.splitlines()
    cur = None
    for i, ln in enumerate(lines):
        m = func_re.match(ln)
        if m:
            cur = m.group(1); defined.add(cur)
            frame.setdefault(cur, 0); edges.setdefault(cur, [])
            continue
        if cur is None:
            continue
        ms = sub_re.search(ln)
        if ms:
            frame[cur] = max(frame[cur], int(ms.group(1),16))
        mc = call_re.search(ln)
        if mc:
            tgt = mc.group(1)
            if "+" in tgt:                       # rel0 -> real target on next line's reloc
                if i+1 < len(lines):
                    mr = reloc_re.search(lines[i+1])
                    tgt = mr.group(1) if mr else None
                else:
                    tgt = None
            if tgt:
                edges[cur].append(tgt)

# longest path (DAG) from DriverEntry, detect cycles
best = {"depth":0, "path":[]}
WHITE,GRAY,BLACK = 0,1,2
color = {}
recursion = []

def dfs(fn, path, bytes_so_far):
    color[fn] = GRAY
    fr = frame.get(fn, 0)
    # per active frame: retaddr(8)+saved rbp(8)+frame(fr)+shadow(0x20 if it calls anything)
    cost = 8 + 8 + fr + (0x20 if edges.get(fn) else 0)
    total = bytes_so_far + cost
    npath = path + [(fn, fr, total)]
    callees = edges.get(fn, [])
    leaf = True
    for c in callees:
        if c not in defined and c != "iii_witness_emit_kernel":
            continue                              # unresolved data sym etc.
        if c == "iii_witness_emit_kernel":
            # leaf hook: +retaddr only, never deeper; account once at peak
            peak = total + 8
            if peak > best["depth"]:
                best.update(depth=peak, path=npath+[("iii_witness_emit_kernel",0,peak)])
            continue
        if color.get(c, WHITE) == GRAY:
            recursion.append((fn, c)); continue
        leaf = False
        dfs(c, npath, total)
    if leaf and not callees:
        if total > best["depth"]:
            best.update(depth=total, path=npath)
    color[fn] = BLACK

root = sys.argv[1] if len(sys.argv) > 1 else "DriverEntry"
if root not in defined:
    print(f"root {root} not found!"); sys.exit(1)
print(f"root = {root}")
dfs(root, [], 0)

KSTACK = 0x6000
print(f"functions parsed: {len(defined)}   distinct frame sizes: {sorted(set(frame.values()))}")
print(f"recursion edges:  {recursion if recursion else 'NONE (acyclic)'}")
print(f"\nDEEPEST PATH (depth {len(best['path'])} frames, peak {best['depth']} bytes = {best['depth']/1024:.1f} KiB):")
for fn, fr, tot in best["path"]:
    print(f"   {tot:6d}  (+frame 0x{fr:x})  {fn}")
print(f"\nkernel stack budget 0x{KSTACK:x} ({KSTACK//1024} KiB);  peak/budget = {100*best['depth']/KSTACK:.1f}%")
print("VERDICT:", "OK (within budget)" if best["depth"] < KSTACK else "*** OVERFLOW RISK ***")
