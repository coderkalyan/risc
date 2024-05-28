`default_nettype none

// this is a simple ALU that performs the following functions:
// branch resolution with taken/not taken
// pc + offset address generation for branches, jal, and auipc
// register + immediate adder for addi, lui, and jalr
// all operations on this execution unit have single cycle latency
module branch_add_unit #(
    parameter WIDTH = 32
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire i_op,
    input wire [2:0] i_func,
    input wire [WIDTH - 1:0] i_rs1,
    input wire [WIDTH - 1:0] i_rs2,
    input wire [WIDTH - 1:0] i_imm,
    input wire [WIDTH - 1:0] i_pc,
    input wire i_start,
    input wire i_pred,
    output reg o_taken,
    output reg o_flush,
    output reg [WIDTH - 1:0] o_result,
    output reg o_valid
);
    // branch resolution (using rs1 and rs2)
    wire eq = i_rs1 == i_rs2;
    wire lt = $signed(i_rs1) < $signed(i_rs2);
    wire ltu = $unsigned(i_rs1) < $unsigned(i_rs2);

    wire func_cmp = i_func[2];
    wire func_unsigned = i_func[1];
    wire func_invert = i_func[0];

    wire taken = (func_cmp ? (func_unsigned ? ltu : lt) : eq) ^ func_invert;
    wire flush = taken != i_pred;

    // addition (using pc or rs1 and immediate)
    wire pc_base = i_op;
    wire [WIDTH - 1:0] base = pc_base ? i_pc : i_rs1;
    wire [WIDTH - 1:0] add_result = base + i_imm;

    // all operations have single cycle latency
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_taken <= 1'b0;
            o_flush <= 1'b0;
            o_result <= 32'h00000000;
            o_valid <= 1'b0;
        end else begin
            o_taken <= taken;
            o_flush <= flush;
            o_result <= add_result;
            o_valid <= i_start;
        end
    end
endmodule
