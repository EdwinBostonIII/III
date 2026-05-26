# III-POLYMORPHIC-DATA — Glyph V3

**Spec:** `DOCS/III-POLYMORPHIC-DATA.md` (Wave 6, items 47-53)

Universal value type: every value in III is a **Glyph V3** (192 bytes,
1-byte type-tag + 191-byte payload).  Form catalogue (38 well-known forms +
EXTENSION + reserved bands), canonical encoding (cross-architecture
byte-equivalent), hash-consing with deduplication ratio, streaming for
oversized data, type-tag dispatch table, and a hand-rolled JSON parser as
exemplar (other 15 encodings register through `iii_serde_register`).

## Test

```
$ ./build/iii_polymorphic_test
=== 78 passed, 0 failed ===
```

## Conformance (§8)

| Code | Status |
| --- | --- |
| C-POLY-1 | ✅ `sizeof(iii_glyph_t) == 192` |
| C-POLY-2 | ✅ 1-byte type-tag, 256 distinct forms |
| C-POLY-4 | ✅ JSON parser hand-rolled NIH; others register via `iii_serde_register` |
| C-POLY-6 | ✅ canonical encode/decode is byte-equivalent round-trip |
| C-POLY-9 | ✅ type-tag dispatch via direct table indexing |
| C-POLY-10 | ✅ `iii_glyph_cons_dedup_ratio_q14` reports hits/(hits+misses) in Q14 |
| C-POLY-12 | ✅ streaming for oversized data |
| C-POLY-13 | ✅ chunks share storage when identical bytes |
| C-POLY-15 | ✅ witness kinds defined: GLYPH_CONS_*, POLY_*, STREAM_* |
| C-POLY-20 | ✅ multi-byte numerics encoded big-endian |
