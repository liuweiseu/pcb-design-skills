# Placing a generated board: the rule placer and its traps

Read this when a script places the parts (a rule placer, hand anchors, a resolver that pushes
courtyards apart), or when a generated placement leaves nets that will not route.

## The rule placer

- **Three hundred passives are placed by rule, not by hand, and the rules are the schematic's
  own** (CostasLink, 2026-10-09, `gen/placement.py`):
  - a shunt stands perpendicular at the pin it serves, outside the chip's courtyard, its signal pad
    nearest the chip;
  - a series part lies on the line between the two pads it joins;
  - a part whose far end's net has nothing placed yet hangs off its known end and becomes the next
    part's anchor;
  - a capacitor between a rail and ground belongs to the chip the SCHEMATIC drew it beside (the
    netlist cannot say: read the sheets' symbol positions and take the nearest chip on that rail on
    the same sheet);
  - a part hangs off a chip pin, then a placed passive, then a jumper, and off a 40-pin connector
    last;
  - then push apart until no courtyards overlap (outward first, then sideways, then a spiral), and
    report what stayed overlapping;
  - draw the plan (courtyards, pads, designators) to look at BEFORE KiCad: the picture found the
    socket mirrored and the USB-C turned into the board, which the overlap count could not.
- **Check that every shunt's signal pad is the one nearer its chip, in code, after placing**
  (CostasLink, 2026-10-09, Response 9). The rule that turns a two-terminal part to stand at a pin
  had its sense inverted for parts above or below a chip (KiCad's rot 90 puts local -x at +y, i.e.
  below), so every rail capacitor and shunt on a chip's top or bottom row faced the pin with its
  GROUND pad, and the fan-out planner reported "C126.2 GND" in front of pin after pin. The picture
  could not show it (an 0402 looks the same either way round); a six-line check measuring both
  pads' distances to the pin found 65 of 65 wrong, and 0 after the fix. Any rule that orients a
  part by a case split needs a measurement after it, not a reading of it.
- **A series part placed at the midpoint of a long line strands it under whatever is there**
  (CostasLink, 2026-10-09). The series rule put the slow Q stage's 1 k resistors in the middle of a
  32 mm run, under the RX synthesizer, and the resolver could not push them out of its fan band.
  When a two-terminal part's two ends are far apart the placement is wrong, not the part: move the
  destination (the slow comparators went under their stage, 5 mm away) and the rule works again.
  Print the span of every rule-placed series part and look at the long ones.
- **An automatic placer optimises what it is told** (CostasLink rev A, §27). "The capacitor beside
  the chip the schematic drew it beside" put the receive tees' 68 pF 36 mm from their chokes.
  Anchor every RF part to the pad it serves, by hand, and measure the distance in the build (see
  the rf-design skill).
- **Keep a band round every fine-pitch chip free of parts, in the placement, before any fan-out is
  planned** (CostasLink, 2026-10-09). OWLternating Current's fan reported the pins it could not
  serve and the parts were moved by hand; with 25 chips that is a day. A chip of 16 pads or more
  owns a band (1.8 mm beyond its courtyard) no part may stand in; its own shunts are placed just
  outside the band, and the resolver pushes everything else out. The fan's vias then always have
  room, and the fan's "why" list shrinks to the parts placed before the rule existed.
- **Reserve every labelled connector's name-and-limit strip in the placer, not only the edge
  rows.** CostasLink's REF OUT jack (J108) was in no label row, so nothing kept its strip clear;
  when build 18's reshuffle moved a tap resistor under its name, the silkscreen found no place for
  "25 MHz, 1.6 Vpp/50R" and the release's label gate failed.

## Hand anchors

- **Place an amplifier's feedback, gain and shunt resistors at its pins, by hand, and check the
  pair order first.** A rule placer treats a feedback resistor as a series part between two pins
  of one chip and can put it anywhere along a detour. CostasLink's I-arm THS4541 got its 4.02 k
  feedback resistors 10 and 13 mm from its pins: a long summing node on an 850 MHz-GBW amplifier,
  which invites peaking. Its Q arm's input lines crossed beside the chip, because the + input's
  network sat to the left and the − input's above. For a differential pair, make the source's pin
  order match the amplifier's. Where it cannot, swap the pair at the input (it inverts the signal;
  say so in the schematic) rather than cross beside the chip. Inverting one arm of a quadrature
  receiver is a mirror, not a rotation: re-derive every loop sign after it (see the rf-design skill).
- **Check that a pair's pins face each other before laying it** (CostasLink build 17, KimiK3's
  review). The MAX2871's RFOUTA_P faced the ADL5380's LOIN, so the drawn P-to-LOIP pair had to
  cross on one layer, and the router took one leg 44 mm round the chip (60° of skew at 5.8 GHz).
  Swap the pair at one end (inverting an LO into a mixer costs a Costas loop nothing: sign(I)·Q is
  even in it), stand its series parts as mirror images, and gate the legs' lengths summed through
  their series parts: KiCad's skew constraint compares single nets, and each leg here is three.
- **A hand anchor keyed by reference follows the number, not the part.** References are handed out
  in drawing order, so adding one part to a schematic helper renumbers every part drawn after it on
  that sheet. CostasLink's Q arm gained a trim resistor in Response 14, and its two anchored
  feedback resistors slid to R117 and R118. The anchor for "R116" then placed the new trim where a
  feedback resistor belonged, and the routing failed there. After any schematic change, check each
  anchored passive's value and nets against what its anchor's comment says. Better, give the parts
  you anchor explicit references in the generator.
- **A shunt-at-pin rule on an ADC's inputs walls its neighbours** (CostasLink, Prompt 31). Four
  100 nF placed hard against the ADS1115's pins boxed the series resistors' far pads and the slow
  ADC's SCL pin: the same two nets failed in six route seeds. A 160 Hz filter does not care where
  its parts sit: anchor them a few millimetres out, with the I2C side clear, before trying seeds.
  Seeds are for luck; a net that fails in every seed is a placement fault.

## Connectors on a generated board

- **pcbnew's `Flip()` onto the back mirrors y, whatever its enum says** (CostasLink, 2026-10-09:
  measured with FLIP_DIRECTION_LEFT_RIGHT in KiCad 10.0.6, the socket's even row went from +2.54 to
  -2.54 and its odd row stayed). Never model a flip; put the HOST's measured connector pins into the
  generator (the PYNQ-Z2's header, from GPSDO-PYNQ-Z2/pcb/geom.py) and have the board generator read
  pcbnew's own pad positions back and refuse to lay copper until pins 1, 2, 3, 39 and 40 sit on
  them. The same check holds the RF pads on their chain lines, which is how each chip's rotation
  was settled.
- **A connector's pad row faces the way its rotation says, not the way its name suggests:** the HRO
  USB-C at rot 270 faces -x (GPiBridge's left edge); on a right edge it is rot 90. Turned the wrong
  way its pads lie past the board edge, outside the routing grid, and the ground fan-out divides by
  zero.
- **A connector's courtyard is what the placer says, not the body** (U.FL 4.35 x 5.0 mm, MMCX 4.9
  square, SOT-23-5 4.1 x 3.4, a 1x2 header 3.5 x 6.1 with its origin on pin 1): print
  `load_footprints()[name]["court"]` before laying a row of jacks, and keep GAP (0.5 mm) between
  courtyards. Seven U.FL at 5.5 mm pitch need 38 mm.
- **Pin-header footprints anchor on pin 1**, not on their centre: a lying 1x2 reaches 6.1 mm past
  its anchor, a 1x3 8.6 mm. Compute the courtyard from the footprint before moving one, or a
  westward nudge lands on the neighbour (ECP5 P26).

## Placement variants

- **A generated board's router is chaotic: build placement variants in parallel.** One moved part
  reroutes the whole board, and a net that routed before can end up walled in elsewhere (CostasLink
  build 18: moving one tap resistor walled in DAC 2's pins; anchoring it beside its jack walled in
  a comparator's input instead). The build is deterministic, so copy the project to three or four
  scratch directories, change one anchor in each, run them at once (32 cores; about 25 minutes for
  four), and keep the one that routes completely, instead of one guess per 11-minute build.
- **A new footprint changes the router's luck** (CostasLink, Prompt 31). Swapping a 6-pad balun for
  a 4-pad one left 3 nets in pieces where the last build had 1. Try seeds side by side in rsync'd
  copies (`COSTASLINK_ROUTE_SEED=n python3 gen/board.py`, 9 min each, six at once on 32 cores) and
  keep the seed that finishes in `gen/routes.py`.
