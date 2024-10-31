`timescale 1ns / 1ps

module tb_matrix_transpose;

    // Parameters
    parameter N = 3;
    parameter D = 4;
    parameter WIDTH = 8;

    // Signals
    reg clk;
    reg reset;
    reg start;
    reg signed [WIDTH-1:0] In [N-1:0][D-1:0];
    wire signed [WIDTH-1:0] Out [D-1:0][N-1:0];
    wire done;

    // Instantiate the Unit Under Test (UUT)
    matrix_transpose #(
        .N(N),
        .D(D),
        .WIDTH(WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .In(In),
        .Out(Out),
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
        
        // Initialize input matrix
        In[0][0] = 8'sd1;  In[0][1] = 8'sd2;  In[0][2] = 8'sd3;  In[0][3] = 8'sd4;
        In[1][0] = 8'sd5;  In[1][1] = 8'sd6;  In[1][2] = 8'sd7;  In[1][3] = 8'sd8;
        In[2][0] = 8'sd9;  In[2][1] = 8'sd10; In[2][2] = 8'sd11; In[2][3] = 8'sd12;

        // Release reset
        #100;
        reset = 0;
        
        // Start transposition
        #10;
        start = 1;
        //#3;
        //start = 0;

        // Wait for done signal
        @(posedge done);
        
        // Check results
        #10;
        if (Out[0][0] === 8'sd1 && Out[0][1] === 8'sd5 && Out[0][2] === 8'sd9 &&
            Out[1][0] === 8'sd2 && Out[1][1] === 8'sd6 && Out[1][2] === 8'sd10 &&
            Out[2][0] === 8'sd3 && Out[2][1] === 8'sd7 && Out[2][2] === 8'sd11 &&
            Out[3][0] === 8'sd4 && Out[3][1] === 8'sd8 && Out[3][2] === 8'sd12) begin
            $display("Test passed!");
        end else begin
            $display("Test failed!");
            $display("Expected: 1  5  9");
            $display("          2  6  10");
            $display("          3  7  11");
            $display("          4  8  12");
            $display("Got:");
            for (int i = 0; i < D; i++) begin
                for (int j = 0; j < N; j++) begin
                    $write("%d  ", Out[i][j]);
                end
                $write("\n");
            end
        end
        
        // Finish simulation
        #100;
        $finish;
    end

endmodule