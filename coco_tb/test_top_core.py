import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def cycle_counter(dut):
    while True:
        await RisingEdge(dut.hclk)
        dut.cycle_cnt.value = (dut.cycle_cnt.value % 4) + 1

@cocotb.coroutine
async def wait_for_signal_change(signal, clk):
    prev_val = signal.value
    while True:
        await RisingEdge(clk)
        current_val = signal.value
        if prev_val != current_val:
            break

    # input wire itcm_hready, // Just keep high????
    # input wire itcm_hresp, //USELESS
    # input wire [31:0] itcm_hrdata, //THIS IS THE INSTRUCTION
    # input wire itcm_ready, // Just keep low????
    # input wire dtcm_hready, // Just keep high????
    # input wire dtcm_hresp, // USELESS
    # input wire [31:0] dtcm_hrdata, // Actual info to load/store
    # input wire [3:0] cycle_cnt,

@cocotb.test()
async def test_core_basic(dut):
    """Test basic functionality of the core"""

    # 100MHz clock signal
    clock = Clock(dut.hclk, 10, units="ns")  # 10ns period (100MHz)
    cocotb.start_soon(clock.start())

    # Reset the DUT
    dut.hrstn.value = 0
    await Timer(10, units="ns")
    dut.hrstn.value = 1

    # Initialize signals
    dut.cycle_cnt.value = 0
    # Trash signals
    dut.itcm_hresp.value = 0
    dut.dtcm_hresp.value = 0

    # Don't change signals
    dut.itcm_ready.value = 0
    dut.itcm_hready.value = 1
    dut.dtcm_hready.value = 1


    dut.itcm_hrdata.value = 0b00000000000000001010000100000011
    #Load operation
    #offset: 000000000000, rs1: 00001, 010, rd: 00010, opcode:: 0000011
    dut.dtcm_hrdata.value = 0xDEADBEEF
    # update cycle_counter
    dut.cycle_cnt.value = 0
    cocotb.start_soon(cycle_counter(dut))

    # Test: Reset should initialize pc to 0
    await RisingEdge(dut.hclk)
    assert dut.ifu_pc.value == 0, "PC not reset to 0"

    # Test: Load instruction from memory
    # await Timer(40, units="ns")
    await wait_for_signal_change(dut.mau_load_data, dut.hclk)
    dut.itcm_hrdata.value = 0b00000000000000010110001000110011
    #ORI operation
    #offset: 000000000000, rs1: 00010, 110, rd: 00100, opcode:: 0110011
    # print("reg_wdata.value: {}".format(dut.mau_load_data.value))
    # await wait_for_signal_change(dut.reg_rdata_1, dut.hclk)
    print(f"regfile values: {dut.dec_or.value})")
    # await Timer(40, units="ns")
    assert dut.mau_load_data.value == 0xDEADBEEF, "Instruction output is incorrect"
    await Timer(80, units="ns")
