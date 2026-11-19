# ============================================================
# Lab 09 约束 — 会师版
# ============================================================
# 注意:N18(50MHz 晶振)在本设计退役 —— 时钟改由 PS 侧 FCLK0 供给
# (方案甲:单时钟域,斩断 CDC 雷;演变史见课程页 ch09)。

# ---------- PL LED:R14(本设计唯一物理引脚) ----------
set_property PACKAGE_PIN R14 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]

# ---------- ★ 手写时钟约束:本课最重要的一行 ----------
# 直例化 PS7 没有 Block Design 替你生成约束,FCLK0 网络上没有任何
# create_clock,Vivado 就不会做时序分析——时序报告"全绿"是假象!
# (周期 20ns = 50MHz,与 SLCR 里配的 FCLK0 频率一致;改频率记得同步改这里)
# 花括号必写:Tcl 会把裸写的 FCLKCLK[0] 当下标展开报错,{} 原样传给 get_pins
create_clock -period 20.000 -name fclk0 [get_pins {PS7_i/FCLKCLK[0]}]
