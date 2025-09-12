// Testbench for BF16 MAC Unit
// Student ID ending: 44
// Tests the 12-element dot product with specified test vectors
// Expected result: ≈0.366250 (≈0x3dca in BF16)

`timescale 1ns / 1ps

module mac16_tb_44;

    // Clock and reset
    reg clk_44;
    reg rst_n_44;
    
    // MAC control signals
    reg start_computation_44;
    wire computation_done_44;
    wire [3:0] debug_cycle_count_44;
    
    // Test vectors - converting from decimal to BF16
    reg [15:0] vector_a_44 [0:11];
    reg [15:0] vector_b_44 [0:11];
    reg [191:0] vector_a_flat_44, vector_b_flat_44;  // Flattened for DUT
    wire [15:0] result_44;
    
    // Expected values for verification
    reg [15:0] expected_result_44;
    
    // Variables for manual calculation
    real manual_sum;
    real prod0, prod1, prod2, prod3, prod4, prod5;
    real prod6, prod7, prod8, prod9, prod10, prod11;
    
    // Instantiate the DUT (Device Under Test)
    BF16DotProduct_44 dut_44 (
        .clk_44(clk_44),
        .rst_n_44(rst_n_44),
        .start_computation_44(start_computation_44),
        .vector_a_flat_44(vector_a_flat_44),
        .vector_b_flat_44(vector_b_flat_44),
        .result_44(result_44),
        .computation_done_44(computation_done_44),
        .debug_cycle_count_44(debug_cycle_count_44)
    );
    
    // Clock generation
    initial begin
        clk_44 = 0;
        forever #5 clk_44 = ~clk_44;  // 100MHz clock (10ns period)
    end
    
    // BF16 conversion function (decimal to BF16 hex)
    function [15:0] decimal_to_bf16;
        input real decimal_val;
        reg sign_bit;
        reg [7:0] exp_bits;
        reg [6:0] mant_bits;
        reg [31:0] ieee754_single;
        integer exp_single, exp_bf16;
        real abs_val;
        
        begin
            if (decimal_val == 0.0) begin
                decimal_to_bf16 = 16'h0000;
            end else begin
                // Handle sign
                if (decimal_val < 0.0) begin
                    sign_bit = 1'b1;
                    abs_val = -decimal_val;
                end else begin
                    sign_bit = 1'b0;
                    abs_val = decimal_val;
                end
                
                // Convert to IEEE 754 single precision first, then truncate to BF16
                ieee754_single = $realtobits(decimal_val);
                
                // Extract exponent and mantissa from single precision
                exp_bits = ieee754_single[30:23];    // Copy exponent directly
                mant_bits = ieee754_single[22:16];   // Take top 7 mantissa bits
                
                decimal_to_bf16 = {sign_bit, exp_bits, mant_bits};
            end
        end
    endfunction
    
    // BF16 to decimal conversion for display
    function real bf16_to_decimal;
        input [15:0] bf16_val;
        reg sign_bit;
        reg [7:0] exp_bits;
        reg [6:0] mant_bits;
        real result;
        integer exp_unbias;
        
        begin
            sign_bit = bf16_val[15];
            exp_bits = bf16_val[14:7];
            mant_bits = bf16_val[6:0];
            
            if (exp_bits == 8'h00) begin
                // Zero or subnormal
                if (mant_bits == 7'h00) begin
                    result = 0.0;
                end else begin
                    // Subnormal number
                    result = (mant_bits / 128.0) * (2.0 ** (-126));
                    if (sign_bit) result = -result;
                end
            end else if (exp_bits == 8'hFF) begin
                // Infinity or NaN
                result = 999999.999;  // Indicate special value
            end else begin
                // Normal number
                exp_unbias = exp_bits - 127;
                result = (1.0 + (mant_bits / 128.0)) * (2.0 ** exp_unbias);
                if (sign_bit) result = -result;
            end
            
            bf16_to_decimal = result;
        end
    endfunction
    
    // Test sequence
    initial begin
        // Initialize signals
        rst_n_44 = 0;
        start_computation_44 = 0;
        
        // Initialize test vectors
        // A = (0.1, 0.2, 0.25, -0.3, 0.4, 0.5, 0.55, 0.6, -0.75, 0.8, 0.875, 0.9)
        vector_a_44[0]  = decimal_to_bf16(0.1);
        vector_a_44[1]  = decimal_to_bf16(0.2);
        vector_a_44[2]  = decimal_to_bf16(0.25);
        vector_a_44[3]  = decimal_to_bf16(-0.3);
        vector_a_44[4]  = decimal_to_bf16(0.4);
        vector_a_44[5]  = decimal_to_bf16(0.5);
        vector_a_44[6]  = decimal_to_bf16(0.55);
        vector_a_44[7]  = decimal_to_bf16(0.6);
        vector_a_44[8]  = decimal_to_bf16(-0.75);
        vector_a_44[9]  = decimal_to_bf16(0.8);
        vector_a_44[10] = decimal_to_bf16(0.875);
        vector_a_44[11] = decimal_to_bf16(0.9);
        
        // B = (0.25, -0.9, 0.125, 0.8, 0.875, -0.75, 0.3, 0.6, 0.1, 0.2, -0.4, 0.55)
        vector_b_44[0]  = decimal_to_bf16(0.25);
        vector_b_44[1]  = decimal_to_bf16(-0.9);
        vector_b_44[2]  = decimal_to_bf16(0.125);
        vector_b_44[3]  = decimal_to_bf16(0.8);
        vector_b_44[4]  = decimal_to_bf16(0.875);
        vector_b_44[5]  = decimal_to_bf16(-0.75);
        vector_b_44[6]  = decimal_to_bf16(0.3);
        vector_b_44[7]  = decimal_to_bf16(0.6);
        vector_b_44[8]  = decimal_to_bf16(0.1);
        vector_b_44[9]  = decimal_to_bf16(0.2);
        vector_b_44[10] = decimal_to_bf16(-0.4);
        vector_b_44[11] = decimal_to_bf16(0.55);
        
        // Expected result: ≈0.366250 ≈ 0x3dca
        expected_result_44 = 16'h3dca;
        
        // Flatten arrays for DUT
        vector_a_flat_44 = {vector_a_44[11], vector_a_44[10], vector_a_44[9], vector_a_44[8],
                           vector_a_44[7], vector_a_44[6], vector_a_44[5], vector_a_44[4],
                           vector_a_44[3], vector_a_44[2], vector_a_44[1], vector_a_44[0]};
        vector_b_flat_44 = {vector_b_44[11], vector_b_44[10], vector_b_44[9], vector_b_44[8],
                           vector_b_44[7], vector_b_44[6], vector_b_44[5], vector_b_44[4],
                           vector_b_44[3], vector_b_44[2], vector_b_44[1], vector_b_44[0]};
        
        $display("=== BF16 MAC Testbench Started ===");
        $display("Test Vectors:");
        $display("Vector A:");
        $display("  A[0] = 0x%04h (%f)", vector_a_44[0], bf16_to_decimal(vector_a_44[0]));
        $display("  A[1] = 0x%04h (%f)", vector_a_44[1], bf16_to_decimal(vector_a_44[1]));
        $display("  A[2] = 0x%04h (%f)", vector_a_44[2], bf16_to_decimal(vector_a_44[2]));
        $display("  A[3] = 0x%04h (%f)", vector_a_44[3], bf16_to_decimal(vector_a_44[3]));
        $display("  A[4] = 0x%04h (%f)", vector_a_44[4], bf16_to_decimal(vector_a_44[4]));
        $display("  A[5] = 0x%04h (%f)", vector_a_44[5], bf16_to_decimal(vector_a_44[5]));
        $display("  A[6] = 0x%04h (%f)", vector_a_44[6], bf16_to_decimal(vector_a_44[6]));
        $display("  A[7] = 0x%04h (%f)", vector_a_44[7], bf16_to_decimal(vector_a_44[7]));
        $display("  A[8] = 0x%04h (%f)", vector_a_44[8], bf16_to_decimal(vector_a_44[8]));
        $display("  A[9] = 0x%04h (%f)", vector_a_44[9], bf16_to_decimal(vector_a_44[9]));
        $display("  A[10] = 0x%04h (%f)", vector_a_44[10], bf16_to_decimal(vector_a_44[10]));
        $display("  A[11] = 0x%04h (%f)", vector_a_44[11], bf16_to_decimal(vector_a_44[11]));
        $display("Vector B:");
        $display("  B[0] = 0x%04h (%f)", vector_b_44[0], bf16_to_decimal(vector_b_44[0]));
        $display("  B[1] = 0x%04h (%f)", vector_b_44[1], bf16_to_decimal(vector_b_44[1]));
        $display("  B[2] = 0x%04h (%f)", vector_b_44[2], bf16_to_decimal(vector_b_44[2]));
        $display("  B[3] = 0x%04h (%f)", vector_b_44[3], bf16_to_decimal(vector_b_44[3]));
        $display("  B[4] = 0x%04h (%f)", vector_b_44[4], bf16_to_decimal(vector_b_44[4]));
        $display("  B[5] = 0x%04h (%f)", vector_b_44[5], bf16_to_decimal(vector_b_44[5]));
        $display("  B[6] = 0x%04h (%f)", vector_b_44[6], bf16_to_decimal(vector_b_44[6]));
        $display("  B[7] = 0x%04h (%f)", vector_b_44[7], bf16_to_decimal(vector_b_44[7]));
        $display("  B[8] = 0x%04h (%f)", vector_b_44[8], bf16_to_decimal(vector_b_44[8]));
        $display("  B[9] = 0x%04h (%f)", vector_b_44[9], bf16_to_decimal(vector_b_44[9]));
        $display("  B[10] = 0x%04h (%f)", vector_b_44[10], bf16_to_decimal(vector_b_44[10]));
        $display("  B[11] = 0x%04h (%f)", vector_b_44[11], bf16_to_decimal(vector_b_44[11]));
        $display("Expected Result: 0x%04h (%f)", expected_result_44, bf16_to_decimal(expected_result_44));
        $display("");
        
        // Reset sequence
        #20;
        rst_n_44 = 1;
        #20;
        
        // Start computation
        $display("Starting MAC computation at time %0t", $time);
        start_computation_44 = 1;
        #10;
        start_computation_44 = 0;
        
        // Wait for computation to complete
        wait(computation_done_44);
        #10;
        
        // Display results
        $display("=== Computation Results ===");
        $display("Computation completed at time %0t", $time);
        $display("Total cycles: %0d", debug_cycle_count_44);
        $display("Result: 0x%04h (decimal: %f)", result_44, bf16_to_decimal(result_44));
        $display("Expected: 0x%04h (decimal: %f)", expected_result_44, bf16_to_decimal(expected_result_44));
        
        // Verify result
        if (result_44 == expected_result_44) begin
            $display("*** TEST PASSED: Result matches expected value! ***");
        end else begin
            $display("*** TEST FAILED: Result mismatch! ***");
            $display("  Difference: 0x%04h", result_44 ^ expected_result_44);
        end
        
        // Calculate actual dot product manually for verification
        
        prod0 = bf16_to_decimal(vector_a_44[0]) * bf16_to_decimal(vector_b_44[0]);
        prod1 = bf16_to_decimal(vector_a_44[1]) * bf16_to_decimal(vector_b_44[1]);
        prod2 = bf16_to_decimal(vector_a_44[2]) * bf16_to_decimal(vector_b_44[2]);
        prod3 = bf16_to_decimal(vector_a_44[3]) * bf16_to_decimal(vector_b_44[3]);
        prod4 = bf16_to_decimal(vector_a_44[4]) * bf16_to_decimal(vector_b_44[4]);
        prod5 = bf16_to_decimal(vector_a_44[5]) * bf16_to_decimal(vector_b_44[5]);
        prod6 = bf16_to_decimal(vector_a_44[6]) * bf16_to_decimal(vector_b_44[6]);
        prod7 = bf16_to_decimal(vector_a_44[7]) * bf16_to_decimal(vector_b_44[7]);
        prod8 = bf16_to_decimal(vector_a_44[8]) * bf16_to_decimal(vector_b_44[8]);
        prod9 = bf16_to_decimal(vector_a_44[9]) * bf16_to_decimal(vector_b_44[9]);
        prod10 = bf16_to_decimal(vector_a_44[10]) * bf16_to_decimal(vector_b_44[10]);
        prod11 = bf16_to_decimal(vector_a_44[11]) * bf16_to_decimal(vector_b_44[11]);
        
        manual_sum = prod0 + prod1 + prod2 + prod3 + prod4 + prod5 + prod6 + prod7 + prod8 + prod9 + prod10 + prod11;
        
        $display("A[0] * B[0] = %f * %f = %f", bf16_to_decimal(vector_a_44[0]), bf16_to_decimal(vector_b_44[0]), prod0);
        $display("A[1] * B[1] = %f * %f = %f", bf16_to_decimal(vector_a_44[1]), bf16_to_decimal(vector_b_44[1]), prod1);
        $display("A[2] * B[2] = %f * %f = %f", bf16_to_decimal(vector_a_44[2]), bf16_to_decimal(vector_b_44[2]), prod2);
        $display("A[3] * B[3] = %f * %f = %f", bf16_to_decimal(vector_a_44[3]), bf16_to_decimal(vector_b_44[3]), prod3);
        $display("A[4] * B[4] = %f * %f = %f", bf16_to_decimal(vector_a_44[4]), bf16_to_decimal(vector_b_44[4]), prod4);
        $display("A[5] * B[5] = %f * %f = %f", bf16_to_decimal(vector_a_44[5]), bf16_to_decimal(vector_b_44[5]), prod5);
        $display("A[6] * B[6] = %f * %f = %f", bf16_to_decimal(vector_a_44[6]), bf16_to_decimal(vector_b_44[6]), prod6);
        $display("A[7] * B[7] = %f * %f = %f", bf16_to_decimal(vector_a_44[7]), bf16_to_decimal(vector_b_44[7]), prod7);
        $display("A[8] * B[8] = %f * %f = %f", bf16_to_decimal(vector_a_44[8]), bf16_to_decimal(vector_b_44[8]), prod8);
        $display("A[9] * B[9] = %f * %f = %f", bf16_to_decimal(vector_a_44[9]), bf16_to_decimal(vector_b_44[9]), prod9);
        $display("A[10] * B[10] = %f * %f = %f", bf16_to_decimal(vector_a_44[10]), bf16_to_decimal(vector_b_44[10]), prod10);
        $display("A[11] * B[11] = %f * %f = %f", bf16_to_decimal(vector_a_44[11]), bf16_to_decimal(vector_b_44[11]), prod11);
        $display("Manual calculation sum: %f", manual_sum);
        $display("Expected BF16 sum: %f", bf16_to_decimal(expected_result_44));
        $display("Actual BF16 result: %f", bf16_to_decimal(result_44));
        
        $display("");
        $display("=== Testbench Complete ===");
        $finish;
    end
    
    // Monitor signals during simulation
    initial begin
        $monitor("Time: %0t | Cycle: %0d | Done: %0b | Result: 0x%04h", 
                 $time, 
                 debug_cycle_count_44, 
                 computation_done_44, 
                 result_44);
    end
    
    // Simulation timeout
    initial begin
        #50000; // 50us timeout
        $display("*** ERROR: Simulation timeout! ***");
        $finish;
    end

endmodule