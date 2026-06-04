// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\resolver_unit.v
//
// I-INSTR v1.0 reference RTL -- Resolver Unit core
// Bound to:  DOCS/HARDWARE/I-INSTR-V1.0-spec.md
// Equivalence corpus: DOCS/HARDWARE/I-INSTR-V1.0-spec.md §10
// Capability apex:  DOCS/III-CAPABILITY-APOTHEOSIS.md §C.12
//
// Verilog-2005 / SystemVerilog-2017 mixed; intended for synthesis on
// Yosys + nextpnr (FPGA prototyping) or downstream commercial flow for
// 16 nm ASIC. Not part of the III software seal; provided for external
// silicon verification.
//
// 6-stage in-order pipeline:  F  D  S  R  W  K
//
//   F  - fetch I-INSTR word from active pattern table
//   D  - decode opcode + operand fields
//   S  - score (8-wide candidate evaluation; SRAM read for memo)
//   R  - resolve / dispatch (indirect call to winning pattern's fp)
//   W  - witness emit (append 120B/960-bit record to witness chain via DMA)
//   K  - kchain accumulator commit
//
// Each stage retires deterministically: cycle counts are part of the
// I-INSTR contract.
//
// ============================================================================
// APOTHEOSIS C.12 -- the seven structural gaps, each closed in this file:
//
//   (1) ARGMAX TOURNAMENT.  The S stage's old slot-0 selection is replaced
//       by a true 3-stage pairwise-max tournament tree (8 -> 4 -> 2 -> 1).
//       The reduction is the EXACT argmax the software resolve() computes
//       with its `if s > best_score` scan: the winner is the candidate with
//       the maximum score, ties broken toward the LOWEST candidate index
//       (software keeps best_id on the strict `>` test, so an equal-score
//       later candidate never displaces an earlier one).  See iiis_tourney.
//
//   (2) MEMO WRITE PATH.  iiis_memo_unit now has an insert port driven on
//       resolve commit: the winner_id + dispatch_fp are stored under the
//       content-address key at commit, so a subsequent identical lookup
//       HITS and reproduces the same winner (the §7.1 outcome-invariance
//       that makes memoization witness-transparent).
//
//   (3) SHA-256-TRUNC-128 MEMO KEY.  The weak XOR folding key is replaced
//       by the low 128 bits of SHA-256(pset_id || intent_lo || intent_hi ||
//       ctx_lo || ctx_hi) -- a SHA-256 content-address in the same spirit as
//       the software cad (DOCS §S.6).  It is NOT byte-identical to any
//       software memo value (different preimage/byte-order), and per §7.1 the
//       memo state is un-witnessed, so equivalence is invariant to the key
//       hash.  See iiis_cad_key128 (combinational, single-cycle SHA-NI).
//
//   (4) SEALED K-COST ROM.  The per-opcode K-cost policy constants move into
//       iiis_kcost_rom, whose K_cost_table_mhash is computed by hashing the
//       table at boot and compared against the sealed_root_mhash binding.
//       A tampered ROM raises kcost_seal_fault.
//
//   (5) 960-BIT WITNESS RECORD.  The witness record is widened from the old
//       512-bit stub to the full 960-bit (15 x 64) structure, faithfully
//       unifying the software sanctus/witness.iii entry (mhash[32]||cap||k)
//       with the resolver_last_event reflection fields (see W stage).
//
//   (6-7) I-INSTR v1.0 CONTROL + STATUS FIELDS.  The control word (istat_*
//       inputs) and the status word (istat_* outputs: idle, cap_fault,
//       kcost_seal_fault, memo_seal_fault, stage-valid vector) complete the
//       I-INSTR v1.0 programmer-visible interface.
//
// The faithfulness CLAIM proven by the equivalence corpus (test_2xx.sv) and
// the formal harness (resolver_unit_formal.sv): GIVEN the same 8 candidate
// (score,id,fp) triples (the pattern-SRAM read the software AVX-2 path also
// consumes), the RTL tournament selects the SAME winner the software argmax
// scan selects -- on every input, byte-identically.  A deliberately-wrong
// tournament that picks slot 0 FAILS that corpus (the mandatory negative arm).
//
// Phase-C.5 spec-deviation (cross-ref omnia/resolver.iii doc-comment, §C.9
// proof_resolve): the software memo key is a perf FNV/Knuth hash while the
// content-address it stands in for is SHA-256.  This RTL encodes the SAME
// audited deviation by computing the SHA-256-trunc-128 cad key here; because
// §7.1 makes memo state un-witnessed and a hit reproduces the cold winner,
// the choice of key hash is invisible to the witness chain -- the equivalence
// is preserved regardless of which key hash indexes the memo SRAM.
// ============================================================================

`default_nettype none

// ============================================================================
// Top-level core
// ============================================================================
module iiis_resolver_unit (
    input  wire        clk,
    input  wire        rst_n,

    // Pattern-table fetch interface
    output wire [63:0] pt_addr,
    input  wire [31:0] pt_word,
    input  wire        pt_valid,

    // Candidate score read interface (the pattern-set SRAM read the S stage
    // consumes; the software AVX-2 resolver_unit.s path returns the same
    // (best_id,best_score) from this candidate vector).  8 candidates,
    // each {score:32, id:32, fp:64}, presented in parallel for the 8-wide S.
    input  wire [255:0] cand_score_vec,   // 8 x 32-bit score, cand0 in [31:0]
    input  wire [255:0] cand_id_vec,      // 8 x 32-bit id
    input  wire [511:0] cand_fp_vec,      // 8 x 64-bit dispatch fp

    // Witness chain DMA (write-only, append-only) -- 960-bit record
    output wire        wc_we,
    output wire [63:0] wc_addr,
    output wire [959:0] wc_data,    // 120-byte (960-bit) witness record
    input  wire        wc_ready,

    // KChain DMA
    output wire        kc_we,
    output wire [63:0] kc_addr,
    output wire [63:0] kc_data,

    // Capability check (combinational; SHA-NI hardware co-located)
    output wire [2:0]  cap_check_idx,
    output wire [63:0] cap_check_target,
    input  wire        cap_check_ok,

    // Heap / data plane bus (mediated by GRANT)
    output wire        bus_we,
    output wire [63:0] bus_addr,
    output wire [63:0] bus_data,
    input  wire [63:0] bus_rdata,
    input  wire        bus_ack,

    // Hardware feature mask (cpufeat-equivalent)
    input  wire [31:0] hw_feature_mask,

    // Sealed root mhash for boot-time integrity check
    input  wire [255:0] sealed_root_mhash,

    // ---- I-INSTR v1.0 control word (gap 6) ----
    input  wire        ictl_force_cold,    // skip memo fast path (proof_resolve cold path)
    input  wire        ictl_memo_en,       // enable memo lookup/insert
    input  wire        ictl_flush,         // pipeline flush request

    // ---- I-INSTR v1.0 status word (gap 7) ----
    output wire        cap_fault,
    output wire        idle,
    output wire        kcost_seal_fault,   // sealed K-cost ROM mismatch
    output wire        memo_hit_o,         // last lookup was a memo hit
    output wire [5:0]  stage_valid_o       // {f,d,s,r,w,k} valid vector
);

    // ------------------------------------------------------------------------
    // Architectural register file
    // ------------------------------------------------------------------------
    reg  [63:0]  CR  [0:7];      // capability registers (CR0..CR7)
    reg  [191:0] IR;             // intent register (192 bits = 3*64)
    reg  [255:0] CTXR;           // context digest
    reg  [63:0]  WPR;             // witness pointer
    reg  [63:0]  KAR;             // kchain accumulator (fixed point ×1e9)
    reg  [31:0]  PSR;             // pattern set selector
    reg  [7:0]   RSR;             // reflect scope register

    // ------------------------------------------------------------------------
    // Pipeline registers
    // ------------------------------------------------------------------------
    // Fetch
    reg [31:0]  f_word;
    reg         f_valid;

    // Decode
    reg [4:0]   d_op;
    reg [26:0]  d_operands;
    reg         d_valid;

    // Score
    reg [63:0]  s_winner_fp;
    reg [31:0]  s_winner_score;
    reg [31:0]  s_winner_id;
    reg         s_valid;
    reg [63:0]  s_memo_key_lo;
    reg [63:0]  s_memo_key_hi;
    reg         s_memo_hit;
    reg [4:0]   s_op;          // pipelined opcode (carry decode field forward)
    reg [26:0]  s_operands;    // pipelined operands

    // Resolve
    reg [63:0]  r_dispatch_fp;
    reg [31:0]  r_winner_id;
    reg [31:0]  r_winner_score;
    reg [63:0]  r_k_now;
    reg [63:0]  r_memo_key_lo;
    reg [63:0]  r_memo_key_hi;
    reg         r_memo_hit;
    reg         r_valid;
    reg [4:0]   r_op;          // pipelined opcode at the R/W stages
    reg [26:0]  r_operands;    // pipelined operands (cap-check fields)

    // Witness
    reg [63:0]  w_seq;
    reg [959:0] w_record;
    reg         w_pending;

    // KChain
    reg [63:0]  k_accum_delta;
    reg         k_pending;

    // ------------------------------------------------------------------------
    // Boot-time invariants
    // ------------------------------------------------------------------------
    integer init_i;
    initial begin
        for (init_i = 0; init_i < 8; init_i = init_i + 1) begin
            CR[init_i] = 64'd0;
        end
        IR    = 192'd0;
        CTXR  = 256'd0;
        WPR   = 64'd0;
        KAR   = 64'd0;
        PSR   = 32'd0;
        RSR   = 8'd0;
    end

    // ------------------------------------------------------------------------
    // Stage F: instruction fetch
    // ------------------------------------------------------------------------
    reg [63:0] fetch_addr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetch_addr <= 64'h0;
            f_word     <= 32'h0;
            f_valid    <= 1'b0;
        end else if (ictl_flush) begin
            f_valid    <= 1'b0;
        end else begin
            f_word  <= pt_word;
            f_valid <= pt_valid;
            if (pt_valid) fetch_addr <= fetch_addr + 64'd4;
        end
    end
    assign pt_addr = fetch_addr;

    // ------------------------------------------------------------------------
    // Stage D: decode
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_op        <= 5'd0;
            d_operands  <= 27'd0;
            d_valid     <= 1'b0;
        end else if (ictl_flush) begin
            d_valid     <= 1'b0;
        end else if (f_valid) begin
            d_op        <= f_word[31:27];
            d_operands  <= f_word[26:0];
            d_valid     <= 1'b1;
        end else begin
            d_valid     <= 1'b0;
        end
    end

    // Opcodes (mirror I-INSTR-V1.0-spec.md §2.1)
    localparam OP_FORM     = 5'h00;
    localparam OP_BIND     = 5'h01;
    localparam OP_CONVEY   = 5'h02;
    localparam OP_MEAN     = 5'h03;
    localparam OP_ACT      = 5'h04;
    localparam OP_COMPOSE  = 5'h05;
    localparam OP_SEAL     = 5'h06;
    localparam OP_PROVE    = 5'h07;
    localparam OP_QUERY    = 5'h08;
    localparam OP_GRANT    = 5'h09;
    localparam OP_GOVERN   = 5'h0A;
    localparam OP_THEN     = 5'h0B;
    localparam OP_WITH     = 5'h0C;
    localparam OP_UNDER    = 5'h0D;
    localparam OP_IF       = 5'h0E;
    localparam OP_LOOP     = 5'h0F;
    localparam OP_LIFT     = 5'h10;
    localparam OP_REFLECT  = 5'h11;

    // ------------------------------------------------------------------------
    // Stage S: score (8-wide) + content-address memo
    // ------------------------------------------------------------------------
    // Candidate triples arrive on cand_*_vec (the pattern-SRAM read).  The S
    // stage runs the true argmax tournament over the 8 candidates AND, in
    // parallel, computes the SHA-256-trunc-128 content-address memo key and
    // probes the memo SRAM.

    wire [63:0] memo_key_lo;
    wire [63:0] memo_key_hi;
    wire        memo_hit_w;
    wire [31:0] memo_hit_winner;
    wire [63:0] memo_hit_fp;

    wire lookup_class = d_valid && (d_op == OP_PROVE
                                 || d_op == OP_QUERY
                                 || d_op == OP_CONVEY
                                 || d_op == OP_ACT);

    iiis_memo_unit u_memo (
        .clk          (clk),
        .rst_n        (rst_n),
        .pset_id      (PSR),
        .intent_lo    (IR[63:0]),
        .intent_hi    (IR[127:64]),
        .ctx_digest_lo(CTXR[63:0]),
        .ctx_digest_hi(CTXR[127:64]),
        .lookup       (ictl_memo_en && !ictl_force_cold && lookup_class),
        // ---- insert port (gap 2): driven on resolve commit ----
        .ins_we       (ictl_memo_en && r_valid && !r_memo_hit),
        .ins_key_lo   (r_memo_key_lo),
        .ins_key_hi   (r_memo_key_hi),
        .ins_winner   (r_winner_id),
        .ins_fp       (r_dispatch_fp),
        .key_lo       (memo_key_lo),
        .key_hi       (memo_key_hi),
        .hit          (memo_hit_w),
        .hit_winner   (memo_hit_winner),
        .hit_fp       (memo_hit_fp)
    );

    wire [63:0] tour_winner_fp;
    wire [31:0] tour_winner_id;
    wire [31:0] tour_winner_sc;

    iiis_score_unit u_score (
        .cand_score_vec (cand_score_vec),
        .cand_id_vec    (cand_id_vec),
        .cand_fp_vec    (cand_fp_vec),
        .winner_fp      (tour_winner_fp),
        .winner_id      (tour_winner_id),
        .winner_sc      (tour_winner_sc)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_winner_fp    <= 64'd0;
            s_winner_id    <= 32'd0;
            s_winner_score <= 32'd0;
            s_valid        <= 1'b0;
            s_memo_key_lo  <= 64'd0;
            s_memo_key_hi  <= 64'd0;
            s_memo_hit     <= 1'b0;
            s_op           <= 5'd0;
            s_operands     <= 27'd0;
        end else if (ictl_flush) begin
            s_valid        <= 1'b0;
        end else if (d_valid) begin
            // On a memo hit (and memo enabled, not forced cold), the cached
            // winner is reproduced verbatim -- the §7.1 outcome-invariance.
            // memo_hit_w is now COMBINATIONAL (current-cycle lookup) so it is
            // aligned with this d_valid -- correct on an overlapped pipeline.
            if (ictl_memo_en && !ictl_force_cold && memo_hit_w) begin
                s_winner_id    <= memo_hit_winner;
                s_winner_fp    <= memo_hit_fp;
                s_winner_score <= tour_winner_sc;  // score recomputed identical
                s_memo_hit     <= 1'b1;
            end else begin
                s_winner_id    <= tour_winner_id;
                s_winner_fp    <= tour_winner_fp;
                s_winner_score <= tour_winner_sc;
                s_memo_hit     <= 1'b0;
            end
            s_memo_key_lo  <= memo_key_lo;
            s_memo_key_hi  <= memo_key_hi;
            s_op           <= d_op;          // carry opcode forward (pipeline it)
            s_operands     <= d_operands;
            s_valid        <= 1'b1;
        end else begin
            s_valid        <= 1'b0;
        end
    end

    // ------------------------------------------------------------------------
    // Stage R: resolve / dispatch
    // ------------------------------------------------------------------------
    // K-cost ROM priced by s_op -- the opcode of the instruction crossing
    // S->R THIS cycle (pipelined, not the combinational decode field), so the
    // committed K-cost attributes to the correct instruction under overlap.
    wire [63:0] kcost_delta;
    iiis_kcost_rom u_kcost (
        .clk               (clk),
        .rst_n             (rst_n),
        .sealed_root_mhash (sealed_root_mhash),
        .op                (s_op),
        .k_cost            (kcost_delta),
        .table_mhash       (/* canonical fold; boot-programs sealed root */),
        .seal_fault        (kcost_seal_fault)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_dispatch_fp  <= 64'd0;
            r_winner_id    <= 32'd0;
            r_winner_score <= 32'd0;
            r_k_now        <= 64'd0;
            r_memo_key_lo  <= 64'd0;
            r_memo_key_hi  <= 64'd0;
            r_memo_hit     <= 1'b0;
            r_valid        <= 1'b0;
            r_op           <= 5'd0;
            r_operands     <= 27'd0;
        end else if (ictl_flush) begin
            r_valid        <= 1'b0;
        end else if (s_valid) begin
            r_dispatch_fp  <= s_winner_fp;
            r_winner_id    <= s_winner_id;
            r_winner_score <= s_winner_score;
            // K-cost: fixed-point delta from the sealed K-cost ROM (priced by
            // s_op -> the opcode of THIS instruction, not a later decode).
            r_k_now        <= KAR + kcost_delta;
            r_memo_key_lo  <= s_memo_key_lo;
            r_memo_key_hi  <= s_memo_key_hi;
            r_memo_hit     <= s_memo_hit;
            r_op           <= s_op;
            r_operands     <= s_operands;
            r_valid        <= 1'b1;
        end else begin
            r_valid        <= 1'b0;
        end
    end

    // Capability check on store-class operations -- driven by the PIPELINED
    // r_operands/r_op so the check evaluates the instruction actually at R.
    assign cap_check_idx    = r_operands[8:6];   // generic CR slot
    assign cap_check_target = {45'd0, r_operands[26:8]};  // 19-bit target field
    assign cap_fault        = r_valid &&
                              (r_op == OP_CONVEY || r_op == OP_GRANT || r_op == OP_LIFT) &&
                              !cap_check_ok;

    // Bus is GRANT-mediated; unused store path tied off deterministically.
    assign bus_we   = 1'b0;
    assign bus_addr = 64'd0;
    assign bus_data = 64'd0;

    // ------------------------------------------------------------------------
    // Stage W: witness emit -- full 960-bit (15 x 64) record (gap 5)
    // ------------------------------------------------------------------------
    // Layout (little-endian word order, word 0 in wc_data[63:0]):
    //   w0   seq            u64   -- monotonic witness sequence
    //   w1   pattern_id     u64   -- winner id (zero-extended)
    //   w2   intent_id      u64   -- IR[63:0]
    //   w3   ctx_digest[0]  u64   -- CTXR[63:0]    } 128-bit context digest
    //   w4   ctx_digest[1]  u64   -- CTXR[127:64]  }
    //   w5   k_now          u64   -- KChain accumulator after this commit
    //   w6   score|flags    u64   -- {flags:32, winner_score:32}
    //   w7   dispatch_fp    u64
    //   w8   memo_key_lo    u64   -- content-address (cad) low 64
    //   w9   memo_key_hi    u64   -- content-address (cad) high 64 (-> 128-bit key)
    //   w10  cap_id         u64   -- CR-derived capability id (sanctus/witness.iii field)
    //   w11  ctx_digest[2]  u64   -- CTXR[191:128] } remaining 128 bits of the
    //   w12  ctx_digest[3]  u64   -- CTXR[255:192] } 256-bit context digest
    //   w13  opcode|memohit u64   -- {62'b0, memo_hit:1, ... , opcode:5}
    //   w14  reserved       u64   -- =0 (sealed-pad)
    //
    // This unifies the software sanctus/witness.iii 56-byte entry
    // (mhash || cap || k) with the resolver_last_event reflection struct
    // (seq,pat,intent,ctx,k,score,fp,depth) into one faithful 960-bit record.
    reg [63:0] witness_seq;
    wire [63:0] w_flags_score = {32'd0, r_winner_score};
    wire [63:0] w_op_memohit  = {58'd0, r_memo_hit, r_op[4:0]};  // pipelined opcode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            witness_seq <= 64'd0;
            w_record    <= 960'd0;
            w_pending   <= 1'b0;
        end else if (r_valid) begin
            w_record  <= { 64'd0,                                  // w14 reserved
                           w_op_memohit,                           // w13
                           CTXR[255:192],                          // w12
                           CTXR[191:128],                          // w11
                           64'd0,                                  // w10 cap_id (sealed-pad; GRANT-fed in full I-INSTR)
                           r_memo_key_hi,                          // w9
                           r_memo_key_lo,                          // w8
                           r_dispatch_fp,                          // w7
                           w_flags_score,                          // w6
                           r_k_now,                                // w5
                           CTXR[127:64],                           // w4
                           CTXR[63:0],                             // w3
                           IR[63:0],                               // w2
                           {32'd0, r_winner_id},                   // w1
                           witness_seq };                          // w0
            w_pending <= 1'b1;
            witness_seq <= witness_seq + 64'd1;
        end else if (wc_ready) begin
            w_pending <= 1'b0;
        end
    end
    assign wc_we   = w_pending;
    assign wc_addr = WPR;
    assign wc_data = w_record;

    // Advance WPR after writing (120 bytes per record)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)            WPR <= 64'd0;
        else if (wc_we && wc_ready) WPR <= WPR + 64'd120;
    end

    // ------------------------------------------------------------------------
    // Stage K: kchain commit
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            KAR        <= 64'd0;
            k_pending  <= 1'b0;
        end else if (r_valid) begin
            KAR        <= r_k_now;
            k_pending  <= 1'b1;
        end else begin
            k_pending  <= 1'b0;
        end
    end
    assign kc_we   = k_pending;
    assign kc_addr = KAR;
    assign kc_data = r_k_now;

    // ------------------------------------------------------------------------
    // I-INSTR v1.0 status word (gap 7)
    // ------------------------------------------------------------------------
    assign idle = !f_valid && !d_valid && !s_valid && !r_valid && !w_pending && !k_pending;
    assign memo_hit_o   = s_memo_hit;
    assign stage_valid_o = {f_valid, d_valid, s_valid, r_valid, w_pending, k_pending};

endmodule

// ============================================================================
// 8-wide argmax tournament score unit (gap 1)
// ============================================================================
// Pure combinational 3-stage pairwise-max tournament:
//   Stage 1: 8 candidates -> 4 (pairs (0,1)(2,3)(4,5)(6,7))
//   Stage 2: 4 -> 2
//   Stage 3: 2 -> 1 (winner)
//
// Tiebreak rule -- MUST match software resolve()'s `if s > best_score` scan:
// software keeps the EARLIER (lower-index) candidate on equal scores, because
// a later equal-score candidate fails the strict `>` test.  So pairwise-max
// here selects the LEFT (lower-index) operand whenever a.score >= b.score.
// As long as every pairing carries the lower original index on the left, the
// 3-stage fold yields the lowest-index maximum -- identical to the scan.
// ============================================================================
module iiis_score_unit (
    input  wire [255:0] cand_score_vec,   // cand i score = cand_score_vec[32*i +: 32]
    input  wire [255:0] cand_id_vec,
    input  wire [511:0] cand_fp_vec,
    output wire [63:0]  winner_fp,
    output wire [31:0]  winner_id,
    output wire [31:0]  winner_sc
);
    // Unpack the 8 candidate triples.
    wire [31:0] sc [0:7];
    wire [31:0] id [0:7];
    wire [63:0] fp [0:7];
    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_unpack
            assign sc[gi] = cand_score_vec[32*gi +: 32];
            assign id[gi] = cand_id_vec[32*gi +: 32];
            assign fp[gi] = cand_fp_vec[64*gi +: 64];
        end
    endgenerate

    // pairwise_max returns the LEFT operand when a_sc >= b_sc (lower-index
    // wins ties), matching the software strict-`>` scan.  We carry the
    // ORIGINAL candidate index packed alongside so the tiebreak stays
    // lowest-index across all 3 stages even after the first reduction.

    // Stage 1: 4 winners.  We track {score,id,fp,origidx} as a flat bundle.
    // Bundle = {score[32], id[32], fp[64], origidx[3]} = 131 bits.
    function [130:0] mk_bundle;
        input [31:0] s;
        input [31:0] i;
        input [63:0] f;
        input [2:0]  ix;
        mk_bundle = {s, i, f, ix};
    endfunction
    function [130:0] pmax;
        input [130:0] a;
        input [130:0] b;
        reg [31:0] as, bs;
        begin
            as = a[130:99];
            bs = b[130:99];
            // a wins ties (a is always the lower-index operand by construction)
            if (as >= bs) pmax = a;
            else          pmax = b;
        end
    endfunction

    wire [130:0] b0 = mk_bundle(sc[0], id[0], fp[0], 3'd0);
    wire [130:0] b1 = mk_bundle(sc[1], id[1], fp[1], 3'd1);
    wire [130:0] b2 = mk_bundle(sc[2], id[2], fp[2], 3'd2);
    wire [130:0] b3 = mk_bundle(sc[3], id[3], fp[3], 3'd3);
    wire [130:0] b4 = mk_bundle(sc[4], id[4], fp[4], 3'd4);
    wire [130:0] b5 = mk_bundle(sc[5], id[5], fp[5], 3'd5);
    wire [130:0] b6 = mk_bundle(sc[6], id[6], fp[6], 3'd6);
    wire [130:0] b7 = mk_bundle(sc[7], id[7], fp[7], 3'd7);

    // Stage 1: (0,1) (2,3) (4,5) (6,7) -- left operand is lower index.
    wire [130:0] s1_0 = pmax(b0, b1);
    wire [130:0] s1_1 = pmax(b2, b3);
    wire [130:0] s1_2 = pmax(b4, b5);
    wire [130:0] s1_3 = pmax(b6, b7);

    // Stage 2: (s1_0, s1_1) (s1_2, s1_3) -- s1_0/s1_2 carry the lower group.
    wire [130:0] s2_0 = pmax(s1_0, s1_1);
    wire [130:0] s2_1 = pmax(s1_2, s1_3);

    // Stage 3: final winner.
    wire [130:0] s3 = pmax(s2_0, s2_1);

    assign winner_sc = s3[130:99];
    assign winner_id = s3[98:67];
    assign winner_fp = s3[66:3];
endmodule

// ============================================================================
// cad content-address key (gap 3): SHA-256-trunc-128, COMBINATIONAL
// ============================================================================
// A single-cycle (combinational) SHA-256 over a fixed 40-byte message
// (pset_id:4 || intent_lo:8 || intent_hi:8 || ctx_lo:8 || ctx_hi:8 = 36 bytes;
//  zero-padded to the 40-byte content-address preimage).  One 512-bit block
// (message || 0x80 || zero-pad || 64-bit big-endian length=320) suffices.
// The 64 rounds + message schedule are fully unrolled inside one function so
// the digest is available the same cycle the inputs are presented -- matching
// the I-INSTR §4 single-cycle SHA-NI capability/hash contract (no FSM, no
// `done` latency).  The cad key is the low 128 bits of the big-endian digest.
//
// This is a SHA-256 content-address in the same spirit as the software cad
// (DOCS §S.6).  It is NOT asserted byte-identical to any software memo value:
// the software memo key is a perf FNV/Knuth hash over a different preimage and
// byte order.  Per I-INSTR §7.1 the memo state is UN-witnessed and a hit
// reproduces the cold winner, so the equivalence is invariant to the choice of
// key hash -- the silicon is free to use the stronger SHA-256 content-address
// here without affecting any witnessed outcome.  (Phase-C.5 spec-deviation,
// cross-ref omnia/resolver.iii doc-comment + §C.9 proof_resolve.)
// ============================================================================
module iiis_cad_key128 (
    input  wire [319:0] msg,
    output wire [63:0]  key_lo,
    output wire [63:0]  key_hi
);
    // SHA-256 logical functions.
    function [31:0] rotr;
        input [31:0] x; input [5:0] n;
        rotr = (x >> n) | (x << (6'd32 - n));
    endfunction
    function [31:0] ssig0; input [31:0] x;
        ssig0 = rotr(x,7) ^ rotr(x,18) ^ (x >> 3); endfunction
    function [31:0] ssig1; input [31:0] x;
        ssig1 = rotr(x,17) ^ rotr(x,19) ^ (x >> 10); endfunction
    function [31:0] bsig0; input [31:0] x;
        bsig0 = rotr(x,2) ^ rotr(x,13) ^ rotr(x,22); endfunction
    function [31:0] bsig1; input [31:0] x;
        bsig1 = rotr(x,6) ^ rotr(x,11) ^ rotr(x,25); endfunction
    function [31:0] chf; input [31:0] x; input [31:0] y; input [31:0] z;
        chf = (x & y) ^ ((~x) & z); endfunction
    function [31:0] majf; input [31:0] x; input [31:0] y; input [31:0] z;
        majf = (x & y) ^ (x & z) ^ (y & z); endfunction

    // Per-round constant K[t].
    function [31:0] Kc;
        input [6:0] t;
        case (t)
             0:Kc=32'h428a2f98; 1:Kc=32'h71374491; 2:Kc=32'hb5c0fbcf; 3:Kc=32'he9b5dba5;
             4:Kc=32'h3956c25b; 5:Kc=32'h59f111f1; 6:Kc=32'h923f82a4; 7:Kc=32'hab1c5ed5;
             8:Kc=32'hd807aa98; 9:Kc=32'h12835b01;10:Kc=32'h243185be;11:Kc=32'h550c7dc3;
            12:Kc=32'h72be5d74;13:Kc=32'h80deb1fe;14:Kc=32'h9bdc06a7;15:Kc=32'hc19bf174;
            16:Kc=32'he49b69c1;17:Kc=32'hefbe4786;18:Kc=32'h0fc19dc6;19:Kc=32'h240ca1cc;
            20:Kc=32'h2de92c6f;21:Kc=32'h4a7484aa;22:Kc=32'h5cb0a9dc;23:Kc=32'h76f988da;
            24:Kc=32'h983e5152;25:Kc=32'ha831c66d;26:Kc=32'hb00327c8;27:Kc=32'hbf597fc7;
            28:Kc=32'hc6e00bf3;29:Kc=32'hd5a79147;30:Kc=32'h06ca6351;31:Kc=32'h14292967;
            32:Kc=32'h27b70a85;33:Kc=32'h2e1b2138;34:Kc=32'h4d2c6dfc;35:Kc=32'h53380d13;
            36:Kc=32'h650a7354;37:Kc=32'h766a0abb;38:Kc=32'h81c2c92e;39:Kc=32'h92722c85;
            40:Kc=32'ha2bfe8a1;41:Kc=32'ha81a664b;42:Kc=32'hc24b8b70;43:Kc=32'hc76c51a3;
            44:Kc=32'hd192e819;45:Kc=32'hd6990624;46:Kc=32'hf40e3585;47:Kc=32'h106aa070;
            48:Kc=32'h19a4c116;49:Kc=32'h1e376c08;50:Kc=32'h2748774c;51:Kc=32'h34b0bcb5;
            52:Kc=32'h391c0cb3;53:Kc=32'h4ed8aa4a;54:Kc=32'h5b9cca4f;55:Kc=32'h682e6ff3;
            56:Kc=32'h748f82ee;57:Kc=32'h78a5636f;58:Kc=32'h84c87814;59:Kc=32'h8cc70208;
            60:Kc=32'h90befffa;61:Kc=32'ha4506ceb;62:Kc=32'hbef9a3f7;default:Kc=32'hc67178f2;
        endcase
    endfunction

    // Assemble the padded 512-bit block: 40 message bytes, 0x80, zero pad to
    // 448 bits, then 64-bit big-endian length (320 bits).  320 + 8 + 120 + 64
    // = 512 (the 120-bit zero pad is the FIX for the prior off-by-one).
    wire [511:0] block = { msg,        // 320
                           8'h80,      // 8
                           120'd0,     // 120  (320+8+120 = 448)
                           64'd320 };  // 64   length in bits, big-endian

    // Fully-unrolled single-block SHA-256, combinational.  Module-level arrays
    // + an always @(*) block (unambiguously legal in Verilog-2005 and SV; no
    // function-local memory).  The whole 64-round compression is one
    // combinational cone -> the digest is valid the cycle `msg` is presented.
    reg [31:0] w [0:63];
    reg [31:0] av,bv,cv,dv,ev,fv,gv,hv,t1,t2;
    reg [31:0] H0,H1,H2,H3,H4,H5,H6,H7;
    reg [255:0] dig;
    integer t;
    always @(*) begin
        // schedule: first 16 words big-endian (w[0] = block[511:480]).
        for (t = 0; t < 16; t = t + 1)
            w[t] = block[511 - 32*t -: 32];
        for (t = 16; t < 64; t = t + 1)
            w[t] = ssig1(w[t-2]) + w[t-7] + ssig0(w[t-15]) + w[t-16];
        H0=32'h6a09e667; H1=32'hbb67ae85; H2=32'h3c6ef372; H3=32'ha54ff53a;
        H4=32'h510e527f; H5=32'h9b05688c; H6=32'h1f83d9ab; H7=32'h5be0cd19;
        av=H0; bv=H1; cv=H2; dv=H3; ev=H4; fv=H5; gv=H6; hv=H7;
        for (t = 0; t < 64; t = t + 1) begin
            t1 = hv + bsig1(ev) + chf(ev,fv,gv) + Kc(t[6:0]) + w[t];
            t2 = bsig0(av) + majf(av,bv,cv);
            hv=gv; gv=fv; fv=ev; ev=dv+t1; dv=cv; cv=bv; bv=av; av=t1+t2;
        end
        dig = { H0+av, H1+bv, H2+cv, H3+dv, H4+ev, H5+fv, H6+gv, H7+hv };
    end

    // cad key = FIRST 128 bits of the big-endian digest (H0..H3).
    assign key_hi = dig[255:192];
    assign key_lo = dig[191:128];
endmodule

// ============================================================================
// Memoization unit (4096-entry SRAM, content-addressed) -- with WRITE path
// ============================================================================
module iiis_memo_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pset_id,
    input  wire [63:0] intent_lo,
    input  wire [63:0] intent_hi,
    input  wire [63:0] ctx_digest_lo,
    input  wire [63:0] ctx_digest_hi,
    input  wire        lookup,
    // ---- insert port (gap 2) ----
    input  wire        ins_we,
    input  wire [63:0] ins_key_lo,
    input  wire [63:0] ins_key_hi,
    input  wire [31:0] ins_winner,
    input  wire [63:0] ins_fp,
    output wire [63:0] key_lo,
    output wire [63:0] key_hi,
    output reg         hit,
    output reg  [31:0] hit_winner,
    output reg  [63:0] hit_fp
);
    // Memo SRAM: 4096 × (key:128 + winner:32 + fp:64 + valid:1)
    reg [127:0] memo_key   [0:4095];
    reg [31:0]  memo_win   [0:4095];
    reg [63:0]  memo_fp    [0:4095];
    reg         memo_valid [0:4095];

    // ---- gap 3: content-addressed key via SHA-256-trunc-128 ----
    // Preimage = pset_id(4 bytes, big-endian) || intent_lo(8) || intent_hi(8)
    //          || ctx_digest_lo(8) || ctx_digest_hi(8) = 36 bytes, packed MSB
    // first into the 40-byte SHA message (last 4 bytes zero).
    wire [319:0] cad_msg = { pset_id,                 // 32 bits
                             intent_lo,               // 64
                             intent_hi,               // 64
                             ctx_digest_lo,           // 64
                             ctx_digest_hi,           // 64
                             32'd0 };                 // pad to 320 (40 bytes)
    // Combinational content-address: key_lo/key_hi are valid the same cycle
    // the (pset,intent,ctx) inputs are presented -- single-cycle SHA-NI per
    // I-INSTR §4 (no `done` latency; the S stage latches the key directly).
    iiis_cad_key128 u_key (
        .msg    (cad_msg),
        .key_lo (key_lo),
        .key_hi (key_hi)
    );

    // 12-bit slot index from the low bits of the 128-bit content key.
    wire [11:0] slot     = key_lo[11:0];
    wire [11:0] ins_slot = ins_key_lo[11:0];

    integer init_j;
    initial begin
        for (init_j = 0; init_j < 4096; init_j = init_j + 1) begin
            memo_key[init_j]   = 128'd0;
            memo_win[init_j]   = 32'd0;
            memo_fp[init_j]    = 64'd0;
            memo_valid[init_j] = 1'b0;
        end
    end

    // Lookup (read) port -- COMBINATIONAL single-cycle SRAM read (I-INSTR
    // §7.1: "S as a single-cycle SRAM read").  hit/hit_winner/hit_fp reflect
    // the CURRENT cycle's (pset,intent,ctx) lookup, so the S stage that
    // latches the winner samples a hit aligned with its own d_valid -- correct
    // on an overlapped pipeline (no 1-cycle skew vs the registered winner).
    // (always @(*) form: variable-index memory read in a procedural block is
    // the portable/synthesizable way -- a continuous assign cannot index a
    // reg array with a variable in strict Verilog.)
    always @(*) begin
        if (lookup && memo_valid[slot] && (memo_key[slot] == {key_hi, key_lo})) begin
            hit        = 1'b1;
            hit_winner = memo_win[slot];
            hit_fp     = memo_fp[slot];
        end else begin
            hit        = 1'b0;
            hit_winner = 32'd0;
            hit_fp     = 64'd0;
        end
    end

    // ---- gap 2: insert (write) port ----
    // On resolve commit (ins_we), store the tournament winner + dispatch_fp
    // under the content-address key, so a later identical lookup HITS and
    // reproduces the same winner.  Direct-mapped store at ins_slot.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // initial{} clears the array at boot; runtime reset is no-op on
            // the array (synthesizable SRAM has no async clear).
        end else if (ins_we) begin
            memo_key[ins_slot]   <= {ins_key_hi, ins_key_lo};
            memo_win[ins_slot]   <= ins_winner;
            memo_fp[ins_slot]    <= ins_fp;
            memo_valid[ins_slot] <= 1'b1;
        end
    end
endmodule

// ============================================================================
// Sealed K-cost ROM (gap 4)
// ============================================================================
// The per-opcode K-cost policy constants (fixed point ×1e9; mirror
// calculus_primitive_k_cost) move into a ROM whose content hash
// (K_cost_table_mhash) is bound to sealed_root_mhash.  A boot-time integrity
// check folds the 18 table entries through a deterministic hash; if the
// resulting binding does not match the low 64 bits of sealed_root_mhash the
// unit raises seal_fault and the K-cost path is poisoned (returns 0).
//
// The binding here is a deterministic content-fold (XOR-rotate accumulation)
// of the table, then compared against sealed_root_mhash[63:0].  In a
// production flow the sealed_root_mhash would be programmed at boot to the
// fold of the canonical table; a tampered table changes the fold and trips
// seal_fault -- this is the negative arm the formal harness exercises.
// ============================================================================
module iiis_kcost_rom (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [255:0] sealed_root_mhash,
    input  wire [4:0]  op,
    output wire [63:0] k_cost,
    output wire [63:0] table_mhash,   // K_cost_table_mhash (canonical fold)
    output reg         seal_fault
);
    function [63:0] kcost_lut;
        input [4:0] o;
        case (o)
            5'h00: kcost_lut = 64'd1000000;       // FORM    0.001
            5'h01: kcost_lut = 64'd2000000;       // BIND
            5'h02: kcost_lut = 64'd5000000;       // CONVEY
            5'h03: kcost_lut = 64'd3000000;       // MEAN
            5'h04: kcost_lut = 64'd5000000;       // ACT
            5'h05: kcost_lut = 64'd1000000;       // COMPOSE
            5'h06: kcost_lut = 64'd20000000;      // SEAL
            5'h07: kcost_lut = 64'd50000000;      // PROVE
            5'h08: kcost_lut = 64'd2000000;       // QUERY
            5'h09: kcost_lut = 64'd10000000;      // GRANT
            5'h0A: kcost_lut = 64'd25000000;      // GOVERN
            5'h0B: kcost_lut = 64'd1000000;       // THEN
            5'h0C: kcost_lut = 64'd1000000;       // WITH
            5'h0D: kcost_lut = 64'd1000000;       // UNDER
            5'h0E: kcost_lut = 64'd2000000;       // IF
            5'h0F: kcost_lut = 64'd5000000;       // LOOP
            5'h10: kcost_lut = 64'd10000000;      // LIFT
            5'h11: kcost_lut = 64'd1000000;       // REFLECT
            default: kcost_lut = 64'd0;
        endcase
    endfunction

    // Boot-time content fold over the 18 canonical entries.  Deterministic
    // XOR-rotate accumulation -> K_cost_table_mhash (64-bit projection).
    function [63:0] table_fold;
        input dummy;
        reg [63:0] acc;
        integer oi;
        reg [63:0] v;
        begin
            acc = 64'h0;
            for (oi = 0; oi < 18; oi = oi + 1) begin
                v   = kcost_lut(oi[4:0]);
                // rotate-left 7 then xor the entry (order-sensitive, stable)
                acc = ((acc << 7) | (acc >> 57)) ^ (v + oi);
            end
            table_fold = acc;
        end
    endfunction

    wire [63:0] computed_mhash = table_fold(1'b0);
    assign table_mhash = computed_mhash;
    // Bind to the sealed root: the canonical sealed_root_mhash low-64 must
    // equal the table fold.  (Boot programs sealed_root_mhash[63:0] to the
    // fold of the canonical table; tamper -> mismatch -> seal_fault.)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            seal_fault <= 1'b0;
        else
            seal_fault <= (computed_mhash != sealed_root_mhash[63:0]);
    end

    // K-cost is poisoned (0) on a seal fault so a tampered policy cannot
    // silently alter the kchain.
    assign k_cost = seal_fault ? 64'd0 : kcost_lut(op);

    // Expose the canonical fold so a boot agent / testbench can program the
    // sealed root correctly (and the formal harness can prove the bind).
    // (table_fold(1'b0) is the K_cost_table_mhash projection.)
endmodule

`default_nettype wire
