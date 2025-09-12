// BF16 Multiplier with 3-stage pipeline: Multiply → Normalize → Round
// Student ID ending: 44
// Pipeline depth: 3 cycles
// Supports IEEE 754 BF16 format: 1 sign + 8 exp + 7 mantissa bits

module BF16Mul_44 (
    input wire clk_44,
    input wire rst_n_44,
    input wire [15:0] a_44,     // BF16 input A
    input wire [15:0] b_44,     // BF16 input B
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
    reg valid_stage1_44, valid_stage2_44;
    
    // Stage 1: Parse inputs and multiply mantissas
    reg sign1_44, sign2_44;
    reg [7:0] exp1_44, exp2_44;
    reg [7:0] mant1_44, mant2_44;  // With implicit leading 1
    reg [15:0] mant_product_44;
    reg [8:0] exp_sum_44;
    reg result_sign_stage1_44;
    
    // Stage 2: Normalize result
    reg [15:0] normalized_mant_44;
    reg [7:0] normalized_exp_44;
    reg result_sign_stage2_44;
    reg [4:0] leading_zeros_44;
    
    // Stage 3: Round and pack result
    reg [15:0] final_result_44;
    reg [7:0] rounded_mant_44;
    reg round_up_44;
    reg guard_bit_44, round_bit_44, sticky_bit_44;

    // Stage 1: Multiply
    always @(posedge clk_44 or negedge rst_n_44) begin
        if (!rst_n_44) begin
            valid_stage1_44 <= 1'b0;
            a_stage1_44 <= 16'h0;
            b_stage1_44 <= 16'h0;
        end else begin
            valid_stage1_44 <= valid_in_44;
            a_stage1_44 <= a_44;
            b_stage1_44 <= b_44;
            
            if (valid_in_44) begin
                // Extract fields
                sign1_44 <= a_44[15];
                sign2_44 <= b_44[15];
                exp1_44 <= a_44[14:7];
                exp2_44 <= b_44[14:7];
                
                // Handle mantissa with implicit leading 1
                // Special case: if exponent is 0, number is subnormal (no implicit 1)
                if (a_44[14:7] == 8'h00) begin
                    mant1_44 <= {1'b0, a_44[6:0]};  // Subnormal: no implicit 1
                end else begin
                    mant1_44 <= {1'b1, a_44[6:0]};  // Normal: implicit 1
                end
                
                if (b_44[14:7] == 8'h00) begin
                    mant2_44 <= {1'b0, b_44[6:0]};  // Subnormal: no implicit 1
                end else begin
                    mant2_44 <= {1'b1, b_44[6:0]};  // Normal: implicit 1
                end
                
                // Calculate result sign
                result_sign_stage1_44 <= sign1_44 ^ sign2_44;
                
                // Add exponents (subtract bias once)
                exp_sum_44 <= exp1_44 + exp2_44 - 8'd127;
            end
        end
    end
    
    // Combinational multiply for mantissas
    always @(*) begin
        mant_product_44 = mant1_44 * mant2_44;
    end

    // Stage 2: Normalize
    always @(posedge clk_44 or negedge rst_n_44) begin
        if (!rst_n_44) begin
            valid_stage2_44 <= 1'b0;
            a_stage2_44 <= 16'h0;
            b_stage2_44 <= 16'h0;
        end else begin
            valid_stage2_44 <= valid_stage1_44;
            a_stage2_44 <= a_stage1_44;
            b_stage2_44 <= b_stage1_44;
            result_sign_stage2_44 <= result_sign_stage1_44;
            
            if (valid_stage1_44) begin
                // Check for special cases first
                if ((a_stage1_44[14:7] == 8'hFF) || (b_stage1_44[14:7] == 8'hFF)) begin
                    // Infinity or NaN cases
                    if ((a_stage1_44[14:0] == 15'h7F00) || (b_stage1_44[14:0] == 15'h7F00)) begin
                        // Pure infinity
                        normalized_exp_44 <= 8'hFF;
                        normalized_mant_44 <= 16'h0;
                    end else begin
                        // NaN
                        normalized_exp_44 <= 8'hFF;
                        normalized_mant_44 <= 16'h4000;  // Quiet NaN
                    end
                end else if ((a_stage1_44[14:0] == 15'h0) || (b_stage1_44[14:0] == 15'h0)) begin
                    // Zero result
                    normalized_exp_44 <= 8'h00;
                    normalized_mant_44 <= 16'h0;
                end else begin
                    // Normal multiplication result normalization
                    if (mant_product_44[15]) begin
                        // Result >= 2.0, shift right and increment exponent
                        normalized_mant_44 <= mant_product_44 >> 1;
                        normalized_exp_44 <= exp_sum_44[7:0] + 1;
                    end else begin
                        // Result < 2.0, no shift needed
                        normalized_mant_44 <= mant_product_44;
                        normalized_exp_44 <= exp_sum_44[7:0];
                    end
                    
                    // Check for overflow/underflow
                    if (exp_sum_44 > 9'h0FE) begin
                        // Overflow to infinity
                        normalized_exp_44 <= 8'hFF;
                        normalized_mant_44 <= 16'h0;
                    end else if (exp_sum_44 < 9'h001) begin
                        // Underflow to zero (or subnormal - simplified to zero)
                        normalized_exp_44 <= 8'h00;
                        normalized_mant_44 <= 16'h0;
                    end
                end
            end
        end
    end

    // Stage 3: Round to Nearest Even (RNE) and pack result
    always @(posedge clk_44 or negedge rst_n_44) begin
        if (!rst_n_44) begin
            valid_out_44 <= 1'b0;
            result_44 <= 16'h0;
        end else begin
            valid_out_44 <= valid_stage2_44;
            
            if (valid_stage2_44) begin
                // Round-to-Nearest-Even implementation
                
                // Extract guard, round, and sticky bits from mantissa product
                guard_bit_44 = normalized_mant_44[8];  // Bit position 8
                round_bit_44 = normalized_mant_44[7];  // Bit position 7
                sticky_bit_44 = |normalized_mant_44[6:0];  // OR of bits 6:0
                
                // Round to nearest, ties to even
                if (guard_bit_44 && (round_bit_44 || sticky_bit_44 || normalized_mant_44[9])) begin
                    round_up_44 = 1'b1;
                end else begin
                    round_up_44 = 1'b0;
                end
                
                // Apply rounding to mantissa
                if (round_up_44) begin
                    rounded_mant_44 = normalized_mant_44[15:8] + 1;
                    // Check for mantissa overflow after rounding
                    if (rounded_mant_44 == 8'h80) begin  // Mantissa overflow
                        final_result_44 = {result_sign_stage2_44, (normalized_exp_44 + 8'd1), 7'h00};
                    end else begin
                        final_result_44 = {result_sign_stage2_44, normalized_exp_44, rounded_mant_44[6:0]};
                    end
                end else begin
                    final_result_44 = {result_sign_stage2_44, normalized_exp_44, normalized_mant_44[14:8]};
                end
                
                result_44 <= final_result_44;
            end
        end
    end

endmodule