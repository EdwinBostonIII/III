import re
with open("r3_existing.txt", "r") as f:
    existing = set(l.strip() for l in f if l.strip())
with open("r3_str_consts.frag", "r") as f:
    text = f.read()
# split into pairs (var line + const _LEN line) so we filter atomically by base name
lines = text.splitlines()
out = []
i = 0
while i < len(lines):
    if i+1 < len(lines) and lines[i].startswith("var ") and lines[i+1].startswith("const "):
        m = re.match(r"var\s+(R3_[A-Z_0-9]+)\s+:", lines[i])
        if m and m.group(1) not in existing:
            out.append(lines[i])
            out.append(lines[i+1])
        i += 2
    else:
        i += 1
with open("r3_str_consts_new.frag", "w") as f:
    f.write("\n".join(out) + "\n")
print(f"Kept {len(out)//2} new const pairs ({len(out)} lines)")
