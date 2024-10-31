`timescale 1ns / 1ps 

module softmax #(
    parameter N = 4,
    parameter S_WIDTH = 16,
    parameter WIDTH = 32,
    parameter FBITS = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input signed [WIDTH-1:0] In [N-1:0],
    output reg signed [WIDTH-1:0] Out [N-1:0],
    output reg done
);

    // States
    localparam IDLE = 3'd0, CALC_MAXMSB = 3'd1, CALC_EXP = 3'd2, SUM_EXP = 3'd3, DIVIDE = 3'd4;
    reg [2:0] state, next_state;

    // Internal signals
    reg signed [WIDTH-1:0] exp_results [N-1:0];
    reg signed [WIDTH+$clog2(N)+FBITS-1:0] sum_exp;
    reg [N-1:0] exp_done;
    reg [$clog2(N)-1:0] counter;
    
    wire signed [S_WIDTH-1:0] S_exp;
    wire signed [S_WIDTH-1:0] S_const = 512;  // S = 2 in fixed-point

    // I-EXP instance
    wire i_exp_start;
    wire signed [WIDTH-1:0] i_exp_in;
    wire signed [WIDTH-1:0] i_exp_out;
    wire i_exp_done;
    reg [$clog2(WIDTH):0] maxmsb;

    i_exp #(
        .Q_WIDTH(WIDTH),
        .S_WIDTH(S_WIDTH),
        .FBITS(FBITS)
    ) i_exp_inst (
        .clk(clk),
        .rst(rst),
        .start(i_exp_start),
        .q(i_exp_in),
        .maxmsb(maxmsb),
        .S(S_const),
        .q_out(i_exp_out),
        .S_out(S_exp),
        .done(i_exp_done)
    );

    // MaxMSB instance
    reg maxmsb_start;
    wire maxmsb_done;
    wire [$clog2(WIDTH):0] msb_index;

    MaxMSB #(WIDTH, N) uut (
        .clk(clk),
        .reset(rst),
        .start(maxmsb_start),
        .In(In),
        .msb_index(msb_index),
        .done(maxmsb_done)
    );

    // Division instance
    wire div_start;
    wire signed [WIDTH+$clog2(N)+FBITS-1:0] div_a, div_b;
    wire signed [WIDTH-1:0] div_out;
    wire div_done;

    divi #(
        .WIDTH(WIDTH+FBITS+$clog2(N)),
        .FBITS(FBITS)
    ) div_inst (
        .clk(clk),
        .rst(rst),
        .start(div_start),
        .busy(),
        .done(div_done),
        .valid(),
        .dbz(),
        .ovf(),
        .a(div_a),
        .b(div_b),
        .val(div_out)
    );

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = CALC_MAXMSB;
            CALC_MAXMSB: if (maxmsb_done) next_state = CALC_EXP;
            CALC_EXP: if (&exp_done) next_state = SUM_EXP;
            SUM_EXP: if (counter == N-1) next_state = DIVIDE;
            DIVIDE: if (counter == N-1 && div_done) next_state = IDLE;
        endcase
    end

    // Datapath
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < N; i = i + 1) begin
                exp_results[i] <= 0;
                Out[i] <= 0;
            end
            sum_exp <= 0;
            exp_done <= 0;
            counter <= 0;
            done <= 0;
            maxmsb <= 0;
            maxmsb_start <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        exp_done <= 0;
                        counter <= 0;
                        sum_exp <= 0;
                        done <= 0;
                        maxmsb_start <= 1;
                    end
                end
                CALC_MAXMSB: begin
                    maxmsb_start <= 0;
                    if (maxmsb_done) begin
                        if(msb_index < 7)
                            maxmsb <= msb_index + 5;
                        else if (msb_index < 11)
                            maxmsb <= msb_index + 2;
                        else if(msb_index < 16)
                            maxmsb <= msb_index;
                        else
                            maxmsb <= 2;
                    end
                end
                CALC_EXP: begin
                    if (i_exp_done) begin
                        exp_results[counter] <= i_exp_out;
                        exp_done[counter] <= 1;
                        counter <= counter + 1;
                    end
                end
                SUM_EXP: begin
                    sum_exp <= sum_exp + exp_results[counter];
                    counter <= counter + 1;
                end
                DIVIDE: begin
                    if (div_done) begin
                        Out[counter] <= div_out;
                        if (counter == N-1) begin
                            done <= 1;
                        end
                        counter <= counter + 1;
                    end
                end
            endcase
        end
    end

    // Control signals
    assign i_exp_start = (state == CALC_EXP) && !exp_done[counter];
    assign i_exp_in = In[counter] >>> 1;
    assign div_start = (state == DIVIDE) && !div_done;
    assign div_a = exp_results[counter] <<< FBITS;
    assign div_b = sum_exp <<< FBITS;

endmodule
