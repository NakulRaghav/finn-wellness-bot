// Simple debug testbench

`timescale 1ns/1ps

module debug_tb;

    reg         clk;
    reg         rst_n;
    reg [11:0]  a, b;
    reg         valid_in;
    wire [11:0] result;
    wire        valid_out;
    
    // Instantiate debug module
    floating_point_multiplier_debug dut (
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
        $display("Debug test starting...");
        
        // Initialize
        rst_n = 0;
        valid_in = 0;
        a = 0;
        b = 0;
        
        // Reset
        #20 rst_n = 1;
        #10;
        
        // Test simple pass-through
        a = 12'b001111100000;  // 1.0
        b = 12'b010000100000;  // 2.0
        valid_in = 1;
        
        $display("Input: a=%b, b=%b, valid_in=%b", a, b, valid_in);
        
        @(posedge clk);
        #1; // Small delay to let values settle
        $display("After 1 cycle: result=%b, valid_out=%b (should have data)", result, valid_out);
        
        if (valid_out == 1 && result == a) begin
            $display("*** PASS: Basic pipeline works! ***");
        end else begin
            $display("*** FAIL: Expected valid_out=1, result=%b, got valid_out=%b, result=%b ***", a, valid_out, result);
        end
        
        $finish;
    end
    
endmodule