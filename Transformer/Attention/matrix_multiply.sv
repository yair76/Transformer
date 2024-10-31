module matrix_multiply #(
    parameter N = 3,     // Sentence length
    parameter Din = 3,   // Old dimension
    parameter Dout = 3,  // New dimension
    parameter WIDTHA = 8,  // Bit width of matrix elements
    parameter WIDTHB = 8  // Bit width of matrix elements
) (
    input clk,
    input reset,
    input START,
    input signed [WIDTHA-1:0] a [N-1:0][Din-1:0],    // Matrix A
    input signed [WIDTHB-1:0] b [Din-1:0][Dout-1:0], // Matrix B
    output reg signed [WIDTHA+WIDTHB-1:0] c [N-1:0][Dout-1:0], // Result matrix C
    output reg DONE
);

reg signed [WIDTHA+WIDTHB-1:0] temp_c [N-1:0][Dout-1:0];
integer i, j, k;

// Combinational block for matrix multiplication calculation
always @(*) begin
    for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < Dout; j = j + 1) begin
            temp_c[i][j] = 0; // Initialize temporary matrix element
            for (k = 0; k < Din; k = k + 1) begin
                temp_c[i][j] = temp_c[i][j] + a[i][k] * b[k][j]; // Accumulate the result
            end
        end
    end
end

// Sequential block to assign the output matrix and signal completion
always @(posedge clk or posedge reset) begin
    if (reset) begin
        DONE <= 0;
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < Dout; j = j + 1) begin
                c[i][j] <= 0;
            end
        end
    end else if (START) begin
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < Dout; j = j + 1) begin
                c[i][j] <= temp_c[i][j]; // Assign the result to the output matrix
            end
        end
        DONE <= 1; // Signal that the calculation is complete
    end else begin
        DONE <= 0;
    end
end

endmodule