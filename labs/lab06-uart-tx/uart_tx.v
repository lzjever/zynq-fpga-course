// ============================================================
// Lab 06 · UART 发送器 — 你的第一个正式状态机
// ============================================================
// 心智模型(先看图再读代码,ch06 §3 的状态图就是本文件):
//   IDLE --start脉冲--> SEND(打起始位+8个数据位)--> STOP(打停止位)--> IDLE
//   三态、每态干什么、沿什么条件跳,代码里逐弧对应,一行不多一行不少
//
// 波特率 = 每秒多少个"位",一个位 = BAUD_DIV 个时钟周期:
//   BAUD_DIV = 434        → 115200 波特(真实串口,给 ILA 看)
//   BAUD_DIV = 5208       → 9600 波特(按一次键,LED 短促一闪)
//   BAUD_DIV = 25_000_000 → 2 波特(一个位 0.5 秒,LED 用 5 秒
//                            肉眼打出 'H' 的完整帧 —— 肉眼 UART)
// 同一份代码,三种现象,全靠 parameter 一处覆盖 —— 这就是参数化的意义。
//
// 端口里 bit_cnt / state 是"观察窗":平时悬空不接,
// ILA 版(lab06_ila_top.v)把它们接到探针上看状态机内部。
module uart_tx #(
    parameter BAUD_DIV = 434            // 一个位 = 多少个 50MHz 时钟(50M/115200≈434)
)(
    input  wire       clk,              // 50MHz(N18)
    input  wire       rst_n,            // 复位,低有效(P14,PL_KEY)
    input  wire       start,            // 单周期脉冲:开始发一帧(接 key_pulse 的 tick)
    input  wire [7:0] data,             // 要发的字节(如 'H' = 8'h48)
    output reg        tx = 1'b1,        // 串口线。注意:空闲态必须为 1(协议规定)
    output wire       busy,             // 1 = 正在发(上层可用它挡住新 start)
    output wire [3:0] bit_cnt,          // 观察窗:当前在打第几个位(0=起始位,1..8=数据位)
    output wire [1:0] state             // 观察窗:状态机当前状态
);

    // ---------- 状态编码:localparam = 只在本模块可见的常量 ----------
    // 综合器会为 state 造 2 个触发器(2 位刚好编码 3 个状态)
    localparam [1:0] S_IDLE = 2'd0,     // 空闲:tx=1,等 start
                     S_SEND = 2'd1,     // 发送:起始位 + 8 个数据位(bit_cnt 0..8)
                     S_STOP = 2'd2;     // 停止位:tx=1 持续一个位时间

    reg [1:0] state_r, next_state;      // 两段式:state_r 是触发器,next_state 是组合逻辑算出的"下一拍去哪"

    // $clog2 = 自动算"装下这个数要几位":BAUD_DIV=434 → 9 位;25_000_000 → 25 位
    // 换波特率参数时位宽自动跟着变,不用手改 —— 三级跳不改一行的秘密
    reg [$clog2(BAUD_DIV)-1:0] baud_cnt = 0;   // 位内计数器:数满 BAUD_DIV 个时钟 = 一个位结束
    reg [3:0]                   bit_cnt_r = 0; // 位计数器:0=起始位,1..8=数据位 0..7(LSB 先行)
    reg [7:0]                   shifter = 8'd0;   // 移位寄存器:把并行字节一位一位"挤"到线上

    // 上电初始值:Xilinx 触发器支持声明处初值(综合成 INIT,上电即生效),
    // 也让任何仿真器不靠复位就能直接跑 —— 本设计不接外部复位键,全靠它
    initial state_r = S_IDLE;

    // ---------- 第一段(时序):状态寄存器 + 数据寄存器 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r   <= S_IDLE;
            tx        <= 1'b1;          // 复位后线上必须是 1(空闲电平)
            baud_cnt  <= 0;
            bit_cnt_r <= 0;
            shifter   <= 8'd0;
        end else begin
            state_r <= next_state;      // 每个时钟沿,跳到组合逻辑算好的下一状态
            // ---- 位内节拍:SEND/STOP 里数时钟,数满清零 ----
            if (state_r == S_IDLE)
                baud_cnt <= 0;          // 空闲态不数,进 SEND 前清零,保证位边界对齐
            else if (baud_cnt == BAUD_DIV-1)
                baud_cnt <= 0;          // 数满 BAUD_DIV 个时钟 = 一个位时间到
            else
                baud_cnt <= baud_cnt + 1'd1;

            // ---- 各状态的具体动作(输出也是"状态的一部分")----
            case (state_r)
                S_IDLE: begin
                    tx <= 1'b1;                     // 空闲电平
                    if (start) begin
                        shifter   <= data;          // 把字节装进移位寄存器
                        bit_cnt_r <= 4'd0;          // 从起始位开始
                        tx        <= 1'b0;          // 起始位:拉低!接收方就靠这个下降沿醒过来
                    end
                end
                S_SEND: begin
                    if (baud_cnt == BAUD_DIV-1) begin  // 一个位时间到了,该换下一个位
                        if (bit_cnt_r == 4'd8) begin
                            tx <= 1'b1;             // 8 个数据位发完 → 拉高就是停止位
                        end else begin
                            bit_cnt_r <= bit_cnt_r + 1'd1;
                            // shifter[0] 是最低位:LSB 先行(协议规定,先发低位)
                            shifter   <= {1'b0, shifter[7:1]};  // 右移:下一位挪到 [0]
                            tx        <= shifter[0];
                        end
                    end
                end
                S_STOP: begin
                    tx <= 1'b1;                      // 停止位 = 回到高电平,持续一个位时间
                    // 停止位时间数满(baud_cnt 回绕后由 next_state 逻辑跳回 IDLE)
                end
                default: tx <= 1'b1;
            endcase
        end
    end

    // ---------- 第二段(组合):次态逻辑 —— 状态图的每条弧对应一行 ----------
    // 图上三条弧:
    //   IDLE --start--> SEND        (按下按键,开始一帧)
    //   SEND --bit_cnt==8 且位时间满--> STOP   (最后一个数据位发完)
    //   STOP --位时间满--> IDLE      (停止位结束,回到空闲)
    always @(*) begin
        case (state_r)
            S_IDLE: next_state = start    ? S_SEND : S_IDLE;
            S_SEND: next_state = (baud_cnt == BAUD_DIV-1 && bit_cnt_r == 4'd8) ? S_STOP : S_SEND;
            S_STOP: next_state = (baud_cnt == BAUD_DIV-1) ? S_IDLE : S_STOP;
            default: next_state = S_IDLE;
        endcase
    end

    // ---------- 观察窗导出 ----------
    assign busy    = (state_r != S_IDLE);   // 不在空闲 = 正忙(顶层可用 busy 挡掉发送中的新 start)
    assign bit_cnt = bit_cnt_r;
    assign state   = state_r;

endmodule
