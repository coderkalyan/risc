`default_nettype none

`define ARITH_OP_ADD 3'h0
`define ARITH_OP_SLT 3'h1
`define ARITH_OP_MUL 3'h2
`define ARITH_OP_DIV 3'h3
`define ARITH_OP_REM 3'h4
`define ARITH_OP_RLI 3'h5

`define LOGIC_OP_XOR 3'h0
`define LOGIC_OP_OR 3'h1
`define LOGIC_OP_AND 3'h2
`define LOGIC_OP_SHIFT 3'h3

module decoder (
    input wire [31:0] i_inst,
    output wire o_compressed
);
    // uncompressed instructions (32 bit) end in 11
    wire [1:0] c_opcode = i_inst[1:0];
    wire compressed = c_opcode != 2'b11;

    // decoding of uncompressed instructions (word size)
    wire [4:0] w_opcode = i_inst[6:2];
    wire [4:0] w_rd = i_inst[11:7];
    wire [4:0] w_rs1 = i_inst[19:15];
    wire [4:0] w_rs2 = i_inst[24:20];
    wire [2:0] w_funct3 = i_inst[14:12];
    wire [6:0] w_funct7 = i_inst[31:25];

    // opcode parsing (word size)
    wire w_branch = w_opcode == 5'b11000;
    wire w_load = w_opcode == 5'b00000;
    wire w_store = w_opcode == 5'b01000;
    wire w_intri = w_opcode == 5'b00100;
    wire w_intrr = w_opcode == 5'b01100;
    wire w_jal = w_opcode == 5'b11011;
    wire w_jalr = w_opcode == 5'b11001;
    wire w_auipc = w_opcode == 5'b00101;
    wire w_lui = w_opcode == 5'b01101;
    wire w_env = w_opcode == 5'b11100;
    wire w_atomic = w_opcode == 5'b01011;
    wire w_fmadd = w_opcode == 5'b10000;
    wire w_fmsub = w_opcode == 5'b10001;
    wire w_fnmsub = w_opcode == 5'b10010;
    wire w_fnmadd = w_opcode == 5'b10011;
    wire w_float = w_opcode == 5'b10100;

    wire w_type_r = w_intrr;
    wire w_type_i = w_intri || w_load || w_jalr || w_env;
    wire w_type_s = w_store;
    wire w_type_b = w_branch;
    wire w_type_j = w_jal;
    wire w_type_u = w_auipc || w_lui;

    // immediate decoding (word size)
    wire [31:0] w_imm;
    assign w_imm[31] = i_inst[31];
    assign w_imm[30:20] = w_type_u ? i_inst[30:20] : i_inst[31];
    assign w_imm[19:12] = (w_type_u || w_type_j) ? i_inst[19:12] : i_inst[31];
    wire imm11_sext = i_inst[31] & !w_type_u;
    wire imm11_bj = w_type_b ? i_inst[7] : i_inst[20];
    assign w_imm[11] = (w_type_i || w_type_s) ? imm11_sext : imm11_bj;
    assign w_imm[10:5] = i_inst[30:25] & {6{!w_type_u}};
    assign w_imm[4:1] = ((w_type_i || w_type_j) ? i_inst[24:21] : i_inst[11:8]) & {4{!w_type_u}};
    assign w_imm[0] = (w_type_i ? i_inst[20] : i_inst[7]) & (w_type_b || w_type_u || w_type_j);

    // compressed instructions (16 bit)
    wire [15:0] c_inst = i_inst[15:0];
    wire [2:0] c_funct3 = c_inst[15:13];
    wire [3:0] c_funct4 = c_inst[15:12];
    //
    // wire c_c2 = c_opcode == 2'b10;
    // wire 
    // wire c_type_cr = (c_mode == 2'b00) && (c_opcode == 

    wire [1:0] load_op = w_funct3[1:0];     // 0 -> byte, 1 -> half, 2 -> word
    wire load_func = w_funct3[2];           // 0 -> signed, 1 -> unsigned

    wire [1:0] store_op = w_funct3[1:0];    // 0 -> byte, 1 -> half, 2 -> word
    wire [2:0] branch_op = w_funct3[2:0];

    reg [2:0] arith_op;
    reg [1:0] arith_func;
    always @(*) begin
        arith_op = 3'bxxx;
        arith_func = 1'bx;

        casex ({w_funct7[0], w_funct3})
            // RV32I
            4'b1000: begin
                arith_op = `ARITH_OP_ADD;
                arith_func = {1'b0, w_funct7[5]};
            end
            4'b101x: begin
                arith_op = `ARITH_OP_SLT;
                arith_func = {1'b0, w_funct3[0]};
            end
            // RV32M
            4'b00xx: begin
                arith_op = `ARITH_OP_MUL;
                arith_func = w_funct3[1:0];
            end
            4'b010x: begin
                arith_op = `ARITH_OP_DIV;
                arith_func = {1'b0, w_funct3[0]};
            end
            4'b011x: begin
                arith_op = `ARITH_OP_REM;
                arith_func = {1'b0, w_funct3[0]};
            end
        endcase
    end

    reg [2:0] logic_op;
    reg [1:0] logic_func;
    always @(*) begin
        logic_op = 3'bxxx;
        logic_func = 1'bx;

        casex (w_funct3)
            3'b100: begin
                logic_op = `LOGIC_OP_XOR;
                logic_func = 1'b0;
            end
            3'b110: begin
                logic_op = `LOGIC_OP_OR;
                logic_func = 1'b0;
            end
            3'b111: begin
                logic_op = `LOGIC_OP_AND;
                logic_func = 1'b0;
            end
            3'bx01: begin
                logic_op = `LOGIC_OP_SHIFT;
                logic_func = {1'b0, w_funct7[5], w_funct3[2]};
            end
        endcase
    end

    wire init_op = w_auipc;

    // reg op;
    // always @(*) begin
    //     case ()
    // end
endmodule
