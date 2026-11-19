# ============================================================
# Lab 07 约束 — 自环回:第一次用 GPIO 排针
# ============================================================
# 老三样(N18/P14/R14)+ 新两样:TX/RX 上 GPIO1 排针。
# 引脚取自厂商 LCD 例程的 top_pin.xdc(附录 A 有全表):
#   TX → U12(GPIO1 控制位第 1 脚,LVCMOS33)
#   RX → W16(GPIO1 数据位第 1 脚,LVCMOS33)
# 选脚已避开三处禁区(接线前对照附录 A 排针表):
#   ① JP1/JP2 的 11/12(VCC_5V)、29/30(VCC_3V3)——排针没有 GND 脚,电源脚插错=短路
#   ② JP1 的 39/40(=P14/R14,GPIO1_17P/N)——板载按键/LED 与排针共享引脚,插上=对顶
#   ③ 其余任意信号脚任选,U12/W16 为既定方案
# 物理位置:都在 GPIO1 排针(丝印 GPIO1_xxP/N)上,相邻与否以板上丝印为准,
# 反正杜邦线够长 —— 附录 A 有排针图,找不到先去对表。

# ---------- 时钟:N18,50MHz ----------
create_clock -period 20.000 -name sys_clk [get_ports clk]
set_property PACKAGE_PIN N18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# ---------- PL 按键:P14 = 发射按钮 ----------
set_property PACKAGE_PIN P14 [get_ports key]
set_property IOSTANDARD LVCMOS33 [get_ports key]

# ---------- PL LED:R14 = 收到一字节翻转一次 ----------
set_property PACKAGE_PIN R14 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]

# ---------- 串口 TX:排针 U12(杜邦线一头) ----------
set_property PACKAGE_PIN U12 [get_ports tx_pad]
set_property IOSTANDARD LVCMOS33 [get_ports tx_pad]

# ---------- 串口 RX:排针 W16(杜邦线另一头) ----------
set_property PACKAGE_PIN W16 [get_ports rx_pad]
set_property IOSTANDARD LVCMOS33 [get_ports rx_pad]
set_property PULLUP   true [get_ports rx_pad]
# ↑ 关键小机关:内部上拉。拔掉杜邦线后 rx 读到恒 1(= 空闲),
#   而不是悬空乱读 —— "拔线 = 静默"才是一个干净的实验结论。
