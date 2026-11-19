// ============================================================
// Lab 10 · 毕业设计骨架 — 呼吸灯亮度/速度 AXI 远控
// ============================================================
// 本文件故意只给你"管道",不给你"器官":
//   管道(已写好):PS7 直例化、GP0 的 AXI 线、时钟、输出端口
//   器官(你的作业,见 TODO):从机、呼吸引擎、挡位逻辑
//
// 规则:
//   ① 先想清楚寄存器映射再动笔(README 需求书)——设计电路,不是翻译代码
//   ② 卡壳 45 分钟才准展开下一级提示(和 lab02 同一条规矩)
//   ③ lab09 的 axi_lite_slave.v / pwm_breather.v 允许复制改造——
//      毕业考考的是"集成与扩展",不是背诵;但你必须能解释每一行
module axi_capstone_top (
    output wire led        // R14,高电平点亮 —— 仍然是唯一物理引脚
);

    // ===================================================================
    // TODO-0(先做):在纸上画框图 + 定寄存器映射(README 需求书第 2 节)
    //   建议(可自行设计,但必须在 README 里写清你的映射表):
    //     0x00 CTRL   —— bit0: 使能呼吸(0=熄灭,1=呼吸)
    //     0x04 BRIGHT —— 亮度上限(duty 三角波的峰值,0~255)
    //     0x08 SPEED  —— 呼吸速度(沿用 lab09 语义)
    // ===================================================================

    // ---------- 以下是管道:PS7 直例化(抄自 lab09,不用改) ----------
    wire [3:0] fclk_bus;            // FCLKCLK 是 4 位总线(FCLK0~FCLK3)
    wire fclk0 = fclk_bus[0];       // 只用 FCLK0
    wire aresetn = 1'b1;

    wire [31:0] gp0_awaddr;
    wire        gp0_awvalid, gp0_awready;
    wire [31:0] gp0_wdata;
    wire        gp0_wvalid, gp0_wready;
    wire        gp0_bvalid, gp0_bready;
    wire [1:0]  gp0_bresp;
    wire [31:0] gp0_araddr;
    wire        gp0_arvalid, gp0_arready;
    wire [31:0] gp0_rdata;
    wire        gp0_rvalid, gp0_rready;
    wire [1:0]  gp0_rresp;

    PS7 PS7_i (
        .FCLKCLK         (fclk_bus),
        .MAXIGP0ACLK     (fclk0),
        .MAXIGP0AWADDR (gp0_awaddr),
        .MAXIGP0AWVALID(gp0_awvalid),
        .MAXIGP0AWREADY(gp0_awready),
        .MAXIGP0AWPROT (),
        .MAXIGP0WDATA  (gp0_wdata),
        .MAXIGP0WVALID (gp0_wvalid),
        .MAXIGP0WREADY (gp0_wready),
        .MAXIGP0WSTRB  (),
        .MAXIGP0BVALID (gp0_bvalid),
        .MAXIGP0BREADY (gp0_bready),
        .MAXIGP0BRESP  (gp0_bresp),
        .MAXIGP0AWID   (), .MAXIGP0WID (), .MAXIGP0WLAST (), .MAXIGP0BID (),
        .MAXIGP0ARADDR (gp0_araddr),
        .MAXIGP0ARVALID(gp0_arvalid),
        .MAXIGP0ARREADY(gp0_arready),
        .MAXIGP0ARPROT (),
        .MAXIGP0RVALID (gp0_rvalid),
        .MAXIGP0RREADY (gp0_rready),
        .MAXIGP0RDATA  (gp0_rdata),
        .MAXIGP0RRESP  (gp0_rresp),
        .MAXIGP0ARID   (), .MAXIGP0RID (), .MAXIGP0RLAST ()
    );

    // ---------- 以下是器官:全部是你的 TODO ----------

    // TODO-1:例化你扩展后的从机(三寄存器版:lab09 的 case 加一个分支而已)
    //   提示:ctrl/bright/speed 三根影子线从这里引出来

    // TODO-2:呼吸引擎:在 pwm_breather 基础上加"亮度上限"
    //   提示:三角波不再是 0~255,而是 0~BRIGHT;想清楚 BRIGHT 变小的一瞬间,
    //         duty 如果正大于 BRIGHT,该怎么收敛(这就是"边界陷阱"的毕业版)

    // TODO-3:挡位/使能逻辑接 led
    //   提示:CTRL.bit0=0 → led 恒 0(熄灭);=1 → 跟呼吸引擎

    // assign led = ...;   ← 删掉本行注释前,设计必须能回答"这一位由谁驱动、何时变"

endmodule
