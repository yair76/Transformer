`timescale 1ns / 1ps

module tb_mat_softmax;

    parameter N = 4;
    parameter S_WIDTH = 16;
    parameter WIDTH = 32;
    parameter FBITS = 8;

    reg clk;
    reg rst;
    reg start;
    reg signed [WIDTH-1:0] In [N-1:0][N-1:0];  // Input matrix for softmax
    wire signed [WIDTH-1:0] Out [N-1:0][N-1:0];  // Output matrix from softmax
    wire done;

    // Instantiate the mat_softmax module
    mat_softmax #(
        .N(N),
        .S_WIDTH(S_WIDTH),
        .WIDTH(WIDTH),
        .FBITS(FBITS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .In(In),
        .Out(Out),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Initialize input and control signals
    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        // Reset the module
        #10 rst = 0;

        // Provide input matrix
        In[0][0] = 64'h0000000000000040;  // Example values (you can replace with actual inputs)
        In[0][1] = 64'h0000000000000020;
        In[0][2] = 64'h0000000000000010;
        In[0][3] = 64'h0000000000000030;

        In[1][0] = 64'h0000000000000020;
        In[1][1] = 64'h0000000000000040;
        In[1][2] = 64'h0000000000000030;
        In[1][3] = 64'h0000000000000010;

        In[2][0] = 64'h0000000000000010;
        In[2][1] = 64'h0000000000000030;
        In[2][2] = 64'h0000000000000020;
        In[2][3] = 64'h0000000000000040;

        In[3][0] = 64'h0000000000000030;
        In[3][1] = 64'h0000000000000010;
        In[3][2] = 64'h0000000000000040;
        In[3][3] = 64'h0000000000000020;

        // Start the softmax operation
        #10 start = 1;
        #10 start = 0;

        // Wait for the operation to complete
        wait(done);

        // Print the output matrix as fractions
        $display("Softmax Output Matrix as Fractions:");
        $display("-----------------------------------");

        for (int i = 0; i < N; i = i + 1) begin
            $write("[ ");
            for (int j = 0; j < N; j = j + 1) begin
                $write("%0f ", Out[i][j] / $itor(2**FBITS)); // Converts to fraction
            end
            $write("]\n");
        end

        $display("-----------------------------------");

        #100;
        $finish;
    end

    initial begin
        #1000000; // 1 ms simulation time limit
        $display("Simulation timeout after 1 ms");
        $finish;
    end

endmodule
