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

// output bundle:
// rs1 (5)
// rs2 (5)
// rd (5)
// execution unit (3)
// execution op select (3)
// execution func select (3)
// immediate (32)
// is branch (modifies control flow) (1)
// 5 + 5 + 5 + 3 + 3 + 3 + 32 + 1 = 57

module decoder (
    input wire [31:0] i_inst,
    output wire [56:0] o_bundle,
    output wire o_valid
);
    localparam UNIT_ASB = 3'h0;
    localparam UNIT_LOGIC = 3'h1;
    localparam UNIT_LOAD = 3'h2;
    localparam UNIT_STORE = 3'h3;

    localparam ASB_FUNC_PC_BIT = 0;
    localparam ASB_FUNC_IMM_BIT = 1;
    localparam ASB_FUNC_NEG_BIT = 2;
    localparam ASB_FUNC_UNSIGNED_BIT = 0;

    localparam ASB_OP_BRANCH = 3'h0;
    localparam ASB_OP_ADDSUB = 3'h1;
    localparam ASB_OP_SLT = 3'h2;

    localparam LOGIC_OP_XOR = 3'h0;
    localparam LOGIC_OP_OR = 3'h1;
    localparam LOGIC_OP_AND = 3'h2;
    localparam LOGIC_OP_SHIFT = 3'h3;

    // uncompressed instructions (32 bit) end in 11
    wire [1:0] c_opcode = i_inst[1:0];
    wire compressed = c_opcode != 2'b11;
    // for now, we reject all compressed instructions as invalid

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
    wire w_ecall = i_inst == 32'h00000073;
    wire w_ebreak = i_inst == 32'h00100073;

    reg valid;
    reg [2:0] unit, op, func;
    always @(*) begin
        valid = 1'b0;
        unit = 3'bxxx;
        op = 3'bxxx;
        func = 3'bxxx;

        case (1'b1)
            w_branch: begin
                case (w_funct3)
                    3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: valid = 1'b1;
                endcase
                unit = UNIT_ASB;
                op = ASB_OP_BRANCH;
                func[ASB_FUNC_PC_BIT] = 1'b1;
                func[ASB_FUNC_IMM_BIT] = 1'b1;
                func[ASB_FUNC_NEG_BIT] = 1'b0;
                func = w_funct3;
            end
            w_load: begin
                case (w_funct3)
                    3'b000, 3'b001, 3'b010, 3'b100, 3'b101: valid = 1'b1;
                endcase
                unit = UNIT_LOAD;
                op[1:0] = w_funct3[1:0];    // 0 -> byte, 1 -> half, 2 -> word
                func[0] = w_funct3[2];      // 0 -> signed, 1 -> unsigned
            end
            w_store: begin
                case (w_funct3)
                    3'b000, 3'b001, 3'b010: valid = 1'b1;
                endcase
                unit = UNIT_STORE;
                op[1:0] = w_funct3[1:0];    // 0 -> byte, 1 -> half, 2 -> word
            end
            w_intri: begin
                casex (w_funct3)
                    3'b000: begin
                        valid = 1'b1;
                        unit = UNIT_ASB;
                        op = ASB_OP_ADDSUB;
                        func[ASB_FUNC_PC_BIT] = 1'b0;
                        func[ASB_FUNC_IMM_BIT] = 1'b1;
                        func[ASB_FUNC_NEG_BIT] = w_funct7[5];
                    end
                    3'b01x: begin
                        valid = 1'b1;
                        unit = UNIT_ASB;
                        op = ASB_OP_SLT;
                        func[ASB_FUNC_UNSIGNED_BIT] = w_funct3[0];
                    end
                    3'b100: begin
                        valid = 1'b1;
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_XOR;
                    end
                    3'b110: begin
                        valid = 1'b1;
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_OR;
                    end
                    3'b111: begin
                        valid = 1'b1;
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_AND;
                    end
                    3'b001: begin
                        valid = w_funct7 == 7'b0000000;
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_SHIFT;
                        func[1] = w_funct7[5];
                        func[0] = w_funct3[2];
                    end
                    3'b101: begin
                        valid = (w_funct7 == 7'b0000000) || (w_funct7 == 7'b0100000);
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_SHIFT;
                        func[1] = w_funct7[5];
                        func[0] = w_funct3[2];
                    end
                endcase
            end
            w_intrr: begin
                casex (w_funct3)
                    3'b000: begin
                        valid = (w_funct7 == 7'b0000000) || (w_funct7 == 7'b0100000);
                        unit = UNIT_ASB;
                        op = ASB_OP_ADDSUB;
                        func[ASB_FUNC_PC_BIT] = 1'b0;
                        func[ASB_FUNC_IMM_BIT] = 1'b0;
                        func[ASB_FUNC_NEG_BIT] = w_funct7[5];
                    end
                    3'b01x: begin
                        valid = w_funct7 == 7'b0000000;
                        unit = UNIT_ASB;
                        op = ASB_OP_SLT;
                        func[ASB_FUNC_IMM_BIT] = 1'b0;
                        func[ASB_FUNC_UNSIGNED_BIT] = w_funct3[0];
                    end
                    3'b100: begin
                        valid = w_funct7 == 7'b0000000;
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_XOR;
                    end
                    3'b110: begin
                        valid = w_funct7 == 7'b0000000;
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_OR;
                    end
                    3'b111: begin
                        valid = w_funct7 == 7'b0000000;
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_AND;
                    end
                    3'b001: begin
                        valid = w_funct7 == 7'b0000000;
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_SHIFT;
                        func[1] = w_funct7[5];
                        func[0] = w_funct3[2];
                    end
                    3'b101: begin
                        valid = (w_funct7 == 7'b0000000) || (w_funct7 == 7'b0100000);
                        unit = UNIT_LOGIC;
                        op = LOGIC_OP_SHIFT;
                        func[1] = w_funct7[5];
                        func[0] = w_funct3[2];
                    end
                endcase
            end
            w_jal: begin
                valid = 1'b1;
                unit = UNIT_ASB;
                op = ASB_OP_ADDSUB;
                func[ASB_FUNC_PC_BIT] = 1'b1;
                func[ASB_FUNC_IMM_BIT] = 1'b1;
                func[ASB_FUNC_NEG_BIT] = 1'b0;
            end
            w_jalr: begin
                valid = w_funct3 == 3'b000;
                unit = UNIT_ASB;
                op = ASB_OP_ADDSUB;
                func[ASB_FUNC_PC_BIT] = 1'b0;
                func[ASB_FUNC_IMM_BIT] = 1'b0;
                func[ASB_FUNC_NEG_BIT] = 1'b0;
            end
            w_auipc: begin
                valid = 1'b1;
                unit = UNIT_ASB;
                op = ASB_OP_ADDSUB;
                func[ASB_FUNC_PC_BIT] = 1'b1;
                func[ASB_FUNC_IMM_BIT] = 1'b1;
                func[ASB_FUNC_NEG_BIT] = 1'b0;
            end
            w_lui: begin
                valid = 1'b1;
                unit = UNIT_ASB;
                op = ASB_OP_ADDSUB;
                func[ASB_FUNC_PC_BIT] = 1'b0;
                func[ASB_FUNC_IMM_BIT] = 1'b1;
                func[ASB_FUNC_NEG_BIT] = 1'b0;
            end
            w_ecall: begin
                valid = 1'b1;
            end
            w_ebreak: begin
                valid = 1'b1;
            end
        endcase
    end

    wire w_type_r = w_intrr;
    wire w_type_i = w_intri || w_load || w_jalr || w_ecall || w_ebreak;
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

    assign o_bundle = {w_rs1, w_rs2, w_rd, unit, op, func, w_imm, 1'b0};
    assign o_valid = valid && !compressed;

`ifdef FORMAL
    reg [31:0] f_inst;
    assign i_inst = f_inst;

    wire [6:0] f_opcode = f_inst[6:0];
    wire [2:0] f_funct3 = f_inst[14:12];
    wire [6:0] f_funct7 = f_inst[31:25];
    wire f_lui   = (f_opcode == 7'b0110111);
    wire f_auipc = (f_opcode == 7'b0010111);
    wire f_jal   = (f_opcode == 7'b1101111);
    wire f_jalr  = (f_opcode == 7'b1100111) && (f_funct3 == 3'b000);
    wire f_beq   = (f_opcode == 7'b1100011) && (f_funct3 == 3'b000);
    wire f_bne   = (f_opcode == 7'b1100011) && (f_funct3 == 3'b001);
    wire f_blt   = (f_opcode == 7'b1100011) && (f_funct3 == 3'b100);
    wire f_bge   = (f_opcode == 7'b1100011) && (f_funct3 == 3'b101);
    wire f_bltu  = (f_opcode == 7'b1100011) && (f_funct3 == 3'b110);
    wire f_bgeu  = (f_opcode == 7'b1100011) && (f_funct3 == 3'b111);
    wire f_lb    = (f_opcode == 7'b0000011) && (f_funct3 == 3'b000);
    wire f_lh    = (f_opcode == 7'b0000011) && (f_funct3 == 3'b001);
    wire f_lw    = (f_opcode == 7'b0000011) && (f_funct3 == 3'b010);
    wire f_lbu   = (f_opcode == 7'b0000011) && (f_funct3 == 3'b100);
    wire f_lhu   = (f_opcode == 7'b0000011) && (f_funct3 == 3'b101);
    wire f_sb    = (f_opcode == 7'b0100011) && (f_funct3 == 3'b000);
    wire f_sh    = (f_opcode == 7'b0100011) && (f_funct3 == 3'b001);
    wire f_sw    = (f_opcode == 7'b0100011) && (f_funct3 == 3'b010);
    wire f_addi  = (f_opcode == 7'b0010011) && (f_funct3 == 3'b000);
    wire f_slti  = (f_opcode == 7'b0010011) && (f_funct3 == 3'b010);
    wire f_sltiu = (f_opcode == 7'b0010011) && (f_funct3 == 3'b011);
    wire f_xori  = (f_opcode == 7'b0010011) && (f_funct3 == 3'b100);
    wire f_ori   = (f_opcode == 7'b0010011) && (f_funct3 == 3'b110);
    wire f_andi  = (f_opcode == 7'b0010011) && (f_funct3 == 3'b111);
    wire f_slli  = (f_opcode == 7'b0010011) && (f_funct3 == 3'b001) && (f_funct7 == 7'b0000000);
    wire f_srli  = (f_opcode == 7'b0010011) && (f_funct3 == 3'b101) && (f_funct7 == 7'b0000000);
    wire f_srai  = (f_opcode == 7'b0010011) && (f_funct3 == 3'b101) && (f_funct7 == 7'b0100000);
    wire f_add   = (f_opcode == 7'b0110011) && (f_funct3 == 3'b000) && (f_funct7 == 7'b0000000);
    wire f_sub   = (f_opcode == 7'b0110011) && (f_funct3 == 3'b000) && (f_funct7 == 7'b0100000);
    wire f_sll   = (f_opcode == 7'b0110011) && (f_funct3 == 3'b001) && (f_funct7 == 7'b0000000);
    wire f_slt   = (f_opcode == 7'b0110011) && (f_funct3 == 3'b010) && (f_funct7 == 7'b0000000);
    wire f_sltu  = (f_opcode == 7'b0110011) && (f_funct3 == 3'b011) && (f_funct7 == 7'b0000000);
    wire f_xor   = (f_opcode == 7'b0110011) && (f_funct3 == 3'b100) && (f_funct7 == 7'b0000000);
    wire f_srl   = (f_opcode == 7'b0110011) && (f_funct3 == 3'b101) && (f_funct7 == 7'b0000000);
    wire f_sra   = (f_opcode == 7'b0110011) && (f_funct3 == 3'b101) && (f_funct7 == 7'b0100000);
    wire f_or    = (f_opcode == 7'b0110011) && (f_funct3 == 3'b110) && (f_funct7 == 7'b0000000);
    wire f_and   = (f_opcode == 7'b0110011) && (f_funct3 == 3'b111) && (f_funct7 == 7'b0000000);
    wire f_ecall = f_inst == 32'b000000000000_00000_000_00000_1110011;
    wire f_ebreak = f_inst == 32'b000000000001_00000_000_00000_1110011;

    wire f_valid_inst = f_lui || f_auipc || f_jal || f_jalr ||
                        f_beq || f_bne || f_blt || f_bge || f_bltu || f_bgeu ||
                        f_lb || f_lh || f_lw || f_lbu || f_lhu || f_sb || f_sh || f_sw ||
                        f_addi || f_slti || f_sltiu || f_xori || f_ori || f_andi ||
                        f_slli || f_srli || f_srai ||
                        f_add || f_sub || f_sll || f_slt || f_sltu || f_xor ||
                        f_srl || f_sra || f_or || f_and ||
                        f_ecall || f_ebreak;

    integer i;
    always @(*) begin
        assert(o_valid == f_valid_inst);
        if (f_valid_inst) begin
            assert((w_type_r + w_type_i + w_type_s + w_type_b + w_type_j + w_type_u) == 1);
        end

        cover(w_type_r);
        cover(w_type_i);
        cover(w_type_s);
        cover(w_type_b);
        cover(w_type_j);
        cover(w_type_u);

        cover(w_branch);
        cover(w_load);
        cover(w_store);
        cover(w_intri);
        cover(w_intrr);
        cover(w_jal);
        cover(w_jalr);
        cover(w_auipc);
        cover(w_lui);
        cover(w_ecall);
        cover(w_ebreak);

        // if (!f_ecall && !f_ebreak)
        //     for (i = 0; i < 32; i = i + 1) cover(w_rd == )
    end
`endif
endmodule
