// SystemVerilog Testbench for BF16 Dot Product MAC
// Student ID ending: 44
// Comprehensive testing with multiple test cases and verification

`timescale 1ns / 1ps

module tb_bf16_dot_44;

    // Test parameters
    parameter CLOCK_PERIOD = 10;  // 100MHz
    parameter NUM_ELEMENTS = 12;
    parameter TIMEOUT_CYCLES = 1000;
    
    // DUT signals
    logic clk_44;
    logic rst_n_44;
    logic start_computation_44;
    logic [15:0] vector_a_44 [0:11];
    logic [15:0] vector_b_44 [0:11];
    logic [15:0] result_44;
    logic computation_done_44;
    logic [3:0] debug_cycle_count_44;
    
    // Test control
    int test_case_44;
    int errors_44;
    int cycle_counter_44;
    
    // DUT instantiation
    BF16DotProduct_44 dut_44 (
        .clk_44(clk_44),
        .rst_n_44(rst_n_44),
        .start_computation_44(start_computation_44),
        .vector_a_44(vector_a_44),
        .vector_b_44(vector_b_44),
        .result_44(result_44),
        .computation_done_44(computation_done_44),
        .debug_cycle_count_44(debug_cycle_count_44)
    );
    
    // Clock generation
    initial begin
        clk_44 = 0;
        forever #(CLOCK_PERIOD/2) clk_44 = ~clk_44;
    end
    
    // BF16 utility functions
    function automatic [15:0] real_to_bf16(real value);
        bit [31:0] ieee754;
        bit sign;
        bit [7:0] exponent;
        bit [6:0] mantissa;
        
        if (value == 0.0) return 16'h0000;
        
        ieee754 = $realtobits(value);
        sign = ieee754[31];
        exponent = ieee754[30:23];
        mantissa = ieee754[22:16];  // Truncate to 7 bits
        
        return {sign, exponent, mantissa};
    endfunction
    
    function automatic real bf16_to_real(bit [15:0] bf16_val);
        bit sign = bf16_val[15];
        bit [7:0] exponent = bf16_val[14:7];
        bit [6:0] mantissa = bf16_val[6:0];
        real result;
        int exp_unbiased;
        
        if (exponent == 8'h00) begin
            if (mantissa == 7'h00) begin
                result = 0.0;
            end else begin
                // Subnormal
                result = (real'(mantissa) / 128.0) * (2.0 ** (-126));
                if (sign) result = -result;
            end
        end else if (exponent == 8'hFF) begin
            result = (sign) ? -999999.0 : 999999.0;  // Infinity representation
        end else begin
            // Normal number
            exp_unbiased = int'(exponent) - 127;
            result = (1.0 + (real'(mantissa) / 128.0)) * (2.0 ** exp_unbiased);
            if (sign) result = -result;
        end
        
        return result;
    endfunction
    
    // Test vector initialization
    task automatic init_test_vectors_44();
        // Test Case 1: Original test vectors
        // A = (0.1, 0.2, 0.25, -0.3, 0.4, 0.5, 0.55, 0.6, -0.75, 0.8, 0.875, 0.9)
        vector_a_44[0]  = real_to_bf16(0.1);
        vector_a_44[1]  = real_to_bf16(0.2);
        vector_a_44[2]  = real_to_bf16(0.25);
        vector_a_44[3]  = real_to_bf16(-0.3);
        vector_a_44[4]  = real_to_bf16(0.4);
        vector_a_44[5]  = real_to_bf16(0.5);
        vector_a_44[6]  = real_to_bf16(0.55);
        vector_a_44[7]  = real_to_bf16(0.6);
        vector_a_44[8]  = real_to_bf16(-0.75);
        vector_a_44[9]  = real_to_bf16(0.8);
        vector_a_44[10] = real_to_bf16(0.875);
        vector_a_44[11] = real_to_bf16(0.9);
        
        // B = (0.25, -0.9, 0.125, 0.8, 0.875, -0.75, 0.3, 0.6, 0.1, 0.2, -0.4, 0.55)
        vector_b_44[0]  = real_to_bf16(0.25);
        vector_b_44[1]  = real_to_bf16(-0.9);
        vector_b_44[2]  = real_to_bf16(0.125);
        vector_b_44[3]  = real_to_bf16(0.8);
        vector_b_44[4]  = real_to_bf16(0.875);
        vector_b_44[5]  = real_to_bf16(-0.75);
        vector_b_44[6]  = real_to_bf16(0.3);
        vector_b_44[7]  = real_to_bf16(0.6);
        vector_b_44[8]  = real_to_bf16(0.1);
        vector_b_44[9]  = real_to_bf16(0.2);
        vector_b_44[10] = real_to_bf16(-0.4);
        vector_b_44[11] = real_to_bf16(0.55);
    endtask
    
    // Alternative test vectors
    task automatic init_test_vectors_zero_44();
        // Test Case 2: One vector is all zeros
        for (int i = 0; i < NUM_ELEMENTS; i++) begin
            vector_a_44[i] = 16'h0000;  // All zeros
            vector_b_44[i] = real_to_bf16(1.0);  // All ones
        end
    endtask
    
    task automatic init_test_vectors_ones_44();
        // Test Case 3: Both vectors are all ones
        for (int i = 0; i < NUM_ELEMENTS; i++) begin
            vector_a_44[i] = real_to_bf16(1.0);  
            vector_b_44[i] = real_to_bf16(1.0);  
        end
    endtask
    
    task automatic init_test_vectors_alternating_44();
        // Test Case 4: Alternating positive/negative values
        for (int i = 0; i < NUM_ELEMENTS; i++) begin
            vector_a_44[i] = real_to_bf16((i % 2) ? 1.0 : -1.0);
            vector_b_44[i] = real_to_bf16((i % 2) ? -1.0 : 1.0);
        end
    endtask
    
    // Reset task
    task automatic reset_dut_44();
        rst_n_44 = 0;
        start_computation_44 = 0;
        repeat (5) @(posedge clk_44);
        rst_n_44 = 1;
        repeat (2) @(posedge clk_44);
    endtask
    
    // Run computation task
    task automatic run_computation_44(input [15:0] expected_result);
        real calculated_result;
        real expected_real;
        real actual_real;
        real tolerance = 0.01;  // 1% tolerance for BF16 precision
        
        // Start computation
        start_computation_44 = 1;
        @(posedge clk_44);
        start_computation_44 = 0;
        
        // Wait for completion with timeout
        cycle_counter_44 = 0;
        fork
            begin
                wait(computation_done_44);
            end
            begin
                repeat (TIMEOUT_CYCLES) @(posedge clk_44);
                $error("Test Case %0d: Timeout waiting for computation_done_44", test_case_44);
                errors_44++;
            end
        join_any
        disable fork;
        
        if (computation_done_44) begin
            // Calculate expected result manually
            calculated_result = 0.0;
            for (int i = 0; i < NUM_ELEMENTS; i++) begin
                calculated_result += bf16_to_real(vector_a_44[i]) * bf16_to_real(vector_b_44[i]);
            end
            
            expected_real = bf16_to_real(expected_result);
            actual_real = bf16_to_real(result_44);
            
            $display("Test Case %0d Results:", test_case_44);
            $display("  Expected (manual calc): %f", calculated_result);
            $display("  Expected (BF16):        0x%04h (%f)", expected_result, expected_real);
            $display("  Actual:                 0x%04h (%f)", result_44, actual_real);
            $display("  Cycles taken:           %0d", debug_cycle_count_44);
            
            // Verify result
            if (result_44 == expected_result) begin
                $display("  *** PASS: Exact match ***");
            end else if ($abs(actual_real - calculated_result) / calculated_result < tolerance) begin
                $display("  *** PASS: Within tolerance ***");
            end else begin
                $display("  *** FAIL: Result mismatch ***");
                $display("  Error: %f (%f%%)", $abs(actual_real - calculated_result), 
                        $abs(actual_real - calculated_result) / calculated_result * 100.0);
                errors_44++;
            end
        end
        
        // Wait a few cycles before next test
        repeat (5) @(posedge clk_44);
    endtask
    
    // Individual component testing tasks
    task automatic test_multiplier_44();
        $display("\n=== Testing BF16 Multiplier Component ===");
        
        // Test basic multiplication
        real a_val = 2.0, b_val = 3.0;
        real expected_prod = a_val * b_val;
        
        @(posedge clk_44);
        dut_44.mac_unit_44.mul_a_44 = real_to_bf16(a_val);
        dut_44.mac_unit_44.mul_b_44 = real_to_bf16(b_val);
        dut_44.mac_unit_44.mul_valid_in_44 = 1'b1;
        
        @(posedge clk_44);
        dut_44.mac_unit_44.mul_valid_in_44 = 1'b0;
        
        // Wait for result (3 cycles)
        repeat (4) @(posedge clk_44);
        
        if (dut_44.mac_unit_44.mul_valid_out_44) begin
            real actual_prod = bf16_to_real(dut_44.mac_unit_44.mul_result_44);
            $display("Multiplier test: %f * %f = %f (expected: %f)", 
                    a_val, b_val, actual_prod, expected_prod);
            
            if ($abs(actual_prod - expected_prod) < 0.1) begin
                $display("*** Multiplier PASS ***");
            end else begin
                $display("*** Multiplier FAIL ***");
                errors_44++;
            end
        end else begin
            $display("*** Multiplier FAIL: No valid output ***");
            errors_44++;
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("=== BF16 MAC Comprehensive Testbench ===");
        $display("Student ID: 44");
        $display("Test Start Time: %0t\n", $time);
        
        errors_44 = 0;
        test_case_44 = 0;
        
        // Initialize and reset
        reset_dut_44();
        
        // Test individual multiplier component
        test_multiplier_44();
        reset_dut_44();
        
        // Test Case 1: Original specified test vectors
        $display("\n=== Test Case 1: Original Test Vectors ===");
        test_case_44 = 1;
        init_test_vectors_44();
        run_computation_44(16'h3dca);  // Expected ≈0.366250
        
        reset_dut_44();
        
        // Test Case 2: Zero vector
        $display("\n=== Test Case 2: Zero Vector Test ===");
        test_case_44 = 2;
        init_test_vectors_zero_44();
        run_computation_44(16'h0000);  // Expected 0.0
        
        reset_dut_44();
        
        // Test Case 3: All ones
        $display("\n=== Test Case 3: All Ones Test ===");
        test_case_44 = 3;
        init_test_vectors_ones_44();
        run_computation_44(real_to_bf16(12.0));  // Expected 12.0
        
        reset_dut_44();
        
        // Test Case 4: Alternating values
        $display("\n=== Test Case 4: Alternating Values Test ===");
        test_case_44 = 4;
        init_test_vectors_alternating_44();
        run_computation_44(real_to_bf16(-12.0));  // Expected -12.0
        
        // Final results
        $display("\n=== Test Summary ===");
        if (errors_44 == 0) begin
            $display("*** ALL TESTS PASSED! ***");
        end else begin
            $display("*** %0d TESTS FAILED! ***", errors_44);
        end
        
        $display("Testbench completed at time: %0t", $time);
        $finish;
    end
    
    // Simulation timeout
    initial begin
        #100000; // 100us timeout
        $display("*** SIMULATION TIMEOUT ***");
        $finish;
    end
    
    // Optional: Dump waveforms for debugging
    initial begin
        $dumpfile("bf16_mac_44.vcd");
        $dumpvars(0, tb_bf16_dot_44);
    end

endmodule