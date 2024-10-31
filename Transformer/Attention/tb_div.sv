`timescale 1ns / 1ps

module tb_div;

    // Parameters
    parameter WIDTH = 32;
    parameter FBITS = 4;

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg [WIDTH-1:0] a;
    reg [WIDTH-1:0] b;

    // Outputs
    wire [WIDTH-1:0] val;
    wire done;
    wire valid;
    wire dbz;

    // Instantiate the Unit Under Test (UUT)
    divi #(
        .WIDTH(WIDTH),
        .FBITS(FBITS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .val(val),
        .done(done),
        .valid(valid),
        .dbz(dbz)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        start = 0;
        a = 32'h00000000;
        b = 32'h00000000;

        // Reset pulse
        #10;
        rst = 0;

        // Test Case 1: a = 10, b = 2
        #10;
        a = 32'h000000A0;  // Fixed-point 10.0
        b = 32'h00000020;  // Fixed-point 2.0
        start = 1;
        #10;
        start = 0;
        wait(done);
        $display("Test Case 1: val = %0d, valid = %b, dbz = %b", val, valid, dbz);
        
        // More test cases can be added here...
        
        $finish;
    end

endmodule
