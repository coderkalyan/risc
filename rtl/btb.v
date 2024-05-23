`default_nettype none

module btb #(
    parameter LEN = 32
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [31:0] i_pred_addr,
    input wire [31:0] i_update_addr,
    input wire [31:0] i_update_target,
    input wire i_update_en,
    output wire [31:0] o_target,
    output wire o_valid
);
    localparam LBITS = $clog2(LEN);

    reg [31:LBITS] tags [LEN - 1:0];
    reg [31:0] targets [LEN - 1:0];
    reg [LEN - 1:0] valid;

    wire [31:LBITS] tag;
    wire [LBITS - 1:0] index;
    assign {tag, index} = i_addr;

    integer i;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            valid <= {LEN{1'b0}};
            for (i = 0; i < LEN; i = i + 1) begin
                tags[i] <= {32 - LBITS{1'b0}};
                targets[i] <= 32'h00000000;
            end
        end else if (i_update_en) begin
            tags[index] <= i_update_addr[31:LBITS];
            targets[index] <= i_update_target;
            valid[index] <= 1'b1;
        end
    end

    wire forward = (i_pred_addr == i_update_addr) && i_update_en;
    assign o_valid = (valid[index] && (tags[index] == tag)) || forward;
    assign o_target = forward ? i_update_target : targets[index];
endmodule
