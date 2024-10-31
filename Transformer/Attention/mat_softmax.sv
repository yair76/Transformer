module mat_softmax #(
    parameter N = 4,               // Matrix dimension
    parameter S_WIDTH = 16,        // Softmax input size width
    parameter WIDTH = 32,          // Data width of input elements
    parameter FBITS = 8            // Fractional bits for fixed-point representation
)(
    input wire clk,
    input wire rst,
    input wire start,
    input signed [WIDTH-1:0] In [N-1:0][N-1:0],  // Input matrix
    output reg signed [WIDTH-1:0] Out [N-1:0][N-1:0], // Output matrix after applying softmax
    output reg done
);

    reg [N-1:0] row_start;                 // Control signal for starting softmax for each row
    reg [N-1:0] row_done;                  // Done signal for each softmax instance
    reg signed [WIDTH-1:0] row_in [N-1:0]; // Input to softmax for each row
    reg signed [WIDTH-1:0] row_out [N-1:0]; // Output of softmax for each row
    reg [3:0] row_index;                   // Index to iterate over rows
    reg softmax_start;                     // Start signal for softmax instance

    wire softmax_done;                     // Done signal from softmax instance

    // Softmax instance
    softmax #(
        .N(N),
        .S_WIDTH(S_WIDTH),
        .WIDTH(WIDTH),
        .FBITS(FBITS)
    ) softmax_inst (
        .clk(clk),
        .rst(rst),
        .start(softmax_start),
        .In(row_in),
        .Out(row_out),
        .done(softmax_done)
    );

    // FSM states
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        LOAD_ROW = 2'b01,
        PROCESS_ROW = 2'b10,
        DONE = 2'b11
    } state_t;

    state_t state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            row_index <= 0;
            done <= 0;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD_ROW;
                end else begin
                    next_state = IDLE;
                end
            end
            LOAD_ROW: begin
                next_state = PROCESS_ROW;
            end
            PROCESS_ROW: begin
                if (softmax_done) begin
                    if (row_index == N-1) begin
                        next_state = DONE;
                    end else begin
                        next_state = LOAD_ROW;
                    end
                end else begin
                    next_state = PROCESS_ROW;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Control row selection and loading
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            row_index <= 0;
        end else if (state == LOAD_ROW) begin
            row_in <= In[row_index];  // Load the next row from input matrix
        end else if (state == PROCESS_ROW && softmax_done) begin
            Out[row_index] <= row_out;  // Store the softmax result into the output matrix
            row_index <= row_index + 1;
        end
    end

    // Control start signal for softmax
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            softmax_start <= 0;
        end else if (state == LOAD_ROW) begin
            softmax_start <= 1;
        end else if (state == PROCESS_ROW && softmax_done) begin
            softmax_start <= 0;
        end
    end

    // Control done signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 0;
        end else if (state == DONE) begin
            done <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule
