# ============================================================
# Lab 06 约束 — UART 发送器(肉眼版 / 真实版 / ILA 版共用)
# ============================================================
# 本课没有新外设:还是那三根老线 —— 时钟、按键、LED。
# 变化在于角色:P14 从"复位"改行当"发射按钮",R14 从"接计数器位"
# 改接 tx 串口线(LED 复用成串口观测窗,这是肉眼 UART 的全部秘密)。
# (ILA 版的探针是片内信号,不占引脚,xdc 一行都不用加)

# ---------- 时钟:N18,50MHz(周期 20ns) ----------
create_clock -period 20.000 -name sys_clk [get_ports clk]
set_property PACKAGE_PIN N18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# ---------- PL 按键:P14(按下 = 0)= "发射按钮" ----------
set_property PACKAGE_PIN P14 [get_ports key]
set_property IOSTANDARD LVCMOS33 [get_ports key]

# ---------- PL LED:R14(高电平点亮)= tx 串口线 ----------
# 注意:tx 空闲态为 1,所以 LED 平时常亮 —— 协议规定,不是坏了
set_property PACKAGE_PIN R14 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]
