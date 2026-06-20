import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
r = d.get('result', d)
print("COUNTS:", r['counts'])
print("CANARY:", r['canary'])
print("PERFECT:", [x.split('/')[-1] for x in r['perfect_files']])
fs = r['surviving_findings']
print("\n=== SURVIVING FINDINGS (%d) ===" % len(fs))
for i, fd in enumerate(fs, 1):
    print("\n[%d] %s  %s  %s  L%s" % (i, fd['file'].split('/')[-1], fd['category'], fd['severity'], fd['line']))
    print("    std:", fd.get('named_standard', '')[:100])
    print("    why:", fd.get('rationale', '')[:260].replace('\n', ' '))
ref = r.get('refuted', [])
print("\n=== REFUTED (%d) ===" % len(ref))
for x in ref[:50]:
    print("  - %s %s L%s: %s" % (x['file'].split('/')[-1], x['category'], x['line'], x['refutation'][:110].replace('\n',' ')))
