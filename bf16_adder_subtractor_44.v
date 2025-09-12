// BF16 Adder/Subtractor with 3-stage pipeline: Align → Add → Normalize
// Student ID ending: 44
// Pipeline depth: 3 cycles
// Supports IEEE 754 BF16 format with Round-to-Nearest-Even (RNE)

module BF16AddSub_44 (
    input wire clk_44,
    input wire rst_n_44,
    input wire [15:0] a_44,     // BF16 input A
    input wire [15:0] b_44,     // BF16 input B
    input wire sub_44,          // 1 for subtraction, 0 for addition
    input wire valid_in_44,
    output reg [15:0] result_44,
    output reg valid_out_44
);

    // BF16 format breakdown
    // Bit 15: Sign
    // Bits 14:7: Exponent (8 bits, bias = 127)
    // Bits 6:0: Mantissa (7 bits, implicit leading 1)

    // Pipeline registers
    reg [15:0] a_stage1_44, b_stage1_44;
    reg [15:0] a_stage2_44, b_stage2_44;
    reg sub_stage1_44, sub_stage2_44;
    reg valid_stage1_44, valid_stage2_44;
    
    // Stage 1: Parse and align operands
    reg sign_a_44, sign_b_44, effective_sign_b_44;
    reg [7:0] exp_a_44, exp_b_44, larger_exp_44;
    reg [8:0] mant_a_extended_44, mant_b_extended_44;  // 9 bits with implicit 1
    reg [8:0] aligned_mant_a_44, aligned_mant_b_44;
    reg [4:0] shift_amount_44;
    reg result_sign_stage1_44;
    reg operands_swapped_44;
    
    // Stage 2: Perform addition/subtraction
    reg [9:0] sum_result_44;  // 10 bits to handle overflow
    reg result_sign_stage2_44;
    reg [7:0] result_exp_stage2_44;
    
    // Stage 3: Normalize and round
    reg [15:0] final_result_44;
    reg [7:0] normalized_exp_44;
    reg [7:0] normalized_mant_44;
    reg [4:0] leading_zeros_44;
    reg round_up_44;

    // Stage 1: Align mantissas
    always @(posedge clk_44 or negedge rst_n_44) begin
        if (!rst_n_44) begin
            valid_stage1_44 <= 1'b0;
            a_stage1_44 <= 16'h0;
            b_stage1_44 <= 16'h0;
            sub_stage1_44 <= 1'b0;
        end else begin
            valid_stage1_44 <= valid_in_44;
            a_stage1_44 <= a_44;
            b_stage1_44 <= b_44;
            sub_stage1_44 <= sub_44;
            
            if (valid_in_44) begin
                // Extract fields
                sign_a_44 <= a_44[15];
                sign_b_44 <= b_44[15];
                exp_a_44 <= a_44[14:7];
                exp_b_44 <= b_44[14:7];
                
                // Determine effective sign of B (considering subtraction)
                effective_sign_b_44 <= b_44[15] ^ sub_44;
                
                // Handle mantissa with implicit leading 1 (or 0 for subnormals)
                if (a_44[14:7] == 8'h00) begin
                    mant_a_extended_44 <= {1'b0, 1'b0, a_44[6:0]};  // Subnormal
                end else begin
                    mant_a_extended_44 <= {1'b0, 1'b1, a_44[6:0]};  // Normal with implicit 1
                end
                
                if (b_44[14:7] == 8'h00) begin
                    mant_b_extended_44 <= {1'b0, 1'b0, b_44[6:0]};  // Subnormal
                end else begin
                    mant_b_extended_44 <= {1'b0, 1'b1, b_44[6:0]};  // Normal with implicit 1
                end
                
                // Determine which exponent is larger and align mantissas
                if (exp_a_44 >= exp_b_44) begin
                    larger_exp_44 <= exp_a_44;
                    shift_amount_44 <= (exp_a_44 > exp_b_44) ? (exp_a_44 - exp_b_44) : 5'h0;
                    operands_swapped_44 <= 1'b0;
                    result_sign_stage1_44 <= sign_a_44;
                end else begin
                    larger_exp_44 <= exp_b_44;
                    shift_amount_44 <= exp_b_44 - exp_a_44;
                    operands_swapped_44 <= 1'b1;
                    result_sign_stage1_44 <= effective_sign_b_44;
                end
            end
        end
    end
    
    // Combinational alignment logic
    always @(*) begin
        if (operands_swapped_44) begin
            // B has larger magnitude
            aligned_mant_b_44 = mant_b_extended_44;
            if (shift_amount_44 >= 5'd9) begin
                aligned_mant_a_44 = 9'h0;  // Shift too large, becomes zero
            end else begin
                aligned_mant_a_44 = mant_a_extended_44 >> shift_amount_44;
            end
        end else begin
            // A has larger or equal magnitude
            aligned_mant_a_44 = mant_a_extended_44;
            if (shift_amount_44 >= 5'd9) begin
                aligned_mant_b_44 = 9'h0;  // Shift too large, becomes zero
            end else begin
                aligned_mant_b_44 = mant_b_extended_44 >> shift_amount_44;
            end
        end
    end

    // Stage 2: Add or subtract aligned mantissas
    always @(posedge clk_44 or negedge rst_n_44) begin
        if (!rst_n_44) begin
            valid_stage2_44 <= 1'b0;
            a_stage2_44 <= 16'h0;
            b_stage2_44 <= 16'h0;
            sub_stage2_44 <= 1'b0;
        end else begin
            valid_stage2_44 <= valid_stage1_44;
            a_stage2_44 <= a_stage1_44;
            b_stage2_44 <= b_stage1_44;
            sub_stage2_44 <= sub_stage1_44;
            result_sign_stage2_44 <= result_sign_stage1_44;
            result_exp_stage2_44 <= larger_exp_44;
            
            if (valid_stage1_44) begin
                // Handle special cases first
                if ((a_stage1_44[14:7] == 8'hFF) || (b_stage1_44[14:7] == 8'hFF)) begin
                    // Infinity or NaN cases
                    if ((a_stage1_44[14:0] == 15'h7F00) && (b_stage1_44[14:0] == 15'h7F00)) begin
                        if (sign_a_44 == effective_sign_b_44) begin
                            // Same sign infinities
                            sum_result_44 <= 10'h200;  // Infinity mantissa pattern
                        end else begin
                            // Opposite sign infinities = NaN
                            sum_result_44 <= 10'h240;  // NaN mantissa pattern
                            result_exp_stage2_44 <= 8'hFF;
                        end
                    end else if (a_stage1_44[14:7] == 8'hFF) begin
                        // A is infinity/NaN
                        sum_result_44 <= {2'b10, aligned_mant_a_44[7:0]};
                        result_exp_stage2_44 <= 8'hFF;
                    end else begin
                        // B is infinity/NaN
                        sum_result_44 <= {2'b10, aligned_mant_b_44[7:0]};
                        result_exp_stage2_44 <= 8'hFF;
                    end
                end else if ((a_stage1_44[14:0] == 15'h0) && (b_stage1_44[14:0] == 15'h0)) begin
                    // Both zero
                    sum_result_44 <= 10'h0;
                    result_exp_stage2_44 <= 8'h00;
                end else if (a_stage1_44[14:0] == 15'h0) begin
                    // A is zero, result is B
                    sum_result_44 <= {1'b0, aligned_mant_b_44};
                    result_sign_stage2_44 <= effective_sign_b_44;
                end else if (b_stage1_44[14:0] == 15'h0) begin
                    // B is zero, result is A
                    sum_result_44 <= {1'b0, aligned_mant_a_44};
                    result_sign_stage2_44 <= sign_a_44;
                end else begin
                    // Normal addition/subtraction
                    if (sign_a_44 == effective_sign_b_44) begin
                        // Same sign: add magnitudes
                        sum_result_44 <= {1'b0, aligned_mant_a_44} + {1'b0, aligned_mant_b_44};
                    end else begin
                        // Opposite signs: subtract magnitudes
                        if (aligned_mant_a_44 >= aligned_mant_b_44) begin
                            sum_result_44 <= {1'b0, aligned_mant_a_44} - {1'b0, aligned_mant_b_44};
                            result_sign_stage2_44 <= sign_a_44;
                        end else begin
                            sum_result_44 <= {1'b0, aligned_mant_b_44} - {1'b0, aligned_mant_a_44};
                            result_sign_stage2_44 <= effective_sign_b_44;
                        end
                    end
                end
            end
        end
    end

    // Stage 3: Normalize and round with RNE
    always @(posedge clk_44 or negedge rst_n_44) begin
        if (!rst_n_44) begin
            valid_out_44 <= 1'b0;
            result_44 <= 16'h0;
        end else begin
            valid_out_44 <= valid_stage2_44;
            
            if (valid_stage2_44) begin
                
                normalized_exp_44 = result_exp_stage2_44;
                
                // Handle zero result
                if (sum_result_44 == 10'h0) begin
                    final_result_44 = {result_sign_stage2_44, 15'h0000};
                end else if (result_exp_stage2_44 == 8'hFF) begin
                    // Infinity or NaN
                    final_result_44 = {result_sign_stage2_44, 8'hFF, sum_result_44[6:0]};
                end else begin
                    // Normalize mantissa
                    if (sum_result_44[9]) begin
                        // Overflow: shift right and increment exponent
                        normalized_mant_44 = sum_result_44[8:1];
                        normalized_exp_44 = result_exp_stage2_44 + 1;
                        
                        // Round-to-Nearest-Even
                        if (sum_result_44[0] && (sum_result_44[1] || |sum_result_44[8:2])) begin
                            round_up_44 = 1'b1;
                        end else begin
                            round_up_44 = 1'b0;
                        end
                    end else if (sum_result_44[8]) begin
                        // Normal case: no shift needed
                        normalized_mant_44 = sum_result_44[7:0];
                        round_up_44 = 1'b0;  // No fractional part to round
                    end else begin
                        // Underflow: find leading zeros and shift left
                        if (sum_result_44[7]) leading_zeros_44 = 5'd1;
                        else if (sum_result_44[6]) leading_zeros_44 = 5'd2;
                        else if (sum_result_44[5]) leading_zeros_44 = 5'd3;
                        else if (sum_result_44[4]) leading_zeros_44 = 5'd4;
                        else if (sum_result_44[3]) leading_zeros_44 = 5'd5;
                        else if (sum_result_44[2]) leading_zeros_44 = 5'd6;
                        else if (sum_result_44[1]) leading_zeros_44 = 5'd7;
                        else if (sum_result_44[0]) leading_zeros_44 = 5'd8;
                        else leading_zeros_44 = 5'd9;
                        
                        if (leading_zeros_44 >= normalized_exp_44) begin
                            // Underflow to zero or subnormal
                            normalized_exp_44 = 8'h00;
                            normalized_mant_44 = 8'h00;
                        end else begin
                            normalized_exp_44 = normalized_exp_44 - leading_zeros_44;
                            normalized_mant_44 = sum_result_44[7:0] << leading_zeros_44;
                        end
                        round_up_44 = 1'b0;
                    end
                    
                    // Apply rounding
                    if (round_up_44) begin
                        if (normalized_mant_44[6:0] == 7'h7F) begin
                            // Mantissa overflow after rounding
                            final_result_44 = {result_sign_stage2_44, (normalized_exp_44 + 8'd1), 7'h00};
                        end else begin
                            final_result_44 = {result_sign_stage2_44, normalized_exp_44, (normalized_mant_44[6:0] + 7'd1)};
                        end
                    end else begin
                        final_result_44 = {result_sign_stage2_44, normalized_exp_44, normalized_mant_44[6:0]};
                    end
                end
                
                result_44 <= final_result_44;
            end
        end
    end

endmodule