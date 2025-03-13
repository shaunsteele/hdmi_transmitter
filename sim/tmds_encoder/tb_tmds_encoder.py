# tb_tmds_encoder.py

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge

from pyuvm import uvm_sequence_item

import vsc


@vsc.randobj
class TmdsEncoderModel(uvm_sequence_item):
    cnt = 0
    def __init__(self, dut):
        self.clk = dut.clk
        self.dut = dut
        self.data_en = vsc.rand_bit_t()
        self.ctrl = vsc.rand_bit_t(2)
        self.data = vsc.rand_bit_t(8)

    def encode(self):
        de = int(self.dut.i_data_en.value)
        d = int(self.dut.i_data.value)
        ctrl = int(self.dut.i_ctrl.value)

        self.q_m = 0
        self.q_m = d & 0x1
        d_ones = format(d & 0xFF, '08b').replace("0b", "").count('1')
        if (d_ones > 4) or ((d_ones == 4) and (d & 0x1 == 0)):
            # 0b1110_0010 0b1111_0100
            for b in range(1, 8):
                curr_mask = 2 ** b
                prev_mask = 2 ** (b - 1)
                self.q_m |= (~(((self.q_m & prev_mask) >> (b - 1)) ^ ((d & curr_mask) >> b)) << b) & curr_mask
            self.q_m &= 0x0FF
        else:
            for b in range(1, 8):
                curr_mask = 2 ** b
                prev_mask = 2 ** (b - 1)
                self.q_m |= ((((self.q_m & prev_mask) >> (b - 1)) ^ ((d & curr_mask) >> b)) << b) & curr_mask
            self.q_m |= 0x100
        
        self.cnt_prev = self.cnt
        self.q_m_ones = format(self.q_m & 0xFF, '08b').replace("0b", "").count('1')
        self.q_m_zeroes = format(self.q_m & 0xFF, '08b').replace("0b", "").count('0')
        # cocotb.log.info(f"ones: {self.q_m_ones}\tzeroes: {self.q_m_zeroes}")
        q = 0
        if de:
            if (self.cnt == 0) or (self.q_m_ones == self.q_m_zeroes):
                q |= (~self.q_m & 0x100) << 1
                q |= self.q_m & 0x100
                q |= self.q_m & 0xFF if self.q_m & 0x100 else ~self.q_m & 0xFF
                if self.q_m & 0x100:
                    self.cnt = self.cnt + self.q_m_ones - self.q_m_zeroes
                else:
                    self.cnt = self.cnt + self.q_m_zeroes - self.q_m_ones
            else:
                if ((self.cnt > 0) and (self.q_m_ones > self.q_m_zeroes)) or \
                    ((self.cnt < 0) and (self.q_m_ones < self.q_m_zeroes)):
                    q |= 0x200
                    q |= self.q_m & 0x100
                    q |= ~self.q_m & 0xFF
                    # cocotb.log.info(f"{self.cnt}\t{(q & 0x100) >> 7}\t{self.q_m_zeroes}\t{self.q_m_ones}")
                    self.cnt = self.cnt + ((q & 0x100) >> 7) + self.q_m_zeroes - self.q_m_ones
                else:
                    q &= 0x1FF
                    q |= self.q_m & 0x100
                    q |= self.q_m & 0xFF
                    # cocotb.log.info(f"{self.cnt}\t{(~q & 0x100) >> 7}\t{self.q_m_ones}\t{self.q_m_zeroes}")
                    self.cnt = self.cnt - ((~q & 0x100) >> 7) + self.q_m_ones - self.q_m_zeroes
            return q
        else:
            self.cnt = 0
            if ctrl == 0b00:
                q = 0b00_1010_1011  # 0x0AB
            elif ctrl == 0b01:
                q = 0b11_0101_0100  # 0x354
            elif ctrl == 0b10:
                q = 0b00_1010_1010  # 0x0AA
            elif ctrl == 0b11:
                q = 0b11_0101_0101  # 0x355
            return q

    async def set_data_en(self):
        await FallingEdge(self.clk)
        self.dut.i_data_en.value = 1
    
    async def reset_data_en(self):
        await FallingEdge(self.clk)
        self.dut.i_data_en.value = 0
    
    def post_randomize(self):
        self.dut.i_data_en.value = self.data_en
        self.dut.i_data.value = self.data
        self.dut.i_ctrl.value = self.ctrl

    async def check(self):
        while True:
            await RisingEdge(self.clk)
            q_exp = self.encode()
            s = f"DE: {int(self.dut.i_data_en.value)}"
            s = f"{s}\tCTRL: {self.dut.i_ctrl.value}"
            s = f"{s}\tD: {int(self.dut.i_data.value):#04x}"
            s = f"{s}\tQ: {int(self.dut.o_q.value):#05x}"
            s = f"{s}\tQExp: {q_exp:#05x}"
            # s = f"{s}\tQ_M: {int(self.dut.q_m.value):#05x}"
            # s = f"{s}\tQ_MExp: {self.q_m:#05x}"
            # s = f"{s}\tCNT_PREV: {int(self.cnt_prev):#05x}"
            # s = f"{s}\tCNT: {int(self.dut.cnt.value):#04x} {int(self.dut.cnt.value)}"
            # s = f"{s}\tCNTExp: {int(self.cnt):#04x} {hex(self.cnt)}"
            # s = f"{s}\tQ_M_ZEROES: {int(self.dut.q_zeroes.value):#05x}"
            # s = f"{s}\tQ_M_ZEROESExp: {self.q_m_zeroes:#05x}"
            cocotb.log.info(s)
            s = f"\tQ_M: {int(self.dut.q_m.value):#05x}"
            s = f"{s}\tQ_MExp: {self.q_m:#05x}"
            s = f"{s}\tCNT: {int(self.dut.cnt.value)}"
            s = f"{s}\tCNTExp: {abs(self.cnt)}"
            s = f"{s}\tQ_M_ZEROES: {int(self.dut.q_zeroes.value)}"
            s = f"{s}\tQ_M_ZEROESExp: {self.q_m_zeroes}"
            assert int(self.dut.o_q.value) == q_exp, s

@cocotb.test()
async def tb_tmds_encoder(dut):
    cocotb.start_soon(Clock(dut.clk, 40, "ns").start())

    dut.i_data_en.value = 0
    dut.i_data.value = 0
    dut.i_ctrl.value = 0
    
    model = TmdsEncoderModel(dut) 
    cocotb.start_soon(model.check())

    await ClockCycles(dut.clk, 1)
    
    # dut.i_data.value = 0xFF
    await model.set_data_en()
    await ClockCycles(dut.clk, 640)
    await model.reset_data_en()

    for _ in range(100000):
        await FallingEdge(dut.clk)
        model.randomize()


    # await ClockCycles(dut.clk, 3)
    cocotb.log.info("Test Complete")
