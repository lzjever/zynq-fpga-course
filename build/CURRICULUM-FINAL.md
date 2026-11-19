# 课程大纲 · 终审定稿(ADJUDICATED)

> 双规划师独立提案 + 双向交叉质询 + 导师终审(2026-11-20)。写作团队**以此文件为唯一依据**。
> 事实基础仍是 build/CURRICULUM-BRIEF.md;两份原案与质询书(plan-edu/plan-hw/critique-edu/critique-hw)保留供查。

## 终审裁定记录(导师)
1. **工具课溶解成立**(教学派胜),采纳实操派四硬条件:附录 C 命令速查卡、每章 README 命令卡、ch04 吸收 program.tcl 与 GUI↔Tcl 等价演示、资源账本自 Lab01 起生效
2. **XSM 独立章砍除**,并入 ch01(置于 Lab02 前,先跑别人的 TB 再自己写)
3. **Vivado/Tcl 并入 ch04,位置=Lab03 之后**(教学派三条理由成立;实操派吸收项全部保留)
4. **ILA 锚定 UART 章**(实操派胜),加教学派交换条件:游标量位宽练习 + tick 触发抓消抖 + 钩子接 ch08
5. **UART 拆两章**:ch06 TX(教学式,含肉眼 UART)/ ch07 RX 自环(先写后看,第二次 FSM 近迁移)
6. **三个技术炸弹采纳教学派修正**:ILA 兜底=升波特率(921600→542 点)或窗口触发,禁写"降 9600";撕裂仿真必须显式注入各位延迟;force 1'bx 改写成"仿真器的盲区"
7. **裸版对比保留**(实操派),归因写两笔(抖动主因+异步次因,ch03 翻案);clk_wiz 移出 ch03 主线;EMIO 砍;BD 降级为 box;L0/L1 并入 ch09
8. **GP0=AXI3(UG585 事实)**:ch08 开写前必须实测"Lite 从机直挂是否容忍 AXI3 单拍传输";不 tolerated 则 create_ip 垫 AXI Interconnect(脚本化,不进 BD)。写作时按两案备好,实测后二选一
9. **ch09 时钟域方案甲**:设计整体活在 FCLK0 域,N18 退役;SLCR 0xF8000170 使能 FCLK 即会师仪式;**必须手写 create_clock**(直例化无 BD 自动约束,时序全绿是假象)
10. **JTAG 互杀警示**(hw_server vs OpenOCD)进附录 A 安全表与 ch06(ch06 当天必撞)
11. 版本术语统一:"免费档(安装界面名 Vivado ML Standard,授权页称 Basic)"首次出现注明,全书用"免费档"
12. ILA 深度/复插核/AXI3 三项标"待实测"(板子恢复后首日补测),写作先按主流值并留注记

## 定稿章节表(14 页:首页+11 章+附录 ABC)

| # | 文件名 | 标题 | 核心内容 | Lab/交付 | 新术语 |
|---|---|---|---|---|---|
| 首页 | index.html | 课程地图与使用指南 | 里程碑四枚、学习曲线、怎么用本课、先修说明(主线 Linux 手册)、进度勾选表 | — | 汇总链接 |
| ch00 | ch00-verilog101.html | Verilog 101(已有,微调) | 已存在;补"课程内位置"导语 | — | 已含 |
| ch01 | ch01-sim.html | 仿真入门:在波形里看见时间 | testbench 是什么/不可综合方言;先跑 lab01 的 TB;XSIM 流程;"半亮"悬案收案;波形阅读法 | labs/lab01-blink 加 tb_led_blink.v + sim.tcl | testbench/XSIM/波形/时间步 |
| ch02 | ch02-debounce.html | Lab02 按键消抖:先写后看 | 需求书(20ms/单周期脉冲);裸版对比实验先行(20 行,按一次乱翻);三关检查点+三级提示(45 分钟规则);参考实现逐行讲 | labs/lab02-debounce/(bare/、reference/、tb/、README) | 消抖/毛刺/同步器(预告) |
| ch03 | ch03-cdc.html | 亚稳态:时间的灾难 | 钩子=ch02 翻案;撕裂仿真(显式注入延迟版);Gray 码对照;"仿真器的盲区"(force X 反例);打两拍;MTBF 概念计算 | labs/lab03-cdc/(sim 为主,板上跑正确链) | 亚稳态/MTBF/CDC/Gray 码 |
| ch04 | ch04-vivado.html | Vivado 幕后与一键化(呼吸谷) | 比特流解剖(bit2bin.py);Tcl 五步全解;GUI=Tcl 等价演示;program.tcl;工程卫生(gitignore/资源账本曲线) | labs/lab01-blink 加 program.tcl + .gitignore 模板 | Tcl/网表/布局布线/WNS |
| ch05 | ch05-pwm.html | PWM 呼吸灯与模块例化 | DRY 动机(第三次写 tick);例化语法;parameter;PWM 原理;8bit 亮度 | labs/lab05-pwm/ | PWM/占空比/例化/parameter |
| ch06 | ch06-uart-tx.html | UART 发送器:时间是编码 | 肉眼 UART(BAUD_DIV=25_000_000,LED 5 秒打 'H')为主现象;帧格式;FSM;ILA 主验证+游标量位宽;第三句摊牌 CH340 在 PS 侧 | labs/lab06-uart-tx/(含肉眼参数版本+ILA 抓波形指引) | UART/波特率/FSM/起始位 |
| ch07 | ch07-uart-rx.html | UART 接收器:自环回(先写后看) | 第二次 FSM(近迁移);杜邦线自环(共地提醒);中点采样;先写后看机制复用;ILA 解码 0x48 | labs/lab07-uart-loop/ | 采样/过采样 |
| ch08 | ch08-axi.html | AXI 总线:和 ARM 说同一种话(纯仿真) | AXI-Lite 通道/握手;TB 假扮 ARM 写寄存器;PS7 直例化预告;AXI3 沟(两案+实测门) | labs/lab08-axi/(slave.v+tb 仿 true) | AXI/地址映射/GP0 |
| ch09 | ch09-merge.html | 会师:Debian 装载你的电路 | FIQ 战地日记(简);FCLK0 域方案甲;手写 create_clock;主路=fpga_mgr 装载;Variant B=JTAG+devmem(命令卡);L0/L1 两级 | labs/lab09-merge/ | FPGA Manager/FCLK/devmem |
| ch10 | ch10-capstone.html | 毕业设计:呼吸灯亮度远控 | 三合一(PWM+AXI+装载):写寄存器改呼吸速度;进阶路线图(HDMI/PL ETH/时序收敛去哪学) | labs/lab10-capstone/ | — |
| 附A | appendix-board.html | 板卡手册 Z7-Nano | 引脚全表(LED/KEY/时钟/GPIO1/GPIO2 29+29 脚,hw 已从厂商 XDC 提取);供电;RST 警示专页;JTAG 互杀;温度读法(XADC) | — | — |
| 附B | appendix-glossary.html | 术语表(全书汇总) | 按字母序;每条=中文全称(English Full Name, 缩写)+一句话解释+首现章节链接;依赖全部章节完成后汇总 | — | — |
| 附C | appendix-cheatsheet.html | 命令速查卡 | Tcl 五步/常用 Vivado 命令/openocd/ssh/串口——"第一次学在章节里,以后查在卡片里" | — | — |

## 写作分工(第一波 4 人并行,第二波 1 人收尾)
- W1:index、ch01、ch02 + lab01 的 TB/sim.tcl + lab02 全套
- W2:ch03、ch04、ch05 + lab03/lab05 工程
- W3:ch06、ch07 + lab06/lab07 工程(肉眼 UART 参数版必须可跑)
- W4:ch08、ch09、ch10 + lab08/lab09/lab10 工程
- W5(第二波):附录 A(hw 的 GPIO 表在 critique-hw.md)+ 附录 C;附录 B 最后(汇总各章术语首现)

## 写作规范(继承 BRIEF 并强调)
- 术语首现:中文全称(English Full Name, 缩写);B 表最终汇总
- 每章:目标→钩子→原理(图)→动手(可复制)→现象与验证→常见坑→小结+三档自测
- 页面骨架沿用 build/page-template.html(本仓库版,导航为本表)
- 站内互相引用用相对链接;姊妹手册引用 https://lzjever.github.io/zynq-z7nano-mainline-linux/
- 代码与板上引脚一致(R14/P14/N18;lab09 后 N18 退役的设计要写明演变)
- "待实测"清单统一标注:ILA 深度/ILA 复插/AXI3 直挂
