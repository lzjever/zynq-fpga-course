# ============================================================
# Lab 05 约束 —— 和 lab01 同款三外设,一行不多
# ============================================================

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
