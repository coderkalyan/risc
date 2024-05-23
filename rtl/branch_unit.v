`default_nettype none

module branch_unit #(
    parameter WIDTH = 32
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [2:0] i_op,
    input wire [WIDTH - 1:0] i_op1,
    input wire [WIDTH - 1:0] i_op2,
    input wire i_start,
    input wire i_pred,
    output wire o_taken,
    output wire o_flush,
    output reg o_valid
);
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            o_valid <= 1'b0;
        else
            o_valid <= i_start;
    end

    wire eq = i_op1 == i_op2;
    wire lt = $signed(i_op1) < $signed(i_op2);
    wire ltu = $unsigned(i_op1) < $unsigned(i_op2);

    wire op_cmp = i_op[2];
    wire op_unsigned = i_op[1];
    wire op_invert = i_op[0];

    assign o_taken = (op_cmp ? (op_unsigned ? ltu : lt) : eq) ^ op_invert;
    assign o_flush = o_taken != i_pred;
endmodule
