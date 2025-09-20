// Debug version of floating point multiplier - simplified for debugging

module floating_point_multiplier_debug (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [11:0]  a,      
    input  wire [11:0]  b,      
    input  wire         valid_in,
    output reg  [11:0]  result,
    output reg          valid_out
);

    // Debug version - just check basic functionality first
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 12'b0;
            valid_out <= 1'b0;
        end else begin
            // Register the valid signal and data on the same cycle
            valid_out <= valid_in;
            if (valid_in) begin
                result <= a;  // Simple pass-through for debugging
            end
        end
    end

endmodule