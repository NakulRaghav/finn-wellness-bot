#!/bin/bash

# Script to run floating point multiplier simulation
# Checks for available simulators and runs the test

echo "=== Floating Point Multiplier Simulation ==="

# Check for available simulators
IVERILOG_AVAILABLE=false
VERILATOR_AVAILABLE=false

if command -v iverilog &> /dev/null; then
    echo "✓ Icarus Verilog found"
    IVERILOG_AVAILABLE=true
fi

if command -v verilator &> /dev/null; then
    echo "✓ Verilator found"
    VERILATOR_AVAILABLE=true
fi

# Try to install iverilog if not available and we're on a debian-based system
if [ "$IVERILOG_AVAILABLE" = false ] && command -v apt-get &> /dev/null; then
    echo "Installing Icarus Verilog..."
    sudo apt-get update -qq
    sudo apt-get install -y iverilog
    if command -v iverilog &> /dev/null; then
        echo "✓ Icarus Verilog installed successfully"
        IVERILOG_AVAILABLE=true
    fi
fi

# Run simulation with available tool
if [ "$IVERILOG_AVAILABLE" = true ]; then
    echo "Running simulation with Icarus Verilog..."
    make sim
elif [ "$VERILATOR_AVAILABLE" = true ]; then
    echo "Running simulation with Verilator..."
    make verilator
else
    echo "❌ No SystemVerilog simulator found!"
    echo "Please install either:"
    echo "  - Icarus Verilog: sudo apt-get install iverilog"
    echo "  - Verilator: sudo apt-get install verilator"
    exit 1
fi

echo "=== Simulation Complete ==="