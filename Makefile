# Makefile for Floating Point Multiplier Simulation

# Default simulator (change as needed)
SIM ?= iverilog

# Source files
RTL_SRC = floating_point_multiplier.sv
TB_SRC = floating_point_multiplier_tb.sv

# Simulation targets
.PHONY: all clean sim run

all: sim

# Compile and run simulation using Icarus Verilog
sim: $(RTL_SRC) $(TB_SRC)
	@echo "Compiling with Icarus Verilog..."
	iverilog -g2012 -o fp_mult_sim $(RTL_SRC) $(TB_SRC)
	@echo "Running simulation..."
	./fp_mult_sim

# Alternative: Verilator simulation (if available)
verilator: $(RTL_SRC) $(TB_SRC)
	@echo "Compiling with Verilator..."
	verilator --cc --exe --build -j 0 --top-module floating_point_multiplier_tb $(RTL_SRC) $(TB_SRC)
	@echo "Running Verilator simulation..."
	./obj_dir/Vfloating_point_multiplier_tb

# Clean generated files
clean:
	rm -f fp_mult_sim
	rm -f *.vcd
	rm -rf obj_dir/
	rm -f *.log

# View waveform (if GTKWave is available)
wave: floating_point_multiplier.vcd
	gtkwave floating_point_multiplier.vcd &

# Help
help:
	@echo "Available targets:"
	@echo "  sim       - Compile and run simulation with Icarus Verilog (default)"
	@echo "  verilator - Compile and run with Verilator"
	@echo "  wave      - View waveform with GTKWave"
	@echo "  clean     - Clean generated files"
	@echo "  help      - Show this help"