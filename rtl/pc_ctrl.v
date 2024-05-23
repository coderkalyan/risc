`default_nettype none

// 4 wide instruction fetch, currently without tracing
module pc_ctrl #(
    // parameter RESET_VECTOR = 32'h80000000
    parameter RESET_VECTOR = 32'h00000000
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [3:0] i_cache_miss,      // each bit means cache miss for corresponding inst
    input wire [2:0] i_di_count,        // number of instructions accepted by dispatch
    input wire i_branch_en,             // branch predictor decided to branch
    input wire [31:0] i_branch_target,
    input wire i_flush_en,              // same deal for flush
    input wire [31:0] i_flush_target,
    output wire [31:0] o_pc
);
    reg [31:0] pc, next_pc;

    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            pc <= RESET_VECTOR;
        else
            pc <= next_pc;
    end

    // in the ideal case, we increment the pc by 4 words = 16B
    // however, we could stall or jump for multiple reasons:
    // 1) instruction cache miss means we need to wait for instructions to be
    //    fetched
    // 2) ROB/RS full or other structural hazard means dispatch stalls
    // 3) branch decoded in instruction packet and predicted taken, so we jump
    // 4) branch resolved and prediction was incorrect, so we jump

    reg [2:0] hit_count;
    always @(*) begin
        casex (i_cache_miss)
            4'b1xxx: hit_count = 3'h0;
            4'b01xx: hit_count = 3'h1;
            4'b001x: hit_count = 3'h2;
            4'b0001: hit_count = 3'h3;
            4'b0000: hit_count = 3'h4;
        endcase
    end

    wire [2:0] consume_count = (hit_count < i_di_count) ? hit_count : i_di_count;

    always @(*) begin
        next_pc = 32'hxxxxxxxx;

        casex ({i_branch_en, i_flush_en})
            // if neither speculating or flushing, we increment depending on
            // consume_count
            2'b00: begin
                case (consume_count)
                    3'h0: next_pc = pc;
                    3'h1: next_pc = pc + 4;
                    3'h2: next_pc = pc + 8;
                    3'h3: next_pc = pc + 12;
                    3'h4: next_pc = pc + 16;
                    default: next_pc = 32'hxxxxxxxx;
                endcase
            end
            // if we need to flush, it doesn't matter if there was a branch
            // decoded in the speculative stream
            2'bx1: next_pc = i_flush_target;
            2'b10: next_pc = i_branch_target;
        endcase
    end

    assign o_pc = pc;
endmodule

// `default_nettype none
//
// module pc_ctrl #(
//     // parameter RESET_VECTOR = 32'h80000000
//     parameter RESET_VECTOR = 0,
//     parameter STRIDE = 4
// ) (
//     input wire i_clk,
//     input wire i_rst_n,
//     input wire [1:0] i_inc, // 0 - 1st inst stall, 1 - 2nd inst stall, 2 - normal, 3 - jump
//     input wire [31:0] i_jump_target,
//     output wire [31:0] o_pc
// );
//     localparam DSTRIDE = 2 * STRIDE;
//
//     reg [31:0] pc, next_pc;
//
//     always @(posedge i_clk, negedge i_rst_n) begin
//         if (!i_rst_n)
//             pc <= RESET_VECTOR;
//         else
//             pc <= next_pc;
//     end
//
//     always @(*) begin
//         case (i_inc)
//             2'b00: next_pc = pc;
//             2'b01: next_pc = pc + STRIDE;
//             2'b10: next_pc = pc + DSTRIDE,
//             2'b11: next_pc = i_branch_target;
//         endcase
//     end
// endmodule
