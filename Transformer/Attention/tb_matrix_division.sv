`timescale 1ns / 1ps

module tb_matrix_division;

    // Parameters
    parameter ROWS = 3;
    parameter COLS = 3;
    parameter WIDTH = 16;
    parameter DIVISOR_WIDTH = 8;

    // Signals
    reg clk;
    reg reset;
    reg start;
    reg signed [WIDTH-1:0] matrix_in [ROWS-1:0][COLS-1:0];
    reg signed [DIVISOR_WIDTH-1:0] divisor;
    wire signed [WIDTH-1:0] matrix_out [ROWS-1:0][COLS-1:0];
    wire done;

    // Instantiate the Unit Under Test (UUT)
    matrix_division #(
        .ROWS(ROWS),
        .COLS(COLS),
        .WIDTH(WIDTH),
        .DIVISOR_WIDTH(DIVISOR_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .matrix_in(matrix_in),
        .divisor(divisor),
        .matrix_out(matrix_out),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test procedure
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        start = 0;
        divisor = 2;  // We'll divide all elements by 2

        // Initialize input matrix
        matrix_in[0][0] = 10; matrix_in[0][1] = 20; matrix_in[0][2] = 30;
        matrix_in[1][0] = 40; matrix_in[1][1] = 50; matrix_in[1][2] = 60;
        matrix_in[2][0] = 70; matrix_in[2][1] = 80; matrix_in[2][2] = 90;

        // Release reset
        #100;
        reset = 0;
        #10;

        // Start division
        start = 1;
        #10;
        start = 0;

        // Wait for done signal
        @(posedge done);
        #10;

        // Check results
        if (matrix_out[0][0] === 5  && matrix_out[0][1] === 10 && matrix_out[0][2] === 15 &&
            matrix_out[1][0] === 20 && matrix_out[1][1] === 25 && matrix_out[1][2] === 30 &&
            matrix_out[2][0] === 35 && matrix_out[2][1] === 40 && matrix_out[2][2] === 45) begin
            $display("Test passed!");
        end else begin
            $display("Test failed!");
            $display("Expected:");
            $display("5  10 15");
            $display("20 25 30");
            $display("35 40 45");
            $display("Got:");
            for (int i = 0; i < ROWS; i++) begin
                for (int j = 0; j < COLS; j++) begin
                    $write("%d ", matrix_out[i][j]);
                end
                $write("\n");
            end
        end

        // Test with negative numbers
        #20;
        matrix_in[0][0] = -10; matrix_in[0][1] = -20; matrix_in[0][2] = -30;
        matrix_in[1][0] = 40;  matrix_in[1][1] = -50; matrix_in[1][2] = 60;
        matrix_in[2][0] = -70; matrix_in[2][1] = 80;  matrix_in[2][2] = -90;
        divisor = 3;

        start = 1;
        #10;
        start = 0;

        @(posedge done);
        #10;

        if (matrix_out[0][0] === -3  && matrix_out[0][1] === -6  && matrix_out[0][2] === -10 &&
            matrix_out[1][0] === 13  && matrix_out[1][1] === -16 && matrix_out[1][2] === 20  &&
            matrix_out[2][0] === -23 && matrix_out[2][1] === 26  && matrix_out[2][2] === -30) begin
            $display("Test with negative numbers passed!");
        end else begin
            $display("Test with negative numbers failed!");
            $display("Expected:");
            $display("-3  -6  -10");
            $display("13 -16  20");
            $display("-23 26 -30");
            $display("Got:");
            for (int i = 0; i < ROWS; i++) begin
                for (int j = 0; j < COLS; j++) begin
                    $write("%d ", matrix_out[i][j]);
                end
                $write("\n");
            end
        end

        // Finish simulation
        #100;
        $display("All tests completed");
        $finish;
    end

endmodule