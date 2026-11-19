# Lab 01 · LED 闪烁 — 上手教程与实验报告

> 章节:docs/ch00-verilog101.html(预备篇:读懂 led_blink.v)· docs/ch01-sim.html(仿真课)
> 硬件:Z7-Nano R20 · 50MHz=N18 · PL_KEY=P14(按下=0)· LED=R14(低电平点亮,0=亮;本电路是方波闪烁,极性无感)
> **警示:丝印 RST 的按键 = 整芯片硬复位(清 PL + 重启 Debian)。本课程用的按键是丝印 PL_KEY 的那颗。**

## 0 · 文件清单

| 文件 | 角色 |
|---|---|
| `led_blink.v` | 被测电路:24 位计数器,bit3→…bit23 分频,`cnt[23]` 接 LED(约 3Hz 心跳) |
| `tb_led_blink.v` | 测试台(ch01 的主角:造时钟/造激励/说停) |
| `lab01.xdc` | 约束:N18 时钟 50MHz / P14 按键 / R14 LED |
| `build.tcl` / `sim.tcl` / `program.tcl` | 一键构建 / 一键仿真 / 一键烧写(用法见命令卡) |
| `lab01.bin` | 4,045,520 字节的 .bin(给 ch09 FPGA Manager 装载用)。**这是有意保留的解剖标本**,不是忘了清理的垃圾:ch04 拿它开膛(凭什么一个计数器要 4MB)、ch09 靠它从 Debian 侧装载——别删,也别把它当构建产物再提交一份 |

## 1 · GUI 最小路径(三步;第一次走一遍,以后用命令卡)

1. **建工程**:开 Vivado → Create Project → 工程名 `lab01_gui` → RTL Project → Part 搜 `xc7z020clg400-2`(注意 -2 速度等级)→ Finish。
2. **加源**:Add Sources → Add or Create Design Sources → Add File → `led_blink.v`(顶层自动识别为 `led_blink`);回到 Add Sources → Add or Create Constraints → `lab01.xdc`。
3. **Generate Bitstream → 烧写**:Flow Navigator 点 **Generate Bitstream**(它自动先跑综合和实现,一键到底)→ 完成后 Open Hardware Manager → Open Target(板子上电、JTAG 线插好)→ **Program Device**,选 `lab01_gui.runs/impl_1/*.bit` → 烧。

**验收现象**:LED 以约 3Hz 心跳闪烁;按住 PL_KEY 灯亮、松开恢复闪烁(按键清零计数器,`cnt=0 → led=0`,R14 低电平点亮 → 0 恰好是亮)。
断电或按 RST 配置即失——比特流不驻留 Flash,这正是 ch04/program.tcl 要讲的事。
GUI 这三步背后就是 build.tcl 的五步舞(ch04 会拆开看每一幕)。

## 2 · 命令卡(第一次学在章节里,以后查在卡片里)

```bash
cd labs/lab01-blink

# 构建(五步舞一键:建工程→加源→综合→实现→比特流;产物在 lab01.runs/impl_1/*.bit)
vivado -mode batch -source build.tcl

# 烧写(JTAG;若在跑 OpenOCD 先 pkill -x openocd——两个 JTAG 主人会互杀,详见附A)
vivado -mode batch -source program.tcl

# 仿真三步舞:xvlog → xelab → xsim(ch01 详解;终端直接打 PASS 判词)
vivado -mode batch -source sim.tcl
```

## 3 · 资源账本(每次 build 后记一行,ch04 回头看曲线)

| Lab | 顶层 | LUT | FF | WNS(ns) | 来源 |
|---|---|---|---|---|---|
| lab01 | led_blink | 2 | 24 | 18.025 | 实测 Vivado 2026.1(build.tcl 收尾打印 + utilization.rpt) |
| lab02 裸版 | key_toggle_raw | | | | |
| lab02 消抖版 | key_toggle | | | | |
| lab03 | tear_demo | | | | |
| lab05 | pwm_breathe | | | | |
| lab06 | lab06_top | | | | |
| lab07 | loop_top | | | | |
| lab08 | axi_lite_slave | | | | |
| lab09 | axi_led_top | | | | |
| lab10 | axi_capstone_top | | | | |

## 4 · 交作业清单

- [ ] 板上验收:约 3Hz 心跳 + 按住 PL_KEY 灯亮(两个现象都拍到/记下)
- [ ] ch00 的三个改数实验(cnt[22] / cnt[0] / 4 位计数器):每个先写预测,再烧板验证
- [ ] (ch01 后)sim.tcl 跑通,终端出现波形输出(观察台,无判分;PASS 判分从 lab02 开始)
- [ ] 资源账本 lab01 行与你自己 build 打印的 WNS/LUT/FF 对得上
