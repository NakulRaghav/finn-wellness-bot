// Simple multiplication test to debug the logic

`timescale 1ns/1ps

module simple_mult_test;

    reg         clk;
    reg         rst_n;
    reg [11:0]  a, b;
    reg         valid_in;
    wire [11:0] result;
    wire        valid_out;
    
    // Instantiate debug module
    debug_mult dut (
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
    
    // Test
    initial begin
        $display("=== Simple Multiplication Debug ===");
        
        // Initialize
        rst_n = 0;
        valid_in = 0;
        a = 0;
        b = 0;
        
        // Reset
        #20 rst_n = 1;
        #10;
        
        // Test 1: 1.0 * 2.0 = 2.0
        a = 12'b001111100000;  // sign=0, exp=15(bias), frac=000000 = 1.0
        b = 12'b010000100000;  // sign=0, exp=16(bias+1), frac=100000 = 2.0
        valid_in = 1;
        
        $display("Input A: %b (sign=%b, exp=%d, frac=%b)", a, a[11], a[10:6], a[5:0]);
        $display("Input B: %b (sign=%b, exp=%d, frac=%b)", b, b[11], b[10:6], b[5:0]);
        $display("Expected: 010000100000 (sign=0, exp=16, frac=100000)");
        
        @(posedge clk);
        #1;
        
        $display("Result:   %b (sign=%b, exp=%d, frac=%b)", result, result[11], result[10:6], result[5:0]);
        $display("Valid:    %b", valid_out);
        
        // Analyze the internal computation manually
        // norm_frac_a = {1'b1, 6'b000000} = 7'b1000000 = 64
        // norm_frac_b = {1'b1, 6'b100000} = 7'b1100000 = 96
        // frac_mult_result = 64 * 96 = 6144
        
        $display("\nManual calculation:");
        $display("norm_frac_a = 1.000000 (binary) = 64 (decimal)");
        $display("norm_frac_b = 1.100000 (binary) = 96 (decimal)"); 
        $display("Product = 64 * 96 = 6144");
        $display("Product binary = 01100000000000 (14 bits)");
        $display("MSB of product = 0 (bit 13)");
        $display("Exponent calculation: 15 + 16 - 15 = 16");
        
        valid_in = 0;
        #20;
        
        $finish;
    end
    
endmodule