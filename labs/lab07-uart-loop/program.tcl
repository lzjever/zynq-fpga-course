# Lab 07 JTAG 烧写三连(连接 → 识别 → 烧写)
# 用法:vivado -mode batch -source program.tcl
# 注意:开 Hardware Manager 前先杀掉可能占着 JTAG 的 OpenOCD:
#   pkill -f openocd
# (hw_server 和 OpenOCD 抢同一个 FT232H,谁后启动谁连不上 —— 互杀口诀见附录 C)

set progbit [glob ./lab07/*.runs/impl_1/*.bit]

open_hw_manager
connect_hw_server
open_hw_target

set device [lindex [get_hw_devices] 0]
current_hw_device $device
set_property PROGRAM.FILE $progbit $device
program_hw_devices $device

puts "=============================="
puts " 烧写完成:$progbit"
puts " (ila 模式烧完后:Open Hardware Manager → Add ILA 核即可抓波形)"
puts "=============================="
close_hw_manager
