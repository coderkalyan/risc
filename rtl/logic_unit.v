`default_nettype none

module logic_unit #(
    parameter XLEN = 32
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [1:0] i_op,
    input wire [2:0] i_func,
    input wire [XLEN - 1:0] i_op1,
    input wire [XLEN - 1:0] i_op2,
    input wire i_start,
    output wire [XLEN - 1:0] o_result,
    output wire o_valid
);
    reg [1:0] op;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            op <= 2'b00;
        else if (i_start)
            op <= i_op;
    end

    reg [1:0] func;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            func <= 3'b000;
        else if (i_start)
            func <= i_func;
    end

    // currently, all operations are single cycle, so
    // i_start propogates to valid in one clock cycle
    reg valid;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            valid <= 1'b0;
        else
            valid <= i_start;
    end

    wire [XLEN - 1:0] xor_result = (i_op1 ^ i_op2) ^ {XLEN{func[0]}};
    wire [XLEN - 1:0] or_result = i_op1 | (i_op2 ^ {XLEN{func[0]}});
    wire [XLEN - 1:0] and_result = i_op1 & (i_op2 ^ {XLEN{func[0]}});

    wire [XLEN - 1:0] shift_result;
    shifter shifter (
        .i_operand(i_op1),
        .i_amount(i_op2[$clog2(XLEN) - 1:0]),
        .i_dir(func[0] ? `SHIFT_DIR_RIGHT : `SHIFT_DIR_LEFT),
        .i_mode(func[2] ? `SHIFT_MODE_ROTATE : `SHIFT_MODE_SHIFT),
        .i_arith(func[1] ? `SHIFT_ARITHMETIC : `SHIFT_LOGICAL),
        .o_result(shift_result)
    );

    reg [XLEN - 1:0] result;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            result <= 0;
        end else begin
            case (op)
                `LOGIC_OP_XOR: result <= xor_result;
                `LOGIC_OP_OR: result <= or_result;
                `LOGIC_OP_AND: result <= and_result;
                `LOGIC_OP_SHIFT: result <= shift_result;
                default: result <= {XLEN{1'bx}};
            endcase
        end
    end

    assign o_result = result;
    assign o_valid = valid;
endmodule
