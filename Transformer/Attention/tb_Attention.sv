`timescale 1ns / 1ps

module tb_Attention;

// Parameters for the Attention module
parameter N = 4;
parameter D = 4;
parameter WIDTH = 8;

// Signals for the Attention module
reg clk;
reg reset;
reg START;
reg signed [WIDTH-1:0] In [N-1:0][D-1:0];
reg signed [WIDTH-1:0] WQ [D-1:0][D-1:0];
reg signed [WIDTH-1:0] WK [D-1:0][D-1:0];
reg signed [WIDTH-1:0] WV [D-1:0][D-1:0];
wire signed [WIDTH*6-1:0] result [N-1:0][D-1:0];
wire DONE;

// Instantiate the Attention module
Attention #(
    .N(N),
    .D(D),
    .WIDTH(WIDTH)
) uut (
    .clk(clk),
    .reset(reset),
    .START(START),
    .In(In),
    .WQ(WQ),
    .WK(WK),
    .WV(WV),
    .result(result),
    .DONE(DONE)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Test procedure
initial begin
    // Initialize inputs
    reset = 1;
    START = 0;

    // Example input values for In, WQ, WK, WV
    // In - 4x4 matrix
    In[0][0] = 1; In[0][1] = 2; In[0][2] = 3; In[0][3] = 4;
    In[1][0] = 5; In[1][1] = 6; In[1][2] = 7; In[1][3] = 8;
    In[2][0] = 9; In[2][1] = 10; In[2][2] = 11; In[2][3] = 12;
    In[3][0] = 13; In[3][1] = 14; In[3][2] = 15; In[3][3] = 16;

    // WQ - 4x4 matrix
    WQ[0][0] = 1; WQ[0][1] = 0; WQ[0][2] = 1; WQ[0][3] = 0;
    WQ[1][0] = 0; WQ[1][1] = 1; WQ[1][2] = 0; WQ[1][3] = 1;
    WQ[2][0] = 1; WQ[2][1] = 0; WQ[2][2] = 1; WQ[2][3] = 0;
    WQ[3][0] = 0; WQ[3][1] = 1; WQ[3][2] = 0; WQ[3][3] = 1;

    // WK - 4x4 matrix
    WK[0][0] = 1; WK[0][1] = 2; WK[0][2] = 1; WK[0][3] = 2;
    WK[1][0] = 2; WK[1][1] = 1; WK[1][2] = 2; WK[1][3] = 1;
    WK[2][0] = 1; WK[2][1] = 2; WK[2][2] = 1; WK[2][3] = 2;
    WK[3][0] = 2; WK[3][1] = 1; WK[3][2] = 2; WK[3][3] = 1;

    // WV - 4x4 matrix
    WV[0][0] = 3; WV[0][1] = 1; WV[0][2] = 2; WV[0][3] = 1;
    WV[1][0] = 1; WV[1][1] = 3; WV[1][2] = 1; WV[1][3] = 2;
    WV[2][0] = 2; WV[2][1] = 1; WV[2][2] = 3; WV[2][3] = 1;
    WV[3][0] = 1; WV[3][1] = 2; WV[3][2] = 1; WV[3][3] = 3;

    // Start the operation
    #10 reset = 0;
    #10 START = 1;
    #10 START = 0;

    // Wait for completion
    wait (DONE);

    // Print the result
    $display("Result:");
    for (int i = 0; i < N; i = i + 1) begin
        for (int j = 0; j < D; j = j + 1) begin
            $write("%d\t", result[i][j]);
        end
        $write("\n");
    end

    $finish;
end

    // Simulation time limit
    initial begin
        #1000000; // 1 ms simulation time limit
        $display("Simulation timeout after 1 ms");
        $finish;
    end

endmodule
