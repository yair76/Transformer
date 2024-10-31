// File: tb_sqrt.sv
`timescale 1ns/1ps

module tb_sqrt;
    parameter WIDTH = 32;

    reg clk;
    reg reset;
    reg signed [WIDTH-1:0] x;
    wire signed [WIDTH/2-1:0] sqrt_out;
    wire done;

    // Instantiate the sqrt module
    sqrt #(
        .N(WIDTH)
    ) uut (
        .Clock(clk),
        .reset(reset),
        .num_in(x),
        .sq_root(sqrt_out),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to perform a single test with a given input and expected result
    task run_test(input [WIDTH-1:0] test_val, input [WIDTH/2-1:0] expected_val);
        begin
            x = test_val;
            reset = 1;
            @(posedge clk);  // Wait for a clock edge
            reset = 0;
            
            // Wait until the done signal asserts (operation completes)
            while (!done) begin
                @(posedge clk);
            end

            // Check the result
            if (sqrt_out == expected_val) begin
                $display("PASS: sqrt(%0d) = %0d", test_val, sqrt_out);
            end else begin
                $display("FAIL: sqrt(%0d) = %0d, expected %0d", test_val, sqrt_out, expected_val);
            end
        end
    endtask

    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        x = 0;

        // Wait for a few clock cycles to start
        #10;

        // Test cases
        run_test(0, 0);            // sqrt(0) should be 0
        run_test(1, 1);            // sqrt(1) should be 1
        run_test(4, 2);            // sqrt(4) should be 2
        run_test(9, 3);            // sqrt(9) should be 3
        run_test(16, 4);           // sqrt(16) should be 4
        run_test(25, 5);           // sqrt(25) should be 5
        run_test(49, 7);           // sqrt(49) should be 7
        run_test(64, 8);           // sqrt(64) should be 8
        run_test(144, 12);         // sqrt(144) should be 12
        run_test(255, 15);         // sqrt(255) should be approximately 15
        run_test(1024, 32);        // sqrt(1024) should be 32
        run_test(4096, 64);        // sqrt(4096) should be 64
        run_test(65535, 255);      // sqrt(65535) should be approximately 255

        // Finish simulation
        $finish;
    end
endmodule
