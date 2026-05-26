#!/usr/bin/env python3
# Decode cg_rm1.iii's RM1_HV_* asm-text byte arrays so we can read exactly what the Ring-1
# backend emits, and diff it against the Phase-0 proven CHARIOT sequence. (I1, read-only.)
import re, sys
src = open(r"C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_rm1.iii", encoding="utf-8", errors="replace").read()
# var NAME : [u8; N] = [ ... ]   (possibly multi-line)
pat = re.compile(r"var\s+(RM1_HV_\w+)\s*:\s*\[u8;\s*\d+\]\s*=\s*\[(.*?)\]", re.S)
want = sys.argv[1:] if len(sys.argv) > 1 else None
for m in pat.finditer(src):
    name, body = m.group(1), m.group(2)
    if want and not any(w in name for w in want):
        continue
    vals = [int(x) for x in re.findall(r"(\d+)u8", body)]
    text = "".join(chr(v) if 9 <= v < 127 else f"\\x{v:02x}" for v in vals)
    print(f"===== {name}  ({len(vals)} bytes) =====")
    print(text)
    print()
