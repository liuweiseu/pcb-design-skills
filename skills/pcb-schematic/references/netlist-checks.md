# The checks every schematic gets (Rosenberg), in full

Run them from the netlist in the build (pcb-workflow skill, §10 gates 13-14), and read
their lists.

- **One-pin nets** fail, except a deliberate test pad: a label typed once is an
  unconnected pin.
- **One name per rail.** "VCC" on one sheet and "+5V" on another, or "GND", "DGND" and
  "AGND", are three nets that look like one. Print every power net with its pin count
  and the sheets it appears on.
- **One ground net, poured as one plane,** even when a datasheet draws AGND and DGND
  apart: a split makes return currents detour round it. The exception is real galvanic
  isolation (the Lorenz board's isolated DC/DC).
- **Copied blocks** bring their net names with them; a repeated name silently merges two
  nets.
- **Inductive loads** (relays, solenoids, motors, PCB coils, electromagnets) each have a
  path for their current when the switch opens: a freewheel diode, a bridge's body
  diodes, or a clamp rated for the peak current (component-selection skill, §15).
- **A fuse** (or PTC, or eFuse) on every input that can deliver more current than the
  board's copper and connectors survive. **Rate everything in series with it for the
  fuse's hold current, not the board's draw:** ECP5 build 31 put a 1 A / 0.5 W Schottky
  ahead of a 2 A-hold PTC, so a 1-2 A fault would have cooked the diode without tripping
  the fuse (both round-2 reviews). A 3 A SS34 in SMA replaced it.
- **Two supplies, two blocking elements.** A Schottky on the bench input keeps USB off
  the bench header; it does not keep the bench supply off USB's VBUS, which then
  back-feeds the laptop (ECP5 build 31; CopilotSDK round 2). Block each path: a P-FET on
  the USB path with its body diode pointing VBUS -> rail, gate pulled to ground (on) and
  lifted by the other supply's presence (off), as the Raspberry Pi Pico and Arduino do.
  It costs no drop on the main path; a second Schottky costs 0.35 V.
- **Trace a two-supply ORing in BOTH directions, with each FET's gate written out.** A
  P-FET ideal diode with its gate grounded conducts both ways once the output rail is
  up: powered from the second input, it fed the rail back onto the first input's
  connector, which lifted the second FET's gate and turned it off, leaving the board on
  a body diode at 4.1 V. The fix is one small N-FET (the first input's presence pulls the
  first FET's gate down; otherwise the second rail holds it up). "Neither feeds the
  other" is a claim to derive, not to write.
- **Straps against an FPGA that is still configuring.** A PHY or other chip that leaves
  reset while the FPGA configures samples its straps then, and the FPGA's configuration
  pull-downs (every unconfigured ECP5 user I/O, up to 150 µA) beat a chip's internal
  pull-up. Every strap that must read 1 gets an external resistor (4.7 k), and so does
  every strap the vendor says needs one (Realtek §7.8). ECP5 build 31 had RXDLY and
  PHYAD0 on internal pull-ups only.
- **A control whose idle must be safe rests where an absent host leaves it**
  (CostasLink, 2026-10-10, Response 15).
  - An unpowered host clamps its pins near 0.6 V through their ESD diodes; a configuring
    one may pull them up (the Zynq's configuration pull-ups, 10 k at the strongest) or
    down (the ECP5's).
  - A pull-up cannot hold a line high against the first, so the safe state must be LOW:
    make the line active-high (TX_EN, not TX_DIS), give it a pull-down that beats the
    configuration pull-ups (1 k: 0.35 V against a 74LVC's 0.8 V), and invert on the board
    when the chip's pin is active-low.
  - CostasLink's TX_DIS sat on a 100 k pull-down into the ADL5375's DSOP, which transmits
    "when grounded or floating", and the board has its own USB-C supply: the modulator
    ran, the synthesizers still programmed, whenever the PYNQ was off, booting its base
    overlay or loading another one.
  - Ask of every line the host drives: what does it do with the host off, configuring,
    and running somebody else's overlay? Latch enables want a pull-down too, so a
    floating LE cannot load a word.
- **Every host line needs a level of its own when the host is not there** (AMOD and RF-MOD,
  bring-up planning, 2026-11-15). Writing the bring-up driver's per-board pin profiles (what
  each line does with the FPGA's pin high-impedance) was a second review of the nine boards,
  and found:
  - two chip selects with no pull-ups, so two parts could drive one MISO;
  - clock and logic inputs of CMOS parts with no pull-downs, on boards that run from USB
    with no host at all;
  - a laser's blanking line whose resting state was "on";
  - a load switch whose own pull-down lets go after its first "on".
  - **The rule:** for each line, write down what the circuit does with the line floating,
    low and high, and give it the resistor that makes floating the safe one. A board that
    must work with no host is in that state all the time.
  - **Order pulls and power switches so that a powered receiver never sees a floating or
    wrong-way input** (GPiBridge, 2026-11-15, found in simulation before power): the pads'
    pull-downs made a listening SN75161B assert NRFD, NDAC and SRQ for the moment its 5 V
    came up.
  - **The FPGA's own pulls are part of the circuit:** a generated constraint rule that pulls
    every bidirectional pin up is wrong for a USB device's D+ and D- (the host's 15 k
    pull-downs then sit against it) and for a hot-plug input (ECP5-2ADC-2DAC, 2026-11-15).
    Read the generated constraint file against each pin's job (pcb-bringup skill).
- **Every op amp's supply range and input common-mode range against the rail it is on**
  (CostasLink, 2026-10-09, Response 9's self-review). The Costas loop's PI filter and VC
  stage were an OPA2187 on 3.3 V with both inputs at 1.65 V: the part's recommended
  supply starts at 4.5 V and its inputs stop 2 V below the rail. Every number of the loop
  had been computed and asserted; the op amp's own operating conditions had not been
  read. The schematic generator must assert, for each op amp, rail >= minimum supply and
  every input's quiescent voltage inside the common-mode range, from numbers typed from
  the datasheet beside the part.
  - **The same for every driver, at the lowest supply the board is promised** (AMOD and
    RF-MOD, pin audit, 2026-11-16): three motor and coil drivers sat below their minimum
    supply on USB alone (5 V less a Schottky's drop). Their bring-up tests had been written
    for USB alone too, so a pass or a fail would have said nothing.
- **A comparator or logic input on a connector** gets a series resistor sized to the
  input clamp's current limit at the worst signal a student can plug in (TLV3501:
  10 mA; 1 kΩ for a 10 V generator). An AC-coupling capacitor is a short at the signal's
  frequency, not a limiter (ECP5 CLK IN, build 31).
- **Polarized parts** the right way round, and every capacitor rated above the
  worst-case voltage across it, with margin.
- **Coupled windings:** transformer and coupled-inductor dots, and common-mode chokes
  wired common-mode.
- **No floating inputs:** unused logic inputs, op-amp sections (wired as grounded
  followers) and ADC channels go to a defined level.
- **A terminated control input is a load on what it controls** (AMOD, 555 tile, found
  writing its bench test on 2026-11-15, three weeks after the order). Its CV jack,
  DC-coupled to the control pin through 2.2 k with a 51 ohm termination to ground, drags
  the thresholds down: the tile will not run at the frequency its silkscreen prints. The
  oscillator tile's "at 0 V" turned out to mean "with a source holding the jack at 0 V".
  For every DC-coupled input, work out the node with the jack open, with a 50 ohm source at
  0 V, and with a high-impedance source, and write each block's expected numbers out of its
  netlist before the order (that is a design review; the bench test table as an order gate
  is in the pcb-bringup skill).
- **Values.** "10" typed for "10k" is a classic. Assert each design equation against the
  values the netlist really carries (gain, cut-off, divider ratio, LED current, time
  constant), as the Lorenz board's 147 assertions re-derive its equations.
- **Each equation's inputs: the guaranteed figure, at the operating point, through what
  the next stage really sees** (CostasLink's design review, Prompt 18; four reviewers
  found one each):
  - the datasheet row for the operating frequency (the ADL5611's 6 GHz P1dB, 16.0 dBm,
    sat in a 5.8 GHz budget whose row says 12.8);
  - the minimum or maximum, not the typical (the THS4541's input range is VS+ − 1.3 V
    guaranteed, VS+ − 1.2 V typical; the HMC536's isolation and P0.1dB were printed on
    the silkscreen at their typicals);
  - a supply's drop at every series part's maximum resistance from the lowest supply the
    board is promised (a PTC's R1max, a FET's RDS(on) max, the bead), and a pin's bias
    current through the divider that biases it (the ADL5375's 2 x 41 µA lifted a 0.5 V
    divider to 0.61 V);
  - a detector's gain as its load sees it: a switch that passes one leg of a pair against
    mid-supply passes half the differential swing (CostasLink's Kd was 2x too high, the
    loop ran at 2.05 kHz and ζ 0.48).
- **Ratings:** every part within its voltage, current and power at the worst-case input
  and temperature (component-selection skill, §12).
- **Options where unsure:** an empty footprint for the alternative, and a configuration
  that software can set rather than a jumper (pcb-bringup skill, "Remote first";
  pcb-workflow skill, "Think five steps ahead").
- **The drawing:** few wire crossings, sheets in order from input to output, and a block
  diagram first when there are many sheets. Rosenberg allows labels for buses and MCU
  I/O; the user's rule (wires, not labels) stands.

# The pin audit: power pins by voltage, pairs by polarity, unfitted parts both ways (ECP5-2ADC-2DAC, 2026-11-16)

ECP5-2ADC-2DAC rev A went to JLCPCB with its USB programming port dead, after the author's pin
audit and five LLM reviews in two rounds had all passed it: the FT2232H's VPHY and VPLL got
1.8 V where its data sheet says 3.0-3.6 V, and its D+ and D- were swapped. With no JTAG and no
UART, nothing on the board could be tested until it was reworked by hand. Both faults were
plain in the netlist against the data sheet's pin table. These are the schematic-side checks;
the gate (pcb-workflow skill, gate 2, 2a-2d) runs them as scripts that fail the build, and
every review brief asks the reviewers to redo them from the data sheets (pcb-design-review
skill).

- **Every power pin of every IC, by voltage (gate 2a).** For each IC, transcribe the data
  sheet's pin table: pin number, the data sheet's pin name, the voltage range it needs, and
  the data sheet's line quoted.
  - It covers every VCC, VDD, VIO, VCORE, VPHY, VPLL, AVDD, DVDD, VREF and bias pin; every
    regulator input and output; every pin an internal regulator feeds, with what that
    output may feed.
  - The script reads the netlist, finds the rail on each pin, and fails unless the rail's
    nominal voltage, with its tolerance, is inside the range. A pin missing from the table
    fails as well. Print the table in the release log.
  - The ECP5's schematic note "VREGOUT: internal 1.8 V, feeds VCORE x3, VPLL, VPHY" was the
    mistake itself, printed as a fact (component-selection skill, FT2232H).
- **Every pair's polarity, connector to chip (gate 2b).** USB D+/D-, LVDS and TMDS P/N,
  Ethernet MDI+/-, CAN H/L, RS-485 A/B and every clock pair.
  - Walk each line from the connector's pin to the chip's pin, by pin function, through
    every part in its path.
  - For ESD arrays with pass-through pin pairs (USBLC6-2: I/O1 is pins 1 and 6, I/O2 is pins
    3 and 4), series resistors, common-mode chokes, level shifters and analog switches,
    follow the data sheet's internal pairing.
  - Assert that the connector's + arrives at the chip's +. Where an FPGA pin can take either
    line, print which way round it landed. Print each pair's path.
- **Pin numbers by function, not by memory or variable name (gate 2c).** Every pin the
  generator names by number is read against the data sheet's table: `u.pin("8")` must match
  "8 DP". The ECP5's generator wrote `dmp, dpp = u.pin("8"), u.pin("7")`, and pin 7 is DM.
- **Parts that are not fitted are checked both ways.** The user (2026-11-16): "The checker
  script should not completely ignore do-not-fit parts, but instead should check the
  situation in cases where they are and are not fitted."
  - **How:** check the board as built, with every DNP part off. Then check it again with
    each DNP part fitted on its own, and with any combination meant to go on together.
  - **Why:** an option that is harmless today gets fitted later by someone who trusts the
    schematic.
    - GPSDO-PYNQ-Z2's 13 BAV99 input clamps are DNP. The symbol draws a common-anode pair
      where the part is a series pair, so a fitted clamp is two forward diodes across
      +3V3_A.
    - SyzygyRadioBoard's L1 (DNI) would short the PLL's VP to ground through L2.
- **Diodes and ties between rails.** `tools/pin_audit/pin_audit.py` also fails:
  - a diode path that conducts from one rail to another;
  - a diode symbol whose A/K pins disagree with the part's data sheet;
  - two rails of different voltage tied through a bead, an inductor or a resistor of
    10 ohm or less.
- **A schematic note, a generator comment or "verified" in a review brief is not evidence.**
  The ECP5's brief told the reviewers that "every IC's pin numbering" had been checked, which
  covered pin numbers, not voltages or polarity, and one reviewer restated the schematic's
  note as checked. A claim of "checked" names the script and its output file.
- **Every connector that follows a standard, against the standard's drawing, from the placed
  pads (gate 2d).** Pmod, SYZYGY, HDMI, USB-C, JTAG, any vendor header.
  - **How:** compute pin 1's place, which end power and ground take, and the row order from the
    placed pads' coordinates and the footprint's rotation, and compare them with the standard's
    own figure in that figure's stated viewpoint. `tools/pin_audit/connectors/` does it, and
    also mates every pair of boards meant to mate.
  - **Why it is a check of its own:** the first whole-tree audit (2026-11-16, `tools/pin_audit/`)
    found ECP5-2ADC-2DAC's Pmod sockets, and the IcepiZero Pmod adapter they were copied from,
    mirrored end to end against the Pmod spec's figure 5: a bought Pmod plugged in normally meets
    +3V3 on its IO1. The netlist was right and the drawing was wrong, so the checks above cannot
    see it.
  - Dual-row and right-angle headers: the pcb-layout skill's ten steps
    (references/dual-row-headers.md).
