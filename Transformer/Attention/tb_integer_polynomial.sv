`timescale 1ns / 1ps

module tb_integer_polynomial;
    reg clk;
    reg rst;
    reg start;
    reg signed [31:0] q;
    reg signed [15:0] S;
    reg signed [31:0] a;
    reg signed [31:0] b;
    reg signed [31:0] c;
    wire signed [31:0] q_out;
    wire signed [15:0] S_out;
    wire done;

    integer_polynomial uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .q(q),
        .S(S),
        .a(a),
        .b(b),
        .c(c),
        .q_out(q_out),
        .S_out(S_out),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end

    task test_case(input signed [31:0] test_q, input signed [15:0] test_S, real expected);
    begin
        rst = 1;
        start = 0;
        q = test_q;
        S = test_S;
        a = 32'hFFFFFFB7; // -73 in two's complement -0.288
        b = 32'hFFFFFE3C; // -452 in two's complement -1.769
        c = 32'h00000100; // 256 in two's complement 1

        #10 rst = 0;
        #10 start = 1;
        #10 start = 0;

        wait (done);

        $display("Test Case: q=%d, S=%d => q_out=%d, S_out=%d, Expected=%.4f", q, S, q_out, S_out, expected);
        #10;
    end
    endtask

    initial begin
        // Reset
        rst = 1;
        #20 rst = 0;

        // Test Case 1: q=2, S=2 => Expected ≈ 16.9306
        test_case(32'sd8, 16'sd128, -0.437);

        // Test Case 2: q=4, S=3 => Expected ≈ 92.2738
        test_case(32'sd24, 16'sd128, -29.229);

        // Test Case 3: q=7, S=1 => Expected ≈ 65.9695
        test_case(32'sd7, 16'sd256, -6.902);

        // Test Case 4: q=5, S=5 => Expected ≈ 607.4934
        test_case(32'sd5, 16'sd1280, -154.85);

        // Test Case 5: q=16, S=0 => Expected ≈ 1.0
        test_case(32'sd16, 16'sd0, 0.096);

        $finish;
    end
endmodule
