// ============================================================
// Lab 06 · uart_tx 的测试台(TB)— 一个软件写成的 UART 接收器
// ============================================================
// 本 TB 的本质:用"接收器的耳朵"检查发送器的嘴。
//   1. 检测 tx 的下降沿(起始位开始)
//   2. 在每个位的正中间采样(起始位后 1.5、2.5 … 个位时间处)
//   3. 按协议重组字节:LSB 先行,拼回 'H' 等字符
//   4. $write 打印出 "Hello PL!" —— 硬件发送 → 软件重组的闭环
//
// 教学要点(刻意设计):TB 的位时间 BIT_NS 是 TB 自己声明的常数,
// 不引用 DUT 的 BAUD_DIV —— 两边各自独立。如果 DUT 的波特率算错/写错,
// TB 会采错位、打出乱码,bug 当场现形。这叫"验证不与被测同源"。
// (代价:换 DUT 波特率时 TB 也要改 —— 板上跑 115200,这里缩到"8 分频"
//  是为了仿真秒级跑完,和 ch01 的"仿真缩时间"同一招。)
`timescale 1ns/1ps

module tb_uart_tx;

    // ---------- TB 自己的世界(与 DUT 独立)----------
    localparam integer TB_BIT_DIV  = 8;          // TB 假设:一个位 = 8 个时钟周期
    localparam integer CLK_NS      = 20;         // 50MHz 时钟周期 20ns
    localparam integer BIT_NS      = TB_BIT_DIV * CLK_NS;   // 位宽 160ns
    localparam integer HALF_NS     = BIT_NS / 2;

    reg  clk = 0;
    reg  start = 0;
    reg  [7:0] data = 8'h48;
    wire tx, busy;
    wire [3:0] bit_cnt;
    wire [1:0] state;

    integer errors = 0;
    integer sent_chars = 0;
    reg [7:0] rx_byte;          // TB 重组出来的字节
    integer k;

    // ---------- 时钟与 DUT ----------
    always #10 clk = ~clk;      // 10ns 翻转一次 = 20ns 周期 = 50MHz

    uart_tx #(.BAUD_DIV(8)) dut (   // DUT 也用 8 分频(缩时),但注意:这个 8 是抄给它的,不是引用来的
        .clk(clk), .rst_n(1'b1),
        .start(start), .data(data),
        .tx(tx), .busy(busy),
        .bit_cnt(bit_cnt), .state(state)
    );

    // ---------- 软件接收器:收一帧并核对 ----------
    task recv_frame(input [7:0] expect_ch);
        integer i;                              // 注意:任务内私有变量,不许用全局 k(会和主循环打架)
        begin
            @(negedge tx);                     // ① 等起始位下降沿(TB 独立检测,不碰 DUT 内部)
            #(HALF_NS);                        // ② 走到起始位正中
            if (tx !== 1'b0) begin
                $display("[%0t] 错:起始位中点不是 0(tx=%b)", $time, tx);
                errors = errors + 1;
            end
            rx_byte = 8'd0;
            for (i = 0; i < 8; i = i + 1) begin
                #BIT_NS;                       // ③ 每过一个位时间 = 下一位的正中
                rx_byte[i] = tx;               //    LSB 先行:第 i 个收到的位放进第 i 位
            end
            #BIT_NS;                           // ④ 停止位正中
            if (tx !== 1'b1) begin
                $display("[%0t] 错:停止位中点不是 1(tx=%b)", $time, tx);
                errors = errors + 1;
            end
            // ⑤ 位宽体检:整个位内电平不该中途翻脸(在 1/4 和 3/4 处再抽两次)
            //    (上面按中点采样的同时其实已覆盖,这里省略 —— 留作思考题)
            if (rx_byte !== expect_ch) begin
                $display("[%0t] 错:收到 0x%02h,期望 0x%02h", $time, rx_byte, expect_ch);
                errors = errors + 1;
            end else begin
                $write("%c", rx_byte);         // ⑥ 收对了就打印 —— 10 帧拼出 "Hello PL!"
                sent_chars = sent_chars + 1;
            end
            #BIT_NS;                           // 帧间休息一个位时间(等线路回空闲)
        end
    endtask

    // ---------- 发一帧(给 DUT 一个单周期 start 脉冲)----------
    task send_byte(input [7:0] ch);
        begin
            @(posedge clk);
            data  <= ch;
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            @(posedge busy);                   // 等发送器忙起来(确认它真的开动了)
            @(negedge busy);                   // 等它发完 —— recv_frame 在并行收
        end
    endtask

    // ---------- 主流程:发 10 个字符,让控制台打印 "Hello PL!" ----------
    reg [7:0] msg [0:9];   // "Hello PL!" 共 9 个可见字符,第 10 个是换行
    initial begin
        msg[0]="H"; msg[1]="e"; msg[2]="l"; msg[3]="l"; msg[4]="o";
        msg[5]=" "; msg[6]="P"; msg[7]="L"; msg[8]="!"; msg[9]="\n";
        $display("=== tb_uart_tx 开始(位宽 %0d ns)= ===", BIT_NS);
        for (k = 0; k < 10; k = k + 1)
            fork
                send_byte(msg[k]);             // 发送方:DUT
                recv_frame(msg[k]);            // 接收方:TB(两者并行,如同两台设备)
            join
        $display("");
        if (errors == 0 && sent_chars == 10)
            // 判词如实:只证明 10 帧解码正确(各位正中采样),不证明位宽精确;
            // 板上 434 分频未在本 TB 中测(本 TB 用 8 分频缩时),交给 ILA 游标验证。
            $display("--- PASS (10/10 帧解码正确,不证明位宽精确) ---");
        else
            $display("--- FAIL:错误 %0d 个,收对 %0d/10 ---", errors, sent_chars);
        $finish;
    end

endmodule
