module sequential_matrix_multiply #(
    parameter N = 3,     // Sentence length
    parameter D1 = 3,    // First dimension
    parameter D2 = 3,    // Second dimension
    parameter WIDTH = 8  // Bit width of matrix elements
) (
    input clk,
    input reset,
    input START,
    input signed [WIDTH-1:0] a [N-1:0][D1-1:0],      // Matrix A (NxD1) Input sentence
    input signed [WIDTH-1:0] b [D1-1:0][D2-1:0],     // Matrix B (D1xD2) CNN-1
    input signed [WIDTH-1:0] c [D2-1:0][D1-1:0],     // Matrix C (D2xD1) CNN-2
    output signed [WIDTH*3-1:0] result [N-1:0][D1-1:0], // Final result (NxD1)
    output reg DONE
);

wire signed [WIDTH*2-1:0] intermediate [N-1:0][D2-1:0]; // Intermediate result (NxD2)
wire DONE_1, DONE_2;

// First matrix multiplication (NxD1 * D1xD2)
matrix_multiply #(
    .N(N),
    .Din(D1),
    .Dout(D2),
    .WIDTH(WIDTH)
) mm1 (
    .clk(clk),
    .reset(reset),
    .START(START),
    .a(a),
    .b(b),
    .c(intermediate),
    .DONE(DONE_1)
);

// Second matrix multiplication (NxD2 * D2xD1)
matrix_multiply #(
    .N(N),
    .Din(D2),
    .Dout(D1),
    .WIDTH(WIDTH*2) // Increase the width to handle larger intermediate results
) mm2 (
    .clk(clk),
    .reset(reset),
    .START(DONE_1), // Start the second multiplication when the first is done
    .a(intermediate),
    .b(c),
    .c(result),
    .DONE(DONE_2)
);

// Set negative numbers in the result matrix to 0
integer i, j;
always @(posedge clk) begin
    if (reset) begin
        DONE <= 0;
    end else if (DONE_2) begin
        for (i = 0; i < N; i++) begin
            for (j = 0; j < D1; j++) begin
                if (result[i][j][WIDTH*3-1]) // Check the sign bit
                    result[i][j] <= 0;
            end
        end
        DONE <= 1;
    end else begin
        DONE <= 0;
    end
end

endmodule