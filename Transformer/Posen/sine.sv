module sine #(
    parameter WIDTH = 16,    
    parameter FBITS = 8      
) (
    input  wire clk,                    
    input  wire rst,                    
    input  wire start,                  
    input  wire signed [WIDTH-1:0] in,  // Integer degrees input
    output reg  signed [WIDTH-1:0] out, 
    output reg  done                    
);

    // Constants
    localparam LUT_SIZE = 256;  
    localparam LUT_ADDR_WIDTH = 8;  // Fixed for 256 entries
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam SCALE = 2'b01;
    localparam LOOKUP = 2'b10;
    localparam OUTPUT = 2'b11;

    // Registers
    reg [1:0] state;
    reg [LUT_ADDR_WIDTH-1:0] lut_index;
    reg [31:0] scaled_value; // Wider for multiplication
    reg angle_is_negative;
    reg [WIDTH-1:0] abs_angle;

    // LUT with sine values scaled to fixed point
    reg signed [15:0] sine_lut [0:LUT_SIZE-1] = {
    16'h0000, 16'h0324, 16'h0647, 16'h096A, 16'h0C8B, 16'h0FAB, 16'h12C7, 16'h15E1,
    16'h18F8, 16'h1C0B, 16'h1F19, 16'h2223, 16'h2527, 16'h2826, 16'h2B1E, 16'h2E10,
    16'h30FB, 16'h33DE, 16'h36B9, 16'h398C, 16'h3C56, 16'h3F16, 16'h41CD, 16'h447A,
    16'h471C, 16'h49B3, 16'h4C3F, 16'h4EBF, 16'h5133, 16'h539A, 16'h55F4, 16'h5842,
    16'h5A81, 16'h5CB3, 16'h5ED6, 16'h60EB, 16'h62F1, 16'h64E7, 16'h66CE, 16'h68A5,
    16'h6A6C, 16'h6C23, 16'h6DC9, 16'h6F5E, 16'h70E1, 16'h7254, 16'h73B5, 16'h7503,
    16'h7640, 16'h776B, 16'h7883, 16'h7989, 16'h7A7C, 16'h7B5C, 16'h7C29, 16'h7CE2,
    16'h7D89, 16'h7E1C, 16'h7E9C, 16'h7F08, 16'h7F61, 16'h7FA6, 16'h7FD7, 16'h7FF5,
    16'h7FFF, 16'h7FF5, 16'h7FD7, 16'h7FA6, 16'h7F61, 16'h7F08, 16'h7E9C, 16'h7E1C,
    16'h7D89, 16'h7CE2, 16'h7C29, 16'h7B5C, 16'h7A7C, 16'h7989, 16'h7883, 16'h776B,
    16'h7640, 16'h7503, 16'h73B5, 16'h7254, 16'h70E1, 16'h6F5E, 16'h6DC9, 16'h6C23,
    16'h6A6C, 16'h68A5, 16'h66CE, 16'h64E7, 16'h62F1, 16'h60EB, 16'h5ED6, 16'h5CB3,
    16'h5A81, 16'h5842, 16'h55F4, 16'h539A, 16'h5133, 16'h4EBF, 16'h4C3F, 16'h49B3,
    16'h471C, 16'h447A, 16'h41CD, 16'h3F16, 16'h3C56, 16'h398C, 16'h36B9, 16'h33DE,
    16'h30FB, 16'h2E10, 16'h2B1E, 16'h2826, 16'h2527, 16'h2223, 16'h1F19, 16'h1C0B,
    16'h18F8, 16'h15E1, 16'h12C7, 16'h0FAB, 16'h0C8B, 16'h096A, 16'h0647, 16'h0324,
    16'h0000, 16'hFCDC, 16'hF9B9, 16'hF696, 16'hF375, 16'hF055, 16'hED39, 16'hEA1F,
    16'hE708, 16'hE3F5, 16'hE0E7, 16'hDDDD, 16'hDAD9, 16'hD7DA, 16'hD4E2, 16'hD1F0,
    16'hCF05, 16'hCC22, 16'hC947, 16'hC674, 16'hC3AA, 16'hC0EA, 16'hBE33, 16'hBB86,
    16'hB8E4, 16'hB64D, 16'hB3C1, 16'hB141, 16'hAECD, 16'hAC66, 16'hAA0C, 16'hA7BE,
    16'hA57F, 16'hA34D, 16'hA12A, 16'h9F15, 16'h9D0F, 16'h9B19, 16'h9932, 16'h975B,
    16'h9594, 16'h93DD, 16'h9237, 16'h90A2, 16'h8F1F, 16'h8DAC, 16'h8C4B, 16'h8AFD,
    16'h89C0, 16'h8895, 16'h877D, 16'h8677, 16'h8584, 16'h84A4, 16'h83D7, 16'h831E,
    16'h8277, 16'h81E4, 16'h8164, 16'h80F8, 16'h809F, 16'h805A, 16'h8029, 16'h800B,
    16'h8001, 16'h800B, 16'h8029, 16'h805A, 16'h809F, 16'h80F8, 16'h8164, 16'h81E4,
    16'h8277, 16'h831E, 16'h83D7, 16'h84A4, 16'h8584, 16'h8677, 16'h877D, 16'h8895,
    16'h89C0, 16'h8AFD, 16'h8C4B, 16'h8DAC, 16'h8F1F, 16'h90A2, 16'h9237, 16'h93DD,
    16'h9594, 16'h975B, 16'h9932, 16'h9B19, 16'h9D0F, 16'h9F15, 16'hA12A, 16'hA34D,
    16'hA57F, 16'hA7BE, 16'hAA0C, 16'hAC66, 16'hAECD, 16'hB141, 16'hB3C1, 16'hB64D,
    16'hB8E4, 16'hBB86, 16'hBE33, 16'hC0EA, 16'hC3AA, 16'hC674, 16'hC947, 16'hCC22,
    16'hCF05, 16'hD1F0, 16'hD4E2, 16'hD7DA, 16'hDAD9, 16'hDDDD, 16'hE0E7, 16'hE3F5,
    16'hE708, 16'hEA1F, 16'hED39, 16'hF055, 16'hF375, 16'hF696, 16'hF9B9, 16'hFCDC
    };

    // Combinational logic for absolute value
    wire [WIDTH-1:0] abs_in = (in[WIDTH-1]) ? (-in) : in;
    
    // Combinational logic for modulo 360
    // We use comparison and subtraction instead of modulo
    wire [WIDTH-1:0] mod360_in = (abs_in >= 360) ? 
                                 (abs_in >= 720) ? 
                                 (abs_in - 720) : 
                                 (abs_in - 360) : 
                                 abs_in;

    // FSM Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 1'b0;
            out <= 0;
            lut_index <= 0;
            angle_is_negative <= 0;
            scaled_value <= 0;
            abs_angle <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= SCALE;
                        done <= 1'b0;
                        angle_is_negative <= in[WIDTH-1];
                        abs_angle <= mod360_in;
                    end
                end

                SCALE: begin
                    // Convert degree to LUT index: (degree * 256) / 360
                    // Multiply by 256 first (left shift by 8)
                    scaled_value <= mod360_in << 8;
                    state <= LOOKUP;
                end

                LOOKUP: begin
                    // Divide by 360 using a close approximation
                    // 256/360 ≈ 0.711111... 
                    // We can use (x * 183) >> 8 as an approximation for x * (256/360)
                    // 183/256 ≈ 0.714844... which is close enough for our needs
                    lut_index <= (scaled_value * 183) >> 16;
                    state <= OUTPUT;
                end

                OUTPUT: begin
                    if (angle_is_negative) begin
                        out <= (-sine_lut[lut_index]) >>> (15-FBITS);
                    end else begin
                        out <= sine_lut[lut_index] >>> (15-FBITS);
                    end
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule