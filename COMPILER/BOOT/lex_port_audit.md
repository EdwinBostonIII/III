# lex.c → lex.iii Port Audit (RITCHIE Stage 2.1.1)

Maps every `lex.c` function to its `.iii` realization, iiis-0 trap exposure, and
workaround. The port replaces the 260-LOC `lex.iii` stub (constants + externs
only) with the full lexer (~1700 LOC), then drops `lex_impl.c` from the iiis-1
build so the lexer self-hosts.

**Location note:** the plan named `STDLIB/scripts/lex_port_audit.md`; this doc
lives in `COMPILER/BOOT/` instead — next to the files it documents (a BOOT-lexer
port doc has no business in the stdlib build-script dir). Content unchanged.

---

## 1. Memory model

`ceiling.iii` proved the dialect: module-scope `var [T;N]` arrays + `*u8` params
with native `data[i]` indexing + `for i in 0..LIT` + `while` + `let mut` +
same-line `;` all work under iiis-0. The C-helper layer (`lex_runtime.c`) is
needed ONLY for **heap memory iiis-0 cannot deref natively**.

| Data | C form | .iii realization |
|---|---|---|
| token-kind-name table | `static const char*[]` | not ported as data — `iii_token_kind_name` is a `when`/if cascade returning `.rdata` literals (Stage-0 has no `const char*[]`) |
| keyword table (48) | `static const iii_keyword_t[]` | parallel module `var` arrays: `KW_NAME_BYTES:[u8;N]` (concatenated names) + `KW_OFF:[u32;49]` (offsets) + `KW_LEN:[u32;48]` + `KW_KIND:[u32;48]`; lookup walks them |
| modifier table (31) | `static const iii_keyword_t[]` | same parallel-array pattern (`MOD_*`) |
| SHA round constants | `static const uint32_t K[64]` | use `lex_runtime.c` SHA externs (already there); no K table in .iii |
| **lex state** | `malloc`'d `struct iii_lex_state` | `iii_lex_malloc_c(LEX_STATE_BYTES)` → u64 base; fields at fixed offsets via `iii_lex_read/write_u*_at_c` |
| **token** | caller `iii_token_t` (stack/array) | `*u8`-param buffer of `TOKEN_BYTES`; fields at fixed offsets (caller allocates) |
| **arena chunk** | `malloc`'d flexible-array struct | `iii_lex_malloc_c(hdr+cap)`; header fields (next,cap,used) at offsets 0/8/16, payload at offset 24 |
| **intern slots** | `calloc`'d slot array | `iii_lex_malloc_c(cap*SLOT_BYTES)`; each slot {start_byte,length,hash,id} at offsets 0/4/8/16 (24 bytes) |
| **error log / history / line_starts** | `realloc`'d arrays | `iii_lex_malloc_c` + manual grow (alloc new, memcpy via `iii_lex_memcpy_c`, free old) |

### Offset layouts (little-endian, packed; the III_*_OFF_* discipline)

```
TOKEN  (TOKEN_BYTES = 104, align 8) — VERIFIED via offsetof probe against the
live iii_token_t (gcc x64). These offsets are GROUND TRUTH; the C parser reads
lex.iii-produced tokens as this struct, so a one-byte error corrupts every parse.
  0   kind            u32          4   start_byte      u32
  8   end_byte        u32         12   line            u32
  16  col             u32         20   logical_line    u32
  24  logical_col     u32         28   (pad)           u32
  32  logical_path    u64 (addr, NULL=0)
  40  int_value       u64         48   int_suffix      u32
  52  mhash[32]       (52..84)
  84  string_len      u32         88   string_payload  u64 (addr)
  96  interned_id     u32        100   leading_doc     u32
  → TOKEN_BYTES = 104

LEX_STATE (offsets; src/len/path + scan pos + caches + dynamic-array tris):
  src u64@0, len u64@8, path u64@16, pos u64@24, line u32@32, col u32@36,
  logical_path u64@40, logical_line u32@48, logical_col u32@52,
  peek_valid u32@56, peek_status i32@60, peek_tok addr u64@64,
  modifier_pending u32@72, pending_doc u32@76, sealed u32@80,
  errors{ptr@88,count@96,cap@104}, line_starts{ptr@112,count@120,cap@128},
  history{ptr@136,count@144,cap@152}, stream_sha addr u64@160 (112-byte SHA state),
  intern{slots@168,cap@176,count@184,next_id@192},
  runtime_kw{ptr@200,count@208,cap@216}, err{code@224,byte@228,line@232,col@236,msg@240},
  arena{head@248,total@256}   → LEX_STATE_BYTES ≈ 264

ARENA_CHUNK:  next u64@0, cap u64@8, used u64@16, data@24
INTERN_SLOT (24): start_byte u32@0, length u32@4, hash u64@8, id u32@16
ERROR_REC (24):  code u32@0, byte u32@4, line u32@8, col u32@12, msg u64@16
```

(Offsets finalized at implementation; the table is the design intent — every
field reachable by `iii_lex_read/write_u*_at_c(base, OFF)`.)

---

## 2. Function-by-function port table

Idiom key: **MV**=module-var/pure-compute · **MH**=malloc+C-helper offsets ·
**PB**=`*u8`-param buffer · **EX**=delegate to lex_runtime extern · **CASCADE**=if/when cascade.

| C function | LOC | Idiom | iiis-0 trap exposure | Workaround |
|---|---|---|---|---|
| sha256 init/update/final/compress/update_u* | ~120 | EX | u32-round miscompile (CP-028) | use `iii_sha256_*` externs verbatim |
| `iii_rotr32` | 1 | (n/a — in C SHA) | — | — |
| `iii_chunk_new` | 10 | MH | flexible-array `data[]` | offset-24 payload; `iii_lex_malloc_c(24+cap)` |
| `iii_arena_alloc` | 16 | MH | n=0 sentinel; ptr arith | return fixed scratch addr for n=0; offset math in u64 |
| `iii_arena_destroy` | 8 | MH | walk+free | loop `iii_lex_free_c(next)` |
| `iii_fnv1a_64_bytes` | 8 | MV (PB) | u64 mul wrap | `*u8` param + `let mut h:u64`; `h*PRIME` wraps fine in u64 |
| `iii_intern_init/destroy` | 12 | MH | calloc | `iii_lex_malloc_c` (zeroed by calloc) |
| `iii_intern_grow` | 20 | MH | rehash, ptr arith | alloc new, re-probe, memcpy slots, free old |
| `iii_intern_get` | 24 | MH | open-addr probe; `memcmp(src+off,...)` | `iii_lex_memcmp_c`; mask idx to u32 before *SLOT_BYTES (u32-in-u64 trap) |
| `iii_lookup_keyword/modifier/runtime_kw` | 8 ea | MV/MH | linear scan + memcmp | parallel-array walk; `iii_lex_memcmp_c` for runtime (arena names) |
| char-class (`is_alpha`..`hex_value`) | 1 ea | MV | — | direct byte compares; **numeric byte literals** (no `'A'`) |
| `iii_at_end/peek_byte/peek_byte_at` | 3 ea | MV | — | read state pos + `data[pos+off]` via src `*u8` |
| `iii_record_line_start_at` | 10 | MH | realloc grow | manual grow of line_starts array |
| `iii_advance` | 12 | MH | `b=='\n'` byte cmp | numeric `10u8`; updates pos/line/col in state |
| `iii_record_error` | 28 | MH | realloc grow; struct copy | grow errors array; write ERROR_REC fields |
| `iii_skip_trivia` | 60 | MV+MH | **nested-block-comment depth loop**; no break | sentinel-flag `closed`/`done`; `while !done` |
| `iii_scan_doc_comment` | 44 | MH | line vs block branch | numeric bytes; sentinel-flag loop |
| `iii_scan_ident_or_keyword` | 70 | MH | modifier_pending; intern | offset math; calls lookups + intern_get |
| `iii_scan_int_suffix` | 40 | MV | local `ENTS[]` table; rollback | parallel arrays or inline if-cascade for 10 suffixes |
| `iii_scan_number` | 110 | MH | **D11 0x+64-hex→MHASH**; `_` sep; u64 overflow; hex→mhash nibble loop | careful u64; mhash bytes written to token buffer @72 |
| `iii_scan_string_inner` | 165 | MH | **2-pass (pre-scan len, decode into arena)**; escape switch; hex decode | sentinel-flag loops; numeric escape bytes; arena alloc |
| `iii_scan_string/prefixed_string` | 8 ea | MH | prefix byte | thin wrappers |
| `iii_handle_invalid_byte` | 8 | MH | — | record_error + advance |
| `iii_emit_single/double` | 18 ea | MH/PB | token field init | write TOKEN fields; memset mhash@72 via `iii_lex_memset_c` |
| `iii_next_internal` | 124 | MV+MH | **big dispatch switch**; maximal munch | if-cascade by leading byte; nested if for `<<`/`<=` etc. |
| `iii_next_with_metadata` | 52 | MH | logical-pos copy; doc-attach; modifier; history; stream-hash | switch on kind → if-cascade |
| `iii_lex_next/peek` | 12 ea | MH | peek-cache | read/write peek_valid + peek_tok buffer |
| `iii_history_append` | 12 | MH | realloc; token copy (96 B) | grow history; `iii_lex_memcpy_c(dst, tok, TOKEN_BYTES)` |
| `iii_token_canonical_update` | 26 | EX | feeds SHA fields | `iii_sha256_update_u*` per field + payload |
| `iii_token_mhash/stream_mhash` | 12 ea | EX/MH | SHA copy for stream | alloc temp 112-byte SHA state; init/update/final |
| `iii_lex_create` | 48 | MH | calloc state; init all fields | malloc LEX_STATE_BYTES; write defaults; init intern + SHA + line_starts[0]=0 |
| `iii_lex_destroy` | 12 | MH | free chains | free arena/intern/errors/line_starts/history/runtime_kw/state |
| `iii_lex_error_count/at/info` | 6 ea | MH | bounds | read errors array |
| `iii_lex_source_path/raw/raw_eq/fnv1a_64` | 6 ea | MV | — | src + offsets; `iii_lex_memcmp_c` |
| `iii_lex_locate/token_at_byte` | 16 ea | MH | **binary search** | std bsearch loop over line_starts/history (u64 lo/hi) |
| `iii_token_span_union` | 10 | PB | min/max | read two token buffers |
| `iii_lex_token_history_at/count` | 6 ea | MH | bounds | read history |
| `iii_lex_set_logical_position` | 6 | MH | — | write state logical_* |
| `iii_lex_register_keyword` | 38 | MH | dup-check; arena copy name; grow | lookups + arena alloc + grow runtime_kw |
| `iii_lex_arena_bytes/mhash` | 12 ea | MH/EX | chunk walk | read arena.total; SHA over chunk payloads |
| `iii_lex_seal` | 78 | MH | **pointer remap** (payloads + kw names); chunk concat | malloc block; per-chunk map (src/dst_off/used); rewrite history payload + runtime_kw addrs |
| `iii_token_kind_name` | 6 | CASCADE | — | if-cascade returning `.rdata` literals for the names actually used by callers |

**Total estimate:** ~1700 LOC of .iii (matches the stub's projection).

---

## 3. DRT-LEX-001 reconciliation (Contract C13)

The .iii kind space has 129 kinds (adds RESOLVE/INTENT/PATTERN/TRANSFORM
125–128); lex.h has 125. Resolution: in the sub-step that ports the keyword
table, ALSO extend `lex.h`'s enum append-only with `III_TOK_KW_RESOLVE..TRANSFORM`
before `III_TOK_KIND_COUNT` so the C and .iii kind-id spaces are identical
(Contract C7 closure-pin safety). The byte-equivalence gate runs on resolution-
word-free stage1_corpus sources (parity holds); whether the keyword TABLE
recognizes the 4 words is governed by the FROZEN-SPEC resolution surface (the
.iii table includes them per ADR-RES-005; lex.c's table is extended to match so
the two lexers agree).

---

## 4. iiis-0 trap register for this port (Contract C9)

Every occurrence gets an inline `/* TRAP: ... */` comment naming the trap:
- **u32-in-u64-slot** before pointer arithmetic (`idx*SLOT_BYTES`): mask `& 0xFFFFFFFFu64`.
- **`*u32` store width**: write multi-byte fields via `iii_lex_write_u32_c` (byte-exact), never a raw `*u32` store.
- **no `break`/`continue`**: every scan loop uses a sentinel flag driving the `while` condition.
- **single-line fn declarations**: all signatures one line, ≤4 args (split helpers if needed).
- **no char literals**: numeric byte values (`34u8` for `"`, `92u8` for `\`, `10u8` for `\n`, `47u8` `/`, `42u8` `*`).
- **no `const [T;N]`**: keyword tables are `var` + one-shot init.
- **no struct-pointer args**: state is the malloc'd LEX_STATE base (u64), passed as a scalar.
- **signed compares**: use `!=`/`==` against sentinels; avoid `<`/`>=` on i64.
- **em-dash / nested `/* */`**: ASCII-only comments; no nested block comments.
- **NON-NUL STRING LITERALS (discovered Stage 2.1.3)**: iiis-0 string literals (`"x" as *u8`) give correct bytes but are **NOT NUL-terminated** — they pack contiguously in .rodata. Safe for length-bounded `memcmp(ptr, lit, n)` (the keyword lookups rely on this, verified). UNSAFE to return as a C-string for printf/strcmp consumers. Any `const char*`-returning fn (iii_token_kind_name, and lex.c's source_path/error `message`) must serve from a **NUL-terminated names pool** (copy literal + explicit NUL into a `var [u8;N]`, return the pool offset). Probe-verified: a literal-return kind_name printed all names concatenated.
- **`/*` and `*/` SEQUENCES IN COMMENTS (discovered Stage 2.1.6 + 2.1.8)**: iiis-0's OWN comment lexer **counts nesting depth**, so a `/*` inside a block comment (even in a quoted string in the comment, e.g. describing `"/**"`) opens a nested level → "unterminated at EOF" (2.1.6). Conversely a `*/` inside a comment (e.g. `i*/u* suffix`) **closes the comment early** → the trailing text is lexed as code → "expected top-level declaration" (2.1.8). NEVER write the two-char sequences `/``*` or `*``/` inside comment text. Use prose ("slash-star", "the block-comment open marker", "triple-slash", "i8..i64 / u8..u64"). Audit before sealing: `grep -o '/\*' f.iii | wc -l` must equal `grep -o '\*/' f.iii | wc -l`. (Same family as the em-dash-in-comment trap.)
- **PARSER RECURSION-DEPTH CEILING ~8 (discovered Stage 2.1.9) [trap #5]**: iiis-0's recursive-descent parser bails with `parse recursion limit exceeded` when an expression/statement nests beyond roughly 8 levels. The first single-function string-escape ladder (nested `if {}` per escape class inside the scan loop) tripped it. **Workaround:** factor deep conditional logic into small helper functions (each ≤~6 nesting levels) — e.g. the escape decode was split into `lex_escape_byte` (flat `if`-cascade of early returns) + `lex_str_esc_advance` (single-level branch returning an i64 byte-count or `-1` sentinel). Keep scan loops flat: classify, then call a helper; never inline a multi-class branch tree inside an already-nested `while`.
- **STANDALONE-HARNESS BYTE-ARRAY RULE (Stage 2.1.9 lesson)**: byte-exact lexer verification must build input buffers as explicit `unsigned char[]` arrays, NOT C string literals — a bash `<<'EOF'` heredoc can collapse `\\n`→a real newline before gcc sees it, silently changing the bytes under test (cost: one false 5-fail run on the raw-string form). Error-returning cases assert `r == 0xffffffff` (a dedicated `ckerr`), never the success-path field check.
- **POSITIVE: iiis-0 string literals DO support `\"` (Stage 2.1.13)**: probe `"h\"...\"" ` compiled and read back bytes `104 34 46 46 46 34` (= `h"..."`). So error messages / literals containing double-quotes can be written directly with `\"` escapes (used for the two `h"..."` h-string error messages, which must byte-match lex.c). Still NOT NUL-terminated (the NUL-pool rule above stands).
- **MESSAGE-TEXT FIDELITY (Stage 2.1.13 catch)**: a ported error message must byte-match lex.c's exact text, not a paraphrase. §2.1.9 had written `h-string body must …`; lex.c says `h"..." body must …`. The byte-equivalence harness (compile shared dump with lex.c, then with lex.iii.o, diff) is what surfaced it — paraphrased messages pass a casual read but fail diff. Always diff messages against the C reference, never eyeball.

---

## 5. Sub-step plan (2.1.2–2.1.14)

Each ends with a build + the byte-identical-token-stream check vs lex.c on the
stage1_corpus (Contract C12), and re-reads the section before sealing (C10).

- **2.1.2** lex state struct offsets + `iii_lex_create`/`destroy` + arena (chunk_new/alloc/destroy).
- **2.1.3** keyword/modifier parallel-array tables + 3 lookups + `iii_token_kind_name` cascade. **(extends lex.h for DRT-LEX-001 here.)**
- **2.1.4** char-class + position helpers (at_end/peek/advance/record_line_start/record_error).
- **2.1.5** intern table (init/destroy/grow/get) + fnv1a_64.
- **2.1.6** trivia + doc-comment scan.
- **2.1.7** ident/keyword scan.
- **2.1.8** number scan (D11/D15/`_`/overflow) + int-suffix.
- **2.1.9** string scan (2-pass, all 4 prefixes, escapes).
- **2.1.10** operator/punct emit + invalid-byte + `next_internal` dispatch.
- **2.1.11** `next_with_metadata` + `next`/`peek` + history.
- **2.1.12** token canonical-update + token_mhash + stream_mhash + arena_mhash.
- **2.1.13** accessors (error log, raw, raw_eq, fnv1a_64, locate, span_union, token_at_byte/history/count, source_path, set_logical_position) + register_keyword.
- **2.1.14** seal (pointer remap) + full byte-equivalence run + add lex.iii to the iiis-1 build, drop lex_impl.c, rebuild iiis-1, verify iiis-0≡iiis-1 fixpoint, roll goldens per DRIFT.

**Acceptance (§2.1 Proof-of-Completion):** lex.iii ≥ 2000 LOC real impl; for every
stage1_corpus input, the token stream + stream-mhash from iiis-1-compiled lex.iii
is byte-identical to lex.c's; `build_iiis1.sh` no longer compiles `lex_impl.c`;
iiis-1 fixpoint holds; full corpus 254/0; `--check-deterministic` BIT-IDENTICAL.
