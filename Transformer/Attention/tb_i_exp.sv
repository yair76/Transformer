`timescale 1ns / 1ps

module tb_i_exp();

// Parameters
localparam Q_WIDTH = 32;
localparam S_WIDTH = 16;
localparam FBITS = 8;

// Inputs
reg clk;
reg rst;
reg start;
reg signed [Q_WIDTH-1:0] q;
reg signed [S_WIDTH-1:0] S;

// Outputs
wire signed [Q_WIDTH-1:0] q_out;
wire signed [S_WIDTH-1:0] S_out;
wire done;

// Instantiate the Unit Under Test (UUT)
i_exp #(
    .Q_WIDTH(Q_WIDTH),
    .S_WIDTH(S_WIDTH),
    .FBITS(FBITS)
) uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .q(q),
    .maxmsb(25),
    .S(S),
    .q_out(q_out),
    .S_out(S_out),
    .done(done)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Fixed-point to float conversion function
function real fixed_to_float;
    input signed [Q_WIDTH-1:0] fixed;
    begin
        fixed_to_float = $itor(fixed) / (1 << FBITS);
    end
endfunction

// Test case structure
typedef struct {
    integer q_int;
    integer S_int;
} test_case_t;

// Test cases (using integer values)
test_case_t test_cases[5] = '{
    '{5, 512},    // q = 1, S = 2
    '{10, 512},   // q = -1, S = 2
    '{15, 512},    // q = 2, S = 1
    '{20, 512},   // q = -2, S = 1
    '{-2, 128}    // q = 1, S = 10
};

// Test procedure
integer i;
real expected, actual_q, actual_S, error;

initial begin
    // Initialize Inputs
    rst = 1;
    start = 0;
    q = 0;
    S = 0;

    // Wait for global reset
    #100;
    rst = 0;
    #10;

    for (i = 0; i < 5; i = i + 1) begin
        // Set integer inputs
        q = test_cases[i].q_int;
        S = test_cases[i].S_int;

        // Start the calculation
        start = 1;

        // Wait for done signal or timeout
        fork
            begin
                @(posedge done);
            end
            begin
                #10000;  // 10,000 ns timeout
                $display("Test Case %0d: Timeout occurred!", i);
                disable fork;
            end
        join_any

        #10 start = 0;

        // Calculate expected result
        expected = $exp($itor(q) * $itor(S/256));

        // Convert output to float
        actual_q = q_out;

        actual_S = S_out;

        // Calculate error
        //error = ((actual - expected) / expected) * 100;

        // Display results
        $display("Test Case %0d:", i);
        $display("  q = %0d, S = %0d", q, S);
        $display("  Expected: %f", expected);
        $display("  Actual_q: %f", actual_q);
        $display("  actual_S: %f", actual_S);
        $display("");

        // Add a delay between test cases
        #100;
    end

    // Finish the simulation
    $finish;
end

// Overall simulation time limit
initial begin
    #100000 $display("Simulation timeout!"); $finish;
end

endmodule