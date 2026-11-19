// ============================================================
// Lab 02 · 参考实现(提示阶梯第 3 级)— 按键消抖器
// ============================================================
// 心智模型:一个"时间滤波器"。
//   信号想改变判定?可以——先稳定地保持 STABLE_CYCLES 拍(真值 = 20ms)。
//   中途抖回原电平哪怕一拍,计时器就被按在地上清零重数。
// 消抖器本质是个两状态小机器(松/按),转移条件是"稳定满 20ms"
// ——第 7 章给它正名"状态机"。
module debounce #(
    // 参数 = 电路的"出厂可调旋钮":稳定多少拍才改判。
    // 真值:20ms × 50MHz = 1_000_000 拍。测试台里可拧小快跑(第 5 章正式讲参数)
    parameter STABLE_CYCLES = 1_000_000
)(
    input  wire clk,      // 50MHz(N18)
    input  wire rst_n,    // 复位(测试台用;上板时接常 1,见 key_toggle.v)
    input  wire key_n,    // 原始按键(P14,按下 = 0;名字带 _n 提醒"低有效")
    output wire tick      // 每次可靠"按下",输出恰好 1 个时钟宽的脉冲
);

    // ---------- 第一级:稳定判定(时间滤波器)----------
    // key_stable:当前判定电平(1=松开,0=按下)。需求书规定了这个名字,
    // 因为测试台要直接观察它(分层引用是仿真的特权)
    reg        key_stable;
    // 稳定计时器:数 key_n 与判定"唱反调"连续多少拍了
    // 20 位:2^20 = 1_048_576 > 999_999,装得下 100 万(若把参数改得更大,记得加宽)
    reg [19:0] cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt        <= 20'd0;    // 复位:判定为"松开",计时清零
            key_stable <= 1'b1;
        end
        else if (key_n == key_stable) begin
            cnt <= 20'd0;           // 信号与判定一致:不用计时,归零待命
        end
        else begin
            // 信号与判定不一致:可能是真按/真松,也可能只是抖动,用时间裁决
            if (cnt == STABLE_CYCLES - 1) begin
                key_stable <= key_n;   // 连续数满 STABLE_CYCLES 拍:改判!
                cnt        <= 20'd0;   // (从 0 数到 N-1 恰好 N 拍——数轴陷阱,想清楚)
            end
            else begin
                cnt <= cnt + 1'd1;     // 没数满:继续数。中途抖回一致?上面分支清零重数
            end
        end
    end

    // ---------- 第二级:边沿 → 单周期脉冲 ----------
    // 给 key_stable 拍一张"上一拍照片"(读的是旧值——非阻塞赋值的承诺)
    reg key_stable_q;
    always @(posedge clk) begin
        if (!rst_n) key_stable_q <= 1'b1;       // 复位:认为"上一拍是松开"
        else        key_stable_q <= key_stable; // 每个节拍拍一张照片
    end

    // 按下沿(1→0):上一拍还是 1,这一拍已是 0 → 恰好一拍为高
    // 非阻塞赋值保证 key_stable_q 读到的是"旧值"——这就是边沿检测的命根子
    assign tick = key_stable_q & ~key_stable;

endmodule
