# Electronic Voting Machine (EVM) in Verilog HDL: Multi-Candidate Digital Voting Architecture with Hardware Debouncing and Mode Control

A modular, synthesizable **Electronic Voting Machine (EVM)** design in Verilog HDL. The architecture features multi-candidate vote logging, synchronous button debouncing/pulse-shaping, tamper-resistant mode control, and visual feedback indication targeting Xilinx FPGA architectures (Zynq-7000).

---

## 1. Overview

Electronic Voting Machines require strict digital integrity: button inputs must be reliably debounced to prevent duplicate vote registration, vote accumulators must be isolated from unauthorized increments during result readouts, and voter feedback must be immediate and unambiguous.

This project implements a complete 4-candidate EVM system in Verilog HDL structured into modular sub-blocks:
- **`buttonControl`**: Rejects high-frequency button chatter and generates a single-cycle valid pulse when an input button is continuously depressed for a predefined threshold.
- **`voteLogger`**: Maintains independent 8-bit vote tallies (up to 255 votes per candidate) and protects vote counts by restricting increments strictly to Voting Mode.
- **`modeControl`**: Manages visual feedback on an 8-bit LED bus, driving a 10-clock-cycle acknowledgment flash (`8'hFF`) upon casting a valid vote in Voting Mode, and multiplexing candidate tally values onto the LEDs in Result Mode.
- **`votingMachine`**: Top-level module integrating all submodules and routing status flags.

The system has been verified through behavioral simulation and RTL/gate-level synthesis in **AMD Vivado**.

---

## 2. Key Architectural Features

- **4-Candidate System**: Dedicated input channels and accumulators for Candidates 1 through 4.
- **Synchronous Digital Debouncing & Single-Pulse Generation**: Rejects contact noise and prevents multi-voting from sustained button holds by issuing exactly one single-cycle pulse per valid press.
- **Tamper-Resistant Vote Logging**: Accumulators increment only when `mode == 0` (Voting Mode). In `mode == 1` (Result Mode), vote increments are disabled.
- **Dual-Mode Visual Output (`led[7:0]`)**:
  - *Voting Mode (`mode = 0`)*: All LEDs illuminate (`8'hFF`) for 10 clock cycles to confirm receipt of a valid vote.
  - *Result Mode (`mode = 1`)*: LEDs display the 8-bit binary vote count of whichever candidate button is pressed.
- **Hierarchical Synthesizable Design**: Clean separation of control path, debouncing filters, and datapath registers targeting Xilinx FPGA primitives.
- **Verified with Vivado Design Suite**: Validated through RTL elaboration, technology mapping, and behavioral simulation waveforms.

---

## 3. Repository Structure

```text
.
├── Vote_machine.v                               # Top-level and submodule RTL implementations
├── votingMachine_tb.v                           # Behavioral simulation testbench
├── Voting machine  elaborated design schematic.png # Vivado RTL elaboration schematic
├── Voting machine systhesized desgin schematic.png # Vivado post-synthesis technology netlist
├── Voting Machine Waveform.png                  # Vivado behavioral simulation waveform
└── README.md                                    # Project documentation
```

---

## 4. System Architecture & Module Hierarchy

```
                                  +-------------------------------------------------------------+
                                  |                        votingMachine                        |
                                  |                                                             |
                   +---------+    |   +-----------------+                                       |
  button1 -------->|   bc1   |------->| valid_vote_1    |----+                                  |
                   +---------+    |   +-----------------+    |                                  |
                   +---------+    |   +-----------------+    |      +------------+              |
  button2 -------->|   bc2   |------->| valid_vote_2    |----+---->|  OR Gate   |-- anyValidVote|
                   +---------+    |   +-----------------+    |  |   +------------+      |       |
                   +---------+    |   +-----------------+    |  |                       |       |
  button3 -------->|   bc3   |------->| valid_vote_3    |----+  |                       |       |
                   +---------+    |   +-----------------+    |  |                       |       |
                   +---------+    |   +-----------------+    |  |                       |       |
  button4 -------->|   bc4   |------->| valid_vote_4    |----+  |                       |       |
                   +---------+    |   +-----------------+       |                       |       |
                                  |                             |                       |       |
                                  |                             v                       v       |
                                  |                     +---------------+       +-------------+ |
  clock ----------------------------------------------->|  voteLogger   |------>| modeControl |-----> led[7:0]
  reset ----------------------------------------------->|     (VL)      |       |    (MC)     | |
  mode  ----------------------------------------------->|               |------>|             | |
                                  |                     +---------------+       +-------------+ |
                                  +-------------------------------------------------------------+
```

### Module Description Table

| Module Name | Entity Role | Source | Function |
| :--- | :--- | :--- | :--- |
| `votingMachine` | Top-Level Wrapper | [`Vote_machine.v`](Vote_machine.v) | Interconnects debouncers, accumulator logger, OR logic, and mode controller. |
| `buttonControl` | Submodule (Instantiated 4x) | [`Vote_machine.v`](Vote_machine.v) | Filters raw button inputs, verifies continuous 10-cycle assertion, and issues a 1-cycle `valid_vote` pulse. |
| `voteLogger` | Submodule (1x) | [`Vote_machine.v`](Vote_machine.v) | Houses four 8-bit registers to accumulate vote tallies; increments only during Voting Mode. |
| `modeControl` | Submodule (1x) | [`Vote_machine.v`](Vote_machine.v) | Generates the 10-cycle LED vote confirmation pulse (`mode=0`) or displays candidate tally on `led[7:0]` (`mode=1`). |

### Top-Level Port Definitions

| Signal Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clock` | Input | `1` | Master positive-edge clock |
| `reset` | Input | `1` | Synchronous active-high reset |
| `mode` | Input | `1` | Operational mode select (`0` = Voting Mode, `1` = Result Mode) |
| `button1` | Input | `1` | Raw input button for Candidate 1 |
| `button2` | Input | `1` | Raw input button for Candidate 2 |
| `button3` | Input | `1` | Raw input button for Candidate 3 |
| `button4` | Input | `1` | Raw input button for Candidate 4 |
| `led` | Output | `8` | 8-bit active-high status/tally indicator bus |

---

## 5. Submodule Operation & Working Principle

### 1. Button Debouncer & Pulse Shaper (`buttonControl`)

Mechanical switches suffer from contact bounce and irregular hold durations. `buttonControl` solves both issues using an internal counter:

```verilog
always @(posedge clock) begin
    if(reset)
        counter <= 0;
    else begin
        if(button && (counter < 11))
            counter <= counter + 1;
        else if(!button)
            counter <= 0;
    end
end

always @(posedge clock) begin
    if(reset)
        valid_vote <= 1'b0;
    else begin
        if(counter == 10)
            valid_vote <= 1'b1;
        else
            valid_vote <= 1'b0;
    end
end
```

- **Noise Filtering**: Any button glitch lasting fewer than 10 consecutive clock cycles fails to trigger `valid_vote`.
- **Single-Pulse Generator**: When the button is held continuously, `counter` reaches `10`, causing `valid_vote` to pulse high for **exactly one clock cycle**.
- **Hold Protection**: On the subsequent cycle, `counter` advances to `11` and caps out. As long as the button remains pressed, `counter` stays at `11`, preventing repeated vote registrations from a single press.
- **Reset on Release**: When the user releases the button (`!button`), `counter` resets to `0`, preparing the circuit for the next press.

---

### 2. Vote Logger & Tamper Prevention (`voteLogger`)

The `voteLogger` module contains four 8-bit registers (`cand1_vote_recvd` through `cand4_vote_recvd`):

```verilog
always @(posedge clock) begin
    if(reset) begin
        cand1_vote_recvd <= 0;
        cand2_vote_recvd <= 0;
        cand3_vote_recvd <= 0;
        cand4_vote_recvd <= 0;
    end
    else begin
        if(cand1_vote_valid && (mode == 0))
            cand1_vote_recvd <= cand1_vote_recvd + 1;
        else if(cand2_vote_valid && (mode == 0))
            cand2_vote_recvd <= cand2_vote_recvd + 1;
        else if(cand3_vote_valid && (mode == 0))
            cand3_vote_recvd <= cand3_vote_recvd + 1;
        else if(cand4_vote_valid && (mode == 0))
            cand4_vote_recvd <= cand4_vote_recvd + 1;
    end
end
```

- **Integrity Gating**: Increments only execute when `mode == 0`. When switching to Result Mode (`mode == 1`), the registers are read-only, ensuring counting integrity during public audit or tally display.
- **Priority Encoding**: The `if-else` hierarchy resolves simultaneous button assertions deterministically.

---

### 3. Mode & Display Controller (`modeControl`)

The `modeControl` module governs the 8-bit `leds` output bus:

1. **Voting Mode (`mode == 0`)**:
   - An active-high pulse on `valid_vote_casted` (from the OR-reduction `anyValidVote = valid_vote_1 | valid_vote_2 | valid_vote_3 | valid_vote_4`) triggers an internal 10-cycle timing counter.
   - For 10 consecutive clock cycles (`counter > 0`), `leds` drives `8'hFF` (all 8 LEDs turn ON), providing visible voter acknowledgment.
   - After 10 cycles, `counter` resets to `0` and `leds` returns to `8'h00`.
2. **Result Mode (`mode == 1`)**:
   - The polling officer presses a candidate's button.
   - The corresponding candidate's 8-bit tally is multiplexed directly to `leds[7:0]`, displaying the vote count in binary.
   - If no button is pressed, `leds` displays `8'h00`.

---

## 6. RTL Elaboration & Synthesis Schematics

### Elaborated RTL Schematic
![Elaborated Design Schematic](Voting%20machine%20%20elaborated%20design%20schematic.png)
*Figure 1: Vivado elaborated schematic for `votingMachine`. Shows the four parallel `buttonControl` blocks (`bc1`–`bc4`), a 3-gate `RTL_OR` reduction tree generating `anyValidVote`, the central accumulator `voteLogger` (`VL`), and the display multiplexer `modeControl` (`MC`) driving output `led[7:0]`.*

### Synthesized Gate-Level Technology View
![Synthesized Design Schematic](Voting%20machine%20systhesized%20desgin%20schematic.png)
*Figure 2: Vivado technology-mapped schematic for `votingMachine`. Input ports pass through `IBUF` pads, the clock is distributed through a global clock buffer `clock_IBUF_BUFG_inst`, internal logic is mapped into LUT/FF hierarchical macros, and the 8-bit output drives `OBUF` pads (`led_OBUF[0]` through `led_OBUF[7]`).*

---

## 7. Behavioral Verification & Waveform Analysis

The testbench [`votingMachine_tb.v`](votingMachine_tb.v) applies a 100 MHz clock (`10 ns` period, `#5 clock = ~clock`) and runs a full operational sequence:

```text
Phase 1: Reset System (0 ns - 20 ns)
Phase 2: Cast Vote for Candidate 1 (hold button1 for 120 ns > 100 ns threshold)
Phase 3: Cast Vote for Candidate 2 (hold button2 for 120 ns > 100 ns threshold)
Phase 4: Cast Second Vote for Candidate 2 (hold button2 for 120 ns)
Phase 5: Cast Vote for Candidate 3 (hold button3 for 120 ns)
Phase 6: Switch to Result Mode (mode = 1 at t = 700 ns)
Phase 7: Query Candidate Tallies (interrogate candidate buttons)
```

### Simulation Waveform Breakdown
![Voting Machine Waveform](Voting%20Machine%20Waveform.png)
*Figure 3: Vivado behavioral simulation waveform for `votingMachine_tb` (1,000 ns timeline).*

### Chronological Signal Observations

| Time Window | Operational Phase | Signal Conditions | Internal State / Output Behavior |
| :---: | :---: | :--- | :--- |
| **0 – 20 ns** | Power-on Reset | `reset = 1`, `mode = 0`, all buttons `0` | All internal counters and vote tallies cleared. `led[7:0] = 8'h00`. |
| **20 – 140 ns** | Vote for Candidate 1 | `button1 = 1` for 120 ns | At $t = 120\text{ ns}$ (10 clock cycles), `bc1` asserts `valid_vote_1`. `cand1_vote_recvd` increments to `1`. `led` flashes `8'hFF` for 10 cycles, then clears back to `8'h00`. |
| **190 – 310 ns** | Vote for Candidate 2 | `button2 = 1` for 120 ns | At $t = 290\text{ ns}$, `valid_vote_2` pulses. `cand2_vote_recvd` increments to `1`. `led` flashes `8'hFF` for 10 cycles. |
| **360 – 480 ns** | 2nd Vote for Candidate 2 | `button2 = 1` for 120 ns | At $t = 460\text{ ns}$, `valid_vote_2` pulses again. `cand2_vote_recvd` increments to `2`. `led` flashes `8'hFF` for 10 cycles. |
| **530 – 650 ns** | Vote for Candidate 3 | `button3 = 1` for 120 ns | At $t = 630\text{ ns}$, `valid_vote_3` pulses. `cand3_vote_recvd` increments to `1`. `led` flashes `8'hFF` for 10 cycles. |
| **700 – 1000 ns** | Result Mode Query | `mode = 1`, testbench pulses buttons for 50 ns | System enters Result Mode. *(See engineering note below).* |

> [!NOTE]
> **Testbench Timing Analysis in Result Mode**:  
> In the testbench lines 106–134, candidate buttons are asserted for `#50` (5 clock cycles) during Result Mode. Because `buttonControl` requires `counter == 10` (10 clock cycles / 100 ns) to assert a valid pulse, a 50 ns pulse does not reach the qualification threshold. Consequently, `candidateX_button_press` remains low, and the waveform shows `led = 8'h00` throughout this phase. This provides practical verification of the debouncer circuit rejecting under-duration input pulses.

---

## 8. Synthesis & Implementation Observations

| Design Attribute | Specification | Evidence from Repository |
| :--- | :--- | :--- |
| **Target Architecture** | Xilinx Zynq-7000 FPGA | Stated in RTL header comments (`Vote_machine.v`) |
| **Clock Domain** | Single global synchronous domain | Buffered via `clock_IBUF_BUFG_inst` |
| **I/O Ports** | 7 Inputs (`clock`, `reset`, `mode`, `button[1:4]`), 8 Outputs (`led[7:0]`) | Mapped via dedicated `IBUF` and `OBUF` buffers |
| **Logic Cell Utilization** | Hierarchical LUT/FF distribution across `bc1-bc4`, `VL`, and `MC` | Confirmed in Vivado technology schematic |

> [!NOTE]
> Physical board constraint files (`.xdc`) and timing closure reports are not included in the repository. The modules represent synthesizable IP ready for top-level pin mapping to push buttons, slide switches, and onboard LEDs.

---

## 9. Engineering Takeaways & Best Practices

1. **Hardware Debouncing via Synchronous Sampling**:
   - Mechanical push buttons produce electrical bounce that can span milliseconds. Implementing digital counter thresholds ensures that noisy transients are rejected without requiring external analog RC filters.
2. **Preventing Multi-Voting through Single-Pulse Shaping**:
   - Without single-pulse generation, a voter holding a button down for half a second on a 100 MHz clock would register 50 million votes. Clamping the debouncer counter to an upper saturated state (`counter == 11`) guarantees that exactly one vote pulse is issued per distinct physical actuation.
3. **FSM & Mode Separation for Electoral Integrity**:
   - Decoupling vote logging from result interrogation at the RTL level ensures that checking results cannot inadvertently alter vote counts.

---

## 10. Limitations & Future Enhancements

- **Real-World Clock Prescaler**:
  - In a physical FPGA deployment with a 50 MHz or 100 MHz system clock, a 10-clock-cycle threshold equals 100 ns—sufficient for simulation, but shorter than physical contact bounce (typically 10–20 ms). Adding a clock prescaler or expanding the counter bit-width would scale debouncing to millisecond intervals.
- **Seven-Segment or LCD Display Integration**:
  - Converting the 8-bit binary LED output to Binary-Coded Decimal (BCD) driving a 7-segment display or an HD44780 LCD module for human-readable decimal vote counts.
- **Non-Volatile Memory (EEPROM / Flash)**:
  - Integrating an SPI/I2C memory interface to safeguard accumulated votes against unexpected power failures.
- **Officer Ballot-Enable Authorization**:
  - Adding a polling officer master enable signal so each voter can only cast one vote until the officer re-enables the machine for the next citizen.

---

## 11. Tools Used

| Tool | Purpose |
| :--- | :--- |
| **Verilog HDL (IEEE 1364-2001)** | RTL implementation and behavioral testbench |
| **AMD Vivado Design Suite** | RTL elaboration, gate-level synthesis, and behavioral simulation |
| **Git / GitHub** | Version control and source hosting |

---

## 12. Author

Created by **Chethan Aithal**  
*Electronic Voting Machine Verilog HDL Design Project for Digital System Design and FPGA Learning.*
