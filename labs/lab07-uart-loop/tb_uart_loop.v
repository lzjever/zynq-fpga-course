// ============================================================
// Lab 07 · 自环回测试台 — 两场考试
// ============================================================
// 考试 1(链路):杜邦线在仿真里就是一根 wire —— 把 tx_pad 和 rx_pad
//   短接,按 10 次"发射按钮",每次都必须收到 'H'、match=1、LED 翻转。
// 考试 2(浸泡/soak):绕开 TX,TB 亲自扮演发送器,给 uart_rx 连灌
//   256 个随机字节,一个都不许错 —— 这才是 RX 的独立压力测试
//   (自环测不出波特率错,因为 TX/RX 同源同错;soak 的位时序由 TB
//   独立生成,能多抓一类错)。
`timescale 1ns/1ps

module tb_uart_loop;

    // ---------- 时间参数(缩时:一个位 8 个时钟,消抖 40 个时钟) ----------
    localparam integer BIT_NS  = 8 * 20;      // 位宽 160ns(板上是 8680ns,道理相同)
    localparam integer HOLD_NS = 40 * 20 * 3; // 按键按住时间 > 消抖窗口

    reg  clk = 0;
    reg  key = 1;
    always #10 clk = ~clk;

    // ---------- 被测 1:自环顶层(tx_pad 和 rx_pad 之间的 wire 就是杜邦线) ----------
    wire tx_pad, rx_pad;
    wire led, dbg_done, dbg_match;
    wire [7:0] dbg_data;

    loop_top #(.BAUD_DIV(8), .STABLE_CYCLES(40), .CHAR(8'h48)) dut (
        .clk(clk), .key(key),
        .rx_pad(rx_pad), .tx_pad(tx_pad),
        .led(led),
        .dbg_done(dbg_done), .dbg_data(dbg_data), .dbg_match(dbg_match)
    );
    assign rx_pad = tx_pad;        // ← 杜邦线:一行 wire,把"接线即外设"演到极致

    // ---------- 被测 2:裸 uart_rx(soak 用,TB 直接驱动它的 rx) ----------
    reg  rx2 = 1;
    wire [7:0] soak_data;
    wire soak_done, soak_err;
    uart_rx #(.BAUD_DIV(8)) u_soak (
        .clk(clk), .rst_n(1'b1),
        .rx(rx2),
        .rx_data(soak_data), .rx_done(soak_done), .frame_err(soak_err),
        .bit_cnt(), .state()
    );

    integer errors = 0;
    integer loop_ok = 0, soak_ok = 0;
    integer i;
    reg [7:0] byte_i;
    reg led_was;

    // ---------- 按一次"发射按钮" ----------
    task press_key;
        begin
            key = 0; #(HOLD_NS);
            key = 1; #(HOLD_NS);
        end
    endtask

    // ---------- TB 当发送器:往 u_soak 的 rx 线上铺一帧 ----------
    task drive_byte(input [7:0] ch);
        integer k;
        begin
            rx2 = 1'b0; #(BIT_NS);                       // 起始位
            for (k = 0; k < 8; k = k + 1) begin
                rx2 = ch[k]; #(BIT_NS);                  // LSB 先行
            end
            rx2 = 1'b1; #(BIT_NS);                       // 停止位
        end
    endtask

    // ---------- 考试 1:自环 10 次 ----------
    task loop_once;
        begin
            led_was = led;
            press_key;
            fork: wait_rx
                begin @(posedge dbg_done); end           // 收到一帧
                begin #(50_000);                          // 超时 50µs(缩时下的一帧只有 1.6µs)
                        $display("[%0t] 错:按了键,没收到帧", $time);
                        errors = errors + 1; end
            join_any
            disable wait_rx;
            #100;
            if (dbg_data !== 8'h48) begin
                $display("[%0t] 错:收到 0x%02h,期望 0x48", $time, dbg_data);
                errors = errors + 1;
            end else if (!dbg_match) begin
                $display("[%0t] 错:match=0", $time);
                errors = errors + 1;
            end else if (led === led_was) begin
                $display("[%0t] 错:收到了但 LED 没翻转", $time);
                errors = errors + 1;
            end else
                loop_ok = loop_ok + 1;
        end
    endtask

    initial begin
        $display("=== tb_uart_loop 开始(位宽 %0d ns)=== ", BIT_NS);
        #(HOLD_NS*2);                       // 上电稳定

        for (i = 0; i < 10; i = i + 1) loop_once;
        $display("考试1 自环回:%0d/10 通过", loop_ok);

        // ---------- 考试 2:256 个随机字节浸泡 ----------
        for (i = 0; i < 256; i = i + 1) begin
            byte_i = $random;               // 随机字节(截到低 8 位)
            fork: wait_soak
                begin @(posedge soak_done); end
                begin #(50_000);
                        $display("[%0t] 错:字节 %0d 无响应", $time, i);
                        errors = errors + 1; end
            join_any
            disable wait_soak;
            #1;   // 等 rx_data 的非阻塞赋值落定(和 rx_done 同沿更新,避一步采样竞争)
            if (soak_data === byte_i) soak_ok = soak_ok + 1;
            else begin
                $display("[%0t] 错:第 %0d 个字节,收到 %02h 期望 %02h",
                          $time, i, soak_data, byte_i);
                errors = errors + 1;
            end
            #200;                           // 帧间休息
        end
        $display("考试2 浸泡:%0d/256 字节正确", soak_ok);

        if (errors == 0 && loop_ok == 10 && soak_ok == 256)
            $display("--- PASS(自环 10/10,浸泡 256/256)---");
        else
            $display("--- FAIL:错误 %0d 个 ---", errors);
        $finish;
    end

endmodule
