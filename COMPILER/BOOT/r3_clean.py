import re
KILL = {"R3_PFX_STR","R3_PFX_MHASH","R3_PFX_DECL","R3_PFX_FIELD","R3_PFX_MATCHEND","R3_PFX_FORTOP","R3_PFX_FOREND"}
with open("r3_str_consts_new.frag","r") as f: lines = f.read().splitlines()
out = []
i = 0
while i < len(lines):
    if i+1 < len(lines) and lines[i].startswith("var "):
        m = re.match(r"var\s+(R3_[A-Z_0-9]+)", lines[i])
        if m and m.group(1) in KILL:
            i += 2; continue
    out.append(lines[i]); i += 1
open("r3_str_consts_clean.frag","w").write("\n".join(out)+"\n")
print(f"final {len(out)//2} new pairs")
