# Zynq FPGA 从零到实战 · 课程规划素材库(BRIEF)

> 本文档是课程设计的事实基础,由亲历导师整理。规划师与作者**必须以此为准**,不得虚构。

## 学员画像(重要!)
- 命令行高手(Linux 日常使用、刚亲手完成 Zynq 主线 Linux 移植——构建内核/U-Boot/Debian/JTAG 调试全部亲历)
- **FPGA/数字电路:零基础**(Verilog 看不懂,已确认)
- 学习风格:喜欢"边做边学、每步讲为什么",反感注水
- **硬性要求:把学员当小白**;所有术语/缩写**每次首次出现必须给全称+中文**(并在书末术语表汇总)

## 手上硬件:微相科技 Z7-Nano R20(XC7Z020-2CLG400)——课程必须紧扣此板实操
- PL 侧可用外设(经原理图+实测核实):
  - 50MHz 晶振 → FPGA 引脚 **N18**(LVCMOS33)
  - PL 按键(**板丝印 PL_KEY**,非 RST!)→ **P14**,按下=0
  - PL LED → **R14**(高电平点亮)
  - RST 按键 = 整芯片硬复位(会清掉 PL 配置+重启 Debian),**教学警示素材**
  - GPIO 扩展排针 GPIO1/GPIO2(bank 34/35,丝印 GPIO1_xxP/N)
  - PL ETH(需自写逻辑)、HDMI TX(需 IP/高级)
- PS 侧现状(学员自己移植的,可作为后段会师实验平台):
  - Debian 13 + 主线内核 6.18 + FPGA Manager(注意:insmod 加载比特流会触发 FIQ 风暴冻机,u-boot GIC 修复已就绪待断电验证——**Lab"PS 会师"要标注此坑的当前状态**)
  - ssh root@192.168.1.10 root/root;串口 CH340 115200
- 软件:Vivado 2026.1(Standard 免费档,Linux,`~/tools/AMD/2026.1`,已配 PATH;注意 en_US locale 坑)

## 已有教学资产(必须复用,不要重造)
1. `docs/ch00-verilog101.html` —— 已写好的"给软件工程师的电路思维速成"(三层定义/两 类句子/逐行解剖 lab01/软件vs电路对照表/三铁律),**学员已学过并完成 lab01**
2. `labs/lab01-blink/` —— led_blink.v(逐行注释版)+ lab01.xdc + build.tcl(一键五步舞)——**学员已亲手做过 GUI 全流程+重命名重构练习**
3. 学员当前进度:Lab02(debounce)需求书已布置(20ms 消抖+单周期脉冲+testbench 骨架),**学员尚未交作业**——课程里 Lab02 应保留"自己写再看参考"的教学设计
4. 导师已规划的路线(供参考,可优化):Lab02 按键消抖 → Lab03 亚稳态与打两拍 → Lab04 PWM 呼吸灯 → Lab05 UART 发送器(状态机)→ Lab06 AXI/PS-PL 会师
5. 配套《主线 Linux 手册》(另一 repo,https://lzjever.github.io/zynq-z7nano-mainline-linux/)可交叉引用,不重复其内容

## 课程硬性规范
- 中文教学,师兄带师弟口吻;每个操作讲"是什么/为什么"
- **术语规范(用户特别强调)**:任何缩写首次出现 → `中文全称(English Full Name, 缩写)`,例如:查找表(Look-Up Table, LUT)。全书术语表单独成页,按字母序
- 每课结构建议:目标(学会什么)→ 原理(带图)→ 动手(可复制命令/代码)→ 现象与验证 → 常见坑 → 小结 + 自测题
- 代码全部可运行、与板卡引脚匹配(R14/P14/N18)
- 网站纯静态零依赖(GitHub Pages 托管),样式沿用 docs/assets/style.css 的 box 体系
- Vivado 教学基于 2026.1 免费版实际界面流程(注意 Basic 档限制:ILA 1 核 5 探针、XSIM 5 万实例——够用,但要如实说明)

## 分寸建议
- 总量:入门部分(Lab00-05 + Vivado/仿真/ILA 工具课 + 板卡附录 + 术语表)约 10-14 个页面/章节
- AXI/PS-PL 会师课可以设计但标注"前置:FIQ 修复验收通过"
- 不做的高级话题(仅路线图提及):HDMI、PL ETH、DDR 接口、时序收敛进阶
