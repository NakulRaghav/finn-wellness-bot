// Floating Point Multiplier Implementation
// Format: 1 sign bit + 5 exponent bits + 6 fraction bits = 12 bits
// Exponent bias: +15

module floating_point_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [11:0]  a,      
    input  wire [11:0]  b,      
    input  wire         valid_in,
    output reg  [11:0]  result,
    output reg          valid_out
);

    // Constants
    parameter BIAS = 15;

    // Internal signals
    wire        sign_a, sign_b;
    wire [4:0]  exp_a, exp_b;
    wire [5:0]  frac_a, frac_b;
    wire [6:0]  norm_frac_a, norm_frac_b;
    wire [13:0] frac_mult_result;
    wire        zero_input;
    
    reg  [11:0] mult_result;
    reg  [5:0]  final_frac;
    reg  [4:0]  final_exp;
    reg  signed [7:0] result_exp_temp;
    reg         sign_result;
    reg         underflow, overflow;

    // Extract fields
    assign sign_a = a[11];
    assign exp_a  = a[10:6];
    assign frac_a = a[5:0];
    assign sign_b = b[11];
    assign exp_b  = b[10:6];
    assign frac_b = b[5:0];

    // Check for zero inputs
    assign zero_input = (a == 12'b0) || (b == 12'b0) || (exp_a == 5'b0) || (exp_b == 5'b0);

    // Add implicit leading 1 for normalized numbers
    assign norm_frac_a = {1'b1, frac_a};
    assign norm_frac_b = {1'b1, frac_b};

    // Multiply fractions
    assign frac_mult_result = norm_frac_a * norm_frac_b;

    // Combinational logic for multiplication
    always @(*) begin
        if (zero_input) begin
            mult_result = 12'b000000000000;
        end else begin
            // Calculate result sign
            sign_result = sign_a ^ sign_b;
            
            // Calculate exponent using signed arithmetic
            result_exp_temp = $signed({3'b000, exp_a}) + $signed({3'b000, exp_b}) - $signed({3'b000, 5'd15});
            
            // Handle normalization
            if (frac_mult_result[13] == 1'b1) begin
                final_frac = frac_mult_result[12:7];
                result_exp_temp = result_exp_temp + 1;
            end else begin
                final_frac = frac_mult_result[11:6];
            end
            
            // Check for underflow and overflow
            underflow = (result_exp_temp <= 8'sd0);
            overflow = (result_exp_temp >= 8'sd30);
            
            if (underflow) begin
                mult_result = 12'b000000000000;
            end else if (overflow) begin
                mult_result = 12'b011110110000; // Saturation value
            end else begin
                final_exp = result_exp_temp[4:0];
                mult_result = {sign_result, final_exp, final_frac};
            end
        end
    end

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 12'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                result <= mult_result;
            end
        end
    end

endmodule