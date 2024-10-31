`timescale 1ns/1ps

module tb_matrix_multiply;

// Parameters
parameter N = 3;
parameter Din = 3;
parameter Dout = 3;
parameter WIDTH = 8;

// Inputs
reg clk;
reg reset;
reg START;
reg signed [WIDTH-1:0] a [N-1:0][Din-1:0];
reg signed [WIDTH-1:0] b [Din-1:0][Dout-1:0];

// Outputs
wire signed [WIDTH*2-1:0] c [N-1:0][Dout-1:0];
wire DONE;

// Instantiate the matrix multiplication module
matrix_multiply #(
    .N(N),
    .Din(Din),
    .Dout(Dout),
    .WIDTHA(WIDTH),
    .WIDTHB(WIDTH)
) dut (
    .clk(clk),
    .reset(reset),
    .START(START),
    .a(a),
    .b(b),
    .c(c),
    .DONE(DONE)
);

// Clock generation
always #5 clk = ~clk;

// Test vectors
integer cycle_count;
integer signed_value;

initial begin
    // Initialize inputs
    clk = 0;
    reset = 1;
    START = 0;
    // Initialize array a
    a[0][0] = -1; a[0][1] = 2; a[0][2] = -3;
    a[1][0] = 4;  a[1][1] = -5; a[1][2] = 6;
    a[2][0] = -7; a[2][1] = 8;  a[2][2] = -9;

    // Initialize array b
    b[0][0] = -1; b[0][1] = 2; b[0][2] = -3;
    b[1][0] = 4;  b[1][1] = -5; b[1][2] = 6;
    b[2][0] = -7; b[2][1] = 8;  b[2][2] = -9;
    
    cycle_count = 0;

    // Reset the module
    #10 reset = 0;

    // Start the computation
    #20 START = 1;

    // Wait for the computation to complete or simulation limit reached
    while (!DONE && cycle_count < 1000) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
    end

    // Check if DONE was asserted or simulation limit reached
    if (DONE) begin
        #10 START = 0;
        // Check the output
        if (c[0][0] == 30 && c[0][1] == -36 && c[0][2] == 42 &&
            c[1][0] == -66  && c[1][1] == 81 && c[1][2] == -96 &&
            c[2][0] == 102 && c[2][1] == -126 && c[2][2] == 150) begin
            $display("Test passed!");
        end else begin
            $display("Test failed!");
            $display("Result matrix:");
            for (integer i = 0; i < N; i++) begin
                for (integer j = 0; j < Dout; j++) begin
                    $display("c[%0d][%0d] = %0d", i, j, c[i][j]);
                end
            end
        end
    end else begin
        $display("Simulation limit reached without DONE assertion!");
    end

    $finish;
end

endmodule