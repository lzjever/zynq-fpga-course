# Lab 06 仿真三步舞(xvlog → xelab → xsim)
# 用法:vivado -mode batch -source sim.tcl
# (xvlog/xelab/xsim 是独立可执行文件,不是 Vivado 的 Tcl 命令,
#  在 Tcl 里要用 exec 调 —— vivado 在 PATH 里,它们就在同目录)
# 现象:控制台最后打印 "Hello PL!" + PASS (10/10)

exec xvlog -sv uart_tx.v tb_uart_tx.v
exec xelab tb_uart_tx -s tb_sim -L work
exec xsim  tb_sim -R
