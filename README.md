# Vending Machine FSM in Verilog

A Moore finite state machine that models a coin-operated vending machine. Accepts 5p, 10p, and 25p coins, tracks the running total across 7 states, dispenses an item once the total reaches 30p, and returns the correct change for every overpayment case.

## Why this project

Vending machine controllers are a classic combination of control logic (FSM) and datapath (change calculation), making them a frequently asked digital design interview question at companies like TI, Analog Devices, and Intel. This implementation goes beyond a toy example by correctly resolving every overpayment combination, including the ambiguous case where two different coin paths land on the same state (20p + 10p vs 20p + 25p), which requires tracking the triggering coin in addition to the previous state.

## Repository structure

```
vending-machine-fsm/
├── src/
│   └── vending_machine.v          RTL source (the FSM design)
├── tb/
│   └── vending_machine_tb.v       Self-checking testbench
├── docs/
│   ├── design_notes.md            FSM design rationale and state table
│   └── waveform_guide.md          How to view and interpret simulation output
├── sim/
│   └── run_sim.sh                 One-command simulation script (Icarus Verilog)
├── .gitignore
├── LICENSE
└── README.md
```

## Design summary

| State | Total collected |
|---|---|
| S0 | 0p |
| S5 | 5p |
| S10 | 10p |
| S15 | 15p |
| S20 | 20p |
| S25 | 25p |
| DISPENSE | ≥ 30p — item dispensed, change returned, then returns to S0 |

Inputs: `clk`, active-low `rst_n`, and one-hot coin pulses `coin5`, `coin10`, `coin25` (one cycle each).
Outputs: `dispense` (1-bit) and `change` (3-bit, encodes 0p/5p/10p/15p/20p in multiples of 5p).

Full design rationale, including why a naive previous-state-only approach fails for two of the nine overpayment cases, is documented in [`docs/design_notes.md`](docs/design_notes.md).

## Running the simulation

Requires [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog` and `vvp`). On Ubuntu/Debian:

```bash
sudo apt install iverilog gtkwave
```

Then from the repository root:

```bash
chmod +x sim/run_sim.sh
./sim/run_sim.sh
```

This compiles the design and testbench, runs the simulation, prints PASS/FAIL for all 11 test groups, and generates `vending_machine.vcd` for waveform inspection in GTKWave.

Alternatively, paste `src/vending_machine.v` and `tb/vending_machine_tb.v` into [EDA Playground](https://www.edaplayground.com/) (free, no install) and run with the Icarus Verilog backend.

## Test coverage

The testbench in `tb/vending_machine_tb.v` is self-checking — it asserts expected `dispense` and `change` values automatically and prints a PASS/FAIL summary rather than requiring manual waveform inspection. It covers:

- All paths that lead to exact change (0p)
- All four overpayment paths (5p, 10p, 15p, 20p change)
- The ambiguous-state case (S20 reached via two different coin combinations)
- Mid-transaction reset behavior

Sample output:

```
[PASS] T6b: 20p+25p=45p change=15p | dispense=1 change=15p
...
 Results: 22 PASSED, 0 FAILED out of 22 tests
 ALL TESTS PASSED
```

## Possible extensions

- Add a `select_item` input so different items have different prices
- Add an `out_of_stock` condition that blocks dispensing and forces a refund
- Convert to a Mealy machine and compare output latency against this Moore version
- Synthesize for an FPGA target and drive `coin*` inputs from physical push-buttons with debounce logic

## Author

AK — written as part of a Verilog/digital design portfolio for core semiconductor placement preparation.

## License

MIT — see [LICENSE](LICENSE).
