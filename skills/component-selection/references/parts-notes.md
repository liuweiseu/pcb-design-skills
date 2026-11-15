# Part-specific notes and part hunting (CLAUDE_PCB.md §6 PID lessons, §17, §19, §20, §22, §26, §29)

## Op amps and models

- **Model an LM358-class output 2 V from each rail.** TI: V+ - 2 V typical, V+ - 3 V
  guaranteed, and it sinks milliamps only about 2 V above V-; a model clamped at V+ - 1.5
  and V- + 0.1 overstated the drive by more than a volt.
- A bipolar op amp's bias current through a big resistance does not show in a behavioural
  model: put it in a check (LM321: 45 nA x 1 Mohm = 45 mV of residual).

## An integrator's capacitor is a filter part: film or C0G, never X5R (PID board)

A 10 uF X5R loses much of its value at the few volts the integrator holds, so I's time
constant moves with its own output (see SKILL.md, class 2 ceramics). Polypropylene at 10 uF
is a brick (27.5 mm leads), so go to 1 uF and let the 1 M trimmer carry RC to 1 s; that also
spreads the useful I range over the whole turn instead of its first tenth. The price is the
bias current through the bigger resistance (LM321, above). Panasonic's ECW-F (450 V, "active
filter circuit" in its own datasheet) is stocked at JLCPCB (C242107, 18.1 x 9.3 mm, leads on
15 mm); JLCPCB's land pattern (`easyeda.py`) confirmed the footprint's origin.

## Motors and off-board parts

- **A motor's ohmmeter reading is high.** 18 ohm on a meter, 14 ohm from the stall current at
  5 V: the brushes' film at a few mA. Use the stall current at a few volts for R.
- **Decode the off-board part's order code before trusting "a 10k linear track".** The lab's
  fader turned out to be a Bourns PSM01-082A-103B2, not the SparkFun part the design assumed:
  its "B2" taper is linear only from 10 % to 90 % of the travel (flat 10 mm at each end), and
  the linear one is the second, "servo" track. The same datasheet gave the motor polarity (A
  positive moves the lever toward terminal 1), so the handbook can say "1, 2, 3 to POT 1, 2,
  3" instead of "swap the wires if it runs away". Ask for the exact part number of anything
  the board plugs into.
- **A slide switch's travel can be read from the datasheet's section.** The MSK12C02 drawing
  shows the handle carrying the moving contact onto the terminal on its own side, with the
  common in the middle: the slider toward pin 1 closes pin 1. Still an ohmmeter check on the
  first board.

## Reading datasheets

**Read a chart's curves from the PDF's vector paths**, not by eye: `pdftocairo -svg -f N -l N`
and parse the `<path d=...>` points with their `transform`; the grid lines give the axes.
Eyeballing a rendered chart put the same curve's ends 5 % apart on two tries.

## Packages and finding parts

- **Choose the small package first, and look for it under every name** (§19). A SOIC-16
  (10.5 mm courtyard) and a SOIC-8 op amp did not fit beside both jacks of a 20 mm tile; the
  TSSOP-16 and the SOT-23-6 did. TI's TSSOP 4046 had 21 in stock, but Nexperia's automotive
  grade (74HC4046APW-Q100J) had 234: search the "-Q100" and other vendors' parts before giving
  up on a package. Read the small package's pinout from the datasheet; the SOT-23-6 OPA847
  moves the pins.
- **A dual op amp in SOIC-8 rarely fits a small cell's quarter; two SOT-23-5 singles usually
  do** (§20). The dual's eight pins on two sides force its four signal nets to cross; two
  singles can each face their own jack.
- **Search JLCPCB by category before giving up on a part family** (§22). Part numbers found
  Mini-Circuits mixers with 2-15 in stock; the category "RF Mixers" found the ADEX-10L+ with
  861. (Stock and free-to-order counts: `jlcpcb-order`.)
- **JLCPCB's 0402 basics** (10 k C25744, 1 k C11702, 470 C25117, 1.5 k C25867, 100 n C1525,
  1 n C1523) and the 0603 10 ohm (C22859) and 1 uF (C15849) are the values that let a SOIC's
  pins have their resistors at the pin pitch; 51 ohm (C25125) and 3.9 k (C51721) are extended
  (§17).

## Spend board area only where the board must

- **Before spending cells on a splitter, look for the output the chip already has** (§22). Two
  RF-MOD tiles were resistive splitters (two cells each, 6 dB lost) while each MAX2871's
  complementary output, RFOUTA-, sat terminated in 51 ohm. Brought to its own jack it is a
  second LO at full power, 180 degrees from the first. A part the student can buy as a cable
  accessory (the user: "I have passive splitters") does not earn board area.
- **A hand-soldered part must fit before it is offered** (§22). A hand-soldered AM tuning
  capacitor was allowed; a polyvaricon with its dial is about 20 mm square, a whole cell beside
  a jack. The answer was a 2-way screw terminal beside the coil's, in parallel with the
  switched capacitors, for an external capacitor with a big knob.

## Ratings and drive

- **A DIP switch is for milliamps** (§20). Its contacts are rated tens of milliamps: switch a
  reference resistor or a coupling capacitor, never a current shunt. Laid out at rot 90 its two
  rows become two columns: one side for the common node, the other for the switched parts.
- **A push-pull output cannot share a bus** (§26). The MT6701's DO drives whether or not its
  chip is selected; a 74LVC1G125 enabled by its chip select lets it share MISO with an IMU.
  Read "high impedance when deselected" in the datasheet before sharing any SPI output.
- **A termination is a load a signal generator can burn** (§29): see SKILL.md; Vishay
  CRCW0402...HP (200 mW, 0402), Yageo SR0603 (250 mW, 0603). This is the op-amp reviewers'
  "size the resistors a misplaced scope clip loads", applied to every jack.
- **A divider to the negative rail is a level shift** (§26, AMOD-C/M/B, 2026-10-28). A current
  amplifier's output centred on 1.65 V reaches 0 V through R1 from the output and R2 to -5 V with
  R2 x 1.65 = R1 x 5 (3.3 k and 10 k): gain 0.75, a 2.5 k source, read at an ADC's or a scope's
  high impedance. It fitted where a difference amplifier did not.
