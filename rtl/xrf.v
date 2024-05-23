`default_nettype none

// primary scalar register file (XRF)
// this is a physical register file (of size XLEN + ROBLEN)
// plus a map table for assigning architetural registers
// and a free list of available physical registers
// p0 is hardcoded to 0, and x0 is permanently mapped to it
module xrf #(
    parameter XLEN = 32,
    parameter ROBLEN = 16,
    parameter PLEN = XLEN + ROBLEN,
    parameter XBITS = $clog2(XLEN),
    parameter PBITS = $clog2(PLEN),
    parameter WPORTS = 1,
) (
    input wire i_clk,
    input wire i_rst_n,
    // map table updates (from dispatch stage)
    // requested source registers are filled in with new entries
    // from the free list
    input wire [XBITS - 1:0] i_alloc1, // architectural register pointers
    input wire [XBITS - 1:0] i_alloc2, // architectural register pointers
    input wire [XBITS - 1:0] i_rs1,
    input wire [XBITS - 1:0] i_rs2,
    input wire [XBITS - 1:0] i_rd,
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

    // free list - bit vector of available physical registers
    reg [PLEN - 1:0] list;

    wire [PBITS - 1:0] free [1:0]; // next physical registers to allocate
    localparam PE_DIFF = 64 - PLEN;
    priority_encoder_6bit pe0 (.i_vec({{PE_DIFF{1'b0}}, list}), .o_code(free[1]));
    // instead of going through the critical path of the first encoder
    // plus a partial shifter, we use a bit manipulation trick to clear the
    // lowest set bit
    wire [PLEN - 1:0] cleared = list & (list - 1'b1);
    priority_encoder_6bit pe1 (.i_vec({{PE_DIFF{1'b0}}, list}), .o_code(free[0]));
    wire [1:0] avail = {list == {PLEN{1'b0}}, cleared == {PLEN{1'b0}}};

    wire [1:0] req = {i_alloc1 == {XBITS{1'b0}}, i_alloc2 == {XBITS{1'b0}}};
    reg [1:0] alloc_count;
    always @(*) begin
        case ({req, avail})
            4'b00xx: alloc_count = 2'b00; // none requested
            4'b01xx: alloc_count = 2'bxx; // invalid encoding
            4'b1000: alloc_count = 2'b00; // 1 requested, 0 available
            4'b101x: alloc_count = 2'b01; // 1 requested, 1 or 2 available
            4'b1100: alloc_count = 2'b00; // 2 requested, 0 available
            4'b1110: alloc_count = 2'b01; // 2 requested, 1 available
            4'b1111: alloc_count = 2'b10; // 2 requested, 2 available
        endcase
    end

    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            // mark all registers as free
            list <= {PLEN{1'b1}};
        end else begin
            // depending on alloc_count, mark registers as not free
            case (alloc_count)
                2'b00: list <= list;
                2'b01: list <= cleared;
                2'b10: list <= cleared & (cleared - 1'b1);
                default: list <= {PLEN{1'bx}};
            endcase
        end
    end

    // map table - contains mappings of architetural to physical registers
    reg [PBITS - 1:0] map_table [XBITS - 1:0];
    reg [XBITS - 1:0] rdy;

    integer i;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            // all registers are marked ready by default
            // (reading them is junk data, but we don't want to stall
            // if the code reads from one of them)
            rdy <= {XBITS{1'b1}};
            // and we can just conveniently map them all to P0,
            // which sets x0 correctly and conveniently clears the others
            for (i = 0; i < PLEN; i = i + 1)
                map_table[i] <= {PBITS{1'b0}};
        end else begin
            // in order frontend supports 2 wide dispatch, so we have two
            // write ports to update the map table
            // the frontend ensures that both write ports (if used) are to
            // distinct entries
            if (i_alloc1 != {XBITS{1'b0}}) begin
                map_table[i_alloc1] <= free[1];

                if (i_alloc2 != {XBITS{1'b0}}) begin
                    map_table[i_alloc2] <= free[0];
                end
            end
        end
    end
endmodule
