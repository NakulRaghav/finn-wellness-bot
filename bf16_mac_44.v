// BF16 MAC (Multiply-Accumulate) Unit for 12-element dot product
// Student ID ending: 44
// Computes A•B for 12-element vectors A and B
// Total latency: 6 cycles from input to accumulator update (3 for mul + 3 for add)

module BF16MAC_44 (
    input wire clk_44,
    input wire rst_n_44,
    input wire start_44,                    // Start computing dot product
    input wire [191:0] a_elements_flat_44,  // Vector A (12 elements, 16 bits each = 192 bits)
    input wire [191:0] b_elements_flat_44,  // Vector B (12 elements, 16 bits each = 192 bits)
    output reg [15:0] dot_product_44,       // Final dot product result
    output reg done_44,                     // Computation complete flag
    output reg [3:0] cycle_count_44         // Current cycle counter for debugging
);

    // Extract individual elements from flattened vectors
    wire [15:0] a_elements_44 [0:11];
    wire [15:0] b_elements_44 [0:11];
    
    generate
        genvar i;
        for (i = 0; i < 12; i = i + 1) begin : element_extract
            assign a_elements_44[i] = a_elements_flat_44[16*i+15:16*i];
            assign b_elements_44[i] = b_elements_flat_44[16*i+15:16*i];
        end
    endgenerate
    
    // State machine states
    parameter IDLE_44 = 3'b000;
    parameter MULTIPLY_44 = 3'b001;
    parameter ACCUMULATE_44 = 3'b010;
    parameter DONE_44 = 3'b011;
    
    reg [2:0] current_state_44, next_state_44;
    
    // MAC component instances
    wire [15:0] mul_result_44;
    wire mul_valid_out_44;
    reg [15:0] mul_a_44, mul_b_44;
    reg mul_valid_in_44;
    
    wire [15:0] add_result_44;
    wire add_valid_out_44;
    reg [15:0] add_a_44, add_b_44;
    reg add_valid_in_44;
    
    // Internal registers
    reg [3:0] element_index_44;        // Current element being processed (0-11)
    reg [15:0] accumulator_44;         // Running sum
    reg [5:0] total_cycles_44;         // Total cycles for operation
    reg computation_active_44;
    
    // Instantiate BF16 multiplier
    BF16Mul_44 multiplier_44 (
        .clk_44(clk_44),
        .rst_n_44(rst_n_44),
        .a_44(mul_a_44),
        .b_44(mul_b_44),
        .valid_in_44(mul_valid_in_44),
        .result_44(mul_result_44),
        .valid_out_44(mul_valid_out_44)
    );
    
    // Instantiate BF16 adder
    BF16AddSub_44 adder_44 (
        .clk_44(clk_44),
        .rst_n_44(rst_n_44),
        .a_44(add_a_44),
        .b_44(add_b_44),
        .sub_44(1'b0),  // Always addition for accumulation
        .valid_in_44(add_valid_in_44),
        .result_44(add_result_44),
        .valid_out_44(add_valid_out_44)
    );
    
    // State machine sequential logic
    always @(posedge clk_44 or negedge rst_n_44) begin
        if (!rst_n_44) begin
            current_state_44 <= IDLE_44;
            element_index_44 <= 4'h0;
            accumulator_44 <= 16'h0000;  // Initialize to +0.0 in BF16
            total_cycles_44 <= 6'h0;
            computation_active_44 <= 1'b0;
            cycle_count_44 <= 4'h0;
            done_44 <= 1'b0;
            dot_product_44 <= 16'h0000;
            mul_valid_in_44 <= 1'b0;
            add_valid_in_44 <= 1'b0;
        end else begin
            case (current_state_44)
                IDLE_44: begin
                    if (start_44) begin
                        element_index_44 <= 4'h0;
                        accumulator_44 <= 16'h0000;  // +0.0 in BF16
                        total_cycles_44 <= 6'h0;
                        computation_active_44 <= 1'b1;
                        done_44 <= 1'b0;
                        cycle_count_44 <= 4'h1;
                        current_state_44 <= MULTIPLY_44;
                        
                        // Start first multiplication
                        mul_a_44 <= a_elements_44[0];
                        mul_b_44 <= b_elements_44[0];
                        mul_valid_in_44 <= 1'b1;
                    end else begin
                        computation_active_44 <= 1'b0;
                        cycle_count_44 <= 4'h0;
                        mul_valid_in_44 <= 1'b0;
                        add_valid_in_44 <= 1'b0;
                    end
                end
                
                MULTIPLY_44: begin
                    cycle_count_44 <= cycle_count_44 + 1;
                    mul_valid_in_44 <= 1'b0;  // Only pulse for one cycle
                    
                    // Wait for multiplication to complete (3 cycles)
                    if (mul_valid_out_44) begin
                        current_state_44 <= ACCUMULATE_44;
                        // Start accumulation
                        add_a_44 <= accumulator_44;
                        add_b_44 <= mul_result_44;
                        add_valid_in_44 <= 1'b1;
                        total_cycles_44 <= 6'h0;  // Reset cycle counter for add
                    end
                end
                
                ACCUMULATE_44: begin
                    cycle_count_44 <= cycle_count_44 + 1;
                    add_valid_in_44 <= 1'b0;  // Only pulse for one cycle
                    total_cycles_44 <= total_cycles_44 + 1;
                    
                    // Wait for addition to complete (3 cycles)  
                    if (add_valid_out_44) begin
                        accumulator_44 <= add_result_44;
                        element_index_44 <= element_index_44 + 1;
                        
                        if (element_index_44 >= 4'd11) begin
                            // All elements processed
                            current_state_44 <= DONE_44;
                            dot_product_44 <= add_result_44;
                            done_44 <= 1'b1;
                            computation_active_44 <= 1'b0;
                        end else begin
                            // Process next element
                            current_state_44 <= MULTIPLY_44;
                            mul_a_44 <= a_elements_44[element_index_44 + 1];
                            mul_b_44 <= b_elements_44[element_index_44 + 1];
                            mul_valid_in_44 <= 1'b1;
                        end
                    end
                end
                
                DONE_44: begin
                    if (!start_44) begin
                        done_44 <= 1'b0;
                        current_state_44 <= IDLE_44;
                    end
                end
                
                default: begin
                    current_state_44 <= IDLE_44;
                end
            endcase
        end
    end
    
endmodule

// Top-level module for dot product computation
module BF16DotProduct_44 (
    input wire clk_44,
    input wire rst_n_44,
    input wire start_computation_44,
    input wire [191:0] vector_a_flat_44,
    input wire [191:0] vector_b_flat_44,
    output wire [15:0] result_44,
    output wire computation_done_44,
    output wire [3:0] debug_cycle_count_44
);

    // Instantiate MAC unit
    BF16MAC_44 mac_unit_44 (
        .clk_44(clk_44),
        .rst_n_44(rst_n_44),
        .start_44(start_computation_44),
        .a_elements_flat_44(vector_a_flat_44),
        .b_elements_flat_44(vector_b_flat_44),
        .dot_product_44(result_44),
        .done_44(computation_done_44),
        .cycle_count_44(debug_cycle_count_44)
    );

endmodule