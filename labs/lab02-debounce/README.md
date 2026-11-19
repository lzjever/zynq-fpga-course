# Lab 02 · 按键消抖 — 实验报告(自己填)

> 章节:docs/ch02-debounce.html(先写后看:流程 = 自己写 → 三关 → 提示阶梯 → 参考 → 差异笔记)
> 硬件:Z7-Nano R20 · 50MHz=N18 · PL_KEY=P14(按下=0)· LED=R14(高=亮)
> **警示:丝印 RST 的按键 = 整芯片硬复位(清 PL + 重启 Debian)。本实验手指整天在按键区,按错一次,现象全没。**

## 0 · 文件清单

| 文件 | 角色 |
|---|---|
| `bare/key_toggle_raw.v` | 裸版(证物 A,~18 行):按一次乱翻,先烧它 |
| `reference/debounce.v` | 参考实现(提示阶梯第 3 级,**过关前别看**) |
| `reference/key_toggle.v` | 参考顶层:消抖 → T 触发器 → LED |
| `tb_debounce.v` | 测试台:随机抖动激励 + 三关自动判分(直接用,别改判分逻辑) |
| `lab02.xdc` | 约束(两版共用:P14 从 rst_n 改名 key) |
| `build.tcl` / `sim.tcl` / `program.tcl` | 一键构建 / 一键仿真 / 一键烧写 |

## 1 · 命令卡(第一次学在章节里,以后查在卡片里)

```bash
# 仿真(判三关,先跑这个)
cd labs/lab02-debounce && vivado -mode batch -source sim.tcl
#   自己写版:先改 sim.tcl 第 8 行,把 reference/debounce.v 换成你的文件

# 构建(烧哪版?先改 build.tcl 第 6 行 set variant bare/reference)
vivado -mode batch -source build.tcl

# 烧写(JTAG;若在跑 OpenOCD 先 pkill -f openocd)
vivado -mode batch -source program.tcl
```

## 2 · 现象记录表(先烧裸版,再烧消抖版,当场填)

### 裸版 key_toggle_raw(预测:乱翻)

| # | 按法 | LED 翻转次数 | 备注(哪次最离谱?) |
|---|---|---|---|
| 1 | 正常按 | | |
| 2 | 快速轻按 | | |
| 3 | 慢按到底 | | |
| 4 | …(自己加) | | |

### 消抖版 key_toggle(验收:按一次翻一次,50 次零失误)

| # | 按法 | 翻转次数 | 对了? |
|---|---|---|---|
| 1-50 | 正常按 ×50 | (数总数) | 应 50 次,零失误 |
| 51 | 快速连按 5 次 | | 应恰好 5 次 |
| 52 | 按住不放 3 秒 | | 应恰好 1 次 |
| 53 | 上电后第一按 | | 应 1 次(推演见课程页"上板"节) |

## 3 · 三关记录(全部仿真判定,截图贴这里)

| 关 | 判据 | STABLE=200 | STABLE=50 | STABLE=400 |
|---|---|---|---|---|
| 关1 | 按压 N 次 → key_stable 恰好 N 个干净下沿(抖动零漏网) | ☐ PASS | ☐ PASS | ☐ PASS |
| 关2 | 每按一次 → 恰好 1 个"一拍宽" tick | ☐ PASS | ☐ PASS | ☐ PASS |
| 关3 | 上面两列都过(设计吃参数,不吃巧合) | — | — | ☐ 全过 |

波形作业:在 STABLE=200 那跑的波形里,截一张"抖动一来,稳定计数器被按在地上清零重数"的图。
(提示:看 dut 内部的 cnt,key_n 抖动区放大。)

## 4 · 差异笔记(看完参考实现必写 ≥3 行,防"抄完即忘")

1. 等价:我的 ____ 和参考的 ____ 是同一件事,只是 ____
2. 我更清晰:____
3. 我没想到:____

## 5 · 资源账本(每次 build 后记一行,ch04 回头看曲线)

| Lab | 顶层 | LUT | FF | 来源 |
|---|---|---|---|---|
| lab01 | led_blink | ~30(量级,以实测为准) | 24 | 24 位计数器,回头补测 |
| lab02 裸版 | key_toggle_raw | | | lab02_bare/utilization.rpt |
| lab02 消抖版 | key_toggle | | | lab02_reference/utilization.rpt |

## 6 · 交作业清单

- [ ] 现象记录表填完(裸版乱翻 + 消抖版 50 次零失误)
- [ ] 三关 ×3 参数全 PASS 的终端截图
- [ ] "计数器清零重数"波形截图
- [ ] 差异笔记 ≥3 行
- [ ] (选做)把 R14 改接到稳定计数器高位等乱点:预测现象"按住时极暗闪烁"(高频翻转又被眼睛平均了——ch01 的知识回来串门)
