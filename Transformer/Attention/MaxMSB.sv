module MaxMSB #(parameter WIDTH = 8, parameter N = 4) (
    input clk,
    input reset,
    input start,
    input signed [WIDTH-1:0] In [N-1:0],
    output reg [$clog2(WIDTH):0] msb_index,  // Sufficient width to store values from 0 to WIDTH-1
    output reg done
);
    reg [$clog2(N):0] i;                   // Index for looping over input array
    reg [$clog2(WIDTH):0] j;                 // Index for finding MSB
    reg signed [WIDTH-1:0] max_value;
    reg finding_max;                         // State to indicate finding maximum value
    reg finding_msb;                         // State to indicate finding the MSB

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all signals to initial state
            msb_index <= 0;
            done <= 0;
            i <= 0;
            j <= WIDTH-1;
            max_value <= - (1 << (WIDTH-1)); // Lowest signed value
            finding_max <= 0;
            finding_msb <= 0;
        end
        else if (start) begin
            // Begin the maximum finding process when start is asserted
            done <= 0;
            i <= 0;
            j <= WIDTH-1;
            max_value <= - (1 << (WIDTH-1));
            finding_max <= 1;
            finding_msb <= 0;
            msb_index <= 0;
        end
        else if (finding_max) begin
            // Finding the maximum value
            if (i < N) begin
                if (In[i] > max_value)
                    max_value <= In[i];
                i <= i + 1;
            end else begin
                // Move to finding the MSB after maximum value is found
                finding_max <= 0;
                finding_msb <= 1;
                j <= WIDTH-1;
            end
        end
        else if (finding_msb) begin
            // Finding the most significant bit (MSB) that isn't 0
            if (j >= 0) begin
                if (max_value[j] == 1) begin
                    msb_index <= j;
                    finding_msb <= 0;
                    done <= 1;              // Operation complete
                end else begin
                    j <= j - 1;
                end
            end else begin
                finding_msb <= 0;
                done <= 1;                  // Operation complete
            end
        end
    end
endmodule
