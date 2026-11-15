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
- **Every op amp's supply range and input common-mode range against the rail it is on**
  (CostasLink, 2026-10-09, Response 9's self-review). The Costas loop's PI filter and VC
  stage were an OPA2187 on 3.3 V with both inputs at 1.65 V: the part's recommended
  supply starts at 4.5 V and its inputs stop 2 V below the rail. Every number of the loop
  had been computed and asserted; the op amp's own operating conditions had not been
  read. The schematic generator must assert, for each op amp, rail >= minimum supply and
  every input's quiescent voltage inside the common-mode range, from numbers typed from
  the datasheet beside the part.
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
