# ngspice through the netlist (PID motor board, 2026-10-24/26)

For simulating RF chains as laid out (ABCD models, the circuit the copper makes), see
`rf-design`. This file is circuit simulation driven from KiCad's exported netlist.

## The pipeline

- **Simulate the exported netlist, not a hand-typed deck.** `sim/pid_sim.py` parses
  `out/<stem>.net`, emits an R/C/D/Q/X line per component with behavioural models, adds
  the plant, and sweeps the switches and trimmers by name; a wiring mistake on the sheet
  then shows up as a wrong step response rather than staying hidden in a deck that says
  what was meant.
- **Make the netlist-to-SPICE step refuse a value it has no model for.** The sim stage ran
  before the schematic stage on the previous netlist; after the transistors were renamed,
  the old value fell through to the SOT-23 branch and every result was garbage with no
  error. An unknown value stops the build with "rebuild the schematic first".
- **A stage that reads another stage's output must make it if it is missing**: the sim ran
  before the schematic and read `out/*.net`, which is not committed, so a fresh clone fell
  back to the committed results with a misleading message.

## ngspice traps

- **`limit(x, lo, hi)` in ngspice is a random (Monte-Carlo) function**, not a clamp: an
  op-amp model written with it returned zero. Use `min(max(x, lo), hi)`.
- **"+15V" and "-15V" sanitise to the same node name** unless the sign is spelled
  ("P15V", "M15V"); the op point failed silently until it was.
- **An integrator starts railed** unless the deck says `.ic V(<its output>)=0`; the
  scenario that switches I in needs it.
- Friction decks run with `gear` integration and 20-50 us steps.

## Models

- **Model an LM358-class output 2 V from each rail.** TI: V+ - 2 V typical, V+ - 3 V
  guaranteed, and it sinks milliamps only about 2 V above V-; a model clamped at V+ - 1.5
  and V- + 0.1 overstated the drive by more than a volt.
- **A behavioural op-amp model does not show bias current**: a bipolar op-amp's bias
  current through a big resistance (LM321: 45 nA x 1 MOhm = 45 mV of residual) must be a
  separate check (see `component-selection` for the integrator capacitor choice).
- **Friction that lets the slider creep is wrong.** Coulomb friction as `F tanh(v / v0)`
  with v0 a fair fraction of the working speed lets anything below break-loose creep, and
  a P-only loop then walks its residual away. Make v0 tiny (10 um/s) and add a Stribeck
  rise, `(Fc + (Fs - Fc) exp(-(v / vs)^2)) tanh(v / v0)`: the deck then sticks, slips and
  hunts on a slow triangle as the bench fader does, and ngspice (gear, 20-50 us steps)
  still runs it. `vs` is a fit to what the bench shows, so say so.
- **Put a fuse's resistance range in the deck** when simulating a fault (a PTC's own
  0.2-1.7 Ohm, or 3 Ohm for a smaller part, is in the circuit); then read the typical
  time-current curve (see `component-selection` for PTC hold/trip behaviour).
- **Simulate the missing rail before adding clamps** (op-amp board, ceramic bypass only):
  with one rail open, a follower, IN+ over +/-12 V, the open rail floated from -1.7 to
  +8.7 V (or -12.7 to 0), each rail LED saw at most 5.2 V reversed through its 10 k, the
  other supply gave at most 14 mA; the one stress was 6.9 V of B-E reverse bias on the
  input pair (past the 2N3904's 6 V) for an input driven far below a missing -15 V. The
  design consequences are in `component-selection`.

## Reading the results

- **Take a transistor's dissipation from its own pins.** The stall sweep computed Q1's
  power as I x (V(+15 V) - V(DRIVE)) with DRIVE at the emitter resistors' junction, which
  quietly counted the 1 Ohm resistor's I^2 R as transistor heat (3.7 W, of which 0.25 W was
  the resistor); when the fuse moved, DRIVE became a node past the PTC too. Use
  V(collector) - V(emitter) from the netlist's own pins (`Deck.pin("Q1", 2)`), and say what
  a rounded-up figure covers when a check keeps it.
- **Report a step's peak, its swing back and where it comes to rest separately.** With
  sticking friction a step can stop past the target without ever overshooting; one
  "overshoot" number (peak past target) called the dead band an overshoot and "settles in
  1500 ms" meant "never enters the band round the target".
- **Measure the natural frequency from the ringing, not from all the crossings.** With
  friction, a step at high gain rings a few cycles (31 Hz) and then hunts slowly (5 Hz);
  the mean of every zero crossing in the first second gave 5 Hz and a D rule off the end
  of the trimmer. Count crossings in the first 150 ms after the first half-cycle. Settle to
  5 %, not 2 %: sticking friction leaves a few per cent of dead band.

## Other lessons filed in the same subsection

- **Hash every UUID the generator writes** and **let an explicit tool path win**: see
  SKILL.md.
- **Parts rotations and datums need the same table**: JLCPCB's origin for a DPAK is 1.9 mm
  toward the tab from KiCad's, the RK09K's is the body centre, and their D2PAK is drawn
  turned 180 degrees from KiCad's TO-263-2 (pins at +x) with its leads 2.45 mm further out.
  `JLC_ROTATION` entries are `(deg, (dx, dy), how, note)`; the upload CPL moves each part
  by its shift rotated into board coordinates, and `check_outputs.py` proves the two CPLs
  differ by exactly the table. (Owned by `jlcpcb-order`.)
- **The AppImage does not ship every 3D model its footprints name**: see `pcbnew-api.md`.
