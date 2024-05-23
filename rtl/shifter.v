`default_nettype none

`define SHIFT_DIR_RIGHT 1'b0
`define SHIFT_DIR_LEFT 1'b1
`define SHIFT_MODE_ROTATE 1'b0
`define SHIFT_MODE_SHIFT 1'b1
`define SHIFT_LOGICAL 1'b0
`define SHIFT_ARITHMETIC 1'b1

module shifter #(
    parameter WIDTH = 32,
    parameter BITS = $clog2(WIDTH)
) (
    input wire [WIDTH - 1:0] i_operand,
    input wire [BITS - 1:0] i_amount,
    input wire i_dir,
    input wire i_mode,
    input wire i_arith,
    output wire [WIDTH - 1:0] o_result
);
    wire [WIDTH - 1:0] ror [BITS:0];
    assign ror[0] = i_operand;

    wire [BITS - 1:0] amount = (i_dir == `SHIFT_DIR_LEFT) ? (WIDTH - i_amount) : i_amount;
    
    genvar i;
    generate
        for (i = 0; i < BITS; i = i + 1) begin
            assign ror[i + 1] = amount[i] ? {ror[i][2 ** i - 1:0], ror[i][WIDTH - 1:2 ** i]} : ror[i];
        end
    endgenerate

    wire mode_shift = i_mode == `SHIFT_MODE_SHIFT;
    wire dir_right = i_dir == `SHIFT_DIR_RIGHT;
    wire arith = mode_shift && dir_right && (i_arith == `SHIFT_ARITHMETIC);

    reg [WIDTH - 1:0] srl_mask;
    always @(*) begin
        // TODO: not sure how to parametrize this properly
        case (i_amount)
            0: srl_mask = 32'hffffffff;
            1: srl_mask = 32'h7fffffff;
            2: srl_mask = 32'h3fffffff;
            3: srl_mask = 32'h1fffffff;
            4: srl_mask = 32'h0fffffff;
            5: srl_mask = 32'h07ffffff;
            6: srl_mask = 32'h03ffffff;
            7: srl_mask = 32'h01ffffff;
            8: srl_mask = 32'h00ffffff;
            9: srl_mask = 32'h007fffff;
            10: srl_mask = 32'h003fffff;
            11: srl_mask = 32'h001fffff;
            12: srl_mask = 32'h000fffff;
            13: srl_mask = 32'h0007ffff;
            14: srl_mask = 32'h0003ffff;
            15: srl_mask = 32'h0001ffff;
            16: srl_mask = 32'h0000ffff;
            17: srl_mask = 32'h00007fff;
            18: srl_mask = 32'h00003fff;
            19: srl_mask = 32'h00001fff;
            20: srl_mask = 32'h00000fff;
            21: srl_mask = 32'h000007ff;
            22: srl_mask = 32'h000003ff;
            23: srl_mask = 32'h000001ff;
            24: srl_mask = 32'h000000ff;
            25: srl_mask = 32'h0000007f;
            26: srl_mask = 32'h0000003f;
            27: srl_mask = 32'h0000001f;
            28: srl_mask = 32'h0000000f;
            29: srl_mask = 32'h00000007;
            30: srl_mask = 32'h00000003;
            31: srl_mask = 32'h00000001;
        endcase
    end

    wire [WIDTH - 1:0] sll_mask;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign sll_mask[i] = srl_mask[WIDTH - i - 1];
        end
    endgenerate

    wire [WIDTH - 1:0] rotate_result = ror[BITS];
    wire [WIDTH - 1:0] mask = dir_right ? srl_mask : sll_mask;
    wire [WIDTH - 1:0] sext = {WIDTH{arith & i_operand[WIDTH - 1]}};
    wire [WIDTH - 1:0] shift_result = (rotate_result & mask) | (~mask & sext);
    assign o_result = mode_shift ? shift_result : rotate_result;
endmodule
