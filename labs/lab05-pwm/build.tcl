# Lab 05 一键构建脚本(五步舞 + 资源账本收尾)
# 用法: cd labs/lab05-pwm && vivado -mode batch -source build.tcl

set proj  lab05
set part  xc7z020clg400-2        ;# 我们板上的芯片(注意 -2 速度等级)

# ① 建工程(在 ./lab05/ 下落盘一堆中间文件)
create_project $proj ./$proj -part $part -force

# ② 加入源码(两个模块!tick_gen 是被例化的零件)和约束
add_files tick_gen.v
add_files pwm_breathe.v
add_files -fileset constrs_1 lab05.xdc
set_property top pwm_breathe [current_fileset]   ;# 顶层只有一个

# ③ 综合:Verilog → 门级电路
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# ④ 实现:门级电路 → 放进 7z020 的真实资源(LUT/FF/布线)
launch_runs impl_1 -jobs 8
wait_on_run impl_1

# ⑤ 生成比特流(.bit = 配置数据,JTAG 或 Linux fpga manager 都吃它)
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# 收账:时序余量 + 资源账本(ch04 起,每个 Lab 记一行)
open_run impl_1
set wns [get_property SLACK [get_timing_paths]]
report_utilization -file ./lab05_utilization.rpt
puts "=============================="
puts " 时序余量 WNS: ${wns} ns (≥0 即达标)"
puts " 资源账本: 打开 ./lab05_utilization.rpt,"
puts "           把 Slice LUTs / Registers 两格抄进 README 的账本表"
puts " 比特流: [glob ./$proj/*.runs/impl_1/*.bit]"
puts "=============================="
