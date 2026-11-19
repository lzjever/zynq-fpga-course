// ============================================================
// Lab 09 · AXI4-Lite 从机(两寄存器版)
// ============================================================
// 相比 lab08 版的全部改动(DIFF 已标注):
//   1. 多了一个寄存器 SPEED(偏移 0x04)
//   2. 写/读时用锁存的地址做译码(case),CTRL/SPEED 各归各门
// 行为仍然一句话:写 = 存值,读 = 回值。
//
// 寄存器映射(Register Map):
//   偏移 0x00  CTRL   读写  bit0 = LED 手动值(L0 点灯用)
//   偏移 0x04  SPEED  读写  呼吸分频(L1 调速用;0 = 手动挡)
module axi_lite_slave #(
    parameter ADDR_W = 4
)(
    input  wire              aclk,
    input  wire              aresetn,
    // ---------- 写地址通道 AW ----------
    input  wire [ADDR_W-1:0] s_axi_awaddr,
    input  wire              s_axi_awvalid,
    output wire              s_axi_awready,
    // ---------- 写数据通道 W ----------
    input  wire [31:0]       s_axi_wdata,
    input  wire              s_axi_wvalid,
    output wire              s_axi_wready,
    // ---------- 写响应通道 B ----------
    output reg               s_axi_bvalid,
    input  wire              s_axi_bready,
    output wire [1:0]        s_axi_bresp,
    // ---------- 读地址通道 AR ----------
    input  wire [ADDR_W-1:0] s_axi_araddr,
    input  wire              s_axi_arvalid,
    output wire              s_axi_arready,
    // ---------- 读数据通道 R ----------
    output reg               s_axi_rvalid,
    output reg  [31:0]       s_axi_rdata,
    input  wire              s_axi_rready,
    output wire [1:0]        s_axi_rresp,
    // ---------- 两个旋钮的对外化身 ----------
    output wire [31:0]       ctrl,      // ← 0x00 的影子
    output wire [31:0]       speed      // ← 0x04 的影子
);

    assign s_axi_bresp = 2'b00;      // 永远 OKAY(未映射地址也 OK——简化,见思考题)
    assign s_axi_rresp = 2'b00;

    // ========================================================
    // 写路径(与 lab08 相同的"各自记账,到齐落值",多了 case 译码)
    // ========================================================
    reg              aw_seen, w_seen;
    reg [ADDR_W-1:0] awbuf;          // 成交拍锁存的地址(译码用它的低位)
    reg [31:0]       wbuf;           // 成交拍锁存的数据
    reg [31:0]       reg_ctrl;       // 0x00 CTRL
    reg [31:0]       reg_speed;      // 0x04 SPEED        ← DIFF:多一个寄存器
    wire write_fire = aw_seen && w_seen;

    assign s_axi_awready = !aw_seen;
    assign s_axi_wready  = !w_seen;

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_seen <= 1'b0;  w_seen <= 1'b0;
            reg_ctrl <= 32'd0;  reg_speed <= 32'd0;
            s_axi_bvalid <= 1'b0;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_seen <= 1'b1;
                awbuf   <= s_axi_awaddr;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_seen <= 1'b1;
                wbuf   <= s_axi_wdata;
            end
            if (write_fire) begin
                case (awbuf[2])                  // ← DIFF:地址译码。字对齐,第 2 位区分 0x00/0x04
                    1'b0: reg_ctrl  <= wbuf;     //    偏移 0x00 → CTRL
                    1'b1: reg_speed <= wbuf;     //    偏移 0x04 → SPEED
                endcase
                aw_seen <= 1'b0;
                w_seen  <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // ========================================================
    // 读路径(同样的 case 译码)
    // ========================================================
    assign s_axi_arready = !s_axi_rvalid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'd0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                case (s_axi_araddr[2])           // ← DIFF:读也译码
                    1'b0: s_axi_rdata <= reg_ctrl;
                    1'b1: s_axi_rdata <= reg_speed;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    assign ctrl  = reg_ctrl;         // 旋钮手柄 ×2
    assign speed = reg_speed;

endmodule
