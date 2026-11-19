// ============================================================
// Lab 07 · UART 接收器 — 你自己写的第二台状态机
// ============================================================
// (本文件是"先写后看"的参考实现:请先按课程页 §3 的需求书自己写,
//  卡壳 45 分钟再按提示阶梯逐级展开,最后才回到这里对差异。)
//
// 与发送器的对称关系(建议对照 uart_tx.v 读):
//   TX:知道何时开始(start 脉冲)→ 主动铺时间轴
//   RX:不知道对方何时说话    → 等下降沿,然后"跟跑"
// 跟跑的关键:中点采样。起始沿对表后,把采样时刻放在每个位的正中间
// (1.5、2.5、… 个位时间处),这样即使双方的时钟略有偏差,只要一位
// 时间内偏不过半,就永远采在"电平最稳的地带"。
//
// 三态,与 TX 同构:
//   IDLE --rx下降沿--> RECV(半位验起始 + 逐位中点采样 8 个数据位)--> STOP(中点验停止位)--> IDLE
module uart_rx #(
    parameter BAUD_DIV = 434               // 与 TX 同一个约定(注意:双方必须一致)
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,                  // 串口输入线(自环时来自杜邦线另一头的 TX)
    output reg  [7:0] rx_data = 8'd0,      // 收到的字节(仅在 rx_done 那一拍更新)
    output reg        rx_done = 1'b0,      // 单周期脉冲:一个字节完整收到且停止位合法
    output wire       frame_err,           // 单周期脉冲:停止位位置读到 0,帧不可信,不提交(rx_done 不发)
    output wire [3:0] bit_cnt,             // 观察窗:0=验起始位,1..8=采数据位 0..7
    output wire [1:0] state                // 观察窗:状态机当前状态
);
    localparam [1:0] S_IDLE = 2'd0,        // 等起始沿(线空闲恒 1)
                     S_RECV = 2'd1,        // 半位验起始 + 8 个数据位中点采样
                     S_STOP = 2'd2;        // 停止位中点验收

    reg [1:0] state_r, next_state;
    reg [$clog2(BAUD_DIV)-1:0] baud_cnt = 0;   // 位内计数器(和 TX 同款,位宽自动适配)
    reg [3:0]                   bit_cnt_r = 0; // 0=起始位,1..8=数据位 d0..d7
    reg [7:0]                   rx_shift = 8'd0;  // 右移拼装:先收到的位最后落在低位 → 自然形成 LSB 先行

    // 上电初始值(同 uart_tx:综合成 Xilinx INIT,仿真器不靠复位也能跑)
    initial state_r = S_IDLE;

    // ---------- 第 0 级:打两拍同步(ch03 的保险,异步串口线是"野信号"本尊) ----------
    reg [1:0] sync = 2'b11;                    // 初值 = 空闲电平 1(声明处初值,上电即生效)
    always @(posedge clk)
        if (!rst_n) sync <= 2'b11;             // 空闲电平是 1
        else       sync <= {sync[0], rx};
    wire rx_s = sync[1];

    // ---------- 起始沿检测:旧值 1、新值 0 = 对方开口了 ----------
    reg rx_s_q = 1'b1;
    always @(posedge clk)
        if (!rst_n) rx_s_q <= 1'b1;
        else        rx_s_q <= rx_s;
    wire start_fall = rx_s_q & ~rx_s;          // 单周期宽的下降沿标志

    // ---------- 时序段:寄存器 + 各状态的数据动作 ----------
    always @(posedge clk) begin
        if (!rst_n) begin
            state_r   <= S_IDLE;
            baud_cnt  <= 0;
            bit_cnt_r <= 0;
            rx_shift  <= 8'd0;
            rx_data   <= 8'd0;
            rx_done   <= 1'b0;
        end else begin
            state_r <= next_state;
            rx_done <= 1'b0;                    // 默认不发脉冲(下面那拍才置 1)

            // 位内节拍:IDLE 不数;RECV 的第一次采样在"半位"处(到起始位正中),
            // 之后每满一个整位采一次 —— 这就是中点采样方案的计数实现
            if (state_r == S_IDLE)
                baud_cnt <= 0;
            else if (baud_cnt == (bit_cnt_r == 0 ? BAUD_DIV/2 - 1 : BAUD_DIV - 1))
                baud_cnt <= 0;
            else
                baud_cnt <= baud_cnt + 1'd1;

            case (state_r)
                S_IDLE: begin
                    if (start_fall)
                        bit_cnt_r <= 4'd0;       // 进 RECV 前归零(上一帧或假起始残留都清掉)
                end
                S_RECV: begin
                    if (baud_cnt == (bit_cnt_r == 0 ? BAUD_DIV/2 - 1 : BAUD_DIV - 1)) begin
                        if (bit_cnt_r == 0) begin
                            // 起始位正中:线还是 0 吗?是 → 真起始;否 → 刚才那记下降沿是毛刺,回睡觉
                            bit_cnt_r <= 4'd1;
                        end else begin
                            // 数据位正中:采!新位从高端进,右移 8 次后最先到的落在 [0] → LSB 先行自动成立
                            rx_shift  <= {rx_s, rx_shift[7:1]};
                            bit_cnt_r <= bit_cnt_r + 1'd1;
                        end
                    end
                end
                S_STOP: begin
                    if (baud_cnt == BAUD_DIV - 1) begin     // 停止位正中
                        rx_data <= rx_shift;                 // 拼好的字节转正
                        rx_done <= rx_s;                     // 停止位=1 → 有效;=0 → rx_done 不发(frame_err 发)
                    end
                end
                default: ;                                  // IDLE:什么都不动,等沿
            endcase
        end
    end

    // ---------- 组合段:次态逻辑(状态图每弧一行) ----------
    //   IDLE --start_fall--> RECV
    //   RECV --半位到且线已回高--> IDLE   (假起始位:毛刺,不算数)
    //   RECV --bit_cnt==8 且位满--> STOP  (8 个数据位采完)
    //   STOP --位满--> IDLE              (验收完成,无论成败)
    always @(*) begin
        case (state_r)
            S_IDLE: next_state = start_fall ? S_RECV : S_IDLE;
            S_RECV: if (baud_cnt == BAUD_DIV/2 - 1 && bit_cnt_r == 0 && rx_s)
                        next_state = S_IDLE;                        // 假起始
                    else if (baud_cnt == BAUD_DIV-1 && bit_cnt_r == 4'd8)
                        next_state = S_STOP;                        // 数据收齐
                    else
                        next_state = S_RECV;
            S_STOP: next_state = (baud_cnt == BAUD_DIV-1) ? S_IDLE : S_STOP;
            default: next_state = S_IDLE;
        endcase
    end

    // 帧错误 = 停止位正中读到的却是 0(双方节拍彻底对不上 / 线被拔了半截)
    reg err_r = 1'b0;
    always @(posedge clk)
        if (!rst_n) err_r <= 1'b0;
        else        err_r <= (state_r == S_STOP) && (baud_cnt == BAUD_DIV-1) && !rx_s;
    assign frame_err = err_r;

    assign bit_cnt = bit_cnt_r;
    assign state   = state_r;

endmodule
