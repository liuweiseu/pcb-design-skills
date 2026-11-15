# Test points, monitor taps and bring-up pictures: details and stories (CLAUDE_PCB.md §9)

## Plug in; don't solder or hold

The user does not want to solder wires or hold probes to debug. Provide labelled test
points with ground clips nearby, U.FL monitor taps for signals worth scoping, and headers
that take standard probes (ECP5 R17, GPSDO P2). The user has many USB scopes and wants to
plug one in and walk away. So: **lots** of taps, on every analog node worth a look (GPSDO
r45, REVB #19). Since 2026-11-07, every test point is a jack.

## Every test point is an MMCX jack

U.FL only where there really is no room for MMCX (the user, 2026-11-07, after the
OWLternating Current rev A bench: "I hate soldering little wires and clipping a ground clip
to one little wire and a probe clip to the other little wires. This is annoying, time
consuming, and they keep falling off when unattended.").

- Rev A had six rail test points as pads: one had a wire soldered on, the hooks slid off
  twice, one landed on the wrong pad, and two ramps aborted on readings that were the hook,
  not the rail (`bringup/REVB.md` 1.1 there).
- A jack carries its own ground, so a probe adapter or a coax to the scope plugs in and
  stays. Label each with the net name in silk.
- **In the production run leave the jacks unpopulated**; the bare footprint is then an
  ordinary test pad.
- This supersedes the 2026-10-10 rule ("If they are there for brief, one off probing, they
  can stay as pads. If I would have to hold something for more than a few seconds, make
  them U.FL."): the hold-time test now only decides MMCX against U.FL where space is tight,
  never jack against pad.
- Anything a computer-controlled instrument will log is a jack even when a meter would do
  (CostasLink Prompt 35: the lock detects, the switch control, the log amp and the seven
  rails went from pads to U.FL / MMCX, the rails' pads kept "at least in addition"). A jack
  drawn late on its sheet gets explicit references, so no hand anchor moves.
- U.FL is rated for 30 matings, MMCX for about 500.

## A monitor tap's series resistor is its divider and its load (GPSDO r45)

- 450 ohm is a 10x probe into a 50 ohm scope, and loads the node with 500 ohm.
- 1 kohm is /21, and loads it with 1 kohm.
- A series capacitor keeps a biased node's DC (and keeps a 50 ohm scope from pulling
  current out of a rail).
- **Never tap a node whose amplitude sets a timing**, such as a comparator's or squarer's
  input behind a series resistor. Plugging the scope in would move the thing measured. Tap
  the low-impedance side.
- **Follow a tap's DC path into the scope.** A 50 ohm input, and the ADALM2000's 1 Mohm, are
  DC-coupled. GPSDO rev B first tapped each channel on the GATE side of its 10 nF coupling
  cap, where the only DC is a 1 Mohm replica bias: plugged in, the scope pulled the gate's
  bias from 1.5 V to 2 mV (50 ohm) or 0.75 V (1 Mohm) and the channel stopped squaring.
  Found while writing the bring-up on order day; moved to the SOURCE side of the cap, where
  at 10 MHz the waveform is the same and the DC lands on the 51 ohm and 2.2 kohm. A tap on any
  node whose DC is set through a high resistance needs the coupling cap between it and the
  node, or a series cap of its own.

## Tap the node nothing else reaches

GPSDO rev B's first tap per channel was on the input, which a tee at the channel's own SMA
already shows for as long as you like. The edge the sampler actually takes, the squarer's
output, had no access at all; the handbook said "The squared signal has no test point". Rev
B taps it: 1 kohm with its pad on the track, the U.FL 2.5 mm from the helper clock and 6 mm
from the squarer's input.

## Probe loops (PID motor board, 2026-10-24/26)

- A probe loop on every op-amp output, and on the push-pull's bases, so the crossover jump
  (about 1.2 V as the output crosses zero) can be seen. Where a loop's name has no room
  beside it, print it rotated 90 degrees between the parallel wires.
- Ask of every probe loop: what does a ground clip here do? (See `component-selection`,
  "Put the fuse ahead of everything a student can reach".)
- Probe-ability beats the PCB price on a low-volume board. The user, on 170 x 120 mm
  against the 100 x 100 discount: "I'd rather keep the ability to probe than save a few
  dollars. Not every student needs one of these boards, whereas every student needs an
  op-amp board." Shrink a board every student gets; let a lab-station board be big.

## A picture beside every place a bring-up step names

The user (2026-10-10): "include a thumbnail around the 3D render so that I can easily find
the reference on a crowded board, which sits on a crowded desk. Double check that the
reference is actually next to the component or probe point you want me to probe."

- Cut each from the board's own 3D render (`kicad-cli pcb render --side top --quality
  high`; the opaque area, alpha over 128, is exactly the board, so board mm map straight to
  pixels).
- Each picture: a small whole board with a red box, the zoom beside it, the part or pin
  circled and the words the board prints for it boxed, drawn the way the board sits on the
  bench.
- Generate them in the build from a list of (designator, pad, printed words), and fail the
  build unless each spot's words are beside it AND nearer it, from the words' centre, than
  any other part of its kind (another test point, U.FL, jack, pin of the same header).
- GPSDO's `gen/handbook_figs.py`: the first run found a test point whose letter had
  silently stopped printing when its net was renamed.

## Rails at a glance

An LED per rail, and an "in range" indication where it matters (GPSDO P40, REVB #6). Drive
the LEDs so that they do not load a quiet rail.
