# ============================================================
# Lab 02 约束 — 与 lab01 的差别只有一处:P14 改名叫 key
# ============================================================
# lab01 里 P14 当"复位"(rst_n);今天它转正为主角——被消抖的按键信号。
# 裸版与消抖版顶层端口同名(clk/key/led),共用这一份约束。

# ---------- 时钟:N18,50MHz(周期 20ns)----------
create_clock -period 20.000 -name sys_clk [get_ports clk]
set_property PACKAGE_PIN N18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# ---------- PL 按键:P14(丝印 PL_KEY,按下 = 0;别碰丝印 RST 的那颗!)----------
set_property PACKAGE_PIN P14 [get_ports key]
set_property IOSTANDARD LVCMOS33 [get_ports key]

# ---------- PL LED:R14(高电平点亮)----------
set_property PACKAGE_PIN R14 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]
