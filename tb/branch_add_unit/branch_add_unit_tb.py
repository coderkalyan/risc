from random import randint
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge


async def reset_dut(rst_n, duration_ns):
    rst_n.value = 0
    await Timer(duration_ns, units="ns")
    rst_n.value = 1


async def test_valid(dut):
    while True:
        await RisingEdge(dut.i_clk)
        started = dut.i_start.value
        await FallingEdge(dut.i_clk)
        assert dut.o_valid.value == started, "valid did not propogate"


async def test_prediction(dut):
    pred = dut.i_pred
    taken = dut.o_taken
    valid = dut.o_valid
    flush = dut.o_flush

    while True:
        # await RisingEdge(dut.i_clk)
        rand = randint(0, 1)
        pred.value = rand
        await FallingEdge(dut.i_clk)
        if valid.value == 1:
            assert flush.value == (0 if taken.value == rand else 1), "did not assert flush"

@cocotb.test()
async def reset_tests(dut):
    dut.i_start.value = 0

    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    await cocotb.start(reset_dut(dut.i_rst_n, 10))

    await Timer(5, units="ns")
    assert dut.o_valid.value == 0, "dut asserted valid during reset"

    await Timer(10, units="ns")
    assert dut.o_valid.value == 0, "dut asserted valid after reset"

@cocotb.test()
async def valid_tests(dut):
    clk = dut.i_clk
    start = dut.i_start
    valid = dut.o_valid

    start.value = 0

    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    cocotb.start_soon(test_valid(dut))
    await reset_dut(dut.i_rst_n, 10)

    rand = randint(0, 1)
    for i in range(10):
        start.value = rand
        await FallingEdge(clk)
        rand = randint(0, 1)

@cocotb.test()
async def eq_tests(dut):
    clk = dut.i_clk
    start = dut.i_start
    func = dut.i_func
    rs1 = dut.i_rs1
    rs2 = dut.i_rs2
    taken = dut.o_taken
    valid = dut.o_valid
    pred = dut.i_pred

    start.value = 0
    rs1.value = 0
    rs2.value = 0
    func.value = 0b000
    pred.value = 0

    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    cocotb.start_soon(test_valid(dut))
    cocotb.start_soon(test_prediction(dut))
    await reset_dut(dut.i_rst_n, 10)

    # test equal values
    for i in range(100):
        rand = randint(0, 2 ** 32 - 1)

        func.value = 0b000
        rs1.value = rand
        rs2.value = rand
        start.value = 1
        await FallingEdge(clk)
        assert taken.value == 1, "equality should be asserted"

        func.value = 0b001
        rs1.value = rand
        rs2.value = rand
        start.value = 1
        await FallingEdge(clk)
        assert taken.value == 0, "inequality should be asserted"

    # test unequal values
    for i in range(100):
        rand1 = randint(0, 2 ** 32 - 1)
        rand2 = randint(0, 2 ** 32 - 1)
        while rand2 == rand1:
            rand2 = randint(0, 2 ** 32 - 1)

        func.value = 0b000
        rs1.value = rand1
        rs2.value = rand2
        start.value = 1
        await FallingEdge(clk)
        assert taken.value == 0, "equality should be asserted"

        func.value = 0b001
        rs1.value = rand1
        rs2.value = rand2
        start.value = 1
        await FallingEdge(clk)
        assert taken.value == 1, "inequality should be asserted"

@cocotb.test()
async def scmp_tests(dut):
    clk = dut.i_clk
    start = dut.i_start
    func = dut.i_func
    rs1 = dut.i_rs1
    rs2 = dut.i_rs2
    taken = dut.o_taken
    valid = dut.o_valid
    pred = dut.i_pred
    flush = dut.o_flush

    start.value = 0
    rs1.value = 0
    rs2.value = 0
    func.value = 0b000
    pred.value = 0

    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    cocotb.start_soon(test_valid(dut))
    cocotb.start_soon(test_prediction(dut))
    await reset_dut(dut.i_rst_n, 10)

    # test signed comparisons
    for i in range(100):
        rand1 = randint(-(2 ** 31), 2 ** 31 - 1)
        rand2 = randint(-(2 ** 31), 2 ** 31 - 1)

        await FallingEdge(clk)
        func.value = 0b100
        rs1.value = rand1
        rs2.value = rand2
        start.value = 1

        await RisingEdge(clk)
        await Timer(1, units="ns")
        assert valid.value == 1, "valid should be asserted"
        assert taken.value == (rand1 < rand2), "signed less than incorrect"

        await FallingEdge(clk)
        func.value = 0b101
        rs1.value = rand1
        rs2.value = rand2
        start.value = 1

        await RisingEdge(clk)
        await Timer(1, units="ns")
        assert valid.value == 1, "valid should be asserted"
        assert taken.value == (rand1 >= rand2), "signed greater than equal incorrect"

@cocotb.test()
async def ucmp_tests(dut):
    clk = dut.i_clk
    start = dut.i_start
    func = dut.i_func
    rs1 = dut.i_rs1
    rs2 = dut.i_rs2
    taken = dut.o_taken
    valid = dut.o_valid
    pred = dut.i_pred
    flush = dut.o_flush

    start.value = 0
    rs1.value = 0
    rs2.value = 0
    func.value = 0b000
    pred.value = 0

    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    cocotb.start_soon(test_valid(dut))
    cocotb.start_soon(test_prediction(dut))
    await reset_dut(dut.i_rst_n, 10)

    # test signed comparisons
    for i in range(100):
        rand1 = randint(0, 2 ** 32 - 1)
        rand2 = randint(0, 2 ** 32 - 1)

        await FallingEdge(clk)
        func.value = 0b110
        rs1.value = rand1
        rs2.value = rand2
        start.value = 1

        await RisingEdge(clk)
        await Timer(1, units="ns")
        assert valid.value == 1, "valid should be asserted"
        assert taken.value == (rand1 < rand2), "unsigned less than incorrect"

        await FallingEdge(clk)
        func.value = 0b111
        rs1.value = rand1
        rs2.value = rand2
        start.value = 1

        await RisingEdge(clk)
        await Timer(1, units="ns")
        assert valid.value == 1, "valid should be asserted"
        assert taken.value == (rand1 >= rand2), "unsigned greater than equal incorrect"
