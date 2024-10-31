module matrix_division #(
    parameter ROWS = 3,
    parameter COLS = 3,
    parameter WIDTH = 16,        // Width of each matrix element
    parameter DIVISOR_WIDTH = 8  // Width of the divisor
)(
    input wire clk,
    input wire reset,
    input wire start,
    input wire signed [WIDTH-1:0] matrix_in [ROWS-1:0][COLS-1:0],
    input wire signed [DIVISOR_WIDTH-1:0] divisor,
    output reg signed [WIDTH-1:0] matrix_out [ROWS-1:0][COLS-1:0],
    output reg done
);

    // Local parameters
    localparam IDLE = 2'b00;
    localparam LOAD_VALUE = 2'b01;
    localparam START_DIV = 2'b10;
    localparam WAIT_DIV = 2'b11;

    // Internal signals
    reg [1:0] state;
    reg [$clog2(ROWS*COLS)-1:0] counter;
    wire [$clog2(ROWS)-1:0] row;
    wire [$clog2(COLS)-1:0] col;

    // Divider signals
    wire div_busy, div_done, div_valid, div_dbz, div_ovf;
    wire signed [WIDTH-1:0] div_result;
    reg div_start;
    reg signed [WIDTH-1:0] current_value;

    // Convert linear counter to 2D indices
    assign row = counter / COLS;
    assign col = counter % COLS;

    // Instantiate division block
    divi #(
        .WIDTH(WIDTH),
        .FBITS(0)
    ) divider (
        .clk(clk),
        .rst(reset),
        .start(div_start),
        .busy(div_busy),
        .done(div_done),
        .valid(div_valid),
        .dbz(div_dbz),
        .ovf(div_ovf),
        .a(current_value),
        .b({{(WIDTH - DIVISOR_WIDTH){1'b0}}, divisor}),
        .val(div_result)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            done <= 0;
            div_start <= 0;
            current_value <= 0;
            for (int i = 0; i < ROWS; i++) begin
                for (int j = 0; j < COLS; j++) begin
                    matrix_out[i][j] <= 0;
                end
            end
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= LOAD_VALUE;
                        counter <= 0;
                        done <= 0;
                    end
                end

                LOAD_VALUE: begin
                    // Load the next matrix element into current_value
                    current_value <= matrix_in[row][col];
                    state <= START_DIV; // Move to START_DIV after loading
                end

                START_DIV: begin
                    if (!div_busy) begin
                        div_start <= 1; // Assert div_start to begin division
                        state <= WAIT_DIV; // Move to WAIT_DIV to wait for completion
                    end
                end

                WAIT_DIV: begin
                    div_start <= 0; // Deassert div_start after starting division
                    if (div_done) begin
                        matrix_out[row][col] <= div_result; // Store the result

                        // Check if we're done with all elements
                        if (counter == ROWS*COLS - 1) begin
                            state <= IDLE;
                            done <= 1;
                        end else begin
                            counter <= counter + 1;
                            state <= LOAD_VALUE; // Load next value before starting new division
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
