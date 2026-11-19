# Lab 08 · AXI-Lite 从机:TB 假扮 ARM(纯仿真,无 xdc)

> 课程页:docs/ch08-axi.html(先读再做)

## 目的

- 读懂一个最小 AXI4-Lite 从机:一个 32 位寄存器,**写 = 存值,读 = 回值**
- 学会用 testbench 任务(task)封装 `axi_write` / `axi_read` —— 这就是"假 ARM"
- 亲眼在波形里看到 valid/ready 握手逐拍成交
- 综合体检:确认从机可综合、记录资源账本(为 ch09 上板扫清障碍)

## 现象(先知道会看到什么)

- 终端逐行打印 `[ OK ]`,最后一行 `--- PASS (12/12) ---`
- 波形里:每笔写 = AW/W 两个通道各自握手 → B 通道回执;每笔读 = AR 握手 → R 带数据回来
- `knob` 信号随每次写入立刻变化(0x55 → 0x40 → 0xFF → 0x00)

## 文件清单

| 文件 | 角色 |
|---|---|
| `axi_lite_slave.v` | 被测电路(DUT):最小 AXI4-Lite 从机,逐行注释 |
| `tb_axi_slave.v` | 假 ARM:axi_write/axi_read 任务 + 记分牌 + PASS/FAIL |
| `sim.tcl` | 仿真三步舞(xvlog → xelab → xsim) |
| `build.tcl` | 综合体检 + 资源账本(本课无 xdc、无 program.tcl——不上板) |

## 命令卡(第一次学在章节里,以后查在卡片里)

```bash
cd labs/lab08-axi

# 仿真三步舞(或一条:vivado -mode batch -source sim.tcl)
xvlog axi_lite_slave.v tb_axi_slave.v
xelab -debug typical tb_axi_slave -s tb_sim
xsim tb_sim -R

# 想开波形 GUI 就去掉 -R(先 pkill -x openocd / hw_server,防 JTAG 互杀)
# 综合体检
vivado -mode batch -source build.tcl
```

## 步骤

1. 先跑仿真,确认 PASS(12/12)
2. 打开波形(tb_sim.wdb 或 tb_axi_slave.vcd),找到第一笔写 0x55:
   数出 AW 成交拍、W 成交拍、`knob` 变 0x55 的拍、B 回执成交拍——**这四拍的先后顺序就是 AXI 写的全部**
3. 跑 build.tcl,抄资源账本,和预测(约百级 LUT)对个数量级

## 资源账本(继承自 Lab01,每课记一行)

| Lab | LUT | FF | 备注 |
|---|---|---|---|
| lab01 blink | | | ch04 记过 |
| **lab08 AXI 从机** | | | 综合后填入 |

## 思考题(答案在课程页自测)

1. 把 TB 的 `s_axi_bready` 初始值改成 1(一直准备收),现象会变快还是变慢?
2. 从机为什么必须在 AW/W 成交拍把 addr/data **锁存**进 awbuf/wbuf,而不能等 write_fire 再直接用 `s_axi_wdata`?
3. 本从机只有一个寄存器,地址不译码——如果读 0x4 会读到什么?(lab09 的两寄存器版用 case 译码修正)

## 与下一课的接口

`knob` 这个端口就是旋钮的手柄。ch09 把它接到 PWM 上,再用真 ARM(Debian 里的 devmem)来拨。
