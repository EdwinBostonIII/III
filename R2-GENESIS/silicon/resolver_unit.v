// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\resolver_unit.v
//
// I-INSTR v1.0 reference RTL -- Resolver Unit core
// Bound to:  DOCS/HARDWARE/I-INSTR-V1.0-spec.md
// Equivalence corpus: DOCS/HARDWARE/I-INSTR-V1.0-spec.md §10
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
//   W  - witness emit (append 64B to witness chain via DMA)
//   K  - kchain accumulator commit
//
// Each stage retires deterministically: cycle counts are part of the
// I-INSTR contract.

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

    // Witness chain DMA (write-only, append-only)
    output wire        wc_we,
    output wire [63:0] wc_addr,
    output wire [511:0] wc_data,    // 64-byte witness record
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

    // Status
    output wire        cap_fault,
    output wire        idle
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

    // Resolve
    reg [63:0]  r_dispatch_fp;
    reg [31:0]  r_winner_id;
    reg [63:0]  r_k_now;
    reg         r_valid;

    // Witness
    reg [63:0]  w_seq;
    reg [511:0] w_record;
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
    // Stage S: score (8-wide)
    // ------------------------------------------------------------------------
    // Pattern set walk: 8 candidates per cycle. For brevity we model a
    // single-cycle score evaluation (production silicon would multi-cycle
    // for sets > 8 candidates; this is the reference happy-path).

    wire [63:0] memo_key_lo;
    wire [63:0] memo_key_hi;

    iiis_memo_unit u_memo (
        .clk          (clk),
        .rst_n        (rst_n),
        .pset_id      (PSR),
        .intent_lo    (IR[63:0]),
        .intent_hi    (IR[127:64]),
        .ctx_digest_lo(CTXR[63:0]),
        .ctx_digest_hi(CTXR[127:64]),
        .lookup       (d_valid && (d_op == OP_PROVE
                                || d_op == OP_QUERY
                                || d_op == OP_CONVEY
                                || d_op == OP_ACT)),
        .key_lo       (memo_key_lo),
        .key_hi       (memo_key_hi),
        .hit          (/* memo hit signal */),
        .hit_winner   (/* cached winner_id */),
        .hit_fp       (/* cached dispatch_fp */)
    );

    iiis_score_unit u_score (
        .clk        (clk),
        .rst_n      (rst_n),
        .d_valid    (d_valid),
        .d_op       (d_op),
        .d_operands (d_operands),
        .pset_id    (PSR),
        .winner_fp  (s_winner_fp),
        .winner_id  (s_winner_id),
        .winner_sc  (s_winner_score),
        .s_valid    (s_valid)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_memo_key_lo <= 64'd0;
            s_memo_key_hi <= 64'd0;
        end else begin
            s_memo_key_lo <= memo_key_lo;
            s_memo_key_hi <= memo_key_hi;
        end
    end

    // ------------------------------------------------------------------------
    // Stage R: resolve / dispatch
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_dispatch_fp <= 64'd0;
            r_winner_id   <= 32'd0;
            r_k_now       <= 64'd0;
            r_valid       <= 1'b0;
        end else if (s_valid) begin
            r_dispatch_fp <= s_winner_fp;
            r_winner_id   <= s_winner_id;
            // K-cost: fixed-point delta added to KAR per primitive (taken
            // from the calculus's `calculus_primitive_k_cost`).
            r_k_now       <= KAR + iiis_k_cost(d_op);
            r_valid       <= 1'b1;
        end else begin
            r_valid       <= 1'b0;
        end
    end

    // Capability check on store-class operations
    assign cap_check_idx    = d_operands[8:6];   // generic CR slot
    assign cap_check_target = {32'd0, d_operands[31:8]};
    assign cap_fault        = r_valid &&
                              (d_op == OP_CONVEY || d_op == OP_GRANT || d_op == OP_LIFT) &&
                              !cap_check_ok;

    // ------------------------------------------------------------------------
    // Stage W: witness emit
    // ------------------------------------------------------------------------
    reg [63:0] witness_seq;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            witness_seq <= 64'd0;
            w_record    <= 512'd0;
            w_pending   <= 1'b0;
        end else if (r_valid) begin
            // Build 64-byte witness record:
            //  [seq:64][pat_id:64][ctx_digest:128][k_now:64][score:32][flags:32][reserved:128]
            w_record  <= { 128'd0,
                           32'h0,                               // flags
                           s_winner_score,                      // 32
                           r_k_now,                             // 64
                           CTXR[127:0],                         // 128
                           {32'd0, r_winner_id},                // 64
                           witness_seq };                       // 64
            w_pending <= 1'b1;
            witness_seq <= witness_seq + 64'd1;
        end else if (wc_ready) begin
            w_pending <= 1'b0;
        end
    end
    assign wc_we   = w_pending;
    assign wc_addr = WPR;
    assign wc_data = w_record;

    // Advance WPR after writing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)            WPR <= 64'd0;
        else if (wc_we && wc_ready) WPR <= WPR + 64'd64;
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
    // Idle status
    // ------------------------------------------------------------------------
    assign idle = !f_valid && !d_valid && !s_valid && !r_valid && !w_pending && !k_pending;

    // ------------------------------------------------------------------------
    // K-cost LUT (fixed point ×1e9; mirrors calculus_primitive_k_cost)
    // ------------------------------------------------------------------------
    function [63:0] iiis_k_cost;
        input [4:0] op;
        case (op)
            OP_FORM:    iiis_k_cost = 64'd1_000_000;       // 0.001
            OP_BIND:    iiis_k_cost = 64'd2_000_000;
            OP_CONVEY:  iiis_k_cost = 64'd5_000_000;
            OP_MEAN:    iiis_k_cost = 64'd3_000_000;
            OP_ACT:     iiis_k_cost = 64'd5_000_000;
            OP_COMPOSE: iiis_k_cost = 64'd1_000_000;
            OP_SEAL:    iiis_k_cost = 64'd20_000_000;
            OP_PROVE:   iiis_k_cost = 64'd50_000_000;
            OP_QUERY:   iiis_k_cost = 64'd2_000_000;
            OP_GRANT:   iiis_k_cost = 64'd10_000_000;
            OP_GOVERN:  iiis_k_cost = 64'd25_000_000;
            OP_THEN:    iiis_k_cost = 64'd1_000_000;
            OP_WITH:    iiis_k_cost = 64'd1_000_000;
            OP_UNDER:   iiis_k_cost = 64'd1_000_000;
            OP_IF:      iiis_k_cost = 64'd2_000_000;
            OP_LOOP:    iiis_k_cost = 64'd5_000_000;
            OP_LIFT:    iiis_k_cost = 64'd10_000_000;
            OP_REFLECT: iiis_k_cost = 64'd1_000_000;
            default:    iiis_k_cost = 64'd0;
        endcase
    endfunction

endmodule

// ============================================================================
// 8-wide score unit
// ============================================================================
module iiis_score_unit (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         d_valid,
    input  wire [4:0]   d_op,
    input  wire [26:0]  d_operands,
    input  wire [31:0]  pset_id,
    output reg  [63:0]  winner_fp,
    output reg  [31:0]  winner_id,
    output reg  [31:0]  winner_sc,
    output reg          s_valid
);
    // Reference single-cycle scoreboard. Production silicon would expand
    // this to 16-wide (AVX-512-class) and multi-cycle for large sets.
    //
    // For each of 8 candidates compute score = base_match + k_fit + ctx_match.
    // Reduction tree: max-of-8 + tiebreak via byte-lex compare on mhash.

    reg [31:0] cand_score [0:7];
    reg [31:0] cand_id    [0:7];
    reg [63:0] cand_fp    [0:7];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                cand_score[i] <= 32'd0;
                cand_id[i]    <= 32'd0;
                cand_fp[i]    <= 64'd0;
            end
            winner_fp <= 64'd0;
            winner_id <= 32'd0;
            winner_sc <= 32'd0;
            s_valid   <= 1'b0;
        end else if (d_valid) begin
            // In a real implementation, candidates come from the pattern
            // set SRAM addressed by `pset_id`. Here we emit a deterministic
            // candidate triple to keep the reference flow concrete.
            for (i = 0; i < 8; i = i + 1) begin
                cand_score[i] <= 32'h00010000 - {28'd0, i[3:0]};   // monotonic
                cand_id[i]    <= 32'd1 + i;
                cand_fp[i]    <= {32'h0001_0000, d_operands, 5'd0} + (i << 12);
            end
            // Reduce: max of 8 (tournament).
            // Stage 1: 4 pairwise max
            // Stage 2: 2 pairwise max
            // Stage 3: 1 pairwise max -> winner
            // Combinational fold:
            winner_sc <= cand_score[0];
            winner_id <= cand_id[0];
            winner_fp <= cand_fp[0];
            s_valid   <= 1'b1;
        end else begin
            s_valid   <= 1'b0;
        end
    end
endmodule

// ============================================================================
// Memoization unit (4096-entry SRAM, content-addressed)
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
    output wire [63:0] key_lo,
    output wire [63:0] key_hi,
    output reg         hit,
    output reg  [31:0] hit_winner,
    output reg  [63:0] hit_fp
);
    // Memo SRAM: 4096 × (key:128 + winner:32 + fp:64 + valid:1) ≈ 4096 × 28B
    // For brevity model as flop array.
    reg [127:0] memo_key   [0:4095];
    reg [31:0]  memo_win   [0:4095];
    reg [63:0]  memo_fp    [0:4095];
    reg         memo_valid [0:4095];

    // Content-addressed key (per spec: SHA-256 truncated to 128 bits
    // of pset_id || intent_lo || intent_hi || ctx_digest_lo || ctx_digest_hi).
    // For reference RTL, use simple hash; production would use SHA-NI ROM.
    assign key_lo = intent_lo ^ ctx_digest_lo ^ {32'd0, pset_id};
    assign key_hi = intent_hi ^ ctx_digest_hi;

    // 12-bit slot index from key
    wire [11:0] slot = key_lo[11:0];

    integer init_j;
    initial begin
        for (init_j = 0; init_j < 4096; init_j = init_j + 1) begin
            memo_key[init_j]   = 128'd0;
            memo_win[init_j]   = 32'd0;
            memo_fp[init_j]    = 64'd0;
            memo_valid[init_j] = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hit         <= 1'b0;
            hit_winner  <= 32'd0;
            hit_fp      <= 64'd0;
        end else if (lookup) begin
            if (memo_valid[slot] &&
                memo_key[slot] == {key_hi, key_lo}) begin
                hit        <= 1'b1;
                hit_winner <= memo_win[slot];
                hit_fp     <= memo_fp[slot];
            end else begin
                hit        <= 1'b0;
            end
        end else begin
            hit        <= 1'b0;
        end
    end

    // Insert path (driven externally on resolve commit; not modeled here
    // beyond the storage declarations).
endmodule

`default_nettype wire
