# III Toolchain — exchange manifest (every `.iii` version + every format it compiles to/from)

**Generated 2026-06-27, against the live tree.** Scope: III (`.iii`) + its IR **SVIR** only. A collected, hash-verified
copy of the canonical pieces lives in `III/EXCHANGE/` (verify with `sha256sum -c EXCHANGE/CHECKSUMS.sha256`).
Hashes below are **live sha256 of the current bytes**, not the sealed `.mhash` goldens (drift is flagged).

## 1. Compiler versions — the bootstrap chain

| Version | Path | Size | live sha256 | Role / lineage | ABI/target |
|---|---|---|---|---|---|
| **iiis-0** | `COMPILED/iiis-0.exe` | 436 KB | `767ce72c…` ✓ | **C seed**; bootstraps iiis-1. A build-variant of the seed (codegen ≡ iiis-2, verified); `.mhash` re-sealed to match | win64 PE/COFF |
| **iiis-1** | `COMPILED/iiis-1.exe` | 3.06 MB | `7d29ee4a…` ◇ | stage-1: the `.iii` ports compiled by iiis-0 (+ residual C TUs) | win64 PE/COFF |
| **iiis-2** | `COMPILED/iiis-2.exe` | 1.52 MB | `52e3b941…` ✓ | **the active self-hosted compiler** (lex/parse/sema/cg_r3 all `.iii`) | win64 PE/COFF |
| **iiis-3** | `COMPILED/iiis-3.exe` | 1.52 MB | `52e3b941…` ✓ | stage-3 = iiis-2 recompiling the sources → **byte-identical to iiis-2** | win64 PE/COFF |
| iiis-4 | — | — | — | **does not exist; not a distinct artifact** — by the iiis-2==iiis-3 fixpoint, stage-4 re-derives iiis-3 | — |

- **✓ The trust gate is the self-hosted fixpoint `iiis-2 == iiis-3` (`52e3b941…`)** — verified live this session. That,
  not any seed seal, is what carries trust.
- **✓ iiis-0 seal — reconciled (evergreen).** Investigation (2026-06-27): the seed had been *rebuilt* — the committed
  `9b1e243d` and the working `767ce72c` are **different binaries that emit byte-identical codegen** (5/5 corpus +
  the full 60/60 `.text`-identity gate → functionally-identical compilers, different builds), while the old `.mhash`
  golden `9704b870` was a stale *third* build. **So the byte-hash is build-variant provenance, not the trust
  invariant.** Fix: the `.mhash` is re-sealed to the live verified binary (`767ce72c…`, canonical two-space format),
  and `seed_text_identity_gate.sh` now enforces BOTH (a) the **real** invariant — **iiis-0 ≡ iiis-2 codegen** (the
  functional seal) — and (b) **seal-consistency** (`mhash == sha256(binary)`), so a future rebuild-without-reseal
  reddens the gate. The drift cannot silently recur. (Trust still ultimately rests on the iiis-2==iiis-3 fixpoint.)
- **◇ iiis-1 flaky mhash:** iiis-1's full-binary hash is non-deterministic by the `.rodata` provenance string-pool
  ordering (see `DOCS/III-SEED-RODATA-DIVERGENCE.md`), NOT a codegen difference; iiis-1 is intermediate, not trust-gated.

## 2. Formats it compiles **to** and **from** — the conversion graph + exact recipes

```
 .c  ──gcc────────────────▶ iiis-0.exe           (seed; frozen)
 .iii ──iiis-(N-1)────────▶ iiis-N.exe           (bootstrap: ports + libiii_native.a)
 .iii ──iiis-2 --compile-only▶ .o                (compile a program/module)
 .o … ──ar rcs────────────▶ .a                   (static archive, e.g. libiii_native.a)
 .o + .a ──link───────────▶ .exe                 (gcc/ld OR the sovereign sovld — no gcc/ld in the trusted path)
 .c  ──ccsv───────────────▶ SVIR (gen_svir.iii)  (C-subset → Sovereign IR; the R1 trust-floor translator)
 SVIR ──svir_verify───────▶ verdict (0=valid)    (the 80-line auditable trust anchor)
 SVIR ──svir_interp───────▶ execution            (reference oracle; 3rd independent executor)
 SVIR ──svir_x86──────────▶ x86 / .s             (sovereign native backend)
 SVIR ──svir_wasm─────────▶ .wasm                (WebAssembly backend)
```

| From → To | Command |
|---|---|
| `.iii` → `.o` | `COMPILED/iiis-2.exe FILE.iii --compile-only --out FILE.o` |
| `.o`(s) → `.a` | `ar rcs lib.a *.o`  (stdlib: `STDLIB/scripts/build_stdlib.sh`) |
| `.o`+`.a` → `.exe` | `gcc FILE.o STDLIB/build/iii/libiii_native.a -lws2_32 -lkernel32 -o FILE.exe` (sovereign: `sovld`) |
| `.iii` → `iiis-N` | `COMPILER/BOOT/build_iiis{1,2,3}.sh` (each gate-checked on `stage1_corpus`) |
| `.c` → SVIR | `ccsv FILE.c > gen_svir.iii`  (`STDLIB/sovir/`) |
| SVIR → verify | link `svir_verify.o`; `svir_verify(ptr,len)` → 0 if valid |
| SVIR → run | link `svir_interp.o` + `gen_svir.o` → executes func 0 |

## 3. Canonical runtime + IR artifacts

| Artifact | Path | Size | Purpose |
|---|---|---|---|
| **libiii_native.a** | `STDLIB/build/iii/libiii_native.a` | 7.53 MB | the trust-closed STDLIB archive linked into every III program + iiis-1/2/3 |
| **svir_verify.iii** | `STDLIB/sovir/svir_verify.iii` | the SVIR **trust anchor** (validates any SVIR module) |
| **svir_interp.iii** | `STDLIB/sovir/svir_interp.iii` | the SVIR **reference executor** (ground-truth oracle) |
| **SVIR-V1-CANONICAL.md** | `DOCS/SVIR-V1-CANONICAL.md` | the SVIR v1 ISA spec |

## 4. Format census (the whole tree)

`.iii` 3371 · `.c` 471 · `.h` 24 · `.o` 5740 · `.a` 8 · `.exe` 4194 · `.s` 5944 · `.wasm` 145 · `.mhash` 19

## 5. The EXCHANGE bundle (`III/EXCHANGE/`)

```
EXCHANGE/
  compiler/  iiis-0.exe  iiis-1.exe  iiis-2.exe  iiis-3.exe  (+ each .witness.json)
  runtime/   libiii_native.a
  svir/      svir_verify.iii  svir_interp.iii  SVIR-V1-CANONICAL.md
  CHECKSUMS.sha256          # verify: cd EXCHANGE && sha256sum -c CHECKSUMS.sha256
```

Everything else (3371 `.iii` sources, 5740 `.o`, 4194 `.exe`, the `.s`/`.wasm` outputs) stays in the live tree; this
manifest is the index + the recipes to regenerate any of it. To add the iiis-4 fixpoint-confirmation binary, a
`build_iiis4.sh` (iiis-3 recompiling the ports) can be created on request — it will reproduce iiis-3 byte-for-byte.
