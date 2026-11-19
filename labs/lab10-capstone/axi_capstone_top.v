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
    wire fclk0;
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
        .FCLKCLK0        (fclk0),
        .M_AXI_GP0_ACLK  (fclk0),
        .M_AXI_GP0_AWADDR (gp0_awaddr),
        .M_AXI_GP0_AWVALID(gp0_awvalid),
        .M_AXI_GP0_AWREADY(gp0_awready),
        .M_AXI_GP0_AWPROT (),
        .M_AXI_GP0_WDATA  (gp0_wdata),
        .M_AXI_GP0_WVALID (gp0_wvalid),
        .M_AXI_GP0_WREADY (gp0_wready),
        .M_AXI_GP0_WSTRB  (),
        .M_AXI_GP0_BVALID (gp0_bvalid),
        .M_AXI_GP0_BREADY (gp0_bready),
        .M_AXI_GP0_BRESP  (gp0_bresp),
        .M_AXI_GP0_AWID   (), .M_AXI_GP0_WID (), .M_AXI_GP0_WLAST (), .M_AXI_GP0_BID (),
        .M_AXI_GP0_ARADDR (gp0_araddr),
        .M_AXI_GP0_ARVALID(gp0_arvalid),
        .M_AXI_GP0_ARREADY(gp0_arready),
        .M_AXI_GP0_ARPROT (),
        .M_AXI_GP0_RVALID (gp0_rvalid),
        .M_AXI_GP0_RREADY (gp0_rready),
        .M_AXI_GP0_RDATA  (gp0_rdata),
        .M_AXI_GP0_RRESP  (gp0_rresp),
        .M_AXI_GP0_ARID   (), .M_AXI_GP0_RID (), .M_AXI_GP0_RLAST ()
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
