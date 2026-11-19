# Lab 07 仿真三步舞(xvlog → xelab → xsim)
# 用法:vivado -mode batch -source sim.tcl
# (xvlog/xelab/xsim 是独立可执行文件,Tcl 里用 exec 调)
# 现象:两场考试 —— 自环 10/10 + 浸泡 256/256,结尾 PASS

# (exec 的返回值要用 puts 打出来,否则工具输出被吞;2>@1 把 stderr 一并带出)
puts [exec xvlog -sv uart_tx.v uart_rx.v key_pulse.v loop_top.v tb_uart_loop.v 2>@1]
puts [exec xelab tb_uart_loop -s tb_sim -L work 2>@1]
puts [exec xsim  tb_sim -R 2>@1]
