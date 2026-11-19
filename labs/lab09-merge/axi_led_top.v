// ============================================================
// Lab 09 · 会师顶层:PS7 直例化 + AXI-Lite 从机 + 呼吸灯
// ============================================================
// 时钟域方案甲(FINAL 裁定):整个设计只活在 FCLK0 一个时钟域里。
//   - N18(板上 50MHz 晶振)在本设计退役:如果逻辑跑 N18、寄存器
//     活在 FCLK0 域,ARM 写进来的多比特 SPEED 就是一颗 CDC 雷
//     (数值撕裂,ch03 的教训)。一刀切进同域,雷不存在。
//   - 代价:FCLK0 由 PS 说了算——所以"使能 FCLK0"那条 devmem
//     命令,是这门课真正意义上的"给电路接电源"(见 README 命令卡)。
//
// PS7 直例化说明:
//   - PS7 是库原语,像例化普通模块一样用,**不进 Block Design**;
//   - 原语端口名与 BD/IP 封装版略有差别(原语 FCLKCLK0,封装 FCLK_CLK0),
//     拿不准就综合一遍,Vivado 会直接点名未定义的端口名;
//   - PS7 有几百个端口(DDR/MIO/中断……),没列出的自动挂空——
//     PS 那半边早已被 FSBL/u-boot 配置好并在跑 Debian,轮不到比特流操心。
//   - GP0 是 AXI3 方言(ch08 方案甲):下面只接 AXI4-Lite 用得着的线,
//     AXI3 独有信号(ID/突发类)全部挂空置之不理。
module axi_led_top (
    output wire led        // R14,高电平点亮 —— 本设计唯一的物理引脚
);

    // ============ ① 复位策略 ============
    // 本设计不需要复位:FCLK0 一停,全体触发器冻结(值保住);时钟回来,继续跑。
    wire aresetn = 1'b1;

    // ============ ② PS7 原语:从 ARM 那半边引出 FCLK0 和 GP0 ============
    wire fclk0;    // PS 送给 PL 的时钟(频率由 SLCR 寄存器定,默认配 50MHz)

    // GP0 总线(lab08 的 S_AXI_* 线,这里接上真 ARM)
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
        .FCLKCLK0        (fclk0),     // 时钟输出:整个设计的唯一节拍
        .M_AXI_GP0_ACLK  (fclk0),     // GP0 总线时钟同源 —— 同域,无 CDC
        // ---- 写通道(AXI3 主侧 ↔ 我们的 AXI4-Lite)----
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
        // ---- AXI3 独有信号,挂空 = 置之不理(ch08 方案甲)----
        .M_AXI_GP0_AWID   (), .M_AXI_GP0_WID (), .M_AXI_GP0_WLAST (),
        .M_AXI_GP0_BID    (),
        // ---- 读通道 ----
        .M_AXI_GP0_ARADDR (gp0_araddr),
        .M_AXI_GP0_ARVALID(gp0_arvalid),
        .M_AXI_GP0_ARREADY(gp0_arready),
        .M_AXI_GP0_ARPROT (),
        .M_AXI_GP0_RVALID (gp0_rvalid),
        .M_AXI_GP0_RREADY (gp0_rready),
        .M_AXI_GP0_RDATA  (gp0_rdata),
        .M_AXI_GP0_RRESP  (gp0_rresp),
        .M_AXI_GP0_ARID   (), .M_AXI_GP0_RID (), .M_AXI_GP0_RLAST ()
        // 其余几百个端口(DDR/MIO/中断/EMIO…)未列出 = 挂空,PS 侧自有人管
    );

    // ============ ③ 你的从机(lab08 的两寄存器版) ============
    wire [31:0] ctrl;    // 0x00 偏移的影子
    wire [31:0] speed;   // 0x04 偏移的影子

    axi_lite_slave u_slave (
        .aclk(fclk0), .aresetn(aresetn),
        .s_axi_awaddr(gp0_awaddr[3:0]), .s_axi_awvalid(gp0_awvalid), .s_axi_awready(gp0_awready),
        .s_axi_wdata (gp0_wdata),      .s_axi_wvalid (gp0_wvalid),  .s_axi_wready (gp0_wready),
        .s_axi_bvalid(gp0_bvalid),     .s_axi_bready (gp0_bready),  .s_axi_bresp  (gp0_bresp),
        .s_axi_araddr(gp0_araddr[3:0]),.s_axi_arvalid(gp0_arvalid), .s_axi_arready(gp0_arready),
        .s_axi_rvalid(gp0_rvalid),     .s_axi_rready (gp0_rready),  .s_axi_rresp  (gp0_rresp),
        .s_axi_rdata (gp0_rdata),
        .ctrl(ctrl), .speed(speed)
    );

    // ============ ④ L0 点灯 / L1 呼吸:一个寄存器决定挡位 ============
    wire breath_led;
    pwm_breather u_breath (
        .clk  (fclk0),
        .speed(speed[15:0]),        // SPEED 只取低 16 位(思考题:写 0x10000 会怎样?)
        .led  (breath_led)
    );

    // SPEED=0 → 手动挡:LED 直接等于 CTRL 的 bit0(L0 点灯)
    // SPEED>0 → 呼吸挡:LED 跟着呼吸灯跑,速度由 SPEED 定(L1 调速)
    assign led = (speed[15:0] == 16'd0) ? ctrl[0] : breath_led;

endmodule
