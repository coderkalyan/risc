`default_nettype none

module rob #(
    parameter LEN = 16,
    parameter BWIDTH = 57,
    parameter LBITS = $clog2(LEN)
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [BWIDTH - 1:0] i_bundle0,
    input wire [BWIDTH - 1:0] i_bundle1,
    input wire [BWIDTH - 1:0] i_bundle2,
    input wire [BWIDTH - 1:0] i_bundle3,
    input wire [2:0] i_dispatch_count,
    output reg [LBITS - 1:0] o_count,
);
    // circular buffer, push to head, pop from tail
    reg [BWIDTH - 1:0] buffer [LEN - 1:0];
    reg [LBITS - 1:0] head, tail;

    integer i;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            head <= {LBITS{1'b0}};
            tail <= {LBITS{1'b0}};
            o_count <= {LBITS{1'b0}};

            for (i = 0; i < LEN; i = i + 1)
                buffer[i] <= {BWIDTH{1'b0}};
        end else begin
            // dispatch stage (inserts into ROB)
            if (i_dispatch_count != 0)
                buffer[head] <= i_bundle0;
            if (i_dispatch_count > 1)
                buffer[head + 1] <= i_bundle1;
            if (i_dispatch_count > 2)
                buffer[head + 2] <= i_bundle2;
            if (i_dispatch_count == 4)
                buffer[head + 3] <= i_bundle3;

            o_count <= o_count + i_dispatch_count;
            head <= head + i_dispatch_count;

            // retire stage (removes from ROB)
        end
    end
endmodule
