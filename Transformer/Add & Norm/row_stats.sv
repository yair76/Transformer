module row_stats #(
    parameter M = 4,  // Number of rows
    parameter N = 4,  // Number of columns
    parameter WIDTH = 8,  // Bit-width of each element
    parameter FRACTION_WIDTH = 8,  // Fractional bit-width for fixed-point
    parameter RESULT_WIDTH = WIDTH + $clog2(N) + FRACTION_WIDTH  // Width of result to handle fixed-point average
)(
    input  wire [WIDTH-1:0] matrix [M-1:0][N-1:0],  // Input matrix
    output reg [RESULT_WIDTH-1:0] row_avg [M-1:0],  // Output row averages (fixed-point)
    output reg [RESULT_WIDTH-1:0] row_stddev [M-1:0]  // Output row standard deviations (fixed-point)
);

    integer i, j;
    reg [RESULT_WIDTH-1:0] sum_squared_diff;
    reg [RESULT_WIDTH-1:0] diff;
    reg [RESULT_WIDTH-1:0] variance;

    // Internal wire to hold the result of the square root operation
    wire [RESULT_WIDTH/2-1:0] sqrt_out;

    // Internal wire to hold the row averages calculated by the row_average module
    wire [RESULT_WIDTH-1:0] row_avg_internal [M-1:0];

    // Instantiate the row_average module to calculate the row averages
    row_average #(
        .M(M),
        .N(N),
        .WIDTH(WIDTH),
        .FRACTION_WIDTH(FRACTION_WIDTH)
    ) row_avg_inst (
        .matrix(matrix),
        .row_avg(row_avg_internal)  // Output row averages
    );

    // Instantiate the sqrt module to calculate the square root for standard deviation
    sqrt #(
        .WIDTH(RESULT_WIDTH)
    ) sqrt_inst (
        .x(variance),  // Input variance
        .sqrt_out(sqrt_out)  // Output square root (stddev)
    );

    always @(*) begin
        for (i = 0; i < M; i = i + 1) begin
            sum_squared_diff = 0;

            // Copy the row averages from row_average instance to row_avg output
            row_avg[i] = row_avg_internal[i];

            // Calculate the sum of squared differences for standard deviation
            for (j = 0; j < N; j = j + 1) begin
                diff = (matrix[i][j] << FRACTION_WIDTH) - row_avg_internal[i];  // Difference from the average
                sum_squared_diff = sum_squared_diff + (diff * diff);  // Square the difference and add to the sum
            end

            // Compute variance (sum of squared differences divided by N)
            variance = sum_squared_diff / N;

            // Use the square root module to calculate the standard deviation
            row_stddev[i] = sqrt_out << FRACTION_WIDTH;  // Adjust the fixed-point result
        end
    end

endmodule
