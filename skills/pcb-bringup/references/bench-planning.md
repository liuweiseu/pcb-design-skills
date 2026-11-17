# Planning the bench time: visits, the status file, the test table, the simulated bench (CLAUDE_PCB.md §9, §30-32)

Written from planning four bring-ups on 2026-11-15, before any of those boards was powered:
AMOD and RF-MOD (nine boards, 104 tiles, about 200 jacks; plan `AMOD-and-RFMOD/BRINGUP.md`, tool
`bringup/`), ECP5-2ADC-2DAC (two assembled boards; plan `ECP5-2ADC-2DAC/BRINGUP.md`, tool
`bringup/bench.py`, rev B rows `bringup/REVB.md`), the op-amp board (assembled rev A boards, one
already working by hand; plan `op-amp-pcb/BRINGUP.md`, tool `bringup/`, rows `bringup/REVB.md`) and
GPiBridge (`BRINGUP.md`, `bringup/run.py`, `bringup/STATUS.md`, `bringup/REVB.md`).

The constraint behind all of it is the user's minutes at the bench. The user (2026-11-15): "it'll
be easy for me to get confused when I pop in and change some physical configuration, so you'll
need to always remind me of where we're at so that I can sit down and *correctly* do what needs
doing"; and of the ECP5 board, "The limiting factor will be my time in the lab".

## Cut a bring-up into visits (AMOD/RF-MOD, §30)

- **A visit** is one set of cables, what to set on the board, and what the agent then measures
  alone. The user cables it, types "`A.v2` cabled" and leaves; the agent runs it, judges it, logs it
  and posts the next card.
- **Name every cable once, for the whole bring-up** (G1, G2 for the generator's channels, S1-S4 for
  the scope's, P1, P2, SA), on tape at both ends. A card then says "G2 moves from p2 IN to p4 IN;
  the rest stay".
- **Sort the tests by who must be there:** cable-only visits (unattended), "hands" sittings (a DIP
  way or a jumper changes between measurements), analyzer sittings (a cable move every half
  minute), and what needs a part from outside the board. Do the unattended ones first.
- **A picture with every card**, drawn from the board's own geometry: the tiles as printed, a
  coloured dot with the cable's name on each jack of the visit, the USB-C and the plug where they
  are, so the board can be turned the right way round at a glance.

## Say where the bring-up stands in a file the tool rewrites (GPiBridge, AMOD/RF-MOD, 2026-11-15)

- **One page, rewritten by the tool after every step** (GPiBridge `bringup/STATUS.md`; AMOD's
  `bringup/STATUS.md`): a table of boards against stages, the board on the bench, what is cabled,
  what passed, and the next physical thing to do, in the silkscreen's words. The user, or a new
  session, reads only that.
- **Begin every bench message with it.**
- **Name each board at first plug-in** (A1, L1), tied to its serial number, written on it with a
  marker, and give the firmware an "identify" command that flashes its LEDs.

## Park the board between steps (GPiBridge)

Each step ends with the board in a state in which any cable may be changed: off the bus, outputs
off, told to stay so at the next power-up. Then a visit to the bench never needs a "wait, let me
turn that off first", and one LED says so (GPiBridge: green off means off the bus).

## A hand on a probe gets a beep, not a prompt

- **GPiBridge `run.py rails`,** for a rev A whose test points are still pads: the step polls the
  scope, knows which rail the tip is on by its voltage (and tells a switched rail from its source
  by switching it for a moment), records it and makes the scope beep. The person looks at the
  board, not at a screen, and touches the points in any order.
- **The person at the bench does not see the script's prompts; the agent does** (ECP5, §31). A
  measurement that keeps the hands busy must need no typing and no reading: the multimeter walk
  along the rails header takes each steady reading as the next rail, in order. The instructions go
  in the chat before, the result after.
- **A rule that ends a probe walk early must not fire on the first odd reading** (ECP5 board A,
  2026-11-16). "A negative reading is -4V2, the last pin, so the walk is over" ended a walk after
  9 s on a wrongly placed probe. End only after most of the walk has been read, or after the probe
  has been lifted for a while.

## One table of tests, read by everything (§30; the one-source-of-truth rule at the bench)

Each test names its jacks, its stimulus, its model and its limits; the cards, the measuring tool,
the pictures and the rehearsal are all made from it. A jack that does not exist, or a visit that
needs more channels than the bench has, fails a test on the PC instead of confusing a person at
the bench (three cross-tile jack names were wrong in AMOD's first draft).

## Rehearse the whole bring-up on a simulated bench before a board is touched (§30)

- Each tile is its own model; the simulated scope has eight bits, clips and has noise, so the
  autoranging and the fits are exercised too. A good board must pass everything, and boards broken
  on purpose (a dead tile, half the gain, a shifted resonance, two cables swapped, a silent host)
  must fail the right tests.
- **What it found on AMOD/RF-MOD:**
  - an edge detector that counted a noisy edge several times (use hysteresis);
  - a delay estimate that failed on a ringing step (correlate the waveforms instead of timing one
    crossing);
  - a planted fault that could not show (swapping two channels that carry the same signal).
- **It cannot show that the models are right.** Say so in the plan.
- The firmware side of the same rehearsal (a pty, planted faults, bus fights) is in
  `firmware-gateware-fpga.md`.

## Working each block's expected numbers out of its netlist is a design review: do it before the order (§30)

- **What it found, three weeks after the boards were ordered:** the 555 tile's terminated CV
  jack drags its thresholds down, so the tile will not run at the frequency its silkscreen prints.
  The node analysis for every DC-coupled input: see the pcb-schematic skill,
  references/netlist-checks.md, "A terminated control input is a load on what it controls".
- **So the bench's test table is an order gate**, as the first firmware is (SKILL.md, "Firmware
  and gateware are part of the design"). For each block: what goes in, what comes out, from which
  parts, within what limits.
- **Print each input's resistance beside its jack.** A generator set "into 50 ohm" puts twice its
  setting on a jack that is not terminated.

## Count the visits at design time, and design them away (§30)

With two generator channels and four scope channels a twelve-tile board is four to six unattended
visits; every switch a test must flip is a sitting; every output that ends on a terminal needs a
part before it can be judged. What AMOD/RF-MOD would have saved (their `REVB.md`, section 2):

- a bench power header, and a way to read one tile's current (here: a hand-made USB-C lead, and a
  "walk" of the slide switches with a person present);
- rail access on every powered board (three of the seven have none);
- one line that turns every tile on, beside the students' slide switches;
- a divided monitor jack on every driven output (bridges, the class-D amplifier, the phases);
- a looped pair of host lines and a row of pads by the plug.

## A board with converters tests itself through a few cables, and in the next revision through none (ECP5, §31)

- **Three short SMA cables** (DAC 1 OUT to ADC A IN, DAC 2 OUT to ADC B IN, CLK OUT to CLK IN)
  turned everything except absolute calibration into a visit that needs a supply and two USB
  cables: transfer line, noise, spurs, capture timing, cross-talk, every clock through the output
  buffer and the input comparator.
- **Design for it:** an output's full scale equal to an input's (here +-1 V into 50 ohm both
  ways), the jacks side by side on one edge, a frequency counter in the FPGA on every clock input,
  a multiplexer that puts any clock on the clock output, a PHY whose loopback returns the MAC's
  frames.
- **What a loop cannot say:** which half an error belongs to, and the volts. Keep one visit with a
  generator and a scope for that, and plan it after the loop has run.
- **In the next revision the loops are switches on the board** (off at power-up), so the
  self-test runs in the enclosure with nothing plugged in.

## The board measures its own analog chain (ECP5 board A, 2026-11-16 night, the tutorial's `ets.sv`)

- Every sample clock is an FPGA output, so the PLL's dynamic phase shift (0.25 ns steps at a
  500 MHz VCO) moves the ADCs' sampling instant against a repeating DAC waveform: DAC -> cable ->
  ADC at an effective 4 GS/s, both channels at once (0.02 ns apart), with no scope. That is how
  the slewing front-end stage was found (the rule about the stage itself is in the analog-signals
  skill).
- The same night a lock box through the cable measured the loop's delay (14.2 samples) from its
  oscillation and matched 1/|1+L| within 0.1 dB.
- **The rule:** keep sample clocks on FPGA outputs that a PLL can drive, and plan bring-up tests
  that use the board on itself before the bench instruments.

## Find out what is plugged in; do not assume it (ECP5, §31)

The tool steps each DAC a few millivolts and reads both ADCs: the answer says which cable is
where, whether the termination shunt is in (the step doubles without it) and which gain jumper is
out (ten or a hundred times). Crossed cables are accepted and remembered. A wrong cable becomes a
row in a table, not a failed test an hour later.

## A board that its USB cable also powers cannot be power-cycled from the PC (ECP5, §31)

Here the bench input and USB are joined by a P-FET: switch the supply off and USB takes over
without a blink, and the PC's hub keeps its 5 V on. So the cold-boot test and the power-on scope
shot need the cables pulled by hand.
- **Design:** a load switch after the two inputs join, on a spare pin of the USB bridge, held on
  by a pull-up.
- **Until then:** with USB out the supply's current is the witness: a board that configured
  itself from its flash draws more than a blank one.

## Every connector gets a test before the order, not a line saying "later gateware" (ECP5, §31)

The ECP5 board's first plan left HDMI, the second USB port, the microSD socket and the Ethernet
data lines untested. Writing those tests took an evening and found two things the order could have
used: the generated constraints pull the USB lines up inside the FPGA, and no one had checked which
pins take a DDR register (the one bank that does not was found by the first gateware, after the
order).
- **Small tests are enough:**
  - a card answers in SPI mode over four of its lines;
  - a USB port is proven electrically by asserting the pull-up and watching the host's reset and
    packets on both lines, with no USB core;
  - a monitor's EDID reads over two bit-banged pins;
  - frames written by the PC go out and come back through the PHY's loopback with their CRC
    checked in hardware.

## A test runs where its part is in specification, and the plan names the supply it runs from (AMOD, 2026-11-16)

A pin audit found three motor and coil drivers below their minimum supply on USB alone (a
Schottky's drop from 5 V). The bring-up's tests of those tiles had been written for USB alone too,
so a pass or a fail would have said nothing. Write each test's supply into the test (here a second
supply output on the barrel jack, set by the tool only for that test and returned to 0 V), and read
the rails again with every tile on, where a shared inverter is loaded hardest.

## A bring-up plan's visits depend on other boards' bring-ups: let them wait, not block (2026-11-16)

The host board's own USB port turned out dead the day the plan was finished. The tool marks a
visit as waiting while its configuration leaves one of its instruments unassigned, says what waits
for what, and always offers the next visit that can run.

## Put the bench on the model before quoting a number in a handbook (op-amp, §32)

- **The simulated bench's board is the SPICE deck that designed the board, plus what a student
  hangs on it:** a metre of coax (100 pF) and a scope's 1 Mohm and 15 pF on the output, 50 ohm
  behind the generator, a meter's 10 Mohm, a x10 probe's 12 pF.
- **Run against that, three sentences of the handbook turned out to be true of the bare board
  only:**
  - "clean edges, no ringing" is 9 % of overshoot through the cable the same sentence tells the
    student to use;
  - "2.2 nF leaves it clean" is 30 % and two and a half cycles;
  - "the gain is 10.1" is 9.7 to 10.6 with amplitude.
- **The check behind a sentence must measure what the sentence says.** The design's cable check
  measured the ripple left 30 us after the edge (none: it does not oscillate) and the handbook
  wrote "clean". Overshoot and cycles of ringing are the words a student would use, so they are
  what to compute.
- **Half a metre of coax is 50 pF** (AMOD, §30). With the scope's own input it moves every corner
  measured into 1 Mohm: a 1 k, 1 nF low-pass printed "159 kHz" reads 138 kHz. Put the cable in the
  model, and its capacitance in the bench's configuration.

## Enumerate every switch setting in the model; it takes a tenth of a second (op-amp, §32)

Three two-way DIP switches are 64 settings. The operating point of each found the one that breaks
the handbook's "a rail over 10 mA is a fault" (no tail with both feedback sliders on: 14.5 mA,
nothing wrong), and gave the power-up ramp its current allowance at each voltage for any setting
the board may arrive in.

## Look for instability at more than one DC level (op-amp, §32)

A stability test at rest sees half of a class-B stage's instability; test with the output well
away from zero too. The rule and the model's numbers: see the analog-signals skill, "Amplifiers".

## A switch the student flips is a visit (op-amp, §32)

- **Order the visits so each changes one slider, and end where you began.** Five switch changes
  walk through the four compensation settings worth seeing and return to the usual one. Say which
  slider goes first where the order matters (FEEDBACK 2 off before 1 on).
- **Give every switch setting a signature at the jacks, or know which have none.**
  - FEEDBACK always shows (the DC gain is 1, 11 or rail to rail).
  - TAIL shows only as a follower, in how the negative supply current follows the input (2.3 mA
    over 16 V with the 10 k, 0.8 mA with the sink).
  - COMPENSATION 1 and 2 look alike at a gain of 11.
  - The tool checks what shows and carries the rest in its record; a wrong record then stops a
    step instead of filing a measurement under the wrong setting.

## Loads and source resistances a program can switch, with nobody there (op-amp, §32)

- **The scope's 50 ohm input is a load**, where a series resistor bounds what the board can put
  into it (here 330 ohm inside the loop: 2 V at most; the input is rated 5 V rms). The output's
  current limit was measured this way in the rehearsal. Read the voltage before switching it in,
  raise the drive in steps, and stop at the level where a limiting board has flattened and a
  faulty one still follows. Back to 1 Mohm in a `finally`.
- **A generator output switched off leaves an input on the scope's input resistance alone**, if
  "off" is an open circuit: at 50 ohm the amplifier's output is its true offset (no generator zero
  error, which is 2 to 3 mV), at 1 Mohm it moves by the bias current times a megohm (2 V for a BJT
  pair). Whether a given generator opens its output is the first thing the step finds out; the
  plan has a second way (the drop across the series resistor, by meter) if it does not.

## Levels at the bench: quote volts into 50 ohm, and divide by a thru (AMOD, §30)

The tool sets the generator's load to 50 ohm so its display agrees with the plan, sweeps the
generator straight into the scope once, and divides every later sweep by that.

## The bench supply

- **Its display can prompt the person** (AMOD, §30). In the power stage the E3646A shows "ON A4",
  the user slides that tile's switch, the tool sees the step in current and shows the next name.
  Each tile's current, from a supply alone.
- **Its current readback is not a measurement at 4 mA until it is zeroed** (op-amp, §32). The
  E3646A's is good to 0.15 % + 5 mA (10 mA on output 2). Take the reading at 0 V with the output
  on and subtract it. Then the supply current is a signature: of the board (the ramp stops at 1 V
  when the leads are on something else), of a switch setting, of a load.
- **A board with switching regulators draws less current as its input rises** (ECP5 board A,
  2026-11-16): a staircase check must test the power (V x I) for "rising with the voltage", not
  the current. Why, with board A's numbers: see the component-selection skill,
  references/power-current-thermal.md, "Switching regulators draw about constant power".

## Budget the bench input from the supply's terminals to the rail, at full load (ECP5 board A, 2026-11-16)

- **At the bench:** tell the person to use short, thick leads straight to the input.
- What happened (J601's drop) and the design rule: see the component-selection skill,
  references/power-current-thermal.md, "Budget the bench input from the supply's terminals to the
  rail, at full load".

## Instruments on a shared bench

- **A bring-up tool touches only the instruments it was given** (AMOD, §30). The bench PC's other
  instruments were in use for other work while this was written. The tool's configuration starts
  with nothing assigned, opens an instrument only when a test first needs it, and asks even
  `*IDN?` only of those it names.
- **A shared bench needs a record of who holds what** (op-amp, §32). lab-instrument-control has
  `bench_claims.py` since this bring-up: a project claims an instrument channel when the person
  has said it is cabled to its board (with what it goes to and the most that will be put on it),
  and calls `require()` before any command that switches an output on. The tool refuses to open an
  instrument it does not hold. A claim is what the person said, so the ramp's signature check
  still runs.

## Tooling for a simulated bench (op-amp, §32)

- **Run rehearsals under `timeout -s KILL`;** a Python timeout cannot stop ngspice running
  through ctypes. Why: see the kicad-scripting skill, references/ngspice.md, "ngspice traps".
- **A slow scope sweep of a circuit that rings at megahertz costs a transient simulation millions
  of steps.** The simulated scope simulates 100 us finely and samples that repeatedly; the real
  scope aliases it anyway.
- **A flat scope trace must not be zoomed into its own noise by an autoranging loop,** and a DC
  level can be cancelled by the scope's offset only as far as that volts/div allows (SDS2104X
  Plus: +-2 V up to 100 mV/div, +-20 V up to 1 V/div). Read DC levels in two looks, coarse then
  offset, and stop zooming at a floor.
