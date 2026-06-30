#!/bin/bash
# =============================================================================
# run_sim.sh — compile and simulate the vending machine FSM with Icarus Verilog
#
# Usage:
#   chmod +x sim/run_sim.sh
#   ./sim/run_sim.sh
#
# Requires: iverilog, vvp (https://github.com/steveicarus/iverilog)
#   sudo apt install iverilog gtkwave
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

SRC="$ROOT_DIR/src/vending_machine.v"
TB="$ROOT_DIR/tb/vending_machine_tb.v"
OUT="$ROOT_DIR/sim/vending_machine.out"

if ! command -v iverilog &> /dev/null; then
    echo "Error: iverilog not found. Install with: sudo apt install iverilog"
    exit 1
fi

echo "Compiling..."
iverilog -o "$OUT" "$SRC" "$TB"

echo "Running simulation..."
cd "$ROOT_DIR"
vvp "$OUT"

echo ""
echo "Done. Waveform written to vending_machine.vcd"
echo "View it with: gtkwave vending_machine.vcd"
