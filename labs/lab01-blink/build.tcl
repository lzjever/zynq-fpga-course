# Lab 01 一键构建脚本(教学版:每步都有注释)
# 用法: vivado -mode batch -source build.tcl
# 五步舞:建工程 → 加源码 → 综合 → 实现 → 生成比特流

set proj  lab01
set part  xc7z020clg400-2        ;# 我们板上的芯片(注意 -2 速度等级)

# ① 建工程(在内存中,不落盘一堆中间文件)
create_project $proj ./$proj -part $part -force

# ② 加入 Verilog 源码和约束
add_files led_blink.v
add_files -fileset constrs_1 lab01.xdc
set_property top led_blink [current_fileset]

# ③ 综合:Verilog → 门级电路
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# ④ 实现:门级电路 → 放进 7z020 的真实资源(内部分三幕:映射/布局/布线)
launch_runs impl_1 -jobs 8
wait_on_run impl_1

# ⑤ 生成比特流(.bit = 配置数据,JTAG 或 Linux fpga manager 都吃它)
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# 收个尾:打印关键结果
set wns [get_property SLACK [get_timing_paths]]
puts "=============================="
puts " 时序余量 WNS: ${wns} ns (≥0 即达标)"
puts " 比特流: [glob ./$proj/*.runs/impl_1/*.bit]"
puts "=============================="
