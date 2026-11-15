---
name: pcb-bringup
description: Bring-up and debuggability of a PCB - remote control instead of jumpers, monitor muxes and current monitors, test points as MMCX/U.FL jacks, monitor-tap resistors, bring-up order and plans, handbook pictures, firmware/gateware written before ordering, FPGA tool pitfalls, protocol decoders and self-capture. Use when designing test points or probe access, writing a BRINGUP.md or HANDBOOK.md, planning the first power-up, debugging a board on the bench, or writing the first firmware/gateware for a new board.
---

# Bring-up and debuggability (CLAUDE_PCB.md §9)

Design the board so the user can debug it remotely, plug instruments in and walk away,
and so the agent can take its own measurements. Related skills: `pcb-silkscreen` (labels),
`pcb-layout` (where taps go), `component-selection` (protection, ratings), `rf-design`
(simulating the laid-out circuit), `pcb-workflow` (build gates).

Reference files:
- `references/remote-and-monitoring.md`: the full remote-first rules (switch types, the
  DVM monitor mux, current monitors, RF self-test, PE43711 example). Read when adding
  controls, jumpers, monitor points or a self-test path.
- `references/test-points-and-taps.md`: the jack/tap rules with the stories behind them
  (GPSDO bias pull, OWL rev A test pads, CostasLink jacks, the handbook pictures). Read
  when placing test points or monitor taps, or generating bring-up figures.
- `references/firmware-gateware-fpga.md`: firmware before ordering, gateware reset
  state, Vivado/Yosys/nextpnr facts, RTL co-simulation, pin-layer tests, RP2350
  open-drain. Read when writing the first firmware or gateware.
- `references/bench-case-studies.md`: the bring-up-plan table, VNA pre-measurement of
  accessories, the CostasLink notch, aggressor sources, the op-amp board as a lab
  instrument. Read when writing a BRINGUP.md or interpreting a first measurement.

## Remote first

- **Anything a jumper, a DNP option or a re-cabling would set, set it from software
  instead** (the user, 2026-10-29: more time away from the bench than at it). CostasLink
  rev A's loop sign needed two jumpers moved by hand and every test needed a cable moved.
  - **Pins are not the obstacle:** static settings go on an I2C GPIO expander (8 outputs
    for under $1) on a bus the board already has; fast signals stay on host pins.
  - **Defaults:** expander outputs come up as inputs, so pull resistors give the safe or
    usual setting at power-up; the board works with no firmware, as with a jumper.
  - **Read it back** (the expander's input register) and log it with every measurement.
  - **Right switch per signal:** logic choice -> logic gate (XOR, 2:1 mux); DC to ~100 MHz
    -> analog switch (1-5 ohm, a few pF); RF -> RF switch (0.5-1 dB loss, 30-50 dB
    isolation).
  - **Keep a jumper where a switch costs what matters** (ahead of an LNA, in a precision
    reference, in a power path or a safety choice). Write the reason beside it.
- **DC levels too: a monitor mux to a DVM jack.** Route every interesting DC node (rails
  at source and far load, Kelvin taps across each high-current part, every bias and
  reference, each regulator's in/out) through a dual 16:1 analog mux, ideally on I2C
  (e.g. MAX14661, +-5.5 V on a single supply; check stock), to a two-terminal DVM jack and
  a spare ADC channel. Divider ahead of nodes over range; never mux high-impedance, loop
  filter, fast or RF nodes (buffer or leave out). Details in the reference.
- **Currents too:** an I2C current monitor (INA226 class, few-mohm shunt) on each rail
  feeding a separate section.
- **RF boards test themselves:** internal loopback through a fixed pad with 50 ohm loads,
  each amplifier's enable on a control line, a selector routing monitor taps to one
  analyzer jack and one or two scope jacks.
- **A part can have switches and SPI at once** when its datasheet offers a parallel mode
  (PE43711: DIP plus pull-downs plus LE pull-up; see the reference).

## Plug in; don't solder or hold

- **The user does not solder wires or hold probes.** Labelled test points with ground
  nearby, U.FL monitor taps for signals worth scoping, headers that take standard probes
  (ECP5 R17, GPSDO P2). Plug a USB scope in and walk away: **lots** of taps, on every
  analog node worth a look (GPSDO r45, REVB #19).
- **Every test point is an MMCX jack; U.FL only where there is really no room for MMCX**
  (2026-11-07, after OWLternating Current rev A). A jack carries its own ground. Label
  each with its net name in silk. **Leave the jacks unpopulated in the production run**
  (the bare footprint is a test pad). Supersedes the 2026-10-10 pad/U.FL hold-time rule;
  hold time now only picks MMCX vs U.FL where space is tight.
  - Anything a computer-controlled instrument will log is a jack even when a meter would
    do (CostasLink Prompt 35). A jack drawn late on its sheet gets explicit references.
  - U.FL is rated for 30 matings, MMCX for about 500.
- **A monitor tap's series resistor is its divider and its load** (GPSDO r45): 450 ohm is
  a 10x probe into 50 ohm (loads the node with 500 ohm); 1 kohm is /21 (loads with 1 k).
  A series capacitor keeps a biased node's DC and keeps a 50 ohm scope from pulling rail
  current.
  - **Never tap a node whose amplitude sets a timing** (comparator/squarer input behind a
    series resistor); tap the low-impedance side.
  - **Follow a tap's DC path into the scope:** 50 ohm and the ADALM2000's 1 Mohm are
    DC-coupled. A tap on a node whose DC is set through a high resistance needs the
    coupling cap between it and the node, or its own series cap.
- **Tap the node nothing else reaches** (GPSDO rev B: the squarer's output, not the input
  a tee already shows).
- **A probe loop on every op-amp output**, and on a push-pull's bases, so the crossover
  jump (~1.2 V as the output crosses zero) is visible; print a loop's name rotated 90
  degrees between the wires when there is no room beside it (PID board).
- **Probe-ability beats PCB price on a low-volume board** (PID board: 170 x 120 mm kept
  over the 100 x 100 discount). Shrink a board every student gets; let a lab-station board
  be big.
- **Rails at a glance:** an LED per rail and an "in range" indication where it matters
  (GPSDO P40, REVB #6); drive the LEDs so they do not load a quiet rail.
- **A picture beside every place a bring-up step names**, generated in the build from
  the 3D render, with a check that the printed words sit beside and nearest their spot
  (GPSDO `gen/handbook_figs.py`; details in the reference).

## Bring-up plan and order

- **Bring-up order** in a `HANDBOOK.md`: current-limited bench supply first, then each
  rail, then the programmer, then the first firmware, then the interfaces (ECP5 §4,
  GPSDO P39). Write each step with its expected reading; that catches wrong instructions.
- **A bring-up plan is a table from the dead-on-arrival list to the stage that retires
  each risk** (CostasLink `BRINGUP.md`): stages in order with connections, measurement,
  pass condition and what to do on failure; a last table mapping DOA item -> stage ->
  fallback. Unspecified accessories: write assumed numbers into the budget as
  assumptions and make measuring them a step. A 40 dB external PA wants a pad on its
  input (the board's +10 dBm drives it 17 dB into compression).
  - **Measure accessories on a VNA before the board arrives** if one is within reach;
    quote the `.s2p` files by name in the plan (CostasLink Prompt 42).
- **Say exactly what to buy and what plugs where** (GPiBridge `BRINGUP.md`): name the
  probe and cables, each stage's connections and what the agent does then; start with a
  partner scriptable at both ends (a Prologix in device mode for a GPIB board).
- **Bench instruments are scriptable** (`lab-instrument-control`: Siglent scopes and
  generators, an HP 33120A over GPIB, an ADALM2000). Design tests that use them.
- **Symmetric connectors need a check, not just a mark:** a 2 x 12 grid solders in
  turned round as easily as right; give a meter check after two pins are tacked (one
  contact must read 0 ohm to GND).
- **Read the DNP flag before saying what is fitted.** A drawn part is not a fitted part
  (GPSDO: a DNP 51 ohm terminator was called fitted and a working test dropped);
  `excluded_from_assembly.csv` answers it in one grep (GPSDO r45).

## On the bench

- **Before calling a dip the chain's response, check that it follows a knob in the
  path** (CostasLink rev A). Sweep at several settings of an attenuator, switch or enable
  in the path and believe only what follows it. Measure the leak floor first
  (transmitter on, receiver input terminated, no cable). Then model the input network as
  laid out (`rf-design`) before suspecting chips.
- **Separate the paths before interpreting a shape** (§27): a knob in the path sorts a
  real response from a leak.
- **Check a loop's sign on the bench before closing the loop:** with the loop held and
  the carrier on a known side of the LO, the arms' phase order (Q ahead of or behind I)
  gives the sign. A wrong sign with a sign() detector holds at +-90 degrees with the
  comparator chattering, which looks like lock (§27; the design rule is in `rf-design`).
- **Try a new bench source as an aggressor before trusting it as a channel** (GPSDO
  r45: a USB-powered CircuitGear's DDS brought its ground and spurs, every other
  channel's beat chattered in common mode).

## Firmware and gateware are part of the design

- **First firmware written and building before the board is ordered**; it shakes out pin
  and clock choices (GPSDO r30 #28: the I2C driver could not read until bring-up).
- **Write the experiment's gateware before ordering, and read its reset state against the
  board** (CostasLink Response 15): writing `safe()` found the board's idle was not safe
  (see `pcb-schematic`, "rests where an absent host leaves it"). Keep a REVA_CHANGES list
  (found / what / change / state).
- **FPGA tool facts, RTL co-simulation, pin-layer tests on a PC, RP2350 open-drain:** see
  `references/firmware-gateware-fpga.md`.
- **Check the protocol with somebody else's decoder:** record the simulated bus as a VCD
  and have sigrok-cli decode it (GPiBridge `firmware/test/sigrok_check.py`); an engine
  and simulator by the same author share misunderstandings.
- **Give the board a way to see itself:** a spare core sampling its own pins into a VCD
  is a logic analyser with no wires.

## Other

- **Check a product name against trademark rules, not just search results:** Raspberry
  Pi's rules forbid "Raspberry" as a hardware brand ("RaspberryGPiB" was declined).
- **A book circuit as a lab instrument: say what it is good for, circuit by circuit**,
  against the real numbers; non-idealities are the lesson, a dead output transistor is
  not (op-amp board; see `references/bench-case-studies.md`).
- **Decide the protection before the floorplan** (budget lesson; see
  `component-selection`).
