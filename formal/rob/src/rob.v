`default_nettype none

module rob #(
    parameter LEN = 16,
    parameter BWIDTH = 57,
    parameter UNITS = 5,
    parameter LBITS = $clog2(LEN)
) (
    input wire i_clk,
    input wire i_rst_n,
    // instruction bundles to insert into buffer
    input wire [BWIDTH - 1:0] i_ins_bundle0,
    input wire [BWIDTH - 1:0] i_ins_bundle1,
    input wire [BWIDTH - 1:0] i_ins_bundle2,
    input wire [BWIDTH - 1:0] i_ins_bundle3,
    // corresponding "old" physical registers, to free on retire
    input wire [5:0] i_ins_old_p0,
    input wire [5:0] i_ins_old_p1,
    input wire [5:0] i_ins_old_p2,
    input wire [5:0] i_ins_old_p3,
    // number of instructions above being inserted
    input wire [2:0] i_ins_count,
    // each execution unit can mark an instruction complete
    // does not need to be in order, just set en correctly
    input wire [LBITS - 1:0] i_cmpl0,
    input wire [LBITS - 1:0] i_cmpl1,
    input wire [LBITS - 1:0] i_cmpl2,
    input wire [LBITS - 1:0] i_cmpl3,
    input wire [LBITS - 1:0] i_cmpl4,
    input wire [LBITS - 1:0] i_cmpl5,
    input wire [5:0] i_cmpl_en,
    output wire [LBITS - 1:0] o_free,
    output reg [5:0] o_ret_p0,
    output reg [5:0] o_ret_p1,
    output reg [5:0] o_ret_p2,
    output reg [5:0] o_ret_p3,
    output reg [2:0] o_ret_count,
);
    // circular buffer, push to head, pop from tail
    reg [BWIDTH - 1:0] buffer [LEN - 1:0];
    reg rdy [LEN - 1:0];
    reg [5:0] old [LEN - 1:0];
    reg [LBITS - 1:0] head, tail;
    wire [LBITS - 1:0] count = head - tail;

    wire [0:3] ins_mask = {i_ins_count != 0, i_ins_count > 1, i_ins_count > 2, i_ins_count == 4};
    wire [0:3] evict_mask;
    assign evict_mask[0] = (count != 0) && rdy[tail];
    assign evict_mask[1] = (count >  1) && rdy[tail + 1] && evict_mask[0];
    assign evict_mask[2] = (count >  2) && rdy[tail + 2] && evict_mask[1];
    assign evict_mask[3] = (count == 4) && rdy[tail + 3] && evict_mask[2];
    wire [2:0] evict_count = evict_mask[0] + evict_mask[1] + evict_mask[2] + evict_mask[3];

    integer i;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            head <= {LBITS{1'b0}};
            tail <= {LBITS{1'b0}};
            o_ret_count <= 3'd0;
            o_ret_p0 <= 6'b000000;
            o_ret_p1 <= 6'b000000;
            o_ret_p2 <= 6'b000000;
            o_ret_p3 <= 6'b000000;

            for (i = 0; i < LEN; i = i + 1) begin
                buffer[i] <= {BWIDTH{1'b0}};
                rdy[i] <= 1'b0;
                old[i] <= 6'b000000;
            end
        end else begin
            head <= head + i_ins_count;

            if (ins_mask[0]) begin
                buffer[head + 0] <= i_ins_bundle0;
                rdy[head + 0] <= 1'b0;
                old[head + 0] <= i_ins_old_p0;
            end

            if (ins_mask[1]) begin
                buffer[head + 1] <= i_ins_bundle1;
                rdy[head + 1] <= 1'b0;
                old[head + 1] <= i_ins_old_p1;
            end

            if (ins_mask[2]) begin
                buffer[head + 2] <= i_ins_bundle2;
                rdy[head + 2] <= 1'b0;
                old[head + 2] <= i_ins_old_p2;
            end

            if (ins_mask[3]) begin
                buffer[head + 3] <= i_ins_bundle3;
                rdy[head + 3] <= 1'b0;
                old[head + 3] <= i_ins_old_p3;
            end

            tail <= tail + evict_count;
            o_ret_p0 <= old[head + 0];
            o_ret_p1 <= old[head + 1];
            o_ret_p2 <= old[head + 2];
            o_ret_p3 <= old[head + 3];
            o_ret_count <= evict_count;

            if (i_cmpl_en[0]) rdy[i_cmpl0] <= 1'b1;
            if (i_cmpl_en[1]) rdy[i_cmpl1] <= 1'b1;
            if (i_cmpl_en[2]) rdy[i_cmpl2] <= 1'b1;
            if (i_cmpl_en[3]) rdy[i_cmpl3] <= 1'b1;
            if (i_cmpl_en[4]) rdy[i_cmpl4] <= 1'b1;
            if (i_cmpl_en[5]) rdy[i_cmpl5] <= 1'b1;
        end
    end

    assign o_free = (LEN - 1) - count;

`ifdef FORMAL
    initial restrict(!i_rst_n);

    reg f_past_valid;
    initial f_past_valid <= 1'b0;
    always @(posedge i_clk) f_past_valid <= 1'b1;

    initial restrict(i_clk == 1'b0);

    // reg f_last_clk;
    // initial f_last_clk <= 1'b1;
    // always @($global_clock) begin
    //     if (f_past_valid) begin
    //         restrict(!$stable(i_clk));
            // f_last_clk <= !f_last_clk;

        // if (!$rose(i_clk)) begin
            // assume($stable(i_rst_n));
        //     assume($stable(i_ins_bundle0));
        //     assume($stable(i_ins_bundle1));
        //     assume($stable(i_ins_bundle2));
        //     assume($stable(i_ins_bundle3));
        //     assume($stable(i_ins_count));
        // end
    //     end
    // end

    reg [$clog2(LEN) - 1:0] f_count;
    initial f_count <= 0;
    always @(posedge i_clk, negedge i_rst_n)
        if (!i_rst_n)
            f_count <= 0;
        else
            f_count <= f_count + i_ins_count - evict_count;

    always @(*) begin
        restrict(i_ins_count <= 3'd4);
        restrict(i_ins_count <= o_free);

        assert(o_free <= (LEN - 1));
        assert(f_count == count);
        assert(o_free == (LEN - 1) - f_count);

        if (!ins_mask[0]) assert(!ins_mask[1]);
        if (!ins_mask[1]) assert(!ins_mask[2]);
        if (!ins_mask[2]) assert(!ins_mask[3]);

        assert(o_ret_count <= 3'd4);
        if (!evict_mask[0]) assert(!evict_mask[1]);
        if (!evict_mask[1]) assert(!evict_mask[2]);
        if (!evict_mask[2]) assert(!evict_mask[3]);
    end

    always @(posedge i_clk) begin
        if (f_past_valid) begin
            if ($past(!i_rst_n)) begin
                assert(o_free == (LEN - 1));
            end else begin
                assert(head == ($past(head) + $past(i_ins_count)));
            end
        end

        if (i_rst_n) begin
            cover(o_ret_count == 0);
            cover(o_ret_count == 1);
            cover(o_ret_count == 2);
            cover(o_ret_count == 3);
            cover(o_ret_count == 4);

            cover(o_free == (LEN - 1));
            cover(o_free == 0);
        end
    end
`endif
endmodule
