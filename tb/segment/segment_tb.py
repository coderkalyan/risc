import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge

WORD = 4
BYTES = WORD * 4
NOP = [0x00, 0x00, 0x00, 0x13][::-1]
CNOP = [0x00, 0x01][::-1]

def packets(segments, packet):
    if len(packet) >= BYTES:
        yield segments, packet
    else:
        yield from packets(segments + [1], packet + CNOP)
        if (len(packet) + 4) <= BYTES:
            yield from packets(segments + [1, 0], packet + NOP)

@cocotb.test()
async def segment_tests(dut):
    for valid, packet in packets([], []):
        buf = BinaryValue()
        buf.buff = bytes(packet)[::-1]
        dut.i_packet.value = buf

        await Timer(1, units="ns")
        dut._log.info(dut.o_valid.value, valid)
        for i, v in enumerate(valid):
            assert dut.o_valid[i].value == v
        # dut._log.info(dut.o_valid_count.value, valid, sum(valid))
        assert dut.o_valid_count.value == sum(valid)
