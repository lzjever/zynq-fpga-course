// ============================================================
// Lab 08 · 最小 AXI4-Lite 从机 — 一扇 ARM 敲得开的门
// ============================================================
// 全部行为一句话:一个 32 位寄存器,写 = 把值存进去,读 = 把值端出来。
//
// 心智模型:它不是"程序",是一张前台柜台——
//   ARM(主机)隔着五条通道递单子,你(从机)按握手规矩接单、回执。
//   寄存器 reg0 就是柜台上唯一的那个旋钮:ARM 写它 = 伸手拨旋钮。
//
// 本课纯仿真:TB 假扮 ARM 来敲门(ch09 才接真 ARM)。
// 端口名沿用 Xilinx 惯例 S_AXI_*(S = Slave,AXI 侧),
// ch09 里它们会原封不动地连到 PS7 的 MAXIGP0*(M = Master;原语实名不带下划线,
// IP 封装名才写作 M_AXI_GP0_*)上。
module axi_lite_slave #(
    parameter ADDR_W = 4            // 地址位宽:4 位足够覆盖 16 字节 = 4 个 32 位寄存器的空间
)(
    input  wire              aclk,     // 总线时钟(仿真里由 TB 给;板上来自 FCLK0)
    input  wire              aresetn,  // 低电平复位的"n"(negative)——AXI 家族惯例
    // ---------- 写地址通道 AW ----------
    input  wire [ADDR_W-1:0] s_axi_awaddr,
    input  wire              s_axi_awvalid,   // 主机:"单子有效"
    output wire              s_axi_awready,   // 从机:"我准备好了"
    // ---------- 写数据通道 W ----------
    input  wire [31:0]       s_axi_wdata,
    input  wire              s_axi_wvalid,
    output wire              s_axi_wready,
    // ---------- 写响应通道 B ----------
    output reg               s_axi_bvalid,    // 从机:"写完了,回执在这"
    input  wire              s_axi_bready,    // 主机:"回执我收"
    output wire [1:0]        s_axi_bresp,     // 00=OKAY(本从机永远 OKAY)
    // ---------- 读地址通道 AR ----------
    input  wire [ADDR_W-1:0] s_axi_araddr,
    input  wire              s_axi_arvalid,
    output wire              s_axi_arready,
    // ---------- 读数据通道 R ----------
    output reg               s_axi_rvalid,
    output reg  [31:0]       s_axi_rdata,     // 读数据:成交拍锁存,保持到 rready
    input  wire              s_axi_rready,
    output wire [1:0]        s_axi_rresp,
    // ---------- 寄存器的对外化身 ----------
    output wire [31:0]       knob             // reg0 的影子,拿去接任何"旋钮"(ch09 接 PWM)
);

    // 响应码恒为 OKAY:本从机没有"失败"这个概念
    assign s_axi_bresp = 2'b00;
    assign s_axi_rresp = 2'b00;

    // ========================================================
    // 写路径:AW 和 W 两个通道**各自**握手,都成交才算"一笔写"
    // ========================================================
    reg          aw_seen;        // 写地址到了吗
    reg          w_seen;         // 写数据到了吗
    reg [ADDR_W-1:0] awbuf;      // 成交拍锁存的地址(为什么锁?AW/W 可能不同拍到)
    reg [31:0]   wbuf;           // 成交拍锁存的数据(同上:成交后 wdata 可能就变了)
    reg [31:0]   reg0;           // ★ 唯一的寄存器:ARM 要拨的那个旋钮
    wire write_fire = aw_seen && w_seen;   // 地址数据都到齐 → 落寄存器 + 举回执

    // ready 策略(最简单的合法策略):没收到的时候就随时欢迎,收到就关门
    assign s_axi_awready = !aw_seen;
    assign s_axi_wready  = !w_seen;

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_seen <= 1'b0;
            w_seen  <= 1'b0;
            reg0    <= 32'd0;
            s_axi_bvalid <= 1'b0;
        end else begin
            // 各通道各自记账:成交拍锁存地址/数据
            if (s_axi_awvalid && s_axi_awready) begin
                aw_seen <= 1'b1;
                awbuf   <= s_axi_awaddr;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_seen  <= 1'b1;
                wbuf    <= s_axi_wdata;
            end
            // 到齐:这一拍是"拨旋钮"的时刻
            if (write_fire) begin
                reg0    <= wbuf;          // ← 写 = 存值(单寄存器不译码:任何地址都落到 reg0,
                aw_seen <= 1'b0;          //    多寄存器版见 lab09 的 case 译码)
                w_seen  <= 1'b0;
                s_axi_bvalid <= 1'b1;     // 举回执,等主机 bready
            end
            // 回执成交后放下(铁律:bvalid 一旦举起,不得撤销,只能等成交)
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // ========================================================
    // 读路径:AR 握手成交 → rvalid 举起,数据保持到 R 成交
    // ========================================================
    assign s_axi_arready = !s_axi_rvalid;    // 上一笔没回完之前,不接新单

    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'd0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= reg0;       // ← 读 = 回值(把寄存器**现值**端出去)
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;       // 成交后放下
            end
        end
    end

    assign knob = reg0;                     // 旋钮的影子:值变了,外面的电路立刻看得见

endmodule
