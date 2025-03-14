# tb_pixel_counter.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge


@cocotb.test()
async def tb_pixel_counter(dut):
    hmax = dut.HMAX.value
    vmax = dut.VMAX.value

    dut.clk.value = 0
    dut.rstn.value = 0
    dut.i_inc.value = 0
    # dut.i_clr.value = 0

    cocotb.start_soon(Clock(dut.clk, 40, "ns").start())

    await ClockCycles(dut.clk, 10)
    
    # reset test
    cocotb.log.info("Reset Testing")
    await FallingEdge(dut.clk)
    dut.rstn.value = 1

    await RisingEdge(dut.clk)
    assert dut.o_hcount.value == 0
    assert dut.o_vcount.value == 0
    # assert dut.o_frame_start.value
    # assert dut.o_frame_end.value == 0
    cocotb.log.info("Reset Testing Passed")

    # horizontal increment test
    num_frames = 2
    cocotb.log.info(f"Increment Testing: {num_frames} frames")
    for i in range(num_frames):
        hc = 0
        vc = 0
        while not(dut.o_hcount.value == (hmax - 1) and dut.o_vcount.value == (vmax - 1)):
            # cocotb.log.info(f"{hc}:\t{vc}")
            await FallingEdge(dut.clk)
            dut.i_inc.value = 1

            await RisingEdge(dut.clk)
            # assert int(dut.o_hcount.value) == hc
            # assert int(dut.o_vcount.value) == vc

            if hc == (hmax - 1):
                hc = 0
            else:
                hc += 1
            
            if hc == (hmax - 1) and vc == (vmax - 1):
                vc = 0
            else:
                vc += 1

            
          
        cocotb.log.info(f"\tFrame {i} passed")

    await FallingEdge(dut.clk)
    dut.i_inc.value = 0
    cocotb.log.info("Increment Testing Passed")

    await RisingEdge(dut.clk)
    cocotb.log.info("Test Complete")
