module i_exp #(
    parameter Q_WIDTH = 32,
    parameter S_WIDTH = 16,
    parameter FBITS = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [Q_WIDTH-1:0] q,
    input reg signed [Q_WIDTH-1:0] maxmsb,
    input wire signed [S_WIDTH-1:0] S,
    output reg signed [Q_WIDTH-1:0] q_out,
    output reg signed [S_WIDTH-1:0] S_out,
    output reg done
);

// Constants
localparam signed [Q_WIDTH-1:0] A = 92; // -73 in two's complement (-0.2888)
localparam signed [Q_WIDTH-1:0] B = 346; // -452 in two's complement (-1.769)
localparam signed [Q_WIDTH-1:0] C = 88; // 256 in two's complement (1)
localparam signed [Q_WIDTH-1:0] LN2 = 177; // ln(2) ≈ 0.693 in fixed-point with 8 fractional bits

// State machine states
localparam IDLE = 4'd0, CALC_QLN2 = 4'd1, CALC_Z_START = 4'd2, CALC_Z_WAIT = 4'd3, 
           CALC_QP = 4'd4, CALC_IPOLY = 4'd5, SHIFT = 4'd6, DONE = 4'd7;
reg [3:0] state, next_state;
reg sign;

// Internal registers
reg signed [Q_WIDTH-1:0] q_ln2, z, qp, qL, q_ln2_frac, q_frac;
reg signed [S_WIDTH-1:0] SL;
reg [Q_WIDTH -1:0] abs_value;
reg div_start, div_z_start, ipoly_start;

// Separate signals for div_ln2
wire div_ln2_done, div_ln2_valid, div_ln2_dbz, div_ln2_ovf;
wire signed [Q_WIDTH-1:0] div_ln2_result;

// Separate signals for div_z
wire div_z_done, div_z_valid, div_z_dbz, div_z_ovf;
wire signed [Q_WIDTH-1:0] div_z_result;

wire ipoly_done;
wire signed [Q_WIDTH-1:0] ipoly_q_out;
wire signed [S_WIDTH-1:0] ipoly_S_out;

// Divider instance for q_ln2 calculation
divi #(
    .WIDTH(Q_WIDTH),
    .FBITS(FBITS)
) div_ln2 (
    .clk(clk),
    .rst(rst),
    .start(div_start),
    .busy(),
    .done(div_ln2_done),
    .valid(div_ln2_valid),
    .dbz(div_ln2_dbz),
    .ovf(div_ln2_ovf),
    .a(LN2),
    .b({{(Q_WIDTH-S_WIDTH){1'b0}}, S}),  // Extend S to match the format of b
    .val(div_ln2_result)
);

// Divider instance for z calculation
divi #(
    .WIDTH(Q_WIDTH),
    .FBITS(FBITS)
) div_z (
    .clk(clk),
    .rst(rst),
    .start(div_z_start),
    .busy(),
    .done(div_z_done),
    .valid(div_z_valid),
    .dbz(div_z_dbz),
    .ovf(div_z_ovf),
    .a(-q_frac),  // Negation of q
    .b(q_ln2_frac),
    .val(div_z_result)
);

// I-POLY module instance
integer_polynomial #(
    .Q_WIDTH(Q_WIDTH),
    .S_WIDTH(S_WIDTH),
    .FBITS(FBITS)
) ipoly (
    .clk(clk),
    .rst(rst),
    .start(ipoly_start),
    .q(qp),
    .S(S),
    .a(A),
    .b(B),
    .c(C),
    .q_out(ipoly_q_out),
    .S_out(ipoly_S_out),
    .done(ipoly_done)
);

// State machine
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    next_state = state;
    case (state)
        IDLE: begin 
            if (start && !q[Q_WIDTH-1])
                next_state = CALC_QLN2;
            else if(start)
                next_state <= DONE;
        end
        CALC_QLN2: begin
            if (!start)
                next_state = IDLE;
            else if(div_ln2_done) 
                next_state = CALC_Z_START;
        end
        CALC_Z_START: next_state = CALC_Z_WAIT;
        CALC_Z_WAIT: if (div_z_done) next_state = CALC_QP;
        CALC_QP: next_state = CALC_IPOLY;
        CALC_IPOLY: if (ipoly_done) next_state = SHIFT;
        SHIFT: next_state = DONE;
        DONE: next_state = IDLE;
    endcase
end

// Datapath
always @(posedge clk or posedge rst) begin
    if (rst) begin
        q_ln2 <= 0;
        z <= 0;
        qp <= 0;
        qL <= 0;
        SL <= 0;
        q_out <= 0;
        S_out <= 0;
        done <= 0;
        div_start <= 0;
        div_z_start <= 0;
        ipoly_start <= 0;
    end else begin
        case (state)
            IDLE: begin
                done <= 0;
                if (start) begin
                    if(q[Q_WIDTH-1]) begin
                        q_out <= 0;
                        S_out <= 0;
                    end
                    else begin
                        div_start <= 1;
                    end
                end
            end
            CALC_QLN2: begin
                div_start <= 0;
                if (div_ln2_done) begin
                    sign = div_ln2_result[Q_WIDTH-1];  // Store the sign bit
                    abs_value = sign ? -div_ln2_result : div_ln2_result;  // Get absolute value
                    q_ln2_frac <= sign ? -abs_value - 1'b1 : abs_value;  // Reapply the sign  
                    abs_value = abs_value >> FBITS;  // Perform the shift
                    q_ln2 <= sign ? -abs_value - 1'b1 : abs_value;  // Reapply the sign  
                end
                q_frac <= q <<< FBITS;
            end
            CALC_Z_START: begin
                div_z_start <= 1;
            end
            CALC_Z_WAIT: begin
                div_z_start <= 0;
                if (div_z_done) begin
                    sign = div_z_result[Q_WIDTH-1];  // Store the sign bit
                    abs_value = sign ? -div_z_result : div_z_result;  // Get absolute value
                    abs_value = abs_value >> FBITS;  // Perform the shift
                    z <= sign ? -abs_value - 1'b1 : abs_value;  // Reapply the sign
                end
            end
            CALC_QP: begin
                qp <= q + (z * q_ln2);
                ipoly_start <= 1;
            end
            CALC_IPOLY: begin
                ipoly_start <= 0;
                if (ipoly_done) begin
                    qL <= ipoly_q_out;
                    SL <= ipoly_S_out;
                end
            end
            SHIFT: begin
                if(z[Q_WIDTH-1]) begin
                    abs_value = -z;
                    if(abs_value > maxmsb) begin
                        q_out = qL <<< maxmsb; // Arithmetic left shift
                    end
                    else begin
                        q_out = qL <<< abs_value; // Arithmetic left shift
                    end
                end
                else begin
                    abs_value = z;
                    if(abs_value > maxmsb) begin
                        q_out = qL >>> maxmsb; // Arithmetic right shift
                    end
                    else begin
                        q_out = qL >>> abs_value; // Arithmetic right shift
                    end
                end
                S_out <= SL;
            end
            DONE: begin
                done <= 1;
            end
        endcase
    end
end

endmodule