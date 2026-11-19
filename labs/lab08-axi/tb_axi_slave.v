// ============================================================
// Lab 08 · TB 假扮 ARM — 用任务封装一次 devmem
// ============================================================
// 本文件是"写给仿真器的软件"(testbench,复习 ch01):
//   它不是电路,不会被综合,所以可以用 initial / # 延时 / task / while。
//
// 核心 idea:把 AXI 握手封成两个 task——
//   axi_write(addr, data) ≈ devmem 0x40000000 32 data(写的半边)
//   axi_read(addr, data)  ≈ devmem 0x40000000(读的半边)
// 调用它们时,你不用再想通道和握手——这正是 ch09 里真 ARM 的视角:
// 对软件来说,总线只是"往一个地址写了个数"。
//
// 采样时机说明(重要,防"TB 与 DUT 同源"盲区):
//   task 在 posedge 醒来后立刻用阻塞读读握手线——DUT 全用 <= 更新,
//   同一时刻读到的必然是"这一沿之前"的稳定值,恰好等于成交判定条件。
`timescale 1ns / 1ps
module tb_axi_slave;

    // ---------- 时钟与复位 ----------
    reg  aclk = 1'b0;
    reg  aresetn = 1'b0;
    always #10 aclk = ~aclk;              // 50MHz,周期 20ns,与全书一致

    // ---------- 主机侧信号(TB 全权驱动) ----------
    reg  [3:0]  s_axi_awaddr = 4'd0;
    reg         s_axi_awvalid = 1'b0;
    reg  [31:0] s_axi_wdata  = 32'd0;
    reg         s_axi_wvalid = 1'b0;
    reg         s_axi_bready = 1'b0;
    reg  [3:0]  s_axi_araddr = 4'd0;
    reg         s_axi_arvalid = 1'b0;
    reg         s_axi_rready = 1'b0;

    // ---------- 从机侧信号(观察) ----------
    wire        s_axi_awready, s_axi_wready, s_axi_bvalid;
    wire [1:0]  s_axi_bresp;
    wire        s_axi_arready, s_axi_rvalid;
    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire [31:0] knob;

    // ---------- 例化被测电路(DUT) ----------
    axi_lite_slave #(.ADDR_W(4)) dut (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(s_axi_awaddr), .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),   .s_axi_wvalid(s_axi_wvalid),   .s_axi_wready(s_axi_wready),
        .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),   .s_axi_bresp(s_axi_bresp),
        .s_axi_araddr(s_axi_araddr), .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
        .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready),   .s_axi_rresp(s_axi_rresp),
        .s_axi_rdata(s_axi_rdata),
        .knob(knob)
    );

    // ---------- 记分牌 ----------
    integer errors = 0;
    integer checks = 0;

    task check(input [31:0] got, input [31:0] want, input [255:0] name);
        begin
            checks = checks + 1;
            if (got !== want) begin
                errors = errors + 1;
                $display("[%0t ns] [FAIL] %0s: got %h, want %h", $time, name, got, want);
            end else
                $display("[%0t ns] [ OK ] %0s = %h", $time, name, got);
        end
    endtask

    // ---------- 复位 task(全书 TB 范式) ----------
    task do_reset;
        begin
            aresetn <= 1'b0;
            repeat (5) @(posedge aclk);
            aresetn <= 1'b1;
            @(posedge aclk);
        end
    endtask

    // ============================================================
    // ★ 假 ARM 的两只手:axi_write / axi_read
    // ============================================================
    // 写一笔:同时举 AW + W(协议也允许先后举),各自成交后撤;
    //          然后等 B 回执,检查响应码。≈ devmem <addr> 32 <data>
    task axi_write(input [3:0] addr, input [31:0] data);
        reg aw_done, w_done;
        begin
            aw_done = 1'b0;
            w_done  = 1'b0;
            @(posedge aclk);
            s_axi_awvalid <= 1'b1;         // 举单子:地址
            s_axi_awaddr  <= addr;
            s_axi_wvalid  <= 1'b1;         // 举单子:数据(与地址同拍举,最常见)
            s_axi_wdata   <= data;
            s_axi_bready  <= 1'b1;         // 随时可以收回执
            // 逐拍等两个握手分别成交(valid&&ready 在同一拍为 1)
            while (!aw_done || !w_done) begin
                @(posedge aclk);
                if (s_axi_awvalid && s_axi_awready) aw_done = 1'b1;
                if (s_axi_wvalid  && s_axi_wready ) w_done  = 1'b1;
                if (aw_done) s_axi_awvalid <= 1'b0;   // 成交拍之后才准撤(铁律:不得提前撤)
                if (w_done)  s_axi_wvalid  <= 1'b0;
            end
            // 等写响应 B:从机举 bvalid,本拍成交
            while (s_axi_bvalid !== 1'b1) @(posedge aclk);
            check(s_axi_bresp, 2'b00, "写响应 bresp=OKAY");
            s_axi_bready <= 1'b0;
        end
    endtask

    // 读一笔:举 AR,成交后从机举 R 带数据;成交拍把 rdata 收走。
    //          ≈ devmem <addr>(读到的是寄存器现值)
    task axi_read(input [3:0] addr, output [31:0] data);
        begin
            @(posedge aclk);
            s_axi_arvalid <= 1'b1;
            s_axi_araddr  <= addr;
            s_axi_rready  <= 1'b1;
            while (s_axi_rvalid !== 1'b1) @(posedge aclk);  // 数据来了
            data = s_axi_rdata;   // rvalid 期间数据保证稳定,现在收走
            check(s_axi_rresp, 2'b00, "读响应 rresp=OKAY");
            s_axi_arvalid <= 1'b0;
            s_axi_rready  <= 1'b0;
        end
    endtask

    // ============================================================
    // 剧本:三组实验
    // ============================================================
    reg [31:0] rdata;
    initial begin
        $timeformat(-9, 0, " ns", 10);
        $dumpfile("tb_axi_slave.vcd");
        $dumpvars(0, tb_axi_slave);
        $display("=== Lab08 TB 假扮 ARM:写 0x55,读回验证 ===");

        do_reset;

        // 实验 1 · 写 0x55 → 旋钮立刻变,读回同一个值(写=存值,读=回值)
        axi_write(4'h0, 32'h0000_0055);
        check(knob, 32'h0000_0055, "旋钮 knob 随写变为 0x55");
        axi_read(4'h0, rdata);
        check(rdata, 32'h0000_0055, "读回 0x55");

        // 实验 2 · 连写三档(为 ch09 的 duty 调节预演:ARM 连续拨旋钮)
        axi_write(4'h0, 32'h0000_0040);
        check(knob, 32'h0000_0040, "旋钮改 0x40");
        axi_write(4'h0, 32'h0000_00FF);
        check(knob, 32'h0000_00FF, "旋钮改 0xFF");
        axi_write(4'h0, 32'h0000_0000);
        check(knob, 32'h0000_0000, "旋钮清零");

        // 实验 3 · 复位语义:重新复位,寄存器应回 0
        do_reset;
        axi_read(4'h0, rdata);
        check(rdata, 32'h0, "复位后读回 0");

        // 收卷
        if (errors == 0)
            $display("\n--- PASS (%0d/%0d) ---\n", checks, checks);
        else
            $display("\n--- FAIL (%0d 处失败 / 共 %0d 项) ---\n", errors, checks);
        $finish;
    end

endmodule
