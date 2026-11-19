# Lab 02 仿真一键脚本:三步舞跑三关判分
# 用法:在 labs/lab02-debounce/ 目录下执行
#   vivado -mode batch -source sim.tcl
# 终端滚出 [PASS 关1] [PASS 关2] ... --- PASS --- 即三关(关3 还需改参数重跑,见 tb 注释)

# ① 编译:被测电路(参考实现或你自己写的 debounce.v)+ 测试台
#    自己写版本:把 reference/debounce.v 换成你的文件路径
puts [exec xvlog reference/debounce.v tb_debounce.v 2>@1]

# ② 装配:快照名带参数提醒——关 3 要改 STABLE 重跑
puts [exec xelab -debug typical tb_debounce -s tb_debounce_sim 2>@1]

# ③ 运行:-R 跑到 $finish,判分全在终端
puts [exec xsim tb_debounce_sim -R 2>@1]
