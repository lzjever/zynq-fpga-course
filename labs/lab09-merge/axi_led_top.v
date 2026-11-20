// ============================================================
// Lab 09 · 会师顶层:PS7 直例化 + AXI-Lite 从机 + 呼吸灯
// ============================================================
// 时钟域方案甲:整个设计只活在 FCLK0 一个时钟域里。
// AXI3 适配(codex 方案 b,2026-11-20):
//   - GP0 是 AXI3 方言,单拍事务也须返回 BID/RID/RLAST
//   - 顶层反射 ID(BID=锁存的 AWID,RID=锁存的 ARID)
//   - RLAST 常高:本从机每笔读只有一拍,RLAST 只在 RVALID=1 时有意义
//   - WLAST 由 PS 驱动,传给从机确认"这是最后一拍数据"
//   - aresetn 接 PS7.FCLKRESETN[0](不再绑死高)
module axi_led_top (
    output wire led        // R14,低电平点亮(本顶层在引脚侧取反)
);

    // ============ ① 复位策略 ============
    // 从 PS7 的 FCLKRESETN[0] 取复位(PS 可控制 PL 复位)
    wire [3:0] fclk_reset_n_bus;
    wire aresetn = fclk_reset_n_bus[0];

    // ============ ② PS7 原语 ============
    wire [3:0] fclk_bus;
    wire fclk0 = fclk_bus[0];

    // GP0 总线(含 AXI3 独有信号)
    wire [31:0] gp0_awaddr;
    wire        gp0_awvalid, gp0_awready;
    wire [11:0] gp0_awid;             // AXI3:写地址 ID(PS 驱动)
    wire [31:0] gp0_wdata;
    wire        gp0_wvalid, gp0_wready;
    wire        gp0_wlast;             // AXI3:写末拍标记(PS 驱动)
    wire        gp0_bvalid, gp0_bready;
    wire [1:0]  gp0_bresp;
    wire [31:0] gp0_araddr;
    wire        gp0_arvalid, gp0_arready;
    wire [11:0] gp0_arid;             // AXI3:读地址 ID(PS 驱动)
    wire [31:0] gp0_rdata;
    wire        gp0_rvalid, gp0_rready;
    wire [1:0]  gp0_rresp;

    // AXI3 ID 反射:锁存 AWID/ARID → 回给 BID/RID
    reg [11:0] gp0_bid, gp0_rid;

    always @(posedge fclk0) begin
        if (!aresetn) begin
            gp0_bid <= 12'd0;
            gp0_rid <= 12'd0;
        end else begin
            if (gp0_awvalid && gp0_awready)
                gp0_bid <= gp0_awid;
            if (gp0_arvalid && gp0_arready)
                gp0_rid <= gp0_arid;
        end
    end

    PS7 PS7_i (
        .FCLKCLK         (fclk_bus),
        .FCLKRESETN      (fclk_reset_n_bus),   // PS→PL 复位(低有效)
        .MAXIGP0ACLK     (fclk0),
        // ---- 写通道 ----
        .MAXIGP0AWADDR (gp0_awaddr),
        .MAXIGP0AWVALID(gp0_awvalid),
        .MAXIGP0AWREADY(gp0_awready),
        .MAXIGP0AWPROT (),
        .MAXIGP0AWID   (gp0_awid),             // AXI3:接回来!
        .MAXIGP0WDATA  (gp0_wdata),
        .MAXIGP0WVALID (gp0_wvalid),
        .MAXIGP0WREADY (gp0_wready),
        .MAXIGP0WSTRB  (),
        .MAXIGP0WLAST  (gp0_wlast),             // AXI3:接回来!
        .MAXIGP0BVALID (gp0_bvalid),
        .MAXIGP0BREADY (gp0_bready),
        .MAXIGP0BRESP  (gp0_bresp),
        .MAXIGP0BID    (gp0_bid),               // AXI3:反射 AWID!
        // ---- 读通道 ----
        .MAXIGP0ARADDR (gp0_araddr),
        .MAXIGP0ARVALID(gp0_arvalid),
        .MAXIGP0ARREADY(gp0_arready),
        .MAXIGP0ARPROT (),
        .MAXIGP0ARID   (gp0_arid),              // AXI3:接回来!
        .MAXIGP0RVALID (gp0_rvalid),
        .MAXIGP0RREADY (gp0_rready),
        .MAXIGP0RDATA  (gp0_rdata),
        .MAXIGP0RRESP  (gp0_rresp),
        .MAXIGP0RID    (gp0_rid),               // AXI3:反射 ARID!
        .MAXIGP0RLAST  (1'b1)                   // AXI3:单拍读,RLAST 恒 1
        // 其余端口(DDR/MIO/中断…)挂空
    );

    // ============ ③ 从机(lab08 两寄存器版,含背压修复) ============
    wire [31:0] ctrl;
    wire [31:0] speed;

    axi_lite_slave u_slave (
        .aclk(fclk0), .aresetn(aresetn),
        .s_axi_awaddr(gp0_awaddr[3:0]), .s_axi_awvalid(gp0_awvalid), .s_axi_awready(gp0_awready),
        .s_axi_wdata (gp0_wdata),      .s_axi_wvalid (gp0_wvalid),  .s_axi_wready (gp0_wready),
        .s_axi_wlast (gp0_wlast),      // AXI3:末拍标记传给从机
        .s_axi_bvalid(gp0_bvalid),     .s_axi_bready (gp0_bready),  .s_axi_bresp  (gp0_bresp),
        .s_axi_araddr(gp0_araddr[3:0]),.s_axi_arvalid(gp0_arvalid), .s_axi_arready(gp0_arready),
        .s_axi_rvalid(gp0_rvalid),     .s_axi_rready (gp0_rready),  .s_axi_rresp  (gp0_rresp),
        .s_axi_rdata (gp0_rdata),
        .ctrl(ctrl), .speed(speed)
    );

    // ============ ④ 点灯/呼吸 ============
    wire breath_led;
    pwm_breather u_breath (
        .clk  (fclk0),
        .speed(speed[15:0]),
        .led  (breath_led)
    );

    assign led = ~((speed[15:0] == 16'd0) ? ctrl[0] : breath_led);

endmodule
