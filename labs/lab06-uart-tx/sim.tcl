# Lab 06 仿真三步舞(xvlog → xelab → xsim)
# 用法:xvlog 需在 Vivado 环境下(或直接用 vivado 自带 shell);一行跑完:
#  vivado -mode batch -source sim.tcl
# 现象:控制台先滚出位宽参数,最后打印 "Hello PL!" + PASS (10/10)

xvlog uart_tx.v tb_uart_tx.v --sv
xelab tb_uart_tx -s tb_sim -L work
xsim tb_sim -R
