// ============================================================
// Lab 06 · ILA 版顶层 — 把 5 探针逻辑分析仪焊进发送器
// ============================================================
// 和 lab06_top 的唯一区别:tx/busy/tick/bit_cnt/state 不再裸奔,
// 全部接到 ILA(Integrated Logic Analyzer,集成逻辑分析仪)核的探针上。
// 免费档限制:1 个 ILA 核、最多 5 个探针 —— 我们正好 5 个,一个不浪费:
//   probe0 = tx      (1 位) 触发用:tx==0 即起始位开始
//   probe1 = busy    (1 位)
//   probe2 = tick    (1 位) 备用触发:按一次键抓一次
//   probe3 = bit_cnt (4 位总线,算 1 个探针)
//   probe4 = state   (2 位总线,算 1 个探针)
// ILA 核由 build.tcl 的 ila 模式自动生成(create_ip),不是手画的。
module lab06_ila_top #(
    parameter BAUD_DIV = 434,             // ILA 版固定真实波特率 115200(肉眼版不需要 ILA)
    parameter [7:0] CHAR = 8'h48
)(
    input  wire clk,      // N18,50MHz —— 也是 ILA 的采样时钟
    input  wire key,      // P14
    output wire led       // R14(还是接 tx,按一次"看不到什么"是正常的,看 ILA 去)
);
    wire tick;
    wire busy;
    wire [3:0] bit_cnt;
    wire [1:0] state;

    key_pulse u_key (
        .clk   (clk),
        .rst_n (1'b1),
        .key   (key),
        .tick  (tick)
    );

    uart_tx #(.BAUD_DIV(BAUD_DIV)) u_tx (
        .clk    (clk),
        .rst_n  (1'b1),
        .start  (tick),
        .data   (CHAR),
        .tx     (led),
        .busy   (busy),
        .bit_cnt(bit_cnt),   // 观察窗接出,喂给探针
        .state  (state)
    );

    // ILA 核:ila_uart(build.tcl 里 create_ip 生成,探针宽度必须和 IP 配置一致)
    ila_uart u_ila (
        .clk    (clk),        // 采样时钟 = 系统时钟:50MHz 采样,每拍记 5 个信号的值
        .probe0 (led),        // tx
        .probe1 (busy),
        .probe2 (tick),
        .probe3 (bit_cnt),
        .probe4 (state)
    );

endmodule
