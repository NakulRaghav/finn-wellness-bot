// Testbench for Floating Point Multiplier
// Tests the specific failing cases mentioned in the problem statement

`timescale 1ns/1ps

module floating_point_multiplier_tb;

    // Testbench signals
    logic        clk;
    logic        rst_n;
    logic [11:0] a, b;
    logic        valid_in;
    logic [11:0] result;
    logic        valid_out;
    
    // Test tracking
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Instantiate DUT
    floating_point_multiplier dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .valid_in(valid_in),
        .result(result),
        .valid_out(valid_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test procedure
    initial begin
        $dumpfile("floating_point_multiplier.vcd");
        $dumpvars(0, floating_point_multiplier_tb);
        
        // Initialize
        rst_n = 0;
        valid_in = 0;
        a = 0;
        b = 0;
        
        // Reset
        #20 rst_n = 1;
        #10;
        
        $display("\n=== Floating Point Multiplier Test Results ===");
        $display("Format: 1 sign + 5 exp + 6 frac = 12 bits, bias = 15");
        $display("Test format: Test# - Description: input_a * input_b = expected -> actual (PASS/FAIL)");
        
        // Test cases based on problem statement
        
        // Test 1: Basic multiplication (1.0 * 2.0 = 2.0)
        run_test("Test 1: Basic multiplication", 
                 12'b001111000000,  // exp=15(bias), frac=000000 = 1.0
                 12'b010000000000,  // exp=16(bias+1), frac=000000 = 2.0  
                 12'b010000000000); // exp=16(bias+1), frac=000000 = 2.0
        
        // Test 2: Zero multiplication
        run_test("Test 2: Zero multiplication",
                 12'b000000000000,  // 0.0
                 12'b001111100000,  // 1.0
                 12'b000000000000); // 0.0
        
        // Test 3: Sign test (positive * negative)
        run_test("Test 3: Sign test (pos * neg)",
                 12'b001111000000,  // +1.0
                 12'b101111000000,  // -1.0
                 12'b101111000000); // -1.0
        
        // Test 4: Sign test (negative * negative)  
        run_test("Test 4: Sign test (neg * neg)",
                 12'b101111000000,  // -1.0
                 12'b101111000000,  // -1.0
                 12'b001111000000); // +1.0
        
        // Test 5: Small * Small (underflow test) - This was failing
        run_test("Test 5: Small * Small (underflow test)",
                 12'b000010100000,  // exp=2(-13), small number
                 12'b000010100000,  // exp=2(-13), small number  
                 12'b000000000000); // Should underflow to 0, not saturate
        
        // Test 6: Large * Large (overflow test)
        run_test("Test 6: Large * Large (overflow test)",
                 12'b011101110000,  // exp=29(+14), large number
                 12'b011101110000,  // exp=29(+14), large number
                 12'b011110110000); // Should saturate
        
        // Test 7: Max exp * 1.0 - This was failing  
        run_test("Test 7: Max exp * 1.0",
                 12'b011101000000,  // exp=29(+14), max valid exp  
                 12'b001111000000,  // exp=15(bias), frac=000000 = 1.0
                 12'b011101000000); // Should preserve max exp, not saturate
        
        // Test 8: 1.0 * Max exp (commutative check)
        run_test("Test 8: 1.0 * Max exp (commutative check)",
                 12'b001111000000,  // 1.0
                 12'b011101000000,  // max valid exp
                 12'b011101000000); // Should preserve max exp
        
        // Test 9: Fractional multiplication (1.25 * 1.25 = 1.5625)
        run_test("Test 9: Fractional multiplication",
                 12'b001111010000,  // exp=15, frac=010000 = 1.25
                 12'b001111010000,  // exp=15, frac=010000 = 1.25
                 12'b001111100100); // Should be approximately 1.5625
        
        // Test 10: Edge case - minimum normalized * 1.0
        run_test("Test 10: Min normalized * 1.0",
                 12'b000001000000,  // exp=1(-14), minimum normalized
                 12'b001111000000,  // 1.0
                 12'b000001000000); // Should preserve minimum normalized
        
        // Test 11: Denormalized input (exp=0) should be treated as zero
        run_test("Test 11: Denormalized input",
                 12'b000000100000,  // exp=0, denormalized
                 12'b001111000000,  // 1.0
                 12'b000000000000); // Should be zero
        
        // Print final results
        $display("\n=== Test Summary ===");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED! ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", fail_count);
        end
        
        $finish;
    end
    
    // Test execution task
    task run_test(string test_name, logic [11:0] input_a, logic [11:0] input_b, logic [11:0] expected);
        test_count++;
        
        // Apply inputs
        a = input_a;
        b = input_b;
        valid_in = 1;
        
        // Wait for result - simplified approach with proper timing
        @(posedge clk);
        valid_in = 0;
        #1; // Small delay to let values settle
        
        // Check result
        if (result == expected) begin
            $display("%s: %b * %b = %b -> %b (PASS)", 
                     test_name, input_a, input_b, expected, result);
            pass_count++;
        end else begin
            $display("%s: %b * %b = %b -> %b (FAIL)", 
                     test_name, input_a, input_b, expected, result);
            fail_count++;
            
            // Additional debug info for failed tests
            $display("  Expected: sign=%b, exp=%b(%0d), frac=%b", 
                     expected[11], expected[10:6], expected[10:6], expected[5:0]);
            $display("  Actual:   sign=%b, exp=%b(%0d), frac=%b", 
                     result[11], result[10:6], result[10:6], result[5:0]);
        end
        
        #10; // Small delay between tests
    endtask
    
endmodule