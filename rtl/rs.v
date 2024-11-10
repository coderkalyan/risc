`default_nettype none

// unified reservation station (scheduler) used by dispatch stage
// to buffer instructions that have been assigned to execution units
// and are waiting for operands to be ready
// currently, we have a one to one mapping of slots to execution units
// and the table is defined manually
module rs #(
    parameter BWIDTH = 57,
    parameter UNITS = 5
) (
    input wire i_clk,
    input wire i_rst_n,
    // queue up to 4 instruction bundles to be inserted into the reservation
    // station slots, in order (if bundle x stalls, x + 1 .. 4 cannot continue)
    // due to in order dispatch
    input wire [BWIDTH - 1:0] i_ins_bundle0,
    input wire [BWIDTH - 1:0] i_ins_bundle1,
    input wire [BWIDTH - 1:0] i_ins_bundle2,
    input wire [BWIDTH - 1:0] i_ins_bundle3,
    // input wire [2:0] i_ins_count,
    // vector of valid instruction bundles to try inserting
    input wire [3:0] i_ins_valid,
    // vector of registers that just became ready
    input wire [63:0] i_rdy_regs,
    // input wire [6 * UNITS - 1:0] i_rdy_regs,
    // each bit marks if the corresponding execution unit is ready to receive
    // a new workload, so the corresponding bundle will be evicted if ready
    input wire [UNITS - 1:0] i_evict_en,
    // these bundles are evicted from the rs
    output reg [BWIDTH - 1:0] o_asb1_bundle,
    output reg [BWIDTH - 1:0] o_asb2_bundle,
    output reg [BWIDTH - 1:0] o_logic_bundle,
    output reg [BWIDTH - 1:0] o_load_bundle,
    output reg [BWIDTH - 1:0] o_store_bundle,
    // hot if both eviction requested (i_evict_en) and slot full and ready
    output reg [UNITS - 1:0] o_evict_valid
);
    localparam RBITS = 5;

    localparam UNIT_ASB = 3'h0;
    localparam UNIT_LOGIC = 3'h1;
    localparam UNIT_LOAD = 3'h2;
    localparam UNIT_STORE = 3'h3;
    localparam UNIT_ENV = 3'h4;

    reg [BWIDTH - 1:0] bundles [UNITS - 1:0];
    reg [RBITS - 1:0] rs1 [UNITS - 1:0];
    reg [RBITS - 1:0] rs2 [UNITS - 1:0];
    reg [UNITS - 1:0] full;
    reg [UNITS - 1:0] rdy1;
    reg [UNITS - 1:0] rdy2;

    wire [UNITS - 1:0] rdy1_eq [UNITS - 1:0];
    wire [UNITS - 1:0] rdy2_eq [UNITS - 1:0];

    // registers that just got marked ready
    wire [UNITS - 1:0] next_rdy1, next_rdy2;
    genvar rdyindex;
    generate
        for (rdyindex = 0; rdyindex < UNITS; rdyindex = rdyindex + 1) begin
            assign next_rdy1[rdyindex] = i_rdy_regs[rs1[rdyindex]];
            assign next_rdy2[rdyindex] = i_rdy_regs[rs2[rdyindex]];
        end
    endgenerate

    // TODO: instructions that only need 1 source
    wire [UNITS - 1:0] rdy = (rdy1 | next_rdy1) & (rdy2 | next_rdy2);
    wire [UNITS - 1:0] evict = full & i_evict_en & rdy;
    // hot if slots are available to be inserted into
    wire [UNITS - 1:0] avail = ~full | evict;

    wire [2:0] units [0:3];
    assign units[0] = i_ins_bundle0[41:39];
    assign units[1] = i_ins_bundle1[41:39];
    assign units[2] = i_ins_bundle2[41:39];
    assign units[3] = i_ins_bundle3[41:39];

    wire [0:3] unit_asb, unit_logic, unit_load, unit_store;
    genvar uindex;
    generate
        for (uindex = 0; uindex < 3; uindex = uindex + 1) begin
            assign unit_asb[uindex] = i_ins_valid[uindex] && (units[uindex] == UNIT_ASB);
            assign unit_logic[uindex] = i_ins_valid[uindex] && (units[uindex] == UNIT_LOGIC);
            assign unit_load[uindex] = i_ins_valid[uindex] && (units[uindex] == UNIT_LOAD);
            assign unit_store[uindex] = i_ins_valid[uindex] && (units[uindex] == UNIT_STORE);
        end
    endgenerate

    wire [1:0] ld_asb_count = unit_asb[0] + unit_asb[1] + unit_asb[2] + unit_asb[3];
    wire ld_asb1_en = avail[0] && ((ld_asb_count == 2'b01) || (ld_asb_count == 2'b10));
    wire ld_asb2_en = avail[1] && (ld_asb_count == 2'b10);
    wire ld_logic_en = avail[2] && |unit_logic;
    wire ld_load_en = avail[3] && |unit_load;
    wire ld_store_en = avail[4] && |unit_store;

    reg [1:0] ld_asb1, ld_asb2, ld_logic, ld_load, ld_store;
    always @(*) begin
        ld_asb1 = 2'bxx;
        ld_asb2 = 2'bxx;
        ld_logic = 2'bxx;
        ld_load = 2'bxx;
        ld_store = 2'bxx;

        casez (unit_asb)
            4'b11??: begin ld_asb1 = 2'b00; ld_asb2 = 2'b01; end
            4'b101?: begin ld_asb1 = 2'b00; ld_asb2 = 2'b10; end
            4'b1001: begin ld_asb1 = 2'b00; ld_asb2 = 2'b11; end
            4'b1000: begin ld_asb1 = 2'b00; ld_asb2 = 2'bxx; end
            4'b011?: begin ld_asb1 = 2'b01; ld_asb2 = 2'b10; end
            4'b0101: begin ld_asb1 = 2'b01; ld_asb2 = 2'b11; end
            4'b0100: begin ld_asb1 = 2'b01; ld_asb2 = 2'bxx; end
            4'b0011: begin ld_asb1 = 2'b10; ld_asb2 = 2'b11; end
            4'b0010: begin ld_asb1 = 2'b10; ld_asb2 = 2'bxx; end
            4'b0001: begin ld_asb1 = 2'b11; ld_asb2 = 2'bxx; end
        endcase

        casez (unit_logic)
            4'b1???: ld_logic = 2'b00;
            4'b01??: ld_logic = 2'b01;
            4'b001?: ld_logic = 2'b10;
            4'b0001: ld_logic = 2'b11;
        endcase

        casez (unit_load)
            4'b1???: ld_load = 2'b00;
            4'b01??: ld_load = 2'b01;
            4'b001?: ld_load = 2'b10;
            4'b0001: ld_load = 2'b11;
        endcase

        casez (unit_store)
            4'b1???: ld_store = 2'b00;
            4'b01??: ld_store = 2'b01;
            4'b001?: ld_store = 2'b10;
            4'b0001: ld_store = 2'b11;
        endcase
    end

    // TODO: probably don't need the ld_*_en in this case
    reg [0:3] disp_en;
    reg [BWIDTH - 1:0] next_bundles [0:UNITS - 1];
    always @(*) begin
        next_bundles[0] = {BWIDTH{1'bx}};
        next_bundles[1] = {BWIDTH{1'bx}};
        next_bundles[2] = {BWIDTH{1'bx}};
        next_bundles[3] = {BWIDTH{1'bx}};
        next_bundles[4] = {BWIDTH{1'bx}};

        case ({ld_asb1_en, ld_asb1})
            3'b100: begin next_bundles[0] = i_ins_bundle0; disp_en[0] = 1'b1; end
            3'b100: begin next_bundles[0] = i_ins_bundle1; disp_en[1] = 1'b1; end
            3'b100: begin next_bundles[0] = i_ins_bundle2; disp_en[2] = 1'b1; end
            3'b100: begin next_bundles[0] = i_ins_bundle3; disp_en[3] = 1'b1; end
        endcase

        case ({ld_asb2_en, ld_asb2})
            3'b100: begin next_bundles[1] = i_ins_bundle0; disp_en[0] = 1'b1; end
            3'b100: begin next_bundles[1] = i_ins_bundle1; disp_en[1] = 1'b1; end
            3'b100: begin next_bundles[1] = i_ins_bundle2; disp_en[2] = 1'b1; end
            3'b100: begin next_bundles[1] = i_ins_bundle3; disp_en[3] = 1'b1; end
        endcase

        case ({ld_logic_en, ld_logic})
            3'b100: begin next_bundles[2] = i_ins_bundle0; disp_en[0] = 1'b1; end
            3'b100: begin next_bundles[2] = i_ins_bundle1; disp_en[1] = 1'b1; end
            3'b100: begin next_bundles[2] = i_ins_bundle2; disp_en[2] = 1'b1; end
            3'b100: begin next_bundles[2] = i_ins_bundle3; disp_en[3] = 1'b1; end
        endcase

        case ({ld_load_en, ld_load})
            3'b100: begin next_bundles[3] = i_ins_bundle0; disp_en[0] = 1'b1; end
            3'b100: begin next_bundles[3] = i_ins_bundle1; disp_en[1] = 1'b1; end
            3'b100: begin next_bundles[3] = i_ins_bundle2; disp_en[2] = 1'b1; end
            3'b100: begin next_bundles[3] = i_ins_bundle3; disp_en[3] = 1'b1; end
        endcase

        case ({ld_store_en, ld_store})
            3'b100: begin next_bundles[4] = i_ins_bundle0; disp_en[0] = 1'b1; end
            3'b100: begin next_bundles[4] = i_ins_bundle1; disp_en[1] = 1'b1; end
            3'b100: begin next_bundles[4] = i_ins_bundle2; disp_en[2] = 1'b1; end
            3'b100: begin next_bundles[4] = i_ins_bundle3; disp_en[3] = 1'b1; end
        endcase
    end

    reg [0:3] disp_en_stalled;
    always @(*) begin
        disp_en_stalled = 4'b0000;

        casez (disp_en)
            4'b0???: disp_en_stalled = 4'b0000;
            4'b10??: disp_en_stalled = 4'b1000;
            4'b110?: disp_en_stalled = 4'b1100;
            4'b1110: disp_en_stalled = 4'b1110;
            4'b1111: disp_en_stalled = 4'b1111;
        endcase
    end

    integer i;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i = 0; i < UNITS; i = i + 1) begin
                bundles[i] <= {BWIDTH{1'b0}};
                rs1[i] <= {RBITS{1'b0}};
                rs2[i] <= {RBITS{1'b0}};
                full[i] <= 1'b0;
                rdy1[i] <= 1'b0;
                rdy2[i] <= 1'b0;
            end
        end else begin
            // TODO: re-calculate rdy when populating
            if (ld_asb1_en && disp_en_stalled[ld_asb1]) bundles[0] <= next_bundles[0];
            if (ld_asb2_en && disp_en_stalled[ld_asb2]) bundles[1] <= next_bundles[1];
            if (ld_logic_en && disp_en_stalled[ld_logic]) bundles[2] <= next_bundles[2];
            if (ld_load_en && disp_en_stalled[ld_load]) bundles[3] <= next_bundles[3];
            if (ld_store_en && disp_en_stalled[ld_store]) bundles[4] <= next_bundles[4];

            full[0] <= avail[0] ? ld_asb1_en : full[0];
            full[1] <= avail[1] ? ld_asb2_en : full[1];
            full[2] <= avail[2] ? ld_logic_en : full[2];
            full[3] <= avail[3] ? ld_load_en : full[3];
            full[4] <= avail[4] ? ld_store_en : full[4];

            for (i = 0; i < UNITS; i = i + 1) begin
                if (next_rdy1[i]) rdy1[i] <= 1'b1;
                if (next_rdy2[i]) rdy2[i] <= 1'b1;
            end

            o_asb1_bundle <= bundles[0];
            o_asb2_bundle <= bundles[1];
            o_logic_bundle <= bundles[2];
            o_load_bundle <= bundles[3];
            o_store_bundle <= bundles[4];
            o_evict_valid <= evict;
        end
    end

    `ifdef FORMAL
    reg f_past_valid;
    initial f_past_valid <= 1'b0;
    always @(posedge i_clk) f_past_valid <= 1'b1;


    `endif
endmodule
