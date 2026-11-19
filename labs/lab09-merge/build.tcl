# Lab 09 会师构建(五步舞 + 资源账本 + WNS)
# 用法:vivado -mode batch -source build.tcl
# 注意:本工程的时钟来自 PS7(FCLK0),不是 N18 引脚——
#       唯一的约束在 lab09.xdc(含手写 create_clock,别忘了为什么)。

set proj  lab09
set part  xc7z020clg400-2        ;# 我们板上的芯片(-2 速度等级)

# ① 建工程
create_project $proj ./$proj -part $part -force

# ② 加入源码与约束(PS7 原语由 Vivado 库自动识别,无需额外文件)
add_files axi_led_top.v
add_files axi_lite_slave.v
add_files pwm_breather.v
add_files -fileset constrs_1 lab09.xdc
set_property top axi_led_top [current_fileset]

# ---------- 预案乙(AXI3 实测若不容忍 Lite 直挂,垫桥在此,取消注释)----------
# create_ip -name axi_interconnect -vendor xilinx.com -library ip -module_name axi_bridge
# set_property -dict [list CONFIG.PROTOCOL {AXI3} CONFIG.NUM_MI {1} \
#     CONFIG.M00_AXI_PROTOCOL {AXI4LITE}] [get_ips axi_bridge]
# generate_target all [get_ips axi_bridge]
# (再把 axi_led_top.v 里 PS7 与从机之间的同名线改接到桥两端;参数名以 2026.1 IP 手册为准)

# ③ 综合
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# ④ 实现
launch_runs impl_1 -jobs 8
wait_on_run impl_1

# ⑤ 比特流(JTAG 路用它;FPGA Manager 路要再过一道 bit2bin.py)
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# 收尾:资源账本 + 时序(这次的 WNS 是真的——因为 XDC 里手写了 create_clock)
open_run impl_1
report_utilization -file lab09_utilization.rpt
set wns [get_property SLACK [get_timing_paths]]
puts "=============================="
puts " WNS: ${wns} ns (≥0 即达标;若时序报告是灰的=约束没生效,先查 XDC!)"
puts " 资源报告: [file normalize lab09_utilization.rpt]"
puts " 比特流: [glob ./$proj/*.runs/impl_1/*.bit]"
puts "=============================="
