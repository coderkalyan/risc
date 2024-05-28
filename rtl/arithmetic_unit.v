`default_nettype none

module arithmetic_unit #(
    parameter XLEN = 32
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [2:0] i_op,
    input wire [1:0] i_func,
    input wire [XLEN - 1:0] i_rs1,
    input wire [XLEN - 1:0] i_rs2,
    input wire i_start,
    output wire [XLEN - 1:0] o_result,
    output wire o_valid
);
    wire op2_sign = i_func[0];
    wire [XLEN - 1:0] add_result = i_rs1 + (i_rs2 ^ {XLEN{op2_sign}}) + op2_sign;

    localparam STATE_INVALID = 1'b0;
    localparam STATE_VALID = 1'b1;

    reg state, next_state;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            state <= STATE_INVALID;
        else
            state <= next_state;
    end

    reg [2:0] op;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            op <= 3'b000;
        else if (i_start)
            op <= i_op;
    end

    always @(*) begin
        next_state = state;

        case (state)
            STATE_INVALID: begin
                if (i_start) begin
                    case (i_op)
                        `ARITH_OP_ADD: next_state = STATE_VALID;
                    endcase
                end
            end
            STATE_VALID: begin
                if (i_start) begin
                    case (i_op)
                        `ARITH_OP_ADD: next_state = STATE_VALID;
                    endcase
                end else begin
                    next_state = STATE_INVALID;
                end
            end
        endcase
    end


    reg [XLEN - 1:0] result;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            result <= {XLEN{1'b0}};
        else begin
            case (op)
                `ARITH_OP_ADD: result <= add_result;
                default: result <= {XLEN{1'bx}};
            endcase
        end
    end

    assign o_valid = state == STATE_VALID;
    assign o_result = result;
endmodule
