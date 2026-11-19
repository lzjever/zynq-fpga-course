# Lab 09 JTAG 烧写三连(Variant B 用;先 pkill -x openocd,防互杀)
# 用法:vivado -mode batch -source program.tcl
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE [glob ./lab09.runs/impl_1/*.bit] [current_hw_device]
program_hw_devices [current_hw_device]
puts "=============================="
puts " JTAG 烧写完成。提醒:JTAG 装的流会顶掉 FPGA Manager 装的流(互斥,谁后到谁生效)"
puts "=============================="
