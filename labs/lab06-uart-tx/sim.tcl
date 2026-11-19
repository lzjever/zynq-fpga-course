# Lab 06 仿真三步舞(xvlog → xelab → xsim)
# 用法:vivado -mode batch -source sim.tcl
# (xvlog/xelab/xsim 是独立可执行文件,不是 Vivado 的 Tcl 命令,
#  在 Tcl 里要用 exec 调 —— vivado 在 PATH 里,它们就在同目录)
# 现象:控制台最后打印 "Hello PL!" + PASS (10/10)

# (exec 的返回值要用 puts 打出来,否则工具输出被吞;2>@1 把 stderr 一并带出)
puts [exec xvlog -sv uart_tx.v tb_uart_tx.v 2>@1]
puts [exec xelab tb_uart_tx -s tb_sim -L work 2>@1]
puts [exec xsim  tb_sim -R 2>@1]
