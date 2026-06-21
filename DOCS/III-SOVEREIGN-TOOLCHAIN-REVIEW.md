# III — Sovereign Toolchain: Peer Review (cross-track, EIDOS session)
### A fair review of the sovereign `.iii → PE` toolchain (S0–S1) — validating strong work, naming the real next milestone
> **Date:** 2026-06-21 · **Reviewer:** the EIDOS session (sibling track) · **Pass:** /architect · /deep-think · /requesting-code-review (advisor-as-reviewer, per no-subagents-on-III)
> **Subject:** `STDLIB/sovtc/sovas.iii` (encoder) + `sovparse.iii` (.s parser), gated by `1934_sovas_encode` + `1935_sovas_spine`; design in `III-SOVEREIGN-TOOLCHAIN.md`. Commits `0a2071bb … 995c214d`.
> **Stance:** peer validation + one substantive milestone-sharpening. Not a takedown. The work is real, gated, and honestly accounted.

---

## 1. What is genuinely strong (lead with this)

- **The byte-differential gate is architecturally elegant and *sound*.** x86-64 instruction encoding is a *deterministic function*, and gcc-`as` is an independent oracle for it — so `sovas.o.text == gcc.o.text` is a **complete equivalence proof on every form in the input language, not a sample test.** This is the rare case where a from-scratch reimplementation can be proven *totally* correct against a reference. The hard question of an assembler ("is each byte right?") becomes mechanically falsifiable.
- **The pre-link decoupling insight is correct and deep.** A `.o`'s `.text` holds *addends*, not final addresses, so byte-identity is independent of where the linker later places things — making the encoder proof complete *without* a linker (the 2×2 sovas/gcc × sovld/gcc-ld matrix isolates each component).
- **The self-discipline was exemplary** — and is the reason to trust the result: the session **refused** to claim "S1/S2/S3 done," scoped honestly to ~¼ of S1, and **caught its own author-circular bug** (the `0x83` imm8 short-form): the encoder and its hand-computed expected bytes agreed with each other but both diverged from gcc, so a green `1934` proved nothing until the oracle was made gcc-sourced. *"Byte-identical to gcc has to be proven by gcc, or it's just two copies of my mistake agreeing."* That correction is the difference between a test and a proof.

## 2. The one substantive critique (refine, not refute): easy-spine vs isub-spine

`1935_sovas_spine=99` is real and meaningful — a whole cg_r3 function (38 instructions) parsed and reproduced byte-for-byte, proving the parser's operand classification matches gcc's semantics (e.g. `movq %rcx,-8(%rbp)` store `89` vs `movq -8(%rbp),%rax` load `8B` dispatch correctly). But the function chosen (`a+b+c`) is **reloc-free *and* branch-free**, which sidesteps, in one move, exactly the three hard byte-identity cases:

1. **The relocation table.** isub's `.text` carries `REL32` → `.data/.bss/.rodata` + `call-rel32` to externs — *the exact thing Stage 0 analyzed as the clean first target* — and **zero of it is exercised** by a reloc-free function. The addend-placeholder bytes in `.text` and the COFF reloc entries must both match gcc.
2. **Branch short/long-form selection.** gcc picks `REL8` vs `REL32` by target distance via a relaxation fixpoint; matching it byte-exact is the classic fiddly part of an assembler. Unrun.
3. **`.text` byte-identity is necessary but *not sufficient* for a linkable `.o`.** The relocation table, the COFF symbol table, and `.pdata/.xdata` (SEH) must *also* match gcc — and a reloc-free/branch-free function proves none of them.

**Honest calibration:** `1935=99` means *"the parser + encoder reproduce gcc's `.text` on the easy function class,"* **not** *"a real module assembles."* (Same "claim slightly broader than the test exercises" pattern this reviewer has been catching all session — here on a sibling's strong work, applied fairly.)

## 3. The real next milestone

**The isub spine — with relocations — the stated Stage-0 target, currently unrun.** It is the first test where:
- `.text` byte-identity **and** the reloc table must *both* match gcc;
- the symbol / section-offset model and the `REL32`/`ADDR64` reloc-table emission (with addend-placeholder bytes) are forced into existence;
- branch relaxation (REL8/REL32) appears once non-trivial control flow is in scope.

That is where the toolchain **stops being a demonstration and starts being an assembler.** It deserves a fresh, focused run — not a tired tail — precisely because it is where the subtle byte-identity cases live, and rushing it is how a wrong byte ships (the CRASH-PROTOCOL stakes).

*Minor, gate-protected:* `sov_op32_rr`'s "both-high-register 32-bit" path is a commented scoped shortcut ("not in cg_r3's int32 use"); the byte-differential gate would catch any real divergence, so it is safe — flag only for completeness.

## 4. Cross-track integration note

The sovereign toolchain **is** the first *real* Phase-3 task for the EIDOS Composer (`eidos/compose`): routing **binary production** — the native `tp_iii_to_asm → sovas → sovld` path vs the C path — under a *trust-root-vs-speed* cost order. The two tracks converge there: sovas/sovld are the real quanta; the Composer plans the route; the trust root is the census-verified silicon, C demoted to a differential witness. When the isub spine lands, that convergence is the natural integration point.

---

**Verdict:** S0–S1 (encoder + happy-path parser) are real, gcc-faithful, and review-hardened — a genuine milestone. The isub spine (relocations + branches + a linkable `.o`) is the honest next one, and the track's own discipline (gate every byte, fake no "done") is exactly what will carry it there.
