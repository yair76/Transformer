module matrix_transpose #(
    parameter N = 3,          // Number of rows
    parameter D = 3,          // Number of columns
    parameter WIDTH = 8       // Width of each element in bits
)(
    input wire clk,
    input wire reset,
    input wire start,
    input signed [WIDTH-1:0] In [N-1:0][D-1:0],
    output reg signed [WIDTH-1:0] Out [D-1:0][N-1:0],
    output reg done
);

    integer i, j;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < D; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    Out[i][j] <= 0;
                end
            end
            done <= 0;
        end
        else if (start) begin
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < D; j = j + 1) begin
                    Out[j][i] <= In[i][j];
                end
            end
            done <= 1;
        end
        else begin
            done <= 0;
        end
    end

endmodule