# Lab 01 仿真一键脚本:xvlog → xelab → xsim 三步舞
# 用法:在 labs/lab01-blink/ 目录下执行
#   vivado -mode batch -source sim.tcl
# (前提:已 source Vivado 的 settings64.sh,使 xvlog/xelab/xsim 在 PATH 里。
#   不想经过 vivado 的话,把下面三步逐条直接敲 shell 也行。)

# ① 编译:xvlog 把两个 .v(被测电路 + 测试台)翻译成仿真器格式
#    (exec 的返回值要用 puts 打出来,否则工具输出被吞;2>@1 把 stderr 一并带出)
puts [exec xvlog led_blink.v tb_led_blink.v 2>@1]

# ② 装配:xelab 把测试台连成可运行的"仿真快照"
#    -debug typical = 让波形里能看到电路内部信号(如 cnt)——不加就只剩顶层端口!
puts [exec xelab -debug typical tb_led_blink -s tb_led_blink_sim 2>@1]

# ③ 运行:xsim 跑快照
#    -R   = 一路跑到 $finish 自动退出(终端打印模式,适合跑 PASS/FAIL)
#    想开波形窗口:去掉 -R,换成  puts [exec xsim tb_led_blink_sim --gui 2>@1]
puts [exec xsim tb_led_blink_sim -R 2>@1]
