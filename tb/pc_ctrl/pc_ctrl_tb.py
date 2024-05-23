from random import randint
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge


async def reset_dut(rst_n, duration_ns):
    rst_n.value = 0
    await Timer(duration_ns, units="ns")
    rst_n.value = 1


@cocotb.test()
async def reset_tests(dut):
    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    await cocotb.start(reset_dut(dut.i_rst_n, 10))

    await Timer(5, units="ns")
    assert dut.o_pc.value == 0, "incorrect pc during reset"

    await Timer(5, units="ns")
    assert dut.o_pc.value == 0, "incorrect pc after reset"


@cocotb.test()
async def increment_tests(dut):
    clk = dut.i_clk
    cache_miss = dut.i_cache_miss
    di_count = dut.i_di_count
    pc = dut.o_pc

    dut.i_branch_en.value = 0
    dut.i_flush_en.value = 0

    cocotb.start_soon(Clock(dut.i_clk, 5, units="ns").start())
    await reset_dut(dut.i_rst_n, 3)

    expected = 0

    await RisingEdge(dut.i_rst_n)

    # no stall
    cache_miss.value = 0b0000
    di_count.value = 4
    for i in range(10):
        expected += 16

        await FallingEdge(clk)
        assert pc.value == expected, "no stall: pc not incrementing correctly"

    # dispatch stall
    cache_miss.value = 0b0000
    for i in range(4):
        di_count.value = i
        expected += i * 4

        await FallingEdge(clk)
        assert pc.value == expected, "dispatch stall: pc not incrementing correctly"

    # cache miss
    di_count.value = 4
    for i in range(16):
        cache_miss.value = i

        bitstring = f"{i:04b}"
        ctz = len(bitstring) - len(bitstring.lstrip('0'))
        expected += ctz * 4

        await FallingEdge(clk)
        assert pc.value == expected, "cache stall: pc not incrementing correctly"
