`timescale 1ns/1ps

module tb_MaxMSB;
    parameter WIDTH = 8;
    parameter N = 4;

    // Clock and control signals
    reg clk;
    reg reset;
    reg start;
    wire done;

    // Input and output signals
    reg signed [WIDTH-1:0] In [N-1:0];
    wire [$clog2(WIDTH):0] msb_index;

    // Instantiate the MaxMSB module
    MaxMSB #(WIDTH, N) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .In(In),
        .msb_index(msb_index),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test procedure
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        start = 0;
        
        // Apply reset
        #10 reset = 0;
        
        // Test case 1: Mixed positive values
        In[0] = 8'b00000011;  // 3
        In[1] = 8'b01000000;  // 64
        In[2] = 8'b00111111;  // 63
        In[3] = 8'b00010000;  // 16

        // Start the operation
        start = 1;
        #10 start = 0;  // Deassert start

        // Wait for done signal
        wait (done);
        #10;
        $display("Test 1 - Expected MSB Index: 6, Actual MSB Index: %0d", msb_index);

        // Test case 2: Mixed negative and positive values
        reset = 1;
        #10 reset = 0;
        
        In[0] = -8'd12;
        In[1] = -8'd45;
        In[2] = 8'b01111111;  // 127
        In[3] = 8'b00000101;  // 5

        // Start the operation
        start = 1;
        #10 start = 0;

        // Wait for done signal
        wait (done);
        #10;
        $display("Test 2 - Expected MSB Index: 6, Actual MSB Index: %0d", msb_index);

        // Test case 3: All negative values
        reset = 1;
        #10 reset = 0;
        
        In[0] = -8'd1;
        In[1] = -8'd2;
        In[2] = -8'd3;
        In[3] = 8'b00000010;  // 2

        // Start the operation
        start = 1;
        #10 start = 0;

        // Wait for done signal
        wait (done);
        #10;
        $display("Test 3 - Expected MSB Index: 1, Actual MSB Index: %0d", msb_index);

        // Test case 4: All zeros
        reset = 1;
        #10 reset = 0;
        
        In[0] = 8'b00000000;
        In[1] = 8'b00000000;
        In[2] = 8'b00000000;
        In[3] = 8'b00000000;

        // Start the operation
        start = 1;
        #10 start = 0;

        // Wait for done signal
        wait (done);
        #10;
        $display("Test 4 - Expected MSB Index: 0, Actual MSB Index: %0d", msb_index);

        // Test case 5: Maximum negative and positive values
        reset = 1;
        #10 reset = 0;

        In[0] = -8'sd128;     // Minimum 8-bit signed value
        In[1] = 8'b01000000;  // 64
        In[2] = 8'b00010000;  // 16
        In[3] = 8'b00100000;  // 32

        // Start the operation
        start = 1;
        #10 start = 0;

        // Wait for done signal
        wait (done);
        #10;
        $display("Test 5 - Expected MSB Index: 6, Actual MSB Index: %0d", msb_index);

        // Finish simulation
        $finish;
    end

    // Simulation time limit
    initial begin
        #1000000; // 1 ms simulation time limit
        $display("Simulation timeout after 1 ms");
        $finish;
    end
    
endmodule
