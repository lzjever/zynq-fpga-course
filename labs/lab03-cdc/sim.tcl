# sim.tcl — Lab03 撕裂仿真(XSIM 批处理)
# 用法(三步舞的最后一步,前两步见 README):
#   xsim tear_tb_sim -tclbatch sim.tcl
# 想开波形窗口看截图点,把 -tclbatch 换成 -gui。

run 60us        ;# TB 在 40us 后自己会收卷打印并 $finish
quit
