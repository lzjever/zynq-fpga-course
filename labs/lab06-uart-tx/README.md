# Lab06 · UART 发送器(肉眼 UART + ILA 抓帧)

> 课程页:docs/ch06-uart-tx.html(原理、帧格式图、状态机逐弧讲解都在那里)
> 本章一句话:**时间就是编码** —— 把 'H' 用 0 和 1 在时间轴上铺出来,听的人按同一个时间约定还原它。

## 文件清单

| 文件 | 作用 |
|---|---|
| `uart_tx.v` | 发送器本体:三态 FSM(IDLE/SEND/STOP)+ `BAUD_DIV` 参数 |
| `key_pulse.v` | 按键消抖出单周期脉冲(= Lab02/03 知识复用:两拍同步 + 稳定计数 + 边沿检测) |
| `lab06_top.v` | 肉眼版/真实版共用顶层:tx 直接接 R14,LED 当串口观测窗 |
| `lab06_ila_top.v` | ILA 版顶层:同一发送器 + 5 探针逻辑分析仪核 |
| `tb_uart_tx.v` | 测试台:软件接收器模型,中点采样收帧,打印 "Hello PL!" + PASS/FAIL |
| `lab06.xdc` | 约束(还是 N18/P14/R14 三根线,没有新外设) |
| `build.tcl` / `sim.tcl` / `program.tcl` | 一键构建(三模式)/ 仿真 / 烧写 |

## 命令卡(第一次学在章节里,以后查在这)

```bash
# 仿真(先跑,~秒级,应看到 "Hello PL!" 与 PASS (10/10))
vivado -mode batch -source sim.tcl

# 肉眼 UART:2 波特,LED 5 秒打出 'H' 帧 —— 先烧这个!
vivado -mode batch -source build.tcl -tclargs eye
vivado -mode batch -source program.tcl     # 烧写前 pkill -x openocd

# 三级跳(同一份代码,零改动):
vivado -mode batch -source build.tcl -tclargs eye    # 2 波特,逐位可读
vivado -mode batch -source build.tcl -tclargs slow   # 9600,按一次 LED 短促一闪
vivado -mode batch -source build.tcl -tclargs real   # 115200,LED 几乎无感
vivado -mode batch -source build.tcl -tclargs ila    # 115200 + ILA 抓帧主验证
```

## 现象对照表(做之前先读,做完对号)

| 模式 | BAUD_DIV | 一个位 | 一帧耗时 | 按一次键 LED 的现象 |
|---|---|---|---|---|
| eye | 25_000_000 | 0.5 s | 5 s | 灭 2 s(起始+d0~d2)→ 亮 0.5 → 灭 1 s(d4+d5)→ 亮 0.5 → 灭 0.5 → 亮起后**常亮**(停止位+空闲) |
| slow | 5_208 | 104 µs | 1.04 ms | 短促一闪——肉眼能看到"有事发生",但读不出任何一位 |
| real | 434 | 8.68 µs | 86.8 µs | 几乎无感(太快,肉眼失效 → 需要 ILA) |
| ila | 434 | 8.68 µs | 86.8 µs | 同上;波形窗里逐位解出 0100_1000 = 'H' |

eye 模式逐位时间线('H' = 0x48 = 8'b01001000,LSB 先行;LED 高=亮):

```
位序(时间→)  起始  d0  d1  d2  d3  d4  d5  d6  d7  停止
逻辑值         0    0   0   0   1   0   0   1   0   1
LED            灭   灭  灭  灭  亮  灭  灭  亮  灭  亮→常亮
持续           0.5s ×10 位 = 5 s
```

## ILA 抓帧步骤(ch06 §6 的页内版,5 步)

1. `pkill -x openocd`(JTAG 互杀口诀,ILA 当天必撞的坑)
2. `vivado -mode batch -source build.tcl -tclargs ila && vivado -mode batch -source program.tcl`
3. 打开 Vivado GUI → Hardware Manager → Open Target(自动)→ 应看到 `ila_uart(x_xx)` 出现在设备树下
4. 触发条件设 **tx(probe0)== 0**(tx 空闲恒 1,拉低 = 起始位开始),Run Trigger Arm
5. 按一下 PL_KEY → 波形冻结 → 放大 tx 线,游标量出一个位的宽度
   **游标量位宽练习**:两游标卡相邻两次电平变化,读数应 ≈ 8680ns(= 434 × 20ns),误差 ≤ 1 个时钟

## 资源账本(每课一行,看电路长大)

| Lab | LUT | FF | 备注 |
|---|---|---|---|
| lab01 blink | ~10 | 24 | 基线 |
| lab06 eye/real | 待填 | 待填 | FSM 3 状态 + 25 位波特计数器 |
| lab06 ila | 待填 | 待填 | ILA 核另吃约百级 LUT/FF —— 账本要含它 |

## 思考题(页内自测的实物版)

1. eye 模式下按住键 3 秒再松开,为什么恰好只发一帧?(key_pulse 的边沿检测)
2. real 模式下连按两下(间隔 >1s),第二帧为什么照样完整?(start 在 SEND 期间被忽略 = 丢帧保护)
3. 把 CHAR 改成 8'h55(0b01010101),eye 模式的亮灭节奏变成什么样?先推再烧。

## 已知坑(详见课程页"常见坑"节)

- LED 平常常亮 = tx 空闲电平,**不是坏了**
- ILA 触发没反应:八成是触发电平写成 1(空闲就是 1,永远立刻触发/永不触发,取决于模式)—— 要用 **tx == 0**
- Hardware Manager 认不到板:插的是 JTAG 那个 type-C,不是串口那个;并确认 openocd 已杀
- 按到板上 RST 键 = 整芯片硬复位:PL 配置被清,LED 灭,ILA 断连 —— 现象消失先想它
