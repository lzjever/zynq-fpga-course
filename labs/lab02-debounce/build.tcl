# Lab 02 一键构建脚本(五步舞 + 资源账本)
# 用法: vivado -mode batch -source build.tcl
# 烧哪一版?改下面一行:bare = 裸版(先烧它看乱翻);reference = 消抖版

set variant reference            ;# ← 想做裸版对比实验,改成 bare 再跑一遍
set proj   lab02_${variant}      ;# 两版各自成工程,互不覆盖
set part   xc7z020clg400-2       ;# 板上芯片(注意 -2 速度等级)

# ① 建工程(落盘版:便于翻 .runs 里的报告,工程卫生 ch04 展开)
create_project $proj ./$proj -part $part -force

# ② 加源码与约束(按版本选顶层;两版顶层端口同名,共用 lab02.xdc)
if {$variant eq "bare"} {
    add_files bare/key_toggle_raw.v
    set_property top key_toggle_raw [current_fileset]
} else {
    add_files reference/debounce.v reference/key_toggle.v
    set_property top key_toggle [current_fileset]
}
add_files -fileset constrs_1 lab02.xdc

# ③ 综合:Verilog → 门级电路
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# ④ 实现:门级电路 → 放进 7z020 的真实资源
launch_runs impl_1 -jobs 8
wait_on_run impl_1

# ⑤ 生成比特流
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# 收尾:打开实现结果,打印时序与资源(资源账本——ch04 会回头看这条曲线)
open_run impl_1                       ;# 报告类命令都要先"打开"实现结果才能查
set wns [get_property SLACK [get_timing_paths]]
report_utilization -file ./$proj/utilization.rpt
puts "=============================="
puts " 版本   : ${variant}"
puts " 时序余量 WNS: ${wns} ns (≥0 即达标)"
puts " 比特流: [glob ./$proj/*.runs/impl_1/*.bit]"
puts " 资源(记进 README 账本): 详见 ${proj}/utilization.rpt"
puts "=============================="
