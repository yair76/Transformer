`timescale 1ns / 1ps

module Attention #(
    parameter N = 4,     // Sentence length
    parameter D = 4,     // Dimension of input vectors
    parameter WIDTH = 8  // Bit width of matrix elements
) (
    input clk,
    input reset,
    input START,
    input signed [WIDTH-1:0] In [N-1:0][D-1:0],      // Input matrix (NxD)
    input signed [WIDTH-1:0] WQ [D-1:0][D-1:0],      // Weight matrix for Q (DxD)
    input signed [WIDTH-1:0] WK [D-1:0][D-1:0],      // Weight matrix for K (DxD)
    input signed [WIDTH-1:0] WV [D-1:0][D-1:0],      // Weight matrix for V (DxD)
    output reg signed [WIDTH*6-1:0] result [N-1:0][D-1:0], // Final result (NxD)
    output reg DONE
);

    // Internal signals
    reg signed [WIDTH*2-1:0] Q [N-1:0][D-1:0];
    reg signed [WIDTH*2-1:0] K [N-1:0][D-1:0];
    reg signed [WIDTH*2-1:0] V [N-1:0][D-1:0];
    reg signed [WIDTH*2-1:0] K_T [D-1:0][N-1:0];
    reg signed [WIDTH*4-1:0] result_qkt [N-1:0][N-1:0];
    reg signed [WIDTH*4-1:0] result_div [N-1:0][N-1:0];
    reg signed [WIDTH*4-1:0] result_softmax [N-1:0][N-1:0];
    reg signed [N-1:0] sqrtD;

    // Done signals for each step
    reg DONE_Q, DONE_K, DONE_V, DONE_TRANSPOSE, DONE_QKT, DONE_SQRT, DONE_DIV, DONE_SOFTMAX, DONE_RESULT, DONE_SHIFT;

    // State encoding
    typedef enum reg [4:0] {
        IDLE,
        CALC_Q,
        CALC_K,
        CALC_V,
        CALC_TRANSPOSE,
        CALC_QKT,
        CALC_SQRT,
        CALC_DIV,
        CALC_SOFTMAX,
        CALC_RESULT,
        SHIFT_RESULT,
        FINISH
    } state_t;

    reg [4:0] current_state, next_state;

    // Instantiate the matrix multiplication, transpose, division, and softmax modules
    matrix_multiply #(
        .N(N),
        .Din(D),
        .Dout(D),
        .WIDTHA(WIDTH),
        .WIDTHB(WIDTH)
    ) mmq (
        .clk(clk),
        .reset(reset),
        .START(current_state == CALC_Q),
        .a(In),
        .b(WQ),
        .c(Q),
        .DONE(DONE_Q)
    );

    matrix_multiply #(
        .N(N),
        .Din(D),
        .Dout(D),
        .WIDTHA(WIDTH),
        .WIDTHB(WIDTH)
    ) mmk (
        .clk(clk),
        .reset(reset),
        .START(current_state == CALC_K),
        .a(In),
        .b(WK),
        .c(K),
        .DONE(DONE_K)
    );

    matrix_multiply #(
        .N(N),
        .Din(D),
        .Dout(D),
        .WIDTHA(WIDTH),
        .WIDTHB(WIDTH)
    ) mmv (
        .clk(clk),
        .reset(reset),
        .START(current_state == CALC_V),
        .a(In),
        .b(WV),
        .c(V),
        .DONE(DONE_V)
    );

    matrix_transpose #(
        .N(N),
        .D(D),
        .WIDTH(2*WIDTH)
    ) transpose (
        .clk(clk),
        .reset(reset),
        .start(current_state == CALC_TRANSPOSE),
        .In(K),
        .Out(K_T),
        .done(DONE_TRANSPOSE)
    );

    matrix_multiply #(
        .N(N),
        .Din(D),
        .Dout(N),
        .WIDTHA(2*WIDTH),
        .WIDTHB(2*WIDTH)
    ) mmqkt (
        .clk(clk),
        .reset(reset),
        .START(current_state == CALC_QKT),
        .a(Q),
        .b(K_T),
        .c(result_qkt),
        .DONE(DONE_QKT)
    );

    // Instantiate the sqrt module for calculating sqrt(Dk)
    sqrt #(
        .N(2*N)
    ) sqrt_inst (
        .Clock(clk),
        .reset(reset),
        .num_in(D),
        .done(DONE_SQRT),
        .sq_root(sqrtD)
    );

    matrix_division #(
        .ROWS(N),
        .COLS(N),
        .WIDTH(WIDTH*4),
        .DIVISOR_WIDTH(N)
    ) mmd (
        .clk(clk),
        .reset(reset),
        .start(current_state == CALC_DIV),
        .matrix_in(result_qkt),
        .divisor(2*sqrtD),
        .matrix_out(result_div),
        .done(DONE_DIV)
    );

        mat_softmax #(
        .N(N),
        .S_WIDTH(2*WIDTH),
        .WIDTH(4*WIDTH),
        .FBITS(WIDTH)
    ) softmat (
        .clk(clk),
        .rst(reset),
        .start(current_state == CALC_SOFTMAX),
        .In(result_div),
        .Out(result_softmax),
        .done(DONE_SOFTMAX)
    );

    matrix_multiply #(
        .N(N),
        .Din(N),
        .Dout(D),
        .WIDTHA(4*WIDTH),
        .WIDTHB(2*WIDTH)
    ) mmresult (
        .clk(clk),
        .reset(reset),
        .START(current_state == CALC_RESULT),
        .a(result_softmax),
        .b(V),
        .c(result),
        .DONE(DONE_RESULT) // Using DONE_RESULT for transition to SHIFT_RESULT
    );

    // State transition logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            DONE_SHIFT <=0;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE:           next_state = START ? CALC_Q : IDLE;
            CALC_Q:         next_state = DONE_Q ? CALC_K : CALC_Q;
            CALC_K:         next_state = DONE_K ? CALC_V : CALC_K;
            CALC_V:         next_state = DONE_V ? CALC_TRANSPOSE : CALC_V;
            CALC_TRANSPOSE: next_state = DONE_TRANSPOSE ? CALC_QKT : CALC_TRANSPOSE;
            CALC_QKT:       next_state = DONE_QKT ? CALC_SQRT : CALC_QKT;
            CALC_SQRT:      next_state = DONE_SQRT ? CALC_DIV : CALC_SQRT;
            CALC_DIV:       next_state = DONE_DIV ? CALC_SOFTMAX : CALC_DIV;
            CALC_SOFTMAX:   next_state = DONE_SOFTMAX ? CALC_RESULT : CALC_SOFTMAX;
            CALC_RESULT:    next_state = DONE_RESULT ? SHIFT_RESULT : CALC_RESULT;
            SHIFT_RESULT:   next_state = DONE_SHIFT ? FINISH : SHIFT_RESULT;
            FINISH:         next_state = IDLE;
            default:        next_state = IDLE;
        endcase
    end

    // Shift result elements by WIDTH bits to the right in SHIFT_RESULT state
    integer i, j;
    always @(posedge clk) begin
        if (reset) begin
            DONE <= 0;
            DONE_SHIFT <= 0;
        end else if (current_state == FINISH) begin
            DONE <= 1;
        end else begin
            DONE <= 0;
        end
        
        if (current_state == SHIFT_RESULT && !DONE_SHIFT) begin
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < D; j = j + 1) begin
                    result[i][j] <= result[i][j] >>> WIDTH; // Right shift each element by WIDTH bits
                end
            end
            DONE_SHIFT <= 1; // Set DONE_SHIFT when shifting is complete
        end else begin
            DONE_SHIFT <= 0; // Ensure DONE_SHIFT is cleared in other states
        end
    end

endmodule
