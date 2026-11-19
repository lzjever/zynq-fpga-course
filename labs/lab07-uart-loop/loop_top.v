// ============================================================
// Lab 07 · 顶层 — 自环回:板子说一句自己听得懂的话
// ============================================================
// 全链路(课程页 §5 的接线图):
//   P14 按键 → key_pulse(tick)→ uart_tx(把 'H' 铺到 tx 线)
//   tx 线 → 引脚 U12 ──杜邦线── 引脚 W16 → uart_rx → rx_done
//   rx_done 每来一拍 → LED(R14)翻转一次(ch02 的 T 触发器惯用法)
//   收到的同时和发送内容比较 → dbg_match(1 = 回环字一致)
//
// 实验变量 = 那根杜邦线:
//   插上:按一次 → LED 翻一次(说的每一句都听到了)
//   拔掉:按再多次 LED 纹丝不动(xdc 给 rx 加了内部上拉,拔线 = 恒 1 = 静默,
//         不是悬空乱读 —— 这样"拔线收不到"才是干净的实验结论)
module loop_top #(
    parameter BAUD_DIV = 434,              // 115200;仿真里 TB 会覆盖成 8 提速
    parameter STABLE_CYCLES = 1_000_000,   // 消抖 20ms;TB 覆盖成 40 提速
    parameter [7:0] CHAR = 8'h48           // 自环内容:'H'
)(
    input  wire clk,      // 50MHz(N18)
    input  wire key,      // PL_KEY(P14)= 发射按钮
    input  wire rx_pad,   // 排针 W16(杜邦线一头)
    output wire tx_pad,   // 排针 U12(杜邦线另一头)
    output wire led       // R14:收到一个字节翻转一次
    // 注:dbg_done/dbg_data/dbg_match 不再作为端口引出(纯片内观察信号
    // 不该上端口表);它们降级为下面的内部 wire,TB 用分层引用 dut.dbg_* 读
);
    wire tick;
    wire [3:0] tx_bit_cnt, rx_bit_cnt;   // ILA 模式下接探针,普通模式悬空
    wire [1:0] tx_state,  rx_state;

    // ---------- 发射链(和 lab06 一模一样) ----------
    key_pulse #(.STABLE_CYCLES(STABLE_CYCLES)) u_key (
        .clk(clk), .rst_n(1'b1), .key(key), .tick(tick)
    );
    uart_tx #(.BAUD_DIV(BAUD_DIV)) u_tx (
        .clk(clk), .rst_n(1'b1),
        .start(tick), .data(CHAR),
        .tx(tx_pad), .busy(),
        .bit_cnt(tx_bit_cnt), .state(tx_state)
    );

    // ---------- 接收链(本章新货) ----------
    wire rx_done_w;
    wire [7:0] rx_data_w;
    uart_rx #(.BAUD_DIV(BAUD_DIV)) u_rx (
        .clk(clk), .rst_n(1'b1),
        .rx(rx_pad),
        .rx_data(rx_data_w), .rx_done(rx_done_w), .frame_err(),
        .bit_cnt(rx_bit_cnt), .state(rx_state)
    );

    // ---------- 收到即翻转:T 触发器(ch02 惯用法第 N 次上岗) ----------
    reg led_r = 1'b0;
    always @(posedge clk)
        if (rx_done_w) led_r <= ~led_r;
    // R14 低电平点亮:引脚侧取反(T 触发器只管翻转,极性不影响"收到即翻转")
    assign led = ~led_r;

    // 观察窗:RX 完成一帧的单周期脉冲 / 收到的字节 / 收发是否一致(回环完整性)
    wire       dbg_done  = rx_done_w;
    wire [7:0] dbg_data  = rx_data_w;
    wire       dbg_match = (rx_data_w == CHAR);   // 回环比较:发送内容 vs 接收结果

// ---------- ILA 模式:加 -verilog_define ILA 时,5 探针核自动长进来 ----------
// (build.tcl 的 ila 模式负责 create_ip ila_uart + 打开这个宏,普通模式整段消失)
`ifdef ILA
    ila_uart u_ila (
        .clk    (clk),          // 探针:rx 线、rx_done、tick、bit_cnt、state —— 5 个用满
        .probe0 (rx_pad),       // rx 波形(解码练习的主角)
        .probe1 (rx_done_w),
        .probe2 (tick),
        .probe3 (rx_bit_cnt),
        .probe4 (rx_state)
    );
`endif

endmodule
