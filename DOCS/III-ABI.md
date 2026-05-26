# III-ABI.md — The Bootstrap ABI Rule

**Document Identity:** C1 / The Single Bootstrap-Only ABI Rule
**Canonical Hash Slot:** R1.C1
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. Minimal by design — one rule, no expansion without `amend.apply` at constitutional tier.

---

## §0. Preamble — Why This Document Is Short

In other languages, an ABI specification is a hundred-page document defining calling conventions, register-saving rules, struct layouts, name-mangling schemes, exception-unwinding tables, TLS access patterns, dynamic-linking discipline, and so on. III rejects this surface area. There is exactly **one legal foreign-function bridge** in III — `extern @abi(c-msvc-x64)` — and one legal use of it: the BOOT compiler's bootstrap, where III source must call into a small set of pre-existing C primitives (the SHA-256 implementation, the UTF-8 decoder, the unicode-NFC table, the kernel-mode driver dispatch helpers).

After Stage 4 self-host (III-SANCTUM.md §1, seal_id 9), even this single bridge becomes vestigial: the SELF compiler's standard library re-implements every C primitive in III, and the `extern @abi(c-msvc-x64)` declarations remain only for backward compatibility with pre-Stage-4 module artifacts.

This document is therefore minimal. The full surface is **one rule**.

---

## §1. The Rule

**Every cross-language bridge in III uses `extern @abi(c-msvc-x64)` and only that.** No other ABI is admitted by the lexer or the type system.

### §1.1 Syntax

```iii
extern @abi(c-msvc-x64) {
    fn sha256_init(state: *Sha256State) -> ();
    fn sha256_update(state: *Sha256State, data: *u8, len: u32) -> ();
    fn sha256_final(state: *Sha256State, out: *[u8; 32]) -> ();
    type Sha256State = [u8; 104];
}
```

### §1.2 Constraints

1. **The ABI name `c-msvc-x64` is the only legal value.** Other ABI names (`c-sysv-x64`, `vmrun-trampoline`, `magic-msr`, `ioctl`) are reserved but not currently admitted; promoting any to legal status requires `amend.apply` at constitutional tier.

2. **`extern` blocks are ring-restricted to R0 and R3.** Calls into C from R-1 or R-2 are rejected at type-check time (`TYPE-EXTERN-001 extern call from privileged ring`). The reason: C code cannot be trusted to maintain the substrate's invariants (witness emission, hexad admission, IRPD discipline); it must be confined to the lower-privilege rings where its damage is bounded.

3. **Every extern call is wrapped in a synthesized cycle.** The compiler emits a cycle whose forward invokes the C function, whose inverse is `Compromise<MEDIUM>` (no general reverse-engineering of opaque C effects), whose witness records the arguments and return value, and whose hexad is `EXTERN_C_CALL` (a structurally-admissible but Trinity-Layer-3-required hexad).

4. **No naked `extern` declarations.** Every `extern @abi(c-msvc-x64)` block must be inside a module declared with `@ring(R0, R3)` (or a subset). Modules at R-1 or R-2 cannot contain `extern` blocks (`PARSE-EXTERN-001 extern in privileged-ring module`).

5. **Argument types are restricted.** The `extern_type` production (III-GRAMMAR.bnf §5.8) admits only:
   - Primitives (`u8..u64`, `i8..i64`, `f32`, `f64`, `bool`).
   - Raw pointers (`*T`) — but pointed-to memory must be owned by the caller and outlive the call.
   - References (`&T`) — borrowed for the call duration only.
   - Fixed-size arrays (`[T; N]`).
   - Type aliases declared inside the same `extern` block.

   Higher-kinded III types (`Reduction`, `Cap`, `Glyph`, `Witness`, `Hexad`, etc.) are **forbidden** as extern arguments — they cannot survive a round-trip through C.

---

## §2. The Bootstrap-Only Discipline

The current legal use of `extern @abi(c-msvc-x64)` is **bootstrap only**. The BOOT compiler `telosc-0` calls into a small, audited set of C primitives:

- SHA-256, BLAKE3, HMAC-SHA-256, HKDF (in `crypto/`).
- Ed25519 signature / verify (in `crypto/`).
- VDF (in `crypto/`).
- UTF-8 decoder + NFC normalization (in `unicode/`).
- BCWL primitives (in `bootstrap/bcwl.c`).
- Windows kernel-mode driver dispatch helpers (`IoCreateDevice`, `IoCallDriver`, etc.).
- Standard `memcpy` / `memset` / `memcmp` (re-implemented in `core/mem.c`).

This entire set is closure-pinned in `STDLIB/extern_bootstrap.III`. After Stage 4, the SELF compiler's standard library re-implements each of these in III source, and the `extern` declarations become **vestigial** — retained only so that pre-Stage-4 binaries can continue to link against the BOOT C runtime during the migration window.

A future constitutional amendment may **remove** the `extern` mechanism entirely once Stage 4 is universally deployed. That amendment is not in scope for R1.

---

## §3. Why No Other ABIs

`c-sysv-x64` is reserved for future Linux/POSIX coexistence (not currently a target).

`vmrun-trampoline` is *not* a foreign-function ABI — it is a cross-ring constructor (per III-PHASES.md §3.4). Calls across rings use the cross-ring constructor catalogue, not `extern`.

`magic-msr` and `ioctl` are likewise cross-ring constructors, not foreign-function ABIs.

The current AMD-Zen + Windows target requires `c-msvc-x64` only.

---

## §4. Closure Identity Rule (R1.C1)

R1.C1 = `SHA-256(canonical_byte_form(this_file))`.

---

## §5. Conformance Criteria

- **C-ABI-1.** `c-msvc-x64` is the only admitted ABI name; other names are rejected at parse time.
- **C-ABI-2.** `extern` blocks appear only in R0 / R3 modules.
- **C-ABI-3.** Every extern call is wrapped in a synthesized cycle with `Compromise<MEDIUM>` inverse and `EXTERN_C_CALL` hexad.
- **C-ABI-4.** Higher-kinded III types are not admitted as extern arguments.

These are folded into III-CONFORMANCE.md §1 as an addendum to C-16 (IRPD-Only) — the extern bridge is the *one* exception, scoped narrowly.

---

## §6. Final Declaration

**One ABI. One bootstrap. No expansion without constitutional consent.**

*Sealed. R1.C1 = SHA-256(canonical_byte_form(this_file)).*
