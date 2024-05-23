`default_nettype none

// simple adder that accepts register + immediate addition, simple shifting, and
// a combination of both
module address_unit #(
    parameter WIDTH = 32
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [WIDTH - 1:0] i_op1,
    input wire [WIDTH - 1:0] i_op2,
    input wire [1:0] i_shift,
    input wire i_start,
    output wire [WIDTH - 1:0] o_result,
    output reg o_result
);
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            o_valid <= 1'b0;
        else
            o_valid <= i_start;
    end

    wire [WIDTH - 1:0] sh0 = i_op1;
    wire [WIDTH - 1:0] sh1 = {i_op1[WIDTH - 2:0], 1'b0};
    wire [WIDTH - 1:0] sh2 = {i_op1[WIDTH - 3:0], 2'b00};
    wire [WIDTH - 1:0] sh3 = {i_op1[WIDTH - 4:0], 3'b000};
    reg [WIDTH - 1:0] shift_result;
    always @(*) begin
        case (i_shift)
            2'h0: shift_result = sh0;
            2'h1: shift_result = sh1;
            2'h2: shift_result = sh2;
            2'h3: shift_result = sh3;
        endcase
    end

    wire [WIDTH - 1:0] result = shift_result + i_op2;

    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            o_result <= 1'b0;
        else
            o_result <= result;
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            o_valid <= 1'b0;
        else
            o_valid <= i_start;
    end
endmodule
