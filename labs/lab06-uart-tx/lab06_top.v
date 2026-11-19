// ============================================================
// Lab 06 · 顶层 — 肉眼 UART 与真实波特率共用一份代码
// ============================================================
// 接线图(全部电路就两块):
//   P14 按键 → key_pulse(消抖出 tick)→ uart_tx(把 CHAR 一帧发出去)
//   tx 线直接焊到 R14 LED 上 ← 本课的戏法:用眼睛当接收器
//
// 现象由 BAUD_DIV 一个参数决定(build.tcl 里 -tclargs 切换,代码零改动):
//   eye  : BAUD_DIV=25_000_000(2 波特)→ 按一次键,LED 用 5 秒打出 'H' 帧
//   real : BAUD_DIV=434(115200 波特)→ 按一次键,LED 几乎无感(86.8µs 的事,
//          肉眼失效 → 所以有 ILA 版,见 lab06_ila_top.v)
//
// 注意 1:tx 空闲态 = 1 → LED 平时常亮,这是协议规定,不是 bug。
// 注意 2:P14 在 lab01 里当"复位"用,本课改行当"发射按钮"——按一下,发一帧。
//   复位怎么办?FPGA 的触发器上电会读 initial 值(uart_tx 里 tx 出生就是 1),
//   所以本设计不需要外部复位键。真想硬复位整个电路:按板上 RST?不行!那是
//   整芯片复位(清 PL 配置 + 重启 Debian)。正确的做法是重新烧写比特流。
module lab06_top #(
    parameter BAUD_DIV = 25_000_000,      // 默认肉眼版;real/ila 版由脚本覆盖为 434
    parameter [7:0] CHAR = 8'h48          // 发送内容:'H'(0x48 = 8'b0100_1000)
)(
    input  wire clk,      // 50MHz 晶振(N18)
    input  wire key,      // PL_KEY(P14,按下=0)= 发射按钮
    output wire led       // LED(R14)—— 直接接 tx 线,肉眼当接收器
);
    wire tick;            // 按键确认沿的单周期脉冲
    wire busy;            // 发送器忙标志(肉眼版一帧 5 秒,连按会丢帧——正好用它讲清 busy 的用途)

    key_pulse u_key (
        .clk   (clk),
        .rst_n (1'b1),    // 上电初始值已够,不需要外部复位(见上"注意 2")
        .key   (key),
        .tick  (tick)
    );

    uart_tx #(.BAUD_DIV(BAUD_DIV)) u_tx (
        .clk    (clk),
        .rst_n  (1'b1),
        .start  (tick),   // tick 来了就发一帧
        .data   (CHAR),
        .tx     (led),    // ← 戏法所在:tx 线就是 LED
        .busy   (busy),
        .bit_cnt(),       // 观察窗悬空(ILA 版才接)
        .state  ()
    );

endmodule
