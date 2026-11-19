# Lab 08 综合体检(纯仿真章:不上板,但必须综合一遍)
# 用法:vivado -mode batch -source build.tcl
# 为什么仿真全过还要综合?——
#   ① 提前暴露"只在综合期才炸"的问题(不可综合语法/锁存器推断),
#      别让 ch09 会师当天才发现从机不能上板;
#   ② 把 AXI 块的资源占用记进账本(预计 < 200 LUT);
#   ③ 本课无 XDC、无引脚(纯仿真),所以只跑到综合 + 利用率报告;
#      时序账本(WNS)从 lab09 有了 create_clock 才开始记。

set proj  lab08
set part  xc7z020clg400-2        ;# 我们板上的芯片(注意 -2 速度等级)

# ① 建工程
create_project $proj ./$proj -part $part -force

# ② 加入源码(顶层就是从机本身)
add_files axi_lite_slave.v
set_property top axi_lite_slave [current_fileset]

# ③ 综合一次:Verilog → 门级电路
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# ④ 资源账本:AXI 块到底吃多少芯片?
open_run synth_1
report_utilization -file lab08_utilization.rpt

puts "=============================="
puts " 综合完成,无报错 = 可上板的第一道体检通过"
puts " 资源报告: [file normalize lab08_utilization.rpt]"
puts " 记账:LUT/FF = ______ / ______(抄进 README 账本)"
puts "=============================="
