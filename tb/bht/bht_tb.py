from random import randint
import itertools
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge


async def reset_dut(rst_n, duration_ns):
    rst_n.value = 0
    await Timer(duration_ns, units="ns")
    rst_n.value = 1


# similar to itertools cycle
def cycle(vector, count):
    for _ in range(count):
        for element in vector:
            yield element


async def simulate(dut, addr, vector, warmup, inference):
    pred_addr, update_addr = dut.i_pred_addr, dut.i_update_addr
    update_taken, update_en = dut.i_update_taken, dut.i_update_en
    pred = dut.o_pred

    pred_addr.value = addr
    update_addr.value = addr

    # warmup
    for taken in cycle(vector, warmup):
        update_taken.value = taken
        update_en.value = 1
        await FallingEdge(dut.i_clk)

    # simulation (inference)
    count = 0
    for taken in cycle(vector, inference):
        update_en.value = 0
        await FallingEdge(dut.i_clk)
        prediction = pred.value
        if prediction == taken:
            count += 1

        update_taken.value = taken
        update_en.value = 1
        await FallingEdge(dut.i_clk)

    return count / (len(vector) * inference)

# @cocotb.test()
# async def reset_tests(dut):
#     cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
#     await cocotb.start(reset_dut(dut.i_rst_n, 10))
#
#     await Timer(5, units="ns")
#     assert dut.o_pc.value == 0, "incorrect pc during reset"
#
#     await Timer(5, units="ns")
#     assert dut.o_pc.value == 0, "incorrect pc after reset"


@cocotb.test()
async def prediction_tests(dut):
    clk = dut.i_clk

    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    await reset_dut(dut.i_rst_n, 3)

    # 1 - always taken
    vector = [1, 1, 1]
    accuracy = await simulate(dut, 0x0, vector, 2, 100)
    assert accuracy == 1.0

    # 2 - always not taken
    vector = [0, 0, 0]
    accuracy = await simulate(dut, 0x0, vector, 2, 100)
    assert accuracy == 1.0

    # 3 - alternating
    vector = [0, 1]
    accuracy = await simulate(dut, 0x0, vector, 5, 100)
    assert accuracy == 1.0

    # 4 - should be able to 100% guess any 4 bit pattern
    for vector in itertools.product((0, 1), repeat=4):
        accuracy = await simulate(dut, 0x0, vector, 5, 100)
        assert accuracy == 1.0

    # 5 - one in every 10 is not taken, should be 90% accuracy
    vector = [1, 1, 1, 1, 1, 1, 1, 1, 1, 0]
    accuracy = await simulate(dut, 0x0, vector, 5, 100)
    assert accuracy >= 0.9
