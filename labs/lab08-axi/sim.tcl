# Lab 08 仿真三步舞:xvlog(编译)→ xelab(装配)→ xsim(跑)
# 用法:vivado -mode batch -source sim.tcl
# 等价命令行(直接在 shell 里敲也行,见 README 命令卡):
#   xvlog axi_lite_slave.v tb_axi_slave.v
#   xelab -debug typical tb_axi_slave -s tb_sim
#   xsim tb_sim -R
# -R = 跑完自动退出;-debug typical 让波形数据库可看(想开 GUI 就去掉 -R)

exec xvlog axi_lite_slave.v tb_axi_slave.v
exec xelab -debug typical tb_axi_slave -s tb_sim
exec xsim tb_sim -R
