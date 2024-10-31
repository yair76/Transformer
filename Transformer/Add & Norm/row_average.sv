module row_average #(
    parameter M = 4,  // Number of rows
    parameter N = 4,  // Number of columns
    parameter WIDTH = 8,  // Bit-width of each element
    parameter FRACTION_WIDTH = 8,  // Fractional bit-width for fixed-point
    parameter RESULT_WIDTH = WIDTH + $clog2(N) + FRACTION_WIDTH  // Width of result to handle fixed-point average
)(
    input  wire [WIDTH-1:0] matrix [M-1:0][N-1:0],  // Input matrix
    output reg [RESULT_WIDTH-1:0] row_avg [M-1:0]   // Output row averages (fixed-point)
);

    integer i, j;
    reg [RESULT_WIDTH-1:0] sum;

    always @(*) begin
        for (i = 0; i < M; i = i + 1) begin
            sum = 0;
            for (j = 0; j < N; j = j + 1) begin
                sum = sum + (matrix[i][j] << FRACTION_WIDTH);  // Shift to fixed-point
            end
            row_avg[i] = sum / N;  // Calculate the average for the row
        end
    end

endmodule
