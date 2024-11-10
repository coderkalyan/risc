`default_nettype none

module cpu #(
    parameter RESET_VECTOR = 32'h80000000
) (
    input wire i_clk,
    input wire i_rst_n
);
    localparam XLEN = 32;
    localparam BWIDTH = 57;

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

    // ----- decode stage -----
    // the current design is a four-wide decoder, capable
    // of parsing up to 4 instructions from a buffer of 16 bytes
    // depending on whether the instructions are compressed,
    // or macro-op fusion takes place, the PC advance can be
    // any multiple of 2 between 0 and 16 (inclusive)
    // however to achieve this, 7 decoders are necessary, at every
    // 2 byte offset except +14
    // these are masked using a segmenter that looks at the chain of
    // compression opcode bits to determine instruction boundaries
    // this can yield up to 8 instructions (if all are compressed)
    // but up to the first four are selected and sent to dispatch

    wire [7:0] inst_bytes [0:15];
    wire [BWIDTH - 1:0] bundles [0:6];
    wire [0:6] inst_valid;

    assign inst_bytes[0] = 8'h93;
    assign inst_bytes[1] = 8'h00;
    assign inst_bytes[2] = 8'h40;
    assign inst_bytes[3] = 8'h06;
    assign inst_bytes[4] = 8'h13;
    assign inst_bytes[5] = 8'h01;
    assign inst_bytes[6] = 8'h80;
    assign inst_bytes[7] = 8'h0c;
    assign inst_bytes[8] = 8'h93;
    assign inst_bytes[9] = 8'h61;
    assign inst_bytes[10] = 8'hc0;
    assign inst_bytes[11] = 8'h12;
    assign inst_bytes[12] = 8'h03;
    assign inst_bytes[13] = 8'h22;
    assign inst_bytes[14] = 8'h00;
    assign inst_bytes[15] = 8'h00;

    genvar dindex;
    generate
        for (dindex = 0; dindex < 7; dindex = dindex + 1) begin
            decoder decoder (
                .i_inst({inst_bytes[2 * dindex + 3], inst_bytes[2 * dindex + 2], inst_bytes[2 * dindex + 1], inst_bytes[2 * dindex + 0]}),
                .o_bundle(bundles[dindex]),
                .o_valid(inst_valid[dindex])
            );
        end
    endgenerate

    wire [0:127] packet;
    genvar bindex;
    generate
        for (bindex = 0; bindex < 16; bindex = bindex + 1) begin
            assign packet[8 * bindex:8 * bindex + 7] = inst_bytes[bindex][7:0];
        end
    endgenerate

    wire [0:7] decoder_valid;
    wire [3:0] decoder_valid_count;
    segment segmenter (.i_packet(packet), .o_valid(decoder_valid), .o_valid_count(decoder_valid_count));

    // TODO: trap if any "segment valid" instructions are invalid
    // TODO: try to optimize this
    reg [BWIDTH - 1:0] di_bundles [0:3];
    always @(*) begin
        di_bundles[0] = bundles[0];
        di_bundles[1] = {BWIDTH{1'bx}};
        di_bundles[2] = {BWIDTH{1'bx}};
        di_bundles[3] = {BWIDTH{1'bx}};

        casez (decoder_valid)
            8'b11??????: di_bundles[1] = bundles[1];
            8'b101?????: di_bundles[1] = bundles[2];
        endcase

        casez (decoder_valid)
            8'b111?????: di_bundles[2] = bundles[2];
            8'b1101????: di_bundles[2] = bundles[3];
            8'b1011????: di_bundles[2] = bundles[3];
            8'b10101???: di_bundles[2] = bundles[4];
        endcase

        casez (decoder_valid)
            8'b1111????: di_bundles[3] = bundles[3];
            8'b11101???: di_bundles[3] = bundles[4];
            8'b11011???: di_bundles[3] = bundles[4];
            8'b110101??: di_bundles[3] = bundles[5];
            8'b10111???: di_bundles[3] = bundles[4];
            8'b101101??: di_bundles[3] = bundles[5];
            8'b101011??: di_bundles[3] = bundles[5];
            8'b1010101?: di_bundles[3] = bundles[6];
        endcase
    end

    // ----- dispatch stage -----
    integer i;
    reg [BWIDTH - 1:0] di_di_bundles [0:3];
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i = 0; i < 4; i++)
                di_di_bundles[i] <= {BWIDTH{1'b0}};
        end else if (di_di_bundles[0] == {BWIDTH{1'b0}}) begin
            for (i = 0; i < 4; i++)
                di_di_bundles[i] <= di_bundles[i];
        end
    end

    rs reservation_stations (
        .i_clk(i_clk), .i_rst_n(i_rst_n),
        .i_bundle0(di_di_bundles[0]), .i_bundle1(di_di_bundles[1]),
        .i_bundle2(di_di_bundles[2]), .i_bundle3(di_di_bundles[3]),
        .i_insert_count(3'd4), // TODO: fix this
        .i_rdy_regs()
    );

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu);

        #1;
        $display("%b", inst_valid);
        $display("%b", decoder_valid);
        $display("source bundles:");
        for (i = 0; i < 8; i++)
            $display("%d: %x", i, bundles[i]);
        $display("dispatched bundles:");
        for (i = 0; i < 4; i++)
            $display("%d: %x", i, di_bundles[i]);
    end
endmodule

// module penc6 (
//     input wire [0:6] i_vec,
//     output reg [2:0] o_loc,
//     output reg o_valid
// );
//     always @(*) begin
//         o_loc = 3'bxxx;
//         o_valid = i_vec != 6'b000000;
//
//         casez (i_vec)
//             6'b1?????: o_loc = 0;
//             6'b01????: o_loc = 1;
//             6'b001???: o_loc = 2;
//             6'b0001??: o_loc = 3;
//             6'b00001?: o_loc = 4;
//             6'b000001: o_loc = 5;
//         endcase
//     end
// endmodule
//
// module cloc6 (
//     input wire [0:6] i_vec,
//     input wire [2:0] i_loc,
//     output wire [0:6] o_vec
// );
//     reg [0:6] mask;
//     always @(*) begin
//         mask = 6'b111111;
//
//         case (i_loc)
//             3'd0: mask = 6'b011111;
//             3'd1: mask = 6'b101111;
//             3'd2: mask = 6'b110111;
//             3'd3: mask = 6'b111011;
//             3'd4: mask = 6'b111101;
//             3'd5: mask = 6'b111110;
//         endcase
//     end
//
//     assign o_vec = i_vec & mask;
// endmodule
