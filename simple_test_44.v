// Simple test for BF16 operations
`timescale 1ns / 1ps

module simple_test_44;
    reg clk_44;
    reg rst_n_44;
    
    // Test multiplier
    reg [15:0] mul_a_44, mul_b_44;
    reg mul_valid_in_44;
    wire [15:0] mul_result_44;
    wire mul_valid_out_44;
    
    // Test adder  
    reg [15:0] add_a_44, add_b_44;
    reg add_valid_in_44;
    wire [15:0] add_result_44;
    wire add_valid_out_44;
    
    BF16Mul_44 mul_test_44 (
        .clk_44(clk_44),
        .rst_n_44(rst_n_44),
        .a_44(mul_a_44),
        .b_44(mul_b_44),
        .valid_in_44(mul_valid_in_44),
        .result_44(mul_result_44),
        .valid_out_44(mul_valid_out_44)
    );
    
    BF16AddSub_44 add_test_44 (
        .clk_44(clk_44),
        .rst_n_44(rst_n_44),
        .a_44(add_a_44),
        .b_44(add_b_44),
        .sub_44(1'b0),
        .valid_in_44(add_valid_in_44),
        .result_44(add_result_44),
        .valid_out_44(add_valid_out_44)
    );
    
    // Clock generation
    initial begin
        clk_44 = 0;
        forever #5 clk_44 = ~clk_44;
    end
    
    function real bf16_to_real;
        input [15:0] bf16_val;
        reg sign_bit;
        reg [7:0] exp_bits;
        reg [6:0] mant_bits;
        real result;
        integer exp_unbiased;
        
        begin
            sign_bit = bf16_val[15];
            exp_bits = bf16_val[14:7];
            mant_bits = bf16_val[6:0];
            
            if (exp_bits == 8'h00) begin
                result = 0.0;
            end else if (exp_bits == 8'hFF) begin
                result = 999999.0;
            end else begin
                exp_unbiased = exp_bits - 127;
                result = (1.0 + (mant_bits / 128.0)) * (2.0 ** exp_unbiased);
                if (sign_bit) result = -result;
            end
            bf16_to_real = result;
        end
    endfunction
    
    initial begin
        rst_n_44 = 0;
        mul_valid_in_44 = 0;
        add_valid_in_44 = 0;
        #20;
        rst_n_44 = 1;
        #10;
        
        $display("=== Simple BF16 Test ===");
        
        // Test 1: Simple multiplication 0.1 * 0.25 = 0.025
        mul_a_44 = 16'h3dcc;  // 0.1
        mul_b_44 = 16'h3e80;  // 0.25
        mul_valid_in_44 = 1;
        #10;
        mul_valid_in_44 = 0;
        
        // Wait for result
        wait(mul_valid_out_44);
        $display("Multiplication: 0.1 * 0.25 = %f (0x%04h)", bf16_to_real(mul_result_44), mul_result_44);
        #10;
        
        // Test 2: Addition 0.0 + 0.025
        add_a_44 = 16'h0000;  // 0.0
        add_b_44 = mul_result_44;  // Previous result
        add_valid_in_44 = 1;
        #10;
        add_valid_in_44 = 0;
        
        wait(add_valid_out_44);
        $display("Addition: 0.0 + prev = %f (0x%04h)", bf16_to_real(add_result_44), add_result_44);
        
        $display("Test complete");
        $finish;
    end

endmodule