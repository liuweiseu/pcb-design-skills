# Power, current and heat: full rules (CLAUDE_PCB.md §15, §23)

The Halloween board (2026-10-07) was the first of the user's boards with real power: a 12 V
brick and amperes into PCB coils. Until it has been built, these are rules from the
standards and app notes, with the arithmetic checked.

## Width for current (IPC-2221)

- I = k * dT^0.44 * A^0.725, with A in mil^2, dT in C, k = 0.048 for outer layers and 0.024
  for inner.
- For a 10 C rise in 1 oz outer copper: 1 A needs 0.30 mm, 2 A 0.78 mm, 3 A 1.37 mm, 5 A
  2.77 mm; 2 oz halves those.
- Inner layers need about 2.6 times the area (3 A in 1 oz inner: 3.6 mm), and JLCPCB's
  inner layers are 0.5 oz unless ordered thicker.
- IPC-2152, which replaced 2221's charts, allows more on boards with planes; 2221 is the
  safe side.
- Compute it per net in the build and fail on a narrower track (`pcb-workflow`, gates 11
  and 16).

## Drop and heat

A square of copper is 0.98 mohm at 0.5 oz, 0.49 mohm at 1 oz and 0.25 mohm at 2 oz, rising
0.39 % per C. 100 mm of 2 mm track in 1 oz is 50 squares, 25 mohm: 75 mV and 0.23 W at 3 A.
Count the squares of every high-current path, its ground return included (Rosenberg).

## Vias and connectors

- Vias carry about 1 A each (0.3 mm drill, for a 10 C rise): use an array at every power
  layer change (at least four for 3 A), and thermal vias under hot parts.
- Connectors: check the rating of the exact part. Barrel jacks run from 1 A to 5 A and more;
  2.54 mm headers about 3 A a pin; screw terminals by their datasheet.

## Copper weight

- Order 2 oz outer copper when a coil or power path needs the conductance. It costs extra and
  raises the fab's minimum track and gap for the whole board. Say so on the order, and in the
  release notes the user pastes.
- **2 oz copper changes the rules.** JLCPCB's 2 oz track and gap minimum is 8 mil, so the
  board's 0.2 mm rules go to 0.21; the order form's "Outer Copper Weight" must say 2 oz
  (generated, with the reason); and KiCad's Python cannot set the stackup
  (`GetStackupDescriptor()` is a bare SwigPyObject), so write the `(stackup ...)` block into
  the saved file, or the gerber job file says 0.035 mm.

## Check the heatsink on the board as built, in the build

- Export each pour as KiCad filled it and the ground plane's fill (with the cuts the back
  runs make), solve two copper sheets with FR4 between on a 0.5 mm grid, and fail above a
  junction limit (PID board: 125 C, leaving 25 C under 150 for the model's error).
- Calibrate the model on one datasheet figure (TI: DDPAK on 1 in^2 of 1 oz, 26 C/W).
- The as-built pours came out a few degrees worse than the rectangle the comparison assumed.
- Keep back runs out from under a heat-spreading pour: the plane there is half the heatsink;
  send supplies up the edge.
- A DPAK on a small pour is ~70 C/W: 2 W is too much.

## Hot-plugging a supply on a cable rings

The cable's inductance and an all-ceramic input make an LC that rings to about twice the
supply at contact (Linear Technology AN88): 12 V becomes 24 V or more. Damp it with a bulk
electrolytic or polymer capacitor (its ESR is the damping), and clamp with a TVS above the
working voltage.

## Protect the input

- reverse polarity: a P-MOSFET with its gate pulled to ground through a resistor and clamped
  by a zener, or an ideal-diode controller (a series Schottky wastes 0.4 V x I);
- overcurrent: a fuse or PTC that opens below what the copper and the connector survive, or
  an eFuse, which also limits inrush;
- a TVS. A 12 V, 5 A brick can make a dropped paper clip across two pads hot enough to burn a
  finger.

## Budget the bench input from the supply's terminals to the rail, at full load (ECP5-2ADC-2DAC board A, 2026-11-16)

- **What happened:** J601, the bench input, is a 0.1" 2-pin header, then an SS34 and a PTC.
  5.00 V at the supply was 4.52 V at J601 through a BNC cable and thin wire, and 4.22 V on
  +5V, at 0.385 A with the FPGA unconfigured. Configured, the board draws nearly twice that.
- **The rule:**
  - give a bench input a connector that takes real leads (a screw terminal, a barrel jack),
    not a 0.1" header;
  - use an ideal-diode FET rather than a Schottky where the drop matters (see "Protect the
    input" above);
  - set the rail's window so that the board's own drop, from the supply's terminals to
    the rail at full load, fits inside it;
  - tell the person at the bench to use short, thick leads straight to the input
    (pcb-bringup skill).

## Switching regulators draw about constant power (ECP5-2ADC-2DAC board A, 2026-11-16)

Once the bucks regulate, a board draws about constant power, so its input current falls as
its input voltage rises: board A drew 0.388 A at 4.0 V and 0.369 A at 5.0 V. Budget the input
current (fuse, PTC, connector, the drop above) at the lowest input voltage, not the nominal
one. A power-up staircase check must test the power (V x I) for "rising with the voltage", not
the current (pcb-bringup skill).

## Inductive loads

Coils, motors, solenoids, relays keep their current when switched off. Give each a freewheel
path (an H-bridge's body diodes, or a diode across a low-side-switched coil). Expect
regeneration: a decelerating motor or a collapsing coil returns energy through the bridge
into the supply, and if the bulk capacitance (with a TVS or clamp) cannot absorb it, the
rail rises and kills what hangs on it ("supply pumping").

## Switching converters

The datasheet's layout is the layout. Keep the hot loop (input capacitor, high-side and
low-side switches) as small as possible, the switch node small (`pcb-layout`), the feedback
trace away from the inductor and the switch node, and the controller's ground at a quiet
point of the plane. Exposed pads get via arrays to the inner planes.

## Current sensing

A Kelvin (four-terminal) connection to the shunt, the two sense lines routed as a pair, an
RC filter at the amplifier or ADC. A low-side shunt lifts the load's ground; a high-side one
needs an amplifier with the common-mode range.

## Gate drive

A small gate loop (driver, gate, source, back), a gate resistor to set the edge and damp
ringing, the bootstrap capacitor at the driver, dead time between the two switches of a half
bridge.

## Budget a rail in the board's worst state, not its working one (GPSDO rev B, 2026-10-10)

- A self-biased unbuffered LVC gate draws about 10-15 mA at its threshold (rev A measured
  180 mA from 14 of them), not the 3 mA the sheet had assumed.
- Rev B biases a replica gate on every channel all the time. With nothing driven and nothing
  parked, all 26 gates sit at threshold: 290-420 mA on a 300 mA LDO.
- Put the measured number on the sheet, the instruction in the bring-up steps, and keep the
  input fuse sized for its fault job, not the current.
- **Check which state the instruction actually produces.** The first version said "fit every
  shunt (50R or PARK) before the first power-up". A 50 ohm termination shunt does not quiet
  an AC-coupled, self-biased gate: with its source off, the gate still sits at threshold.
  Only PARK does. Writing the bring-up step by step, with the expected reading at each, is
  what caught it (order day): "0.25-0.35 A with every channel parked" cannot be written for a
  board with eleven 50R shunts and no sources.

## A passive board can take a little power from the host connector (§23)

A step attenuator (150 uA) and an oscillator (2 mA) run on the host's 3.3 V through the
board's own Pmod plug, with no USB tile (the user: "If something can run on 3.3V, it could
still be plugged into the PMOD port"). Pour the 3.3 V on an inner layer and give it a
PWR_FLAG in the schematic: no regulator pin drives it.

## Mains stays off the board

A certified (UL/ETL-listed) external adapter. A board that touches mains needs the creepage
and clearance of a safety standard (IEC 62368-1), which no board here has had.
