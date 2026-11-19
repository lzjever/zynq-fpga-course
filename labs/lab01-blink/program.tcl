# Lab 01 一键烧写脚本(ch04 教具:GUI 里点 Program Device 的全过程)
# 用法: vivado -mode batch -source program.tcl
#      (或在 Vivado Tcl Console 里敲: source program.tcl)
# 注意:如果 connect/open 卡住或报错,先确认没有 openocd 占着 JTAG:
#       pkill -f openocd   (两个 JTAG 主人会互杀,详见附录 A)

open_hw_manager
connect_hw_server              ;# 启动/连接本机 hw_server(默认 localhost:3121)
open_hw_target                 ;# 打开板上的 JTAG 链

set dev [lindex [get_hw_devices xc7z020*] 0]     ;# 链上的 7z020
set_property PROGRAM.FILE [glob ./lab01.runs/impl_1/*.bit] $dev
program_hw_devices $dev        ;# 烧!

puts "=============================="
puts " 烧写完成:PL 已按 lab01 工程的比特流配置"
puts " 断电或按 RST 会清掉配置(比特流不驻留 Flash)"
puts "=============================="
