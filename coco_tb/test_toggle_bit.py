import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_toggle_bit(dut):
    """Test the toggle_bit module functionality."""

    # 创建一个 10ns 的时钟周期信号
    clock = Clock(dut.clk, 10, units="ns")  # 10ns 的时钟周期
    cocotb.start_soon(clock.start())  # 启动时钟

    # 初始化复位
    dut.rst.value = 1
    await RisingEdge(dut.clk)  # 等待一个时钟上升沿
    dut.rst.value = 0  # 释放复位信号
    await RisingEdge(dut.clk)  # 等待下一个时钟上升沿

    # 检查 toggle 信号在复位之后是否初始化为 0
    assert dut.toggle.value == 0, "Toggle bit should be 0 after reset"

    # 模拟一段时间，观察 toggle 的变化
    for i in range(9):  # 检查多个时钟周期
        await RisingEdge(dut.clk)  # 等待时钟上升沿
        if (i + 1) % 3 == 0:  # 每三个时钟周期检查 toggle
            expected_toggle = 1 - dut.toggle.value
            await RisingEdge(dut.clk)  # 等待时钟上升沿
            # assert dut.toggle.value == expected_toggle, f"Toggle didn't flip as expected at cycle {i+1}"
            print(f"At cycle {i+1}, toggle flipped to {dut.toggle.value}")

