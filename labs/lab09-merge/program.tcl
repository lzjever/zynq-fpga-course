# Lab 09 JTAG 烧写三连(Variant B 用;先 pkill -x openocd,防互杀)
# 用法:vivado -mode batch -source program.tcl
open_hw_manager
connect_hw_server
open_hw_target
# Zynq JTAG 链上有两个设备:arm_dap(ARM 调试口,不可编程)和 xc7z020(本尊)
# 必须按名字选 FPGA,不能盲取第 0 个!
set fpga_dev [lindex [get_hw_devices xc7z020*] 0]
if {$fpga_dev eq ""} { puts "ERROR: 未找到 xc7z020 设备"; exit 1 }
current_hw_device $fpga_dev
set_property PROGRAM.FILE [glob ./lab09/*.runs/impl_1/*.bit] [current_hw_device]
program_hw_devices [current_hw_device]
puts "=============================="
puts " JTAG 烧写完成。提醒:JTAG 装的流会顶掉 FPGA Manager 装的流(互斥,谁后到谁生效)"
puts "=============================="
close_hw_manager
