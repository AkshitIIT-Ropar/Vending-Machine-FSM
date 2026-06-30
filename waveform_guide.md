# Waveform guide

The testbench writes a VCD (Value Change Dump) file named `vending_machine.vcd` after running. This can be opened in [GTKWave](http://gtkwave.sourceforge.net/) for visual inspection alongside the PASS/FAIL console output.

## Opening the waveform

```bash
gtkwave vending_machine.vcd
```

In the GTKWave signal tree, expand `vending_machine_tb` → `uut` and drag the following signals into the waveform pane in this order for the clearest view:

1. `clk`
2. `rst_n`
3. `coin5`, `coin10`, `coin25`
4. `state` — right-click and set Data Format to Decimal, since the states are numbered 0–6
5. `prev_state`
6. `trig_coin`
7. `dispense`
8. `change`

## What to look for

- `state` should always start at `0` (S0) right after a `rst_n` pulse low-to-high transition
- Each coin pulse on `coin5`/`coin10`/`coin25` should be exactly one clock cycle wide
- `state` should increment by exactly one "step" per coin insertion until it reaches `6` (DISPENSE)
- `dispense` should pulse high for exactly one cycle when `state == 6`
- `change` should hold its correct value during that same cycle, matching the table in `docs/design_notes.md`
- The cycle immediately after DISPENSE should show `state` back at `0`

## Tip for interviews

Being able to read a waveform and explain, cycle by cycle, why a signal changed when it did, is one of the most commonly tested practical skills in a digital design interview. Practicing this on your own design — where you already know the expected behavior — is a good way to build that fluency before being asked to read someone else's unfamiliar waveform.
