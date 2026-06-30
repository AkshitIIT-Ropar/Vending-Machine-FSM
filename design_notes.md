# Design notes — Vending Machine FSM

## 1. Problem statement

Design a controller that:
- Accepts coins of denomination 5p, 10p, and 25p, one at a time
- Tracks the cumulative total inserted
- Dispenses a single item once the total reaches or exceeds 30p
- Returns correct change for any amount paid in excess of 30p
- Resets to idle and is ready for the next customer immediately after dispensing

## 2. Why a Moore machine

The output (`dispense`, `change`) should be stable and well-defined for the entire cycle in which the machine is in the DISPENSE state, regardless of what input arrives in that same cycle. A Moore machine — where outputs depend only on the current state — gives this guarantee naturally. A Mealy implementation would also work but would require the output to react combinationally to the input that just arrived, which is less natural for a "complete and stable for a full cycle" type of output like a physical item dispense signal.

## 3. State space

Seven states are sufficient: one for each possible running total from 0p to 25p in steps of 5p (since all coin denominations are multiples of 5p, the total is always a multiple of 5p), plus one absorbing DISPENSE state.

```
S0 (0p) -> S5 (5p) -> S10 (10p) -> S15 (15p) -> S20 (20p) -> S25 (25p) -> DISPENSE -> S0
```

From any state, inserting a coin moves forward by that coin's value, or jumps straight to DISPENSE if the new total would be ≥ 30p.

## 4. The change calculation problem

This is the part of the design that is easy to get wrong, and worth understanding clearly since it is the kind of detail an interviewer will probe.

If you only remember `prev_state` (the state you were in immediately before entering DISPENSE), you cannot always determine the correct change. Consider:

- From S20, inserting a 10p coin reaches exactly 30p → 0p change
- From S20, inserting a 25p coin reaches 45p → 15p change

Both transitions start from S20 and end in DISPENSE, but require different change amounts. `prev_state` alone is ambiguous here.

The fix used in this design: register **both** `prev_state` and the coin that triggered the transition (`trig_coin`) on the same clock edge. The output logic then keys off the pair `{prev_state, trig_coin}`, which is unambiguous for every reachable transition into DISPENSE.

Full table of transitions into DISPENSE:

| From state | Coin inserted | New total | Change |
|---|---|---|---|
| S5  | 25p | 30p | 0p |
| S10 | 25p | 35p | 5p |
| S15 | 25p | 40p | 10p |
| S20 | 10p | 30p | 0p |
| S20 | 25p | 45p | 15p |
| S25 | 5p  | 30p | 0p |
| S25 | 10p | 35p | 5p |
| S25 | 25p | 50p | 20p |

Note S0, S5 (via 5p/10p), S10 (via 5p/10p), and S15 (via 5p/10p) never reach DISPENSE directly — they only ever move to the next intermediate state, since their totals plus 5p or 10p never exceed 30p alone. Only the eight transitions above lead into DISPENSE.

## 5. Why `next_state = state` matters

In the next-state combinational block, the first line assigns `next_state = state` before the `case` statement runs. This is a deliberate default. Without it, any state/input combination not explicitly covered by an `if` condition would leave `next_state` undriven in that branch, and Verilog would infer a latch to hold the previous value — a synthesis-unfriendly and generally undesired result for what is meant to be purely combinational logic. Setting a default at the top guarantees `next_state` is always driven, regardless of which `if` branches are taken.

## 6. Extending the design

A natural next step for a CV writeup is to note the limitation: this version assumes only one coin denomination is inserted per clock cycle, and that the testbench/environment is responsible for that timing discipline (debounced, one-coin-per-cycle). Real coin acceptors typically produce a pulse train that would need debounce and edge-detection logic ahead of this FSM — a good "what I'd add next" talking point in an interview.
