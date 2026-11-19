// ============================================================
// Lab 06 · 按键单脉冲 — Lab02 消抖器的第 N 次复用
// ============================================================
// 作用:把 P14 这根"野信号"变成一个干净的单周期脉冲 tick:
//   按一次 PL_KEY → tick 输出恰好 1 个时钟宽的脉冲(不管按多久、抖多少)
// 链条:打两拍同步(ch03)→ 稳定计数消抖(ch02)→ 下降沿检测(ch02)
// 三个旧 Lab 在此汇合 —— 这就是课程复利。
module key_pulse #(
    parameter STABLE_CYCLES = 1_000_000    // 稳定阈值:20ms × 50MHz = 100 万个时钟
)(
    input  wire clk,
    input  wire rst_n,
    input  wire key,                       // 原始按键(按下 = 0)
    output wire tick                       // 单周期脉冲:确认"按下"那一刻输出 1 拍
);
    // ---------- 第 1 级:打两拍同步器(ch03 的保险,防止亚稳态进 50MHz 世界) ----------
    reg [1:0] sync = 2'b11;    // 初值 = 松开(空闲是 1);声明处初值综合成上电值
    always @(posedge clk)
        if (!rst_n) sync <= 2'b11;         // 复位 = 松开(按键空闲是 1)
        else       sync <= {sync[0], key}; // 两拍流水,输出永远比输入晚 2 个时钟

    wire key_s = sync[1];                  // 同步后的按键电平

    // ---------- 第 2 级:消抖 —— 电平必须稳定 STABLE_CYCLES 个时钟才被承认 ----------
    // 抖动一来计数就清零重数(和 Lab02 一模一样的思想)
    reg [$clog2(STABLE_CYCLES)-1:0] cnt = 0;
    reg key_stable = 1'b1;
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt        <= 0;
            key_stable <= 1'b1;
        end else if (key_s != key_stable) begin       // 线上电平和"被承认的电平"不一致
            if (cnt == STABLE_CYCLES-1) begin          // 不一致且已稳定满 20ms → 承认新电平
                key_stable <= key_s;
                cnt        <= 0;
            end else
                cnt <= cnt + 1'd1;                     // 还在数(抖动期间反复被清零)
        end else
            cnt <= 0;                                   // 一致:不数
    end

    // ---------- 第 3 级:下降沿检测 → 单周期脉冲 ----------
    // key_stable_q 是 key_stable 的"上一拍照片";旧值 1、新值 0 = 按下沿
    reg key_stable_q = 1'b1;
    always @(posedge clk)
        if (!rst_n) key_stable_q <= 1'b1;
        else        key_stable_q <= key_stable;

    assign tick = key_stable_q & ~key_stable;   // 恰好 1 个时钟宽(ch02 的边沿检测惯用法)

endmodule
