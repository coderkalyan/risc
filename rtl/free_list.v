`default_nettype none

module free_list #(
    parameter LEN = 32 + 16,
    parameter LBITS = $clog2(LEN)
) (
    input wire i_clk,
    input wire i_rst_n,
    // registers being retired (inserted into the free list)
    input wire [LBITS - 1:0] i_ret_p0,
    input wire [LBITS - 1:0] i_ret_p1,
    input wire [LBITS - 1:0] i_ret_p2,
    input wire [LBITS - 1:0] i_ret_p3,
    input wire [2:0] i_ret_count,
    // registers being requested (popped from the free list)
    input wire [2:0] i_req_count,
    output reg [LBITS - 1:0] o_req0,
    output reg [LBITS - 1:0] o_req1,
    output reg [LBITS - 1:0] o_req2,
    output reg [LBITS - 1:0] o_req3,
    output reg [2:0] o_req_count, // i_req_count mirrored back
    output reg [LBITS - 1:0] o_avail_count
);
    reg [0:LEN - 1] free;

    wire [0:3] ret_mask = {i_ret_count != 0, i_ret_count > 1, i_ret_count > 2, i_ret_count == 4};
    wire [0:LEN - 1] released0 = ret_mask[0] << i_ret_p0;
    wire [0:LEN - 1] released1 = ret_mask[1] << i_ret_p1;
    wire [0:LEN - 1] released2 = ret_mask[2] << i_ret_p2;
    wire [0:LEN - 1] released3 = ret_mask[3] << i_ret_p3;
    wire [0:LEN - 1] released = free | released0 | released1 | released2 | released3;

    wire [0:LEN - 1] clb0 = released & (released - 1);
    wire [0:LEN - 1] clb1 = clb0 & (clb0 - 1);
    wire [0:LEN - 1] clb2 = clb1 & (clb1 - 1);
    wire [0:LEN - 1] clb3 = clb2 & (clb2 - 1);

    wire [0:LEN - 1] mask0 = released ^ clb0;
    wire [0:LEN - 1] mask1 = clb0 ^ clb1;
    wire [0:LEN - 1] mask2 = clb1 ^ clb2;
    wire [0:LEN - 1] mask3 = clb2 ^ clb3;

    wire [LBITS - 1:0] req0, req1, req2, req3;
    encoder_6bit enc0 (.i_vec(mask0), .o_code(req0));
    encoder_6bit enc1 (.i_vec(mask1), .o_code(req1));
    encoder_6bit enc2 (.i_vec(mask2), .o_code(req2));
    encoder_6bit enc3 (.i_vec(mask3), .o_code(req3));

    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            free <= {LEN{1'b1}};
            o_avail_count <= LEN;
            o_req0 <= {LBITS{1'b0}};
            o_req1 <= {LBITS{1'b0}};
            o_req2 <= {LBITS{1'b0}};
            o_req3 <= {LBITS{1'b0}};
            o_req_count <= 3'd0;
        end else begin
            o_avail_count <= o_avail_count + i_ret_count - i_req_count;

            case (i_req_count)
                3'd0: free <= released;
                3'd1: free <= clb0;
                3'd2: free <= clb1;
                3'd3: free <= clb2;
                3'd4: free <= clb3;
            endcase

            o_req0 <= req0;
            o_req1 <= req1;
            o_req2 <= req2;
            o_req3 <= req3;
            o_req_count <= i_req_count;
        end
    end

`ifdef FORMAL
    // initial restrict(!i_rst_n);
    initial restrict(free == {LEN{1'b1}});
    initial restrict(o_req_count == 3'd0);

    reg f_past_valid;
    initial f_past_valid <= 1'b0;
    always @(posedge i_clk) f_past_valid <= 1'b1;

    always @(*) begin
        restrict(i_rst_n);
        restrict(i_ret_count <= 3'd4);
        restrict(i_req_count <= 3'd4);
        restrict(i_req_count <= o_avail_count);
    end

    integer f_i;
    always @(posedge i_clk) begin
        if (!i_rst_n || !$past(i_rst_n)) begin
            assert(o_req_count == 3'd0);
            assert(free == {LEN{1'b1}});
        end else begin
            if (f_past_valid && ($past(i_ret_count) == 3'd0)) begin
                if ($past(i_req_count > 3'd0)) begin
                    assert($past(free[$past(o_req0)]));
                    assert(!free[$past(o_req0)]);
                end
            end
        end
    end
`endif
endmodule

module encoder_6bit (
    input wire [63:0] i_vec,
    output reg [5:0] o_code
);
    always @(*) begin
        o_code = 6'h0;

        case (1'b1)
            i_vec[6'h0]: o_code = 6'h0;
            i_vec[6'h1]: o_code = 6'h1;
            i_vec[6'h2]: o_code = 6'h2;
            i_vec[6'h3]: o_code = 6'h3;
            i_vec[6'h4]: o_code = 6'h4;
            i_vec[6'h5]: o_code = 6'h5;
            i_vec[6'h6]: o_code = 6'h6;
            i_vec[6'h7]: o_code = 6'h7;
            i_vec[6'h8]: o_code = 6'h8;
            i_vec[6'h9]: o_code = 6'h9;
            i_vec[6'ha]: o_code = 6'ha;
            i_vec[6'hb]: o_code = 6'hb;
            i_vec[6'hc]: o_code = 6'hc;
            i_vec[6'hd]: o_code = 6'hd;
            i_vec[6'he]: o_code = 6'he;
            i_vec[6'hf]: o_code = 6'hf;
            i_vec[6'h10]: o_code = 6'h10;
            i_vec[6'h11]: o_code = 6'h11;
            i_vec[6'h12]: o_code = 6'h12;
            i_vec[6'h13]: o_code = 6'h13;
            i_vec[6'h14]: o_code = 6'h14;
            i_vec[6'h15]: o_code = 6'h15;
            i_vec[6'h16]: o_code = 6'h16;
            i_vec[6'h17]: o_code = 6'h17;
            i_vec[6'h18]: o_code = 6'h18;
            i_vec[6'h19]: o_code = 6'h19;
            i_vec[6'h1a]: o_code = 6'h1a;
            i_vec[6'h1b]: o_code = 6'h1b;
            i_vec[6'h1c]: o_code = 6'h1c;
            i_vec[6'h1d]: o_code = 6'h1d;
            i_vec[6'h1e]: o_code = 6'h1e;
            i_vec[6'h1f]: o_code = 6'h1f;
            i_vec[6'h20]: o_code = 6'h20;
            i_vec[6'h21]: o_code = 6'h21;
            i_vec[6'h22]: o_code = 6'h22;
            i_vec[6'h23]: o_code = 6'h23;
            i_vec[6'h24]: o_code = 6'h24;
            i_vec[6'h25]: o_code = 6'h25;
            i_vec[6'h26]: o_code = 6'h26;
            i_vec[6'h27]: o_code = 6'h27;
            i_vec[6'h28]: o_code = 6'h28;
            i_vec[6'h29]: o_code = 6'h29;
            i_vec[6'h2a]: o_code = 6'h2a;
            i_vec[6'h2b]: o_code = 6'h2b;
            i_vec[6'h2c]: o_code = 6'h2c;
            i_vec[6'h2d]: o_code = 6'h2d;
            i_vec[6'h2e]: o_code = 6'h2e;
            i_vec[6'h2f]: o_code = 6'h2f;
            i_vec[6'h30]: o_code = 6'h30;
            i_vec[6'h31]: o_code = 6'h31;
            i_vec[6'h32]: o_code = 6'h32;
            i_vec[6'h33]: o_code = 6'h33;
            i_vec[6'h34]: o_code = 6'h34;
            i_vec[6'h35]: o_code = 6'h35;
            i_vec[6'h36]: o_code = 6'h36;
            i_vec[6'h37]: o_code = 6'h37;
            i_vec[6'h38]: o_code = 6'h38;
            i_vec[6'h39]: o_code = 6'h39;
            i_vec[6'h3a]: o_code = 6'h3a;
            i_vec[6'h3b]: o_code = 6'h3b;
            i_vec[6'h3c]: o_code = 6'h3c;
            i_vec[6'h3d]: o_code = 6'h3d;
            i_vec[6'h3e]: o_code = 6'h3e;
            i_vec[6'h3f]: o_code = 6'h3f;
        endcase
    end
endmodule
