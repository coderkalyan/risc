`default_nettype none

// primary scalar register file (XRF)
module xrf #(
    parameter XLEN = 32
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [4:0] i_rs1,
    input wire [4:0] i_rs2,
    input wire [4:0] i_rd,
    input wire [XLEN - 1:0] i_wdata,
    input wire i_wen,
    output wire [XLEN - 1:0] o_rdata1,
    output wire [XLEN - 1:0] o_rdata2
);
    reg [XLEN - 1:0] file [31:0];

    wire [XLEN - 1:0] rdata1, rdata2;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            for (integer i = 0; i < 32; i = i + 1)
                file[i] <= 0;
        else begin

        end
    end
endmodule
