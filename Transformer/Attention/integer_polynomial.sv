`timescale 1ns / 1ps

module integer_polynomial #(
    parameter Q_WIDTH = 32,
    parameter S_WIDTH = 16,
    parameter FBITS = 8  // Fractional bits for fixed-point arithmetic
)(
    input wire clk,
    input wire rst,  // Active-high reset
    input wire start,
    
    input wire signed [Q_WIDTH-1:0] q,  // Input q int
    input wire signed [S_WIDTH-1:0] S,  // Input S (fixed-point)
    input wire signed [Q_WIDTH-1:0] a,  // Input a (fixed-point)
    input wire signed [Q_WIDTH-1:0] b,  // Input b (fixed-point)
    input wire signed [Q_WIDTH-1:0] c,  // Input c (fixed-point)
    
    output reg signed [Q_WIDTH-1:0] q_out,  // Output q_out
    output reg signed [S_WIDTH-1:0] S_out,  // Output S_out (integer)
    output reg done  // Done signal
);

    // State machine
    localparam IDLE = 3'd0, DIV_B = 3'd1, WAIT_B = 3'd2, 
               DIV_C = 3'd3, WAIT_C = 3'd4, FINALIZE = 3'd5;
    reg [2:0] state;
    reg sign;
    
    // Intermediate registers
    reg signed [Q_WIDTH-1:0] q_b;
    reg [Q_WIDTH -1:0] abs_value;
    reg signed [Q_WIDTH-1:0] q_c;
    reg signed [Q_WIDTH-1:0] q_plus_qb;
    reg signed [2*S_WIDTH-1:0] S_squared;
    reg signed [Q_WIDTH+2*S_WIDTH-1:0] aS_squared;

    // Divider control signals and outputs
    wire start_div_b;
    wire signed [Q_WIDTH-1:0] div_b_result;
    wire div_b_done;
    wire div_b_valid;
    wire div_b_dbz;
    
    wire start_div_c;
    wire signed [Q_WIDTH-1:0] div_c_result;
    wire div_c_done;
    wire div_c_valid;
    wire div_c_dbz;

    // Control signals for dividers
    assign start_div_b = (state == DIV_B);
    assign start_div_c = (state == DIV_C);

    // Instantiate the division for b/S
    divi #(
        .WIDTH(Q_WIDTH),
        .FBITS(FBITS)
    ) div_b (
        .clk(clk),
        .rst(rst),
        .start(start_div_b),
        .busy(),
        .done(div_b_done),
        .valid(div_b_valid),
        .dbz(div_b_dbz),
        .a(b),
        .b({{(Q_WIDTH-S_WIDTH){1'b0}}, S}),  // Extend S to match the format of b
        .val(div_b_result)
    );

    // Instantiate the division for c/(a * S^2)
    divi #(
        .WIDTH(Q_WIDTH),
        .FBITS(FBITS)
    ) div_c (
        .clk(clk),
        .rst(rst),
        .start(start_div_c),
        .busy(),
        .done(div_c_done),
        .valid(div_c_valid),
        .dbz(div_c_dbz),
        .a(c),
        .b(aS_squared[Q_WIDTH-1:0]),
        .val(div_c_result)
    );

    // State machine logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            q_b <= 0;
            q_c <= 0;
            q_plus_qb <= 0;
            S_squared <= 0;
            aS_squared <= 0;
            S_out <= 0;
            q_out <= 0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= DIV_B;
                        S_squared <= (S * S) >> FBITS;  // Convert S squared to fixed-point
                    end
                    done <= 1'b0;
                end
                
                DIV_B: begin
                    state <= WAIT_B;
                end
                
                WAIT_B: begin
                    if (div_b_done && div_b_valid && !div_b_dbz) begin
                        sign = div_b_result[Q_WIDTH-1];  // Store the sign bit
                        abs_value = sign ? -div_b_result : div_b_result;  // Get absolute value
                        abs_value = abs_value >> FBITS;  // Perform the shift
                        q_b <= sign ? -abs_value - 1'b1 : abs_value;  // Reapply the sign
                        aS_squared <= (a * S_squared) >> FBITS;
                        state <= DIV_C;
                    end else if (div_b_done && (div_b_dbz || !div_b_valid)) begin
                        // Error handling for division by zero or invalid result
                        state <= IDLE;
                        done <= 1'b1;
                    end
                end
                
                DIV_C: begin
                    state <= WAIT_C;
                    sign = aS_squared[Q_WIDTH+2*S_WIDTH-1];  // Store the sign bit
                    abs_value = sign ? -aS_squared : aS_squared;  // Get absolute value
                    abs_value = abs_value >> FBITS;  // Perform the shift
                    S_out <= sign ? -abs_value - 1'b1 : abs_value;  // Reapply the sign
                end
                
                WAIT_C: begin
                    if (div_c_done && div_c_valid && !div_c_dbz) begin
                        sign = div_c_result[Q_WIDTH-1];  // Store the sign bit
                        abs_value = sign ? -div_c_result : div_c_result;  // Get absolute value
                        abs_value = abs_value >> FBITS;  // Perform the shift
                        q_c <= sign ? -abs_value - 1'b1 : abs_value;  // Reapply the sign
                        q_plus_qb <= q + q_b;
                        state <= FINALIZE;
                    end else if (div_c_done && (div_c_dbz || !div_c_valid)) begin
                        // Error handling for division by zero or invalid result
                        state <= IDLE;
                        done <= 1'b1;
                    end
                end
                
                FINALIZE: begin
                    q_out <= q_plus_qb * q_plus_qb + q_c;  // Final result
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
