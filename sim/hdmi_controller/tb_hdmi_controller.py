# tb_hdmi_controller.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge


async def pixel_count_driver(dut):
    hc = 0
    vc = 0
    while True:
        await FallingEdge(dut.clk)
        if hc < int(dut.HMAX.value):
            hc += 1
        else:
            if vc < int(dut.VMAX.value):
                vc += 1
            else:
                vc = 0
            hc = 0
        dut.i_hcount.value = hc
        dut.i_vcount.value = vc


@cocotb.test()
async def tb_hdmi_controller(dut):
    cocotb.start_soon(Clock(dut.clk, 40, "ns").start())

    dut.rstn.value = 0
    dut.i_hcount.value = 0
    dut.i_vcount.value = 0

    await FallingEdge(dut.clk)
    dut.rstn.value = 1

    await RisingEdge(dut.clk)
    cocotb.start_soon(pixel_count_driver(dut))

    await ClockCycles(dut.clk, 500000)
    cocotb.log.info("Test Complete")
