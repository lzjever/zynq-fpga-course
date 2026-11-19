// ============================================================
// Lab 09 · 呼吸灯模块(pwm_breather)— ch05 的 PWM + 三角波,带"速度"输入
// ============================================================
// 与 ch05 的呼吸灯唯一的不同:duty 的爬升速度不再写死,
// 而是来自 SPEED 寄存器 —— ARM 拨旋钮,呼吸就变速。
//
// 时间账(时钟 = FCLK0,默认 50MHz):
//   PWM 载波 = 256 拍(8bit 分辨率,50MHz/256 ≈ 195kHz,人眼无感)
//   duty 每走一步 = 等 (SPEED+1) 个载波周期
//   一次完整呼吸(三角 0→255→0)= 512 步
//   ⇒ 呼吸周期 ≈ (SPEED+1) × 512 × 256 ÷ 50MHz = (SPEED+1) × 2.62ms
//      SPEED=0x17D(381)  ≈ 1 秒
//      SPEED=0x5F5(1525) ≈ 4 秒
//
// SPEED = 0:duty 冻结在当前值(顶层用它切"手动挡",见 axi_led_top.v)
module pwm_breather (
    input  wire        clk,
    input  wire [15:0] speed,
    output wire        led
);

    // ---- 第一级 tick:载波节拍(每 256 拍一下)----
    reg [7:0] carrier_div;
    always @(posedge clk) carrier_div <= carrier_div + 8'd1;
    wire carrier_tick = (carrier_div == 8'd0);

    // ---- 第二级 tick:呼吸步进节拍(每 SPEED+1 个载波一下)----
    reg [15:0] step_cnt;
    always @(posedge clk) begin
        if (carrier_tick)
            step_cnt <= (step_cnt >= speed) ? 16'd0 : step_cnt + 16'd1;
    end
    // speed=0 时不再步进(duty 冻结;顺便防住"0 永远满足"的空转)
    wire step_tick = carrier_tick && (speed != 16'd0) && (step_cnt >= speed);

    // ---- duty 三角波:0→255→0 循环爬升 ----
    reg [7:0] duty;
    reg       up;
    always @(posedge clk) begin
        if (step_tick) begin
            if (up) begin
                if (duty == 8'd254) up <= 1'b0;
                duty <= duty + 8'd1;
            end else begin
                if (duty == 8'd1) up <= 1'b1;
                duty <= duty - 8'd1;
            end
        end
    end

    // ---- PWM 载波比较(ch05 的老朋友;用 < 号,duty=255 时亮度 255/256)----
    reg [7:0] phase;
    always @(posedge clk) phase <= phase + 8'd1;
    assign led = (phase < duty);

endmodule
