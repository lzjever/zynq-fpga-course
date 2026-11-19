# ============================================================
# Lab 01 约束文件 — 告诉 Vivado"电路的端口接在芯片哪个脚上"
# ============================================================
# 三要素:引脚号(PACKAGE_PIN)、电气标准(IOSTANDARD)、时钟周期(create_clock)

# ---------- 时钟:N18,50MHz(周期 20ns) ----------
create_clock -period 20.000 -name sys_clk [get_ports clk]
set_property PACKAGE_PIN N18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# ---------- PL 按键:P14 ----------
set_property PACKAGE_PIN P14 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# ---------- PL LED:R14 ----------
set_property PACKAGE_PIN R14 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]
