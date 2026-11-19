# Lab 06 一键构建脚本 — 三种模式,一份代码
# 用法:
#   vivado -mode batch -source build.tcl -tclargs eye    ← 肉眼 UART(2 波特,LED 5 秒打 'H')默认
#   vivado -mode batch -source build.tcl -tclargs real   ← 真实波特率 115200(板上现象:几乎无感)
#   vivado -mode batch -source build.tcl -tclargs ila    ← 115200 + ILA 核(5 探针,抓帧主验证)
# 三种模式改的都是同一份 uart_tx.v —— parameter 三级跳,零代码改动。

if {$argc < 1} { set mode "eye" } else { set mode [lindex $argv 0] }

set proj  lab06
set part  xc7z020clg400-2

# ---------- 模式 → 参数映射 ----------
switch $mode {
    "eye"  { set top lab06_top;       set div 25000000; set ila 0 }  ;# 2 波特
    "real" { set top lab06_top;       set div 434;      set ila 0 }  ;# 115200
    "ila"  { set top lab06_ila_top;   set div 434;      set ila 1 }  ;# 115200+ILA
    default { puts "未知模式:$mode(可用:eye / real / ila)"; exit 1 }
}
puts "=============================="
puts " Lab06 模式:$mode  顶层:$top  BAUD_DIV=$div"
puts "=============================="

create_project $proj ./$proj -part $part -force

add_files uart_tx.v key_pulse.v lab06_top.v lab06_ila_top.v
add_files -fileset constrs_1 lab06.xdc

# ---------- ILA 模式:显式例化路线,create_ip 全脚本化(不点 GUI)----------
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
    puts "ILA 核 ila_uart 已生成(1 核 5 探针,深度 8192)"
    # 注:ila 版本号 6.2 按 2026.1 写;若报"找不到 IP 定义",
    # 先跑 `get_ipdefs *ila*` 看实际版本号再改这一行(待实测项)。
}

# parameter 覆盖就在这一行:顶层 generic 重定义,源文件一字不动
set_property generic "BAUD_DIV=$div" [current_fileset]
set_property top $top [current_fileset]

launch_runs synth_1 -jobs 8
wait_on_run synth_1
launch_runs impl_1 -jobs 8
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# 收尾:时序 + 资源账本(每一课记一行,看电路长大)
set wns [get_property SLACK [get_timing_paths]]
puts "=============================="
puts " 时序余量 WNS:${wns} ns(≥0 即达标)"
puts " 比特流:[glob ./$proj/*.runs/impl_1/*.bit]"
open_run impl_1
report_utilization -file util_$mode.rpt
puts " 资源报告:util_$mode.rpt(记进 README 账本)"
puts "=============================="
