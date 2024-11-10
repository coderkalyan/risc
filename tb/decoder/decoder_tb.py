from random import randint
from collections import namedtuple
import enum
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge

Bundle = namedtuple("Bundle", ["rs1", "rs2", "rd", "unit", "op", "func", "immediate", "is_branch"])

class Unit(enum.Enum):
    ARITH = 0
    LOGIC = 1
    BRANCH = 2
    LOAD = 3
    STORE = 4

class ArithOp(enum.Enum):
    ADD = 0
    SLT = 1
    MUL = 2
    DIV = 3
    REM = 4

class LogicOp(enum.Enum):
    XOR = 0
    OR = 1
    AND = 2
    SHIFT = 3

def unpack(packed: int) -> Bundle:
    bits = f"{packed:057b}"
    rs1 = int(bits[0:5], 2)
    rs2 = int(bits[5:10], 2)
    rd = int(bits[10:15], 2)
    unit = int(bits[15:18], 2)
    op = int(bits[18:21], 2)
    func = int(bits[21:24], 2)
    immediate = int(bits[24:56], 2)
    is_branch = int(bits[56:57], 2)
    
    return Bundle(rs1, rs2, rd, unit, op, func, immediate, is_branch)

def pack_i(opcode: int, funct3: int, rs1: int, rd: int, immediate: int) -> int:
    assert opcode < 2 ** 7, "opcode out of range"
    assert funct3 < 2 ** 3, "funct3 out of range"
    assert rs1 < 2 ** 5, "rs1 out of range"
    assert rd < 2 ** 5, "rd out of range"
    assert immediate < 2 ** 12, "immediate out of range"

    result = 0
    result |= immediate << 20
    result |= rs1 << 15
    result |= funct3 << 12
    result |= rd << 7
    result |= opcode << 0

    return result

@cocotb.test()
async def intri_tests(dut):
    opcode = 0b0010011
    functs = {
        "addi": 0b000,
        "slti": 0b010,
        "sltiu": 0b011,
        "xori": 0b100,
        "ori": 0b110,
        "andi": 0b111,
    }

    for operation, funct3 in functs.items():
        for i in range(1000):
            immediate = randint(-(2 ** 11), 2 ** 11 - 1)
            rs1 = randint(0, 31)
            rd = randint(0, 31)
            dut.i_inst.value = pack_i(opcode, funct3, rs1, rd, immediate)
            await Timer(1, units="ns")

            # internal signals
            assert dut.c_opcode == 0b11
            assert dut.compressed.value == 0
            assert dut.w_opcode.value == opcode >> 2
            assert dut.w_rd.value == rd
            assert dut.w_rs1.value == rs1
            assert dut.w_funct3.value == funct3

            assert dut.w_branch.value == 0
            assert dut.w_load.value == 0
            assert dut.w_store.value == 0
            assert dut.w_intri.value == 1
            assert dut.w_intrr.value == 0
            assert dut.w_jal.value == 0
            assert dut.w_jalr.value == 0
            assert dut.w_auipc.value == 0
            assert dut.w_lui.value == 0
            assert dut.w_env.value == 0
            assert dut.w_atomic.value == 0
            assert dut.w_fmadd.value == 0
            assert dut.w_fmsub.value == 0
            assert dut.w_fnmsub.value == 0
            assert dut.w_fnmadd.value == 0
            assert dut.w_float.value == 0

            assert dut.w_type_r.value == 0
            assert dut.w_type_i.value == 1
            assert dut.w_type_s.value == 0
            assert dut.w_type_b.value == 0
            assert dut.w_type_j.value == 0
            assert dut.w_type_u.value == 0

            dut._log.info("%032b %d %032b %d", immediate, immediate, dut.w_imm.value, dut.w_imm.value)
            assert dut.w_imm.value == immediate

            # external signals
            bundle = unpack(int(dut.o_bundle.value))
            assert bundle.rs1 == rs1
            assert bundle.rd == rd

            if operation == "addi":
                assert bundle.unit == Unit.ARITH
                assert bundle.op == ArithOp.ADD
                assert bundle.func == 0b00
            elif operation == "slti":
                assert bundle.unit == Unit.ARITH
                assert bundle.op == ArithOp.SLT
                assert bundle.func == 0b00
            elif operation == "sltiu":
                assert bundle.unit == Unit.ARITH
                assert bundle.op == ArithOp.SLT
                assert bundle.func == 0b01
            elif operation == "xori":
                assert bundle.unit == Unit.LOGIC
                assert bundle.op == LogicOp.XOR
                assert bundle.func == 0b000
            elif operation == "ori":
                assert bundle.unit == Unit.LOGIC
                assert bundle.op == LogicOp.OR
                assert bundle.func == 0b000
            elif operation == "andi":
                assert bundle.unit == Unit.AND
                assert bundle.op == LogicOp.AND
                assert bundle.func == 0b000

            assert bundle.immediate == immediate
            assert bundle.is_branch == 0
