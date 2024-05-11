`default_nettype none

module decoder (
    input wire [31:0] i_inst
    output wire o_compressed,
);
    // uncompressed instructions (32 bit) end in 11
    wire [1:0] compress_mode = i_inst[1:0];
    wire compressed = compress_mode != 2'b11;

    // decoding of uncompressed instructions (word size)
    wire w_opcode = i_inst[6:2];
    wire w_rd = i_inst[11:7];
    wire w_rs1 = i_inst[19:15];
    wire w_rs2 = i_inst[24:20];
    wire w_funct3 = i_inst[14:12];
    wire w_funct7 = i_inst[31:25];

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
    wire w_imm[31:0];
    assign w_imm[31] = i_inst[31];
    assign w_imm[30:20] = w_type_u ? i_inst[30:20] : i_inst[31];
    assign w_imm[19:12] = (w_type_u || w_type_j) ? i_inst[19:12] : i_inst[31];
    wire imm11_sext = i_inst[31] & !w_type_u;
    wire imm11_bj = w_type_b ? i_inst[7] : i_inst[20];
    assign w_imm[11] = ((w_type_i || w_type_s) ? imm11_sext : imm11_bj;
    assign w_imm[10:5] = i_inst[30:25] & {6{!w_type_u}};
    assign w_imm[4:1] = ((w_type_i || w_type_j) ? i_inst[24:21] : i_inst[11:8]) & {4{!w_type_u}};
    assign w_imm[0] = (w_type_i ? i_inst[20] : i_inst[7]) & (w_type_b || w_type_u || w_type_j);

    // compressed instructions (16 bit)
    wire [15:0] c_inst = i_inst[15:0];
endmodule
