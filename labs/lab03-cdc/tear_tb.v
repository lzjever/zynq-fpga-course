// ============================================================
// Lab 03 · 撕裂仿真 TB —— 显式延迟注入版(ch03 配套)
// ============================================================
// 核心思想:理想 RTL 仿真里,非阻塞赋值让一个计数器的各位
// "原子地"一起更新,零延迟导线上永远看不到撕裂。所以要看清
// 撕裂,必须把真实世界的"布线偏斜"(各位导线不等长)手工
// 注入进来——本 TB 给每一位接了一根不等长的延迟线。
//
// 三路对照,同一个采样时钟 clk_dst:
//   ① bin_skew  二进制 + 各位延迟 #4/#3/#2/#1  → 会被撕(主角)
//   ② gray_skew 格雷码 + 同样的延迟            → 撕不动(对照)
//   ③ bin_clean 二进制 + 零延迟(理想 RTL)     → 永远干净(假象)
//
// 跑法见 README:XSIM 三步舞,或 iverilog 一行命令。
`timescale 1ns/1ps

module tear_tb;

    // ---------- 两个"互不相认"的时钟 ----------
    // 同样标称 50MHz,周期故意差 0.3ns:两个独立晶振永远对不齐,
    // 采样沿会在源时钟周期里缓缓扫动(每拍相对移 0.3ns,
    // 约 67 拍扫完一圈)——总有一天正好落进撕裂窗口。
    reg clk_src = 1'b0;
    reg clk_dst = 1'b0;
    always #10.00 clk_src = ~clk_src;    // 周期 20.00ns
    always #9.85  clk_dst = ~clk_dst;    // 周期 19.70ns

    // ---------- 被测电路 ----------
    wire [3:0] bin_q, gray_q;
    tear_demo u_dut (
        .clk_src (clk_src),
        .bin_q   (bin_q),
        .gray_q  (gray_q)
    );

    // ---------- ① 延迟注入:给每一位接一根"不等长的导线" ----------
    // 真实芯片里,计数器各位到采样触发器的布线长短不一(偏斜)。
    // 延迟故意"反着排":最高位最短、最低位最长。
    // 于是 7(0111)→8(1000) 的路上,采样沿会先看到高位已变、
    // 低位未变 → 抓到 1111 = 15——一个比 7 和 8 都离谱的撕裂值。
    wire [3:0] bin_skew, gray_skew;
    assign #4 bin_skew[0] = bin_q[0];    // 最低位:绕最远的导线
    assign #3 bin_skew[1] = bin_q[1];
    assign #2 bin_skew[2] = bin_q[2];
    assign #1 bin_skew[3] = bin_q[3];    // 最高位:抄近道

    assign #4 gray_skew[0] = gray_q[0];  // 格雷码吃完全相同的延迟
    assign #3 gray_skew[1] = gray_q[1];
    assign #2 gray_skew[2] = gray_q[2];
    assign #1 gray_skew[3] = gray_q[3];

    // ---------- ③ 零延迟对照(理想 RTL 的样子) ----------
    wire [3:0] bin_clean = bin_q;        // 一捆等长导线 = 没有导线

    // ---------- 采样:clk_dst 域的三排触发器 ----------
    reg [3:0] s_bin, s_gray, s_binC;     // 本拍样本
    reg [3:0] p_bin, p_gray, p_binC;     // 上一拍样本
    always @(posedge clk_dst) begin
        s_bin  <= bin_skew;
        s_gray <= gray_skew;
        s_binC <= bin_clean;
        p_bin  <= s_bin;
        p_gray <= s_gray;
        p_binC <= s_binC;
    end

    // ---------- 撕裂检测 ----------
    // 判据:合法样本 = 上一拍值 或 上一拍值+1(16 进制自然回绕)。
    // 依据:计数器每 40ns 才 +1(tear_demo 的 pace),而相邻两个
    // 采样沿各自"看到"的窗口(含 3ns 偏斜)总共只有 22.7ns 宽
    // ——窗口装不下两次 +1,所以正常样本至多前进 1 步。
    integer tears_skew = 0;   // ① 计数:该撕的(期望 > 0)
    integer gray_viol  = 0;   // ② 计数:不该撕的(期望 = 0)
    integer tears_clean= 0;   // ③ 计数:不该撕的(期望 = 0)
    integer samples    = 0;
    integer edge_cnt   = 0;
    reg [3:0] diff;

    always @(posedge clk_dst) begin
        edge_cnt = edge_cnt + 1;
        if (edge_cnt >= 3) begin              // 攒够两拍样本再判
            samples = samples + 1;
            // ① 二进制 + 延迟注入:只允许 p_bin 或 p_bin+1
            if (s_bin !== p_bin && s_bin !== p_bin + 1'd1) begin
                tears_skew = tears_skew + 1;
                if (tears_skew <= 5)          // 只细报前 5 发,后面数数
                    $display("[%4t] 撕裂! 上一拍 %0d → 本拍 %0d   (合法值只有 %0d 或 %0d)",
                             $time, p_bin, s_bin, p_bin, p_bin + 1'd1);
            end
            // ③ 二进制 + 零延迟:同样判据,应当永远沉默
            if (s_binC !== p_binC && s_binC !== p_binC + 1'd1) begin
                tears_clean = tears_clean + 1;
                $display("[%4t] 异常:零延迟对照也撕了(%0d → %0d)?!",
                         $time, p_binC, s_binC);
            end
            // ② 格雷码 + 延迟注入:连续样本最多只许差 1 位
            diff = s_gray ^ p_gray;
            if (diff[0] + diff[1] + diff[2] + diff[3] > 1) begin
                gray_viol = gray_viol + 1;
                $display("[%4t] 异常:格雷码也撕了(%b → %b)?!",
                         $time, p_gray, s_gray);
            end
        end
    end

    // ---------- 盲区演示的四拍小链条(force X 用) ----------
    reg blind_d  = 1'b1;
    reg blind_q1 = 1'b0;
    reg blind_q2 = 1'b0;
    always @(posedge clk_dst) begin
        blind_q1 <= blind_d;
        blind_q2 <= blind_q1;
    end

    // ---------- 总导演 ----------
    initial begin
        $timeformat(-9, 0, " ns", 10);   // 统一按纳秒打印时间
        // 阶段一:撕裂大赛,跑 40us(约 1000 次计数递增)
        #40_000;

        $display("===================================================");
        $display(" 阶段一 · 撕裂统计(共 %0d 个有效采样)", samples);
        $display("   ① 二进制 + 延迟注入 : %0d 个撕裂样本   ← 该撕的,撕了", tears_skew);
        $display("   ② 格雷码 + 延迟注入 : %0d 个撕裂样本   ← 对照组,纹丝不动", gray_viol);
        $display("   ③ 二进制 + 零延迟   : %0d 个撕裂样本   ← 理想仿真的假象", tears_clean);
        $display("===================================================");

        // 阶段二:仿真器的盲区——force 1'bx 演不出"物理收敛"
        // 强制第一拍输出为 X,模拟"第一拍触发器亚稳,输出悬在中间"。
        // 物理世界:这点中间电压会在几 ns 内倒向 0 或 1(收敛);
        // 四态仿真:X 进 X 出,第二拍只会把 X 原样传染下去。
        force blind_q1 = 1'bx;
        @(posedge clk_dst);   // 第二拍:采样到 X
        @(posedge clk_dst);   // 第三拍:X 仍在传染
        #1;                   // 让 NBA 落定再读
        $display(" 盲区演示: force q1 = X 两拍后, q2 = %b", blind_q2);
        $display(" (物理世界会收敛到 0/1;四态仿真永远 X —— 安全性仿真不出来)");
        release blind_q1;

        // ---------- 收卷 ----------
        if (tears_skew > 0 && gray_viol == 0 && tears_clean == 0)
            $display(" PASS:撕裂已被延迟注入复现;格雷码与理想对照干净。");
        else
            $display(" FAIL:对照路出现了不该有的值,检查 TB。");
        $finish;
    end

    // 波形观察指引(XSIM GUI / GTKWave 通用):
    // ◆ 截图点 1:bin_skew[3:0] —— 找一次 7→8:四位不同时跳,高位先走
    // ◆ 截图点 2:s_bin 撕裂瞬间 —— 上一拍 7、本拍 15(对齐 console 首发撕裂时刻)
    // ◆ 截图点 3:gray_skew 同一时刻 —— 只有 1 位在跳,采样永远干净

endmodule
