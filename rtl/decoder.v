`default_nettype none

`define UNIT_ARITH 3'h0
`define UNIT_LOGIC 3'h1
`define UNIT_INIT  3'h2
`define UNIT_BRANCH 3'h3
`define UNIT_LOAD  3'h4
`define UNIT_STORE 3'h5

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

`define BRANCH_OP_CONDBR 2'h0
`define BRANCH_OP_JAL 2'h1
`define BRANCH_OP_JALR 2'h2

module decoder (
    input wire [31:0] i_inst,
    output wire [4:0] o_rs1,
    output wire [4:0] o_rs2,
    output wire [4:0] o_rd,
    output reg [2:0] o_unit,
    output reg [2:0] o_op,
    output reg [2:0] o_func,
    output wire [31:0] o_imm,
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

    // compressed instructioyosysyosys -p "prep -top my_top_module; write_json output.json" input.v -p "prep -top my_top_module; write_json output.json" input.vns (16 bit)
    wire [15:0] c_inst = i_inst[15:0];
    wire [2:0] c_funct3 = c_inst[15:13];
    wire [3:0] c_funct4 = c_inst[15:12];
    //
    // wire c_c2 = c_opcode == 2'b10;
    // wire 
    // wire c_type_cr = (c_mode == 2'b00) && (c_opcode == 

    wire [1:0] load_op = w_funct3[1:0];     // 0 -> byte, 1 -> half, 2 -> word
    wire load_func = w_funct3[2];           // 0 -> signed, 1 -> unsigned
    wire load_unit = w_load;

    wire [1:0] store_op = w_funct3[1:0];    // 0 -> byte, 1 -> half, 2 -> word
    wire store_unit = w_store;

    reg [2:0] arith_op;
    reg [1:0] arith_func;
    reg arith_unit;
    always @(*) begin
        arith_op = 3'bxxx;
        arith_func = 1'bx;
        arith_unit = 1'b0;

        casex ({w_funct7[0], w_funct3})
            // RV32I
            4'b0000: begin
                arith_op = `ARITH_OP_ADD;
                arith_func = {1'b0, w_funct7[5]};
                arith_unit = 1'b1;
            end
            4'b001x: begin
                arith_op = `ARITH_OP_SLT;
                arith_func = {1'b0, w_funct3[0]};
                arith_unit = 1'b1;
            end
            // RV32M
            4'b10xx: begin
                arith_op = `ARITH_OP_MUL;
                arith_func = w_funct3[1:0];
                arith_unit = 1'b1;
            end
            4'b110x: begin
                arith_op = `ARITH_OP_DIV;
                arith_func = {1'b0, w_funct3[0]};
                arith_unit = 1'b1;
            end
            4'b111x: begin
                arith_op = `ARITH_OP_REM;
                arith_func = {1'b0, w_funct3[0]};
                arith_unit = 1'b1;
            end
        endcase
    end

    reg [2:0] logic_op;
    reg [2:0] logic_func;
    reg logic_unit;
    always @(*) begin
        logic_op = 3'bxxx;
        logic_func = 3'bxxx;
        logic_unit = 1'b0;

        casex (w_funct3)
            3'b100: begin
                logic_op = `LOGIC_OP_XOR;
                logic_func = 3'b000;
                logic_unit = 1'b1;
            end
            3'b110: begin
                logic_op = `LOGIC_OP_OR;
                logic_func = 3'b000;
                logic_unit = 1'b1;
            end
            3'b111: begin
                logic_op = `LOGIC_OP_AND;
                logic_func = 3'b000;
                logic_unit = 1'b1;
            end
            3'bx01: begin
                logic_op = `LOGIC_OP_SHIFT;
                logic_func = {1'b0, w_funct7[5], w_funct3[2]};
                logic_unit = 1'b1;
            end
        endcase
    end

    wire init_op = w_auipc;
    wire init_unit = w_lui || w_auipc;

    reg [1:0] branch_op;
    reg [2:0] branch_func;
    reg branch_unit;
    always @(*) begin
        branch_op = 2'bxx;
        branch_func = 3'bxxx;
        branch_unit = 1'b0;

        case ({w_branch, w_jal, w_jalr})
            3'b100: begin
                branch_op = `BRANCH_OP_CONDBR;
                branch_func = w_funct3;
                branch_unit = 1'b1;
            end
            3'b010: begin
                branch_op = `BRANCH_OP_JAL;
                branch_unit = 1'b1;
            end
            3'b001: begin
                branch_op = `BRANCH_OP_JALR;
                branch_unit = 1'b1;
            end
        endcase
    end

    assign o_rs1 = w_rs1;
    assign o_rs2 = w_rs2;
    assign o_rd = w_rd;
    assign o_imm = w_imm;
    assign o_compressed = compressed;

    always @(*) begin
        o_unit = 3'bxxx;
        o_op = 3'bxxx;
        o_func = 3'bxx;

        case ({arith_unit, logic_unit, init_unit, branch_unit, load_unit, store_unit})
            6'b100000: begin
                o_unit = `UNIT_ARITH;
                o_op = arith_op;
                o_func = {1'bx, arith_func};
            end
            6'b010000: begin
                o_unit = `UNIT_LOGIC;
                o_op = logic_op;
                o_func = logic_func;
            end
            6'b001000: begin
                o_unit = `UNIT_INIT;
                o_op = init_op;
                o_func = 3'bxxx;
            end
            6'b000100: begin
                o_unit = `UNIT_BRANCH;
                o_op = {1'bx, branch_op};
                o_func = branch_func;
            end
            6'b000010: begin
                o_unit = `UNIT_LOAD;
                o_op = {1'bx, load_op};
                o_func = {2'bxx, load_func};
            end
            6'b000001: begin
                o_unit = `UNIT_STORE;
                o_op = {1'bx, store_op};
                o_func = 3'bxxx;
            end
        endcase
    end
endmodule
