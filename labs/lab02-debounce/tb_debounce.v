// ============================================================
// Lab 02 · 测试台 — 会抖动的按键 + 三关自动判分
// ============================================================
// 它扮演一颗真实的机械按键:每次按压/释放都注入随机抖动(3~5 次弹跳),
// 然后自动判分:按一次必须恰好出 1 个"一拍宽"的 tick,抖动一个都不许漏过。
// 终端打印 PASS / FAIL;波形里还能亲眼看见"计数器被抖动按在地上清零重数"。
//
// 关 3 用法:改下面的 STABLE 为 50 / 400 各重跑一遍——三跑全 PASS 才算过关。
// (抖动时长全用"时钟拍数"写,不用 ns 写——这样换参数不用改测试台,换板子也一样)
//
// 已知限制(如实告知,不是 bug,也刻意不修):三关验证的是"功能"——滤抖、
// 恰好 1 个一拍宽 tick、换参数仍成立;不验证稳定窗精确到拍。若 DUT 的比较
// 条件差一拍(cnt == STABLE_CYCLES 或 == STABLE_CYCLES-2),本 TB 察觉不到:
// 按压场给了 STABLE+50 拍余量,长毛刺场只比窗口短 20 拍,±1 拍都滑过去。
// 要验精确阈值,需另测"弹跳安分 → key_stable 改判"的拍数并与 STABLE 对账。
`timescale 1ns/1ps

module tb_debounce;

    // ================= 关 3 的旋钮 =================
    // 稳定窗,单位:时钟拍。快跑值 200(真值 1_000_000 的 1/5000,仿真秒级出结果)。
    // 想体验真值慢跑:改成 1_000_000,泡杯茶(约几十秒)。
    localparam integer STABLE = 200;

    // ---------- 造时钟/复位/按键(三要素之①②)----------
    reg  clk   = 1'b0;
    reg  rst_n = 1'b0;
    reg  key_n = 1'b1;        // 松开(注意极性:按下 = 0,与 P14 一致)
    wire tick;

    // ---------- 被测电路:例化时拧小参数(关 3 的另一半)----------
    debounce #(.STABLE_CYCLES(STABLE)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .key_n (key_n),
        .tick  (tick)
    );

    always #10 clk = ~clk;    // 50MHz,与板上 N18 同款

    // ================= 观察员(自动判分)=================
    integer tick_total = 0;   // 全场 tick 总数
    integer tick_last  = 0;   // 每场开始前的快照
    integer run_len    = 0;   // tick 连续为高的拍数(查脉宽)
    integer ks_falls   = 0;   // key_stable 下沿总数(关 1:抖动漏网计数)
    integer errors     = 0;   // 违例计数
    reg    ks_q = 1'b1;      // key_stable 的"上一拍照片"

    always @(posedge clk) if (rst_n) begin
        // tick 观察:下游触发器视角,数脉冲个数
        if (tick) begin
            run_len = run_len + 1;
            if (run_len > 1) begin          // 连续第 2 拍还是高 → 脉宽超了
                errors = errors + 1;
                $display("[FAIL 关2] tick 连续 %0d 拍为高(必须恰好 1 拍)", run_len);
            end
            tick_total = tick_total + 1;
        end
        else
            run_len = 0;

        // key_stable 观察:仿真特权——直接看被测电路内部(所以需求书规定了信号名)
        ks_q <= dut.key_stable;
        if (ks_q & ~dut.key_stable)         // 检测到 1→0 下沿(晚一拍,不影响计数)
            ks_falls = ks_falls + 1;
    end

    // ================= 抖动演员 =================
    // 按一次"带抖动的按压":先弹跳 n_bounce 次(每次闭合/断开 1~3 拍),再稳定按住
    task automatic do_press(input integer n_bounce);
        integer i;
        begin
            tick_last = tick_total;
            for (i = 0; i < n_bounce; i = i + 1) begin
                key_n = 1'b0;                              // 触点闭合
                repeat (({$random} % 3) + 1) @(posedge clk);
                key_n = 1'b1;                              // 又弹开
                repeat (({$random} % 3) + 1) @(posedge clk);
            end
            key_n = 1'b0;                                  // 抖完了,稳定按住
            repeat (STABLE + 50) @(posedge clk);           // 给足稳定窗 + 余量
            #1;                                            // 让观察员把账记完(避开同沿赛跑)
            if (tick_total - tick_last == 1)
                $display("[PASS 关2] 一次按压(含 %0d 次抖动)→ 恰好 1 个 tick", n_bounce);
            else begin
                errors = errors + 1;
                $display("[FAIL 关2] 一次按压 → %0d 个 tick(应恰好 1 个)", tick_total - tick_last);
            end
        end
    endtask

    // 按一次"带抖动的释放":释放也该被消抖,且不许报 tick
    task automatic do_release(input integer n_bounce);
        integer i;
        begin
            tick_last = tick_total;
            for (i = 0; i < n_bounce; i = i + 1) begin
                key_n = 1'b1;
                repeat (({$random} % 3) + 1) @(posedge clk);
                key_n = 1'b0;
                repeat (({$random} % 3) + 1) @(posedge clk);
            end
            key_n = 1'b1;
            repeat (STABLE + 50) @(posedge clk);
            #1;
            if (tick_total - tick_last == 0)
                $display("[PASS] 一次释放(含 %0d 次抖动)→ 0 个 tick(松开不该报)", n_bounce);
            else begin
                errors = errors + 1;
                $display("[FAIL] 释放出 %0d 个 tick(应 0)", tick_total - tick_last);
            end
        end
    endtask

    // ================= 总导演(三要素之③:$finish)=================
    integer presses = 0;
    initial begin
        repeat (10) @(posedge clk);
        rst_n = 1'b1;

        // 第 1 场:常规按压 ×5,每次 3~5 次随机抖动
        presses = 5;
        repeat (presses) begin
            do_press(({$random} % 3) + 3);
            do_release(({$random} % 3) + 3);
        end

        // 第 2 场:长毛刺刁难——按住 0.9×稳定窗 再弹开,必须一个都不报
        tick_last = tick_total;
        key_n = 1'b0;
        repeat (STABLE - 20) @(posedge clk);
        key_n = 1'b1;
        repeat (STABLE) @(posedge clk);
        #1;
        if (tick_total == tick_last)
            $display("[PASS] 长毛刺(差 20 拍数满)→ 0 个 tick,没上当");
        else begin
            errors = errors + 1;
            $display("[FAIL] 长毛刺被骗,出了 %0d 个 tick", tick_total - tick_last);
        end

        // 第 3 场:刁难之后再正常按一次,证明电路没被搞坏
        do_press(4);
        do_release(4);
        presses = presses + 1;

        // ================= 结算(三关对账)=================
        $display("==============================================");
        if (ks_falls == presses)
            $display("[PASS 关1] %0d 次按压,稳定电平恰好 %0d 个干净下沿(抖动零漏网)",
                     presses, ks_falls);
        else begin
            errors = errors + 1;
            $display("[FAIL 关1] 下沿 %0d 个 ≠ 按压 %0d 次:有抖动漏网,电平不干净",
                     ks_falls, presses);
        end
        if (errors == 0 && tick_total == presses)
            $display("--- PASS:关1+关2 全过(按 %0d 次 → %0d 个 tick)---", presses, tick_total);
        else
            $display("--- FAIL:errors=%0d,tick=%0d(按压 %0d 次)---", errors, tick_total, presses);
        $display("[提醒 关3] 把 STABLE 改成 50 / 400 各重跑一遍,三跑全 PASS 才算数");
        $display("==============================================");
        $finish;
    end

endmodule
