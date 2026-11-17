---
name: pcb-bringup
description: Bring-up and debuggability of a PCB - remote control instead of jumpers, monitor muxes and current monitors, test points as MMCX/U.FL jacks, monitor-tap resistors, bring-up order and plans, bench visits and a STATUS.md, rehearsing the bring-up on a simulated bench and the firmware on a PC, handbook pictures, firmware/gateware written before ordering, FPGA tool pitfalls, rework instructions, protocol decoders and self-capture. Use when designing test points or probe access, writing a BRINGUP.md or HANDBOOK.md, planning the first power-up or the bench time, debugging a board on the bench, or writing the first firmware/gateware for a new board.
---

# Bring-up and debuggability (CLAUDE_PCB.md §9, §30-33)

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
- `references/firmware-gateware-fpga.md`: firmware before ordering and on a PC before
  power (pty, planted faults, bus fights), unsimulated code, RP2350/Pico SDK traps,
  gateware reset state, Vivado/Yosys/nextpnr/ecppll facts, ECP5 global clocks, RTL
  co-simulation and the bench procedures run live against it, pin-layer tests, raw mode,
  RP2350 open-drain. Read when writing the first firmware or gateware.
- `references/bench-planning.md`: visits, named cables, `STATUS.md`, parking the board,
  the one test table, the simulated-bench rehearsal, counting visits, self-test cables,
  modelling the bench, switch settings, switchable loads, the bench supply, the bench
  input budget, instrument claims. Read when planning the bench time or writing the
  bring-up tool.
- `references/bench-case-studies.md`: the bring-up-plan table, VNA pre-measurement of
  accessories, the CostasLink notch, aggressor sources, the op-amp board as a lab
  instrument, powering ECP5 board A (rework, USB plug-in, photos). Read when writing a
  BRINGUP.md, a rework step, or interpreting a first measurement.

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
- **Let the firmware read its own rails** (GPiBridge rev A, `bringup/REVB.md` 1.2): VBUS,
  each switched rail and the core supply to spare ADC pins through a divider each,
  reported by the status command. Left unconnected, the only way to a rail is a hand on a
  probe. Until then the temperature sensor against the ADC's reference gives the 3.3 V
  rail to about 5 % (RP2350: 0.706 V at 27 C). See `references/remote-and-monitoring.md`.
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
- **Print a test header's names next to the pins they name** (ECP5 board A, 2026-11-16):
  J602's rail names sat beside its ground row, and the first meter walk read -2.507 V on
  every pin. Signal row next to the names, ground on the far row with "GND" printed by it;
  a "top row = GND" note elsewhere does not undo the names' position.
- **For the meter, a loop at each end of a series resistor whose drop is a lesson** (op-amp
  board, 2026-11-15: 2 mV of bias current across the 1 k input resistor, with a loop on
  the base side only and a screw head at the other end).
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
  contact must read 0 ohm to GND). For a standard 2-row connector (Pmod), before power,
  plug in a bought module and buzz its GND to GND and VCC to 3V3 (under 1 ohm); the
  geometry rules are in `pcb-layout`, "Dual-row headers" (2026-11-16).
- **Read the DNP flag before saying what is fitted.** A drawn part is not a fitted part
  (GPSDO: a DNP 51 ohm terminator was called fitted and a working test dropped);
  `excluded_from_assembly.csv` answers it in one grep (GPSDO r45).

## Plan the bench time (§30-32; details in `references/bench-planning.md`)

The user's minutes at the bench are the constraint (the user, 2026-11-15: "it'll be easy for
me to get confused when I pop in and change some physical configuration, so you'll need to
always remind me of where we're at so that I can sit down and *correctly* do what needs
doing").
- **Cut a bring-up into visits** (AMOD/RF-MOD, 2026-11-15): one set of cables, what to set,
  then what the agent measures alone. Name every cable once for the whole bring-up (G1, S1-S4,
  P1, SA), on tape at both ends; sort tests by who must be there and run the unattended ones
  first; a picture with every card, drawn from the board's geometry.
- **Say where the bring-up stands in a file the tool rewrites** (GPiBridge, AMOD
  `bringup/STATUS.md`): boards against stages, what is cabled, what passed, the next physical
  thing in the silkscreen's words. Begin every bench message with it. Name each board at
  first plug-in (A1, L1), tied to its serial, written on it, with an "identify" command.
- **Park the board between steps** (GPiBridge): off the bus, outputs off, told to stay so at
  the next power-up, so any cable may be changed; one LED says so.
- **One table of tests, read by everything** (§30): jacks, stimulus, model, limits; cards,
  tool, pictures and rehearsal are made from it, and a missing jack or too many channels
  fails on the PC (three cross-tile jack names were wrong in the first draft).
- **Rehearse the whole bring-up on a simulated bench before a board is touched**: an 8-bit,
  clipping, noisy scope; boards broken on purpose must fail the right tests. It found an edge
  counter without hysteresis, a delay estimate that failed on ringing, a fault that could not
  show. Say in the plan that it cannot prove the models right.
- **The bench's test table is an order gate:** working each block's expected numbers out of
  its netlist is a design review. AMOD's 555 tile will not run at its printed frequency (its
  terminated CV jack drags the thresholds), found three weeks after the order. Work every
  DC-coupled input open, at 50 ohm to 0 V and high-impedance; print each input's resistance
  beside its jack.
- **Count the visits at design time, and design them away:** a bench power header, rail
  access, one "all tiles on" line, a divided monitor jack on every driven output, a looped
  pair of host lines (AMOD `REVB.md` section 2).
- **Every connector gets a test before the order, not "later gateware"** (ECP5, §31): it
  found constraints pulling USB up inside the FPGA and an unchecked DDR-register bank.
- **A board with converters tests itself through a few cables, and next revision through
  none** (ECP5: DAC->ADC and CLK OUT->CLK IN SMA loops; matched full scales, clock counters,
  a clock mux, PHY loopback). Keep one generator-and-scope visit for the volts.
- **Plan tests that use the board on itself before the bench instruments:** PLL phase steps
  on FPGA-driven sample clocks gave an effective 4 GS/s DAC->ADC capture with no scope (ECP5
  board A, 2026-11-16, `ets.sv`). Keep sample clocks on FPGA outputs a PLL can drive.
- **A board that its USB cable also powers cannot be power-cycled from the PC** (ECP5): put a
  load switch after the inputs join, on a spare USB-bridge pin, pulled on.
- **A test runs where its part is in specification, and names its supply** (AMOD,
  2026-11-16: three drivers below their minimum supply on USB alone).
- **Put the bench on the model before quoting a number in a handbook** (op-amp, §32: coax,
  scope, probe, meter and generator in the SPICE deck turned "no ringing" into 9 %
  overshoot). The check behind a sentence must measure what the sentence says.
- **Enumerate every switch setting in the model** (64 settings in a tenth of a second), **look
  for instability at more than one DC level** (a class-B stage quiet at 0 V oscillates with
  its output at 3 V), and **order switch visits to change one slider each and end where they
  began**, knowing which settings have no signature at the jacks (op-amp, §32).
- **Budget the bench input from the supply's terminals to the rail, at full load** (ECP5
  board A: 5.00 V at the supply, 4.22 V on +5V at 0.385 A): real terminals, an ideal-diode
  FET where the drop matters, a rail window the board's own drop fits inside; short, thick
  leads.
- **Let visits that wait on another board's bring-up wait, not block:** the tool offers the
  next visit that can run (2026-11-16).

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
- **A hand on a probe gets a beep, not a prompt** (GPiBridge `run.py rails`): the tool polls
  the scope, knows the rail by its voltage, records it and beeps; the person never reads a
  screen or types. A walk ends only after most of it is read, never on the first odd
  reading (ECP5 board A: a misplaced probe ended one after 9 s).
- **Two of your own boards are each other's test fixture** (GPiBridge `++t raw`, `run.py
  pair`): one asserts each line alone, the other must read exactly that line, both ways, in
  every driver mode; it names an open joint, bridge or turned connector by contact number.
- **Find out what is plugged in; do not assume it** (ECP5): a few-mV DAC step read on both
  ADCs says which cable is where, whether a termination is in and which gain jumper is out.
- **Levels: volts into 50 ohm, divided by a thru** (AMOD); half a metre of coax is 50 pF and
  moves a 159 kHz corner to 138 kHz into 1 Mohm, so the cable goes in the model.
- **The bench supply is an instrument:** its display can prompt the person ("ON A4"); zero its
  current readback at 0 V before trusting it at mA (E3646A: 0.15 % + 5 mA); and a board
  with bucks draws about constant power, so a staircase checks V x I rising, not the current
  (ECP5 board A: 0.388 A at 4.0 V, 0.369 A at 5.0 V).
- **Switch loads by program:** the scope's 50 ohm input as a load behind a series resistor,
  a generator output switched off as an open input; back to 1 Mohm in a `finally` (op-amp).
- **A bring-up tool touches only the instruments it holds** (AMOD; `bench_claims.py` in
  lab-instrument-control since the op-amp bring-up): nothing assigned at start, no `*IDN?`
  to others, a claim before any output goes on.
- **The first USB plug-in tells a silent device from a broken one:** an attach then
  enumeration errors means a pull-up and bad lines; nothing in `journalctl -k -f` on any
  port means no pull-up (no PHY supply, no clock, held in reset, or a cable with no
  data wires) (ECP5 board
  A, 2026-11-16).
- **A photo cannot show whether a header has a shunt on it** (ECP5 board A's JP501): call a
  jumper "can't tell: check by eye", never ask for one removed on a photo alone; flat marks
  and pin-1 dots can be read, anything standing up cannot.
- **Write rework as "remove the whole part, wire to ONE named pad", never "lift one end"**
  (the user, 2026-11-16: "When I use a hot air gun and tweezers, the whole thing comes
  off."). "Lift FB6241's +1V8 end" lost the bead, the wire bridged both pads and tied +3V3
  to the FT2232H's 1.8 V core (absolute maximum 2.0 V). Name the part to remove, the pad by
  net and neighbour, the pad kept bare under Kapton (red X in the figure), and a meter check
  before power. See `references/bench-case-studies.md`.
- **When a step fails, compare bytes, and distrust the message** (GPiBridge A1, 2026-11-16):
  an hour went on the wrong reboot until the step's and a hand replay's bytes were diffed.
  A wait says which event it waited for and what it saw.

## Firmware and gateware are part of the design

- **First firmware written and building before the board is ordered**; it shakes out pin
  and clock choices (GPSDO r30 #28: the I2C driver could not read until bring-up).
- **Bring the board up on a PC before it has power** (GPiBridge Prompt 12, 2026-11-15, the
  user: "If there is any firmware for this project, write it and simulate it as best you can
  before connecting any hardware. This includes one-off things just for the bringup
  process."). The firmware behind a pty on a model of its chips, the real host software on
  top, each bring-up step run with faults planted, several boards on one simulated cable
  counting bus fights, "nothing was touched" asserted: seven faults found the evening before
  the first plug-in. Details in `references/firmware-gateware-fpga.md`.
- **The first bugs a board finds are in the code no simulator runs** (GPiBridge A1,
  2026-11-16: start-up, watchdog and flash). List that code in the README and give each path
  a day-one bench check: a setting across a reboot from a fresh power-up, three reboots in a
  row, the crash failsafe fired on purpose. Two RP2350/Pico SDK 2.1.1 traps
  (`watchdog_caused_reboot()`, `flash_safe_execute()`) are in the reference.
- **A check that passes because of what ran before it proves nothing** (GPiBridge `bare`):
  put each check where it depends on nothing earlier, or run it first.
- **Write the experiment's gateware before ordering, and read its reset state against the
  board** (CostasLink Response 15): writing `safe()` found the board's idle was not safe
  (see `pcb-schematic`, "rests where an absent host leaves it"). Keep a REVA_CHANGES list
  (found / what / change / state).
- **FPGA tool facts, RTL co-simulation, pin-layer tests on a PC, RP2350 open-drain:** see
  `references/firmware-gateware-fpga.md`. Run the bench procedures and the plan's own calls
  through the real driver into the RTL, live (ECP5, §31), and read a generated constraint
  file against each pin's job (a blanket pull-up is wrong on USB D+/D-).
- **An ECP5 design can build, meet timing, load and still be dead: count the global
  clocks** (ECP5 board A, 2026-11-16: nine DCCA dead, eight or fewer fine). Keep the
  bring-up design's globals low, and an echo bitstream and a minimal UART design beside
  the full one; only loading on the board shows this.
- **Bring-up gateware should need the least of its host** (`pmodbench`: oscillator, serial,
  Pmod pins; no PLL, converter or memory).
- **Check the protocol with somebody else's decoder:** record the simulated bus as a VCD
  and have sigrok-cli decode it (GPiBridge `firmware/test/sigrok_check.py`); an engine
  and simulator by the same author share misunderstandings.
- **A check that skips itself when its tool is missing has never run on that machine**
  (GPiBridge, 2026-11-15: "skipped (no sigrok-cli)" passed; installed, sigrok 0.6 renamed
  the channels and 0 of 12 recordings decoded). Install the tools on the bench PC before
  bench day, make "skipped" loud, write version-independent files.
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
