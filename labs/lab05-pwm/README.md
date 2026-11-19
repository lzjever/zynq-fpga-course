# Lab 05 · PWM 呼吸灯(ch05 配套)

第一个"多模块工程":tick 生成器抽成 `tick_gen` 零件,呼吸灯顶层
`pwm_breathe` 例化它——从此告别第三次抄 tick。现象:R14 上的 LED
以约 4 秒一个周期平滑呼吸(渐亮 2s + 渐暗 2s)。

## 文件清单

| 文件 | 说明 |
|---|---|
| `tick_gen.v`    | tick 零件:数满 DIV 个时钟发一个单周期脉冲(parameter 可调) |
| `pwm_breathe.v` | 顶层:例化 tick_gen + 三角波亮度 + 载波相位 + 比较器 |
| `lab05.xdc`     | 引脚约束(和 lab01 同款三外设:N18/P14/R14) |
| `build.tcl`     | 五步舞一键脚本(尾部队附资源账本报告) |

## 命令卡

```bash
cd labs/lab05-pwm
vivado -mode batch -source build.tcl          # 构建 + 出账本
# 烧写:借用 ch04 的 program.tcl,改个路径就行(复习"脚本可复用")
cp ../lab01-blink/program.tcl .
sed -i 's/lab01/lab05/g' program.tcl
vivado -mode batch -source program.tcl
```

## 现象与验收

- LED 平滑呼吸,一个周期约 **4.0 s**(510 步 × 7.8125ms),
  无频闪(载波 195.3kHz,远超人眼暂留);
- **按住 PL_KEY**:LED 立即全灭(复位把 duty 清 0,占空比 0/256),
  松开后从最暗重新起呼吸——顺手验证了复位路径和 duty=0 边界;
- 变参数(改完重新 build,先猜后验):
  `STEP_DIV = 390_625 → 195_312`:呼吸变 2s(快一倍);
  `STEP_DIV = 781_250`:呼吸变 8s。
  呼吸周期 = 510 × STEP_DIV ÷ 50MHz,一个参数管全部。

## 边界陷阱复现(本章 B 类自测的实物版)

把 `pwm_breathe.v` 最后一行改成 `assign led = (phase <= duty);`
重新烧板:按住 PL_KEY(duty=0)时,LED 在暗房间里能看到极暗的
微光——`phase == duty == 0` 那一拍偷亮,占空比变成了 1/256。
"最暗档关不严"就是这么来的。比较器用 `<`,0 档才是真全灭。

## 资源账本(跑完 build 抄两格,ch04 全班对账)

| Lab | LUT | FF |
|---|---|---|
| lab05 | 29 | 37 |

2026.1 实测 29 LUT / 37 FF(tick 分频 19 FF + phase 8 + duty 8 + 比较逻辑;
引脚侧取反综合进了既有 LUT,不另占资源),以你的报告为准复核。

## 选做(不增加主线负担)

1. **正弦呼吸**:把三角波换成正弦表——`case (step)` 查一个 64 点
   亮度表(只读存储器(Read-Only Memory, ROM)的 case 写法)。
   注意术语:这个"查找表"是数据结构,和 FPGA 的 LUT(查找表)
   重名不同物——ch00 的 LUT 是硬件单元,别混。
2. **按键调速**:例化你 lab02 的消抖器,按一次 PL_KEY 在
   两档 STEP_DIV 之间切换(呼吸 2s ↔ 8s)。三个 Lab 的资产
   在这里第一次会师(ch06 还会会一次)。

## 常见坑

- 例化端口**永远用命名关联** `.clk(clk)` 写法;按位置写
  `(clk, rst_n, tick)` 顺序一错就是"编译通过、行为诡异";
- 参数覆盖写在 `#()` 里、端口连线写在 `()` 里,两括号别混:
  `tick_gen #(.DIV(434)) u (.clk(...), ...)`;
- `STEP_DIV` 改大之后计数器位宽不用手改——`$clog2(DIV)` 自动算,
  手写位宽迟早忘;
- 别给 phase / duty 用不同的复位条件,全家一个 rst_n。
