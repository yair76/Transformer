`timescale 1ns / 1ps

module tb_softmax();

    // Parameters
    parameter N = 4;
    parameter S_WIDTH = 16;
    parameter WIDTH = 32;
    parameter FBITS = 8;
    
    // Signals
    reg clk;
    reg rst;
    reg start;
    reg signed [WIDTH-1:0] In [N-1:0];
    wire signed [WIDTH-1:0] Out [N-1:0];
    wire done;
    
    // Instantiate the Unit Under Test (UUT)
    softmax #(
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
    always begin
        #5 clk = ~clk;
    end
    
    // Test case variables
    reg [31:0] test_case;
    real float_out [N-1:0];
    real sum_exp;
    
    // Convert fixed-point to float
    function real fixed_to_float;
        input signed [WIDTH-1:0] fixed;
        real float;
    begin
        float = $itor(fixed) / (1 << FBITS);
        fixed_to_float = float;
    end
    endfunction
    
    // Testbench stimulus and checking
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        test_case = 0;
        
        // Reset the module
        #100;
        rst = 0;
        #10;
        
        // Test case 1: Simple values
        test_case = 1;
        In[0] = 64; In[1] = 32; In[2] = 16; In[3] = 48;
        
        // Start the softmax calculation
        start = 1;
        #10 start = 0;
        
        // Wait for done signal
        wait(done);
        #10;
        
        // Check results
        sum_exp = 0;
        for (int i = 0; i < N; i++) begin
            sum_exp = sum_exp + $exp(In[i]);
        end
        for (int i = 0; i < N; i++) begin
            float_out[i] = fixed_to_float(Out[i]);
            $display("Out[%0d] = %f (Expected: %f)", i, float_out[i], $exp(In[i])/sum_exp);
        end
        
        // Test case 2: Larger values
        #100;
        test_case = 2;
        In[0] = 20; In[1] = 10; In[2] = 40; In[3] = 30;
        
        // Start the softmax calculation
        start = 1;
        #10 start = 0;
        
        // Wait for done signal
        wait(done);
        #10;
        
        // Check results
        sum_exp = 0;
        for (int i = 0; i < N; i++) begin
            sum_exp = sum_exp + $exp(In[i]);
        end
        for (int i = 0; i < N; i++) begin
            float_out[i] = fixed_to_float(Out[i]);
            $display("Out[%0d] = %f (Expected: %f)", i, float_out[i], $exp(In[i])/sum_exp);
        end
        
        // End simulation
        #100;
        $finish;
    end

    // Simulation time limit
    initial begin
        #1000000; // 1 ms simulation time limit
        $display("Simulation timeout after 1 ms");
        $finish;
    end

endmodule