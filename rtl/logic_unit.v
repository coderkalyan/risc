`default_nettype none

module logic_unit (
    input wire i_clk,
    input wire i_rst_n,
    input wire i_op1,
    input wire [31:0] i_op2,
    input wire i_start,
    output wire o_done,
);
