# Lab 09 · PS-PL 会师:Debian 装载你的电路

> 课程页:docs/ch09-merge.html(先读再做)

```
┌─────────────────────────────────────────────────────────────┐
│  ⚠ 前置验收门:FIQ 修复                                       │
│  用 lab01 的 blink.bin 先过三绿,再装本设计:                    │
│    ① insmod / echo 装载后 LED 亮                              │
│    ② ssh 仍活着(系统没冻)                                    │
│    ③ /sys/class/fpga_manager/fpga0/state = operating         │
│  当前状态(2026-11-20):u-boot GIC 修复已就绪,待断电验证。      │
│  未过门 → 走 Variant B(JTAG),课程照常毕业。                   │
└─────────────────────────────────────────────────────────────┘
```

## 目的

- 把 lab08 的从机接上真 ARM:PS7 直例化(不进 Block Design)
- 走完"软件写一个数 → 电路变"的最后一公里(devmem → GP0 → 你的寄存器 → LED)
- 理解三件事:FCLK0 是这个设计的电源(方案甲)、create_clock 必须手写、地址是怎么算出来的

## 设计一览

```
        FCLK0(50MHz,由 SLCR 0xF8000170 使能)
          │
 PS7 ─────┤ GP0(AXI3,方案甲直挂)
          ▼
   axi_lite_slave ── 0x00 CTRL(bit0=LED 手动值)
   │                └─ 0x04 SPEED(呼吸分频,0=手动挡)
   ▼
 pwm_breather ──▶ R14
```

| 文件 | 角色 |
|---|---|
| `axi_led_top.v` | 顶层:PS7 直例化 + 从机 + 呼吸灯(L0/L1 挡位切换) |
| `axi_lite_slave.v` | lab08 从机的两寄存器版(DIFF 已标) |
| `pwm_breather.v` | ch05 呼吸灯 + SPEED 输入 |
| `lab09.xdc` | R14 + ★手写 create_clock |
| `build.tcl` | 五步舞 + 资源账本(预案乙垫桥开关在注释里) |
| `program.tcl` | Variant B:JTAG 烧写三连 |
| `load_fpga.sh` | 主路 A:bit2bin → scp → FPGA Manager 装载一条龙 |

## devmem 命令卡(背下这五行,你就是把两个世界接通的人)

```bash
# ssh root@192.168.1.10(root/root)之后:

# ① FCLK0 现状:先读后写(工程师的礼貌)
devmem 0xF8000170
# 若 bit24 已是 1(时钟已活)→ 跳过 ②

# ② 使能 FCLK0 = 50MHz —— "给电路接电源"的仪式
#    组装:bit24=1(使能) | DIV1=1<<16 | DIV0=20<<8 | 源=IOPLL(00<<4)
#    IO PLL 1000MHz ÷ DIV0(20) ÷ DIV1(1) = 50MHz
devmem 0xF8000170 32 0x01011400
# (除数以板上 IO PLL 实际值为准;先读回旧值换算,别盲写)

# ③ L0 点灯:CTRL 的 bit0 写 1 / 写 0
devmem 0x40000000 32 0x00000001
devmem 0x40000000 32 0x00000000

# ④ L1 呼吸调速:SPEED 写分频(公式:呼吸周期 ≈ (SPEED+1) × 2.62ms @50MHz)
devmem 0x40000004 32 0x0000017D   # ≈1 秒一次呼吸
devmem 0x40000004 32 0x000005F5   # ≈4 秒一次呼吸
devmem 0x40000004 32 0x00000000   # 回手动挡(CTRL bit0 直接控灯)

# ⑤ 读回(验证"读 = 回值":应回显你最后写的数)
devmem 0x40000004
```

### 地址是怎么算出来的(软件工程师的本能问题)

```
寄存器地址 = GP0 基址 + 寄存器偏移
           = 0x4000_0000 + 0x00(CTRL)→ 0x4000_0000
           = 0x4000_0000 + 0x04(SPEED)→ 0x4000_0004
```

单从机直挂 GP0,**没有互连重映射**:你在 Verilog 里例化时接的是哪根地址线,ARM 就按偏移 0x00/0x04 直达。若走预案乙(垫 Interconnect),互连只转发不改地址,偏移不变。

## 两条装载路(互斥,谁后到谁生效)

| | 主路 A:FPGA Manager(FIQ 门内) | Variant B:JTAG + devmem(门外的保底路) |
|---|---|---|
| 谁装载 | Debian(`load_fpga.sh`:bit2bin → scp → echo 固件名) | PC(`program.tcl`,先 `pkill -f openocd`) |
| 前置 | 三绿验收门已过 | 无(FIQ 修复不依赖) |
| 装载后 | 已是运行态,直接跑命令卡 ③ | 先跑命令卡 ①②(FCLK0 使能 = 接电源仪式) |
| 注意 | .bit 必须先过 bit2bin.py | JTAG 装的流会顶掉 Manager 装的流,反之亦然 |

## 步骤

1. `vivado -mode batch -source build.tcl` → 检查 WNS ≥ 0(**若时序报告是灰的,说明 create_clock 没生效,先修 XDC**)
2. 门内:跑 `./load_fpga.sh` 三绿 → 命令卡 ③④⑤
   门外:跑 `vivado -mode batch -source program.tcl` → ssh 上板跑命令卡 ①→⑤
3. **毕业考**:不看资料,手绘"一条 devmem 0x40000000 32 1 的全路径"(ARM 指令 → AXI 通道 → CTRL 寄存器 → mux → R14),对照课程页图 2 验收

## 资源账本

| Lab | LUT | FF | 备注 |
|---|---|---|---|
| lab08 AXI 从机 | | | 上课记过 |
| **lab09 会师顶层** | | | 填入 build.tcl 报告值(预计 300 上下) |

## 首跑微调清单(板上第一批要盯的点)

本 lab 是"待实测"三件套的实地考场(板子恢复后首日补测):

1. **PS7 原语端口名**:若综合报未定义端口(FCLKCLK0 / M_AXI_GP0_*),查 2026.1 原语库的实际拼写,改 top 即可
2. **AXI3 直挂**(方案甲):若 devmem ③ 写了 LED 没反应/读回 0xDEAD 之类的脏值 → 切 build.tcl 里的预案乙垫桥
3. **FCLK0 除数**:0xF8000170 读回值先手算一遍再写;若内核 clk 框架已把 FCLK0 挂走,`cat /sys/kernel/debug/clk/clk_summary | grep -i fclk` 看状态
4. **频率一致性**:SLCR 里配了非 50MHz → lab09.xdc 的 create_clock 周期要同步改,否则 WNS 是错的

## 思考题

1. SPEED 写 `0x00010000`(65536)会发生什么?(提示:top 里只取了低 16 位)
2. 为什么这个设计敢不用复位(aresetn 绑 1)?
3. 如果想让呼吸"亮度上限"也能调,寄存器映射怎么扩?(答案开向 lab10)
