# Electronic Voting Machine (EVM) using Verilog HDL

## Overview

This project implements a simple Electronic Voting Machine (EVM) in Verilog HDL. The system allows users to cast votes for one of four candidates, stores the votes, and displays the results through LEDs.

## Features

- Supports 4 candidates
- Vote validation using button press detection
- Vote counting and storage
- Voting mode and result mode
- LED indication for successful vote registration
- Modular Verilog design

## Project Structure

```text
buttonControl.v   -> Validates button presses
voteLogger.v      -> Records and stores votes
modeControl.v     -> Controls voting/result display modes
votingMachine.v   -> Top-level module
votingMachine_tb.v -> Testbench
```

## Modules

### buttonControl

Detects a valid button press and generates a single vote pulse.

**Inputs**
- `clock`
- `reset`
- `button`

**Output**
- `valid_vote`

---

### voteLogger

Stores votes for each candidate.

**Inputs**
- Candidate vote signals
- Clock and reset
- Mode selection

**Outputs**
- Vote count for each candidate

---

### modeControl

Controls system operation based on mode selection.

**Mode 0 (Voting Mode)**
- Accepts votes
- LEDs indicate successful vote registration

**Mode 1 (Result Mode)**
- Displays vote count of the selected candidate

---

### votingMachine

Top-level module integrating all submodules.

## Working

### Voting Mode (`mode = 0`)

1. User presses a candidate button.
2. Button press is validated.
3. Vote is recorded.
4. LEDs briefly turn ON to confirm the vote.

### Result Mode (`mode = 1`)

1. Press a candidate button.
2. Corresponding vote count is displayed on LEDs.

## Simulation

Run the provided testbench:

```verilog
votingMachine_tb.v
```

Example votes:

| Candidate | Votes |
|------------|--------|
| Candidate 1 | 1 |
| Candidate 2 | 2 |
| Candidate 3 | 1 |
| Candidate 4 | 0 |

## Requirements

- Verilog HDL
- ModelSim / QuestaSim / Vivado Simulator / Icarus Verilog

## Future Improvements

- Voter authentication
- LCD/OLED display
- EEPROM vote storage
- More candidate support
- FPGA implementation

## Author

Electronic Voting Machine project developed using Verilog HDL for Digital Design and FPGA learning.
