`default_nettype none

module cpu #(
    parameter RESET_VECTOR = 32'h80000000
) (
    input wire i_clk,
    input wire i_rst_n,
);
    localparam XLEN = 32;

    // ----- fetch stage -----
    wire [3:0] icache_miss = 4'b0000;
    wire [2:0] di_count = 3'h4;
    wire [31:0] pc;
    pc_ctrl pc_ctrl (
        .i_clk(i_clk), .i_rst_n(i_rst_n), .i_cache_miss(icache_miss), .i_di_count(di_count),
        .i_branch_en(1'b0), .i_branch_target(),
        .i_flush_en(1'b0), .i_flush_target(),
        .o_pc(pc)
    );

    // wire [31:0] pc0, pc1;
    // wire [1:0] pc0_inc, pc1_inc;
    // wire [31:0] pc0_target, pc1_target;
    // pc_ctrl pc_ctrl0 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_inc(pc0_inc), .i_jump_target(pc0_target), .o_pc(pc0));
    // pc_ctrl pc_ctrl1 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_inc(pc1_inc), .i_jump_target(pc1_target), .o_pc(pc1));
    
    // reg [XLEN - 1:0] pc1, pc2;
    // reg [XLEN - 1:0] next_pc1, next_pc2;
    // reg [2 * XLEN - 1:0] insts;
    //
    // always @(posedge i_clk, negedge i_rst_n) begin
    //     if (!i_rst_n) begin
    //         pc1 <= RESET_VECTOR;
    //         pc2 <= RESET_VECTOR + 4;
    //     end else begin
    //         pc1 <= next_pc1;
    //         pc2 <= next_pc2;
    //     end
    // end

    // wire i1 = insts[31:0];
    // wire i2 = insts[63:32];
    // wire i1_branch = (i1[6:0] == 7'b1100011) || ((i1[6:4] == 3'b110) && (i1[2:0] == 3'b111);
    // wire i2_branch = (i2[6:0] == 7'b1100011) || ((i2[6:4] == 3'b110) && (i2[2:0] == 3'b111);

    // ----- decode stage -----
    // the current design is a two-wide decoder, capable
    // of parsing up to 2 instructions from a buffer of 8 bytes
    // depending on whether the instructions are compressed,
    // or macro-op fusion takes place, the PC advance can be
    // 4 (2 + 2), 6 (2 + 4 or 4 + 2), or 8 (4 + 4 or 8) bytes
    // achieved with 3 decoders, at 0, 2, and 4 byte offsets

    wire [2:0] dec1_unit, dec2_unit, dec3_unit;
    wire [2:0] dec1_op, dec2_op, , dec3_func;
    wire [4:0] dec1_rs1, dec2_rs1, dec3_rs1;
    wire [4:0] dec1_rs2, dec2_rs2, dec3_rs2;
    wire [4:0] dec1_rd, dec2_rd, dec3_rd;
    decoder dec1 (
        .i_inst(insts[31:0]),
        .o_rs1(dec1_rs1),
        .o_rs2(dec1_rs2),
        .o_rd(dec1_rd),
        .o_unit(dec1_unit),
        .o_op(dec1_op),
        .o_func(dec1_func)
    );
    decoder dec2 (
        .i_inst(insts[47:16]),
        .o_rs1(dec2_rs1),
        .o_rs2(dec2_rs2),
        .o_rd(dec2_rd),
        .o_unit(dec2_unit),
        .o_op(dec2_op),
        .o_func(dec2_func)
    );
    decoder dec3 (
        .i_inst(insts[63:32]),
        .o_rs1(dec3_rs1),
        .o_rs2(dec3_rs2),
        .o_rd(dec3_rd),
        .o_unit(dec3_unit),
        .o_op(dec3_op),
        .o_func(dec3_func)
    );


endmodule
