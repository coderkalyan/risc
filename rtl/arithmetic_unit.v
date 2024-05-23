`default_nettype none

module arithmetic_unit #(
    parameter XLEN = 32
) (
    input wire i_clk,
    input wire i_rst_n,
    input wire [2:0] i_op,
    input wire [1:0] i_func,
    input wire [XLEN - 1:0] i_op1,
    input wire [XLEN - 1:0] i_op2,
    input wire i_start,
    output wire [XLEN - 1:0] o_result,
    output wire o_valid
);
    localparam STATE_IDLE = 1'b0;
    localparam STATE_DONE = 1'b1;

    reg state, next_state;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            state <= STATE_IDLE;
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
    
    reg next_valid, op2_sign;
    always @(*) begin
        next_state = state;
        next_valid = 1'b0;
        op2_sign = 1'b0;

        case (state)
            STATE_IDLE: begin
                if (i_start) begin
                    // TODO: support other operations
                    op2_sign = i_func[0];
                    next_state = STATE_IDLE;
                    next_valid = 1'b1;
                end
            end
            // STATE_DONE: begin
            //     valid = 1'b1;
            //     next_state = STATE_IDLE;
            // end
        endcase
    end

    wire [XLEN - 1:0] add_result = i_op1 + (i_op2 ^ {XLEN{op2_sign}}) + op2_sign;

    reg [XLEN - 1:0] result;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            result <= 0;
        else begin
            case (op)
                `ARITH_OP_ADD: result <= add_result;
                default: result <= {XLEN{1'bx}};
            endcase
        end
    end

    reg valid;
    always @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n)
            valid <= 1'b0;
        else
            valid <= next_valid;
    end

    assign o_valid = valid;
    assign o_result = result;
endmodule
