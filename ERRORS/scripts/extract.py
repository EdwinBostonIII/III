#!/usr/bin/env python3
"""Extract every error code from DOCS/III-ERRORS.md and emit C catalogue."""
import re, sys, os, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPEC = ROOT / "DOCS" / "III-ERRORS.md"
OUT_C = ROOT / "ERRORS" / "src" / "errors_catalog.c"
OUT_H = ROOT / "ERRORS" / "include" / "iii" / "errors_codes.h"

# Phase prefixes -> (phase enum name, phase display, default severity)
# Severity: INFO, WARN, ERROR, PANIC, COMPROMISE
PHASE_TABLE = [
    ("LEX",     "compile_lex",     "ERROR"),
    ("PARSE",   "compile_parse",   "ERROR"),
    ("TYPE",    "compile_type",    "ERROR"),
    ("PROOF",   "compile_proof",   "ERROR"),
    ("SID",     "compile_sid",     "ERROR"),
    ("CG",      "compile_codegen", "ERROR"),
    ("LINK",    "compile_link",    "ERROR"),
    ("RUN",     "runtime_cycle",   "ERROR"),
    ("TRIN",    "runtime_trinity", "ERROR"),
    ("CAT",     "runtime_catalyst","ERROR"),
    ("SAN",     "runtime_sanctum", "ERROR"),
    ("FED",     "runtime_fed",     "ERROR"),
    ("WIT",     "runtime_witness", "ERROR"),
    ("MOD",     "runtime_module",  "ERROR"),
    ("FNDR",    "runtime_anchor",  "ERROR"),
    ("CONF",    "audit_conform",   "ERROR"),
    ("REPLAY",  "audit_replay",    "ERROR"),
    ("CRYPTO",  "runtime_crypto",  "ERROR"),
    ("ZK",      "runtime_zk",      "ERROR"),
    ("GENESIS", "runtime_genesis", "ERROR"),
    ("PANIC",   "panic",           "PANIC"),
]
PHASE_PREFIXES = [p[0] for p in PHASE_TABLE]

# Renaming map (§19) — registered as namespace alias entries.
RENAMES = [
    ("A1",  "LEXICON",    "C-LEX-*"),
    ("A2",  "GRAMMAR",    "C-GRAM-*"),
    ("A3",  "TYPES",      "C-TYPE-*"),
    ("A4",  "EFFECTS",    "C-EFF-*"),
    ("A5",  "CYCLES",     "C-CYC-*"),
    ("A6",  "HEXAD",      "C-HEX-*"),
    ("A7",  "PHASES",     "C-PH-*"),
    ("A8",  "SANCTUM",    "C-SAN-*"),
    ("A9",  "TRINITY",    "C-TRIN-*"),
    ("A10", "MODULES",    "C-MOD-*"),
    ("B1",  "CATALYST",   "C-CAT-*"),
    ("B2",  "FEDERATION", "C-FED-*"),
    ("C1",  "ABI",        "C-ABI-*"),
]

text = SPEC.read_text(encoding="utf-8")

# Match table rows: | CODE | msg | recovery |  where CODE matches our prefix set.
prefix_alt = "|".join(re.escape(p) for p in PHASE_PREFIXES)
row_re = re.compile(
    r"^\|\s*((?:" + prefix_alt + r")[-A-Z0-9]*-[A-Z0-9-]+?)\s*\|"
    r"(?:\s*\d+\s*\|)?"            # optional layer column for TRIN
    r"\s*(.+?)\s*\|\s*(.+?)\s*\|\s*$",
    re.MULTILINE,
)

entries = []  # list of (code, phase_prefix, subsystem, suffix_num, message, recovery, severity)
seen_codes = set()

# Severity hints
def classify_severity(code, msg, recovery):
    if code.startswith("PANIC-"):
        if "CATASTROPHIC" in recovery.upper() or "CATASTROPHIC" in msg.upper():
            return "CATASTROPHIC"
        return "PANIC"
    if "compromise" in msg.lower() or "compromise" in recovery.lower():
        return "COMPROMISE"
    if "informational" in recovery.lower() or "(informational" in recovery.lower():
        return "INFO"
    if "operational" in recovery.lower():
        return "INFO"
    if "warning" in msg.lower():
        return "WARN"
    return "ERROR"

def split_subsystem(code):
    # code like LEX-ENC-001 -> phase=LEX, sub=ENC, suffix=001
    # CONF-CRITERION-FAIL-N -> phase=CONF, sub=CRITERION-FAIL, suffix=N
    parts = code.split("-")
    phase = parts[0]
    if len(parts) == 2:
        return phase, "GEN", parts[1]
    # subsystem = middle segments joined; suffix = last segment
    sub = "-".join(parts[1:-1])
    suffix = parts[-1]
    return phase, sub, suffix

for m in row_re.finditer(text):
    code = m.group(1).strip()
    msg  = m.group(2).strip()
    rec  = m.group(3).strip()
    # Skip header/separator rows where code is literally "Code"
    if code in seen_codes:
        continue
    if not any(code.startswith(p + "-") or code == p for p in PHASE_PREFIXES):
        continue
    phase, sub, suffix = split_subsystem(code)
    sev = classify_severity(code, msg, rec)
    entries.append((code, phase, sub, suffix, msg, rec, sev))
    seen_codes.add(code)

# Append rename namespace alias entries (informational catalog metadata).
for new_short, spec_name, old_pref in RENAMES:
    code = f"CONF-RENAME-{new_short}"
    if code in seen_codes:
        continue
    msg = f"Per-spec criterion namespace alias: spec {spec_name} ({old_pref}) renamed to C-{new_short}-*"
    rec = "Use the C-<NSCODE>-N form when citing per-spec conformance criteria."
    entries.append((code, "CONF", "RENAME", new_short, msg, rec, "INFO"))
    seen_codes.add(code)

# Sort: by phase (in PHASE_TABLE order), then subsystem, then suffix
phase_order = {p: i for i, p in enumerate(PHASE_PREFIXES)}
def sort_key(e):
    code, phase, sub, suffix, *_ = e
    # numeric suffix sort if possible
    try:
        n = int(re.sub(r"\D","",suffix) or "0")
    except Exception:
        n = 0
    return (phase_order.get(phase, 99), sub, n, suffix)
entries.sort(key=sort_key)

def c_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

def c_id(code):
    return "III_E_" + re.sub(r"[^A-Za-z0-9]+","_", code)

# Emit codes header (enum)
H = ['/* AUTO-GENERATED by ERRORS/scripts/extract.py — do not edit */',
     '#ifndef III_ERRORS_CODES_H',
     '#define III_ERRORS_CODES_H',
     '#include <stdint.h>',
     '',
     '/* Stable numeric IDs for every catalogued error.',
     ' * The numeric value equals the entry index + 1; index 0 is reserved INVALID. */',
     'typedef uint32_t iii_error_code_t;',
     '',
     '#define III_E_INVALID  ((iii_error_code_t)0u)',
     '']
for i, e in enumerate(entries, start=1):
    H.append(f"#define {c_id(e[0])}  ((iii_error_code_t){i}u)")
H.append('')
H.append(f"#define III_ERROR_COUNT_TOTAL  ((iii_error_code_t){len(entries)}u)")
H.append('')
H.append('#endif /* III_ERRORS_CODES_H */')
OUT_H.write_text("\n".join(H) + "\n", encoding="utf-8")

# Emit catalogue C source
C = ['/* AUTO-GENERATED by ERRORS/scripts/extract.py — do not edit */',
     '#include "iii/errors.h"',
     '#include <stddef.h>',
     '',
     'const iii_error_info_t iii_error_catalog[] = {']
for i, (code, phase, sub, suffix, msg, rec, sev) in enumerate(entries, start=1):
    C.append('    { ' +
             f'.code = {i}u, ' +
             f'.name = {c_string(code)}, ' +
             f'.phase = {c_string(phase)}, ' +
             f'.subsystem = {c_string(sub)}, ' +
             f'.suffix = {c_string(suffix)}, ' +
             f'.severity = III_SEV_{sev}, ' +
             f'.description = {c_string(msg)}, ' +
             f'.remediation = {c_string(rec)}' +
             ' },')
C.append('};')
C.append('')
C.append(f'const size_t iii_error_catalog_len = (size_t){len(entries)}u;')
C.append('')

# Phase table
C.append('const iii_phase_info_t iii_phase_table[] = {')
for pref, name, _sev in PHASE_TABLE:
    C.append(f'    {{ .prefix = "{pref}", .display = "{name}" }},')
C.append('};')
C.append(f'const size_t iii_phase_table_len = (size_t){len(PHASE_TABLE)}u;')
C.append('')
OUT_C.write_text("\n".join(C) + "\n", encoding="utf-8")

# Stats
phase_counts = {}
for e in entries:
    phase_counts[e[1]] = phase_counts.get(e[1], 0) + 1
print(f"Total entries: {len(entries)}")
for p in PHASE_PREFIXES:
    print(f"  {p:8s} {phase_counts.get(p,0)}")
