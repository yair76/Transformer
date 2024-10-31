module matrix_multiply #(
    parameter N = 3,     // Sentence length
    parameter Din = 3,   // Old dimension
    parameter Dout = 3,  // New dimension
    parameter WIDTH = 8  // Bit width of matrix elements
) (
    input clk,
    input reset,
    input START,
    input signed [WIDTH-1:0] a [N-1:0][Din-1:0],  // Matrix A
    input signed [WIDTH-1:0] b [Din-1:0][Dout-1:0], // Matrix B
    output signed [WIDTH*2-1:0] c [N-1:0][Dout:0], // Result matrix C
    output reg DONE
);

reg signed [WIDTH*2-1:0] c_reg [N-1:0][Dout:0];
reg compute;

integer i, j, k;

always @(posedge clk) begin
    if (reset) begin
        DONE <= 0;
        compute <= 0;
        for (i = 0; i < N; i++) begin
            for (j = 0; j < Dout; j++) begin
                c_reg[i][j] <= 0;
                c[i][j] <= 0;
            end
        end
    end else if (START) begin
        DONE <= 0;
        compute <= 1;
    end else if (compute) begin
        for (i = 0; i < N; i++) begin
            for (j = 0; j < Dout; j++) begin
                c_reg[i][j] <= 0;
                for (k = 0; k < Din; k++) begin
                    c_reg[i][j] <= c_reg[i][j] + a[i][k] * b[k][j];
                end
                c[i][j] <= c_reg[i][j];
            end
        end
        DONE <= 1;
        compute <= 0;
    end
end

endmodule