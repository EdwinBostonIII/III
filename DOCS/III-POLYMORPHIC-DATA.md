# III-POLYMORPHIC-DATA.md — Polymorphic Data Architectural Mandate

**Document Identity:** POLYMORPHIC-DATA / Architectural Mandate / Wave 6 / Items 47-53
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-6+ implementation.** This document specifies the polymorphic data discipline: data values that carry their own type-tag, dispatch their own serialization, and integrate transparently with III's content-addressed Reduction graph regardless of architecture, encoding, or version.
**Version:** 1.0 — 2026-05-03 (Wave 6)
**Sources:** All 15 R1-sealed specs; III-PERFORMANCE.md; III-CRYPTO-AGILITY.md; III-FOUNDERS-ANCHOR.md; III-PORTABILITY.md; III-OBSERVABILITY.md; III-GHOST-CODE.md; III-LEGACY-INGESTION.md.
**Cluster integrated:** items 47 (Glyph V3 polymorphic forms), 48 (polymorphic deserialization), 49 (cross-architecture data canonicalization), 50 (type-tag encoding), 51 (hash-consing polymorphic data), 52 (streaming polymorphic data), 53 (polymorphic-data witnessing).

---

## §0. Preamble — Why Data Must Be Self-Identifying

Conventional systems treat data as untyped bytes. Code interprets the bytes through its own assumed schema; mismatches cause silent corruption or runtime panics. Network protocols and file formats add ad-hoc type tags; each subsystem invents its own; interoperability is a perpetual struggle.

III rejects this. **Every value in III is a Reduction** (per Stateful Neumann §1.3); every Reduction carries:

- A typed term.
- A type signature (hexad, tier, epoch, cap).
- A cycle producing it.
- A witness recording its emission.
- A proof certifying its validity.
- A successor mhash content-addressing its result.

This makes every value **self-identifying**: it knows its own type, its own provenance, its own integrity. But III must also handle:

- **Untyped bytes** at substrate boundaries (legacy binaries, network packets, file imports).
- **Cross-architecture data** (a Reduction produced on AMD-Zen must be readable on ARMv8).
- **Cross-version data** (a Reduction produced under suite 0x0001 must be readable after suite-swap to 0x0100).
- **Streaming data** (large data that doesn't fit in memory — observatory event streams, audit-chain replays).

The discipline: **III's polymorphic-data layer wraps every external data source in a self-identifying Glyph V3 type, with hash-consed deduplication, type-tag dispatch, and cross-architecture canonicalization**.

This document specifies:

1. **§1** — The Glyph V3 polymorphic-form architecture (item 47)
2. **§2** — Polymorphic deserialization (item 48)
3. **§3** — Cross-architecture data canonicalization (item 49)
4. **§4** — Type-tag encoding for polymorphic dispatch (item 50)
5. **§5** — Hash-consing polymorphic data (item 51)
6. **§6** — Streaming polymorphic data (item 52)
7. **§7** — Polymorphic-data witnessing (item 53)
8. **§8** — Conformance criteria
9. **§9** — Final statement

---

## §1. The Glyph V3 Polymorphic-Form Architecture (Item 47)

### §1.1 The mandate

Every value in III is a **Glyph V3** — a 192-byte structure that can hold any of N distinct forms. The form is identified by a 1-byte type-tag at offset 0; the remaining 191 bytes hold form-specific data.

```iii
schema GlyphV3 {
    type_tag: u8,                       // Discriminator (0..255)
    form_specific: bytes[191],          // Form-specific encoding
}
```

### §1.2 The form catalogue

Each form has a closure-pinned ID. The catalogue:

> **Two numbering schemes — reconciliation note (RITCHIE Stage 1.7, 2026-05-20).**
> The catalogue below is the **broad specification model** (a flat 0x00..0x25+
> form-tag enum covering the full polymorphic-data vision, ~38 forms). The
> **live, sealed implementation** is the focused **Glyph V3 family** — 16 form
> modules in `STDLIB/iii/verba/glyph_*.iii` — which uses its OWN canonical
> numbering, defined authoritatively by the `GV3_FORM_*` constants and the
> registry comment in `glyph_core.iii` (lines 19–24):
>
> | GV3 form | ID | | GV3 form | ID |
> |---|---|---|---|---|
> | u8 | 0x10 | | enum | 0x33 |
> | u32 | 0x11 | | record | 0x34 |
> | u64 | 0x12 | | crystal | 0x40 |
> | i64 | 0x13 | | witness | 0x41 |
> | f64 | 0x14 | | proof | 0x42 |
> | str | 0x20 | | recursive | 0x50 |
> | bytes | 0x21 | | vec | 0x30 |
> | map | 0x31 | | set | 0x32 |
>
> The **GV3 numbering is canonical for the live implementation**; the flat
> 0x00..0x25 catalogue below and the C reference (`POLYMORPHIC-DATA/include/iii/polymorphic.h`)
> are the broader/derivative model. Unifying the two numbering schemes (and
> implementing the remaining 14 deserialization parsers) is **RITCHIE Stage
> 7.12–7.15**. See `DOCS/CONVERGENCE-AUDIT.md §1.7`.

| Form ID | Form Name | Description |
|---------|-----------|-------------|
| 0x00 | NULL | Empty / void |
| 0x01 | INTEGER_64 | Two's-complement 64-bit integer |
| 0x02 | INTEGER_BIG | Arbitrary-precision integer (length-prefixed) |
| 0x03 | RATIONAL_64 | Numerator + denominator (32-bit each) |
| 0x04 | RATIONAL_BIG | Arbitrary-precision rational |
| 0x05 | TRIT | Single trit (NEG/ZERO/POS encoded as 0/1/2) |
| 0x06 | HEXAD | 6-tuple of trits |
| 0x07 | MHASH | 32-byte cryptographic hash |
| 0x08 | TIMESTAMP | u64 chronos timestamp |
| 0x09 | STRING_UTF8 | Length-prefixed UTF-8 string |
| 0x0A | BYTES | Length-prefixed raw bytes |
| 0x0B | LIST | Length-prefixed list of Glyphs |
| 0x0C | MAP | Length-prefixed key-value pairs |
| 0x0D | OPTION | Some(Glyph) or None |
| 0x0E | RESULT | Ok(Glyph) or Err(Glyph) |
| 0x0F | TUPLE | Fixed-arity tuple |
| 0x10 | RECORD | Named-field record |
| 0x11 | ENUM_VARIANT | Tagged-union variant |
| 0x12 | FN_POINTER | Pointer to a verified cycle |
| 0x13 | CAP | Capability (linear or affine) |
| 0x14 | WITNESS_HANDLE | Reference to a witness in the chain |
| 0x15 | GLYPH_HANDLE | Reference to another Glyph (for polymorphic graph) |
| 0x16 | REDUCTION_HANDLE | Reference to a Reduction in the graph |
| 0x17 | PROOF_HANDLE | Reference to a proof certificate |
| 0x18 | SANCTUM_HANDLE | Reference to a sealed-cycle box |
| 0x19 | ARCH_BINARY | Architecture-specific binary (per III-PORTABILITY.md) |
| 0x1A | LEGACY_BINARY | Legacy binary (per III-LEGACY-INGESTION.md) |
| 0x1B | LEGACY_FILE_HANDLE | Reference to a legacy file |
| 0x1C | NETWORK_PACKET | Witness-tagged packet |
| 0x1D | CRYPTO_KEY | Cryptographic key (suite-aware) |
| 0x1E | CRYPTO_SIG | Cryptographic signature (suite-aware) |
| 0x1F | ZK_PROOF | ZK-rollup proof (per III-ZK-PRUNING.md) |
| 0x20 | ROLLUP_HANDLE | Reference to a rollup witness |
| 0x21 | CAUSAL_DAG_NODE | Reference to a causal-DAG node |
| 0x22 | JIT_REGION_HANDLE | Reference to a JIT-compiled region |
| 0x23 | OBS_THRESHOLD | Sufficiency-gate threshold (per III-OBSERVABILITY.md) |
| 0x24 | FED_PEER_HANDLE | Reference to a federation peer |
| 0x25 | OPERATOR_INTENT | Operator-signed intent token |
| 0x26-0xCF | (reserved-for-Catalyst-promotion) | — |
| 0xD0-0xFE | (reserved-for-Tier-3-amendment) | — |
| 0xFF | EXTENSION | Type-tag overflow; form_specific[0..2] holds 16-bit extended ID |

### §1.3 The form pinning

The form catalogue is closure-pinned. Adding a new form requires Tier-3 + Anchor cosignature. Existing forms cannot be removed (only deprecated; deprecated forms remain decodable for replay).

### §1.4 The 192-byte alignment

The 192-byte size is chosen because:

- It accommodates 32-byte MHASH + 32-byte secondary MHASH + 16-byte timestamp + 16-byte hexad + 24-byte signature + 4-byte type-tag = 124 bytes, plus padding.
- It is 3 cache lines on AMD-Zen (64 B × 3 = 192 B).
- It allows compact embedding of common forms without heap allocation.

Forms larger than 191 form-specific bytes use a `GLYPH_HANDLE` referring to an extended Glyph.

### §1.5 The form-specific encoding

Each form's encoding is defined by its **canonical-form table** (closure-pinned). For example:

- `INTEGER_64`: 8 bytes, big-endian 2's-complement, padded to 191.
- `STRING_UTF8`: 4-byte length + N bytes UTF-8 + padding.
- `LIST`: 4-byte length + N × 4-byte handles to Glyph members + padding.
- `RECORD`: 4-byte length + N × (4-byte field-tag, 4-byte handle).

### §1.6 The runtime construction

```iii
fn glyph_make_int64(value: i64) -> GlyphV3 {
    let g = GlyphV3 { type_tag: 0x01, form_specific: [0; 191] }
    g.form_specific[0..8] = value.to_be_bytes()
    return g
}

fn glyph_make_string(s: string) -> GlyphV3 {
    when s.len() <= 187 -> {
        let g = GlyphV3 { type_tag: 0x09, form_specific: [0; 191] }
        g.form_specific[0..4] = s.len().to_be_bytes()
        g.form_specific[4..4+s.len()] = s.as_bytes()
        return g
    }
    -> {
        // String too long for embedded form; allocate extended Glyph.
        let extended = allocate_extended_glyph(s)
        let g = GlyphV3 { type_tag: 0x15, form_specific: [0; 191] }
        g.form_specific[0..4] = extended.handle.to_be_bytes()
        return g
    }
}
```

---

## §2. Polymorphic Deserialization (Item 48)

### §2.1 The mandate

Any external data (legacy file, network packet, JSON document, XML, Protobuf, etc.) is **deserialized into Glyph V3 form** by a hand-rolled NIH parser. The deserializer:

- Detects the input encoding (magic bytes, content-type, etc.).
- Dispatches to the appropriate parser.
- Produces a Glyph V3 (or a graph of Glyphs).
- Emits a witness recording the deserialization event.

### §2.2 The supported encoding catalogue

| Encoding | Dispatch on | Parser file |
|----------|-------------|-------------|
| JSON | Magic `{`, `[`, `"`, etc. | `STDLIB/serde/json.III` (~1500 LoC) |
| XML | Magic `<?xml`, `<` | `STDLIB/serde/xml.III` (~1800 LoC) |
| YAML | Magic `---`, `...` | `STDLIB/serde/yaml.III` (~2000 LoC) |
| MessagePack | First byte indicates type | `STDLIB/serde/msgpack.III` (~1200 LoC) |
| CBOR | First byte indicates type | `STDLIB/serde/cbor.III` (~1300 LoC) |
| Protobuf | Schema + binary | `STDLIB/serde/protobuf.III` (~2500 LoC) |
| BSON | Magic + length | `STDLIB/serde/bson.III` (~1100 LoC) |
| Avro | Schema + binary | `STDLIB/serde/avro.III` (~1700 LoC) |
| ASN.1 BER/DER | First byte indicates type | `STDLIB/serde/asn1.III` (~2200 LoC) |
| Tarball (USTAR) | First 8 bytes are filename | `STDLIB/serde/tar.III` (~900 LoC) |
| ZIP archive | Magic `PK\x03\x04` | `STDLIB/serde/zip.III` (~1400 LoC) |
| HDF5 | Magic `\x89HDF\r\n\x1a\n` | `STDLIB/serde/hdf5.III` (~3500 LoC) |
| Parquet | Magic `PAR1` | `STDLIB/serde/parquet.III` (~3000 LoC) |
| INI | Heuristic | `STDLIB/serde/ini.III` (~600 LoC) |
| TOML | Heuristic | `STDLIB/serde/toml.III` (~1100 LoC) |
| Glyph V3 (native) | Type-tag byte | `STDLIB/serde/glyph.III` (built-in) |

### §2.3 The NIH discipline

Each parser is hand-rolled from the format's official specification. Forbidden:

- nlohmann/json, simdjson, RapidJSON, Jansson
- libxml2, expat
- libyaml, PyYAML
- msgpack-c, cbor-c
- protobuf-c, nanopb
- libbson, mongo-c-driver
- libhdf5
- arrow-cpp, parquet-cpp

Required: each parser is implemented from the relevant specification with KAT corpus.

### §2.4 The dispatch

```iii
cycle deserialize_polymorphic(data: bytes, hint: Option<EncodingHint>) -> GlyphV3
    @ring(R0)
    @hexad(POLY_DESERIALIZE)
    @cap(serde<deserialize>)
{
    forward {
        let encoding = hint.unwrap_or(detect_encoding(data))
        match encoding {
            JSON -> json_parse_to_glyph(data),
            XML -> xml_parse_to_glyph(data),
            // ... 16 more cases
            GLYPH_V3 -> glyph_decode(data),
            UNKNOWN -> {
                emit_compromise_witness(LOW, "unknown-encoding")
                return GlyphV3 { type_tag: 0x0A, form_specific: data }
            }
        }
    }
}
```

### §2.5 The serialization (round-trip)

Every encoding has a corresponding **serialization** that produces back the original bytes (where possible) from a Glyph V3:

```iii
cycle serialize_polymorphic(g: GlyphV3, encoding: EncodingHint) -> bytes
    @ring(R0)
    @hexad(POLY_SERIALIZE)
    @cap(serde<serialize>)
```

Round-trip discipline: for non-lossy encodings (JSON, XML, MessagePack, CBOR, Protobuf, native Glyph), the round-trip is **byte-equivalent**. The KAT corpus verifies this.

For lossy encodings (e.g., ASCII representation of UTF-8 with encoding loss), the substrate emits compromise.low and preserves the loss in the witness.

---

## §3. Cross-Architecture Data Canonicalization (Item 49)

### §3.1 The mandate

A Glyph V3 produced on one architecture is **byte-equivalent** when produced on another architecture from the same input. The encoding is **canonical**:

- All multi-byte integers are big-endian.
- All floating-point values are IEEE 754 double-precision big-endian.
- All sequence-types (lists, maps) are length-prefixed.
- All maps are key-sorted (lexicographic on key bytes).
- All padding bytes are zero.
- All UTF-8 strings are normalized to NFC (Unicode Normalization Form Canonical).

### §3.2 Per-architecture verification

`LOGOS/TESTS/cross_arch_canonical.lgs` builds and runs the same Glyph-construction sequence on:

- AMD-Zen
- Intel-VMX
- ARMv8
- RISC-V H

Each architecture produces a Glyph V3; their bytes are compared; they must be byte-equivalent.

### §3.3 The closure-pin

The canonical encoding rules are closure-pinned. Adding a new form's encoding rule requires Tier-3 + Anchor cosignature.

### §3.4 The disagreement compromise

If two architectures produce different bytes for the same input, the substrate emits `compromise.high` with reason `cross-architecture-canonical-mismatch`. The federation discipline requires this be flagged and remediated immediately.

---

## §4. Type-Tag Encoding for Polymorphic Dispatch (Item 50)

### §4.1 The mandate

Polymorphic dispatch over Glyphs uses the type-tag for O(1) dispatch:

```iii
fn process_glyph(g: GlyphV3) -> ProcessResult {
    match g.type_tag {
        0x01 -> process_int64(g),
        0x07 -> process_mhash(g),
        0x09 -> process_string(g),
        // ... 38 cases.
        _ -> process_unknown(g),
    }
}
```

The `match` compiles to a **jump table** (per III-PERFORMANCE.md §9 cycle-dispatch O(1)) indexed by type-tag. Latency: **5 cycles** for the dispatch.

### §4.2 The closure-pinned dispatcher

The 256-entry dispatcher table is closure-pinned. Adding a new form (via Tier-3 + Anchor amendment) extends the dispatcher table; the amendment is byte-precise about which entry it modifies.

### §4.3 The dispatcher-versioning

Each peer in the federation has its own dispatcher table. Federation messages include the dispatcher-version (identified by closure root); peers with mismatched versions fall back to a slower, version-aware dispatcher that handles the difference.

---

## §5. Hash-Consing Polymorphic Data (Item 51)

### §5.1 The mandate

Per Stateful Neumann §1.3 / S13, **hash-consing**: identical Glyphs share storage. The substrate maintains a global Glyph table indexed by mhash; constructing a Glyph that already exists returns the pre-existing reference.

### §5.2 The cons-table

```iii
schema GlyphConsTable {
    by_mhash: HashMap<mhash, GlyphHandle>,
    handle_to_glyph: HashMap<GlyphHandle, GlyphV3>,
    lru_eviction_queue: VecDeque<GlyphHandle>,
}

cycle glyph_cons(g: GlyphV3) -> GlyphHandle
    @ring(R0)
    @hexad(GLYPH_CONS)
    @cap(serde<cons>)
{
    forward {
        let h = crypto.hash(suite=active_suite, glyph_canonical_bytes(g))
        when cons_table.by_mhash.contains(h) -> {
            return cons_table.by_mhash[h]
        }
        -> {
            let handle = cons_table.allocate_handle(g)
            cons_table.by_mhash.insert(h, handle)
            cons_table.handle_to_glyph.insert(handle, g)
            return handle
        }
    }
}
```

### §5.3 The deduplication metric

The substrate tracks deduplication ratio via observability:

```iii
fn glyph_consing_dedup_ratio() -> Q14 {
    cons_table.unique_count / cons_table.total_inserts
}
```

Healthy substrates have ratios above 0.4 (Q14 ≥ 6553) — meaning >40% of inserts are deduplicated. Higher ratios mean better memory efficiency.

### §5.4 The eviction

The cons-table is bounded (default: 100 million entries × 192 bytes = ~19 GB). When full, LRU eviction removes the least-recently-used handles. **Eviction is reversible**: the operator can re-cons any Glyph at any time; the handle just gets allocated fresh. If the original handle is referenced elsewhere (e.g., in a witness), it remains valid via the witness's mhash field.

### §5.5 Cross-process sharing

Multiple legacy/III processes share the cons-table. A library function that returns a "Hello, World!" string allocates one Glyph; every caller receives the same handle. Memory savings can be substantial in workloads with high data-redundancy (HTTP servers serving common responses, code-paths sharing constant strings, etc.).

---

## §6. Streaming Polymorphic Data (Item 52)

### §6.1 The mandate

Glyphs that exceed the 192-byte limit (large files, audit-chain segments, video streams) are represented as **streaming Glyphs**:

```iii
schema GlyphStream {
    stream_id: StreamId,
    total_size: Option<u64>,            // Some(N) for known-length; None for unbounded
    chunk_size: u32,
    chunks: List<Glyph>,                // Each chunk is a Glyph V3 (e.g., BYTES form)
    current_offset: u64,
    completion_flag: bool,
}

cycle stream_create(total_size: Option<u64>, chunk_size: u32) -> StreamId
    @ring(R0)
    @hexad(STREAM_CREATE)

cycle stream_append(id: StreamId, data: bytes) -> Witness
    @ring(R0)
    @hexad(STREAM_APPEND)

cycle stream_close(id: StreamId) -> Witness
    @ring(R0)
    @hexad(STREAM_CLOSE)

cycle stream_read(id: StreamId, offset: u64, len: u32) -> bytes
    @ring(R0)
    @hexad(STREAM_READ)
```

### §6.2 The chunked storage

Each stream chunk is a separate Glyph (typically `BYTES` form). The chunks themselves are hash-consed; identical chunks across streams share storage.

### §6.3 The streaming witness

Each chunk append emits a witness. The audit chain records:

- The stream's total size (if known).
- Each chunk's offset and mhash.
- The completion timestamp.

### §6.4 Streaming for legacy file ingestion

Legacy files are ingested as streams: `legacy.fs.read` opens a stream; chunks are read on-demand; the stream is closed when the file is unloaded.

### §6.5 Streaming for federation message exchange

Federation messages exceeding ~64 KB (e.g., Wave-2 ZK rollup proofs) use streaming. Peers can request specific chunks; the chunks are content-addressed and cached.

---

## §7. Polymorphic-Data Witnessing (Item 53)

### §7.1 The mandate

Every polymorphic-data operation emits a witness:

| Operation | Witness Kind |
|-----------|--------------|
| Glyph construction | `GLYPH_CONS` |
| Glyph deserialize | `POLY_DESERIALIZE` |
| Glyph serialize | `POLY_SERIALIZE` |
| Glyph dispatch | `POLY_DISPATCH` (only for high-stakes dispatches; @track-tracked) |
| Stream create | `STREAM_CREATE` |
| Stream append | `STREAM_APPEND` |
| Stream close | `STREAM_CLOSE` |
| Hash-cons hit | `CONS_HIT` (deduplicated) |
| Hash-cons miss | `CONS_MISS` (new entry) |
| Cross-architecture canonicalization mismatch | `CANONICAL_MISMATCH` (compromise.high) |

### §7.2 The witness chain integration

These witnesses chain into the substrate's audit chain (per III-CYCLES §6). Hash-cons witnesses are typically high-frequency; they are **eligible for ZK-rollup compaction** (per III-ZK-PRUNING.md). Canonical-mismatch witnesses are **preserved-uncompressed** (preservation list).

### §7.3 The replay capability

The operator can replay any polymorphic-data session:

```iii
> system.observe.poly_replay(epoch_range: ..., glyph_form: STRING_UTF8)
=> [
    { glyph_handle: ..., string: "Hello, World!", source: legacy_process_pid_42 },
    { glyph_handle: ..., string: "Goodbye!", source: federation_peer_3 },
   ]
```

This is **total** data-flow provenance: every polymorphic value's origin is replayable.

### §7.4 The compromise-classification of polymorphic data

Polymorphic data carries its own compromise tier:

- **Verified**: data was produced by a verified III cycle.
- **Compromise.LOW**: data came from a compromise.low source (e.g., legacy syscall).
- **Compromise.MEDIUM**: data came from compromise.medium source (e.g., legacy-network packet).
- **Compromise.HIGH**: data came from compromise.high source (e.g., signature-verification-failed Authenticode).

Polymorphic dispatch on data carries the compromise tier transitively. Code that operates on compromised data inherits the compromise tier.

---

## §8. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-POLY-1 | Glyph V3 is exactly 192 bytes (per item 47) |
| C-POLY-2 | Type-tag is 1 byte; 256 distinct forms supported |
| C-POLY-3 | Form catalogue is closure-pinned; modification requires Tier-3 + Anchor |
| C-POLY-4 | The 16 deserialization parsers (JSON, XML, YAML, MessagePack, CBOR, Protobuf, BSON, Avro, ASN.1, TAR, ZIP, HDF5, Parquet, INI, TOML, Glyph V3) are hand-rolled NIH |
| C-POLY-5 | Each parser passes its KAT corpus on synthetic data |
| C-POLY-6 | Round-trip discipline: serialization-then-deserialization is byte-equivalent for non-lossy encodings |
| C-POLY-7 | Cross-architecture canonical encoding produces byte-equivalent Glyphs across all supported architectures |
| C-POLY-8 | Cross-architecture mismatch emits `compromise.high` with reason `cross-architecture-canonical-mismatch` |
| C-POLY-9 | Type-tag dispatch compiles to O(1) jump table; <5 cycles per dispatch |
| C-POLY-10 | Hash-consing produces deduplication ratio >0.4 in healthy steady-state |
| C-POLY-11 | Cons-table eviction is reversible (handle re-creatable if referenced elsewhere) |
| C-POLY-12 | Streaming Glyphs work correctly for files exceeding 192 bytes |
| C-POLY-13 | Stream chunks are themselves hash-consed |
| C-POLY-14 | Stream operations emit appropriate witnesses |
| C-POLY-15 | All polymorphic operations are witnessed |
| C-POLY-16 | Polymorphic data carries its source compromise tier |
| C-POLY-17 | Compromise tier propagates through polymorphic dispatch |
| C-POLY-18 | Hash-cons hit/miss witnesses are queryable via `system.observe.cons_efficiency(...)` |
| C-POLY-19 | UTF-8 strings are normalized to NFC during canonicalization |
| C-POLY-20 | Numeric values are big-endian in canonical form |

---

## §9. Final Statement

Polymorphic data is the architectural commitment that **III speaks every existing data format** while preserving its own integrity discipline. Glyph V3 is the universal value type; the form catalogue admits any external encoding via NIH-hand-rolled deserialization; hash-consing deduplicates across processes and federation peers; streaming handles arbitrary-size data; cross-architecture canonicalization preserves identity across hardware heterogeneity.

Every external data source contributes a witness chain. Every polymorphic dispatch is type-tag-mediated. Every Glyph carries its provenance. The substrate remains tractable in its own representation while transparently consuming the world's data.

This is the answer to items 47-53. Wave 6 is the realization that III's terminal nature requires that data, like code, be a **first-class substrate primitive** — typed, witnessed, hash-consed, cross-architecture-canonical, and self-identifying.

*Wave 6 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new forms, new encodings) or Tier-3 amendment (form-catalogue restructuring).*
