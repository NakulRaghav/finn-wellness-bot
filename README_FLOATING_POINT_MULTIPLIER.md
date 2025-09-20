# Floating Point Multiplier Implementation

## Overview
This repository contains a corrected SystemVerilog implementation of a 12-bit floating point multiplier that properly handles edge cases including underflow and overflow conditions.

## Floating Point Format
- **Total bits**: 12
- **Sign bit**: 1 (bit 11)
- **Exponent bits**: 5 (bits 10:6)
- **Fraction bits**: 6 (bits 5:0)
- **Exponent bias**: +15
- **Valid exponent range**: 1-29 (0 = denormalized, 30+ = overflow)

## Key Features
- **Proper underflow handling**: Small * Small operations correctly underflow to zero instead of saturating
- **Correct saturation logic**: Only saturates when exponent >= 30
- **Precise arithmetic**: Uses signed exponent calculations to handle edge cases
- **IEEE-like behavior**: Treats denormalized inputs (exp=0) as zero

## Files
- `floating_point_multiplier.sv` - Main implementation
- `floating_point_multiplier_tb.sv` - Comprehensive testbench  
- `Makefile` - Build automation
- `run_simulation.sh` - Automated simulation script

## Test Cases
The implementation passes all 11 comprehensive test cases including:

1. **Basic multiplication** (1.0 × 2.0 = 2.0)
2. **Zero multiplication** (0.0 × 1.0 = 0.0)
3. **Sign tests** (positive/negative combinations)
4. **Sign tests** (negative × negative = positive)
5. **Small × Small underflow test** ✅ **FIXED** - Now correctly underflows to zero
6. **Large × Large overflow test** (correctly saturates)
7. **Max exp × 1.0** ✅ **FIXED** - Now preserves maximum exponent
8. **Commutative test** (1.0 × Max exp)
9. **Fractional multiplication** (1.25 × 1.25 = 1.5625)
10. **Minimum normalized × 1.0** (preserves minimum values)
11. **Denormalized input handling** (treats as zero)

## Key Bug Fixes

### Issue 1: Small × Small Underflow
- **Problem**: Small numbers (exp=2) multiplied were saturating instead of underflowing
- **Root Cause**: Incorrect overflow/underflow detection logic
- **Fix**: Proper signed arithmetic for exponent calculation: `2 + 2 - 15 = -11` → underflow to zero

### Issue 2: Max Exponent × 1.0 Saturation  
- **Problem**: Max exponent (29) × 1.0 was incorrectly saturating
- **Root Cause**: Overly aggressive saturation condition
- **Fix**: Correct calculation: `29 + 15 - 15 = 29` → preserve valid result

### Issue 3: Timing Issues
- **Problem**: Testbench timing didn't match pipeline behavior
- **Fix**: Proper synchronization with clock edge and delta delays

## Usage

### Compilation and Simulation
```bash
# Make sure you have Icarus Verilog installed
sudo apt-get install iverilog

# Run the simulation
make sim

# Or use the automated script
./run_simulation.sh

# Clean generated files
make clean
```

### Integration
The module can be instantiated as:
```systemverilog
floating_point_multiplier mult_inst (
    .clk(clk),
    .rst_n(rst_n),
    .a(operand_a),      // 12-bit floating point input
    .b(operand_b),      // 12-bit floating point input  
    .valid_in(valid),   // Input valid signal
    .result(product),   // 12-bit floating point result
    .valid_out(ready)   // Output valid signal (pipelined)
);
```

## Implementation Details

### Exponent Calculation
```systemverilog
result_exp_temp = $signed({3'b000, exp_a}) + $signed({3'b000, exp_b}) - $signed({3'b000, 5'd15});
```

### Normalization Logic
- If `frac_mult_result[13] == 1`: shift right, increment exponent
- Else: use lower bits directly

### Underflow/Overflow Detection
- **Underflow**: `result_exp_temp <= 0` → output zero
- **Overflow**: `result_exp_temp >= 30` → saturate to `011110110000`

## Testing
All test cases pass, confirming correct behavior for:
- Standard arithmetic operations
- Edge cases (underflow/overflow)
- Sign handling
- Denormalized input handling
- Pipeline timing

The implementation successfully fixes the specific failing test cases mentioned in the original problem statement.