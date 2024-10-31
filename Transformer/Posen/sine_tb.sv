module sine_tb;
    parameter WIDTH = 16;
    parameter FBITS = 8;
    
    reg clk;
    reg rst;
    reg start;
    reg signed [WIDTH-1:0] in;
    wire signed [WIDTH-1:0] out;
    wire done;
    
    real fractional_out;
    real expected_value;
    
    // Instance of sine module
    sine #(
        .WIDTH(WIDTH),
        .FBITS(FBITS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .in(in),
        .out(out),
        .done(done)
    );
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test procedure
    initial begin
        // Initialize
        rst = 1;
        start = 0;
        in = 0;
        
        // Reset
        #20 rst = 0;
        
        // Test angles
        test_sine(0);
        test_sine(30);
        test_sine(45);
        test_sine(60);
        test_sine(90);
        test_sine(120);
        test_sine(150);
        test_sine(180);
        test_sine(270);
        test_sine(360);
        
        // Test negative angles
        test_sine(-30);
        test_sine(-90);
        test_sine(-180);
        
        #100 $finish;
    end
    
    function real abs(real value);
        return (value < 0) ? -value : value;
    endfunction
    
    // Test task
    task test_sine(input integer degree);
        begin
            // Apply input
            in = degree;
            start = 1;
            #10 start = 0;
            
            // Wait for done
            @(posedge done);
            #10;
            
            // Convert output to real
            fractional_out = $signed(out) / (1.0 * (1 << FBITS));
            expected_value = $sin(degree * 3.14159265359 / 180.0);
            
            // Display results
            $display("Degree: %4d, Out (hex): %h, Sine (module): %f, Expected: %f, Error: %f", 
                     degree, out, fractional_out, expected_value, 
                     abs(expected_value - fractional_out));
        end
    endtask
endmodule