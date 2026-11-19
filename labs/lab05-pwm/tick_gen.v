// ============================================================
// tick_gen —— "数满 DIV 个时钟,发一个单周期脉冲"
// ============================================================
// 全课程被复用最多的零件:lab01/lab02 里你已经手写了两遍
// "数满 N 产一个 tick",第三遍之前,把它抽成模块——从此只
// 例化,不再抄。例化它的地方:
//   ch05  #(.DIV(390625))   呼吸灯亮度步进(7.8125ms/步)
//   (ch06 的波特率节拍是同一手法,但它要跟状态机走停,
//    长在 uart_tx 肚子里,不单独例化——到时对照着想一想)
//
// 参数 DIV:多少个时钟产一个 tick。任意整数(≥2)都行,
// 不必是 2 的幂——这是它比"cnt 最高位"手法更通用的地方。
//   DIV = 2**23   → 每 0.1678s 一 tick(lab01 cnt[23] 的节奏)
//   DIV = 434     → 115200 波特一位 8.68us(同款算术)
module tick_gen #(
    parameter DIV = 390_625
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick        // 每 DIV 个时钟,高电平恰好 1 拍
);

    // 需要几位的计数器:clog2(390625)=19
    localparam W = $clog2(DIV);

    reg [W-1:0] div_cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            div_cnt <= {W{1'b0}};
            tick    <= 1'b0;
        end else if (div_cnt == DIV - 1) begin
            div_cnt <= {W{1'b0}};
            tick    <= 1'b1;         // 数满:发一个……
        end else begin
            div_cnt <= div_cnt + 1'd1;
            tick    <= 1'b0;         // ……单周期脉冲,下一拍自动熄灭
        end
    end

endmodule
