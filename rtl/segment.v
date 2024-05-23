`default_nettype none

// part of the decode logic, generates validity signals for each of the
// decoders based on compression bits
localparam WORD = 32;
localparam HALF = 16;

module segment #(
    parameter WIDTH = 4,            // number of word length instructions
    parameter BITS = WORD * WIDTH,
    parameter DWIDTH = 2 * WIDTH    // number of compressed instructions
) (
    input wire [BITS - 1:0] i_packet,
    output wire [DWIDTH - 1:0] o_valid,
    output reg [$clog2(DWIDTH + 1) - 1:0] o_valid_count
);
    wire [DWIDTH - 1:0] compressed;
    genvar i;
    generate
        for (i = 0; i < DWIDTH; i = i + 1)
            assign compressed[i] = i_packet[i * HALF + 1:i * HALF] != 2'b11;
    endgenerate

    assign o_valid[0] = 1'b1;
    generate if (WIDTH > 1)
        assign o_valid[1] = o_valid[0] && compressed[0];
    endgenerate

    // TODO: its possible that flattening this (like a carry lookahead
    // generator) will improve latency, but it may not if the trees get too
    // large; it may also not matter if this is only used to gate the regular
    // decode logic at the end of the stage
    genvar j;
    generate
        for (j = 2; j < DWIDTH; j = j + 1)
            assign o_valid[j] = (o_valid[j - 2] && !compressed[j - 2]) || (o_valid[j - 1] && compressed[j - 1]);
    endgenerate

    integer k;
    always @(*) begin
        o_valid_count = 0;

        for (k = 0; k < DWIDTH; k = k + 1)
            o_valid_count = o_valid_count + o_valid[k];
    end
endmodule
