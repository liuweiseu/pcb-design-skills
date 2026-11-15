# Bring-up plans and bench case studies (CLAUDE_PCB.md §9, §27)

## A bring-up plan is a table from the DOA list to the stage that retires each risk

(CostasLink `BRINGUP.md`, 2026-10-09.)
- Stages in order, each with its connections, measurement, pass condition and what to do if
  it fails; a last table that says which stage answers which DOA item and what the fallback
  is.
- An accessory from AliExpress has a spec table on its page or none at all (the 5.8 GHz
  "SAW + LNA" module had none): write the assumed numbers into the budget as assumptions,
  and make measuring them a step of the plan.
- An external PA with 40 dB of gain wants a pad on its input: the board's +10 dBm would
  drive it 17 dB into compression.

### Measure them on a VNA before the board arrives, if one is within reach

(CostasLink Prompt 42, 2026-10-24, boards in transit.)
- The "SAW + LNA" module assumed at 15 dB measured 29; the "40 dB" PA 46; the 10 m cables
  10 dB each at 5.8 GHz where the budget had 5 dB of LMR-200; two of four grid antennas had
  their feeds turned against their bars. Each changed a step of the plan (the PA's pad, the
  frequency plan, where the amplifiers sit).
- Two antennas measured as a pair give the board a link whose loss and delay are known to a
  dB and 0.1 ns before it is powered: calibrate the receiver's level scale against that, not
  a generator.
- Measure the fixture (the pad chain with no device) before every de-embedded campaign.
- Check a recalled calibration on a thru after a power cycle (S21 against S12).
- Let the plan quote the `.s2p` files by name: the pads' values are files too.

## Bring-up order and instructions

- Order in a `HANDBOOK.md`: current-limited bench supply first, then each rail, then the
  programmer, then the first firmware, then the interfaces (ECP5 §4, GPSDO P39).
- Write the bring-up step by step with the expected reading at each; this catches
  instructions that produce the wrong state (GPSDO rev B: "fit every shunt before first
  power-up" did not quiet the self-biased gates; see `component-selection`, "Budget a rail
  in the board's worst state").

## Say exactly what to buy and what plugs where (GPiBridge `BRINGUP.md`)

Name the probe and its cables, give each stage's connections and what the agent does then,
and start with a partner both ends of which are scriptable: a Prologix in device mode for a
GPIB board. The user asked "what do I buy, and how do I connect it" before anything was
built.

## Bench instruments are scriptable

`lab-instrument-control` (Siglent scopes and generators, an HP 33120A over GPIB, an
ADALM2000) lets the agent take its own measurements once a board is cabled. Design tests
that use them.

## Before calling a dip the chain's response, check that it follows a knob in the path

(CostasLink rev A, 2026-10-29.)
- **What happened:** a 10 MHz-step map showed a "notch" at 5.89 GHz with a "recovery" above
  it. It was the chain cancelling against a transmitter leak that bypassed the step
  attenuator. Above 5.86 GHz, RX MON and the demodulator's I/Q did not move between 0 and
  31.75 dB of attenuation, and the null moved with the setting.
- **The rule:** sweep every frequency at several settings of an attenuator, a switch or an
  enable that sits in the path. Believe only the part that follows it.
- **Measure the leak floor first:** transmitter on, the receiver's input terminated, no
  cable between them.
- **Then trace the rest:** model the input network as laid out (`rf-design`) before
  suspecting the chips.

## Loop sign on the bench (§27)

Inverting one arm of a quadrature receiver flips the loop's sign (the design rule is in
`rf-design`). A wrong sign in a loop with a sign() detector does not run away, as CostasLink's
bring-up text expected: it holds at the detector's jumps (+-90 degrees) with the comparator
chattering, which looks like a lock. Check before closing the loop: with the loop held and
the carrier on a known side of the LO, the arms' phase order (Q ahead of or behind I) gives
the sign.

## Try a new bench source as an aggressor before trusting it as a channel

A USB-powered CircuitGear's DDS 10 MHz on one GPSDO input made every other channel's beat
chatter (common mode: the pair differences stayed clean). It brings its ground and its spurs
with it (GPSDO r45).

## Read the DNP flag before saying what is fitted

- A part drawn on the schematic is not a part on the board.
- GPSDO's pps jacks draw a 51 ohm terminator, marked DNP. Round 44 called the inputs
  terminated and dropped a test that works.
- `excluded_from_assembly.csv` answers the question in one grep (GPSDO r45).

## Symmetric connectors

A 2 x 12 grid solders in turned round as easily as right. Give a meter check after two pins
are tacked (one contact must read 0 ohms to GND).

## Product names

Check a product name against trademark rules, not just search results. Raspberry Pi's rules
forbid "Raspberry" as a brand for hardware; "RaspberryGPiB" was proposed and had to be
declined.

## A book circuit as a lab instrument (op-amp board, 2026-10-24)

The user: "I want to show students that opamps aren't magic (just made of transistors) ...
Could this be used for the first few circuits in lab 6 and 7 and maybe even 8?"
- Read the actual lab circuits out of the book's PDF (`pdftotext -layout`, then the section
  headings) and judge each one against the amplifier's real numbers.
- A 0.7 mA BJT pair has ~2 uA of input bias current, so the photodiode converter's 10 Mohm
  and the integrator's 10 Mohm leak are out; the 100 kohm phototransistor version and a 1 uF
  integrator are in; and the output has no current limit where the LF411 has 25 mA.
- The user, on being told: "Being a 'bad' integrator isn't the end of the world ... As long
  as it doesn't run away in a tiny fraction of a second (and can't be fixed with a bigger
  capacitor), I'm perfectly happy with a 'not very good op-amp' that is made of real
  discrete transistors that the students can see and poke at."
- Non-idealities are the lesson; a dead output transistor is not. Put the verdicts in the
  handbook and the bias current and the missing current limit on the back of the board.
