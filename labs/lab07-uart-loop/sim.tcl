# Lab 07 仿真三步舞(xvlog → xelab → xsim)
# 用法:vivado -mode batch -source sim.tcl
# 现象:两场考试 —— 自环 10/10 + 浸泡 256/256,结尾 PASS

xvlog uart_tx.v uart_rx.v key_pulse.v loop_top.v tb_uart_loop.v --sv
xelab tb_uart_loop -s tb_sim -L work
xsim tb_sim -R
