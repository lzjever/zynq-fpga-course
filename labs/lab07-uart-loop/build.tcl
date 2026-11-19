# Lab 07 一键构建脚本 — 两种模式
# 用法:
#   vivado -mode batch -source build.tcl             ← 普通版(自环现象)
#   vivado -mode batch -source build.tcl -tclargs ila ← ILA 版(抓 RX 波形做解码练习)
# ILA 版不换顶层:build.tcl 给 loop_top 打开 ILA 宏定义并生成 ila_uart 核,
# loop_top.v 里的 `ifdef ILA 段会把 5 探针分析仪长进接收链。

if {$argc < 1} { set mode "plain" } else { set mode [lindex $argv 0] }

set proj  lab07
set part  xc7z020clg400-2

switch $mode {
    "plain" { set ila 0 }
    "ila"   { set ila 1 }
    default { puts "未知模式:$mode(可用:plain / ila)"; exit 1 }
}
puts "=============================="
puts " Lab07 模式:$mode"
puts "=============================="

create_project $proj ./$proj -part $part -force

add_files uart_tx.v uart_rx.v key_pulse.v loop_top.v
add_files -fileset constrs_1 lab07.xdc

if {$ila} {
    create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_uart
    set_property -dict [list \
        CONFIG.C_NUM_OF_PROBES {5} \
        CONFIG.C_DATA_DEPTH    {8192} \
        CONFIG.C_PROBE0_WIDTH  {1} \
        CONFIG.C_PROBE1_WIDTH  {1} \
        CONFIG.C_PROBE2_WIDTH  {1} \
        CONFIG.C_PROBE3_WIDTH  {4} \
        CONFIG.C_PROBE4_WIDTH  {2} \
    ] [get_ips ila_uart]
    generate_target all [get_ips ila_uart]
    set_property verilog_define {ILA} [current_fileset]
    puts "ILA 核 ila_uart 已生成,loop_top 的 ILA 段已启用(probe: rx/rx_done/tick/bit_cnt/state)"
    # 待实测:ila 版本号按 2026.1 写 6.2;报错就 get_ipdefs *ila* 查实号。
}

set_property top loop_top [current_fileset]

launch_runs synth_1 -jobs 8
wait_on_run synth_1
launch_runs impl_1 -jobs 8
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set wns [get_property SLACK [get_timing_paths]]
puts "=============================="
puts " 时序余量 WNS:${wns} ns(≥0 即达标)"
puts " 比特流:[glob ./$proj/*.runs/impl_1/*.bit]"
open_run impl_1
report_utilization -file util_$mode.rpt
puts " 资源报告:util_$mode.rpt(记进 README 账本)"
puts "=============================="
