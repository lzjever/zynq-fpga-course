# Lab 02 JTAG 烧写三连:连接 → 探测 → 下载(约 15 行)
# 用法: vivado -mode batch -source program.tcl
# 前提:① 只插 JTAG 那个 type-C(串口那个是 CH340,不认 JTAG);
#       ② 如果你在跑 OpenOCD,先 pkill -f openocd——两者抢同一个 JTAG 口(附录 A)

open_hw_manager                       ;# 打开硬件管理器
connect_hw_server                     ;# 连本机 hw_server
open_hw_target                        ;# 探测 JTAG 链上的芯片

# 设备名以探测结果为准(单板单芯片一般是 xc7z020_1);
# 比特流路径:可用  vivado -mode batch -source program.tcl -tclargs 路径.bit
# 指定;不指定就按"先消抖版后裸版"的顺序自动找
set bitfile ""
if {[info exists argv]} {
    set bitfile [lindex $argv 0]
}
if {$bitfile eq ""} {
    set bitfile [glob -nocomplain ./lab02_reference.runs/impl_1/*.bit]
}
if {[llength $bitfile] == 0} {
    set bitfile [glob ./lab02_bare.runs/impl_1/*.bit]
}

set device [get_hw_devices xc7z020*]
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device           ;# 下载!下载后电路立即上电运行

puts "烧写完成: $bitfile"
puts "(板上 RST 键是整芯片复位——按一下电路全没,别按!)"
