// ============================================================
// Lab 02 · 顶层:消抖按键 → 翻转 LED(烧上板,按一次翻一次)
// ============================================================
// 和裸版 key_toggle_raw.v 端口完全相同(同用一份 lab02.xdc):
// 差别只在中间多了一层 20ms 时间滤波器。
module key_toggle (
    input  wire clk,     // 50MHz 晶振(N18)
    input  wire key,     // PL_KEY(P14,按下 = 0)——lab01 里它当过复位,今天转正当主角
    output reg  led      // LED(R14,低 = 亮);上电时触发器自动为 0,无需初始化(翻转逻辑不关心极性)
);

    wire tick;    // 消抖器的产出:每按一次,恰好一个时钟宽的脉冲

    // 例化消抖器,拧上真值参数:20ms × 50MHz = 100 万拍
    debounce #(.STABLE_CYCLES(1_000_000)) u_debounce (
        .clk   (clk),
        // 板上没有第二个 PL 按键给电路当复位(唯一的 RST 是整芯片复位,附录 A)。
        // 消抖电路其实不需要专用复位:上电时所有触发器为 0,
        // 推演见课程页"上板"一节——结论:LED 不会误翻,安全。
        .rst_n (1'b1),
        .key_n (key),
        .tick  (tick)
    );

    // T 触发器(Toggle Flip-Flop):把看不见的单周期脉冲"可见化"——
    // 每来一个 tick,LED 翻转一次。按一次翻一次,全靠上游只放行一个
    always @(posedge clk) begin
        if (tick)
            led <= ~led;
    end

endmodule
