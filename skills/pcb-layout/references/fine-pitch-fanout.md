# Fine-pitch fan-out: planning the escape from a QFN, LGA or fine LQFP

Read this before routing anything from a chip with pins at 0.5 mm pitch or finer, or when a
router leaves a QFN's pins walled in.

## Plan every fine-pitch chip's fan-out; never leave it to the router

A maze router routing net by net walls a QFN's later pins in: the first lines hug the chip, and
its vias at the pin's tip (0.45 mm vias, 0.4 mm pitch) shut the neighbours. A fan-out band (no
vias near the pins) or stubs straight out at the pins' pitch do not help: a 0.4 mm comb leaves no
room for a via between its teeth or for a tip to turn. Before routing anything long, give each
signal pin a stub (to 0.25 mm past the pad), then a straight line to a via of its own:

1. Per side, go from the middle pin outward, each via outward of the one before, so the lines
   spread like a fan and none crosses another or passes in front of a pin still to come.
2. No line steeper than about 35 degrees from the pin's axis (at 0.4 mm pitch a steeper line
   passes closer than track plus clearance to the next pin's stub end); outer pins go deeper, not
   steeper.
3. Vias evenly spaced, in one row (0.62 mm apart for 0.45 mm vias) or two staggered rows (lines to
   the second pass between the first's vias), with a straight run out of the pins first where
   capacitors stand in front; search the spacing, depth, sideways shift and run for the cheapest
   pattern that serves every pin.
4. Check planned lines with exact geometry (segment to segment, pad, via, zone), not the router's
   grid: a grid judges a line at any angle only to within its pitch (0.07 mm on a 0.1 mm grid), and
   one that answers "radius 0" queries only at nodes it lands on exactly hardly checks diagonal
   lines at all (OWLternating Current's first fan-out overlapped; 53 shorts in DRC).
5. Route the chip's short local nets first (USB, flash, a current-setting resistor), and plan lines
   that leave from the middle of a side (a crystal's XIN and XOUT): a routed one cuts diagonally in
   front of the pins beside it and closes them in. (On a board of many chips, fan every chip before
   any chip's local nets: see below.)

A pin a fan cannot serve is walled in by its neighbours' lines, whatever comes after (keeping its
line's place, an escape to the nearest via spot, routing it first: all tried, all walled it or its
neighbours in). **The cure is placement:** a decoupling capacitor straight in front of a signal pin
blocks it and both neighbours, so put it midway between two signal pins (an 0402 standing across
fits between pins 1.2 mm apart) or at the end of the row in front of ground pins that go inward to
the exposed pad. Have the fan print what blocks each pin it cannot serve.

The router then starts each net from its via with every layer to choose from. OWLternating
Current's RP2354A (QFN-60, 33 signals) and LP5036s: 37 nets unjoined with the router escaping on
its own; with planned fan-outs, the placement moves the fan's report asked for, and rip-up and
reroute, 1.

## Order on a board of many chips

- **Every chip's fan-out before any chip's local nets, and a planned line runs straight out of a
  fine pin for the fan band's depth before it turns** (CostasLink, 2026-10-09, Response 9).
  OWLternating Current routed each chip's short local nets before its own fan-out, so the fan's
  vias would not wall them; with twenty-five chips, a local net of one chip (a feedback resistor
  9 mm away) ran along the NEXT chip's pin row before that chip had its fan, and sealed two pins
  (the stamp of the router's grid showed the pad enclosed on an otherwise empty board). Fan every
  chip first; from its via a local net has every layer and goes round.
- A planned line that leaves a 0.5 mm-pitch pin and turns at the pad's tip passes the neighbouring
  pin at exactly the clearance: DRC-legal, and nothing can ever leave that neighbour. Run straight
  for 1.4 mm.
- **Keep a band round every fine-pitch chip free of parts** (16 pads or more, 1.8 mm beyond the
  courtyard; generated-placement.md).

## Net classes and widths near fine pins

- **A 0.5 mm pitch QFN on a 0.2 mm board** (RF-MOD, §18): give the chip's own nets a fine net class
  (0.127 / 0.15 mm, 0.45 / 0.25 vias; JLCPCB's four-layer floor is lower) and lower the board's
  floor to match; the rest of the board keeps 0.2. Fan the pins out at 45 degrees to 0402s on a
  1.2 mm pitch, ground pins straight into the paddle, the paddle's vias first.
- **A fine board's DRC still uses each net's class** (§26). A 0.4 mm pitch QFN's stubs pass at
  0.2 mm wide only (the Default class's 0.2 mm clearance applies between nets of that class); an
  LGA's unconnected pins, 0.15 mm apart, are each a Default net. Put a fine tile's nets in the Fine
  class, and its unconnected pins too with a netclass pattern (`unconnected-(U601-*`).
- **A radius-0 cell query on a line laid at pad coordinates finds no cell at all** (CostasLink,
  2026-10-09). The track-widening pass asked the grid for the cells under a track's centre line
  with reach 0; a fan-out stub drawn from a pad centre like x = 26.79 lies between the 0.1 mm grid
  nodes, so the query returned nothing, nothing blocked it, and the stub at a 0.5 mm-pitch QFN pin
  was widened to 0.8 mm into its neighbours (14 shorts). Sample with half a pitch of reach; and
  never widen a planned line or anything within a millimetre of a fine-pitch pin.
- **A chip under a motor routes on the back between the slots** (AMOD-B, §26). Four radial slots
  leave 45-degree corridors: a back line along x + y = c (or x - y = c) clears a slot's end only
  where c is far enough from the slot's centre line, so compute the band of allowed c and give each
  line its own. The MT6701's pins went to fine vias under its body, its lines on those diagonals;
  the SOIC turned 180 so its SSI pins faced the tiles they serve.
