// ============================================================
// Lab 05 · PWM 呼吸灯 —— 例化时代的第一个顶层
// ============================================================
// 结构(自上而下,先画得出图再读得懂码):
//
//   tick_gen(例化)──→ step_tick:每 STEP_DIV 个时钟一拍
//   duty 三角波    ──→ 每步 ±1,在 0↔255 之间往返(亮度值)
//   phase 载波计数 ──→ 每 clk +1,0..255 循环(50M/256≈195.3kHz)
//   比较器        ──→ phase < duty 时点亮 LED:
//                        占空比 = duty/256 → 平均亮度 = duty 档
//
// 呼吸周期 = (255 亮步 + 255 暗步) × STEP_DIV ÷ 50MHz
//   STEP_DIV = 390625 → 510 × 7.8125ms ≈ 4.0 s(默认)
//   想快想慢,只改这一个数,别的都不动——这就是 parameter。
module pwm_breathe #(
    parameter STEP_DIV = 390_625    // 亮度每进一步,隔多少个时钟
)(
    input  wire clk,      // 50MHz 晶振(N18)
    input  wire rst_n,    // PL 按键(P14),按下=0
    output wire led       // LED(R14)
);

    // ---------- 例化 tick 生成器:从此不再抄第三遍 ----------
    wire step_tick;
    tick_gen #(.DIV(STEP_DIV)) u_step (
        .clk   (clk),
        .rst_n (rst_n),
        .tick  (step_tick)
    );

    // ---------- 载波相位:0..255 每 clk +1,永不停转 ----------
    // 周期 256×20ns = 5.12us(195.3kHz),远快于人眼暂留 → 无频闪
    reg [7:0] phase;
    always @(posedge clk)
        if (!rst_n) phase <= 8'd0;
        else        phase <= phase + 1'd1;

    // ---------- 亮度 duty:三角波往返 ----------
    reg [7:0] duty;      // 0=全灭,255≈全亮,共 256 档
    reg       up;        // 方向:1=渐亮,0=渐暗

    always @(posedge clk) begin
        if (!rst_n) begin
            duty <= 8'd0;
            up   <= 1'b1;
        end else if (step_tick) begin        // 只在步进拍动作
            if (up) begin
                if (duty == 8'd254) begin    // 亮到顶:
                    duty <= 8'd255;          //   在 255 停一步
                    up   <= 1'b0;            //   然后掉头渐暗
                end else
                    duty <= duty + 1'd1;
            end else begin
                if (duty == 8'd1) begin      // 暗到底:
                    duty <= 8'd0;            //   在 0 停一步
                    up   <= 1'b1;            //   掉头渐亮
                end else
                    duty <= duty - 1'd1;
            end
        end
    end

    // ---------- PWM 比较:相位走在亮度"预算"内 → 亮 ----------
    // duty=0   → phase<0 永假 → 全灭(0/256)
    // duty=255 → 亮 255/256(差 1/256 满亮,肉眼不可见)
    // 陷阱:写成 phase <= duty 的话,duty=0 会在 phase==0 那 1 拍
    //       偷亮 → "最暗档关不严"的微光 bug(ch05 讲)
    assign led = (phase < duty);

endmodule
