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
    input wire [BWIDTH - 1:0] i_bundle0,
    input wire [BWIDTH - 1:0] i_bundle1,
    input wire [BWIDTH - 1:0] i_bundle2,
    input wire [BWIDTH - 1:0] i_bundle3,
    input wire [1:0] i_insert_count,
    input wire [6 * UNITS - 1:0] i_rdy_regs,
    output wire [BWIDTH - 1:0] o_rdy,
    output wire [BWIDTH - 1:0] o_asb1_bundle,
    output wire [BWIDTH - 1:0] o_asb2_bundle,
    output wire [BWIDTH - 1:0] o_logic_bundle,
    output wire [BWIDTH - 1:0] o_load_bundle,
    output wire [BWIDTH - 1:0] o_store_bundle
);
    localparam RBITS = 5;

    localparam UNIT_ASB = 3'h0;
    localparam UNIT_LOGIC = 3'h1;
    localparam UNIT_LOAD = 3'h2;
    localparam UNIT_STORE = 3'h3;
    localparam UNIT_ENV = 3'h4;

    wire [0:3] insert_valid = {i_insert_count != 0, i_insert_count > 1, i_insert_count > 2, i_insert_count == 3};

    wire [2:0] units [0:UNITS - 1];
    assign units[0] = i_bundle0[41:39];
    assign units[1] = i_bundle1[41:39];
    assign units[2] = i_bundle2[41:39];
    assign units[3] = i_bundle3[41:39];

    wire [0:3] unit_asb, unit_logic, unit_load, unit_store;
    genvar uindex;
    generate
        for (uindex = 0; uindex < 3; uindex = uindex + 1) begin
            assign unit_asb[uindex] = insert_valid[uindex] && (units[uindex] == UNIT_ASB);
            assign unit_logic[uindex] = insert_valid[uindex] && (units[uindex] == UNIT_LOGIC);
            assign unit_load[uindex] = insert_valid[uindex] && (units[uindex] == UNIT_LOAD);
            assign unit_store[uindex] = insert_valid[uindex] && (units[uindex] == UNIT_STORE);
        end
    endgenerate

    wire [1:0] ld_asb_count = unit_asb[0] + unit_asb[1] + unit_asb[2] + unit_asb[3];
    wire ld_asb1_en = (ld_asb_count == 2'b01) || (ld_asb_count == 2'b10);
    wire ld_asb2_en = ld_asb_count == 2'b10;
    wire ld_logic_en = |unit_logic;
    wire ld_load_en = |unit_load;
    wire ld_store_en = |unit_store;

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

    reg [BWIDTH - 1:0] bundles [UNITS - 1:0];
    reg [RBITS - 1:0] rs1 [UNITS - 1:0];
    reg [RBITS - 1:0] rs2 [UNITS - 1:0];
    reg full [UNITS - 1:0];
    reg rdy1 [UNITS - 1:0];
    reg rdy2 [UNITS - 1:0];

    wire [UNITS - 1:0] rdy1_eq [UNITS - 1:0];
    wire [UNITS - 1:0] rdy2_eq [UNITS - 1:0];

    genvar j, k;
    generate
        for (j = 0; j < UNITS; j = j + 1) begin
            for (k = 0; k < UNITS; k = k + 1) begin
                assign rdy1_eq[j][k] = rs1[j] == i_rdy_regs[k];
                assign rdy2_eq[j][k] = rs2[j] == i_rdy_regs[k];
            end
        end
    endgenerate
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
            if (ld_asb1_en && !full[0]) begin
                full[0] <= 1'b1;
                case (ld_asb1)
                    2'b00: bundles[0] <= i_bundle0;
                    2'b01: bundles[0] <= i_bundle1;
                    2'b10: bundles[0] <= i_bundle2;
                    2'b11: bundles[0] <= i_bundle3;
                endcase
            end

            if (ld_asb2_en && !full[1]) begin
                full[1] <= 1'b1;
                case (ld_asb1)
                    2'b00: bundles[1] <= i_bundle0;
                    2'b01: bundles[1] <= i_bundle1;
                    2'b10: bundles[1] <= i_bundle2;
                    2'b11: bundles[1] <= i_bundle3;
                endcase
            end

            if (ld_logic_en && !full[2]) begin
                full[2] <= 1'b1;
                case (ld_asb1)
                    2'b00: bundles[2] <= i_bundle0;
                    2'b01: bundles[2] <= i_bundle1;
                    2'b10: bundles[2] <= i_bundle2;
                    2'b11: bundles[2] <= i_bundle3;
                endcase
            end

            if (ld_load_en && !full[3]) begin
                full[3] <= 1'b1;
                case (ld_asb1)
                    2'b00: bundles[3] <= i_bundle0;
                    2'b01: bundles[3] <= i_bundle1;
                    2'b10: bundles[3] <= i_bundle2;
                    2'b11: bundles[3] <= i_bundle3;
                endcase
            end

            if (ld_store_en && !full[4]) begin
                full[4] <= 1'b1;
                case (ld_asb1)
                    2'b00: bundles[4] <= i_bundle0;
                    2'b01: bundles[4] <= i_bundle1;
                    2'b10: bundles[4] <= i_bundle2;
                    2'b11: bundles[4] <= i_bundle3;
                endcase
            end

            for (i = 0; i < UNITS; i = i + 1) begin
                if (|rdy1_eq[i]) rdy1[i] <= 1'b1;
                if (|rdy2_eq[i]) rdy2[i] <= 1'b1;
            end
        end
    end

    generate
        for (uindex = 0; uindex < UNITS; uindex = uindex + 1) begin
            assign o_rdy[uindex] = rdy1[uindex] && rdy2[uindex];
        end
    endgenerate

    assign o_asb1_bundle = bundles[0];
    assign o_asb2_bundle = bundles[1];
    assign o_logic_bundle = bundles[2];
    assign o_load_bundle = bundles[3];
    assign o_store_bundle = bundles[4];
endmodule
