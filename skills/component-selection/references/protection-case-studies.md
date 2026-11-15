# Protection: case studies (PID motor board, op-amp board; CLAUDE_PCB.md §6 PID lessons, §9, §15)

The PID motor board (Lab 10L, 2026-10-24/26) drives a 14 ohm motorized fader from +-15 V
through a D2PAK/DPAK push-pull. The op-amp board is a discrete-transistor op amp for
students.

## A linear driver into a stalled motor dissipates most at half the rail, below any fuse

- The pass transistor takes (Vcc - V) * V / R, at most Vcc^2/4R at V = Vcc/2: 3.7 W from
  +-15 V into the PID board's 14 ohm motor, at 0.49 A.
- The 0.35 A PTC sized for the full-drive stall (0.63 A) holds, and 0.14 A at 2 V already
  makes 1.8 W.
- A smaller fuse cannot help when the motor needs 0.15 A just to move.
- Size the heatsink for Vcc^2/4R (a DPAK on a small pour is ~70 C/W: 2 W is too much), or
  give the transistor a real heatsink, before trusting a fuse. Sweep the stall over DRIVE in
  the simulation.
- Then check the heatsink as built (`power-current-thermal.md`).

## A PTC opens only above its trip current, and its own resistance is in the circuit

- Between hold and trip the datasheet promises nothing. The PID board's full-drive stall
  (0.61 A) sits between the 0.35 A part's 0.35 and 0.70 A, so "it opens a stall in seconds"
  was false (minutes, or never).
- A smaller part does not cure it: the 0.30 A part's own 3 ohm pulls the stall current back
  below its 0.60 A trip.
- Simulate the fault with the fuse's resistance range in the deck, read the typical
  time-current curve, and if a short can put a rail across the open fuse, take the higher
  voltage grade.

## Put the fuse ahead of everything a student can reach

- A PTC in the motor lead left the DRIVE probe loop, the driver's feedback and DRIVE OUT
  ahead of it, so a scope's ground clip on the DRIVE loop was a short that only the
  transistors limited (2.3 A, 28 W in one).
- Put it straight after the output stage's emitter resistors and take the feedback from
  behind it: the loop then corrects the PTC's 0.2-1.7 ohm, the motor gets exactly what the
  loop asks for, and the only unfused copper is the short run from the emitter resistors to
  the fuse, with no loop and no name.
- The clamps and the snubber can stay at the transistors, ahead of it.
- Ask of every probe loop: what does a ground clip here do? (Review round 1; the user: "move
  the fuse".)
- `check_circuit` asserts the set of parts ahead of the fuse, and that none is a TP or a
  connector.

## Split rails with series reverse-supply diodes want a clamp from each rail to ground

- With one rail connected and the other open, the loads drag the open rail past ground and
  reverse-bias its electrolytic; a Schottky from each rail to ground, reverse-biased in use,
  holds it within 0.4 V. The same part as the series diodes costs no order code.
- **Simulate the missing rail before adding them.** The op-amp board (ceramic bypass only)
  with one rail open, a follower, IN+ over +-12 V: the open rail floated from -1.7 to +8.7 V
  (or -12.7 to 0), each rail LED saw at most 5.2 V reversed through its 10 k, the other
  supply gave at most 14 mA. With nothing polarised there was nothing for a clamp to save.
- The one stress was an input driven far below a missing -15 V: 6.9 V of B-E reverse bias on
  the input pair, past the 2N3904's 6 V, which a rail clamp does not prevent (the input is
  outside the rail, not the rail outside ground). The fix there is a line in the handbook:
  turn both rails on together.

## A series diode's resistance at a few milliamps couples load current

Into anything referenced to that rail. On the PID board the motor's current through the
-15 V diode (several ohms at 4 mA) moves the fader track's midpoint, which asks for more
drive: with TARGET from a ground-referenced jack the loop rests at a volt of DRIVE, stuck in
the friction. A source referenced to the same rails (the knob) cancels it exactly.

## A class-B output stage needs diodes in its current limiter (op-amp board)

Found in simulation before the board was drawn.
- The 741's limiter (a sense resistor in each emitter and a transistor across it that steals
  the drive) assumes a class-AB stage whose two bases sit a volt apart.
- With the book's bare class-B pair the bases are tied, so while one half conducts the idle
  sense transistor's base sits a Vbe above its collector: the junction conducts, dumps
  current into the drive node that the 12 k pull-down cannot sink, and the negative swing
  collapsed from -14 V to -9 V.
- A 1N4148 in series with each sense transistor's collector (anode toward the drive node)
  blocks it and costs nothing at the limit, which sits 1.25 V away from OUT.
- Simulate the limiter shorted and swinging, not just at rest; and when a protection circuit
  is added to a textbook circuit, give it its own box on the board and say in it that it is a
  safety feature.

## A lesson about budgets

Adding six parts to a finished 100 x 100 mm layout cost a whole re-plan of the right-hand
third (feed, return, switch, divider, loops) and raised the hop count from three to nine.
Decide the protection before the floorplan.
