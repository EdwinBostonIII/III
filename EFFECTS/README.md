# III-EFFECTS — 17 SE Kinds + 3 Compromise Tiers

**Doc-ID:** A4 / R1.A4
**Spec:** `DOCS/III-EFFECTS.md`

The 17 IRPD-only side-effect kinds (MSR_WRITE..NMI_INSTALL), 3 compromise
tiers (NONE/LOW/MEDIUM/HIGH-uninhabited), PIP (Predictive Inverse
Pre-Materialization) blob classes, ghost effects, epistemic uncertainty
carriers, Möbius-promotable effect kinds, and the wavefront/effect-set
algebra.

## Layout

```
EFFECTS/
├── include/iii/effects.h
├── src/effects.c
├── tests/test_effects.c           55 assertions (standalone API)
├── tools/iii_effects_tool.c       Parser-coupled walker
└── build/build.bat                builds lib + test + iii_effects_tool.exe
```

The library depends on LEXICON + GRAMMAR + TYPES (since AST nodes carry
effect-set evidence).  Standalone API surface (SE kinds, compromise tiers,
PIP blob primitives, epistemic carriers) is exercised by the test.

## Build

```
$ build\build.bat          REM (or the equivalent gcc invocation)
$ ./build/iii_effects_test
=== 55 passed, 0 failed ===
```

`build.bat` (added RITCHIE Stage 1.22; the tool source existed but was never
built) compiles `src/effects.c` → `libiii_effects.a`, then links **both** the
test and **`iii_effects_tool.exe`** against EFFECTS + TYPES + GRAMMAR + LEXICON.

`iii_effects_tool` subcommands: `infer <FILE.III>` (per-function effect set),
`irpd <KIND|METHOD>` (IRPD admissibility/inverse), `compromise <FILE.III>`
(highest tier in module), `kinds` (17 SE kinds + 3 compromise tiers),
`--hash <FILE>` (R1.A4 SHA-256), `--module` (name/version).

## Test

```
$ ./build/iii_effects_test
=== 55 passed, 0 failed ===
```

## Conformance

| Code | Status |
| --- | --- |
| C-EFF-1 | ✅ 17 SE kinds (`III_SE_BUILTIN_COUNT == 17`) |
| C-EFF-2 | ✅ Compromise.join is monotone max |
| C-EFF-3 | ✅ PIP STATIC_BYTES / DYNAMIC_FN / COMPOSED constructors + reconstruct |
| C-EFF-7 | ✅ Compromise.HIGH structurally not inhabited |
| §5    | ✅ uncertainty escalation when confidence < 13926 q14 OR question_count > 0 |
| §6    | ✅ reserved Möbius promotion band 0x01C7..0x01CF (9 slots) |
