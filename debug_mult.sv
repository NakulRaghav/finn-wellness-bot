// Debug version with explicit intermediate value monitoring

module debug_mult (
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

    // Combinational logic with debug outputs
    always @(*) begin
        // Debug prints
        if (valid_in) begin
            $display("DEBUG: Processing inputs a=%b, b=%b", a, b);
            $display("  sign_a=%b, exp_a=%d, frac_a=%b", sign_a, exp_a, frac_a);
            $display("  sign_b=%b, exp_b=%d, frac_b=%b", sign_b, exp_b, frac_b);
            $display("  zero_input=%b", zero_input);
            $display("  norm_frac_a=%b (%d), norm_frac_b=%b (%d)", norm_frac_a, norm_frac_a, norm_frac_b, norm_frac_b);
            $display("  frac_mult_result=%b (%d)", frac_mult_result, frac_mult_result);
        end
        
        if (zero_input) begin
            mult_result = 12'b000000000000;
            if (valid_in) $display("  Result: ZERO (zero input)");
        end else begin
            // Calculate result sign
            sign_result = sign_a ^ sign_b;
            
            // Calculate exponent using signed arithmetic
            result_exp_temp = $signed({3'b000, exp_a}) + $signed({3'b000, exp_b}) - $signed({3'b000, 5'd15});
            
            if (valid_in) begin
                $display("  sign_result=%b", sign_result);
                $display("  exp calculation: %d + %d - %d = %d", exp_a, exp_b, 15, result_exp_temp);
            end
            
            // Handle normalization
            if (frac_mult_result[13] == 1'b1) begin
                final_frac = frac_mult_result[12:7];
                result_exp_temp = result_exp_temp + 1;
                if (valid_in) $display("  Normalize: MSB=1, shift right, final_frac=%b, exp=%d", final_frac, result_exp_temp);
            end else begin
                final_frac = frac_mult_result[11:6];
                if (valid_in) $display("  Normalize: MSB=0, no shift, final_frac=%b, exp=%d", final_frac, result_exp_temp);
            end
            
            // Check for underflow and overflow
            underflow = (result_exp_temp <= 8'sd0);
            overflow = (result_exp_temp >= 8'sd30);
            
            if (valid_in) begin
                $display("  underflow=%b (exp <= 0), overflow=%b (exp >= 30)", underflow, overflow);
            end
            
            if (underflow) begin
                mult_result = 12'b000000000000;
                if (valid_in) $display("  Result: ZERO (underflow)");
            end else if (overflow) begin
                mult_result = 12'b011110110000;
                if (valid_in) $display("  Result: SATURATED");
            end else begin
                final_exp = result_exp_temp[4:0];
                mult_result = {sign_result, final_exp, final_frac};
                if (valid_in) $display("  Result: %b (sign=%b, exp=%d, frac=%b)", mult_result, sign_result, final_exp, final_frac);
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