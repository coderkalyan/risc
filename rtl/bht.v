`default_nettype none

// currently we're not doing anything fancy for initialization/hit checking
// like tagging and seeding the predictor with branch direction
// this will probably have very minimal effect on performance, so the bht is
// really simple for now, dedicating all space to actually storing the table

module bht #(
    parameter LEN = 32,
    parameter HBITS = 3
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [31:0] i_pred_addr,
    input wire [31:0] i_update_addr,
    input wire i_update_taken,
    input wire i_update_en,
    output wire o_pred
);
    localparam LBITS = $clog2(LEN);

    reg [1:0] counters [LEN - 1:0][HBITS - 1:0];
    reg [HBITS - 1:0] histories [LEN - 1:0];

    wire [LBITS - 1:0] pred_index = i_pred_addr[LBITS - 1:0];
    wire [HBITS - 1:0] pred_history = histories[pred_index];
    wire [1:0] pred_counter = counters[pred_index][pred_history];

    wire [LBITS - 1:0] update_index = i_update_addr[LBITS - 1:0];
    wire [HBITS - 1:0] update_history = histories[update_index];
    wire [1:0] update_counter = counters[update_index][update_history];

    reg [1:0] next_counter;
    always @(*) begin
        case (update_counter)
            2'b00: next_counter = i_update_taken ? 2'b01 : 2'b00;
            2'b01: next_counter = i_update_taken ? 2'b10 : 2'b00;
            2'b10: next_counter = i_update_taken ? 2'b11 : 2'b01;
            2'b11: next_counter = i_update_taken ? 2'b11 : 2'b10;
        endcase
    end

    integer i, j;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i = 0; i < LEN; i = i + 1) begin
                for (j = 0; j < 2 ** HBITS; j = j + 1)
                    counters[i][j] <= 2'b00;

                histories[i] <= {HBITS{1'b0}};
            end
        end else if (i_update_en) begin
            counters[update_index][update_history] <= next_counter;
            histories[update_index] <= {update_history[HBITS - 2:0], i_update_taken};
        end
    end

    // forwarding from update to prediction
    wire forward = (i_pred_addr == i_update_addr) && (pred_history == update_history) && i_update_en;
    assign o_pred = (forward) ? next_counter[1] : pred_counter[1];
endmodule
