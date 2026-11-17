# Remote control and monitoring: full rules (CLAUDE_PCB.md §9, §24)

## Remote first

**Anything a jumper, a DNP option or a re-cabling would set, set it from software
instead.** The user (2026-10-29): "I spend more time away from the bench than at it, and
having remote control of these things is generally better than requiring me to come in."
CostasLink rev A's loop sign needed two jumpers moved by hand, and every test of its night
needed a cable moved (its REVB "Quality of life" rows are the worked list).

- **Pins are not the obstacle.** Static settings go on an I2C GPIO expander (8 outputs for
  under $1, no host pins) on a bus the board already has. Fast signals stay on the host's
  pins.
- **Defaults:** an expander's outputs come up as inputs, so pull resistors give the safe or
  usual setting at power-up. The board then works with no firmware, as with a jumper.
- **Read it back:** read the state back (the expander's input register) and log it with
  every measurement.
- **Use the right switch for each kind of signal:**
  - a logic choice (a sign, a source select): a logic gate (XOR, 2:1 mux), with no
    resistance question at all;
  - DC and up to some 100 MHz (terminations, gain and bias resistors, a reference clock):
    an analog switch (1-5 ohm, a few pF);
  - RF (loopbacks, terminations, monitor routing): an RF switch, at 0.5-1 dB and 30-50 dB
    of isolation.
- **Where a switch is a bad idea:** a jumper stays where a switch would cost what matters:
  ahead of an LNA, where its loss is noise figure; in a precision reference; in a power path
  or a safety choice. Write the reason beside it.

## A monitor mux to a DVM jack

The user (2026-10-29): "if it's a few dollars to analog MUX every interesting signal down
to a few connectors for DVMs, if we don't need to monitor things simultaneously, that would
have made finding the high resistance path into the USB plug much faster". CostasLink rev
A's 5 V input path lost 192 mohm from VBUS to +5V_RF (its REVB row 2), and finding which
part took it meant probing by hand.

- **What to route:** every interesting DC node:
  - each rail at its source and at its far load;
  - both sides of each part in a high-current path (fuse, FET, ferrite, connector), as
    Kelvin taps;
  - each bias and reference (V_MID, the DACs' outputs, the FDAs' Vocm, the comparators'
    thresholds);
  - each regulator's input and output.
- **The mux:** a dual 16:1 analog mux, ideally one on I2C. For example the MAX14661 takes
  +-5.5 V signals on a single supply; check its stock at design time. A dual mux puts any
  two of the 16 nodes across the meter, so a drop is read differentially, with no ground
  error.
- **Where it goes:** to a two-terminal DVM jack (banana or a 2-pin header), and to a spare
  channel of the board's own ADC for unattended logging.
- **Why the mux's resistance doesn't matter:** a 10 Mohm meter makes its 10-100 ohm
  irrelevant. Its nA of leakage is also nothing on a low-impedance node.
- **Nodes over the mux's range:** a precision divider ahead.
- **Never mux a node whose leakage or capacitance matters:** a high-impedance node, a loop
  filter, a fast or RF node. Buffer it first, or leave it out.

## Currents

A current monitor on each rail that feeds a separate section, on I2C (INA226 class, a few
mohm shunt). The bench supply's one number cannot say which section draws what, or which
part is hot.

## Let the firmware read its own rails (GPiBridge rev A, `bringup/REVB.md` 1.2)

- An MCU's spare ADC pins cost a divider each; left unconnected, the only way to a rail is a hand
  on a probe.
- Route VBUS, each switched rail and the core supply to ADC pins and report them in the status
  command.
- Until then the chip's temperature sensor, read against the ADC's reference, gives the 3.3 V rail
  to about 5 % with no pin at all (RP2350: 0.706 V at 27 C over the rail).

## RF self-test without hands

- an internal loopback through a fixed pad, with a 50 ohm load on each port, so calibration
  and leak tests run any time;
- each amplifier's enable on a control line;
- a selector that routes the monitor taps to one analyzer jack and one or two scope jacks.

## Manual switches and a bus at once (AMOD/RF-MOD, §24)

A step attenuator can have switches and SPI at once. The PE43711's direct parallel mode
(P/S low, LE high) is pSemi's "ideal for manual control": an 8-way DIP (way 1 drives P/S
for SPI, ways 2-8 the bits), 100 k pull-downs on every bit and P/S, LE pulled up by 100 k so
a floating FPGA pin leaves the switches in charge. In serial mode the parallel pins must be
low (every bit off). The chip still needs its 3.3 V: switches do not make an active switch
array passive.
